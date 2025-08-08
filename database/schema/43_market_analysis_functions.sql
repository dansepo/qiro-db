-- =====================================================
-- Market Analysis and Rent Optimization Functions
-- Phase 3.4.3: Market Analysis and Rent Setting
-- =====================================================

-- 1. Calculate optimal rent function
CREATE OR REPLACE FUNCTION bms.calculate_optimal_rent(
    p_company_id UUID,
    p_unit_id UUID,
    p_market_analysis_id UUID DEFAULT NULL,
    p_target_occupancy_rate DECIMAL(5,2) DEFAULT 95.0,
    p_competitive_adjustment DECIMAL(5,2) DEFAULT 0.0
) RETURNS TABLE (
    recommended_rent DECIMAL(10,2),
    market_position VARCHAR(20),
    confidence_level VARCHAR(20),
    analysis_notes TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_unit RECORD;
    v_market_data RECORD;
    v_current_rent DECIMAL(10,2);
    v_market_avg DECIMAL(10,2);
    v_recommended_rent DECIMAL(10,2);
    v_market_position VARCHAR(20);
    v_confidence_level VARCHAR(20);
    v_analysis_notes TEXT;
BEGIN
    -- Get unit information
    SELECT u.*, b.name as building_name, b.building_type
    INTO v_unit
    FROM bms.units u
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE u.unit_id = p_unit_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Unit not found: %', p_unit_id;
    END IF;
    
    -- Get current rent from active contract or asking rent
    SELECT COALESCE(lc.monthly_rent, 0)
    INTO v_current_rent
    FROM bms.lease_contracts lc
    WHERE lc.unit_id = p_unit_id
    AND lc.contract_status = 'ACTIVE'
    ORDER BY lc.contract_start_date DESC
    LIMIT 1;
    
    -- Get market analysis data
    IF p_market_analysis_id IS NOT NULL THEN
        SELECT * INTO v_market_data
        FROM bms.market_analysis
        WHERE analysis_id = p_market_analysis_id;
    ELSE
        -- Get most recent market analysis for this building/unit type
        SELECT * INTO v_market_data
        FROM bms.market_analysis
        WHERE company_id = p_company_id
        AND (building_id = v_unit.building_id OR building_id IS NULL)
        AND (unit_type = v_unit.unit_type OR unit_type IS NULL)
        ORDER BY analysis_date DESC
        LIMIT 1;
    END IF;
    
    -- Calculate recommended rent
    IF v_market_data.analysis_id IS NOT NULL THEN
        v_market_avg := v_market_data.average_market_rent;
        
        -- Base recommendation on market average
        v_recommended_rent := v_market_avg;
        
        -- Adjust for competitive position
        IF v_market_data.competitive_position = 'PREMIUM' THEN
            v_recommended_rent := v_recommended_rent * 1.10;
            v_market_position := 'PREMIUM';
        ELSIF v_market_data.competitive_position = 'ABOVE_MARKET' THEN
            v_recommended_rent := v_recommended_rent * 1.05;
            v_market_position := 'ABOVE_MARKET';
        ELSIF v_market_data.competitive_position = 'BELOW_MARKET' THEN
            v_recommended_rent := v_recommended_rent * 0.95;
            v_market_position := 'BELOW_MARKET';
        ELSIF v_market_data.competitive_position = 'VALUE' THEN
            v_recommended_rent := v_recommended_rent * 0.90;
            v_market_position := 'VALUE';
        ELSE
            v_market_position := 'MARKET_RATE';
        END IF;
        
        -- Apply competitive adjustment
        v_recommended_rent := v_recommended_rent * (1 + p_competitive_adjustment / 100);
        
        -- Adjust for occupancy target
        IF p_target_occupancy_rate > 95 THEN
            v_recommended_rent := v_recommended_rent * 0.98; -- Slightly lower for higher occupancy
        ELSIF p_target_occupancy_rate < 90 THEN
            v_recommended_rent := v_recommended_rent * 1.02; -- Slightly higher for lower occupancy target
        END IF;
        
        -- Determine confidence level
        IF v_market_data.analysis_date >= CURRENT_DATE - INTERVAL '30 days' THEN
            v_confidence_level := 'HIGH';
        ELSIF v_market_data.analysis_date >= CURRENT_DATE - INTERVAL '90 days' THEN
            v_confidence_level := 'MEDIUM';
        ELSE
            v_confidence_level := 'LOW';
        END IF;
        
        -- Generate analysis notes
        v_analysis_notes := FORMAT(
            'Based on market analysis from %s. Current rent: $%s, Market average: $%s, Recommended: $%s. ' ||
            'Market trend: %s, Demand: %s, Supply: %s.',
            v_market_data.analysis_date,
            v_current_rent,
            v_market_avg,
            v_recommended_rent,
            COALESCE(v_market_data.rent_trend, 'Unknown'),
            COALESCE(v_market_data.demand_level, 'Unknown'),
            COALESCE(v_market_data.supply_level, 'Unknown')
        );
        
    ELSE
        -- No market data available, use current rent or estimate
        v_recommended_rent := COALESCE(v_current_rent, 1500); -- Default fallback
        v_market_position := 'UNKNOWN';
        v_confidence_level := 'LOW';
        v_analysis_notes := 'No recent market analysis available. Recommendation based on current rent or default estimate.';
    END IF;
    
    -- Round to nearest $5
    v_recommended_rent := ROUND(v_recommended_rent / 5) * 5;
    
    RETURN QUERY SELECT v_recommended_rent, v_market_position, v_confidence_level, v_analysis_notes;
END;
$$;-
- 2. Analyze rent performance function
CREATE OR REPLACE FUNCTION bms.analyze_rent_performance(
    p_company_id UUID,
    p_building_id UUID DEFAULT NULL,
    p_analysis_period INTEGER DEFAULT 12 -- months
) RETURNS TABLE (
    unit_id UUID,
    unit_number VARCHAR(20),
    current_rent DECIMAL(10,2),
    market_rent DECIMAL(10,2),
    rent_variance_pct DECIMAL(5,2),
    rent_performance VARCHAR(20),
    vacancy_risk VARCHAR(20),
    recommendation TEXT
) LANGUAGE plpgsql AS $$
DECLARE
    v_unit RECORD;
    v_market_avg DECIMAL(10,2);
    v_variance_pct DECIMAL(5,2);
    v_performance VARCHAR(20);
    v_vacancy_risk VARCHAR(20);
    v_recommendation TEXT;
BEGIN
    -- Loop through units
    FOR v_unit IN
        SELECT u.unit_id, u.unit_number, u.unit_type, u.building_id,
               lc.monthly_rent as current_rent
        FROM bms.units u
        LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id 
            AND lc.contract_status = 'ACTIVE'
        WHERE u.company_id = p_company_id
        AND (p_building_id IS NULL OR u.building_id = p_building_id)
        AND u.unit_status IN ('OCCUPIED', 'VACANT')
    LOOP
        -- Get market average for this unit type
        SELECT average_market_rent
        INTO v_market_avg
        FROM bms.market_analysis
        WHERE company_id = p_company_id
        AND (building_id = v_unit.building_id OR building_id IS NULL)
        AND (unit_type = v_unit.unit_type OR unit_type IS NULL)
        AND analysis_date >= CURRENT_DATE - INTERVAL '%s months' % p_analysis_period
        ORDER BY analysis_date DESC
        LIMIT 1;
        
        -- Use default if no market data
        IF v_market_avg IS NULL THEN
            v_market_avg := 1500; -- Default market rent
        END IF;
        
        -- Calculate variance
        IF v_unit.current_rent IS NOT NULL AND v_market_avg > 0 THEN
            v_variance_pct := ((v_unit.current_rent - v_market_avg) / v_market_avg) * 100;
        ELSE
            v_variance_pct := 0;
        END IF;
        
        -- Determine performance
        IF v_variance_pct > 10 THEN
            v_performance := 'ABOVE_MARKET';
            v_vacancy_risk := 'HIGH';
            v_recommendation := 'Consider rent reduction to improve competitiveness';
        ELSIF v_variance_pct > 5 THEN
            v_performance := 'SLIGHTLY_HIGH';
            v_vacancy_risk := 'MEDIUM';
            v_recommendation := 'Monitor market conditions closely';
        ELSIF v_variance_pct < -10 THEN
            v_performance := 'BELOW_MARKET';
            v_vacancy_risk := 'LOW';
            v_recommendation := 'Opportunity for rent increase';
        ELSIF v_variance_pct < -5 THEN
            v_performance := 'SLIGHTLY_LOW';
            v_vacancy_risk := 'LOW';
            v_recommendation := 'Consider modest rent increase';
        ELSE
            v_performance := 'MARKET_RATE';
            v_vacancy_risk := 'LOW';
            v_recommendation := 'Rent is appropriately positioned';
        END IF;
        
        -- Return row
        RETURN QUERY SELECT 
            v_unit.unit_id,
            v_unit.unit_number,
            v_unit.current_rent,
            v_market_avg,
            v_variance_pct,
            v_performance,
            v_vacancy_risk,
            v_recommendation;
    END LOOP;
END;
$$;

-- 3. Generate pricing strategy function
CREATE OR REPLACE FUNCTION bms.generate_pricing_strategy(
    p_company_id UUID,
    p_building_id UUID,
    p_target_occupancy DECIMAL(5,2) DEFAULT 95.0,
    p_target_revenue_growth DECIMAL(5,2) DEFAULT 3.0
) RETURNS TABLE (
    strategy_type VARCHAR(30),
    strategy_description TEXT,
    expected_occupancy_impact DECIMAL(5,2),
    expected_revenue_impact DECIMAL(5,2),
    implementation_priority INTEGER,
    risk_level VARCHAR(20)
) LANGUAGE plpgsql AS $$
DECLARE
    v_building RECORD;
    v_current_occupancy DECIMAL(5,2);
    v_avg_rent DECIMAL(10,2);
    v_market_conditions RECORD;
BEGIN
    -- Get building information
    SELECT * INTO v_building
    FROM bms.buildings
    WHERE building_id = p_building_id;
    
    -- Calculate current occupancy
    SELECT 
        (COUNT(*) FILTER (WHERE u.unit_status = 'OCCUPIED')::DECIMAL / COUNT(*) * 100)
    INTO v_current_occupancy
    FROM bms.units u
    WHERE u.building_id = p_building_id;
    
    -- Get average rent
    SELECT AVG(lc.monthly_rent)
    INTO v_avg_rent
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    WHERE u.building_id = p_building_id
    AND lc.contract_status = 'ACTIVE';
    
    -- Get market conditions
    SELECT * INTO v_market_conditions
    FROM bms.market_analysis
    WHERE company_id = p_company_id
    AND (building_id = p_building_id OR building_id IS NULL)
    ORDER BY analysis_date DESC
    LIMIT 1;
    
    -- Generate strategies based on current situation
    
    -- Strategy 1: Market-based pricing
    RETURN QUERY SELECT 
        'MARKET_PRICING'::VARCHAR(30),
        'Align rents with current market rates based on recent analysis'::TEXT,
        CASE WHEN v_current_occupancy < p_target_occupancy THEN 2.0 ELSE -1.0 END,
        CASE WHEN v_market_conditions.rent_trend = 'INCREASING' THEN 3.0 ELSE 1.0 END,
        1,
        'LOW'::VARCHAR(20);
    
    -- Strategy 2: Value-add pricing
    IF v_current_occupancy >= p_target_occupancy THEN
        RETURN QUERY SELECT 
            'VALUE_ADD_PRICING'::VARCHAR(30),
            'Implement amenity improvements and increase rents accordingly'::TEXT,
            -2.0::DECIMAL(5,2),
            5.0::DECIMAL(5,2),
            2,
            'MEDIUM'::VARCHAR(20);
    END IF;
    
    -- Strategy 3: Penetration pricing
    IF v_current_occupancy < 85 THEN
        RETURN QUERY SELECT 
            'PENETRATION_PRICING'::VARCHAR(30),
            'Reduce rents temporarily to increase occupancy quickly'::TEXT,
            8.0::DECIMAL(5,2),
            -3.0::DECIMAL(5,2),
            1,
            'HIGH'::VARCHAR(20);
    END IF;
    
    -- Strategy 4: Dynamic pricing
    RETURN QUERY SELECT 
        'DYNAMIC_PRICING'::VARCHAR(30),
        'Implement flexible pricing based on demand, seasonality, and market conditions'::TEXT,
        3.0::DECIMAL(5,2),
        4.0::DECIMAL(5,2),
        3,
        'MEDIUM'::VARCHAR(20);
    
    -- Strategy 5: Premium positioning
    IF v_current_occupancy >= 95 AND v_market_conditions.competitive_position = 'PREMIUM' THEN
        RETURN QUERY SELECT 
            'PREMIUM_POSITIONING'::VARCHAR(30),
            'Position as premium property with higher rents and enhanced services'::TEXT,
            -3.0::DECIMAL(5,2),
            8.0::DECIMAL(5,2),
            2,
            'HIGH'::VARCHAR(20);
    END IF;
END;
$$;-- 4. Mar
ket competitiveness analysis view
CREATE OR REPLACE VIEW bms.v_market_competitiveness AS
SELECT 
    b.building_id,
    b.company_id,
    b.name as building_name,
    b.address,
    
    -- Current performance
    COUNT(u.unit_id) as total_units,
    COUNT(u.unit_id) FILTER (WHERE u.unit_status = 'OCCUPIED') as occupied_units,
    ROUND((COUNT(u.unit_id) FILTER (WHERE u.unit_status = 'OCCUPIED')::DECIMAL / COUNT(u.unit_id) * 100), 2) as occupancy_rate,
    
    -- Rent analysis
    AVG(lc.monthly_rent) as avg_current_rent,
    MIN(lc.monthly_rent) as min_rent,
    MAX(lc.monthly_rent) as max_rent,
    
    -- Market comparison
    ma.average_market_rent,
    CASE 
        WHEN AVG(lc.monthly_rent) IS NOT NULL AND ma.average_market_rent IS NOT NULL THEN
            ROUND(((AVG(lc.monthly_rent) - ma.average_market_rent) / ma.average_market_rent * 100), 2)
        ELSE NULL
    END as rent_variance_from_market_pct,
    
    -- Market position
    ma.competitive_position,
    ma.rent_trend,
    ma.demand_level,
    ma.supply_level,
    
    -- Vacancy analysis
    COUNT(vt.vacancy_id) as total_vacancies_last_year,
    AVG(vt.vacancy_duration_days) as avg_vacancy_duration,
    SUM(vt.total_vacancy_cost) as total_vacancy_costs,
    
    -- Performance indicators
    CASE 
        WHEN ROUND((COUNT(u.unit_id) FILTER (WHERE u.unit_status = 'OCCUPIED')::DECIMAL / COUNT(u.unit_id) * 100), 2) >= 95 THEN 'EXCELLENT'
        WHEN ROUND((COUNT(u.unit_id) FILTER (WHERE u.unit_status = 'OCCUPIED')::DECIMAL / COUNT(u.unit_id) * 100), 2) >= 90 THEN 'GOOD'
        WHEN ROUND((COUNT(u.unit_id) FILTER (WHERE u.unit_status = 'OCCUPIED')::DECIMAL / COUNT(u.unit_id) * 100), 2) >= 85 THEN 'FAIR'
        ELSE 'POOR'
    END as occupancy_performance,
    
    CASE 
        WHEN AVG(lc.monthly_rent) IS NOT NULL AND ma.average_market_rent IS NOT NULL THEN
            CASE 
                WHEN ((AVG(lc.monthly_rent) - ma.average_market_rent) / ma.average_market_rent * 100) > 5 THEN 'ABOVE_MARKET'
                WHEN ((AVG(lc.monthly_rent) - ma.average_market_rent) / ma.average_market_rent * 100) < -5 THEN 'BELOW_MARKET'
                ELSE 'AT_MARKET'
            END
        ELSE 'UNKNOWN'
    END as rent_competitiveness,
    
    -- Latest analysis date
    ma.analysis_date as last_market_analysis_date
    
FROM bms.buildings b
JOIN bms.units u ON b.building_id = u.building_id
LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id AND lc.contract_status = 'ACTIVE'
LEFT JOIN LATERAL (
    SELECT *
    FROM bms.market_analysis ma_sub
    WHERE ma_sub.company_id = b.company_id
    AND (ma_sub.building_id = b.building_id OR ma_sub.building_id IS NULL)
    ORDER BY ma_sub.analysis_date DESC
    LIMIT 1
) ma ON true
LEFT JOIN bms.vacancy_tracking vt ON u.unit_id = vt.unit_id 
    AND vt.vacancy_start_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY b.building_id, b.company_id, b.name, b.address, 
         ma.average_market_rent, ma.competitive_position, ma.rent_trend, 
         ma.demand_level, ma.supply_level, ma.analysis_date;

-- 5. Rent optimization recommendations view
CREATE OR REPLACE VIEW bms.v_rent_optimization_recommendations AS
SELECT 
    u.unit_id,
    u.company_id,
    u.building_id,
    b.name as building_name,
    u.unit_number,
    u.unit_type,
    
    -- Current situation
    lc.monthly_rent as current_rent,
    u.unit_status,
    
    -- Market data
    ma.average_market_rent,
    ma.recommended_rent,
    
    -- Optimization analysis
    CASE 
        WHEN lc.monthly_rent IS NULL THEN ma.recommended_rent
        WHEN ma.recommended_rent IS NOT NULL THEN ma.recommended_rent
        ELSE lc.monthly_rent
    END as optimized_rent,
    
    CASE 
        WHEN lc.monthly_rent IS NOT NULL AND ma.recommended_rent IS NOT NULL THEN
            ma.recommended_rent - lc.monthly_rent
        ELSE 0
    END as rent_adjustment_amount,
    
    CASE 
        WHEN lc.monthly_rent IS NOT NULL AND ma.recommended_rent IS NOT NULL AND lc.monthly_rent > 0 THEN
            ROUND(((ma.recommended_rent - lc.monthly_rent) / lc.monthly_rent * 100), 2)
        ELSE 0
    END as rent_adjustment_pct,
    
    -- Recommendations
    CASE 
        WHEN u.unit_status = 'VACANT' THEN 'SET_MARKET_RENT'
        WHEN lc.monthly_rent IS NOT NULL AND ma.recommended_rent IS NOT NULL THEN
            CASE 
                WHEN ma.recommended_rent > lc.monthly_rent * 1.05 THEN 'INCREASE_RENT'
                WHEN ma.recommended_rent < lc.monthly_rent * 0.95 THEN 'DECREASE_RENT'
                ELSE 'MAINTAIN_RENT'
            END
        ELSE 'NEEDS_ANALYSIS'
    END as recommendation,
    
    -- Risk assessment
    CASE 
        WHEN u.unit_status = 'VACANT' THEN 'LOW'
        WHEN lc.monthly_rent IS NOT NULL AND ma.recommended_rent IS NOT NULL THEN
            CASE 
                WHEN ma.recommended_rent > lc.monthly_rent * 1.10 THEN 'HIGH'
                WHEN ma.recommended_rent > lc.monthly_rent * 1.05 THEN 'MEDIUM'
                ELSE 'LOW'
            END
        ELSE 'UNKNOWN'
    END as adjustment_risk,
    
    -- Timing
    CASE 
        WHEN u.unit_status = 'VACANT' THEN 'IMMEDIATE'
        WHEN lc.contract_end_date <= CURRENT_DATE + INTERVAL '3 months' THEN 'AT_RENEWAL'
        WHEN lc.contract_end_date <= CURRENT_DATE + INTERVAL '6 months' THEN 'PLAN_FOR_RENEWAL'
        ELSE 'FUTURE_CONSIDERATION'
    END as implementation_timing,
    
    -- Contract information
    lc.contract_end_date,
    lc.contract_start_date,
    
    -- Market analysis date
    ma.analysis_date as market_analysis_date
    
FROM bms.units u
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.lease_contracts lc ON u.unit_id = lc.unit_id AND lc.contract_status = 'ACTIVE'
LEFT JOIN LATERAL (
    SELECT *
    FROM bms.market_analysis ma_sub
    WHERE ma_sub.company_id = u.company_id
    AND (ma_sub.building_id = u.building_id OR ma_sub.building_id IS NULL)
    AND (ma_sub.unit_type = u.unit_type OR ma_sub.unit_type IS NULL)
    ORDER BY ma_sub.analysis_date DESC
    LIMIT 1
) ma ON true
WHERE u.unit_status IN ('OCCUPIED', 'VACANT');--
 6. Comments
COMMENT ON FUNCTION bms.calculate_optimal_rent(UUID, UUID, UUID, DECIMAL, DECIMAL) IS 'Calculate optimal rent - Determine recommended rent based on market analysis and competitive positioning';
COMMENT ON FUNCTION bms.analyze_rent_performance(UUID, UUID, INTEGER) IS 'Analyze rent performance - Compare current rents against market rates and identify optimization opportunities';
COMMENT ON FUNCTION bms.generate_pricing_strategy(UUID, UUID, DECIMAL, DECIMAL) IS 'Generate pricing strategy - Create pricing strategies based on occupancy targets and market conditions';

COMMENT ON VIEW bms.v_market_competitiveness IS 'Market competitiveness view - Building-level market position and competitive analysis';
COMMENT ON VIEW bms.v_rent_optimization_recommendations IS 'Rent optimization recommendations view - Unit-level rent optimization recommendations with risk assessment';

-- Script completion message
SELECT 'Market analysis and rent optimization functions created successfully.' as message;