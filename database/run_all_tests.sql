-- =====================================================
-- QIRO 사업자 회원가입 시스템 전체 테스트 실행 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시, 회원가입 플로우, 성능 테스트 통합 실행
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;

-- =====================================================
-- 1. 테스트 실행 로그 테이블
-- =====================================================

-- 테스트 실행 로그 테이블 생성
CREATE TABLE IF NOT EXISTS test_execution_log (
    log_id BIGSERIAL PRIMARY KEY,
    test_suite VARCHAR(100) NOT NULL,
    test_name VARCHAR(255) NOT NULL,
    test_status VARCHAR(20) NOT NULL CHECK (test_status IN ('RUNNING', 'PASSED', 'FAILED', 'SKIPPED')),
    execution_time_ms BIGINT,
    error_message TEXT,
    test_details JSONB DEFAULT '{}',
    executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    executed_by VARCHAR(100) DEFAULT current_user
);

-- =====================================================
-- 2. 전체 테스트 실행 함수
-- =====================================================

-- 전체 테스트 스위트 실행 함수
CREATE OR REPLACE FUNCTION run_all_qiro_tests(
    p_include_performance_data BOOLEAN DEFAULT false,
    p_performance_data_size INTEGER DEFAULT 100
)
RETURNS TABLE (
    test_suite VARCHAR(100),
    total_tests INTEGER,
    passed_tests INTEGER,
    failed_tests INTEGER,
    skipped_tests INTEGER,
    success_rate DECIMAL(5,2),
    total_execution_time_seconds DECIMAL(10,2)
) AS $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    suite_start_time TIMESTAMP;
    suite_end_time TIMESTAMP;
    test_start_time TIMESTAMP;
    test_end_time TIMESTAMP;
    
    -- 테스트 결과 카운터
    multitenancy_total INTEGER := 0;
    multitenancy_passed INTEGER := 0;
    multitenancy_failed INTEGER := 0;
    
    registration_total INTEGER := 0;
    registration_passed INTEGER := 0;
    registration_failed INTEGER := 0;
    
    performance_total INTEGER := 0;
    performance_passed INTEGER := 0;
    performance_failed INTEGER := 0;
    
    -- 실행 시간 추적
    multitenancy_time DECIMAL(10,2) := 0;
    registration_time DECIMAL(10,2) := 0;
    performance_time DECIMAL(10,2) := 0;
    
    -- 기타 변수
    test_result BOOLEAN;
    error_msg TEXT;
    session_id UUID;
BEGIN
    start_time := clock_timestamp();
    
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'QIRO 사업자 회원가입 시스템 전체 테스트 시작';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '시작 시간: %', start_time;
    RAISE NOTICE '성능 테스트 데이터 생성: %', CASE WHEN p_include_performance_data THEN 'YES' ELSE 'NO' END;
    RAISE NOTICE '';
    
    -- =====================================================
    -- 테스트 스위트 1: 멀티테넌시 데이터 격리 테스트
    -- =====================================================
    
    suite_start_time := clock_timestamp();
    RAISE NOTICE '1. 멀티테넌시 데이터 격리 테스트 시작';
    RAISE NOTICE '----------------------------------------------------';
    
    BEGIN
        -- 멀티테넌시 격리 테스트 실행
        test_start_time := clock_timestamp();
        
        -- 테스트 파일 로드 및 실행
        \i database/test_data/multitenancy_isolation_test.sql
        
        test_end_time := clock_timestamp();
        
        -- 성공으로 간주 (예외가 발생하지 않았으므로)
        multitenancy_total := multitenancy_total + 1;
        multitenancy_passed := multitenancy_passed + 1;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            execution_time_ms, test_details
        ) VALUES (
            'Multitenancy', 'Data Isolation Test', 'PASSED',
            EXTRACT(EPOCH FROM (test_end_time - test_start_time) * 1000)::BIGINT,
            jsonb_build_object('description', 'RLS 정책 및 데이터 격리 검증')
        );
        
    EXCEPTION WHEN OTHERS THEN
        multitenancy_total := multitenancy_total + 1;
        multitenancy_failed := multitenancy_failed + 1;
        error_msg := SQLERRM;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            error_message, test_details
        ) VALUES (
            'Multitenancy', 'Data Isolation Test', 'FAILED',
            error_msg,
            jsonb_build_object('description', 'RLS 정책 및 데이터 격리 검증')
        );
        
        RAISE NOTICE '멀티테넌시 테스트 실패: %', error_msg;
    END;
    
    suite_end_time := clock_timestamp();
    multitenancy_time := EXTRACT(EPOCH FROM (suite_end_time - suite_start_time));
    
    RAISE NOTICE '멀티테넌시 테스트 완료: %초', multitenancy_time;
    RAISE NOTICE '';
    
    -- =====================================================
    -- 테스트 스위트 2: 사업자 회원가입 플로우 테스트
    -- =====================================================
    
    suite_start_time := clock_timestamp();
    RAISE NOTICE '2. 사업자 회원가입 플로우 통합 테스트 시작';
    RAISE NOTICE '----------------------------------------------------';
    
    BEGIN
        -- 회원가입 플로우 테스트 실행
        test_start_time := clock_timestamp();
        
        -- 테스트 파일 로드 및 실행
        \i database/test_data/business_registration_integration_test.sql
        
        test_end_time := clock_timestamp();
        
        -- 성공으로 간주
        registration_total := registration_total + 1;
        registration_passed := registration_passed + 1;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            execution_time_ms, test_details
        ) VALUES (
            'Registration', 'Business Registration Flow Test', 'PASSED',
            EXTRACT(EPOCH FROM (test_end_time - test_start_time) * 1000)::BIGINT,
            jsonb_build_object('description', '전체 회원가입 프로세스 검증')
        );
        
    EXCEPTION WHEN OTHERS THEN
        registration_total := registration_total + 1;
        registration_failed := registration_failed + 1;
        error_msg := SQLERRM;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            error_message, test_details
        ) VALUES (
            'Registration', 'Business Registration Flow Test', 'FAILED',
            error_msg,
            jsonb_build_object('description', '전체 회원가입 프로세스 검증')
        );
        
        RAISE NOTICE '회원가입 플로우 테스트 실패: %', error_msg;
    END;
    
    suite_end_time := clock_timestamp();
    registration_time := EXTRACT(EPOCH FROM (suite_end_time - suite_start_time));
    
    RAISE NOTICE '회원가입 플로우 테스트 완료: %초', registration_time;
    RAISE NOTICE '';
    
    -- =====================================================
    -- 테스트 스위트 3: 성능 및 부하 테스트
    -- =====================================================
    
    suite_start_time := clock_timestamp();
    RAISE NOTICE '3. 성능 및 부하 테스트 시작';
    RAISE NOTICE '----------------------------------------------------';
    
    -- 성능 테스트 데이터 생성 (옵션)
    IF p_include_performance_data THEN
        RAISE NOTICE '성능 테스트 데이터 생성 중... (% 개 회사)', p_performance_data_size;
        
        BEGIN
            -- 성능 테스트 데이터 생성
            \i database/test_data/performance_test_data.sql
            PERFORM setup_performance_test_data(p_performance_data_size, 3, 2, 1);
            
            performance_total := performance_total + 1;
            performance_passed := performance_passed + 1;
            
            INSERT INTO test_execution_log (
                test_suite, test_name, test_status, test_details
            ) VALUES (
                'Performance', 'Test Data Generation', 'PASSED',
                jsonb_build_object(
                    'description', '성능 테스트용 대용량 데이터 생성',
                    'company_count', p_performance_data_size
                )
            );
            
        EXCEPTION WHEN OTHERS THEN
            performance_total := performance_total + 1;
            performance_failed := performance_failed + 1;
            error_msg := SQLERRM;
            
            INSERT INTO test_execution_log (
                test_suite, test_name, test_status, 
                error_message, test_details
            ) VALUES (
                'Performance', 'Test Data Generation', 'FAILED',
                error_msg,
                jsonb_build_object('description', '성능 테스트용 대용량 데이터 생성')
            );
            
            RAISE NOTICE '성능 테스트 데이터 생성 실패: %', error_msg;
        END;
    END IF;
    
    -- 성능 테스트 실행
    BEGIN
        test_start_time := clock_timestamp();
        
        -- 성능 테스트 파일 로드 및 실행
        \i database/test_data/multitenancy_performance_load_test.sql
        
        -- 종합 부하 테스트 실행
        session_id := run_comprehensive_load_test();
        
        test_end_time := clock_timestamp();
        
        performance_total := performance_total + 1;
        performance_passed := performance_passed + 1;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            execution_time_ms, test_details
        ) VALUES (
            'Performance', 'Comprehensive Load Test', 'PASSED',
            EXTRACT(EPOCH FROM (test_end_time - test_start_time) * 1000)::BIGINT,
            jsonb_build_object(
                'description', '종합 성능 및 부하 테스트',
                'session_id', session_id
            )
        );
        
    EXCEPTION WHEN OTHERS THEN
        performance_total := performance_total + 1;
        performance_failed := performance_failed + 1;
        error_msg := SQLERRM;
        
        INSERT INTO test_execution_log (
            test_suite, test_name, test_status, 
            error_message, test_details
        ) VALUES (
            'Performance', 'Comprehensive Load Test', 'FAILED',
            error_msg,
            jsonb_build_object('description', '종합 성능 및 부하 테스트')
        );
        
        RAISE NOTICE '성능 테스트 실패: %', error_msg;
    END;
    
    suite_end_time := clock_timestamp();
    performance_time := EXTRACT(EPOCH FROM (suite_end_time - suite_start_time));
    
    RAISE NOTICE '성능 및 부하 테스트 완료: %초', performance_time;
    RAISE NOTICE '';
    
    -- =====================================================
    -- 테스트 결과 요약
    -- =====================================================
    
    end_time := clock_timestamp();
    
    RAISE NOTICE '====================================================';
    RAISE NOTICE '전체 테스트 결과 요약';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '완료 시간: %', end_time;
    RAISE NOTICE '총 소요 시간: %', end_time - start_time;
    RAISE NOTICE '';
    
    -- 결과 반환
    RETURN QUERY SELECT 
        'Multitenancy'::VARCHAR(100),
        multitenancy_total,
        multitenancy_passed,
        multitenancy_failed,
        0, -- skipped
        CASE WHEN multitenancy_total > 0 THEN ROUND((multitenancy_passed::DECIMAL / multitenancy_total) * 100, 2) ELSE 0 END,
        multitenancy_time;
    
    RETURN QUERY SELECT 
        'Registration'::VARCHAR(100),
        registration_total,
        registration_passed,
        registration_failed,
        0, -- skipped
        CASE WHEN registration_total > 0 THEN ROUND((registration_passed::DECIMAL / registration_total) * 100, 2) ELSE 0 END,
        registration_time;
    
    RETURN QUERY SELECT 
        'Performance'::VARCHAR(100),
        performance_total,
        performance_passed,
        performance_failed,
        0, -- skipped
        CASE WHEN performance_total > 0 THEN ROUND((performance_passed::DECIMAL / performance_total) * 100, 2) ELSE 0 END,
        performance_time;
    
    -- 전체 요약
    RETURN QUERY SELECT 
        'TOTAL'::VARCHAR(100),
        multitenancy_total + registration_total + performance_total,
        multitenancy_passed + registration_passed + performance_passed,
        multitenancy_failed + registration_failed + performance_failed,
        0, -- skipped
        CASE WHEN (multitenancy_total + registration_total + performance_total) > 0 
             THEN ROUND(((multitenancy_passed + registration_passed + performance_passed)::DECIMAL / 
                        (multitenancy_total + registration_total + performance_total)) * 100, 2) 
             ELSE 0 END,
        EXTRACT(EPOCH FROM (end_time - start_time))::DECIMAL(10,2);
    
    RAISE NOTICE '테스트 실행 로그는 test_execution_log 테이블에서 확인할 수 있습니다.';
    RAISE NOTICE '====================================================';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 테스트 결과 분석 함수
-- =====================================================

-- 테스트 실행 히스토리 조회 함수
CREATE OR REPLACE FUNCTION get_test_execution_history(
    p_days INTEGER DEFAULT 7
)
RETURNS TABLE (
    execution_date DATE,
    test_suite VARCHAR(100),
    total_tests BIGINT,
    passed_tests BIGINT,
    failed_tests BIGINT,
    success_rate DECIMAL(5,2),
    avg_execution_time_ms DECIMAL(10,2)
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        DATE(tel.executed_at) as execution_date,
        tel.test_suite,
        COUNT(*) as total_tests,
        COUNT(CASE WHEN tel.test_status = 'PASSED' THEN 1 END) as passed_tests,
        COUNT(CASE WHEN tel.test_status = 'FAILED' THEN 1 END) as failed_tests,
        ROUND(
            (COUNT(CASE WHEN tel.test_status = 'PASSED' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 
            2
        ) as success_rate,
        ROUND(AVG(tel.execution_time_ms), 2) as avg_execution_time_ms
    FROM test_execution_log tel
    WHERE tel.executed_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    GROUP BY DATE(tel.executed_at), tel.test_suite
    ORDER BY execution_date DESC, tel.test_suite;
END;
$ LANGUAGE plpgsql;

-- 실패한 테스트 상세 조회 함수
CREATE OR REPLACE FUNCTION get_failed_tests_detail(
    p_days INTEGER DEFAULT 1
)
RETURNS TABLE (
    test_suite VARCHAR(100),
    test_name VARCHAR(255),
    error_message TEXT,
    executed_at TIMESTAMPTZ,
    test_details JSONB
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        tel.test_suite,
        tel.test_name,
        tel.error_message,
        tel.executed_at,
        tel.test_details
    FROM test_execution_log tel
    WHERE tel.test_status = 'FAILED'
    AND tel.executed_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
    ORDER BY tel.executed_at DESC;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 테스트 정리 함수
-- =====================================================

-- 전체 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_all_test_data()
RETURNS VOID AS $
BEGIN
    RAISE NOTICE '전체 테스트 데이터 정리 시작...';
    
    -- 각 테스트 스위트의 정리 함수 호출
    BEGIN
        PERFORM cleanup_multitenancy_test_data();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '멀티테넌시 테스트 데이터 정리 중 오류: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM cleanup_business_registration_test_data();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '회원가입 테스트 데이터 정리 중 오류: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM cleanup_load_test_data();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '부하 테스트 데이터 정리 중 오류: %', SQLERRM;
    END;
    
    BEGIN
        PERFORM cleanup_performance_test_data();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '성능 테스트 데이터 정리 중 오류: %', SQLERRM;
    END;
    
    -- 테스트 실행 로그 정리 (30일 이전 데이터)
    DELETE FROM test_execution_log 
    WHERE executed_at < now() - INTERVAL '30 days';
    
    RAISE NOTICE '전체 테스트 데이터 정리 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 인덱스 및 코멘트
-- =====================================================

-- 테스트 실행 로그 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_test_execution_log_executed_at 
ON test_execution_log(executed_at DESC);

CREATE INDEX IF NOT EXISTS idx_test_execution_log_test_suite 
ON test_execution_log(test_suite);

CREATE INDEX IF NOT EXISTS idx_test_execution_log_test_status 
ON test_execution_log(test_status);

-- 코멘트 추가
COMMENT ON TABLE test_execution_log IS '전체 테스트 실행 로그 테이블';
COMMENT ON FUNCTION run_all_qiro_tests(BOOLEAN, INTEGER) IS 'QIRO 전체 테스트 스위트 실행';
COMMENT ON FUNCTION get_test_execution_history(INTEGER) IS '테스트 실행 히스토리 조회';
COMMENT ON FUNCTION get_failed_tests_detail(INTEGER) IS '실패한 테스트 상세 정보 조회';
COMMENT ON FUNCTION cleanup_all_test_data() IS '전체 테스트 데이터 정리';

-- =====================================================
-- 6. 사용법 안내
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'QIRO 전체 테스트 시스템이 준비되었습니다.';
    RAISE NOTICE '====================================================';
    RAISE NOTICE '';
    RAISE NOTICE '기본 사용법:';
    RAISE NOTICE '1. 전체 테스트 실행 (성능 데이터 제외):';
    RAISE NOTICE '   SELECT * FROM run_all_qiro_tests();';
    RAISE NOTICE '';
    RAISE NOTICE '2. 전체 테스트 실행 (성능 데이터 포함):';
    RAISE NOTICE '   SELECT * FROM run_all_qiro_tests(true, 500);';
    RAISE NOTICE '';
    RAISE NOTICE '3. 테스트 히스토리 조회:';
    RAISE NOTICE '   SELECT * FROM get_test_execution_history(7);';
    RAISE NOTICE '';
    RAISE NOTICE '4. 실패한 테스트 상세 조회:';
    RAISE NOTICE '   SELECT * FROM get_failed_tests_detail(1);';
    RAISE NOTICE '';
    RAISE NOTICE '5. 테스트 데이터 정리:';
    RAISE NOTICE '   SELECT cleanup_all_test_data();';
    RAISE NOTICE '';
    RAISE NOTICE '개별 테스트 실행:';
    RAISE NOTICE '- 멀티테넌시: \\i database/test_data/multitenancy_isolation_test.sql';
    RAISE NOTICE '- 회원가입: \\i database/test_data/business_registration_integration_test.sql';
    RAISE NOTICE '- 성능/부하: \\i database/test_data/multitenancy_performance_load_test.sql';
    RAISE NOTICE '';
    RAISE NOTICE '====================================================';
END
$;