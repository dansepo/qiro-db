-- =====================================================
-- 민원 및 회계 관리 시스템 - 세무 관리 테이블 (기존 구조 호환)
-- 작성일: 2025-01-30
-- 요구사항: 7.1, 7.2, 7.3 - 세무 관리, 부가세 신고, 원천징수
-- =====================================================

-- 세무 관련 ENUM 타입 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tax_type') THEN
        CREATE TYPE tax_type AS ENUM ('VAT', 'INCOME_TAX', 'LOCAL_TAX', 'WITHHOLDING_TAX', 'CORPORATE_TAX');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'transaction_type') THEN
        CREATE TYPE transaction_type AS ENUM ('PURCHASE', 'SALE', 'WITHHOLDING', 'PAYMENT', 'REFUND');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'filing_status') THEN
        CREATE TYPE filing_status AS ENUM ('NOT_FILED', 'FILED', 'AMENDED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_type') THEN
        CREATE TYPE invoice_type AS ENUM ('GENERAL', 'SIMPLIFIED', 'IMPORT', 'EXPORT');
    END IF;
END $$;

-- 세무 거래 테이블
CREATE TABLE IF NOT EXISTS bms.tax_transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    transaction_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    building_id UUID REFERENCES bms.buildings(building_id),
    
    -- 거래 기본 정보
    transaction_date DATE NOT NULL,
    tax_type tax_type NOT NULL,
    transaction_type transaction_type NOT NULL,
    
    -- 거래처 정보
    supplier_customer_name VARCHAR(255) NOT NULL,
    supplier_customer_registration_number VARCHAR(20),
    supplier_customer_address TEXT,
    
    -- 세금계산서 정보
    tax_invoice_number VARCHAR(50),
    tax_invoice_date DATE,
    invoice_type invoice_type DEFAULT 'GENERAL',
    
    -- 금액 정보
    supply_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 10.00,
    
    -- 공제 및 신고 정보
    is_deductible BOOLEAN DEFAULT true,
    deduction_amount DECIMAL(15,2) DEFAULT 0,
    filing_period VARCHAR(7), -- YYYY-MM 형식
    filing_status filing_status DEFAULT 'NOT_FILED',
    filed_at TIMESTAMP,
    
    -- 관련 회계 항목
    accounting_entry_id BIGINT REFERENCES bms.accounting_entries(entry_id),
    
    -- 비고
    description TEXT,
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    -- 제약조건
    CONSTRAINT chk_tax_transactions_amounts CHECK (
        supply_amount >= 0 AND tax_amount >= 0 AND total_amount >= 0
    ),
    CONSTRAINT chk_tax_transactions_total_amount CHECK (
        total_amount = supply_amount + tax_amount
    )
);

-- 부가세 신고 테이블
CREATE TABLE IF NOT EXISTS bms.vat_returns (
    return_id BIGSERIAL PRIMARY KEY,
    return_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 신고 기간 정보
    filing_period VARCHAR(7) NOT NULL, -- YYYY-MM 형식
    filing_year INTEGER NOT NULL,
    filing_month INTEGER NOT NULL CHECK (filing_month BETWEEN 1 AND 12),
    return_type VARCHAR(20) DEFAULT 'REGULAR' CHECK (return_type IN ('REGULAR', 'AMENDED', 'FINAL')),
    
    -- 매출 관련
    total_sales_amount DECIMAL(15,2) DEFAULT 0,
    taxable_sales_amount DECIMAL(15,2) DEFAULT 0,
    tax_free_sales_amount DECIMAL(15,2) DEFAULT 0,
    output_tax_amount DECIMAL(15,2) DEFAULT 0,
    
    -- 매입 관련
    total_purchase_amount DECIMAL(15,2) DEFAULT 0,
    deductible_purchase_amount DECIMAL(15,2) DEFAULT 0,
    input_tax_amount DECIMAL(15,2) DEFAULT 0,
    
    -- 세액 계산
    net_tax_amount DECIMAL(15,2) DEFAULT 0, -- 납부할 세액 또는 환급받을 세액
    previous_period_carryover DECIMAL(15,2) DEFAULT 0,
    current_period_payment DECIMAL(15,2) DEFAULT 0,
    
    -- 신고 상태
    filing_status filing_status DEFAULT 'NOT_FILED',
    filed_at TIMESTAMP,
    filed_by UUID REFERENCES bms.users(user_id),
    
    -- 신고서 데이터 (JSON 형태로 저장)
    return_data JSONB,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    -- 제약조건
    CONSTRAINT uk_vat_returns_company_period UNIQUE(company_id, filing_period, return_type)
);

-- 원천징수 테이블
CREATE TABLE IF NOT EXISTS bms.withholding_tax (
    withholding_id BIGSERIAL PRIMARY KEY,
    withholding_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 지급 정보
    payment_date DATE NOT NULL,
    payee_name VARCHAR(255) NOT NULL,
    payee_registration_number VARCHAR(20),
    payee_address TEXT,
    
    -- 소득 정보
    income_type VARCHAR(50) NOT NULL, -- 근로소득, 사업소득, 기타소득 등
    income_code VARCHAR(10),
    payment_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 원천징수 계산
    tax_base_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    withholding_rate DECIMAL(5,2) NOT NULL DEFAULT 0,
    withholding_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    local_tax_amount DECIMAL(15,2) DEFAULT 0, -- 지방소득세
    
    -- 신고 정보
    filing_period VARCHAR(7), -- YYYY-MM 형식
    filing_status filing_status DEFAULT 'NOT_FILED',
    filed_at TIMESTAMP,
    
    -- 지급명세서 정보
    statement_issued BOOLEAN DEFAULT false,
    statement_issued_at TIMESTAMP,
    
    -- 관련 회계 항목
    accounting_entry_id BIGINT REFERENCES bms.accounting_entries(entry_id),
    
    -- 비고
    description TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    -- 제약조건
    CONSTRAINT chk_withholding_tax_amounts CHECK (
        payment_amount >= 0 AND tax_base_amount >= 0 AND withholding_amount >= 0
    )
);

-- 세무 신고 일정 테이블
CREATE TABLE IF NOT EXISTS bms.tax_filing_schedule (
    schedule_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 신고 정보
    tax_type tax_type NOT NULL,
    filing_period VARCHAR(7) NOT NULL, -- YYYY-MM 형식
    filing_year INTEGER NOT NULL,
    filing_month INTEGER CHECK (filing_month BETWEEN 1 AND 12),
    
    -- 신고 기한
    due_date DATE NOT NULL,
    filing_deadline DATE NOT NULL,
    
    -- 신고 상태
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP,
    completed_by UUID REFERENCES bms.users(user_id),
    
    -- 알림 설정
    reminder_days_before INTEGER DEFAULT 7,
    reminder_sent BOOLEAN DEFAULT false,
    reminder_sent_at TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_tax_filing_schedule_company_type_period UNIQUE(company_id, tax_type, filing_period)
);

-- 세무 계산 규칙 테이블
CREATE TABLE IF NOT EXISTS bms.tax_calculation_rules (
    rule_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 규칙 정보
    rule_name VARCHAR(255) NOT NULL,
    tax_type tax_type NOT NULL,
    rule_code VARCHAR(50) NOT NULL,
    
    -- 적용 조건
    effective_from DATE NOT NULL,
    effective_to DATE,
    
    -- 계산 규칙 (JSON 형태로 저장)
    calculation_rules JSONB NOT NULL,
    
    -- 활성 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES bms.users(user_id),
    
    CONSTRAINT uk_tax_calculation_rules_company_code UNIQUE(company_id, rule_code)
);

-- 세무 검증 로그 테이블
CREATE TABLE IF NOT EXISTS bms.tax_validation_log (
    log_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 검증 대상
    entity_type VARCHAR(50) NOT NULL, -- TAX_TRANSACTION, VAT_RETURN, WITHHOLDING_TAX
    entity_id BIGINT NOT NULL,
    
    -- 검증 정보
    validation_type VARCHAR(50) NOT NULL,
    validation_rule VARCHAR(255),
    
    -- 검증 결과
    is_valid BOOLEAN NOT NULL,
    error_message TEXT,
    warning_message TEXT,
    
    -- 검증 시간
    validated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    validated_by UUID REFERENCES bms.users(user_id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_tax_transactions_company ON bms.tax_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_building ON bms.tax_transactions(building_id);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_date ON bms.tax_transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_type ON bms.tax_transactions(tax_type, transaction_type);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_filing_period ON bms.tax_transactions(filing_period);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_filing_status ON bms.tax_transactions(filing_status);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_invoice_number ON bms.tax_transactions(tax_invoice_number);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_supplier ON bms.tax_transactions(supplier_customer_registration_number);
CREATE INDEX IF NOT EXISTS idx_tax_transactions_accounting ON bms.tax_transactions(accounting_entry_id);

CREATE INDEX IF NOT EXISTS idx_vat_returns_company ON bms.vat_returns(company_id);
CREATE INDEX IF NOT EXISTS idx_vat_returns_filing_period ON bms.vat_returns(filing_period);
CREATE INDEX IF NOT EXISTS idx_vat_returns_status ON bms.vat_returns(filing_status);
CREATE INDEX IF NOT EXISTS idx_vat_returns_year_month ON bms.vat_returns(filing_year, filing_month);

CREATE INDEX IF NOT EXISTS idx_withholding_tax_company ON bms.withholding_tax(company_id);
CREATE INDEX IF NOT EXISTS idx_withholding_tax_payment_date ON bms.withholding_tax(payment_date);
CREATE INDEX IF NOT EXISTS idx_withholding_tax_payee ON bms.withholding_tax(payee_registration_number);
CREATE INDEX IF NOT EXISTS idx_withholding_tax_filing_period ON bms.withholding_tax(filing_period);
CREATE INDEX IF NOT EXISTS idx_withholding_tax_status ON bms.withholding_tax(filing_status);
CREATE INDEX IF NOT EXISTS idx_withholding_tax_accounting ON bms.withholding_tax(accounting_entry_id);

CREATE INDEX IF NOT EXISTS idx_tax_filing_schedule_company ON bms.tax_filing_schedule(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_filing_schedule_due_date ON bms.tax_filing_schedule(due_date);
CREATE INDEX IF NOT EXISTS idx_tax_filing_schedule_completed ON bms.tax_filing_schedule(is_completed);
CREATE INDEX IF NOT EXISTS idx_tax_filing_schedule_type_period ON bms.tax_filing_schedule(tax_type, filing_period);

CREATE INDEX IF NOT EXISTS idx_tax_calculation_rules_company ON bms.tax_calculation_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_calculation_rules_type ON bms.tax_calculation_rules(tax_type);
CREATE INDEX IF NOT EXISTS idx_tax_calculation_rules_active ON bms.tax_calculation_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_tax_calculation_rules_effective ON bms.tax_calculation_rules(effective_from, effective_to);

CREATE INDEX IF NOT EXISTS idx_tax_validation_log_company ON bms.tax_validation_log(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_validation_log_entity ON bms.tax_validation_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_tax_validation_log_validated_at ON bms.tax_validation_log(validated_at);

-- 세무 거래 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_tax_transaction_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
    prefix TEXT;
BEGIN
    -- 세무 유형에 따른 접두사 설정
    CASE NEW.tax_type
        WHEN 'VAT' THEN prefix := 'VT';
        WHEN 'INCOME_TAX' THEN prefix := 'IT';
        WHEN 'LOCAL_TAX' THEN prefix := 'LT';
        WHEN 'WITHHOLDING_TAX' THEN prefix := 'WT';
        WHEN 'CORPORATE_TAX' THEN prefix := 'CT';
        ELSE prefix := 'TX';
    END CASE;
    
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별, 유형별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(transaction_number FROM 9) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.tax_transactions 
    WHERE transaction_number LIKE prefix || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 거래번호 생성 (접두사 + YYYYMM + 4자리 순번)
    new_number := prefix || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.transaction_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 세무 거래 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_tax_transaction_number ON bms.tax_transactions;
CREATE TRIGGER trg_generate_tax_transaction_number
    BEFORE INSERT ON bms.tax_transactions
    FOR EACH ROW
    WHEN (NEW.transaction_number IS NULL OR NEW.transaction_number = '')
    EXECUTE FUNCTION bms.generate_tax_transaction_number();

-- 부가세 신고 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_vat_return_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(return_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.vat_returns 
    WHERE return_number LIKE 'VR' || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 신고번호 생성 (VR + YYYYMM + 4자리 순번)
    new_number := 'VR' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.return_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 부가세 신고 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_vat_return_number ON bms.vat_returns;
CREATE TRIGGER trg_generate_vat_return_number
    BEFORE INSERT ON bms.vat_returns
    FOR EACH ROW
    WHEN (NEW.return_number IS NULL OR NEW.return_number = '')
    EXECUTE FUNCTION bms.generate_vat_return_number();

-- 원천징수 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_withholding_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(withholding_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.withholding_tax 
    WHERE withholding_number LIKE 'WH' || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 원천징수번호 생성 (WH + YYYYMM + 4자리 순번)
    new_number := 'WH' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.withholding_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 원천징수 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_withholding_number ON bms.withholding_tax;
CREATE TRIGGER trg_generate_withholding_number
    BEFORE INSERT ON bms.withholding_tax
    FOR EACH ROW
    WHEN (NEW.withholding_number IS NULL OR NEW.withholding_number = '')
    EXECUTE FUNCTION bms.generate_withholding_number();

-- 세무 거래 금액 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_tax_transaction_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- 총 금액 = 공급가액 + 세액
    NEW.total_amount := NEW.supply_amount + NEW.tax_amount;
    
    -- 공제 가능 금액 설정 (기본적으로 세액과 동일)
    IF NEW.is_deductible THEN
        NEW.deduction_amount := NEW.tax_amount;
    ELSE
        NEW.deduction_amount := 0;
    END IF;
    
    -- 신고 기간 자동 설정 (거래일 기준)
    IF NEW.filing_period IS NULL THEN
        NEW.filing_period := TO_CHAR(NEW.transaction_date, 'YYYY-MM');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 세무 거래 금액 검증 트리거
DROP TRIGGER IF EXISTS trg_validate_tax_transaction_amounts ON bms.tax_transactions;
CREATE TRIGGER trg_validate_tax_transaction_amounts
    BEFORE INSERT OR UPDATE ON bms.tax_transactions
    FOR EACH ROW
    EXECUTE FUNCTION bms.validate_tax_transaction_amounts();

-- 원천징수 금액 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_withholding_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- 세무 기준액 설정 (기본적으로 지급액과 동일)
    IF NEW.tax_base_amount = 0 THEN
        NEW.tax_base_amount := NEW.payment_amount;
    END IF;
    
    -- 원천징수액 계산
    NEW.withholding_amount := ROUND(NEW.tax_base_amount * NEW.withholding_rate / 100, 0);
    
    -- 지방소득세 계산 (원천징수액의 10%)
    NEW.local_tax_amount := ROUND(NEW.withholding_amount * 0.1, 0);
    
    -- 신고 기간 자동 설정 (지급일 기준)
    IF NEW.filing_period IS NULL THEN
        NEW.filing_period := TO_CHAR(NEW.payment_date, 'YYYY-MM');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 원천징수 금액 계산 트리거
DROP TRIGGER IF EXISTS trg_calculate_withholding_amounts ON bms.withholding_tax;
CREATE TRIGGER trg_calculate_withholding_amounts
    BEFORE INSERT OR UPDATE ON bms.withholding_tax
    FOR EACH ROW
    EXECUTE FUNCTION bms.calculate_withholding_amounts();

-- 기본 세무 계산 규칙 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_tax_calculation_rules(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 부가세 계산 규칙
    INSERT INTO bms.tax_calculation_rules (
        company_id, rule_name, tax_type, rule_code, effective_from, calculation_rules
    ) VALUES (
        p_company_id, '일반 부가세 계산', 'VAT', 'VAT_GENERAL', '2024-01-01',
        '{"tax_rate": 10.0, "calculation_method": "supply_amount * tax_rate / 100"}'::jsonb
    ) ON CONFLICT (company_id, rule_code) DO NOTHING;
    
    -- 원천징수 계산 규칙 (사업소득)
    INSERT INTO bms.tax_calculation_rules (
        company_id, rule_name, tax_type, rule_code, effective_from, calculation_rules
    ) VALUES (
        p_company_id, '사업소득 원천징수', 'WITHHOLDING_TAX', 'WITHHOLDING_BUSINESS', '2024-01-01',
        '{"withholding_rate": 3.3, "local_tax_rate": 0.33, "calculation_method": "payment_amount * withholding_rate / 100"}'::jsonb
    ) ON CONFLICT (company_id, rule_code) DO NOTHING;
    
    -- 원천징수 계산 규칙 (기타소득)
    INSERT INTO bms.tax_calculation_rules (
        company_id, rule_name, tax_type, rule_code, effective_from, calculation_rules
    ) VALUES (
        p_company_id, '기타소득 원천징수', 'WITHHOLDING_TAX', 'WITHHOLDING_OTHER', '2024-01-01',
        '{"withholding_rate": 22.0, "local_tax_rate": 2.2, "calculation_method": "payment_amount * withholding_rate / 100"}'::jsonb
    ) ON CONFLICT (company_id, rule_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.tax_transactions IS '세무 거래 테이블 - 모든 세무 관련 거래 기록';
COMMENT ON TABLE bms.vat_returns IS '부가세 신고 테이블 - 월별 부가세 신고서 관리';
COMMENT ON TABLE bms.withholding_tax IS '원천징수 테이블 - 원천징수 대상 지급 및 세액 관리';
COMMENT ON TABLE bms.tax_filing_schedule IS '세무 신고 일정 테이블 - 세무 신고 기한 관리';
COMMENT ON TABLE bms.tax_calculation_rules IS '세무 계산 규칙 테이블 - 세무 계산 로직 정의';
COMMENT ON TABLE bms.tax_validation_log IS '세무 검증 로그 테이블 - 세무 데이터 검증 이력';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.tax_transactions.transaction_number IS '세무 거래 번호 - 세무유형별 접두사 + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.tax_transactions.filing_period IS '신고 기간 - YYYY-MM 형식';
COMMENT ON COLUMN bms.tax_transactions.is_deductible IS '공제 가능 여부 - 매입세액 공제 가능 여부';
COMMENT ON COLUMN bms.tax_transactions.tax_rate IS '세율 - 부가세율 (기본 10%)';

COMMENT ON COLUMN bms.vat_returns.return_number IS '부가세 신고 번호 - VR + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.vat_returns.net_tax_amount IS '순 세액 - 납부할 세액(+) 또는 환급받을 세액(-)';
COMMENT ON COLUMN bms.vat_returns.return_data IS '신고서 데이터 - JSON 형태로 저장된 신고서 상세 정보';

COMMENT ON COLUMN bms.withholding_tax.withholding_number IS '원천징수 번호 - WH + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.withholding_tax.withholding_rate IS '원천징수율 - 소득 유형별 원천징수율 (%)';
COMMENT ON COLUMN bms.withholding_tax.local_tax_amount IS '지방소득세 - 원천징수액의 10%';

COMMENT ON COLUMN bms.tax_filing_schedule.due_date IS '신고 기한 - 세무 신고 마감일';
COMMENT ON COLUMN bms.tax_filing_schedule.reminder_days_before IS '알림 일수 - 신고 기한 며칠 전에 알림을 보낼지 설정';

COMMENT ON COLUMN bms.tax_calculation_rules.calculation_rules IS '계산 규칙 - JSON 형태로 저장된 세무 계산 로직';
COMMENT ON COLUMN bms.tax_calculation_rules.effective_from IS '적용 시작일 - 규칙 적용 시작 날짜';
COMMENT ON COLUMN bms.tax_calculation_rules.effective_to IS '적용 종료일 - 규칙 적용 종료 날짜 (NULL이면 무기한)';