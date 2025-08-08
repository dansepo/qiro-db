# Phase 2: 도메인별 파일 이동 실행

## 작업 개요
- **목표**: Migration 패키지의 유용한 파일들을 적절한 도메인으로 이동
- **대상**: 49개 파일
- **작업 일시**: 2025-01-08

## 이동 계획

### 1. Common 서비스로 이동 (8개)
- Controller: DataIntegrityController.kt, SystemInitializationController.kt, NumberGenerationController.kt
- DTO: CommonCodeDto.kt, SystemInitializationDto.kt
- Entity: CodeGroup.kt, CommonCode.kt
- Repository: CodeGroupRepository.kt, CommonCodeRepository.kt
- Common: BaseService.kt

### 2. Billing 도메인으로 이동 (5개)
- Controller: BillingController.kt
- DTO: BillingDto.kt
- Entity: MonthlyFeeCalculation.kt
- Repository: MonthlyFeeCalculationRepository.kt, UnitMonthlyFeeRepository.kt, MaintenanceFeeItemRepository.kt, FeeCalculationLogRepository.kt, PaymentTransactionRepository.kt

### 3. Facility 도메인으로 이동 (6개)
- Controller: FacilityController.kt
- DTO: FacilityDto.kt
- Entity: FacilityAsset.kt, FaultReport.kt, WorkOrder.kt
- Repository: FacilityAssetRepository.kt, FaultReportRepository.kt, WorkOrderRepository.kt

### 4. Security 도메인으로 이동 (8개)
- Controller: SecurityController.kt
- DTO: SecurityDto.kt
- Entity: Security.kt
- Repository: SecurityDeviceRepository.kt, SecurityIncidentRepository.kt, SecurityPatrolRepository.kt, SecurityZoneRepository.kt, VisitorManagementRepository.kt, AccessControlRecordRepository.kt

### 5. 기타 도메인들 (22개)
- Lease, Dashboard, Inventory, Safety, Common 등

## 실행 로그