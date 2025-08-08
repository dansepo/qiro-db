-- =====================================================
-- Inspection Execution Management System Tables
-- Phase 4.2.2: Inspection Execution Management
-- =====================================================

-- 1. Inspection executions table
CREATE TABLE IF NOT EXISTS bms.inspection_executions (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    schedule_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    template_id UUID NOT NULL,
    
    -- Execution information
    execution_number VARCHAR(50) NOT NULL,
    execution_date DATE NOT NULL,
    execution_start_time TIMESTAMP WITH TIME ZONE,
    execution_end_time TIMESTAMP WITH TIME ZONE,
    actual_duration_minutes INTEGER,
    
    -- Inspector information
    primary_inspector_id UUID NOT NULL,
    secondary_inspector_id UUID,
    inspector_team JSONB,
    
    -- Execution status
    execution_status VARCHAR(20) DEFAULT 'SCHEDULED',
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Environmental conditions
    weather_conditions VARCHAR(50),
    temperature_celsius DECIMAL(6,2),
    humidity_percentage DECIMAL(5,2),
    environmental_notes TEXT,
    
    -- Equipment and tools used
    tools_used JSONB,
    equipment_used JSONB,
    calibration_status JSONB,
    
    -- Safety and compliance
    safety_briefing_completed BOOLEAN DEFAULT false,
    ppe_used JSONB,
    safety_incidents JSONB,
    permit_numbers JSONB,
    
    -- Overall results
    overall_result VARCHAR(20),
    overall_score DECIMAL(5,2),
    pass_fail_result VARCHAR(10),
    
    -- Issues and findings
    issues_found INTEGER DEFAULT 0,
    critical_issues INTEGER DEFAULT 0,
    major_issues INTEGER DEFAULT 0,
    minor_issues INTEGER DEFAULT 0,
    
    -- Follow-up actions
    immediate_actions_required BOOLEAN DEFAULT false,
    follow_up_required BOOLEAN DEFAULT false,
    next_inspection_recommended_date DATE,
    
    -- Quality assurance
    reviewed_by UUID,
    review_date DATE,
    review_status VARCHAR(20) DEFAULT 'PENDING',
    review_comments TEXT,
    
    -- Documentation
    photos JSONB,
    documents JSONB,
    signatures JSONB,
    
    -- Cost tracking
    execution_cost DECIMAL(10,2) DEFAULT 0,
    labor_cost DECIMAL(10,2) DEFAULT 0,
    material_cost DECIMAL(10,2) DEFAULT 0,
    
    -- Notes and observations
    inspector_notes TEXT,
    recommendations TEXT,
    lessons_learned TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_inspection_executions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_executions_schedule FOREIGN KEY (schedule_id) REFERENCES bms.inspection_schedules(schedule_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_executions_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_executions_template FOREIGN KEY (template_id) REFERENCES bms.inspection_templates(template_id) ON DELETE RESTRICT,
    CONSTRAINT uk_inspection_executions_number UNIQUE (company_id, execution_number),
    
    -- Check constraints
    CONSTRAINT chk_execution_status CHECK (execution_status IN (
        'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'POSTPONED', 'FAILED'
    )),
    CONSTRAINT chk_overall_result CHECK (overall_result IN (
        'EXCELLENT', 'GOOD', 'SATISFACTORY', 'NEEDS_ATTENTION', 'UNSATISFACTORY', 'FAILED'
    ) OR overall_result IS NULL),
    CONSTRAINT chk_pass_fail_result CHECK (pass_fail_result IN (
        'PASS', 'FAIL', 'CONDITIONAL'
    ) OR pass_fail_result IS NULL),
    CONSTRAINT chk_review_status CHECK (review_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'NEEDS_REVISION'
    )),
    CONSTRAINT chk_completion_percentage CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    ),
    CONSTRAINT chk_execution_times CHECK (
        execution_end_time IS NULL OR execution_start_time IS NULL OR execution_end_time >= execution_start_time
    ),
    CONSTRAINT chk_cost_values CHECK (
        execution_cost >= 0 AND labor_cost >= 0 AND material_cost >= 0
    )
);

-- 2. Inspection checklist results table
CREATE TABLE IF NOT EXISTS bms.inspection_checklist_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    execution_id UUID NOT NULL,
    
    -- Checklist item information
    item_sequence INTEGER NOT NULL,
    item_code VARCHAR(50),
    item_description TEXT NOT NULL,
    item_category VARCHAR(50),
    
    -- Inspection criteria
    inspection_method VARCHAR(30),
    acceptance_criteria TEXT,
    measurement_unit VARCHAR(20),
    
    -- Results
    result_status VARCHAR(20) NOT NULL,
    result_value VARCHAR(200),
    numeric_value DECIMAL(15,4),
    pass_fail VARCHAR(10),
    
    -- Measurements and observations
    measured_values JSONB,
    tolerance_range JSONB,
    deviation_percentage DECIMAL(8,4),
    
    -- Issue details
    issue_severity VARCHAR(20),
    issue_description TEXT,
    root_cause_analysis TEXT,
    
    -- Corrective actions
    immediate_action_taken TEXT,
    corrective_action_required TEXT,
    corrective_action_deadline DATE,
    responsible_person UUID,
    
    -- Evidence and documentation
    photos JSONB,
    measurements_data JSONB,
    reference_documents JSONB,
    
    -- Inspector information
    inspected_by UUID,
    inspection_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Quality control
    verified_by UUID,
    verification_date DATE,
    verification_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Notes
    inspector_notes TEXT,
    verification_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_checklist_results_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_checklist_results_execution FOREIGN KEY (execution_id) REFERENCES bms.inspection_executions(execution_id) ON DELETE CASCADE,
    CONSTRAINT uk_checklist_results_sequence UNIQUE (execution_id, item_sequence),
    
    -- Check constraints
    CONSTRAINT chk_inspection_method CHECK (inspection_method IN (
        'VISUAL', 'MEASUREMENT', 'TESTING', 'FUNCTIONAL', 'PERFORMANCE', 'DOCUMENTATION'
    ) OR inspection_method IS NULL),
    CONSTRAINT chk_result_status CHECK (result_status IN (
        'PASS', 'FAIL', 'CONDITIONAL', 'NOT_APPLICABLE', 'NOT_TESTED', 'DEFERRED'
    )),
    CONSTRAINT chk_pass_fail_item CHECK (pass_fail IN (
        'PASS', 'FAIL', 'N/A'
    ) OR pass_fail IS NULL),
    CONSTRAINT chk_issue_severity CHECK (issue_severity IN (
        'CRITICAL', 'MAJOR', 'MINOR', 'OBSERVATION'
    ) OR issue_severity IS NULL),
    CONSTRAINT chk_verification_status CHECK (verification_status IN (
        'PENDING', 'VERIFIED', 'REJECTED', 'NEEDS_REVIEW'
    ))
);-- 3. I
nspection findings table
CREATE TABLE IF NOT EXISTS bms.inspection_findings (
    finding_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    execution_id UUID NOT NULL,
    checklist_result_id UUID,
    
    -- Finding information
    finding_number VARCHAR(50) NOT NULL,
    finding_type VARCHAR(30) NOT NULL,
    finding_category VARCHAR(30) NOT NULL,
    finding_title VARCHAR(200) NOT NULL,
    finding_description TEXT NOT NULL,
    
    -- Severity and priority
    severity_level VARCHAR(20) NOT NULL,
    priority_level VARCHAR(20) NOT NULL,
    risk_level VARCHAR(20) DEFAULT 'MEDIUM',
    
    -- Location and context
    location_description TEXT,
    equipment_affected JSONB,
    systems_affected JSONB,
    
    -- Impact assessment
    safety_impact VARCHAR(20) DEFAULT 'NONE',
    operational_impact VARCHAR(20) DEFAULT 'NONE',
    financial_impact_estimate DECIMAL(12,2) DEFAULT 0,
    environmental_impact VARCHAR(20) DEFAULT 'NONE',
    
    -- Root cause analysis
    probable_cause TEXT,
    contributing_factors JSONB,
    failure_mode VARCHAR(50),
    
    -- Recommendations
    immediate_action_required BOOLEAN DEFAULT false,
    immediate_action_description TEXT,
    long_term_recommendation TEXT,
    preventive_measures TEXT,
    
    -- Action tracking
    corrective_action_required BOOLEAN DEFAULT true,
    corrective_action_description TEXT,
    corrective_action_deadline DATE,
    assigned_to UUID,
    
    -- Status tracking
    finding_status VARCHAR(20) DEFAULT 'OPEN',
    resolution_date DATE,
    resolution_description TEXT,
    resolved_by UUID,
    
    -- Verification
    verification_required BOOLEAN DEFAULT true,
    verification_method TEXT,
    verified_by UUID,
    verification_date DATE,
    verification_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Recurrence tracking
    is_repeat_finding BOOLEAN DEFAULT false,
    previous_finding_id UUID,
    recurrence_count INTEGER DEFAULT 0,
    
    -- Documentation
    photos JSONB,
    supporting_documents JSONB,
    reference_standards JSONB,
    
    -- Cost tracking
    investigation_cost DECIMAL(10,2) DEFAULT 0,
    correction_cost DECIMAL(10,2) DEFAULT 0,
    
    -- Metadata
    identified_by UUID,
    identified_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_inspection_findings_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_findings_execution FOREIGN KEY (execution_id) REFERENCES bms.inspection_executions(execution_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_findings_checklist FOREIGN KEY (checklist_result_id) REFERENCES bms.inspection_checklist_results(result_id) ON DELETE SET NULL,
    CONSTRAINT fk_inspection_findings_previous FOREIGN KEY (previous_finding_id) REFERENCES bms.inspection_findings(finding_id) ON DELETE SET NULL,
    CONSTRAINT uk_inspection_findings_number UNIQUE (company_id, finding_number),
    
    -- Check constraints
    CONSTRAINT chk_finding_type CHECK (finding_type IN (
        'DEFECT', 'NON_COMPLIANCE', 'SAFETY_HAZARD', 'PERFORMANCE_ISSUE',
        'MAINTENANCE_NEED', 'IMPROVEMENT_OPPORTUNITY', 'OBSERVATION'
    )),
    CONSTRAINT chk_finding_category CHECK (finding_category IN (
        'STRUCTURAL', 'MECHANICAL', 'ELECTRICAL', 'SAFETY', 'ENVIRONMENTAL',
        'OPERATIONAL', 'DOCUMENTATION', 'PROCEDURAL', 'OTHER'
    )),
    CONSTRAINT chk_severity_level CHECK (severity_level IN (
        'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFORMATIONAL'
    )),
    CONSTRAINT chk_priority_level CHECK (priority_level IN (
        'URGENT', 'HIGH', 'MEDIUM', 'LOW', 'DEFERRED'
    )),
    CONSTRAINT chk_risk_level CHECK (risk_level IN (
        'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'NEGLIGIBLE'
    )),
    CONSTRAINT chk_impact_levels CHECK (
        safety_impact IN ('NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL') AND
        operational_impact IN ('NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL') AND
        environmental_impact IN ('NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    ),
    CONSTRAINT chk_finding_status CHECK (finding_status IN (
        'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'DEFERRED', 'CANCELLED'
    )),
    CONSTRAINT chk_verification_status_finding CHECK (verification_status IN (
        'PENDING', 'VERIFIED', 'REJECTED', 'NOT_REQUIRED'
    ))
);

-- 4. Inspection corrective actions table
CREATE TABLE IF NOT EXISTS bms.inspection_corrective_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    finding_id UUID NOT NULL,
    
    -- Action information
    action_number VARCHAR(50) NOT NULL,
    action_type VARCHAR(30) NOT NULL,
    action_title VARCHAR(200) NOT NULL,
    action_description TEXT NOT NULL,
    
    -- Planning
    action_priority VARCHAR(20) NOT NULL,
    estimated_cost DECIMAL(12,2) DEFAULT 0,
    estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Scheduling
    planned_start_date DATE,
    planned_completion_date DATE,
    actual_start_date DATE,
    actual_completion_date DATE,
    
    -- Resource requirements
    required_skills JSONB,
    required_materials JSONB,
    required_tools JSONB,
    required_permits JSONB,
    
    -- Assignment
    assigned_to UUID,
    assigned_team JSONB,
    responsible_manager UUID,
    
    -- Status tracking
    action_status VARCHAR(20) DEFAULT 'PLANNED',
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Implementation details
    implementation_method TEXT,
    work_instructions TEXT,
    safety_requirements TEXT,
    quality_standards TEXT,
    
    -- Results
    actual_cost DECIMAL(12,2) DEFAULT 0,
    actual_duration_hours DECIMAL(8,2) DEFAULT 0,
    effectiveness_rating DECIMAL(3,1) DEFAULT 0,
    
    -- Verification
    verification_required BOOLEAN DEFAULT true,
    verification_criteria TEXT,
    verified_by UUID,
    verification_date DATE,
    verification_result VARCHAR(20),
    
    -- Documentation
    work_photos JSONB,
    completion_documents JSONB,
    test_results JSONB,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    follow_up_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_corrective_actions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_corrective_actions_finding FOREIGN KEY (finding_id) REFERENCES bms.inspection_findings(finding_id) ON DELETE CASCADE,
    CONSTRAINT uk_corrective_actions_number UNIQUE (company_id, action_number),
    
    -- Check constraints
    CONSTRAINT chk_action_type CHECK (action_type IN (
        'REPAIR', 'REPLACEMENT', 'ADJUSTMENT', 'CLEANING', 'LUBRICATION',
        'CALIBRATION', 'TRAINING', 'PROCEDURE_UPDATE', 'MONITORING', 'OTHER'
    )),
    CONSTRAINT chk_action_priority CHECK (action_priority IN (
        'IMMEDIATE', 'URGENT', 'HIGH', 'MEDIUM', 'LOW'
    )),
    CONSTRAINT chk_action_status CHECK (action_status IN (
        'PLANNED', 'APPROVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DEFERRED'
    )),
    CONSTRAINT chk_verification_result CHECK (verification_result IN (
        'SATISFACTORY', 'UNSATISFACTORY', 'NEEDS_REWORK', 'PENDING'
    ) OR verification_result IS NULL),
    CONSTRAINT chk_completion_percentage_action CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    ),
    CONSTRAINT chk_effectiveness_rating CHECK (
        effectiveness_rating >= 0 AND effectiveness_rating <= 10
    )
);-- 5
. RLS policies and indexes
ALTER TABLE bms.inspection_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.inspection_checklist_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.inspection_findings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.inspection_corrective_actions ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY inspection_executions_isolation_policy ON bms.inspection_executions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY checklist_results_isolation_policy ON bms.inspection_checklist_results
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY inspection_findings_isolation_policy ON bms.inspection_findings
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY corrective_actions_isolation_policy ON bms.inspection_corrective_actions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for inspection_executions
CREATE INDEX IF NOT EXISTS idx_inspection_executions_company_id ON bms.inspection_executions(company_id);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_schedule_id ON bms.inspection_executions(schedule_id);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_asset_id ON bms.inspection_executions(asset_id);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_template_id ON bms.inspection_executions(template_id);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_date ON bms.inspection_executions(execution_date);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_status ON bms.inspection_executions(execution_status);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_inspector ON bms.inspection_executions(primary_inspector_id);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_result ON bms.inspection_executions(overall_result);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_number ON bms.inspection_executions(execution_number);

-- Performance indexes for inspection_checklist_results
CREATE INDEX IF NOT EXISTS idx_checklist_results_company_id ON bms.inspection_checklist_results(company_id);
CREATE INDEX IF NOT EXISTS idx_checklist_results_execution_id ON bms.inspection_checklist_results(execution_id);
CREATE INDEX IF NOT EXISTS idx_checklist_results_sequence ON bms.inspection_checklist_results(item_sequence);
CREATE INDEX IF NOT EXISTS idx_checklist_results_status ON bms.inspection_checklist_results(result_status);
CREATE INDEX IF NOT EXISTS idx_checklist_results_pass_fail ON bms.inspection_checklist_results(pass_fail);
CREATE INDEX IF NOT EXISTS idx_checklist_results_severity ON bms.inspection_checklist_results(issue_severity);
CREATE INDEX IF NOT EXISTS idx_checklist_results_inspected_by ON bms.inspection_checklist_results(inspected_by);

-- Performance indexes for inspection_findings
CREATE INDEX IF NOT EXISTS idx_inspection_findings_company_id ON bms.inspection_findings(company_id);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_execution_id ON bms.inspection_findings(execution_id);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_checklist_id ON bms.inspection_findings(checklist_result_id);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_type ON bms.inspection_findings(finding_type);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_category ON bms.inspection_findings(finding_category);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_severity ON bms.inspection_findings(severity_level);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_priority ON bms.inspection_findings(priority_level);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_status ON bms.inspection_findings(finding_status);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_assigned ON bms.inspection_findings(assigned_to);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_deadline ON bms.inspection_findings(corrective_action_deadline);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_number ON bms.inspection_findings(finding_number);

-- Performance indexes for inspection_corrective_actions
CREATE INDEX IF NOT EXISTS idx_corrective_actions_company_id ON bms.inspection_corrective_actions(company_id);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_finding_id ON bms.inspection_corrective_actions(finding_id);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_type ON bms.inspection_corrective_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_priority ON bms.inspection_corrective_actions(action_priority);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_status ON bms.inspection_corrective_actions(action_status);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_assigned ON bms.inspection_corrective_actions(assigned_to);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_start_date ON bms.inspection_corrective_actions(planned_start_date);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_completion_date ON bms.inspection_corrective_actions(planned_completion_date);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_number ON bms.inspection_corrective_actions(action_number);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_inspection_executions_asset_date ON bms.inspection_executions(asset_id, execution_date);
CREATE INDEX IF NOT EXISTS idx_inspection_executions_company_status ON bms.inspection_executions(company_id, execution_status);
CREATE INDEX IF NOT EXISTS idx_checklist_results_execution_sequence ON bms.inspection_checklist_results(execution_id, item_sequence);
CREATE INDEX IF NOT EXISTS idx_inspection_findings_company_status ON bms.inspection_findings(company_id, finding_status);
CREATE INDEX IF NOT EXISTS idx_corrective_actions_company_status ON bms.inspection_corrective_actions(company_id, action_status);

-- Updated_at triggers
CREATE TRIGGER inspection_executions_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_executions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER inspection_checklist_results_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_checklist_results
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER inspection_findings_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_findings
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER inspection_corrective_actions_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_corrective_actions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.inspection_executions IS 'Inspection executions - Records of actual inspection activities and results';
COMMENT ON TABLE bms.inspection_checklist_results IS 'Inspection checklist results - Detailed results for each checklist item';
COMMENT ON TABLE bms.inspection_findings IS 'Inspection findings - Issues and observations identified during inspections';
COMMENT ON TABLE bms.inspection_corrective_actions IS 'Inspection corrective actions - Actions taken to address inspection findings';

-- Script completion message
SELECT 'Inspection execution management system tables created successfully.' as message;