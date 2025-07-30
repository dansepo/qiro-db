
# 🗣️ QIRO 민원 처리 관리 API 설계

## 1. 문서 정보
- **문서명:** QIRO 민원 처리 관리 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-COMPMGMT-001 - QIRO - 민원 처리 관리 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 민원 처리 관리 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 민원 접수, 담당자 배정, 처리 상태 업데이트, 결과 기록 등의 업무를 수행할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 민원 (Complaint) 관리 API

#### 4.1.1. 신규 민원 접수
- **HTTP Method:** `POST`
- **URI:** `/complaints`
- **설명:** 새로운 민원을 시스템에 등록한다. (주로 관리자가 입력)
- **요청 권한:** 총괄관리자, 관리소장, 민원 담당 직원
- **Request Body:** `ComplaintCreateRequestDto`
  ```json
  {
      "buildingId": "building-uuid-string",
      "unitId": "unit-uuid-string", // 민원 발생 호실
      "tenantId": "tenant-uuid-string-optional", // 민원 제기 임차인 (연결 시)
      "reporterName": "홍길동", // 실제 민원 제기자명
      "reporterContact": "010-1234-5678", // 실제 민원 제기자 연락처
      "complaintTypeCode": "FACILITY_REPAIR_ELEC", // 민원 유형 코드 (사전 정의된 값)
      "title": "거실 형광등 점멸 문제", // 선택 사항
      "description": "어제 저녁부터 거실 형광등이 깜빡거리다가 현재는 켜지지 않습니다. 빠른 확인 부탁드립니다.",
      "attachments": [ // 선택 사항: 파일 업로드 후 받은 파일 키 목록
          {"fileName": "living_room_light.jpg", "fileKey": "s3-key-for-image1"},
          {"fileName": "video_flicker.mp4", "fileKey": "s3-key-for-video1"}
      ]
  }
  ```

- **Request Body 필드 설명:** (주요 필드)

  | 필드명             | 타입          | 필수 | 설명                                  |
  | :----------------- | :------------ | :--- | :------------------------------------ |
  | buildingId       | String        | Y    | 관련 건물 ID                          |
  | unitId           | String        | Y    | 민원 발생 호실 ID                     |
  | tenantId         | String        | N    | (연결된 경우) 민원 제기 임차인 ID     |
  | reporterName     | String        | Y    | 민원 제기자 성명                      |
  | reporterContact  | String        | Y    | 민원 제기자 연락처                    |
  | complaintTypeCode| String        | Y    | 민원 유형 코드                        |
  | title            | String        | N    | 민원 제목 (요약)                      |
  | description      | String        | Y    | 민원 상세 내용                        |
  | attachments      | Array&lt;Object> | N    | 첨부 파일 정보 (fileName, fileKey) |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/complaints/{complaintId}`
  - **Body:** `ComplaintResponseDto` (생성된 민원 정보)

- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (buildingId/unitId 등 참조 ID 오류).

#### 4.1.2. 민원 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/complaints`

- **설명:** 민원 목록을 조회한다. (필터링, 정렬, 페이지네이션 지원)

- **요청 권한:** 총괄관리자, 관리소장, 민원 담당 직원, (자신의 민원만) 시설관리자(협력업체)

- **Query Parameters:**

  | 파라미터명          | 타입    | 필수 | 설명                                    | 예시                             |
  | :------------------ | :------ | :--- | :-------------------------------------- | :------------------------------- |
  | buildingId        | String  | N    | 특정 건물 필터링                        | building-uuid                  |
  | unitId            | String  | N    | 특정 호실 필터링                        | unit-uuid                      |
  | complaintTypeCode | String  | N    | 민원 유형 필터링                        | FACILITY_REPAIR                |
  | status            | String  | N    | 처리 상태 필터링 (RECEIVED, IN_PROGRESS, RESOLVED 등) | IN_PROGRESS                    |
  | assignedUserId    | String  | N    | 담당 직원 ID 필터링                     | user-uuid                      |
  | assignedVendorId  | String  | N    | 담당 협력업체 ID 필터링                 | vendor-uuid                    |
  | startDate         | String  | N    | 접수일 검색 시작일 (YYYY-MM-DD)         | 2025-06-01                     |
  | endDate           | String  | N    | 접수일 검색 종료일 (YYYY-MM-DD)         | 2025-06-30                     |
  | keyword           | String  | N    | 제목, 내용, 민원인 등 키워드 검색       | 누수                           |
  | page, size, sortBy, sortDirection (공통 파라미터) |         | N    |                                         | receivedDateTime DESC          |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<ComplaintSummaryDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`.

#### 4.1.3. 특정 민원 상세 조회

- **HTTP Method:** `GET`
- **URI:** `/complaints/{complaintId}`
- **설명:** 지정된 ID의 민원 상세 정보(처리 이력, 첨부파일 포함)를 조회한다.
- **요청 권한:** 총괄관리자, 관리소장, 민원 담당 직원, 해당 건 담당 시설관리자(협력업체), 해당 건 민원인(향후 포털 연동 시)
- **Path Parameters:** `complaintId` (민원 고유 ID)
- Success Response:
  - **Code:** `200 OK`
  - **Body:** `ComplaintDetailResponseDto` (처리 이력 및 첨부파일 목록 포함)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden` (자신의 민원이 아닐 경우 등), `404 Not Found`.

#### 4.1.4. 민원 정보 부분 수정 (상태 변경, 담당자 배정, 처리 결과 등록 등)

- **HTTP Method:** `PATCH`

- **URI:** `/complaints/{complaintId}`

- **설명:** 지정된 ID의 민원 정보를 부분적으로 수정한다. 주로 담당자 배정, 처리 상태 변경, 처리 내용 및 결과 등록에 사용된다.

- **요청 권한:** 총괄관리자, 관리소장, 민원 담당 직원, (자신에게 배정된 건의 상태 및 결과만) 시설관리자(협력업체)

- **Path Parameters:** `complaintId`

- Request Body:

```
  ComplaintUpdateRequestDto
```

   (수정할 필드만 포함)

  JSON

  ```
  // 예시 1: 담당자 배정 및 상태 변경
  {
      "assignedUserId": "user-uuid-staff",
      "status": "ASSIGNED", // 또는 IN_PROGRESS
      "remarks": "김철수 담당자에게 배정됨. 확인 요망."
  }

  // 예시 2: 처리 결과 등록
  {
      "status": "RESOLVED",
      "resolutionDetails": "누수 부위 확인 후 배관 교체 완료. 추가 테스트 결과 이상 없음.",
      "completedDateTime": "2025-06-05T14:30:00.000Z",
      "newAttachments": [
          {"fileName": "repair_complete.jpg", "fileKey": "s3-key-for-repair-image"}
      ]
  }

  // 예시 3: 민원인 피드백 등록 및 종결
  {
      "status": "CLOSED_SATISFIED",
      "satisfactionScore": 5, // 1~5
      "satisfactionComment": "빠른 처리 감사합니다."
  }
  ```

- Success Response:

  - **Code:** `200 OK`
  - **Body:** `ComplaintDetailResponseDto` (수정된 민원 상세 정보)

- **Error Responses:** `400 Bad Request` (잘못된 상태 전환, 필수값 누락), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.1.5. 민원 삭제 (또는 취소)

- **HTTP Method:** `DELETE`
- **URI:** `/complaints/{complaintId}`
- **설명:** 지정된 ID의 민원을 삭제(또는 취소)한다. (주로 '접수됨' 상태이거나, 특정 조건 하에서만 물리적 삭제 가능. 그 외에는 '취소됨' 상태로 변경하는 논리적 삭제 권장)
- **요청 권한:** 총괄관리자, 관리소장
- **Path Parameters:** `complaintId`
- **Success Response:** `204 No Content` 또는 `200 OK` (논리적 삭제 시 상태 변경된 정보 반환)
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`, `409 Conflict` (삭제 불가 조건).

------

### 4.2. 민원 첨부파일 관리 API (세부 API)

*(실제 파일 업로드는 별도의 파일 업로드 서비스(예: Presigned URL 방식 S3 직접 업로드 후 키값 전달)를 사용하고, 이 API는 메타데이터 관리 및 연결에 집중할 수 있음. 또는 이 API가 직접 파일을 받을 수도 있음.)*

#### 4.2.1. 민원에 파일 첨부

- **HTTP Method:** `POST`
- **URI:** `/complaints/{complaintId}/attachments`
- **설명:** 특정 민원에 하나 이상의 파일을 첨부한다. (Multipart/form-data 사용)
- **요청 권한:** 민원 수정 권한이 있는 사용자
- **Path Parameters:** `complaintId`
- **Request Body:** `multipart/form-data` containing `files`
- **Success Response:** `201 Created`, `List<ComplaintAttachmentDto>` (추가된 첨부파일 정보 목록)
- **Error Responses:** `400 Bad Request` (파일 크기/형식 제한 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

#### 4.2.2. 특정 첨부파일 삭제

- **HTTP Method:** `DELETE`
- **URI:** `/complaints/{complaintId}/attachments/{attachmentId}`
- **설명:** 특정 민원에서 지정된 첨부파일을 삭제한다.
- **요청 권한:** 민원 수정 권한이 있는 사용자, 파일 업로더
- **Path Parameters:** `complaintId`, `attachmentId`
- **Success Response:** `204 No Content`
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.3. 민원 유형 마스터 API (선택적 관리 기능)

- **HTTP Method:** `GET`
- **URI:** `/complaint-types`
- **설명:** 시스템에서 사용 가능한 민원 유형 목록을 조회한다. (주로 드롭다운 채우기 용도)
- **요청 권한:** 인증된 모든 내부 사용자
- **Success Response:** `200 OK`, `List<ComplaintTypeMasterDto>`
- *(POST, PUT, DELETE 등 CRUD API는 시스템 관리자 전용으로 별도 정의 가능)*

## 5. 데이터 모델 (DTOs) - 주요 항목 예시

### 5.1. `ComplaintResponseDto` / `ComplaintDetailResponseDto`

JSON

  ```
{
    "complaintId": "string (UUID or Long)",
    "complaintNumber": "string (예: QCP-20250603-001)", // 시스템 채번
    "buildingId": "string",
    "buildingName": "string", // 편의상 추가
    "unitId": "string",
    "unitNumber": "string", // 예: "101동 1001호"
    "tenantId": "string (nullable)",
    "tenantName": "string (nullable)", // 편의상 추가
    "reporterName": "string",
    "reporterContact": "string",
    "receivedDateTime": "string (ISO DateTime)",
    "complaintTypeCode": "string",
    "complaintTypeName": "string", // 코드에 대한 명칭
    "title": "string (nullable)",
    "description": "string",
    "status": "string (Enum)",
    "statusName": "string",
    "assignedUserId": "string (nullable)",
    "assignedUserName": "string (nullable)",
    "assignedVendorId": "string (nullable)",
    "assignedVendorName": "string (nullable)",
    "targetCompletionDate": "string (YYYY-MM-DD, nullable)",
    "resolutionDetails": "string (nullable)",
    "completedDateTime": "string (ISO DateTime, nullable)",
    "satisfactionScore": "integer (nullable)",
    "satisfactionComment": "string (nullable)",
    "attachments": [ // array of ComplaintAttachmentDto
        {
            "attachmentId": "string",
            "fileName": "string",
            "fileUrl": "string", // 다운로드 URL
            "fileType": "string",
            "fileSize": "long",
            "uploadedAt": "string (ISO DateTime)"
        }
    ],
    "history": [ // array of ComplaintHistoryDto (DetailResponseDto에만 포함)
        {
            "historyId": "string",
            "actionDateTime": "string (ISO DateTime)",
            "actorName": "string",
            "actionType": "string",
            "previousStatusName": "string (nullable)",
            "newStatusName": "string (nullable)",
            "remarks": "string (nullable)"
        }
    ],
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

(Create/Update Request DTO들은 위 Response DTO에서 필요한 입력 필드만 선별하여 구성)

(PagedResponse&lt;ComplaintSummaryDto>는 목록 조회 시 사용, SummaryDto는 목록 표시에 필요한 최소 정보만 포함)

------

