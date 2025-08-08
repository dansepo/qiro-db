-- 은행 계좌 관리 시스템 스키마
-- 은행 계좌 정보 및 잔액 관리, 거래 내역 자동 가져오기, 자동 매칭 및 대사 기능

-- 은행 계좌 테이블
CREATE TABLE IF NOT EXISTS bms.bank_accounts (
    bank_account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    bank_name VARCHAR(50) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    account_type VARCHAR(20) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KRW',
    current_balance DECIMAL(15,2) DEFAULT 0,
    available_balance DECIMAL(15,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, bank_name, account_number),
    CONSTRAINT chk_account_type CHECK (account_type IN ('CHECKING', 'SAVINGS', 'DEPOSIT', 'LOAN'))
);

COMMENT ON TABLE bms.bank_accounts IS '은행 계좌 테이블';

-- 은행 거래 내역 테이블
CREATE TABLE IF NOT EXISTS bms.bank_transactions (
    bank_transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bank_account_id UUID NOT NULL REFERENCES bms.bank_accounts(bank_account_id),
    company_id UUID NOT NULL,
    transaction_date DATE NOT NULL,
    transaction_time TIME,
    transaction_type VARCHAR(20) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2),
    counterpart_name VARCHAR(100),
    counterpart_account VARCHAR(50),
    description TEXT,
    reference_number VARCHAR(100),
    is_matched BOOLEAN DEFAULT false,
    matched_transaction_id UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER_IN', 'TRANSFER_OUT', 'FEE', 'INTEREST'))
);

COMMENT ON TABLE bms.bank_transactions IS '은행 거래 내역 테이블';

-- 자동 매칭 규칙 테이블
CREATE TABLE IF NOT EXISTS bms.bank_matching_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    rule_name VARCHAR(100) NOT NULL,
    rule_type VARCHAR(20) NOT NULL,
    pattern VARCHAR(200) NOT NULL,
    target_account_id UUID,
    priority INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rule_type CHECK (rule_type IN ('COUNTERPART_NAME', 'DESCRIPTION', 'AMOUNT', 'REFERENCE'))
);

COMMENT ON TABLE bms.bank_matching_rules IS '자동 매칭 규칙 테이블';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_bank_accounts_company_id ON bms.bank_accounts(company_id);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_account_date ON bms.bank_transactions(bank_account_id, transaction_date);
CREATE INDEX IF NOT EXISTS idx_bank_transactions_matched ON bms.bank_transactions(company_id, is_matched);