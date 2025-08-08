-- =====================================================
-- Phase 1: 테스트 관련 함수 제거 스크립트
-- 실행 전 백업 필수!
-- =====================================================

-- 실행 전 확인사항 출력
\echo '======================================'
\echo 'Phase 1: 테스트 관련 함수 제거 시작'
\echo '백엔드 서비스 구현 완료 확인 필수!'
\echo '======================================'

-- 현재 함수 목록 백업 (실행 전)
\echo '현재 함수 목록을 백업합니다...'
\o database/cleanup/backup_functions_phase1.sql
SELECT 'CREATE OR REPLACE ' || pg_get_functiondef(p.oid) || ';' 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'bms') 
AND p.proname IN (
    'run_integrity_test',
    'run_multitenancy_benchmark', 
    'cleanup_test_data',
    'start_performance_test_session',
    'execute_performance_test',
    'complete_performance_test_session',
    'run_comprehensive_performance_test',
    'analyze_performance_test_results',
    'identify_slow_tests',
    'analyze_performance_trends',
    'generate_performance_report',
    'run_daily_performance_test',
    'run_qiro_integration_tests',
    'summarize_test_results',
    'run_all_qiro_tests',
    'get_test_execution_history',
    'get_failed_tests_detail',
    'cleanup_all_test_data',
    'generate_performance_test_data'
);
\o

\echo '백업 완료. 함수 제거를 시작합니다...'

-- =====================================================
-- 1. 데이터 무결성 테스트 함수 제거
-- =====================================================

\echo '1. 데이터 무결성 테스트 함수 제거 중...'

-- run_integrity_test 함수 제거
DROP FUNCTION IF EXISTS run_integrity_test(VARCHAR, VARCHAR, TEXT, TEXT);
DROP FUNCTION IF EXISTS run_integrity_test(VARCHAR, VARCHAR, TEXT);
\echo '  ✓ run_integrity_test 함수 제거 완료'

-- =====================================================
-- 2. 성능 테스트 함수 제거
-- =====================================================

\echo '2. 성능 테스트 함수 제거 중...'

-- 성능 벤치마크 함수 제거
DROP FUNCTION IF EXISTS run_multitenancy_benchmark();
\echo '  ✓ run_multitenancy_benchmark 함수 제거 완료'

-- 테스트 데이터 정리 함수 제거
DROP FUNCTION IF EXISTS cleanup_test_data();
\echo '  ✓ cleanup_test_data 함수 제거 완료'

-- =====================================================
-- 3. 성능 테스트 실행 함수 제거
-- =====================================================

\echo '3. 성능 테스트 실행 함수 제거 중...'

-- 성능 테스트 세션 관리 함수들 제거
DROP FUNCTION IF EXISTS start_performance_test_session(VARCHAR, TEXT);
\echo '  ✓ start_performance_test_session 함수 제거 완료'

DROP FUNCTION IF EXISTS execute_performance_test(UUID, VARCHAR, TEXT, JSONB);
\echo '  ✓ execute_performance_test 함수 제거 완료'

DROP FUNCTION IF EXISTS complete_performance_test_session(UUID);
\echo '  ✓ complete_performance_test_session 함수 제거 완료'

-- 종합 성능 테스트 함수 제거
DROP FUNCTION IF EXISTS run_comprehensive_performance_test();
\echo '  ✓ run_comprehensive_performance_test 함수 제거 완료'

-- 성능 분석 함수들 제거
DROP FUNCTION IF EXISTS analyze_performance_test_results(UUID);
DROP FUNCTION IF EXISTS analyze_performance_test_results();
\echo '  ✓ analyze_performance_test_results 함수 제거 완료'

DROP FUNCTION IF EXISTS identify_slow_tests(INTEGER, UUID);
DROP FUNCTION IF EXISTS identify_slow_tests(INTEGER);
DROP FUNCTION IF EXISTS identify_slow_tests();
\echo '  ✓ identify_slow_tests 함수 제거 완료'

DROP FUNCTION IF EXISTS analyze_performance_trends(INTEGER);
\echo '  ✓ analyze_performance_trends 함수 제거 완료'

DROP FUNCTION IF EXISTS generate_performance_report(UUID);
\echo '  ✓ generate_performance_report 함수 제거 완료'

DROP FUNCTION IF EXISTS run_daily_performance_test();
\echo '  ✓ run_daily_performance_test 함수 제거 완료'

-- =====================================================
-- 4. 통합 테스트 함수 제거
-- =====================================================

\echo '4. 통합 테스트 함수 제거 중...'

-- 통합 테스트 실행 함수 제거
DROP FUNCTION IF EXISTS run_qiro_integration_tests();
\echo '  ✓ run_qiro_integration_tests 함수 제거 완료'

-- 테스트 결과 요약 함수 제거
DROP FUNCTION IF EXISTS summarize_test_results();
\echo '  ✓ summarize_test_results 함수 제거 완료'

-- =====================================================
-- 5. 전체 테스트 스위트 함수 제거
-- =====================================================

\echo '5. 전체 테스트 스위트 함수 제거 중...'

-- 전체 테스트 실행 함수 제거
DROP FUNCTION IF EXISTS run_all_qiro_tests(BOOLEAN, INTEGER);
DROP FUNCTION IF EXISTS run_all_qiro_tests(BOOLEAN);
DROP FUNCTION IF EXISTS run_all_qiro_tests();
\echo '  ✓ run_all_qiro_tests 함수 제거 완료'

-- 테스트 히스토리 조회 함수 제거
DROP FUNCTION IF EXISTS get_test_execution_history(INTEGER);
DROP FUNCTION IF EXISTS get_test_execution_history();
\echo '  ✓ get_test_execution_history 함수 제거 완료'

-- 실패 테스트 상세 조회 함수 제거
DROP FUNCTION IF EXISTS get_failed_tests_detail(INTEGER);
DROP FUNCTION IF EXISTS get_failed_tests_detail();
\echo '  ✓ get_failed_tests_detail 함수 제거 완료'

-- 전체 테스트 데이터 정리 함수 제거
DROP FUNCTION IF EXISTS cleanup_all_test_data();
\echo '  ✓ cleanup_all_test_data 함수 제거 완료'

-- =====================================================
-- 6. 테스트 데이터 생성 함수 제거
-- =====================================================

\echo '6. 테스트 데이터 생성 함수 제거 중...'

-- 성능 테스트 데이터 생성 함수 제거
DROP FUNCTION IF EXISTS generate_performance_test_data();
\echo '  ✓ generate_performance_test_data 함수 제거 완료'

-- =====================================================
-- 7. 관련 테이블 정리 (선택사항)
-- =====================================================

\echo '7. 관련 테스트 테이블 정리 여부 확인...'

-- 테스트 관련 임시 테이블들이 있다면 정리
-- 주의: 프로덕션 데이터가 있는지 반드시 확인 후 실행
-- DROP TABLE IF EXISTS test_results;
-- DROP TABLE IF EXISTS performance_test_sessions;
-- DROP TABLE IF EXISTS performance_test_results;

\echo '  → 테스트 테이블 정리는 수동으로 확인 후 실행하세요'

-- =====================================================
-- 완료 확인
-- =====================================================

\echo ''
\echo '======================================'
\echo 'Phase 1 함수 제거 완료!'
\echo '======================================'

-- 제거된 함수 확인
\echo '제거 확인: 남은 테스트 관련 함수 목록'
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'bms') 
AND (
    p.proname LIKE '%test%' OR 
    p.proname LIKE '%benchmark%' OR
    p.proname LIKE '%performance%'
)
ORDER BY n.nspname, p.proname;

\echo ''
\echo '다음 단계:'
\echo '1. 백엔드 테스트 서비스가 정상 동작하는지 확인'
\echo '2. 기존 테스트 기능이 백엔드에서 동일하게 작동하는지 검증'
\echo '3. 문제없으면 Phase 2 실행 준비'
\echo ''
\echo 'Phase 1 완료 - 테스트 관련 함수 제거 성공!'