-- =====================================================
-- QIRO 성능 테스트 쿼리 모음
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 환경에서의 성능 테스트를 위한 쿼리 모음
-- =====================================================

-- =====================================================
-- 1. 멀티테넌시 핵심 성능 테스트 쿼리
-- =====================================================

-- 1.1 조직별 사용자 조회 성능 테스트 (가장 빈번한 쿼리)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    u.user_id,
    u.email,
    u.full_name,
    u.user_type,
    u.status,
    u.last_login_at,
    r.role_name,
    r.role_code
FROM users u
JOIN user_role_links url ON u.user_id = url.user_id
JOIN roles r ON url.role_id = r.role_id
WHERE u.company_id = 'test-company-uuid'::UUID
AND u.status = 'ACTIVE'
ORDER BY u.last_login_at DESC NULLS LAST
LIMIT 50;

-- 1.2 조직별 건물 그룹 및 배정 현황 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    bg.group_id,
    bg.group_name,
    bg.group_type,
    bg.is_active,
    COUNT(DISTINCT bga.building_id) as building_count,
    COUNT(DISTINCT uga.user_id) as user_count,
    bg.created_at
FROM building_groups bg
LEFT JOIN building_group_assignments bga ON bg.group_id = bga.group_id AND bga.is_active = true
LEFT JOIN user_group_assignments uga ON bg.group_id = uga.group_id AND uga.is_active = true
WHERE bg.company_id = 'test-company-uuid'::UUID
AND bg.is_active = true
GROUP BY bg.group_id, bg.group_name, bg.group_type, bg.is_active, bg.created_at
ORDER BY bg.created_at DESC;

-- 1.3 사용자별 접근 가능한 건물 그룹 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT DISTINCT
    bg.group_id,
    bg.group_name,
    bg.group_type,
    uga.access_level,
    COUNT(bga.building_id) as building_count
FROM building_groups bg
JOIN user_group_assignments uga ON bg.group_id = uga.group_id
LEFT JOIN building_group_assignments bga ON bg.group_id = bga.group_id AND bga.is_active = true
WHERE uga.user_id = 'test-user-uuid'::UUID
AND uga.is_active = true
AND bg.is_active = true
GROUP BY bg.group_id, bg.group_name, bg.group_type, uga.access_level
ORDER BY bg.group_name;

-- =====================================================
-- 2. 인증 시스템 성능 테스트 쿼리
-- =====================================================

-- 2.1 사업자 인증 기록 조회 (파티션 테이블)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    bvr.verification_id,
    bvr.verification_type,
    bvr.verification_status,
    bvr.verification_date,
    bvr.created_at
FROM business_verification_records bvr
WHERE bvr.company_id = 'test-company-uuid'::UUID
AND bvr.created_at >= CURRENT_DATE - INTERVAL '30 days'
AND bvr.verification_status = 'SUCCESS'
ORDER BY bvr.created_at DESC;

-- 2.2 전화번호 인증 토큰 조회 (파티션 테이블)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    pvt.token_id,
    pvt.phone_number,
    pvt.expires_at,
    pvt.is_used,
    pvt.attempts
FROM phone_verification_tokens pvt
WHERE pvt.user_id = 'test-user-uuid'::UUID
AND pvt.is_used = false
AND pvt.expires_at > now()
ORDER BY pvt.created_at DESC
LIMIT 1;

-- 2.3 만료된 토큰 정리 쿼리
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
DELETE FROM phone_verification_tokens
WHERE expires_at <= now() - INTERVAL '1 day'
AND is_used = false;

-- =====================================================
-- 3. 대용량 데이터 처리 성능 테스트
-- =====================================================

-- 3.1 월별 통계 집계 쿼리
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    DATE_TRUNC('month', c.created_at) as month,
    c.verification_status,
    COUNT(*) as company_count,
    COUNT(DISTINCT c.business_type) as business_type_count
FROM companies c
WHERE c.created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', c.created_at), c.verification_status
ORDER BY month DESC, c.verification_status;

-- 3.2 사용자 활동 통계 쿼리
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    c.company_id,
    c.company_name,
    COUNT(u.user_id) as total_users,
    COUNT(CASE WHEN u.status = 'ACTIVE' THEN 1 END) as active_users,
    COUNT(CASE WHEN u.last_login_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_active_users,
    MAX(u.last_login_at) as last_activity
FROM companies c
LEFT JOIN users u ON c.company_id = u.company_id
WHERE c.verification_status = 'VERIFIED'
AND c.subscription_status = 'ACTIVE'
GROUP BY c.company_id, c.company_name
HAVING COUNT(u.user_id) > 0
ORDER BY recent_active_users DESC, total_users DESC
LIMIT 100;

-- =====================================================
-- 4. 복잡한 조인 쿼리 성능 테스트
-- =====================================================

-- 4.1 전체 조직 구조 조회 (사용자 + 역할 + 그룹)
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    c.company_name,
    u.full_name,
    u.email,
    u.user_type,
    u.status,
    r.role_name,
    bg.group_name,
    bg.group_type,
    uga.access_level,
    COUNT(bga.building_id) as managed_buildings
FROM companies c
JOIN users u ON c.company_id = u.company_id
JOIN user_role_links url ON u.user_id = url.user_id
JOIN roles r ON url.role_id = r.role_id
LEFT JOIN user_group_assignments uga ON u.user_id = uga.user_id AND uga.is_active = true
LEFT JOIN building_groups bg ON uga.group_id = bg.group_id AND bg.is_active = true
LEFT JOIN building_group_assignments bga ON bg.group_id = bga.group_id AND bga.is_active = true
WHERE c.company_id = 'test-company-uuid'::UUID
AND u.status = 'ACTIVE'
GROUP BY c.company_name, u.full_name, u.email, u.user_type, u.status, 
         r.role_name, bg.group_name, bg.group_type, uga.access_level
ORDER BY u.full_name, bg.group_name;

-- 4.2 건물 그룹별 상세 정보 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT 
    bg.group_id,
    bg.group_name,
    bg.group_type,
    bg.description,
    COUNT(DISTINCT bga.building_id) as building_count,
    COUNT(DISTINCT uga.user_id) as assigned_user_count,
    STRING_AGG(DISTINCT u.full_name, ', ' ORDER BY u.full_name) as assigned_users,
    bg.created_at,
    bg.updated_at
FROM building_groups bg
LEFT JOIN building_group_assignments bga ON bg.group_id = bga.group_id AND bga.is_active = true
LEFT JOIN user_group_assignments uga ON bg.group_id = uga.group_id AND uga.is_active = true
LEFT JOIN users u ON uga.user_id = u.user_id AND u.status = 'ACTIVE'
WHERE bg.company_id = 'test-company-uuid'::UUID
AND bg.is_active = true
GROUP BY bg.group_id, bg.group_name, bg.group_type, bg.description, bg.created_at, bg.updated_at
ORDER BY bg.created_at DESC;

-- =====================================================
-- 5. RLS 성능 테스트 쿼리
-- =====================================================

-- 5.1 RLS 정책 적용 상태에서의 조회 성능
-- 애플리케이션 컨텍스트 설정
SELECT set_config('app.current_company_id', 'test-company-uuid', false);

-- RLS가 적용된 상태에서의 사용자 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM users WHERE status = 'ACTIVE' ORDER BY created_at DESC LIMIT 50;

-- RLS가 적용된 상태에서의 그룹 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
SELECT * FROM building_groups WHERE is_active = true ORDER BY created_at DESC;

-- 컨텍스트 초기화
SELECT set_config('app.current_company_id', '', false);

-- =====================================================
-- 6. 동시성 테스트 쿼리
-- =====================================================

-- 6.1 동시 사용자 생성 시뮬레이션
DO $
DECLARE
    i INTEGER;
    test_company_id UUID := gen_random_uuid();
    test_user_id UUID;
BEGIN
    -- 테스트 회사 생성
    INSERT INTO companies (company_id, business_registration_number, company_name, 
                          representative_name, business_address, contact_phone, 
                          contact_email, business_type, establishment_date)
    VALUES (test_company_id, '1234567890', 'Test Company', 'Test Rep', 
            'Test Address', '010-1234-5678', 'test@test.com', 'IT', CURRENT_DATE);
    
    -- 동시 사용자 생성 시뮬레이션
    FOR i IN 1..100 LOOP
        test_user_id := gen_random_uuid();
        
        INSERT INTO users (user_id, company_id, email, password_hash, full_name, user_type)
        VALUES (test_user_id, test_company_id, 'user' || i || '@test.com', 
                'hashed_password', 'Test User ' || i, 'EMPLOYEE');
        
        -- 역할 할당
        INSERT INTO user_role_links (user_id, role_id)
        SELECT test_user_id, role_id 
        FROM roles 
        WHERE company_id = test_company_id 
        AND role_code = 'EMPLOYEE' 
        LIMIT 1;
    END LOOP;
    
    RAISE NOTICE '동시성 테스트 데이터 생성 완료: % 사용자', i;
END
$;

-- 6.2 동시 그룹 배정 시뮬레이션
DO $
DECLARE
    i INTEGER;
    test_group_id UUID;
    test_building_id BIGINT;
BEGIN
    -- 테스트 그룹 생성
    FOR i IN 1..10 LOOP
        test_group_id := gen_random_uuid();
        
        INSERT INTO building_groups (group_id, company_id, group_name, group_type)
        SELECT test_group_id, company_id, 'Test Group ' || i, 'CUSTOM'
        FROM companies 
        WHERE company_name = 'Test Company'
        LIMIT 1;
        
        -- 건물 배정 (기존 건물이 있다고 가정)
        SELECT id INTO test_building_id FROM buildings LIMIT 1;
        
        IF test_building_id IS NOT NULL THEN
            INSERT INTO building_group_assignments (group_id, building_id)
            VALUES (test_group_id, test_building_id);
        END IF;
    END LOOP;
    
    RAISE NOTICE '동시성 테스트 그룹 생성 완료: % 그룹', i;
END
$;

-- =====================================================
-- 7. 성능 벤치마크 함수
-- =====================================================

-- 7.1 멀티테넌시 성능 벤치마크 함수
CREATE OR REPLACE FUNCTION run_multitenancy_benchmark()
RETURNS TABLE (
    test_name TEXT,
    execution_time_ms BIGINT,
    rows_processed INTEGER,
    performance_rating TEXT
) AS $
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    exec_time_ms BIGINT;
    row_count INTEGER;
BEGIN
    -- 테스트 1: 조직별 사용자 조회
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM users u
    JOIN user_role_links url ON u.user_id = url.user_id
    WHERE u.company_id IN (SELECT company_id FROM companies LIMIT 10)
    AND u.status = 'ACTIVE';
    end_time := clock_timestamp();
    exec_time_ms := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        'Multi-tenant User Query'::TEXT,
        exec_time_ms,
        row_count,
        CASE 
            WHEN exec_time_ms < 100 THEN 'EXCELLENT'
            WHEN exec_time_ms < 500 THEN 'GOOD'
            WHEN exec_time_ms < 1000 THEN 'FAIR'
            ELSE 'POOR'
        END::TEXT;
    
    -- 테스트 2: 그룹 배정 현황 조회
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM building_groups bg
    JOIN building_group_assignments bga ON bg.group_id = bga.group_id
    WHERE bg.is_active = true AND bga.is_active = true;
    end_time := clock_timestamp();
    exec_time_ms := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        'Group Assignment Query'::TEXT,
        exec_time_ms,
        row_count,
        CASE 
            WHEN exec_time_ms < 200 THEN 'EXCELLENT'
            WHEN exec_time_ms < 1000 THEN 'GOOD'
            WHEN exec_time_ms < 2000 THEN 'FAIR'
            ELSE 'POOR'
        END::TEXT;
    
    -- 테스트 3: 인증 기록 조회 (파티션 테이블)
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM business_verification_records
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';
    end_time := clock_timestamp();
    exec_time_ms := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        'Partitioned Table Query'::TEXT,
        exec_time_ms,
        row_count,
        CASE 
            WHEN exec_time_ms < 50 THEN 'EXCELLENT'
            WHEN exec_time_ms < 200 THEN 'GOOD'
            WHEN exec_time_ms < 500 THEN 'FAIR'
            ELSE 'POOR'
        END::TEXT;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 8. 성능 모니터링 대시보드 쿼리
-- =====================================================

-- 8.1 실시간 성능 대시보드
CREATE OR REPLACE VIEW v_performance_dashboard AS
SELECT 
    'Active Connections' as metric,
    COUNT(*)::TEXT as value,
    'connections' as unit
FROM pg_stat_activity 
WHERE state = 'active'

UNION ALL

SELECT 
    'Database Size' as metric,
    pg_size_pretty(pg_database_size(current_database())) as value,
    'bytes' as unit

UNION ALL

SELECT 
    'Cache Hit Ratio' as metric,
    ROUND(
        100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2
    )::TEXT || '%' as value,
    'percentage' as unit
FROM pg_stat_database
WHERE datname = current_database()

UNION ALL

SELECT 
    'Active Companies' as metric,
    COUNT(*)::TEXT as value,
    'companies' as unit
FROM companies 
WHERE verification_status = 'VERIFIED' 
AND subscription_status = 'ACTIVE'

UNION ALL

SELECT 
    'Active Users' as metric,
    COUNT(*)::TEXT as value,
    'users' as unit
FROM users 
WHERE status = 'ACTIVE'

UNION ALL

SELECT 
    'Active Groups' as metric,
    COUNT(*)::TEXT as value,
    'groups' as unit
FROM building_groups 
WHERE is_active = true;

-- =====================================================
-- 9. 테스트 데이터 정리 함수
-- =====================================================

-- 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_test_data()
RETURNS TEXT AS $
DECLARE
    result_text TEXT := '';
    deleted_count INTEGER;
BEGIN
    -- 테스트 회사 및 관련 데이터 삭제
    DELETE FROM companies WHERE company_name LIKE 'Test Company%';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    result_text := result_text || 'Deleted ' || deleted_count || ' test companies' || E'\n';
    
    -- 테스트 그룹 삭제
    DELETE FROM building_groups WHERE group_name LIKE 'Test Group%';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    result_text := result_text || 'Deleted ' || deleted_count || ' test groups' || E'\n';
    
    -- 만료된 토큰 정리
    DELETE FROM phone_verification_tokens 
    WHERE expires_at <= now() - INTERVAL '1 day';
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    result_text := result_text || 'Deleted ' || deleted_count || ' expired tokens' || E'\n';
    
    RETURN result_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 10. 코멘트 및 사용법 안내
-- =====================================================

COMMENT ON FUNCTION run_multitenancy_benchmark() IS '멀티테넌시 환경 성능 벤치마크 실행';
COMMENT ON FUNCTION cleanup_test_data() IS '성능 테스트용 데이터 정리';
COMMENT ON VIEW v_performance_dashboard IS '실시간 성능 모니터링 대시보드';

-- 사용법 안내
DO $
BEGIN
    RAISE NOTICE '성능 테스트 쿼리 모음이 준비되었습니다.';
    RAISE NOTICE '벤치마크 실행: SELECT * FROM run_multitenancy_benchmark();';
    RAISE NOTICE '성능 대시보드: SELECT * FROM v_performance_dashboard;';
    RAISE NOTICE '테스트 데이터 정리: SELECT cleanup_test_data();';
END
$;