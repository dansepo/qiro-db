-- =====================================================
-- 관리비 검증 시스템 함수 개발 스크립트
-- Phase 3.3: 관리비 검증 함수들
-- =====================================================

-- 1. 관리비 검증 실행 함수
CREATE OR REPLACE FUNCTION bms.execute_fee_validation(
    p_calculation_id UUID,
    p_execution_type VARCHAR(20) DEFAULT 'MANUAL',
    p_executed_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_execution_id UUID;
    v_company_id UUID;
    v_rule_rec RECORD;
    v_total_rules INTEGER := 0;
    v_executed_rules INTEGER := 0;
    v_passed_count INTEGER := 0;
    v_warning_count INTEGER := 0;
    v_error_count INTEGER := 0;
    v_critical_count INTEGER := 0;
    v_start_time TIMESTAMP WITH TIME ZONE := NOW();
BEGIN
    -- 계산 정보 조회
    SELECT company_id INTO v_company_id
    FROM bms.monthly_fee_calculations
    WHERE calculation_id = p_calculation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계산 정보를 찾을 수 없습니다: %', p_calculation_id;
    END IF;
    
    -- 실행 이력 생성
    v_execution_id := gen_random_uuid();
    
    INSERT INTO bms.validation_execution_history (
        execution_id, company_id, calculation_id,
        execution_type, execution_trigger, execution_status,
        execution_start_time, executed_by
    ) VALUES (
        v_execution_id, v_company_id, p_calculation_id,
        p_execution_type, 'USER_REQUEST', 'RUNNING',
        v_start_time, p_executed_by
    );
    
    -- 활성화된 검증 규칙 조회 및 실행
    FOR v_rule_rec IN 
        SELECT rule_id, rule_name, rule_category, rule_type, 
               validation_condition, threshold_values, severity_level
        FROM bms.validation_rules
        WHERE company_id = v_company_id
          AND is_active = true
          AND (effective_start_date <= CURRENT_DATE)
          AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
        ORDER BY priority_order, rule_name
    LOOP
        v_total_rules := v_total_rules + 1;
        
        BEGIN
            -- 규칙별 검증 실행
            PERFORM bms.execute_single_validation_rule(
                p_calculation_id, 
                v_rule_rec.rule_id,
                v_execution_id
            );
            
            v_executed_rules := v_executed_rules + 1;
            
        EXCEPTION WHEN OTHERS THEN
            -- 개별 규칙 실행 오류는 로그만 남기고 계속 진행
            RAISE NOTICE '검증 규칙 실행 오류: % - %', v_rule_rec.rule_name, SQLERRM;
        END;
    END LOOP;
    
    -- 실행 결과 집계
    SELECT 
        COUNT(CASE WHEN validation_status = 'PASSED' THEN 1 END),
        COUNT(CASE WHEN validation_status = 'WARNING' THEN 1 END),
        COUNT(CASE WHEN severity_level = 'ERROR' THEN 1 END),
        COUNT(CASE WHEN severity_level = 'CRITICAL' THEN 1 END)
    INTO v_passed_count, v_warning_count, v_error_count, v_critical_count
    FROM bms.validation_results
    WHERE calculation_id = p_calculation_id
      AND created_at >= v_start_time;
    
    -- 실행 이력 업데이트
    UPDATE bms.validation_execution_history
    SET execution_status = 'COMPLETED',
        execution_end_time = NOW(),
        execution_duration_ms = EXTRACT(EPOCH FROM (NOW() - v_start_time)) * 1000,
        total_rules_count = v_total_rules,
        executed_rules_count = v_executed_rules,
        passed_count = v_passed_count,
        warning_count = v_warning_count,
        error_count = v_error_count,
        critical_count = v_critical_count,
        execution_summary = jsonb_build_object(
            'total_rules', v_total_rules,
            'executed_rules', v_executed_rules,
            'success_rate', CASE WHEN v_executed_rules > 0 THEN v_passed_count::DECIMAL / v_executed_rules ELSE 0 END,
            'completion_time', NOW()
        )
    WHERE execution_id = v_execution_id;
    
    RETURN v_execution_id;
END;
$$ LANGUAGE plpgsql;

-- 2. 개별 검증 규칙 실행 함수
CREATE OR REPLACE FUNCTION bms.execute_single_validation_rule(
    p_calculation_id UUID,
    p_rule_id UUID,
    p_execution_id UUID DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_rule_rec RECORD;
    v_calculation_rec RECORD;
    v_result_count INTEGER := 0;
    v_condition JSONB;
    v_threshold JSONB;
BEGIN
    -- 규칙 정보 조회
    SELECT * INTO v_rule_rec
    FROM bms.validation_rules
    WHERE rule_id = p_rule_id AND is_active = true;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- 계산 정보 조회
    SELECT * INTO v_calculation_rec
    FROM bms.monthly_fee_calculations
    WHERE calculation_id = p_calculation_id;
    
    v_condition := v_rule_rec.validation_condition;
    v_threshold := v_rule_rec.threshold_values;
    
    -- 규칙 유형별 검증 실행
    CASE v_rule_rec.rule_type
        WHEN 'RANGE_CHECK' THEN
            v_result_count := bms.validate_range_check(p_calculation_id, p_rule_id, v_condition, v_threshold);
        WHEN 'COMPARISON' THEN
            v_result_count := bms.validate_comparison(p_calculation_id, p_rule_id, v_condition, v_threshold);
        WHEN 'FORMULA_VALIDATION' THEN
            v_result_count := bms.validate_formula(p_calculation_id, p_rule_id, v_condition, v_threshold);
        WHEN 'STATISTICAL' THEN
            v_result_count := bms.validate_statistical(p_calculation_id, p_rule_id, v_condition, v_threshold);
        ELSE
            -- 기본 검증
            v_result_count := bms.validate_basic_check(p_calculation_id, p_rule_id, v_condition, v_threshold);
    END CASE;
    
    RETURN v_result_count;
END;
$$ LANGUAGE plpgsql;

-- 3. 범위 검사 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_range_check(
    p_calculation_id UUID,
    p_rule_id UUID,
    p_condition JSONB,
    p_threshold JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_unit_rec RECORD;
    v_result_count INTEGER := 0;
    v_min_value DECIMAL(15,2);
    v_max_value DECIMAL(15,2);
    v_field_name TEXT;
    v_field_value DECIMAL(15,2);
BEGIN
    v_field_name := p_condition->>'field_name';
    v_min_value := (p_threshold->>'min_value')::DECIMAL(15,2);
    v_max_value := (p_threshold->>'max_value')::DECIMAL(15,2);
    
    -- 각 호실별 관리비 검증
    FOR v_unit_rec IN 
        SELECT umf.*, u.unit_number
        FROM bms.unit_monthly_fees umf
        JOIN bms.units u ON umf.unit_id = u.unit_id
        WHERE umf.calculation_id = p_calculation_id
    LOOP
        -- 필드값 추출
        CASE v_field_name
            WHEN 'total_amount' THEN v_field_value := v_unit_rec.total_amount;
            WHEN 'common_management_fee' THEN v_field_value := v_unit_rec.common_management_fee;
            WHEN 'electricity_fee' THEN v_field_value := v_unit_rec.electricity_fee;
            WHEN 'water_fee' THEN v_field_value := v_unit_rec.water_fee;
            ELSE v_field_value := 0;
        END CASE;
        
        -- 범위 검사
        IF v_field_value < v_min_value OR v_field_value > v_max_value THEN
            INSERT INTO bms.validation_results (
                company_id, calculation_id, rule_id,
                target_type, target_id, target_description,
                validation_status, severity_level,
                validation_message, expected_value, actual_value,
                deviation_amount
            ) VALUES (
                (SELECT company_id FROM bms.monthly_fee_calculations WHERE calculation_id = p_calculation_id),
                p_calculation_id, p_rule_id,
                'UNIT_FEE', v_unit_rec.unit_id, v_unit_rec.unit_number || '호 ' || v_field_name,
                'FAILED', (SELECT severity_level FROM bms.validation_rules WHERE rule_id = p_rule_id),
                v_field_name || ' 값이 허용 범위를 벗어났습니다',
                jsonb_build_object('min', v_min_value, 'max', v_max_value),
                jsonb_build_object('value', v_field_value),
                CASE 
                    WHEN v_field_value < v_min_value THEN v_field_value - v_min_value
                    ELSE v_field_value - v_max_value
                END
            );
            
            v_result_count := v_result_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_result_count;
END;
$$ LANGUAGE plpgsql;

-- 4. 비교 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_comparison(
    p_calculation_id UUID,
    p_rule_id UUID,
    p_condition JSONB,
    p_threshold JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_calculation_rec RECORD;
    v_result_count INTEGER := 0;
    v_calculated_total DECIMAL(15,2);
    v_header_total DECIMAL(15,2);
    v_tolerance DECIMAL(15,2);
BEGIN
    -- 계산 정보 조회
    SELECT * INTO v_calculation_rec
    FROM bms.monthly_fee_calculations
    WHERE calculation_id = p_calculation_id;
    
    v_tolerance := COALESCE((p_threshold->>'tolerance')::DECIMAL(15,2), 1.0);
    
    -- 호실별 합계와 헤더 총액 비교
    SELECT SUM(total_amount) INTO v_calculated_total
    FROM bms.unit_monthly_fees
    WHERE calculation_id = p_calculation_id;
    
    v_header_total := v_calculation_rec.total_amount;
    
    IF ABS(v_calculated_total - v_header_total) > v_tolerance THEN
        INSERT INTO bms.validation_results (
            company_id, calculation_id, rule_id,
            target_type, target_id, target_description,
            validation_status, severity_level,
            validation_message, expected_value, actual_value,
            deviation_amount, deviation_percentage
        ) VALUES (
            v_calculation_rec.company_id, p_calculation_id, p_rule_id,
            'TOTAL_AMOUNT', NULL, '총액 일치성 검증',
            'FAILED', (SELECT severity_level FROM bms.validation_rules WHERE rule_id = p_rule_id),
            '헤더 총액과 호실별 합계가 일치하지 않습니다',
            jsonb_build_object('header_total', v_header_total),
            jsonb_build_object('calculated_total', v_calculated_total),
            v_calculated_total - v_header_total,
            CASE WHEN v_header_total > 0 THEN (v_calculated_total - v_header_total) / v_header_total * 100 ELSE 0 END
        );
        
        v_result_count := 1;
    END IF;
    
    RETURN v_result_count;
END;
$$ LANGUAGE plpgsql;

-- 5. 통계적 검증 함수 (이상치 탐지)
CREATE OR REPLACE FUNCTION bms.validate_statistical(
    p_calculation_id UUID,
    p_rule_id UUID,
    p_condition JSONB,
    p_threshold JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_unit_rec RECORD;
    v_result_count INTEGER := 0;
    v_field_name TEXT;
    v_field_value DECIMAL(15,2);
    v_avg_value DECIMAL(15,2);
    v_stddev_value DECIMAL(15,2);
    v_z_score DECIMAL(10,4);
    v_z_threshold DECIMAL(10,4);
BEGIN
    v_field_name := p_condition->>'field_name';
    v_z_threshold := COALESCE((p_threshold->>'z_threshold')::DECIMAL(10,4), 2.0);
    
    -- 평균과 표준편차 계산
    EXECUTE format('
        SELECT AVG(%I), STDDEV(%I)
        FROM bms.unit_monthly_fees
        WHERE calculation_id = $1
    ', v_field_name, v_field_name)
    INTO v_avg_value, v_stddev_value
    USING p_calculation_id;
    
    -- 표준편차가 0이면 검증 건너뜀
    IF v_stddev_value IS NULL OR v_stddev_value = 0 THEN
        RETURN 0;
    END IF;
    
    -- 각 호실별 Z-점수 계산 및 이상치 탐지
    FOR v_unit_rec IN 
        EXECUTE format('
            SELECT umf.unit_id, umf.%I as field_value, u.unit_number
            FROM bms.unit_monthly_fees umf
            JOIN bms.units u ON umf.unit_id = u.unit_id
            WHERE umf.calculation_id = $1
        ', v_field_name)
        USING p_calculation_id
    LOOP
        v_field_value := v_unit_rec.field_value;
        v_z_score := (v_field_value - v_avg_value) / v_stddev_value;
        
        -- 이상치 탐지 (Z-점수 기준)
        IF ABS(v_z_score) > v_z_threshold THEN
            INSERT INTO bms.validation_results (
                company_id, calculation_id, rule_id,
                target_type, target_id, target_description,
                validation_status, severity_level,
                validation_message, expected_value, actual_value,
                deviation_amount, validation_context
            ) VALUES (
                (SELECT company_id FROM bms.monthly_fee_calculations WHERE calculation_id = p_calculation_id),
                p_calculation_id, p_rule_id,
                'UNIT_FEE', v_unit_rec.unit_id, v_unit_rec.unit_number || '호 ' || v_field_name || ' 이상치',
                'WARNING', 'WARNING',
                v_field_name || ' 값이 통계적 이상치로 탐지되었습니다',
                jsonb_build_object('avg', v_avg_value, 'stddev', v_stddev_value),
                jsonb_build_object('value', v_field_value, 'z_score', v_z_score),
                v_field_value - v_avg_value,
                jsonb_build_object(
                    'z_score', v_z_score,
                    'z_threshold', v_z_threshold,
                    'avg_value', v_avg_value,
                    'stddev_value', v_stddev_value
                )
            );
            
            v_result_count := v_result_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_result_count;
END;
$$ LANGUAGE plpgsql;

-- 6. 기본 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_basic_check(
    p_calculation_id UUID,
    p_rule_id UUID,
    p_condition JSONB,
    p_threshold JSONB
)
RETURNS INTEGER AS $$
DECLARE
    v_result_count INTEGER := 0;
BEGIN
    -- 기본적인 데이터 무결성 검증
    
    -- 음수 금액 검증
    INSERT INTO bms.validation_results (
        company_id, calculation_id, rule_id,
        target_type, target_id, target_description,
        validation_status, severity_level,
        validation_message, actual_value
    )
    SELECT 
        (SELECT company_id FROM bms.monthly_fee_calculations WHERE calculation_id = p_calculation_id),
        p_calculation_id, p_rule_id,
        'UNIT_FEE', umf.unit_id, u.unit_number || '호 음수 금액',
        'FAILED', 'ERROR',
        '관리비에 음수 금액이 포함되어 있습니다',
        jsonb_build_object('total_amount', umf.total_amount)
    FROM bms.unit_monthly_fees umf
    JOIN bms.units u ON umf.unit_id = u.unit_id
    WHERE umf.calculation_id = p_calculation_id
      AND umf.total_amount < 0;
    
    GET DIAGNOSTICS v_result_count = ROW_COUNT;
    
    RETURN v_result_count;
END;
$$ LANGUAGE plpgsql;

-- 7. 자동 수정 함수
CREATE OR REPLACE FUNCTION bms.apply_auto_fix(
    p_result_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_result_rec RECORD;
    v_rule_rec RECORD;
    v_auto_fix_action JSONB;
    v_success BOOLEAN := false;
BEGIN
    -- 검증 결과 조회
    SELECT * INTO v_result_rec
    FROM bms.validation_results
    WHERE result_id = p_result_id
      AND resolution_status = 'PENDING';
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- 규칙 정보 조회
    SELECT * INTO v_rule_rec
    FROM bms.validation_rules
    WHERE rule_id = v_result_rec.rule_id
      AND auto_fix_enabled = true;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    v_auto_fix_action := v_rule_rec.auto_fix_action;
    
    -- 자동 수정 액션 실행
    CASE v_auto_fix_action->>'action_type'
        WHEN 'ROUND_AMOUNT' THEN
            -- 금액 반올림
            UPDATE bms.unit_monthly_fees
            SET total_amount = ROUND(total_amount / 10) * 10,
                adjustment_amount = ROUND(total_amount / 10) * 10 - total_amount,
                adjustment_reason = '자동 반올림 적용'
            WHERE unit_id = v_result_rec.target_id;
            
            v_success := true;
            
        WHEN 'SET_DEFAULT_VALUE' THEN
            -- 기본값 설정
            DECLARE
                v_default_value DECIMAL(15,2) := (v_auto_fix_action->>'default_value')::DECIMAL(15,2);
            BEGIN
                UPDATE bms.unit_monthly_fees
                SET total_amount = v_default_value,
                    adjustment_amount = v_default_value - total_amount,
                    adjustment_reason = '자동 기본값 적용'
                WHERE unit_id = v_result_rec.target_id;
                
                v_success := true;
            END;
    END CASE;
    
    -- 자동 수정 결과 업데이트
    IF v_success THEN
        UPDATE bms.validation_results
        SET auto_fix_applied = true,
            auto_fix_details = jsonb_build_object(
                'action_type', v_auto_fix_action->>'action_type',
                'applied_at', NOW(),
                'success', true
            ),
            resolution_status = 'RESOLVED',
            resolved_at = NOW(),
            resolution_action = '자동 수정 적용'
        WHERE result_id = p_result_id;
    END IF;
    
    RETURN v_success;
END;
$$ LANGUAGE plpgsql;

-- 8. 검증 대시보드 요약 함수
CREATE OR REPLACE FUNCTION bms.get_validation_summary(
    p_company_id UUID,
    p_period_days INTEGER DEFAULT 30
)
RETURNS TABLE(
    total_validations INTEGER,
    passed_count INTEGER,
    failed_count INTEGER,
    warning_count INTEGER,
    pending_issues INTEGER,
    auto_fixed_count INTEGER,
    success_rate DECIMAL(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_validations,
        COUNT(CASE WHEN vr.validation_status = 'PASSED' THEN 1 END)::INTEGER as passed_count,
        COUNT(CASE WHEN vr.validation_status = 'FAILED' THEN 1 END)::INTEGER as failed_count,
        COUNT(CASE WHEN vr.validation_status = 'WARNING' THEN 1 END)::INTEGER as warning_count,
        COUNT(CASE WHEN vr.resolution_status = 'PENDING' THEN 1 END)::INTEGER as pending_issues,
        COUNT(CASE WHEN vr.auto_fix_applied = true THEN 1 END)::INTEGER as auto_fixed_count,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND(COUNT(CASE WHEN vr.validation_status = 'PASSED' THEN 1 END)::DECIMAL / COUNT(*) * 100, 2)
            ELSE 0
        END as success_rate
    FROM bms.validation_results vr
    WHERE vr.company_id = p_company_id
      AND vr.created_at >= CURRENT_DATE - (p_period_days || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- 함수 권한 설정
GRANT EXECUTE ON FUNCTION bms.execute_fee_validation TO application_role;
GRANT EXECUTE ON FUNCTION bms.execute_single_validation_rule TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_range_check TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_comparison TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_statistical TO application_role;
GRANT EXECUTE ON FUNCTION bms.validate_basic_check TO application_role;
GRANT EXECUTE ON FUNCTION bms.apply_auto_fix TO application_role;
GRANT EXECUTE ON FUNCTION bms.get_validation_summary TO application_role;

-- 완료 메시지
SELECT '✅ 관리비 검증 시스템 함수 개발이 완료되었습니다!' as result;