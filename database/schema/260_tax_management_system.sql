-- 세금 관리 시스템 스키마
-- 부가세 계산 및 신고서 생성, 원천징수 관리, 세금계산서 발행 및 수취 관리

-- 세금 신고 테이블
CREATE TABLE IF NOT EXISTS bms.tax_returns (
    tax_return_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    tax_type VARCHAR(20) NOT NULL,
    return_period VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_sales DECIMAL(15,2) DEFAULT 0,
    total_purchases DECIMAL(15,2) DEFAULT 0,
    vat_payable DECIMAL(15,2) DEFAULT 0,
    vat_receivable DECIMAL(15,2) DEFAULT 0,
    net_vat DECIMAL(15,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'DRAFT',
    submitted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tax_type CHECK (tax_type IN ('VAT', 'INCOME', 'CORPORATE')),
    CONSTRAINT chk_return_status CHECK (status IN ('DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'))
);

COMMENT ON TABLE bms.tax_returns IS '세금 신고 테이블';

-- 세금계산서 테이블
CREATE TABLE IF NOT EXISTS bms.tax_invoices (
    tax_invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    invoice_type VARCHAR(20) NOT NULL,
    invoice_number VARCHAR(50) NOT NULL,
    issue_date DATE NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_business_number VARCHAR(20) NOT NULL,
    buyer_name VARCHAR(100) NOT NULL,
    buyer_business_number VARCHAR(20) NOT NULL,
    supply_amount DECIMAL(15,2) NOT NULL,
    vat_amount DECIMAL(15,2) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'ISSUED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_invoice_type CHECK (invoice_type IN ('SALES', 'PURCHASE', 'CREDIT_NOTE', 'DEBIT_NOTE')),
    CONSTRAINT chk_invoice_status CHECK (status IN ('ISSUED', 'SENT', 'RECEIVED', 'CANCELLED'))
);

COMMENT ON TABLE bms.tax_invoices IS '세금계산서 테이블';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_tax_returns_company_period ON bms.tax_returns(company_id, return_period);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_company_date ON bms.tax_invoices(company_id, issue_date);