# 건물 관리 업무 프로그램 데이터베이스 설계

## 개요

QIRO 건물 관리 SaaS를 위한 PostgreSQL 기반 데이터베이스 설계입니다. Spring Boot와 JPA를 활용한 백엔드 시스템과 Next.js 기반 프론트엔드를 지원하는 RESTful API 구조로 설계되며, 전체 시스템 기능 아키텍처의 6개 주요 영역을 완전히 지원합니다.

## 아키텍처

### 시스템 아키텍처
```
Frontend (Next.js) -> Backend API (Spring Boot) -> Database (PostgreSQL)
                                ↓
                        External Services (한전, 수도 등)
```

### 백엔드 레이어 구조
```
Controller Layer -> Service Layer -> Repository Layer -> Entity Layer
```

### 기능 아키텍처 매핑
본 설계는 QIRO 전체 시스템 기능 아키텍처의 6개 영역을 지원합니다:

1. **기초 정보 및 정책 관리** (Foundation & Policy)
2. **월별 관리비 처리 워크플로우** (Monthly Billing Workflow)
3. **임대차 관리 워크플로우** (Lease Management Workflow)
4. **시설 유지보수 관리 워크플로우** (Facility Maintenance Workflow)
5. **운영 및 고객 관리** (Operations & Customer)
6. **시스템 및 데이터 관리** (System & Data)

### 데이터베이스 설계 원칙
- 정규화를 통한 데이터 무결성 보장
- 외래키 제약조건을 통한 참조 무결성 유지
- 인덱스 최적화를 통한 조회 성능 향상
- 감사(Audit) 기능을 통한 변경 이력 추적
- 월별 워크플로우 지원을 위한 시간 기반 데이터 분할
- 다중 건물 관리를 위한 테넌트 격리

## 컴포넌트 및 인터페이스

### 핵심 도메인 엔티티 (기능 아키텍처 기반)

#### 1. 기초 정보 및 정책 관리 도메인
- **Building**: 건물 기본 정보 (F-BLDGMGMT-001)
- **Unit**: 호실 정보
- **Lessor**: 임대인 정보 (F-PEOPLEMGMT-001)
- **Tenant**: 임차인 정보 (F-PEOPLEMGMT-001)
- **FeeItem**: 관리비 항목 (F-FEE-SETUP-001)
- **ExternalBillAccount**: 외부 고지서 계정 (F-EXTBILL-MGMT-001)
- **PaymentPolicy**: 납부 정책 (F-PAYINFO-001)

#### 2. 월별 관리비 처리 도메인
- **BillingMonth**: 청구월 (F-BILL-CREATE-001)
- **UnitMeterReading**: 검침 데이터 (F-DATAINPUT-001)
- **MonthlyFee**: 산정된 관리비 (F-FEE-CALC-001)
- **Invoice**: 고지서 (F-INV-ISSUE-001)
- **Payment**: 수납 내역 (F-PAY-PROC-001)
- **Delinquency**: 미납 관리 (F-DELINQMGMT-001)

#### 3. 임대차 관리 도메인
- **LeaseContract**: 임대 계약 (F-LCMGMT-001)
- **MonthlyRent**: 임대료 관리 (F-RENTMGMT-001)
- **MoveOutSettlement**: 퇴실 정산 (F-MVSETTLE-001)

#### 4. 시설 유지보수 관리 도메인
- **Facility**: 시설물 정보 (F-FACILITY-OVERALL-001)
- **MaintenanceRequest**: 유지보수 요청
- **MaintenanceWork**: 유지보수 작업
- **FacilityVendor**: 협력업체 (F-VENDMGMT-001)

#### 5. 운영 및 고객 관리 도메인
- **Complaint**: 민원 관리 (F-COMPMGMT-001)
- **Announcement**: 공지사항 (F-NOTICEMGMT-001)
- **Notification**: 알림

#### 6. 시스템 및 데이터 관리 도메인
- **JournalEntry**: 회계 전표 (F-ACCMGMT-001)
- **User**: 사용자 정보 (F-USERROLEMGMT-001)
- **Role**: 사용자 역할
- **OrganizationSetting**: 시스템 환경설정 (F-SYSCONFIG-001)
- **AuditLog**: 감사 로그

### API 인터페이스 설계 (기능 아키텍처 기반)

#### 기초 정보 및 정책 관리 API
```
POST /buildings                           - 건물 등록
GET /buildings/{id}                       - 건물 조회
GET /buildings/{id}/units                 - 호실 목록
POST /lessors                            - 임대인 등록
POST /tenants                            - 임차인 등록
POST /fee-items                          - 관리비 항목 설정
POST /external-bill-accounts             - 외부 고지서 계정 등록
GET /payment-settings/policies           - 납부 정책 조회
PUT /payment-settings/policies           - 납부 정책 수정
```

#### 월별 관리비 처리 워크플로우 API
```
POST /billing-months                                    - 청구월 생성
POST /unit-meter-readings/batch                         - 검침 데이터 일괄 입력
PUT /billing-months/{id}/external-bill-amounts          - 외부 고지서 총액 입력
POST /billing-months/{id}/actions/calculate-fees        - 관리비 자동 산정
POST /billing-months/{id}/invoices/batch-generate       - 고지서 일괄 발급
POST /invoices/{id}/payments                           - 수납 처리
GET /delinquencies                                     - 미납 현황 조회
POST /delinquencies/actions/calculate-all-late-fees    - 연체료 일괄 계산
```

#### 임대차 관리 워크플로우 API
```
POST /lease-contracts                     - 임대 계약 생성
GET /lease-contracts/{id}                 - 계약 조회
GET /monthly-rents                        - 임대료 현황
POST /monthly-rents/{id}/payments         - 임대료 납부 처리
POST /move-out-settlements                - 퇴실 정산
GET /leasing-status/summary               - 임대 현황 요약
GET /leasing-status/units                 - 호실별 임대 현황
```

#### 시설 유지보수 관리 API
```
GET /facilities                                      - 시설물 목록
POST /facilities/{id}/inspection-records             - 점검 기록 등록
POST /facility-vendors                               - 협력업체 등록
GET /facility-vendors                                - 협력업체 목록
```

#### 운영 및 고객 관리 API
```
POST /complaints                          - 민원 접수
GET /complaints/{id}                      - 민원 조회
POST /announcements                       - 공지사항 등록
POST /notifications/send                  - 알림 발송
```

#### 시스템 및 데이터 관리 API
```
POST /journal-entries                                    - 회계 전표 등록
GET /financial-statements/income-statement               - 손익계산서 조회
GET /reports/available-reports                           - 사용 가능한 보고서 목록
GET /reports/leasing/occupancy-status                    - 임대율 보고서
POST /internal-users                                     - 내부 사용자 등록
GET /roles                                              - 역할 목록
GET /organization-settings                               - 조직 설정 조회
PUT /organization-settings                               - 조직 설정 수정
POST /units/batch-upload                                - 호실 정보 일괄 등록
GET /audit-logs                                         - 감사 로그 조회
```

## 데이터 모델

### 1. 기초 정보 및 정책 관리 테이블

#### 1.1 건물 정보 (Building)
```sql
CREATE TABLE buildings (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    building_type VARCHAR(50) NOT NULL,
    total_floors INTEGER NOT NULL,
    total_area DECIMAL(10,2) NOT NULL,
    construction_year INTEGER,
    owner_name VARCHAR(255),
    owner_contact VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);
```

#### 1.2 호실 정보 (Unit)
```sql
CREATE TABLE units (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    unit_number VARCHAR(50) NOT NULL,
    floor_number INTEGER NOT NULL,
    area DECIMAL(10,2) NOT NULL,
    unit_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'AVAILABLE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, unit_number)
);
```

#### 1.3 임대인 정보 (Lessor)
```sql
CREATE TABLE lessors (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    business_registration_number VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.4 임차인 정보 (Tenant)
```sql
CREATE TABLE tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    business_registration_number VARCHAR(20),
    representative_name VARCHAR(255),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.5 관리비 항목 (FeeItem)
```sql
CREATE TABLE fee_items (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    fee_type VARCHAR(50) NOT NULL,
    is_taxable BOOLEAN DEFAULT false,
    calculation_method VARCHAR(50) NOT NULL,
    unit_price DECIMAL(12,2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.6 외부 고지서 계정 (ExternalBillAccount)
```sql
CREATE TABLE external_bill_accounts (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    provider_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    usage_purpose VARCHAR(100),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 1.7 납부 정책 (PaymentPolicy)
```sql
CREATE TABLE payment_policies (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    payment_due_day INTEGER NOT NULL,
    late_fee_rate DECIMAL(5,2) NOT NULL,
    grace_period_days INTEGER DEFAULT 0,
    bank_account VARCHAR(100),
    account_holder VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. 월별 관리비 처리 워크플로우 테이블

#### 2.1 청구월 (BillingMonth)
```sql
CREATE TABLE billing_months (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    billing_year INTEGER NOT NULL,
    billing_month INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(building_id, billing_year, billing_month)
);
```

#### 2.2 검침 데이터 (UnitMeterReading)
```sql
CREATE TABLE unit_meter_readings (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id),
    unit_id BIGINT NOT NULL REFERENCES units(id),
    meter_type VARCHAR(50) NOT NULL,
    previous_reading DECIMAL(10,2),
    current_reading DECIMAL(10,2),
    usage_amount DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.3 산정된 관리비 (MonthlyFee)
```sql
CREATE TABLE monthly_fees (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id),
    unit_id BIGINT NOT NULL REFERENCES units(id),
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id),
    calculated_amount DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.4 고지서 (Invoice)
```sql
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id),
    unit_id BIGINT NOT NULL REFERENCES units(id),
    total_amount DECIMAL(12,2) NOT NULL,
    due_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'ISSUED',
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.5 수납 내역 (Payment)
```sql
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id),
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    payment_method VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2.6 미납 관리 (Delinquency)
```sql
CREATE TABLE delinquencies (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id),
    overdue_amount DECIMAL(12,2) NOT NULL,
    overdue_days INTEGER NOT NULL,
    late_fee DECIMAL(12,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'OVERDUE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. 임대차 관리 워크플로우 테이블

#### 3.1 임대 계약 (LeaseContract)
```sql
CREATE TABLE lease_contracts (
    id BIGSERIAL PRIMARY KEY,
    unit_id BIGINT NOT NULL REFERENCES units(id),
    tenant_id BIGINT NOT NULL REFERENCES tenants(id),
    lessor_id BIGINT NOT NULL REFERENCES lessors(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent DECIMAL(12,2) NOT NULL,
    deposit DECIMAL(12,2) NOT NULL,
    contract_terms TEXT,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3.2 임대료 관리 (MonthlyRent)
```sql
CREATE TABLE monthly_rents (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id),
    rent_year INTEGER NOT NULL,
    rent_month INTEGER NOT NULL,
    rent_amount DECIMAL(12,2) NOT NULL,
    due_date DATE NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0,
    paid_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3.3 퇴실 정산 (MoveOutSettlement)
```sql
CREATE TABLE move_out_settlements (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id),
    move_out_date DATE NOT NULL,
    deposit_refund DECIMAL(12,2) NOT NULL,
    outstanding_amount DECIMAL(12,2) DEFAULT 0,
    utility_settlement DECIMAL(12,2) DEFAULT 0,
    final_settlement DECIMAL(12,2) NOT NULL,
    settlement_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. 시설 유지보수 관리 테이블

#### 4.1 시설물 정보 (Facility)
```sql
CREATE TABLE facilities (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    facility_name VARCHAR(255) NOT NULL,
    facility_type VARCHAR(50) NOT NULL,
    location VARCHAR(255),
    installation_date DATE,
    warranty_expiry_date DATE,
    maintenance_cycle_months INTEGER,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4.2 유지보수 요청 (MaintenanceRequest)
```sql
CREATE TABLE maintenance_requests (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    facility_id BIGINT REFERENCES facilities(id),
    unit_id BIGINT REFERENCES units(id),
    requester_name VARCHAR(255) NOT NULL,
    requester_contact VARCHAR(100),
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(20) DEFAULT 'PENDING',
    assigned_to BIGINT,
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4.3 유지보수 작업 (MaintenanceWork)
```sql
CREATE TABLE maintenance_works (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES maintenance_requests(id),
    vendor_id BIGINT REFERENCES facility_vendors(id),
    work_description TEXT NOT NULL,
    cost DECIMAL(12,2) DEFAULT 0,
    worker_name VARCHAR(255),
    work_date DATE NOT NULL,
    completed_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4.4 협력업체 (FacilityVendor)
```sql
CREATE TABLE facility_vendors (
    id BIGSERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    business_registration_number VARCHAR(20),
    specialization VARCHAR(100),
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 5. 운영 및 고객 관리 테이블

#### 5.1 민원 관리 (Complaint)
```sql
CREATE TABLE complaints (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    unit_id BIGINT REFERENCES units(id),
    complainant_name VARCHAR(255) NOT NULL,
    complainant_contact VARCHAR(100),
    complaint_type VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'MEDIUM',
    status VARCHAR(20) DEFAULT 'RECEIVED',
    assigned_to BIGINT,
    resolution TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 5.2 공지사항 (Announcement)
```sql
CREATE TABLE announcements (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT REFERENCES buildings(id),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    announcement_type VARCHAR(50) NOT NULL,
    target_audience VARCHAR(50) DEFAULT 'ALL',
    is_urgent BOOLEAN DEFAULT false,
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 5.3 알림 (Notification)
```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    recipient_type VARCHAR(20) NOT NULL,
    recipient_id BIGINT NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 6. 시스템 및 데이터 관리 테이블

#### 6.1 회계 전표 (JournalEntry)
```sql
CREATE TABLE journal_entries (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id),
    entry_date DATE NOT NULL,
    reference_number VARCHAR(50),
    description TEXT NOT NULL,
    total_debit DECIMAL(15,2) NOT NULL,
    total_credit DECIMAL(15,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'DRAFT',
    created_by BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 6.2 사용자 정보 (User)
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role_id BIGINT NOT NULL REFERENCES roles(id),
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 6.3 사용자 역할 (Role)
```sql
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    permissions JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 6.4 시스템 환경설정 (OrganizationSetting)
```sql
CREATE TABLE organization_settings (
    id BIGSERIAL PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    logo_url VARCHAR(500),
    contact_info JSONB,
    default_policies JSONB,
    external_service_configs JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 6.5 감사 로그 (AuditLog)
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by BIGINT REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);
```

## 비즈니스 규칙 및 제약조건

### 데이터 무결성 규칙
- **R-DB-001**: 건물 내에서 (동 명칭 + 호실 번호)는 고유해야 함
- **R-DB-002**: 건물의 총 세대수는 실제 등록된 Unit 레코드 수와 일치해야 함
- **R-DB-003**: 계약 기간 중복 방지 (동일 호실에 대한 중복 계약 불가)
- **R-DB-004**: 관리비 부과 시 차변/대변 합계 일치 검증 (복식부기 원칙)
- **R-DB-005**: 임대료 연체 계산 시 납부 정책의 연체료율 및 유예기간 적용

### 상태 관리 규칙
- **R-ST-001**: Unit의 currentStatus는 임대 계약 상태와 연동하여 자동 업데이트
- **R-ST-002**: 계약 만료일 30일 전 자동 알림 생성
- **R-ST-003**: 미납 발생 시 연체 일수 및 연체료 자동 계산

### 권한 및 접근 제어 규칙
- **R-AC-001**: 사업장별 데이터 격리 (다른 사업장 데이터 접근 불가)
- **R-AC-002**: 역할 기반 접근 제어 (RBAC) 적용
- **R-AC-003**: 중요 데이터 변경 시 감사 로그 기록 필수

## 성능 요구사항

### 응답 시간 요구사항
- **NFR-PF-001**: 주요 페이지 로딩 시간 3초 이내
- **NFR-PF-002**: 데이터 조회 결과 2초 이내 표시 (1만 건 기준)
- **NFR-PF-003**: 관리비 자동 계산 500세대 기준 10초 이내
- **NFR-PF-004**: 고지서 일괄 생성 1000건 기준 30초 이내

### 처리량 요구사항
- **NFR-PF-005**: 최소 100명 동시 접속 지원
- **NFR-PF-006**: 시간당 최소 5000건 관리비 고지서 처리
- **NFR-PF-007**: 초당 평균 100건 민원 접수 처리

### 확장성 요구사항
- **NFR-PF-008**: 수평적/수직적 확장 가능한 아키텍처
- **NFR-PF-009**: 사업장 수 10배 증가 시에도 성능 지표 유지

## 보안 요구사항

### 인증 및 인가
- **NFR-SE-001**: 사업자등록번호 기반 회원가입 및 진위 확인
- **NFR-SE-002**: 비밀번호 최소 10자, 3가지 이상 문자 조합
- **NFR-SE-003**: 관리자급 계정 2단계 인증(MFA) 필수
- **NFR-SE-004**: 로그인 5회 실패 시 30분 계정 잠금
- **NFR-SE-005**: 비활성 30분 경과 시 세션 자동 만료

### 데이터 보안
- **NFR-SE-006**: 개인정보 및 금융정보 AES-256 암호화 저장
- **NFR-SE-007**: 모든 통신 구간 HTTPS(SSL/TLS) 암호화
- **NFR-SE-008**: 일 1회 이상 자동 백업, 백업 데이터 암호화
- **NFR-SE-009**: 첨부파일 악성코드 검사

### 시스템 보안
- **NFR-SE-010**: OWASP Top 10 취약점 방어 대책 적용
- **NFR-SE-011**: 정기 보안 패치 적용
- **NFR-SE-012**: 불필요한 포트 차단, 관리자 접근 IP 제한

### 감사 로그
- **NFR-SE-013**: 주요 사용자 활동 감사 로그 기록
- **NFR-SE-014**: 로그 최소 1년 보관, 위변조 방지

## 사용성 요구사항

### 학습 용이성
- **NFR-US-001**: 신규 사용자 2시간 내 핵심 기능 습득 가능
- **NFR-US-002**: 일관된 UI/UX 패턴 적용
- **NFR-US-003**: 명확한 도움말 및 사용자 매뉴얼 제공

### 효율성
- **NFR-US-004**: 반복 업무 기존 대비 50% 이상 시간 단축
- **NFR-US-005**: 주요 기능 2-3 클릭 내 접근
- **NFR-US-006**: 자동 완성, 기본값 제공으로 입력 효율 향상

### 오류 방지 및 처리
- **NFR-US-007**: 입력 오류 사전 검증 및 피드백
- **NFR-US-008**: 중요 작업 전 확인 메시지 표시
- **NFR-US-009**: 구체적이고 친절한 한국어 오류 메시지

## 오류 처리

### 데이터베이스 제약조건 오류
- 외래키 제약조건 위반 시 적절한 오류 메시지 제공
- 유니크 제약조건 위반 시 중복 데이터 안내
- NOT NULL 제약조건 위반 시 필수 필드 안내

### 비즈니스 로직 오류
- 계약 기간 중복 검증
- 임대료 연체 계산 오류 처리
- 권한 부족 시 접근 제한

### 시스템 오류
- 데이터베이스 연결 오류 처리
- 트랜잭션 롤백 처리
- 동시성 제어 오류 처리

## 테스트 전략

### 단위 테스트
- Repository 레이어 테스트 (H2 인메모리 DB 사용)
- Service 레이어 비즈니스 로직 테스트
- Entity 검증 로직 테스트
- Kotest 5.4.2 및 SpringMockK 4.0.2 활용

### 통합 테스트
- API 엔드포인트 테스트 (REST Assured 5.3.0 사용)
- 데이터베이스 트랜잭션 테스트
- 권한 검증 테스트
- 외부 서비스 연동 테스트

### 성능 테스트
- 대용량 데이터 조회 성능 테스트 (JMeter 활용)
- 복잡한 쿼리 성능 최적화 테스트
- 동시 접근 처리 테스트 (부하 테스트)
- 메모리 사용량 및 CPU 사용률 모니터링

### 보안 테스트
- 정적/동적 코드 분석
- 모의 해킹 테스트
- OWASP ZAP 취약점 스캐닝
- 권한 우회 시도 테스트

### 사용성 테스트
- 사용자 관찰 및 인터뷰
- 휴리스틱 평가
- A/B 테스트 (필요시)
- 사용자 만족도 설문조사

### 데이터 무결성 테스트
- 외래키 제약조건 테스트
- 비즈니스 규칙 검증 테스트
- 감사 로그 기능 테스트
- 백업 및 복구 테스트