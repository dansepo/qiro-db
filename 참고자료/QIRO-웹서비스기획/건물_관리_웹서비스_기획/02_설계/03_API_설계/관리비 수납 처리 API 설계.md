
# 💳 QIRO 관리비 수납 처리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 관리비 수납 처리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-PAY-PROC-001 - QIRO - 관리비 수납 처리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 관리비 및 임대료 수납 내역 등록, 조회, (제한적) 수정 및 관련 고지서/미납 상태 업데이트를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 업로드 시 `multipart/form-data`)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 특정 고지서에 대한 수납 내역 등록

- **HTTP Method:** `POST`
- **URI:** `/invoices/{invoiceId}/payments`
- **설명:** 특정 고지서(또는 청구 건)에 대해 수신된 납부 내역을 시스템에 신규 등록한다. 이 작업은 해당 고지서의 납부 상태 및 미납액을 자동으로 업데이트한다.
- **요청 권한:** 경리담당자, 관리소장
- **Path Parameters:**

  | 파라미터명    | 타입         | 설명                         |
  | :------------ | :----------- | :--------------------------- |
  | `invoiceId`   | UUID / Long  | 수납을 기록할 대상 고지서의 ID |

- **Request Body:** `PaymentRecordCreateRequestDto`
  ```json
  {
      "paymentDate": "2025-07-10", // 실제 납부일
      "paidAmount": 250000, // 납부 금액
      "paymentMethod": "BANK_TRANSFER", // CASH, CARD, BANK_TRANSFER 등 Enum 값
      "payerName": "홍길동", // 선택 사항: 실제 납부자명 (임차인과 다를 경우)
      "transactionDetails": "QIRO은행 123-456 이체 확인", // 선택 사항: 은행, 계좌번호 일부, 거래번호 등
      "receivingBankAccountId": "acc-uuid-default", // 선택 사항: 입금된 수납 계좌 ID
      "remarks": "7월분 관리비 완납" // 선택 사항
  }
  ```

- **Request Body 필드 설명:** (주요 필드)

  | 필드명                     | 타입   | 필수 | 설명                               |
  | :------------------------- | :----- | :--- | :--------------------------------- |
  | paymentDate              | String | Y    | 실제 납부일 (YYYY-MM-DD)           |
  | paidAmount               | Number | Y    | 납부 금액                          |
  | paymentMethod            | String | Y    | 납부 수단 (Enum)                   |
  | payerName                | String | N    | 실제 납부자명                      |
  | transactionDetails       | String | N    | 거래 관련 상세 정보 (메모)         |
  | receivingBankAccountId   | String | N    | 입금된 QIRO측 수납 계좌 ID         |
  | remarks                  | String | N    | 수납 관련 비고                     |

- **Success Response:**

  - **Code:** `201 Created`

  - **Headers:** `Location: /v1/payments/{paymentRecordId}` (생성된 수납 기록 ID)

  - Body:

```
    PaymentRecordResponseDto
```

     (생성된 수납 기록 정보)
    
    - 이 응답에는 업데이트된 고지서의 요약 정보(예: 새 미납액, 납부 상태)를 함께 포함할 수 있다.

- **Error Responses:** `400 Bad Request` (필수값 누락, 금액 오류, 이미 완납된 고지서 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (invoiceId).

------

### 4.2. 특정 고지서의 수납 이력 조회

- **HTTP Method:** `GET`
- **URI:** `/invoices/{invoiceId}/payments`
- **설명:** 지정된 고지서에 연결된 모든 수납 이력 목록을 조회한다. (분할 납부 등으로 여러 건이 있을 수 있음)
- **요청 권한:** 경리담당자, 관리소장
- **Path Parameters:** `invoiceId`
- **Query Parameters:** (필요시 `sortBy`, `sortDirection` 등 추가)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `List<PaymentRecordResponseDto>`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

------

### 4.3. 전체 수납 이력 목록 조회 (필터링 및 검색)

- **HTTP Method:** `GET`

- **URI:** `/payments`

- **설명:** 시스템에 기록된 전체 수납 이력 목록을 다양한 조건으로 필터링, 검색, 정렬하여 조회한다. (은행 거래내역 대사 등에 활용)

- **요청 권한:** 총괄관리자, 경리담당자

- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                     | 예시                        |
  | :------------------- | :------ | :--- | :--------------------------------------- | :-------------------------- |
  | buildingId         | String  | N    | 특정 건물 필터링                         | building-uuid             |
  | unitId             | String  | N    | 특정 호실 필터링                         | unit-uuid                 |
  | tenantNameKeyword  | String  | N    | 임차인명 키워드 검색                     | 홍길동                    |
  | paymentDateFrom    | String  | N    | 납부일 검색 시작일 (YYYY-MM-DD)          | 2025-07-01                |
  | paymentDateTo      | String  | N    | 납부일 검색 종료일 (YYYY-MM-DD)          | 2025-07-31                |
  | paymentMethod      | String  | N    | 납부 수단 필터링                         | BANK_TRANSFER             |
  | receivingBankAccountId| String | N   | 특정 수납 계좌로 입금된 건 필터링        | acc-uuid-default          |
  | minPaidAmount      | Number  | N    | 최소 납부 금액                           | 100000                    |
  | page, size, sortBy (paymentDate, paidAmount), sortDirection (공통 파라미터) |         | N    |                                          | paymentDate DESC          |

- **Success Response:** `200 OK`, `PagedResponse<PaymentRecordResponseDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

------

### 4.4. 특정 수납 기록 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/payments/{paymentRecordId}`
- **설명:** 지정된 ID의 수납 기록 상세 정보를 조회한다.
- **요청 권한:** 경리담당자, 관리소장
- **Path Parameters:** `paymentRecordId` (수납 기록 고유 ID)
- **Success Response:** `200 OK`, `PaymentRecordResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

------

### 4.5. 수납 기록 수정 (매우 제한적)

- **HTTP Method:** `PUT` (또는 `PATCH` 권장)

- **URI:** `/payments/{paymentRecordId}`

- **설명:** 이미 등록된 수납 기록의 일부 정보(예: 메모, 거래 상세 정보)를 수정한다. 납부 금액, 납부일 등 중요 정보 수정은 원칙적으로 제한되며, 필요시 기존 기록 취소 후 재등록 절차를 따르거나 최상위 관리자 권한으로 엄격한 통제 하에 이루어져야 한다. (수정 시 관련 고지서 미납 상태 재계산 필요)

- **요청 권한:** 경리담당자(제한된 필드), 총괄관리자(더 많은 필드 및 위험 감수)

- **Path Parameters:** `paymentRecordId`

- Request Body:

  ```
  PaymentRecordUpdateRequestDto
  ```

   (수정 가능한 필드만 포함)

  JSON

  ```
  {
      "remarks": "은행 입금자명과 임차인명 불일치 건 확인 완료",
      "transactionDetails": "QIRO은행 123-456 (입금자: 박춘향)"
      // "paidAmount": 155000, // 금액 수정은 매우 신중해야 하며, 권한 통제 및 재계산 로직 필수
  }
  ```

- **Success Response:** `200 OK`, `PaymentRecordResponseDto`

- **Error Responses:** `400 Bad Request` (수정 불가 항목 시도, 유효성 오류), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.6. 수납 기록 삭제/취소 (매우 제한적)

- **HTTP Method:** `DELETE`
- **URI:** `/payments/{paymentRecordId}`
- **설명:** 잘못 입력된 수납 기록을 취소(논리적 삭제 또는 상태 변경)한다. 이 작업은 관련 고지서의 납부 상태 및 미납액을 반드시 원복(재계산)해야 한다. 매우 제한적인 상황에서 최상위 관리자 또는 특정 권한을 가진 사용자만 수행 가능하다.
- **요청 권한:** 총괄관리자 (또는 엄격한 승인 절차 후)
- **Path Parameters:** `paymentRecordId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (이미 마감된 청구월의 수납 기록 등).

------

### 4.7. (선택) 은행 거래내역 파일 업로드를 통한 수납 일괄 등록/대사

- **HTTP Method:** `POST`

- **URI:** `/payments/batch-upload/bank-statement`

- **설명:** 은행에서 다운로드한 거래내역 파일(Excel/CSV)을 업로드하여 다수의 수납 건을 시스템에 일괄 등록하거나, 기존 미납 고지 내역과 자동으로 대사(matching)하는 작업을 시작한다. 비동기 처리될 수 있다.

- **요청 권한:** 경리담당자

- Request:

  ```
  multipart/form-data
  ```

  - `billingMonthId` (String, N): (선택) 특정 청구월 범위로 대사 대상 한정
  - `bankAccountId` (String, Y): 입금된 QIRO측 수납 계좌 ID (필수)
  - `file` (File, Y): 은행 거래내역 파일
  - `uploadOptions` (String/JSON, N): (예: `{"dateFormatInFile": "YYYY.MM.DD", "matchingSensitivity": "HIGH"}`)

- Success Response:

  - **Code:** `202 Accepted` (비동기 처리 시작 시)

  - Body:

    JSON

    ```
    {
        "jobId": "pay-upload-job-uuid-001",
        "message": "은행 거래내역 파일 업로드가 접수되었습니다. 데이터 처리 및 대사 작업 완료 후 결과를 확인해주세요.",
        "statusCheckUrl": "/v1/batch-jobs/pay-upload-job-uuid-001"
    }
    ```

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

- *(참고: 이후 이 `jobId`를 통해 진행 상태를 확인하고, 대사 결과를 검토 및 확정하는 별도의 UI와 API가 필요함)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `PaymentRecordResponseDto`

JSON

```
{
    "paymentRecordId": "string (UUID or Long)",
    "invoiceId": "string (UUID or Long)", // 관련 고지서 ID
    "unitNumber": "string", // 편의 정보: 호실
    "tenantName": "string", // 편의 정보: 임차인명
    "billingYearMonth": "string (YYYY-MM)", // 편의 정보: 청구월
    "paymentDate": "string (YYYY-MM-DD)",
    "paidAmount": "number",
    "paymentMethod": "string (Enum: BANK_TRANSFER, CASH, CARD, ETC)",
    "paymentMethodName": "string", // Enum에 대한 한글명
    "payerName": "string (nullable)",
    "transactionDetails": "string (nullable)",
    "receivingBankAccountId": "string (nullable)",
    "receivingBankAccountInfo": "string (nullable)", // 예: "QIRO은행 123-..."
    "remarks": "string (nullable)",
    "processedBy": "string (User ID/Name)", // 처리자
    "processedAt": "string (ISO DateTime)", // 처리일시
    "isCancelled": "boolean" // 취소 여부
}
```

### 5.2. `PaymentRecordCreateRequestDto`

(4.1 요청 본문 필드 참조)

### 5.3. `PaymentRecordUpdateRequestDto` (제한적 필드)

JSON

```
{
    "paymentDate": "string (YYYY-MM-DD, optional, 변경 시 재계산 유발 가능성)",
    "paidAmount": "number (optional, 변경 시 재계산 유발 가능성)",
    "paymentMethod": "string (Enum, optional)",
    "payerName": "string (optional)",
    "transactionDetails": "string (optional)",
    "receivingBankAccountId": "string (optional)",
    "remarks": "string (optional)"
}
```

*(PagedResponse<Dto>는 목록 조회 시 공통적으로 사용)*

------

```
이 API 설계안은 QIRO 서비스의 "관리비 수납 처리" 기능을 위한 핵심적인 부분들을 다루고 있습니다. 특히 수납 기록의 생성, 조회 및 (제한적인) 수정/삭제, 그리고 대량 처리를 위한 파일 업로드 기능을 포함합니다. 수납 처리 결과가 미납 상태 및 연체료 계산에 미치는 영향은 백엔드 로직에서 긴밀하게 연동되어야 합니다. 
```