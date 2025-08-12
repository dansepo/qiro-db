# QIRO 건물관리 시스템 백엔드

QIRO는 건물관리를 위한 종합적인 웹 애플리케이션입니다. 이 프로젝트는 Spring Boot와 Kotlin을 기반으로 구축된 백엔드 API 서버입니다.

## 🏗️ 아키텍처

### 기술 스택
- **언어**: Kotlin 1.9.25
- **프레임워크**: Spring Boot 3.5.3
- **데이터베이스**: PostgreSQL 17.5
- **ORM**: Spring Data JPA + QueryDSL 5.0.0
- **보안**: Spring Security + JWT
- **테스트**: Kotest 5.4.2 + MockK
- **빌드**: Gradle with Kotlin DSL
- **컨테이너**: Docker + Docker Compose

### 시스템 구조
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend API   │    │   Database      │
│   (Next.js)     │◄──►│  (Spring Boot)  │◄──►│  (PostgreSQL)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │   Monitoring    │
                       │ (Prometheus +   │
                       │   Grafana)      │
                       └─────────────────┘
```

## 🚀 주요 기능

### 핵심 도메인
- **건물 관리**: 건물 정보, 세대 관리, 임대차 계약
- **관리비 처리**: 월별 관리비 산정, 고지서 발행, 수납 관리
- **미납 관리**: 연체료 계산, 독촉 관리, 법적 조치 추적
- **시설 유지보수**: 시설물 관리, 유지보수 요청, 작업 진행 추적
- **사용자 관리**: 멀티테넌시, 역할 기반 권한 관리

### 기술적 특징
- **멀티테넌시**: 여러 관리업체가 하나의 시스템을 공유
- **JWT 인증**: 무상태 인증 시스템
- **RESTful API**: 표준화된 API 설계
- **실시간 모니터링**: Actuator + Prometheus + Grafana
- **구조화된 로깅**: JSON 형태의 구조화된 로그
- **자동화된 테스트**: 단위/통합/E2E 테스트

## 📋 사전 요구사항

- Java 21 이상
- Docker & Docker Compose
- PostgreSQL 17.5 (Docker 사용 시 불필요)

## 🛠️ 설치 및 실행

### 1. 저장소 클론
```bash
git clone https://github.com/your-org/qiro-backend.git
cd qiro-backend
```

### 2. Docker Compose로 실행 (권장)
```bash
# 전체 스택 실행 (데이터베이스, 백엔드, 모니터링)
docker-compose up -d

# 로그 확인
docker-compose logs -f qiro-backend
```

### 3. 로컬 개발 환경 실행
```bash
# 데이터베이스만 Docker로 실행
docker-compose up -d postgres redis

# 애플리케이션 실행
./gradlew bootRun
```

### 4. 테스트 실행
```bash
# 전체 테스트 실행
./gradlew test

# 특정 테스트 실행
./gradlew test --tests "InvoiceServiceImplTest"
```

## 🔧 설정

### 환경별 설정 파일
- `application.yml`: 기본 설정
- `application-prod.yml`: 운영 환경 설정
- `application-test.yml`: 테스트 환경 설정

### 주요 환경 변수
```bash
# 데이터베이스
DATABASE_URL=jdbc:postgresql://localhost:5432/qiro_dev
DATABASE_USERNAME=qiro
DATABASE_PASSWORD=p@ssword

# JWT
JWT_SECRET=your-jwt-secret-key

# 파일 업로드
FILE_UPLOAD_PATH=/app/uploads
PDF_GENERATION_PATH=/app/pdf-temp

# 이메일 설정
EMAIL_HOST=smtp.gmail.com
EMAIL_USERNAME=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

## 📚 API 문서

### Swagger UI
애플리케이션 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:
- 개발 환경: http://localhost:8080/swagger-ui/index.html
- OpenAPI 스펙: http://localhost:8080/v3/api-docs

### 주요 API 엔드포인트

#### 인증
- `POST /api/v1/auth/login` - 로그인
- `POST /api/v1/auth/refresh` - 토큰 갱신
- `POST /api/v1/auth/logout` - 로그아웃

#### 건물 관리
- `GET /api/v1/buildings` - 건물 목록 조회
- `POST /api/v1/buildings` - 건물 생성
- `GET /api/v1/buildings/{id}/units` - 세대 목록 조회

#### 고지서 관리
- `GET /api/v1/invoices` - 고지서 목록 조회
- `POST /api/v1/invoices` - 고지서 생성
- `POST /api/v1/invoices/{id}/payment` - 결제 처리

#### 시설 유지보수
- `GET /api/v1/maintenance/requests` - 유지보수 요청 목록
- `POST /api/v1/maintenance/requests` - 유지보수 요청 생성

## 🔍 모니터링

### 헬스 체크
- `GET /actuator/health` - 애플리케이션 상태 확인
- `GET /actuator/metrics` - 메트릭 정보

### 모니터링 대시보드
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090

### 주요 메트릭
- API 응답 시간
- 데이터베이스 연결 상태
- JVM 메모리 사용량
- 비즈니스 메트릭 (고지서 생성, 결제 처리 등)

## 🧪 테스트

### 테스트 구조
```
src/test/kotlin/
├── unit/                 # 단위 테스트
│   ├── service/         # 서비스 계층 테스트
│   └── entity/          # 엔티티 테스트
├── integration/         # 통합 테스트
│   ├── controller/      # 컨트롤러 테스트
│   └── repository/      # 리포지토리 테스트
└── e2e/                 # E2E 테스트
```

### 테스트 실행
```bash
# 전체 테스트
./gradlew test

# 특정 패키지 테스트
./gradlew test --tests "com.qiro.domain.invoice.*"

# 테스트 커버리지 리포트 생성
./gradlew jacocoTestReport
```

## 🚀 배포

### Docker 이미지 빌드
```bash
# 이미지 빌드
docker build -t qiro-backend:latest .

# 이미지 실행
docker run -p 8080:8080 qiro-backend:latest
```

### 운영 환경 배포
```bash
# 운영 프로파일로 실행
SPRING_PROFILES_ACTIVE=prod java -jar build/libs/qiro-backend.jar
```

## 📁 프로젝트 구조

```
src/main/kotlin/com/qiro/
├── common/              # 공통 컴포넌트
│   ├── config/         # 설정 클래스
│   ├── dto/            # 공통 DTO
│   ├── exception/      # 예외 처리
│   ├── security/       # 보안 설정
│   └── util/           # 유틸리티
├── domain/             # 도메인별 패키지
│   ├── auth/           # 인증/인가
│   ├── building/       # 건물 관리
│   ├── invoice/        # 고지서 관리
│   ├── payment/        # 결제 관리
│   ├── maintenance/    # 유지보수 관리
│   └── user/           # 사용자 관리
└── QiroApplication.kt  # 메인 애플리케이션
```

각 도메인 패키지는 다음 구조를 따릅니다:
```
domain/{domain}/
├── controller/         # REST 컨트롤러
├── service/           # 비즈니스 로직
├── repository/        # 데이터 접근
├── entity/            # JPA 엔티티
└── dto/               # 데이터 전송 객체
```

## 🤝 기여하기

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 `LICENSE` 파일을 참조하세요.

## 📞 지원

- 이슈 리포트: [GitHub Issues](https://github.com/your-org/qiro-backend/issues)
- 이메일: dev@qiro.com
- 문서: [Wiki](https://github.com/your-org/qiro-backend/wiki)