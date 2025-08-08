-- =====================================================
-- Phase 1: 테스트 관련 함수 삭제 스크립트
-- 백엔드 서비스 이관 완료 후 실행
-- 실행 전 반드시 백업 수행 필요
-- =====================================================

-- 실행 전 확인사항 체크
DO $check$
BEGIN
    -- 백엔드 서비스 구현 완료 확인
    RAISE NOTICE '=== Phase 1 테스트 함수 삭제 시작 ===';
    RAISE NOTICE '실행 시간: %', NOW();
    RAISE NOTICE '대상: 테스트 관련 함수 및 성능 모니터링 함수';
    RAISE NOTICE '';
    
    -- 삭제 대상 함수 개수 확인
    RAISE NOTICE '삭제 예정 함수 개수: %', (
        SELECT COUNT(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'bms' 
        AND routine_name IN (
            'test_partition_performance',
            'test_company_data_isolation', 
            'test_user_permissions',
            'run_multitenancy_isolation_tests',
            'generate_test_companies',
            'cleanup_multitenancy_test_data',
            'get_partition_stats',
            'get_validation_summary',
            'cleanup_audit_logs',
            'cleanup_expired_sessions',
            'archive_old_partitions',
            'annual_archive_maintenance',
            'create_monthly_partitions'
        )
    );
END $check$;

-- =====================================================
-- 1. 성능 테스트 함수 삭제
-- =====================================================

-- 1.1 파티션 성능 테스트 함수
DROP FUNCTION IF EXISTS bms.test_partition_performance() CASCADE;
RAISE NOTICE '✓ test_partition_performance() 함수 삭제 완료';

-- 1.2 데이터 격리 테스트 함수
DROP FUNCTION IF EXISTS bms.test_company_data_isolation() CASCADE;
RAISE NOTICE '✓ test_company_data_isolation() 함수 삭제 완료';

-- 1.3 사용자 권한 테스트 함수
DROP FUNCTION IF EXISTS bms.test_user_permissions() CASCADE;
RAISE NOTICE '✓ test_user_permissions() 함수 삭제 완료';

-- 1.4 멀티테넌시 격리 테스트 함수
DROP FUNCTION IF EXISTS bms.run_multitenancy_isolation_tests() CASCADE;
RAISE NOTICE '✓ run_multitenancy_isolation_tests() 함수 삭제 완료';

-- =====================================================
-- 2. 테스트 데이터 생성 함수 삭제
-- =====================================================

-- 2.1 테스트 회사 데이터 생성 함수
DROP FUNCTION IF EXISTS bms.generate_test_companies() CASCADE;
RAISE NOTICE '✓ generate_test_companies() 함수 삭제 완료';

-- =====================================================
-- 3. 시스템 유지보수 및 정리 함수 삭제
-- =====================================================

-- 3.1 테스트 데이터 정리 함수
DROP FUNCTION IF EXISTS bms.cleanup_multitenancy_test_data() CASCADE;
RAISE NOTICE '✓ cleanup_multitenancy_test_data() 함수 삭제 완료';

-- 3.2 파티션 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_partition_stats() CASCADE;
RAISE NOTICE '✓ get_partition_stats() 함수 삭제 완료';

-- 3.3 검증 요약 조회 함수
DROP FUNCTION IF EXISTS bms.get_validation_summary() CASCADE;
RAISE NOTICE '✓ get_validation_summary() 함수 삭제 완료';

-- 3.4 감사 로그 정리 함수
DROP FUNCTION IF EXISTS bms.cleanup_audit_logs() CASCADE;
RAISE NOTICE '✓ cleanup_audit_logs() 함수 삭제 완료';

-- 3.5 만료된 세션 정리 함수
DROP FUNCTION IF EXISTS bms.cleanup_expired_sessions() CASCADE;
RAISE NOTICE '✓ cleanup_expired_sessions() 함수 삭제 완료';

-- 3.6 오래된 파티션 아카이브 함수
DROP FUNCTION IF EXISTS bms.archive_old_partitions() CASCADE;
RAISE NOTICE '✓ archive_old_partitions() 함수 삭제 완료';

-- 3.7 연간 아카이브 유지보수 함수
DROP FUNCTION IF EXISTS bms.annual_archive_maintenance() CASCADE;
RAISE NOTICE '✓ annual_archive_maintenance() 함수 삭제 완료';

-- 3.8 월별 파티션 생성 함수
DROP FUNCTION IF EXISTS bms.create_monthly_partitions() CASCADE;
RAISE NOTICE '✓ create_monthly_partitions() 함수 삭제 완료';

-- =====================================================
-- 4. 통계 및 모니터링 함수 삭제
-- =====================================================

-- 4.1 감사 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_audit_statistics() CASCADE;
RAISE NOTICE '✓ get_audit_statistics() 함수 삭제 완료';

-- 4.2 완료 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_completion_statistics() CASCADE;
RAISE NOTICE '✓ get_completion_statistics() 함수 삭제 완료';

-- 4.3 고장 신고 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_fault_report_statistics() CASCADE;
RAISE NOTICE '✓ get_fault_report_statistics() 함수 삭제 완료';

-- 4.4 작업 지시서 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_work_order_statistics() CASCADE;
RAISE NOTICE '✓ get_work_order_statistics() 함수 삭제 완료';

-- 4.5 자재 통계 조회 함수
DROP FUNCTION IF EXISTS bms.get_material_statistics() CASCADE;
RAISE NOTICE '✓ get_material_statistics() 함수 삭제 완료';

-- =====================================================
-- 5. 삭제 완료 확인 및 정리
-- =====================================================

DO $cleanup$
DECLARE
    remaining_count INTEGER;
BEGIN
    -- 남은 테스트 관련 함수 확인
    SELECT COUNT(*) INTO remaining_count
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND (
        routine_name LIKE '%test%' OR 
        routine_name LIKE '%cleanup%' OR
        routine_name LIKE '%partition%' OR
        routine_name LIKE '%statistics%'
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '=== Phase 1 삭제 완료 ===';
    RAISE NOTICE '삭제 완료 시간: %', NOW();
    RAISE NOTICE '남은 테스트 관련 함수: %개', remaining_count;
    
    IF remaining_count > 0 THEN
        RAISE NOTICE '주의: 일부 테스트 관련 함수가 남아있습니다. 수동 확인이 필요합니다.';
    ELSE
        RAISE NOTICE '✓ 모든 테스트 관련 함수가 성공적으로 삭제되었습니다.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계: Phase 2 비즈니스 로직 함수 삭제';
    RAISE NOTICE '실행 파일: phase2_business_functions_cleanup.sql';
END $cleanup$;

-- =====================================================
-- 6. 롤백 스크립트 정보
-- =====================================================

/*
롤백이 필요한 경우 다음 단계를 수행하세요:

1. 백업에서 함수들을 복원
2. 백엔드 서비스에서 해당 기능 비활성화
3. 데이터베이스 함수 호출로 다시 전환

주요 복원 대상 함수:
- bms.test_partition_performance()
- bms.generate_test_companies()
- bms.cleanup_audit_logs()
- bms.get_audit_statistics()
- 기타 모든 삭제된 함수들

복원 후 확인사항:
- 기존 애플리케이션 정상 동작 확인
- 성능 테스트 실행
- 로그 모니터링
*/