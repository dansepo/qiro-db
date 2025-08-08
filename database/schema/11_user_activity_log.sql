-- =====================================================
-- 사용자 활동 로그 시스템 생성 스크립트
-- Phase 4.2: 사용자 활동 로그 테이블
-- =====================================================

-- 1. 사용자 활동 로그 테이블 생성
CREATE TABLE IF NOT EXISTS bms.user_activity_logs (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 사용자 정보
    user_id UUID,                                       -- 사용자 ID (NULL이면 익명 사용자)
    user_name VARCHAR(100),                             -- 사용자명 (스냅샷)
    user_email VARCHAR(255),                            -- 사용자 이메일 (스냅샷)
    user_role VARCHAR(50),                              -- 사용자 역할 (스냅샷)
    
    -- 활동 정보
    activity_type VARCHAR(50) NOT NULL,                 -- 활동 유형
    activity_category VARCHAR(30) NOT NULL,             -- 활동 분류
    activity_description TEXT,                          -- 활동 설명
    activity_result VARCHAR(20) DEFAULT 'SUCCESS',      -- 활동 결과
    
    -- 세션 정보
    session_id VARCHAR(100),                            -- 세션 ID
    session_start_time TIMESTAMP WITH TIME ZONE,        -- 세션 시작 시간
    session_duration INTEGER,                           -- 세션 지속 시간 (초)
    
    -- 접근 정보
    client_ip INET,                                     -- 클라이언트 IP
    user_agent TEXT,                                    -- 사용자 에이전트
    device_type VARCHAR(20),                            -- 디바이스 타입
    browser_name VARCHAR(50),                           -- 브라우저명
    os_name VARCHAR(50),                                -- 운영체제명
    
    -- 위치 정보
    country_code VARCHAR(2),                            -- 국가 코드
    region VARCHAR(100),                                -- 지역
    city VARCHAR(100),                                  -- 도시
    timezone VARCHAR(50),                               -- 시간대
    
    -- 애플리케이션 정보
    application_name VARCHAR(100),                      -- 애플리케이션명
    application_version VARCHAR(20),                    -- 애플리케이션 버전
    api_endpoint VARCHAR(200),                          -- API 엔드포인트
    http_method VARCHAR(10),                            -- HTTP 메소드
    http_status_code INTEGER,                           -- HTTP 상태 코드
    
    -- 비즈니스 컨텍스트
    business_context VARCHAR(100),                      -- 비즈니스 컨텍스트
    resource_type VARCHAR(50),                          -- 리소스 타입
    resource_id UUID,                                   -- 리소스 ID
    building_id UUID,                                   -- 관련 건물 ID
    
    -- 성능 정보
    response_time_ms INTEGER,                           -- 응답 시간 (밀리초)
    request_size_bytes INTEGER,                         -- 요청 크기 (바이트)
    response_size_bytes INTEGER,                        -- 응답 크기 (바이트)
    
    -- 보안 정보
    security_level INTEGER DEFAULT 1,                   -- 보안 레벨 (1-5)
    risk_score INTEGER DEFAULT 0,                       -- 위험 점수 (0-100)
    is_suspicious BOOLEAN DEFAULT false,                -- 의심스러운 활동 여부
    threat_indicators TEXT[],                           -- 위협 지표 목록
    
    -- 추가 데이터
    metadata JSONB,                                     -- 추가 메타데이터
    tags TEXT[],                                        -- 태그 목록
    
    -- 시간 정보
    -- activity_timestamp는 created_at으로 대체
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_user_activity_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_activity_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_user_activity_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_activity_type CHECK (activity_type IN (
        'LOGIN',                -- 로그인
        'LOGOUT',               -- 로그아웃
        'PAGE_VIEW',            -- 페이지 조회
        'API_CALL',             -- API 호출
        'DATA_EXPORT',          -- 데이터 내보내기
        'DATA_IMPORT',          -- 데이터 가져오기
        'FILE_UPLOAD',          -- 파일 업로드
        'FILE_DOWNLOAD',        -- 파일 다운로드
        'SEARCH',               -- 검색
        'REPORT_GENERATION',    -- 보고서 생성
        'CONFIGURATION_CHANGE', -- 설정 변경
        'PASSWORD_CHANGE',      -- 비밀번호 변경
        'PERMISSION_CHANGE',    -- 권한 변경
        'FAILED_LOGIN',         -- 로그인 실패
        'SECURITY_VIOLATION',   -- 보안 위반
        'SYSTEM_ERROR',         -- 시스템 오류
        'CUSTOM'                -- 사용자 정의
    )),
    CONSTRAINT chk_activity_category CHECK (activity_category IN (
        'AUTHENTICATION',       -- 인증
        'AUTHORIZATION',        -- 인가
        'DATA_ACCESS',          -- 데이터 접근
        'DATA_MODIFICATION',    -- 데이터 수정
        'SYSTEM_ADMINISTRATION',-- 시스템 관리
        'BUSINESS_OPERATION',   -- 비즈니스 운영
        'SECURITY',             -- 보안
        'PERFORMANCE',          -- 성능
        'ERROR',                -- 오류
        'AUDIT'                 -- 감사
    )),
    CONSTRAINT chk_activity_result CHECK (activity_result IN ('SUCCESS', 'FAILURE', 'PARTIAL', 'TIMEOUT', 'ERROR')),
    CONSTRAINT chk_device_type CHECK (device_type IN ('DESKTOP', 'MOBILE', 'TABLET', 'API', 'UNKNOWN')),
    CONSTRAINT chk_security_level CHECK (security_level BETWEEN 1 AND 5),
    CONSTRAINT chk_risk_score CHECK (risk_score BETWEEN 0 AND 100),
    CONSTRAINT chk_response_time CHECK (response_time_ms >= 0),
    CONSTRAINT chk_request_size CHECK (request_size_bytes >= 0),
    CONSTRAINT chk_response_size CHECK (response_size_bytes >= 0)
);

-- 2. 로그인 세션 테이블 생성
CREATE TABLE IF NOT EXISTS bms.user_sessions (
    session_id VARCHAR(100) PRIMARY KEY,
    company_id UUID NOT NULL,
    user_id UUID NOT NULL,
    
    -- 세션 정보
    session_token VARCHAR(500),                         -- 세션 토큰 (해시)
    refresh_token VARCHAR(500),                         -- 리프레시 토큰 (해시)
    
    -- 시간 정보
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_activity_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    
    -- 접근 정보
    client_ip INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(500),                    -- 디바이스 지문
    
    -- 상태 정보
    is_active BOOLEAN DEFAULT true,
    logout_reason VARCHAR(50),                          -- 로그아웃 사유
    
    -- 보안 정보
    login_method VARCHAR(20) DEFAULT 'PASSWORD',        -- 로그인 방식
    mfa_verified BOOLEAN DEFAULT false,                 -- MFA 인증 여부
    is_trusted_device BOOLEAN DEFAULT false,            -- 신뢰할 수 있는 디바이스 여부
    
    -- 제약조건
    CONSTRAINT fk_user_sessions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_sessions_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_login_method CHECK (login_method IN ('PASSWORD', 'SSO', 'API_KEY', 'TOKEN', 'BIOMETRIC')),
    CONSTRAINT chk_logout_reason CHECK (logout_reason IN ('USER_LOGOUT', 'TIMEOUT', 'ADMIN_LOGOUT', 'SECURITY_LOGOUT', 'SYSTEM_LOGOUT'))
);

-- 3. 보안 이벤트 로그 테이블 생성
CREATE TABLE IF NOT EXISTS bms.security_event_logs (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 이벤트 정보
    event_type VARCHAR(50) NOT NULL,                    -- 이벤트 유형
    event_severity VARCHAR(20) NOT NULL,                -- 심각도
    event_description TEXT NOT NULL,                    -- 이벤트 설명
    event_source VARCHAR(100),                          -- 이벤트 소스
    
    -- 사용자 정보
    user_id UUID,
    user_name VARCHAR(100),
    user_ip INET,
    
    -- 위협 정보
    threat_type VARCHAR(50),                            -- 위협 유형
    attack_vector VARCHAR(100),                         -- 공격 벡터
    indicators_of_compromise TEXT[],                    -- 침해 지표
    
    -- 대응 정보
    response_action VARCHAR(100),                       -- 대응 조치
    response_status VARCHAR(20) DEFAULT 'PENDING',      -- 대응 상태
    assigned_to UUID,                                   -- 담당자
    resolved_at TIMESTAMP WITH TIME ZONE,              -- 해결 시간
    
    -- 추가 정보
    additional_data JSONB,                              -- 추가 데이터
    
    -- 시간 정보
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_security_events_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_events_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_events_assigned FOREIGN KEY (assigned_to) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_event_type CHECK (event_type IN (
        'FAILED_LOGIN_ATTEMPT',     -- 로그인 실패 시도
        'BRUTE_FORCE_ATTACK',       -- 무차별 대입 공격
        'SUSPICIOUS_IP_ACCESS',     -- 의심스러운 IP 접근
        'PRIVILEGE_ESCALATION',     -- 권한 상승
        'DATA_EXFILTRATION',        -- 데이터 유출
        'MALWARE_DETECTION',        -- 악성코드 탐지
        'UNAUTHORIZED_ACCESS',      -- 무단 접근
        'POLICY_VIOLATION',         -- 정책 위반
        'ANOMALY_DETECTION',        -- 이상 행위 탐지
        'SYSTEM_COMPROMISE'         -- 시스템 침해
    )),
    CONSTRAINT chk_event_severity CHECK (event_severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_response_status CHECK (response_status IN ('PENDING', 'IN_PROGRESS', 'RESOLVED', 'DISMISSED'))
);

-- 4. RLS 정책 활성화
ALTER TABLE bms.user_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.security_event_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY user_activity_logs_isolation_policy ON bms.user_activity_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY user_sessions_isolation_policy ON bms.user_sessions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY security_event_logs_isolation_policy ON bms.security_event_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 6. 성능 최적화 인덱스 생성
-- 사용자 활동 로그 인덱스
CREATE INDEX idx_user_activity_logs_company_id ON bms.user_activity_logs(company_id);
CREATE INDEX idx_user_activity_logs_user_id ON bms.user_activity_logs(user_id);
CREATE INDEX idx_user_activity_logs_activity_type ON bms.user_activity_logs(activity_type);
CREATE INDEX idx_user_activity_logs_activity_category ON bms.user_activity_logs(activity_category);
CREATE INDEX idx_user_activity_logs_timestamp ON bms.user_activity_logs(created_at DESC);
CREATE INDEX idx_user_activity_logs_session_id ON bms.user_activity_logs(session_id);
CREATE INDEX idx_user_activity_logs_client_ip ON bms.user_activity_logs(client_ip);
-- building_id 컬럼이 없으므로 인덱스 생성 생략
CREATE INDEX idx_user_activity_logs_is_suspicious ON bms.user_activity_logs(is_suspicious);
CREATE INDEX idx_user_activity_logs_risk_score ON bms.user_activity_logs(risk_score DESC);

-- 사용자 세션 인덱스
CREATE INDEX idx_user_sessions_company_id ON bms.user_sessions(company_id);
CREATE INDEX idx_user_sessions_user_id ON bms.user_sessions(user_id);
CREATE INDEX idx_user_sessions_is_active ON bms.user_sessions(is_active);
CREATE INDEX idx_user_sessions_expires_at ON bms.user_sessions(expires_at);
CREATE INDEX idx_user_sessions_last_activity ON bms.user_sessions(last_activity_at DESC);
CREATE INDEX idx_user_sessions_client_ip ON bms.user_sessions(client_ip);

-- 보안 이벤트 로그 인덱스
CREATE INDEX idx_security_events_company_id ON bms.security_event_logs(company_id);
CREATE INDEX idx_security_events_event_type ON bms.security_event_logs(event_type);
CREATE INDEX idx_security_events_severity ON bms.security_event_logs(event_severity);
CREATE INDEX idx_security_events_timestamp ON bms.security_event_logs(event_timestamp DESC);
CREATE INDEX idx_security_events_user_id ON bms.security_event_logs(user_id);
CREATE INDEX idx_security_events_is_resolved ON bms.security_event_logs(is_resolved);
CREATE INDEX idx_security_events_resolved_by ON bms.security_event_logs(resolved_by);

-- 복합 인덱스
CREATE INDEX idx_user_activity_company_user ON bms.user_activity_logs(company_id, user_id);
CREATE INDEX idx_user_activity_company_timestamp ON bms.user_activity_logs(company_id, created_at DESC);
CREATE INDEX idx_user_activity_type_timestamp ON bms.user_activity_logs(activity_type, created_at DESC);
CREATE INDEX idx_user_sessions_user_active ON bms.user_sessions(user_id, is_active);
CREATE INDEX idx_security_events_company_severity ON bms.security_event_logs(company_id, event_severity);

-- 7. 사용자 활동 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_user_activity(
    p_user_id UUID DEFAULT NULL,
    p_activity_type VARCHAR(50) DEFAULT 'CUSTOM',
    p_activity_category VARCHAR(30) DEFAULT 'BUSINESS_OPERATION',
    p_activity_description TEXT DEFAULT NULL,
    p_activity_result VARCHAR(20) DEFAULT 'SUCCESS',
    p_business_context VARCHAR(100) DEFAULT NULL,
    p_resource_type VARCHAR(50) DEFAULT NULL,
    p_resource_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_activity_id UUID;
    v_company_id UUID;
    v_user_name VARCHAR(100);
    v_user_email VARCHAR(255);
    v_user_role VARCHAR(50);
    v_session_id VARCHAR(100);
    v_client_ip INET;
    v_user_agent TEXT;
BEGIN
    -- 현재 회사 ID 가져오기
    v_company_id := (current_setting('app.current_company_id', true))::uuid;
    
    -- 사용자 정보 조회
    IF p_user_id IS NOT NULL THEN
        SELECT u.full_name, u.email, r.role_name 
        INTO v_user_name, v_user_email, v_user_role
        FROM bms.users u
        LEFT JOIN bms.user_role_links url ON u.user_id = url.user_id
        LEFT JOIN bms.roles r ON url.role_id = r.role_id
        WHERE u.user_id = p_user_id
        LIMIT 1;
    END IF;
    
    -- 세션 정보 가져오기
    BEGIN
        v_session_id := current_setting('app.session_id', true);
        v_client_ip := inet_client_addr();
        v_user_agent := current_setting('app.user_agent', true);
    EXCEPTION WHEN OTHERS THEN
        -- 설정이 없는 경우 무시
        NULL;
    END;
    
    -- 활동 로그 생성
    v_activity_id := gen_random_uuid();
    
    INSERT INTO bms.user_activity_logs (
        activity_id, company_id, user_id, user_name, user_email, user_role,
        activity_type, activity_category, activity_description, activity_result,
        session_id, client_ip, user_agent,
        business_context, resource_type, resource_id, building_id,
        metadata
    ) VALUES (
        v_activity_id, v_company_id, p_user_id, v_user_name, v_user_email, v_user_role,
        p_activity_type, p_activity_category, p_activity_description, p_activity_result,
        v_session_id, v_client_ip, v_user_agent,
        p_business_context, p_resource_type, p_resource_id, p_building_id,
        p_metadata
    );
    
    RETURN v_activity_id;
END;
$$ LANGUAGE plpgsql;

-- 8. 보안 이벤트 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_security_event(
    p_event_type VARCHAR(50),
    p_event_severity VARCHAR(20),
    p_event_description TEXT,
    p_user_id UUID DEFAULT NULL,
    p_threat_type VARCHAR(50) DEFAULT NULL,
    p_attack_vector VARCHAR(100) DEFAULT NULL,
    p_additional_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_company_id UUID;
    v_user_name VARCHAR(100);
    v_client_ip INET;
BEGIN
    -- 현재 회사 ID 가져오기
    v_company_id := (current_setting('app.current_company_id', true))::uuid;
    
    -- 사용자 정보 조회
    IF p_user_id IS NOT NULL THEN
        SELECT full_name INTO v_user_name
        FROM bms.users
        WHERE user_id = p_user_id;
    END IF;
    
    -- 클라이언트 IP 가져오기
    BEGIN
        v_client_ip := inet_client_addr();
    EXCEPTION WHEN OTHERS THEN
        v_client_ip := NULL;
    END;
    
    -- 보안 이벤트 로그 생성
    v_event_id := gen_random_uuid();
    
    INSERT INTO bms.security_event_logs (
        event_id, company_id, event_type, event_severity, event_description,
        user_id, user_name, user_ip,
        threat_type, attack_vector, additional_data
    ) VALUES (
        v_event_id, v_company_id, p_event_type, p_event_severity, p_event_description,
        p_user_id, v_user_name, v_client_ip,
        p_threat_type, p_attack_vector, p_additional_data
    );
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- 9. 세션 관리 함수
CREATE OR REPLACE FUNCTION bms.create_user_session(
    p_user_id UUID,
    p_session_token VARCHAR(500),
    p_expires_at TIMESTAMP WITH TIME ZONE,
    p_login_method VARCHAR(20) DEFAULT 'PASSWORD'
)
RETURNS VARCHAR(100) AS $$
DECLARE
    v_session_id VARCHAR(100);
    v_company_id UUID;
    v_client_ip INET;
    v_user_agent TEXT;
BEGIN
    -- 세션 ID 생성
    v_session_id := 'sess_' || substr(md5(random()::text), 1, 32);
    
    -- 현재 회사 ID 가져오기
    SELECT company_id INTO v_company_id
    FROM bms.users
    WHERE user_id = p_user_id;
    
    -- 클라이언트 정보 가져오기
    BEGIN
        v_client_ip := inet_client_addr();
        v_user_agent := current_setting('app.user_agent', true);
    EXCEPTION WHEN OTHERS THEN
        -- 설정이 없는 경우 무시
        NULL;
    END;
    
    -- 세션 생성
    INSERT INTO bms.user_sessions (
        session_id, company_id, user_id, session_token, expires_at,
        client_ip, user_agent, login_method
    ) VALUES (
        v_session_id, v_company_id, p_user_id, p_session_token, p_expires_at,
        v_client_ip, v_user_agent, p_login_method
    );
    
    -- 로그인 활동 기록
    PERFORM bms.log_user_activity(
        p_user_id, 'LOGIN', 'AUTHENTICATION', '사용자 로그인', 'SUCCESS',
        'USER_SESSION', 'SESSION', v_session_id::uuid
    );
    
    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql;

-- 10. 활동 로그 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_user_activity_summary AS
SELECT 
    ual.company_id,
    c.company_name,
    ual.user_id,
    ual.user_name,
    ual.activity_type,
    ual.activity_category,
    COUNT(*) as activity_count,
    MIN(ual.created_at) as first_activity,
    MAX(ual.created_at) as last_activity,
    COUNT(DISTINCT DATE(ual.created_at)) as active_days,
    AVG(ual.response_time) as avg_response_time,
    SUM(CASE WHEN ual.activity_result = 'FAILURE' THEN 1 ELSE 0 END) as failure_count,
    SUM(CASE WHEN ual.is_suspicious THEN 1 ELSE 0 END) as suspicious_count
FROM bms.user_activity_logs ual
JOIN bms.companies c ON ual.company_id = c.company_id
WHERE ual.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ual.company_id, c.company_name, ual.user_id, ual.user_name, 
         ual.activity_type, ual.activity_category
ORDER BY activity_count DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_user_activity_summary OWNER TO qiro;

-- 11. 보안 대시보드 뷰 생성
CREATE OR REPLACE VIEW bms.v_security_dashboard AS
SELECT 
    sel.company_id,
    c.company_name,
    sel.event_type,
    sel.event_severity,
    COUNT(*) as event_count,
    COUNT(DISTINCT sel.user_id) as affected_users,
    MIN(sel.event_timestamp) as first_occurrence,
    MAX(sel.event_timestamp) as last_occurrence,
    SUM(CASE WHEN sel.is_resolved = true THEN 1 ELSE 0 END) as resolved_count,
    SUM(CASE WHEN sel.is_resolved = false THEN 1 ELSE 0 END) as pending_count
FROM bms.security_event_logs sel
JOIN bms.companies c ON sel.company_id = c.company_id
WHERE sel.event_timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY sel.company_id, c.company_name, sel.event_type, sel.event_severity
ORDER BY event_count DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_security_dashboard OWNER TO qiro;

-- 12. 세션 정리 함수 (만료된 세션 삭제)
CREATE OR REPLACE FUNCTION bms.cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- 만료된 세션 삭제
    DELETE FROM bms.user_sessions
    WHERE expires_at < NOW()
       OR (last_activity_at < NOW() - INTERVAL '30 days' AND is_active = false);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RAISE NOTICE '만료된 세션 %개를 정리했습니다.', v_deleted_count;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 4.2 사용자 활동 로그 시스템 생성이 완료되었습니다!' as result;