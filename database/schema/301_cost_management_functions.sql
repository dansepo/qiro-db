-- =====================================================
-- 비용 관리 시스템 함수 및 프로시저
-- 작업: 15. 비용 관리 REST API 구현
-- =====================================================

-- 1. 예산 사용량 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_budget_usage(
    p_company_id UUID,
    p_budget_category VARCHAR(50),
    p_budget_year INTEGER,
    p_amount DECIMAL(12,2)
)
RETURNS VOID AS $$
BEGIN
    -- 해당 예산의 사용량 업데이트
    UPDATE bms.budget_management 
    SET 
        spent_amount = spent_amount + p_amount,
        available_amount = allocated_amount - (spent_amount + p_amount) - committed_amount,
        updated_at = NOW()
    WHERE 
        company_id = p_company_id 
        AND budget_category = p_budget_category 
        AND budget_year = p_budget_year
        AND budget_status = 'ACTIVE';
        
    -- 업데이트된 행이 없으면 예외 발생
    IF NOT FOUND THEN
        RAISE EXCEPTION '활성 예산을 찾을 수 없습니다: 회사 %, 카테고리 %, 연도 %', 
            p_company_id, p_budget_category, p_budget_year;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 2. 비용 기록 생성 함수
CREATE OR REPLACE FUNCTION bms.create_cost_record(
    p_company_id UUID,
    p_cost_type VARCHAR(30),
    p_category VARCHAR(50),
    p_amount DECIMAL(12,2),
    p_cost_date DATE,
    p_description TEXT,
    p_created_by UUID,
    p_work_order_id UUID DEFAULT NULL,
    p_maintenance_id UUID DEFAULT NULL,
    p_fault_report_id UUID DEFAULT NULL,
    p_payment_method VARCHAR(20) DEFAULT NULL,
    p_invoice_number VARCHAR(50) DEFAULT NULL,
    p_budget_category VARCHAR(50) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_cost_id UUID;
    v_cost_number VARCHAR(50);
    v_budget_year INTEGER;
BEGIN
    -- 비용 번호 생성
    v_cost_number := 'COST-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                     LPAD(NEXTVAL('bms.cost_number_seq')::TEXT, 4, '0');
    
    -- 예산 연도 설정
    v_budget_year := EXTRACT(YEAR FROM p_cost_date);
    
    -- 비용 기록 생성
    INSERT INTO bms.cost_tracking (
        company_id, work_order_id, maintenance_id, fault_report_id,
        cost_number, cost_type, category, amount, cost_date,
        description, payment_method, invoice_number,
        budget_category, budget_year, budget_month, created_by
    ) VALUES (
        p_company_id, p_work_order_id, p_maintenance_id, p_fault_report_id,
        v_cost_number, p_cost_type, p_category, p_amount, p_cost_date,
        p_description, p_payment_method, p_invoice_number,
        COALESCE(p_budget_category, p_category), v_budget_year, 
        EXTRACT(MONTH FROM p_cost_date), p_created_by
    ) RETURNING cost_id INTO v_cost_id;
    
    -- 예산 사용량 업데이트 (예산이 설정된 경우)
    IF p_budget_category IS NOT NULL THEN
        BEGIN
            PERFORM bms.update_budget_usage(
                p_company_id, 
                p_budget_category, 
                v_budget_year, 
                p_amount
            );
        EXCEPTION WHEN OTHERS THEN
            -- 예산이 없어도 비용 기록은 생성되도록 함
            RAISE NOTICE '예산 업데이트 실패: %', SQLERRM;
        END;
    END IF;
    
    RETURN v_cost_id;
END;
$$ LANGUAGE plpgsql;

-- 3. 예산 상태 확인 함수
CREATE OR REPLACE FUNCTION bms.check_budget_status(
    p_company_id UUID,
    p_budget_category VARCHAR(50),
    p_budget_year INTEGER
)
RETURNS TABLE (
    budget_id UUID,
    budget_name VARCHAR(100),
    allocated_amount DECIMAL(12,2),
    spent_amount DECIMAL(12,2),
    available_amount DECIMAL(12,2),
    utilization_percentage DECIMAL(5,2),
    status_level VARCHAR(20),
    warning_threshold DECIMAL(5,2),
    critical_threshold DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bm.budget_id,
        bm.budget_name,
        bm.allocated_amount,
        bm.spent_amount,
        bm.available_amount,
        ROUND((bm.spent_amount / bm.allocated_amount * 100)::NUMERIC, 2) as utilization_percentage,
        CASE 
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.critical_threshold THEN 'CRITICAL'
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.warning_threshold THEN 'WARNING'
            ELSE 'NORMAL'
        END as status_level,
        bm.warning_threshold,
        bm.critical_threshold
    FROM bms.budget_management bm
    WHERE 
        bm.company_id = p_company_id 
        AND bm.budget_category = p_budget_category 
        AND bm.budget_year = p_budget_year
        AND bm.budget_status = 'ACTIVE';
END;
$$ LANGUAGE plpgsql;

-- 4. 비용 통계 분석 함수
CREATE OR REPLACE FUNCTION bms.get_cost_statistics(
    p_company_id UUID,
    p_start_date DATE,
    p_end_date DATE,
    p_category VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    total_cost DECIMAL(12,2),
    transaction_count BIGINT,
    average_cost DECIMAL(12,2),
    labor_cost DECIMAL(12,2),
    material_cost DECIMAL(12,2),
    equipment_cost DECIMAL(12,2),
    contractor_cost DECIMAL(12,2),
    emergency_cost DECIMAL(12,2),
    preventive_cost DECIMAL(12,2),
    corrective_cost DECIMAL(12,2),
    upgrade_cost DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        SUM(ct.amount) as total_cost,
        COUNT(*) as transaction_count,
        AVG(ct.amount) as average_cost,
        
        -- 비용 유형별
        SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount ELSE 0 END) as labor_cost,
        SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount ELSE 0 END) as material_cost,
        SUM(CASE WHEN ct.cost_type = 'EQUIPMENT' THEN ct.amount ELSE 0 END) as equipment_cost,
        SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount ELSE 0 END) as contractor_cost,
        SUM(CASE WHEN ct.cost_type = 'EMERGENCY' THEN ct.amount ELSE 0 END) as emergency_cost,
        
        -- 카테고리별
        SUM(CASE WHEN ct.category = 'PREVENTIVE' THEN ct.amount ELSE 0 END) as preventive_cost,
        SUM(CASE WHEN ct.category = 'CORRECTIVE' THEN ct.amount ELSE 0 END) as corrective_cost,
        SUM(CASE WHEN ct.category = 'UPGRADE' THEN ct.amount ELSE 0 END) as upgrade_cost
        
    FROM bms.cost_tracking ct
    WHERE 
        ct.company_id = p_company_id
        AND ct.cost_date BETWEEN p_start_date AND p_end_date
        AND (p_category IS NULL OR ct.category = p_category);
END;
$$ LANGUAGE plpgsql;

-- 5. 월별 비용 트렌드 분석 함수
CREATE OR REPLACE FUNCTION bms.get_monthly_cost_trend(
    p_company_id UUID,
    p_year INTEGER,
    p_category VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    month_number INTEGER,
    month_name VARCHAR(20),
    total_cost DECIMAL(12,2),
    transaction_count BIGINT,
    average_cost DECIMAL(12,2),
    cost_change_percentage DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    WITH monthly_costs AS (
        SELECT 
            EXTRACT(MONTH FROM ct.cost_date)::INTEGER as month_num,
            SUM(ct.amount) as monthly_total,
            COUNT(*) as monthly_count,
            AVG(ct.amount) as monthly_avg
        FROM bms.cost_tracking ct
        WHERE 
            ct.company_id = p_company_id
            AND EXTRACT(YEAR FROM ct.cost_date) = p_year
            AND (p_category IS NULL OR ct.category = p_category)
        GROUP BY EXTRACT(MONTH FROM ct.cost_date)
    ),
    monthly_with_change AS (
        SELECT 
            mc.month_num,
            mc.monthly_total,
            mc.monthly_count,
            mc.monthly_avg,
            LAG(mc.monthly_total) OVER (ORDER BY mc.month_num) as prev_month_total
        FROM monthly_costs mc
    )
    SELECT 
        mwc.month_num as month_number,
        TO_CHAR(TO_DATE(mwc.month_num::TEXT, 'MM'), 'Month') as month_name,
        mwc.monthly_total as total_cost,
        mwc.monthly_count as transaction_count,
        mwc.monthly_avg as average_cost,
        CASE 
            WHEN mwc.prev_month_total IS NULL OR mwc.prev_month_total = 0 THEN 0
            ELSE ROUND(((mwc.monthly_total - mwc.prev_month_total) / mwc.prev_month_total * 100)::NUMERIC, 2)
        END as cost_change_percentage
    FROM monthly_with_change mwc
    ORDER BY mwc.month_num;
END;
$$ LANGUAGE plpgsql;

-- 6. 예산 경고 알림 함수
CREATE OR REPLACE FUNCTION bms.check_budget_alerts(
    p_company_id UUID
)
RETURNS TABLE (
    budget_id UUID,
    budget_name VARCHAR(100),
    budget_category VARCHAR(50),
    utilization_percentage DECIMAL(5,2),
    alert_level VARCHAR(20),
    remaining_amount DECIMAL(12,2),
    days_remaining INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bm.budget_id,
        bm.budget_name,
        bm.budget_category,
        ROUND((bm.spent_amount / bm.allocated_amount * 100)::NUMERIC, 2) as utilization_percentage,
        CASE 
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.critical_threshold THEN 'CRITICAL'
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.warning_threshold THEN 'WARNING'
            ELSE 'NORMAL'
        END as alert_level,
        (bm.allocated_amount - bm.spent_amount - bm.committed_amount) as remaining_amount,
        (bm.end_date - CURRENT_DATE) as days_remaining
    FROM bms.budget_management bm
    WHERE 
        bm.company_id = p_company_id
        AND bm.budget_status = 'ACTIVE'
        AND (
            (bm.spent_amount / bm.allocated_amount * 100) >= bm.warning_threshold
            OR (bm.end_date - CURRENT_DATE) <= 30
        )
    ORDER BY 
        CASE 
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.critical_threshold THEN 1
            WHEN (bm.spent_amount / bm.allocated_amount * 100) >= bm.warning_threshold THEN 2
            ELSE 3
        END,
        bm.budget_name;
END;
$$ LANGUAGE plpgsql;

-- 7. 시퀀스 생성 (비용 번호용)
CREATE SEQUENCE IF NOT EXISTS bms.cost_number_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- 8. 함수 코멘트
COMMENT ON FUNCTION bms.update_budget_usage(UUID, VARCHAR(50), INTEGER, DECIMAL(12,2)) IS '예산 사용량 업데이트';
COMMENT ON FUNCTION bms.create_cost_record(UUID, VARCHAR(30), VARCHAR(50), DECIMAL(12,2), DATE, TEXT, UUID, UUID, UUID, UUID, VARCHAR(20), VARCHAR(50), VARCHAR(50)) IS '비용 기록 생성';
COMMENT ON FUNCTION bms.check_budget_status(UUID, VARCHAR(50), INTEGER) IS '예산 상태 확인';
COMMENT ON FUNCTION bms.get_cost_statistics(UUID, DATE, DATE, VARCHAR(50)) IS '비용 통계 분석';
COMMENT ON FUNCTION bms.get_monthly_cost_trend(UUID, INTEGER, VARCHAR(50)) IS '월별 비용 트렌드 분석';
COMMENT ON FUNCTION bms.check_budget_alerts(UUID) IS '예산 경고 알림 확인';