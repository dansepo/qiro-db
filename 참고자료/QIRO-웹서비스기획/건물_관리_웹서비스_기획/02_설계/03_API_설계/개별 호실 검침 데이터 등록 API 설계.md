
#  QIRO 개별 호실 검침 데이터 등록 API 설계

## 1. 문서 정보
- **문서명:** QIRO 개별 호실 검침 데이터 등록 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-UNITMTR-001 - QIRO - 개별 호실 검침 데이터 등록 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 개별 호실(세대)별 월별 공과금 검침 데이터 등록, 조회, 수정 및 엑셀 일괄 업로드 기능을 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 관리자는 각 세대의 정확한 유틸리티 사용량을 시스템에 기록하여 공정한 관리비 부과의 기초를 마련할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다.
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`. (파일 업로드 시 `multipart/form-data`)
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 개별 호실 검침 데이터 일괄 생성/수정 (화면 직접 입력용)

- **HTTP Method:** `POST` (또는 `PUT` - 리소스의 전체 교체 개념이라면)
- **URI:** `/unit-meter-readings/batch`
- **설명:** 특정 청구월에 대해 다수 호실의 여러 공과금 항목에 대한 검침 데이터를 일괄적으로 생성하거나 수정한다. (UI에서 표 형태로 여러 건 입력 후 한 번에 저장하는 시나리오 지원)
- **요청 권한:** 관리소장, 경리담당자, 검침 담당자
- **Request Body:** `UnitMeterReadingBatchUpdateRequestDto`
  ```json
  {
      "billingMonthId": "bm-uuid-202506", // 대상 청구월 ID
      "readings": [
          {
              "unitId": "unit-uuid-101",
              "utilityTypeCode": "ELEC_I", // 세대 전기
              "readingDate": "2025-06-28",
              "currentMeterReading": 12550.5,
              "remarks": "정기 검침" // 선택 사항
          },
          {
              "unitId": "unit-uuid-101",
              "utilityTypeCode": "WATER_I", // 세대 수도
              "readingDate": "2025-06-28",
              "currentMeterReading": 901.0
          },
          {
              // 기존 검침 기록 ID를 알고 있다면 업데이트로 간주 가능 (unitReadingId 포함)
              "unitReadingId": "urm-uuid-prev-002", // 수정 대상 ID
              "unitId": "unit-uuid-102",
              "utilityTypeCode": "ELEC_I",
              "readingDate": "2025-06-29",
              "currentMeterReading": 16050.0,
              "remarks": "수정된 값"
          }
          // ... more readings for different units/utility types
      ]
  }
  ```

*백엔드는 각 항목에 대해 `billingMonthId`, `unitId`, `utilityTypeCode` 조합으로 기존 데이터 존재 여부를 확인하여 생성(Create) 또는 수정(Update) 처리한다. `previousMeterReading`은 서버에서 자동으로 조회/설정하고, `usageCalculated`도 서버에서 계산한다.*

- **Success Response**:
- **Code:** `200 OK`
  
- Body:

```
    BatchProcessResponseDto
```


    JSON
    
    ```
    {
        "totalItems": 3,
        "successfulItems": 3,
        "failedItems": 0,
        "results": [ // 각 항목별 처리 결과 (선택적 상세 제공)
            {"unitReadingId": "urm-uuid-new-001", "unitId": "unit-uuid-101", "utilityTypeCode": "ELEC_I", "status": "CREATED"},
            {"unitReadingId": "urm-uuid-new-002", "unitId": "unit-uuid-101", "utilityTypeCode": "WATER_I", "status": "CREATED"},
            {"unitReadingId": "urm-uuid-prev-002", "unitId": "unit-uuid-102", "utilityTypeCode": "ELEC_I", "status": "UPDATED"}
        ]
    }
    ```

- **Error Responses:** `400 Bad Request` (필수값 누락, 형식 오류, 청구월 상태 부적합 등), `401 Unauthorized`, `403 Forbidden`, `404 Not Found` (billingMonthId, unitId 등).

------

### 4.2. 개별 호실 검침 데이터 엑셀/CSV 일괄 업로드

- **HTTP Method:** `POST`

- **URI:** `/unit-meter-readings/batch-upload`

- **설명:** Excel 또는 CSV 파일을 통해 다수 호실의 검침 데이터를 특정 청구월에 대해 일괄 업로드하여 생성 또는 수정한다. 비동기 처리될 수 있다.

- **요청 권한:** 관리소장, 경리담당자, 검침 담당자

- Request:

  ```
  multipart/form-data
  ```

  - `billingMonthId` (String): 대상 청구월 ID (필수)
  - `file` (File): 업로드할 Excel 또는 CSV 파일 (필수)
  - `uploadOptions` (String/JSON, 선택): (예: `{"overwriteExisting": true, "dateFormat": "YYYY.MM.DD"}`)

- Success Response:

  - **Code:** `202 Accepted` (비동기 처리 시작 시)

  - Body:

    JSON

    ```
    {
        "jobId": "umr-upload-job-uuid-001",
        "message": "검침 데이터 파일 업로드가 접수되었습니다. 처리 완료 후 결과를 확인해주세요.",
        "statusCheckUrl": "/v1/batch-jobs/umr-upload-job-uuid-001" // (선택) 작업 상태 확인 URL
    }
    ```

- **Error Responses:** `400 Bad Request` (파일 누락, billingMonthId 누락, 지원하지 않는 파일 형식 등), `401 Unauthorized`, `403 Forbidden`.

- *(참고: `GET /v1/batch-jobs/{jobId}` API는 별도로 배치 작업 상태를 조회하는 공통 API로 설계될 수 있음)*

------

### 4.3. 특정 청구월의 개별 호실 검침 데이터 목록 조회

- **HTTP Method:** `GET`

- **URI:** `/billing-months/{billingMonthId}/unit-meter-readings`

- **설명:** 지정된 청구월에 등록된 모든 개별 호실 검침 데이터 목록을 조회한다. (UI의 표 형태 데이터 제공용)

- **요청 권한:** 관리소장, 경리담당자, 검침 담당자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                     |

  | :---------------- | :----------- | :----------------------- |

  | billingMonthId  | UUID / Long  | 조회할 청구월의 ID       |

- **Query Parameters:**

  | 파라미터명        | 타입    | 필수 | 설명                                     | 예시                          |

  | :---------------- | :------ | :--- | :--------------------------------------- | :---------------------------- |

  | buildingId      | String  | N    | 특정 건물 필터링                         | building-uuid-001           |

  | dongId          | String  | N    | 특정 동 필터링                           | dong-uuid-A                 |

  | unitId          | String  | N    | 특정 호실의 검침 데이터만 필터링         | unit-uuid-101               |

  | utilityTypeCode | String  | N    | 특정 공과금 종류로 필터링 (예: ELEC_I) | WATER_I                     |

  | page, size, sortBy (unitNumber, readingDate), sortDirection (공통 파라미터) |         | N    |                                          | unitNumber ASC              |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `PagedResponse<UnitMeterReadingResponseDto>`

- **Error Responses:** `400 Bad Request`, `401 Unauthorized`, `404 Not Found` (billingMonthId).

------

### 4.4. 특정 개별 호실 검침 데이터 상세 조회

- **HTTP Method:** `GET`

- **URI:** `/unit-meter-readings/{unitReadingId}`

- **설명:** 지정된 ID의 개별 호실 검침 데이터 상세 정보를 조회한다.

- **요청 권한:** (4.3과 유사)

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                         |
  | :---------------- | :----------- | :--------------------------- |
  | unitReadingId   | UUID / Long  | 조회할 개별 검침 기록의 ID   |

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `UnitMeterReadingResponseDto`

- **Error Responses:** `401 Unauthorized`, `404 Not Found`.

------

### 4.5. 특정 개별 호실 검침 데이터 수정

- **HTTP Method:** `PUT` (또는 `PATCH` 권장)

- **URI:** `/unit-meter-readings/{unitReadingId}`

- **설명:** 지정된 ID의 개별 호실 검침 데이터를 수정한다. (주로 당월 지침, 검침일, 메모 등 수정)

- **요청 권한:** 관리소장, 경리담당자, 검침 담당자

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                         |
  | :---------------- | :----------- | :--------------------------- |
  | unitReadingId   | UUID / Long  | 수정할 개별 검침 기록의 ID   |

- **Request Body:** `UnitMeterReadingUpdateRequestDto`

  JSON

  ```
  {
      "readingDate": "2025-06-28", // 수정된 검침일
      "currentMeterReading": 12490.0, // 수정된 당월 지침
      "remarks": "재검침하여 수정"
      // attachments 수정은 별도 엔드포인트 고려 또는 이 DTO 내에 포함
  }
  ```

- **Success Response:**

  - **Code:** `200 OK`
  - **Body:** `UnitMeterReadingResponseDto` (수정된 검침 데이터)

- **Error Responses:** `400 Bad Request` (청구월 상태가 '준비중'이 아님, 유효성 오류), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

------

### 4.6. 특정 개별 호실 검침 데이터 삭제

- **HTTP Method:** `DELETE`

- **URI:** `/unit-meter-readings/{unitReadingId}`

- **설명:** 지정된 ID의 개별 호실 검침 데이터를 삭제한다. (청구월 상태가 '준비중'일 때만 가능)

- **요청 권한:** 관리소장, 검침 담당자 (또는 상위 권한자)

- **Path Parameters:**

  | 파라미터명        | 타입         | 설명                         |
  | :---------------- | :----------- | :--------------------------- |
  | unitReadingId   | UUID / Long  | 삭제할 개별 검침 기록의 ID   |

- **Success Response:**

  - **Code:** `204 No Content`

- **Error Responses:** `400 Bad Request` (청구월 상태가 '준비중'이 아님), `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.

## 5. 데이터 모델 (DTOs)

### 5.1. `UnitMeterReadingResponseDto`

JSON

```
{
    "unitReadingId": "string (UUID or Long)",
    "billingMonthId": "string (UUID or Long)",
    "billingYearMonth": "string (YYYY-MM)", // 편의상 추가
    "unitId": "string (UUID or Long)",
    "unitNumber": "string", // 편의상 추가 (예: "101동 1001호")
    "tenantName": "string (nullable)", // 현재 임차인명 (편의상 추가)
    "utilityTypeCode": "string (Enum: ELEC_I, WATER_I, GAS_I, HEAT_I)",
    "utilityTypeName": "string", // 코드에 대한 한글명 (예: "세대 전기")
    "readingDate": "string (YYYY-MM-DD)",
    "previousMeterReading": "number (BigDecimal/Double)", // 서버에서 조회/설정
    "currentMeterReading": "number (BigDecimal/Double)",
    "usageCalculated": "number (BigDecimal/Double)", // 서버에서 계산
    "attachments": [ // array of AttachmentDto (선택적)
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

### 5.2. `UnitMeterReadingBatchUpdateRequestDto` (4.1 요청 본문 참조)

- `billingMonthId` (String)

- ```
  readings
  ```

   (Array of objects):

  - `unitReadingId` (String, N - 수정 시)
  - `unitId` (String, Y)
  - `utilityTypeCode` (String, Y)
  - `readingDate` (String, Y)
  - `currentMeterReading` (Number, Y)
  - `remarks` (String, N)

### 5.3. `UnitMeterReadingUpdateRequestDto` (4.5 요청 본문 참조)

- `readingDate` (String, N)
- `currentMeterReading` (Number, N)
- `remarks` (String, N)
- `attachments` (Array&lt;Object>, N - 첨부파일 수정/추가 시)

### 5.4. `BatchProcessResponseDto` (일괄 처리 응답 공통)

JSON

```
{
    "totalItems": "integer", // 총 처리 시도 건수
    "successfulItems": "integer", // 성공 건수
    "failedItems": "integer", // 실패 건수
    "results": [ // (선택적) 각 항목별 처리 결과 요약
        {
            "identifier": "string", // unitId + utilityTypeCode 등 식별자
            "status": "string (Enum: CREATED, UPDATED, FAILED)",
            "message": "string (nullable, 실패 시 사유)"
            // "resourceId": "string (nullable, 성공 시 생성/수정된 리소스 ID)"
        }
    ],
    "jobId": "string (nullable, 비동기 처리 시 작업 ID)"
}
```

*(PagedResponse<Dto>는 목록 조회 시 공통적으로 사용)*

------

```
이 API 설계안은 QIRO 서비스의 "개별 호실 검침 데이터 등록" 기능을 위한 핵심 엔드포인트와 데이터 구조를 정의합니다. 특히 대량의 데이터를 다루는 UI를 고려하여 일괄 처리 API(`POST /unit-meter-readings/batch`)와 엑셀 업로드 API(`POST /unit-meter-readings/batch-upload`)를 포함했습니다. 실제 구현 시에는 각 필드의 상세 유효성 검증, `previousMeterReading` 조회 로직, 청구월 상태에 따른 CRUD 제한 등을 백엔드에서 정확히 구현해야 합니다. 
```