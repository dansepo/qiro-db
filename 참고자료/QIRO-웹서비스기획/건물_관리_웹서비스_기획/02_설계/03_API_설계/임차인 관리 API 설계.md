
# 👥 QIRO 임차인 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 임차인 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-TNMGMT-001 - QIRO - 임차인 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 임차인 정보 및 임차인 관련 부가 정보(차량 등) 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 임차인 (Tenants) 관리 API (`/tenants`)

#### 4.1.1. 신규 임차인 등록
- **HTTP Method:** `POST`
- **URI:** `/tenants`
- **설명:** 새로운 임차인 정보를 시스템에 등록한다. 임대 계약 생성 시 함께 등록되거나, 별도로 등록 후 계약에 연결될 수 있다.
- **요청 권한:** 총괄관리자, 관리소장
- **Request Body:** `TenantCreateRequestDto`
  ```json
  {
      "name": "성춘향",
      "contactNumber": "010-1111-2222",
      "email": "chunhyang@qiro.com", // 선택 사항
      "unitId": "unit-uuid-101", // 현재 배정 또는 계약 예정 호실 ID
      "leaseContractId": "contract-uuid-001", // 연결된 주 임대 계약 ID (선택 사항, 계약과 별도 생성 시)
      "moveInDate": "2025-07-01",
      "status": "RESIDING", // RESIDING, MOVING_OUT, MOVED_OUT 등 Enum
      "emergencyContact": { // 선택 사항
          "name": "변학도",
          "relation": "지인",
          "contactNumber": "010-3333-4444"
      },
      "vehicles": [ // 선택 사항: 초기 차량 정보
          {
              "vehicleNumber": "12가 3456",
              "vehicleModel": "소나타",
              "remarks": "정기 방문 차량"
          }
      ]
  }
  ```

- **Request Body 필드 설명:** (주요 필드)

  | 필드명             | 타입          | 필수 | 설명                                           |
  | :----------------- | :------------ | :--- | :--------------------------------------------- |
  | name             | String        | Y    | 임차인명 (개인 또는 사업체명)                  |
  | contactNumber    | String        | Y    | 연락처 (휴대폰 번호)                           |
  | email            | String        | N    | 이메일 주소                                    |
  | unitId           | String        | Y    | 거주/계약 호실 ID                            |
  | leaseContractId  | String        | N    | 연결된 주 임대 계약 ID                         |
  | moveInDate       | String        | Y    | 입주일 (YYYY-MM-DD)                          |
  | status           | String        | Y    | 임차인 상태 (Enum)                             |
  | emergencyContact | Object        | N    | 비상 연락처 정보 (name, relation, contactNumber) |
  | vehicles         | Array&lt;Object> | N    | 차량 정보 목록 (vehicleNumber, vehicleModel, remarks) |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/tenants/{tenantId}`
  - **Body:** `TenantResponseDto` (생성된 임차인 정보, 차량 정보 ID 포함)

- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (unitId 등 참조 ID 오류).

#### 4.1.2. 임차인 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/tenants`

- **설명:** 등록된 임차인 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명        | 타입    | 필수 | 설명                                    | 예시                             |
  | :---------------- | :------ | :--- | :-------------------------------------- | :------------------------------- |
  | buildingId      | String  | N    | 특정 건물 내 임차인 필터링              | building-uuid                  |
  | unitId          | String  | N    | 특정 호실의 임차인 필터링               | unit-uuid                      |
  | name            | String  | N    | 임차인명 검색 (부분 일치)               | 춘향                           |
  | contactNumber   | String  | N    | 연락처 검색                             | 2222                           |
  | status          | String  | N    | 임차인 상태 필터링 (RESIDING, MOVED_OUT 등) | RESIDING                       |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                         | name ASC                       |

- **Success Response:** `200 OK`, `PagedResponse<TenantSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 임차인 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/tenants/{tenantId}`
- **설명:** 지정된 ID의 임차인 상세 정보(연결된 계약 요약, 차량 정보 등 포함)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등
- **Path Parameters:** `tenantId` (임차인 고유 ID)
- **Success Response:** `200 OK`, `TenantDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 임차인 정보 전체 수정

- **HTTP Method:** `PUT`
- **URI:** `/tenants/{tenantId}`
- **설명:** 지정된 ID의 임차인 정보를 전체 수정한다. (차량 정보 등 부속 정보는 별도 API 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `tenantId`
- **Request Body:** `TenantUpdateRequestDto` (4.1.1의 Create DTO와 유사하나, 수정 가능한 필드만. `unitId`, `leaseContractId` 변경은 신중해야 함)
- **Success Response:** `200 OK`, `TenantResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.5. 임차인 정보 부분 수정 (상태, 연락처, 퇴거일 등)

- **HTTP Method:** `PATCH`

- **URI:** `/tenants/{tenantId}`

- **설명:** 지정된 ID의 임차인 정보 중 일부를 수정한다.

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:** `tenantId`

- Request Body:

```
  TenantPartialUpdateRequestDto
```

   (수정할 필드만 포함)

  JSON

  ```
  {
      "contactNumber": "010-5555-6666",
      "email": "new.chunhyang@qiro.com",
      "status": "MOVING_OUT",
      "moveOutDate": "2025-12-31"
  }
  ```

- **Success Response:** `200 OK`, `TenantResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 임차인 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/tenants/{tenantId}`
- **설명:** 지정된 ID의 임차인 정보를 삭제한다. (보통 '퇴거 완료' 후, 미납금 등이 없을 때 논리적 삭제 또는 비활성화)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `tenantId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건 - 예: 미정산 금액 존재).

------

### 4.2. 임차인 차량 정보 관리 API (`/tenants/{tenantId}/vehicles`)

#### 4.2.1. 특정 임차인의 차량 정보 추가

- **HTTP Method:** `POST`

- **URI:** `/tenants/{tenantId}/vehicles`

- **설명:** 특정 임차인에게 차량 정보를 추가한다.

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:** `tenantId`

- Request Body:

  ```
  TenantVehicleCreateRequestDto
  ```

  JSON

  ```
  {
      "vehicleNumber": "서울12나 7890",
      "vehicleModel": "K5",
      "remarks": "세대주 차량"
  }
  ```

- **Success Response:** `201 Created`, `Location` 헤더, `TenantVehicleResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (tenantId).

#### 4.2.2. 특정 임차인의 차량 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/tenants/{tenantId}/vehicles`
- **요청 권한:** 총괄관리자, 관리소장 등
- **Path Parameters:** `tenantId`
- **Success Response:** `200 OK`, `List<TenantVehicleResponseDto>`

#### 4.2.3. 특정 임차인의 특정 차량 정보 수정

- **HTTP Method:** `PUT`
- **URI:** `/tenants/{tenantId}/vehicles/{vehicleId}`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `tenantId`, `vehicleId`
- **Request Body:** `TenantVehicleUpdateRequestDto` (Create DTO와 유사)
- **Success Response:** `200 OK`, `TenantVehicleResponseDto`

#### 4.2.4. 특정 임차인의 특정 차량 정보 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/tenants/{tenantId}/vehicles/{vehicleId}`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `tenantId`, `vehicleId`
- **Success Response:** `204 No Content`

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `TenantResponseDto` / `TenantSummaryDto` / `TenantDetailResponseDto`

JSON

  ```
// TenantSummaryDto (목록용)
{
    "tenantId": "string",
    "name": "string",
    "contactNumber": "string",
    "unitInfo": { // 간략한 호실 정보
        "unitId": "string",
        "unitNumber": "string", // 예: "101동 1001호"
        "buildingName": "string"
    },
    "status": "string (Enum: RESIDING, MOVING_OUT, MOVED_OUT)"
}

// TenantDetailResponseDto (상세용)
{
    "tenantId": "string",
    "name": "string",
    "contactNumber": "string",
    "email": "string (nullable)",
    "unitId": "string",
    "unitNumber": "string", // 편의상 추가
    "buildingId": "string", // 편의상 추가
    "buildingName": "string", // 편의상 추가
    "leaseContractId": "string (nullable)", // 주 계약 ID
    "leaseContractPeriod": "string (nullable)", // 예: "2024-01-01 ~ 2025-12-31"
    "moveInDate": "string (YYYY-MM-DD)",
    "moveOutDate": "string (YYYY-MM-DD, nullable)",
    "status": "string (Enum)",
    "emergencyContact": {
        "name": "string (nullable)",
        "relation": "string (nullable)",
        "contactNumber": "string (nullable)"
    },
    "vehicles": [ // array of TenantVehicleResponseDto
        {
            "vehicleId": "string",
            "vehicleNumber": "string",
            "vehicleModel": "string (nullable)",
            "remarks": "string (nullable)"
        }
    ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `TenantVehicleResponseDto`

JSON

```
{
    "vehicleId": "string",
    "tenantId": "string", // 불필요할 수 있음 (이미 부모 리소스에서 tenantId 명시)
    "vehicleNumber": "string",
    "vehicleModel": "string (nullable)",
    "remarks": "string (nullable)",
    "createdAt": "string (ISO DateTime)"
}
```

(Create/Update Request DTO들은 위 Response DTO에서 ID 및 감사 필드 제외, 필요한 입력 필드 포함)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

