-- =====================================================
-- 보증금 관리 함수 생성 스크립트
-- Phase 3.2.3: 보증금 관리 함수
-- =====================================================

-- 1. 보증금 수납 처리 함수
CREATE OR REPLACE FUNCTION bms.process_deposit_receipt(
    p_company_id UUID,
    p_contract_id UUID,
    p_deposit_amount DECIMAL(15,2),
    p_receipt_date DATE,
    p_payment_method VARCHAR(20),
    p_payment_reference VARCHAR(100) DEFAULT NULL,
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_account_number VARCHAR(50) DEFAULT NULL,
    p_account_holder VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_receipt_id UUID;
    v_receipt_number VARCHAR(50);
    v_contract RECORD;
    v_total_received DECIMAL(15,2);
BEGIN
    -- 계약 정보 조회
    SELECT lc.*, u.unit_number, b.name as building_name
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 수납 번호 생성
    v_receipt_number := 'DR' || TO_CHAR(p_receipt_date, 'YYYYMMDD') || '-' || 
                       REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- 기존 수납 금액 확인
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_total_received
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- 초과 수납 확인
    IF (v_total_received + p_deposit_amount) > v_contract.deposit_amount THEN
        RAISE EXCEPTION '보증금 초과 수납입니다. 계약 보증금: %, 기존 수납: %, 추가 수납: %', 
            v_contract.deposit_amount, v_total_received, p_deposit_amount;
    END IF;
    
    -- 보증금 수납 기록 생성
    INSERT INTO bms.deposit_receipts (
        company_id,
        contract_id,
        receipt_number,
        deposit_amount,
        receipt_date,
        payment_method,
        payment_reference,
        bank_name,
        account_number,
        account_holder,
        processed_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_receipt_number,
        p_deposit_amount,
        p_receipt_date,
        p_payment_method,
        p_payment_reference,
        p_bank_name,
        p_account_number,
        p_account_holder,
        p_processed_by
    ) RETURNING receipt_id INTO v_receipt_id;
    
    -- 계약 보증금 상태 업데이트
    PERFORM bms.update_contract_deposit_status(p_contract_id);
    
    RETURN v_receipt_id;
END;
$$;-- 2
. 보증금 이자 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_deposit_interest(
    p_company_id UUID,
    p_contract_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(15,2) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_deposit_amount DECIMAL(15,2);
    v_interest_rate DECIMAL(5,4);
    v_interest_amount DECIMAL(15,2) := 0;
    v_days_held INTEGER;
    v_annual_interest DECIMAL(15,2);
BEGIN
    -- 계약 정보 조회
    SELECT lc.*, dp.interest_rate, dp.interest_calculation_method
    INTO v_contract
    FROM bms.lease_contracts lc
    LEFT JOIN bms.deposit_policies dp ON lc.company_id = dp.company_id AND dp.is_active = true
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 보증금 금액 확인
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_deposit_amount
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- 보증금이 없으면 0 반환
    IF v_deposit_amount = 0 THEN
        RETURN 0;
    END IF;
    
    -- 이자율 설정 (기본값: 연 1.5%)
    v_interest_rate := COALESCE(v_contract.interest_rate, 0.015);
    
    -- 보유 일수 계산
    v_days_held := p_calculation_date - v_contract.contract_start_date;
    
    -- 이자 계산 (일할 계산)
    IF v_days_held > 0 THEN
        v_annual_interest := v_deposit_amount * v_interest_rate;
        v_interest_amount := v_annual_interest * v_days_held / 365;
        
        -- 소수점 둘째 자리에서 반올림
        v_interest_amount := ROUND(v_interest_amount, 2);
    END IF;
    
    RETURN v_interest_amount;
END;
$$;

-- 3. 보증금 반환 처리 함수
CREATE OR REPLACE FUNCTION bms.process_deposit_refund(
    p_company_id UUID,
    p_contract_id UUID,
    p_refund_date DATE,
    p_refund_amount DECIMAL(15,2),
    p_interest_amount DECIMAL(15,2) DEFAULT 0,
    p_deduction_amount DECIMAL(15,2) DEFAULT 0,
    p_deduction_reason TEXT DEFAULT NULL,
    p_refund_method VARCHAR(20) DEFAULT 'BANK_TRANSFER',
    p_bank_name VARCHAR(100) DEFAULT NULL,
    p_account_number VARCHAR(50) DEFAULT NULL,
    p_account_holder VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_refund_id UUID;
    v_refund_number VARCHAR(50);
    v_contract RECORD;
    v_total_received DECIMAL(15,2);
    v_net_refund_amount DECIMAL(15,2);
BEGIN
    -- 계약 정보 조회
    SELECT lc.*, u.unit_number, b.name as building_name
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 반환 번호 생성
    v_refund_number := 'DF' || TO_CHAR(p_refund_date, 'YYYYMMDD') || '-' || 
                      REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                      LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- 수납된 보증금 총액 확인
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_total_received
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- 반환 가능 금액 확인
    IF p_refund_amount > v_total_received THEN
        RAISE EXCEPTION '반환 금액이 수납된 보증금을 초과합니다. 수납 금액: %, 반환 요청: %', 
            v_total_received, p_refund_amount;
    END IF;
    
    -- 실제 반환 금액 계산
    v_net_refund_amount := p_refund_amount + p_interest_amount - p_deduction_amount;
    
    -- 보증금 반환 기록 생성
    INSERT INTO bms.deposit_refunds (
        company_id,
        contract_id,
        refund_number,
        refund_date,
        deposit_refund_amount,
        interest_amount,
        deduction_amount,
        deduction_reason,
        net_refund_amount,
        refund_method,
        bank_name,
        account_number,
        account_holder,
        processed_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_refund_number,
        p_refund_date,
        p_refund_amount,
        p_interest_amount,
        p_deduction_amount,
        p_deduction_reason,
        v_net_refund_amount,
        p_refund_method,
        p_bank_name,
        p_account_number,
        p_account_holder,
        p_processed_by
    ) RETURNING refund_id INTO v_refund_id;
    
    -- 계약 보증금 상태 업데이트
    PERFORM bms.update_contract_deposit_status(p_contract_id);
    
    RETURN v_refund_id;
END;
$$;-- 4. 계
약 보증금 상태 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_contract_deposit_status(
    p_contract_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_total_received DECIMAL(15,2);
    v_total_refunded DECIMAL(15,2);
    v_deposit_status VARCHAR(20);
BEGIN
    -- 계약 정보 조회
    SELECT * INTO v_contract
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- 총 수납 금액 계산
    SELECT COALESCE(SUM(deposit_amount), 0)
    INTO v_total_received
    FROM bms.deposit_receipts
    WHERE contract_id = p_contract_id
    AND receipt_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- 총 반환 금액 계산
    SELECT COALESCE(SUM(deposit_refund_amount), 0)
    INTO v_total_refunded
    FROM bms.deposit_refunds
    WHERE contract_id = p_contract_id
    AND refund_status = 'COMPLETED'
    AND is_cancelled = false;
    
    -- 보증금 상태 결정
    IF v_total_received = 0 THEN
        v_deposit_status := 'PENDING';
    ELSIF v_total_received >= v_contract.deposit_amount THEN
        IF v_total_refunded > 0 THEN
            IF v_total_refunded >= v_total_received THEN
                v_deposit_status := 'REFUNDED';
            ELSE
                v_deposit_status := 'PARTIAL_REFUNDED';
            END IF;
        ELSE
            v_deposit_status := 'RECEIVED';
        END IF;
    ELSE
        v_deposit_status := 'PARTIAL_RECEIVED';
    END IF;
    
    -- 계약 보증금 상태 업데이트
    UPDATE bms.lease_contracts
    SET deposit_status = v_deposit_status,
        updated_at = NOW()
    WHERE contract_id = p_contract_id;
    
    RETURN true;
END;
$$;

-- 5. 보증금 대체 처리 함수 (보증보험 등)
CREATE OR REPLACE FUNCTION bms.process_deposit_substitute(
    p_company_id UUID,
    p_contract_id UUID,
    p_substitute_type VARCHAR(20), -- 'INSURANCE', 'GUARANTEE', 'BOND'
    p_substitute_amount DECIMAL(15,2),
    p_provider_name VARCHAR(200),
    p_policy_number VARCHAR(100),
    p_effective_date DATE,
    p_expiry_date DATE,
    p_premium_amount DECIMAL(15,2) DEFAULT 0,
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_substitute_id UUID;
    v_substitute_number VARCHAR(50);
    v_contract RECORD;
BEGIN
    -- 계약 정보 조회
    SELECT lc.*, u.unit_number, b.name as building_name
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 대체 번호 생성
    v_substitute_number := 'DS' || TO_CHAR(p_effective_date, 'YYYYMMDD') || '-' || 
                          REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- 보증금 대체 기록 생성
    INSERT INTO bms.deposit_substitutes (
        company_id,
        contract_id,
        substitute_number,
        substitute_type,
        substitute_amount,
        provider_name,
        policy_number,
        effective_date,
        expiry_date,
        premium_amount,
        processed_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        v_substitute_number,
        p_substitute_type,
        p_substitute_amount,
        p_provider_name,
        p_policy_number,
        p_effective_date,
        p_expiry_date,
        p_premium_amount,
        p_processed_by
    ) RETURNING substitute_id INTO v_substitute_id;
    
    -- 계약 보증금 상태 업데이트
    PERFORM bms.update_contract_deposit_status(p_contract_id);
    
    RETURN v_substitute_id;
END;
$$;-- 6. 
보증금 현황 뷰
CREATE OR REPLACE VIEW bms.v_deposit_status AS
SELECT 
    lc.contract_id,
    lc.company_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- 계약 정보
    lc.deposit_amount as contract_deposit_amount,
    lc.deposit_status,
    lc.contract_start_date,
    lc.contract_end_date,
    
    -- 수납 정보
    COALESCE(receipts.total_received, 0) as total_received_amount,
    COALESCE(receipts.receipt_count, 0) as receipt_count,
    receipts.last_receipt_date,
    
    -- 반환 정보
    COALESCE(refunds.total_refunded, 0) as total_refunded_amount,
    COALESCE(refunds.refund_count, 0) as refund_count,
    refunds.last_refund_date,
    
    -- 대체 정보
    COALESCE(substitutes.total_substitute, 0) as total_substitute_amount,
    COALESCE(substitutes.substitute_count, 0) as substitute_count,
    
    -- 계산된 필드
    (lc.deposit_amount - COALESCE(receipts.total_received, 0) - COALESCE(substitutes.total_substitute, 0)) as outstanding_amount,
    
    -- 이자 계산
    bms.calculate_deposit_interest(lc.company_id, lc.contract_id, CURRENT_DATE) as accrued_interest,
    
    CASE 
        WHEN lc.deposit_status = 'RECEIVED' THEN '수납완료'
        WHEN lc.deposit_status = 'PARTIAL_RECEIVED' THEN '부분수납'
        WHEN lc.deposit_status = 'REFUNDED' THEN '반환완료'
        WHEN lc.deposit_status = 'PARTIAL_REFUNDED' THEN '부분반환'
        WHEN lc.deposit_status = 'PENDING' THEN '수납대기'
        ELSE lc.deposit_status
    END as status_display,
    
    -- 임차인 정보
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone
    
FROM bms.lease_contracts lc
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN (
    SELECT 
        contract_id,
        SUM(deposit_amount) as total_received,
        COUNT(*) as receipt_count,
        MAX(receipt_date) as last_receipt_date
    FROM bms.deposit_receipts
    WHERE receipt_status = 'COMPLETED' AND is_cancelled = false
    GROUP BY contract_id
) receipts ON lc.contract_id = receipts.contract_id
LEFT JOIN (
    SELECT 
        contract_id,
        SUM(deposit_refund_amount) as total_refunded,
        COUNT(*) as refund_count,
        MAX(refund_date) as last_refund_date
    FROM bms.deposit_refunds
    WHERE refund_status = 'COMPLETED' AND is_cancelled = false
    GROUP BY contract_id
) refunds ON lc.contract_id = refunds.contract_id
LEFT JOIN (
    SELECT 
        contract_id,
        SUM(substitute_amount) as total_substitute,
        COUNT(*) as substitute_count
    FROM bms.deposit_substitutes
    WHERE substitute_status = 'ACTIVE' AND is_cancelled = false
    GROUP BY contract_id
) substitutes ON lc.contract_id = substitutes.contract_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true
WHERE lc.contract_status != 'CANCELLED';

-- 7. 보증금 통계 뷰
CREATE OR REPLACE VIEW bms.v_deposit_statistics AS
SELECT 
    company_id,
    
    -- 전체 통계
    COUNT(*) as total_contracts,
    SUM(deposit_amount) as total_deposit_amount,
    
    -- 상태별 통계
    COUNT(*) FILTER (WHERE deposit_status = 'PENDING') as pending_count,
    COUNT(*) FILTER (WHERE deposit_status = 'PARTIAL_RECEIVED') as partial_received_count,
    COUNT(*) FILTER (WHERE deposit_status = 'RECEIVED') as received_count,
    COUNT(*) FILTER (WHERE deposit_status = 'PARTIAL_REFUNDED') as partial_refunded_count,
    COUNT(*) FILTER (WHERE deposit_status = 'REFUNDED') as refunded_count,
    
    -- 금액별 통계
    SUM(deposit_amount) FILTER (WHERE deposit_status = 'RECEIVED') as received_amount,
    SUM(deposit_amount) FILTER (WHERE deposit_status = 'PARTIAL_RECEIVED') as partial_received_amount,
    SUM(deposit_amount) FILTER (WHERE deposit_status = 'PENDING') as pending_amount,
    
    -- 수납률 계산
    CASE 
        WHEN SUM(deposit_amount) > 0 THEN
            ROUND((SUM(deposit_amount) FILTER (WHERE deposit_status IN ('RECEIVED', 'PARTIAL_REFUNDED', 'REFUNDED')) / SUM(deposit_amount) * 100), 2)
        ELSE 0
    END as collection_rate,
    
    -- 평균 보증금
    ROUND(AVG(deposit_amount), 2) as avg_deposit_amount,
    
    -- 최신 업데이트 시간
    MAX(updated_at) as last_updated_at
    
FROM bms.lease_contracts
WHERE contract_status != 'CANCELLED'
GROUP BY company_id;-- 8. 보증금
 만료 알림 함수
CREATE OR REPLACE FUNCTION bms.get_deposit_expiry_alerts(
    p_company_id UUID,
    p_days_ahead INTEGER DEFAULT 30
) RETURNS TABLE (
    contract_id UUID,
    contract_number VARCHAR(50),
    unit_number VARCHAR(20),
    building_name VARCHAR(200),
    tenant_name VARCHAR(100),
    substitute_type VARCHAR(20),
    provider_name VARCHAR(200),
    policy_number VARCHAR(100),
    expiry_date DATE,
    days_until_expiry INTEGER,
    substitute_amount DECIMAL(15,2)
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lc.contract_id,
        lc.contract_number,
        u.unit_number,
        b.name as building_name,
        cp.name as tenant_name,
        ds.substitute_type,
        ds.provider_name,
        ds.policy_number,
        ds.expiry_date,
        (ds.expiry_date - CURRENT_DATE)::INTEGER as days_until_expiry,
        ds.substitute_amount
    FROM bms.deposit_substitutes ds
    JOIN bms.lease_contracts lc ON ds.contract_id = lc.contract_id
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    LEFT JOIN bms.contract_parties cp ON lc.contract_id = cp.contract_id 
        AND cp.party_role = 'TENANT' AND cp.is_primary = true
    WHERE ds.company_id = p_company_id
    AND ds.substitute_status = 'ACTIVE'
    AND ds.is_cancelled = false
    AND ds.expiry_date <= CURRENT_DATE + INTERVAL '%s days' % p_days_ahead
    AND ds.expiry_date >= CURRENT_DATE
    ORDER BY ds.expiry_date ASC;
END;
$$;

-- 9. 보증금 이자 일괄 계산 함수
CREATE OR REPLACE FUNCTION bms.bulk_calculate_deposit_interest(
    p_company_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    calculated_count INTEGER,
    total_interest DECIMAL(15,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_calculated_count INTEGER := 0;
    v_total_interest DECIMAL(15,2) := 0;
    v_interest_amount DECIMAL(15,2);
BEGIN
    -- 활성 계약들에 대해 이자 계산
    FOR v_contract IN
        SELECT contract_id
        FROM bms.lease_contracts
        WHERE company_id = p_company_id
        AND contract_status = 'ACTIVE'
        AND deposit_status IN ('RECEIVED', 'PARTIAL_RECEIVED')
    LOOP
        -- 각 계약의 이자 계산
        SELECT bms.calculate_deposit_interest(
            p_company_id,
            v_contract.contract_id,
            p_calculation_date
        ) INTO v_interest_amount;
        
        IF v_interest_amount > 0 THEN
            v_calculated_count := v_calculated_count + 1;
            v_total_interest := v_total_interest + v_interest_amount;
        END IF;
    END LOOP;
    
    RETURN QUERY SELECT v_calculated_count, v_total_interest;
END;
$$;

-- 10. 코멘트 추가
COMMENT ON FUNCTION bms.process_deposit_receipt(UUID, UUID, DECIMAL, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID) IS '보증금 수납 처리 함수 - 보증금 수납을 기록하고 계약 상태를 업데이트';
COMMENT ON FUNCTION bms.calculate_deposit_interest(UUID, UUID, DATE) IS '보증금 이자 계산 함수 - 보유 기간에 따른 이자를 계산';
COMMENT ON FUNCTION bms.process_deposit_refund(UUID, UUID, DATE, DECIMAL, DECIMAL, DECIMAL, TEXT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, UUID) IS '보증금 반환 처리 함수 - 보증금 반환을 처리하고 이자 및 공제 금액을 계산';
COMMENT ON FUNCTION bms.update_contract_deposit_status(UUID) IS '계약 보증금 상태 업데이트 함수 - 수납 및 반환 현황에 따라 보증금 상태를 자동 업데이트';
COMMENT ON FUNCTION bms.process_deposit_substitute(UUID, UUID, VARCHAR, DECIMAL, VARCHAR, VARCHAR, DATE, DATE, DECIMAL, UUID) IS '보증금 대체 처리 함수 - 보증보험 등 보증금 대체 수단을 등록';
COMMENT ON FUNCTION bms.get_deposit_expiry_alerts(UUID, INTEGER) IS '보증금 만료 알림 함수 - 보증보험 등의 만료 예정 건을 조회';
COMMENT ON FUNCTION bms.bulk_calculate_deposit_interest(UUID, DATE) IS '보증금 이자 일괄 계산 함수 - 모든 활성 계약의 보증금 이자를 일괄 계산';

COMMENT ON VIEW bms.v_deposit_status IS '보증금 현황 뷰 - 계약별 보증금 수납, 반환, 대체 현황을 종합적으로 조회';
COMMENT ON VIEW bms.v_deposit_statistics IS '보증금 통계 뷰 - 회사별 보증금 관리 통계 정보';

-- 스크립트 완료 메시지
SELECT '보증금 관리 함수 생성이 완료되었습니다.' as message;