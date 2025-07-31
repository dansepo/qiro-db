-- =====================================================
-- 관리비 항목 마스터 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    fee_item_count INTEGER := 0;
    rate_count INTEGER := 0;
    fee_item_id_var UUID;
BEGIN
    -- 각 회사에 대해 관리비 항목 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 관리비 항목 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 회사 공통 관리비 항목들 생성
        
        -- 일반 관리비
        INSERT INTO bms.fee_items (
            company_id, building_id, item_code, item_name, item_description, item_category,
            calculation_method, unit_price, calculation_unit, billing_cycle, billing_day, due_days,
            is_mandatory, is_system_item, display_order, show_in_invoice
        ) VALUES 
        (company_rec.company_id, NULL, 'MGMT_FEE', '일반관리비', '건물 일반 관리를 위한 기본 관리비', 'MANAGEMENT',
         'AREA_BASED', 2500.0, '㎡', 'MONTHLY', 1, 30, true, true, 1, true),
        (company_rec.company_id, NULL, 'CLEANING_FEE', '청소비', '공용구역 청소를 위한 비용', 'CLEANING',
         'AREA_BASED', 800.0, '㎡', 'MONTHLY', 1, 30, true, true, 3, true);
        
        INSERT INTO bms.fee_items (
            company_id, building_id, item_code, item_name, item_description, item_category,
            calculation_method, base_amount, billing_cycle, billing_day, due_days,
            is_mandatory, is_system_item, display_order, show_in_invoice
        ) VALUES 
        (company_rec.company_id, NULL, 'SECURITY_FEE', '경비비', '건물 보안 및 경비를 위한 비용', 'SECURITY',
         'FIXED', 50000, 'MONTHLY', 1, 30, true, true, 2, true);
        
        fee_item_count := fee_item_count + 3;
        
        -- 공과금 항목들
        INSERT INTO bms.fee_items (
            company_id, building_id, item_code, item_name, item_description, item_category,
            calculation_method, unit_price, calculation_unit, billing_cycle, billing_day, due_days,
            meter_reading_required, tax_rate, display_order, show_in_invoice
        ) VALUES 
        (company_rec.company_id, NULL, 'ELECTRIC', '전기료', '전력 사용에 따른 전기료', 'UTILITY',
         'USAGE_BASED', 120.50, 'kWh', 'MONTHLY', 5, 25, true, 10.0, 4, true),
        (company_rec.company_id, NULL, 'WATER', '수도료', '급수 사용에 따른 수도료', 'UTILITY',
         'USAGE_BASED', 850.0, '㎥', 'MONTHLY', 5, 25, true, 10.0, 5, true),
        (company_rec.company_id, NULL, 'GAS', '가스료', '가스 사용에 따른 가스료', 'UTILITY',
         'USAGE_BASED', 950.0, '㎥', 'MONTHLY', 5, 25, true, 10.0, 6, true);
        
        fee_item_count := fee_item_count + 3;
        
        -- 기타 항목들
        INSERT INTO bms.fee_items (
            company_id, building_id, item_code, item_name, item_description, item_category,
            calculation_method, base_amount, billing_cycle, billing_day, due_days,
            display_order, show_in_invoice, is_mandatory
        ) VALUES 
        (company_rec.company_id, NULL, 'INSURANCE', '건물보험료', '건물 종합보험료', 'INSURANCE',
         'FIXED', 30000, 'MONTHLY', 1, 30, 7, true, false),
        (company_rec.company_id, NULL, 'ELEVATOR', '승강기유지비', '엘리베이터 유지보수 비용', 'FACILITY',
         'UNIT_COUNT', 15000, 'MONTHLY', 1, 30, 9, true, false);
        
        INSERT INTO bms.fee_items (
            company_id, building_id, item_code, item_name, item_description, item_category,
            calculation_method, unit_price, calculation_unit, billing_cycle, billing_day, due_days,
            display_order, show_in_invoice, is_mandatory
        ) VALUES 
        (company_rec.company_id, NULL, 'MAINTENANCE', '시설유지비', '시설 유지보수를 위한 비용', 'MAINTENANCE',
         'AREA_BASED', 1200.0, '㎡', 'MONTHLY', 1, 30, 8, true, false);
        
        fee_item_count := fee_item_count + 4;
        
        -- 2. 각 건물별 특화 관리비 항목들 생성
        FOR building_rec IN 
            SELECT building_id, name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            -- 주차비 (건물별)
            INSERT INTO bms.fee_items (
                company_id, building_id, item_code, item_name, item_description, item_category,
                calculation_method, base_amount, billing_cycle, billing_day, due_days,
                apply_to_all_units, display_order, show_in_invoice
            ) VALUES 
            (company_rec.company_id, building_rec.building_id, 'PARKING', '주차비', 
             building_rec.name || ' 주차장 이용료', 'PARKING',
             'FIXED', 80000, 'MONTHLY', 1, 30, false, 10, true);
            
            fee_item_count := fee_item_count + 1;
            
            -- 난방비 (건물별, 계절별)
            INSERT INTO bms.fee_items (
                company_id, building_id, item_code, item_name, item_description, item_category,
                calculation_method, unit_price, calculation_unit, billing_cycle, billing_day, due_days,
                effective_start_date, effective_end_date, display_order, show_in_invoice
            ) VALUES 
            (company_rec.company_id, building_rec.building_id, 'HEATING', '난방비', 
             building_rec.name || ' 겨울철 난방비', 'UTILITY',
             'AREA_BASED', 1200.0, '㎡', 'MONTHLY', 5, 25,
             '2024-11-01', '2025-03-31', 11, true);
            
            fee_item_count := fee_item_count + 1;
        END LOOP;
        
        RAISE NOTICE '회사 % 관리비 항목 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 3. 관리비 항목별 요율 생성
    
    -- 전기료 누진 요율 생성
    SELECT fee_item_id INTO fee_item_id_var
    FROM bms.fee_items 
    WHERE item_code = 'ELECTRIC' 
    LIMIT 1;
    
    IF fee_item_id_var IS NOT NULL THEN
        INSERT INTO bms.fee_item_rates (
            company_id, fee_item_id, rate_name, rate_type, rate_value,
            min_usage, max_usage, display_order
        ) VALUES 
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '1단계 (0-100kWh)', 'STANDARD', 95.30, 0, 100, 1),
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '2단계 (101-200kWh)', 'STANDARD', 187.90, 101, 200, 2),
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '3단계 (201kWh 이상)', 'STANDARD', 280.60, 201, NULL, 3);
        
        rate_count := rate_count + 3;
    END IF;
    
    -- 수도료 누진 요율 생성
    SELECT fee_item_id INTO fee_item_id_var
    FROM bms.fee_items 
    WHERE item_code = 'WATER' 
    LIMIT 1;
    
    IF fee_item_id_var IS NOT NULL THEN
        INSERT INTO bms.fee_item_rates (
            company_id, fee_item_id, rate_name, rate_type, rate_value,
            min_usage, max_usage, display_order
        ) VALUES 
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '1단계 (0-20㎥)', 'STANDARD', 690.0, 0, 20, 1),
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '2단계 (21-30㎥)', 'STANDARD', 1260.0, 21, 30, 2),
        ((SELECT company_id FROM bms.fee_items WHERE fee_item_id = fee_item_id_var),
         fee_item_id_var, '3단계 (31㎥ 이상)', 'STANDARD', 1840.0, 31, NULL, 3);
        
        rate_count := rate_count + 3;
    END IF;
    
    -- 단가 설정은 이미 INSERT 시 완료됨
    
    -- 일부 항목을 비활성화 (테스트용)
    UPDATE bms.fee_items 
    SET is_active = false
    WHERE item_code = 'ELEVATOR'
      AND fee_item_id IN (
          SELECT fee_item_id 
          FROM bms.fee_items 
          WHERE item_code = 'ELEVATOR'
          ORDER BY RANDOM() 
          LIMIT 1
      );
    
    -- 일부 항목에 유효 종료일 설정 (테스트용)
    UPDATE bms.fee_items 
    SET effective_end_date = CURRENT_DATE + INTERVAL '90 days'
    WHERE item_code = 'HEATING';
    
    RAISE NOTICE '총 % 개의 관리비 항목과 % 개의 요율이 생성되었습니다.', fee_item_count, rate_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.fee_items;
ANALYZE bms.fee_item_rates;

-- 데이터 검증 및 결과 출력
SELECT 
    '관리비 항목 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_fee_items,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_fee_items,
    COUNT(CASE WHEN is_mandatory = true THEN 1 END) as mandatory_fee_items,
    COUNT(CASE WHEN is_system_item = true THEN 1 END) as system_fee_items,
    COUNT(CASE WHEN building_id IS NULL THEN 1 END) as common_fee_items,
    COUNT(CASE WHEN building_id IS NOT NULL THEN 1 END) as building_specific_items
FROM bms.fee_items;

-- 계산 방식별 통계
SELECT 
    '계산 방식별 현황' as info,
    calculation_method,
    COUNT(*) as count,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_count,
    ROUND(AVG(base_amount), 0) as avg_base_amount,
    ROUND(AVG(unit_price), 2) as avg_unit_price
FROM bms.fee_items
GROUP BY calculation_method
ORDER BY count DESC;

-- 항목 분류별 통계
SELECT 
    '항목 분류별 현황' as info,
    item_category,
    COUNT(*) as count,
    COUNT(CASE WHEN is_mandatory = true THEN 1 END) as mandatory_count,
    COUNT(CASE WHEN meter_reading_required = true THEN 1 END) as meter_reading_count
FROM bms.fee_items
GROUP BY item_category
ORDER BY count DESC;

-- 활성 관리비 항목 뷰 테스트
SELECT 
    '활성 관리비 항목' as info,
    item_code,
    item_name,
    item_category,
    calculation_method,
    COALESCE(base_amount, 0) as base_amount,
    COALESCE(unit_price, 0) as unit_price,
    calculation_unit
FROM bms.v_active_fee_items
ORDER BY display_order
LIMIT 10;

-- 건물별 관리비 통계 뷰 테스트
SELECT 
    '건물별 관리비 통계' as info,
    building_name,
    total_fee_items,
    active_fee_items,
    mandatory_fee_items,
    fixed_fee_items,
    area_based_items,
    usage_based_items,
    total_fixed_amount
FROM bms.v_building_fee_statistics
ORDER BY total_fee_items DESC
LIMIT 5;

-- 관리비 계산 함수 테스트
SELECT 
    '관리비 계산 함수 테스트' as info,
    bms.calculate_fee_amount(
        (SELECT fee_item_id FROM bms.fee_items WHERE item_code = 'MGMT_FEE' LIMIT 1),
        50.0  -- 50㎡ 기준
    ) as mgmt_fee_50sqm,
    bms.calculate_fee_amount(
        (SELECT fee_item_id FROM bms.fee_items WHERE item_code = 'SECURITY_FEE' LIMIT 1)
    ) as security_fee_fixed,
    bms.calculate_fee_amount(
        (SELECT fee_item_id FROM bms.fee_items WHERE item_code = 'ELECTRIC' LIMIT 1),
        NULL, 150.0  -- 150kWh 사용량 기준
    ) as electric_fee_150kwh;

-- 완료 메시지
SELECT '✅ 관리비 항목 테스트 데이터 생성이 완료되었습니다!' as result;