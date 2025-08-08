-- =====================================================
-- 거래 기록 및 분류 시스템 (Transaction System)
-- 회계 관리 시스템의 거래 관리 기능
-- =====================================================

-- 거래 테이블 (Transactions)
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    transaction_number VARCHAR(50) NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
    transaction_category VARCHAR(30) NOT NULL CHECK (transaction_category IN (
        'MANAGEMENT_FEE_INCOME', 'RENTAL_INCOME', 'PARKING_FEE_INCOME', 'OTHER_INCOME',
        'FACILITY_MAINTENANCE', 'PERSONNEL_EXPENSE', 'UTILITY_EXPENSE', 'INSURANCE_EXPENSE',
        'TAX_EXPENSE', 'REPAIR_EXPENSE', 'CLEANING_EXPENSE', 'SECURITY_EXPENSE', 'OTHER_EXPENSE'
    )),
    description TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    counterparty VARCHAR(255),
    counterparty_account VARCHAR(50),
    suggested_account_id UUID REFERENCES accounts(account_id),
    confidence_score DECIMAL(5,2) CHECK (confidence_score BETWEEN 0 AND 1),
    reference_type VARCHAR(50),
    reference_id UUID,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PROCESSED')),
    approved_by UUID,
    approved_at TIMESTAMP,
    rejection_reason TEXT,
    tags TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID,
    
    UNIQUE(company_id, transaction_number)
);

-- 거래 첨부파일 테이블 (Transaction Attachments)
CREATE TABLE IF NOT EXISTS transaction_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id UUID NOT NULL REFERENCES transactions(transaction_id) ON DELETE CASCADE,
    original_filename VARCHAR(255) NOT NULL,
    stored_filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    content_type VARCHAR(100) NOT NULL,
    file_type VARCHAR(20) NOT NULL CHECK (file_type IN ('RECEIPT', 'TAX_INVOICE', 'INVOICE', 'DEPOSIT_SLIP', 'CONTRACT', 'OTHER_DOCUMENT')),
    description TEXT,
    ocr_extracted_data JSONB,
    is_ocr_processed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 거래 분류 규칙 테이블 (Transaction Rules)
CREATE TABLE IF NOT EXISTS transaction_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    rule_name VARCHAR(255) NOT NULL,
    description TEXT,
    transaction_type VARCHAR(20) CHECK (transaction_type IN ('INCOME', 'EXPENSE')),
    transaction_category VARCHAR(30) CHECK (transaction_category IN (
        'MANAGEMENT_FEE_INCOME', 'RENTAL_INCOME', 'PARKING_FEE_INCOME', 'OTHER_INCOME',
        'FACILITY_MAINTENANCE', 'PERSONNEL_EXPENSE', 'UTILITY_EXPENSE', 'INSURANCE_EXPENSE',
        'TAX_EXPENSE', 'REPAIR_EXPENSE', 'CLEANING_EXPENSE', 'SECURITY_EXPENSE', 'OTHER_EXPENSE'
    )),
    counterparty_pattern VARCHAR(255),
    description_pattern VARCHAR(255),
    amount_min DECIMAL(15,2) CHECK (amount_min >= 0),
    amount_max DECIMAL(15,2) CHECK (amount_max >= 0),
    suggested_account_id UUID NOT NULL REFERENCES accounts(account_id),
    confidence_score DECIMAL(5,2) NOT NULL DEFAULT 0.80 CHECK (confidence_score BETWEEN 0 AND 1),
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    usage_count BIGINT DEFAULT 0,
    success_count BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_by UUID,
    
    UNIQUE(company_id, rule_name),
    CHECK (amount_min IS NULL OR amount_max IS NULL OR amount_min <= amount_max)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_transactions_company_date ON transactions(company_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_reference ON transactions(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(suggested_account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_counterparty ON transactions(counterparty);
CREATE INDEX IF NOT EXISTS idx_transactions_category ON transactions(transaction_category);

CREATE INDEX IF NOT EXISTS idx_transaction_attachments_transaction ON transaction_attachments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transaction_attachments_type ON transaction_attachments(file_type);
CREATE INDEX IF NOT EXISTS idx_transaction_attachments_ocr ON transaction_attachments(is_ocr_processed);

CREATE INDEX IF NOT EXISTS idx_transaction_rules_company ON transaction_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_transaction_rules_priority ON transaction_rules(priority);
CREATE INDEX IF NOT EXISTS idx_transaction_rules_active ON transaction_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_transaction_rules_type ON transaction_rules(transaction_type);
CREATE INDEX IF NOT EXISTS idx_transaction_rules_category ON transaction_rules(transaction_category);

-- =====================================================
-- 거래 처리 관련 함수들
-- =====================================================

-- 거래 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_transaction_number(
    p_company_id UUID,
    p_transaction_date DATE
)
RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(4);
    v_month VARCHAR(2);
    v_sequence INTEGER;
    v_transaction_number VARCHAR(50);
BEGIN
    v_year := EXTRACT(YEAR FROM p_transaction_date)::VARCHAR;
    v_month := LPAD(EXTRACT(MONTH FROM p_transaction_date)::VARCHAR, 2, '0');
    
    -- 해당 월의 마지막 순번 조회
    SELECT COALESCE(MAX(
        CASE 
            WHEN transaction_number ~ ('^TX' || v_year || v_month || '[0-9]+$') 
            THEN SUBSTRING(transaction_number FROM LENGTH('TX' || v_year || v_month) + 1)::INTEGER
            ELSE 0
        END
    ), 0) + 1
    INTO v_sequence
    FROM transactions
    WHERE company_id = p_company_id
        AND EXTRACT(YEAR FROM transaction_date) = EXTRACT(YEAR FROM p_transaction_date)
        AND EXTRACT(MONTH FROM transaction_date) = EXTRACT(MONTH FROM p_transaction_date);
    
    v_transaction_number := 'TX' || v_year || v_month || LPAD(v_sequence::VARCHAR, 4, '0');
    
    RETURN v_transaction_number;
END;
$$ LANGUAGE plpgsql;

-- 거래 분류 규칙 매칭 함수
CREATE OR REPLACE FUNCTION match_transaction_rules(
    p_company_id UUID,
    p_transaction_type VARCHAR(20),
    p_transaction_category VARCHAR(30),
    p_counterparty VARCHAR(255),
    p_description TEXT,
    p_amount DECIMAL(15,2)
)
RETURNS TABLE(
    rule_id UUID,
    suggested_account_id UUID,
    confidence_score DECIMAL(5,2),
    rule_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tr.rule_id,
        tr.suggested_account_id,
        tr.confidence_score,
        tr.rule_name
    FROM transaction_rules tr
    WHERE tr.company_id = p_company_id
        AND tr.is_active = true
        AND (tr.transaction_type IS NULL OR tr.transaction_type = p_transaction_type)
        AND (tr.transaction_category IS NULL OR tr.transaction_category = p_transaction_category)
        AND (tr.counterparty_pattern IS NULL OR p_counterparty ~ tr.counterparty_pattern)
        AND (tr.description_pattern IS NULL OR p_description ~ tr.description_pattern)
        AND (tr.amount_min IS NULL OR p_amount >= tr.amount_min)
        AND (tr.amount_max IS NULL OR p_amount <= tr.amount_max)
    ORDER BY tr.priority ASC, tr.confidence_score DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 거래 승인 함수
CREATE OR REPLACE FUNCTION approve_transaction(
    p_transaction_id UUID,
    p_account_id UUID,
    p_approved_by UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    -- 현재 상태 확인
    SELECT status INTO v_status
    FROM transactions
    WHERE transaction_id = p_transaction_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '거래를 찾을 수 없습니다: %', p_transaction_id;
    END IF;
    
    -- PENDING 상태만 승인 가능
    IF v_status != 'PENDING' THEN
        RAISE EXCEPTION '승인 대기 중인 거래만 승인할 수 있습니다. 현재 상태: %', v_status;
    END IF;
    
    -- 승인 처리
    UPDATE transactions
    SET 
        status = 'APPROVED',
        suggested_account_id = p_account_id,
        approved_by = p_approved_by,
        approved_at = CURRENT_TIMESTAMP,
        notes = COALESCE(p_notes, notes),
        updated_at = CURRENT_TIMESTAMP
    WHERE transaction_id = p_transaction_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 거래 거부 함수
CREATE OR REPLACE FUNCTION reject_transaction(
    p_transaction_id UUID,
    p_rejected_by UUID,
    p_reason TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    -- 현재 상태 확인
    SELECT status INTO v_status
    FROM transactions
    WHERE transaction_id = p_transaction_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '거래를 찾을 수 없습니다: %', p_transaction_id;
    END IF;
    
    -- PENDING 상태만 거부 가능
    IF v_status != 'PENDING' THEN
        RAISE EXCEPTION '승인 대기 중인 거래만 거부할 수 있습니다. 현재 상태: %', v_status;
    END IF;
    
    -- 거부 처리
    UPDATE transactions
    SET 
        status = 'REJECTED',
        approved_by = p_rejected_by,
        approved_at = CURRENT_TIMESTAMP,
        rejection_reason = p_reason,
        updated_at = CURRENT_TIMESTAMP
    WHERE transaction_id = p_transaction_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 거래 처리 완료 함수
CREATE OR REPLACE FUNCTION mark_transaction_processed(
    p_transaction_id UUID,
    p_journal_entry_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    -- 현재 상태 확인
    SELECT status INTO v_status
    FROM transactions
    WHERE transaction_id = p_transaction_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '거래를 찾을 수 없습니다: %', p_transaction_id;
    END IF;
    
    -- APPROVED 상태만 처리 가능
    IF v_status != 'APPROVED' THEN
        RAISE EXCEPTION '승인된 거래만 처리할 수 있습니다. 현재 상태: %', v_status;
    END IF;
    
    -- 처리 완료 표시
    UPDATE transactions
    SET 
        status = 'PROCESSED',
        updated_at = CURRENT_TIMESTAMP
    WHERE transaction_id = p_transaction_id;
    
    -- 분개 전표와 거래 연결 (journal_entries 테이블에 reference 정보 업데이트)
    UPDATE journal_entries
    SET 
        reference_type = 'TRANSACTION',
        reference_id = p_transaction_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE entry_id = p_journal_entry_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- 거래 분류 규칙 사용 횟수 증가 함수
CREATE OR REPLACE FUNCTION increment_rule_usage(
    p_rule_id UUID,
    p_is_success BOOLEAN DEFAULT FALSE
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE transaction_rules
    SET 
        usage_count = usage_count + 1,
        success_count = CASE WHEN p_is_success THEN success_count + 1 ELSE success_count END,
        updated_at = CURRENT_TIMESTAMP
    WHERE rule_id = p_rule_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 거래 조회 뷰
-- =====================================================

-- 거래 상세 뷰
CREATE OR REPLACE VIEW v_transaction_details AS
SELECT 
    t.transaction_id,
    t.company_id,
    t.transaction_number,
    t.transaction_date,
    t.transaction_type,
    t.transaction_category,
    t.description,
    t.amount,
    t.counterparty,
    t.counterparty_account,
    t.status,
    t.approved_by,
    t.approved_at,
    t.rejection_reason,
    t.tags,
    t.notes,
    t.created_at,
    t.updated_at,
    t.created_by,
    a.account_code,
    a.account_name,
    a.account_type,
    t.confidence_score,
    COUNT(ta.attachment_id) as attachment_count
FROM transactions t
LEFT JOIN accounts a ON t.suggested_account_id = a.account_id
LEFT JOIN transaction_attachments ta ON t.transaction_id = ta.transaction_id
GROUP BY t.transaction_id, a.account_code, a.account_name, a.account_type
ORDER BY t.transaction_date DESC, t.created_at DESC;

-- 거래 통계 뷰
CREATE OR REPLACE VIEW v_transaction_statistics AS
SELECT 
    t.company_id,
    EXTRACT(YEAR FROM t.transaction_date) as year,
    EXTRACT(MONTH FROM t.transaction_date) as month,
    t.transaction_type,
    t.transaction_category,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as average_amount,
    COUNT(CASE WHEN t.status = 'PENDING' THEN 1 END) as pending_count,
    COUNT(CASE WHEN t.status = 'APPROVED' THEN 1 END) as approved_count,
    COUNT(CASE WHEN t.status = 'REJECTED' THEN 1 END) as rejected_count,
    COUNT(CASE WHEN t.status = 'PROCESSED' THEN 1 END) as processed_count
FROM transactions t
WHERE t.status IN ('APPROVED', 'PROCESSED')
GROUP BY t.company_id, EXTRACT(YEAR FROM t.transaction_date), EXTRACT(MONTH FROM t.transaction_date), 
         t.transaction_type, t.transaction_category
ORDER BY year DESC, month DESC, t.transaction_type, t.transaction_category;

-- 거래처별 통계 뷰
CREATE OR REPLACE VIEW v_counterparty_statistics AS
SELECT 
    t.company_id,
    t.counterparty,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as average_amount,
    MIN(t.transaction_date) as first_transaction_date,
    MAX(t.transaction_date) as last_transaction_date,
    COUNT(DISTINCT t.suggested_account_id) as account_count
FROM transactions t
WHERE t.counterparty IS NOT NULL
    AND t.status IN ('APPROVED', 'PROCESSED')
GROUP BY t.company_id, t.counterparty
ORDER BY total_amount DESC;

-- 거래 분류 규칙 성과 뷰
CREATE OR REPLACE VIEW v_rule_performance AS
SELECT 
    tr.rule_id,
    tr.company_id,
    tr.rule_name,
    tr.transaction_type,
    tr.transaction_category,
    tr.priority,
    tr.is_active,
    tr.usage_count,
    tr.success_count,
    CASE 
        WHEN tr.usage_count > 0 THEN 
            ROUND((tr.success_count::DECIMAL / tr.usage_count::DECIMAL) * 100, 2)
        ELSE 0 
    END as success_rate_percent,
    a.account_code,
    a.account_name,
    tr.confidence_score,
    tr.created_at,
    tr.updated_at
FROM transaction_rules tr
JOIN accounts a ON tr.suggested_account_id = a.account_id
ORDER BY tr.usage_count DESC, success_rate_percent DESC;

-- =====================================================
-- 기본 거래 분류 규칙 데이터
-- =====================================================

-- 기본 거래 분류 규칙 삽입 함수
CREATE OR REPLACE FUNCTION insert_default_transaction_rules(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 수입 관련 기본 규칙
    INSERT INTO transaction_rules (company_id, rule_name, description, transaction_type, transaction_category, suggested_account_id, confidence_score, priority, created_by) 
    SELECT 
        p_company_id,
        '관리비 수입 기본 규칙',
        '관리비 수입을 관리비수익 계정으로 분류',
        'INCOME',
        'MANAGEMENT_FEE_INCOME',
        a.account_id,
        0.90,
        10,
        '00000000-0000-0000-0000-000000000000'::UUID
    FROM accounts a 
    WHERE a.company_id = p_company_id AND a.account_code = '4200'
    ON CONFLICT (company_id, rule_name) DO NOTHING;
    
    INSERT INTO transaction_rules (company_id, rule_name, description, transaction_type, transaction_category, suggested_account_id, confidence_score, priority, created_by) 
    SELECT 
        p_company_id,
        '임대료 수입 기본 규칙',
        '임대료 수입을 임대료수익 계정으로 분류',
        'INCOME',
        'RENTAL_INCOME',
        a.account_id,
        0.90,
        10,
        '00000000-0000-0000-0000-000000000000'::UUID
    FROM accounts a 
    WHERE a.company_id = p_company_id AND a.account_code = '4100'
    ON CONFLICT (company_id, rule_name) DO NOTHING;
    
    -- 지출 관련 기본 규칙
    INSERT INTO transaction_rules (company_id, rule_name, description, transaction_type, transaction_category, suggested_account_id, confidence_score, priority, created_by) 
    SELECT 
        p_company_id,
        '시설 관리비 기본 규칙',
        '시설 관리비를 관리비 계정으로 분류',
        'EXPENSE',
        'FACILITY_MAINTENANCE',
        a.account_id,
        0.85,
        20,
        '00000000-0000-0000-0000-000000000000'::UUID
    FROM accounts a 
    WHERE a.company_id = p_company_id AND a.account_code = '5100'
    ON CONFLICT (company_id, rule_name) DO NOTHING;
    
    INSERT INTO transaction_rules (company_id, rule_name, description, transaction_type, transaction_category, suggested_account_id, confidence_score, priority, created_by) 
    SELECT 
        p_company_id,
        '수선비 기본 규칙',
        '수선비를 수선비 계정으로 분류',
        'EXPENSE',
        'REPAIR_EXPENSE',
        a.account_id,
        0.85,
        20,
        '00000000-0000-0000-0000-000000000000'::UUID
    FROM accounts a 
    WHERE a.company_id = p_company_id AND a.account_code = '5200'
    ON CONFLICT (company_id, rule_name) DO NOTHING;
    
    INSERT INTO transaction_rules (company_id, rule_name, description, transaction_type, transaction_category, suggested_account_id, confidence_score, priority, created_by) 
    SELECT 
        p_company_id,
        '공과금 기본 규칙',
        '공과금을 세금과공과 계정으로 분류',
        'EXPENSE',
        'UTILITY_EXPENSE',
        a.account_id,
        0.85,
        20,
        '00000000-0000-0000-0000-000000000000'::UUID
    FROM accounts a 
    WHERE a.company_id = p_company_id AND a.account_code = '5300'
    ON CONFLICT (company_id, rule_name) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 테이블 코멘트
-- =====================================================

COMMENT ON TABLE transactions IS '거래 테이블 - 모든 수입/지출 거래 정보 관리';
COMMENT ON TABLE transaction_attachments IS '거래 첨부파일 테이블 - 영수증, 증빙서류 등 관리';
COMMENT ON TABLE transaction_rules IS '거래 분류 규칙 테이블 - 자동 계정과목 제안 규칙 관리';

-- 컬럼 코멘트
COMMENT ON COLUMN transactions.transaction_type IS '거래 유형 (INCOME: 수입, EXPENSE: 지출)';
COMMENT ON COLUMN transactions.transaction_category IS '거래 카테고리 (세부 분류)';
COMMENT ON COLUMN transactions.confidence_score IS '계정과목 제안 신뢰도 (0.0 ~ 1.0)';
COMMENT ON COLUMN transactions.status IS '거래 상태 (PENDING: 대기, APPROVED: 승인, REJECTED: 거부, PROCESSED: 처리완료)';

COMMENT ON COLUMN transaction_rules.counterparty_pattern IS '거래처 매칭 정규식 패턴';
COMMENT ON COLUMN transaction_rules.description_pattern IS '설명 매칭 정규식 패턴';
COMMENT ON COLUMN transaction_rules.priority IS '규칙 우선순위 (낮을수록 높은 우선순위)';
COMMENT ON COLUMN transaction_rules.usage_count IS '규칙 사용 횟수';
COMMENT ON COLUMN transaction_rules.success_count IS '규칙 성공 횟수 (사용자가 제안을 승인한 횟수)';