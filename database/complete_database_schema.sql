-- =====================================================
-- QIRO 건물 관리 SaaS 통합 데이터베이스 스키마
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 건물 관리 업무 프로그램을 위한 완전한 데이터베이스 스키마
-- =====================================================

-- 데이터베이스 생성 (필요시)
-- CREATE DATABASE qiro_building_management;
-- \c qiro_building_management;

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. 기본 ENUM 타입 정의
-- =====================================================

-- 건물 관련 ENUM 타입
CREATE TYPE building_status AS ENUM ('ACTIVE', 'UNDER_CONSTRUCTION', 'MAINTENANCE', 'INACTIVE');
CREATE TYPE building_type AS ENUM ('APARTMENT', 'COMMERCIAL', 'MIXED_USE', 'OFFICE', 'RETAIL', 'WAREHOUSE');
CREATE TYPE unit_status AS ENUM ('AVAILABLE', 'OCCUPIED', 'MAINTENANCE', 'UNAVAILABLE');
CREATE TYPE unit_type AS ENUM ('RESIDENTIAL', 'COMMERCIAL', 'OFFICE', 'STORAGE', 'PARKING', 'COMMON_AREA');

-- 사용자 관련 ENUM 타입
CREATE TYPE entity_type AS ENUM ('INDIVIDUAL', 'CORPORATION', 'PARTNERSHIP');
CREATE TYPE contact_priority AS ENUM ('PRIMARY', 'SECONDARY', 'EMERGENCY');

-- 관리비 관련 ENUM 타입
CREATE TYPE fee_type AS ENUM ('COMMON_MAINTENANCE', 'INDIVIDUAL_UTILITY', 'COMMON_UTILITY', 'SPECIAL_ASSESSMENT', 'LATE_FEE', 'OTHER_CHARGES');
CREATE TYPE calculation_method AS ENUM ('FIXED_AMOUNT', 'UNIT_PRICE', 'AREA_BASED', 'HOUSEHOLD_BASED', 'USAGE_BASED', 'PERCENTAGE_BASED', 'TIERED_RATE');
CREATE TYPE charge_target AS ENUM ('ALL_UNITS', 'OCCUPIED_UNITS', 'RESIDENTIAL_ONLY', 'COMMERCIAL_ONLY', 'SPECIFIC_UNITS', 'BY_FLOOR', 'BY_AREA_RANGE');
CREATE TYPE external_provider AS ENUM ('KEPCO', 'K_WATER', 'CITY_GAS', 'LPG', 'INTERNET', 'CABLE_TV', 'WASTE_MANAGEMENT', 'ELEVATOR', 'SECURITY', 'CLEANING', 'OTHER');
CREATE TYPE payment_method AS ENUM ('BANK_TRANSFER', 'DIRECT_DEBIT', 'CASH', 'CHECK', 'CREDIT_CARD', 'MOBILE_PAYMENT', 'VIRTUAL_ACCOUNT');

-- 청구 및 납부 관련 ENUM 타입
CREATE TYPE billing_month_status AS ENUM ('DRAFT', 'DATA_INPUT', 'CALCULATING', 'CALCULATED', 'INVOICED', 'CLOSED');
CREATE TYPE meter_type AS ENUM ('ELECTRICITY', 'WATER', 'GAS', 'HEATING', 'HOT_WATER', 'COMMON_ELECTRICITY', 'COMMON_WATER');
CREATE TYPE invoice_status AS ENUM ('DRAFT', 'ISSUED', 'SENT', 'VIEWED', 'PAID', 'OVERDUE', 'CANCELLED');
CREATE TYPE fee_calculation_method AS ENUM ('FIXED_AMOUNT', 'UNIT_BASED', 'USAGE_BASED', 'RATIO_BASED', 'EXTERNAL_BILL');

-- 임대차 관련 ENUM 타입
CREATE TYPE lease_contract_status AS ENUM ('DRAFT', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'RENEWED');
CREATE TYPE contract_type AS ENUM ('NEW', 'RENEWAL', 'TRANSFER');
CREATE TYPE rent_payment_status AS ENUM ('PENDING', 'PARTIAL', 'PAID', 'OVERDUE', 'WAIVED');
CREATE TYPE settlement_status AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'DISPUTED', 'CANCELLED');
CREATE TYPE settlement_item_type AS ENUM ('DEPOSIT_REFUND', 'UNPAID_RENT', 'UNPAID_MAINTENANCE', 'LATE_FEE', 'UTILITY_SETTLEMENT', 'REPAIR_COST', 'CLEANING_FEE', 'KEY_REPLACEMENT', 'OTHER_DEDUCTION', 'OTHER_REFUND');

-- 시설 관리 관련 ENUM 타입
CREATE TYPE facility_category AS ENUM ('ELEVATOR', 'HVAC', 'ELECTRICAL', 'PLUMBING', 'FIRE_SAFETY', 'SECURITY', 'PARKING', 'COMMON_AREA', 'EXTERIOR', 'OTHER');
CREATE TYPE facility_status AS ENUM ('ACTIVE', 'MAINTENANCE', 'OUT_OF_ORDER', 'SCHEDULED_MAINTENANCE', 'RETIRED');
CREATE TYPE inspection_type AS ENUM ('ROUTINE', 'PREVENTIVE', 'EMERGENCY', 'LEGAL_REQUIRED', 'WARRANTY');
CREATE TYPE inspection_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE', 'CANCELLED');
CREATE TYPE maintenance_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL');
CREATE TYPE maintenance_request_status AS ENUM ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'REJECTED', 'CANCELLED', 'ON_HOLD');
CREATE TYPE maintenance_work_status AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'FAILED', 'RESCHEDULED');
CREATE TYPE maintenance_request_type AS ENUM ('REPAIR', 'REPLACEMENT', 'UPGRADE', 'PREVENTIVE', 'EMERGENCY', 'INSPECTION', 'CLEANING', 'OTHER');

-- 민원 및 공지 관련 ENUM 타입
CREATE TYPE complaint_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
CREATE TYPE complaint_status AS ENUM ('RECEIVED', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_INFO', 'RESOLVED', 'CLOSED', 'CANCELLED');
CREATE TYPE announcement_target AS ENUM ('ALL', 'TENANTS', 'OWNERS', 'STAFF', 'BUILDING_SPECIFIC', 'UNIT_SPECIFIC', 'CUSTOM');
CREATE TYPE announcement_status AS ENUM ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'EXPIRED', 'CANCELLED');
CREATE TYPE notification_type AS ENUM ('ANNOUNCEMENT', 'COMPLAINT_UPDATE', 'MAINTENANCE_SCHEDULE', 'BILLING_NOTICE', 'CONTRACT_EXPIRY', 'PAYMENT_DUE', 'SYSTEM_ALERT', 'CUSTOM');
CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED');
CREATE TYPE notification_channel AS ENUM ('IN_APP', 'EMAIL', 'SMS', 'PUSH');

-- =====================================================
-- 2. 공통 함수 정의
-- =====================================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 개인정보 암호화 함수 (예시 - 실제 구현 시 적절한 암호화 라이브러리 사용)
CREATE OR REPLACE FUNCTION encrypt_personal_data(data TEXT, key TEXT DEFAULT 'default_key')
RETURNS BYTEA AS $
BEGIN
    -- 실제 구현에서는 AES-256 등의 강력한 암호화 알고리즘 사용
    RETURN encode(data::BYTEA, 'base64')::BYTEA;
END;
$ LANGUAGE plpgsql;

-- 개인정보 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_personal_data(encrypted_data BYTEA, key TEXT DEFAULT 'default_key')
RETURNS TEXT AS $
BEGIN
    -- 실제 구현에서는 해당하는 복호화 알고리즘 사용
    RETURN decode(encrypted_data, 'base64')::TEXT;
END;
$ LANGUAGE plpgsql;

-- 사업자등록번호 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_business_registration_number(brn TEXT)
RETURNS BOOLEAN AS $
DECLARE
    digits INTEGER[];
    check_sum INTEGER;
    calculated_check INTEGER;
BEGIN
    -- 사업자등록번호 형식 검증 (10자리 숫자)
    IF brn IS NULL OR LENGTH(brn) != 10 OR brn !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 각 자리수를 배열로 변환
    FOR i IN 1..10 LOOP
        digits[i] := SUBSTRING(brn FROM i FOR 1)::INTEGER;
    END LOOP;
    
    -- 체크섬 계산
    check_sum := digits[1] * 1 + digits[2] * 3 + digits[3] * 7 + digits[4] * 1 + 
                 digits[5] * 3 + digits[6] * 7 + digits[7] * 1 + digits[8] * 3 + 
                 (digits[9] * 5) % 10;
    
    calculated_check := (10 - (check_sum % 10)) % 10;
    
    -- 마지막 자리수와 계산된 체크 디지트 비교
    RETURN calculated_check = digits[10];
END;
$ LANGUAGE plpgsql;-- ==
===================================================
-- 3. 사용자 및 권한 관리 테이블
-- =====================================================

-- 사용자 역할 테이블
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 사용자 정보 테이블
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role_id BIGINT NOT NULL REFERENCES roles(id),
    organization_id BIGINT,
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- =====================================================
-- 4. 건물 및 호실 정보 테이블
-- =====================================================

-- 건물 정보 테이블
CREATE TABLE buildings (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    building_type building_type NOT NULL,
    total_floors INTEGER NOT NULL CHECK (total_floors > 0),
    basement_floors INTEGER DEFAULT 0 CHECK (basement_floors >= 0),
    total_area DECIMAL(12,2) NOT NULL CHECK (total_area > 0),
    total_units INTEGER DEFAULT 0 CHECK (total_units >= 0),
    construction_year INTEGER CHECK (construction_year > 1900 AND construction_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    completion_date DATE,
    building_permit_number VARCHAR(100),
    owner_name VARCHAR(255),
    owner_contact VARCHAR(100),
    owner_business_number VARCHAR(20),
    management_company VARCHAR(255),
    management_contact VARCHAR(100),
    status building_status DEFAULT 'ACTIVE',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 호실 정보 테이블
CREATE TABLE units (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    unit_number VARCHAR(50) NOT NULL,
    floor_number INTEGER NOT NULL,
    unit_type unit_type NOT NULL,
    area DECIMAL(10,2) NOT NULL CHECK (area > 0),
    common_area DECIMAL(10,2) DEFAULT 0 CHECK (common_area >= 0),
    total_area DECIMAL(10,2) GENERATED ALWAYS AS (area + common_area) STORED,
    monthly_rent DECIMAL(12,2) DEFAULT 0 CHECK (monthly_rent >= 0),
    deposit DECIMAL(12,2) DEFAULT 0 CHECK (deposit >= 0),
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0),
    status unit_status DEFAULT 'AVAILABLE',
    room_count INTEGER CHECK (room_count >= 0),
    bathroom_count INTEGER CHECK (bathroom_count >= 0),
    has_balcony BOOLEAN DEFAULT false,
    has_parking BOOLEAN DEFAULT false,
    heating_type VARCHAR(50),
    air_conditioning BOOLEAN DEFAULT false,
    elevator_access BOOLEAN DEFAULT false,
    description TEXT,
    special_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT uk_building_unit_number UNIQUE (building_id, unit_number)
);

-- =====================================================
-- 5. 임대인 및 임차인 정보 테이블
-- =====================================================

-- 임대인 정보 테이블
CREATE TABLE lessors (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    entity_type entity_type NOT NULL DEFAULT 'INDIVIDUAL',
    resident_number_encrypted BYTEA,
    birth_date DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    business_registration_number VARCHAR(20),
    corporate_registration_number VARCHAR(20),
    representative_name VARCHAR(255),
    business_type VARCHAR(100),
    establishment_date DATE,
    primary_phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    email VARCHAR(255),
    fax VARCHAR(20),
    address TEXT,
    postal_code VARCHAR(10),
    detailed_address TEXT,
    bank_name VARCHAR(100),
    account_number_encrypted BYTEA,
    account_holder VARCHAR(255),
    tax_id VARCHAR(20),
    tax_office VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    privacy_consent BOOLEAN DEFAULT false,
    privacy_consent_date TIMESTAMP,
    marketing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 임차인 정보 테이블
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    entity_type entity_type NOT NULL DEFAULT 'INDIVIDUAL',
    resident_number_encrypted BYTEA,
    birth_date DATE,
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    nationality VARCHAR(50) DEFAULT 'KR',
    business_registration_number VARCHAR(20),
    corporate_registration_number VARCHAR(20),
    representative_name VARCHAR(255),
    business_type VARCHAR(100),
    establishment_date DATE,
    primary_phone VARCHAR(20),
    secondary_phone VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    current_address TEXT,
    permanent_address TEXT,
    postal_code VARCHAR(10),
    detailed_address TEXT,
    occupation VARCHAR(100),
    employer VARCHAR(255),
    monthly_income DECIMAL(12,2),
    income_proof_type VARCHAR(50),
    credit_score INTEGER CHECK (credit_score >= 0 AND credit_score <= 1000),
    credit_rating VARCHAR(10),
    family_members INTEGER DEFAULT 1 CHECK (family_members >= 1),
    has_pets BOOLEAN DEFAULT false,
    pet_details TEXT,
    previous_rental_experience BOOLEAN DEFAULT false,
    rental_references TEXT,
    is_active BOOLEAN DEFAULT true,
    blacklist_status BOOLEAN DEFAULT false,
    blacklist_reason TEXT,
    notes TEXT,
    privacy_consent BOOLEAN DEFAULT false,
    privacy_consent_date TIMESTAMP,
    marketing_consent BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 연락처 정보 테이블 (확장 가능한 연락처 관리)
CREATE TABLE contacts (
    id BIGSERIAL PRIMARY KEY,
    lessor_id BIGINT REFERENCES lessors(id) ON DELETE CASCADE,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE CASCADE,
    contact_type VARCHAR(20) NOT NULL,
    contact_value VARCHAR(255) NOT NULL,
    priority contact_priority DEFAULT 'SECONDARY',
    label VARCHAR(100),
    is_verified BOOLEAN DEFAULT false,
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_contact_owner CHECK (
        (lessor_id IS NOT NULL AND tenant_id IS NULL) OR
        (lessor_id IS NULL AND tenant_id IS NOT NULL)
    )
);

-- =====================================================
-- 6. 관리비 항목 및 정책 테이블
-- =====================================================

-- 관리비 항목 테이블
CREATE TABLE fee_items (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    description TEXT,
    fee_type fee_type NOT NULL,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    calculation_method calculation_method NOT NULL,
    charge_target charge_target NOT NULL DEFAULT 'ALL_UNITS',
    unit_price DECIMAL(12,2),
    fixed_amount DECIMAL(12,2),
    minimum_amount DECIMAL(12,2) DEFAULT 0,
    maximum_amount DECIMAL(12,2),
    percentage_rate DECIMAL(5,4),
    base_amount DECIMAL(12,2),
    tiered_rates JSONB,
    is_taxable BOOLEAN DEFAULT false,
    tax_rate DECIMAL(5,4) DEFAULT 0.1000,
    tax_type VARCHAR(50) DEFAULT 'VAT',
    apply_conditions JSONB,
    exclude_conditions JSONB,
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY',
    proration_method VARCHAR(50),
    external_provider external_provider,
    external_account_required BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE,
    effective_to DATE,
    display_order INTEGER DEFAULT 0,
    account_code VARCHAR(20),
    cost_center VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 납부 정책 테이블
CREATE TABLE payment_policies (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    policy_name VARCHAR(255) NOT NULL,
    description TEXT,
    payment_due_day INTEGER NOT NULL CHECK (payment_due_day BETWEEN 1 AND 31),
    grace_period_days INTEGER DEFAULT 0 CHECK (grace_period_days >= 0),
    late_fee_rate DECIMAL(5,4) NOT NULL DEFAULT 0.0200,
    late_fee_calculation_method VARCHAR(50) DEFAULT 'COMPOUND',
    minimum_late_fee DECIMAL(12,2) DEFAULT 0,
    maximum_late_fee DECIMAL(12,2),
    late_fee_grace_days INTEGER DEFAULT 0,
    early_payment_discount_rate DECIMAL(5,4) DEFAULT 0,
    early_payment_days INTEGER DEFAULT 0,
    bulk_payment_discount_rate DECIMAL(5,4) DEFAULT 0,
    allowed_payment_methods JSONB,
    preferred_payment_method payment_method,
    bank_name VARCHAR(100),
    account_number VARCHAR(100),
    account_holder VARCHAR(255),
    virtual_account_prefix VARCHAR(20),
    auto_debit_enabled BOOLEAN DEFAULT false,
    auto_debit_day INTEGER CHECK (auto_debit_day BETWEEN 1 AND 31),
    auto_debit_retry_days INTEGER DEFAULT 3,
    invoice_delivery_method VARCHAR(50) DEFAULT 'EMAIL',
    invoice_send_days_before INTEGER DEFAULT 7,
    reminder_send_days JSONB,
    installment_allowed BOOLEAN DEFAULT false,
    max_installments INTEGER DEFAULT 1,
    installment_fee DECIMAL(12,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 외부 고지서 계정 테이블
CREATE TABLE external_bill_accounts (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    provider_name VARCHAR(100) NOT NULL,
    provider_type external_provider NOT NULL,
    provider_code VARCHAR(50),
    account_number VARCHAR(100) NOT NULL,
    account_name VARCHAR(255),
    contract_number VARCHAR(100),
    usage_purpose VARCHAR(100),
    service_type VARCHAR(100),
    meter_number VARCHAR(100),
    rate_plan VARCHAR(100),
    base_charge DECIMAL(12,2) DEFAULT 0,
    unit_price DECIMAL(12,4),
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY',
    billing_day INTEGER,
    payment_due_day INTEGER,
    connected_units JSONB,
    allocation_method VARCHAR(50),
    allocation_ratios JSONB,
    auto_import_enabled BOOLEAN DEFAULT false,
    api_endpoint VARCHAR(500),
    api_credentials_encrypted BYTEA,
    last_import_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    connection_status VARCHAR(20) DEFAULT 'MANUAL',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT uk_building_provider_account UNIQUE (building_id, provider_type, account_number)
);

-- 관리비 계산 메타데이터 테이블
CREATE TABLE fee_calculation_metadata (
    id BIGSERIAL PRIMARY KEY,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE CASCADE,
    metadata_key VARCHAR(100) NOT NULL,
    metadata_value TEXT,
    data_type VARCHAR(20) DEFAULT 'STRING',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_fee_item_metadata_key UNIQUE (fee_item_id, metadata_key)
);-
- =====================================================
-- 7. 월별 관리비 처리 워크플로우 테이블
-- =====================================================

-- 청구월 관리 테이블
CREATE TABLE billing_months (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    billing_year INTEGER NOT NULL CHECK (billing_year >= 2020 AND billing_year <= 2100),
    billing_month INTEGER NOT NULL CHECK (billing_month >= 1 AND billing_month <= 12),
    status billing_month_status DEFAULT 'DRAFT' NOT NULL,
    due_date DATE NOT NULL,
    calculation_completed_at TIMESTAMP,
    invoice_generation_completed_at TIMESTAMP,
    closed_at TIMESTAMP,
    external_bill_total_amount DECIMAL(15,2) DEFAULT 0 CHECK (external_bill_total_amount >= 0),
    external_bill_input_completed BOOLEAN DEFAULT false,
    meter_reading_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(building_id, billing_year, billing_month),
    CONSTRAINT check_calculation_completed_when_calculated 
        CHECK (status != 'CALCULATED' OR calculation_completed_at IS NOT NULL),
    CONSTRAINT check_invoice_completed_when_invoiced 
        CHECK (status != 'INVOICED' OR invoice_generation_completed_at IS NOT NULL),
    CONSTRAINT check_closed_when_closed 
        CHECK (status != 'CLOSED' OR closed_at IS NOT NULL)
);

-- 호실별 검침 데이터 테이블
CREATE TABLE unit_meter_readings (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    meter_type meter_type NOT NULL,
    previous_reading DECIMAL(12,3) CHECK (previous_reading >= 0),
    current_reading DECIMAL(12,3) CHECK (current_reading >= 0),
    usage_amount DECIMAL(12,3) GENERATED ALWAYS AS (
        CASE 
            WHEN current_reading IS NOT NULL AND previous_reading IS NOT NULL 
            THEN current_reading - previous_reading
            ELSE NULL
        END
    ) STORED,
    unit_price DECIMAL(10,4) CHECK (unit_price >= 0),
    calculated_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        CASE 
            WHEN usage_amount IS NOT NULL AND unit_price IS NOT NULL 
            THEN usage_amount * unit_price
            ELSE NULL
        END
    ) STORED,
    reading_date DATE,
    meter_serial_number VARCHAR(50),
    reader_name VARCHAR(100),
    notes TEXT,
    is_estimated BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    verification_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(billing_month_id, unit_id, meter_type),
    CONSTRAINT check_current_reading_gte_previous 
        CHECK (current_reading IS NULL OR previous_reading IS NULL OR current_reading >= previous_reading),
    CONSTRAINT check_usage_amount_positive 
        CHECK (usage_amount IS NULL OR usage_amount >= 0),
    CONSTRAINT check_reading_date_reasonable 
        CHECK (reading_date IS NULL OR reading_date >= '2020-01-01' AND reading_date <= CURRENT_DATE + INTERVAL '1 month')
);

-- 공용 시설 검침 데이터 테이블
CREATE TABLE common_meter_readings (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    meter_type meter_type NOT NULL,
    previous_reading DECIMAL(12,3) CHECK (previous_reading >= 0),
    current_reading DECIMAL(12,3) CHECK (current_reading >= 0),
    usage_amount DECIMAL(12,3) GENERATED ALWAYS AS (
        CASE 
            WHEN current_reading IS NOT NULL AND previous_reading IS NOT NULL 
            THEN current_reading - previous_reading
            ELSE NULL
        END
    ) STORED,
    unit_price DECIMAL(10,4) CHECK (unit_price >= 0),
    total_amount DECIMAL(15,2) CHECK (total_amount >= 0),
    reading_date DATE,
    meter_serial_number VARCHAR(50),
    meter_location VARCHAR(200),
    reader_name VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(billing_month_id, building_id, meter_type, meter_serial_number),
    CONSTRAINT check_common_current_reading_gte_previous 
        CHECK (current_reading IS NULL OR previous_reading IS NULL OR current_reading >= previous_reading),
    CONSTRAINT check_common_usage_amount_positive 
        CHECK (usage_amount IS NULL OR usage_amount >= 0)
);

-- 월별 관리비 산정 결과 테이블
CREATE TABLE monthly_fees (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE RESTRICT,
    calculation_method fee_calculation_method NOT NULL,
    base_amount DECIMAL(15,2),
    unit_price DECIMAL(12,4),
    quantity DECIMAL(12,3),
    ratio_percentage DECIMAL(5,2),
    calculated_amount DECIMAL(12,2) NOT NULL CHECK (calculated_amount >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    final_amount DECIMAL(12,2) GENERATED ALWAYS AS (calculated_amount + tax_amount) STORED,
    calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calculation_notes TEXT,
    is_manual_adjustment BOOLEAN DEFAULT false,
    adjustment_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(billing_month_id, unit_id, fee_item_id),
    CONSTRAINT check_fixed_amount_calculation 
        CHECK (calculation_method != 'FIXED_AMOUNT' OR calculated_amount IS NOT NULL),
    CONSTRAINT check_unit_based_calculation 
        CHECK (calculation_method != 'UNIT_BASED' OR (unit_price IS NOT NULL AND quantity IS NOT NULL)),
    CONSTRAINT check_usage_based_calculation 
        CHECK (calculation_method != 'USAGE_BASED' OR (unit_price IS NOT NULL AND quantity IS NOT NULL)),
    CONSTRAINT check_ratio_based_calculation 
        CHECK (calculation_method != 'RATIO_BASED' OR (base_amount IS NOT NULL AND ratio_percentage IS NOT NULL)),
    CONSTRAINT check_ratio_percentage_valid 
        CHECK (ratio_percentage IS NULL OR (ratio_percentage >= 0 AND ratio_percentage <= 100)),
    CONSTRAINT check_manual_adjustment_reason 
        CHECK (is_manual_adjustment = false OR adjustment_reason IS NOT NULL)
);

-- 관리비 계산 검증 테이블 (복식부기 원칙 적용)
CREATE TABLE fee_calculation_verification (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE RESTRICT,
    total_base_amount DECIMAL(15,2),
    total_calculated_amount DECIMAL(15,2) NOT NULL,
    total_allocated_amount DECIMAL(15,2) NOT NULL,
    variance_amount DECIMAL(15,2) GENERATED ALWAYS AS (total_calculated_amount - total_allocated_amount) STORED,
    is_balanced BOOLEAN GENERATED ALWAYS AS (ABS(variance_amount) < 0.01) STORED,
    verification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_by BIGINT REFERENCES users(id),
    UNIQUE(billing_month_id, fee_item_id)
);

-- 고지서 테이블
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE DEFAULT CURRENT_DATE NOT NULL,
    due_date DATE NOT NULL,
    subtotal_amount DECIMAL(12,2) NOT NULL CHECK (subtotal_amount >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (subtotal_amount + tax_amount) STORED,
    previous_balance DECIMAL(12,2) DEFAULT 0 CHECK (previous_balance >= 0),
    late_fee DECIMAL(12,2) DEFAULT 0 CHECK (late_fee >= 0),
    final_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_amount + previous_balance + late_fee) STORED,
    status invoice_status DEFAULT 'DRAFT' NOT NULL,
    delivery_method VARCHAR(20),
    delivery_address TEXT,
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    paid_amount DECIMAL(12,2) DEFAULT 0 CHECK (paid_amount >= 0),
    remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (final_amount - paid_amount) STORED,
    fully_paid_at TIMESTAMP,
    notes TEXT,
    special_instructions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(billing_month_id, unit_id),
    CONSTRAINT check_due_date_after_issue_date CHECK (due_date >= issue_date),
    CONSTRAINT check_paid_amount_not_exceed_final CHECK (paid_amount <= final_amount),
    CONSTRAINT check_sent_when_sent_status CHECK (status != 'SENT' OR sent_at IS NOT NULL),
    CONSTRAINT check_viewed_when_viewed_status CHECK (status != 'VIEWED' OR viewed_at IS NOT NULL),
    CONSTRAINT check_fully_paid_when_paid_status CHECK (status != 'PAID' OR fully_paid_at IS NOT NULL)
);

-- 고지서 상세 항목 테이블
CREATE TABLE invoice_line_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    monthly_fee_id BIGINT NOT NULL REFERENCES monthly_fees(id) ON DELETE CASCADE,
    fee_item_name VARCHAR(255) NOT NULL,
    description TEXT,
    quantity DECIMAL(12,3),
    unit_price DECIMAL(12,4),
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    tax_rate DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (amount + tax_amount) STORED,
    display_order INTEGER DEFAULT 0,
    UNIQUE(invoice_id, monthly_fee_id)
);

-- 수납 내역 테이블
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('CASH', 'BANK_TRANSFER', 'CARD', 'CMS', 'VIRTUAL_ACCOUNT')),
    payment_reference VARCHAR(100),
    notes TEXT,
    payment_status VARCHAR(20) DEFAULT 'COMPLETED' CHECK (payment_status IN ('PENDING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
    processed_by BIGINT REFERENCES users(id),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 미납 관리 테이블
CREATE TABLE delinquencies (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    overdue_amount DECIMAL(12,2) NOT NULL CHECK (overdue_amount >= 0),
    overdue_days INTEGER NOT NULL CHECK (overdue_days >= 0),
    late_fee DECIMAL(12,2) DEFAULT 0 CHECK (late_fee >= 0),
    late_fee_rate DECIMAL(5,2) NOT NULL CHECK (late_fee_rate >= 0 AND late_fee_rate <= 100),
    grace_period_days INTEGER DEFAULT 0 CHECK (grace_period_days >= 0),
    status VARCHAR(20) DEFAULT 'OVERDUE' CHECK (status IN ('OVERDUE', 'PARTIAL_PAID', 'RESOLVED', 'WRITTEN_OFF')),
    first_overdue_date DATE NOT NULL,
    last_calculated_date DATE DEFAULT CURRENT_DATE,
    resolution_date DATE,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(invoice_id)
);

-- 수납 상세 내역 테이블
CREATE TABLE payment_details (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id),
    allocated_amount DECIMAL(12,2) NOT NULL CHECK (allocated_amount > 0),
    is_late_fee BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 연체료 계산 이력 테이블
CREATE TABLE late_fee_calculations (
    id BIGSERIAL PRIMARY KEY,
    delinquency_id BIGINT NOT NULL REFERENCES delinquencies(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,
    overdue_amount DECIMAL(12,2) NOT NULL,
    overdue_days INTEGER NOT NULL,
    daily_rate DECIMAL(8,6) NOT NULL,
    calculated_late_fee DECIMAL(12,2) NOT NULL,
    cumulative_late_fee DECIMAL(12,2) NOT NULL,
    calculation_method VARCHAR(50) NOT NULL DEFAULT 'SIMPLE_INTEREST',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 8. 임대차 관리 워크플로우 테이블
-- =====================================================

-- 임대 계약 테이블
CREATE TABLE lease_contracts (
    id BIGSERIAL PRIMARY KEY,
    contract_number VARCHAR(50) UNIQUE NOT NULL,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE RESTRICT,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    lessor_id BIGINT NOT NULL REFERENCES lessors(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(12,2) NOT NULL CHECK (monthly_rent >= 0),
    deposit DECIMAL(12,2) NOT NULL CHECK (deposit >= 0),
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0),
    contract_type contract_type NOT NULL DEFAULT 'NEW',
    contract_terms TEXT,
    special_conditions TEXT,
    status lease_contract_status NOT NULL DEFAULT 'DRAFT',
    previous_contract_id BIGINT REFERENCES lease_contracts(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT chk_lease_contract_dates CHECK (end_date > start_date),
    CONSTRAINT chk_lease_contract_amounts CHECK (monthly_rent > 0 OR deposit > 0)
);

-- 계약 상태 변경 이력 테이블
CREATE TABLE lease_contract_status_history (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
    previous_status lease_contract_status,
    new_status lease_contract_status NOT NULL,
    change_reason VARCHAR(255),
    change_description TEXT,
    changed_by BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    supporting_documents JSONB
);

-- 계약 갱신 알림 설정 테이블
CREATE TABLE lease_contract_renewal_alerts (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
    alert_days_before INTEGER NOT NULL DEFAULT 30,
    is_enabled BOOLEAN DEFAULT true,
    notify_lessor BOOLEAN DEFAULT true,
    notify_tenant BOOLEAN DEFAULT true,
    notify_manager BOOLEAN DEFAULT true,
    last_notification_sent_at TIMESTAMP,
    notification_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 월별 임대료 관리 테이블
CREATE TABLE monthly_rents (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE RESTRICT,
    rent_year INTEGER NOT NULL,
    rent_month INTEGER NOT NULL CHECK (rent_month BETWEEN 1 AND 12),
    rent_amount DECIMAL(12,2) NOT NULL CHECK (rent_amount >= 0),
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0),
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (rent_amount + maintenance_fee) STORED,
    due_date DATE NOT NULL,
    payment_status rent_payment_status NOT NULL DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0 CHECK (paid_amount >= 0),
    remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (rent_amount + maintenance_fee - paid_amount) STORED,
    paid_date DATE,
    overdue_days INTEGER DEFAULT 0 CHECK (overdue_days >= 0),
    late_fee_rate DECIMAL(5,4) DEFAULT 0.0000 CHECK (late_fee_rate >= 0),
    late_fee_amount DECIMAL(12,2) DEFAULT 0 CHECK (late_fee_amount >= 0),
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT uk_monthly_rents_contract_period UNIQUE (lease_contract_id, rent_year, rent_month),
    CONSTRAINT chk_monthly_rents_paid_amount CHECK (paid_amount <= rent_amount + maintenance_fee + late_fee_amount)
);

-- 임대료 납부 내역 테이블
CREATE TABLE rent_payments (
    id BIGSERIAL PRIMARY KEY,
    monthly_rent_id BIGINT NOT NULL REFERENCES monthly_rents(id) ON DELETE RESTRICT,
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL CHECK (payment_amount > 0),
    payment_method VARCHAR(50) NOT NULL,
    payment_reference VARCHAR(100),
    rent_portion DECIMAL(12,2) DEFAULT 0 CHECK (rent_portion >= 0),
    maintenance_portion DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_portion >= 0),
    late_fee_portion DECIMAL(12,2) DEFAULT 0 CHECK (late_fee_portion >= 0),
    notes TEXT,
    receipt_file_path VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    CONSTRAINT chk_rent_payments_portions CHECK (
        rent_portion + maintenance_portion + late_fee_portion = payment_amount
    )
);

-- 임대료 연체 관리 테이블
CREATE TABLE rent_delinquencies (
    id BIGSERIAL PRIMARY KEY,
    monthly_rent_id BIGINT NOT NULL REFERENCES monthly_rents(id) ON DELETE CASCADE,
    overdue_amount DECIMAL(12,2) NOT NULL CHECK (overdue_amount > 0),
    overdue_start_date DATE NOT NULL,
    overdue_days INTEGER NOT NULL CHECK (overdue_days > 0),
    late_fee_rate DECIMAL(5,4) NOT NULL CHECK (late_fee_rate >= 0),
    calculated_late_fee DECIMAL(12,2) NOT NULL CHECK (calculated_late_fee >= 0),
    applied_late_fee DECIMAL(12,2) NOT NULL CHECK (applied_late_fee >= 0),
    is_resolved BOOLEAN DEFAULT false,
    resolved_date DATE,
    resolution_method VARCHAR(50),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT chk_rent_delinquencies_resolved CHECK (
        (is_resolved = false AND resolved_date IS NULL) OR
        (is_resolved = true AND resolved_date IS NOT NULL)
    )
);

-- 퇴실 정산 테이블
CREATE TABLE move_out_settlements (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE RESTRICT,
    settlement_number VARCHAR(50) UNIQUE NOT NULL,
    move_out_date DATE NOT NULL,
    move_out_reason VARCHAR(100),
    notice_date DATE,
    settlement_start_date DATE NOT NULL,
    settlement_end_date DATE NOT NULL,
    original_deposit DECIMAL(12,2) NOT NULL CHECK (original_deposit >= 0),
    total_deductions DECIMAL(12,2) DEFAULT 0 CHECK (total_deductions >= 0),
    total_additional_charges DECIMAL(12,2) DEFAULT 0 CHECK (total_additional_charges >= 0),
    final_refund_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        original_deposit - total_deductions + total_additional_charges
    ) STORED,
    status settlement_status NOT NULL DEFAULT 'PENDING',
    settlement_date DATE,
    refund_method VARCHAR(50),
    refund_account_info JSONB,
    refund_completed_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);--
 =====================================================
-- 9. 시설 유지보수 관리 테이블
-- =====================================================

-- 시설물 정보 테이블
CREATE TABLE facilities (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    facility_code VARCHAR(50) NOT NULL,
    facility_name VARCHAR(255) NOT NULL,
    category facility_category NOT NULL,
    subcategory VARCHAR(100),
    location_description TEXT,
    floor_number INTEGER,
    room_number VARCHAR(50),
    manufacturer VARCHAR(255),
    model_number VARCHAR(255),
    serial_number VARCHAR(255),
    specifications JSONB,
    installation_date DATE,
    installation_cost DECIMAL(15,2),
    warranty_start_date DATE,
    warranty_end_date DATE,
    warranty_provider VARCHAR(255),
    maintenance_cycle_months INTEGER DEFAULT 12,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    maintenance_cost_budget DECIMAL(15,2),
    status facility_status DEFAULT 'ACTIVE',
    expected_lifespan_years INTEGER,
    replacement_due_date DATE,
    disposal_date DATE,
    notes TEXT,
    attachments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT facilities_building_code_unique UNIQUE (building_id, facility_code),
    CONSTRAINT facilities_installation_warranty_check 
        CHECK (warranty_start_date IS NULL OR installation_date IS NULL OR warranty_start_date >= installation_date),
    CONSTRAINT facilities_warranty_period_check 
        CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date),
    CONSTRAINT facilities_maintenance_cycle_check 
        CHECK (maintenance_cycle_months > 0 AND maintenance_cycle_months <= 120),
    CONSTRAINT facilities_lifespan_check 
        CHECK (expected_lifespan_years IS NULL OR expected_lifespan_years > 0)
);

-- 시설물 점검 계획 테이블
CREATE TABLE facility_inspection_schedules (
    id BIGSERIAL PRIMARY KEY,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    inspection_type inspection_type NOT NULL,
    inspection_name VARCHAR(255) NOT NULL,
    description TEXT,
    scheduled_date DATE NOT NULL,
    estimated_duration_hours DECIMAL(4,2),
    assigned_to BIGINT,
    vendor_id BIGINT,
    inspection_checklist JSONB,
    required_tools JSONB,
    safety_requirements TEXT,
    status inspection_status DEFAULT 'SCHEDULED',
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    estimated_cost DECIMAL(12,2),
    actual_cost DECIMAL(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT inspection_schedules_duration_check 
        CHECK (estimated_duration_hours IS NULL OR estimated_duration_hours > 0),
    CONSTRAINT inspection_schedules_cost_check 
        CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT inspection_schedules_actual_cost_check 
        CHECK (actual_cost IS NULL OR actual_cost >= 0),
    CONSTRAINT inspection_schedules_time_check 
        CHECK (actual_end_time IS NULL OR actual_start_time IS NULL OR actual_end_time >= actual_start_time)
);

-- 시설물 점검 결과 테이블
CREATE TABLE facility_inspection_results (
    id BIGSERIAL PRIMARY KEY,
    schedule_id BIGINT NOT NULL REFERENCES facility_inspection_schedules(id) ON DELETE CASCADE,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    inspection_date DATE NOT NULL,
    inspector_name VARCHAR(255) NOT NULL,
    inspector_certification VARCHAR(255),
    overall_condition VARCHAR(50) NOT NULL,
    detailed_findings JSONB,
    issues_found JSONB,
    recommendations TEXT,
    next_inspection_due_date DATE,
    next_inspection_type inspection_type,
    photos JSONB,
    documents JSONB,
    approved_by BIGINT,
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT inspection_results_condition_check 
        CHECK (overall_condition IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'CRITICAL'))
);

-- 시설물 생애주기 이력 테이블
CREATE TABLE facility_lifecycle_history (
    id BIGSERIAL PRIMARY KEY,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_date DATE NOT NULL,
    event_description TEXT NOT NULL,
    cost DECIMAL(15,2),
    vendor_id BIGINT,
    previous_status facility_status,
    new_status facility_status,
    performance_metrics JSONB,
    documents JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    CONSTRAINT lifecycle_history_event_type_check 
        CHECK (event_type IN ('INSTALLED', 'MAINTAINED', 'REPAIRED', 'UPGRADED', 'RETIRED', 'INSPECTED')),
    CONSTRAINT lifecycle_history_cost_check 
        CHECK (cost IS NULL OR cost >= 0)
);

-- 유지보수 요청 테이블
CREATE TABLE maintenance_requests (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    facility_id BIGINT REFERENCES facilities(id) ON DELETE SET NULL,
    unit_id BIGINT REFERENCES units(id) ON DELETE SET NULL,
    request_number VARCHAR(50) UNIQUE NOT NULL,
    request_type maintenance_request_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    requester_name VARCHAR(255) NOT NULL,
    requester_contact VARCHAR(100),
    requester_email VARCHAR(255),
    requester_type VARCHAR(50) NOT NULL,
    requester_unit_id BIGINT REFERENCES units(id),
    priority maintenance_priority DEFAULT 'MEDIUM',
    status maintenance_request_status DEFAULT 'SUBMITTED',
    urgency_reason TEXT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    preferred_date DATE,
    preferred_time_start TIME,
    preferred_time_end TIME,
    assigned_to BIGINT,
    assigned_at TIMESTAMP,
    estimated_cost DECIMAL(12,2),
    approved_budget DECIMAL(12,2),
    completed_at TIMESTAMP,
    completion_notes TEXT,
    requester_satisfaction INTEGER,
    requester_feedback TEXT,
    attachments JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT maintenance_requests_requester_type_check 
        CHECK (requester_type IN ('TENANT', 'LESSOR', 'MANAGER', 'STAFF', 'EXTERNAL')),
    CONSTRAINT maintenance_requests_satisfaction_check 
        CHECK (requester_satisfaction IS NULL OR (requester_satisfaction >= 1 AND requester_satisfaction <= 5)),
    CONSTRAINT maintenance_requests_cost_check 
        CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT maintenance_requests_budget_check 
        CHECK (approved_budget IS NULL OR approved_budget >= 0),
    CONSTRAINT maintenance_requests_time_check 
        CHECK (preferred_time_end IS NULL OR preferred_time_start IS NULL OR preferred_time_end > preferred_time_start)
);

-- 협력업체 테이블
CREATE TABLE facility_vendors (
    id BIGSERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    business_registration_number VARCHAR(20),
    specialization VARCHAR(100),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 유지보수 작업 테이블
CREATE TABLE maintenance_works (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
    facility_id BIGINT REFERENCES facilities(id) ON DELETE SET NULL,
    vendor_id BIGINT REFERENCES facility_vendors(id) ON DELETE SET NULL,
    work_order_number VARCHAR(50) UNIQUE NOT NULL,
    work_title VARCHAR(255) NOT NULL,
    work_description TEXT NOT NULL,
    work_type maintenance_request_type NOT NULL,
    scheduled_start_date DATE NOT NULL,
    scheduled_end_date DATE,
    scheduled_start_time TIME,
    scheduled_end_time TIME,
    actual_start_time TIMESTAMP,
    actual_end_time TIMESTAMP,
    actual_duration_hours DECIMAL(6,2),
    primary_worker_name VARCHAR(255),
    worker_count INTEGER DEFAULT 1,
    worker_details JSONB,
    supervisor_name VARCHAR(255),
    labor_cost DECIMAL(12,2) DEFAULT 0,
    material_cost DECIMAL(12,2) DEFAULT 0,
    equipment_cost DECIMAL(12,2) DEFAULT 0,
    other_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) GENERATED ALWAYS AS (
        COALESCE(labor_cost, 0) + COALESCE(material_cost, 0) + 
        COALESCE(equipment_cost, 0) + COALESCE(other_cost, 0)
    ) STORED,
    materials_used JSONB,
    parts_replaced JSONB,
    tools_used JSONB,
    status maintenance_work_status DEFAULT 'SCHEDULED',
    work_quality_rating INTEGER,
    completion_percentage INTEGER DEFAULT 0,
    work_result_summary TEXT,
    issues_encountered TEXT,
    recommendations TEXT,
    safety_measures_taken TEXT,
    permits_obtained JSONB,
    regulations_compliance BOOLEAN DEFAULT true,
    inspection_required BOOLEAN DEFAULT false,
    inspected_by BIGINT,
    inspected_at TIMESTAMP,
    inspection_notes TEXT,
    warranty_period_months INTEGER,
    warranty_start_date DATE,
    warranty_end_date DATE,
    warranty_terms TEXT,
    before_photos JSONB,
    after_photos JSONB,
    work_documents JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    CONSTRAINT maintenance_works_schedule_check 
        CHECK (scheduled_end_date IS NULL OR scheduled_end_date >= scheduled_start_date),
    CONSTRAINT maintenance_works_time_check 
        CHECK (scheduled_end_time IS NULL OR scheduled_start_time IS NULL OR scheduled_end_time > scheduled_start_time),
    CONSTRAINT maintenance_works_actual_time_check 
        CHECK (actual_end_time IS NULL OR actual_start_time IS NULL OR actual_end_time >= actual_start_time),
    CONSTRAINT maintenance_works_cost_check 
        CHECK (labor_cost >= 0 AND material_cost >= 0 AND equipment_cost >= 0 AND other_cost >= 0),
    CONSTRAINT maintenance_works_quality_check 
        CHECK (work_quality_rating IS NULL OR (work_quality_rating >= 1 AND work_quality_rating <= 5)),
    CONSTRAINT maintenance_works_completion_check 
        CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    CONSTRAINT maintenance_works_worker_count_check 
        CHECK (worker_count > 0),
    CONSTRAINT maintenance_works_warranty_check 
        CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date)
);

-- =====================================================
-- 10. 민원 처리 관리 테이블
-- =====================================================

-- 민원 분류 코드 테이블
CREATE TABLE complaint_categories (
    id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    default_priority VARCHAR(20) DEFAULT 'MEDIUM',
    default_sla_hours INTEGER DEFAULT 72,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 관리 테이블
CREATE TABLE complaints (
    id BIGSERIAL PRIMARY KEY,
    complaint_number VARCHAR(20) UNIQUE NOT NULL,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    unit_id BIGINT REFERENCES units(id),
    category_id BIGINT NOT NULL REFERENCES complaint_categories(id),
    complainant_name VARCHAR(255) NOT NULL,
    complainant_contact VARCHAR(100),
    complainant_email VARCHAR(255),
    complainant_type VARCHAR(20) DEFAULT 'TENANT',
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location_detail VARCHAR(255),
    priority complaint_priority NOT NULL DEFAULT 'MEDIUM',
    status complaint_status NOT NULL DEFAULT 'RECEIVED',
    urgency_reason TEXT,
    assigned_to BIGINT REFERENCES users(id),
    assigned_at TIMESTAMP,
    assigned_by BIGINT REFERENCES users(id),
    sla_due_at TIMESTAMP NOT NULL,
    sla_hours INTEGER NOT NULL,
    is_sla_breached BOOLEAN DEFAULT false,
    sla_breach_reason TEXT,
    resolution TEXT,
    resolution_cost DECIMAL(12,2) DEFAULT 0,
    satisfaction_score INTEGER CHECK (satisfaction_score >= 1 AND satisfaction_score <= 5),
    satisfaction_comment TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    CONSTRAINT chk_resolution_required CHECK (
        (status IN ('RESOLVED', 'CLOSED') AND resolution IS NOT NULL) OR 
        (status NOT IN ('RESOLVED', 'CLOSED'))
    ),
    CONSTRAINT chk_resolved_at_required CHECK (
        (status IN ('RESOLVED', 'CLOSED') AND resolved_at IS NOT NULL) OR 
        (status NOT IN ('RESOLVED', 'CLOSED'))
    )
);

-- 민원 처리 이력 테이블
CREATE TABLE complaint_histories (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    previous_status complaint_status,
    new_status complaint_status,
    previous_assignee BIGINT REFERENCES users(id),
    new_assignee BIGINT REFERENCES users(id),
    comment TEXT,
    action_by BIGINT NOT NULL REFERENCES users(id),
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 첨부파일 테이블
CREATE TABLE complaint_attachments (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 댓글/메모 테이블
CREATE TABLE complaint_comments (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    comment_type VARCHAR(20) DEFAULT 'INTERNAL',
    content TEXT NOT NULL,
    is_visible_to_complainant BOOLEAN DEFAULT false,
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 11. 공지사항 및 알림 관리 테이블
-- =====================================================

-- 공지사항 분류 코드 테이블
CREATE TABLE announcement_categories (
    id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 테이블
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    announcement_number VARCHAR(20) UNIQUE NOT NULL,
    building_id BIGINT REFERENCES buildings(id),
    category_id BIGINT NOT NULL REFERENCES announcement_categories(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary VARCHAR(500),
    target_audience announcement_target NOT NULL DEFAULT 'ALL',
    is_urgent BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    allow_comments BOOLEAN DEFAULT false,
    status announcement_status NOT NULL DEFAULT 'DRAFT',
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    auto_expire BOOLEAN DEFAULT false,
    has_attachments BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    created_by BIGINT NOT NULL REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_published_at_required CHECK (
        (status = 'PUBLISHED' AND published_at IS NOT NULL) OR 
        (status != 'PUBLISHED')
    ),
    CONSTRAINT chk_expires_at_valid CHECK (
        expires_at IS NULL OR expires_at > published_at
    )
);

-- 공지사항 대상자 테이블
CREATE TABLE announcement_targets (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL,
    target_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 첨부파일 테이블
CREATE TABLE announcement_attachments (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    download_count INTEGER DEFAULT 0,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 댓글 테이블
CREATE TABLE announcement_comments (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    parent_comment_id BIGINT REFERENCES announcement_comments(id),
    commenter_name VARCHAR(255) NOT NULL,
    commenter_contact VARCHAR(100),
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    approved_by BIGINT REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 조회 이력 테이블
CREATE TABLE announcement_views (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    viewer_type VARCHAR(20) NOT NULL,
    viewer_id BIGINT,
    viewer_ip INET,
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(announcement_id, viewer_id, DATE(viewed_at))
);

-- 알림 테이블
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    notification_number VARCHAR(20) UNIQUE NOT NULL,
    recipient_type VARCHAR(20) NOT NULL,
    recipient_id BIGINT NOT NULL,
    recipient_name VARCHAR(255),
    recipient_contact VARCHAR(100),
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    channels notification_channel[] NOT NULL DEFAULT ARRAY['IN_APP'],
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5),
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    status notification_status NOT NULL DEFAULT 'PENDING',
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    failed_reason TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retry INTEGER DEFAULT 3,
    related_entity_type VARCHAR(50),
    related_entity_id BIGINT,
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 알림 템플릿 테이블
CREATE TABLE notification_templates (
    id BIGSERIAL PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    notification_type notification_type NOT NULL,
    title_template VARCHAR(255) NOT NULL,
    message_template TEXT NOT NULL,
    default_channels notification_channel[] NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 사용자별 알림 설정 테이블
CREATE TABLE user_notification_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    notification_type notification_type NOT NULL,
    enabled_channels notification_channel[] NOT NULL DEFAULT ARRAY['IN_APP'],
    is_enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_type)
);-- ===
==================================================
-- 12. 회계 관리 테이블
-- =====================================================

-- 계정과목 테이블
CREATE TABLE chart_of_accounts (
    id BIGSERIAL PRIMARY KEY,
    account_code VARCHAR(20) UNIQUE NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE')),
    parent_account_id BIGINT REFERENCES chart_of_accounts(id),
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 회계 전표 테이블
CREATE TABLE journal_entries (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    entry_date DATE NOT NULL,
    reference_number VARCHAR(50),
    description TEXT NOT NULL,
    total_debit DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_credit DECIMAL(15,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'POSTED', 'REVERSED')),
    posted_at TIMESTAMP,
    reversed_at TIMESTAMP,
    reversal_reason TEXT,
    created_by BIGINT NOT NULL,
    posted_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_debit_credit_balance CHECK (total_debit = total_credit)
);

-- 회계 전표 상세 테이블
CREATE TABLE journal_entry_details (
    id BIGSERIAL PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL REFERENCES journal_entries(id) ON DELETE CASCADE,
    account_id BIGINT NOT NULL REFERENCES chart_of_accounts(id),
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    description TEXT,
    reference_document_type VARCHAR(50),
    reference_document_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_debit_or_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (debit_amount = 0 AND credit_amount > 0)
    )
);

-- 회계 기간 테이블
CREATE TABLE accounting_periods (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    period_year INTEGER NOT NULL,
    period_month INTEGER NOT NULL CHECK (period_month BETWEEN 1 AND 12),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED', 'LOCKED')),
    closed_at TIMESTAMP,
    closed_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, period_year, period_month)
);

-- 계정별 잔액 테이블
CREATE TABLE account_balances (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    account_id BIGINT NOT NULL REFERENCES chart_of_accounts(id),
    period_id BIGINT NOT NULL REFERENCES accounting_periods(id),
    opening_balance DECIMAL(15,2) DEFAULT 0,
    debit_total DECIMAL(15,2) DEFAULT 0,
    credit_total DECIMAL(15,2) DEFAULT 0,
    closing_balance DECIMAL(15,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, account_id, period_id)
);

-- 재무제표 템플릿 테이블
CREATE TABLE financial_statement_templates (
    id BIGSERIAL PRIMARY KEY,
    template_name VARCHAR(255) NOT NULL,
    statement_type VARCHAR(50) NOT NULL CHECK (statement_type IN ('BALANCE_SHEET', 'INCOME_STATEMENT', 'CASH_FLOW')),
    template_structure JSONB NOT NULL,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 13. 시스템 환경설정 테이블
-- =====================================================

-- 조직 설정 테이블
CREATE TABLE organization_settings (
    id BIGSERIAL PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    business_registration_number VARCHAR(20),
    representative_name VARCHAR(255),
    address TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    locale VARCHAR(10) DEFAULT 'ko_KR',
    currency VARCHAR(3) DEFAULT 'KRW',
    date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
    fiscal_year_start_month INTEGER DEFAULT 1 CHECK (fiscal_year_start_month BETWEEN 1 AND 12),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id)
);

-- 시스템 설정 테이블
CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json', 'encrypted')),
    category VARCHAR(50) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    is_encrypted BOOLEAN DEFAULT false,
    validation_rule JSONB,
    default_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id)
);

-- 설정 변경 이력 테이블
CREATE TABLE setting_change_history (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    changed_by BIGINT REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- 외부 서비스 설정 테이블
CREATE TABLE external_service_configs (
    id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL,
    config_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_test_mode BOOLEAN DEFAULT false,
    api_endpoint VARCHAR(500),
    api_key_encrypted TEXT,
    last_health_check TIMESTAMP,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'unhealthy', 'unknown')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    UNIQUE(service_name, service_type)
);

-- 시스템 상태 모니터링 테이블
CREATE TABLE system_health_logs (
    id BIGSERIAL PRIMARY KEY,
    component VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'warning', 'critical', 'unknown')),
    response_time_ms INTEGER,
    error_message TEXT,
    additional_data JSONB,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 14. 권한 및 감사 로그 테이블
-- =====================================================

-- 사용자-건물 접근 권한 테이블
CREATE TABLE user_building_access (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    access_level VARCHAR(20) NOT NULL DEFAULT 'read' CHECK (access_level IN ('read', 'write', 'admin')),
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, building_id)
);

-- 권한 매트릭스 테이블
CREATE TABLE permission_matrix (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    is_allowed BOOLEAN DEFAULT false,
    conditions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_id, resource, action)
);

-- 사용자 세션 테이블
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 감사 로그 테이블
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[],
    user_id BIGINT REFERENCES users(id),
    session_id BIGINT REFERENCES user_sessions(id),
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    building_id BIGINT REFERENCES buildings(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 로그인 이력 테이블
CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    username VARCHAR(50) NOT NULL,
    login_type VARCHAR(20) NOT NULL CHECK (login_type IN ('SUCCESS', 'FAILED', 'LOCKED', 'LOGOUT')),
    ip_address INET,
    user_agent TEXT,
    failure_reason VARCHAR(100),
    session_id BIGINT REFERENCES user_sessions(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 비밀번호 재설정 토큰 테이블
CREATE TABLE password_reset_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 15. 인덱스 생성
-- =====================================================

-- 사용자 및 권한 관련 인덱스
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_user_building_access_user_id ON user_building_access(user_id);
CREATE INDEX idx_user_building_access_building_id ON user_building_access(building_id);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_permission_matrix_role_resource ON permission_matrix(role_id, resource);

-- 건물 및 호실 관련 인덱스
CREATE INDEX idx_buildings_name ON buildings(name);
CREATE INDEX idx_buildings_type ON buildings(building_type);
CREATE INDEX idx_buildings_status ON buildings(status);
CREATE INDEX idx_buildings_created_at ON buildings(created_at);
CREATE INDEX idx_units_building_id ON units(building_id);
CREATE INDEX idx_units_floor_number ON units(floor_number);
CREATE INDEX idx_units_unit_type ON units(unit_type);
CREATE INDEX idx_units_status ON units(status);
CREATE INDEX idx_units_area ON units(area);
CREATE INDEX idx_units_monthly_rent ON units(monthly_rent);

-- 임대인 및 임차인 관련 인덱스
CREATE INDEX idx_lessors_name ON lessors(name);
CREATE INDEX idx_lessors_entity_type ON lessors(entity_type);
CREATE INDEX idx_lessors_business_number ON lessors(business_registration_number);
CREATE INDEX idx_lessors_email ON lessors(email);
CREATE INDEX idx_lessors_is_active ON lessors(is_active);
CREATE INDEX idx_lessors_created_at ON lessors(created_at);
CREATE INDEX idx_tenants_name ON tenants(name);
CREATE INDEX idx_tenants_entity_type ON tenants(entity_type);
CREATE INDEX idx_tenants_business_number ON tenants(business_registration_number);
CREATE INDEX idx_tenants_email ON tenants(email);
CREATE INDEX idx_tenants_primary_phone ON tenants(primary_phone);
CREATE INDEX idx_tenants_is_active ON tenants(is_active);
CREATE INDEX idx_tenants_blacklist_status ON tenants(blacklist_status);
CREATE INDEX idx_tenants_created_at ON tenants(created_at);
CREATE INDEX idx_contacts_lessor_id ON contacts(lessor_id);
CREATE INDEX idx_contacts_tenant_id ON contacts(tenant_id);
CREATE INDEX idx_contacts_type ON contacts(contact_type);
CREATE INDEX idx_contacts_priority ON contacts(priority);

-- 관리비 관련 인덱스
CREATE INDEX idx_fee_items_building_id ON fee_items(building_id);
CREATE INDEX idx_fee_items_fee_type ON fee_items(fee_type);
CREATE INDEX idx_fee_items_calculation_method ON fee_items(calculation_method);
CREATE INDEX idx_fee_items_charge_target ON fee_items(charge_target);
CREATE INDEX idx_fee_items_is_active ON fee_items(is_active);
CREATE INDEX idx_fee_items_external_provider ON fee_items(external_provider);
CREATE INDEX idx_fee_items_effective_dates ON fee_items(effective_from, effective_to);
CREATE INDEX idx_fee_items_display_order ON fee_items(display_order);
CREATE INDEX idx_payment_policies_building_id ON payment_policies(building_id);
CREATE INDEX idx_payment_policies_is_active ON payment_policies(is_active);
CREATE INDEX idx_payment_policies_effective_dates ON payment_policies(effective_from, effective_to);
CREATE INDEX idx_external_accounts_building_id ON external_bill_accounts(building_id);
CREATE INDEX idx_external_accounts_provider_type ON external_bill_accounts(provider_type);
CREATE INDEX idx_external_accounts_account_number ON external_bill_accounts(account_number);
CREATE INDEX idx_external_accounts_is_active ON external_bill_accounts(is_active);
CREATE INDEX idx_external_accounts_connection_status ON external_bill_accounts(connection_status);
CREATE INDEX idx_fee_metadata_fee_item_id ON fee_calculation_metadata(fee_item_id);
CREATE INDEX idx_fee_metadata_key ON fee_calculation_metadata(metadata_key);

-- 청구 및 납부 관련 인덱스
CREATE INDEX idx_billing_months_building_year_month ON billing_months(building_id, billing_year, billing_month);
CREATE INDEX idx_billing_months_status ON billing_months(status);
CREATE INDEX idx_billing_months_due_date ON billing_months(due_date);
CREATE INDEX idx_billing_months_created_at ON billing_months(created_at);
CREATE INDEX idx_unit_meter_readings_billing_month ON unit_meter_readings(billing_month_id);
CREATE INDEX idx_unit_meter_readings_unit ON unit_meter_readings(unit_id);
CREATE INDEX idx_unit_meter_readings_type ON unit_meter_readings(meter_type);
CREATE INDEX idx_unit_meter_readings_billing_unit_type ON unit_meter_readings(billing_month_id, unit_id, meter_type);
CREATE INDEX idx_unit_meter_readings_reading_date ON unit_meter_readings(reading_date);
CREATE INDEX idx_unit_meter_readings_verification ON unit_meter_readings(is_verified) WHERE is_verified = false;
CREATE INDEX idx_common_meter_readings_billing_month ON common_meter_readings(billing_month_id);
CREATE INDEX idx_common_meter_readings_building ON common_meter_readings(building_id);
CREATE INDEX idx_common_meter_readings_type ON common_meter_readings(meter_type);
CREATE INDEX idx_monthly_fees_billing_month ON monthly_fees(billing_month_id);
CREATE INDEX idx_monthly_fees_unit ON monthly_fees(unit_id);
CREATE INDEX idx_monthly_fees_fee_item ON monthly_fees(fee_item_id);
CREATE INDEX idx_monthly_fees_calculation_method ON monthly_fees(calculation_method);
CREATE INDEX idx_monthly_fees_manual_adjustment ON monthly_fees(is_manual_adjustment) WHERE is_manual_adjustment = true;
CREATE INDEX idx_invoices_billing_month ON invoices(billing_month_id);
CREATE INDEX idx_invoices_unit ON invoices(unit_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_issue_date ON invoices(issue_date);
CREATE INDEX idx_invoices_remaining_amount ON invoices(remaining_amount) WHERE remaining_amount > 0;
CREATE INDEX idx_invoice_line_items_invoice ON invoice_line_items(invoice_id);
CREATE INDEX idx_invoice_line_items_monthly_fee ON invoice_line_items(monthly_fee_id);
CREATE INDEX idx_invoice_line_items_display_order ON invoice_line_items(invoice_id, display_order);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
CREATE INDEX idx_payments_payment_method ON payments(payment_method);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_processed_by ON payments(processed_by);
CREATE INDEX idx_delinquencies_status ON delinquencies(status);
CREATE INDEX idx_delinquencies_overdue_days ON delinquencies(overdue_days);
CREATE INDEX idx_delinquencies_first_overdue_date ON delinquencies(first_overdue_date);
CREATE INDEX idx_delinquencies_last_calculated_date ON delinquencies(last_calculated_date);
CREATE INDEX idx_payment_details_payment_id ON payment_details(payment_id);
CREATE INDEX idx_payment_details_fee_item_id ON payment_details(fee_item_id);
CREATE INDEX idx_late_fee_calculations_delinquency_id ON late_fee_calculations(delinquency_id);
CREATE INDEX idx_late_fee_calculations_calculation_date ON late_fee_calculations(calculation_date);

-- 임대차 관련 인덱스
CREATE INDEX idx_lease_contracts_unit_id ON lease_contracts(unit_id);
CREATE INDEX idx_lease_contracts_tenant_id ON lease_contracts(tenant_id);
CREATE INDEX idx_lease_contracts_lessor_id ON lease_contracts(lessor_id);
CREATE INDEX idx_lease_contracts_status ON lease_contracts(status);
CREATE INDEX idx_lease_contracts_dates ON lease_contracts(start_date, end_date);
CREATE INDEX idx_lease_contracts_end_date ON lease_contracts(end_date) WHERE status = 'ACTIVE';
CREATE INDEX idx_lease_contracts_contract_number ON lease_contracts(contract_number);
CREATE UNIQUE INDEX idx_lease_contracts_unit_period_unique 
ON lease_contracts(unit_id, start_date, end_date) 
WHERE status IN ('ACTIVE', 'DRAFT');
CREATE INDEX idx_lease_contract_status_history_contract_id ON lease_contract_status_history(lease_contract_id);
CREATE INDEX idx_lease_contract_status_history_changed_at ON lease_contract_status_history(changed_at);
CREATE INDEX idx_lease_contract_renewal_alerts_contract_id ON lease_contract_renewal_alerts(lease_contract_id);
CREATE INDEX idx_monthly_rents_lease_contract_id ON monthly_rents(lease_contract_id);
CREATE INDEX idx_monthly_rents_period ON monthly_rents(rent_year, rent_month);
CREATE INDEX idx_monthly_rents_due_date ON monthly_rents(due_date);
CREATE INDEX idx_monthly_rents_payment_status ON monthly_rents(payment_status);
CREATE INDEX idx_monthly_rents_overdue ON monthly_rents(payment_status, due_date) 
WHERE payment_status IN ('PENDING', 'PARTIAL', 'OVERDUE');
CREATE INDEX idx_rent_payments_monthly_rent_id ON rent_payments(monthly_rent_id);
CREATE INDEX idx_rent_payments_payment_date ON rent_payments(payment_date);
CREATE INDEX idx_rent_delinquencies_monthly_rent_id ON rent_delinquencies(monthly_rent_id);
CREATE INDEX idx_rent_delinquencies_overdue_start_date ON rent_delinquencies(overdue_start_date);
CREATE INDEX idx_rent_delinquencies_unresolved ON rent_delinquencies(is_resolved, overdue_start_date) 
WHERE is_resolved = false;

-- 시설 관리 관련 인덱스
CREATE INDEX idx_facilities_building_id ON facilities(building_id);
CREATE INDEX idx_facilities_category ON facilities(category);
CREATE INDEX idx_facilities_status ON facilities(status);
CREATE INDEX idx_facilities_next_maintenance ON facilities(next_maintenance_date) WHERE next_maintenance_date IS NOT NULL;
CREATE INDEX idx_facilities_warranty_expiry ON facilities(warranty_end_date) WHERE warranty_end_date IS NOT NULL;
CREATE INDEX idx_facilities_replacement_due ON facilities(replacement_due_date) WHERE replacement_due_date IS NOT NULL;
CREATE INDEX idx_facilities_location ON facilities(building_id, floor_number, room_number);
CREATE INDEX idx_inspection_schedules_facility_id ON facility_inspection_schedules(facility_id);
CREATE INDEX idx_inspection_schedules_scheduled_date ON facility_inspection_schedules(scheduled_date);
CREATE INDEX idx_inspection_schedules_status ON facility_inspection_schedules(status);
CREATE INDEX idx_inspection_schedules_assigned_to ON facility_inspection_schedules(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_inspection_schedules_vendor_id ON facility_inspection_schedules(vendor_id) WHERE vendor_id IS NOT NULL;
CREATE INDEX idx_inspection_schedules_overdue ON facility_inspection_schedules(scheduled_date, status) 
    WHERE status IN ('SCHEDULED', 'IN_PROGRESS');
CREATE INDEX idx_inspection_results_schedule_id ON facility_inspection_results(schedule_id);
CREATE INDEX idx_inspection_results_facility_id ON facility_inspection_results(facility_id);
CREATE INDEX idx_inspection_results_inspection_date ON facility_inspection_results(inspection_date);
CREATE INDEX idx_inspection_results_condition ON facility_inspection_results(overall_condition);
CREATE INDEX idx_inspection_results_next_due ON facility_inspection_results(next_inspection_due_date) 
    WHERE next_inspection_due_date IS NOT NULL;
CREATE INDEX idx_lifecycle_history_facility_id ON facility_lifecycle_history(facility_id);
CREATE INDEX idx_lifecycle_history_event_date ON facility_lifecycle_history(event_date);
CREATE INDEX idx_lifecycle_history_event_type ON facility_lifecycle_history(event_type);
CREATE INDEX idx_lifecycle_history_vendor_id ON facility_lifecycle_history(vendor_id) WHERE vendor_id IS NOT NULL;
CREATE INDEX idx_maintenance_requests_building_id ON maintenance_requests(building_id);
CREATE INDEX idx_maintenance_requests_facility_id ON maintenance_requests(facility_id);
CREATE INDEX idx_maintenance_requests_status ON maintenance_requests(status);
CREATE INDEX idx_maintenance_requests_priority ON maintenance_requests(priority);
CREATE INDEX idx_maintenance_requests_assigned_to ON maintenance_requests(assigned_to);
CREATE INDEX idx_maintenance_requests_requested_at ON maintenance_requests(requested_at);
CREATE INDEX idx_maintenance_works_request_id ON maintenance_works(request_id);
CREATE INDEX idx_maintenance_works_facility_id ON maintenance_works(facility_id);
CREATE INDEX idx_maintenance_works_vendor_id ON maintenance_works(vendor_id);
CREATE INDEX idx_maintenance_works_status ON maintenance_works(status);
CREATE INDEX idx_maintenance_works_scheduled_date ON maintenance_works(scheduled_start_date);

-- 민원 관련 인덱스
CREATE INDEX idx_complaints_building_id ON complaints(building_id);
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id);
CREATE INDEX idx_complaints_category_id ON complaints(category_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_priority ON complaints(priority);
CREATE INDEX idx_complaints_assigned_to ON complaints(assigned_to);
CREATE INDEX idx_complaints_submitted_at ON complaints(submitted_at);
CREATE INDEX idx_complaints_sla_due_at ON complaints(sla_due_at);
CREATE INDEX idx_complaints_number ON complaints(complaint_number);
CREATE INDEX idx_complaint_histories_complaint_id ON complaint_histories(complaint_id);
CREATE INDEX idx_complaint_histories_action_at ON complaint_histories(action_at);
CREATE INDEX idx_complaint_attachments_complaint_id ON complaint_attachments(complaint_id);
CREATE INDEX idx_complaint_comments_complaint_id ON complaint_comments(complaint_id);

-- 공지사항 및 알림 관련 인덱스
CREATE INDEX idx_announcements_building_id ON announcements(building_id);
CREATE INDEX idx_announcements_category_id ON announcements(category_id);
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_announcements_published_at ON announcements(published_at);
CREATE INDEX idx_announcements_expires_at ON announcements(expires_at);
CREATE INDEX idx_announcements_target_audience ON announcements(target_audience);
CREATE INDEX idx_announcements_is_urgent ON announcements(is_urgent);
CREATE INDEX idx_announcements_is_pinned ON announcements(is_pinned);
CREATE INDEX idx_announcements_number ON announcements(announcement_number);
CREATE INDEX idx_announcement_targets_announcement_id ON announcement_targets(announcement_id);
CREATE INDEX idx_announcement_targets_type_id ON announcement_targets(target_type, target_id);
CREATE INDEX idx_announcement_attachments_announcement_id ON announcement_attachments(announcement_id);
CREATE INDEX idx_announcement_comments_announcement_id ON announcement_comments(announcement_id);
CREATE INDEX idx_announcement_comments_parent_id ON announcement_comments(parent_comment_id);
CREATE INDEX idx_announcement_views_announcement_id ON announcement_views(announcement_id);
CREATE INDEX idx_announcement_views_viewer ON announcement_views(viewer_id, viewed_at);
CREATE INDEX idx_notifications_recipient ON notifications(recipient_type, recipient_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);
CREATE INDEX idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);
CREATE INDEX idx_notifications_number ON notifications(notification_number);
CREATE INDEX idx_notification_templates_code ON notification_templates(template_code);
CREATE INDEX idx_notification_templates_type ON notification_templates(notification_type);
CREATE INDEX idx_user_notification_settings_user_type ON user_notification_settings(user_id, notification_type);

-- 회계 관련 인덱스
CREATE INDEX idx_journal_entries_building_date ON journal_entries(building_id, entry_date);
CREATE INDEX idx_journal_entries_status ON journal_entries(status);
CREATE INDEX idx_journal_entries_reference ON journal_entries(reference_number);
CREATE INDEX idx_journal_entry_details_journal_id ON journal_entry_details(journal_entry_id);
CREATE INDEX idx_journal_entry_details_account_id ON journal_entry_details(account_id);
CREATE INDEX idx_account_balances_building_period ON account_balances(building_id, period_id);
CREATE INDEX idx_chart_of_accounts_code ON chart_of_accounts(account_code);
CREATE INDEX idx_chart_of_accounts_type ON chart_of_accounts(account_type);

-- 시스템 설정 관련 인덱스
CREATE INDEX idx_system_settings_category ON system_settings(category);
CREATE INDEX idx_system_settings_key ON system_settings(setting_key);
CREATE INDEX idx_setting_change_history_key ON setting_change_history(setting_key);
CREATE INDEX idx_setting_change_history_changed_at ON setting_change_history(changed_at);
CREATE INDEX idx_external_service_configs_service ON external_service_configs(service_name, service_type);
CREATE INDEX idx_system_health_logs_component ON system_health_logs(component);
CREATE INDEX idx_system_health_logs_checked_at ON system_health_logs(checked_at);

-- 감사 로그 관련 인덱스
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_building_id ON audit_logs(building_id);
CREATE INDEX idx_login_history_user_id ON login_history(user_id);
CREATE INDEX idx_login_history_created_at ON login_history(created_at);-- ==
===================================================
-- 16. 트리거 함수들
-- =====================================================

-- 건물의 총 호실 수 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_building_total_units()
RETURNS TRIGGER AS $
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE buildings 
        SET total_units = (
            SELECT COUNT(*) 
            FROM units 
            WHERE building_id = NEW.building_id
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.building_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE buildings 
        SET total_units = (
            SELECT COUNT(*) 
            FROM units 
            WHERE building_id = OLD.building_id
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.building_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$ LANGUAGE plpgsql;

-- 호실 번호 중복 검증 함수
CREATE OR REPLACE FUNCTION validate_unit_number_uniqueness()
RETURNS TRIGGER AS $
BEGIN
    IF EXISTS (
        SELECT 1 FROM units 
        WHERE building_id = NEW.building_id 
        AND unit_number = NEW.unit_number 
        AND id != COALESCE(NEW.id, 0)
    ) THEN
        RAISE EXCEPTION '동일 건물 내에 중복된 호실 번호가 존재합니다: %', NEW.unit_number;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 사업자등록번호 유효성 검증 트리거 함수
CREATE OR REPLACE FUNCTION validate_business_number_trigger()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.business_registration_number IS NOT NULL THEN
        IF NOT validate_business_registration_number(NEW.business_registration_number) THEN
            RAISE EXCEPTION '유효하지 않은 사업자등록번호입니다: %', NEW.business_registration_number;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 관리비 항목 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_fee_item_configuration()
RETURNS TRIGGER AS $
BEGIN
    CASE NEW.calculation_method
        WHEN 'FIXED_AMOUNT' THEN
            IF NEW.fixed_amount IS NULL OR NEW.fixed_amount <= 0 THEN
                RAISE EXCEPTION '고정금액 계산 방식에서는 fixed_amount가 필수입니다.';
            END IF;
        WHEN 'UNIT_PRICE' THEN
            IF NEW.unit_price IS NULL OR NEW.unit_price <= 0 THEN
                RAISE EXCEPTION '단가 계산 방식에서는 unit_price가 필수입니다.';
            END IF;
        WHEN 'PERCENTAGE_BASED' THEN
            IF NEW.percentage_rate IS NULL OR NEW.percentage_rate <= 0 THEN
                RAISE EXCEPTION '비율 계산 방식에서는 percentage_rate가 필수입니다.';
            END IF;
        WHEN 'TIERED_RATE' THEN
            IF NEW.tiered_rates IS NULL THEN
                RAISE EXCEPTION '누진요금제에서는 tiered_rates 설정이 필수입니다.';
            END IF;
    END CASE;
    
    IF NEW.external_provider IS NOT NULL AND NEW.external_account_required = true THEN
        IF NOT EXISTS (
            SELECT 1 FROM external_bill_accounts 
            WHERE building_id = NEW.building_id 
            AND provider_type = NEW.external_provider 
            AND is_active = true
        ) THEN
            RAISE EXCEPTION '외부 제공업체 연동을 위해서는 해당 업체의 활성 계정이 필요합니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 납부 정책 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_payment_policy()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.late_fee_rate < 0 OR NEW.late_fee_rate > 0.1000 THEN
        RAISE EXCEPTION '연체료율은 0%에서 10% 사이여야 합니다.';
    END IF;
    
    IF NEW.early_payment_discount_rate < 0 OR NEW.early_payment_discount_rate > 0.5000 THEN
        RAISE EXCEPTION '조기납부 할인율은 0%에서 50% 사이여야 합니다.';
    END IF;
    
    IF NEW.auto_debit_enabled = true THEN
        IF NEW.bank_name IS NULL OR NEW.account_number IS NULL OR NEW.account_holder IS NULL THEN
            RAISE EXCEPTION '자동출금 사용 시 은행 정보가 필수입니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 검침 데이터 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_meter_reading_consistency()
RETURNS TRIGGER AS $
BEGIN
    -- 이전 월의 현재 검침값과 이번 월의 이전 검침값이 일치하는지 확인
    IF NEW.previous_reading IS NOT NULL THEN
        -- 실제 구현에서는 더 복잡한 검증 로직 필요
        NULL;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 청구월 상태 변경 이력 기록 함수
CREATE OR REPLACE FUNCTION record_billing_month_status_change()
RETURNS TRIGGER AS $
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO billing_month_status_history (
            billing_month_id, 
            from_status, 
            to_status, 
            changed_by
        ) VALUES (
            NEW.id, 
            OLD.status, 
            NEW.status, 
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 관리비 계산 결과 검증 함수
CREATE OR REPLACE FUNCTION verify_fee_calculation_balance()
RETURNS TRIGGER AS $
DECLARE
    total_calculated DECIMAL(15,2);
    total_allocated DECIMAL(15,2);
    base_amount DECIMAL(15,2);
BEGIN
    SELECT 
        COALESCE(SUM(mf.calculated_amount), 0),
        MAX(CASE WHEN mf.calculation_method = 'RATIO_BASED' THEN mf.base_amount END)
    INTO total_allocated, base_amount
    FROM monthly_fees mf
    WHERE mf.billing_month_id = NEW.billing_month_id 
      AND mf.fee_item_id = NEW.fee_item_id;
    
    INSERT INTO fee_calculation_verification (
        billing_month_id, 
        fee_item_id, 
        total_base_amount,
        total_calculated_amount,
        total_allocated_amount,
        verified_by
    ) VALUES (
        NEW.billing_month_id, 
        NEW.fee_item_id, 
        base_amount,
        COALESCE(base_amount, total_allocated),
        total_allocated,
        NEW.updated_by
    )
    ON CONFLICT (billing_month_id, fee_item_id) 
    DO UPDATE SET
        total_base_amount = EXCLUDED.total_base_amount,
        total_calculated_amount = EXCLUDED.total_calculated_amount,
        total_allocated_amount = EXCLUDED.total_allocated_amount,
        verification_date = CURRENT_TIMESTAMP,
        verified_by = EXCLUDED.verified_by;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 고지서 상태 변경 이력 기록 함수
CREATE OR REPLACE FUNCTION record_invoice_status_change()
RETURNS TRIGGER AS $
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO invoice_status_history (
            invoice_id, 
            from_status, 
            to_status, 
            changed_by
        ) VALUES (
            NEW.id, 
            OLD.status, 
            NEW.status, 
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 고지서 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_invoice_number(
    p_building_id BIGINT,
    p_billing_year INTEGER,
    p_billing_month INTEGER
) RETURNS VARCHAR(50) AS $
DECLARE
    sequence_num INTEGER;
    invoice_number VARCHAR(50);
BEGIN
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(invoice_number FROM '[0-9]+$') AS INTEGER)
    ), 0) + 1
    INTO sequence_num
    FROM invoices i
    JOIN billing_months bm ON i.billing_month_id = bm.id
    WHERE bm.building_id = p_building_id
      AND bm.billing_year = p_billing_year
      AND bm.billing_month = p_billing_month;
    
    invoice_number := FORMAT('B%03d-%04d-%02d-%04d', 
        p_building_id, p_billing_year, p_billing_month, sequence_num);
    
    RETURN invoice_number;
END;
$ LANGUAGE plpgsql;

-- 연체료 계산 함수 (단리 방식)
CREATE OR REPLACE FUNCTION calculate_late_fee(
    p_overdue_amount DECIMAL(12,2),
    p_overdue_days INTEGER,
    p_late_fee_rate DECIMAL(5,2),
    p_grace_period_days INTEGER DEFAULT 0
) RETURNS DECIMAL(12,2) AS $
DECLARE
    v_effective_overdue_days INTEGER;
    v_daily_rate DECIMAL(8,6);
    v_late_fee DECIMAL(12,2);
BEGIN
    v_effective_overdue_days := GREATEST(0, p_overdue_days - p_grace_period_days);
    
    IF v_effective_overdue_days <= 0 THEN
        RETURN 0;
    END IF;
    
    v_daily_rate := p_late_fee_rate / 365.0;
    v_late_fee := p_overdue_amount * v_daily_rate * v_effective_overdue_days / 100.0;
    
    RETURN ROUND(v_late_fee, 2);
END;
$ LANGUAGE plpgsql IMMUTABLE;

-- 미납 현황 업데이트 함수
CREATE OR REPLACE FUNCTION update_delinquency_status(p_invoice_id BIGINT)
RETURNS VOID AS $
DECLARE
    v_invoice_record RECORD;
    v_total_paid DECIMAL(12,2);
    v_overdue_amount DECIMAL(12,2);
    v_overdue_days INTEGER;
    v_late_fee DECIMAL(12,2);
    v_payment_policy RECORD;
    v_delinquency_exists BOOLEAN;
BEGIN
    SELECT i.*, bm.billing_year, bm.billing_month, u.building_id
    INTO v_invoice_record
    FROM invoices i
    JOIN billing_months bm ON i.billing_month_id = bm.id
    JOIN units u ON i.unit_id = u.id
    WHERE i.id = p_invoice_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '고지서를 찾을 수 없습니다: %', p_invoice_id;
    END IF;
    
    SELECT * INTO v_payment_policy
    FROM payment_policies
    WHERE building_id = v_invoice_record.building_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '납부 정책을 찾을 수 없습니다. 건물 ID: %', v_invoice_record.building_id;
    END IF;
    
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
    FROM payments
    WHERE invoice_id = p_invoice_id AND payment_status = 'COMPLETED';
    
    v_overdue_amount := v_invoice_record.total_amount - v_total_paid;
    v_overdue_days := GREATEST(0, CURRENT_DATE - v_invoice_record.due_date);
    
    IF v_overdue_amount <= 0 THEN
        UPDATE delinquencies 
        SET status = 'RESOLVED',
            resolution_date = CURRENT_DATE,
            resolution_notes = '전액 납부 완료',
            updated_at = CURRENT_TIMESTAMP
        WHERE invoice_id = p_invoice_id AND status != 'RESOLVED';
        RETURN;
    END IF;
    
    v_late_fee := calculate_late_fee(
        v_overdue_amount,
        v_overdue_days,
        v_payment_policy.late_fee_rate,
        v_payment_policy.grace_period_days
    );
    
    SELECT EXISTS(SELECT 1 FROM delinquencies WHERE invoice_id = p_invoice_id)
    INTO v_delinquency_exists;
    
    IF v_delinquency_exists THEN
        UPDATE delinquencies
        SET overdue_amount = v_overdue_amount,
            overdue_days = v_overdue_days,
            late_fee = v_late_fee,
            late_fee_rate = v_payment_policy.late_fee_rate,
            grace_period_days = v_payment_policy.grace_period_days,
            status = CASE 
                WHEN v_total_paid > 0 AND v_overdue_amount > 0 THEN 'PARTIAL_PAID'
                ELSE 'OVERDUE'
            END,
            last_calculated_date = CURRENT_DATE,
            updated_at = CURRENT_TIMESTAMP
        WHERE invoice_id = p_invoice_id;
    ELSE
        INSERT INTO delinquencies (
            invoice_id,
            overdue_amount,
            overdue_days,
            late_fee,
            late_fee_rate,
            grace_period_days,
            status,
            first_overdue_date,
            last_calculated_date
        ) VALUES (
            p_invoice_id,
            v_overdue_amount,
            v_overdue_days,
            v_late_fee,
            v_payment_policy.late_fee_rate,
            v_payment_policy.grace_period_days,
            CASE 
                WHEN v_total_paid > 0 THEN 'PARTIAL_PAID'
                ELSE 'OVERDUE'
            END,
            v_invoice_record.due_date + INTERVAL '1 day',
            CURRENT_DATE
        );
    END IF;
    
    INSERT INTO late_fee_calculations (
        delinquency_id,
        calculation_date,
        overdue_amount,
        overdue_days,
        daily_rate,
        calculated_late_fee,
        cumulative_late_fee,
        calculation_method,
        notes
    ) 
    SELECT 
        d.id,
        CURRENT_DATE,
        v_overdue_amount,
        v_overdue_days,
        v_payment_policy.late_fee_rate / 365.0,
        v_late_fee,
        v_late_fee,
        'SIMPLE_INTEREST',
        '자동 계산'
    FROM delinquencies d
    WHERE d.invoice_id = p_invoice_id;
    
END;
$ LANGUAGE plpgsql;

-- 수납 처리 후 미납 상태 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION trigger_update_delinquency_on_payment()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.payment_status = 'COMPLETED' THEN
        PERFORM update_delinquency_status(NEW.invoice_id);
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 수납 취소/환불 시 미납 상태 재계산 트리거 함수
CREATE OR REPLACE FUNCTION trigger_recalculate_delinquency_on_payment_change()
RETURNS TRIGGER AS $
BEGIN
    IF OLD.payment_status != NEW.payment_status THEN
        PERFORM update_delinquency_status(NEW.invoice_id);
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 고지서 생성 시 미납 상태 초기화 트리거 함수
CREATE OR REPLACE FUNCTION trigger_initialize_delinquency_on_invoice()
RETURNS TRIGGER AS $
BEGIN
    IF NEW.due_date < CURRENT_DATE THEN
        PERFORM update_delinquency_status(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 수납 금액 제약조건 함수
CREATE OR REPLACE FUNCTION check_payment_amount_constraint()
RETURNS TRIGGER AS $
DECLARE
    v_invoice_total DECIMAL(12,2);
    v_total_paid DECIMAL(12,2);
BEGIN
    SELECT total_amount INTO v_invoice_total
    FROM invoices
    WHERE id = NEW.invoice_id;
    
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM payments
    WHERE invoice_id = NEW.invoice_id 
      AND payment_status = 'COMPLETED'
      AND id != COALESCE(NEW.id, -1);
    
    IF (v_total_paid + NEW.amount) > v_invoice_total THEN
        RAISE EXCEPTION '납부 금액이 고지서 총액을 초과할 수 없습니다. 고지서 총액: %, 기존 납부액: %, 신규 납부액: %', 
            v_invoice_total, v_total_paid, NEW.amount;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 수납 상세 내역 합계 제약조건 함수
CREATE OR REPLACE FUNCTION check_payment_details_sum_constraint()
RETURNS TRIGGER AS $
DECLARE
    v_payment_amount DECIMAL(12,2);
    v_details_sum DECIMAL(12,2);
BEGIN
    SELECT amount INTO v_payment_amount
    FROM payments
    WHERE id = NEW.payment_id;
    
    SELECT COALESCE(SUM(allocated_amount), 0) INTO v_details_sum
    FROM payment_details
    WHERE payment_id = NEW.payment_id
      AND id != COALESCE(NEW.id, -1);
    
    IF (v_details_sum + NEW.allocated_amount) > v_payment_amount THEN
        RAISE EXCEPTION '수납 상세 내역 합계가 수납 총액을 초과할 수 없습니다. 수납 총액: %, 기존 상세 합계: %, 신규 배분액: %', 
            v_payment_amount, v_details_sum, NEW.allocated_amount;
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;-
- =====================================================
-- 17. 트리거 생성
-- =====================================================

-- 건물 및 호실 관련 트리거
CREATE TRIGGER trigger_update_building_total_units
    AFTER INSERT OR DELETE ON units
    FOR EACH ROW
    EXECUTE FUNCTION update_building_total_units();

CREATE TRIGGER trigger_validate_unit_number_uniqueness
    BEFORE INSERT OR UPDATE ON units
    FOR EACH ROW
    EXECUTE FUNCTION validate_unit_number_uniqueness();

CREATE TRIGGER trigger_buildings_updated_at
    BEFORE UPDATE ON buildings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_units_updated_at
    BEFORE UPDATE ON units
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 임대인 및 임차인 관련 트리거
CREATE TRIGGER trigger_validate_lessor_business_number
    BEFORE INSERT OR UPDATE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION validate_business_number_trigger();

CREATE TRIGGER trigger_validate_tenant_business_number
    BEFORE INSERT OR UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION validate_business_number_trigger();

CREATE TRIGGER trigger_lessors_updated_at
    BEFORE UPDATE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_tenants_updated_at
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 관리비 항목 및 정책 관련 트리거
CREATE TRIGGER trigger_validate_fee_item_configuration
    BEFORE INSERT OR UPDATE ON fee_items
    FOR EACH ROW
    EXECUTE FUNCTION validate_fee_item_configuration();

CREATE TRIGGER trigger_validate_payment_policy
    BEFORE INSERT OR UPDATE ON payment_policies
    FOR EACH ROW
    EXECUTE FUNCTION validate_payment_policy();

CREATE TRIGGER trigger_fee_items_updated_at
    BEFORE UPDATE ON fee_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_payment_policies_updated_at
    BEFORE UPDATE ON payment_policies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_external_accounts_updated_at
    BEFORE UPDATE ON external_bill_accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_fee_metadata_updated_at
    BEFORE UPDATE ON fee_calculation_metadata
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 청구 및 납부 관련 트리거
CREATE TRIGGER trigger_validate_meter_reading_consistency
    BEFORE INSERT OR UPDATE ON unit_meter_readings
    FOR EACH ROW
    EXECUTE FUNCTION validate_meter_reading_consistency();

CREATE TRIGGER trigger_record_billing_month_status_change
    AFTER UPDATE ON billing_months
    FOR EACH ROW
    EXECUTE FUNCTION record_billing_month_status_change();

CREATE TRIGGER trigger_verify_fee_calculation_balance
    AFTER INSERT OR UPDATE OR DELETE ON monthly_fees
    FOR EACH ROW
    EXECUTE FUNCTION verify_fee_calculation_balance();

CREATE TRIGGER trigger_record_invoice_status_change
    AFTER UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION record_invoice_status_change();

CREATE TRIGGER trg_payment_insert_update_delinquency
    AFTER INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_delinquency_on_payment();

CREATE TRIGGER trg_payment_update_recalculate_delinquency
    AFTER UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recalculate_delinquency_on_payment_change();

CREATE TRIGGER trg_invoice_insert_initialize_delinquency
    AFTER INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION trigger_initialize_delinquency_on_invoice();

CREATE TRIGGER trg_check_payment_amount
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION check_payment_amount_constraint();

CREATE TRIGGER trg_check_payment_details_sum
    BEFORE INSERT OR UPDATE ON payment_details
    FOR EACH ROW
    EXECUTE FUNCTION check_payment_details_sum_constraint();-- ===
==================================================
-- 18. 기본 데이터 삽입
-- =====================================================

-- 기본 역할 생성
INSERT INTO roles (name, display_name, description, is_system_role, permissions) VALUES
('SUPER_ADMIN', '시스템 관리자', '모든 권한을 가진 시스템 관리자', true, '{
    "system": ["*"],
    "users": ["*"],
    "buildings": ["*"],
    "accounting": ["*"]
}'),
('BUILDING_ADMIN', '건물 관리자', '건물 관리 전체 권한', false, '{
    "buildings": ["read", "update"],
    "tenants": ["*"],
    "contracts": ["*"],
    "invoices": ["*"],
    "payments": ["*"],
    "maintenance": ["*"],
    "reports": ["*"]
}'),
('ACCOUNTING_MANAGER', '회계 담당자', '회계 및 재무 관리 권한', false, '{
    "accounting": ["*"],
    "invoices": ["*"],
    "payments": ["*"],
    "reports": ["read"]
}'),
('FACILITY_MANAGER', '시설 관리자', '시설 유지보수 관리 권한', false, '{
    "buildings": ["read"],
    "maintenance": ["*"],
    "facilities": ["*"],
    "vendors": ["*"]
}'),
('STAFF', '일반 직원', '기본 조회 및 제한적 수정 권한', false, '{
    "buildings": ["read"],
    "tenants": ["read", "update"],
    "contracts": ["read"],
    "invoices": ["read"],
    "maintenance": ["read", "create"]
}'),
('VIEWER', '조회자', '읽기 전용 권한', false, '{
    "buildings": ["read"],
    "tenants": ["read"],
    "contracts": ["read"],
    "invoices": ["read"],
    "reports": ["read"]
}');

-- 권한 매트릭스 데이터 삽입 (주요 권한만)
INSERT INTO permission_matrix (role_id, resource, action, is_allowed) VALUES
-- SUPER_ADMIN 권한 (모든 권한)
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'create', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'read', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'update', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'delete', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'create', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'update', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'delete', true),
-- BUILDING_ADMIN 권한
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'buildings', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'update', true),
-- VIEWER 권한 (읽기 전용)
((SELECT id FROM roles WHERE name = 'VIEWER'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'tenants', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'contracts', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'invoices', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'reports', 'read', true);

-- 민원 분류 코드 기본 데이터
INSERT INTO complaint_categories (category_code, category_name, description, default_priority, default_sla_hours) VALUES
('FACILITY', '시설 관련', '엘리베이터, 보일러, 전기, 수도 등 시설 문제', 'HIGH', 24),
('NOISE', '소음 관련', '층간소음, 공사소음, 기타 소음 문제', 'MEDIUM', 48),
('PARKING', '주차 관련', '주차 공간, 주차 위반, 주차 요금 문제', 'MEDIUM', 48),
('CLEANING', '청소 관련', '공용구역 청소, 쓰레기 처리 문제', 'LOW', 72),
('SECURITY', '보안 관련', '출입통제, CCTV, 보안 문제', 'HIGH', 12),
('BILLING', '요금 관련', '관리비, 임대료, 기타 요금 문의', 'MEDIUM', 48),
('NEIGHBOR', '이웃 관련', '이웃 간 분쟁, 공동생활 문제', 'MEDIUM', 72),
('ADMIN', '관리 관련', '관리사무소 업무, 서비스 문의', 'LOW', 72),
('OTHER', '기타', '기타 민원 사항', 'MEDIUM', 48);

-- 공지사항 분류 기본 데이터
INSERT INTO announcement_categories (category_code, category_name, description, icon, color) VALUES
('GENERAL', '일반 공지', '일반적인 공지사항', 'info-circle', 'blue'),
('MAINTENANCE', '시설 공지', '시설 점검, 공사 관련 공지', 'tools', 'orange'),
('EVENT', '행사 공지', '건물 내 행사, 이벤트 공지', 'calendar', 'green'),
('EMERGENCY', '긴급 공지', '긴급상황, 비상사태 공지', 'exclamation-triangle', 'red'),
('BILLING', '요금 공지', '관리비, 임대료 관련 공지', 'credit-card', 'purple'),
('POLICY', '정책 공지', '관리 정책, 규정 변경 공지', 'file-text', 'gray'),
('SAFETY', '안전 공지', '안전 수칙, 주의사항 공지', 'shield', 'yellow');

-- 알림 템플릿 기본 데이터
INSERT INTO notification_templates (template_code, template_name, notification_type, title_template, message_template, default_channels) VALUES
('ANNOUNCEMENT_NEW', '새 공지사항 알림', 'ANNOUNCEMENT', '새 공지사항: {{title}}', '{{building_name}}에 새로운 공지사항이 등록되었습니다.\n\n제목: {{title}}\n내용: {{summary}}', ARRAY['IN_APP', 'EMAIL']),
('COMPLAINT_ASSIGNED', '민원 배정 알림', 'COMPLAINT_UPDATE', '민원이 배정되었습니다: {{complaint_number}}', '민원 {{complaint_number}}이(가) 귀하에게 배정되었습니다.\n\n제목: {{title}}\n우선순위: {{priority}}', ARRAY['IN_APP', 'EMAIL']),
('COMPLAINT_RESOLVED', '민원 해결 알림', 'COMPLAINT_UPDATE', '민원이 해결되었습니다: {{complaint_number}}', '접수하신 민원이 해결되었습니다.\n\n민원번호: {{complaint_number}}\n해결내용: {{resolution}}', ARRAY['IN_APP', 'EMAIL', 'SMS']),
('MAINTENANCE_SCHEDULED', '유지보수 일정 알림', 'MAINTENANCE_SCHEDULE', '유지보수 일정 안내', '{{facility_name}} 유지보수가 예정되어 있습니다.\n\n일시: {{scheduled_date}}\n내용: {{description}}', ARRAY['IN_APP', 'EMAIL']),
('BILLING_DUE', '관리비 납부 안내', 'BILLING_NOTICE', '관리비 납부 안내', '{{month}}월 관리비 납부 기한이 임박했습니다.\n\n금액: {{amount}}원\n납부기한: {{due_date}}', ARRAY['IN_APP', 'EMAIL', 'SMS']),
('CONTRACT_EXPIRY', '계약 만료 안내', 'CONTRACT_EXPIRY', '임대 계약 만료 안내', '임대 계약이 곧 만료됩니다.\n\n만료일: {{expiry_date}}\n연장 문의: {{contact_info}}', ARRAY['IN_APP', 'EMAIL']);

-- 기본 계정과목 데이터 삽입
INSERT INTO chart_of_accounts (account_code, account_name, account_type, description) VALUES
-- 자산 계정
('1100', '현금', 'ASSET', '현금 및 현금성 자산'),
('1200', '예금', 'ASSET', '은행 예금'),
('1300', '미수금', 'ASSET', '임대료 및 관리비 미수금'),
('1400', '보증금', 'ASSET', '임차인으로부터 받은 보증금'),
('1500', '건물', 'ASSET', '건물 자산'),
('1600', '감가상각누계액', 'ASSET', '건물 감가상각 누계액'),
-- 부채 계정
('2100', '미지급금', 'LIABILITY', '각종 미지급 비용'),
('2200', '예수보증금', 'LIABILITY', '임차인에게 받은 보증금'),
('2300', '미지급세금', 'LIABILITY', '미지급 세금'),
-- 자본 계정
('3100', '자본금', 'EQUITY', '소유자 자본금'),
('3200', '이익잉여금', 'EQUITY', '누적 이익잉여금'),
-- 수익 계정
('4100', '임대료수익', 'REVENUE', '임대료 수익'),
('4200', '관리비수익', 'REVENUE', '관리비 수익'),
('4300', '기타수익', 'REVENUE', '기타 수익'),
-- 비용 계정
('5100', '관리비', 'EXPENSE', '건물 관리비용'),
('5200', '수선비', 'EXPENSE', '건물 수선 및 유지비'),
('5300', '세금과공과', 'EXPENSE', '세금 및 공과금'),
('5400', '감가상각비', 'EXPENSE', '건물 감가상각비'),
('5500', '기타비용', 'EXPENSE', '기타 운영비용');

-- 기본 재무제표 템플릿 데이터
INSERT INTO financial_statement_templates (template_name, statement_type, template_structure, is_default) VALUES
('기본 손익계산서', 'INCOME_STATEMENT', '{
    "sections": [
        {"name": "수익", "accounts": ["4100", "4200", "4300"]},
        {"name": "비용", "accounts": ["5100", "5200", "5300", "5400", "5500"]}
    ]
}', true),
('기본 대차대조표', 'BALANCE_SHEET', '{
    "sections": [
        {"name": "자산", "accounts": ["1100", "1200", "1300", "1400", "1500", "1600"]},
        {"name": "부채", "accounts": ["2100", "2200", "2300"]},
        {"name": "자본", "accounts": ["3100", "3200"]}
    ]
}', true);

-- 기본 조직 설정
INSERT INTO organization_settings (
    organization_name, 
    timezone, 
    locale, 
    currency, 
    date_format, 
    fiscal_year_start_month
) VALUES (
    'QIRO 건물 관리 시스템', 
    'Asia/Seoul', 
    'ko_KR', 
    'KRW', 
    'YYYY-MM-DD', 
    1
);

-- =====================================================
-- 19. 유용한 뷰 생성
-- =====================================================

-- 미납 현황 종합 뷰
CREATE VIEW v_delinquency_summary AS
SELECT 
    d.id,
    d.invoice_id,
    i.billing_month_id,
    bm.billing_year,
    bm.billing_month,
    b.name as building_name,
    u.unit_number,
    t.name as tenant_name,
    t.primary_phone as tenant_phone,
    i.total_amount as invoice_amount,
    COALESCE(p.total_paid, 0) as paid_amount,
    d.overdue_amount,
    d.overdue_days,
    d.late_fee,
    d.overdue_amount + d.late_fee as total_overdue,
    d.status,
    d.first_overdue_date,
    d.last_calculated_date,
    pp.late_fee_rate,
    pp.grace_period_days
FROM delinquencies d
JOIN invoices i ON d.invoice_id = i.id
JOIN billing_months bm ON i.billing_month_id = bm.id
JOIN units u ON i.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
LEFT JOIN lease_contracts lc ON u.id = lc.unit_id 
    AND lc.status = 'ACTIVE'
    AND CURRENT_DATE BETWEEN lc.start_date AND lc.end_date
LEFT JOIN tenants t ON lc.tenant_id = t.id
LEFT JOIN payment_policies pp ON b.id = pp.building_id
LEFT JOIN (
    SELECT 
        invoice_id,
        SUM(amount) as total_paid
    FROM payments
    WHERE payment_status = 'COMPLETED'
    GROUP BY invoice_id
) p ON i.id = p.invoice_id
WHERE d.status IN ('OVERDUE', 'PARTIAL_PAID');

-- 수납 현황 종합 뷰
CREATE VIEW v_payment_summary AS
SELECT 
    p.id,
    p.invoice_id,
    i.billing_month_id,
    bm.billing_year,
    bm.billing_month,
    b.name as building_name,
    u.unit_number,
    t.name as tenant_name,
    p.payment_date,
    p.amount,
    p.payment_method,
    p.payment_status,
    p.payment_reference,
    i.total_amount as invoice_amount,
    i.due_date,
    CASE 
        WHEN p.payment_date <= i.due_date THEN '정상납부'
        ELSE '연체납부'
    END as payment_type,
    u2.full_name as processed_by_name
FROM payments p
JOIN invoices i ON p.invoice_id = i.id
JOIN billing_months bm ON i.billing_month_id = bm.id
JOIN units u ON i.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
LEFT JOIN lease_contracts lc ON u.id = lc.unit_id 
    AND lc.status = 'ACTIVE'
    AND p.payment_date BETWEEN lc.start_date AND lc.end_date
LEFT JOIN tenants t ON lc.tenant_id = t.id
LEFT JOIN users u2 ON p.processed_by = u2.id;

-- 손익계산서 뷰
CREATE VIEW v_income_statement AS
SELECT 
    ab.building_id,
    ap.period_year,
    ap.period_month,
    coa.account_type,
    coa.account_code,
    coa.account_name,
    ab.closing_balance,
    CASE 
        WHEN coa.account_type = 'REVENUE' THEN ab.closing_balance
        ELSE 0
    END as revenue_amount,
    CASE 
        WHEN coa.account_type = 'EXPENSE' THEN ab.closing_balance
        ELSE 0
    END as expense_amount
FROM account_balances ab
JOIN chart_of_accounts coa ON ab.account_id = coa.id
JOIN accounting_periods ap ON ab.period_id = ap.id
WHERE coa.account_type IN ('REVENUE', 'EXPENSE')
    AND coa.is_active = true;

-- 대차대조표 뷰
CREATE VIEW v_balance_sheet AS
SELECT 
    ab.building_id,
    ap.period_year,
    ap.period_month,
    coa.account_type,
    coa.account_code,
    coa.account_name,
    ab.closing_balance,
    CASE 
        WHEN coa.account_type = 'ASSET' THEN ab.closing_balance
        ELSE 0
    END as asset_amount,
    CASE 
        WHEN coa.account_type = 'LIABILITY' THEN ab.closing_balance
        ELSE 0
    END as liability_amount,
    CASE 
        WHEN coa.account_type = 'EQUITY' THEN ab.closing_balance
        ELSE 0
    END as equity_amount
FROM account_balances ab
JOIN chart_of_accounts coa ON ab.account_id = coa.id
JOIN accounting_periods ap ON ab.period_id = ap.id
WHERE coa.account_type IN ('ASSET', 'LIABILITY', 'EQUITY')
    AND coa.is_active = true;

-- =====================================================
-- 20. 코멘트 추가
-- =====================================================

-- 테이블 코멘트
COMMENT ON TABLE buildings IS '건물 기본 정보를 관리하는 테이블';
COMMENT ON TABLE units IS '호실 정보를 관리하는 테이블';
COMMENT ON TABLE lessors IS '임대인 정보를 관리하는 테이블 (개인정보 암호화 적용)';
COMMENT ON TABLE tenants IS '임차인 정보를 관리하는 테이블 (개인정보 암호화 적용)';
COMMENT ON TABLE fee_items IS '관리비 항목 정보를 관리하는 테이블 (계산 방식별 메타데이터 포함)';
COMMENT ON TABLE payment_policies IS '납부 정책 정보를 관리하는 테이블 (연체료, 할인, 자동출금 등)';
COMMENT ON TABLE external_bill_accounts IS '외부 고지서 계정 정보를 관리하는 테이블 (한전, 수도 등)';
COMMENT ON TABLE billing_months IS '청구월 관리 테이블 - 월별 관리비 처리 워크플로우의 중심';
COMMENT ON TABLE unit_meter_readings IS '호실별 검침 데이터 테이블 - 전기, 수도, 가스 등 개별 검침';
COMMENT ON TABLE monthly_fees IS '월별 관리비 산정 결과 테이블 - 호실별, 항목별 계산 결과';
COMMENT ON TABLE invoices IS '고지서 테이블 - 월별 관리비 고지서';
COMMENT ON TABLE payments IS '관리비 수납 내역 테이블';
COMMENT ON TABLE delinquencies IS '미납 관리 테이블';
COMMENT ON TABLE lease_contracts IS '임대 계약 정보를 관리하는 테이블';
COMMENT ON TABLE monthly_rents IS '월별 임대료 관리 테이블';
COMMENT ON TABLE facilities IS '시설물 기본 정보 및 생애주기 관리';
COMMENT ON TABLE maintenance_requests IS '유지보수 요청 관리 테이블';
COMMENT ON TABLE complaints IS '민원 관리 테이블 - 건물 관련 민원 접수 및 처리 관리';
COMMENT ON TABLE announcements IS '공지사항 관리 테이블 - 건물별 공지사항 등록 및 관리';
COMMENT ON TABLE notifications IS '알림 관리 테이블 - 다양한 채널을 통한 알림 발송 관리';
COMMENT ON TABLE journal_entries IS '회계 전표 헤더 테이블';
COMMENT ON TABLE users IS '시스템 사용자 정보 테이블';
COMMENT ON TABLE audit_logs IS '시스템 감사 로그 테이블';

-- 스키마 완료 메시지
SELECT 'QIRO 건물 관리 SaaS 데이터베이스 스키마 생성이 완료되었습니다.' as message;