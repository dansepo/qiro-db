-- =====================================================
-- 시설 관리 대시보드 및 보고서 시스템 (간단 버전)
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

-- 5. RLS 정책 설정
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

-- 6. 인덱스 생성
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

-- 7. 트리거 설정
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

-- 8. 테이블 코멘트 추가
COMMENT ON TABLE bms.dashboard_configurations IS '대시보드 설정 정보를 관리하는 테이블';
COMMENT ON TABLE bms.report_templates IS '보고서 템플릿 정보를 관리하는 테이블';
COMMENT ON TABLE bms.generated_reports IS '생성된 보고서 이력을 관리하는 테이블';
COMMENT ON TABLE bms.dashboard_widgets IS '대시보드 위젯 설정을 관리하는 테이블';

-- 9. 컬럼 코멘트 추가
COMMENT ON COLUMN bms.dashboard_configurations.dashboard_name IS '대시보드 이름';
COMMENT ON COLUMN bms.dashboard_configurations.dashboard_type IS '대시보드 유형 (FACILITY_OVERVIEW, MAINTENANCE, COST_ANALYSIS)';
COMMENT ON COLUMN bms.dashboard_configurations.widget_configuration IS '위젯 구성 정보';
COMMENT ON COLUMN bms.dashboard_configurations.refresh_interval_minutes IS '새로고침 간격(분)';
COMMENT ON COLUMN bms.dashboard_configurations.auto_refresh IS '자동 새로고침 여부';
COMMENT ON COLUMN bms.dashboard_configurations.access_roles IS '접근 가능한 역할 목록';
COMMENT ON COLUMN bms.dashboard_configurations.is_public IS '공개 대시보드 여부';
COMMENT ON COLUMN bms.dashboard_configurations.is_active IS '활성 상태';

COMMENT ON COLUMN bms.report_templates.template_name IS '템플릿 이름';
COMMENT ON COLUMN bms.report_templates.template_type IS '보고서 유형';
COMMENT ON COLUMN bms.report_templates.report_format IS '보고서 형식 (PDF, EXCEL, HTML)';
COMMENT ON COLUMN bms.report_templates.report_frequency IS '생성 주기';
COMMENT ON COLUMN bms.report_templates.auto_generate IS '자동 생성 여부';
COMMENT ON COLUMN bms.report_templates.distribution_list IS '배포 대상 목록';

COMMENT ON COLUMN bms.generated_reports.report_name IS '보고서 이름';
COMMENT ON COLUMN bms.generated_reports.report_type IS '보고서 유형';
COMMENT ON COLUMN bms.generated_reports.generation_type IS '생성 유형 (MANUAL, AUTO)';
COMMENT ON COLUMN bms.generated_reports.summary_data IS '보고서 요약 데이터';
COMMENT ON COLUMN bms.generated_reports.distribution_status IS '배포 상태';
COMMENT ON COLUMN bms.generated_reports.report_status IS '보고서 상태';

COMMENT ON COLUMN bms.dashboard_widgets.widget_name IS '위젯 이름';
COMMENT ON COLUMN bms.dashboard_widgets.widget_type IS '위젯 유형';
COMMENT ON COLUMN bms.dashboard_widgets.data_source IS '데이터 소스';
COMMENT ON COLUMN bms.dashboard_widgets.query_configuration IS '쿼리 설정';
COMMENT ON COLUMN bms.dashboard_widgets.display_configuration IS '표시 설정';