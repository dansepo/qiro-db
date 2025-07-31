-- =====================================================
-- QIRO 보안 강화 시스템 통합 실행 스크립트
-- 데이터 암호화, 인증 보안, 접근 모니터링 시스템 통합 설정
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 실행 전 확인사항
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '=== QIRO 보안 강화 시스템 설치 시작 ===';
    RAISE NOTICE '실행 시간: %', now();
    RAISE NOTICE '데이터베이스: %', current_database();
    RAISE NOTICE '사용자: %', current_user;
    RAISE NOTICE '';
    
    -- 필수 확장 기능 확인
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE EXCEPTION 'pgcrypto 확장이 필요합니다. CREATE EXTENSION pgcrypto; 를 먼저 실행하세요.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        RAISE EXCEPTION 'uuid-ossp 확장이 필요합니다. CREATE EXTENSION "uuid-ossp"; 를 먼저 실행하세요.';
    END IF;
    
    RAISE NOTICE '필수 확장 기능 확인 완료';
END $;

-- =====================================================
-- 1단계: 데이터 암호화 시스템 설치
-- =====================================================

\echo '=== 1단계: 데이터 암호화 시스템 설치 ==='

-- 데이터 암호화 시스템 실행
\i database/security/01_data_encryption_security.sql

-- 암호화 컬럼 마이그레이션 실행
\i database/schema/migration_encryption_columns.sql

-- =====================================================
-- 2단계: 인증 보안 강화 시스템 설치
-- =====================================================

\echo '=== 2단계: 인증 보안 강화 시스템 설치 ==='

-- 인증 보안 시스템 실행
\i database/security/02_authentication_security.sql

-- =====================================================
-- 3단계: 접근 로그 및 모니터링 시스템 설치
-- =====================================================

\echo '=== 3단계: 접근 로그 및 모니터링 시스템 설치 ==='

-- 접근 모니터링 시스템 실행
\i database/security/03_access_monitoring_system.sql

-- =====================================================
-- 4단계: 보안 시스템 통합 설정
-- =====================================================

\echo '=== 4단계: 보안 시스템 통합 설정 ==='

-- 보안 관련 사용자 정의 타입 생성 (필요한 경우)
DO $
BEGIN
    -- 보안 이벤트 심각도 타입
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'security_severity') THEN
        CREATE TYPE security_severity AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');
    END IF;
    
    -- 인증 방법 타입
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'auth_method') THEN
        CREATE TYPE auth_method AS ENUM ('PASSWORD', 'MFA', 'SSO', 'API_KEY', 'REFRESH_TOKEN');
    END IF;
    
    RAISE NOTICE '보안 관련 사용자 정의 타입 생성 완료';
END $;

-- 보안 설정 테이블 생성
CREATE TABLE IF NOT EXISTS security_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 보안 정책 설정
    enable_encryption BOOLEAN DEFAULT true,
    enable_mfa BOOLEAN DEFAULT false,
    enable_audit_logging BOOLEAN DEFAULT true,
    enable_suspicious_activity_detection BOOLEAN DEFAULT true,
    
    -- 세션 관리 설정
    session_timeout_minutes INTEGER DEFAULT 480, -- 8시간
    max_concurrent_sessions INTEGER DEFAULT 5,
    require_fresh_login_for_sensitive_ops BOOLEAN DEFAULT true,
    
    -- 알림 설정
    notify_on_suspicious_login BOOLEAN DEFAULT true,
    notify_on_permission_change BOOLEAN DEFAULT true,
    notify_on_security_event BOOLEAN DEFAULT true,
    notification_email VARCHAR(255),
    
    -- 메타데이터
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by UUID REFERENCES users(user_id)
);

-- 기본 보안 설정 생성 함수
CREATE OR REPLACE FUNCTION create_default_security_settings(p_company_id UUID)
RETURNS UUID AS $
DECLARE
    setting_id UUID;
BEGIN
    INSERT INTO security_settings (
        company_id,
        enable_encryption,
        enable_mfa,
        enable_audit_logging,
        enable_suspicious_activity_detection,
        session_timeout_minutes,
        max_concurrent_sessions
    ) VALUES (
        p_company_id,
        true,  -- 암호화 활성화
        false, -- MFA는 선택적
        true,  -- 감사 로깅 활성화
        true,  -- 의심스러운 활동 감지 활성화
        480,   -- 8시간 세션 타임아웃
        5      -- 최대 5개 동시 세션
    ) RETURNING security_settings.setting_id INTO setting_id;
    
    RETURN setting_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 회사 생성 시 기본 보안 설정 자동 생성 트리거
CREATE OR REPLACE FUNCTION create_security_settings_for_company()
RETURNS TRIGGER AS $
BEGIN
    PERFORM create_default_security_settings(NEW.company_id);
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 트리거 생성 (이미 존재하지 않는 경우에만)
DO $
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'company_security_settings_trigger'
    ) THEN
        CREATE TRIGGER company_security_settings_trigger
            AFTER INSERT ON companies
            FOR EACH ROW
            EXECUTE FUNCTION create_security_settings_for_company();
    END IF;
END $;

-- =====================================================
-- 5단계: 보안 모니터링 대시보드 뷰 생성
-- =====================================================

\echo '=== 5단계: 보안 모니터링 대시보드 뷰 생성 ==='

-- 종합 보안 대시보드 뷰
CREATE OR REPLACE VIEW security_dashboard AS
SELECT 
    c.company_id,
    c.company_name,
    
    -- 로그인 통계 (최근 24시간)
    (SELECT COUNT(*) FROM login_attempt_logs lal 
     WHERE lal.company_id = c.company_id 
     AND lal.attempted_at >= now() - INTERVAL '24 hours') as login_attempts_24h,
    
    (SELECT COUNT(*) FROM login_attempt_logs lal 
     WHERE lal.company_id = c.company_id 
     AND lal.attempted_at >= now() - INTERVAL '24 hours'
     AND lal.attempt_result = 'SUCCESS') as successful_logins_24h,
    
    (SELECT COUNT(*) FROM login_attempt_logs lal 
     WHERE lal.company_id = c.company_id 
     AND lal.attempted_at >= now() - INTERVAL '24 hours'
     AND lal.is_suspicious = true) as suspicious_logins_24h,
    
    -- 보안 이벤트 통계
    (SELECT COUNT(*) FROM security_events se 
     WHERE se.company_id = c.company_id 
     AND se.status IN ('OPEN', 'INVESTIGATING')) as open_security_events,
    
    (SELECT COUNT(*) FROM security_events se 
     WHERE se.company_id = c.company_id 
     AND se.severity_level = 'CRITICAL'
     AND se.detected_at >= now() - INTERVAL '7 days') as critical_events_7d,
    
    -- 권한 변경 통계
    (SELECT COUNT(*) FROM permission_change_logs pcl 
     WHERE pcl.company_id = c.company_id 
     AND pcl.changed_at >= now() - INTERVAL '7 days') as permission_changes_7d,
    
    -- MFA 활성화 통계
    (SELECT COUNT(DISTINCT u.user_id) FROM users u
     JOIN mfa_settings ms ON u.user_id = ms.user_id
     WHERE u.company_id = c.company_id 
     AND ms.is_enabled = true) as mfa_enabled_users,
    
    (SELECT COUNT(*) FROM users u 
     WHERE u.company_id = c.company_id 
     AND u.status = 'ACTIVE') as total_active_users,
    
    -- 보안 설정 상태
    ss.enable_encryption,
    ss.enable_mfa,
    ss.enable_audit_logging,
    ss.enable_suspicious_activity_detection,
    
    -- 마지막 업데이트 시간
    now() as dashboard_updated_at
    
FROM companies c
LEFT JOIN security_settings ss ON c.company_id = ss.company_id
WHERE c.verification_status = 'VERIFIED';

-- =====================================================
-- 6단계: 보안 점검 및 권장사항 함수
-- =====================================================

\echo '=== 6단계: 보안 점검 및 권장사항 함수 생성 ==='

-- 보안 상태 점검 함수
CREATE OR REPLACE FUNCTION security_health_check(p_company_id UUID)
RETURNS TABLE (
    check_category VARCHAR(50),
    check_name VARCHAR(100),
    status VARCHAR(20),
    score INTEGER,
    recommendation TEXT
) AS $
DECLARE
    total_users INTEGER;
    mfa_users INTEGER;
    recent_password_changes INTEGER;
    encryption_enabled BOOLEAN;
    audit_enabled BOOLEAN;
BEGIN
    -- 기본 통계 수집
    SELECT COUNT(*) INTO total_users
    FROM users WHERE company_id = p_company_id AND status = 'ACTIVE';
    
    SELECT COUNT(DISTINCT ms.user_id) INTO mfa_users
    FROM mfa_settings ms
    JOIN users u ON ms.user_id = u.user_id
    WHERE u.company_id = p_company_id AND ms.is_enabled = true;
    
    SELECT COUNT(*) INTO recent_password_changes
    FROM password_history ph
    JOIN users u ON ph.user_id = u.user_id
    WHERE u.company_id = p_company_id 
    AND ph.created_at >= now() - INTERVAL '90 days';
    
    SELECT ss.enable_encryption, ss.enable_audit_logging
    INTO encryption_enabled, audit_enabled
    FROM security_settings ss
    WHERE ss.company_id = p_company_id;
    
    -- MFA 활성화 점검
    RETURN QUERY
    SELECT 
        'AUTHENTICATION'::VARCHAR(50),
        'MFA 활성화율'::VARCHAR(100),
        CASE 
            WHEN mfa_users::FLOAT / NULLIF(total_users, 0) >= 0.8 THEN 'GOOD'
            WHEN mfa_users::FLOAT / NULLIF(total_users, 0) >= 0.5 THEN 'WARNING'
            ELSE 'CRITICAL'
        END::VARCHAR(20),
        LEAST(100, (mfa_users::FLOAT / NULLIF(total_users, 0) * 100)::INTEGER),
        CASE 
            WHEN mfa_users::FLOAT / NULLIF(total_users, 0) < 0.5 
            THEN '사용자의 50% 이상이 MFA를 활성화하는 것을 권장합니다.'
            ELSE 'MFA 활성화 상태가 양호합니다.'
        END;
    
    -- 암호화 상태 점검
    RETURN QUERY
    SELECT 
        'DATA_PROTECTION'::VARCHAR(50),
        '데이터 암호화'::VARCHAR(100),
        CASE WHEN encryption_enabled THEN 'GOOD' ELSE 'CRITICAL' END::VARCHAR(20),
        CASE WHEN encryption_enabled THEN 100 ELSE 0 END,
        CASE 
            WHEN NOT encryption_enabled 
            THEN '민감한 데이터 암호화를 활성화하세요.'
            ELSE '데이터 암호화가 활성화되어 있습니다.'
        END;
    
    -- 감사 로깅 점검
    RETURN QUERY
    SELECT 
        'MONITORING'::VARCHAR(50),
        '감사 로깅'::VARCHAR(100),
        CASE WHEN audit_enabled THEN 'GOOD' ELSE 'WARNING' END::VARCHAR(20),
        CASE WHEN audit_enabled THEN 100 ELSE 50 END,
        CASE 
            WHEN NOT audit_enabled 
            THEN '보안 감사를 위해 로깅을 활성화하세요.'
            ELSE '감사 로깅이 활성화되어 있습니다.'
        END;
    
    -- 최근 의심스러운 활동 점검
    RETURN QUERY
    SELECT 
        'THREAT_DETECTION'::VARCHAR(50),
        '최근 보안 위협'::VARCHAR(100),
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM security_events se 
                WHERE se.company_id = p_company_id 
                AND se.severity_level = 'CRITICAL'
                AND se.status IN ('OPEN', 'INVESTIGATING')
            ) THEN 'CRITICAL'
            WHEN EXISTS (
                SELECT 1 FROM security_events se 
                WHERE se.company_id = p_company_id 
                AND se.severity_level = 'HIGH'
                AND se.status IN ('OPEN', 'INVESTIGATING')
            ) THEN 'WARNING'
            ELSE 'GOOD'
        END::VARCHAR(20),
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM security_events se 
                WHERE se.company_id = p_company_id 
                AND se.severity_level IN ('CRITICAL', 'HIGH')
                AND se.status IN ('OPEN', 'INVESTIGATING')
            ) THEN 25
            ELSE 100
        END,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM security_events se 
                WHERE se.company_id = p_company_id 
                AND se.severity_level = 'CRITICAL'
                AND se.status IN ('OPEN', 'INVESTIGATING')
            ) THEN '긴급한 보안 위협이 감지되었습니다. 즉시 확인하세요.'
            WHEN EXISTS (
                SELECT 1 FROM security_events se 
                WHERE se.company_id = p_company_id 
                AND se.severity_level = 'HIGH'
                AND se.status IN ('OPEN', 'INVESTIGATING')
            ) THEN '높은 수준의 보안 위협이 있습니다. 검토가 필요합니다.'
            ELSE '현재 심각한 보안 위협은 감지되지 않았습니다.'
        END;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7단계: 정기 유지보수 작업 함수
-- =====================================================

\echo '=== 7단계: 정기 유지보수 작업 함수 생성 ==='

-- 종합 보안 유지보수 함수
CREATE OR REPLACE FUNCTION run_security_maintenance()
RETURNS TABLE (
    maintenance_task VARCHAR(100),
    records_processed BIGINT,
    status VARCHAR(20),
    message TEXT
) AS $
DECLARE
    expired_tokens INTEGER;
    old_mfa_attempts INTEGER;
    old_password_history INTEGER;
    old_security_logs INTEGER;
    detected_patterns INTEGER;
BEGIN
    -- 만료된 토큰 정리
    SELECT cleanup_expired_tokens() INTO expired_tokens;
    RETURN QUERY SELECT 
        '만료된 토큰 정리'::VARCHAR(100), 
        expired_tokens::BIGINT, 
        'COMPLETED'::VARCHAR(20),
        format('%s개의 만료된 토큰을 정리했습니다.', expired_tokens);
    
    -- 오래된 MFA 시도 로그 정리
    SELECT cleanup_old_mfa_attempts() INTO old_mfa_attempts;
    RETURN QUERY SELECT 
        'MFA 시도 로그 정리'::VARCHAR(100), 
        old_mfa_attempts::BIGINT, 
        'COMPLETED'::VARCHAR(20),
        format('%s개의 오래된 MFA 시도 로그를 정리했습니다.', old_mfa_attempts);
    
    -- 오래된 비밀번호 이력 정리
    SELECT cleanup_old_password_history() INTO old_password_history;
    RETURN QUERY SELECT 
        '비밀번호 이력 정리'::VARCHAR(100), 
        old_password_history::BIGINT, 
        'COMPLETED'::VARCHAR(20),
        format('%s개의 오래된 비밀번호 이력을 정리했습니다.', old_password_history);
    
    -- 보안 로그 정리
    SELECT SUM(deleted_count) INTO old_security_logs
    FROM cleanup_old_security_logs();
    RETURN QUERY SELECT 
        '보안 로그 정리'::VARCHAR(100), 
        old_security_logs::BIGINT, 
        'COMPLETED'::VARCHAR(20),
        format('%s개의 오래된 보안 로그를 정리했습니다.', old_security_logs);
    
    -- 의심스러운 패턴 감지 실행
    SELECT COUNT(*) INTO detected_patterns
    FROM detect_suspicious_patterns();
    
    -- 감지된 패턴에 대한 보안 이벤트 생성
    INSERT INTO security_events (
        company_id, user_id, event_type, severity_level, 
        event_title, event_description, detection_method
    )
    SELECT 
        dp.company_id, dp.user_id, dp.pattern_type, dp.severity,
        format('자동 감지: %s', dp.pattern_type), dp.description, 'AUTOMATED_DETECTION'
    FROM detect_suspicious_patterns() dp;
    
    RETURN QUERY SELECT 
        '의심스러운 패턴 감지'::VARCHAR(100), 
        detected_patterns::BIGINT, 
        'COMPLETED'::VARCHAR(20),
        format('%s개의 의심스러운 패턴을 감지하고 보안 이벤트를 생성했습니다.', detected_patterns);
    
    -- 유지보수 완료 로그
    PERFORM log_audit_event(
        'SYSTEM_MAINTENANCE',
        'SYSTEM_ADMINISTRATION',
        '보안 시스템 정기 유지보수 완료',
        'MAINTENANCE',
        'SECURITY_MAINTENANCE',
        jsonb_build_object(
            'expired_tokens_cleaned', expired_tokens,
            'mfa_attempts_cleaned', old_mfa_attempts,
            'password_history_cleaned', old_password_history,
            'security_logs_cleaned', old_security_logs,
            'patterns_detected', detected_patterns
        )
    );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8단계: 설치 완료 및 검증
-- =====================================================

\echo '=== 8단계: 설치 완료 및 검증 ==='

-- 설치 검증 함수
CREATE OR REPLACE FUNCTION verify_security_installation()
RETURNS TABLE (
    component VARCHAR(50),
    status VARCHAR(20),
    details TEXT
) AS $
BEGIN
    -- 암호화 시스템 검증
    RETURN QUERY
    SELECT 
        'ENCRYPTION'::VARCHAR(50),
        CASE WHEN EXISTS (SELECT 1 FROM encryption_keys WHERE is_active = true) 
             THEN 'INSTALLED' ELSE 'MISSING' END::VARCHAR(20),
        CASE WHEN EXISTS (SELECT 1 FROM encryption_keys WHERE is_active = true)
             THEN '암호화 키가 설정되어 있습니다.'
             ELSE '암호화 키가 설정되지 않았습니다.' END;
    
    -- 인증 시스템 검증
    RETURN QUERY
    SELECT 
        'AUTHENTICATION'::VARCHAR(50),
        CASE WHEN EXISTS (SELECT 1 FROM password_policies WHERE is_active = true) 
             THEN 'INSTALLED' ELSE 'MISSING' END::VARCHAR(20),
        CASE WHEN EXISTS (SELECT 1 FROM password_policies WHERE is_active = true)
             THEN '비밀번호 정책이 설정되어 있습니다.'
             ELSE '비밀번호 정책이 설정되지 않았습니다.' END;
    
    -- 모니터링 시스템 검증
    RETURN QUERY
    SELECT 
        'MONITORING'::VARCHAR(50),
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'login_attempt_logs') 
             THEN 'INSTALLED' ELSE 'MISSING' END::VARCHAR(20),
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'login_attempt_logs')
             THEN '로그인 모니터링 시스템이 설치되어 있습니다.'
             ELSE '로그인 모니터링 시스템이 설치되지 않았습니다.' END;
    
    -- 보안 이벤트 시스템 검증
    RETURN QUERY
    SELECT 
        'SECURITY_EVENTS'::VARCHAR(50),
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_events') 
             THEN 'INSTALLED' ELSE 'MISSING' END::VARCHAR(20),
        CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_events')
             THEN '보안 이벤트 시스템이 설치되어 있습니다.'
             ELSE '보안 이벤트 시스템이 설치되지 않았습니다.' END;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 설치 검증 실행
\echo '=== 보안 시스템 설치 검증 ==='
SELECT * FROM verify_security_installation();

-- =====================================================
-- 최종 완료 메시지
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== QIRO 보안 강화 시스템 설치 완료 ===';
    RAISE NOTICE '설치 완료 시간: %', now();
    RAISE NOTICE '';
    RAISE NOTICE '=== 설치된 보안 컴포넌트 ===';
    RAISE NOTICE '1. 데이터 암호화 시스템';
    RAISE NOTICE '   - AES-256-GCM 암호화/복호화';
    RAISE NOTICE '   - 검색 가능한 해시 시스템';
    RAISE NOTICE '   - 암호화 키 관리 및 회전';
    RAISE NOTICE '';
    RAISE NOTICE '2. 인증 보안 강화 시스템';
    RAISE NOTICE '   - JWT 리프레시 토큰 관리';
    RAISE NOTICE '   - 비밀번호 정책 및 이력 관리';
    RAISE NOTICE '   - 다단계 인증(MFA) 지원';
    RAISE NOTICE '';
    RAISE NOTICE '3. 접근 로그 및 모니터링 시스템';
    RAISE NOTICE '   - 로그인 시도 추적 및 위험 평가';
    RAISE NOTICE '   - 권한 변경 이력 관리';
    RAISE NOTICE '   - 보안 이벤트 및 위협 탐지';
    RAISE NOTICE '   - 의심스러운 활동 자동 감지';
    RAISE NOTICE '';
    RAISE NOTICE '=== 주요 관리 함수 ===';
    RAISE NOTICE '- security_health_check(company_id): 보안 상태 점검';
    RAISE NOTICE '- run_security_maintenance(): 정기 유지보수';
    RAISE NOTICE '- verify_security_installation(): 설치 검증';
    RAISE NOTICE '';
    RAISE NOTICE '=== 모니터링 뷰 ===';
    RAISE NOTICE '- security_dashboard: 종합 보안 대시보드';
    RAISE NOTICE '- real_time_login_activity: 실시간 로그인 활동';
    RAISE NOTICE '- active_security_events: 활성 보안 이벤트';
    RAISE NOTICE '- recent_permission_changes: 최근 권한 변경';
    RAISE NOTICE '';
    RAISE NOTICE '=== 권장 사항 ===';
    RAISE NOTICE '1. 정기적인 보안 점검 실행: SELECT * FROM security_health_check(company_id);';
    RAISE NOTICE '2. 주기적인 유지보수 작업: SELECT * FROM run_security_maintenance();';
    RAISE NOTICE '3. 보안 대시보드 모니터링: SELECT * FROM security_dashboard;';
    RAISE NOTICE '4. 암호화 키 정기 회전 정책 수립';
    RAISE NOTICE '5. 보안 이벤트 대응 프로세스 구축';
    RAISE NOTICE '';
    RAISE NOTICE '보안 시스템이 성공적으로 설치되었습니다!';
END $;