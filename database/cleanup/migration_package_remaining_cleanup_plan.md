# Migration 패키지 남은 파일들 정리 계획

## 현황 분석
- **총 남은 파일**: 64개
- **디렉토리**: 7개 (common, config, controller, dto, entity, exception, repository)
- **상태**: 서비스 레이어만 정리 완료, 나머지 레이어 정리 필요

## 정리 전략

### 1. 즉시 삭제 대상 (Migration 전용)
이들은 프로시저 이관 과정에서만 사용된 임시 파일들로 더 이상 필요하지 않습니다.

#### 1.1 Migration 전용 Controller (3개)
- `MigrationController.kt` - 이관 프로세스 관리용
- `TestExecutionController.kt` - 테스트 실행용
- `TestRunnerController.kt` - 테스트 러너용

#### 1.2 Migration 전용 Entity (3개)
- `MigrationWorkLog.kt` - 이관 작업 로그
- `PerformanceTestResult.kt` - 성능 테스트 결과
- `ProcedureMigrationLog.kt` - 프로시저 이관 로그

#### 1.3 Migration 전용 Repository (3개)
- `MigrationWorkLogRepository.kt`
- `PerformanceTestResultRepository.kt`
- `ProcedureMigrationLogRepository.kt`

#### 1.4 Migration 전용 DTO (2개)
- `PerformanceResult.kt`
- `ValidationResult.kt`

#### 1.5 Migration 전용 Exception (2개)
- `GlobalMigrationExceptionHandler.kt`
- `ProcedureMigrationException.kt`

#### 1.6 Migration 전용 Config (2개)
- `CacheConfig.kt` - 이관용 캐시 설정
- `MigrationTransactionConfig.kt` - 이관용 트랜잭션 설정

**삭제 대상 소계: 15개 파일**

### 2. 도메인별 이동 대상 (49개)

#### 2.1 Common 서비스로 이동 (8개)
- **Controller**: `DataIntegrityController.kt`, `SystemInitializationController.kt`, `NumberGenerationController.kt`
- **DTO**: `CommonCodeDto.kt`, `SystemInitializationDto.kt`
- **Entity**: `CodeGroup.kt`, `CommonCode.kt`
- **Repository**: `CodeGroupRepository.kt`, `CommonCodeRepository.kt`
- **Common**: `BaseService.kt`

#### 2.2 Billing 도메인으로 이동 (5개)
- **Controller**: `BillingController.kt`
- **DTO**: `BillingDto.kt`
- **Entity**: `MonthlyFeeCalculation.kt`
- **Repository**: `MonthlyFeeCalculationRepository.kt`, `UnitMonthlyFeeRepository.kt`, `MaintenanceFeeItemRepository.kt`, `FeeCalculationLogRepository.kt`, `PaymentTransactionRepository.kt`

#### 2.3 Facility 도메인으로 이동 (6개)
- **Controller**: `FacilityController.kt`
- **DTO**: `FacilityDto.kt`
- **Entity**: `FacilityAsset.kt`, `FaultReport.kt`, `WorkOrder.kt`
- **Repository**: `FacilityAssetRepository.kt`, `FaultReportRepository.kt`, `WorkOrderRepository.kt`

#### 2.4 Security 도메인으로 이동 (8개)
- **Controller**: `SecurityController.kt`
- **DTO**: `SecurityDto.kt`
- **Entity**: `Security.kt`
- **Repository**: `SecurityDeviceRepository.kt`, `SecurityIncidentRepository.kt`, `SecurityPatrolRepository.kt`, `SecurityZoneRepository.kt`, `VisitorManagementRepository.kt`, `AccessControlRecordRepository.kt`

#### 2.5 Lease 도메인으로 이동 (6개)
- **DTO**: `LeaseDto.kt`
- **Entity**: `LeaseContract.kt`
- **Repository**: `LeaseContractRepository.kt`, `ContractPartyRepository.kt`, `ContractRenewalRepository.kt`, `ContractStatusHistoryRepository.kt`, `DepositManagementRepository.kt`

#### 2.6 Dashboard 도메인으로 이동 (3개)
- **DTO**: `AnalyticsDto.kt`
- **Entity**: `Analytics.kt`

#### 2.7 Inventory 도메인으로 이동 (3개)
- **DTO**: `InventoryDto.kt`
- **Entity**: `Inventory.kt`

#### 2.8 Safety 도메인으로 이동 (3개)
- **DTO**: `SafetyComplianceDto.kt`
- **Entity**: `SafetyCompliance.kt`

#### 2.9 Common 서비스로 이동 (7개)
- **Controller**: `AuditController.kt`, `PerformanceMonitoringController.kt`
- **DTO**: `AuditDto.kt`, `ServiceResponse.kt`
- **Entity**: `AuditLog.kt`, `UserActivityLog.kt`
- **Repository**: `AuditLogRepository.kt`, `UserActivityLogRepository.kt`

## 정리 순서

### Phase 1: Migration 전용 파일 삭제 (15개)
1. Migration 전용 Controller, Entity, Repository, DTO, Exception, Config 삭제
2. 더 이상 사용되지 않는 임시 파일들 정리

### Phase 2: 도메인별 파일 이동 (49개)
1. 각 도메인별로 Controller, DTO, Entity, Repository 이동
2. 패키지 경로 수정 및 import 업데이트
3. 기존 도메인 파일들과 통합 또는 공존

### Phase 3: Migration 패키지 완전 삭제
1. 모든 파일 이동 완료 후 빈 디렉토리 삭제
2. Migration 패키지 완전 제거

## 예상 결과
- **삭제될 파일**: 15개 (Migration 전용)
- **이동될 파일**: 49개 (도메인별 배치)
- **최종 상태**: Migration 패키지 완전 제거

## 주의사항
1. **의존성 확인**: 이동 전 다른 패키지에서의 참조 확인
2. **테스트 코드**: 관련 테스트 코드도 함께 이동 필요
3. **설정 파일**: application.yml 등에서 패키지 경로 참조 확인
4. **단계적 진행**: 한 번에 모든 파일을 이동하지 말고 도메인별로 단계적 진행

이 계획을 통해 Migration 패키지를 완전히 정리하고 깔끔한 도메인 구조를 완성할 수 있습니다.