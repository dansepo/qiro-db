# **관리비 계산 최종 결과(billing_details) 상세**

### **1. 문서 개요**

본 문서는 '월별 관리비 자동 계산' 기능의 최종 결과물이 저장되는 **`bms.billing_details` 테이블의 상세한 DDL(Data Definition Language)**과, 실제 데이터가 어떻게 기록되는지에 대한 **구체적인 예시**를 정의합니다.

### **2. `bms.billing_details` 테이블 DDL (PostgreSQL)**

이 테이블은 각 호실에 부과된 모든 관리비 항목의 최종 계산 금액과 그 근거를 상세하게 기록하는 역할을 합니다.

```
-- =====================================================================
-- 관리비 계산 최종 결과 상세 테이블 DDL
-- 데이터베이스 종류: PostgreSQL, 스키마: bms
-- =====================================================================

-- 기존 테이블이 존재하면 삭제 (초기화 시에만 사용)
DROP TABLE IF EXISTS bms.billing_details;

-- 관리비 계산 최종 결과 상세 테이블 생성
CREATE TABLE bms.billing_details (
    detail_id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    billing_cycle_id uuid NOT NULL,
    unit_id uuid NOT NULL,
    display_name varchar(255) NOT NULL,
    amount numeric(15, 2) NOT NULL,
    calculation_log text NULL,
    created_at timestamptz DEFAULT now() NOT NULL,
    created_by varchar(100),
    updated_at timestamptz DEFAULT now() NOT NULL,
    updated_by varchar(100),
    CONSTRAINT fk_billing_cycle FOREIGN KEY (billing_cycle_id) REFERENCES bms.billing_cycles(id) ON DELETE CASCADE,
    CONSTRAINT fk_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id)
);

-- 테이블 및 각 컬럼에 대한 주석 추가
COMMENT ON TABLE bms.billing_details IS '각 호실별로 부과된 모든 항목의 최종 계산 금액과 근거를 기록하는 테이블';
COMMENT ON COLUMN bms.billing_details.detail_id IS '상세 내역의 고유 식별자 (PK)';
COMMENT ON COLUMN bms.billing_details.billing_cycle_id IS '이 상세 내역이 속한 청구월의 ID';
COMMENT ON COLUMN bms.billing_details.unit_id IS '이 상세 내역이 부과된 호실의 ID';
COMMENT ON COLUMN bms.billing_details.display_name IS '고지서에 표시될 항목명 (예: 일반관리비, 세대 전기료)';
COMMENT ON COLUMN bms.billing_details.amount IS '최종 계산된 부과 금액';
COMMENT ON COLUMN bms.billing_details.calculation_log IS '어떻게 계산되었는지에 대한 로그 (예: "1500원/㎡ * 84.5㎡")';
COMMENT ON COLUMN bms.billing_details.created_at IS '레코드 생성 시각';
COMMENT ON COLUMN bms.billing_details.created_by IS '레코드를 생성한 사용자 ID';
COMMENT ON COLUMN bms.billing_details.updated_at IS '레코드 마지막 수정 시각';
COMMENT ON COLUMN bms.billing_details.updated_by IS '레코드를 마지막으로 수정한 사용자 ID';
```

### **3. 저장되는 최종 결과 데이터 예시**

**상황:** 2025년 7월분 관리비 계산이 완료된 후, **101호**에 대한 `bms.billing_details` 테이블의 데이터 예시입니다.

| detail_id | billing_cycle_id    | unit_id         | display_name      | amount  | calculation_log                                              |
| --------- | ------------------- | --------------- | ----------------- | ------- | ------------------------------------------------------------ |
| `uuid-1`  | `cycle-uuid-202507` | `unit-uuid-101` | 일반관리비        | 126,750 | `TOTAL_PER_AREA`: (총액 18,000,000원 / 전체면적 12,000㎡) * 84.5㎡ |
| `uuid-2`  | `cycle-uuid-202507` | `unit-id-101`   | 청소비            | 30,000  | `TOTAL_PER_UNIT_EQUAL`: 총액 1,500,000원 / 50세대            |
| `uuid-3`  | `cycle-uuid-202507` | `unit-id-101`   | 세대 전기료       | 24,100  | `RATE_PER_USAGE`: 120.5원/kWh * 200kWh                       |
| `uuid-4`  | `cycle-uuid-202507` | `unit-id-101`   | 공용 전기료(기본) | 5,633   | `TOTAL_PER_AREA`: (총액 800,000원 / 전체면적 12,000㎡) * 84.5㎡ |
| `uuid-5`  | `cycle-uuid-202507` | `unit-id-101`   | 공용 전기료(사용) | 7,500   | `INDIVIDUAL_USAGE_PROPORTIONAL`: (총액 300,000원) * (200kWh/8000kWh) |
| `uuid-6`  | `cycle-uuid-202507` | `unit-id-101`   | 헬스장 이용료     | 30,000  | `FIXED_AMOUNT`: 고정액 부과                                  |
| `uuid-7`  | `cycle-uuid-202507` | `unit-id-101`   | 기타 수리비       | 25,000  | `DIRECT_ASSIGNMENT`: 복도 전등 파손 수리비                   |

이처럼 각 호실에 부과된 모든 항목이 **개별적인 행(Row)**으로 저장되며, `calculation_log`를 통해 각 금액이 어떤 기준으로 산출되었는지 명확하게 추적할 수 있습니다. 이 데이터는 최종적으로 고지서를 생성하고, 각종 통계 및 보고서를 만드는 데 사용됩니다.