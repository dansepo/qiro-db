# 시설 관리 시스템 API 사용 가이드

## 목차
1. [개요](#개요)
2. [인증 및 권한](#인증-및-권한)
3. [API 기본 사용법](#api-기본-사용법)
4. [주요 API 사용 예제](#주요-api-사용-예제)
5. [오류 처리](#오류-처리)
6. [모바일 앱 연동](#모바일-앱-연동)
7. [성능 최적화](#성능-최적화)
8. [FAQ](#faq)

## 개요

시설 관리 시스템 API는 건물 내 시설물의 고장 신고부터 수리 완료까지의 전체 생명주기를 관리하는 RESTful API입니다.

### 기본 정보
- **Base URL**: `https://api.qiro.com/api/v1`
- **인증 방식**: JWT Bearer Token
- **응답 형식**: JSON
- **문자 인코딩**: UTF-8
- **API 버전**: v1.0.0

### 지원 환경
- **개발 서버**: `https://api-dev.qiro.com`
- **스테이징 서버**: `https://api-staging.qiro.com`
- **프로덕션 서버**: `https://api.qiro.com`

## 인증 및 권한

### 1. 로그인 및 토큰 발급

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "user@example.com",
  "password": "password123"
}
```

**응답:**
```json
{
  "success": true,
  "message": "로그인 성공",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "username": "user@example.com",
      "name": "홍길동",
      "role": "FACILITY_MANAGER"
    }
  },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 2. 토큰 사용

모든 API 요청에 Authorization 헤더를 포함해야 합니다:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. 토큰 갱신

```http
POST /api/v1/auth/refresh
Content-Type: application/json
Authorization: Bearer <refresh_token>

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 4. 권한 체계

| 역할 | 권한 | 설명 |
|------|------|------|
| `ADMIN` | `*` | 모든 권한 |
| `FACILITY_MANAGER` | `facility:*`, `work:*`, `maintenance:*` | 시설 관리 전체 권한 |
| `TECHNICIAN` | `work:read`, `work:update`, `maintenance:read` | 작업자 권한 |
| `RESIDENT` | `fault:create`, `fault:read` | 입주민 권한 |

## API 기본 사용법

### 1. 공통 응답 형식

**성공 응답:**
```json
{
  "success": true,
  "message": "요청이 성공적으로 처리되었습니다",
  "data": { ... },
  "timestamp": "2024-01-01T00:00:00Z"
}
```

**오류 응답:**
```json
{
  "success": false,
  "message": "오류 메시지",
  "errorCode": "VALIDATION_ERROR",
  "errors": [
    {
      "field": "email",
      "message": "유효한 이메일 주소를 입력하세요"
    }
  ],
  "timestamp": "2024-01-01T00:00:00Z"
}
```

### 2. 페이징

목록 조회 API는 페이징을 지원합니다:

```http
GET /api/v1/fault-reports?page=0&size=20&sort=createdAt,desc
```

**페이징 응답:**
```json
{
  "success": true,
  "data": {
    "content": [...],
    "pageable": {
      "page": 0,
      "size": 20,
      "sort": "createdAt,desc"
    },
    "totalElements": 150,
    "totalPages": 8,
    "first": true,
    "last": false
  }
}
```

### 3. 필터링 및 검색

```http
GET /api/v1/fault-reports?status=OPEN&priority=HIGH&search=엘리베이터
```

### 4. 날짜 형식

- **날짜**: `YYYY-MM-DD` (예: `2024-01-01`)
- **날짜시간**: `YYYY-MM-DDTHH:mm:ssZ` (예: `2024-01-01T12:00:00Z`)

## 주요 API 사용 예제

### 1. 고장 신고 생성

```http
POST /api/v1/fault-reports
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "엘리베이터 고장",
  "description": "1층 엘리베이터가 작동하지 않습니다",
  "assetId": "123e4567-e89b-12d3-a456-426614174000",
  "priority": "HIGH",
  "location": "1층 로비",
  "attachments": [
    {
      "fileName": "elevator_photo.jpg",
      "fileUrl": "https://storage.qiro.com/files/elevator_photo.jpg"
    }
  ]
}
```

### 2. 작업 지시서 생성

```http
POST /api/v1/work-orders
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "엘리베이터 수리",
  "description": "엘리베이터 모터 교체 작업",
  "faultReportId": "123e4567-e89b-12d3-a456-426614174000",
  "workType": "REPAIR",
  "priority": "HIGH",
  "assignedTo": "456e7890-e89b-12d3-a456-426614174000",
  "scheduledStart": "2024-01-02T09:00:00Z",
  "scheduledEnd": "2024-01-02T17:00:00Z",
  "estimatedCost": 500000
}
```

### 3. 예방 정비 계획 생성

```http
POST /api/v1/maintenance/plans
Content-Type: application/json
Authorization: Bearer <token>

{
  "assetId": "123e4567-e89b-12d3-a456-426614174000",
  "planType": "PREVENTIVE",
  "maintenanceStrategy": "TIME_BASED",
  "frequency": "MONTHLY",
  "intervalDays": 30,
  "title": "엘리베이터 정기 점검",
  "description": "월 1회 엘리베이터 안전 점검",
  "checklist": [
    "모터 상태 확인",
    "케이블 점검",
    "안전장치 테스트",
    "청소 및 윤활"
  ],
  "estimatedDuration": 120,
  "estimatedCost": 200000
}
```

### 4. 대시보드 데이터 조회

```http
GET /api/v1/dashboard/facility-overview
Authorization: Bearer <token>
```

**응답:**
```json
{
  "success": true,
  "data": {
    "totalAssets": 150,
    "activeWorkOrders": 12,
    "pendingFaultReports": 5,
    "upcomingMaintenance": 8,
    "monthlyStats": {
      "completedWorkOrders": 45,
      "totalCost": 2500000,
      "averageResolutionTime": 4.5
    },
    "urgentIssues": [
      {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "title": "화재 경보기 오작동",
        "priority": "CRITICAL",
        "reportedAt": "2024-01-01T10:30:00Z"
      }
    ]
  }
}
```

### 5. 파일 업로드

```http
POST /api/v1/attachments/upload
Content-Type: multipart/form-data
Authorization: Bearer <token>

--boundary
Content-Disposition: form-data; name="file"; filename="photo.jpg"
Content-Type: image/jpeg

[binary data]
--boundary
Content-Disposition: form-data; name="entityType"

FAULT_REPORT
--boundary
Content-Disposition: form-data; name="entityId"

123e4567-e89b-12d3-a456-426614174000
--boundary--
```

## 오류 처리

### HTTP 상태 코드

| 코드 | 의미 | 설명 |
|------|------|------|
| 200 | OK | 요청 성공 |
| 201 | Created | 리소스 생성 성공 |
| 400 | Bad Request | 잘못된 요청 |
| 401 | Unauthorized | 인증 실패 |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스 없음 |
| 409 | Conflict | 리소스 충돌 |
| 422 | Unprocessable Entity | 유효성 검사 실패 |
| 500 | Internal Server Error | 서버 오류 |

### 오류 코드

| 오류 코드 | 설명 | 해결 방법 |
|-----------|------|-----------|
| `VALIDATION_ERROR` | 입력 데이터 유효성 검사 실패 | 요청 데이터 확인 |
| `AUTHENTICATION_FAILED` | 인증 실패 | 토큰 확인 및 재로그인 |
| `AUTHORIZATION_DENIED` | 권한 없음 | 사용자 권한 확인 |
| `RESOURCE_NOT_FOUND` | 리소스 없음 | 요청 URL 및 ID 확인 |
| `DUPLICATE_RESOURCE` | 중복 리소스 | 기존 데이터 확인 |
| `BUSINESS_RULE_VIOLATION` | 비즈니스 규칙 위반 | 비즈니스 로직 확인 |

### 오류 처리 예제

```javascript
// JavaScript 예제
async function createFaultReport(data) {
  try {
    const response = await fetch('/api/v1/fault-reports', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(data)
    });

    const result = await response.json();

    if (!result.success) {
      // 오류 처리
      if (result.errorCode === 'VALIDATION_ERROR') {
        // 유효성 검사 오류 처리
        result.errors.forEach(error => {
          console.error(`${error.field}: ${error.message}`);
        });
      } else {
        console.error(`오류: ${result.message}`);
      }
      return null;
    }

    return result.data;
  } catch (error) {
    console.error('네트워크 오류:', error);
    return null;
  }
}
```

## 모바일 앱 연동

### 1. 모바일 전용 API

모바일 앱을 위한 최적화된 API 엔드포인트:

```http
GET /api/v1/mobile/dashboard
GET /api/v1/mobile/fault-reports
POST /api/v1/mobile/fault-reports/quick
GET /api/v1/mobile/work-orders/my
```

### 2. 푸시 알림 등록

```http
POST /api/v1/mobile/push-tokens
Content-Type: application/json
Authorization: Bearer <token>

{
  "deviceId": "device-unique-id",
  "pushToken": "firebase-push-token",
  "platform": "ANDROID",
  "appVersion": "1.0.0"
}
```

### 3. 오프라인 동기화

```http
GET /api/v1/mobile/sync?lastSyncTime=2024-01-01T00:00:00Z
```

### 4. 이미지 최적화

모바일용 이미지 요청:

```http
GET /api/v1/attachments/{id}/thumbnail?size=medium
```

## 성능 최적화

### 1. 캐싱

자주 조회되는 데이터는 캐시를 활용하세요:

```http
GET /api/v1/buildings
Cache-Control: max-age=300
```

### 2. 필드 선택

필요한 필드만 요청하여 응답 크기를 줄이세요:

```http
GET /api/v1/fault-reports?fields=id,title,status,priority,createdAt
```

### 3. 배치 요청

여러 리소스를 한 번에 요청:

```http
POST /api/v1/batch
Content-Type: application/json

{
  "requests": [
    {
      "method": "GET",
      "url": "/api/v1/fault-reports/123"
    },
    {
      "method": "GET", 
      "url": "/api/v1/work-orders/456"
    }
  ]
}
```

### 4. 압축

gzip 압축을 활용하세요:

```http
Accept-Encoding: gzip, deflate
```

## FAQ

### Q1: API 호출 제한이 있나요?
A: 네, 사용자당 시간당 1000회, 분당 100회로 제한됩니다. 제한 초과 시 429 상태 코드가 반환됩니다.

### Q2: 토큰 만료 시간은 얼마나 되나요?
A: Access Token은 1시간, Refresh Token은 30일입니다.

### Q3: 파일 업로드 크기 제한은?
A: 파일당 최대 10MB, 요청당 최대 50MB입니다.

### Q4: API 버전 관리는 어떻게 되나요?
A: URL 경로에 버전을 포함합니다 (`/api/v1/`). 하위 호환성을 유지하며, 주요 변경 시 새 버전을 제공합니다.

### Q5: 웹훅을 지원하나요?
A: 네, 주요 이벤트(고장 신고 생성, 작업 완료 등)에 대한 웹훅을 지원합니다.

```http
POST /api/v1/webhooks
Content-Type: application/json

{
  "url": "https://your-app.com/webhook",
  "events": ["fault_report.created", "work_order.completed"],
  "secret": "your-webhook-secret"
}
```

### Q6: 테스트 환경에서 API를 테스트할 수 있나요?
A: 네, 개발 서버(`https://api-dev.qiro.com`)에서 테스트 가능합니다. 테스트 계정은 별도 문의하세요.

### Q7: API 문서는 어디서 확인할 수 있나요?
A: Swagger UI를 통해 실시간 API 문서를 확인할 수 있습니다:
- 개발: `https://api-dev.qiro.com/swagger-ui.html`
- 프로덕션: `https://api.qiro.com/swagger-ui.html`

### Q8: 에러 로그는 어떻게 확인하나요?
A: 각 API 응답에 포함된 `traceId`를 통해 로그를 추적할 수 있습니다. 문제 발생 시 이 ID를 포함하여 문의하세요.

---

## 지원 및 문의

- **기술 지원**: support@qiro.com
- **개발자 포럼**: https://developers.qiro.com
- **상태 페이지**: https://status.qiro.com
- **변경 로그**: https://docs.qiro.com/changelog

마지막 업데이트: 2024년 1월 1일