-- =====================================================
-- 임대료 부과 및 수납 관리 함수 생성 스크립트
-- Phase 3.2.2: 임대료 부과 및 수납 함수
-- =====================================================

-- 1. 월별 임대료 자동 부과 함수
CREATE OR REPLACE FUNCTION bms.generate_monthly_rental_charges(
    p_company_id UUID,
    p_charge_year INTEGER,
    p_charge_month INTEGER,
    p_building_id UUID DEFAULT NULL
) RETURNS TABLE (
    generated_count INTEGER,
    total_amount DECIMAL(15,2),
    charge_details JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_charge_id UUID;
    v_charge_number VARCHAR(50);
    v_generated_count INTEGER := 0;
    v_total_amount DECIMAL(15,2) := 0;
    v_charge_details JSONB := '[]'::jsonb;
    v_period_start DATE;
    v_period_end DATE;
    v_due_date DATE;
    v_total_charge DECIMAL(15,2);
BEGIN
    -- 부과 기간 계산
    v_period_start := DATE(p_charge_year || '-' || LPAD(p_charge_month::TEXT, 2, '0') || '-01');
    v_period_end := (v_period_start + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    v_due_date := v_period_start + INTERVAL '1 month' + INTERVAL '5 days';
    
    -- 활성 계약들에 대해 임대료 부과 생성
    FOR v_contract IN
        SELECT 
            lc.contract_id,
            lc.contract_number,
            lc.monthly_rent,
            lc.maintenance_fee,
            lc.rent_payment_day,
            u.unit_id,
            u.unit_number,
            b.building_id
        FROM bms.lease_contracts lc
        JOIN bms.units u ON lc.unit_id = u.unit_id
        JOIN bms.buildings b ON u.building_id = b.building_id
        WHERE lc.company_id = p_company_id
        AND lc.contract_status = 'ACTIVE'
        AND lc.contract_start_date <= v_period_end
        AND lc.contract_end_date >= v_period_start
        AND (p_building_id IS NULL OR b.building_id = p_building_id)
        AND NOT EXISTS (
            SELECT 1 FROM bms.rental_fee_charges rfc
            WHERE rfc.contract_id = lc.contract_id
            AND rfc.charge_year = p_charge_year
            AND rfc.charge_month = p_charge_month
        )
    LOOP
        -- 부과 번호 생성
        v_charge_number := 'RC' || TO_CHAR(v_period_start, 'YYYYMM') || '-' || 
                          REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
        
        -- 총 부과 금액 계산
        v_total_charge := v_contract.monthly_rent + COALESCE(v_contract.maintenance_fee, 0);
        
        -- 임대료 부과 생성
        INSERT INTO bms.rental_fee_charges (
            company_id,
            contract_id,
            charge_number,
            charge_type,
            charge_year,
            charge_month,
            charge_period_start,
            charge_period_end,
            base_rent_amount,
            maintenance_fee_amount,
            total_charge_amount,
            due_date,
            charge_status
        ) VALUES (
            p_company_id,
            v_contract.contract_id,
            v_charge_number,
            'MONTHLY_RENT',
            p_charge_year,
            p_charge_month,
            v_period_start,
            v_period_end,
            v_contract.monthly_rent,
            COALESCE(v_contract.maintenance_fee, 0),
            v_total_charge,
            v_due_date,
            'ISSUED'
        ) RETURNING charge_id INTO v_charge_id;
        
        -- 통계 업데이트
        v_generated_count := v_generated_count + 1;
        v_total_amount := v_total_amount + v_total_charge;
        
        -- 상세 정보 추가
        v_charge_details := v_charge_details || jsonb_build_object(
            'charge_id', v_charge_id,
            'contract_number', v_contract.contract_number,
            'unit_number', v_contract.unit_number,
            'charge_amount', v_total_charge
        );
    END LOOP;
    
    RETURN QUERY SELECT v_generated_count, v_total_amount, v_charge_details;
END;
$$;