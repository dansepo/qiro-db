
# 🧑‍💼 QIRO 임대인 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 임대인 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-LSMGMT-001 - QIRO - 임대인 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 임대인 정보, 임대인 소유 자산 연결, 임대인 정산 계좌 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 임대인 (Lessors) 관리 API (`/lessors`)

#### 4.1.1. 신규 임대인 등록
- **HTTP Method:** `POST`
- **URI:** `/lessors`
- **설명:** 새로운 임대인 정보를 시스템에 등록한다. 초기 소유 자산 및 정산 계좌 정보도 함께 등록할 수 있다.
- **요청 권한:** 총괄관리자, 관리소장
- **Request Body:** `LessorCreateRequestDto`
  ```json
  {
      "lessorType": "INDIVIDUAL", // INDIVIDUAL, CORPORATION, SOLE_PROPRIETOR
      "name": "이몽룡",
      "representativeName": null, // lessorType이 CORPORATION일 경우
      "businessNumber": null, // lessorType이 CORPORATION 또는 SOLE_PROPRIETOR일 경우
      "contactNumber": "010-9876-5432",
      "email": "mong@qiro.com",
      "address": {
          "zipCode": "06124",
          "streetAddress": "서울특별시 강남구 도산대로 111",
          "detailAddress": "202호"
      },
      "status": "ACTIVE", // ACTIVE, PENDING, EXPIRED
      "properties": [ // 선택 사항: 초기 소유 자산
          {
              "buildingId": "building-uuid-001",
              "unitId": "unit-uuid-101", // 특정 호실 소유 시
              "ownershipStartDate": "2020-01-01"
          }
      ],
      "bankAccounts": [ // 선택 사항: 초기 정산 계좌
          {
              "bankName": "QIRO은행",
              "accountNumber": "110-234-567890",
              "accountHolderName": "이몽룡",
              "isPrimary": true
          }
      ]
  }
  ```

- Success Response:
  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/lessors/{lessorId}`
  - **Body:** `LessorResponseDto` (생성된 임대인 정보)
- **Error Responses:** `400 Bad Request` (입력값 유효성 오류), `401 Unauthorized`, `403 Forbidden`, `409 Conflict` (사업자번호 중복 등).

#### 4.1.2. 임대인 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/lessors`

- **설명:** 등록된 임대인 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명        | 타입    | 필수 | 설명                                    | 예시              |
  | :---------------- | :------ | :--- | :-------------------------------------- | :---------------- |
  | name            | String  | N    | 임대인명/법인명 검색 (부분 일치)        | 몽룡            |
  | contactNumber   | String  | N    | 연락처 검색                             | 5432            |
  | businessNumber  | String  | N    | 사업자번호 검색                         | 123-45          |
  | lessorType      | String  | N    | 임대인 구분 필터링                      | INDIVIDUAL    |
  | status          | String  | N    | 계약 상태 필터링                        | ACTIVE          |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                         | name ASC        |

- **Success Response:** `200 OK`, `PagedResponse<LessorSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 임대인 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/lessors/{lessorId}`
- **설명:** 지정된 ID의 임대인 상세 정보(연결된 소유 자산, 정산 계좌 포함)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등
- **Path Parameters:** `lessorId` (임대인 고유 ID)
- **Success Response:** `200 OK`, `LessorDetailResponseDto` (소유 자산, 정산 계좌 목록 포함)
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 임대인 정보 전체 수정

- **HTTP Method:** `PUT`
- **URI:** `/lessors/{lessorId}`
- **설명:** 지정된 ID의 임대인 기본 정보를 전체 수정한다. (소유 자산 및 계좌는 별도 API로 관리 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `lessorId`
- **Request Body:** `LessorUpdateRequestDto` (4.1.1의 Create DTO와 유사하나, 수정 가능한 필드만 포함)
- **Success Response:** `200 OK`, `LessorResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.

#### 4.1.5. 임대인 정보 부분 수정

- **HTTP Method:** `PATCH`
- **URI:** `/lessors/{lessorId}`
- **설명:** 지정된 ID의 임대인 정보 중 일부(예: 연락처, 이메일, 상태)를 수정한다.
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `lessorId`
- **Request Body:** `LessorPartialUpdateRequestDto` (수정할 필드만 포함)
- **Success Response:** `200 OK`, `LessorResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 임대인 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/lessors/{lessorId}`
- **설명:** 지정된 ID의 임대인 정보를 삭제한다. (연결된 활성 계약 등이 없을 경우. 보통 논리적 삭제 또는 비활성화)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `lessorId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 임대인 소유 자산 (Lessor Properties) 관리 API

#### 4.2.1. 임대인에게 소유 자산 연결

- **HTTP Method:** `POST`

- **URI:** `/lessors/{lessorId}/properties`

- **설명:** 특정 임대인에게 소유 자산(건물 또는 호실)을 연결한다.

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:** `lessorId`

- Request Body:

```
  LessorPropertyLinkCreateRequestDto
```

  JSON

  ```
  {
      "buildingId": "building-uuid-002",
      "unitId": "unit-uuid-203", // 특정 호실 소유 시, 건물 전체 소유 시 null
      "ownershipStartDate": "2021-03-15",
      "ownershipEndDate": null // null이면 계속 소유
  }
  ```

- **Success Response:** `201 Created`, `LessorPropertyLinkResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (lessorId, buildingId 등).

#### 4.2.2. 특정 임대인의 소유 자산 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/lessors/{lessorId}/properties`
- **요청 권한:** 총괄관리자, 관리소장 등
- **Path Parameters:** `lessorId`
- **Success Response:** `200 OK`, `List<LessorPropertyLinkResponseDto>`

#### 4.2.3. 임대인 소유 자산 연결 정보 수정

- **HTTP Method:** `PUT`
- **URI:** `/lessors/{lessorId}/properties/{linkId}`
- **설명:** 특정 임대인과 자산 간의 연결 정보(예: 소유 기간)를 수정한다.
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `lessorId`, `linkId` (LessorPropertyLink의 ID)
- **Request Body:** `LessorPropertyLinkUpdateRequestDto` (`ownershipStartDate`, `ownershipEndDate` 등)
- **Success Response:** `200 OK`, `LessorPropertyLinkResponseDto`

#### 4.2.4. 임대인 소유 자산 연결 해제

- **HTTP Method:** `DELETE`
- **URI:** `/lessors/{lessorId}/properties/{linkId}`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `lessorId`, `linkId`
- **Success Response:** `204 No Content`

------

### 4.3. 임대인 정산 계좌 (Lessor Bank Accounts) 관리 API

#### 4.3.1. 임대인에게 정산 계좌 추가

- **HTTP Method:** `POST`

- **URI:** `/lessors/{lessorId}/bank-accounts`

- **설명:** 특정 임대인에게 정산(임대료 입금 등)을 위한 은행 계좌 정보를 추가한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Path Parameters:** `lessorId`

- Request Body:

  ```
  LessorBankAccountCreateRequestDto
  ```

  JSON

  ```
  {
      "bankName": "QIRO은행",
      "accountNumber": "110-987-654321",
      "accountHolderName": "이몽룡",
      "isPrimary": false,
      "purpose": "임대료 수입 계좌" // 선택 사항
  }
  ```

- **Success Response:** `201 Created`, `LessorBankAccountResponseDto`

#### 4.3.2. 특정 임대인의 정산 계좌 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/lessors/{lessorId}/bank-accounts`
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등
- **Path Parameters:** `lessorId`
- **Success Response:** `200 OK`, `List<LessorBankAccountResponseDto>`

#### 4.3.3. 임대인 정산 계좌 정보 수정

- **HTTP Method:** `PUT`
- **URI:** `/lessors/{lessorId}/bank-accounts/{bankAccountId}`
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Path Parameters:** `lessorId`, `bankAccountId`
- **Request Body:** `LessorBankAccountUpdateRequestDto` (Create DTO와 유사)
- **Success Response:** `200 OK`, `LessorBankAccountResponseDto`

#### 4.3.4. 임대인 정산 계좌 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/lessors/{lessorId}/bank-accounts/{bankAccountId}`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `lessorId`, `bankAccountId`
- **Success Response:** `204 No Content`
- **Error Responses:** `409 Conflict` (기본 계좌 삭제 시도 등)

#### 4.3.5. (선택) 임대인 주거래 계좌 설정

- **HTTP Method:** `PATCH`
- **URI:** `/lessors/{lessorId}/bank-accounts/{bankAccountId}/set-primary`
- **설명:** 특정 계좌를 해당 임대인의 주거래 정산 계좌로 설정한다. (기존 주거래 계좌는 일반으로 변경)
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Path Parameters:** `lessorId`, `bankAccountId`
- **Success Response:** `200 OK`, `LessorBankAccountResponseDto`

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `LessorResponseDto` / `LessorSummaryDto` / `LessorDetailResponseDto`

JSON

  ```
// LessorSummaryDto (목록용)
{
    "lessorId": "string",
    "name": "string", // 임대인명 또는 법인명
    "lessorType": "string (Enum)",
    "contactNumber": "string",
    "businessNumber": "string (nullable)",
    "status": "string (Enum)",
    "propertyCount": "integer" // 소유/관리 자산 수
}

// LessorDetailResponseDto (상세용)
{
    "lessorId": "string",
    "lessorType": "string (Enum)",
    "name": "string",
    "representativeName": "string (nullable)",
    "businessNumber": "string (nullable)",
    "contactNumber": "string",
    "email": "string (nullable)",
    "address": { /* AddressDto */ },
    "status": "string (Enum)",
    "properties": [ /* array of LessorPropertyLinkResponseDto */ ],
    "bankAccounts": [ /* array of LessorBankAccountResponseDto */ ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `LessorPropertyLinkResponseDto`

JSON

```
{
    "linkId": "string",
    "buildingId": "string",
    "buildingName": "string", // 편의상 추가
    "unitId": "string (nullable)",
    "unitNumber": "string (nullable)", // 편의상 추가
    "ownershipStartDate": "string (YYYY-MM-DD)",
    "ownershipEndDate": "string (YYYY-MM-DD, nullable)"
}
```

### 5.3. `LessorBankAccountResponseDto`

JSON

```
{
    "bankAccountId": "string",
    "bankName": "string",
    "accountNumber": "string", // (응답 시 마스킹 처리 고려)
    "accountHolderName": "string",
    "isPrimary": "boolean",
    "purpose": "string (nullable)"
}
```

(Create/Update Request DTO들은 위 Response DTO에서 ID 및 감사 필드 제외, 필요한 입력 필드 포함)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

