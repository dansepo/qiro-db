-- =====================================================
-- Repair Work Management Functions
-- Phase 4.3.2: Repair Work Management Functions
-- =====================================================

-- 1. Create work order function
CREATE OR REPLACE FUNCTION bms.create_work_order(
    p_company_id UUID,
    p_work_order_title VARCHAR(200),
    p_work_description TEXT,
    p_work_category VARCHAR(30),
    p_work_type VARCHAR(30),
    p_work_priority VARCHAR(20),
    p_work_urgency VARCHAR(20),
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_asset_id UUID DEFAULT NULL,
    p_fault_report_id UUID DEFAULT NULL,
    p_template_id UUID DEFAULT NULL,
    p_requested_by UUID DEFAULT NULL,
    p_work_location TEXT DEFAULT NULL,
    p_work_scope TEXT DEFAULT NULL,
    p_estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    p_estimated_cost DECIMAL(12,2) DEFAULT 0
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_work_order_id UUID;
    v_work_order_number VARCHAR(50);
    v_template RECORD;
BEGIN
    -- Generate work order number
    v_work_order_number := 'WO-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Get template information if provided
    IF p_template_id IS NOT NULL THEN
        SELECT * INTO v_template
        FROM bms.work_order_templates
        WHERE template_id = p_template_id AND company_id = p_company_id;
        
        IF FOUND THEN
            -- Use template defaults if not provided
            p_estimated_duration_hours := COALESCE(p_estimated_duration_hours, v_template.estimated_duration_hours);
            p_work_description := COALESCE(p_work_description, v_template.work_instructions);
        END IF;
    END IF;
    
    -- Create work order
    INSERT INTO bms.work_orders (
        company_id,
        building_id,
        unit_id,
        asset_id,
        fault_report_id,
        work_order_number,
        work_order_title,
        work_description,
        work_category,
        work_type,
        work_priority,
        work_urgency,
        template_id,
        requested_by,
        work_location,
        work_scope,
        estimated_duration_hours,
        estimated_cost,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_unit_id,
        p_asset_id,
        p_fault_report_id,
        v_work_order_number,
        p_work_order_title,
        p_work_description,
        p_work_category,
        p_work_type,
        p_work_priority,
        p_work_urgency,
        p_template_id,
        p_requested_by,
        p_work_location,
        p_work_scope,
        p_estimated_duration_hours,
        p_estimated_cost,
        p_requested_by
    ) RETURNING work_order_id INTO v_work_order_id;
    
    -- Update related fault report if exists
    IF p_fault_report_id IS NOT NULL THEN
        UPDATE bms.fault_reports
        SET report_status = 'ASSIGNED',
            resolution_status = 'SCHEDULED'
        WHERE report_id = p_fault_report_id;
    END IF;
    
    RETURN v_work_order_id;
END;
$$;

-- 2. Assign work order function
CREATE OR REPLACE FUNCTION bms.assign_work_order(
    p_work_order_id UUID,
    p_assigned_to UUID,
    p_assignment_role VARCHAR(30) DEFAULT 'PRIMARY_TECHNICIAN',
    p_assignment_type VARCHAR(20) DEFAULT 'INTERNAL',
    p_allocated_hours DECIMAL(8,2) DEFAULT 0,
    p_expected_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_expected_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_assignment_notes TEXT DEFAULT NULL,
    p_assigned_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_assignment_id UUID;
    v_work_order RECORD;
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Create assignment
    INSERT INTO bms.work_order_assignments (
        company_id,
        work_order_id,
        assigned_to,
        assignment_role,
        assignment_type,
        allocated_hours,
        expected_start_date,
        expected_end_date,
        assignment_notes,
        created_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        p_assigned_to,
        p_assignment_role,
        p_assignment_type,
        p_allocated_hours,
        p_expected_start_date,
        p_expected_end_date,
        p_assignment_notes,
        p_assigned_by
    ) RETURNING assignment_id INTO v_assignment_id;
    
    -- Update work order status if this is the primary assignment
    IF p_assignment_role = 'PRIMARY_TECHNICIAN' THEN
        UPDATE bms.work_orders
        SET assigned_to = p_assigned_to,
            assignment_date = NOW(),
            work_status = CASE 
                WHEN work_status = 'PENDING' THEN 'SCHEDULED'
                ELSE work_status
            END,
            updated_by = p_assigned_by
        WHERE work_order_id = p_work_order_id;
    END IF;
    
    RETURN v_assignment_id;
END;
$$;

-- 3. Update work order status function
CREATE OR REPLACE FUNCTION bms.update_work_order_status(
    p_work_order_id UUID,
    p_new_status VARCHAR(20),
    p_work_phase VARCHAR(30) DEFAULT NULL,
    p_progress_percentage INTEGER DEFAULT NULL,
    p_status_notes TEXT DEFAULT NULL,
    p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_work_order RECORD;
    v_old_status VARCHAR(20);
BEGIN
    -- Get current work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    v_old_status := v_work_order.work_status;
    
    -- Update status
    UPDATE bms.work_orders
    SET work_status = p_new_status,
        work_phase = COALESCE(p_work_phase, work_phase),
        progress_percentage = COALESCE(p_progress_percentage, progress_percentage),
        actual_start_date = CASE 
            WHEN p_new_status = 'IN_PROGRESS' AND actual_start_date IS NULL 
            THEN NOW() 
            ELSE actual_start_date 
        END,
        actual_end_date = CASE 
            WHEN p_new_status = 'COMPLETED' AND actual_end_date IS NULL 
            THEN NOW() 
            ELSE actual_end_date 
        END,
        updated_by = p_updated_by
    WHERE work_order_id = p_work_order_id;
    
    -- Update related fault report if exists
    IF v_work_order.fault_report_id IS NOT NULL THEN
        UPDATE bms.fault_reports
        SET resolution_status = CASE p_new_status
            WHEN 'IN_PROGRESS' THEN 'IN_PROGRESS'
            WHEN 'COMPLETED' THEN 'COMPLETED'
            WHEN 'CANCELLED' THEN 'CANCELLED'
            ELSE resolution_status
        END
        WHERE report_id = v_work_order.fault_report_id;
    END IF;
    
    RETURN TRUE;
END;
$$;-
- 4. Add work order material function
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

-- 5. Record work progress function
CREATE OR REPLACE FUNCTION bms.record_work_progress(
    p_work_order_id UUID,
    p_progress_percentage INTEGER,
    p_work_phase VARCHAR(30),
    p_work_completed TEXT,
    p_work_remaining TEXT DEFAULT NULL,
    p_issues_encountered TEXT DEFAULT NULL,
    p_hours_worked DECIMAL(8,2) DEFAULT 0,
    p_next_steps TEXT DEFAULT NULL,
    p_expected_completion_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_reported_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_progress_id UUID;
    v_work_order RECORD;
    v_cumulative_hours DECIMAL(8,2);
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Calculate cumulative hours
    SELECT COALESCE(SUM(hours_worked), 0) + p_hours_worked INTO v_cumulative_hours
    FROM bms.work_order_progress
    WHERE work_order_id = p_work_order_id;
    
    -- Create progress record
    INSERT INTO bms.work_order_progress (
        company_id,
        work_order_id,
        progress_percentage,
        work_phase,
        work_completed,
        work_remaining,
        issues_encountered,
        hours_worked,
        cumulative_hours,
        next_steps,
        expected_completion_date,
        reported_by
    ) VALUES (
        v_work_order.company_id,
        p_work_order_id,
        p_progress_percentage,
        p_work_phase,
        p_work_completed,
        p_work_remaining,
        p_issues_encountered,
        p_hours_worked,
        v_cumulative_hours,
        p_next_steps,
        p_expected_completion_date,
        p_reported_by
    ) RETURNING progress_id INTO v_progress_id;
    
    -- Update work order progress
    UPDATE bms.work_orders
    SET progress_percentage = p_progress_percentage,
        work_phase = p_work_phase,
        actual_duration_hours = v_cumulative_hours,
        updated_by = p_reported_by
    WHERE work_order_id = p_work_order_id;
    
    -- Auto-update status based on progress
    IF p_progress_percentage = 100 AND v_work_order.work_status != 'COMPLETED' THEN
        PERFORM bms.update_work_order_status(
            p_work_order_id,
            'COMPLETED',
            'COMPLETION',
            100,
            'Work completed automatically based on 100% progress',
            p_reported_by
        );
    ELSIF p_progress_percentage > 0 AND v_work_order.work_status = 'SCHEDULED' THEN
        PERFORM bms.update_work_order_status(
            p_work_order_id,
            'IN_PROGRESS',
            p_work_phase,
            p_progress_percentage,
            'Work started automatically based on progress update',
            p_reported_by
        );
    END IF;
    
    RETURN v_progress_id;
END;
$$;

-- 6. Get work orders with filters function
CREATE OR REPLACE FUNCTION bms.get_work_orders(
    p_company_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_work_status VARCHAR(20) DEFAULT NULL,
    p_work_priority VARCHAR(20) DEFAULT NULL,
    p_work_category VARCHAR(30) DEFAULT NULL,
    p_assigned_to UUID DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
) RETURNS TABLE (
    work_order_id UUID,
    work_order_number VARCHAR(50),
    work_order_title VARCHAR(200),
    work_description TEXT,
    work_category VARCHAR(30),
    work_type VARCHAR(30),
    work_priority VARCHAR(20),
    work_status VARCHAR(20),
    work_phase VARCHAR(30),
    progress_percentage INTEGER,
    building_name VARCHAR(200),
    unit_number VARCHAR(50),
    assigned_to_name VARCHAR(200),
    request_date TIMESTAMP WITH TIME ZONE,
    scheduled_start_date TIMESTAMP WITH TIME ZONE,
    actual_start_date TIMESTAMP WITH TIME ZONE,
    estimated_duration_hours DECIMAL(8,2),
    actual_duration_hours DECIMAL(8,2),
    estimated_cost DECIMAL(12,2),
    actual_cost DECIMAL(12,2),
    total_count BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wo.work_order_id,
        wo.work_order_number,
        wo.work_order_title,
        wo.work_description,
        wo.work_category,
        wo.work_type,
        wo.work_priority,
        wo.work_status,
        wo.work_phase,
        wo.progress_percentage,
        b.building_name,
        u.unit_number,
        COALESCE(up.first_name || ' ' || up.last_name, 'Unassigned') as assigned_to_name,
        wo.request_date,
        wo.scheduled_start_date,
        wo.actual_start_date,
        wo.estimated_duration_hours,
        wo.actual_duration_hours,
        wo.estimated_cost,
        wo.actual_cost,
        COUNT(*) OVER() as total_count
    FROM bms.work_orders wo
    LEFT JOIN bms.buildings b ON wo.building_id = b.building_id
    LEFT JOIN bms.units u ON wo.unit_id = u.unit_id
    LEFT JOIN bms.users up ON wo.assigned_to = up.user_id
    WHERE wo.company_id = p_company_id
        AND (p_building_id IS NULL OR wo.building_id = p_building_id)
        AND (p_unit_id IS NULL OR wo.unit_id = p_unit_id)
        AND (p_work_status IS NULL OR wo.work_status = p_work_status)
        AND (p_work_priority IS NULL OR wo.work_priority = p_work_priority)
        AND (p_work_category IS NULL OR wo.work_category = p_work_category)
        AND (p_assigned_to IS NULL OR wo.assigned_to = p_assigned_to)
        AND (p_date_from IS NULL OR DATE(wo.request_date) >= p_date_from)
        AND (p_date_to IS NULL OR DATE(wo.request_date) <= p_date_to)
    ORDER BY wo.request_date DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;-
- 7. Get work order statistics function
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

-- 8. Complete work order function
CREATE OR REPLACE FUNCTION bms.complete_work_order(
    p_work_order_id UUID,
    p_work_completion_notes TEXT,
    p_quality_rating DECIMAL(3,1) DEFAULT NULL,
    p_actual_cost DECIMAL(12,2) DEFAULT NULL,
    p_follow_up_required BOOLEAN DEFAULT FALSE,
    p_follow_up_date DATE DEFAULT NULL,
    p_follow_up_notes TEXT DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_work_order RECORD;
BEGIN
    -- Get work order information
    SELECT * INTO v_work_order
    FROM bms.work_orders
    WHERE work_order_id = p_work_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work order not found: %', p_work_order_id;
    END IF;
    
    -- Complete work order
    UPDATE bms.work_orders
    SET work_status = 'COMPLETED',
        work_phase = 'COMPLETION',
        progress_percentage = 100,
        actual_end_date = NOW(),
        work_completion_notes = p_work_completion_notes,
        quality_rating = COALESCE(p_quality_rating, quality_rating),
        actual_cost = COALESCE(p_actual_cost, actual_cost),
        follow_up_required = p_follow_up_required,
        follow_up_date = p_follow_up_date,
        follow_up_notes = p_follow_up_notes,
        closed_by = p_completed_by,
        closed_date = NOW(),
        closure_reason = 'COMPLETED',
        updated_by = p_completed_by
    WHERE work_order_id = p_work_order_id;
    
    -- Update related fault report if exists
    IF v_work_order.fault_report_id IS NOT NULL THEN
        UPDATE bms.fault_reports
        SET report_status = 'RESOLVED',
            resolution_status = 'COMPLETED',
            resolved_at = NOW(),
            resolved_by = p_completed_by,
            resolution_description = p_work_completion_notes
        WHERE report_id = v_work_order.fault_report_id;
    END IF;
    
    -- Update assignments
    UPDATE bms.work_order_assignments
    SET assignment_status = 'COMPLETED',
        completed_date = NOW(),
        completed_by = p_completed_by
    WHERE work_order_id = p_work_order_id
        AND assignment_status NOT IN ('COMPLETED', 'CANCELLED');
    
    RETURN TRUE;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.create_work_order IS 'Create a new work order with automatic numbering and template support';
COMMENT ON FUNCTION bms.assign_work_order IS 'Assign work order to technician or contractor with role specification';
COMMENT ON FUNCTION bms.update_work_order_status IS 'Update work order status with automatic timestamp tracking';
COMMENT ON FUNCTION bms.add_work_order_material IS 'Add material requirement to work order with cost calculation';
COMMENT ON FUNCTION bms.record_work_progress IS 'Record work progress with automatic status updates';
COMMENT ON FUNCTION bms.get_work_orders IS 'Get work orders with filtering and pagination';
COMMENT ON FUNCTION bms.get_work_order_statistics IS 'Get comprehensive work order statistics and analytics';
COMMENT ON FUNCTION bms.complete_work_order IS 'Complete work order with quality rating and follow-up planning';

-- Script completion message
SELECT 'Repair work management functions created successfully.' as message;