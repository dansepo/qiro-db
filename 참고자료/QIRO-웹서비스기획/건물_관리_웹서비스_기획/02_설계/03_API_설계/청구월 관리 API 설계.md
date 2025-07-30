# 🗓️ QIRO 청구월 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 청구월 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **작성일:** 2025년 06월 03일
- **최종 수정일:** 2025년 06월 03일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 청구월(Billing Month) 생성, 조회, 초기 데이터 설정("선택적 데이터 가져오기" 포함), 상태 변경 등 청구월의 전체 생명주기를 관리하기 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 신규 청구월 생성

- **HTTP Method:** `POST`
- **URI:** `/billing-months`
- **설명:** 새로운 청구월을 시스템에 기본값으로 생성한다. 생성 시 "관리비 항목 설정"의 마스터 항목이 적용되며, 기타 설정값 및 기초 데이터(전월 검침값, 미납액 등)는 시스템 기본값(예: 마스터 기본값, 0, '미정산')으로 초기화된다. 생성된 청구월의 초기 상태는 '준비중(PREPARING)'이다. 상세 초기값 설정은 별도의 "초기값 데이터 가져오기/설정" API를 통해 수행한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Request Body:** `BillingMonthCreateRequestDto`

```json
  {
      "year": 2025,
      "month": 7 // 1-12
  }
```

- **Request Body 필드 설명:**

  | 필드명  | 타입    | 필수 | 설명             | 비고     |
  | :------ | :------ | :--- | :--------------- | :------- |
  | year  | Integer | Y    | 대상 연도 (YYYY) |          |
  | month | Integer | Y    | 대상 월 (1~12)   |          |
  
- **Success Response:**

  - **Code:** `201 Created`

  - **Headers:** `Location: /v1/billing-months/{billingMonthId}`

  - Body:

```
    BillingMonthResponseDto
```

     (생성된 청구월 기본 정보)
    
    JSON
    
    ```
    {
        "billingMonthId": "bm-uuid-string-001",
        "year": 2025,
        "month": 7,
        "status": "PREPARING", // PREPARING, IN_PROGRESS, COMPLETED
        "description": null,
        "closedDate": null,
        "createdAt": "2025-06-03T14:00:00.000Z",
        "lastModifiedAt": "2025-06-03T14:00:00.000Z"
    }
    ```

- **Error Responses:**

  - `400 Bad Request`: 입력값 유효성 오류 (연/월 형식 오류, 필수값 누락). 이미 해당 연월의 청구월이 존재할 경우.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.

------

### 4.2. 청구월 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/billing-months`

- **설명:** 등록된 청구월 목록을 조회한다. 필터링, 정렬, 페이지네이션 기능을 지원한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명      | 타입    | 필수 | 설명                        | 예시                      |
  | :-------------- | :------ | :--- | :-------------------------- | :------------------------ |
  | year          | Integer | N    | 특정 연도로 필터링          | 2025                    |
  | status        | String  | N    | 상태로 필터링 (PREPARING, IN_PROGRESS, COMPLETED) | PREPARING               |
  | page          | Integer | N    | 페이지 번호 (0부터 시작)      | 0 (기본값)              |
  | size          | Integer | N    | 페이지 당 항목 수             | 20 (기본값, 최대 100)   |
  | sortBy        | String  | N    | 정렬 기준 필드 (예: yearMonth, status) | yearMonth (기본값)      |
  | sortDirection | String  | N    | 정렬 방향 (ASC, DESC)     | DESC (기본값)           |

- **Success Response:**

  - **Code:** `200 OK`

  - Body:

    ```
    PagedBillingMonthResponseDto
    ```

    JSON

    ```
    {
        "data": [
            // array of BillingMonthResponseDto
            {
                "billingMonthId": "bm-uuid-string-001",
                "year": 2025,
                "month": 7,
                "status": "PREPARING",
                // ...
            }
        ],
        "pagination": {
            "totalElements": 15,
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

### 4.3. 특정 청구월 상세 조회 (초기 설정값 포함)

- **HTTP Method:** `GET`

- **URI:** `/billing-months/{billingMonthId}`

- **설명:** 지정된 ID의 청구월 상세 정보를 조회한다. 이 정보에는 해당 청구월에 설정된 관리비 항목별 설정값, 세대별 전월 검침값, 세대별 전월 미납액 등의 초기 설정 데이터가 포함된다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | billingMonthId  | UUID / Long  | 조회할 청구월의 ID     |

- **Success Response:**

  - **Code:** `200 OK`

  - Body:

    ```
    BillingMonthDetailResponseDto
    ```

    JSON

    ```
    {
        "billingMonthId": "bm-uuid-string-001",
        "year": 2025,
        "month": 7,
        "status": "PREPARING",
        "description": "2025년 7월분 관리비 (초기 설정 진행 중)",
        "closedDate": null,
        "previousMonthStatus": "COMPLETED", // 직전 청구월의 상태 정보 (예시)
        "feeItemSettings": [ // BillingMonthFeeItemSettingDto 목록
            {
                "feeItemId": "fi-uuid-001",
                "itemName": "일반관리비",
                "unitPrice": 1500,
                "dataSource": "PREVIOUS_COMPLETED_SETTING",
                // ...
            }
        ],
        "previousMeterReadings": [ // BillingMonthUnitPreviousMeterReadingDto 목록
            {
                "unitId": "unit-uuid-101",
                "utilityTypeCode": "ELEC_I",
                "meterReading": 12345.0,
                "dataSource": "PREVIOUS_COMPLETED_READING",
                // ...
            }
        ],
        "previousUnpaidAmounts": [ // BillingMonthUnitUnpaidAmountDto 목록
            {
                "unitId": "unit-uuid-101",
                "unpaidAmount": 0,
                "dataSource": "PREVIOUS_COMPLETED_UNPAID",
                // ...
            }
        ],
        "createdAt": "2025-06-03T14:00:00.000Z",
        "lastModifiedAt": "2025-06-03T14:05:00.000Z"
    }
    ```

- **Error Responses:**

  - `401 Unauthorized`: 인증 실패.
  - `404 Not Found`: 해당 ID의 청구월이 존재하지 않음.

------

### 4.4. 청구월 초기값 데이터 가져오기 및 설정 (선택적 데이터 가져오기)

- **HTTP Method:** `PUT`

- **URI:** `/billing-months/{billingMonthId}/initial-setup-data`

- **설명:** 지정된 '준비중' 상태의 청구월에 대해, "선택적 데이터 가져오기" 로직을 실행하여 관리비 항목별 설정값, 세대별 전월 검침값, 세대별 전월 미납액 등을 직전월 또는 마스터 기본값에서 선택적으로 가져와 최종 설정한다. 요청 본문에는 각 데이터 유형 및 항목별로 어떤 소스에서 데이터를 가져올지(또는 직접 입력할 값)에 대한 사용자 선택 정보가 포함된다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | billingMonthId  | UUID / Long  | 설정할 청구월의 ID     |

- **Request Body:** `BillingMonthInitialSetupRequestDto`

  JSON

  ```
  {
      "feeItemSettings": [
          {
              "feeItemId": "fi-uuid-001",
              "dataSource": "PREVIOUS_MONTH", // MASTER_DEFAULT, MANUAL_INPUT
              "manualUnitPrice": null, // dataSource가 MANUAL_INPUT일 경우 값 지정
              "manualRate": null,
              "manualVatApplicable": null
          }
          // ... 모든 관리비 항목에 대한 설정
      ],
      "openingMeterReadings": [
          {
              "unitId": "unit-uuid-101",
              "utilityTypeCode": "ELEC_I",
              "dataSource": "PREVIOUS_MONTH", // MANUAL_INPUT
              "manualMeterReading": null // dataSource가 MANUAL_INPUT일 경우 값 지정
          }
          // ... 검침 대상 모든 세대/항목에 대한 설정
      ],
      "previousUnpaidAmounts": [ // 직전월이 '완료'된 경우에만 의미 있는 값을 가져옴
          {
              "unitId": "unit-uuid-101",
              "dataSource": "PREVIOUS_MONTH", // MANUAL_INPUT (권장하지 않음)
              "manualUnpaidAmount": null
          }
          // ... 모든 세대에 대한 설정
      ]
  }
  ```

- **Request Body 필드 설명 (간략):**

  - `feeItemSettings[].dataSource`: 각 항목 설정값의 출처 (`PREVIOUS_MONTH`, `MASTER_DEFAULT`, `MANUAL_INPUT`)
  - `feeItemSettings[].manualXxx`: `dataSource`가 `MANUAL_INPUT`일 때 사용자가 직접 입력한 값.
  - (나머지 `openingMeterReadings`, `previousUnpaidAmounts`도 유사한 구조)

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `BillingMonthDetailResponseDto` (업데이트된 청구월 상세 정보, 4.3의 응답과 동일)

- **Error Responses:**

  - `400 Bad Request`: 입력값 유효성 오류, 청구월 상태가 '준비중'이 아님, 직전월 미완료 상태에서 미납액 연동 시도 등.
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 청구월이 존재하지 않음.

------

### 4.5. 청구월 상태 변경

- **HTTP Method:** `PATCH`

- **URI:** `/billing-months/{billingMonthId}/status`

- **설명:** 지정된 청구월의 상태를 변경한다. (예: `준비중` -> `진행중`, `진행중` -> `완료`). 각 상태 변경은 특정 조건(예: 필수 데이터 입력 완료, 이전 달 마감 완료, 현재 '진행중'인 다른 달 없음 등)을 만족해야 한다.

- **요청 권한:** 총괄관리자, 관리소장 (상태 변경 종류에 따라 권한 차등 가능)

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | billingMonthId  | UUID / Long  | 상태 변경할 청구월 ID  |

- **Request Body:** `BillingMonthStatusUpdateRequestDto`

  JSON

  ```
  {
      "newStatus": "IN_PROGRESS", // PREPARING, IN_PROGRESS, COMPLETED
      "forceTransition": false // 선택 사항: 경고를 무시하고 강제 진행 여부 (매우 제한적 사용)
  }
  ```

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `BillingMonthResponseDto` (상태가 변경된 청구월 정보)

- **Error Responses:**

  - `400 Bad Request`: 유효하지 않은 `newStatus` 값, 상태 변경 조건 미충족 (예: 다른 '진행중' 청구월 존재, 필수 데이터 미입력 등).
  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 청구월이 존재하지 않음.
  - `409 Conflict`: 현재 상태에서 요청된 상태로 변경할 수 없음 (잘못된 흐름).

------

### 4.6. 청구월 삭제 (제한적)

- **HTTP Method:** `DELETE`

- **URI:** `/billing-months/{billingMonthId}`

- **설명:** 지정된 청구월을 삭제한다. 일반적으로 '준비중' 상태이고, 아직 어떠한 중요 데이터(산정, 고지, 수납 내역 등)도 연결되지 않은 경우에만 물리적 삭제가 가능하다. 그 외에는 논리적 삭제(비활성화) 또는 삭제 불가 처리.

- **요청 권한:** 총괄관리자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                |
  | :---------------- | :----------- | :------------------ |
  | billingMonthId  | UUID / Long  | 삭제할 청구월의 ID  |

- **Success Response:**

  - **Code:** `204 No Content` (성공적으로 삭제 시)

- **Error Responses:**

  - `401 Unauthorized`: 인증 실패.
  - `403 Forbidden`: 권한 없음.
  - `404 Not Found`: 해당 ID의 청구월이 존재하지 않음.
  - `409 Conflict`: 삭제할 수 없는 조건일 때 (예: 이미 '진행중'이거나 '완료'된 청구월).

## 5. 데이터 모델 (DTOs) - 주요 항목 요약

### 5.1. `BillingMonthResponseDto`

(4.1의 성공 응답 본문 참조)

### 5.2. `BillingMonthDetailResponseDto`

(4.3의 성공 응답 본문 참조 - `feeItemSettings`, `previousMeterReadings`, `previousUnpaidAmounts` DTO 목록 포함)

- `BillingMonthFeeItemSettingDto` (예시):

  JSON

  ```
  {
      "feeItemId": "string",
      "itemName": "string",
      "unitPrice": "number",
      "rate": "number (nullable)",
      "vatApplicable": "boolean",
      "dataSource": "string (Enum)", // 예: PREVIOUS_COMPLETED_SETTING, MASTER_DEFAULT, MANUAL
      "isConfirmedByPrevious": "boolean"
  }
  ```

- `BillingMonthUnitPreviousMeterReadingDto` (예시):

  JSON

  ```
  {
      "unitId": "string",
      "utilityTypeCode": "string",
      "meterReading": "number",
      "dataSource": "string (Enum)" // 예: PREVIOUS_COMPLETED_READING, MANUAL
  }
  ```

- `BillingMonthUnitUnpaidAmountDto` (예시):

  JSON

  ```
  {
      "unitId": "string",
      "unpaidAmount": "number",
      "dataSource": "string (Enum)" // 예: PREVIOUS_COMPLETED_UNPAID, UNSETTLED_INITIAL
  }
  ```

### 5.3. `BillingMonthCreateRequestDto`

(4.1의 요청 본문 참조)

### 5.4. `BillingMonthInitialSetupRequestDto`

(4.4의 요청 본문 참조 - 각 항목별 `dataSource` 및 `manualXxx` 값들을 포함하는 복합 객체)

### 5.5. `BillingMonthStatusUpdateRequestDto`

(4.5의 요청 본문 참조)

### 5.6. `PagedBillingMonthResponseDto`

(4.2의 성공 응답 본문 참조)

