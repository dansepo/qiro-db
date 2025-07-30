-- =====================================================
-- 회계 관리 테이블 설계 (Accounting Management)
-- =====================================================

-- 계정과목 테이블 (Chart of Accounts)
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

-- 회계 전표 테이블 (Journal Entries)
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
    
    -- 복식부기 원칙: 차변과 대변의 합계가 일치해야 함
    CONSTRAINT chk_debit_credit_balance CHECK (total_debit = total_credit)
);

-- 회계 전표 상세 테이블 (Journal Entry Details)
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
    
    -- 차변 또는 대변 중 하나만 값을 가져야 함
    CONSTRAINT chk_debit_or_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (debit_amount = 0 AND credit_amount > 0)
    )
);

-- 회계 기간 테이블 (Accounting Periods)
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

-- 계정별 잔액 테이블 (Account Balances)
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

-- 재무제표 템플릿 테이블 (Financial Statement Templates)
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

-- 인덱스 생성
CREATE INDEX idx_journal_entries_building_date ON journal_entries(building_id, entry_date);
CREATE INDEX idx_journal_entries_status ON journal_entries(status);
CREATE INDEX idx_journal_entries_reference ON journal_entries(reference_number);
CREATE INDEX idx_journal_entry_details_journal_id ON journal_entry_details(journal_entry_id);
CREATE INDEX idx_journal_entry_details_account_id ON journal_entry_details(account_id);
CREATE INDEX idx_account_balances_building_period ON account_balances(building_id, period_id);
CREATE INDEX idx_chart_of_accounts_code ON chart_of_accounts(account_code);
CREATE INDEX idx_chart_of_accounts_type ON chart_of_accounts(account_type);

-- 복식부기 검증을 위한 트리거 함수
CREATE OR REPLACE FUNCTION validate_journal_entry_balance()
RETURNS TRIGGER AS $$
DECLARE
    total_debit DECIMAL(15,2);
    total_credit DECIMAL(15,2);
BEGIN
    -- 전표 상세의 차변/대변 합계 계산
    SELECT 
        COALESCE(SUM(debit_amount), 0),
        COALESCE(SUM(credit_amount), 0)
    INTO total_debit, total_credit
    FROM journal_entry_details
    WHERE journal_entry_id = COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);
    
    -- 전표 헤더의 합계 업데이트
    UPDATE journal_entries 
    SET 
        total_debit = total_debit,
        total_credit = total_credit,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.journal_entry_id, OLD.journal_entry_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 전표 상세 변경 시 자동으로 합계 업데이트하는 트리거
CREATE TRIGGER trg_validate_journal_entry_balance
    AFTER INSERT OR UPDATE OR DELETE ON journal_entry_details
    FOR EACH ROW
    EXECUTE FUNCTION validate_journal_entry_balance();

-- 계정 잔액 업데이트 함수
CREATE OR REPLACE FUNCTION update_account_balance(
    p_building_id BIGINT,
    p_account_id BIGINT,
    p_period_id BIGINT
)
RETURNS VOID AS $$
DECLARE
    v_debit_total DECIMAL(15,2);
    v_credit_total DECIMAL(15,2);
    v_opening_balance DECIMAL(15,2);
    v_closing_balance DECIMAL(15,2);
    v_account_type VARCHAR(20);
BEGIN
    -- 계정 유형 조회
    SELECT account_type INTO v_account_type
    FROM chart_of_accounts
    WHERE id = p_account_id;
    
    -- 해당 기간의 차변/대변 합계 계산
    SELECT 
        COALESCE(SUM(jed.debit_amount), 0),
        COALESCE(SUM(jed.credit_amount), 0)
    INTO v_debit_total, v_credit_total
    FROM journal_entry_details jed
    JOIN journal_entries je ON jed.journal_entry_id = je.id
    JOIN accounting_periods ap ON je.building_id = ap.building_id 
        AND je.entry_date BETWEEN ap.start_date AND ap.end_date
    WHERE je.building_id = p_building_id
        AND jed.account_id = p_account_id
        AND ap.id = p_period_id
        AND je.status = 'POSTED';
    
    -- 이전 기간 마감 잔액을 기초 잔액으로 설정 (구현 단순화를 위해 0으로 설정)
    v_opening_balance := 0;
    
    -- 계정 유형에 따른 잔액 계산
    IF v_account_type IN ('ASSET', 'EXPENSE') THEN
        v_closing_balance := v_opening_balance + v_debit_total - v_credit_total;
    ELSE
        v_closing_balance := v_opening_balance + v_credit_total - v_debit_total;
    END IF;
    
    -- 계정 잔액 테이블 업데이트 또는 삽입
    INSERT INTO account_balances (
        building_id, account_id, period_id, 
        opening_balance, debit_total, credit_total, closing_balance
    )
    VALUES (
        p_building_id, p_account_id, p_period_id,
        v_opening_balance, v_debit_total, v_credit_total, v_closing_balance
    )
    ON CONFLICT (building_id, account_id, period_id)
    DO UPDATE SET
        opening_balance = v_opening_balance,
        debit_total = v_debit_total,
        credit_total = v_credit_total,
        closing_balance = v_closing_balance,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 재무제표 생성을 위한 뷰 (Financial Statement Views)
-- =====================================================

-- 손익계산서 뷰 (Income Statement View)
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

-- 대차대조표 뷰 (Balance Sheet View)
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

-- 계정별 원장 뷰 (General Ledger View)
CREATE VIEW v_general_ledger AS
SELECT 
    je.building_id,
    je.entry_date,
    je.reference_number,
    je.description as journal_description,
    coa.account_code,
    coa.account_name,
    coa.account_type,
    jed.debit_amount,
    jed.credit_amount,
    jed.description as detail_description,
    je.status,
    je.created_by,
    je.created_at
FROM journal_entries je
JOIN journal_entry_details jed ON je.id = jed.journal_entry_id
JOIN chart_of_accounts coa ON jed.account_id = coa.id
WHERE je.status = 'POSTED'
ORDER BY je.entry_date, je.id, jed.id;

-- 월별 손익 요약 뷰 (Monthly Profit & Loss Summary)
CREATE VIEW v_monthly_pnl_summary AS
SELECT 
    building_id,
    period_year,
    period_month,
    SUM(revenue_amount) as total_revenue,
    SUM(expense_amount) as total_expense,
    SUM(revenue_amount) - SUM(expense_amount) as net_income
FROM v_income_statement
GROUP BY building_id, period_year, period_month;

-- =====================================================
-- 회계 마감 관련 함수
-- =====================================================

-- 회계 기간 마감 함수
CREATE OR REPLACE FUNCTION close_accounting_period(
    p_building_id BIGINT,
    p_period_year INTEGER,
    p_period_month INTEGER,
    p_closed_by BIGINT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_period_id BIGINT;
    v_total_debit DECIMAL(15,2);
    v_total_credit DECIMAL(15,2);
BEGIN
    -- 회계 기간 조회
    SELECT id INTO v_period_id
    FROM accounting_periods
    WHERE building_id = p_building_id
        AND period_year = p_period_year
        AND period_month = p_period_month
        AND status = 'OPEN';
    
    IF v_period_id IS NULL THEN
        RAISE EXCEPTION '마감할 수 있는 회계 기간이 없습니다.';
    END IF;
    
    -- 해당 기간의 모든 전표가 전기되었는지 확인
    SELECT COUNT(*)
    FROM journal_entries je
    JOIN accounting_periods ap ON je.building_id = ap.building_id
        AND je.entry_date BETWEEN ap.start_date AND ap.end_date
    WHERE ap.id = v_period_id
        AND je.status = 'DRAFT';
    
    IF FOUND THEN
        RAISE EXCEPTION '전기되지 않은 전표가 있어 마감할 수 없습니다.';
    END IF;
    
    -- 모든 계정의 잔액 업데이트
    PERFORM update_account_balance(p_building_id, coa.id, v_period_id)
    FROM chart_of_accounts coa
    WHERE coa.is_active = true;
    
    -- 차변/대변 합계 검증
    SELECT 
        SUM(CASE WHEN account_type IN ('ASSET', 'EXPENSE') THEN closing_balance ELSE 0 END),
        SUM(CASE WHEN account_type IN ('LIABILITY', 'EQUITY', 'REVENUE') THEN closing_balance ELSE 0 END)
    INTO v_total_debit, v_total_credit
    FROM account_balances ab
    JOIN chart_of_accounts coa ON ab.account_id = coa.id
    WHERE ab.building_id = p_building_id
        AND ab.period_id = v_period_id;
    
    IF ABS(v_total_debit - v_total_credit) > 0.01 THEN
        RAISE EXCEPTION '차변과 대변의 합계가 일치하지 않습니다. 차변: %, 대변: %', v_total_debit, v_total_credit;
    END IF;
    
    -- 회계 기간 마감
    UPDATE accounting_periods
    SET 
        status = 'CLOSED',
        closed_at = CURRENT_TIMESTAMP,
        closed_by = p_closed_by,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_period_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

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

-- 코멘트 추가
COMMENT ON TABLE chart_of_accounts IS '계정과목 마스터 테이블';
COMMENT ON TABLE journal_entries IS '회계 전표 헤더 테이블';
COMMENT ON TABLE journal_entry_details IS '회계 전표 상세 테이블';
COMMENT ON TABLE accounting_periods IS '회계 기간 관리 테이블';
COMMENT ON TABLE account_balances IS '계정별 잔액 관리 테이블';
COMMENT ON TABLE financial_statement_templates IS '재무제표 템플릿 테이블';

COMMENT ON COLUMN journal_entries.total_debit IS '전표의 총 차변 금액';
COMMENT ON COLUMN journal_entries.total_credit IS '전표의 총 대변 금액';
COMMENT ON CONSTRAINT chk_debit_credit_balance ON journal_entries IS '복식부기 원칙: 차변과 대변의 합계 일치';
COMMENT ON CONSTRAINT chk_debit_or_credit ON journal_entry_details IS '차변 또는 대변 중 하나만 값을 가져야 함';