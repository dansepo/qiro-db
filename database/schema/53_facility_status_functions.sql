-- =====================================================
-- Facility Status Management Functions
-- Phase 4.1.2: Facility Status Management Functions
-- =====================================================

-- 1. Record facility monitoring data function
CREATE OR REPLACE FUNCTION bms.record_facility_monitoring(
    p_company_id UUID,
    p_asset_id UUID,
    p_monitoring_type VARCHAR(30),
    p_operational_status VARCHAR(20),
    p_performance_rating DECIMAL(5,2) DEFAULT NULL,
    p_temperature_celsius DECIMAL(6,2) DEFAULT NULL,
    p_humidity_percentage DECIMAL(5,2) DEFAULT NULL,
    p_power_consumption_kw DECIMAL(10,3) DEFAULT NULL,
    p_operating_hours DECIMAL(10,2) DEFAULT NULL,
    p_observations TEXT DEFAULT NULL,
    p_monitored_by UUID DEFAULT NULL,
    p_data_source VARCHAR(50) DEFAULT 'MANUAL'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_monitoring_id UUID;
    v_asset RECORD;
    v_alert_needed BOOLEAN := false;
    v_alert_type VARCHAR(30);
    v_alert_severity VARCHAR(20);
    v_alert_description TEXT;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Insert monitoring record
    INSERT INTO bms.facility_status_monitoring (
        company_id,
        asset_id,
        monitoring_type,
        operational_status,
        performance_rating,
        temperature_celsius,
        humidity_percentage,
        power_consumption_kw,
        operating_hours,
        observations,
        monitored_by,
        data_source
    ) VALUES (
        p_company_id,
        p_asset_id,
        p_monitoring_type,
        p_operational_status,
        p_performance_rating,
        p_temperature_celsius,
        p_humidity_percentage,
        p_power_consumption_kw,
        p_operating_hours,
        p_observations,
        p_monitored_by,
        p_data_source
    ) RETURNING monitoring_id INTO v_monitoring_id;
    
    -- Check for alert conditions
    -- Performance degradation alert
    IF p_performance_rating IS NOT NULL AND p_performance_rating < 70 THEN
        v_alert_needed := true;
        v_alert_type := 'PERFORMANCE_DEGRADATION';
        v_alert_severity := CASE 
            WHEN p_performance_rating < 50 THEN 'CRITICAL'
            WHEN p_performance_rating < 60 THEN 'HIGH'
            ELSE 'MEDIUM'
        END;
        v_alert_description := 'Performance rating dropped to ' || p_performance_rating || '%';
    END IF;
    
    -- Temperature anomaly alert
    IF p_temperature_celsius IS NOT NULL AND (p_temperature_celsius > 80 OR p_temperature_celsius < -10) THEN
        v_alert_needed := true;
        v_alert_type := 'TEMPERATURE_ANOMALY';
        v_alert_severity := CASE 
            WHEN p_temperature_celsius > 100 OR p_temperature_celsius < -20 THEN 'CRITICAL'
            WHEN p_temperature_celsius > 90 OR p_temperature_celsius < -15 THEN 'HIGH'
            ELSE 'MEDIUM'
        END;
        v_alert_description := 'Temperature anomaly detected: ' || p_temperature_celsius || '°C';
    END IF;
    
    -- Equipment failure alert
    IF p_operational_status = 'FAULT' THEN
        v_alert_needed := true;
        v_alert_type := 'EQUIPMENT_FAILURE';
        v_alert_severity := 'HIGH';
        v_alert_description := 'Equipment failure detected';
    END IF;
    
    -- Create alert if needed
    IF v_alert_needed THEN
        PERFORM bms.create_facility_alert(
            p_company_id,
            p_asset_id,
            v_monitoring_id,
            v_alert_type,
            v_alert_severity,
            v_alert_description,
            p_monitored_by
        );
    END IF;
    
    -- Update asset status if needed
    IF p_operational_status != v_asset.asset_status THEN
        PERFORM bms.update_asset_status(
            p_asset_id,
            p_operational_status,
            NULL, -- condition not changed
            'MONITORING_UPDATE',
            'Status updated from monitoring data',
            0, -- no cost
            0, -- no downtime
            p_monitored_by
        );
    END IF;
    
    RETURN v_monitoring_id;
END;
$$;

-- 2. Create facility alert function
CREATE OR REPLACE FUNCTION bms.create_facility_alert(
    p_company_id UUID,
    p_asset_id UUID,
    p_monitoring_id UUID DEFAULT NULL,
    p_alert_type VARCHAR(30),
    p_alert_severity VARCHAR(20),
    p_alert_description TEXT,
    p_created_by UUID DEFAULT NULL,
    p_threshold_value DECIMAL(15,4) DEFAULT NULL,
    p_actual_value DECIMAL(15,4) DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_alert_id UUID;
    v_asset RECORD;
    v_alert_title VARCHAR(200);
    v_priority_level INTEGER;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Generate alert title
    v_alert_title := v_asset.asset_name || ' - ' || REPLACE(p_alert_type, '_', ' ');
    
    -- Determine priority level based on severity
    v_priority_level := CASE p_alert_severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END;
    
    -- Create alert
    INSERT INTO bms.facility_alerts (
        company_id,
        asset_id,
        monitoring_id,
        alert_type,
        alert_severity,
        alert_title,
        alert_description,
        threshold_value,
        actual_value,
        priority_level,
        created_by
    ) VALUES (
        p_company_id,
        p_asset_id,
        p_monitoring_id,
        p_alert_type,
        p_alert_severity,
        v_alert_title,
        p_alert_description,
        p_threshold_value,
        p_actual_value,
        v_priority_level,
        p_created_by
    ) RETURNING alert_id INTO v_alert_id;
    
    RETURN v_alert_id;
END;
$$;-- 
3. Calculate facility performance metrics function
CREATE OR REPLACE FUNCTION bms.calculate_facility_performance_metrics(
    p_asset_id UUID,
    p_metric_date DATE DEFAULT CURRENT_DATE,
    p_metric_period VARCHAR(20) DEFAULT 'DAILY'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_metric_id UUID;
    v_asset RECORD;
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_end_date TIMESTAMP WITH TIME ZONE;
    v_total_hours DECIMAL(8,2);
    v_runtime_hours DECIMAL(8,2) := 0;
    v_downtime_hours DECIMAL(8,2) := 0;
    v_maintenance_hours DECIMAL(8,2) := 0;
    v_failure_count INTEGER := 0;
    v_maintenance_cost DECIMAL(12,2) := 0;
    v_energy_consumed DECIMAL(12,3) := 0;
    v_availability_percentage DECIMAL(5,2);
    v_oee_percentage DECIMAL(5,2);
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Calculate period boundaries
    CASE p_metric_period
        WHEN 'DAILY' THEN
            v_start_date := p_metric_date::TIMESTAMP WITH TIME ZONE;
            v_end_date := v_start_date + INTERVAL '1 day';
            v_total_hours := 24;
        WHEN 'WEEKLY' THEN
            v_start_date := DATE_TRUNC('week', p_metric_date)::TIMESTAMP WITH TIME ZONE;
            v_end_date := v_start_date + INTERVAL '1 week';
            v_total_hours := 168;
        WHEN 'MONTHLY' THEN
            v_start_date := DATE_TRUNC('month', p_metric_date)::TIMESTAMP WITH TIME ZONE;
            v_end_date := v_start_date + INTERVAL '1 month';
            v_total_hours := EXTRACT(EPOCH FROM (v_end_date - v_start_date)) / 3600;
        ELSE
            v_start_date := p_metric_date::TIMESTAMP WITH TIME ZONE;
            v_end_date := v_start_date + INTERVAL '1 day';
            v_total_hours := 24;
    END CASE;
    
    -- Calculate runtime hours from monitoring data
    SELECT 
        COALESCE(SUM(CASE WHEN operational_status = 'RUNNING' THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN operational_status IN ('STOPPED', 'FAULT', 'OFFLINE') THEN 1 ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN operational_status = 'MAINTENANCE' THEN 1 ELSE 0 END), 0),
        COALESCE(AVG(power_consumption_kw), 0) * v_total_hours
    INTO v_runtime_hours, v_downtime_hours, v_maintenance_hours, v_energy_consumed
    FROM bms.facility_status_monitoring
    WHERE asset_id = p_asset_id
    AND monitoring_date >= v_start_date
    AND monitoring_date < v_end_date;
    
    -- Calculate failure count from status history
    SELECT COUNT(*) INTO v_failure_count
    FROM bms.asset_status_history
    WHERE asset_id = p_asset_id
    AND change_reason = 'FAILURE'
    AND change_date >= v_start_date
    AND change_date < v_end_date;
    
    -- Calculate maintenance cost from status history
    SELECT COALESCE(SUM(change_cost), 0) INTO v_maintenance_cost
    FROM bms.asset_status_history
    WHERE asset_id = p_asset_id
    AND change_reason IN ('MAINTENANCE', 'REPAIR')
    AND change_date >= v_start_date
    AND change_date < v_end_date;
    
    -- Calculate availability percentage
    v_availability_percentage := CASE 
        WHEN v_total_hours > 0 THEN ((v_total_hours - v_downtime_hours) / v_total_hours) * 100
        ELSE 100
    END;
    
    -- Calculate OEE (simplified calculation)
    v_oee_percentage := CASE 
        WHEN v_total_hours > 0 THEN 
            (v_availability_percentage / 100) * 
            (COALESCE(v_asset.efficiency_rating, 100) / 100) * 
            (100 / 100) * 100 -- Quality assumed to be 100%
        ELSE 0
    END;
    
    -- Insert or update performance metrics
    INSERT INTO bms.facility_performance_metrics (
        company_id,
        asset_id,
        metric_date,
        metric_period,
        total_runtime_hours,
        planned_downtime_hours,
        unplanned_downtime_hours,
        availability_percentage,
        energy_consumed_kwh,
        maintenance_hours,
        maintenance_cost,
        failure_count,
        oee_percentage
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        p_metric_date,
        p_metric_period,
        v_runtime_hours,
        v_maintenance_hours,
        v_downtime_hours - v_maintenance_hours,
        v_availability_percentage,
        v_energy_consumed,
        v_maintenance_hours,
        v_maintenance_cost,
        v_failure_count,
        v_oee_percentage
    ) 
    ON CONFLICT (asset_id, metric_date, metric_period)
    DO UPDATE SET
        total_runtime_hours = EXCLUDED.total_runtime_hours,
        planned_downtime_hours = EXCLUDED.planned_downtime_hours,
        unplanned_downtime_hours = EXCLUDED.unplanned_downtime_hours,
        availability_percentage = EXCLUDED.availability_percentage,
        energy_consumed_kwh = EXCLUDED.energy_consumed_kwh,
        maintenance_hours = EXCLUDED.maintenance_hours,
        maintenance_cost = EXCLUDED.maintenance_cost,
        failure_count = EXCLUDED.failure_count,
        oee_percentage = EXCLUDED.oee_percentage,
        updated_at = NOW()
    RETURNING metric_id INTO v_metric_id;
    
    RETURN v_metric_id;
END;
$$;

-- 4. Analyze facility condition trends function
CREATE OR REPLACE FUNCTION bms.analyze_facility_condition_trends(
    p_asset_id UUID,
    p_analysis_date DATE DEFAULT CURRENT_DATE,
    p_trend_period VARCHAR(20) DEFAULT 'MONTHLY'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_trend_id UUID;
    v_asset RECORD;
    v_lookback_months INTEGER;
    v_performance_trend VARCHAR(20) := 'STABLE';
    v_efficiency_trend VARCHAR(20) := 'STABLE';
    v_reliability_trend VARCHAR(20) := 'STABLE';
    v_overall_condition_trend VARCHAR(20) := 'STABLE';
    v_failure_probability DECIMAL(5,4) := 0;
    v_replacement_recommendation VARCHAR(20) := 'NOT_NEEDED';
    v_data_points_count INTEGER := 0;
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Determine lookback period
    v_lookback_months := CASE p_trend_period
        WHEN 'WEEKLY' THEN 3
        WHEN 'MONTHLY' THEN 12
        WHEN 'QUARTERLY' THEN 24
        ELSE 12
    END;
    
    -- Count available data points
    SELECT COUNT(*) INTO v_data_points_count
    FROM bms.facility_performance_metrics
    WHERE asset_id = p_asset_id
    AND metric_date >= p_analysis_date - (v_lookback_months || ' months')::INTERVAL;
    
    -- Analyze performance trend (simplified linear trend analysis)
    WITH performance_data AS (
        SELECT 
            metric_date,
            availability_percentage,
            ROW_NUMBER() OVER (ORDER BY metric_date) as rn
        FROM bms.facility_performance_metrics
        WHERE asset_id = p_asset_id
        AND metric_date >= p_analysis_date - (v_lookback_months || ' months')::INTERVAL
        ORDER BY metric_date
    ),
    trend_calc AS (
        SELECT 
            CASE 
                WHEN COUNT(*) >= 3 THEN
                    CASE 
                        WHEN (MAX(availability_percentage) - MIN(availability_percentage)) > 10 THEN 'VOLATILE'
                        WHEN AVG(CASE WHEN rn > COUNT(*)/2 THEN availability_percentage END) > 
                             AVG(CASE WHEN rn <= COUNT(*)/2 THEN availability_percentage END) THEN 'IMPROVING'
                        WHEN AVG(CASE WHEN rn > COUNT(*)/2 THEN availability_percentage END) < 
                             AVG(CASE WHEN rn <= COUNT(*)/2 THEN availability_percentage END) THEN 'DECLINING'
                        ELSE 'STABLE'
                    END
                ELSE 'STABLE'
            END as trend
        FROM performance_data
    )
    SELECT trend INTO v_performance_trend FROM trend_calc;
    
    -- Calculate failure probability based on age and condition
    v_failure_probability := LEAST(
        (EXTRACT(YEAR FROM AGE(p_analysis_date, v_asset.installation_date)) / v_asset.expected_lifespan_years) * 0.1 +
        CASE v_asset.condition_rating
            WHEN 'CRITICAL' THEN 0.8
            WHEN 'POOR' THEN 0.4
            WHEN 'FAIR' THEN 0.2
            WHEN 'GOOD' THEN 0.1
            ELSE 0.05
        END,
        1.0
    );
    
    -- Determine replacement recommendation
    v_replacement_recommendation := CASE 
        WHEN v_failure_probability > 0.8 THEN 'IMMEDIATE_REPLACEMENT'
        WHEN v_failure_probability > 0.6 THEN 'URGENT_REPLACEMENT'
        WHEN v_failure_probability > 0.4 THEN 'PLAN_REPLACEMENT'
        WHEN v_failure_probability > 0.2 THEN 'MONITOR'
        ELSE 'NOT_NEEDED'
    END;
    
    -- Insert trend analysis
    INSERT INTO bms.facility_condition_trends (
        company_id,
        asset_id,
        analysis_date,
        trend_period,
        data_points_count,
        performance_trend,
        efficiency_trend,
        reliability_trend,
        overall_condition_trend,
        failure_probability,
        replacement_recommendation,
        estimated_remaining_life_years,
        analysis_method
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        p_analysis_date,
        p_trend_period,
        v_data_points_count,
        v_performance_trend,
        v_efficiency_trend,
        v_reliability_trend,
        v_overall_condition_trend,
        v_failure_probability,
        v_replacement_recommendation,
        GREATEST(v_asset.expected_lifespan_years - EXTRACT(YEAR FROM AGE(p_analysis_date, v_asset.installation_date)), 0),
        'STATISTICAL_ANALYSIS'
    )
    ON CONFLICT (asset_id, analysis_date, trend_period)
    DO UPDATE SET
        data_points_count = EXCLUDED.data_points_count,
        performance_trend = EXCLUDED.performance_trend,
        efficiency_trend = EXCLUDED.efficiency_trend,
        reliability_trend = EXCLUDED.reliability_trend,
        overall_condition_trend = EXCLUDED.overall_condition_trend,
        failure_probability = EXCLUDED.failure_probability,
        replacement_recommendation = EXCLUDED.replacement_recommendation,
        estimated_remaining_life_years = EXCLUDED.estimated_remaining_life_years,
        updated_at = NOW()
    RETURNING trend_id INTO v_trend_id;
    
    RETURN v_trend_id;
END;
$$;-- 5. Fa
cility status dashboard view
CREATE OR REPLACE VIEW bms.v_facility_status_dashboard AS
SELECT 
    fa.company_id,
    
    -- Asset status counts
    COUNT(*) as total_monitored_assets,
    COUNT(*) FILTER (WHERE fsm.operational_status = 'RUNNING') as running_assets,
    COUNT(*) FILTER (WHERE fsm.operational_status = 'STOPPED') as stopped_assets,
    COUNT(*) FILTER (WHERE fsm.operational_status = 'MAINTENANCE') as maintenance_assets,
    COUNT(*) FILTER (WHERE fsm.operational_status = 'FAULT') as fault_assets,
    COUNT(*) FILTER (WHERE fsm.operational_status = 'OFFLINE') as offline_assets,
    
    -- Performance metrics
    AVG(fsm.performance_rating) as avg_performance_rating,
    AVG(fsm.efficiency_percentage) as avg_efficiency_percentage,
    AVG(fpm.availability_percentage) as avg_availability_percentage,
    AVG(fpm.oee_percentage) as avg_oee_percentage,
    
    -- Alert counts
    COUNT(fal.alert_id) FILTER (WHERE fal.alert_status = 'ACTIVE') as active_alerts,
    COUNT(fal.alert_id) FILTER (WHERE fal.alert_severity = 'CRITICAL') as critical_alerts,
    COUNT(fal.alert_id) FILTER (WHERE fal.alert_severity = 'HIGH') as high_alerts,
    COUNT(fal.alert_id) FILTER (WHERE fal.alert_severity = 'MEDIUM') as medium_alerts,
    
    -- Energy consumption
    SUM(fpm.energy_consumed_kwh) as total_energy_consumed_today,
    AVG(fsm.power_consumption_kw) as avg_power_consumption,
    
    -- Maintenance metrics
    SUM(fpm.maintenance_cost) as total_maintenance_cost_today,
    SUM(fpm.maintenance_hours) as total_maintenance_hours_today,
    SUM(fpm.failure_count) as total_failures_today,
    
    -- Condition trends
    COUNT(*) FILTER (WHERE fct.overall_condition_trend = 'IMPROVING') as improving_assets,
    COUNT(*) FILTER (WHERE fct.overall_condition_trend = 'DECLINING') as declining_assets,
    COUNT(*) FILTER (WHERE fct.replacement_recommendation IN ('URGENT_REPLACEMENT', 'IMMEDIATE_REPLACEMENT')) as replacement_needed,
    
    -- Recent activity
    COUNT(*) FILTER (WHERE DATE_TRUNC('day', fsm.monitoring_date) = CURRENT_DATE) as monitored_today,
    MAX(fsm.monitoring_date) as last_monitoring_time,
    MAX(fal.first_detected_at) as last_alert_time
    
FROM bms.facility_assets fa
LEFT JOIN LATERAL (
    SELECT *
    FROM bms.facility_status_monitoring fsm_inner
    WHERE fsm_inner.asset_id = fa.asset_id
    ORDER BY fsm_inner.monitoring_date DESC
    LIMIT 1
) fsm ON true
LEFT JOIN bms.facility_performance_metrics fpm ON fa.asset_id = fpm.asset_id 
    AND fpm.metric_date = CURRENT_DATE 
    AND fpm.metric_period = 'DAILY'
LEFT JOIN bms.facility_alerts fal ON fa.asset_id = fal.asset_id 
    AND fal.alert_status IN ('ACTIVE', 'ACKNOWLEDGED', 'IN_PROGRESS')
LEFT JOIN LATERAL (
    SELECT *
    FROM bms.facility_condition_trends fct_inner
    WHERE fct_inner.asset_id = fa.asset_id
    ORDER BY fct_inner.analysis_date DESC
    LIMIT 1
) fct ON true
WHERE fa.asset_status != 'DISPOSED'
GROUP BY fa.company_id;

-- 6. Facility monitoring details view
CREATE OR REPLACE VIEW bms.v_facility_monitoring_details AS
SELECT 
    fsm.monitoring_id,
    fsm.company_id,
    fsm.asset_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_type,
    
    -- Monitoring information
    fsm.monitoring_date,
    fsm.monitoring_type,
    fsm.monitoring_method,
    fsm.operational_status,
    
    -- Performance readings
    fsm.performance_rating,
    fsm.efficiency_percentage,
    fsm.operating_hours,
    fsm.load_percentage,
    
    -- Technical readings
    fsm.temperature_celsius,
    fsm.humidity_percentage,
    fsm.pressure_kpa,
    fsm.vibration_level,
    fsm.noise_level_db,
    fsm.power_consumption_kw,
    
    -- Condition indicators
    fsm.wear_level,
    fsm.lubrication_status,
    fsm.filter_condition,
    fsm.belt_tension,
    
    -- Alert status
    fsm.has_alarms,
    fsm.alarm_codes,
    fsm.warning_indicators,
    
    -- Environmental conditions
    fsm.ambient_temperature,
    fsm.ambient_humidity,
    fsm.air_quality_index,
    
    -- Data quality
    fsm.data_quality_score,
    fsm.reliability_index,
    fsm.data_source,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    fa.location_description,
    
    -- Status indicators
    CASE 
        WHEN fsm.operational_status = 'FAULT' THEN 'CRITICAL'
        WHEN fsm.performance_rating < 50 THEN 'CRITICAL'
        WHEN fsm.performance_rating < 70 THEN 'WARNING'
        WHEN fsm.has_alarms THEN 'WARNING'
        ELSE 'NORMAL'
    END as status_indicator,
    
    -- Time since monitoring
    EXTRACT(EPOCH FROM (NOW() - fsm.monitoring_date)) / 3600 as hours_since_monitoring,
    
    fsm.observations,
    fsm.recommendations,
    fsm.created_at
    
FROM bms.facility_status_monitoring fsm
JOIN bms.facility_assets fa ON fsm.asset_id = fa.asset_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
ORDER BY fsm.monitoring_date DESC;

-- 7. Active facility alerts view
CREATE OR REPLACE VIEW bms.v_active_facility_alerts AS
SELECT 
    fal.alert_id,
    fal.company_id,
    fal.asset_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_type,
    
    -- Alert information
    fal.alert_type,
    fal.alert_severity,
    fal.alert_status,
    fal.alert_title,
    fal.alert_description,
    
    -- Alert conditions
    fal.trigger_condition,
    fal.threshold_value,
    fal.actual_value,
    fal.measurement_unit,
    
    -- Timing
    fal.first_detected_at,
    fal.last_updated_at,
    fal.acknowledged_at,
    
    -- Priority and assignment
    fal.priority_level,
    fal.escalation_level,
    fal.assigned_to,
    fal.acknowledged_by,
    
    -- Impact
    fal.impact_level,
    fal.estimated_downtime_hours,
    fal.estimated_cost_impact,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    fa.location_description,
    
    -- Time calculations
    EXTRACT(EPOCH FROM (NOW() - fal.first_detected_at)) / 3600 as hours_since_detection,
    CASE 
        WHEN fal.acknowledged_at IS NOT NULL THEN 
            EXTRACT(EPOCH FROM (fal.acknowledged_at - fal.first_detected_at)) / 3600
        ELSE NULL
    END as hours_to_acknowledgment,
    
    -- Urgency indicator
    CASE 
        WHEN fal.alert_severity = 'CRITICAL' AND fal.alert_status = 'ACTIVE' THEN 'URGENT'
        WHEN fal.alert_severity = 'HIGH' AND 
             EXTRACT(EPOCH FROM (NOW() - fal.first_detected_at)) / 3600 > 4 THEN 'URGENT'
        WHEN EXTRACT(EPOCH FROM (NOW() - fal.first_detected_at)) / 3600 > 24 THEN 'OVERDUE'
        ELSE 'NORMAL'
    END as urgency_status,
    
    fal.created_at
    
FROM bms.facility_alerts fal
JOIN bms.facility_assets fa ON fal.asset_id = fa.asset_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
WHERE fal.alert_status IN ('ACTIVE', 'ACKNOWLEDGED', 'IN_PROGRESS')
ORDER BY fal.priority_level ASC, fal.first_detected_at ASC;

-- Script completion message
SELECT 'Facility status management functions and views created successfully.' as message;