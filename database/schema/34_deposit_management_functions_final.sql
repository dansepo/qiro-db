-- =====================================================
-- Deposit Management Functions
-- Phase 3.2.3: Deposit Management Functions
-- =====================================================

-- 1. Process deposit receipt function
CREATE OR REPLACE FUNCTION bms.process_deposit_receipt(
    p_company_id UUID,
    p_contract_id UUID,
    p_deposit_amount DECIMAL(15,2),
    p_receipt_date DATE,
    p_payment_method VARCHAR(20),
    p_payment_reference VARCHAR(100) DEFAULT NULL,
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_account_number VARCHAR(50) DEFAULT NULL,
    p_account_holder VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_receipt_id UUID;
    v_receipt_number VARCHAR(50);
    v_contract RECORD;
    v_total_received DECIMAL(15,2);
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
    
    -- Generate receipt number
    v_receipt_number := 'DR' || TO_CHAR(p_receipt_date, 'YYYYMMDD') || '-' || 
                       REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Check existing received amount
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_total_received
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- Check for over-receipt
    IF (v_total_received + p_deposit_amount) > v_contract.deposit_amount THEN
        RAISE EXCEPTION 'Deposit over-receipt. Contract deposit: %, Existing: %, Additional: %', 
            v_contract.deposit_amount, v_total_received, p_deposit_amount;
    END IF;
    
    -- Create deposit receipt record
    INSERT INTO bms.deposit_receipts (
        company_id,
        contract_id,
        receipt_number,
        deposit_amount,
        receipt_date,
        payment_method,
        payment_reference,
        bank_name,
        account_number,
        account_holder,
        processed_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_receipt_number,
        p_deposit_amount,
        p_receipt_date,
        p_payment_method,
        p_payment_reference,
        p_bank_name,
        p_account_number,
        p_account_holder,
        p_processed_by
    ) RETURNING receipt_id INTO v_receipt_id;
    
    RETURN v_receipt_id;
END;
$$;-- 2. Calcul
ate deposit interest function
CREATE OR REPLACE FUNCTION bms.calculate_deposit_interest(
    p_company_id UUID,
    p_contract_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(15,2) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_deposit_amount DECIMAL(15,2);
    v_interest_rate DECIMAL(5,4);
    v_interest_amount DECIMAL(15,2) := 0;
    v_days_held INTEGER;
    v_annual_interest DECIMAL(15,2);
BEGIN
    -- Get contract information
    SELECT lc.*
    INTO v_contract
    FROM bms.lease_contracts lc
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found: %', p_contract_id;
    END IF;
    
    -- Check deposit amount
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_deposit_amount
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- Return 0 if no deposit
    IF v_deposit_amount = 0 THEN
        RETURN 0;
    END IF;
    
    -- Set interest rate (default: 1.5% annually)
    v_interest_rate := 0.015;
    
    -- Calculate days held
    v_days_held := p_calculation_date - v_contract.contract_start_date;
    
    -- Calculate interest (daily calculation)
    IF v_days_held > 0 THEN
        v_annual_interest := v_deposit_amount * v_interest_rate;
        v_interest_amount := v_annual_interest * v_days_held / 365;
        
        -- Round to 2 decimal places
        v_interest_amount := ROUND(v_interest_amount, 2);
    END IF;
    
    RETURN v_interest_amount;
END;
$$;-- 3. 
Process deposit refund function
CREATE OR REPLACE FUNCTION bms.process_deposit_refund(
    p_company_id UUID,
    p_contract_id UUID,
    p_refund_date DATE,
    p_refund_amount DECIMAL(15,2),
    p_interest_amount DECIMAL(15,2) DEFAULT 0,
    p_deduction_amount DECIMAL(15,2) DEFAULT 0,
    p_deduction_reason TEXT DEFAULT NULL,
    p_refund_method VARCHAR(20) DEFAULT 'BANK_TRANSFER',
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_account_number VARCHAR(50) DEFAULT NULL,
    p_account_holder VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_refund_id UUID;
    v_refund_number VARCHAR(50);
    v_contract RECORD;
    v_total_received DECIMAL(15,2);
    v_net_refund_amount DECIMAL(15,2);
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
    
    -- Generate refund number
    v_refund_number := 'DF' || TO_CHAR(p_refund_date, 'YYYYMMDD') || '-' || 
                      REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                      LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Check total received deposit
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_total_received
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- Check refundable amount
    IF p_refund_amount > v_total_received THEN
        RAISE EXCEPTION 'Refund amount exceeds received deposit. Received: %, Requested: %', 
            v_total_received, p_refund_amount;
    END IF;
    
    -- Calculate net refund amount
    v_net_refund_amount := p_refund_amount + p_interest_amount - p_deduction_amount;
    
    -- Create deposit refund record
    INSERT INTO bms.deposit_refunds (
        company_id,
        contract_id,
        refund_number,
        refund_date,
        deposit_refund_amount,
        interest_amount,
        deduction_amount,
        deduction_reason,
        net_refund_amount,
        refund_method,
        bank_name,
        account_number,
        account_holder,
        processed_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_refund_number,
        p_refund_date,
        p_refund_amount,
        p_interest_amount,
        p_deduction_amount,
        p_deduction_reason,
        v_net_refund_amount,
        p_refund_method,
        p_bank_name,
        p_account_number,
        p_account_holder,
        p_processed_by
    ) RETURNING refund_id INTO v_refund_id;
    
    RETURN v_refund_id;
END;
$$;-- 4. 
Deposit status view
CREATE OR REPLACE VIEW bms.v_deposit_status AS
SELECT 
    lc.contract_id,
    lc.company_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- Contract information
    lc.deposit_amount as contract_deposit_amount,
    lc.contract_start_date,
    lc.contract_end_date,
    
    -- Receipt information
    COALESCE(receipts.total_received, 0) as total_received_amount,
    COALESCE(receipts.receipt_count, 0) as receipt_count,
    receipts.last_receipt_date,
    
    -- Refund information
    COALESCE(refunds.total_refunded, 0) as total_refunded_amount,
    COALESCE(refunds.refund_count, 0) as refund_count,
    refunds.last_refund_date,
    
    -- Calculated fields
    (lc.deposit_amount - COALESCE(receipts.total_received, 0)) as outstanding_amount,
    
    -- Interest calculation
    bms.calculate_deposit_interest(lc.company_id, lc.contract_id, CURRENT_DATE) as accrued_interest,
    
    -- Status display
    CASE 
        WHEN COALESCE(receipts.total_received, 0) >= lc.deposit_amount THEN
            CASE 
                WHEN COALESCE(refunds.total_refunded, 0) >= COALESCE(receipts.total_received, 0) THEN 'REFUNDED'
                WHEN COALESCE(refunds.total_refunded, 0) > 0 THEN 'PARTIAL_REFUNDED'
                ELSE 'RECEIVED'
            END
        WHEN COALESCE(receipts.total_received, 0) > 0 THEN 'PARTIAL_RECEIVED'
        ELSE 'PENDING'
    END as deposit_status,
    
    -- Tenant information
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone
    
FROM bms.lease_contracts lc
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN (
    SELECT 
        contract_id,
        SUM(deposit_amount) as total_received,
        COUNT(*) as receipt_count,
        MAX(receipt_date) as last_receipt_date
    FROM bms.deposit_receipts
    WHERE receipt_status = 'COMPLETED' AND is_cancelled = false
    GROUP BY contract_id
) receipts ON lc.contract_id = receipts.contract_id
LEFT JOIN (
    SELECT 
        contract_id,
        SUM(deposit_refund_amount) as total_refunded,
        COUNT(*) as refund_count,
        MAX(refund_date) as last_refund_date
    FROM bms.deposit_refunds
    WHERE refund_status = 'COMPLETED' AND is_cancelled = false
    GROUP BY contract_id
) refunds ON lc.contract_id = refunds.contract_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true
WHERE lc.contract_status != 'CANCELLED';-- 5.
 Deposit statistics view
CREATE OR REPLACE VIEW bms.v_deposit_statistics AS
SELECT 
    company_id,
    
    -- Overall statistics
    COUNT(*) as total_contracts,
    SUM(deposit_amount) as total_deposit_amount,
    
    -- Average deposit
    ROUND(AVG(deposit_amount), 2) as avg_deposit_amount,
    
    -- Latest update time
    MAX(updated_at) as last_updated_at
    
FROM bms.lease_contracts
WHERE contract_status != 'CANCELLED'
GROUP BY company_id;

-- 6. Bulk calculate deposit interest function
CREATE OR REPLACE FUNCTION bms.bulk_calculate_deposit_interest(
    p_company_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    calculated_count INTEGER,
    total_interest DECIMAL(15,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_calculated_count INTEGER := 0;
    v_total_interest DECIMAL(15,2) := 0;
    v_interest_amount DECIMAL(15,2);
BEGIN
    -- Calculate interest for active contracts
    FOR v_contract IN
        SELECT contract_id
        FROM bms.lease_contracts
        WHERE company_id = p_company_id
        AND contract_status = 'ACTIVE'
    LOOP
        -- Calculate interest for each contract
        SELECT bms.calculate_deposit_interest(
            p_company_id,
            v_contract.contract_id,
            p_calculation_date
        ) INTO v_interest_amount;
        
        IF v_interest_amount > 0 THEN
            v_calculated_count := v_calculated_count + 1;
            v_total_interest := v_total_interest + v_interest_amount;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT v_calculated_count, v_total_interest;
END;
$$;

-- 7. Comments
COMMENT ON FUNCTION bms.process_deposit_receipt(UUID, UUID, DECIMAL, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID) IS 'Process deposit receipt - Record deposit receipt and update contract status';
COMMENT ON FUNCTION bms.calculate_deposit_interest(UUID, UUID, DATE) IS 'Calculate deposit interest - Calculate interest based on holding period';
COMMENT ON FUNCTION bms.process_deposit_refund(UUID, UUID, DATE, DECIMAL, DECIMAL, DECIMAL, TEXT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID) IS 'Process deposit refund - Handle deposit refund with interest and deductions';
COMMENT ON FUNCTION bms.bulk_calculate_deposit_interest(UUID, DATE) IS 'Bulk calculate deposit interest - Calculate interest for all active contracts';

COMMENT ON VIEW bms.v_deposit_status IS 'Deposit status view - Comprehensive view of deposit receipts and refunds by contract';
COMMENT ON VIEW bms.v_deposit_statistics IS 'Deposit statistics view - Company-wise deposit management statistics';

-- Script completion message
SELECT 'Deposit management functions created successfully.' as message;