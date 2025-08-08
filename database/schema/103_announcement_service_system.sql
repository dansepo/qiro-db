-- =====================================================
-- 민원 및 회계 관리 시스템 - 공지사항 및 서비스 관리 테이블
-- 작성일: 2025-01-30
-- 요구사항: 3.1, 9.1, 10.1 - 공지사항 관리, 직원 관리, 서비스 관리
-- =====================================================

-- 공지사항 및 서비스 관련 ENUM 타입 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'announcement_status') THEN
        CREATE TYPE announcement_status AS ENUM ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'EXPIRED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'announcement_target') THEN
        CREATE TYPE announcement_target AS ENUM ('ALL', 'TENANTS', 'OWNERS', 'STAFF', 'BUILDING_SPECIFIC', 'UNIT_SPECIFIC', 'CUSTOM');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
        CREATE TYPE notification_type AS ENUM (
            'ANNOUNCEMENT', 'COMPLAINT_UPDATE', 'MAINTENANCE_SCHEDULE', 'BILLING_NOTICE',
            'CONTRACT_EXPIRY', 'PAYMENT_DUE', 'SYSTEM_ALERT', 'CUSTOM'
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_status') THEN
        CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'DELIVERED', 'READ', 'FAILED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_channel') THEN
        CREATE TYPE notification_channel AS ENUM ('IN_APP', 'EMAIL', 'SMS', 'PUSH');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'service_status') THEN
        CREATE TYPE service_status AS ENUM ('ACTIVE', 'INACTIVE', 'MAINTENANCE', 'DISCONTINUED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
        CREATE TYPE booking_status AS ENUM ('PENDING', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'employment_status') THEN
        CREATE TYPE employment_status AS ENUM ('ACTIVE', 'INACTIVE', 'TERMINATED', 'ON_LEAVE');
    END IF;
END $$;

-- 공지사항 분류 테이블
CREATE TABLE IF NOT EXISTS bms.announcement_categories (
    category_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_announcement_categories_company_code UNIQUE(company_id, category_code)
);

-- 공지사항 테이블
CREATE TABLE IF NOT EXISTS bms.announcements (
    announcement_id BIGSERIAL PRIMARY KEY,
    announcement_number VARCHAR(20) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    building_id BIGINT REFERENCES bms.buildings(id),
    category_id BIGINT NOT NULL REFERENCES bms.announcement_categories(category_id),
    
    -- 공지사항 내용
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary VARCHAR(500),
    
    -- 공지사항 속성
    target_audience announcement_target NOT NULL DEFAULT 'ALL',
    is_urgent BOOLEAN DEFAULT false,
    is_pinned BOOLEAN DEFAULT false,
    allow_comments BOOLEAN DEFAULT false,
    
    -- 발행 관리
    announcement_status announcement_status NOT NULL DEFAULT 'DRAFT',
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    auto_expire BOOLEAN DEFAULT false,
    
    -- 첨부파일 정보
    has_attachments BOOLEAN DEFAULT false,
    
    -- 조회 통계
    view_count INTEGER DEFAULT 0,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    -- 제약조건
    CONSTRAINT chk_announcements_published_at_required CHECK (
        (announcement_status = 'PUBLISHED' AND published_at IS NOT NULL) OR 
        (announcement_status != 'PUBLISHED')
    ),
    CONSTRAINT chk_announcements_expires_at_valid CHECK (
        expires_at IS NULL OR expires_at > published_at
    )
);

-- 공지사항 대상자 테이블
CREATE TABLE IF NOT EXISTS bms.announcement_targets (
    target_id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES bms.announcements(announcement_id) ON DELETE CASCADE,
    target_type VARCHAR(20) NOT NULL CHECK (target_type IN ('BUILDING', 'UNIT', 'USER', 'ROLE')),
    target_entity_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 첨부파일 테이블
CREATE TABLE IF NOT EXISTS bms.announcement_attachments (
    attachment_id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES bms.announcements(announcement_id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    mime_type VARCHAR(100),
    download_count INTEGER DEFAULT 0,
    uploaded_by BIGINT NOT NULL REFERENCES bms.users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 공지사항 조회 이력 테이블
CREATE TABLE IF NOT EXISTS bms.announcement_views (
    view_id BIGSERIAL PRIMARY KEY,
    announcement_id BIGINT NOT NULL REFERENCES bms.announcements(announcement_id) ON DELETE CASCADE,
    viewer_type VARCHAR(20) NOT NULL CHECK (viewer_type IN ('USER', 'ANONYMOUS')),
    viewer_id BIGINT REFERENCES bms.users(id),
    viewer_ip INET,
    user_agent TEXT,
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 중복 조회 방지 (같은 사용자가 하루에 여러 번 조회해도 1회로 계산)
    CONSTRAINT uk_announcement_views_daily UNIQUE(announcement_id, viewer_id, DATE(viewed_at))
);

-- 알림 테이블
CREATE TABLE IF NOT EXISTS bms.notifications (
    notification_id BIGSERIAL PRIMARY KEY,
    notification_number VARCHAR(20) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    
    -- 수신자 정보
    recipient_type VARCHAR(20) NOT NULL CHECK (recipient_type IN ('USER', 'TENANT', 'OWNER', 'STAFF')),
    recipient_id BIGINT NOT NULL,
    recipient_name VARCHAR(255),
    recipient_contact VARCHAR(100),
    
    -- 알림 내용
    notification_type notification_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    action_url VARCHAR(500),
    
    -- 발송 설정
    channels notification_channel[] NOT NULL DEFAULT ARRAY['IN_APP'],
    priority INTEGER DEFAULT 3 CHECK (priority >= 1 AND priority <= 5),
    
    -- 발송 일정
    scheduled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- 상태 관리
    notification_status notification_status NOT NULL DEFAULT 'PENDING',
    
    -- 발송 결과
    sent_at TIMESTAMP,
    delivered_at TIMESTAMP,
    read_at TIMESTAMP,
    failed_reason TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retry INTEGER DEFAULT 3,
    
    -- 관련 데이터
    related_entity_type VARCHAR(50),
    related_entity_id BIGINT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id)
);

-- 알림 발송 이력 테이블
CREATE TABLE IF NOT EXISTS bms.notification_delivery_history (
    history_id BIGSERIAL PRIMARY KEY,
    notification_id BIGINT NOT NULL REFERENCES bms.notifications(notification_id) ON DELETE CASCADE,
    channel notification_channel NOT NULL,
    delivery_status notification_status NOT NULL,
    delivery_attempt INTEGER DEFAULT 1,
    delivered_at TIMESTAMP,
    error_message TEXT,
    response_data JSONB
);

-- 알림 수신 확인 테이블
CREATE TABLE IF NOT EXISTS bms.notification_receipts (
    receipt_id BIGSERIAL PRIMARY KEY,
    notification_id BIGINT NOT NULL REFERENCES bms.notifications(notification_id) ON DELETE CASCADE,
    recipient_id BIGINT NOT NULL,
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    action_taken VARCHAR(50),
    feedback TEXT
);

-- 직원 테이블
CREATE TABLE IF NOT EXISTS bms.employees (
    employee_id BIGSERIAL PRIMARY KEY,
    employee_number VARCHAR(20) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES bms.users(id),
    
    -- 기본 정보
    name VARCHAR(255) NOT NULL,
    position VARCHAR(100),
    department VARCHAR(100),
    
    -- 고용 정보
    hire_date DATE NOT NULL,
    employment_type VARCHAR(20) DEFAULT 'FULL_TIME' CHECK (employment_type IN ('FULL_TIME', 'PART_TIME', 'CONTRACT', 'INTERN')),
    employment_status employment_status DEFAULT 'ACTIVE',
    termination_date DATE,
    termination_reason TEXT,
    
    -- 급여 정보
    base_salary DECIMAL(12,2),
    hourly_rate DECIMAL(8,2),
    
    -- 연락처 정보
    phone VARCHAR(20),
    email VARCHAR(255),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    
    -- 주소 정보
    address TEXT,
    
    -- 기술 및 자격
    skills JSONB,
    certifications JSONB,
    
    -- 성과 평가
    performance_rating DECIMAL(3,2) CHECK (performance_rating >= 0 AND performance_rating <= 5),
    last_evaluation_date DATE,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    -- 제약조건
    CONSTRAINT chk_employees_termination_date CHECK (
        (employment_status = 'TERMINATED' AND termination_date IS NOT NULL) OR
        (employment_status != 'TERMINATED')
    )
);

-- 서비스 테이블
CREATE TABLE IF NOT EXISTS bms.services (
    service_id BIGSERIAL PRIMARY KEY,
    service_code VARCHAR(20) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    building_id BIGINT REFERENCES bms.buildings(id),
    
    -- 서비스 기본 정보
    service_name VARCHAR(255) NOT NULL,
    service_category VARCHAR(100) NOT NULL,
    service_description TEXT,
    
    -- 서비스 속성
    service_type VARCHAR(20) DEFAULT 'FREE' CHECK (service_type IN ('FREE', 'PAID', 'SUBSCRIPTION')),
    price DECIMAL(10,2) DEFAULT 0,
    duration_minutes INTEGER DEFAULT 60,
    max_capacity INTEGER DEFAULT 1,
    
    -- 예약 설정
    booking_advance_days INTEGER DEFAULT 7,
    cancellation_hours INTEGER DEFAULT 24,
    auto_confirm BOOLEAN DEFAULT false,
    
    -- 운영 시간
    operating_hours JSONB,
    
    -- 서비스 상태
    service_status service_status DEFAULT 'ACTIVE',
    
    -- 제공업체 정보
    provider_info JSONB,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id)
);

-- 서비스 예약 테이블
CREATE TABLE IF NOT EXISTS bms.service_bookings (
    booking_id BIGSERIAL PRIMARY KEY,
    booking_number VARCHAR(20) UNIQUE NOT NULL,
    service_id BIGINT NOT NULL REFERENCES bms.services(service_id),
    
    -- 예약자 정보
    booker_id BIGINT REFERENCES bms.users(id),
    booker_name VARCHAR(255) NOT NULL,
    booker_phone VARCHAR(20),
    booker_email VARCHAR(255),
    
    -- 예약 정보
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    duration_minutes INTEGER NOT NULL,
    participant_count INTEGER DEFAULT 1,
    
    -- 예약 상태
    booking_status booking_status DEFAULT 'PENDING',
    confirmed_at TIMESTAMP,
    confirmed_by BIGINT REFERENCES bms.users(id),
    
    -- 결제 정보
    total_amount DECIMAL(10,2) DEFAULT 0,
    payment_status VARCHAR(20) DEFAULT 'PENDING' CHECK (payment_status IN ('PENDING', 'PAID', 'CANCELLED', 'REFUNDED')),
    payment_method VARCHAR(50),
    paid_at TIMESTAMP,
    
    -- 서비스 제공 정보
    service_provider_id BIGINT REFERENCES bms.employees(employee_id),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    -- 취소 정보
    cancelled_at TIMESTAMP,
    cancelled_by BIGINT REFERENCES bms.users(id),
    cancellation_reason TEXT,
    
    -- 특별 요청사항
    special_requests TEXT,
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id)
);

-- 서비스 피드백 테이블
CREATE TABLE IF NOT EXISTS bms.service_feedback (
    feedback_id BIGSERIAL PRIMARY KEY,
    booking_id BIGINT NOT NULL REFERENCES bms.service_bookings(booking_id) ON DELETE CASCADE,
    
    -- 평가 정보
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
    service_quality_rating INTEGER CHECK (service_quality_rating >= 1 AND service_quality_rating <= 5),
    staff_courtesy_rating INTEGER CHECK (staff_courtesy_rating >= 1 AND staff_courtesy_rating <= 5),
    facility_rating INTEGER CHECK (facility_rating >= 1 AND facility_rating <= 5),
    
    -- 피드백 내용
    positive_feedback TEXT,
    improvement_suggestions TEXT,
    would_recommend BOOLEAN,
    
    -- 추가 의견
    additional_comments TEXT,
    
    -- 피드백 제출 정보
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    submitted_by BIGINT REFERENCES bms.users(id)
);

-- 서비스 이용 통계 테이블
CREATE TABLE IF NOT EXISTS bms.service_usage_statistics (
    stat_id BIGSERIAL PRIMARY KEY,
    service_id BIGINT NOT NULL REFERENCES bms.services(service_id),
    
    -- 통계 기간
    stat_date DATE NOT NULL,
    stat_period VARCHAR(20) NOT NULL CHECK (stat_period IN ('DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY')),
    
    -- 이용 통계
    total_bookings INTEGER DEFAULT 0,
    confirmed_bookings INTEGER DEFAULT 0,
    completed_bookings INTEGER DEFAULT 0,
    cancelled_bookings INTEGER DEFAULT 0,
    no_show_bookings INTEGER DEFAULT 0,
    
    -- 수익 통계
    total_revenue DECIMAL(12,2) DEFAULT 0,
    average_rating DECIMAL(3,2),
    
    -- 자동 생성 시간
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_announcement_categories_company ON bms.announcement_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_announcement_categories_active ON bms.announcement_categories(is_active);

CREATE INDEX IF NOT EXISTS idx_announcements_company ON bms.announcements(company_id);
CREATE INDEX IF NOT EXISTS idx_announcements_building ON bms.announcements(building_id);
CREATE INDEX IF NOT EXISTS idx_announcements_category ON bms.announcements(category_id);
CREATE INDEX IF NOT EXISTS idx_announcements_status ON bms.announcements(announcement_status);
CREATE INDEX IF NOT EXISTS idx_announcements_published_at ON bms.announcements(published_at);
CREATE INDEX IF NOT EXISTS idx_announcements_expires_at ON bms.announcements(expires_at);
CREATE INDEX IF NOT EXISTS idx_announcements_target_audience ON bms.announcements(target_audience);
CREATE INDEX IF NOT EXISTS idx_announcements_urgent ON bms.announcements(is_urgent);
CREATE INDEX IF NOT EXISTS idx_announcements_pinned ON bms.announcements(is_pinned);

CREATE INDEX IF NOT EXISTS idx_announcement_targets_announcement ON bms.announcement_targets(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_targets_type_entity ON bms.announcement_targets(target_type, target_entity_id);

CREATE INDEX IF NOT EXISTS idx_announcement_attachments_announcement ON bms.announcement_attachments(announcement_id);

CREATE INDEX IF NOT EXISTS idx_announcement_views_announcement ON bms.announcement_views(announcement_id);
CREATE INDEX IF NOT EXISTS idx_announcement_views_viewer ON bms.announcement_views(viewer_id, viewed_at);

CREATE INDEX IF NOT EXISTS idx_notifications_company ON bms.notifications(company_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON bms.notifications(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON bms.notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON bms.notifications(notification_status);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled_at ON bms.notifications(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_notifications_related_entity ON bms.notifications(related_entity_type, related_entity_id);

CREATE INDEX IF NOT EXISTS idx_notification_delivery_history_notification ON bms.notification_delivery_history(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_delivery_history_channel ON bms.notification_delivery_history(channel);

CREATE INDEX IF NOT EXISTS idx_notification_receipts_notification ON bms.notification_receipts(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_receipts_recipient ON bms.notification_receipts(recipient_id);

CREATE INDEX IF NOT EXISTS idx_employees_company ON bms.employees(company_id);
CREATE INDEX IF NOT EXISTS idx_employees_user ON bms.employees(user_id);
CREATE INDEX IF NOT EXISTS idx_employees_status ON bms.employees(employment_status);
CREATE INDEX IF NOT EXISTS idx_employees_department ON bms.employees(department);
CREATE INDEX IF NOT EXISTS idx_employees_hire_date ON bms.employees(hire_date);

CREATE INDEX IF NOT EXISTS idx_services_company ON bms.services(company_id);
CREATE INDEX IF NOT EXISTS idx_services_building ON bms.services(building_id);
CREATE INDEX IF NOT EXISTS idx_services_category ON bms.services(service_category);
CREATE INDEX IF NOT EXISTS idx_services_status ON bms.services(service_status);
CREATE INDEX IF NOT EXISTS idx_services_type ON bms.services(service_type);

CREATE INDEX IF NOT EXISTS idx_service_bookings_service ON bms.service_bookings(service_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_booker ON bms.service_bookings(booker_id);
CREATE INDEX IF NOT EXISTS idx_service_bookings_date ON bms.service_bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_service_bookings_status ON bms.service_bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_service_bookings_provider ON bms.service_bookings(service_provider_id);

CREATE INDEX IF NOT EXISTS idx_service_feedback_booking ON bms.service_feedback(booking_id);
CREATE INDEX IF NOT EXISTS idx_service_feedback_rating ON bms.service_feedback(overall_rating);

CREATE INDEX IF NOT EXISTS idx_service_usage_statistics_service ON bms.service_usage_statistics(service_id);
CREATE INDEX IF NOT EXISTS idx_service_usage_statistics_date ON bms.service_usage_statistics(stat_date);
CREATE INDEX IF NOT EXISTS idx_service_usage_statistics_period ON bms.service_usage_statistics(stat_period);

-- 공지사항 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_announcement_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(announcement_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.announcements 
    WHERE announcement_number LIKE 'A' || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 공지번호 생성 (A + YYYYMM + 4자리 순번)
    new_number := 'A' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.announcement_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 공지사항 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_announcement_number ON bms.announcements;
CREATE TRIGGER trg_generate_announcement_number
    BEFORE INSERT ON bms.announcements
    FOR EACH ROW
    WHEN (NEW.announcement_number IS NULL OR NEW.announcement_number = '')
    EXECUTE FUNCTION bms.generate_announcement_number();

-- 알림 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_notification_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(notification_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.notifications 
    WHERE notification_number LIKE 'N' || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 알림번호 생성 (N + YYYYMM + 4자리 순번)
    new_number := 'N' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.notification_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 알림 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_notification_number ON bms.notifications;
CREATE TRIGGER trg_generate_notification_number
    BEFORE INSERT ON bms.notifications
    FOR EACH ROW
    WHEN (NEW.notification_number IS NULL OR NEW.notification_number = '')
    EXECUTE FUNCTION bms.generate_notification_number();

-- 직원 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_employee_number()
RETURNS TRIGGER AS $$
DECLARE
    year_text TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYY 형식으로 년도 생성
    year_text := TO_CHAR(CURRENT_DATE, 'YYYY');
    
    -- 해당 년도의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(employee_number FROM 6) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.employees 
    WHERE employee_number LIKE 'E' || year_text || '%'
      AND company_id = NEW.company_id;
    
    -- 직원번호 생성 (E + YYYY + 4자리 순번)
    new_number := 'E' || year_text || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.employee_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 직원 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_employee_number ON bms.employees;
CREATE TRIGGER trg_generate_employee_number
    BEFORE INSERT ON bms.employees
    FOR EACH ROW
    WHEN (NEW.employee_number IS NULL OR NEW.employee_number = '')
    EXECUTE FUNCTION bms.generate_employee_number();

-- 서비스 예약 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_booking_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산
    SELECT COALESCE(MAX(CAST(SUBSTRING(booking_number FROM 8) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.service_bookings 
    WHERE booking_number LIKE 'B' || year_month || '%';
    
    -- 예약번호 생성 (B + YYYYMM + 4자리 순번)
    new_number := 'B' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.booking_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 서비스 예약 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_booking_number ON bms.service_bookings;
CREATE TRIGGER trg_generate_booking_number
    BEFORE INSERT ON bms.service_bookings
    FOR EACH ROW
    WHEN (NEW.booking_number IS NULL OR NEW.booking_number = '')
    EXECUTE FUNCTION bms.generate_booking_number();

-- 공지사항 조회수 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_announcement_view_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE bms.announcements 
    SET view_count = view_count + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE announcement_id = NEW.announcement_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 공지사항 조회수 업데이트 트리거
DROP TRIGGER IF EXISTS trg_update_announcement_view_count ON bms.announcement_views;
CREATE TRIGGER trg_update_announcement_view_count
    AFTER INSERT ON bms.announcement_views
    FOR EACH ROW
    EXECUTE FUNCTION bms.update_announcement_view_count();

-- 첨부파일 존재 여부 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_announcement_attachments_flag()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE bms.announcements 
        SET has_attachments = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE announcement_id = NEW.announcement_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE bms.announcements 
        SET has_attachments = (
            SELECT COUNT(*) > 0 
            FROM bms.announcement_attachments 
            WHERE announcement_id = OLD.announcement_id
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE announcement_id = OLD.announcement_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 첨부파일 존재 여부 업데이트 트리거
DROP TRIGGER IF EXISTS trg_update_announcement_attachments_flag ON bms.announcement_attachments;
CREATE TRIGGER trg_update_announcement_attachments_flag
    AFTER INSERT OR DELETE ON bms.announcement_attachments
    FOR EACH ROW
    EXECUTE FUNCTION bms.update_announcement_attachments_flag();

-- 서비스 예약 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.update_booking_timestamps()
RETURNS TRIGGER AS $$
BEGIN
    -- 확인 시간 기록
    IF OLD.booking_status != 'CONFIRMED' AND NEW.booking_status = 'CONFIRMED' THEN
        NEW.confirmed_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- 서비스 시작 시간 기록
    IF OLD.booking_status != 'IN_PROGRESS' AND NEW.booking_status = 'IN_PROGRESS' THEN
        NEW.started_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- 서비스 완료 시간 기록
    IF OLD.booking_status != 'COMPLETED' AND NEW.booking_status = 'COMPLETED' THEN
        NEW.completed_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- 취소 시간 기록
    IF OLD.booking_status != 'CANCELLED' AND NEW.booking_status = 'CANCELLED' THEN
        NEW.cancelled_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 서비스 예약 상태 변경 이력 트리거
DROP TRIGGER IF EXISTS trg_update_booking_timestamps ON bms.service_bookings;
CREATE TRIGGER trg_update_booking_timestamps
    BEFORE UPDATE ON bms.service_bookings
    FOR EACH ROW
    EXECUTE FUNCTION bms.update_booking_timestamps();

-- 기본 공지사항 분류 데이터 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_announcement_categories(p_company_id BIGINT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.announcement_categories (company_id, category_code, category_name, description, icon, color) VALUES
    (p_company_id, 'GENERAL', '일반 공지', '일반적인 공지사항', 'info-circle', 'blue'),
    (p_company_id, 'MAINTENANCE', '시설 공지', '시설 점검, 공사 관련 공지', 'tools', 'orange'),
    (p_company_id, 'EVENT', '행사 공지', '건물 내 행사, 이벤트 공지', 'calendar', 'green'),
    (p_company_id, 'EMERGENCY', '긴급 공지', '긴급상황, 비상사태 공지', 'exclamation-triangle', 'red'),
    (p_company_id, 'BILLING', '요금 공지', '관리비, 임대료 관련 공지', 'credit-card', 'purple'),
    (p_company_id, 'POLICY', '정책 공지', '관리 정책, 규정 변경 공지', 'file-text', 'gray'),
    (p_company_id, 'SAFETY', '안전 공지', '안전 수칙, 주의사항 공지', 'shield', 'yellow')
    ON CONFLICT (company_id, category_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 기본 서비스 데이터 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_services(p_company_id BIGINT, p_building_id BIGINT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.services (company_id, building_id, service_code, service_name, service_category, service_description, service_type, price, duration_minutes, max_capacity, operating_hours, created_by) VALUES
    (p_company_id, p_building_id, 'CLEANING', '청소 서비스', '생활 서비스', '세대 내 청소 서비스', 'PAID', 50000, 120, 1, '{"monday": {"start": "09:00", "end": "18:00"}, "tuesday": {"start": "09:00", "end": "18:00"}, "wednesday": {"start": "09:00", "end": "18:00"}, "thursday": {"start": "09:00", "end": "18:00"}, "friday": {"start": "09:00", "end": "18:00"}}'::jsonb, 1),
    (p_company_id, p_building_id, 'LAUNDRY', '세탁 서비스', '생활 서비스', '의류 세탁 및 드라이클리닝', 'PAID', 15000, 60, 10, '{"monday": {"start": "08:00", "end": "20:00"}, "tuesday": {"start": "08:00", "end": "20:00"}, "wednesday": {"start": "08:00", "end": "20:00"}, "thursday": {"start": "08:00", "end": "20:00"}, "friday": {"start": "08:00", "end": "20:00"}, "saturday": {"start": "09:00", "end": "17:00"}}'::jsonb, 1),
    (p_company_id, p_building_id, 'DELIVERY', '택배 보관', '편의 서비스', '택배 수령 및 보관 서비스', 'FREE', 0, 30, 50, '{"monday": {"start": "00:00", "end": "23:59"}, "tuesday": {"start": "00:00", "end": "23:59"}, "wednesday": {"start": "00:00", "end": "23:59"}, "thursday": {"start": "00:00", "end": "23:59"}, "friday": {"start": "00:00", "end": "23:59"}, "saturday": {"start": "00:00", "end": "23:59"}, "sunday": {"start": "00:00", "end": "23:59"}}'::jsonb, 1),
    (p_company_id, p_building_id, 'MEETING_ROOM', '회의실 대여', '시설 서비스', '공용 회의실 대여 서비스', 'PAID', 20000, 60, 8, '{"monday": {"start": "09:00", "end": "22:00"}, "tuesday": {"start": "09:00", "end": "22:00"}, "wednesday": {"start": "09:00", "end": "22:00"}, "thursday": {"start": "09:00", "end": "22:00"}, "friday": {"start": "09:00", "end": "22:00"}, "saturday": {"start": "10:00", "end": "18:00"}, "sunday": {"start": "10:00", "end": "18:00"}}'::jsonb, 1)
    ON CONFLICT (service_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.announcement_categories IS '공지사항 분류 테이블 - 공지사항 유형별 분류 관리';
COMMENT ON TABLE bms.announcements IS '공지사항 테이블 - 건물별 공지사항 등록 및 관리';
COMMENT ON TABLE bms.announcement_targets IS '공지사항 대상자 테이블 - 맞춤형 공지사항 대상 지정';
COMMENT ON TABLE bms.announcement_attachments IS '공지사항 첨부파일 테이블 - 공지사항 관련 첨부 파일 관리';
COMMENT ON TABLE bms.announcement_views IS '공지사항 조회 이력 테이블 - 공지사항 조회 통계 관리';
COMMENT ON TABLE bms.notifications IS '알림 테이블 - 다양한 채널을 통한 알림 발송 관리';
COMMENT ON TABLE bms.notification_delivery_history IS '알림 발송 이력 테이블 - 채널별 발송 결과 기록';
COMMENT ON TABLE bms.notification_receipts IS '알림 수신 확인 테이블 - 수신자별 알림 확인 상태';
COMMENT ON TABLE bms.employees IS '직원 테이블 - 관리사무소 직원 정보 관리';
COMMENT ON TABLE bms.services IS '서비스 테이블 - 입주자 대상 서비스 정의';
COMMENT ON TABLE bms.service_bookings IS '서비스 예약 테이블 - 서비스 예약 및 이용 관리';
COMMENT ON TABLE bms.service_feedback IS '서비스 피드백 테이블 - 서비스 이용 후 만족도 및 피드백';
COMMENT ON TABLE bms.service_usage_statistics IS '서비스 이용 통계 테이블 - 서비스별 이용 현황 통계';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.announcements.announcement_number IS '공지 번호 - A + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.announcements.target_audience IS '공지 대상 - ALL(전체), TENANTS(임차인), OWNERS(임대인), STAFF(직원) 등';
COMMENT ON COLUMN bms.announcements.is_pinned IS '상단 고정 여부 - true시 공지사항 목록 상단에 고정 표시';
COMMENT ON COLUMN bms.announcements.view_count IS '조회수 - announcement_views 테이블 INSERT 시 자동 증가';

COMMENT ON COLUMN bms.notifications.notification_number IS '알림 번호 - N + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.notifications.channels IS '발송 채널 배열 - IN_APP, EMAIL, SMS, PUSH 중 복수 선택 가능';
COMMENT ON COLUMN bms.notifications.priority IS '알림 우선순위 - 1(낮음) ~ 5(높음), 높을수록 우선 발송';

COMMENT ON COLUMN bms.employees.employee_number IS '직원 번호 - E + YYYY + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.employees.performance_rating IS '성과 평가 - 0.0 ~ 5.0 점수';
COMMENT ON COLUMN bms.employees.skills IS 'JSON 형태로 저장된 보유 기술 정보';
COMMENT ON COLUMN bms.employees.certifications IS 'JSON 형태로 저장된 자격증 정보';

COMMENT ON COLUMN bms.services.operating_hours IS 'JSON 형태로 저장된 요일별 운영 시간';
COMMENT ON COLUMN bms.services.provider_info IS 'JSON 형태로 저장된 서비스 제공업체 정보';

COMMENT ON COLUMN bms.service_bookings.booking_number IS '예약 번호 - B + YYYYMM + 4자리 순번으로 자동 생성';
COMMENT ON COLUMN bms.service_bookings.duration_minutes IS '서비스 이용 시간 (분)';
COMMENT ON COLUMN bms.service_bookings.participant_count IS '참여 인원 수';