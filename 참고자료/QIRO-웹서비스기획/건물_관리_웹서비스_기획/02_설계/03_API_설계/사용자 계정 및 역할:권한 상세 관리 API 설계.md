
# 👤 QIRO 사용자 계정 및 역할/권한 상세 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 사용자 계정 및 역할/권한 상세 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-USERROLEMGMT-001 - QIRO - 사용자 계정 및 역할/권한 상세 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 내부 직원 사용자 계정, 역할, 역할에 따른 권한 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 이를 통해 시스템 관리자는 최소 권한 원칙에 입각하여 안전하고 효율적인 사용자 접근 통제를 구현할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 내부 사용자 (직원) 계정 관리 API (`/internal-users`)

#### 4.1.1. 신규 직원 계정 생성
- **HTTP Method:** `POST`
- **URI:** `/internal-users`
- **설명:** 새로운 내부 직원 사용자 계정을 시스템에 등록한다. 초기 비밀번호 설정 방식 및 역할 할당을 포함한다.
- **요청 권한:** 총괄관리자
- **Request Body:** `InternalUserCreateRequestDto`
  ```json
  {
      "email": "new.staff@qiro.com",
      "name": "김유신",
      "department": "운영1팀", // 선택 사항
      "initialPassword": "Password123!", // 또는 passwordSetupMethod: "INVITE_VIA_EMAIL"
      "roleIds": ["role-uuid-building-manager"], // 할당할 역할 ID 목록
      "assignedBuildingIds": ["building-uuid-001", "building-uuid-002"], // 담당 건물 ID 목록 (선택 사항)
      "mfaEnabled": false // 선택 사항, 기본값 false
  }
  ```

- **Request Body 필드 설명:** (주요 필드)

  | 필드명                 | 타입          | 필수 | 설명                                      |
  | :--------------------- | :------------ | :--- | :---------------------------------------- |
  | email                | String        | Y    | 이메일 주소 (로그인 ID)                   |
  | name                 | String        | Y    | 이름                                      |
  | department           | String        | N    | 소속 부서                                 |
  | initialPassword      | String        | (조건부Y)| 초기 비밀번호 (직접 설정 시)              |
  | passwordSetupMethod  | String        | (조건부Y)| 비밀번호 설정 방식 (예: DIRECT, INVITE_VIA_EMAIL) |
  | roleIds              | Array&lt;String> | Y    | 할당할 역할의 ID 목록                     |
  | assignedBuildingIds  | Array&lt;String> | N    | 담당할 건물의 ID 목록                     |
  | mfaEnabled           | Boolean       | N    | 2단계 인증(MFA) 초기 활성화 여부        |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/internal-users/{userId}`
  - **Body:** `InternalUserResponseDto` (생성된 사용자 정보)

- **Error Responses:** `400 Bad Request` (입력값 유효성 오류, 이메일 중복 등), `401 Unauthorized`, `403 Forbidden`.

#### 4.1.2. 직원 계정 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/internal-users`

- **설명:** 내부 직원 계정 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자

- **Query Parameters:**

  | 파라미터명      | 타입    | 필수 | 설명                                  | 예시                             |
  | :-------------- | :------ | :--- | :------------------------------------ | :------------------------------- |
  | name          | String  | N    | 이름 검색 (부분 일치)                 | 김유신                         |
  | email         | String  | N    | 이메일 검색 (부분 일치)               | staff@qiro.com                 |
  | roleId        | String  | N    | 특정 역할 ID로 필터링                 | role-uuid-building-manager   |
  | status        | String  | N    | 계정 상태 (ACTIVE, INACTIVE, LOCKED) | ACTIVE                         |
  | department    | String  | N    | 부서명 검색                           | 운영                           |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                       | name ASC                       |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<InternalUserSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

#### 4.1.3. 특정 직원 계정 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/internal-users/{userId}`
- **설명:** 지정된 ID의 직원 계정 상세 정보(할당된 역할, 담당 건물 등 포함)를 조회한다.
- **요청 권한:** 총괄관리자, (자신의 정보) 해당 사용자
- **Path Parameters:** `userId` (직원 계정 고유 ID)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `InternalUserDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.4. 직원 계정 정보 수정 (기본 정보)

- **HTTP Method:** `PUT` (또는 `PATCH` 권장)

- **URI:** `/internal-users/{userId}`

- **설명:** 지정된 ID의 직원 계정 기본 정보(이름, 부서 등)를 수정한다. 역할, 담당 건물, 상태 변경은 별도 PATCH 엔드포인트 사용 권장.

- **요청 권한:** 총괄관리자

- **Path Parameters:** `userId`

- Request Body:

```
  InternalUserUpdateRequestDto
```

   (이름, 부서 등 수정 가능한 필드)

  JSON

  ```
  {
      "name": "김유신 장군",
      "department": "전략기획팀"
  }
  ```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `InternalUserDetailResponseDto` (수정된 정보)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.5. 직원 계정 상태 변경

- **HTTP Method:** `PATCH`

- **URI:** `/internal-users/{userId}/status`

- **설명:** 지정된 직원 계정의 상태(활성, 비활성, 잠금 해제)를 변경한다.

- **요청 권한:** 총괄관리자

- **Path Parameters:** `userId`

- Request Body:

  JSON

  ```
  {
      "status": "INACTIVE" // ACTIVE, INACTIVE, (잠금 해제 시) UNLOCK
  }
  ```

- **Success Response:** `200 OK`, `InternalUserDetailResponseDto`

- **Error Responses:** `400 Bad Request` (유효하지 않은 상태값), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 직원 계정 역할 변경

- **HTTP Method:** `PUT` (또는 `PATCH`)

- **URI:** `/internal-users/{userId}/roles`

- **설명:** 지정된 직원 계정에 할당된 역할을 변경(전체 교체)한다.

- **요청 권한:** 총괄관리자

- **Path Parameters:** `userId`

- Request Body:

  JSON

  ```
  {
      "roleIds": ["role-uuid-new-1", "role-uuid-new-2"]
  }
  ```

- **Success Response:** `200 OK`, `InternalUserDetailResponseDto` (업데이트된 역할 정보 포함)

- **Error Responses:** `400 Bad Request` (존재하지 않는 역할 ID), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.7. 직원 담당 건물 변경

- **HTTP Method:** `PUT` (또는 `PATCH`)

- **URI:** `/internal-users/{userId}/buildings`

- **설명:** 지정된 직원 계정이 접근/담당할 수 있는 건물을 변경(전체 교체)한다.

- **요청 권한:** 총괄관리자

- **Path Parameters:** `userId`

- Request Body:

  JSON

  ```
  {
      "buildingIds": ["building-uuid-new-A", "building-uuid-new-B"]
  }
  ```

- **Success Response:** `200 OK`, `InternalUserDetailResponseDto` (업데이트된 담당 건물 정보 포함)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.8. (관리자) 직원 비밀번호 재설정 요청

- **HTTP Method:** `POST`
- **URI:** `/internal-users/{userId}/actions/reset-password`
- **설명:** 관리자가 특정 직원의 비밀번호 재설정을 요청한다. (시스템이 임시 비밀번호를 생성하여 이메일로 발송하거나, 재설정 링크 발송)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `userId`
- **Success Response:** `200 OK` 또는 `202 Accepted`, `{ "message": "비밀번호 재설정 요청이 처리되었습니다." }`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.9. (관리자) 직원 MFA 설정 초기화/해제

- **HTTP Method:** `POST`
- **URI:** `/internal-users/{userId}/actions/reset-mfa`
- **설명:** 관리자가 특정 직원의 MFA 설정을 초기화하거나 강제로 해제한다 (예: 직원이 OTP 기기 분실 시).
- **요청 권한:** 총괄관리자
- **Path Parameters:** `userId`
- **Success Response:** `200 OK`, `{ "message": "MFA 설정이 초기화/해제되었습니다." }`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.2. 역할 (Role) 관리 API (`/roles`)

#### 4.2.1. 역할 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/roles`
- **설명:** 시스템에 정의된 모든 역할(기본 제공 역할 및 커스텀 역할) 목록을 조회한다.
- **요청 권한:** 총괄관리자 (또는 역할 관리 권한자)
- **Query Parameters:**
 | 파라미터명     | 타입    | 필수 | 설명                                     | 예시         |
 | :------------- | :------ | :--- | :--------------------------------------- | :----------- |
 | `isSystemRole` | Boolean | N    | 시스템 기본 역할만 또는 커스텀 역할만 필터링 | `true`       |

- **Success Response:** `200 OK`, `List<RoleResponseDto>`

#### 4.2.2. 특정 역할 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/roles/{roleId}`
- **설명:** 지정된 ID의 역할 상세 정보(부여된 권한 목록 포함)를 조회한다.
- **요청 권한:** 총괄관리자 (또는 역할 관리 권한자)
- **Path Parameters:** `roleId`
- **Success Response:** `200 OK`, `RoleDetailResponseDto` (권한 목록 포함)

#### 4.2.3. (선택) 신규 커스텀 역할 생성

- **HTTP Method:** `POST`
- **URI:** `/roles`
- **설명:** 새로운 커스텀 역할을 생성한다. (초기 권한은 없거나 최소한으로 부여)
- **요청 권한:** 총괄관리자
- **Request Body:** `RoleCreateRequestDto` (`roleName`, `description`)
- **Success Response:** `201 Created`, `Location` 헤더, `RoleResponseDto`

#### 4.2.4. (선택) 커스텀 역할 수정 (이름, 설명, 권한 변경)

- **HTTP Method:** `PUT`
- **URI:** `/roles/{roleId}`
- **설명:** 지정된 커스텀 역할의 이름, 설명 및 부여된 권한 목록을 수정한다. 시스템 기본 역할은 수정 불가.
- **요청 권한:** 총괄관리자
- **Path Parameters:** `roleId`
- **Request Body:** `RoleUpdateRequestDto` (`roleName`, `description`, `permissionIds`: Array&lt;String>)
- **Success Response:** `200 OK`, `RoleDetailResponseDto`

#### 4.2.5. (선택) 커스텀 역할 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/roles/{roleId}`
- **설명:** 지정된 커스텀 역할을 삭제한다. 해당 역할이 할당된 사용자가 없을 경우에만 삭제 가능. 시스템 기본 역할은 삭제 불가.
- **요청 권한:** 총괄관리자
- **Path Parameters:** `roleId`
- **Success Response:** `204 No Content`
- **Error Responses:** `404 Not Found`, `409 Conflict` (사용 중인 역할).

------

### 4.3. 권한 (Permission) 목록 조회 API (`/permissions`)

#### 4.3.1. 전체 권한 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/permissions`
- **설명:** 시스템에 사전 정의된 모든 세부 권한(Permission) 목록을 조회한다. (주로 역할에 권한을 할당하는 UI에서 사용)
- **요청 권한:** 총괄관리자 (또는 역할 관리 권한자)
- **Query Parameters:**
 | 파라미터명 | 타입   | 필수 | 설명                     | 예시        |
 | :--------- | :----- | :--- | :----------------------- | :---------- | 
 | `category` | String | N    | 권한 카테고리로 필터링   | `건물관리`  |

- **Success Response:** `200 OK`, `List<PermissionResponseDto>`

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `InternalUserResponseDto` / `InternalUserSummaryDto` / `InternalUserDetailResponseDto`

JSON

  ```
// InternalUserSummaryDto (목록용)
{
    "userId": "string",
    "email": "string",
    "name": "string",
    "department": "string (nullable)",
    "roles": [{"roleId": "string", "roleName": "string"}], // 요약된 역할 정보
    "status": "string (Enum: ACTIVE, INACTIVE, LOCKED)",
    "lastLoginAt": "string (ISO DateTime, nullable)"
}

// InternalUserDetailResponseDto (상세용)
{
    "userId": "string",
    "email": "string",
    "name": "string",
    "department": "string (nullable)",
    "roles": [ // 상세 역할 정보
        {
            "roleId": "string",
            "roleName": "string",
            "description": "string (nullable)"
        }
    ],
    "assignedBuildings": [ // 담당 건물 정보
        {
            "buildingId": "string",
            "buildingName": "string"
        }
    ],
    "status": "string (Enum)",
    "mfaEnabled": "boolean",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `RoleResponseDto` / `RoleDetailResponseDto`

JSON

```
// RoleResponseDto (목록 및 기본 정보용)
{
    "roleId": "string",
    "roleName": "string",
    "description": "string (nullable)",
    "isSystemRole": "boolean"
}

// RoleDetailResponseDto (상세용 - 권한 포함)
{
    "roleId": "string",
    "roleName": "string",
    "description": "string (nullable)",
    "isSystemRole": "boolean",
    "permissions": [ // array of PermissionResponseDto
        {
            "permissionId": "string",
            "permissionKey": "string", // 예: "building:read"
            "description": "string (nullable)",
            "category": "string (nullable)"
        }
    ]
}
```

### 5.3. `PermissionResponseDto`

JSON

```
{
    "permissionId": "string",
    "permissionKey": "string",
    "description": "string (nullable)",
    "category": "string (nullable)"
}
```

(Create/Update Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

