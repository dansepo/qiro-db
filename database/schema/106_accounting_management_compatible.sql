-- =====================================================
-- 민원 및 회계 관리 시스템 - 회계 관리 테이블 (기존 구조 호환)
-- 작성일: 2025-01-30
-- 요구사항: 4.1, 4.2, 5.1 - 수입/지출 관리, 예산 관리, 분석
-- =====================================================

-- 회계 관련 ENUM 타입 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_type') THEN
        CREATE TYPE account_type AS ENUM ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'entry_status') THEN
        CREATE TYPE entry_status AS ENUM ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'POSTED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'budget_status') THEN
        CREATE TYPE budget_status AS ENUM ('DRAFT', 'APPROVED', 'ACTIVE', 'CLOSED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'approval_status') THEN
        CREATE TYPE approval_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');
    END IF;
END $$;

-- 계정과목 테이블
CREATE TABLE IF NOT EXISTS bms.account_codes (
    account_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type account_type NOT NULL,
    parent_account_id BIGINT REFERENCES bms.account_codes(account_id),
    account_level INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    is_system_account BOOLEAN DEFAULT false,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    CONSTRAINT uk_account_codes_company_code UNIQUE(company_id, account_code)
);

-- 회계 항목 테이블 (수입/지출 통합 관리)
CREATE TABLE IF NOT EXISTS bms.accounting_entries (
    entry_id BIGSERIAL PRIMARY KEY,
    entry_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    building_id UUID REFERENCES bms.buildings(building_id),
    entry_date DATE NOT NULL,
    entry_type VARCHAR(20) NOT NULL CHECK (entry_type IN ('REVENUE', 'EXPENSE', 'TRANSFER', 'ADJUSTMENT')),
    
    -- 계정 정보
    account_code_id BIGINT NOT NULL REFERENCES bms.account_codes(account_id),
    
    -- 금액 정보
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    net_amount DECIMAL(15,2) NOT NULL,
    
    -- 거래 설명
    description TEXT NOT NULL,
    reference_number VARCHAR(50),
    reference_document_type VARCHAR(50),
    reference_document_id BIGINT,
    
    -- 예산 연결
    budget_item_id BIGINT,
    
    -- 승인 관리
    approval_status approval_status NOT NULL DEFAULT 'PENDING',
    approved_by UUID REFERENCES bms.users(user_id),
    approved_at TIMESTAMP,
    approval_comment TEXT,
    
    -- 회계 처리 상태
    entry_status entry_status NOT NULL DEFAULT 'DRAFT',
    posted_by UUID REFERENCES bms.users(user_id),
    posted_at TIMESTAMP,
    
    -- 회계 연도/월
    fiscal_year INTEGER NOT NULL,
    fiscal_month INTEGER NOT NULL CHECK (fiscal_month BETWEEN 1 AND 12),
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    -- 제약조건
    CONSTRAINT chk_accounting_entries_debit_or_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (debit_amount = 0 AND credit_amount > 0) OR
        (debit_amount = 0 AND credit_amount = 0 AND entry_type = 'ADJUSTMENT')
    ),
    CONSTRAINT chk_accounting_entries_approved_fields CHECK (
        (approval_status = 'APPROVED' AND approved_by IS NOT NULL AND approved_at IS NOT NULL) OR
        (approval_status != 'APPROVED')
    )
);

-- 예산 계획 테이블
CREATE TABLE IF NOT EXISTS bms.budget_plans (
    budget_id BIGSERIAL PRIMARY KEY,
    budget_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    building_id UUID REFERENCES bms.buildings(building_id),
    
    -- 예산 기본 정보
    budget_name VARCHAR(255) NOT NULL,
    fiscal_year INTEGER NOT NULL,
    budget_type VARCHAR(20) NOT NULL CHECK (budget_type IN ('ANNUAL', 'MONTHLY', 'QUARTERLY', 'PROJECT')),
    budget_category VARCHAR(50) NOT NULL,
    
    -- 계정 정보
    account_code_id BIGINT NOT NULL REFERENCES bms.account_codes(account_id),
    
    -- 예산 금액
    planned_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    allocated_amount DECIMAL(15,2) DEFAULT 0,
    executed_amount DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2) DEFAULT 0,
    execution_rate DECIMAL(5,2) DEFAULT 0,
    
    -- 예산 기간
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- 예산 상태
    budget_status budget_status NOT NULL DEFAULT 'DRAFT',
    
    -- 승인 정보
    approved_by UUID REFERENCES bms.users(user_id),
    approved_at TIMESTAMP,
    
    -- 설명 및 비고
    description TEXT,
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id),
    
    -- 제약조건
    CONSTRAINT chk_budget_plans_date_range CHECK (end_date >= start_date),
    CONSTRAINT chk_budget_plans_amounts CHECK (planned_amount >= 0 AND allocated_amount >= 0)
);

-- 재무 보고서 테이블
CREATE TABLE IF NOT EXISTS bms.financial_reports (
    report_id BIGSERIAL PRIMARY KEY,
    report_number VARCHAR(20) UNIQUE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    building_id UUID REFERENCES bms.buildings(building_id),
    
    -- 보고서 기본 정보
    report_name VARCHAR(255) NOT NULL,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('INCOME_STATEMENT', 'BALANCE_SHEET', 'CASH_FLOW', 'BUDGET_ANALYSIS', 'CUSTOM')),
    report_period_type VARCHAR(20) NOT NULL CHECK (report_period_type IN ('MONTHLY', 'QUARTERLY', 'YEARLY', 'CUSTOM')),
    
    -- 보고서 기간
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    fiscal_year INTEGER NOT NULL,
    
    -- 보고서 데이터
    report_data JSONB NOT NULL,
    summary_data JSONB,
    
    -- 보고서 상태
    is_finalized BOOLEAN DEFAULT false,
    finalized_by UUID REFERENCES bms.users(user_id),
    finalized_at TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_by UUID REFERENCES bms.users(user_id)
);

-- 수입/지출 분류 테이블
CREATE TABLE IF NOT EXISTS bms.transaction_categories (
    category_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_type VARCHAR(20) NOT NULL CHECK (category_type IN ('REVENUE', 'EXPENSE')),
    parent_category_id BIGINT REFERENCES bms.transaction_categories(category_id),
    account_code_id BIGINT REFERENCES bms.account_codes(account_id),
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_transaction_categories_company_code UNIQUE(company_id, category_code)
);

-- 승인 워크플로우 테이블
CREATE TABLE IF NOT EXISTS bms.approval_workflows (
    workflow_id BIGSERIAL PRIMARY KEY,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    workflow_name VARCHAR(255) NOT NULL,
    workflow_type VARCHAR(50) NOT NULL,
    
    -- 승인 조건
    amount_threshold DECIMAL(15,2),
    approval_levels INTEGER DEFAULT 1,
    approval_rules JSONB,
    
    -- 승인자 설정
    approvers JSONB NOT NULL,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES bms.users(user_id)
);

-- 승인 요청 테이블
CREATE TABLE IF NOT EXISTS bms.approval_requests (
    request_id BIGSERIAL PRIMARY KEY,
    workflow_id BIGINT NOT NULL REFERENCES bms.approval_workflows(workflow_id),
    entity_type VARCHAR(50) NOT NULL,
    entity_id BIGINT NOT NULL,
    
    -- 요청 정보
    request_title VARCHAR(255) NOT NULL,
    request_description TEXT,
    request_amount DECIMAL(15,2),
    
    -- 현재 승인 단계
    current_level INTEGER DEFAULT 1,
    current_approver UUID REFERENCES bms.users(user_id),
    
    -- 승인 상태
    approval_status approval_status NOT NULL DEFAULT 'PENDING',
    final_approved_by UUID REFERENCES bms.users(user_id),
    final_approved_at TIMESTAMP,
    
    -- 요청자 정보
    requested_by UUID NOT NULL REFERENCES bms.users(user_id),
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 완료 정보
    completed_at TIMESTAMP,
    rejection_reason TEXT
);

-- 승인 이력 테이블
CREATE TABLE IF NOT EXISTS bms.approval_history (
    history_id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES bms.approval_requests(request_id) ON DELETE CASCADE,
    approval_level INTEGER NOT NULL,
    approver_id UUID NOT NULL REFERENCES bms.users(user_id),
    
    -- 승인 결과
    approval_action VARCHAR(20) NOT NULL CHECK (approval_action IN ('APPROVED', 'REJECTED', 'DELEGATED')),
    approval_comment TEXT,
    
    -- 위임 정보 (DELEGATED인 경우)
    delegated_to UUID REFERENCES bms.users(user_id),
    
    -- 승인 시간
    approved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_account_codes_company ON bms.account_codes(company_id);
CREATE INDEX IF NOT EXISTS idx_account_codes_type ON bms.account_codes(account_type);
CREATE INDEX IF NOT EXISTS idx_account_codes_parent ON bms.account_codes(parent_account_id);
CREATE INDEX IF NOT EXISTS idx_account_codes_active ON bms.account_codes(is_active);

CREATE INDEX IF NOT EXISTS idx_accounting_entries_company ON bms.accounting_entries(company_id);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_building ON bms.accounting_entries(building_id);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_date ON bms.accounting_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_type ON bms.accounting_entries(entry_type);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_account ON bms.accounting_entries(account_code_id);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_status ON bms.accounting_entries(entry_status);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_approval ON bms.accounting_entries(approval_status);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_fiscal ON bms.accounting_entries(fiscal_year, fiscal_month);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_number ON bms.accounting_entries(entry_number);
CREATE INDEX IF NOT EXISTS idx_accounting_entries_budget ON bms.accounting_entries(budget_item_id);

CREATE INDEX IF NOT EXISTS idx_budget_plans_company ON bms.budget_plans(company_id);
CREATE INDEX IF NOT EXISTS idx_budget_plans_building ON bms.budget_plans(building_id);
CREATE INDEX IF NOT EXISTS idx_budget_plans_fiscal_year ON bms.budget_plans(fiscal_year);
CREATE INDEX IF NOT EXISTS idx_budget_plans_account ON bms.budget_plans(account_code_id);
CREATE INDEX IF NOT EXISTS idx_budget_plans_status ON bms.budget_plans(budget_status);
CREATE INDEX IF NOT EXISTS idx_budget_plans_category ON bms.budget_plans(budget_category);
CREATE INDEX IF NOT EXISTS idx_budget_plans_date_range ON bms.budget_plans(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_financial_reports_company ON bms.financial_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_financial_reports_building ON bms.financial_reports(building_id);
CREATE INDEX IF NOT EXISTS idx_financial_reports_type ON bms.financial_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_financial_reports_fiscal_year ON bms.financial_reports(fiscal_year);
CREATE INDEX IF NOT EXISTS idx_financial_reports_date_range ON bms.financial_reports(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_transaction_categories_company ON bms.transaction_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_transaction_categories_type ON bms.transaction_categories(category_type);
CREATE INDEX IF NOT EXISTS idx_transaction_categories_parent ON bms.transaction_categories(parent_category_id);

CREATE INDEX IF NOT EXISTS idx_approval_workflows_company ON bms.approval_workflows(company_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflows_type ON bms.approval_workflows(workflow_type);

CREATE INDEX IF NOT EXISTS idx_approval_requests_workflow ON bms.approval_requests(workflow_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_entity ON bms.approval_requests(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON bms.approval_requests(approval_status);
CREATE INDEX IF NOT EXISTS idx_approval_requests_approver ON bms.approval_requests(current_approver);
CREATE INDEX IF NOT EXISTS idx_approval_requests_requested_by ON bms.approval_requests(requested_by);

CREATE INDEX IF NOT EXISTS idx_approval_history_request ON bms.approval_history(request_id);
CREATE INDEX IF NOT EXISTS idx_approval_history_approver ON bms.approval_history(approver_id);

-- 회계 항목 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_accounting_entry_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
    prefix TEXT;
BEGIN
    -- 항목 유형에 따른 접두사 설정
    CASE NEW.entry_type
        WHEN 'REVENUE' THEN prefix := 'R';
        WHEN 'EXPENSE' THEN prefix := 'E';
        WHEN 'TRANSFER' THEN prefix := 'T';
        WHEN 'ADJUSTMENT' THEN prefix := 'A';
        ELSE prefix := 'G';
    END CASE;
    
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별, 유형별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(entry_number FROM 9) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.accounting_entries 
    WHERE entry_number LIKE prefix || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 항목번호 생성 (접두사 + YYYYMM + 4자리 순번)
    new_number := prefix || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.entry_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 회계 항목 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_accounting_entry_number ON bms.accounting_entries;
CREATE TRIGGER trg_generate_accounting_entry_number
    BEFORE INSERT ON bms.accounting_entries
    FOR EACH ROW
    WHEN (NEW.entry_number IS NULL OR NEW.entry_number = '')
    EXECUTE FUNCTION bms.generate_accounting_entry_number();

-- 예산 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_budget_number()
RETURNS TRIGGER AS $$
DECLARE
    year_text TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYY 형식으로 년도 생성
    year_text := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    -- 해당 년도의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(budget_number FROM 6) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.budget_plans 
    WHERE budget_number LIKE 'B' || year_text || '%'
      AND company_id = NEW.company_id;
    
    -- 예산번호 생성 (B + YYYY + 4자리 순번)
    new_number := 'B' || year_text || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.budget_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 예산 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_budget_number ON bms.budget_plans;
CREATE TRIGGER trg_generate_budget_number
    BEFORE INSERT ON bms.budget_plans
    FOR EACH ROW
    WHEN (NEW.budget_number IS NULL OR NEW.budget_number = '')
    EXECUTE FUNCTION bms.generate_budget_number();

-- 보고서 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_report_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
    prefix TEXT;
BEGIN
    -- 보고서 유형에 따른 접두사 설정
    CASE NEW.report_type
        WHEN 'INCOME_STATEMENT' THEN prefix := 'IS';
        WHEN 'BALANCE_SHEET' THEN prefix := 'BS';
        WHEN 'CASH_FLOW' THEN prefix := 'CF';
        WHEN 'BUDGET_ANALYSIS' THEN prefix := 'BA';
        ELSE prefix := 'RP';
    END CASE;
    
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별, 유형별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(report_number FROM 9) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.financial_reports 
    WHERE report_number LIKE prefix || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 보고서번호 생성 (접두사 + YYYYMM + 4자리 순번)
    new_number := prefix || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.report_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 보고서 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_report_number ON bms.financial_reports;
CREATE TRIGGER trg_generate_report_number
    BEFORE INSERT ON bms.financial_reports
    FOR EACH ROW
    WHEN (NEW.report_number IS NULL OR NEW.report_number = '')
    EXECUTE FUNCTION bms.generate_report_number();

-- 예산 집행률 자동 계산 함수
CREATE OR REPLACE FUNCTION bms.update_budget_execution()
RETURNS TRIGGER AS $$
BEGIN
    -- 예산 항목이 연결된 경우 집행률 업데이트
    IF NEW.budget_item_id IS NOT NULL AND NEW.entry_status = 'POSTED' THEN
        UPDATE bms.budget_plans
        SET 
            executed_amount = (
                SELECT COALESCE(SUM(net_amount), 0)
                FROM bms.accounting_entries
                WHERE budget_item_id = NEW.budget_item_id
                  AND entry_status = 'POSTED'
            ),
            updated_at = CURRENT_TIMESTAMP
        WHERE budget_id = NEW.budget_item_id;
        
        -- 집행률 및 잔여 금액 계산
        UPDATE bms.budget_plans
        SET 
            remaining_amount = planned_amount - executed_amount,
            execution_rate = CASE 
                WHEN planned_amount > 0 THEN 
                    ROUND((executed_amount / planned_amount * 100), 2)
                ELSE 0 
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE budget_id = NEW.budget_item_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 예산 집행률 자동 계산 트리거
DROP TRIGGER IF EXISTS trg_update_budget_execution ON bms.accounting_entries;
CREATE TRIGGER trg_update_budget_execution
    AFTER INSERT OR UPDATE ON bms.accounting_entries
    FOR EACH ROW
    EXECUTE FUNCTION bms.update_budget_execution();

-- 회계 연도/월 자동 설정 함수
CREATE OR REPLACE FUNCTION bms.set_fiscal_period()
RETURNS TRIGGER AS $$
BEGIN
    -- 회계 연도/월 자동 설정 (entry_date 기준)
    NEW.fiscal_year := EXTRACT(YEAR FROM NEW.entry_date);
    NEW.fiscal_month := EXTRACT(MONTH FROM NEW.entry_date);
    
    -- net_amount 계산
    IF NEW.debit_amount > 0 THEN
        NEW.net_amount := NEW.debit_amount;
    ELSE
        NEW.net_amount := NEW.credit_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 회계 연도/월 자동 설정 트리거
DROP TRIGGER IF EXISTS trg_set_fiscal_period ON bms.accounting_entries;
CREATE TRIGGER trg_set_fiscal_period
    BEFORE INSERT OR UPDATE ON bms.accounting_entries
    FOR EACH ROW
    EXECUTE FUNCTION bms.set_fiscal_period();

-- 기본 계정과목 데이터 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_account_codes(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.account_codes (company_id, account_code, account_name, account_type, description, is_system_account) VALUES
    -- 자산 계정
    (p_company_id, '1100', '현금', 'ASSET', '현금 및 현금성 자산', true),
    (p_company_id, '1200', '예금', 'ASSET', '은행 예금', true),
    (p_company_id, '1300', '미수금', 'ASSET', '임대료 및 관리비 미수금', true),
    (p_company_id, '1400', '보증금', 'ASSET', '임차인으로부터 받은 보증금', true),
    (p_company_id, '1500', '건물', 'ASSET', '건물 자산', true),
    (p_company_id, '1600', '감가상각누계액', 'ASSET', '건물 감가상각 누계액', true),
    
    -- 부채 계정
    (p_company_id, '2100', '미지급금', 'LIABILITY', '각종 미지급 비용', true),
    (p_company_id, '2200', '예수보증금', 'LIABILITY', '임차인에게 받은 보증금', true),
    (p_company_id, '2300', '미지급세금', 'LIABILITY', '미지급 세금', true),
    
    -- 자본 계정
    (p_company_id, '3100', '자본금', 'EQUITY', '소유자 자본금', true),
    (p_company_id, '3200', '이익잉여금', 'EQUITY', '누적 이익잉여금', true),
    
    -- 수익 계정
    (p_company_id, '4100', '임대료수익', 'REVENUE', '임대료 수익', true),
    (p_company_id, '4200', '관리비수익', 'REVENUE', '관리비 수익', true),
    (p_company_id, '4300', '기타수익', 'REVENUE', '기타 수익', true),
    
    -- 비용 계정
    (p_company_id, '5100', '관리비', 'EXPENSE', '건물 관리비용', true),
    (p_company_id, '5200', '수선비', 'EXPENSE', '건물 수선 및 유지비', true),
    (p_company_id, '5300', '세금과공과', 'EXPENSE', '세금 및 공과금', true),
    (p_company_id, '5400', '감가상각비', 'EXPENSE', '건물 감가상각비', true),
    (p_company_id, '5500', '기타비용', 'EXPENSE', '기타 운영비용', true)
    ON CONFLICT (company_id, account_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 기본 거래 분류 데이터 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_transaction_categories(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.transaction_categories (company_id, category_code, category_name, category_type, description) VALUES
    -- 수익 분류
    (p_company_id, 'REV001', '임대료 수익', 'REVENUE', '건물 임대료 수익'),
    (p_company_id, 'REV002', '관리비 수익', 'REVENUE', '공용 관리비 수익'),
    (p_company_id, 'REV003', '주차료 수익', 'REVENUE', '주차장 이용료 수익'),
    (p_company_id, 'REV004', '기타 수익', 'REVENUE', '기타 부대 수익'),
    
    -- 비용 분류
    (p_company_id, 'EXP001', '시설 관리비', 'EXPENSE', '건물 시설 관리 비용'),
    (p_company_id, 'EXP002', '수선 유지비', 'EXPENSE', '건물 수선 및 유지 비용'),
    (p_company_id, 'EXP003', '공과금', 'EXPENSE', '전기, 가스, 수도 등 공과금'),
    (p_company_id, 'EXP004', '보험료', 'EXPENSE', '건물 보험료'),
    (p_company_id, 'EXP005', '세금', 'EXPENSE', '각종 세금 및 공과금'),
    (p_company_id, 'EXP006', '인건비', 'EXPENSE', '관리 인건비'),
    (p_company_id, 'EXP007', '기타 비용', 'EXPENSE', '기타 운영 비용')
    ON CONFLICT (company_id, category_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.account_codes IS '계정과목 마스터 테이블 - 회계 처리를 위한 계정 체계';
COMMENT ON TABLE bms.accounting_entries IS '회계 항목 테이블 - 모든 수입/지출 거래 기록';
COMMENT ON TABLE bms.budget_plans IS '예산 계획 테이블 - 연간/월간 예산 계획 및 집행 관리';
COMMENT ON TABLE bms.financial_reports IS '재무 보고서 테이블 - 각종 재무 보고서 생성 및 관리';
COMMENT ON TABLE bms.transaction_categories IS '거래 분류 테이블 - 수입/지출 거래의 세부 분류';
COMMENT ON TABLE bms.approval_workflows IS '승인 워크플로우 테이블 - 회계 승인 프로세스 정의';
COMMENT ON TABLE bms.approval_requests IS '승인 요청 테이블 - 회계 항목 승인 요청 관리';
COMMENT ON TABLE bms.approval_history IS '승인 이력 테이블 - 승인 과정의 모든 이력 기록';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.accounting_entries.entry_number IS '회계 항목 번호 - 유형별 접두사 + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.accounting_entries.net_amount IS '순 금액 - 차변 또는 대변 금액';
COMMENT ON COLUMN bms.accounting_entries.approval_status IS '승인 상태 - PENDING(대기), APPROVED(승인), REJECTED(거부), CANCELLED(취소)';
COMMENT ON COLUMN bms.accounting_entries.entry_status IS '회계 처리 상태 - DRAFT(초안), PENDING_APPROVAL(승인대기), APPROVED(승인), POSTED(전기), CANCELLED(취소)';

COMMENT ON COLUMN bms.budget_plans.budget_number IS '예산 번호 - B + YYYY + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.budget_plans.execution_rate IS '예산 집행률 - 집행금액/계획금액 * 100 (%)';
COMMENT ON COLUMN bms.budget_plans.remaining_amount IS '잔여 예산 - 계획금액 - 집행금액';

COMMENT ON COLUMN bms.financial_reports.report_number IS '보고서 번호 - 유형별 접두사 + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.financial_reports.report_data IS '보고서 데이터 - JSON 형태로 저장된 보고서 상세 데이터';
COMMENT ON COLUMN bms.financial_reports.summary_data IS '요약 데이터 - JSON 형태로 저장된 보고서 요약 정보';