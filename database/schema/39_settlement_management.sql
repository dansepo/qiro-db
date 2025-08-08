-- =====================================================
-- Settlement Management System Tables
-- Phase 3.3.3: Settlement Management System
-- =====================================================

-- 1. Settlement processes table
CREATE TABLE IF NOT EXISTS bms.settlement_processes (
    settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    move_out_process_id UUID,
    
    -- Settlement basic information
    settlement_number VARCHAR(50) NOT NULL,
    settlement_date DATE DEFAULT CURRENT_DATE,
    settlement_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Settlement period
    settlement_start_date DATE,
    settlement_end_date DATE,
    
    -- Deposit information
    original_deposit_amount DECIMAL(15,2) DEFAULT 0,
    deposit_interest_amount DECIMAL(15,2) DEFAULT 0,
    total_deposit_available DECIMAL(15,2) DEFAULT 0,
    
    -- Outstanding amounts
    outstanding_rent_amount DECIMAL(15,2) DEFAULT 0,
    outstanding_maintenance_amount DECIMAL(15,2) DEFAULT 0,
    outstanding_utility_amount DECIMAL(15,2) DEFAULT 0,
    outstanding_late_fee_amount DECIMAL(15,2) DEFAULT 0,
    outstanding_other_amount DECIMAL(15,2) DEFAULT 0,
    total_outstanding_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Restoration costs
    restoration_cost_amount DECIMAL(15,2) DEFAULT 0,
    tenant_responsible_restoration DECIMAL(15,2) DEFAULT 0,
    
    -- Additional charges and deductions
    additional_charges_amount DECIMAL(15,2) DEFAULT 0,
    additional_deductions_amount DECIMAL(15,2) DEFAULT 0,
    
    -- Final settlement amounts
    total_deductions DECIMAL(15,2) DEFAULT 0,
    net_refund_amount DECIMAL(15,2) DEFAULT 0,
    additional_payment_required DECIMAL(15,2) DEFAULT 0,
    
    -- Approval and processing
    tenant_acknowledged BOOLEAN DEFAULT false,
    tenant_acknowledgment_date DATE,
    landlord_approved BOOLEAN DEFAULT false,
    landlord_approval_date DATE,
    processed_date DATE,
    
    -- Notes and documentation
    settlement_notes TEXT,
    dispute_notes TEXT,
    attached_documents JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_settlements_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlements_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlements_move_out FOREIGN KEY (move_out_process_id) REFERENCES bms.move_out_processes(process_id) ON DELETE SET NULL,
    CONSTRAINT uk_settlements_number UNIQUE (company_id, settlement_number),
    CONSTRAINT uk_settlements_contract UNIQUE (contract_id),
    
    -- Check constraints
    CONSTRAINT chk_settlement_status CHECK (settlement_status IN (
        'PENDING', 'CALCULATED', 'TENANT_REVIEW', 'DISPUTED', 'APPROVED', 'PROCESSED', 'CANCELLED'
    )),
    CONSTRAINT chk_settlement_amounts CHECK (
        original_deposit_amount >= 0 AND
        deposit_interest_amount >= 0 AND
        total_deposit_available >= 0 AND
        total_outstanding_amount >= 0 AND
        restoration_cost_amount >= 0 AND
        tenant_responsible_restoration >= 0 AND
        total_deductions >= 0 AND
        net_refund_amount >= 0 AND
        additional_payment_required >= 0
    ),
    CONSTRAINT chk_settlement_dates CHECK (
        settlement_end_date >= settlement_start_date AND
        (tenant_acknowledgment_date IS NULL OR tenant_acknowledgment_date >= settlement_date) AND
        (landlord_approval_date IS NULL OR landlord_approval_date >= settlement_date) AND
        (processed_date IS NULL OR processed_date >= settlement_date)
    )
);-- 2. S
ettlement line items table
CREATE TABLE IF NOT EXISTS bms.settlement_line_items (
    line_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    settlement_id UUID NOT NULL,
    
    -- Line item information
    item_category VARCHAR(30) NOT NULL,
    item_type VARCHAR(20) NOT NULL,
    item_description TEXT NOT NULL,
    item_reference_id UUID,
    
    -- Amount information
    item_amount DECIMAL(15,2) NOT NULL,
    is_deduction BOOLEAN DEFAULT true,
    
    -- Period information
    item_start_date DATE,
    item_end_date DATE,
    
    -- Calculation details
    calculation_basis TEXT,
    calculation_details JSONB,
    
    -- Approval status
    is_disputed BOOLEAN DEFAULT false,
    dispute_reason TEXT,
    is_approved BOOLEAN DEFAULT false,
    approved_by UUID,
    approval_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_settlement_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_items_settlement FOREIGN KEY (settlement_id) REFERENCES bms.settlement_processes(settlement_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_item_category CHECK (item_category IN (
        'DEPOSIT_REFUND', 'DEPOSIT_INTEREST', 'OUTSTANDING_RENT', 'OUTSTANDING_MAINTENANCE',
        'OUTSTANDING_UTILITY', 'LATE_FEES', 'RESTORATION_COST', 'CLEANING_FEE',
        'DAMAGE_REPAIR', 'ADDITIONAL_CHARGE', 'ADDITIONAL_DEDUCTION', 'OTHER'
    )),
    CONSTRAINT chk_item_type CHECK (item_type IN (
        'CREDIT', 'DEBIT'
    )),
    CONSTRAINT chk_item_dates CHECK (
        item_end_date IS NULL OR item_start_date IS NULL OR item_end_date >= item_start_date
    )
);

-- 3. Settlement disputes table
CREATE TABLE IF NOT EXISTS bms.settlement_disputes (
    dispute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    settlement_id UUID NOT NULL,
    line_item_id UUID,
    
    -- Dispute information
    dispute_type VARCHAR(20) NOT NULL,
    dispute_category VARCHAR(30) NOT NULL,
    dispute_description TEXT NOT NULL,
    disputed_amount DECIMAL(15,2),
    
    -- Dispute parties
    raised_by VARCHAR(20) NOT NULL,
    raised_date DATE DEFAULT CURRENT_DATE,
    
    -- Resolution information
    dispute_status VARCHAR(20) DEFAULT 'OPEN',
    resolution_description TEXT,
    resolved_amount DECIMAL(15,2),
    resolved_by UUID,
    resolution_date DATE,
    
    -- Communication log
    communication_log JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_disputes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_disputes_settlement FOREIGN KEY (settlement_id) REFERENCES bms.settlement_processes(settlement_id) ON DELETE CASCADE,
    CONSTRAINT fk_disputes_line_item FOREIGN KEY (line_item_id) REFERENCES bms.settlement_line_items(line_item_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_dispute_type CHECK (dispute_type IN (
        'AMOUNT', 'CALCULATION', 'RESPONSIBILITY', 'DOCUMENTATION', 'OTHER'
    )),
    CONSTRAINT chk_dispute_category CHECK (dispute_category IN (
        'DEPOSIT_REFUND', 'OUTSTANDING_FEES', 'RESTORATION_COST', 'DAMAGE_ASSESSMENT',
        'CLEANING_FEE', 'LATE_FEES', 'ADDITIONAL_CHARGES', 'OTHER'
    )),
    CONSTRAINT chk_raised_by CHECK (raised_by IN (
        'TENANT', 'LANDLORD', 'SYSTEM'
    )),
    CONSTRAINT chk_dispute_status CHECK (dispute_status IN (
        'OPEN', 'UNDER_REVIEW', 'RESOLVED', 'ESCALATED', 'CLOSED'
    )),
    CONSTRAINT chk_dispute_amounts CHECK (
        (disputed_amount IS NULL OR disputed_amount >= 0) AND
        (resolved_amount IS NULL OR resolved_amount >= 0)
    )
);--
 4. Settlement payments table
CREATE TABLE IF NOT EXISTS bms.settlement_payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    settlement_id UUID NOT NULL,
    
    -- Payment information
    payment_type VARCHAR(20) NOT NULL,
    payment_amount DECIMAL(15,2) NOT NULL,
    payment_date DATE DEFAULT CURRENT_DATE,
    payment_method VARCHAR(20) DEFAULT 'BANK_TRANSFER',
    
    -- Bank information
    bank_name VARCHAR(100),
    account_number VARCHAR(50),
    account_holder VARCHAR(100),
    
    -- Reference information
    payment_reference VARCHAR(100),
    transaction_id VARCHAR(100),
    
    -- Status
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_by UUID,
    
    -- Constraints
    CONSTRAINT fk_settlement_payments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_payments_settlement FOREIGN KEY (settlement_id) REFERENCES bms.settlement_processes(settlement_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_payment_type CHECK (payment_type IN (
        'REFUND', 'ADDITIONAL_PAYMENT'
    )),
    CONSTRAINT chk_payment_method CHECK (payment_method IN (
        'CASH', 'BANK_TRANSFER', 'CHECK', 'CARD', 'OTHER'
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'
    )),
    CONSTRAINT chk_payment_amount CHECK (payment_amount > 0)
);

-- 5. RLS policies and indexes
ALTER TABLE bms.settlement_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.settlement_line_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.settlement_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.settlement_payments ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY settlements_isolation_policy ON bms.settlement_processes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY settlement_items_isolation_policy ON bms.settlement_line_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY settlement_disputes_isolation_policy ON bms.settlement_disputes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY settlement_payments_isolation_policy ON bms.settlement_payments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_settlements_company_id ON bms.settlement_processes(company_id);
CREATE INDEX IF NOT EXISTS idx_settlements_contract_id ON bms.settlement_processes(contract_id);
CREATE INDEX IF NOT EXISTS idx_settlements_status ON bms.settlement_processes(settlement_status);
CREATE INDEX IF NOT EXISTS idx_settlements_date ON bms.settlement_processes(settlement_date);
CREATE INDEX IF NOT EXISTS idx_settlements_move_out ON bms.settlement_processes(move_out_process_id);

CREATE INDEX IF NOT EXISTS idx_settlement_items_company_id ON bms.settlement_line_items(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_items_settlement_id ON bms.settlement_line_items(settlement_id);
CREATE INDEX IF NOT EXISTS idx_settlement_items_category ON bms.settlement_line_items(item_category);
CREATE INDEX IF NOT EXISTS idx_settlement_items_type ON bms.settlement_line_items(item_type);

CREATE INDEX IF NOT EXISTS idx_settlement_disputes_company_id ON bms.settlement_disputes(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_disputes_settlement_id ON bms.settlement_disputes(settlement_id);
CREATE INDEX IF NOT EXISTS idx_settlement_disputes_status ON bms.settlement_disputes(dispute_status);
CREATE INDEX IF NOT EXISTS idx_settlement_disputes_raised_by ON bms.settlement_disputes(raised_by);

CREATE INDEX IF NOT EXISTS idx_settlement_payments_company_id ON bms.settlement_payments(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_payments_settlement_id ON bms.settlement_payments(settlement_id);
CREATE INDEX IF NOT EXISTS idx_settlement_payments_status ON bms.settlement_payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_settlement_payments_date ON bms.settlement_payments(payment_date);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_settlements_company_status ON bms.settlement_processes(company_id, settlement_status);
CREATE INDEX IF NOT EXISTS idx_settlement_items_settlement_category ON bms.settlement_line_items(settlement_id, item_category);

-- Updated_at triggers
CREATE TRIGGER settlements_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_processes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER settlement_items_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_line_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER settlement_disputes_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_disputes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER settlement_payments_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_payments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.settlement_processes IS 'Settlement processes - Main settlement process management for move-out';
COMMENT ON TABLE bms.settlement_line_items IS 'Settlement line items - Detailed breakdown of settlement calculations';
COMMENT ON TABLE bms.settlement_disputes IS 'Settlement disputes - Dispute management for settlement items';
COMMENT ON TABLE bms.settlement_payments IS 'Settlement payments - Payment processing for settlements';

-- Script completion message
SELECT 'Settlement management system tables created successfully.' as message;