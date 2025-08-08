-- =====================================================
-- Individual Completion Management Functions
-- Phase 4.3.3: Individual Function Creation
-- =====================================================

-- Create cost settlement function
CREATE OR REPLACE FUNCTION bms.create_cost_settlement(
    p_work_order_id UUID,
    p_settlement_type VARCHAR(20),
    p_estimated_labor_cost DECIMAL(12,2) DEFAULT 0,
    p_actual_labor_cost DECIMAL(12,2) DEFAULT 0,
    p_estimated_material_cost DECIMAL(12,2) DEFAULT 0,
    p_actual_material_cost DECIMAL(12,2) DEFAULT 0,
    p_estimated_equipment_cost DECIMAL(12,2) DEFAULT 0,
    p_actual_equipment_cost DECIMAL(12,2) DEFAULT 0,
    p_overtime_cost DECIMAL(12,2) DEFAULT 0,
    p_contractor_fees DECIMAL(12,2) DEFAULT 0,
    p_approved_budget DECIMAL(12,2) DEFAULT 0,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_settlement_id UUID;
    v_work_order RECORD;
    v_settlement_number VARCHAR(50);
    v_total_estimated_cost DECIMAL(12,2);
    v_total_actual_cost DECIMAL(12,2);
    v_cost_variance DECIMAL(12,2);
    v_variance_percentage DECIMAL(5,2);
    v_budget_variance DECIMAL(12,2);
    v_budget_utilization_percentage DECIMAL(5,2);
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Generate settlement number
    v_settlement_number := 'CS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Calculate totals and variances
    v_total_estimated_cost := p_estimated_labor_cost + p_estimated_material_cost + p_estimated_equipment_cost;
    v_total_actual_cost := p_actual_labor_cost + p_actual_material_cost + p_actual_equipment_cost + 
                          p_overtime_cost + p_contractor_fees;
    v_cost_variance := v_total_actual_cost - v_total_estimated_cost;
    
    -- Calculate variance percentage
    IF v_total_estimated_cost > 0 THEN
        v_variance_percentage := (v_cost_variance / v_total_estimated_cost) * 100;
    ELSE
        v_variance_percentage := 0;
    END IF;
    
    -- Calculate budget variance and utilization
    IF p_approved_budget > 0 THEN
        v_budget_variance := v_total_actual_cost - p_approved_budget;
        v_budget_utilization_percentage := (v_total_actual_cost / p_approved_budget) * 100;
    ELSE
        v_budget_variance := 0;
        v_budget_utilization_percentage := 0;
    END IF;
    
    -- Create cost settlement
    INSERT INTO bms.work_cost_settlements (
        company_id,
        work_order_id,
        settlement_number,
        settlement_type,
        estimated_labor_cost,
        actual_labor_cost,
        estimated_material_cost,
        actual_material_cost,
        estimated_equipment_cost,
        actual_equipment_cost,
        overtime_cost,
        contractor_fees,
        total_estimated_cost,
        total_actual_cost,
        cost_variance,
        variance_percentage,
        approved_budget,
        budget_utilization_percentage,
        budget_variance,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        v_settlement_number,
        p_settlement_type,
        p_estimated_labor_cost,
        p_actual_labor_cost,
        p_estimated_material_cost,
        p_actual_material_cost,
        p_estimated_equipment_cost,
        p_actual_equipment_cost,
        p_overtime_cost,
        p_contractor_fees,
        v_total_estimated_cost,
        v_total_actual_cost,
        v_cost_variance,
        v_variance_percentage,
        p_approved_budget,
        v_budget_utilization_percentage,
        v_budget_variance,
        p_created_by
    ) RETURNING settlement_id INTO v_settlement_id;
    
    -- Update work order with actual cost
    UPDATE bms.work_orders
    SET actual_cost = v_total_actual_cost
    WHERE work_order_id = p_work_order_id;
    
    RETURN v_settlement_id;
END;
$$;

-- Get completion statistics function
CREATE OR REPLACE FUNCTION bms.get_completion_statistics(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
) RETURNS TABLE (
    total_completed_works BIGINT,
    passed_inspections BIGINT,
    failed_inspections BIGINT,
    rework_required BIGINT,
    avg_quality_score DECIMAL(3,1),
    avg_safety_score DECIMAL(3,1),
    avg_workmanship_score DECIMAL(3,1),
    total_cost_variance DECIMAL(12,2),
    avg_cost_variance_percentage DECIMAL(5,2),
    budget_overruns BIGINT,
    active_warranties BIGINT,
    prevention_measures_implemented BIGINT,
    completion_by_category JSONB,
    cost_variance_by_type JSONB,
    warranty_status_distribution JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_date_from DATE := COALESCE(p_date_from, CURRENT_DATE - INTERVAL '30 days');
    v_date_to DATE := COALESCE(p_date_to, CURRENT_DATE);
BEGIN
    RETURN QUERY
    WITH completion_stats AS (
        SELECT 
            COUNT(DISTINCT wo.work_order_id) as total_completed_works,
            COUNT(DISTINCT wci.inspection_id) FILTER (WHERE wci.overall_result = 'PASSED') as passed_inspections,
            COUNT(DISTINCT wci.inspection_id) FILTER (WHERE wci.overall_result = 'FAILED') as failed_inspections,
            COUNT(DISTINCT wci.inspection_id) FILTER (WHERE wci.requires_rework = true) as rework_required,
            AVG(wci.quality_score) FILTER (WHERE wci.quality_score > 0) as avg_quality_score,
            AVG(wci.safety_compliance_score) FILTER (WHERE wci.safety_compliance_score > 0) as avg_safety_score,
            AVG(wci.workmanship_score) FILTER (WHERE wci.workmanship_score > 0) as avg_workmanship_score,
            SUM(wcs.cost_variance) as total_cost_variance,
            AVG(wcs.variance_percentage) as avg_cost_variance_percentage,
            COUNT(DISTINCT wcs.settlement_id) FILTER (WHERE wcs.budget_variance > 0) as budget_overruns,
            COUNT(DISTINCT ww.warranty_id) FILTER (WHERE ww.warranty_status = 'ACTIVE') as active_warranties,
            COUNT(DISTINCT pm.measure_id) FILTER (WHERE pm.implementation_status = 'COMPLETED') as prevention_measures_implemented
        FROM bms.work_orders wo
        LEFT JOIN bms.work_completion_inspections wci ON wo.work_order_id = wci.work_order_id
        LEFT JOIN bms.work_cost_settlements wcs ON wo.work_order_id = wcs.work_order_id
        LEFT JOIN bms.work_warranties ww ON wo.work_order_id = ww.work_order_id
        LEFT JOIN bms.prevention_measures pm ON wo.work_order_id = pm.work_order_id
        WHERE wo.company_id = p_company_id
            AND wo.work_status = 'COMPLETED'
            AND (p_building_id IS NULL OR wo.building_id = p_building_id)
            AND DATE(wo.actual_end_date) BETWEEN v_date_from AND v_date_to
    ),
    category_stats AS (
        SELECT jsonb_object_agg(work_category, count) as completion_by_category
        FROM (
            SELECT wo.work_category, COUNT(*) as count
            FROM bms.work_orders wo
            WHERE wo.company_id = p_company_id
                AND wo.work_status = 'COMPLETED'
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND DATE(wo.actual_end_date) BETWEEN v_date_from AND v_date_to
            GROUP BY wo.work_category
        ) t
    ),
    variance_stats AS (
        SELECT jsonb_object_agg(settlement_type, avg_variance) as cost_variance_by_type
        FROM (
            SELECT wcs.settlement_type, AVG(wcs.variance_percentage) as avg_variance
            FROM bms.work_cost_settlements wcs
            JOIN bms.work_orders wo ON wcs.work_order_id = wo.work_order_id
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND DATE(wcs.settlement_date) BETWEEN v_date_from AND v_date_to
            GROUP BY wcs.settlement_type
        ) t
    ),
    warranty_stats AS (
        SELECT jsonb_object_agg(warranty_status, count) as warranty_status_distribution
        FROM (
            SELECT ww.warranty_status, COUNT(*) as count
            FROM bms.work_warranties ww
            JOIN bms.work_orders wo ON ww.work_order_id = wo.work_order_id
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
            GROUP BY ww.warranty_status
        ) t
    )
    SELECT 
        cs.total_completed_works,
        cs.passed_inspections,
        cs.failed_inspections,
        cs.rework_required,
        cs.avg_quality_score,
        cs.avg_safety_score,
        cs.avg_workmanship_score,
        cs.total_cost_variance,
        cs.avg_cost_variance_percentage,
        cs.budget_overruns,
        cs.active_warranties,
        cs.prevention_measures_implemented,
        cat.completion_by_category,
        var.cost_variance_by_type,
        war.warranty_status_distribution
    FROM completion_stats cs
    CROSS JOIN category_stats cat
    CROSS JOIN variance_stats var
    CROSS JOIN warranty_stats war;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.create_cost_settlement IS 'Create cost settlement with variance analysis';
COMMENT ON FUNCTION bms.get_completion_statistics IS 'Get comprehensive completion statistics and analytics';

-- Script completion message
SELECT 'Individual completion functions created successfully.' as message;