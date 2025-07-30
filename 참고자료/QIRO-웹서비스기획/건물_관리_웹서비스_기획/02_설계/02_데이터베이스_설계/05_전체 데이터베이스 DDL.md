## 🏛️ QIRO 서비스 전체 데이터베이스 DDL (PostgreSQL) - 최종 통합본

**사전 실행:**

- `UUID` 자동 생성을 위해 `pgcrypto` 확장 모듈이 필요할 수 있습니다.

- 스크립트 실행 전, 데이터베이스에 접속하여 아래 명령어를 먼저 실행해주세요.

  SQL

  ```
  CREATE EXTENSION IF NOT EXISTS "pgcrypto";
  ```

------

### **Part 1: 테이블 생성 (CREATE TABLE)**

------

SQL

```
-- ### 1. 사용자 및 접근 관리 (User & Access Management) ###

CREATE TABLE internal_user (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(50) NOT NULL,
    department VARCHAR(100),
    position VARCHAR(100),
    contact_number VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED')),
    mfa_enabled BOOLEAN NOT NULL DEFAULT false,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_by VARCHAR(50)
);
COMMENT ON TABLE internal_user IS 'QIRO 시스템 내부 사용자(직원) 계정 정보';

CREATE TABLE role (
    role_id VARCHAR(50) PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT false
);
COMMENT ON TABLE role IS '사용자 역할 정보 (총괄관리자, 관리소장 등)';

CREATE TABLE permission (
    permission_id VARCHAR(100) PRIMARY KEY,
    permission_name VARCHAR(255) NOT NULL,
    category VARCHAR(50),
    description TEXT
);
COMMENT ON TABLE permission IS '시스템 내 세분화된 기능/데이터 접근 권한';

CREATE TABLE user_role_link (
    user_id UUID NOT NULL,
    role_id VARCHAR(50) NOT NULL,
    PRIMARY KEY (user_id, role_id)
);
COMMENT ON TABLE user_role_link IS '사용자와 역할의 다대다 관계 연결 테이블';

CREATE TABLE role_permission_link (
    role_id VARCHAR(50) NOT NULL,
    permission_id VARCHAR(100) NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);
COMMENT ON TABLE role_permission_link IS '역할과 권한의 다대다 관계 연결 테이블';


-- ### 2. 건물 및 호실 정보 관리 (Building & Unit Information Management) ###

CREATE TABLE building (
    building_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_name VARCHAR(100) NOT NULL,
    address_zip_code VARCHAR(10),
    address_street VARCHAR(255) NOT NULL,
    address_detail VARCHAR(255),
    building_type_code VARCHAR(20) NOT NULL,
    total_unit_count INTEGER NOT NULL DEFAULT 0,
    management_start_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_by VARCHAR(50)
);
COMMENT ON TABLE building IS '관리 대상 건물 마스터 정보';

CREATE TABLE user_building_access (
    user_id UUID NOT NULL,
    building_id UUID NOT NULL,
    PRIMARY KEY (user_id, building_id)
);
COMMENT ON TABLE user_building_access IS '사용자별 접근 가능/담당 건물 정보';

CREATE TABLE unit (
    unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL,
    dong_name VARCHAR(50),
    unit_number VARCHAR(20) NOT NULL,
    floor VARCHAR(10) NOT NULL,
    unit_type_code VARCHAR(20) NOT NULL,
    exclusive_area NUMERIC(10, 2) NOT NULL,
    contract_area NUMERIC(10, 2),
    current_status VARCHAR(20) NOT NULL DEFAULT 'VACANT' CHECK (current_status IN ('VACANT', 'LEASED', 'UNDER_REPAIR', 'NOT_FOR_LEASE')),
    current_lessor_id UUID,
    current_tenant_id UUID,
    current_lease_contract_id UUID,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_by VARCHAR(50)
);
COMMENT ON TABLE unit IS '건물 내 개별 호실(세대) 정보';


-- ### 3. 임대인 및 임차인 관리 (Lessor & Tenant Management) ###

CREATE TABLE lessor (
    lessor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lessor_type VARCHAR(20) NOT NULL CHECK (lessor_type IN ('INDIVIDUAL', 'CORPORATION', 'SOLE_PROPRIETOR')),
    name VARCHAR(100) NOT NULL,
    representative_name VARCHAR(50),
    business_number VARCHAR(20) UNIQUE,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    address TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE lessor IS '건물 소유주(임대인) 정보';

CREATE TABLE lessor_bank_account (
    bank_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lessor_id UUID NOT NULL,
    bank_name VARCHAR(50) NOT NULL,
    account_number VARCHAR(255) NOT NULL, -- 암호화 필요
    account_holder VARCHAR(50) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    purpose VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE lessor_bank_account IS '임대인 정산 계좌 정보';

CREATE TABLE tenant (
    tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    status VARCHAR(20) NOT NULL DEFAULT 'RESIDING' CHECK (status IN ('RESIDING', 'MOVING_OUT_SCHEDULED', 'MOVED_OUT', 'CONTRACT_PENDING')),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE tenant IS '임차인(세대주) 정보';

CREATE TABLE tenant_vehicle (
    vehicle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    vehicle_number VARCHAR(30) NOT NULL,
    vehicle_model VARCHAR(50),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE tenant_vehicle IS '임차인 등록 차량 정보';


-- ### 4. 임대 계약 관리 (Lease Contract Management) ###

CREATE TABLE lease_contract (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID NOT NULL,
    lessor_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    contract_number VARCHAR(50) UNIQUE,
    contract_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    deposit_amount NUMERIC(15, 2) NOT NULL DEFAULT 0,
    rent_amount NUMERIC(15, 2) NOT NULL DEFAULT 0,
    rent_payment_day VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('SCHEDULED', 'ACTIVE', 'EXPIRING_SOON', 'EXPIRED', 'TERMINATED', 'RENEWED')),
    parent_contract_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT check_contract_dates CHECK (end_date >= start_date)
);
COMMENT ON TABLE lease_contract IS '임대차 계약 정보';


-- ### 5. 관리비 설정 (Fee Item & Policy Setup) ###

CREATE TABLE fee_item (
    fee_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_name VARCHAR(100) NOT NULL UNIQUE,
    item_category VARCHAR(30) NOT NULL,
    imposition_method VARCHAR(30) NOT NULL,
    default_unit_price NUMERIC(15, 2) DEFAULT 0,
    default_unit VARCHAR(20),
    is_vat_applicable BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    is_system_default BOOLEAN NOT NULL DEFAULT false,
    description TEXT,
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE fee_item IS '관리비 부과 항목 마스터 정보';

CREATE TABLE external_bill_account (
    ext_bill_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL,
    customer_number VARCHAR(50) NOT NULL,
    utility_type VARCHAR(30) NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    account_nickname VARCHAR(100) NOT NULL,
    meter_number VARCHAR(50),
    is_for_individual_usage BOOLEAN NOT NULL DEFAULT false,
    is_for_common_usage BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_ext_bill_account UNIQUE (building_id, customer_number, utility_type),
    CONSTRAINT check_usage_purpose CHECK (is_for_individual_usage = true OR is_for_common_usage = true)
);
COMMENT ON TABLE external_bill_account IS '외부 공과금 고지서의 고객번호 정보';

CREATE TABLE bill_to_fee_item_link (
    link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ext_bill_account_id UUID NOT NULL,
    fee_item_id UUID NOT NULL,
    description TEXT,
    allocation_type VARCHAR(30) NOT NULL,
    portion_value_type VARCHAR(30),
    portion_value NUMERIC(15, 4),
    processing_order INTEGER NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE bill_to_fee_item_link IS '외부 고지서 금액을 관리비 항목으로 배분하는 규칙';

CREATE TABLE receiving_bank_account (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_name VARCHAR(50) NOT NULL,
    account_number VARCHAR(255) NOT NULL UNIQUE,
    account_holder VARCHAR(50) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    purpose VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE receiving_bank_account IS '관리비 수납 계좌 정보';

CREATE TABLE payment_policy (
    policy_id VARCHAR(50) PRIMARY KEY,
    payment_due_day VARCHAR(10) NOT NULL,
    late_fee_rate NUMERIC(5, 2) NOT NULL,
    late_fee_calculation_method VARCHAR(30) NOT NULL,
    rounding_policy VARCHAR(30) NOT NULL,
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE payment_policy IS '납부 관련 기본 정책';


-- ### 6. 청구월 및 월별 데이터 관리 (Billing Month & Monthly Data) ###

CREATE TABLE billing_month (
    billing_month_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    status VARCHAR(20) NOT NULL DEFAULT 'PREPARING' CHECK (status IN ('PREPARING', 'IN_PROGRESS', 'COMPLETED')),
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    payment_due_date DATE NOT NULL,
    closed_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_billing_month_period UNIQUE (building_id, year, month)
);
COMMENT ON TABLE billing_month IS '관리비 부과 및 정산의 기준이 되는 청구월 마스터';

CREATE TABLE billing_month_fee_item_setting (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    fee_item_id UUID NOT NULL,
    unit_price NUMERIC(15, 2),
    rate NUMERIC(10, 4),
    is_vat_applicable BOOLEAN,
    data_source VARCHAR(30) NOT NULL
);
COMMENT ON TABLE billing_month_fee_item_setting IS '특정 청구월에 적용될 관리비 항목별 상세 설정값';

CREATE TABLE unit_monthly_previous_meter_reading (
    prev_reading_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    utility_type_code VARCHAR(30) NOT NULL,
    meter_reading_value NUMERIC(15, 2) NOT NULL,
    data_source VARCHAR(30) NOT NULL
);
COMMENT ON TABLE unit_monthly_previous_meter_reading IS '청구월의 시작(전월) 기준 검침값';

CREATE TABLE unit_monthly_unpaid_amount (
    unpaid_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    unpaid_amount NUMERIC(15, 2) NOT NULL,
    data_source VARCHAR(30) NOT NULL
);
COMMENT ON TABLE unit_monthly_unpaid_amount IS '청구월에 이월된 세대별 전월 미납액';

CREATE TABLE common_facility_monthly_reading (
    common_reading_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    facility_id UUID NOT NULL,
    reading_date DATE NOT NULL,
    previous_meter_reading NUMERIC(15, 2) NOT NULL,
    current_meter_reading NUMERIC(15, 2) NOT NULL,
    usage_calculated NUMERIC(15, 2) NOT NULL
);
COMMENT ON TABLE common_facility_monthly_reading IS '공용 시설 월별 검침 데이터';

CREATE TABLE unit_monthly_meter_reading (
    unit_reading_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    utility_type_code VARCHAR(30) NOT NULL,
    reading_date DATE NOT NULL,
    previous_meter_reading NUMERIC(15, 2) NOT NULL,
    current_meter_reading NUMERIC(15, 2) NOT NULL,
    usage_calculated NUMERIC(15, 2) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_unit_monthly_reading UNIQUE (billing_month_id, unit_id, utility_type_code)
);
COMMENT ON TABLE unit_monthly_meter_reading IS '개별 호실 월별 공과금 계량기 검침 데이터';

CREATE TABLE monthly_external_bill_amount (
    monthly_ext_bill_amount_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    ext_bill_account_id UUID NOT NULL,
    total_billed_amount NUMERIC(15, 2) NOT NULL,
    common_usage_allocated_amount NUMERIC(15, 2),
    individual_usage_pool_amount NUMERIC(15, 2),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_monthly_ext_bill UNIQUE (billing_month_id, ext_bill_account_id)
);
COMMENT ON TABLE monthly_external_bill_amount IS '월별 외부 고지서 청구 금액 및 분배 정보';

CREATE TABLE monthly_common_fee (
    monthly_common_fee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    fee_item_id UUID NOT NULL,
    total_amount_for_month NUMERIC(15, 2) NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE monthly_common_fee IS '월별 공용 관리비 총액 (검침 외 항목)';


-- ### 7. 관리비 정산, 고지, 수납 (Fee Calculation, Invoicing, Payment) ###

CREATE TABLE unit_monthly_fee (
    unit_monthly_fee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    billing_month_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    final_amount_due NUMERIC(15, 2) NOT NULL,
    paid_amount NUMERIC(15, 2) NOT NULL DEFAULT 0,
    current_unpaid_balance NUMERIC(15, 2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',
    calculation_status VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE unit_monthly_fee IS '월별 세대 관리비 계산 결과 총괄';

CREATE TABLE unit_fee_detail (
    unit_fee_detail_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_monthly_fee_id UUID NOT NULL,
    fee_item_id UUID NOT NULL,
    item_name VARCHAR(100) NOT NULL,
    calculation_basis VARCHAR(255),
    amount_before_vat NUMERIC(15, 2) NOT NULL,
    vat_amount NUMERIC(15, 2) NOT NULL DEFAULT 0,
    total_amount_with_vat NUMERIC(15, 2) NOT NULL
);
COMMENT ON TABLE unit_fee_detail IS '세대별 월별 관리비 상세 항목';

CREATE TABLE invoice (
    invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_monthly_fee_id UUID NOT NULL,
    issue_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'GENERATED',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE invoice IS '관리비 고지서 정보';

CREATE TABLE payment_record (
    payment_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_monthly_fee_id UUID NOT NULL,
    payment_date DATE NOT NULL,
    paid_amount NUMERIC(15, 2) NOT NULL CHECK (paid_amount > 0),
    payment_method VARCHAR(30) NOT NULL,
    payer_name VARCHAR(50),
    transaction_details VARCHAR(255),
    receiving_bank_account_id UUID,
    remarks TEXT,
    is_cancelled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50)
);
COMMENT ON TABLE payment_record IS '수납 이력';

CREATE TABLE delinquency_record (
    delinquency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_ledger_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    billing_year_month VARCHAR(7) NOT NULL,
    original_unpaid_amount NUMERIC(15, 2) NOT NULL,
    current_unpaid_amount NUMERIC(15, 2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'OVERDUE',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE delinquency_record IS '미납/연체 기록';

CREATE TABLE late_fee_transaction (
    late_fee_tx_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    delinquency_id UUID NOT NULL,
    calculation_date DATE NOT NULL,
    late_fee_amount NUMERIC(15, 2) NOT NULL,
    applied_rate NUMERIC(5, 2) NOT NULL,
    applied_period_days INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE late_fee_transaction IS '연체료 부과 이력';

CREATE TABLE move_out_settlement (
    settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    move_out_date DATE NOT NULL,
    deposit_amount_held NUMERIC(15, 2) NOT NULL,
    calculation_details_json JSONB NOT NULL,
    net_settlement_amount NUMERIC(15, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CALCULATED',
    settlement_processed_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_modified_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE move_out_settlement IS '이사 정산 내역';


-- ### 8. 시설 관리 (Facility Management) - (이전 답변에서 일부 생성됨) ###
-- facility, vendor 테이블은 이전 스크립트에서 생성됨

CREATE TABLE vendor_contact_person (
    contact_person_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL,
    name VARCHAR(50) NOT NULL,
    position VARCHAR(50),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE vendor_contact_person IS '협력업체 담당자 정보';

CREATE TABLE vendor_contract (
    vendor_contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL,
    contract_name VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    terms_summary TEXT,
    contract_file_key VARCHAR(255),
    is_active_contract BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE vendor_contract IS '협력업체 계약 정보';


-- ### 9. 민원 관리 (Complaint Management) - (이전 답변에서 일부 생성됨) ###
-- complaint 테이블은 이전 스크립트에서 생성됨

CREATE TABLE complaint_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    complaint_id UUID NOT NULL,
    action_datetime TIMESTAMPTZ NOT NULL DEFAULT now(),
    actor_user_id UUID NOT NULL,
    action_type VARCHAR(30) NOT NULL,
    previous_status VARCHAR(20),
    new_status VARCHAR(20),
    remarks TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE complaint_history IS '민원 처리 이력';


-- ### 10. 회계 관리 (Accounting Management) ###

CREATE TABLE chart_of_account (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_code VARCHAR(20) NOT NULL UNIQUE,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE')),
    parent_account_id UUID,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true
);
COMMENT ON TABLE chart_of_account IS '회계 계정과목';

CREATE TABLE journal_entry (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_date DATE NOT NULL,
    entry_number VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    entry_type VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50)
);
COMMENT ON TABLE journal_entry IS '회계 전표 헤더';

CREATE TABLE journal_entry_line (
    line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID NOT NULL,
    account_id UUID NOT NULL,
    entry_side VARCHAR(10) NOT NULL CHECK (entry_side IN ('DEBIT', 'CREDIT')),
    amount NUMERIC(18, 2) NOT NULL CHECK (amount >= 0),
    line_description VARCHAR(255)
);
COMMENT ON TABLE journal_entry_line IS '회계 전표 상세 분개 라인';


-- ### 11. 알림 및 공지 (Notification & Announcement Management) ###

CREATE TABLE announcement (
    announcement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    target_type VARCHAR(30) NOT NULL,
    target_identifiers JSONB NOT NULL,
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ,
    importance VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by VARCHAR(50)
);
COMMENT ON TABLE announcement IS '공지사항';

CREATE TABLE notification_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_type VARCHAR(50) NOT NULL,
    reference_id UUID,
    recipient_info VARCHAR(255) NOT NULL,
    channel_type VARCHAR(20) NOT NULL,
    subject VARCHAR(255),
    content TEXT NOT NULL,
    sent_datetime TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(20) NOT NULL,
    error_message TEXT
);
COMMENT ON TABLE notification_log IS '알림 발송 이력';


-- ### 13. 공통 (Common) ###
CREATE TABLE attachment (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    related_entity_type VARCHAR(50) NOT NULL,
    related_entity_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_key_or_path VARCHAR(512) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    uploaded_by VARCHAR(50) NOT NULL
);
COMMENT ON TABLE attachment IS '범용 첨부파일';
```

------

### **Part 2: 외래 키(Foreign Key) 제약조건 추가**

------

SQL

```
-- ### 외래 키(Foreign Key) 제약조건 추가 (테이블 생성 순서에 구애받지 않기 위함) ###

-- user_role_link
ALTER TABLE user_role_link ADD CONSTRAINT fk_userrolelink_user FOREIGN KEY (user_id) REFERENCES internal_user(user_id) ON DELETE CASCADE;
ALTER TABLE user_role_link ADD CONSTRAINT fk_userrolelink_role FOREIGN KEY (role_id) REFERENCES role(role_id) ON DELETE RESTRICT;

-- role_permission_link
ALTER TABLE role_permission_link ADD CONSTRAINT fk_rolepermissionlink_role FOREIGN KEY (role_id) REFERENCES role(role_id) ON DELETE CASCADE;
ALTER TABLE role_permission_link ADD CONSTRAINT fk_rolepermissionlink_permission FOREIGN KEY (permission_id) REFERENCES permission(permission_id) ON DELETE CASCADE;

-- user_building_access
ALTER TABLE user_building_access ADD CONSTRAINT fk_userbuildingaccess_user FOREIGN KEY (user_id) REFERENCES internal_user(user_id) ON DELETE CASCADE;
ALTER TABLE user_building_access ADD CONSTRAINT fk_userbuildingaccess_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE CASCADE;

-- unit
ALTER TABLE unit ADD CONSTRAINT fk_unit_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE RESTRICT;
ALTER TABLE unit ADD CONSTRAINT fk_unit_lessor FOREIGN KEY (current_lessor_id) REFERENCES lessor(lessor_id) ON DELETE SET NULL;
ALTER TABLE unit ADD CONSTRAINT fk_unit_tenant FOREIGN KEY (current_tenant_id) REFERENCES tenant(tenant_id) ON DELETE SET NULL;
ALTER TABLE unit ADD CONSTRAINT fk_unit_leasecontract FOREIGN KEY (current_lease_contract_id) REFERENCES lease_contract(contract_id) ON DELETE SET NULL;

-- lessor_bank_account
ALTER TABLE lessor_bank_account ADD CONSTRAINT fk_lessorbankaccount_lessor FOREIGN KEY (lessor_id) REFERENCES lessor(lessor_id) ON DELETE CASCADE;

-- tenant_vehicle
ALTER TABLE tenant_vehicle ADD CONSTRAINT fk_tenantvehicle_tenant FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON DELETE CASCADE;

-- lease_contract
ALTER TABLE lease_contract ADD CONSTRAINT fk_leasecontract_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE RESTRICT;
ALTER TABLE lease_contract ADD CONSTRAINT fk_leasecontract_lessor FOREIGN KEY (lessor_id) REFERENCES lessor(lessor_id) ON DELETE RESTRICT;
ALTER TABLE lease_contract ADD CONSTRAINT fk_leasecontract_tenant FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON DELETE RESTRICT;
ALTER TABLE lease_contract ADD CONSTRAINT fk_leasecontract_parent FOREIGN KEY (parent_contract_id) REFERENCES lease_contract(contract_id) ON DELETE SET NULL;

-- external_bill_account
ALTER TABLE external_bill_account ADD CONSTRAINT fk_extbillaccount_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE CASCADE;

-- bill_to_fee_item_link
ALTER TABLE bill_to_fee_item_link ADD CONSTRAINT fk_billlink_extbill FOREIGN KEY (ext_bill_account_id) REFERENCES external_bill_account(ext_bill_account_id) ON DELETE CASCADE;
ALTER TABLE bill_to_fee_item_link ADD CONSTRAINT fk_billlink_feeitem FOREIGN KEY (fee_item_id) REFERENCES fee_item(fee_item_id) ON DELETE RESTRICT;

-- billing_month
ALTER TABLE billing_month ADD CONSTRAINT fk_billingmonth_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE RESTRICT;

-- billing_month_fee_item_setting
ALTER TABLE billing_month_fee_item_setting ADD CONSTRAINT fk_bmfis_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE CASCADE;
ALTER TABLE billing_month_fee_item_setting ADD CONSTRAINT fk_bmfis_feeitem FOREIGN KEY (fee_item_id) REFERENCES fee_item(fee_item_id) ON DELETE RESTRICT;

-- unit_monthly_previous_meter_reading
ALTER TABLE unit_monthly_previous_meter_reading ADD CONSTRAINT fk_umpr_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE unit_monthly_previous_meter_reading ADD CONSTRAINT fk_umpr_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE CASCADE;

-- unit_monthly_unpaid_amount
ALTER TABLE unit_monthly_unpaid_amount ADD CONSTRAINT fk_umua_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE unit_monthly_unpaid_amount ADD CONSTRAINT fk_umua_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE CASCADE;

-- common_facility_monthly_reading
ALTER TABLE common_facility_monthly_reading ADD CONSTRAINT fk_cfmr_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE common_facility_monthly_reading ADD CONSTRAINT fk_cfmr_facility FOREIGN KEY (facility_id) REFERENCES facility(facility_id) ON DELETE RESTRICT;

-- unit_monthly_meter_reading
ALTER TABLE unit_monthly_meter_reading ADD CONSTRAINT fk_unitreading_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE unit_monthly_meter_reading ADD CONSTRAINT fk_unitreading_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE CASCADE;

-- monthly_external_bill_amount
ALTER TABLE monthly_external_bill_amount ADD CONSTRAINT fk_meba_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE monthly_external_bill_amount ADD CONSTRAINT fk_meba_extbillaccount FOREIGN KEY (ext_bill_account_id) REFERENCES external_bill_account(ext_bill_account_id) ON DELETE RESTRICT;

-- monthly_common_fee
ALTER TABLE monthly_common_fee ADD CONSTRAINT fk_mcf_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE monthly_common_fee ADD CONSTRAINT fk_mcf_feeitem FOREIGN KEY (fee_item_id) REFERENCES fee_item(fee_item_id) ON DELETE RESTRICT;

-- unit_monthly_fee
ALTER TABLE unit_monthly_fee ADD CONSTRAINT fk_umf_billingmonth FOREIGN KEY (billing_month_id) REFERENCES billing_month(billing_month_id) ON DELETE RESTRICT;
ALTER TABLE unit_monthly_fee ADD CONSTRAINT fk_umf_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE RESTRICT;

-- unit_fee_detail
ALTER TABLE unit_fee_detail ADD CONSTRAINT fk_ufd_unitmonthlyfee FOREIGN KEY (unit_monthly_fee_id) REFERENCES unit_monthly_fee(unit_monthly_fee_id) ON DELETE CASCADE;
ALTER TABLE unit_fee_detail ADD CONSTRAINT fk_ufd_feeitem FOREIGN KEY (fee_item_id) REFERENCES fee_item(fee_item_id) ON DELETE RESTRICT;

-- invoice
ALTER TABLE invoice ADD CONSTRAINT fk_invoice_unitmonthlyfee FOREIGN KEY (unit_monthly_fee_id) REFERENCES unit_monthly_fee(unit_monthly_fee_id) ON DELETE RESTRICT;

-- payment_record
ALTER TABLE payment_record ADD CONSTRAINT fk_payment_unitmonthlyfee FOREIGN KEY (unit_monthly_fee_id) REFERENCES unit_monthly_fee(unit_monthly_fee_id) ON DELETE RESTRICT;
ALTER TABLE payment_record ADD CONSTRAINT fk_payment_invoice FOREIGN KEY (invoice_id) REFERENCES invoice(invoice_id) ON DELETE SET NULL;
ALTER TABLE payment_record ADD CONSTRAINT fk_payment_bankaccount FOREIGN KEY (receiving_bank_account_id) REFERENCES receiving_bank_account(account_id) ON DELETE SET NULL;

-- delinquency_record
ALTER TABLE delinquency_record ADD CONSTRAINT fk_delinquency_ledger FOREIGN KEY (target_ledger_id) REFERENCES unit_monthly_fee(unit_monthly_fee_id) ON DELETE CASCADE;
ALTER TABLE delinquency_record ADD CONSTRAINT fk_delinquency_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE CASCADE;
ALTER TABLE delinquency_record ADD CONSTRAINT fk_delinquency_tenant FOREIGN KEY (tenant_id) REFERENCES tenant(tenant_id) ON DELETE CASCADE;

-- late_fee_transaction
ALTER TABLE late_fee_transaction ADD CONSTRAINT fk_latefee_delinquency FOREIGN KEY (delinquency_id) REFERENCES delinquency_record(delinquency_id) ON DELETE CASCADE;

-- move_out_settlement
ALTER TABLE move_out_settlement ADD CONSTRAINT fk_settlement_contract FOREIGN KEY (contract_id) REFERENCES lease_contract(contract_id) ON DELETE RESTRICT;

-- facility
ALTER TABLE facility ADD CONSTRAINT fk_facility_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE CASCADE;
ALTER TABLE facility ADD CONSTRAINT fk_facility_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE SET NULL;

-- facility_inspection_record
ALTER TABLE facility_inspection_record ADD CONSTRAINT fk_inspection_facility FOREIGN KEY (facility_id) REFERENCES facility(facility_id) ON DELETE CASCADE;
ALTER TABLE facility_inspection_record ADD CONSTRAINT fk_inspection_vendor FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) ON DELETE SET NULL;

-- vendor_contact_person
ALTER TABLE vendor_contact_person ADD CONSTRAINT fk_vendorcontact_vendor FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) ON DELETE CASCADE;

-- vendor_contract
ALTER TABLE vendor_contract ADD CONSTRAINT fk_vendorcontract_vendor FOREIGN KEY (vendor_id) REFERENCES vendor(vendor_id) ON DELETE CASCADE;

-- complaint
ALTER TABLE complaint ADD CONSTRAINT fk_complaint_building FOREIGN KEY (building_id) REFERENCES building(building_id) ON DELETE CASCADE;
ALTER TABLE complaint ADD CONSTRAINT fk_complaint_unit FOREIGN KEY (unit_id) REFERENCES unit(unit_id) ON DELETE SET NULL;
ALTER TABLE complaint ADD CONSTRAINT fk_complaint_assigneduser FOREIGN KEY (assigned_user_id) REFERENCES internal_user(user_id) ON DELETE SET NULL;
ALTER TABLE complaint ADD CONSTRAINT fk_complaint_assignedvendor FOREIGN KEY (assigned_vendor_id) REFERENCES vendor(vendor_id) ON DELETE SET NULL;

-- complaint_history
ALTER TABLE complaint_history ADD CONSTRAINT fk_complainthistory_complaint FOREIGN KEY (complaint_id) REFERENCES complaint(complaint_id) ON DELETE CASCADE;
ALTER TABLE complaint_history ADD CONSTRAINT fk_complainthistory_user FOREIGN KEY (actor_user_id) REFERENCES internal_user(user_id) ON DELETE RESTRICT;

-- chart_of_account
ALTER TABLE chart_of_account ADD CONSTRAINT fk_coa_parent FOREIGN KEY (parent_account_id) REFERENCES chart_of_account(account_id) ON DELETE SET NULL;

-- journal_entry_line
ALTER TABLE journal_entry_line ADD CONSTRAINT fk_jel_journalentry FOREIGN KEY (entry_id) REFERENCES journal_entry(entry_id) ON DELETE CASCADE;
ALTER TABLE journal_entry_line ADD CONSTRAINT fk_jel_coa FOREIGN KEY (account_id) REFERENCES chart_of_account(account_id) ON DELETE RESTRICT;
```

------

### **Part 3: 인덱스(Index) 생성**

------

SQL

```
-- ### 인덱스(Index) 생성 (성능 향상용) ###

-- 건물, 호실, 임대/임차인
CREATE INDEX idx_building_name ON building(building_name);
CREATE INDEX idx_unit_building_id ON unit(building_id);
CREATE INDEX idx_lessor_name ON lessor(name);
CREATE INDEX idx_tenant_name ON tenant(name);

-- 임대 계약
CREATE INDEX idx_lease_contract_unit_id ON lease_contract(unit_id);
CREATE INDEX idx_lease_contract_status ON lease_contract(status);
CREATE INDEX idx_lease_contract_end_date ON lease_contract(end_date);

-- 관리비 관련
CREATE INDEX idx_billing_month_status ON billing_month(status);
CREATE INDEX idx_unit_monthly_reading_unit_id ON unit_monthly_meter_reading(unit_id);
CREATE INDEX idx_unit_monthly_reading_billing_month_id ON unit_monthly_meter_reading(billing_month_id);
CREATE INDEX idx_unit_monthly_fee_unit_id ON unit_monthly_fee(unit_id);
CREATE INDEX idx_payment_record_payment_date ON payment_record(payment_date);

-- 시설 관련
CREATE INDEX idx_facility_name ON facility(name);
CREATE INDEX idx_facility_type_code ON facility(facility_type_code);
CREATE INDEX idx_facility_next_inspection_date ON facility(next_inspection_date);
CREATE INDEX idx_inspection_record_facility_id ON facility_inspection_record(facility_id);
CREATE INDEX idx_inspection_record_date ON facility_inspection_record(inspection_date);

-- 민원 관련
CREATE INDEX idx_complaint_status ON complaint(status);
CREATE INDEX idx_complaint_type_code ON complaint(complaint_type_code);
CREATE INDEX idx_complaint_received_datetime ON complaint(received_datetime);

-- 회계 관련
CREATE INDEX idx_journal_entry_date ON journal_entry(entry_date);
CREATE INDEX idx_journal_entry_line_entry_id ON journal_entry_line(entry_id);
CREATE INDEX idx_journal_entry_line_account_id ON journal_entry_line(account_id);
```

이것으로 지금까지 논의된 모든 엔티티에 대한 DDL 스크립트 작성을 마무리하겠습니다. 이 스크립트는 QIRO 서비스 데이터베이스의 견고한 기반이 될 것입니다. 😊