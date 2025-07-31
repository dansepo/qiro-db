-- =====================================================
-- 건물 상세 정보 테이블 확장 오류 수정 스크립트
-- =====================================================

-- 1. 건물 상세 정보 뷰 수정 (companies 테이블 조인 제거)
DROP VIEW IF EXISTS bms.v_building_summary;
CREATE OR REPLACE VIEW bms.v_building_summary AS
SELECT 
    b.id,
    b.company_id,
    b.name,
    b.address_detail,
    b.postal_code,
    b.building_type,
    b.building_status,
    b.total_floors,
    b.basement_floors,
    b.total_area,
    b.construction_date,
    b.management_office_name,
    b.manager_name,
    b.manager_phone,
    b.has_elevator,
    b.elevator_count,
    b.has_parking,
    b.parking_spaces,
    b.maintenance_fee_base,
    b.next_inspection_date,
    b.created_at,
    b.updated_at
FROM bms.buildings b
WHERE b.building_status = 'ACTIVE';

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_summary OWNER TO qiro;

-- 2. 기존 테스트 데이터의 company_id 확인 후 업데이트
-- 먼저 실제 존재하는 company_id 확인
DO $$
DECLARE
    test_company_ids UUID[];
    company_id_val UUID;
BEGIN
    -- 실제 존재하는 company_id들을 배열로 가져오기
    SELECT ARRAY(SELECT id FROM bms.companies LIMIT 2) INTO test_company_ids;
    
    -- 배열이 비어있지 않다면 업데이트 실행
    IF array_length(test_company_ids, 1) > 0 THEN
        -- 첫 번째 회사의 건물들 업데이트
        company_id_val := test_company_ids[1];
        
        UPDATE bms.buildings 
        SET 
            address_detail = COALESCE(address_detail, name || ' 상세주소'),
            postal_code = COALESCE(postal_code, '12345'),
            building_type = COALESCE(building_type, 'OFFICE'),
            total_floors = COALESCE(total_floors, 10),
            basement_floors = COALESCE(basement_floors, 2),
            total_area = COALESCE(total_area, 5000.00),
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
        
        -- 두 번째 회사가 있다면 업데이트
        IF array_length(test_company_ids, 1) > 1 THEN
            company_id_val := test_company_ids[2];
            
            UPDATE bms.buildings 
            SET 
                address_detail = COALESCE(address_detail, name || ' 상세주소'),
                postal_code = COALESCE(postal_code, '54321'),
                building_type = COALESCE(building_type, 'COMMERCIAL'),
                total_floors = COALESCE(total_floors, 15),
                basement_floors = COALESCE(basement_floors, 3),
                total_area = COALESCE(total_area, 7500.00),
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
        END IF;
        
        RAISE NOTICE '테스트 데이터 업데이트가 완료되었습니다. 업데이트된 회사 수: %', array_length(test_company_ids, 1);
    ELSE
        RAISE NOTICE '업데이트할 회사 데이터가 없습니다.';
    END IF;
END $$;

-- 3. 데이터 검증 쿼리
SELECT 
    '건물 상세 정보 확장 완료 - 총 건물 수: ' || COUNT(*) || 
    ', 상세 정보가 있는 건물 수: ' || COUNT(CASE WHEN address_detail IS NOT NULL THEN 1 END) as result
FROM bms.buildings;

-- 4. 건물 타입별 통계
SELECT 
    building_type,
    COUNT(*) as count,
    AVG(total_area) as avg_area,
    SUM(parking_spaces) as total_parking
FROM bms.buildings 
WHERE building_type IS NOT NULL
GROUP BY building_type
ORDER BY count DESC;

-- 완료 메시지
SELECT '건물 상세 정보 테이블 확장 오류 수정이 완료되었습니다.' as result;