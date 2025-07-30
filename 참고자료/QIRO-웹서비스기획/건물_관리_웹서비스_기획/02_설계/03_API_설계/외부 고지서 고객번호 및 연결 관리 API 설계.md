
# 📲 QIRO 외부 고지서 고객번호 및 연결 관리 API 설계

## 1. 문서 정보

- **문서명:** QIRO 외부 고지서 고객번호 및 연결 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **작성일:** 2025년 06월 03일
- **최종 수정일:** 2025년 06월 03일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요

본 문서는 QIRO 서비스의 "외부 고지서 고객번호 및 연결 관리" 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 건물별 외부 공과금 고객번호 정보를 등록하고, 해당 고객번호의 관리비 청구 용도(개별/공용)를 설정할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항

- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** 모든 요청 및 응답 본문은 `application/json` 형식을 사용하며, 문자 인코딩은 `UTF-8`을 사용한다.
- **JSON 속성 명명 규칙:** `camelCase`를 사용한다.
- **날짜 및 시간 형식:** `ISO 8601` 형식 (`YYYY-MM-DDTHH:mm:ss.sssZ` 또는 `YYYY-MM-DD`)을 사용한다.
- **오류 응답 형식:**
  ```json
  {
      "timestamp": "2025-06-03T11:00:00.123Z",
      "status": 400, // HTTP 상태 코드
      "error": "Bad Request", // HTTP 상태 메시지
      "message": "사용자 친화적 오류 메시지",
      "path": "/requested/uri",
      "details": [ // 선택 사항: 필드별 유효성 검사 오류 등
          {
              "field": "fieldName",
              "rejectedValue": "invalidValue",
              "message": "오류 상세 내용"
          }
      ]
  }
  ```

## 4. API 엔드포인트 (Endpoints)

------

### 4.1. 외부 고지서 고객번호 정보 생성

- **HTTP Method:** `POST`

- **URI:** `/external-bill-accounts`

- **설명:** 새로운 외부 고지서 고객번호 정보를 시스템에 등록한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Request Body:** `ExternalBillAccountCreateRequestDto`

  JSON

```
  {
      "buildingId": "building-uuid-string",
      "customerNumber": "1234567890",
      "utilityType": "ELECTRICITY",
      "supplierName": "한국전력공사",
      "accountNickname": "본관 전체 전기",
      "meterNumber": "METER_SN_00123",
      "remarks": "월별 고지서 확인 필요",
      "isForIndividualUsage": false,
      "isForCommonUsage": true,
      "isActive": true
  }
```

- **Request Body 필드 설명:**

  | 필드명                 | 타입    | 필수 | 설명                                                        | 비고                                |
  | :--------------------- | :------ | :--- | :---------------------------------------------------------- | :---------------------------------- |
  | buildingId           | String  | Y    | 연결된 건물의 고유 ID                                       | UUID 형식 권장                      |
  | customerNumber       | String  | Y    | 고객번호/납부자번호                                         | 최대 50자, (buildingId + utilityType 내 중복 불가 권장) |
  | utilityType          | String  | Y    | 공과금 종류 코드                                            | Enum: ELECTRICITY, WATER, GAS 등 |
  | supplierName         | String  | Y    | 공급자명                                                    | 최대 100자                          |
  | accountNickname      | String  | Y    | 계정 별칭 (사용자 식별용)                                   | 최대 100자                          |
  | meterNumber          | String  | N    | 관련 계량기 번호                                            | 최대 50자                           |
  | remarks              | String  | N    | 메모                                                        | 최대 500자                          |
  | isForIndividualUsage | Boolean | Y    | 개별 사용료 청구 대상 여부                                  | 기본값 false                       |
  | isForCommonUsage     | Boolean | Y    | 공용 사용료 청구 대상 여부                                  | 기본값 false                       |
  | isActive             | Boolean | N    | 활성 상태 여부                                              | 기본값 true                        |

- **Success Response:**

  - **Code:** `201 Created`

  - **Headers:** `Location: /v1/external-bill-accounts/{extBillAccountId}`

  - Body:

  ```
    ExternalBillAccountResponseDto
  ```
  
     (생성된 자원 정보)
  
    JSON
  
    ```
    {
        "extBillAccountId": "eba-uuid-string-001",
        "buildingId": "building-uuid-string",
        "customerNumber": "1234567890",
        "utilityType": "ELECTRICITY",
        "supplierName": "한국전력공사",
        "accountNickname": "본관 전체 전기",
        "meterNumber": "METER_SN_00123",
        "remarks": "월별 고지서 확인 필요",
        "isForIndividualUsage": false,
        "isForCommonUsage": true,
        "isActive": true,
        "createdAt": "2025-06-03T11:05:00.000Z",
        "lastModifiedAt": "2025-06-03T11:05:00.000Z"
    }
    ```

- **Error Responses:**

  - `400 Bad Request`: 입력값 유효성 오류 (필수 항목 누락, 형식 오류, 중복 등).
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: `buildingId`에 해당하는 건물이 없을 경우.

------

### 4.2. 외부 고지서 고객번호 정보 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/external-bill-accounts`

- **설명:** 등록된 외부 고지서 고객번호 정보 목록을 조회한다. 필터링, 정렬, 페이지네이션 기능을 지원한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등 조회 권한이 있는 사용자

- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                    | 예시                        |
  | :------------------- | :------ | :--- | :-------------------------------------- | :-------------------------- |
  | buildingId         | String  | N    | 특정 건물의 고객번호 정보만 필터링        | building-uuid-string    |
  | utilityType        | String  | N    | 공과금 종류로 필터링                    | WATER                     |
  | supplierName       | String  | N    | 공급자명 검색 (부분 일치)               | 가스                      |
  | accountNickname    | String  | N    | 별칭 검색 (부분 일치)                   | A동                       |
  | customerNumber     | String  | N    | 고객번호 검색 (부분 일치)               | 12345                     |
  | isActive           | Boolean | N    | 활성 상태로 필터링                      | true                      |
  | page               | Integer | N    | 페이지 번호 (0부터 시작)                | 0 (기본값)                |
  | size               | Integer | N    | 페이지 당 항목 수                       | 20 (기본값, 최대 100)     |
  | sortBy             | String  | N    | 정렬 기준 필드 (예: accountNickname)  | createdAt (기본값)        |
  | sortDirection      | String  | N    | 정렬 방향 (ASC, DESC)               | DESC (기본값)             |

- **Success Response:**

  - **Code:** `200 OK`

  - Body:

    ```
    PagedExternalBillAccountResponseDto
    ```

    JSON

    ```
    {
        "data": [
            {
                "extBillAccountId": "eba-uuid-string-001",
                "buildingId": "building-uuid-string",
                "customerNumber": "1234567890",
                "utilityType": "ELECTRICITY",
                "supplierName": "한국전력공사",
                "accountNickname": "본관 전체 전기",
                "meterNumber": "METER_SN_00123",
                "isForIndividualUsage": false,
                "isForCommonUsage": true,
                "isActive": true,
                "createdAt": "2025-06-03T11:05:00.000Z"
            }
            // ... more items
        ],
        "pagination": {
            "totalElements": 5,
            "totalPages": 1,
            "currentPage": 0,
            "pageSize": 20
        }
    }
    ```

- **Error Responses:**

  - `400 Bad Request`: 잘못된 쿼리 파라미터 형식.
  - `401 Unauthorized`: 인증 실패.

------

### 4.3. 특정 외부 고지서 고객번호 정보 상세 조회

- **HTTP Method:** `GET`

- **URI:** `/external-bill-accounts/{accountId}`

- **설명:** 지정된 ID의 외부 고지서 고객번호 정보 상세를 조회한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등 조회 권한이 있는 사용자

- **Path Parameters:**

  | 파라미터명     | 타입         | 설명                          |
  | :------------- | :----------- | :---------------------------- |
  | accountId    | UUID / Long  | 조회할 외부 고지서 계정의 ID  |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `ExternalBillAccountResponseDto` (4.1의 성공 응답 본문과 동일한 구조)

- **Error Responses:**

  - `401 Unauthorized`: 인증 실패.
  - `404 Not Found`: 해당 ID의 정보가 존재하지 않음.

------

### 4.4. 외부 고지서 고객번호 정보 전체 수정

- **HTTP Method:** `PUT`

- **URI:** `/external-bill-accounts/{accountId}`

- **설명:** 지정된 ID의 외부 고지서 고객번호 정보 전체를 수정한다. 모든 필수 필드를 포함해야 한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명     | 타입         | 설명                          |
  | :------------- | :----------- | :---------------------------- |
  | accountId    | UUID / Long  | 수정할 외부 고지서 계정의 ID  |

- **Request Body:** `ExternalBillAccountUpdateRequestDto` (4.1의 `ExternalBillAccountCreateRequestDto` 와 필드 동일, `buildingId`는 보통 수정 불가 대상이나 정책에 따라 결정)

  JSON

  ```
  {
      "customerNumber": "1234567890",
      "utilityType": "ELECTRICITY",
      "supplierName": "한국전력공사",
      "accountNickname": "본관 전체 전기 (수정)",
      "meterNumber": "METER_SN_00123_NEW",
      "remarks": "메모 수정됨",
      "isForIndividualUsage": true,
      "isForCommonUsage": true,
      "isActive": true
  }
  ```

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `ExternalBillAccountResponseDto` (수정된 자원 정보)

- **Error Responses:**

  - `400 Bad Request`: 입력값 유효성 오류.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 정보가 존재하지 않음.
  - `409 Conflict`: 수정하려는 정보가 다른 제약조건(예: 중복)에 위배될 경우.

------

### 4.5. 외부 고지서 고객번호 정보 부분 수정

- **HTTP Method:** `PATCH`

- **URI:** `/external-bill-accounts/{accountId}`

- **설명:** 지정된 ID의 외부 고지서 고객번호 정보 중 일부를 수정한다. (예: 별명 변경, 활성 상태 변경, 청구 용도 플래그 변경)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명     | 타입         | 설명                          |
  | :------------- | :----------- | :---------------------------- |
  | accountId    | UUID / Long  | 수정할 외부 고지서 계정의 ID  |

- **Request Body:** `ExternalBillAccountPartialUpdateRequestDto` (수정할 필드만 포함)

  JSON

  ```
  // 예시 1: 청구 용도만 변경
  {
      "isForIndividualUsage": true,
      "isForCommonUsage": false
  }
  
  // 예시 2: 별명 및 활성 상태 변경
  {
      "accountNickname": "본관 1층 상가 전기",
      "isActive": false
  }
  ```

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `ExternalBillAccountResponseDto` (수정된 자원 정보)

- **Error Responses:**

  - `400 Bad Request`: 입력값 유효성 오류.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 정보가 존재하지 않음.

------

### 4.6. 외부 고지서 고객번호 정보 삭제

- **HTTP Method:** `DELETE`

- **URI:** `/external-bill-accounts/{accountId}`

- **설명:** 지정된 ID의 외부 고지서 고객번호 정보를 삭제한다. (실제 삭제 또는 비활성화 처리 - 정책에 따름. 연결된 월별 고지서 금액 입력 내역 등이 있을 경우 논리적 삭제 권장)

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:**

  | 파라미터명     | 타입         | 설명                          |
  | :------------- | :----------- | :---------------------------- |
  | accountId    | UUID / Long  | 삭제할 외부 고지서 계정의 ID  |

- **Success Response:**

  - **Code:** `204 No Content` (성공적으로 삭제 또는 비활성화 처리 시)
  - 또는 `200 OK`와 함께 상태가 변경된 정보 반환 (논리적 삭제 시).

- **Error Responses:**

  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 정보가 존재하지 않음.
  - `409 Conflict`: 삭제할 수 없는 조건일 때 (예: 이미 사용 중인 데이터가 있어 물리 삭제 불가).

## 5. 데이터 모델 (DTOs)

### 5.1. `ExternalBillAccountResponseDto`

JSON

```
{
    "extBillAccountId": "string (UUID or Long)",
    "buildingId": "string (UUID or Long)",
    "customerNumber": "string",
    "utilityType": "string (Enum: ELECTRICITY, WATER, GAS, HEATING, etc.)",
    "supplierName": "string",
    "accountNickname": "string",
    "meterNumber": "string (nullable)",
    "remarks": "string (nullable)",
    "isForIndividualUsage": "boolean",
    "isForCommonUsage": "boolean",
    "isActive": "boolean",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
```

### 5.2. `ExternalBillAccountCreateRequestDto`

(4.1 요청 본문 필드와 동일. 모든 필수 필드 포함)

### 5.3. `ExternalBillAccountUpdateRequestDto`

(4.4 요청 본문 필드와 동일. `buildingId`는 일반적으로 변경 불가하나, 모든 필수값 포함하여 자원 전체 교체)

### 5.4. `ExternalBillAccountPartialUpdateRequestDto`

(4.5 요청 본문 필드와 동일. 모든 필드는 선택 사항)

### 5.5. `PagedExternalBillAccountResponseDto`

JSON

```
{
    "data": [
        // array of ExternalBillAccountResponseDto
    ],
    "pagination": {
        "totalElements": "long",
        "totalPages": "integer",
        "currentPage": "integer", // 0-indexed
        "pageSize": "integer"
    }
}
```

