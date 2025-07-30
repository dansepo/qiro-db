# Qiro 서버 프로젝트 아키텍처

이 문서는 Qiro 서버 애플리케이션의 기술 스택, 구조 및 설계 원칙을 설명합니다.

## 1. 개요

본 프로젝트는 **Spring Boot**를 기반으로 하는 **계층형 아키텍처(Layered Architecture)**를 따르는 모놀리식(Monolithic) 애플리케이션입니다. 각 계층은 명확하게 정의된 책임을 가지며, 이를 통해 코드의 유지보수성, 테스트 용이성, 확장성을 높이는 것을 목표로 합니다.

주요 기능은 다음과 같습니다.
- RESTful API를 통한 클라이언트(웹/모바일)와의 통신
- JWT(JSON Web Token)를 이용한 상태 비저장(Stateless) 인증 및 인가
- PostgreSQL 데이터베이스를 이용한 데이터 영속성 관리

## 2. 기술 스택 (Technology Stack)

| 구분 | 기술 | 버전/라이브러리 | 역할 |
| :--- | :--- | :--- | :--- |
| **언어** | Kotlin | 1.9.25 | 메인 개발 언어 |
| **런타임** | Java | 21 | JVM 실행 환경 |
| **프레임워크** | Spring Boot | 3.4.4 | 애플리케이션 핵심 프레임워크 |
| | Spring Web | - | RESTful API 및 웹 계층 |
| | Spring Data JPA | - | 데이터 영속성 및 ORM |
| | Spring Security | - | 인증 및 인가 |
| | Thymeleaf | - | 서버 사이드 템플릿 엔진 (필요시 사용) |
| **데이터베이스** | PostgreSQL | - | 운영(Production) 데이터베이스 |
| | H2 Database | - | 개발 및 테스트용 인메모리 DB |
| **쿼리** | QueryDSL | 5.0.0 | 타입-세이프(Type-safe) 동적 쿼리 작성 |
| **인증** | JWT (jjwt) | 0.11.2 | 토큰 기반 인증 |
| **테스트** | Kotest | 5.4.2 | Kotlin 테스트 프레임워크 |
| | SpringMockK | 4.0.2 | Kotlin 객체 모킹(Mocking) |
| | REST Assured | 5.3.0 | REST API 통합 테스트 |
| **빌드 도구** | Gradle | Kotlin DSL | 의존성 관리 및 빌드 자동화 |

## 3. 아키텍처 계층 (Layered Architecture)

애플리케이션은 크게 4개의 주요 계층으로 구성됩니다. 데이터의 흐름은 일반적으로 `Controller -> Service -> Repository` 순으로 단방향으로 이루어집니다.

### 3.1. Presentation Layer (Controller)

- **역할**: 외부의 HTTP 요청을 받아 내부 비즈니스 로직으로 연결하는 진입점입니다.
- **구현**:
    - `@RestController`를 사용하여 RESTful API 엔드포인트를 정의합니다.
    - 클라이언트로부터 받은 요청 데이터는 DTO(Data Transfer Object)로 변환하고, `spring-boot-starter-validation`을 통해 유효성을 검증합니다.
    - 비즈니스 로직 처리를 위해 `Service` 계층을 호출합니다.
    - 처리 결과를 클라이언트에 JSON 형태로 응답합니다.

### 3.2. Business Logic Layer (Service)

- **역할**: 애플리케이션의 핵심 비즈니스 로직을 처리합니다.
- **구현**:
    - `@Service` 어노테이션을 사용하여 비즈니스 로직을 캡슐화합니다.
    - `@Transactional` 어노테이션을 통해 데이터베이스 트랜잭션을 관리합니다.
    - 여러 `Repository`를 조합하여 복잡한 비즈니스 요구사항을 구현합니다.
    - 도메인 객체(Entity)를 직접 다루지 않고, DTO를 통해 `Controller` 계층과 데이터를 주고받습니다.

### 3.3. Data Access Layer (Repository)

- **역할**: 데이터베이스와의 통신을 담당하며, 데이터의 영속성을 관리합니다.
- **구현**:
    - Spring Data JPA의 `JpaRepository` 인터페이스를 상속받아 기본적인 CRUD 기능을 구현합니다.
    - 복잡한 조회나 동적 쿼리가 필요한 경우, **QueryDSL**을 사용하여 타입-세이프하고 가독성 높은 쿼리를 작성합니다.
    - 데이터베이스의 종류(PostgreSQL, H2)에 종속되지 않는 코드를 작성합니다.

### 3.4. Domain Layer (Entity)

- **역할**: 애플리케이션의 핵심 데이터 모델을 정의합니다.
- **구현**:
    - `@Entity` 어노테이션을 사용하여 데이터베이스 테이블과 매핑되는 클래스를 정의합니다.
    - `@Id`, `@Column`, `@ManyToOne` 등 JPA 어노테이션을 사용하여 테이블의 속성과 관계를 명시합니다.
    - 이 계층의 객체는 비즈니스 로직 전반에서 사용됩니다.

## 4. 보안 (Security)

- **Spring Security**를 사용하여 인증(Authentication) 및 인가(Authorization)를 처리합니다.
- 인증 방식은 상태 비저장(Stateless)을 유지하기 위해 **JWT(JSON Web Token)**를 사용합니다.
    1.  **로그인**: 사용자가 ID/PW로 로그인을 요청하면, 서버는 인증 후 Access Token과 Refresh Token을 발급합니다.
    2.  **API 요청**: 클라이언트는 이후의 모든 API 요청 시 `Authorization` 헤더에 Access Token을 담아 전송합니다.
    3.  **인증 필터**: 서버는 JWT 필터를 통해 토큰의 유효성을 검증하고, 유효한 경우 요청을 처리합니다.

## 5. 테스트 전략 (Testing Strategy)

- **단위 테스트 (Unit Test)**:
    - **대상**: `Service` 클래스 등 비즈니스 로직의 특정 단위.
    - **도구**: `Kotest`를 사용하여 테스트 케이스를 작성하고, `SpringMockK`를 사용하여 의존성을 갖는 객체(Repository 등)를 모킹(Mocking)합니다.
- **통합 테스트 (Integration Test)**:
    - **대상**: `Controller` API 엔드포인트.
    - **도구**: `@SpringBootTest`를 사용하여 전체 Spring 컨텍스트를 로드하고, `REST Assured`를 사용하여 실제 HTTP 요청을 보내 API의 전체 흐름을 테스트합니다. 테스트 시에는 H2 인메모리 데이터베이스를 사용합니다.

## 6. 패키지 구조 (Package Structure)

프로젝트는 기능별, 계층별로 패키지를 구성하여 코드의 응집도를 높이고 결합도를 낮춥니다.
