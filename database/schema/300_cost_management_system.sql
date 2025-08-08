-- =====================================================
-- 비용 관리 시스템 스키마
-- 작업: 15. 비용 관리 REST API 구현
-- =====================================================

-- 1. 비용 추적 테이블 (기본 비용 기록)
CREATE TABLE IF NOT EXISTS bms.cost_tracking (
    cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 연관 작업 정보
    work_order_id UUID,
    maintenance_id UUID,
    fault_report_id UUID,
    
    -- 비용 기본 정보
    cost_number VARCHAR(50) NOT NULL,
    cost_type VARCHAR(30) NOT NULL, -- LABOR, MATERIAL, EQUIPMENT, CONTRACTOR, EMERGENCY, MISCELLANEOUS
    category VARCHAR(50) NOT NULL, -- PREVENTIVE, CORRECTIVE, EMERGENCY, UPGRADE
    
    -- 비용 상세
    amount DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'KRW',
    cost_date DATE NOT NULL,
    description TEXT,
    
    -- 결제 정보
    payment_method VARCHAR(20), -- CASH, CARD, TRANSFER, CHECK
    invoice_number VARCHAR(50),
    receipt_number VARCHAR(50),
    
    -- 승인 정보
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 예산 정보
    budget_category VARCHAR(50),
    budget_year INTEGER,
    budget_month INTEGER,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_cost_tracking_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id),
    CONSTRAINT fk_cost_tracking_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id),
    CONSTRAINT fk_cost_tracking_maintenance FOREIGN KEY (maintenance_id) REFERENCES bms.maintenance_plans(plan_id),
    CONSTRAINT fk_cost_tracking_fault_report FOREIGN KEY (fault_report_id) REFERENCES bms.fault_reports(report_id),
    CONSTRAINT chk_cost_amount CHECK (amount >= 0),
    CONSTRAINT chk_cost_type CHECK (cost_type IN ('LABOR', 'MATERIAL', 'EQUIPMENT', 'CONTRACTOR', 'EMERGENCY', 'MISCELLANEOUS')),
    CONSTRAINT chk_cost_category CHECK (category IN ('PREVENTIVE', 'CORRECTIVE', 'EMERGENCY', 'UPGRADE', 'INSPECTION')),
    CONSTRAINT chk_cost_currency CHECK (currency IN ('KRW', 'USD', 'EUR', 'JPY')),
    CONSTRAINT uk_cost_number UNIQUE (company_id, cost_number)
);

-- 2. 예산 관리 테이블
CREATE TABLE IF NOT EXISTS bms.budget_management (
    budget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 예산 기본 정보
    budget_name VARCHAR(100) NOT NULL,
    budget_year INTEGER NOT NULL,
    budget_category VARCHAR(50) NOT NULL, -- MAINTENANCE, REPAIR, EMERGENCY, UPGRADE
    
    -- 예산 금액
    allocated_amount DECIMAL(12,2) NOT NULL,
    spent_amount DECIMAL(12,2) DEFAULT 0,
    committed_amount DECIMAL(12,2) DEFAULT 0, -- 약정된 금액
    available_amount DECIMAL(12,2) DEFAULT 0,
    
    -- 예산 기간
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- 예산 상태
    budget_status VARCHAR(20) DEFAULT 'ACTIVE', -- ACTIVE, SUSPENDED, CLOSED, EXCEEDED
    
    -- 경고 설정
    warning_threshold DECIMAL(5,2) DEFAULT 80.00, -- 80% 사용 시 경고
    critical_threshold DECIMAL(5,2) DEFAULT 95.00, -- 95% 사용 시 위험 경고
    
    -- 승인 정보
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_budget_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id),
    CONSTRAINT chk_budget_amounts CHECK (allocated_amount >= 0 AND spent_amount >= 0 AND committed_amount >= 0),
    CONSTRAINT chk_budget_thresholds CHECK (warning_threshold > 0 AND critical_threshold > warning_threshold),
    CONSTRAINT chk_budget_dates CHECK (end_date > start_date),
    CONSTRAINT uk_budget_name_year UNIQUE (company_id, budget_name, budget_year)
);

-- 3. 비용 분석 뷰 (월별 비용 통계)
CREATE OR REPLACE VIEW bms.v_monthly_cost_summary AS
SELECT 
    ct.company_id,
    EXTRACT(YEAR FROM ct.cost_date) as cost_year,
    EXTRACT(MONTH FROM ct.cost_date) as cost_month,
    ct.category,
    ct.cost_type,
    
    -- 비용 통계
    COUNT(*) as transaction_count,
    SUM(ct.amount) as total_amount,
    AVG(ct.amount) as average_amount,
    MIN(ct.amount) as min_amount,
    MAX(ct.amount) as max_amount,
    
    -- 비용 유형별 분석
    SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount ELSE 0 END) as labor_cost,
    SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount ELSE 0 END) as material_cost,
    SUM(CASE WHEN ct.cost_type = 'EQUIPMENT' THEN ct.amount ELSE 0 END) as equipment_cost,
    SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount ELSE 0 END) as contractor_cost,
    SUM(CASE WHEN ct.cost_type = 'EMERGENCY' THEN ct.amount ELSE 0 END) as emergency_cost,
    
    -- 카테고리별 분석
    SUM(CASE WHEN ct.category = 'PREVENTIVE' THEN ct.amount ELSE 0 END) as preventive_cost,
    SUM(CASE WHEN ct.category = 'CORRECTIVE' THEN ct.amount ELSE 0 END) as corrective_cost,
    SUM(CASE WHEN ct.category = 'EMERGENCY' THEN ct.amount ELSE 0 END) as emergency_category_cost,
    SUM(CASE WHEN ct.category = 'UPGRADE' THEN ct.amount ELSE 0 END) as upgrade_cost
    
FROM bms.cost_tracking ct
GROUP BY 
    ct.company_id, 
    EXTRACT(YEAR FROM ct.cost_date),
    EXTRACT(MONTH FROM ct.cost_date),
    ct.category,
    ct.cost_type;

-- 4. 예산 현황 뷰
CREATE OR REPLACE VIEW bms.v_budget_status AS
SELECT 
    bm.budget_id,
    bm.company_id,
    bm.budget_name,
    bm.budget_year,
    bm.budget_category,
    bm.allocated_amount,
    bm.spent_amount,
    bm.committed_amount,
    bm.available_amount,
    
    -- 사용률 계산
    ROUND((bm.spent_amount / bm.allocated_amount * 100), 2) as utilization_percentage,
    ROUND(((bm.spent_amount + bm.committed_amount) / bm.allocated_amount * 100), 2) as commitment_percentage,
    
    -- 상태 판정
    CASE 
        WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.critical_threshold THEN 'CRITICAL'
        WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.warning_threshold THEN 'WARNING'
        ELSE 'NORMAL'
    END as status_level,
    
    -- 잔여 예산
    (bm.allocated_amount - bm.spent_amount - bm.committed_amount) as remaining_budget,
    
    -- 기간 정보
    bm.start_date,
    bm.end_date,
    CASE 
        WHEN CURRENT_DATE < bm.start_date THEN 'FUTURE'
        WHEN CURRENT_DATE > bm.end_date THEN 'EXPIRED'
        ELSE 'ACTIVE'
    END as period_status
    
FROM bms.budget_management bm;

-- 5. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cost_tracking_company_date ON bms.cost_tracking(company_id, cost_date);
CREATE INDEX IF NOT EXISTS idx_cost_tracking_work_order ON bms.cost_tracking(work_order_id);
CREATE INDEX IF NOT EXISTS idx_cost_tracking_category ON bms.cost_tracking(company_id, category);
CREATE INDEX IF NOT EXISTS idx_cost_tracking_type ON bms.cost_tracking(company_id, cost_type);
CREATE INDEX IF NOT EXISTS idx_cost_tracking_budget ON bms.cost_tracking(company_id, budget_year, budget_month);

CREATE INDEX IF NOT EXISTS idx_budget_management_company_year ON bms.budget_management(company_id, budget_year);
CREATE INDEX IF NOT EXISTS idx_budget_management_category ON bms.budget_management(company_id, budget_category);
CREATE INDEX IF NOT EXISTS idx_budget_management_status ON bms.budget_management(company_id, budget_status);

-- 6. 테이블 코멘트
COMMENT ON TABLE bms.cost_tracking IS '비용 추적 테이블 - 모든 시설 관리 관련 비용을 기록';
COMMENT ON TABLE bms.budget_management IS '예산 관리 테이블 - 연간/분기별 예산 계획 및 실행 현황 관리';

-- 7. 컬럼 코멘트
COMMENT ON COLUMN bms.cost_tracking.cost_id IS '비용 기록 고유 식별자';
COMMENT ON COLUMN bms.cost_tracking.company_id IS '회사 식별자';
COMMENT ON COLUMN bms.cost_tracking.work_order_id IS '연관된 작업 지시서 ID';
COMMENT ON COLUMN bms.cost_tracking.maintenance_id IS '연관된 정비 계획 ID';
COMMENT ON COLUMN bms.cost_tracking.fault_report_id IS '연관된 고장 신고 ID';
COMMENT ON COLUMN bms.cost_tracking.cost_number IS '비용 기록 번호';
COMMENT ON COLUMN bms.cost_tracking.cost_type IS '비용 유형 (인건비, 자재비, 장비비, 외주비 등)';
COMMENT ON COLUMN bms.cost_tracking.category IS '비용 카테고리 (예방정비, 수정정비, 응급수리 등)';
COMMENT ON COLUMN bms.cost_tracking.amount IS '비용 금액';
COMMENT ON COLUMN bms.cost_tracking.currency IS '통화 단위';
COMMENT ON COLUMN bms.cost_tracking.cost_date IS '비용 발생일';
COMMENT ON COLUMN bms.cost_tracking.description IS '비용 설명';
COMMENT ON COLUMN bms.cost_tracking.payment_method IS '결제 방법';
COMMENT ON COLUMN bms.cost_tracking.invoice_number IS '송장 번호';
COMMENT ON COLUMN bms.cost_tracking.receipt_number IS '영수증 번호';
COMMENT ON COLUMN bms.cost_tracking.approved_by IS '승인자 ID';
COMMENT ON COLUMN bms.cost_tracking.approval_date IS '승인일';
COMMENT ON COLUMN bms.cost_tracking.budget_category IS '예산 카테고리';
COMMENT ON COLUMN bms.cost_tracking.budget_year IS '예산 연도';
COMMENT ON COLUMN bms.cost_tracking.budget_month IS '예산 월';

COMMENT ON COLUMN bms.budget_management.budget_id IS '예산 고유 식별자';
COMMENT ON COLUMN bms.budget_management.company_id IS '회사 식별자';
COMMENT ON COLUMN bms.budget_management.budget_name IS '예산 이름';
COMMENT ON COLUMN bms.budget_management.budget_year IS '예산 연도';
COMMENT ON COLUMN bms.budget_management.budget_category IS '예산 카테고리';
COMMENT ON COLUMN bms.budget_management.allocated_amount IS '할당된 예산 금액';
COMMENT ON COLUMN bms.budget_management.spent_amount IS '사용된 금액';
COMMENT ON COLUMN bms.budget_management.committed_amount IS '약정된 금액';
COMMENT ON COLUMN bms.budget_management.available_amount IS '사용 가능한 금액';
COMMENT ON COLUMN bms.budget_management.budget_status IS '예산 상태';
COMMENT ON COLUMN bms.budget_management.warning_threshold IS '경고 임계값 (%)';
COMMENT ON COLUMN bms.budget_management.critical_threshold IS '위험 임계값 (%)';