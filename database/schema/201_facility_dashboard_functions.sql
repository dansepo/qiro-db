-- =====================================================
-- 시설 관리 대시보드 및 보고서 시스템 함수
-- Phase 10: Dashboard and Reporting System Functions
-- =====================================================

-- 1. 월별 시설 관리 보고서 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_monthly_facility_report(
    p_company_id UUID,
    p_report_month DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_report_id UUID;
    v_template_id UUID;
    v_report_data JSONB;
    v_file_name VARCHAR(255);
BEGIN
    -- 월별 보고서 템플릿 조회
    SELECT template_id INTO v_template_id
    FROM bms.report_templates
    WHERE company_id = p_company_id
      AND template_type = 'FACILITY_STATUS'
      AND report_frequency = 'MONTHLY'
      AND is_active = true
    LIMIT 1;
    
    -- 템플릿이 없으면 기본 템플릿 생성
    IF v_template_id IS NULL THEN
        INSERT INTO bms.report_templates (
            company_id, template_name, template_type, description,
            report_format, report_frequency, auto_generate,
            data_sources, layout_configuration
        ) VALUES (
            p_company_id,
            '월별 시설 관리 현황 보고서',
            'FACILITY_STATUS',
            '월별 시설 관리 현황 및 통계 보고서',
            'PDF',
            'MONTHLY',
            true,
            '{"sources": ["facility_assets", "fault_reports", "work_orders", "maintenance_schedules", "cost_tracking"]}'::jsonb,
            '{"sections": ["overview", "fault_statistics", "work_orders", "maintenance", "cost_analysis"]}'::jsonb
        ) RETURNING template_id INTO v_template_id;
    END IF;
    
    -- 보고서 데이터 수집
    SELECT jsonb_build_object(
        'report_period', p_report_month,
        'company_info', jsonb_build_object(
            'company_id', c.company_id,
            'company_name', c.company_name
        ),
        'facility_overview', jsonb_build_object(
            'total_assets', COUNT(DISTINCT fa.asset_id),
            'active_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END),
            'maintenance_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'MAINTENANCE' THEN fa.asset_id END),
            'out_of_order_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'OUT_OF_ORDER' THEN fa.asset_id END)
        ),
        'fault_statistics', jsonb_build_object(
            'total_reports', COUNT(DISTINCT fr.report_id),
            'emergency_reports', COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' THEN fr.report_id END),
            'high_priority_reports', COUNT(DISTINCT CASE WHEN fr.fault_priority = 'HIGH' THEN fr.report_id END),
            'resolved_reports', COUNT(DISTINCT CASE WHEN fr.report_status = 'COMPLETED' THEN fr.report_id END),
            'avg_resolution_time_hours', COALESCE(AVG(EXTRACT(EPOCH FROM (fr.actual_completion_date - fr.reported_date))/3600), 0)
        ),
        'work_order_statistics', jsonb_build_object(
            'total_work_orders', COUNT(DISTINCT wo.work_order_id),
            'preventive_work_orders', COUNT(DISTINCT CASE WHEN wo.work_category = 'PREVENTIVE' THEN wo.work_order_id END),
            'corrective_work_orders', COUNT(DISTINCT CASE WHEN wo.work_category = 'CORRECTIVE' THEN wo.work_order_id END),
            'emergency_work_orders', COUNT(DISTINCT CASE WHEN wo.work_category = 'EMERGENCY' THEN wo.work_order_id END),
            'completed_work_orders', COUNT(DISTINCT CASE WHEN wo.work_status = 'COMPLETED' THEN wo.work_order_id END)
        ),
        'cost_analysis', jsonb_build_object(
            'total_cost', COALESCE(SUM(ct.amount), 0),
            'labor_cost', COALESCE(SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount END), 0),
            'material_cost', COALESCE(SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount END), 0),
            'contractor_cost', COALESCE(SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount END), 0),
            'avg_cost_per_work_order', COALESCE(AVG(ct.amount), 0)
        ),
        'maintenance_statistics', jsonb_build_object(
            'total_schedules', COUNT(DISTINCT ms.schedule_id),
            'completed_maintenance', COUNT(DISTINCT CASE WHEN ms.last_performed_date >= p_report_month 
                AND ms.last_performed_date < p_report_month + INTERVAL '1 month' THEN ms.schedule_id END),
            'overdue_maintenance', COUNT(DISTINCT CASE WHEN ms.next_due_date < p_report_month + INTERVAL '1 month' 
                AND ms.last_performed_date < p_report_month THEN ms.schedule_id END)
        ),
        'performance_metrics', jsonb_build_object(
            'avg_uptime_percentage', COALESCE(AVG(fa.uptime_percentage), 0),
            'avg_efficiency_rating', COALESCE(AVG(fa.efficiency_rating), 0),
            'total_failures', COALESCE(SUM(fa.failure_count), 0),
            'high_performance_assets', COUNT(CASE WHEN fa.uptime_percentage >= 95 THEN 1 END),
            'low_performance_assets', COUNT(CASE WHEN fa.uptime_percentage < 80 THEN 1 END)
        )
    ) INTO v_report_data
    FROM bms.companies c
    LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
    LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
        AND fr.reported_date >= p_report_month
        AND fr.reported_date < p_report_month + INTERVAL '1 month'
    LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
        AND wo.created_at >= p_report_month
        AND wo.created_at < p_report_month + INTERVAL '1 month'
    LEFT JOIN bms.cost_tracking ct ON c.company_id = ct.company_id 
        AND ct.cost_date >= p_report_month
        AND ct.cost_date < p_report_month + INTERVAL '1 month'
    LEFT JOIN bms.maintenance_schedules ms ON c.company_id = ms.company_id
    WHERE c.company_id = p_company_id
    GROUP BY c.company_id, c.company_name;
    
    -- 파일명 생성
    v_file_name := 'monthly_facility_report_' || TO_CHAR(p_report_month, 'YYYY_MM') || '_' || 
                   REPLACE(p_company_id::text, '-', '') || '.pdf';
    
    -- 보고서 레코드 생성
    INSERT INTO bms.generated_reports (
        company_id,
        template_id,
        report_name,
        report_type,
        report_period_start,
        report_period_end,
        generation_type,
        file_name,
        file_format,
        summary_data,
        key_metrics,
        report_status
    ) VALUES (
        p_company_id,
        v_template_id,
        '월별 시설 관리 현황 보고서 - ' || TO_CHAR(p_report_month, 'YYYY년 MM월'),
        'FACILITY_STATUS',
        p_report_month,
        p_report_month + INTERVAL '1 month' - INTERVAL '1 day',
        'AUTO',
        v_file_name,
        'PDF',
        v_report_data,
        (v_report_data->'cost_analysis') || (v_report_data->'performance_metrics'),
        'GENERATED'
    ) RETURNING report_id INTO v_report_id;
    
    RETURN v_report_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '월별 보고서 생성 중 오류 발생: %', SQLERRM;
END;
$$;

-- 2. 비용 분석 보고서 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_cost_analysis_report(
    p_company_id UUID,
    p_start_date DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month'),
    p_end_date DATE DEFAULT DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 day'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_report_id UUID;
    v_template_id UUID;
    v_report_data JSONB;
    v_file_name VARCHAR(255);
    v_cost_breakdown JSONB;
    v_trend_analysis JSONB;
BEGIN
    -- 비용 분석 보고서 템플릿 조회
    SELECT template_id INTO v_template_id
    FROM bms.report_templates
    WHERE company_id = p_company_id
      AND template_type = 'COST_ANALYSIS'
      AND is_active = true
    LIMIT 1;
    
    -- 템플릿이 없으면 기본 템플릿 생성
    IF v_template_id IS NULL THEN
        INSERT INTO bms.report_templates (
            company_id, template_name, template_type, description,
            report_format, report_frequency, auto_generate,
            data_sources, layout_configuration
        ) VALUES (
            p_company_id,
            '비용 분석 보고서',
            'COST_ANALYSIS',
            '시설 관리 비용 분석 및 통계 보고서',
            'PDF',
            'MONTHLY',
            false,
            '{"sources": ["cost_tracking", "work_orders", "facility_assets"]}'::jsonb,
            '{"sections": ["cost_summary", "cost_breakdown", "trend_analysis", "recommendations"]}'::jsonb
        ) RETURNING template_id INTO v_template_id;
    END IF;
    
    -- 비용 분석 데이터 수집
    WITH cost_summary AS (
        SELECT 
            SUM(ct.amount) as total_cost,
            COUNT(DISTINCT ct.work_order_id) as total_work_orders,
            AVG(ct.amount) as avg_cost_per_work_order,
            MAX(ct.amount) as highest_cost,
            MIN(ct.amount) as lowest_cost
        FROM bms.cost_tracking ct
        WHERE ct.company_id = p_company_id
          AND ct.cost_date >= p_start_date
          AND ct.cost_date <= p_end_date
    ),
    cost_by_type AS (
        SELECT 
            ct.cost_type,
            SUM(ct.amount) as total_amount,
            COUNT(*) as count,
            AVG(ct.amount) as avg_amount
        FROM bms.cost_tracking ct
        WHERE ct.company_id = p_company_id
          AND ct.cost_date >= p_start_date
          AND ct.cost_date <= p_end_date
        GROUP BY ct.cost_type
    ),
    cost_by_category AS (
        SELECT 
            wo.work_category,
            SUM(ct.amount) as total_amount,
            COUNT(DISTINCT wo.work_order_id) as work_order_count,
            AVG(ct.amount) as avg_cost_per_order
        FROM bms.cost_tracking ct
        JOIN bms.work_orders wo ON ct.work_order_id = wo.work_order_id
        WHERE ct.company_id = p_company_id
          AND ct.cost_date >= p_start_date
          AND ct.cost_date <= p_end_date
        GROUP BY wo.work_category
    ),
    cost_by_asset_type AS (
        SELECT 
            fa.asset_type,
            SUM(ct.amount) as total_amount,
            COUNT(DISTINCT fa.asset_id) as asset_count,
            AVG(ct.amount) as avg_cost_per_asset
        FROM bms.cost_tracking ct
        JOIN bms.work_orders wo ON ct.work_order_id = wo.work_order_id
        JOIN bms.facility_assets fa ON wo.asset_id = fa.asset_id
        WHERE ct.company_id = p_company_id
          AND ct.cost_date >= p_start_date
          AND ct.cost_date <= p_end_date
        GROUP BY fa.asset_type
    )
    SELECT jsonb_build_object(
        'report_period', jsonb_build_object(
            'start_date', p_start_date,
            'end_date', p_end_date
        ),
        'cost_summary', to_jsonb(cs.*),
        'cost_by_type', jsonb_agg(DISTINCT to_jsonb(cbt.*)),
        'cost_by_category', jsonb_agg(DISTINCT to_jsonb(cbc.*)),
        'cost_by_asset_type', jsonb_agg(DISTINCT to_jsonb(cbat.*))
    ) INTO v_report_data
    FROM cost_summary cs
    CROSS JOIN cost_by_type cbt
    CROSS JOIN cost_by_category cbc
    CROSS JOIN cost_by_asset_type cbat;
    
    -- 파일명 생성
    v_file_name := 'cost_analysis_report_' || TO_CHAR(p_start_date, 'YYYY_MM_DD') || '_to_' || 
                   TO_CHAR(p_end_date, 'YYYY_MM_DD') || '_' || REPLACE(p_company_id::text, '-', '') || '.pdf';
    
    -- 보고서 레코드 생성
    INSERT INTO bms.generated_reports (
        company_id,
        template_id,
        report_name,
        report_type,
        report_period_start,
        report_period_end,
        generation_type,
        file_name,
        file_format,
        summary_data,
        key_metrics,
        report_status
    ) VALUES (
        p_company_id,
        v_template_id,
        '비용 분석 보고서 - ' || TO_CHAR(p_start_date, 'YYYY.MM.DD') || ' ~ ' || TO_CHAR(p_end_date, 'YYYY.MM.DD'),
        'COST_ANALYSIS',
        p_start_date,
        p_end_date,
        'MANUAL',
        v_file_name,
        'PDF',
        v_report_data,
        v_report_data->'cost_summary',
        'GENERATED'
    ) RETURNING report_id INTO v_report_id;
    
    RETURN v_report_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '비용 분석 보고서 생성 중 오류 발생: %', SQLERRM;
END;
$$;

-- 3. 시설물 성능 보고서 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_performance_report(
    p_company_id UUID,
    p_asset_type VARCHAR(30) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_report_id UUID;
    v_template_id UUID;
    v_report_data JSONB;
    v_file_name VARCHAR(255);
    v_asset_filter TEXT;
BEGIN
    -- 성능 보고서 템플릿 조회
    SELECT template_id INTO v_template_id
    FROM bms.report_templates
    WHERE company_id = p_company_id
      AND template_type = 'PERFORMANCE_REPORT'
      AND is_active = true
    LIMIT 1;
    
    -- 템플릿이 없으면 기본 템플릿 생성
    IF v_template_id IS NULL THEN
        INSERT INTO bms.report_templates (
            company_id, template_name, template_type, description,
            report_format, report_frequency, auto_generate,
            data_sources, layout_configuration
        ) VALUES (
            p_company_id,
            '시설물 성능 분석 보고서',
            'PERFORMANCE_REPORT',
            '시설물 성능 지표 및 분석 보고서',
            'PDF',
            'QUARTERLY',
            false,
            '{"sources": ["facility_assets", "fault_reports", "maintenance_schedules"]}'::jsonb,
            '{"sections": ["performance_overview", "uptime_analysis", "efficiency_metrics", "failure_analysis"]}'::jsonb
        ) RETURNING template_id INTO v_template_id;
    END IF;
    
    -- 성능 분석 데이터 수집
    SELECT jsonb_build_object(
        'report_date', CURRENT_DATE,
        'asset_filter', COALESCE(p_asset_type, 'ALL'),
        'performance_overview', jsonb_build_object(
            'total_assets', COUNT(fa.asset_id),
            'avg_uptime_percentage', COALESCE(AVG(fa.uptime_percentage), 0),
            'avg_efficiency_rating', COALESCE(AVG(fa.efficiency_rating), 0),
            'total_failures', COALESCE(SUM(fa.failure_count), 0),
            'avg_maintenance_cost', COALESCE(AVG(fa.total_maintenance_cost), 0)
        ),
        'uptime_analysis', jsonb_build_object(
            'excellent_uptime_count', COUNT(CASE WHEN fa.uptime_percentage >= 98 THEN 1 END),
            'good_uptime_count', COUNT(CASE WHEN fa.uptime_percentage >= 95 AND fa.uptime_percentage < 98 THEN 1 END),
            'fair_uptime_count', COUNT(CASE WHEN fa.uptime_percentage >= 90 AND fa.uptime_percentage < 95 THEN 1 END),
            'poor_uptime_count', COUNT(CASE WHEN fa.uptime_percentage < 90 THEN 1 END),
            'highest_uptime', COALESCE(MAX(fa.uptime_percentage), 0),
            'lowest_uptime', COALESCE(MIN(fa.uptime_percentage), 0)
        ),
        'efficiency_metrics', jsonb_build_object(
            'high_efficiency_count', COUNT(CASE WHEN fa.efficiency_rating >= 90 THEN 1 END),
            'medium_efficiency_count', COUNT(CASE WHEN fa.efficiency_rating >= 70 AND fa.efficiency_rating < 90 THEN 1 END),
            'low_efficiency_count', COUNT(CASE WHEN fa.efficiency_rating < 70 THEN 1 END),
            'avg_efficiency_by_type', (
                SELECT jsonb_object_agg(
                    asset_type, 
                    ROUND(AVG(efficiency_rating)::numeric, 2)
                )
                FROM bms.facility_assets
                WHERE company_id = p_company_id
                  AND (p_asset_type IS NULL OR asset_type = p_asset_type)
                GROUP BY asset_type
            )
        ),
        'failure_analysis', jsonb_build_object(
            'total_failures', COALESCE(SUM(fa.failure_count), 0),
            'avg_failures_per_asset', COALESCE(AVG(fa.failure_count), 0),
            'assets_with_no_failures', COUNT(CASE WHEN fa.failure_count = 0 THEN 1 END),
            'high_failure_assets', COUNT(CASE WHEN fa.failure_count > 5 THEN 1 END),
            'failure_by_type', (
                SELECT jsonb_object_agg(
                    asset_type, 
                    SUM(failure_count)
                )
                FROM bms.facility_assets
                WHERE company_id = p_company_id
                  AND (p_asset_type IS NULL OR asset_type = p_asset_type)
                GROUP BY asset_type
            )
        ),
        'condition_analysis', jsonb_build_object(
            'excellent_condition', COUNT(CASE WHEN fa.condition_rating = 'EXCELLENT' THEN 1 END),
            'good_condition', COUNT(CASE WHEN fa.condition_rating = 'GOOD' THEN 1 END),
            'fair_condition', COUNT(CASE WHEN fa.condition_rating = 'FAIR' THEN 1 END),
            'poor_condition', COUNT(CASE WHEN fa.condition_rating = 'POOR' THEN 1 END)
        ),
        'maintenance_correlation', jsonb_build_object(
            'avg_cost_vs_uptime', CORR(fa.total_maintenance_cost, fa.uptime_percentage),
            'avg_cost_vs_failures', CORR(fa.total_maintenance_cost, fa.failure_count),
            'uptime_vs_efficiency', CORR(fa.uptime_percentage, fa.efficiency_rating)
        )
    ) INTO v_report_data
    FROM bms.facility_assets fa
    WHERE fa.company_id = p_company_id
      AND (p_asset_type IS NULL OR fa.asset_type = p_asset_type)
      AND fa.asset_status != 'DECOMMISSIONED';
    
    -- 파일명 생성
    v_asset_filter := COALESCE(p_asset_type, 'ALL');
    v_file_name := 'performance_report_' || v_asset_filter || '_' || 
                   TO_CHAR(CURRENT_DATE, 'YYYY_MM_DD') || '_' || 
                   REPLACE(p_company_id::text, '-', '') || '.pdf';
    
    -- 보고서 레코드 생성
    INSERT INTO bms.generated_reports (
        company_id,
        template_id,
        report_name,
        report_type,
        report_period_start,
        report_period_end,
        generation_type,
        file_name,
        file_format,
        summary_data,
        key_metrics,
        report_status
    ) VALUES (
        p_company_id,
        v_template_id,
        '시설물 성능 분석 보고서' || CASE WHEN p_asset_type IS NOT NULL THEN ' - ' || p_asset_type ELSE '' END,
        'PERFORMANCE_REPORT',
        CURRENT_DATE - INTERVAL '3 months',
        CURRENT_DATE,
        'MANUAL',
        v_file_name,
        'PDF',
        v_report_data,
        v_report_data->'performance_overview',
        'GENERATED'
    ) RETURNING report_id INTO v_report_id;
    
    RETURN v_report_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '성능 분석 보고서 생성 중 오류 발생: %', SQLERRM;
END;
$$;

-- 4. 대시보드 데이터 새로고침 함수
CREATE OR REPLACE FUNCTION bms.refresh_dashboard_data(
    p_company_id UUID,
    p_dashboard_type VARCHAR(30) DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_dashboard_data JSONB;
    v_facility_overview JSONB;
    v_maintenance_status JSONB;
    v_cost_analysis JSONB;
    v_alerts JSONB;
BEGIN
    -- 시설 현황 데이터
    SELECT jsonb_build_object(
        'total_assets', COUNT(DISTINCT fa.asset_id),
        'active_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END),
        'maintenance_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'MAINTENANCE' THEN fa.asset_id END),
        'out_of_order_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'OUT_OF_ORDER' THEN fa.asset_id END),
        'avg_uptime_percentage', COALESCE(AVG(fa.uptime_percentage), 0),
        'avg_efficiency_rating', COALESCE(AVG(fa.efficiency_rating), 0),
        'assets_by_condition', jsonb_build_object(
            'excellent', COUNT(CASE WHEN fa.condition_rating = 'EXCELLENT' THEN 1 END),
            'good', COUNT(CASE WHEN fa.condition_rating = 'GOOD' THEN 1 END),
            'fair', COUNT(CASE WHEN fa.condition_rating = 'FAIR' THEN 1 END),
            'poor', COUNT(CASE WHEN fa.condition_rating = 'POOR' THEN 1 END)
        ),
        'assets_by_type', (
            SELECT jsonb_object_agg(asset_type, asset_count)
            FROM (
                SELECT asset_type, COUNT(*) as asset_count
                FROM bms.facility_assets
                WHERE company_id = p_company_id
                GROUP BY asset_type
            ) t
        )
    ) INTO v_facility_overview
    FROM bms.facility_assets fa
    WHERE fa.company_id = p_company_id;
    
    -- 유지보수 현황 데이터
    SELECT jsonb_build_object(
        'total_schedules', COUNT(ms.schedule_id),
        'due_maintenance', COUNT(CASE WHEN ms.next_due_date <= CURRENT_DATE THEN 1 END),
        'upcoming_maintenance', COUNT(CASE WHEN ms.next_due_date <= CURRENT_DATE + INTERVAL '7 days' THEN 1 END),
        'overdue_maintenance', COUNT(CASE WHEN ms.next_due_date < CURRENT_DATE THEN 1 END),
        'completed_this_month', COUNT(CASE WHEN ms.last_performed_date >= DATE_TRUNC('month', CURRENT_DATE) THEN 1 END),
        'maintenance_by_type', (
            SELECT jsonb_object_agg(maintenance_type, maintenance_count)
            FROM (
                SELECT maintenance_type, COUNT(*) as maintenance_count
                FROM bms.maintenance_schedules
                WHERE company_id = p_company_id
                GROUP BY maintenance_type
            ) t
        )
    ) INTO v_maintenance_status
    FROM bms.maintenance_schedules ms
    WHERE ms.company_id = p_company_id;
    
    -- 비용 분석 데이터 (이번 달)
    SELECT jsonb_build_object(
        'monthly_cost', COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN ct.amount END), 0),
        'yearly_cost', COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('year', CURRENT_DATE) THEN ct.amount END), 0),
        'cost_by_type', jsonb_build_object(
            'labor', COALESCE(SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount END), 0),
            'material', COALESCE(SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount END), 0),
            'contractor', COALESCE(SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount END), 0),
            'equipment', COALESCE(SUM(CASE WHEN ct.cost_type = 'EQUIPMENT' THEN ct.amount END), 0)
        ),
        'cost_by_category', (
            SELECT jsonb_object_agg(wo.work_category, cost_sum)
            FROM (
                SELECT wo.work_category, SUM(ct.amount) as cost_sum
                FROM bms.cost_tracking ct
                JOIN bms.work_orders wo ON ct.work_order_id = wo.work_order_id
                WHERE ct.company_id = p_company_id
                  AND ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE)
                GROUP BY wo.work_category
            ) t
        ),
        'avg_cost_per_work_order', COALESCE(AVG(ct.amount), 0),
        'total_work_orders_with_cost', COUNT(DISTINCT ct.work_order_id)
    ) INTO v_cost_analysis
    FROM bms.cost_tracking ct
    WHERE ct.company_id = p_company_id
      AND ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE);
    
    -- 알림 및 경고 데이터
    SELECT jsonb_build_object(
        'emergency_reports', COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' AND fr.report_status != 'COMPLETED' THEN fr.report_id END),
        'overdue_work_orders', COUNT(DISTINCT CASE WHEN wo.scheduled_end_date < CURRENT_DATE AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END),
        'overdue_maintenance', COUNT(DISTINCT CASE WHEN ms.next_due_date < CURRENT_DATE THEN ms.schedule_id END),
        'warranty_expiring_soon', COUNT(DISTINCT CASE WHEN fa.warranty_end_date <= CURRENT_DATE + INTERVAL '30 days' AND fa.warranty_end_date >= CURRENT_DATE THEN fa.asset_id END),
        'low_performance_assets', COUNT(DISTINCT CASE WHEN fa.uptime_percentage < 80 THEN fa.asset_id END),
        'poor_condition_assets', COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END),
        'recent_fault_reports', COUNT(DISTINCT CASE WHEN fr.reported_date >= CURRENT_DATE - INTERVAL '7 days' THEN fr.report_id END),
        'pending_work_orders', COUNT(DISTINCT CASE WHEN wo.work_status = 'ASSIGNED' THEN wo.work_order_id END)
    ) INTO v_alerts
    FROM bms.companies c
    LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id
    LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id
    LEFT JOIN bms.maintenance_schedules ms ON c.company_id = ms.company_id
    LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
    WHERE c.company_id = p_company_id;
    
    -- 전체 대시보드 데이터 구성
    v_dashboard_data := jsonb_build_object(
        'company_id', p_company_id,
        'last_updated', NOW(),
        'facility_overview', v_facility_overview,
        'maintenance_status', v_maintenance_status,
        'cost_analysis', v_cost_analysis,
        'alerts', v_alerts
    );
    
    RETURN v_dashboard_data;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '대시보드 데이터 새로고침 중 오류 발생: %', SQLERRM;
END;
$$;

-- 5. 보고서 자동 생성 스케줄러 함수
CREATE OR REPLACE FUNCTION bms.schedule_automatic_reports()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_template RECORD;
    v_report_id UUID;
    v_last_generated_date DATE;
    v_should_generate BOOLEAN;
BEGIN
    -- 자동 생성이 활성화된 모든 템플릿 조회
    FOR v_template IN 
        SELECT rt.*, c.company_name
        FROM bms.report_templates rt
        JOIN bms.companies c ON rt.company_id = c.company_id
        WHERE rt.auto_generate = true
          AND rt.is_active = true
    LOOP
        v_should_generate := false;
        
        -- 마지막 생성 날짜 확인
        SELECT MAX(generated_at::date) INTO v_last_generated_date
        FROM bms.generated_reports
        WHERE template_id = v_template.template_id
          AND generation_type = 'AUTO';
        
        -- 생성 주기에 따른 생성 여부 결정
        CASE v_template.report_frequency
            WHEN 'DAILY' THEN
                v_should_generate := (v_last_generated_date IS NULL OR v_last_generated_date < CURRENT_DATE);
            WHEN 'WEEKLY' THEN
                v_should_generate := (v_last_generated_date IS NULL OR v_last_generated_date < CURRENT_DATE - INTERVAL '7 days');
            WHEN 'MONTHLY' THEN
                v_should_generate := (v_last_generated_date IS NULL OR v_last_generated_date < DATE_TRUNC('month', CURRENT_DATE));
            WHEN 'QUARTERLY' THEN
                v_should_generate := (v_last_generated_date IS NULL OR v_last_generated_date < DATE_TRUNC('quarter', CURRENT_DATE));
            WHEN 'YEARLY' THEN
                v_should_generate := (v_last_generated_date IS NULL OR v_last_generated_date < DATE_TRUNC('year', CURRENT_DATE));
        END CASE;
        
        -- 보고서 생성
        IF v_should_generate THEN
            BEGIN
                CASE v_template.template_type
                    WHEN 'FACILITY_STATUS' THEN
                        v_report_id := bms.generate_monthly_facility_report(v_template.company_id);
                    WHEN 'COST_ANALYSIS' THEN
                        v_report_id := bms.generate_cost_analysis_report(v_template.company_id);
                    WHEN 'PERFORMANCE_REPORT' THEN
                        v_report_id := bms.generate_performance_report(v_template.company_id);
                END CASE;
                
                RAISE NOTICE '자동 보고서 생성 완료: 회사=%, 템플릿=%, 보고서ID=%', 
                    v_template.company_name, v_template.template_name, v_report_id;
                    
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING '자동 보고서 생성 실패: 회사=%, 템플릿=%, 오류=%', 
                        v_template.company_name, v_template.template_name, SQLERRM;
            END;
        END IF;
    END LOOP;
    
END;
$$;

-- 6. 대시보드 위젯 데이터 조회 함수
CREATE OR REPLACE FUNCTION bms.get_widget_data(
    p_company_id UUID,
    p_widget_type VARCHAR(30),
    p_filter_config JSONB DEFAULT '{}'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
    v_start_date DATE;
    v_end_date DATE;
    v_asset_type VARCHAR(30);
BEGIN
    -- 필터 설정 파싱
    v_start_date := COALESCE((p_filter_config->>'start_date')::date, CURRENT_DATE - INTERVAL '30 days');
    v_end_date := COALESCE((p_filter_config->>'end_date')::date, CURRENT_DATE);
    v_asset_type := p_filter_config->>'asset_type';
    
    -- 위젯 유형별 데이터 조회
    CASE p_widget_type
        WHEN 'KPI_CARD' THEN
            SELECT jsonb_build_object(
                'total_assets', COUNT(DISTINCT fa.asset_id),
                'active_assets', COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END),
                'avg_uptime', COALESCE(AVG(fa.uptime_percentage), 0),
                'total_cost_this_month', COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN ct.amount END), 0)
            ) INTO v_result
            FROM bms.facility_assets fa
            LEFT JOIN bms.cost_tracking ct ON fa.company_id = ct.company_id
            WHERE fa.company_id = p_company_id
              AND (v_asset_type IS NULL OR fa.asset_type = v_asset_type);
              
        WHEN 'LINE_CHART' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'date', cost_date,
                    'amount', daily_cost
                ) ORDER BY cost_date
            ) INTO v_result
            FROM (
                SELECT 
                    ct.cost_date,
                    SUM(ct.amount) as daily_cost
                FROM bms.cost_tracking ct
                WHERE ct.company_id = p_company_id
                  AND ct.cost_date >= v_start_date
                  AND ct.cost_date <= v_end_date
                GROUP BY ct.cost_date
                ORDER BY ct.cost_date
            ) t;
            
        WHEN 'BAR_CHART' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'category', work_category,
                    'count', work_count,
                    'cost', total_cost
                )
            ) INTO v_result
            FROM (
                SELECT 
                    wo.work_category,
                    COUNT(wo.work_order_id) as work_count,
                    COALESCE(SUM(ct.amount), 0) as total_cost
                FROM bms.work_orders wo
                LEFT JOIN bms.cost_tracking ct ON wo.work_order_id = ct.work_order_id
                WHERE wo.company_id = p_company_id
                  AND wo.created_at >= v_start_date
                  AND wo.created_at <= v_end_date + INTERVAL '1 day'
                GROUP BY wo.work_category
            ) t;
            
        WHEN 'PIE_CHART' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'label', asset_type,
                    'value', asset_count,
                    'percentage', ROUND((asset_count * 100.0 / total_assets)::numeric, 1)
                )
            ) INTO v_result
            FROM (
                SELECT 
                    fa.asset_type,
                    COUNT(*) as asset_count,
                    SUM(COUNT(*)) OVER () as total_assets
                FROM bms.facility_assets fa
                WHERE fa.company_id = p_company_id
                  AND (v_asset_type IS NULL OR fa.asset_type = v_asset_type)
                GROUP BY fa.asset_type
            ) t;
            
        WHEN 'GAUGE' THEN
            SELECT jsonb_build_object(
                'current_value', COALESCE(AVG(fa.uptime_percentage), 0),
                'min_value', 0,
                'max_value', 100,
                'target_value', 95,
                'unit', '%'
            ) INTO v_result
            FROM bms.facility_assets fa
            WHERE fa.company_id = p_company_id
              AND (v_asset_type IS NULL OR fa.asset_type = v_asset_type);
              
        WHEN 'ALERT_LIST' THEN
            SELECT jsonb_agg(
                jsonb_build_object(
                    'type', alert_type,
                    'message', alert_message,
                    'severity', severity,
                    'created_at', created_at
                ) ORDER BY created_at DESC
            ) INTO v_result
            FROM (
                SELECT 
                    'EMERGENCY_REPORT' as alert_type,
                    '긴급 고장 신고: ' || fr.report_title as alert_message,
                    'HIGH' as severity,
                    fr.reported_date as created_at
                FROM bms.fault_reports fr
                WHERE fr.company_id = p_company_id
                  AND fr.fault_priority = 'EMERGENCY'
                  AND fr.report_status != 'COMPLETED'
                  AND fr.reported_date >= CURRENT_DATE - INTERVAL '7 days'
                UNION ALL
                SELECT 
                    'OVERDUE_MAINTENANCE' as alert_type,
                    '지연된 정비: ' || ms.schedule_name as alert_message,
                    'MEDIUM' as severity,
                    ms.next_due_date as created_at
                FROM bms.maintenance_schedules ms
                WHERE ms.company_id = p_company_id
                  AND ms.next_due_date < CURRENT_DATE
                LIMIT 10
            ) t;
            
        ELSE
            v_result := '{"error": "지원하지 않는 위젯 유형입니다"}'::jsonb;
    END CASE;
    
    RETURN COALESCE(v_result, '[]'::jsonb);
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object('error', '위젯 데이터 조회 중 오류 발생: ' || SQLERRM);
END;
$$;

-- 7. 함수 권한 설정
GRANT EXECUTE ON FUNCTION bms.generate_monthly_facility_report(UUID, DATE) TO application_role;
GRANT EXECUTE ON FUNCTION bms.generate_cost_analysis_report(UUID, DATE, DATE) TO application_role;
GRANT EXECUTE ON FUNCTION bms.generate_performance_report(UUID, VARCHAR) TO application_role;
GRANT EXECUTE ON FUNCTION bms.refresh_dashboard_data(UUID, VARCHAR) TO application_role;
GRANT EXECUTE ON FUNCTION bms.schedule_automatic_reports() TO application_role;
GRANT EXECUTE ON FUNCTION bms.get_widget_data(UUID, VARCHAR, JSONB) TO application_role;

-- 8. 함수 코멘트 추가
COMMENT ON FUNCTION bms.generate_monthly_facility_report(UUID, DATE) IS '월별 시설 관리 현황 보고서 자동 생성 함수';
COMMENT ON FUNCTION bms.generate_cost_analysis_report(UUID, DATE, DATE) IS '비용 분석 보고서 생성 함수';
COMMENT ON FUNCTION bms.generate_performance_report(UUID, VARCHAR) IS '시설물 성능 분석 보고서 생성 함수';
COMMENT ON FUNCTION bms.refresh_dashboard_data(UUID, VARCHAR) IS '대시보드 데이터 새로고침 함수';
COMMENT ON FUNCTION bms.schedule_automatic_reports() IS '보고서 자동 생성 스케줄러 함수';
COMMENT ON FUNCTION bms.get_widget_data(UUID, VARCHAR, JSONB) IS '대시보드 위젯 데이터 조회 함수';