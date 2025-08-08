-- =====================================================
-- Safety Inspection Management System
-- Phase 4.7.1: Safety Inspection and Management Tables
-- =====================================================

-- 1. Safety inspection categories table
CREATE TABLE IF NOT EXISTS bms.safety_inspection_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Category identification
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    category_type VARCHAR(30) NOT NULL,
    
    -- Regulatory requirements
    regulatory_basis VARCHAR(200),
    inspection_frequency VARCHAR(50),
    mandatory_inspection BOOLEAN DEFAULT TRUE,
    
    -- Category hierarchy
    parent_category_id UUID,
    category_level INTEGER DEFAULT 1,
    
    -- Inspection requirements
    required_qualifications JSONB,
    required_equipment JSONB,
    inspection_duration INTEGER, -- minutes
    
    -- Compliance
    compliance_standards JSONB,
    penalty_for_non_compliance TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_safety_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.safety_inspection_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_safety_categories_code UNIQUE (company_id, category_code),
    
    -- Check constraints
    CONSTRAINT chk_category_type CHECK (category_type IN (
        'FIRE_SAFETY', 'ELECTRICAL_SAFETY', 'STRUCTURAL_SAFETY', 'ELEVATOR_SAFETY', 
        'GAS_SAFETY', 'ENVIRONMENTAL_SAFETY', 'GENERAL_SAFETY', 'EMERGENCY_PREPAREDNESS'
    )),
    CONSTRAINT chk_category_level CHECK (category_level >= 1 AND category_level <= 3),
    CONSTRAINT chk_inspection_duration CHECK (inspection_duration IS NULL OR inspection_duration > 0)
);

-- 2. Safety inspection schedules table
CREATE TABLE IF NOT EXISTS bms.safety_inspection_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Schedule identification
    schedule_name VARCHAR(200) NOT NULL,
    schedule_description TEXT,
    
    -- Category and scope
    category_id UUID NOT NULL,
    inspection_scope TEXT NOT NULL,
    
    -- Facility/Location
    building_id UUID,
    facility_id UUID,
    inspection_locations JSONB,
    
    -- Frequency and timing
    frequency_type VARCHAR(20) NOT NULL,
    frequency_value INTEGER NOT NULL,
    frequency_unit VARCHAR(20) NOT NULL,
    
    -- Schedule details
    next_inspection_date DATE NOT NULL,
    last_inspection_date DATE,
    inspection_time_start TIME,
    inspection_duration INTEGER, -- minutes
    
    -- Assignment
    assigned_inspector_id UUID,
    backup_inspector_id UUID,
    external_inspector_required BOOLEAN DEFAULT FALSE,
    external_inspector_company VARCHAR(200),
    
    -- Notification settings
    advance_notification_days INTEGER DEFAULT 7,
    notification_recipients JSONB,
    
    -- Status
    schedule_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_safety_schedules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_schedules_category FOREIGN KEY (category_id) REFERENCES bms.safety_inspection_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_safety_schedules_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_schedules_inspector FOREIGN KEY (assigned_inspector_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_schedules_backup FOREIGN KEY (backup_inspector_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_frequency_type CHECK (frequency_type IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL', 'CUSTOM'
    )),
    CONSTRAINT chk_frequency_unit CHECK (frequency_unit IN (
        'DAYS', 'WEEKS', 'MONTHS', 'YEARS'
    )),
    CONSTRAINT chk_schedule_status CHECK (schedule_status IN (
        'ACTIVE', 'INACTIVE', 'SUSPENDED', 'COMPLETED'
    )),
    CONSTRAINT chk_frequency_value CHECK (frequency_value > 0),
    CONSTRAINT chk_inspection_duration_schedule CHECK (inspection_duration IS NULL OR inspection_duration > 0),
    CONSTRAINT chk_advance_notification CHECK (advance_notification_days >= 0)
);

-- 3. Safety inspections table
CREATE TABLE IF NOT EXISTS bms.safety_inspections (
    inspection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Inspection identification
    inspection_number VARCHAR(50) NOT NULL,
    inspection_title VARCHAR(200) NOT NULL,
    inspection_date DATE NOT NULL,
    inspection_time TIME,
    
    -- Schedule reference
    schedule_id UUID,
    category_id UUID NOT NULL,
    
    -- Inspector information
    inspector_id UUID NOT NULL,
    inspector_name VARCHAR(100),
    inspector_qualification VARCHAR(200),
    external_inspector BOOLEAN DEFAULT FALSE,
    external_inspector_company VARCHAR(200),
    
    -- Inspection scope and location
    inspection_scope TEXT NOT NULL,
    building_id UUID,
    facility_id UUID,
    inspection_locations JSONB,
    
    -- Weather and conditions
    weather_conditions VARCHAR(100),
    environmental_conditions TEXT,
    
    -- Inspection results
    overall_result VARCHAR(20) NOT NULL,
    total_items_checked INTEGER DEFAULT 0,
    passed_items INTEGER DEFAULT 0,
    failed_items INTEGER DEFAULT 0,
    not_applicable_items INTEGER DEFAULT 0,
    
    -- Scoring
    safety_score DECIMAL(5,2),
    compliance_score DECIMAL(5,2),
    overall_score DECIMAL(5,2),
    
    -- Issues and findings
    critical_issues INTEGER DEFAULT 0,
    major_issues INTEGER DEFAULT 0,
    minor_issues INTEGER DEFAULT 0,
    observations INTEGER DEFAULT 0,
    
    -- Recommendations
    immediate_actions_required TEXT,
    corrective_actions_required TEXT,
    recommendations TEXT,
    
    -- Follow-up
    reinspection_required BOOLEAN DEFAULT FALSE,
    reinspection_date DATE,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    
    -- Completion
    inspection_completed BOOLEAN DEFAULT FALSE,
    completion_date TIMESTAMP WITH TIME ZONE,
    
    -- Status
    inspection_status VARCHAR(20) DEFAULT 'SCHEDULED',
    
    -- Documents and evidence
    inspection_report_path VARCHAR(500),
    photos_path JSONB,
    certificates_issued JSONB,
    
    -- Notes
    inspection_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_safety_inspections_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_inspections_schedule FOREIGN KEY (schedule_id) REFERENCES bms.safety_inspection_schedules(schedule_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_inspections_category FOREIGN KEY (category_id) REFERENCES bms.safety_inspection_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_safety_inspections_inspector FOREIGN KEY (inspector_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_safety_inspections_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT uk_safety_inspections_number UNIQUE (company_id, inspection_number),
    
    -- Check constraints
    CONSTRAINT chk_overall_result_safety CHECK (overall_result IN (
        'PASSED', 'FAILED', 'CONDITIONAL', 'PENDING', 'CANCELLED'
    )),
    CONSTRAINT chk_inspection_status_safety CHECK (inspection_status IN (
        'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'RESCHEDULED'
    )),
    CONSTRAINT chk_inspection_counts CHECK (
        total_items_checked >= 0 AND passed_items >= 0 AND failed_items >= 0 AND
        not_applicable_items >= 0 AND critical_issues >= 0 AND major_issues >= 0 AND
        minor_issues >= 0 AND observations >= 0
    ),
    CONSTRAINT chk_safety_scores CHECK (
        (safety_score IS NULL OR (safety_score >= 0 AND safety_score <= 100)) AND
        (compliance_score IS NULL OR (compliance_score >= 0 AND compliance_score <= 100)) AND
        (overall_score IS NULL OR (overall_score >= 0 AND overall_score <= 100))
    )
);

-- 4. Safety inspection items table
CREATE TABLE IF NOT EXISTS bms.safety_inspection_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    inspection_id UUID NOT NULL,
    
    -- Item identification
    item_number INTEGER NOT NULL,
    item_name VARCHAR(200) NOT NULL,
    item_description TEXT,
    item_category VARCHAR(50),
    
    -- Inspection criteria
    inspection_criteria TEXT NOT NULL,
    acceptance_criteria TEXT,
    measurement_method VARCHAR(100),
    
    -- Location
    item_location VARCHAR(200),
    equipment_id VARCHAR(100),
    
    -- Results
    inspection_result VARCHAR(20) NOT NULL,
    measured_value VARCHAR(100),
    reference_value VARCHAR(100),
    pass_fail_criteria VARCHAR(200),
    
    -- Issue classification
    issue_severity VARCHAR(20),
    issue_category VARCHAR(50),
    issue_description TEXT,
    
    -- Corrective actions
    corrective_action_required BOOLEAN DEFAULT FALSE,
    corrective_action_description TEXT,
    corrective_action_deadline DATE,
    corrective_action_responsible UUID,
    
    -- Evidence
    photos JSONB,
    measurements JSONB,
    test_results JSONB,
    
    -- Notes
    item_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_safety_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_items_inspection FOREIGN KEY (inspection_id) REFERENCES bms.safety_inspections(inspection_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_items_responsible FOREIGN KEY (corrective_action_responsible) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_safety_items_number UNIQUE (inspection_id, item_number),
    
    -- Check constraints
    CONSTRAINT chk_inspection_result_item CHECK (inspection_result IN (
        'PASS', 'FAIL', 'CONDITIONAL', 'NOT_APPLICABLE', 'NOT_TESTED'
    )),
    CONSTRAINT chk_issue_severity CHECK (issue_severity IN (
        'CRITICAL', 'MAJOR', 'MINOR', 'OBSERVATION', 'NONE'
    ))
);--
 5. Safety training records table
CREATE TABLE IF NOT EXISTS bms.safety_training_records (
    training_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Training identification
    training_number VARCHAR(50) NOT NULL,
    training_title VARCHAR(200) NOT NULL,
    training_type VARCHAR(30) NOT NULL,
    training_category VARCHAR(50) NOT NULL,
    
    -- Training details
    training_description TEXT,
    training_objectives TEXT,
    training_content JSONB,
    
    -- Schedule
    training_date DATE NOT NULL,
    training_start_time TIME,
    training_end_time TIME,
    training_duration INTEGER, -- minutes
    
    -- Location
    training_location VARCHAR(200),
    building_id UUID,
    room_number VARCHAR(50),
    
    -- Instructor information
    instructor_id UUID,
    instructor_name VARCHAR(100),
    instructor_qualification VARCHAR(200),
    external_instructor BOOLEAN DEFAULT FALSE,
    external_instructor_company VARCHAR(200),
    
    -- Participants
    target_participants JSONB,
    max_participants INTEGER,
    registered_participants INTEGER DEFAULT 0,
    attended_participants INTEGER DEFAULT 0,
    
    -- Training materials
    training_materials JSONB,
    handouts_provided BOOLEAN DEFAULT FALSE,
    certificates_issued BOOLEAN DEFAULT FALSE,
    
    -- Assessment
    assessment_required BOOLEAN DEFAULT FALSE,
    assessment_method VARCHAR(50),
    pass_score DECIMAL(5,2),
    
    -- Results
    training_effectiveness_score DECIMAL(5,2),
    participant_satisfaction_score DECIMAL(5,2),
    
    -- Status
    training_status VARCHAR(20) DEFAULT 'SCHEDULED',
    
    -- Documents
    training_report_path VARCHAR(500),
    attendance_sheet_path VARCHAR(500),
    certificates_path JSONB,
    
    -- Notes
    training_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_safety_training_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_training_instructor FOREIGN KEY (instructor_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_training_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT uk_safety_training_number UNIQUE (company_id, training_number),
    
    -- Check constraints
    CONSTRAINT chk_training_type CHECK (training_type IN (
        'FIRE_SAFETY', 'ELECTRICAL_SAFETY', 'EMERGENCY_RESPONSE', 'FIRST_AID', 
        'EVACUATION', 'GENERAL_SAFETY', 'EQUIPMENT_SAFETY', 'CHEMICAL_SAFETY'
    )),
    CONSTRAINT chk_training_status CHECK (training_status IN (
        'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'RESCHEDULED'
    )),
    CONSTRAINT chk_assessment_method CHECK (assessment_method IN (
        'WRITTEN_TEST', 'PRACTICAL_TEST', 'ORAL_TEST', 'OBSERVATION', 'NONE'
    )),
    CONSTRAINT chk_training_duration CHECK (training_duration IS NULL OR training_duration > 0),
    CONSTRAINT chk_max_participants CHECK (max_participants IS NULL OR max_participants > 0),
    CONSTRAINT chk_participant_counts CHECK (
        registered_participants >= 0 AND attended_participants >= 0 AND
        attended_participants <= registered_participants
    ),
    CONSTRAINT chk_training_scores CHECK (
        (training_effectiveness_score IS NULL OR (training_effectiveness_score >= 0 AND training_effectiveness_score <= 100)) AND
        (participant_satisfaction_score IS NULL OR (participant_satisfaction_score >= 0 AND participant_satisfaction_score <= 100)) AND
        (pass_score IS NULL OR (pass_score >= 0 AND pass_score <= 100))
    )
);

-- 6. Safety incidents table
CREATE TABLE IF NOT EXISTS bms.safety_incidents (
    incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Incident identification
    incident_number VARCHAR(50) NOT NULL,
    incident_title VARCHAR(200) NOT NULL,
    incident_type VARCHAR(30) NOT NULL,
    incident_date DATE NOT NULL,
    incident_time TIME,
    
    -- Location
    incident_location VARCHAR(200) NOT NULL,
    building_id UUID,
    floor_level INTEGER,
    room_number VARCHAR(50),
    specific_location TEXT,
    
    -- Incident details
    incident_description TEXT NOT NULL,
    incident_cause TEXT,
    contributing_factors TEXT,
    
    -- Severity and impact
    severity_level VARCHAR(20) NOT NULL,
    injury_type VARCHAR(30),
    property_damage BOOLEAN DEFAULT FALSE,
    environmental_impact BOOLEAN DEFAULT FALSE,
    
    -- People involved
    injured_persons INTEGER DEFAULT 0,
    witnesses INTEGER DEFAULT 0,
    people_evacuated INTEGER DEFAULT 0,
    
    -- Reporting
    reported_by UUID NOT NULL,
    reported_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    discovered_by UUID,
    discovery_date TIMESTAMP WITH TIME ZONE,
    
    -- Emergency response
    emergency_services_called BOOLEAN DEFAULT FALSE,
    emergency_services_type JSONB,
    response_time INTEGER, -- minutes
    
    -- Investigation
    investigation_required BOOLEAN DEFAULT TRUE,
    investigator_id UUID,
    investigation_start_date DATE,
    investigation_completion_date DATE,
    investigation_findings TEXT,
    
    -- Corrective actions
    immediate_actions_taken TEXT,
    corrective_actions_required TEXT,
    preventive_measures TEXT,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT TRUE,
    follow_up_date DATE,
    lessons_learned TEXT,
    
    -- Regulatory reporting
    regulatory_reporting_required BOOLEAN DEFAULT FALSE,
    regulatory_bodies_notified JSONB,
    regulatory_report_submitted BOOLEAN DEFAULT FALSE,
    
    -- Status
    incident_status VARCHAR(20) DEFAULT 'REPORTED',
    
    -- Documents
    incident_report_path VARCHAR(500),
    investigation_report_path VARCHAR(500),
    photos_path JSONB,
    witness_statements JSONB,
    
    -- Notes
    incident_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_safety_incidents_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_safety_incidents_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_incidents_reported_by FOREIGN KEY (reported_by) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_safety_incidents_discovered_by FOREIGN KEY (discovered_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_safety_incidents_investigator FOREIGN KEY (investigator_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_safety_incidents_number UNIQUE (company_id, incident_number),
    
    -- Check constraints
    CONSTRAINT chk_incident_type CHECK (incident_type IN (
        'FIRE', 'ELECTRICAL', 'STRUCTURAL', 'SLIP_FALL', 'EQUIPMENT_FAILURE', 
        'CHEMICAL_SPILL', 'GAS_LEAK', 'ELEVATOR', 'SECURITY_BREACH', 'OTHER'
    )),
    CONSTRAINT chk_severity_level_incident CHECK (severity_level IN (
        'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL', 'CATASTROPHIC'
    )),
    CONSTRAINT chk_injury_type CHECK (injury_type IN (
        'NONE', 'MINOR_INJURY', 'MAJOR_INJURY', 'FATALITY', 'NEAR_MISS'
    )),
    CONSTRAINT chk_incident_status CHECK (incident_status IN (
        'REPORTED', 'UNDER_INVESTIGATION', 'INVESTIGATION_COMPLETE', 'CLOSED'
    )),
    CONSTRAINT chk_incident_counts CHECK (
        injured_persons >= 0 AND witnesses >= 0 AND people_evacuated >= 0
    ),
    CONSTRAINT chk_response_time CHECK (response_time IS NULL OR response_time >= 0)
);

-- 7. RLS policies and indexes
ALTER TABLE bms.safety_inspection_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.safety_inspection_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.safety_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.safety_inspection_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.safety_training_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.safety_incidents ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY safety_categories_isolation_policy ON bms.safety_inspection_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY safety_schedules_isolation_policy ON bms.safety_inspection_schedules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY safety_inspections_isolation_policy ON bms.safety_inspections
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY safety_items_isolation_policy ON bms.safety_inspection_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY safety_training_isolation_policy ON bms.safety_training_records
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY safety_incidents_isolation_policy ON bms.safety_incidents
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_safety_categories_company_id ON bms.safety_inspection_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_categories_code ON bms.safety_inspection_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_safety_categories_type ON bms.safety_inspection_categories(category_type);
CREATE INDEX IF NOT EXISTS idx_safety_categories_active ON bms.safety_inspection_categories(is_active);

CREATE INDEX IF NOT EXISTS idx_safety_schedules_company_id ON bms.safety_inspection_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_schedules_category ON bms.safety_inspection_schedules(category_id);
CREATE INDEX IF NOT EXISTS idx_safety_schedules_next_date ON bms.safety_inspection_schedules(next_inspection_date);
CREATE INDEX IF NOT EXISTS idx_safety_schedules_inspector ON bms.safety_inspection_schedules(assigned_inspector_id);
CREATE INDEX IF NOT EXISTS idx_safety_schedules_status ON bms.safety_inspection_schedules(schedule_status);

CREATE INDEX IF NOT EXISTS idx_safety_inspections_company_id ON bms.safety_inspections(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_number ON bms.safety_inspections(inspection_number);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_schedule ON bms.safety_inspections(schedule_id);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_category ON bms.safety_inspections(category_id);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_inspector ON bms.safety_inspections(inspector_id);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_date ON bms.safety_inspections(inspection_date);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_status ON bms.safety_inspections(inspection_status);
CREATE INDEX IF NOT EXISTS idx_safety_inspections_result ON bms.safety_inspections(overall_result);

CREATE INDEX IF NOT EXISTS idx_safety_items_company_id ON bms.safety_inspection_items(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_items_inspection ON bms.safety_inspection_items(inspection_id);
CREATE INDEX IF NOT EXISTS idx_safety_items_result ON bms.safety_inspection_items(inspection_result);
CREATE INDEX IF NOT EXISTS idx_safety_items_severity ON bms.safety_inspection_items(issue_severity);

CREATE INDEX IF NOT EXISTS idx_safety_training_company_id ON bms.safety_training_records(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_training_number ON bms.safety_training_records(training_number);
CREATE INDEX IF NOT EXISTS idx_safety_training_type ON bms.safety_training_records(training_type);
CREATE INDEX IF NOT EXISTS idx_safety_training_date ON bms.safety_training_records(training_date);
CREATE INDEX IF NOT EXISTS idx_safety_training_status ON bms.safety_training_records(training_status);
CREATE INDEX IF NOT EXISTS idx_safety_training_instructor ON bms.safety_training_records(instructor_id);

CREATE INDEX IF NOT EXISTS idx_safety_incidents_company_id ON bms.safety_incidents(company_id);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_number ON bms.safety_incidents(incident_number);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_type ON bms.safety_incidents(incident_type);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_date ON bms.safety_incidents(incident_date);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_severity ON bms.safety_incidents(severity_level);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_status ON bms.safety_incidents(incident_status);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_reported_by ON bms.safety_incidents(reported_by);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_safety_inspections_category_date ON bms.safety_inspections(category_id, inspection_date);
CREATE INDEX IF NOT EXISTS idx_safety_schedules_inspector_date ON bms.safety_inspection_schedules(assigned_inspector_id, next_inspection_date);
CREATE INDEX IF NOT EXISTS idx_safety_incidents_type_severity ON bms.safety_incidents(incident_type, severity_level);

-- Updated_at triggers
CREATE TRIGGER safety_categories_updated_at_trigger
    BEFORE UPDATE ON bms.safety_inspection_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER safety_schedules_updated_at_trigger
    BEFORE UPDATE ON bms.safety_inspection_schedules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER safety_inspections_updated_at_trigger
    BEFORE UPDATE ON bms.safety_inspections
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER safety_items_updated_at_trigger
    BEFORE UPDATE ON bms.safety_inspection_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER safety_training_updated_at_trigger
    BEFORE UPDATE ON bms.safety_training_records
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER safety_incidents_updated_at_trigger
    BEFORE UPDATE ON bms.safety_incidents
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.safety_inspection_categories IS 'Safety inspection categories - Types and categories of safety inspections';
COMMENT ON TABLE bms.safety_inspection_schedules IS 'Safety inspection schedules - Scheduled safety inspections';
COMMENT ON TABLE bms.safety_inspections IS 'Safety inspections - Actual safety inspection records';
COMMENT ON TABLE bms.safety_inspection_items IS 'Safety inspection items - Individual items checked during inspections';
COMMENT ON TABLE bms.safety_training_records IS 'Safety training records - Safety training sessions and records';
COMMENT ON TABLE bms.safety_incidents IS 'Safety incidents - Safety incidents and accident reports';

-- Script completion message
SELECT 'Safety Inspection Management System tables created successfully!' as status;