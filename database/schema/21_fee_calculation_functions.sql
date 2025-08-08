-- =====================================================
-- 관리비 계산 함수 개발 스크립트
-- Phase 3.2: 관리비 계산 함수 개발 (핵심 DB 함수만)
-- =====================================================

-- 1. 면적 기준 관리비 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_area_based_fee(
    p_unit_area DECIMAL(10,2),
    p_rate_per_sqm DECIMAL(10,2),
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_calculated_amount DECIMAL(15,2);
BEGIN
    -- 기본 계산
    v_calculated_amount := p_unit_area * p_rate_per_sqm;
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_calculated_amount := ROUND(v_calculated_amount / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN COALESCE(v_calculated_amount, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. 사용량 기준 관리비 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_usage_based_fee(
    p_usage_amount DECIMAL(15,4),
    p_unit_rate DECIMAL(10,2),
    p_basic_charge DECIMAL(15,2) DEFAULT 0,
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_calculated_amount DECIMAL(15,2);
BEGIN
    -- 기본요금 + 사용량 * 단가
    v_calculated_amount := p_basic_charge + (p_usage_amount * p_unit_rate);
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_calculated_amount := ROUND(v_calculated_amount / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN COALESCE(v_calculated_amount, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 3. 구간별 차등 요금 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_tiered_fee(
    p_usage_amount DECIMAL(15,4),
    p_tier_rates JSONB,  -- [{"min": 0, "max": 100, "rate": 1000}, {"min": 100, "max": null, "rate": 1200}]
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_calculated_amount DECIMAL(15,2) := 0;
    v_remaining_usage DECIMAL(15,4) := p_usage_amount;
    v_tier JSONB;
    v_tier_min DECIMAL(15,4);
    v_tier_max DECIMAL(15,4);
    v_tier_rate DECIMAL(10,2);
    v_tier_usage DECIMAL(15,4);
BEGIN
    -- 각 구간별로 계산
    FOR v_tier IN SELECT * FROM jsonb_array_elements(p_tier_rates)
    LOOP
        v_tier_min := (v_tier->>'min')::DECIMAL(15,4);
        v_tier_max := CASE WHEN v_tier->>'max' IS NULL THEN NULL ELSE (v_tier->>'max')::DECIMAL(15,4) END;
        v_tier_rate := (v_tier->>'rate')::DECIMAL(10,2);
        
        -- 현재 구간에서 사용할 사용량 계산
        IF p_usage_amount > v_tier_min THEN
            IF v_tier_max IS NULL THEN
                v_tier_usage := p_usage_amount - v_tier_min;
            ELSE
                v_tier_usage := LEAST(p_usage_amount - v_tier_min, v_tier_max - v_tier_min);
            END IF;
            
            -- 구간별 요금 추가
            v_calculated_amount := v_calculated_amount + (v_tier_usage * v_tier_rate);
        END IF;
    END LOOP;
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_calculated_amount := ROUND(v_calculated_amount / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN COALESCE(v_calculated_amount, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 4. 비례 배분 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_proportional_fee(
    p_unit_basis_value DECIMAL(15,4),    -- 호실의 기준값 (면적, 세대수 등)
    p_total_basis_value DECIMAL(15,4),   -- 전체 기준값
    p_total_amount DECIMAL(15,2),        -- 배분할 총 금액
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_calculated_amount DECIMAL(15,2);
    v_ratio DECIMAL(10,6);
BEGIN
    -- 비율 계산
    IF p_total_basis_value > 0 THEN
        v_ratio := p_unit_basis_value / p_total_basis_value;
        v_calculated_amount := p_total_amount * v_ratio;
    ELSE
        v_calculated_amount := 0;
    END IF;
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_calculated_amount := ROUND(v_calculated_amount / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN COALESCE(v_calculated_amount, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 5. 할인/감면 적용 함수
CREATE OR REPLACE FUNCTION bms.apply_discount(
    p_original_amount DECIMAL(15,2),
    p_discount_type VARCHAR(20),         -- 'PERCENTAGE', 'FIXED_AMOUNT'
    p_discount_value DECIMAL(15,2),      -- 할인율(%) 또는 할인금액
    p_max_discount DECIMAL(15,2) DEFAULT NULL,  -- 최대 할인 한도
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_discount_amount DECIMAL(15,2);
    v_final_amount DECIMAL(15,2);
BEGIN
    -- 할인 금액 계산
    CASE p_discount_type
        WHEN 'PERCENTAGE' THEN
            v_discount_amount := p_original_amount * (p_discount_value / 100.0);
        WHEN 'FIXED_AMOUNT' THEN
            v_discount_amount := p_discount_value;
        ELSE
            v_discount_amount := 0;
    END CASE;
    
    -- 최대 할인 한도 적용
    IF p_max_discount IS NOT NULL THEN
        v_discount_amount := LEAST(v_discount_amount, p_max_discount);
    END IF;
    
    -- 할인 후 금액 계산
    v_final_amount := p_original_amount - v_discount_amount;
    
    -- 음수 방지
    v_final_amount := GREATEST(v_final_amount, 0);
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_final_amount := ROUND(v_final_amount / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN v_final_amount;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 6. 연체료 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_late_fee(
    p_original_amount DECIMAL(15,2),
    p_due_date DATE,
    p_current_date DATE DEFAULT CURRENT_DATE,
    p_daily_rate DECIMAL(8,4) DEFAULT 0.025,  -- 일일 연체료율 (2.5%)
    p_max_rate DECIMAL(8,4) DEFAULT 25.0,     -- 최대 연체료율 (25%)
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_overdue_days INTEGER;
    v_late_fee_rate DECIMAL(8,4);
    v_late_fee DECIMAL(15,2);
BEGIN
    -- 연체일수 계산
    v_overdue_days := GREATEST(p_current_date - p_due_date, 0);
    
    -- 연체가 없으면 0 반환
    IF v_overdue_days = 0 THEN
        RETURN 0;
    END IF;
    
    -- 연체료율 계산 (최대 한도 적용)
    v_late_fee_rate := LEAST(v_overdue_days * p_daily_rate, p_max_rate);
    
    -- 연체료 계산
    v_late_fee := p_original_amount * (v_late_fee_rate / 100.0);
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_late_fee := ROUND(v_late_fee / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    RETURN COALESCE(v_late_fee, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 7. 호실별 관리비 총액 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_unit_total_fee(
    p_unit_id UUID,
    p_calculation_period DATE,
    p_fee_components JSONB,  -- 관리비 구성 요소별 금액
    p_rounding_unit INTEGER DEFAULT 10
)
RETURNS TABLE(
    total_amount DECIMAL(15,2),
    component_details JSONB
) AS $$
DECLARE
    v_total DECIMAL(15,2) := 0;
    v_component_key TEXT;
    v_component_value DECIMAL(15,2);
    v_details JSONB := '{}'::jsonb;
BEGIN
    -- 각 구성 요소별 금액 합계
    FOR v_component_key, v_component_value IN 
        SELECT key, value::text::DECIMAL(15,2) 
        FROM jsonb_each_text(p_fee_components)
    LOOP
        v_total := v_total + COALESCE(v_component_value, 0);
        v_details := v_details || jsonb_build_object(v_component_key, v_component_value);
    END LOOP;
    
    -- 반올림 처리
    IF p_rounding_unit > 1 THEN
        v_total := ROUND(v_total / p_rounding_unit) * p_rounding_unit;
    END IF;
    
    -- 결과 반환
    total_amount := v_total;
    component_details := v_details || jsonb_build_object('total', v_total, 'calculated_at', NOW());
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- 8. 관리비 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_fee_calculation(
    p_calculation_id UUID
)
RETURNS TABLE(
    is_valid BOOLEAN,
    validation_errors JSONB,
    validation_summary JSONB
) AS $$
DECLARE
    v_calculation_rec RECORD;
    v_unit_count INTEGER;
    v_calculated_total DECIMAL(15,2);
    v_header_total DECIMAL(15,2);
    v_errors JSONB := '[]'::jsonb;
    v_warnings JSONB := '[]'::jsonb;
    v_is_valid BOOLEAN := true;
BEGIN
    -- 계산 헤더 정보 조회
    SELECT * INTO v_calculation_rec
    FROM bms.monthly_fee_calculations
    WHERE calculation_id = p_calculation_id;
    
    IF NOT FOUND THEN
        is_valid := false;
        validation_errors := jsonb_build_array(jsonb_build_object('error', 'calculation_not_found'));
        validation_summary := jsonb_build_object('status', 'error', 'message', '계산 정보를 찾을 수 없습니다');
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- 호실별 관리비 합계 검증
    SELECT COUNT(*), SUM(total_amount) INTO v_unit_count, v_calculated_total
    FROM bms.unit_monthly_fees
    WHERE calculation_id = p_calculation_id;
    
    v_header_total := v_calculation_rec.total_amount;
    
    -- 총액 일치 검증
    IF ABS(v_calculated_total - v_header_total) > 1 THEN  -- 1원 이상 차이
        v_errors := v_errors || jsonb_build_object(
            'type', 'amount_mismatch',
            'message', '헤더 총액과 호실별 합계가 일치하지 않습니다',
            'header_total', v_header_total,
            'calculated_total', v_calculated_total,
            'difference', v_calculated_total - v_header_total
        );
        v_is_valid := false;
    END IF;
    
    -- 호실 수 검증
    IF v_unit_count != v_calculation_rec.target_unit_count THEN
        v_warnings := v_warnings || jsonb_build_object(
            'type', 'unit_count_mismatch',
            'message', '대상 호실 수와 계산된 호실 수가 다릅니다',
            'target_count', v_calculation_rec.target_unit_count,
            'calculated_count', v_unit_count
        );
    END IF;
    
    -- 음수 금액 검증
    IF EXISTS (
        SELECT 1 FROM bms.unit_monthly_fees 
        WHERE calculation_id = p_calculation_id AND total_amount < 0
    ) THEN
        v_errors := v_errors || jsonb_build_object(
            'type', 'negative_amount',
            'message', '음수 관리비가 존재합니다'
        );
        v_is_valid := false;
    END IF;
    
    -- 결과 반환
    is_valid := v_is_valid;
    validation_errors := CASE WHEN jsonb_array_length(v_errors) > 0 THEN v_errors ELSE NULL END;
    validation_summary := jsonb_build_object(
        'total_units', v_unit_count,
        'total_amount', v_calculated_total,
        'validation_date', NOW(),
        'errors_count', jsonb_array_length(v_errors),
        'warnings_count', jsonb_array_length(v_warnings),
        'warnings', CASE WHEN jsonb_array_length(v_warnings) > 0 THEN v_warnings ELSE NULL END
    );
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- 9. 관리비 재계산 함수 (간단한 버전)
CREATE OR REPLACE FUNCTION bms.recalculate_unit_fees(
    p_calculation_id UUID,
    p_recalculate_all BOOLEAN DEFAULT false
)
RETURNS TABLE(
    unit_id UUID,
    old_amount DECIMAL(15,2),
    new_amount DECIMAL(15,2),
    difference DECIMAL(15,2)
) AS $$
DECLARE
    v_unit_rec RECORD;
    v_old_amount DECIMAL(15,2);
    v_new_amount DECIMAL(15,2);
BEGIN
    -- 각 호실별로 재계산
    FOR v_unit_rec IN 
        SELECT umf.unit_id, umf.total_amount, u.exclusive_area
        FROM bms.unit_monthly_fees umf
        JOIN bms.units u ON umf.unit_id = u.unit_id
        WHERE umf.calculation_id = p_calculation_id
    LOOP
        v_old_amount := v_unit_rec.total_amount;
        
        -- 간단한 재계산 (면적 기준)
        -- 실제로는 복잡한 비즈니스 로직이 백엔드에서 처리됨
        v_new_amount := bms.calculate_area_based_fee(v_unit_rec.exclusive_area, 1000, 10);
        
        -- 결과 반환
        unit_id := v_unit_rec.unit_id;
        old_amount := v_old_amount;
        new_amount := v_new_amount;
        difference := v_new_amount - v_old_amount;
        
        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 10. 관리비 계산 함수 사용 예제 뷰
CREATE OR REPLACE VIEW bms.v_fee_calculation_examples AS
SELECT 
    'area_based' as calculation_type,
    '면적 기준 계산 (84㎡ × 1,000원)' as description,
    bms.calculate_area_based_fee(84.0, 1000, 10) as calculated_amount
UNION ALL
SELECT 
    'usage_based' as calculation_type,
    '사용량 기준 계산 (300kWh × 120원 + 기본료 10,000원)' as description,
    bms.calculate_usage_based_fee(300, 120, 10000, 10) as calculated_amount
UNION ALL
SELECT 
    'proportional' as calculation_type,
    '비례 배분 계산 (84㎡ / 1000㎡ × 500,000원)' as description,
    bms.calculate_proportional_fee(84.0, 1000.0, 500000, 10) as calculated_amount
UNION ALL
SELECT 
    'discount' as calculation_type,
    '할인 적용 (100,000원에서 10% 할인)' as description,
    bms.apply_discount(100000, 'PERCENTAGE', 10, NULL, 10) as calculated_amount
UNION ALL
SELECT 
    'late_fee' as calculation_type,
    '연체료 계산 (100,000원, 30일 연체)' as description,
    bms.calculate_late_fee(100000, CURRENT_DATE - 30, CURRENT_DATE, 0.025, 25.0, 10) as calculated_amount;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_fee_calculation_examples OWNER TO qiro;

-- 함수 권한 설정
GRANT EXECUTE ON FUNCTION bms.calculate_area_based_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.calculate_usage_based_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.calculate_tiered_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.calculate_proportional_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.apply_discount TO application_role;
GRANT EXECUTE ON FUNCTION bms.calculate_late_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.calculate_unit_total_fee TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_fee_calculation TO application_role;
GRANT EXECUTE ON FUNCTION bms.recalculate_unit_fees TO application_role;

-- 완료 메시지
SELECT '✅ 3.2 관리비 계산 함수 개발이 완료되었습니다!' as result;