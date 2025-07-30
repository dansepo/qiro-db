
# 🛠️ QIRO 시설 점검 및 유지보수 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 시설 점검 및 유지보수 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-FMMGMT-001 - QIRO - 시설 점검 및 유지보수 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 시설물 정보 등록/관리 및 시설물 점검 이력 등록/관리, 다음 점검일 관리 등을 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 업로드 시 `multipart/form-data`)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601` (`YYYY-MM-DDTHH:mm:ss.sssZ` 또는 `YYYY-MM-DD`).
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 시설물 (Facilities) 관리 API

#### 4.1.1. 신규 시설물 등록
- **HTTP Method:** `POST`
- **URI:** `/facilities`
- **설명:** 새로운 시설물 정보를 시스템에 등록한다. 시설물의 기본 정보 및 초기 점검 관련 정보를 포함한다.
- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자
- **Request Body:** `FacilityCreateRequestDto`
  ```json
  {
      "buildingId": "building-uuid-001", // 시설물이 속한 건물 ID
      "name": "엘리베이터 1호기",
      "facilityTypeCode": "ELEVATOR", // 예: ELEVATOR, FIRE_ALARM, HVAC, PUMP
      "location": "1층 주출입구 옆",
      "installationDate": "2020-05-15", // 선택 사항
      "manufacturer": "현대엘리베이터", // 선택 사항
      "modelName": "HD-2000X", // 선택 사항
      "inspectionCycleDays": 90, // 점검 주기 (일 단위)
      "initialLastInspectionDate": "2025-02-15", // 선택 사항: 초기 최근 점검일
      "initialNextInspectionDate": "2025-05-16", // 선택 사항: 초기 다음 점검일 (미입력 시 lastInspectionDate + cycle로 계산 가능)
      "initialStatus": "NORMAL", // 초기 상태 (Enum: NORMAL, INSPECTION_NEEDED 등)
      "remarks": "정기 점검 계약 업체: OOO엘리베이터" // 선택 사항
  }
  ```

- **Success Response**:
  
  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/facilities/{facilityId}`
  - **Body:** `FacilityResponseDto` (생성된 시설물 정보)
- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (buildingId).

#### 4.1.2. 시설물 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/facilities`

- **설명:** 등록된 시설물 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자, (제한된 정보) 협력업체

- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                    | 예시                |
  | :------------------- | :------ | :--- | :-------------------------------------- | :------------------ |
  | buildingId         | String  | N    | 특정 건물 내 시설물 필터링              | building-uuid     |
  | facilityTypeCode   | String  | N    | 시설물 유형 코드로 필터링               | ELEVATOR          |
  | status             | String  | N    | 상태로 필터링 (NORMAL, INSPECTION_NEEDED 등) | INSPECTION_NEEDED |
  | nameKeyword        | String  | N    | 시설물명 키워드 검색                    | 엘리베이터        |
  | nextInspectionDateFrom | String | N    | 다음 점검일 검색 시작 (YYYY-MM-DD)      | 2025-06-01        |
  | nextInspectionDateTo   | String | N    | 다음 점검일 검색 종료 (YYYY-MM-DD)      | 2025-06-30        |
  | page, size, sortBy (name, nextInspectionDate), sortDirection (공통 파라미터) |         | N    |                                         | nextInspectionDate ASC |

- **Success Response:** `200 OK`, `PagedResponse<FacilitySummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 시설물 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/facilities/{facilityId}`
- **설명:** 지정된 ID의 시설물 상세 정보(최근 점검 이력 요약 포함 가능)를 조회한다.
- **요청 권한:** (4.1.2와 유사)
- **Path Parameters:** `facilityId`
- **Success Response:** `200 OK`, `FacilityDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 시설물 정보 전체 수정

- **HTTP Method:** `PUT`
- **URI:** `/facilities/{facilityId}`
- **설명:** 지정된 ID의 시설물 정보를 전체 수정한다.
- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자
- **Path Parameters:** `facilityId`
- **Request Body:** `FacilityUpdateRequestDto` (4.1.1의 Create DTO와 유사)
- **Success Response:** `200 OK`, `FacilityResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.5. 시설물 정보 부분 수정 (다음 점검일, 상태 등)

- **HTTP Method:** `PATCH`

- **URI:** `/facilities/{facilityId}`

- **설명:** 지정된 ID의 시설물 정보 중 일부를 수정한다. (예: 상태, 다음 점검일, 비고)

- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자

- **Path Parameters:** `facilityId`

- Request Body:

```
  FacilityPartialUpdateRequestDto
```

  JSON

  ```
  {
      "nextInspectionDate": "2025-07-15",
      "status": "UNDER_REPAIR",
      "remarks": "부품 교체 예정"
  }
  ```

- **Success Response:** `200 OK`, `FacilityResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 시설물 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/facilities/{facilityId}`
- **설명:** 지정된 ID의 시설물을 삭제한다. (연결된 점검 이력이 많을 경우 논리적 삭제 또는 비활성화 처리 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `facilityId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 시설물 점검 이력 (Facility Inspection Records) 관리 API

#### 4.2.1. 특정 시설물에 대한 신규 점검 이력 등록

- **HTTP Method:** `POST`

- **URI:** `/facilities/{facilityId}/inspection-records`

- **설명:** 특정 시설물에 대한 새로운 점검 이력을 등록한다. 이 작업 후 해당 시설물의 `lastInspectionDate`, `nextInspectionDate`, `status`가 업데이트될 수 있다.

- **요청 권한:** 총괄관리자, 관리소장, 시설 담당자, 해당 작업 수행 협력업체

- **Path Parameters:** `facilityId`

- Request Body:

  ```
  InspectionRecordCreateRequestDto
  ```

  JSON

  ```
  {
      "inspectionDate": "2025-06-04",
      "inspectorName": "홍길동",
      "vendorName": "QIRO 안전점검", // 선택 사항
      "inspectionResultCode": "REPAIR_NEEDED", // PASS, FAIL_MINOR, REPAIR_NEEDED 등 Enum
      "details": "메인보드 소손 확인, 교체 필요.",
      "nextRecommendedInspectionDate": "2025-06-11", // 선택 사항: 수리 후 재점검일 등
      "attachments": [
          {"fileName": "inspection_photo1.jpg", "fileKey": "s3-key-photo1.jpg"}
      ] // 선택 사항
  }
  ```

- **Success Response:** `201 Created`, `Location` 헤더, `InspectionRecordResponseDto`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (facilityId).

#### 4.2.2. 특정 시설물의 점검 이력 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/facilities/{facilityId}/inspection-records`
- **설명:** 특정 시설물에 대한 모든 점검 이력 목록을 조회한다. (페이지네이션, 기간 필터링 지원)
- **요청 권한:** (4.1.2와 유사)
- **Path Parameters:** `facilityId`
- **Query Parameters:** `inspectionDateFrom`, `inspectionDateTo`, `resultCode`, `page`, `size`, `sortBy`, `sortDirection`.
- **Success Response:** `200 OK`, `PagedResponse<InspectionRecordSummaryDto>`

#### 4.2.3. 특정 점검 이력 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/inspection-records/{recordId}` (또는 `/facilities/{facilityId}/inspection-records/{recordId}`)
- **설명:** 지정된 ID의 점검 이력 상세 정보를 조회한다. (일관성을 위해 후자 경로 권장)
- **요청 권한:** (4.1.2와 유사)
- **Path Parameters:** (facilityId - 선택적), `recordId`
- **Success Response:** `200 OK`, `InspectionRecordResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.2.4. 점검 이력 수정 (제한적)

- **HTTP Method:** `PUT` (또는 `PATCH`)
- **URI:** `/inspection-records/{recordId}`
- **설명:** 이미 등록된 점검 이력의 일부 정보(예: 오타 수정, 첨부파일 추가)를 수정한다. (점검 결과, 점검일 등 주요 정보 수정은 엄격히 통제되거나 재점검으로 처리 권장)
- **요청 권한:** 총괄관리자, 관리소장, 해당 점검 기록자
- **Path Parameters:** `recordId`
- **Request Body:** `InspectionRecordUpdateRequestDto` (수정 가능한 필드만)
- **Success Response:** `200 OK`, `InspectionRecordResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.2.5. 점검 이력 삭제 (매우 제한적)

- **HTTP Method:** `DELETE`
- **URI:** `/inspection-records/{recordId}`
- **설명:** 점검 이력을 삭제한다. (데이터 무결성을 위해 거의 허용되지 않으며, 필요시 '취소' 상태로 변경 또는 관리자만 가능)
- **요청 권한:** 최상위 관리자
- **Path Parameters:** `recordId`
- **Success Response:** `204 No Content`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.

*(첨부파일 관련 API는 `/inspection-records/{recordId}/attachments` 와 같이 별도 정의 가능하며, 이전 민원/계약 첨부파일 API와 유사한 패턴을 따름)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `FacilityResponseDto` / `FacilitySummaryDto` / `FacilityDetailResponseDto`

JSON

  ```
// FacilitySummaryDto (목록용)
{
    "facilityId": "string",
    "buildingName": "string", // 소속 건물명
    "name": "string", // 시설물명
    "facilityTypeName": "string", // 시설물 유형명
    "location": "string",
    "lastInspectionDate": "string (YYYY-MM-DD, nullable)",
    "nextInspectionDate": "string (YYYY-MM-DD, nullable)",
    "status": "string (Enum)", // NORMAL, INSPECTION_NEEDED 등
    "statusName": "string" // 상태 한글명
}

// FacilityDetailResponseDto (상세용)
{
    "facilityId": "string",
    "buildingId": "string",
    "buildingName": "string",
    "name": "string",
    "facilityTypeCode": "string",
    "facilityTypeName": "string",
    "location": "string",
    "installationDate": "string (YYYY-MM-DD, nullable)",
    "manufacturer": "string (nullable)",
    "modelName": "string (nullable)",
    "inspectionCycleDays": "integer (nullable)",
    "lastInspectionDate": "string (YYYY-MM-DD, nullable)",
    "nextInspectionDate": "string (YYYY-MM-DD, nullable)",
    "status": "string (Enum)",
    "statusName": "string",
    "remarks": "string (nullable)",
    "recentInspectionHistory": [ // 최근 몇 건의 InspectionRecordSummaryDto
        // ...
    ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `InspectionRecordResponseDto` / `InspectionRecordSummaryDto`

JSON

```
// InspectionRecordSummaryDto (시설물 상세 내 최근 이력 요약용)
{
    "inspectionRecordId": "string",
    "inspectionDate": "string (YYYY-MM-DD)",
    "inspectorName": "string",
    "vendorName": "string (nullable)",
    "inspectionResultName": "string", // 점검 결과 한글명
    "detailsSummary": "string" // 점검 내용 요약
}

// InspectionRecordResponseDto (점검 이력 상세용)
{
    "inspectionRecordId": "string",
    "facilityId": "string",
    "facilityName": "string", // 편의상 추가
    "inspectionDate": "string (YYYY-MM-DD)",
    "inspectorName": "string",
    "vendorName": "string (nullable)",
    "inspectionResultCode": "string (Enum)",
    "inspectionResultName": "string",
    "details": "string (nullable)",
    "nextRecommendedInspectionDate": "string (YYYY-MM-DD, nullable)",
    "attachments": [ /* AttachmentDto 목록 */ ],
    "createdAt": "string (ISO DateTime)",
    "createdBy": "string"
}
```

(Create/Update Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

