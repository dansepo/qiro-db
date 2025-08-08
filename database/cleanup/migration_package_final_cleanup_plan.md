# Migration 패키지 최종 정리 계획

## 현재 상황 분석
- migration 패키지에 controller, dto, entity, repository 파일들이 남아있음
- 이들은 프로시저 이관 과정에서 임시로 생성된 파일들
- 실제 비즈니스 로직은 이미 정식 도메인으로 이관 완료

## 정리 방침
**완전 삭제 방식 채택**
- migration 패키지의 모든 파일들을 삭제
- 이유: 임시 파일들이며, 실제 기능은 정식 도메인에 구현됨
- 필요한 기능이 있다면 정식 도메인에서 별도 구현

## 삭제 대상 파일들

### 1. Controller (7개)
- AuditController.kt
- BillingController.kt  
- FacilityController.kt
- NumberGenerationController.kt
- PerformanceMonitoringController.kt
- SecurityController.kt
- SystemInitializationController.kt

### 2. DTO (11개)
- AnalyticsDto.kt
- AuditDto.kt
- BillingDto.kt
- CommonCodeDto.kt
- FacilityDto.kt
- InventoryDto.kt
- LeaseDto.kt
- SafetyComplianceDto.kt
- SecurityDto.kt
- ServiceResponse.kt
- SystemInitializationDto.kt

### 3. Entity (14개)
- Analytics.kt
- AuditLog.kt
- CodeGroup.kt
- CommonCode.kt
- FacilityAsset.kt
- FaultReport.kt
- Inventory.kt
- LeaseContract.kt
- MonthlyFeeCalculation.kt
- SafetyCompliance.kt
- Security.kt
- UserActivityLog.kt
- WorkOrder.kt

### 4. Repository (24개)
- 모든 Repository 파일들

### 5. Common (1개)
- BaseService.kt

## 실행 계획
1. **백업 생성**: 혹시 모를 상황에 대비해 백업
2. **단계별 삭제**: 디렉토리별로 순차 삭제
3. **검증**: 정식 도메인들이 정상 동작하는지 확인
4. **migration 패키지 완전 삭제**

## 예상 결과
- migration 패키지 완전 제거
- 코드베이스 정리 완료
- 임시 코드 제거로 인한 혼란 방지