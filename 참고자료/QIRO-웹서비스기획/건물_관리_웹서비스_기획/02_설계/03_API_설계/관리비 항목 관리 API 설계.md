
# API QIRO 관리비 항목 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 관리비 항목 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **작성일:** 2025년 06월 03일
- **최종 수정일:** 2025년 06월 03일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 관리비 항목(Fee Item) 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수하여 설계되었다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** 모든 요청 및 응답 본문은 `application/json` 형식을 사용하며, 문자 인코딩은 `UTF-8`을 사용한다.
- **JSON 속성 명명 규칙:** `camelCase`를 사용한다.
- **날짜 및 시간 형식:** `ISO 8601` 형식 (`YYYY-MM-DDTHH:mm:ss.sssZ` 또는 `YYYY-MM-DD`)을 사용한다.
- **오류 응답 형식:** (API 설계 가이드라인의 표준 오류 응답 형식 참조)
  ```json
  {
      "timestamp": "2025-06-03T10:00:00.123Z",
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

### 4.1. 관리비 항목 생성

- **HTTP Method:** `POST`

- **URI:** `/fee-items`

- **설명:** 새로운 관리비 항목을 시스템에 등록한다. 신규 항목의 '적용 시작일'은 기본적으로 등록일의 익월 1일로 설정되거나, 요청 시 명시된 익월 이후 날짜를 사용한다.

- **요청 권한:** 총괄관리자, 관리소장

- Request Body:

```
  FeeItemCreateRequestDto
```

  JSON

  ```
  {
      "itemName": "세대 일반관리비",
      "impositionMethod": "PER_AREA", // FIXED_AMOUNT, PER_AREA, PER_USAGE, COMMON_TOTAL_PER_AREA, COMMON_TOTAL_PER_SHARE
      "unitPrice": 1500.00,
      "unit": "원/㎡",
      "vatApplicable": true,
      "description": "세대 전용면적 기준으로 부과되는 일반관리비",
      "effectiveStartDate": "2025-07-01", // 선택 사항: 미제공 시 서버에서 익월 1일로 기본 설정
      "effectiveEndDate": null // 선택 사항: null 또는 미제공 시 계속 유효
  }
  ```

- **Request Body 필드 설명:**
 | 필드명                | 타입    | 필수 | 설명                                                                 | 비고                                                               |
 | :-------------------- | :------ | :--- | :------------------------------------------------------------------- | :----------------------------------------------------------------- |
 | `itemName`            | String  | Y    | 항목명                                                               | 최대 50자, 시스템 내 고유 (적용 기간 고려)                         |
 | `impositionMethod`    | String  | Y    | 부과 방식 코드                                                       | Enum 값 중 하나                                                    |
 | `unitPrice`           | Number  | (조건부Y) | 단가 (또는 고정액)                                                   | `FIXED_AMOUNT` 아닐 시 필수                                         |
 | `unit`                | String  | (조건부Y) | 단위                                                                 | `FIXED_AMOUNT` 아닐 시 또는 필요 시                               |
 | `vatApplicable`       | Boolean | Y    | 부가세 적용 여부                                                     | 기본값 `false`                                                      |
 | `description`         | String  | N    | 항목 설명                                                            | 최대 200자                                                         |
 | `effectiveStartDate`  | String  | N    | 적용 시작일 (YYYY-MM-DD). 익월 이후 날짜여야 함. 미제공시 서버 기본값. | 신규 항목은 현재 청구월에 적용 안됨 (R-FEE-SETUP-006)               |
 | `effectiveEndDate`    | String  | N    | 적용 종료일 (YYYY-MM-DD). 시작일 이후여야 함.                         | null이거나 없으면 계속 유효                                          |

- Success Response:

  - **Code:** `201 Created`

  - **Headers:** `Location: /v1/fee-items/{feeItemId}`

  - Body:

  ```
    FeeItemResponseDto
  ```
  
     (생성된 자원 정보)
  
    JSON
  
    ```
    {
        "feeItemId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "itemName": "세대 일반관리비",
        "impositionMethod": "PER_AREA",
        "unitPrice": 1500.00,
        "unit": "원/㎡",
        "vatApplicable": true,
        "description": "세대 전용면적 기준으로 부과되는 일반관리비",
        "effectiveStartDate": "2025-07-01",
        "effectiveEndDate": null,
        "status": "ACTIVE", // 기본 상태
        "createdAt": "2025-06-03T10:00:00.000Z",
        "lastModifiedAt": "2025-06-03T10:00:00.000Z"
    }
    ```

- Error Responses:

  - `400 Bad Request`: 입력값 유효성 오류 (필수 항목 누락, 형식 오류, 중복된 항목명 등). `effectiveStartDate`가 익월 이전일 경우.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.

------

### 4.2. 관리비 항목 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/fee-items`

- **설명:** 등록된 관리비 항목 목록을 조회한다. 필터링, 정렬, 페이지네이션 기능을 지원한다.

- **요청 권한:** 총괄관리자, 관리소장, (선택적으로 경리담당자 등 조회 권한)

- **Query Parameters:**
 | 파라미터명         | 타입    | 필수 | 설명                                      | 예시                      |
 | :----------------- | :------ | :--- | :---------------------------------------- | :------------------------ |
 | `itemName`         | String  | N    | 항목명 검색 (부분 일치)                   | `전기`                    |
 | `impositionMethod` | String  | N    | 부과 방식 코드로 필터링                   | `PER_USAGE`               |
 | `status`           | String  | N    | 상태로 필터링 (`ACTIVE`, `INACTIVE`)      | `ACTIVE`                  |
 | `effectiveOnDate`  | String  | N    | 특정 날짜 기준 유효한 항목 필터링 (YYYY-MM-DD) | `2025-07-15`              |
 | `page`             | Integer | N    | 페이지 번호 (0부터 시작)                  | `0` (기본값)              |
 | `size`             | Integer | N    | 페이지 당 항목 수                         | `20` (기본값, 최대 100)   |
 | `sortBy`           | String  | N    | 정렬 기준 필드 (예: `itemName`, `createdAt`) | `createdAt` (기본값)      |
 | `sortDirection`    | String  | N    | 정렬 방향 (`ASC`, `DESC`)                 | `DESC` (기본값)           |

- Success Response:

  - **Code:** `200 OK`

  - Body:

    ```
    PagedFeeItemResponseDto
    ```

    JSON

    ```
    {
        "data": [
            {
                "feeItemId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
                "itemName": "세대 일반관리비",
                "impositionMethod": "PER_AREA",
                "unitPrice": 1500.00,
                "unit": "원/㎡",
                "vatApplicable": true,
                "effectiveStartDate": "2025-07-01",
                "status": "ACTIVE",
                "createdAt": "2025-06-03T10:00:00.000Z"
            },
            // ... more items
        ],
        "pagination": {
            "totalElements": 25,
            "totalPages": 2,
            "currentPage": 0,
            "pageSize": 20
        }
    }
    ```

- Error Responses:

  - `400 Bad Request`: 잘못된 쿼리 파라미터 형식.
  - `401 Unauthorized`: 인증 실패.

------

### 4.3. 특정 관리비 항목 상세 조회

- **HTTP Method:** `GET`

- **URI:** `/fee-items/{feeItemId}`

- **설명:** 지정된 ID의 관리비 항목 상세 정보를 조회한다.

- **요청 권한:** 총괄관리자, 관리소장, (선택적으로 경리담당자 등 조회 권한)

- **Path Parameters:**
 | 파라미터명   | 타입         | 설명              |
 | :----------- | :----------- | :---------------- |
 | `feeItemId`  | UUID / Long  | 조회할 항목의 ID  |

- Success Response:

  - **Code:** `200 OK`

  - Body:

    ```
    FeeItemResponseDto
    ```

     (4.1의 응답 본문과 동일한 구조)

    JSON

    ```
    {
        "feeItemId": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
        "itemName": "세대 일반관리비",
        "impositionMethod": "PER_AREA",
        "unitPrice": 1500.00,
        "unit": "원/㎡",
        "vatApplicable": true,
        "description": "세대 전용면적 기준으로 부과되는 일반관리비",
        "effectiveStartDate": "2025-07-01",
        "effectiveEndDate": null,
        "status": "ACTIVE",
        "createdAt": "2025-06-03T10:00:00.000Z",
        "lastModifiedAt": "2025-06-03T10:00:00.000Z"
    }
    ```

- Error Responses:

  - `401 Unauthorized`: 인증 실패.
  - `404 Not Found`: 해당 ID의 항목이 존재하지 않음.

------

### 4.4. 관리비 항목 전체 수정

- **HTTP Method:** `PUT`

- **URI:** `/fee-items/{feeItemId}`

- **설명:** 지정된 ID의 관리비 항목 전체 정보를 수정한다. 모든 필수 필드를 포함해야 한다. '상태'를 'INACTIVE'에서 'ACTIVE'로 변경 시, '적용 시작일'은 익월 이후여야 한다.

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:**
 | 파라미터명   | 타입         | 설명              |
 | :----------- | :----------- | :---------------- |
 | `feeItemId`  | UUID / Long  | 수정할 항목의 ID  |

- Request Body:

  ```
  FeeItemUpdateRequestDto
  ```

   (4.1의 

  ```
  FeeItemCreateRequestDto
  ```

   와 유사하나, 모든 필드가 필수일 수 있음)

  JSON

  ```
  {
      "itemName": "세대 일반관리비 (수정)",
      "impositionMethod": "PER_AREA",
      "unitPrice": 1600.00,
      "unit": "원/㎡",
      "vatApplicable": true,
      "description": "세대 전용면적 기준으로 부과되는 일반관리비 (단가 인상)",
      "effectiveStartDate": "2025-08-01", // 상태가 ACTIVE로 변경되거나, 기존 ACTIVE 항목의 시작일 변경 시 익월 이후 규칙 적용
      "effectiveEndDate": null,
      "status": "ACTIVE" // 또는 INACTIVE
  }
  ```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `FeeItemResponseDto` (수정된 자원 정보)

- Error Responses:

  - `400 Bad Request`: 입력값 유효성 오류, `effectiveStartDate` 규칙 위반.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 항목이 존재하지 않음.
  - `409 Conflict`: 수정하려는 항목명 중복 (다른 유효한 항목과).

------

### 4.5. 관리비 항목 부분 수정 (상태 변경 등)

- **HTTP Method:** `PATCH`

- **URI:** `/fee-items/{feeItemId}`

- **설명:** 지정된 ID의 관리비 항목 정보 중 일부를 수정한다. 특히 '상태'를 'INACTIVE'에서 'ACTIVE'로 변경(재사용) 시, '적용 시작일'은 익월 이후로 설정되거나 자동 조정되어야 한다 (R-FEE-SETUP-007 규칙).

- **요청 권한:** 총괄관리자, 관리소장

- **Path Parameters:**
 | 파라미터명   | 타입         | 설명              |
 | :----------- | :----------- | :---------------- |
 | `feeItemId`  | UUID / Long  | 수정할 항목의 ID  |

- Request Body:

  ```
  FeeItemPartialUpdateRequestDto
  ```

   (수정할 필드만 포함)

  JSON

  ```
  // 예시 1: 상태만 변경 (INACTIVE -> ACTIVE)
  {
      "status": "ACTIVE",
      "effectiveStartDate": "2025-08-01" // 상태 변경에 따른 적용 시작일 명시 또는 서버에서 조정
  }
  
  // 예시 2: 단가만 변경
  {
      "unitPrice": 1700.00
  }
  ```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `FeeItemResponseDto` (수정된 자원 정보)

- Error Responses:

  - `400 Bad Request`: 입력값 유효성 오류. 'INACTIVE' -> 'ACTIVE' 변경 시 `effectiveStartDate` 규칙 위반.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `4.4 Not Found`: 해당 ID의 항목이 존재하지 않음.

------

### 4.6. 관리비 항목 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/fee-items/{feeItemId}`
- **설명:** 지정된 ID의 관리비 항목을 삭제한다. 단, 해당 항목이 과거 또는 현재 청구월의 관리비 산정에 이미 사용된 경우, 물리적 삭제 대신 '상태'를 'INACTIVE' 또는 'DELETED'로 변경하여 논리적 삭제 처리한다 (R-FEE-SETUP-004 규칙).
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** 
| 파라미터명   | 타입         | 설명              |
| :----------- | :----------- | :---------------- |
| `feeItemId`  | UUID / Long  | 삭제할 항목의 ID  |
- Success Response:
  - **Code:** `204 No Content` (물리적 삭제 또는 논리적 삭제 성공 시 모두 가능)
  - 또는 `200 OK`와 함께 상태가 변경된 항목 정보 반환.
- Error Responses:
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 항목이 존재하지 않음.
  - `409 Conflict`: (정책에 따라) 삭제할 수 없는 조건일 때 (예: 활성 계약에 연결된 경우 - 단, 여기선 관리비 산정 사용 여부가 주 조건).

------

## 5. 데이터 모델 (DTOs)

### 5.1. `FeeItemResponseDto`

JSON

```
{
    "feeItemId": "string (UUID or Long)",
    "itemName": "string",
    "impositionMethod": "string (Enum: FIXED_AMOUNT, PER_AREA, PER_USAGE, COMMON_TOTAL_PER_AREA, COMMON_TOTAL_PER_SHARE)",
    "unitPrice": "number (BigDecimal/Double)",
    "unit": "string",
    "vatApplicable": "boolean",
    "description": "string (nullable)",
    "effectiveStartDate": "string (YYYY-MM-DD)",
    "effectiveEndDate": "string (YYYY-MM-DD, nullable)",
    "status": "string (Enum: ACTIVE, INACTIVE)",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
```

### 5.2. `FeeItemCreateRequestDto` / `FeeItemUpdateRequestDto`

(위 4.1 및 4.4 요청 본문 예시 참조)

### 5.3. `PagedFeeItemResponseDto`

JSON

```
{
    "data": [
        // array of FeeItemResponseDto
    ],
    "pagination": {
        "totalElements": "long",
        "totalPages": "integer",
        "currentPage": "integer", // 0-indexed
        "pageSize": "integer"
    }
}
```

