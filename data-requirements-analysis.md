# QIRO 건물 관리 시스템 데이터 요구사항 분석 및 정의

## 1. 개요

본 문서는 QIRO 건물 관리 SaaS의 6개 기능 영역별 데이터 요구사항을 상세히 분석하고, 엔티티 식별 및 속성 정의, 데이터 흐름 및 생명주기를 분석한 결과를 정리합니다.

## 2. 전체 시스템 기능 아키텍처 기반 데이터 요구사항

### 2.1. 6개 기능 영역 분류

QIRO 시스템은 다음 6개 기능 영역으로 구성됩니다:

1. **기초 정보 및 정책 관리** (Foundation & Policy)
2. **월별 관리비 처리 워크플로우** (Monthly Billing Workflow)
3. **임대차 관리 워크플로우** (Lease Management Workflow)
4. **시설 유지보수 관리 워크플로우** (Facility Maintenance Workflow)
5. **운영 및 고객 관리** (Operations & Customer)
6. **시스템 및 데이터 관리** (System & Data)

## 3. 기능 영역별 데이터 요구사항 분석

### 3.1. 기초 정보 및 정책 관리 도메인

#### 3.1.1. 핵심 엔티티
- **Building** (건물): 건물 기본 정보 관리
- **Unit** (호실): 임대 가능한 공간 정보
- **Lessor** (임대인): 건물/호실 소유주 정보
- **Tenant** (임차인): 임차인/세대주 정보
- **FeeItem** (관리비 항목): 정기 관리비 항목 마스터
- **ExternalBillAccount** (외부 고지서 계정): 한전, 수도 등 외부 기관 계정
- **PaymentPolicy** (납부 정책): 관리비 수납 정책

#### 3.1.2. 데이터 흐름
1. 건물 등록 → 호실 정보 등록 → 임대인/임차인 정보 등록
2. 관리비 항목 설정 → 외부 고지서 계정 연결 → 납부 정책 설정
3. 기초 정보는 다른 모든 워크플로우의 기반 데이터로 활용

#### 3.1.3. 주요 데이터 속성
- **Building**: buildingId(PK), buildingName, address, buildingType, totalUnitCount, totalFloorArea
- **Unit**: unitId(PK), buildingId(FK), unitNumber, floor, exclusiveArea, currentStatus
- **FeeItem**: feeItemId(PK), itemName, impositionMethod, unitPrice, isVatApplicable, isActive

### 3.2. 월별 관리비 처리 워크플로우 도메인

#### 3.2.1. 핵심 엔티티
- **BillingMonth** (청구월): 관리비 작업 컨텍스트
- **UnitMeterReading** (검침 데이터): 개별 호실 검침값
- **MonthlyExternalBillAmount** (외부 고지서 금액): 월별 외부 고지서 총액
- **UnitMonthlyFee** (월별 관리비): 산정된 관리비 결과
- **Invoice** (고지서): 발급된 고지서
- **PaymentRecord** (수납 내역): 납부 처리 기록
- **DelinquencyRecord** (미납 관리): 미납 및 연체료 관리

#### 3.2.2. 데이터 흐름 (월별 워크플로우)
1. 청구월 생성 → 검침 데이터 입력 → 외부 고지서 금액 입력
2. 관리비 자동 산정 → 고지서 발급 → 수납 처리
3. 미납 관리 → 연체료 계산 → 다음 달 이월

#### 3.2.3. 주요 데이터 속성
- **BillingMonth**: billingMonthId(PK), year, month, status, paymentDueDate
- **UnitMeterReading**: readingId(PK), billingMonthId(FK), unitId(FK), utilityType, currentReading, usageAmount
- **UnitMonthlyFee**: unitMonthlyFeeId(PK), billingMonthId(FK), unitId(FK), finalAmountDue, paidAmount, paymentStatus

### 3.3. 임대차 관리 워크플로우 도메인

#### 3.3.1. 핵심 엔티티
- **LeaseContract** (임대 계약): 임대 계약 정보
- **MonthlyRent** (임대료 관리): 월별 임대료 청구 및 납부
- **MoveOutSettlement** (퇴실 정산): 입주/퇴실 시 정산 처리

#### 3.3.2. 데이터 흐름
1. 계약 체결 → 월별 임대료 청구 → 납부 처리
2. 계약 만료/해지 → 퇴실 정산 → 보증금 반환

#### 3.3.3. 주요 데이터 속성
- **LeaseContract**: contractId(PK), unitId(FK), lessorId(FK), tenantId(FK), startDate, endDate, depositAmount, rentAmount, status
- **MonthlyRent**: rentId(PK), contractId(FK), rentYear, rentMonth, rentAmount, paymentStatus

### 3.4. 시설 유지보수 관리 워크플로우 도메인

#### 3.4.1. 핵심 엔티티
- **Facility** (시설물): 건물 내 시설물 정보
- **MaintenanceRequest** (유지보수 요청): 유지보수 요청 접수
- **MaintenanceWork** (유지보수 작업): 실제 수행된 작업 기록
- **FacilityVendor** (협력업체): 시설 관리 협력업체

#### 3.4.2. 데이터 흐름
1. 시설물 등록 → 정기 점검 일정 → 점검 수행
2. 유지보수 요청 → 업체 배정 → 작업 수행 → 결과 기록

#### 3.4.3. 주요 데이터 속성
- **Facility**: facilityId(PK), buildingId(FK), facilityName, facilityType, lastMaintenanceDate, nextMaintenanceDate
- **MaintenanceWork**: workId(PK), facilityId(FK), vendorId(FK), workDate, workType, cost, status

### 3.5. 운영 및 고객 관리 도메인

#### 3.5.1. 핵심 엔티티
- **Complaint** (민원): 입주민 민원 관리
- **Announcement** (공지사항): 공지사항 게시
- **Notification** (알림): 시스템 알림 관리

#### 3.5.2. 데이터 흐름
1. 민원 접수 → 담당자 배정 → 처리 → 완료
2. 공지사항 작성 → 대상자 선정 → 발송 → 읽음 확인

#### 3.5.3. 주요 데이터 속성
- **Complaint**: complaintId(PK), buildingId(FK), unitId(FK), complainantName, complaintType, status
- **Announcement**: announcementId(PK), title, content, targetAudience, publishedAt

### 3.6. 시스템 및 데이터 관리 도메인

#### 3.6.1. 핵심 엔티티
- **User** (사용자): 시스템 사용자 계정
- **Role** (역할): 사용자 역할 정의
- **JournalEntry** (회계 전표): 회계 처리 기록
- **AuditLog** (감사 로그): 시스템 변경 이력
- **OrganizationSetting** (시스템 설정): 조직별 환경 설정

#### 3.6.2. 데이터 흐름
1. 사용자 등록 → 역할 부여 → 권한 관리
2. 업무 처리 → 회계 전표 생성 → 재무제표 작성
3. 시스템 사용 → 감사 로그 기록 → 추적성 보장

#### 3.6.3. 주요 데이터 속성
- **User**: userId(PK), username, email, roleId(FK), isActive
- **JournalEntry**: entryId(PK), entryDate, description, totalDebit, totalCredit
- **AuditLog**: logId(PK), tableName, recordId, action, changedBy, changedAt

## 4. 엔티티 간 관계 분석

### 4.1. 핵심 관계
1. **Building (1) ↔ (N) Unit**: 건물은 여러 호실을 포함
2. **Unit (1) ↔ (N) LeaseContract**: 호실은 시간에 따라 여러 계약 보유
3. **BillingMonth (1) ↔ (N) UnitMonthlyFee**: 청구월별 세대 관리비 산정
4. **Unit (1) ↔ (N) UnitMeterReading**: 호실별 월별 검침 데이터
5. **Facility (1) ↔ (N) MaintenanceWork**: 시설물별 유지보수 작업 이력

### 4.2. 참조 무결성 제약조건
- 외래키 관계에서 ON DELETE RESTRICT/CASCADE 정책 적용
- 중요 마스터 데이터는 RESTRICT, 종속 데이터는 CASCADE
- 순환 참조 방지 (예: LeaseContract.parentContractId)

## 5. 데이터 생명주기 분석

### 5.1. 마스터 데이터 생명주기
- **Building, Unit**: 시스템 초기 설정 시 생성, 변경 빈도 낮음
- **Lessor, Tenant**: 계약 체결 시 생성, 정보 변경 시 업데이트
- **FeeItem**: 관리비 정책 변경 시 생성/수정, 이력 관리 필요

### 5.2. 트랜잭션 데이터 생명주기
- **BillingMonth**: 매월 생성 → 데이터 입력 → 산정 → 고지 → 수납 → 마감
- **LeaseContract**: 계약 체결 → 활성 → 만료 예정 → 만료/갱신
- **MaintenanceWork**: 요청 → 배정 → 진행 → 완료

### 5.3. 이력 데이터 관리
- **AuditLog**: 모든 중요 데이터 변경 시 자동 생성
- **PaymentRecord**: 수납 처리 시 생성, 취소 불가 원칙
- **DelinquencyRecord**: 미납 발생 시 생성, 완납 시 해결 상태로 변경

## 6. 데이터 품질 및 무결성 요구사항

### 6.1. 비즈니스 규칙
- **R-DB-001**: 건물 내 호실 번호 고유성 보장
- **R-DB-002**: 계약 기간 중복 방지 (동일 호실)
- **R-DB-003**: 관리비 산정 시 차변/대변 합계 일치
- **R-DB-004**: 임대료 연체 계산 시 정책 적용
- **R-DB-005**: 감사 로그 필수 기록 대상 정의

### 6.2. 데이터 검증 규칙
- 필수 필드 NOT NULL 제약
- 금액 필드 양수 제약 (CHECK 제약)
- 날짜 필드 논리적 순서 제약 (시작일 ≤ 종료일)
- 상태 필드 ENUM 값 제약

### 6.3. 참조 무결성
- 모든 외래키 관계에 대한 참조 무결성 보장
- 삭제 시 종속 데이터 처리 정책 (CASCADE/RESTRICT)
- 고아 레코드 방지

## 7. 성능 및 확장성 고려사항

### 7.1. 대용량 데이터 처리
- 월별 데이터 파티셔닝 (BillingMonth 기준)
- 이력 데이터 아카이빙 전략
- 인덱스 최적화 (조회 패턴 기반)

### 7.2. 동시성 제어
- 관리비 산정 시 동시 수정 방지
- 수납 처리 시 중복 방지
- 계약 등록 시 호실 상태 동기화

## 8. 보안 및 개인정보 보호

### 8.1. 개인정보 암호화
- 임대인/임차인 연락처, 주소 암호화
- 계좌번호 등 금융정보 암호화
- 사업자등록번호 등 식별정보 보호

### 8.2. 접근 제어
- 역할 기반 접근 제어 (RBAC)
- 건물별 데이터 격리
- 감사 로그를 통한 접근 추적

## 9. 결론

QIRO 시스템의 데이터 요구사항 분석 결과, 6개 기능 영역을 지원하기 위해 약 30여 개의 핵심 엔티티가 필요하며, 이들 간의 복잡한 관계와 비즈니스 규칙을 데이터베이스 설계에 반영해야 합니다. 

특히 월별 관리비 처리 워크플로우의 데이터 흐름이 가장 복잡하며, 이를 중심으로 한 데이터 모델링이 시스템 성공의 핵심 요소가 될 것입니다.

다음 단계에서는 이 분석 결과를 바탕으로 데이터베이스 설계 표준 및 명명 규칙을 수립하고, 구체적인 ERD와 DDL을 작성할 예정입니다.