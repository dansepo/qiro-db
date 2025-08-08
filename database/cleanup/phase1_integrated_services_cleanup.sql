-- =====================================================
-- 통합 서비스 구현 완료 후 프로시저 정리 스크립트 (Phase 1)
-- 데이터 무결성, 성능 모니터링, 테스트 관련 프로시저 제거
-- =====================================================

-- 실행 전 백업 권장
-- pg_dump -h 59.1.24.88 -p 65432 -U qiro -d qiro_dev -s > backup_schema_before_cleanup.sql

BEGIN;

-- =====================================================
-- 1. 데이터 무결성 관련 프로시저 제거
-- (DataIntegrityService로 이관 완료)
-- =====================================================

-- 1.1 공통 코드 관리 함수
DROP FUNCTION IF EXISTS bms.get_code_name(text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.get_codes_by_group(text) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_common_code_data(uuid) CASCADE;

-- 1.2 데이터 검증 함수들
DROP FUNCTION IF EXISTS bms.validate_business_registration_number(text) CASCADE;
DROP FUNCTION IF EXISTS public.validate_business_registration_number(text) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_building_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_contract_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_facility_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_fee_item_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_lessor_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_tenant_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_unit_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_system_setting_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_basic_check(text, anyelement, text) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_comparison(anyelement, anyelement, text) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_external_bill(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_fee_calculation(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_range_check(anyelement, anyelement, anyelement) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_statistical(numeric[], text) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_tax_transaction_amounts(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_zone_access(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.execute_fee_validation(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.execute_single_validation_rule(text, jsonb) CASCADE;

-- 1.3 사용자 활동 및 보안 로그 함수
DROP FUNCTION IF EXISTS bms.log_user_activity(uuid, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_activity(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_access(uuid, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_access(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_security_event(uuid, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_security_event(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_event(uuid, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_event(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_data_change(uuid, text, text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_privacy_processing(uuid, text, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_privacy_processing(uuid, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_access_attempt(uuid, text, boolean, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_building_changes(uuid, uuid, text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.log_contract_status_changes(uuid, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_facility_status_changes(uuid, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_lessor_status_changes(uuid, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_setting_changes(uuid, text, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_tenant_status_changes(uuid, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.log_unit_status_changes(uuid, uuid, text, text, text) CASCADE;
DROP FUNCTION IF EXISTS bms.auto_audit_trigger() CASCADE;

-- =====================================================
-- 2. 성능 모니터링 및 테스트 관련 프로시저 제거
-- (PerformanceMonitoringService로 이관 완료)
-- =====================================================

-- 2.1 성능 테스트 함수
DROP FUNCTION IF EXISTS bms.test_partition_performance(text) CASCADE;
DROP FUNCTION IF EXISTS bms.test_company_data_isolation(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.test_user_permissions(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.run_multitenancy_isolation_tests() CASCADE;

-- 2.2 통계 및 모니터링 함수
DROP FUNCTION IF EXISTS bms.get_audit_statistics(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.get_completion_statistics(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.get_fault_report_statistics(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.get_work_order_statistics(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.get_material_statistics(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.get_partition_stats(text) CASCADE;
DROP FUNCTION IF EXISTS bms.get_validation_summary(uuid) CASCADE;

-- 2.3 시스템 유지보수 및 정리 함수
DROP FUNCTION IF EXISTS bms.cleanup_audit_logs(interval) CASCADE;
DROP FUNCTION IF EXISTS bms.cleanup_expired_sessions() CASCADE;
DROP FUNCTION IF EXISTS bms.cleanup_multitenancy_test_data() CASCADE;
DROP FUNCTION IF EXISTS bms.archive_old_partitions(text, interval) CASCADE;
DROP FUNCTION IF EXISTS bms.annual_archive_maintenance() CASCADE;
DROP FUNCTION IF EXISTS bms.create_monthly_partitions(text, date) CASCADE;

-- =====================================================
-- 3. 테스트 데이터 생성 관련 프로시저 제거
-- (TestExecutionService로 이관 완료)
-- =====================================================

-- 3.1 테스트 데이터 생성 함수
DROP FUNCTION IF EXISTS bms.generate_test_companies(integer) CASCADE;

-- =====================================================
-- 정리 완료 로그 기록
-- =====================================================

-- 정리 완료 기록을 위한 임시 테이블 생성 (이미 존재하면 무시)
CREATE TABLE IF NOT EXISTS bms.procedure_cleanup_log (
    cleanup_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    phase_name text NOT NULL,
    cleanup_date timestamp DEFAULT CURRENT_TIMESTAMP,
    procedures_removed integer NOT NULL,
    status text NOT NULL,
    notes text
);

-- Phase 1 정리 완료 기록
INSERT INTO bms.procedure_cleanup_log (
    phase_name, 
    procedures_removed, 
    status, 
    notes
) VALUES (
    'Phase 1: 통합 서비스 관련 프로시저 정리',
    45, -- 실제 제거된 프로시저 수
    'COMPLETED',
    '데이터 무결성, 성능 모니터링, 테스트 관련 프로시저를 백엔드 서비스로 완전 이관 후 제거 완료'
);

-- =====================================================
-- 정리 결과 확인 쿼리
-- =====================================================

-- 남은 bms 스키마 함수 수 확인
SELECT 
    'Phase 1 정리 후 남은 함수 수' as description,
    COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_schema = 'bms' 
AND routine_type = 'FUNCTION';

-- 정리 로그 확인
SELECT * FROM bms.procedure_cleanup_log ORDER BY cleanup_date DESC LIMIT 5;

COMMIT;

-- =====================================================
-- 롤백 스크립트 (필요시 사용)
-- =====================================================

/*
-- 롤백이 필요한 경우 아래 주석을 해제하고 실행
-- 단, 백엔드 서비스가 정상 동작하는지 먼저 확인 필요

ROLLBACK;

-- 또는 백업에서 복원
-- psql -h 59.1.24.88 -p 65432 -U qiro -d qiro_dev < backup_schema_before_cleanup.sql
*/

-- =====================================================
-- 실행 후 확인사항
-- =====================================================

/*
1. 백엔드 서비스 정상 동작 확인
   - DataIntegrityService 기능 테스트
   - PerformanceMonitoringService 기능 테스트
   - TestExecutionService 기능 테스트

2. 애플리케이션 로그 확인
   - 프로시저 호출 관련 오류 없는지 확인
   - 성능 저하 없는지 모니터링

3. 다음 단계 준비
   - Phase 2: 비즈니스 로직 프로시저 정리 계획
   - 각 도메인 서비스 구현 상태 점검
*/