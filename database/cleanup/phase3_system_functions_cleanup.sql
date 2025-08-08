-- =====================================================
-- Phase 3: 시스템 관리 함수 삭제 스크립트
-- Phase 2 완료 후 실행
-- 실행 전 반드시 백업 수행 필요
-- =====================================================

-- 실행 전 확인사항 체크
DO $check$
BEGIN
    RAISE NOTICE '=== Phase 3 시스템 관리 함수 삭제 시작 ===';
    RAISE NOTICE '실행 시간: %', NOW();
    RAISE NOTICE '대상: 시스템 관리 및 나머지 함수들';
    RAISE NOTICE '';
    
    -- Phase 2 완료 확인
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_schema = 'bms' 
        AND routine_name = 'calculate_fee_amount'
    ) THEN
        RAISE EXCEPTION 'Phase 2가 완료되지 않았습니다. Phase 2를 먼저 실행하세요.';
    END IF;
    
    RAISE NOTICE '✓ Phase 2 완료 확인됨';
END $check$;

-- =====================================================
-- 1. 재고 및 자재 관리 함수 삭제
-- =====================================================

-- 1.1 재고 관리 함수
DROP FUNCTION IF EXISTS bms.get_inventory_movement_history(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.get_inventory_summary_by_location(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.get_low_stock_report(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS bms.reserve_inventory(UUID, UUID, DECIMAL, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.create_inventory_receipt_transaction(UUID, UUID, DECIMAL, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS bms.process_cycle_count_variance(UUID, DECIMAL, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.update_reorder_flags(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.update_reservation_remaining_quantity(UUID, DECIMAL) CASCADE;
RAISE NOTICE '✓ 재고 관리 함수 삭제 완료';

-- 1.2 자재 관리 함수
DROP FUNCTION IF EXISTS bms.get_materials(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.create_material(UUID, VARCHAR, VARCHAR, VARCHAR, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS bms.add_work_order_material(UUID, UUID, DECIMAL, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS bms.update_material_cost(UUID, DECIMAL, DATE) CASCADE;
RAISE NOTICE '✓ 자재 관리 함수 삭제 완료';

-- 1.3 공급업체 관리 함수
DROP FUNCTION IF EXISTS bms.get_suppliers(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.create_supplier(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.get_material_suppliers(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.add_material_supplier(UUID, UUID, DECIMAL, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS bms.get_supplier_performance_report(UUID, UUID, DATE, DATE) CASCADE;
RAISE NOTICE '✓ 공급업체 관리 함수 삭제 완료';

-- 1.4 구매 관리 함수
DROP FUNCTION IF EXISTS bms.submit_purchase_request(UUID, UUID, DECIMAL, DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.get_purchase_request_summary(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.create_purchase_order_from_quotation(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.select_quotation(UUID, UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.update_quotation_totals(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.approve_purchase_invoice(UUID, UUID, DATE) CASCADE;
RAISE NOTICE '✓ 구매 관리 함수 삭제 완료';

-- =====================================================
-- 2. 보안 및 접근 제어 함수 삭제
-- =====================================================

-- 2.1 보안 관리 함수
DROP FUNCTION IF EXISTS bms.create_security_incident(UUID, VARCHAR, VARCHAR, TEXT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.create_security_zone(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.update_security_zone_path(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.register_security_device(UUID, VARCHAR, VARCHAR, VARCHAR, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.update_device_status(UUID, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_security_alert(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.get_security_dashboard_data(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.schedule_security_patrol(UUID, VARCHAR, VARCHAR, DATE, TIME) CASCADE;
RAISE NOTICE '✓ 보안 관리 함수 삭제 완료';

-- 2.2 방문자 관리 함수
DROP FUNCTION IF EXISTS bms.register_visitor(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.visitor_check_in(UUID, UUID, TIMESTAMP, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.visitor_check_out(UUID, UUID, TIMESTAMP) CASCADE;
RAISE NOTICE '✓ 방문자 관리 함수 삭제 완료';

-- 2.3 권한 및 세션 관리 함수
DROP FUNCTION IF EXISTS bms.check_user_permission(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.check_user_permission(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.create_user_session(UUID, VARCHAR, INET, TEXT) CASCADE;
RAISE NOTICE '✓ 권한 및 세션 관리 함수 삭제 완료';

-- =====================================================
-- 3. 안전 및 규정 준수 함수 삭제
-- =====================================================

-- 3.1 안전 점검 함수
DROP FUNCTION IF EXISTS bms.create_safety_inspection(UUID, VARCHAR, UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.create_safety_inspection_schedule(UUID, VARCHAR, UUID, TEXT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.complete_safety_inspection(UUID, VARCHAR, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS bms.get_safety_inspection_summary(UUID, DATE, DATE, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.report_safety_incident(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
RAISE NOTICE '✓ 안전 점검 함수 삭제 완료';

-- 3.2 규정 준수 함수
DROP FUNCTION IF EXISTS bms.create_legal_compliance_requirement(UUID, VARCHAR, TEXT, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.create_risk_assessment(UUID, VARCHAR, VARCHAR, TEXT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS bms.create_prevention_measure(UUID, VARCHAR, TEXT, DATE, UUID) CASCADE;
RAISE NOTICE '✓ 규정 준수 함수 삭제 완료';

-- =====================================================
-- 4. 마케팅 및 고객 관리 함수 삭제
-- =====================================================

-- 4.1 마케팅 캠페인 함수
DROP FUNCTION IF EXISTS bms.create_marketing_campaign(UUID, VARCHAR, TEXT, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.update_campaign_performance(UUID, INTEGER, INTEGER, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS bms.generate_pricing_strategy(UUID, UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_optimal_rent(UUID, UUID, JSONB) CASCADE;
RAISE NOTICE '✓ 마케팅 캠페인 함수 삭제 완료';

-- 4.2 고객 만족도 관리 함수
DROP FUNCTION IF EXISTS bms.create_satisfaction_survey(UUID, VARCHAR, JSONB, DATE) CASCADE;
RAISE NOTICE '✓ 고객 만족도 관리 함수 삭제 완료';

-- =====================================================
-- 5. 보험 및 리스크 관리 함수 삭제
-- =====================================================

DROP FUNCTION IF EXISTS bms.create_insurance_policy(UUID, VARCHAR, VARCHAR, DECIMAL, DATE, DATE) CASCADE;
RAISE NOTICE '✓ 보험 관리 함수 삭제 완료';

-- =====================================================
-- 6. 외주 및 계약업체 관리 함수 삭제
-- =====================================================

DROP FUNCTION IF EXISTS bms.create_outsourcing_work_request(UUID, VARCHAR, TEXT, DATE, DECIMAL) CASCADE;
DROP FUNCTION IF EXISTS bms.assign_work_to_contractor(UUID, UUID, DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.register_contractor(UUID, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.register_contractor(UUID, VARCHAR, VARCHAR, VARCHAR, JSONB) CASCADE;
RAISE NOTICE '✓ 외주 관리 함수 삭제 완료';

-- =====================================================
-- 7. 분석 및 리포팅 함수 삭제
-- =====================================================

-- 7.1 성과 분석 함수
DROP FUNCTION IF EXISTS bms.analyze_facility_condition_trends(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.analyze_maintenance_effectiveness(UUID, VARCHAR, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.analyze_rent_performance(UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.calculate_asset_performance(UUID, UUID, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.compare_period_performance(UUID, DATE, DATE, DATE, DATE) CASCADE;
RAISE NOTICE '✓ 성과 분석 함수 삭제 완료';

-- 7.2 업무 요약 함수
DROP FUNCTION IF EXISTS bms.get_work_assignment_summary(UUID, DATE, DATE) CASCADE;
RAISE NOTICE '✓ 업무 요약 함수 삭제 완료';

-- =====================================================
-- 8. 시스템 설정 및 초기화 함수 삭제
-- =====================================================

-- 8.1 기본 데이터 생성 함수
DROP FUNCTION IF EXISTS bms.create_default_common_codes(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.create_default_roles(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.create_default_roles(UUID, VARCHAR[]) CASCADE;
DROP FUNCTION IF EXISTS bms.create_default_system_settings(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_account_codes(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_announcement_categories(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_complaint_categories(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_complaint_categories(UUID, VARCHAR[]) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_services(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_tax_calculation_rules(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.insert_default_transaction_categories(UUID) CASCADE;
RAISE NOTICE '✓ 기본 데이터 생성 함수 삭제 완료';

-- 8.2 시스템 설정 관리 함수
DROP FUNCTION IF EXISTS bms.get_system_setting(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.get_setting_value(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.get_setting_value(VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.update_setting_value(UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.get_json_setting(UUID, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.set_fiscal_period(UUID, DATE, DATE) CASCADE;
RAISE NOTICE '✓ 시스템 설정 관리 함수 삭제 완료';

-- =====================================================
-- 9. 사용자 활동 및 보안 로그 함수 삭제
-- =====================================================

DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_access(UUID, VARCHAR, INET, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.log_user_access(UUID, VARCHAR, INET, VARCHAR, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_event(VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_event(VARCHAR, VARCHAR, TEXT, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.log_data_change(UUID, VARCHAR, VARCHAR, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.log_privacy_processing(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_privacy_processing(UUID, VARCHAR, VARCHAR, TEXT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.log_access_attempt(UUID, UUID, UUID, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.log_building_changes(UUID, VARCHAR, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.log_contract_status_changes(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_facility_status_changes(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_lessor_status_changes(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_system_setting_changes(UUID, VARCHAR, VARCHAR, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.log_tenant_status_changes(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.log_unit_status_changes(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.auto_audit_trigger() CASCADE;
RAISE NOTICE '✓ 사용자 활동 및 보안 로그 함수 삭제 완료';

-- =====================================================
-- 10. 기타 업무 프로세스 함수 삭제
-- =====================================================

-- 10.1 예약 관리 함수
DROP FUNCTION IF EXISTS bms.cancel_reservation(UUID, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.fulfill_reservation(UUID, UUID, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS bms.update_booking_timestamps(UUID, TIMESTAMP, TIMESTAMP) CASCADE;
RAISE NOTICE '✓ 예약 관리 함수 삭제 완료';

-- 10.2 불만 처리 함수
DROP FUNCTION IF EXISTS bms.record_complaint_history(UUID, VARCHAR, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.set_complaint_sla(UUID, INTEGER, VARCHAR) CASCADE;
RAISE NOTICE '✓ 불만 처리 함수 삭제 완료';

-- 10.3 기타 업무 함수들
DROP FUNCTION IF EXISTS bms.assign_incident_investigator(UUID, UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.complete_patrol_checkpoint(UUID, UUID, TIMESTAMP, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.update_budget_execution(UUID, DECIMAL, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.create_balance_adjustment(UUID, UUID, DECIMAL, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.create_cost_settlement(UUID, UUID, DECIMAL, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.create_refund_transaction(UUID, DECIMAL, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.update_announcement_attachments_flag(UUID, BOOLEAN) CASCADE;
DROP FUNCTION IF EXISTS bms.update_announcement_view_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.apply_auto_fix(UUID, VARCHAR, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.apply_status_change(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.check_sla_breach(UUID, TIMESTAMP, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS bms.complete_checklist_item(UUID, UUID, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.create_completion_inspection(UUID, UUID, DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.create_completion_report(UUID, TEXT, JSONB, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.create_party_relationship(UUID, UUID, VARCHAR, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.create_status_approval_request(UUID, VARCHAR, VARCHAR, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.create_work_inspection(UUID, UUID, DATE, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.create_work_warranty(UUID, INTEGER, TEXT, DATE) CASCADE;
DROP FUNCTION IF EXISTS bms.detect_reading_anomaly(DECIMAL, DECIMAL[], VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.evaluate_party_credit(UUID, JSONB) CASCADE;
DROP FUNCTION IF EXISTS bms.execute_usage_allocation(UUID, UUID, DECIMAL, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS bms.process_status_approval(UUID, VARCHAR, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS bms.send_status_notification(UUID, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.update_assessment_damage_costs(UUID, DECIMAL, TEXT) CASCADE;
DROP FUNCTION IF EXISTS bms.update_updated_at_column() CASCADE;
RAISE NOTICE '✓ 기타 업무 함수 삭제 완료';

-- =====================================================
-- 11. 최종 정리 및 확인
-- =====================================================

DO $final_cleanup$
DECLARE
    remaining_functions INTEGER;
    remaining_procedures INTEGER;
    total_remaining INTEGER;
    function_list TEXT;
BEGIN
    -- 남은 함수 개수 확인
    SELECT COUNT(*) INTO remaining_functions
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'FUNCTION';
    
    -- 남은 프로시저 개수 확인
    SELECT COUNT(*) INTO remaining_procedures
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'PROCEDURE';
    
    total_remaining := remaining_functions + remaining_procedures;
    
    -- 남은 함수 목록 생성 (처음 10개만)
    SELECT string_agg(routine_name, ', ') INTO function_list
    FROM (
        SELECT routine_name 
        FROM information_schema.routines 
        WHERE routine_schema = 'bms' 
        ORDER BY routine_name 
        LIMIT 10
    ) t;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== Phase 3 및 전체 정리 완료 ===';
    RAISE NOTICE '완료 시간: %', NOW();
    RAISE NOTICE '남은 함수: %개', remaining_functions;
    RAISE NOTICE '남은 프로시저: %개', remaining_procedures;
    RAISE NOTICE '총 남은 루틴: %개', total_remaining;
    
    IF total_remaining > 0 THEN
        RAISE NOTICE '';
        RAISE NOTICE '남은 함수 목록 (처음 10개):';
        RAISE NOTICE '%', COALESCE(function_list, '없음');
        RAISE NOTICE '';
        
        IF total_remaining <= 10 THEN
            RAISE NOTICE '✓ 소수의 함수만 남아있습니다. 수동 검토 후 삭제하세요.';
        ELSE
            RAISE NOTICE '⚠ 예상보다 많은 함수가 남아있습니다. 추가 정리가 필요할 수 있습니다.';
        END IF;
    ELSE
        RAISE NOTICE '🎉 모든 bms 스키마 함수가 성공적으로 삭제되었습니다!';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 프로시저 삭제 작업 완료 ===';
    RAISE NOTICE '다음 단계: 데이터베이스 스키마 최적화 및 성능 테스트';
    RAISE NOTICE '백엔드 서비스 정상 동작 확인 필요';
END $final_cleanup$;

-- =====================================================
-- 12. 삭제 완료 후 권장 작업
-- =====================================================

/*
프로시저 삭제 완료 후 수행할 작업:

1. 백엔드 서비스 동작 확인
   - 모든 API 엔드포인트 테스트
   - 핵심 비즈니스 로직 검증
   - 성능 테스트 실행

2. 데이터베이스 최적화
   - VACUUM FULL 실행으로 공간 회수
   - 인덱스 재구성 (REINDEX)
   - 통계 정보 업데이트 (ANALYZE)

3. 모니터링 설정
   - 애플리케이션 로그 모니터링
   - 데이터베이스 성능 모니터링
   - 오류 알림 설정

4. 문서 업데이트
   - API 문서 갱신
   - 운영 가이드 업데이트
   - 장애 대응 매뉴얼 수정

5. 백업 및 복구 테스트
   - 새로운 구조에 맞는 백업 절차 확인
   - 복구 시나리오 테스트
   - 재해 복구 계획 업데이트

권장 SQL 명령어:
VACUUM FULL;
REINDEX DATABASE qiro_dev;
ANALYZE;
*/