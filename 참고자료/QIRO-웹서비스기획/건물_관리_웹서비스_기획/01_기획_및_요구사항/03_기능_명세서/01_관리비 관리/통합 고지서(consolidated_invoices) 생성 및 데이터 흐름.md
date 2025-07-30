# **통합 고지서(consolidated_invoices) 생성 및 데이터 흐름**

### **1. 문서 개요**

본 문서는 '월별 관리비 자동 계산'이 완료된 후, `bms.billing_details` 테이블의 상세 내역을 바탕으로 입주사(임차인/소유주)에게 발행될 **최종 통합 고지서** 정보를 관리하는 **`bms.consolidated_invoices` 테이블의 상세한 DDL(Data Definition Language)**과, **'고지서 발행' 시의 데이터 처리 흐름**을 정의합니다.

### **2. `bms.consolidated_invoices` 테이블 DDL (PostgreSQL)**

이 테이블은 각 수신자(임차인 또는 소유주)에게 발행된 최종 고지서의 요약 정보와 상태를 관리하는 역할을 합니다.

```
-- =====================================================================
-- 통합 고지서 정보 테이블 DDL
-- 데이터베이스 종류: PostgreSQL, 스키마: bms
-- =====================================================================

-- 기존 테이블 및 타입이 존재하면 삭제 (초기화 시에만 사용)
DROP TABLE IF EXISTS bms.consolidated_invoices;
DROP TYPE IF EXISTS bms.invoice_status;

-- 고지서 상태 ENUM 타입 생성
CREATE TYPE bms.invoice_status AS ENUM ('PENDING', 'ISSUED', 'SENT', 'PAID', 'PARTIALLY_PAID', 'OVERDUE', 'VOID');
COMMENT ON TYPE bms.invoice_status IS '고지서 상태 (발행대기, 발행완료, 발송완료, 납부완료, 부분납부, 연체, 무효)';

-- 통합 고지서 정보 테이블 생성
CREATE TABLE bms.consolidated_invoices (
    invoice_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    billing_cycle_id uuid NOT NULL,
    recipient_type varchar(50) NOT NULL,
    recipient_id uuid NOT NULL,
    unit_ids text NOT NULL,
    invoice_number varchar(100) NOT NULL UNIQUE,
    issue_date date NOT NULL,
    due_date date NOT NULL,
    total_amount numeric(15, 2) NOT NULL,
    paid_amount numeric(15, 2) DEFAULT 0 NOT NULL,
    unpaid_amount numeric(15, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    status bms.invoice_status DEFAULT 'PENDING' NOT NULL,
    pdf_file_url text NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    updated_at timestamptz DEFAULT now() NOT NULL,
    created_by varchar(100),
    updated_by varchar(100),
    CONSTRAINT fk_billing_cycle FOREIGN KEY (billing_cycle_id) REFERENCES bms.billing_cycles(id) ON DELETE CASCADE
);

-- 테이블 및 각 컬럼에 대한 주석 추가
COMMENT ON TABLE bms.consolidated_invoices IS '각 수신자(임차인/소유주)에게 발행된 최종 통합 고지서 정보를 관리하는 테이블';
COMMENT ON COLUMN bms.consolidated_invoices.invoice_id IS '고지서의 고유 식별자 (PK)';
COMMENT ON COLUMN bms.consolidated_invoices.billing_cycle_id IS '이 고지서가 속한 청구월의 ID';
COMMENT ON COLUMN bms.consolidated_invoices.recipient_type IS '수신자 유형 (TENANT: 임차인, OWNER: 소유주)';
COMMENT ON COLUMN bms.consolidated_invoices.recipient_id IS '수신자의 고유 ID (bms.tenants 또는 bms.unit_owners의 ID)';
COMMENT ON COLUMN bms.consolidated_invoices.unit_ids IS '이 고지서에 포함된 모든 호실 ID 목록 (쉼표로 구분된 텍스트)';
COMMENT ON COLUMN bms.consolidated_invoices.invoice_number IS '고유한 고지서 번호';
COMMENT ON COLUMN bms.consolidated_invoices.issue_date IS '고지서 발행일';
COMMENT ON COLUMN bms.consolidated_invoices.due_date IS '납부 마감일';
COMMENT ON COLUMN bms.consolidated_invoices.total_amount IS '총 청구금액';
COMMENT ON COLUMN bms.consolidated_invoices.paid_amount IS '현재까지 납부된 금액';
COMMENT ON COLUMN bms.consolidated_invoices.unpaid_amount IS '미납 잔액 (total_amount - paid_amount)으로 자동 계산됨';
COMMENT ON COLUMN bms.consolidated_invoices.status IS '고지서의 현재 상태 (bms.invoice_status ENUM 타입 사용)';
COMMENT ON COLUMN bms.consolidated_invoices.pdf_file_url IS 'AWS S3 등에 저장된 실제 고지서 PDF 파일의 URL';
COMMENT ON COLUMN bms.consolidated_invoices.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN bms.consolidated_invoices.updated_at IS '레코드 마지막 수정 시각';
COMMENT ON COLUMN bms.consolidated_invoices.created_by IS '레코드를 생성한 사용자 ID';
COMMENT ON COLUMN bms.consolidated_invoices.updated_by IS '레코드를 마지막으로 수정한 사용자 ID';
```

### **3. '고지서 발행' 시의 데이터 흐름**

관리자가 **'관리비 계산 결과 검토'**를 마치고 **`[고지서 일괄 발행]`** 버튼을 클릭했을 때, 시스템은 다음과 같은 절차를 하나의 트랜잭션으로 처리합니다.

#### **1단계: 데이터 집계 및 수신자 결정**

1. **데이터 조회:** 시스템은 `bms.billing_details` 테이블에서 현재 청구월(`billing_cycle_id`)에 해당하는 모든 상세 부과 내역을 가져옵니다.
2. **수신자 결정:** 각 `detail` 레코드의 `unit_id`를 기준으로, `bms.units`와 `bms.lease_contracts` 테이블을 참조하여 해당 호실의 현재 계약 상태(공실/계약중)를 확인하고, 최종 고지서 수신자(임차인 ID 또는 소유주 ID)를 결정합니다.
3. **수신자별 그룹화:** 모든 `detail` 레코드를 **'최종 수신자'**를 기준으로 그룹화합니다.
   - **(예시)** 한 명의 임차인이 2개의 호실을 계약했다면, 그 임차인 앞으로 2개 호실의 모든 `detail` 레코드가 하나의 그룹으로 묶입니다.

#### **2단계: 통합 고지서 생성 및 저장**

1. **고지서 생성:** 시스템은 1단계에서 그룹화된 각 수신자 그룹에 대해 **하나의 통합 고지서**를 생성합니다.
2. **금액 합산:** 각 그룹에 속한 `billing_details`의 `amount`를 모두 합산하여, 해당 수신자의 **`total_amount`(총 청구금액)**를 계산합니다.
3. **데이터 저장:** 계산된 정보를 바탕으로 `bms.consolidated_invoices` 테이블에 새로운 행을 **`INSERT`** 합니다. 이때 `status`는 기본값인 **`PENDING`(발행대기)**으로 저장됩니다.

#### **3단계: PDF 생성 및 업로드**

1. **PDF 생성:** 방금 생성된 각 `consolidated_invoice`에 대해, 관련된 모든 `billing_details` 데이터를 모아 `PdfGeneratorService`를 호출하여 **고지서 PDF 파일을 생성**합니다.
2. **S3 업로드:** 생성된 PDF 파일을 `S3StorageService`를 호출하여 **AWS S3에 업로드**하고, 고유한 파일 URL을 반환받습니다.
3. **URL 업데이트:** 반환받은 S3 파일 URL을 `bms.consolidated_invoices` 테이블의 해당 고지서 레코드에 **`UPDATE`** 하여 저장합니다.

#### **4단계: 최종 발행 처리 및 알림**

1. **상태 변경:** 모든 PDF 생성 및 업로드가 완료되면, `bms.consolidated_invoices` 테이블에 있는 해당 월의 모든 고지서 `status`를 `PENDING`에서 **`ISSUED`(발행완료)**로 일괄 **`UPDATE`** 합니다.
2. **청구월 상태 변경:** `bms.billing_cycles` 테이블의 현재 청구월 상세 상태를 **`INVOICE_ISSUED`(고지서 발행완료)**로 변경합니다.
3. **알림 발송:** `NotificationService`를 호출하여, 모든 수신자에게 이메일, SMS 등을 통해 **고지서 발행 사실을 통지**합니다.

이러한 흐름을 통해, 상세 계산 내역과 최종 발행 고지서 정보가 명확하게 분리되어 관리되며, 전체 프로세스가 자동화되어 처리됩니다.