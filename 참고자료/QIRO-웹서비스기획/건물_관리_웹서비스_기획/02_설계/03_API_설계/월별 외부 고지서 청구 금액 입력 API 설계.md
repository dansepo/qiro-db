
# 🧾 QIRO 월별 외부 고지서 청구 금액 입력 API 설계

## 1. 문서 정보
- **문서명:** QIRO 월별 외부 고지서 청구 금액 입력 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** (F-EXTBILL-AMT-001 - QIRO - 월별 외부 고지서 청구 금액 입력 기능 명세서.md - 가칭)
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스에서 특정 청구월에 대해 외부 공급자(예: 한전, 도시가스, 수도사업소)로부터 받은 고지서의 총 청구 금액을 입력하고, 해당 금액이 개별 사용료와 공용 사용료로 사용될 경우 그 기초 분배 금액을 지정하는 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 입력된 금액은 "관리비 산정" 시 중요한 기초 데이터로 활용된다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 첨부 시 해당 형식 명시)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 특정 청구월의 외부 고지서 청구 금액 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/billing-months/{billingMonthId}/external-bill-amounts`
- **설명:** 지정된 청구월에 대해 이미 입력된 외부 고지서 고객번호별 청구 금액 및 분배 내역 목록을 조회한다. UI에서 해당 월의 입력 화면을 구성할 때 기존 데이터를 보여주는 데 사용된다.
- **요청 권한:** 관리소장, 경리담당자
- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                     |
  | :---------------- | :----------- | :----------------------- |
  | `billingMonthId`  | UUID / Long  | 조회할 청구월의 ID       |

- **Query Parameters:**

  | 파라미터명           | 타입   | 필수 | 설명                                     | 예시                          |
  | :------------------- | :----- | :--- | :--------------------------------------- | :---------------------------- |
  | `buildingId`         | String | N    | 특정 건물 필터링 (청구월이 건물별로 관리될 경우) | `building-uuid-001`           |
  | `extBillAccountId`   | String | N    | 특정 외부 고지서 고객번호에 대한 정보만 조회 | `eba-uuid-string-001`         |

- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `List<MonthlyExternalBillAmountResponseDto>`
      ```json
      [
          {
              "monthlyExtBillAmountId": "meba-uuid-001",
              "billingMonthId": "bm-uuid-202506",
              "extBillAccount": { // 외부 고지서 고객번호 정보 요약
                  "extBillAccountId": "eba-uuid-string-001",
                  "customerNumber": "1234567890",
                  "utilityType": "ELECTRICITY",
                  "accountNickname": "본관 전체 전기",
                  "isForIndividualUsage": true,
                  "isForCommonUsage": true
              },
              "totalBilledAmount": 1000000,
              "commonUsageAllocatedAmount": 200000,
              "individualUsagePoolAmount": 800000,
              "billStatementFile": {
                  "fileName": "kepco_bill_jun.pdf",
                  "fileKey": "s3-key-for-kepco-bill.pdf",
                  "fileUrl": "https://s3..." // 선택 사항
              },
              "remarks": "6월분 본관 전체 전기료",
              "lastModifiedAt": "2025-07-05T10:00:00Z"
          }
          // ... more items
      ]
      ```
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `404 Not Found` (billingMonthId).

---
### 4.2. 특정 청구월의 외부 고지서 청구 금액 일괄 생성/수정 (Upsert)

- **HTTP Method:** `PUT`
- **URI:** `/billing-months/{billingMonthId}/external-bill-amounts`
- **설명:** 지정된 청구월에 대해 여러 외부 고지서 고객번호의 월별 청구 총액 및 (필요시) 개별/공용 분배 금액을 일괄적으로 생성하거나 수정한다 (Upsert 방식). UI에서 여러 항목을 한 번에 저장할 때 사용된다.
- **요청 권한:** 관리소장, 경리담당자
- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                     |
  | :---------------- | :----------- | :----------------------- |
  | `billingMonthId`  | UUID / Long  | 설정할 청구월의 ID       |

- **Request Body:** `List<MonthlyExternalBillAmountUpsertRequestDto>`
  ```json
  [
      {
          "extBillAccountId": "eba-uuid-string-001", // KEPCO 전기료 고객번호
          "totalBilledAmount": 1000000,
          // 이 고객번호가 isForIndividualUsage=true AND isForCommonUsage=true 일 경우에만 아래 필드 유효/필수
          "commonUsageAllocatedAmountIfMixed": 200000,
          "billStatementFileKey": "s3-key-kepco.pdf", // S3 등에 업로드된 파일의 Key
          "remarks": "6월분 본관 전체 전기료"
      },
      {
          "extBillAccountId": "eba-uuid-string-002", // 수도료 고객번호 (공용 전용으로 가정)
          "totalBilledAmount": 300000,
          // commonUsageAllocatedAmountIfMixed 필드는 이 고객번호가 공용 전용이므로 불필요 (서버가 totalBilledAmount를 공용으로 간주)
          "remarks": "6월분 공용 수도료"
      },
      {
          "extBillAccountId": "eba-uuid-string-003", // 가스료 고객번호 (개별 전용으로 가정)
          "totalBilledAmount": 500000,
          // commonUsageAllocatedAmountIfMixed 필드는 이 고객번호가 개별 전용이므로 불필요 (서버가 totalBilledAmount를 개별 사용료 풀로 간주)
          "remarks": "6월분 세대 가스료 총액"
      }
  ]
  ```

- **Success Response**:
  
  - **Code:** `200 OK`
  - **Body:** `List<MonthlyExternalBillAmountResponseDto>` (생성/수정된 전체 목록)
- **Error Responses:** `400 Bad Request` (입력값 유효성 오류, 청구월 상태가 '준비중'이 아님 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId 또는 요청 내 extBillAccountId).

------

### 4.3. 특정 월별 외부 고지서 청구 금액 상세 조회

- **HTTP Method:** `GET`

- **URI:** `/external-bill-amounts/{monthlyExtBillAmountId}`

- **설명:** 지정된 ID의 월별 외부 고지서 청구 금액 상세 정보를 조회한다.

- **요청 권한:** 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명                | 타입         | 설명                                  |
  | :----------------------- | :----------- | :------------------------------------ |
  | monthlyExtBillAmountId | UUID / Long  | 조회할 월별 외부 고지서 청구 금액 기록 ID |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `MonthlyExternalBillAmountResponseDto` (4.1의 응답 본문 내 객체와 동일)

- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

------

### 4.4. 특정 월별 외부 고지서 청구 금액 삭제 (제한적)

- **HTTP Method:** `DELETE`

- **URI:** `/external-bill-amounts/{monthlyExtBillAmountId}`

- **설명:** 지정된 ID의 월별 외부 고지서 청구 금액 기록을 삭제한다. (청구월 상태가 '준비중'일 때만 가능)

- **요청 권한:** 관리소장, 경리담당자

- **Path Parameters:**

  | 파라미터명                | 타입         | 설명                                  |
  | :----------------------- | :----------- | :------------------------------------ |
  | monthlyExtBillAmountId | UUID / Long  | 삭제할 월별 외부 고지서 청구 금액 기록 ID |

- **Success Response:**

  - **Code:** `204 No Content`

- **Error Responses:** `400 Bad Request` (청구월 상태가 '준비중'이 아님), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

*(참고: 고지서 파일 첨부는 파일 업로드 전용 API를 통해 먼저 S3 등에 업로드 후, 그 결과로 받은 fileKey 또는 URL을 이 API들에 전달하는 방식을 권장합니다. 이 명세서에서는 fileKey를 전달하는 것으로 가정합니다.)*

## 5. 데이터 모델 (DTOs)

### 5.1. `MonthlyExternalBillAmountResponseDto`

JSON

```
{
    "monthlyExtBillAmountId": "string (UUID or Long)",
    "billingMonthId": "string (UUID or Long)",
    "billingYearMonth": "string (YYYY-MM)", // 편의 정보
    "extBillAccount": { // 외부 고지서 고객번호 상세 정보 (ExternalBillAccountBriefDto)
        "extBillAccountId": "string",
        "customerNumber": "string",
        "utilityType": "string (Enum)",
        "utilityTypeName": "string", // 예: "전기", "수도"
        "supplierName": "string",
        "accountNickname": "string",
        "isForIndividualUsage": "boolean",
        "isForCommonUsage": "boolean"
    },
    "totalBilledAmount": "number", // 해당 고객번호로 청구된 총액
    "commonUsageAllocatedAmount": "number (nullable)", // 위 총액 중 공용 사용료로 배분(지정)된 금액
    "individualUsagePoolAmount": "number (nullable)", // 위 총액 중 개별 사용료 풀로 배분(지정)된 금액
    "billStatementFile": { // AttachmentInfo Dto (선택 사항)
        "fileName": "string (nullable)",
        "fileKey": "string (nullable)", // S3 Key 등
        "fileUrl": "string (nullable)"  // 다운로드 URL
    },
    "remarks": "string (nullable)",
    "enteredBy": "string (User ID/Name)",
    "entryDate": "string (ISO DateTime)", // 금액 입력/수정일
    "lastModifiedAt": "string (ISO DateTime)"
}
```

### 5.2. `MonthlyExternalBillAmountUpsertRequestDto` (4.2 요청 본문 내 배열 요소)

JSON

```
{
    "extBillAccountId": "string", // 필수
    "totalBilledAmount": "number", // 필수
    // extBillAccountId에 연결된 ExternalBillAccount의 isForIndividualUsage=true AND isForCommonUsage=true 일 경우에만 필수 또는 유효
    "commonUsageAllocatedAmountIfMixed": "number (nullable)",
    "billStatementFileKey": "string (nullable)", // S3 등에 업로드된 파일의 Key
    "remarks": "string (nullable)"
}
```

*서버 로직: `commonUsageAllocatedAmountIfMixed`가 제공되면, `individualUsagePoolAmount = totalBilledAmount - commonUsageAllocatedAmountIfMixed`로 계산. 만약 `ExternalBillAccount`가 단일 용도(개별 전용 또는 공용 전용)이면, `totalBilledAmount`가 해당 용도의 금액으로 자동 설정됨.*

*(PagedResponse<Dto>는 목록 조회 시 공통적으로 사용)*

------

```
이 API 설계안은 QIRO 서비스의 "월별 외부 고지서 청구 금액 입력" 기능을 위한 핵심 엔드포인트와 데이터 구조를 정의합니다. 특히 하나의 외부 고지서 총액을 개별 사용료와 공용 사용료로 나누어 입력해야 하는 경우의 처리 방안을 `commonUsageAllocatedAmountIfMixed` 필드를 통해 제안했습니다. 실제 구현 시에는 이 분배 로직의 유효성 검증(예: 분배액의 합계가 총액과 일치하는지)을 백엔드에서 철저히 수행해야 합니다. 
```