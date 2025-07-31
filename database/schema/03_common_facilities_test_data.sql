-- =====================================================
-- 공용시설 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    building_rec RECORD;
    facility_count INTEGER := 0;
    floor_num INTEGER;
BEGIN
    -- 각 건물에 대해 공용시설 생성
    FOR building_rec IN 
        SELECT building_id, company_id, name, total_floors, basement_floors 
        FROM bms.buildings 
        WHERE building_status = 'ACTIVE'
        LIMIT 5  -- 처음 5개 건물만 테스트 데이터 생성
    LOOP
        RAISE NOTICE '건물 % (%) 공용시설 생성 시작', building_rec.name, building_rec.building_id;
        
        -- 1. 엘리베이터 시설 (지하1층과 1층에 설치)
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            capacity, area, installation_date, manufacturer, model_number,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            installation_cost, monthly_maintenance_cost, annual_inspection_cost,
            operating_hours, power_consumption, warranty_start_date, warranty_end_date
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '승객용 엘리베이터 #1', 'ELV-001',
         'ELEVATOR', 'PASSENGER_ELEVATOR', 1, '중앙홀',
         15, 4.5, '2020-01-15', '현대엘리베이터', 'HE-2000',
         'ACTIVE', 'NORMAL', '김기술', '010-1111-2222',
         CURRENT_DATE - INTERVAL '2 months', CURRENT_DATE + INTERVAL '4 months', 6,
         50000000, 200000, 500000,
         '06:00-24:00', 15.5, '2020-01-15', '2025-01-15'),
        
        (building_rec.company_id, building_rec.building_id, '승객용 엘리베이터 #2', 'ELV-002',
         'ELEVATOR', 'PASSENGER_ELEVATOR', 1, '중앙홀',
         15, 4.5, '2020-01-15', '현대엘리베이터', 'HE-2000',
         'ACTIVE', 'NORMAL', '김기술', '010-1111-2222',
         CURRENT_DATE - INTERVAL '1 month', CURRENT_DATE + INTERVAL '5 months', 6,
         50000000, 200000, 500000,
         '06:00-24:00', 15.5, '2020-01-15', '2025-01-15');
        
        facility_count := facility_count + 2;
        
        -- 2. HVAC 시설 (각 층에 설치)
        FOR floor_num IN 1..LEAST(building_rec.total_floors, 5) LOOP
            INSERT INTO bms.common_facilities (
                company_id, building_id, facility_name, facility_code,
                facility_category, facility_type, location_floor, location_area,
                capacity, area, installation_date, manufacturer,
                facility_status, operational_status, manager_name, manager_phone,
                last_inspection_date, next_inspection_date, inspection_cycle_months,
                monthly_maintenance_cost, power_consumption
            ) VALUES (
                building_rec.company_id, building_rec.building_id, 
                floor_num || '층 공조시설', 'HVAC-' || LPAD(floor_num::text, 3, '0'),
                'HVAC', 'AIR_CONDITIONER', floor_num, '기계실',
                0, 20.0, '2020-02-01', 'LG전자',
                'ACTIVE', 'NORMAL', '박공조', '010-2222-3333',
                CURRENT_DATE - INTERVAL '3 months', CURRENT_DATE + INTERVAL '3 months', 6,
                150000, 25.0
            );
            facility_count := facility_count + 1;
        END LOOP;
        
        -- 3. 전기 시설 (지하층과 옥상)
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            area, installation_date, manufacturer, model_number,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, power_consumption
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '주배전반', 'ELEC-001',
         'ELECTRICAL', 'MAIN_PANEL', -1, '전기실',
         15.0, '2020-01-10', '한국전력기술', 'KPT-3000',
         'ACTIVE', 'NORMAL', '이전기', '010-3333-4444',
         CURRENT_DATE - INTERVAL '1 month', CURRENT_DATE + INTERVAL '5 months', 6,
         100000, 0.0);
        
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            area, installation_date, manufacturer, model_number,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, power_consumption
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '비상발전기', 'ELEC-002',
         'ELECTRICAL', 'GENERATOR', -1, '발전기실',
         25.0, '2020-01-20', '대우중공업', 'DH-500',
         'ACTIVE', 'NORMAL', '이전기', '010-3333-4444',
         CURRENT_DATE - INTERVAL '2 weeks', CURRENT_DATE + INTERVAL '10 weeks', 3,
         300000, 500.0);
        
        facility_count := facility_count + 2;
        
        -- 4. 급수 시설
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            capacity, area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, power_consumption, water_usage
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '급수펌프', 'PLUMB-001',
         'PLUMBING', 'WATER_PUMP', -1, '기계실',
         1000, 10.0, '2020-02-15', '한일펌프',
         'ACTIVE', 'NORMAL', '최배관', '010-4444-5555',
         CURRENT_DATE - INTERVAL '6 weeks', CURRENT_DATE + INTERVAL '6 weeks', 3,
         80000, 7.5, 500.0);
        
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            capacity, area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, power_consumption, water_usage
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '옥상 물탱크', 'PLUMB-002',
         'PLUMBING', 'WATER_TANK', building_rec.total_floors + 1, '옥상',
         5000, 30.0, '2020-01-25', '코스모탱크',
         'ACTIVE', 'NORMAL', '최배관', '010-4444-5555',
         CURRENT_DATE - INTERVAL '4 months', CURRENT_DATE + INTERVAL '2 months', 6,
         50000, 0.0, 0.0);
        
        facility_count := facility_count + 2;
        
        -- 5. 소방 시설
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '소방펌프', 'FIRE-001',
         'FIRE_SAFETY', 'FIRE_PUMP', -1, '소방펌프실',
         12.0, '2020-01-30', '한국소방펌프',
         'ACTIVE', 'NORMAL', '정소방', '010-5555-6666',
         CURRENT_DATE - INTERVAL '2 months', CURRENT_DATE + INTERVAL '4 months', 6,
         120000);
        
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '화재감지시스템', 'FIRE-002',
         'FIRE_SAFETY', 'FIRE_ALARM', 1, '방재실',
         8.0, '2020-02-05', '한국화재감지',
         'ACTIVE', 'WARNING', '정소방', '010-5555-6666',
         CURRENT_DATE - INTERVAL '1 month', CURRENT_DATE + INTERVAL '5 months', 6,
         80000);
        
        facility_count := facility_count + 2;
        
        -- 6. 보안 시설
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            capacity, area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, operating_hours
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, 'CCTV 통합관제시스템', 'SEC-001',
         'SECURITY', 'CCTV', 1, '경비실',
         32, 15.0, '2020-03-01', '한화테크윈',
         'ACTIVE', 'NORMAL', '김경비', '010-6666-7777',
         CURRENT_DATE - INTERVAL '3 months', CURRENT_DATE + INTERVAL '3 months', 6,
         100000, '24시간');
        
        INSERT INTO bms.common_facilities (
            company_id, building_id, facility_name, facility_code,
            facility_category, facility_type, location_floor, location_area,
            capacity, area, installation_date, manufacturer,
            facility_status, operational_status, manager_name, manager_phone,
            last_inspection_date, next_inspection_date, inspection_cycle_months,
            monthly_maintenance_cost, operating_hours
        ) VALUES 
        (building_rec.company_id, building_rec.building_id, '출입통제시스템', 'SEC-002',
         'SECURITY', 'ACCESS_CONTROL', 1, '로비',
         0, 5.0, '2020-03-10', '유니온커뮤니티',
         'ACTIVE', 'NORMAL', '김경비', '010-6666-7777',
         CURRENT_DATE - INTERVAL '2 months', CURRENT_DATE + INTERVAL '4 months', 6,
         60000, '24시간');
        
        facility_count := facility_count + 2;
        
        -- 7. 주차 시설 (지하층에만)
        IF building_rec.basement_floors > 0 THEN
            INSERT INTO bms.common_facilities (
                company_id, building_id, facility_name, facility_code,
                facility_category, facility_type, location_floor, location_area,
                capacity, area, installation_date, manufacturer,
                facility_status, operational_status, manager_name, manager_phone,
                last_inspection_date, next_inspection_date, inspection_cycle_months,
                monthly_maintenance_cost, operating_hours
            ) VALUES (
                building_rec.company_id, building_rec.building_id, '주차관제시스템', 'PARK-001',
                'PARKING', 'PARKING_GATE', -1, '주차장 입구',
                0, 2.0, '2020-03-15', '파킹클라우드',
                'ACTIVE', 'NORMAL', '박주차', '010-7777-8888',
                CURRENT_DATE - INTERVAL '1 month', CURRENT_DATE + INTERVAL '5 months', 6,
                70000, '24시간'
            );
            facility_count := facility_count + 1;
        END IF;
        
        RAISE NOTICE '건물 % 공용시설 생성 완료', building_rec.name;
    END LOOP;
    
    RAISE NOTICE '총 % 개의 테스트 공용시설이 생성되었습니다.', facility_count;
END $$;

-- 일부 시설을 다른 상태로 변경 (다양성을 위해)
UPDATE bms.common_facilities 
SET facility_status = 'UNDER_MAINTENANCE', operational_status = 'MAINTENANCE'
WHERE facility_code LIKE '%002' AND facility_category = 'ELEVATOR';

UPDATE bms.common_facilities 
SET facility_status = 'OUT_OF_ORDER', operational_status = 'ERROR'
WHERE facility_code = 'HVAC-003';

UPDATE bms.common_facilities 
SET operational_status = 'WARNING'
WHERE facility_category = 'FIRE_SAFETY' AND facility_type = 'FIRE_ALARM';

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.common_facilities;

-- 데이터 검증 및 결과 출력
SELECT 
    '공용시설 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_facilities,
    COUNT(CASE WHEN facility_status = 'ACTIVE' THEN 1 END) as active_facilities,
    COUNT(CASE WHEN facility_status = 'UNDER_MAINTENANCE' THEN 1 END) as maintenance_facilities,
    COUNT(CASE WHEN facility_status = 'OUT_OF_ORDER' THEN 1 END) as out_of_order_facilities,
    COUNT(CASE WHEN operational_status = 'WARNING' THEN 1 END) as warning_facilities,
    ROUND(AVG(monthly_maintenance_cost), 0) as avg_monthly_cost
FROM bms.common_facilities;

-- 시설 분류별 통계
SELECT 
    '시설 분류별 현황' as info,
    facility_category,
    COUNT(*) as count,
    COUNT(CASE WHEN facility_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN operational_status = 'ERROR' THEN 1 END) as error_count,
    ROUND(AVG(monthly_maintenance_cost), 0) as avg_cost
FROM bms.common_facilities
GROUP BY facility_category
ORDER BY count DESC;

-- 건물별 시설 통계 뷰 테스트
SELECT 
    '건물별 시설 통계' as info,
    building_name,
    total_facilities,
    active_facilities,
    out_of_order_facilities,
    warning_facilities,
    overdue_inspections,
    total_monthly_maintenance_cost
FROM bms.v_building_facility_statistics
ORDER BY total_facilities DESC
LIMIT 5;

-- 점검 예정 시설 뷰 테스트
SELECT 
    '점검 예정 시설' as info,
    building_name,
    facility_name,
    facility_category,
    next_inspection_date,
    inspection_urgency
FROM bms.v_inspection_schedule
WHERE inspection_urgency IN ('OVERDUE', 'THIS_WEEK', 'THIS_MONTH')
ORDER BY next_inspection_date
LIMIT 10;

-- 완료 메시지
SELECT '✅ 공용시설 테스트 데이터 생성이 완료되었습니다!' as result;