-- =====================================================
-- Fault Reporting System Functions
-- Phase 4.3.1: Fault Reporting System Functions
-- =====================================================

-- 1. Create fault report function
CREATE OR REPLACE FUNCTION bms.create_fault_report(
    p_company_id UUID,
    p_report_title VARCHAR(200),
    p_report_description TEXT,
    p_category_id UUID,
    p_fault_type VARCHAR(30),
    p_fault_severity VARCHAR(20),
    p_reporter_type VARCHAR(20),
    p_reporter_name VARCHAR(100) DEFAULT NULL,
    p_reporter_contact VARCHAR(100) DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_asset_id UUID DEFAULT NULL,
    p_fault_location TEXT DEFAULT NULL,
    p_reported_by_user_id UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_report_id UUID;
    v_report_number VARCHAR(50);
    v_category RECORD;
    v_priority_level VARCHAR(20);
    v_urgency_level VARCHAR(20);
BEGIN
    -- Get category information for default settings
    SELECT * INTO v_category
    FROM bms.fault_categories
    WHERE category_id = p_category_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault category not found: %', p_category_id;
    END IF;
    
    -- Generate report number
    v_report_number := 'FR-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                      LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Determine priority and urgency based on severity and category defaults
    v_priority_level := CASE p_fault_severity
        WHEN 'CATASTROPHIC' THEN 'EMERGENCY'
        WHEN 'CRITICAL' THEN 'URGENT'
        WHEN 'MAJOR' THEN 'HIGH'
        WHEN 'MODERATE' THEN COALESCE(v_category.default_priority, 'MEDIUM')
        ELSE 'LOW'
    END;
    
    v_urgency_level := CASE p_fault_severity
        WHEN 'CATASTROPHIC' THEN 'CRITICAL'
        WHEN 'CRITICAL' THEN 'CRITICAL'
        WHEN 'MAJOR' THEN 'HIGH'
        WHEN 'MODERATE' THEN COALESCE(v_category.default_urgency, 'NORMAL')
        ELSE 'LOW'
    END;
    
    -- Create fault report
    INSERT INTO bms.fault_reports (
        company_id,
        building_id,
        unit_id,
        asset_id,
        category_id,
        report_number,
        report_title,
        report_description,
        reporter_type,
        reporter_name,
        reporter_contact,
        reported_by_user_id,
        fault_type,
        fault_severity,
        fault_location,
        priority_level,
        urgency_level,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_unit_id,
        p_asset_id,
        p_category_id,
        v_report_number,
        p_report_title,
        p_report_description,
        p_reporter_type,
        p_reporter_name,
        p_reporter_contact,
        p_reported_by_user_id,
        p_fault_type,
        p_fault_severity,
        p_fault_location,
        v_priority_level,
        v_urgency_level,
        p_reported_by_user_id
    ) RETURNING report_id INTO v_report_id;
    
    -- Create initial communication record
    INSERT INTO bms.fault_report_communications (
        company_id,
        report_id,
        communication_type,
        communication_direction,
        communication_method,
        sender_type,
        sender_name,
        sender_contact,
        sender_user_id,
        recipient_type,
        subject,
        message_content,
        created_by
    ) VALUES (
        p_company_id,
        v_report_id,
        'INITIAL_REPORT',
        'INBOUND',
        CASE p_reporter_type
            WHEN 'SYSTEM' THEN 'SYSTEM'
            ELSE 'WEB_PORTAL'
        END,
        p_reporter_type,
        p_reporter_name,
        p_reporter_contact,
        p_reported_by_user_id,
        'STAFF',
        'New Fault Report: ' || p_report_title,
        p_report_description,
        p_reported_by_user_id
    );
    
    -- Auto-assign if enabled for this category
    IF v_category.auto_assign_enabled AND v_category.default_assignee_id IS NOT NULL THEN
        PERFORM bms.assign_fault_report(
            v_report_id,
            v_category.default_assignee_id,
            'AUTO_ASSIGNED',
            NULL -- system assignment
        );
    END IF;
    
    RETURN v_report_id;
END;
$$;

-- 2. Assign fault report function
CREATE OR REPLACE FUNCTION bms.assign_fault_report(
    p_report_id UUID,
    p_assigned_to UUID,
    p_assignment_reason VARCHAR(100) DEFAULT 'MANUAL_ASSIGNMENT',
    p_assigned_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_report RECORD;
BEGIN
    -- Get report information
    SELECT * INTO v_report
    FROM bms.fault_reports
    WHERE report_id = p_report_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault report not found: %', p_report_id;
    END IF;
    
    -- Update assignment
    UPDATE bms.fault_reports
    SET assigned_to = p_assigned_to,
        assignment_date = NOW(),
        report_status = CASE 
            WHEN report_status = 'SUBMITTED' THEN 'ASSIGNED'
            ELSE report_status
        END,
        updated_by = p_assigned_by
    WHERE report_id = p_report_id;
    
    -- Create communication record for assignment
    INSERT INTO bms.fault_report_communications (
        company_id,
        report_id,
        communication_type,
        communication_direction,
        communication_method,
        sender_type,
        recipient_type,
        subject,
        message_content,
        created_by
    ) VALUES (
        v_report.company_id,
        p_report_id,
        'STATUS_UPDATE',
        'OUTBOUND',
        'SYSTEM',
        'SYSTEM',
        'STAFF',
        'Fault Report Assigned: ' || v_report.report_title,
        'Report has been assigned. Reason: ' || p_assignment_reason,
        p_assigned_by
    );
    
    RETURN TRUE;
END;
$$;-- 3.
 Update fault report status function
CREATE OR REPLACE FUNCTION bms.update_fault_report_status(
    p_report_id UUID,
    p_new_status VARCHAR(20),
    p_resolution_status VARCHAR(20) DEFAULT NULL,
    p_status_notes TEXT DEFAULT NULL,
    p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_report RECORD;
    v_old_status VARCHAR(20);
BEGIN
    -- Get current report information
    SELECT * INTO v_report
    FROM bms.fault_reports
    WHERE report_id = p_report_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault report not found: %', p_report_id;
    END IF;
    
    v_old_status := v_report.report_status;
    
    -- Update status
    UPDATE bms.fault_reports
    SET report_status = p_new_status,
        resolution_status = COALESCE(p_resolution_status, resolution_status),
        acknowledged_at = CASE 
            WHEN p_new_status = 'ACKNOWLEDGED' AND acknowledged_at IS NULL 
            THEN NOW() 
            ELSE acknowledged_at 
        END,
        acknowledged_by = CASE 
            WHEN p_new_status = 'ACKNOWLEDGED' AND acknowledged_by IS NULL 
            THEN p_updated_by 
            ELSE acknowledged_by 
        END,
        response_started_at = CASE 
            WHEN p_new_status = 'IN_PROGRESS' AND response_started_at IS NULL 
            THEN NOW() 
            ELSE response_started_at 
        END,
        resolved_at = CASE 
            WHEN p_new_status = 'RESOLVED' AND resolved_at IS NULL 
            THEN NOW() 
            ELSE resolved_at 
        END,
        resolved_by = CASE 
            WHEN p_new_status = 'RESOLVED' AND resolved_by IS NULL 
            THEN p_updated_by 
            ELSE resolved_by 
        END,
        updated_by = p_updated_by
    WHERE report_id = p_report_id;
    
    -- Create communication record for status change
    INSERT INTO bms.fault_report_communications (
        company_id,
        report_id,
        communication_type,
        communication_direction,
        communication_method,
        sender_type,
        recipient_type,
        subject,
        message_content,
        created_by
    ) VALUES (
        v_report.company_id,
        p_report_id,
        'STATUS_UPDATE',
        'OUTBOUND',
        'SYSTEM',
        'SYSTEM',
        v_report.reporter_type,
        'Status Update: ' || v_report.report_title,
        'Status changed from ' || v_old_status || ' to ' || p_new_status || 
        CASE WHEN p_status_notes IS NOT NULL THEN '. Notes: ' || p_status_notes ELSE '' END,
        p_updated_by
    );
    
    RETURN TRUE;
END;
$$;

-- 4. Add communication to fault report function
CREATE OR REPLACE FUNCTION bms.add_fault_report_communication(
    p_report_id UUID,
    p_communication_type VARCHAR(20),
    p_communication_direction VARCHAR(10),
    p_communication_method VARCHAR(20),
    p_sender_type VARCHAR(20),
    p_sender_name VARCHAR(100) DEFAULT NULL,
    p_sender_contact VARCHAR(100) DEFAULT NULL,
    p_sender_user_id UUID DEFAULT NULL,
    p_recipient_type VARCHAR(20),
    p_recipient_name VARCHAR(100) DEFAULT NULL,
    p_recipient_contact VARCHAR(100) DEFAULT NULL,
    p_recipient_user_id UUID DEFAULT NULL,
    p_subject VARCHAR(200) DEFAULT NULL,
    p_message_content TEXT,
    p_requires_response BOOLEAN DEFAULT FALSE,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_communication_id UUID;
    v_report RECORD;
BEGIN
    -- Get report information
    SELECT * INTO v_report
    FROM bms.fault_reports
    WHERE report_id = p_report_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault report not found: %', p_report_id;
    END IF;
    
    -- Create communication record
    INSERT INTO bms.fault_report_communications (
        company_id,
        report_id,
        communication_type,
        communication_direction,
        communication_method,
        sender_type,
        sender_name,
        sender_contact,
        sender_user_id,
        recipient_type,
        recipient_name,
        recipient_contact,
        recipient_user_id,
        subject,
        message_content,
        requires_response,
        created_by
    ) VALUES (
        v_report.company_id,
        p_report_id,
        p_communication_type,
        p_communication_direction,
        p_communication_method,
        p_sender_type,
        p_sender_name,
        p_sender_contact,
        p_sender_user_id,
        p_recipient_type,
        p_recipient_name,
        p_recipient_contact,
        p_recipient_user_id,
        p_subject,
        p_message_content,
        p_requires_response,
        p_created_by
    ) RETURNING communication_id INTO v_communication_id;
    
    RETURN v_communication_id;
END;
$$;

-- 5. Submit fault report feedback function
CREATE OR REPLACE FUNCTION bms.submit_fault_report_feedback(
    p_report_id UUID,
    p_feedback_provider_type VARCHAR(20),
    p_feedback_provider_name VARCHAR(100) DEFAULT NULL,
    p_feedback_provider_contact VARCHAR(100) DEFAULT NULL,
    p_feedback_provider_user_id UUID DEFAULT NULL,
    p_feedback_type VARCHAR(20),
    p_feedback_category VARCHAR(30),
    p_overall_satisfaction DECIMAL(3,1) DEFAULT NULL,
    p_response_time_rating DECIMAL(3,1) DEFAULT NULL,
    p_communication_quality_rating DECIMAL(3,1) DEFAULT NULL,
    p_resolution_quality_rating DECIMAL(3,1) DEFAULT NULL,
    p_staff_professionalism_rating DECIMAL(3,1) DEFAULT NULL,
    p_positive_aspects TEXT DEFAULT NULL,
    p_areas_for_improvement TEXT DEFAULT NULL,
    p_additional_comments TEXT DEFAULT NULL,
    p_would_recommend BOOLEAN DEFAULT NULL,
    p_issue_fully_resolved BOOLEAN DEFAULT NULL,
    p_resolution_met_expectations BOOLEAN DEFAULT NULL,
    p_submission_method VARCHAR(20) DEFAULT 'WEB_PORTAL'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_feedback_id UUID;
    v_report RECORD;
BEGIN
    -- Get report information
    SELECT * INTO v_report
    FROM bms.fault_reports
    WHERE report_id = p_report_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault report not found: %', p_report_id;
    END IF;
    
    -- Create feedback record
    INSERT INTO bms.fault_report_feedback (
        company_id,
        report_id,
        feedback_provider_type,
        feedback_provider_name,
        feedback_provider_contact,
        feedback_provider_user_id,
        feedback_type,
        feedback_category,
        overall_satisfaction,
        response_time_rating,
        communication_quality_rating,
        resolution_quality_rating,
        staff_professionalism_rating,
        positive_aspects,
        areas_for_improvement,
        additional_comments,
        would_recommend,
        issue_fully_resolved,
        resolution_met_expectations,
        submission_method
    ) VALUES (
        v_report.company_id,
        p_report_id,
        p_feedback_provider_type,
        p_feedback_provider_name,
        p_feedback_provider_contact,
        p_feedback_provider_user_id,
        p_feedback_type,
        p_feedback_category,
        p_overall_satisfaction,
        p_response_time_rating,
        p_communication_quality_rating,
        p_resolution_quality_rating,
        p_staff_professionalism_rating,
        p_positive_aspects,
        p_areas_for_improvement,
        p_additional_comments,
        p_would_recommend,
        p_issue_fully_resolved,
        p_resolution_met_expectations,
        p_submission_method
    ) RETURNING feedback_id INTO v_feedback_id;
    
    -- Update report with feedback ratings
    UPDATE bms.fault_reports
    SET reporter_satisfaction_rating = COALESCE(p_overall_satisfaction, reporter_satisfaction_rating),
        resolution_quality_rating = COALESCE(p_resolution_quality_rating, resolution_quality_rating)
    WHERE report_id = p_report_id;
    
    RETURN v_feedback_id;
END;
$$;-- 6. G
et fault reports with filters function
CREATE OR REPLACE FUNCTION bms.get_fault_reports(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_category_id UUID DEFAULT NULL,
    p_status VARCHAR(20) DEFAULT NULL,
    p_priority VARCHAR(20) DEFAULT NULL,
    p_assigned_to UUID DEFAULT NULL,
    p_reporter_type VARCHAR(20) DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    report_id UUID,
    report_number VARCHAR(50),
    report_title VARCHAR(200),
    report_description TEXT,
    fault_type VARCHAR(30),
    fault_severity VARCHAR(20),
    priority_level VARCHAR(20),
    urgency_level VARCHAR(20),
    report_status VARCHAR(20),
    resolution_status VARCHAR(20),
    reporter_type VARCHAR(20),
    reporter_name VARCHAR(100),
    reporter_contact VARCHAR(100),
    building_name VARCHAR(200),
    unit_number VARCHAR(50),
    category_name VARCHAR(100),
    assigned_to_name VARCHAR(200),
    reported_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    response_time_hours DECIMAL(8,2),
    resolution_time_hours DECIMAL(8,2),
    reporter_satisfaction_rating DECIMAL(3,1),
    total_count BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fr.report_id,
        fr.report_number,
        fr.report_title,
        fr.report_description,
        fr.fault_type,
        fr.fault_severity,
        fr.priority_level,
        fr.urgency_level,
        fr.report_status,
        fr.resolution_status,
        fr.reporter_type,
        fr.reporter_name,
        fr.reporter_contact,
        b.building_name,
        u.unit_number,
        fc.category_name,
        COALESCE(up.first_name || ' ' || up.last_name, 'Unassigned') as assigned_to_name,
        fr.reported_at,
        fr.resolved_at,
        CASE 
            WHEN fr.response_started_at IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (fr.response_started_at - fr.reported_at)) / 3600
            ELSE NULL
        END as response_time_hours,
        CASE 
            WHEN fr.resolved_at IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (fr.resolved_at - fr.reported_at)) / 3600
            ELSE NULL
        END as resolution_time_hours,
        fr.reporter_satisfaction_rating,
        COUNT(*) OVER() as total_count
    FROM bms.fault_reports fr
    LEFT JOIN bms.buildings b ON fr.building_id = b.building_id
    LEFT JOIN bms.units u ON fr.unit_id = u.unit_id
    LEFT JOIN bms.fault_categories fc ON fr.category_id = fc.category_id
    LEFT JOIN bms.user_profiles up ON fr.assigned_to = up.user_id
    WHERE fr.company_id = p_company_id
        AND (p_building_id IS NULL OR fr.building_id = p_building_id)
        AND (p_unit_id IS NULL OR fr.unit_id = p_unit_id)
        AND (p_category_id IS NULL OR fr.category_id = p_category_id)
        AND (p_status IS NULL OR fr.report_status = p_status)
        AND (p_priority IS NULL OR fr.priority_level = p_priority)
        AND (p_assigned_to IS NULL OR fr.assigned_to = p_assigned_to)
        AND (p_reporter_type IS NULL OR fr.reporter_type = p_reporter_type)
        AND (p_date_from IS NULL OR DATE(fr.reported_at) >= p_date_from)
        AND (p_date_to IS NULL OR DATE(fr.reported_at) <= p_date_to)
    ORDER BY fr.reported_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 7. Get fault report statistics function
CREATE OR REPLACE FUNCTION bms.get_fault_report_statistics(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
) RETURNS TABLE (
    total_reports BIGINT,
    open_reports BIGINT,
    resolved_reports BIGINT,
    overdue_reports BIGINT,
    avg_response_time_hours DECIMAL(8,2),
    avg_resolution_time_hours DECIMAL(8,2),
    avg_satisfaction_rating DECIMAL(3,1),
    reports_by_priority JSONB,
    reports_by_category JSONB,
    reports_by_type JSONB,
    monthly_trend JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_date_from DATE := COALESCE(p_date_from, CURRENT_DATE - INTERVAL '30 days');
    v_date_to DATE := COALESCE(p_date_to, CURRENT_DATE);
BEGIN
    RETURN QUERY
    WITH report_stats AS (
        SELECT 
            COUNT(*) as total_reports,
            COUNT(*) FILTER (WHERE report_status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')) as open_reports,
            COUNT(*) FILTER (WHERE report_status IN ('RESOLVED', 'CLOSED')) as resolved_reports,
            COUNT(*) FILTER (WHERE 
                report_status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') AND
                reported_at < NOW() - INTERVAL '24 hours'
            ) as overdue_reports,
            AVG(CASE 
                WHEN response_started_at IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (response_started_at - reported_at)) / 3600
                ELSE NULL
            END) as avg_response_time_hours,
            AVG(CASE 
                WHEN resolved_at IS NOT NULL 
                THEN EXTRACT(EPOCH FROM (resolved_at - reported_at)) / 3600
                ELSE NULL
            END) as avg_resolution_time_hours,
            AVG(reporter_satisfaction_rating) FILTER (WHERE reporter_satisfaction_rating > 0) as avg_satisfaction_rating
        FROM bms.fault_reports fr
        WHERE fr.company_id = p_company_id
            AND (p_building_id IS NULL OR fr.building_id = p_building_id)
            AND DATE(fr.reported_at) BETWEEN v_date_from AND v_date_to
    ),
    priority_stats AS (
        SELECT jsonb_object_agg(priority_level, count) as reports_by_priority
        FROM (
            SELECT priority_level, COUNT(*) as count
            FROM bms.fault_reports fr
            WHERE fr.company_id = p_company_id
                AND (p_building_id IS NULL OR fr.building_id = p_building_id)
                AND DATE(fr.reported_at) BETWEEN v_date_from AND v_date_to
            GROUP BY priority_level
        ) t
    ),
    category_stats AS (
        SELECT jsonb_object_agg(category_name, count) as reports_by_category
        FROM (
            SELECT fc.category_name, COUNT(*) as count
            FROM bms.fault_reports fr
            JOIN bms.fault_categories fc ON fr.category_id = fc.category_id
            WHERE fr.company_id = p_company_id
                AND (p_building_id IS NULL OR fr.building_id = p_building_id)
                AND DATE(fr.reported_at) BETWEEN v_date_from AND v_date_to
            GROUP BY fc.category_name
        ) t
    ),
    type_stats AS (
        SELECT jsonb_object_agg(fault_type, count) as reports_by_type
        FROM (
            SELECT fault_type, COUNT(*) as count
            FROM bms.fault_reports fr
            WHERE fr.company_id = p_company_id
                AND (p_building_id IS NULL OR fr.building_id = p_building_id)
                AND DATE(fr.reported_at) BETWEEN v_date_from AND v_date_to
            GROUP BY fault_type
        ) t
    ),
    monthly_stats AS (
        SELECT jsonb_object_agg(month_year, count) as monthly_trend
        FROM (
            SELECT 
                TO_CHAR(reported_at, 'YYYY-MM') as month_year,
                COUNT(*) as count
            FROM bms.fault_reports fr
            WHERE fr.company_id = p_company_id
                AND (p_building_id IS NULL OR fr.building_id = p_building_id)
                AND reported_at >= CURRENT_DATE - INTERVAL '12 months'
            GROUP BY TO_CHAR(reported_at, 'YYYY-MM')
            ORDER BY month_year
        ) t
    )
    SELECT 
        rs.total_reports,
        rs.open_reports,
        rs.resolved_reports,
        rs.overdue_reports,
        rs.avg_response_time_hours,
        rs.avg_resolution_time_hours,
        rs.avg_satisfaction_rating,
        ps.reports_by_priority,
        cs.reports_by_category,
        ts.reports_by_type,
        ms.monthly_trend
    FROM report_stats rs
    CROSS JOIN priority_stats ps
    CROSS JOIN category_stats cs
    CROSS JOIN type_stats ts
    CROSS JOIN monthly_stats ms;
END;
$$;

-- 8. Escalate fault report function
CREATE OR REPLACE FUNCTION bms.escalate_fault_report(
    p_report_id UUID,
    p_escalated_to UUID,
    p_escalation_reason TEXT,
    p_escalated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_report RECORD;
    v_current_level INTEGER;
BEGIN
    -- Get current report information
    SELECT * INTO v_report
    FROM bms.fault_reports
    WHERE report_id = p_report_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Fault report not found: %', p_report_id;
    END IF;
    
    v_current_level := COALESCE(v_report.escalation_level, 0);
    
    -- Update escalation
    UPDATE bms.fault_reports
    SET escalation_level = v_current_level + 1,
        escalated_at = NOW(),
        escalated_to = p_escalated_to,
        escalation_reason = p_escalation_reason,
        assigned_to = p_escalated_to,
        assignment_date = NOW(),
        priority_level = CASE 
            WHEN priority_level = 'LOW' THEN 'MEDIUM'
            WHEN priority_level = 'MEDIUM' THEN 'HIGH'
            WHEN priority_level = 'HIGH' THEN 'URGENT'
            ELSE priority_level
        END,
        updated_by = p_escalated_by
    WHERE report_id = p_report_id;
    
    -- Create communication record for escalation
    INSERT INTO bms.fault_report_communications (
        company_id,
        report_id,
        communication_type,
        communication_direction,
        communication_method,
        sender_type,
        recipient_type,
        subject,
        message_content,
        created_by
    ) VALUES (
        v_report.company_id,
        p_report_id,
        'ESCALATION',
        'OUTBOUND',
        'SYSTEM',
        'SYSTEM',
        'STAFF',
        'Fault Report Escalated: ' || v_report.report_title,
        'Report escalated to level ' || (v_current_level + 1) || '. Reason: ' || p_escalation_reason,
        p_escalated_by
    );
    
    RETURN TRUE;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.create_fault_report IS 'Create a new fault report with automatic priority assignment and initial communication';
COMMENT ON FUNCTION bms.assign_fault_report IS 'Assign fault report to a user with communication logging';
COMMENT ON FUNCTION bms.update_fault_report_status IS 'Update fault report status with automatic timestamp tracking';
COMMENT ON FUNCTION bms.add_fault_report_communication IS 'Add communication record to fault report';
COMMENT ON FUNCTION bms.submit_fault_report_feedback IS 'Submit feedback for resolved fault report';
COMMENT ON FUNCTION bms.get_fault_reports IS 'Get fault reports with filtering and pagination';
COMMENT ON FUNCTION bms.get_fault_report_statistics IS 'Get comprehensive fault report statistics and analytics';
COMMENT ON FUNCTION bms.escalate_fault_report IS 'Escalate fault report to higher level with priority adjustment';

-- Script completion message
SELECT 'Fault reporting system functions created successfully.' as message;