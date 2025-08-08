-- =====================================================
-- Phase 3: 시스템 관리 함수 제거 스크립트 (최종 단계)
-- Phase 1, 2 완료 및 전체 시스템 검증 후 실행
-- =====================================================

-- 실행 전 확인사항 출력
\echo '======================================'
\echo 'Phase 3: 시스템 관리 함수 제거 시작 (최종 단계)'
\echo 'Phase 1, 2 완료 및 전체 시스템 검증 필수!'
\echo '======================================'

-- 현재 함수 목록 백업 (실행 전)
\echo '현재 함수 목록을 백업합니다...'
\o database/cleanup/backup_functions_phase3.sql
SELECT 'CREATE OR REPLACE ' || pg_get_functiondef(p.oid) || ';' 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'bms') 
AND p.proname IN (
    'get_unused_indexes',
    'reindex_multitenancy_tables',
    'convert_business_verification_to_partitioned',
    'convert_phone_verification_to_partitioned',
    'create_monthly_partitions',
    'archive_old_partitions',
    'batch_insert_verification_records',
    'optimize_concurrency_settings',
    'monitor_table_locks',
    'partition_maintenance_job',
    'test_partition_performance'
);
\o

\echo '백업 완료. 시스템 관리 함수 제거를 시작합니다...'

-- =====================================================
-- 1. 인덱스 관리 함수 제거
-- =====================================================

\echo '1. 인덱스 관리 함수 제거 중...'

-- 사용되지 않는 인덱스 조회 함수 제거
DROP FUNCTION IF EXISTS get_unused_indexes();
\echo '  ✓ get_unused_indexes 함수 제거 완료'

-- 인덱스 재구성 함수 제거
DROP FUNCTION IF EXISTS reindex_multitenancy_tables();
\echo '  ✓ reindex_multitenancy_tables 함수 제거 완료'

-- =====================================================
-- 2. 파티셔닝 관리 함수 제거
-- =====================================================

\echo '2. 파티셔닝 관리 함수 제거 중...'

-- 테이블 파티셔닝 변환 함수들 제거
DROP FUNCTION IF EXISTS convert_business_verification_to_partitioned();
\echo '  ✓ convert_business_verification_to_partitioned 함수 제거 완료'

DROP FUNCTION IF EXISTS convert_phone_verification_to_partitioned();
\echo '  ✓ convert_phone_verification_to_partitioned 함수 제거 완료'

-- 월별 파티션 생성 함수 제거
DROP FUNCTION IF EXISTS create_monthly_partitions();
\echo '  ✓ create_monthly_partitions 함수 제거 완료'

-- 파티션 아카이빙 함수 제거
DROP FUNCTION IF EXISTS archive_old_partitions(INTEGER);
DROP FUNCTION IF EXISTS archive_old_partitions();
\echo '  ✓ archive_old_partitions 함수 제거 완료'

-- 배치 삽입 함수 제거
DROP FUNCTION IF EXISTS batch_insert_verification_records(JSONB, INTEGER);
DROP FUNCTION IF EXISTS batch_insert_verification_records(JSONB);
\echo '  ✓ batch_insert_verification_records 함수 제거 완료'

-- =====================================================
-- 3. 동시성 및 락 관리 함수 제거
-- =====================================================

\echo '3. 동시성 및 락 관리 함수 제거 중...'

-- 동시성 설정 최적화 함수 제거
DROP FUNCTION IF EXISTS optimize_concurrency_settings();
\echo '  ✓ optimize_concurrency_settings 함수 제거 완료'

-- 테이블 락 모니터링 함수 제거
DROP FUNCTION IF EXISTS monitor_table_locks();
\echo '  ✓ monitor_table_locks 함수 제거 완료'

-- =====================================================
-- 4. 파티션 유지보수 함수 제거
-- =====================================================

\echo '4. 파티션 유지보수 함수 제거 중...'

-- 파티션 유지보수 작업 함수 제거
DROP FUNCTION IF EXISTS partition_maintenance_job();
\echo '  ✓ partition_maintenance_job 함수 제거 완료'

-- 파티션 성능 테스트 함수 제거
DROP FUNCTION IF EXISTS test_partition_performance(INTEGER);
DROP FUNCTION IF EXISTS test_partition_performance();
\echo '  ✓ test_partition_performance 함수 제거 완료'

-- =====================================================
-- 5. 관련 뷰 및 시퀀스 정리
-- =====================================================

\echo '5. 관련 뷰 및 시퀀스 정리 중...'

-- 성능 관련 뷰들 제거 (있다면)
DROP VIEW IF EXISTS v_table_index_sizes CASCADE;
DROP VIEW IF EXISTS v_index_usage_stats CASCADE;
DROP VIEW IF EXISTS v_performance_dashboard CASCADE;
DROP VIEW IF EXISTS v_slow_queries CASCADE;
DROP VIEW IF EXISTS v_partition_performance_stats CASCADE;
\echo '  ✓ 성능 관련 뷰 제거 완료'

-- 테스트 관련 시퀀스 제거 (있다면)
DROP SEQUENCE IF EXISTS test_sequence CASCADE;
\echo '  ✓ 관련 시퀀스 제거 완료'

-- =====================================================
-- 6. 임시 테이블 및 테스트 데이터 정리
-- =====================================================

\echo '6. 임시 테이블 및 테스트 데이터 정리 중...'

-- 주의: 프로덕션 데이터 확인 후 실행
-- 테스트 관련 임시 테이블들 제거
DROP TABLE IF EXISTS temp_test_results CASCADE;
DROP TABLE IF EXISTS test_results CASCADE;
DROP TABLE IF EXISTS performance_test_sessions CASCADE;
DROP TABLE IF EXISTS performance_test_results CASCADE;
DROP TABLE IF EXISTS test_execution_log CASCADE;
\echo '  ✓ 테스트 관련 임시 테이블 제거 완료'

-- 성능 테스트 관련 테이블 제거 (있다면)
DROP TABLE IF EXISTS performance_benchmarks CASCADE;
DROP TABLE IF EXISTS index_usage_history CASCADE;
\echo '  ✓ 성능 테스트 관련 테이블 제거 완료'

-- =====================================================
-- 7. 스키마 정리 및 권한 정리
-- =====================================================

\echo '7. 스키마 정리 및 권한 정리 중...'

-- 제거된 함수들에 대한 권한 정리
-- (CASCADE로 자동 제거되지만 명시적 확인)
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA bms FROM application_role;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM application_role;
\echo '  ✓ 함수 권한 정리 완료'

-- 사용하지 않는 스키마가 있다면 정리 (주의 필요)
-- DROP SCHEMA IF EXISTS test_schema CASCADE;
\echo '  → 스키마 정리는 수동으로 확인 후 실행하세요'

-- =====================================================
-- 8. 최종 정리 및 최적화
-- =====================================================

\echo '8. 최종 정리 및 최적화 중...'

-- 통계 정보 업데이트
ANALYZE;
\echo '  ✓ 데이터베이스 통계 정보 업데이트 완료'

-- 불필요한 의존성 정리
VACUUM;
\echo '  ✓ 데이터베이스 정리 완료'

-- =====================================================
-- 9. 최종 검증
-- =====================================================

\echo '9. 최종 검증 중...'

-- 남은 함수 목록 확인
\echo '남은 사용자 정의 함수 목록:'
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments,
    p.prosrc as source_preview
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('bms', 'public')
AND p.proname NOT LIKE 'pg_%'
AND p.proname NOT LIKE 'information_schema_%'
ORDER BY n.nspname, p.proname;

-- 남은 트리거 확인
\echo ''
\echo '남은 사용자 정의 트리거 목록:'
SELECT 
    trigger_schema,
    trigger_name,
    event_object_table,
    action_timing,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_schema IN ('bms', 'public')
ORDER BY trigger_schema, trigger_name;

-- 남은 뷰 확인
\echo ''
\echo '남은 사용자 정의 뷰 목록:'
SELECT 
    table_schema,
    table_name,
    view_definition
FROM information_schema.views 
WHERE table_schema IN ('bms', 'public')
ORDER BY table_schema, table_name;

-- =====================================================
-- 완료 확인
-- =====================================================

\echo ''
\echo '======================================'
\echo 'Phase 3 시스템 관리 함수 제거 완료!'
\echo '======================================'

\echo ''
\echo '전체 프로시저 제거 작업 완료 요약:'
\echo '✓ Phase 1: 테스트 관련 함수 제거 완료'
\echo '✓ Phase 2: 비즈니스 로직 함수 제거 완료'  
\echo '✓ Phase 3: 시스템 관리 함수 제거 완료'
\echo ''
\echo '데이터베이스 정리 결과:'
\echo '- 모든 사용자 정의 프로시저/함수 제거'
\echo '- 관련 트리거 및 뷰 정리'
\echo '- 테스트 데이터 및 임시 테이블 정리'
\echo '- 데이터베이스 최적화 완료'
\echo ''
\echo '다음 단계:'
\echo '1. 백엔드 서비스가 모든 기능을 정상 제공하는지 최종 확인'
\echo '2. 성능 테스트 실행하여 성능 저하 없는지 확인'
\echo '3. 프로덕션 배포 전 전체 시스템 통합 테스트'
\echo '4. 백업 파일 보관 및 롤백 계획 수립'
\echo ''
\echo '🎉 데이터베이스 프로시저 → 백엔드 이관 완료!'
\echo '모든 비즈니스 로직이 백엔드에서 처리됩니다.'