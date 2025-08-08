-- 수입 관리 시스템 스키마
-- 관리비 및 임대료 수입 자동 기록, 미수금 관리, 연체료 계산 기능

-- 수입 유형 테이블
CREATE TABLE IF NOT EXISTS bms.income_types (
    income_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    type_code VARCHAR(20) NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_recurring BOOLEAN DEFAULT false,
    default_account_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, type_code)
);

COMMENT ON TABLE bms.income_types IS '수입 유형 관리 테이블';
COMMENT ON COLUMN bms.income_types.income_type_id IS '수입 유형 ID';
COMMENT ON COLUMN bms.income_types.company_id IS '회사 ID';
COMMENT ON COLUMN bms.income_types.type_code IS '수입 유형 코드 (MAINTENANCE_FEE, RENT, DEPOSIT, ETC)';
COMMENT ON COLUMN bms.income_types.type_name IS '수입 유형명';
COMMENT ON COLUMN bms.income_types.description IS '수입 유형 설명';
COMMENT ON COLUMN bms.income_types.is_recurring IS '정기 수입 여부';
COMMENT ON COLUMN bms.income_types.default_account_id IS '기본 계정과목 ID';
COMMENT ON COLUMN bms.income_types.is_active IS '활성 상태';

-- 수입 기록 테이블
CREATE TABLE IF NOT EXISTS bms.income_records (
    income_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    income_type_id UUID NOT NULL REFERENCES bms.income_types(income_type_id),
    building_id UUID,
    unit_id UUID,
    contract_id UUID,
    tenant_id UUID,
    income_date DATE NOT NULL,
    due_date DATE,
    amount DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50),
    bank_account_id UUID,
    reference_number VARCHAR(100),
    description TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    journal_entry_id UUID,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_income_status CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED'))
);

COMMENT ON TABLE bms.income_records IS '수입 기록 테이블';
COMMENT ON COLUMN bms.income_records.income_record_id IS '수입 기록 ID';
COMMENT ON COLUMN bms.income_records.company_id IS '회사 ID';
COMMENT ON COLUMN bms.income_records.income_type_id IS '수입 유형 ID';
COMMENT ON COLUMN bms.income_records.building_id IS '건물 ID';
COMMENT ON COLUMN bms.income_records.unit_id IS '세대 ID';
COMMENT ON COLUMN bms.income_records.contract_id IS '계약 ID';
COMMENT ON COLUMN bms.income_records.tenant_id IS '임차인 ID';
COMMENT ON COLUMN bms.income_records.income_date IS '수입 발생일';
COMMENT ON COLUMN bms.income_records.due_date IS '납부 기한';
COMMENT ON COLUMN bms.income_records.amount IS '기본 금액';
COMMENT ON COLUMN bms.income_records.tax_amount IS '세금 금액';
COMMENT ON COLUMN bms.income_records.total_amount IS '총 금액';
COMMENT ON COLUMN bms.income_records.payment_method IS '결제 방법';
COMMENT ON COLUMN bms.income_records.bank_account_id IS '은행 계좌 ID';
COMMENT ON COLUMN bms.income_records.reference_number IS '참조 번호';
COMMENT ON COLUMN bms.income_records.description IS '설명';
COMMENT ON COLUMN bms.income_records.status IS '상태 (PENDING, CONFIRMED, CANCELLED)';
COMMENT ON COLUMN bms.income_records.journal_entry_id IS '분개 전표 ID';

-- 미수금 관리 테이블
CREATE TABLE IF NOT EXISTS bms.receivables (
    receivable_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    income_record_id UUID NOT NULL REFERENCES bms.income_records(income_record_id),
    building_id UUID,
    unit_id UUID,
    tenant_id UUID,
    original_amount DECIMAL(15,2) NOT NULL,
    outstanding_amount DECIMAL(15,2) NOT NULL,
    overdue_days INTEGER DEFAULT 0,
    late_fee_amount DECIMAL(15,2) DEFAULT 0,
    total_outstanding DECIMAL(15,2) NOT NULL,
    due_date DATE NOT NULL,
    last_payment_date DATE,
    status VARCHAR(20) DEFAULT 'OUTSTANDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_receivable_status CHECK (status IN ('OUTSTANDING', 'PARTIALLY_PAID', 'FULLY_PAID', 'WRITTEN_OFF'))
);

COMMENT ON TABLE bms.receivables IS '미수금 관리 테이블';
COMMENT ON COLUMN bms.receivables.receivable_id IS '미수금 ID';
COMMENT ON COLUMN bms.receivables.company_id IS '회사 ID';
COMMENT ON COLUMN bms.receivables.income_record_id IS '수입 기록 ID';
COMMENT ON COLUMN bms.receivables.building_id IS '건물 ID';
COMMENT ON COLUMN bms.receivables.unit_id IS '세대 ID';
COMMENT ON COLUMN bms.receivables.tenant_id IS '임차인 ID';
COMMENT ON COLUMN bms.receivables.original_amount IS '원래 금액';
COMMENT ON COLUMN bms.receivables.outstanding_amount IS '미수 금액';
COMMENT ON COLUMN bms.receivables.overdue_days IS '연체 일수';
COMMENT ON COLUMN bms.receivables.late_fee_amount IS '연체료 금액';
COMMENT ON COLUMN bms.receivables.total_outstanding IS '총 미수 금액';
COMMENT ON COLUMN bms.receivables.due_date IS '납부 기한';
COMMENT ON COLUMN bms.receivables.last_payment_date IS '최종 납부일';
COMMENT ON COLUMN bms.receivables.status IS '상태 (OUTSTANDING, PARTIALLY_PAID, FULLY_PAID, WRITTEN_OFF)';

-- 결제 기록 테이블
CREATE TABLE IF NOT EXISTS bms.payment_records (
    payment_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    receivable_id UUID NOT NULL REFERENCES bms.receivables(receivable_id),
    income_record_id UUID NOT NULL REFERENCES bms.income_records(income_record_id),
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(15,2) NOT NULL,
    late_fee_paid DECIMAL(15,2) DEFAULT 0,
    total_paid DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50),
    bank_account_id UUID,
    transaction_reference VARCHAR(100),
    notes TEXT,
    journal_entry_id UUID,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE bms.payment_records IS '결제 기록 테이블';
COMMENT ON COLUMN bms.payment_records.payment_record_id IS '결제 기록 ID';
COMMENT ON COLUMN bms.payment_records.company_id IS '회사 ID';
COMMENT ON COLUMN bms.payment_records.receivable_id IS '미수금 ID';
COMMENT ON COLUMN bms.payment_records.income_record_id IS '수입 기록 ID';
COMMENT ON COLUMN bms.payment_records.payment_date IS '결제일';
COMMENT ON COLUMN bms.payment_records.payment_amount IS '결제 금액';
COMMENT ON COLUMN bms.payment_records.late_fee_paid IS '연체료 납부 금액';
COMMENT ON COLUMN bms.payment_records.total_paid IS '총 납부 금액';
COMMENT ON COLUMN bms.payment_records.payment_method IS '결제 방법';
COMMENT ON COLUMN bms.payment_records.bank_account_id IS '은행 계좌 ID';
COMMENT ON COLUMN bms.payment_records.transaction_reference IS '거래 참조 번호';
COMMENT ON COLUMN bms.payment_records.notes IS '비고';
COMMENT ON COLUMN bms.payment_records.journal_entry_id IS '분개 전표 ID';

-- 연체료 정책 테이블
CREATE TABLE IF NOT EXISTS bms.late_fee_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    income_type_id UUID NOT NULL REFERENCES bms.income_types(income_type_id),
    policy_name VARCHAR(100) NOT NULL,
    grace_period_days INTEGER DEFAULT 0,
    late_fee_type VARCHAR(20) NOT NULL,
    late_fee_rate DECIMAL(5,4),
    fixed_late_fee DECIMAL(15,2),
    max_late_fee DECIMAL(15,2),
    compound_interest BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    effective_from DATE NOT NULL,
    effective_to DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_late_fee_type CHECK (late_fee_type IN ('PERCENTAGE', 'FIXED', 'DAILY_RATE'))
);

COMMENT ON TABLE bms.late_fee_policies IS '연체료 정책 테이블';
COMMENT ON COLUMN bms.late_fee_policies.policy_id IS '정책 ID';
COMMENT ON COLUMN bms.late_fee_policies.company_id IS '회사 ID';
COMMENT ON COLUMN bms.late_fee_policies.income_type_id IS '수입 유형 ID';
COMMENT ON COLUMN bms.late_fee_policies.policy_name IS '정책명';
COMMENT ON COLUMN bms.late_fee_policies.grace_period_days IS '유예 기간 (일)';
COMMENT ON COLUMN bms.late_fee_policies.late_fee_type IS '연체료 유형 (PERCENTAGE, FIXED, DAILY_RATE)';
COMMENT ON COLUMN bms.late_fee_policies.late_fee_rate IS '연체료율 (%)';
COMMENT ON COLUMN bms.late_fee_policies.fixed_late_fee IS '고정 연체료';
COMMENT ON COLUMN bms.late_fee_policies.max_late_fee IS '최대 연체료';
COMMENT ON COLUMN bms.late_fee_policies.compound_interest IS '복리 적용 여부';
COMMENT ON COLUMN bms.late_fee_policies.is_active IS '활성 상태';
COMMENT ON COLUMN bms.late_fee_policies.effective_from IS '적용 시작일';
COMMENT ON COLUMN bms.late_fee_policies.effective_to IS '적용 종료일';

-- 정기 수입 스케줄 테이블
CREATE TABLE IF NOT EXISTS bms.recurring_income_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    income_type_id UUID NOT NULL REFERENCES bms.income_types(income_type_id),
    building_id UUID,
    unit_id UUID,
    contract_id UUID,
    tenant_id UUID,
    schedule_name VARCHAR(100) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    interval_value INTEGER DEFAULT 1,
    amount DECIMAL(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    next_generation_date DATE NOT NULL,
    last_generated_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_frequency CHECK (frequency IN ('MONTHLY', 'QUARTERLY', 'SEMI_ANNUALLY', 'ANNUALLY'))
);

COMMENT ON TABLE bms.recurring_income_schedules IS '정기 수입 스케줄 테이블';
COMMENT ON COLUMN bms.recurring_income_schedules.schedule_id IS '스케줄 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.company_id IS '회사 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.income_type_id IS '수입 유형 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.building_id IS '건물 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.unit_id IS '세대 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.contract_id IS '계약 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.tenant_id IS '임차인 ID';
COMMENT ON COLUMN bms.recurring_income_schedules.schedule_name IS '스케줄명';
COMMENT ON COLUMN bms.recurring_income_schedules.frequency IS '주기 (MONTHLY, QUARTERLY, SEMI_ANNUALLY, ANNUALLY)';
COMMENT ON COLUMN bms.recurring_income_schedules.interval_value IS '간격 값';
COMMENT ON COLUMN bms.recurring_income_schedules.amount IS '금액';
COMMENT ON COLUMN bms.recurring_income_schedules.start_date IS '시작일';
COMMENT ON COLUMN bms.recurring_income_schedules.end_date IS '종료일';
COMMENT ON COLUMN bms.recurring_income_schedules.next_generation_date IS '다음 생성일';
COMMENT ON COLUMN bms.recurring_income_schedules.last_generated_date IS '최종 생성일';
COMMENT ON COLUMN bms.recurring_income_schedules.is_active IS '활성 상태';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_income_types_company_id ON bms.income_types(company_id);
CREATE INDEX IF NOT EXISTS idx_income_types_type_code ON bms.income_types(company_id, type_code);

CREATE INDEX IF NOT EXISTS idx_income_records_company_id ON bms.income_records(company_id);
CREATE INDEX IF NOT EXISTS idx_income_records_income_date ON bms.income_records(company_id, income_date);
CREATE INDEX IF NOT EXISTS idx_income_records_status ON bms.income_records(company_id, status);
CREATE INDEX IF NOT EXISTS idx_income_records_building_unit ON bms.income_records(company_id, building_id, unit_id);

CREATE INDEX IF NOT EXISTS idx_receivables_company_id ON bms.receivables(company_id);
CREATE INDEX IF NOT EXISTS idx_receivables_status ON bms.receivables(company_id, status);
CREATE INDEX IF NOT EXISTS idx_receivables_due_date ON bms.receivables(company_id, due_date);
CREATE INDEX IF NOT EXISTS idx_receivables_tenant ON bms.receivables(company_id, tenant_id);

CREATE INDEX IF NOT EXISTS idx_payment_records_company_id ON bms.payment_records(company_id);
CREATE INDEX IF NOT EXISTS idx_payment_records_payment_date ON bms.payment_records(company_id, payment_date);
CREATE INDEX IF NOT EXISTS idx_payment_records_receivable ON bms.payment_records(receivable_id);

CREATE INDEX IF NOT EXISTS idx_late_fee_policies_company_id ON bms.late_fee_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_late_fee_policies_income_type ON bms.late_fee_policies(income_type_id);
CREATE INDEX IF NOT EXISTS idx_late_fee_policies_effective ON bms.late_fee_policies(company_id, effective_from, effective_to);

CREATE INDEX IF NOT EXISTS idx_recurring_schedules_company_id ON bms.recurring_income_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_recurring_schedules_next_date ON bms.recurring_income_schedules(company_id, next_generation_date);
CREATE INDEX IF NOT EXISTS idx_recurring_schedules_active ON bms.recurring_income_schedules(company_id, is_active);

-- 연체료 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_late_fee(
    p_receivable_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_receivable RECORD;
    v_policy RECORD;
    v_overdue_days INTEGER;
    v_late_fee DECIMAL(15,2) := 0;
BEGIN
    -- 미수금 정보 조회
    SELECT r.*, ir.income_type_id
    INTO v_receivable
    FROM bms.receivables r
    JOIN bms.income_records ir ON r.income_record_id = ir.income_record_id
    WHERE r.receivable_id = p_receivable_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- 연체 일수 계산
    v_overdue_days := p_calculation_date - v_receivable.due_date;
    
    IF v_overdue_days <= 0 THEN
        RETURN 0;
    END IF;
    
    -- 연체료 정책 조회
    SELECT *
    INTO v_policy
    FROM bms.late_fee_policies
    WHERE income_type_id = v_receivable.income_type_id
      AND is_active = true
      AND effective_from <= p_calculation_date
      AND (effective_to IS NULL OR effective_to >= p_calculation_date)
    ORDER BY effective_from DESC
    LIMIT 1;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- 유예 기간 확인
    IF v_overdue_days <= v_policy.grace_period_days THEN
        RETURN 0;
    END IF;
    
    -- 실제 연체 일수 (유예 기간 제외)
    v_overdue_days := v_overdue_days - v_policy.grace_period_days;
    
    -- 연체료 계산
    CASE v_policy.late_fee_type
        WHEN 'PERCENTAGE' THEN
            v_late_fee := v_receivable.outstanding_amount * v_policy.late_fee_rate / 100;
        WHEN 'FIXED' THEN
            v_late_fee := v_policy.fixed_late_fee;
        WHEN 'DAILY_RATE' THEN
            v_late_fee := v_receivable.outstanding_amount * v_policy.late_fee_rate / 100 * v_overdue_days;
    END CASE;
    
    -- 최대 연체료 제한
    IF v_policy.max_late_fee IS NOT NULL AND v_late_fee > v_policy.max_late_fee THEN
        v_late_fee := v_policy.max_late_fee;
    END IF;
    
    RETURN COALESCE(v_late_fee, 0);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.calculate_late_fee IS '연체료 계산 함수';

-- 미수금 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_receivable_status(
    p_receivable_id UUID
) RETURNS VOID AS $$
DECLARE
    v_receivable RECORD;
    v_total_paid DECIMAL(15,2);
    v_late_fee DECIMAL(15,2);
    v_overdue_days INTEGER;
    v_new_status VARCHAR(20);
BEGIN
    -- 미수금 정보 조회
    SELECT * INTO v_receivable
    FROM bms.receivables
    WHERE receivable_id = p_receivable_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    -- 총 납부 금액 계산
    SELECT COALESCE(SUM(total_paid), 0)
    INTO v_total_paid
    FROM bms.payment_records
    WHERE receivable_id = p_receivable_id;
    
    -- 연체료 계산
    v_late_fee := bms.calculate_late_fee(p_receivable_id);
    
    -- 연체 일수 계산
    v_overdue_days := GREATEST(0, CURRENT_DATE - v_receivable.due_date);
    
    -- 상태 결정
    IF v_total_paid >= (v_receivable.original_amount + v_late_fee) THEN
        v_new_status := 'FULLY_PAID';
    ELSIF v_total_paid > 0 THEN
        v_new_status := 'PARTIALLY_PAID';
    ELSE
        v_new_status := 'OUTSTANDING';
    END IF;
    
    -- 미수금 정보 업데이트
    UPDATE bms.receivables
    SET outstanding_amount = GREATEST(0, v_receivable.original_amount - v_total_paid + v_late_fee),
        overdue_days = v_overdue_days,
        late_fee_amount = v_late_fee,
        total_outstanding = GREATEST(0, v_receivable.original_amount - v_total_paid + v_late_fee),
        status = v_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE receivable_id = p_receivable_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.update_receivable_status IS '미수금 상태 업데이트 함수';

-- 정기 수입 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_recurring_income(
    p_schedule_id UUID,
    p_generation_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID AS $$
DECLARE
    v_schedule RECORD;
    v_income_record_id UUID;
    v_receivable_id UUID;
    v_next_date DATE;
BEGIN
    -- 스케줄 정보 조회
    SELECT * INTO v_schedule
    FROM bms.recurring_income_schedules
    WHERE schedule_id = p_schedule_id
      AND is_active = true
      AND next_generation_date <= p_generation_date;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- 수입 기록 생성
    INSERT INTO bms.income_records (
        company_id, income_type_id, building_id, unit_id, contract_id, tenant_id,
        income_date, due_date, amount, total_amount, description, status, created_by
    ) VALUES (
        v_schedule.company_id, v_schedule.income_type_id, v_schedule.building_id,
        v_schedule.unit_id, v_schedule.contract_id, v_schedule.tenant_id,
        p_generation_date,
        p_generation_date + INTERVAL '30 days', -- 기본 30일 후 납부 기한
        v_schedule.amount, v_schedule.amount,
        v_schedule.schedule_name || ' - ' || TO_CHAR(p_generation_date, 'YYYY-MM'),
        'PENDING',
        '00000000-0000-0000-0000-000000000000'::UUID -- 시스템 생성
    ) RETURNING income_record_id INTO v_income_record_id;
    
    -- 미수금 생성
    INSERT INTO bms.receivables (
        company_id, income_record_id, building_id, unit_id, tenant_id,
        original_amount, outstanding_amount, total_outstanding, due_date, status
    ) VALUES (
        v_schedule.company_id, v_income_record_id, v_schedule.building_id,
        v_schedule.unit_id, v_schedule.tenant_id,
        v_schedule.amount, v_schedule.amount, v_schedule.amount,
        p_generation_date + INTERVAL '30 days', 'OUTSTANDING'
    ) RETURNING receivable_id INTO v_receivable_id;
    
    -- 다음 생성일 계산
    CASE v_schedule.frequency
        WHEN 'MONTHLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value || ' months')::INTERVAL;
        WHEN 'QUARTERLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value * 3 || ' months')::INTERVAL;
        WHEN 'SEMI_ANNUALLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value * 6 || ' months')::INTERVAL;
        WHEN 'ANNUALLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value || ' years')::INTERVAL;
    END CASE;
    
    -- 스케줄 업데이트
    UPDATE bms.recurring_income_schedules
    SET next_generation_date = v_next_date,
        last_generated_date = p_generation_date,
        updated_at = CURRENT_TIMESTAMP
    WHERE schedule_id = p_schedule_id;
    
    RETURN v_income_record_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.generate_recurring_income IS '정기 수입 생성 함수';