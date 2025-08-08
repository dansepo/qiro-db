# Migration 패키지 남은 파일들 분석 및 정리 계획

## 현재 상황
- service 디렉토리는 정리 완료
- controller, dto, entity, repository 디렉토리에 많은 파일들이 남아있음
- 이들을 적절한 도메인으로 이동 필요

## 남은 파일들 분석

### 1. Controller 파일들 (7개)
- AuditController.kt → audit 도메인 (새로 생성 필요)
- BillingController.kt → billing 도메인 (기존 존재)
- FacilityController.kt → facility 도메인 (기존 존재)
- NumberGenerationController.kt → common 또는 utility 도메인
- PerformanceMonitoringController.kt → performance 도메인 (기존 존재)
- SecurityController.kt → security 도메인 (기존 존재)
- SystemInitializationController.kt → system 또는 admin 도메인

### 2. DTO 파일들 (11개)
- AnalyticsDto.kt → analytics 또는 dashboard 도메인
- AuditDto.kt → audit 도메인
- BillingDto.kt → billing 도메인
- CommonCodeDto.kt → common 도메인
- FacilityDto.kt → facility 도메인
- InventoryDto.kt → inventory 도메인 (새로 생성 필요)
- LeaseDto.kt → lease 도메인 (기존 존재)
- SafetyComplianceDto.kt → safety 도메인 (기존 존재)
- SecurityDto.kt → security 도메인
- ServiceResponse.kt → common 도메인
- SystemInitializationDto.kt → system 또는 admin 도메인

### 3. Entity 파일들 (14개)
- Analytics.kt → dashboard 도메인
- AuditLog.kt → audit 도메인
- CodeGroup.kt, CommonCode.kt → common 도메인
- FacilityAsset.kt → facility 도메인
- FaultReport.kt → fault 도메인 (기존 존재)
- Inventory.kt → inventory 도메인
- LeaseContract.kt → lease 도메인
- MonthlyFeeCalculation.kt → billing 도메인
- SafetyCompliance.kt → safety 도메인
- Security.kt → security 도메인
- UserActivityLog.kt → audit 도는 user 도메인
- WorkOrder.kt → workorder 도메인 (기존 존재)

### 4. Repository 파일들 (24개)
각 Entity에 대응하는 Repository들로, Entity와 동일한 도메인으로 이동

## 정리 계획

### Phase 1: 기존 도메인으로 이동 가능한 파일들
1. **billing 도메인**
   - BillingController.kt, BillingDto.kt, MonthlyFeeCalculation.kt
   - 관련 Repository들

2. **facility 도메인**
   - FacilityController.kt, FacilityDto.kt, FacilityAsset.kt
   - 관련 Repository들

3. **security 도메인**
   - SecurityController.kt, SecurityDto.kt, Security.kt
   - 관련 Repository들

4. **기타 기존 도메인들**
   - lease, safety, fault, workorder, performance, dashboard 등

### Phase 2: 새로운 도메인 생성 필요
1. **audit 도메인 생성**
   - AuditController.kt, AuditDto.kt, AuditLog.kt, UserActivityLog.kt
   - 관련 Repository들

2. **inventory 도메인 생성** (이미 생성됨)
   - InventoryDto.kt, Inventory.kt
   - 관련 Repository들

3. **common 도메인 생성**
   - CommonCodeDto.kt, ServiceResponse.kt
   - CodeGroup.kt, CommonCode.kt
   - NumberGenerationController.kt

### Phase 3: 시스템 관리 관련
- SystemInitializationController.kt, SystemInitializationDto.kt
- admin 도메인 또는 system 도메인으로 이동

## 예상 결과
- migration 패키지 완전 정리
- 도메인별 명확한 책임 분리
- 코드 구조의 일관성 확보