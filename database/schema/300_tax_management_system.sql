-- =====================================================
-- 세무 관리 시스템 (Tax Management System)
-- 파일: database/schema/300_tax_management_system.sql
-- 설명: 부가세, 원천징수, 세금계산서 관리 시스템
-- 생성일: 2025-01-08
-- =====================================================

-- 스키마 설정
SET search_path TO bms;

-- =====================================================
-- 1. 세무 신고 기간 관리 테이블
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_periods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('MONTHLY', 'QUARTERLY', 'YEARLY')),
    tax_type VARCHAR(30) NOT NULL CHECK (tax_type IN ('VAT', 'WITHHOLDING', 'CORPORATE', 'LOCAL')),
    period_year INTEGER NOT NULL,
    period_month INTEGER CHECK (period_month BETWEEN 1 AND 12),
    period_quarter INTEGER CHECK (period_quarter BETWEEN 1 AND 4),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED', 'SUBMITTED', 'APPROVED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE tax_periods IS '세무 신고 기간 관리';
COMMENT ON COLUMN tax_periods.period_type IS '신고 주기 (월별, 분기별, 연별)';
COMMENT ON COLUMN tax_periods.tax_type IS '세금 유형 (부가세, 원천징수, 법인세, 지방세)';
COMMENT ON COLUMN tax_periods.status IS '신고 상태 (진행중, 마감, 제출완료, 승인완료)';

-- =====================================================
-- 2. 부가세 신고서 관리 테이블
-- =====================================================
CREATE TABLE IF NOT EXISTS vat_returns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    tax_period_id UUID NOT NULL REFERENCES tax_periods(id),
    return_type VARCHAR(20) NOT NULL CHECK (return_type IN ('GENERAL', 'SIMPLIFIED', 'ZERO_RATE')),
    filing_date DATE,
    due_date DATE NOT NULL,
    
    -- 매출 관련
    taxable_sales_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    zero_rate_sales_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    exempt_sales_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    output_vat_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 매입 관련
    taxable_purchases_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    input_vat_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    input_vat_deduction_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 계산 결과
    net_vat_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    additional_tax_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    total_tax_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 신고 상태
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'CALCULATED', 'REVIEWED', 'SUBMITTED', 'APPROVED')),
    submission_reference VARCHAR(100),
    
    -- 메타데이터
    calculation_data JSONB,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE vat_returns IS '부가세 신고서 관리';
COMMENT ON COLUMN vat_returns.return_type IS '신고서 유형 (일반, 간이, 영세율)';
COMMENT ON COLUMN vat_returns.net_vat_amount IS '납부할 부가세 (매출세액 - 매입세액)';
COMMENT ON COLUMN vat_returns.calculation_data IS '부가세 계산 상세 데이터 (JSON)';

-- =====================================================
-- 3. 원천징수 관리 테이블
-- =====================================================
CREATE TABLE IF NOT EXISTS withholding_taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    tax_period_id UUID NOT NULL REFERENCES tax_periods(id),
    
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
-- 4. 세금계산서 관리 테이블
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_invoices (
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

COMMENT ON TABLE tax_invoices IS '세금계산서 관리';
COMMENT ON COLUMN tax_invoices.invoice_type IS '세금계산서 유형 (발행, 수취, 수정, 취소)';
COMMENT ON COLUMN tax_invoices.electronic_invoice_id IS '전자세금계산서 ID';
COMMENT ON COLUMN tax_invoices.nts_confirmation_number IS '국세청 승인번호';

-- =====================================================
-- 5. 세무 일정 관리 테이블
-- =====================================================
CREATE TABLE IF NOT EXISTS tax_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 일정 정보
    schedule_name VARCHAR(200) NOT NULL,
    tax_type VARCHAR(30) NOT NULL CHECK (tax_type IN ('VAT', 'WITHHOLDING', 'CORPORATE', 'LOCAL', 'OTHER')),
    schedule_type VARCHAR(20) NOT NULL CHECK (schedule_type IN ('FILING', 'PAYMENT', 'PREPARATION', 'REVIEW')),
    
    -- 날짜 정보
    due_date DATE NOT NULL,
    reminder_date DATE,
    completion_date DATE,
    
    -- 상태 관리
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE')),
    priority VARCHAR(10) NOT NULL DEFAULT 'MEDIUM' CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT')),
    
    -- 담당자 정보
    assigned_to UUID,
    
    -- 메타데이터
    description TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    updated_by UUID
);

COMMENT ON TABLE tax_schedules IS '세무 일정 관리';
COMMENT ON COLUMN tax_schedules.schedule_type IS '일정 유형 (신고, 납부, 준비, 검토)';
COMMENT ON COLUMN tax_schedules.priority IS '우선순위 (낮음, 보통, 높음, 긴급)';

-- =====================================================
-- 6. 세무 서류 관리 테이블
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
    related_vat_return_id UUID REFERENCES vat_returns(id),
    related_withholding_id UUID REFERENCES withholding_taxes(id),
    related_tax_invoice_id UUID REFERENCES tax_invoices(id),
    
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

-- 세무 신고 기간 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_periods_company_type ON tax_periods(company_id, tax_type);
CREATE INDEX IF NOT EXISTS idx_tax_periods_period ON tax_periods(period_year, period_month, period_quarter);
CREATE INDEX IF NOT EXISTS idx_tax_periods_due_date ON tax_periods(due_date);
CREATE INDEX IF NOT EXISTS idx_tax_periods_status ON tax_periods(status);

-- 부가세 신고서 인덱스
CREATE INDEX IF NOT EXISTS idx_vat_returns_company ON vat_returns(company_id);
CREATE INDEX IF NOT EXISTS idx_vat_returns_period ON vat_returns(tax_period_id);
CREATE INDEX IF NOT EXISTS idx_vat_returns_due_date ON vat_returns(due_date);
CREATE INDEX IF NOT EXISTS idx_vat_returns_status ON vat_returns(status);

-- 원천징수 인덱스
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_company ON withholding_taxes(company_id);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_period ON withholding_taxes(tax_period_id);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_payment_date ON withholding_taxes(payment_date);
CREATE INDEX IF NOT EXISTS idx_withholding_taxes_payee ON withholding_taxes(payee_registration_number);

-- 세금계산서 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_invoices_company ON tax_invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_type ON tax_invoices(invoice_type);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_issue_date ON tax_invoices(issue_date);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_supplier ON tax_invoices(supplier_registration_number);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_buyer ON tax_invoices(buyer_registration_number);
CREATE INDEX IF NOT EXISTS idx_tax_invoices_number ON tax_invoices(invoice_number);

-- 세무 일정 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_schedules_company ON tax_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_schedules_due_date ON tax_schedules(due_date);
CREATE INDEX IF NOT EXISTS idx_tax_schedules_status ON tax_schedules(status);
CREATE INDEX IF NOT EXISTS idx_tax_schedules_assigned ON tax_schedules(assigned_to);

-- 세무 서류 인덱스
CREATE INDEX IF NOT EXISTS idx_tax_documents_company ON tax_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_tax_documents_type ON tax_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_tax_documents_period ON tax_documents(related_tax_period_id);

-- =====================================================
-- 비즈니스 함수
-- =====================================================

-- 부가세 계산 함수
CREATE OR REPLACE FUNCTION calculate_vat_return(
    p_company_id UUID,
    p_tax_period_id UUID
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
    FROM tax_invoices ti
    JOIN tax_periods tp ON tp.id = p_tax_period_id
    WHERE ti.company_id = p_company_id
      AND ti.invoice_type = 'ISSUED'
      AND ti.issue_date BETWEEN tp.start_date AND tp.end_date
      AND ti.status IN ('ISSUED', 'SENT', 'CONFIRMED');
    
    -- 매입세액 계산 (세금계산서 수취분)
    SELECT 
        COALESCE(SUM(vat_amount), 0)
    INTO v_input_vat
    FROM tax_invoices ti
    JOIN tax_periods tp ON tp.id = p_tax_period_id
    WHERE ti.company_id = p_company_id
      AND ti.invoice_type = 'RECEIVED'
      AND ti.issue_date BETWEEN tp.start_date AND tp.end_date
      AND ti.status IN ('RECEIVED', 'CONFIRMED');
    
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

COMMENT ON FUNCTION calculate_vat_return IS '부가세 신고서 자동 계산';

-- 세무 일정 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_tax_schedules(
    p_company_id UUID,
    p_year INTEGER
) RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER := 0;
    v_quarter INTEGER;
    v_month INTEGER;
BEGIN
    -- 분기별 부가세 신고 일정 생성
    FOR v_quarter IN 1..4 LOOP
        INSERT INTO tax_schedules (
            company_id, schedule_name, tax_type, schedule_type,
            due_date, reminder_date, status, priority
        ) VALUES (
            p_company_id,
            p_year || '년 ' || v_quarter || '분기 부가세 신고',
            'VAT',
            'FILING',
            CASE v_quarter
                WHEN 1 THEN (p_year || '-04-25')::DATE
                WHEN 2 THEN (p_year || '-07-25')::DATE
                WHEN 3 THEN (p_year || '-10-25')::DATE
                WHEN 4 THEN ((p_year + 1) || '-01-25')::DATE
            END,
            CASE v_quarter
                WHEN 1 THEN (p_year || '-04-15')::DATE
                WHEN 2 THEN (p_year || '-07-15')::DATE
                WHEN 3 THEN (p_year || '-10-15')::DATE
                WHEN 4 THEN ((p_year + 1) || '-01-15')::DATE
            END,
            'PENDING',
            'HIGH'
        );
        v_count := v_count + 1;
    END LOOP;
    
    -- 월별 원천징수 신고 일정 생성
    FOR v_month IN 1..12 LOOP
        INSERT INTO tax_schedules (
            company_id, schedule_name, tax_type, schedule_type,
            due_date, reminder_date, status, priority
        ) VALUES (
            p_company_id,
            p_year || '년 ' || v_month || '월 원천징수 신고',
            'WITHHOLDING',
            'FILING',
            CASE 
                WHEN v_month = 12 THEN ((p_year + 1) || '-01-10')::DATE
                ELSE (p_year || '-' || LPAD((v_month + 1)::TEXT, 2, '0') || '-10')::DATE
            END,
            CASE 
                WHEN v_month = 12 THEN ((p_year + 1) || '-01-05')::DATE
                ELSE (p_year || '-' || LPAD((v_month + 1)::TEXT, 2, '0') || '-05')::DATE
            END,
            'PENDING',
            'MEDIUM'
        );
        v_count := v_count + 1;
    END LOOP;
    
    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION generate_tax_schedules IS '연간 세무 일정 자동 생성';

-- =====================================================
-- 트리거 함수
-- =====================================================

-- 부가세 신고서 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_vat_return_amounts()
RETURNS TRIGGER AS $$
BEGIN
    -- 계산된 금액들 업데이트
    NEW.total_tax_amount := NEW.net_vat_amount + NEW.additional_tax_amount;
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_vat_return_amounts ON vat_returns;
CREATE TRIGGER trigger_update_vat_return_amounts
    BEFORE UPDATE ON vat_returns
    FOR EACH ROW
    EXECUTE FUNCTION update_vat_return_amounts();

-- 세무 일정 상태 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_tax_schedule_status()
RETURNS TRIGGER AS $$
BEGIN
    -- 완료일이 설정되면 상태를 완료로 변경
    IF NEW.completion_date IS NOT NULL AND OLD.completion_date IS NULL THEN
        NEW.status := 'COMPLETED';
    END IF;
    
    -- 기한이 지나면 연체 상태로 변경
    IF NEW.due_date < CURRENT_DATE AND NEW.status = 'PENDING' THEN
        NEW.status := 'OVERDUE';
    END IF;
    
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_tax_schedule_status ON tax_schedules;
CREATE TRIGGER trigger_update_tax_schedule_status
    BEFORE UPDATE ON tax_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_tax_schedule_status();

-- =====================================================
-- 기본 데이터 삽입
-- =====================================================

-- 2025년 세무 기간 생성 (예시)
INSERT INTO tax_periods (company_id, period_type, tax_type, period_year, period_quarter, start_date, end_date, due_date)
VALUES 
    ('550e8400-e29b-41d4-a716-446655440000', 'QUARTERLY', 'VAT', 2025, 1, '2025-01-01', '2025-03-31', '2025-04-25'),
    ('550e8400-e29b-41d4-a716-446655440000', 'QUARTERLY', 'VAT', 2025, 2, '2025-04-01', '2025-06-30', '2025-07-25'),
    ('550e8400-e29b-41d4-a716-446655440000', 'QUARTERLY', 'VAT', 2025, 3, '2025-07-01', '2025-09-30', '2025-10-25'),
    ('550e8400-e29b-41d4-a716-446655440000', 'QUARTERLY', 'VAT', 2025, 4, '2025-10-01', '2025-12-31', '2026-01-25')
ON CONFLICT DO NOTHING;

-- 세무 일정 자동 생성 실행
SELECT generate_tax_schedules('550e8400-e29b-41d4-a716-446655440000', 2025);

COMMIT;