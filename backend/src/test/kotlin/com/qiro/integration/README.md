# 시설 관리 시스템 통합 테스트

## 개요

시설 관리 시스템의 통합 테스트는 TestExecutionService를 활용하여 전체 플로우를 검증합니다. 기존 데이터베이스 프로시저 로직을 백엔드 서비스로 완전 이관한 후, 시스템의 통합성과 안정성을 보장하기 위한 포괄적인 테스트를 제공합니다.

## 테스트 구조

### 1. 통합 테스트 클래스

#### FacilityManagementIntegrationTest
- **목적**: 전체 시설 관리 시스템의 통합 플로우 테스트
- **주요 테스트**:
  - 시스템 전체 플로우 테스트
  - 데이터 무결성 검증
  - 성능 테스트
  - 비즈니스 로직 테스트
  - 시스템 부하 테스트
  - 데이터 일관성 테스트
  - 보안 및 권한 테스트
  - 성능 회귀 테스트

#### PreventiveMaintenanceIntegrationTest
- **목적**: 예방 정비 자동 생성 및 실행 플로우 테스트
- **주요 테스트**:
  - 예방 정비 자동 생성 플로우
  - 예방 정비 실행 플로우
  - 문제 발견 시 작업 지시서 자동 생성
  - 예방 정비 성과 분석 및 최적화
  - 계절별 예방 정비 자동 조정
  - 예방 정비 품질 관리

#### NotificationEscalationIntegrationTest
- **목적**: 알림 발송 및 에스컬레이션 플로우 테스트
- **주요 테스트**:
  - 긴급 고장 신고 즉시 알림 플로우
  - 작업 지연 알림 및 에스컬레이션 플로우
  - 정비 일정 사전 알림 플로우
  - 다채널 알림 발송 및 실패 처리
  - 알림 우선순위 및 배치 처리
  - 알림 템플릿 및 개인화
  - 알림 성과 분석 및 최적화

#### FacilityManagementTestSuite
- **목적**: 전체 테스트 스위트 실행 및 관리
- **주요 기능**:
  - 통합 테스트 스위트 실행
  - TestExecutionService 활용 테스트
  - 테스트 결과 요약 및 분석
  - 백엔드 서비스 기반 테스트 실행

### 2. 베이스 클래스

#### BaseIntegrationTest
- **목적**: 모든 통합 테스트의 공통 기능 제공
- **주요 기능**:
  - 테스트 데이터 생성 헬퍼
  - 테스트 실행 시간 측정
  - 테스트 결과 검증
  - 테스트 환경 설정

## 테스트 실행 방법

### 1. 전체 통합 테스트 실행
```bash
# Gradle을 통한 통합 테스트 실행
./gradlew integrationTest

# 또는 특정 테스트 클래스 실행
./gradlew test --tests "com.qiro.integration.FacilityManagementIntegrationTest"
```

### 2. 개별 테스트 카테고리 실행
```bash
# 단위 테스트만 실행
./gradlew unitTest

# 성능 테스트만 실행
./gradlew performanceTest

# 모든 테스트 실행
./gradlew allTests
```

### 3. IDE에서 실행
- IntelliJ IDEA 또는 Eclipse에서 테스트 클래스를 직접 실행
- `application-integration.yml` 프로파일이 자동으로 적용됨

## 테스트 환경 설정

### 1. 데이터베이스 설정
```yaml
# application-integration.yml
spring:
  datasource:
    url: jdbc:h2:mem:testdb
    driver-class-name: org.h2.Driver
  jpa:
    hibernate:
      ddl-auto: create-drop
```

### 2. 테스트 전용 설정
```yaml
qiro:
  test:
    auto-generate-test-data: true
    cleanup-after-test: true
    execution-timeout: 300
    parallel-execution: false
```

### 3. 외부 서비스 Mock 설정
```yaml
external-services:
  sms:
    enabled: false
    mock: true
  email:
    enabled: false
    mock: true
```

## 테스트 시나리오

### 1. 전체 플로우 테스트
1. **시스템 초기 상태 확인**
   - 데이터베이스 연결 확인
   - 기본 설정 검증
   - 서비스 의존성 확인

2. **데이터 무결성 검사**
   - 회사 데이터 무결성 검사
   - 시설물 데이터 무결성 검사
   - 사용자 데이터 무결성 검사
   - 작업 지시서 데이터 무결성 검사

3. **성능 테스트**
   - 데이터베이스 연결 성능
   - API 응답 시간
   - 캐시 성능
   - 메모리 사용량

4. **비즈니스 로직 테스트**
   - 고장 신고 생성 로직
   - 작업 지시서 배정 로직
   - 예방 정비 스케줄링
   - 비용 계산 로직

5. **통합 최적화 실행**
   - 데이터 무결성 최적화
   - 성능 최적화
   - 캐시 최적화
   - 데이터베이스 최적화

### 2. 예방 정비 플로우 테스트
1. **정기 점검 일정 자동 생성**
   - 시설물별 정비 일정 생성
   - 담당자 배정
   - 알림 발송

2. **예방 정비 실행**
   - 체크리스트 기반 점검
   - 문제 감지 및 기록
   - 결과 분석

3. **문제 발견 시 처리**
   - 자동 작업 지시서 생성
   - 우선순위 평가
   - 에스컬레이션

### 3. 알림 시스템 플로우 테스트
1. **긴급 알림 발송**
   - 긴급 상황 감지
   - 즉시 알림 발송
   - 다채널 발송

2. **작업 지연 에스컬레이션**
   - 지연 감지
   - 담당자 알림
   - 관리자 에스컬레이션

3. **사전 알림**
   - 정비 일정 사전 알림
   - 준비 가이드 제공
   - 리마인더 발송

## 테스트 결과 분석

### 1. 성공 기준
- **전체 성공률**: 95% 이상
- **응답 시간**: 평균 2초 이내
- **메모리 사용량**: 80% 이하
- **데이터 무결성**: 90점 이상

### 2. 성능 임계값
```yaml
performance-thresholds:
  database:
    connection-time-ms: 100
    query-time-ms: 500
  api:
    response-time-ms: 1000
  cache:
    hit-rate-percent: 80.0
  memory:
    heap-usage-percent: 80.0
```

### 3. 테스트 결과 리포트
- **테스트 실행 시간**: 각 테스트별 실행 시간 측정
- **성공/실패 통계**: 카테고리별 성공률 분석
- **성능 메트릭**: 응답 시간, 메모리 사용량 등
- **오류 상세**: 실패한 테스트의 상세 오류 정보

## 백엔드 서비스 이관 검증

### 1. 이관 완료 서비스
- ✅ **DataIntegrityService**: 데이터 무결성 검사 (45개 프로시저 이관)
- ✅ **PerformanceMonitoringService**: 성능 모니터링 (25개 프로시저 이관)
- ✅ **TestExecutionService**: 테스트 실행 (15개 프로시저 이관)
- ✅ **IntegratedCommonService**: 통합 공통 서비스

### 2. 이관 검증 테스트
```kotlin
// 기존 프로시저 vs 백엔드 서비스 결과 비교
val procedureResult = runDatabaseProcedure()
val serviceResult = runBackendService()
assertEquals(procedureResult, serviceResult)
```

### 3. 성능 비교
- **프로시저 실행 시간** vs **서비스 실행 시간**
- **메모리 사용량** 비교
- **동시성 처리** 성능 비교

## 문제 해결 가이드

### 1. 일반적인 문제
- **테스트 실패**: 로그 확인 후 데이터 상태 점검
- **성능 저하**: 메모리 사용량 및 GC 로그 확인
- **데이터베이스 연결 오류**: H2 설정 및 연결 풀 확인

### 2. 디버깅 방법
```bash
# 상세 로그 출력
./gradlew integrationTest --debug

# 특정 테스트만 실행
./gradlew test --tests "*FacilityManagementIntegrationTest.전체 플로우*"

# 테스트 결과 HTML 리포트 확인
open build/reports/tests/integrationTest/index.html
```

### 3. 테스트 데이터 확인
```bash
# H2 콘솔 접속 (테스트 실행 중)
http://localhost:8080/h2-console
```

## 지속적 통합 (CI/CD)

### 1. GitHub Actions 설정
```yaml
name: Integration Tests
on: [push, pull_request]
jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '21'
      - run: ./gradlew integrationTest
```

### 2. 테스트 결과 리포팅
- **JUnit 리포트**: XML 형식으로 테스트 결과 출력
- **Jacoco 커버리지**: 코드 커버리지 측정
- **성능 메트릭**: 실행 시간 및 리소스 사용량 추적

## 향후 계획

### 1. 단기 계획 (1-2개월)
- 나머지 비즈니스 로직 프로시저 이관 테스트 추가
- 성능 벤치마크 테스트 강화
- 테스트 자동화 개선

### 2. 중기 계획 (3-6개월)
- 부하 테스트 시나리오 확장
- 장애 복구 테스트 추가
- 보안 테스트 강화

### 3. 장기 계획 (6-12개월)
- 카오스 엔지니어링 도입
- AI 기반 테스트 케이스 생성
- 실시간 모니터링 통합

## 기여 가이드

### 1. 새로운 테스트 추가
```kotlin
// BaseIntegrationTest를 상속받아 구현
class NewFeatureIntegrationTest : BaseIntegrationTest() {
    // 테스트 구현
}
```

### 2. 테스트 명명 규칙
- **클래스명**: `{Feature}IntegrationTest`
- **테스트명**: `{기능} {시나리오} 테스트`
- **패키지**: `com.qiro.integration.{domain}`

### 3. 코드 리뷰 체크리스트
- [ ] 테스트 시나리오가 명확한가?
- [ ] 성능 임계값이 적절한가?
- [ ] Mock 설정이 올바른가?
- [ ] 테스트 데이터 정리가 되는가?
- [ ] 문서화가 충분한가?