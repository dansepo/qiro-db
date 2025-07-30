
#  M QIRO 공용 시설 검침 데이터 등록 API 설계

## 1. 문서 정보
- **문서명:** QIRO 공용 시설 검침 데이터 등록 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-COMMMTR-001 - QIRO - 공용 시설 검침 데이터 등록 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 공용 시설(구역) 계량기 검침 데이터 등록, 조회, 수정, 삭제를 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 청구월별 공용 시설의 유틸리티 사용량을 시스템에 기록하고 관리할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 업로드 시 `multipart/form-data`)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 특정 청구월에 공용 시설 검침 데이터 등록

- **HTTP Method:** `POST`
- **URI:** `/billing-months/{billingMonthId}/common-area-meter-readings`
- **설명:** 지정된 청구월에 특정 공용 시설(계량기)에 대한 새로운 검침 데이터를 등록한다. 등록 시 이전 검침 기록을 바탕으로 전월 지침이 조회될 수 있다.
- **요청 권한:** 관리소장, 경리담당자, 시설 담당자
- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                   |
  | :---------------- | :----------- | :--------------------- |
  | `billingMonthId`  | UUID / Long  | 검침 데이터를 등록할 청구월의 ID |

- **Request Body:** `CommonAreaMeterReadingCreateRequestDto`
  ```json
  {
      "facilityId": "facility-uuid-common-meter-001", // 검침 대상 공용 시설(계량기) ID
      "readingDate": "2025-06-28",
      "currentMeterReading": 15780.5, // 당월 지침 값
      "attachments": [ // 선택 사항: 계량기 사진 등
          {"fileName": "common_elec_meter_jun.jpg", "fileKey": "s3-key-for-photo.jpg"}
      ],
      "remarks": "정기 검침" // 선택 사항
  }
  ```

- **Request Body 필드 설명:**

  | 필드명                  | 타입          | 필수 | 설명                               |
  | :---------------------- | :------------ | :--- | :--------------------------------- |
  | facilityId            | String        | Y    | 검침 대상 공용 시설(계량기)의 ID     |
  | readingDate           | String        | Y    | 검침일 (YYYY-MM-DD)                |
  | currentMeterReading   | Number        | Y    | 당월 검침 지침 값                    |
  | attachments           | Array&lt;Object> | N    | 첨부 파일 정보 (fileName, fileKey) |
  | remarks               | String        | N    | 비고                               |

- **Success Response:**

  - **Code:** `201 Created`
  - **Headers:** `Location: /v1/common-area-meter-readings/{commonReadingId}` (생성된 개별 검침 기록 ID)
  - **Body:** `CommonAreaMeterReadingResponseDto` (생성된 검침 데이터, 전월지침 및 사용량 포함)

- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류, 잘못된 facilityId 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId 또는 facilityId). `409 Conflict` (해당 청구월/시설에 이미 검침 데이터 존재 시).

------

### 4.2. 특정 청구월의 공용 시설 검침 데이터 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/billing-months/{billingMonthId}/common-area-meter-readings`

- **설명:** 지정된 청구월에 등록된 모든 공용 시설 검침 데이터 목록을 조회한다.

- **요청 권한:** 총괄관리자, 관리소장, 경리담당자, 시설 담당자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                     |
  | :---------------- | :----------- | :----------------------- |
  | billingMonthId  | UUID / Long  | 조회할 청구월의 ID       |

- **Query Parameters:**

  | 파라미터명        | 타입   | 필수 | 설명                                     | 예시                          |
  | :---------------- | :----- | :--- | :--------------------------------------- | :---------------------------- |
  | facilityId      | String | N    | 특정 공용 시설(계량기)의 검침 데이터만 필터링 | facility-uuid-common-meter-001 |
  | utilityType     | String | N    | 공과금 종류로 필터링 (예: ELECTRICITY)   | WATER                       |
  | page, size, sortBy (readingDate, facilityName), sortDirection (공통 파라미터) |        | N    |                                          | readingDate DESC            |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<CommonAreaMeterReadingResponseDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `404 Not Found` (billingMonthId).

------

### 4.3. 특정 공용 시설 검침 데이터 상세 조회

- **HTTP Method:** `GET`

- **URI:** `/common-area-meter-readings/{commonReadingId}`

- **설명:** 지정된 ID의 공용 시설 검침 데이터 상세 정보를 조회한다.

- **요청 권한:** (4.2와 유사)

- **Path Parameters:**

  | 파라미터명          | 타입         | 설명                         |
  | :------------------ | :----------- | :--------------------------- |
  | commonReadingId   | UUID / Long  | 조회할 공용 검침 기록의 ID   |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `CommonAreaMeterReadingResponseDto`

- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

------

### 4.4. 특정 공용 시설 검침 데이터 수정

- **HTTP Method:** `PUT` (또는 `PATCH`)

- **URI:** `/common-area-meter-readings/{commonReadingId}`

- **설명:** 지정된 ID의 공용 시설 검침 데이터를 수정한다. (예: 당월 지침 값, 검침일, 메모, 첨부파일 수정)

- **요청 권한:** 관리소장, 경리담당자, 시설 담당자

- **Path Parameters:**

  | 파라미터명          | 타입         | 설명                         |
  | :------------------ | :----------- | :--------------------------- |
  | commonReadingId   | UUID / Long  | 수정할 공용 검침 기록의 ID   |

- **Request Body:** `CommonAreaMeterReadingUpdateRequestDto` (4.1의 Create DTO와 유사하나, `facilityId`는 보통 변경 불가)

  JSON

```
  {
      "readingDate": "2025-06-29", // 수정된 검침일
      "currentMeterReading": 15800.0, // 수정된 당월 지침
      "remarks": "검침일 변경 및 지침 수정",
      "attachments": [ // 수정된 첨부 파일 목록
          {"fileName": "new_meter_photo.jpg", "fileKey": "s3-key-new-photo.jpg"}
      ]
  }
```

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `CommonAreaMeterReadingResponseDto` (수정된 검침 데이터)

- **Error Responses:** `400 Bad Request` (청구월 상태가 '준비중'이 아님, 유효성 오류), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.5. 특정 공용 시설 검침 데이터 삭제

- **HTTP Method:** `DELETE`

- **URI:** `/common-area-meter-readings/{commonReadingId}`

- **설명:** 지정된 ID의 공용 시설 검침 데이터를 삭제한다. (청구월 상태가 '준비중'일 때만 가능)

- **요청 권한:** 관리소장, 시설 담당자 (또는 상위 권한자)

- **Path Parameters:**

  | 파라미터명          | 타입         | 설명                         |
  | :------------------ | :----------- | :--------------------------- |
  | commonReadingId   | UUID / Long  | 삭제할 공용 검침 기록의 ID   |

- **Success Response:**

  - **Code:** `204 No Content`

- **Error Responses:** `400 Bad Request` (청구월 상태가 '준비중'이 아님), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

## 5. 데이터 모델 (DTOs)

### 5.1. `CommonAreaMeterReadingResponseDto`

JSON

  ```
{
    "commonReadingId": "string (UUID or Long)",
    "billingMonthId": "string (UUID or Long)",
    "billingYearMonth": "string (YYYY-MM)", // 편의상 추가
    "facilityId": "string (UUID or Long)",
    "facilityName": "string", // 편의상 추가 (예: "본관 공용 전기 계량기")
    "utilityType": "string (Enum: ELECTRICITY, WATER, GAS, HEATING)",
    "readingDate": "string (YYYY-MM-DD)",
    "previousMeterReading": "number (BigDecimal/Double)", // 서버에서 조회하여 설정
    "currentMeterReading": "number (BigDecimal/Double)",
    "usageCalculated": "number (BigDecimal/Double)", // 서버에서 계산
    "attachments": [ // array of AttachmentDto
        {
            "attachmentId": "string",
            "fileName": "string",
            "fileUrl": "string",
            "uploadedAt": "string (ISO DateTime)"
        }
    ],
    "remarks": "string (nullable)",
    "createdAt": "string (ISO DateTime)",
    "lastModifiedAt": "string (ISO DateTime)"
}
  ```

### 5.2. `CommonAreaMeterReadingCreateRequestDto`

(4.1 요청 본문 필드 참조)

### 5.3. `CommonAreaMeterReadingUpdateRequestDto`

(4.4 요청 본문 필드 참조 - `facilityId` 등 주요 식별자 제외한 수정 가능 필드)

### 5.4. `PagedResponse<CommonAreaMeterReadingResponseDto>`

(표준 페이지네이션 응답 구조에 `data` 항목으로 `CommonAreaMeterReadingResponseDto` 배열 포함)

------

```
이 API 설계안은 QIRO 서비스의 "공용 시설 검침 데이터 등록" 기능을 위한 핵심 엔드포인트와 데이터 구조를 정의합니다. 실제 구현 시에는 `previousMeterReading`을 가져오는 로직, `usageCalculated` 계산 로직, 그리고 청구월 상태에 따른 CRUD 제한 등을 백엔드에서 정확히 구현해야 합니다. 
```