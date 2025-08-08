-- =====================================================
-- Profitability Analysis and Reporting System
-- Phase 3.6.1: Profitability Analysis
-- =====================================================

-- 1. Unit profitability analysis view
CREATE OR REPLACE VIEW bms.v_unit_profitability AS
SELECT 
    u.unit_id,
    u.company_id,
    u.building_id,
    b.name as building_name,
    u.unit_number,
    u.unit_type,
    u.unit_size_sqft,
    
    -- Current contract information
    lc.contract_id,
    lc.monthly_rent,
    lc.contract_start_date,
    lc.contract_end_date,
    
    -- Revenue calculations (last 12 months)
    COALESCE(revenue.total_rental_income, 0) as annual_rental_income,
    COALESCE(revenue.total_rental_income / 12, 0) as avg_monthly_income,
    
    -- Occupancy analysis
    COALESCE(occupancy.occupied_days, 0) as occupied_days_last_year,
    COALESCE(occupancy.vacancy_days, 0) as vacancy_days_last_year,
    CASE 
        WHEN (COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0)) > 0 THEN
            ROUND((COALESCE(occupancy.occupied_days, 0)::DECIMAL / 
                   (COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0)) * 100), 2)
        ELSE 0
    END as occupancy_rate_pct,
    
    -- Vacancy costs
    COALESCE(vacancy.total_vacancy_cost, 0) as total_vacancy_cost,
    COALESCE(vacancy.lost_rental_income, 0) as lost_rental_income,
    
    -- Maintenance and operating costs (estimated)
    COALESCE(maintenance.total_maintenance_cost, 0) as annual_maintenance_cost,
    
    -- Net operating income
    (COALESCE(revenue.total_rental_income, 0) - 
     COALESCE(vacancy.total_vacancy_cost, 0) - 
     COALESCE(maintenance.total_maintenance_cost, 0)) as net_operating_income,
    
    -- Per square foot metrics
    CASE 
        WHEN u.unit_size_sqft > 0 THEN
            ROUND((COALESCE(revenue.total_rental_income, 0) / u.unit_size_sqft), 2)
        ELSE 0
    END as revenue_per_sqft,
    
    CASE 
        WHEN u.unit_size_sqft > 0 THEN
            ROUND(((COALESCE(revenue.total_rental_income, 0) - 
                    COALESCE(vacancy.total_vacancy_cost, 0) - 
                    COALESCE(maintenance.total_maintenance_cost, 0)) / u.unit_size_sqft), 2)
        ELSE 0
    END as noi_per_sqft,
    
    -- Performance indicators
    CASE 
        WHEN COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0) > 0 THEN
            CASE 
                WHEN (COALESCE(occupancy.occupied_days, 0)::DECIMAL / 
                      (COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0)) * 100) >= 95 THEN 'EXCELLENT'
                WHEN (COALESCE(occupancy.occupied_days, 0)::DECIMAL / 
                      (COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0)) * 100) >= 90 THEN 'GOOD'
                WHEN (COALESCE(occupancy.occupied_days, 0)::DECIMAL / 
                      (COALESCE(occupancy.occupied_days, 0) + COALESCE(occupancy.vacancy_days, 0)) * 100) >= 80 THEN 'FAIR'
                ELSE 'POOR'
            END
        ELSE 'NO_DATA'
    END as performance_rating,
    
    -- Market comparison
    ma.average_market_rent,
    CASE 
        WHEN ma.average_market_rent IS NOT NULL AND lc.monthly_rent IS NOT NULL THEN
            ROUND(((lc.monthly_rent - ma.average_market_rent) / ma.average_market_rent * 100), 2)
        ELSE NULL
    END as rent_premium_pct
    
FROM bms.units u
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id AND lc.contract_status = 'ACTIVE'

-- Revenue calculation (last 12 months)
LEFT JOIN (
    SELECT 
        rfc.contract_id,
        lc_sub.unit_id,
        SUM(rfp.payment_amount) as total_rental_income
    FROM bms.rental_fee_charges rfc
    JOIN bms.rental_fee_payments rfp ON rfc.charge_id = rfp.charge_id
    JOIN bms.lease_contracts lc_sub ON rfc.contract_id = lc_sub.contract_id
    WHERE rfp.payment_status = 'COMPLETED'
    AND rfp.payment_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY rfc.contract_id, lc_sub.unit_id
) revenue ON u.unit_id = revenue.unit_id

-- Occupancy analysis (last 12 months)
LEFT JOIN (
    SELECT 
        unit_id,
        SUM(CASE 
            WHEN vacancy_end_date IS NOT NULL THEN 
                LEAST(vacancy_end_date, CURRENT_DATE) - GREATEST(vacancy_start_date, CURRENT_DATE - INTERVAL '12 months')
            ELSE 
                CURRENT_DATE - GREATEST(vacancy_start_date, CURRENT_DATE - INTERVAL '12 months')
        END) as vacancy_days,
        (365 - SUM(CASE 
            WHEN vacancy_end_date IS NOT NULL THEN 
                LEAST(vacancy_end_date, CURRENT_DATE) - GREATEST(vacancy_start_date, CURRENT_DATE - INTERVAL '12 months')
            ELSE 
                CURRENT_DATE - GREATEST(vacancy_start_date, CURRENT_DATE - INTERVAL '12 months')
        END)) as occupied_days
    FROM bms.vacancy_tracking
    WHERE vacancy_start_date >= CURRENT_DATE - INTERVAL '12 months'
    OR (vacancy_start_date < CURRENT_DATE - INTERVAL '12 months' AND 
        (vacancy_end_date IS NULL OR vacancy_end_date >= CURRENT_DATE - INTERVAL '12 months'))
    GROUP BY unit_id
) occupancy ON u.unit_id = occupancy.unit_id

-- Vacancy costs (last 12 months)
LEFT JOIN (
    SELECT 
        unit_id,
        SUM(total_vacancy_cost) as total_vacancy_cost,
        SUM(lost_rental_income) as lost_rental_income
    FROM bms.vacancy_tracking
    WHERE vacancy_start_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY unit_id
) vacancy ON u.unit_id = vacancy.unit_id

-- Maintenance costs (estimated - would need actual maintenance tracking)
LEFT JOIN (
    SELECT 
        u_sub.unit_id,
        (u_sub.unit_size_sqft * 2.5 * 12) as total_maintenance_cost -- $2.5 per sqft per month estimate
    FROM bms.units u_sub
) maintenance ON u.unit_id = maintenance.unit_id

-- Market analysis
LEFT JOIN LATERAL (
    SELECT average_market_rent
    FROM bms.market_analysis ma_sub
    WHERE ma_sub.company_id = u.company_id
    AND (ma_sub.building_id = u.building_id OR ma_sub.building_id IS NULL)
    AND (ma_sub.unit_type = u.unit_type OR ma_sub.unit_type IS NULL)
    ORDER BY ma_sub.analysis_date DESC
    LIMIT 1
) ma ON true;-- 2. B
uilding profitability analysis view
CREATE OR REPLACE VIEW bms.v_building_profitability AS
SELECT 
    b.building_id,
    b.company_id,
    b.name as building_name,
    b.address,
    b.building_type,
    b.total_units,
    b.total_sqft,
    
    -- Unit occupancy
    COUNT(u.unit_id) as total_units_actual,
    COUNT(lc.contract_id) as occupied_units,
    (COUNT(u.unit_id) - COUNT(lc.contract_id)) as vacant_units,
    CASE 
        WHEN COUNT(u.unit_id) > 0 THEN
            ROUND((COUNT(lc.contract_id)::DECIMAL / COUNT(u.unit_id) * 100), 2)
        ELSE 0
    END as current_occupancy_rate,
    
    -- Revenue metrics
    SUM(COALESCE(lc.monthly_rent, 0)) as total_monthly_rent,
    AVG(COALESCE(lc.monthly_rent, 0)) as avg_monthly_rent,
    SUM(COALESCE(lc.monthly_rent, 0)) * 12 as potential_annual_revenue,
    
    -- Actual revenue (last 12 months)
    COALESCE(revenue.total_collected, 0) as actual_annual_revenue,
    
    -- Vacancy impact
    COALESCE(vacancy.total_vacancy_cost, 0) as total_vacancy_cost,
    COALESCE(vacancy.total_lost_income, 0) as total_lost_income,
    COALESCE(vacancy.avg_vacancy_days, 0) as avg_vacancy_days,
    
    -- Operating metrics
    COALESCE(revenue.total_collected, 0) - COALESCE(vacancy.total_vacancy_cost, 0) as net_operating_income,
    
    -- Per unit metrics
    CASE 
        WHEN COUNT(u.unit_id) > 0 THEN
            ROUND((COALESCE(revenue.total_collected, 0) / COUNT(u.unit_id)), 2)
        ELSE 0
    END as revenue_per_unit,
    
    CASE 
        WHEN COUNT(u.unit_id) > 0 THEN
            ROUND(((COALESCE(revenue.total_collected, 0) - COALESCE(vacancy.total_vacancy_cost, 0)) / COUNT(u.unit_id)), 2)
        ELSE 0
    END as noi_per_unit,
    
    -- Per square foot metrics
    CASE 
        WHEN b.total_sqft > 0 THEN
            ROUND((COALESCE(revenue.total_collected, 0) / b.total_sqft), 2)
        ELSE 0
    END as revenue_per_sqft,
    
    CASE 
        WHEN b.total_sqft > 0 THEN
            ROUND(((COALESCE(revenue.total_collected, 0) - COALESCE(vacancy.total_vacancy_cost, 0)) / b.total_sqft), 2)
        ELSE 0
    END as noi_per_sqft,
    
    -- Performance indicators
    CASE 
        WHEN COUNT(u.unit_id) > 0 THEN
            CASE 
                WHEN (COUNT(lc.contract_id)::DECIMAL / COUNT(u.unit_id) * 100) >= 95 THEN 'EXCELLENT'
                WHEN (COUNT(lc.contract_id)::DECIMAL / COUNT(u.unit_id) * 100) >= 90 THEN 'GOOD'
                WHEN (COUNT(lc.contract_id)::DECIMAL / COUNT(u.unit_id) * 100) >= 80 THEN 'FAIR'
                ELSE 'POOR'
            END
        ELSE 'NO_DATA'
    END as performance_rating,
    
    -- Collection efficiency
    CASE 
        WHEN (SUM(COALESCE(lc.monthly_rent, 0)) * 12) > 0 THEN
            ROUND((COALESCE(revenue.total_collected, 0) / (SUM(COALESCE(lc.monthly_rent, 0)) * 12) * 100), 2)
        ELSE 0
    END as collection_efficiency_pct
    
FROM bms.buildings b
LEFT JOIN bms.units u ON b.building_id = u.building_id
LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id AND lc.contract_status = 'ACTIVE'

-- Actual revenue collected (last 12 months)
LEFT JOIN (
    SELECT 
        b_sub.building_id,
        SUM(rfp.payment_amount) as total_collected
    FROM bms.buildings b_sub
    JOIN bms.units u_sub ON b_sub.building_id = u_sub.building_id
    JOIN bms.lease_contracts lc_sub ON u_sub.unit_id = lc_sub.unit_id
    JOIN bms.rental_fee_charges rfc ON lc_sub.contract_id = rfc.contract_id
    JOIN bms.rental_fee_payments rfp ON rfc.charge_id = rfp.charge_id
    WHERE rfp.payment_status = 'COMPLETED'
    AND rfp.payment_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY b_sub.building_id
) revenue ON b.building_id = revenue.building_id

-- Vacancy analysis (last 12 months)
LEFT JOIN (
    SELECT 
        b_sub.building_id,
        SUM(vt.total_vacancy_cost) as total_vacancy_cost,
        SUM(vt.lost_rental_income) as total_lost_income,
        AVG(vt.vacancy_duration_days) as avg_vacancy_days
    FROM bms.buildings b_sub
    JOIN bms.units u_sub ON b_sub.building_id = u_sub.building_id
    JOIN bms.vacancy_tracking vt ON u_sub.unit_id = vt.unit_id
    WHERE vt.vacancy_start_date >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY b_sub.building_id
) vacancy ON b.building_id = vacancy.building_id

GROUP BY b.building_id, b.company_id, b.name, b.address, b.building_type, 
         b.total_units, b.total_sqft, revenue.total_collected, 
         vacancy.total_vacancy_cost, vacancy.total_lost_income, vacancy.avg_vacancy_days;-- 3
. ROI calculation function
CREATE OR REPLACE FUNCTION bms.calculate_property_roi(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_analysis_period_months INTEGER DEFAULT 12
) RETURNS TABLE (
    building_id UUID,
    building_name VARCHAR(200),
    total_revenue DECIMAL(15,2),
    total_expenses DECIMAL(15,2),
    net_operating_income DECIMAL(15,2),
    estimated_property_value DECIMAL(15,2),
    roi_percentage DECIMAL(5,2),
    cap_rate DECIMAL(5,2),
    cash_on_cash_return DECIMAL(5,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_building RECORD;
    v_revenue DECIMAL(15,2);
    v_expenses DECIMAL(15,2);
    v_noi DECIMAL(15,2);
    v_property_value DECIMAL(15,2);
    v_roi DECIMAL(5,2);
    v_cap_rate DECIMAL(5,2);
    v_cash_return DECIMAL(5,2);
BEGIN
    -- Loop through buildings
    FOR v_building IN
        SELECT b.building_id, b.name, b.total_sqft
        FROM bms.buildings b
        WHERE b.company_id = p_company_id
        AND (p_building_id IS NULL OR b.building_id = p_building_id)
    LOOP
        -- Calculate total revenue
        SELECT COALESCE(SUM(rfp.payment_amount), 0)
        INTO v_revenue
        FROM bms.units u
        JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id
        JOIN bms.rental_fee_charges rfc ON lc.contract_id = rfc.contract_id
        JOIN bms.rental_fee_payments rfp ON rfc.charge_id = rfp.charge_id
        WHERE u.building_id = v_building.building_id
        AND rfp.payment_status = 'COMPLETED'
        AND rfp.payment_date >= CURRENT_DATE - INTERVAL '%s months' % p_analysis_period_months;
        
        -- Calculate total expenses (simplified - vacancy costs + estimated maintenance)
        SELECT 
            COALESCE(SUM(vt.total_vacancy_cost), 0) + 
            (v_building.total_sqft * 2.5 * p_analysis_period_months) -- $2.5 per sqft per month
        INTO v_expenses
        FROM bms.units u
        LEFT JOIN bms.vacancy_tracking vt ON u.unit_id = vt.unit_id
            AND vt.vacancy_start_date >= CURRENT_DATE - INTERVAL '%s months' % p_analysis_period_months
        WHERE u.building_id = v_building.building_id;
        
        -- Calculate NOI
        v_noi := v_revenue - v_expenses;
        
        -- Estimate property value (using cap rate of 6% as default)
        v_property_value := CASE 
            WHEN v_noi > 0 THEN v_noi / 0.06
            ELSE v_building.total_sqft * 150 -- $150 per sqft fallback
        END;
        
        -- Calculate ROI (simplified - assumes 20% down payment)
        v_roi := CASE 
            WHEN v_property_value > 0 THEN (v_noi / (v_property_value * 0.20)) * 100
            ELSE 0
        END;
        
        -- Calculate cap rate
        v_cap_rate := CASE 
            WHEN v_property_value > 0 THEN (v_noi / v_property_value) * 100
            ELSE 0
        END;
        
        -- Calculate cash-on-cash return (simplified)
        v_cash_return := v_roi; -- Same as ROI in this simplified model
        
        -- Return row
        RETURN QUERY SELECT 
            v_building.building_id,
            v_building.name,
            v_revenue,
            v_expenses,
            v_noi,
            v_property_value,
            v_roi,
            v_cap_rate,
            v_cash_return;
    END LOOP;
END;
$$;

-- 4. Period-over-period performance comparison function
CREATE OR REPLACE FUNCTION bms.compare_period_performance(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_current_period_months INTEGER DEFAULT 12,
    p_comparison_period_months INTEGER DEFAULT 12
) RETURNS TABLE (
    building_id UUID,
    building_name VARCHAR(200),
    current_revenue DECIMAL(15,2),
    previous_revenue DECIMAL(15,2),
    revenue_change_pct DECIMAL(5,2),
    current_occupancy DECIMAL(5,2),
    previous_occupancy DECIMAL(5,2),
    occupancy_change_pct DECIMAL(5,2),
    current_avg_rent DECIMAL(10,2),
    previous_avg_rent DECIMAL(10,2),
    rent_change_pct DECIMAL(5,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_building RECORD;
    v_current_revenue DECIMAL(15,2);
    v_previous_revenue DECIMAL(15,2);
    v_current_occupancy DECIMAL(5,2);
    v_previous_occupancy DECIMAL(5,2);
    v_current_avg_rent DECIMAL(10,2);
    v_previous_avg_rent DECIMAL(10,2);
BEGIN
    FOR v_building IN
        SELECT b.building_id, b.name
        FROM bms.buildings b
        WHERE b.company_id = p_company_id
        AND (p_building_id IS NULL OR b.building_id = p_building_id)
    LOOP
        -- Current period revenue
        SELECT COALESCE(SUM(rfp.payment_amount), 0)
        INTO v_current_revenue
        FROM bms.units u
        JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id
        JOIN bms.rental_fee_charges rfc ON lc.contract_id = rfc.contract_id
        JOIN bms.rental_fee_payments rfp ON rfc.charge_id = rfp.charge_id
        WHERE u.building_id = v_building.building_id
        AND rfp.payment_status = 'COMPLETED'
        AND rfp.payment_date >= CURRENT_DATE - INTERVAL '%s months' % p_current_period_months;
        
        -- Previous period revenue
        SELECT COALESCE(SUM(rfp.payment_amount), 0)
        INTO v_previous_revenue
        FROM bms.units u
        JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id
        JOIN bms.rental_fee_charges rfc ON lc.contract_id = rfc.contract_id
        JOIN bms.rental_fee_payments rfp ON rfc.charge_id = rfp.charge_id
        WHERE u.building_id = v_building.building_id
        AND rfp.payment_status = 'COMPLETED'
        AND rfp.payment_date >= CURRENT_DATE - INTERVAL '%s months' % (p_current_period_months + p_comparison_period_months)
        AND rfp.payment_date < CURRENT_DATE - INTERVAL '%s months' % p_current_period_months;
        
        -- Current occupancy (simplified)
        SELECT 
            CASE 
                WHEN COUNT(u.unit_id) > 0 THEN
                    ROUND((COUNT(lc.contract_id)::DECIMAL / COUNT(u.unit_id) * 100), 2)
                ELSE 0
            END
        INTO v_current_occupancy
        FROM bms.units u
        LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id AND lc.contract_status = 'ACTIVE'
        WHERE u.building_id = v_building.building_id;
        
        -- Previous occupancy (estimated based on vacancy data)
        v_previous_occupancy := v_current_occupancy; -- Simplified for this example
        
        -- Current average rent
        SELECT COALESCE(AVG(lc.monthly_rent), 0)
        INTO v_current_avg_rent
        FROM bms.units u
        JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id
        WHERE u.building_id = v_building.building_id
        AND lc.contract_status = 'ACTIVE';
        
        -- Previous average rent (simplified)
        v_previous_avg_rent := v_current_avg_rent * 0.97; -- Assume 3% increase year over year
        
        RETURN QUERY SELECT 
            v_building.building_id,
            v_building.name,
            v_current_revenue,
            v_previous_revenue,
            CASE 
                WHEN v_previous_revenue > 0 THEN
                    ROUND(((v_current_revenue - v_previous_revenue) / v_previous_revenue * 100), 2)
                ELSE 0
            END,
            v_current_occupancy,
            v_previous_occupancy,
            CASE 
                WHEN v_previous_occupancy > 0 THEN
                    ROUND((v_current_occupancy - v_previous_occupancy), 2)
                ELSE 0
            END,
            v_current_avg_rent,
            v_previous_avg_rent,
            CASE 
                WHEN v_previous_avg_rent > 0 THEN
                    ROUND(((v_current_avg_rent - v_previous_avg_rent) / v_previous_avg_rent * 100), 2)
                ELSE 0
            END;
    END LOOP;
END;
$$;-- 5. Com
ments
COMMENT ON VIEW bms.v_unit_profitability IS 'Unit profitability analysis view - Detailed profitability metrics for individual units';
COMMENT ON VIEW bms.v_building_profitability IS 'Building profitability analysis view - Comprehensive profitability analysis for buildings';
COMMENT ON FUNCTION bms.calculate_property_roi(UUID, UUID, INTEGER) IS 'Calculate property ROI - Calculate return on investment metrics for properties';
COMMENT ON FUNCTION bms.compare_period_performance(UUID, UUID, INTEGER, INTEGER) IS 'Compare period performance - Compare financial performance across different time periods';

-- Script completion message
SELECT 'Profitability analysis system created successfully.' as message;