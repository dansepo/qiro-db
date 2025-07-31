-- =====================================================
-- 계약 검증 함수 수정
-- =====================================================

-- 6. 계약 정보 검증 함수 (수정)
CREATE OR REPLACE FUNCTION bms.validate_contract_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 계약 기간 검증
    IF NEW.contract_end_date <= NEW.contract_start_date THEN
        RAISE EXCEPTION '계약 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 계약 기간 (개월) 자동 계산
    NEW.contract_duration_months := EXTRACT(YEAR FROM AGE(NEW.contract_end_date, NEW.contract_start_date)) * 12 + 
                                    EXTRACT(MONTH FROM AGE(NEW.contract_end_date, NEW.contract_start_date));
    
    -- 다음 갱신 예정일 자동 설정 (자동 갱신인 경우)
    IF NEW.auto_renewal = true AND NEW.next_renewal_date IS NULL THEN
        NEW.next_renewal_date := NEW.contract_end_date;
    END IF;
    
    -- 임대료 지급일 검증
    IF NEW.rent_payment_day < 1 OR NEW.rent_payment_day > 31 THEN
        RAISE EXCEPTION '임대료 지급일은 1-31일 범위여야 합니다.';
    END IF;
    
    -- 연체료율 검증
    IF NEW.late_fee_rate < 0 OR NEW.late_fee_rate > 100 THEN
        RAISE EXCEPTION '연체료율은 0-100%% 범위여야 합니다.';
    END IF;
    
    -- 보증금 반환액 검증
    IF NEW.deposit_return_amount IS NOT NULL AND NEW.deposit_return_amount > NEW.deposit_amount THEN
        RAISE EXCEPTION '보증금 반환액은 보증금을 초과할 수 없습니다.';
    END IF;
    
    -- 계약 상태별 검증
    IF NEW.contract_status = 'ACTIVE' THEN
        -- 활성 계약은 서명이 완료되어야 함
        IF NEW.lessor_signature = false OR NEW.tenant_signature = false THEN
            RAISE EXCEPTION '활성 계약은 임대인과 임차인 모두 서명이 완료되어야 합니다.';
        END IF;
        
        -- 계약 체결일이 설정되어야 함
        IF NEW.contract_signed_date IS NULL THEN
            NEW.contract_signed_date := CURRENT_DATE;
        END IF;
    END IF;
    
    -- 해지된 계약은 해지일과 사유가 있어야 함
    IF NEW.contract_status = 'TERMINATED' THEN
        IF NEW.termination_date IS NULL THEN
            NEW.termination_date := CURRENT_DATE;
        END IF;
        IF NEW.termination_reason IS NULL THEN
            RAISE EXCEPTION '해지된 계약은 해지 사유가 필요합니다.';
        END IF;
    END IF;
    
    -- 만료된 계약 자동 처리
    IF NEW.contract_status = 'ACTIVE' AND NEW.contract_end_date < CURRENT_DATE THEN
        NEW.contract_status := 'EXPIRED';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 계약 검증 트리거 생성 (기존 트리거 삭제 후 재생성)
DROP TRIGGER IF EXISTS trg_validate_contract_data ON bms.lease_contracts;
CREATE TRIGGER trg_validate_contract_data
    BEFORE INSERT OR UPDATE ON bms.lease_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.validate_contract_data();

-- 완료 메시지
SELECT '✅ 계약 검증 함수가 수정되었습니다!' as result;