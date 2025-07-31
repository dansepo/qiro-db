-- =====================================================
-- QIRO 성능 최적화 통합 실행 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 환경 성능 최적화를 위한 통합 실행 스크립트
-- =====================================================

\echo '======================================'
\echo 'QIRO 성능 최적화 시작'
\echo '======================================'

-- 실행 시작 시간 기록
\set start_time `date`
\echo '시작 시간:' :start_time

-- =====================================================
-- 1. 멀티테넌시 환경 최적화 인덱스 생성
-- =====================================================

\echo ''
\echo '1. 멀티테넌시 환경 최적화 인덱스 생성 중...'
\i database/performance/01_multitenancy_performance_indexes.sql

-- =====================================================
-- 2. 파티셔닝 및 아카이빙 전략 적용
-- =====================================================

\echo ''
\echo '2. 파티셔닝 및 아카이빙 전략 설정 중...'
\i database/performance/02_partitioning_archiving_strategy.sql

-- =====================================================
-- 3. 성능 테스트 쿼리 및 모니터링 시스템 설정
-- =====================================================

\echo ''
\echo '3. 성능 테스트 쿼리 시스템 설정 중...'
\i database/performance/performance_test_queries.sql

-- =====================================================
-- 4. 성능 테스트 실행 시스템 설정
-- =====================================================

\echo ''
\echo '4. 성능 테스트 실행 시스템 설정 중...'
\i database/performance/performance_test_execution.sql

-- =====================================================
-- 5. 성능 최적화 검증
-- =====================================================

\echo ''
\echo '5. 성능 최적화 검증 중...'

-- 인덱스 생성 확인
\echo '생성된 인덱스 수:'
SELECT COUNT(*) as index_count 
FROM pg_indexes 
WHERE schemaname = current_schema() 
AND indexname LIKE 'idx_%';

-- 테이블 크기 확인
\echo ''
\echo '주요 테이블 크기:'
SELECT * FROM v_table_index_sizes 
WHERE tablename IN ('companies', 'users', 'building_groups', 'roles')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 인덱스 사용량 확인
\echo ''
\echo '인덱스 사용량 통계:'
SELECT * FROM v_index_usage_stats 
WHERE tablename IN ('companies', 'users', 'building_groups', 'roles')
ORDER BY idx_scan DESC
LIMIT 10;

-- =====================================================
-- 6. 성능 테스트 실행 (선택사항)
-- =====================================================

\echo ''
\echo '6. 기본 성능 테스트 실행 중...'

-- 간단한 성능 벤치마크 실행
SELECT * FROM run_multitenancy_benchmark();

-- 성능 대시보드 확인
\echo ''
\echo '성능 대시보드:'
SELECT * FROM v_performance_dashboard;

-- =====================================================
-- 7. 파티셔닝 적용 (선택사항 - 주의 필요)
-- =====================================================

\echo ''
\echo '7. 파티셔닝 적용 옵션 안내'
\echo '주의: 파티셔닝은 기존 데이터에 영향을 줄 수 있습니다.'
\echo '프로덕션 환경에서는 백업 후 실행하세요.'
\echo ''
\echo '파티셔닝 적용 명령어:'
\echo '  - Business Verification Records: SELECT convert_business_verification_to_partitioned();'
\echo '  - Phone Verification Tokens: SELECT convert_phone_verification_to_partitioned();'

-- =====================================================
-- 8. 유지보수 작업 스케줄링 안내
-- =====================================================

\echo ''
\echo '8. 유지보수 작업 스케줄링 안내'
\echo '다음 함수들을 정기적으로 실행하도록 스케줄링하세요:'
\echo ''
\echo '월별 실행:'
\echo '  - SELECT partition_maintenance_job();  -- 파티션 유지보수'
\echo '  - SELECT create_monthly_partitions();  -- 새 파티션 생성'
\echo ''
\echo '주별 실행:'
\echo '  - SELECT reindex_multitenancy_tables();  -- 인덱스 재구성'
\echo '  - SELECT auto_unlock_expired_accounts();  -- 만료된 계정 잠금 해제'
\echo ''
\echo '일별 실행:'
\echo '  - SELECT run_daily_performance_test();  -- 일일 성능 테스트'
\echo '  - SELECT cleanup_test_data();  -- 테스트 데이터 정리'

-- =====================================================
-- 9. 성능 모니터링 설정 안내
-- =====================================================

\echo ''
\echo '9. 성능 모니터링 설정 안내'
\echo '다음 확장 기능을 활성화하여 더 자세한 성능 모니터링이 가능합니다:'
\echo ''
\echo 'pg_stat_statements 확장 (느린 쿼리 분석):'
\echo '  CREATE EXTENSION IF NOT EXISTS pg_stat_statements;'
\echo ''
\echo 'pg_buffercache 확장 (버퍼 캐시 분석):'
\echo '  CREATE EXTENSION IF NOT EXISTS pg_buffercache;'
\echo ''
\echo '성능 모니터링 뷰:'
\echo '  - SELECT * FROM v_slow_queries;  -- 느린 쿼리 확인'
\echo '  - SELECT * FROM v_partition_performance_stats;  -- 파티션 성능 통계'
\echo '  - SELECT * FROM monitor_table_locks();  -- 테이블 락 모니터링'

-- =====================================================
-- 10. 최적화 완료 요약
-- =====================================================

\echo ''
\echo '======================================'
\echo 'QIRO 성능 최적화 완료'
\echo '======================================'

-- 완료 시간 기록
\set end_time `date`
\echo '완료 시간:' :end_time

-- 최적화 결과 요약
\echo ''
\echo '적용된 최적화:'
\echo '✓ 멀티테넌시 환경 최적화 인덱스 생성'
\echo '✓ 파티셔닝 전략 및 아카이빙 시스템 구축'
\echo '✓ 성능 테스트 및 모니터링 시스템 구축'
\echo '✓ 동시성 제어 최적화'
\echo '✓ RLS 성능 최적화'
\echo '✓ 대용량 데이터 처리 최적화'

\echo ''
\echo '다음 단계:'
\echo '1. 프로덕션 환경에서 파티셔닝 적용 검토'
\echo '2. 정기 유지보수 작업 스케줄링 설정'
\echo '3. 성능 모니터링 대시보드 구축'
\echo '4. 애플리케이션 레벨 최적화 검토'

\echo ''
\echo '성능 최적화가 완료되었습니다!'

-- =====================================================
-- 11. 성능 최적화 검증 리포트 생성
-- =====================================================

-- 최적화 검증 결과를 파일로 출력 (선택사항)
-- \o performance_optimization_report.txt
-- \echo '======================================'
-- \echo 'QIRO 성능 최적화 검증 리포트'
-- \echo '======================================'
-- \echo '생성일시:' :end_time
-- \echo ''

-- SELECT 'Database Size' as metric, pg_size_pretty(pg_database_size(current_database())) as value
-- UNION ALL
-- SELECT 'Total Tables', COUNT(*)::TEXT FROM pg_tables WHERE schemaname = current_schema()
-- UNION ALL  
-- SELECT 'Total Indexes', COUNT(*)::TEXT FROM pg_indexes WHERE schemaname = current_schema()
-- UNION ALL
-- SELECT 'Multitenancy Indexes', COUNT(*)::TEXT FROM pg_indexes WHERE schemaname = current_schema() AND indexname LIKE 'idx_%company%'
-- UNION ALL
-- SELECT 'Performance Functions', COUNT(*)::TEXT FROM pg_proc WHERE proname LIKE '%performance%';

-- \o

\echo ''
\echo '성능 최적화 스크립트 실행이 완료되었습니다.'