-- =====================================================
-- Vacancy and Marketing Management Functions
-- Phase 3.4.1: Vacancy and Marketing Functions
-- =====================================================

-- 1. Create vacancy tracking function
CREATE OR REPLACE FUNCTION bms.create_vacancy_tracking(
    p_company_id UUID,
    p_unit_id UUID,
    p_vacancy_start_date DATE DEFAULT CURRENT_DATE,
    p_vacancy_reason VARCHAR(30) DEFAULT 'TENANT_TURNOVER',
    p_vacancy_type VARCHAR(20) DEFAULT 'TENANT_TURNOVER',
    p_previous_contract_id UUID DEFAULT NULL,
    p_move_out_date DATE DEFAULT NULL,
    p_market_rent_at_vacancy DECIMAL(15,2) DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_vacancy_id UUID;
    v_unit RECORD;
    v_previous_tenant VARCHAR(100);
BEGIN
    -- Get unit information
    SELECT u.*, b.name as building_name
    INTO v_unit
    FROM bms.units u
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE u.unit_id = p_unit_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unit not found: %', p_unit_id;
    END IF;
    
    -- Check if there's already an active vacancy for this unit
    IF EXISTS (
        SELECT 1 FROM bms.vacancy_tracking 
        WHERE unit_id = p_unit_id 
        AND vacancy_status = 'ACTIVE'
    ) THEN
        RAISE EXCEPTION 'Active vacancy already exists for unit: %', v_unit.unit_number;
    END IF;
    
    -- Get previous tenant name if contract provided
    IF p_previous_contract_id IS NOT NULL THEN
        SELECT cp.name
        INTO v_previous_tenant
        FROM bms.contract_parties cp
        WHERE cp.contract_id = p_previous_contract_id
        AND cp.party_role = 'TENANT'
        AND cp.is_primary = true;
    END IF;
    
    -- Create vacancy tracking record
    INSERT INTO bms.vacancy_tracking (
        company_id,
        unit_id,
        vacancy_start_date,
        vacancy_reason,
        vacancy_type,
        previous_contract_id,
        previous_tenant_name,
        move_out_date,
        market_rent_at_vacancy,
        created_by
    ) VALUES (
        p_company_id,
        p_unit_id,
        p_vacancy_start_date,
        p_vacancy_reason,
        p_vacancy_type,
        p_previous_contract_id,
        v_previous_tenant,
        p_move_out_date,
        p_market_rent_at_vacancy,
        p_created_by
    ) RETURNING vacancy_id INTO v_vacancy_id;
    
    -- Update unit status to vacant
    UPDATE bms.units
    SET unit_status = 'VACANT',
        updated_at = NOW()
    WHERE unit_id = p_unit_id;
    
    RETURN v_vacancy_id;
END;
$$;-- 2.
 End vacancy tracking function
CREATE OR REPLACE FUNCTION bms.end_vacancy_tracking(
    p_vacancy_id UUID,
    p_vacancy_end_date DATE DEFAULT CURRENT_DATE,
    p_resolution_type VARCHAR(20) DEFAULT 'NEW_LEASE',
    p_final_rent_achieved DECIMAL(15,2) DEFAULT NULL,
    p_total_marketing_costs DECIMAL(15,2) DEFAULT 0,
    p_total_preparation_costs DECIMAL(15,2) DEFAULT 0
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_vacancy RECORD;
    v_duration_days INTEGER;
    v_lost_income DECIMAL(15,2) := 0;
    v_total_cost DECIMAL(15,2);
BEGIN
    -- Get vacancy information
    SELECT * INTO v_vacancy
    FROM bms.vacancy_tracking
    WHERE vacancy_id = p_vacancy_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vacancy not found: %', p_vacancy_id;
    END IF;
    
    -- Calculate vacancy duration
    v_duration_days := p_vacancy_end_date - v_vacancy.vacancy_start_date;
    
    -- Calculate lost rental income
    IF v_vacancy.market_rent_at_vacancy IS NOT NULL THEN
        v_lost_income := v_vacancy.market_rent_at_vacancy * v_duration_days / 30;
    END IF;
    
    -- Calculate total vacancy cost
    v_total_cost := v_lost_income + p_total_marketing_costs + p_total_preparation_costs;
    
    -- Update vacancy record
    UPDATE bms.vacancy_tracking
    SET vacancy_end_date = p_vacancy_end_date,
        vacancy_duration_days = v_duration_days,
        resolution_type = p_resolution_type,
        final_rent_achieved = p_final_rent_achieved,
        lost_rental_income = v_lost_income,
        marketing_costs = p_total_marketing_costs,
        preparation_costs = p_total_preparation_costs,
        total_vacancy_cost = v_total_cost,
        vacancy_status = 'LEASED',
        resolution_date = p_vacancy_end_date,
        updated_at = NOW()
    WHERE vacancy_id = p_vacancy_id;
    
    -- Update unit status to occupied
    UPDATE bms.units
    SET unit_status = 'OCCUPIED',
        updated_at = NOW()
    WHERE unit_id = v_vacancy.unit_id;
    
    RETURN true;
END;
$$;

-- 3. Create marketing campaign function
CREATE OR REPLACE FUNCTION bms.create_marketing_campaign(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_campaign_name VARCHAR(200),
    p_campaign_description TEXT DEFAULT NULL,
    p_campaign_type VARCHAR(20) DEFAULT 'GENERAL',
    p_campaign_start_date DATE DEFAULT CURRENT_DATE,
    p_campaign_end_date DATE DEFAULT NULL,
    p_planned_budget DECIMAL(15,2) DEFAULT 0,
    p_target_units JSONB DEFAULT NULL,
    p_marketing_channels JSONB DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_campaign_id UUID;
BEGIN
    -- Create marketing campaign
    INSERT INTO bms.marketing_campaigns (
        company_id,
        building_id,
        campaign_name,
        campaign_description,
        campaign_type,
        campaign_start_date,
        campaign_end_date,
        planned_budget,
        target_units,
        marketing_channels,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_campaign_name,
        p_campaign_description,
        p_campaign_type,
        p_campaign_start_date,
        p_campaign_end_date,
        p_planned_budget,
        p_target_units,
        p_marketing_channels,
        p_created_by
    ) RETURNING campaign_id INTO v_campaign_id;
    
    RETURN v_campaign_id;
END;
$$;--
 4. Create prospect inquiry function
CREATE OR REPLACE FUNCTION bms.create_prospect_inquiry(
    p_company_id UUID,
    p_prospect_name VARCHAR(100) DEFAULT NULL,
    p_prospect_email VARCHAR(200) DEFAULT NULL,
    p_prospect_phone VARCHAR(20) DEFAULT NULL,
    p_inquiry_source VARCHAR(30),
    p_inquiry_channel VARCHAR(30) DEFAULT NULL,
    p_campaign_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_interested_units JSONB DEFAULT NULL,
    p_budget_range JSONB DEFAULT NULL,
    p_move_in_timeline VARCHAR(20) DEFAULT NULL,
    p_specific_requirements TEXT DEFAULT NULL,
    p_assigned_to UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_inquiry_id UUID;
    v_lead_score INTEGER := 0;
BEGIN
    -- Calculate initial lead score
    v_lead_score := 0;
    
    -- Score based on contact information completeness
    IF p_prospect_name IS NOT NULL THEN v_lead_score := v_lead_score + 10; END IF;
    IF p_prospect_email IS NOT NULL THEN v_lead_score := v_lead_score + 15; END IF;
    IF p_prospect_phone IS NOT NULL THEN v_lead_score := v_lead_score + 15; END IF;
    
    -- Score based on inquiry details
    IF p_budget_range IS NOT NULL THEN v_lead_score := v_lead_score + 20; END IF;
    IF p_move_in_timeline IN ('IMMEDIATE', 'WITHIN_WEEK', 'WITHIN_MONTH') THEN 
        v_lead_score := v_lead_score + 25; 
    END IF;
    IF p_specific_requirements IS NOT NULL THEN v_lead_score := v_lead_score + 10; END IF;
    
    -- Score based on source quality
    IF p_inquiry_source IN ('REFERRAL', 'WEBSITE', 'WALK_IN') THEN 
        v_lead_score := v_lead_score + 15; 
    END IF;
    
    -- Create prospect inquiry
    INSERT INTO bms.prospect_inquiries (
        company_id,
        campaign_id,
        unit_id,
        prospect_name,
        prospect_email,
        prospect_phone,
        inquiry_source,
        inquiry_channel,
        interested_units,
        budget_range,
        move_in_timeline,
        specific_requirements,
        lead_score,
        assigned_to
    ) VALUES (
        p_company_id,
        p_campaign_id,
        p_unit_id,
        p_prospect_name,
        p_prospect_email,
        p_prospect_phone,
        p_inquiry_source,
        p_inquiry_channel,
        p_interested_units,
        p_budget_range,
        p_move_in_timeline,
        p_specific_requirements,
        v_lead_score,
        p_assigned_to
    ) RETURNING inquiry_id INTO v_inquiry_id;
    
    -- Update campaign metrics if associated
    IF p_campaign_id IS NOT NULL THEN
        UPDATE bms.marketing_campaigns
        SET total_leads = total_leads + 1,
            updated_at = NOW()
        WHERE campaign_id = p_campaign_id;
    END IF;
    
    RETURN v_inquiry_id;
END;
$$;-- 5. 
Update prospect status function
CREATE OR REPLACE FUNCTION bms.update_prospect_status(
    p_inquiry_id UUID,
    p_lead_status VARCHAR(20),
    p_qualification_notes TEXT DEFAULT NULL,
    p_contact_date DATE DEFAULT CURRENT_DATE,
    p_next_follow_up_date DATE DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_inquiry RECORD;
    v_old_status VARCHAR(20);
BEGIN
    -- Get current inquiry information
    SELECT * INTO v_inquiry
    FROM bms.prospect_inquiries
    WHERE inquiry_id = p_inquiry_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Prospect inquiry not found: %', p_inquiry_id;
    END IF;
    
    v_old_status := v_inquiry.lead_status;
    
    -- Update prospect inquiry
    UPDATE bms.prospect_inquiries
    SET lead_status = p_lead_status,
        qualification_notes = COALESCE(p_qualification_notes, qualification_notes),
        last_contact_date = p_contact_date,
        next_follow_up_date = p_next_follow_up_date,
        contact_attempts = contact_attempts + 1,
        application_submitted = CASE 
            WHEN p_lead_status = 'APPLIED' THEN true 
            ELSE application_submitted 
        END,
        application_date = CASE 
            WHEN p_lead_status = 'APPLIED' AND application_date IS NULL THEN p_contact_date
            ELSE application_date 
        END,
        lease_signed = CASE 
            WHEN p_lead_status = 'LEASED' THEN true 
            ELSE lease_signed 
        END,
        lease_signed_date = CASE 
            WHEN p_lead_status = 'LEASED' AND lease_signed_date IS NULL THEN p_contact_date
            ELSE lease_signed_date 
        END,
        updated_at = NOW()
    WHERE inquiry_id = p_inquiry_id;
    
    -- Update campaign metrics if associated
    IF v_inquiry.campaign_id IS NOT NULL THEN
        -- Update qualified leads count
        IF v_old_status NOT IN ('QUALIFIED', 'INTERESTED', 'APPLIED', 'APPROVED', 'LEASED') 
           AND p_lead_status IN ('QUALIFIED', 'INTERESTED', 'APPLIED', 'APPROVED', 'LEASED') THEN
            UPDATE bms.marketing_campaigns
            SET qualified_leads = qualified_leads + 1,
                updated_at = NOW()
            WHERE campaign_id = v_inquiry.campaign_id;
        END IF;
        
        -- Update applications count
        IF v_old_status NOT IN ('APPLIED', 'APPROVED', 'LEASED') 
           AND p_lead_status IN ('APPLIED', 'APPROVED', 'LEASED') THEN
            UPDATE bms.marketing_campaigns
            SET applications_received = applications_received + 1,
                updated_at = NOW()
            WHERE campaign_id = v_inquiry.campaign_id;
        END IF;
        
        -- Update leases signed count
        IF v_old_status != 'LEASED' AND p_lead_status = 'LEASED' THEN
            UPDATE bms.marketing_campaigns
            SET leases_signed = leases_signed + 1,
                updated_at = NOW()
            WHERE campaign_id = v_inquiry.campaign_id;
        END IF;
    END IF;
    
    RETURN true;
END;
$$;-- 6
. Create market analysis function
CREATE OR REPLACE FUNCTION bms.create_market_analysis(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_unit_type VARCHAR(20) DEFAULT NULL,
    p_analysis_period VARCHAR(20) DEFAULT 'MONTHLY',
    p_market_rent_range JSONB,
    p_average_market_rent DECIMAL(10,2),
    p_occupancy_rate DECIMAL(5,2) DEFAULT NULL,
    p_competitor_data JSONB DEFAULT NULL,
    p_competitive_position VARCHAR(20) DEFAULT NULL,
    p_rent_trend VARCHAR(20) DEFAULT NULL,
    p_demand_level VARCHAR(20) DEFAULT NULL,
    p_supply_level VARCHAR(20) DEFAULT NULL,
    p_recommended_rent DECIMAL(10,2) DEFAULT NULL,
    p_pricing_strategy VARCHAR(30) DEFAULT NULL,
    p_marketing_recommendations TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_analysis_id UUID;
BEGIN
    -- Create market analysis
    INSERT INTO bms.market_analysis (
        company_id,
        building_id,
        unit_type,
        analysis_period,
        market_rent_range,
        average_market_rent,
        occupancy_rate,
        competitor_data,
        competitive_position,
        rent_trend,
        demand_level,
        supply_level,
        recommended_rent,
        pricing_strategy,
        marketing_recommendations,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_unit_type,
        p_analysis_period,
        p_market_rent_range,
        p_average_market_rent,
        p_occupancy_rate,
        p_competitor_data,
        p_competitive_position,
        p_rent_trend,
        p_demand_level,
        p_supply_level,
        p_recommended_rent,
        p_pricing_strategy,
        p_marketing_recommendations,
        p_created_by
    ) RETURNING analysis_id INTO v_analysis_id;
    
    RETURN v_analysis_id;
END;
$$;

-- 7. Update campaign performance function
CREATE OR REPLACE FUNCTION bms.update_campaign_performance(
    p_campaign_id UUID,
    p_actual_spent DECIMAL(15,2) DEFAULT NULL,
    p_performance_analysis JSONB DEFAULT NULL,
    p_roi_analysis JSONB DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_campaign RECORD;
    v_cost_per_lead DECIMAL(10,2);
    v_cost_per_lease DECIMAL(10,2);
BEGIN
    -- Get campaign information
    SELECT * INTO v_campaign
    FROM bms.marketing_campaigns
    WHERE campaign_id = p_campaign_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Campaign not found: %', p_campaign_id;
    END IF;
    
    -- Calculate cost per lead
    IF v_campaign.total_leads > 0 AND p_actual_spent IS NOT NULL THEN
        v_cost_per_lead := p_actual_spent / v_campaign.total_leads;
    END IF;
    
    -- Calculate cost per lease
    IF v_campaign.leases_signed > 0 AND p_actual_spent IS NOT NULL THEN
        v_cost_per_lease := p_actual_spent / v_campaign.leases_signed;
    END IF;
    
    -- Update campaign
    UPDATE bms.marketing_campaigns
    SET actual_spent = COALESCE(p_actual_spent, actual_spent),
        cost_per_lead = v_cost_per_lead,
        cost_per_lease = v_cost_per_lease,
        performance_analysis = COALESCE(p_performance_analysis, performance_analysis),
        roi_analysis = COALESCE(p_roi_analysis, roi_analysis),
        updated_at = NOW()
    WHERE campaign_id = p_campaign_id;
    
    RETURN true;
END;
$$;--
 8. Vacancy statistics view
CREATE OR REPLACE VIEW bms.v_vacancy_statistics AS
SELECT 
    vt.company_id,
    
    -- Overall vacancy statistics
    COUNT(*) as total_vacancies,
    COUNT(*) FILTER (WHERE vacancy_status = 'ACTIVE') as active_vacancies,
    COUNT(*) FILTER (WHERE vacancy_status = 'LEASED') as resolved_vacancies,
    
    -- Vacancy duration statistics
    AVG(vacancy_duration_days) FILTER (WHERE vacancy_status = 'LEASED') as avg_vacancy_days,
    MIN(vacancy_duration_days) FILTER (WHERE vacancy_status = 'LEASED') as min_vacancy_days,
    MAX(vacancy_duration_days) FILTER (WHERE vacancy_status = 'LEASED') as max_vacancy_days,
    
    -- Financial impact
    SUM(total_vacancy_cost) as total_vacancy_costs,
    AVG(total_vacancy_cost) as avg_vacancy_cost,
    SUM(lost_rental_income) as total_lost_income,
    SUM(marketing_costs) as total_marketing_costs,
    SUM(preparation_costs) as total_preparation_costs,
    
    -- Vacancy reasons breakdown
    COUNT(*) FILTER (WHERE vacancy_reason = 'TENANT_TURNOVER') as tenant_turnover_count,
    COUNT(*) FILTER (WHERE vacancy_reason = 'LEASE_EXPIRY') as lease_expiry_count,
    COUNT(*) FILTER (WHERE vacancy_reason = 'EARLY_TERMINATION') as early_termination_count,
    COUNT(*) FILTER (WHERE vacancy_reason = 'EVICTION') as eviction_count,
    
    -- Current month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', vacancy_start_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_vacancies,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', resolution_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_resolved,
    
    -- Building-level aggregation
    b.name as building_name,
    b.building_id,
    
    -- Latest update
    MAX(vt.updated_at) as last_updated_at
    
FROM bms.vacancy_tracking vt
JOIN bms.units u ON vt.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
GROUP BY vt.company_id, b.building_id, b.name;

-- 9. Marketing performance view
CREATE OR REPLACE VIEW bms.v_marketing_performance AS
SELECT 
    mc.campaign_id,
    mc.company_id,
    mc.building_id,
    b.name as building_name,
    
    -- Campaign information
    mc.campaign_name,
    mc.campaign_type,
    mc.campaign_status,
    mc.campaign_start_date,
    mc.campaign_end_date,
    
    -- Budget and costs
    mc.planned_budget,
    mc.actual_spent,
    CASE 
        WHEN mc.planned_budget > 0 THEN 
            ROUND((mc.actual_spent / mc.planned_budget * 100), 2)
        ELSE 0
    END as budget_utilization_pct,
    
    -- Performance metrics
    mc.total_leads,
    mc.qualified_leads,
    mc.applications_received,
    mc.leases_signed,
    mc.cost_per_lead,
    mc.cost_per_lease,
    
    -- Conversion rates
    CASE 
        WHEN mc.total_leads > 0 THEN 
            ROUND((mc.qualified_leads::DECIMAL / mc.total_leads * 100), 2)
        ELSE 0
    END as lead_qualification_rate,
    
    CASE 
        WHEN mc.qualified_leads > 0 THEN 
            ROUND((mc.applications_received::DECIMAL / mc.qualified_leads * 100), 2)
        ELSE 0
    END as application_conversion_rate,
    
    CASE 
        WHEN mc.applications_received > 0 THEN 
            ROUND((mc.leases_signed::DECIMAL / mc.applications_received * 100), 2)
        ELSE 0
    END as lease_conversion_rate,
    
    CASE 
        WHEN mc.total_leads > 0 THEN 
            ROUND((mc.leases_signed::DECIMAL / mc.total_leads * 100), 2)
        ELSE 0
    END as overall_conversion_rate,
    
    -- ROI calculation
    CASE 
        WHEN mc.actual_spent > 0 AND mc.leases_signed > 0 THEN
            -- Assuming average monthly rent of $1500 for ROI calculation
            ROUND(((mc.leases_signed * 1500) / mc.actual_spent * 100), 2)
        ELSE 0
    END as estimated_roi_pct
    
FROM bms.marketing_campaigns mc
LEFT JOIN bms.buildings b ON mc.building_id = b.building_id;-- 10. Pros
pect pipeline view
CREATE OR REPLACE VIEW bms.v_prospect_pipeline AS
SELECT 
    pi.company_id,
    
    -- Pipeline statistics by status
    COUNT(*) as total_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'NEW') as new_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'CONTACTED') as contacted_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'QUALIFIED') as qualified_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'INTERESTED') as interested_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'APPLIED') as applied_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'APPROVED') as approved_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'LEASED') as leased_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'LOST') as lost_prospects,
    COUNT(*) FILTER (WHERE lead_status = 'UNQUALIFIED') as unqualified_prospects,
    
    -- Source analysis
    COUNT(*) FILTER (WHERE inquiry_source = 'WEBSITE') as website_inquiries,
    COUNT(*) FILTER (WHERE inquiry_source = 'REFERRAL') as referral_inquiries,
    COUNT(*) FILTER (WHERE inquiry_source = 'WALK_IN') as walk_in_inquiries,
    COUNT(*) FILTER (WHERE inquiry_source = 'ONLINE_LISTING') as online_listing_inquiries,
    COUNT(*) FILTER (WHERE inquiry_source = 'SOCIAL_MEDIA') as social_media_inquiries,
    
    -- Timeline analysis
    COUNT(*) FILTER (WHERE move_in_timeline = 'IMMEDIATE') as immediate_move_in,
    COUNT(*) FILTER (WHERE move_in_timeline = 'WITHIN_WEEK') as within_week_move_in,
    COUNT(*) FILTER (WHERE move_in_timeline = 'WITHIN_MONTH') as within_month_move_in,
    COUNT(*) FILTER (WHERE move_in_timeline = 'WITHIN_3_MONTHS') as within_3months_move_in,
    
    -- Lead quality metrics
    AVG(lead_score) as avg_lead_score,
    AVG(contact_attempts) as avg_contact_attempts,
    
    -- Conversion rates
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(*) FILTER (WHERE lead_status = 'LEASED')::DECIMAL / COUNT(*) * 100), 2)
        ELSE 0
    END as overall_conversion_rate,
    
    -- This month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', inquiry_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_inquiries,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', lease_signed_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_leases,
    
    -- Latest update
    MAX(updated_at) as last_updated_at
    
FROM bms.prospect_inquiries pi
GROUP BY pi.company_id;

-- 11. Comments
COMMENT ON FUNCTION bms.create_vacancy_tracking(UUID, UUID, DATE, VARCHAR, VARCHAR, UUID, DATE, DECIMAL, UUID) IS 'Create vacancy tracking - Start tracking vacancy for a unit with reason and market conditions';
COMMENT ON FUNCTION bms.end_vacancy_tracking(UUID, DATE, VARCHAR, DECIMAL, DECIMAL, DECIMAL) IS 'End vacancy tracking - Complete vacancy tracking with resolution and costs';
COMMENT ON FUNCTION bms.create_marketing_campaign(UUID, UUID, VARCHAR, TEXT, VARCHAR, DATE, DATE, DECIMAL, JSONB, JSONB, UUID) IS 'Create marketing campaign - Set up marketing campaign for rental properties';
COMMENT ON FUNCTION bms.create_prospect_inquiry(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID, UUID, JSONB, JSONB, VARCHAR, TEXT, UUID) IS 'Create prospect inquiry - Record new prospect inquiry with lead scoring';
COMMENT ON FUNCTION bms.update_prospect_status(UUID, VARCHAR, TEXT, DATE, DATE) IS 'Update prospect status - Update prospect lead status and track conversion funnel';
COMMENT ON FUNCTION bms.create_market_analysis(UUID, UUID, VARCHAR, VARCHAR, JSONB, DECIMAL, DECIMAL, JSONB, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DECIMAL, VARCHAR, TEXT, UUID) IS 'Create market analysis - Record market research and competitive analysis';
COMMENT ON FUNCTION bms.update_campaign_performance(UUID, DECIMAL, JSONB, JSONB) IS 'Update campaign performance - Update campaign metrics and ROI analysis';

COMMENT ON VIEW bms.v_vacancy_statistics IS 'Vacancy statistics view - Comprehensive vacancy tracking and cost analysis by building';
COMMENT ON VIEW bms.v_marketing_performance IS 'Marketing performance view - Campaign performance metrics and conversion rates';
COMMENT ON VIEW bms.v_prospect_pipeline IS 'Prospect pipeline view - Lead funnel analysis and conversion tracking';

-- Script completion message
SELECT 'Vacancy and marketing management functions created successfully.' as message;