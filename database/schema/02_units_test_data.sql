-- =====================================================
-- 호실(Unit) 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    building_rec RECORD;
    floor_num INTEGER;
    unit_num INTEGER;
    unit_count INTEGER := 0;
BEGIN
    -- 각 건물에 대해 호실 생성
    FOR building_rec IN 
        SELECT building_id, company_id, name, total_floors, basement_floors 
        FROM bms.buildings 
        WHERE building_status = 'ACTIVE'
        LIMIT 5  -- 처음 5개 건물만 테스트 데이터 생성
    LOOP
        RAISE NOTICE '건물 % (%) 호실 생성 시작', building_rec.name, building_rec.building_id;
        
        -- 지하층 호실 생성 (REVERSE 대신 일반 루프 사용)
        IF building_rec.basement_floors > 0 THEN
            FOR floor_num IN 1..building_rec.basement_floors LOOP
                FOR unit_num IN 1..5 LOOP  -- 각 층에 5개 호실
                    INSERT INTO bms.units (
                        company_id, building_id, unit_number, floor_number,
                        unit_type, unit_status, exclusive_area, common_area,
                        monthly_rent, deposit, maintenance_fee,
                        room_count, bathroom_count, has_parking, parking_spaces,
                        direction, heating_type, cooling_type
                    ) VALUES (
                        building_rec.company_id,
                        building_rec.building_id,
                        'B' || floor_num || '-' || LPAD(unit_num::text, 2, '0'),
                        -floor_num,  -- 음수로 지하층 표현
                        CASE WHEN unit_num <= 2 THEN 'PARKING' ELSE 'STORAGE' END,
                        CASE WHEN unit_num % 3 = 0 THEN 'OCCUPIED' ELSE 'VACANT' END,
                        CASE WHEN unit_num <= 2 THEN 15.0 ELSE 10.0 END,
                        5.0,
                        CASE WHEN unit_num <= 2 THEN 50000 ELSE 30000 END,
                        CASE WHEN unit_num <= 2 THEN 500000 ELSE 300000 END,
                        CASE WHEN unit_num <= 2 THEN 10000 ELSE 5000 END,
                        0, 0,
                        CASE WHEN unit_num <= 2 THEN true ELSE false END,
                        CASE WHEN unit_num <= 2 THEN 1 ELSE 0 END,
                        CASE unit_num % 4 WHEN 0 THEN 'N' WHEN 1 THEN 'S' WHEN 2 THEN 'E' ELSE 'W' END,
                        'ELECTRIC', 'NONE'
                    );
                    unit_count := unit_count + 1;
                END LOOP;
            END LOOP;
        END IF;
        
        -- 지상층 호실 생성
        FOR floor_num IN 1..LEAST(building_rec.total_floors, 10) LOOP  -- 최대 10층까지만
            FOR unit_num IN 1..8 LOOP  -- 각 층에 8개 호실
                INSERT INTO bms.units (
                    company_id, building_id, unit_number, floor_number,
                    unit_type, unit_status, exclusive_area, common_area,
                    monthly_rent, deposit, maintenance_fee,
                    room_count, bathroom_count, has_balcony, has_parking, parking_spaces,
                    direction, heating_type, cooling_type, move_in_date
                ) VALUES (
                    building_rec.company_id,
                    building_rec.building_id,
                    floor_num || LPAD(unit_num::text, 2, '0'),
                    floor_num,
                    CASE 
                        WHEN unit_num <= 4 THEN 'OFFICE'
                        WHEN unit_num <= 6 THEN 'RETAIL'
                        ELSE 'WAREHOUSE'
                    END,
                    CASE 
                        WHEN unit_num % 4 = 0 THEN 'OCCUPIED'
                        WHEN unit_num % 5 = 0 THEN 'MAINTENANCE'
                        ELSE 'VACANT'
                    END,
                    20.0 + (unit_num * 5.0) + (floor_num * 2.0),  -- 면적 다양화
                    10.0 + (floor_num * 1.0),
                    100000 + (unit_num * 20000) + (floor_num * 10000),  -- 임대료 다양화
                    1000000 + (unit_num * 200000),
                    50000 + (unit_num * 5000),
                    CASE WHEN unit_num <= 4 THEN 2 + (unit_num % 3) ELSE 1 END,
                    CASE WHEN unit_num <= 4 THEN 1 + (unit_num % 2) ELSE 1 END,
                    CASE WHEN unit_num % 3 = 0 THEN true ELSE false END,
                    CASE WHEN unit_num % 4 = 0 THEN true ELSE false END,
                    CASE WHEN unit_num % 4 = 0 THEN 1 ELSE 0 END,
                    CASE unit_num % 4 WHEN 0 THEN 'N' WHEN 1 THEN 'S' WHEN 2 THEN 'E' ELSE 'W' END,
                    'CENTRAL', 'CENTRAL',
                    CASE WHEN unit_num % 4 = 0 THEN CURRENT_DATE - INTERVAL '30 days' * (unit_num % 12) ELSE NULL END
                );
                unit_count := unit_count + 1;
            END LOOP;
        END LOOP;
        
        RAISE NOTICE '건물 % 호실 생성 완료', building_rec.name;
    END LOOP;
    
    RAISE NOTICE '총 % 개의 테스트 호실이 생성되었습니다.', unit_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.units;

-- 데이터 검증 및 결과 출력
SELECT 
    '호실 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_units,
    COUNT(CASE WHEN unit_status = 'VACANT' THEN 1 END) as vacant_units,
    COUNT(CASE WHEN unit_status = 'OCCUPIED' THEN 1 END) as occupied_units,
    COUNT(CASE WHEN unit_status = 'MAINTENANCE' THEN 1 END) as maintenance_units,
    ROUND(AVG(total_area), 2) as avg_area,
    ROUND(AVG(monthly_rent), 0) as avg_rent
FROM bms.units;

-- 호실 타입별 통계
SELECT 
    '호실 타입별 현황' as info,
    unit_type,
    COUNT(*) as count,
    ROUND(AVG(total_area), 2) as avg_area,
    ROUND(AVG(monthly_rent), 0) as avg_rent,
    COUNT(CASE WHEN unit_status = 'OCCUPIED' THEN 1 END) as occupied_count
FROM bms.units
GROUP BY unit_type
ORDER BY count DESC;

-- 층별 통계
SELECT 
    '층별 현황' as info,
    floor_number,
    COUNT(*) as unit_count,
    COUNT(CASE WHEN unit_status = 'OCCUPIED' THEN 1 END) as occupied_count,
    ROUND(AVG(total_area), 2) as avg_area
FROM bms.units
GROUP BY floor_number
ORDER BY floor_number;

-- 건물별 호실 통계 뷰 테스트
SELECT 
    '건물별 호실 통계' as info,
    building_name,
    total_units,
    vacant_units,
    occupied_units,
    occupancy_rate
FROM bms.v_building_unit_statistics
ORDER BY total_units DESC
LIMIT 5;

-- 완료 메시지
SELECT '✅ 호실 테스트 데이터 생성이 완료되었습니다!' as result;