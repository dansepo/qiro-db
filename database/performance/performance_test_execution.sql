-- =====================================================
-- QIRO 성능 테스트 실행 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 환경 성능 테스트 자동 실행 및 결과 분석
-- =====================================================

-- =====================================================
-- 1. 성능 테스트 결과 저장 테이블
-- =====================================================

-- 성능 테스트 결과 저장 테이블
CREATE TABLE IF NOT EXISTS performance_test_results (
    test_id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_category VARCHAR(100) NOT NULL,
    execution_time_ms BIGINT NOT NULL,
    rows_processed INTEGER DEFAULT 0,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    cache_hit_ratio DECIMAL(5,2),
    test_parameters JSONB DEFAULT '{}',
    test_environment JSONB DEFAULT '{}',
    executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    executed_by VARCHAR(100) DEFAULT current_user
);

-- 성능 테스트 세션 정보 테이블
CREATE TABLE IF NOT EXISTS performance_test_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_name VARCHAR(255) NOT NULL,
    test_description TEXT,
    database_version TEXT,
    server_specs JSONB,
    test_data_size JSONB,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    total_tests INTEGER DEFAULT 0,
    passed_tests INTEGER DEFAULT 0,
    failed_tests INTEGER DEFAULT 0,
    session_status VARCHAR(20) DEFAULT 'RUNNING' CHECK (session_status IN ('RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED'))
);

-- =====================================================
-- 2. 성능 테스트 실행 함수
-- =====================================================

-- 성능 테스트 세션 시작 함수
CREATE OR REPLACE FUNCTION start_performance_test_session(
    p_session_name VARCHAR(255),
    p_description TEXT DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    session_id UUID;
    db_version TEXT;
    server_info JSONB;
    data_size_info JSONB;
BEGIN
    -- 데이터베이스 버전 정보 수집
    SELECT version() INTO db_version;
    
    -- 서버 정보 수집
    server_info := jsonb_build_object(
        'shared_buffers', current_setting('shared_buffers'),
        'work_mem', current_setting('work_mem'),
        'maintenance_work_mem', current_setting('maintenance_work_mem'),
        'effective_cache_size', current_setting('effective_cache_size'),
        'max_connections', current_setting('max_connections')
    );
    
    -- 테스트 데이터 크기 정보 수집
    data_size_info := jsonb_build_object(
        'companies_count', (SELECT COUNT(*) FROM companies),
        'users_count', (SELECT COUNT(*) FROM users),
        'building_groups_count', (SELECT COUNT(*) FROM building_groups),
        'verification_records_count', (SELECT COUNT(*) FROM business_verification_records),
        'database_size', pg_size_pretty(pg_database_size(current_database()))
    );
    
    -- 세션 생성
    INSERT INTO performance_test_sessions (
        session_name,
        test_description,
        database_version,
        server_specs,
        test_data_size
    ) VALUES (
        p_session_name,
        p_description,
        db_version,
        server_info,
        data_size_info
    ) RETURNING session_id;
    
    RAISE NOTICE '성능 테스트 세션 시작: % (ID: %)', p_session_name, session_id;
    RETURN session_id;
END;
$ LANGUAGE plpgsql;

-- 개별 성능 테스트 실행 함수
CREATE OR REPLACE FUNCTION execute_performance_test(
    p_session_id UUID,
    p_test_name VARCHAR(255),
    p_test_category VARCHAR(100),
    p_test_query TEXT,
    p_test_parameters JSONB DEFAULT '{}'
)
RETURNS BIGINT AS $
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    execution_time_ms BIGINT;
    rows_processed INTEGER := 0;
    cache_hit_ratio DECIMAL(5,2);
    test_result_id BIGINT;
    query_result RECORD;
BEGIN
    -- 캐시 히트 비율 측정 시작
    SELECT 
        ROUND(100.0 * sum(blks_hit) / NULLIF(sum(blks_hit) + sum(blks_read), 0), 2)
    INTO cache_hit_ratio
    FROM pg_stat_database
    WHERE datname = current_database();
    
    -- 테스트 실행
    start_time := clock_timestamp();
    
    BEGIN
        EXECUTE p_test_query;
        GET DIAGNOSTICS rows_processed = ROW_COUNT;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '테스트 실행 오류 [%]: %', p_test_name, SQLERRM;
        rows_processed := -1;
    END;
    
    end_time := clock_timestamp();
    execution_time_ms := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    -- 결과 저장
    INSERT INTO performance_test_results (
        test_name,
        test_category,
        execution_time_ms,
        rows_processed,
        cache_hit_ratio,
        test_parameters
    ) VALUES (
        p_test_name,
        p_test_category,
        execution_time_ms,
        rows_processed,
        cache_hit_ratio,
        p_test_parameters
    ) RETURNING test_id INTO test_result_id;
    
    RAISE NOTICE '테스트 완료 [%]: %ms, % rows', p_test_name, execution_time_ms, rows_processed;
    RETURN test_result_id;
END;
$ LANGUAGE plpgsql;

-- 성능 테스트 세션 완료 함수
CREATE OR REPLACE FUNCTION complete_performance_test_session(
    p_session_id UUID
)
RETURNS VOID AS $
DECLARE
    test_stats RECORD;
BEGIN
    -- 테스트 통계 계산
    SELECT 
        COUNT(*) as total_tests,
        COUNT(CASE WHEN rows_processed >= 0 THEN 1 END) as passed_tests,
        COUNT(CASE WHEN rows_processed < 0 THEN 1 END) as failed_tests
    INTO test_stats
    FROM performance_test_results ptr
    WHERE ptr.executed_at >= (
        SELECT started_at FROM performance_test_sessions WHERE session_id = p_session_id
    );
    
    -- 세션 완료 처리
    UPDATE performance_test_sessions 
    SET 
        completed_at = now(),
        total_tests = test_stats.total_tests,
        passed_tests = test_stats.passed_tests,
        failed_tests = test_stats.failed_tests,
        session_status = CASE 
            WHEN test_stats.failed_tests = 0 THEN 'COMPLETED'
            ELSE 'FAILED'
        END
    WHERE session_id = p_session_id;
    
    RAISE NOTICE '성능 테스트 세션 완료: 총 % 테스트, % 성공, % 실패', 
                 test_stats.total_tests, test_stats.passed_tests, test_stats.failed_tests;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 종합 성능 테스트 실행 함수
-- =====================================================

-- 전체 성능 테스트 스위트 실행
CREATE OR REPLACE FUNCTION run_comprehensive_performance_test()
RETURNS UUID AS $
DECLARE
    session_id UUID;
    test_company_id UUID;
    test_user_id UUID;
    test_group_id UUID;
BEGIN
    -- 테스트 세션 시작
    session_id := start_performance_test_session(
        'Comprehensive Performance Test',
        'QIRO 멀티테넌시 환경 종합 성능 테스트'
    );
    
    -- 테스트 데이터 준비
    SELECT company_id INTO test_company_id FROM companies LIMIT 1;
    SELECT user_id INTO test_user_id FROM users WHERE company_id = test_company_id LIMIT 1;
    SELECT group_id INTO test_group_id FROM building_groups WHERE company_id = test_company_id LIMIT 1;
    
    -- 테스트 1: 기본 조회 성능
    PERFORM execute_performance_test(
        session_id,
        'Company List Query',
        'Basic Queries',
        'SELECT * FROM companies WHERE verification_status = ''VERIFIED'' ORDER BY created_at DESC LIMIT 100'
    );
    
    PERFORM execute_performance_test(
        session_id,
        'Active Users Query',
        'Basic Queries',
        format('SELECT * FROM users WHERE company_id = ''%s'' AND status = ''ACTIVE'' ORDER BY last_login_at DESC LIMIT 50', test_company_id)
    );
    
    PERFORM execute_performance_test(
        session_id,
        'Building Groups Query',
        'Basic Queries',
        format('SELECT * FROM building_groups WHERE company_id = ''%s'' AND is_active = true ORDER BY created_at DESC', test_company_id)
    );
    
    -- 테스트 2: 복합 조인 쿼리 성능
    PERFORM execute_performance_test(
        session_id,
        'User Role Assignment Query',
        'Join Queries',
        format('SELECT u.*, r.role_name FROM users u JOIN user_role_links url ON u.user_id = url.user_id JOIN roles r ON url.role_id = r.role_id WHERE u.company_id = ''%s''', test_company_id)
    );
    
    PERFORM execute_performance_test(
        session_id,
        'Group Assignment Details Query',
        'Join Queries',
        format('SELECT bg.*, COUNT(bga.building_id) as building_count, COUNT(uga.user_id) as user_count FROM building_groups bg LEFT JOIN building_group_assignments bga ON bg.group_id = bga.group_id AND bga.is_active = true LEFT JOIN user_group_assignments uga ON bg.group_id = uga.group_id AND uga.is_active = true WHERE bg.company_id = ''%s'' GROUP BY bg.group_id', test_company_id)
    );
    
    -- 테스트 3: 집계 쿼리 성능
    PERFORM execute_performance_test(
        session_id,
        'Monthly Statistics Query',
        'Aggregation Queries',
        'SELECT DATE_TRUNC(''month'', created_at) as month, verification_status, COUNT(*) FROM companies WHERE created_at >= CURRENT_DATE - INTERVAL ''12 months'' GROUP BY DATE_TRUNC(''month'', created_at), verification_status ORDER BY month DESC'
    );
    
    PERFORM execute_performance_test(
        session_id,
        'User Activity Statistics Query',
        'Aggregation Queries',
        'SELECT c.company_name, COUNT(u.user_id) as total_users, COUNT(CASE WHEN u.status = ''ACTIVE'' THEN 1 END) as active_users FROM companies c LEFT JOIN users u ON c.company_id = u.company_id WHERE c.verification_status = ''VERIFIED'' GROUP BY c.company_id, c.company_name HAVING COUNT(u.user_id) > 0 ORDER BY active_users DESC LIMIT 50'
    );
    
    -- 테스트 4: 파티션 테이블 쿼리 성능
    PERFORM execute_performance_test(
        session_id,
        'Recent Verification Records Query',
        'Partition Queries',
        format('SELECT * FROM business_verification_records WHERE company_id = ''%s'' AND created_at >= CURRENT_DATE - INTERVAL ''30 days'' ORDER BY created_at DESC', test_company_id)
    );
    
    PERFORM execute_performance_test(
        session_id,
        'Active Phone Tokens Query',
        'Partition Queries',
        format('SELECT * FROM phone_verification_tokens WHERE user_id = ''%s'' AND is_used = false AND expires_at > now() ORDER BY created_at DESC', test_user_id)
    );
    
    -- 테스트 5: 인덱스 효율성 테스트
    PERFORM execute_performance_test(
        session_id,
        'Company Search by Name',
        'Index Tests',
        'SELECT * FROM companies WHERE company_name ILIKE ''%Test%'' ORDER BY company_name'
    );
    
    PERFORM execute_performance_test(
        session_id,
        'User Search by Email',
        'Index Tests',
        'SELECT * FROM users WHERE email ILIKE ''%test%'' ORDER BY email'
    );
    
    -- 테스트 6: RLS 성능 테스트
    PERFORM set_config('app.current_company_id', test_company_id::TEXT, false);
    
    PERFORM execute_performance_test(
        session_id,
        'RLS Users Query',
        'RLS Tests',
        'SELECT * FROM users WHERE status = ''ACTIVE'' ORDER BY created_at DESC LIMIT 50'
    );
    
    PERFORM execute_performance_test(
        session_id,
        'RLS Building Groups Query',
        'RLS Tests',
        'SELECT * FROM building_groups WHERE is_active = true ORDER BY created_at DESC'
    );
    
    PERFORM set_config('app.current_company_id', '', false);
    
    -- 세션 완료
    PERFORM complete_performance_test_session(session_id);
    
    RETURN session_id;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 성능 테스트 결과 분석 함수
-- =====================================================

-- 성능 테스트 결과 요약 함수
CREATE OR REPLACE FUNCTION analyze_performance_test_results(
    p_session_id UUID DEFAULT NULL
)
RETURNS TABLE (
    category VARCHAR(100),
    test_count BIGINT,
    avg_execution_time_ms DECIMAL(10,2),
    min_execution_time_ms BIGINT,
    max_execution_time_ms BIGINT,
    avg_rows_processed DECIMAL(10,2),
    avg_cache_hit_ratio DECIMAL(5,2),
    performance_grade CHAR(1)
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        ptr.test_category,
        COUNT(*) as test_count,
        ROUND(AVG(ptr.execution_time_ms), 2) as avg_execution_time_ms,
        MIN(ptr.execution_time_ms) as min_execution_time_ms,
        MAX(ptr.execution_time_ms) as max_execution_time_ms,
        ROUND(AVG(ptr.rows_processed), 2) as avg_rows_processed,
        ROUND(AVG(ptr.cache_hit_ratio), 2) as avg_cache_hit_ratio,
        CASE 
            WHEN AVG(ptr.execution_time_ms) < 100 THEN 'A'
            WHEN AVG(ptr.execution_time_ms) < 500 THEN 'B'
            WHEN AVG(ptr.execution_time_ms) < 1000 THEN 'C'
            WHEN AVG(ptr.execution_time_ms) < 2000 THEN 'D'
            ELSE 'F'
        END::CHAR(1) as performance_grade
    FROM performance_test_results ptr
    WHERE (p_session_id IS NULL OR ptr.executed_at >= (
        SELECT started_at FROM performance_test_sessions WHERE session_id = p_session_id
    ))
    AND ptr.rows_processed >= 0  -- 실패한 테스트 제외
    GROUP BY ptr.test_category
    ORDER BY avg_execution_time_ms;
END;
$ LANGUAGE plpgsql;

-- 성능 저하 테스트 식별 함수
CREATE OR REPLACE FUNCTION identify_slow_tests(
    p_threshold_ms INTEGER DEFAULT 1000,
    p_session_id UUID DEFAULT NULL
)
RETURNS TABLE (
    test_name VARCHAR(255),
    test_category VARCHAR(100),
    execution_time_ms BIGINT,
    rows_processed INTEGER,
    cache_hit_ratio DECIMAL(5,2),
    executed_at TIMESTAMPTZ,
    performance_impact TEXT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        ptr.test_name,
        ptr.test_category,
        ptr.execution_time_ms,
        ptr.rows_processed,
        ptr.cache_hit_ratio,
        ptr.executed_at,
        CASE 
            WHEN ptr.execution_time_ms > 5000 THEN 'CRITICAL'
            WHEN ptr.execution_time_ms > 2000 THEN 'HIGH'
            WHEN ptr.execution_time_ms > p_threshold_ms THEN 'MEDIUM'
            ELSE 'LOW'
        END::TEXT as performance_impact
    FROM performance_test_results ptr
    WHERE ptr.execution_time_ms > p_threshold_ms
    AND ptr.rows_processed >= 0  -- 실패한 테스트 제외
    AND (p_session_id IS NULL OR ptr.executed_at >= (
        SELECT started_at FROM performance_test_sessions WHERE session_id = p_session_id
    ))
    ORDER BY ptr.execution_time_ms DESC;
END;
$ LANGUAGE plpgsql;

-- 성능 트렌드 분석 함수
CREATE OR REPLACE FUNCTION analyze_performance_trends(
    p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
    test_date DATE,
    test_category VARCHAR(100),
    avg_execution_time_ms DECIMAL(10,2),
    test_count BIGINT,
    trend_direction TEXT
) AS $
DECLARE
    trend_query TEXT;
BEGIN
    RETURN QUERY
    WITH daily_stats AS (
        SELECT 
            DATE(ptr.executed_at) as test_date,
            ptr.test_category,
            ROUND(AVG(ptr.execution_time_ms), 2) as avg_execution_time_ms,
            COUNT(*) as test_count
        FROM performance_test_results ptr
        WHERE ptr.executed_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
        AND ptr.rows_processed >= 0
        GROUP BY DATE(ptr.executed_at), ptr.test_category
    ),
    trend_analysis AS (
        SELECT 
            *,
            LAG(avg_execution_time_ms) OVER (
                PARTITION BY test_category 
                ORDER BY test_date
            ) as prev_avg_time
        FROM daily_stats
    )
    SELECT 
        ta.test_date,
        ta.test_category,
        ta.avg_execution_time_ms,
        ta.test_count,
        CASE 
            WHEN ta.prev_avg_time IS NULL THEN 'BASELINE'
            WHEN ta.avg_execution_time_ms > ta.prev_avg_time * 1.1 THEN 'DEGRADING'
            WHEN ta.avg_execution_time_ms < ta.prev_avg_time * 0.9 THEN 'IMPROVING'
            ELSE 'STABLE'
        END::TEXT as trend_direction
    FROM trend_analysis ta
    ORDER BY ta.test_date DESC, ta.test_category;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 성능 테스트 리포트 생성 함수
-- =====================================================

-- 성능 테스트 리포트 생성 함수
CREATE OR REPLACE FUNCTION generate_performance_report(
    p_session_id UUID
)
RETURNS TEXT AS $
DECLARE
    session_info RECORD;
    report_text TEXT := '';
    category_stats RECORD;
    slow_test RECORD;
BEGIN
    -- 세션 정보 조회
    SELECT * INTO session_info
    FROM performance_test_sessions
    WHERE session_id = p_session_id;
    
    IF NOT FOUND THEN
        RETURN 'Session not found: ' || p_session_id;
    END IF;
    
    -- 리포트 헤더
    report_text := report_text || '=====================================' || E'\n';
    report_text := report_text || 'QIRO 성능 테스트 리포트' || E'\n';
    report_text := report_text || '=====================================' || E'\n';
    report_text := report_text || '세션명: ' || session_info.session_name || E'\n';
    report_text := report_text || '실행일시: ' || session_info.started_at || E'\n';
    report_text := report_text || '완료일시: ' || COALESCE(session_info.completed_at::TEXT, 'N/A') || E'\n';
    report_text := report_text || '총 테스트: ' || session_info.total_tests || E'\n';
    report_text := report_text || '성공: ' || session_info.passed_tests || E'\n';
    report_text := report_text || '실패: ' || session_info.failed_tests || E'\n';
    report_text := report_text || E'\n';
    
    -- 데이터베이스 환경 정보
    report_text := report_text || '데이터베이스 환경:' || E'\n';
    report_text := report_text || '- 버전: ' || session_info.database_version || E'\n';
    report_text := report_text || '- 회사 수: ' || (session_info.test_data_size->>'companies_count') || E'\n';
    report_text := report_text || '- 사용자 수: ' || (session_info.test_data_size->>'users_count') || E'\n';
    report_text := report_text || '- 그룹 수: ' || (session_info.test_data_size->>'building_groups_count') || E'\n';
    report_text := report_text || '- DB 크기: ' || (session_info.test_data_size->>'database_size') || E'\n';
    report_text := report_text || E'\n';
    
    -- 카테고리별 성능 요약
    report_text := report_text || '카테고리별 성능 요약:' || E'\n';
    report_text := report_text || '----------------------------------------' || E'\n';
    
    FOR category_stats IN 
        SELECT * FROM analyze_performance_test_results(p_session_id)
    LOOP
        report_text := report_text || format(
            '- %s: %s개 테스트, 평균 %sms, 등급 %s' || E'\n',
            category_stats.category,
            category_stats.test_count,
            category_stats.avg_execution_time_ms,
            category_stats.performance_grade
        );
    END LOOP;
    
    report_text := report_text || E'\n';
    
    -- 느린 테스트 목록
    report_text := report_text || '성능 개선 필요 테스트:' || E'\n';
    report_text := report_text || '----------------------------------------' || E'\n';
    
    FOR slow_test IN 
        SELECT * FROM identify_slow_tests(500, p_session_id) LIMIT 10
    LOOP
        report_text := report_text || format(
            '- %s (%s): %sms [%s]' || E'\n',
            slow_test.test_name,
            slow_test.test_category,
            slow_test.execution_time_ms,
            slow_test.performance_impact
        );
    END LOOP;
    
    report_text := report_text || E'\n';
    report_text := report_text || '=====================================' || E'\n';
    
    RETURN report_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 자동화된 성능 테스트 스케줄링
-- =====================================================

-- 일일 성능 테스트 실행 함수
CREATE OR REPLACE FUNCTION run_daily_performance_test()
RETURNS UUID AS $
DECLARE
    session_id UUID;
BEGIN
    session_id := run_comprehensive_performance_test();
    
    -- 결과를 로그 테이블에 저장
    INSERT INTO maintenance_log (job_type, job_result, executed_at)
    VALUES (
        'daily_performance_test',
        generate_performance_report(session_id),
        now()
    );
    
    RETURN session_id;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 인덱스 생성 및 코멘트
-- =====================================================

-- 성능 테스트 결과 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_test_results_executed_at 
ON performance_test_results(executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_performance_test_results_category 
ON performance_test_results(test_category);

CREATE INDEX IF NOT EXISTS idx_performance_test_results_execution_time 
ON performance_test_results(execution_time_ms DESC);

-- 성능 테스트 세션 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_test_sessions_started_at 
ON performance_test_sessions(started_at DESC);

CREATE INDEX IF NOT EXISTS idx_performance_test_sessions_status 
ON performance_test_sessions(session_status);

-- =====================================================
-- 8. 코멘트 추가
-- =====================================================

COMMENT ON TABLE performance_test_results IS '성능 테스트 실행 결과 저장 테이블';
COMMENT ON TABLE performance_test_sessions IS '성능 테스트 세션 정보 테이블';

COMMENT ON FUNCTION start_performance_test_session(VARCHAR, TEXT) IS '성능 테스트 세션 시작';
COMMENT ON FUNCTION execute_performance_test(UUID, VARCHAR, VARCHAR, TEXT, JSONB) IS '개별 성능 테스트 실행';
COMMENT ON FUNCTION complete_performance_test_session(UUID) IS '성능 테스트 세션 완료';
COMMENT ON FUNCTION run_comprehensive_performance_test() IS '종합 성능 테스트 실행';
COMMENT ON FUNCTION analyze_performance_test_results(UUID) IS '성능 테스트 결과 분석';
COMMENT ON FUNCTION identify_slow_tests(INTEGER, UUID) IS '느린 테스트 식별';
COMMENT ON FUNCTION analyze_performance_trends(INTEGER) IS '성능 트렌드 분석';
COMMENT ON FUNCTION generate_performance_report(UUID) IS '성능 테스트 리포트 생성';
COMMENT ON FUNCTION run_daily_performance_test() IS '일일 성능 테스트 실행 (스케줄러용)';

-- =====================================================
-- 9. 사용법 안내
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '성능 테스트 실행 시스템이 준비되었습니다.';
    RAISE NOTICE '종합 성능 테스트 실행: SELECT run_comprehensive_performance_test();';
    RAISE NOTICE '결과 분석: SELECT * FROM analyze_performance_test_results();';
    RAISE NOTICE '느린 테스트 확인: SELECT * FROM identify_slow_tests();';
    RAISE NOTICE '성능 트렌드 분석: SELECT * FROM analyze_performance_trends();';
END
$;