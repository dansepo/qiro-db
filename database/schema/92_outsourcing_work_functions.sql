-- =====================================================
-- Outsourcing Work Management Functions
-- Phase 4.5.2: Outsourcing Work Management Functions
-- =====================================================

-- 1. Function to create outsourcing work request
CREATE OR REPLACE FUNCTION bms.create_outsourcing_work_request(
    p_company_id UUID,
    p_request_title VARCHAR(200),
    p_request_type VARCHAR(30),
    p_requester_id UUID,
    p_work_description TEXT,
    p_work_location VARCHAR(200) DEFAULT NULL,
    p_required_start_date DATE DEFAULT NULL,
    p_required_completion_date DATE DEFAULT NULL,
    p_estimated_budget DECIMAL(15,2) DEFAULT 0,
    p_priority_level VARCHAR(20) DEFAULT 'NORMAL',
    p_urgency_level VARCHAR(20) DEFAULT 'NORMAL',
    p_required_contractor_category UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_request_id UUID;
    v_request_number VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate request number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(request_number FROM 'OWR-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.outsourcing_work_requests 
    WHERE company_id = p_company_id 
      AND request_number LIKE 'OWR-' || v_year || '-%';
    
    v_request_number := 'OWR-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert request
    INSERT INTO bms.outsourcing_work_requests (
        company_id, request_number, request_title, request_type,
        requester_id, work_description, work_location,
        required_start_date, required_completion_date, estimated_budget,
        priority_level, urgency_level, required_contractor_category,
        created_by
    ) VALUES (
        p_company_id, v_request_number, p_request_title, p_request_type,
        p_requester_id, p_work_description, p_work_location,
        p_required_start_date, p_required_completion_date, p_estimated_budget,
        p_priority_level, p_urgency_level, p_required_contractor_category,
        p_requester_id
    ) RETURNING request_id INTO v_request_id;
    
    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to assign work to contractor
CREATE OR REPLACE FUNCTION bms.assign_work_to_contractor(
    p_request_id UUID,
    p_contractor_id UUID,
    p_scheduled_start_date DATE,
    p_scheduled_completion_date DATE,
    p_contract_amount DECIMAL(15,2),
    p_supervisor_id UUID DEFAULT NULL,
    p_payment_terms VARCHAR(200) DEFAULT NULL,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_assignment_id UUID;
    v_assignment_number VARCHAR(50);
    v_request RECORD;
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Get request details
    SELECT * INTO v_request
    FROM bms.outsourcing_work_requests 
    WHERE request_id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work request not found: %', p_request_id;
    END IF;
    
    -- Generate assignment number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(assignment_number FROM 'OWA-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.outsourcing_work_assignments 
    WHERE company_id = v_request.company_id 
      AND assignment_number LIKE 'OWA-' || v_year || '-%';
    
    v_assignment_number := 'OWA-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert assignment
    INSERT INTO bms.outsourcing_work_assignments (
        company_id, assignment_number, assignment_title,
        request_id, contractor_id, work_description, work_location,
        scheduled_start_date, scheduled_completion_date, contract_amount,
        supervisor_id, payment_terms, created_by
    ) VALUES (
        v_request.company_id, v_assignment_number, v_request.request_title,
        p_request_id, p_contractor_id, v_request.work_description, v_request.work_location,
        p_scheduled_start_date, p_scheduled_completion_date, p_contract_amount,
        p_supervisor_id, p_payment_terms, p_assigned_by
    ) RETURNING assignment_id INTO v_assignment_id;
    
    -- Update request status
    UPDATE bms.outsourcing_work_requests 
    SET 
        request_status = 'ASSIGNED',
        updated_at = NOW()
    WHERE request_id = p_request_id;
    
    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to update work progress
CREATE OR REPLACE FUNCTION bms.update_work_progress(
    p_assignment_id UUID,
    p_progress_percentage DECIMAL(5,2),
    p_updated_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_assignment RECORD;
    v_new_status VARCHAR(20);
BEGIN
    -- Get assignment details
    SELECT * INTO v_assignment
    FROM bms.outsourcing_work_assignments 
    WHERE assignment_id = p_assignment_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work assignment not found: %', p_assignment_id;
    END IF;
    
    -- Determine new status based on progress
    v_new_status := CASE 
        WHEN p_progress_percentage = 0 THEN 'ASSIGNED'
        WHEN p_progress_percentage > 0 AND p_progress_percentage < 100 THEN 'IN_PROGRESS'
        WHEN p_progress_percentage = 100 THEN 'COMPLETED'
        ELSE v_assignment.assignment_status
    END;
    
    -- Update assignment
    UPDATE bms.outsourcing_work_assignments 
    SET 
        progress_percentage = p_progress_percentage,
        assignment_status = v_new_status,
        actual_start_date = CASE 
            WHEN actual_start_date IS NULL AND p_progress_percentage > 0 THEN CURRENT_DATE
            ELSE actual_start_date
        END,
        actual_completion_date = CASE 
            WHEN p_progress_percentage = 100 THEN CURRENT_DATE
            ELSE NULL
        END,
        updated_by = p_updated_by,
        updated_at = NOW()
    WHERE assignment_id = p_assignment_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Function to create work inspection
CREATE OR REPLACE FUNCTION bms.create_work_inspection(
    p_assignment_id UUID,
    p_inspection_type VARCHAR(30),
    p_inspector_id UUID,
    p_inspection_scope TEXT,
    p_overall_result VARCHAR(20) DEFAULT 'PENDING',
    p_quality_score DECIMAL(5,2) DEFAULT NULL,
    p_safety_score DECIMAL(5,2) DEFAULT NULL,
    p_major_issues TEXT DEFAULT NULL,
    p_recommendations TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_inspection_id UUID;
    v_inspection_number VARCHAR(50);
    v_company_id UUID;
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Get company_id from assignment
    SELECT company_id INTO v_company_id
    FROM bms.outsourcing_work_assignments 
    WHERE assignment_id = p_assignment_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Work assignment not found: %', p_assignment_id;
    END IF;
    
    -- Generate inspection number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(inspection_number FROM 'INS-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.work_inspection_records 
    WHERE company_id = v_company_id 
      AND inspection_number LIKE 'INS-' || v_year || '-%';
    
    v_inspection_number := 'INS-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert inspection
    INSERT INTO bms.work_inspection_records (
        company_id, assignment_id, inspection_number, inspection_type,
        inspector_id, inspection_scope, overall_result,
        quality_score, safety_score, major_issues, recommendations,
        created_by
    ) VALUES (
        v_company_id, p_assignment_id, v_inspection_number, p_inspection_type,
        p_inspector_id, p_inspection_scope, p_overall_result,
        p_quality_score, p_safety_score, p_major_issues, p_recommendations,
        p_inspector_id
    ) RETURNING inspection_id INTO v_inspection_id;
    
    RETURN v_inspection_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to get work assignment summary
CREATE OR REPLACE FUNCTION bms.get_work_assignment_summary(
    p_company_id UUID,
    p_contractor_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    assignment_status VARCHAR(20),
    assignment_count BIGINT,
    total_contract_value DECIMAL(15,2),
    avg_progress DECIMAL(5,2),
    on_time_count BIGINT,
    delayed_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        owa.assignment_status,
        COUNT(*) as assignment_count,
        COALESCE(SUM(owa.contract_amount), 0) as total_contract_value,
        COALESCE(AVG(owa.progress_percentage), 0) as avg_progress,
        COUNT(CASE WHEN owa.actual_completion_date <= owa.scheduled_completion_date THEN 1 END) as on_time_count,
        COUNT(CASE WHEN owa.actual_completion_date > owa.scheduled_completion_date OR 
                        (owa.actual_completion_date IS NULL AND CURRENT_DATE > owa.scheduled_completion_date) 
                   THEN 1 END) as delayed_count
    FROM bms.outsourcing_work_assignments owa
    WHERE owa.company_id = p_company_id
      AND (p_contractor_id IS NULL OR owa.contractor_id = p_contractor_id)
      AND (p_start_date IS NULL OR owa.assignment_date >= p_start_date)
      AND (p_end_date IS NULL OR owa.assignment_date <= p_end_date)
    GROUP BY owa.assignment_status
    ORDER BY owa.assignment_status;
END;
$$ LANGUAGE plpgsql;

-- Comments for functions
COMMENT ON FUNCTION bms.create_outsourcing_work_request(UUID, VARCHAR, VARCHAR, UUID, TEXT, VARCHAR, DATE, DATE, DECIMAL, VARCHAR, VARCHAR, UUID) IS 'Create new outsourcing work request';
COMMENT ON FUNCTION bms.assign_work_to_contractor(UUID, UUID, DATE, DATE, DECIMAL, UUID, VARCHAR, UUID) IS 'Assign work request to contractor';
COMMENT ON FUNCTION bms.update_work_progress(UUID, DECIMAL, UUID) IS 'Update work assignment progress';
COMMENT ON FUNCTION bms.create_work_inspection(UUID, VARCHAR, UUID, TEXT, VARCHAR, DECIMAL, DECIMAL, TEXT, TEXT) IS 'Create work inspection record';
COMMENT ON FUNCTION bms.get_work_assignment_summary(UUID, UUID, DATE, DATE) IS 'Get work assignment summary statistics';

-- Script completion message
SELECT 'Outsourcing Work Management Functions created successfully!' as status;