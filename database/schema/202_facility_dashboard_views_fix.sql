-- =====================================================
-- 시설 관리 대시보드 뷰 수정
-- Phase 10: Dashboard Views Fix
-- =====================================================

-- 1. 실시간 현황 대시보드 뷰 수정
DROP VIEW IF EXISTS bms.v_facility_dashboard_overview CASCADE;
CREATE OR REPLACE VIEW bms.v_facility_dashboard_overview AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 시설물 현황
    COUNT(DISTINCT fa.asset_id) as total_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END) as active_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'MAINTENANCE' THEN fa.asset_id END) as maintenance_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'OUT_OF_ORDER' THEN fa.asset_id END) as out_of_order_assets,
    
    -- 고장 신고 현황
    COUNT(DISTINCT fr.report_id) as total_fault_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'REPORTED' THEN fr.report_id END) as new_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'IN_PROGRESS' THEN fr.report_id END) as in_progress_reports,
    COUNT(DISTINCT CASE WHEN fr.report_status = 'COMPLETED' THEN fr.report_id END) as completed_reports,
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' THEN fr.report_id END) as emergency_reports,
    
    -- 작업 지시 현황
    COUNT(DISTINCT wo.work_order_id) as total_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'ASSIGNED' THEN wo.work_order_id END) as assigned_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'IN_PROGRESS' THEN wo.work_order_id END) as in_progress_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'COMPLETED' THEN wo.work_order_id END) as completed_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_status = 'OVERDUE' THEN wo.work_order_id END) as overdue_work_orders,
    
    -- 예방 정비 현황
    COUNT(DISTINCT mp.plan_id) as total_maintenance_plans,
    COUNT(DISTINCT CASE WHEN mp.next_execution_date <= CURRENT_DATE THEN mp.plan_id END) as due_maintenance,
    COUNT(DISTINCT CASE WHEN mp.next_execution_date <= CURRENT_DATE + INTERVAL '7 days' THEN mp.plan_id END) as upcoming_maintenance,
    
    -- 비용 현황 (이번 달) - work_cost_settlements 테이블 사용
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= DATE_TRUNC('month', CURRENT_DATE) THEN wcs.total_amount END), 0) as monthly_cost,
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= DATE_TRUNC('year', CURRENT_DATE) THEN wcs.total_amount END), 0) as yearly_cost,
    
    -- 업데이트 시간
    NOW() as last_updated
FROM bms.companies c
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.work_cost_settlements wcs ON c.company_id = wcs.company_id
GROUP BY c.company_id, c.company_name;

-- 2. 월별 시설 관리 현황 보고서 뷰 수정
DROP VIEW IF EXISTS bms.v_monthly_facility_report CASCADE;
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
    COALESCE(AVG(EXTRACT(EPOCH FROM (fr.actual_completion_date - fr.reported_date))/3600), 0) as avg_resolution_time_hours,
    
    -- 작업 지시 통계
    COUNT(DISTINCT wo.work_order_id) as total_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'PREVENTIVE' THEN wo.work_order_id END) as preventive_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'CORRECTIVE' THEN wo.work_order_id END) as corrective_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'EMERGENCY' THEN wo.work_order_id END) as emergency_work_orders,
    
    -- 비용 통계 - work_cost_settlements와 work_order_labor_costs 사용
    COALESCE(SUM(wcs.total_amount), 0) + COALESCE(SUM(wolc.total_cost), 0) as total_maintenance_cost,
    COALESCE(SUM(wolc.total_cost), 0) as labor_cost,
    COALESCE(SUM(wcs.material_cost), 0) as material_cost,
    COALESCE(SUM(wcs.contractor_cost), 0) as contractor_cost,
    
    -- 시설물 상태 통계
    COUNT(DISTINCT fa.asset_id) as total_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END) as active_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'EXCELLENT' THEN fa.asset_id END) as excellent_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'GOOD' THEN fa.asset_id END) as good_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'FAIR' THEN fa.asset_id END) as fair_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예방 정비 통계
    COUNT(DISTINCT mp.plan_id) as total_maintenance_plans,
    COUNT(DISTINCT CASE WHEN pme.execution_date >= DATE_TRUNC('month', CURRENT_DATE) THEN mp.plan_id END) as completed_maintenance,
    COUNT(DISTINCT CASE WHEN mp.next_execution_date <= CURRENT_DATE THEN mp.plan_id END) as overdue_maintenance,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.reported_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND fr.reported_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND wo.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_cost_settlements wcs ON c.company_id = wcs.company_id 
    AND wcs.settlement_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND wcs.settlement_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_order_labor_costs wolc ON wo.work_order_id = wolc.work_order_id
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.preventive_maintenance_executions pme ON mp.plan_id = pme.plan_id
GROUP BY c.company_id, c.company_name;

-- 3. 비용 분석 및 통계 뷰 수정
DROP VIEW IF EXISTS bms.v_cost_analysis_report CASCADE;
CREATE OR REPLACE VIEW bms.v_cost_analysis_report AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 기간별 비용 분석 - work_cost_settlements 기준
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= CURRENT_DATE - INTERVAL '7 days' THEN wcs.total_amount END), 0) as weekly_cost,
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= DATE_TRUNC('month', CURRENT_DATE) THEN wcs.total_amount END), 0) as monthly_cost,
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= DATE_TRUNC('quarter', CURRENT_DATE) THEN wcs.total_amount END), 0) as quarterly_cost,
    COALESCE(SUM(CASE WHEN wcs.settlement_date >= DATE_TRUNC('year', CURRENT_DATE) THEN wcs.total_amount END), 0) as yearly_cost,
    
    -- 비용 유형별 분석
    COALESCE(SUM(wolc.total_cost), 0) as total_labor_cost,
    COALESCE(SUM(wcs.material_cost), 0) as total_material_cost,
    COALESCE(SUM(wcs.contractor_cost), 0) as total_contractor_cost,
    COALESCE(SUM(wcs.equipment_cost), 0) as total_equipment_cost,
    
    -- 작업 카테고리별 비용
    COALESCE(SUM(CASE WHEN wo.work_category = 'PREVENTIVE' THEN wcs.total_amount END), 0) as preventive_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'CORRECTIVE' THEN wcs.total_amount END), 0) as corrective_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'EMERGENCY' THEN wcs.total_amount END), 0) as emergency_repair_cost,
    
    -- 시설물 유형별 비용
    COALESCE(SUM(CASE WHEN fa.asset_type = 'ELECTRICAL' THEN wcs.total_amount END), 0) as electrical_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'PLUMBING' THEN wcs.total_amount END), 0) as plumbing_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'HVAC' THEN wcs.total_amount END), 0) as hvac_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'ELEVATOR' THEN wcs.total_amount END), 0) as elevator_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'FIRE_SAFETY' THEN wcs.total_amount END), 0) as fire_safety_cost,
    
    -- 평균 비용 분석
    COALESCE(AVG(wcs.total_amount), 0) as avg_cost_per_work_order,
    COALESCE(COUNT(DISTINCT wcs.work_order_id), 0) as total_cost_entries,
    
    -- 최고/최저 비용
    COALESCE(MAX(wcs.total_amount), 0) as highest_single_cost,
    COALESCE(MIN(wcs.total_amount), 0) as lowest_single_cost,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.work_cost_settlements wcs ON c.company_id = wcs.company_id
LEFT JOIN bms.work_orders wo ON wcs.work_order_id = wo.work_order_id
LEFT JOIN bms.work_order_labor_costs wolc ON wo.work_order_id = wolc.work_order_id
LEFT JOIN bms.facility_assets fa ON wo.asset_id = fa.asset_id
GROUP BY c.company_id, c.company_name;

-- 4. 알림 및 경고 대시보드 뷰 수정
DROP VIEW IF EXISTS bms.v_facility_alerts_dashboard CASCADE;
CREATE OR REPLACE VIEW bms.v_facility_alerts_dashboard AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 긴급 알림
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' AND fr.report_status != 'COMPLETED' THEN fr.report_id END) as active_emergency_reports,
    COUNT(DISTINCT CASE WHEN wo.work_priority = 'EMERGENCY' AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as active_emergency_work_orders,
    
    -- 지연 알림
    COUNT(DISTINCT CASE WHEN wo.scheduled_end_date < CURRENT_DATE AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as overdue_work_orders,
    COUNT(DISTINCT CASE WHEN mp.next_execution_date < CURRENT_DATE THEN mp.plan_id END) as overdue_maintenance,
    
    -- 보증 만료 알림
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date <= CURRENT_DATE + INTERVAL '30 days' AND fa.warranty_end_date >= CURRENT_DATE THEN fa.asset_id END) as warranty_expiring_soon,
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date < CURRENT_DATE THEN fa.asset_id END) as warranty_expired,
    
    -- 성능 저하 알림
    COUNT(DISTINCT CASE WHEN fa.uptime_percentage < 80 THEN fa.asset_id END) as low_performance_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예산 초과 위험
    CASE 
        WHEN SUM(wcs.total_amount) > 100000 THEN 'HIGH'
        WHEN SUM(wcs.total_amount) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as budget_risk_level,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.work_cost_settlements wcs ON c.company_id = wcs.company_id 
    AND wcs.settlement_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY c.company_id, c.company_name;

-- 5. 뷰 코멘트 추가
COMMENT ON VIEW bms.v_facility_dashboard_overview IS '시설 관리 실시간 현황 대시보드 뷰 (수정됨)';
COMMENT ON VIEW bms.v_monthly_facility_report IS '월별 시설 관리 현황 보고서 뷰 (수정됨)';
COMMENT ON VIEW bms.v_cost_analysis_report IS '비용 분석 및 통계 보고서 뷰 (수정됨)';
COMMENT ON VIEW bms.v_facility_alerts_dashboard IS '시설 관리 알림 및 경고 대시보드 뷰 (수정됨)';