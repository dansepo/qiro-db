# QIRO 데이터베이스 설계 표준 및 명명 규칙

## 1. 개요

본 문서는 QIRO 건물 관리 시스템의 PostgreSQL 17.5 기반 데이터베이스 설계를 위한 표준과 명명 규칙을 정의합니다. 일관성 있는 데이터베이스 구조와 유지보수성을 보장하기 위한 가이드라인을 제시합니다.

## 2. 데이터베이스 설계 원칙

### 2.1. 기본 설계 원칙
- **정규화**: 3NF(Third Normal Form)까지 정규화를 원칙으로 하되, 성능상 필요시 의도적 비정규화 허용
- **참조 무결성**: 모든 외래키 관계에 대해 참조 무결성 제약조건 설정
- **데이터 타입 일관성**: 동일한 성격의 데이터는 동일한 데이터 타입 사용
- **확장성**: 향후 기능 확장을 고려한 유연한 구조 설계
- **성능**: 조회 패턴을 고려한 인덱스 설계

### 2.2. PostgreSQL 특화 원칙
- **JSONB 활용**: 반구조화 데이터는 JSONB 타입 적극 활용
- **UUID 사용**: 분산 환경을 고려한 UUID 기본키 사용
- **파티셔닝**: 대용량 테이블은 시간 기반 파티셔닝 적용
- **트리거 활용**: 비즈니스 로직 구현을 위한 트리거 적절히 활용

## 3. 명명 규칙 (Naming Conventions)

### 3.1. 테이블 명명 규칙

#### 3.1.1. 기본 규칙
- **형식**: `snake_case` 사용
- **언어**: 영어 사용, 한국어 금지
- **복수형**: 테이블명은 복수형 사용 (예: `users`, `buildings`)
- **길이**: 최대 63자 (PostgreSQL 제한)

#### 3.1.2. 테이블 유형별 명명
```sql
-- 마스터 테이블
buildings, units, lessors, tenants, fee_items

-- 트랜잭션 테이블  
lease_contracts, billing_months, invoices, payments

-- 연결 테이블 (M:N 관계)
user_role_links, lessor_property_links

-- 이력 테이블
audit_logs, payment_histories

-- 설정 테이블
organization_settings, payment_policies
```

#### 3.1.3. 접두사/접미사 규칙
- **이력 테이블**: `_histories` 접미사 (예: `contract_histories`)
- **로그 테이블**: `_logs` 접미사 (예: `audit_logs`)
- **연결 테이블**: `_links` 접미사 (예: `user_role_links`)
- **설정 테이블**: `_settings` 접미사 (예: `system_settings`)

### 3.2. 컬럼 명명 규칙

#### 3.2.1. 기본 규칙
- **형식**: `snake_case` 사용
- **언어**: 영어 사용
- **명확성**: 축약어 사용 최소화, 의미가 명확한 이름 사용

#### 3.2.2. 특수 컬럼 명명
```sql
-- 기본키
id (BIGSERIAL) 또는 {table_name}_id (UUID)
-- 예: user_id, building_id

-- 외래키
{referenced_table_singular}_id
-- 예: building_id, lessor_id, tenant_id

-- 상태 컬럼
status, state
-- 예: contract_status, payment_status

-- 플래그 컬럼 (Boolean)
is_{condition}, has_{condition}, can_{action}
-- 예: is_active, has_elevator, can_edit

-- 날짜/시간 컬럼
{action}_at, {action}_date
-- 예: created_at, updated_at, contract_date, due_date

-- 금액 컬럼
{purpose}_amount
-- 예: rent_amount, deposit_amount, total_amount

-- 수량 컬럼
{item}_count, {item}_quantity
-- 예: unit_count, floor_count
```

#### 3.2.3. 감사 필드 (Audit Fields)
모든 테이블에 다음 감사 필드 포함:
```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by BIGINT NOT NULL,
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by BIGINT NOT NULL
```

### 3.3. 인덱스 명명 규칙

#### 3.3.1. 인덱스 유형별 명명
```sql
-- 기본키 인덱스 (자동 생성)
{table_name}_pkey

-- 고유 인덱스
idx_{table_name}_{column_names}_unique
-- 예: idx_users_email_unique

-- 일반 인덱스
idx_{table_name}_{column_names}
-- 예: idx_lease_contracts_unit_id, idx_payments_payment_date

-- 복합 인덱스
idx_{table_name}_{column1}_{column2}
-- 예: idx_billing_months_year_month

-- 부분 인덱스
idx_{table_name}_{column_names}_{condition}
-- 예: idx_contracts_status_active (WHERE status = 'ACTIVE')

-- 함수 기반 인덱스
idx_{table_name}_{function_name}
-- 예: idx_users_lower_email (ON lower(email))
```

### 3.4. 제약조건 명명 규칙

#### 3.4.1. 제약조건 유형별 명명
```sql
-- 기본키 제약조건 (자동 생성)
{table_name}_pkey

-- 외래키 제약조건
fk_{table_name}_{referenced_table}
-- 예: fk_lease_contracts_units, fk_payments_invoices

-- 고유 제약조건
uk_{table_name}_{column_names}
-- 예: uk_users_email, uk_buildings_name_address

-- 체크 제약조건
ck_{table_name}_{column_name}_{condition}
-- 예: ck_payments_amount_positive, ck_contracts_dates_valid

-- NOT NULL 제약조건 (컬럼 정의에서 직접 지정)
```

### 3.5. 뷰 명명 규칙

```sql
-- 일반 뷰
v_{purpose}
-- 예: v_active_contracts, v_monthly_revenue

-- 구체화된 뷰 (Materialized View)
mv_{purpose}
-- 예: mv_building_statistics, mv_payment_summary
```

### 3.6. 함수 및 프로시저 명명 규칙

```sql
-- 함수
fn_{purpose}
-- 예: fn_calculate_late_fee, fn_get_unit_status

-- 프로시저
sp_{purpose}
-- 예: sp_generate_monthly_bills, sp_process_payments

-- 트리거 함수
tf_{table_name}_{event}
-- 예: tf_audit_logs_insert, tf_contracts_status_update
```

### 3.7. 트리거 명명 규칙

```sql
-- 트리거
tr_{table_name}_{event}_{purpose}
-- 예: tr_users_update_audit, tr_contracts_insert_status
```

## 4. 데이터 타입 표준화

### 4.1. 기본 데이터 타입 매핑

#### 4.1.1. 식별자 타입
```sql
-- 기본키 (자동 증가)
BIGSERIAL

-- 기본키 (UUID)
UUID DEFAULT gen_random_uuid()

-- 외래키
BIGINT (BIGSERIAL 참조 시)
UUID (UUID 참조 시)
```

#### 4.1.2. 문자열 타입
```sql
-- 짧은 문자열 (이름, 코드 등)
VARCHAR(100)  -- 일반적인 이름
VARCHAR(50)   -- 코드, 상태값
VARCHAR(20)   -- 전화번호, 우편번호

-- 긴 문자열 (주소, 설명 등)
VARCHAR(500)  -- 주소
TEXT          -- 긴 설명, 메모

-- 고정 길이 문자열
CHAR(10)      -- 사업자등록번호 등
```

#### 4.1.3. 숫자 타입
```sql
-- 정수
INTEGER       -- 일반적인 정수 (층수, 개수 등)
BIGINT        -- 큰 정수 (ID, 외래키 등)
SMALLINT      -- 작은 정수 (월, 일 등)

-- 소수
NUMERIC(15,2) -- 금액 (최대 13자리 정수, 2자리 소수)
NUMERIC(10,2) -- 면적, 사용량
DECIMAL(5,2)  -- 비율, 요율 (예: 99.99%)
```

#### 4.1.4. 날짜/시간 타입
```sql
-- 날짜만
DATE          -- 계약일, 만료일 등

-- 날짜와 시간 (타임존 포함)
TIMESTAMPTZ   -- 생성일시, 수정일시 등

-- 날짜와 시간 (타임존 없음)
TIMESTAMP     -- 특정 시점 기록 (필요시)
```

#### 4.1.5. 기타 타입
```sql
-- 논리값
BOOLEAN       -- 플래그, 상태 등

-- JSON 데이터
JSONB         -- 설정값, 메타데이터 등

-- 배열
TEXT[]        -- 태그, 카테고리 등

-- 열거형 (ENUM) - 필요시 정의
CREATE TYPE contract_status AS ENUM ('ACTIVE', 'EXPIRED', 'TERMINATED');
```

### 4.2. 도메인별 표준 타입

#### 4.2.1. 금액 관련
```sql
-- 일반 금액 (원 단위)
NUMERIC(15,2) -- 최대 999,999,999,999,999.99원

-- 소액 (수수료, 연체료 등)
NUMERIC(10,2) -- 최대 99,999,999.99원

-- 비율 (연체료율, 할인율 등)
NUMERIC(5,2)  -- 최대 999.99%
```

#### 4.2.2. 면적 관련
```sql
-- 건물 면적 (㎡)
NUMERIC(10,2) -- 최대 99,999,999.99㎡

-- 호실 면적 (㎡)  
NUMERIC(8,2)  -- 최대 999,999.99㎡
```

#### 4.2.3. 연락처 관련
```sql
-- 전화번호
VARCHAR(20)   -- 국제번호 포함 가능

-- 이메일
VARCHAR(255)  -- RFC 5321 표준 최대 길이

-- 주소
VARCHAR(500)  -- 상세주소 포함
```

## 5. 제약조건 정책

### 5.1. 기본키 제약조건
- 모든 테이블은 기본키를 가져야 함
- 자연키보다는 대리키(Surrogate Key) 사용 권장
- UUID 또는 BIGSERIAL 사용

### 5.2. 외래키 제약조건
- 모든 외래키 관계에 대해 제약조건 설정
- ON DELETE 및 ON UPDATE 액션 명시적 지정
- 참조 무결성 보장

#### 5.2.1. 삭제 정책 (ON DELETE)
```sql
-- 마스터 데이터 참조
ON DELETE RESTRICT  -- 참조되는 데이터 삭제 방지

-- 종속 데이터
ON DELETE CASCADE   -- 부모 삭제 시 자식도 삭제

-- 선택적 참조
ON DELETE SET NULL  -- 부모 삭제 시 NULL로 설정
```

### 5.3. 체크 제약조건
- 비즈니스 규칙을 데이터베이스 레벨에서 강제
- 데이터 품질 보장

#### 5.3.1. 일반적인 체크 제약조건
```sql
-- 금액은 0 이상
CONSTRAINT ck_payments_amount_positive 
CHECK (amount >= 0)

-- 날짜 순서 검증
CONSTRAINT ck_contracts_dates_valid 
CHECK (end_date >= start_date)

-- 상태값 검증
CONSTRAINT ck_contracts_status_valid 
CHECK (status IN ('ACTIVE', 'EXPIRED', 'TERMINATED'))

-- 비율 범위 검증
CONSTRAINT ck_late_fee_rate_valid 
CHECK (late_fee_rate >= 0 AND late_fee_rate <= 100)
```

### 5.4. 고유 제약조건
- 비즈니스 고유성 보장
- 복합 고유 제약조건 적극 활용

```sql
-- 단일 컬럼 고유성
CONSTRAINT uk_users_email UNIQUE (email)

-- 복합 고유성
CONSTRAINT uk_units_building_number 
UNIQUE (building_id, unit_number)

-- 조건부 고유성 (부분 인덱스 활용)
CREATE UNIQUE INDEX uk_contracts_unit_active 
ON lease_contracts (unit_id) 
WHERE status = 'ACTIVE';
```

## 6. 감사 로그 및 이력 관리 표준

### 6.1. 감사 필드 표준
모든 테이블에 다음 필드 포함:
```sql
created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by BIGINT NOT NULL REFERENCES users(id),
updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by BIGINT NOT NULL REFERENCES users(id)
```

### 6.2. 감사 로그 테이블 구조
```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by BIGINT NOT NULL REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);
```

### 6.3. 이력 관리 방식

#### 6.3.1. 기간 기반 이력 관리
- 시작일/종료일을 통한 유효 기간 관리
- 현재 유효한 레코드 식별을 위한 뷰 제공

```sql
-- 예: 임대료 이력 관리
CREATE TABLE rent_histories (
    id BIGSERIAL PRIMARY KEY,
    contract_id BIGINT NOT NULL,
    rent_amount NUMERIC(15,2) NOT NULL,
    effective_from DATE NOT NULL,
    effective_to DATE,
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL
);
```

#### 6.3.2. 범용 감사 로그
- 모든 테이블의 변경사항을 중앙 집중 관리
- 트리거를 통한 자동 로깅

### 6.4. 트리거 기반 감사 로깅
```sql
-- 감사 로그 트리거 함수 예시
CREATE OR REPLACE FUNCTION tf_audit_log()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), OLD.updated_by);
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), NEW.updated_by);
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), NEW.created_by);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
```

## 7. 성능 최적화 표준

### 7.1. 인덱스 설계 원칙
- 조회 패턴 분석 기반 인덱스 설계
- 복합 인덱스 컬럼 순서 최적화 (선택도 높은 컬럼 우선)
- 부분 인덱스 적극 활용

### 7.2. 파티셔닝 전략
- 시간 기반 파티셔닝 (월별, 연도별)
- 대용량 테이블 대상 (billing_months, payments 등)

```sql
-- 월별 파티셔닝 예시
CREATE TABLE payments (
    id BIGSERIAL,
    payment_date DATE NOT NULL,
    amount NUMERIC(15,2) NOT NULL,
    -- 기타 컬럼들
) PARTITION BY RANGE (payment_date);

-- 월별 파티션 생성
CREATE TABLE payments_2024_01 PARTITION OF payments
FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

### 7.3. 쿼리 최적화 가이드라인
- WHERE 절에 사용되는 컬럼에 인덱스 생성
- JOIN 조건에 사용되는 컬럼에 인덱스 생성
- ORDER BY 절에 사용되는 컬럼 조합 인덱스 고려

## 8. 보안 표준

### 8.1. 데이터 암호화
- 개인정보 필드 암호화 (전화번호, 주소 등)
- 금융정보 암호화 (계좌번호 등)
- PostgreSQL의 pgcrypto 확장 활용

### 8.2. 접근 제어
- 역할 기반 접근 제어 (RBAC)
- 최소 권한 원칙 적용
- 데이터베이스 사용자별 권한 분리

### 8.3. 감사 및 모니터링
- 모든 DDL/DML 작업 로깅
- 민감한 데이터 접근 모니터링
- 정기적인 보안 감사

## 9. 문서화 표준

### 9.1. 테이블 및 컬럼 주석
```sql
-- 테이블 주석
COMMENT ON TABLE buildings IS '건물 기본 정보를 관리하는 테이블';

-- 컬럼 주석
COMMENT ON COLUMN buildings.building_name IS '건물명';
COMMENT ON COLUMN buildings.total_unit_count IS '총 세대수';
```

### 9.2. ERD 문서화
- 논리적 ERD와 물리적 ERD 분리 관리
- 주요 비즈니스 규칙 ERD에 표기
- 정기적인 ERD 업데이트

### 9.3. 데이터 사전 (Data Dictionary)
- 모든 테이블, 컬럼, 인덱스, 제약조건 정보 관리
- 비즈니스 용어와 기술 용어 매핑
- 변경 이력 관리

## 10. 결론

본 표준은 QIRO 시스템의 데이터베이스 설계 일관성과 품질을 보장하기 위한 가이드라인입니다. 모든 개발자는 이 표준을 준수하여 데이터베이스를 설계하고 구현해야 하며, 표준의 변경이 필요한 경우 충분한 검토와 승인 과정을 거쳐야 합니다.

이 표준을 통해 유지보수성, 확장성, 성능을 모두 고려한 견고한 데이터베이스 시스템을 구축할 수 있을 것입니다.