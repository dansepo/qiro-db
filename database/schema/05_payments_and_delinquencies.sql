-- =====================================================
-- 수납 처리 및 미납 관리 테이블 설계
-- 작성일: 2025-01-30
-- 설명: 관리비 수납 처리, 미납 관리, 연체료 자동 계산 기능
-- =====================================================

-- 수납 내역 테이블 (payments)
-- 관리비 고지서에 대한 수납 처리 내역을 관리
CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    payment_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(50) NOT NULL CHECK (payment_method IN ('CASH', 'BANK_TRANSFER', 'CARD', 'CMS', 'VIRTUAL_ACCOUNT')),
    payment_reference VARCHAR(100), -- 거래번호, 계좌이체 참조번호 등
    notes TEXT,
    payment_status VARCHAR(20) DEFAULT 'COMPLETED' CHECK (payment_status IN ('PENDING', 'COMPLETED', 'CANCELLED', 'REFUNDED')),
    processed_by BIGINT REFERENCES users(id),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 미납 관리 테이블 (delinquencies)
-- 고지서별 미납 현황 및 연체료 관리
CREATE TABLE delinquencies (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
    overdue_amount DECIMAL(12,2) NOT NULL CHECK (overdue_amount >= 0),
    overdue_days INTEGER NOT NULL CHECK (overdue_days >= 0),
    late_fee DECIMAL(12,2) DEFAULT 0 CHECK (late_fee >= 0),
    late_fee_rate DECIMAL(5,2) NOT NULL CHECK (late_fee_rate >= 0 AND late_fee_rate <= 100),
    grace_period_days INTEGER DEFAULT 0 CHECK (grace_period_days >= 0),
    status VARCHAR(20) DEFAULT 'OVERDUE' CHECK (status IN ('OVERDUE', 'PARTIAL_PAID', 'RESOLVED', 'WRITTEN_OFF')),
    first_overdue_date DATE NOT NULL,
    last_calculated_date DATE DEFAULT CURRENT_DATE,
    resolution_date DATE,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(invoice_id) -- 고지서당 하나의 미납 레코드만 존재
);

-- 수납 상세 내역 테이블 (payment_details)
-- 부분 수납 시 어떤 항목에 얼마가 수납되었는지 추적
CREATE TABLE payment_details (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id),
    allocated_amount DECIMAL(12,2) NOT NULL CHECK (allocated_amount > 0),
    is_late_fee BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 연체료 계산 이력 테이블 (late_fee_calculations)
-- 연체료 계산 과정의 투명성과 추적성 보장
CREATE TABLE late_fee_calculations (
    id BIGSERIAL PRIMARY KEY,
    delinquency_id BIGINT NOT NULL REFERENCES delinquencies(id) ON DELETE CASCADE,
    calculation_date DATE NOT NULL,
    overdue_amount DECIMAL(12,2) NOT NULL,
    overdue_days INTEGER NOT NULL,
    daily_rate DECIMAL(8,6) NOT NULL, -- 일일 연체료율
    calculated_late_fee DECIMAL(12,2) NOT NULL,
    cumulative_late_fee DECIMAL(12,2) NOT NULL,
    calculation_method VARCHAR(50) NOT NULL DEFAULT 'SIMPLE_INTEREST',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 인덱스 생성
-- =====================================================

-- payments 테이블 인덱스
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_payments_payment_date ON payments(payment_date);
CREATE INDEX idx_payments_payment_method ON payments(payment_method);
CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_processed_by ON payments(processed_by);

-- delinquencies 테이블 인덱스
CREATE INDEX idx_delinquencies_status ON delinquencies(status);
CREATE INDEX idx_delinquencies_overdue_days ON delinquencies(overdue_days);
CREATE INDEX idx_delinquencies_first_overdue_date ON delinquencies(first_overdue_date);
CREATE INDEX idx_delinquencies_last_calculated_date ON delinquencies(last_calculated_date);

-- payment_details 테이블 인덱스
CREATE INDEX idx_payment_details_payment_id ON payment_details(payment_id);
CREATE INDEX idx_payment_details_fee_item_id ON payment_details(fee_item_id);

-- late_fee_calculations 테이블 인덱스
CREATE INDEX idx_late_fee_calculations_delinquency_id ON late_fee_calculations(delinquency_id);
CREATE INDEX idx_late_fee_calculations_calculation_date ON late_fee_calculations(calculation_date);

-- =====================================================
-- 연체료 자동 계산 함수
-- =====================================================

-- 연체료 계산 함수 (단리 방식)
CREATE OR REPLACE FUNCTION calculate_late_fee(
    p_overdue_amount DECIMAL(12,2),
    p_overdue_days INTEGER,
    p_late_fee_rate DECIMAL(5,2),
    p_grace_period_days INTEGER DEFAULT 0
) RETURNS DECIMAL(12,2) AS $$
DECLARE
    v_effective_overdue_days INTEGER;
    v_daily_rate DECIMAL(8,6);
    v_late_fee DECIMAL(12,2);
BEGIN
    -- 유예기간 적용
    v_effective_overdue_days := GREATEST(0, p_overdue_days - p_grace_period_days);
    
    -- 연체일이 0일 이하면 연체료 없음
    IF v_effective_overdue_days <= 0 THEN
        RETURN 0;
    END IF;
    
    -- 일일 연체료율 계산 (연 단위 -> 일 단위)
    v_daily_rate := p_late_fee_rate / 365.0;
    
    -- 연체료 계산 (단리)
    v_late_fee := p_overdue_amount * v_daily_rate * v_effective_overdue_days / 100.0;
    
    -- 소수점 둘째 자리에서 반올림
    RETURN ROUND(v_late_fee, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 미납 현황 업데이트 함수
CREATE OR REPLACE FUNCTION update_delinquency_status(p_invoice_id BIGINT)
RETURNS VOID AS $$
DECLARE
    v_invoice_record RECORD;
    v_total_paid DECIMAL(12,2);
    v_overdue_amount DECIMAL(12,2);
    v_overdue_days INTEGER;
    v_late_fee DECIMAL(12,2);
    v_payment_policy RECORD;
    v_delinquency_exists BOOLEAN;
BEGIN
    -- 고지서 정보 조회
    SELECT i.*, bm.billing_year, bm.billing_month, u.building_id
    INTO v_invoice_record
    FROM invoices i
    JOIN billing_months bm ON i.billing_month_id = bm.id
    JOIN units u ON i.unit_id = u.id
    WHERE i.id = p_invoice_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '고지서를 찾을 수 없습니다: %', p_invoice_id;
    END IF;
    
    -- 납부 정책 조회
    SELECT * INTO v_payment_policy
    FROM payment_policies
    WHERE building_id = v_invoice_record.building_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '납부 정책을 찾을 수 없습니다. 건물 ID: %', v_invoice_record.building_id;
    END IF;
    
    -- 총 납부 금액 계산
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
    FROM payments
    WHERE invoice_id = p_invoice_id AND payment_status = 'COMPLETED';
    
    -- 미납 금액 계산
    v_overdue_amount := v_invoice_record.total_amount - v_total_paid;
    
    -- 연체일 계산
    v_overdue_days := GREATEST(0, CURRENT_DATE - v_invoice_record.due_date);
    
    -- 미납이 없는 경우
    IF v_overdue_amount <= 0 THEN
        -- 기존 미납 레코드가 있으면 해결 처리
        UPDATE delinquencies 
        SET status = 'RESOLVED',
            resolution_date = CURRENT_DATE,
            resolution_notes = '전액 납부 완료',
            updated_at = CURRENT_TIMESTAMP
        WHERE invoice_id = p_invoice_id AND status != 'RESOLVED';
        RETURN;
    END IF;
    
    -- 연체료 계산
    v_late_fee := calculate_late_fee(
        v_overdue_amount,
        v_overdue_days,
        v_payment_policy.late_fee_rate,
        v_payment_policy.grace_period_days
    );
    
    -- 미납 레코드 존재 여부 확인
    SELECT EXISTS(SELECT 1 FROM delinquencies WHERE invoice_id = p_invoice_id)
    INTO v_delinquency_exists;
    
    IF v_delinquency_exists THEN
        -- 기존 미납 레코드 업데이트
        UPDATE delinquencies
        SET overdue_amount = v_overdue_amount,
            overdue_days = v_overdue_days,
            late_fee = v_late_fee,
            late_fee_rate = v_payment_policy.late_fee_rate,
            grace_period_days = v_payment_policy.grace_period_days,
            status = CASE 
                WHEN v_total_paid > 0 AND v_overdue_amount > 0 THEN 'PARTIAL_PAID'
                ELSE 'OVERDUE'
            END,
            last_calculated_date = CURRENT_DATE,
            updated_at = CURRENT_TIMESTAMP
        WHERE invoice_id = p_invoice_id;
    ELSE
        -- 새로운 미납 레코드 생성
        INSERT INTO delinquencies (
            invoice_id,
            overdue_amount,
            overdue_days,
            late_fee,
            late_fee_rate,
            grace_period_days,
            status,
            first_overdue_date,
            last_calculated_date
        ) VALUES (
            p_invoice_id,
            v_overdue_amount,
            v_overdue_days,
            v_late_fee,
            v_payment_policy.late_fee_rate,
            v_payment_policy.grace_period_days,
            CASE 
                WHEN v_total_paid > 0 THEN 'PARTIAL_PAID'
                ELSE 'OVERDUE'
            END,
            v_invoice_record.due_date + INTERVAL '1 day',
            CURRENT_DATE
        );
    END IF;
    
    -- 연체료 계산 이력 기록
    INSERT INTO late_fee_calculations (
        delinquency_id,
        calculation_date,
        overdue_amount,
        overdue_days,
        daily_rate,
        calculated_late_fee,
        cumulative_late_fee,
        calculation_method,
        notes
    ) 
    SELECT 
        d.id,
        CURRENT_DATE,
        v_overdue_amount,
        v_overdue_days,
        v_payment_policy.late_fee_rate / 365.0,
        v_late_fee,
        v_late_fee,
        'SIMPLE_INTEREST',
        '자동 계산'
    FROM delinquencies d
    WHERE d.invoice_id = p_invoice_id;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 함수
-- =====================================================

-- 수납 처리 후 미납 상태 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION trigger_update_delinquency_on_payment()
RETURNS TRIGGER AS $$
BEGIN
    -- 수납이 완료된 경우에만 미납 상태 업데이트
    IF NEW.payment_status = 'COMPLETED' THEN
        PERFORM update_delinquency_status(NEW.invoice_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 수납 취소/환불 시 미납 상태 재계산 트리거 함수
CREATE OR REPLACE FUNCTION trigger_recalculate_delinquency_on_payment_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 수납 상태가 변경된 경우 미납 상태 재계산
    IF OLD.payment_status != NEW.payment_status THEN
        PERFORM update_delinquency_status(NEW.invoice_id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 고지서 생성 시 미납 상태 초기화 트리거 함수
CREATE OR REPLACE FUNCTION trigger_initialize_delinquency_on_invoice()
RETURNS TRIGGER AS $$
BEGIN
    -- 고지서 발급일로부터 납기일이 지난 경우에만 미납 레코드 생성
    IF NEW.due_date < CURRENT_DATE THEN
        PERFORM update_delinquency_status(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 생성
-- =====================================================

-- 수납 완료 시 미납 상태 자동 업데이트
CREATE TRIGGER trg_payment_insert_update_delinquency
    AFTER INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_update_delinquency_on_payment();

-- 수납 상태 변경 시 미납 상태 재계산
CREATE TRIGGER trg_payment_update_recalculate_delinquency
    AFTER UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recalculate_delinquency_on_payment_change();

-- 고지서 생성 시 미납 상태 초기화 (기존 고지서에 대해서만)
CREATE TRIGGER trg_invoice_insert_initialize_delinquency
    AFTER INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION trigger_initialize_delinquency_on_invoice();

-- =====================================================
-- 데이터 무결성 제약조건
-- =====================================================

-- 수납 금액이 고지서 총액을 초과하지 않도록 하는 제약조건 함수
CREATE OR REPLACE FUNCTION check_payment_amount_constraint()
RETURNS TRIGGER AS $$
DECLARE
    v_invoice_total DECIMAL(12,2);
    v_total_paid DECIMAL(12,2);
BEGIN
    -- 고지서 총액 조회
    SELECT total_amount INTO v_invoice_total
    FROM invoices
    WHERE id = NEW.invoice_id;
    
    -- 기존 납부 총액 + 신규 납부액 계산
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM payments
    WHERE invoice_id = NEW.invoice_id 
      AND payment_status = 'COMPLETED'
      AND id != COALESCE(NEW.id, -1); -- UPDATE 시 자기 자신 제외
    
    -- 총 납부액이 고지서 총액을 초과하는지 확인
    IF (v_total_paid + NEW.amount) > v_invoice_total THEN
        RAISE EXCEPTION '납부 금액이 고지서 총액을 초과할 수 없습니다. 고지서 총액: %, 기존 납부액: %, 신규 납부액: %', 
            v_invoice_total, v_total_paid, NEW.amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 수납 금액 제약조건 트리거
CREATE TRIGGER trg_check_payment_amount
    BEFORE INSERT OR UPDATE ON payments
    FOR EACH ROW
    EXECUTE FUNCTION check_payment_amount_constraint();

-- 수납 상세 내역 합계가 수납 총액과 일치하는지 확인하는 제약조건 함수
CREATE OR REPLACE FUNCTION check_payment_details_sum_constraint()
RETURNS TRIGGER AS $$
DECLARE
    v_payment_amount DECIMAL(12,2);
    v_details_sum DECIMAL(12,2);
BEGIN
    -- 수납 총액 조회
    SELECT amount INTO v_payment_amount
    FROM payments
    WHERE id = NEW.payment_id;
    
    -- 수납 상세 내역 합계 계산
    SELECT COALESCE(SUM(allocated_amount), 0) INTO v_details_sum
    FROM payment_details
    WHERE payment_id = NEW.payment_id
      AND id != COALESCE(NEW.id, -1); -- UPDATE 시 자기 자신 제외
    
    -- 상세 내역 합계가 수납 총액을 초과하는지 확인
    IF (v_details_sum + NEW.allocated_amount) > v_payment_amount THEN
        RAISE EXCEPTION '수납 상세 내역 합계가 수납 총액을 초과할 수 없습니다. 수납 총액: %, 기존 상세 합계: %, 신규 배분액: %', 
            v_payment_amount, v_details_sum, NEW.allocated_amount;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 수납 상세 내역 합계 제약조건 트리거
CREATE TRIGGER trg_check_payment_details_sum
    BEFORE INSERT OR UPDATE ON payment_details
    FOR EACH ROW
    EXECUTE FUNCTION check_payment_details_sum_constraint();

-- =====================================================
-- 유용한 뷰 생성
-- =====================================================

-- 미납 현황 종합 뷰
CREATE VIEW v_delinquency_summary AS
SELECT 
    d.id,
    d.invoice_id,
    i.billing_month_id,
    bm.billing_year,
    bm.billing_month,
    b.name as building_name,
    u.unit_number,
    t.name as tenant_name,
    t.contact_phone as tenant_phone,
    i.total_amount as invoice_amount,
    COALESCE(p.total_paid, 0) as paid_amount,
    d.overdue_amount,
    d.overdue_days,
    d.late_fee,
    d.overdue_amount + d.late_fee as total_overdue,
    d.status,
    d.first_overdue_date,
    d.last_calculated_date,
    pp.late_fee_rate,
    pp.grace_period_days
FROM delinquencies d
JOIN invoices i ON d.invoice_id = i.id
JOIN billing_months bm ON i.billing_month_id = bm.id
JOIN units u ON i.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
LEFT JOIN lease_contracts lc ON u.id = lc.unit_id 
    AND lc.status = 'ACTIVE'
    AND CURRENT_DATE BETWEEN lc.start_date AND lc.end_date
LEFT JOIN tenants t ON lc.tenant_id = t.id
LEFT JOIN payment_policies pp ON b.id = pp.building_id
LEFT JOIN (
    SELECT 
        invoice_id,
        SUM(amount) as total_paid
    FROM payments
    WHERE payment_status = 'COMPLETED'
    GROUP BY invoice_id
) p ON i.id = p.invoice_id
WHERE d.status IN ('OVERDUE', 'PARTIAL_PAID');

-- 수납 현황 종합 뷰
CREATE VIEW v_payment_summary AS
SELECT 
    p.id,
    p.invoice_id,
    i.billing_month_id,
    bm.billing_year,
    bm.billing_month,
    b.name as building_name,
    u.unit_number,
    t.name as tenant_name,
    p.payment_date,
    p.amount,
    p.payment_method,
    p.payment_status,
    p.payment_reference,
    i.total_amount as invoice_amount,
    i.due_date,
    CASE 
        WHEN p.payment_date <= i.due_date THEN '정상납부'
        ELSE '연체납부'
    END as payment_type,
    u2.full_name as processed_by_name
FROM payments p
JOIN invoices i ON p.invoice_id = i.id
JOIN billing_months bm ON i.billing_month_id = bm.id
JOIN units u ON i.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
LEFT JOIN lease_contracts lc ON u.id = lc.unit_id 
    AND lc.status = 'ACTIVE'
    AND p.payment_date BETWEEN lc.start_date AND lc.end_date
LEFT JOIN tenants t ON lc.tenant_id = t.id
LEFT JOIN users u2 ON p.processed_by = u2.id;

-- =====================================================
-- 코멘트 추가
-- =====================================================

COMMENT ON TABLE payments IS '관리비 수납 내역 테이블';
COMMENT ON COLUMN payments.invoice_id IS '고지서 ID (외래키)';
COMMENT ON COLUMN payments.payment_date IS '수납일';
COMMENT ON COLUMN payments.amount IS '수납 금액';
COMMENT ON COLUMN payments.payment_method IS '수납 방법 (현금, 계좌이체, 카드, CMS, 가상계좌)';
COMMENT ON COLUMN payments.payment_reference IS '거래 참조번호';
COMMENT ON COLUMN payments.payment_status IS '수납 상태 (대기, 완료, 취소, 환불)';

COMMENT ON TABLE delinquencies IS '미납 관리 테이블';
COMMENT ON COLUMN delinquencies.invoice_id IS '고지서 ID (외래키, 유니크)';
COMMENT ON COLUMN delinquencies.overdue_amount IS '미납 금액';
COMMENT ON COLUMN delinquencies.overdue_days IS '연체 일수';
COMMENT ON COLUMN delinquencies.late_fee IS '연체료';
COMMENT ON COLUMN delinquencies.late_fee_rate IS '연체료율 (연 %)';
COMMENT ON COLUMN delinquencies.grace_period_days IS '유예 기간 (일)';
COMMENT ON COLUMN delinquencies.status IS '미납 상태 (연체, 부분납부, 해결, 손실처리)';

COMMENT ON TABLE payment_details IS '수납 상세 내역 테이블 - 부분 수납 시 항목별 배분 추적';
COMMENT ON COLUMN payment_details.payment_id IS '수납 ID (외래키)';
COMMENT ON COLUMN payment_details.fee_item_id IS '관리비 항목 ID (외래키)';
COMMENT ON COLUMN payment_details.allocated_amount IS '배분 금액';
COMMENT ON COLUMN payment_details.is_late_fee IS '연체료 여부';

COMMENT ON TABLE late_fee_calculations IS '연체료 계산 이력 테이블 - 계산 과정의 투명성 보장';
COMMENT ON COLUMN late_fee_calculations.delinquency_id IS '미납 ID (외래키)';
COMMENT ON COLUMN late_fee_calculations.calculation_date IS '계산일';
COMMENT ON COLUMN late_fee_calculations.daily_rate IS '일일 연체료율';
COMMENT ON COLUMN late_fee_calculations.calculated_late_fee IS '계산된 연체료';
COMMENT ON COLUMN late_fee_calculations.cumulative_late_fee IS '누적 연체료';

COMMENT ON FUNCTION calculate_late_fee(DECIMAL, INTEGER, DECIMAL, INTEGER) IS '연체료 계산 함수 (단리 방식)';
COMMENT ON FUNCTION update_delinquency_status(BIGINT) IS '미납 현황 업데이트 함수';

COMMENT ON VIEW v_delinquency_summary IS '미납 현황 종합 뷰 - 건물, 호실, 임차인 정보 포함';
COMMENT ON VIEW v_payment_summary IS '수납 현황 종합 뷰 - 건물, 호실, 임차인 정보 포함';