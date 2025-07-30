
## 📋 QIRO 서비스 주요 엔티티 및 속성 정리 (초안)

*(참고: 아래 엔티티명과 속성명은 이해를 돕기 위한 예시이며, 실제 물리 설계 시 DB 명명 규칙(예: snake_case)에 따라 변경될 수 있습니다. 데이터 타입은 일반적인 논리적 타입을 우선 명시합니다.)*

### 1. 사용자 및 접근 관리 (User & Access Management)

#### 1.1. `InternalUser` (내부 사용자/직원 계정)

- `userId` (PK, 고유 ID, UUID/Long) - 사용자 고유 식별자
- `email` (문자열, 고유) - 로그인 ID로 사용될 이메일 주소
- `passwordHash` (문자열) - 해시된 비밀번호
- `name` (문자열) - 사용자 이름
- `department` (문자열, 선택) - 소속 부서
- `position` (문자열, 선택) - 직책
- `contactNumber` (문자열, 선택) - 연락처
- `status` (Enum: `ACTIVE`, `INACTIVE`, `LOCKED`) - 계정 상태
- `mfaEnabled` (Boolean) - 2단계 인증(MFA) 사용 여부
- `lastLoginAt` (날짜시간, 선택) - 최근 로그인 일시
- `createdAt` (날짜시간) - 생성 일시
- `createdBy` (문자열/User ID) - 생성자
- `lastModifiedAt` (날짜시간) - 최종 수정 일시
- `lastModifiedBy` (문자열/User ID) - 최종 수정자

#### 1.2. `Role` (역할)

- `roleId` (PK, 고유 ID, UUID/ShortText) - 역할 고유 식별자 (예: `SUPER_ADMIN`, `BUILDING_MGR`)
- `roleName` (문자열, 고유) - 역할명 (예: 총괄관리자, 관리소장)
- `description` (문자열, 선택) - 역할 설명
- `isSystemRole` (Boolean) - 시스템 기본 제공 역할 여부 (수정/삭제 제한)

#### 1.3. `Permission` (권한 - 마스터 데이터)

- `permissionId` (PK, 고유 ID, UUID/ShortText) - 권한 고유 식별자 (예: `BLDG_CREATE`, `FEE_CALCULATE`)
- `permissionName` (문자열, 고유) - 권한명 (예: 건물 정보 생성, 관리비 계산 실행)
- `description` (문자열, 선택) - 권한 상세 설명
- `category` (문자열, 선택) - 권한 그룹/카테고리 (예: 건물관리, 관리비관리)

#### 1.4. `UserRoleLink` (사용자-역할 매핑, M:N)

- `userId` (FK from `InternalUser`, PK) - 사용자 ID
- `roleId` (FK from `Role`, PK) - 역할 ID

#### 1.5. `RolePermissionLink` (역할-권한 매핑, M:N)

- `roleId` (FK from `Role`, PK) - 역할 ID
- `permissionId` (FK from `Permission`, PK) - 권한 ID

#### 1.6. `UserBuildingAccess` (사용자-담당건물 매핑, M:N - 선택적)

- `userId` (FK from `InternalUser`, PK) - 사용자 ID
- `buildingId` (FK from `Building`, PK) - 건물 ID

### 2. 건물 및 호실 정보 관리 (Building & Unit Information Management)

#### 2.1. `Building` (건물)

- `buildingId` (PK, 고유 ID, UUID/Long) - 건물 고유 식별자
- `buildingName` (문자열) - 건물명
- `addressZipCode` (문자열) - 우편번호
- `addressStreet` (문자열) - 도로명/지번 주소
- `addressDetail` (문자열, 선택) - 상세 주소
- `buildingTypeCode` (문자열, FK/Enum) - 건물 유형 코드 (예: `APT`, `OFFICETEL`, `COMMERCIAL`)
- `totalDongCount` (정수, 선택) - 총 동 수
- `totalUnitCount` (정수) - 총 세대(호실) 수
- `totalFloorArea` (숫자, 선택) - 연면적 (㎡)
- `completionDate` (날짜, 선택) - 준공일
- `managementStartDate` (날짜) - QIRO 시스템 관리 시작일
- `status` (Enum: `ACTIVE`, `INACTIVE`, `PREPARING_MGMT`) - 건물 관리 상태
- `mainImageKey` (문자열, 선택) - 대표 이미지 S3 Key 또는 URL
- `lessorId` (FK from `Lessor`, 선택) - 주 건물 소유주 ID (단일 소유주 건물인 경우)
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드: `createdAt`, `createdBy`, `lastModifiedAt`, `lastModifiedBy`)

#### 2.2. `BuildingDong` (건물 동 - 선택적)

- `dongId` (PK, 고유 ID, UUID/Long) - 동 고유 식별자
- `buildingId` (FK from `Building`) - 소속 건물 ID
- `dongName` (문자열) - 동 명칭 (예: 101동, A동)
- `numberOfFloors` (정수, 선택) - 해당 동의 총 층수 (지상/지하 별도 가능)
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 2.3. `Unit` (호실/세대)

- `unitId` (PK, 고유 ID, UUID/Long) - 호실 고유 식별자
- `buildingId` (FK from `Building`) - 소속 건물 ID
- `dongId` (FK from `BuildingDong`, 선택) - 소속 동 ID
- `unitNumber` (문자열) - 호실 번호 (예: 101, B203)
- `floor` (정수 또는 문자열) - 소재 층 (예: 10, "B1")
- `unitTypeCode` (문자열, FK/Enum) - 호실 유형 코드 (예: `RES_APT_84` (주거용아파트84㎡), `OFFICE_A` (사무실A타입))
- `exclusiveArea` (숫자) - 전용 면적 (㎡)
- `contractArea` (숫자, 선택) - 계약 면적 (㎡)
- `currentStatus` (Enum: `VACANT`, `LEASED`, `UNDER_REPAIR`, `NOT_FOR_LEASE`) - 현재 호실 상태 (임대 계약과 연동)
- `currentLessorId` (FK from `Lessor`, 선택) - 현재 연결된 주 임대인 ID
- `currentTenantId` (FK from `Tenant`, 선택) - 현재 연결된 주 임차인 ID (임대중일 경우)
- `currentLeaseContractId` (FK from `LeaseContract`, 선택) - 현재 유효한 임대 계약 ID
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 2.4. `BuildingCommonFacility` (건물 공용 시설 - 선택적)

- `commonFacilityId` (PK, 고유 ID, UUID/Long) - 공용시설 고유 식별자
- `buildingId` (FK from `Building`) - 소속 건물 ID
- `facilityName` (문자열) - 공용시설명 (예: 지하주차장, 1층 로비, 헬스장)
- `location` (문자열, 선택) - 위치 상세
- `description` (문자열, 선택) - 설명 및 비고
- ... (감사 필드)

### 3. 임대인 및 임차인 관리 (Lessor & Tenant Management)

#### 3.1. `Lessor` (임대인)

- `lessorId` (PK, 고유 ID, UUID/Long) - 임대인 고유 식별자
- `lessorType` (Enum: `INDIVIDUAL`, `CORPORATION`, `SOLE_PROPRIETOR`) - 임대인 구분
- `name` (문자열) - 임대인명 또는 법인명
- `representativeName` (문자열, 선택) - 대표자명 (법인/개인사업자 시)
- `businessNumber` (문자열, 선택, 고유(정책)) - 사업자등록번호
- `contactNumber` (문자열) - 주 연락처
- `email` (문자열, 선택) - 이메일 주소
- `addressZipCode` (문자열, 선택)
- `addressStreet` (문자열, 선택)
- `addressDetail` (문자열, 선택)
- `status` (Enum: `ACTIVE`, `INACTIVE`) - 임대인 관리 상태 (예: QIRO 관리 회사와의 계약 상태)
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 3.2. `LessorPropertyLink` (임대인-소유자산 연결, M:N)

- `linkId` (PK, 고유 ID)
- `lessorId` (FK from `Lessor`)
- `buildingId` (FK from `Building`)
- `unitId` (FK from `Unit`, 선택) - 특정 호실 소유 시
- `ownershipStartDate` (날짜) - 소유(또는 관리 위탁) 시작일
- `ownershipEndDate` (날짜, 선택) - 소유(또는 관리 위탁) 종료일
- ... (감사 필드)

#### 3.3. `LessorBankAccount` (임대인 정산 계좌, Lessor에 1:N)

- `bankAccountId` (PK, 고유 ID)
- `lessorId` (FK from `Lessor`)
- `bankName` (문자열) - 은행명
- `accountNumber` (문자열) - 계좌번호 (암호화 저장)
- `accountHolderName` (문자열) - 예금주명
- `isPrimary` (Boolean) - 주 사용 계좌 여부
- `purpose` (문자열, 선택) - 계좌 용도
- `isActive` (Boolean) - 사용 여부
- ... (감사 필드)

#### 3.4. `Tenant` (임차인/세대주)

- `tenantId` (PK, 고유 ID, UUID/Long) - 임차인 고유 식별자
- `name` (문자열) - 임차인명 (개인 또는 사업체명)
- `contactNumber` (문자열) - 주 연락처
- `email` (문자열, 선택) - 이메일 주소
- `status` (Enum: `RESIDING`, `MOVING_OUT_SCHEDULED`, `MOVED_OUT`, `CONTRACT_PENDING`) - 임차인 상태
- `emergencyContactName` (문자열, 선택) - 비상 연락처 이름
- `emergencyContactRelation` (문자열, 선택) - 비상 연락처 관계
- `emergencyContactNumber` (문자열, 선택) - 비상 연락처 번호
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 3.5. `TenantVehicle` (임차인 차량 정보, Tenant에 1:N)

- `vehicleId` (PK, 고유 ID)
- `tenantId` (FK from `Tenant`)
- `vehicleNumber` (문자열) - 차량 번호
- `vehicleModel` (문자열, 선택) - 차종
- `remarks` (문자열, 선택) - 비고 (예: 주 사용 차량, 방문 차량 구분)
- ... (감사 필드)

### 4. 임대 계약 관리 (Lease Contract Management)

#### 4.1. `LeaseContract` (임대 계약)

- `contractId` (PK, 고유 ID, UUID/Long) - 계약 고유 식별자
- `unitId` (FK from `Unit`) - 임대 대상 호실 ID
- `lessorId` (FK from `Lessor`) - 임대인 ID
- `tenantId` (FK from `Tenant`) - 임차인 ID
- `contractNumber` (문자열, 선택, 고유(정책)) - 계약 관리 번호
- `contractDate` (날짜) - 계약 체결일
- `startDate` (날짜) - 계약 시작일 (실제 입주일과 다를 수 있음)
- `endDate` (날짜) - 계약 종료일
- `depositAmount` (숫자) - 보증금
- `rentAmount` (숫자) - 월 임대료 (또는 해당 주기 임대료)
- `rentPaymentCycle` (Enum: `MONTHLY`, `QUARTERLY`, `YEARLY_PREPAID`) - 임대료 납부 주기
- `rentPaymentDay` (정수 또는 문자열) - 임대료 납부일 (예: 25, "LAST_DAY")
- `maintenanceFeeCondition` (Enum: `INCLUDED_IN_RENT`, `SEPARATE_BILLING`, `FIXED_AMOUNT`) - 관리비 조건
- `maintenanceFeeAmount` (숫자, 선택) - 고정 관리비 금액 (위 조건이 `FIXED_AMOUNT`일 경우)
- `specialClauses` (텍스트, 선택) - 특약 사항
- `brokerInfo` (문자열, 선택) - 중개사 정보
- `status` (Enum: `SCHEDULED`, `ACTIVE`, `EXPIRING_SOON`, `EXPIRED`, `TERMINATED`, `RENEWED`) - 계약 상태
- `parentContractId` (FK from `LeaseContract`, Self, 선택) - 갱신 계약의 경우 이전 계약 ID
- `terminationDate` (날짜, 선택) - (중도)해지일
- `terminationReason` (문자열, 선택) - 해지 사유
- ... (감사 필드)

#### 4.2. `ContractAttachment` (계약 첨부파일, LeaseContract에 1:N)

- `attachmentId` (PK, 고유 ID)
- `contractId` (FK from `LeaseContract`)
- `fileName` (문자열) - 파일 원본명
- `fileKeyOrPath` (문자열) - S3 Key 또는 저장 경로
- `fileSize` (Long) - 파일 크기
- `fileType` (문자열) - 파일 MIME 타입
- `uploadedAt` (날짜시간) - 업로드 일시
- ... (감사 필드)

### 5. 관리비 설정 (Fee Item & Policy Setup)

#### 5.1. `FeeItem` (관리비 부과 항목 마스터)

- `feeItemId` (PK, 고유 ID, UUID/Long) - 관리비 항목 고유 식별자
- `itemName` (문자열) - 항목명 (예: 일반관리비, 청소비)
- `itemCategory` (Enum/String, 선택) - 항목 대분류 (예: `COMMON_FEE`, `INDIVIDUAL_FEE`, `OTHER_LEVY`)
- `impositionMethod` (Enum/String) - 부과(배분) 방식 코드 (예: `FIXED_AMOUNT_PER_UNIT`, `PER_AREA_RATE`, `TOTAL_COMMON_PER_AREA`, `TOTAL_COMMON_PER_UNIT_EQUAL`)
- `calculationBasisType` (Enum/String, 선택) - `impositionMethod`이 `PER_AREA_RATE`일 경우 기준 면적 유형 (예: `EXCLUSIVE_AREA`, `CONTRACT_AREA`)
- `defaultUnitPrice` (숫자, 선택) - 기본 단가 (만약 `impositionMethod`이 단가 기반일 경우)
- `defaultUnit` (문자열, 선택) - 기본 단위 (예: 원/세대, 원/㎡)
- `isVatApplicable` (Boolean) - 부가세 적용 여부 (기본값)
- `description` (문자열, 선택) - 항목 설명
- `isActive` (Boolean) - 사용 여부 (마스터 항목의 활성 상태)
- `isSystemDefault` (Boolean) - 시스템 기본 제공 항목 여부 (사용자 수정/삭제 제한)
- ... (감사 필드: `createdAt`, `createdBy`, `lastModifiedAt`, `lastModifiedBy`)

#### 5.2. `ExternalBillAccount` (외부 고지서 계정 정보)

- `extBillAccountId` (PK, 고유 ID, UUID/Long) - 외부 고지서 계정 고유 식별자
- `customerNumber` (문자열) - 공급자가 부여한 고객번호/납부자번호
- `utilityType` (Enum/String) - 공과금 종류 (예: `ELECTRICITY`, `WATER`, `GAS`, `HEATING`)
- `supplierName` (문자열) - 공급자명
- `buildingId` (FK from `Building`) - 연결된 건물 ID
- `accountNickname` (문자열) - 계정 별칭 (사용자 식별용)
- `meterNumber` (문자열, 선택) - 관련 대표 계량기 번호
- `isForIndividualUsage` (Boolean) - 개별 사용료 청구 용도 여부
- `isForCommonUsage` (Boolean) - 공용 사용료 청구 용도 여부
- `remarks` (문자열, 선택) - 메모
- `isActive` (Boolean) - 활성 여부
- ... (감사 필드)

#### 5.3. `BillToFeeItemLink` (외부 고지서-관리비 항목 연결 및 배분 규칙)

- `linkId` (PK, 고유 ID, UUID/Long) - 연결 배분 규칙 고유 ID
- `extBillAccountId` (FK from `ExternalBillAccount`) - 외부 고지서 계정 ID
- `feeItemId` (FK from `FeeItem`) - 연결될 관리비 항목 ID
- `description` (문자열, 선택) - 이 배분 규칙에 대한 설명
- `allocationType` (Enum/String) - 금액 할당 방식 (`ENTIRE_BILL_AMOUNT`, `PORTION_FROM_BILL_AMOUNT`)
- `portionValueType` (Enum/String, 선택) - 부분 할당 유형 (`FIXED_AMOUNT`, `PERCENTAGE`, `REMAINDER`)
- `portionValue` (숫자, 선택) - 부분 할당 값 (금액 또는 %)
- `processingOrder` (정수) - 동일 고지서 내 배분 규칙 처리 순서
- `isActive` (Boolean) - 이 연결 규칙의 활성 여부
- ... (감사 필드)

#### 5.4. `ReceivingBankAccount` (관리비 수납 계좌)

- `accountId` (PK, 고유 ID, UUID/Long) - 수납 계좌 고유 식별자
- `bankName` (문자열) - 은행명
- `accountNumber` (문자열) - 계좌번호 (암호화 저장)
- `accountHolder` (문자열) - 예금주명
- `purpose` (문자열, 선택) - 계좌 용도
- `isDefault` (Boolean) - 기본 수납 계좌 여부
- `isActive` (Boolean) - 사용 여부
- ... (감사 필드)

#### 5.5. `PaymentPolicy` (납부 정책 - 시스템 또는 사업장 단위 설정)

- `policyId` (PK, 고유 ID, (보통 단일 레코드))
- `paymentDueDay` (정수 또는 문자열) - 매월 납부 마감일 (예: 25, "LAST_DAY")
- `lateFeeRate` (숫자) - 연체료율 (%)
- `lateFeeCalculationMethod` (Enum/String, 선택) - 연체료 계산 방식 (예: `DAILY_SIMPLE`, `MONTHLY_COMPOUND`)
- `roundingPolicy` (Enum/String, 선택) - 금액 반올림/절사 정책
- ... (감사 필드)

### 6. 청구월 및 월별 데이터 관리 (Billing Month & Monthly Data Management)

#### 6.1. `BillingMonth` (청구월)

- `billingMonthId` (PK, 고유 ID, UUID/Long) - 청구월 고유 식별자
- `year` (정수) - 대상 연도 (YYYY)
- `month` (정수) - 대상 월 (1-12)
- `status` (Enum: `PREPARING`, `IN_PROGRESS`, `COMPLETED`) - 청구월 상태
- `description` (문자열, 선택) - 해당 청구월에 대한 설명 또는 메모
- `startDate` (날짜) - 청구 기간 시작일 (보통 해당월 1일)
- `endDate` (날짜) - 청구 기간 종료일 (보통 해당월 말일)
- `paymentDueDate` (날짜) - 이 청구월의 납부 마감일 (`PaymentPolicy` 기반으로 생성 시 설정)
- `closedDate` (날짜, 선택) - 마감 처리 일자 (`status`가 `COMPLETED`일 때)
- ... (감사 필드)

#### 6.2. `BillingMonthFeeItemSetting` (청구월별 항목 설정값)

- `settingId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `feeItemId` (FK from `FeeItem`)
- `unitPrice` (숫자, 선택) - 해당 청구월에 적용될 단가 (또는 고정액/총액)
- `rate` (숫자, 선택) - 해당 청구월에 적용될 요율
- `isVatApplicable` (Boolean) - 해당 청구월에 이 항목 부가세 적용 여부 (마스터 우선, 변경 가능)
- `dataSource` (Enum/String) - 이 설정값의 출처 (예: `MASTER_DEFAULT`, `PREVIOUS_MONTH_CONFIRMED`, `MANUAL_INPUT`)
- `isConfirmedByPrevious` (Boolean, 선택) - 이전달 '완료' 후 확정된 값으로 업데이트 되었는지 여부
- ... (감사 필드)

#### 6.3. `UnitMonthlyPreviousMeterReading` (청구월 세대별 전월 기준 검침값)

- `prevReadingId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `unitId` (FK from `Unit`)
- `utilityTypeCode` (문자열, FK/Enum) - 검침 항목 코드 (예: `ELEC_I`, `WATER_I`)
- `meterReadingValue` (숫자) - 이 청구월의 시작(전월) 검침값
- `dataSource` (Enum/String) - 이 검침값의 출처 (예: `PREVIOUS_COMPLETED_READING`, `MANUAL_INPUT`)
- ... (감사 필드)

#### 6.4. `UnitMonthlyUnpaidAmount` (청구월 세대별 전월 미납액)

- `unpaidId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `unitId` (FK from `Unit`)
- `unpaidAmount` (숫자) - 해당 청구월에 이월된 전월 미납 총액 (연체료 포함 가능)
- `dataSource` (Enum/String) - 이 미납액의 출처 (예: `PREVIOUS_COMPLETED_UNPAID`, `UNSETTLED_INITIAL`)
- ... (감사 필드)

#### 6.5. `CommonFacilityMonthlyReading` (공용 시설 월별 검침)

- `commonReadingId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `facilityId` (FK from `Facility` - 공용 계량기 시설물 ID)
- `utilityType` (Enum/String) - 공과금 종류
- `readingDate` (날짜) - 검침일
- `previousMeterReading` (숫자) - 전월 지침
- `currentMeterReading` (숫자) - 당월 지침
- `usageCalculated` (숫자) - 계산된 사용량
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 6.6. `UnitMonthlyMeterReading` (개별 호실 월별 검침)

- `unitReadingId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `unitId` (FK from `Unit`)
- `utilityTypeCode` (문자열, FK/Enum) - 공과금 항목 코드
- `readingDate` (날짜) - 검침일
- `previousMeterReading` (숫자) - 전월 지침
- `currentMeterReading` (숫자) - 당월 지침
- `usageCalculated` (숫자) - 계산된 사용량
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 6.7. `MonthlyExternalBillAmount` (월별 외부 고지서 청구 금액)

- `monthlyExtBillAmountId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `extBillAccountId` (FK from `ExternalBillAccount`)
- `totalBilledAmount` (숫자) - 해당 고객번호로 청구된 해당 월 총액
- `commonUsageAllocatedAmount` (숫자, 선택) - 위 총액 중 공용 사용료로 배분(지정)된 금액
- `individualUsagePoolAmount` (숫자, 선택) - 위 총액 중 개별 사용료 풀로 배분(지정)된 금액
- `billStatementFileKey` (문자열, 선택) - 고지서 스캔 파일 S3 Key
- `remarks` (문자열, 선택) - 비고
- `entryDate` (날짜시간) - 금액 입력/수정일
- ... (감사 필드)

#### 6.8. `MonthlyCommonFee` (월별 공용 관리비 - 검침 외 항목 직접 입력)

- `monthlyCommonFeeId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `feeItemId` (FK from `FeeItem` - 공용 관리비 항목)
- `totalAmountForMonth` (숫자) - 해당 청구월에 발생한 해당 항목의 총 금액
- `description` (문자열, 선택) - 설명
- `attachedFileReferences` (JSON/String, 선택) - 증빙 파일 참조
- ... (감사 필드)

### 7. 관리비 정산 및 고지/수납 (Fee Calculation, Invoicing, Payment)

#### 7.1. `UnitMonthlyFee` (월별 세대 관리비 - 계산 결과 총괄)

- `unitMonthlyFeeId` (PK, 고유 ID, UUID/Long)
- `billingMonthId` (FK from `BillingMonth`)
- `unitId` (FK from `Unit`)
- `totalFeeForUnitBeforeAdjustments` (숫자) - 순수 당월 관리비 항목 합계 (부가세 포함)
- `previousUnpaidAmountApplied` (숫자, 선택) - 적용된 전월 미납액
- `lateFeeApplied` (숫자, 선택) - 적용된 연체료
- `adjustmentsTotal` (숫자, 선택) - 기타 가감액 합계
- `finalAmountDue` (숫자) - 최종 납부 요청 금액
- `paidAmount` (숫자) - 현재까지 납부된 금액 (초기값 0, `PaymentRecord` 합계로 업데이트)
- `currentUnpaidBalance` (숫자) - 현재 미납 잔액 (`finalAmountDue - paidAmount`)
- `paymentStatus` (Enum: `UNPAID`, `PARTIALLY_PAID`, `FULLY_PAID`, `OVERDUE`) - 납부 상태
- `calculationStatus` (Enum: `SUCCESS`, `ERROR`) - 산정 상태
- `calculationLog` (텍스트, 선택) - 산정 관련 로그 또는 오류 메시지
- `confirmedBy` (문자열/User ID, 선택) - 관리비 산정 확정자 ID
- `confirmedAt` (날짜시간, 선택) - 관리비 산정 확정 일시
- ... (감사 필드)

#### 7.2. `UnitFeeDetail` (세대별 월별 관리비 상세 항목)

- `unitFeeDetailId` (PK, 고유 ID, UUID/Long)
- `unitMonthlyFeeId` (FK from `UnitMonthlyFee`)
- `feeItemId` (FK from `FeeItem`)
- `itemName` (문자열) - (FeeItem 정보 복사 또는 참조) 항목명
- `calculationBasis` (문자열, 선택) - 산출근거 (예: 100kWh * 120원/kWh)
- `amountBeforeVat` (숫자) - 항목별 금액 (부가세 제외)
- `vatAmount` (숫자) - 항목별 부가세액
- `totalAmountWithVat` (숫자) - 항목별 합계 (부가세 포함)
- ... (감사 필드)

#### 7.3. `Invoice` (관리비 고지서)

- `invoiceId` (PK, 고유 ID, UUID/Long)
- `unitMonthlyFeeId` (FK from `UnitMonthlyFee`) - 이 고지서의 근거가 되는 월별 세대 관리비
- `billingMonthId` (FK from `BillingMonth`)
- `unitId` (FK from `Unit`)
- `tenantId` (FK from `Tenant`)
- `issueDate` (날짜) - 고지서 발급(생성)일
- `dueDate` (날짜) - 납부 기한일
- `totalAmountBilled` (숫자) - 해당 고지서의 총 청구 금액 (`UnitMonthlyFee.finalAmountDue`와 일치)
- `status` (Enum: `DRAFT`, `GENERATED`, `ISSUED`, `SENT_EMAIL`, `VIEWED_BY_TENANT`) - 고지서 상태
- `invoiceContentRef` (문자열, 선택) - 생성된 고지서 파일 참조 (S3 Key 등) 또는 데이터 자체
- `notifiedAt` (날짜시간, 선택) - 실제 입주민에게 통지된 일시
- ... (감사 필드)

#### 7.4. `PaymentRecord` (수납 이력)

- `paymentRecordId` (PK, 고유 ID, UUID/Long)
- `invoiceId` (FK from `Invoice`, 선택) - 관련 고지서 ID (또는 `unitMonthlyFeeId`)
- `unitId` (FK from `Unit`)
- `billingMonthId` (FK from `BillingMonth`) - 어느 달 부과분에 대한 수납인지
- `paymentDate` (날짜) - 실제 납부일
- `paidAmount` (숫자) - 납부된 금액
- `paymentMethod` (Enum/String) - 납부 수단 (예: `BANK_TRANSFER`, `CASH`, `CARD`)
- `payerName` (문자열, 선택) - 실제 납부자명
- `transactionDetails` (문자열, 선택) - 거래 관련 추가 정보
- `receivingBankAccountId` (FK from `ReceivingBankAccount`, 선택) - 입금된 QIRO측 수납 계좌 ID
- `remarks` (문자열, 선택) - 수납 관련 메모
- `isCancelled` (Boolean) - 취소된 수납 여부
- `processedBy` (문자열/User ID) - 처리자
- `processedAt` (날짜시간) - 처리(등록) 일시
- ... (감사 필드)

#### 7.5. `DelinquencyRecord` (미납/연체 기록)

- `delinquencyId` (PK, 고유 ID, UUID/Long)
- `targetLedgerId` (FK, 원본 청구/고지 ID - `InvoiceId` 또는 `UnitMonthlyFeeId`)
- `unitId` (FK from `Unit`)
- `tenantId` (FK from `Tenant`)
- `billingYearMonth` (문자열, YYYY-MM) - 미납 발생 청구 연월
- `originalAmountDue` (숫자) - 최초 미납 원금
- `currentUnpaidAmount` (숫자) - 현재 미납 잔액 (부분 수납 반영)
- `dueDate` (날짜) - 납부 마감일
- `overdueDays` (정수) - 연체 일수 (조회 시점 기준 자동 계산)
- `totalLateFeeApplied` (숫자) - 총 부과된 연체료
- `status` (Enum: `OVERDUE`, `LATE_FEE_APPLIED`, `REMINDER_SENT`, `RESOLVED`) - 미납 상태
- `lastReminderSentDate` (날짜, 선택) - 최종 독촉 알림 발송일
- ... (감사 필드)

#### 7.6. `LateFeeTransaction` (연체료 부과 이력)

- `lateFeeTxId` (PK, 고유 ID, UUID/Long)
- `delinquencyId` (FK from `DelinquencyRecord`) - 또는 `targetLedgerId`
- `calculationDate` (날짜) - 연체료 계산/부과일
- `lateFeeAmount` (숫자) - 해당 시점에 계산/부과된 연체료 금액
- `appliedRate` (숫자) - 적용된 연체료율 (%)
- `appliedPeriodDays` (정수) - 연체료 계산 대상 기간(일수)
- `remarks` (문자열, 선택) - 비고
- ... (감사 필드)

#### 7.7. `MoveOutSettlement` (이사 정산)

(이전 "이사 정산 기능 명세서"의 4.3절 엔티티 정의 내용 참조)

### 8. 시설 관리 (Facility Management)

(이전 "시설 점검 및 유지보수 관리 API 설계" 답변의 5.1, 5.2 DTO 및 관련 FRS의 엔티티 정의 내용 참조)

- `Facility` (시설물)
- `FacilityInspectionRecord` (시설물 점검 기록)
- `Vendor` (시설 관리 협력업체)
- `VendorContactPerson` (협력업체 담당자)
- `VendorContract` (협력업체 계약)
- `ServiceType` (시설 서비스 유형 마스터)

### 9. 민원 관리 (Complaint Management)

(이전 "민원 처리 관리 API 설계" 답변의 5.1 DTO 및 관련 FRS의 엔티티 정의 내용 참조)

- `Complaint` (민원)
- `ComplaintHistory` (민원 처리 이력)
- `ComplaintAttachment` (민원 첨부파일)
- `ComplaintTypeMaster` (민원 유형 마스터)

### 10. 회계 관리 (Accounting Management - High Level)

(이전 "회계 관리 API 설계" 답변의 5.1, 5.2 DTO 및 관련 FRS의 엔티티 정의 내용 참조)

- `ChartOfAccount` (계정과목)
- `JournalEntry` (전표)
- `JournalEntryLine` (분개 라인)

### 11. 알림 및 공지 (Notification & Announcement Management)

(이전 "알림 및 공지사항 관리 API 설계" 답변의 5.1~5.4 DTO 및 관련 FRS의 엔티티 정의 내용 참조)

- `Announcement` (공지사항)
- `SystemNotificationSetting` (시스템 알림 설정)
- `NotificationTemplate` (알림 템플릿)
- `NotificationLog` (알림 발송 이력)

### 12. 시스템 설정 (System Configuration)

(이전 "시스템 환경설정 API 설계" 답변의 5.1, 5.2 DTO 및 관련 FRS의 엔티티 정의 내용 참조)

- `SystemConfiguration` (Key-Value 또는 구조화된 설정 테이블) 또는 `OrganizationSetting`
- `CompanyProfile` (고객사 정보)

### 13. 공통/기타 (Common/Miscellaneous)

#### 13.1. `Attachment` (범용 첨부파일 - 선택적)

- `attachmentId` (PK, 고유 ID, UUID/Long)
- `relatedEntityType` (문자열) - 연결된 엔티티 유형 (예: `COMPLAINT`, `LEASE_CONTRACT`, `FACILITY_INSPECTION`)
- `relatedEntityId` (문자열/Long) - 연결된 엔티티의 PK 값
- `fileName` (문자열) - 원본 파일명
- `fileKeyOrPath` (문자열) - S3 Key 또는 저장 경로
- `fileSize` (Long) - 파일 크기 (bytes)
- `fileType` (문자열) - 파일 MIME 타입
- `description` (문자열, 선택) - 파일 설명
- `uploadedAt` (날짜시간) - 업로드 일시
- `uploadedBy` (문자열/User ID) - 업로더
- ... (감사 필드)

