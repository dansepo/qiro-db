
# 📜 QIRO 임대 계약 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 임대 계약 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-LCMGMT-001 - QIRO - 임대 계약 관리 기능 명세서.md` (v1.1 기준)
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 임대 계약 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 임대 계약의 생성부터 종료(만료, 해지, 갱신)까지 전 과정을 관리하고, 계약 조건, 당사자 정보, 관련 문서 등을 체계적으로 기록 및 조회할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601` (`YYYY-MM-DDTHH:mm:ss.sssZ` 또는 `YYYY-MM-DD`).
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 임대 계약 (Lease Contracts) 관리 API (`/lease-contracts`)

#### 4.1.1. 신규 임대 계약 등록
- **HTTP Method:** `POST`
- **URI:** `/lease-contracts`
- **설명:** 새로운 임대 계약 정보를 시스템에 등록한다.
- **요청 권한:** 총괄관리자, 관리소장
- **Request Body:** `LeaseContractCreateRequestDto`
  ```json
  {
      "unitId": "unit-uuid-101",
      "lessorId": "lessor-uuid-001",
      "tenantId": "tenant-uuid-007",
      "contractNumber": "QIRO-LC-2025-001", // 선택 사항, 시스템 자동 채번 가능
      "contractDate": "2025-06-01",
      "startDate": "2025-07-01",
      "endDate": "2027-06-30",
      "depositAmount": 50000000,
      "rentAmount": 1200000,
      "rentPaymentCycle": "MONTHLY", // MONTHLY, QUARTERLY, YEARLY_PREPAID 등 Enum
      "rentPaymentDay": 25, // 매월 납부일 (1-31, 말일은 99 등으로 표현 가능)
      "maintenanceFeeCondition": "SEPARATE_BILLING", // INCLUDED_IN_RENT, SEPARATE_BILLING, FIXED_AMOUNT 등 Enum
      "maintenanceFeeAmount": 50000, // maintenanceFeeCondition이 FIXED_AMOUNT일 경우
      "specialClauses": "애완동물 금지. 월세 2기 이상 연체 시 계약 해지 가능.",
      "brokerInfo": "QIRO 공인중개사무소 (02-123-4567)", // 선택 사항
      "status": "SCHEDULED", // SCHEDULED, ACTIVE 등 초기 상태
      "attachments": [ // 선택 사항: 파일 업로드 후 받은 파일 키 목록
          {"fileName": "lease_contract_scan.pdf", "fileKey": "s3-key-contract.pdf"}
      ]
  }
  ```

- Success Response:
  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/lease-contracts/{contractId}`
  - **Body:** `LeaseContractResponseDto` (생성된 계약 정보)
- **Error Responses:** `400 Bad Request` (필수값 누락, 날짜 논리 오류, 호실 중복 계약 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (unitId, lessorId, tenantId 등 참조 ID 오류).

#### 4.1.2. 임대 계약 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/lease-contracts`

- **설명:** 등록된 임대 계약 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자 등

- **Query Parameters:**

  | 파라미터명           | 타입    | 필수 | 설명                                           | 예시                             |
  | :------------------- | :------ | :--- | :--------------------------------------------- | :------------------------------- |
  | buildingId         | String  | N    | 특정 건물 내 계약 필터링                       | building-uuid                  |
  | unitId             | String  | N    | 특정 호실 계약 필터링                          | unit-uuid                      |
  | lessorId           | String  | N    | 특정 임대인 계약 필터링                        | lessor-uuid                    |
  | tenantId           | String  | N    | 특정 임차인 계약 필터링                        | tenant-uuid                    |
  | status             | String  | N    | 계약 상태 필터링 (ACTIVE, EXPIRED, EXPIRING_SOON 등) | ACTIVE                         |
  | expiryStartDate    | String  | N    | 계약 만료일 검색 시작일 (YYYY-MM-DD)           | 2025-07-01                     |
  | expiryEndDate      | String  | N    | 계약 만료일 검색 종료일 (YYYY-MM-DD)           | 2025-09-30                     |
  | keyword            | String  | N    | 임차인명, 임대인명, 계약번호 등 키워드 검색    | 홍길동                         |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                                | endDate ASC                    |

- **Success Response:** `200 OK`, `PagedResponse<LeaseContractSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 임대 계약 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/lease-contracts/{contractId}`
- **설명:** 지정된 ID의 임대 계약 상세 정보(첨부파일 포함)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 경리담당자, 관련 임대인/임차인(향후 포털 연동 시)
- **Path Parameters:** `contractId` (계약 고유 ID)
- **Success Response:** `200 OK`, `LeaseContractDetailResponseDto`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.4. 임대 계약 정보 수정 (주요 조건 변경은 신중, 보통 부속 합의 또는 갱신으로 처리)

- **HTTP Method:** `PUT` (또는 `PATCH`로 부분 수정)
- **URI:** `/lease-contracts/{contractId}`
- **설명:** 지정된 ID의 임대 계약 정보를 수정한다. (계약 기간, 금액 등 주요 조건 변경 시 이력 관리 또는 별도 '계약 변경/갱신' API 사용 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `contractId`
- **Request Body:** `LeaseContractUpdateRequestDto` (4.1.1의 Create DTO와 유사하나, 수정 가능한 필드만. 예: `specialClauses`, `brokerInfo`, `status` - 상태변경은 별도 액션API 권장)
- **Success Response:** `200 OK`, `LeaseContractResponseDto`
- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict`.

#### 4.1.5. 임대 계약 상태 변경 및 기타 액션 (Action-based endpoints)

##### 4.1.5.1. 계약 활성화 (Activate Contract)

- **HTTP Method:** `POST`
- **URI:** `/lease-contracts/{contractId}/actions/activate`
- **설명:** '계약 예정(SCHEDULED)' 상태의 계약을 '계약중(ACTIVE)' 상태로 변경한다 (예: 실제 입주일 도래 시).
- **요청 권한:** 관리소장
- **Path Parameters:** `contractId`
- **Request Body:** (선택적) `{ "actualStartDate": "YYYY-MM-DD" }`
- **Success Response:** `200 OK`, `LeaseContractResponseDto` (상태 변경됨)
- **Error Responses:** `400 Bad Request` (잘못된 현재 상태), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

##### 4.1.5.2. 계약 갱신 (Renew Contract)

- **HTTP Method:** `POST`

- **URI:** `/lease-contracts/{contractId}/actions/renew`

- **설명:** 기존 계약을 기반으로 새로운 조건의 갱신 계약을 생성한다. 기존 계약은 '갱신됨(RENEWED)' 또는 '만료됨(EXPIRED)' 상태로 변경될 수 있다.

- **요청 권한:** 관리소장

- **Path Parameters:** `contractId` (갱신 대상 이전 계약 ID)

- Request Body:

```
  LeaseContractRenewalRequestDto
```

   (새로운 계약 기간, 임대료, 보증금 등 갱신 조건)

  JSON

  ```
  {
      "newStartDate": "2027-07-01",
      "newEndDate": "2029-06-30",
      "newRentAmount": 1300000,
      "newDepositAmount": 50000000,
      // ... 기타 변경된 조건
      "linkToParentContract": true // (내부적으로 parentContractId 설정)
  }
  ```

- **Success Response:** `201 Created` (새로운 계약 리소스), `Location` 헤더, `LeaseContractResponseDto` (새로 생성된 갱신 계약 정보)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

##### 4.1.5.3. 계약 해지/종료 (Terminate Contract)

- **HTTP Method:** `POST`

- **URI:** `/lease-contracts/{contractId}/actions/terminate`

- **설명:** 현재 '계약중' 또는 '만료 예정'인 계약을 해지(또는 만료) 처리한다. "이사 정산" 절차와 연동될 수 있다.

- **요청 권한:** 관리소장

- **Path Parameters:** `contractId`

- Request Body:

  ```
  LeaseContractTerminationRequestDto
  ```

  JSON

  ```
  {
      "terminationDate": "2025-10-15", // 실제 해지/만료일
      "reason": "임차인 사유로 인한 중도 해지", // 해지 사유
      "initiateMoveOutSettlement": true // 이사 정산 절차 시작 여부
  }
  ```

- **Success Response:** `200 OK`, `LeaseContractResponseDto` (상태가 `TERMINATED` 또는 `EXPIRED`로 변경됨)

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.6. 임대 계약 삭제 (제한적)

- **HTTP Method:** `DELETE`
- **URI:** `/lease-contracts/{contractId}`
- **설명:** 임대 계약 정보를 삭제한다. (주로 잘못 입력된 '계약 예정' 건에 한해 물리적 삭제 가능. 그 외에는 '해지됨' 또는 '취소됨' 상태 변경 권장)
- **요청 권한:** 총괄관리자
- **Path Parameters:** `contractId`
- **Success Response:** `204 No Content`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 임대 계약 첨부파일 관리 API (`/lease-contracts/{contractId}/attachments`)

*(민원 처리 API의 첨부파일 관리와 유사한 패턴)*

#### 4.2.1. 계약에 파일 첨부

- **HTTP Method:** `POST`
- **URI:** `/lease-contracts/{contractId}/attachments`
- **요청 권한:** 계약 수정 권한이 있는 사용자
- **Request Body:** `multipart/form-data` (파일)
- **Success Response:** `201 Created`, `List<ContractAttachmentDto>`

#### 4.2.2. 특정 계약의 첨부파일 목록 조회

- **HTTP Method:** `GET`
- **URI:** `/lease-contracts/{contractId}/attachments`
- **Success Response:** `200 OK`, `List<ContractAttachmentDto>`

#### 4.2.3. 특정 첨부파일 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/lease-contracts/{contractId}/attachments/{attachmentId}`
- **Success Response:** `204 No Content`

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `LeaseContractResponseDto` / `LeaseContractSummaryDto` / `LeaseContractDetailResponseDto`

JSON

  ```
// LeaseContractSummaryDto (목록용)
{
    "contractId": "string",
    "unitInfo": { "unitId": "string", "unitNumber": "string", "buildingName": "string" },
    "tenantName": "string",
    "lessorName": "string (nullable)",
    "startDate": "string (YYYY-MM-DD)",
    "endDate": "string (YYYY-MM-DD)",
    "rentAmount": "number",
    "depositAmount": "number",
    "status": "string (Enum)",
    "remainingDays": "integer (nullable)" // 계약 만료까지 남은 일수
}

// LeaseContractDetailResponseDto (상세용)
{
    "contractId": "string",
    "unitId": "string",
    "unitNumber": "string", // 편의 정보
    "buildingId": "string", // 편의 정보
    "buildingName": "string", // 편의 정보
    "lessorId": "string",
    "lessorName": "string", // 편의 정보
    "tenantId": "string",
    "tenantName": "string", // 편의 정보
    "contractNumber": "string (nullable)",
    "contractDate": "string (YYYY-MM-DD)",
    "startDate": "string (YYYY-MM-DD)",
    "endDate": "string (YYYY-MM-DD)",
    "depositAmount": "number",
    "rentAmount": "number",
    "rentPaymentCycle": "string (Enum)",
    "rentPaymentDay": "integer",
    "maintenanceFeeCondition": "string (Enum)",
    "maintenanceFeeAmount": "number (nullable)",
    "specialClauses": "string (nullable)",
    "brokerInfo": "string (nullable)",
    "status": "string (Enum)",
    "statusName": "string", // Enum에 대한 한글명
    "parentContractId": "string (nullable)", // 갱신 시 이전 계약 ID
    "attachments": [ // array of ContractAttachmentDto
        {
            "attachmentId": "string",
            "fileName": "string",
            "fileUrl": "string", // 다운로드 URL
            "uploadedAt": "string (ISO DateTime)"
        }
    ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

(Create/Update/Renewal/Termination Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;Dto>는 목록 조회 시 공통적으로 사용)

------

