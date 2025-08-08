-- =====================================================
-- 사용자 활동 로그 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    user_rec RECORD;
    building_rec RECORD;
    activity_count INTEGER := 0;
    session_count INTEGER := 0;
    security_event_count INTEGER := 0;
    i INTEGER;
    j INTEGER;
BEGIN
    -- 각 회사의 사용자들에 대해 활동 로그 생성
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
        
        -- 각 회사의 사용자들에 대해 활동 로그 생성
        FOR user_rec IN 
            SELECT user_id, full_name, email
            FROM bms.users 
            WHERE company_id = company_rec.company_id
            LIMIT 5  -- 각 회사당 5명의 사용자
        LOOP
            RAISE NOTICE '  사용자 % 활동 로그 생성', user_rec.full_name;
            
            -- 1. 로그인 세션 생성 (지난 30일간)
            FOR i IN 1..15 LOOP  -- 15개의 세션
                DECLARE
                    v_session_id VARCHAR(100);
                    v_login_time TIMESTAMP WITH TIME ZONE;
                    v_logout_time TIMESTAMP WITH TIME ZONE;
                BEGIN
                    v_login_time := NOW() - (random() * 30 || ' days')::INTERVAL;
                    v_logout_time := v_login_time + (random() * 8 || ' hours')::INTERVAL;
                    
                    -- 세션 생성
                    INSERT INTO bms.user_sessions (
                        session_id, company_id, user_id, session_token,
                        created_at, last_activity_at, expires_at,
                        client_ip, user_agent, is_active, login_method
                    ) VALUES (
                        'sess_' || substr(md5(random()::text), 1, 32),
                        company_rec.company_id, user_rec.user_id,
                        'token_' || substr(md5(random()::text), 1, 40),
                        v_login_time, v_logout_time, v_logout_time + INTERVAL '1 hour',
                        ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                        (ARRAY['Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 'Mozilla/5.0 (Macintosh; Intel Mac OS X)', 'Mozilla/5.0 (X11; Linux x86_64)'])[ceil(random() * 3)],
                        CASE WHEN v_logout_time < NOW() THEN false ELSE true END,
                        (ARRAY['PASSWORD', 'SSO', 'API_KEY'])[ceil(random() * 3)]
                    ) RETURNING session_id INTO v_session_id;
                    
                    session_count := session_count + 1;
                    
                    -- 로그인 활동 로그
                    INSERT INTO bms.user_activity_logs (
                        company_id, user_id, user_name, user_email,
                        activity_type, activity_category, activity_description, activity_result,
                        session_id, client_ip, user_agent,
                        business_context, feature_used,
                        created_at
                    ) VALUES (
                        company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                        'LOGIN', 'AUTHENTICATION', '사용자 로그인', 'SUCCESS',
                        v_session_id, ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                        (ARRAY['Chrome/91.0', 'Firefox/89.0', 'Safari/14.1'])[ceil(random() * 3)],
                        'USER_SESSION', 'LOGIN_FORM',
                        v_login_time
                    );
                    activity_count := activity_count + 1;
                    
                    -- 세션 중 다양한 활동들 생성
                    FOR j IN 1..(random() * 20 + 5)::integer LOOP
                        INSERT INTO bms.user_activity_logs (
                            company_id, user_id, user_name, user_email,
                            activity_type, activity_category, activity_description, activity_result,
                            session_id, client_ip, user_agent,
                            business_context, feature_used, response_time,
                            created_at
                        ) VALUES (
                            company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                            (ARRAY['PAGE_VIEW', 'API_CALL', 'SEARCH', 'DATA_EXPORT', 'REPORT_GENERATION'])[ceil(random() * 5)],
                            (ARRAY['DATA_ACCESS', 'BUSINESS_OPERATION', 'SYSTEM_ADMINISTRATION'])[ceil(random() * 3)],
                            (ARRAY['건물 목록 조회', '호실 정보 확인', '관리비 조회', '계약 관리', '보고서 생성', '설정 변경'])[ceil(random() * 6)],
                            CASE WHEN random() < 0.95 THEN 'SUCCESS' ELSE 'FAILURE' END,
                            v_session_id, ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                            (ARRAY['Chrome/91.0', 'Firefox/89.0', 'Safari/14.1'])[ceil(random() * 3)],
                            'DAILY_OPERATION',
                            (ARRAY['BUILDING_LIST', 'UNIT_DETAIL', 'FEE_MANAGEMENT', 'CONTRACT_MANAGEMENT', 'REPORT_DASHBOARD'])[ceil(random() * 5)],
                            (random() * 2000 + 50)::integer,  -- 50-2050ms 응답시간
                            v_login_time + (random() * (v_logout_time - v_login_time))
                        );
                        activity_count := activity_count + 1;
                    END LOOP;
                    
                    -- 로그아웃 활동 로그 (세션이 종료된 경우)
                    IF v_logout_time < NOW() THEN
                        INSERT INTO bms.user_activity_logs (
                            company_id, user_id, user_name, user_email,
                            activity_type, activity_category, activity_description, activity_result,
                            session_id, client_ip, user_agent,
                            business_context, feature_used,
                            created_at
                        ) VALUES (
                            company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                            'LOGOUT', 'AUTHENTICATION', '사용자 로그아웃', 'SUCCESS',
                            v_session_id, ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                            (ARRAY['Chrome/91.0', 'Firefox/89.0', 'Safari/14.1'])[ceil(random() * 3)],
                            'USER_SESSION', 'LOGOUT_BUTTON',
                            v_logout_time
                        );
                        activity_count := activity_count + 1;
                    END IF;
                END;
            END LOOP;
            
            -- 2. 의심스러운 활동 시뮬레이션 (일부 사용자에 대해)
            IF random() < 0.3 THEN  -- 30% 확률로 의심스러운 활동 생성
                INSERT INTO bms.user_activity_logs (
                    company_id, user_id, user_name, user_email,
                    activity_type, activity_category, activity_description, activity_result,
                    client_ip, user_agent, is_suspicious, risk_score,
                    business_context, feature_used,
                    created_at
                ) VALUES (
                    company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                    'DATA_EXPORT', 'DATA_ACCESS', '대량 데이터 내보내기', 'SUCCESS',
                    ('10.0.0.' || (random() * 254 + 1)::integer)::inet,  -- 다른 IP 대역
                    'curl/7.68.0',  -- 의심스러운 User-Agent
                    true, (random() * 50 + 50)::integer,  -- 50-100 위험 점수
                    'SUSPICIOUS_ACTIVITY', 'BULK_EXPORT',
                    NOW() - (random() * 7 || ' days')::INTERVAL
                );
                activity_count := activity_count + 1;
            END IF;
            
            -- 3. 실패한 로그인 시도 시뮬레이션
            IF random() < 0.4 THEN  -- 40% 확률로 실패한 로그인 시도
                FOR i IN 1..(random() * 3 + 1)::integer LOOP
                    INSERT INTO bms.user_activity_logs (
                        company_id, user_id, user_name, user_email,
                        activity_type, activity_category, activity_description, activity_result,
                        client_ip, user_agent, is_suspicious, risk_score,
                        business_context, feature_used,
                        created_at
                    ) VALUES (
                        company_rec.company_id, user_rec.user_id, user_rec.full_name, user_rec.email,
                        'FAILED_LOGIN', 'AUTHENTICATION', '로그인 실패', 'FAILURE',
                        ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                        (ARRAY['Chrome/91.0', 'Firefox/89.0', 'Safari/14.1'])[ceil(random() * 3)],
                        CASE WHEN i > 2 THEN true ELSE false END,  -- 3번째부터 의심스러운 활동
                        CASE WHEN i > 2 THEN (random() * 30 + 20)::integer ELSE 0 END,
                        'AUTHENTICATION_FAILURE', 'LOGIN_FORM',
                        NOW() - (random() * 14 || ' days')::INTERVAL
                    );
                    activity_count := activity_count + 1;
                END LOOP;
            END IF;
        END LOOP;
        
        -- 4. 보안 이벤트 로그 생성
        FOR i IN 1..(random() * 5 + 2)::integer LOOP
            INSERT INTO bms.security_event_logs (
                company_id, event_type, event_severity, event_description,
                user_id, user_name, user_ip,
                event_details, is_resolved, resolved_by,
                event_timestamp
            ) VALUES (
                company_rec.company_id,
                (ARRAY['FAILED_LOGIN_ATTEMPT', 'SUSPICIOUS_IP_ACCESS', 'UNAUTHORIZED_ACCESS', 'POLICY_VIOLATION', 'ANOMALY_DETECTION'])[ceil(random() * 5)],
                (ARRAY['LOW', 'MEDIUM', 'HIGH'])[ceil(random() * 3)],
                (ARRAY['다중 로그인 실패 감지', '비정상적인 IP에서 접근', '권한 없는 데이터 접근 시도', '보안 정책 위반', '비정상적인 사용자 행동 패턴'])[ceil(random() * 5)],
                (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id ORDER BY random() LIMIT 1),
                (SELECT full_name FROM bms.users WHERE company_id = company_rec.company_id ORDER BY random() LIMIT 1),
                ('192.168.1.' || (random() * 254 + 1)::integer)::inet,
                '{"source": "automated_detection", "confidence": ' || (random() * 100)::integer || '}',
                random() < 0.7,  -- 70% 확률로 해결됨
                CASE WHEN random() < 0.7 THEN (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id ORDER BY random() LIMIT 1) ELSE NULL END,
                NOW() - (random() * 30 || ' days')::INTERVAL
            );
            security_event_count := security_event_count + 1;
        END LOOP;
        
        RAISE NOTICE '회사 % 사용자 활동 로그 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 사용자 활동 로그 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 활동 로그 수: %', activity_count;
    RAISE NOTICE '총 세션 수: %', session_count;
    RAISE NOTICE '총 보안 이벤트 수: %', security_event_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 사용자 활동 통계
SELECT 
    '사용자 활동 통계' as category,
    c.company_name,
    ual.activity_type,
    COUNT(*) as activity_count,
    COUNT(DISTINCT ual.user_id) as unique_users,
    AVG(ual.response_time) as avg_response_time,
    SUM(CASE WHEN ual.activity_result = 'FAILURE' THEN 1 ELSE 0 END) as failure_count,
    SUM(CASE WHEN ual.is_suspicious THEN 1 ELSE 0 END) as suspicious_count
FROM bms.user_activity_logs ual
JOIN bms.companies c ON ual.company_id = c.company_id
GROUP BY c.company_name, ual.activity_type
ORDER BY activity_count DESC
LIMIT 15;

-- 2. 세션 통계
SELECT 
    '세션 통계' as category,
    c.company_name,
    us.login_method,
    COUNT(*) as session_count,
    COUNT(DISTINCT us.user_id) as unique_users,
    SUM(CASE WHEN us.is_active THEN 1 ELSE 0 END) as active_sessions,
    AVG(EXTRACT(EPOCH FROM (us.last_activity_at - us.created_at))/3600) as avg_session_hours
FROM bms.user_sessions us
JOIN bms.companies c ON us.company_id = c.company_id
GROUP BY c.company_name, us.login_method
ORDER BY session_count DESC;

-- 3. 보안 이벤트 통계
SELECT 
    '보안 이벤트 통계' as category,
    c.company_name,
    sel.event_type,
    sel.event_severity,
    COUNT(*) as event_count,
    SUM(CASE WHEN sel.is_resolved THEN 1 ELSE 0 END) as resolved_count,
    COUNT(DISTINCT sel.user_id) as affected_users
FROM bms.security_event_logs sel
JOIN bms.companies c ON sel.company_id = c.company_id
GROUP BY c.company_name, sel.event_type, sel.event_severity
ORDER BY event_count DESC;

-- 4. 최근 의심스러운 활동
SELECT 
    '의심스러운 활동' as category,
    c.company_name,
    ual.user_name,
    ual.activity_type,
    ual.activity_description,
    ual.risk_score,
    ual.client_ip,
    ual.created_at
FROM bms.user_activity_logs ual
JOIN bms.companies c ON ual.company_id = c.company_id
WHERE ual.is_suspicious = true
ORDER BY ual.created_at DESC
LIMIT 10;

-- 5. 활동 로그 뷰 테스트
SELECT 
    '활동 요약 뷰' as category,
    company_name,
    user_name,
    activity_type,
    activity_count,
    failure_count,
    suspicious_count
FROM bms.v_user_activity_summary
ORDER BY activity_count DESC
LIMIT 10;

-- 6. 보안 대시보드 뷰 테스트
SELECT 
    '보안 대시보드' as category,
    company_name,
    event_type,
    event_severity,
    event_count,
    resolved_count,
    pending_count
FROM bms.v_security_dashboard
ORDER BY event_count DESC
LIMIT 10;

-- 완료 메시지
SELECT '✅ 사용자 활동 로그 테스트 데이터 생성이 완료되었습니다!' as result;