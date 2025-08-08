-- =====================================================
-- Outsourcing Work Management System
-- Phase 4.5.2: Outsourcing Work Management Tables
-- =====================================================

-- 1. Outsourcing work requests table
CREATE TABLE IF NOT EXISTS bms.outsourcing_work_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Request identification
    request_number VARCHAR(50) NOT NULL,
    request_title VARCHAR(200) NOT NULL,
    request_type VARCHAR(30) NOT NULL,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Requester information
    requester_id UUID NOT NULL,
    department VARCHAR(50),
    cost_center VARCHAR(20),
    
    -- Work details
    work_description TEXT NOT NULL,
    work_location VARCHAR(200),
    work_scope TEXT,
    technical_requirements TEXT,
    
    -- Timing
    required_start_date DATE,
    required_completion_date DATE,
    estimated_duration INTEGER, -- days
    
    -- Budget
    estimated_budget DECIMAL(15,2) DEFAULT 0,
    budget_code VARCHAR(30),
    currency_code VARCHAR(3) DEFAULT 'KRW',
    
    -- Priority and urgency
    priority_level VARCHAR(20) DEFAULT 'NORMAL',
    urgency_level VARCHAR(20) DEFAULT 'NORMAL',
    
    -- Contractor requirements
    required_contractor_category UUID,
    required_licenses JSONB,
    required_certifications JSONB,
    minimum_experience_years INTEGER DEFAULT 0,
    
    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    current_approver_id UUID,
    approval_level INTEGER DEFAULT 1,
    
    -- Status
    request_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- Documents
    request_documents JSONB,
    
    -- Notes
    request_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_outsourcing_requests_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_outsourcing_requests_requester FOREIGN KEY (requester_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_outsourcing_requests_approver FOREIGN KEY (current_approver_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_outsourcing_requests_category FOREIGN KEY (required_contractor_category) REFERENCES bms.contractor_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_outsourcing_requests_number UNIQUE (company_id, request_number),
    
    -- Check constraints
    CONSTRAINT chk_request_type_outsourcing CHECK (request_type IN (
        'MAINTENANCE', 'REPAIR', 'INSTALLATION', 'INSPECTION', 'CLEANING', 'SECURITY', 'CONSTRUCTION', 'CONSULTING'
    )),
    CONSTRAINT chk_priority_level_outsourcing CHECK (priority_level IN (
        'LOW', 'NORMAL', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_urgency_level_outsourcing CHECK (urgency_level IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_approval_status_outsourcing CHECK (approval_status IN (
        'PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'CANCELLED'
    )),
    CONSTRAINT chk_request_status_outsourcing CHECK (request_status IN (
        'DRAFT', 'SUBMITTED', 'IN_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED', 'ASSIGNED'
    )),
    CONSTRAINT chk_estimated_budget CHECK (estimated_budget >= 0),
    CONSTRAINT chk_estimated_duration CHECK (estimated_duration IS NULL OR estimated_duration > 0),
    CONSTRAINT chk_minimum_experience CHECK (minimum_experience_years >= 0),
    CONSTRAINT chk_required_dates CHECK (required_completion_date IS NULL OR required_start_date IS NULL OR required_completion_date >= required_start_date)
);

-- 2. Outsourcing work assignments table
CREATE TABLE IF NOT EXISTS bms.outsourcing_work_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Assignment identification
    assignment_number VARCHAR(50) NOT NULL,
    assignment_title VARCHAR(200) NOT NULL,
    assignment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Request reference
    request_id UUID NOT NULL,
    
    -- Contractor information
    contractor_id UUID NOT NULL,
    contractor_contact_person VARCHAR(100),
    contractor_contact_phone VARCHAR(20),
    contractor_contact_email VARCHAR(100),
    
    -- Work details
    work_description TEXT NOT NULL,
    work_location VARCHAR(200),
    work_scope TEXT,
    technical_specifications TEXT,
    
    -- Schedule
    scheduled_start_date DATE NOT NULL,
    scheduled_completion_date DATE NOT NULL,
    actual_start_date DATE,
    actual_completion_date DATE,
    
    -- Contract terms
    contract_amount DECIMAL(15,2) NOT NULL,
    payment_terms VARCHAR(200),
    performance_bond_required BOOLEAN DEFAULT FALSE,
    performance_bond_amount DECIMAL(15,2),
    warranty_period INTEGER, -- months
    
    -- Quality requirements
    quality_standards TEXT,
    inspection_requirements TEXT,
    acceptance_criteria TEXT,
    
    -- Safety requirements
    safety_requirements TEXT,
    required_safety_equipment JSONB,
    safety_briefing_required BOOLEAN DEFAULT TRUE,
    
    -- Progress tracking
    progress_percentage DECIMAL(5,2) DEFAULT 0,
    milestone_count INTEGER DEFAULT 0,
    completed_milestones INTEGER DEFAULT 0,
    
    -- Status
    assignment_status VARCHAR(20) DEFAULT 'ASSIGNED',
    
    -- Supervisor
    supervisor_id UUID,
    
    -- Documents
    contract_document_path VARCHAR(500),
    work_order_document_path VARCHAR(500),
    
    -- Notes
    assignment_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_outsourcing_assignments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_outsourcing_assignments_request FOREIGN KEY (request_id) REFERENCES bms.outsourcing_work_requests(request_id) ON DELETE RESTRICT,
    CONSTRAINT fk_outsourcing_assignments_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE RESTRICT,
    CONSTRAINT fk_outsourcing_assignments_supervisor FOREIGN KEY (supervisor_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_outsourcing_assignments_number UNIQUE (company_id, assignment_number),
    
    -- Check constraints
    CONSTRAINT chk_assignment_status CHECK (assignment_status IN (
        'ASSIGNED', 'IN_PROGRESS', 'ON_HOLD', 'COMPLETED', 'CANCELLED', 'REJECTED'
    )),
    CONSTRAINT chk_contract_amount CHECK (contract_amount >= 0),
    CONSTRAINT chk_performance_bond CHECK (
        (performance_bond_required = FALSE) OR 
        (performance_bond_required = TRUE AND performance_bond_amount > 0)
    ),
    CONSTRAINT chk_warranty_period CHECK (warranty_period IS NULL OR warranty_period >= 0),
    CONSTRAINT chk_progress_percentage CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT chk_milestone_counts CHECK (
        milestone_count >= 0 AND completed_milestones >= 0 AND 
        completed_milestones <= milestone_count
    ),
    CONSTRAINT chk_schedule_dates CHECK (scheduled_completion_date >= scheduled_start_date),
    CONSTRAINT chk_actual_dates CHECK (
        actual_completion_date IS NULL OR actual_start_date IS NULL OR 
        actual_completion_date >= actual_start_date
    )
);

-- 3. Work progress milestones table
CREATE TABLE IF NOT EXISTS bms.work_progress_milestones (
    milestone_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    assignment_id UUID NOT NULL,
    
    -- Milestone identification
    milestone_number INTEGER NOT NULL,
    milestone_name VARCHAR(200) NOT NULL,
    milestone_description TEXT,
    
    -- Schedule
    planned_date DATE NOT NULL,
    actual_date DATE,
    
    -- Progress
    milestone_percentage DECIMAL(5,2) NOT NULL,
    is_critical BOOLEAN DEFAULT FALSE,
    
    -- Deliverables
    deliverables TEXT,
    acceptance_criteria TEXT,
    
    -- Status
    milestone_status VARCHAR(20) DEFAULT 'PLANNED',
    
    -- Verification
    verified_by UUID,
    verification_date TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT,
    
    -- Documents
    milestone_documents JSONB,
    
    -- Notes
    milestone_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_milestones_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_milestones_assignment FOREIGN KEY (assignment_id) REFERENCES bms.outsourcing_work_assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_milestones_verified_by FOREIGN KEY (verified_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_milestones_number UNIQUE (assignment_id, milestone_number),
    
    -- Check constraints
    CONSTRAINT chk_milestone_status CHECK (milestone_status IN (
        'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'DELAYED', 'CANCELLED'
    )),
    CONSTRAINT chk_milestone_percentage CHECK (milestone_percentage >= 0 AND milestone_percentage <= 100)
);

-- 4. Work inspection records table
CREATE TABLE IF NOT EXISTS bms.work_inspection_records (
    inspection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    assignment_id UUID NOT NULL,
    
    -- Inspection identification
    inspection_number VARCHAR(50) NOT NULL,
    inspection_type VARCHAR(30) NOT NULL,
    inspection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Inspector information
    inspector_id UUID NOT NULL,
    inspector_name VARCHAR(100),
    inspector_qualification VARCHAR(100),
    
    -- Inspection scope
    inspection_scope TEXT NOT NULL,
    inspection_criteria TEXT,
    
    -- Results
    overall_result VARCHAR(20) NOT NULL,
    quality_score DECIMAL(5,2),
    safety_score DECIMAL(5,2),
    compliance_score DECIMAL(5,2),
    
    -- Findings
    passed_items INTEGER DEFAULT 0,
    failed_items INTEGER DEFAULT 0,
    defects_found INTEGER DEFAULT 0,
    
    -- Issues and recommendations
    major_issues TEXT,
    minor_issues TEXT,
    recommendations TEXT,
    corrective_actions_required TEXT,
    
    -- Follow-up
    reinspection_required BOOLEAN DEFAULT FALSE,
    reinspection_date DATE,
    
    -- Status
    inspection_status VARCHAR(20) DEFAULT 'COMPLETED',
    
    -- Documents
    inspection_report_path VARCHAR(500),
    photos_path JSONB,
    
    -- Notes
    inspection_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_inspections_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspections_assignment FOREIGN KEY (assignment_id) REFERENCES bms.outsourcing_work_assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspections_inspector FOREIGN KEY (inspector_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT uk_inspections_number UNIQUE (company_id, inspection_number),
    
    -- Check constraints
    CONSTRAINT chk_inspection_type CHECK (inspection_type IN (
        'INITIAL', 'PROGRESS', 'FINAL', 'QUALITY', 'SAFETY', 'COMPLIANCE', 'REINSPECTION'
    )),
    CONSTRAINT chk_overall_result CHECK (overall_result IN (
        'PASSED', 'FAILED', 'CONDITIONAL', 'PENDING'
    )),
    CONSTRAINT chk_inspection_status CHECK (inspection_status IN (
        'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT chk_inspection_scores CHECK (
        (quality_score IS NULL OR (quality_score >= 0 AND quality_score <= 100)) AND
        (safety_score IS NULL OR (safety_score >= 0 AND safety_score <= 100)) AND
        (compliance_score IS NULL OR (compliance_score >= 0 AND compliance_score <= 100))
    ),
    CONSTRAINT chk_inspection_counts CHECK (
        passed_items >= 0 AND failed_items >= 0 AND defects_found >= 0
    )
);-- 5.
 Work completion records table
CREATE TABLE IF NOT EXISTS bms.work_completion_records (
    completion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    assignment_id UUID NOT NULL,
    
    -- Completion identification
    completion_number VARCHAR(50) NOT NULL,
    completion_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Completion details
    work_completed_description TEXT NOT NULL,
    deliverables_provided TEXT,
    materials_used JSONB,
    
    -- Quality assessment
    quality_rating DECIMAL(3,2) DEFAULT 0,
    workmanship_rating DECIMAL(3,2) DEFAULT 0,
    timeliness_rating DECIMAL(3,2) DEFAULT 0,
    overall_satisfaction DECIMAL(3,2) DEFAULT 0,
    
    -- Final inspection
    final_inspection_id UUID,
    final_inspection_result VARCHAR(20),
    defects_corrected BOOLEAN DEFAULT FALSE,
    
    -- Acceptance
    accepted_by UUID,
    acceptance_date TIMESTAMP WITH TIME ZONE,
    acceptance_notes TEXT,
    
    -- Warranty
    warranty_start_date DATE,
    warranty_end_date DATE,
    warranty_terms TEXT,
    
    -- Financial
    final_amount DECIMAL(15,2),
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    payment_date TIMESTAMP WITH TIME ZONE,
    
    -- Status
    completion_status VARCHAR(20) DEFAULT 'SUBMITTED',
    
    -- Documents
    completion_report_path VARCHAR(500),
    warranty_document_path VARCHAR(500),
    handover_documents JSONB,
    
    -- Notes
    completion_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_completions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_completions_assignment FOREIGN KEY (assignment_id) REFERENCES bms.outsourcing_work_assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_completions_inspection FOREIGN KEY (final_inspection_id) REFERENCES bms.work_inspection_records(inspection_id) ON DELETE SET NULL,
    CONSTRAINT fk_completions_accepted_by FOREIGN KEY (accepted_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_completions_number UNIQUE (company_id, completion_number),
    
    -- Check constraints
    CONSTRAINT chk_final_inspection_result CHECK (final_inspection_result IN (
        'PASSED', 'FAILED', 'CONDITIONAL', 'PENDING'
    )),
    CONSTRAINT chk_completion_payment_status CHECK (payment_status IN (
        'PENDING', 'PARTIAL', 'COMPLETED', 'OVERDUE'
    )),
    CONSTRAINT chk_completion_status CHECK (completion_status IN (
        'SUBMITTED', 'UNDER_REVIEW', 'ACCEPTED', 'REJECTED', 'REWORK_REQUIRED'
    )),
    CONSTRAINT chk_completion_ratings CHECK (
        quality_rating >= 0 AND quality_rating <= 5 AND
        workmanship_rating >= 0 AND workmanship_rating <= 5 AND
        timeliness_rating >= 0 AND timeliness_rating <= 5 AND
        overall_satisfaction >= 0 AND overall_satisfaction <= 5
    ),
    CONSTRAINT chk_final_amount CHECK (final_amount IS NULL OR final_amount >= 0),
    CONSTRAINT chk_warranty_dates CHECK (
        warranty_end_date IS NULL OR warranty_start_date IS NULL OR 
        warranty_end_date >= warranty_start_date
    )
);

-- 6. Work issue tracking table
CREATE TABLE IF NOT EXISTS bms.work_issue_tracking (
    issue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    assignment_id UUID NOT NULL,
    
    -- Issue identification
    issue_number VARCHAR(50) NOT NULL,
    issue_title VARCHAR(200) NOT NULL,
    issue_type VARCHAR(30) NOT NULL,
    issue_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Issue details
    issue_description TEXT NOT NULL,
    issue_location VARCHAR(200),
    severity_level VARCHAR(20) NOT NULL,
    impact_level VARCHAR(20) NOT NULL,
    
    -- Reporting
    reported_by UUID NOT NULL,
    discovered_date DATE,
    
    -- Assignment
    assigned_to UUID,
    assigned_date TIMESTAMP WITH TIME ZONE,
    
    -- Resolution
    resolution_description TEXT,
    resolution_date TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    
    -- Root cause analysis
    root_cause TEXT,
    preventive_measures TEXT,
    
    -- Status
    issue_status VARCHAR(20) DEFAULT 'OPEN',
    
    -- Documents
    issue_photos JSONB,
    resolution_documents JSONB,
    
    -- Notes
    issue_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_issues_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_issues_assignment FOREIGN KEY (assignment_id) REFERENCES bms.outsourcing_work_assignments(assignment_id) ON DELETE CASCADE,
    CONSTRAINT fk_issues_reported_by FOREIGN KEY (reported_by) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_issues_assigned_to FOREIGN KEY (assigned_to) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_issues_resolved_by FOREIGN KEY (resolved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_issues_number UNIQUE (company_id, issue_number),
    
    -- Check constraints
    CONSTRAINT chk_issue_type CHECK (issue_type IN (
        'QUALITY', 'SAFETY', 'SCHEDULE', 'COST', 'TECHNICAL', 'COMMUNICATION', 'COMPLIANCE', 'OTHER'
    )),
    CONSTRAINT chk_severity_level CHECK (severity_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_impact_level CHECK (impact_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_issue_status CHECK (issue_status IN (
        'OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED'
    ))
);

-- 7. RLS policies and indexes
ALTER TABLE bms.outsourcing_work_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.outsourcing_work_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_progress_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_inspection_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_completion_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_issue_tracking ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY outsourcing_requests_isolation_policy ON bms.outsourcing_work_requests
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY outsourcing_assignments_isolation_policy ON bms.outsourcing_work_assignments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_milestones_isolation_policy ON bms.work_progress_milestones
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_inspections_isolation_policy ON bms.work_inspection_records
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_completions_isolation_policy ON bms.work_completion_records
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_issues_isolation_policy ON bms.work_issue_tracking
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_company_id ON bms.outsourcing_work_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_number ON bms.outsourcing_work_requests(request_number);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_requester ON bms.outsourcing_work_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_status ON bms.outsourcing_work_requests(request_status);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_type ON bms.outsourcing_work_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_priority ON bms.outsourcing_work_requests(priority_level);
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_date ON bms.outsourcing_work_requests(request_date);

CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_company_id ON bms.outsourcing_work_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_number ON bms.outsourcing_work_assignments(assignment_number);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_request ON bms.outsourcing_work_assignments(request_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_contractor ON bms.outsourcing_work_assignments(contractor_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_status ON bms.outsourcing_work_assignments(assignment_status);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_supervisor ON bms.outsourcing_work_assignments(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_dates ON bms.outsourcing_work_assignments(scheduled_start_date, scheduled_completion_date);

CREATE INDEX IF NOT EXISTS idx_work_milestones_company_id ON bms.work_progress_milestones(company_id);
CREATE INDEX IF NOT EXISTS idx_work_milestones_assignment ON bms.work_progress_milestones(assignment_id);
CREATE INDEX IF NOT EXISTS idx_work_milestones_status ON bms.work_progress_milestones(milestone_status);
CREATE INDEX IF NOT EXISTS idx_work_milestones_date ON bms.work_progress_milestones(planned_date);

CREATE INDEX IF NOT EXISTS idx_work_inspections_company_id ON bms.work_inspection_records(company_id);
CREATE INDEX IF NOT EXISTS idx_work_inspections_assignment ON bms.work_inspection_records(assignment_id);
CREATE INDEX IF NOT EXISTS idx_work_inspections_number ON bms.work_inspection_records(inspection_number);
CREATE INDEX IF NOT EXISTS idx_work_inspections_type ON bms.work_inspection_records(inspection_type);
CREATE INDEX IF NOT EXISTS idx_work_inspections_inspector ON bms.work_inspection_records(inspector_id);
CREATE INDEX IF NOT EXISTS idx_work_inspections_result ON bms.work_inspection_records(overall_result);
CREATE INDEX IF NOT EXISTS idx_work_inspections_date ON bms.work_inspection_records(inspection_date);

CREATE INDEX IF NOT EXISTS idx_work_completions_company_id ON bms.work_completion_records(company_id);
CREATE INDEX IF NOT EXISTS idx_work_completions_assignment ON bms.work_completion_records(assignment_id);
CREATE INDEX IF NOT EXISTS idx_work_completions_number ON bms.work_completion_records(completion_number);
CREATE INDEX IF NOT EXISTS idx_work_completions_status ON bms.work_completion_records(completion_status);
CREATE INDEX IF NOT EXISTS idx_work_completions_accepted_by ON bms.work_completion_records(accepted_by);
CREATE INDEX IF NOT EXISTS idx_work_completions_date ON bms.work_completion_records(completion_date);

CREATE INDEX IF NOT EXISTS idx_work_issues_company_id ON bms.work_issue_tracking(company_id);
CREATE INDEX IF NOT EXISTS idx_work_issues_assignment ON bms.work_issue_tracking(assignment_id);
CREATE INDEX IF NOT EXISTS idx_work_issues_number ON bms.work_issue_tracking(issue_number);
CREATE INDEX IF NOT EXISTS idx_work_issues_type ON bms.work_issue_tracking(issue_type);
CREATE INDEX IF NOT EXISTS idx_work_issues_status ON bms.work_issue_tracking(issue_status);
CREATE INDEX IF NOT EXISTS idx_work_issues_severity ON bms.work_issue_tracking(severity_level);
CREATE INDEX IF NOT EXISTS idx_work_issues_reported_by ON bms.work_issue_tracking(reported_by);
CREATE INDEX IF NOT EXISTS idx_work_issues_assigned_to ON bms.work_issue_tracking(assigned_to);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_outsourcing_requests_status_date ON bms.outsourcing_work_requests(request_status, request_date);
CREATE INDEX IF NOT EXISTS idx_outsourcing_assignments_contractor_status ON bms.outsourcing_work_assignments(contractor_id, assignment_status);
CREATE INDEX IF NOT EXISTS idx_work_issues_assignment_status ON bms.work_issue_tracking(assignment_id, issue_status);

-- Updated_at triggers
CREATE TRIGGER outsourcing_requests_updated_at_trigger
    BEFORE UPDATE ON bms.outsourcing_work_requests
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER outsourcing_assignments_updated_at_trigger
    BEFORE UPDATE ON bms.outsourcing_work_assignments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_milestones_updated_at_trigger
    BEFORE UPDATE ON bms.work_progress_milestones
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_inspections_updated_at_trigger
    BEFORE UPDATE ON bms.work_inspection_records
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_completions_updated_at_trigger
    BEFORE UPDATE ON bms.work_completion_records
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_issues_updated_at_trigger
    BEFORE UPDATE ON bms.work_issue_tracking
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.outsourcing_work_requests IS 'Outsourcing work requests - Initial requests for outsourced work';
COMMENT ON TABLE bms.outsourcing_work_assignments IS 'Outsourcing work assignments - Assigned work to contractors';
COMMENT ON TABLE bms.work_progress_milestones IS 'Work progress milestones - Project milestones and progress tracking';
COMMENT ON TABLE bms.work_inspection_records IS 'Work inspection records - Quality and compliance inspections';
COMMENT ON TABLE bms.work_completion_records IS 'Work completion records - Final completion and acceptance records';
COMMENT ON TABLE bms.work_issue_tracking IS 'Work issue tracking - Issues and problems during work execution';

-- Script completion message
SELECT 'Outsourcing Work Management System tables created successfully!' as status;