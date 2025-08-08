-- =====================================================
-- Individual Fault Reporting System Functions
-- Phase 4.3.1: Individual Function Creation
-- =====================================================

-- Update fault report status function
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

-- Submit fault report feedback function
CREATE OR REPLACE FUNCTION bms.submit_fault_report_feedback(
    p_report_id UUID,
    p_feedback_provider_type VARCHAR(20),
    p_feedback_type VARCHAR(20),
    p_feedback_category VARCHAR(30),
    p_submission_method VARCHAR(20) DEFAULT 'WEB_PORTAL',
    p_feedback_provider_name VARCHAR(100) DEFAULT NULL,
    p_feedback_provider_contact VARCHAR(100) DEFAULT NULL,
    p_feedback_provider_user_id UUID DEFAULT NULL,
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
    p_resolution_met_expectations BOOLEAN DEFAULT NULL
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
$$;

-- Comments
COMMENT ON FUNCTION bms.update_fault_report_status IS 'Update fault report status with automatic timestamp tracking';
COMMENT ON FUNCTION bms.submit_fault_report_feedback IS 'Submit feedback for resolved fault report';

-- Script completion message
SELECT 'Individual fault reporting functions created successfully.' as message;