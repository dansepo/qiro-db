# Migration 패키지 정리 및 통합 계획

## 개요
- **작업 일시**: 2025-01-08
- **작업 범위**: backend/src/main/kotlin/com/qiro/domain/migration 패키지 정리
- **목표**: 임시 migration 패키지의 서비스들을 적절한 도메인으로 이동 및 통합

## 현재 상황 분석

### Migration 패키지 내 서비스 현황
1. **ComplaintServiceImpl.kt** - complaint 도메인 참조 (도메인 미존재)
2. **ContractorServiceImpl.kt** - contractor 도메인으로 이동 가능
3. **InsuranceServiceImpl.kt** - 새로운 insurance 도메인 생성 필요
4. **MarketingServiceImpl.kt** - 새로운 marketing 도메인 생성 필요
5. **NotificationServiceImpl.kt** - notification 도메인으로 이동 가능
6. **NotificationService.kt** - notification 도메인으로 이동 가능
7. **ReservationService.kt** - facility 도메인으로 이동 가능

## 정리 계획

### Phase 1: 기존 도메인으로 이동
1. **ContractorServiceImpl** → `contractor/service/` 이동
2. **NotificationServiceImpl, NotificationService** → `notification/service/` 이동
3. **ReservationService** → `facility/service/` 이동

### Phase 2: 새로운 도메인 생성 및 이동
1. **insurance 도메인 생성**
   - `backend/src/main/kotlin/com/qiro/domain/insurance/service/` 생성
   - InsuranceServiceImpl, InsuranceService 이동

2. **marketing 도메인 생성**
   - `backend/src/main/kotlin/com/qiro/domain/marketing/service/` 생성
   - MarketingServiceImpl, MarketingService 이동

### Phase 3: 불필요한 파일 제거
1. **ComplaintServiceImpl** 제거 (참조하는 complaint 도메인 미존재)
2. **migration 패키지 정리** (빈 디렉토리 및 불필요한 파일 제거)

## 예상 결과
- migration 패키지의 임시 서비스들이 적절한 도메인으로 이동
- 도메인별 응집도 향상
- 코드 구조의 일관성 확보
- 불필요한 임시 코드 제거

## 주의사항
- 패키지 이동 시 import 경로 수정 필요
- 기존 도메인의 서비스와 중복 확인 필요
- 테스트 코드 존재 시 함께 이동 필요