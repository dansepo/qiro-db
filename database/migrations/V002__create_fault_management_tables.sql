-- =====================================================
-- 고장 신고 시스템 테이블 생성
-- 버전: V002
-- 설명: 고장 신고, 분류, 첨부파일 테이블 생성
-- =====================================================

-- 1. 고장 분류 테이블
CREATE TABLE IF NOT EXISTS bms.fault_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 분류 정보
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    parent_category_id UUID,
    
    -- 분류 설정
    default_priority VARCHAR(20) DEFAULT 'MEDIUM',
    default_urgency VARCHAR(20) DEFAULT 'NORMAL',
    auto_escalation_hours INTEGER DEFAULT 24,
    requires_immediate_response BOOLEAN DEFAULT false,
    
    -- 응답 시간 SLA
    response_time_minutes INTEGER DEFAULT 240, -- 4시간 기본값
    resolution_time_hours INTEGER DEFAULT 24,
    
    -- 배정 규칙
    default_assigned_team VARCHAR(50),
    requires_specialist BOOLEAN DEFAULT false,
    contractor_required BOOLEAN DEFAULT false,
    
    -- 알림 설정
    notify_management BOOLEAN DEFAULT false,
    notify_residents BOOLEAN DEFAULT false,
    
    -- 분류 계층
    category_level INTEGER DEFAULT 1,
    display_order INTEGER DEFAULT 0,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 감사 필드
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_fault_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.fault_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_fault_categories_code UNIQUE (company_id, category_code),
    
    -- 체크 제약 조건
    CONSTRAINT chk_fault_priority CHECK (default_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_fault_urgency CHECK (default_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_category_level_fault CHECK (category_level >= 1 AND category_level <= 5)
);

-- 2. 고장 신고 테이블
CREATE TABLE IF NOT EXISTS bms.fault_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_id UUID,
    asset_id UUID,
    category_id UUID NOT NULL,
    
    -- 신고 식별 정보
    report_number VARCHAR(50) NOT NULL,
    report_title VARCHAR(200) NOT NULL,
    report_description TEXT NOT NULL,
    
    -- 신고자 정보
    reporter_type VARCHAR(20) NOT NULL,
    reporter_name VARCHAR(100),
    reporter_contact JSONB,
    reporter_unit_id UUID,
    anonymous_report BOOLEAN DEFAULT false,
    
    -- 고장 상세 정보
    fault_type VARCHAR(30) NOT NULL,
    fault_severity VARCHAR(20) NOT NULL,
    fault_urgency VARCHAR(20) NOT NULL,
    fault_priority VARCHAR(20) NOT NULL,
    
    -- 위치 및 상황 정보
    fault_location TEXT,
    affected_areas JSONB,
    environmental_conditions TEXT,
    
    -- 영향도 평가
    safety_impact VARCHAR(20) DEFAULT 'NONE',
    operational_impact VARCHAR(20) DEFAULT 'MINOR',
    resident_impact VARCHAR(20) DEFAULT 'MINOR',
    estimated_affected_units INTEGER DEFAULT 0,
    
    -- 시간 정보
    fault_occurred_at TIMESTAMP WITH TIME ZONE,
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_response_due TIMESTAMP WITH TIME ZONE,
    resolution_due TIMESTAMP WITH TIME ZONE,
    
    -- 상태 추적
    report_status VARCHAR(20) DEFAULT 'OPEN',
    resolution_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- 배정 정보
    assigned_to UUID,
    assigned_team VARCHAR(50),
    contractor_id UUID,
    escalation_level INTEGER DEFAULT 1,
    
    -- 응답 추적
    first_response_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID,
    
    -- 해결 추적
    work_started_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    resolution_method VARCHAR(50),
    resolution_description TEXT,
    
    -- 비용 추적
    estimated_repair_cost DECIMAL(12,2) DEFAULT 0,
    actual_repair_cost DECIMAL(12,2) DEFAULT 0,
    
    -- 품질 및 만족도
    resolution_quality_rating DECIMAL(3,1) DEFAULT 0,
    reporter_satisfaction_rating DECIMAL(3,1) DEFAULT 0,
    
    -- 문서화
    initial_photos JSONB,
    resolution_photos JSONB,
    supporting_documents JSONB,
    
    -- 소통 로그
    communication_log JSONB,
    internal_notes TEXT,
    
    -- 후속 조치
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date TIMESTAMP WITH TIME ZONE,
    follow_up_notes TEXT,
    
    -- 반복 문제 추적
    is_recurring_issue BOOLEAN DEFAULT false,
    
    -- 감사 필드
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_fault_reports_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE SET NULL,
    CONSTRAINT fk_fault_reports_category FOREIGN KEY (category_id) REFERENCES bms.fault_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_fault_reports_reporter_unit FOREIGN KEY (reporter_unit_id) REFERENCES bms.units(unit_id) ON DELETE SET NULL,
    CONSTRAINT uk_fault_reports_number UNIQUE (company_id, report_number),
    
    -- 체크 제약 조건
    CONSTRAINT chk_reporter_type CHECK (reporter_type IN (
        'RESIDENT', 'TENANT', 'VISITOR', 'STAFF', 'CONTRACTOR', 'SYSTEM', 'ANONYMOUS'
    )),
    CONSTRAINT chk_fault_type CHECK (fault_type IN (
        'ELECTRICAL', 'PLUMBING', 'HVAC', 'ELEVATOR', 'FIRE_SAFETY', 'SECURITY',
        'STRUCTURAL', 'APPLIANCE', 'LIGHTING', 'COMMUNICATION', 'OTHER'
    )),
    CONSTRAINT chk_fault_severity CHECK (fault_severity IN (
        'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL', 'CATASTROPHIC'
    )),
    CONSTRAINT chk_fault_urgency CHECK (fault_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_fault_priority CHECK (fault_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_impact_levels CHECK (
        safety_impact IN ('NONE', 'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL') AND
        operational_impact IN ('NONE', 'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL') AND
        resident_impact IN ('NONE', 'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL')
    ),
    CONSTRAINT chk_report_status CHECK (report_status IN (
        'OPEN', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED'
    )),
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN (
        'PENDING', 'INVESTIGATING', 'PARTS_ORDERED', 'SCHEDULED', 'IN_PROGRESS', 
        'COMPLETED', 'DEFERRED', 'CANCELLED'
    )),
    CONSTRAINT chk_escalation_level CHECK (escalation_level >= 1 AND escalation_level <= 5),
    CONSTRAINT chk_rating_values CHECK (
        (resolution_quality_rating >= 0 AND resolution_quality_rating <= 10) AND
        (reporter_satisfaction_rating >= 0 AND reporter_satisfaction_rating <= 10)
    ),
    CONSTRAINT chk_cost_values_fault CHECK (
        estimated_repair_cost >= 0 AND actual_repair_cost >= 0
    )
);

-- 3. 첨부파일 테이블
CREATE TABLE IF NOT EXISTS bms.attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 연결된 엔티티 정보
    entity_id UUID NOT NULL,
    entity_type VARCHAR(20) NOT NULL,
    
    -- 파일 정보
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    file_size BIGINT NOT NULL,
    
    -- 첨부파일 분류
    attachment_category VARCHAR(20) DEFAULT 'GENERAL',
    description TEXT,
    
    -- 썸네일 (이미지인 경우)
    thumbnail_path VARCHAR(500),
    
    -- 업로드 정보
    uploaded_by UUID NOT NULL,
    is_public BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- 감사 필드
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 체크 제약 조건
    CONSTRAINT chk_entity_type CHECK (entity_type IN (
        'FAULT_REPORT', 'WORK_ORDER', 'MAINTENANCE', 'INSPECTION', 'FEEDBACK'
    )),
    CONSTRAINT chk_attachment_category CHECK (attachment_category IN (
        'INITIAL_PHOTO', 'PROGRESS_PHOTO', 'COMPLETION_PHOTO', 'DOCUMENT', 'VIDEO', 'AUDIO', 'GENERAL'
    )),
    CONSTRAINT chk_file_size CHECK (file_size > 0)
);

-- 4. RLS 정책 활성화
ALTER TABLE bms.fault_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fault_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.attachments ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY fault_categories_isolation_policy ON bms.fault_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fault_reports_isolation_policy ON bms.fault_reports
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 첨부파일은 연결된 엔티티를 통해 접근 제어
CREATE POLICY attachments_isolation_policy ON bms.attachments
    FOR ALL TO application_role
    USING (
        CASE entity_type
            WHEN 'FAULT_REPORT' THEN EXISTS (
                SELECT 1 FROM bms.fault_reports fr 
                WHERE fr.report_id = entity_id 
                AND fr.company_id = (current_setting('app.current_company_id', true))::uuid
            )
            ELSE true -- 다른 엔티티 타입에 대한 정책은 추후 추가
        END
    );

-- 5. 성능 인덱스 생성
-- 고장 분류 인덱스
CREATE INDEX IF NOT EXISTS idx_fault_categories_company_id ON bms.fault_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_categories_parent ON bms.fault_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_fault_categories_code ON bms.fault_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_fault_categories_active ON bms.fault_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_fault_categories_priority ON bms.fault_categories(default_priority);

-- 고장 신고 인덱스
CREATE INDEX IF NOT EXISTS idx_fault_reports_company_id ON bms.fault_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_building_id ON bms.fault_reports(building_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_unit_id ON bms.fault_reports(unit_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_asset_id ON bms.fault_reports(asset_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_category_id ON bms.fault_reports(category_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_number ON bms.fault_reports(report_number);
CREATE INDEX IF NOT EXISTS idx_fault_reports_status ON bms.fault_reports(report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_resolution_status ON bms.fault_reports(resolution_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_priority ON bms.fault_reports(fault_priority);
CREATE INDEX IF NOT EXISTS idx_fault_reports_urgency ON bms.fault_reports(fault_urgency);
CREATE INDEX IF NOT EXISTS idx_fault_reports_severity ON bms.fault_reports(fault_severity);
CREATE INDEX IF NOT EXISTS idx_fault_reports_type ON bms.fault_reports(fault_type);
CREATE INDEX IF NOT EXISTS idx_fault_reports_reporter_type ON bms.fault_reports(reporter_type);
CREATE INDEX IF NOT EXISTS idx_fault_reports_assigned_to ON bms.fault_reports(assigned_to);
CREATE INDEX IF NOT EXISTS idx_fault_reports_reported_at ON bms.fault_reports(reported_at);
CREATE INDEX IF NOT EXISTS idx_fault_reports_occurred_at ON bms.fault_reports(fault_occurred_at);
CREATE INDEX IF NOT EXISTS idx_fault_reports_first_response_due ON bms.fault_reports(first_response_due);
CREATE INDEX IF NOT EXISTS idx_fault_reports_resolution_due ON bms.fault_reports(resolution_due);

-- 첨부파일 인덱스
CREATE INDEX IF NOT EXISTS idx_attachments_entity ON bms.attachments(entity_id, entity_type);
CREATE INDEX IF NOT EXISTS idx_attachments_category ON bms.attachments(attachment_category);
CREATE INDEX IF NOT EXISTS idx_attachments_uploaded_by ON bms.attachments(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_attachments_file_type ON bms.attachments(file_type);
CREATE INDEX IF NOT EXISTS idx_attachments_created_at ON bms.attachments(created_at);
CREATE INDEX IF NOT EXISTS idx_attachments_active ON bms.attachments(is_active);

-- 복합 인덱스 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_fault_reports_company_status ON bms.fault_reports(company_id, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_building_status ON bms.fault_reports(building_id, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_priority_status ON bms.fault_reports(fault_priority, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_assigned_status ON bms.fault_reports(assigned_to, report_status);

-- 6. 업데이트 트리거 생성
CREATE TRIGGER fault_categories_updated_at_trigger
    BEFORE UPDATE ON bms.fault_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fault_reports_updated_at_trigger
    BEFORE UPDATE ON bms.fault_reports
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER attachments_updated_at_trigger
    BEFORE UPDATE ON bms.attachments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 테이블 코멘트
COMMENT ON TABLE bms.fault_categories IS '고장 분류 - 고장 유형별 분류 및 기본 설정 관리';
COMMENT ON TABLE bms.fault_reports IS '고장 신고 - 시설물 고장 신고 및 처리 과정 관리';
COMMENT ON TABLE bms.attachments IS '첨부파일 - 고장 신고 관련 파일 첨부 관리';

-- 컬럼 코멘트
COMMENT ON COLUMN bms.fault_categories.category_code IS '분류 코드';
COMMENT ON COLUMN bms.fault_categories.category_name IS '분류명';
COMMENT ON COLUMN bms.fault_categories.default_priority IS '기본 우선순위';
COMMENT ON COLUMN bms.fault_categories.default_urgency IS '기본 긴급도';
COMMENT ON COLUMN bms.fault_categories.response_time_minutes IS '응답 시간 (분 단위)';
COMMENT ON COLUMN bms.fault_categories.resolution_time_hours IS '해결 시간 (시간 단위)';

COMMENT ON COLUMN bms.fault_reports.report_number IS '신고 번호 (고유 식별자)';
COMMENT ON COLUMN bms.fault_reports.report_title IS '신고 제목';
COMMENT ON COLUMN bms.fault_reports.reporter_type IS '신고자 유형';
COMMENT ON COLUMN bms.fault_reports.fault_type IS '고장 유형';
COMMENT ON COLUMN bms.fault_reports.fault_severity IS '고장 심각도';
COMMENT ON COLUMN bms.fault_reports.fault_urgency IS '고장 긴급도';
COMMENT ON COLUMN bms.fault_reports.fault_priority IS '고장 우선순위';
COMMENT ON COLUMN bms.fault_reports.report_status IS '신고 상태';
COMMENT ON COLUMN bms.fault_reports.resolution_status IS '해결 상태';

COMMENT ON COLUMN bms.attachments.entity_id IS '연결된 엔티티 ID';
COMMENT ON COLUMN bms.attachments.entity_type IS '엔티티 유형';
COMMENT ON COLUMN bms.attachments.attachment_category IS '첨부파일 분류';
COMMENT ON COLUMN bms.attachments.file_size IS '파일 크기 (바이트)';

-- 스크립트 완료 메시지
SELECT '고장 신고 시스템 테이블이 성공적으로 생성되었습니다.' as message;