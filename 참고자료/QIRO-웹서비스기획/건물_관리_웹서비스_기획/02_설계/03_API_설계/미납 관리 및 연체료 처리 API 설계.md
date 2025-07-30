
# ❗ QIRO 미납 관리 및 연체료 처리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 미납 관리 및 연체료 처리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-DELINQMGMT-001 - QIRO - 미납 관리 및 연체료 처리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 미납 관리 및 연체료 처리 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 미납 현황을 조회하고, 연체료를 계산/적용하며, 미납자에게 알림을 발송하는 등의 업무를 수행할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.
미납 기록 자체는 "수납 처리" 결과 및 "납부 마감일" 경과에 따라 시스템 내부적으로 식별되는 것을 전제로 하며, 본 API는 식별된 미납 건에 대한 관리 액션에 중점을 둔다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 미납 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/delinquencies`
- **설명:** 미납된 관리비 또는 임대료 목록을 조회한다. 다양한 조건으로 필터링, 정렬, 페이지네이션 기능을 지원한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                            | 예시                             |
  | :------------------- | :------ | :--- | :---------------------------------------------- | :------------------------------- |
  | `buildingId`         | String  | N    | 특정 건물 필터링                                | `building-uuid`                  |
  | `unitId`             | String  | N    | 특정 호실 필터링                                | `unit-uuid`                      |
  | `tenantId`           | String  | N    | 특정 임차인 필터링                              | `tenant-uuid`                    |
  | `billingYearMonth`   | String  | N    | 미납 발생 청구 연월 필터링 (YYYY-MM)            | `2025-05`                        |
  | `status`             | String  | N    | 미납 상태 필터링 (예: `OVERDUE`, `LATE_FEE_APPLIED`, `REMINDER_SENT_1ST`, `PAYMENT_PLAN_ACTIVE`, `RESOLVED`) | `OVERDUE`                        |
  | `minOverdueDays`     | Integer | N    | 최소 연체 일수                                  | `30`                             |
  | `maxOverdueDays`     | Integer | N    | 최대 연체 일수                                  | `60`                             |
  | `minUnpaidAmount`    | Number  | N    | 최소 미납 원금                                  | `50000`                          |
  | `page`, `size`, `sortBy`, `sortDirection` (공통 파라미터) |         | N    |                                                 | `dueDate` ASC                    |

- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `PagedResponse<DelinquencySummaryDto>`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

---
### 4.2. 특정 미납 건 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/delinquencies/{delinquencyId}`
- **설명:** 지정된 ID의 미납 건에 대한 상세 정보를 조회한다. (미납 원금, 발생 연체료, 총 미납액, 관련 알림 이력 등 포함)
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Path Parameters:** `delinquencyId` (미납 기록 고유 ID)
- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `DelinquencyDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

---
### 4.3. 연체료 일괄 계산 및 적용 (배치 작업 요청)

- **HTTP Method:** `POST`
- **URI:** `/delinquencies/actions/calculate-all-late-fees`
- **설명:** 현재 시스템에 등록된 모든 미납 건 또는 특정 조건에 맞는 미납 건들에 대해 연체료를 일괄적으로 계산하고 적용(부과)한다. 이 작업은 비동기로 처리될 수 있다.
- **요청 권한:** 총괄관리자, 경리담당자 (정책 실행 권한)
- **Request Body (선택적 필터):** `BatchLateFeeCalculationRequestDto`
  ```json
  {
      "asOfDate": "2025-06-03", // 연체료 계산 기준일 (미지정 시 현재일)
      "filter": { // 선택적: 특정 조건의 미납 건만 대상
          "buildingId": "building-uuid-string-optional",
          "minOverdueDays": 30 // 예: 30일 이상 연체 건만 대상
      }
  }
  ```

- Success Response:
  - **Code:** `202 Accepted` (비동기 작업 시작 시)
  - **Body:** `{ "jobId": "ltf-calc-job-uuid", "message": "연체료 일괄 계산 작업이 요청되었습니다." }`
  - 또는, 동기 처리 시 `200 OK` 와 함께 처리 결과 요약.
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

------

### 4.4. 특정 미납 건 연체료 계산 및 적용

- **HTTP Method:** `POST`

- **URI:** `/delinquencies/{delinquencyId}/actions/calculate-late-fee`

- **설명:** 지정된 ID의 특정 미납 건에 대해 연체료를 계산하고 적용(부과)한다.

- **요청 권한:** 총괄관리자, 경리담당자

- **Path Parameters:** `delinquencyId`

- Request Body (선택적):

  JSON

```
  {
      "asOfDate": "2025-06-03" // 연체료 계산 기준일 (미지정 시 현재일)
  }
```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `DelinquencyDetailResponseDto` (연체료가 업데이트된 상세 정보)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.5. 미납 알림(독촉장) 발송 요청

- **HTTP Method:** `POST`

- **URI:** `/delinquencies/{delinquencyId}/actions/send-reminder`

- **설명:** 지정된 ID의 미납 건에 대해 미납 안내 또는 독촉 알림을 발송한다. (실제 발송은 "알림 및 공지사항 관리" 기능과 연동)

- **요청 권한:** 관리소장, 경리담당자

- **Path Parameters:** `delinquencyId`

- Request Body:

  ```
  SendReminderRequestDto
  ```

  JSON

  ```
  {
      "reminderLevel": "FIRST_NOTICE", // FIRST_NOTICE, SECOND_NOTICE, FINAL_NOTICE 등 Enum
      "channels": ["EMAIL", "SMS"], // 발송 채널 선택 (배열)
      "customMessage": "추가 메시지 내용입니다. 빠른 시일 내 납부 바랍니다." // 선택 사항
  }
  ```

- Success Response:

  - **Code:** `202 Accepted` (알림 발송 작업 요청 성공 시)
  - **Body:** `{ "message": "미납 알림 발송이 요청되었습니다.", "notificationLogIds": ["log-uuid-1", "log-uuid-2"] }`

- **Error Responses:** `400 Bad Request` (잘못된 reminderLevel, 채널 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.6. (선택적 고급 기능) 특정 미납 건에 대한 납부 계획 설정

- **HTTP Method:** `POST`

- **URI:** `/delinquencies/{delinquencyId}/payment-arrangements`

- **설명:** 특정 미납 건에 대해 임차인과 합의된 분할 납부 계획 등을 설정한다.

- **요청 권한:** 관리소장, 경리담당자

- **Path Parameters:** `delinquencyId`

- Request Body:

  ```
  PaymentArrangementCreateDto
  ```

  JSON

  ```
  {
      "numberOfInstallments": 3,
      "installmentAmount": 100000,
      "firstPaymentDueDate": "2025-07-10",
      "paymentIntervalDays": 30, // 또는 특정 날짜 배열
      "notes": "3개월 분할 납부 합의"
  }
  ```

- **Success Response:** `201 Created`, `PaymentArrangementResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.7. (선택적 고급 기능) 특정 미납 건의 납부 계획 조회

- **HTTP Method:** `GET`
- **URI:** `/delinquencies/{delinquencyId}/payment-arrangements`
- **설명:** 특정 미납 건에 설정된 납부 계획(들)을 조회한다.
- **요청 권한:** 관리소장, 경리담당자
- **Path Parameters:** `delinquencyId`
- **Success Response:** `200 OK`, `List<PaymentArrangementResponseDto>`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `DelinquencySummaryDto` (목록 조회용)

JSON

  ```
{
    "delinquencyId": "string (UUID or Long)",
    "buildingName": "string",
    "unitNumber": "string",
    "tenantName": "string",
    "billingYearMonth": "string (YYYY-MM)",
    "originalAmountDue": "number", // 미납 원금
    "currentUnpaidAmount": "number", // 현재 미납 잔액 (부분납 고려)
    "dueDate": "string (YYYY-MM-DD)",
    "overdueDays": "integer",
    "totalLateFeeApplied": "number", // 현재까지 부과된 총 연체료
    "totalAmountOutstanding": "number", // currentUnpaidAmount + totalLateFeeApplied 중 미납분
    "status": "string (Enum)"
}
  ```

### 5.2. `DelinquencyDetailResponseDto` (상세 조회 및 업데이트 응답용)

JSON

```
{
    "delinquencyId": "string",
    "targetLedgerId": "string", // 원본 청구(고지) ID
    "buildingInfo": { "buildingId": "string", "buildingName": "string" },
    "unitInfo": { "unitId": "string", "unitNumber": "string" },
    "tenantInfo": { "tenantId": "string", "tenantName": "string", "contactNumber": "string" },
    "billingYearMonth": "string (YYYY-MM)",
    "feeType": "string (Enum: RENT, MGMT_FEE)", // 미납 항목 구분
    "originalAmountDue": "number",
    "paidAmountOnOriginal": "number", // 원본 청구에 대해 납부된 금액
    "currentUnpaidAmount": "number", // 현재 미납 원금 잔액
    "dueDate": "string (YYYY-MM-DD)",
    "overdueDays": "integer",
    "lateFeePolicy": { // 적용된 연체료 정책 요약
        "ratePercent": "number", // 예: 3.0
        "calculationMethod": "string" // 예: "DAILY_SIMPLE_INTEREST"
    },
    "lateFeeTransactions": [ // array of LateFeeTransactionDto
        {
            "lateFeeTxId": "string",
            "calculationDate": "string (YYYY-MM-DD)",
            "lateFeeAmount": "number",
            "appliedRate": "number",
            "appliedPeriodDays": "integer",
            "remarks": "string (nullable)"
        }
    ],
    "totalLateFeeApplied": "number", // 총 부과 연체료
    "totalLateFeePaid": "number", // 납부된 연체료
    "totalAmountOutstanding": "number", // 최종 미납 총액 (미납원금 + 미납연체료)
    "status": "string (Enum)",
    "lastReminderSentDate": "string (YYYY-MM-DD, nullable)",
    "paymentArrangement": "object (PaymentArrangementResponseDto, nullable)", // 설정된 납부 계획
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
```

### 5.3. `SendReminderRequestDto`

JSON

```
{
    "reminderLevel": "string (Enum: FIRST_NOTICE, SECOND_NOTICE, FINAL_NOTICE, CUSTOM)",
    "channels": ["EMAIL", "SMS"], // Array<String (Enum)>
    "customMessage": "string (nullable, reminderLevel이 CUSTOM일 때 사용)"
}
```

### 5.4. `PaymentArrangementCreateDto` / `PaymentArrangementResponseDto` (선택적)

JSON

```
// PaymentArrangementCreateDto
{
    "numberOfInstallments": "integer", // 분납 횟수
    "installmentAmount": "number", // 회차당 납부액 (마지막 회차는 조정될 수 있음)
    "firstPaymentDueDate": "string (YYYY-MM-DD)",
    "paymentIntervalDays": "integer", // 납부 간격(일) 또는 paymentDates 배열 사용
    // "paymentDates": ["YYYY-MM-DD", "YYYY-MM-DD", ...], // 또는 특정 납부일 지정
    "notes": "string (nullable)"
}

// PaymentArrangementResponseDto (CreateDto 필드 포함 + id, status 등)
{
    "arrangementId": "string",
    "delinquencyId": "string",
    "numberOfInstallments": "integer",
    "installmentAmount": "number",
    "firstPaymentDueDate": "string (YYYY-MM-DD)",
    "paymentIntervalDays": "integer (nullable)",
    "paymentDates": ["string (YYYY-MM-DD)", "... (nullable)"],
    "status": "string (Enum: ACTIVE, COMPLETED, DEFAULTED)",
    "notes": "string (nullable)",
    "createdAt": "string (ISO DateTime)"
}
```

## *(PagedResponseDto는 목록 조회 시 공통적으로 사용)*

