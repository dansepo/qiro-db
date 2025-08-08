-- =====================================================
-- Individual Repair Work Management Functions
-- Phase 4.3.2: Individual Function Creation
-- =====================================================

-- Add work order material function
CREATE OR REPLACE FUNCTION bms.add_work_order_material(
    p_work_order_id UUID,
    p_material_name VARCHAR(200),
    p_required_quantity DECIMAL(10,3),
    p_unit_of_measure VARCHAR(20),
    p_material_code VARCHAR(50) DEFAULT NULL,
    p_material_category VARCHAR(50) DEFAULT NULL,
    p_unit_cost DECIMAL(12,2) DEFAULT 0,
    p_supplier_name VARCHAR(200) DEFAULT NULL,
    p_quality_check_required BOOLEAN DEFAULT FALSE,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_material_usage_id UUID;
    v_work_order RECORD;
    v_total_estimated_cost DECIMAL(12,2);
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Calculate total estimated cost
    v_total_estimated_cost := p_required_quantity * p_unit_cost;
    
    -- Create material requirement
    INSERT INTO bms.work_order_materials (
        company_id,
        work_order_id,
        material_code,
        material_name,
        material_category,
        required_quantity,
        unit_of_measure,
        unit_cost,
        total_estimated_cost,
        supplier_name,
        quality_check_required,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        p_material_code,
        p_material_name,
        p_material_category,
        p_required_quantity,
        p_unit_of_measure,
        p_unit_cost,
        v_total_estimated_cost,
        p_supplier_name,
        p_quality_check_required,
        p_created_by
    ) RETURNING material_usage_id INTO v_material_usage_id;
    
    -- Update work order estimated cost
    UPDATE bms.work_orders
    SET estimated_cost = estimated_cost + v_total_estimated_cost
    WHERE work_order_id = p_work_order_id;
    
    RETURN v_material_usage_id;
END;
$$;

-- Get work order statistics function
CREATE OR REPLACE FUNCTION bms.get_work_order_statistics(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
) RETURNS TABLE (
    total_work_orders BIGINT,
    pending_work_orders BIGINT,
    in_progress_work_orders BIGINT,
    completed_work_orders BIGINT,
    overdue_work_orders BIGINT,
    avg_completion_time_hours DECIMAL(8,2),
    avg_cost_per_order DECIMAL(12,2),
    total_estimated_cost DECIMAL(12,2),
    total_actual_cost DECIMAL(12,2),
    work_orders_by_category JSONB,
    work_orders_by_priority JSONB,
    work_orders_by_status JSONB,
    monthly_trend JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_date_from DATE := COALESCE(p_date_from, CURRENT_DATE - INTERVAL '30 days');
    v_date_to DATE := COALESCE(p_date_to, CURRENT_DATE);
BEGIN
    RETURN QUERY
    WITH work_stats AS (
        SELECT 
            COUNT(*) as total_work_orders,
            COUNT(*) FILTER (WHERE work_status IN ('PENDING', 'APPROVED', 'SCHEDULED')) as pending_work_orders,
            COUNT(*) FILTER (WHERE work_status = 'IN_PROGRESS') as in_progress_work_orders,
            COUNT(*) FILTER (WHERE work_status = 'COMPLETED') as completed_work_orders,
            COUNT(*) FILTER (WHERE 
                work_status NOT IN ('COMPLETED', 'CANCELLED') AND
                scheduled_start_date < NOW()
            ) as overdue_work_orders,
            AVG(CASE 
                WHEN actual_start_date IS NOT NULL AND actual_end_date IS NOT NULL
                THEN EXTRACT(EPOCH FROM (actual_end_date - actual_start_date)) / 3600
                ELSE NULL
            END) as avg_completion_time_hours,
            AVG(actual_cost) FILTER (WHERE actual_cost > 0) as avg_cost_per_order,
            SUM(estimated_cost) as total_estimated_cost,
            SUM(actual_cost) as total_actual_cost
        FROM bms.work_orders wo
        WHERE wo.company_id = p_company_id
            AND (p_building_id IS NULL OR wo.building_id = p_building_id)
            AND DATE(wo.request_date) BETWEEN v_date_from AND v_date_to
    ),
    category_stats AS (
        SELECT jsonb_object_agg(work_category, count) as work_orders_by_category
        FROM (
            SELECT work_category, COUNT(*) as count
            FROM bms.work_orders wo
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND DATE(wo.request_date) BETWEEN v_date_from AND v_date_to
            GROUP BY work_category
        ) t
    ),
    priority_stats AS (
        SELECT jsonb_object_agg(work_priority, count) as work_orders_by_priority
        FROM (
            SELECT work_priority, COUNT(*) as count
            FROM bms.work_orders wo
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND DATE(wo.request_date) BETWEEN v_date_from AND v_date_to
            GROUP BY work_priority
        ) t
    ),
    status_stats AS (
        SELECT jsonb_object_agg(work_status, count) as work_orders_by_status
        FROM (
            SELECT work_status, COUNT(*) as count
            FROM bms.work_orders wo
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND DATE(wo.request_date) BETWEEN v_date_from AND v_date_to
            GROUP BY work_status
        ) t
    ),
    monthly_stats AS (
        SELECT jsonb_object_agg(month_year, count) as monthly_trend
        FROM (
            SELECT 
                TO_CHAR(request_date, 'YYYY-MM') as month_year,
                COUNT(*) as count
            FROM bms.work_orders wo
            WHERE wo.company_id = p_company_id
                AND (p_building_id IS NULL OR wo.building_id = p_building_id)
                AND request_date >= CURRENT_DATE - INTERVAL '12 months'
            GROUP BY TO_CHAR(request_date, 'YYYY-MM')
            ORDER BY month_year
        ) t
    )
    SELECT 
        ws.total_work_orders,
        ws.pending_work_orders,
        ws.in_progress_work_orders,
        ws.completed_work_orders,
        ws.overdue_work_orders,
        ws.avg_completion_time_hours,
        ws.avg_cost_per_order,
        ws.total_estimated_cost,
        ws.total_actual_cost,
        cs.work_orders_by_category,
        ps.work_orders_by_priority,
        ss.work_orders_by_status,
        ms.monthly_trend
    FROM work_stats ws
    CROSS JOIN category_stats cs
    CROSS JOIN priority_stats ps
    CROSS JOIN status_stats ss
    CROSS JOIN monthly_stats ms;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.add_work_order_material IS 'Add material requirement to work order with cost calculation';
COMMENT ON FUNCTION bms.get_work_order_statistics IS 'Get comprehensive work order statistics and analytics';

-- Script completion message
SELECT 'Individual repair work functions created successfully.' as message;