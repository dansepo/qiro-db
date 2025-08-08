-- =====================================================
-- Safety Inspection Management Functions
-- Phase 4.7.1: Safety Inspection Management Functions
-- =====================================================

-- 1. Function to create safety inspection schedule
CREATE OR REPLACE FUNCTION bms.create_safety_inspection_schedule(
    p_company_id UUID,
    p_schedule_name VARCHAR(200),
    p_category_id UUID,
    p_inspection_scope TEXT,
    p_frequency_type VARCHAR(20),
    p_frequency_value INTEGER,
    p_frequency_unit VARCHAR(20),
    p_next_inspection_date DATE,
    p_assigned_inspector_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_schedule_id UUID;
BEGIN
    -- Insert schedule
    INSERT INTO bms.safety_inspection_schedules (
        company_id, schedule_name, category_id, inspection_scope,
        frequency_type, frequency_value, frequency_unit,
        next_inspection_date, assigned_inspector_id, building_id,
        created_by
    ) VALUES (
        p_company_id, p_schedule_name, p_category_id, p_inspection_scope,
        p_frequency_type, p_frequency_value, p_frequency_unit,
        p_next_inspection_date, p_assigned_inspector_id, p_building_id,
        p_assigned_inspector_id
    ) RETURNING schedule_id INTO v_schedule_id;
    
    RETURN v_schedule_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to create safety inspection
CREATE OR REPLACE FUNCTION bms.create_safety_inspection(
    p_company_id UUID,
    p_inspection_title VARCHAR(200),
    p_category_id UUID,
    p_inspector_id UUID,
    p_inspection_scope TEXT,
    p_inspection_date DATE DEFAULT CURRENT_DATE,
    p_schedule_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_inspection_id UUID;
    v_inspection_number VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate inspection number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(inspection_number FROM 'SI-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.safety_inspections 
    WHERE company_id = p_company_id 
      AND inspection_number LIKE 'SI-' || v_year || '-%';
    
    v_inspection_number := 'SI-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert inspection
    INSERT INTO bms.safety_inspections (
        company_id, inspection_number, inspection_title,
        category_id, inspector_id, inspection_scope,
        inspection_date, schedule_id, building_id,
        overall_result, created_by
    ) VALUES (
        p_company_id, v_inspection_number, p_inspection_title,
        p_category_id, p_inspector_id, p_inspection_scope,
        p_inspection_date, p_schedule_id, p_building_id,
        'PENDING', p_inspector_id
    ) RETURNING inspection_id INTO v_inspection_id;
    
    RETURN v_inspection_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to complete safety inspection
CREATE OR REPLACE FUNCTION bms.complete_safety_inspection(
    p_inspection_id UUID,
    p_overall_result VARCHAR(20),
    p_total_items_checked INTEGER DEFAULT 0,
    p_passed_items INTEGER DEFAULT 0,
    p_failed_items INTEGER DEFAULT 0,
    p_critical_issues INTEGER DEFAULT 0,
    p_major_issues INTEGER DEFAULT 0,
    p_minor_issues INTEGER DEFAULT 0,
    p_safety_score DECIMAL(5,2) DEFAULT NULL,
    p_immediate_actions TEXT DEFAULT NULL,
    p_corrective_actions TEXT DEFAULT NULL,
    p_recommendations TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_overall_score DECIMAL(5,2);
    v_reinspection_required BOOLEAN := FALSE;
BEGIN
    -- Calculate overall score
    IF p_total_items_checked > 0 THEN
        v_overall_score := (p_passed_items::DECIMAL / p_total_items_checked::DECIMAL) * 100;
    END IF;
    
    -- Determine if reinspection is required
    IF p_critical_issues > 0 OR p_overall_result = 'FAILED' THEN
        v_reinspection_required := TRUE;
    END IF;
    
    -- Update inspection
    UPDATE bms.safety_inspections 
    SET 
        overall_result = p_overall_result,
        total_items_checked = p_total_items_checked,
        passed_items = p_passed_items,
        failed_items = p_failed_items,
        critical_issues = p_critical_issues,
        major_issues = p_major_issues,
        minor_issues = p_minor_issues,
        safety_score = p_safety_score,
        overall_score = v_overall_score,
        immediate_actions_required = p_immediate_actions,
        corrective_actions_required = p_corrective_actions,
        recommendations = p_recommendations,
        reinspection_required = v_reinspection_required,
        reinspection_date = CASE 
            WHEN v_reinspection_required THEN CURRENT_DATE + INTERVAL '30 days'
            ELSE NULL
        END,
        inspection_completed = TRUE,
        completion_date = NOW(),
        inspection_status = 'COMPLETED',
        updated_at = NOW()
    WHERE inspection_id = p_inspection_id;
    
    -- Update schedule's last inspection date
    UPDATE bms.safety_inspection_schedules 
    SET 
        last_inspection_date = (SELECT inspection_date FROM bms.safety_inspections WHERE inspection_id = p_inspection_id),
        next_inspection_date = CASE 
            WHEN frequency_type = 'MONTHLY' THEN 
                (SELECT inspection_date FROM bms.safety_inspections WHERE inspection_id = p_inspection_id) + (frequency_value || ' months')::INTERVAL
            WHEN frequency_type = 'QUARTERLY' THEN 
                (SELECT inspection_date FROM bms.safety_inspections WHERE inspection_id = p_inspection_id) + (frequency_value * 3 || ' months')::INTERVAL
            WHEN frequency_type = 'ANNUAL' THEN 
                (SELECT inspection_date FROM bms.safety_inspections WHERE inspection_id = p_inspection_id) + (frequency_value || ' years')::INTERVAL
            ELSE next_inspection_date
        END,
        updated_at = NOW()
    WHERE schedule_id = (SELECT schedule_id FROM bms.safety_inspections WHERE inspection_id = p_inspection_id)
      AND schedule_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Function to report safety incident
CREATE OR REPLACE FUNCTION bms.report_safety_incident(
    p_company_id UUID,
    p_incident_title VARCHAR(200),
    p_incident_type VARCHAR(30),
    p_incident_location VARCHAR(200),
    p_incident_description TEXT,
    p_severity_level VARCHAR(20),
    p_reported_by UUID,
    p_incident_date DATE DEFAULT CURRENT_DATE,
    p_building_id UUID DEFAULT NULL,
    p_injured_persons INTEGER DEFAULT 0,
    p_property_damage BOOLEAN DEFAULT FALSE
)
RETURNS UUID AS $$
DECLARE
    v_incident_id UUID;
    v_incident_number VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate incident number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(incident_number FROM 'INC-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.safety_incidents 
    WHERE company_id = p_company_id 
      AND incident_number LIKE 'INC-' || v_year || '-%';
    
    v_incident_number := 'INC-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert incident
    INSERT INTO bms.safety_incidents (
        company_id, incident_number, incident_title, incident_type,
        incident_location, incident_description, severity_level,
        reported_by, incident_date, building_id,
        injured_persons, property_damage,
        investigation_required, follow_up_required,
        regulatory_reporting_required, created_by
    ) VALUES (
        p_company_id, v_incident_number, p_incident_title, p_incident_type,
        p_incident_location, p_incident_description, p_severity_level,
        p_reported_by, p_incident_date, p_building_id,
        p_injured_persons, p_property_damage,
        CASE WHEN p_severity_level IN ('MAJOR', 'CRITICAL', 'CATASTROPHIC') THEN TRUE ELSE FALSE END,
        TRUE,
        CASE WHEN p_severity_level IN ('CRITICAL', 'CATASTROPHIC') OR p_injured_persons > 0 THEN TRUE ELSE FALSE END,
        p_reported_by
    ) RETURNING incident_id INTO v_incident_id;
    
    RETURN v_incident_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to get safety inspection summary
CREATE OR REPLACE FUNCTION bms.get_safety_inspection_summary(
    p_company_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL,
    p_category_id UUID DEFAULT NULL
)
RETURNS TABLE (
    inspection_status VARCHAR(20),
    inspection_count BIGINT,
    passed_count BIGINT,
    failed_count BIGINT,
    avg_safety_score DECIMAL(5,2),
    critical_issues_total BIGINT,
    major_issues_total BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        si.inspection_status,
        COUNT(*) as inspection_count,
        COUNT(CASE WHEN si.overall_result = 'PASSED' THEN 1 END) as passed_count,
        COUNT(CASE WHEN si.overall_result = 'FAILED' THEN 1 END) as failed_count,
        COALESCE(AVG(si.safety_score), 0) as avg_safety_score,
        COALESCE(SUM(si.critical_issues), 0) as critical_issues_total,
        COALESCE(SUM(si.major_issues), 0) as major_issues_total
    FROM bms.safety_inspections si
    WHERE si.company_id = p_company_id
      AND (p_start_date IS NULL OR si.inspection_date >= p_start_date)
      AND (p_end_date IS NULL OR si.inspection_date <= p_end_date)
      AND (p_category_id IS NULL OR si.category_id = p_category_id)
    GROUP BY si.inspection_status
    ORDER BY si.inspection_status;
END;
$$ LANGUAGE plpgsql;

-- Comments for functions
COMMENT ON FUNCTION bms.create_safety_inspection_schedule(UUID, VARCHAR, UUID, TEXT, VARCHAR, INTEGER, VARCHAR, DATE, UUID, UUID) IS 'Create safety inspection schedule';
COMMENT ON FUNCTION bms.create_safety_inspection(UUID, VARCHAR, UUID, UUID, TEXT, DATE, UUID, UUID) IS 'Create safety inspection record';
COMMENT ON FUNCTION bms.complete_safety_inspection(UUID, VARCHAR, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, DECIMAL, TEXT, TEXT, TEXT) IS 'Complete safety inspection with results';
COMMENT ON FUNCTION bms.report_safety_incident(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, UUID, DATE, UUID, INTEGER, BOOLEAN) IS 'Report safety incident';
COMMENT ON FUNCTION bms.get_safety_inspection_summary(UUID, DATE, DATE, UUID) IS 'Get safety inspection summary statistics';

-- Script completion message
SELECT 'Safety Inspection Management Functions created successfully!' as status;