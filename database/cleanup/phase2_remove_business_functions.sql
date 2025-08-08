-- =====================================================
-- Phase 2: 비즈니스 로직 함수 제거 스크립트
-- Phase 1 완료 및 백엔드 서비스 검증 후 실행
-- =====================================================

-- 실행 전 확인사항 출력
\echo '======================================'
\echo 'Phase 2: 비즈니스 로직 함수 제거 시작'
\echo 'Phase 1 완료 및 백엔드 서비스 검증 필수!'
\echo '======================================'

-- 현재 함수 목록 백업 (실행 전)
\echo '현재 함수 목록을 백업합니다...'
\o database/cleanup/backup_functions_phase2.sql
SELECT 'CREATE OR REPLACE ' || pg_get_functiondef(p.oid) || ';' 
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'bms') 
AND p.proname IN (
    'validate_common_code_data',
    'get_code_name',
    'get_codes_by_group',
    'log_user_activity',
    'log_security_event',
    'create_work_order',
    'assign_work_order',
    'update_work_order_status',
    'add_work_order_material',
    'record_work_progress',
    'get_work_orders',
    'get_work_order_statistics',
    'complete_work_order',
    'start_inspection_execution',
    'complete_inspection_execution',
    'record_checklist_result',
    'create_inspection_finding',
    'create_corrective_action'
);
\o

\echo '백업 완료. 비즈니스 로직 함수 제거를 시작합니다...'

-- =====================================================
-- 1. 공통 코드 관리 함수 제거
-- =====================================================

\echo '1. 공통 코드 관리 함수 제거 중...'

-- 공통 코드 검증 함수 제거 (트리거 함수)
DROP FUNCTION IF EXISTS bms.validate_common_code_data() CASCADE;
\echo '  ✓ validate_common_code_data 함수 및 관련 트리거 제거 완료'

-- 공통 코드 조회 함수들 제거
DROP FUNCTION IF EXISTS bms.get_code_name(VARCHAR, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS bms.get_code_name(VARCHAR, VARCHAR);
\echo '  ✓ get_code_name 함수 제거 완료'

DROP FUNCTION IF EXISTS bms.get_codes_by_group(VARCHAR, UUID, BOOLEAN);
DROP FUNCTION IF EXISTS bms.get_codes_by_group(VARCHAR, UUID);
DROP FUNCTION IF EXISTS bms.get_codes_by_group(VARCHAR);
\echo '  ✓ get_codes_by_group 함수 제거 완료'

-- =====================================================
-- 2. 사용자 활동 로그 함수 제거
-- =====================================================

\echo '2. 사용자 활동 로그 함수 제거 중...'

-- 사용자 활동 로그 기록 함수 제거
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT, JSONB, INET);
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT, JSONB);
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR);
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID);
DROP FUNCTION IF EXISTS bms.log_user_activity();
\echo '  ✓ log_user_activity 함수 제거 완료'

-- 보안 이벤트 로그 기록 함수 제거
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT, JSONB, INET);
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT, JSONB);
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT);
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR);
\echo '  ✓ log_security_event 함수 제거 완료'

-- =====================================================
-- 3. 작업 지시서 관리 함수 제거
-- =====================================================

\echo '3. 작업 지시서 관리 함수 제거 중...'

-- 작업 지시서 생성 함수 제거
DROP FUNCTION IF EXISTS bms.create_work_order(UUID, VARCHAR, TEXT, VARCHAR, VARCHAR, UUID, UUID, TIMESTAMP, TIMESTAMP, DECIMAL, TEXT);
\echo '  ✓ create_work_order 함수 제거 완료'

-- 작업 지시서 배정 함수 제거
DROP FUNCTION IF EXISTS bms.assign_work_order(UUID, UUID, TEXT);
\echo '  ✓ assign_work_order 함수 제거 완료'

-- 작업 지시서 상태 업데이트 함수 제거
DROP FUNCTION IF EXISTS bms.update_work_order_status(UUID, VARCHAR, TEXT, UUID);
\echo '  ✓ update_work_order_status 함수 제거 완료'

-- 작업 자재 추가 함수 제거
DROP FUNCTION IF EXISTS bms.add_work_order_material(UUID, VARCHAR, VARCHAR, INTEGER, DECIMAL, DECIMAL, VARCHAR, TEXT);
\echo '  ✓ add_work_order_material 함수 제거 완료'

-- 작업 진행 기록 함수 제거
DROP FUNCTION IF EXISTS bms.record_work_progress(UUID, INTEGER, TEXT, DECIMAL, INTEGER, UUID);
\echo '  ✓ record_work_progress 함수 제거 완료'

-- 작업 지시서 조회 함수 제거
DROP FUNCTION IF EXISTS bms.get_work_orders(UUID, INTEGER, INTEGER, VARCHAR, VARCHAR, UUID, UUID, DATE, DATE);
\echo '  ✓ get_work_orders 함수 제거 완료'

-- 작업 지시서 통계 함수 제거
DROP FUNCTION IF EXISTS bms.get_work_order_statistics(UUID, UUID, DATE, DATE);
\echo '  ✓ get_work_order_statistics 함수 제거 완료'

-- 작업 지시서 완료 함수 제거
DROP FUNCTION IF EXISTS bms.complete_work_order(UUID, TEXT, DECIMAL, INTEGER, UUID);
\echo '  ✓ complete_work_order 함수 제거 완료'

-- =====================================================
-- 4. 점검 실행 관리 함수 제거
-- =====================================================

\echo '4. 점검 실행 관리 함수 제거 중...'

-- 점검 실행 시작 함수 제거
DROP FUNCTION IF EXISTS bms.start_inspection_execution(UUID, UUID, UUID, TEXT);
\echo '  ✓ start_inspection_execution 함수 제거 완료'

-- 점검 실행 완료 함수 제거
DROP FUNCTION IF EXISTS bms.complete_inspection_execution(UUID, VARCHAR, TEXT, UUID);
\echo '  ✓ complete_inspection_execution 함수 제거 완료'

-- 체크리스트 결과 기록 함수 제거
DROP FUNCTION IF EXISTS bms.record_checklist_result(UUID, INTEGER, VARCHAR, TEXT, DECIMAL, VARCHAR, TEXT);
\echo '  ✓ record_checklist_result 함수 제거 완료'

-- 점검 발견사항 생성 함수 제거
DROP FUNCTION IF EXISTS bms.create_inspection_finding(UUID, UUID, VARCHAR, VARCHAR, TEXT, VARCHAR, TEXT, UUID);
\echo '  ✓ create_inspection_finding 함수 제거 완료'

-- 시정조치 생성 함수 제거
DROP FUNCTION IF EXISTS bms.create_corrective_action(UUID, VARCHAR, TEXT, UUID, DATE, VARCHAR, TEXT);
\echo '  ✓ create_corrective_action 함수 제거 완료'

-- =====================================================
-- 5. 관련 트리거 정리
-- =====================================================

\echo '5. 관련 트리거 정리 중...'

-- 공통 코드 검증 트리거가 제거되었는지 확인
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'bms' 
AND action_statement LIKE '%validate_common_code_data%';

\echo '  → 관련 트리거들이 CASCADE로 제거되었습니다'

-- =====================================================
-- 6. 함수 의존성 확인
-- =====================================================

\echo '6. 함수 의존성 확인 중...'

-- 제거된 함수들을 참조하는 다른 객체가 있는지 확인
SELECT DISTINCT
    dependent_ns.nspname as dependent_schema,
    dependent_obj.relname as dependent_object,
    dependent_obj.relkind as object_type
FROM pg_depend d
JOIN pg_class dependent_obj ON d.objid = dependent_obj.oid
JOIN pg_namespace dependent_ns ON dependent_obj.relnamespace = dependent_ns.oid
JOIN pg_proc referenced_proc ON d.refobjid = referenced_proc.oid
WHERE referenced_proc.proname IN (
    'validate_common_code_data', 'get_code_name', 'get_codes_by_group',
    'log_user_activity', 'log_security_event',
    'create_work_order', 'assign_work_order', 'update_work_order_status',
    'add_work_order_material', 'record_work_progress', 'get_work_orders',
    'get_work_order_statistics', 'complete_work_order',
    'start_inspection_execution', 'complete_inspection_execution',
    'record_checklist_result', 'create_inspection_finding', 'create_corrective_action'
);

\echo '  → 의존성 확인 완료'

-- =====================================================
-- 완료 확인
-- =====================================================

\echo ''
\echo '======================================'
\echo 'Phase 2 비즈니스 로직 함수 제거 완료!'
\echo '======================================'

-- 제거된 함수 확인
\echo '제거 확인: 남은 비즈니스 로직 함수 목록'
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p 
JOIN pg_namespace n ON p.pronamespace = n.oid 
WHERE n.nspname IN ('public', 'bms') 
AND (
    p.proname LIKE '%work_order%' OR 
    p.proname LIKE '%inspection%' OR
    p.proname LIKE '%common_code%' OR
    p.proname LIKE '%log_%'
)
ORDER BY n.nspname, p.proname;

\echo ''
\echo '다음 단계:'
\echo '1. 백엔드 비즈니스 서비스가 정상 동작하는지 확인'
\echo '2. 기존 비즈니스 로직이 백엔드에서 동일하게 작동하는지 검증'
\echo '3. 트리거 제거로 인한 데이터 무결성 확인'
\echo '4. 문제없으면 Phase 3 실행 준비'
\echo ''
\echo 'Phase 2 완료 - 비즈니스 로직 함수 제거 성공!'