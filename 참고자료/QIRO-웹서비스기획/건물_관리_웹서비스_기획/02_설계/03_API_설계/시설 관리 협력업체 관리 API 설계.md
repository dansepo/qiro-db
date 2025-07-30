
# 🔩 QIRO 시설 관리 협력업체 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 시설 관리 협력업체 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-VENDMGMT-001 - QIRO - 시설 관리 협력업체 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 시설 관리 협력업체 정보, 업체별 담당자 정보, 그리고 업체와의 계약 정보 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 업로드 시 `multipart/form-data`)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 시설 관리 협력업체 (Facility Vendors) API (`/facility-vendors`)

#### 4.1.1. 신규 협력업체 등록
- **HTTP Method:** `POST`
- **URI:** `/facility-vendors`
- **설명:** 새로운 시설 관리 협력업체 정보를 시스템에 등록한다. 초기 담당자 및 계약 정보도 함께 등록 가능.
- **요청 권한:** 총괄관리자, 관리소장, 시설 담당 관리자
- **Request Body:** `FacilityVendorCreateRequestDto`
  ```json
  {
      "companyName": "QIRO 클린 주식회사",
      "businessRegistrationNumber": "123-81-00001",
      "ceoName": "청소해",
      "address": {
          "zipCode": "06125",
          "streetAddress": "서울특별시 강남구 봉은사로 111",
          "detailAddress": "5층"
      },
      "primaryPhone": "02-555-1234",
      "primaryEmail": "contact@qiroclean.com",
      "status": "ACTIVE", // ACTIVE, INACTIVE, CONTRACT_EXPIRED 등 Enum
      "serviceTypeCodes": ["CLEANING", "LANDSCAPING"], // 전문 분야/서비스 유형 코드 목록 (사전 정의된 마스터 데이터)
      "remarks": "정기 건물 청소 및 조경 관리 전문",
      "contactPersons": [ // 선택 사항: 초기 담당자 정보
          {
              "name": "김담당",
              "position": "영업팀장",
              "phone": "010-1212-3434",
              "email": "kim@qiroclean.com"
          }
      ],
      "contracts": [ // 선택 사항: 초기 계약 정보
          {
              "contractName": "2025년 연간 청소 용역 계약",
              "startDate": "2025-01-01",
              "endDate": "2025-12-31",
              "termsSummary": "월 2회 전체 구역 청소, 월 1회 특별 방역",
              "contractFile": { // 계약서 파일 정보 (업로드 후 키 또는 URL)
                  "fileName": "qiro_clean_contract_2025.pdf",
                  "fileKey": "s3-key-for-contract.pdf"
              }
          }
      ]
  }
  ```

- **Success Response**:
  
  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/facility-vendors/{vendorId}`
  - **Body:** `FacilityVendorResponseDto` (생성된 업체 정보)
- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류, 사업자번호 중복 등), `401 Unauthorized`, `403 Forbidden`.

#### 4.1.2. 협력업체 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/facility-vendors`

- **설명:** 등록된 시설 관리 협력업체 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 시설 담당 관리자 등

- **Query Parameters:**

  | 파라미터명        | 타입    | 필수 | 설명                                  | 예시           |
  | :---------------- | :------ | :--- | :------------------------------------ | :------------- |
  | companyName     | String  | N    | 업체명 검색 (부분 일치)               | 클린         |
  | serviceTypeCode | String  | N    | 전문 분야/서비스 유형 코드로 필터링   | CLEANING     |
  | status          | String  | N    | 상태로 필터링 (ACTIVE, INACTIVE 등) | ACTIVE       |
  | page, size, sortBy (companyName, status), sortDirection (공통 파라미터) |         | N    |                                       | companyName ASC |

- **Success Response:** `200 OK`, `PagedResponse<FacilityVendorSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 협력업체 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/facility-vendors/{vendorId}`
- **설명:** 지정된 ID의 협력업체 상세 정보(담당자, 계약 목록 포함)를 조회한다.
- **요청 권한:** (4.1.2와 유사)
- **Path Parameters:** `vendorId` (협력업체 고유 ID)
- **Success Response:** `200 OK`, `FacilityVendorDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

#### 4.1.4. 협력업체 정보 전체 수정

- **HTTP Method:** `PUT`
- **URI:** `/facility-vendors/{vendorId}`
- **설명:** 지정된 ID의 협력업체 기본 정보를 전체 수정한다. (담당자, 계약은 별도 하위 리소스 API로 관리 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `vendorId`
- **Request Body:** `FacilityVendorUpdateRequestDto` (4.1.1의 Create DTO와 유사하나, 담당자/계약은 제외하고 업체 자체 정보만)
- **Success Response:** `200 OK`, `FacilityVendorResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.

#### 4.1.5. 협력업체 정보 부분 수정

- **HTTP Method:** `PATCH`
- **URI:** `/facility-vendors/{vendorId}`
- **설명:** 지정된 ID의 협력업체 정보 중 일부(예: 상태, 연락처, 전문 분야)를 수정한다.
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `vendorId`
- **Request Body:** `FacilityVendorPartialUpdateRequestDto` (수정할 필드만 포함)
- **Success Response:** `200 OK`, `FacilityVendorResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 협력업체 삭제 (또는 비활성화)

- **HTTP Method:** `DELETE`
- **URI:** `/facility-vendors/{vendorId}`
- **설명:** 지정된 ID의 협력업체 정보를 삭제한다. (진행 중인 작업 오더 또는 유효한 계약이 있을 경우 논리적 삭제 또는 비활성화)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `vendorId`
- **Success Response:** `204 No Content` 또는 `200 OK` (상태 변경 시)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 협력업체 담당자 (Vendor Contact Persons) 관리 API (`/facility-vendors/{vendorId}/contact-persons`)

#### 4.2.1. 특정 협력업체에 담당자 추가

- **HTTP Method:** `POST`
- **URI:** `/facility-vendors/{vendorId}/contact-persons`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `vendorId`
- **Request Body:** `VendorContactPersonCreateRequestDto`
- **Success Response:** `201 Created`, `Location` 헤더, `VendorContactPersonResponseDto`

#### 4.2.2. 특정 협력업체의 담당자 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/facility-vendors/{vendorId}/contact-persons`
- **Success Response:** `200 OK`, `List<VendorContactPersonResponseDto>`

#### 4.2.3. 특정 협력업체 담당자 정보 수정

- **HTTP Method:** `PUT`
- **URI:** `/facility-vendors/{vendorId}/contact-persons/{contactPersonId}`
- **Request Body:** `VendorContactPersonUpdateRequestDto`
- **Success Response:** `200 OK`, `VendorContactPersonResponseDto`

#### 4.2.4. 특정 협력업체 담당자 정보 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/facility-vendors/{vendorId}/contact-persons/{contactPersonId}`
- **Success Response:** `204 No Content`

------

### 4.3. 협력업체 계약 (Vendor Contracts) 관리 API (`/facility-vendors/{vendorId}/contracts`)

#### 4.3.1. 특정 협력업체에 계약 정보 추가

- **HTTP Method:** `POST`
- **URI:** `/facility-vendors/{vendorId}/contracts`
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `vendorId`
- **Request Body:** `VendorContractCreateRequestDto` (계약명, 기간, 조건 요약, 파일 첨부 정보 포함)
- **Success Response:** `201 Created`, `Location` 헤더, `VendorContractResponseDto`

#### 4.3.2. 특정 협력업체의 계약 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/facility-vendors/{vendorId}/contracts`
- **Success Response:** `200 OK`, `List<VendorContractResponseDto>`

#### 4.3.3. 특정 협력업체 계약 정보 수정

- **HTTP Method:** `PUT`
- **URI:** `/facility-vendors/{vendorId}/contracts/{contractId}`
- **Request Body:** `VendorContractUpdateRequestDto`
- **Success Response:** `200 OK`, `VendorContractResponseDto`

#### 4.3.4. 특정 협력업체 계약 정보 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/facility-vendors/{vendorId}/contracts/{contractId}`
- **Success Response:** `204 No Content`

*(계약서 파일 업로드 자체는 별도의 파일 업로드 API를 사용하고, 여기서는 파일 참조 키(S3 key 등)를 관리하는 방식이 일반적입니다.)*

------

### 4.4. 전문 분야/서비스 유형 (Service Types) 마스터 API (`/facility-service-types`) - 선택적

*(만약 서비스 유형이 관리자에 의해 동적으로 추가/관리되어야 한다면 필요. 시스템 고정값이라면 불필요)*

#### 4.4.1. 서비스 유형 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/facility-service-types`
- **설명:** 시설 관리 협력업체가 제공할 수 있는 전문 분야/서비스 유형의 마스터 목록을 조회한다.
- **요청 권한:** 인증된 모든 내부 사용자
- **Success Response:** `200 OK`, `List<ServiceTypeResponseDto>` *(POST, PUT, DELETE는 최상위 관리자 전용으로 별도 정의 가능)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `FacilityVendorResponseDto` / `FacilityVendorSummaryDto` / `FacilityVendorDetailResponseDto`

JSON

```
// FacilityVendorSummaryDto (목록용)
{
    "vendorId": "string",
    "companyName": "string",
    "primaryPhone": "string (nullable)",
    "primaryContactPersonName": "string (nullable)", // 주 담당자명
    "serviceTypeNames": ["청소", "보안"], // 주요 전문 분야 요약
    "status": "string (Enum)" // ACTIVE, INACTIVE 등
}

// FacilityVendorDetailResponseDto (상세용)
{
    "vendorId": "string",
    "companyName": "string",
    "businessRegistrationNumber": "string (nullable)",
    "ceoName": "string (nullable)",
    "address": { /* AddressDto */ },
    "primaryPhone": "string (nullable)",
    "primaryEmail": "string (nullable)",
    "status": "string (Enum)",
    "serviceTypeCodes": ["string (Enum)"], // 예: ["CLEANING", "SECURITY"]
    "serviceTypeNames": ["string"], // 예: ["청소용역", "경비보안"]
    "remarks": "string (nullable)",
    "contactPersons": [ /* array of VendorContactPersonResponseDto */ ],
    "contracts": [ /* array of VendorContractResponseDto */ ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
```

### 5.2. `VendorContactPersonResponseDto`

JSON

```
{
    "contactPersonId": "string",
    "name": "string",
    "position": "string (nullable)",
    "phone": "string",
    "email": "string (nullable)"
}
```

### 5.3. `VendorContractResponseDto`

JSON

```
{
    "vendorContractId": "string",
    "contractName": "string (nullable)",
    "startDate": "string (YYYY-MM-DD)",
    "endDate": "string (YYYY-MM-DD)",
    "termsSummary": "string (nullable)",
    "contractFile": { // AttachmentDto
        "fileName": "string",
        "fileUrl": "string", // 다운로드 URL
        "uploadedAt": "string (ISO DateTime)"
    },
    "isActiveContract": "boolean"
}
```

### 5.4. `ServiceTypeResponseDto` (전문 분야 마스터용)

JSON

```
{
    "serviceTypeCode": "string", // 예: CLEANING
    "serviceTypeName": "string"  // 예: 청소 용역
}
```

(Create/Update Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

