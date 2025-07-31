-- =====================================================
-- 사용자 활동 로그 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    user_rec RECORD;
    session_rec RECORD;
    activity_count INTEGER := 0;
    session_count INTEGER := 0;
    security_event_count INTEGER := 0;
    i INTEGER;
    j INTEGER;
    v_session_id VARCHAR(100);
    v_activity_types VARCHAR(50)[] := ARRAY[
        'LOGIN', 'LOGOUT', 'PAGE_VIEW', 'SEARCH', 'CREATE', 'READ', 'UPDATE', 'DELETE',
        'DOWNLOAD', 'UPLOAD', 'EXPORT', 'IMPORT', 'REPORT_GENERATE', 'CONFIG_CHANGE'
    ];
    v_activity_categories VARCHAR(30)[] := ARRAY[
        'AUTHENTICATION', 'DATA_ACCESS', 'DATA_MODIFICATION', 'SYSTEM_ADMIN', 
        'USER_INTERFACE', 'REPORTING', 'SECURITY'
    ];
    v_security_events VARCHAR(50)[] := ARRAY[
        'FAILED_LOGIN', 'BRUTE_FORCE', 'SUSPICIOUS_IP', 'UNAUTHORIZED_ACCESS',
        'ACCOUNT_LOCKOUT', 'API_ABUSE', 'RATE_LIMIT_EXCEEDED'
    ];
    v_browsers VARCHAR(50)[] := ARRAY['Chrome', 'Firefox', 'Safari', 'Edge', 'Opera'];
    v_os_names VARCHAR(50)[] := ARRAY['Windows 11', 'macOS', 'Ubuntu', 'iOS', 'Android'];
    v_device_types VARCHAR(20)[] := ARRAY['Desktop', 'Mobile', 'Tablet'];
BEGIN
    -- 각 회사에 대해 사용자 활동 로그 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 사용자 활동 로그 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 각 사용자에 대해 세션 및 활동 로그 생성
        FOR user_rec IN 
            SELECT user_id, full_name, email
            FROM bms.users 
            WHERE company_id = company_rec.company_id
            LIMIT 5  -- 각 회사당 5명의 사용자
        LOOP
            RAISE NOTICE '  사용자 % 활동 로그 생성', user_rec.full_name;
            
            -- 1. 사용자 세션 생성 (최근 30일간)
            FOR i IN 1..10 LOOP  -- 사용자당 10개 세션
                v_session_id := 'sess_' || substr(md5(random()::text), 1, 32);
                
                INSERT INTO bms.user_sessions (
                    session_id, company_id, user_id,
                    session_token, created_at, last_activity_at, expires_at,
                    client_ip, user_agent, device_fingerprint,
                    is_active, login_method, mfa_verified
                ) VALUES (
                    v_session_id, company_rec.company_id, user_rec.user_id,
                    'token_' || substr(md5(random()::text), 1, 40),
                    NOW() - (random() * 30 || ' days')::INTERVAL,
                    NOW() - (random() * 5 || ' days')::INTERVAL,
                    NOW() + (random() * 7 || ' days')::INTERVAL,
                    ('192.168.' || floor(random() * 255) || '.' || floor(random() * 255))::INET,
                    v_browsers[ceil(random() * array_length(v_browsers, 1))] || '/' || 
                    (90 + random() * 20)::INTEGER || '.0 (' || 
                    v_os_names[ceil(random() * array_length(v_os_names, 1))] || ')',
                    'fp_' || substr(md5(random()::text), 1, 20),
                    CASE WHEN random() > 0.1 THEN true ELSE false END,
                    CASE WHEN random() > 0.8 THEN 'SSO' ELSE 'PASSWORD' END,
                    CASE WHEN random() > 0.7 THEN true ELSE false END
                );
                session_count := session_count + 1;
                
                -- 2. 각 세션에 대해 활동 로그 생성
                FOR j IN 1..(5 + random() * 15)::INTEGER LOOP  -- 세션당 5-20개 활동
                    INSERT INTO bms.user_activity_logs (
                        company_id, user_id, user_name, user_email,
                        activity_type, activity_category,
                        activity_description, activity_result,
                        session_id, request_method, request_url,
                        response_status, response_time,
                        client_ip, user_agent,
                        browser_name, browser_version, os_name, device_type,
                        country_code, region, city, timezone,
                        is_suspicious, risk_score,
                        business_context, feature_used,
                        page_load_time, database_query_time, api_call_count,
                        created_at
                    ) VALUES (
                        company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                        v_activity_types[ceil(random() * array_length(v_activity_types, 1))],
                        v_activity_categories[ceil(random() * array_length(v_activity_categories, 1))],
                        '사용자 활동 - ' || (ARRAY['건물 관리', '호실 조회', '입주자 관리', '계약 관리', '보고서 생성'])[ceil(random() * 5)],
                        CASE WHEN random() > 0.05 THEN 'SUCCESS' ELSE 'FAILURE' END,
                        v_session_id,
                        (ARRAY['GET', 'POST', 'PUT', 'DELETE'])[ceil(random() * 4)],
                        '/api/v1/' || (ARRAY['buildings', 'units', 'tenants', 'contracts', 'reports'])[ceil(random() * 5)] || 
                        '/' || floor(random() * 1000),
                        CASE WHEN random() > 0.1 THEN 200 ELSE (ARRAY[400, 401, 403, 404, 500])[ceil(random() * 5)] END,
                        (50 + random() * 2000)::INTEGER,
                        ('192.168.' || floor(random() * 255) || '.' || floor(random() * 255))::INET,
                        v_browsers[ceil(random() * array_length(v_browsers, 1))] || '/' || 
                        (90 + random() * 20)::INTEGER || '.0',
                        v_browsers[ceil(random() * array_length(v_browsers, 1))],
                        (90 + random() * 20)::TEXT || '.0',
                        v_os_names[ceil(random() * array_length(v_os_names, 1))],
                        v_device_types[ceil(random() * array_length(v_device_types, 1))],
                        'KR', '서울특별시', '강남구', 'Asia/Seoul',
                        CASE WHEN random() > 0.95 THEN true ELSE false END,
                        (random() * 30)::INTEGER,
                        (ARRAY['BUILDING_MGMT', 'TENANT_MGMT', 'CONTRACT_MGMT', 'REPORT_GEN', 'SYSTEM_ADMIN'])[ceil(random() * 5)],
                        (ARRAY['건물목록', '호실관리', '입주자등록', '계약조회', '보고서생성'])[ceil(random() * 5)],
                        (500 + random() * 3000)::INTEGER,
                        (10 + random() * 100)::INTEGER,
                        (1 + random() * 10)::INTEGER,
                        NOW() - (random() * 30 || ' days')::INTERVAL - (random() * 24 || ' hours')::INTERVAL
                    );
                    activity_count := activity_count + 1;
                END LOOP;
            END LOOP;
            
            -- 3. 보안 이벤트 생성 (일부 사용자에 대해)
            IF random() > 0.7 THEN  -- 30% 확률로 보안 이벤트 생성
                FOR i IN 1..(1 + random() * 3)::INTEGER LOOP
                    INSERT INTO bms.security_event_logs (
                        company_id, event_type, event_severity, event_description,
                        user_id, user_name, user_ip,
                        event_details, affected_resources,
                        is_resolved, resolution_notes,
                        notification_sent, event_timestamp
                    ) VALUES (
                        company_rec.company_id,
                        v_security_events[ceil(random() * array_length(v_security_events, 1))],
                        (ARRAY['LOW', 'MEDIUM', 'HIGH'])[ceil(random() * 3)],
                        '보안 이벤트 - ' || user_rec.full_name || '에 대한 ' || 
                        v_security_events[ceil(random() * array_length(v_security_events, 1))] || ' 탐지',
                        user_rec.user_id, user_rec.full_name,
                        ('192.168.' || floor(random() * 255) || '.' || floor(random() * 255))::INET,
                        ('{"attempt_count": ' || (1 + random() * 10)::INTEGER || 
                         ', "source_country": "KR", "user_agent": "' || 
                         v_browsers[ceil(random() * array_length(v_browsers, 1))] || '"}')::JSONB,
                        ARRAY['user_account', 'session_data'],
                        CASE WHEN random() > 0.3 THEN true ELSE false END,
                        CASE WHEN random() > 0.3 THEN '자동 해결됨' ELSE NULL END,
                        CASE WHEN random() > 0.5 THEN true ELSE false END,
                        NOW() - (random() * 30 || ' days')::INTERVAL
                    );
                    security_event_count := security_event_count + 1;
                END LOOP;
            END IF;
        END LOOP;
        
        RAISE NOTICE '회사 % 사용자 활동 로그 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 4. 추가 보안 이벤트 생성 (시스템 레벨)
    RAISE NOTICE '시스템 레벨 보안 이벤트 생성 시작';
    
    FOR i IN 1..20 LOOP
        INSERT INTO bms.security_event_logs (
            company_id, event_type, event_severity, event_description,
            user_ip, event_details, affected_resources,
            is_resolved, notification_sent, event_timestamp
        ) VALUES (
            (SELECT company_id FROM bms.companies LIMIT 1),
            v_security_events[ceil(random() * array_length(v_security_events, 1))],
            (ARRAY['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'])[ceil(random() * 4)],
            '시스템 보안 이벤트 - ' || v_security_events[ceil(random() * array_length(v_security_events, 1))],
            ('10.0.' || floor(random() * 255) || '.' || floor(random() * 255))::INET,
            ('{"event_source": "system", "detection_method": "automated", "confidence": ' || 
             (70 + random() * 30)::INTEGER || '}')::JSONB,
            ARRAY['system_config', 'user_data', 'api_endpoints'],
            CASE WHEN random() > 0.4 THEN true ELSE false END,
            CASE WHEN random() > 0.6 THEN true ELSE false END,
            NOW() - (random() * 7 || ' days')::INTERVAL
        );
        security_event_count := security_event_count + 1;
    END LOOP;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 사용자 활동 로그 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 사용자 세션 수: %', session_count;
    RAISE NOTICE '총 활동 로그 수: %', activity_count;
    RAISE NOTICE '총 보안 이벤트 수: %', security_event_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 사용자 세션 현황
SELECT 
    '사용자 세션 현황' as category,
    c.company_name,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN is_active THEN 1 END) as active_sessions,
    COUNT(CASE WHEN expires_at > NOW() THEN 1 END) as valid_sessions,
    COUNT(CASE WHEN login_method = 'SSO' THEN 1 END) as sso_sessions,
    COUNT(CASE WHEN mfa_verified THEN 1 END) as mfa_sessions
FROM bms.user_sessions us
JOIN bms.companies c ON us.company_id = c.company_id
GROUP BY c.company_name
ORDER BY total_sessions DESC;

-- 2. 활동 로그 통계
SELECT 
    '활동 로그 통계' as category,
    activity_type,
    activity_category,
    COUNT(*) as log_count,
    COUNT(DISTINCT user_id) as unique_users,
    AVG(response_time) as avg_response_time,
    COUNT(CASE WHEN activity_result = 'SUCCESS' THEN 1 END) as success_count,
    COUNT(CASE WHEN activity_result = 'FAILURE' THEN 1 END) as failure_count
FROM bms.user_activity_logs
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY activity_type, activity_category
ORDER BY log_count DESC
LIMIT 15;

-- 3. 보안 이벤트 현황
SELECT 
    '보안 이벤트 현황' as category,
    event_type,
    event_severity,
    COUNT(*) as event_count,
    COUNT(CASE WHEN is_resolved THEN 1 END) as resolved_count,
    COUNT(CASE WHEN NOT is_resolved THEN 1 END) as unresolved_count,
    COUNT(CASE WHEN notification_sent THEN 1 END) as notified_count,
    MIN(event_timestamp) as first_event,
    MAX(event_timestamp) as last_event
FROM bms.security_event_logs
GROUP BY event_type, event_severity
ORDER BY event_count DESC;

-- 4. 최근 활동 로그 샘플
SELECT 
    '최근 활동 로그' as category,
    user_name,
    activity_type,
    activity_category,
    activity_description,
    activity_result,
    response_time,
    created_at
FROM bms.user_activity_logs
ORDER BY created_at DESC
LIMIT 10;

-- 5. 의심스러운 활동 현황
SELECT 
    '의심스러운 활동' as category,
    user_name,
    activity_type,
    risk_score,
    client_ip,
    created_at,
    activity_description
FROM bms.user_activity_logs
WHERE is_suspicious = true OR risk_score > 50
ORDER BY risk_score DESC, created_at DESC
LIMIT 10;

-- 6. 활동 로그 함수 테스트
SELECT 
    '활동 로그 함수 테스트' as category,
    bms.log_user_activity(
        'PAGE_VIEW'::VARCHAR(50),
        'USER_INTERFACE'::VARCHAR(30),
        (SELECT user_id FROM bms.users LIMIT 1),
        '테스트 페이지 조회'::TEXT,
        'SUCCESS'::VARCHAR(20),
        '/test/page'::TEXT,
        200,
        'TEST_CONTEXT'::VARCHAR(100),
        'TEST_FEATURE'::VARCHAR(100)
    ) as test_activity_id;

-- 완료 메시지
SELECT '✅ 사용자 활동 로그 시스템 테스트 데이터 생성이 완료되었습니다!' as result;