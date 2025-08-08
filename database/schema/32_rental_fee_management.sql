-- =====================================================
-- 임대료 및 보증금 관리 시스템 테이블 생성 스크립트
-- Phase 3.2: 임대료 및 보증금 관리
-- =====================================================

-- 1. 임대료 정책 테이블
CREATE TABLE IF NOT EXISTS bms.rental_fee_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- 정책 기본 정보
    policy_name VARCHAR(100) NOT NULL,
    policy_description TEXT,
    policy_type VARCHAR(20) NOT NULL,
    
    -- 임대료 인상 정책
    annual_increase_rate DECIMAL(5,2) DEFAULT 0,
    max_increase_rate DECIMAL(5,2) DEFAULT 5.0,
    increase_frequency_months INTEGER DEFAULT 12,
    increase_notice_days INTEGER DEFAULT 60,
    
    -- 할인 및 면제 정책
    discount_policies JSONB,
    exemption_conditions JSONB,
    
    -- 연체료 정책
    late_fee_rate DECIMAL(8,4) DEFAULT 0.025,
    late_fee_grace_days INTEGER DEFAULT 5,
    late_fee_calculation_method VARCHAR(20) DEFAULT 'DAILY_RATE',
    
    -- 상태 및 기간
    is_active BOOLEAN DEFAULT true,
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_rental_fee_policies_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rental_fee_policies_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_rental_fee_policies_name UNIQUE (company_id, building_id, policy_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_policy_type_rental CHECK (policy_type IN (
        'STANDARD', 'PREMIUM', 'SOCIAL', 'COMMERCIAL', 'CUSTOM'
    )),
    CONSTRAINT chk_increase_rates CHECK (
        annual_increase_rate >= 0 AND annual_increase_rate <= 100 AND
        max_increase_rate >= 0 AND max_increase_rate <= 100 AND
        max_increase_rate >= annual_increase_rate
    ),
    CONSTRAINT chk_frequency_notice CHECK (
        increase_frequency_months > 0 AND increase_notice_days > 0
    )
);-- 2. 임
대료 부과 테이블
CREATE TABLE IF NOT EXISTS bms.rental_fee_charges (
    charge_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    
    -- 부과 기본 정보
    charge_number VARCHAR(50) NOT NULL,
    charge_type VARCHAR(20) NOT NULL,
    charge_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- 부과 기간
    charge_year INTEGER NOT NULL,
    charge_month INTEGER NOT NULL,
    charge_period_start DATE NOT NULL,
    charge_period_end DATE NOT NULL,
    
    -- 금액 정보
    base_rent_amount DECIMAL(15,2) NOT NULL,
    maintenance_fee_amount DECIMAL(15,2) DEFAULT 0,
    utility_fee_amount DECIMAL(15,2) DEFAULT 0,
    other_fee_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_charge_amount DECIMAL(15,2) NOT NULL,
    
    -- 납부 정보
    due_date DATE NOT NULL,
    payment_method VARCHAR(20),
    bank_account_info JSONB,
    
    -- 연체 정보
    late_fee_amount DECIMAL(15,2) DEFAULT 0,
    overdue_days INTEGER DEFAULT 0,
    
    -- 처리 정보
    issued_date DATE DEFAULT CURRENT_DATE,
    issued_by UUID,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_rental_fee_charges_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rental_fee_charges_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT uk_rental_fee_charges_number UNIQUE (company_id, charge_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_charge_type CHECK (charge_type IN (
        'MONTHLY_RENT', 'DEPOSIT', 'UTILITY', 'MAINTENANCE', 'PENALTY', 'OTHER'
    )),
    CONSTRAINT chk_charge_status CHECK (charge_status IN (
        'PENDING', 'ISSUED', 'PAID', 'OVERDUE', 'CANCELLED'
    )),
    CONSTRAINT chk_charge_year_month CHECK (
        charge_year BETWEEN 2000 AND 2100 AND
        charge_month BETWEEN 1 AND 12
    ),
    CONSTRAINT chk_amounts_charge CHECK (
        base_rent_amount >= 0 AND maintenance_fee_amount >= 0 AND
        utility_fee_amount >= 0 AND other_fee_amount >= 0 AND
        discount_amount >= 0 AND total_charge_amount >= 0 AND
        late_fee_amount >= 0
    ),
    CONSTRAINT chk_overdue_days CHECK (overdue_days >= 0),
    CONSTRAINT chk_period_dates CHECK (charge_period_end >= charge_period_start)
);-
- 3. 보증금 관리 테이블
CREATE TABLE IF NOT EXISTS bms.deposit_management (
    deposit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    
    -- 보증금 기본 정보
    deposit_type VARCHAR(20) NOT NULL,
    deposit_amount DECIMAL(15,2) NOT NULL,
    deposit_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- 수납 정보
    received_amount DECIMAL(15,2) DEFAULT 0,
    received_date DATE,
    payment_method VARCHAR(20),
    payment_reference VARCHAR(100),
    
    -- 보관 정보
    custody_bank VARCHAR(100),
    custody_account VARCHAR(50),
    custody_account_holder VARCHAR(100),
    
    -- 이자 정보
    interest_rate DECIMAL(8,4) DEFAULT 0,
    interest_calculation_method VARCHAR(20) DEFAULT 'SIMPLE',
    accrued_interest DECIMAL(15,2) DEFAULT 0,
    last_interest_calculation_date DATE,
    
    -- 반환 정보
    return_amount DECIMAL(15,2),
    return_date DATE,
    return_method VARCHAR(20),
    return_account_info JSONB,
    deduction_amount DECIMAL(15,2) DEFAULT 0,
    deduction_reason TEXT,
    
    -- 대체 정보
    substitute_type VARCHAR(20),
    substitute_details JSONB,
    substitute_amount DECIMAL(15,2),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_deposit_management_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_deposit_management_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_deposit_type CHECK (deposit_type IN (
        'SECURITY_DEPOSIT', 'KEY_MONEY', 'GUARANTEE_DEPOSIT', 'MAINTENANCE_DEPOSIT'
    )),
    CONSTRAINT chk_deposit_status CHECK (deposit_status IN (
        'PENDING', 'RECEIVED', 'HELD', 'RETURNED', 'FORFEITED', 'SUBSTITUTED'
    )),
    CONSTRAINT chk_interest_calculation_method CHECK (interest_calculation_method IN (
        'SIMPLE', 'COMPOUND', 'NONE'
    )),
    CONSTRAINT chk_substitute_type CHECK (substitute_type IN (
        'INSURANCE', 'GUARANTEE', 'BOND', 'LETTER_OF_CREDIT'
    )),
    CONSTRAINT chk_amounts_deposit CHECK (
        deposit_amount > 0 AND received_amount >= 0 AND
        accrued_interest >= 0 AND
        (return_amount IS NULL OR return_amount >= 0) AND
        deduction_amount >= 0 AND
        (substitute_amount IS NULL OR substitute_amount >= 0)
    ),
    CONSTRAINT chk_interest_rate CHECK (interest_rate >= 0 AND interest_rate <= 100)
);-- 4.
 임대료 수납 테이블
CREATE TABLE IF NOT EXISTS bms.rental_fee_payments (
    payment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    charge_id UUID NOT NULL,
    
    -- 수납 기본 정보
    payment_number VARCHAR(50) NOT NULL,
    payment_amount DECIMAL(15,2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    
    -- 결제 상세 정보
    payment_reference VARCHAR(100),
    bank_name VARCHAR(100),
    account_number VARCHAR(50),
    account_holder VARCHAR(100),
    
    -- 할당 정보
    allocated_to_rent DECIMAL(15,2) DEFAULT 0,
    allocated_to_maintenance DECIMAL(15,2) DEFAULT 0,
    allocated_to_utility DECIMAL(15,2) DEFAULT 0,
    allocated_to_late_fee DECIMAL(15,2) DEFAULT 0,
    allocated_to_other DECIMAL(15,2) DEFAULT 0,
    
    -- 처리 정보
    payment_status VARCHAR(20) DEFAULT 'COMPLETED',
    processed_by UUID,
    processing_notes TEXT,
    
    -- 취소/환불 정보
    is_cancelled BOOLEAN DEFAULT false,
    cancelled_date DATE,
    cancelled_reason TEXT,
    refund_amount DECIMAL(15,2) DEFAULT 0,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_rental_fee_payments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rental_fee_payments_charge FOREIGN KEY (charge_id) REFERENCES bms.rental_fee_charges(charge_id) ON DELETE CASCADE,
    CONSTRAINT uk_rental_fee_payments_number UNIQUE (company_id, payment_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_payment_method_rental CHECK (payment_method IN (
        'BANK_TRANSFER', 'CASH', 'CHECK', 'CREDIT_CARD', 'AUTO_DEBIT', 'MOBILE_PAY'
    )),
    CONSTRAINT chk_payment_status_rental CHECK (payment_status IN (
        'PENDING', 'COMPLETED', 'FAILED', 'CANCELLED', 'REFUNDED'
    )),
    CONSTRAINT chk_amounts_payment CHECK (
        payment_amount > 0 AND
        allocated_to_rent >= 0 AND allocated_to_maintenance >= 0 AND
        allocated_to_utility >= 0 AND allocated_to_late_fee >= 0 AND
        allocated_to_other >= 0 AND refund_amount >= 0 AND
        (allocated_to_rent + allocated_to_maintenance + allocated_to_utility + 
         allocated_to_late_fee + allocated_to_other) <= payment_amount
    )
);-- 5. RLS
 정책 활성화
ALTER TABLE bms.rental_fee_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.rental_fee_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.deposit_management ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.rental_fee_payments ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY rental_fee_policies_isolation_policy ON bms.rental_fee_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY rental_fee_charges_isolation_policy ON bms.rental_fee_charges
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY deposit_management_isolation_policy ON bms.deposit_management
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY rental_fee_payments_isolation_policy ON bms.rental_fee_payments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 임대료 정책 인덱스
CREATE INDEX IF NOT EXISTS idx_rental_fee_policies_company_id ON bms.rental_fee_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_policies_building_id ON bms.rental_fee_policies(building_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_policies_type ON bms.rental_fee_policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_rental_fee_policies_active ON bms.rental_fee_policies(is_active);

-- 임대료 부과 인덱스
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_company_id ON bms.rental_fee_charges(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_contract_id ON bms.rental_fee_charges(contract_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_status ON bms.rental_fee_charges(charge_status);
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_due_date ON bms.rental_fee_charges(due_date);
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_period ON bms.rental_fee_charges(charge_year, charge_month);

-- 보증금 관리 인덱스
CREATE INDEX IF NOT EXISTS idx_deposit_management_company_id ON bms.deposit_management(company_id);
CREATE INDEX IF NOT EXISTS idx_deposit_management_contract_id ON bms.deposit_management(contract_id);
CREATE INDEX IF NOT EXISTS idx_deposit_management_status ON bms.deposit_management(deposit_status);
CREATE INDEX IF NOT EXISTS idx_deposit_management_type ON bms.deposit_management(deposit_type);

-- 임대료 수납 인덱스
CREATE INDEX IF NOT EXISTS idx_rental_fee_payments_company_id ON bms.rental_fee_payments(company_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_payments_charge_id ON bms.rental_fee_payments(charge_id);
CREATE INDEX IF NOT EXISTS idx_rental_fee_payments_date ON bms.rental_fee_payments(payment_date DESC);
CREATE INDEX IF NOT EXISTS idx_rental_fee_payments_status ON bms.rental_fee_payments(payment_status);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_company_status ON bms.rental_fee_charges(company_id, charge_status);
CREATE INDEX IF NOT EXISTS idx_rental_fee_charges_contract_period ON bms.rental_fee_charges(contract_id, charge_year, charge_month);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER rental_fee_policies_updated_at_trigger
    BEFORE UPDATE ON bms.rental_fee_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER rental_fee_charges_updated_at_trigger
    BEFORE UPDATE ON bms.rental_fee_charges
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER deposit_management_updated_at_trigger
    BEFORE UPDATE ON bms.deposit_management
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER rental_fee_payments_updated_at_trigger
    BEFORE UPDATE ON bms.rental_fee_payments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '임대료 및 보증금 관리 시스템 테이블 생성이 완료되었습니다.' as message;