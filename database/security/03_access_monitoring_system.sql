-- =====================================================
-- QIRO 접근 로그 및 보안 모니터링 시스템
-- 로그인 추적, 권한 변경 이력, 의심스러운 활동 감지
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 로그인 시도 및 세션 관리 테이블
-- =====================================================

-- 로그인 시도 상세 로그 (기존 audit_logs 확장)
CREATE TABLE login_attempt_logs (
    attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    
    -- 로그인 시도 정보
    email_attempted VARCHAR(255) NOT NULL,
    login_method VARCHAR(20) NOT NULL DEFAULT 'PASSWORD', -- PASSWORD, MFA, SSO, etc.
    attempt_result VARCHAR(20) NOT NULL,
    failure_reason VARCHAR(100),
    
    -- 보안 정보
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_fingerprint VARCHAR(255), -- 디바이스 지문
    geolocation JSONB, -- 지리적 위치 정보
    
    -- 위험 평가
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    risk_factors TEXT[], -- 위험 요소들
    is_suspicious BOOLEAN DEFAULT false,
    
    -- 세션 정보
    session_id VARCHAR(255),
    session_duration_seconds INTEGER,
    
    -- 시간 정보
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    session_ended_at TIMESTAMPTZ,
    
    -- 인덱스를 위한 필드
    attempt_date DATE GENERATED ALWAYS AS (attempted_at::DATE) STORED,
    
    CONSTRAINT chk_attempt_result CHECK (
        attempt_result IN ('SUCCESS', 'INVALID_CREDENTIALS', 'ACCOUNT_LOCKED', 'MFA_REQUIRED', 
                          'MFA_FAILED', 'RATE_LIMITED', 'SUSPICIOUS_ACTIVITY', 'SYSTEM_ERROR')
    ),
    CONSTRAINT chk_login_method CHECK (
        login_method IN ('PASSWORD', 'MFA', 'SSO', 'API_KEY', 'REFRESH_TOKEN')
    )
);

-- 인덱스 생성
CREATE INDEX idx_login_attempts_user_id ON login_attempt_logs(user_id);
CREATE INDEX idx_login_attempts_company_id ON login_attempt_logs(company_id);
CREATE INDEX idx_login_attempts_ip_address ON login_attempt_logs(ip_address);
CREATE INDEX idx_login_attempts_attempted_at ON login_attempt_logs(attempted_at DESC);
CREATE INDEX idx_login_attempts_result ON login_attempt_logs(attempt_result);
CREATE INDEX idx_login_attempts_suspicious ON login_attempt_logs(is_suspicious) WHERE is_suspicious = true;
CREATE INDEX idx_login_attempts_date ON login_attempt_logs(attempt_date);

-- =====================================================
-- 2. 권한 변경 이력 테이블
-- =====================================================

-- 권한 및 역할 변경 이력
CREATE TABLE permission_change_logs (
    change_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 변경 대상 정보
    target_user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    target_role_id UUID REFERENCES roles(role_id) ON DELETE SET NULL,
    target_group_id UUID REFERENCES building_groups(group_id) ON DELETE SET NULL,
    
    -- 변경 수행자 정보
    changed_by_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    change_reason VARCHAR(200),
    
    -- 변경 내용
    change_type VARCHAR(50) NOT NULL,
    change_scope VARCHAR(50) NOT NULL,
    
    -- 변경 전/후 데이터
    previous_permissions JSONB,
    new_permissions JSONB,
    permission_diff JSONB, -- 변경된 권한들만
    
    -- 승인 정보 (필요한 경우)
    requires_approval BOOLEAN DEFAULT false,
    approved_by_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- 메타데이터
    ip_address INET,
    user_agent TEXT,
    
    -- 시간 정보
    changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    effective_from TIMESTAMPTZ DEFAULT now(),
    effective_until TIMESTAMPTZ,
    
    CONSTRAINT chk_change_type CHECK (
        change_type IN ('ROLE_ASSIGNED', 'ROLE_REVOKED', 'PERMISSION_GRANTED', 'PERMISSION_REVOKED',
                       'GROUP_ASSIGNED', 'GROUP_REMOVED', 'ACCESS_LEVEL_CHANGED', 'BULK_CHANGE')
    ),
    CONSTRAINT chk_change_scope CHECK (
        change_scope IN ('USER', 'ROLE', 'GROUP', 'SYSTEM', 'COMPANY')
    ),
    CONSTRAINT chk_approval_status CHECK (
        approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'AUTO_APPROVED')
    )
);

-- 인덱스 생성
CREATE INDEX idx_permission_changes_target_user ON permission_change_logs(target_user_id);
CREATE INDEX idx_permission_changes_changed_by ON permission_change_logs(changed_by_user_id);
CREATE INDEX idx_permission_changes_company_id ON permission_change_logs(company_id);
CREATE INDEX idx_permission_changes_changed_at ON permission_change_logs(changed_at DESC);
CREATE INDEX idx_permission_changes_type ON permission_change_logs(change_type);
CREATE INDEX idx_permission_changes_approval ON permission_change_logs(approval_status) 
    WHERE requires_approval = true;

-- =====================================================
-- 3. 의심스러운 활동 감지 테이블
-- =====================================================

-- 보안 이벤트 및 위협 탐지
CREATE TABLE security_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    
    -- 이벤트 분류
    event_type VARCHAR(50) NOT NULL,
    severity_level VARCHAR(20) NOT NULL DEFAULT 'LOW',
    threat_category VARCHAR(50),
    
    -- 이벤트 상세
    event_title VARCHAR(200) NOT NULL,
    event_description TEXT NOT NULL,
    event_data JSONB,
    
    -- 위험 평가
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    confidence_level NUMERIC(3,2) DEFAULT 0.5 CHECK (confidence_level >= 0 AND confidence_level <= 1),
    
    -- 탐지 정보
    detection_method VARCHAR(50), -- RULE_BASED, ML_MODEL, ANOMALY_DETECTION, etc.
    detection_rule VARCHAR(100),
    false_positive BOOLEAN DEFAULT false,
    
    -- 대응 정보
    status VARCHAR(20) DEFAULT 'OPEN',
    assigned_to_user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    resolution_notes TEXT,
    resolved_at TIMESTAMPTZ,
    
    -- 메타데이터
    ip_address INET,
    user_agent TEXT,
    related_session_id VARCHAR(255),
    
    -- 시간 정보
    detected_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    first_seen_at TIMESTAMPTZ DEFAULT now(),
    last_seen_at TIMESTAMPTZ DEFAULT now(),
    
    CONSTRAINT chk_event_type CHECK (
        event_type IN ('BRUTE_FORCE', 'UNUSUAL_LOGIN_LOCATION', 'MULTIPLE_FAILED_MFA', 
                      'PRIVILEGE_ESCALATION', 'DATA_EXFILTRATION', 'UNUSUAL_ACCESS_PATTERN',
                      'ACCOUNT_TAKEOVER', 'INSIDER_THREAT', 'MALICIOUS_IP', 'RATE_LIMIT_EXCEEDED')
    ),
    CONSTRAINT chk_severity_level CHECK (
        severity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')
    ),
    CONSTRAINT chk_status CHECK (
        status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE', 'IGNORED')
    )
);

-- 인덱스 생성
CREATE INDEX idx_security_events_company_id ON security_events(company_id);
CREATE INDEX idx_security_events_user_id ON security_events(user_id);
CREATE INDEX idx_security_events_detected_at ON security_events(detected_at DESC);
CREATE INDEX idx_security_events_severity ON security_events(severity_level);
CREATE INDEX idx_security_events_status ON security_events(status);
CREATE INDEX idx_security_events_type ON security_events(event_type);
CREATE INDEX idx_security_events_risk_score ON security_events(risk_score DESC);

-- =====================================================
-- 4. 실시간 모니터링 뷰
-- =====================================================

-- 실시간 로그인 활동 뷰
CREATE OR REPLACE VIEW real_time_login_activity AS
SELECT 
    lal.attempt_id,
    lal.company_id,
    c.company_name,
    lal.user_id,
    u.email,
    u.full_name,
    lal.email_attempted,
    lal.attempt_result,
    lal.failure_reason,
    lal.ip_address,
    lal.risk_score,
    lal.is_suspicious,
    lal.attempted_at,
    lal.session_duration_seconds
FROM login_attempt_logs lal
LEFT JOIN companies c ON lal.company_id = c.company_id
LEFT JOIN users u ON lal.user_id = u.user_id
WHERE lal.attempted_at >= now() - INTERVAL '24 hours'
ORDER BY lal.attempted_at DESC;

-- 활성 보안 이벤트 뷰
CREATE OR REPLACE VIEW active_security_events AS
SELECT 
    se.event_id,
    se.company_id,
    c.company_name,
    se.user_id,
    u.email as user_email,
    se.event_type,
    se.severity_level,
    se.event_title,
    se.risk_score,
    se.confidence_level,
    se.status,
    se.detected_at,
    se.last_seen_at,
    assigned_user.email as assigned_to_email
FROM security_events se
LEFT JOIN companies c ON se.company_id = c.company_id
LEFT JOIN users u ON se.user_id = u.user_id
LEFT JOIN users assigned_user ON se.assigned_to_user_id = assigned_user.user_id
WHERE se.status IN ('OPEN', 'INVESTIGATING')
ORDER BY se.risk_score DESC, se.detected_at DESC;

-- 권한 변경 요약 뷰
CREATE OR REPLACE VIEW recent_permission_changes AS
SELECT 
    pcl.change_id,
    pcl.company_id,
    c.company_name,
    target_user.email as target_user_email,
    target_user.full_name as target_user_name,
    changed_by_user.email as changed_by_email,
    pcl.change_type,
    pcl.change_scope,
    pcl.change_reason,
    pcl.approval_status,
    pcl.changed_at,
    pcl.effective_from
FROM permission_change_logs pcl
LEFT JOIN companies c ON pcl.company_id = c.company_id
LEFT JOIN users target_user ON pcl.target_user_id = target_user.user_id
LEFT JOIN users changed_by_user ON pcl.changed_by_user_id = changed_by_user.user_id
WHERE pcl.changed_at >= now() - INTERVAL '7 days'
ORDER BY pcl.changed_at DESC;

-- =====================================================
-- 5. 로그인 시도 추적 함수들
-- =====================================================

-- 로그인 시도 기록
CREATE OR REPLACE FUNCTION log_login_attempt(
    p_email VARCHAR(255),
    p_company_id UUID,
    p_user_id UUID,
    p_attempt_result VARCHAR(20),
    p_failure_reason VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_session_id VARCHAR(255) DEFAULT NULL,
    p_login_method VARCHAR(20) DEFAULT 'PASSWORD'
)
RETURNS UUID AS $
DECLARE
    attempt_id UUID;
    calculated_risk_score INTEGER := 0;
    risk_factors TEXT[] := ARRAY[]::TEXT[];
    is_suspicious_activity BOOLEAN := false;
BEGIN
    -- 위험 점수 계산
    calculated_risk_score := calculate_login_risk_score(
        p_email, p_company_id, p_user_id, p_attempt_result, p_ip_address
    );
    
    -- 위험 요소 분석
    risk_factors := analyze_login_risk_factors(
        p_email, p_company_id, p_user_id, p_ip_address, p_user_agent
    );
    
    -- 의심스러운 활동 판단
    is_suspicious_activity := calculated_risk_score >= 70;
    
    -- 로그인 시도 기록
    INSERT INTO login_attempt_logs (
        company_id,
        user_id,
        email_attempted,
        login_method,
        attempt_result,
        failure_reason,
        ip_address,
        user_agent,
        session_id,
        risk_score,
        risk_factors,
        is_suspicious
    ) VALUES (
        p_company_id,
        p_user_id,
        p_email,
        p_login_method,
        p_attempt_result,
        p_failure_reason,
        p_ip_address,
        p_user_agent,
        p_session_id,
        calculated_risk_score,
        risk_factors,
        is_suspicious_activity
    ) RETURNING attempt_id INTO attempt_id;
    
    -- 의심스러운 활동인 경우 보안 이벤트 생성
    IF is_suspicious_activity THEN
        PERFORM create_security_event(
            p_company_id,
            p_user_id,
            'SUSPICIOUS_LOGIN',
            'HIGH',
            format('의심스러운 로그인 시도: %s', p_email),
            format('위험 점수 %s로 의심스러운 로그인 시도가 감지되었습니다.', calculated_risk_score),
            jsonb_build_object(
                'attempt_id', attempt_id,
                'risk_factors', risk_factors,
                'ip_address', p_ip_address::TEXT
            ),
            p_ip_address,
            p_user_agent
        );
    END IF;
    
    RETURN attempt_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 로그인 위험 점수 계산
CREATE OR REPLACE FUNCTION calculate_login_risk_score(
    p_email VARCHAR(255),
    p_company_id UUID,
    p_user_id UUID,
    p_attempt_result VARCHAR(20),
    p_ip_address INET
)
RETURNS INTEGER AS $
DECLARE
    risk_score INTEGER := 0;
    recent_failures INTEGER;
    ip_history_count INTEGER;
    unusual_time BOOLEAN;
    current_hour INTEGER;
BEGIN
    -- 기본 점수 (실패한 로그인)
    IF p_attempt_result != 'SUCCESS' THEN
        risk_score := risk_score + 20;
    END IF;
    
    -- 최근 실패 횟수 확인 (지난 1시간)
    SELECT COUNT(*) INTO recent_failures
    FROM login_attempt_logs
    WHERE email_attempted = p_email
    AND attempted_at >= now() - INTERVAL '1 hour'
    AND attempt_result != 'SUCCESS';
    
    -- 연속 실패에 따른 점수 증가
    IF recent_failures >= 3 THEN
        risk_score := risk_score + 30;
    ELSIF recent_failures >= 5 THEN
        risk_score := risk_score + 50;
    END IF;
    
    -- IP 주소 이력 확인
    IF p_user_id IS NOT NULL THEN
        SELECT COUNT(DISTINCT ip_address) INTO ip_history_count
        FROM login_attempt_logs
        WHERE user_id = p_user_id
        AND attempted_at >= now() - INTERVAL '30 days'
        AND attempt_result = 'SUCCESS';
        
        -- 새로운 IP에서의 접근
        IF NOT EXISTS (
            SELECT 1 FROM login_attempt_logs
            WHERE user_id = p_user_id
            AND ip_address = p_ip_address
            AND attempt_result = 'SUCCESS'
            AND attempted_at >= now() - INTERVAL '30 days'
        ) THEN
            risk_score := risk_score + 25;
        END IF;
    END IF;
    
    -- 비정상적인 시간대 확인 (새벽 2-6시)
    current_hour := EXTRACT(HOUR FROM now());
    IF current_hour >= 2 AND current_hour <= 6 THEN
        risk_score := risk_score + 15;
    END IF;
    
    -- 최대 100점으로 제한
    RETURN LEAST(risk_score, 100);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 로그인 위험 요소 분석
CREATE OR REPLACE FUNCTION analyze_login_risk_factors(
    p_email VARCHAR(255),
    p_company_id UUID,
    p_user_id UUID,
    p_ip_address INET,
    p_user_agent TEXT
)
RETURNS TEXT[] AS $
DECLARE
    risk_factors TEXT[] := ARRAY[]::TEXT[];
    recent_failures INTEGER;
    current_hour INTEGER;
BEGIN
    -- 최근 실패 횟수 확인
    SELECT COUNT(*) INTO recent_failures
    FROM login_attempt_logs
    WHERE email_attempted = p_email
    AND attempted_at >= now() - INTERVAL '1 hour'
    AND attempt_result != 'SUCCESS';
    
    IF recent_failures >= 3 THEN
        risk_factors := array_append(risk_factors, 'MULTIPLE_RECENT_FAILURES');
    END IF;
    
    -- 새로운 IP 주소
    IF p_user_id IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM login_attempt_logs
        WHERE user_id = p_user_id
        AND ip_address = p_ip_address
        AND attempt_result = 'SUCCESS'
        AND attempted_at >= now() - INTERVAL '30 days'
    ) THEN
        risk_factors := array_append(risk_factors, 'NEW_IP_ADDRESS');
    END IF;
    
    -- 비정상적인 시간대
    current_hour := EXTRACT(HOUR FROM now());
    IF current_hour >= 2 AND current_hour <= 6 THEN
        risk_factors := array_append(risk_factors, 'UNUSUAL_TIME');
    END IF;
    
    -- 의심스러운 User-Agent (간단한 검사)
    IF p_user_agent IS NULL OR length(p_user_agent) < 10 THEN
        risk_factors := array_append(risk_factors, 'SUSPICIOUS_USER_AGENT');
    END IF;
    
    RETURN risk_factors;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. 권한 변경 추적 함수들
-- =====================================================

-- 권한 변경 기록
CREATE OR REPLACE FUNCTION log_permission_change(
    p_company_id UUID,
    p_target_user_id UUID,
    p_changed_by_user_id UUID,
    p_change_type VARCHAR(50),
    p_change_scope VARCHAR(50),
    p_previous_permissions JSONB,
    p_new_permissions JSONB,
    p_change_reason VARCHAR(200) DEFAULT NULL,
    p_target_role_id UUID DEFAULT NULL,
    p_target_group_id UUID DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    change_id UUID;
    permission_diff JSONB;
BEGIN
    -- 권한 차이 계산
    permission_diff := jsonb_build_object(
        'added', p_new_permissions - p_previous_permissions,
        'removed', p_previous_permissions - p_new_permissions
    );
    
    -- 권한 변경 기록
    INSERT INTO permission_change_logs (
        company_id,
        target_user_id,
        target_role_id,
        target_group_id,
        changed_by_user_id,
        change_reason,
        change_type,
        change_scope,
        previous_permissions,
        new_permissions,
        permission_diff,
        ip_address,
        user_agent
    ) VALUES (
        p_company_id,
        p_target_user_id,
        p_target_role_id,
        p_target_group_id,
        p_changed_by_user_id,
        p_change_reason,
        p_change_type,
        p_change_scope,
        p_previous_permissions,
        p_new_permissions,
        permission_diff,
        p_ip_address,
        p_user_agent
    ) RETURNING permission_change_logs.change_id INTO change_id;
    
    -- 감사 로그에도 기록
    PERFORM log_audit_event(
        'PERMISSION_CHANGE',
        'ACCESS_CONTROL',
        format('%s 권한이 변경되었습니다', p_change_type),
        'PERMISSION_CHANGE',
        change_id::TEXT,
        jsonb_build_object(
            'change_type', p_change_type,
            'target_user_id', p_target_user_id,
            'changed_by_user_id', p_changed_by_user_id,
            'permission_diff', permission_diff
        ),
        p_ip_address,
        p_user_agent
    );
    
    RETURN change_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. 보안 이벤트 생성 및 관리 함수들
-- =====================================================

-- 보안 이벤트 생성
CREATE OR REPLACE FUNCTION create_security_event(
    p_company_id UUID,
    p_user_id UUID,
    p_event_type VARCHAR(50),
    p_severity_level VARCHAR(20),
    p_event_title VARCHAR(200),
    p_event_description TEXT,
    p_event_data JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_detection_method VARCHAR(50) DEFAULT 'RULE_BASED'
)
RETURNS UUID AS $
DECLARE
    event_id UUID;
    calculated_risk_score INTEGER;
BEGIN
    -- 위험 점수 계산 (간단한 매핑)
    calculated_risk_score := CASE p_severity_level
        WHEN 'LOW' THEN 25
        WHEN 'MEDIUM' THEN 50
        WHEN 'HIGH' THEN 75
        WHEN 'CRITICAL' THEN 100
        ELSE 50
    END;
    
    -- 보안 이벤트 생성
    INSERT INTO security_events (
        company_id,
        user_id,
        event_type,
        severity_level,
        event_title,
        event_description,
        event_data,
        risk_score,
        detection_method,
        ip_address,
        user_agent
    ) VALUES (
        p_company_id,
        p_user_id,
        p_event_type,
        p_severity_level,
        p_event_title,
        p_event_description,
        p_event_data,
        calculated_risk_score,
        p_detection_method,
        p_ip_address,
        p_user_agent
    ) RETURNING security_events.event_id INTO event_id;
    
    -- 감사 로그에도 기록
    PERFORM log_audit_event(
        'SECURITY_EVENT',
        'SECURITY',
        p_event_title,
        'SECURITY_EVENT',
        event_id::TEXT,
        p_event_data,
        p_ip_address,
        p_user_agent
    );
    
    RETURN event_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 의심스러운 활동 패턴 감지
CREATE OR REPLACE FUNCTION detect_suspicious_patterns()
RETURNS TABLE (
    company_id UUID,
    user_id UUID,
    pattern_type VARCHAR(50),
    severity VARCHAR(20),
    description TEXT,
    evidence JSONB
) AS $
BEGIN
    -- 브루트 포스 공격 감지
    RETURN QUERY
    SELECT 
        lal.company_id,
        lal.user_id,
        'BRUTE_FORCE'::VARCHAR(50),
        'HIGH'::VARCHAR(20),
        format('사용자 %s에 대한 %s회의 연속 로그인 실패', lal.email_attempted, COUNT(*)),
        jsonb_build_object(
            'failed_attempts', COUNT(*),
            'time_window', '1 hour',
            'ip_addresses', array_agg(DISTINCT lal.ip_address::TEXT)
        )
    FROM login_attempt_logs lal
    WHERE lal.attempted_at >= now() - INTERVAL '1 hour'
    AND lal.attempt_result != 'SUCCESS'
    GROUP BY lal.company_id, lal.user_id, lal.email_attempted
    HAVING COUNT(*) >= 5;
    
    -- 비정상적인 접근 위치 감지
    RETURN QUERY
    SELECT 
        lal.company_id,
        lal.user_id,
        'UNUSUAL_LOCATION'::VARCHAR(50),
        'MEDIUM'::VARCHAR(20),
        format('사용자가 새로운 위치에서 로그인: %s', lal.ip_address::TEXT),
        jsonb_build_object(
            'new_ip', lal.ip_address::TEXT,
            'previous_ips', (
                SELECT array_agg(DISTINCT prev.ip_address::TEXT)
                FROM login_attempt_logs prev
                WHERE prev.user_id = lal.user_id
                AND prev.attempt_result = 'SUCCESS'
                AND prev.attempted_at >= now() - INTERVAL '30 days'
                AND prev.attempted_at < lal.attempted_at
            )
        )
    FROM login_attempt_logs lal
    WHERE lal.attempted_at >= now() - INTERVAL '24 hours'
    AND lal.attempt_result = 'SUCCESS'
    AND lal.user_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM login_attempt_logs prev
        WHERE prev.user_id = lal.user_id
        AND prev.ip_address = lal.ip_address
        AND prev.attempt_result = 'SUCCESS'
        AND prev.attempted_at >= now() - INTERVAL '30 days'
        AND prev.attempted_at < lal.attempted_at
    );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. 모니터링 및 통계 함수들
-- =====================================================

-- 로그인 통계 조회
CREATE OR REPLACE FUNCTION get_login_statistics(
    p_company_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '7 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    date DATE,
    total_attempts BIGINT,
    successful_logins BIGINT,
    failed_attempts BIGINT,
    unique_users BIGINT,
    suspicious_attempts BIGINT,
    success_rate NUMERIC(5,2)
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        lal.attempt_date,
        COUNT(*) as total_attempts,
        COUNT(*) FILTER (WHERE lal.attempt_result = 'SUCCESS') as successful_logins,
        COUNT(*) FILTER (WHERE lal.attempt_result != 'SUCCESS') as failed_attempts,
        COUNT(DISTINCT lal.user_id) as unique_users,
        COUNT(*) FILTER (WHERE lal.is_suspicious = true) as suspicious_attempts,
        ROUND(
            COUNT(*) FILTER (WHERE lal.attempt_result = 'SUCCESS')::NUMERIC / 
            NULLIF(COUNT(*), 0) * 100, 2
        ) as success_rate
    FROM login_attempt_logs lal
    WHERE lal.company_id = p_company_id
    AND lal.attempt_date BETWEEN p_start_date AND p_end_date
    GROUP BY lal.attempt_date
    ORDER BY lal.attempt_date;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 보안 이벤트 요약
CREATE OR REPLACE FUNCTION get_security_event_summary(
    p_company_id UUID,
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    event_type VARCHAR(50),
    severity_level VARCHAR(20),
    event_count BIGINT,
    avg_risk_score NUMERIC(5,2),
    open_events BIGINT,
    resolved_events BIGINT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        se.event_type,
        se.severity_level,
        COUNT(*) as event_count,
        ROUND(AVG(se.risk_score), 2) as avg_risk_score,
        COUNT(*) FILTER (WHERE se.status IN ('OPEN', 'INVESTIGATING')) as open_events,
        COUNT(*) FILTER (WHERE se.status = 'RESOLVED') as resolved_events
    FROM security_events se
    WHERE se.company_id = p_company_id
    AND se.detected_at >= now() - (p_days || ' days')::INTERVAL
    GROUP BY se.event_type, se.severity_level
    ORDER BY event_count DESC, avg_risk_score DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. 자동 정리 및 유지보수 함수들
-- =====================================================

-- 오래된 로그 정리
CREATE OR REPLACE FUNCTION cleanup_old_security_logs()
RETURNS TABLE (
    table_name TEXT,
    deleted_count BIGINT
) AS $
DECLARE
    login_deleted BIGINT;
    permission_deleted BIGINT;
    security_deleted BIGINT;
BEGIN
    -- 90일 이상 된 로그인 시도 로그 삭제
    DELETE FROM login_attempt_logs
    WHERE attempted_at <= now() - INTERVAL '90 days';
    GET DIAGNOSTICS login_deleted = ROW_COUNT;
    
    -- 1년 이상 된 권한 변경 로그 삭제
    DELETE FROM permission_change_logs
    WHERE changed_at <= now() - INTERVAL '1 year';
    GET DIAGNOSTICS permission_deleted = ROW_COUNT;
    
    -- 해결된 보안 이벤트 중 6개월 이상 된 것 삭제
    DELETE FROM security_events
    WHERE status = 'RESOLVED' 
    AND resolved_at <= now() - INTERVAL '6 months';
    GET DIAGNOSTICS security_deleted = ROW_COUNT;
    
    RETURN QUERY VALUES
        ('login_attempt_logs', login_deleted),
        ('permission_change_logs', permission_deleted),
        ('security_events', security_deleted);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. RLS 정책 설정
-- =====================================================

-- 로그인 시도 로그 RLS
ALTER TABLE login_attempt_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY login_attempts_company_policy ON login_attempt_logs
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 권한 변경 로그 RLS
ALTER TABLE permission_change_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY permission_changes_company_policy ON permission_change_logs
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 보안 이벤트 RLS
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY security_events_company_policy ON security_events
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- =====================================================
-- 11. 코멘트 추가
-- =====================================================

COMMENT ON TABLE login_attempt_logs IS '로그인 시도 상세 로그 및 위험 평가';
COMMENT ON TABLE permission_change_logs IS '권한 및 역할 변경 이력 추적';
COMMENT ON TABLE security_events IS '보안 이벤트 및 위협 탐지 로그';

COMMENT ON FUNCTION log_login_attempt IS '로그인 시도 기록 및 위험 평가';
COMMENT ON FUNCTION log_permission_change IS '권한 변경 이력 기록';
COMMENT ON FUNCTION create_security_event IS '보안 이벤트 생성';
COMMENT ON FUNCTION detect_suspicious_patterns IS '의심스러운 활동 패턴 자동 감지';

-- =====================================================
-- 12. 설정 완료 메시지
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '=== QIRO 접근 로그 및 보안 모니터링 시스템 설정 완료 ===';
    RAISE NOTICE '1. 로그인 시도 추적 시스템 구축 완료';
    RAISE NOTICE '2. 권한 변경 이력 관리 시스템 구축 완료';
    RAISE NOTICE '3. 보안 이벤트 및 위협 탐지 시스템 구축 완료';
    RAISE NOTICE '4. 실시간 모니터링 뷰 생성 완료';
    RAISE NOTICE '5. 의심스러운 활동 자동 감지 시스템 구축 완료';
    RAISE NOTICE '';
    RAISE NOTICE '=== 주요 기능들 ===';
    RAISE NOTICE '- log_login_attempt(): 로그인 시도 기록 및 위험 평가';
    RAISE NOTICE '- log_permission_change(): 권한 변경 이력 기록';
    RAISE NOTICE '- create_security_event(): 보안 이벤트 생성';
    RAISE NOTICE '- detect_suspicious_patterns(): 의심스러운 패턴 감지';
    RAISE NOTICE '- get_login_statistics(): 로그인 통계 조회';
    RAISE NOTICE '';
    RAISE NOTICE '=== 모니터링 뷰들 ===';
    RAISE NOTICE '- real_time_login_activity: 실시간 로그인 활동';
    RAISE NOTICE '- active_security_events: 활성 보안 이벤트';
    RAISE NOTICE '- recent_permission_changes: 최근 권한 변경';
    RAISE NOTICE '';
    RAISE NOTICE '=== 권장사항 ===';
    RAISE NOTICE '1. 정기적인 의심스러운 패턴 감지 실행';
    RAISE NOTICE '2. 보안 이벤트 대응 프로세스 수립';
    RAISE NOTICE '3. 로그 정리 작업 스케줄링';
END $;