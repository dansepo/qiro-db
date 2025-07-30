
# 📊 QIRO 회계 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 회계 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-ACCMGMT-001 - QIRO - 회계 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 회계 관리 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API는 계정과목 관리, 전표 관리, 장부 조회, 재무제표 생성, 회계 마감 등의 기능을 포함한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)
  ```json
  {
      "timestamp": "2025-06-04T10:00:00.123Z",
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

### 4.1. 계정과목 (Chart of Accounts) 관리 API

#### 4.1.1. 신규 계정과목 생성

- **HTTP Method:** `POST`

- **URI:** `/chart-of-accounts`

- **설명:** 새로운 계정과목을 시스템에 등록한다.

- **요청 권한:** 총괄관리자, 경리담당자 (설정 권한 보유 시)

- **Request Body:** `ChartOfAccountCreateRequestDto`

  JSON

  ```
  {
      "accountCode": "10101",
      "accountName": "보통예금",
      "accountType": "ASSET", // ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE
      "parentAccountId": null, // 상위 계정 ID (계층 구조 시)
      "description": "은행 보통예금 계정",
      "isActive": true
  }
  ```

- **Request Body 필드 설명:**

  | 필드명             | 타입    | 필수 | 설명                                  | 비고                                     |
  | :----------------- | :------ | :--- | :------------------------------------ | :--------------------------------------- |
  | accountCode      | String  | Y    | 계정 코드 (사용자 정의 또는 표준 코드)    | 시스템 내 고유해야 함                    |
  | accountName      | String  | Y    | 계정명                                |                                          |
  | accountType      | String  | Y    | 계정 유형 (Enum 값)                   | ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE |
  | parentAccountId  | String  | N    | 상위 계정 ID (계층 구조 표현)         | UUID/Long 형식, 유효한 계정 ID여야 함     |
  | description      | String  | N    | 계정 설명                             | 최대 200자                               |
  | isActive         | Boolean | N    | 활성 상태 여부                        | 기본값 true                             |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/chart-of-accounts/{accountId}`
  - **Body:** `ChartOfAccountResponseDto` (생성된 계정과목 정보)

- **Error Responses:** `400 Bad Request` (입력값 유효성 오류, 코드/명칭 중복), `401 Unauthorized`, `403 Forbidden`.

#### 4.1.2. 계정과목 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/chart-of-accounts`

- **설명:** 등록된 계정과목 목록을 조회한다. (계층 구조 또는 플랫 리스트, 필터링 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명      | 타입    | 필수 | 설명                                | 예시         |
  | :-------------- | :------ | :--- | :---------------------------------- | :----------- |
  | accountType   | String  | N    | 계정 유형으로 필터링                | ASSET      |
  | accountName   | String  | N    | 계정명 검색 (부분 일치)             | 예금       |
  | isActive      | Boolean | N    | 활성 상태로 필터링                  | true       |
  | hierarchical  | Boolean | N    | 계층 구조로 반환 여부 (기본값 false - 플랫 리스트) | true       |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                     |              |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<ChartOfAccountResponseDto>` (플랫 리스트 시) 또는 `List<HierarchicalChartOfAccountDto>` (계층 구조 시)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 계정과목 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/chart-of-accounts/{accountId}`
- **설명:** 지정된 ID의 계정과목 상세 정보를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등
- **Path Parameters:** `accountId` (계정과목 고유 ID)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `ChartOfAccountResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 계정과목 정보 수정

- **HTTP Method:** `PUT` (또는 `PATCH`로 부분 수정 지원)
- **URI:** `/chart-of-accounts/{accountId}`
- **설명:** 지정된 ID의 계정과목 정보를 수정한다.
- **요청 권한:** 총괄관리자, 경리담당자 (설정 권한 보유 시)
- **Path Parameters:** `accountId`
- **Request Body:** `ChartOfAccountUpdateRequestDto` (4.1.1의 Create DTO와 유사하나, `accountCode`는 변경 불가 가능성)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `ChartOfAccountResponseDto` (수정된 계정과목 정보)
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.5. 계정과목 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/chart-of-accounts/{accountId}`
- **설명:** 지정된 ID의 계정과목을 삭제한다. (이미 전표에 사용된 경우 논리적 삭제 또는 비활성화 처리)
- **요청 권한:** 총괄관리자, 경리담당자 (설정 권한 보유 시)
- **Path Parameters:** `accountId`
- **Success Response:** `204 No Content` 또는 `200 OK` (논리적 삭제 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 전표 (Journal Entry) 관리 API

#### 4.2.1. 신규 전표 생성

- **HTTP Method:** `POST`

- **URI:** `/journal-entries`

- **설명:** 새로운 전표(분개 라인 포함)를 시스템에 등록한다. (수동 전표 입력용. 자동 전표는 시스템 내부적으로 생성)

- **요청 권한:** 경리담당자, 관리소장(제한적)

- Request Body:

  ```
  JournalEntryCreateRequestDto
  ```

  JSON

  ```
  {
      "entryDate": "2025-06-03",
      "description": "사무용품 구입비 (현금 지급)",
      "entryType": "MANUAL", // MANUAL, AUTO_FEE, AUTO_RENT, CLOSING 등
      "lines": [
          {
              "accountId": "acc-uuid-supplies", // 소모품비 계정 ID
              "entrySide": "DEBIT",
              "amount": 50000,
              "lineDescription": "A4용지 및 필기구 구입",
              "relatedPartyId": "vendor-uuid-office-store" // 선택적 거래처 ID
          },
          {
              "accountId": "acc-uuid-cash", // 현금 계정 ID
              "entrySide": "CREDIT",
              "amount": 50000,
              "lineDescription": "A4용지 및 필기구 구입"
          }
      ],
      "attachments": [ // 선택 사항: 증빙 파일 정보
          {"fileName": "receipt_20250603.pdf", "fileKey": "s3-key-receipt"}
      ]
  }
  ```

- Success Response:

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/journal-entries/{entryId}`
  - **Body:** `JournalEntryResponseDto` (생성된 전표 정보)

- **Error Responses:** `400 Bad Request` (차/대변 불일치, 필수값 누락 등), `401 Unauthorized`, `403 Forbidden`.

#### 4.2.2. 전표 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/journal-entries`

- **설명:** 전표 목록을 조회한다. (기간, 상태, 유형 등 필터링 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명      | 타입    | 필수 | 설명                                  | 예시                             |
  | :-------------- | :------ | :--- | :------------------------------------ | :------------------------------- |
  | startDate     | String  | N    | 조회 시작일 (YYYY-MM-DD)              | 2025-06-01                     |
  | endDate       | String  | N    | 조회 종료일 (YYYY-MM-DD)              | 2025-06-30                     |
  | status        | String  | N    | 전표 상태 (DRAFT, CONFIRMED, CANCELLED) | CONFIRMED                      |
  | entryType     | String  | N    | 전표 유형                             | MANUAL                         |
  | accountId     | String  | N    | 특정 계정과목이 포함된 전표 필터링    | acc-uuid-cash                  |
  | descriptionKeyword | String | N    | 적요 내용 키워드 검색                 | 관리비                         |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                       | entryDate DESC                 |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<JournalEntrySummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.2.3. 특정 전표 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/journal-entries/{entryId}`
- **설명:** 지정된 ID의 전표 상세 정보(분개 라인 포함)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등
- **Path Parameters:** `entryId` (전표 고유 ID)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `JournalEntryResponseDto` (분개 라인 상세 포함)
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.2.4. 전표 정보 수정 (제한적)

- **HTTP Method:** `PUT` (또는 `PATCH` - 적요, 첨부파일 등 일부 필드만 수정)
- **URI:** `/journal-entries/{entryId}`
- **설명:** 지정된 ID의 전표 정보를 수정한다. (주로 'DRAFT' 상태의 전표 또는 'CONFIRMED' 상태 전표의 비재무적 정보 수정)
- **요청 권한:** 경리담당자 (수정 권한 보유 시)
- **Path Parameters:** `entryId`
- **Request Body:** `JournalEntryUpdateRequestDto` (수정 가능한 필드만 포함)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `JournalEntryResponseDto` (수정된 전표 정보)
- **Error Responses:** `400 Bad Request` (수정 불가 조건 위배), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.2.5. 전표 상태 변경 (예: 확정, 취소)

- **HTTP Method:** `PATCH`

- **URI:** `/journal-entries/{entryId}/status`

- **설명:** 지정된 전표의 상태를 변경한다 (예: `DRAFT` -> `CONFIRMED`).

- **요청 권한:** 경리담당자 (확정/취소 권한 보유 시)

- **Path Parameters:** `entryId`

- Request Body:

  JSON

  ```
  {
      "newStatus": "CONFIRMED" // 또는 CANCELLED
  }
  ```

- **Success Response:** `200 OK`, `JournalEntryResponseDto`

- **Error Responses:** `400 Bad Request` (잘못된 상태 전환), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.

#### 4.2.6. 전표 삭제 (제한적)

- **HTTP Method:** `DELETE`
- **URI:** `/journal-entries/{entryId}`
- **설명:** 지정된 전표를 삭제한다. (주로 'DRAFT' 상태 또는 특정 조건 하에서만 가능. 'CONFIRMED' 전표는 반제 전표로 처리 권장)
- **요청 권한:** 경리담당자 (삭제 권한 보유 시)
- **Path Parameters:** `entryId`
- **Success Response:** `204 No Content`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.3. 장부 (Ledger) 조회 API (주로 GET)

- 분개장 조회:
  - **HTTP Method:** `GET`
  - **URI:** `/ledgers/journal`
  - **설명:** 기간별, 조건별 분개장(확정된 전표 라인 목록) 조회.
  - **Query Parameters:** `startDate`, `endDate`, (기타 필터 조건).
  - **Success Response:** `200 OK`, `PagedResponse<JournalEntryLineDto>`
- 총계정원장 조회:
  - **HTTP Method:** `GET`
  - **URI:** `/ledgers/general/{accountId}`
  - **설명:** 특정 계정과목의 기간별 총계정원장 조회.
  - **Path Parameters:** `accountId`
  - **Query Parameters:** `startDate`, `endDate`.
  - **Success Response:** `200 OK`, `List<GeneralLedgerEntryDto>` (일자, 적요, 차변, 대변, 잔액 등)

------

### 4.4. 재무제표 (Financial Statement) 생성/조회 API (주로 GET)

- 재무상태표 조회:
  - **HTTP Method:** `GET`
  - **URI:** `/financial-statements/balance-sheet`
  - **설명:** 특정 기준일의 재무상태표 생성 및 조회.
  - **Query Parameters:** `asOfDate` (기준일), `buildingId` (선택적, 건물별 재무상태표).
  - **Success Response:** `200 OK`, `BalanceSheetDto` (자산, 부채, 자본 항목 및 금액)
- 손익계산서 조회:
  - **HTTP Method:** `GET`
  - **URI:** `/financial-statements/income-statement`
  - **설명:** 특정 기간의 손익계산서 생성 및 조회.
  - **Query Parameters:** `startDate`, `endDate`, `buildingId` (선택적).
  - **Success Response:** `200 OK`, `IncomeStatementDto` (수익, 비용 항목 및 금액, 당기순이익)

------

### 4.5. 회계 마감 (Accounting Closing) API (주로 POST)

- 연차 마감 및 이월 처리:
  - **HTTP Method:** `POST`
  - **URI:** `/accounting/closings/year-end`
  - **설명:** 지정된 회계연도에 대한 연차 마감(수익/비용 계정 마감, 이익잉여금 대체) 및 자산/부채/자본 계정 잔액 차기 이월을 실행한다.
  - **Request Body:** `YearEndClosingRequestDto` (`yearToClose`)
  - **Success Response:** `202 Accepted` (비동기 처리) 또는 `200 OK` (처리 결과 요약)
  - **Error Responses:** `400 Bad Request` (마감 조건 미충족), `401 Unauthorized`, `403 Forbidden`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `ChartOfAccountResponseDto`

JSON

  ```
{
    "accountId": "string (UUID or Long)",
    "accountCode": "string",
    "accountName": "string",
    "accountType": "string (Enum: ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE)",
    "parentAccountId": "string (nullable)",
    "description": "string (nullable)",
    "isActive": "boolean",
    "balance": "number (BigDecimal/Double)", // 현재 또는 특정 시점 잔액
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `JournalEntryResponseDto`

JSON

```
{
    "entryId": "string (UUID or Long)",
    "entryDate": "string (YYYY-MM-DD)",
    "description": "string",
    "status": "string (Enum: DRAFT, CONFIRMED, CANCELLED)",
    "entryType": "string (Enum: MANUAL, AUTO_FEE, AUTO_RENT, CLOSING)",
    "totalDebit": "number (BigDecimal/Double)",
    "totalCredit": "number (BigDecimal/Double)",
    "lines": [ // array of JournalEntryLineDto
        {
            "lineId": "string",
            "accountId": "string",
            "accountCode": "string", // 편의상 추가
            "accountName": "string", // 편의상 추가
            "entrySide": "string (DEBIT or CREDIT)",
            "amount": "number",
            "lineDescription": "string (nullable)",
            "relatedPartyId": "string (nullable)"
        }
    ],
    "attachments": [ // array of AttachmentDto (선택)
        {"fileName": "string", "fileKey": "string", "fileUrl": "string"}
    ],
    "createdAt": "string (ISO DateTime)",
    "createdBy": "string (User ID/Name)",
    "lastModifiedAt": "string (ISO DateTime)",
    "lastModifiedBy": "string (User ID/Name)"
}
```

(Create/Update Request DTO들은 위 Response DTO에서 ID 및 감사 필드 제외, 필요한 필드 추가/조정)

(PagedResponse&lt;Dto>, BalanceSheetDto, IncomeStatementDto 등은 해당 API 명세에 맞게 상세 정의 필요)

------

