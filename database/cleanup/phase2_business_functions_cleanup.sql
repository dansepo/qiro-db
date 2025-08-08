-- =====================================================
-- Phase 2: 비즈니스 로직 함수 삭제 스크립트
-- 백엔드 서비스 이관 완료 후 실행
-- 실행 전 반드시 백업 수행 필요
-- =====================================================

-- 실행 전 확인사항 체크
DO $check$
BEGIN
    RAISE NOTICE '=== Phase 2 비즈니스 로직 함수 삭제 시작 ===';
    RAISE NOTICE '실행 시간: %', NOW();
    RAISE NOTICE '대상: 비즈니스 로직 관련 함수 (계산, 검증, 생성, 계약, 작업지시서 등)';
    RAISE NOTICE '';
    
    -- 삭제 대상 함수 개수 확인
    RAISE NOTICE '삭제 예정 함수 개수: %', (
        SELECT COUNT(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'bms' 
        AND (
            routine_name LIKE '%validate%' OR 
            routine_name LIKE '%calculate%' OR
            routine_name LIKE '%generate_%' OR
            routine_name LIKE '%contract%' OR
            routine_name LIKE '%work_order%' OR
            routine_name LIKE '%fault_report%' OR
            routine_name LIKE '%deposit%' OR
            routine_name LIKE '%settlement%'
        )
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  중요: 백엔드 서비스가 정상 동작하는지 확인하세요!';
    RAISE NOTICE '5초 후 삭제를 시작합니다...';
    PERFORM pg_sleep(5);
END $check$;

-- =====================================================
-- 1. 계산 관련 함수 삭제 (calculate_*)
-- =====================================================

DO $calculate_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '1. 계산 관련 함수 삭제 중...';
END $calculate_functions$;

-- 요금 계산 함수들
DROP FUNCTION IF EXISTS bms.calculate_area_based_fee(numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_fee_amount(uuid, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_late_fee(uuid, numeric, numeric, date, integer, date, date, numeric, numeric, character varying, numeric, numeric, integer, numeric) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_proportional_fee(numeric, numeric, numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_tiered_fee(numeric, jsonb, integer) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_unit_total_fee(uuid, date, jsonb, integer) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_tier_rate(uuid, numeric) CASCADE;

-- 보증금 및 이자 계산 함수들
DROP FUNCTION IF EXISTS bms.calculate_deposit_interest(uuid, uuid, date) CASCADE;
DROP FUNCTION IF EXISTS bms.bulk_calculate_deposit_interest(uuid, date) CASCADE;

-- 정산 관련 계산 함수들
DROP FUNCTION IF EXISTS bms.calculate_settlement_amount(uuid, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_settlement_amounts(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_proportional_allocation(uuid, date, date, uuid, numeric) CASCADE;

-- 자산 및 임대료 계산 함수들
DROP FUNCTION IF EXISTS bms.calculate_asset_performance(uuid, date) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_optimal_rent(uuid, uuid, uuid, numeric, numeric) CASCADE;

RAISE NOTICE '✓ 계산 관련 함수 삭제 완료';

-- =====================================================
-- 2. 검증 관련 함수 삭제 (validate_*)
-- =====================================================

DO $validate_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '2. 검증 관련 함수 삭제 중...';
END $validate_functions$;

-- 사업자등록번호 검증
DROP FUNCTION IF EXISTS bms.validate_business_registration_number(character varying) CASCADE;

-- 건물 및 유닛 데이터 검증
DROP FUNCTION IF EXISTS bms.validate_building_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_unit_data(uuid) CASCADE;

-- 계약 관련 검증
DROP FUNCTION IF EXISTS bms.validate_contract_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_contract_dates(date, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_contract_parties(uuid) CASCADE;

-- 요금 및 정산 검증
DROP FUNCTION IF EXISTS bms.validate_fee_calculation(uuid, numeric, numeric) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_settlement_data(uuid) CASCADE;

-- 작업 지시서 검증
DROP FUNCTION IF EXISTS bms.validate_work_order_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_work_order_assignment(uuid, uuid) CASCADE;

-- 기타 데이터 검증
DROP FUNCTION IF EXISTS bms.validate_user_permissions(uuid, character varying) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_company_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_tenant_data(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.validate_meter_reading(uuid, numeric, timestamp with time zone) CASCADE;

RAISE NOTICE '✓ 검증 관련 함수 삭제 완료';

-- =====================================================
-- 3. 생성 관련 함수 삭제 (generate_*)
-- =====================================================

DO $generate_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '3. 생성 관련 함수 삭제 중...';
END $generate_functions$;

-- 번호 생성 함수들
DROP FUNCTION IF EXISTS bms.generate_accounting_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_notice_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_reservation_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_complaint_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_incident_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_patrol_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_budget_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_contract_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_work_order_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_fault_report_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_invoice_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_receipt_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_settlement_number(uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_deposit_receipt_number(uuid) CASCADE;

-- 기타 생성 함수들
DROP FUNCTION IF EXISTS bms.generate_unique_identifier(character varying) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_qr_code_data(uuid, character varying) CASCADE;

RAISE NOTICE '✓ 생성 관련 함수 삭제 완료';

-- =====================================================
-- 4. 계약 관련 함수 삭제 (contract_*)
-- =====================================================

DO $contract_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '4. 계약 관련 함수 삭제 중...';
END $contract_functions$;

-- 계약 당사자 관리
DROP FUNCTION IF EXISTS bms.add_contract_party(uuid, character varying, character varying, character varying, character varying, character varying, character varying, text, boolean, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.update_contract_party(uuid, character varying, character varying, character varying, character varying, character varying, text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.remove_contract_party(uuid, uuid) CASCADE;

-- 계약 생성 및 관리
DROP FUNCTION IF EXISTS bms.create_lease_contract(uuid, uuid, uuid, date, date, numeric, character varying, jsonb) CASCADE;
DROP FUNCTION IF EXISTS bms.update_contract_status(uuid, character varying, character varying, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.terminate_contract(uuid, date, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.renew_contract(uuid, date, date, numeric, jsonb, uuid) CASCADE;

-- 계약 조건 관리
DROP FUNCTION IF EXISTS bms.add_contract_condition(uuid, character varying, text, boolean, date, date) CASCADE;
DROP FUNCTION IF EXISTS bms.update_contract_terms(uuid, jsonb, uuid) CASCADE;

RAISE NOTICE '✓ 계약 관련 함수 삭제 완료';

-- =====================================================
-- 5. 작업 지시서 관련 함수 삭제 (work_order_*)
-- =====================================================

DO $work_order_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '5. 작업 지시서 관련 함수 삭제 중...';
END $work_order_functions$;

-- 작업 지시서 생성 및 관리
DROP FUNCTION IF EXISTS bms.create_work_order(uuid, uuid, character varying, character varying, text, character varying, timestamp with time zone, timestamp with time zone, numeric, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_work_order_status(uuid, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.assign_work_order(uuid, uuid, character varying, character varying, numeric, timestamp with time zone, timestamp with time zone, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.complete_work_order(uuid, timestamp with time zone, text, numeric, uuid) CASCADE;

-- 작업 지시서 자재 관리
DROP FUNCTION IF EXISTS bms.add_work_order_material(uuid, character varying, numeric, character varying, character varying, character varying, numeric, character varying, boolean, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_work_order_material_usage(uuid, uuid, numeric, numeric, text) CASCADE;

-- 작업 지시서 진행 관리
DROP FUNCTION IF EXISTS bms.start_work_order(uuid, timestamp with time zone, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.pause_work_order(uuid, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.resume_work_order(uuid, text, uuid) CASCADE;

RAISE NOTICE '✓ 작업 지시서 관련 함수 삭제 완료';

-- =====================================================
-- 6. 고장 신고 관련 함수 삭제 (fault_report_*)
-- =====================================================

DO $fault_report_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '6. 고장 신고 관련 함수 삭제 중...';
END $fault_report_functions$;

-- 고장 신고 생성 및 관리
DROP FUNCTION IF EXISTS bms.create_fault_report(uuid, uuid, uuid, character varying, character varying, text, character varying, character varying, boolean, jsonb, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_fault_report_status(uuid, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.assign_fault_report(uuid, uuid, character varying, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.resolve_fault_report(uuid, text, character varying, numeric, timestamp with time zone, uuid) CASCADE;

-- 고장 신고 커뮤니케이션
DROP FUNCTION IF EXISTS bms.add_fault_report_communication(uuid, character varying, character varying, character varying, character varying, character varying, character varying, text, character varying, character varying, uuid, character varying, character varying, uuid, boolean, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_fault_report_priority(uuid, character varying, character varying, uuid) CASCADE;

-- 고장 신고 진행 관리
DROP FUNCTION IF EXISTS bms.start_fault_report_response(uuid, timestamp with time zone, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.escalate_fault_report(uuid, character varying, text, uuid) CASCADE;

RAISE NOTICE '✓ 고장 신고 관련 함수 삭제 완료';

-- =====================================================
-- 7. 보증금 관련 함수 삭제 (deposit_*)
-- =====================================================

DO $deposit_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '7. 보증금 관련 함수 삭제 중...';
END $deposit_functions$;

-- 보증금 관리
DROP FUNCTION IF EXISTS bms.create_deposit_record(uuid, uuid, numeric, character varying, date, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_deposit_status(uuid, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.process_deposit_refund(uuid, numeric, character varying, text, date, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.transfer_deposit(uuid, uuid, numeric, character varying, text, uuid) CASCADE;

-- 보증금 이자 관리
DROP FUNCTION IF EXISTS bms.apply_deposit_interest(uuid, numeric, date, character varying, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.adjust_deposit_amount(uuid, numeric, character varying, text, uuid) CASCADE;

RAISE NOTICE '✓ 보증금 관련 함수 삭제 완료';

-- =====================================================
-- 8. 정산 관련 함수 삭제 (settlement_*)
-- =====================================================

DO $settlement_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '8. 정산 관련 함수 삭제 중...';
END $settlement_functions$;

-- 정산 생성 및 관리
DROP FUNCTION IF EXISTS bms.create_settlement_record(uuid, uuid, date, date, character varying, numeric, numeric, character varying, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.update_settlement_status(uuid, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.finalize_settlement(uuid, timestamp with time zone, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.approve_settlement(uuid, text, uuid) CASCADE;

-- 정산 계산 및 처리
DROP FUNCTION IF EXISTS bms.process_settlement_payment(uuid, numeric, character varying, text, date, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.adjust_settlement_amount(uuid, numeric, character varying, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.reverse_settlement(uuid, character varying, text, uuid) CASCADE;

RAISE NOTICE '✓ 정산 관련 함수 삭제 완료';

-- =====================================================
-- 9. 기타 비즈니스 로직 함수 삭제
-- =====================================================

DO $other_functions$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '9. 기타 비즈니스 로직 함수 삭제 중...';
END $other_functions$;

-- 계약자 관리
DROP FUNCTION IF EXISTS bms.assign_work_to_contractor(uuid, uuid, date, date, numeric, uuid, character varying, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.evaluate_contractor_performance(uuid, uuid, numeric, text, uuid) CASCADE;

-- 기타 업무 프로세스
DROP FUNCTION IF EXISTS bms.process_invoice_payment(uuid, numeric, character varying, date, text, uuid) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_monthly_report(uuid, date, character varying) CASCADE;
DROP FUNCTION IF EXISTS bms.update_asset_condition(uuid, character varying, text, date, uuid) CASCADE;

RAISE NOTICE '✓ 기타 비즈니스 로직 함수 삭제 완료';

-- =====================================================
-- 10. 삭제 완료 확인 및 정리
-- =====================================================

DO $cleanup$
DECLARE
    remaining_count INTEGER;
    total_deleted INTEGER;
BEGIN
    -- 남은 Phase 2 관련 함수 확인
    SELECT COUNT(*) INTO remaining_count
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND (
        routine_name LIKE '%validate%' OR 
        routine_name LIKE '%calculate%' OR
        routine_name LIKE '%generate_%' OR
        routine_name LIKE '%contract%' OR
        routine_name LIKE '%work_order%' OR
        routine_name LIKE '%fault_report%' OR
        routine_name LIKE '%deposit%' OR
        routine_name LIKE '%settlement%'
    );
    
    total_deleted := 92 - remaining_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== Phase 2 삭제 완료 ===';
    RAISE NOTICE '삭제 완료 시간: %', NOW();
    RAISE NOTICE '삭제된 함수: %개', total_deleted;
    RAISE NOTICE '남은 Phase 2 관련 함수: %개', remaining_count;
    
    IF remaining_count = 0 THEN
        RAISE NOTICE '✅ 모든 Phase 2 비즈니스 로직 함수가 성공적으로 삭제되었습니다!';
    ELSIF remaining_count <= 5 THEN
        RAISE NOTICE '⚠️  소수의 함수가 남아있습니다. 수동 확인이 필요합니다.';
    ELSE
        RAISE NOTICE '❌ 예상보다 많은 함수가 남아있습니다. 스크립트를 재검토하세요.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '현재 총 bms 함수 개수: %', (
        SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema = 'bms'
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계: Phase 3 시스템 관리 함수 삭제';
    RAISE NOTICE '실행 파일: phase3_system_functions_cleanup.sql';
END $cleanup$;

-- =====================================================
-- 11. 롤백 스크립트 정보
-- =====================================================

/*
롤백이 필요한 경우 다음 단계를 수행하세요:

1. 백업에서 함수들을 복원
2. 백엔드 서비스에서 해당 기능 비활성화
3. 데이터베이스 함수 호출로 다시 전환

주요 복원 대상 함수 카테고리:
- 계산 관련: calculate_fee_amount, calculate_deposit_interest 등
- 검증 관련: validate_business_registration_number, validate_contract_data 등  
- 생성 관련: generate_contract_number, generate_work_order_number 등
- 계약 관리: create_lease_contract, add_contract_party 등
- 작업 지시서: create_work_order, assign_work_order 등
- 고장 신고: create_fault_report, assign_fault_report 등
- 보증금 관리: create_deposit_record, process_deposit_refund 등
- 정산 관리: create_settlement_record, process_settlement_payment 등

복원 후 확인사항:
- 백엔드 서비스 기능 비활성화
- 데이터베이스 함수 호출 재활성화
- 전체 시스템 기능 테스트
- 성능 및 안정성 확인
*/