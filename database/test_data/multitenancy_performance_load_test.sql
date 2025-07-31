-- =====================================================
-- 멀티테넌시 성능 및 부하 테스트
-- QIRO 사업자 회원가입 시스템
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;

-- =====================================================
-- 1. 부하 테스트 시나리오 정의
-- =====================================================

-- 부하 테스트 시나리오:
-- 1. 동시 사업자 등록 부하 테스트
-- 2. 멀티테넌시 데이터 격리 성능 테스트
-- 3. RLS 정책 성능 영향 측정
-- 4. 대용량 데이터 환경에서의 조회 성능
-- 5. 동시 접속 시나리오 테스트
-- 6. 메모리 및 CPU 사용량 모니터링

-- =====================================================
-- 2. 부하 테스트 결과 저장 테이블
-- =====================================================

-- 부하 테스트 결과 저장 테이블
CREATE TABLE IF NOT EXISTS load_test_results (
    test_id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_type VARCHAR(100) NOT NULL,
    concurrent_users INTEGER NOT NULL,
    total_operations INTEGER NOT NULL,
    successful_operations INTEGER NOT NULL,
    failed_operations INTEGER NOT NULL,
    avg_response_time_ms DECIMAL(10,2) NOT NULL,
    min_response_time_ms BIGINT NOT NULL,
    max_response_time_ms BIGINT NOT NULL,
    throughput_ops_per_sec DECIMAL(10,2) NOT NULL,
    error_rate_percent DECIMAL(5,2) NOT NULL,
    memory_usage_mb DECIMAL(10,2),
    cpu_usage_percent DECIMAL(5,2),
    test_duration_seconds INTEGER NOT NULL,
    test_parameters JSONB DEFAULT '{}',
    executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    executed_by VARCHAR(100) DEFAULT current_user
);

-- 부하 테스트 세션 테이블
CREATE TABLE IF NOT EXISTS load_test_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_name VARCHAR(255) NOT NULL,
    test_description TEXT,
    total_test_duration_seconds INTEGER,
    max_concurrent_users INTEGER,
    total_operations INTEGER,
    overall_success_rate DECIMAL(5,2),
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    session_status VARCHAR(20) DEFAULT 'RUNNING' CHECK (session_status IN ('RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED'))
);

-- =====================================================
-- 3. 동시 사업자 등록 부하 테스트
-- =====================================================

-- 동시 사업자 등록 시뮬레이션 함수
CREATE OR REPLACE FUNCTION simulate_concurrent_business_registration(
    p_concurrent_users INTEGER DEFAULT 10,
    p_registrations_per_user INTEGER DEFAULT 5
)
RETURNS TABLE (
    user_id INTEGER,
    successful_registrations INTEGER,
    failed_registrations INTEGER,
    avg_response_time_ms DECIMAL(10,2),
    total_time_seconds DECIMAL(10,2)
) AS $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    i INTEGER;
    j INTEGER;
    success_count INTEGER;
    fail_count INTEGER;
    total_time DECIMAL(10,2);
    reg_start_time TIMESTAMP;
    reg_end_time TIMESTAMP;
    response_times DECIMAL(10,2)[] := '{}';
    business_number TEXT;
    company_name TEXT;
    test_email TEXT;
BEGIN
    RAISE NOTICE '동시 사업자 등록 부하 테스트 시작: % 사용자, 사용자당 % 등록', 
                 p_concurrent_users, p_registrations_per_user;
    
    -- 각 동시 사용자에 대해 시뮬레이션
    FOR i IN 1..p_concurrent_users LOOP
        start_time := clock_timestamp();
        success_count := 0;
        fail_count := 0;
        response_times := '{}';
        
        -- 각 사용자가 여러 회사 등록 시도
        FOR j IN 1..p_registrations_per_user LOOP
            reg_start_time := clock_timestamp();
            
            -- 유니크한 테스트 데이터 생성
            business_number := LPAD(((i * 1000 + j + 2000000000)::BIGINT)::TEXT, 10, '0');
            company_name := '부하테스트회사_' || i || '_' || j;
            test_email := 'loadtest_' || i || '_' || j || '@test.com';
            
            BEGIN
                -- 회사 등록
                INSERT INTO companies (
                    business_registration_number, company_name, representative_name,
                    business_address, contact_phone, contact_email, business_type,
                    establishment_date, verification_status
                ) VALUES (
                    business_number, company_name, '부하테스트대표' || i || '_' || j,
                    '서울시 강남구 부하테스트로 ' || (i * 100 + j), 
                    '02-' || LPAD((i * 1000 + j)::TEXT, 8, '0'),
                    test_email, '부동산임대업', '2020-01-01', 'PENDING'
                );
                
                success_count := success_count + 1;
                
            EXCEPTION WHEN OTHERS THEN
                fail_count := fail_count + 1;
            END;
            
            reg_end_time := clock_timestamp();
            response_times := response_times || EXTRACT(EPOCH FROM (reg_end_time - reg_start_time) * 1000)::DECIMAL(10,2);
            
            -- 부하 분산을 위한 짧은 대기
            PERFORM pg_sleep(0.01);
        END LOOP;
        
        end_time := clock_timestamp();
        total_time := EXTRACT(EPOCH FROM (end_time - start_time));
        
        RETURN QUERY SELECT 
            i,
            success_count,
            fail_count,
            (SELECT AVG(rt) FROM unnest(response_times) AS rt),
            total_time;
    END LOOP;
    
    RAISE NOTICE '동시 사업자 등록 부하 테스트 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. RLS 성능 영향 측정 테스트
-- =====================================================

-- RLS 성능 영향 측정 함수
CREATE OR REPLACE FUNCTION measure_rls_performance_impact(
    p_test_iterations INTEGER DEFAULT 1000
)
RETURNS TABLE (
    test_scenario TEXT,
    avg_execution_time_ms DECIMAL(10,2),
    min_execution_time_ms BIGINT,
    max_execution_time_ms BIGINT,
    performance_impact_percent DECIMAL(5,2)
) AS $
DECLARE
    i INTEGER;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_times_without_rls BIGINT[] := '{}';
    execution_times_with_rls BIGINT[] := '{}';
    test_company_id UUID;
    execution_time BIGINT;
    avg_without_rls DECIMAL(10,2);
    avg_with_rls DECIMAL(10,2);
BEGIN
    RAISE NOTICE 'RLS 성능 영향 측정 시작: % 회 반복', p_test_iterations;
    
    -- 테스트용 회사 ID 선택
    SELECT company_id INTO test_company_id 
    FROM companies 
    WHERE company_name LIKE '테스트회사%' 
    LIMIT 1;
    
    IF test_company_id IS NULL THEN
        RAISE EXCEPTION '테스트 데이터가 없습니다. 먼저 성능 테스트 데이터를 생성하세요.';
    END IF;
    
    -- 1. RLS 비활성화 상태에서 성능 측정
    ALTER TABLE users DISABLE ROW LEVEL SECURITY;
    ALTER TABLE companies DISABLE ROW LEVEL SECURITY;
    ALTER TABLE building_groups DISABLE ROW LEVEL SECURITY;
    
    FOR i IN 1..p_test_iterations LOOP
        start_time := clock_timestamp();
        
        PERFORM u.user_id, u.full_name, c.company_name
        FROM users u 
        JOIN companies c ON u.company_id = c.company_id
        WHERE c.verification_status = 'VERIFIED'
        AND u.status = 'ACTIVE'
        LIMIT 50;
        
        end_time := clock_timestamp();
        execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
        execution_times_without_rls := execution_times_without_rls || execution_time;
    END LOOP;
    
    -- 2. RLS 활성화 상태에서 성능 측정
    ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
    ALTER TABLE building_groups ENABLE ROW LEVEL SECURITY;
    
    PERFORM set_config('app.current_company_id', test_company_id::TEXT, false);
    
    FOR i IN 1..p_test_iterations LOOP
        start_time := clock_timestamp();
        
        PERFORM u.user_id, u.full_name, c.company_name
        FROM users u 
        JOIN companies c ON u.company_id = c.company_id
        WHERE c.verification_status = 'VERIFIED'
        AND u.status = 'ACTIVE'
        LIMIT 50;
        
        end_time := clock_timestamp();
        execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
        execution_times_with_rls := execution_times_with_rls || execution_time;
    END LOOP;
    
    PERFORM set_config('app.current_company_id', '', false);
    
    -- 결과 계산
    SELECT AVG(et) INTO avg_without_rls FROM unnest(execution_times_without_rls) AS et;
    SELECT AVG(et) INTO avg_with_rls FROM unnest(execution_times_with_rls) AS et;
    
    -- RLS 비활성화 결과 반환
    RETURN QUERY SELECT 
        'RLS 비활성화'::TEXT,
        avg_without_rls,
        (SELECT MIN(et) FROM unnest(execution_times_without_rls) AS et),
        (SELECT MAX(et) FROM unnest(execution_times_without_rls) AS et),
        0.00::DECIMAL(5,2);
    
    -- RLS 활성화 결과 반환
    RETURN QUERY SELECT 
        'RLS 활성화'::TEXT,
        avg_with_rls,
        (SELECT MIN(et) FROM unnest(execution_times_with_rls) AS et),
        (SELECT MAX(et) FROM unnest(execution_times_with_rls) AS et),
        ROUND(((avg_with_rls - avg_without_rls) / avg_without_rls * 100), 2);
    
    RAISE NOTICE 'RLS 성능 영향 측정 완료';
    RAISE NOTICE 'RLS 비활성화 평균: %ms, RLS 활성화 평균: %ms', avg_without_rls, avg_with_rls;
    RAISE NOTICE '성능 영향: %%%', ROUND(((avg_with_rls - avg_without_rls) / avg_without_rls * 100), 2);
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 동시 접속 시나리오 테스트
-- =====================================================

-- 동시 접속 시뮬레이션 함수
CREATE OR REPLACE FUNCTION simulate_concurrent_access(
    p_concurrent_sessions INTEGER DEFAULT 50,
    p_operations_per_session INTEGER DEFAULT 20
)
RETURNS TABLE (
    session_id INTEGER,
    successful_operations INTEGER,
    failed_operations INTEGER,
    avg_response_time_ms DECIMAL(10,2),
    total_session_time_seconds DECIMAL(10,2)
) AS $
DECLARE
    i INTEGER;
    j INTEGER;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    op_start_time TIMESTAMP;
    op_end_time TIMESTAMP;
    success_count INTEGER;
    fail_count INTEGER;
    response_times DECIMAL(10,2)[] := '{}';
    test_companies UUID[];
    selected_company_id UUID;
    operation_type INTEGER;
BEGIN
    RAISE NOTICE '동시 접속 시뮬레이션 시작: % 세션, 세션당 % 작업', 
                 p_concurrent_sessions, p_operations_per_session;
    
    -- 테스트용 회사 ID 목록 준비
    SELECT ARRAY(
        SELECT company_id 
        FROM companies 
        WHERE company_name LIKE '테스트회사%' 
        LIMIT 100
    ) INTO test_companies;
    
    IF array_length(test_companies, 1) = 0 THEN
        RAISE EXCEPTION '테스트 데이터가 없습니다. 먼저 성능 테스트 데이터를 생성하세요.';
    END IF;
    
    -- 각 동시 세션 시뮬레이션
    FOR i IN 1..p_concurrent_sessions LOOP
        start_time := clock_timestamp();
        success_count := 0;
        fail_count := 0;
        response_times := '{}';
        
        -- 랜덤 회사 선택
        selected_company_id := test_companies[1 + (i % array_length(test_companies, 1))];
        
        -- 회사 컨텍스트 설정
        PERFORM set_config('app.current_company_id', selected_company_id::TEXT, false);
        
        -- 각 세션에서 여러 작업 수행
        FOR j IN 1..p_operations_per_session LOOP
            op_start_time := clock_timestamp();
            operation_type := (j % 5) + 1;
            
            BEGIN
                CASE operation_type
                    WHEN 1 THEN
                        -- 사용자 목록 조회
                        PERFORM * FROM users WHERE status = 'ACTIVE' LIMIT 10;
                    WHEN 2 THEN
                        -- 건물 그룹 조회
                        PERFORM * FROM building_groups WHERE is_active = true LIMIT 10;
                    WHEN 3 THEN
                        -- 회사 정보 조회
                        PERFORM * FROM companies WHERE verification_status = 'VERIFIED';
                    WHEN 4 THEN
                        -- 복합 조인 쿼리
                        PERFORM u.full_name, r.role_name 
                        FROM users u 
                        JOIN user_role_links url ON u.user_id = url.user_id 
                        JOIN roles r ON url.role_id = r.role_id 
                        LIMIT 5;
                    WHEN 5 THEN
                        -- 인증 레코드 조회
                        PERFORM * FROM business_verification_records 
                        WHERE verification_status = 'SUCCESS' 
                        ORDER BY verification_date DESC 
                        LIMIT 5;
                END CASE;
                
                success_count := success_count + 1;
                
            EXCEPTION WHEN OTHERS THEN
                fail_count := fail_count + 1;
            END;
            
            op_end_time := clock_timestamp();
            response_times := response_times || EXTRACT(EPOCH FROM (op_end_time - op_start_time) * 1000)::DECIMAL(10,2);
            
            -- 작업 간 짧은 대기 (실제 사용자 행동 시뮬레이션)
            PERFORM pg_sleep(0.05 + random() * 0.1);
        END LOOP;
        
        -- 컨텍스트 초기화
        PERFORM set_config('app.current_company_id', '', false);
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            i,
            success_count,
            fail_count,
            (SELECT AVG(rt) FROM unnest(response_times) AS rt),
            EXTRACT(EPOCH FROM (end_time - start_time))::DECIMAL(10,2);
    END LOOP;
    
    RAISE NOTICE '동시 접속 시뮬레이션 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 대용량 데이터 조회 성능 테스트
-- =====================================================

-- 대용량 데이터 조회 성능 테스트 함수
CREATE OR REPLACE FUNCTION test_large_dataset_performance()
RETURNS TABLE (
    test_name TEXT,
    dataset_size INTEGER,
    execution_time_ms BIGINT,
    rows_returned INTEGER,
    throughput_rows_per_sec DECIMAL(10,2)
) AS $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time BIGINT;
    row_count INTEGER;
BEGIN
    RAISE NOTICE '대용량 데이터 조회 성능 테스트 시작';
    
    -- 테스트 1: 전체 회사 목록 조회
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count FROM companies;
    end_time := clock_timestamp();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        '전체 회사 수 조회'::TEXT,
        row_count,
        execution_time,
        row_count,
        CASE WHEN execution_time > 0 THEN (row_count::DECIMAL / (execution_time::DECIMAL / 1000)) ELSE 0 END;
    
    -- 테스트 2: 페이지네이션 조회 (첫 페이지)
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count 
    FROM companies 
    WHERE verification_status = 'VERIFIED' 
    ORDER BY created_at DESC 
    LIMIT 50;
    end_time := clock_timestamp();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        '페이지네이션 조회 (첫 페이지)'::TEXT,
        (SELECT COUNT(*) FROM companies WHERE verification_status = 'VERIFIED')::INTEGER,
        execution_time,
        LEAST(row_count, 50),
        CASE WHEN execution_time > 0 THEN (LEAST(row_count, 50)::DECIMAL / (execution_time::DECIMAL / 1000)) ELSE 0 END;
    
    -- 테스트 3: 복합 조인 쿼리
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM companies c
    JOIN users u ON c.company_id = u.company_id
    JOIN user_role_links url ON u.user_id = url.user_id
    JOIN roles r ON url.role_id = r.role_id
    WHERE c.verification_status = 'VERIFIED'
    AND u.status = 'ACTIVE';
    end_time := clock_timestamp();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        '복합 조인 쿼리'::TEXT,
        row_count,
        execution_time,
        row_count,
        CASE WHEN execution_time > 0 THEN (row_count::DECIMAL / (execution_time::DECIMAL / 1000)) ELSE 0 END;
    
    -- 테스트 4: 집계 쿼리
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM (
        SELECT c.company_id, c.company_name, COUNT(u.user_id) as user_count
        FROM companies c
        LEFT JOIN users u ON c.company_id = u.company_id
        WHERE c.verification_status = 'VERIFIED'
        GROUP BY c.company_id, c.company_name
        HAVING COUNT(u.user_id) > 0
    ) subq;
    end_time := clock_timestamp();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        '집계 쿼리 (회사별 사용자 수)'::TEXT,
        row_count,
        execution_time,
        row_count,
        CASE WHEN execution_time > 0 THEN (row_count::DECIMAL / (execution_time::DECIMAL / 1000)) ELSE 0 END;
    
    -- 테스트 5: 전문 검색
    start_time := clock_timestamp();
    SELECT COUNT(*) INTO row_count
    FROM companies
    WHERE company_name ILIKE '%테스트%'
    OR representative_name ILIKE '%테스트%';
    end_time := clock_timestamp();
    execution_time := EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT;
    
    RETURN QUERY SELECT 
        '전문 검색 (ILIKE)'::TEXT,
        (SELECT COUNT(*) FROM companies)::INTEGER,
        execution_time,
        row_count,
        CASE WHEN execution_time > 0 THEN (row_count::DECIMAL / (execution_time::DECIMAL / 1000)) ELSE 0 END;
    
    RAISE NOTICE '대용량 데이터 조회 성능 테스트 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 종합 부하 테스트 실행 함수
-- =====================================================

-- 종합 부하 테스트 실행 함수
CREATE OR REPLACE FUNCTION run_comprehensive_load_test()
RETURNS UUID AS $
DECLARE
    session_id UUID;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    total_operations INTEGER := 0;
    successful_operations INTEGER := 0;
    failed_operations INTEGER := 0;
    reg_result RECORD;
    access_result RECORD;
    perf_result RECORD;
BEGIN
    -- 부하 테스트 세션 시작
    INSERT INTO load_test_sessions (
        session_name,
        test_description,
        started_at
    ) VALUES (
        'Comprehensive Load Test',
        'QIRO 멀티테넌시 환경 종합 부하 테스트',
        now()
    ) RETURNING session_id;
    
    start_time := clock_timestamp();
    
    RAISE NOTICE '=== 종합 부하 테스트 시작 (세션 ID: %) ===', session_id;
    
    -- 1. 동시 사업자 등록 부하 테스트
    RAISE NOTICE '1. 동시 사업자 등록 부하 테스트 실행 중...';
    
    FOR reg_result IN SELECT * FROM simulate_concurrent_business_registration(20, 3) LOOP
        total_operations := total_operations + reg_result.successful_registrations + reg_result.failed_registrations;
        successful_operations := successful_operations + reg_result.successful_registrations;
        failed_operations := failed_operations + reg_result.failed_registrations;
    END LOOP;
    
    -- 2. RLS 성능 영향 측정
    RAISE NOTICE '2. RLS 성능 영향 측정 중...';
    
    FOR perf_result IN SELECT * FROM measure_rls_performance_impact(500) LOOP
        RAISE NOTICE 'RLS 성능 측정: % - 평균 %ms', 
                     perf_result.test_scenario, perf_result.avg_execution_time_ms;
    END LOOP;
    
    -- 3. 동시 접속 시뮬레이션
    RAISE NOTICE '3. 동시 접속 시뮬레이션 실행 중...';
    
    FOR access_result IN SELECT * FROM simulate_concurrent_access(30, 15) LOOP
        total_operations := total_operations + access_result.successful_operations + access_result.failed_operations;
        successful_operations := successful_operations + access_result.successful_operations;
        failed_operations := failed_operations + access_result.failed_operations;
    END LOOP;
    
    -- 4. 대용량 데이터 조회 성능 테스트
    RAISE NOTICE '4. 대용량 데이터 조회 성능 테스트 실행 중...';
    
    FOR perf_result IN SELECT * FROM test_large_dataset_performance() LOOP
        RAISE NOTICE '대용량 조회 테스트: % - %ms (%개 행)', 
                     perf_result.test_name, perf_result.execution_time_ms, perf_result.rows_returned;
    END LOOP;
    
    end_time := clock_timestamp();
    
    -- 세션 완료 처리
    UPDATE load_test_sessions 
    SET 
        completed_at = end_time,
        total_test_duration_seconds = EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER,
        max_concurrent_users = 50, -- 최대 동시 사용자 수
        total_operations = total_operations,
        overall_success_rate = CASE 
            WHEN total_operations > 0 THEN (successful_operations::DECIMAL / total_operations * 100)
            ELSE 0 
        END,
        session_status = 'COMPLETED'
    WHERE session_id = session_id;
    
    RAISE NOTICE '=== 종합 부하 테스트 완료 ===';
    RAISE NOTICE '총 소요 시간: %', end_time - start_time;
    RAISE NOTICE '총 작업 수: %, 성공: %, 실패: %', total_operations, successful_operations, failed_operations;
    RAISE NOTICE '성공률: %%', ROUND((successful_operations::DECIMAL / total_operations * 100), 2);
    
    RETURN session_id;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 8. 부하 테스트 결과 분석 함수
-- =====================================================

-- 부하 테스트 결과 분석 함수
CREATE OR REPLACE FUNCTION analyze_load_test_results(
    p_session_id UUID
)
RETURNS TABLE (
    metric_name TEXT,
    metric_value TEXT,
    performance_grade CHAR(1),
    recommendation TEXT
) AS $
DECLARE
    session_info RECORD;
    avg_response_time DECIMAL(10,2);
    max_response_time BIGINT;
    error_rate DECIMAL(5,2);
    throughput DECIMAL(10,2);
BEGIN
    -- 세션 정보 조회
    SELECT * INTO session_info
    FROM load_test_sessions
    WHERE session_id = p_session_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'Error'::TEXT, 'Session not found'::TEXT, 'F'::CHAR(1), 'Check session ID'::TEXT;
        RETURN;
    END IF;
    
    -- 기본 메트릭 반환
    RETURN QUERY SELECT 
        '총 테스트 시간'::TEXT,
        session_info.total_test_duration_seconds || ' 초'::TEXT,
        CASE 
            WHEN session_info.total_test_duration_seconds < 300 THEN 'A'
            WHEN session_info.total_test_duration_seconds < 600 THEN 'B'
            WHEN session_info.total_test_duration_seconds < 1200 THEN 'C'
            ELSE 'D'
        END::CHAR(1),
        '테스트 완료 시간'::TEXT;
    
    RETURN QUERY SELECT 
        '전체 성공률'::TEXT,
        ROUND(session_info.overall_success_rate, 2) || '%'::TEXT,
        CASE 
            WHEN session_info.overall_success_rate >= 99 THEN 'A'
            WHEN session_info.overall_success_rate >= 95 THEN 'B'
            WHEN session_info.overall_success_rate >= 90 THEN 'C'
            WHEN session_info.overall_success_rate >= 80 THEN 'D'
            ELSE 'F'
        END::CHAR(1),
        CASE 
            WHEN session_info.overall_success_rate >= 95 THEN '우수한 안정성'
            WHEN session_info.overall_success_rate >= 90 THEN '양호한 안정성'
            ELSE '안정성 개선 필요'
        END::TEXT;
    
    RETURN QUERY SELECT 
        '최대 동시 사용자'::TEXT,
        session_info.max_concurrent_users || ' 명'::TEXT,
        CASE 
            WHEN session_info.max_concurrent_users >= 100 THEN 'A'
            WHEN session_info.max_concurrent_users >= 50 THEN 'B'
            WHEN session_info.max_concurrent_users >= 20 THEN 'C'
            ELSE 'D'
        END::CHAR(1),
        '동시 접속 처리 능력'::TEXT;
    
    RETURN QUERY SELECT 
        '총 작업 수'::TEXT,
        session_info.total_operations || ' 개'::TEXT,
        CASE 
            WHEN session_info.total_operations >= 1000 THEN 'A'
            WHEN session_info.total_operations >= 500 THEN 'B'
            WHEN session_info.total_operations >= 100 THEN 'C'
            ELSE 'D'
        END::CHAR(1),
        '처리량 지표'::TEXT;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 9. 부하 테스트 리포트 생성 함수
-- =====================================================

-- 부하 테스트 리포트 생성 함수
CREATE OR REPLACE FUNCTION generate_load_test_report(
    p_session_id UUID
)
RETURNS TEXT AS $
DECLARE
    session_info RECORD;
    report_text TEXT := '';
    metric_info RECORD;
BEGIN
    -- 세션 정보 조회
    SELECT * INTO session_info
    FROM load_test_sessions
    WHERE session_id = p_session_id;
    
    IF NOT FOUND THEN
        RETURN 'Load test session not found: ' || p_session_id;
    END IF;
    
    -- 리포트 헤더
    report_text := report_text || '=====================================' || E'\n';
    report_text := report_text || 'QIRO 부하 테스트 리포트' || E'\n';
    report_text := report_text || '=====================================' || E'\n';
    report_text := report_text || '세션명: ' || session_info.session_name || E'\n';
    report_text := report_text || '테스트 설명: ' || COALESCE(session_info.test_description, 'N/A') || E'\n';
    report_text := report_text || '시작 시간: ' || session_info.started_at || E'\n';
    report_text := report_text || '완료 시간: ' || COALESCE(session_info.completed_at::TEXT, 'N/A') || E'\n';
    report_text := report_text || '상태: ' || session_info.session_status || E'\n';
    report_text := report_text || E'\n';
    
    -- 성능 메트릭
    report_text := report_text || '성능 메트릭:' || E'\n';
    report_text := report_text || '----------------------------------------' || E'\n';
    
    FOR metric_info IN 
        SELECT * FROM analyze_load_test_results(p_session_id)
    LOOP
        report_text := report_text || format(
            '- %s: %s [등급: %s] - %s' || E'\n',
            metric_info.metric_name,
            metric_info.metric_value,
            metric_info.performance_grade,
            metric_info.recommendation
        );
    END LOOP;
    
    report_text := report_text || E'\n';
    
    -- 권장사항
    report_text := report_text || '권장사항:' || E'\n';
    report_text := report_text || '----------------------------------------' || E'\n';
    
    IF session_info.overall_success_rate < 95 THEN
        report_text := report_text || '- 오류율이 높습니다. 데이터베이스 연결 풀 및 쿼리 최적화를 검토하세요.' || E'\n';
    END IF;
    
    IF session_info.total_test_duration_seconds > 600 THEN
        report_text := report_text || '- 테스트 완료 시간이 깁니다. 인덱스 최적화를 고려하세요.' || E'\n';
    END IF;
    
    IF session_info.max_concurrent_users < 50 THEN
        report_text := report_text || '- 동시 접속 처리 능력을 향상시키기 위해 커넥션 풀 설정을 검토하세요.' || E'\n';
    END IF;
    
    report_text := report_text || '- 정기적인 부하 테스트를 통해 성능 트렌드를 모니터링하세요.' || E'\n';
    report_text := report_text || '- RLS 정책의 성능 영향을 지속적으로 모니터링하세요.' || E'\n';
    
    report_text := report_text || E'\n';
    report_text := report_text || '=====================================' || E'\n';
    
    RETURN report_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 10. 테스트 정리 함수
-- =====================================================

-- 부하 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_load_test_data()
RETURNS VOID AS $
BEGIN
    -- 부하 테스트로 생성된 회사 데이터 삭제
    DELETE FROM companies WHERE company_name LIKE '부하테스트회사_%';
    
    -- 테스트 결과 테이블 정리 (선택적)
    -- DELETE FROM load_test_results WHERE executed_at < now() - INTERVAL '30 days';
    -- DELETE FROM load_test_sessions WHERE started_at < now() - INTERVAL '30 days';
    
    -- 테스트 함수들 삭제
    DROP FUNCTION IF EXISTS simulate_concurrent_business_registration(INTEGER, INTEGER);
    DROP FUNCTION IF EXISTS measure_rls_performance_impact(INTEGER);
    DROP FUNCTION IF EXISTS simulate_concurrent_access(INTEGER, INTEGER);
    DROP FUNCTION IF EXISTS test_large_dataset_performance();
    DROP FUNCTION IF EXISTS run_comprehensive_load_test();
    DROP FUNCTION IF EXISTS analyze_load_test_results(UUID);
    DROP FUNCTION IF EXISTS generate_load_test_report(UUID);
    DROP FUNCTION IF EXISTS cleanup_load_test_data();
    
    RAISE NOTICE '부하 테스트 데이터 및 함수 정리 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 11. 인덱스 및 코멘트
-- =====================================================

-- 부하 테스트 결과 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_load_test_results_executed_at 
ON load_test_results(executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_load_test_results_test_type 
ON load_test_results(test_type);

-- 부하 테스트 세션 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_load_test_sessions_started_at 
ON load_test_sessions(started_at DESC);

-- 코멘트 추가
COMMENT ON TABLE load_test_results IS '부하 테스트 실행 결과 저장 테이블';
COMMENT ON TABLE load_test_sessions IS '부하 테스트 세션 정보 테이블';

-- =====================================================
-- 12. 사용법 안내
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '멀티테넌시 성능 및 부하 테스트 시스템이 준비되었습니다.';
    RAISE NOTICE '';
    RAISE NOTICE '사용법:';
    RAISE NOTICE '1. 테스트 데이터 생성: SELECT setup_performance_test_data(1000, 5, 3, 2);';
    RAISE NOTICE '2. 종합 부하 테스트 실행: SELECT run_comprehensive_load_test();';
    RAISE NOTICE '3. 결과 분석: SELECT * FROM analyze_load_test_results(session_id);';
    RAISE NOTICE '4. 리포트 생성: SELECT generate_load_test_report(session_id);';
    RAISE NOTICE '5. 정리: SELECT cleanup_load_test_data();';
    RAISE NOTICE '';
    RAISE NOTICE '개별 테스트:';
    RAISE NOTICE '- 동시 등록: SELECT * FROM simulate_concurrent_business_registration(20, 3);';
    RAISE NOTICE '- RLS 성능: SELECT * FROM measure_rls_performance_impact(1000);';
    RAISE NOTICE '- 동시 접속: SELECT * FROM simulate_concurrent_access(50, 20);';
    RAISE NOTICE '- 대용량 조회: SELECT * FROM test_large_dataset_performance();';
END
$;