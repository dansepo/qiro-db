-- =====================================================
-- Contract Renewal Management Functions
-- Phase 3.5.1: Contract Renewal Functions
-- =====================================================

-- 1. Create contract renewal process function
CREATE OR REPLACE FUNCTION bms.create_contract_renewal_process(
    p_company_id UUID,
    p_contract_id UUID,
    p_renewal_type VARCHAR(20) DEFAULT 'STANDARD',
    p_proposed_rent_increase_pct DECIMAL(5,2) DEFAULT 0,
    p_assigned_staff_id UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_renewal_id UUID;
    v_renewal_number VARCHAR(50);
    v_contract RECORD;
    v_policy RECORD;
    v_proposed_rent DECIMAL(15,2);
    v_notice_period INTEGER := 60;
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
    
    -- Check if renewal process already exists
    IF EXISTS (
        SELECT 1 FROM bms.contract_renewal_processes 
        WHERE contract_id = p_contract_id
    ) THEN
        RAISE EXCEPTION 'Renewal process already exists for contract: %', p_contract_id;
    END IF;
    
    -- Generate renewal number
    v_renewal_number := 'RN' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Get applicable rent adjustment policy
    SELECT * INTO v_policy
    FROM bms.rent_adjustment_policies
    WHERE company_id = p_company_id
    AND (building_id = v_contract.building_id OR building_id IS NULL)
    AND is_active = true
    ORDER BY building_id NULLS LAST, created_at DESC
    LIMIT 1;
    
    -- Calculate proposed rent
    IF v_policy.policy_id IS NOT NULL THEN
        v_proposed_rent := v_contract.monthly_rent * (1 + COALESCE(v_policy.base_increase_rate, p_proposed_rent_increase_pct) / 100);
        v_notice_period := v_policy.notice_period_days;
    ELSE
        v_proposed_rent := v_contract.monthly_rent * (1 + p_proposed_rent_increase_pct / 100);
    END IF;
    
    -- Create renewal process
    INSERT INTO bms.contract_renewal_processes (
        company_id,
        contract_id,
        renewal_number,
        renewal_type,
        contract_expiry_date,
        renewal_notice_period_days,
        tenant_response_deadline,
        landlord_decision_deadline,
        proposed_new_start_date,
        proposed_new_end_date,
        proposed_rent_amount,
        proposed_rent_increase_pct,
        assigned_staff_id,
        created_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_renewal_number,
        p_renewal_type,
        v_contract.contract_end_date,
        v_notice_period,
        v_contract.contract_end_date - INTERVAL '%s days' % (v_notice_period / 2),
        v_contract.contract_end_date - INTERVAL '7 days',
        v_contract.contract_end_date + INTERVAL '1 day',
        v_contract.contract_end_date + INTERVAL '1 year',
        v_proposed_rent,
        p_proposed_rent_increase_pct,
        p_assigned_staff_id,
        p_created_by
    ) RETURNING renewal_id INTO v_renewal_id;
    
    RETURN v_renewal_id;
END;
$$;-- 2.
 Send renewal notice function
CREATE OR REPLACE FUNCTION bms.send_renewal_notice(
    p_renewal_id UUID,
    p_notice_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_renewal RECORD;
BEGIN
    -- Get renewal information
    SELECT * INTO v_renewal
    FROM bms.contract_renewal_processes
    WHERE renewal_id = p_renewal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Renewal process not found: %', p_renewal_id;
    END IF;
    
    -- Update renewal process
    UPDATE bms.contract_renewal_processes
    SET renewal_notice_date = p_notice_date,
        renewal_status = 'NOTICE_SENT',
        updated_at = NOW()
    WHERE renewal_id = p_renewal_id;
    
    RETURN true;
END;
$$;

-- 3. Process tenant response function
CREATE OR REPLACE FUNCTION bms.process_tenant_response(
    p_renewal_id UUID,
    p_tenant_response VARCHAR(20),
    p_response_date DATE DEFAULT CURRENT_DATE,
    p_counter_offer JSONB DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_renewal RECORD;
    v_new_status VARCHAR(20);
BEGIN
    -- Get renewal information
    SELECT * INTO v_renewal
    FROM bms.contract_renewal_processes
    WHERE renewal_id = p_renewal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Renewal process not found: %', p_renewal_id;
    END IF;
    
    -- Determine new status
    CASE p_tenant_response
        WHEN 'ACCEPT' THEN v_new_status := 'AGREED';
        WHEN 'DECLINE' THEN v_new_status := 'DECLINED';
        WHEN 'COUNTER_OFFER' THEN v_new_status := 'NEGOTIATING';
        WHEN 'REQUEST_CHANGES' THEN v_new_status := 'NEGOTIATING';
        ELSE v_new_status := 'TENANT_RESPONDED';
    END CASE;
    
    -- Update renewal process
    UPDATE bms.contract_renewal_processes
    SET tenant_response = p_tenant_response,
        tenant_response_date = p_response_date,
        tenant_counter_offer = p_counter_offer,
        renewal_status = v_new_status,
        negotiation_rounds = CASE 
            WHEN p_tenant_response IN ('COUNTER_OFFER', 'REQUEST_CHANGES') THEN negotiation_rounds + 1
            ELSE negotiation_rounds
        END,
        current_offer_from = CASE 
            WHEN p_tenant_response IN ('COUNTER_OFFER', 'REQUEST_CHANGES') THEN 'TENANT'
            ELSE current_offer_from
        END,
        updated_at = NOW()
    WHERE renewal_id = p_renewal_id;
    
    RETURN true;
END;
$$;-- 4. Pr
ocess landlord decision function
CREATE OR REPLACE FUNCTION bms.process_landlord_decision(
    p_renewal_id UUID,
    p_landlord_decision VARCHAR(20),
    p_decision_date DATE DEFAULT CURRENT_DATE,
    p_counter_offer JSONB DEFAULT NULL,
    p_final_rent_amount DECIMAL(15,2) DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_renewal RECORD;
    v_new_status VARCHAR(20);
BEGIN
    -- Get renewal information
    SELECT * INTO v_renewal
    FROM bms.contract_renewal_processes
    WHERE renewal_id = p_renewal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Renewal process not found: %', p_renewal_id;
    END IF;
    
    -- Determine new status
    CASE p_landlord_decision
        WHEN 'APPROVE' THEN v_new_status := 'AGREED';
        WHEN 'DECLINE' THEN v_new_status := 'DECLINED';
        WHEN 'COUNTER_OFFER' THEN v_new_status := 'NEGOTIATING';
        WHEN 'REQUEST_CHANGES' THEN v_new_status := 'NEGOTIATING';
        ELSE v_new_status := v_renewal.renewal_status;
    END CASE;
    
    -- Update renewal process
    UPDATE bms.contract_renewal_processes
    SET landlord_decision = p_landlord_decision,
        landlord_decision_date = p_decision_date,
        landlord_counter_offer = p_counter_offer,
        renewal_status = v_new_status,
        final_rent_amount = COALESCE(p_final_rent_amount, final_rent_amount),
        negotiation_rounds = CASE 
            WHEN p_landlord_decision IN ('COUNTER_OFFER', 'REQUEST_CHANGES') THEN negotiation_rounds + 1
            ELSE negotiation_rounds
        END,
        current_offer_from = CASE 
            WHEN p_landlord_decision IN ('COUNTER_OFFER', 'REQUEST_CHANGES') THEN 'LANDLORD'
            ELSE current_offer_from
        END,
        updated_at = NOW()
    WHERE renewal_id = p_renewal_id;
    
    RETURN true;
END;
$$;

-- 5. Complete renewal process function
CREATE OR REPLACE FUNCTION bms.complete_renewal_process(
    p_renewal_id UUID,
    p_renewal_outcome VARCHAR(20),
    p_new_contract_id UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_renewal RECORD;
BEGIN
    -- Get renewal information
    SELECT * INTO v_renewal
    FROM bms.contract_renewal_processes
    WHERE renewal_id = p_renewal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Renewal process not found: %', p_renewal_id;
    END IF;
    
    -- Update renewal process
    UPDATE bms.contract_renewal_processes
    SET renewal_outcome = p_renewal_outcome,
        new_contract_id = p_new_contract_id,
        renewal_status = 'COMPLETED',
        updated_at = NOW()
    WHERE renewal_id = p_renewal_id;
    
    -- Update original contract status if not renewed
    IF p_renewal_outcome = 'NOT_RENEWED' THEN
        UPDATE bms.lease_contracts
        SET contract_status = 'EXPIRED',
            updated_at = NOW()
        WHERE contract_id = v_renewal.contract_id;
    END IF;
    
    RETURN true;
END;
$$;--
 6. Calculate rent adjustment function
CREATE OR REPLACE FUNCTION bms.calculate_rent_adjustment(
    p_company_id UUID,
    p_contract_id UUID,
    p_policy_id UUID DEFAULT NULL
) RETURNS TABLE (
    current_rent DECIMAL(15,2),
    proposed_rent DECIMAL(15,2),
    increase_amount DECIMAL(15,2),
    increase_percentage DECIMAL(5,2),
    policy_applied VARCHAR(100),
    adjustment_factors JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_policy RECORD;
    v_current_rent DECIMAL(15,2);
    v_proposed_rent DECIMAL(15,2);
    v_base_increase DECIMAL(5,2);
    v_market_factor DECIMAL(5,2) := 0;
    v_tenant_factor DECIMAL(5,2) := 0;
    v_adjustment_factors JSONB;
BEGIN
    -- Get contract information
    SELECT lc.*, u.unit_type, b.building_id
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found: %', p_contract_id;
    END IF;
    
    v_current_rent := v_contract.monthly_rent;
    
    -- Get rent adjustment policy
    IF p_policy_id IS NOT NULL THEN
        SELECT * INTO v_policy
        FROM bms.rent_adjustment_policies
        WHERE policy_id = p_policy_id;
    ELSE
        SELECT * INTO v_policy
        FROM bms.rent_adjustment_policies
        WHERE company_id = p_company_id
        AND (building_id = v_contract.building_id OR building_id IS NULL)
        AND is_active = true
        ORDER BY building_id NULLS LAST, created_at DESC
        LIMIT 1;
    END IF;
    
    -- Apply base increase rate
    IF v_policy.policy_id IS NOT NULL THEN
        v_base_increase := v_policy.base_increase_rate;
        
        -- Apply market adjustment factor
        v_market_factor := COALESCE(v_policy.market_adjustment_factor, 0);
        
        -- Apply tenant-specific discounts
        -- Long-term tenant discount (if contract > 2 years)
        IF v_contract.contract_start_date <= CURRENT_DATE - INTERVAL '2 years' THEN
            v_tenant_factor := v_tenant_factor - COALESCE(v_policy.long_term_tenant_discount, 0);
        END IF;
        
        -- Good payment history discount (simplified check)
        -- In real implementation, this would check payment history
        v_tenant_factor := v_tenant_factor - COALESCE(v_policy.good_payment_history_discount, 0);
        
    ELSE
        -- Default increase if no policy
        v_base_increase := 3.0; -- 3% default
    END IF;
    
    -- Calculate total increase percentage
    DECLARE
        v_total_increase_pct DECIMAL(5,2);
    BEGIN
        v_total_increase_pct := v_base_increase + v_market_factor + v_tenant_factor;
        
        -- Apply caps if policy exists
        IF v_policy.policy_id IS NOT NULL THEN
            v_total_increase_pct := GREATEST(v_total_increase_pct, v_policy.min_increase_rate);
            v_total_increase_pct := LEAST(v_total_increase_pct, v_policy.max_increase_rate);
        END IF;
        
        -- Calculate proposed rent
        v_proposed_rent := v_current_rent * (1 + v_total_increase_pct / 100);
        
        -- Apply maximum increase amount cap if exists
        IF v_policy.policy_id IS NOT NULL AND v_policy.max_increase_amount IS NOT NULL THEN
            v_proposed_rent := LEAST(v_proposed_rent, v_current_rent + v_policy.max_increase_amount);
        END IF;
        
        -- Round to nearest dollar
        v_proposed_rent := ROUND(v_proposed_rent, 0);
        
        -- Build adjustment factors JSON
        v_adjustment_factors := jsonb_build_object(
            'base_increase_rate', v_base_increase,
            'market_adjustment_factor', v_market_factor,
            'tenant_discount_factor', v_tenant_factor,
            'total_increase_percentage', v_total_increase_pct,
            'policy_caps_applied', v_policy.policy_id IS NOT NULL
        );
        
        RETURN QUERY SELECT 
            v_current_rent,
            v_proposed_rent,
            v_proposed_rent - v_current_rent,
            v_total_increase_pct,
            COALESCE(v_policy.policy_name, 'Default Policy'),
            v_adjustment_factors;
    END;
END;
$$;-- 
7. Contract renewal status view
CREATE OR REPLACE VIEW bms.v_contract_renewal_status AS
SELECT 
    crp.renewal_id,
    crp.company_id,
    crp.contract_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- Renewal process information
    crp.renewal_number,
    crp.renewal_type,
    crp.renewal_status,
    
    -- Timeline information
    crp.contract_expiry_date,
    crp.renewal_notice_date,
    crp.tenant_response_deadline,
    crp.landlord_decision_deadline,
    
    -- Current rent vs proposed
    lc.monthly_rent as current_rent,
    crp.proposed_rent_amount,
    crp.proposed_rent_increase_pct,
    crp.final_rent_amount,
    
    -- Response tracking
    crp.tenant_response,
    crp.tenant_response_date,
    crp.landlord_decision,
    crp.landlord_decision_date,
    
    -- Negotiation status
    crp.negotiation_rounds,
    crp.current_offer_from,
    
    -- Outcome
    crp.renewal_outcome,
    crp.new_contract_id,
    
    -- Days calculations
    CASE 
        WHEN crp.contract_expiry_date >= CURRENT_DATE THEN
            crp.contract_expiry_date - CURRENT_DATE
        ELSE 0
    END as days_until_expiry,
    
    CASE 
        WHEN crp.tenant_response_deadline >= CURRENT_DATE THEN
            crp.tenant_response_deadline - CURRENT_DATE
        ELSE 0
    END as days_until_tenant_deadline,
    
    -- Status indicators
    CASE 
        WHEN crp.renewal_status = 'COMPLETED' THEN 'COMPLETED'
        WHEN crp.contract_expiry_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN crp.tenant_response_deadline < CURRENT_DATE AND crp.tenant_response IS NULL THEN 'OVERDUE'
        WHEN crp.renewal_status = 'NEGOTIATING' THEN 'NEGOTIATING'
        WHEN crp.renewal_status = 'AGREED' THEN 'AGREED'
        WHEN crp.renewal_status = 'DECLINED' THEN 'DECLINED'
        ELSE crp.renewal_status
    END as status_display,
    
    -- Priority scoring
    CASE 
        WHEN crp.contract_expiry_date <= CURRENT_DATE + INTERVAL '7 days' THEN 100
        WHEN crp.contract_expiry_date <= CURRENT_DATE + INTERVAL '30 days' THEN 90
        WHEN crp.contract_expiry_date <= CURRENT_DATE + INTERVAL '60 days' THEN 70
        ELSE 50
    END as priority_score,
    
    -- Staff and tenant information
    crp.assigned_staff_id,
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone,
    tenant.email as tenant_email
    
FROM bms.contract_renewal_processes crp
JOIN bms.lease_contracts lc ON crp.contract_id = lc.contract_id
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true;

-- 8. Renewal statistics view
CREATE OR REPLACE VIEW bms.v_renewal_statistics AS
SELECT 
    company_id,
    
    -- Overall statistics
    COUNT(*) as total_renewals,
    
    -- Status breakdown
    COUNT(*) FILTER (WHERE renewal_status = 'PENDING') as pending_count,
    COUNT(*) FILTER (WHERE renewal_status = 'NOTICE_SENT') as notice_sent_count,
    COUNT(*) FILTER (WHERE renewal_status = 'TENANT_RESPONDED') as tenant_responded_count,
    COUNT(*) FILTER (WHERE renewal_status = 'NEGOTIATING') as negotiating_count,
    COUNT(*) FILTER (WHERE renewal_status = 'AGREED') as agreed_count,
    COUNT(*) FILTER (WHERE renewal_status = 'DECLINED') as declined_count,
    COUNT(*) FILTER (WHERE renewal_status = 'COMPLETED') as completed_count,
    
    -- Outcome statistics
    COUNT(*) FILTER (WHERE renewal_outcome = 'RENEWED') as renewed_count,
    COUNT(*) FILTER (WHERE renewal_outcome = 'NOT_RENEWED') as not_renewed_count,
    
    -- Success rates
    CASE 
        WHEN COUNT(*) FILTER (WHERE renewal_status = 'COMPLETED') > 0 THEN
            ROUND((COUNT(*) FILTER (WHERE renewal_outcome = 'RENEWED')::DECIMAL / 
                   COUNT(*) FILTER (WHERE renewal_status = 'COMPLETED') * 100), 2)
        ELSE 0
    END as renewal_success_rate,
    
    -- Financial impact
    AVG(proposed_rent_increase_pct) as avg_proposed_increase_pct,
    AVG(final_rent_amount - (SELECT monthly_rent FROM bms.lease_contracts lc WHERE lc.contract_id = contract_renewal_processes.contract_id)) as avg_rent_increase_amount,
    
    -- Negotiation statistics
    AVG(negotiation_rounds) as avg_negotiation_rounds,
    COUNT(*) FILTER (WHERE negotiation_rounds > 0) as negotiations_count,
    
    -- Timing statistics
    AVG(CASE 
        WHEN tenant_response_date IS NOT NULL AND renewal_notice_date IS NOT NULL THEN
            tenant_response_date - renewal_notice_date
        ELSE NULL
    END) as avg_tenant_response_days,
    
    -- This month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_renewals,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', contract_expiry_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_expiring,
    
    -- Latest update
    MAX(updated_at) as last_updated_at
    
FROM bms.contract_renewal_processes
GROUP BY company_id;-- 9. Comm
ents
COMMENT ON FUNCTION bms.create_contract_renewal_process(UUID, UUID, VARCHAR, DECIMAL, UUID, UUID) IS 'Create contract renewal process - Initialize renewal process with proposed terms based on policies';
COMMENT ON FUNCTION bms.send_renewal_notice(UUID, DATE) IS 'Send renewal notice - Mark renewal notice as sent and update process status';
COMMENT ON FUNCTION bms.process_tenant_response(UUID, VARCHAR, DATE, JSONB) IS 'Process tenant response - Record tenant response and update negotiation status';
COMMENT ON FUNCTION bms.process_landlord_decision(UUID, VARCHAR, DATE, JSONB, DECIMAL) IS 'Process landlord decision - Record landlord decision and finalize terms';
COMMENT ON FUNCTION bms.complete_renewal_process(UUID, VARCHAR, UUID) IS 'Complete renewal process - Finalize renewal outcome and update contract status';
COMMENT ON FUNCTION bms.calculate_rent_adjustment(UUID, UUID, UUID) IS 'Calculate rent adjustment - Calculate proposed rent increase based on policies and market factors';

COMMENT ON VIEW bms.v_contract_renewal_status IS 'Contract renewal status view - Comprehensive view of renewal process status and timeline';
COMMENT ON VIEW bms.v_renewal_statistics IS 'Renewal statistics view - Company-wise renewal process statistics and success rates';

-- Script completion message
SELECT 'Contract renewal management functions created successfully.' as message;