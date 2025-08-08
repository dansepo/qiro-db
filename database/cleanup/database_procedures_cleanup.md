# 데이터베이스 프로시저 정리 계획

## 개요
백엔드 서비스로 이관 완료 후 삭제할 데이터베이스 프로시저 및 함수 목록입니다.
실제 서버(qiro_dev)에서 확인된 271개의 bms 스키마 함수를 기준으로 작성되었습니다.

## 삭제 대상 프로시저/함수 목록 (실제 서버 기준 - 2024.07.30 확인)

### 1. 데이터 무결성 및 검증 함수 (→ DataIntegrityService로 이관)

#### 1.1 공통 코드 관리 함수
- `bms.get_code_name()` → `CommonCodeService.getCodeName()`
- `bms.get_codes_by_group()` → `CommonCodeService.getCodesByGroup()`
- `bms.validate_common_code_data()` → `DataIntegrityService.validateCommonCode()`

#### 1.2 데이터 검증 함수들
- `bms.validate_business_registration_number()` → `DataIntegrityService.validateBusinessRegistrationNumber()`
- `public.validate_business_registration_number()` → `DataIntegrityService.validateBusinessRegistrationNumber()`
- `bms.validate_building_data()` → `DataIntegrityService.validateBuildingData()`
- `bms.validate_contract_data()` → `DataIntegrityService.validateContractData()`
- `bms.validate_facility_data()` → `DataIntegrityService.validateFacilityData()`
- `bms.validate_fee_item_data()` → `DataIntegrityService.validateFeeItemData()`
- `bms.validate_lessor_data()` → `DataIntegrityService.validateLessorData()`
- `bms.validate_tenant_data()` → `DataIntegrityService.validateTenantData()`
- `bms.validate_unit_data()` → `DataIntegrityService.validateUnitData()`
- `bms.validate_system_setting_data()` → `DataIntegrityService.validateSystemSettingData()`
- `bms.validate_basic_check()` → `DataIntegrityService.validateBasicCheck()`
- `bms.validate_comparison()` → `DataIntegrityService.validateComparison()`
- `bms.validate_external_bill()` → `DataIntegrityService.validateExternalBill()`
- `bms.validate_fee_calculation()` → `DataIntegrityService.validateFeeCalculation()`
- `bms.validate_range_check()` → `DataIntegrityService.validateRangeCheck()`
- `bms.validate_statistical()` → `DataIntegrityService.validateStatistical()`
- `bms.validate_tax_transaction_amounts()` → `DataIntegrityService.validateTaxTransactionAmounts()`
- `bms.validate_zone_access()` → `DataIntegrityService.validateZoneAccess()`
- `bms.execute_fee_validation()` → `DataIntegrityService.executeFeeValidation()`
- `bms.execute_single_validation_rule()` → `DataIntegrityService.executeSingleValidationRule()`

#### 1.3 사용자 활동 및 보안 로그 함수
- `bms.log_user_activity()` (2개 오버로드) → `AuditService.logUserActivity()`
- `bms.log_user_access()` (2개 오버로드) → `AuditService.logUserAccess()`
- `bms.log_security_event()` (2개 오버로드) → `AuditService.logSecurityEvent()`
- `bms.log_system_event()` (2개 오버로드) → `AuditService.logSystemEvent()`
- `bms.log_data_change()` → `AuditService.logDataChange()`
- `bms.log_privacy_processing()` (2개 오버로드) → `AuditService.logPrivacyProcessing()`
- `bms.log_access_attempt()` → `AuditService.logAccessAttempt()`
- `bms.log_building_changes()` → `AuditService.logBuildingChanges()`
- `bms.log_contract_status_changes()` → `AuditService.logContractStatusChanges()`
- `bms.log_facility_status_changes()` → `AuditService.logFacilityStatusChanges()`
- `bms.log_lessor_status_changes()` → `AuditService.logLessorStatusChanges()`
- `bms.log_system_setting_changes()` → `AuditService.logSystemSettingChanges()`
- `bms.log_tenant_status_changes()` → `AuditService.logTenantStatusChanges()`
- `bms.log_unit_status_changes()` → `AuditService.logUnitStatusChanges()`
- `bms.auto_audit_trigger()` → `AuditService.autoAuditTrigger()`

### 2. 성능 모니터링 및 테스트 함수 (→ PerformanceMonitoringService로 이관)

#### 2.1 성능 테스트 함수
- `bms.test_partition_performance()` → `PerformanceMonitoringService.testPartitionPerformance()`
- `bms.test_company_data_isolation()` → `PerformanceMonitoringService.testDataIsolation()`
- `bms.test_user_permissions()` → `PerformanceMonitoringService.testUserPermissions()`
- `bms.run_multitenancy_isolation_tests()` → `PerformanceMonitoringService.runIsolationTests()`

#### 2.2 통계 및 모니터링 함수
- `bms.get_audit_statistics()` → `PerformanceMonitoringService.getAuditStatistics()`
- `bms.get_completion_statistics()` → `PerformanceMonitoringService.getCompletionStatistics()`
- `bms.get_fault_report_statistics()` → `PerformanceMonitoringService.getFaultReportStatistics()`
- `bms.get_work_order_statistics()` → `PerformanceMonitoringService.getWorkOrderStatistics()`
- `bms.get_material_statistics()` → `PerformanceMonitoringService.getMaterialStatistics()`
- `bms.get_partition_stats()` → `PerformanceMonitoringService.getPartitionStats()`
- `bms.get_validation_summary()` → `PerformanceMonitoringService.getValidationSummary()`

#### 2.3 시스템 유지보수 및 정리 함수
- `bms.cleanup_audit_logs()` → `PerformanceMonitoringService.cleanupAuditLogs()`
- `bms.cleanup_expired_sessions()` → `PerformanceMonitoringService.cleanupExpiredSessions()`
- `bms.cleanup_multitenancy_test_data()` → `PerformanceMonitoringService.cleanupTestData()`
- `bms.archive_old_partitions()` → `PerformanceMonitoringService.archiveOldPartitions()`
- `bms.annual_archive_maintenance()` → `PerformanceMonitoringService.annualArchiveMaintenance()`
- `bms.create_monthly_partitions()` → `PerformanceMonitoringService.createMonthlyPartitions()`

### 3. 테스트 데이터 생성 함수 (→ TestExecutionService로 이관)

#### 3.1 테스트 데이터 생성 함수
- `bms.generate_test_companies()` → `TestExecutionService.generateTestCompanies()`

### 4. 번호 생성 함수 (→ NumberGenerationService로 이관)

#### 4.1 각종 번호 생성 함수들
- `bms.generate_accounting_entry_number()` → `NumberGenerationService.generateAccountingEntryNumber()`
- `bms.generate_announcement_number()` → `NumberGenerationService.generateAnnouncementNumber()`
- `bms.generate_booking_number()` → `NumberGenerationService.generateBookingNumber()`
- `bms.generate_budget_number()` → `NumberGenerationService.generateBudgetNumber()`
- `bms.generate_complaint_number()` → `NumberGenerationService.generateComplaintNumber()`
- `bms.generate_employee_number()` → `NumberGenerationService.generateEmployeeNumber()`
- `bms.generate_incident_number()` → `NumberGenerationService.generateIncidentNumber()`
- `bms.generate_notification_number()` → `NumberGenerationService.generateNotificationNumber()`
- `bms.generate_patrol_number()` → `NumberGenerationService.generatePatrolNumber()`
- `bms.generate_report_number()` → `NumberGenerationService.generateReportNumber()`
- `bms.generate_tax_transaction_number()` → `NumberGenerationService.generateTaxTransactionNumber()`
- `bms.generate_vat_return_number()` → `NumberGenerationService.generateVatReturnNumber()`
- `bms.generate_visit_number()` → `NumberGenerationService.generateVisitNumber()`
- `bms.generate_withholding_number()` → `NumberGenerationService.generateWithholdingNumber()`

### 5. 시설 관리 함수 (→ FacilityService로 이관)

#### 5.1 작업 지시서 관리 함수
- `bms.create_work_order()` → `WorkOrderService.createWorkOrder()`
- `bms.update_work_order_status()` → `WorkOrderService.updateStatus()`
- `bms.record_work_progress()` → `WorkOrderService.recordProgress()`
- `bms.get_work_orders()` → `WorkOrderService.getWorkOrders()`
- `bms.get_work_order_statistics()` → `WorkOrderService.getStatistics()`
- `bms.finalize_work_completion()` → `WorkOrderService.finalizeCompletion()`
- `bms.update_work_progress()` → `WorkOrderService.updateProgress()`

#### 5.2 점검 및 유지보수 함수
- `bms.start_inspection_execution()` → `InspectionService.startExecution()`
- `bms.update_inspection_schedule_after_completion()` → `InspectionService.updateScheduleAfterCompletion()`
- `bms.generate_due_inspections()` → `InspectionService.generateDueInspections()`
- `bms.start_preventive_maintenance_execution()` → `MaintenanceService.startPreventiveExecution()`
- `bms.schedule_asset_maintenance()` → `MaintenanceService.scheduleAssetMaintenance()`

#### 5.3 고장 신고 관리 함수
- `bms.get_fault_reports()` → `FaultReportService.getFaultReports()`
- `bms.get_fault_report_statistics()` → `FaultReportService.getStatistics()`
- `bms.escalate_fault_report()` → `FaultReportService.escalateFaultReport()`
- `bms.update_fault_report_status()` → `FaultReportService.updateStatus()`
- `bms.submit_fault_report_feedback()` → `FaultReportService.submitFeedback()`

#### 5.4 자산 관리 함수
- `bms.update_asset_status()` → `AssetService.updateStatus()`
- `bms.record_facility_monitoring()` → `AssetService.recordMonitoring()`

### 6. 요금 계산 및 청구 함수 (→ BillingService로 이관)

#### 6.1 요금 계산 함수
- `bms.calculate_area_based_fee()` → `BillingService.calculateAreaBasedFee()`
- `bms.calculate_fee_amount()` → `BillingService.calculateFeeAmount()`
- `bms.calculate_late_fee()` (3개 오버로드) → `BillingService.calculateLateFee()`
- `bms.calculate_proportional_allocation()` → `BillingService.calculateProportionalAllocation()`
- `bms.calculate_proportional_fee()` → `BillingService.calculateProportionalFee()`
- `bms.calculate_tier_rate()` → `BillingService.calculateTierRate()`
- `bms.calculate_tiered_fee()` → `BillingService.calculateTieredFee()`
- `bms.calculate_unit_total_fee()` → `BillingService.calculateUnitTotalFee()`
- `bms.calculate_usage_amount()` → `BillingService.calculateUsageAmount()`
- `bms.calculate_usage_based_fee()` → `BillingService.calculateUsageBasedFee()`
- `bms.calculate_withholding_amounts()` → `BillingService.calculateWithholdingAmounts()`
- `bms.recalculate_unit_fees()` → `BillingService.recalculateUnitFees()`

#### 6.2 요금 정책 및 할인 함수
- `bms.apply_discount()` → `BillingService.applyDiscount()`
- `bms.get_building_fee_items()` → `BillingService.getBuildingFeeItems()`
- `bms.get_current_fee_item_price()` → `BillingService.getCurrentFeeItemPrice()`
- `bms.get_effective_fee_policy()` → `BillingService.getEffectiveFeePolicy()`
- `bms.get_seasonal_rate_multiplier()` → `BillingService.getSeasonalRateMultiplier()`
- `bms.get_time_rate_multiplier()` → `BillingService.getTimeRateMultiplier()`

#### 6.3 청구 및 결제 함수
- `bms.auto_approve_bill()` → `BillingService.autoApproveBill()`
- `bms.generate_monthly_rental_charges()` → `BillingService.generateMonthlyRentalCharges()`
- `bms.process_invoice_payment()` → `BillingService.processInvoicePayment()`
- `bms.update_overdue_status()` → `BillingService.updateOverdueStatus()`
- `bms.create_overdue_notification()` → `BillingService.createOverdueNotification()`

### 7. 계약 및 임대 관리 함수 (→ LeaseService로 이관)

#### 6.1 계약 관리 함수
- `bms.get_expiring_contracts()` → `LeaseService.getExpiringContracts()`
- `bms.update_contract_status()` → `LeaseService.updateContractStatus()`
- `bms.execute_status_automation()` → `LeaseService.executeStatusAutomation()`
- `bms.execute_status_workflow()` → `LeaseService.executeStatusWorkflow()`
- `bms.process_contract_renewal()` → `LeaseService.processContractRenewal()`
- `bms.send_renewal_notice()` → `LeaseService.sendRenewalNotice()`
- `bms.process_tenant_response()` → `LeaseService.processTenantResponse()`
- `bms.create_lease_contract()` → `LeaseService.createLeaseContract()`
- `bms.create_contract_renewal_process()` → `LeaseService.createRenewalProcess()`
- `bms.complete_renewal_process()` → `LeaseService.completeRenewalProcess()`
- `bms.add_contract_party()` → `LeaseService.addContractParty()`
- `bms.apply_party_change()` → `LeaseService.applyPartyChange()`
- `bms.process_party_change()` → `LeaseService.processPartyChange()`

#### 6.2 보증금 관리 함수
- `bms.process_deposit_receipt()` → `DepositService.processReceipt()`
- `bms.process_deposit_refund()` → `DepositService.processRefund()`
- `bms.process_deposit_substitute()` → `DepositService.processSubstitute()`
- `bms.bulk_calculate_deposit_interest()` → `DepositService.bulkCalculateInterest()`
- `bms.calculate_deposit_interest()` → `DepositService.calculateInterest()`

#### 6.3 입주/퇴거 관리 함수
- `bms.update_move_in_process_status()` → `MoveService.updateMoveInStatus()`
- `bms.update_move_out_process_status()` → `MoveService.updateMoveOutStatus()`
- `bms.end_vacancy_tracking()` → `VacancyService.endVacancyTracking()`
- `bms.update_prospect_status()` → `ProspectService.updateStatus()`
- `bms.create_move_in_process()` → `MoveService.createMoveInProcess()`
- `bms.create_move_out_process()` → `MoveService.createMoveOutProcess()`
- `bms.create_vacancy_tracking()` → `VacancyService.createVacancyTracking()`
- `bms.create_prospect_inquiry()` → `ProspectService.createInquiry()`
- `bms.complete_facility_orientation()` → `MoveService.completeFacilityOrientation()`
- `bms.complete_move_out_checklist_item()` → `MoveService.completeMoveOutChecklistItem()`
- `bms.return_key_security_card()` → `MoveService.returnKeySecurityCard()`

#### 6.4 정산 관리 함수
- `bms.recalculate_settlement_totals()` → `SettlementService.recalculateTotals()`
- `bms.process_settlement_payment()` → `SettlementService.processPayment()`
- `bms.resolve_settlement_dispute()` → `SettlementService.resolveDispute()`
- `bms.update_dispute_status()` → `SettlementService.updateDisputeStatus()`
- `bms.create_settlement_process()` → `SettlementService.createProcess()`
- `bms.create_settlement_request()` → `SettlementService.createRequest()`
- `bms.create_settlement_notification()` → `SettlementService.createNotification()`
- `bms.create_dispute_case()` → `SettlementService.createDisputeCase()`
- `bms.calculate_settlement_amount()` → `SettlementService.calculateAmount()`
- `bms.calculate_settlement_amounts()` → `SettlementService.calculateAmounts()`

### 8. 재고 및 자재 관리 함수 (→ InventoryService로 이관)

#### 8.1 재고 관리 함수
- `bms.get_inventory_movement_history()` → `InventoryService.getMovementHistory()`
- `bms.get_inventory_summary_by_location()` → `InventoryService.getSummaryByLocation()`
- `bms.get_low_stock_report()` → `InventoryService.getLowStockReport()`
- `bms.reserve_inventory()` → `InventoryService.reserveInventory()`
- `bms.create_inventory_receipt_transaction()` → `InventoryService.createReceiptTransaction()`
- `bms.process_cycle_count_variance()` → `InventoryService.processCycleCountVariance()`
- `bms.update_reorder_flags()` → `InventoryService.updateReorderFlags()`
- `bms.update_reservation_remaining_quantity()` → `InventoryService.updateReservationRemainingQuantity()`

#### 8.2 자재 관리 함수
- `bms.get_materials()` → `MaterialService.getMaterials()`
- `bms.create_material()` → `MaterialService.createMaterial()`
- `bms.add_work_order_material()` → `MaterialService.addWorkOrderMaterial()`
- `bms.update_material_cost()` → `MaterialService.updateMaterialCost()`

#### 8.3 공급업체 관리 함수
- `bms.get_suppliers()` → `SupplierService.getSuppliers()`
- `bms.create_supplier()` → `SupplierService.createSupplier()`
- `bms.get_material_suppliers()` → `SupplierService.getMaterialSuppliers()`
- `bms.add_material_supplier()` → `SupplierService.addMaterialSupplier()`
- `bms.get_supplier_performance_report()` → `SupplierService.getPerformanceReport()`

#### 8.4 구매 관리 함수
- `bms.submit_purchase_request()` → `PurchaseService.submitRequest()`
- `bms.get_purchase_request_summary()` → `PurchaseService.getRequestSummary()`
- `bms.create_purchase_order_from_quotation()` → `PurchaseService.createOrderFromQuotation()`
- `bms.select_quotation()` → `PurchaseService.selectQuotation()`
- `bms.update_quotation_totals()` → `PurchaseService.updateQuotationTotals()`
- `bms.approve_purchase_invoice()` → `PurchaseService.approveInvoice()`

### 9. 보안 및 접근 제어 함수 (→ SecurityService로 이관)

#### 9.1 보안 관리 함수
- `bms.create_security_incident()` → `SecurityService.createIncident()`
- `bms.create_security_zone()` → `SecurityService.createZone()`
- `bms.update_security_zone_path()` → `SecurityService.updateZonePath()`
- `bms.register_security_device()` → `SecurityService.registerDevice()`
- `bms.update_device_status()` → `SecurityService.updateDeviceStatus()`
- `bms.generate_security_alert()` → `SecurityService.generateAlert()`
- `bms.get_security_dashboard_data()` → `SecurityService.getDashboardData()`
- `bms.schedule_security_patrol()` → `SecurityService.schedulePatrol()`

#### 9.2 방문자 관리 함수
- `bms.register_visitor()` → `VisitorService.registerVisitor()`
- `bms.visitor_check_in()` → `VisitorService.checkIn()`
- `bms.visitor_check_out()` → `VisitorService.checkOut()`

#### 9.3 권한 및 세션 관리 함수
- `bms.check_user_permission()` (2개 오버로드) → `SecurityService.checkUserPermission()`
- `bms.create_user_session()` → `SecurityService.createUserSession()`

### 10. 안전 및 규정 준수 함수 (→ SafetyComplianceService로 이관)

#### 10.1 안전 점검 함수
- `bms.create_safety_inspection()` → `SafetyService.createInspection()`
- `bms.create_safety_inspection_schedule()` → `SafetyService.createInspectionSchedule()`
- `bms.complete_safety_inspection()` → `SafetyService.completeInspection()`
- `bms.get_safety_inspection_summary()` → `SafetyService.getInspectionSummary()`
- `bms.report_safety_incident()` → `SafetyService.reportIncident()`

#### 10.2 규정 준수 함수
- `bms.create_legal_compliance_requirement()` → `ComplianceService.createLegalRequirement()`
- `bms.create_risk_assessment()` → `ComplianceService.createRiskAssessment()`
- `bms.create_prevention_measure()` → `ComplianceService.createPreventionMeasure()`

### 11. 마케팅 및 고객 관리 함수 (→ MarketingService로 이관)

#### 11.1 마케팅 캠페인 함수
- `bms.create_marketing_campaign()` → `MarketingService.createCampaign()`
- `bms.update_campaign_performance()` → `MarketingService.updateCampaignPerformance()`
- `bms.generate_pricing_strategy()` → `MarketingService.generatePricingStrategy()`
- `bms.calculate_optimal_rent()` → `MarketingService.calculateOptimalRent()`

#### 11.2 고객 만족도 관리 함수
- `bms.create_satisfaction_survey()` → `CustomerService.createSatisfactionSurvey()`

### 12. 보험 및 리스크 관리 함수 (→ InsuranceService로 이관)

#### 12.1 보험 관리 함수
- `bms.create_insurance_policy()` → `InsuranceService.createPolicy()`

### 13. 외주 및 계약업체 관리 함수 (→ ContractorService로 이관)

#### 13.1 외주 관리 함수
- `bms.create_outsourcing_work_request()` → `ContractorService.createOutsourcingRequest()`
- `bms.assign_work_to_contractor()` → `ContractorService.assignWork()`
- `bms.register_contractor()` (2개 오버로드) → `ContractorService.registerContractor()`

### 14. 분석 및 리포팅 함수 (→ AnalyticsService로 이관)

#### 14.1 성과 분석 함수
- `bms.analyze_facility_condition_trends()` → `AnalyticsService.analyzeFacilityConditionTrends()`
- `bms.analyze_maintenance_effectiveness()` → `AnalyticsService.analyzeMaintenanceEffectiveness()`
- `bms.analyze_rent_performance()` → `AnalyticsService.analyzeRentPerformance()`
- `bms.calculate_asset_performance()` → `AnalyticsService.calculateAssetPerformance()`
- `bms.compare_period_performance()` → `AnalyticsService.comparePeriodPerformance()`

#### 14.2 업무 요약 함수
- `bms.get_work_assignment_summary()` → `AnalyticsService.getWorkAssignmentSummary()`

### 15. 시스템 설정 및 초기화 함수 (→ SystemInitializationService로 이관)

#### 15.1 기본 데이터 생성 함수
- `bms.create_default_common_codes()` → `SystemInitializationService.createDefaultCommonCodes()`
- `bms.create_default_roles()` (2개 오버로드) → `SystemInitializationService.createDefaultRoles()`
- `bms.create_default_system_settings()` → `SystemInitializationService.createDefaultSystemSettings()`
- `bms.insert_default_account_codes()` → `SystemInitializationService.insertDefaultAccountCodes()`
- `bms.insert_default_announcement_categories()` → `SystemInitializationService.insertDefaultAnnouncementCategories()`
- `bms.insert_default_complaint_categories()` (2개 오버로드) → `SystemInitializationService.insertDefaultComplaintCategories()`
- `bms.insert_default_services()` → `SystemInitializationService.insertDefaultServices()`
- `bms.insert_default_tax_calculation_rules()` → `SystemInitializationService.insertDefaultTaxCalculationRules()`
- `bms.insert_default_transaction_categories()` → `SystemInitializationService.insertDefaultTransactionCategories()`

#### 15.2 시스템 설정 관리 함수
- `bms.get_system_setting()` → `SystemSettingService.getSystemSetting()`
- `bms.get_setting_value()` (2개 오버로드) → `SystemSettingService.getSettingValue()`
- `bms.update_setting_value()` → `SystemSettingService.updateSettingValue()`
- `bms.get_json_setting()` → `SystemSettingService.getJsonSetting()`
- `bms.set_fiscal_period()` → `SystemSettingService.setFiscalPeriod()`

### 16. 기타 업무 프로세스 함수 (→ 각 해당 서비스로 이관)

#### 16.1 예약 관리 함수
- `bms.cancel_reservation()` → `ReservationService.cancelReservation()`
- `bms.fulfill_reservation()` → `ReservationService.fulfillReservation()`
- `bms.update_booking_timestamps()` → `ReservationService.updateBookingTimestamps()`

#### 16.2 불만 처리 함수
- `bms.record_complaint_history()` → `ComplaintService.recordHistory()`
- `bms.set_complaint_sla()` → `ComplaintService.setComplaintSla()`

#### 16.3 사건 관리 함수
- `bms.assign_incident_investigator()` → `IncidentService.assignInvestigator()`

#### 16.4 순찰 관리 함수
- `bms.complete_patrol_checkpoint()` → `PatrolService.completeCheckpoint()`

#### 16.5 예산 관리 함수
- `bms.update_budget_execution()` → `BudgetService.updateExecution()`

#### 16.6 회계 관리 함수
- `bms.create_balance_adjustment()` → `AccountingService.createBalanceAdjustment()`
- `bms.create_cost_settlement()` → `AccountingService.createCostSettlement()`
- `bms.create_refund_transaction()` → `AccountingService.createRefundTransaction()`

#### 16.7 공지사항 관리 함수
- `bms.update_announcement_attachments_flag()` → `AnnouncementService.updateAttachmentsFlag()`
- `bms.update_announcement_view_count()` → `AnnouncementService.updateViewCount()`

#### 16.8 기타 업무 함수
- `bms.apply_auto_fix()` → `AutomationService.applyAutoFix()`
- `bms.apply_status_change()` → `StatusService.applyStatusChange()`
- `bms.check_sla_breach()` → `SlaService.checkSlaBreach()`
- `bms.complete_checklist_item()` → `ChecklistService.completeItem()`
- `bms.create_completion_inspection()` → `InspectionService.createCompletionInspection()`
- `bms.create_completion_report()` → `ReportService.createCompletionReport()`
- `bms.create_party_relationship()` → `PartyService.createRelationship()`
- `bms.create_status_approval_request()` → `ApprovalService.createStatusApprovalRequest()`
- `bms.create_work_inspection()` → `InspectionService.createWorkInspection()`
- `bms.create_work_warranty()` → `WarrantyService.createWorkWarranty()`
- `bms.detect_reading_anomaly()` → `MonitoringService.detectReadingAnomaly()`
- `bms.evaluate_party_credit()` → `CreditService.evaluatePartyCredit()`
- `bms.execute_usage_allocation()` → `AllocationService.executeUsageAllocation()`
- `bms.process_status_approval()` → `ApprovalService.processStatusApproval()`
- `bms.send_status_notification()` → `NotificationService.sendStatusNotification()`
- `bms.update_assessment_damage_costs()` → `AssessmentService.updateDamageCosts()`
- `bms.update_updated_at_column()` → `DatabaseService.updateUpdatedAtColumn()`

## 삭제 실행 계획

### Phase 1: 백엔드 서비스 구현 완료 확인
1. 모든 백엔드 서비스가 구현되고 테스트 완료
2. 프로시저 기능이 백엔드에서 정상 동작 확인
3. 성능 비교 테스트 실행

### Phase 2: 단계적 프로시저 제거
1. **1단계**: 테스트 관련 함수 제거
   - 통합 테스트 함수들
   - 성능 테스트 함수들
   - 테스트 데이터 생성 함수들

2. **2단계**: 비즈니스 로직 함수 제거
   - 시설 관리 함수들
   - 데이터 검증 함수들
   - 공통 코드 함수들

3. **3단계**: 시스템 관리 함수 제거
   - 파티셔닝 관리 함수들
   - 인덱스 관리 함수들
   - 성능 모니터링 함수들

### Phase 3: 정리 및 검증
1. 삭제된 함수들의 의존성 확인
2. 남은 SQL 스크립트 정리
3. 데이터베이스 스키마 최적화

## 삭제 스크립트 생성

각 Phase별로 삭제 스크립트를 생성하여 안전하게 제거할 예정입니다.

### 주의사항
- 프로덕션 환경에서는 백업 후 실행
- 단계별 실행으로 롤백 가능하도록 구성
- 각 단계마다 기능 테스트 실행
- 의존성이 있는 함수들은 순서를 고려하여 삭제

## 예상 효과

### 1. 코드 관리 개선
- 비즈니스 로직의 중앙화
- 버전 관리 용이성
- 코드 리뷰 프로세스 개선

### 2. 성능 향상
- 애플리케이션 레벨 캐싱 활용
- 연결 풀 최적화
- 메모리 사용량 최적화

### 3. 유지보수성 향상
- IDE 지원을 통한 개발 효율성
- 단위 테스트 작성 용이
- 디버깅 및 프로파일링 개선

### 4. 확장성 개선
- 마이크로서비스 아키텍처 적합
- 수평적 확장 용이
- 클라우드 네이티브 환경 최적화