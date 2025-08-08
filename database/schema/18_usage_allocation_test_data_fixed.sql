-- =====================================================
-- 사용량 배분 시스템 테스트 데이터 생성 스크립트 (수정버전)
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    meter_rec RECORD;
    unit_rec RECORD;
    rule_count INTEGER := 0;
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
        
        -- 3. 사용량 배분 실행 시뮬레이션 (최근 3개월)
        FOR i IN 0..2 LOOP
            DECLARE
                v_period_start DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL;
                v_period_end DATE := v_period_start + INTERVAL '1 month' - INTERVAL '1 day';
            BEGIN
                -- 각 건물의 공용 계량기별 배분 실행
                FOR meter_rec IN 
                    SELECT m.meter_id, m.building_id, m.meter_type, 
                           COALESCE(mr.usage_amount, 1000 + random() * 5000) as usage_amount
                    FROM bms.meters m
                    LEFT JOIN bms.meter_readings mr ON m.meter_id = mr.meter_id 
                        AND DATE_TRUNC('month', mr.reading_date) = v_period_start
                    WHERE m.company_id = company_rec.company_id
                      AND m.unit_id IS NULL  -- 공용 계량기만
                    LIMIT 2  -- 각 월당 2개 계량기만
                LOOP
                    -- 해당 건물의 각 호실별로 배분 생성
                    FOR unit_rec IN 
                        SELECT unit_id, area
                        FROM bms.units
                        WHERE building_id = meter_rec.building_id
                          AND status = 'OCCUPIED'
                        LIMIT 3  -- 각 계량기당 3개 호실만
                    LOOP
                        DECLARE
                            v_selected_rule_id UUID;
                            v_allocation_ratio DECIMAL(8,4);
                            v_calculated_amount DECIMAL(15,4);
                            v_total_area DECIMAL(10,2);
                        BEGIN
                            -- 계량기 유형에 따른 적절한 배분 규칙 선택
                            CASE meter_rec.meter_type
                                WHEN 'ELECTRIC' THEN v_selected_rule_id := area_rule_id;
                                WHEN 'WATER' THEN v_selected_rule_id := weighted_rule_id;
                                WHEN 'GAS' THEN v_selected_rule_id := area_rule_id;
                                WHEN 'HEATING' THEN v_selected_rule_id := household_rule_id;
                                ELSE v_selected_rule_id := area_rule_id;
                            END CASE;
                            
                            -- 건물 전체 면적 조회
                            SELECT SUM(area) INTO v_total_area
                            FROM bms.units
                            WHERE building_id = meter_rec.building_id
                              AND status = 'OCCUPIED';
                            
                            -- 배분 비율 계산 (면적 기준)
                            IF v_total_area > 0 THEN
                                v_allocation_ratio := (unit_rec.area / v_total_area) * 100;
                            ELSE
                                v_allocation_ratio := 10.0;  -- 기본값
                            END IF;
                            
                            -- 배분량 계산
                            v_calculated_amount := meter_rec.usage_amount * (v_allocation_ratio / 100.0);
                            
                            -- 사용량 배분 결과 저장
                            INSERT INTO bms.usage_allocations (
                                company_id, rule_id, allocation_period_start, allocation_period_end,
                                source_meter_id, target_unit_id, total_source_usage,
                                allocation_basis_value, allocation_ratio, calculated_amount,
                                final_allocated_amount, allocation_status
                            ) VALUES (
                                company_rec.company_id, v_selected_rule_id, v_period_start, v_period_end,
                                meter_rec.meter_id, unit_rec.unit_id, meter_rec.usage_amount,
                                unit_rec.area, v_allocation_ratio, v_calculated_amount,
                                v_calculated_amount, 'CALCULATED'
                            );
                            
                            allocation_count := allocation_count + 1;
                            
                            -- 일부 배분 결과를 검증 완료 상태로 변경
                            IF random() < 0.7 THEN  -- 70% 확률로 검증 완료
                                UPDATE bms.usage_allocations
                                SET allocation_status = 'VALIDATED',
                                    is_validated = true,
                                    validation_status = 'PASSED',
                                    validated_by = (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                                    validated_at = NOW() - (random() * 10 || ' days')::INTERVAL
                                WHERE company_id = company_rec.company_id
                                  AND rule_id = v_selected_rule_id
                                  AND allocation_period_start = v_period_start
                                  AND source_meter_id = meter_rec.meter_id
                                  AND target_unit_id = unit_rec.unit_id;
                                
                                -- 일부는 승인까지 완료
                                IF random() < 0.5 THEN  -- 50% 확률로 승인 완료
                                    UPDATE bms.usage_allocations
                                    SET allocation_status = 'APPROVED',
                                        approval_status = 'APPROVED',
                                        approved_by = (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                                        approved_at = NOW() - (random() * 5 || ' days')::INTERVAL
                                    WHERE company_id = company_rec.company_id
                                      AND rule_id = v_selected_rule_id
                                      AND allocation_period_start = v_period_start
                                      AND source_meter_id = meter_rec.meter_id
                                      AND target_unit_id = unit_rec.unit_id;
                                END IF;
                            END IF;
                        END;
                    END LOOP;
                END LOOP;
            END;
        END LOOP;
        
        RAISE NOTICE '회사 % 사용량 배분 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 사용량 배분 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 배분 규칙: %개', rule_count;
    RAISE NOTICE '생성된 배분 결과: %개', allocation_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 사용량 배분 시스템 테스트 데이터 생성이 완료되었습니다!' as result;