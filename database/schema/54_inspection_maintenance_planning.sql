-- =====================================================
-- Inspection and Maintenance Planning System Tables
-- Phase 4.2.1: Inspection Planning Management
-- =====================================================

-- 1. Inspection templates table
CREATE TABLE IF NOT EXISTS bms.inspection_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    category_id UUID,
    
    -- Template information
    template_name VARCHAR(200) NOT NULL,
    template_code VARCHAR(50) NOT NULL,
    template_description TEXT,
    template_type VARCHAR(30) NOT NULL,
    
    -- Inspection scope
    applicable_asset_types JSONB,
    applicable_categories JSONB,
    inspection_scope VARCHAR(50) NOT NULL,
    
    -- Frequency settings
    default_frequency_type VARCHAR(20) NOT NULL,
    default_frequency_interval INTEGER DEFAULT 1,
    default_duration_hours DECIMAL(6,2) DEFAULT 1.0,
    
    -- Compliance and certification
    is_mandatory BOOLEAN DEFAULT false,
    regulatory_requirement VARCHAR(100),
    certification_required BOOLEAN DEFAULT false,
    qualified_inspector_required BOOLEAN DEFAULT false,
    
    -- Safety requirements
    safety_requirements TEXT,
    required_ppe JSONB, -- Personal Protective Equipment
    hazard_warnings TEXT,
    
    -- Checklist structure
    checklist_items JSONB NOT NULL,
    scoring_method VARCHAR(20) DEFAULT 'PASS_FAIL',
    pass_threshold DECIMAL(5,2) DEFAULT 100.00,
    
    -- Documentation requirements
    photo_required BOOLEAN DEFAULT false,
    signature_required BOOLEAN DEFAULT true,
    report_template TEXT,
    
    -- Status and versioning
    template_version VARCHAR(20) DEFAULT '1.0',
    is_active BOOLEAN DEFAULT true,
    effective_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_inspection_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_templates_category FOREIGN KEY (category_id) REFERENCES bms.facility_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_inspection_templates_code UNIQUE (company_id, template_code),
    
    -- Check constraints
    CONSTRAINT chk_template_type CHECK (template_type IN (
        'ROUTINE_INSPECTION', 'SAFETY_INSPECTION', 'COMPLIANCE_INSPECTION',
        'PREVENTIVE_MAINTENANCE', 'CONDITION_ASSESSMENT', 'PERFORMANCE_TEST',
        'CALIBRATION', 'CERTIFICATION', 'OTHER'
    )),
    CONSTRAINT chk_inspection_scope CHECK (inspection_scope IN (
        'VISUAL', 'FUNCTIONAL', 'PERFORMANCE', 'SAFETY', 'COMPREHENSIVE'
    )),
    CONSTRAINT chk_frequency_type CHECK (default_frequency_type IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL', 'CUSTOM'
    )),
    CONSTRAINT chk_scoring_method CHECK (scoring_method IN (
        'PASS_FAIL', 'NUMERIC_SCORE', 'PERCENTAGE', 'RATING_SCALE'
    ))
);

-- 2. Inspection schedules table
CREATE TABLE IF NOT EXISTS bms.inspection_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    template_id UUID NOT NULL,
    
    -- Schedule information
    schedule_name VARCHAR(200) NOT NULL,
    schedule_description TEXT,
    schedule_type VARCHAR(20) NOT NULL DEFAULT 'RECURRING',
    
    -- Frequency configuration
    frequency_type VARCHAR(20) NOT NULL,
    frequency_interval INTEGER DEFAULT 1,
    frequency_unit VARCHAR(20),
    
    -- Schedule timing
    start_date DATE NOT NULL,
    end_date DATE,
    next_due_date DATE NOT NULL,
    last_completed_date DATE,
    
    -- Work planning
    estimated_duration_hours DECIMAL(6,2) DEFAULT 1.0,
    estimated_cost DECIMAL(10,2) DEFAULT 0,
    required_personnel_count INTEGER DEFAULT 1,
    required_skills JSONB,
    
    -- Assignment
    assigned_inspector_id UUID,
    assigned_team JSONB,
    preferred_contractor_id UUID,
    
    -- Notification settings
    advance_notice_days INTEGER DEFAULT 7,
    reminder_frequency_days INTEGER DEFAULT 1,
    escalation_days INTEGER DEFAULT 3,
    
    -- Priority and criticality
    priority_level VARCHAR(20) DEFAULT 'MEDIUM',
    criticality_level VARCHAR(20) DEFAULT 'MEDIUM',
    business_impact VARCHAR(20) DEFAULT 'MEDIUM',
    
    -- Seasonal and environmental factors
    seasonal_restrictions JSONB,
    weather_dependent BOOLEAN DEFAULT false,
    operating_condition_requirements TEXT,
    
    -- Status tracking
    schedule_status VARCHAR(20) DEFAULT 'ACTIVE',
    compliance_status VARCHAR(20) DEFAULT 'COMPLIANT',
    
    -- Performance tracking
    completion_rate DECIMAL(5,2) DEFAULT 100.00,
    average_score DECIMAL(5,2) DEFAULT 0,
    last_score DECIMAL(5,2) DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_inspection_schedules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_schedules_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_inspection_schedules_template FOREIGN KEY (template_id) REFERENCES bms.inspection_templates(template_id) ON DELETE RESTRICT,
    
    -- Check constraints
    CONSTRAINT chk_schedule_type CHECK (schedule_type IN (
        'RECURRING', 'ONE_TIME', 'CONDITIONAL', 'ON_DEMAND'
    )),
    CONSTRAINT chk_frequency_type_sched CHECK (frequency_type IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL', 'CUSTOM'
    )),
    CONSTRAINT chk_frequency_unit_sched CHECK (frequency_unit IN (
        'DAYS', 'WEEKS', 'MONTHS', 'YEARS'
    ) OR frequency_unit IS NULL),
    CONSTRAINT chk_priority_level CHECK (priority_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL'
    )),
    CONSTRAINT chk_criticality_level CHECK (criticality_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_business_impact CHECK (business_impact IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_schedule_status CHECK (schedule_status IN (
        'ACTIVE', 'INACTIVE', 'SUSPENDED', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT chk_compliance_status CHECK (compliance_status IN (
        'COMPLIANT', 'NON_COMPLIANT', 'OVERDUE', 'PENDING'
    )),
    CONSTRAINT chk_schedule_dates CHECK (
        end_date IS NULL OR end_date >= start_date
    ),
    CONSTRAINT chk_percentages_sched CHECK (
        completion_rate >= 0 AND completion_rate <= 100
    )
);-
- 3. Maintenance plans table
CREATE TABLE IF NOT EXISTS bms.maintenance_plans (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Plan information
    plan_name VARCHAR(200) NOT NULL,
    plan_code VARCHAR(50) NOT NULL,
    plan_description TEXT,
    plan_type VARCHAR(30) NOT NULL,
    
    -- Maintenance strategy
    maintenance_strategy VARCHAR(30) NOT NULL,
    maintenance_approach VARCHAR(30) NOT NULL,
    criticality_analysis JSONB,
    
    -- Frequency and timing
    frequency_type VARCHAR(20) NOT NULL,
    frequency_interval INTEGER DEFAULT 1,
    frequency_unit VARCHAR(20),
    
    -- Condition-based triggers
    condition_triggers JSONB,
    performance_thresholds JSONB,
    usage_based_triggers JSONB,
    
    -- Work planning
    estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    estimated_cost DECIMAL(12,2) DEFAULT 0,
    required_downtime_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Resource requirements
    required_personnel JSONB,
    required_skills JSONB,
    required_tools JSONB,
    required_parts JSONB,
    
    -- Scheduling constraints
    seasonal_restrictions JSONB,
    operational_constraints TEXT,
    coordination_requirements TEXT,
    
    -- Safety and compliance
    safety_requirements TEXT,
    permit_requirements JSONB,
    regulatory_compliance JSONB,
    
    -- Performance targets
    target_availability DECIMAL(5,2) DEFAULT 95.00,
    target_reliability DECIMAL(5,2) DEFAULT 95.00,
    target_cost_per_year DECIMAL(12,2) DEFAULT 0,
    
    -- Plan status
    plan_status VARCHAR(20) DEFAULT 'ACTIVE',
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    effective_date DATE DEFAULT CURRENT_DATE,
    review_date DATE,
    
    -- Performance tracking
    actual_cost_ytd DECIMAL(12,2) DEFAULT 0,
    actual_hours_ytd DECIMAL(8,2) DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0,
    effectiveness_score DECIMAL(5,2) DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    approved_by UUID,
    approved_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT fk_maintenance_plans_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_plans_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT uk_maintenance_plans_code UNIQUE (company_id, plan_code),
    
    -- Check constraints
    CONSTRAINT chk_plan_type CHECK (plan_type IN (
        'PREVENTIVE_MAINTENANCE', 'PREDICTIVE_MAINTENANCE', 'CONDITION_BASED',
        'TIME_BASED', 'USAGE_BASED', 'RELIABILITY_CENTERED', 'TOTAL_PRODUCTIVE'
    )),
    CONSTRAINT chk_maintenance_strategy CHECK (maintenance_strategy IN (
        'REACTIVE', 'PREVENTIVE', 'PREDICTIVE', 'PROACTIVE', 'RELIABILITY_CENTERED'
    )),
    CONSTRAINT chk_maintenance_approach CHECK (maintenance_approach IN (
        'IN_HOUSE', 'OUTSOURCED', 'HYBRID', 'VENDOR_MANAGED'
    )),
    CONSTRAINT chk_frequency_type_plan CHECK (frequency_type IN (
        'HOURS', 'DAYS', 'WEEKS', 'MONTHS', 'YEARS', 'CYCLES', 'CONDITION_BASED'
    )),
    CONSTRAINT chk_plan_status CHECK (plan_status IN (
        'ACTIVE', 'INACTIVE', 'DRAFT', 'UNDER_REVIEW', 'ARCHIVED'
    )),
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'UNDER_REVIEW'
    )),
    CONSTRAINT chk_target_percentages CHECK (
        target_availability >= 0 AND target_availability <= 100 AND
        target_reliability >= 0 AND target_reliability <= 100 AND
        completion_rate >= 0 AND completion_rate <= 100
    )
);

-- 4. Maintenance tasks table
CREATE TABLE IF NOT EXISTS bms.maintenance_tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    plan_id UUID NOT NULL,
    
    -- Task information
    task_sequence INTEGER NOT NULL,
    task_name VARCHAR(200) NOT NULL,
    task_description TEXT,
    task_type VARCHAR(30) NOT NULL,
    
    -- Task details
    task_instructions TEXT,
    safety_precautions TEXT,
    quality_standards TEXT,
    
    -- Resource requirements
    estimated_duration_minutes INTEGER DEFAULT 0,
    required_skill_level VARCHAR(20) DEFAULT 'BASIC',
    required_tools JSONB,
    required_parts JSONB,
    
    -- Task conditions
    prerequisite_tasks JSONB,
    environmental_conditions TEXT,
    equipment_state_required VARCHAR(30),
    
    -- Quality control
    inspection_required BOOLEAN DEFAULT false,
    measurement_required BOOLEAN DEFAULT false,
    documentation_required BOOLEAN DEFAULT true,
    photo_required BOOLEAN DEFAULT false,
    
    -- Performance criteria
    acceptance_criteria TEXT,
    measurement_points JSONB,
    tolerance_specifications JSONB,
    
    -- Task status
    is_critical BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_maintenance_tasks_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_maintenance_tasks_plan FOREIGN KEY (plan_id) REFERENCES bms.maintenance_plans(plan_id) ON DELETE CASCADE,
    CONSTRAINT uk_maintenance_tasks_sequence UNIQUE (plan_id, task_sequence),
    
    -- Check constraints
    CONSTRAINT chk_task_type CHECK (task_type IN (
        'INSPECTION', 'CLEANING', 'LUBRICATION', 'ADJUSTMENT', 'CALIBRATION',
        'REPLACEMENT', 'REPAIR', 'TESTING', 'MEASUREMENT', 'DOCUMENTATION'
    )),
    CONSTRAINT chk_required_skill_level CHECK (required_skill_level IN (
        'BASIC', 'INTERMEDIATE', 'ADVANCED', 'EXPERT', 'CERTIFIED'
    )),
    CONSTRAINT chk_equipment_state CHECK (equipment_state_required IN (
        'RUNNING', 'STOPPED', 'ISOLATED', 'LOCKED_OUT', 'ANY'
    ) OR equipment_state_required IS NULL)
);-- 5. R
LS policies and indexes
ALTER TABLE bms.inspection_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.inspection_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_tasks ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY inspection_templates_isolation_policy ON bms.inspection_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY inspection_schedules_isolation_policy ON bms.inspection_schedules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY maintenance_plans_isolation_policy ON bms.maintenance_plans
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY maintenance_tasks_isolation_policy ON bms.maintenance_tasks
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for inspection_templates
CREATE INDEX IF NOT EXISTS idx_inspection_templates_company_id ON bms.inspection_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_inspection_templates_category_id ON bms.inspection_templates(category_id);
CREATE INDEX IF NOT EXISTS idx_inspection_templates_type ON bms.inspection_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_inspection_templates_code ON bms.inspection_templates(template_code);
CREATE INDEX IF NOT EXISTS idx_inspection_templates_active ON bms.inspection_templates(is_active);

-- Performance indexes for inspection_schedules
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_company_id ON bms.inspection_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_asset_id ON bms.inspection_schedules(asset_id);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_template_id ON bms.inspection_schedules(template_id);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_next_due ON bms.inspection_schedules(next_due_date);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_status ON bms.inspection_schedules(schedule_status);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_priority ON bms.inspection_schedules(priority_level);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_assigned ON bms.inspection_schedules(assigned_inspector_id);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_compliance ON bms.inspection_schedules(compliance_status);

-- Performance indexes for maintenance_plans
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_company_id ON bms.maintenance_plans(company_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_asset_id ON bms.maintenance_plans(asset_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_type ON bms.maintenance_plans(plan_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_strategy ON bms.maintenance_plans(maintenance_strategy);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_status ON bms.maintenance_plans(plan_status);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_approval ON bms.maintenance_plans(approval_status);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_effective ON bms.maintenance_plans(effective_date);

-- Performance indexes for maintenance_tasks
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_company_id ON bms.maintenance_tasks(company_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_plan_id ON bms.maintenance_tasks(plan_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_sequence ON bms.maintenance_tasks(task_sequence);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_type ON bms.maintenance_tasks(task_type);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_critical ON bms.maintenance_tasks(is_critical);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_active ON bms.maintenance_tasks(is_active);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_asset_due ON bms.inspection_schedules(asset_id, next_due_date);
CREATE INDEX IF NOT EXISTS idx_inspection_schedules_company_status ON bms.inspection_schedules(company_id, schedule_status);
CREATE INDEX IF NOT EXISTS idx_maintenance_plans_asset_status ON bms.maintenance_plans(asset_id, plan_status);
CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_plan_sequence ON bms.maintenance_tasks(plan_id, task_sequence);

-- Updated_at triggers
CREATE TRIGGER inspection_templates_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER inspection_schedules_updated_at_trigger
    BEFORE UPDATE ON bms.inspection_schedules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER maintenance_plans_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_plans
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER maintenance_tasks_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_tasks
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.inspection_templates IS 'Inspection templates - Standardized inspection procedures and checklists';
COMMENT ON TABLE bms.inspection_schedules IS 'Inspection schedules - Scheduled inspection plans for facility assets';
COMMENT ON TABLE bms.maintenance_plans IS 'Maintenance plans - Comprehensive maintenance strategies and plans';
COMMENT ON TABLE bms.maintenance_tasks IS 'Maintenance tasks - Individual tasks within maintenance plans';

-- Script completion message
SELECT 'Inspection and maintenance planning system tables created successfully.' as message;