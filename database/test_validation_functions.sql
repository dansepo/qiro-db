-- =====================================================
-- 테스트 검증을 위한 함수들
-- 작성일: 2025-01-30
-- 설명: 비즈니스 규칙 검증을 위한 유틸리티 함수들
-- =====================================================

-- 사업자등록번호 유효성 검증 함수
CREATE OR REPLACE FUNCTION validate_business_registration_number(brn TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    check_digit INTEGER;
    sum_value INTEGER := 0;
    multipliers INTEGER[] := ARRAY[1,3,7,1,3,7,1,3,5];
    i INTEGER;
BEGIN
    -- NULL이나 빈 문자열 체크
    IF brn IS NULL OR LENGTH(brn) != 10 THEN
        RETURN FALSE;
    END IF;
    
    -- 숫자만 포함되어 있는지 체크
    IF brn !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 체크섬 계산
    FOR i IN 1..9 LOOP
        sum_value := sum_value + (SUBSTRING(brn, i, 1)::INTEGER * multipliers[i]);
    END LOOP;
    
    check_digit := sum_value % 10;
    IF check_digit != 0 THEN
        check_digit := 10 - check_digit;
    END IF;
    
    -- 마지막 자리수와 체크섬 비교
    RETURN check_digit = SUBSTRING(brn, 10, 1)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- 연체료 계산 함수
CREATE OR REPLACE FUNCTION calculate_late_fee(
    base_amount DECIMAL,
    overdue_days INTEGER,
    annual_rate DECIMAL,
    grace_period_days INTEGER DEFAULT 0
) RETURNS DECIMAL AS $$
BEGIN
    -- 유예기간 내인 경우 연체료 없음
    IF overdue_days <= grace_period_days THEN
        RETURN 0;
    END IF;
    
    -- 일할 계산 (연 이율을 일 이율로 변환)
    RETURN ROUND(
        base_amount * (annual_rate / 365.0) * (overdue_days - grace_period_days), 
        0
    );
END;
$$ LANGUAGE plpgsql;

-- 미납 상태 업데이트 함수
CREATE OR REPLACE FUNCTION update_delinquency_status(building_id_param BIGINT)
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    -- 미납 상태 업데이트 로직 (실제 구현에서는 더 복잡할 수 있음)
    UPDATE delinquencies 
    SET updated_at = CURRENT_TIMESTAMP
    WHERE invoice_id IN (
        SELECT i.id 
        FROM invoices i 
        JOIN billing_months bm ON i.billing_month_id = bm.id 
        WHERE bm.building_id = building_id_param
    );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- 호실 상태 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_unit_status_on_contract_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 계약이 활성화되면 호실을 OCCUPIED로 변경
    IF NEW.status = 'ACTIVE' AND CURRENT_DATE BETWEEN NEW.start_date AND NEW.end_date THEN
        UPDATE units SET status = 'OCCUPIED' WHERE id = NEW.unit_id;
    -- 계약이 종료되면 호실을 AVAILABLE로 변경
    ELSIF NEW.status = 'TERMINATED' OR CURRENT_DATE > NEW.end_date THEN
        UPDATE units SET status = 'AVAILABLE' WHERE id = NEW.unit_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 건물 총 호실 수 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_building_total_units()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE buildings 
        SET total_units = (SELECT COUNT(*) FROM units WHERE building_id = NEW.building_id)
        WHERE id = NEW.building_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE buildings 
        SET total_units = (SELECT COUNT(*) FROM units WHERE building_id = OLD.building_id)
        WHERE id = OLD.building_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 회계 전표 차변/대변 검증 함수
CREATE OR REPLACE FUNCTION validate_journal_entry_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- 차변과 대변이 일치하지 않으면 오류 발생
    IF NEW.total_debit != NEW.total_credit THEN
        RAISE EXCEPTION '차변(%)과 대변(%)이 일치하지 않습니다.', NEW.total_debit, NEW.total_credit;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 수납 금액 검증 함수
CREATE OR REPLACE FUNCTION validate_payment_amount()
RETURNS TRIGGER AS $$
DECLARE
    invoice_total DECIMAL;
    paid_amount DECIMAL;
BEGIN
    -- 고지서 총액 조회
    SELECT (subtotal_amount + tax_amount) INTO invoice_total
    FROM invoices WHERE id = NEW.invoice_id;
    
    -- 기존 수납 금액 조회
    SELECT COALESCE(SUM(amount), 0) INTO paid_amount
    FROM payments 
    WHERE invoice_id = NEW.invoice_id 
      AND payment_status = 'COMPLETED'
      AND id != COALESCE(NEW.id, 0);
    
    -- 총 수납 금액이 고지서 금액을 초과하는지 검증
    IF (paid_amount + NEW.amount) > invoice_total THEN
        RAISE EXCEPTION '수납 금액(%)이 고지서 총액(%)을 초과합니다.', 
            (paid_amount + NEW.amount), invoice_total;
    END IF;
    
    -- 음수 금액 방지
    IF NEW.amount <= 0 THEN
        RAISE EXCEPTION '수납 금액은 0보다 커야 합니다.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 관리비 항목 설정 검증 함수
CREATE OR REPLACE FUNCTION validate_fee_item_configuration()
RETURNS TRIGGER AS $$
BEGIN
    -- 고정금액 방식인 경우 fixed_amount 필수
    IF NEW.calculation_method = 'FIXED_AMOUNT' AND NEW.fixed_amount IS NULL THEN
        RAISE EXCEPTION '고정금액 방식의 경우 fixed_amount가 필요합니다.';
    END IF;
    
    -- 단가 방식인 경우 unit_price 필수
    IF NEW.calculation_method = 'UNIT_PRICE' AND NEW.unit_price IS NULL THEN
        RAISE EXCEPTION '단가 방식의 경우 unit_price가 필요합니다.';
    END IF;
    
    -- 면적 기준인 경우 unit_price 필수
    IF NEW.calculation_method = 'AREA_BASED' AND NEW.unit_price IS NULL THEN
        RAISE EXCEPTION '면적 기준 방식의 경우 unit_price가 필요합니다.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 납부 정책 검증 함수
CREATE OR REPLACE FUNCTION validate_payment_policy()
RETURNS TRIGGER AS $$
BEGIN
    -- 연체료율 범위 검증 (0-10%)
    IF NEW.late_fee_rate < 0 OR NEW.late_fee_rate > 0.10 THEN
        RAISE EXCEPTION '연체료율은 0%에서 10% 사이여야 합니다.';
    END IF;
    
    -- 납부 기한일 범위 검증 (1-31일)
    IF NEW.payment_due_day < 1 OR NEW.payment_due_day > 31 THEN
        RAISE EXCEPTION '납부 기한일은 1일에서 31일 사이여야 합니다.';
    END IF;
    
    -- 유예기간 음수 방지
    IF NEW.grace_period_days < 0 THEN
        RAISE EXCEPTION '유예기간은 0일 이상이어야 합니다.';
    END IF;
    
    -- 자동출금 설정 시 은행 정보 필수
    IF NEW.auto_debit_enabled = true AND (NEW.bank_name IS NULL OR NEW.account_number IS NULL) THEN
        RAISE EXCEPTION '자동출금 설정 시 은행명과 계좌번호가 필요합니다.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMIT;