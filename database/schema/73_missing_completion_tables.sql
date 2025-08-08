-- =====================================================
-- Missing Completion Management Tables
-- Phase 4.3.3: Create missing tables
-- =====================================================

-- Cost settlements table
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

-- Work warranties table
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

-- Enable RLS
ALTER TABLE bms.work_cost_settlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_warranties ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY cost_settlements_isolation_policy ON bms.work_cost_settlements
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_warranties_isolation_policy ON bms.work_warranties
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_cost_settlements_company_id ON bms.work_cost_settlements(company_id);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_work_order ON bms.work_cost_settlements(work_order_id);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_number ON bms.work_cost_settlements(settlement_number);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_type ON bms.work_cost_settlements(settlement_type);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_status ON bms.work_cost_settlements(settlement_status);
CREATE INDEX IF NOT EXISTS idx_cost_settlements_date ON bms.work_cost_settlements(settlement_date);

CREATE INDEX IF NOT EXISTS idx_work_warranties_company_id ON bms.work_warranties(company_id);
CREATE INDEX IF NOT EXISTS idx_work_warranties_work_order ON bms.work_warranties(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_warranties_number ON bms.work_warranties(warranty_number);
CREATE INDEX IF NOT EXISTS idx_work_warranties_type ON bms.work_warranties(warranty_type);
CREATE INDEX IF NOT EXISTS idx_work_warranties_status ON bms.work_warranties(warranty_status);
CREATE INDEX IF NOT EXISTS idx_work_warranties_start_date ON bms.work_warranties(warranty_start_date);
CREATE INDEX IF NOT EXISTS idx_work_warranties_end_date ON bms.work_warranties(warranty_end_date);

-- Updated_at triggers
CREATE TRIGGER cost_settlements_updated_at_trigger
    BEFORE UPDATE ON bms.work_cost_settlements
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_warranties_updated_at_trigger
    BEFORE UPDATE ON bms.work_warranties
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Add comments
COMMENT ON TABLE bms.work_cost_settlements IS 'Work cost settlements - Cost analysis and financial settlement for completed work';
COMMENT ON TABLE bms.work_warranties IS 'Work warranties - Warranty management for completed work and installed components';

-- Script completion message
SELECT 'Missing completion management tables created successfully.' as message;