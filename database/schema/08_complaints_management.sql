-- =====================================================
-- 민원 처리 관리 테이블 설계
-- 요구사항: 5.1 - 민원 처리 관리
-- =====================================================

-- 민원 분류 코드 테이블
CREATE TABLE complaint_categories (
    id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    default_priority VARCHAR(20) DEFAULT 'MEDIUM',
    default_sla_hours INTEGER DEFAULT 72, -- 기본 SLA 시간 (72시간)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 분류 코드 기본 데이터
INSERT INTO complaint_categories (category_code, category_name, description, default_priority, default_sla_hours) VALUES
('FACILITY', '시설 관련', '엘리베이터, 보일러, 전기, 수도 등 시설 문제', 'HIGH', 24),
('NOISE', '소음 관련', '층간소음, 공사소음, 기타 소음 문제', 'MEDIUM', 48),
('PARKING', '주차 관련', '주차 공간, 주차 위반, 주차 요금 문제', 'MEDIUM', 48),
('CLEANING', '청소 관련', '공용구역 청소, 쓰레기 처리 문제', 'LOW', 72),
('SECURITY', '보안 관련', '출입통제, CCTV, 보안 문제', 'HIGH', 12),
('BILLING', '요금 관련', '관리비, 임대료, 기타 요금 문의', 'MEDIUM', 48),
('NEIGHBOR', '이웃 관련', '이웃 간 분쟁, 공동생활 문제', 'MEDIUM', 72),
('ADMIN', '관리 관련', '관리사무소 업무, 서비스 문의', 'LOW', 72),
('OTHER', '기타', '기타 민원 사항', 'MEDIUM', 48);

-- 민원 우선순위 정의 (ENUM 타입)
CREATE TYPE complaint_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
CREATE TYPE complaint_status AS ENUM ('RECEIVED', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_INFO', 'RESOLVED', 'CLOSED', 'CANCELLED');

-- 민원 관리 테이블 (기존 설계 확장)
CREATE TABLE complaints (
    id BIGSERIAL PRIMARY KEY,
    complaint_number VARCHAR(20) UNIQUE NOT NULL, -- 민원 번호 (자동 생성)
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    unit_id BIGINT REFERENCES units(id),
    category_id BIGINT NOT NULL REFERENCES complaint_categories(id),
    
    -- 민원 접수 정보
    complainant_name VARCHAR(255) NOT NULL,
    complainant_contact VARCHAR(100),
    complainant_email VARCHAR(255),
    complainant_type VARCHAR(20) DEFAULT 'TENANT', -- TENANT, OWNER, VISITOR, ANONYMOUS
    
    -- 민원 내용
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    location_detail VARCHAR(255), -- 구체적인 위치 (예: 지하 1층 주차장 A구역)
    
    -- 우선순위 및 상태 관리
    priority complaint_priority NOT NULL DEFAULT 'MEDIUM',
    status complaint_status NOT NULL DEFAULT 'RECEIVED',
    urgency_reason TEXT, -- 긴급 처리 사유
    
    -- 담당자 정보
    assigned_to BIGINT REFERENCES users(id),
    assigned_at TIMESTAMP,
    assigned_by BIGINT REFERENCES users(id),
    
    -- SLA 관리
    sla_due_at TIMESTAMP NOT NULL, -- SLA 만료 시간
    sla_hours INTEGER NOT NULL, -- 할당된 SLA 시간
    is_sla_breached BOOLEAN DEFAULT false, -- SLA 위반 여부
    sla_breach_reason TEXT, -- SLA 위반 사유
    
    -- 처리 결과
    resolution TEXT,
    resolution_cost DECIMAL(12,2) DEFAULT 0, -- 처리 비용
    satisfaction_score INTEGER CHECK (satisfaction_score >= 1 AND satisfaction_score <= 5), -- 만족도 (1-5점)
    satisfaction_comment TEXT, -- 만족도 의견
    
    -- 일정 관리
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    first_response_at TIMESTAMP, -- 최초 응답 시간
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    CONSTRAINT chk_resolution_required CHECK (
        (status IN ('RESOLVED', 'CLOSED') AND resolution IS NOT NULL) OR 
        (status NOT IN ('RESOLVED', 'CLOSED'))
    ),
    CONSTRAINT chk_resolved_at_required CHECK (
        (status IN ('RESOLVED', 'CLOSED') AND resolved_at IS NOT NULL) OR 
        (status NOT IN ('RESOLVED', 'CLOSED'))
    )
);

-- 민원 처리 이력 테이블
CREATE TABLE complaint_histories (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- STATUS_CHANGE, ASSIGNMENT, COMMENT, ESCALATION
    previous_status complaint_status,
    new_status complaint_status,
    previous_assignee BIGINT REFERENCES users(id),
    new_assignee BIGINT REFERENCES users(id),
    comment TEXT,
    action_by BIGINT NOT NULL REFERENCES users(id),
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 첨부파일 테이블
CREATE TABLE complaint_attachments (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 댓글/메모 테이블
CREATE TABLE complaint_comments (
    id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES complaints(id) ON DELETE CASCADE,
    comment_type VARCHAR(20) DEFAULT 'INTERNAL', -- INTERNAL, PUBLIC, SYSTEM
    content TEXT NOT NULL,
    is_visible_to_complainant BOOLEAN DEFAULT false,
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 SLA 설정 테이블 (건물별 커스터마이징 가능)
CREATE TABLE complaint_sla_settings (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    category_id BIGINT NOT NULL REFERENCES complaint_categories(id),
    priority complaint_priority NOT NULL,
    sla_hours INTEGER NOT NULL,
    escalation_hours INTEGER, -- 에스컬레이션 시간
    auto_assign_to BIGINT REFERENCES users(id), -- 자동 할당 담당자
    notification_emails TEXT[], -- 알림 이메일 목록
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, category_id, priority)
);

-- 민원 통계 뷰
CREATE VIEW complaint_statistics AS
SELECT 
    building_id,
    category_id,
    cc.category_name,
    priority,
    status,
    COUNT(*) as complaint_count,
    AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, CURRENT_TIMESTAMP) - submitted_at))/3600) as avg_resolution_hours,
    COUNT(CASE WHEN is_sla_breached THEN 1 END) as sla_breach_count,
    AVG(satisfaction_score) as avg_satisfaction_score
FROM complaints c
JOIN complaint_categories cc ON c.category_id = cc.id
GROUP BY building_id, category_id, cc.category_name, priority, status;

-- 인덱스 생성
CREATE INDEX idx_complaints_building_id ON complaints(building_id);
CREATE INDEX idx_complaints_unit_id ON complaints(unit_id);
CREATE INDEX idx_complaints_category_id ON complaints(category_id);
CREATE INDEX idx_complaints_status ON complaints(status);
CREATE INDEX idx_complaints_priority ON complaints(priority);
CREATE INDEX idx_complaints_assigned_to ON complaints(assigned_to);
CREATE INDEX idx_complaints_submitted_at ON complaints(submitted_at);
CREATE INDEX idx_complaints_sla_due_at ON complaints(sla_due_at);
CREATE INDEX idx_complaints_number ON complaints(complaint_number);

CREATE INDEX idx_complaint_histories_complaint_id ON complaint_histories(complaint_id);
CREATE INDEX idx_complaint_histories_action_at ON complaint_histories(action_at);

CREATE INDEX idx_complaint_attachments_complaint_id ON complaint_attachments(complaint_id);
CREATE INDEX idx_complaint_comments_complaint_id ON complaint_comments(complaint_id);

CREATE INDEX idx_complaint_sla_settings_building_category ON complaint_sla_settings(building_id, category_id);

-- 민원 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_complaint_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산
    SELECT COALESCE(MAX(CAST(SUBSTRING(complaint_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM complaints 
    WHERE complaint_number LIKE 'C' || year_month || '%';
    
    -- 민원번호 생성 (C + YYYYMM + 4자리 순번)
    new_number := 'C' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.complaint_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 민원 번호 자동 생성 트리거
CREATE TRIGGER trg_generate_complaint_number
    BEFORE INSERT ON complaints
    FOR EACH ROW
    WHEN (NEW.complaint_number IS NULL)
    EXECUTE FUNCTION generate_complaint_number();

-- SLA 계산 및 설정 함수
CREATE OR REPLACE FUNCTION set_complaint_sla()
RETURNS TRIGGER AS $$
DECLARE
    sla_hours INTEGER;
BEGIN
    -- 건물별 SLA 설정이 있는지 확인
    SELECT cs.sla_hours INTO sla_hours
    FROM complaint_sla_settings cs
    WHERE cs.building_id = NEW.building_id 
      AND cs.category_id = NEW.category_id 
      AND cs.priority = NEW.priority
      AND cs.is_active = true;
    
    -- 건물별 설정이 없으면 기본 설정 사용
    IF sla_hours IS NULL THEN
        SELECT cc.default_sla_hours INTO sla_hours
        FROM complaint_categories cc
        WHERE cc.id = NEW.category_id;
    END IF;
    
    -- SLA 시간 설정
    NEW.sla_hours := sla_hours;
    NEW.sla_due_at := NEW.submitted_at + (sla_hours || ' hours')::INTERVAL;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SLA 설정 트리거
CREATE TRIGGER trg_set_complaint_sla
    BEFORE INSERT ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION set_complaint_sla();

-- SLA 위반 체크 함수
CREATE OR REPLACE FUNCTION check_sla_breach()
RETURNS TRIGGER AS $$
BEGIN
    -- 해결되지 않은 민원의 SLA 위반 체크
    IF NEW.status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') AND 
       NEW.sla_due_at < CURRENT_TIMESTAMP THEN
        NEW.is_sla_breached := true;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SLA 위반 체크 트리거
CREATE TRIGGER trg_check_sla_breach
    BEFORE UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION check_sla_breach();

-- 민원 이력 자동 기록 함수
CREATE OR REPLACE FUNCTION record_complaint_history()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태 변경 시 이력 기록
    IF TG_OP = 'UPDATE' AND OLD.status != NEW.status THEN
        INSERT INTO complaint_histories (
            complaint_id, action_type, previous_status, new_status, 
            action_by, action_at
        ) VALUES (
            NEW.id, 'STATUS_CHANGE', OLD.status, NEW.status,
            NEW.updated_by, CURRENT_TIMESTAMP
        );
    END IF;
    
    -- 담당자 변경 시 이력 기록
    IF TG_OP = 'UPDATE' AND COALESCE(OLD.assigned_to, 0) != COALESCE(NEW.assigned_to, 0) THEN
        INSERT INTO complaint_histories (
            complaint_id, action_type, previous_assignee, new_assignee,
            action_by, action_at
        ) VALUES (
            NEW.id, 'ASSIGNMENT', OLD.assigned_to, NEW.assigned_to,
            NEW.updated_by, CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 민원 이력 기록 트리거
CREATE TRIGGER trg_record_complaint_history
    AFTER UPDATE ON complaints
    FOR EACH ROW
    EXECUTE FUNCTION record_complaint_history();

-- 민원 처리 성과 지표 뷰
CREATE VIEW complaint_performance_metrics AS
SELECT 
    building_id,
    DATE_TRUNC('month', submitted_at) as month,
    COUNT(*) as total_complaints,
    COUNT(CASE WHEN status IN ('RESOLVED', 'CLOSED') THEN 1 END) as resolved_complaints,
    COUNT(CASE WHEN is_sla_breached THEN 1 END) as sla_breached_complaints,
    ROUND(
        COUNT(CASE WHEN status IN ('RESOLVED', 'CLOSED') THEN 1 END)::DECIMAL / 
        COUNT(*)::DECIMAL * 100, 2
    ) as resolution_rate,
    ROUND(
        COUNT(CASE WHEN is_sla_breached THEN 1 END)::DECIMAL / 
        COUNT(*)::DECIMAL * 100, 2
    ) as sla_breach_rate,
    AVG(satisfaction_score) as avg_satisfaction_score,
    AVG(EXTRACT(EPOCH FROM (resolved_at - submitted_at))/3600) as avg_resolution_hours
FROM complaints
GROUP BY building_id, DATE_TRUNC('month', submitted_at);

-- =====================================================
-- 공지사항 및 알림 관리 테이블 설계
-- 요구사항: 5.2, 5.3 - 공지사항 및 알림 관리
-- =====================================================

-- 공지사항 분류 코드 테이블
CREATE TABLE announcement_categories (
    id BIGSERIAL PRIMARY KEY,
    category_code VARCHAR(20) UNIQUE NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50), -- 아이콘 클래스명
    color VARCHAR(20), -- 표시 색상
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 분류 기본 데이터
INSERT INTO announcement_categories (category_code, category_name, description, icon, color) VALUES
('GENERAL', '일반 공지', '일반적인 공지사항', 'info-circle', 'blue'),
('MAINTENANCE', '시설 공지', '시설 점검, 공사 관련 공지', 'tools', 'orange'),
('EVENT', '행사 공지', '건물 내 행사, 이벤트 공지', 'calendar', 'green'),
('EMERGENCY', '긴급 공지', '긴급상황, 비상사태 공지', 'exclamation-triangle', 'red'),
('BILLING', '요금 공지', '관리비, 임대료 관련 공지', 'credit-card', 'purple'),
('POLICY', '정책 공지', '관리 정책, 규정 변경 공지', 'file-text', 'gray'),
('SAFETY', '안전 공지', '안전 수칙, 주의사항 공지', 'shield', 'yellow');

-- 공지사항 대상 그룹 정의
CREATE TYPE announcement_target AS ENUM ('ALL', 'TENANTS', 'OWNERS', 'STAFF', 'BUILDING_SPECIFIC', 'UNIT_SPECIFIC', 'CUSTOM');
CREATE TYPE announcement_status AS ENUM ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'EXPIRED', 'CANCELLED');

-- 공지사항 테이블 (기존 설계 확장)
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    announcement_number VARCHAR(20) UNIQUE NOT NULL, -- 공지 번호 (자동 생성)
    building_id BIGINT REFERENCES buildings(id), -- NULL이면 전체 건물 대상
    category_id BIGINT NOT NULL REFERENCES announcement_categories(id),
    
    -- 공지사항 내용
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary VARCHAR(500), -- 요약 (목록 표시용)
    
    -- 공지사항 속성
    target_audience announcement_target NOT NULL DEFAULT 'ALL',
    is_urgent BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false, -- 상단 고정 여부
    allow_comments BOOLEAN DEFAULT false, -- 댓글 허용 여부
    
    -- 발행 관리
    status announcement_status NOT NULL DEFAULT 'DRAFT',
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    auto_expire BOOLEAN DEFAULT false, -- 자동 만료 여부
    
    -- 첨부파일 정보
    has_attachments BOOLEAN DEFAULT false,
    
    -- 조회 통계
    view_count INTEGER DEFAULT 0,
    
    -- 감사 필드
    created_by BIGINT NOT NULL REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 제약조건
    CONSTRAINT chk_published_at_required CHECK (
        (status = 'PUBLISHED' AND published_at IS NOT NULL) OR 
        (status != 'PUBLISHED')
    ),
    CONSTRAINT chk_expires_at_valid CHECK (
        expires_at IS NULL OR expires_at > published_at
    )
);

-- 공지사항 대상자 테이블 (CUSTOM 타겟용)
CREATE TABLE announcement_targets (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL, -- BUILDING, UNIT, USER, ROLE
    target_id BIGINT NOT NULL, -- 대상 ID
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 첨부파일 테이블
CREATE TABLE announcement_attachments (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    download_count INTEGER DEFAULT 0,
    uploaded_by BIGINT NOT NULL REFERENCES users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 댓글 테이블
CREATE TABLE announcement_comments (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    parent_comment_id BIGINT REFERENCES announcement_comments(id), -- 대댓글용
    commenter_name VARCHAR(255) NOT NULL,
    commenter_contact VARCHAR(100),
    content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false, -- 댓글 승인 여부
    approved_by BIGINT REFERENCES users(id),
    approved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 조회 이력 테이블
CREATE TABLE announcement_views (
    id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
    viewer_type VARCHAR(20) NOT NULL, -- USER, ANONYMOUS
    viewer_id BIGINT, -- 로그인 사용자의 경우
    viewer_ip INET,
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 중복 조회 방지 (같은 사용자가 하루에 여러 번 조회해도 1회로 계산)
    UNIQUE(announcement_id, viewer_id, DATE(viewed_at))
);

-- 알림 유형 정의
CREATE TYPE notification_type AS ENUM (
    'ANNOUNCEMENT', 'COMPLAINT_UPDATE', 'MAINTENANCE_SCHEDULE', 'BILLING_NOTICE',
    'CONTRACT_EXPIRY', 'PAYMENT_DUE', 'SYSTEM_ALERT', 'CUSTOM'
);
CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED');
CREATE TYPE notification_channel AS ENUM ('IN_APP', 'EMAIL', 'SMS', 'PUSH');

-- 알림 테이블 (기존 설계 확장)
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    notification_number VARCHAR(20) UNIQUE NOT NULL, -- 알림 번호 (자동 생성)
    
    -- 수신자 정보
    recipient_type VARCHAR(20) NOT NULL, -- USER, TENANT, OWNER, STAFF
    recipient_id BIGINT NOT NULL,
    recipient_name VARCHAR(255),
    recipient_contact VARCHAR(100), -- 이메일 또는 전화번호
    
    -- 알림 내용
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500), -- 클릭 시 이동할 URL
    
    -- 발송 설정
    channels notification_channel[] NOT NULL DEFAULT ARRAY['IN_APP'], -- 발송 채널 (배열)
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5), -- 1(낮음) ~ 5(높음)
    
    -- 발송 일정
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- 상태 관리
    status notification_status NOT NULL DEFAULT 'PENDING',
    
    -- 발송 결과
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    failed_reason TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retry INTEGER DEFAULT 3,
    
    -- 관련 데이터
    related_entity_type VARCHAR(50), -- COMPLAINT, ANNOUNCEMENT, INVOICE 등
    related_entity_id BIGINT,
    
    -- 감사 필드
    created_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 알림 템플릿 테이블
CREATE TABLE notification_templates (
    id BIGSERIAL PRIMARY KEY,
    template_code VARCHAR(50) UNIQUE NOT NULL,
    template_name VARCHAR(255) NOT NULL,
    notification_type notification_type NOT NULL,
    title_template VARCHAR(255) NOT NULL, -- 제목 템플릿 (변수 포함)
    message_template TEXT NOT NULL, -- 메시지 템플릿 (변수 포함)
    default_channels notification_channel[] NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 알림 템플릿 기본 데이터
INSERT INTO notification_templates (template_code, template_name, notification_type, title_template, message_template, default_channels) VALUES
('ANNOUNCEMENT_NEW', '새 공지사항 알림', 'ANNOUNCEMENT', '새 공지사항: {{title}}', '{{building_name}}에 새로운 공지사항이 등록되었습니다.\n\n제목: {{title}}\n내용: {{summary}}', ARRAY['IN_APP', 'EMAIL']),
('COMPLAINT_ASSIGNED', '민원 배정 알림', 'COMPLAINT_UPDATE', '민원이 배정되었습니다: {{complaint_number}}', '민원 {{complaint_number}}이(가) 귀하에게 배정되었습니다.\n\n제목: {{title}}\n우선순위: {{priority}}', ARRAY['IN_APP', 'EMAIL']),
('COMPLAINT_RESOLVED', '민원 해결 알림', 'COMPLAINT_UPDATE', '민원이 해결되었습니다: {{complaint_number}}', '접수하신 민원이 해결되었습니다.\n\n민원번호: {{complaint_number}}\n해결내용: {{resolution}}', ARRAY['IN_APP', 'EMAIL', 'SMS']),
('MAINTENANCE_SCHEDULED', '유지보수 일정 알림', 'MAINTENANCE_SCHEDULE', '유지보수 일정 안내', '{{facility_name}} 유지보수가 예정되어 있습니다.\n\n일시: {{scheduled_date}}\n내용: {{description}}', ARRAY['IN_APP', 'EMAIL']),
('BILLING_DUE', '관리비 납부 안내', 'BILLING_NOTICE', '관리비 납부 안내', '{{month}}월 관리비 납부 기한이 임박했습니다.\n\n금액: {{amount}}원\n납부기한: {{due_date}}', ARRAY['IN_APP', 'EMAIL', 'SMS']),
('CONTRACT_EXPIRY', '계약 만료 안내', 'CONTRACT_EXPIRY', '임대 계약 만료 안내', '임대 계약이 곧 만료됩니다.\n\n만료일: {{expiry_date}}\n연장 문의: {{contact_info}}', ARRAY['IN_APP', 'EMAIL']);

-- 사용자별 알림 설정 테이블
CREATE TABLE user_notification_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    notification_type notification_type NOT NULL,
    enabled_channels notification_channel[] NOT NULL DEFAULT ARRAY['IN_APP'],
    is_enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME, -- 알림 금지 시작 시간
    quiet_hours_end TIME, -- 알림 금지 종료 시간
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, notification_type)
);

-- 인덱스 생성
CREATE INDEX idx_announcements_building_id ON announcements(building_id);
CREATE INDEX idx_announcements_category_id ON announcements(category_id);
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_announcements_published_at ON announcements(published_at);
CREATE INDEX idx_announcements_expires_at ON announcements(expires_at);
CREATE INDEX idx_announcements_target_audience ON announcements(target_audience);
CREATE INDEX idx_announcements_is_urgent ON announcements(is_urgent);
CREATE INDEX idx_announcements_is_pinned ON announcements(is_pinned);
CREATE INDEX idx_announcements_number ON announcements(announcement_number);

CREATE INDEX idx_announcement_targets_announcement_id ON announcement_targets(announcement_id);
CREATE INDEX idx_announcement_targets_type_id ON announcement_targets(target_type, target_id);

CREATE INDEX idx_announcement_attachments_announcement_id ON announcement_attachments(announcement_id);
CREATE INDEX idx_announcement_comments_announcement_id ON announcement_comments(announcement_id);
CREATE INDEX idx_announcement_comments_parent_id ON announcement_comments(parent_comment_id);

CREATE INDEX idx_announcement_views_announcement_id ON announcement_views(announcement_id);
CREATE INDEX idx_announcement_views_viewer ON announcement_views(viewer_id, viewed_at);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_type, recipient_id);
CREATE INDEX idx_notifications_type ON notifications(notification_type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);
CREATE INDEX idx_notifications_related_entity ON notifications(related_entity_type, related_entity_id);
CREATE INDEX idx_notifications_number ON notifications(notification_number);

CREATE INDEX idx_notification_templates_code ON notification_templates(template_code);
CREATE INDEX idx_notification_templates_type ON notification_templates(notification_type);

CREATE INDEX idx_user_notification_settings_user_type ON user_notification_settings(user_id, notification_type);

-- 공지사항 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_announcement_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산
    SELECT COALESCE(MAX(CAST(SUBSTRING(announcement_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM announcements 
    WHERE announcement_number LIKE 'A' || year_month || '%';
    
    -- 공지번호 생성 (A + YYYYMM + 4자리 순번)
    new_number := 'A' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.announcement_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 공지사항 번호 자동 생성 트리거
CREATE TRIGGER trg_generate_announcement_number
    BEFORE INSERT ON announcements
    FOR EACH ROW
    WHEN (NEW.announcement_number IS NULL)
    EXECUTE FUNCTION generate_announcement_number();

-- 알림 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_notification_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산
    SELECT COALESCE(MAX(CAST(SUBSTRING(notification_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM notifications 
    WHERE notification_number LIKE 'N' || year_month || '%';
    
    -- 알림번호 생성 (N + YYYYMM + 4자리 순번)
    new_number := 'N' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.notification_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 알림 번호 자동 생성 트리거
CREATE TRIGGER trg_generate_notification_number
    BEFORE INSERT ON notifications
    FOR EACH ROW
    WHEN (NEW.notification_number IS NULL)
    EXECUTE FUNCTION generate_notification_number();

-- 공지사항 조회수 업데이트 함수
CREATE OR REPLACE FUNCTION update_announcement_view_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE announcements 
    SET view_count = view_count + 1
    WHERE id = NEW.announcement_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 공지사항 조회수 업데이트 트리거
CREATE TRIGGER trg_update_announcement_view_count
    AFTER INSERT ON announcement_views
    FOR EACH ROW
    EXECUTE FUNCTION update_announcement_view_count();

-- 첨부파일 존재 여부 업데이트 함수
CREATE OR REPLACE FUNCTION update_announcement_attachments_flag()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE announcements 
        SET has_attachments = true
        WHERE id = NEW.announcement_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE announcements 
        SET has_attachments = (
            SELECT COUNT(*) > 0 
            FROM announcement_attachments 
            WHERE announcement_id = OLD.announcement_id
        )
        WHERE id = OLD.announcement_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 첨부파일 존재 여부 업데이트 트리거
CREATE TRIGGER trg_update_announcement_attachments_flag
    AFTER INSERT OR DELETE ON announcement_attachments
    FOR EACH ROW
    EXECUTE FUNCTION update_announcement_attachments_flag();

-- 공지사항 통계 뷰
CREATE VIEW announcement_statistics AS
SELECT 
    building_id,
    category_id,
    ac.category_name,
    status,
    target_audience,
    COUNT(*) as announcement_count,
    SUM(view_count) as total_views,
    AVG(view_count) as avg_views,
    COUNT(CASE WHEN is_urgent THEN 1 END) as urgent_count,
    COUNT(CASE WHEN has_attachments THEN 1 END) as with_attachments_count
FROM announcements a
JOIN announcement_categories ac ON a.category_id = ac.id
GROUP BY building_id, category_id, ac.category_name, status, target_audience;

-- 알림 발송 통계 뷰
CREATE VIEW notification_statistics AS
SELECT 
    notification_type,
    status,
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as notification_count,
    COUNT(CASE WHEN status = 'SENT' THEN 1 END) as sent_count,
    COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END) as delivered_count,
    COUNT(CASE WHEN status = 'READ' THEN 1 END) as read_count,
    COUNT(CASE WHEN status = 'FAILED' THEN 1 END) as failed_count,
    ROUND(
        COUNT(CASE WHEN status = 'READ' THEN 1 END)::DECIMAL / 
        NULLIF(COUNT(CASE WHEN status IN ('SENT', 'DELIVERED', 'READ') THEN 1 END), 0) * 100, 2
    ) as read_rate
FROM notifications
GROUP BY notification_type, status, DATE_TRUNC('day', created_at);

-- 코멘트 추가
COMMENT ON TABLE complaints IS '민원 관리 테이블 - 건물 관련 민원 접수 및 처리 관리';
COMMENT ON TABLE complaint_categories IS '민원 분류 코드 테이블 - 민원 유형별 분류 및 기본 설정';
COMMENT ON TABLE complaint_histories IS '민원 처리 이력 테이블 - 민원 처리 과정의 모든 변경 이력';
COMMENT ON TABLE complaint_attachments IS '민원 첨부파일 테이블 - 민원 관련 첨부 파일 관리';
COMMENT ON TABLE complaint_comments IS '민원 댓글/메모 테이블 - 민원 처리 과정의 의견 및 메모';
COMMENT ON TABLE complaint_sla_settings IS '민원 SLA 설정 테이블 - 건물별 민원 처리 기준 시간 설정';

COMMENT ON TABLE announcements IS '공지사항 관리 테이블 - 건물별 공지사항 등록 및 관리';
COMMENT ON TABLE announcement_categories IS '공지사항 분류 코드 테이블 - 공지사항 유형별 분류';
COMMENT ON TABLE announcement_targets IS '공지사항 대상자 테이블 - 맞춤형 공지사항 대상 지정';
COMMENT ON TABLE announcement_attachments IS '공지사항 첨부파일 테이블 - 공지사항 관련 첨부 파일 관리';
COMMENT ON TABLE announcement_comments IS '공지사항 댓글 테이블 - 공지사항에 대한 댓글 및 대댓글';
COMMENT ON TABLE announcement_views IS '공지사항 조회 이력 테이블 - 공지사항 조회 통계 관리';
COMMENT ON TABLE notifications IS '알림 관리 테이블 - 다양한 채널을 통한 알림 발송 관리';
COMMENT ON TABLE notification_templates IS '알림 템플릿 테이블 - 알림 유형별 템플릿 관리';
COMMENT ON TABLE user_notification_settings IS '사용자별 알림 설정 테이블 - 개인별 알림 수신 설정';

COMMENT ON COLUMN complaints.complaint_number IS '민원 번호 - C + YYYYMM + 4자리 순번 형식으로 자동 생성';
COMMENT ON COLUMN complaints.sla_due_at IS 'SLA 만료 시간 - 민원 접수 시간 + SLA 시간으로 자동 계산';
COMMENT ON COLUMN complaints.is_sla_breached IS 'SLA 위반 여부 - 만료 시간 초과 시 자동으로 true 설정';
COMMENT ON COLUMN complaints.satisfaction_score IS '만족도 점수 - 1(매우 불만족) ~ 5(매우 만족)';

COMMENT ON COLUMN announcements.announcement_number IS '공지 번호 - A + YYYYMM + 4자리 순번 형식으로 자동 생성';
COMMENT ON COLUMN announcements.target_audience IS '공지 대상 - ALL(전체), TENANTS(임차인), OWNERS(임대인), STAFF(직원) 등';
COMMENT ON COLUMN announcements.is_pinned IS '상단 고정 여부 - true시 공지사항 목록 상단에 고정 표시';
COMMENT ON COLUMN announcements.view_count IS '조회수 - announcement_views 테이블 INSERT 시 자동 증가';

COMMENT ON COLUMN notifications.notification_number IS '알림 번호 - N + YYYYMM + 4자리 순번 형식으로 자동 생성';
COMMENT ON COLUMN notifications.channels IS '발송 채널 배열 - IN_APP, EMAIL, SMS, PUSH 중 복수 선택 가능';
COMMENT ON COLUMN notifications.priority IS '알림 우선순위 - 1(낮음) ~ 5(높음), 높을수록 우선 발송';