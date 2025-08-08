-- 재무제표 생성 시스템 스키마
-- 손익계산서, 대차대조표, 현금흐름표 자동 생성

-- 재무제표 템플릿 테이블
CREATE TABLE IF NOT EXISTS bms.financial_statement_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    statement_type VARCHAR(20) NOT NULL,
    template_structure JSONB NOT NULL,
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_statement_type CHECK (statement_type IN ('INCOME_STATEMENT', 'BALANCE_SHEET', 'CASH_FLOW'))
);

COMMENT ON TABLE bms.financial_statement_templates IS '재무제표 템플릿 테이블';

-- 재무제표 생성 이력 테이블
CREATE TABLE IF NOT EXISTS bms.financial_statements (
    statement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    template_id UUID REFERENCES bms.financial_statement_templates(template_id),
    statement_type VARCHAR(20) NOT NULL,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    statement_data JSONB NOT NULL,
    generated_by UUID NOT NULL,
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_fs_statement_type CHECK (statement_type IN ('INCOME_STATEMENT', 'BALANCE_SHEET', 'CASH_FLOW'))
);

COMMENT ON TABLE bms.financial_statements IS '재무제표 생성 이력 테이블';

-- 재무비율 분석 테이블
CREATE TABLE IF NOT EXISTS bms.financial_ratios (
    ratio_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    statement_id UUID NOT NULL REFERENCES bms.financial_statements(statement_id),
    ratio_type VARCHAR(50) NOT NULL,
    ratio_name VARCHAR(100) NOT NULL,
    ratio_value DECIMAL(10,4),
    calculation_formula TEXT,
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE bms.financial_ratios IS '재무비율 분석 테이블';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_financial_statements_company_period ON bms.financial_statements(company_id, period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_financial_ratios_statement ON bms.financial_ratios(statement_id);