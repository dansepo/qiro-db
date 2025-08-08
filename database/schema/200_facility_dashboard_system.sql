-- =====================================================
-- 시설 관리 대시보드 및 보고서 시스템
-- Phase 10: Dashboard and Reporting System
-- =====================================================

-- 1. 대시보드 설정 테이블
CREATE TABLE IF NOT EXISTS bms.dashboard_configurations (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 대시보드 정보
    dashboard_name VARCHAR(100) NOT NULL,
    dashboard_type VARCHAR(30) NOT NULL,
    description TEXT,
    
    -- 설정 정보
    widget_configuration JSONB,
    refresh_interval_minutes INTEGER DEFAULT 15,
    auto_refresh BOOLEAN DEFAULT true,
    
    -- 접근 권한
    access_roles JSONB,
    is_public BOOLEAN DEFAULT false,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_dashboard_config_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_dashboard_config_name UNIQUE (company_id, dashboard_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_dashboard_type CHECK (dashboard_type IN (
        'FACILITY_OVERVIEW', 'MAINTENANCE_STATUS', 'COST_ANALYSIS', 
        'FAULT_TRACKING', 'PERFORMANCE_METRICS', 'CUSTOM'
    ))
);

-- 2. 보고서 템플릿 테이블
CREATE TABLE IF NOT EXISTS bms.report_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 템플릿 정보
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(30) NOT NULL,
    description TEXT,
    
    -- 보고서 설정
    report_format VARCHAR(20) DEFAULT 'PDF',
    report_frequency VARCHAR(20) DEFAULT 'MONTHLY',
    
    -- 데이터 설정
    data_sources JSONB,
    filter_criteria JSONB,
    grouping_criteria JSONB,
    sorting_criteria JSONB,
    
    -- 레이아웃 설정
    layout_configuration JSONB,
    chart_configurations JSONB,
    table_configurations JSONB,
    
    -- 배포 설정
    auto_generate BOOLEAN DEFAULT false,
    distribution_list JSONB,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_report_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_report_templates_name UNIQUE (company_id, template_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_report_type CHECK (template_type IN (
        'FACILITY_STATUS', 'MAINTENANCE_SUMMARY', 'COST_ANALYSIS', 
        'FAULT_STATISTICS', 'PERFORMANCE_REPORT', 'COMPLIANCE_REPORT', 'CUSTOM'
    )),
    CONSTRAINT chk_report_format CHECK (report_format IN ('PDF', 'EXCEL', 'HTML', 'CSV')),
    CONSTRAINT chk_report_frequency CHECK (report_frequency IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY', 'ON_DEMAND'
    ))
);

-- 3. 생성된 보고서 이력 테이블
CREATE TABLE IF NOT EXISTS bms.generated_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    template_id UUID,
    
    -- 보고서 정보
    report_name VARCHAR(200) NOT NULL,
    report_type VARCHAR(30) NOT NULL,
    report_period_start DATE,
    report_period_end DATE,
    
    -- 생성 정보
    generation_type VARCHAR(20) DEFAULT 'MANUAL',
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    generated_by UUID,
    
    -- 파일 정보
    file_name VARCHAR(255),
    file_path VARCHAR(500),
    file_size BIGINT,
    file_format VARCHAR(20),
    
    -- 보고서 내용 요약
    summary_data JSONB,
    key_metrics JSONB,
    
    -- 배포 정보
    distribution_status VARCHAR(20) DEFAULT 'PENDING',
    distributed_at TIMESTAMP WITH TIME ZONE,
    distribution_log JSONB,
    
    -- 상태
    report_status VARCHAR(20) DEFAULT 'GENERATED',
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_generated_reports_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_generated_reports_template FOREIGN KEY (template_id) REFERENCES bms.report_templates(template_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_generation_type CHECK (generation_type IN ('MANUAL', 'AUTO', 'SCHEDULED')),
    CONSTRAINT chk_distribution_status CHECK (distribution_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'CANCELLED'
    )),
    CONSTRAINT chk_report_status CHECK (report_status IN (
        'GENERATING', 'GENERATED', 'DISTRIBUTED', 'ARCHIVED', 'DELETED'
    ))
);

-- 4. 대시보드 위젯 설정 테이블
CREATE TABLE IF NOT EXISTS bms.dashboard_widgets (
    widget_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    dashboard_config_id UUID,
    
    -- 위젯 정보
    widget_name VARCHAR(100) NOT NULL,
    widget_type VARCHAR(30) NOT NULL,
    widget_title VARCHAR(200),
    
    -- 위치 및 크기
    position_x INTEGER DEFAULT 0,
    position_y INTEGER DEFAULT 0,
    width INTEGER DEFAULT 4,
    height INTEGER DEFAULT 3,
    
    -- 데이터 설정
    data_source VARCHAR(100),
    query_configuration JSONB,
    filter_configuration JSONB,
    
    -- 표시 설정
    display_configuration JSONB,
    chart_configuration JSONB,
    color_scheme JSONB,
    
    -- 새로고침 설정
    refresh_interval_minutes INTEGER DEFAULT 15,
    auto_refresh BOOLEAN DEFAULT true,
    
    -- 상태
    is_visible BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_dashboard_widgets_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_dashboard_widgets_config FOREIGN KEY (dashboard_config_id) REFERENCES bms.dashboard_configurations(config_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_widget_type CHECK (widget_type IN (
        'KPI_CARD', 'LINE_CHART', 'BAR_CHART', 'PIE_CHART', 'DONUT_CHART',
        'TABLE', 'GAUGE', 'PROGRESS_BAR', 'ALERT_LIST', 'STATUS_GRID', 'MAP'
    ))
);

-- 5. 실시간 현황 대시보드 뷰
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
    
    -- 비용 현황 (이번 달)
    COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN ct.labor_cost END), 0) as monthly_cost,
    COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('year', CURRENT_DATE) THEN ct.labor_cost END), 0) as yearly_cost,
    
    -- 업데이트 시간
    NOW() as last_updated
FROM bms.companies c
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN bms.maintenance_plans mp ON c.company_id = mp.company_id
LEFT JOIN bms.work_order_labor_costs ct ON wo.work_order_id = ct.work_order_id
GROUP BY c.company_id, c.company_name;

-- 6. 월별 시설 관리 현황 보고서 뷰
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
    COALESCE(AVG(EXTRACT(EPOCH FROM (fr.actual_completion_date - fr.reported_at))/3600), 0) as avg_resolution_time_hours,
    
    -- 작업 지시 통계
    COUNT(DISTINCT wo.work_order_id) as total_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'PREVENTIVE' THEN wo.work_order_id END) as preventive_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'CORRECTIVE' THEN wo.work_order_id END) as corrective_work_orders,
    COUNT(DISTINCT CASE WHEN wo.work_category = 'EMERGENCY' THEN wo.work_order_id END) as emergency_work_orders,
    
    -- 비용 통계
    COALESCE(SUM(ct.amount), 0) as total_maintenance_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount END), 0) as labor_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount END), 0) as material_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount END), 0) as contractor_cost,
    
    -- 시설물 상태 통계
    COUNT(DISTINCT fa.asset_id) as total_assets,
    COUNT(DISTINCT CASE WHEN fa.asset_status = 'ACTIVE' THEN fa.asset_id END) as active_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'EXCELLENT' THEN fa.asset_id END) as excellent_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'GOOD' THEN fa.asset_id END) as good_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'FAIR' THEN fa.asset_id END) as fair_condition_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예방 정비 통계
    COUNT(DISTINCT ms.schedule_id) as total_maintenance_schedules,
    COUNT(DISTINCT CASE WHEN ms.last_performed_date >= DATE_TRUNC('month', CURRENT_DATE) THEN ms.schedule_id END) as completed_maintenance,
    COUNT(DISTINCT CASE WHEN ms.next_due_date <= CURRENT_DATE THEN ms.schedule_id END) as overdue_maintenance,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id 
    AND fr.reported_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND fr.reported_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id 
    AND wo.created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND wo.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.cost_tracking ct ON c.company_id = ct.company_id 
    AND ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE)
    AND ct.cost_date < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.maintenance_schedules ms ON c.company_id = ms.company_id
GROUP BY c.company_id, c.company_name;

-- 7. 비용 분석 및 통계 뷰
CREATE OR REPLACE VIEW bms.v_cost_analysis_report AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 기간별 비용 분석
    COALESCE(SUM(CASE WHEN ct.cost_date >= CURRENT_DATE - INTERVAL '7 days' THEN ct.amount END), 0) as weekly_cost,
    COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE) THEN ct.amount END), 0) as monthly_cost,
    COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('quarter', CURRENT_DATE) THEN ct.amount END), 0) as quarterly_cost,
    COALESCE(SUM(CASE WHEN ct.cost_date >= DATE_TRUNC('year', CURRENT_DATE) THEN ct.amount END), 0) as yearly_cost,
    
    -- 비용 유형별 분석
    COALESCE(SUM(CASE WHEN ct.cost_type = 'LABOR' THEN ct.amount END), 0) as total_labor_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'MATERIAL' THEN ct.amount END), 0) as total_material_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'CONTRACTOR' THEN ct.amount END), 0) as total_contractor_cost,
    COALESCE(SUM(CASE WHEN ct.cost_type = 'EQUIPMENT' THEN ct.amount END), 0) as total_equipment_cost,
    
    -- 작업 카테고리별 비용
    COALESCE(SUM(CASE WHEN wo.work_category = 'PREVENTIVE' THEN ct.amount END), 0) as preventive_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'CORRECTIVE' THEN ct.amount END), 0) as corrective_maintenance_cost,
    COALESCE(SUM(CASE WHEN wo.work_category = 'EMERGENCY' THEN ct.amount END), 0) as emergency_repair_cost,
    
    -- 시설물 유형별 비용
    COALESCE(SUM(CASE WHEN fa.asset_type = 'ELECTRICAL' THEN ct.amount END), 0) as electrical_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'PLUMBING' THEN ct.amount END), 0) as plumbing_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'HVAC' THEN ct.amount END), 0) as hvac_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'ELEVATOR' THEN ct.amount END), 0) as elevator_cost,
    COALESCE(SUM(CASE WHEN fa.asset_type = 'FIRE_SAFETY' THEN ct.amount END), 0) as fire_safety_cost,
    
    -- 평균 비용 분석
    COALESCE(AVG(ct.amount), 0) as avg_cost_per_work_order,
    COALESCE(COUNT(DISTINCT ct.work_order_id), 0) as total_cost_entries,
    
    -- 최고/최저 비용
    COALESCE(MAX(ct.amount), 0) as highest_single_cost,
    COALESCE(MIN(ct.amount), 0) as lowest_single_cost,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.cost_tracking ct ON c.company_id = ct.company_id
LEFT JOIN bms.work_orders wo ON ct.work_order_id = wo.work_order_id
LEFT JOIN bms.facility_assets fa ON wo.asset_id = fa.asset_id
GROUP BY c.company_id, c.company_name;

-- 8. 시설물 성능 지표 뷰
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

-- 9. 알림 및 경고 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_facility_alerts_dashboard AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 긴급 알림
    COUNT(DISTINCT CASE WHEN fr.fault_priority = 'EMERGENCY' AND fr.report_status != 'COMPLETED' THEN fr.report_id END) as active_emergency_reports,
    COUNT(DISTINCT CASE WHEN wo.work_priority = 'EMERGENCY' AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as active_emergency_work_orders,
    
    -- 지연 알림
    COUNT(DISTINCT CASE WHEN wo.scheduled_end_date < CURRENT_DATE AND wo.work_status != 'COMPLETED' THEN wo.work_order_id END) as overdue_work_orders,
    COUNT(DISTINCT CASE WHEN ms.next_due_date < CURRENT_DATE THEN ms.schedule_id END) as overdue_maintenance,
    
    -- 보증 만료 알림
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date <= CURRENT_DATE + INTERVAL '30 days' AND fa.warranty_end_date >= CURRENT_DATE THEN fa.asset_id END) as warranty_expiring_soon,
    COUNT(DISTINCT CASE WHEN fa.warranty_end_date < CURRENT_DATE THEN fa.asset_id END) as warranty_expired,
    
    -- 성능 저하 알림
    COUNT(DISTINCT CASE WHEN fa.uptime_percentage < 80 THEN fa.asset_id END) as low_performance_assets,
    COUNT(DISTINCT CASE WHEN fa.condition_rating = 'POOR' THEN fa.asset_id END) as poor_condition_assets,
    
    -- 예산 초과 위험
    CASE 
        WHEN SUM(ct.amount) > 100000 THEN 'HIGH'
        WHEN SUM(ct.amount) > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END as budget_risk_level,
    
    -- 생성 시간
    NOW() as generated_at
FROM bms.companies c
LEFT JOIN bms.fault_reports fr ON c.company_id = fr.company_id
LEFT JOIN bms.work_orders wo ON c.company_id = wo.company_id
LEFT JOIN bms.maintenance_schedules ms ON c.company_id = ms.company_id
LEFT JOIN bms.facility_assets fa ON c.company_id = fa.company_id
LEFT JOIN bms.cost_tracking ct ON c.company_id = ct.company_id 
    AND ct.cost_date >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY c.company_id, c.company_name;

-- 10. RLS 정책 설정
ALTER TABLE bms.dashboard_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.generated_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.dashboard_widgets ENABLE ROW LEVEL SECURITY;

-- 회사별 데이터 격리 정책
CREATE POLICY dashboard_configurations_isolation_policy ON bms.dashboard_configurations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY report_templates_isolation_policy ON bms.report_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY generated_reports_isolation_policy ON bms.generated_reports
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY dashboard_widgets_isolation_policy ON bms.dashboard_widgets
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 11. 인덱스 생성
-- 대시보드 설정 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_dashboard_config_company_id ON bms.dashboard_configurations(company_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_config_type ON bms.dashboard_configurations(dashboard_type);
CREATE INDEX IF NOT EXISTS idx_dashboard_config_active ON bms.dashboard_configurations(is_active);

-- 보고서 템플릿 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_report_templates_company_id ON bms.report_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_report_templates_type ON bms.report_templates(template_type);
CREATE INDEX IF NOT EXISTS idx_report_templates_frequency ON bms.report_templates(report_frequency);
CREATE INDEX IF NOT EXISTS idx_report_templates_auto_generate ON bms.report_templates(auto_generate);

-- 생성된 보고서 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_generated_reports_company_id ON bms.generated_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_generated_reports_template_id ON bms.generated_reports(template_id);
CREATE INDEX IF NOT EXISTS idx_generated_reports_type ON bms.generated_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_generated_reports_generated_at ON bms.generated_reports(generated_at);
CREATE INDEX IF NOT EXISTS idx_generated_reports_period ON bms.generated_reports(report_period_start, report_period_end);
CREATE INDEX IF NOT EXISTS idx_generated_reports_status ON bms.generated_reports(report_status);

-- 대시보드 위젯 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_company_id ON bms.dashboard_widgets(company_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_config_id ON bms.dashboard_widgets(dashboard_config_id);
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_type ON bms.dashboard_widgets(widget_type);
CREATE INDEX IF NOT EXISTS idx_dashboard_widgets_active ON bms.dashboard_widgets(is_active);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_dashboard_config_company_type ON bms.dashboard_configurations(company_id, dashboard_type);
CREATE INDEX IF NOT EXISTS idx_report_templates_company_type ON bms.report_templates(company_id, template_type);
CREATE INDEX IF NOT EXISTS idx_generated_reports_company_period ON bms.generated_reports(company_id, report_period_start, report_period_end);

-- 12. 트리거 설정
CREATE TRIGGER dashboard_configurations_updated_at_trigger
    BEFORE UPDATE ON bms.dashboard_configurations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER report_templates_updated_at_trigger
    BEFORE UPDATE ON bms.report_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER generated_reports_updated_at_trigger
    BEFORE UPDATE ON bms.generated_reports
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER dashboard_widgets_updated_at_trigger
    BEFORE UPDATE ON bms.dashboard_widgets
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 13. 테이블 및 컬럼 코멘트 추가
COMMENT ON TABLE bms.dashboard_configurations IS '대시보드 설정 정보를 관리하는 테이블';
COMMENT ON TABLE bms.report_templates IS '보고서 템플릿 정보를 관리하는 테이블';
COMMENT ON TABLE bms.generated_reports IS '생성된 보고서 이력을 관리하는 테이블';
COMMENT ON TABLE bms.dashboard_widgets IS '대시보드 위젯 설정을 관리하는 테이블';

COMMENT ON VIEW bms.v_facility_dashboard_overview IS '시설 관리 실시간 현황 대시보드 뷰';
COMMENT ON VIEW bms.v_monthly_facility_report IS '월별 시설 관리 현황 보고서 뷰';
COMMENT ON VIEW bms.v_cost_analysis_report IS '비용 분석 및 통계 보고서 뷰';
COMMENT ON VIEW bms.v_facility_performance_metrics IS '시설물 성능 지표 뷰';
COMMENT ON VIEW bms.v_facility_alerts_dashboard IS '시설 관리 알림 및 경고 대시보드 뷰';