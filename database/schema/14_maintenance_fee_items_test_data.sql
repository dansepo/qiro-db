-- =====================================================
-- 관리비 항목 마스터 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    category_count INTEGER := 0;
    item_count INTEGER := 0;
    setting_count INTEGER := 0;
    
    -- 분류 ID 저장용 변수들
    general_category_id UUID;
    utility_category_id UUID;
    facility_category_id UUID;
    security_category_id UUID;
    cleaning_category_id UUID;
    insurance_category_id UUID;
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
        
        -- 1. 관리비 항목 분류 생성
        INSERT INTO bms.fee_item_categories (
            company_id, category_code, category_name, category_description,
            display_order, default_calculation_method, is_utility_category, is_common_area_category
        ) VALUES 
        (company_rec.company_id, 'GENERAL', '일반관리비', '건물 운영을 위한 기본 관리비', 1, 'AREA_BASED', false, true),
        (company_rec.company_id, 'UTILITY', '공과금', '전기, 수도, 가스 등 공과금', 2, 'USAGE_BASED', true, false),
        (company_rec.company_id, 'FACILITY', '시설관리비', '시설 유지보수 및 관리비', 3, 'AREA_BASED', false, true),
        (company_rec.company_id, 'SECURITY', '경비비', '보안 및 경비 관련 비용', 4, 'HOUSEHOLD_BASED', false, true),
        (company_rec.company_id, 'CLEANING', '청소비', '공용구역 청소 및 위생 관리비', 5, 'AREA_BASED', false, true),
        (company_rec.company_id, 'INSURANCE', '보험료', '건물 및 시설 보험료', 6, 'FIXED_AMOUNT', false, true);
        
        -- 분류 ID 개별 조회 (RETURNING이 제대로 작동하지 않는 경우)
        SELECT category_id INTO general_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'GENERAL';
        SELECT category_id INTO utility_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'UTILITY';
        SELECT category_id INTO facility_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'FACILITY';
        SELECT category_id INTO security_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'SECURITY';
        SELECT category_id INTO cleaning_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'CLEANING';
        SELECT category_id INTO insurance_category_id FROM bms.fee_item_categories WHERE company_id = company_rec.company_id AND category_code = 'INSURANCE';
        
        category_count := category_count + 6;
        
        -- 2. 일반관리비 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant
        ) VALUES 
        (company_rec.company_id, general_category_id, 'GEN001', '일반관리비', '건물 운영 및 관리를 위한 기본 비용', 'AREA_BASED', 800.00, 'M2', 1, true, true),
        (company_rec.company_id, general_category_id, 'GEN002', '관리사무소운영비', '관리사무소 운영에 필요한 비용', 'AREA_BASED', 200.00, 'M2', 2, true, true),
        (company_rec.company_id, general_category_id, 'GEN003', '공용전기료', '복도, 로비 등 공용구역 전기료', 'AREA_BASED', 150.00, 'M2', 3, true, true);
        
        -- 3. 공과금 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant, external_source, auto_import_enabled
        ) VALUES 
        (company_rec.company_id, utility_category_id, 'UTL001', '전기료', '호실별 전기 사용료', 'USAGE_BASED', 120.50, 'KWH', 1, true, true, 'KEPCO', true),
        (company_rec.company_id, utility_category_id, 'UTL002', '수도료', '호실별 수도 사용료', 'USAGE_BASED', 850.00, 'M3', 2, true, true, 'K_WATER', true),
        (company_rec.company_id, utility_category_id, 'UTL003', '가스료', '호실별 가스 사용료', 'USAGE_BASED', 680.00, 'M3', 3, true, true, 'CITY_GAS', true),
        (company_rec.company_id, utility_category_id, 'UTL004', '난방비', '중앙난방 사용료', 'AREA_BASED', 1200.00, 'M2', 4, true, true, 'HEATING', false);
        
        -- 4. 시설관리비 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant
        ) VALUES 
        (company_rec.company_id, facility_category_id, 'FAC001', '승강기유지비', '엘리베이터 유지보수 비용', 'HOUSEHOLD_BASED', 15000.00, 'HOUSEHOLD', 1, true, true),
        (company_rec.company_id, facility_category_id, 'FAC002', '시설보수비', '건물 시설 보수 및 개선 비용', 'AREA_BASED', 300.00, 'M2', 2, true, true),
        (company_rec.company_id, facility_category_id, 'FAC003', '소독비', '정기 방역 및 소독 비용', 'AREA_BASED', 50.00, 'M2', 3, true, true),
        (company_rec.company_id, facility_category_id, 'FAC004', '조경관리비', '조경 및 녹지 관리 비용', 'AREA_BASED', 100.00, 'M2', 4, true, true);
        
        -- 5. 경비비 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant
        ) VALUES 
        (company_rec.company_id, security_category_id, 'SEC001', '경비비', '보안 및 경비 서비스 비용', 'HOUSEHOLD_BASED', 25000.00, 'HOUSEHOLD', 1, true, true),
        (company_rec.company_id, security_category_id, 'SEC002', 'CCTV운영비', 'CCTV 시스템 운영 및 관리 비용', 'HOUSEHOLD_BASED', 5000.00, 'HOUSEHOLD', 2, true, true);
        
        -- 6. 청소비 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant
        ) VALUES 
        (company_rec.company_id, cleaning_category_id, 'CLN001', '청소비', '공용구역 청소 서비스 비용', 'AREA_BASED', 250.00, 'M2', 1, true, true),
        (company_rec.company_id, cleaning_category_id, 'CLN002', '쓰레기처리비', '생활폐기물 처리 비용', 'HOUSEHOLD_BASED', 8000.00, 'HOUSEHOLD', 2, true, true);
        
        -- 7. 보험료 항목 생성
        INSERT INTO bms.maintenance_fee_items (
            company_id, category_id, item_code, item_name, item_description,
            calculation_method, unit_price, unit_type, display_order,
            applies_to_all_units, is_visible_to_tenant
        ) VALUES 
        (company_rec.company_id, insurance_category_id, 'INS001', '화재보험료', '건물 화재보험료', 'AREA_BASED', 80.00, 'M2', 1, true, true),
        (company_rec.company_id, insurance_category_id, 'INS002', '배상책임보험료', '시설 배상책임보험료', 'AREA_BASED', 30.00, 'M2', 2, true, true);
        
        item_count := item_count + 16;
        
        -- 8. 각 건물별 개별 설정 생성 (일부 항목에 대해)
        FOR building_rec IN 
            SELECT building_id, name as building_name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            RAISE NOTICE '  건물 % 개별 설정 생성', building_rec.building_name;
            
            -- 일반관리비에 대한 건물별 개별 단가 설정
            INSERT INTO bms.building_fee_item_settings (
                building_id, item_id, company_id, custom_unit_price, override_default, notes
            ) 
            SELECT 
                building_rec.building_id,
                mfi.item_id,
                company_rec.company_id,
                mfi.unit_price * (0.9 + random() * 0.2),  -- 기본 단가의 90~110%
                true,
                '건물별 개별 단가 적용'
            FROM bms.maintenance_fee_items mfi
            WHERE mfi.company_id = company_rec.company_id
              AND mfi.item_code IN ('GEN001', 'FAC001', 'SEC001')  -- 일부 항목만
              AND random() < 0.5;  -- 50% 확률로 적용
            
            setting_count := setting_count + 1;
        END LOOP;
        
        -- 9. 단가 변경 이력 생성 (일부 항목에 대해)
        INSERT INTO bms.fee_item_price_history (
            item_id, company_id, unit_price, change_reason, change_type,
            effective_start_date, effective_end_date, created_by
        )
        SELECT 
            mfi.item_id,
            company_rec.company_id,
            mfi.unit_price * 0.9,  -- 이전 단가 (10% 낮음)
            '연간 단가 조정',
            'INCREASE',
            CURRENT_DATE - INTERVAL '6 months',
            CURRENT_DATE - INTERVAL '1 day',
            (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1)
        FROM bms.maintenance_fee_items mfi
        WHERE mfi.company_id = company_rec.company_id
          AND mfi.item_code IN ('GEN001', 'UTL001', 'FAC001')  -- 일부 항목만
          AND random() < 0.7;  -- 70% 확률로 이력 생성
        
        RAISE NOTICE '회사 % 관리비 항목 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 관리비 항목 마스터 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 분류 수: %', category_count;
    RAISE NOTICE '총 항목 수: %', item_count;
    RAISE NOTICE '총 건물별 설정 수: %', setting_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 관리비 분류 현황
SELECT 
    '관리비 분류' as category,
    c.company_name,
    fic.category_code,
    fic.category_name,
    fic.default_calculation_method,
    fic.is_utility_category,
    fic.is_common_area_category
FROM bms.fee_item_categories fic
JOIN bms.companies c ON fic.company_id = c.company_id
WHERE fic.is_active = true
ORDER BY c.company_name, fic.display_order;

-- 2. 관리비 항목 현황
SELECT 
    '관리비 항목' as category,
    c.company_name,
    fic.category_name,
    mfi.item_code,
    mfi.item_name,
    mfi.calculation_method,
    mfi.unit_price,
    mfi.unit_type,
    mfi.applies_to_all_units
FROM bms.maintenance_fee_items mfi
JOIN bms.companies c ON mfi.company_id = c.company_id
LEFT JOIN bms.fee_item_categories fic ON mfi.category_id = fic.category_id
WHERE mfi.is_active = true
ORDER BY c.company_name, fic.display_order, mfi.display_order
LIMIT 20;

-- 3. 건물별 개별 설정 현황
SELECT 
    '건물별 설정' as category,
    c.company_name,
    b.name as building_name,
    mfi.item_name,
    mfi.unit_price as default_price,
    bfis.custom_unit_price,
    bfis.override_default,
    bfis.notes
FROM bms.building_fee_item_settings bfis
JOIN bms.buildings b ON bfis.building_id = b.building_id
JOIN bms.companies c ON bfis.company_id = c.company_id
JOIN bms.maintenance_fee_items mfi ON bfis.item_id = mfi.item_id
WHERE bfis.is_enabled = true
ORDER BY c.company_name, b.name, mfi.item_name;

-- 4. 단가 변경 이력
SELECT 
    '단가 이력' as category,
    c.company_name,
    mfi.item_name,
    fph.unit_price,
    fph.change_type,
    fph.change_reason,
    fph.effective_start_date,
    fph.effective_end_date
FROM bms.fee_item_price_history fph
JOIN bms.maintenance_fee_items mfi ON fph.item_id = mfi.item_id
JOIN bms.companies c ON fph.company_id = c.company_id
ORDER BY c.company_name, mfi.item_name, fph.effective_start_date DESC;

-- 5. 활성 관리비 항목 뷰 테스트
SELECT 
    '활성 항목 뷰' as category,
    item_name,
    calculation_method,
    unit_price,
    unit_type
FROM bms.v_active_fee_items
ORDER BY display_order
LIMIT 15;

-- 6. 함수 테스트 - 현재 단가 조회
SELECT 
    '현재 단가 조회' as category,
    c.company_name,
    mfi.item_name,
    mfi.unit_price as master_price,
    bms.get_current_fee_item_price(mfi.item_id) as current_price
FROM bms.maintenance_fee_items mfi
JOIN bms.companies c ON mfi.company_id = c.company_id
WHERE mfi.is_active = true
ORDER BY c.company_name, mfi.item_name
LIMIT 10;

-- 완료 메시지
SELECT '✅ 관리비 항목 마스터 테스트 데이터 생성이 완료되었습니다!' as result;