-- 예산 관리 시스템 스키마
-- 연간 예산 수립 및 월별 배정, 예산 대비 실적 실시간 계산, 예산 초과 경고 기능

-- 예산 계획 테이블
CREATE TABLE IF NOT EXISTS bms.budget_plans (
    budget_plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    plan_name VARCHAR(100) NOT NULL,
    fiscal_year INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_budget DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    approved_by UUID,
    approved_at TIMESTAMP,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, fiscal_year),
    CONSTRAINT chk_budget_status CHECK (status IN ('DRAFT', 'APPROVED', 'ACTIVE', 'CLOSED'))
);

COMMENT ON TABLE bms.budget_plans IS '예산 계획 테이블';
COMMENT ON COLUMN bms.budget_plans.budget_plan_id IS '예산 계획 ID';
COMMENT ON COLUMN bms.budget_plans.company_id IS '회사 ID';
COMMENT ON COLUMN bms.budget_plans.plan_name IS '예산 계획명';
COMMENT ON COLUMN bms.budget_plans.fiscal_year IS '회계연도';
COMMENT ON COLUMN bms.budget_plans.start_date IS '시작일';
COMMENT ON COLUMN bms.budget_plans.end_date IS '종료일';
COMMENT ON COLUMN bms.budget_plans.total_budget IS '총 예산';
COMMENT ON COLUMN bms.budget_plans.status IS '상태 (DRAFT, APPROVED, ACTIVE, CLOSED)';

-- 예산 항목 테이블
CREATE TABLE IF NOT EXISTS bms.budget_items (
    budget_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_plan_id UUID NOT NULL REFERENCES bms.budget_plans(budget_plan_id),
    company_id UUID NOT NULL,
    category VARCHAR(50) NOT NULL,
    subcategory VARCHAR(50),
    item_name VARCHAR(100) NOT NULL,
    description TEXT,
    annual_budget DECIMAL(15,2) NOT NULL,
    allocated_budget DECIMAL(15,2) DEFAULT 0,
    used_budget DECIMAL(15,2) DEFAULT 0,
    remaining_budget DECIMAL(15,2) DEFAULT 0,
    account_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_budget_category CHECK (category IN ('INCOME', 'EXPENSE', 'INVESTMENT', 'RESERVE'))
);

COMMENT ON TABLE bms.budget_items IS '예산 항목 테이블';
COMMENT ON COLUMN bms.budget_items.budget_item_id IS '예산 항목 ID';
COMMENT ON COLUMN bms.budget_items.budget_plan_id IS '예산 계획 ID';
COMMENT ON COLUMN bms.budget_items.category IS '예산 카테고리 (INCOME, EXPENSE, INVESTMENT, RESERVE)';
COMMENT ON COLUMN bms.budget_items.subcategory IS '세부 카테고리';
COMMENT ON COLUMN bms.budget_items.item_name IS '예산 항목명';
COMMENT ON COLUMN bms.budget_items.annual_budget IS '연간 예산';
COMMENT ON COLUMN bms.budget_items.allocated_budget IS '배정 예산';
COMMENT ON COLUMN bms.budget_items.used_budget IS '사용 예산';
COMMENT ON COLUMN bms.budget_items.remaining_budget IS '잔여 예산';

-- 월별 예산 배정 테이블
CREATE TABLE IF NOT EXISTS bms.monthly_budget_allocations (
    allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_item_id UUID NOT NULL REFERENCES bms.budget_items(budget_item_id),
    company_id UUID NOT NULL,
    allocation_year INTEGER NOT NULL,
    allocation_month INTEGER NOT NULL,
    allocated_amount DECIMAL(15,2) NOT NULL,
    used_amount DECIMAL(15,2) DEFAULT 0,
    remaining_amount DECIMAL(15,2) DEFAULT 0,
    variance_amount DECIMAL(15,2) DEFAULT 0,
    variance_percentage DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(budget_item_id, allocation_year, allocation_month),
    CONSTRAINT chk_allocation_month CHECK (allocation_month BETWEEN 1 AND 12)
);

COMMENT ON TABLE bms.monthly_budget_allocations IS '월별 예산 배정 테이블';
COMMENT ON COLUMN bms.monthly_budget_allocations.allocation_id IS '배정 ID';
COMMENT ON COLUMN bms.monthly_budget_allocations.budget_item_id IS '예산 항목 ID';
COMMENT ON COLUMN bms.monthly_budget_allocations.allocation_year IS '배정 연도';
COMMENT ON COLUMN bms.monthly_budget_allocations.allocation_month IS '배정 월';
COMMENT ON COLUMN bms.monthly_budget_allocations.allocated_amount IS '배정 금액';
COMMENT ON COLUMN bms.monthly_budget_allocations.used_amount IS '사용 금액';
COMMENT ON COLUMN bms.monthly_budget_allocations.remaining_amount IS '잔여 금액';
COMMENT ON COLUMN bms.monthly_budget_allocations.variance_amount IS '차이 금액';
COMMENT ON COLUMN bms.monthly_budget_allocations.variance_percentage IS '차이 비율';

-- 예산 실적 추적 테이블
CREATE TABLE IF NOT EXISTS bms.budget_performance_tracking (
    tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_item_id UUID NOT NULL REFERENCES bms.budget_items(budget_item_id),
    company_id UUID NOT NULL,
    transaction_id UUID,
    expense_record_id UUID,
    income_record_id UUID,
    tracking_date DATE NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN ('INCOME', 'EXPENSE', 'TRANSFER', 'ADJUSTMENT'))
);

COMMENT ON TABLE bms.budget_performance_tracking IS '예산 실적 추적 테이블';
COMMENT ON COLUMN bms.budget_performance_tracking.tracking_id IS '추적 ID';
COMMENT ON COLUMN bms.budget_performance_tracking.budget_item_id IS '예산 항목 ID';
COMMENT ON COLUMN bms.budget_performance_tracking.transaction_id IS '거래 ID';
COMMENT ON COLUMN bms.budget_performance_tracking.expense_record_id IS '지출 기록 ID';
COMMENT ON COLUMN bms.budget_performance_tracking.income_record_id IS '수입 기록 ID';
COMMENT ON COLUMN bms.budget_performance_tracking.tracking_date IS '추적일';
COMMENT ON COLUMN bms.budget_performance_tracking.amount IS '금액';
COMMENT ON COLUMN bms.budget_performance_tracking.transaction_type IS '거래 유형';

-- 예산 경고 설정 테이블
CREATE TABLE IF NOT EXISTS bms.budget_alert_settings (
    alert_setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_item_id UUID NOT NULL REFERENCES bms.budget_items(budget_item_id),
    company_id UUID NOT NULL,
    alert_type VARCHAR(20) NOT NULL,
    threshold_percentage DECIMAL(5,2) NOT NULL,
    threshold_amount DECIMAL(15,2),
    is_enabled BOOLEAN DEFAULT true,
    notification_emails TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_alert_type CHECK (alert_type IN ('USAGE_WARNING', 'USAGE_CRITICAL', 'OVERBUDGET', 'MONTHLY_LIMIT'))
);

COMMENT ON TABLE bms.budget_alert_settings IS '예산 경고 설정 테이블';
COMMENT ON COLUMN bms.budget_alert_settings.alert_setting_id IS '경고 설정 ID';
COMMENT ON COLUMN bms.budget_alert_settings.budget_item_id IS '예산 항목 ID';
COMMENT ON COLUMN bms.budget_alert_settings.alert_type IS '경고 유형';
COMMENT ON COLUMN bms.budget_alert_settings.threshold_percentage IS '임계값 비율';
COMMENT ON COLUMN bms.budget_alert_settings.threshold_amount IS '임계값 금액';
COMMENT ON COLUMN bms.budget_alert_settings.notification_emails IS '알림 이메일 목록';

-- 예산 경고 이력 테이블
CREATE TABLE IF NOT EXISTS bms.budget_alert_history (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_item_id UUID NOT NULL REFERENCES bms.budget_items(budget_item_id),
    company_id UUID NOT NULL,
    alert_type VARCHAR(20) NOT NULL,
    alert_level VARCHAR(20) NOT NULL,
    current_usage_amount DECIMAL(15,2) NOT NULL,
    current_usage_percentage DECIMAL(5,2) NOT NULL,
    threshold_amount DECIMAL(15,2),
    threshold_percentage DECIMAL(5,2),
    alert_message TEXT NOT NULL,
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_alert_level CHECK (alert_level IN ('INFO', 'WARNING', 'CRITICAL', 'EMERGENCY'))
);

COMMENT ON TABLE bms.budget_alert_history IS '예산 경고 이력 테이블';
COMMENT ON COLUMN bms.budget_alert_history.alert_id IS '경고 ID';
COMMENT ON COLUMN bms.budget_alert_history.alert_level IS '경고 수준';
COMMENT ON COLUMN bms.budget_alert_history.current_usage_amount IS '현재 사용 금액';
COMMENT ON COLUMN bms.budget_alert_history.current_usage_percentage IS '현재 사용 비율';
COMMENT ON COLUMN bms.budget_alert_history.alert_message IS '경고 메시지';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_budget_plans_company_id ON bms.budget_plans(company_id);
CREATE INDEX IF NOT EXISTS idx_budget_plans_fiscal_year ON bms.budget_plans(company_id, fiscal_year);
CREATE INDEX IF NOT EXISTS idx_budget_plans_status ON bms.budget_plans(company_id, status);

CREATE INDEX IF NOT EXISTS idx_budget_items_budget_plan ON bms.budget_items(budget_plan_id);
CREATE INDEX IF NOT EXISTS idx_budget_items_company_id ON bms.budget_items(company_id);
CREATE INDEX IF NOT EXISTS idx_budget_items_category ON bms.budget_items(company_id, category);

CREATE INDEX IF NOT EXISTS idx_monthly_allocations_budget_item ON bms.monthly_budget_allocations(budget_item_id);
CREATE INDEX IF NOT EXISTS idx_monthly_allocations_period ON bms.monthly_budget_allocations(company_id, allocation_year, allocation_month);

CREATE INDEX IF NOT EXISTS idx_budget_tracking_budget_item ON bms.budget_performance_tracking(budget_item_id);
CREATE INDEX IF NOT EXISTS idx_budget_tracking_date ON bms.budget_performance_tracking(company_id, tracking_date);
CREATE INDEX IF NOT EXISTS idx_budget_tracking_transaction ON bms.budget_performance_tracking(transaction_id);

CREATE INDEX IF NOT EXISTS idx_budget_alerts_budget_item ON bms.budget_alert_settings(budget_item_id);
CREATE INDEX IF NOT EXISTS idx_budget_alert_history_budget_item ON bms.budget_alert_history(budget_item_id);
CREATE INDEX IF NOT EXISTS idx_budget_alert_history_created ON bms.budget_alert_history(company_id, created_at);

-- 예산 실적 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_budget_performance(
    p_budget_item_id UUID,
    p_amount DECIMAL(15,2),
    p_transaction_type VARCHAR(20),
    p_tracking_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
    v_budget_item RECORD;
    v_monthly_allocation RECORD;
    v_year INTEGER;
    v_month INTEGER;
BEGIN
    -- 예산 항목 조회
    SELECT * INTO v_budget_item FROM bms.budget_items WHERE budget_item_id = p_budget_item_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 예산 항목입니다: %', p_budget_item_id;
    END IF;
    
    -- 연도, 월 추출
    v_year := EXTRACT(YEAR FROM p_tracking_date);
    v_month := EXTRACT(MONTH FROM p_tracking_date);
    
    -- 월별 배정 조회
    SELECT * INTO v_monthly_allocation 
    FROM bms.monthly_budget_allocations 
    WHERE budget_item_id = p_budget_item_id 
      AND allocation_year = v_year 
      AND allocation_month = v_month;
    
    -- 예산 항목 사용 금액 업데이트
    UPDATE bms.budget_items
    SET used_budget = used_budget + p_amount,
        remaining_budget = annual_budget - (used_budget + p_amount),
        updated_at = CURRENT_TIMESTAMP
    WHERE budget_item_id = p_budget_item_id;
    
    -- 월별 배정 사용 금액 업데이트 (배정이 있는 경우)
    IF FOUND THEN
        UPDATE bms.monthly_budget_allocations
        SET used_amount = used_amount + p_amount,
            remaining_amount = allocated_amount - (used_amount + p_amount),
            variance_amount = (used_amount + p_amount) - allocated_amount,
            variance_percentage = CASE 
                WHEN allocated_amount > 0 THEN 
                    ((used_amount + p_amount) - allocated_amount) / allocated_amount * 100
                ELSE 0 
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE allocation_id = v_monthly_allocation.allocation_id;
    END IF;
    
    -- 실적 추적 기록 생성
    INSERT INTO bms.budget_performance_tracking (
        budget_item_id, company_id, tracking_date, amount, transaction_type
    ) VALUES (
        p_budget_item_id, v_budget_item.company_id, p_tracking_date, p_amount, p_transaction_type
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.update_budget_performance IS '예산 실적 업데이트 함수';

-- 예산 경고 확인 함수
CREATE OR REPLACE FUNCTION bms.check_budget_alerts(
    p_budget_item_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_budget_item RECORD;
    v_alert_setting RECORD;
    v_usage_percentage DECIMAL(5,2);
    v_alert_level VARCHAR(20);
    v_alert_message TEXT;
BEGIN
    -- 예산 항목 조회
    SELECT * INTO v_budget_item FROM bms.budget_items WHERE budget_item_id = p_budget_item_id;
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- 사용률 계산
    v_usage_percentage := CASE 
        WHEN v_budget_item.annual_budget > 0 THEN 
            (v_budget_item.used_budget / v_budget_item.annual_budget) * 100
        ELSE 0 
    END;
    
    -- 경고 설정 확인
    FOR v_alert_setting IN 
        SELECT * FROM bms.budget_alert_settings 
        WHERE budget_item_id = p_budget_item_id 
          AND is_enabled = true
          AND v_usage_percentage >= threshold_percentage
    LOOP
        -- 경고 수준 결정
        v_alert_level := CASE 
            WHEN v_usage_percentage >= 100 THEN 'EMERGENCY'
            WHEN v_usage_percentage >= 90 THEN 'CRITICAL'
            WHEN v_usage_percentage >= 80 THEN 'WARNING'
            ELSE 'INFO'
        END;
        
        -- 경고 메시지 생성
        v_alert_message := FORMAT(
            '예산 항목 "%s"의 사용률이 %.2f%%에 달했습니다. (사용금액: %s, 예산: %s)',
            v_budget_item.item_name,
            v_usage_percentage,
            v_budget_item.used_budget,
            v_budget_item.annual_budget
        );
        
        -- 경고 이력 생성
        INSERT INTO bms.budget_alert_history (
            budget_item_id, company_id, alert_type, alert_level,
            current_usage_amount, current_usage_percentage,
            threshold_percentage, alert_message
        ) VALUES (
            p_budget_item_id, v_budget_item.company_id, v_alert_setting.alert_type, v_alert_level,
            v_budget_item.used_budget, v_usage_percentage,
            v_alert_setting.threshold_percentage, v_alert_message
        );
    END LOOP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.check_budget_alerts IS '예산 경고 확인 함수';