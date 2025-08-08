-- =====================================================
-- Move-out Process Management System Tables
-- Phase 3.3.2: Move-out Process Management
-- =====================================================

-- 1. Move-out checklist templates table
CREATE TABLE IF NOT EXISTS bms.move_out_checklist_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- Template basic information
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    
    -- Checklist items (JSON array)
    checklist_items JSONB NOT NULL,
    
    -- Status and settings
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_move_out_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_out_templates_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_move_out_templates_name UNIQUE (company_id, building_id, template_name),
    
    -- Check constraints
    CONSTRAINT chk_template_type_move_out CHECK (template_type IN (
        'STANDARD', 'PREMIUM', 'COMMERCIAL', 'STUDIO', 'FAMILY', 'CUSTOM'
    ))
);

-- 2. Move-out processes table
CREATE TABLE IF NOT EXISTS bms.move_out_processes (
    process_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    template_id UUID,
    
    -- Process basic information
    process_number VARCHAR(50) NOT NULL,
    process_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Schedule information
    notice_date DATE,
    scheduled_move_out_date DATE,
    actual_move_out_date DATE,
    process_start_date DATE DEFAULT CURRENT_DATE,
    process_completion_date DATE,
    
    -- Notice period information
    notice_period_days INTEGER,
    early_termination BOOLEAN DEFAULT false,
    termination_reason VARCHAR(50),
    
    -- Staff information
    assigned_staff_id UUID,
    contact_person_name VARCHAR(100),
    contact_person_phone VARCHAR(20),
    
    -- Special notes
    special_requirements TEXT,
    process_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_move_out_processes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_out_processes_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_out_processes_template FOREIGN KEY (template_id) REFERENCES bms.move_out_checklist_templates(template_id) ON DELETE SET NULL,
    CONSTRAINT uk_move_out_processes_number UNIQUE (company_id, process_number),
    CONSTRAINT uk_move_out_processes_contract UNIQUE (contract_id),
    
    -- Check constraints
    CONSTRAINT chk_process_status_move_out CHECK (process_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ON_HOLD'
    )),
    CONSTRAINT chk_termination_reason CHECK (termination_reason IN (
        'NORMAL_EXPIRY', 'EARLY_TERMINATION', 'BREACH_OF_CONTRACT', 
        'MUTUAL_AGREEMENT', 'LANDLORD_TERMINATION', 'OTHER'
    )),
    CONSTRAINT chk_move_out_dates CHECK (
        (actual_move_out_date IS NULL OR actual_move_out_date >= process_start_date) AND
        (process_completion_date IS NULL OR process_completion_date >= process_start_date) AND
        (notice_date IS NULL OR scheduled_move_out_date IS NULL OR scheduled_move_out_date >= notice_date)
    )
);-
- 3. Move-out checklist items table
CREATE TABLE IF NOT EXISTS bms.move_out_checklist_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    process_id UUID NOT NULL,
    
    -- Checklist item information
    item_category VARCHAR(50) NOT NULL,
    item_name VARCHAR(200) NOT NULL,
    item_description TEXT,
    item_order INTEGER DEFAULT 0,
    
    -- Execution information
    is_required BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    completion_date TIMESTAMP WITH TIME ZONE,
    completed_by UUID,
    
    -- Results and notes
    completion_result VARCHAR(20) DEFAULT 'PENDING',
    completion_notes TEXT,
    attached_files JSONB,
    
    -- Inspection results (for inspection items)
    inspection_result VARCHAR(20),
    damage_assessment JSONB,
    repair_required BOOLEAN DEFAULT false,
    estimated_repair_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_move_out_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_out_items_process FOREIGN KEY (process_id) REFERENCES bms.move_out_processes(process_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_completion_result_move_out CHECK (completion_result IN (
        'PENDING', 'COMPLETED', 'FAILED', 'SKIPPED', 'DEFERRED'
    )),
    CONSTRAINT chk_item_category_move_out CHECK (item_category IN (
        'DOCUMENTATION', 'INSPECTION', 'KEY_RETURN', 'UTILITIES', 
        'CLEANING', 'REPAIR', 'FINAL_CHECK', 'OTHER'
    )),
    CONSTRAINT chk_inspection_result CHECK (inspection_result IN (
        'GOOD', 'FAIR', 'DAMAGED', 'NEEDS_REPAIR', 'REPLACED'
    ) OR inspection_result IS NULL),
    CONSTRAINT chk_repair_cost CHECK (estimated_repair_cost >= 0)
);

-- 4. Unit condition assessments table
CREATE TABLE IF NOT EXISTS bms.unit_condition_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    process_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- Assessment information
    assessment_date DATE NOT NULL,
    assessment_type VARCHAR(20) NOT NULL DEFAULT 'MOVE_OUT',
    assessed_by UUID,
    
    -- Overall condition
    overall_condition VARCHAR(20) NOT NULL,
    overall_notes TEXT,
    
    -- Room-by-room assessment
    room_assessments JSONB,
    
    -- Damage summary
    total_damages INTEGER DEFAULT 0,
    total_repair_cost DECIMAL(15,2) DEFAULT 0,
    tenant_responsible_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Photos and documentation
    photos JSONB,
    assessment_report_file VARCHAR(500),
    
    -- Approval information
    tenant_acknowledged BOOLEAN DEFAULT false,
    tenant_signature_date DATE,
    landlord_approved BOOLEAN DEFAULT false,
    landlord_approval_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_unit_assessments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_assessments_process FOREIGN KEY (process_id) REFERENCES bms.move_out_processes(process_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_assessments_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_assessment_type CHECK (assessment_type IN (
        'MOVE_IN', 'MOVE_OUT', 'PERIODIC', 'DAMAGE_REPORT'
    )),
    CONSTRAINT chk_overall_condition CHECK (overall_condition IN (
        'EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'DAMAGED'
    )),
    CONSTRAINT chk_assessment_costs CHECK (
        total_repair_cost >= 0 AND tenant_responsible_cost >= 0 AND
        tenant_responsible_cost <= total_repair_cost
    )
);-
- 5. Unit restoration works table
CREATE TABLE IF NOT EXISTS bms.unit_restoration_works (
    work_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    process_id UUID NOT NULL,
    assessment_id UUID,
    
    -- Work information
    work_category VARCHAR(30) NOT NULL,
    work_description TEXT NOT NULL,
    work_location VARCHAR(100),
    
    -- Cost information
    estimated_cost DECIMAL(15,2) NOT NULL,
    actual_cost DECIMAL(15,2),
    tenant_responsibility_percentage DECIMAL(5,2) DEFAULT 100,
    tenant_responsible_amount DECIMAL(15,2),
    
    -- Scheduling
    scheduled_start_date DATE,
    scheduled_completion_date DATE,
    actual_start_date DATE,
    actual_completion_date DATE,
    
    -- Contractor information
    contractor_name VARCHAR(200),
    contractor_contact VARCHAR(100),
    work_order_number VARCHAR(50),
    
    -- Status and results
    work_status VARCHAR(20) DEFAULT 'PLANNED',
    work_quality VARCHAR(20),
    completion_notes TEXT,
    
    -- Documentation
    before_photos JSONB,
    after_photos JSONB,
    receipts JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_restoration_works_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_restoration_works_process FOREIGN KEY (process_id) REFERENCES bms.move_out_processes(process_id) ON DELETE CASCADE,
    CONSTRAINT fk_restoration_works_assessment FOREIGN KEY (assessment_id) REFERENCES bms.unit_condition_assessments(assessment_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_work_category CHECK (work_category IN (
        'CLEANING', 'PAINTING', 'FLOORING', 'PLUMBING', 'ELECTRICAL',
        'APPLIANCE_REPAIR', 'FIXTURE_REPLACEMENT', 'WALL_REPAIR', 'OTHER'
    )),
    CONSTRAINT chk_work_status CHECK (work_status IN (
        'PLANNED', 'SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ON_HOLD'
    )),
    CONSTRAINT chk_work_quality CHECK (work_quality IN (
        'EXCELLENT', 'GOOD', 'SATISFACTORY', 'POOR', 'UNACCEPTABLE'
    ) OR work_quality IS NULL),
    CONSTRAINT chk_work_costs CHECK (
        estimated_cost >= 0 AND 
        (actual_cost IS NULL OR actual_cost >= 0) AND
        tenant_responsibility_percentage >= 0 AND tenant_responsibility_percentage <= 100 AND
        (tenant_responsible_amount IS NULL OR tenant_responsible_amount >= 0)
    ),
    CONSTRAINT chk_work_dates CHECK (
        (actual_start_date IS NULL OR scheduled_start_date IS NULL OR actual_start_date >= scheduled_start_date) AND
        (actual_completion_date IS NULL OR actual_start_date IS NULL OR actual_completion_date >= actual_start_date)
    )
);-- 6. RLS
 policies and indexes
ALTER TABLE bms.move_out_checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.move_out_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.move_out_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.unit_condition_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.unit_restoration_works ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY move_out_templates_isolation_policy ON bms.move_out_checklist_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY move_out_processes_isolation_policy ON bms.move_out_processes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY move_out_items_isolation_policy ON bms.move_out_checklist_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY unit_assessments_isolation_policy ON bms.unit_condition_assessments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY restoration_works_isolation_policy ON bms.unit_restoration_works
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_move_out_templates_company_id ON bms.move_out_checklist_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_move_out_templates_building_id ON bms.move_out_checklist_templates(building_id);
CREATE INDEX IF NOT EXISTS idx_move_out_templates_active ON bms.move_out_checklist_templates(is_active);

CREATE INDEX IF NOT EXISTS idx_move_out_processes_company_id ON bms.move_out_processes(company_id);
CREATE INDEX IF NOT EXISTS idx_move_out_processes_contract_id ON bms.move_out_processes(contract_id);
CREATE INDEX IF NOT EXISTS idx_move_out_processes_status ON bms.move_out_processes(process_status);
CREATE INDEX IF NOT EXISTS idx_move_out_processes_move_out_date ON bms.move_out_processes(scheduled_move_out_date);
CREATE INDEX IF NOT EXISTS idx_move_out_processes_staff ON bms.move_out_processes(assigned_staff_id);

CREATE INDEX IF NOT EXISTS idx_move_out_items_company_id ON bms.move_out_checklist_items(company_id);
CREATE INDEX IF NOT EXISTS idx_move_out_items_process_id ON bms.move_out_checklist_items(process_id);
CREATE INDEX IF NOT EXISTS idx_move_out_items_category ON bms.move_out_checklist_items(item_category);
CREATE INDEX IF NOT EXISTS idx_move_out_items_completed ON bms.move_out_checklist_items(is_completed);

CREATE INDEX IF NOT EXISTS idx_unit_assessments_company_id ON bms.unit_condition_assessments(company_id);
CREATE INDEX IF NOT EXISTS idx_unit_assessments_process_id ON bms.unit_condition_assessments(process_id);
CREATE INDEX IF NOT EXISTS idx_unit_assessments_unit_id ON bms.unit_condition_assessments(unit_id);
CREATE INDEX IF NOT EXISTS idx_unit_assessments_date ON bms.unit_condition_assessments(assessment_date);

CREATE INDEX IF NOT EXISTS idx_restoration_works_company_id ON bms.unit_restoration_works(company_id);
CREATE INDEX IF NOT EXISTS idx_restoration_works_process_id ON bms.unit_restoration_works(process_id);
CREATE INDEX IF NOT EXISTS idx_restoration_works_status ON bms.unit_restoration_works(work_status);
CREATE INDEX IF NOT EXISTS idx_restoration_works_category ON bms.unit_restoration_works(work_category);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_move_out_processes_company_status ON bms.move_out_processes(company_id, process_status);
CREATE INDEX IF NOT EXISTS idx_move_out_items_process_completed ON bms.move_out_checklist_items(process_id, is_completed);

-- Updated_at triggers
CREATE TRIGGER move_out_templates_updated_at_trigger
    BEFORE UPDATE ON bms.move_out_checklist_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER move_out_processes_updated_at_trigger
    BEFORE UPDATE ON bms.move_out_processes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER move_out_items_updated_at_trigger
    BEFORE UPDATE ON bms.move_out_checklist_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER unit_assessments_updated_at_trigger
    BEFORE UPDATE ON bms.unit_condition_assessments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER restoration_works_updated_at_trigger
    BEFORE UPDATE ON bms.unit_restoration_works
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.move_out_checklist_templates IS 'Move-out checklist templates - Building-specific move-out process templates';
COMMENT ON TABLE bms.move_out_processes IS 'Move-out processes - Contract-specific move-out process management';
COMMENT ON TABLE bms.move_out_checklist_items IS 'Move-out checklist items - Detailed checklist items for move-out processes';
COMMENT ON TABLE bms.unit_condition_assessments IS 'Unit condition assessments - Unit condition evaluation during move-out';
COMMENT ON TABLE bms.unit_restoration_works IS 'Unit restoration works - Repair and restoration work management';

-- Script completion message
SELECT 'Move-out process management system tables created successfully.' as message;