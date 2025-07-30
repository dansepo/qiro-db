
# 💳 QIRO 납부 정보 설정 API 설계

## 1. 문서 정보
- **문서명:** QIRO 납부 정보 설정 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-PAYINFO-001 - QIRO - 납부 정보 설정 기능 명세서.md` (가칭)
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 납부 정보 설정(수납 계좌 관리, 납부 마감일 설정, 연체료율 설정) 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 서비스 내에서 사용될 수납 계좌 정보를 관리하고, 납부 관련 주요 정책을 설정할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다. (주로 총괄관리자 또는 경리 담당자 권한 필요)
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 수납 계좌 (Receiving Bank Accounts) 관리 API (`/payment-settings/bank-accounts`)

#### 4.1.1. 신규 수납 계좌 추가
- **HTTP Method:** `POST`
- **URI:** `/payment-settings/bank-accounts`
- **설명:** 새로운 관리비 수납 계좌 정보를 시스템에 등록한다.
- **요청 권한:** 총괄관리자, 경리담당자
- **Request Body:** `ReceivingBankAccountCreateRequestDto`
  ```json
  {
      "bankName": "QIRO은행",
      "accountNumber": "123-456-789012",
      "accountHolder": "주식회사 QIRO 관리",
      "purpose": "관리비 및 임대료 수납", // 선택 사항
      "isDefault": false
  }
  ```

- **Request Body 필드 설명:**

  | 필드명           | 타입    | 필수 | 설명                         | 비고                  |
  | :--------------- | :------ | :--- | :--------------------------- | :-------------------- |
  | bankName       | String  | Y    | 은행명                       | 최대 50자             |
  | accountNumber  | String  | Y    | 계좌번호                     | 최대 50자, 시스템 내 중복 불가 |
  | accountHolder  | String  | Y    | 예금주명                     | 최대 50자             |
  | purpose        | String  | N    | 계좌 용도                    | 최대 100자            |
  | isDefault      | Boolean | Y    | 기본 수납 계좌 지정 여부     |                       |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/payment-settings/bank-accounts/{accountId}`
  - **Body:** `ReceivingBankAccountResponseDto` (생성된 계좌 정보)

- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류, 계좌번호 중복), `401 Unauthorized`, `403 Forbidden`.

#### 4.1.2. 수납 계좌 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/payment-settings/bank-accounts`

- **설명:** 등록된 모든 수납 계좌 목록을 조회한다.

- **요청 권한:** 총괄관리자, 경리담당자, 관리소장 (조회 권한)

- **Query Parameters:** (필요시 추가 - 예: `isActive=true`)

- Success Response:

  - **Code:** `200 OK`

  - Body:

    ```
    List<ReceivingBankAccountResponseDto>
    ```

    JSON

    ```
    [
        {
            "accountId": "acc-uuid-001",
            "bankName": "QIRO은행",
            "accountNumber": "123-456-789012", // 응답 시 마스킹 처리 고려
            "accountHolder": "주식회사 QIRO 관리",
            "purpose": "관리비 및 임대료 수납",
            "isDefault": true,
            "isActive": true,
            "createdAt": "2025-06-04T09:00:00Z"
        }
        // ... more accounts
    ]
    ```

- **Error Responses:** `401 Unauthorized`.

#### 4.1.3. 특정 수납 계좌 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/payment-settings/bank-accounts/{accountId}`
- **설명:** 지정된 ID의 수납 계좌 상세 정보를 조회한다.
- **요청 권한:** (4.1.2와 유사)
- **Path Parameters:** `accountId` (수납 계좌 고유 ID)
- **Success Response:** `200 OK`, `ReceivingBankAccountResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 수납 계좌 정보 수정

- **HTTP Method:** `PUT`

- **URI:** `/payment-settings/bank-accounts/{accountId}`

- **설명:** 지정된 ID의 수납 계좌 정보를 수정한다.

- **요청 권한:** 총괄관리자, 경리담당자

- **Path Parameters:** `accountId`

- Request Body:

  ```
  ReceivingBankAccountUpdateRequestDto
  ```

   (4.1.1의 Create DTO와 필드 유사)

  JSON

  ```
  {
      "bankName": "새로운 QIRO은행",
      "accountNumber": "123-456-789012", // 계좌번호는 보통 수정 불가 또는 신중한 처리 필요
      "accountHolder": "주식회사 QIRO 관리 (변경)",
      "purpose": "관리비 전용 수납",
      "isDefault": true,
      "isActive": true
  }
  ```

- **Success Response:** `200 OK`, `ReceivingBankAccountResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (수정하려는 계좌번호가 다른 계좌와 중복 시).

#### 4.1.5. 수납 계좌 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/payment-settings/bank-accounts/{accountId}`
- **설명:** 지정된 ID의 수납 계좌를 삭제한다. (기본 계좌이거나 사용 중인 경우 논리적 삭제 또는 비활성화 처리 권장)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `accountId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건: 예: 기본 계좌, 사용 중).

#### 4.1.6. 기본 수납 계좌 설정

- **HTTP Method:** `PATCH` (또는 `PUT`을 특정 필드에 사용)
- **URI:** `/payment-settings/bank-accounts/{accountId}/set-default`
- **설명:** 지정된 ID의 수납 계좌를 기본 수납 계좌로 설정한다. (이전 기본 계좌는 자동으로 일반 계좌로 변경됨)
- **요청 권한:** 총괄관리자, 경리담당자
- **Path Parameters:** `accountId`
- **Request Body:** (없어도 되거나, `{"isDefault": true}` 전달)
- **Success Response:** `200 OK`, `ReceivingBankAccountResponseDto` (업데이트된 계좌 정보)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.2. 납부 정책 (Payment Policies) 관리 API (`/payment-settings/policies`)

*(이 설정은 보통 조직/사업장 단위로 하나만 존재하므로, 특정 ID 없이 단일 리소스로 관리)*

#### 4.2.1. 현재 납부 정책 조회

- **HTTP Method:** `GET`

- **URI:** `/payment-settings/policies`

- **설명:** 현재 시스템(또는 해당 조직)에 설정된 납부 마감일 및 연체료율 정책을 조회한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- Success Response:

  - **Code:** `200 OK`

  - Body:

    ```
    PaymentPolicyResponseDto
    ```

    JSON

    ```
    {
        "paymentDueDay": 25, // 매월 납부 마감일 (1-31, 또는 99는 '말일')
        "lateFeeRate": 3.0, // 연체료율 (%)
        "lateFeeCalculationMethod": "DAILY_SIMPLE_INTEREST", // 연체료 계산 방식 (Enum)
        "lastModifiedAt": "2025-06-01T10:00:00Z",
        "lastModifiedBy": "admin@qiro.com"
    }
    ```

- **Error Responses:** `401 Unauthorized`.

#### 4.2.2. 납부 정책 수정

- **HTTP Method:** `PUT`

- **URI:** `/payment-settings/policies`

- **설명:** 납부 마감일 및 연체료율 정책을 수정한다.

- **요청 권한:** 총괄관리자

- Request Body:

  ```
  PaymentPolicyUpdateRequestDto
  ```

  JSON

  ```
  {
      "paymentDueDay": 28,
      "lateFeeRate": 2.5,
      "lateFeeCalculationMethod": "MONTHLY_SIMPLE_INTEREST_ON_PRINCIPAL" // 변경된 계산 방식
  }
  ```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `PaymentPolicyResponseDto` (업데이트된 정책 정보)

- **Error Responses:** `400 Bad Request` (유효하지 않은 값), `401 Unauthorized`, `403 Forbidden`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `ReceivingBankAccountResponseDto`

JSON

```
{
    "accountId": "string (UUID or Long)",
    "bankName": "string",
    "accountNumber": "string", // 보안상 응답 시 마스킹 처리될 수 있음
    "accountHolder": "string",
    "purpose": "string (nullable)",
    "isDefault": "boolean",
    "isActive": "boolean",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
```

*(Create/Update Request DTO들은 위 Response DTO에서 ID 및 감사 필드 제외, 필요한 입력 필드 포함)*

### 5.2. `PaymentPolicyResponseDto` / `PaymentPolicyUpdateRequestDto`

JSON

```
// PaymentPolicyResponseDto
{
    "paymentDueDay": "integer", // 1-31 (또는 '말일'을 나타내는 특정 값, 예: 99)
    "lateFeeRate": "number", // % 단위
    "lateFeeCalculationMethod": "string (Enum)", // 예: DAILY_SIMPLE_INTEREST, MONTHLY_SIMPLE_INTEREST_ON_PRINCIPAL
    "lastModifiedAt": "string (ISO DateTime)",
    "lastModifiedBy": "string (User ID/Name)"
}

// PaymentPolicyUpdateRequestDto
{
    "paymentDueDay": "integer",
    "lateFeeRate": "number",
    "lateFeeCalculationMethod": "string (Enum, optional)"
}
```

------

