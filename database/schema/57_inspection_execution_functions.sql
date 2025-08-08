-- =====================================================
-- Inspection Execution Management Functions
-- Phase 4.2.2: Inspection Execution Functions
-- =====================================================

-- 1. Start inspection execution function
CREATE OR REPLACE FUNCTION bms.start_inspection_execution(
    p_company_id UUID,
    p_schedule_id UUID,
    p_primary_inspector_id UUID,
    p_execution_date DATE DEFAULT CURRENT_DATE,
    p_secondary_inspector_id UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_execution_id UUID;
    v_schedule RECORD;
    v_execution_number VARCHAR(50);
BEGIN
    -- Get schedule information
    SELECT 
        ins.*, 
        fa.asset_id,
        it.template_id
    INTO v_schedule
    FROM bms.inspection_schedules ins
    JOIN bms.facility_assets fa ON ins.asset_id = fa.asset_id
    JOIN bms.inspection_templates it ON ins.template_id = it.template_id
    WHERE ins.schedule_id = p_schedule_id 
    AND ins.company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection schedule not found: %', p_schedule_id;
    END IF;
    
    -- Generate execution number
    v_execution_number := 'INS-' || TO_CHAR(p_execution_date, 'YYYYMMDD') || '-' || 
                         LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Create inspection execution
    INSERT INTO bms.inspection_executions (
        company_id,
        schedule_id,
        asset_id,
        template_id,
        execution_number,
        execution_date,
        execution_start_time,
        primary_inspector_id,
        secondary_inspector_id,
        execution_status,
        estimated_duration_hours,
        created_by
    ) VALUES (
        p_company_id,
        p_schedule_id,
        v_schedule.asset_id,
        v_schedule.template_id,
        v_execution_number,
        p_execution_date,
        NOW(),
        p_primary_inspector_id,
        p_secondary_inspector_id,
        'IN_PROGRESS',
        v_schedule.estimated_duration_hours,
        p_created_by
    ) RETURNING execution_id INTO v_execution_id;
    
    RETURN v_execution_id;
END;
$$;

-- 2. Complete inspection execution function
CREATE OR REPLACE FUNCTION bms.complete_inspection_execution(
    p_execution_id UUID,
    p_overall_result VARCHAR(20),
    p_overall_score DECIMAL(5,2) DEFAULT NULL,
    p_pass_fail_result VARCHAR(10) DEFAULT NULL,
    p_inspector_notes TEXT DEFAULT NULL,
    p_recommendations TEXT DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_execution RECORD;
    v_duration_minutes INTEGER;
    v_issues_summary RECORD;
BEGIN
    -- Get execution information
    SELECT * INTO v_execution
    FROM bms.inspection_executions
    WHERE execution_id = p_execution_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection execution not found: %', p_execution_id;
    END IF;
    
    -- Calculate actual duration
    v_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_execution.execution_start_time)) / 60;
    
    -- Get issues summary from checklist results
    SELECT 
        COUNT(*) as total_issues,
        COUNT(*) FILTER (WHERE issue_severity = 'CRITICAL') as critical_issues,
        COUNT(*) FILTER (WHERE issue_severity = 'MAJOR') as major_issues,
        COUNT(*) FILTER (WHERE issue_severity = 'MINOR') as minor_issues
    INTO v_issues_summary
    FROM bms.inspection_checklist_results
    WHERE execution_id = p_execution_id
    AND result_status = 'FAIL';
    
    -- Update execution record
    UPDATE bms.inspection_executions
    SET execution_end_time = NOW(),
        actual_duration_minutes = v_duration_minutes,
        execution_status = 'COMPLETED',
        completion_percentage = 100,
        overall_result = p_overall_result,
        overall_score = p_overall_score,
        pass_fail_result = p_pass_fail_result,
        issues_found = COALESCE(v_issues_summary.total_issues, 0),
        critical_issues = COALESCE(v_issues_summary.critical_issues, 0),
        major_issues = COALESCE(v_issues_summary.major_issues, 0),
        minor_issues = COALESCE(v_issues_summary.minor_issues, 0),
        inspector_notes = p_inspector_notes,
        recommendations = p_recommendations,
        updated_at = NOW()
    WHERE execution_id = p_execution_id;
    
    -- Update inspection schedule
    PERFORM bms.update_inspection_schedule_after_completion(
        v_execution.schedule_id,
        v_execution.execution_date,
        p_overall_score
    );
    
    RETURN true;
END;
$$;-- 3. 
Record checklist result function
CREATE OR REPLACE FUNCTION bms.record_checklist_result(
    p_execution_id UUID,
    p_item_sequence INTEGER,
    p_item_description TEXT,
    p_result_status VARCHAR(20),
    p_result_value VARCHAR(200) DEFAULT NULL,
    p_numeric_value DECIMAL(15,4) DEFAULT NULL,
    p_issue_severity VARCHAR(20) DEFAULT NULL,
    p_issue_description TEXT DEFAULT NULL,
    p_inspected_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_result_id UUID;
    v_execution RECORD;
    v_pass_fail VARCHAR(10);
BEGIN
    -- Get execution information
    SELECT * INTO v_execution
    FROM bms.inspection_executions
    WHERE execution_id = p_execution_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection execution not found: %', p_execution_id;
    END IF;
    
    -- Determine pass/fail based on result status
    v_pass_fail := CASE p_result_status
        WHEN 'PASS' THEN 'PASS'
        WHEN 'FAIL' THEN 'FAIL'
        WHEN 'NOT_APPLICABLE' THEN 'N/A'
        ELSE NULL
    END;
    
    -- Insert checklist result
    INSERT INTO bms.inspection_checklist_results (
        company_id,
        execution_id,
        item_sequence,
        item_description,
        result_status,
        result_value,
        numeric_value,
        pass_fail,
        issue_severity,
        issue_description,
        inspected_by,
        inspection_time
    ) VALUES (
        v_execution.company_id,
        p_execution_id,
        p_item_sequence,
        p_item_description,
        p_result_status,
        p_result_value,
        p_numeric_value,
        v_pass_fail,
        p_issue_severity,
        p_issue_description,
        p_inspected_by,
        NOW()
    ) RETURNING result_id INTO v_result_id;
    
    -- Create finding if result is FAIL and has issue description
    IF p_result_status = 'FAIL' AND p_issue_description IS NOT NULL THEN
        PERFORM bms.create_inspection_finding(
            v_execution.company_id,
            p_execution_id,
            v_result_id,
            'DEFECT',
            'OPERATIONAL',
            'Checklist Item Failure: ' || p_item_description,
            p_issue_description,
            COALESCE(p_issue_severity, 'MEDIUM'),
            p_inspected_by
        );
    END IF;
    
    RETURN v_result_id;
END;
$$;

-- 4. Create inspection finding function
CREATE OR REPLACE FUNCTION bms.create_inspection_finding(
    p_company_id UUID,
    p_execution_id UUID,
    p_checklist_result_id UUID DEFAULT NULL,
    p_finding_type VARCHAR(30),
    p_finding_category VARCHAR(30),
    p_finding_title VARCHAR(200),
    p_finding_description TEXT,
    p_severity_level VARCHAR(20),
    p_identified_by UUID DEFAULT NULL,
    p_corrective_action_deadline DATE DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_finding_id UUID;
    v_finding_number VARCHAR(50);
    v_priority_level VARCHAR(20);
    v_execution RECORD;
BEGIN
    -- Get execution information
    SELECT * INTO v_execution
    FROM bms.inspection_executions
    WHERE execution_id = p_execution_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection execution not found: %', p_execution_id;
    END IF;
    
    -- Generate finding number
    v_finding_number := 'FND-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Determine priority based on severity
    v_priority_level := CASE p_severity_level
        WHEN 'CRITICAL' THEN 'URGENT'
        WHEN 'HIGH' THEN 'HIGH'
        WHEN 'MEDIUM' THEN 'MEDIUM'
        WHEN 'LOW' THEN 'LOW'
        ELSE 'MEDIUM'
    END;
    
    -- Set default deadline if not provided
    IF p_corrective_action_deadline IS NULL THEN
        p_corrective_action_deadline := CASE p_severity_level
            WHEN 'CRITICAL' THEN CURRENT_DATE + INTERVAL '1 day'
            WHEN 'HIGH' THEN CURRENT_DATE + INTERVAL '7 days'
            WHEN 'MEDIUM' THEN CURRENT_DATE + INTERVAL '30 days'
            ELSE CURRENT_DATE + INTERVAL '90 days'
        END;
    END IF;
    
    -- Create inspection finding
    INSERT INTO bms.inspection_findings (
        company_id,
        execution_id,
        checklist_result_id,
        finding_number,
        finding_type,
        finding_category,
        finding_title,
        finding_description,
        severity_level,
        priority_level,
        corrective_action_deadline,
        identified_by,
        identified_date
    ) VALUES (
        p_company_id,
        p_execution_id,
        p_checklist_result_id,
        v_finding_number,
        p_finding_type,
        p_finding_category,
        p_finding_title,
        p_finding_description,
        p_severity_level,
        v_priority_level,
        p_corrective_action_deadline,
        p_identified_by,
        NOW()
    ) RETURNING finding_id INTO v_finding_id;
    
    RETURN v_finding_id;
END;
$$;-
- 5. Create corrective action function
CREATE OR REPLACE FUNCTION bms.create_corrective_action(
    p_finding_id UUID,
    p_action_type VARCHAR(30),
    p_action_title VARCHAR(200),
    p_action_description TEXT,
    p_action_priority VARCHAR(20),
    p_estimated_cost DECIMAL(12,2) DEFAULT 0,
    p_planned_completion_date DATE DEFAULT NULL,
    p_assigned_to UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_action_id UUID;
    v_action_number VARCHAR(50);
    v_finding RECORD;
BEGIN
    -- Get finding information
    SELECT * INTO v_finding
    FROM bms.inspection_findings
    WHERE finding_id = p_finding_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Inspection finding not found: %', p_finding_id;
    END IF;
    
    -- Generate action number
    v_action_number := 'ACT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                      LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Set default completion date if not provided
    IF p_planned_completion_date IS NULL THEN
        p_planned_completion_date := CASE p_action_priority
            WHEN 'IMMEDIATE' THEN CURRENT_DATE + INTERVAL '1 day'
            WHEN 'URGENT' THEN CURRENT_DATE + INTERVAL '7 days'
            WHEN 'HIGH' THEN CURRENT_DATE + INTERVAL '14 days'
            WHEN 'MEDIUM' THEN CURRENT_DATE + INTERVAL '30 days'
            ELSE CURRENT_DATE + INTERVAL '60 days'
        END;
    END IF;
    
    -- Create corrective action
    INSERT INTO bms.inspection_corrective_actions (
        company_id,
        finding_id,
        action_number,
        action_type,
        action_title,
        action_description,
        action_priority,
        estimated_cost,
        planned_completion_date,
        assigned_to,
        created_by
    ) VALUES (
        v_finding.company_id,
        p_finding_id,
        v_action_number,
        p_action_type,
        p_action_title,
        p_action_description,
        p_action_priority,
        p_estimated_cost,
        p_planned_completion_date,
        p_assigned_to,
        p_created_by
    ) RETURNING action_id INTO v_action_id;
    
    RETURN v_action_id;
END;
$$;

-- 6. Inspection execution dashboard view
CREATE OR REPLACE VIEW bms.v_inspection_execution_dashboard AS
SELECT 
    ie.company_id,
    
    -- Execution counts by status
    COUNT(*) as total_executions,
    COUNT(*) FILTER (WHERE ie.execution_status = 'SCHEDULED') as scheduled_executions,
    COUNT(*) FILTER (WHERE ie.execution_status = 'IN_PROGRESS') as in_progress_executions,
    COUNT(*) FILTER (WHERE ie.execution_status = 'COMPLETED') as completed_executions,
    COUNT(*) FILTER (WHERE ie.execution_status = 'CANCELLED') as cancelled_executions,
    
    -- Results analysis
    COUNT(*) FILTER (WHERE ie.pass_fail_result = 'PASS') as passed_inspections,
    COUNT(*) FILTER (WHERE ie.pass_fail_result = 'FAIL') as failed_inspections,
    COUNT(*) FILTER (WHERE ie.pass_fail_result = 'CONDITIONAL') as conditional_inspections,
    
    -- Performance metrics
    AVG(ie.overall_score) FILTER (WHERE ie.overall_score IS NOT NULL) as avg_overall_score,
    AVG(ie.actual_duration_minutes) FILTER (WHERE ie.actual_duration_minutes IS NOT NULL) as avg_duration_minutes,
    
    -- Issues summary
    SUM(ie.issues_found) as total_issues_found,
    SUM(ie.critical_issues) as total_critical_issues,
    SUM(ie.major_issues) as total_major_issues,
    SUM(ie.minor_issues) as total_minor_issues,
    
    -- Findings and actions
    COUNT(if_data.finding_id) as total_findings,
    COUNT(if_data.finding_id) FILTER (WHERE if_data.finding_status = 'OPEN') as open_findings,
    COUNT(ica_data.action_id) as total_corrective_actions,
    COUNT(ica_data.action_id) FILTER (WHERE ica_data.action_status = 'COMPLETED') as completed_actions,
    
    -- Cost analysis
    SUM(ie.execution_cost) as total_execution_cost,
    AVG(ie.execution_cost) as avg_execution_cost,
    
    -- Time analysis
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', ie.execution_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_executions,
    COUNT(*) FILTER (WHERE DATE_TRUNC('week', ie.execution_date) = DATE_TRUNC('week', CURRENT_DATE)) as this_week_executions,
    
    -- Latest activity
    MAX(ie.updated_at) as last_updated_at
    
FROM bms.inspection_executions ie
LEFT JOIN bms.inspection_findings if_data ON ie.execution_id = if_data.execution_id
LEFT JOIN bms.inspection_corrective_actions ica_data ON if_data.finding_id = ica_data.finding_id
GROUP BY ie.company_id;

-- 7. Active inspection findings view
CREATE OR REPLACE VIEW bms.v_active_inspection_findings AS
SELECT 
    if_main.finding_id,
    if_main.company_id,
    if_main.execution_id,
    ie.execution_number,
    ie.execution_date,
    fa.asset_code,
    fa.asset_name,
    
    -- Finding details
    if_main.finding_number,
    if_main.finding_type,
    if_main.finding_category,
    if_main.finding_title,
    if_main.finding_description,
    if_main.severity_level,
    if_main.priority_level,
    if_main.finding_status,
    
    -- Impact assessment
    if_main.safety_impact,
    if_main.operational_impact,
    if_main.financial_impact_estimate,
    
    -- Action tracking
    if_main.corrective_action_required,
    if_main.corrective_action_deadline,
    if_main.assigned_to,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    
    -- Time analysis
    if_main.corrective_action_deadline - CURRENT_DATE as days_until_deadline,
    CASE 
        WHEN if_main.corrective_action_deadline < CURRENT_DATE THEN 'OVERDUE'
        WHEN if_main.corrective_action_deadline <= CURRENT_DATE + INTERVAL '7 days' THEN 'DUE_SOON'
        WHEN if_main.corrective_action_deadline <= CURRENT_DATE + INTERVAL '30 days' THEN 'DUE_THIS_MONTH'
        ELSE 'FUTURE'
    END as deadline_status,
    
    -- Priority scoring for sorting
    CASE if_main.priority_level
        WHEN 'URGENT' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END as priority_score,
    
    -- Corrective actions summary
    COUNT(ica.action_id) as total_actions,
    COUNT(ica.action_id) FILTER (WHERE ica.action_status = 'COMPLETED') as completed_actions,
    
    if_main.identified_date,
    if_main.created_at,
    if_main.updated_at
    
FROM bms.inspection_findings if_main
JOIN bms.inspection_executions ie ON if_main.execution_id = ie.execution_id
JOIN bms.facility_assets fa ON ie.asset_id = fa.asset_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
LEFT JOIN bms.inspection_corrective_actions ica ON if_main.finding_id = ica.finding_id
WHERE if_main.finding_status IN ('OPEN', 'IN_PROGRESS')
GROUP BY 
    if_main.finding_id, if_main.company_id, if_main.execution_id, ie.execution_number, ie.execution_date,
    fa.asset_code, fa.asset_name, if_main.finding_number, if_main.finding_type, if_main.finding_category,
    if_main.finding_title, if_main.finding_description, if_main.severity_level, if_main.priority_level,
    if_main.finding_status, if_main.safety_impact, if_main.operational_impact, if_main.financial_impact_estimate,
    if_main.corrective_action_required, if_main.corrective_action_deadline, if_main.assigned_to,
    b.name, u.unit_number, if_main.identified_date, if_main.created_at, if_main.updated_at
ORDER BY priority_score ASC, if_main.corrective_action_deadline ASC;

-- Script completion message
SELECT 'Inspection execution management functions and views created successfully.' as message;