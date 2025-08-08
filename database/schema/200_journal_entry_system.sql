-- =====================================================
-- 분개 처리 시스템 (Journal Entry System)
-- 회계 관리 시스템의 핵심 분개 처리 기능
-- =====================================================

-- 계정과목 테이블 (Chart of Accounts)
CREATE TABLE IF NOT EXISTS accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    account_type VARCHAR(20) NOT NULL CHECK (account_type IN ('ASSET', 'LIABILITY', 'EQUITY', 'REVENUE', 'EXPENSE')),
    account_category VARCHAR(50),
    parent_account_id UUID REFERENCES accounts(account_id),
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID,
    
    UNIQUE(company_id, account_code)
);

-- 분개 전표 헤더 테이블 (Journal Entries)
CREATE TABLE IF NOT EXISTS journal_entries (
    entry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    entry_number VARCHAR(50) NOT NULL,
    entry_date DATE NOT NULL,
    entry_type VARCHAR(20) DEFAULT 'MANUAL' CHECK (entry_type IN ('MANUAL', 'AUTO', 'ADJUSTMENT', 'CLOSING')),
    reference_type VARCHAR(50),
    reference_id UUID,
    description TEXT NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING', 'APPROVED', 'POSTED', 'REVERSED')),
    created_by UUID NOT NULL,
    approved_by UUID,
    approved_at TIMESTAMP,
    posted_at TIMESTAMP,
    reversed_at TIMESTAMP,
    reversal_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(company_id, entry_number)
);

-- 분개 전표 상세 테이블 (Journal Entry Lines)
CREATE TABLE IF NOT EXISTS journal_entry_lines (
    line_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID NOT NULL REFERENCES journal_entries(entry_id) ON DELETE CASCADE,
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    debit_amount DECIMAL(15,2) DEFAULT 0,
    credit_amount DECIMAL(15,2) DEFAULT 0,
    description TEXT,
    reference_type VARCHAR(50),
    reference_id UUID,
    line_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 차변 또는 대변 중 하나만 값을 가져야 함
    CONSTRAINT chk_debit_or_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (debit_amount = 0 AND credit_amount > 0)
    ),
    
    -- 금액은 0보다 커야 함
    CONSTRAINT chk_positive_amount CHECK (debit_amount >= 0 AND credit_amount >= 0)
);

-- 회계 기간 테이블 (Financial Periods)
CREATE TABLE IF NOT EXISTS financial_periods (
    period_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    fiscal_year INTEGER NOT NULL,
    period_number INTEGER NOT NULL CHECK (period_number BETWEEN 1 AND 12),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED', 'LOCKED')),
    is_closed BOOLEAN DEFAULT false,
    closed_at TIMESTAMP,
    closed_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(company_id, fiscal_year, period_number)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_accounts_company_code ON accounts(company_id, account_code);
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_accounts_parent ON accounts(parent_account_id);

CREATE INDEX IF NOT EXISTS idx_journal_entries_company_date ON journal_entries(company_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_journal_entries_status ON journal_entries(status);
CREATE INDEX IF NOT EXISTS idx_journal_entries_number ON journal_entries(entry_number);
CREATE INDEX IF NOT EXISTS idx_journal_entries_reference ON journal_entries(reference_type, reference_id);

CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_entry ON journal_entry_lines(entry_id);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_account ON journal_entry_lines(account_id);
CREATE INDEX IF NOT EXISTS idx_journal_entry_lines_reference ON journal_entry_lines(reference_type, reference_id);

CREATE INDEX IF NOT EXISTS idx_financial_periods_company_year ON financial_periods(company_id, fiscal_year);
CREATE INDEX IF NOT EXISTS idx_financial_periods_status ON financial_periods(status);

-- =====================================================
-- 분개 처리 관련 함수들
-- =====================================================

-- 분개 전표 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_journal_entry_number(
    p_company_id UUID,
    p_entry_date DATE
)
RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(4);
    v_month VARCHAR(2);
    v_sequence INTEGER;
    v_entry_number VARCHAR(50);
BEGIN
    v_year := EXTRACT(YEAR FROM p_entry_date)::VARCHAR;
    v_month := LPAD(EXTRACT(MONTH FROM p_entry_date)::VARCHAR, 2, '0');
    
    -- 해당 월의 마지막 순번 조회
    SELECT COALESCE(MAX(
        CASE 
            WHEN entry_number ~ ('^JE' || v_year || v_month || '[0-9]+$') 
            THEN SUBSTRING(entry_number FROM LENGTH('JE' || v_year || v_month) + 1)::INTEGER
            ELSE 0
        END
    ), 0) + 1
    INTO v_sequence
    FROM journal_entries
    WHERE company_id = p_company_id
        AND EXTRACT(YEAR FROM entry_date) = EXTRACT(YEAR FROM p_entry_date)
        AND EXTRACT(MONTH FROM entry_date) = EXTRACT(MONTH FROM p_entry_date);
    
    v_entry_number := 'JE' || v_year || v_month || LPAD(v_sequence::VARCHAR, 4, '0');
    
    RETURN v_entry_number;
END;
$$ LANGUAGE plpgsql;

-- 복식부기 검증 함수
CREATE OR REPLACE FUNCTION validate_journal_entry_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_total_debit DECIMAL(15,2);
    v_total_credit DECIMAL(15,2);
    v_entry_id UUID;
BEGIN
    -- 변경된 분개 전표 ID 확인
    v_entry_id := COALESCE(NEW.entry_id, OLD.entry_id);
    
    -- 분개선의 차변/대변 합계 계산
    SELECT 
        COALESCE(SUM(debit_amount), 0),
        COALESCE(SUM(credit_amount), 0)
    INTO v_total_debit, v_total_credit
    FROM journal_entry_lines
    WHERE entry_id = v_entry_id;
    
    -- 분개 전표 헤더의 총 금액 업데이트
    UPDATE journal_entries 
    SET 
        total_amount = v_total_debit,
        updated_at = CURRENT_TIMESTAMP
    WHERE entry_id = v_entry_id;
    
    -- 복식부기 원칙 검증 (차변 = 대변)
    IF ABS(v_total_debit - v_total_credit) > 0.01 THEN
        RAISE EXCEPTION '복식부기 원칙 위반: 차변(%)과 대변(%)의 합계가 일치하지 않습니다.', 
            v_total_debit, v_total_credit;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 분개선 변경 시 자동 검증 트리거
CREATE OR REPLACE TRIGGER trg_validate_journal_entry_balance
    AFTER INSERT OR UPDATE OR DELETE ON journal_entry_lines
    FOR EACH ROW
    EXECUTE FUNCTION validate_journal_entry_balance();

-- 분개 전기 함수
CREATE OR REPLACE FUNCTION post_journal_entry(
    p_entry_id UUID,
    p_posted_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_company_id UUID;
    v_status VARCHAR(20);
    v_total_debit DECIMAL(15,2);
    v_total_credit DECIMAL(15,2);
BEGIN
    -- 분개 전표 정보 조회
    SELECT company_id, status
    INTO v_company_id, v_status
    FROM journal_entries
    WHERE entry_id = p_entry_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '분개 전표를 찾을 수 없습니다: %', p_entry_id;
    END IF;
    
    -- 상태 확인
    IF v_status != 'APPROVED' THEN
        RAISE EXCEPTION '승인된 분개 전표만 전기할 수 있습니다. 현재 상태: %', v_status;
    END IF;
    
    -- 복식부기 원칙 재검증
    SELECT 
        COALESCE(SUM(debit_amount), 0),
        COALESCE(SUM(credit_amount), 0)
    INTO v_total_debit, v_total_credit
    FROM journal_entry_lines
    WHERE entry_id = p_entry_id;
    
    IF ABS(v_total_debit - v_total_credit) > 0.01 THEN
        RAISE EXCEPTION '복식부기 원칙 위반으로 전기할 수 없습니다. 차변: %, 대변: %', 
            v_total_debit, v_total_credit;
    END IF;
    
    -- 분개 전표 상태를 POSTED로 변경
    UPDATE journal_entries
    SET 
        status = 'POSTED',
        posted_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE entry_id = p_entry_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 역분개 처리 함수
CREATE OR REPLACE FUNCTION reverse_journal_entry(
    p_entry_id UUID,
    p_reversal_reason TEXT,
    p_reversed_by UUID
)
RETURNS UUID AS $$
DECLARE
    v_original_entry journal_entries%ROWTYPE;
    v_new_entry_id UUID;
    v_new_entry_number VARCHAR(50);
    v_line_record RECORD;
BEGIN
    -- 원본 분개 전표 조회
    SELECT * INTO v_original_entry
    FROM journal_entries
    WHERE entry_id = p_entry_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '분개 전표를 찾을 수 없습니다: %', p_entry_id;
    END IF;
    
    -- 전기된 전표만 역분개 가능
    IF v_original_entry.status != 'POSTED' THEN
        RAISE EXCEPTION '전기된 분개 전표만 역분개할 수 있습니다. 현재 상태: %', v_original_entry.status;
    END IF;
    
    -- 새로운 전표 번호 생성
    v_new_entry_number := generate_journal_entry_number(
        v_original_entry.company_id, 
        CURRENT_DATE
    );
    
    -- 역분개 전표 생성
    INSERT INTO journal_entries (
        company_id, entry_number, entry_date, entry_type,
        reference_type, reference_id, description, total_amount,
        status, created_by, approved_by, approved_at
    )
    VALUES (
        v_original_entry.company_id,
        v_new_entry_number,
        CURRENT_DATE,
        'ADJUSTMENT',
        'REVERSAL',
        p_entry_id,
        '역분개: ' || v_original_entry.description || ' - ' || p_reversal_reason,
        v_original_entry.total_amount,
        'APPROVED',
        p_reversed_by,
        p_reversed_by,
        CURRENT_TIMESTAMP
    )
    RETURNING entry_id INTO v_new_entry_id;
    
    -- 원본 분개선을 반대로 생성
    FOR v_line_record IN
        SELECT * FROM journal_entry_lines
        WHERE entry_id = p_entry_id
        ORDER BY line_order
    LOOP
        INSERT INTO journal_entry_lines (
            entry_id, account_id, debit_amount, credit_amount,
            description, reference_type, reference_id, line_order
        )
        VALUES (
            v_new_entry_id,
            v_line_record.account_id,
            v_line_record.credit_amount,  -- 차변과 대변을 바꿈
            v_line_record.debit_amount,   -- 차변과 대변을 바꿈
            '역분개: ' || COALESCE(v_line_record.description, ''),
            'REVERSAL',
            v_line_record.line_id,
            v_line_record.line_order
        );
    END LOOP;
    
    -- 역분개 전표 즉시 전기
    PERFORM post_journal_entry(v_new_entry_id, p_reversed_by);
    
    -- 원본 전표 상태를 REVERSED로 변경
    UPDATE journal_entries
    SET 
        status = 'REVERSED',
        reversed_at = CURRENT_TIMESTAMP,
        reversal_reason = p_reversal_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE entry_id = p_entry_id;
    
    RETURN v_new_entry_id;
END;
$$ LANGUAGE plpgsql;

-- 분개 전표 승인 함수
CREATE OR REPLACE FUNCTION approve_journal_entry(
    p_entry_id UUID,
    p_approved_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    -- 현재 상태 확인
    SELECT status INTO v_status
    FROM journal_entries
    WHERE entry_id = p_entry_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '분개 전표를 찾을 수 없습니다: %', p_entry_id;
    END IF;
    
    -- PENDING 상태만 승인 가능
    IF v_status != 'PENDING' THEN
        RAISE EXCEPTION '승인 대기 중인 분개 전표만 승인할 수 있습니다. 현재 상태: %', v_status;
    END IF;
    
    -- 승인 처리
    UPDATE journal_entries
    SET 
        status = 'APPROVED',
        approved_by = p_approved_by,
        approved_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP
    WHERE entry_id = p_entry_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 분개 조회 뷰
-- =====================================================

-- 분개 전표 상세 뷰
CREATE OR REPLACE VIEW v_journal_entry_details AS
SELECT 
    je.entry_id,
    je.company_id,
    je.entry_number,
    je.entry_date,
    je.entry_type,
    je.description as entry_description,
    je.total_amount,
    je.status,
    je.created_by,
    je.approved_by,
    je.approved_at,
    je.posted_at,
    je.created_at,
    jel.line_id,
    jel.account_id,
    a.account_code,
    a.account_name,
    a.account_type,
    jel.debit_amount,
    jel.credit_amount,
    jel.description as line_description,
    jel.line_order
FROM journal_entries je
JOIN journal_entry_lines jel ON je.entry_id = jel.entry_id
JOIN accounts a ON jel.account_id = a.account_id
ORDER BY je.entry_date DESC, je.entry_number, jel.line_order;

-- 계정별 원장 뷰
CREATE OR REPLACE VIEW v_general_ledger AS
SELECT 
    a.company_id,
    a.account_id,
    a.account_code,
    a.account_name,
    a.account_type,
    je.entry_date,
    je.entry_number,
    je.description as entry_description,
    jel.debit_amount,
    jel.credit_amount,
    jel.description as line_description,
    je.status,
    je.created_at,
    -- 누적 잔액 계산 (윈도우 함수 사용)
    SUM(jel.debit_amount - jel.credit_amount) OVER (
        PARTITION BY a.account_id 
        ORDER BY je.entry_date, je.entry_number, jel.line_order
        ROWS UNBOUNDED PRECEDING
    ) as running_balance
FROM accounts a
JOIN journal_entry_lines jel ON a.account_id = jel.account_id
JOIN journal_entries je ON jel.entry_id = je.entry_id
WHERE je.status = 'POSTED'
ORDER BY a.account_code, je.entry_date, je.entry_number, jel.line_order;

-- 시산표 뷰
CREATE OR REPLACE VIEW v_trial_balance AS
SELECT 
    a.company_id,
    a.account_id,
    a.account_code,
    a.account_name,
    a.account_type,
    COALESCE(SUM(jel.debit_amount), 0) as total_debit,
    COALESCE(SUM(jel.credit_amount), 0) as total_credit,
    COALESCE(SUM(jel.debit_amount - jel.credit_amount), 0) as balance
FROM accounts a
LEFT JOIN journal_entry_lines jel ON a.account_id = jel.account_id
LEFT JOIN journal_entries je ON jel.entry_id = je.entry_id AND je.status = 'POSTED'
WHERE a.is_active = true
GROUP BY a.company_id, a.account_id, a.account_code, a.account_name, a.account_type
ORDER BY a.account_code;

-- =====================================================
-- 기본 계정과목 데이터
-- =====================================================

-- 기본 계정과목 삽입 함수
CREATE OR REPLACE FUNCTION insert_default_accounts(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 자산 계정
    INSERT INTO accounts (company_id, account_code, account_name, account_type, description) VALUES
    (p_company_id, '1100', '현금', 'ASSET', '현금 및 현금성 자산'),
    (p_company_id, '1200', '예금', 'ASSET', '은행 예금'),
    (p_company_id, '1300', '미수금', 'ASSET', '임대료 및 관리비 미수금'),
    (p_company_id, '1400', '보증금', 'ASSET', '임차인으로부터 받은 보증금'),
    (p_company_id, '1500', '건물', 'ASSET', '건물 자산'),
    (p_company_id, '1600', '감가상각누계액', 'ASSET', '건물 감가상각 누계액'),
    
    -- 부채 계정
    (p_company_id, '2100', '미지급금', 'LIABILITY', '각종 미지급 비용'),
    (p_company_id, '2200', '예수보증금', 'LIABILITY', '임차인에게 받은 보증금'),
    (p_company_id, '2300', '미지급세금', 'LIABILITY', '미지급 세금'),
    
    -- 자본 계정
    (p_company_id, '3100', '자본금', 'EQUITY', '소유자 자본금'),
    (p_company_id, '3200', '이익잉여금', 'EQUITY', '누적 이익잉여금'),
    
    -- 수익 계정
    (p_company_id, '4100', '임대료수익', 'REVENUE', '임대료 수익'),
    (p_company_id, '4200', '관리비수익', 'REVENUE', '관리비 수익'),
    (p_company_id, '4300', '기타수익', 'REVENUE', '기타 수익'),
    
    -- 비용 계정
    (p_company_id, '5100', '관리비', 'EXPENSE', '건물 관리비용'),
    (p_company_id, '5200', '수선비', 'EXPENSE', '건물 수선 및 유지비'),
    (p_company_id, '5300', '세금과공과', 'EXPENSE', '세금 및 공과금'),
    (p_company_id, '5400', '감가상각비', 'EXPENSE', '건물 감가상각비'),
    (p_company_id, '5500', '기타비용', 'EXPENSE', '기타 운영비용');
    
    -- 현재 연도 회계 기간 생성
    PERFORM create_financial_periods(p_company_id, EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER);
END;
$$ LANGUAGE plpgsql;

-- 회계 기간 생성 함수
CREATE OR REPLACE FUNCTION create_financial_periods(
    p_company_id UUID,
    p_fiscal_year INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_month INTEGER;
    v_start_date DATE;
    v_end_date DATE;
BEGIN
    FOR v_month IN 1..12 LOOP
        v_start_date := DATE(p_fiscal_year || '-' || LPAD(v_month::TEXT, 2, '0') || '-01');
        v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;
        
        INSERT INTO financial_periods (
            company_id, fiscal_year, period_number, 
            start_date, end_date
        )
        VALUES (
            p_company_id, p_fiscal_year, v_month,
            v_start_date, v_end_date
        )
        ON CONFLICT (company_id, fiscal_year, period_number) DO NOTHING;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 테이블 코멘트
-- =====================================================

COMMENT ON TABLE accounts IS '계정과목 마스터 테이블 - 회계 계정 정보 관리';
COMMENT ON TABLE journal_entries IS '분개 전표 헤더 테이블 - 분개 전표의 기본 정보';
COMMENT ON TABLE journal_entry_lines IS '분개 전표 상세 테이블 - 분개선별 차변/대변 정보';
COMMENT ON TABLE financial_periods IS '회계 기간 테이블 - 회계 기간 관리';

-- 컬럼 코멘트
COMMENT ON COLUMN accounts.account_code IS '계정 코드 (회사별 유니크)';
COMMENT ON COLUMN accounts.account_type IS '계정 유형 (ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE)';
COMMENT ON COLUMN accounts.parent_account_id IS '상위 계정 ID (계층 구조)';

COMMENT ON COLUMN journal_entries.entry_number IS '분개 전표 번호 (회사별 유니크)';
COMMENT ON COLUMN journal_entries.entry_type IS '분개 유형 (MANUAL, AUTO, ADJUSTMENT, CLOSING)';
COMMENT ON COLUMN journal_entries.status IS '분개 상태 (DRAFT, PENDING, APPROVED, POSTED, REVERSED)';
COMMENT ON COLUMN journal_entries.total_amount IS '분개 전표 총 금액 (차변 = 대변)';

COMMENT ON COLUMN journal_entry_lines.debit_amount IS '차변 금액';
COMMENT ON COLUMN journal_entry_lines.credit_amount IS '대변 금액';
COMMENT ON COLUMN journal_entry_lines.line_order IS '분개선 순서';

COMMENT ON COLUMN financial_periods.fiscal_year IS '회계 연도';
COMMENT ON COLUMN financial_periods.period_number IS '회계 기간 번호 (1-12월)';
COMMENT ON COLUMN financial_periods.status IS '기간 상태 (OPEN, CLOSED, LOCKED)';