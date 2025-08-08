-- =====================================================
-- Preventive Maintenance Management Functions
-- Phase 4.2.3: Preventive Maintenance Functions
-- =====================================================

-- 1. Start preventive maintenance execution function
CREATE OR REPLACE FUNCTION bms.start_preventive_maintenance_execution(
    p_company_id UUID,
    p_plan_id UUID,
    p_asset_id UUID,
    p_execution_date DATE DEFAULT CURRENT_DATE,
    p_lead_technician_id UUID DEFAULT NULL,
    p_execution_type VARCHAR(30) DEFAULT 'SCHEDULED',
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_execution_id UUID;
    v_execution_number VARCHAR(50);
    v_plan RECORD;
BEGIN
    -- Get maintenance plan information
    SELECT * INTO v_plan
    FROM bms.maintenance_plans
    WHERE plan_id = p_plan_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Maintenance plan not found: %', p_plan_id;
    END IF;
    
    -- Generate execution number
    v_execution_number := 'PM-' || TO_CHAR(p_execution_date, 'YYYYMMDD') || '-' || 
                         LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Create preventive maintenance execution
    INSERT INTO bms.preventive_maintenance_executions (
        company_id,
        plan_id,
        asset_id,
        execution_number,
        execution_type,
        execution_date,
        planned_start_time,
        execution_status,
        planned_duration_hours,
        planned_cost,
        lead_technician_id,
        created_by
    ) VALUES (
        p_company_id,
        p_plan_id,
        p_asset_id,
        v_execution_number,
        p_execution_type,
        p_execution_date,
        NOW(),
        'PLANNED',
        v_plan.estimated_duration_hours,
        v_plan.estimated_cost,
        p_lead_technician_id,
        p_created_by
    ) RETURNING execution_id INTO v_execution_id;
    
    -- Create task executions for all tasks in the plan
    INSERT INTO bms.maintenance_task_executions (
        company_id,
        execution_id,
        task_id,
        task_sequence,
        task_name,
        task_description,
        planned_duration_minutes
    )
    SELECT 
        p_company_id,
        v_execution_id,
        mt.task_id,
        mt.task_sequence,
        mt.task_name,
        mt.task_description,
        mt.estimated_duration_minutes
    FROM bms.maintenance_tasks mt
    WHERE mt.plan_id = p_plan_id
    AND mt.is_active = true
    ORDER BY mt.task_sequence;
    
    RETURN v_execution_id;
END;
$$;

-- 2. Complete preventive maintenance execution function
CREATE OR REPLACE FUNCTION bms.complete_preventive_maintenance_execution(
    p_execution_id UUID,
    p_asset_condition_after VARCHAR(20) DEFAULT NULL,
    p_work_quality_rating DECIMAL(3,1) DEFAULT NULL,
    p_actual_cost DECIMAL(12,2) DEFAULT NULL,
    p_technician_notes TEXT DEFAULT NULL,
    p_recommendations TEXT DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_execution RECORD;
    v_actual_duration_hours DECIMAL(8,2);
    v_task_completion_rate DECIMAL(5,2);
BEGIN
    -- Get execution information
    SELECT * INTO v_execution
    FROM bms.preventive_maintenance_executions
    WHERE execution_id = p_execution_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Preventive maintenance execution not found: %', p_execution_id;
    END IF;
    
    -- Calculate actual duration
    v_actual_duration_hours := EXTRACT(EPOCH FROM (NOW() - v_execution.actual_start_time)) / 3600;
    
    -- Calculate task completion rate
    SELECT 
        CASE 
            WHEN COUNT(*) > 0 THEN 
                (COUNT(*) FILTER (WHERE task_status = 'COMPLETED')::DECIMAL / COUNT(*)) * 100
            ELSE 100
        END
    INTO v_task_completion_rate
    FROM bms.maintenance_task_executions
    WHERE execution_id = p_execution_id;
    
    -- Update execution record
    UPDATE bms.preventive_maintenance_executions
    SET actual_end_time = NOW(),
        actual_duration_hours = v_actual_duration_hours,
        execution_status = 'COMPLETED',
        completion_percentage = v_task_completion_rate,
        asset_condition_after = COALESCE(p_asset_condition_after, asset_condition_after),
        work_quality_rating = COALESCE(p_work_quality_rating, work_quality_rating),
        actual_cost = COALESCE(p_actual_cost, actual_cost),
        technician_notes = COALESCE(p_technician_notes, technician_notes),
        recommendations = COALESCE(p_recommendations, recommendations),
        work_completed_by = p_completed_by,
        work_completion_date = NOW(),
        updated_at = NOW()
    WHERE execution_id = p_execution_id;
    
    -- Update asset last maintenance date
    UPDATE bms.facility_assets
    SET last_maintenance_date = v_execution.execution_date,
        updated_at = NOW()
    WHERE asset_id = v_execution.asset_id;
    
    RETURN true;
END;
$$;-
- 3. Complete maintenance task function
CREATE OR REPLACE FUNCTION bms.complete_maintenance_task(
    p_task_execution_id UUID,
    p_task_status VARCHAR(20) DEFAULT 'COMPLETED',
    p_measurements_taken JSONB DEFAULT NULL,
    p_issues_encountered TEXT DEFAULT NULL,
    p_technician_notes TEXT DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_task_execution RECORD;
    v_actual_duration_minutes INTEGER;
BEGIN
    -- Get task execution information
    SELECT * INTO v_task_execution
    FROM bms.maintenance_task_executions
    WHERE task_execution_id = p_task_execution_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Maintenance task execution not found: %', p_task_execution_id;
    END IF;
    
    -- Calculate actual duration
    IF v_task_execution.actual_start_time IS NOT NULL THEN
        v_actual_duration_minutes := EXTRACT(EPOCH FROM (NOW() - v_task_execution.actual_start_time)) / 60;
    ELSE
        v_actual_duration_minutes := v_task_execution.planned_duration_minutes;
    END IF;
    
    -- Update task execution
    UPDATE bms.maintenance_task_executions
    SET actual_end_time = NOW(),
        actual_duration_minutes = v_actual_duration_minutes,
        task_status = p_task_status,
        completion_percentage = CASE p_task_status
            WHEN 'COMPLETED' THEN 100
            WHEN 'FAILED' THEN 0
            WHEN 'SKIPPED' THEN 0
            ELSE completion_percentage
        END,
        measurements_taken = COALESCE(p_measurements_taken, measurements_taken),
        issues_encountered = COALESCE(p_issues_encountered, issues_encountered),
        technician_notes = COALESCE(p_technician_notes, technician_notes),
        completed_by = p_completed_by,
        completion_date = NOW(),
        updated_at = NOW()
    WHERE task_execution_id = p_task_execution_id;
    
    RETURN true;
END;
$$;

-- 4. Analyze maintenance effectiveness function
CREATE OR REPLACE FUNCTION bms.analyze_maintenance_effectiveness(
    p_asset_id UUID,
    p_analysis_date DATE DEFAULT CURRENT_DATE,
    p_analysis_period VARCHAR(20) DEFAULT 'MONTHLY'
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_analysis_id UUID;
    v_asset RECORD;
    v_period_start_date DATE;
    v_period_end_date DATE;
    v_maintenance_metrics RECORD;
    v_reliability_metrics RECORD;
    v_cost_metrics RECORD;
    v_effectiveness VARCHAR(20);
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Calculate period boundaries
    CASE p_analysis_period
        WHEN 'WEEKLY' THEN
            v_period_start_date := DATE_TRUNC('week', p_analysis_date)::DATE;
            v_period_end_date := v_period_start_date + INTERVAL '1 week' - INTERVAL '1 day';
        WHEN 'MONTHLY' THEN
            v_period_start_date := DATE_TRUNC('month', p_analysis_date)::DATE;
            v_period_end_date := v_period_start_date + INTERVAL '1 month' - INTERVAL '1 day';
        WHEN 'QUARTERLY' THEN
            v_period_start_date := DATE_TRUNC('quarter', p_analysis_date)::DATE;
            v_period_end_date := v_period_start_date + INTERVAL '3 months' - INTERVAL '1 day';
        WHEN 'ANNUAL' THEN
            v_period_start_date := DATE_TRUNC('year', p_analysis_date)::DATE;
            v_period_end_date := v_period_start_date + INTERVAL '1 year' - INTERVAL '1 day';
        ELSE
            v_period_start_date := DATE_TRUNC('month', p_analysis_date)::DATE;
            v_period_end_date := v_period_start_date + INTERVAL '1 month' - INTERVAL '1 day';
    END CASE;
    
    -- Calculate maintenance metrics
    SELECT 
        COUNT(*) as planned_count,
        COUNT(*) FILTER (WHERE execution_status = 'COMPLETED') as completed_count,
        COUNT(*) FILTER (WHERE execution_status = 'CANCELLED') as cancelled_count,
        SUM(planned_cost) as planned_cost,
        SUM(actual_cost) as actual_cost,
        AVG(work_quality_rating) FILTER (WHERE work_quality_rating > 0) as avg_quality
    INTO v_maintenance_metrics
    FROM bms.preventive_maintenance_executions
    WHERE asset_id = p_asset_id
    AND execution_date >= v_period_start_date
    AND execution_date <= v_period_end_date;
    
    -- Calculate reliability metrics from facility performance
    SELECT 
        COALESCE(SUM(unplanned_downtime_hours), 0) as unplanned_downtime,
        COALESCE(SUM(planned_downtime_hours), 0) as planned_downtime,
        COALESCE(AVG(availability_percentage), 100) as availability,
        COALESCE(SUM(failure_count), 0) as failures
    INTO v_reliability_metrics
    FROM bms.facility_performance_metrics
    WHERE asset_id = p_asset_id
    AND metric_date >= v_period_start_date
    AND metric_date <= v_period_end_date;
    
    -- Determine effectiveness rating
    v_effectiveness := CASE 
        WHEN v_maintenance_metrics.completed_count::DECIMAL / NULLIF(v_maintenance_metrics.planned_count, 0) >= 0.95 
             AND v_reliability_metrics.availability >= 95 
             AND v_reliability_metrics.failures <= 1 THEN 'HIGHLY_EFFECTIVE'
        WHEN v_maintenance_metrics.completed_count::DECIMAL / NULLIF(v_maintenance_metrics.planned_count, 0) >= 0.85 
             AND v_reliability_metrics.availability >= 90 THEN 'EFFECTIVE'
        WHEN v_maintenance_metrics.completed_count::DECIMAL / NULLIF(v_maintenance_metrics.planned_count, 0) >= 0.70 
             AND v_reliability_metrics.availability >= 80 THEN 'MODERATELY_EFFECTIVE'
        WHEN v_maintenance_metrics.completed_count::DECIMAL / NULLIF(v_maintenance_metrics.planned_count, 0) >= 0.50 THEN 'INEFFECTIVE'
        ELSE 'NEEDS_REVIEW'
    END;
    
    -- Insert analysis record
    INSERT INTO bms.maintenance_effectiveness_analysis (
        company_id,
        asset_id,
        analysis_date,
        analysis_period,
        period_start_date,
        period_end_date,
        planned_maintenance_count,
        completed_maintenance_count,
        cancelled_maintenance_count,
        failure_count,
        unplanned_downtime_hours,
        planned_downtime_hours,
        availability_percentage,
        planned_maintenance_cost,
        actual_maintenance_cost,
        maintenance_strategy_effectiveness,
        maintenance_quality_score,
        analyzed_by
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        p_analysis_date,
        p_analysis_period,
        v_period_start_date,
        v_period_end_date,
        COALESCE(v_maintenance_metrics.planned_count, 0),
        COALESCE(v_maintenance_metrics.completed_count, 0),
        COALESCE(v_maintenance_metrics.cancelled_count, 0),
        COALESCE(v_reliability_metrics.failures, 0),
        COALESCE(v_reliability_metrics.unplanned_downtime, 0),
        COALESCE(v_reliability_metrics.planned_downtime, 0),
        COALESCE(v_reliability_metrics.availability, 100),
        COALESCE(v_maintenance_metrics.planned_cost, 0),
        COALESCE(v_maintenance_metrics.actual_cost, 0),
        v_effectiveness,
        COALESCE(v_maintenance_metrics.avg_quality, 0),
        NULL -- analyzed_by will be set by calling function
    )
    ON CONFLICT (asset_id, analysis_date, analysis_period)
    DO UPDATE SET
        planned_maintenance_count = EXCLUDED.planned_maintenance_count,
        completed_maintenance_count = EXCLUDED.completed_maintenance_count,
        cancelled_maintenance_count = EXCLUDED.cancelled_maintenance_count,
        failure_count = EXCLUDED.failure_count,
        unplanned_downtime_hours = EXCLUDED.unplanned_downtime_hours,
        planned_downtime_hours = EXCLUDED.planned_downtime_hours,
        availability_percentage = EXCLUDED.availability_percentage,
        planned_maintenance_cost = EXCLUDED.planned_maintenance_cost,
        actual_maintenance_cost = EXCLUDED.actual_maintenance_cost,
        maintenance_strategy_effectiveness = EXCLUDED.maintenance_strategy_effectiveness,
        maintenance_quality_score = EXCLUDED.maintenance_quality_score,
        updated_at = NOW()
    RETURNING analysis_id INTO v_analysis_id;
    
    RETURN v_analysis_id;
END;
$$;-- 5. C
reate optimization recommendation function
CREATE OR REPLACE FUNCTION bms.create_optimization_recommendation(
    p_asset_id UUID,
    p_analysis_id UUID DEFAULT NULL,
    p_recommendation_type VARCHAR(30),
    p_recommendation_title VARCHAR(200),
    p_recommendation_description TEXT,
    p_priority_level VARCHAR(20),
    p_implementation_cost DECIMAL(12,2) DEFAULT 0,
    p_annual_savings_estimate DECIMAL(12,2) DEFAULT 0,
    p_recommended_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_recommendation_id UUID;
    v_asset RECORD;
    v_recommendation_category VARCHAR(30);
    v_impact_level VARCHAR(20);
    v_payback_period_months INTEGER;
    v_roi_estimate DECIMAL(8,4);
BEGIN
    -- Get asset information
    SELECT * INTO v_asset
    FROM bms.facility_assets
    WHERE asset_id = p_asset_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Facility asset not found: %', p_asset_id;
    END IF;
    
    -- Determine recommendation category based on type
    v_recommendation_category := CASE p_recommendation_type
        WHEN 'FREQUENCY_ADJUSTMENT' THEN 'COST_REDUCTION'
        WHEN 'STRATEGY_CHANGE' THEN 'RELIABILITY_IMPROVEMENT'
        WHEN 'RESOURCE_OPTIMIZATION' THEN 'EFFICIENCY_ENHANCEMENT'
        WHEN 'TECHNOLOGY_UPGRADE' THEN 'EFFICIENCY_ENHANCEMENT'
        WHEN 'PROCESS_IMPROVEMENT' THEN 'EFFICIENCY_ENHANCEMENT'
        WHEN 'TRAINING_NEED' THEN 'SAFETY_IMPROVEMENT'
        ELSE 'COST_REDUCTION'
    END;
    
    -- Determine impact level based on savings
    v_impact_level := CASE 
        WHEN p_annual_savings_estimate > 10000000 THEN 'HIGH'
        WHEN p_annual_savings_estimate > 5000000 THEN 'MEDIUM'
        WHEN p_annual_savings_estimate > 0 THEN 'LOW'
        ELSE 'MINIMAL'
    END;
    
    -- Calculate payback period and ROI
    IF p_implementation_cost > 0 AND p_annual_savings_estimate > 0 THEN
        v_payback_period_months := CEIL((p_implementation_cost / p_annual_savings_estimate) * 12);
        v_roi_estimate := (p_annual_savings_estimate / p_implementation_cost) * 100;
    ELSE
        v_payback_period_months := 0;
        v_roi_estimate := 0;
    END IF;
    
    -- Create optimization recommendation
    INSERT INTO bms.maintenance_optimization_recommendations (
        company_id,
        asset_id,
        analysis_id,
        recommendation_type,
        recommendation_category,
        recommendation_title,
        recommendation_description,
        priority_level,
        impact_level,
        implementation_cost,
        annual_savings_estimate,
        payback_period_months,
        roi_estimate,
        recommended_by
    ) VALUES (
        v_asset.company_id,
        p_asset_id,
        p_analysis_id,
        p_recommendation_type,
        v_recommendation_category,
        p_recommendation_title,
        p_recommendation_description,
        p_priority_level,
        v_impact_level,
        p_implementation_cost,
        p_annual_savings_estimate,
        v_payback_period_months,
        v_roi_estimate,
        p_recommended_by
    ) RETURNING recommendation_id INTO v_recommendation_id;
    
    RETURN v_recommendation_id;
END;
$$;

-- 6. Preventive maintenance dashboard view
CREATE OR REPLACE VIEW bms.v_preventive_maintenance_dashboard AS
SELECT 
    pme.company_id,
    
    -- Execution counts by status
    COUNT(*) as total_executions,
    COUNT(*) FILTER (WHERE pme.execution_status = 'PLANNED') as planned_executions,
    COUNT(*) FILTER (WHERE pme.execution_status = 'IN_PROGRESS') as in_progress_executions,
    COUNT(*) FILTER (WHERE pme.execution_status = 'COMPLETED') as completed_executions,
    COUNT(*) FILTER (WHERE pme.execution_status = 'CANCELLED') as cancelled_executions,
    
    -- Execution types
    COUNT(*) FILTER (WHERE pme.execution_type = 'SCHEDULED') as scheduled_executions,
    COUNT(*) FILTER (WHERE pme.execution_type = 'EMERGENCY') as emergency_executions,
    COUNT(*) FILTER (WHERE pme.execution_type = 'CONDITION_BASED') as condition_based_executions,
    
    -- Performance metrics
    AVG(pme.completion_percentage) as avg_completion_percentage,
    AVG(pme.work_quality_rating) FILTER (WHERE pme.work_quality_rating > 0) as avg_quality_rating,
    AVG(pme.actual_duration_hours) FILTER (WHERE pme.actual_duration_hours > 0) as avg_duration_hours,
    
    -- Cost analysis
    SUM(pme.planned_cost) as total_planned_cost,
    SUM(pme.actual_cost) as total_actual_cost,
    AVG(pme.actual_cost) FILTER (WHERE pme.actual_cost > 0) as avg_actual_cost,
    
    -- Downtime analysis
    SUM(pme.downtime_hours) as total_downtime_hours,
    AVG(pme.downtime_hours) as avg_downtime_hours,
    
    -- Task completion analysis
    COUNT(mte.task_execution_id) as total_tasks,
    COUNT(mte.task_execution_id) FILTER (WHERE mte.task_status = 'COMPLETED') as completed_tasks,
    COUNT(mte.task_execution_id) FILTER (WHERE mte.task_status = 'FAILED') as failed_tasks,
    
    -- Time analysis
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', pme.execution_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_executions,
    COUNT(*) FILTER (WHERE DATE_TRUNC('week', pme.execution_date) = DATE_TRUNC('week', CURRENT_DATE)) as this_week_executions,
    
    -- Latest activity
    MAX(pme.updated_at) as last_updated_at
    
FROM bms.preventive_maintenance_executions pme
LEFT JOIN bms.maintenance_task_executions mte ON pme.execution_id = mte.execution_id
GROUP BY pme.company_id;

-- 7. Maintenance effectiveness summary view
CREATE OR REPLACE VIEW bms.v_maintenance_effectiveness_summary AS
SELECT 
    mea.analysis_id,
    mea.company_id,
    mea.asset_id,
    fa.asset_code,
    fa.asset_name,
    fa.asset_type,
    
    -- Analysis information
    mea.analysis_date,
    mea.analysis_period,
    mea.maintenance_strategy_effectiveness,
    
    -- Performance metrics
    mea.availability_percentage,
    mea.planned_maintenance_count,
    mea.completed_maintenance_count,
    mea.failure_count,
    
    -- Cost metrics
    mea.planned_maintenance_cost,
    mea.actual_maintenance_cost,
    mea.actual_maintenance_cost - mea.planned_maintenance_cost as cost_variance,
    
    -- Quality metrics
    mea.maintenance_quality_score,
    mea.first_time_fix_rate,
    mea.rework_percentage,
    
    -- Trends
    mea.failure_trend,
    mea.cost_trend,
    mea.performance_trend,
    
    -- ROI analysis
    mea.roi_percentage,
    mea.maintenance_investment,
    mea.avoided_failure_cost,
    
    -- Location information
    b.name as building_name,
    u.unit_number,
    
    -- Effectiveness indicators
    CASE 
        WHEN mea.maintenance_strategy_effectiveness = 'NEEDS_REVIEW' THEN 'CRITICAL'
        WHEN mea.maintenance_strategy_effectiveness = 'INEFFECTIVE' THEN 'HIGH'
        WHEN mea.maintenance_strategy_effectiveness = 'MODERATELY_EFFECTIVE' THEN 'MEDIUM'
        ELSE 'LOW'
    END as attention_level,
    
    -- Recommendations count
    COUNT(mor.recommendation_id) as total_recommendations,
    COUNT(mor.recommendation_id) FILTER (WHERE mor.recommendation_status = 'APPROVED') as approved_recommendations,
    
    mea.created_at,
    mea.updated_at
    
FROM bms.maintenance_effectiveness_analysis mea
JOIN bms.facility_assets fa ON mea.asset_id = fa.asset_id
LEFT JOIN bms.buildings b ON fa.building_id = b.building_id
LEFT JOIN bms.units u ON fa.unit_id = u.unit_id
LEFT JOIN bms.maintenance_optimization_recommendations mor ON mea.analysis_id = mor.analysis_id
GROUP BY 
    mea.analysis_id, mea.company_id, mea.asset_id, fa.asset_code, fa.asset_name, fa.asset_type,
    mea.analysis_date, mea.analysis_period, mea.maintenance_strategy_effectiveness,
    mea.availability_percentage, mea.planned_maintenance_count, mea.completed_maintenance_count,
    mea.failure_count, mea.planned_maintenance_cost, mea.actual_maintenance_cost,
    mea.maintenance_quality_score, mea.first_time_fix_rate, mea.rework_percentage,
    mea.failure_trend, mea.cost_trend, mea.performance_trend, mea.roi_percentage,
    mea.maintenance_investment, mea.avoided_failure_cost, b.name, u.unit_number,
    mea.created_at, mea.updated_at
ORDER BY mea.analysis_date DESC;

-- Script completion message
SELECT 'Preventive maintenance management functions and views created successfully.' as message;