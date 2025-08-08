-- =====================================================
-- 관리비 검증 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    calculation_rec RECORD;
    rule_count INTEGER := 0;
    validation_count INTEGER := 0;
    anomaly_config_count INTEGER := 0;
    
    -- 규칙 ID 저장용 변수들
    v_range_rule_id UUID;
    v_comparison_rule_id UUID;
    v_statistical_rule_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 검증 시스템 데이터 생성
    FOR company_rec IN 
        SELECT DISTINCT c.company_id, c.company_name
        FROM bms.companies c
        JOIN bms.monthly_fee_calculations mfc ON c.company_id = mfc.company_id
        LIMIT 3  -- 관리비 계산이 있는 3개 회사만
    LOOP
        RAISE NOTICE '회사 % (%) 검증 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 1. 검증 규칙 생성
        -- 범위 검사 규칙
        INSERT INTO bms.validation_rules (
            company_id, building_id, rule_name, rule_description,
            rule_category, rule_type, target_scope, target_fee_types,
            validation_condition, threshold_values,
            severity_level, auto_fix_enabled, auto_fix_action,
            notification_enabled, notification_recipients,
            priority_order, created_by
        ) VALUES 
        (company_rec.company_id, NULL, '관리비 총액 범위 검사', '호실별 관리비 총액이 정상 범위 내에 있는지 검증',
         'AMOUNT_VALIDATION', 'RANGE_CHECK', 'UNIT', ARRAY['total_amount'],
         jsonb_build_object('field_name', 'total_amount'),
         jsonb_build_object('min_value', 50000, 'max_value', 1000000),
         'ERROR', true, 
         jsonb_build_object('action_type', 'ROUND_AMOUNT', 'rounding_unit', 10),
         true, ARRAY['admin@' || company_rec.company_name || '.com'],
         1, v_admin_user_id);
        
        -- 비교 검증 규칙
        INSERT INTO bms.validation_rules (
            company_id, building_id, rule_name, rule_description,
            rule_category, rule_type, target_scope, target_fee_types,
            validation_condition, threshold_values,
            severity_level, auto_fix_enabled,
            notification_enabled, notification_recipients,
            priority_order, created_by
        ) VALUES 
        (company_rec.company_id, NULL, '총액 일치성 검증', '헤더 총액과 호실별 합계가 일치하는지 검증',
         'DATA_CONSISTENCY', 'COMPARISON', 'CALCULATION', ARRAY['total_amount'],
         jsonb_build_object('comparison_type', 'header_vs_detail'),
         jsonb_build_object('tolerance', 1.0),
         'CRITICAL', false,
         true, ARRAY['admin@' || company_rec.company_name || '.com'],
         2, v_admin_user_id);
        
        -- 통계적 검증 규칙 (이상치 탐지)
        INSERT INTO bms.validation_rules (
            company_id, building_id, rule_name, rule_description,
            rule_category, rule_type, target_scope, target_fee_types,
            validation_condition, threshold_values,
            severity_level, auto_fix_enabled,
            notification_enabled, notification_recipients,
            priority_order, created_by
        ) VALUES 
        (company_rec.company_id, NULL, '관리비 이상치 탐지', '통계적 방법으로 관리비 이상치를 탐지',
         'ANOMALY_DETECTION', 'STATISTICAL', 'UNIT', ARRAY['total_amount'],
         jsonb_build_object('field_name', 'total_amount'),
         jsonb_build_object('z_threshold', 2.5),
         'WARNING', false,
         true, ARRAY['admin@' || company_rec.company_name || '.com'],
         3, v_admin_user_id);
        
        -- 전기료 범위 검사 규칙
        INSERT INTO bms.validation_rules (
            company_id, building_id, rule_name, rule_description,
            rule_category, rule_type, target_scope, target_fee_types,
            validation_condition, threshold_values,
            severity_level, auto_fix_enabled,
            notification_enabled, notification_recipients,
            priority_order, created_by
        ) VALUES 
        (company_rec.company_id, NULL, '전기료 범위 검사', '호실별 전기료가 정상 범위 내에 있는지 검증',
         'AMOUNT_VALIDATION', 'RANGE_CHECK', 'UNIT', ARRAY['electricity_fee'],
         jsonb_build_object('field_name', 'electricity_fee'),
         jsonb_build_object('min_value', 10000, 'max_value', 200000),
         'WARNING', false,
         true, ARRAY['admin@' || company_rec.company_name || '.com'],
         4, v_admin_user_id);
        
        -- 규칙 ID 조회
        SELECT rule_id INTO v_range_rule_id FROM bms.validation_rules WHERE company_id = company_rec.company_id AND rule_name = '관리비 총액 범위 검사';
        SELECT rule_id INTO v_comparison_rule_id FROM bms.validation_rules WHERE company_id = company_rec.company_id AND rule_name = '총액 일치성 검증';
        SELECT rule_id INTO v_statistical_rule_id FROM bms.validation_rules WHERE company_id = company_rec.company_id AND rule_name = '관리비 이상치 탐지';
        
        rule_count := rule_count + 4;
        
        -- 2. 이상치 탐지 설정 생성
        INSERT INTO bms.anomaly_detection_configs (
            company_id, building_id, config_name, config_description,
            detection_type, target_fee_types, target_metrics,
            algorithm_type, algorithm_parameters,
            threshold_method, threshold_multiplier,
            training_period_months, min_data_points,
            auto_execution, execution_schedule,
            created_by
        ) VALUES 
        (company_rec.company_id, NULL, '월별 관리비 급증 탐지', '전월 대비 관리비가 급격히 증가한 경우 탐지',
         'AMOUNT_SPIKE', ARRAY['total_amount'], ARRAY['month_over_month_change'],
         'Z_SCORE', jsonb_build_object('window_size', 3, 'sensitivity', 2.0),
         'STATISTICAL', 2.5,
         6, 5,
         true, '0 0 1 * *',  -- 매월 1일 실행
         v_admin_user_id),
        
        (company_rec.company_id, NULL, '계절적 패턴 이상 탐지', '계절적 패턴에서 벗어난 관리비 탐지',
         'SEASONAL_ANOMALY', ARRAY['heating_fee', 'electricity_fee'], ARRAY['seasonal_pattern'],
         'SEASONAL_DECOMPOSE', jsonb_build_object('seasonal_period', 12, 'trend_component', true),
         'PERCENTILE', 1.5,
         12, 10,
         true, '0 0 15 * *',  -- 매월 15일 실행
         v_admin_user_id);
        
        anomaly_config_count := anomaly_config_count + 2;
        
        -- 3. 기존 관리비 계산에 대해 검증 실행
        FOR calculation_rec IN 
            SELECT calculation_id, calculation_period, building_id
            FROM bms.monthly_fee_calculations
            WHERE company_id = company_rec.company_id
              AND calculation_status IN ('CALCULATED', 'VALIDATED', 'APPROVED', 'FINALIZED')
            ORDER BY calculation_period DESC
            LIMIT 5  -- 최근 5개 계산만
        LOOP
            DECLARE
                v_execution_id UUID;
                v_unit_rec RECORD;
                v_total_amount DECIMAL(15,2);
                v_avg_amount DECIMAL(15,2);
                v_stddev_amount DECIMAL(15,2);
            BEGIN
                RAISE NOTICE '  계산 % 검증 실행', calculation_rec.calculation_period;
                
                -- 검증 실행
                v_execution_id := bms.execute_fee_validation(
                    calculation_rec.calculation_id,
                    'AUTOMATIC',
                    v_admin_user_id
                );
                
                -- 추가적인 테스트 검증 결과 생성 (시뮬레이션)
                -- 일부 호실에 대해 의도적으로 검증 실패 케이스 생성
                
                -- 총액 통계 계산
                SELECT SUM(total_amount), AVG(total_amount), STDDEV(total_amount)
                INTO v_total_amount, v_avg_amount, v_stddev_amount
                FROM bms.unit_monthly_fees
                WHERE calculation_id = calculation_rec.calculation_id;
                
                -- 범위 초과 케이스 시뮬레이션 (5% 확률)
                FOR v_unit_rec IN 
                    SELECT unit_id, unit_number, total_amount
                    FROM bms.unit_monthly_fees umf
                    JOIN bms.units u ON umf.unit_id = u.unit_id
                    WHERE umf.calculation_id = calculation_rec.calculation_id
                      AND random() < 0.05  -- 5% 확률
                    LIMIT 2
                LOOP
                    IF v_unit_rec.total_amount > 800000 THEN  -- 80만원 초과
                        INSERT INTO bms.validation_results (
                            company_id, calculation_id, rule_id,
                            target_type, target_id, target_description,
                            validation_status, severity_level,
                            validation_message, expected_value, actual_value,
                            deviation_amount, resolution_status
                        ) VALUES (
                            company_rec.company_id, calculation_rec.calculation_id, v_range_rule_id,
                            'UNIT_FEE', v_unit_rec.unit_id, v_unit_rec.unit_number || '호 관리비 범위 초과',
                            'FAILED', 'ERROR',
                            '관리비 총액이 허용 범위를 초과했습니다',
                            jsonb_build_object('max_value', 800000),
                            jsonb_build_object('value', v_unit_rec.total_amount),
                            v_unit_rec.total_amount - 800000,
                            CASE WHEN random() < 0.3 THEN 'RESOLVED' ELSE 'PENDING' END
                        );
                        
                        validation_count := validation_count + 1;
                    END IF;
                END LOOP;
                
                -- 이상치 탐지 시뮬레이션
                IF v_stddev_amount > 0 THEN
                    FOR v_unit_rec IN 
                        SELECT unit_id, unit_number, total_amount
                        FROM bms.unit_monthly_fees umf
                        JOIN bms.units u ON umf.unit_id = u.unit_id
                        WHERE umf.calculation_id = calculation_rec.calculation_id
                          AND ABS(umf.total_amount - v_avg_amount) > (v_stddev_amount * 2.5)  -- Z-score > 2.5
                        LIMIT 3
                    LOOP
                        INSERT INTO bms.validation_results (
                            company_id, calculation_id, rule_id,
                            target_type, target_id, target_description,
                            validation_status, severity_level,
                            validation_message, expected_value, actual_value,
                            deviation_amount, validation_context,
                            resolution_status
                        ) VALUES (
                            company_rec.company_id, calculation_rec.calculation_id, v_statistical_rule_id,
                            'UNIT_FEE', v_unit_rec.unit_id, v_unit_rec.unit_number || '호 통계적 이상치',
                            'WARNING', 'WARNING',
                            '관리비가 통계적 이상치로 탐지되었습니다',
                            jsonb_build_object('avg', v_avg_amount, 'stddev', v_stddev_amount),
                            jsonb_build_object('value', v_unit_rec.total_amount),
                            v_unit_rec.total_amount - v_avg_amount,
                            jsonb_build_object(
                                'z_score', (v_unit_rec.total_amount - v_avg_amount) / v_stddev_amount,
                                'threshold', 2.5
                            ),
                            CASE WHEN random() < 0.5 THEN 'RESOLVED' ELSE 'PENDING' END
                        );
                        
                        validation_count := validation_count + 1;
                    END LOOP;
                END IF;
                
                -- 일부 검증 결과에 자동 수정 적용
                UPDATE bms.validation_results
                SET auto_fix_applied = true,
                    auto_fix_details = jsonb_build_object(
                        'action_type', 'ROUND_AMOUNT',
                        'applied_at', NOW() - (random() * 5 || ' days')::INTERVAL,
                        'success', true
                    ),
                    resolution_status = 'RESOLVED',
                    resolved_at = NOW() - (random() * 3 || ' days')::INTERVAL,
                    resolution_action = '자동 반올림 적용'
                WHERE company_id = company_rec.company_id
                  AND calculation_id = calculation_rec.calculation_id
                  AND rule_id = v_range_rule_id
                  AND random() < 0.4;  -- 40% 확률로 자동 수정
            END;
        END LOOP;
        
        RAISE NOTICE '회사 % 검증 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 관리비 검증 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 검증 규칙: %개', rule_count;
    RAISE NOTICE '생성된 이상치 탐지 설정: %개', anomaly_config_count;
    RAISE NOTICE '생성된 검증 결과: %개', validation_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 관리비 검증 시스템 테스트 데이터 생성이 완료되었습니다!' as result;