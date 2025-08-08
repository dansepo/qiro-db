-- =====================================================
-- Security Facility Management Functions
-- Phase 4.7.2: Security Facility Management Functions
-- =====================================================

-- 1. Security zone management functions
CREATE OR REPLACE FUNCTION bms.create_security_zone(
    p_company_id UUID,
    p_zone_code VARCHAR(20),
    p_zone_name VARCHAR(100),
    p_zone_type VARCHAR(30),
    p_security_level VARCHAR(20),
    p_building_id UUID DEFAULT NULL,
    p_parent_zone_id UUID DEFAULT NULL,
    p_zone_description TEXT DEFAULT NULL,
    p_operating_hours JSONB DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_zone_id UUID;
    v_zone_level INTEGER := 1;
BEGIN
    -- Calculate zone level if parent exists
    IF p_parent_zone_id IS NOT NULL THEN
        SELECT zone_level + 1 INTO v_zone_level
        FROM bms.security_zones
        WHERE zone_id = p_parent_zone_id AND company_id = p_company_id;
        
        IF v_zone_level IS NULL THEN
            RAISE EXCEPTION '상위 보안 구역을 찾을 수 없습니다: %', p_parent_zone_id;
        END IF;
    END IF;
    
    -- Insert new security zone
    INSERT INTO bms.security_zones (
        company_id, zone_code, zone_name, zone_description, zone_type,
        building_id, parent_zone_id, zone_level, security_level,
        operating_hours, created_by
    ) VALUES (
        p_company_id, p_zone_code, p_zone_name, p_zone_description, p_zone_type,
        p_building_id, p_parent_zone_id, v_zone_level, p_security_level,
        p_operating_hours, p_created_by
    ) RETURNING zone_id INTO v_zone_id;
    
    RETURN v_zone_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Security device registration function
CREATE OR REPLACE FUNCTION bms.register_security_device(
    p_company_id UUID,
    p_device_code VARCHAR(30),
    p_device_name VARCHAR(100),
    p_device_type VARCHAR(30),
    p_device_category VARCHAR(30),
    p_zone_id UUID,
    p_manufacturer VARCHAR(100) DEFAULT NULL,
    p_model VARCHAR(100) DEFAULT NULL,
    p_serial_number VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_installation_date DATE DEFAULT CURRENT_DATE,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_device_id UUID;
    v_zone_exists BOOLEAN;
BEGIN
    -- Verify zone exists and belongs to company
    SELECT EXISTS(
        SELECT 1 FROM bms.security_zones 
        WHERE zone_id = p_zone_id AND company_id = p_company_id
    ) INTO v_zone_exists;
    
    IF NOT v_zone_exists THEN
        RAISE EXCEPTION '지정된 보안 구역을 찾을 수 없습니다: %', p_zone_id;
    END IF;
    
    -- Insert new security device
    INSERT INTO bms.security_devices (
        company_id, device_code, device_name, device_type, device_category,
        zone_id, manufacturer, model, serial_number, ip_address,
        installation_date, created_by
    ) VALUES (
        p_company_id, p_device_code, p_device_name, p_device_type, p_device_category,
        p_zone_id, p_manufacturer, p_model, p_serial_number, p_ip_address,
        p_installation_date, p_created_by
    ) RETURNING device_id INTO v_device_id;
    
    RETURN v_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Access control logging function
CREATE OR REPLACE FUNCTION bms.log_access_attempt(
    p_company_id UUID,
    p_device_id UUID,
    p_zone_id UUID,
    p_person_id UUID DEFAULT NULL,
    p_person_name VARCHAR(100) DEFAULT NULL,
    p_person_type VARCHAR(30) DEFAULT 'UNKNOWN',
    p_access_method VARCHAR(30) DEFAULT 'CARD',
    p_credential_type VARCHAR(30) DEFAULT NULL,
    p_credential_id VARCHAR(100) DEFAULT NULL,
    p_access_result VARCHAR(20) DEFAULT 'DENIED',
    p_access_direction VARCHAR(10) DEFAULT 'IN',
    p_anomaly_detected BOOLEAN DEFAULT FALSE,
    p_anomaly_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_record_id UUID;
    v_device_exists BOOLEAN;
    v_zone_exists BOOLEAN;
BEGIN
    -- Verify device and zone exist
    SELECT EXISTS(
        SELECT 1 FROM bms.security_devices 
        WHERE device_id = p_device_id AND company_id = p_company_id
    ) INTO v_device_exists;
    
    SELECT EXISTS(
        SELECT 1 FROM bms.security_zones 
        WHERE zone_id = p_zone_id AND company_id = p_company_id
    ) INTO v_zone_exists;
    
    IF NOT v_device_exists THEN
        RAISE EXCEPTION '지정된 보안 장비를 찾을 수 없습니다: %', p_device_id;
    END IF;
    
    IF NOT v_zone_exists THEN
        RAISE EXCEPTION '지정된 보안 구역을 찾을 수 없습니다: %', p_zone_id;
    END IF;
    
    -- Insert access control record
    INSERT INTO bms.access_control_records (
        company_id, device_id, zone_id, person_id, person_name, person_type,
        access_method, credential_type, credential_id, access_result, access_direction,
        anomaly_detected, anomaly_description
    ) VALUES (
        p_company_id, p_device_id, p_zone_id, p_person_id, p_person_name, p_person_type,
        p_access_method, p_credential_type, p_credential_id, p_access_result, p_access_direction,
        p_anomaly_detected, p_anomaly_description
    ) RETURNING record_id INTO v_record_id;
    
    -- Generate alert if anomaly detected or access denied
    IF p_anomaly_detected OR p_access_result = 'DENIED' THEN
        PERFORM bms.generate_security_alert(
            p_company_id, 
            'ACCESS_CONTROL',
            CASE 
                WHEN p_anomaly_detected THEN 'ANOMALY_DETECTED'
                ELSE 'ACCESS_DENIED'
            END,
            p_zone_id,
            p_device_id,
            COALESCE(p_anomaly_description, '출입 거부: ' || p_person_name)
        );
    END IF;
    
    RETURN v_record_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Security incident creation function
CREATE OR REPLACE FUNCTION bms.create_security_incident(
    p_company_id UUID,
    p_incident_title VARCHAR(200),
    p_incident_type VARCHAR(30),
    p_incident_category VARCHAR(30),
    p_severity_level VARCHAR(20),
    p_incident_description TEXT,
    p_zone_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_detecting_device_id UUID DEFAULT NULL,
    p_detected_by UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_incident_id UUID;
    v_incident_number VARCHAR(50);
BEGIN
    -- Generate incident number
    v_incident_number := 'INC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                        LPAD(NEXTVAL('bms.incident_number_seq')::TEXT, 4, '0');
    
    -- Insert security incident
    INSERT INTO bms.security_incidents (
        company_id, incident_number, incident_title, incident_type, incident_category,
        severity_level, incident_description, zone_id, building_id,
        detecting_device_id, detected_by, created_by
    ) VALUES (
        p_company_id, v_incident_number, p_incident_title, p_incident_type, p_incident_category,
        p_severity_level, p_incident_description, p_zone_id, p_building_id,
        p_detecting_device_id, p_detected_by, p_created_by
    ) RETURNING incident_id INTO v_incident_id;
    
    -- Auto-assign investigator for high/critical incidents
    IF p_severity_level IN ('HIGH', 'CRITICAL') THEN
        PERFORM bms.assign_incident_investigator(v_incident_id, p_company_id);
    END IF;
    
    RETURN v_incident_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Security patrol scheduling function
CREATE OR REPLACE FUNCTION bms.schedule_security_patrol(
    p_company_id UUID,
    p_patrol_name VARCHAR(100),
    p_patrol_type VARCHAR(30),
    p_patrol_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_patrol_officer_id UUID,
    p_zones_to_patrol JSONB,
    p_patrol_route JSONB DEFAULT NULL,
    p_patrol_instructions TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_patrol_id UUID;
    v_patrol_number VARCHAR(50);
    v_officer_exists BOOLEAN;
BEGIN
    -- Verify patrol officer exists
    SELECT EXISTS(
        SELECT 1 FROM bms.users 
        WHERE user_id = p_patrol_officer_id AND company_id = p_company_id
    ) INTO v_officer_exists;
    
    IF NOT v_officer_exists THEN
        RAISE EXCEPTION '지정된 순찰 담당자를 찾을 수 없습니다: %', p_patrol_officer_id;
    END IF;
    
    -- Generate patrol number
    v_patrol_number := 'PAT-' || TO_CHAR(p_patrol_date, 'YYYYMMDD') || '-' || 
                      LPAD(NEXTVAL('bms.patrol_number_seq')::TEXT, 3, '0');
    
    -- Insert security patrol
    INSERT INTO bms.security_patrols (
        company_id, patrol_number, patrol_name, patrol_type, patrol_date,
        scheduled_start_time, scheduled_end_time, patrol_officer_id,
        zones_to_patrol, patrol_route, patrol_instructions, created_by
    ) VALUES (
        p_company_id, v_patrol_number, p_patrol_name, p_patrol_type, p_patrol_date,
        p_start_time, p_end_time, p_patrol_officer_id,
        p_zones_to_patrol, p_patrol_route, p_patrol_instructions, p_created_by
    ) RETURNING patrol_id INTO v_patrol_id;
    
    RETURN v_patrol_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Visitor registration function
CREATE OR REPLACE FUNCTION bms.register_visitor(
    p_company_id UUID,
    p_visitor_name VARCHAR(100),
    p_visit_type VARCHAR(30),
    p_visit_purpose TEXT,
    p_host_employee_id UUID,
    p_scheduled_arrival TIMESTAMP WITH TIME ZONE,
    p_scheduled_departure TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_visitor_company VARCHAR(200) DEFAULT NULL,
    p_visitor_phone VARCHAR(20) DEFAULT NULL,
    p_visitor_email VARCHAR(100) DEFAULT NULL,
    p_authorized_zones JSONB DEFAULT NULL,
    p_escort_required BOOLEAN DEFAULT TRUE,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_visit_id UUID;
    v_visit_number VARCHAR(50);
    v_host_exists BOOLEAN;
BEGIN
    -- Verify host employee exists
    IF p_host_employee_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 FROM bms.users 
            WHERE user_id = p_host_employee_id AND company_id = p_company_id
        ) INTO v_host_exists;
        
        IF NOT v_host_exists THEN
            RAISE EXCEPTION '지정된 호스트 직원을 찾을 수 없습니다: %', p_host_employee_id;
        END IF;
    END IF;
    
    -- Generate visit number
    v_visit_number := 'VIS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                     LPAD(NEXTVAL('bms.visit_number_seq')::TEXT, 4, '0');
    
    -- Insert visitor registration
    INSERT INTO bms.visitor_management (
        company_id, visit_number, visit_type, visitor_name, visit_purpose,
        host_employee_id, scheduled_arrival, scheduled_departure,
        visitor_company, visitor_phone, visitor_email,
        authorized_zones, escort_required, created_by
    ) VALUES (
        p_company_id, v_visit_number, p_visit_type, p_visitor_name, p_visit_purpose,
        p_host_employee_id, p_scheduled_arrival, p_scheduled_departure,
        p_visitor_company, p_visitor_phone, p_visitor_email,
        p_authorized_zones, p_escort_required, p_created_by
    ) RETURNING visit_id INTO v_visit_id;
    
    RETURN v_visit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Security alert generation function
CREATE OR REPLACE FUNCTION bms.generate_security_alert(
    p_company_id UUID,
    p_alert_type VARCHAR(30),
    p_alert_subtype VARCHAR(50),
    p_zone_id UUID DEFAULT NULL,
    p_device_id UUID DEFAULT NULL,
    p_alert_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_alert_level VARCHAR(20);
    v_notification_required BOOLEAN := FALSE;
BEGIN
    -- Determine alert level based on type
    v_alert_level := CASE p_alert_type
        WHEN 'ACCESS_CONTROL' THEN 
            CASE p_alert_subtype
                WHEN 'ANOMALY_DETECTED' THEN 'HIGH'
                WHEN 'ACCESS_DENIED' THEN 'MEDIUM'
                ELSE 'LOW'
            END
        WHEN 'DEVICE_MALFUNCTION' THEN 'HIGH'
        WHEN 'INTRUSION_DETECTED' THEN 'CRITICAL'
        WHEN 'EMERGENCY' THEN 'CRITICAL'
        ELSE 'MEDIUM'
    END;
    
    -- Determine if notification is required
    v_notification_required := v_alert_level IN ('HIGH', 'CRITICAL');
    
    -- Log the alert (this would typically go to a separate alerts table)
    -- For now, we'll create a security incident for high/critical alerts
    IF v_notification_required THEN
        PERFORM bms.create_security_incident(
            p_company_id,
            '보안 알림: ' || p_alert_type,
            CASE p_alert_type
                WHEN 'ACCESS_CONTROL' THEN 'UNAUTHORIZED_ACCESS'
                WHEN 'DEVICE_MALFUNCTION' THEN 'DEVICE_TAMPERING'
                WHEN 'INTRUSION_DETECTED' THEN 'INTRUSION'
                ELSE 'SUSPICIOUS_ACTIVITY'
            END,
            'PHYSICAL_SECURITY',
            v_alert_level,
            COALESCE(p_alert_message, '자동 생성된 보안 알림'),
            p_zone_id,
            NULL,
            p_device_id
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Incident investigator assignment function
CREATE OR REPLACE FUNCTION bms.assign_incident_investigator(
    p_incident_id UUID,
    p_company_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_investigator_id UUID;
BEGIN
    -- Find available security officer or manager
    SELECT user_id INTO v_investigator_id
    FROM bms.users u
    JOIN bms.user_roles ur ON u.user_id = ur.user_id
    JOIN bms.roles r ON ur.role_id = r.role_id
    WHERE u.company_id = p_company_id
      AND r.role_name IN ('SECURITY_MANAGER', 'SECURITY_OFFICER')
      AND u.user_status = 'ACTIVE'
    ORDER BY 
        CASE r.role_name 
            WHEN 'SECURITY_MANAGER' THEN 1 
            ELSE 2 
        END,
        u.created_at
    LIMIT 1;
    
    -- Update incident with investigator
    IF v_investigator_id IS NOT NULL THEN
        UPDATE bms.security_incidents
        SET investigator_id = v_investigator_id,
            investigation_status = 'PENDING',
            updated_at = NOW()
        WHERE incident_id = p_incident_id;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Security zone access validation function
CREATE OR REPLACE FUNCTION bms.validate_zone_access(
    p_company_id UUID,
    p_person_id UUID,
    p_zone_id UUID,
    p_access_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS BOOLEAN AS $$
DECLARE
    v_zone_security_level VARCHAR(20);
    v_zone_status VARCHAR(20);
    v_operating_hours JSONB;
    v_person_clearance_level VARCHAR(20);
    v_current_time TIME;
    v_current_day INTEGER;
    v_access_allowed BOOLEAN := FALSE;
BEGIN
    -- Get zone information
    SELECT security_level, zone_status, operating_hours
    INTO v_zone_security_level, v_zone_status, v_operating_hours
    FROM bms.security_zones
    WHERE zone_id = p_zone_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Check if zone is active
    IF v_zone_status != 'ACTIVE' THEN
        RETURN FALSE;
    END IF;
    
    -- Get person's security clearance level (simplified - would need proper implementation)
    SELECT COALESCE(
        (SELECT role_name FROM bms.roles r 
         JOIN bms.user_roles ur ON r.role_id = ur.role_id 
         WHERE ur.user_id = p_person_id 
         ORDER BY r.role_level DESC LIMIT 1),
        'LOW'
    ) INTO v_person_clearance_level;
    
    -- Check security level clearance
    v_access_allowed := CASE 
        WHEN v_zone_security_level = 'PUBLIC' THEN TRUE
        WHEN v_zone_security_level = 'LOW' AND v_person_clearance_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL') THEN TRUE
        WHEN v_zone_security_level = 'MEDIUM' AND v_person_clearance_level IN ('MEDIUM', 'HIGH', 'CRITICAL') THEN TRUE
        WHEN v_zone_security_level = 'HIGH' AND v_person_clearance_level IN ('HIGH', 'CRITICAL') THEN TRUE
        WHEN v_zone_security_level = 'CRITICAL' AND v_person_clearance_level = 'CRITICAL' THEN TRUE
        ELSE FALSE
    END;
    
    -- Check operating hours if specified
    IF v_access_allowed AND v_operating_hours IS NOT NULL THEN
        v_current_time := p_access_time::TIME;
        v_current_day := EXTRACT(DOW FROM p_access_time); -- 0=Sunday, 6=Saturday
        
        -- Simplified operating hours check (would need more complex logic for real implementation)
        v_access_allowed := TRUE; -- Placeholder - implement actual hours checking
    END IF;
    
    RETURN v_access_allowed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Device status monitoring function
CREATE OR REPLACE FUNCTION bms.update_device_status(
    p_device_id UUID,
    p_company_id UUID,
    p_operational_status VARCHAR(20),
    p_last_online_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS VOID AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_device_type VARCHAR(30);
BEGIN
    -- Get current device status
    SELECT operational_status, device_type
    INTO v_current_status, v_device_type
    FROM bms.security_devices
    WHERE device_id = p_device_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '지정된 보안 장비를 찾을 수 없습니다: %', p_device_id;
    END IF;
    
    -- Update device status
    UPDATE bms.security_devices
    SET operational_status = p_operational_status,
        last_online_time = p_last_online_time,
        updated_at = NOW()
    WHERE device_id = p_device_id;
    
    -- Generate alert if device went offline or has error
    IF v_current_status = 'ONLINE' AND p_operational_status IN ('OFFLINE', 'ERROR') THEN
        PERFORM bms.generate_security_alert(
            p_company_id,
            'DEVICE_MALFUNCTION',
            p_operational_status,
            (SELECT zone_id FROM bms.security_devices WHERE device_id = p_device_id),
            p_device_id,
            '보안 장비 상태 변경: ' || v_device_type || ' - ' || p_operational_status
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Patrol completion function
CREATE OR REPLACE FUNCTION bms.complete_patrol_checkpoint(
    p_patrol_id UUID,
    p_company_id UUID,
    p_checkpoint_id VARCHAR(50),
    p_checkpoint_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_findings TEXT DEFAULT NULL,
    p_anomalies_found INTEGER DEFAULT 0
)
RETURNS VOID AS $$
DECLARE
    v_patrol_exists BOOLEAN;
    v_current_completed INTEGER;
    v_total_checkpoints INTEGER;
    v_completion_percentage DECIMAL(5,2);
BEGIN
    -- Verify patrol exists
    SELECT EXISTS(
        SELECT 1 FROM bms.security_patrols 
        WHERE patrol_id = p_patrol_id AND company_id = p_company_id
    ) INTO v_patrol_exists;
    
    IF NOT v_patrol_exists THEN
        RAISE EXCEPTION '지정된 보안 순찰을 찾을 수 없습니다: %', p_patrol_id;
    END IF;
    
    -- Update patrol with checkpoint completion
    UPDATE bms.security_patrols
    SET checkpoints_completed = checkpoints_completed + 1,
        anomalies_reported = anomalies_reported + p_anomalies_found,
        patrol_findings = COALESCE(patrol_findings, '') || 
                         CASE WHEN patrol_findings IS NOT NULL THEN E'\n' ELSE '' END ||
                         '[' || p_checkpoint_time::TEXT || '] ' || p_checkpoint_id || 
                         CASE WHEN p_findings IS NOT NULL THEN ': ' || p_findings ELSE '' END,
        updated_at = NOW()
    WHERE patrol_id = p_patrol_id
    RETURNING checkpoints_completed, total_checkpoints 
    INTO v_current_completed, v_total_checkpoints;
    
    -- Calculate and update completion percentage
    IF v_total_checkpoints > 0 THEN
        v_completion_percentage := (v_current_completed::DECIMAL / v_total_checkpoints) * 100;
        
        UPDATE bms.security_patrols
        SET completion_percentage = v_completion_percentage,
            patrol_status = CASE 
                WHEN v_completion_percentage >= 100 THEN 'COMPLETED'
                WHEN v_completion_percentage > 0 THEN 'IN_PROGRESS'
                ELSE patrol_status
            END
        WHERE patrol_id = p_patrol_id;
    END IF;
    
    -- Generate alert if anomalies found
    IF p_anomalies_found > 0 THEN
        PERFORM bms.generate_security_alert(
            p_company_id,
            'PATROL_ANOMALY',
            'ANOMALY_DETECTED',
            NULL,
            NULL,
            '순찰 중 이상 발견: ' || p_checkpoint_id || ' - ' || p_findings
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Visitor check-in/check-out functions
CREATE OR REPLACE FUNCTION bms.visitor_check_in(
    p_visit_id UUID,
    p_company_id UUID,
    p_actual_arrival TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_badge_number VARCHAR(50) DEFAULT NULL,
    p_escort_person_id UUID DEFAULT NULL,
    p_screening_result VARCHAR(20) DEFAULT 'PASSED'
)
RETURNS VOID AS $$
DECLARE
    v_visit_exists BOOLEAN;
    v_current_status VARCHAR(20);
BEGIN
    -- Verify visit exists and get current status
    SELECT visit_status INTO v_current_status
    FROM bms.visitor_management
    WHERE visit_id = p_visit_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '지정된 방문 기록을 찾을 수 없습니다: %', p_visit_id;
    END IF;
    
    IF v_current_status != 'SCHEDULED' THEN
        RAISE EXCEPTION '체크인할 수 없는 방문 상태입니다: %', v_current_status;
    END IF;
    
    -- Update visit with check-in information
    UPDATE bms.visitor_management
    SET actual_arrival = p_actual_arrival,
        visit_status = 'CHECKED_IN',
        check_in_completed = TRUE,
        screening_completed = TRUE,
        screening_result = p_screening_result,
        badge_number = p_badge_number,
        temporary_badge_issued = (p_badge_number IS NOT NULL),
        escort_person_id = p_escort_person_id,
        updated_at = NOW()
    WHERE visit_id = p_visit_id;
    
    -- Log access control record for check-in
    PERFORM bms.log_access_attempt(
        p_company_id,
        (SELECT device_id FROM bms.security_devices 
         WHERE device_type = 'ACCESS_READER' AND company_id = p_company_id 
         ORDER BY created_at LIMIT 1), -- Simplified - would need proper entrance device
        (SELECT zone_id FROM bms.security_zones 
         WHERE zone_type = 'ENTRANCE' AND company_id = p_company_id 
         ORDER BY created_at LIMIT 1), -- Simplified - would need proper entrance zone
        NULL,
        (SELECT visitor_name FROM bms.visitor_management WHERE visit_id = p_visit_id),
        'VISITOR',
        'MANUAL',
        'VISITOR_BADGE',
        p_badge_number,
        'GRANTED',
        'IN'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION bms.visitor_check_out(
    p_visit_id UUID,
    p_company_id UUID,
    p_actual_departure TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS VOID AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_badge_number VARCHAR(50);
BEGIN
    -- Verify visit exists and get current status
    SELECT visit_status, badge_number INTO v_current_status, v_badge_number
    FROM bms.visitor_management
    WHERE visit_id = p_visit_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '지정된 방문 기록을 찾을 수 없습니다: %', p_visit_id;
    END IF;
    
    IF v_current_status NOT IN ('CHECKED_IN', 'IN_PROGRESS') THEN
        RAISE EXCEPTION '체크아웃할 수 없는 방문 상태입니다: %', v_current_status;
    END IF;
    
    -- Update visit with check-out information
    UPDATE bms.visitor_management
    SET actual_departure = p_actual_departure,
        visit_status = 'CHECKED_OUT',
        check_out_completed = TRUE,
        updated_at = NOW()
    WHERE visit_id = p_visit_id;
    
    -- Log access control record for check-out
    PERFORM bms.log_access_attempt(
        p_company_id,
        (SELECT device_id FROM bms.security_devices 
         WHERE device_type = 'ACCESS_READER' AND company_id = p_company_id 
         ORDER BY created_at LIMIT 1), -- Simplified
        (SELECT zone_id FROM bms.security_zones 
         WHERE zone_type = 'ENTRANCE' AND company_id = p_company_id 
         ORDER BY created_at LIMIT 1), -- Simplified
        NULL,
        (SELECT visitor_name FROM bms.visitor_management WHERE visit_id = p_visit_id),
        'VISITOR',
        'MANUAL',
        'VISITOR_BADGE',
        v_badge_number,
        'GRANTED',
        'OUT'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 13. Security reporting functions
CREATE OR REPLACE FUNCTION bms.get_security_dashboard_data(
    p_company_id UUID,
    p_date_from DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_date_to DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    total_zones INTEGER,
    active_devices INTEGER,
    offline_devices INTEGER,
    access_attempts_today INTEGER,
    denied_access_today INTEGER,
    open_incidents INTEGER,
    critical_incidents INTEGER,
    scheduled_patrols_today INTEGER,
    completed_patrols_today INTEGER,
    active_visitors INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*)::INTEGER FROM bms.security_zones 
         WHERE company_id = p_company_id AND zone_status = 'ACTIVE'),
        (SELECT COUNT(*)::INTEGER FROM bms.security_devices 
         WHERE company_id = p_company_id AND operational_status = 'ONLINE'),
        (SELECT COUNT(*)::INTEGER FROM bms.security_devices 
         WHERE company_id = p_company_id AND operational_status = 'OFFLINE'),
        (SELECT COUNT(*)::INTEGER FROM bms.access_control_records 
         WHERE company_id = p_company_id AND access_time::DATE = CURRENT_DATE),
        (SELECT COUNT(*)::INTEGER FROM bms.access_control_records 
         WHERE company_id = p_company_id AND access_time::DATE = CURRENT_DATE 
         AND access_result = 'DENIED'),
        (SELECT COUNT(*)::INTEGER FROM bms.security_incidents 
         WHERE company_id = p_company_id AND incident_status IN ('OPEN', 'IN_PROGRESS')),
        (SELECT COUNT(*)::INTEGER FROM bms.security_incidents 
         WHERE company_id = p_company_id AND severity_level = 'CRITICAL' 
         AND incident_status IN ('OPEN', 'IN_PROGRESS')),
        (SELECT COUNT(*)::INTEGER FROM bms.security_patrols 
         WHERE company_id = p_company_id AND patrol_date = CURRENT_DATE),
        (SELECT COUNT(*)::INTEGER FROM bms.security_patrols 
         WHERE company_id = p_company_id AND patrol_date = CURRENT_DATE 
         AND patrol_status = 'COMPLETED'),
        (SELECT COUNT(*)::INTEGER FROM bms.visitor_management 
         WHERE company_id = p_company_id AND visit_status IN ('CHECKED_IN', 'IN_PROGRESS'));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to functions
GRANT EXECUTE ON FUNCTION bms.create_security_zone TO application_role;
GRANT EXECUTE ON FUNCTION bms.register_security_device TO application_role;
GRANT EXECUTE ON FUNCTION bms.log_access_attempt TO application_role;
GRANT EXECUTE ON FUNCTION bms.create_security_incident TO application_role;
GRANT EXECUTE ON FUNCTION bms.schedule_security_patrol TO application_role;
GRANT EXECUTE ON FUNCTION bms.register_visitor TO application_role;
GRANT EXECUTE ON FUNCTION bms.generate_security_alert TO application_role;
GRANT EXECUTE ON FUNCTION bms.assign_incident_investigator TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_zone_access TO application_role;
GRANT EXECUTE ON FUNCTION bms.update_device_status TO application_role;
GRANT EXECUTE ON FUNCTION bms.complete_patrol_checkpoint TO application_role;
GRANT EXECUTE ON FUNCTION bms.visitor_check_in TO application_role;
GRANT EXECUTE ON FUNCTION bms.visitor_check_out TO application_role;
GRANT EXECUTE ON FUNCTION bms.get_security_dashboard_data TO application_role;