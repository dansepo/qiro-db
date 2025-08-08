-- =====================================================
-- 민원 및 회계 관리 시스템 - 민원 관리 테이블
-- 작성일: 2025-01-30
-- 요구사항: 1.1, 1.2, 2.1 - 민원 접수, 처리, 만족도 관리
-- =====================================================

-- 기존 ENUM 타입이 존재하는지 확인하고 없으면 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'complaint_priority') THEN
        CREATE TYPE complaint_priority AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'complaint_status') THEN
        CREATE TYPE complaint_status AS ENUM ('RECEIVED', 'ASSIGNED', 'IN_PROGRESS', 'PENDING_INFO', 'RESOLVED', 'CLOSED', 'CANCELLED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'complaint_channel') THEN
        CREATE TYPE complaint_channel AS ENUM ('PHONE', 'EMAIL', 'APP', 'VISIT', 'WEB', 'SMS');
    END IF;
END $$;

-- 민원 분류 테이블
CREATE TABLE IF NOT EXISTS bms.complaint_categories (
    category_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    parent_category_id BIGINT REFERENCES bms.complaint_categories(category_id),
    description TEXT,
    default_priority complaint_priority DEFAULT 'MEDIUM',
    default_due_hours INTEGER DEFAULT 72,
    auto_assign_rules JSONB,
    escalation_rules JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_complaint_categories_company_code UNIQUE(company_id, category_code)
);

-- 민원 기본 정보 테이블
CREATE TABLE IF NOT EXISTS bms.complaints (
    complaint_id BIGSERIAL PRIMARY KEY,
    complaint_number VARCHAR(20) UNIQUE NOT NULL,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    building_id BIGINT REFERENCES bms.buildings(id),
    unit_id BIGINT REFERENCES bms.units(id),
    complaint_category_id BIGINT NOT NULL REFERENCES bms.complaint_categories(category_id),
    
    -- 신고자 정보
    reporter_id BIGINT REFERENCES bms.users(id),
    reporter_name VARCHAR(255) NOT NULL,
    reporter_phone VARCHAR(20),
    reporter_email VARCHAR(255),
    reporter_type VARCHAR(20) DEFAULT 'TENANT',
    
    -- 민원 내용
    complaint_title VARCHAR(255) NOT NULL,
    complaint_description TEXT NOT NULL,
    location_detail VARCHAR(255),
    
    -- 접수 정보
    complaint_channel complaint_channel NOT NULL DEFAULT 'WEB',
    priority_level complaint_priority NOT NULL DEFAULT 'MEDIUM',
    complaint_status complaint_status NOT NULL DEFAULT 'RECEIVED',
    urgency_reason TEXT,
    
    -- 담당자 배정
    assigned_to BIGINT REFERENCES bms.users(id),
    assigned_at TIMESTAMP,
    assigned_by BIGINT REFERENCES bms.users(id),
    
    -- SLA 관리
    due_date TIMESTAMP NOT NULL,
    sla_hours INTEGER NOT NULL DEFAULT 72,
    is_sla_breached BOOLEAN DEFAULT false,
    sla_breach_reason TEXT,
    
    -- 처리 결과
    resolution_description TEXT,
    resolution_cost DECIMAL(12,2) DEFAULT 0,
    satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
    satisfaction_comment TEXT,
    
    -- 일정 관리
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    closed_at TIMESTAMP,
    
    -- 감사 필드
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    -- 제약조건
    CONSTRAINT chk_complaints_resolution_required CHECK (
        (complaint_status IN ('RESOLVED', 'CLOSED') AND resolution_description IS NOT NULL) OR 
        (complaint_status NOT IN ('RESOLVED', 'CLOSED'))
    ),
    CONSTRAINT chk_complaints_resolved_at_required CHECK (
        (complaint_status IN ('RESOLVED', 'CLOSED') AND resolved_at IS NOT NULL) OR 
        (complaint_status NOT IN ('RESOLVED', 'CLOSED'))
    ),
    CONSTRAINT chk_complaints_satisfaction_with_resolved CHECK (
        (satisfaction_rating IS NOT NULL AND complaint_status IN ('RESOLVED', 'CLOSED')) OR
        (satisfaction_rating IS NULL)
    )
);

-- 민원 첨부파일 테이블
CREATE TABLE IF NOT EXISTS bms.complaint_attachments (
    attachment_id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES bms.complaints(complaint_id) ON DELETE CASCADE,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(100) NOT NULL,
    mime_type VARCHAR(100),
    uploaded_by BIGINT NOT NULL REFERENCES bms.users(id),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 민원 소통 기록 테이블
CREATE TABLE IF NOT EXISTS bms.complaint_communications (
    communication_id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES bms.complaints(complaint_id) ON DELETE CASCADE,
    sender_id BIGINT REFERENCES bms.users(id),
    sender_name VARCHAR(255) NOT NULL,
    receiver_id BIGINT REFERENCES bms.users(id),
    receiver_name VARCHAR(255),
    message_type VARCHAR(20) NOT NULL DEFAULT 'TEXT',
    message_content TEXT NOT NULL,
    attachment_files JSONB,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    is_internal BOOLEAN DEFAULT false,
    created_by BIGINT REFERENCES bms.users(id)
);

-- 민원 처리 이력 테이블
CREATE TABLE IF NOT EXISTS bms.complaint_status_history (
    history_id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES bms.complaints(complaint_id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    previous_status complaint_status,
    new_status complaint_status,
    previous_assignee BIGINT REFERENCES bms.users(id),
    new_assignee BIGINT REFERENCES bms.users(id),
    comment TEXT,
    action_by BIGINT NOT NULL REFERENCES bms.users(id),
    action_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 만족도 조사 테이블
CREATE TABLE IF NOT EXISTS bms.satisfaction_surveys (
    survey_id BIGSERIAL PRIMARY KEY,
    complaint_id BIGINT NOT NULL REFERENCES bms.complaints(complaint_id) ON DELETE CASCADE,
    survey_sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    survey_completed_at TIMESTAMP,
    overall_rating INTEGER CHECK (overall_rating >= 1 AND overall_rating <= 5),
    response_time_rating INTEGER CHECK (response_time_rating >= 1 AND response_time_rating <= 5),
    resolution_quality_rating INTEGER CHECK (resolution_quality_rating >= 1 AND resolution_quality_rating <= 5),
    staff_courtesy_rating INTEGER CHECK (staff_courtesy_rating >= 1 AND staff_courtesy_rating <= 5),
    improvement_suggestions TEXT,
    would_recommend BOOLEAN,
    additional_comments TEXT,
    is_completed BOOLEAN DEFAULT false,
    created_by BIGINT REFERENCES bms.users(id)
);

-- 피드백 응답 테이블
CREATE TABLE IF NOT EXISTS bms.feedback_responses (
    response_id BIGSERIAL PRIMARY KEY,
    survey_id BIGINT NOT NULL REFERENCES bms.satisfaction_surveys(survey_id) ON DELETE CASCADE,
    question_code VARCHAR(50) NOT NULL,
    question_text TEXT NOT NULL,
    response_type VARCHAR(20) NOT NULL, -- RATING, TEXT, BOOLEAN, CHOICE
    response_value TEXT,
    numeric_value INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_complaint_categories_company ON bms.complaint_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_complaint_categories_parent ON bms.complaint_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_complaint_categories_active ON bms.complaint_categories(is_active);

CREATE INDEX IF NOT EXISTS idx_complaints_company ON bms.complaints(company_id);
CREATE INDEX IF NOT EXISTS idx_complaints_building ON bms.complaints(building_id);
CREATE INDEX IF NOT EXISTS idx_complaints_unit ON bms.complaints(unit_id);
CREATE INDEX IF NOT EXISTS idx_complaints_category ON bms.complaints(complaint_category_id);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON bms.complaints(complaint_status);
CREATE INDEX IF NOT EXISTS idx_complaints_priority ON bms.complaints(priority_level);
CREATE INDEX IF NOT EXISTS idx_complaints_assigned_to ON bms.complaints(assigned_to);
CREATE INDEX IF NOT EXISTS idx_complaints_reporter ON bms.complaints(reporter_id);
CREATE INDEX IF NOT EXISTS idx_complaints_created_at ON bms.complaints(created_at);
CREATE INDEX IF NOT EXISTS idx_complaints_due_date ON bms.complaints(due_date);
CREATE INDEX IF NOT EXISTS idx_complaints_number ON bms.complaints(complaint_number);
CREATE INDEX IF NOT EXISTS idx_complaints_sla_breach ON bms.complaints(is_sla_breached);

CREATE INDEX IF NOT EXISTS idx_complaint_attachments_complaint ON bms.complaint_attachments(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_attachments_uploaded_by ON bms.complaint_attachments(uploaded_by);

CREATE INDEX IF NOT EXISTS idx_complaint_communications_complaint ON bms.complaint_communications(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_communications_sender ON bms.complaint_communications(sender_id);
CREATE INDEX IF NOT EXISTS idx_complaint_communications_receiver ON bms.complaint_communications(receiver_id);
CREATE INDEX IF NOT EXISTS idx_complaint_communications_sent_at ON bms.complaint_communications(sent_at);

CREATE INDEX IF NOT EXISTS idx_complaint_status_history_complaint ON bms.complaint_status_history(complaint_id);
CREATE INDEX IF NOT EXISTS idx_complaint_status_history_action_by ON bms.complaint_status_history(action_by);
CREATE INDEX IF NOT EXISTS idx_complaint_status_history_action_at ON bms.complaint_status_history(action_at);

CREATE INDEX IF NOT EXISTS idx_satisfaction_surveys_complaint ON bms.satisfaction_surveys(complaint_id);
CREATE INDEX IF NOT EXISTS idx_satisfaction_surveys_completed ON bms.satisfaction_surveys(is_completed);
CREATE INDEX IF NOT EXISTS idx_satisfaction_surveys_sent_at ON bms.satisfaction_surveys(survey_sent_at);

CREATE INDEX IF NOT EXISTS idx_feedback_responses_survey ON bms.feedback_responses(survey_id);
CREATE INDEX IF NOT EXISTS idx_feedback_responses_question ON bms.feedback_responses(question_code);

-- 민원 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_complaint_number()
RETURNS TRIGGER AS $$
DECLARE
    year_month TEXT;
    sequence_num INTEGER;
    new_number TEXT;
BEGIN
    -- YYYYMM 형식으로 년월 생성
    year_month := TO_CHAR(CURRENT_DATE, 'YYYYMM');
    
    -- 해당 월의 순번 계산 (회사별로 분리)
    SELECT COALESCE(MAX(CAST(SUBSTRING(complaint_number FROM 9) AS INTEGER)), 0) + 1
    INTO sequence_num
    FROM bms.complaints 
    WHERE complaint_number LIKE 'C' || year_month || '%'
      AND company_id = NEW.company_id;
    
    -- 민원번호 생성 (C + YYYYMM + 4자리 순번)
    new_number := 'C' || year_month || LPAD(sequence_num::TEXT, 4, '0');
    
    NEW.complaint_number := new_number;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 민원 번호 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_generate_complaint_number ON bms.complaints;
CREATE TRIGGER trg_generate_complaint_number
    BEFORE INSERT ON bms.complaints
    FOR EACH ROW
    WHEN (NEW.complaint_number IS NULL OR NEW.complaint_number = '')
    EXECUTE FUNCTION bms.generate_complaint_number();

-- SLA 계산 및 설정 함수
CREATE OR REPLACE FUNCTION bms.set_complaint_sla()
RETURNS TRIGGER AS $$
DECLARE
    default_hours INTEGER;
BEGIN
    -- 민원 분류의 기본 SLA 시간 가져오기
    SELECT default_due_hours INTO default_hours
    FROM bms.complaint_categories
    WHERE category_id = NEW.complaint_category_id;
    
    -- SLA 시간 설정 (우선순위에 따라 조정)
    CASE NEW.priority_level
        WHEN 'URGENT' THEN NEW.sla_hours := LEAST(default_hours, 4);
        WHEN 'HIGH' THEN NEW.sla_hours := LEAST(default_hours, 24);
        WHEN 'MEDIUM' THEN NEW.sla_hours := default_hours;
        WHEN 'LOW' THEN NEW.sla_hours := default_hours * 2;
        ELSE NEW.sla_hours := default_hours;
    END CASE;
    
    -- 만료 시간 계산
    NEW.due_date := NEW.created_at + (NEW.sla_hours || ' hours')::INTERVAL;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SLA 설정 트리거
DROP TRIGGER IF EXISTS trg_set_complaint_sla ON bms.complaints;
CREATE TRIGGER trg_set_complaint_sla
    BEFORE INSERT ON bms.complaints
    FOR EACH ROW
    EXECUTE FUNCTION bms.set_complaint_sla();

-- SLA 위반 체크 함수
CREATE OR REPLACE FUNCTION bms.check_sla_breach()
RETURNS TRIGGER AS $$
BEGIN
    -- 해결되지 않은 민원의 SLA 위반 체크
    IF NEW.complaint_status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') AND 
       NEW.due_date < CURRENT_TIMESTAMP THEN
        NEW.is_sla_breached := true;
        IF NEW.sla_breach_reason IS NULL THEN
            NEW.sla_breach_reason := 'SLA 기한 초과';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- SLA 위반 체크 트리거
DROP TRIGGER IF EXISTS trg_check_sla_breach ON bms.complaints;
CREATE TRIGGER trg_check_sla_breach
    BEFORE UPDATE ON bms.complaints
    FOR EACH ROW
    EXECUTE FUNCTION bms.check_sla_breach();

-- 민원 이력 자동 기록 함수
CREATE OR REPLACE FUNCTION bms.record_complaint_history()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태 변경 시 이력 기록
    IF TG_OP = 'UPDATE' AND OLD.complaint_status != NEW.complaint_status THEN
        INSERT INTO bms.complaint_status_history (
            complaint_id, action_type, previous_status, new_status, 
            action_by, action_at
        ) VALUES (
            NEW.complaint_id, 'STATUS_CHANGE', OLD.complaint_status, NEW.complaint_status,
            COALESCE(NEW.updated_by, NEW.created_by), CURRENT_TIMESTAMP
        );
    END IF;
    
    -- 담당자 변경 시 이력 기록
    IF TG_OP = 'UPDATE' AND COALESCE(OLD.assigned_to, 0) != COALESCE(NEW.assigned_to, 0) THEN
        INSERT INTO bms.complaint_status_history (
            complaint_id, action_type, previous_assignee, new_assignee,
            action_by, action_at
        ) VALUES (
            NEW.complaint_id, 'ASSIGNMENT', OLD.assigned_to, NEW.assigned_to,
            COALESCE(NEW.updated_by, NEW.created_by), CURRENT_TIMESTAMP
        );
        
        -- 담당자 배정 시간 기록
        IF NEW.assigned_to IS NOT NULL AND OLD.assigned_to IS NULL THEN
            NEW.assigned_at := CURRENT_TIMESTAMP;
        END IF;
    END IF;
    
    -- 최초 응답 시간 기록
    IF TG_OP = 'UPDATE' AND OLD.complaint_status = 'RECEIVED' AND NEW.complaint_status != 'RECEIVED' THEN
        NEW.first_response_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- 해결 시간 기록
    IF TG_OP = 'UPDATE' AND OLD.complaint_status NOT IN ('RESOLVED', 'CLOSED') AND NEW.complaint_status IN ('RESOLVED', 'CLOSED') THEN
        NEW.resolved_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- 종료 시간 기록
    IF TG_OP = 'UPDATE' AND OLD.complaint_status != 'CLOSED' AND NEW.complaint_status = 'CLOSED' THEN
        NEW.closed_at := CURRENT_TIMESTAMP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 민원 이력 기록 트리거
DROP TRIGGER IF EXISTS trg_record_complaint_history ON bms.complaints;
CREATE TRIGGER trg_record_complaint_history
    BEFORE UPDATE ON bms.complaints
    FOR EACH ROW
    EXECUTE FUNCTION bms.record_complaint_history();

-- 만족도 조사 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.create_satisfaction_survey()
RETURNS TRIGGER AS $$
BEGIN
    -- 민원이 해결될 때 만족도 조사 자동 생성
    IF NEW.complaint_status = 'RESOLVED' AND OLD.complaint_status != 'RESOLVED' THEN
        INSERT INTO bms.satisfaction_surveys (
            complaint_id, survey_sent_at, created_by
        ) VALUES (
            NEW.complaint_id, CURRENT_TIMESTAMP, NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 만족도 조사 자동 생성 트리거
DROP TRIGGER IF EXISTS trg_create_satisfaction_survey ON bms.complaints;
CREATE TRIGGER trg_create_satisfaction_survey
    AFTER UPDATE ON bms.complaints
    FOR EACH ROW
    EXECUTE FUNCTION bms.create_satisfaction_survey();

-- 기본 민원 분류 데이터 삽입 함수
CREATE OR REPLACE FUNCTION bms.insert_default_complaint_categories(p_company_id BIGINT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.complaint_categories (company_id, category_code, category_name, description, default_priority, default_due_hours) VALUES
    (p_company_id, 'FACILITY', '시설 관련', '엘리베이터, 보일러, 전기, 수도 등 시설 문제', 'HIGH', 24),
    (p_company_id, 'NOISE', '소음 관련', '층간소음, 공사소음, 기타 소음 문제', 'MEDIUM', 48),
    (p_company_id, 'PARKING', '주차 관련', '주차 공간, 주차 위반, 주차 요금 문제', 'MEDIUM', 48),
    (p_company_id, 'CLEANING', '청소 관련', '공용구역 청소, 쓰레기 처리 문제', 'LOW', 72),
    (p_company_id, 'SECURITY', '보안 관련', '출입통제, CCTV, 보안 문제', 'HIGH', 12),
    (p_company_id, 'BILLING', '요금 관련', '관리비, 임대료, 기타 요금 문의', 'MEDIUM', 48),
    (p_company_id, 'NEIGHBOR', '이웃 관련', '이웃 간 분쟁, 공동생활 문제', 'MEDIUM', 72),
    (p_company_id, 'ADMIN', '관리 관련', '관리사무소 업무, 서비스 문의', 'LOW', 72),
    (p_company_id, 'OTHER', '기타', '기타 민원 사항', 'MEDIUM', 48)
    ON CONFLICT (company_id, category_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.complaint_categories IS '민원 분류 테이블 - 민원 유형별 분류 및 기본 SLA 설정';
COMMENT ON TABLE bms.complaints IS '민원 관리 테이블 - 건물 관련 민원 접수 및 처리 관리';
COMMENT ON TABLE bms.complaint_attachments IS '민원 첨부파일 테이블 - 민원 관련 첨부 파일 관리';
COMMENT ON TABLE bms.complaint_communications IS '민원 소통 기록 테이블 - 민원 처리 과정의 의사소통 내역';
COMMENT ON TABLE bms.complaint_status_history IS '민원 처리 이력 테이블 - 민원 처리 과정의 모든 변경 이력';
COMMENT ON TABLE bms.satisfaction_surveys IS '만족도 조사 테이블 - 민원 해결 후 만족도 조사 관리';
COMMENT ON TABLE bms.feedback_responses IS '피드백 응답 테이블 - 만족도 조사의 상세 응답 내역';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.complaints.complaint_number IS '민원 번호 - C + YYYYMM + 4자리 순번 형식으로 자동 생성';
COMMENT ON COLUMN bms.complaints.due_date IS 'SLA 만료 시간 - 민원 접수 시간 + SLA 시간으로 자동 계산';
COMMENT ON COLUMN bms.complaints.is_sla_breached IS 'SLA 위반 여부 - 만료 시간 초과 시 자동으로 true 설정';
COMMENT ON COLUMN bms.complaints.satisfaction_rating IS '만족도 점수 - 1(매우 불만족) ~ 5(매우 만족)';
COMMENT ON COLUMN bms.complaints.priority_level IS '우선순위 - URGENT(긴급), HIGH(높음), MEDIUM(보통), LOW(낮음)';
COMMENT ON COLUMN bms.complaints.complaint_status IS '처리 상태 - RECEIVED(접수), ASSIGNED(배정), IN_PROGRESS(진행중), PENDING_INFO(정보대기), RESOLVED(해결), CLOSED(종료), CANCELLED(취소)';
COMMENT ON COLUMN bms.complaints.complaint_channel IS '접수 채널 - PHONE(전화), EMAIL(이메일), APP(앱), VISIT(방문), WEB(웹), SMS(문자)';

COMMENT ON COLUMN bms.satisfaction_surveys.overall_rating IS '전체 만족도 - 1(매우 불만족) ~ 5(매우 만족)';
COMMENT ON COLUMN bms.satisfaction_surveys.response_time_rating IS '응답 시간 만족도 - 1(매우 불만족) ~ 5(매우 만족)';
COMMENT ON COLUMN bms.satisfaction_surveys.resolution_quality_rating IS '해결 품질 만족도 - 1(매우 불만족) ~ 5(매우 만족)';
COMMENT ON COLUMN bms.satisfaction_surveys.staff_courtesy_rating IS '직원 친절도 - 1(매우 불만족) ~ 5(매우 만족)';