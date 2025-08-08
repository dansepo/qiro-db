-- =====================================================
-- Settlement Management Functions
-- Phase 3.3.3: Settlement Management Functions
-- =====================================================

-- 1. Create settlement process function
CREATE OR REPLACE FUNCTION bms.create_settlement_process(
    p_company_id UUID,
    p_contract_id UUID,
    p_move_out_process_id UUID DEFAULT NULL,
    p_settlement_start_date DATE DEFAULT NULL,
    p_settlement_end_date DATE DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_settlement_id UUID;
    v_settlement_number VARCHAR(50);
    v_contract RECORD;
    v_deposit_amount DECIMAL(15,2) := 0;
    v_deposit_interest DECIMAL(15,2) := 0;
BEGIN
    -- Get contract information
    SELECT lc.*, u.unit_number, b.name as building_name
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found: %', p_contract_id;
    END IF;
    
    -- Check if settlement already exists
    IF EXISTS (
        SELECT 1 FROM bms.settlement_processes 
        WHERE contract_id = p_contract_id
    ) THEN
        RAISE EXCEPTION 'Settlement already exists for contract: %', p_contract_id;
    END IF;
    
    -- Generate settlement number
    v_settlement_number := 'ST' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                          REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Get deposit information
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_deposit_amount
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- Calculate deposit interest
    SELECT bms.calculate_deposit_interest(p_company_id, p_contract_id, CURRENT_DATE)
    INTO v_deposit_interest;
    
    -- Set default settlement period if not provided
    IF p_settlement_start_date IS NULL THEN
        p_settlement_start_date := v_contract.contract_start_date;
    END IF;
    
    IF p_settlement_end_date IS NULL THEN
        p_settlement_end_date := COALESCE(v_contract.contract_end_date, CURRENT_DATE);
    END IF;
    
    -- Create settlement process
    INSERT INTO bms.settlement_processes (
        company_id,
        contract_id,
        move_out_process_id,
        settlement_number,
        settlement_start_date,
        settlement_end_date,
        original_deposit_amount,
        deposit_interest_amount,
        total_deposit_available,
        created_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        p_move_out_process_id,
        v_settlement_number,
        p_settlement_start_date,
        p_settlement_end_date,
        v_deposit_amount,
        v_deposit_interest,
        v_deposit_amount + v_deposit_interest,
        p_created_by
    ) RETURNING settlement_id INTO v_settlement_id;
    
    -- Calculate settlement automatically
    PERFORM bms.calculate_settlement_amounts(v_settlement_id);
    
    RETURN v_settlement_id;
END;
$$;-
- 2. Calculate settlement amounts function
CREATE OR REPLACE FUNCTION bms.calculate_settlement_amounts(
    p_settlement_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_settlement RECORD;
    v_outstanding_rent DECIMAL(15,2) := 0;
    v_outstanding_maintenance DECIMAL(15,2) := 0;
    v_outstanding_utility DECIMAL(15,2) := 0;
    v_outstanding_late_fee DECIMAL(15,2) := 0;
    v_restoration_cost DECIMAL(15,2) := 0;
    v_tenant_responsible_restoration DECIMAL(15,2) := 0;
    v_total_deductions DECIMAL(15,2) := 0;
    v_net_refund DECIMAL(15,2) := 0;
    v_additional_payment DECIMAL(15,2) := 0;
BEGIN
    -- Get settlement information
    SELECT * INTO v_settlement
    FROM bms.settlement_processes
    WHERE settlement_id = p_settlement_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Settlement not found: %', p_settlement_id;
    END IF;
    
    -- Calculate outstanding rental fees
    SELECT COALESCE(SUM(
        rfc.total_charge_amount + rfc.late_fee_amount - 
        COALESCE(payments.total_paid, 0)
    ), 0)
    INTO v_outstanding_rent
    FROM bms.rental_fee_charges rfc
    LEFT JOIN (
        SELECT 
            charge_id,
            SUM(payment_amount) as total_paid
        FROM bms.rental_fee_payments
        WHERE payment_status = 'COMPLETED' AND is_cancelled = false
        GROUP BY charge_id
    ) payments ON rfc.charge_id = payments.charge_id
    WHERE rfc.contract_id = v_settlement.contract_id
    AND rfc.charge_status != 'CANCELLED'
    AND (rfc.total_charge_amount + rfc.late_fee_amount - COALESCE(payments.total_paid, 0)) > 0;
    
    -- Get restoration costs from move-out process
    IF v_settlement.move_out_process_id IS NOT NULL THEN
        SELECT 
            COALESCE(SUM(COALESCE(actual_cost, estimated_cost)), 0),
            COALESCE(SUM(tenant_responsible_amount), 0)
        INTO v_restoration_cost, v_tenant_responsible_restoration
        FROM bms.unit_restoration_works
        WHERE process_id = v_settlement.move_out_process_id;
    END IF;
    
    -- Calculate total deductions
    v_total_deductions := v_outstanding_rent + v_outstanding_maintenance + 
                         v_outstanding_utility + v_outstanding_late_fee + 
                         v_tenant_responsible_restoration;
    
    -- Calculate net refund or additional payment required
    IF v_settlement.total_deposit_available >= v_total_deductions THEN
        v_net_refund := v_settlement.total_deposit_available - v_total_deductions;
        v_additional_payment := 0;
    ELSE
        v_net_refund := 0;
        v_additional_payment := v_total_deductions - v_settlement.total_deposit_available;
    END IF;
    
    -- Update settlement with calculated amounts
    UPDATE bms.settlement_processes
    SET outstanding_rent_amount = v_outstanding_rent,
        outstanding_maintenance_amount = v_outstanding_maintenance,
        outstanding_utility_amount = v_outstanding_utility,
        outstanding_late_fee_amount = v_outstanding_late_fee,
        total_outstanding_amount = v_outstanding_rent + v_outstanding_maintenance + 
                                  v_outstanding_utility + v_outstanding_late_fee,
        restoration_cost_amount = v_restoration_cost,
        tenant_responsible_restoration = v_tenant_responsible_restoration,
        total_deductions = v_total_deductions,
        net_refund_amount = v_net_refund,
        additional_payment_required = v_additional_payment,
        settlement_status = 'CALCULATED',
        updated_at = NOW()
    WHERE settlement_id = p_settlement_id;
    
    -- Create settlement line items
    PERFORM bms.create_settlement_line_items(p_settlement_id);
    
    RETURN true;
END;
$$;-
- 3. Create settlement line items function
CREATE OR REPLACE FUNCTION bms.create_settlement_line_items(
    p_settlement_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_settlement RECORD;
BEGIN
    -- Get settlement information
    SELECT * INTO v_settlement
    FROM bms.settlement_processes
    WHERE settlement_id = p_settlement_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Clear existing line items
    DELETE FROM bms.settlement_line_items WHERE settlement_id = p_settlement_id;
    
    -- Add deposit refund (credit)
    IF v_settlement.original_deposit_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'DEPOSIT_REFUND', 'CREDIT',
            'Original deposit refund', v_settlement.original_deposit_amount, false
        );
    END IF;
    
    -- Add deposit interest (credit)
    IF v_settlement.deposit_interest_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'DEPOSIT_INTEREST', 'CREDIT',
            'Deposit interest', v_settlement.deposit_interest_amount, false
        );
    END IF;
    
    -- Add outstanding rent (debit)
    IF v_settlement.outstanding_rent_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'OUTSTANDING_RENT', 'DEBIT',
            'Outstanding rental fees', v_settlement.outstanding_rent_amount, true
        );
    END IF;
    
    -- Add outstanding maintenance (debit)
    IF v_settlement.outstanding_maintenance_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'OUTSTANDING_MAINTENANCE', 'DEBIT',
            'Outstanding maintenance fees', v_settlement.outstanding_maintenance_amount, true
        );
    END IF;
    
    -- Add outstanding utility (debit)
    IF v_settlement.outstanding_utility_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'OUTSTANDING_UTILITY', 'DEBIT',
            'Outstanding utility fees', v_settlement.outstanding_utility_amount, true
        );
    END IF;
    
    -- Add late fees (debit)
    IF v_settlement.outstanding_late_fee_amount > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'LATE_FEES', 'DEBIT',
            'Late payment fees', v_settlement.outstanding_late_fee_amount, true
        );
    END IF;
    
    -- Add restoration costs (debit)
    IF v_settlement.tenant_responsible_restoration > 0 THEN
        INSERT INTO bms.settlement_line_items (
            company_id, settlement_id, item_category, item_type,
            item_description, item_amount, is_deduction
        ) VALUES (
            v_settlement.company_id, p_settlement_id, 'RESTORATION_COST', 'DEBIT',
            'Unit restoration costs', v_settlement.tenant_responsible_restoration, true
        );
    END IF;
    
    RETURN true;
END;
$$;-- 4. 
Add settlement line item function
CREATE OR REPLACE FUNCTION bms.add_settlement_line_item(
    p_settlement_id UUID,
    p_item_category VARCHAR(30),
    p_item_type VARCHAR(20),
    p_item_description TEXT,
    p_item_amount DECIMAL(15,2),
    p_is_deduction BOOLEAN DEFAULT true,
    p_calculation_basis TEXT DEFAULT NULL,
    p_calculation_details JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_line_item_id UUID;
    v_settlement RECORD;
BEGIN
    -- Get settlement information
    SELECT * INTO v_settlement
    FROM bms.settlement_processes
    WHERE settlement_id = p_settlement_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Settlement not found: %', p_settlement_id;
    END IF;
    
    -- Create line item
    INSERT INTO bms.settlement_line_items (
        company_id,
        settlement_id,
        item_category,
        item_type,
        item_description,
        item_amount,
        is_deduction,
        calculation_basis,
        calculation_details
    ) VALUES (
        v_settlement.company_id,
        p_settlement_id,
        p_item_category,
        p_item_type,
        p_item_description,
        p_item_amount,
        p_is_deduction,
        p_calculation_basis,
        p_calculation_details
    ) RETURNING line_item_id INTO v_line_item_id;
    
    -- Recalculate settlement totals
    PERFORM bms.recalculate_settlement_totals(p_settlement_id);
    
    RETURN v_line_item_id;
END;
$$;

-- 5. Recalculate settlement totals function
CREATE OR REPLACE FUNCTION bms.recalculate_settlement_totals(
    p_settlement_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_settlement RECORD;
    v_total_credits DECIMAL(15,2) := 0;
    v_total_debits DECIMAL(15,2) := 0;
    v_net_refund DECIMAL(15,2) := 0;
    v_additional_payment DECIMAL(15,2) := 0;
BEGIN
    -- Get settlement information
    SELECT * INTO v_settlement
    FROM bms.settlement_processes
    WHERE settlement_id = p_settlement_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Calculate total credits
    SELECT COALESCE(SUM(item_amount), 0)
    INTO v_total_credits
    FROM bms.settlement_line_items
    WHERE settlement_id = p_settlement_id
    AND item_type = 'CREDIT'
    AND is_approved = true;
    
    -- Calculate total debits
    SELECT COALESCE(SUM(item_amount), 0)
    INTO v_total_debits
    FROM bms.settlement_line_items
    WHERE settlement_id = p_settlement_id
    AND item_type = 'DEBIT'
    AND is_approved = true;
    
    -- Calculate net amounts
    IF v_total_credits >= v_total_debits THEN
        v_net_refund := v_total_credits - v_total_debits;
        v_additional_payment := 0;
    ELSE
        v_net_refund := 0;
        v_additional_payment := v_total_debits - v_total_credits;
    END IF;
    
    -- Update settlement totals
    UPDATE bms.settlement_processes
    SET total_deductions = v_total_debits,
        net_refund_amount = v_net_refund,
        additional_payment_required = v_additional_payment,
        updated_at = NOW()
    WHERE settlement_id = p_settlement_id;
    
    RETURN true;
END;
$$;-- 6. Crea
te settlement dispute function
CREATE OR REPLACE FUNCTION bms.create_settlement_dispute(
    p_company_id UUID,
    p_settlement_id UUID,
    p_line_item_id UUID DEFAULT NULL,
    p_dispute_type VARCHAR(20),
    p_dispute_category VARCHAR(30),
    p_dispute_description TEXT,
    p_disputed_amount DECIMAL(15,2) DEFAULT NULL,
    p_raised_by VARCHAR(20) DEFAULT 'TENANT'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_dispute_id UUID;
BEGIN
    -- Create dispute
    INSERT INTO bms.settlement_disputes (
        company_id,
        settlement_id,
        line_item_id,
        dispute_type,
        dispute_category,
        dispute_description,
        disputed_amount,
        raised_by
    ) VALUES (
        p_company_id,
        p_settlement_id,
        p_line_item_id,
        p_dispute_type,
        p_dispute_category,
        p_dispute_description,
        p_disputed_amount,
        p_raised_by
    ) RETURNING dispute_id INTO v_dispute_id;
    
    -- Update settlement status to disputed
    UPDATE bms.settlement_processes
    SET settlement_status = 'DISPUTED',
        updated_at = NOW()
    WHERE settlement_id = p_settlement_id;
    
    -- Mark line item as disputed if specified
    IF p_line_item_id IS NOT NULL THEN
        UPDATE bms.settlement_line_items
        SET is_disputed = true,
            updated_at = NOW()
        WHERE line_item_id = p_line_item_id;
    END IF;
    
    RETURN v_dispute_id;
END;
$$;

-- 7. Resolve settlement dispute function
CREATE OR REPLACE FUNCTION bms.resolve_settlement_dispute(
    p_dispute_id UUID,
    p_resolution_description TEXT,
    p_resolved_amount DECIMAL(15,2) DEFAULT NULL,
    p_resolved_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_dispute RECORD;
    v_remaining_disputes INTEGER;
BEGIN
    -- Get dispute information
    SELECT * INTO v_dispute
    FROM bms.settlement_disputes
    WHERE dispute_id = p_dispute_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dispute not found: %', p_dispute_id;
    END IF;
    
    -- Update dispute
    UPDATE bms.settlement_disputes
    SET dispute_status = 'RESOLVED',
        resolution_description = p_resolution_description,
        resolved_amount = p_resolved_amount,
        resolved_by = p_resolved_by,
        resolution_date = CURRENT_DATE,
        updated_at = NOW()
    WHERE dispute_id = p_dispute_id;
    
    -- Update line item if resolved amount is different
    IF v_dispute.line_item_id IS NOT NULL AND p_resolved_amount IS NOT NULL THEN
        UPDATE bms.settlement_line_items
        SET item_amount = p_resolved_amount,
            is_disputed = false,
            updated_at = NOW()
        WHERE line_item_id = v_dispute.line_item_id;
        
        -- Recalculate settlement totals
        PERFORM bms.recalculate_settlement_totals(v_dispute.settlement_id);
    END IF;
    
    -- Check if there are any remaining open disputes
    SELECT COUNT(*)
    INTO v_remaining_disputes
    FROM bms.settlement_disputes
    WHERE settlement_id = v_dispute.settlement_id
    AND dispute_status IN ('OPEN', 'UNDER_REVIEW');
    
    -- Update settlement status if no more disputes
    IF v_remaining_disputes = 0 THEN
        UPDATE bms.settlement_processes
        SET settlement_status = 'CALCULATED',
            updated_at = NOW()
        WHERE settlement_id = v_dispute.settlement_id;
    END IF;
    
    RETURN true;
END;
$$;-- 8. Appro
ve settlement function
CREATE OR REPLACE FUNCTION bms.approve_settlement(
    p_settlement_id UUID,
    p_approved_by VARCHAR(20) DEFAULT 'LANDLORD',
    p_approver_id UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    -- Update settlement approval
    IF p_approved_by = 'TENANT' THEN
        UPDATE bms.settlement_processes
        SET tenant_acknowledged = true,
            tenant_acknowledgment_date = CURRENT_DATE,
            settlement_status = CASE 
                WHEN landlord_approved = true THEN 'APPROVED'
                ELSE 'TENANT_REVIEW'
            END,
            updated_at = NOW()
        WHERE settlement_id = p_settlement_id;
    ELSIF p_approved_by = 'LANDLORD' THEN
        UPDATE bms.settlement_processes
        SET landlord_approved = true,
            landlord_approval_date = CURRENT_DATE,
            settlement_status = CASE 
                WHEN tenant_acknowledged = true THEN 'APPROVED'
                ELSE 'CALCULATED'
            END,
            updated_at = NOW()
        WHERE settlement_id = p_settlement_id;
    END IF;
    
    -- Approve all line items
    UPDATE bms.settlement_line_items
    SET is_approved = true,
        approved_by = p_approver_id,
        approval_date = CURRENT_DATE,
        updated_at = NOW()
    WHERE settlement_id = p_settlement_id
    AND is_disputed = false;
    
    -- Recalculate totals with approved items only
    PERFORM bms.recalculate_settlement_totals(p_settlement_id);
    
    RETURN true;
END;
$$;

-- 9. Process settlement payment function
CREATE OR REPLACE FUNCTION bms.process_settlement_payment(
    p_settlement_id UUID,
    p_payment_type VARCHAR(20),
    p_payment_amount DECIMAL(15,2),
    p_payment_method VARCHAR(20) DEFAULT 'BANK_TRANSFER',
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_account_number VARCHAR(50) DEFAULT NULL,
    p_account_holder VARCHAR(100) DEFAULT NULL,
    p_payment_reference VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_payment_id UUID;
    v_settlement RECORD;
BEGIN
    -- Get settlement information
    SELECT * INTO v_settlement
    FROM bms.settlement_processes
    WHERE settlement_id = p_settlement_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Settlement not found: %', p_settlement_id;
    END IF;
    
    -- Validate payment amount
    IF p_payment_type = 'REFUND' AND p_payment_amount > v_settlement.net_refund_amount THEN
        RAISE EXCEPTION 'Refund amount exceeds net refund amount';
    ELSIF p_payment_type = 'ADDITIONAL_PAYMENT' AND p_payment_amount > v_settlement.additional_payment_required THEN
        RAISE EXCEPTION 'Additional payment exceeds required amount';
    END IF;
    
    -- Create payment record
    INSERT INTO bms.settlement_payments (
        company_id,
        settlement_id,
        payment_type,
        payment_amount,
        payment_method,
        bank_name,
        account_number,
        account_holder,
        payment_reference,
        processed_by
    ) VALUES (
        v_settlement.company_id,
        p_settlement_id,
        p_payment_type,
        p_payment_amount,
        p_payment_method,
        p_bank_name,
        p_account_number,
        p_account_holder,
        p_payment_reference,
        p_processed_by
    ) RETURNING payment_id INTO v_payment_id;
    
    -- Update settlement status to processed
    UPDATE bms.settlement_processes
    SET settlement_status = 'PROCESSED',
        processed_date = CURRENT_DATE,
        updated_at = NOW()
    WHERE settlement_id = p_settlement_id;
    
    RETURN v_payment_id;
END;
$$;-- 10. Se
ttlement status view
CREATE OR REPLACE VIEW bms.v_settlement_status AS
SELECT 
    sp.settlement_id,
    sp.company_id,
    sp.contract_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- Settlement information
    sp.settlement_number,
    sp.settlement_date,
    sp.settlement_status,
    sp.settlement_start_date,
    sp.settlement_end_date,
    
    -- Deposit information
    sp.original_deposit_amount,
    sp.deposit_interest_amount,
    sp.total_deposit_available,
    
    -- Outstanding amounts
    sp.total_outstanding_amount,
    sp.outstanding_rent_amount,
    sp.outstanding_maintenance_amount,
    sp.outstanding_utility_amount,
    sp.outstanding_late_fee_amount,
    
    -- Restoration costs
    sp.restoration_cost_amount,
    sp.tenant_responsible_restoration,
    
    -- Final amounts
    sp.total_deductions,
    sp.net_refund_amount,
    sp.additional_payment_required,
    
    -- Approval status
    sp.tenant_acknowledged,
    sp.tenant_acknowledgment_date,
    sp.landlord_approved,
    sp.landlord_approval_date,
    sp.processed_date,
    
    -- Line items summary
    COALESCE(line_items.total_items, 0) as total_line_items,
    COALESCE(line_items.disputed_items, 0) as disputed_line_items,
    COALESCE(line_items.approved_items, 0) as approved_line_items,
    
    -- Disputes summary
    COALESCE(disputes.total_disputes, 0) as total_disputes,
    COALESCE(disputes.open_disputes, 0) as open_disputes,
    COALESCE(disputes.resolved_disputes, 0) as resolved_disputes,
    
    -- Payments summary
    COALESCE(payments.total_payments, 0) as total_payments,
    COALESCE(payments.total_payment_amount, 0) as total_payment_amount,
    
    -- Status display
    CASE 
        WHEN sp.settlement_status = 'PENDING' THEN 'PENDING'
        WHEN sp.settlement_status = 'CALCULATED' THEN 'CALCULATED'
        WHEN sp.settlement_status = 'TENANT_REVIEW' THEN 'TENANT_REVIEW'
        WHEN sp.settlement_status = 'DISPUTED' THEN 'DISPUTED'
        WHEN sp.settlement_status = 'APPROVED' THEN 'APPROVED'
        WHEN sp.settlement_status = 'PROCESSED' THEN 'PROCESSED'
        WHEN sp.settlement_status = 'CANCELLED' THEN 'CANCELLED'
        ELSE sp.settlement_status
    END as status_display,
    
    -- Tenant information
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone
    
FROM bms.settlement_processes sp
JOIN bms.lease_contracts lc ON sp.contract_id = lc.contract_id
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN (
    SELECT 
        settlement_id,
        COUNT(*) as total_items,
        COUNT(*) FILTER (WHERE is_disputed = true) as disputed_items,
        COUNT(*) FILTER (WHERE is_approved = true) as approved_items
    FROM bms.settlement_line_items
    GROUP BY settlement_id
) line_items ON sp.settlement_id = line_items.settlement_id
LEFT JOIN (
    SELECT 
        settlement_id,
        COUNT(*) as total_disputes,
        COUNT(*) FILTER (WHERE dispute_status IN ('OPEN', 'UNDER_REVIEW')) as open_disputes,
        COUNT(*) FILTER (WHERE dispute_status = 'RESOLVED') as resolved_disputes
    FROM bms.settlement_disputes
    GROUP BY settlement_id
) disputes ON sp.settlement_id = disputes.settlement_id
LEFT JOIN (
    SELECT 
        settlement_id,
        COUNT(*) as total_payments,
        SUM(payment_amount) as total_payment_amount
    FROM bms.settlement_payments
    WHERE payment_status = 'COMPLETED'
    GROUP BY settlement_id
) payments ON sp.settlement_id = payments.settlement_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true;-- 11. S
ettlement statistics view
CREATE OR REPLACE VIEW bms.v_settlement_statistics AS
SELECT 
    company_id,
    
    -- Overall statistics
    COUNT(*) as total_settlements,
    
    -- Status statistics
    COUNT(*) FILTER (WHERE settlement_status = 'PENDING') as pending_count,
    COUNT(*) FILTER (WHERE settlement_status = 'CALCULATED') as calculated_count,
    COUNT(*) FILTER (WHERE settlement_status = 'TENANT_REVIEW') as tenant_review_count,
    COUNT(*) FILTER (WHERE settlement_status = 'DISPUTED') as disputed_count,
    COUNT(*) FILTER (WHERE settlement_status = 'APPROVED') as approved_count,
    COUNT(*) FILTER (WHERE settlement_status = 'PROCESSED') as processed_count,
    COUNT(*) FILTER (WHERE settlement_status = 'CANCELLED') as cancelled_count,
    
    -- Financial statistics
    AVG(original_deposit_amount) as avg_deposit_amount,
    AVG(net_refund_amount) as avg_refund_amount,
    AVG(additional_payment_required) as avg_additional_payment,
    AVG(total_deductions) as avg_total_deductions,
    
    -- Sum totals
    SUM(original_deposit_amount) as total_deposits,
    SUM(net_refund_amount) as total_refunds,
    SUM(additional_payment_required) as total_additional_payments,
    SUM(total_deductions) as total_deductions_sum,
    
    -- Processing statistics
    COUNT(*) FILTER (WHERE tenant_acknowledged = true) as tenant_acknowledged_count,
    COUNT(*) FILTER (WHERE landlord_approved = true) as landlord_approved_count,
    
    -- Dispute statistics
    COUNT(*) FILTER (WHERE settlement_status = 'DISPUTED') as settlements_with_disputes,
    
    -- This month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', settlement_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_settlements,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', processed_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_processed,
    
    -- Latest update time
    MAX(updated_at) as last_updated_at
    
FROM bms.settlement_processes
GROUP BY company_id;

-- 12. Comments
COMMENT ON FUNCTION bms.create_settlement_process(UUID, UUID, UUID, DATE, DATE, UUID) IS 'Create settlement process - Initialize settlement process with deposit and contract information';
COMMENT ON FUNCTION bms.calculate_settlement_amounts(UUID) IS 'Calculate settlement amounts - Calculate all outstanding amounts and deductions for settlement';
COMMENT ON FUNCTION bms.create_settlement_line_items(UUID) IS 'Create settlement line items - Generate detailed line items for settlement calculation';
COMMENT ON FUNCTION bms.add_settlement_line_item(UUID, VARCHAR, VARCHAR, TEXT, DECIMAL, BOOLEAN, TEXT, JSONB) IS 'Add settlement line item - Add custom line item to settlement';
COMMENT ON FUNCTION bms.recalculate_settlement_totals(UUID) IS 'Recalculate settlement totals - Recalculate settlement totals based on approved line items';
COMMENT ON FUNCTION bms.create_settlement_dispute(UUID, UUID, UUID, VARCHAR, VARCHAR, TEXT, DECIMAL, VARCHAR) IS 'Create settlement dispute - Create dispute for settlement item';
COMMENT ON FUNCTION bms.resolve_settlement_dispute(UUID, TEXT, DECIMAL, UUID) IS 'Resolve settlement dispute - Resolve dispute and update settlement amounts';
COMMENT ON FUNCTION bms.approve_settlement(UUID, VARCHAR, UUID) IS 'Approve settlement - Approve settlement by tenant or landlord';
COMMENT ON FUNCTION bms.process_settlement_payment(UUID, VARCHAR, DECIMAL, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID) IS 'Process settlement payment - Process refund or additional payment for settlement';

COMMENT ON VIEW bms.v_settlement_status IS 'Settlement status view - Comprehensive view of settlement process status and amounts';
COMMENT ON VIEW bms.v_settlement_statistics IS 'Settlement statistics view - Company-wise settlement statistics and financial summaries';

-- Script completion message
SELECT 'Settlement management functions created successfully.' as message;