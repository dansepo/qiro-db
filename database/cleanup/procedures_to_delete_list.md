# 삭제 대상 프로시저/함수 전체 목록

## 개요
백엔드 서비스로 이관 완료 후 삭제할 데이터베이스 프로시저 및 함수의 전체 목록입니다.
총 271개의 bms 스키마 함수가 삭제 대상입니다.

---

## Phase 1: 테스트 관련 함수 (18개)

### 성능 테스트 함수 (4개)
- `bms.test_partition_performance()`
- `bms.test_company_data_isolation()`
- `bms.test_user_permissions()`
- `bms.run_multitenancy_isolation_tests()`

### 테스트 데이터 생성 함수 (1개)
- `bms.generate_test_companies()`

### 시스템 유지보수 및 정리 함수 (8개)
- `bms.cleanup_multitenancy_test_data()`
- `bms.get_partition_stats()`
- `bms.get_validation_summary()`
- `bms.cleanup_audit_logs()`
- `bms.cleanup_expired_sessions()`
- `bms.archive_old_partitions()`
- `bms.annual_archive_maintenance()`
- `bms.create_monthly_partitions()`

### 통계 및 모니터링 함수 (5개)
- `bms.get_audit_statistics()`
- `bms.get_completion_statistics()`
- `bms.get_fault_report_statistics()`
- `bms.get_work_order_statistics()`
- `bms.get_material_statistics()`

---

## Phase 2: 비즈니스 로직 함수 (약 150개)

### 1. 데이터 무결성 및 검증 함수 (23개)

#### 공통 코드 관리 함수 (3개)
- `bms.get_code_name(VARCHAR, VARCHAR)`
- `bms.get_codes_by_group(VARCHAR)`
- `bms.validate_common_code_data(UUID, VARCHAR, VARCHAR, VARCHAR)`

#### 데이터 검증 함수들 (20개)
- `bms.validate_business_registration_number(VARCHAR)`
- `public.validate_business_registration_number(VARCHAR)`
- `bms.validate_building_data(UUID, VARCHAR, VARCHAR, VARCHAR, INTEGER)`
- `bms.validate_contract_data(UUID, UUID, UUID, DATE, DATE, DECIMAL)`
- `bms.validate_facility_data(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.validate_fee_item_data(UUID, VARCHAR, VARCHAR, DECIMAL, VARCHAR)`
- `bms.validate_lessor_data(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.validate_tenant_data(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.validate_unit_data(UUID, VARCHAR, DECIMAL, INTEGER, VARCHAR)`
- `bms.validate_system_setting_data(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.validate_basic_check(VARCHAR, VARCHAR, VARCHAR)`
- `bms.validate_comparison(DECIMAL, DECIMAL, VARCHAR)`
- `bms.validate_external_bill(UUID, VARCHAR, DECIMAL, DATE)`
- `bms.validate_fee_calculation(UUID, UUID, DECIMAL, VARCHAR)`
- `bms.validate_range_check(DECIMAL, DECIMAL, DECIMAL)`
- `bms.validate_statistical(DECIMAL[], VARCHAR)`
- `bms.validate_tax_transaction_amounts(UUID, DECIMAL, DECIMAL, DECIMAL)`
- `bms.validate_zone_access(UUID, UUID, TIMESTAMP)`
- `bms.execute_fee_validation(UUID, UUID, VARCHAR)`
- `bms.execute_single_validation_rule(UUID, VARCHAR, JSONB)`

### 2. 번호 생성 함수 (14개)
- `bms.generate_accounting_entry_number(UUID)`
- `bms.generate_announcement_number(UUID)`
- `bms.generate_booking_number(UUID)`
- `bms.generate_budget_number(UUID)`
- `bms.generate_complaint_number(UUID)`
- `bms.generate_employee_number(UUID)`
- `bms.generate_incident_number(UUID)`
- `bms.generate_notification_number(UUID)`
- `bms.generate_patrol_number(UUID)`
- `bms.generate_report_number(UUID)`
- `bms.generate_tax_transaction_number(UUID)`
- `bms.generate_vat_return_number(UUID)`
- `bms.generate_visit_number(UUID)`
- `bms.generate_withholding_number(UUID)`

### 3. 시설 관리 함수 (19개)

#### 작업 지시서 관리 함수 (7개)
- `bms.create_work_order(UUID, VARCHAR, TEXT, VARCHAR, UUID, DATE)`
- `bms.update_work_order_status(UUID, VARCHAR, TEXT)`
- `bms.record_work_progress(UUID, INTEGER, TEXT, UUID)`
- `bms.get_work_orders(UUID, VARCHAR, DATE, DATE)`
- `bms.finalize_work_completion(UUID, TEXT, UUID)`
- `bms.update_work_progress(UUID, INTEGER, TEXT)`

#### 점검 및 유지보수 함수 (5개)
- `bms.start_inspection_execution(UUID, UUID, DATE)`
- `bms.update_inspection_schedule_after_completion(UUID, DATE, VARCHAR)`
- `bms.generate_due_inspections(UUID, DATE)`
- `bms.start_preventive_maintenance_execution(UUID, UUID, DATE)`
- `bms.schedule_asset_maintenance(UUID, UUID, DATE, VARCHAR)`

#### 고장 신고 관리 함수 (5개)
- `bms.get_fault_reports(UUID, VARCHAR, DATE, DATE)`
- `bms.escalate_fault_report(UUID, VARCHAR, TEXT)`
- `bms.update_fault_report_status(UUID, VARCHAR, TEXT)`
- `bms.submit_fault_report_feedback(UUID, INTEGER, TEXT)`

#### 자산 관리 함수 (2개)
- `bms.update_asset_status(UUID, VARCHAR, TEXT)`
- `bms.record_facility_monitoring(UUID, JSONB, TIMESTAMP)`

### 4. 요금 계산 및 청구 함수 (23개)

#### 요금 계산 함수 (12개)
- `bms.calculate_area_based_fee(UUID, DECIMAL, DECIMAL)`
- `bms.calculate_fee_amount(UUID, UUID, INTEGER, VARCHAR)`
- `bms.calculate_late_fee(DECIMAL, INTEGER, DECIMAL)` (3개 오버로드)
- `bms.calculate_proportional_allocation(DECIMAL, DECIMAL[], VARCHAR)`
- `bms.calculate_proportional_fee(DECIMAL, DECIMAL, DECIMAL)`
- `bms.calculate_tier_rate(DECIMAL, JSONB)`
- `bms.calculate_tiered_fee(DECIMAL, JSONB)`
- `bms.calculate_unit_total_fee(UUID, INTEGER, VARCHAR)`
- `bms.calculate_usage_amount(DECIMAL, DECIMAL, VARCHAR)`
- `bms.calculate_usage_based_fee(UUID, DECIMAL, DECIMAL)`
- `bms.calculate_withholding_amounts(UUID, DECIMAL)`
- `bms.recalculate_unit_fees(UUID, INTEGER, VARCHAR)`

#### 요금 정책 및 할인 함수 (6개)
- `bms.apply_discount(DECIMAL, VARCHAR, DECIMAL)`
- `bms.get_building_fee_items(UUID)`
- `bms.get_current_fee_item_price(UUID, DATE)`
- `bms.get_effective_fee_policy(UUID, DATE)`
- `bms.get_seasonal_rate_multiplier(DATE, VARCHAR)`
- `bms.get_time_rate_multiplier(TIME, VARCHAR)`

#### 청구 및 결제 함수 (5개)
- `bms.auto_approve_bill(UUID, VARCHAR)`
- `bms.generate_monthly_rental_charges(UUID, INTEGER, VARCHAR)`
- `bms.process_invoice_payment(UUID, DECIMAL, DATE, VARCHAR)`
- `bms.update_overdue_status(UUID, DATE)`
- `bms.create_overdue_notification(UUID, INTEGER)`

### 5. 계약 및 임대 관리 함수 (36개)

#### 계약 관리 함수 (13개)
- `bms.get_expiring_contracts(UUID, INTEGER)`
- `bms.update_contract_status(UUID, VARCHAR, TEXT)`
- `bms.execute_status_automation(UUID, VARCHAR)`
- `bms.execute_status_workflow(UUID, VARCHAR, VARCHAR)`
- `bms.process_contract_renewal(UUID, DATE, DECIMAL)`
- `bms.send_renewal_notice(UUID, INTEGER)`
- `bms.process_tenant_response(UUID, VARCHAR, TEXT)`
- `bms.create_lease_contract(UUID, UUID, UUID, DATE, DATE, DECIMAL)`
- `bms.create_contract_renewal_process(UUID, DATE)`
- `bms.complete_renewal_process(UUID, VARCHAR)`
- `bms.add_contract_party(UUID, UUID, VARCHAR, DATE)`
- `bms.apply_party_change(UUID, UUID, VARCHAR)`
- `bms.process_party_change(UUID, VARCHAR, TEXT)`

#### 보증금 관리 함수 (5개)
- `bms.process_deposit_receipt(UUID, DECIMAL, DATE, VARCHAR)`
- `bms.process_deposit_refund(UUID, DECIMAL, DATE, VARCHAR)`
- `bms.process_deposit_substitute(UUID, UUID, DECIMAL)`
- `bms.bulk_calculate_deposit_interest(UUID, DATE, DATE)`
- `bms.calculate_deposit_interest(UUID, DATE, DATE)`

#### 입주/퇴거 관리 함수 (8개)
- `bms.update_move_in_process_status(UUID, VARCHAR, TEXT)`
- `bms.update_move_out_process_status(UUID, VARCHAR, TEXT)`
- `bms.end_vacancy_tracking(UUID, DATE, VARCHAR)`
- `bms.update_prospect_status(UUID, VARCHAR, TEXT)`
- `bms.create_move_in_process(UUID, UUID, DATE)`
- `bms.create_move_out_process(UUID, UUID, DATE)`
- `bms.create_vacancy_tracking(UUID, DATE, VARCHAR)`
- `bms.create_prospect_inquiry(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.complete_facility_orientation(UUID, UUID, DATE)`
- `bms.complete_move_out_checklist_item(UUID, UUID, VARCHAR)`
- `bms.return_key_security_card(UUID, VARCHAR, DATE)`

#### 정산 관리 함수 (10개)
- `bms.recalculate_settlement_totals(UUID)`
- `bms.process_settlement_payment(UUID, DECIMAL, DATE)`
- `bms.resolve_settlement_dispute(UUID, VARCHAR, TEXT)`
- `bms.update_dispute_status(UUID, VARCHAR, TEXT)`
- `bms.create_settlement_process(UUID, UUID, DATE)`
- `bms.create_settlement_request(UUID, DECIMAL, TEXT)`
- `bms.create_settlement_notification(UUID, VARCHAR)`
- `bms.create_dispute_case(UUID, VARCHAR, TEXT)`
- `bms.calculate_settlement_amount(UUID, DATE)`
- `bms.calculate_settlement_amounts(UUID, DATE, DATE)`

---

## Phase 3: 시스템 관리 및 나머지 함수 (약 103개)

### 1. 재고 및 자재 관리 함수 (23개)

#### 재고 관리 함수 (8개)
- `bms.get_inventory_movement_history(UUID, DATE, DATE)`
- `bms.get_inventory_summary_by_location(UUID, UUID)`
- `bms.get_low_stock_report(UUID, INTEGER)`
- `bms.reserve_inventory(UUID, UUID, DECIMAL, VARCHAR)`
- `bms.create_inventory_receipt_transaction(UUID, UUID, DECIMAL, DECIMAL)`
- `bms.process_cycle_count_variance(UUID, DECIMAL, VARCHAR)`
- `bms.update_reorder_flags(UUID)`
- `bms.update_reservation_remaining_quantity(UUID, DECIMAL)`

#### 자재 관리 함수 (4개)
- `bms.get_materials(UUID, VARCHAR)`
- `bms.create_material(UUID, VARCHAR, VARCHAR, VARCHAR, DECIMAL)`
- `bms.add_work_order_material(UUID, UUID, DECIMAL, DECIMAL)`
- `bms.update_material_cost(UUID, DECIMAL, DATE)`

#### 공급업체 관리 함수 (5개)
- `bms.get_suppliers(UUID, VARCHAR)`
- `bms.create_supplier(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.get_material_suppliers(UUID, UUID)`
- `bms.add_material_supplier(UUID, UUID, DECIMAL, INTEGER)`
- `bms.get_supplier_performance_report(UUID, UUID, DATE, DATE)`

#### 구매 관리 함수 (6개)
- `bms.submit_purchase_request(UUID, UUID, DECIMAL, DATE, TEXT)`
- `bms.get_purchase_request_summary(UUID, DATE, DATE)`
- `bms.create_purchase_order_from_quotation(UUID, UUID, TEXT)`
- `bms.select_quotation(UUID, UUID, VARCHAR)`
- `bms.update_quotation_totals(UUID)`
- `bms.approve_purchase_invoice(UUID, UUID, DATE)`

### 2. 보안 및 접근 제어 함수 (14개)

#### 보안 관리 함수 (8개)
- `bms.create_security_incident(UUID, VARCHAR, VARCHAR, TEXT, VARCHAR)`
- `bms.create_security_zone(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR)`
- `bms.update_security_zone_path(UUID, VARCHAR)`
- `bms.register_security_device(UUID, VARCHAR, VARCHAR, VARCHAR, UUID)`
- `bms.update_device_status(UUID, VARCHAR, TEXT)`
- `bms.generate_security_alert(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.get_security_dashboard_data(UUID, DATE, DATE)`
- `bms.schedule_security_patrol(UUID, VARCHAR, VARCHAR, DATE, TIME)`

#### 방문자 관리 함수 (3개)
- `bms.register_visitor(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT)`
- `bms.visitor_check_in(UUID, UUID, TIMESTAMP, VARCHAR)`
- `bms.visitor_check_out(UUID, UUID, TIMESTAMP)`

#### 권한 및 세션 관리 함수 (3개)
- `bms.check_user_permission(UUID, VARCHAR, VARCHAR)` (2개 오버로드)
- `bms.create_user_session(UUID, VARCHAR, INET, TEXT)`

### 3. 안전 및 규정 준수 함수 (8개)

#### 안전 점검 함수 (5개)
- `bms.create_safety_inspection(UUID, VARCHAR, UUID, UUID, TEXT)`
- `bms.create_safety_inspection_schedule(UUID, VARCHAR, UUID, TEXT, VARCHAR)`
- `bms.complete_safety_inspection(UUID, VARCHAR, INTEGER, INTEGER)`
- `bms.get_safety_inspection_summary(UUID, DATE, DATE, UUID)`
- `bms.report_safety_incident(UUID, VARCHAR, VARCHAR, VARCHAR, TEXT)`

#### 규정 준수 함수 (3개)
- `bms.create_legal_compliance_requirement(UUID, VARCHAR, TEXT, DATE)`
- `bms.create_risk_assessment(UUID, VARCHAR, VARCHAR, TEXT, INTEGER)`
- `bms.create_prevention_measure(UUID, VARCHAR, TEXT, DATE, UUID)`

### 4. 마케팅 및 고객 관리 함수 (5개)

#### 마케팅 캠페인 함수 (4개)
- `bms.create_marketing_campaign(UUID, VARCHAR, TEXT, DATE, DATE)`
- `bms.update_campaign_performance(UUID, INTEGER, INTEGER, DECIMAL)`
- `bms.generate_pricing_strategy(UUID, UUID, VARCHAR)`
- `bms.calculate_optimal_rent(UUID, UUID, JSONB)`

#### 고객 만족도 관리 함수 (1개)
- `bms.create_satisfaction_survey(UUID, VARCHAR, JSONB, DATE)`

### 5. 보험 및 리스크 관리 함수 (1개)
- `bms.create_insurance_policy(UUID, VARCHAR, VARCHAR, DECIMAL, DATE, DATE)`

### 6. 외주 및 계약업체 관리 함수 (4개)
- `bms.create_outsourcing_work_request(UUID, VARCHAR, TEXT, DATE, DECIMAL)`
- `bms.assign_work_to_contractor(UUID, UUID, DATE, TEXT)`
- `bms.register_contractor(UUID, VARCHAR, VARCHAR, VARCHAR)` (2개 오버로드)

### 7. 분석 및 리포팅 함수 (6개)

#### 성과 분석 함수 (5개)
- `bms.analyze_facility_condition_trends(UUID, DATE, DATE)`
- `bms.analyze_maintenance_effectiveness(UUID, VARCHAR, DATE, DATE)`
- `bms.analyze_rent_performance(UUID, DATE, DATE)`
- `bms.calculate_asset_performance(UUID, UUID, DATE, DATE)`
- `bms.compare_period_performance(UUID, DATE, DATE, DATE, DATE)`

#### 업무 요약 함수 (1개)
- `bms.get_work_assignment_summary(UUID, DATE, DATE)`

### 8. 시스템 설정 및 초기화 함수 (16개)

#### 기본 데이터 생성 함수 (10개)
- `bms.create_default_common_codes(UUID)`
- `bms.create_default_roles(UUID)` (2개 오버로드)
- `bms.create_default_system_settings(UUID)`
- `bms.insert_default_account_codes(UUID)`
- `bms.insert_default_announcement_categories(UUID)`
- `bms.insert_default_complaint_categories(UUID)` (2개 오버로드)
- `bms.insert_default_services(UUID)`
- `bms.insert_default_tax_calculation_rules(UUID)`
- `bms.insert_default_transaction_categories(UUID)`

#### 시스템 설정 관리 함수 (6개)
- `bms.get_system_setting(UUID, VARCHAR)`
- `bms.get_setting_value(UUID, VARCHAR)` (2개 오버로드)
- `bms.update_setting_value(UUID, VARCHAR, VARCHAR)`
- `bms.get_json_setting(UUID, VARCHAR)`
- `bms.set_fiscal_period(UUID, DATE, DATE)`

### 9. 사용자 활동 및 보안 로그 함수 (17개)
- `bms.log_user_activity(UUID, VARCHAR, VARCHAR, TEXT)` (2개 오버로드)
- `bms.log_user_access(UUID, VARCHAR, INET, VARCHAR)` (2개 오버로드)
- `bms.log_security_event(UUID, VARCHAR, VARCHAR, TEXT)` (2개 오버로드)
- `bms.log_system_event(VARCHAR, VARCHAR, TEXT)` (2개 오버로드)
- `bms.log_data_change(UUID, VARCHAR, VARCHAR, JSONB, JSONB)`
- `bms.log_privacy_processing(UUID, VARCHAR, VARCHAR, TEXT)` (2개 오버로드)
- `bms.log_access_attempt(UUID, UUID, UUID, VARCHAR, VARCHAR)`
- `bms.log_building_changes(UUID, VARCHAR, JSONB, JSONB)`
- `bms.log_contract_status_changes(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.log_facility_status_changes(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.log_lessor_status_changes(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.log_system_setting_changes(UUID, VARCHAR, VARCHAR, VARCHAR)`
- `bms.log_tenant_status_changes(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.log_unit_status_changes(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.auto_audit_trigger()`

### 10. 기타 업무 프로세스 함수 (약 30개)

#### 예약 관리 함수 (3개)
- `bms.cancel_reservation(UUID, VARCHAR, TEXT)`
- `bms.fulfill_reservation(UUID, UUID, TIMESTAMP)`
- `bms.update_booking_timestamps(UUID, TIMESTAMP, TIMESTAMP)`

#### 불만 처리 함수 (2개)
- `bms.record_complaint_history(UUID, VARCHAR, TEXT, UUID)`
- `bms.set_complaint_sla(UUID, INTEGER, VARCHAR)`

#### 기타 업무 함수들 (25개)
- `bms.assign_incident_investigator(UUID, UUID, TEXT)`
- `bms.complete_patrol_checkpoint(UUID, UUID, TIMESTAMP, TEXT)`
- `bms.update_budget_execution(UUID, DECIMAL, DATE)`
- `bms.create_balance_adjustment(UUID, UUID, DECIMAL, VARCHAR, TEXT)`
- `bms.create_cost_settlement(UUID, UUID, DECIMAL, DATE)`
- `bms.create_refund_transaction(UUID, DECIMAL, VARCHAR, TEXT)`
- `bms.update_announcement_attachments_flag(UUID, BOOLEAN)`
- `bms.update_announcement_view_count(UUID)`
- `bms.apply_auto_fix(UUID, VARCHAR, JSONB)`
- `bms.apply_status_change(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.check_sla_breach(UUID, TIMESTAMP, INTEGER)`
- `bms.complete_checklist_item(UUID, UUID, VARCHAR, TEXT)`
- `bms.create_completion_inspection(UUID, UUID, DATE, TEXT)`
- `bms.create_completion_report(UUID, TEXT, JSONB, UUID)`
- `bms.create_party_relationship(UUID, UUID, VARCHAR, DATE)`
- `bms.create_status_approval_request(UUID, VARCHAR, VARCHAR, UUID)`
- `bms.create_work_inspection(UUID, UUID, DATE, TEXT)`
- `bms.create_work_warranty(UUID, INTEGER, TEXT, DATE)`
- `bms.detect_reading_anomaly(DECIMAL, DECIMAL[], VARCHAR)`
- `bms.evaluate_party_credit(UUID, JSONB)`
- `bms.execute_usage_allocation(UUID, UUID, DECIMAL, VARCHAR)`
- `bms.process_status_approval(UUID, VARCHAR, TEXT, UUID)`
- `bms.send_status_notification(UUID, VARCHAR, VARCHAR, TEXT)`
- `bms.update_assessment_damage_costs(UUID, DECIMAL, TEXT)`
- `bms.update_updated_at_column()`

---

## 삭제 요약

### 총 삭제 대상: 271개 함수
- **Phase 1**: 18개 (테스트 관련)
- **Phase 2**: 약 150개 (비즈니스 로직)
- **Phase 3**: 약 103개 (시스템 관리 및 나머지)

### 백엔드 서비스 이관 매핑
- **DataIntegrityService**: 23개 함수
- **NumberGenerationService**: 14개 함수
- **FacilityService**: 19개 함수
- **BillingService**: 23개 함수
- **LeaseService**: 36개 함수
- **InventoryService**: 23개 함수
- **SecurityService**: 14개 함수
- **SafetyComplianceService**: 8개 함수
- **MarketingService**: 5개 함수
- **InsuranceService**: 1개 함수
- **ContractorService**: 4개 함수
- **AnalyticsService**: 6개 함수
- **SystemInitializationService**: 16개 함수
- **AuditService**: 17개 함수
- **기타 서비스들**: 약 82개 함수

### 삭제 후 예상 효과
1. **코드 관리 개선**: 비즈니스 로직의 중앙화 및 버전 관리 용이성
2. **성능 향상**: 애플리케이션 레벨 캐싱 및 연결 풀 최적화
3. **유지보수성 향상**: IDE 지원 및 단위 테스트 작성 용이
4. **확장성 개선**: 마이크로서비스 아키텍처 적합성
5. **보안 강화**: 애플리케이션 레벨 보안 정책 적용

---

## 주의사항
- 모든 함수 삭제 전 반드시 전체 데이터베이스 백업 수행
- 백엔드 서비스 구현 및 테스트 완료 확인
- 단계별 실행으로 문제 발생 시 롤백 가능
- 각 Phase 완료 후 시스템 정상 동작 확인 필수