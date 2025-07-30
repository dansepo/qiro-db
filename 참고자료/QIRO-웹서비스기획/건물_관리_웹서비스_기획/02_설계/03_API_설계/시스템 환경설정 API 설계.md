
# ⚙️ QIRO 시스템 환경설정 API 설계

## 1. 문서 정보
- **문서명:** QIRO 시스템 환경설정 API 설계
- **프로젝트명:** QIRO (중소형 건물관리 SaaS) 프로젝트
- **관련 기능 명세서:** `F-SYSCONFIG-001 - QIRO - 시스템 환경설정 기능 명세서.md`
- **작성일:** 2025년 06월 04일
- **최종 수정일:** 2025년 06월 04일
- **작성자:** QIRO API 설계팀
- **문서 버전:** 1.0
- **기준 API 버전:** v1

## 2. 개요
본 문서는 QIRO 서비스의 시스템 환경설정 관리를 위한 RESTful API의 명세와 사용 방법을 정의한다. 이 API를 통해 각 고객사의 총괄관리자는 회사 정보, 기본 표시 설정, 납부/연체 관련 기본 정책, 알림 기본 설정, 외부 서비스 연동 정보 등을 관리할 수 있다. 모든 API는 "QIRO API 설계 가이드라인"을 준수한다.

## 3. 공통 사항
- **Base URL:** `https://api.qiro.com/v1` (예시)
- **인증 (Authentication):** 모든 API 요청은 `Authorization` 헤더에 `Bearer <JWT_ACCESS_TOKEN>` 형식의 토큰을 포함해야 한다. (총괄관리자 권한 필요)
- **요청/응답 형식 (Data Format):** `application/json`, `UTF-8`.
- **JSON 속성 명명 규칙:** `camelCase`.
- **날짜 및 시간 형식:** `ISO 8601`.
- **오류 응답 형식:** (API 설계 가이드라인 표준 오류 응답 형식 참조)

## 4. API 엔드포인트 (Endpoints)

---
### 4.1. 조직(회사/사업장) 환경설정 조회

- **HTTP Method:** `GET`
- **URI:** `/organization-settings`
- **설명:** 현재 인증된 사용자가 속한 조직(회사/사업장)의 전체 시스템 환경설정 정보를 조회한다.
- **요청 권한:** 총괄관리자
- **Success Response:**
    - **Code:** `200 OK`
    - **Body:** `OrganizationSettingsResponseDto`
      ```json
      {
          "companyProfile": {
              "companyName": "QIRO 관리 주식회사",
              "businessRegistrationNumber": "123-45-67890",
              "ceoName": "홍길동",
              "address": {
                  "zipCode": "06123",
                  "streetAddress": "서울특별시 강남구 테헤란로 123",
                  "detailAddress": "QIRO 빌딩 10층"
              },
              "contactNumber": "02-1234-5678",
              "email": "admin@qiro.co.kr",
              "logoUrl": "[https://s3.ap-northeast-2.amazonaws.com/qiro-logos/logo-uuid.png](https://s3.ap-northeast-2.amazonaws.com/qiro-logos/logo-uuid.png)"
          },
          "displaySettings": {
              "defaultLanguage": "ko-KR", // 또는 en-US 등
              "timezone": "Asia/Seoul",
              "dateFormat": "YYYY-MM-DD",
              "numberFormat": "#,##0.##", // 1,234.56
              "defaultCurrency": "KRW"
          },
          "paymentPolicyDefaults": {
              "paymentDueDay": 25, // 매월 25일
              "lateFeeRate": 3.0, // % 단위
              "lateFeeCalculationMethod": "DAILY_SIMPLE_INTEREST", // 연체료 계산 방식 (Enum)
              "roundingPolicy": "ROUND_HALF_UP" // 숫자 처리 반올림 정책 (Enum)
          },
          "notificationDefaults": {
              "defaultSenderEmail": "notice@qiro.co.kr",
              "defaultSenderName": "QIRO 관리 시스템",
              "smsSenderNumber": "02-1234-5678" // 사전 인증된 번호
          },
          "externalServiceIntegrations": {
              "smsService": {
                  "serviceProvider": "SomeSmsProvider", // 예: NHN Cloud, Twilio 등
                  "apiKeyMasked": "**********", // 실제 키는 응답에 포함하지 않거나 마스킹
                  "isEnabled": true
              },
              "emailService": {
                  "serviceProvider": "AWS_SES", // 예: AWS SES, SendGrid
                  "configurationDetails": { /* ... */ },
                  "isEnabled": true
              }
          },
          "featureToggles": { // 선택적 고급 기능
              "enableBudgetManagement": false,
              "enableEContractIntegration": true
          },
          "lastModifiedAt": "2025-06-01T10:00:00Z",
          "lastModifiedBy": "superadmin@qiro.co.kr"
      }
      ```
- **Error Responses:** `401 Unauthorized`, `403 Forbidden`.

---
### 4.2. 조직(회사/사업장) 환경설정 수정

- **HTTP Method:** `PUT`
- **URI:** `/organization-settings`
- **설명:** 현재 인증된 사용자가 속한 조직의 시스템 환경설정 정보를 전체 또는 부분적으로 수정한다. 요청 본문에 포함된 섹션의 설정만 업데이트된다. (백엔드는 부분 업데이트를 지원하도록 구현하거나, 클라이언트가 항상 전체 설정 객체를 보내도록 할 수 있음. 여기서는 부분 업데이트 가능한 구조로 가정)
- **요청 권한:** 총괄관리자
- **Request Body:** `OrganizationSettingsUpdateRequestDto` (수정하려는 섹션과 필드만 포함 가능)
  ```json
  {
      "companyProfile": { // 이 섹션 전체를 보내면 전체 업데이트, 일부 필드만 보내면 해당 필드만 업데이트 (PATCH적 동작) 또는 전체 필드 필수 (PUT적 동작)
          "companyName": "새로운 QIRO 관리 주식회사",
          "contactNumber": "02-9876-5432"
          // 로고는 별도 API로 업로드 후 URL만 여기 포함하거나, base64 인코딩 문자열 (비권장)
      },
      "paymentPolicyDefaults": {
          "paymentDueDay": 28,
          "lateFeeRate": 2.5
      }
      // 수정하지 않는 섹션(예: displaySettings)은 보내지 않거나 null로 보낼 수 있음
  }
  ```

- Success Response:
  - **Code:** `200 OK`
  - **Body:** `OrganizationSettingsResponseDto` (업데이트된 전체 설정 정보)
- **Error Responses:** `400 Bad Request` (입력값 유효성 오류), `401 Unauthorized`, `403 Forbidden`.

------

### 4.3. 회사/사업장 로고 이미지 업로드

- **HTTP Method:** `POST`

- **URI:** `/organization-settings/logo`

- **설명:** 조직(회사/사업장)의 로고 이미지를 업로드한다. 성공 시 해당 이미지에 접근 가능한 URL 또는 시스템 내 키 값을 반환하며, 이 값은 `PUT /organization-settings` API를 통해 `companyProfile.logoUrl`에 저장되어야 한다.

- **요청 권한:** 총괄관리자

- Request Body:

```
  multipart/form-data
```

  - `file`: (이미지 파일: jpg, png 등)

- Success Response:

  - **Code:** `200 OK` (또는 `201 Created` 만약 URL이 리소스로 간주된다면)

  - Body:

    JSON

  ```
    {
        "message": "로고 이미지가 성공적으로 업로드되었습니다.",
        "logoUrl": "[https://s3.ap-northeast-2.amazonaws.com/qiro-logos/new-logo-uuid.png](https://s3.ap-northeast-2.amazonaws.com/qiro-logos/new-logo-uuid.png)", // 업로드된 이미지의 URL 또는 식별 키
        "fileKey": "qiro-logos/new-logo-uuid.png" // S3 Key 등 내부 식별자
    }
  ```

- **Error Responses:** `400 Bad Request` (파일 형식 오류, 크기 초과), `401 Unauthorized`, `403 Forbidden`, `500 Internal Server Error` (업로드 처리 실패).

## 5. 데이터 모델 (DTOs)

### 5.1. `OrganizationSettingsResponseDto`

(위 4.1의 성공 응답 본문 참조)

- 각 하위 객체 (예: `CompanyProfileDto`, `DisplaySettingsDto`, `PaymentPolicyDefaultsDto`, `NotificationDefaultsDto`, `ExternalServiceIntegrationDto`, `FeatureToggleDto`)는 해당 설정 그룹의 필드들을 포함한다.

### 5.2. `OrganizationSettingsUpdateRequestDto`

- `OrganizationSettingsResponseDto`와 유사한 구조를 가지나, 모든 필드는 선택 사항(Optional)으로 정의되어 부분 업데이트를 지원할 수 있다.

- 예시 `CompanyProfileUpdateDto` (UpdateRequestDto 내 하위 객체):

  JSON

  ```
  {
      "companyName": "string (optional)",
      "businessRegistrationNumber": "string (optional)",
      "ceoName": "string (optional)",
      "address": { // AddressDto (optional)
          "zipCode": "string (optional)",
          "streetAddress": "string (optional)",
          "detailAddress": "string (optional)"
      },
      "contactNumber": "string (optional)",
      "email": "string (optional, email format)",
      "logoUrl": "string (optional, URL format)" // 로고 업로드 API 통해 받은 URL
  }
  ```

- 예시 `ExternalServiceIntegrationUpdateDto` (UpdateRequestDto 내 하위 객체):

  JSON

  ```
  {
      "smsService": { // SmsServiceConfigUpdateDto (optional)
          "serviceProvider": "string (optional)",
          "apiKey": "string (optional, write-only, will be encrypted)", // API Key는 요청 시에만 받고 응답에는 포함하지 않음
          "isEnabled": "boolean (optional)"
      },
      "emailService": { // EmailServiceConfigUpdateDto (optional)
          // ... email service specific updatable fields
          "isEnabled": "boolean (optional)"
      }
  }
  ```

------

