
# 💸 QIRO 입주/퇴실 정산 처리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 입주/퇴실 정산 처리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-MVOUTSETTLE-001 - QIRO - 입주/퇴실 시 임대료 및 관리비 정산 처리 기능 명세서.md` (v1.1 기준)
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 입주 및 퇴실 시 발생하는 임대료, 관리비, 공과금, 보증금 및 기타 비용 정산 처리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 정산 내역을 정확히 계산, 기록, 조회하고 정산서를 생성할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (정산서 등 파일 요청 시 해당 파일 형식)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 퇴실 정산 (Move-Out Settlements) API (`/move-out-settlements`)

#### 4.1.1. 퇴실 정산 내역 사전 계산 (Preview)
- **HTTP Method:** `POST`
- **URI:** `/move-out-settlements/calculate-preview`
- **설명:** 특정 임대 계약 및 퇴실(정산 기준)일에 대해 예상되는 퇴실 정산 내역을 사전 계산하여 반환한다. 실제 데이터를 저장하지는 않는다.
- **요청 권한:** 관리소장, 경리담당자
- **Request Body:** `MoveOutSettlementCalculationRequestDto`
  ```json
  {
      "leaseContractId": "contract-uuid-string",
      "moveOutDate": "2025-12-15", // 실제 퇴실일(정산 기준일)
      "finalMeterReadings": [ // 이 시점의 최종 검침값
          {"utilityTypeCode": "ELEC_I", "readingValue": 15500.0, "readingDate": "2025-12-15"},
          {"utilityTypeCode": "WATER_I", "readingValue": 1250.0, "readingDate": "2025-12-15"},
          {"utilityTypeCode": "GAS_I", "readingValue": 750.0, "readingDate": "2025-12-15"}
      ],
      "damageRepairCosts": 50000, // 선택 사항: 손해 배상금
      "otherDeductions": [ // 선택 사항: 기타 공제 항목
          {"itemName": "퇴실 청소비", "amount": 70000},
          {"itemName": "키 반납 분실 비용", "amount": 20000}
      ],
      "otherRefunds": [ // 선택 사항: 기타 환급 항목
          {"itemName": "선수관리비 반환", "amount": 150000}
      ]
  }
  ```

- **Success Response**:
  
  - **Code:** `200 OK`
  - **Body:** `MoveOutSettlementPreviewResponseDto` (상세 계산 내역 포함)
- **Error Responses:** `400 Bad Request` (필수값 누락, 날짜 오류 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (leaseContractId).

#### 4.1.2. 신규 퇴실 정산 기록 생성 및 확정

- **HTTP Method:** `POST`

- **URI:** `/move-out-settlements`

- **설명:** 퇴실 정산 내역을 시스템에 최종 기록하고 확정한다. 요청 본문은 사전 계산된 내역 또는 관리자가 조정한 최종 내역을 포함할 수 있다.

- **요청 권한:** 관리소장, 경리담당자

- Request Body:

```
  MoveOutSettlementCreateDto
```

   (4.1.1의 Request DTO와 유사하며, 필요시 정산 관련 추가 메모 등 포함)

  JSON

  ```
  {
      "leaseContractId": "contract-uuid-string",
      "moveOutDate": "2025-12-15",
      "finalMeterReadings": [
          {"utilityTypeCode": "ELEC_I", "readingValue": 15500.0, "readingDate": "2025-12-15"},
          // ...
      ],
      "damageRepairCosts": 50000,
      "otherDeductions": [{"itemName": "퇴실 청소비", "amount": 70000}],
      "otherRefunds": [{"itemName": "선수관리비 반환", "amount": 150000}],
      "remarks": "임차인과 최종 합의된 정산 내역임.",
      "settlementDate": "2025-12-16", // 실제 정산금 지급/수령일
      "settlementMethod": "BANK_TRANSFER", // 지급/수령 방법
      "netSettlementAmountCalculated": -350000 // 시스템 계산 또는 확인된 최종 정산액 (음수: 임차인 추가납부)
  }
  ```

- Success Response:

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/move-out-settlements/{settlementId}`
  - **Body:** `MoveOutSettlementResponseDto` (생성된 정산 기록)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.3. 퇴실 정산 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/move-out-settlements`

- **설명:** 퇴실 정산 기록 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                      | 예시                     |
  | :------------------- | :------ | :--- | :---------------------------------------- | :----------------------- |
  | buildingId         | String  | N    | 특정 건물 필터링                          | building-uuid          |
  | unitId             | String  | N    | 특정 호실 필터링                          | unit-uuid              |
  | tenantNameKeyword  | String  | N    | 임차인명 키워드 검색                      | 홍길동                 |
  | moveOutDateFrom    | String  | N    | 퇴실(정산)일 검색 시작일 (YYYY-MM-DD)     | 2025-12-01             |
  | moveOutDateTo      | String  | N    | 퇴실(정산)일 검색 종료일 (YYYY-MM-DD)     | 2025-12-31             |
  | status             | String  | N    | 정산 상태 필터링 (예: PENDING_CALC, CALCULATED, SETTLED) | SETTLED                |
  | page, size, sortBy (moveOutDate, netSettlementAmount), sortDirection (공통 파라미터) |         | N    |                                           | moveOutDate DESC       |
- **Success Response:** `200 OK`, `PagedResponse<MoveOutSettlementSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.4. 특정 퇴실 정산 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/move-out-settlements/{settlementId}`
- **설명:** 지정된 ID의 퇴실 정산 상세 정보를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Path Parameters:** `settlementId`
- **Success Response:** `200 OK`, `MoveOutSettlementResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.5. 퇴실 정산 정보 수정 (주로 정산 완료 처리 및 메모 수정)

- **HTTP Method:** `PUT` (또는 `PATCH`)

- **URI:** `/move-out-settlements/{settlementId}`

- **설명:** 이미 생성된 퇴실 정산 기록의 일부 정보(예: 실제 정산금 지급/수령 정보, 상태, 메모)를 수정한다. (핵심 계산 항목 수정은 제한적이어야 함)

- **요청 권한:** 관리소장, 경리담당자

- **Path Parameters:** `settlementId`

- Request Body:

  ```
  MoveOutSettlementUpdateDto
  ```

  JSON

  ```
  {
      "settlementDate": "2025-12-17",
      "settlementMethod": "CASH",
      "settlementTransactionRef": "직접 전달",
      "status": "SETTLED",
      "remarks": "임차인 확인 후 현금으로 보증금 잔액 반환 완료."
  }
  ```

- **Success Response:** `200 OK`, `MoveOutSettlementResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 퇴실 정산 내역서 조회/다운로드

- **HTTP Method:** `GET`
- **URI:** `/move-out-settlements/{settlementId}/statement`
- **설명:** 지정된 퇴실 정산 건에 대한 정산 내역서를 PDF 등의 형식으로 조회하거나 다운로드한다.
- **요청 권한:** 관리소장, 경리담당자, (관련 임차인 - 포털 연동 시)
- **Path Parameters:** `settlementId`
- **Query Parameters:** `format` (String, N, 기본값 `pdf`, 예: `html`, `pdf`)
- Success Response:
  - **Code:** `200 OK`
  - **Headers (파일 다운로드 시):** `Content-Type: application/pdf`, `Content-Disposition: attachment; filename="move_out_statement_{settlementId}.pdf"`
  - **Body:** (파일 바이너리 또는 HTML 내용)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.2. 입주 시 초기 정보 기록 API (간소화)

*(입주 시 정산은 주로 첫 달 임대료/관리비 계산과 초기 검침값 기록에 중점. 이는 첫 관리비 부과 시 반영되거나, 계약 활성화 시점에 처리될 수 있음. 여기서는 계약과 연관된 초기 검침값 기록을 위한 API 예시)*

#### 4.2.1. 특정 계약에 대한 입주 시 초기 검침값 기록

- **HTTP Method:** `POST`

- **URI:** `/lease-contracts/{contractId}/move-in-meter-readings`

- **설명:** 특정 임대 계약과 관련하여 입주 시점의 각 개별 공과금 항목에 대한 초기 계량기 검침값을 기록한다. 이 값은 해당 임차인의 첫 사용량 계산 시 '전월 지침'으로 사용된다.

- **요청 권한:** 관리소장

- **Path Parameters:** `contractId`

- Request Body:

  ```
  List<MoveInMeterReadingDto>
  ```

  JSON

  ```
  [
      {"utilityTypeCode": "ELEC_I", "readingValue": 12000.0, "readingDate": "2025-07-01"},
      {"utilityTypeCode": "WATER_I", "readingValue": 850.5, "readingDate": "2025-07-01"},
      {"utilityTypeCode": "GAS_I", "readingValue": 500.0, "readingDate": "2025-07-01"}
  ]
  ```

- Success Response:

  - **Code:** `201 Created` (또는 `200 OK` если 업데이트 개념)
  - **Body:** (저장된 검침 기록 정보 목록)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (contractId).

*(참고: 첫 달 임대료/고정관리비 일할계산은 "신규 청구월 생성" 또는 첫 "관리비 산정" 시 계약 시작일을 기준으로 시스템이 계산하는 것을 기본으로 하며, 별도의 입주 시 '정산' API를 통해 명시적으로 생성하기보다는 해당 월의 관리비 부과 로직에 통합될 수 있음. 만약 입주 시 별도 정산서 발행이 필요하다면, 4.1.1과 유사한 `POST /move-in-settlements/calculate-preview` API를 설계할 수 있음.)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `MoveOutSettlementResponseDto` / `MoveOutSettlementSummaryDto`

JSON

  ```
// MoveOutSettlementSummaryDto (목록용)
{
    "settlementId": "string",
    "unitNumber": "string", // 예: "101동 1001호"
    "tenantName": "string",
    "moveOutDate": "string (YYYY-MM-DD)",
    "contractEndDate": "string (YYYY-MM-DD)", // 참고용
    "depositAmountHeld": "number",
    "totalDeductionsCalculated": "number", // 총 공제액
    "netSettlementAmount": "number", // 최종 정산액 (양수: 반환, 음수: 추가 징수)
    "status": "string (Enum)" // PENDING_CALCULATION, CALCULATED, SETTLED 등
}

// MoveOutSettlementResponseDto (상세용 - PreviewDto와 유사하나 저장된 ID 등 포함)
{
    "settlementId": "string",
    "leaseContractId": "string",
    "unitInfo": { /* ... */ },
    "tenantInfo": { /* ... */ },
    "moveOutDate": "string (YYYY-MM-DD)",
    "depositAmountHeld": "number",
    "calculations": {
        "finalRentProrated": "number",
        "finalFixedMaintFeeProrated": "number",
        "finalUtilityBills": [
            {"utilityTypeName": "전기료", "usage": "number", "amount": "number"}
        ],
        "totalPriorUnpaidDues": "number",
        "damageRepairCosts": "number",
        "otherDeductions": [{"itemName": "string", "amount": "number"}],
        "otherRefunds": [{"itemName": "string", "amount": "number"}]
    },
    "totalDeductionsCalculated": "number",
    "netSettlementAmount": "number",
    "status": "string (Enum)",
    "settlementDate": "string (YYYY-MM-DD, nullable)", // 실제 정산금 처리일
    "settlementMethod": "string (nullable)",
    "settlementTransactionRef": "string (nullable)",
    "remarks": "string (nullable)",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `MoveOutSettlementCalculationRequestDto` / `MoveOutSettlementCreateDto`

(4.1.1 및 4.1.2 요청 본문 예시 참조)

### 5.3. `MoveInMeterReadingDto`

JSON

```
{
    "utilityTypeCode": "string (Enum)", // ELEC_I, WATER_I, GAS_I 등
    "readingValue": "number",
    "readingDate": "string (YYYY-MM-DD)"
}
```

*(PagedResponse<Dto>는 목록 조회 시 공통적으로 사용)*

------

