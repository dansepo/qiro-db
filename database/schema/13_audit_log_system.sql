-- =====================================================
-- 감사 로그 시스템 (Audit Log System)
-- 중요 작업에 대한 감사 추적, 사용자 활동 로그, 데이터 변경 이력 관리
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 감사 로그 테이블 생성
-- =====================================================

-- 감사 로그 메인 테이블
CREATE TABLE IF NOT EXISTS audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    session_id VARCHAR(255), -- 세션 식별자
    
    -- 감사 이벤트 정보
    event_type VARCHAR(50) NOT NULL, -- LOGIN, LOGOUT, CREATE, UPDATE, DELETE, ACCESS, etc.
    event_category VARCHAR(50) NOT NULL, -- AUTHENTICATION, DATA_MODIFICATION, ACCESS_CONTROL, etc.
    resource_type VARCHAR(100), -- TABLE_NAME, API_ENDPOINT, etc.
    resource_id VARCHAR(255), -- 리소스의 식별자
    
    -- 이벤트 상세 정보
    event_description TEXT NOT NULL,
    event_data JSONB, -- 상세 데이터 (변경 전/후 값 등)
    
    -- 메타데이터
    ip_address INET,
    user_agent TEXT,
    request_method VARCHAR(10), -- GET, POST, PUT, DELETE, etc.
    request_url TEXT,
    
    -- 결과 정보
    success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    
    -- 시간 정보
    event_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    processing_time_ms INTEGER, -- 처리 시간 (밀리초)
    
    -- 인덱스를 위한 추가 필드
    event_date DATE GENERATED ALWAYS AS (event_timestamp::DATE) STORED,
    
    -- 제약조건
    CONSTRAINT audit_logs_event_type_check 
        CHECK (event_type IN ('LOGIN', 'LOGOUT', 'CREATE', 'UPDATE', 'DELETE', 'ACCESS', 'PERMISSION_CHANGE', 'SYSTEM_CONFIG', 'DATA_EXPORT', 'DATA_IMPORT', 'ERROR')),
    CONSTRAINT audit_logs_event_category_check 
        CHECK (event_category IN ('AUTHENTICATION', 'DATA_MODIFICATION', 'ACCESS_CONTROL', 'SYSTEM_ADMINISTRATION', 'BUSINESS_OPERATION', 'SECURITY', 'ERROR'))
);

-- 사용자 활동 로그 테이블 (더 상세한 사용자 행동 추적)
CREATE TABLE IF NOT EXISTS user_activity_logs (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    session_id VARCHAR(255),
    
    -- 활동 정보
    activity_type VARCHAR(50) NOT NULL, -- PAGE_VIEW, BUTTON_CLICK, FORM_SUBMIT, etc.
    page_url TEXT,
    feature_used VARCHAR(100), -- 사용한 기능명
    action_details JSONB, -- 액션 상세 정보
    
    -- 컨텍스트 정보
    building_group_id UUID REFERENCES building_groups(group_id) ON DELETE SET NULL,
    related_resource_type VARCHAR(100),
    related_resource_id VARCHAR(255),
    
    -- 메타데이터
    ip_address INET,
    user_agent TEXT,
    screen_resolution VARCHAR(20),
    browser_info JSONB,
    
    -- 시간 정보
    activity_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    session_duration_seconds INTEGER, -- 세션 지속 시간
    
    -- 인덱스를 위한 추가 필드
    activity_date DATE GENERATED ALWAYS AS (activity_timestamp::DATE) STORED
);

-- 데이터 변경 이력 테이블
CREATE TABLE IF NOT EXISTS data_change_history (
    change_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    
    -- 변경 대상 정보
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(255) NOT NULL, -- 변경된 레코드의 ID
    operation_type VARCHAR(10) NOT NULL CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    
    -- 변경 데이터
    old_values JSONB, -- 변경 전 값
    new_values JSONB, -- 변경 후 값
    changed_fields TEXT[], -- 변경된 필드 목록
    
    -- 메타데이터
    change_reason TEXT, -- 변경 사유
    change_context JSONB, -- 변경 컨텍스트 (API 호출, 배치 작업 등)
    
    -- 시간 정보
    change_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 인덱스를 위한 추가 필드
    change_date DATE GENERATED ALWAYS AS (change_timestamp::DATE) STORED
);

-- 로그인 시도 로그 테이블 (보안 강화)
CREATE TABLE IF NOT EXISTS login_attempt_logs (
    attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    
    -- 로그인 시도 정보
    email VARCHAR(255) NOT NULL,
    success BOOLEAN NOT NULL,
    failure_reason VARCHAR(100), -- INVALID_PASSWORD, ACCOUNT_LOCKED, etc.
    
    -- 보안 정보
    ip_address INET NOT NULL,
    user_agent TEXT,
    country_code VARCHAR(2), -- 국가 코드 (GeoIP 기반)
    is_suspicious BOOLEAN DEFAULT false, -- 의심스러운 활동 여부
    
    -- 시간 정보
    attempt_timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 인덱스를 위한 추가 필드
    attempt_date DATE GENERATED ALWAYS AS (attempt_timestamp::DATE) STORED
);

-- =====================================================
-- 2. 인덱스 생성
-- =====================================================

-- audit_logs 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_audit_logs_company_date ON audit_logs(company_id, event_date DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_timestamp ON audit_logs(user_id, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event_type ON audit_logs(event_type, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_session ON audit_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_ip ON audit_logs(ip_address);

-- user_activity_logs 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_user_activity_company_date ON user_activity_logs(company_id, activity_date DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_timestamp ON user_activity_logs(user_id, activity_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_session ON user_activity_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_feature ON user_activity_logs(feature_used);

-- data_change_history 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_data_change_company_date ON data_change_history(company_id, change_date DESC);
CREATE INDEX IF NOT EXISTS idx_data_change_table_record ON data_change_history(table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_data_change_user_timestamp ON data_change_history(user_id, change_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_data_change_operation ON data_change_history(operation_type, change_timestamp DESC);

-- login_attempt_logs 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_login_attempt_email_timestamp ON login_attempt_logs(email, attempt_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempt_ip_timestamp ON login_attempt_logs(ip_address, attempt_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_login_attempt_suspicious ON login_attempt_logs(is_suspicious, attempt_timestamp DESC) WHERE is_suspicious = true;
CREATE INDEX IF NOT EXISTS idx_login_attempt_company_date ON login_attempt_logs(company_id, attempt_date DESC);

-- =====================================================
-- 3. Row Level Security (RLS) 정책 설정
-- =====================================================

-- audit_logs 테이블 RLS 설정
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_logs_company_policy ON audit_logs
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY audit_logs_readonly_policy ON audit_logs
    FOR SELECT
    TO readonly_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

CREATE POLICY audit_logs_audit_policy ON audit_logs
    FOR SELECT
    TO audit_role
    USING (true); -- 감사 역할은 모든 로그 조회 가능

CREATE POLICY audit_logs_admin_policy ON audit_logs
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- user_activity_logs 테이블 RLS 설정
ALTER TABLE user_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_activity_logs_company_policy ON user_activity_logs
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY user_activity_logs_self_policy ON user_activity_logs
    FOR SELECT
    TO application_role
    USING (
        user_id = current_setting('app.current_user_id', true)::UUID
        AND company_id = current_setting('app.current_company_id', true)::UUID
    );

CREATE POLICY user_activity_logs_audit_policy ON user_activity_logs
    FOR SELECT
    TO audit_role
    USING (true);

CREATE POLICY user_activity_logs_admin_policy ON user_activity_logs
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- data_change_history 테이블 RLS 설정
ALTER TABLE data_change_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY data_change_history_company_policy ON data_change_history
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY data_change_history_audit_policy ON data_change_history
    FOR SELECT
    TO audit_role
    USING (true);

CREATE POLICY data_change_history_admin_policy ON data_change_history
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- login_attempt_logs 테이블 RLS 설정
ALTER TABLE login_attempt_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY login_attempt_logs_company_policy ON login_attempt_logs
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
        OR company_id IS NULL -- 로그인 실패 시 company_id가 없을 수 있음
    );

CREATE POLICY login_attempt_logs_audit_policy ON login_attempt_logs
    FOR SELECT
    TO audit_role
    USING (true);

CREATE POLICY login_attempt_logs_admin_policy ON login_attempt_logs
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- =====================================================
-- 4. 감사 로그 기록 함수들
-- =====================================================

-- 일반 감사 로그 기록 함수
CREATE OR REPLACE FUNCTION log_audit_event(
    p_event_type VARCHAR(50),
    p_event_category VARCHAR(50),
    p_event_description TEXT,
    p_resource_type VARCHAR(100) DEFAULT NULL,
    p_resource_id VARCHAR(255) DEFAULT NULL,
    p_event_data JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_request_method VARCHAR(10) DEFAULT NULL,
    p_request_url TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL,
    p_processing_time_ms INTEGER DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    audit_id UUID;
    current_company_id UUID;
    current_user_id UUID;
    session_id TEXT;
BEGIN
    -- 현재 컨텍스트 정보 가져오기
    BEGIN
        current_company_id := current_setting('app.current_company_id', true)::UUID;
        current_user_id := current_setting('app.current_user_id', true)::UUID;
        session_id := current_setting('app.session_id', true);
    EXCEPTION WHEN OTHERS THEN
        -- 컨텍스트가 설정되지 않은 경우 NULL로 처리
        current_company_id := NULL;
        current_user_id := NULL;
        session_id := NULL;
    END;
    
    -- 감사 로그 삽입
    INSERT INTO audit_logs (
        company_id, user_id, session_id,
        event_type, event_category, resource_type, resource_id,
        event_description, event_data,
        ip_address, user_agent, request_method, request_url,
        success, error_message, processing_time_ms
    ) VALUES (
        current_company_id, current_user_id, session_id,
        p_event_type, p_event_category, p_resource_type, p_resource_id,
        p_event_description, p_event_data,
        p_ip_address, p_user_agent, p_request_method, p_request_url,
        p_success, p_error_message, p_processing_time_ms
    ) RETURNING audit_id INTO audit_id;
    
    RETURN audit_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자 활동 로그 기록 함수
CREATE OR REPLACE FUNCTION log_user_activity(
    p_activity_type VARCHAR(50),
    p_page_url TEXT DEFAULT NULL,
    p_feature_used VARCHAR(100) DEFAULT NULL,
    p_action_details JSONB DEFAULT NULL,
    p_building_group_id UUID DEFAULT NULL,
    p_related_resource_type VARCHAR(100) DEFAULT NULL,
    p_related_resource_id VARCHAR(255) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_screen_resolution VARCHAR(20) DEFAULT NULL,
    p_browser_info JSONB DEFAULT NULL,
    p_session_duration_seconds INTEGER DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    activity_id UUID;
    current_company_id UUID;
    current_user_id UUID;
    session_id TEXT;
BEGIN
    -- 현재 컨텍스트 정보 가져오기
    current_company_id := current_setting('app.current_company_id', true)::UUID;
    current_user_id := current_setting('app.current_user_id', true)::UUID;
    session_id := current_setting('app.session_id', true);
    
    -- 사용자 활동 로그 삽입
    INSERT INTO user_activity_logs (
        company_id, user_id, session_id,
        activity_type, page_url, feature_used, action_details,
        building_group_id, related_resource_type, related_resource_id,
        ip_address, user_agent, screen_resolution, browser_info,
        session_duration_seconds
    ) VALUES (
        current_company_id, current_user_id, session_id,
        p_activity_type, p_page_url, p_feature_used, p_action_details,
        p_building_group_id, p_related_resource_type, p_related_resource_id,
        p_ip_address, p_user_agent, p_screen_resolution, p_browser_info,
        p_session_duration_seconds
    ) RETURNING activity_id INTO activity_id;
    
    RETURN activity_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 데이터 변경 이력 기록 함수
CREATE OR REPLACE FUNCTION log_data_change(
    p_table_name VARCHAR(100),
    p_record_id VARCHAR(255),
    p_operation_type VARCHAR(10),
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_changed_fields TEXT[] DEFAULT NULL,
    p_change_reason TEXT DEFAULT NULL,
    p_change_context JSONB DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    change_id UUID;
    current_company_id UUID;
    current_user_id UUID;
BEGIN
    -- 현재 컨텍스트 정보 가져오기
    current_company_id := current_setting('app.current_company_id', true)::UUID;
    current_user_id := current_setting('app.current_user_id', true)::UUID;
    
    -- 데이터 변경 이력 삽입
    INSERT INTO data_change_history (
        company_id, user_id,
        table_name, record_id, operation_type,
        old_values, new_values, changed_fields,
        change_reason, change_context
    ) VALUES (
        current_company_id, current_user_id,
        p_table_name, p_record_id, p_operation_type,
        p_old_values, p_new_values, p_changed_fields,
        p_change_reason, p_change_context
    ) RETURNING change_id INTO change_id;
    
    RETURN change_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 로그인 시도 기록 함수
CREATE OR REPLACE FUNCTION log_login_attempt(
    p_email VARCHAR(255),
    p_success BOOLEAN,
    p_failure_reason VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_country_code VARCHAR(2) DEFAULT NULL,
    p_is_suspicious BOOLEAN DEFAULT false
)
RETURNS UUID AS $
DECLARE
    attempt_id UUID;
    user_company_id UUID;
    user_id UUID;
BEGIN
    -- 사용자 정보 조회 (성공한 경우)
    IF p_success THEN
        SELECT u.company_id, u.user_id 
        INTO user_company_id, user_id
        FROM users u 
        WHERE u.email = p_email 
        LIMIT 1;
    END IF;
    
    -- 로그인 시도 로그 삽입
    INSERT INTO login_attempt_logs (
        company_id, user_id, email, success, failure_reason,
        ip_address, user_agent, country_code, is_suspicious
    ) VALUES (
        user_company_id, user_id, p_email, p_success, p_failure_reason,
        p_ip_address, p_user_agent, p_country_code, p_is_suspicious
    ) RETURNING attempt_id INTO attempt_id;
    
    RETURN attempt_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;-
- =====================================================
-- 5. 자동 감사 로그 트리거 함수들
-- =====================================================

-- 일반적인 테이블 변경 감사 트리거 함수
CREATE OR REPLACE FUNCTION audit_table_changes()
RETURNS TRIGGER AS $
DECLARE
    old_values JSONB;
    new_values JSONB;
    changed_fields TEXT[];
    operation_type VARCHAR(10);
BEGIN
    -- 작업 타입 결정
    IF TG_OP = 'DELETE' THEN
        operation_type := 'DELETE';
        old_values := to_jsonb(OLD);
        new_values := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        operation_type := 'UPDATE';
        old_values := to_jsonb(OLD);
        new_values := to_jsonb(NEW);
        
        -- 변경된 필드 찾기
        SELECT array_agg(key) INTO changed_fields
        FROM jsonb_each(old_values) o
        WHERE o.value IS DISTINCT FROM (new_values->o.key);
        
    ELSIF TG_OP = 'INSERT' THEN
        operation_type := 'INSERT';
        old_values := NULL;
        new_values := to_jsonb(NEW);
    END IF;
    
    -- 데이터 변경 이력 기록
    PERFORM log_data_change(
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (OLD.company_id || '_' || COALESCE(OLD.user_id::TEXT, OLD.group_id::TEXT, 'unknown'))
            ELSE (NEW.company_id || '_' || COALESCE(NEW.user_id::TEXT, NEW.group_id::TEXT, 'unknown'))
        END,
        operation_type,
        old_values,
        new_values,
        changed_fields,
        'Automatic audit trigger',
        jsonb_build_object('trigger_name', TG_NAME, 'table_name', TG_TABLE_NAME)
    );
    
    -- 감사 로그 기록
    PERFORM log_audit_event(
        operation_type,
        'DATA_MODIFICATION',
        format('%s operation on %s table', operation_type, TG_TABLE_NAME),
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (OLD.company_id || '_' || COALESCE(OLD.user_id::TEXT, OLD.group_id::TEXT, 'unknown'))
            ELSE (NEW.company_id || '_' || COALESCE(NEW.user_id::TEXT, NEW.group_id::TEXT, 'unknown'))
        END,
        jsonb_build_object(
            'operation', operation_type,
            'table', TG_TABLE_NAME,
            'changed_fields', changed_fields
        )
    );
    
    -- 반환값 결정
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자 로그인/로그아웃 감사 함수
CREATE OR REPLACE FUNCTION audit_user_session(
    p_user_id UUID,
    p_event_type VARCHAR(50), -- 'LOGIN' or 'LOGOUT'
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_session_duration_seconds INTEGER DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    audit_id UUID;
    user_info RECORD;
BEGIN
    -- 사용자 정보 조회
    SELECT u.company_id, u.email, u.full_name
    INTO user_info
    FROM users u
    WHERE u.user_id = p_user_id;
    
    -- 감사 로그 기록
    SELECT log_audit_event(
        p_event_type,
        'AUTHENTICATION',
        format('User %s %s', user_info.email, LOWER(p_event_type)),
        'USER_SESSION',
        p_user_id::TEXT,
        jsonb_build_object(
            'user_email', user_info.email,
            'user_name', user_info.full_name,
            'session_duration_seconds', p_session_duration_seconds
        ),
        p_ip_address,
        p_user_agent
    ) INTO audit_id;
    
    RETURN audit_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 권한 변경 감사 함수
CREATE OR REPLACE FUNCTION audit_permission_change(
    p_target_user_id UUID,
    p_change_type VARCHAR(50), -- 'ROLE_ASSIGNED', 'ROLE_REMOVED', 'GROUP_ASSIGNED', etc.
    p_change_details JSONB
)
RETURNS UUID AS $
DECLARE
    audit_id UUID;
    target_user_info RECORD;
BEGIN
    -- 대상 사용자 정보 조회
    SELECT u.company_id, u.email, u.full_name
    INTO target_user_info
    FROM users u
    WHERE u.user_id = p_target_user_id;
    
    -- 감사 로그 기록
    SELECT log_audit_event(
        'PERMISSION_CHANGE',
        'ACCESS_CONTROL',
        format('Permission change for user %s: %s', target_user_info.email, p_change_type),
        'USER_PERMISSION',
        p_target_user_id::TEXT,
        jsonb_build_object(
            'target_user_email', target_user_info.email,
            'target_user_name', target_user_info.full_name,
            'change_type', p_change_type,
            'change_details', p_change_details
        )
    ) INTO audit_id;
    
    RETURN audit_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. 감사 로그 조회 및 분석 함수들
-- =====================================================

-- 조직별 감사 로그 요약 조회
CREATE OR REPLACE FUNCTION get_audit_summary(
    p_company_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    event_type VARCHAR(50),
    event_category VARCHAR(50),
    total_count BIGINT,
    success_count BIGINT,
    failure_count BIGINT,
    unique_users BIGINT,
    latest_event TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        al.event_type,
        al.event_category,
        COUNT(*) as total_count,
        COUNT(*) FILTER (WHERE al.success = true) as success_count,
        COUNT(*) FILTER (WHERE al.success = false) as failure_count,
        COUNT(DISTINCT al.user_id) as unique_users,
        MAX(al.event_timestamp) as latest_event
    FROM audit_logs al
    WHERE al.company_id = p_company_id
    AND al.event_date BETWEEN p_start_date AND p_end_date
    GROUP BY al.event_type, al.event_category
    ORDER BY total_count DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자별 활동 요약 조회
CREATE OR REPLACE FUNCTION get_user_activity_summary(
    p_company_id UUID,
    p_user_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    user_id UUID,
    user_email VARCHAR(255),
    user_name VARCHAR(100),
    total_activities BIGINT,
    unique_features BIGINT,
    total_session_time_hours NUMERIC,
    last_activity TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.email,
        u.full_name,
        COUNT(ual.*) as total_activities,
        COUNT(DISTINCT ual.feature_used) as unique_features,
        ROUND(SUM(COALESCE(ual.session_duration_seconds, 0)) / 3600.0, 2) as total_session_time_hours,
        MAX(ual.activity_timestamp) as last_activity
    FROM users u
    LEFT JOIN user_activity_logs ual ON u.user_id = ual.user_id
        AND ual.activity_date BETWEEN p_start_date AND p_end_date
    WHERE u.company_id = p_company_id
    AND (p_user_id IS NULL OR u.user_id = p_user_id)
    GROUP BY u.user_id, u.email, u.full_name
    ORDER BY total_activities DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 의심스러운 활동 탐지
CREATE OR REPLACE FUNCTION detect_suspicious_activities(
    p_company_id UUID DEFAULT NULL,
    p_hours_back INTEGER DEFAULT 24
)
RETURNS TABLE (
    activity_type VARCHAR(50),
    description TEXT,
    user_email VARCHAR(255),
    ip_address INET,
    event_count BIGINT,
    first_occurrence TIMESTAMPTZ,
    last_occurrence TIMESTAMPTZ,
    risk_level VARCHAR(10)
) AS $
BEGIN
    RETURN QUERY
    -- 1. 단시간 내 다수 로그인 실패
    SELECT 
        'MULTIPLE_LOGIN_FAILURES'::VARCHAR(50),
        format('Multiple login failures from IP %s', lal.ip_address),
        lal.email,
        lal.ip_address,
        COUNT(*),
        MIN(lal.attempt_timestamp),
        MAX(lal.attempt_timestamp),
        CASE 
            WHEN COUNT(*) >= 10 THEN 'HIGH'
            WHEN COUNT(*) >= 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END::VARCHAR(10)
    FROM login_attempt_logs lal
    WHERE lal.success = false
    AND lal.attempt_timestamp >= now() - (p_hours_back || ' hours')::INTERVAL
    AND (p_company_id IS NULL OR lal.company_id = p_company_id)
    GROUP BY lal.email, lal.ip_address
    HAVING COUNT(*) >= 3
    
    UNION ALL
    
    -- 2. 비정상적인 시간대 접근
    SELECT 
        'OFF_HOURS_ACCESS'::VARCHAR(50),
        format('Access during off-hours (user: %s)', u.email),
        u.email,
        al.ip_address,
        COUNT(*),
        MIN(al.event_timestamp),
        MAX(al.event_timestamp),
        'MEDIUM'::VARCHAR(10)
    FROM audit_logs al
    JOIN users u ON al.user_id = u.user_id
    WHERE al.event_timestamp >= now() - (p_hours_back || ' hours')::INTERVAL
    AND (EXTRACT(hour FROM al.event_timestamp) < 6 OR EXTRACT(hour FROM al.event_timestamp) > 22)
    AND (p_company_id IS NULL OR al.company_id = p_company_id)
    GROUP BY u.email, al.ip_address
    HAVING COUNT(*) >= 5
    
    UNION ALL
    
    -- 3. 다수 IP에서의 동시 접근
    SELECT 
        'MULTIPLE_IP_ACCESS'::VARCHAR(50),
        format('Access from multiple IPs (user: %s)', u.email),
        u.email,
        NULL::INET,
        COUNT(DISTINCT al.ip_address),
        MIN(al.event_timestamp),
        MAX(al.event_timestamp),
        CASE 
            WHEN COUNT(DISTINCT al.ip_address) >= 5 THEN 'HIGH'
            ELSE 'MEDIUM'
        END::VARCHAR(10)
    FROM audit_logs al
    JOIN users u ON al.user_id = u.user_id
    WHERE al.event_timestamp >= now() - (p_hours_back || ' hours')::INTERVAL
    AND (p_company_id IS NULL OR al.company_id = p_company_id)
    GROUP BY u.user_id, u.email
    HAVING COUNT(DISTINCT al.ip_address) >= 3
    
    ORDER BY risk_level DESC, event_count DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 데이터 변경 이력 조회 (특정 레코드)
CREATE OR REPLACE FUNCTION get_record_change_history(
    p_table_name VARCHAR(100),
    p_record_id VARCHAR(255),
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE (
    change_id UUID,
    user_email VARCHAR(255),
    operation_type VARCHAR(10),
    changed_fields TEXT[],
    old_values JSONB,
    new_values JSONB,
    change_reason TEXT,
    change_timestamp TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        dch.change_id,
        u.email,
        dch.operation_type,
        dch.changed_fields,
        dch.old_values,
        dch.new_values,
        dch.change_reason,
        dch.change_timestamp
    FROM data_change_history dch
    LEFT JOIN users u ON dch.user_id = u.user_id
    WHERE dch.table_name = p_table_name
    AND dch.record_id = p_record_id
    ORDER BY dch.change_timestamp DESC
    LIMIT p_limit;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. 감사 로그 유지보수 함수들
-- =====================================================

-- 오래된 로그 정리 함수
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs(
    p_retention_days INTEGER DEFAULT 365
)
RETURNS TABLE (
    table_name TEXT,
    deleted_count BIGINT
) AS $
DECLARE
    cutoff_date DATE;
    deleted_audit_logs BIGINT;
    deleted_activity_logs BIGINT;
    deleted_change_history BIGINT;
    deleted_login_attempts BIGINT;
BEGIN
    cutoff_date := CURRENT_DATE - (p_retention_days || ' days')::INTERVAL;
    
    -- audit_logs 정리
    DELETE FROM audit_logs 
    WHERE event_date < cutoff_date;
    GET DIAGNOSTICS deleted_audit_logs = ROW_COUNT;
    
    -- user_activity_logs 정리
    DELETE FROM user_activity_logs 
    WHERE activity_date < cutoff_date;
    GET DIAGNOSTICS deleted_activity_logs = ROW_COUNT;
    
    -- data_change_history 정리 (더 긴 보존 기간)
    DELETE FROM data_change_history 
    WHERE change_date < (cutoff_date - INTERVAL '365 days');
    GET DIAGNOSTICS deleted_change_history = ROW_COUNT;
    
    -- login_attempt_logs 정리
    DELETE FROM login_attempt_logs 
    WHERE attempt_date < cutoff_date;
    GET DIAGNOSTICS deleted_login_attempts = ROW_COUNT;
    
    -- 결과 반환
    RETURN QUERY VALUES 
        ('audit_logs', deleted_audit_logs),
        ('user_activity_logs', deleted_activity_logs),
        ('data_change_history', deleted_change_history),
        ('login_attempt_logs', deleted_login_attempts);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 감사 로그 통계 조회
CREATE OR REPLACE FUNCTION get_audit_statistics()
RETURNS TABLE (
    table_name TEXT,
    total_records BIGINT,
    records_last_30_days BIGINT,
    oldest_record TIMESTAMPTZ,
    newest_record TIMESTAMPTZ,
    avg_records_per_day NUMERIC
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        'audit_logs'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE event_timestamp >= CURRENT_DATE - INTERVAL '30 days'),
        MIN(event_timestamp),
        MAX(event_timestamp),
        ROUND(COUNT(*)::NUMERIC / GREATEST(EXTRACT(days FROM (MAX(event_timestamp) - MIN(event_timestamp))), 1), 2)
    FROM audit_logs
    
    UNION ALL
    
    SELECT 
        'user_activity_logs'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE activity_timestamp >= CURRENT_DATE - INTERVAL '30 days'),
        MIN(activity_timestamp),
        MAX(activity_timestamp),
        ROUND(COUNT(*)::NUMERIC / GREATEST(EXTRACT(days FROM (MAX(activity_timestamp) - MIN(activity_timestamp))), 1), 2)
    FROM user_activity_logs
    
    UNION ALL
    
    SELECT 
        'data_change_history'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE change_timestamp >= CURRENT_DATE - INTERVAL '30 days'),
        MIN(change_timestamp),
        MAX(change_timestamp),
        ROUND(COUNT(*)::NUMERIC / GREATEST(EXTRACT(days FROM (MAX(change_timestamp) - MIN(change_timestamp))), 1), 2)
    FROM data_change_history
    
    UNION ALL
    
    SELECT 
        'login_attempt_logs'::TEXT,
        COUNT(*),
        COUNT(*) FILTER (WHERE attempt_timestamp >= CURRENT_DATE - INTERVAL '30 days'),
        MIN(attempt_timestamp),
        MAX(attempt_timestamp),
        ROUND(COUNT(*)::NUMERIC / GREATEST(EXTRACT(days FROM (MAX(attempt_timestamp) - MIN(attempt_timestamp))), 1), 2)
    FROM login_attempt_logs;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;-- 
=====================================================
-- 8. 주요 테이블에 감사 트리거 설정
-- =====================================================

-- Companies 테이블 감사 트리거
DROP TRIGGER IF EXISTS companies_audit_trigger ON companies;
CREATE TRIGGER companies_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON companies
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- Users 테이블 감사 트리거
DROP TRIGGER IF EXISTS users_audit_trigger ON users;
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- Building_groups 테이블 감사 트리거
DROP TRIGGER IF EXISTS building_groups_audit_trigger ON building_groups;
CREATE TRIGGER building_groups_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON building_groups
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- User_role_links 테이블 감사 트리거 (권한 변경 추적)
DROP TRIGGER IF EXISTS user_role_links_audit_trigger ON user_role_links;
CREATE TRIGGER user_role_links_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_role_links
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- User_group_assignments 테이블 감사 트리거
DROP TRIGGER IF EXISTS user_group_assignments_audit_trigger ON user_group_assignments;
CREATE TRIGGER user_group_assignments_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON user_group_assignments
    FOR EACH ROW EXECUTE FUNCTION audit_table_changes();

-- =====================================================
-- 9. 권한 부여
-- =====================================================

-- 감사 로그 테이블 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON audit_logs TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_activity_logs TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON data_change_history TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON login_attempt_logs TO application_role;

-- 읽기 전용 권한
GRANT SELECT ON audit_logs TO readonly_role;
GRANT SELECT ON user_activity_logs TO readonly_role;
GRANT SELECT ON data_change_history TO readonly_role;
GRANT SELECT ON login_attempt_logs TO readonly_role;

-- 감사 역할 권한 (모든 로그 읽기 가능)
GRANT SELECT ON audit_logs TO audit_role;
GRANT SELECT ON user_activity_logs TO audit_role;
GRANT SELECT ON data_change_history TO audit_role;
GRANT SELECT ON login_attempt_logs TO audit_role;

-- 관리자 권한
GRANT ALL PRIVILEGES ON audit_logs TO admin_role;
GRANT ALL PRIVILEGES ON user_activity_logs TO admin_role;
GRANT ALL PRIVILEGES ON data_change_history TO admin_role;
GRANT ALL PRIVILEGES ON login_attempt_logs TO admin_role;

-- 함수 실행 권한
GRANT EXECUTE ON FUNCTION log_audit_event(VARCHAR(50), VARCHAR(50), TEXT, VARCHAR(100), VARCHAR(255), JSONB, INET, TEXT, VARCHAR(10), TEXT, BOOLEAN, TEXT, INTEGER) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION log_user_activity(VARCHAR(50), TEXT, VARCHAR(100), JSONB, UUID, VARCHAR(100), VARCHAR(255), INET, TEXT, VARCHAR(20), JSONB, INTEGER) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION log_data_change(VARCHAR(100), VARCHAR(255), VARCHAR(10), JSONB, JSONB, TEXT[], TEXT, JSONB) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION log_login_attempt(VARCHAR(255), BOOLEAN, VARCHAR(100), INET, TEXT, VARCHAR(2), BOOLEAN) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION audit_user_session(UUID, VARCHAR(50), INET, TEXT, INTEGER) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION audit_permission_change(UUID, VARCHAR(50), JSONB) TO application_role, admin_role;

-- 조회 함수 권한
GRANT EXECUTE ON FUNCTION get_audit_summary(UUID, DATE, DATE) TO application_role, readonly_role, audit_role, admin_role;
GRANT EXECUTE ON FUNCTION get_user_activity_summary(UUID, UUID, DATE, DATE) TO application_role, readonly_role, audit_role, admin_role;
GRANT EXECUTE ON FUNCTION detect_suspicious_activities(UUID, INTEGER) TO application_role, audit_role, admin_role;
GRANT EXECUTE ON FUNCTION get_record_change_history(VARCHAR(100), VARCHAR(255), INTEGER) TO application_role, readonly_role, audit_role, admin_role;
GRANT EXECUTE ON FUNCTION get_audit_statistics() TO audit_role, admin_role;

-- 유지보수 함수 권한 (관리자만)
GRANT EXECUTE ON FUNCTION cleanup_old_audit_logs(INTEGER) TO admin_role;

-- =====================================================
-- 10. 테스트 데이터 및 검증 함수
-- =====================================================

-- 감사 로그 시스템 테스트 함수
CREATE OR REPLACE FUNCTION test_audit_system(
    test_company_id UUID,
    test_user_id UUID
)
RETURNS JSONB AS $
DECLARE
    result JSONB;
    audit_id UUID;
    activity_id UUID;
    change_id UUID;
    login_id UUID;
BEGIN
    -- 컨텍스트 설정
    PERFORM initialize_session_context(test_company_id, test_user_id, 'EMPLOYEE');
    
    -- 1. 일반 감사 로그 테스트
    SELECT log_audit_event(
        'ACCESS',
        'BUSINESS_OPERATION',
        'Test audit log entry',
        'TEST_RESOURCE',
        'test_resource_123',
        '{"test": true}'::jsonb,
        '192.168.1.100'::inet,
        'Test User Agent',
        'GET',
        '/api/test',
        true,
        NULL,
        150
    ) INTO audit_id;
    
    -- 2. 사용자 활동 로그 테스트
    SELECT log_user_activity(
        'PAGE_VIEW',
        '/dashboard',
        'Dashboard View',
        '{"page": "dashboard", "section": "overview"}'::jsonb,
        NULL,
        'DASHBOARD',
        'main_dashboard',
        '192.168.1.100'::inet,
        'Test User Agent',
        '1920x1080',
        '{"browser": "Chrome", "version": "120.0"}'::jsonb,
        300
    ) INTO activity_id;
    
    -- 3. 데이터 변경 이력 테스트
    SELECT log_data_change(
        'test_table',
        'test_record_123',
        'UPDATE',
        '{"old_field": "old_value"}'::jsonb,
        '{"old_field": "new_value"}'::jsonb,
        ARRAY['old_field'],
        'Test data change',
        '{"context": "test"}'::jsonb
    ) INTO change_id;
    
    -- 4. 로그인 시도 테스트
    SELECT log_login_attempt(
        'test@example.com',
        true,
        NULL,
        '192.168.1.100'::inet,
        'Test User Agent',
        'KR',
        false
    ) INTO login_id;
    
    -- 결과 구성
    result := jsonb_build_object(
        'test_results', jsonb_build_object(
            'audit_log_id', audit_id,
            'activity_log_id', activity_id,
            'change_log_id', change_id,
            'login_log_id', login_id
        ),
        'context', get_current_context(),
        'test_timestamp', now(),
        'success', true
    );
    
    RETURN result;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 감사 로그 시스템 상태 확인 함수
CREATE OR REPLACE FUNCTION check_audit_system_health()
RETURNS JSONB AS $
DECLARE
    result JSONB;
    table_stats JSONB;
    trigger_stats JSONB;
    policy_stats JSONB;
BEGIN
    -- 테이블 통계
    SELECT jsonb_agg(
        jsonb_build_object(
            'table_name', table_name,
            'total_records', total_records,
            'records_last_30_days', records_last_30_days,
            'oldest_record', oldest_record,
            'newest_record', newest_record,
            'avg_records_per_day', avg_records_per_day
        )
    ) INTO table_stats
    FROM get_audit_statistics();
    
    -- 트리거 상태 확인
    SELECT jsonb_agg(
        jsonb_build_object(
            'table_name', schemaname || '.' || tablename,
            'trigger_name', trigger_name,
            'event_manipulation', event_manipulation,
            'action_timing', action_timing
        )
    ) INTO trigger_stats
    FROM information_schema.triggers
    WHERE trigger_name LIKE '%audit%'
    AND trigger_schema = 'public';
    
    -- RLS 정책 상태 확인
    SELECT jsonb_agg(
        jsonb_build_object(
            'table_name', table_name,
            'rls_enabled', rls_enabled,
            'policy_count', policy_count
        )
    ) INTO policy_stats
    FROM get_rls_policy_status()
    WHERE table_name IN ('audit_logs', 'user_activity_logs', 'data_change_history', 'login_attempt_logs');
    
    -- 결과 구성
    result := jsonb_build_object(
        'system_health', 'OK',
        'check_timestamp', now(),
        'table_statistics', table_stats,
        'trigger_status', trigger_stats,
        'rls_policy_status', policy_stats,
        'recommendations', CASE 
            WHEN (SELECT COUNT(*) FROM audit_logs WHERE event_timestamp >= CURRENT_DATE - INTERVAL '1 day') = 0 
            THEN jsonb_build_array('No recent audit logs detected - check if logging is working properly')
            ELSE jsonb_build_array('System appears to be functioning normally')
        END
    );
    
    RETURN result;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. 코멘트 추가
-- =====================================================

COMMENT ON TABLE audit_logs IS '시스템 감사 로그 - 중요한 시스템 이벤트 및 사용자 작업 추적';
COMMENT ON TABLE user_activity_logs IS '사용자 활동 로그 - 상세한 사용자 행동 패턴 추적';
COMMENT ON TABLE data_change_history IS '데이터 변경 이력 - 모든 데이터 변경사항의 상세 기록';
COMMENT ON TABLE login_attempt_logs IS '로그인 시도 로그 - 보안 모니터링을 위한 로그인 시도 기록';

COMMENT ON FUNCTION log_audit_event(VARCHAR(50), VARCHAR(50), TEXT, VARCHAR(100), VARCHAR(255), JSONB, INET, TEXT, VARCHAR(10), TEXT, BOOLEAN, TEXT, INTEGER) IS '일반 감사 이벤트 기록';
COMMENT ON FUNCTION log_user_activity(VARCHAR(50), TEXT, VARCHAR(100), JSONB, UUID, VARCHAR(100), VARCHAR(255), INET, TEXT, VARCHAR(20), JSONB, INTEGER) IS '사용자 활동 기록';
COMMENT ON FUNCTION log_data_change(VARCHAR(100), VARCHAR(255), VARCHAR(10), JSONB, JSONB, TEXT[], TEXT, JSONB) IS '데이터 변경 이력 기록';
COMMENT ON FUNCTION log_login_attempt(VARCHAR(255), BOOLEAN, VARCHAR(100), INET, TEXT, VARCHAR(2), BOOLEAN) IS '로그인 시도 기록';
COMMENT ON FUNCTION audit_table_changes() IS '테이블 변경사항 자동 감사 트리거 함수';
COMMENT ON FUNCTION audit_user_session(UUID, VARCHAR(50), INET, TEXT, INTEGER) IS '사용자 세션 감사 (로그인/로그아웃)';
COMMENT ON FUNCTION audit_permission_change(UUID, VARCHAR(50), JSONB) IS '권한 변경 감사';
COMMENT ON FUNCTION get_audit_summary(UUID, DATE, DATE) IS '조직별 감사 로그 요약 조회';
COMMENT ON FUNCTION get_user_activity_summary(UUID, UUID, DATE, DATE) IS '사용자별 활동 요약 조회';
COMMENT ON FUNCTION detect_suspicious_activities(UUID, INTEGER) IS '의심스러운 활동 탐지';
COMMENT ON FUNCTION get_record_change_history(VARCHAR(100), VARCHAR(255), INTEGER) IS '특정 레코드의 변경 이력 조회';
COMMENT ON FUNCTION cleanup_old_audit_logs(INTEGER) IS '오래된 감사 로그 정리';
COMMENT ON FUNCTION get_audit_statistics() IS '감사 로그 시스템 통계 조회';
COMMENT ON FUNCTION test_audit_system(UUID, UUID) IS '감사 로그 시스템 테스트';
COMMENT ON FUNCTION check_audit_system_health() IS '감사 로그 시스템 상태 확인';

-- =====================================================
-- 12. 초기 설정 완료 로그
-- =====================================================

-- 시스템 초기화 로그 기록
DO $
BEGIN
    -- 시스템 감사 로그 기록 (컨텍스트 없이)
    INSERT INTO audit_logs (
        company_id, user_id, session_id,
        event_type, event_category, resource_type, resource_id,
        event_description, event_data,
        success
    ) VALUES (
        NULL, NULL, NULL,
        'SYSTEM_CONFIG', 'SYSTEM_ADMINISTRATION', 'AUDIT_SYSTEM', 'initialization',
        'Audit log system initialized successfully',
        jsonb_build_object(
            'version', '1.0',
            'initialization_date', now(),
            'tables_created', jsonb_build_array('audit_logs', 'user_activity_logs', 'data_change_history', 'login_attempt_logs'),
            'functions_created', 15,
            'triggers_created', 5
        ),
        true
    );
END
$;

-- 성공 메시지
SELECT 'Audit Log System initialized successfully!' as status,
       now() as initialization_time,
       'All tables, functions, triggers, and policies have been created' as details;