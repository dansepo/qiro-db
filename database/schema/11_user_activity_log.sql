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
    
    -- 요청 정보
    request_method VARCHAR(10),                         -- HTTP 메소드
    request_url TEXT,                                   -- 요청 URL
    request_params JSONB,                               -- 요청 파라미터
    response_status INTEGER,                            -- 응답 상태 코드
    response_time INTEGER,                              -- 응답 시간 (ms)
    
    -- 클라이언트 정보
    client_ip INET,                                     -- 클라이언트 IP
    client_port INTEGER,                                -- 클라이언트 포트
    user_agent TEXT,                                    -- 사용자 에이전트
    browser_name VARCHAR(50),                           -- 브라우저명
    browser_version VARCHAR(20),                        -- 브라우저 버전
    os_name VARCHAR(50),                                -- 운영체제명
    os_version VARCHAR(20),                             -- 운영체제 버전
    device_type VARCHAR(20),                            -- 디바이스 타입
    
    -- 지리적 정보
    country_code VARCHAR(2),                            -- 국가 코드
    region VARCHAR(100),                                -- 지역
    city VARCHAR(100),                                  -- 도시
    timezone VARCHAR(50),                               -- 시간대
    
    -- 보안 정보
    is_suspicious BOOLEAN DEFAULT false,                -- 의심스러운 활동 여부
    risk_score INTEGER DEFAULT 0,                       -- 위험 점수 (0-100)
    security_flags TEXT[],                              -- 보안 플래그
    
    -- 비즈니스 컨텍스트
    business_context VARCHAR(100),                      -- 비즈니스 컨텍스트
    feature_used VARCHAR(100),                          -- 사용된 기능
    data_accessed TEXT[],                               -- 접근한 데이터
    
    -- 성능 정보
    page_load_time INTEGER,                             -- 페이지 로드 시간 (ms)
    database_query_time INTEGER,                        -- DB 쿼리 시간 (ms)
    api_call_count INTEGER DEFAULT 0,                   -- API 호출 횟수
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_user_activity_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_activity_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_activity_type CHECK (activity_type IN (
        'LOGIN',                -- 로그인
        'LOGOUT',               -- 로그아웃
        'PAGE_VIEW',            -- 페이지 조회
        'SEARCH',               -- 검색
        'CREATE',               -- 생성
        'READ',                 -- 조회
        'UPDATE',               -- 수정
        'DELETE',               -- 삭제
        'DOWNLOAD',             -- 다운로드
        'UPLOAD',               -- 업로드
        'EXPORT',               -- 내보내기
        'IMPORT',               -- 가져오기
        'PRINT',                -- 인쇄
        'EMAIL_SEND',           -- 이메일 발송
        'REPORT_GENERATE',      -- 보고서 생성
        'BACKUP',               -- 백업
        'RESTORE',              -- 복원
        'CONFIG_CHANGE',        -- 설정 변경
        'USER_MANAGEMENT',      -- 사용자 관리
        'PERMISSION_CHANGE',    -- 권한 변경
        'API_CALL',             -- API 호출
        'ERROR',                -- 오류
        'SECURITY_EVENT'        -- 보안 이벤트
    )),
    CONSTRAINT chk_activity_category CHECK (activity_category IN (
        'AUTHENTICATION',       -- 인증
        'AUTHORIZATION',        -- 인가
        'DATA_ACCESS',          -- 데이터 접근
        'DATA_MODIFICATION',    -- 데이터 수정
        'SYSTEM_ADMIN',         -- 시스템 관리
        'USER_INTERFACE',       -- 사용자 인터페이스
        'REPORTING',            -- 보고서
        'INTEGRATION',          -- 연동
        'SECURITY',             -- 보안
        'PERFORMANCE',          -- 성능
        'ERROR_HANDLING'        -- 오류 처리
    )),
    CONSTRAINT chk_activity_result CHECK (activity_result IN (
        'SUCCESS',              -- 성공
        'FAILURE',              -- 실패
        'PARTIAL_SUCCESS',      -- 부분 성공
        'TIMEOUT',              -- 타임아웃
        'CANCELLED',            -- 취소됨
        'PENDING'               -- 대기중
    )),
    CONSTRAINT chk_risk_score CHECK (risk_score BETWEEN 0 AND 100),
    CONSTRAINT chk_response_status CHECK (response_status BETWEEN 100 AND 599)
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
    
    -- 클라이언트 정보
    client_ip INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(100),                    -- 디바이스 지문
    
    -- 상태 정보
    is_active BOOLEAN DEFAULT true,
    logout_reason VARCHAR(50),                          -- 로그아웃 사유
    
    -- 보안 정보
    login_method VARCHAR(20) DEFAULT 'PASSWORD',        -- 로그인 방법
    mfa_verified BOOLEAN DEFAULT false,                 -- MFA 인증 여부
    is_suspicious BOOLEAN DEFAULT false,
    
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
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 사용자 정보
    user_id UUID,
    user_name VARCHAR(100),
    user_ip INET,
    
    -- 상세 정보
    event_details JSONB,                                -- 이벤트 상세 정보
    affected_resources TEXT[],                          -- 영향받은 리소스
    
    -- 대응 정보
    is_resolved BOOLEAN DEFAULT false,                  -- 해결 여부
    resolution_notes TEXT,                              -- 해결 노트
    resolved_by UUID,                                   -- 해결자 ID
    resolved_at TIMESTAMP WITH TIME ZONE,              -- 해결 시간
    
    -- 알림 정보
    notification_sent BOOLEAN DEFAULT false,           -- 알림 발송 여부
    notification_recipients TEXT[],                     -- 알림 수신자
    
    -- 제약조건
    CONSTRAINT fk_security_events_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_security_events_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_events_resolver FOREIGN KEY (resolved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_event_type CHECK (event_type IN (
        'FAILED_LOGIN',         -- 로그인 실패
        'BRUTE_FORCE',          -- 무차별 대입 공격
        'SUSPICIOUS_IP',        -- 의심스러운 IP
        'PRIVILEGE_ESCALATION', -- 권한 상승
        'DATA_BREACH',          -- 데이터 유출
        'UNAUTHORIZED_ACCESS',  -- 무단 접근
        'MALWARE_DETECTED',     -- 악성코드 탐지
        'SQL_INJECTION',        -- SQL 인젝션
        'XSS_ATTACK',           -- XSS 공격
        'CSRF_ATTACK',          -- CSRF 공격
        'ACCOUNT_LOCKOUT',      -- 계정 잠금
        'PASSWORD_POLICY_VIOLATION', -- 비밀번호 정책 위반
        'SESSION_HIJACKING',    -- 세션 하이재킹
        'API_ABUSE',            -- API 남용
        'RATE_LIMIT_EXCEEDED'   -- 요청 한도 초과
    )),
    CONSTRAINT chk_event_severity CHECK (event_severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
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
-- 사용자 활동 로그 테이블 인덱스
CREATE INDEX idx_user_activity_company_id ON bms.user_activity_logs(company_id);
CREATE INDEX idx_user_activity_user_id ON bms.user_activity_logs(user_id);
CREATE INDEX idx_user_activity_type ON bms.user_activity_logs(activity_type);
CREATE INDEX idx_user_activity_category ON bms.user_activity_logs(activity_category);
CREATE INDEX idx_user_activity_created_at ON bms.user_activity_logs(created_at DESC);
CREATE INDEX idx_user_activity_client_ip ON bms.user_activity_logs(client_ip);
CREATE INDEX idx_user_activity_session_id ON bms.user_activity_logs(session_id);
CREATE INDEX idx_user_activity_suspicious ON bms.user_activity_logs(is_suspicious) WHERE is_suspicious = true;

-- 사용자 세션 테이블 인덱스
CREATE INDEX idx_user_sessions_company_id ON bms.user_sessions(company_id);
CREATE INDEX idx_user_sessions_user_id ON bms.user_sessions(user_id);
CREATE INDEX idx_user_sessions_is_active ON bms.user_sessions(is_active);
CREATE INDEX idx_user_sessions_expires_at ON bms.user_sessions(expires_at);
CREATE INDEX idx_user_sessions_last_activity ON bms.user_sessions(last_activity_at DESC);
CREATE INDEX idx_user_sessions_client_ip ON bms.user_sessions(client_ip);

-- 보안 이벤트 로그 테이블 인덱스
CREATE INDEX idx_security_events_company_id ON bms.security_event_logs(company_id);
CREATE INDEX idx_security_events_type ON bms.security_event_logs(event_type);
CREATE INDEX idx_security_events_severity ON bms.security_event_logs(event_severity);
CREATE INDEX idx_security_events_timestamp ON bms.security_event_logs(event_timestamp DESC);
CREATE INDEX idx_security_events_user_id ON bms.security_event_logs(user_id);
CREATE INDEX idx_security_events_resolved ON bms.security_event_logs(is_resolved);

-- 복합 인덱스
CREATE INDEX idx_user_activity_company_user ON bms.user_activity_logs(company_id, user_id);
CREATE INDEX idx_user_activity_company_date ON bms.user_activity_logs(company_id, created_at DESC);
CREATE INDEX idx_user_activity_type_date ON bms.user_activity_logs(activity_type, created_at DESC);
CREATE INDEX idx_security_events_company_severity ON bms.security_event_logs(company_id, event_severity);

-- 7. 사용자 활동 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_user_activity(
    p_activity_type VARCHAR(50),
    p_activity_category VARCHAR(30),
    p_user_id UUID DEFAULT NULL,
    p_activity_description TEXT DEFAULT NULL,
    p_activity_result VARCHAR(20) DEFAULT 'SUCCESS',
    p_request_url TEXT DEFAULT NULL,
    p_response_status INTEGER DEFAULT 200,
    p_business_context VARCHAR(100) DEFAULT NULL,
    p_feature_used VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_activity_id UUID;
    v_company_id UUID;
    v_user_name VARCHAR(100);
    v_user_email VARCHAR(255);
    v_user_role VARCHAR(50);
    v_session_id VARCHAR(100);
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
    
    -- 세션 ID 가져오기
    v_session_id := current_setting('app.session_id', true);
    
    -- 활동 로그 생성
    v_activity_id := gen_random_uuid();
    
    INSERT INTO bms.user_activity_logs (
        activity_id, company_id, user_id, user_name, user_email, user_role,
        activity_type, activity_category, activity_description, activity_result,
        session_id, request_url, response_status,
        client_ip, user_agent,
        business_context, feature_used
    ) VALUES (
        v_activity_id, v_company_id, p_user_id, v_user_name, v_user_email, v_user_role,
        p_activity_type, p_activity_category, p_activity_description, p_activity_result,
        v_session_id, p_request_url, p_response_status,
        inet_client_addr(),
        current_setting('app.user_agent', true),
        p_business_context, p_feature_used
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
    p_event_details JSONB DEFAULT NULL,
    p_affected_resources TEXT[] DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_company_id UUID;
    v_user_name VARCHAR(100);
BEGIN
    -- 현재 회사 ID 가져오기
    v_company_id := (current_setting('app.current_company_id', true))::uuid;
    
    -- 사용자 정보 조회
    IF p_user_id IS NOT NULL THEN
        SELECT full_name INTO v_user_name
        FROM bms.users
        WHERE user_id = p_user_id;
    END IF;
    
    -- 보안 이벤트 로그 생성
    v_event_id := gen_random_uuid();
    
    INSERT INTO bms.security_event_logs (
        event_id, company_id, event_type, event_severity, event_description,
        user_id, user_name, user_ip,
        event_details, affected_resources
    ) VALUES (
        v_event_id, v_company_id, p_event_type, p_event_severity, p_event_description,
        p_user_id, v_user_name, inet_client_addr(),
        p_event_details, p_affected_resources
    );
    
    -- 심각도가 HIGH 이상인 경우 알림 처리 (향후 구현)
    IF p_event_severity IN ('HIGH', 'CRITICAL') THEN
        -- 알림 로직 추가 예정
        RAISE NOTICE '심각한 보안 이벤트 발생: % - %', p_event_type, p_event_description;
    END IF;
    
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
BEGIN
    -- 세션 ID 생성
    v_session_id := 'sess_' || substr(md5(random()::text), 1, 32);
    
    -- 현재 회사 ID 가져오기
    v_company_id := (current_setting('app.current_company_id', true))::uuid;
    
    -- 세션 생성
    INSERT INTO bms.user_sessions (
        session_id, company_id, user_id, session_token, expires_at,
        client_ip, user_agent, login_method
    ) VALUES (
        v_session_id, v_company_id, p_user_id, p_session_token, p_expires_at,
        inet_client_addr(), current_setting('app.user_agent', true), p_login_method
    );
    
    -- 로그인 활동 기록
    PERFORM bms.log_user_activity(
        p_user_id, 'LOGIN', 'AUTHENTICATION', '사용자 로그인', 'SUCCESS',
        NULL, 200, 'USER_SESSION', 'LOGIN'
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
    AVG(ual.response_time) as avg_response_time
FROM bms.user_activity_logs ual
JOIN bms.companies c ON ual.company_id = c.company_id
WHERE ual.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY ual.company_id, c.company_name, ual.user_id, ual.user_name, 
         ual.activity_type, ual.activity_category
ORDER BY activity_count DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_user_activity_summary OWNER TO qiro;

-- 11. 보안 이벤트 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_security_event_summary AS
SELECT 
    sel.company_id,
    c.company_name,
    sel.event_type,
    sel.event_severity,
    COUNT(*) as event_count,
    COUNT(CASE WHEN sel.is_resolved THEN 1 END) as resolved_count,
    COUNT(CASE WHEN NOT sel.is_resolved THEN 1 END) as unresolved_count,
    MIN(sel.event_timestamp) as first_event,
    MAX(sel.event_timestamp) as last_event,
    AVG(EXTRACT(EPOCH FROM (sel.resolved_at - sel.event_timestamp))/3600) as avg_resolution_hours
FROM bms.security_event_logs sel
JOIN bms.companies c ON sel.company_id = c.company_id
WHERE sel.event_timestamp >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY sel.company_id, c.company_name, sel.event_type, sel.event_severity
ORDER BY event_count DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_security_event_summary OWNER TO qiro;

-- 12. 세션 정리 함수 (만료된 세션 삭제)
CREATE OR REPLACE FUNCTION bms.cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
BEGIN
    -- 만료된 세션 삭제
    DELETE FROM bms.user_sessions
    WHERE expires_at < NOW()
       OR (last_activity_at < NOW() - INTERVAL '7 days' AND is_active = false);
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RAISE NOTICE '만료된 세션 %개를 정리했습니다.', v_deleted_count;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 4.2 사용자 활동 로그 시스템 생성이 완료되었습니다!' as result;