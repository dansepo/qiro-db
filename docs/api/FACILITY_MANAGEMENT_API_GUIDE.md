# 시설 관리 시스템 API 사용 가이드

## 개요

시설 관리 시스템 API는 건물 내 시설물의 고장 신고부터 수리 완료까지의 전체 생명주기를 관리하는 RESTful API입니다. 이 가이드는 개발자가 API를 효과적으로 사용할 수 있도록 상세한 사용법과 예제를 제공합니다.

## 목차

1. [시작하기](#시작하기)
2. [인증 및 권한](#인증-및-권한)
3. [API 엔드포인트](#api-엔드포인트)
4. [요청/응답 형식](#요청응답-형식)
5. [에러 처리](#에러-처리)
6. [페이징 및 정렬](#페이징-및-정렬)
7. [파일 업로드](#파일-업로드)
8. [실시간 알림](#실시간-알림)
9. [SDK 및 클라이언트 라이브러리](#sdk-및-클라이언트-라이브러리)
10. [예제 코드](#예제-코드)

## 시작하기

### 기본 정보

- **Base URL**: `https://api.qiro.com/api/v1`
- **API 버전**: v1.0.0
- **프로토콜**: HTTPS
- **데이터 형식**: JSON
- **문자 인코딩**: UTF-8
- **시간대**: Asia/Seoul (KST)

### 개발 환경

- **로컬 개발**: `http://localhost:8080/api/v1`
- **개발 서버**: `https://api-dev.qiro.com/api/v1`
- **스테이징**: `https://api-staging.qiro.com/api/v1`
- **프로덕션**: `https://api.qiro.com/api/v1`

### API 문서

- **Swagger UI**: `https://api.qiro.com/api/swagger-ui.html`
- **OpenAPI Spec**: `https://api.qiro.com/api/v3/api-docs`

## 인증 및 권한

### JWT 토큰 기반 인증

시설 관리 시스템 API는 JWT(JSON Web Token) 기반 인증을 사용합니다.

#### 1. 로그인

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin@qiro.com",
  "password": "password123"
}
```

**응답:**
```json
{
  "success": true,
  "message": "로그인이 성공적으로 완료되었습니다",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "admin@qiro.com",
      "name": "관리자",
      "role": "ADMIN",
      "companyId": "550e8400-e29b-41d4-a716-446655440001"
    }
  },
  "timestamp": "2024-01-01T09:00:00+09:00"
}
```

#### 2. 토큰 사용

모든 API 요청에 Authorization 헤더를 포함해야 합니다:

```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### 3. 토큰 갱신

```http
POST /api/v1/auth/refresh
Content-Type: application/json
Authorization: Bearer <refresh_token>

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 권한 레벨

| 역할 | 설명 | 권한 |
|------|------|------|
| `SUPER_ADMIN` | 시스템 관리자 | 모든 기능 접근 |
| `ADMIN` | 회사 관리자 | 회사 내 모든 기능 |
| `MANAGER` | 시설 관리자 | 시설 관리 기능 |
| `TECHNICIAN` | 기술자 | 작업 수행 및 보고 |
| `RESIDENT` | 입주민 | 신고 및 조회 |

## API 엔드포인트

### 1. 고장 신고 관리

#### 고장 신고 등록

```http
POST /api/v1/fault-reports
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "엘리베이터 고장",
  "description": "1층 엘리베이터가 작동하지 않습니다",
  "assetId": "550e8400-e29b-41d4-a716-446655440002",
  "unitId": "550e8400-e29b-41d4-a716-446655440003",
  "priority": "HIGH",
  "faultType": "MECHANICAL",
  "location": "1층 엘리베이터 홀",
  "attachments": [
    {
      "fileName": "elevator_issue.jpg",
      "fileType": "image/jpeg",
      "fileSize": 1024000
    }
  ]
}
```

#### 고장 신고 목록 조회

```http
GET /api/v1/fault-reports?page=0&size=20&sort=reportedAt,desc&status=REPORTED&priority=HIGH
Authorization: Bearer <token>
```

#### 고장 신고 상세 조회

```http
GET /api/v1/fault-reports/550e8400-e29b-41d4-a716-446655440004
Authorization: Bearer <token>
```

#### 고장 신고 상태 업데이트

```http
PATCH /api/v1/fault-reports/550e8400-e29b-41d4-a716-446655440004/status
Content-Type: application/json
Authorization: Bearer <token>

{
  "status": "IN_PROGRESS",
  "assignedTo": "550e8400-e29b-41d4-a716-446655440005",
  "expectedCompletion": "2024-01-02T15:00:00+09:00",
  "notes": "기술자 배정 완료, 부품 주문 중"
}
```

### 2. 작업 지시서 관리

#### 작업 지시서 생성

```http
POST /api/v1/work-orders
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "엘리베이터 수리 작업",
  "description": "엘리베이터 모터 교체 및 점검",
  "faultReportId": "550e8400-e29b-41d4-a716-446655440004",
  "assetId": "550e8400-e29b-41d4-a716-446655440002",
  "workType": "REPAIR",
  "priority": "HIGH",
  "assignedTo": "550e8400-e29b-41d4-a716-446655440005",
  "scheduledStart": "2024-01-02T09:00:00+09:00",
  "scheduledEnd": "2024-01-02T17:00:00+09:00",
  "estimatedCost": 500000
}
```

#### 작업 진행 상황 업데이트

```http
PATCH /api/v1/work-orders/550e8400-e29b-41d4-a716-446655440006/progress
Content-Type: application/json
Authorization: Bearer <token>

{
  "status": "IN_PROGRESS",
  "actualStart": "2024-01-02T09:30:00+09:00",
  "workNotes": "부품 교체 시작, 예상 완료 시간 14:00",
  "partsUsed": [
    {
      "partName": "엘리베이터 모터",
      "partNumber": "ELV-MOTOR-001",
      "quantityUsed": 1,
      "unitCost": 300000,
      "supplier": "엘리베이터 부품 공급업체"
    }
  ],
  "laborHours": 2.5
}
```

### 3. 예방 정비 관리

#### 정비 일정 생성

```http
POST /api/v1/maintenance/schedules
Content-Type: application/json
Authorization: Bearer <token>

{
  "assetId": "550e8400-e29b-41d4-a716-446655440002",
  "maintenanceType": "PREVENTIVE",
  "title": "엘리베이터 정기 점검",
  "description": "월간 엘리베이터 안전 점검 및 청소",
  "frequency": "MONTHLY",
  "intervalDays": 30,
  "nextDueDate": "2024-02-01T10:00:00+09:00",
  "assignedTo": "550e8400-e29b-41d4-a716-446655440005",
  "checklist": [
    "모터 상태 점검",
    "케이블 장력 확인",
    "안전장치 작동 테스트",
    "내부 청소"
  ]
}
```

#### 정비 실행

```http
POST /api/v1/maintenance/550e8400-e29b-41d4-a716-446655440007/perform
Content-Type: application/json
Authorization: Bearer <token>

{
  "performedAt": "2024-01-15T10:00:00+09:00",
  "performedBy": "550e8400-e29b-41d4-a716-446655440005",
  "checklistResults": [
    {
      "item": "모터 상태 점검",
      "status": "PASS",
      "notes": "정상 작동"
    },
    {
      "item": "케이블 장력 확인",
      "status": "PASS",
      "notes": "적정 장력 유지"
    }
  ],
  "overallStatus": "COMPLETED",
  "notes": "모든 항목 정상, 다음 점검일: 2024-02-15",
  "nextMaintenanceDate": "2024-02-15T10:00:00+09:00"
}
```

### 4. 시설물 자산 관리

#### 시설물 등록

```http
POST /api/v1/assets
Content-Type: application/json
Authorization: Bearer <token>

{
  "assetNumber": "ELV-001",
  "assetName": "1층 승객용 엘리베이터",
  "assetType": "ELEVATOR",
  "category": "VERTICAL_TRANSPORT",
  "buildingId": "550e8400-e29b-41d4-a716-446655440008",
  "location": "1층 엘리베이터 홀",
  "manufacturer": "현대엘리베이터",
  "modelNumber": "HE-2000",
  "installationDate": "2020-03-15",
  "warrantyExpiryDate": "2025-03-15",
  "purchaseCost": 50000000,
  "specifications": {
    "capacity": "15명",
    "speed": "60m/min",
    "floors": "B1-10F"
  }
}
```

#### 자산 이력 조회

```http
GET /api/v1/assets/550e8400-e29b-41d4-a716-446655440002/history
Authorization: Bearer <token>
```

### 5. 비용 관리

#### 비용 기록

```http
POST /api/v1/costs
Content-Type: application/json
Authorization: Bearer <token>

{
  "workOrderId": "550e8400-e29b-41d4-a716-446655440006",
  "costType": "REPAIR",
  "category": "PARTS",
  "amount": 300000,
  "currency": "KRW",
  "costDate": "2024-01-02",
  "description": "엘리베이터 모터 교체",
  "paymentMethod": "COMPANY_CARD",
  "invoiceNumber": "INV-2024-001",
  "supplier": "엘리베이터 부품 공급업체"
}
```

#### 비용 통계 조회

```http
GET /api/v1/costs/summary?startDate=2024-01-01&endDate=2024-01-31&groupBy=CATEGORY
Authorization: Bearer <token>
```

### 6. 알림 시스템

#### 알림 발송

```http
POST /api/v1/notifications
Content-Type: application/json
Authorization: Bearer <token>

{
  "recipientIds": ["550e8400-e29b-41d4-a716-446655440009"],
  "notificationType": "FAULT_REPORT_URGENT",
  "title": "긴급 고장 신고",
  "message": "1층 엘리베이터 긴급 수리가 필요합니다",
  "channels": ["SMS", "EMAIL", "PUSH"],
  "priority": "HIGH",
  "metadata": {
    "faultReportId": "550e8400-e29b-41d4-a716-446655440004",
    "assetId": "550e8400-e29b-41d4-a716-446655440002"
  }
}
```

### 7. 대시보드 및 보고서

#### 대시보드 데이터 조회

```http
GET /api/v1/dashboard/overview
Authorization: Bearer <token>
```

**응답:**
```json
{
  "success": true,
  "data": {
    "faultReports": {
      "total": 45,
      "pending": 12,
      "inProgress": 8,
      "completed": 25
    },
    "workOrders": {
      "total": 38,
      "scheduled": 5,
      "inProgress": 10,
      "completed": 23
    },
    "maintenance": {
      "overdue": 3,
      "dueThisWeek": 7,
      "completed": 15
    },
    "costs": {
      "thisMonth": 2500000,
      "lastMonth": 1800000,
      "budget": 5000000,
      "budgetUsed": 0.5
    }
  }
}
```

## 요청/응답 형식

### 공통 응답 형식

모든 API 응답은 다음과 같은 공통 형식을 따릅니다:

```json
{
  "success": true,
  "message": "요청이 성공적으로 처리되었습니다",
  "data": { ... },
  "timestamp": "2024-01-01T09:00:00+09:00"
}
```

### 페이징 응답 형식

목록 조회 API의 응답 형식:

```json
{
  "success": true,
  "message": "목록 조회가 완료되었습니다",
  "data": {
    "content": [ ... ],
    "pageable": {
      "page": 0,
      "size": 20,
      "sort": "createdAt,desc"
    },
    "totalElements": 150,
    "totalPages": 8,
    "first": true,
    "last": false,
    "numberOfElements": 20
  },
  "timestamp": "2024-01-01T09:00:00+09:00"
}
```

## 에러 처리

### HTTP 상태 코드

| 상태 코드 | 설명 |
|-----------|------|
| 200 | 성공 |
| 201 | 생성 성공 |
| 400 | 잘못된 요청 |
| 401 | 인증 실패 |
| 403 | 권한 없음 |
| 404 | 리소스 없음 |
| 409 | 충돌 |
| 422 | 유효성 검사 실패 |
| 500 | 서버 오류 |

### 에러 응답 형식

```json
{
  "success": false,
  "message": "요청 처리 중 오류가 발생했습니다",
  "errorCode": "VALIDATION_FAILED",
  "errors": [
    {
      "field": "title",
      "message": "제목은 필수 입력 항목입니다"
    },
    {
      "field": "priority",
      "message": "우선순위는 HIGH, MEDIUM, LOW 중 하나여야 합니다"
    }
  ],
  "timestamp": "2024-01-01T09:00:00+09:00"
}
```

### 주요 에러 코드

| 에러 코드 | 설명 |
|-----------|------|
| `VALIDATION_FAILED` | 입력 데이터 유효성 검사 실패 |
| `RESOURCE_NOT_FOUND` | 요청한 리소스를 찾을 수 없음 |
| `UNAUTHORIZED` | 인증되지 않은 요청 |
| `FORBIDDEN` | 권한이 없는 요청 |
| `DUPLICATE_RESOURCE` | 중복된 리소스 생성 시도 |
| `BUSINESS_RULE_VIOLATION` | 비즈니스 규칙 위반 |
| `EXTERNAL_SERVICE_ERROR` | 외부 서비스 연동 오류 |

## 페이징 및 정렬

### 페이징 파라미터

| 파라미터 | 설명 | 기본값 | 예시 |
|----------|------|--------|------|
| `page` | 페이지 번호 (0부터 시작) | 0 | `page=0` |
| `size` | 페이지 크기 | 20 | `size=50` |
| `sort` | 정렬 기준 | `createdAt,desc` | `sort=name,asc` |

### 정렬 옵션

```http
# 단일 필드 정렬
GET /api/v1/fault-reports?sort=reportedAt,desc

# 다중 필드 정렬
GET /api/v1/fault-reports?sort=priority,desc&sort=reportedAt,asc

# 복합 정렬
GET /api/v1/fault-reports?sort=status,asc,priority,desc,reportedAt,desc
```

## 파일 업로드

### 단일 파일 업로드

```http
POST /api/v1/attachments
Content-Type: multipart/form-data
Authorization: Bearer <token>

--boundary
Content-Disposition: form-data; name="file"; filename="image.jpg"
Content-Type: image/jpeg

[파일 데이터]
--boundary
Content-Disposition: form-data; name="entityType"

FAULT_REPORT
--boundary
Content-Disposition: form-data; name="entityId"

550e8400-e29b-41d4-a716-446655440004
--boundary--
```

### 다중 파일 업로드

```http
POST /api/v1/attachments/batch
Content-Type: multipart/form-data
Authorization: Bearer <token>

--boundary
Content-Disposition: form-data; name="files"; filename="image1.jpg"
Content-Type: image/jpeg

[파일 데이터 1]
--boundary
Content-Disposition: form-data; name="files"; filename="image2.jpg"
Content-Type: image/jpeg

[파일 데이터 2]
--boundary
Content-Disposition: form-data; name="entityType"

WORK_ORDER
--boundary
Content-Disposition: form-data; name="entityId"

550e8400-e29b-41d4-a716-446655440006
--boundary--
```

### 지원 파일 형식

#### 이미지 파일
- JPEG, JPG, PNG, GIF, WebP, BMP
- 최대 크기: 10MB
- 자동 썸네일 생성 (300x300px)

#### 동영상 파일
- MP4, AVI, MOV, WMV, WebM, MKV
- 최대 크기: 50MB

#### 문서 파일
- PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT, CSV
- 최대 크기: 10MB

## 실시간 알림

### WebSocket 연결

```javascript
const socket = new WebSocket('wss://api.qiro.com/api/ws/notifications');

socket.onopen = function(event) {
    console.log('WebSocket 연결 성공');
    
    // 인증 토큰 전송
    socket.send(JSON.stringify({
        type: 'auth',
        token: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
    }));
};

socket.onmessage = function(event) {
    const notification = JSON.parse(event.data);
    console.log('실시간 알림:', notification);
    
    // 알림 처리 로직
    handleNotification(notification);
};
```

### 알림 타입

| 타입 | 설명 |
|------|------|
| `FAULT_REPORT_CREATED` | 새로운 고장 신고 |
| `FAULT_REPORT_URGENT` | 긴급 고장 신고 |
| `WORK_ORDER_ASSIGNED` | 작업 배정 |
| `WORK_ORDER_COMPLETED` | 작업 완료 |
| `MAINTENANCE_DUE` | 정비 일정 도래 |
| `COST_BUDGET_WARNING` | 예산 초과 경고 |

## SDK 및 클라이언트 라이브러리

### JavaScript/TypeScript SDK

```bash
npm install @qiro/facility-management-sdk
```

```typescript
import { QiroFacilityAPI } from '@qiro/facility-management-sdk';

const api = new QiroFacilityAPI({
  baseURL: 'https://api.qiro.com/api/v1',
  apiKey: 'your-api-key'
});

// 고장 신고 등록
const faultReport = await api.faultReports.create({
  title: '엘리베이터 고장',
  description: '1층 엘리베이터가 작동하지 않습니다',
  priority: 'HIGH'
});

// 작업 지시서 목록 조회
const workOrders = await api.workOrders.list({
  page: 0,
  size: 20,
  status: 'IN_PROGRESS'
});
```

### Python SDK

```bash
pip install qiro-facility-management
```

```python
from qiro_facility import QiroFacilityAPI

api = QiroFacilityAPI(
    base_url='https://api.qiro.com/api/v1',
    api_key='your-api-key'
)

# 고장 신고 등록
fault_report = api.fault_reports.create({
    'title': '엘리베이터 고장',
    'description': '1층 엘리베이터가 작동하지 않습니다',
    'priority': 'HIGH'
})

# 작업 지시서 목록 조회
work_orders = api.work_orders.list(
    page=0,
    size=20,
    status='IN_PROGRESS'
)
```

## 예제 코드

### 완전한 고장 신고 처리 플로우

```javascript
// 1. 고장 신고 등록
async function reportFault() {
    const faultReport = await fetch('/api/v1/fault-reports', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
            title: '엘리베이터 고장',
            description: '1층 엘리베이터가 작동하지 않습니다',
            assetId: 'asset-uuid',
            priority: 'HIGH',
            faultType: 'MECHANICAL',
            location: '1층 엘리베이터 홀'
        })
    });
    
    const result = await faultReport.json();
    return result.data;
}

// 2. 작업 지시서 생성
async function createWorkOrder(faultReportId) {
    const workOrder = await fetch('/api/v1/work-orders', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
            title: '엘리베이터 수리 작업',
            description: '엘리베이터 모터 점검 및 수리',
            faultReportId: faultReportId,
            workType: 'REPAIR',
            priority: 'HIGH',
            assignedTo: 'technician-uuid',
            scheduledStart: '2024-01-02T09:00:00+09:00',
            scheduledEnd: '2024-01-02T17:00:00+09:00'
        })
    });
    
    const result = await workOrder.json();
    return result.data;
}

// 3. 작업 완료 처리
async function completeWork(workOrderId) {
    const completion = await fetch(`/api/v1/work-orders/${workOrderId}/complete`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
            actualEnd: '2024-01-02T15:30:00+09:00',
            completionNotes: '모터 교체 완료, 정상 작동 확인',
            partsUsed: [
                {
                    partName: '엘리베이터 모터',
                    partNumber: 'ELV-MOTOR-001',
                    quantityUsed: 1,
                    unitCost: 300000
                }
            ],
            laborHours: 6.5,
            actualCost: 350000
        })
    });
    
    const result = await completion.json();
    return result.data;
}

// 전체 플로우 실행
async function handleFaultReportFlow() {
    try {
        // 1. 고장 신고
        const faultReport = await reportFault();
        console.log('고장 신고 등록:', faultReport);
        
        // 2. 작업 지시서 생성
        const workOrder = await createWorkOrder(faultReport.id);
        console.log('작업 지시서 생성:', workOrder);
        
        // 3. 작업 완료 (실제로는 기술자가 수행)
        const completion = await completeWork(workOrder.id);
        console.log('작업 완료:', completion);
        
    } catch (error) {
        console.error('처리 중 오류 발생:', error);
    }
}
```

### 대시보드 데이터 실시간 업데이트

```javascript
class FacilityDashboard {
    constructor(apiBaseUrl, token) {
        this.apiBaseUrl = apiBaseUrl;
        this.token = token;
        this.socket = null;
        this.dashboardData = {};
    }
    
    // WebSocket 연결
    connectWebSocket() {
        this.socket = new WebSocket(`${this.apiBaseUrl.replace('http', 'ws')}/ws/notifications`);
        
        this.socket.onopen = () => {
            console.log('WebSocket 연결 성공');
            this.socket.send(JSON.stringify({
                type: 'auth',
                token: `Bearer ${this.token}`
            }));
        };
        
        this.socket.onmessage = (event) => {
            const notification = JSON.parse(event.data);
            this.handleRealtimeUpdate(notification);
        };
    }
    
    // 초기 대시보드 데이터 로드
    async loadDashboardData() {
        try {
            const response = await fetch(`${this.apiBaseUrl}/dashboard/overview`, {
                headers: {
                    'Authorization': `Bearer ${this.token}`
                }
            });
            
            const result = await response.json();
            this.dashboardData = result.data;
            this.updateUI();
            
        } catch (error) {
            console.error('대시보드 데이터 로드 실패:', error);
        }
    }
    
    // 실시간 업데이트 처리
    handleRealtimeUpdate(notification) {
        switch (notification.type) {
            case 'FAULT_REPORT_CREATED':
                this.dashboardData.faultReports.total++;
                this.dashboardData.faultReports.pending++;
                break;
                
            case 'WORK_ORDER_COMPLETED':
                this.dashboardData.workOrders.completed++;
                this.dashboardData.workOrders.inProgress--;
                break;
                
            case 'MAINTENANCE_COMPLETED':
                this.dashboardData.maintenance.completed++;
                break;
        }
        
        this.updateUI();
    }
    
    // UI 업데이트
    updateUI() {
        // DOM 업데이트 로직
        document.getElementById('fault-reports-total').textContent = 
            this.dashboardData.faultReports.total;
        document.getElementById('fault-reports-pending').textContent = 
            this.dashboardData.faultReports.pending;
        // ... 기타 UI 업데이트
    }
    
    // 초기화
    async init() {
        await this.loadDashboardData();
        this.connectWebSocket();
    }
}

// 사용 예시
const dashboard = new FacilityDashboard('https://api.qiro.com/api/v1', 'your-token');
dashboard.init();
```

## 문의 및 지원

### 기술 지원

- **이메일**: support@qiro.com
- **전화**: 02-1234-5678
- **운영시간**: 평일 09:00-18:00 (KST)

### 개발자 커뮤니티

- **GitHub**: https://github.com/qiro-com/facility-management-api
- **Discord**: https://discord.gg/qiro-developers
- **Stack Overflow**: `qiro-facility-management` 태그

### 업데이트 및 공지

- **API 변경사항**: https://api.qiro.com/changelog
- **상태 페이지**: https://status.qiro.com
- **개발자 블로그**: https://blog.qiro.com/developers

---

**문서 버전**: v1.0.0  
**최종 업데이트**: 2024년 1월 1일  
**다음 업데이트 예정**: 2024년 2월 1일