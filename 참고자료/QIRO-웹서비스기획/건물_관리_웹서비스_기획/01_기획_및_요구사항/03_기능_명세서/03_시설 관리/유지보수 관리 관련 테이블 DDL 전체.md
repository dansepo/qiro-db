

### **유지보수 관리 관련 테이블 DDL 전체 (PostgreSQL)**





#### **1. 사전 정의 (ENUM 타입 및 트리거 함수)**



테이블 생성에 앞서, 여러 테이블에서 공통으로 사용할 `ENUM` 타입들과 `updated_at` 자동 갱신 트리거 함수를 먼저 정의합니다.

SQL

```
-- ENUM 타입 정의
CREATE TYPE facility_type AS ENUM ('ELECTRICITY', 'GAS', 'WATER', 'ELEVATOR', 'FIRE_FIGHTING', 'HVAC', 'PLUMBING', 'OTHER');
CREATE TYPE maintenance_type AS ENUM ('REPAIR', 'REPLACEMENT', 'PREVENTIVE', 'BREAKDOWN');
CREATE TYPE contract_scope_type AS ENUM ('FULL_MANAGEMENT', 'CLEANING', 'SECURITY', 'ELEVATOR_MAINTENANCE', 'FIRE_FIGHTING_MAINTENANCE', 'HVAC_MAINTENANCE', 'OTHER');
CREATE TYPE vendor_invoice_status AS ENUM ('DUE', 'PAID', 'OVERDUE', 'CANCELED');
CREATE TYPE payment_method_enum AS ENUM ('BANK_TRANSFER', 'CREDIT_CARD', 'CASH');

-- updated_at 컬럼 자동 갱신을 위한 트리거 함수 생성
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

*(참고: `Companies`, `Buildings`, `Units` 등 최상위 마스터 테이블은 이전 답변에 정의되어 있으며, 아래 테이블들은 해당 테이블이 존재한다고 가정합니다.)*

------



#### **2. 테이블 정의 (Table Definitions)**





##### **2.1. `Facilities` (시설물 마스터)**



건물 내 관리 대상이 되는 모든 물리적 설비 및 시설물의 정보를 담습니다.

SQL

```
-- 테이블 생성
CREATE TABLE Facilities (
    facility_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    building_id VARCHAR(100) NOT NULL REFERENCES Buildings(building_id),
    location_description TEXT NOT NULL,
    facility_type facility_type NOT NULL,
    model_name VARCHAR(255),
    manufacturer VARCHAR(255),
    installation_date DATE,
    qr_code VARCHAR(255) UNIQUE,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 주석 추가
COMMENT ON TABLE Facilities IS '건물 내 다양한 설비 및 시설물의 마스터 정보';
COMMENT ON COLUMN Facilities.facility_id IS '시설물 고유 식별자 (PK)';
COMMENT ON COLUMN Facilities.company_id IS '시설물이 속한 회사의 ID (FK)';
COMMENT ON COLUMN Facilities.building_id IS '시설물이 설치된 건물의 ID (FK)';
COMMENT ON COLUMN Facilities.location_description IS '시설물 설치 상세 위치 (예: 지하2층 전기실, 101동 승강기)';
COMMENT ON COLUMN Facilities.facility_type IS '시설물 종류 (ENUM: ELECTRICITY, ELEVATOR 등)';
COMMENT ON COLUMN Facilities.model_name IS '시설물 모델명';
COMMENT ON COLUMN Facilities.manufacturer IS '시설물 제조사';
COMMENT ON COLUMN Facilities.installation_date IS '시설물 설치일';
COMMENT ON COLUMN Facilities.qr_code IS '시설물 고유 QR 코드 (스캔용)';
COMMENT ON COLUMN Facilities.notes IS '기타 비고 및 특이사항';
COMMENT ON COLUMN Facilities.is_active IS '시설물 활성화 여부';

-- 트리거 적용
CREATE TRIGGER set_timestamp_facilities
BEFORE UPDATE ON Facilities
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.2. `Vendors` (공급업체 마스터)**



유지보수, 물품 구매 등과 관련된 모든 외부 업체의 정보를 관리합니다.

SQL

```
-- 테이블 생성
CREATE TABLE Vendors (
    vendor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    vendor_name VARCHAR(255) NOT NULL,
    business_registration_number VARCHAR(50),
    representative_name VARCHAR(100),
    contact_person VARCHAR(100),
    contact_phone VARCHAR(50),
    contact_email VARCHAR(100),
    address TEXT,
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(100),
    bank_account_holder VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (company_id, business_registration_number)
);

-- 주석 추가
COMMENT ON TABLE Vendors IS '시설관리, 물품구매 등과 관련된 모든 외부 공급업체 마스터 정보';
COMMENT ON COLUMN Vendors.vendor_id IS '공급업체 고유 식별자 (PK)';
COMMENT ON COLUMN Vendors.company_id IS '공급업체가 등록된 회사 ID (FK)';
COMMENT ON COLUMN Vendors.vendor_name IS '공급업체명';
COMMENT ON COLUMN Vendors.business_registration_number IS '사업자등록번호';
COMMENT ON COLUMN Vendors.representative_name IS '대표자명';
COMMENT ON COLUMN Vendors.contact_person IS '업체 담당자 이름';
COMMENT ON COLUMN Vendors.contact_phone IS '업체 담당자 연락처';
COMMENT ON COLUMN Vendors.contact_email IS '업체 담당자 이메일';
COMMENT ON COLUMN Vendors.address IS '업체 주소';
COMMENT ON COLUMN Vendors.bank_name IS '지급용 은행명';
COMMENT ON COLUMN Vendors.bank_account_number IS '지급용 계좌번호';
COMMENT ON COLUMN Vendors.bank_account_holder IS '지급용 예금주명';
COMMENT ON COLUMN Vendors.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN Vendors.updated_at IS '레코드 마지막 수정 시각';

-- 트리거 적용
CREATE TRIGGER set_timestamp_vendors
BEFORE UPDATE ON Vendors
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.3. `Contract_Agreements` (위탁 계약)**



공급업체와 맺은 정기적인 유지보수, 관리 등의 계약 정보를 담습니다.

SQL

```
-- 테이블 생성
CREATE TABLE Contract_Agreements (
    agreement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    building_id VARCHAR(100) NOT NULL REFERENCES Buildings(building_id),
    vendor_id UUID NOT NULL REFERENCES Vendors(vendor_id),
    contract_scope contract_scope_type NOT NULL,
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    contract_amount DECIMAL(15, 2),
    payment_cycle VARCHAR(50) NOT NULL DEFAULT 'MONTHLY',
    next_invoice_date DATE,
    contract_file_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (building_id, vendor_id, contract_scope, contract_start_date)
);

-- 주석 추가
COMMENT ON TABLE Contract_Agreements IS '건물 단위 위탁/대행 계약 정보';
COMMENT ON COLUMN Contract_Agreements.agreement_id IS '계약 고유 식별자 (PK)';
COMMENT ON COLUMN Contract_Agreements.company_id IS '계약이 속한 회사 ID (FK)';
COMMENT ON COLUMN Contract_Agreements.building_id IS '계약이 적용되는 건물 ID (FK)';
COMMENT ON COLUMN Contract_Agreements.vendor_id IS '계약을 맺은 공급업체 ID (FK)';
COMMENT ON COLUMN Contract_Agreements.contract_scope IS '계약 범위 (ENUM)';
COMMENT ON COLUMN Contract_Agreements.contract_start_date IS '계약 시작일';
COMMENT ON COLUMN Contract_Agreements.contract_end_date IS '계약 종료일';
COMMENT ON COLUMN Contract_Agreements.contract_amount IS '계약 금액';
COMMENT ON COLUMN Contract_Agreements.payment_cycle IS '결제 주기 (예: MONTHLY, QUARTERLY, ANNUALLY)';
COMMENT ON COLUMN Contract_Agreements.next_invoice_date IS '다음 청구서 생성 예정일';
COMMENT ON COLUMN Contract_Agreements.contract_file_url IS '계약서 파일 URL';
COMMENT ON COLUMN Contract_Agreements.notes IS '계약 관련 비고';
COMMENT ON COLUMN Contract_Agreements.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN Contract_Agreements.updated_at IS '레코드 마지막 수정 시각';

-- 트리거 적용
CREATE TRIGGER set_timestamp_contract_agreements
BEFORE UPDATE ON Contract_Agreements
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.4. `Maintenances` (유지보수 이력)**



시설물에 대한 모든 수선/교체 등 유지보수 활동(작업지시)을 기록합니다.

SQL

```
-- 테이블 생성
CREATE TABLE Maintenances (
    maintenance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    facility_id UUID NOT NULL REFERENCES Facilities(facility_id),
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    building_id VARCHAR(100) NOT NULL REFERENCES Buildings(building_id),
    maintenance_type maintenance_type NOT NULL,
    scheduled_date DATE,
    actual_completion_date DATE,
    maintenance_details TEXT NOT NULL,
    performed_by_internal BOOLEAN NOT NULL,
    vendor_id UUID NULL REFERENCES Vendors(vendor_id),
    responsible_person VARCHAR(100),
    attachment_file_urls TEXT[],
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 주석 추가
COMMENT ON TABLE Maintenances IS '시설물별 수선/교체 등 유지보수 이력';
COMMENT ON COLUMN Maintenances.maintenance_id IS '유지보수 이력 고유 식별자 (PK)';
COMMENT ON COLUMN Maintenances.facility_id IS '관련 시설물 ID (FK)';
COMMENT ON COLUMN Maintenances.company_id IS '회사의 ID (FK)';
COMMENT ON COLUMN Maintenances.building_id IS '건물의 ID (FK)';
COMMENT ON COLUMN Maintenances.maintenance_type IS '유지보수 유형 (ENUM: REPAIR, REPLACEMENT 등)';
COMMENT ON COLUMN Maintenances.scheduled_date IS '작업 예정일';
COMMENT ON COLUMN Maintenances.actual_completion_date IS '실제 작업 완료일';
COMMENT ON COLUMN Maintenances.maintenance_details IS '작업 내용 상세';
COMMENT ON COLUMN Maintenances.performed_by_internal IS '내부 작업 여부 (TRUE: 내부, FALSE: 외부)';
COMMENT ON COLUMN Maintenances.vendor_id IS '외부 작업인 경우 공급업체 ID (FK)';
COMMENT ON COLUMN Maintenances.responsible_person IS '작업 담당자 (내부직원/외부업체 담당자 이름)';
COMMENT ON COLUMN Maintenances.attachment_file_urls IS '첨부 파일 URL 목록 (배열)';
COMMENT ON COLUMN Maintenances.notes IS '기타 비고';
COMMENT ON COLUMN Maintenances.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN Maintenances.updated_at IS '레코드 마지막 수정 시각';

-- 트리거 적용
CREATE TRIGGER set_timestamp_maintenances
BEFORE UPDATE ON Maintenances
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.5. `Maintenance_Costs` (유지보수 비용 기록)**



하나의 유지보수 활동에 수반된 구체적인 지출 내역을 기록합니다.

SQL

```
-- 테이블 생성
CREATE TABLE Maintenance_Costs (
    cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    maintenance_id UUID NOT NULL REFERENCES Maintenances(maintenance_id),
    cost_date DATE NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    cost_category VARCHAR(100) NOT NULL,
    applicable_fund_type VARCHAR(50) NOT NULL,
    proof_file_url TEXT,
    notes TEXT,
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    building_id VARCHAR(100) NOT NULL REFERENCES Buildings(building_id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 주석 추가
COMMENT ON TABLE Maintenance_Costs IS '유지보수 활동에 수반된 비용 상세 기록';
COMMENT ON COLUMN Maintenance_Costs.cost_id IS '비용 기록 고유 식별자 (PK)';
COMMENT ON COLUMN Maintenance_Costs.maintenance_id IS '연결된 유지보수 이력 ID (FK)';
COMMENT ON COLUMN Maintenance_Costs.cost_date IS '비용 발생일';
COMMENT ON COLUMN Maintenance_Costs.amount IS '비용 금액';
COMMENT ON COLUMN Maintenance_Costs.cost_category IS '비용 항목 (예: 자재비, 공임비, 외주용역비)';
COMMENT ON COLUMN Maintenance_Costs.applicable_fund_type IS '적용된 자금 유형 (예: 장기수선충당금, 수선유지비, 예치금)';
COMMENT ON COLUMN Maintenance_Costs.proof_file_url IS '증빙 파일 URL (영수증 등)';
COMMENT ON COLUMN Maintenance_Costs.notes IS '비고';
COMMENT ON COLUMN Maintenance_Costs.company_id IS '비용이 발생한 회사의 ID (FK)';
COMMENT ON COLUMN Maintenance_Costs.building_id IS '비용이 발생한 건물의 ID (FK)';
COMMENT ON COLUMN Maintenance_Costs.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN Maintenance_Costs.updated_at IS '레코드 마지막 수정 시각';

-- 트리거 적용
CREATE TRIGGER set_timestamp_maintenance_costs
BEFORE UPDATE ON Maintenance_Costs
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.6. `Vendor_Invoices` (공급업체 청구서)**



유지보수 등의 활동 후 공급업체로부터 받은 청구서(매입 채무)를 관리합니다.

SQL

```
-- 테이블 생성
CREATE TABLE Vendor_Invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES Vendors(vendor_id),
    company_id VARCHAR(100) NOT NULL REFERENCES Companies(company_id),
    building_id VARCHAR(100) NOT NULL REFERENCES Buildings(building_id),
    vendor_invoice_number VARCHAR(100),
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    status vendor_invoice_status NOT NULL DEFAULT 'DUE',
    source_type VARCHAR(50),
    source_id UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 주석 추가
COMMENT ON TABLE Vendor_Invoices IS '공급업체로부터 받은 청구서(매입 채무)를 관리하는 테이블';
COMMENT ON COLUMN Vendor_Invoices.id IS '공급업체 청구서의 고유 식별자 (PK)';
COMMENT ON COLUMN Vendor_Invoices.vendor_id IS '청구서를 발행한 공급업체 ID (FK)';
COMMENT ON COLUMN Vendor_Invoices.company_id IS '청구서가 귀속된 회사 ID (FK)';
COMMENT ON COLUMN Vendor_Invoices.building_id IS '청구서가 귀속된 건물 ID (FK)';
COMMENT ON COLUMN Vendor_Invoices.vendor_invoice_number IS '공급업체 청구서 번호 (세금계산서 승인번호 등)';
COMMENT ON COLUMN Vendor_Invoices.issue_date IS '청구서 발행일';
COMMENT ON COLUMN Vendor_Invoices.due_date IS '지급 기한일';
COMMENT ON COLUMN Vendor_Invoices.total_amount IS '청구 총액';
COMMENT ON COLUMN Vendor_Invoices.status IS '지급 상태 (ENUM: DUE, PAID 등)';
COMMENT ON COLUMN Vendor_Invoices.source_type IS '출처 유형 (예: CONTRACT, MAINTENANCE_COST)';
COMMENT ON COLUMN Vendor_Invoices.source_id IS '출처 데이터의 ID (Contract_Agreements.id 또는 Maintenance_Costs.cost_id)';
COMMENT ON COLUMN Vendor_Invoices.notes IS '비고';
COMMENT ON COLUMN Vendor_Invoices.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN Vendor_Invoices.updated_at IS '레코드 마지막 수정 시각';

-- 트리거 적용
CREATE TRIGGER set_timestamp_vendor_invoices
BEFORE UPDATE ON Vendor_Invoices
FOR EACH ROW
EXECUTE PROCEDURE trigger_set_timestamp();
```



##### **2.7. `Vendor_Payments` (공급업체 지급 내역)**



공급업체 청구서에 대해 실제 대금을 지급한 내역을 기록합니다.

SQL

```
-- 테이블 생성
CREATE TABLE Vendor_Payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_invoice_id UUID NOT NULL REFERENCES Vendor_Invoices(id),
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(15, 2) NOT NULL,
    payment_method payment_method_enum NOT NULL,
    bank_account_info TEXT,
    transaction_memo TEXT,
    created_by_user_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 주석 추가
COMMENT ON TABLE Vendor_Payments IS '공급업체 청구서에 대해 실제 대금을 지급한 내역을 기록하는 테이블';
COMMENT ON COLUMN Vendor_Payments.id IS '지급 내역의 고유 식별자 (PK)';
COMMENT ON COLUMN Vendor_Payments.vendor_invoice_id IS '관련된 공급업체 청구서 ID (FK)';
COMMENT ON COLUMN Vendor_Payments.payment_date IS '실제 지급일';
COMMENT ON COLUMN Vendor_Payments.payment_amount IS '지급액';
COMMENT ON COLUMN Vendor_Payments.payment_method IS '지급 수단 (ENUM: BANK_TRANSFER 등)';
COMMENT ON COLUMN Vendor_Payments.bank_account_info IS '지급이 이루어진 출금 계좌 정보 (필요시)';
COMMENT ON COLUMN Vendor_Payments.transaction_memo IS '거래 메모 (이체 시 적요 등)';
COMMENT ON COLUMN Vendor_Payments.created_by_user_id IS '지급 처리 담당자 ID';
COMMENT ON COLUMN Vendor_Payments.created_at IS '레코드 생성 시각';
```