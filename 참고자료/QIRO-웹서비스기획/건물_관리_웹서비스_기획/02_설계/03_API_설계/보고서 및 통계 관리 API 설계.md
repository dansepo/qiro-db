
# 📈 QIRO 보고서 및 통계 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 보고서 및 통계 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-RPTMGMT-001 - QIRO - 보고서 및 통계 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 보고서 및 통계 관리 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 다양한 운영 현황 보고서(임대, 관리비, 시설, 민원, 회계 요약 등)를 조회하고, 조건에 따라 필터링하며, 결과를 다양한 형식(JSON, PDF, Excel)으로 받을 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):**
    - 데이터 조회: 기본 `application/json`, `UTF-8`.
    - 파일 내보내기: `application/pdf`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (Excel), `text/csv` 등. (아래 "3.1. 보고서 형식 지정" 참조)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)
- **페이지네이션:** 목록 형태의 상세 데이터 반환 시 공통 페이지네이션 DTO 사용 (`PagedResponse<T>`).

### 3.1. 보고서 형식 지정 (출력/내보내기)
보고서 데이터의 출력 형식은 다음 두 가지 방법 중 하나로 지정할 수 있다 (팀 정책에 따라 택1 또는 혼용):
1.  **`Accept` 헤더 사용 (Content Negotiation):**
    - `Accept: application/json` (기본값, JSON 데이터 반환)
    - `Accept: application/pdf` (PDF 파일 반환)
    - `Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (Excel 파일 반환)
    - `Accept: text/csv` (CSV 파일 반환)
2.  **쿼리 파라미터 `format` 사용:**
    - 예: `GET /reports/leasing/occupancy-status?format=pdf`
    - 지원 값: `json` (기본값), `pdf`, `xlsx`, `csv`.
    - 파일 반환 시, API는 적절한 `Content-Type` 및 `Content-Disposition: attachment; filename="report-name.ext"` 헤더를 포함하여 응답한다.

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 사용 가능한 보고서 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/reports/available-reports`
- **설명:** 현재 사용자가 생성/조회할 수 있는 사전 정의된 보고서 유형 목록과 각 보고서에 필요한 파라미터 정보를 제공한다.
- **요청 권한:** 보고서 조회 권한이 있는 모든 내부 사용자
- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `List<AvailableReportDto>`
      ```json
      [
          {
              "reportId": "leasing_occupancy_status",
              "reportName": "임대 현황 보고서 (공실률 포함)",
              "description": "건물별, 기간별 임대율 및 공실 현황을 제공합니다.",
              "category": "LEASING",
              "requiredParams": ["asOfDate"],
              "optionalParams": ["buildingId", "unitType"]
          },
          {
              "reportId": "management_fees_collection_status",
              "reportName": "관리비 수납 현황 보고서",
              // ...
          }
          // ... 기타 보고서 정의
      ]
      ```
- **Error Responses:** `401 Unauthorized`.

---
### 4.2. 임대 관련 보고서 API

#### 4.2.1. 임대 현황 보고서 (공실률 포함)
- **HTTP Method:** `GET`
- **URI:** `/reports/leasing/occupancy-status`
- **설명:** 지정된 조건에 따른 건물(들)의 임대율, 공실 현황 및 상세 목록을 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Query Parameters:**

  | 파라미터명    | 타입   | 필수 | 설명                                    | 예시                    |
  | :------------ | :----- | :--- | :-------------------------------------- | :---------------------- |
  | `asOfDate`    | String | Y    | 조회 기준일 (YYYY-MM-DD)                | `2025-06-30`            |
  | `buildingId`  | String | N    | 특정 건물 ID (미지정 시 전체 담당 건물) | `building-uuid-001`     |
  | `unitType`    | String | N    | 호실 유형 코드 (필터링 시)              | `RESIDENTIAL_APT`       |
  | `format`      | String | N    | 출력 형식 (`json`, `pdf`, `xlsx`, `csv`) | `pdf`                   |

- **Success Response (JSON format):**
    - **Code:** `200 OK`
    - **Body:** `OccupancyStatusReportDto`
      ```json
      {
          "reportTitle": "임대 현황 보고서 (2025-06-30 기준)",
          "generatedAt": "2025-06-04T15:00:00Z",
          "filterCriteria": {
              "asOfDate": "2025-06-30",
              "buildingName": "행복아파트 A동 (또는 전체)"
          },
          "summary": {
              "totalUnits": 100,
              "occupiedUnits": 85,
              "vacantUnits": 15,
              "occupancyRate": 85.0 // %
          },
          "details": [ // PagedResponse<OccupancyDetailItemDto> 가능
              {
                  "buildingName": "행복아파트 A동",
                  "unitNumber": "101동 101호",
                  "area": 84.5,
                  "status": "LEASED", // LEASED, VACANT
                  "tenantName": "홍길동", // LEASED 일 경우
                  "leaseEndDate": "2026-05-31" // LEASED 일 경우
              }
              // ...
          ]
      }
      ```
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

*(기타 임대 관련 보고서: `GET /reports/leasing/lease-expiries`, `GET /reports/leasing/rent-income` 등 유사한 패턴으로 정의)*

---
### 4.3. 관리비 관련 보고서 API

#### 4.3.1. 월별 관리비 수납 현황 보고서
- **HTTP Method:** `GET`
- **URI:** `/reports/management-fees/collection-status`
- **설명:** 지정된 청구월 및 조건에 따른 관리비 수납 현황(수납률, 미납액 등) 및 상세 목록을 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Query Parameters:**

  | 파라미터명          | 타입   | 필수 | 설명                                    | 예시                    |
  | :----------------- | :----- | :--- | :-------------------------------------- | :---------------------- |
  | `billingYearMonth` | String | Y    | 조회 대상 청구 연월 (YYYY-MM)           | `2025-05`               |
  | `buildingId`       | String | N    | 특정 건물 ID (미지정 시 전체 담당 건물) | `building-uuid-001`     |
  | `paymentStatus`    | String | N    | 납부 상태 필터링 (예: `UNPAID`, `PARTIALLY_PAID`) | `UNPAID`                |
  | `format`           | String | N    | 출력 형식 (`json`, `pdf`, `xlsx`, `csv`) | `xlsx`                  |

- **Success Response (JSON format):**
    - **Code:** `200 OK`
    - **Body:** `FeeCollectionReportDto`
      ```json
      {
          "reportTitle": "2025년 05월 관리비 수납 현황 보고서",
          "billingYearMonth": "2025-05",
          "generatedAt": "2025-06-04T15:10:00Z",
          "filterCriteria": { /* ... */ },
          "summary": {
              "totalBilledAmount": 50000000,
              "totalCollectedAmount": 48000000,
              "totalUnpaidAmount": 2000000,
              "collectionRate": 96.0 // %
          },
          "details": [ // PagedResponse<FeeCollectionDetailItemDto> 가능
              {
                  "buildingName": "행복아파트 A동",
                  "unitNumber": "101동 101호",
                  "tenantName": "홍길동",
                  "billedAmount": 250000,
                  "paidAmount": 250000,
                  "unpaidAmount": 0,
                  "paymentStatus": "FULLY_PAID",
                  "lastPaymentDate": "2025-05-25"
              },
              {
                  "buildingName": "행복아파트 A동",
                  "unitNumber": "101동 102호",
                  "tenantName": "이영희",
                  "billedAmount": 230000,
                  "paidAmount": 0,
                  "unpaidAmount": 230000,
                  "paymentStatus": "UNPAID",
                  "lastPaymentDate": null
              }
              // ...
          ]
      }
      ```
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

*(기타 관리비 관련 보고서: `GET /reports/management-fees/imposition-summary`, `GET /reports/management-fees/delinquency-aging` 등 유사한 패턴으로 정의)*

---
### 4.4. 시설 관리 관련 보고서 API (예시)

#### 4.4.1. 시설 점검 이력 보고서
- **HTTP Method:** `GET`
- **URI:** `/reports/facility/inspection-history`
- **설명:** 지정된 기간 및 조건에 따른 시설물 점검 이력 목록을 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자
- **Query Parameters:** `periodStart`, `periodEnd`, `buildingId` (N), `facilityId` (N), `facilityTypeCode` (N), `inspectionResultCode` (N), `format` (N).
- **Success Response (JSON):** `200 OK`, `InspectionHistoryReportDto` (점검 기록 목록 포함)

---
### 4.5. 민원 관련 보고서 API (예시)

#### 4.5.1. 민원 유형별/상태별 현황 보고서
- **HTTP Method:** `GET`
- **URI:** `/reports/complaints/summary-by-type-status`
- **설명:** 지정된 기간 및 조건에 따른 민원 발생 현황을 유형별, 상태별로 집계하여 조회한다.
- **요청 권한:** 총괄관리자, 관리소장
- **Query Parameters:** `periodStart`, `periodEnd`, `buildingId` (N), `complaintTypeCode` (N), `status` (N), `format` (N).
- **Success Response (JSON):** `200 OK`, `ComplaintSummaryReportDto` (집계 데이터 및 차트용 데이터 포함 가능)

---
### 4.6. 회계 관련 보고서 API (예시 - 요약 수준)

#### 4.6.1. 기간별 수입/지출 요약 보고서
- **HTTP Method:** `GET`
- **URI:** `/reports/accounting/income-expense-summary`
- **설명:** 지정된 기간 및 건물의 운영 관련 수입과 지출을 요약하여 조회한다. (상세 재무제표는 "회계 관리" 기능 API 참조)
- **요청 권한:** 총괄관리자, 경리담당자
- **Query Parameters:** `periodStart`, `periodEnd`, `buildingId` (N), `format` (N).
- **Success Response (JSON):** `200 OK`, `IncomeExpenseSummaryReportDto` (주요 수입 항목 합계, 주요 지출 항목 합계, 순이익 요약)

## 5. 데이터 모델 (DTOs) - 주요 보고서 예시

### 5.1. `AvailableReportDto`
```json
{
    "reportId": "string", // 보고서 고유 식별자 (API 경로에 사용될 수 있음)
    "reportName": "string", // 보고서 사용자 표시명
    "description": "string", // 보고서 설명
    "category": "string (Enum: LEASING, MANAGEMENT_FEE, FACILITY, COMPLAINT, ACCOUNTING)", // 보고서 분류
    "requiredParams": ["string"], // 필수 요청 파라미터 목록
    "optionalParams": ["string"]  // 선택적 요청 파라미터 목록
}
```

### 5.2. `OccupancyStatusReportDto` (임대 현황 보고서)

JSON

```
{
    "reportTitle": "string",
    "generatedAt": "string (ISO DateTime)",
    "filterCriteria": { // 적용된 필터 조건 명시
        "asOfDate": "string (YYYY-MM-DD)",
        "buildingName": "string (nullable)"
        // ... 기타 적용된 필터
    },
    "summary": {
        "totalUnits": "integer",
        "occupiedUnits": "integer",
        "vacantUnits": "integer",
        "occupancyRate": "number" // %
    },
    "details": [ // array of OccupancyDetailItemDto
        {
            "buildingName": "string",
            "unitNumber": "string", // 예: "101동 101호"
            "area": "number", // ㎡
            "status": "string (Enum: LEASED, VACANT, UNDER_REPAIR)",
            "tenantName": "string (nullable, LEASED 경우)",
            "leaseStartDate": "string (YYYY-MM-DD, nullable)",
            "leaseEndDate": "string (YYYY-MM-DD, nullable)"
        }
    ]
    // pagination 정보 포함 가능
}
```

### 5.3. `FeeCollectionReportDto` (관리비 수납 현황 보고서)

JSON

```
{
    "reportTitle": "string",
    "billingYearMonth": "string (YYYY-MM)",
    "generatedAt": "string (ISO DateTime)",
    "filterCriteria": { /* ... */ },
    "summary": {
        "totalBilledAmount": "number",  // 총 부과액
        "totalCollectedAmount": "number", // 총 수납액
        "totalUnpaidAmount": "number", // 총 미납액
        "collectionRate": "number" // %
    },
    "details": [ // array of FeeCollectionDetailItemDto
        {
            "buildingName": "string",
            "unitNumber": "string",
            "tenantName": "string",
            "billedAmount": "number", // 해당 세대 부과액
            "paidAmount": "number",   // 해당 세대 납부액
            "unpaidAmount": "number", // 해당 세대 미납액
            "paymentStatus": "string (Enum: FULLY_PAID, PARTIALLY_PAID, UNPAID, OVERDUE)",
            "lastPaymentDate": "string (YYYY-MM-DD, nullable)"
        }
    ]
    // pagination 정보 포함 가능
}
```

*(기타 보고서 DTO들도 각 보고서의 내용에 맞게 상세히 정의)*

------

