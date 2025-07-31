-- =====================================================
-- 건물 상세 정보 테이블 확장 최종 완료 스크립트
-- =====================================================

-- 1. 건물 상세 정보 뷰 생성 (올바른 컬럼명 사용)
CREATE OR REPLACE VIEW bms.v_building_summary AS
SELECT 
    b.building_id as id,
    b.company_id,
    b.name,
    b.address,
    b.address_detail,
    b.postal_code,
    b.building_type,
    b.building_status,
    b.total_floors,
    b.basement_floors,
    b.total_area,
    b.total_units,
    b.construction_date,
    b.management_office_name,
    b.manager_name,
    b.manager_phone,
    b.manager_email,
    b.has_elevator,
    b.elevator_count,
    b.has_parking,
    b.parking_spaces,
    b.has_security,
    b.security_system,
    b.heating_system,
    b.water_supply_system,
    b.maintenance_fee_base,
    b.next_inspection_date,
    b.created_at,
    b.updated_at
FROM bms.buildings b
WHERE b.building_status = 'ACTIVE';

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_summary OWNER TO qiro;

-- 2. 건물 통계 뷰 생성 (올바른 컬럼명 사용)
CREATE OR REPLACE VIEW bms.v_building_statistics AS
SELECT 
    company_id,
    COUNT(*) as total_buildings,
    COUNT(CASE WHEN building_status = 'ACTIVE' THEN 1 END) as active_buildings,
    COUNT(CASE WHEN building_type = 'OFFICE' THEN 1 END) as office_buildings,
    COUNT(CASE WHEN building_type = 'COMMERCIAL' THEN 1 END) as commercial_buildings,
    COUNT(CASE WHEN building_type = 'RESIDENTIAL' THEN 1 END) as residential_buildings,
    COUNT(CASE WHEN building_type = 'MIXED_USE' THEN 1 END) as mixed_use_buildings,
    SUM(total_area) as total_area_sum,
    AVG(total_area) as avg_area,
    SUM(total_units) as total_units_sum,
    SUM(parking_spaces) as total_parking_spaces,
    COUNT(CASE WHEN has_elevator = true THEN 1 END) as buildings_with_elevator,
    COUNT(CASE WHEN has_parking = true THEN 1 END) as buildings_with_parking,
    COUNT(CASE WHEN has_security = true THEN 1 END) as buildings_with_security
FROM bms.buildings
GROUP BY company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_statistics OWNER TO qiro;

-- 3. 기존 테스트 데이터에 상세 정보 추가
-- 먼저 실제 존재하는 company_id 확인 후 업데이트
DO $$
DECLARE
    test_company_ids UUID[];
    company_id_val UUID;
    building_count INTEGER;
BEGIN
    -- 실제 존재하는 company_id들을 배열로 가져오기
    SELECT ARRAY(SELECT company_id FROM bms.companies LIMIT 2) INTO test_company_ids;
    
    -- 배열이 비어있지 않다면 업데이트 실행
    IF array_length(test_company_ids, 1) > 0 THEN
        -- 첫 번째 회사의 건물들 업데이트
        company_id_val := test_company_ids[1];
        
        UPDATE bms.buildings 
        SET 
            address_detail = COALESCE(address_detail, address || ' 상세주소'),
            postal_code = COALESCE(postal_code, '12345'),
            building_type = CASE 
                WHEN building_type = 'APARTMENT' THEN 'RESIDENTIAL'
                ELSE COALESCE(building_type, 'OFFICE')
            END,
            basement_floors = COALESCE(basement_floors, 2),
            construction_date = COALESCE(construction_date, '2020-01-01'::DATE),
            building_status = COALESCE(building_status, 'ACTIVE'),
            management_office_name = COALESCE(management_office_name, name || ' 관리사무소'),
            management_office_phone = COALESCE(management_office_phone, '02-1234-5678'),
            manager_name = COALESCE(manager_name, '김관리'),
            manager_phone = COALESCE(manager_phone, '010-1234-5678'),
            manager_email = COALESCE(manager_email, 'manager@example.com'),
            has_elevator = COALESCE(has_elevator, true),
            elevator_count = COALESCE(elevator_count, 2),
            has_parking = COALESCE(has_parking, true),
            parking_spaces = COALESCE(parking_spaces, 50),
            has_security = COALESCE(has_security, true),
            security_system = COALESCE(security_system, 'CCTV, 출입통제시스템'),
            heating_system = COALESCE(heating_system, 'CENTRAL'),
            water_supply_system = COALESCE(water_supply_system, 'DIRECT'),
            fire_safety_grade = COALESCE(fire_safety_grade, 'A'),
            energy_efficiency_grade = COALESCE(energy_efficiency_grade, '1'),
            maintenance_fee_base = COALESCE(maintenance_fee_base, 100000.00),
            common_area_ratio = COALESCE(common_area_ratio, 25.5),
            next_inspection_date = COALESCE(next_inspection_date, CURRENT_DATE + INTERVAL '6 months')
        WHERE company_id = company_id_val;
        
        GET DIAGNOSTICS building_count = ROW_COUNT;
        RAISE NOTICE '첫 번째 회사 (%) 건물 % 개 업데이트 완료', company_id_val, building_count;
        
        -- 두 번째 회사가 있다면 업데이트
        IF array_length(test_company_ids, 1) > 1 THEN
            company_id_val := test_company_ids[2];
            
            UPDATE bms.buildings 
            SET 
                address_detail = COALESCE(address_detail, address || ' 상세주소'),
                postal_code = COALESCE(postal_code, '54321'),
                building_type = CASE 
                    WHEN building_type = 'APARTMENT' THEN 'RESIDENTIAL'
                    ELSE COALESCE(building_type, 'COMMERCIAL')
                END,
                basement_floors = COALESCE(basement_floors, 3),
                construction_date = COALESCE(construction_date, '2019-06-01'::DATE),
                building_status = COALESCE(building_status, 'ACTIVE'),
                management_office_name = COALESCE(management_office_name, name || ' 관리사무소'),
                management_office_phone = COALESCE(management_office_phone, '02-9876-5432'),
                manager_name = COALESCE(manager_name, '이관리'),
                manager_phone = COALESCE(manager_phone, '010-9876-5432'),
                manager_email = COALESCE(manager_email, 'manager2@example.com'),
                has_elevator = COALESCE(has_elevator, true),
                elevator_count = COALESCE(elevator_count, 3),
                has_parking = COALESCE(has_parking, true),
                parking_spaces = COALESCE(parking_spaces, 80),
                has_security = COALESCE(has_security, true),
                security_system = COALESCE(security_system, 'CCTV, 지문인식, 출입통제'),
                heating_system = COALESCE(heating_system, 'INDIVIDUAL'),
                water_supply_system = COALESCE(water_supply_system, 'TANK'),
                fire_safety_grade = COALESCE(fire_safety_grade, 'B'),
                energy_efficiency_grade = COALESCE(energy_efficiency_grade, '2'),
                maintenance_fee_base = COALESCE(maintenance_fee_base, 150000.00),
                common_area_ratio = COALESCE(common_area_ratio, 30.0),
                next_inspection_date = COALESCE(next_inspection_date, CURRENT_DATE + INTERVAL '3 months')
            WHERE company_id = company_id_val;
            
            GET DIAGNOSTICS building_count = ROW_COUNT;
            RAISE NOTICE '두 번째 회사 (%) 건물 % 개 업데이트 완료', company_id_val, building_count;
        END IF;
        
        RAISE NOTICE '테스트 데이터 업데이트가 완료되었습니다. 총 회사 수: %', array_length(test_company_ids, 1);
    ELSE
        RAISE NOTICE '업데이트할 회사 데이터가 없습니다.';
    END IF;
END $$;

-- 4. 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.buildings;

-- 5. 데이터 검증 쿼리
SELECT 
    '건물 상세 정보 확장 완료' as status,
    COUNT(*) as total_buildings,
    COUNT(CASE WHEN address_detail IS NOT NULL THEN 1 END) as buildings_with_detail,
    COUNT(CASE WHEN manager_name IS NOT NULL THEN 1 END) as buildings_with_manager,
    COUNT(CASE WHEN has_elevator = true THEN 1 END) as buildings_with_elevator
FROM bms.buildings;

-- 6. 건물 타입별 통계
SELECT 
    '건물 타입별 통계' as info,
    building_type,
    COUNT(*) as count,
    ROUND(AVG(total_area), 2) as avg_area,
    SUM(parking_spaces) as total_parking,
    COUNT(CASE WHEN has_elevator = true THEN 1 END) as with_elevator
FROM bms.buildings 
WHERE building_type IS NOT NULL
GROUP BY building_type
ORDER BY count DESC;

-- 7. 뷰 테스트
SELECT 
    '뷰 테스트 결과' as info,
    COUNT(*) as summary_view_count
FROM bms.v_building_summary;

SELECT 
    '통계 뷰 테스트 결과' as info,
    company_id,
    total_buildings,
    active_buildings,
    buildings_with_elevator,
    buildings_with_parking
FROM bms.v_building_statistics
ORDER BY total_buildings DESC;

-- 완료 메시지
SELECT '✅ 1.1 건물 상세 정보 테이블 확장이 완료되었습니다!' as result;