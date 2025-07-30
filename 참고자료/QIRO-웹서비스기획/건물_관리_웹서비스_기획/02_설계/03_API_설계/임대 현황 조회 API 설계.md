
# 📊 QIRO 임대 현황 조회 API 설계

## 1. 문서 정보
- **문서명:** QIRO 임대 현황 조회 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-LSSTAT-001 - QIRO - 임대 현황 조회 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 임대 현황 조회 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API는 건물별/전체 임대율, 총 임대 수입(월 기준), 계약 만료 예정 건수 등 주요 KPI와 함께 세대별 상세 임대 상태 목록을 제공한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):**
    - 데이터 조회: 기본 `application/json`, `UTF-8`.
    - 파일 내보내기: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` (Excel), `text/csv` 등. (API 설계 가이드라인의 "보고서 형식 지정" 참조)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)
- **페이지네이션:** 목록 형태의 상세 데이터 반환 시 공통 페이지네이션 DTO 사용 (`PagedResponse<T>`).

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 임대 현황 KPI 요약 조회

- **HTTP Method:** `GET`
- **URI:** `/leasing-status/summary`
- **설명:** 선택된 범위(전체 또는 특정 건물)의 주요 임대 현황 KPI(임대율, 월 임대료 총액, 계약 만료 예정 건수)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Query Parameters:**

  | 파라미터명                  | 타입    | 필수 | 설명                                                              | 예시                    |
  | :-------------------------- | :------ | :--- | :---------------------------------------------------------------- | :---------------------- |
  | `buildingId`              | String  | N    | 특정 건물 ID (미지정 시 사용자 권한 내 전체 건물 대상)            | `building-uuid-001`     |
  | `asOfDate`                  | String  | N    | 조회 기준일 (YYYY-MM-DD, 미지정 시 오늘 날짜)                     | `2025-06-30`            |
  | `expiringSoonThresholdDays` | Integer | N    | '계약 만료 예정' 판단 기준일 (예: 90일 이내, 미지정 시 기본값 90일) | `60`                      |

- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `LeasingSummaryResponseDto`
      ```json
      {
          "asOfDate": "2025-06-30",
          "occupancyRate": 85.0, // 임대율 (%)
          "totalManagedUnits": 20, // 관리 대상 총 세대 수
          "occupiedUnits": 17, // 임대중 세대 수
          "vacantUnits": 3, // 공실 세대 수
          "totalMonthlyRentActive": 21000000, // 현재 '계약중'인 계약의 월 임대료 총액 (이미지 내용 기반)
          "contractsExpiringSoonCount": 2 // 설정된 임계일 이내 만료 예정 계약 건수
      }
      ```
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

---
### 4.2. 임대 현황 상세 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/leasing-status/units`
- **설명:** 지정된 조건에 따른 세대별 임대 현황 상세 목록을 조회한다. (테이블 목록 표시용)
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자
- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                            | 예시                             |
  | :------------------- | :------ | :--- | :---------------------------------------------- | :------------------------------- |
  | `buildingId`         | String  | N    | 특정 건물 ID 필터링                             | `building-uuid-001`              |
  | `unitStatus`         | String  | N    | 세대 임대 상태 필터링 (`LEASED`, `VACANT`, `EXPIRING_SOON` 등 Enum) | `VACANT`                         |
  | `contractStatus`     | String  | N    | (연결된) 계약 상태 필터링 (`ACTIVE`, `EXPIRED` 등 Enum) | `ACTIVE`                         |
  | `keyword`            | String  | N    | 세대번호, 임차인명 등 키워드 검색 (부분 일치)     | `101호` 또는 `홍길동`            |
  | `expiryDateFrom`     | String  | N    | 계약 만료일 검색 시작일 (YYYY-MM-DD)            | `2025-07-01`                     |
  | `expiryDateTo`       | String  | N    | 계약 만료일 검색 종료일 (YYYY-MM-DD)            | `2025-09-30`                     |
  | `page`, `size`, `sortBy` (`unitNumber`, `tenantName`, `contractEndDate`, `monthlyRent`, `status`), `sortDirection` (공통 파라미터) |         | N    |                                                 | `contractEndDate` ASC            |
  | `format`             | String  | N    | 출력 형식 (`json`, `xlsx`, `csv` - 내보내기용)  | `xlsx`                           |

- **Success Response (JSON `format=json` 또는 `Accept: application/json`):**
    - **Code:** `200 OK`
    - **Body:** `PagedResponse<UnitLeasingStatusDto>`
- **Success Response (File `format=xlsx` 등 또는 해당 `Accept` 헤더):**
    - **Code:** `200 OK`
    - **Headers:** `Content-Type`, `Content-Disposition`
    - **Body:** (파일 바이너리)
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`.

---
### 4.3. (선택) 임대 현황 데이터 일괄 업로드/가져오기

- **HTTP Method:** `POST`
- **URI:** `/leasing-status/units/batch-upload`
- **설명:** (기능이 필요한 경우) Excel 또는 CSV 파일을 통해 임대 현황 관련 데이터를 일괄적으로 업데이트하거나 시스템으로 가져온다. (예: 초기 데이터 마이그레이션, 특정 정보 일괄 변경). 이 API의 구체적인 동작(어떤 데이터를 어떻게 업데이트할지)은 상세 정책에 따라 달라진다.
- **요청 권한:** 총괄관리자
- **Request Body:** `multipart/form-data`
    - `file`: (업로드할 Excel 또는 CSV 파일)
    - `importOptions` (String/JSON, 선택): 업로드 방식에 대한 옵션 (예: `{"updateMode": "OVERWRITE_ALL"}`)
- **Success Response:**
    - **Code:** `202 Accepted` (비동기 처리 시) 또는 `200 OK` (동기 처리 및 결과 요약 포함 시)
    - **Body (예시):**
      ```json
      {
          "jobId": "batch-ls-upload-uuid-001", // 비동기 처리 시
          "message": "임대 현황 데이터 일괄 업로드 요청이 접수되었습니다. 처리 완료 후 알림 예정입니다.",
          "summary": { // 동기 처리 시 또는 완료 후 조회 가능
              "totalRows": 100,
              "successCount": 98,
              "failureCount": 2,
              "errorDetailsUrl": "/v1/batch-jobs/ls-upload-uuid-001/errors" // 실패 상세 조회 URL
          }
      }
      ```
- **Error Responses:** `400 Bad Request` (파일 형식/내용 오류, 잘못된 옵션), `401 Unauthorized`, `403 Forbidden`.

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `LeasingSummaryResponseDto` (KPI 요약 정보)
```json
{
    "asOfDate": "string (YYYY-MM-DD)", // 조회 기준일
    "occupancyRate": "number", // 임대율 (%)
    "totalManagedUnits": "integer", // 관리 대상 총 세대 수
    "occupiedUnits": "integer", // 임대중 세대 수
    "vacantUnits": "integer", // 공실 세대 수
    "totalMonthlyRentActive": "number", // 현재 '계약중'인 계약의 월 임대료 총액
    "contractsExpiringSoonCount": "integer" // 계약 만료 예정 건수
}
```

### 5.2. `UnitLeasingStatusDto` (임대 현황 목록 내 개별 항목)

JSON

```
{
    "unitId": "string",
    "buildingId": "string",
    "buildingName": "string", // 편의 정보
    "unitNumberDisplay": "string", // 예: "101동 1001호" 또는 이미지의 "@ 1001"
    "floor": "string", // 예: "10F"
    "areaSquareMeter": "number", // 면적 (㎡)
    "status": "string (Enum: LEASED, VACANT, UNDER_REPAIR, UNAVAILABLE)", // 호실의 현재 임대 관련 상태
    "statusDisplay": "string", // 예: "임대중", "공실"
    "tenantName": "string (nullable)", // 임대중일 경우 임차인명
    "monthlyRent": "number (nullable)", // 임대중일 경우 월 임대료
    "contractId": "string (nullable)", // 연결된 현재 유효 계약 ID
    "contractStartDate": "string (YYYY-MM-DD, nullable)",
    "contractEndDate": "string (YYYY-MM-DD, nullable)",
    "remainingLeaseDays": "integer (nullable)" // 계약 만료까지 남은 일수 (음수일 경우 만료 지남)
}
```

### 5.3. `AvailableReportDto` (사용 가능한 보고서 목록 조회 응답 내 항목)

JSON

```
{
    "reportId": "string",
    "reportName": "string",
    "description": "string",
    "category": "string (Enum)",
    "requiredParams": ["string"],
    "optionalParams": ["string"]
}
```

*(PagedResponse<Dto>는 목록 조회 시 공통적으로 사용)*

------

