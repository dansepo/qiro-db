-- =====================================================
-- Legal Management and Dispute Resolution Functions
-- Phase 3.7: Legal Management and Dispute Processing Functions
-- =====================================================

-- 1. Create dispute case function
CREATE OR REPLACE FUNCTION bms.create_dispute_case(
    p_company_id UUID,
    p_dispute_type VARCHAR(30),
    p_dispute_title VARCHAR(200),
    p_dispute_description TEXT,
    p_complainant_type VARCHAR(20),
    p_complainant_name VARCHAR(100),
    p_respondent_type VARCHAR(20),
    p_respondent_name VARCHAR(100),
    p_contract_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_disputed_amount DECIMAL(15,2) DEFAULT 0,
    p_claimed_damages DECIMAL(15,2) DEFAULT 0,
    p_assigned_staff_id UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_dispute_id UUID;
    v_case_number VARCHAR(50);
    v_dispute_category VARCHAR(20);
BEGIN
    -- Generate case number
    v_case_number := 'DISP' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                    LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Determine dispute category based on type
    v_dispute_category := CASE 
        WHEN p_dispute_type IN ('RENT_DISPUTE', 'DEPOSIT_DISPUTE') THEN 'FINANCIAL'
        WHEN p_dispute_type IN ('LEASE_VIOLATION', 'BREACH_OF_CONTRACT') THEN 'CONTRACTUAL'
        WHEN p_dispute_type IN ('NOISE_COMPLAINT', 'HARASSMENT') THEN 'BEHAVIORAL'
        WHEN p_dispute_type IN ('PROPERTY_DAMAGE', 'MAINTENANCE_DISPUTE') THEN 'PROPERTY'
        WHEN p_dispute_type IN ('EVICTION', 'DISCRIMINATION') THEN 'LEGAL'
        ELSE 'OTHER'
    END;
    
    -- Create dispute case
    INSERT INTO bms.dispute_cases (
        company_id,
        contract_id,
        unit_id,
        case_number,
        dispute_type,
        dispute_category,
        dispute_title,
        dispute_description,
        complainant_type,
        complainant_name,
        respondent_type,
        respondent_name,
        disputed_amount,
        claimed_damages,
        assigned_staff_id,
        created_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        p_unit_id,
        v_case_number,
        p_dispute_type,
        v_dispute_category,
        p_dispute_title,
        p_dispute_description,
        p_complainant_type,
        p_complainant_name,
        p_respondent_type,
        p_respondent_name,
        p_disputed_amount,
        p_claimed_damages,
        p_assigned_staff_id,
        p_created_by
    ) RETURNING dispute_id INTO v_dispute_id;
    
    -- Create initial risk assessment if financial dispute
    IF v_dispute_category = 'FINANCIAL' AND p_disputed_amount > 0 THEN
        PERFORM bms.create_risk_assessment(
            p_company_id,
            'LEGAL_COMPLIANCE_RISK',
            'Dispute Financial Risk: ' || p_dispute_title,
            'Financial risk assessment for dispute case ' || v_case_number,
            'DISPUTE_FINANCIAL_EXPOSURE',
            CASE 
                WHEN p_disputed_amount > 10000000 THEN 'CRITICAL'
                WHEN p_disputed_amount > 5000000 THEN 'HIGH'
                WHEN p_disputed_amount > 1000000 THEN 'MEDIUM'
                ELSE 'LOW'
            END,
            p_disputed_amount,
            p_created_by,
            p_contract_id
        );
    END IF;
    
    RETURN v_dispute_id;
END;
$$;

-- 2. Update dispute status function
CREATE OR REPLACE FUNCTION bms.update_dispute_status(
    p_dispute_id UUID,
    p_new_status VARCHAR(20),
    p_resolution_method VARCHAR(20) DEFAULT NULL,
    p_resolution_summary TEXT DEFAULT NULL,
    p_settlement_amount DECIMAL(15,2) DEFAULT NULL,
    p_resolution_terms JSONB DEFAULT NULL,
    p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_dispute RECORD;
    v_old_status VARCHAR(20);
BEGIN
    -- Get current dispute information
    SELECT * INTO v_dispute
    FROM bms.dispute_cases
    WHERE dispute_id = p_dispute_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Dispute case not found: %', p_dispute_id;
    END IF;
    
    v_old_status := v_dispute.dispute_status;
    
    -- Update dispute case
    UPDATE bms.dispute_cases
    SET dispute_status = p_new_status,
        resolution_method = COALESCE(p_resolution_method, resolution_method),
        resolution_summary = COALESCE(p_resolution_summary, resolution_summary),
        settlement_amount = COALESCE(p_settlement_amount, settlement_amount),
        resolution_terms = COALESCE(p_resolution_terms, resolution_terms),
        resolution_date = CASE 
            WHEN p_new_status IN ('RESOLVED', 'DISMISSED') THEN CURRENT_DATE
            ELSE resolution_date
        END,
        updated_at = NOW(),
        updated_by = p_updated_by
    WHERE dispute_id = p_dispute_id;
    
    -- Log status change in correspondence
    UPDATE bms.dispute_cases
    SET correspondence_log = COALESCE(correspondence_log, '[]'::jsonb) || 
        jsonb_build_object(
            'timestamp', NOW(),
            'type', 'STATUS_CHANGE',
            'old_status', v_old_status,
            'new_status', p_new_status,
            'updated_by', p_updated_by,
            'notes', p_resolution_summary
        )
    WHERE dispute_id = p_dispute_id;
    
    -- Update related risk assessments if resolved
    IF p_new_status IN ('RESOLVED', 'DISMISSED') THEN
        UPDATE bms.risk_assessments
        SET assessment_status = 'RESOLVED',
            mitigation_status = 'COMPLETED',
            updated_at = NOW()
        WHERE company_id = v_dispute.company_id
        AND contract_id = v_dispute.contract_id
        AND assessment_type = 'LEGAL_COMPLIANCE_RISK'
        AND assessment_status = 'ACTIVE';
    END IF;
    
    RETURN true;
END;
$$;-- 3
. Create risk assessment function
CREATE OR REPLACE FUNCTION bms.create_risk_assessment(
    p_company_id UUID,
    p_assessment_type VARCHAR(30),
    p_assessment_title VARCHAR(200),
    p_assessment_description TEXT,
    p_risk_factor VARCHAR(50),
    p_risk_level VARCHAR(20),
    p_potential_financial_impact DECIMAL(15,2) DEFAULT 0,
    p_created_by UUID DEFAULT NULL,
    p_contract_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_assessment_id UUID;
    v_assessment_category VARCHAR(20);
    v_probability_score INTEGER;
    v_impact_score INTEGER;
    v_overall_risk_score INTEGER;
    v_next_review_date DATE;
BEGIN
    -- Determine assessment category
    v_assessment_category := CASE 
        WHEN p_assessment_type IN ('TENANT_CREDIT_RISK', 'PAYMENT_DEFAULT_RISK', 'MARKET_RISK') THEN 'FINANCIAL'
        WHEN p_assessment_type IN ('PROPERTY_DAMAGE_RISK', 'OPERATIONAL_RISK') THEN 'OPERATIONAL'
        WHEN p_assessment_type IN ('LEGAL_COMPLIANCE_RISK', 'INSURANCE_RISK') THEN 'LEGAL'
        WHEN p_assessment_type IN ('SAFETY_RISK') THEN 'SAFETY'
        WHEN p_assessment_type IN ('ENVIRONMENTAL_RISK') THEN 'ENVIRONMENTAL'
        ELSE 'OPERATIONAL'
    END;
    
    -- Calculate risk scores based on risk level and financial impact
    CASE p_risk_level
        WHEN 'LOW' THEN 
            v_probability_score := 2;
            v_impact_score := CASE 
                WHEN p_potential_financial_impact > 5000000 THEN 8
                WHEN p_potential_financial_impact > 1000000 THEN 6
                WHEN p_potential_financial_impact > 500000 THEN 4
                ELSE 2
            END;
        WHEN 'MEDIUM' THEN 
            v_probability_score := 5;
            v_impact_score := CASE 
                WHEN p_potential_financial_impact > 5000000 THEN 9
                WHEN p_potential_financial_impact > 1000000 THEN 7
                WHEN p_potential_financial_impact > 500000 THEN 5
                ELSE 3
            END;
        WHEN 'HIGH' THEN 
            v_probability_score := 7;
            v_impact_score := CASE 
                WHEN p_potential_financial_impact > 5000000 THEN 10
                WHEN p_potential_financial_impact > 1000000 THEN 8
                WHEN p_potential_financial_impact > 500000 THEN 6
                ELSE 4
            END;
        WHEN 'CRITICAL' THEN 
            v_probability_score := 9;
            v_impact_score := CASE 
                WHEN p_potential_financial_impact > 5000000 THEN 10
                WHEN p_potential_financial_impact > 1000000 THEN 9
                WHEN p_potential_financial_impact > 500000 THEN 8
                ELSE 6
            END;
        ELSE
            v_probability_score := 5;
            v_impact_score := 5;
    END CASE;
    
    -- Calculate overall risk score (probability * impact)
    v_overall_risk_score := v_probability_score * v_impact_score;
    
    -- Set next review date based on risk level
    v_next_review_date := CASE p_risk_level
        WHEN 'CRITICAL' THEN CURRENT_DATE + INTERVAL '1 month'
        WHEN 'HIGH' THEN CURRENT_DATE + INTERVAL '3 months'
        WHEN 'MEDIUM' THEN CURRENT_DATE + INTERVAL '6 months'
        ELSE CURRENT_DATE + INTERVAL '12 months'
    END;
    
    -- Create risk assessment
    INSERT INTO bms.risk_assessments (
        company_id,
        building_id,
        unit_id,
        contract_id,
        assessment_type,
        assessment_category,
        assessment_title,
        assessment_description,
        risk_factor,
        risk_level,
        probability_score,
        impact_score,
        overall_risk_score,
        potential_financial_impact,
        next_review_date,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_unit_id,
        p_contract_id,
        p_assessment_type,
        v_assessment_category,
        p_assessment_title,
        p_assessment_description,
        p_risk_factor,
        p_risk_level,
        v_probability_score,
        v_impact_score,
        v_overall_risk_score,
        p_potential_financial_impact,
        v_next_review_date,
        p_created_by
    ) RETURNING assessment_id INTO v_assessment_id;
    
    RETURN v_assessment_id;
END;
$$;

-- 4. Create insurance policy function
CREATE OR REPLACE FUNCTION bms.create_insurance_policy(
    p_company_id UUID,
    p_policy_number VARCHAR(100),
    p_policy_type VARCHAR(30),
    p_policy_name VARCHAR(200),
    p_insurance_company VARCHAR(200),
    p_coverage_amount DECIMAL(15,2),
    p_annual_premium DECIMAL(15,2),
    p_policy_start_date DATE,
    p_policy_end_date DATE,
    p_building_id UUID DEFAULT NULL,
    p_deductible_amount DECIMAL(15,2) DEFAULT 0,
    p_payment_frequency VARCHAR(20) DEFAULT 'ANNUAL',
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_policy_id UUID;
    v_next_payment_date DATE;
BEGIN
    -- Calculate next payment date based on frequency
    v_next_payment_date := CASE p_payment_frequency
        WHEN 'MONTHLY' THEN p_policy_start_date + INTERVAL '1 month'
        WHEN 'QUARTERLY' THEN p_policy_start_date + INTERVAL '3 months'
        WHEN 'SEMI_ANNUAL' THEN p_policy_start_date + INTERVAL '6 months'
        ELSE p_policy_start_date + INTERVAL '1 year'
    END;
    
    -- Create insurance policy
    INSERT INTO bms.insurance_policies (
        company_id,
        building_id,
        policy_number,
        policy_type,
        policy_name,
        insurance_company,
        coverage_amount,
        deductible_amount,
        policy_start_date,
        policy_end_date,
        renewal_date,
        annual_premium,
        payment_frequency,
        next_payment_date,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_policy_number,
        p_policy_type,
        p_policy_name,
        p_insurance_company,
        p_coverage_amount,
        p_deductible_amount,
        p_policy_start_date,
        p_policy_end_date,
        p_policy_end_date, -- renewal_date same as end_date initially
        p_annual_premium,
        p_payment_frequency,
        v_next_payment_date,
        p_created_by
    ) RETURNING policy_id INTO v_policy_id;
    
    RETURN v_policy_id;
END;
$$;-- 
5. Legal compliance monitoring function
CREATE OR REPLACE FUNCTION bms.create_legal_compliance_requirement(
    p_company_id UUID,
    p_requirement_type VARCHAR(30),
    p_requirement_title VARCHAR(200),
    p_requirement_description TEXT,
    p_legal_basis VARCHAR(100) DEFAULT NULL,
    p_compliance_deadline DATE DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_risk_level VARCHAR(20) DEFAULT 'MEDIUM',
    p_responsible_staff_id UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_requirement_id UUID;
    v_requirement_category VARCHAR(20);
    v_next_review_date DATE;
BEGIN
    -- Determine requirement category
    v_requirement_category := CASE 
        WHEN p_requirement_type IN ('TENANT_PROTECTION_LAW', 'DEPOSIT_PROTECTION') THEN 'MANDATORY'
        WHEN p_requirement_type IN ('SAFETY_REGULATION', 'BUILDING_CODE', 'FIRE_SAFETY') THEN 'MANDATORY'
        WHEN p_requirement_type IN ('ACCESSIBILITY', 'ENVIRONMENTAL') THEN 'MANDATORY'
        WHEN p_requirement_type IN ('TAX_COMPLIANCE', 'INSURANCE_REQUIREMENT') THEN 'MANDATORY'
        ELSE 'RECOMMENDED'
    END;
    
    -- Set next review date based on risk level
    v_next_review_date := CASE p_risk_level
        WHEN 'CRITICAL' THEN CURRENT_DATE + INTERVAL '1 month'
        WHEN 'HIGH' THEN CURRENT_DATE + INTERVAL '3 months'
        WHEN 'MEDIUM' THEN CURRENT_DATE + INTERVAL '6 months'
        ELSE CURRENT_DATE + INTERVAL '12 months'
    END;
    
    -- Create compliance requirement
    INSERT INTO bms.legal_compliance_requirements (
        company_id,
        building_id,
        requirement_type,
        requirement_category,
        requirement_title,
        requirement_description,
        legal_basis,
        compliance_deadline,
        next_review_date,
        risk_level,
        responsible_staff_id,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_requirement_type,
        v_requirement_category,
        p_requirement_title,
        p_requirement_description,
        p_legal_basis,
        p_compliance_deadline,
        v_next_review_date,
        p_risk_level,
        p_responsible_staff_id,
        p_created_by
    ) RETURNING requirement_id INTO v_requirement_id;
    
    -- Create related risk assessment for mandatory requirements
    IF v_requirement_category = 'MANDATORY' THEN
        PERFORM bms.create_risk_assessment(
            p_company_id,
            'LEGAL_COMPLIANCE_RISK',
            'Compliance Risk: ' || p_requirement_title,
            'Legal compliance risk for ' || p_requirement_type,
            'NON_COMPLIANCE_PENALTY',
            p_risk_level,
            CASE p_risk_level
                WHEN 'CRITICAL' THEN 50000000
                WHEN 'HIGH' THEN 20000000
                WHEN 'MEDIUM' THEN 5000000
                ELSE 1000000
            END,
            p_created_by,
            NULL,
            p_building_id
        );
    END IF;
    
    RETURN v_requirement_id;
END;
$$;

-- 6. Legal dashboard view
CREATE OR REPLACE VIEW bms.v_legal_dashboard AS
SELECT 
    dc.company_id,
    
    -- Dispute statistics
    COUNT(dc.dispute_id) as total_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_status = 'OPEN') as open_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_status = 'UNDER_INVESTIGATION') as investigating_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_status IN ('MEDIATION', 'ARBITRATION', 'LITIGATION')) as active_legal_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_status = 'RESOLVED') as resolved_disputes,
    
    -- Financial impact
    SUM(dc.disputed_amount) as total_disputed_amount,
    SUM(dc.claimed_damages) as total_claimed_damages,
    SUM(dc.settlement_amount) as total_settlement_amount,
    AVG(dc.disputed_amount) FILTER (WHERE dc.disputed_amount > 0) as avg_disputed_amount,
    
    -- Dispute types breakdown
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_type = 'RENT_DISPUTE') as rent_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_type = 'DEPOSIT_DISPUTE') as deposit_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_type = 'MAINTENANCE_DISPUTE') as maintenance_disputes,
    COUNT(dc.dispute_id) FILTER (WHERE dc.dispute_type = 'EVICTION') as eviction_cases,
    
    -- Risk assessments
    COUNT(ra.assessment_id) as total_risk_assessments,
    COUNT(ra.assessment_id) FILTER (WHERE ra.risk_level = 'CRITICAL') as critical_risks,
    COUNT(ra.assessment_id) FILTER (WHERE ra.risk_level = 'HIGH') as high_risks,
    COUNT(ra.assessment_id) FILTER (WHERE ra.assessment_status = 'ACTIVE') as active_risks,
    
    -- Compliance requirements
    COUNT(lcr.requirement_id) as total_compliance_requirements,
    COUNT(lcr.requirement_id) FILTER (WHERE lcr.compliance_status = 'NON_COMPLIANT') as non_compliant_requirements,
    COUNT(lcr.requirement_id) FILTER (WHERE lcr.compliance_deadline < CURRENT_DATE AND lcr.compliance_status != 'COMPLIANT') as overdue_requirements,
    
    -- Insurance policies
    COUNT(ip.policy_id) as total_insurance_policies,
    COUNT(ip.policy_id) FILTER (WHERE ip.policy_status = 'ACTIVE') as active_policies,
    COUNT(ip.policy_id) FILTER (WHERE ip.policy_end_date <= CURRENT_DATE + INTERVAL '30 days') as expiring_soon_policies,
    SUM(ip.coverage_amount) as total_coverage_amount,
    SUM(ip.annual_premium) as total_annual_premiums,
    
    -- Recent activity
    COUNT(dc.dispute_id) FILTER (WHERE DATE_TRUNC('month', dc.created_at) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_disputes,
    COUNT(ra.assessment_id) FILTER (WHERE DATE_TRUNC('month', ra.created_at) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_assessments,
    
    -- Latest updates
    MAX(dc.updated_at) as last_dispute_update,
    MAX(ra.updated_at) as last_risk_update,
    MAX(lcr.updated_at) as last_compliance_update
    
FROM bms.dispute_cases dc
FULL OUTER JOIN bms.risk_assessments ra ON dc.company_id = ra.company_id
FULL OUTER JOIN bms.legal_compliance_requirements lcr ON COALESCE(dc.company_id, ra.company_id) = lcr.company_id
FULL OUTER JOIN bms.insurance_policies ip ON COALESCE(dc.company_id, ra.company_id, lcr.company_id) = ip.company_id
GROUP BY COALESCE(dc.company_id, ra.company_id, lcr.company_id, ip.company_id);-
- 7. Dispute case details view
CREATE OR REPLACE VIEW bms.v_dispute_case_details AS
SELECT 
    dc.dispute_id,
    dc.company_id,
    dc.case_number,
    dc.dispute_type,
    dc.dispute_category,
    dc.dispute_title,
    dc.dispute_description,
    dc.dispute_status,
    
    -- Parties information
    dc.complainant_type,
    dc.complainant_name,
    dc.respondent_type,
    dc.respondent_name,
    
    -- Financial details
    dc.disputed_amount,
    dc.claimed_damages,
    dc.settlement_amount,
    
    -- Timeline
    dc.dispute_date,
    dc.filing_date,
    dc.response_deadline,
    dc.hearing_date,
    dc.resolution_date,
    
    -- Case management
    dc.assigned_staff_id,
    dc.case_manager_id,
    dc.legal_counsel_required,
    dc.legal_counsel_assigned,
    
    -- Resolution details
    dc.resolution_method,
    dc.resolution_summary,
    
    -- Related information
    lc.contract_number,
    lc.tenant_name,
    u.unit_number,
    b.name as building_name,
    
    -- Status indicators
    CASE 
        WHEN dc.dispute_status = 'RESOLVED' THEN 'RESOLVED'
        WHEN dc.response_deadline < CURRENT_DATE AND dc.dispute_status = 'OPEN' THEN 'OVERDUE_RESPONSE'
        WHEN dc.hearing_date <= CURRENT_DATE + INTERVAL '7 days' AND dc.hearing_date IS NOT NULL THEN 'HEARING_SOON'
        ELSE 'NORMAL'
    END as urgency_status,
    
    -- Financial impact category
    CASE 
        WHEN dc.disputed_amount > 10000000 THEN 'HIGH_VALUE'
        WHEN dc.disputed_amount > 5000000 THEN 'MEDIUM_VALUE'
        WHEN dc.disputed_amount > 0 THEN 'LOW_VALUE'
        ELSE 'NON_FINANCIAL'
    END as financial_impact_category,
    
    -- Days since creation
    CURRENT_DATE - dc.dispute_date as days_since_dispute,
    
    -- Days to resolution (if resolved)
    CASE 
        WHEN dc.resolution_date IS NOT NULL THEN dc.resolution_date - dc.dispute_date
        ELSE NULL
    END as days_to_resolution,
    
    dc.created_at,
    dc.updated_at
    
FROM bms.dispute_cases dc
LEFT JOIN bms.lease_contracts lc ON dc.contract_id = lc.contract_id
LEFT JOIN bms.units u ON dc.unit_id = u.unit_id
LEFT JOIN bms.buildings b ON u.building_id = b.building_id;

-- 8. Risk assessment summary view
CREATE OR REPLACE VIEW bms.v_risk_assessment_summary AS
SELECT 
    ra.assessment_id,
    ra.company_id,
    ra.assessment_type,
    ra.assessment_category,
    ra.assessment_title,
    ra.risk_factor,
    ra.risk_level,
    ra.overall_risk_score,
    ra.potential_financial_impact,
    ra.assessment_status,
    ra.mitigation_status,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    lc.contract_number,
    
    -- Timeline
    ra.assessment_date,
    ra.next_review_date,
    ra.action_deadline,
    
    -- Status indicators
    CASE 
        WHEN ra.next_review_date < CURRENT_DATE THEN 'REVIEW_OVERDUE'
        WHEN ra.next_review_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'REVIEW_DUE_SOON'
        WHEN ra.action_deadline < CURRENT_DATE AND ra.mitigation_status != 'COMPLETED' THEN 'ACTION_OVERDUE'
        WHEN ra.action_deadline <= CURRENT_DATE + INTERVAL '7 days' AND ra.mitigation_status != 'COMPLETED' THEN 'ACTION_DUE_SOON'
        ELSE 'NORMAL'
    END as status_indicator,
    
    -- Risk scoring
    CASE 
        WHEN ra.overall_risk_score >= 80 THEN 'CRITICAL'
        WHEN ra.overall_risk_score >= 60 THEN 'HIGH'
        WHEN ra.overall_risk_score >= 40 THEN 'MEDIUM'
        ELSE 'LOW'
    END as calculated_risk_level,
    
    ra.created_at,
    ra.updated_at
    
FROM bms.risk_assessments ra
LEFT JOIN bms.buildings b ON ra.building_id = b.building_id
LEFT JOIN bms.units u ON ra.unit_id = u.unit_id
LEFT JOIN bms.lease_contracts lc ON ra.contract_id = lc.contract_id;

-- 9. Insurance policy monitoring view
CREATE OR REPLACE VIEW bms.v_insurance_policy_monitoring AS
SELECT 
    ip.policy_id,
    ip.company_id,
    ip.policy_number,
    ip.policy_type,
    ip.policy_name,
    ip.insurance_company,
    ip.policy_status,
    
    -- Coverage details
    ip.coverage_amount,
    ip.deductible_amount,
    ip.annual_premium,
    
    -- Timeline
    ip.policy_start_date,
    ip.policy_end_date,
    ip.renewal_date,
    ip.next_payment_date,
    
    -- Claims information
    ip.claims_count,
    ip.total_claims_amount,
    ip.last_claim_date,
    
    -- Building information
    b.name as building_name,
    b.address as building_address,
    
    -- Status indicators
    CASE 
        WHEN ip.policy_end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN ip.policy_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN ip.next_payment_date < CURRENT_DATE THEN 'PAYMENT_OVERDUE'
        WHEN ip.next_payment_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'PAYMENT_DUE_SOON'
        ELSE 'CURRENT'
    END as status_indicator,
    
    -- Days until expiration
    ip.policy_end_date - CURRENT_DATE as days_until_expiration,
    
    -- Days until next payment
    ip.next_payment_date - CURRENT_DATE as days_until_payment,
    
    -- Claims ratio
    CASE 
        WHEN ip.annual_premium > 0 THEN 
            ROUND((ip.total_claims_amount / ip.annual_premium * 100), 2)
        ELSE 0
    END as claims_ratio_percentage,
    
    ip.created_at,
    ip.updated_at
    
FROM bms.insurance_policies ip
LEFT JOIN bms.buildings b ON ip.building_id = b.building_id;

-- Script completion message
SELECT 'Legal management and dispute resolution functions created successfully.' as message;