-- =====================================================
-- 시설 관리 대시보드 뷰 (간단 버전)
-- Phase 10: Dashboard Views (Simple)
-- =====================================================

-- 1. 실시간 현황 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_facility_dashboard_overview AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 시설물 현황
    COUNT(DISTINCT fa.asset_id) as total_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END) as active_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'MAINTENANCE' THEN fa.asset_id END) as maintenance_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'OUT_OF_ORDER' THEN fa.asset_id END) as out_of_order_assets,
    
    -- 고장 신고 현황 (최근 30일)
    COUNT(DISTINCT fr.report_id) as total_fault_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'REPORTED' THEN fr.report_id END) as new_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'IN_PROGRESS' THEN fr.report_id END) as in_progress_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'COMPLETED' THEN fr.report_id END) as completed_reports,
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' THEN fr.report_id END) as emergency_reports,
    
    -- 작업 지시 현황 (최근 30일)
    COUNT(DISTINCT wo.work_order_id) as total_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'ASSIGNED' THEN wo.work_order_id END) as assigned_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'IN_PROGRESS' THEN wo.work_order_id END) as in_progress_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'COMPLETED' THEN wo.work_order_id END) as completed_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'OVERDUE' THEN wo.work_order_id END) as overdue_work_orders,
    
    -- 예방 정비 현황
    COUNT(DISTINCT mp.plan_id) as total_maintenance_plans,
    
    -- 비용 현황 (이번 달)
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN lc.total_labor_cost END), 0) as monthly_labor_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN mc.total_actual_cost END), 0) as monthly_material_cost,
    
    -- 업데이트 시간
    NOW() as last_updated
FROM bms.companies c
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.reported_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.work_order_labor_costs lc ON wo.work_order_id = lc.work_order_id
LEFT JOIN bms.work_order_materials mc ON wo.work_order_id = mc.work_order_id
GROUP BY c.company_id, c.company_name;

-- 2. 월별 시설 관리 현황 보고서 뷰
CREATE OR REPLACE VIEW bms.v_monthly_facility_report AS
SELECT 
    c.company_id,
    c.company_name,
    DATE_TRUNC('month', CURRENT_DATE) as report_month,
    
    -- 고장 신고 통계
    COUNT(DISTINCT fr.report_id) as total_fault_reports,
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' THEN fr.report_id END) as emergency_reports,
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'HIGH' THEN fr.report_id END) as high_priority_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'COMPLETED' THEN fr.report_id END) as resolved_reports,
    
    -- 평균 해결 시간 (시간 단위)
    COALESCE(AVG(EXTRACT(EPOCH FROM (fr.resolved_at - fr.reported_at))/3600), 0) as avg_resolution_time_hours,
    
    -- 작업 지시 통계
    COUNT(DISTINCT wo.work_order_id) as total_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'PREVENTIVE' THEN wo.work_order_id END) as preventive_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'CORRECTIVE' THEN wo.work_order_id END) as corrective_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'EMERGENCY' THEN wo.work_order_id END) as emergency_work_orders,
    
    -- 비용 통계
    COALESCE(SUM(lc.total_labor_cost), 0) as total_labor_cost,
    COALESCE(SUM(mc.total_actual_cost), 0) as total_material_cost,
    COALESCE(SUM(lc.total_labor_cost) + SUM(mc.total_actual_cost), 0) as total_maintenance_cost,
    
    -- 시설물 상태 통계
    COUNT(DISTINCT fa.asset_id) as total_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END) as active_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'EXCELLENT' THEN fa.asset_id END) as excellent_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'GOOD' THEN fa.asset_id END) as good_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'FAIR' THEN fa.asset_id END) as fair_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예방 정비 통계
    COUNT(DISTINCT mp.plan_id) as total_maintenance_plans,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.reported_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND fr.reported_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND wo.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_order_labor_costs lc ON wo.work_order_id = lc.work_order_id
    AND lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND lc.cost_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_order_materials mc ON wo.work_order_id = mc.work_order_id
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
GROUP BY c.company_id, c.company_name;

-- 3. 비용 분석 및 통계 뷰
CREATE OR REPLACE VIEW bms.v_cost_analysis_report AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 기간별 비용 분석
    COALESCE(SUM(CASE WHEN lc.cost_date >= CURRENT_DATE - INTERVAL '7 days' THEN lc.total_labor_cost END), 0) as weekly_labor_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN lc.total_labor_cost END), 0) as monthly_labor_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('quarter', CURRENT_DATE) THEN lc.total_labor_cost END), 0) as quarterly_labor_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('year', CURRENT_DATE) THEN lc.total_labor_cost END), 0) as yearly_labor_cost,
    
    COALESCE(SUM(CASE WHEN lc.cost_date >= CURRENT_DATE - INTERVAL '7 days' THEN mc.total_actual_cost END), 0) as weekly_material_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN mc.total_actual_cost END), 0) as monthly_material_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('quarter', CURRENT_DATE) THEN mc.total_actual_cost END), 0) as quarterly_material_cost,
    COALESCE(SUM(CASE WHEN lc.cost_date >= DATE_TRUNC('year', CURRENT_DATE) THEN mc.total_actual_cost END), 0) as yearly_material_cost,
    
    -- 작업 카테고리별 비용
    COALESCE(SUM(CASE WHEN wo.work_category = 'PREVENTIVE' THEN lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0) END), 0) as preventive_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'CORRECTIVE' THEN lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0) END), 0) as corrective_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'EMERGENCY' THEN lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0) END), 0) as emergency_repair_cost,
    
    -- 평균 비용 분석
    COALESCE(AVG(lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0)), 0) as avg_cost_per_work_order,
    COUNT(DISTINCT wo.work_order_id) as total_work_orders_with_cost,
    
    -- 최고/최저 비용
    COALESCE(MAX(lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0)), 0) as highest_single_cost,
    COALESCE(MIN(lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0)), 0) as lowest_single_cost,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id
LEFT JOIN bms.work_order_labor_costs lc ON wo.work_order_id = lc.work_order_id
LEFT JOIN bms.work_order_materials mc ON wo.work_order_id = mc.work_order_id
LEFT JOIN bms.facility_assets fa ON wo.asset_id = fa.asset_id
GROUP BY c.company_id, c.company_name;

-- 4. 시설물 성능 지표 뷰
CREATE OR REPLACE VIEW bms.v_facility_performance_metrics AS
SELECT 
    c.company_id,
    c.company_name,
    fa.asset_type,
    
    -- 시설물 수량
    COUNT(fa.asset_id) as total_assets,
    
    -- 가동률 분석
    AVG(fa.uptime_percentage) as avg_uptime_percentage,
    COUNT(CASE WHEN fa.uptime_percentage >= 95 THEN 1 END) as high_performance_assets,
    COUNT(CASE WHEN fa.uptime_percentage < 80 THEN 1 END) as low_performance_assets,
    
    -- 효율성 분석
    AVG(fa.efficiency_rating) as avg_efficiency_rating,
    
    -- 고장 빈도 분석
    AVG(fa.failure_count) as avg_failure_count,
    SUM(fa.failure_count) as total_failures,
    
    -- 유지보수 비용 분석
    AVG(fa.total_maintenance_cost) as avg_maintenance_cost_per_asset,
    SUM(fa.total_maintenance_cost) as total_maintenance_cost,
    
    -- 상태 분포
    COUNT(CASE WHEN fa.condition_rating = 'EXCELLENT' THEN 1 END) as excellent_condition_count,
    COUNT(CASE WHEN fa.condition_rating = 'GOOD' THEN 1 END) as good_condition_count,
    COUNT(CASE WHEN fa.condition_rating = 'FAIR' THEN 1 END) as fair_condition_count,
    COUNT(CASE WHEN fa.condition_rating = 'POOR' THEN 1 END) as poor_condition_count,
    
    -- 연령 분석
    AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, fa.installation_date))) as avg_asset_age_years,
    COUNT(CASE WHEN fa.installation_date <= CURRENT_DATE - INTERVAL '10 years' THEN 1 END) as aging_assets_count,
    
    -- 보증 상태
    COUNT(CASE WHEN fa.warranty_end_date >= CURRENT_DATE THEN 1 END) as assets_under_warranty,
    COUNT(CASE WHEN fa.warranty_end_date < CURRENT_DATE THEN 1 END) as assets_out_of_warranty,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
WHERE fa.asset_id IS NOT NULL
GROUP BY c.company_id, c.company_name, fa.asset_type;

-- 5. 알림 및 경고 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_facility_alerts_dashboard AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 긴급 알림
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' AND fr.report_status != 'COMPLETED' THEN fr.report_id END) as active_emergency_reports,
    COUNT(DISTINCT CASE WHEN wo.work_priority = 'EMERGENCY' AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as active_emergency_work_orders,
    
    -- 지연 알림
    COUNT(DISTINCT CASE WHEN wo.scheduled_end_date < CURRENT_DATE AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as overdue_work_orders,
    
    -- 보증 만료 알림
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date <= CURRENT_DATE + INTERVAL '30 days' AND fa.warranty_end_date >= CURRENT_DATE THEN fa.asset_id END) as warranty_expiring_soon,
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date < CURRENT_DATE THEN fa.asset_id END) as warranty_expired,
    
    -- 성능 저하 알림
    COUNT(DISTINCT CASE WHEN fa.uptime_percentage < 80 THEN fa.asset_id END) as low_performance_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예산 초과 위험 (월간 비용 기준)
    CASE 
        WHEN SUM(lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0)) > 100000 THEN 'HIGH'
        WHEN SUM(lc.total_labor_cost + COALESCE(mc.total_actual_cost, 0)) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as budget_risk_level,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.work_order_labor_costs lc ON wo.work_order_id = lc.work_order_id 
    AND lc.cost_date >= DATE_TRUNC('month', CURRENT_DATE)
LEFT JOIN bms.work_order_materials mc ON wo.work_order_id = mc.work_order_id
GROUP BY c.company_id, c.company_name;

-- 6. 뷰 코멘트 추가
COMMENT ON VIEW bms.v_facility_dashboard_overview IS '시설 관리 실시간 현황 대시보드 뷰';
COMMENT ON VIEW bms.v_monthly_facility_report IS '월별 시설 관리 현황 보고서 뷰';
COMMENT ON VIEW bms.v_cost_analysis_report IS '비용 분석 및 통계 보고서 뷰';
COMMENT ON VIEW bms.v_facility_performance_metrics IS '시설물 성능 지표 뷰';
COMMENT ON VIEW bms.v_facility_alerts_dashboard IS '시설 관리 알림 및 경고 대시보드 뷰';