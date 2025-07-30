
# 🧾 QIRO 관리비 고지서 발급 API 설계

## 1. 문서 정보
- **문서명:** QIRO 관리비 고지서 발급 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-INV-ISSUE-001 - QIRO - 관리비 고지서 발급 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 관리비 고지서 생성, 미리보기, 발급 처리 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 확정된 관리비 산정 결과를 바탕으로 각 세대별 고지서를 시스템 내에서 생성하고 관리하며, 실제 통지(이메일, SMS 등)를 위한 준비를 완료할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 다운로드 시 `application/pdf` 등)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 특정 청구월 고지서 일괄 생성 (초안 생성)

- **HTTP Method:** `POST`
- **URI:** `/billing-months/{billingMonthId}/invoices/batch-generate`
- **설명:** 지정된 청구월에 대해, 관리비 산정이 확정된 모든 (또는 선택된) 세대의 고지서 데이터를 시스템 내에 초안(또는 `GENERATED_PENDING_REVIEW`) 상태로 일괄 생성한다. 이 단계에서는 실제 발송이 이루어지지 않는다.
- **요청 권한:** 경리담당자, 관리소장
- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                        |
  | :---------------- | :----------- | :-------------------------- |
  | `billingMonthId`  | UUID / Long  | 고지서를 생성할 청구월의 ID |

- **Request Body (선택적):** `InvoiceBatchGenerationRequestDto`
  ```json
  {
      "unitIds": ["unit-uuid-101", "unit-uuid-102", null], // null 또는 빈 배열 시 해당 청구월 전체 대상
      "issueDate": "2025-07-05", // 고지서 상 발급일 (필수)
      "dueDate": "2025-07-25" // 납부 마감일 (필수, "납부 정보 설정" 기본값 사용 가능)
  }
  ```

- **Success Response**:

  - **Code:** `202 Accepted` (비동기 대량 처리 시) 또는 `200 OK` (동기 처리 및 요약 반환 시)

  - Body (예시 - 비동기):

    JSON

```
    {
        "jobId": "inv-gen-job-uuid-001",
        "message": "고지서 일괄 생성 작업이 시작되었습니다. 완료 후 목록에서 확인할 수 있습니다."
    }
```

  - Body (예시 - 동기):

    JSON

    ```
    {
        "billingMonthId": "bm-uuid-202506",
        "invoicesGeneratedCount": 50,
        "message": "50건의 고지서가 성공적으로 생성되었습니다."
    }
    ```

- **Error Responses:** `400 Bad Request` (청구월 상태 부적합 - 예: 산정 미확정, 필수 정보 누락), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId).

------

### 4.2. 특정 청구월의 생성된 고지서 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/billing-months/{billingMonthId}/invoices`

- **설명:** 지정된 청구월에 대해 생성되었거나 발급된 고지서 목록을 조회한다.

- **요청 권한:** 경리담당자, 관리소장

- **Path Parameters:** `billingMonthId`

- **Query Parameters:**

  | 파라미터명    | 타입    | 필수 | 설명                                    | 예시              |
  | :------------ | :------ | :--- | :-------------------------------------- | :---------------- |
  | unitId      | String  | N    | 특정 호실의 고지서만 필터링             | unit-uuid-101   |
  | status      | String  | N    | 고지서 상태 필터링 (DRAFT, GENERATED, ISSUED, SENT 등) | GENERATED       |
  | page, size, sortBy (unitNumber, issueDate), sortDirection (공통 파라미터) |         | N    |                                         | unitNumber ASC  |

- **Success Response:** `200 OK`, `PagedResponse<InvoiceSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `404 Not Found`.

------

### 4.3. 특정 고지서 상세 조회 (및 미리보기 데이터)

- **HTTP Method:** `GET`
- **URI:** `/invoices/{invoiceId}`
- **설명:** 지정된 ID의 고지서 상세 정보를 조회한다. 이 정보는 미리보기 화면 구성에 사용될 수 있다.
- **요청 권한:** 경리담당자, 관리소장, (관련 임차인 - 포털 연동 시)
- **Path Parameters:** `invoiceId` (고지서 고유 ID)
- **Success Response:** `200 OK`, `InvoiceDetailResponseDto` (항목별 상세 금액, 납부 정보 등 포함)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.4. 특정 고지서 미리보기 (파일 형식 요청)

- **HTTP Method:** `GET`

- **URI:** `/invoices/{invoiceId}/preview`

- **설명:** 지정된 ID의 고지서를 특정 파일 형식(예: PDF, HTML)으로 미리보기 위해 조회한다.

- **요청 권한:** 경리담당자, 관리소장

- **Path Parameters:** `invoiceId`

- **Query Parameters (또는 `Accept` 헤더 사용):**

  | 파라미터명 | 타입   | 필수 | 설명                           | 예시  |
  | :--------- | :----- | :--- | :----------------------------- | :---- |
  | format   | String | N    | 미리보기 형식 (html, pdf 등) | pdf |

- **Success Response:**

  - **Code:** `200 OK`
  - **Headers (PDF 요청 시 예):** `Content-Type: application/pdf`, `Content-Disposition: inline; filename="invoice_{invoiceId}.pdf"`
  - **Body:** (요청 형식에 따른 파일 스트림 또는 HTML 내용)

- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.5. 특정 청구월 고지서 일괄 발급 처리 (상태 변경 및 알림 트리거)

- **HTTP Method:** `POST`

- **URI:** `/billing-months/{billingMonthId}/invoices/batch-issue`

- **설명:** 지정된 청구월에 대해 '생성됨(GENERATED)' 상태의 고지서들을 '발급 완료(ISSUED)' 상태로 변경하고, 설정에 따라 실제 통지(이메일, SMS 등) 프로세스를 트리거한다.

- **요청 권한:** 경리담당자, 관리소장

- **Path Parameters:** `billingMonthId`

- Request Body (선택적):

  ```
  InvoiceBatchIssueRequestDto
  ```

  JSON

  ```
  {
      "invoiceIds": ["inv-uuid-001", "inv-uuid-002", null], // null 또는 빈 배열 시 해당 청구월 전체 '생성됨' 상태 고지서 대상
      "issuanceNotes": "2025년 6월분 관리비 정기 고지 완료", // 선택적 발급 메모
      "sendNotification": true // 실제 알림 발송 여부 (기본값: true)
  }
  ```

- Success Response:

  - **Code:** `202 Accepted` (비동기 대량 처리 시) 또는 `200 OK` (동기 처리 및 요약 반환 시)

  - Body (예시):

    JSON

    ```
    {
        "jobId": "inv-issue-job-uuid-001", // 비동기 처리 시
        "message": "고지서 발급 처리 및 알림 발송 작업이 시작되었습니다.",
        "summary": {
            "totalInvoicesProcessed": 50,
            "successfullyIssued": 50,
            "notificationsTriggered": 50 // 알림 발송 시도 건수
        }
    }
    ```

- **Error Responses:** `400 Bad Request` (청구월 상태 부적합, 대상 고지서 없음 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.6. (선택) 특정 고지서 재발송/개별 발송

- **HTTP Method:** `POST`

- **URI:** `/invoices/{invoiceId}/actions/send`

- **설명:** 이미 '발급 완료(ISSUED)' 상태인 특정 고지서를 임차인에게 재발송하거나, 선택한 채널로 개별 발송한다.

- **요청 권한:** 경리담당자, 관리소장

- **Path Parameters:** `invoiceId`

- Request Body:

  ```
  InvoiceSendRequestDto
  ```

  JSON

  ```
  {
      "channels": ["EMAIL", "SMS"], // 재발송할 채널 지정 (없을 시 기본 설정 채널)
      "isResend": true
  }
  ```

- Success Response:

  ```
  202 Accepted
  ```

   또는 

  ```
  200 OK
  ```

  JSON

  ```
  {
      "message": "고지서가 지정된 채널로 재발송 요청되었습니다.",
      "deliveryStatus": [ // 각 채널별 발송 시도 결과 (NotificationLog 와 연계)
          {"channel": "EMAIL", "status": "SENT_SUCCESS", "recipient": "tenant@example.com"}
      ]
  }
  ```

- **Error Responses:** `400 Bad Request` (고지서 상태 부적합), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `InvoiceSummaryDto` (목록 조회용)

JSON

```
{
    "invoiceId": "string",
    "billingYearMonth": "string (YYYY-MM)",
    "unitNumber": "string", // 예: "101동 1001호"
    "tenantName": "string",
    "totalAmountBilled": "number",
    "issueDate": "string (YYYY-MM-DD)",
    "dueDate": "string (YYYY-MM-DD)",
    "status": "string (Enum: DRAFT, GENERATED, ISSUED, SENT_EMAIL, SENT_SMS, VIEWED)",
    "statusName": "string" // 상태 한글명
}
```

### 5.2. `InvoiceDetailResponseDto` (상세 조회용)

JSON

```
{
    "invoiceId": "string",
    "billingMonthId": "string",
    "billingYearMonth": "string (YYYY-MM)",
    "unitInfo": { "unitId": "string", "unitNumber": "string", "buildingName": "string", "areaSqm": "number" },
    "tenantInfo": { "tenantId": "string", "tenantName": "string", "contactNumber": "string" },
    "lessorInfo": { "lessorId": "string", "lessorName": "string" }, // 고지서 표기용 임대인 정보
    "managementCompanyInfo": { // 고지서 표기용 관리주체 정보
        "companyName": "string",
        "address": "string",
        "contactNumber": "string",
        "businessRegistrationNumber": "string"
    },
    "issueDate": "string (YYYY-MM-DD)",
    "dueDate": "string (YYYY-MM-DD)",
    "totalAmountBilled": "number", // 최종 청구 금액 (미납/연체 포함 가능)
    "currentMonthFee": "number",   // 당월 부과 순수 관리비
    "previousUnpaidAmount": "number (nullable)", // 이월된 전월 미납액
    "lateFeeApplied": "number (nullable)", // 당월 발생 또는 누적 연체료
    "adjustments": "number (nullable)", // 기타 가감액
    "itemizedDetails": [ // array of InvoiceItemDetailDto
        {
            "feeItemId": "string",
            "itemName": "string", // 관리비 항목명
            "calculationBasis": "string (nullable)", // 산출근거 (예: 100kWh * 120원/kWh)
            "amount": "number", // 항목별 금액 (부가세 제외)
            "vat": "number",    // 항목별 부가세
            "totalWithVat": "number" // 항목별 합계 (부가세 포함)
        }
    ],
    "paymentAccountInfo": { // 납부 계좌 정보 (기본 수납 계좌)
        "bankName": "string",
        "accountNumber": "string",
        "accountHolder": "string"
    },
    "status": "string (Enum)",
    "statusName": "string",
    "invoiceContentRef": "string (nullable)", // 생성된 PDF 파일의 S3 Key 등
    "createdAt": "string (ISO DateTime)",
    "issuedAt": "string (ISO DateTime, nullable)" // 실제 발급(시스템 처리) 일시
}
```

(Create/Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

```
이 API 설계안은 QIRO 서비스의 "관리비 고지서 발급" 기능의 핵심적인 부분을 다룹니다. 실제 고지서에 표시될 항목이나 상세 계산 로직은 "관리비 산정" 기능과의 연동, 그리고 "납부 정보 설정" 및 "관리비 항목 설정"에서 정의된 정책에 따라 결정됩니다. 
```