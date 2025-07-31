-- =====================================================
-- QIRO 통합 테스트 실행 스크립트 (수정된 버전)
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-31
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;
SET search_path TO bms;

-- =====================================================
-- 통합 테스트 실행 함수
-- =====================================================

CREATE OR REPLACE FUNCTION run_qiro_integration_tests()
RETURNS TABLE (
    test_category TEXT,
    test_name TEXT,
    test_result TEXT,
    execution_time_ms NUMERIC,
    notes TEXT
) AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    company1_id UUID;
    company2_id UUID;
    test_count INTEGER;
    total_companies INTEGER;
    total_users INTEGER;
BEGIN
    RAISE NOTICE '=== QIRO 통합 테스트 시작 ===';
    
    -- 기본 데이터 상태 확인
    SELECT COUNT(*) INTO total_companies FROM companies;
    SELECT COUNT(*) INTO total_users FROM users;
    
    RAISE NOTICE '현재 데이터 상태: 회사 % 개, 사용자 % 명', total_companies, total_users;
    
    -- 테스트 1: 기본 데이터 구조 검증
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO test_count FROM companies WHERE business_registration_number IN ('1234567890', '9876543210');
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        '데이터 구조'::TEXT,
        '테스트 회사 존재 확인'::TEXT,
        CASE WHEN test_count = 2 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('테스트 회사 %개 발견 (예상: 2개)', test_count)::TEXT;
    
    -- 테스트 2: RLS 정책 동작 확인
    start_time := clock_timestamp();
    
    -- 회사 ID 가져오기
    SELECT company_id INTO company1_id FROM companies WHERE business_registration_number = '1234567890';
    SELECT company_id INTO company2_id FROM companies WHERE business_registration_number = '9876543210';
    
    -- 회사1 컨텍스트 테스트
    PERFORM set_config('app.current_company_id', company1_id::TEXT, false);
    SET ROLE application_role;
    SELECT COUNT(*) INTO test_count FROM companies;
    RESET ROLE;
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        'RLS 정책'::TEXT,
        '회사1 컨텍스트 격리'::TEXT,
        CASE WHEN test_count = 1 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('회사1 컨텍스트에서 %개 회사 조회 (예상: 1개)', test_count)::TEXT;
    
    -- 테스트 3: 회사2 컨텍스트 테스트
    start_time := clock_timestamp();
    
    PERFORM set_config('app.current_company_id', company2_id::TEXT, false);
    SET ROLE application_role;
    SELECT COUNT(*) INTO test_count FROM companies;
    RESET ROLE;
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        'RLS 정책'::TEXT,
        '회사2 컨텍스트 격리'::TEXT,
        CASE WHEN test_count = 1 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('회사2 컨텍스트에서 %개 회사 조회 (예상: 1개)', test_count)::TEXT;
    
    -- 테스트 4: 사용자 데이터 격리 확인
    start_time := clock_timestamp();
    
    PERFORM set_config('app.current_company_id', company1_id::TEXT, false);
    SET ROLE application_role;
    SELECT COUNT(*) INTO test_count FROM users;
    RESET ROLE;
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        'RLS 정책'::TEXT,
        '사용자 데이터 격리'::TEXT,
        CASE WHEN test_count = 1 THEN 'PASS' ELSE 'FAIL' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('회사1 컨텍스트에서 %명 사용자 조회 (예상: 1명)', test_count)::TEXT;
    
    -- 테스트 5: 성능 테스트 (전체 회사 조회)
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO test_count FROM companies;
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        '성능 테스트'::TEXT,
        '전체 회사 조회'::TEXT,
        CASE WHEN EXTRACT(EPOCH FROM (end_time - start_time) * 1000) < 100 THEN 'PASS' ELSE 'WARN' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('%개 회사 조회 완료', test_count)::TEXT;
    
    -- 테스트 6: 복합 조인 쿼리 성능
    start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO test_count
    FROM companies c
    JOIN users u ON c.company_id = u.company_id
    WHERE c.verification_status = 'VERIFIED';
    
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        '성능 테스트'::TEXT,
        '복합 조인 쿼리'::TEXT,
        CASE WHEN EXTRACT(EPOCH FROM (end_time - start_time) * 1000) < 200 THEN 'PASS' ELSE 'WARN' END::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::NUMERIC,
        format('조인 결과 %개 레코드', test_count)::TEXT;
    
    -- 컨텍스트 초기화
    PERFORM set_config('app.current_company_id', '', false);
    
    RAISE NOTICE '=== QIRO 통합 테스트 완료 ===';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 테스트 결과 요약 함수
-- =====================================================

CREATE OR REPLACE FUNCTION summarize_test_results()
RETURNS TABLE (
    summary_category TEXT,
    total_tests INTEGER,
    passed_tests INTEGER,
    failed_tests INTEGER,
    warning_tests INTEGER,
    success_rate NUMERIC(5,2),
    avg_execution_time_ms NUMERIC(10,2)
) AS $$
DECLARE
    total_count INTEGER;
    pass_count INTEGER;
    fail_count INTEGER;
    warn_count INTEGER;
    avg_time NUMERIC;
BEGIN
    -- 임시 테이블에서 결과 집계
    CREATE TEMP TABLE IF NOT EXISTS temp_test_results AS
    SELECT * FROM run_qiro_integration_tests();
    
    -- 전체 통계 계산
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN test_result = 'PASS' THEN 1 END),
        COUNT(CASE WHEN test_result = 'FAIL' THEN 1 END),
        COUNT(CASE WHEN test_result = 'WARN' THEN 1 END),
        AVG(execution_time_ms)
    INTO total_count, pass_count, fail_count, warn_count, avg_time
    FROM temp_test_results;
    
    -- 카테고리별 통계
    FOR rec IN 
        SELECT 
            test_category,
            COUNT(*) as total,
            COUNT(CASE WHEN test_result = 'PASS' THEN 1 END) as passed,
            COUNT(CASE WHEN test_result = 'FAIL' THEN 1 END) as failed,
            COUNT(CASE WHEN test_result = 'WARN' THEN 1 END) as warned,
            AVG(execution_time_ms) as avg_exec_time
        FROM temp_test_results
        GROUP BY test_category
    LOOP
        RETURN QUERY SELECT 
            rec.test_category,
            rec.total,
            rec.passed,
            rec.failed,
            rec.warned,
            ROUND((rec.passed::NUMERIC / rec.total) * 100, 2),
            ROUND(rec.avg_exec_time, 2);
    END LOOP;
    
    -- 전체 요약
    RETURN QUERY SELECT 
        '전체'::TEXT,
        total_count,
        pass_count,
        fail_count,
        warn_count,
        ROUND((pass_count::NUMERIC / total_count) * 100, 2),
        ROUND(avg_time, 2);
    
    -- 임시 테이블 정리
    DROP TABLE IF EXISTS temp_test_results;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 테스트 실행
-- =====================================================

-- 상세 테스트 결과 출력
SELECT 
    test_category as "카테고리",
    test_name as "테스트명",
    test_result as "결과",
    ROUND(execution_time_ms, 2) as "실행시간(ms)",
    notes as "비고"
FROM run_qiro_integration_tests()
ORDER BY test_category, test_name;

-- 테스트 결과 요약
SELECT 
    summary_category as "카테고리",
    total_tests as "총 테스트",
    passed_tests as "성공",
    failed_tests as "실패", 
    warning_tests as "경고",
    success_rate as "성공률(%)",
    avg_execution_time_ms as "평균실행시간(ms)"
FROM summarize_test_results()
ORDER BY 
    CASE summary_category 
        WHEN '전체' THEN 999 
        ELSE 1 
    END,
    summary_category;

-- 정리
DROP FUNCTION IF EXISTS run_qiro_integration_tests();
DROP FUNCTION IF EXISTS summarize_test_results();