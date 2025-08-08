-- =====================================================
-- Contract Renewal and Management System Tables
-- Phase 3.5.1: Contract Renewal and Management
-- =====================================================

-- 1. Contract renewal processes table
CREATE TABLE IF NOT EXISTS bms.contract_renewal_processes (
    renewal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    
    -- Renewal process information
    renewal_number VARCHAR(50) NOT NULL,
    renewal_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    renewal_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Timeline information
    contract_expiry_date DATE NOT NULL,
    renewal_notice_date DATE,
    renewal_notice_period_days INTEGER,
    tenant_response_deadline DATE,
    landlord_decision_deadline DATE,
    
    -- Renewal terms
    proposed_new_start_date DATE,
    proposed_new_end_date DATE,
    proposed_rent_amount DECIMAL(15,2),
    proposed_rent_increase_pct DECIMAL(5,2),
    proposed_deposit_adjustment DECIMAL(15,2) DEFAULT 0,
    
    -- Negotiation tracking
    negotiation_rounds INTEGER DEFAULT 0,
    current_offer_from VARCHAR(20),
    current_rent_offer DECIMAL(15,2),
    current_terms_offer JSONB,
    
    -- Responses and decisions
    tenant_response VARCHAR(20),
    tenant_response_date DATE,
    tenant_counter_offer JSONB,
    
    landlord_decision VARCHAR(20),
    landlord_decision_date DATE,
    landlord_counter_offer JSONB,
    
    -- Final outcome
    renewal_outcome VARCHAR(20),
    final_rent_amount DECIMAL(15,2),
    final_contract_terms JSONB,
    new_contract_id UUID,
    
    -- Process notes
    renewal_notes TEXT,
    negotiation_history JSONB,
    
    -- Staff assignment
    assigned_staff_id UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_renewals_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_renewals_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_renewals_new_contract FOREIGN KEY (new_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    CONSTRAINT uk_renewals_number UNIQUE (company_id, renewal_number),
    CONSTRAINT uk_renewals_contract UNIQUE (contract_id),
    
    -- Check constraints
    CONSTRAINT chk_renewal_type CHECK (renewal_type IN (
        'STANDARD', 'EARLY', 'AUTOMATIC', 'HOLDOVER', 'MONTH_TO_MONTH'
    )),
    CONSTRAINT chk_renewal_status CHECK (renewal_status IN (
        'PENDING', 'NOTICE_SENT', 'TENANT_RESPONDED', 'NEGOTIATING', 
        'AGREED', 'DECLINED', 'EXPIRED', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT chk_tenant_response CHECK (tenant_response IN (
        'ACCEPT', 'DECLINE', 'COUNTER_OFFER', 'REQUEST_CHANGES', 'NO_RESPONSE'
    ) OR tenant_response IS NULL),
    CONSTRAINT chk_landlord_decision CHECK (landlord_decision IN (
        'APPROVE', 'DECLINE', 'COUNTER_OFFER', 'REQUEST_CHANGES'
    ) OR landlord_decision IS NULL),
    CONSTRAINT chk_renewal_outcome CHECK (renewal_outcome IN (
        'RENEWED', 'NOT_RENEWED', 'HOLDOVER', 'EARLY_TERMINATION'
    ) OR renewal_outcome IS NULL),
    CONSTRAINT chk_current_offer_from CHECK (current_offer_from IN (
        'TENANT', 'LANDLORD'
    ) OR current_offer_from IS NULL),
    CONSTRAINT chk_renewal_dates CHECK (
        proposed_new_end_date IS NULL OR proposed_new_start_date IS NULL OR 
        proposed_new_end_date > proposed_new_start_date
    )
);-- 2
. Rent adjustment policies table
CREATE TABLE IF NOT EXISTS bms.rent_adjustment_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- Policy information
    policy_name VARCHAR(100) NOT NULL,
    policy_description TEXT,
    policy_type VARCHAR(20) NOT NULL DEFAULT 'ANNUAL',
    
    -- Adjustment rules
    base_increase_rate DECIMAL(5,2) DEFAULT 0,
    market_adjustment_factor DECIMAL(5,2) DEFAULT 0,
    inflation_adjustment BOOLEAN DEFAULT false,
    
    -- Caps and limits
    max_increase_rate DECIMAL(5,2) DEFAULT 10.0,
    min_increase_rate DECIMAL(5,2) DEFAULT 0,
    max_increase_amount DECIMAL(10,2),
    
    -- Timing rules
    notice_period_days INTEGER DEFAULT 60,
    effective_frequency_months INTEGER DEFAULT 12,
    
    -- Market conditions
    market_conditions_factor JSONB,
    occupancy_rate_thresholds JSONB,
    
    -- Tenant considerations
    long_term_tenant_discount DECIMAL(5,2) DEFAULT 0,
    good_payment_history_discount DECIMAL(5,2) DEFAULT 0,
    
    -- Status and validity
    is_active BOOLEAN DEFAULT true,
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_rent_policies_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rent_policies_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_rent_policies_name UNIQUE (company_id, building_id, policy_name),
    
    -- Check constraints
    CONSTRAINT chk_policy_type_rent CHECK (policy_type IN (
        'ANNUAL', 'BIANNUAL', 'MARKET_BASED', 'FIXED', 'CUSTOM'
    )),
    CONSTRAINT chk_rent_rates CHECK (
        base_increase_rate >= 0 AND base_increase_rate <= 100 AND
        max_increase_rate >= min_increase_rate AND
        max_increase_rate <= 100 AND min_increase_rate >= 0
    ),
    CONSTRAINT chk_notice_period CHECK (notice_period_days >= 0),
    CONSTRAINT chk_frequency CHECK (effective_frequency_months > 0)
);

-- 3. Contract modifications table
CREATE TABLE IF NOT EXISTS bms.contract_modifications (
    modification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    renewal_id UUID,
    
    -- Modification information
    modification_number VARCHAR(50) NOT NULL,
    modification_type VARCHAR(30) NOT NULL,
    modification_category VARCHAR(20) NOT NULL,
    
    -- Change details
    field_changed VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    
    -- Effective dates
    effective_date DATE DEFAULT CURRENT_DATE,
    requested_date DATE DEFAULT CURRENT_DATE,
    approved_date DATE,
    
    -- Approval workflow
    modification_status VARCHAR(20) DEFAULT 'PENDING',
    requested_by UUID,
    approved_by UUID,
    
    -- Financial impact
    financial_impact DECIMAL(15,2) DEFAULT 0,
    impact_description TEXT,
    
    -- Documentation
    supporting_documents JSONB,
    modification_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_modifications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_modifications_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_modifications_renewal FOREIGN KEY (renewal_id) REFERENCES bms.contract_renewal_processes(renewal_id) ON DELETE SET NULL,
    CONSTRAINT uk_modifications_number UNIQUE (company_id, modification_number),
    
    -- Check constraints
    CONSTRAINT chk_modification_type CHECK (modification_type IN (
        'RENT_ADJUSTMENT', 'TERM_EXTENSION', 'TERM_REDUCTION', 'DEPOSIT_CHANGE',
        'TENANT_CHANGE', 'GUARANTOR_CHANGE', 'TERMS_CHANGE', 'OTHER'
    )),
    CONSTRAINT chk_modification_category CHECK (modification_category IN (
        'FINANCIAL', 'PERSONAL', 'TERMS', 'ADMINISTRATIVE'
    )),
    CONSTRAINT chk_modification_status CHECK (modification_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'IMPLEMENTED', 'CANCELLED'
    ))
);-- 4. R
LS policies and indexes
ALTER TABLE bms.contract_renewal_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.rent_adjustment_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_modifications ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY renewal_processes_isolation_policy ON bms.contract_renewal_processes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY rent_policies_isolation_policy ON bms.rent_adjustment_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_modifications_isolation_policy ON bms.contract_modifications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_renewal_processes_company_id ON bms.contract_renewal_processes(company_id);
CREATE INDEX IF NOT EXISTS idx_renewal_processes_contract_id ON bms.contract_renewal_processes(contract_id);
CREATE INDEX IF NOT EXISTS idx_renewal_processes_status ON bms.contract_renewal_processes(renewal_status);
CREATE INDEX IF NOT EXISTS idx_renewal_processes_expiry_date ON bms.contract_renewal_processes(contract_expiry_date);
CREATE INDEX IF NOT EXISTS idx_renewal_processes_assigned_staff ON bms.contract_renewal_processes(assigned_staff_id);

CREATE INDEX IF NOT EXISTS idx_rent_policies_company_id ON bms.rent_adjustment_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_rent_policies_building_id ON bms.rent_adjustment_policies(building_id);
CREATE INDEX IF NOT EXISTS idx_rent_policies_active ON bms.rent_adjustment_policies(is_active);
CREATE INDEX IF NOT EXISTS idx_rent_policies_type ON bms.rent_adjustment_policies(policy_type);

CREATE INDEX IF NOT EXISTS idx_contract_modifications_company_id ON bms.contract_modifications(company_id);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_contract_id ON bms.contract_modifications(contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_renewal_id ON bms.contract_modifications(renewal_id);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_status ON bms.contract_modifications(modification_status);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_type ON bms.contract_modifications(modification_type);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_effective_date ON bms.contract_modifications(effective_date);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_renewal_processes_company_status ON bms.contract_renewal_processes(company_id, renewal_status);
CREATE INDEX IF NOT EXISTS idx_contract_modifications_contract_status ON bms.contract_modifications(contract_id, modification_status);

-- Updated_at triggers
CREATE TRIGGER renewal_processes_updated_at_trigger
    BEFORE UPDATE ON bms.contract_renewal_processes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER rent_policies_updated_at_trigger
    BEFORE UPDATE ON bms.rent_adjustment_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_modifications_updated_at_trigger
    BEFORE UPDATE ON bms.contract_modifications
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.contract_renewal_processes IS 'Contract renewal processes - Manage contract renewal workflow and negotiations';
COMMENT ON TABLE bms.rent_adjustment_policies IS 'Rent adjustment policies - Define rules and policies for rent increases';
COMMENT ON TABLE bms.contract_modifications IS 'Contract modifications - Track all changes and modifications to lease contracts';

-- Script completion message
SELECT 'Contract renewal and management system tables created successfully.' as message;