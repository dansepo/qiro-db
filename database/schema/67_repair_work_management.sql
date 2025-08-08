-- =====================================================
-- Repair Work Management System
-- Phase 4.3.2: Repair Work Management Tables
-- =====================================================

-- 1. Work order templates table
CREATE TABLE IF NOT EXISTS bms.work_order_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Template information
    template_code VARCHAR(20) NOT NULL,
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    
    -- Work type classification
    work_category VARCHAR(30) NOT NULL,
    work_type VARCHAR(30) NOT NULL,
    fault_type VARCHAR(30),
    
    -- Template settings
    default_priority VARCHAR(20) DEFAULT 'MEDIUM',
    estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    required_skill_level VARCHAR(20) DEFAULT 'BASIC',
    requires_specialist BOOLEAN DEFAULT false,
    requires_contractor BOOLEAN DEFAULT false,
    
    -- Safety requirements
    safety_requirements JSONB,
    required_tools JSONB,
    required_materials JSONB,
    
    -- Work instructions
    work_instructions TEXT,
    safety_precautions TEXT,
    quality_checkpoints JSONB,
    
    -- Template status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_work_templates_code UNIQUE (company_id, template_code),
    
    -- Check constraints
    CONSTRAINT chk_work_category CHECK (work_category IN (
        'PREVENTIVE', 'CORRECTIVE', 'EMERGENCY', 'IMPROVEMENT', 'INSPECTION'
    )),
    CONSTRAINT chk_work_type CHECK (work_type IN (
        'ELECTRICAL', 'PLUMBING', 'HVAC', 'ELEVATOR', 'FIRE_SAFETY', 
        'SECURITY', 'STRUCTURAL', 'APPLIANCE', 'LIGHTING', 'CLEANING', 'OTHER'
    )),
    CONSTRAINT chk_work_priority CHECK (default_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_skill_level CHECK (required_skill_level IN (
        'BASIC', 'INTERMEDIATE', 'ADVANCED', 'EXPERT', 'SPECIALIST'
    ))
);

-- 2. Work orders table
CREATE TABLE IF NOT EXISTS bms.work_orders (
    work_order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_id UUID,
    asset_id UUID,
    
    -- Related fault report
    fault_report_id UUID,
    
    -- Work order identification
    work_order_number VARCHAR(50) NOT NULL,
    work_order_title VARCHAR(200) NOT NULL,
    work_description TEXT NOT NULL,
    
    -- Work classification
    work_category VARCHAR(30) NOT NULL,
    work_type VARCHAR(30) NOT NULL,
    work_priority VARCHAR(20) NOT NULL,
    work_urgency VARCHAR(20) NOT NULL,
    
    -- Template reference
    template_id UUID,
    
    -- Requester information
    requested_by UUID,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    request_reason TEXT,
    
    -- Work location and scope
    work_location TEXT,
    work_scope TEXT,
    affected_areas JSONB,
    
    -- Scheduling
    scheduled_start_date TIMESTAMP WITH TIME ZONE,
    scheduled_end_date TIMESTAMP WITH TIME ZONE,
    estimated_duration_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Assignment
    assigned_to UUID,
    assigned_team VARCHAR(50),
    assignment_date TIMESTAMP WITH TIME ZONE,
    
    -- Contractor information
    contractor_id UUID,
    contractor_contact JSONB,
    
    -- Work status tracking
    work_status VARCHAR(20) DEFAULT 'PENDING',
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Execution tracking
    actual_start_date TIMESTAMP WITH TIME ZONE,
    actual_end_date TIMESTAMP WITH TIME ZONE,
    actual_duration_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Progress tracking
    progress_percentage INTEGER DEFAULT 0,
    work_phase VARCHAR(30) DEFAULT 'PLANNING',
    
    -- Cost information
    estimated_cost DECIMAL(12,2) DEFAULT 0,
    approved_budget DECIMAL(12,2) DEFAULT 0,
    actual_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Materials and resources
    required_materials JSONB,
    used_materials JSONB,
    required_tools JSONB,
    
    -- Safety and quality
    safety_requirements JSONB,
    quality_checkpoints JSONB,
    safety_incidents INTEGER DEFAULT 0,
    
    -- Work results
    work_completion_notes TEXT,
    quality_rating DECIMAL(3,1) DEFAULT 0,
    customer_satisfaction DECIMAL(3,1) DEFAULT 0,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    follow_up_notes TEXT,
    
    -- Documentation
    work_photos JSONB,
    work_documents JSONB,
    before_photos JSONB,
    after_photos JSONB,
    
    -- Approval workflow
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Closure
    closed_by UUID,
    closed_date TIMESTAMP WITH TIME ZONE,
    closure_reason VARCHAR(50),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_orders_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_orders_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_orders_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_orders_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE SET NULL,
    CONSTRAINT fk_work_orders_fault_report FOREIGN KEY (fault_report_id) REFERENCES bms.fault_reports(report_id) ON DELETE SET NULL,
    CONSTRAINT fk_work_orders_template FOREIGN KEY (template_id) REFERENCES bms.work_order_templates(template_id) ON DELETE SET NULL,
    CONSTRAINT uk_work_orders_number UNIQUE (company_id, work_order_number),
    
    -- Check constraints
    CONSTRAINT chk_work_category_orders CHECK (work_category IN (
        'PREVENTIVE', 'CORRECTIVE', 'EMERGENCY', 'IMPROVEMENT', 'INSPECTION'
    )),
    CONSTRAINT chk_work_type_orders CHECK (work_type IN (
        'ELECTRICAL', 'PLUMBING', 'HVAC', 'ELEVATOR', 'FIRE_SAFETY', 
        'SECURITY', 'STRUCTURAL', 'APPLIANCE', 'LIGHTING', 'CLEANING', 'OTHER'
    )),
    CONSTRAINT chk_work_priority_orders CHECK (work_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_work_urgency CHECK (work_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_work_status CHECK (work_status IN (
        'PENDING', 'APPROVED', 'SCHEDULED', 'IN_PROGRESS', 'ON_HOLD', 
        'COMPLETED', 'CANCELLED', 'REJECTED'
    )),
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'REQUIRES_REVISION'
    )),
    CONSTRAINT chk_work_phase CHECK (work_phase IN (
        'PLANNING', 'PREPARATION', 'EXECUTION', 'TESTING', 'COMPLETION', 'CLOSURE'
    )),
    CONSTRAINT chk_progress_percentage CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT chk_cost_values_work CHECK (
        estimated_cost >= 0 AND approved_budget >= 0 AND actual_cost >= 0
    ),
    CONSTRAINT chk_quality_ratings CHECK (
        quality_rating >= 0 AND quality_rating <= 10 AND
        customer_satisfaction >= 0 AND customer_satisfaction <= 10
    )
);--
 3. Work order assignments table
CREATE TABLE IF NOT EXISTS bms.work_order_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Assignment details
    assigned_to UUID NOT NULL,
    assignment_role VARCHAR(30) NOT NULL,
    assignment_type VARCHAR(20) NOT NULL,
    
    -- Assignment period
    assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expected_start_date TIMESTAMP WITH TIME ZONE,
    expected_end_date TIMESTAMP WITH TIME ZONE,
    
    -- Assignment status
    assignment_status VARCHAR(20) DEFAULT 'ASSIGNED',
    acceptance_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Work allocation
    allocated_hours DECIMAL(8,2) DEFAULT 0,
    actual_hours DECIMAL(8,2) DEFAULT 0,
    work_percentage INTEGER DEFAULT 0,
    
    -- Assignment notes
    assignment_notes TEXT,
    acceptance_notes TEXT,
    completion_notes TEXT,
    
    -- Performance tracking
    performance_rating DECIMAL(3,1) DEFAULT 0,
    quality_score DECIMAL(3,1) DEFAULT 0,
    timeliness_score DECIMAL(3,1) DEFAULT 0,
    
    -- Assignment completion
    completed_date TIMESTAMP WITH TIME ZONE,
    completed_by UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_assignments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_assignments_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_assignment_role CHECK (assignment_role IN (
        'PRIMARY_TECHNICIAN', 'ASSISTANT_TECHNICIAN', 'SUPERVISOR', 
        'SPECIALIST', 'CONTRACTOR', 'INSPECTOR', 'COORDINATOR'
    )),
    CONSTRAINT chk_assignment_type CHECK (assignment_type IN (
        'INTERNAL', 'EXTERNAL', 'CONTRACTOR', 'CONSULTANT'
    )),
    CONSTRAINT chk_assignment_status CHECK (assignment_status IN (
        'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REASSIGNED'
    )),
    CONSTRAINT chk_acceptance_status CHECK (acceptance_status IN (
        'PENDING', 'ACCEPTED', 'DECLINED', 'REQUIRES_CLARIFICATION'
    )),
    CONSTRAINT chk_work_percentage_assign CHECK (work_percentage >= 0 AND work_percentage <= 100),
    CONSTRAINT chk_performance_scores CHECK (
        performance_rating >= 0 AND performance_rating <= 10 AND
        quality_score >= 0 AND quality_score <= 10 AND
        timeliness_score >= 0 AND timeliness_score <= 10
    )
);

-- 4. Work order materials table
CREATE TABLE IF NOT EXISTS bms.work_order_materials (
    material_usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Material information
    material_code VARCHAR(50),
    material_name VARCHAR(200) NOT NULL,
    material_category VARCHAR(50),
    material_specification TEXT,
    
    -- Quantity information
    required_quantity DECIMAL(10,3) NOT NULL,
    allocated_quantity DECIMAL(10,3) DEFAULT 0,
    used_quantity DECIMAL(10,3) DEFAULT 0,
    returned_quantity DECIMAL(10,3) DEFAULT 0,
    
    -- Unit information
    unit_of_measure VARCHAR(20) NOT NULL,
    
    -- Cost information
    unit_cost DECIMAL(12,2) DEFAULT 0,
    total_estimated_cost DECIMAL(12,2) DEFAULT 0,
    total_actual_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Supply information
    supplier_name VARCHAR(200),
    supplier_contact JSONB,
    purchase_order_number VARCHAR(50),
    
    -- Status tracking
    material_status VARCHAR(20) DEFAULT 'REQUIRED',
    procurement_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Delivery information
    requested_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_location TEXT,
    
    -- Quality information
    quality_specification TEXT,
    quality_check_required BOOLEAN DEFAULT false,
    quality_check_passed BOOLEAN DEFAULT false,
    quality_notes TEXT,
    
    -- Usage tracking
    usage_date TIMESTAMP WITH TIME ZONE,
    used_by UUID,
    usage_notes TEXT,
    
    -- Waste and return
    waste_quantity DECIMAL(10,3) DEFAULT 0,
    waste_reason TEXT,
    return_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_materials_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_materials_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_material_status CHECK (material_status IN (
        'REQUIRED', 'REQUESTED', 'ORDERED', 'DELIVERED', 'ALLOCATED', 
        'USED', 'RETURNED', 'CANCELLED'
    )),
    CONSTRAINT chk_procurement_status CHECK (procurement_status IN (
        'PENDING', 'REQUESTED', 'APPROVED', 'ORDERED', 'DELIVERED', 
        'RECEIVED', 'REJECTED', 'CANCELLED'
    )),
    CONSTRAINT chk_quantity_values CHECK (
        required_quantity > 0 AND
        allocated_quantity >= 0 AND
        used_quantity >= 0 AND
        returned_quantity >= 0 AND
        waste_quantity >= 0
    ),
    CONSTRAINT chk_cost_values_materials CHECK (
        unit_cost >= 0 AND
        total_estimated_cost >= 0 AND
        total_actual_cost >= 0
    )
);

-- 5. Work order progress tracking table
CREATE TABLE IF NOT EXISTS bms.work_order_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Progress information
    progress_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress_percentage INTEGER NOT NULL,
    work_phase VARCHAR(30) NOT NULL,
    
    -- Progress details
    work_completed TEXT,
    work_remaining TEXT,
    issues_encountered TEXT,
    
    -- Time tracking
    hours_worked DECIMAL(8,2) DEFAULT 0,
    cumulative_hours DECIMAL(8,2) DEFAULT 0,
    
    -- Quality metrics
    quality_checkpoints_completed INTEGER DEFAULT 0,
    quality_issues_found INTEGER DEFAULT 0,
    quality_issues_resolved INTEGER DEFAULT 0,
    
    -- Resource usage
    materials_used JSONB,
    tools_used JSONB,
    personnel_involved JSONB,
    
    -- Progress photos and documentation
    progress_photos JSONB,
    progress_documents JSONB,
    
    -- Next steps
    next_steps TEXT,
    expected_completion_date TIMESTAMP WITH TIME ZONE,
    
    -- Reported by
    reported_by UUID NOT NULL,
    supervisor_reviewed BOOLEAN DEFAULT false,
    supervisor_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_work_progress_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_progress_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_progress_percentage_track CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT chk_work_phase_track CHECK (work_phase IN (
        'PLANNING', 'PREPARATION', 'EXECUTION', 'TESTING', 'COMPLETION', 'CLOSURE'
    )),
    CONSTRAINT chk_hours_worked CHECK (hours_worked >= 0 AND cumulative_hours >= 0),
    CONSTRAINT chk_quality_metrics CHECK (
        quality_checkpoints_completed >= 0 AND
        quality_issues_found >= 0 AND
        quality_issues_resolved >= 0 AND
        quality_issues_resolved <= quality_issues_found
    )
);-- 6. RLS
 policies and indexes
ALTER TABLE bms.work_order_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_order_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_order_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_order_progress ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY work_templates_isolation_policy ON bms.work_order_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_orders_isolation_policy ON bms.work_orders
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_assignments_isolation_policy ON bms.work_order_assignments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_materials_isolation_policy ON bms.work_order_materials
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_progress_isolation_policy ON bms.work_order_progress
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for work_order_templates
CREATE INDEX IF NOT EXISTS idx_work_templates_company_id ON bms.work_order_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_work_templates_code ON bms.work_order_templates(template_code);
CREATE INDEX IF NOT EXISTS idx_work_templates_category ON bms.work_order_templates(work_category);
CREATE INDEX IF NOT EXISTS idx_work_templates_type ON bms.work_order_templates(work_type);
CREATE INDEX IF NOT EXISTS idx_work_templates_active ON bms.work_order_templates(is_active);

-- Performance indexes for work_orders
CREATE INDEX IF NOT EXISTS idx_work_orders_company_id ON bms.work_orders(company_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_building_id ON bms.work_orders(building_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_unit_id ON bms.work_orders(unit_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_asset_id ON bms.work_orders(asset_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_fault_report ON bms.work_orders(fault_report_id);
CREATE INDEX IF NOT EXISTS idx_work_orders_number ON bms.work_orders(work_order_number);
CREATE INDEX IF NOT EXISTS idx_work_orders_status ON bms.work_orders(work_status);
CREATE INDEX IF NOT EXISTS idx_work_orders_priority ON bms.work_orders(work_priority);
CREATE INDEX IF NOT EXISTS idx_work_orders_category ON bms.work_orders(work_category);
CREATE INDEX IF NOT EXISTS idx_work_orders_type ON bms.work_orders(work_type);
CREATE INDEX IF NOT EXISTS idx_work_orders_assigned ON bms.work_orders(assigned_to);
CREATE INDEX IF NOT EXISTS idx_work_orders_requested_by ON bms.work_orders(requested_by);
CREATE INDEX IF NOT EXISTS idx_work_orders_request_date ON bms.work_orders(request_date);
CREATE INDEX IF NOT EXISTS idx_work_orders_scheduled_start ON bms.work_orders(scheduled_start_date);
CREATE INDEX IF NOT EXISTS idx_work_orders_scheduled_end ON bms.work_orders(scheduled_end_date);
CREATE INDEX IF NOT EXISTS idx_work_orders_actual_start ON bms.work_orders(actual_start_date);
CREATE INDEX IF NOT EXISTS idx_work_orders_actual_end ON bms.work_orders(actual_end_date);

-- Performance indexes for work_order_assignments
CREATE INDEX IF NOT EXISTS idx_work_assignments_company_id ON bms.work_order_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_work_assignments_work_order ON bms.work_order_assignments(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_assignments_assigned_to ON bms.work_order_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_work_assignments_role ON bms.work_order_assignments(assignment_role);
CREATE INDEX IF NOT EXISTS idx_work_assignments_status ON bms.work_order_assignments(assignment_status);
CREATE INDEX IF NOT EXISTS idx_work_assignments_date ON bms.work_order_assignments(assigned_date);

-- Performance indexes for work_order_materials
CREATE INDEX IF NOT EXISTS idx_work_materials_company_id ON bms.work_order_materials(company_id);
CREATE INDEX IF NOT EXISTS idx_work_materials_work_order ON bms.work_order_materials(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_materials_code ON bms.work_order_materials(material_code);
CREATE INDEX IF NOT EXISTS idx_work_materials_category ON bms.work_order_materials(material_category);
CREATE INDEX IF NOT EXISTS idx_work_materials_status ON bms.work_order_materials(material_status);
CREATE INDEX IF NOT EXISTS idx_work_materials_procurement ON bms.work_order_materials(procurement_status);

-- Performance indexes for work_order_progress
CREATE INDEX IF NOT EXISTS idx_work_progress_company_id ON bms.work_order_progress(company_id);
CREATE INDEX IF NOT EXISTS idx_work_progress_work_order ON bms.work_order_progress(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_progress_date ON bms.work_order_progress(progress_date);
CREATE INDEX IF NOT EXISTS idx_work_progress_phase ON bms.work_order_progress(work_phase);
CREATE INDEX IF NOT EXISTS idx_work_progress_reported_by ON bms.work_order_progress(reported_by);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_work_orders_company_status ON bms.work_orders(company_id, work_status);
CREATE INDEX IF NOT EXISTS idx_work_orders_building_status ON bms.work_orders(building_id, work_status);
CREATE INDEX IF NOT EXISTS idx_work_orders_priority_status ON bms.work_orders(work_priority, work_status);
CREATE INDEX IF NOT EXISTS idx_work_orders_assigned_status ON bms.work_orders(assigned_to, work_status);
CREATE INDEX IF NOT EXISTS idx_work_assignments_assigned_status ON bms.work_order_assignments(assigned_to, assignment_status);

-- Updated_at triggers
CREATE TRIGGER work_templates_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_orders_updated_at_trigger
    BEFORE UPDATE ON bms.work_orders
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_assignments_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_assignments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_materials_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_materials
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.work_order_templates IS 'Work order templates - Standardized work order templates for different types of maintenance work';
COMMENT ON TABLE bms.work_orders IS 'Work orders - Comprehensive work order management for repair and maintenance tasks';
COMMENT ON TABLE bms.work_order_assignments IS 'Work order assignments - Assignment of work orders to technicians and contractors';
COMMENT ON TABLE bms.work_order_materials IS 'Work order materials - Material requirements and usage tracking for work orders';
COMMENT ON TABLE bms.work_order_progress IS 'Work order progress - Progress tracking and status updates for work orders';

-- Script completion message
SELECT 'Repair work management system tables created successfully.' as message;