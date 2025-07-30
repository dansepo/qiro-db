-- =====================================================
-- 성능 테스트용 대용량 데이터 생성 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 성능 테스트를 위한 대용량 테스트 데이터 생성
-- =====================================================

-- 성능 테스트 설정
\set ECHO all
\timing on

-- 성능 테스트용 임시 함수 생성
CREATE OR REPLACE FUNCTION generate_performance_test_data()
RETURNS VOID AS $$
DECLARE
    building_count INTEGER := 50;  -- 50개 건물
    units_per_building INTEGER := 200;  -- 건물당 200세대
    months_to_generate INTEGER := 24;  -- 24개월 데이터
    start_date DATE := '2023-01-01';
    current_building_id BIGINT;
    current_unit_id BIGINT;
    current_billing_month_id BIGINT;
    i INTEGER;
    j INTEGER;
    k INTEGER;
BEGIN
    RAISE NOTICE '성능 테스트 데이터 생성 시작...';
    
    -- 1. 대용량 건물 데이터 생성 (50개)
    RAISE NOTICE '건물 데이터 생성 중... (% 개)', building_count;
    FOR i IN 1..building_count LOOP
        INSERT INTO buildings (
            name, address, building_type, total_floors, total_area, 
            total_units, construction_year, status
        ) VALUES (
            '성능테스트빌딩' || i,
            '서울시 강남구 테스트로 ' || i || '번길',
            CASE (i % 4) 
                WHEN 0 THEN 'APARTMENT'::building_type
                WHEN 1 THEN 'COMMERCIAL'::building_type  
                WHEN 2 THEN 'MIXED_USE'::building_type
                ELSE 'OFFICE'::building_type
            END,
            (i % 20) + 5,  -- 5~24층
            (i % 1000 + 500) * 10.5,  -- 5,250~15,750 평방미터
            units_per_building,
            2020 + (i % 5),  -- 2020~2024년
            'ACTIVE'::building_status
        );
    END LOOP;
    
    -- 2. 대용량 호실 데이터 생성 (50 * 200 = 10,000세대)
    RAISE NOTICE '호실 데이터 생성 중... (% 개)', building_count * units_per_building;
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        FOR j IN 1..units_per_building LOOP
            INSERT INTO units (
                building_id, unit_number, floor_number, unit_type, area,
                monthly_rent, deposit, status
            ) VALUES (
                current_building_id,
                LPAD(j::TEXT, 4, '0'),  -- 0001, 0002, ...
                ((j - 1) / 10) + 1,  -- 층수 계산
                CASE (j % 3)
                    WHEN 0 THEN 'RESIDENTIAL'::unit_type
                    WHEN 1 THEN 'COMMERCIAL'::unit_type
                    ELSE 'OFFICE'::unit_type
                END,
                (j % 50 + 20) * 3.3,  -- 66~231 평방미터
                (j % 100 + 50) * 10000,  -- 50만~150만원
                (j % 200 + 100) * 100000,  -- 1천만~3천만원
                CASE (j % 10)
                    WHEN 0 THEN 'AVAILABLE'::unit_status
                    ELSE 'OCCUPIED'::unit_status
                END
            );
        END LOOP;
    END LOOP;  
  
    -- 3. 임차인 데이터 생성 (9,000명 - 90% 입주율)
    RAISE NOTICE '임차인 데이터 생성 중...';
    FOR i IN 1..(building_count * units_per_building * 0.9)::INTEGER LOOP
        INSERT INTO tenants (
            name, entity_type, primary_phone, email, 
            business_registration_number, is_active
        ) VALUES (
            '성능테스트임차인' || i,
            CASE (i % 10)
                WHEN 0 THEN 'CORPORATION'::entity_type
                ELSE 'INDIVIDUAL'::entity_type
            END,
            '010-' || LPAD((i % 10000)::TEXT, 4, '0') || '-' || LPAD((i % 10000)::TEXT, 4, '0'),
            'tenant' || i || '@test.com',
            CASE WHEN (i % 10) = 0 THEN 
                LPAD((100000000 + i)::TEXT, 10, '0')
            ELSE NULL END,
            true
        );
    END LOOP;
    
    -- 4. 관리비 항목 생성 (건물당 15개 항목)
    RAISE NOTICE '관리비 항목 데이터 생성 중...';
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        -- 기본 관리비 항목들
        INSERT INTO fee_items (building_id, name, fee_type, calculation_method, unit_price, is_active) VALUES
        (current_building_id, '일반관리비', 'COMMON_MAINTENANCE'::fee_type, 'AREA_BASED'::calculation_method, 1500, true),
        (current_building_id, '청소비', 'COMMON_MAINTENANCE'::fee_type, 'HOUSEHOLD_BASED'::calculation_method, 25000, true),
        (current_building_id, '경비비', 'COMMON_MAINTENANCE'::fee_type, 'HOUSEHOLD_BASED'::calculation_method, 35000, true),
        (current_building_id, '승강기유지비', 'COMMON_MAINTENANCE'::fee_type, 'HOUSEHOLD_BASED'::calculation_method, 15000, true),
        (current_building_id, '전기료(공용)', 'COMMON_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 120.5, true),
        (current_building_id, '수도료(공용)', 'COMMON_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 850.3, true),
        (current_building_id, '전기료(개별)', 'INDIVIDUAL_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 120.5, true),
        (current_building_id, '수도료(개별)', 'INDIVIDUAL_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 850.3, true),
        (current_building_id, '가스료', 'INDIVIDUAL_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 680.2, true),
        (current_building_id, '난방비', 'INDIVIDUAL_UTILITY'::fee_type, 'USAGE_BASED'::calculation_method, 45.8, true),
        (current_building_id, '인터넷료', 'OTHER_CHARGES'::fee_type, 'FIXED_AMOUNT'::calculation_method, 30000, true),
        (current_building_id, '케이블TV료', 'OTHER_CHARGES'::fee_type, 'FIXED_AMOUNT'::calculation_method, 15000, true),
        (current_building_id, '주차료', 'OTHER_CHARGES'::fee_type, 'FIXED_AMOUNT'::calculation_method, 50000, true),
        (current_building_id, '수선충당금', 'COMMON_MAINTENANCE'::fee_type, 'AREA_BASED'::calculation_method, 300, true),
        (current_building_id, '장기수선충당금', 'COMMON_MAINTENANCE'::fee_type, 'AREA_BASED'::calculation_method, 500, true);
    END LOOP;    

    -- 5. 24개월간 청구월 데이터 생성
    RAISE NOTICE '청구월 데이터 생성 중... (% 개월)', months_to_generate;
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        FOR j IN 0..(months_to_generate - 1) LOOP
            INSERT INTO billing_months (
                building_id, billing_year, billing_month, 
                status, due_date
            ) VALUES (
                current_building_id,
                EXTRACT(YEAR FROM start_date + (j || ' months')::INTERVAL),
                EXTRACT(MONTH FROM start_date + (j || ' months')::INTERVAL),
                CASE 
                    WHEN j < (months_to_generate - 2) THEN 'CLOSED'::billing_month_status
                    WHEN j = (months_to_generate - 2) THEN 'INVOICED'::billing_month_status
                    ELSE 'DRAFT'::billing_month_status
                END,
                (start_date + (j || ' months')::INTERVAL + INTERVAL '25 days')::DATE
            );
        END LOOP;
    END LOOP;
    
    -- 6. 검침 데이터 생성 (최근 12개월만)
    RAISE NOTICE '검침 데이터 생성 중...';
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        -- 최근 12개월 청구월 ID 조회
        FOR current_billing_month_id IN 
            SELECT id FROM billing_months 
            WHERE building_id = current_building_id 
            AND billing_year * 100 + billing_month >= 
                (EXTRACT(YEAR FROM CURRENT_DATE) - 1) * 100 + EXTRACT(MONTH FROM CURRENT_DATE)
        LOOP
            -- 각 호실별 검침 데이터
            FOR current_unit_id IN 
                SELECT id FROM units WHERE building_id = current_building_id AND status = 'OCCUPIED'::unit_status
            LOOP
                -- 전기 검침
                INSERT INTO unit_meter_readings (
                    billing_month_id, unit_id, meter_type,
                    previous_reading, current_reading, unit_price
                ) VALUES (
                    current_billing_month_id, current_unit_id, 'ELECTRICITY'::meter_type,
                    (random() * 1000 + 5000)::DECIMAL(12,3),
                    (random() * 1000 + 5000 + random() * 500)::DECIMAL(12,3),
                    120.5
                );
                
                -- 수도 검침
                INSERT INTO unit_meter_readings (
                    billing_month_id, unit_id, meter_type,
                    previous_reading, current_reading, unit_price
                ) VALUES (
                    current_billing_month_id, current_unit_id, 'WATER'::meter_type,
                    (random() * 100 + 500)::DECIMAL(12,3),
                    (random() * 100 + 500 + random() * 50)::DECIMAL(12,3),
                    850.3
                );
                
                -- 가스 검침
                INSERT INTO unit_meter_readings (
                    billing_month_id, unit_id, meter_type,
                    previous_reading, current_reading, unit_price
                ) VALUES (
                    current_billing_month_id, current_unit_id, 'GAS'::meter_type,
                    (random() * 200 + 1000)::DECIMAL(12,3),
                    (random() * 200 + 1000 + random() * 100)::DECIMAL(12,3),
                    680.2
                );
            END LOOP;
        END LOOP;
    END LOOP;    

    -- 7. 관리비 산정 데이터 생성 (최근 12개월)
    RAISE NOTICE '관리비 산정 데이터 생성 중...';
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        -- 최근 12개월 청구월에 대해
        FOR current_billing_month_id IN 
            SELECT id FROM billing_months 
            WHERE building_id = current_building_id 
            AND billing_year * 100 + billing_month >= 
                (EXTRACT(YEAR FROM CURRENT_DATE) - 1) * 100 + EXTRACT(MONTH FROM CURRENT_DATE)
        LOOP
            -- 각 호실별 관리비 산정
            FOR current_unit_id IN 
                SELECT id FROM units WHERE building_id = current_building_id AND status = 'OCCUPIED'::unit_status
            LOOP
                -- 각 관리비 항목별 산정
                INSERT INTO monthly_fees (
                    billing_month_id, unit_id, fee_item_id, 
                    calculation_method, calculated_amount
                )
                SELECT 
                    current_billing_month_id,
                    current_unit_id,
                    fi.id,
                    CASE fi.calculation_method
                        WHEN 'AREA_BASED' THEN 'UNIT_BASED'::fee_calculation_method
                        WHEN 'HOUSEHOLD_BASED' THEN 'FIXED_AMOUNT'::fee_calculation_method
                        WHEN 'USAGE_BASED' THEN 'USAGE_BASED'::fee_calculation_method
                        ELSE 'FIXED_AMOUNT'::fee_calculation_method
                    END,
                    CASE fi.calculation_method
                        WHEN 'AREA_BASED' THEN (u.area * fi.unit_price)::DECIMAL(12,2)
                        WHEN 'HOUSEHOLD_BASED' THEN fi.unit_price::DECIMAL(12,2)
                        WHEN 'USAGE_BASED' THEN 
                            COALESCE((
                                SELECT umr.usage_amount * fi.unit_price 
                                FROM unit_meter_readings umr 
                                WHERE umr.billing_month_id = current_billing_month_id 
                                AND umr.unit_id = current_unit_id 
                                AND umr.meter_type = CASE fi.name
                                    WHEN '전기료(개별)' THEN 'ELECTRICITY'::meter_type
                                    WHEN '수도료(개별)' THEN 'WATER'::meter_type
                                    WHEN '가스료' THEN 'GAS'::meter_type
                                    ELSE 'ELECTRICITY'::meter_type
                                END
                                LIMIT 1
                            ), fi.unit_price::DECIMAL(12,2))
                        ELSE fi.unit_price::DECIMAL(12,2)
                    END
                FROM fee_items fi
                JOIN units u ON u.id = current_unit_id
                WHERE fi.building_id = current_building_id AND fi.is_active = true;
            END LOOP;
        END LOOP;
    END LOOP; 
   
    -- 8. 고지서 데이터 생성 (최근 12개월)
    RAISE NOTICE '고지서 데이터 생성 중...';
    FOR i IN 1..building_count LOOP
        SELECT id INTO current_building_id FROM buildings WHERE name = '성능테스트빌딩' || i;
        
        -- 최근 12개월 청구월에 대해
        FOR current_billing_month_id IN 
            SELECT id FROM billing_months 
            WHERE building_id = current_building_id 
            AND billing_year * 100 + billing_month >= 
                (EXTRACT(YEAR FROM CURRENT_DATE) - 1) * 100 + EXTRACT(MONTH FROM CURRENT_DATE)
        LOOP
            -- 각 호실별 고지서 생성
            INSERT INTO invoices (
                billing_month_id, unit_id, invoice_number,
                issue_date, due_date, subtotal_amount, status
            )
            SELECT 
                current_billing_month_id,
                u.id,
                'INV-' || current_building_id || '-' || current_billing_month_id || '-' || u.id,
                bm.due_date - INTERVAL '25 days',
                bm.due_date,
                COALESCE(SUM(mf.calculated_amount), 0),
                CASE 
                    WHEN bm.status = 'CLOSED' THEN 'PAID'::invoice_status
                    WHEN bm.status = 'INVOICED' THEN 'ISSUED'::invoice_status
                    ELSE 'DRAFT'::invoice_status
                END
            FROM units u
            JOIN billing_months bm ON bm.id = current_billing_month_id
            LEFT JOIN monthly_fees mf ON mf.billing_month_id = current_billing_month_id AND mf.unit_id = u.id
            WHERE u.building_id = current_building_id AND u.status = 'OCCUPIED'::unit_status
            GROUP BY u.id, bm.due_date, bm.status;
        END LOOP;
    END LOOP;
    
    -- 9. 수납 데이터 생성 (완료된 고지서에 대해)
    RAISE NOTICE '수납 데이터 생성 중...';
    INSERT INTO payments (
        invoice_id, payment_date, amount, payment_method, payment_status
    )
    SELECT 
        i.id,
        i.due_date - INTERVAL '5 days' + (random() * 10)::INTEGER * INTERVAL '1 day',
        i.total_amount * (0.8 + random() * 0.2),  -- 80~100% 납부
        CASE (i.id % 5)
            WHEN 0 THEN 'CASH'
            WHEN 1 THEN 'BANK_TRANSFER'
            WHEN 2 THEN 'CARD'
            WHEN 3 THEN 'CMS'
            ELSE 'VIRTUAL_ACCOUNT'
        END,
        'COMPLETED'
    FROM invoices i
    WHERE i.status = 'PAID'::invoice_status;
    
    -- 10. 통계 정보 출력
    RAISE NOTICE '=== 성능 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '건물 수: %', (SELECT COUNT(*) FROM buildings WHERE name LIKE '성능테스트빌딩%');
    RAISE NOTICE '호실 수: %', (SELECT COUNT(*) FROM units u JOIN buildings b ON u.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '임차인 수: %', (SELECT COUNT(*) FROM tenants WHERE name LIKE '성능테스트임차인%');
    RAISE NOTICE '관리비 항목 수: %', (SELECT COUNT(*) FROM fee_items fi JOIN buildings b ON fi.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '청구월 수: %', (SELECT COUNT(*) FROM billing_months bm JOIN buildings b ON bm.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '검침 데이터 수: %', (SELECT COUNT(*) FROM unit_meter_readings umr JOIN billing_months bm ON umr.billing_month_id = bm.id JOIN buildings b ON bm.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '관리비 산정 수: %', (SELECT COUNT(*) FROM monthly_fees mf JOIN billing_months bm ON mf.billing_month_id = bm.id JOIN buildings b ON bm.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '고지서 수: %', (SELECT COUNT(*) FROM invoices i JOIN billing_months bm ON i.billing_month_id = bm.id JOIN buildings b ON bm.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    RAISE NOTICE '수납 내역 수: %', (SELECT COUNT(*) FROM payments p JOIN invoices i ON p.invoice_id = i.id JOIN billing_months bm ON i.billing_month_id = bm.id JOIN buildings b ON bm.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%');
    
END;
$$ LANGUAGE plpgsql;

-- 성능 테스트 데이터 생성 실행
SELECT generate_performance_test_data();

-- 임시 함수 삭제
DROP FUNCTION generate_performance_test_data();