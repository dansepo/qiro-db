-- =====================================================
-- Repair Completion Management Functions
-- Phase 4.3.3: Repair Completion Management Functions
-- =====================================================

-- 1. Create completion inspection function
CREATE OR REPLACE FUNCTION bms.create_completion_inspection(
    p_work_order_id UUID,
    p_inspection_type VARCHAR(30),
    p_inspector_id UUID,
    p_inspector_role VARCHAR(30),
    p_inspection_checklist JSONB DEFAULT NULL,
    p_quality_standards JSONB DEFAULT NULL,
    p_safety_requirements JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_inspection_id UUID;
    v_work_order RECORD;
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Create inspection record
    INSERT INTO bms.work_completion_inspections (
        company_id,
        work_order_id,
        inspection_type,
        inspector_id,
        inspector_role,
        inspection_checklist,
        quality_standards,
        safety_requirements,
        overall_result,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        p_inspection_type,
        p_inspector_id,
        p_inspector_role,
        p_inspection_checklist,
        p_quality_standards,
        p_safety_requirements,
        'PENDING',
        p_inspector_id
    ) RETURNING inspection_id INTO v_inspection_id;
    
    RETURN v_inspection_id;
END;
$$;

-- 2. Complete inspection function
CREATE OR REPLACE FUNCTION bms.complete_inspection(
    p_inspection_id UUID,
    p_overall_result VARCHAR(20),
    p_quality_score DECIMAL(3,1) DEFAULT NULL,
    p_safety_compliance_score DECIMAL(3,1) DEFAULT NULL,
    p_workmanship_score DECIMAL(3,1) DEFAULT NULL,
    p_passed_items JSONB DEFAULT NULL,
    p_failed_items JSONB DEFAULT NULL,
    p_defects_found JSONB DEFAULT NULL,
    p_inspection_notes TEXT DEFAULT NULL,
    p_recommendations TEXT DEFAULT NULL,
    p_requires_rework BOOLEAN DEFAULT FALSE,
    p_rework_deadline DATE DEFAULT NULL,
    p_inspector_id UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_inspection RECORD;
BEGIN
    -- Get inspection information
    SELECT * INTO v_inspection
    FROM bms.work_completion_inspections
    WHERE inspection_id = p_inspection_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection not found: %', p_inspection_id;
    END IF;
    
    -- Update inspection results
    UPDATE bms.work_completion_inspections
    SET overall_result = p_overall_result,
        quality_score = COALESCE(p_quality_score, quality_score),
        safety_compliance_score = COALESCE(p_safety_compliance_score, safety_compliance_score),
        workmanship_score = COALESCE(p_workmanship_score, workmanship_score),
        passed_items = COALESCE(p_passed_items, passed_items),
        failed_items = COALESCE(p_failed_items, failed_items),
        defects_found = COALESCE(p_defects_found, defects_found),
        inspection_notes = COALESCE(p_inspection_notes, inspection_notes),
        recommendations = COALESCE(p_recommendations, recommendations),
        requires_rework = p_requires_rework,
        rework_deadline = p_rework_deadline,
        updated_by = p_inspector_id
    WHERE inspection_id = p_inspection_id;
    
    -- Update work order status based on inspection result
    IF p_overall_result = 'FAILED' OR p_requires_rework THEN
        UPDATE bms.work_orders
        SET work_status = 'ON_HOLD',
            work_phase = 'REWORK_REQUIRED'
        WHERE work_order_id = v_inspection.work_order_id;
    ELSIF p_overall_result = 'PASSED' THEN
        UPDATE bms.work_orders
        SET work_phase = 'COMPLETION'
        WHERE work_order_id = v_inspection.work_order_id;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- 3. Create completion report function
CREATE OR REPLACE FUNCTION bms.create_completion_report(
    p_work_order_id UUID,
    p_work_summary TEXT,
    p_work_performed TEXT,
    p_total_hours_worked DECIMAL(8,2),
    p_labor_cost DECIMAL(12,2) DEFAULT 0,
    p_material_cost DECIMAL(12,2) DEFAULT 0,
    p_equipment_cost DECIMAL(12,2) DEFAULT 0,
    p_materials_used JSONB DEFAULT NULL,
    p_tools_used JSONB DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL,
    p_supervised_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_completion_report_id UUID;
    v_work_order RECORD;
    v_report_number VARCHAR(50);
    v_total_cost DECIMAL(12,2);
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Generate report number
    v_report_number := 'CR-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                      LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Calculate total cost
    v_total_cost := p_labor_cost + p_material_cost + p_equipment_cost;
    
    -- Create completion report
    INSERT INTO bms.work_completion_reports (
        company_id,
        work_order_id,
        report_number,
        work_summary,
        work_performed,
        total_hours_worked,
        labor_cost,
        material_cost,
        equipment_cost,
        total_cost,
        materials_used,
        tools_used,
        completed_by,
        supervised_by,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        v_report_number,
        p_work_summary,
        p_work_performed,
        p_total_hours_worked,
        p_labor_cost,
        p_material_cost,
        p_equipment_cost,
        v_total_cost,
        p_materials_used,
        p_tools_used,
        p_completed_by,
        p_supervised_by,
        p_completed_by
    ) RETURNING completion_report_id INTO v_completion_report_id;
    
    RETURN v_completion_report_id;
END;
$$;-- 
4. Create cost settlement function
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

-- 5. Create prevention measure function
CREATE OR REPLACE FUNCTION bms.create_prevention_measure(
    p_company_id UUID,
    p_measure_title VARCHAR(200),
    p_measure_description TEXT,
    p_root_cause_category VARCHAR(30),
    p_root_cause_description TEXT,
    p_prevention_type VARCHAR(30),
    p_prevention_category VARCHAR(30),
    p_preventive_actions JSONB,
    p_implementation_priority VARCHAR(20),
    p_estimated_cost DECIMAL(12,2) DEFAULT 0,
    p_estimated_duration_days INTEGER DEFAULT 0,
    p_work_order_id UUID DEFAULT NULL,
    p_fault_report_id UUID DEFAULT NULL,
    p_responsible_person UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_measure_id UUID;
    v_measure_code VARCHAR(20);
BEGIN
    -- Generate measure code
    v_measure_code := 'PM-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                     LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 4, '0');
    
    -- Create prevention measure
    INSERT INTO bms.prevention_measures (
        company_id,
        work_order_id,
        fault_report_id,
        measure_code,
        measure_title,
        measure_description,
        root_cause_category,
        root_cause_description,
        prevention_type,
        prevention_category,
        preventive_actions,
        implementation_priority,
        estimated_cost,
        estimated_duration_days,
        responsible_person,
        created_by
    ) VALUES (
        p_company_id,
        p_work_order_id,
        p_fault_report_id,
        v_measure_code,
        p_measure_title,
        p_measure_description,
        p_root_cause_category,
        p_root_cause_description,
        p_prevention_type,
        p_prevention_category,
        p_preventive_actions,
        p_implementation_priority,
        p_estimated_cost,
        p_estimated_duration_days,
        p_responsible_person,
        p_created_by
    ) RETURNING measure_id INTO v_measure_id;
    
    RETURN v_measure_id;
END;
$$;

-- 6. Create work warranty function
CREATE OR REPLACE FUNCTION bms.create_work_warranty(
    p_work_order_id UUID,
    p_warranty_type VARCHAR(30),
    p_warranty_provider VARCHAR(100),
    p_warranty_scope TEXT,
    p_warranty_duration_months INTEGER,
    p_warranty_terms TEXT,
    p_warranty_start_date DATE DEFAULT CURRENT_DATE,
    p_covered_components JSONB DEFAULT NULL,
    p_warranty_contact_person VARCHAR(100) DEFAULT NULL,
    p_warranty_contact_phone VARCHAR(20) DEFAULT NULL,
    p_warranty_contact_email VARCHAR(100) DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_warranty_id UUID;
    v_work_order RECORD;
    v_warranty_number VARCHAR(50);
    v_warranty_end_date DATE;
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Generate warranty number
    v_warranty_number := 'WR-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                        LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Calculate warranty end date
    v_warranty_end_date := p_warranty_start_date + (p_warranty_duration_months || ' months')::INTERVAL;
    
    -- Create warranty record
    INSERT INTO bms.work_warranties (
        company_id,
        work_order_id,
        warranty_number,
        warranty_type,
        warranty_provider,
        warranty_scope,
        covered_components,
        warranty_start_date,
        warranty_end_date,
        warranty_duration_months,
        warranty_terms,
        warranty_contact_person,
        warranty_contact_phone,
        warranty_contact_email,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        v_warranty_number,
        p_warranty_type,
        p_warranty_provider,
        p_warranty_scope,
        p_covered_components,
        p_warranty_start_date,
        v_warranty_end_date,
        p_warranty_duration_months,
        p_warranty_terms,
        p_warranty_contact_person,
        p_warranty_contact_phone,
        p_warranty_contact_email,
        p_created_by
    ) RETURNING warranty_id INTO v_warranty_id;
    
    RETURN v_warranty_id;
END;
$$;-- 7. Get c
ompletion statistics function
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

-- 8. Finalize work completion function
CREATE OR REPLACE FUNCTION bms.finalize_work_completion(
    p_work_order_id UUID,
    p_customer_acceptance BOOLEAN DEFAULT TRUE,
    p_customer_feedback TEXT DEFAULT NULL,
    p_follow_up_required BOOLEAN DEFAULT FALSE,
    p_follow_up_schedule JSONB DEFAULT NULL,
    p_finalized_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_work_order RECORD;
    v_completion_report_id UUID;
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Check if work order is completed
    IF v_work_order.work_status != 'COMPLETED' THEN
        RAISE EXCEPTION 'Work order must be completed before finalization';
    END IF;
    
    -- Update completion report with customer acceptance
    UPDATE bms.work_completion_reports
    SET customer_handover_date = NOW(),
        customer_acceptance = p_customer_acceptance,
        customer_feedback = p_customer_feedback,
        follow_up_required = p_follow_up_required,
        follow_up_schedule = p_follow_up_schedule,
        report_status = 'FINALIZED',
        updated_by = p_finalized_by
    WHERE work_order_id = p_work_order_id;
    
    -- Update work order closure
    UPDATE bms.work_orders
    SET work_phase = 'CLOSURE',
        closed_by = p_finalized_by,
        closed_date = NOW(),
        closure_reason = 'COMPLETED_AND_ACCEPTED',
        customer_satisfaction = CASE 
            WHEN p_customer_acceptance THEN 10.0 
            ELSE 5.0 
        END
    WHERE work_order_id = p_work_order_id;
    
    -- Update related fault report if exists
    IF v_work_order.fault_report_id IS NOT NULL THEN
        UPDATE bms.fault_reports
        SET report_status = 'CLOSED',
            resolution_status = 'COMPLETED'
        WHERE report_id = v_work_order.fault_report_id;
    END IF;
    
    RETURN TRUE;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.create_completion_inspection IS 'Create completion inspection for work order quality control';
COMMENT ON FUNCTION bms.complete_inspection IS 'Complete inspection with results and recommendations';
COMMENT ON FUNCTION bms.create_completion_report IS 'Create comprehensive completion report with technical details';
COMMENT ON FUNCTION bms.create_cost_settlement IS 'Create cost settlement with variance analysis';
COMMENT ON FUNCTION bms.create_prevention_measure IS 'Create prevention measure based on root cause analysis';
COMMENT ON FUNCTION bms.create_work_warranty IS 'Create warranty record for completed work';
COMMENT ON FUNCTION bms.get_completion_statistics IS 'Get comprehensive completion statistics and analytics';
COMMENT ON FUNCTION bms.finalize_work_completion IS 'Finalize work completion with customer acceptance';

-- Script completion message
SELECT 'Repair completion management functions created successfully.' as message;