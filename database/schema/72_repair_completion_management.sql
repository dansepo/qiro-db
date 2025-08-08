-- =====================================================
-- Repair Completion Management System
-- Phase 4.3.3: Repair Completion Management Tables
-- =====================================================

-- 1. Work completion inspections table
CREATE TABLE IF NOT EXISTS bms.work_completion_inspections (
    inspection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Inspection details
    inspection_type VARCHAR(30) NOT NULL,
    inspection_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    inspector_id UUID NOT NULL,
    inspector_role VARCHAR(30) NOT NULL,
    
    -- Inspection criteria
    inspection_checklist JSONB,
    quality_standards JSONB,
    safety_requirements JSONB,
    
    -- Inspection results
    overall_result VARCHAR(20) NOT NULL,
    quality_score DECIMAL(3,1) DEFAULT 0,
    safety_compliance_score DECIMAL(3,1) DEFAULT 0,
    workmanship_score DECIMAL(3,1) DEFAULT 0,
    
    -- Detailed findings
    passed_items JSONB,
    failed_items JSONB,
    defects_found JSONB,
    improvement_areas JSONB,
    
    -- Inspector notes
    inspection_notes TEXT,
    recommendations TEXT,
    corrective_actions_required TEXT,
    
    -- Follow-up requirements
    requires_rework BOOLEAN DEFAULT false,
    rework_deadline DATE,
    requires_reinspection BOOLEAN DEFAULT false,
    reinspection_date DATE,
    
    -- Approval status
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Documentation
    inspection_photos JSONB,
    inspection_documents JSONB,
    test_results JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_completion_inspections_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_completion_inspections_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_inspection_type CHECK (inspection_type IN (
        'INITIAL_INSPECTION', 'QUALITY_CHECK', 'SAFETY_INSPECTION', 
        'FINAL_INSPECTION', 'REINSPECTION', 'COMPLIANCE_CHECK'
    )),
    CONSTRAINT chk_inspector_role CHECK (inspector_role IN (
        'SUPERVISOR', 'QUALITY_INSPECTOR', 'SAFETY_INSPECTOR', 
        'TECHNICAL_LEAD', 'EXTERNAL_INSPECTOR', 'CUSTOMER_REP'
    )),
    CONSTRAINT chk_inspection_result CHECK (overall_result IN (
        'PASSED', 'FAILED', 'CONDITIONAL_PASS', 'REQUIRES_REWORK', 'PENDING'
    )),
    CONSTRAINT chk_approval_status_inspection CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'REQUIRES_REVISION'
    )),
    CONSTRAINT chk_inspection_scores CHECK (
        quality_score >= 0 AND quality_score <= 10 AND
        safety_compliance_score >= 0 AND safety_compliance_score <= 10 AND
        workmanship_score >= 0 AND workmanship_score <= 10
    )
);

-- 2. Work completion reports table
CREATE TABLE IF NOT EXISTS bms.work_completion_reports (
    completion_report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Report details
    report_number VARCHAR(50) NOT NULL,
    report_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_by UUID NOT NULL,
    supervised_by UUID,
    
    -- Work summary
    work_summary TEXT NOT NULL,
    work_performed TEXT NOT NULL,
    materials_used JSONB,
    tools_used JSONB,
    
    -- Time and cost tracking
    total_hours_worked DECIMAL(8,2) NOT NULL,
    labor_cost DECIMAL(12,2) DEFAULT 0,
    material_cost DECIMAL(12,2) DEFAULT 0,
    equipment_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Quality metrics
    work_quality_rating DECIMAL(3,1) DEFAULT 0,
    customer_satisfaction DECIMAL(3,1) DEFAULT 0,
    completion_timeliness DECIMAL(3,1) DEFAULT 0,
    
    -- Technical details
    technical_specifications_met BOOLEAN DEFAULT true,
    safety_standards_followed BOOLEAN DEFAULT true,
    environmental_compliance BOOLEAN DEFAULT true,
    
    -- Issues and resolutions
    issues_encountered TEXT,
    resolutions_applied TEXT,
    lessons_learned TEXT,
    
    -- Testing and validation
    tests_performed JSONB,
    test_results JSONB,
    validation_criteria_met BOOLEAN DEFAULT true,
    
    -- Warranty and guarantees
    warranty_period_months INTEGER DEFAULT 0,
    warranty_terms TEXT,
    guarantee_conditions TEXT,
    
    -- Follow-up requirements
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_schedule JSONB,
    maintenance_recommendations TEXT,
    
    -- Customer handover
    customer_handover_date TIMESTAMP WITH TIME ZONE,
    customer_acceptance BOOLEAN DEFAULT false,
    customer_signature TEXT,
    customer_feedback TEXT,
    
    -- Documentation
    completion_photos JSONB,
    technical_drawings JSONB,
    certificates JSONB,
    manuals_provided JSONB,
    
    -- Report status
    report_status VARCHAR(20) DEFAULT 'DRAFT',
    submitted_date TIMESTAMP WITH TIME ZONE,
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_completion_reports_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_completion_reports_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT uk_completion_reports_number UNIQUE (company_id, report_number),
    
    -- Check constraints
    CONSTRAINT chk_report_status CHECK (report_status IN (
        'DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'FINALIZED'
    )),
    CONSTRAINT chk_completion_ratings CHECK (
        work_quality_rating >= 0 AND work_quality_rating <= 10 AND
        customer_satisfaction >= 0 AND customer_satisfaction <= 10 AND
        completion_timeliness >= 0 AND completion_timeliness <= 10
    ),
    CONSTRAINT chk_cost_values_completion CHECK (
        labor_cost >= 0 AND material_cost >= 0 AND 
        equipment_cost >= 0 AND total_cost >= 0
    ),
    CONSTRAINT chk_warranty_period CHECK (warranty_period_months >= 0)
);-
- 3. Cost settlements table
CREATE TABLE IF NOT EXISTS bms.work_cost_settlements (
    settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Settlement details
    settlement_number VARCHAR(50) NOT NULL,
    settlement_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    settlement_type VARCHAR(20) NOT NULL,
    
    -- Cost breakdown
    estimated_labor_cost DECIMAL(12,2) DEFAULT 0,
    actual_labor_cost DECIMAL(12,2) DEFAULT 0,
    estimated_material_cost DECIMAL(12,2) DEFAULT 0,
    actual_material_cost DECIMAL(12,2) DEFAULT 0,
    estimated_equipment_cost DECIMAL(12,2) DEFAULT 0,
    actual_equipment_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Additional costs
    overtime_cost DECIMAL(12,2) DEFAULT 0,
    emergency_surcharge DECIMAL(12,2) DEFAULT 0,
    contractor_fees DECIMAL(12,2) DEFAULT 0,
    miscellaneous_costs DECIMAL(12,2) DEFAULT 0,
    
    -- Total costs
    total_estimated_cost DECIMAL(12,2) DEFAULT 0,
    total_actual_cost DECIMAL(12,2) DEFAULT 0,
    cost_variance DECIMAL(12,2) DEFAULT 0,
    variance_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Budget information
    approved_budget DECIMAL(12,2) DEFAULT 0,
    budget_utilization_percentage DECIMAL(5,2) DEFAULT 0,
    budget_variance DECIMAL(12,2) DEFAULT 0,
    
    -- Payment details
    payment_method VARCHAR(20),
    payment_terms VARCHAR(100),
    payment_due_date DATE,
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Approval workflow
    requires_approval BOOLEAN DEFAULT false,
    approval_threshold DECIMAL(12,2) DEFAULT 0,
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Variance analysis
    variance_reason TEXT,
    variance_justification TEXT,
    corrective_actions TEXT,
    
    -- Documentation
    receipts JSONB,
    invoices JSONB,
    supporting_documents JSONB,
    
    -- Settlement status
    settlement_status VARCHAR(20) DEFAULT 'DRAFT',
    finalized_by UUID,
    finalized_date TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_cost_settlements_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_cost_settlements_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT uk_cost_settlements_number UNIQUE (company_id, settlement_number),
    
    -- Check constraints
    CONSTRAINT chk_settlement_type CHECK (settlement_type IN (
        'INTERNAL', 'CONTRACTOR', 'EMERGENCY', 'WARRANTY', 'INSURANCE'
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'PENDING', 'APPROVED', 'PAID', 'OVERDUE', 'DISPUTED', 'CANCELLED'
    )),
    CONSTRAINT chk_settlement_status CHECK (settlement_status IN (
        'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED', 'FINALIZED'
    )),
    CONSTRAINT chk_cost_values_settlement CHECK (
        estimated_labor_cost >= 0 AND actual_labor_cost >= 0 AND
        estimated_material_cost >= 0 AND actual_material_cost >= 0 AND
        estimated_equipment_cost >= 0 AND actual_equipment_cost >= 0 AND
        total_estimated_cost >= 0 AND total_actual_cost >= 0 AND
        approved_budget >= 0
    )
);

-- 4. Prevention measures table
CREATE TABLE IF NOT EXISTS bms.prevention_measures (
    measure_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID,
    fault_report_id UUID,
    
    -- Measure identification
    measure_code VARCHAR(20) NOT NULL,
    measure_title VARCHAR(200) NOT NULL,
    measure_description TEXT NOT NULL,
    
    -- Root cause analysis
    root_cause_category VARCHAR(30) NOT NULL,
    root_cause_description TEXT NOT NULL,
    contributing_factors JSONB,
    
    -- Prevention strategy
    prevention_type VARCHAR(30) NOT NULL,
    prevention_category VARCHAR(30) NOT NULL,
    implementation_approach TEXT,
    
    -- Measure details
    preventive_actions JSONB NOT NULL,
    corrective_actions JSONB,
    monitoring_requirements JSONB,
    
    -- Implementation planning
    implementation_priority VARCHAR(20) NOT NULL,
    estimated_cost DECIMAL(12,2) DEFAULT 0,
    estimated_duration_days INTEGER DEFAULT 0,
    required_resources JSONB,
    
    -- Responsibility and timeline
    responsible_person UUID,
    responsible_department VARCHAR(50),
    target_start_date DATE,
    target_completion_date DATE,
    
    -- Implementation tracking
    implementation_status VARCHAR(20) DEFAULT 'PLANNED',
    actual_start_date DATE,
    actual_completion_date DATE,
    implementation_notes TEXT,
    
    -- Effectiveness measurement
    success_criteria JSONB,
    measurement_methods JSONB,
    effectiveness_rating DECIMAL(3,1) DEFAULT 0,
    
    -- Review and monitoring
    review_frequency VARCHAR(20),
    next_review_date DATE,
    monitoring_indicators JSONB,
    
    -- Impact assessment
    expected_impact TEXT,
    actual_impact TEXT,
    cost_benefit_analysis TEXT,
    
    -- Documentation
    supporting_documents JSONB,
    implementation_photos JSONB,
    training_materials JSONB,
    
    -- Approval and status
    approval_required BOOLEAN DEFAULT false,
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    measure_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_prevention_measures_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_prevention_measures_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE SET NULL,
    CONSTRAINT fk_prevention_measures_fault_report FOREIGN KEY (fault_report_id) REFERENCES bms.fault_reports(report_id) ON DELETE SET NULL,
    CONSTRAINT uk_prevention_measures_code UNIQUE (company_id, measure_code),
    
    -- Check constraints
    CONSTRAINT chk_root_cause_category CHECK (root_cause_category IN (
        'DESIGN_FLAW', 'MATERIAL_DEFECT', 'INSTALLATION_ERROR', 'MAINTENANCE_NEGLECT',
        'OPERATOR_ERROR', 'ENVIRONMENTAL_FACTOR', 'WEAR_AND_TEAR', 'EXTERNAL_DAMAGE', 'OTHER'
    )),
    CONSTRAINT chk_prevention_type CHECK (prevention_type IN (
        'DESIGN_IMPROVEMENT', 'PROCESS_CHANGE', 'TRAINING', 'MAINTENANCE_ENHANCEMENT',
        'MONITORING_SYSTEM', 'QUALITY_CONTROL', 'SAFETY_MEASURE', 'POLICY_UPDATE'
    )),
    CONSTRAINT chk_prevention_category CHECK (prevention_category IN (
        'TECHNICAL', 'PROCEDURAL', 'TRAINING', 'MONITORING', 'POLICY', 'ENVIRONMENTAL'
    )),
    CONSTRAINT chk_implementation_priority CHECK (implementation_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL'
    )),
    CONSTRAINT chk_implementation_status CHECK (implementation_status IN (
        'PLANNED', 'IN_PROGRESS', 'COMPLETED', 'ON_HOLD', 'CANCELLED', 'DEFERRED'
    )),
    CONSTRAINT chk_measure_status CHECK (measure_status IN (
        'ACTIVE', 'INACTIVE', 'UNDER_REVIEW', 'SUPERSEDED', 'CANCELLED'
    )),
    CONSTRAINT chk_effectiveness_rating CHECK (effectiveness_rating >= 0 AND effectiveness_rating <= 10),
    CONSTRAINT chk_prevention_cost CHECK (estimated_cost >= 0)
);-- 5. 
Work warranties table
CREATE TABLE IF NOT EXISTS bms.work_warranties (
    warranty_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Warranty details
    warranty_number VARCHAR(50) NOT NULL,
    warranty_type VARCHAR(30) NOT NULL,
    warranty_provider VARCHAR(100) NOT NULL,
    
    -- Coverage details
    warranty_scope TEXT NOT NULL,
    covered_components JSONB,
    excluded_items JSONB,
    coverage_limitations TEXT,
    
    -- Warranty period
    warranty_start_date DATE NOT NULL,
    warranty_end_date DATE NOT NULL,
    warranty_duration_months INTEGER NOT NULL,
    
    -- Terms and conditions
    warranty_terms TEXT NOT NULL,
    maintenance_requirements TEXT,
    usage_conditions TEXT,
    void_conditions TEXT,
    
    -- Contact information
    warranty_contact_person VARCHAR(100),
    warranty_contact_phone VARCHAR(20),
    warranty_contact_email VARCHAR(100),
    service_hotline VARCHAR(20),
    
    -- Claim process
    claim_procedure TEXT,
    required_documentation JSONB,
    response_time_hours INTEGER DEFAULT 24,
    resolution_time_days INTEGER DEFAULT 7,
    
    -- Status tracking
    warranty_status VARCHAR(20) DEFAULT 'ACTIVE',
    claims_count INTEGER DEFAULT 0,
    last_claim_date DATE,
    
    -- Financial details
    warranty_cost DECIMAL(12,2) DEFAULT 0,
    deductible_amount DECIMAL(12,2) DEFAULT 0,
    coverage_limit DECIMAL(12,2),
    
    -- Documentation
    warranty_certificate JSONB,
    terms_document JSONB,
    installation_certificate JSONB,
    
    -- Notifications
    expiry_notification_sent BOOLEAN DEFAULT false,
    renewal_notification_sent BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_warranties_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_warranties_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT uk_work_warranties_number UNIQUE (company_id, warranty_number),
    
    -- Check constraints
    CONSTRAINT chk_warranty_type CHECK (warranty_type IN (
        'MANUFACTURER', 'CONTRACTOR', 'EXTENDED', 'SERVICE', 'PARTS_ONLY', 'LABOR_ONLY', 'COMPREHENSIVE'
    )),
    CONSTRAINT chk_warranty_status CHECK (warranty_status IN (
        'ACTIVE', 'EXPIRED', 'VOIDED', 'CLAIMED', 'SUSPENDED', 'TRANSFERRED'
    )),
    CONSTRAINT chk_warranty_dates CHECK (warranty_end_date > warranty_start_date),
    CONSTRAINT chk_warranty_duration CHECK (warranty_duration_months > 0),
    CONSTRAINT chk_warranty_costs CHECK (
        warranty_cost >= 0 AND deductible_amount >= 0 AND
        (coverage_limit IS NULL OR coverage_limit > 0)
    )
);

-- 6. RLS policies and indexes
ALTER TABLE bms.work_completion_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_completion_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_cost_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.prevention_measures ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_warranties ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY completion_inspections_isolation_policy ON bms.work_completion_inspections
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY completion_reports_isolation_policy ON bms.work_completion_reports
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY cost_settlements_isolation_policy ON bms.work_cost_settlements
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY prevention_measures_isolation_policy ON bms.prevention_measures
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_warranties_isolation_policy ON bms.work_warranties
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for work_completion_inspections
CREATE INDEX IF NOT EXISTS idx_completion_inspections_company_id ON bms.work_completion_inspections(company_id);
CREATE INDEX IF NOT EXISTS idx_completion_inspections_work_order ON bms.work_completion_inspections(work_order_id);
CREATE INDEX IF NOT EXISTS idx_completion_inspections_type ON bms.work_completion_inspections(inspection_type);
CREATE INDEX IF NOT EXISTS idx_completion_inspections_result ON bms.work_completion_inspections(overall_result);
CREATE INDEX IF NOT EXISTS idx_completion_inspections_inspector ON bms.work_completion_inspections(inspector_id);
CREATE INDEX IF NOT EXISTS idx_completion_inspections_date ON bms.work_completion_inspections(inspection_date);

-- Performance indexes for work_completion_reports
CREATE INDEX IF NOT EXISTS idx_completion_reports_company_id ON bms.work_completion_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_completion_reports_work_order ON bms.work_completion_reports(work_order_id);
CREATE INDEX IF NOT EXISTS idx_completion_reports_number ON bms.work_completion_reports(report_number);
CREATE INDEX IF NOT EXISTS idx_completion_reports_status ON bms.work_completion_reports(report_status);
CREATE INDEX IF NOT EXISTS idx_completion_reports_date ON bms.work_completion_reports(report_date);
CREATE INDEX IF NOT EXISTS idx_completion_reports_completed_by ON bms.work_completion_reports(completed_by);

-- Performance indexes for work_cost_settlements
CREATE INDEX IF NOT EXISTS idx_cost_settlements_company_id ON bms.work_cost_settlements(company_id);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_work_order ON bms.work_cost_settlements(work_order_id);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_number ON bms.work_cost_settlements(settlement_number);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_type ON bms.work_cost_settlements(settlement_type);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_status ON bms.work_cost_settlements(settlement_status);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_date ON bms.work_cost_settlements(settlement_date);

-- Performance indexes for prevention_measures
CREATE INDEX IF NOT EXISTS idx_prevention_measures_company_id ON bms.prevention_measures(company_id);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_work_order ON bms.prevention_measures(work_order_id);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_fault_report ON bms.prevention_measures(fault_report_id);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_code ON bms.prevention_measures(measure_code);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_category ON bms.prevention_measures(root_cause_category);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_status ON bms.prevention_measures(implementation_status);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_priority ON bms.prevention_measures(implementation_priority);

-- Performance indexes for work_warranties
CREATE INDEX IF NOT EXISTS idx_work_warranties_company_id ON bms.work_warranties(company_id);
CREATE INDEX IF NOT EXISTS idx_work_warranties_work_order ON bms.work_warranties(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_warranties_number ON bms.work_warranties(warranty_number);
CREATE INDEX IF NOT EXISTS idx_work_warranties_type ON bms.work_warranties(warranty_type);
CREATE INDEX IF NOT EXISTS idx_work_warranties_status ON bms.work_warranties(warranty_status);
CREATE INDEX IF NOT EXISTS idx_work_warranties_start_date ON bms.work_warranties(warranty_start_date);
CREATE INDEX IF NOT EXISTS idx_work_warranties_end_date ON bms.work_warranties(warranty_end_date);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_completion_inspections_work_result ON bms.work_completion_inspections(work_order_id, overall_result);
CREATE INDEX IF NOT EXISTS idx_completion_reports_work_status ON bms.work_completion_reports(work_order_id, report_status);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_work_status ON bms.work_cost_settlements(work_order_id, settlement_status);
CREATE INDEX IF NOT EXISTS idx_prevention_measures_work_status ON bms.prevention_measures(work_order_id, implementation_status);
CREATE INDEX IF NOT EXISTS idx_work_warranties_work_status ON bms.work_warranties(work_order_id, warranty_status);

-- Updated_at triggers
CREATE TRIGGER completion_inspections_updated_at_trigger
    BEFORE UPDATE ON bms.work_completion_inspections
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER completion_reports_updated_at_trigger
    BEFORE UPDATE ON bms.work_completion_reports
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER cost_settlements_updated_at_trigger
    BEFORE UPDATE ON bms.work_cost_settlements
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER prevention_measures_updated_at_trigger
    BEFORE UPDATE ON bms.prevention_measures
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_warranties_updated_at_trigger
    BEFORE UPDATE ON bms.work_warranties
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.work_completion_inspections IS 'Work completion inspections - Quality and safety inspections for completed work';
COMMENT ON TABLE bms.work_completion_reports IS 'Work completion reports - Comprehensive completion reports with technical details';
COMMENT ON TABLE bms.work_cost_settlements IS 'Work cost settlements - Cost analysis and financial settlement for completed work';
COMMENT ON TABLE bms.prevention_measures IS 'Prevention measures - Root cause analysis and preventive measures to avoid recurrence';
COMMENT ON TABLE bms.work_warranties IS 'Work warranties - Warranty management for completed work and installed components';

-- Script completion message
SELECT 'Repair completion management system tables created successfully.' as message;