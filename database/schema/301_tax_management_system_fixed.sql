-- =====================================================
-- 세무 관리 시스템 (Tax Management System) - 수정버전
-- 파일: database/schema/301_tax_management_system_fixed.sql
-- 설명: 부가세, 원천징수, 세금계산서 관리 시스템
-- 생성일: 2025-01-08
-- =====================================================

-- 스키마 설정
SET search_path TO bms;

-- =====================================================
-- 1. 기존 vat_returns 테이블 수정
-- =====================================================

-- 필요한 컬럼 추가
ALTER TABLE vat_returns 
ADD COLUMN IF NOT EXISTS tax_period_id UUID,
ADD COLUMN IF NOT EXISTS due_date DATE,
ADD COLUMN IF NOT EXISTS zero_rate_sales_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS exempt_sales_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS input_vat_deduction_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS additional_tax_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS total_tax_amount DECIMAL(15,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS submission_reference VARCHAR(100),
ADD COLUMN IF NOT EXISTS calculation_data JSONB,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- 기존 컬럼명 매핑을 위한 뷰 생성
CREATE OR REPLACE VIEW vat_returns_view AS
SELECT 
    return_id as id,
    company_id,
    tax_period_id,
    return_type,
    due_date,
    filed_at as filing_date,
    
    -- 매출 관련 (기존 컬럼 매핑)
    taxable_sales_amount,
    zero_rate_sales_amount,
    exempt_sales_amount,
    output_tax_amount as output_vat_amount,
    
    -- 매입 관련 (기존 컬럼 매핑)
    deductible_purchase_amount as taxable_purchases_amount,
    input_tax_amount as input_vat_amount,
    input_vat_deduction_amount,
    
    -- 계산 결과 (기존 컬럼 매핑)
    net_tax_amount as net_vat_amount,
    additional_tax_amount,
    total_tax_amount,
    
    -- 상태 관리
    filing_status::text as status,
    submission_reference,
    
    -- 메타데이터
    calculation_data,
    notes,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM vat_returns;

-- =====================================================
-- 2. 원천징수 관리 테이블 (새로 생성)
-- =====================================================
CREATE TABLE IF NOT EXISTS withholding_taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    tax_period_id UUID,
    
    -- 지급 정보
    payment_date DATE NOT NULL,
    payee_name VARCHAR(200) NOT NULL,
    payee_registration_number VARCHAR(20),
    payee_address TEXT,
    
    -- 소득 정보
    income_type VARCHAR(50) NOT NULL CHECK (income_type IN ('SALARY', 'BONUS', 'RETIREMENT', 'BUSINESS', 'PROFESSIONAL', 'OTHER')),
    income_amount DECIMAL(15,2) NOT NULL,
    tax_rate DECIMAL(5,4) NOT NULL,
    withholding_amount DECIMAL(15,2) NOT NULL,
    
    -- 신고 정보
    report_date DATE,
    report_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (report_status IN ('PENDING', 'REPORTED', 'CORRECTED')),
    report_reference VARCHAR(100),
    
    -- 메타데이터
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE withholding_taxes IS '원천징수 관리';
COMMENT ON COLUMN withholding_taxes.income_type IS '소득 유형 (급여, 상여, 퇴직, 사업, 전문직, 기타)';
COMMENT ON COLUMN withholding_taxes.tax_rate IS '원천징수율';

-- =====================================================
-- 3. 세금계산서 관리 테이블 (새로 생성)
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_invoices_new (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 세금계산서 기본 정보
    invoice_type VARCHAR(20) NOT NULL CHECK (invoice_type IN ('ISSUED', 'RECEIVED', 'MODIFIED', 'CANCELLED')),
    invoice_number VARCHAR(50) NOT NULL,
    issue_date DATE NOT NULL,
    
    -- 공급자 정보
    supplier_name VARCHAR(200) NOT NULL,
    supplier_registration_number VARCHAR(20) NOT NULL,
    supplier_address TEXT,
    supplier_contact VARCHAR(100),
    
    -- 공급받는자 정보
    buyer_name VARCHAR(200) NOT NULL,
    buyer_registration_number VARCHAR(20) NOT NULL,
    buyer_address TEXT,
    buyer_contact VARCHAR(100),
    
    -- 금액 정보
    supply_amount DECIMAL(15,2) NOT NULL,
    vat_amount DECIMAL(15,2) NOT NULL,
    total_amount DECIMAL(15,2) NOT NULL,
    
    -- 품목 정보
    item_description TEXT,
    item_details JSONB,
    
    -- 전자세금계산서 정보
    electronic_invoice_id VARCHAR(100),
    nts_confirmation_number VARCHAR(100),
    
    -- 상태 관리
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ISSUED', 'SENT', 'RECEIVED', 'CONFIRMED', 'CANCELLED')),
    
    -- 연동 정보
    related_transaction_id UUID,
    related_expense_id UUID,
    related_income_id UUID,
    
    -- 메타데이터
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE tax_invoices_new IS '세금계산서 관리';
COMMENT ON COLUMN tax_invoices_new.invoice_type IS '세금계산서 유형 (발행, 수취, 수정, 취소)';
COMMENT ON COLUMN tax_invoices_new.electronic_invoice_id IS '전자세금계산서 ID';
COMMENT ON COLUMN tax_invoices_new.nts_confirmation_number IS '국세청 승인번호';

-- =====================================================
-- 4. 세무 서류 관리 테이블 (새로 생성)
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 서류 정보
    document_name VARCHAR(200) NOT NULL,
    document_type VARCHAR(50) NOT NULL CHECK (document_type IN ('VAT_RETURN', 'WITHHOLDING_REPORT', 'TAX_INVOICE', 'RECEIPT', 'CONTRACT', 'OTHER')),
    document_category VARCHAR(50),
    
    -- 파일 정보
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    file_type VARCHAR(50),
    
    -- 관련 정보
    related_tax_period_id UUID REFERENCES tax_periods(id),
    related_vat_return_id BIGINT REFERENCES vat_returns(return_id),
    related_withholding_id UUID REFERENCES withholding_taxes(id),
    related_tax_invoice_id UUID REFERENCES tax_invoices_new(id),
    
    -- 보관 정보
    retention_period INTEGER DEFAULT 5, -- 보관 연수
    expiry_date DATE,
    
    -- 메타데이터
    description TEXT,
    tags VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE tax_documents IS '세무 서류 관리';
COMMENT ON COLUMN tax_documents.document_type IS '서류 유형 (부가세신고서, 원천징수신고서, 세금계산서, 영수증, 계약서, 기타)';
COMMENT ON COLUMN tax_documents.retention_period IS '법정 보관 기간 (년)';

-- =====================================================
-- 인덱스 생성
-- =====================================================

-- 원천징수 인덱스
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_company ON withholding_taxes(company_id);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_period ON withholding_taxes(tax_period_id);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_payment_date ON withholding_taxes(payment_date);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_payee ON withholding_taxes(payee_registration_number);

-- 세금계산서 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_company ON tax_invoices_new(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_type ON tax_invoices_new(invoice_type);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_issue_date ON tax_invoices_new(issue_date);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_supplier ON tax_invoices_new(supplier_registration_number);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_buyer ON tax_invoices_new(buyer_registration_number);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_new_number ON tax_invoices_new(invoice_number);

-- 세무 서류 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_documents_company ON tax_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_documents_type ON tax_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_tax_documents_period ON tax_documents(related_tax_period_id);

-- =====================================================
-- 비즈니스 함수 (수정버전)
-- =====================================================

-- 부가세 계산 함수 (기존 테이블 구조 사용)
CREATE OR REPLACE FUNCTION calculate_vat_return_fixed(
    p_company_id UUID,
    p_filing_year INTEGER,
    p_filing_month INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_taxable_sales DECIMAL(15,2) := 0;
    v_output_vat DECIMAL(15,2) := 0;
    v_input_vat DECIMAL(15,2) := 0;
    v_net_vat DECIMAL(15,2) := 0;
BEGIN
    -- 매출세액 계산 (세금계산서 발행분)
    SELECT 
        COALESCE(SUM(supply_amount), 0),
        COALESCE(SUM(vat_amount), 0)
    INTO v_taxable_sales, v_output_vat
    FROM tax_invoices_new
    WHERE company_id = p_company_id
      AND invoice_type = 'ISSUED'
      AND EXTRACT(YEAR FROM issue_date) = p_filing_year
      AND EXTRACT(MONTH FROM issue_date) = p_filing_month
      AND status IN ('ISSUED', 'SENT', 'CONFIRMED');
    
    -- 매입세액 계산 (세금계산서 수취분)
    SELECT 
        COALESCE(SUM(vat_amount), 0)
    INTO v_input_vat
    FROM tax_invoices_new
    WHERE company_id = p_company_id
      AND invoice_type = 'RECEIVED'
      AND EXTRACT(YEAR FROM issue_date) = p_filing_year
      AND EXTRACT(MONTH FROM issue_date) = p_filing_month
      AND status IN ('RECEIVED', 'CONFIRMED');
    
    -- 납부할 부가세 계산
    v_net_vat := v_output_vat - v_input_vat;
    
    -- 결과 JSON 생성
    v_result := jsonb_build_object(
        'taxable_sales_amount', v_taxable_sales,
        'output_vat_amount', v_output_vat,
        'input_vat_amount', v_input_vat,
        'net_vat_amount', v_net_vat,
        'calculation_date', CURRENT_TIMESTAMP
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_vat_return_fixed IS '부가세 신고서 자동 계산 (수정버전)';

-- 원천징수 집계 함수
CREATE OR REPLACE FUNCTION calculate_withholding_summary(
    p_company_id UUID,
    p_year INTEGER,
    p_month INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_total_income DECIMAL(15,2) := 0;
    v_total_withholding DECIMAL(15,2) := 0;
    v_count INTEGER := 0;
BEGIN
    -- 월별 원천징수 집계
    SELECT 
        COUNT(*),
        COALESCE(SUM(income_amount), 0),
        COALESCE(SUM(withholding_amount), 0)
    INTO v_count, v_total_income, v_total_withholding
    FROM withholding_taxes
    WHERE company_id = p_company_id
      AND EXTRACT(YEAR FROM payment_date) = p_year
      AND EXTRACT(MONTH FROM payment_date) = p_month;
    
    -- 결과 JSON 생성
    v_result := jsonb_build_object(
        'total_count', v_count,
        'total_income_amount', v_total_income,
        'total_withholding_amount', v_total_withholding,
        'calculation_date', CURRENT_TIMESTAMP
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_withholding_summary IS '원천징수 월별 집계';

-- =====================================================
-- 테스트 데이터 삽입
-- =====================================================

-- 원천징수 테스트 데이터
INSERT INTO withholding_taxes (
    company_id, payment_date, payee_name, payee_registration_number,
    income_type, income_amount, tax_rate, withholding_amount, notes
) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', '2025-01-15', '김철수', '123-45-67890', 'PROFESSIONAL', 1000000, 0.033, 33000, '컨설팅 용역비'),
    ('550e8400-e29b-41d4-a716-446655440000', '2025-01-20', '박영희', '234-56-78901', 'BUSINESS', 500000, 0.033, 16500, '디자인 용역비'),
    ('550e8400-e29b-41d4-a716-446655440000', '2025-01-25', '이민수', '345-67-89012', 'PROFESSIONAL', 800000, 0.033, 26400, '법무 자문료')
ON CONFLICT DO NOTHING;

-- 세금계산서 테스트 데이터
INSERT INTO tax_invoices_new (
    company_id, invoice_type, invoice_number, issue_date,
    supplier_name, supplier_registration_number, buyer_name, buyer_registration_number,
    supply_amount, vat_amount, total_amount, item_description, status
) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'ISSUED', '2025-001', '2025-01-10', 
     '(주)큐로', '123-45-67890', '(주)고객사', '234-56-78901', 
     1000000, 100000, 1100000, '관리 서비스', 'ISSUED'),
    ('550e8400-e29b-41d4-a716-446655440000', 'RECEIVED', '2025-002', '2025-01-15', 
     '(주)공급업체', '345-67-89012', '(주)큐로', '123-45-67890', 
     500000, 50000, 550000, '사무용품 구매', 'RECEIVED'),
    ('550e8400-e29b-41d4-a716-446655440000', 'ISSUED', '2025-003', '2025-01-20', 
     '(주)큐로', '123-45-67890', '(주)고객사2', '456-78-90123', 
     2000000, 200000, 2200000, '시설 관리 서비스', 'CONFIRMED')
ON CONFLICT DO NOTHING;

-- 세무 서류 테스트 데이터
INSERT INTO tax_documents (
    company_id, document_name, document_type, file_name, file_path,
    description
) VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', '2024년 4분기 부가세 신고서', 'VAT_RETURN', 'vat_return_2024_q4.pdf', '/tax/documents/vat_return_2024_q4.pdf', '2024년 4분기 부가세 신고서'),
    ('550e8400-e29b-41d4-a716-446655440000', '2025년 1월 원천징수 신고서', 'WITHHOLDING_REPORT', 'withholding_2025_01.pdf', '/tax/documents/withholding_2025_01.pdf', '2025년 1월 원천징수 신고서'),
    ('550e8400-e29b-41d4-a716-446655440000', '세금계산서 2025-001', 'TAX_INVOICE', 'tax_invoice_2025_001.pdf', '/tax/documents/tax_invoice_2025_001.pdf', '발행 세금계산서')
ON CONFLICT DO NOTHING;

COMMIT;