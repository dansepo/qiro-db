# 📜 QIRO API 설계 가이드라인

## 1. 문서 정보
- **문서명:** QIRO API 설계 가이드라인
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **작성일:** 2025년 05월 28일
- **최종 수정일:** 2025년 05월 28일
- **작성자:** (이름 또는 팀)
- **검토자/승인자 (선택 사항):** (이름 또는 팀)
- **문서 버전:** 1.0

## 2. 개요
### 2.1. 문서 목적
본 문서는 QIRO 서비스의 API를 개발하고 유지보수하는 과정에서 일관성, 예측 가능성, 사용 편의성 및 확장성을 확보하기 위한 설계 원칙, 명명 규칙, 데이터 형식, 오류 처리 방식 등을 정의하는 것을 목적으로 한다.

### 2.2. 적용 범위
본 가이드라인은 QIRO 서비스에서 제공하는 모든 내부 및 외부 공개 API(RESTful API) 설계 및 구현에 적용된다.

### 2.3. 기본 원칙
- **자원 중심 (Resource-Oriented):** API는 명확하게 정의된 자원을 중심으로 설계한다.
- **표준 HTTP 활용 (Standard HTTP Usage):** HTTP 메소드와 상태 코드를 의미에 맞게 정확히 사용한다.
- **일관성 (Consistency):** API 전반에 걸쳐 URI 구조, 요청/응답 형식, 명명 규칙 등을 일관되게 적용한다.
- **단순성 및 예측 가능성 (Simplicity & Predictability):** API 사용자가 쉽게 이해하고 예측 가능한 형태로 설계한다.
- **무상태성 (Statelessness):** 각 요청은 이전 요청과 독립적으로 처리되어야 한다.
- **보안 (Security):** 모든 API는 보안 원칙을 준수하여 설계한다.
- **문서화 (Documentation):** 명확하고 상세한 API 문서를 제공한다.
- **버전 관리 (Versioning):** API 변경에 따른 하위 호환성을 고려한 체계적인 버전 관리를 시행한다.

### 2.4. 참고 문서
- `01_기술_스택_정의.md`
- OpenAPI Specification (Swagger)
- (기타 REST API 디자인 베스트 프랙티스 문서 링크)

## 3. URI (Uniform Resource Identifier) 설계 규칙
### 3.1. 자원(Resource) 표현
- URI는 자원을 표현하며, 명사를 사용한다. (동사 사용 금지)
- 자원 컬렉션은 복수형 명사를 사용한다.
    - 예: `/buildings`, `/users`, `/management-fees`
- 특정 자원을 지칭할 때는 경로 파라미터(Path Parameter)로 해당 자원의 식별자를 사용한다.
    - 예: `/buildings/{buildingId}`, `/users/{userId}`

### 3.2. 경로(Path) 규칙
- 소문자를 사용한다.
- 단어 간 구분은 하이픈(`-`)을 사용한다. (팀 표준: **하이픈 `-`** / 또는 밑줄 `_` - 하나로 통일)
    - 예: `/management-fees`, `/facility-inspections`
- 계층 관계를 나타낼 때는 `/`를 사용한다.
    - 예: `/buildings/{buildingId}/units/{unitId}/tenants`
- URI 마지막에 `/`를 포함하지 않는다.
- 파일 확장자를 URI에 포함하지 않는다. (Content Negotiation은 `Accept` 헤더 사용)

### 3.3. 쿼리 파라미터 (Query Parameters)
- 자원 컬렉션에 대한 필터링, 정렬, 페이지네이션, 특정 필드 선택 등에 사용한다.
- 파라미터명은 **camelCase**를 사용한다. (팀 표준: **camelCase** / 또는 snake_case - 하나로 통일)
    - 예: `status`, `sortBy`, `sortDirection`, `page`, `size`, `fields`
- 예시:
    - `/buildings?status=active&page=1&size=20`
    - `/management-fees?buildingId={buildingId}&yearMonth=2025-06&sortBy=unitNumber&sortDirection=asc`

## 4. HTTP 메소드 (HTTP Methods)
- 각 HTTP 메소드는 CRUD 연산에 다음과 같이 매핑하여 사용한다:
    - **`GET`**: 자원 조회 (Read). 본문(body)을 사용하지 않으며, 멱등성(Idempotent)을 가진다.
    - **`POST`**: 자원 생성 (Create). 본문을 통해 생성할 자원 정보를 전달받는다. 멱등성을 가지지 않는다.
        - 성공 시 `201 Created` 상태 코드와 `Location` 헤더(생성된 자원의 URI)를 반환한다.
    - **`PUT`**: 자원 전체 수정 (Update) 또는 지정된 ID로 자원 생성. 본문을 통해 수정할 전체 자원 정보를 전달받는다. 멱등성을 가진다.
    - **`PATCH`**: 자원 부분 수정 (Partial Update). 본문을 통해 수정할 일부 자원 정보만 전달받는다. 일반적으로 멱등성을 가지지 않는다.
    - **`DELETE`**: 자원 삭제 (Delete). 멱등성을 가진다. 성공 시 `204 No Content` 또는 삭제된 자원 정보를 반환할 수 있다.

## 5. 요청 (Request)
### 5.1. 헤더 (Headers)
- **`Content-Type`**: 요청 본문의 미디어 타입을 명시한다. QIRO API는 `application/json`을 기본으로 사용한다.
- **`Authorization`**: 인증 토큰을 전달한다. (예: `Bearer <JWT_TOKEN>`)
- **`Accept`**: 클라이언트가 응답받기를 원하는 미디어 타입을 명시한다. 기본은 `application/json`.
- **(선택) `X-QIRO-Client-Version`**: 클라이언트 애플리케이션 버전을 명시 (문제 추적 및 호환성 관리용).

### 5.2. 본문 (Body)
- `POST`, `PUT`, `PATCH` 메소드 요청 시 사용된다.
- **JSON (JavaScript Object Notation)** 형식을 기본으로 사용한다.
- 속성(Property) 명명 규칙은 **camelCase**를 사용한다. (팀 표준: **camelCase** / 또는 snake_case - 하나로 통일)
- 날짜 및 시간은 **ISO 8601** 형식 (`YYYY-MM-DDTHH:mm:ss.sssZ` 또는 `YYYY-MM-DD`)을 사용한다. 타임존은 UTC를 기본으로 한다.
- 빈 값(Empty Value) 처리:
    - `null`: 해당 속성 값이 없거나 알 수 없음을 의미.
    - 빈 문자열 `""`: 문자열 속성 값이 비어 있음을 의미.
    - (필드가 선택 사항이고 값이 없는 경우, 요청 본문에서 해당 필드를 생략하는 것을 권장)

## 6. 응답 (Response)
### 6.1. 상태 코드 (HTTP Status Codes)
- 표준 HTTP 상태 코드를 의미에 맞게 사용한다.
    - **`2xx` (성공):**
        - `200 OK`: 요청 성공 (GET, PUT, PATCH, DELETE - 내용 반환 시).
        - `201 Created`: 자원 생성 성공 (POST). `Location` 헤더에 생성된 자원 URI 포함.
        - `204 No Content`: 요청은 성공했으나 응답할 내용이 없음 (DELETE, PUT - 내용 반환 안 할 시).
    - **`4xx` (클라이언트 오류):**
        - `400 Bad Request`: 요청 형식 오류, 유효성 검사 실패 등.
        - `401 Unauthorized`: 인증되지 않은 사용자의 요청.
        - `403 Forbidden`: 인증은 되었으나 해당 자원에 대한 권한 없음.
        - `404 Not Found`: 요청한 자원이 존재하지 않음.
        - `405 Method Not Allowed`: 허용되지 않은 HTTP 메소드 사용.
        - `409 Conflict`: 자원 충돌 (예: 중복된 데이터 생성 시도).
        - `422 Unprocessable Entity`: 요청 형식은 맞으나 의미상 오류 (예: 비즈니스 규칙 위반).
    - **`5xx` (서버 오류):**
        - `500 Internal Server Error`: 서버 내부 오류 발생.
        - `503 Service Unavailable`: 서비스 일시적 사용 불가 (점검 등).

### 6.2. 헤더 (Headers)
- **`Content-Type`**: 응답 본문의 미디어 타입을 명시한다. QIRO API는 `application/json`을 기본으로 사용한다.
- **`Location`**: `201 Created` 응답 시 생성된 자원의 URI를 명시한다.
- **(선택) `X-Total-Count`**: `GET` 요청으로 컬렉션 조회 시, 페이지네이션과 관계없이 전체 아이템 개수를 명시.

### 6.3. 본문 (Body)
- **JSON 형식**을 기본으로 사용한다.
- 속성(Property) 명명 규칙은 요청 본문과 동일하게 **camelCase**를 사용한다. (팀 표준 일관성)
- 날짜 및 시간은 **ISO 8601** 형식을 사용한다.
- **일관된 응답 구조 (Data Envelope):**
    - 단일 자원 응답:
      ```json
      {
          "data": {
              "id": "...",
              "attribute1": "value1",
              // ...
          }
      }
      ```
    - 자원 컬렉션 응답 (페이지네이션 포함):
      ```json
      {
          "data": [
              { "id": "...", "attribute1": "value1", ... },
              { "id": "...", "attribute1": "value2", ... }
          ],
          "pagination": {
              "totalElements": 100,
              "totalPages": 10,
              "currentPage": 1,
              "pageSize": 10
          }
      }
      ```
    - (또는, { "success": true/false, "data": ..., "error": ... } 구조도 고려 가능. 팀 내 논의 후 결정)

## 7. 오류 응답 (Error Response)
- `4xx`, `5xx` 오류 발생 시 일관된 JSON 형식의 오류 메시지를 반환한다.
- 오류 응답 구조 예시:
  ```json
  {
      "timestamp": "2025-05-28T12:59:41.123Z",
      "status": 400,
      "error": "Bad Request",
      "message": "입력값이 유효하지 않습니다. (상세 메시지 또는 필드별 오류)",
      "path": "/requested/uri",
      "details": [ // 선택 사항: 유효성 검사 실패 시 필드별 상세 오류
          {
              "field": "fieldName",
              "rejectedValue": "invalidValue",
              "message": "필드 값은 비어 있을 수 없습니다."
          }
      ]
  }
  ```
- (또는, { "success": false, "error": { "code": "UNIQUE_ERROR_CODE", "message": "사용자 친화적 메시지", "details": ... } } 구조)
- 오류 코드(UNIQUE_ERROR_CODE)를 정의하여 클라이언트가 오류 유형을 식별하고 처리할 수 있도록 지원한다. (부록에 공통 오류 코드 목록 정의)

## 8. 보안 (Security)
- **HTTPS (TLS) 필수:** 모든 API 통신은 HTTPS를 사용한다.
- **인증 (Authentication):** JWT (JSON Web Token) 기반의 Bearer Token 인증 방식을 사용한다. (상세 내용은 별도 인증 명세 참조)
- **인가 (Authorization):** 역할 기반 접근 제어(RBAC)를 적용하여 각 API 엔드포인트 및 자원에 대한 접근 권한을 관리한다.
- **입력 값 검증 (Input Validation):** 서버 측에서 모든 사용자 입력 값에 대한 철저한 유효성 검증을 수행하여 SQL Injection, XSS 등의 공격을 방지한다.
- **민감 정보 노출 최소화:** 응답 데이터에 불필요한 민감 정보를 포함하지 않는다.
- **Rate Limiting & Throttling:** API Gateway 또는 애플리케이션 레벨에서 API 호출 빈도 및 요청량 제한을 설정하여 서비스 남용을 방지한다.

## 9. 버전 관리 (Versioning)
- API 변경 시 하위 호환성을 최대한 유지하되, Breaking Change가 발생하는 경우 명시적인 버전 관리를 수행한다.
- **URI 경로에 버전 정보 포함**하는 방식을 기본으로 한다.
    - 예: `/v1/buildings`, `/v2/buildings`
- 버전은 `v{정수}` 형식 (예: `v1`, `v2`)으로 표현한다.
- 각 버전별 API 문서를 제공하고, 이전 버전 지원 중단(Deprecated) 시 충분한 공지 기간을 둔다.

## 10. 문서화 (Documentation)
- **OpenAPI Specification (OAS) v3.x** (구 Swagger)를 사용하여 API 명세를 작성하고 관리한다.
- 각 API 엔드포인트별로 다음 정보를 명확히 기술한다:
    - 기능 설명
    - URI 및 HTTP 메소드
    - 경로 파라미터, 쿼리 파라미터 (명칭, 타입, 필수 여부, 설명)
    - 요청 헤더 및 본문 (데이터 모델, 예제)
    - 응답 상태 코드, 헤더 및 본문 (데이터 모델, 예제)
    - 필요한 권한
    - 예시 요청/응답
- API 문서는 개발자 포털 또는 접근 가능한 위치에 게시하고 항상 최신 상태를 유지한다. (예: Swagger UI, ReDoc)

## 11. 명명 규칙 요약 (Naming Convention Summary - 팀 표준)
- **URI 경로 세그먼트:** **하이픈 (`-`)** 사용 (예: `management-fees`)
- **쿼리 파라미터:** **camelCase** 사용 (예: `buildingId`, `yearMonth`)
- **JSON 속성 (요청/응답):** **camelCase** 사용 (예: `buildingName`, `totalAmount`)
- **(기타 팀 내에서 합의된 명명 규칙 명시)**

## 12. (선택) 부록: 공통 오류 코드 목록
| 오류 코드 (Error Code) | HTTP 상태 | 메시지 (Description)                  |
| :--------------------- | :---------- | :------------------------------------ |
| `INVALID_INPUT_VALUE`  | 400         | 입력값이 유효하지 않음                  |
| `RESOURCE_NOT_FOUND`   | 404         | 요청한 자원을 찾을 수 없음              |
| `UNAUTHORIZED_ACCESS`  | 401         | 인증되지 않은 접근                      |
| `FORBIDDEN_ACCESS`     | 403         | 해당 자원에 대한 접근 권한 없음         |
| `DUPLICATE_RESOURCE`   | 409         | 이미 존재하는 자원 (예: 중복 등록 시도) |
| `INTERNAL_SERVER_ERROR`| 500         | 서버 내부 오류 발생                     |
| ...                    | ...         | ...                                   |

## 13. 문서 이력
| 버전 | 날짜          | 작성자 | 주요 변경 내용               |
| :--- | :------------ | :----- | :--------------------------- |
| 1.0  | 2025-05-28    | (이름)  | QIRO API 설계 가이드라인 초안 작성 |
|      |               |        |                              |

---