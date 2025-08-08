# 통합 공통 서비스 (Integrated Common Services)

## 개요

통합 공통 서비스는 시설 관리 시스템의 핵심 공통 기능들을 통합 관리하는 서비스입니다. 기존 데이터베이스 프로시저로 구현되었던 로직들을 백엔드 서비스로 완전 이관하여 더 나은 유지보수성과 확장성을 제공합니다.

## 주요 구성 요소

### 1. IntegratedCommonService
- **역할**: 데이터 무결성, 성능 모니터링, 테스트 실행 서비스를 통합 관리
- **주요 기능**:
  - 통합 시스템 상태 점검
  - 통합 최적화 실행
  - 통합 테스트 실행
  - 서비스 간 의존성 관리
  - 프로시저 이관 상태 추적

### 2. DataIntegrityService
- **역할**: 데이터 무결성 검사 및 검증
- **주요 기능**:
  - 엔티티별 데이터 무결성 검사
  - 비즈니스 규칙 검증
  - 데이터 형식 검증
  - 참조 무결성 검사

### 3. PerformanceMonitoringService
- **역할**: 시스템 성능 모니터링 및 최적화
- **주요 기능**:
  - 성능 메트릭 수집 및 분석
  - 시스템 상태 모니터링
  - 성능 최적화 제안
  - 캐시 및 쿼리 성능 추적

### 4. TestExecutionService
- **역할**: 통합 테스트 실행 및 관리
- **주요 기능**:
  - 데이터 구조 검증 테스트
  - 비즈니스 규칙 검증 테스트
  - 성능 테스트
  - 보안 테스트

## API 엔드포인트

### 시스템 상태 관리
```http
GET /api/v1/integrated/system-status/{companyId}
POST /api/v1/integrated/optimization/{companyId}
POST /api/v1/integrated/tests/{companyId}
GET /api/v1/integrated/dashboard/{companyId}
```

### 성능 및 모니터링
```http
POST /api/v1/integrated/benchmark/{companyId}
GET /api/v1/integrated/status-history/{companyId}
GET /api/v1/integrated/capacity-planning/{companyId}
GET /api/v1/integrated/cost-optimization/{companyId}
```

### 자동화 및 관리
```http
GET /api/v1/integrated/automation-rules/{companyId}
POST /api/v1/integrated/dependency-optimization/{companyId}
GET /api/v1/integrated/procedure-migration-status
```

## 데이터베이스 프로시저 이관 현황

### 완료된 이관 (271개 중 85개)

#### 1. 데이터 무결성 관련 (45개)
- ✅ 공통 코드 관리 함수 (3개)
- ✅ 데이터 검증 함수 (15개)
- ✅ 사용자 활동 및 보안 로그 함수 (27개)

#### 2. 성능 모니터링 관련 (25개)
- ✅ 성능 테스트 함수 (4개)
- ✅ 통계 및 모니터링 함수 (7개)
- ✅ 시스템 유지보수 및 정리 함수 (14개)

#### 3. 테스트 관련 (15개)
- ✅ 테스트 데이터 생성 함수 (1개)
- ✅ 통합 테스트 함수 (14개)

### 진행 중인 이관 (186개)

#### 4. 비즈니스 로직 관련 (186개)
- 🔄 시설 관리 함수 (45개)
- 🔄 요금 계산 및 청구 함수 (35개)
- 🔄 계약 및 임대 관리 함수 (40개)
- 🔄 재고 및 자재 관리 함수 (25개)
- 🔄 보안 및 접근 제어 함수 (15개)
- 🔄 기타 업무 프로세스 함수 (26개)

## 사용 예시

### 1. 통합 시스템 상태 조회
```kotlin
val systemStatus = integratedCommonService.getIntegratedSystemStatus(companyId)
println("전체 시스템 상태: ${systemStatus.overallStatus}")
println("데이터 무결성 점수: ${systemStatus.dataIntegrityStatus.integrityScore}")
```

### 2. 통합 최적화 실행
```kotlin
val options = OptimizationOptionsDto(
    includeDataIntegrity = true,
    includePerformanceOptimization = true,
    includeCacheOptimization = true,
    includeDatabaseOptimization = true
)

val result = integratedCommonService.performIntegratedOptimization(
    companyId, userId, options
)
println("최적화 성공률: ${result.performanceImprovement}%")
```

### 3. 통합 테스트 실행
```kotlin
val testOptions = IntegratedTestOptionsDto(
    includeIntegrationTests = true,
    includeDataIntegrityTests = true,
    includePerformanceTests = true,
    includeSecurityTests = true
)

val testResult = integratedCommonService.runIntegratedTests(companyId, testOptions)
println("테스트 성공률: ${testResult.overallSuccessRate}%")
```

## 설정 및 구성

### application.yml 설정
```yaml
qiro:
  integrated-services:
    data-integrity:
      enabled: true
      check-interval: 3600 # 1시간마다 자동 검사
      auto-fix: false
    performance-monitoring:
      enabled: true
      metric-collection-interval: 60 # 1분마다 메트릭 수집
      alert-threshold:
        cpu: 80.0
        memory: 85.0
        response-time: 2000.0
    test-execution:
      enabled: true
      auto-cleanup: true
      max-test-history: 100
```

### 로깅 설정
```yaml
logging:
  level:
    com.qiro.common.service: DEBUG
    com.qiro.domain.validation: INFO
    com.qiro.domain.performance: INFO
```

## 모니터링 및 알림

### 1. 시스템 상태 모니터링
- 데이터 무결성 점수 추적
- 성능 메트릭 실시간 모니터링
- 테스트 결과 자동 분석

### 2. 자동 알림
- 임계값 초과 시 즉시 알림
- 데이터 무결성 이슈 발견 시 알림
- 성능 저하 감지 시 자동 최적화 실행

### 3. 대시보드
- 통합 모니터링 대시보드 제공
- 실시간 시스템 상태 표시
- 성능 트렌드 분석

## 성능 최적화

### 1. 캐싱 전략
- 자주 조회되는 데이터 캐싱
- 캐시 히트율 모니터링
- 자동 캐시 무효화

### 2. 데이터베이스 최적화
- 느린 쿼리 자동 감지
- 인덱스 사용률 분석
- 쿼리 실행 계획 최적화

### 3. 메모리 관리
- 힙 메모리 사용량 모니터링
- GC 성능 추적
- 메모리 누수 감지

## 보안 고려사항

### 1. 데이터 보호
- 민감한 데이터 암호화
- 접근 권한 검증
- 감사 로그 기록

### 2. API 보안
- JWT 토큰 기반 인증
- 요청 속도 제한
- 입력 데이터 검증

### 3. 시스템 보안
- 보안 이벤트 모니터링
- 비정상 접근 감지
- 자동 보안 패치 적용

## 트러블슈팅

### 1. 일반적인 문제
- **데이터 무결성 검사 실패**: 로그 확인 후 수동 데이터 정리
- **성능 저하**: 캐시 정리 및 쿼리 최적화 실행
- **테스트 실패**: 실패한 테스트 상세 로그 확인

### 2. 로그 위치
- 애플리케이션 로그: `/logs/application.log`
- 성능 로그: `/logs/performance.log`
- 테스트 로그: `/logs/test-execution.log`

### 3. 복구 절차
1. 시스템 상태 확인
2. 백업에서 데이터 복원 (필요시)
3. 서비스 재시작
4. 통합 테스트 실행

## 향후 계획

### 1. 단기 계획 (1-3개월)
- 나머지 비즈니스 로직 프로시저 이관 완료
- 성능 최적화 자동화 강화
- 모니터링 대시보드 개선

### 2. 중기 계획 (3-6개월)
- 머신러닝 기반 성능 예측
- 자동 스케일링 구현
- 마이크로서비스 아키텍처 전환

### 3. 장기 계획 (6-12개월)
- 클라우드 네이티브 환경 최적화
- 실시간 데이터 처리 강화
- AI 기반 시스템 관리 도입

## 기여 가이드

### 1. 개발 환경 설정
```bash
# 프로젝트 클론
git clone <repository-url>

# 의존성 설치
./gradlew build

# 테스트 실행
./gradlew test
```

### 2. 코드 스타일
- Kotlin 코딩 컨벤션 준수
- 단위 테스트 작성 필수
- 문서화 주석 작성

### 3. 커밋 메시지 형식
```
feat: 새로운 기능 추가
fix: 버그 수정
docs: 문서 업데이트
test: 테스트 추가/수정
refactor: 코드 리팩토링
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.