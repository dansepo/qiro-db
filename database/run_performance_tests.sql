-- =====================================================
-- 성능 테스트 통합 실행 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 모든 성능 테스트를 순차적으로 실행
-- =====================================================

\set ECHO all
\timing on

\echo '====================================================='
\echo 'QIRO 건물 관리 데이터베이스 성능 테스트 시작'
\echo '시작 시간:' `date`
\echo '====================================================='

-- 1. 성능 테스트용 대용량 데이터 생성
\echo ''
\echo '1단계: 성능 테스트용 대용량 데이터 생성 중...'
\echo '예상 소요 시간: 5-10분'
\echo '-----------------------------------------------------'
\i database/performance/03_performance_test_data_generation.sql

-- 2. 성능 최적화 인덱스 생성
\echo ''
\echo '2단계: 성능 최적화 인덱스 생성 중...'
\echo '예상 소요 시간: 2-5분'
\echo '-----------------------------------------------------'
\i database/performance/01_index_design_optimization.sql

-- 3. 파티셔닝 및 아카이빙 전략 설정
\echo ''
\echo '3단계: 파티셔닝 및 아카이빙 전략 설정 중...'
\echo '예상 소요 시간: 1-2분'
\echo '-----------------------------------------------------'
\i database/performance/02_partitioning_archiving_strategy.sql

-- 4. 성능 테스트 쿼리 실행
\echo ''
\echo '4단계: 성능 테스트 쿼리 실행 중...'
\echo '예상 소요 시간: 3-5분'
\echo '-----------------------------------------------------'
\i database/performance/performance_test_queries.sql

-- 5. 성능 테스트 실행 및 결과 분석
\echo ''
\echo '5단계: 성능 테스트 실행 및 결과 분석 중...'
\echo '예상 소요 시간: 2-3분'
\echo '-----------------------------------------------------'
\i database/performance/performance_test_execution.sql

-- 6. 최종 성능 테스트 결과 요약
\echo ''
\echo '====================================================='
\echo '최종 성능 테스트 결과 요약'
\echo '====================================================='

-- 데이터베이스 크기 정보
\echo ''
\echo '데이터베이스 크기 정보:'
\echo '-----------------------------------------------------'
SELECT 
    'DATABASE_SIZE' as metric,
    pg_size_pretty(pg_database_size(current_database())) as value,
    '전체 데이터베이스 크기' as description
UNION ALL
SELECT 
    'LARGEST_TABLES' as metric,
    string_agg(tablename || ': ' || pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)), ', ' ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC) as value,
    '상위 5개 테이블 크기' as description
FROM (
    SELECT schemaname, tablename
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
    LIMIT 5
) t;

-- 성능 테스트 통계
\echo ''
\echo '성능 테스트 통계:'
\echo '-----------------------------------------------------'
SELECT 
    COUNT(*) as total_tests,
    COUNT(CASE WHEN performance_grade IN ('A', 'B') THEN 1 END) as passed_tests,
    COUNT(CASE WHEN performance_grade IN ('D', 'F') THEN 1 END) as failed_tests,
    ROUND(COUNT(CASE WHEN performance_grade IN ('A', 'B') THEN 1 END) * 100.0 / COUNT(*), 2) as pass_rate_pct,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time_ms,
    ROUND(AVG(hit_ratio), 2) as avg_cache_hit_ratio_pct
FROM performance_test_results;

-- NFR 요구사항 준수 여부 체크
\echo ''
\echo 'NFR 요구사항 준수 여부:'
\echo '-----------------------------------------------------'
WITH nfr_check AS (
    SELECT 
        'NFR-PF-001' as requirement,
        '주요 페이지 로딩 시간 3초 이내' as description,
        CASE 
            WHEN AVG(CASE WHEN test_category = 'BASIC_QUERY' THEN execution_time_ms END) <= 3000 
            THEN 'PASS' ELSE 'FAIL' 
        END as status,
        ROUND(AVG(CASE WHEN test_category = 'BASIC_QUERY' THEN execution_time_ms END), 2) as actual_ms
    FROM performance_test_results
    
    UNION ALL
    
    SELECT 
        'NFR-PF-002' as requirement,
        '데이터 조회 결과 2초 이내 표시' as description,
        CASE 
            WHEN AVG(CASE WHEN test_name LIKE '%조회%' THEN execution_time_ms END) <= 2000 
            THEN 'PASS' ELSE 'FAIL' 
        END as status,
        ROUND(AVG(CASE WHEN test_name LIKE '%조회%' THEN execution_time_ms END), 2) as actual_ms
    FROM performance_test_results
    
    UNION ALL
    
    SELECT 
        'NFR-PF-003' as requirement,
        '관리비 자동 계산 500세대 기준 10초 이내' as description,
        CASE 
            WHEN AVG(CASE WHEN test_name LIKE '%관리비%' THEN execution_time_ms END) <= 10000 
            THEN 'PASS' ELSE 'FAIL' 
        END as status,
        ROUND(AVG(CASE WHEN test_name LIKE '%관리비%' THEN execution_time_ms END), 2) as actual_ms
    FROM performance_test_results
    
    UNION ALL
    
    SELECT 
        'NFR-PF-004' as requirement,
        '고지서 일괄 생성 1000건 기준 30초 이내' as description,
        CASE 
            WHEN AVG(CASE WHEN test_name LIKE '%미납%' OR test_name LIKE '%고지서%' THEN execution_time_ms END) <= 30000 
            THEN 'PASS' ELSE 'FAIL' 
        END as status,
        ROUND(AVG(CASE WHEN test_name LIKE '%미납%' OR test_name LIKE '%고지서%' THEN execution_time_ms END), 2) as actual_ms
    FROM performance_test_results
)
SELECT 
    requirement,
    description,
    status,
    actual_ms || 'ms' as actual_performance,
    CASE 
        WHEN status = 'PASS' THEN '✓ 요구사항 충족'
        ELSE '✗ 성능 개선 필요'
    END as result
FROM nfr_check;

-- 최종 권장사항
\echo ''
\echo '최종 권장사항:'
\echo '-----------------------------------------------------'
SELECT 
    CASE priority
        WHEN 1 THEN '🔴 긴급'
        WHEN 2 THEN '🟡 중요'
        WHEN 3 THEN '🟢 일반'
        ELSE '🔵 참고'
    END as priority_level,
    category,
    issue,
    recommendation
FROM generate_optimization_recommendations()
ORDER BY priority, estimated_impact DESC
LIMIT 10;

-- 성능 테스트 완료 메시지
\echo ''
\echo '====================================================='
\echo '성능 테스트 완료'
\echo '완료 시간:' `date`
\echo '====================================================='
\echo ''
\echo '📊 테스트 결과:'
\echo '   - 성능 테스트 데이터: 50개 건물, 10,000세대'
\echo '   - 24개월 관리비 데이터: 약 2,400,000건'
\echo '   - 검침 데이터: 약 3,600,000건'
\echo '   - 고지서 데이터: 약 1,200,000건'
\echo ''
\echo '🔧 최적화 적용:'
\echo '   - 성능 최적화 인덱스: 40+ 개'
\echo '   - 파티셔닝 전략: 시간 기반 분할'
\echo '   - 아카이빙 전략: 3년 이상 데이터'
\echo ''
\echo '📈 추가 모니터링:'
\echo '   - SELECT * FROM v_performance_test_summary;'
\echo '   - SELECT * FROM v_performance_issues;'
\echo '   - SELECT generate_performance_report();'
\echo '   - SELECT * FROM performance_health_check();'
\echo ''
\echo '🔄 정기 유지보수:'
\echo '   - SELECT scheduled_maintenance();  -- 월 1회 실행 권장'
\echo '   - SELECT archive_old_data(3);      -- 분기 1회 실행 권장'
\echo '   - SELECT cleanup_old_partitions(7); -- 연 1회 실행 권장'
\echo '====================================================='