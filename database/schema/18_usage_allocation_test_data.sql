-- =====================================================
-- 사용량 배분 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    rule_count INTEGER := 0;
    factor_count INTEGER := 0;
    allocation_count INTEGER := 0;
    
    -- 배분 규칙 ID 저장용 변수들
    area_rule_id UUID;
    household_rule_id UUID;
    weighted_rule_id UUID;
BEGIN
    -- 각 회사에 대해 사용량 배분 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 사용량 배분 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 회사 전체 배분 규칙 생성
        -- 면적 기준 배분 규칙
        INSERT INTO bms.usage_allocation_rules (
            company_id, building_id, rule_name, rule_description, rule_type,
            meter_type, allocation_method, allocation_basis,
            min_allocation_ratio, max_allocation_ratio, priority_order
        ) VALUES 
        (company_rec.company_id, NULL, '면적 기준 배분', '전용면적 기준으로 공용 사용량을 배분', 'COMMON_AREA',
         'ELECTRIC', 'PROPORTIONAL', 'AREA', 1.0, 50.0, 1);
        
        -- 세대수 기준 배분 규칙
        INSERT INTO bms.usage_allocation_rules (
            company_id, building_id, rule_name, rule_description, rule_type,
            meter_type, allocation_method, allocation_basis,
            min_allocation_ratio, max_allocation_ratio, priority_order
        ) VALUES 
        (company_rec.company_id, NULL, '세대수 기준 배분', '세대수 기준으로 균등 배분', 'COMMON_AREA',
         'HEATING', 'EQUAL', 'HOUSEHOLD', 0.5, 30.0, 2);
        
        -- 가중치 기준 배분 규칙
        INSERT INTO bms.usage_allocation_rules (
            company_id, building_id, rule_name, rule_description, rule_type,
            meter_type, allocation_method, allocation_basis,
            min_allocation_ratio, max_allocation_ratio, priority_order
        ) VALUES 
        (company_rec.company_id, NULL, '복합 가중치 배분', '면적과 세대수를 고려한 가중치 배분', 'PROPORTIONAL',
         'WATER', 'WEIGHTED', 'CUSTOM_WEIGHT', 0.5, 40.0, 3);
        
        -- 규칙 ID 개별 조회
        SELECT rule_id INTO area_rule_id FROM bms.usage_allocation_rules WHERE company_id = company_rec.company_id AND rule_name = '면적 기준 배분';
        SELECT rule_id INTO household_rule_id FROM bms.usage_allocation_rules WHERE company_id = company_rec.company_id AND rule_name = '세대수 기준 배분';
        SELECT rule_id INTO weighted_rule_id FROM bms.usage_allocation_rules WHERE company_id = company_rec.company_id AND rule_name = '복합 가중치 배분';
        
        rule_count := rule_count + 3;
        
        -- 2. 건물별 개별 배분 규칙 생성
        FOR building_rec IN 
            SELECT building_id, name as building_name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            RAISE NOTICE '  건물 % 개별 배분 규칙 생성', building_rec.building_name;
            
            -- 건물별 특별 배분 규칙
            INSERT INTO bms.usage_allocation_rules (
                company_id, building_id, rule_name, rule_description, rule_type,
                meter_type, allocation_method, allocation_basis, priority_order
            ) VALUES 
            (company_rec.company_id, building_rec.building_id, 
             building_rec.building_name || ' 전용 배분 규칙', 
             building_rec.building_name || '에 적용되는 개별 배분 규칙', 'CUSTOM',
             'ELECTRIC', 'WEIGHTED', 'CUSTOM_WEIGHT', 1);
            
            rule_count := rule_count + 1;
        END LOOP;
        
        -- 3. 호실별 배분 계수 생성
        DECLARE
            v_unit_rec RECORD;
            v_total_area DECIMAL(10,2);
            v_total_units INTEGER;
        BEGIN
            -- 각 건물별로 호실 배분 계수 계산
            FOR building_rec IN 
                SELECT building_id, name as building_name
                FROM bms.buildings 
                WHERE company_id = company_rec.company_id
                LIMIT 2
            LOOP
                -- 건물 전체 면적 및 호실 수 계산
                SELECT SUM(area), COUNT(*) INTO v_total_area, v_total_units
                FROM bms.units
                WHERE building_id = building_rec.building_id
                  AND status = 'OCCUPIED';
                
                -- 각 호실별 배분 계수 생성
                FOR v_unit_rec IN 
                    SELECT unit_id, unit_number, area
                    FROM bms.units
                    WHERE building_id = building_rec.building_id
                      AND status = 'OCCUPIED'
                    LIMIT 5  -- 각 건물당 5개 호실만
                LOOP
                    -- 면적 기준 배분 계수
                    INSERT INTO bms.unit_allocation_factors (
                        company_id, unit_id, rule_id, factor_type, factor_value,
                        factor_description, base_area, adjustment_factor
                    ) VALUES 
                    (company_rec.company_id, v_unit_rec.unit_id, area_rule_id, 'AREA_RATIO',
                     CASE WHEN v_total_area > 0 THEN v_unit_rec.area / v_total_area ELSE 0 END,
                     '전용면적 기준 배분 계수', v_unit_rec.area, 1.0),
                    
                    -- 세대수 기준 배분 계수
                    (company_rec.company_id, v_unit_rec.unit_id, household_rule_id, 'HOUSEHOLD_RATIO',
                     CASE WHEN v_total_units > 0 THEN 1.0 / v_total_units ELSE 0 END,
                     '세대수 기준 균등 배분 계수', NULL, 1.0),
                    
                    -- 복합 가중치 배분 계수
                    (company_rec.company_id, v_unit_rec.unit_id, weighted_rule_id, 'COMPOSITE_RATIO',
                     CASE WHEN v_total_area > 0 AND v_total_units > 0 THEN 
                         (v_unit_rec.area / v_total_area * 0.6) + (1.0 / v_total_units * 0.4)
                     ELSE 0 END,
                     '면적과 세대수 복합 가중치 배분 계수', v_unit_rec.area, 1.0);
                    
                    factor_count := factor_count + 3;
                END LOOP;
            END LOOP;
        END;
        
        -- 4. 사용량 배분 실행 시뮬레이션 (최근 3개월)
        FOR i IN 0..2 LOOP
            DECLARE
                v_allocation_period DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL;
                v_meter_rec RECORD;
                v_allocation_id UUID;
            BEGIN
                -- 각 건물의 공용 계량기별 배분 실행
                FOR v_meter_rec IN 
                    SELECT m.meter_id, m.building_id, m.meter_type, mr.usage_amount, mr.reading_id
                    FROM bms.meters m
                    JOIN bms.meter_readings mr ON m.meter_id = mr.meter_id
                    WHERE m.company_id = company_rec.company_id
                      AND m.unit_id IS NULL  -- 공용 계량기만
                      AND DATE_TRUNC('month', mr.reading_date) = v_allocation_period
                      AND mr.usage_amount IS NOT NULL
                      AND mr.usage_amount > 0
                    LIMIT 3  -- 각 월당 3개 계량기만
                LOOP
                    -- 계량기 유형에 따른 적절한 배분 규칙 선택
                    DECLARE
                        v_selected_rule_id UUID;
                    BEGIN
                        CASE v_meter_rec.meter_type
                            WHEN 'ELECTRIC' THEN v_selected_rule_id := area_rule_id;
                            WHEN 'WATER' THEN v_selected_rule_id := weighted_rule_id;
                            WHEN 'GAS' THEN v_selected_rule_id := area_rule_id;
                            WHEN 'HEATING' THEN v_selected_rule_id := household_rule_id;
                            ELSE v_selected_rule_id := area_rule_id;
                        END CASE;
                        
                        -- 사용량 배분 실행
                        v_allocation_id := bms.execute_usage_allocation(
                            v_meter_rec.building_id,
                            v_allocation_period,
                            v_selected_rule_id,
                            v_meter_rec.usage_amount,
                            v_meter_rec.meter_id,
                            v_meter_rec.reading_id
                        );
                        
                        allocation_count := allocation_count + 1;
                        
                        -- 일부 배분 결과를 검증 완료 상태로 변경
                        IF random() < 0.7 THEN  -- 70% 확률로 검증 완료
                            UPDATE bms.usage_allocations
                            SET allocation_status = 'VERIFIED',
                                is_verified = true,
                                verified_by = (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                                verified_at = NOW() - (random() * 10 || ' days')::INTERVAL
                            WHERE allocation_id = v_allocation_id;
                            
                            -- 일부는 승인까지 완료
                            IF random() < 0.5 THEN  -- 50% 확률로 승인 완료
                                UPDATE bms.usage_allocations
                                SET allocation_status = 'APPROVED',
                                    is_approved = true,
                                    approved_by = (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                                    approved_at = NOW() - (random() * 5 || ' days')::INTERVAL
                                WHERE allocation_id = v_allocation_id;
                            END IF;
                        END IF;
                    END;
                END LOOP;
            END;
        END LOOP;
        
        RAISE NOTICE '회사 % 사용량 배분 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 사용량 배분 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 배분 규칙: %개', rule_count;
    RAISE NOTICE '생성된 배분 계수: %개', factor_count;
    RAISE NOTICE '생성된 배분 결과: %개', allocation_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 사용량 배분 시스템 테스트 데이터 생성이 완료되었습니다!' as result;