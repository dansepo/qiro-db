-- =====================================================
-- Facility Status Monitoring System Tables
-- Phase 4.1.2: Facility Status Management
-- =====================================================

-- 1. Facility status monitoring table
CREATE TABLE IF NOT EXISTS bms.facility_status_monitoring (
    monitoring_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Monitoring information
    monitoring_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    monitoring_type VARCHAR(30) NOT NULL,
    monitoring_method VARCHAR(20) NOT NULL,
    
    -- Status readings
    operational_status VARCHAR(20) NOT NULL,
    performance_rating DECIMAL(5,2) DEFAULT 100.00,
    efficiency_percentage DECIMAL(5,2) DEFAULT 100.00,
    
    -- Technical readings
    temperature_celsius DECIMAL(6,2),
    humidity_percentage DECIMAL(5,2),
    pressure_kpa DECIMAL(8,2),
    vibration_level DECIMAL(8,4),
    noise_level_db DECIMAL(6,2),
    power_consumption_kw DECIMAL(10,3),
    
    -- Operating parameters
    operating_hours DECIMAL(10,2) DEFAULT 0,
    load_percentage DECIMAL(5,2) DEFAULT 0,
    cycle_count INTEGER DEFAULT 0,
    
    -- Condition indicators
    wear_level VARCHAR(20) DEFAULT 'NORMAL',
    lubrication_status VARCHAR(20) DEFAULT 'ADEQUATE',
    filter_condition VARCHAR(20) DEFAULT 'CLEAN',
    belt_tension VARCHAR(20) DEFAULT 'PROPER',
    
    -- Alert and alarm status
    has_alarms BOOLEAN DEFAULT false,
    alarm_codes JSONB,
    warning_indicators JSONB,
    
    -- Environmental conditions
    ambient_temperature DECIMAL(6,2),
    ambient_humidity DECIMAL(5,2),
    air_quality_index INTEGER,
    
    -- Monitoring source
    monitored_by UUID,
    monitoring_device VARCHAR(100),
    data_source VARCHAR(50) DEFAULT 'MANUAL',
    
    -- Quality indicators
    data_quality_score DECIMAL(3,1) DEFAULT 10.0,
    reliability_index DECIMAL(5,2) DEFAULT 100.00,
    
    -- Notes and observations
    observations TEXT,
    recommendations TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT fk_facility_monitoring_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_monitoring_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_monitoring_type CHECK (monitoring_type IN (
        'ROUTINE_INSPECTION', 'PERFORMANCE_CHECK', 'CONDITION_ASSESSMENT',
        'PREVENTIVE_MAINTENANCE', 'DIAGNOSTIC_TEST', 'CALIBRATION',
        'SAFETY_INSPECTION', 'ENVIRONMENTAL_MONITORING', 'IOT_SENSOR', 'OTHER'
    )),
    CONSTRAINT chk_monitoring_method CHECK (monitoring_method IN (
        'VISUAL', 'MANUAL_MEASUREMENT', 'AUTOMATED_SENSOR', 'DIAGNOSTIC_TOOL',
        'THERMAL_IMAGING', 'VIBRATION_ANALYSIS', 'OIL_ANALYSIS', 'OTHER'
    )),
    CONSTRAINT chk_operational_status CHECK (operational_status IN (
        'RUNNING', 'STOPPED', 'STANDBY', 'MAINTENANCE', 'FAULT', 'OFFLINE'
    )),
    CONSTRAINT chk_wear_level CHECK (wear_level IN (
        'MINIMAL', 'NORMAL', 'MODERATE', 'HIGH', 'EXCESSIVE'
    )),
    CONSTRAINT chk_lubrication_status CHECK (lubrication_status IN (
        'EXCELLENT', 'ADEQUATE', 'LOW', 'CONTAMINATED', 'MISSING'
    )),
    CONSTRAINT chk_filter_condition CHECK (filter_condition IN (
        'CLEAN', 'SLIGHTLY_DIRTY', 'DIRTY', 'VERY_DIRTY', 'BLOCKED'
    )),
    CONSTRAINT chk_belt_tension CHECK (belt_tension IN (
        'PROPER', 'LOOSE', 'TIGHT', 'DAMAGED', 'MISSING'
    )),
    CONSTRAINT chk_data_source CHECK (data_source IN (
        'MANUAL', 'IOT_SENSOR', 'BMS_SYSTEM', 'SCADA', 'MOBILE_APP', 'API'
    )),
    CONSTRAINT chk_percentages CHECK (
        performance_rating >= 0 AND performance_rating <= 100 AND
        efficiency_percentage >= 0 AND efficiency_percentage <= 100 AND
        load_percentage >= 0 AND load_percentage <= 100 AND
        reliability_index >= 0 AND reliability_index <= 100
    ),
    CONSTRAINT chk_data_quality CHECK (
        data_quality_score >= 0 AND data_quality_score <= 10
    )
);

-- 2. Facility performance metrics table
CREATE TABLE IF NOT EXISTS bms.facility_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Metric period
    metric_date DATE NOT NULL,
    metric_period VARCHAR(20) NOT NULL DEFAULT 'DAILY',
    
    -- Availability metrics
    total_runtime_hours DECIMAL(8,2) DEFAULT 0,
    planned_downtime_hours DECIMAL(8,2) DEFAULT 0,
    unplanned_downtime_hours DECIMAL(8,2) DEFAULT 0,
    availability_percentage DECIMAL(5,2) DEFAULT 100.00,
    
    -- Performance metrics
    actual_output DECIMAL(15,3) DEFAULT 0,
    rated_output DECIMAL(15,3) DEFAULT 0,
    performance_ratio DECIMAL(5,2) DEFAULT 100.00,
    efficiency_rating DECIMAL(5,2) DEFAULT 100.00,
    
    -- Quality metrics
    quality_index DECIMAL(5,2) DEFAULT 100.00,
    defect_rate DECIMAL(8,4) DEFAULT 0,
    rework_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Energy consumption
    energy_consumed_kwh DECIMAL(12,3) DEFAULT 0,
    energy_efficiency_ratio DECIMAL(8,4) DEFAULT 0,
    power_factor DECIMAL(4,3) DEFAULT 1.000,
    
    -- Maintenance metrics
    maintenance_hours DECIMAL(8,2) DEFAULT 0,
    maintenance_cost DECIMAL(12,2) DEFAULT 0,
    parts_replaced_count INTEGER DEFAULT 0,
    
    -- Failure metrics
    failure_count INTEGER DEFAULT 0,
    mtbf_hours DECIMAL(10,2) DEFAULT 0, -- Mean Time Between Failures
    mttr_hours DECIMAL(8,2) DEFAULT 0,  -- Mean Time To Repair
    
    -- Cost metrics
    operating_cost DECIMAL(12,2) DEFAULT 0,
    energy_cost DECIMAL(12,2) DEFAULT 0,
    maintenance_cost_total DECIMAL(12,2) DEFAULT 0,
    
    -- Environmental impact
    carbon_footprint_kg DECIMAL(10,3) DEFAULT 0,
    water_consumption_liters DECIMAL(12,2) DEFAULT 0,
    waste_generated_kg DECIMAL(10,3) DEFAULT 0,
    
    -- Overall Equipment Effectiveness (OEE)
    oee_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Calculation metadata
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calculated_by UUID,
    calculation_method VARCHAR(50),
    data_sources JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_performance_metrics_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_performance_metrics_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT uk_performance_metrics_period UNIQUE (asset_id, metric_date, metric_period),
    
    -- Check constraints
    CONSTRAINT chk_metric_period CHECK (metric_period IN (
        'HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUAL'
    )),
    CONSTRAINT chk_performance_percentages CHECK (
        availability_percentage >= 0 AND availability_percentage <= 100 AND
        performance_ratio >= 0 AND performance_ratio <= 200 AND
        efficiency_rating >= 0 AND efficiency_rating <= 100 AND
        quality_index >= 0 AND quality_index <= 100 AND
        oee_percentage >= 0 AND oee_percentage <= 100
    ),
    CONSTRAINT chk_time_values CHECK (
        total_runtime_hours >= 0 AND planned_downtime_hours >= 0 AND
        unplanned_downtime_hours >= 0 AND maintenance_hours >= 0 AND
        mtbf_hours >= 0 AND mttr_hours >= 0
    ),
    CONSTRAINT chk_cost_values CHECK (
        maintenance_cost >= 0 AND operating_cost >= 0 AND
        energy_cost >= 0 AND maintenance_cost_total >= 0
    )
);-- 3. Fac
ility alerts and notifications table
CREATE TABLE IF NOT EXISTS bms.facility_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    monitoring_id UUID,
    
    -- Alert information
    alert_type VARCHAR(30) NOT NULL,
    alert_severity VARCHAR(20) NOT NULL,
    alert_status VARCHAR(20) DEFAULT 'ACTIVE',
    alert_title VARCHAR(200) NOT NULL,
    alert_description TEXT,
    
    -- Alert conditions
    trigger_condition VARCHAR(100),
    threshold_value DECIMAL(15,4),
    actual_value DECIMAL(15,4),
    measurement_unit VARCHAR(20),
    
    -- Timing information
    first_detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    
    -- Priority and escalation
    priority_level INTEGER DEFAULT 3, -- 1=Critical, 2=High, 3=Medium, 4=Low, 5=Info
    escalation_level INTEGER DEFAULT 1,
    auto_escalate_after_hours INTEGER DEFAULT 24,
    
    -- Response information
    acknowledged_by UUID,
    assigned_to UUID,
    resolved_by UUID,
    resolution_notes TEXT,
    
    -- Impact assessment
    impact_level VARCHAR(20) DEFAULT 'MEDIUM',
    affected_systems JSONB,
    estimated_downtime_hours DECIMAL(8,2) DEFAULT 0,
    estimated_cost_impact DECIMAL(12,2) DEFAULT 0,
    
    -- Notification tracking
    notifications_sent JSONB,
    last_notification_at TIMESTAMP WITH TIME ZONE,
    notification_count INTEGER DEFAULT 0,
    
    -- Root cause analysis
    root_cause VARCHAR(100),
    corrective_actions TEXT,
    preventive_measures TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT fk_facility_alerts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_alerts_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_alerts_monitoring FOREIGN KEY (monitoring_id) REFERENCES bms.facility_status_monitoring(monitoring_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_alert_type CHECK (alert_type IN (
        'PERFORMANCE_DEGRADATION', 'TEMPERATURE_ANOMALY', 'VIBRATION_ALERT',
        'PRESSURE_ALERT', 'ENERGY_CONSUMPTION', 'MAINTENANCE_DUE',
        'INSPECTION_OVERDUE', 'SAFETY_VIOLATION', 'EQUIPMENT_FAILURE',
        'ENVIRONMENTAL_ALERT', 'SECURITY_BREACH', 'OTHER'
    )),
    CONSTRAINT chk_alert_severity CHECK (alert_severity IN (
        'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO'
    )),
    CONSTRAINT chk_alert_status CHECK (alert_status IN (
        'ACTIVE', 'ACKNOWLEDGED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'SUPPRESSED'
    )),
    CONSTRAINT chk_impact_level CHECK (impact_level IN (
        'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'MINIMAL'
    )),
    CONSTRAINT chk_priority_level CHECK (priority_level >= 1 AND priority_level <= 5),
    CONSTRAINT chk_escalation_level CHECK (escalation_level >= 1 AND escalation_level <= 5)
);

-- 4. Facility condition trends table
CREATE TABLE IF NOT EXISTS bms.facility_condition_trends (
    trend_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Trend analysis period
    analysis_date DATE NOT NULL,
    trend_period VARCHAR(20) NOT NULL,
    data_points_count INTEGER DEFAULT 0,
    
    -- Performance trends
    performance_trend VARCHAR(20) DEFAULT 'STABLE',
    performance_change_rate DECIMAL(8,4) DEFAULT 0,
    performance_variance DECIMAL(8,4) DEFAULT 0,
    
    -- Efficiency trends
    efficiency_trend VARCHAR(20) DEFAULT 'STABLE',
    efficiency_change_rate DECIMAL(8,4) DEFAULT 0,
    efficiency_variance DECIMAL(8,4) DEFAULT 0,
    
    -- Reliability trends
    reliability_trend VARCHAR(20) DEFAULT 'STABLE',
    failure_rate_trend DECIMAL(8,6) DEFAULT 0,
    mtbf_trend DECIMAL(8,4) DEFAULT 0,
    
    -- Energy consumption trends
    energy_trend VARCHAR(20) DEFAULT 'STABLE',
    energy_change_rate DECIMAL(8,4) DEFAULT 0,
    energy_efficiency_trend DECIMAL(8,4) DEFAULT 0,
    
    -- Maintenance trends
    maintenance_frequency_trend VARCHAR(20) DEFAULT 'STABLE',
    maintenance_cost_trend VARCHAR(20) DEFAULT 'STABLE',
    maintenance_duration_trend VARCHAR(20) DEFAULT 'STABLE',
    
    -- Condition deterioration
    overall_condition_trend VARCHAR(20) DEFAULT 'STABLE',
    deterioration_rate DECIMAL(8,6) DEFAULT 0,
    estimated_remaining_life_years DECIMAL(6,2),
    
    -- Predictive indicators
    failure_probability DECIMAL(5,4) DEFAULT 0,
    maintenance_urgency_score DECIMAL(5,2) DEFAULT 0,
    replacement_recommendation VARCHAR(20) DEFAULT 'NOT_NEEDED',
    
    -- Statistical measures
    trend_confidence_level DECIMAL(5,2) DEFAULT 0,
    correlation_coefficient DECIMAL(6,4) DEFAULT 0,
    r_squared DECIMAL(6,4) DEFAULT 0,
    
    -- Analysis metadata
    analysis_method VARCHAR(50),
    algorithm_version VARCHAR(20),
    analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    analyzed_by UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_condition_trends_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_condition_trends_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT uk_condition_trends_period UNIQUE (asset_id, analysis_date, trend_period),
    
    -- Check constraints
    CONSTRAINT chk_trend_period CHECK (trend_period IN (
        'WEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    CONSTRAINT chk_trend_direction CHECK (
        performance_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        efficiency_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        reliability_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        energy_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        maintenance_frequency_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        maintenance_cost_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        maintenance_duration_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE') AND
        overall_condition_trend IN ('IMPROVING', 'STABLE', 'DECLINING', 'VOLATILE')
    ),
    CONSTRAINT chk_replacement_recommendation CHECK (replacement_recommendation IN (
        'NOT_NEEDED', 'MONITOR', 'PLAN_REPLACEMENT', 'URGENT_REPLACEMENT', 'IMMEDIATE_REPLACEMENT'
    )),
    CONSTRAINT chk_probability_values CHECK (
        failure_probability >= 0 AND failure_probability <= 1 AND
        trend_confidence_level >= 0 AND trend_confidence_level <= 100
    )
);-- 5. RLS 
policies and indexes
ALTER TABLE bms.facility_status_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.facility_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.facility_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.facility_condition_trends ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY facility_monitoring_isolation_policy ON bms.facility_status_monitoring
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY performance_metrics_isolation_policy ON bms.facility_performance_metrics
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY facility_alerts_isolation_policy ON bms.facility_alerts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY condition_trends_isolation_policy ON bms.facility_condition_trends
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for facility_status_monitoring
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_company_id ON bms.facility_status_monitoring(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_asset_id ON bms.facility_status_monitoring(asset_id);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_date ON bms.facility_status_monitoring(monitoring_date);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_type ON bms.facility_status_monitoring(monitoring_type);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_status ON bms.facility_status_monitoring(operational_status);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_source ON bms.facility_status_monitoring(data_source);
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_alarms ON bms.facility_status_monitoring(has_alarms);

-- Performance indexes for facility_performance_metrics
CREATE INDEX IF NOT EXISTS idx_performance_metrics_company_id ON bms.facility_performance_metrics(company_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_asset_id ON bms.facility_performance_metrics(asset_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_date ON bms.facility_performance_metrics(metric_date);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_period ON bms.facility_performance_metrics(metric_period);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_availability ON bms.facility_performance_metrics(availability_percentage);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_oee ON bms.facility_performance_metrics(oee_percentage);

-- Performance indexes for facility_alerts
CREATE INDEX IF NOT EXISTS idx_facility_alerts_company_id ON bms.facility_alerts(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_asset_id ON bms.facility_alerts(asset_id);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_type ON bms.facility_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_severity ON bms.facility_alerts(alert_severity);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_status ON bms.facility_alerts(alert_status);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_priority ON bms.facility_alerts(priority_level);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_detected ON bms.facility_alerts(first_detected_at);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_assigned ON bms.facility_alerts(assigned_to);

-- Performance indexes for facility_condition_trends
CREATE INDEX IF NOT EXISTS idx_condition_trends_company_id ON bms.facility_condition_trends(company_id);
CREATE INDEX IF NOT EXISTS idx_condition_trends_asset_id ON bms.facility_condition_trends(asset_id);
CREATE INDEX IF NOT EXISTS idx_condition_trends_date ON bms.facility_condition_trends(analysis_date);
CREATE INDEX IF NOT EXISTS idx_condition_trends_period ON bms.facility_condition_trends(trend_period);
CREATE INDEX IF NOT EXISTS idx_condition_trends_overall ON bms.facility_condition_trends(overall_condition_trend);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_facility_monitoring_asset_date ON bms.facility_status_monitoring(asset_id, monitoring_date);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_asset_period ON bms.facility_performance_metrics(asset_id, metric_date, metric_period);
CREATE INDEX IF NOT EXISTS idx_facility_alerts_status_priority ON bms.facility_alerts(alert_status, priority_level);
CREATE INDEX IF NOT EXISTS idx_condition_trends_asset_analysis ON bms.facility_condition_trends(asset_id, analysis_date);

-- Updated_at triggers
CREATE TRIGGER facility_performance_metrics_updated_at_trigger
    BEFORE UPDATE ON bms.facility_performance_metrics
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER facility_alerts_updated_at_trigger
    BEFORE UPDATE ON bms.facility_alerts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER facility_condition_trends_updated_at_trigger
    BEFORE UPDATE ON bms.facility_condition_trends
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.facility_status_monitoring IS 'Facility status monitoring - Real-time and periodic monitoring data for facility assets';
COMMENT ON TABLE bms.facility_performance_metrics IS 'Facility performance metrics - Calculated performance indicators and KPIs';
COMMENT ON TABLE bms.facility_alerts IS 'Facility alerts - Alert and notification management for facility issues';
COMMENT ON TABLE bms.facility_condition_trends IS 'Facility condition trends - Trend analysis and predictive maintenance indicators';

-- Script completion message
SELECT 'Facility status monitoring system tables created successfully.' as message;