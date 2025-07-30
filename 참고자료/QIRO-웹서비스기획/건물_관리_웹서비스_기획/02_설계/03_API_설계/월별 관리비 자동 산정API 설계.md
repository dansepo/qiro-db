
#  QIRO. 월별 관리비 자동 산정 API 설계

## 1. 문서 정보
- **문서명:** QIRO 월별 관리비 자동 산정 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-FEE-CALC-001 - QIRO - 월별 관리비 자동 산정 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 월별 관리비 자동 산정 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 특정 청구월의 관리비 산정을 실행하고, 계산된 상세 내역을 조회하며, 최종적으로 산정 결과를 확정할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 특정 청구월 관리비 산정 실행

- **HTTP Method:** `POST`
- **URI:** `/billing-months/{billingMonthId}/actions/calculate-fees`
- **설명:** 지정된 청구월에 대한 관리비 자동 산정 프로세스를 시작(또는 재시작)한다. 이 작업은 청구월이 '준비중' 상태이고 모든 필수 기초 데이터가 입력된 후에만 가능하다. 계산이 성공적으로 완료되면, 해당 청구월의 내부 상태는 '산정됨(결과 확인 대기)'으로 변경될 수 있다.
- **요청 권한:** 관리소장, 경리담당자
- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | `billingMonthId`  | UUID / Long  | 관리비를 산정할 청구월의 ID |

- **Request Body (선택적):** `FeeCalculationRequestDto`
  ```json
  {
      "calculationDate": "2025-07-01", // 산정 기준일 (미지정 시 현재일 또는 청구월의 특정일)
      "isRecalculation": false, // 재계산 여부 (기존 산정 내역이 있을 경우)
      "recalculationReason": null // 재계산 사유 (isRecalculation이 true일 경우)
  }
  ```

- **Success Response**:

  - **Code:** `202 Accepted` (비동기 처리 시) 또는 `200 OK` (동기 처리 및 즉시 결과 반환 시)

  - Body (비동기 시):

    JSON

```
    {
        "jobId": "fee-calc-job-uuid-001",
        "message": "관리비 산정 작업이 시작되었습니다. 완료 후 결과를 조회할 수 있습니다.",
        "statusCheckUrl": "/v1/batch-jobs/fee-calc-job-uuid-001" // 작업 상태 확인 URL
    }
```

  - Body (동기 처리 및 요약 결과 반환 시):

    ```
    FeeCalculationSummaryResponseDto
    ```

    JSON

    ```
    {
        "billingMonthId": "bm-uuid-202506",
        "calculationDateTime": "2025-07-01T10:30:00Z",
        "totalBilledAmountForAllUnits": 15250000,
        "numberOfUnitsProcessed": 50,
        "status": "CALCULATED_PENDING_CONFIRMATION", // 예시 내부 상태
        "message": "관리비 산정이 완료되었습니다. 결과를 확인하고 확정해주세요."
    }
    ```

- **Error Responses:** `400 Bad Request` (청구월 상태 부적합, 필수 데이터 누락 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId). `409 Conflict` (이미 다른 산정 작업 진행 중).

------

### 4.2. 특정 청구월 관리비 산정 결과 조회

- **HTTP Method:** `GET`

- **URI:** `/billing-months/{billingMonthId}/fee-calculation-results`

- **설명:** 지정된 청구월의 관리비 산정 결과를 상세하게 조회한다. 세대별, 관리비 항목별 부과 금액 및 합계 정보를 포함한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                         |
  | :---------------- | :----------- | :--------------------------- |
  | billingMonthId  | UUID / Long  | 산정 결과를 조회할 청구월의 ID |

- **Query Parameters:**

  | 파라미터명    | 타입    | 필수 | 설명                                    | 예시              |
  | :------------ | :------ | :--- | :-------------------------------------- | :---------------- |
  | unitId      | String  | N    | 특정 호실의 산정 결과만 필터링          | unit-uuid-101   |
  | unitNumber  | String  | N    | 호실 번호 키워드 검색                   | 101동           |
  | tenantName  | String  | N    | 임차인명 키워드 검색                    | 홍길동          |
  | page, size (공통 페이지네이션 파라미터) |         | N    | (세대별 상세 내역이 많을 경우)        |                   |

- **Success Response:**

  - **Code:** `200 OK`

  - Body:

    ```
    BillingMonthFeeCalculationDetailResponseDto
    ```

    JSON

    ```
    {
        "billingMonthId": "bm-uuid-202506",
        "year": 2025,
        "month": 6,
        "calculationStatus": "CALCULATED_PENDING_CONFIRMATION", // 산정 상태
        "calculationDateTime": "2025-07-01T10:30:00Z",
        "totalBilledAmountForAllUnits": 15250000,
        "numberOfUnitsCalculated": 50,
        "unitCalculations": [ // PagedResponse<UnitFeeCalculationDto> 가능
            {
                "unitId": "unit-uuid-101",
                "unitNumber": "101동 101호",
                "tenantName": "홍길동",
                "totalFeeForUnitBeforeAdjustments": 285000, // 조정 전 관리비 합계
                "feeItemDetails": [
                    {"feeItemId": "fi-001", "itemName": "일반관리비", "amount": 100000, "vat": 10000, "totalWithVat": 110000},
                    {"feeItemId": "fi-002", "itemName": "세대 전기료", "amount": 50000, "vat": 5000, "totalWithVat": 55000},
                    {"feeItemId": "fi-003", "itemName": "공용 수도료", "amount": 20000, "vat": 0, "totalWithVat": 20000}
                    // ... 기타 부과 항목
                ],
                "previousUnpaidAmount": 10000, // 전월 미납액
                "lateFeeApplied": 500, // 당월 발생 연체료
                "adjustments": [{"description": "누수 피해 감면", "amount": -15000}], // 기타 조정액
                "finalAmountDue": 280500 // 최종 납부 요청 금액
            }
            // ... more units
        ]
    }
    ```

- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId 또는 산정 결과 없음).

------

### 4.3. 특정 청구월 관리비 산정 결과 확정

- **HTTP Method:** `POST`

- **URI:** `/billing-months/{billingMonthId}/actions/confirm-fee-calculation`

- **설명:** 관리자가 검토한 관리비 산정 결과를 최종적으로 확정한다. 이 작업 이후, 해당 청구월의 관리비 부과 내역은 변경이 제한되며, 고지서 발급 단계로 진행할 수 있다. 청구월의 주요 상태가 '진행중(IN_PROGRESS)'으로, 내부 진행 상태(마일스톤)가 '산정 완료(CalculationComplete)'로 변경된다.

- **요청 권한:** 관리소장 (또는 최종 확정 권한자)

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | billingMonthId  | UUID / Long  | 산정 결과를 확정할 청구월의 ID |

- **Request Body (선택적):** `ConfirmFeeCalculationRequestDto`

  JSON

  ```
  {
      "confirmationRemarks": "2025년 6월 관리비 산정 내역 최종 검토 및 확정함." // 확정 시 남길 메모
  }
  ```

- **Success Response:**

  - **Code:** `200 OK`

  - Body:

    ```
    BillingMonthResponseDto
    ```

     (상태가 업데이트된 청구월 정보)

    JSON

    ```
    {
        "billingMonthId": "bm-uuid-202506",
        "year": 2025,
        "month": 6,
        "status": "IN_PROGRESS", // 주요 상태 변경
        "internalProgress": "CALCULATION_CONFIRMED", // 내부 진행 상태/마일스톤
        // ...
        "lastModifiedAt": "2025-07-01T11:00:00Z"
    }
    ```

- **Error Responses:** `400 Bad Request` (산정 결과가 없거나 이미 확정된 경우), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `FeeCalculationRequestDto`

JSON

```
{
    "calculationDate": "string (YYYY-MM-DD, nullable)",
    "isRecalculation": "boolean (default: false)",
    "recalculationReason": "string (nullable, isRecalculation이 true일 경우)"
}
```

### 5.2. `FeeCalculationSummaryResponseDto` (동기 처리 시 간단 응답)

JSON

```
{
    "billingMonthId": "string",
    "calculationDateTime": "string (ISO DateTime)",
    "totalBilledAmountForAllUnits": "number",
    "numberOfUnitsProcessed": "integer",
    "status": "string (Enum)", // 예: CALCULATED_PENDING_CONFIRMATION
    "message": "string"
}
```

### 5.3. `BillingMonthFeeCalculationDetailResponseDto` (산정 결과 상세)

(4.2의 성공 응답 본문 참조)

- ```
  UnitFeeCalculationDto
  ```

   (내부 배열 요소):

  JSON

  ```
  {
      "unitId": "string",
      "unitNumber": "string",
      "tenantName": "string (nullable)",
      "totalFeeForUnitBeforeAdjustments": "number", // 순수 관리비 항목 합계 (부가세 포함)
      "feeItemDetails": [ // array of FeeItemCalculationDetailDto
          {
              "feeItemId": "string",
              "itemName": "string",
              "amount": "number", // 부가세 제외 금액
              "vat": "number",    // 부가세액
              "totalWithVat": "number" // 부가세 포함 금액
          }
      ],
      "previousUnpaidAmount": "number (nullable)",
      "lateFeeApplied": "number (nullable)",
      "adjustments": [ // array of AdjustmentDto (선택적)
          {"description": "string", "amount": "number"} // 음수 가능
      ],
      "finalAmountDue": "number" // 최종 납부 요청 금액
  }
  ```

### 5.4. `BillingMonthResponseDto` (상태 변경 등 응답 시)

(이전에 "청구월 관리 API"에서 정의된 DTO 참조)

------

```
이 API 설계안은 QIRO 서비스의 "월별 관리비 자동 산정" 기능의 핵심적인 실행, 조회, 확정 단계를 다룹니다. 실제 구현 시에는 각 관리비 항목별 세부 계산 로직(기능 명세서 5.1절 참조), 예외 처리, 그리고 비동기 처리 시 작업 상태를 조회하는 API 등을 더욱 상세히 정의해야 합니다. 
```