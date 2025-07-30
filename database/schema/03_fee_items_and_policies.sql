-- =====================================================
-- 관리비 항목 및 정책 테이블 설계
-- 요구사항: 1.1, 1.2
-- =====================================================

-- 관리비 유형 ENUM 타입
CREATE TYPE fee_type AS ENUM (
    'COMMON_MAINTENANCE',   -- 공용관리비
    'INDIVIDUAL_UTILITY',   -- 개별 공과금
    'COMMON_UTILITY',       -- 공용 공과금
    'SPECIAL_ASSESSMENT',   -- 특별부과금
    'LATE_FEE',            -- 연체료
    'OTHER_CHARGES'        -- 기타 부과금
);

-- 계산 방식 ENUM 타입
CREATE TYPE calculation_method AS ENUM (
    'FIXED_AMOUNT',        -- 고정금액
    'UNIT_PRICE',          -- 단가 × 사용량
    'AREA_BASED',          -- 면적 비례
    'HOUSEHOLD_BASED',     -- 세대 균등분할
    'USAGE_BASED',         -- 사용량 기준
    'PERCENTAGE_BASED',    -- 비율 기준
    'TIERED_RATE'         -- 누진요금제
);

-- 부과 대상 ENUM 타입
CREATE TYPE charge_target AS ENUM (
    'ALL_UNITS',           -- 전체 호실
    'OCCUPIED_UNITS',      -- 입주 호실만
    'RESIDENTIAL_ONLY',    -- 주거용만
    'COMMERCIAL_ONLY',     -- 상업용만
    'SPECIFIC_UNITS',      -- 특정 호실
    'BY_FLOOR',           -- 층별
    'BY_AREA_RANGE'       -- 면적 구간별
);

-- 외부 고지서 제공업체 ENUM 타입
CREATE TYPE external_provider AS ENUM (
    'KEPCO',              -- 한국전력공사
    'K_WATER',            -- 한국수자원공사
    'CITY_GAS',           -- 도시가스
    'LPG',                -- LPG
    'INTERNET',           -- 인터넷
    'CABLE_TV',           -- 케이블TV
    'WASTE_MANAGEMENT',   -- 폐기물처리
    'ELEVATOR',           -- 엘리베이터
    'SECURITY',           -- 보안
    'CLEANING',           -- 청소
    'OTHER'               -- 기타
);

-- 납부 방법 ENUM 타입
CREATE TYPE payment_method AS ENUM (
    'BANK_TRANSFER',      -- 계좌이체
    'DIRECT_DEBIT',       -- 자동출금
    'CASH',               -- 현금
    'CHECK',              -- 수표
    'CREDIT_CARD',        -- 신용카드
    'MOBILE_PAYMENT',     -- 모바일결제
    'VIRTUAL_ACCOUNT'     -- 가상계좌
);

-- =====================================================
-- 관리비 항목 테이블 (fee_items)
-- =====================================================
CREATE TABLE fee_items (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 건물 연관 관계
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE COMMENT '건물 ID',
    
    -- 항목 기본 정보
    name VARCHAR(255) NOT NULL COMMENT '관리비 항목명',
    code VARCHAR(50) COMMENT '항목 코드',
    description TEXT COMMENT '항목 설명',
    
    -- 분류 정보
    fee_type fee_type NOT NULL COMMENT '관리비 유형',
    category VARCHAR(100) COMMENT '카테고리',
    subcategory VARCHAR(100) COMMENT '하위 카테고리',
    
    -- 계산 방식
    calculation_method calculation_method NOT NULL COMMENT '계산 방식',
    charge_target charge_target NOT NULL DEFAULT 'ALL_UNITS' COMMENT '부과 대상',
    
    -- 금액 정보
    unit_price DECIMAL(12,2) COMMENT '단가',
    fixed_amount DECIMAL(12,2) COMMENT '고정금액',
    minimum_amount DECIMAL(12,2) DEFAULT 0 COMMENT '최소 부과금액',
    maximum_amount DECIMAL(12,2) COMMENT '최대 부과금액',
    
    -- 비율 정보 (percentage_based 계산 시 사용)
    percentage_rate DECIMAL(5,4) COMMENT '비율 (0.0000 ~ 1.0000)',
    base_amount DECIMAL(12,2) COMMENT '기준 금액',
    
    -- 누진요금제 정보 (JSON 형태로 저장)
    tiered_rates JSONB COMMENT '누진요금 구간별 요율 정보',
    
    -- 세금 정보
    is_taxable BOOLEAN DEFAULT false COMMENT '과세 여부',
    tax_rate DECIMAL(5,4) DEFAULT 0.1000 COMMENT '세율 (기본 10%)',
    tax_type VARCHAR(50) DEFAULT 'VAT' COMMENT '세금 유형',
    
    -- 부과 조건
    apply_conditions JSONB COMMENT '부과 조건 (JSON)',
    exclude_conditions JSONB COMMENT '제외 조건 (JSON)',
    
    -- 계산 주기
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY' COMMENT '부과 주기',
    proration_method VARCHAR(50) COMMENT '일할계산 방식',
    
    -- 외부 연동 정보
    external_provider external_provider COMMENT '외부 제공업체',
    external_account_required BOOLEAN DEFAULT false COMMENT '외부 계정 연결 필요 여부',
    
    -- 상태 및 메타데이터
    is_active BOOLEAN DEFAULT true COMMENT '활성 상태',
    effective_from DATE COMMENT '적용 시작일',
    effective_to DATE COMMENT '적용 종료일',
    display_order INTEGER DEFAULT 0 COMMENT '표시 순서',
    
    -- 회계 연동
    account_code VARCHAR(20) COMMENT '회계 계정 코드',
    cost_center VARCHAR(20) COMMENT '비용 센터',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID'
);

-- 관리비 항목 테이블 인덱스
CREATE INDEX idx_fee_items_building_id ON fee_items(building_id);
CREATE INDEX idx_fee_items_fee_type ON fee_items(fee_type);
CREATE INDEX idx_fee_items_calculation_method ON fee_items(calculation_method);
CREATE INDEX idx_fee_items_charge_target ON fee_items(charge_target);
CREATE INDEX idx_fee_items_is_active ON fee_items(is_active);
CREATE INDEX idx_fee_items_external_provider ON fee_items(external_provider);
CREATE INDEX idx_fee_items_effective_dates ON fee_items(effective_from, effective_to);
CREATE INDEX idx_fee_items_display_order ON fee_items(display_order);

-- =====================================================
-- 납부 정책 테이블 (payment_policies)
-- =====================================================
CREATE TABLE payment_policies (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 건물 연관 관계
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE COMMENT '건물 ID',
    
    -- 정책 기본 정보
    policy_name VARCHAR(255) NOT NULL COMMENT '정책명',
    description TEXT COMMENT '정책 설명',
    
    -- 납부 기한 설정
    payment_due_day INTEGER NOT NULL CHECK (payment_due_day BETWEEN 1 AND 31) COMMENT '납부 기한일',
    grace_period_days INTEGER DEFAULT 0 CHECK (grace_period_days >= 0) COMMENT '유예 기간 (일)',
    
    -- 연체료 설정
    late_fee_rate DECIMAL(5,4) NOT NULL DEFAULT 0.0200 COMMENT '연체료율 (월 2%)',
    late_fee_calculation_method VARCHAR(50) DEFAULT 'COMPOUND' COMMENT '연체료 계산 방식',
    minimum_late_fee DECIMAL(12,2) DEFAULT 0 COMMENT '최소 연체료',
    maximum_late_fee DECIMAL(12,2) COMMENT '최대 연체료',
    late_fee_grace_days INTEGER DEFAULT 0 COMMENT '연체료 면제 기간',
    
    -- 할인 정책
    early_payment_discount_rate DECIMAL(5,4) DEFAULT 0 COMMENT '조기납부 할인율',
    early_payment_days INTEGER DEFAULT 0 COMMENT '조기납부 기준일',
    bulk_payment_discount_rate DECIMAL(5,4) DEFAULT 0 COMMENT '일괄납부 할인율',
    
    -- 납부 방법 설정
    allowed_payment_methods JSONB COMMENT '허용된 납부 방법 목록',
    preferred_payment_method payment_method COMMENT '권장 납부 방법',
    
    -- 은행 정보
    bank_name VARCHAR(100) COMMENT '은행명',
    account_number VARCHAR(100) COMMENT '계좌번호',
    account_holder VARCHAR(255) COMMENT '예금주',
    virtual_account_prefix VARCHAR(20) COMMENT '가상계좌 접두사',
    
    -- 자동출금 설정
    auto_debit_enabled BOOLEAN DEFAULT false COMMENT '자동출금 사용 여부',
    auto_debit_day INTEGER CHECK (auto_debit_day BETWEEN 1 AND 31) COMMENT '자동출금일',
    auto_debit_retry_days INTEGER DEFAULT 3 COMMENT '자동출금 재시도 일수',
    
    -- 고지서 발송 설정
    invoice_delivery_method VARCHAR(50) DEFAULT 'EMAIL' COMMENT '고지서 발송 방법',
    invoice_send_days_before INTEGER DEFAULT 7 COMMENT '고지서 발송 사전 일수',
    reminder_send_days JSONB COMMENT '독촉 발송 일정 (JSON 배열)',
    
    -- 분할납부 설정
    installment_allowed BOOLEAN DEFAULT false COMMENT '분할납부 허용 여부',
    max_installments INTEGER DEFAULT 1 COMMENT '최대 분할 횟수',
    installment_fee DECIMAL(12,2) DEFAULT 0 COMMENT '분할납부 수수료',
    
    -- 상태 및 메타데이터
    is_active BOOLEAN DEFAULT true COMMENT '활성 상태',
    effective_from DATE NOT NULL COMMENT '적용 시작일',
    effective_to DATE COMMENT '적용 종료일',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID'
);

-- 납부 정책 테이블 인덱스
CREATE INDEX idx_payment_policies_building_id ON payment_policies(building_id);
CREATE INDEX idx_payment_policies_is_active ON payment_policies(is_active);
CREATE INDEX idx_payment_policies_effective_dates ON payment_policies(effective_from, effective_to);

-- =====================================================
-- 외부 고지서 계정 테이블 (external_bill_accounts)
-- =====================================================
CREATE TABLE external_bill_accounts (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 건물 연관 관계
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE COMMENT '건물 ID',
    
    -- 제공업체 정보
    provider_name VARCHAR(100) NOT NULL COMMENT '제공업체명',
    provider_type external_provider NOT NULL COMMENT '제공업체 유형',
    provider_code VARCHAR(50) COMMENT '제공업체 코드',
    
    -- 계정 정보
    account_number VARCHAR(100) NOT NULL COMMENT '고객번호/계정번호',
    account_name VARCHAR(255) COMMENT '계정명',
    contract_number VARCHAR(100) COMMENT '계약번호',
    
    -- 사용 목적 및 분류
    usage_purpose VARCHAR(100) COMMENT '사용 목적',
    service_type VARCHAR(100) COMMENT '서비스 유형',
    meter_number VARCHAR(100) COMMENT '계량기 번호',
    
    -- 요금 정보
    rate_plan VARCHAR(100) COMMENT '요금제',
    base_charge DECIMAL(12,2) DEFAULT 0 COMMENT '기본요금',
    unit_price DECIMAL(12,4) COMMENT '단위요금',
    
    -- 청구 정보
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY' COMMENT '청구 주기',
    billing_day INTEGER COMMENT '검침일',
    payment_due_day INTEGER COMMENT '납부 기한일',
    
    -- 연결된 호실 정보 (JSON 배열)
    connected_units JSONB COMMENT '연결된 호실 ID 목록',
    allocation_method VARCHAR(50) COMMENT '배분 방식',
    allocation_ratios JSONB COMMENT '배분 비율 정보',
    
    -- 자동 연동 설정
    auto_import_enabled BOOLEAN DEFAULT false COMMENT '자동 가져오기 사용 여부',
    api_endpoint VARCHAR(500) COMMENT 'API 엔드포인트',
    api_credentials_encrypted BYTEA COMMENT 'API 인증정보 (암호화)',
    last_import_date TIMESTAMP COMMENT '마지막 가져오기 일시',
    
    -- 상태 및 메타데이터
    is_active BOOLEAN DEFAULT true COMMENT '활성 상태',
    connection_status VARCHAR(20) DEFAULT 'MANUAL' COMMENT '연결 상태',
    notes TEXT COMMENT '특이사항',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID',
    
    -- 제약조건
    CONSTRAINT uk_building_provider_account UNIQUE (building_id, provider_type, account_number)
);

-- 외부 고지서 계정 테이블 인덱스
CREATE INDEX idx_external_accounts_building_id ON external_bill_accounts(building_id);
CREATE INDEX idx_external_accounts_provider_type ON external_bill_accounts(provider_type);
CREATE INDEX idx_external_accounts_account_number ON external_bill_accounts(account_number);
CREATE INDEX idx_external_accounts_is_active ON external_bill_accounts(is_active);
CREATE INDEX idx_external_accounts_connection_status ON external_bill_accounts(connection_status);

-- =====================================================
-- 관리비 계산 메타데이터 테이블 (fee_calculation_metadata)
-- =====================================================
CREATE TABLE fee_calculation_metadata (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 관리비 항목 연관 관계
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE CASCADE COMMENT '관리비 항목 ID',
    
    -- 메타데이터 키-값
    metadata_key VARCHAR(100) NOT NULL COMMENT '메타데이터 키',
    metadata_value TEXT COMMENT '메타데이터 값',
    data_type VARCHAR(20) DEFAULT 'STRING' COMMENT '데이터 타입',
    
    -- 설명
    description TEXT COMMENT '설명',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 제약조건
    CONSTRAINT uk_fee_item_metadata_key UNIQUE (fee_item_id, metadata_key)
);

-- 메타데이터 테이블 인덱스
CREATE INDEX idx_fee_metadata_fee_item_id ON fee_calculation_metadata(fee_item_id);
CREATE INDEX idx_fee_metadata_key ON fee_calculation_metadata(metadata_key);

-- =====================================================
-- 비즈니스 로직 함수들
-- =====================================================

-- 관리비 항목 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_fee_item_configuration()
RETURNS TRIGGER AS $$
BEGIN
    -- 계산 방식에 따른 필수 필드 검증
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
    
    -- 외부 제공업체 연동 시 계정 필요 여부 검증
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
$$ LANGUAGE plpgsql;

-- 납부 정책 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_payment_policy()
RETURNS TRIGGER AS $$
BEGIN
    -- 연체료율 범위 검증 (0% ~ 10%)
    IF NEW.late_fee_rate < 0 OR NEW.late_fee_rate > 0.1000 THEN
        RAISE EXCEPTION '연체료율은 0%에서 10% 사이여야 합니다.';
    END IF;
    
    -- 할인율 범위 검증 (0% ~ 50%)
    IF NEW.early_payment_discount_rate < 0 OR NEW.early_payment_discount_rate > 0.5000 THEN
        RAISE EXCEPTION '조기납부 할인율은 0%에서 50% 사이여야 합니다.';
    END IF;
    
    -- 자동출금 설정 시 은행 정보 필수 검증
    IF NEW.auto_debit_enabled = true THEN
        IF NEW.bank_name IS NULL OR NEW.account_number IS NULL OR NEW.account_holder IS NULL THEN
            RAISE EXCEPTION '자동출금 사용 시 은행 정보가 필수입니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 생성
-- =====================================================

-- 관리비 항목 유효성 검증 트리거
CREATE TRIGGER trigger_validate_fee_item_configuration
    BEFORE INSERT OR UPDATE ON fee_items
    FOR EACH ROW
    EXECUTE FUNCTION validate_fee_item_configuration();

-- 납부 정책 유효성 검증 트리거
CREATE TRIGGER trigger_validate_payment_policy
    BEFORE INSERT OR UPDATE ON payment_policies
    FOR EACH ROW
    EXECUTE FUNCTION validate_payment_policy();

-- updated_at 자동 업데이트 트리거
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

-- =====================================================
-- 기본 데이터 삽입
-- =====================================================

-- 기본 관리비 항목 템플릿 (예시)
INSERT INTO fee_items (building_id, name, code, fee_type, calculation_method, charge_target, description) VALUES
(1, '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', '건물 일반 관리를 위한 기본 관리비'),
(1, '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', '공용구역 청소를 위한 비용'),
(1, '보안비', 'SECURITY', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', '건물 보안 관리 비용'),
(1, '승강기유지비', 'ELEVATOR', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', '승강기 유지보수 비용'),
(1, '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', '개별 전기 사용료'),
(1, '수도료', 'WATER', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', '개별 수도 사용료'),
(1, '가스료', 'GAS', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', '개별 가스 사용료');

-- =====================================================
-- 테이블 코멘트
-- =====================================================
COMMENT ON TABLE fee_items IS '관리비 항목 정보를 관리하는 테이블 (계산 방식별 메타데이터 포함)';
COMMENT ON TABLE payment_policies IS '납부 정책 정보를 관리하는 테이블 (연체료, 할인, 자동출금 등)';
COMMENT ON TABLE external_bill_accounts IS '외부 고지서 계정 정보를 관리하는 테이블 (한전, 수도 등)';
COMMENT ON TABLE fee_calculation_metadata IS '관리비 계산을 위한 확장 메타데이터 테이블';

-- 중요 컬럼 코멘트
COMMENT ON COLUMN fee_items.tiered_rates IS '누진요금 구간별 요율 정보 (JSON): [{"from": 0, "to": 100, "rate": 100}, {"from": 101, "to": 200, "rate": 150}]';
COMMENT ON COLUMN external_bill_accounts.connected_units IS '연결된 호실 ID 목록 (JSON): [1, 2, 3]';
COMMENT ON COLUMN external_bill_accounts.allocation_ratios IS '배분 비율 정보 (JSON): {"1": 0.3, "2": 0.4, "3": 0.3}';
COMMENT ON COLUMN external_bill_accounts.api_credentials_encrypted IS 'API 인증정보 (AES-256 암호화 저장)';