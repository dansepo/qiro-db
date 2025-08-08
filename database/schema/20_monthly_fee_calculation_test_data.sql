-- =====================================================
-- 월별 관리비 산정 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    unit_rec RECORD;
    calculation_count INTEGER := 0;
    unit_fee_count INTEGER := 0;
    log_count INTEGER := 0;
    adjustment_count INTEGER := 0;
    
    -- 산정 ID 저장용 변수
    v_calculation_id UUID;
    v_fee_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 월별 관리비 산정 시스템 데이터 생성
    FOR company_rec IN 
        SELECT DISTINCT c.company_id, c.company_name
        FROM bms.companies c
        JOIN bms.buildings b ON c.company_id = b.company_id
        JOIN bms.units u ON b.building_id = u.building_id
        WHERE u.unit_status = 'OCCUPIED'
        LIMIT 3  -- 입주 호실이 있는 3개 회사만
    LOOP
        RAISE NOTICE '회사 % (%) 월별 관리비 산정 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 각 건물별로 월별 관리비 산정 생성 (최근 6개월)
        FOR building_rec IN 
            SELECT DISTINCT b.building_id, b.name as building_name
            FROM bms.buildings b
            JOIN bms.units u ON b.building_id = u.building_id
            WHERE b.company_id = company_rec.company_id
              AND u.unit_status = 'OCCUPIED'
            LIMIT 2  -- 입주 호실이 있는 2개 건물만
        LOOP
            RAISE NOTICE '  건물 % 월별 관리비 산정 생성', building_rec.building_name;
            
            -- 최근 6개월 관리비 산정 생성
            FOR i IN 0..5 LOOP
                DECLARE
                    v_calculation_period DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL;
                    v_unit_count INTEGER;
                    v_total_amount DECIMAL(15,2) := 0;
                BEGIN
                    -- 대상 호실 수 계산
                    SELECT COUNT(*) INTO v_unit_count
                    FROM bms.units
                    WHERE building_id = building_rec.building_id
                      AND unit_status = 'OCCUPIED';
                    
                    -- 월별 관리비 산정 헤더 생성
                    v_calculation_id := gen_random_uuid();
                    
                    INSERT INTO bms.monthly_fee_calculations (
                        calculation_id, company_id, building_id,
                        calculation_period, calculation_name, calculation_type,
                        target_unit_count, calculation_status, calculation_method,
                        calculation_rules, rounding_method, rounding_unit,
                        is_validated, is_approved, is_finalized,
                        validated_by, validated_at, approved_by, approved_at,
                        finalized_by, finalized_at, created_by
                    ) VALUES (
                        v_calculation_id, company_rec.company_id, building_rec.building_id,
                        v_calculation_period, 
                        DATE_PART('year', v_calculation_period) || '년 ' || DATE_PART('month', v_calculation_period) || '월 관리비',
                        CASE WHEN i = 0 THEN 'REGULAR' WHEN random() < 0.1 THEN 'ADJUSTMENT' ELSE 'REGULAR' END,
                        v_unit_count, 
                        CASE 
                            WHEN i <= 1 THEN 'FINALIZED'  -- 최근 2개월은 확정
                            WHEN i <= 3 THEN 'APPROVED'   -- 3-4개월 전은 승인
                            ELSE 'CALCULATED'              -- 나머지는 계산 완료
                        END,
                        'AUTOMATIC',
                        jsonb_build_object(
                            'include_utilities', true,
                            'apply_discounts', true,
                            'calculate_late_fees', false,
                            'prorate_partial_month', true
                        ),
                        'ROUND', 10,  -- 10원 단위 반올림
                        CASE WHEN i <= 3 THEN true ELSE false END,  -- 최근 4개월은 검증 완료
                        CASE WHEN i <= 1 THEN true ELSE false END,  -- 최근 2개월은 승인 완료
                        CASE WHEN i <= 1 THEN true ELSE false END,  -- 최근 2개월은 확정 완료
                        CASE WHEN i <= 3 THEN v_admin_user_id ELSE NULL END,
                        CASE WHEN i <= 3 THEN v_calculation_period + INTERVAL '5 days' ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_admin_user_id ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_calculation_period + INTERVAL '7 days' ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_admin_user_id ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_calculation_period + INTERVAL '10 days' ELSE NULL END,
                        v_admin_user_id
                    );
                    
                    calculation_count := calculation_count + 1;
                    
                    -- 계산 로그 생성 (초기화 단계)
                    INSERT INTO bms.fee_calculation_logs (
                        calculation_id, company_id, step_sequence, step_name, step_type,
                        step_description, input_data, calculation_result,
                        execution_status, execution_time_ms
                    ) VALUES (
                        v_calculation_id, company_rec.company_id, 1, '계산 초기화', 'INITIALIZATION',
                        '월별 관리비 계산 프로세스 초기화',
                        jsonb_build_object('target_units', v_unit_count, 'calculation_period', v_calculation_period),
                        jsonb_build_object('status', 'initialized', 'timestamp', NOW()),
                        'SUCCESS', 150
                    );
                    
                    log_count := log_count + 1;
                    
                    -- 각 호실별 관리비 상세 생성
                    FOR unit_rec IN 
                        SELECT unit_id, unit_number, exclusive_area as area, unit_status as status
                        FROM bms.units
                        WHERE building_id = building_rec.building_id
                          AND unit_status = 'OCCUPIED'
                        LIMIT 10  -- 각 건물당 10개 호실만
                    LOOP
                        DECLARE
                            v_common_mgmt_fee DECIMAL(15,2);
                            v_cleaning_fee DECIMAL(15,2);
                            v_security_fee DECIMAL(15,2);
                            v_electricity_fee DECIMAL(15,2);
                            v_water_fee DECIMAL(15,2);
                            v_gas_fee DECIMAL(15,2);
                            v_heating_fee DECIMAL(15,2);
                            v_parking_fee DECIMAL(15,2);
                            v_subtotal DECIMAL(15,2);
                            v_discount DECIMAL(15,2);
                            v_unit_total DECIMAL(15,2);
                        BEGIN
                            -- 면적 기준 관리비 계산 (면적당 단가 적용)
                            v_common_mgmt_fee := ROUND((unit_rec.area * (800 + random() * 200)) / 10) * 10;  -- 800~1000원/㎡
                            v_cleaning_fee := ROUND((unit_rec.area * (200 + random() * 100)) / 10) * 10;     -- 200~300원/㎡
                            v_security_fee := ROUND((unit_rec.area * (150 + random() * 100)) / 10) * 10;     -- 150~250원/㎡
                            
                            -- 사용량 기준 공과금 (랜덤 생성)
                            v_electricity_fee := ROUND((50000 + random() * 100000) / 10) * 10;  -- 5~15만원
                            v_water_fee := ROUND((20000 + random() * 30000) / 10) * 10;         -- 2~5만원
                            v_gas_fee := ROUND((30000 + random() * 50000) / 10) * 10;           -- 3~8만원
                            v_heating_fee := ROUND((40000 + random() * 60000) / 10) * 10;       -- 4~10만원
                            
                            -- 기타 비용
                            v_parking_fee := CASE WHEN random() < 0.7 THEN 50000 ELSE 0 END;    -- 70% 확률로 주차비
                            
                            -- 소계 계산
                            v_subtotal := v_common_mgmt_fee + v_cleaning_fee + v_security_fee + 
                                         v_electricity_fee + v_water_fee + v_gas_fee + v_heating_fee + v_parking_fee;
                            
                            -- 할인 적용 (10% 확률)
                            v_discount := CASE WHEN random() < 0.1 THEN ROUND(v_subtotal * 0.05 / 10) * 10 ELSE 0 END;
                            
                            -- 총액 계산
                            v_unit_total := v_subtotal - v_discount;
                            v_total_amount := v_total_amount + v_unit_total;
                            
                            -- 호실별 관리비 상세 생성
                            v_fee_id := gen_random_uuid();
                            
                            INSERT INTO bms.unit_monthly_fees (
                                fee_id, calculation_id, company_id, unit_id,
                                fee_period, unit_number, unit_area, occupancy_status,
                                common_management_fee, cleaning_fee, security_fee,
                                electricity_fee, water_fee, gas_fee, heating_fee,
                                parking_fee, discount_amount, subtotal_amount, total_amount,
                                calculation_details, applied_rates, usage_data
                            ) VALUES (
                                v_fee_id, v_calculation_id, company_rec.company_id, unit_rec.unit_id,
                                v_calculation_period, unit_rec.unit_number, unit_rec.area, unit_rec.status,
                                v_common_mgmt_fee, v_cleaning_fee, v_security_fee,
                                v_electricity_fee, v_water_fee, v_gas_fee, v_heating_fee,
                                v_parking_fee, v_discount, v_subtotal, v_unit_total,
                                jsonb_build_object(
                                    'calculation_method', 'area_based',
                                    'area_rate_common', 800 + random() * 200,
                                    'area_rate_cleaning', 200 + random() * 100,
                                    'area_rate_security', 150 + random() * 100,
                                    'utility_estimated', true
                                ),
                                jsonb_build_object(
                                    'common_mgmt_rate', 800 + random() * 200,
                                    'cleaning_rate', 200 + random() * 100,
                                    'security_rate', 150 + random() * 100,
                                    'electricity_rate', 120,
                                    'water_rate', 800,
                                    'gas_rate', 600
                                ),
                                jsonb_build_object(
                                    'electricity_usage', 300 + random() * 200,
                                    'water_usage', 25 + random() * 15,
                                    'gas_usage', 50 + random() * 30,
                                    'heating_usage', 1 + random() * 2
                                )
                            );
                            
                            unit_fee_count := unit_fee_count + 1;
                            
                            -- 일부 호실에 대해 조정 이력 생성 (5% 확률)
                            IF random() < 0.05 THEN
                                DECLARE
                                    v_adjustment_amount DECIMAL(15,2) := ROUND((random() * 20000 - 10000) / 10) * 10;  -- -1만원 ~ +1만원
                                BEGIN
                                    INSERT INTO bms.fee_adjustment_history (
                                        calculation_id, unit_fee_id, company_id,
                                        adjustment_type, adjustment_reason, adjustment_category,
                                        original_amount, adjusted_amount, adjustment_difference,
                                        affected_fee_items, adjustment_details,
                                        approval_status, approved_by, approved_at,
                                        requested_by, processed_by, processed_at
                                    ) VALUES (
                                        v_calculation_id, v_fee_id, company_rec.company_id,
                                        CASE WHEN v_adjustment_amount > 0 THEN 'MANUAL' ELSE 'CORRECTION' END,
                                        CASE WHEN v_adjustment_amount > 0 THEN '특별 할인 적용' ELSE '계산 오류 정정' END,
                                        CASE WHEN v_adjustment_amount > 0 THEN 'SPECIAL_CASE' ELSE 'CALCULATION_ERROR' END,
                                        v_unit_total, v_unit_total + v_adjustment_amount, v_adjustment_amount,
                                        ARRAY['total_amount'],
                                        jsonb_build_object(
                                            'reason_detail', CASE WHEN v_adjustment_amount > 0 THEN '장기 거주자 할인' ELSE '면적 계산 오류 수정' END,
                                            'adjustment_date', v_calculation_period + INTERVAL '3 days'
                                        ),
                                        'APPROVED', v_admin_user_id, v_calculation_period + INTERVAL '4 days',
                                        v_admin_user_id, v_admin_user_id, v_calculation_period + INTERVAL '3 days'
                                    );
                                    
                                    -- 조정된 금액으로 업데이트
                                    UPDATE bms.unit_monthly_fees
                                    SET adjustment_amount = v_adjustment_amount,
                                        total_amount = v_unit_total + v_adjustment_amount,
                                        adjusted_by = v_admin_user_id,
                                        adjusted_at = v_calculation_period + INTERVAL '3 days'
                                    WHERE fee_id = v_fee_id;
                                    
                                    adjustment_count := adjustment_count + 1;
                                END;
                            END IF;
                        END;
                    END LOOP;
                    
                    -- 계산 완료 로그 생성
                    INSERT INTO bms.fee_calculation_logs (
                        calculation_id, company_id, step_sequence, step_name, step_type,
                        step_description, calculation_result,
                        execution_status, execution_time_ms
                    ) VALUES (
                        v_calculation_id, company_rec.company_id, 2, '관리비 계산 완료', 'FEE_CALCULATION',
                        '호실별 관리비 계산 완료',
                        jsonb_build_object(
                            'total_units', v_unit_count,
                            'total_amount', v_total_amount,
                            'avg_amount', CASE WHEN v_unit_count > 0 THEN v_total_amount / v_unit_count ELSE 0 END
                        ),
                        'SUCCESS', 2500
                    );
                    
                    log_count := log_count + 1;
                    
                    -- 헤더 총액 업데이트
                    UPDATE bms.monthly_fee_calculations
                    SET total_amount = v_total_amount,
                        total_common_fees = v_total_amount * 0.4,  -- 40% 공통 관리비
                        total_individual_fees = v_total_amount * 0.1,  -- 10% 개별 관리비
                        total_utility_fees = v_total_amount * 0.5   -- 50% 공과금
                    WHERE calculation_id = v_calculation_id;
                END;
            END LOOP;
        END LOOP;
        
        RAISE NOTICE '회사 % 월별 관리비 산정 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 월별 관리비 산정 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 관리비 산정: %개', calculation_count;
    RAISE NOTICE '생성된 호실별 관리비: %개', unit_fee_count;
    RAISE NOTICE '생성된 계산 로그: %개', log_count;
    RAISE NOTICE '생성된 조정 이력: %개', adjustment_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 월별 관리비 산정 시스템 테스트 데이터 생성이 완료되었습니다!' as result;