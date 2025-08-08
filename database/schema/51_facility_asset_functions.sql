-- =====================================================
-- Facility Asset Management Functions
-- Phase 4.1: Facility Asset Management Functions
-- =====================================================

-- 1. Create facility asset function
CREATE OR REPLACE FUNCTION bms.create_facility_asset(
    p_company_id UUID,
    p_category_id UUID,
    p_asset_name VARCHAR(200),
    p_asset_type VARCHAR(30),
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_manufacturer VARCHAR(100) DEFAULT NULL,
    p_model_number VARCHAR(100) DEFAULT NULL,
    p_serial_number VARCHAR(100) DEFAULT NULL,
    p_installation_date DATE DEFAULT CURRENT_DATE,
    p_installation_cost DECIMAL(15,2) DEFAULT 0,
    p_expected_lifespan_years INTEGER DEFAULT 10,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_asset_id UUID;
    v_asset_code VARCHAR(50);
    v_category_info RECORD;
    v_next_inspection_date DATE;
    v_next_maintenance_date DATE;
BEGIN
    -- Get category information
    SELECT * INTO v_category_info
    FROM bms.facility_categories
    WHERE category_id = p_category_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility category not found: %', p_category_id;
    END IF;
    
    -- Generate asset code
    v_asset_code := v_category_info.category_code || '-' || 
                   TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                   LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Calculate next inspection and maintenance dates
    v_next_inspection_date := p_installation_date + 
                             (v_category_info.default_inspection_cycle_months || ' months')::INTERVAL;
    v_next_maintenance_date := p_installation_date + 
                              (v_category_info.default_maintenance_cycle_months || ' months')::INTERVAL;
    
    -- Create facility asset
    INSERT INTO bms.facility_assets (
        company_id,
        building_id,
        unit_id,
        category_id,
        asset_code,
        asset_name,
        asset_type,
        manufacturer,
        model_number,
        serial_number,
        installation_date,
        installation_cost,
        expected_lifespan_years,
        next_inspection_date,
        next_maintenance_date,
        created_by
    ) VALUES (
        p_company_id,
        p_building_id,
        p_unit_id,
        p_category_id,
        v_asset_code,
        p_asset_name,
        p_asset_type,
        p_manufacturer,
        p_model_number,
        p_serial_number,
        p_installation_date,
        p_installation_cost,
        p_expected_lifespan_years,
        v_next_inspection_date,
        v_next_maintenance_date,
        p_created_by
    ) RETURNING asset_id INTO v_asset_id;
    
    -- Create initial status history
    INSERT INTO bms.asset_status_history (
        company_id,
        asset_id,
        change_reason,
        change_description,
        new_status,
        new_condition,
        change_cost,
        changed_by,
        created_by
    ) VALUES (
        p_company_id,
        v_asset_id,
        'INSTALLATION',
        'Asset installed and registered in system',
        'ACTIVE',
        'GOOD',
        p_installation_cost,
        p_created_by,
        p_created_by
    );
    
    RETURN v_asset_id;
END;
$$;

-- 2. Update asset status function
CREATE OR REPLACE FUNCTION bms.update_asset_status(
    p_asset_id UUID,
    p_new_status VARCHAR(20),
    p_new_condition VARCHAR(20) DEFAULT NULL,
    p_change_reason VARCHAR(50) DEFAULT 'OTHER',
    p_change_description TEXT DEFAULT NULL,
    p_change_cost DECIMAL(15,2) DEFAULT 0,
    p_downtime_hours DECIMAL(8,2) DEFAULT 0,
    p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_asset RECORD;
    v_old_status VARCHAR(20);
    v_old_condition VARCHAR(20);
BEGIN
    -- Get current asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    v_old_status := v_asset.asset_status;
    v_old_condition := v_asset.condition_rating;
    
    -- Update asset
    UPDATE bms.facility_assets
    SET asset_status = p_new_status,
        condition_rating = COALESCE(p_new_condition, condition_rating),
        total_maintenance_cost = total_maintenance_cost + p_change_cost,
        failure_count = CASE 
            WHEN p_change_reason = 'FAILURE' THEN failure_count + 1
            ELSE failure_count
        END,
        updated_at = NOW()
    WHERE asset_id = p_asset_id;
    
    -- Create status history record
    INSERT INTO bms.asset_status_history (
        company_id,
        asset_id,
        old_status,
        new_status,
        old_condition,
        new_condition,
        change_reason,
        change_description,
        change_cost,
        downtime_hours,
        changed_by,
        created_by
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        v_old_status,
        p_new_status,
        v_old_condition,
        COALESCE(p_new_condition, v_old_condition),
        p_change_reason,
        p_change_description,
        p_change_cost,
        p_downtime_hours,
        p_updated_by,
        p_updated_by
    );
    
    RETURN true;
END;
$$;-
- 3. Calculate asset depreciation function
CREATE OR REPLACE FUNCTION bms.calculate_asset_depreciation(
    p_asset_id UUID,
    p_depreciation_year INTEGER,
    p_depreciation_month INTEGER
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_asset RECORD;
    v_depreciation_id UUID;
    v_book_value_start DECIMAL(15,2);
    v_depreciation_amount DECIMAL(15,2);
    v_accumulated_depreciation DECIMAL(15,2);
    v_book_value_end DECIMAL(15,2);
    v_depreciation_rate DECIMAL(8,4);
    v_months_since_installation INTEGER;
    v_total_depreciation_months INTEGER;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Calculate months since installation
    v_months_since_installation := (p_depreciation_year - EXTRACT(YEAR FROM v_asset.installation_date)) * 12 +
                                  (p_depreciation_month - EXTRACT(MONTH FROM v_asset.installation_date));
    
    -- Calculate total depreciation months
    v_total_depreciation_months := v_asset.expected_lifespan_years * 12;
    
    -- Get previous month's book value or start with installation cost
    SELECT COALESCE(book_value_end, v_asset.installation_cost) INTO v_book_value_start
    FROM bms.asset_depreciation
    WHERE asset_id = p_asset_id
    AND ((depreciation_year = p_depreciation_year AND depreciation_month = p_depreciation_month - 1)
         OR (depreciation_year = p_depreciation_year - 1 AND depreciation_month = 12 AND p_depreciation_month = 1))
    ORDER BY depreciation_year DESC, depreciation_month DESC
    LIMIT 1;
    
    IF v_book_value_start IS NULL THEN
        v_book_value_start := v_asset.installation_cost;
    END IF;
    
    -- Calculate depreciation based on method
    CASE v_asset.depreciation_method
        WHEN 'STRAIGHT_LINE' THEN
            v_depreciation_rate := 1.0 / v_total_depreciation_months;
            v_depreciation_amount := (v_asset.installation_cost - v_asset.salvage_value) / v_total_depreciation_months;
        WHEN 'DECLINING_BALANCE' THEN
            v_depreciation_rate := 2.0 / v_total_depreciation_months;
            v_depreciation_amount := v_book_value_start * v_depreciation_rate;
        ELSE
            v_depreciation_rate := 1.0 / v_total_depreciation_months;
            v_depreciation_amount := (v_asset.installation_cost - v_asset.salvage_value) / v_total_depreciation_months;
    END CASE;
    
    -- Ensure depreciation doesn't go below salvage value
    IF v_book_value_start - v_depreciation_amount < v_asset.salvage_value THEN
        v_depreciation_amount := v_book_value_start - v_asset.salvage_value;
    END IF;
    
    -- Calculate accumulated depreciation
    SELECT COALESCE(SUM(depreciation_amount), 0) + v_depreciation_amount INTO v_accumulated_depreciation
    FROM bms.asset_depreciation
    WHERE asset_id = p_asset_id
    AND (depreciation_year < p_depreciation_year 
         OR (depreciation_year = p_depreciation_year AND depreciation_month < p_depreciation_month));
    
    -- Calculate ending book value
    v_book_value_end := v_book_value_start - v_depreciation_amount;
    
    -- Insert depreciation record
    INSERT INTO bms.asset_depreciation (
        company_id,
        asset_id,
        depreciation_year,
        depreciation_month,
        book_value_start,
        depreciation_amount,
        accumulated_depreciation,
        book_value_end,
        depreciation_rate,
        calculation_method,
        is_final_year
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        p_depreciation_year,
        p_depreciation_month,
        v_book_value_start,
        v_depreciation_amount,
        v_accumulated_depreciation,
        v_book_value_end,
        v_depreciation_rate,
        v_asset.depreciation_method,
        v_months_since_installation >= v_total_depreciation_months
    ) RETURNING depreciation_id INTO v_depreciation_id;
    
    RETURN v_depreciation_id;
END;
$$;

-- 4. Asset maintenance scheduling function
CREATE OR REPLACE FUNCTION bms.schedule_asset_maintenance(
    p_asset_id UUID,
    p_maintenance_type VARCHAR(30) DEFAULT 'PREVENTIVE',
    p_scheduled_date DATE DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_estimated_cost DECIMAL(15,2) DEFAULT 0,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_asset RECORD;
    v_schedule_id UUID;
    v_scheduled_date DATE;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Use provided date or next maintenance date
    v_scheduled_date := COALESCE(p_scheduled_date, v_asset.next_maintenance_date, CURRENT_DATE + INTERVAL '30 days');
    
    -- Create maintenance schedule (this would link to maintenance_schedules table when created)
    -- For now, we'll update the asset's next maintenance date
    UPDATE bms.facility_assets
    SET next_maintenance_date = v_scheduled_date + INTERVAL '1 year',
        updated_at = NOW()
    WHERE asset_id = p_asset_id;
    
    -- Return a placeholder UUID (in real implementation, this would return the schedule ID)
    RETURN gen_random_uuid();
END;
$$;

-- 5. Asset performance calculation function
CREATE OR REPLACE FUNCTION bms.calculate_asset_performance(
    p_asset_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
    v_asset RECORD;
    v_total_downtime DECIMAL(10,2);
    v_total_hours DECIMAL(10,2);
    v_uptime_percentage DECIMAL(5,2);
    v_mtbf DECIMAL(10,2); -- Mean Time Between Failures
    v_performance_data JSONB;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Calculate total downtime from status history
    SELECT COALESCE(SUM(downtime_hours), 0) INTO v_total_downtime
    FROM bms.asset_status_history
    WHERE asset_id = p_asset_id
    AND change_date >= p_calculation_date - INTERVAL '1 year';
    
    -- Calculate total hours in the period (assuming 24/7 operation)
    v_total_hours := EXTRACT(EPOCH FROM (p_calculation_date - (p_calculation_date - INTERVAL '1 year'))) / 3600;
    
    -- Calculate uptime percentage
    v_uptime_percentage := CASE 
        WHEN v_total_hours > 0 THEN ((v_total_hours - v_total_downtime) / v_total_hours) * 100
        ELSE 100
    END;
    
    -- Calculate MTBF (Mean Time Between Failures)
    v_mtbf := CASE 
        WHEN v_asset.failure_count > 0 THEN v_total_hours / v_asset.failure_count
        ELSE v_total_hours
    END;
    
    -- Update asset performance metrics
    UPDATE bms.facility_assets
    SET uptime_percentage = v_uptime_percentage,
        updated_at = NOW()
    WHERE asset_id = p_asset_id;
    
    -- Build performance data JSON
    v_performance_data := jsonb_build_object(
        'asset_id', p_asset_id,
        'calculation_date', p_calculation_date,
        'uptime_percentage', v_uptime_percentage,
        'total_downtime_hours', v_total_downtime,
        'total_hours', v_total_hours,
        'failure_count', v_asset.failure_count,
        'mtbf_hours', v_mtbf,
        'total_maintenance_cost', v_asset.total_maintenance_cost,
        'age_years', EXTRACT(YEAR FROM AGE(p_calculation_date, v_asset.installation_date))
    );
    
    RETURN v_performance_data;
END;
$$;-- 6. Asse
t dashboard view
CREATE OR REPLACE VIEW bms.v_facility_asset_dashboard AS
SELECT 
    fa.company_id,
    
    -- Asset counts by status
    COUNT(*) as total_assets,
    COUNT(*) FILTER (WHERE fa.asset_status = 'ACTIVE') as active_assets,
    COUNT(*) FILTER (WHERE fa.asset_status = 'INACTIVE') as inactive_assets,
    COUNT(*) FILTER (WHERE fa.asset_status = 'MAINTENANCE') as maintenance_assets,
    COUNT(*) FILTER (WHERE fa.asset_status = 'REPAIR') as repair_assets,
    COUNT(*) FILTER (WHERE fa.asset_status = 'RETIRED') as retired_assets,
    
    -- Asset counts by condition
    COUNT(*) FILTER (WHERE fa.condition_rating = 'EXCELLENT') as excellent_condition,
    COUNT(*) FILTER (WHERE fa.condition_rating = 'GOOD') as good_condition,
    COUNT(*) FILTER (WHERE fa.condition_rating = 'FAIR') as fair_condition,
    COUNT(*) FILTER (WHERE fa.condition_rating = 'POOR') as poor_condition,
    COUNT(*) FILTER (WHERE fa.condition_rating = 'CRITICAL') as critical_condition,
    
    -- Asset counts by type
    COUNT(*) FILTER (WHERE fa.asset_type = 'HVAC') as hvac_assets,
    COUNT(*) FILTER (WHERE fa.asset_type = 'ELECTRICAL') as electrical_assets,
    COUNT(*) FILTER (WHERE fa.asset_type = 'PLUMBING') as plumbing_assets,
    COUNT(*) FILTER (WHERE fa.asset_type = 'ELEVATOR') as elevator_assets,
    COUNT(*) FILTER (WHERE fa.asset_type = 'FIRE_SAFETY') as fire_safety_assets,
    COUNT(*) FILTER (WHERE fa.asset_type = 'SECURITY') as security_assets,
    
    -- Maintenance and inspection due
    COUNT(*) FILTER (WHERE fa.next_maintenance_date <= CURRENT_DATE + INTERVAL '30 days') as maintenance_due_soon,
    COUNT(*) FILTER (WHERE fa.next_maintenance_date < CURRENT_DATE) as maintenance_overdue,
    COUNT(*) FILTER (WHERE fa.next_inspection_date <= CURRENT_DATE + INTERVAL '30 days') as inspection_due_soon,
    COUNT(*) FILTER (WHERE fa.next_inspection_date < CURRENT_DATE) as inspection_overdue,
    
    -- Financial metrics
    SUM(fa.installation_cost) as total_installation_cost,
    SUM(fa.replacement_cost) as total_replacement_cost,
    SUM(fa.total_maintenance_cost) as total_maintenance_cost,
    AVG(fa.installation_cost) as avg_installation_cost,
    
    -- Performance metrics
    AVG(fa.uptime_percentage) as avg_uptime_percentage,
    AVG(fa.efficiency_rating) as avg_efficiency_rating,
    SUM(fa.failure_count) as total_failures,
    
    -- Age analysis
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date))) as avg_age_years,
    COUNT(*) FILTER (WHERE EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date)) > fa.expected_lifespan_years) as assets_beyond_lifespan,
    
    -- Recent activity
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', fa.created_at) = DATE_TRUNC('month', CURRENT_DATE)) as assets_added_this_month,
    
    -- Latest updates
    MAX(fa.updated_at) as last_updated_at
    
FROM bms.facility_assets fa
WHERE fa.asset_status != 'DISPOSED'
GROUP BY fa.company_id;

-- 7. Asset details view
CREATE OR REPLACE VIEW bms.v_facility_asset_details AS
SELECT 
    fa.asset_id,
    fa.company_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_description,
    fa.asset_type,
    fa.asset_status,
    fa.condition_rating,
    
    -- Category information
    fc.category_name,
    fc.category_code,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    fa.location_description,
    fa.floor_level,
    fa.room_number,
    
    -- Technical specifications
    fa.manufacturer,
    fa.model_number,
    fa.serial_number,
    fa.capacity_rating,
    fa.power_consumption,
    
    -- Installation and lifecycle
    fa.installation_date,
    fa.installation_cost,
    fa.expected_lifespan_years,
    fa.depreciation_method,
    fa.salvage_value,
    fa.replacement_cost,
    
    -- Warranty information
    fa.warranty_start_date,
    fa.warranty_end_date,
    CASE 
        WHEN fa.warranty_end_date >= CURRENT_DATE THEN 'ACTIVE'
        WHEN fa.warranty_end_date < CURRENT_DATE THEN 'EXPIRED'
        ELSE 'NO_WARRANTY'
    END as warranty_status,
    
    -- Maintenance and inspection
    fa.last_inspection_date,
    fa.next_inspection_date,
    fa.last_maintenance_date,
    fa.next_maintenance_date,
    
    -- Performance metrics
    fa.uptime_percentage,
    fa.efficiency_rating,
    fa.failure_count,
    fa.total_maintenance_cost,
    
    -- Age and depreciation
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date)) as age_years,
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date)) > fa.expected_lifespan_years THEN 'BEYOND_LIFESPAN'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date)) > fa.expected_lifespan_years * 0.8 THEN 'NEAR_END_OF_LIFE'
        ELSE 'NORMAL'
    END as lifecycle_status,
    
    -- Current book value (latest depreciation record)
    COALESCE(ad.book_value_end, fa.installation_cost) as current_book_value,
    
    -- Status indicators
    CASE 
        WHEN fa.next_maintenance_date < CURRENT_DATE THEN 'MAINTENANCE_OVERDUE'
        WHEN fa.next_maintenance_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'MAINTENANCE_DUE_SOON'
        WHEN fa.next_inspection_date < CURRENT_DATE THEN 'INSPECTION_OVERDUE'
        WHEN fa.next_inspection_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'INSPECTION_DUE_SOON'
        WHEN fa.condition_rating = 'CRITICAL' THEN 'CRITICAL_CONDITION'
        WHEN fa.condition_rating = 'POOR' THEN 'POOR_CONDITION'
        ELSE 'NORMAL'
    END as alert_status,
    
    -- Responsible parties
    fa.assigned_technician_id,
    fa.maintenance_contractor_id,
    
    fa.created_at,
    fa.updated_at
    
FROM bms.facility_assets fa
JOIN bms.facility_categories fc ON fa.category_id = fc.category_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
LEFT JOIN LATERAL (
    SELECT book_value_end
    FROM bms.asset_depreciation ad_inner
    WHERE ad_inner.asset_id = fa.asset_id
    ORDER BY depreciation_year DESC, depreciation_month DESC
    LIMIT 1
) ad ON true;

-- 8. Asset status history view
CREATE OR REPLACE VIEW bms.v_asset_status_history AS
SELECT 
    ash.history_id,
    ash.company_id,
    ash.asset_id,
    fa.asset_code,
    fa.asset_name,
    
    -- Status change information
    ash.change_date,
    ash.old_status,
    ash.new_status,
    ash.old_condition,
    ash.new_condition,
    ash.change_reason,
    ash.change_description,
    
    -- Impact information
    ash.change_cost,
    ash.downtime_hours,
    ash.impact_description,
    
    -- Responsible parties
    ash.changed_by,
    ash.approved_by,
    
    -- Time since change
    EXTRACT(EPOCH FROM (NOW() - ash.change_date)) / 3600 as hours_since_change,
    
    ash.created_at
    
FROM bms.asset_status_history ash
JOIN bms.facility_assets fa ON ash.asset_id = fa.asset_id
ORDER BY ash.change_date DESC;

-- Script completion message
SELECT 'Facility asset management functions and views created successfully.' as message;