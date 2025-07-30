
# 🏢 QIRO 건물 정보 상세 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 건물 정보 상세 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-BLDGMGMT-001 - QIRO - 건물 정보 상세 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 건물, (해당 시) 동, 호실(세대), 그리고 건물 공용 시설 정보 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 건물 (Building) 관리 API

#### 4.1.1. 신규 건물 등록
- **HTTP Method:** `POST`
- **URI:** `/buildings`
- **설명:** 새로운 건물 정보를 시스템에 등록한다.
- **요청 권한:** 총괄관리자 (또는 상위 관리자 역할)
- **Request Body:** `BuildingCreateRequestDto`
  ```json
  {
      "buildingName": "QIRO 프리미엄 타워",
      "address": {
          "zipCode": "06123",
          "streetAddress": "서울특별시 강남구 테헤란로 123",
          "detailAddress": "45층"
      },
      "buildingTypeCode": "OFFICETEL", // 예: APT, OFFICETEL, COMMERCIAL, MIXED_USE
      "totalDongCount": 1, // 단일 동 건물일 경우 1 또는 null/0 (정책)
      "totalUnitCount": 250,
      "totalFloorArea": 35000.50, // 제곱미터(㎡)
      "completionDate": "2023-10-15",
      "managementStartDate": "2023-11-01",
      "status": "ACTIVE", // ACTIVE, INACTIVE, PREPARING
      "mainImageKey": "s3://bucket/path/to/image.jpg" // 선택 사항
  }
  ```

- Success Response:
  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/buildings/{buildingId}`
  - **Body:** `BuildingResponseDto` (생성된 건물 정보)
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `409 Conflict` (예: 동일 주소/건물명 중복 시)

#### 4.1.2. 건물 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/buildings`
- **설명:** 등록된 건물 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)
- **요청 권한:** 총괄관리자, 관리소장 등
- **Query Parameters:**

 | 파라미터명        | 타입    | 필수 | 설명                                     | 예시         |
 | :---------------- | :------ | :--- | :--------------------------------------- | :----------- |
 | `buildingName`    | String  | N    | 건물명 검색 (부분 일치)                  | `QIRO`       |
 | `addressKeyword`  | String  | N    | 주소 키워드 검색                         | `강남대로`   |
 | `buildingTypeCode`| String  | N    | 건물 유형 코드로 필터링                  | `OFFICETEL`  |
 | `status`          | String  | N    | 상태로 필터링 (`ACTIVE`, `INACTIVE` 등) | `ACTIVE`     |
 | `page`            | Integer | N    | 페이지 번호 (기본값 0)                   | `0`          |
 | `size`            | Integer | N    | 페이지 당 항목 수 (기본값 20)            | `10`         |
 | `sortBy`          | String  | N    | 정렬 기준 필드 (예: `buildingName`)      | `createdAt`  |
 | `sortDirection`   | String  | N    | 정렬 방향 (`ASC`, `DESC`)                | `DESC`       |

- Success Response:
  - **Code:** `200 OK`
  - **Body:** `PagedResponse<BuildingSummaryDto>`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`

#### 4.1.3. 특정 건물 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/buildings/{buildingId}`
- **설명:** 지정된 ID의 건물 상세 정보를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장 등
- **Path Parameters:** `buildingId` (건물 고유 ID)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `BuildingResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`

#### 4.1.4. 건물 정보 전체 수정

- **HTTP Method:** `PUT`
- **URI:** `/buildings/{buildingId}`
- **설명:** 지정된 ID의 건물 정보 전체를 수정한다.
- **요청 권한:** 총괄관리자 (또는 해당 건물 관리 권한자)
- **Path Parameters:** `buildingId`
- **Request Body:** `BuildingUpdateRequestDto` (4.1.1의 `BuildingCreateRequestDto`와 유사한 구조)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `BuildingResponseDto` (수정된 건물 정보)
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`

#### 4.1.5. 건물 정보 부분 수정

- **HTTP Method:** `PATCH`
- **URI:** `/buildings/{buildingId}`
- **설명:** 지정된 ID의 건물 정보 중 일부를 수정한다 (예: 상태 변경, 관리 시작일 변경).
- **요청 권한:** 총괄관리자 (또는 해당 건물 관리 권한자)
- **Path Parameters:** `buildingId`
- **Request Body:** `BuildingPartialUpdateRequestDto` (수정할 필드만 포함)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `BuildingResponseDto` (수정된 건물 정보)
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`

#### 4.1.6. 건물 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/buildings/{buildingId}`
- **설명:** 지정된 ID의 건물을 삭제한다. (연결된 호실, 계약 등이 있을 경우 논리적 삭제 또는 비활성화 처리)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `buildingId`
- **Success Response:** `204 No Content` 또는 `200 OK` (논리적 삭제 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건)

------

### 4.2. 동 (Building Dong) 관리 API (건물 유형에 따라 선택적)

*(건물이 여러 동으로 구성된 경우 사용. 단일 동 건물은 이 API 세트 불필요 또는 buildingId로만 관리)*

#### 4.2.1. 특정 건물 내 신규 동 등록

- **HTTP Method:** `POST`
- **URI:** `/buildings/{buildingId}/dongs`
- **설명:** 특정 건물 내에 새로운 동 정보를 등록한다.
- **요청 권한:** 총괄관리자, 해당 건물 관리소장
- **Path Parameters:** `buildingId`
- **Request Body:** `DongCreateRequestDto` (`dongName`, `numberOfFloors` 등)
- **Success Response:** `201 Created`, `Location` 헤더, `DongResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (buildingId)

#### 4.2.2. 특정 건물 내 동 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/buildings/{buildingId}/dongs`
- **요청 권한:** 총괄관리자, 해당 건물 관리소장 등
- **Path Parameters:** `buildingId`
- **Success Response:** `200 OK`, `List<DongResponseDto>`
- **Error Responses:** `401 Unauthorized`, `404 Not Found` (buildingId)

*(PUT, PATCH, DELETE 엔드포인트는 유사하게 정의 가능)*

------

### 4.3. 호실/세대 (Unit) 관리 API

#### 4.3.1. 특정 건물(또는 동) 내 신규 호실 등록

- **HTTP Method:** `POST`

- **URI:** `/buildings/{buildingId}/units` (동이 있다면 `/buildings/{buildingId}/dongs/{dongId}/units` 또는 요청 바디에 `dongId` 포함)

- **설명:** 특정 건물(및 동) 내에 새로운 호실 정보를 등록한다.

- **요청 권한:** 총괄관리자, 해당 건물 관리소장

- **Path Parameters:** `buildingId` (필요시 `dongId`)

- Request Body:

```
  UnitCreateRequestDto
```

  JSON

  ```
  {
      "dongId": "dong-uuid-string-optional", // 동이 있는 건물일 경우 필수
      "unitNumber": "101호",
      "floor": 10,
      "unitTypeCode": "RES_APT_84", // 주거용-아파트-84타입 등
      "exclusiveArea": 84.98, // ㎡
      "contractArea": 112.50, // ㎡
      "currentStatus": "VACANT", // VACANT, LEASED, UNDER_REPAIR 등
      "lessorId": "lessor-uuid-string-optional" // 선택적 직접 연결
  }
  ```

- **Success Response:** `201 Created`, `Location` 헤더, `UnitResponseDto`

- **Error Responses:** `400 Bad Request` (예: 동일 건물/동 내 호실번호 중복), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (buildingId/dongId)

#### 4.3.2. 특정 건물(또는 동) 내 호실 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/buildings/{buildingId}/units`
- **요청 권한:** 총괄관리자, 해당 건물 관리소장 등
- **Path Parameters:** `buildingId`
- **Query Parameters:** | 파라미터명   | 타입    | 필수 | 설명                      | 예시        | | :----------- | :------ | :--- | :------------------------ | :---------- | | `dongId`     | String  | N    | 특정 동의 호실만 필터링   | `dong-uuid` | | `floor`      | Integer | N    | 특정 층의 호실만 필터링   | `10`        | | `unitNumber` | String  | N    | 호실번호 검색 (부분 일치) | `101`       | | `status`     | String  | N    | 현재 상태로 필터링        | `VACANT`    | | `page`, `size`, `sortBy`, `sortDirection` (공통 페이지네이션/정렬 파라미터) | | | | |
- **Success Response:** `200 OK`, `PagedResponse<UnitSummaryDto>`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `404 Not Found` (buildingId)

#### 4.3.3. 특정 호실 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/units/{unitId}` (또는 `/buildings/{buildingId}/units/{unitId}` - 후자가 더 RESTful)
- **설명:** 지정된 ID의 호실 상세 정보를 조회한다. (경로 일관성을 위해 `/buildings/{buildingId}/units/{unitId}` 사용 권장)
- **요청 권한:** 총괄관리자, 해당 건물 관리소장 등
- **Path Parameters:** `buildingId`, `unitId`
- **Success Response:** `200 OK`, `UnitResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`

*(PUT, PATCH, DELETE 엔드포인트는 유사하게 정의 가능. 호실 상태는 임대 계약에 의해 주로 변경됨)*

#### 4.3.4. (선택) 호실 정보 일괄 등록/수정 (Excel 업로드)

- **HTTP Method:** `POST`
- **URI:** `/buildings/{buildingId}/units/batch-upload`
- **설명:** Excel 파일을 통해 다수의 호실 정보를 일괄 등록하거나 수정한다.
- **요청 권한:** 총괄관리자, 해당 건물 관리소장
- **Request Body:** `multipart/form-data` (Excel 파일)
- **Success Response:** `202 Accepted` (비동기 처리 시) 또는 `200 OK` (처리 결과 요약 포함)
- **Error Responses:** `400 Bad Request` (파일 형식 오류, 데이터 유효성 오류 등)

------

### 4.4. 건물 공용 시설 관리 API

#### 4.4.1. 특정 건물 내 공용 시설 등록

- **HTTP Method:** `POST`
- **URI:** `/buildings/{buildingId}/common-facilities`
- **설명:** 특정 건물에 공용 시설 정보를 등록한다.
- **요청 권한:** 총괄관리자, 해당 건물 관리소장
- **Path Parameters:** `buildingId`
- **Request Body:** `CommonFacilityCreateRequestDto` (`facilityName`, `location`, `description` 등)
- **Success Response:** `201 Created`, `Location` 헤더, `CommonFacilityResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (buildingId)

*(GET (목록/상세), PUT, PATCH, DELETE 엔드포인트는 유사하게 정의 가능)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `BuildingResponseDto`

JSON

  ```
{
    "buildingId": "string (UUID or Long)",
    "buildingName": "string",
    "address": {
        "zipCode": "string",
        "streetAddress": "string",
        "detailAddress": "string (nullable)"
    },
    "buildingTypeCode": "string",
    "buildingTypeName": "string", // 코드에 대한 명칭
    "totalDongCount": "integer (nullable)",
    "totalUnitCount": "integer",
    "totalFloorArea": "number (BigDecimal/Double, nullable)",
    "completionDate": "string (YYYY-MM-DD, nullable)",
    "managementStartDate": "string (YYYY-MM-DD)",
    "status": "string (Enum: ACTIVE, INACTIVE, PREPARING)",
    "statusName": "string", // 코드에 대한 명칭
    "mainImageKey": "string (nullable)",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `UnitResponseDto`

JSON

  ```
{
    "unitId": "string (UUID or Long)",
    "buildingId": "string",
    "buildingName": "string", // 편의를 위한 추가 정보
    "dongId": "string (nullable)",
    "dongName": "string (nullable)",
    "unitNumber": "string", // 예: "101", "B203"
    "floor": "integer",
    "unitTypeCode": "string",
    "unitTypeName": "string",
    "exclusiveArea": "number (BigDecimal/Double)", // 전용 면적
    "contractArea": "number (BigDecimal/Double, nullable)", // 계약 면적
    "currentStatus": "string (Enum: VACANT, LEASED, UNDER_REPAIR, NOT_FOR_LEASE)",
    "currentStatusName": "string",
    "lessorId": "string (nullable)", // 임대인 ID
    "lessorName": "string (nullable)", // 임대인명
    "tenantId": "string (nullable)", // 현재 임차인 ID (임대중일 경우)
    "tenantName": "string (nullable)", // 현재 임차인명
    "leaseContractId": "string (nullable)", // 현재 유효 계약 ID
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

(Create/Update Request DTO들은 위 Response DTO에서 ID 및 감사 필드 제외, 필요한 필드 추가/조정)

(Dong, CommonFacility DTO들도 유사하게 정의)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)