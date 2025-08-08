-- =====================================================
-- Security Facility Management System
-- Phase 4.7.2: Security Facility Management Tables
-- =====================================================

-- 1. Security zones table
CREATE TABLE IF NOT EXISTS bms.security_zones (
    zone_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Zone identification
    zone_code VARCHAR(20) NOT NULL,
    zone_name VARCHAR(100) NOT NULL,
    zone_description TEXT,
    zone_type VARCHAR(30) NOT NULL,
    
    -- Location
    building_id UUID,
    floor_level INTEGER,
    zone_area DECIMAL(10,2),
    
    -- Zone hierarchy
    parent_zone_id UUID,
    zone_level INTEGER DEFAULT 1,
    zone_path VARCHAR(500),
    
    -- Security level
    security_level VARCHAR(20) NOT NULL,
    access_control_required BOOLEAN DEFAULT TRUE,
    surveillance_required BOOLEAN DEFAULT TRUE,
    patrol_required BOOLEAN DEFAULT FALSE,
    
    -- Operating hours
    operating_hours JSONB,
    restricted_hours JSONB,
    
    -- Zone manager
    zone_manager_id UUID,
    security_officer_id UUID,
    
    -- Emergency procedures
    emergency_procedures TEXT,
    evacuation_route TEXT,
    
    -- Status
    zone_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_security_zones_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_zones_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_zones_parent FOREIGN KEY (parent_zone_id) REFERENCES bms.security_zones(zone_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_zones_manager FOREIGN KEY (zone_manager_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_zones_officer FOREIGN KEY (security_officer_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_security_zones_code UNIQUE (company_id, zone_code),
    
    -- Check constraints
    CONSTRAINT chk_zone_type CHECK (zone_type IN (
        'ENTRANCE', 'LOBBY', 'CORRIDOR', 'OFFICE', 'PARKING', 'STORAGE', 'MECHANICAL', 
        'ROOFTOP', 'STAIRWELL', 'ELEVATOR', 'RESTRICTED', 'PUBLIC'
    )),
    CONSTRAINT chk_security_level CHECK (security_level IN (
        'PUBLIC', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_zone_status CHECK (zone_status IN (
        'ACTIVE', 'INACTIVE', 'MAINTENANCE', 'EMERGENCY'
    )),
    CONSTRAINT chk_zone_level CHECK (zone_level >= 1 AND zone_level <= 5)
);

-- 2. Security devices table
CREATE TABLE IF NOT EXISTS bms.security_devices (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Device identification
    device_code VARCHAR(30) NOT NULL,
    device_name VARCHAR(100) NOT NULL,
    device_type VARCHAR(30) NOT NULL,
    device_category VARCHAR(30) NOT NULL,
    
    -- Location
    zone_id UUID NOT NULL,
    building_id UUID,
    floor_level INTEGER,
    room_number VARCHAR(20),
    specific_location TEXT,
    coordinates JSONB,
    
    -- Device specifications
    manufacturer VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    firmware_version VARCHAR(50),
    
    -- Technical details
    ip_address INET,
    mac_address MACADDR,
    port_number INTEGER,
    network_settings JSONB,
    
    -- Installation
    installation_date DATE,
    installer_company VARCHAR(200),
    installation_notes TEXT,
    
    -- Warranty and maintenance
    warranty_start_date DATE,
    warranty_end_date DATE,
    maintenance_schedule VARCHAR(50),
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    
    -- Operational settings
    device_settings JSONB,
    recording_settings JSONB,
    alert_settings JSONB,
    
    -- Status
    device_status VARCHAR(20) DEFAULT 'ACTIVE',
    operational_status VARCHAR(20) DEFAULT 'ONLINE',
    last_online_time TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_security_devices_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_devices_zone FOREIGN KEY (zone_id) REFERENCES bms.security_zones(zone_id) ON DELETE RESTRICT,
    CONSTRAINT fk_security_devices_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT uk_security_devices_code UNIQUE (company_id, device_code),
    CONSTRAINT uk_security_devices_serial UNIQUE (company_id, serial_number),
    
    -- Check constraints
    CONSTRAINT chk_device_type CHECK (device_type IN (
        'CCTV_CAMERA', 'ACCESS_READER', 'MOTION_SENSOR', 'DOOR_SENSOR', 'GLASS_BREAK_SENSOR',
        'SMOKE_DETECTOR', 'PANIC_BUTTON', 'INTERCOM', 'BARRIER_GATE', 'TURNSTILE',
        'METAL_DETECTOR', 'X_RAY_MACHINE', 'BIOMETRIC_SCANNER', 'KEYPAD', 'ALARM_PANEL'
    )),
    CONSTRAINT chk_device_category CHECK (device_category IN (
        'SURVEILLANCE', 'ACCESS_CONTROL', 'INTRUSION_DETECTION', 'FIRE_SAFETY', 
        'EMERGENCY_COMMUNICATION', 'PERIMETER_SECURITY', 'SCREENING'
    )),
    CONSTRAINT chk_device_status CHECK (device_status IN (
        'ACTIVE', 'INACTIVE', 'MAINTENANCE', 'FAULTY', 'DECOMMISSIONED'
    )),
    CONSTRAINT chk_operational_status CHECK (operational_status IN (
        'ONLINE', 'OFFLINE', 'ERROR', 'MAINTENANCE', 'UNKNOWN'
    )),
    CONSTRAINT chk_maintenance_schedule CHECK (maintenance_schedule IN (
        'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL', 'AS_NEEDED'
    ))
);

-- 3. Access control records table
CREATE TABLE IF NOT EXISTS bms.access_control_records (
    record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Access attempt identification
    access_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_id UUID NOT NULL,
    zone_id UUID NOT NULL,
    
    -- Person information
    person_id UUID,
    person_name VARCHAR(100),
    person_type VARCHAR(30),
    employee_id VARCHAR(50),
    visitor_id VARCHAR(50),
    
    -- Access method
    access_method VARCHAR(30) NOT NULL,
    credential_type VARCHAR(30),
    credential_id VARCHAR(100),
    
    -- Access result
    access_result VARCHAR(20) NOT NULL,
    access_direction VARCHAR(10),
    
    -- Additional information
    purpose_of_visit TEXT,
    authorized_by UUID,
    escort_required BOOLEAN DEFAULT FALSE,
    escort_person_id UUID,
    
    -- Biometric data (if applicable)
    biometric_template_matched BOOLEAN,
    biometric_confidence_score DECIMAL(5,2),
    
    -- Photo/Video evidence
    photo_captured BOOLEAN DEFAULT FALSE,
    photo_path VARCHAR(500),
    video_clip_path VARCHAR(500),
    
    -- Anomaly detection
    anomaly_detected BOOLEAN DEFAULT FALSE,
    anomaly_type VARCHAR(50),
    anomaly_description TEXT,
    
    -- Follow-up actions
    alert_generated BOOLEAN DEFAULT FALSE,
    security_notified BOOLEAN DEFAULT FALSE,
    investigation_required BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_access_records_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_access_records_device FOREIGN KEY (device_id) REFERENCES bms.security_devices(device_id) ON DELETE RESTRICT,
    CONSTRAINT fk_access_records_zone FOREIGN KEY (zone_id) REFERENCES bms.security_zones(zone_id) ON DELETE RESTRICT,
    CONSTRAINT fk_access_records_person FOREIGN KEY (person_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_access_records_authorized_by FOREIGN KEY (authorized_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_access_records_escort FOREIGN KEY (escort_person_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_person_type CHECK (person_type IN (
        'EMPLOYEE', 'CONTRACTOR', 'VISITOR', 'DELIVERY', 'MAINTENANCE', 'EMERGENCY', 'UNKNOWN'
    )),
    CONSTRAINT chk_access_method CHECK (access_method IN (
        'CARD', 'PIN', 'BIOMETRIC', 'MOBILE', 'QR_CODE', 'MANUAL', 'EMERGENCY_OVERRIDE'
    )),
    CONSTRAINT chk_credential_type CHECK (credential_type IN (
        'ACCESS_CARD', 'PIN_CODE', 'FINGERPRINT', 'FACE_RECOGNITION', 'IRIS_SCAN', 
        'MOBILE_APP', 'QR_CODE', 'TEMPORARY_CODE'
    )),
    CONSTRAINT chk_access_result CHECK (access_result IN (
        'GRANTED', 'DENIED', 'FORCED', 'TAILGATING', 'TIMEOUT', 'ERROR'
    )),
    CONSTRAINT chk_access_direction CHECK (access_direction IN (
        'IN', 'OUT', 'UNKNOWN'
    )),
    CONSTRAINT chk_biometric_confidence CHECK (
        biometric_confidence_score IS NULL OR 
        (biometric_confidence_score >= 0 AND biometric_confidence_score <= 100)
    )
);-- 4
. Security incidents table
CREATE TABLE IF NOT EXISTS bms.security_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Incident identification
    incident_number VARCHAR(50) NOT NULL,
    incident_title VARCHAR(200) NOT NULL,
    incident_type VARCHAR(30) NOT NULL,
    incident_category VARCHAR(30) NOT NULL,
    
    -- Timing
    incident_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    detection_time TIMESTAMP WITH TIME ZONE,
    response_time TIMESTAMP WITH TIME ZONE,
    resolution_time TIMESTAMP WITH TIME ZONE,
    
    -- Location
    zone_id UUID,
    building_id UUID,
    specific_location TEXT,
    
    -- Incident details
    incident_description TEXT NOT NULL,
    incident_cause TEXT,
    
    -- Severity and impact
    severity_level VARCHAR(20) NOT NULL,
    security_impact VARCHAR(30),
    business_impact VARCHAR(30),
    
    -- Detection method
    detection_method VARCHAR(30),
    detecting_device_id UUID,
    detected_by UUID,
    
    -- People involved
    suspects_count INTEGER DEFAULT 0,
    witnesses_count INTEGER DEFAULT 0,
    affected_persons INTEGER DEFAULT 0,
    
    -- Response
    first_responder_id UUID,
    response_team JSONB,
    law_enforcement_notified BOOLEAN DEFAULT FALSE,
    emergency_services_called BOOLEAN DEFAULT FALSE,
    
    -- Investigation
    investigation_required BOOLEAN DEFAULT TRUE,
    investigator_id UUID,
    investigation_status VARCHAR(20) DEFAULT 'PENDING',
    investigation_findings TEXT,
    
    -- Evidence
    evidence_collected BOOLEAN DEFAULT FALSE,
    video_evidence_path JSONB,
    photo_evidence_path JSONB,
    other_evidence_description TEXT,
    
    -- Resolution
    resolution_description TEXT,
    corrective_actions TEXT,
    preventive_measures TEXT,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT TRUE,
    follow_up_date DATE,
    lessons_learned TEXT,
    
    -- Reporting
    reported_to_authorities BOOLEAN DEFAULT FALSE,
    authority_report_number VARCHAR(100),
    insurance_claim_filed BOOLEAN DEFAULT FALSE,
    insurance_claim_number VARCHAR(100),
    
    -- Status
    incident_status VARCHAR(20) DEFAULT 'OPEN',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_security_incidents_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_incidents_zone FOREIGN KEY (zone_id) REFERENCES bms.security_zones(zone_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_device FOREIGN KEY (detecting_device_id) REFERENCES bms.security_devices(device_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_detected_by FOREIGN KEY (detected_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_responder FOREIGN KEY (first_responder_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_investigator FOREIGN KEY (investigator_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_security_incidents_number UNIQUE (company_id, incident_number),
    
    -- Check constraints
    CONSTRAINT chk_incident_type_security CHECK (incident_type IN (
        'UNAUTHORIZED_ACCESS', 'INTRUSION', 'THEFT', 'VANDALISM', 'SUSPICIOUS_ACTIVITY',
        'VIOLENCE', 'HARASSMENT', 'DEVICE_TAMPERING', 'SYSTEM_BREACH', 'FALSE_ALARM'
    )),
    CONSTRAINT chk_incident_category_security CHECK (incident_category IN (
        'PHYSICAL_SECURITY', 'CYBER_SECURITY', 'PERSONNEL_SECURITY', 'INFORMATION_SECURITY',
        'OPERATIONAL_SECURITY', 'EMERGENCY_RESPONSE'
    )),
    CONSTRAINT chk_severity_level_security CHECK (severity_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_security_impact CHECK (security_impact IN (
        'NONE', 'MINOR', 'MODERATE', 'MAJOR', 'SEVERE'
    )),
    CONSTRAINT chk_business_impact CHECK (business_impact IN (
        'NONE', 'MINOR', 'MODERATE', 'MAJOR', 'SEVERE'
    )),
    CONSTRAINT chk_detection_method CHECK (detection_method IN (
        'AUTOMATIC', 'MANUAL', 'ALARM', 'SURVEILLANCE', 'PATROL', 'REPORT'
    )),
    CONSTRAINT chk_investigation_status_security CHECK (investigation_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'SUSPENDED', 'CLOSED'
    )),
    CONSTRAINT chk_incident_status_security CHECK (incident_status IN (
        'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED'
    )),
    CONSTRAINT chk_people_counts CHECK (
        suspects_count >= 0 AND witnesses_count >= 0 AND affected_persons >= 0
    )
);

-- 4. Security incidents table
CREATE TABLE IF NOT EXISTS bms.security_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Incident identification
    incident_number VARCHAR(50) NOT NULL,
    incident_title VARCHAR(200) NOT NULL,
    incident_type VARCHAR(30) NOT NULL,
    incident_category VARCHAR(30) NOT NULL,
    
    -- Timing
    incident_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    detection_time TIMESTAMP WITH TIME ZONE,
    response_time TIMESTAMP WITH TIME ZONE,
    resolution_time TIMESTAMP WITH TIME ZONE,
    
    -- Location
    zone_id UUID,
    building_id UUID,
    specific_location TEXT,
    
    -- Incident details
    incident_description TEXT NOT NULL,
    incident_cause TEXT,
    
    -- Severity and impact
    severity_level VARCHAR(20) NOT NULL,
    security_impact VARCHAR(30),
    business_impact VARCHAR(30),
    
    -- Detection method
    detection_method VARCHAR(30),
    detecting_device_id UUID,
    detected_by UUID,
    
    -- People involved
    suspects_count INTEGER DEFAULT 0,
    witnesses_count INTEGER DEFAULT 0,
    affected_persons INTEGER DEFAULT 0,
    
    -- Response
    first_responder_id UUID,
    response_team JSONB,
    law_enforcement_notified BOOLEAN DEFAULT FALSE,
    emergency_services_called BOOLEAN DEFAULT FALSE,
    
    -- Investigation
    investigation_required BOOLEAN DEFAULT TRUE,
    investigator_id UUID,
    investigation_status VARCHAR(20) DEFAULT 'PENDING',
    investigation_findings TEXT,
    
    -- Evidence
    evidence_collected BOOLEAN DEFAULT FALSE,
    video_evidence_path JSONB,
    photo_evidence_path JSONB,
    other_evidence_description TEXT,
    
    -- Resolution
    resolution_description TEXT,
    corrective_actions TEXT,
    preventive_measures TEXT,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT TRUE,
    follow_up_date DATE,
    lessons_learned TEXT,
    
    -- Reporting
    reported_to_authorities BOOLEAN DEFAULT FALSE,
    authority_report_number VARCHAR(100),
    insurance_claim_filed BOOLEAN DEFAULT FALSE,
    insurance_claim_number VARCHAR(100),
    
    -- Status
    incident_status VARCHAR(20) DEFAULT 'OPEN',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_security_incidents_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_incidents_zone FOREIGN KEY (zone_id) REFERENCES bms.security_zones(zone_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_device FOREIGN KEY (detecting_device_id) REFERENCES bms.security_devices(device_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_detected_by FOREIGN KEY (detected_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_responder FOREIGN KEY (first_responder_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_incidents_investigator FOREIGN KEY (investigator_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_security_incidents_number UNIQUE (company_id, incident_number),
    
    -- Check constraints
    CONSTRAINT chk_incident_type_security CHECK (incident_type IN (
        'UNAUTHORIZED_ACCESS', 'INTRUSION', 'THEFT', 'VANDALISM', 'SUSPICIOUS_ACTIVITY',
        'VIOLENCE', 'HARASSMENT', 'DEVICE_TAMPERING', 'SYSTEM_BREACH', 'FALSE_ALARM'
    )),
    CONSTRAINT chk_incident_category_security CHECK (incident_category IN (
        'PHYSICAL_SECURITY', 'CYBER_SECURITY', 'PERSONNEL_SECURITY', 'INFORMATION_SECURITY',
        'OPERATIONAL_SECURITY', 'EMERGENCY_RESPONSE'
    )),
    CONSTRAINT chk_severity_level_security CHECK (severity_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_security_impact CHECK (security_impact IN (
        'NONE', 'MINOR', 'MODERATE', 'MAJOR', 'SEVERE'
    )),
    CONSTRAINT chk_business_impact CHECK (business_impact IN (
        'NONE', 'MINOR', 'MODERATE', 'MAJOR', 'SEVERE'
    )),
    CONSTRAINT chk_detection_method CHECK (detection_method IN (
        'AUTOMATIC', 'MANUAL', 'ALARM', 'SURVEILLANCE', 'PATROL', 'REPORT'
    )),
    CONSTRAINT chk_investigation_status_security CHECK (investigation_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'SUSPENDED', 'CLOSED'
    )),
    CONSTRAINT chk_incident_status_security CHECK (incident_status IN (
        'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED'
    )),
    CONSTRAINT chk_people_counts CHECK (
        suspects_count >= 0 AND witnesses_count >= 0 AND affected_persons >= 0
    )
);

-- 5. Security patrols table
CREATE TABLE IF NOT EXISTS bms.security_patrols (
    patrol_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Patrol identification
    patrol_number VARCHAR(50) NOT NULL,
    patrol_name VARCHAR(100) NOT NULL,
    patrol_type VARCHAR(30) NOT NULL,
    
    -- Schedule
    patrol_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIME,
    actual_end_time TIME,
    
    -- Route and zones
    patrol_route JSONB NOT NULL,
    zones_to_patrol JSONB NOT NULL,
    checkpoints JSONB,
    
    -- Personnel
    patrol_officer_id UUID NOT NULL,
    backup_officer_id UUID,
    supervisor_id UUID,
    
    -- Patrol details
    patrol_instructions TEXT,
    special_attention_areas JSONB,
    equipment_required JSONB,
    
    -- Results
    checkpoints_completed INTEGER DEFAULT 0,
    total_checkpoints INTEGER DEFAULT 0,
    incidents_found INTEGER DEFAULT 0,
    anomalies_reported INTEGER DEFAULT 0,
    
    -- Findings
    patrol_findings TEXT,
    security_observations TEXT,
    maintenance_issues TEXT,
    recommendations TEXT,
    
    -- Status
    patrol_status VARCHAR(20) DEFAULT 'SCHEDULED',
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Weather and conditions
    weather_conditions VARCHAR(100),
    visibility_conditions VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_security_patrols_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_patrols_officer FOREIGN KEY (patrol_officer_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_security_patrols_backup FOREIGN KEY (backup_officer_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_patrols_supervisor FOREIGN KEY (supervisor_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_security_patrols_number UNIQUE (company_id, patrol_number),
    
    -- Check constraints
    CONSTRAINT chk_patrol_type CHECK (patrol_type IN (
        'ROUTINE', 'RANDOM', 'SPECIAL', 'EMERGENCY', 'INVESTIGATION', 'ESCORT'
    )),
    CONSTRAINT chk_patrol_status CHECK (patrol_status IN (
        'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DELAYED'
    )),
    CONSTRAINT chk_completion_percentage CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    CONSTRAINT chk_checkpoint_counts CHECK (
        checkpoints_completed >= 0 AND total_checkpoints >= 0 AND
        checkpoints_completed <= total_checkpoints
    ),
    CONSTRAINT chk_incident_counts CHECK (incidents_found >= 0 AND anomalies_reported >= 0),
    CONSTRAINT chk_scheduled_times CHECK (scheduled_end_time > scheduled_start_time)
);

-- 6. Visitor management table
CREATE TABLE IF NOT EXISTS bms.visitor_management (
    visit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Visit identification
    visit_number VARCHAR(50) NOT NULL,
    visit_type VARCHAR(30) NOT NULL,
    
    -- Visitor information
    visitor_name VARCHAR(100) NOT NULL,
    visitor_company VARCHAR(200),
    visitor_phone VARCHAR(20),
    visitor_email VARCHAR(100),
    visitor_id_type VARCHAR(30),
    visitor_id_number VARCHAR(50),
    
    -- Visit details
    visit_purpose TEXT NOT NULL,
    host_employee_id UUID,
    host_name VARCHAR(100),
    host_department VARCHAR(100),
    
    -- Timing
    scheduled_arrival TIMESTAMP WITH TIME ZONE,
    scheduled_departure TIMESTAMP WITH TIME ZONE,
    actual_arrival TIMESTAMP WITH TIME ZONE,
    actual_departure TIMESTAMP WITH TIME ZONE,
    
    -- Access permissions
    authorized_zones JSONB,
    access_level VARCHAR(20) DEFAULT 'VISITOR',
    escort_required BOOLEAN DEFAULT TRUE,
    escort_person_id UUID,
    
    -- Credentials
    temporary_badge_issued BOOLEAN DEFAULT FALSE,
    badge_number VARCHAR(50),
    access_card_issued BOOLEAN DEFAULT FALSE,
    access_card_number VARCHAR(50),
    
    -- Security screening
    security_screening_required BOOLEAN DEFAULT TRUE,
    screening_completed BOOLEAN DEFAULT FALSE,
    screening_result VARCHAR(20),
    screening_notes TEXT,
    
    -- Vehicle information
    vehicle_registration VARCHAR(20),
    parking_assigned BOOLEAN DEFAULT FALSE,
    parking_location VARCHAR(100),
    
    -- Documents and photos
    photo_taken BOOLEAN DEFAULT FALSE,
    photo_path VARCHAR(500),
    id_document_scanned BOOLEAN DEFAULT FALSE,
    id_document_path VARCHAR(500),
    
    -- Visit status
    visit_status VARCHAR(20) DEFAULT 'SCHEDULED',
    check_in_completed BOOLEAN DEFAULT FALSE,
    check_out_completed BOOLEAN DEFAULT FALSE,
    
    -- Emergency contact
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    
    -- Special requirements
    special_requirements TEXT,
    accessibility_needs TEXT,
    
    -- Notes
    visit_notes TEXT,
    security_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_visitor_management_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_visitor_management_host FOREIGN KEY (host_employee_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_visitor_management_escort FOREIGN KEY (escort_person_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_visitor_management_number UNIQUE (company_id, visit_number),
    
    -- Check constraints
    CONSTRAINT chk_visit_type CHECK (visit_type IN (
        'BUSINESS', 'INTERVIEW', 'DELIVERY', 'MAINTENANCE', 'INSPECTION', 'TOUR', 'EVENT', 'OTHER'
    )),
    CONSTRAINT chk_visitor_id_type CHECK (visitor_id_type IN (
        'NATIONAL_ID', 'PASSPORT', 'DRIVERS_LICENSE', 'EMPLOYEE_ID', 'OTHER'
    )),
    CONSTRAINT chk_access_level_visitor CHECK (access_level IN (
        'VISITOR', 'CONTRACTOR', 'VIP', 'RESTRICTED'
    )),
    CONSTRAINT chk_screening_result CHECK (screening_result IN (
        'PASSED', 'FAILED', 'CONDITIONAL', 'WAIVED'
    )),
    CONSTRAINT chk_visit_status CHECK (visit_status IN (
        'SCHEDULED', 'CHECKED_IN', 'IN_PROGRESS', 'CHECKED_OUT', 'CANCELLED', 'NO_SHOW'
    ))
);-- 7.
 RLS policies and indexes
ALTER TABLE bms.security_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.security_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.access_control_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.security_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.security_patrols ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.visitor_management ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY security_zones_isolation_policy ON bms.security_zones
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY security_devices_isolation_policy ON bms.security_devices
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY access_control_records_isolation_policy ON bms.access_control_records
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY security_incidents_isolation_policy ON bms.security_incidents
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY security_patrols_isolation_policy ON bms.security_patrols
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY visitor_management_isolation_policy ON bms.visitor_management
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_security_zones_company_id ON bms.security_zones(company_id);
CREATE INDEX IF NOT EXISTS idx_security_zones_code ON bms.security_zones(zone_code);
CREATE INDEX IF NOT EXISTS idx_security_zones_type ON bms.security_zones(zone_type);
CREATE INDEX IF NOT EXISTS idx_security_zones_level ON bms.security_zones(security_level);
CREATE INDEX IF NOT EXISTS idx_security_zones_status ON bms.security_zones(zone_status);
CREATE INDEX IF NOT EXISTS idx_security_zones_building ON bms.security_zones(building_id);

CREATE INDEX IF NOT EXISTS idx_security_devices_company_id ON bms.security_devices(company_id);
CREATE INDEX IF NOT EXISTS idx_security_devices_code ON bms.security_devices(device_code);
CREATE INDEX IF NOT EXISTS idx_security_devices_type ON bms.security_devices(device_type);
CREATE INDEX IF NOT EXISTS idx_security_devices_zone ON bms.security_devices(zone_id);
CREATE INDEX IF NOT EXISTS idx_security_devices_status ON bms.security_devices(device_status);
CREATE INDEX IF NOT EXISTS idx_security_devices_operational ON bms.security_devices(operational_status);
CREATE INDEX IF NOT EXISTS idx_security_devices_ip ON bms.security_devices(ip_address);

CREATE INDEX IF NOT EXISTS idx_access_control_company_id ON bms.access_control_records(company_id);
CREATE INDEX IF NOT EXISTS idx_access_control_time ON bms.access_control_records(access_time);
CREATE INDEX IF NOT EXISTS idx_access_control_device ON bms.access_control_records(device_id);
CREATE INDEX IF NOT EXISTS idx_access_control_zone ON bms.access_control_records(zone_id);
CREATE INDEX IF NOT EXISTS idx_access_control_person ON bms.access_control_records(person_id);
CREATE INDEX IF NOT EXISTS idx_access_control_result ON bms.access_control_records(access_result);
CREATE INDEX IF NOT EXISTS idx_access_control_method ON bms.access_control_records(access_method);
CREATE INDEX IF NOT EXISTS idx_access_control_anomaly ON bms.access_control_records(anomaly_detected);

CREATE INDEX IF NOT EXISTS idx_security_incidents_company_id ON bms.security_incidents(company_id);
CREATE INDEX IF NOT EXISTS idx_security_incidents_number ON bms.security_incidents(incident_number);
CREATE INDEX IF NOT EXISTS idx_security_incidents_time ON bms.security_incidents(incident_time);
CREATE INDEX IF NOT EXISTS idx_security_incidents_type ON bms.security_incidents(incident_type);
CREATE INDEX IF NOT EXISTS idx_security_incidents_severity ON bms.security_incidents(severity_level);
CREATE INDEX IF NOT EXISTS idx_security_incidents_status ON bms.security_incidents(incident_status);
CREATE INDEX IF NOT EXISTS idx_security_incidents_zone ON bms.security_incidents(zone_id);
CREATE INDEX IF NOT EXISTS idx_security_incidents_detection ON bms.security_incidents(detection_time);

CREATE INDEX IF NOT EXISTS idx_security_patrols_company_id ON bms.security_patrols(company_id);
CREATE INDEX IF NOT EXISTS idx_security_patrols_number ON bms.security_patrols(patrol_number);
CREATE INDEX IF NOT EXISTS idx_security_patrols_date ON bms.security_patrols(patrol_date);
CREATE INDEX IF NOT EXISTS idx_security_patrols_officer ON bms.security_patrols(patrol_officer_id);
CREATE INDEX IF NOT EXISTS idx_security_patrols_status ON bms.security_patrols(patrol_status);
CREATE INDEX IF NOT EXISTS idx_security_patrols_type ON bms.security_patrols(patrol_type);

CREATE INDEX IF NOT EXISTS idx_visitor_management_company_id ON bms.visitor_management(company_id);
CREATE INDEX IF NOT EXISTS idx_visitor_management_number ON bms.visitor_management(visit_number);
CREATE INDEX IF NOT EXISTS idx_visitor_management_name ON bms.visitor_management(visitor_name);
CREATE INDEX IF NOT EXISTS idx_visitor_management_arrival ON bms.visitor_management(scheduled_arrival);
CREATE INDEX IF NOT EXISTS idx_visitor_management_host ON bms.visitor_management(host_employee_id);
CREATE INDEX IF NOT EXISTS idx_visitor_management_status ON bms.visitor_management(visit_status);
CREATE INDEX IF NOT EXISTS idx_visitor_management_type ON bms.visitor_management(visit_type);

-- Composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_access_control_time_device ON bms.access_control_records(access_time, device_id);
CREATE INDEX IF NOT EXISTS idx_access_control_person_time ON bms.access_control_records(person_id, access_time);
CREATE INDEX IF NOT EXISTS idx_security_incidents_time_severity ON bms.security_incidents(incident_time, severity_level);
CREATE INDEX IF NOT EXISTS idx_security_patrols_date_officer ON bms.security_patrols(patrol_date, patrol_officer_id);
CREATE INDEX IF NOT EXISTS idx_visitor_management_arrival_status ON bms.visitor_management(scheduled_arrival, visit_status);

-- JSONB indexes for better performance on JSON queries
CREATE INDEX IF NOT EXISTS idx_security_zones_operating_hours ON bms.security_zones USING GIN (operating_hours);
CREATE INDEX IF NOT EXISTS idx_security_devices_settings ON bms.security_devices USING GIN (device_settings);
CREATE INDEX IF NOT EXISTS idx_security_patrols_route ON bms.security_patrols USING GIN (patrol_route);
CREATE INDEX IF NOT EXISTS idx_visitor_management_zones ON bms.visitor_management USING GIN (authorized_zones);

-- Comments for documentation
COMMENT ON TABLE bms.security_zones IS '보안 구역 관리 - 건물 내 보안 구역 정의 및 관리';
COMMENT ON TABLE bms.security_devices IS '보안 장비 관리 - CCTV, 출입통제 등 보안 장비 정보';
COMMENT ON TABLE bms.access_control_records IS '출입 통제 기록 - 모든 출입 시도 및 결과 기록';
COMMENT ON TABLE bms.security_incidents IS '보안 사고 관리 - 보안 관련 사고 및 대응 기록';
COMMENT ON TABLE bms.security_patrols IS '보안 순찰 관리 - 보안 순찰 계획 및 실행 기록';
COMMENT ON TABLE bms.visitor_management IS '방문자 관리 - 방문자 등록, 출입 관리';

-- Column comments for key fields
COMMENT ON COLUMN bms.security_zones.zone_code IS '구역 코드 (예: SEC-001, ENT-001)';
COMMENT ON COLUMN bms.security_zones.security_level IS '보안 등급: PUBLIC, LOW, MEDIUM, HIGH, CRITICAL';
COMMENT ON COLUMN bms.security_devices.device_type IS '장비 유형: CCTV_CAMERA, ACCESS_READER, MOTION_SENSOR 등';
COMMENT ON COLUMN bms.access_control_records.access_result IS '출입 결과: GRANTED, DENIED, FORCED, TAILGATING 등';
COMMENT ON COLUMN bms.security_incidents.severity_level IS '심각도: LOW, MEDIUM, HIGH, CRITICAL';
COMMENT ON COLUMN bms.security_patrols.patrol_type IS '순찰 유형: ROUTINE, RANDOM, SPECIAL, EMERGENCY 등';
COMMENT ON COLUMN bms.visitor_management.visit_status IS '방문 상태: SCHEDULED, CHECKED_IN, IN_PROGRESS, CHECKED_OUT 등';

-- Trigger functions for automatic updates
CREATE OR REPLACE FUNCTION bms.update_security_zone_path()
RETURNS TRIGGER AS $$
BEGIN
    -- Update zone path when parent changes
    IF NEW.parent_zone_id IS NOT NULL THEN
        SELECT COALESCE(zone_path, '') || '/' || NEW.zone_code
        INTO NEW.zone_path
        FROM bms.security_zones
        WHERE zone_id = NEW.parent_zone_id;
    ELSE
        NEW.zone_path := NEW.zone_code;
    END IF;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bms.generate_incident_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate incident number if not provided
    IF NEW.incident_number IS NULL OR NEW.incident_number = '' THEN
        NEW.incident_number := 'INC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                              LPAD(NEXTVAL('bms.incident_number_seq')::TEXT, 4, '0');
    END IF;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bms.generate_patrol_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate patrol number if not provided
    IF NEW.patrol_number IS NULL OR NEW.patrol_number = '' THEN
        NEW.patrol_number := 'PAT-' || TO_CHAR(NEW.patrol_date, 'YYYYMMDD') || '-' || 
                            LPAD(NEXTVAL('bms.patrol_number_seq')::TEXT, 3, '0');
    END IF;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bms.generate_visit_number()
RETURNS TRIGGER AS $$
BEGIN
    -- Generate visit number if not provided
    IF NEW.visit_number IS NULL OR NEW.visit_number = '' THEN
        NEW.visit_number := 'VIS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                           LPAD(NEXTVAL('bms.visit_number_seq')::TEXT, 4, '0');
    END IF;
    
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create sequences for number generation
CREATE SEQUENCE IF NOT EXISTS bms.incident_number_seq START 1;
CREATE SEQUENCE IF NOT EXISTS bms.patrol_number_seq START 1;
CREATE SEQUENCE IF NOT EXISTS bms.visit_number_seq START 1;

-- Create triggers
CREATE TRIGGER trg_security_zones_path
    BEFORE INSERT OR UPDATE ON bms.security_zones
    FOR EACH ROW EXECUTE FUNCTION bms.update_security_zone_path();

CREATE TRIGGER trg_security_incidents_number
    BEFORE INSERT OR UPDATE ON bms.security_incidents
    FOR EACH ROW EXECUTE FUNCTION bms.generate_incident_number();

CREATE TRIGGER trg_security_patrols_number
    BEFORE INSERT OR UPDATE ON bms.security_patrols
    FOR EACH ROW EXECUTE FUNCTION bms.generate_patrol_number();

CREATE TRIGGER trg_visitor_management_number
    BEFORE INSERT OR UPDATE ON bms.visitor_management
    FOR EACH ROW EXECUTE FUNCTION bms.generate_visit_number();

-- Update triggers for timestamp management
CREATE TRIGGER trg_security_zones_updated_at
    BEFORE UPDATE ON bms.security_zones
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trg_security_devices_updated_at
    BEFORE UPDATE ON bms.security_devices
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trg_security_incidents_updated_at
    BEFORE UPDATE ON bms.security_incidents
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trg_security_patrols_updated_at
    BEFORE UPDATE ON bms.security_patrols
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trg_visitor_management_updated_at
    BEFORE UPDATE ON bms.visitor_management
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.security_zones TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.security_devices TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.access_control_records TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.security_incidents TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.security_patrols TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.visitor_management TO application_role;

GRANT USAGE ON SEQUENCE bms.incident_number_seq TO application_role;
GRANT USAGE ON SEQUENCE bms.patrol_number_seq TO application_role;
GRANT USAGE ON SEQUENCE bms.visit_number_seq TO application_role;