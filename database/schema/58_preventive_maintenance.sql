-- =====================================================
-- Preventive Maintenance Management System Tables
-- Phase 4.2.3: Preventive Maintenance Management
-- =====================================================

-- 1. Preventive maintenance executions table
CREATE TABLE IF NOT EXISTS bms.preventive_maintenance_executions (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Execution information
    execution_number VARCHAR(50) NOT NULL,
    execution_type VARCHAR(30) NOT NULL DEFAULT 'SCHEDULED',
    execution_date DATE NOT NULL,
    planned_start_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    planned_end_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    
    -- Duration tracking
    planned_duration_hours DECIMAL(8,2) DEFAULT 0,
    actual_duration_hours DECIMAL(8,2) DEFAULT 0,
    downtime_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Team and resources
    maintenance_team JSONB,
    lead_technician_id UUID,
    supporting_technicians JSONB,
    contractor_id UUID,
    
    -- Execution status
    execution_status VARCHAR(20) DEFAULT 'PLANNED',
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Work conditions
    equipment_shutdown_required BOOLEAN DEFAULT false,
    shutdown_start_time TIMESTAMP WITH TIME ZONE,
    shutdown_end_time TIMESTAMP WITH TIME ZONE,
    environmental_conditions TEXT,
    
    -- Safety and permits
    safety_briefing_completed BOOLEAN DEFAULT false,
    permits_obtained JSONB,
    lockout_tagout_applied BOOLEAN DEFAULT false,
    safety_incidents JSONB,
    
    -- Materials and tools
    materials_used JSONB,
    tools_used JSONB,
    spare_parts_consumed JSONB,
    
    -- Cost tracking
    planned_cost DECIMAL(12,2) DEFAULT 0,
    actual_cost DECIMAL(12,2) DEFAULT 0,
    labor_cost DECIMAL(12,2) DEFAULT 0,
    material_cost DECIMAL(12,2) DEFAULT 0,
    contractor_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Quality and results
    work_quality_rating DECIMAL(3,1) DEFAULT 0,
    asset_condition_before VARCHAR(20),
    asset_condition_after VARCHAR(20),
    performance_improvement DECIMAL(5,2) DEFAULT 0,
    
    -- Issues and findings
    issues_encountered JSONB,
    unexpected_findings JSONB,
    additional_work_required BOOLEAN DEFAULT false,
    follow_up_actions JSONB,
    
    -- Documentation
    work_photos JSONB,
    completion_certificates JSONB,
    test_results JSONB,
    maintenance_reports JSONB,
    
    -- Approval and sign-off
    work_completed_by UUID,
    work_completion_date TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID,
    review_date DATE,
    approved_by UUID,
    approval_date DATE,
    
    -- Notes and observations
    technician_notes TEXT,
    supervisor_comments TEXT,
    lessons_learned TEXT,
    recommendations TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_pm_executions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_pm_executions_plan FOREIGN KEY (plan_id) REFERENCES bms.maintenance_plans(plan_id) ON DELETE CASCADE,
    CONSTRAINT fk_pm_executions_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT uk_pm_executions_number UNIQUE (company_id, execution_number),
    
    -- Check constraints
    CONSTRAINT chk_execution_type CHECK (execution_type IN (
        'SCHEDULED', 'EMERGENCY', 'CONDITION_BASED', 'OPPORTUNITY', 'CORRECTIVE'
    )),
    CONSTRAINT chk_pm_execution_status CHECK (execution_status IN (
        'PLANNED', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DEFERRED', 'FAILED'
    )),
    CONSTRAINT chk_asset_condition CHECK (
        (asset_condition_before IS NULL OR asset_condition_before IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'CRITICAL')) AND
        (asset_condition_after IS NULL OR asset_condition_after IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'CRITICAL'))
    ),
    CONSTRAINT chk_completion_percentage_pm CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    ),
    CONSTRAINT chk_work_quality_rating CHECK (
        work_quality_rating >= 0 AND work_quality_rating <= 10
    ),
    CONSTRAINT chk_cost_values_pm CHECK (
        planned_cost >= 0 AND actual_cost >= 0 AND labor_cost >= 0 AND 
        material_cost >= 0 AND contractor_cost >= 0
    )
);

-- 2. Maintenance task executions table
CREATE TABLE IF NOT EXISTS bms.maintenance_task_executions (
    task_execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    execution_id UUID NOT NULL,
    task_id UUID NOT NULL,
    
    -- Task execution details
    task_sequence INTEGER NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    task_description TEXT,
    
    -- Execution timing
    planned_start_time TIMESTAMP WITH TIME ZONE,
    actual_start_time TIMESTAMP WITH TIME ZONE,
    planned_end_time TIMESTAMP WITH TIME ZONE,
    actual_end_time TIMESTAMP WITH TIME ZONE,
    planned_duration_minutes INTEGER DEFAULT 0,
    actual_duration_minutes INTEGER DEFAULT 0,
    
    -- Task status
    task_status VARCHAR(20) DEFAULT 'PENDING',
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Execution details
    work_instructions_followed BOOLEAN DEFAULT true,
    safety_precautions_taken BOOLEAN DEFAULT true,
    quality_standards_met BOOLEAN DEFAULT true,
    
    -- Measurements and results
    measurements_taken JSONB,
    test_results JSONB,
    acceptance_criteria_met BOOLEAN DEFAULT true,
    
    -- Issues and deviations
    issues_encountered TEXT,
    deviations_from_plan TEXT,
    corrective_actions_taken TEXT,
    
    -- Resources used
    technician_assigned UUID,
    tools_used JSONB,
    materials_consumed JSONB,
    
    -- Quality control
    inspection_required BOOLEAN DEFAULT false,
    inspection_completed BOOLEAN DEFAULT false,
    inspection_result VARCHAR(20),
    inspector_id UUID,
    inspection_date TIMESTAMP WITH TIME ZONE,
    
    -- Documentation
    task_photos JSONB,
    measurement_data JSONB,
    completion_evidence JSONB,
    
    -- Task completion
    completed_by UUID,
    completion_date TIMESTAMP WITH TIME ZONE,
    verified_by UUID,
    verification_date TIMESTAMP WITH TIME ZONE,
    
    -- Notes
    technician_notes TEXT,
    supervisor_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_task_executions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_task_executions_execution FOREIGN KEY (execution_id) REFERENCES bms.preventive_maintenance_executions(execution_id) ON DELETE CASCADE,
    CONSTRAINT fk_task_executions_task FOREIGN KEY (task_id) REFERENCES bms.maintenance_tasks(task_id) ON DELETE CASCADE,
    CONSTRAINT uk_task_executions_sequence UNIQUE (execution_id, task_sequence),
    
    -- Check constraints
    CONSTRAINT chk_task_status CHECK (task_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'SKIPPED', 'FAILED', 'DEFERRED'
    )),
    CONSTRAINT chk_inspection_result CHECK (inspection_result IN (
        'PASS', 'FAIL', 'CONDITIONAL', 'NOT_APPLICABLE'
    ) OR inspection_result IS NULL),
    CONSTRAINT chk_task_completion_percentage CHECK (
        completion_percentage >= 0 AND completion_percentage <= 100
    )
);-- 3
. Maintenance effectiveness analysis table
CREATE TABLE IF NOT EXISTS bms.maintenance_effectiveness_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    plan_id UUID,
    
    -- Analysis period
    analysis_date DATE NOT NULL,
    analysis_period VARCHAR(20) NOT NULL,
    period_start_date DATE NOT NULL,
    period_end_date DATE NOT NULL,
    
    -- Maintenance metrics
    planned_maintenance_count INTEGER DEFAULT 0,
    completed_maintenance_count INTEGER DEFAULT 0,
    cancelled_maintenance_count INTEGER DEFAULT 0,
    deferred_maintenance_count INTEGER DEFAULT 0,
    
    -- Reliability metrics
    failure_count INTEGER DEFAULT 0,
    unplanned_downtime_hours DECIMAL(10,2) DEFAULT 0,
    planned_downtime_hours DECIMAL(10,2) DEFAULT 0,
    mtbf_hours DECIMAL(12,2) DEFAULT 0, -- Mean Time Between Failures
    mttr_hours DECIMAL(8,2) DEFAULT 0,  -- Mean Time To Repair
    availability_percentage DECIMAL(5,2) DEFAULT 100.00,
    
    -- Cost effectiveness
    planned_maintenance_cost DECIMAL(15,2) DEFAULT 0,
    actual_maintenance_cost DECIMAL(15,2) DEFAULT 0,
    emergency_repair_cost DECIMAL(15,2) DEFAULT 0,
    total_maintenance_cost DECIMAL(15,2) DEFAULT 0,
    cost_per_operating_hour DECIMAL(10,4) DEFAULT 0,
    
    -- Performance metrics
    asset_performance_rating DECIMAL(5,2) DEFAULT 100.00,
    efficiency_improvement DECIMAL(5,2) DEFAULT 0,
    condition_improvement DECIMAL(5,2) DEFAULT 0,
    energy_efficiency_improvement DECIMAL(5,2) DEFAULT 0,
    
    -- Maintenance quality
    rework_percentage DECIMAL(5,2) DEFAULT 0,
    first_time_fix_rate DECIMAL(5,2) DEFAULT 100.00,
    maintenance_quality_score DECIMAL(5,2) DEFAULT 0,
    
    -- Compliance and safety
    compliance_rate DECIMAL(5,2) DEFAULT 100.00,
    safety_incidents INTEGER DEFAULT 0,
    near_miss_incidents INTEGER DEFAULT 0,
    
    -- Trend analysis
    failure_trend VARCHAR(20) DEFAULT 'STABLE',
    cost_trend VARCHAR(20) DEFAULT 'STABLE',
    performance_trend VARCHAR(20) DEFAULT 'STABLE',
    
    -- Recommendations
    maintenance_strategy_effectiveness VARCHAR(20) DEFAULT 'EFFECTIVE',
    recommended_frequency_adjustment VARCHAR(50),
    recommended_strategy_changes TEXT,
    cost_optimization_opportunities TEXT,
    
    -- ROI analysis
    maintenance_investment DECIMAL(15,2) DEFAULT 0,
    avoided_failure_cost DECIMAL(15,2) DEFAULT 0,
    productivity_improvement_value DECIMAL(15,2) DEFAULT 0,
    roi_percentage DECIMAL(8,4) DEFAULT 0,
    
    -- Benchmarking
    industry_benchmark_availability DECIMAL(5,2),
    industry_benchmark_mtbf DECIMAL(12,2),
    industry_benchmark_cost DECIMAL(10,4),
    performance_vs_benchmark DECIMAL(8,4) DEFAULT 0,
    
    -- Analysis metadata
    analysis_method VARCHAR(50),
    data_quality_score DECIMAL(3,1) DEFAULT 10.0,
    confidence_level DECIMAL(5,2) DEFAULT 95.00,
    analyzed_by UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_effectiveness_analysis_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_effectiveness_analysis_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_effectiveness_analysis_plan FOREIGN KEY (plan_id) REFERENCES bms.maintenance_plans(plan_id) ON DELETE SET NULL,
    CONSTRAINT uk_effectiveness_analysis_period UNIQUE (asset_id, analysis_date, analysis_period),
    
    -- Check constraints
    CONSTRAINT chk_analysis_period CHECK (analysis_period IN (
        'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    CONSTRAINT chk_trend_values CHECK (
        failure_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        cost_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        performance_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE')
    ),
    CONSTRAINT chk_maintenance_effectiveness CHECK (maintenance_strategy_effectiveness IN (
        'HIGHLY_EFFECTIVE', 'EFFECTIVE', 'MODERATELY_EFFECTIVE', 'INEFFECTIVE', 'NEEDS_REVIEW'
    )),
    CONSTRAINT chk_percentage_values CHECK (
        availability_percentage >= 0 AND availability_percentage <= 100 AND
        rework_percentage >= 0 AND rework_percentage <= 100 AND
        first_time_fix_rate >= 0 AND first_time_fix_rate <= 100 AND
        compliance_rate >= 0 AND compliance_rate <= 100 AND
        confidence_level >= 0 AND confidence_level <= 100
    ),
    CONSTRAINT chk_cost_values_analysis CHECK (
        planned_maintenance_cost >= 0 AND actual_maintenance_cost >= 0 AND
        emergency_repair_cost >= 0 AND total_maintenance_cost >= 0 AND
        maintenance_investment >= 0 AND avoided_failure_cost >= 0
    ),
    CONSTRAINT chk_period_dates CHECK (period_end_date >= period_start_date)
);

-- 4. Maintenance optimization recommendations table
CREATE TABLE IF NOT EXISTS bms.maintenance_optimization_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    analysis_id UUID,
    
    -- Recommendation information
    recommendation_type VARCHAR(30) NOT NULL,
    recommendation_category VARCHAR(30) NOT NULL,
    recommendation_title VARCHAR(200) NOT NULL,
    recommendation_description TEXT NOT NULL,
    
    -- Priority and impact
    priority_level VARCHAR(20) NOT NULL,
    impact_level VARCHAR(20) NOT NULL,
    implementation_difficulty VARCHAR(20) DEFAULT 'MEDIUM',
    
    -- Financial analysis
    implementation_cost DECIMAL(12,2) DEFAULT 0,
    annual_savings_estimate DECIMAL(12,2) DEFAULT 0,
    payback_period_months INTEGER DEFAULT 0,
    roi_estimate DECIMAL(8,4) DEFAULT 0,
    
    -- Implementation details
    implementation_timeline VARCHAR(50),
    required_resources JSONB,
    required_approvals JSONB,
    risk_factors JSONB,
    
    -- Expected benefits
    expected_availability_improvement DECIMAL(5,2) DEFAULT 0,
    expected_cost_reduction DECIMAL(5,2) DEFAULT 0,
    expected_reliability_improvement DECIMAL(5,2) DEFAULT 0,
    expected_safety_improvement TEXT,
    
    -- Status tracking
    recommendation_status VARCHAR(20) DEFAULT 'PROPOSED',
    implementation_status VARCHAR(20) DEFAULT 'NOT_STARTED',
    
    -- Decision tracking
    decision_date DATE,
    decision_maker UUID,
    decision_rationale TEXT,
    approved_budget DECIMAL(12,2) DEFAULT 0,
    
    -- Implementation tracking
    implementation_start_date DATE,
    implementation_end_date DATE,
    actual_implementation_cost DECIMAL(12,2) DEFAULT 0,
    implementation_notes TEXT,
    
    -- Results tracking
    actual_benefits_achieved JSONB,
    actual_roi DECIMAL(8,4) DEFAULT 0,
    lessons_learned TEXT,
    
    -- Metadata
    recommended_by UUID,
    recommendation_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_optimization_recommendations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_optimization_recommendations_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_optimization_recommendations_analysis FOREIGN KEY (analysis_id) REFERENCES bms.maintenance_effectiveness_analysis(analysis_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_recommendation_type CHECK (recommendation_type IN (
        'FREQUENCY_ADJUSTMENT', 'STRATEGY_CHANGE', 'RESOURCE_OPTIMIZATION',
        'TECHNOLOGY_UPGRADE', 'PROCESS_IMPROVEMENT', 'TRAINING_NEED',
        'SPARE_PARTS_OPTIMIZATION', 'CONTRACTOR_CHANGE', 'OTHER'
    )),
    CONSTRAINT chk_recommendation_category CHECK (recommendation_category IN (
        'COST_REDUCTION', 'RELIABILITY_IMPROVEMENT', 'EFFICIENCY_ENHANCEMENT',
        'SAFETY_IMPROVEMENT', 'COMPLIANCE', 'SUSTAINABILITY', 'AUTOMATION'
    )),
    CONSTRAINT chk_priority_level_rec CHECK (priority_level IN (
        'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'DEFERRED'
    )),
    CONSTRAINT chk_impact_level_rec CHECK (impact_level IN (
        'HIGH', 'MEDIUM', 'LOW', 'MINIMAL'
    )),
    CONSTRAINT chk_implementation_difficulty CHECK (implementation_difficulty IN (
        'EASY', 'MEDIUM', 'DIFFICULT', 'VERY_DIFFICULT'
    )),
    CONSTRAINT chk_recommendation_status CHECK (recommendation_status IN (
        'PROPOSED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'DEFERRED'
    )),
    CONSTRAINT chk_implementation_status CHECK (implementation_status IN (
        'NOT_STARTED', 'PLANNING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ON_HOLD'
    )),
    CONSTRAINT chk_financial_values CHECK (
        implementation_cost >= 0 AND annual_savings_estimate >= 0 AND
        approved_budget >= 0 AND actual_implementation_cost >= 0
    )
);--
 5. RLS policies and indexes
ALTER TABLE bms.preventive_maintenance_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_task_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_effectiveness_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_optimization_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY pm_executions_isolation_policy ON bms.preventive_maintenance_executions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY task_executions_isolation_policy ON bms.maintenance_task_executions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY effectiveness_analysis_isolation_policy ON bms.maintenance_effectiveness_analysis
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY optimization_recommendations_isolation_policy ON bms.maintenance_optimization_recommendations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for preventive_maintenance_executions
CREATE INDEX IF NOT EXISTS idx_pm_executions_company_id ON bms.preventive_maintenance_executions(company_id);
CREATE INDEX IF NOT EXISTS idx_pm_executions_plan_id ON bms.preventive_maintenance_executions(plan_id);
CREATE INDEX IF NOT EXISTS idx_pm_executions_asset_id ON bms.preventive_maintenance_executions(asset_id);
CREATE INDEX IF NOT EXISTS idx_pm_executions_date ON bms.preventive_maintenance_executions(execution_date);
CREATE INDEX IF NOT EXISTS idx_pm_executions_status ON bms.preventive_maintenance_executions(execution_status);
CREATE INDEX IF NOT EXISTS idx_pm_executions_type ON bms.preventive_maintenance_executions(execution_type);
CREATE INDEX IF NOT EXISTS idx_pm_executions_technician ON bms.preventive_maintenance_executions(lead_technician_id);
CREATE INDEX IF NOT EXISTS idx_pm_executions_number ON bms.preventive_maintenance_executions(execution_number);

-- Performance indexes for maintenance_task_executions
CREATE INDEX IF NOT EXISTS idx_task_executions_company_id ON bms.maintenance_task_executions(company_id);
CREATE INDEX IF NOT EXISTS idx_task_executions_execution_id ON bms.maintenance_task_executions(execution_id);
CREATE INDEX IF NOT EXISTS idx_task_executions_task_id ON bms.maintenance_task_executions(task_id);
CREATE INDEX IF NOT EXISTS idx_task_executions_sequence ON bms.maintenance_task_executions(task_sequence);
CREATE INDEX IF NOT EXISTS idx_task_executions_status ON bms.maintenance_task_executions(task_status);
CREATE INDEX IF NOT EXISTS idx_task_executions_technician ON bms.maintenance_task_executions(technician_assigned);
CREATE INDEX IF NOT EXISTS idx_task_executions_completion ON bms.maintenance_task_executions(completion_date);

-- Performance indexes for maintenance_effectiveness_analysis
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_company_id ON bms.maintenance_effectiveness_analysis(company_id);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_asset_id ON bms.maintenance_effectiveness_analysis(asset_id);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_plan_id ON bms.maintenance_effectiveness_analysis(plan_id);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_date ON bms.maintenance_effectiveness_analysis(analysis_date);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_period ON bms.maintenance_effectiveness_analysis(analysis_period);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_effectiveness ON bms.maintenance_effectiveness_analysis(maintenance_strategy_effectiveness);

-- Performance indexes for maintenance_optimization_recommendations
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_company_id ON bms.maintenance_optimization_recommendations(company_id);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_asset_id ON bms.maintenance_optimization_recommendations(asset_id);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_analysis_id ON bms.maintenance_optimization_recommendations(analysis_id);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_type ON bms.maintenance_optimization_recommendations(recommendation_type);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_priority ON bms.maintenance_optimization_recommendations(priority_level);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_status ON bms.maintenance_optimization_recommendations(recommendation_status);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_implementation ON bms.maintenance_optimization_recommendations(implementation_status);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_pm_executions_asset_date ON bms.preventive_maintenance_executions(asset_id, execution_date);
CREATE INDEX IF NOT EXISTS idx_pm_executions_company_status ON bms.preventive_maintenance_executions(company_id, execution_status);
CREATE INDEX IF NOT EXISTS idx_task_executions_execution_sequence ON bms.maintenance_task_executions(execution_id, task_sequence);
CREATE INDEX IF NOT EXISTS idx_effectiveness_analysis_asset_period ON bms.maintenance_effectiveness_analysis(asset_id, analysis_date, analysis_period);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_asset_status ON bms.maintenance_optimization_recommendations(asset_id, recommendation_status);

-- Updated_at triggers
CREATE TRIGGER pm_executions_updated_at_trigger
    BEFORE UPDATE ON bms.preventive_maintenance_executions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER task_executions_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_task_executions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER effectiveness_analysis_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_effectiveness_analysis
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER optimization_recommendations_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_optimization_recommendations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.preventive_maintenance_executions IS 'Preventive maintenance executions - Records of actual preventive maintenance work performed';
COMMENT ON TABLE bms.maintenance_task_executions IS 'Maintenance task executions - Detailed execution records for individual maintenance tasks';
COMMENT ON TABLE bms.maintenance_effectiveness_analysis IS 'Maintenance effectiveness analysis - Analysis of maintenance strategy effectiveness and performance';
COMMENT ON TABLE bms.maintenance_optimization_recommendations IS 'Maintenance optimization recommendations - Recommendations for improving maintenance strategies';

-- Script completion message
SELECT 'Preventive maintenance management system tables created successfully.' as message;