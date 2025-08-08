-- =====================================================
-- Inspection and Maintenance Planning Functions
-- Phase 4.2.1: Inspection and Maintenance Planning Functions
-- =====================================================

-- 1. Create inspection schedule function
CREATE OR REPLACE FUNCTION bms.create_inspection_schedule(
    p_company_id UUID,
    p_asset_id UUID,
    p_template_id UUID,
    p_schedule_name VARCHAR(200),
    p_frequency_type VARCHAR(20) DEFAULT 'MONTHLY',
    p_frequency_interval INTEGER DEFAULT 1,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_assigned_inspector_id UUID DEFAULT NULL,
    p_priority_level VARCHAR(20) DEFAULT 'MEDIUM',
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_schedule_id UUID;
    v_template RECORD;
    v_next_due_date DATE;
    v_frequency_unit VARCHAR(20);
BEGIN
    -- Get template information
    SELECT * INTO v_template
    FROM bms.inspection_templates
    WHERE template_id = p_template_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection template not found: %', p_template_id;
    END IF;
    
    -- Calculate frequency unit and next due date
    CASE p_frequency_type
        WHEN 'DAILY' THEN 
            v_frequency_unit := 'DAYS';
            v_next_due_date := p_start_date + (p_frequency_interval || ' days')::INTERVAL;
        WHEN 'WEEKLY' THEN 
            v_frequency_unit := 'WEEKS';
            v_next_due_date := p_start_date + (p_frequency_interval || ' weeks')::INTERVAL;
        WHEN 'MONTHLY' THEN 
            v_frequency_unit := 'MONTHS';
            v_next_due_date := p_start_date + (p_frequency_interval || ' months')::INTERVAL;
        WHEN 'QUARTERLY' THEN 
            v_frequency_unit := 'MONTHS';
            v_next_due_date := p_start_date + (p_frequency_interval * 3 || ' months')::INTERVAL;
        WHEN 'SEMI_ANNUAL' THEN 
            v_frequency_unit := 'MONTHS';
            v_next_due_date := p_start_date + (p_frequency_interval * 6 || ' months')::INTERVAL;
        WHEN 'ANNUAL' THEN 
            v_frequency_unit := 'YEARS';
            v_next_due_date := p_start_date + (p_frequency_interval || ' years')::INTERVAL;
        ELSE 
            v_frequency_unit := 'MONTHS';
            v_next_due_date := p_start_date + INTERVAL '1 month';
    END CASE;
    
    -- Create inspection schedule
    INSERT INTO bms.inspection_schedules (
        company_id,
        asset_id,
        template_id,
        schedule_name,
        frequency_type,
        frequency_interval,
        frequency_unit,
        start_date,
        next_due_date,
        estimated_duration_hours,
        assigned_inspector_id,
        priority_level,
        created_by
    ) VALUES (
        p_company_id,
        p_asset_id,
        p_template_id,
        p_schedule_name,
        p_frequency_type,
        p_frequency_interval,
        v_frequency_unit,
        p_start_date,
        v_next_due_date,
        v_template.default_duration_hours,
        p_assigned_inspector_id,
        p_priority_level,
        p_created_by
    ) RETURNING schedule_id INTO v_schedule_id;
    
    RETURN v_schedule_id;
END;
$$;

-- 2. Create maintenance plan function
CREATE OR REPLACE FUNCTION bms.create_maintenance_plan(
    p_company_id UUID,
    p_asset_id UUID,
    p_plan_name VARCHAR(200),
    p_plan_type VARCHAR(30),
    p_maintenance_strategy VARCHAR(30),
    p_frequency_type VARCHAR(20),
    p_frequency_interval INTEGER DEFAULT 1,
    p_estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    p_estimated_cost DECIMAL(12,2) DEFAULT 0,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_plan_id UUID;
    v_plan_code VARCHAR(50);
    v_asset RECORD;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Generate plan code
    v_plan_code := 'MP-' || v_asset.asset_code || '-' || TO_CHAR(NOW(), 'YYYYMMDD');
    
    -- Create maintenance plan
    INSERT INTO bms.maintenance_plans (
        company_id,
        asset_id,
        plan_name,
        plan_code,
        plan_type,
        maintenance_strategy,
        maintenance_approach,
        frequency_type,
        frequency_interval,
        estimated_duration_hours,
        estimated_cost,
        created_by
    ) VALUES (
        p_company_id,
        p_asset_id,
        p_plan_name,
        v_plan_code,
        p_plan_type,
        p_maintenance_strategy,
        'IN_HOUSE', -- default approach
        p_frequency_type,
        p_frequency_interval,
        p_estimated_duration_hours,
        p_estimated_cost,
        p_created_by
    ) RETURNING plan_id INTO v_plan_id;
    
    RETURN v_plan_id;
END;
$$;-- 
3. Add maintenance task function
CREATE OR REPLACE FUNCTION bms.add_maintenance_task(
    p_plan_id UUID,
    p_task_name VARCHAR(200),
    p_task_type VARCHAR(30),
    p_task_description TEXT DEFAULT NULL,
    p_task_instructions TEXT DEFAULT NULL,
    p_estimated_duration_minutes INTEGER DEFAULT 0,
    p_required_skill_level VARCHAR(20) DEFAULT 'BASIC',
    p_is_critical BOOLEAN DEFAULT false,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_task_id UUID;
    v_plan RECORD;
    v_next_sequence INTEGER;
BEGIN
    -- Get plan information
    SELECT * INTO v_plan
    FROM bms.maintenance_plans
    WHERE plan_id = p_plan_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Maintenance plan not found: %', p_plan_id;
    END IF;
    
    -- Get next sequence number
    SELECT COALESCE(MAX(task_sequence), 0) + 1 INTO v_next_sequence
    FROM bms.maintenance_tasks
    WHERE plan_id = p_plan_id;
    
    -- Create maintenance task
    INSERT INTO bms.maintenance_tasks (
        company_id,
        plan_id,
        task_sequence,
        task_name,
        task_description,
        task_type,
        task_instructions,
        estimated_duration_minutes,
        required_skill_level,
        is_critical,
        created_by
    ) VALUES (
        v_plan.company_id,
        p_plan_id,
        v_next_sequence,
        p_task_name,
        p_task_description,
        p_task_type,
        p_task_instructions,
        p_estimated_duration_minutes,
        p_required_skill_level,
        p_is_critical,
        p_created_by
    ) RETURNING task_id INTO v_task_id;
    
    RETURN v_task_id;
END;
$$;

-- 4. Generate due inspections function
CREATE OR REPLACE FUNCTION bms.generate_due_inspections(
    p_company_id UUID,
    p_days_ahead INTEGER DEFAULT 30
) RETURNS TABLE (
    generated_count INTEGER,
    inspection_details JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_schedule RECORD;
    v_generated_count INTEGER := 0;
    v_inspection_details JSONB := '[]'::jsonb;
    v_inspection_info JSONB;
BEGIN
    -- Find inspection schedules that are due
    FOR v_schedule IN
        SELECT 
            ins.schedule_id,
            ins.schedule_name,
            ins.next_due_date,
            ins.priority_level,
            ins.assigned_inspector_id,
            fa.asset_name,
            fa.asset_code,
            it.template_name,
            b.name as building_name,
            u.unit_number
        FROM bms.inspection_schedules ins
        JOIN bms.facility_assets fa ON ins.asset_id = fa.asset_id
        JOIN bms.inspection_templates it ON ins.template_id = it.template_id
        LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
        LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
        WHERE ins.company_id = p_company_id
        AND ins.schedule_status = 'ACTIVE'
        AND ins.next_due_date <= CURRENT_DATE + (p_days_ahead || ' days')::INTERVAL
        ORDER BY ins.next_due_date ASC, ins.priority_level ASC
    LOOP
        v_generated_count := v_generated_count + 1;
        
        -- Build inspection details
        v_inspection_info := jsonb_build_object(
            'schedule_id', v_schedule.schedule_id,
            'schedule_name', v_schedule.schedule_name,
            'asset_name', v_schedule.asset_name,
            'asset_code', v_schedule.asset_code,
            'template_name', v_schedule.template_name,
            'building_name', v_schedule.building_name,
            'unit_number', v_schedule.unit_number,
            'due_date', v_schedule.next_due_date,
            'priority_level', v_schedule.priority_level,
            'assigned_inspector_id', v_schedule.assigned_inspector_id,
            'days_until_due', v_schedule.next_due_date - CURRENT_DATE
        );
        
        v_inspection_details := v_inspection_details || v_inspection_info;
    END LOOP;
    
    RETURN QUERY SELECT v_generated_count, v_inspection_details;
END;
$$;

-- 5. Update inspection schedule after completion function
CREATE OR REPLACE FUNCTION bms.update_inspection_schedule_after_completion(
    p_schedule_id UUID,
    p_completion_date DATE DEFAULT CURRENT_DATE,
    p_score DECIMAL(5,2) DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_schedule RECORD;
    v_next_due_date DATE;
BEGIN
    -- Get schedule information
    SELECT * INTO v_schedule
    FROM bms.inspection_schedules
    WHERE schedule_id = p_schedule_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Calculate next due date
    CASE v_schedule.frequency_type
        WHEN 'DAILY' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval || ' days')::INTERVAL;
        WHEN 'WEEKLY' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval || ' weeks')::INTERVAL;
        WHEN 'MONTHLY' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval || ' months')::INTERVAL;
        WHEN 'QUARTERLY' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval * 3 || ' months')::INTERVAL;
        WHEN 'SEMI_ANNUAL' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval * 6 || ' months')::INTERVAL;
        WHEN 'ANNUAL' THEN 
            v_next_due_date := p_completion_date + (v_schedule.frequency_interval || ' years')::INTERVAL;
        ELSE 
            v_next_due_date := p_completion_date + INTERVAL '1 month';
    END CASE;
    
    -- Update schedule
    UPDATE bms.inspection_schedules
    SET last_completed_date = p_completion_date,
        next_due_date = v_next_due_date,
        last_score = COALESCE(p_score, last_score),
        average_score = CASE 
            WHEN p_score IS NOT NULL THEN 
                CASE 
                    WHEN average_score = 0 THEN p_score
                    ELSE (average_score + p_score) / 2
                END
            ELSE average_score
        END,
        compliance_status = CASE 
            WHEN p_completion_date <= v_schedule.next_due_date THEN 'COMPLIANT'
            ELSE 'OVERDUE'
        END,
        updated_at = NOW()
    WHERE schedule_id = p_schedule_id;
    
    RETURN true;
END;
$$;-
- 6. Inspection schedule dashboard view
CREATE OR REPLACE VIEW bms.v_inspection_schedule_dashboard AS
SELECT 
    ins.company_id,
    
    -- Schedule counts by status
    COUNT(*) as total_schedules,
    COUNT(*) FILTER (WHERE ins.schedule_status = 'ACTIVE') as active_schedules,
    COUNT(*) FILTER (WHERE ins.schedule_status = 'INACTIVE') as inactive_schedules,
    COUNT(*) FILTER (WHERE ins.schedule_status = 'SUSPENDED') as suspended_schedules,
    
    -- Compliance status
    COUNT(*) FILTER (WHERE ins.compliance_status = 'COMPLIANT') as compliant_schedules,
    COUNT(*) FILTER (WHERE ins.compliance_status = 'NON_COMPLIANT') as non_compliant_schedules,
    COUNT(*) FILTER (WHERE ins.compliance_status = 'OVERDUE') as overdue_schedules,
    
    -- Due analysis
    COUNT(*) FILTER (WHERE ins.next_due_date <= CURRENT_DATE) as due_today,
    COUNT(*) FILTER (WHERE ins.next_due_date <= CURRENT_DATE + INTERVAL '7 days') as due_this_week,
    COUNT(*) FILTER (WHERE ins.next_due_date <= CURRENT_DATE + INTERVAL '30 days') as due_this_month,
    COUNT(*) FILTER (WHERE ins.next_due_date < CURRENT_DATE) as overdue_count,
    
    -- Priority breakdown
    COUNT(*) FILTER (WHERE ins.priority_level = 'CRITICAL') as critical_priority,
    COUNT(*) FILTER (WHERE ins.priority_level = 'HIGH') as high_priority,
    COUNT(*) FILTER (WHERE ins.priority_level = 'MEDIUM') as medium_priority,
    COUNT(*) FILTER (WHERE ins.priority_level = 'LOW') as low_priority,
    
    -- Performance metrics
    AVG(ins.completion_rate) as avg_completion_rate,
    AVG(ins.average_score) FILTER (WHERE ins.average_score > 0) as avg_inspection_score,
    
    -- Frequency analysis
    COUNT(*) FILTER (WHERE ins.frequency_type = 'DAILY') as daily_inspections,
    COUNT(*) FILTER (WHERE ins.frequency_type = 'WEEKLY') as weekly_inspections,
    COUNT(*) FILTER (WHERE ins.frequency_type = 'MONTHLY') as monthly_inspections,
    COUNT(*) FILTER (WHERE ins.frequency_type = 'QUARTERLY') as quarterly_inspections,
    COUNT(*) FILTER (WHERE ins.frequency_type = 'ANNUAL') as annual_inspections,
    
    -- Cost and time estimates
    SUM(ins.estimated_cost) as total_estimated_cost,
    SUM(ins.estimated_duration_hours) as total_estimated_hours,
    AVG(ins.estimated_duration_hours) as avg_duration_hours,
    
    -- Recent activity
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', ins.last_completed_date) = DATE_TRUNC('month', CURRENT_DATE)) as completed_this_month,
    
    -- Latest updates
    MAX(ins.updated_at) as last_updated_at
    
FROM bms.inspection_schedules ins
GROUP BY ins.company_id;

-- 7. Due inspections view
CREATE OR REPLACE VIEW bms.v_due_inspections AS
SELECT 
    ins.schedule_id,
    ins.company_id,
    ins.asset_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_type,
    
    -- Schedule information
    ins.schedule_name,
    ins.next_due_date,
    ins.priority_level,
    ins.criticality_level,
    ins.compliance_status,
    
    -- Template information
    it.template_name,
    it.template_type,
    it.is_mandatory,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    fa.location_description,
    
    -- Assignment
    ins.assigned_inspector_id,
    ins.estimated_duration_hours,
    ins.estimated_cost,
    
    -- Timing analysis
    ins.next_due_date - CURRENT_DATE as days_until_due,
    CASE 
        WHEN ins.next_due_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN ins.next_due_date <= CURRENT_DATE + INTERVAL '1 day' THEN 'DUE_TODAY'
        WHEN ins.next_due_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'DUE_THIS_WEEK'
        WHEN ins.next_due_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'DUE_THIS_MONTH'
        ELSE 'FUTURE'
    END as due_status,
    
    -- Priority scoring for sorting
    CASE ins.priority_level
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END as priority_score,
    
    -- Last completion info
    ins.last_completed_date,
    ins.last_score,
    ins.average_score,
    
    ins.created_at,
    ins.updated_at
    
FROM bms.inspection_schedules ins
JOIN bms.facility_assets fa ON ins.asset_id = fa.asset_id
JOIN bms.inspection_templates it ON ins.template_id = it.template_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
WHERE ins.schedule_status = 'ACTIVE'
AND ins.next_due_date <= CURRENT_DATE + INTERVAL '90 days'
ORDER BY priority_score ASC, ins.next_due_date ASC;

-- 8. Maintenance plan summary view
CREATE OR REPLACE VIEW bms.v_maintenance_plan_summary AS
SELECT 
    mp.plan_id,
    mp.company_id,
    mp.asset_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_type,
    
    -- Plan information
    mp.plan_name,
    mp.plan_code,
    mp.plan_type,
    mp.maintenance_strategy,
    mp.maintenance_approach,
    mp.plan_status,
    mp.approval_status,
    
    -- Performance targets vs actuals
    mp.target_availability,
    mp.target_reliability,
    mp.target_cost_per_year,
    mp.actual_cost_ytd,
    mp.actual_hours_ytd,
    mp.completion_rate,
    mp.effectiveness_score,
    
    -- Resource planning
    mp.estimated_duration_hours,
    mp.estimated_cost,
    mp.required_downtime_hours,
    
    -- Task summary
    COUNT(mt.task_id) as total_tasks,
    COUNT(mt.task_id) FILTER (WHERE mt.is_critical) as critical_tasks,
    COUNT(mt.task_id) FILTER (WHERE mt.is_active) as active_tasks,
    SUM(mt.estimated_duration_minutes) / 60.0 as total_task_hours,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    
    -- Status indicators
    CASE 
        WHEN mp.approval_status = 'PENDING' THEN 'NEEDS_APPROVAL'
        WHEN mp.plan_status = 'INACTIVE' THEN 'INACTIVE'
        WHEN mp.completion_rate < 50 THEN 'POOR_PERFORMANCE'
        WHEN mp.actual_cost_ytd > mp.target_cost_per_year * 1.2 THEN 'OVER_BUDGET'
        ELSE 'NORMAL'
    END as status_indicator,
    
    mp.effective_date,
    mp.review_date,
    mp.created_at,
    mp.updated_at
    
FROM bms.maintenance_plans mp
JOIN bms.facility_assets fa ON mp.asset_id = fa.asset_id
LEFT JOIN bms.maintenance_tasks mt ON mp.plan_id = mt.plan_id AND mt.is_active = true
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
GROUP BY 
    mp.plan_id, mp.company_id, mp.asset_id, fa.asset_code, fa.asset_name, fa.asset_type,
    mp.plan_name, mp.plan_code, mp.plan_type, mp.maintenance_strategy, mp.maintenance_approach,
    mp.plan_status, mp.approval_status, mp.target_availability, mp.target_reliability,
    mp.target_cost_per_year, mp.actual_cost_ytd, mp.actual_hours_ytd, mp.completion_rate,
    mp.effectiveness_score, mp.estimated_duration_hours, mp.estimated_cost, mp.required_downtime_hours,
    b.name, u.unit_number, mp.effective_date, mp.review_date, mp.created_at, mp.updated_at;

-- Script completion message
SELECT 'Inspection and maintenance planning functions and views created successfully.' as message;