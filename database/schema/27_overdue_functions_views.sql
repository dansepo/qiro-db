-- =====================================================
-- 연체 관리 시스템 함수 및 뷰 생성 스크립트
-- Phase 5.2: 연체 관리 시스템 함수 및 뷰
-- =====================================================

-- 1. 연체료 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_late_fee(
    p_overdue_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    late_fee_amount DECIMAL(15,2),
    calculation_details JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_record RECORD;
    v_policy RECORD;
    v_days_overdue INTEGER;
    v_calculated_fee DECIMAL(15,2) := 0;
    v_details JSONB := '{}';
    v_daily_rate DECIMAL(8,4);
    v_base_amount DECIMAL(15,2);
BEGIN
    -- 연체 기록과 정책 정보 조회
    SELECT o.*, bi.total_amount
    INTO v_record
    FROM bms.overdue_records o
    JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
    WHERE o.overdue_id = p_overdue_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '연체 기록을 찾을 수 없습니다: %', p_overdue_id;
    END IF;
    
    -- 정책 정보 조회
    SELECT * INTO v_policy
    FROM bms.overdue_policies
    WHERE policy_id = v_record.policy_id;
    
    -- 연체 일수 계산
    v_days_overdue := p_calculation_date - v_record.overdue_start_date;
    
    -- 기준 금액 설정 (미납 금액 기준)
    v_base_amount := v_record.outstanding_amount;
    
    -- 연체료 계산 방법에 따른 처리
    CASE v_policy.late_fee_calculation_method
        WHEN 'DAILY_RATE' THEN
            -- 일일 요율 계산
            v_daily_rate := v_policy.daily_late_fee_rate / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'DAILY_RATE',
                'base_amount', v_base_amount,
                'daily_rate', v_policy.daily_late_fee_rate,
                'days_overdue', v_days_overdue,
                'calculation', format('%s × %s%% × %s일', v_base_amount, v_policy.daily_late_fee_rate, v_days_overdue)
            );
            
        WHEN 'MONTHLY_RATE' THEN
            -- 월별 요율 계산
            v_calculated_fee := v_base_amount * (v_policy.monthly_late_fee_rate / 100) * (v_days_overdue / 30.0);
            
            v_details := jsonb_build_object(
                'method', 'MONTHLY_RATE',
                'base_amount', v_base_amount,
                'monthly_rate', v_policy.monthly_late_fee_rate,
                'days_overdue', v_days_overdue,
                'months_overdue', ROUND(v_days_overdue / 30.0, 2),
                'calculation', format('%s × %s%% × %s개월', v_base_amount, v_policy.monthly_late_fee_rate, ROUND(v_days_overdue / 30.0, 2))
            );
            
        WHEN 'FIXED_AMOUNT' THEN
            -- 고정 금액
            v_calculated_fee := COALESCE(v_policy.fixed_late_fee_amount, 0);
            
            v_details := jsonb_build_object(
                'method', 'FIXED_AMOUNT',
                'fixed_amount', v_policy.fixed_late_fee_amount,
                'calculation', format('고정 연체료: %s원', v_policy.fixed_late_fee_amount)
            );
            
        WHEN 'TIERED_RATE' THEN
            -- 단계별 요율 (JSON 설정 기반)
            -- 여기서는 기본 일일 요율 적용
            v_daily_rate := v_policy.daily_late_fee_rate / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'TIERED_RATE',
                'base_amount', v_base_amount,
                'applied_rate', v_policy.daily_late_fee_rate,
                'days_overdue', v_days_overdue,
                'calculation', '단계별 요율 적용'
            );
            
        ELSE
            -- 기본값: 일일 요율
            v_daily_rate := COALESCE(v_policy.daily_late_fee_rate, 0.025) / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'DEFAULT_DAILY',
                'base_amount', v_base_amount,
                'daily_rate', COALESCE(v_policy.daily_late_fee_rate, 0.025),
                'days_overdue', v_days_overdue,
                'calculation', '기본 일일 요율 적용'
            );
    END CASE;
    
    -- 최대/최소 연체료 제한 적용
    IF v_policy.max_late_fee_amount IS NOT NULL THEN
        v_calculated_fee := LEAST(v_calculated_fee, v_policy.max_late_fee_amount);
    END IF;
    
    IF v_policy.max_late_fee_rate IS NOT NULL THEN
        v_calculated_fee := LEAST(v_calculated_fee, v_base_amount * v_policy.max_late_fee_rate / 100);
    END IF;
    
    v_calculated_fee := GREATEST(v_calculated_fee, COALESCE(v_policy.min_late_fee_amount, 0));
    
    -- 상세 정보에 제한 적용 내역 추가
    v_details := v_details || jsonb_build_object(
        'max_late_fee_amount', v_policy.max_late_fee_amount,
        'max_late_fee_rate', v_policy.max_late_fee_rate,
        'min_late_fee_amount', v_policy.min_late_fee_amount,
        'final_amount', v_calculated_fee,
        'calculation_date', p_calculation_date
    );
    
    RETURN QUERY SELECT v_calculated_fee, v_details;
END;
$$;

-- 2. 연체 현황 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_overdue_status(
    p_company_id UUID DEFAULT NULL,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    updated_count INTEGER,
    total_late_fee DECIMAL(15,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_record RECORD;
    v_late_fee_result RECORD;
    v_updated_count INTEGER := 0;
    v_total_late_fee DECIMAL(15,2) := 0;
    v_new_stage VARCHAR(20);
    v_policy RECORD;
BEGIN
    -- 활성 연체 기록들을 순회
    FOR v_record IN 
        SELECT o.*, op.overdue_threshold_days, op.legal_action_threshold_days
        FROM bms.overdue_records o
        JOIN bms.overdue_policies op ON o.policy_id = op.policy_id
        WHERE o.overdue_status = 'ACTIVE'
        AND (p_company_id IS NULL OR o.company_id = p_company_id)
    LOOP
        -- 연체 일수 업데이트
        UPDATE bms.overdue_records 
        SET overdue_days = p_calculation_date - overdue_start_date
        WHERE overdue_id = v_record.overdue_id;
        
        -- 연체료 계산
        SELECT * INTO v_late_fee_result
        FROM bms.calculate_late_fee(v_record.overdue_id, p_calculation_date);
        
        -- 연체 단계 결정
        v_new_stage := CASE 
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 7 THEN 'INITIAL'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 30 THEN 'WARNING'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 60 THEN 'DEMAND'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 90 THEN 'FINAL_NOTICE'
            WHEN v_record.legal_action_threshold_days IS NOT NULL 
                 AND (p_calculation_date - v_record.overdue_start_date) >= v_record.legal_action_threshold_days 
                 THEN 'LEGAL_ACTION'
            ELSE 'LEGAL_PREPARATION'
        END;
        
        -- 연체 기록 업데이트
        UPDATE bms.overdue_records 
        SET 
            overdue_days = p_calculation_date - overdue_start_date,
            overdue_stage = v_new_stage,
            late_fee_amount = v_late_fee_result.late_fee_amount,
            total_overdue_amount = outstanding_amount + v_late_fee_result.late_fee_amount,
            late_fee_calculation_date = p_calculation_date,
            late_fee_calculation_details = v_late_fee_result.calculation_details,
            updated_at = NOW()
        WHERE overdue_id = v_record.overdue_id;
        
        v_updated_count := v_updated_count + 1;
        v_total_late_fee := v_total_late_fee + v_late_fee_result.late_fee_amount;
    END LOOP;
    
    RETURN QUERY SELECT v_updated_count, v_total_late_fee;
END;
$$;

-- 3. 연체 알림 생성 함수
CREATE OR REPLACE FUNCTION bms.create_overdue_notification(
    p_overdue_id UUID,
    p_notification_type VARCHAR(20),
    p_notification_method VARCHAR(20),
    p_scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_notification_id UUID;
    v_overdue_record RECORD;
    v_unit_info RECORD;
    v_resident_info RECORD;
    v_title VARCHAR(200);
    v_content TEXT;
BEGIN
    -- 연체 기록 정보 조회
    SELECT o.*, EXTRACT(YEAR FROM bi.bill_period) as bill_year, EXTRACT(MONTH FROM bi.bill_period) as bill_month, bi.total_amount
    INTO v_overdue_record
    FROM bms.overdue_records o
    JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
    WHERE o.overdue_id = p_overdue_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '연체 기록을 찾을 수 없습니다: %', p_overdue_id;
    END IF;
    
    -- 세대 및 입주자 정보 조회
    SELECT u.unit_number, u.unit_type, b.building_name
    INTO v_unit_info
    FROM bms.bill_issuances bi
    JOIN bms.units u ON bi.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE bi.issuance_id = v_overdue_record.issuance_id;
    
    -- 입주자 정보는 임시로 기본값 설정 (residents 테이블이 없는 경우)
    v_resident_info.resident_name := '입주자';
    v_resident_info.phone_number := '010-0000-0000';
    v_resident_info.email := 'resident@example.com';
    v_resident_info.address := v_unit_info.building_name || ' ' || v_unit_info.unit_number || '호';
    
    -- 알림 제목 및 내용 생성
    v_title := CASE p_notification_type
        WHEN 'REMINDER' THEN format('[%s] 관리비 납부 안내', v_unit_info.building_name)
        WHEN 'WARNING' THEN format('[%s] 관리비 연체 경고', v_unit_info.building_name)
        WHEN 'DEMAND' THEN format('[%s] 관리비 납부 독촉', v_unit_info.building_name)
        WHEN 'FINAL_NOTICE' THEN format('[%s] 관리비 최종 납부 통지', v_unit_info.building_name)
        WHEN 'LEGAL_NOTICE' THEN format('[%s] 법적 조치 예고 통지', v_unit_info.building_name)
        ELSE format('[%s] 관리비 관련 안내', v_unit_info.building_name)
    END;
    
    v_content := format(
        E'안녕하세요. %s입니다.\n\n' ||
        E'%s호 %s년 %s월 관리비가 연체되었습니다.\n\n' ||
        E'연체 정보:\n' ||
        E'- 원금: %s원\n' ||
        E'- 연체료: %s원\n' ||
        E'- 총 연체금액: %s원\n' ||
        E'- 연체일수: %s일\n\n' ||
        E'빠른 시일 내에 납부해 주시기 바랍니다.',
        v_unit_info.building_name,
        v_unit_info.unit_number,
        v_overdue_record.bill_year,
        v_overdue_record.bill_month,
        v_overdue_record.outstanding_amount,
        v_overdue_record.late_fee_amount,
        v_overdue_record.total_overdue_amount,
        v_overdue_record.overdue_days
    );
    
    -- 알림 기록 생성
    INSERT INTO bms.overdue_notifications (
        overdue_id,
        company_id,
        notification_type,
        notification_stage,
        notification_method,
        notification_title,
        notification_content,
        recipient_name,
        recipient_contact,
        recipient_address,
        scheduled_at
    ) VALUES (
        p_overdue_id,
        v_overdue_record.company_id,
        p_notification_type,
        v_overdue_record.overdue_stage,
        p_notification_method,
        v_title,
        v_content,
        v_resident_info.resident_name,
        CASE p_notification_method
            WHEN 'EMAIL' THEN v_resident_info.email
            WHEN 'SMS' THEN v_resident_info.phone_number
            WHEN 'KAKAO_TALK' THEN v_resident_info.phone_number
            ELSE v_resident_info.address
        END,
        v_resident_info.address,
        p_scheduled_at
    ) RETURNING notification_id INTO v_notification_id;
    
    -- 연체 기록의 알림 정보 업데이트
    UPDATE bms.overdue_records 
    SET 
        notification_count = notification_count + 1,
        last_notification_date = CURRENT_DATE,
        next_notification_date = CURRENT_DATE + INTERVAL '7 days'
    WHERE overdue_id = p_overdue_id;
    
    RETURN v_notification_id;
END;
$$;

-- 4. 연체 관리 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_overdue_dashboard AS
SELECT 
    o.overdue_id,
    o.company_id,
    u.building_id,
    bi.unit_id,
    u.unit_number,
    u.unit_type,
    r.resident_name,
    
    -- 청구 정보
    EXTRACT(YEAR FROM bi.bill_period) as bill_year,
    EXTRACT(MONTH FROM bi.bill_period) as bill_month,
    bi.total_amount as original_amount,
    o.outstanding_amount,
    o.late_fee_amount,
    o.total_overdue_amount,
    
    -- 연체 정보
    o.overdue_status,
    o.overdue_stage,
    o.due_date,
    o.overdue_start_date,
    o.overdue_days,
    
    -- 정책 정보
    op.policy_name,
    op.daily_late_fee_rate,
    op.max_late_fee_rate,
    
    -- 알림 정보
    o.notification_count,
    o.last_notification_date,
    o.next_notification_date,
    
    -- 조치 정보
    o.warning_issued,
    o.legal_action_initiated,
    o.is_exempted,
    o.is_resolved,
    
    -- 계산된 필드
    CASE 
        WHEN o.overdue_days <= 30 THEN '1개월 이내'
        WHEN o.overdue_days <= 90 THEN '3개월 이내'
        WHEN o.overdue_days <= 180 THEN '6개월 이내'
        ELSE '6개월 초과'
    END as overdue_period_category,
    
    CASE 
        WHEN o.total_overdue_amount < 100000 THEN '10만원 미만'
        WHEN o.total_overdue_amount < 500000 THEN '50만원 미만'
        WHEN o.total_overdue_amount < 1000000 THEN '100만원 미만'
        ELSE '100만원 이상'
    END as amount_category,
    
    -- 우선순위 계산 (연체일수 * 금액 가중치)
    (o.overdue_days * 0.1 + o.total_overdue_amount / 10000) as priority_score
    
FROM bms.overdue_records o
JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
JOIN bms.units u ON bi.unit_id = u.unit_id
LEFT JOIN (SELECT unit_id, '입주자' as resident_name FROM bms.units LIMIT 0) r ON u.unit_id = r.unit_id
JOIN bms.overdue_policies op ON o.policy_id = op.policy_id
WHERE o.overdue_status = 'ACTIVE';

-- 5. 연체 통계 뷰
CREATE OR REPLACE VIEW bms.v_overdue_statistics AS
SELECT 
    company_id,
    
    -- 전체 통계
    COUNT(*) as total_overdue_count,
    SUM(total_overdue_amount) as total_overdue_amount,
    AVG(overdue_days) as avg_overdue_days,
    
    -- 상태별 통계
    COUNT(*) FILTER (WHERE overdue_status = 'ACTIVE') as active_count,
    COUNT(*) FILTER (WHERE overdue_status = 'RESOLVED') as resolved_count,
    COUNT(*) FILTER (WHERE overdue_status = 'EXEMPTED') as exempted_count,
    
    -- 단계별 통계
    COUNT(*) FILTER (WHERE overdue_stage = 'INITIAL') as initial_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'WARNING') as warning_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'DEMAND') as demand_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'FINAL_NOTICE') as final_notice_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'LEGAL_ACTION') as legal_action_count,
    
    -- 금액별 통계
    COUNT(*) FILTER (WHERE total_overdue_amount < 100000) as under_100k_count,
    COUNT(*) FILTER (WHERE total_overdue_amount BETWEEN 100000 AND 499999) as between_100k_500k_count,
    COUNT(*) FILTER (WHERE total_overdue_amount BETWEEN 500000 AND 999999) as between_500k_1m_count,
    COUNT(*) FILTER (WHERE total_overdue_amount >= 1000000) as over_1m_count,
    
    -- 기간별 통계
    COUNT(*) FILTER (WHERE overdue_days <= 30) as within_30days_count,
    COUNT(*) FILTER (WHERE overdue_days BETWEEN 31 AND 90) as between_31_90days_count,
    COUNT(*) FILTER (WHERE overdue_days BETWEEN 91 AND 180) as between_91_180days_count,
    COUNT(*) FILTER (WHERE overdue_days > 180) as over_180days_count,
    
    -- 금액 통계
    SUM(outstanding_amount) as total_outstanding_amount,
    SUM(late_fee_amount) as total_late_fee_amount,
    
    -- 최신 업데이트 시간
    MAX(updated_at) as last_updated_at
    
FROM bms.overdue_records
GROUP BY company_id;

-- 6. 코멘트 추가
COMMENT ON TABLE bms.overdue_policies IS '연체 정책 설정 테이블 - 회사별/건물별 연체 관리 정책을 정의';
COMMENT ON TABLE bms.overdue_records IS '연체 현황 테이블 - 개별 청구서의 연체 상태와 연체료를 관리';
COMMENT ON TABLE bms.overdue_notifications IS '연체 알림 이력 테이블 - 연체자에게 발송된 알림 내역을 기록';
COMMENT ON TABLE bms.overdue_actions IS '연체 조치 이력 테이블 - 연체에 대한 각종 조치 활동을 기록';

COMMENT ON COLUMN bms.overdue_policies.late_fee_calculation_method IS '연체료 계산 방법: DAILY_RATE(일일요율), MONTHLY_RATE(월별요율), FIXED_AMOUNT(고정금액), TIERED_RATE(단계별요율), COMPOUND_RATE(복리요율)';
COMMENT ON COLUMN bms.overdue_policies.stage_configurations IS '단계별 설정 JSON: 각 연체 단계별 세부 설정 정보';
COMMENT ON COLUMN bms.overdue_policies.exemption_conditions IS '면제 조건 JSON: 연체료 면제 조건 및 기준';

COMMENT ON COLUMN bms.overdue_records.overdue_stage IS '연체 단계: INITIAL(초기), WARNING(경고), DEMAND(독촉), FINAL_NOTICE(최종통지), LEGAL_PREPARATION(법적조치준비), LEGAL_ACTION(법적조치)';
COMMENT ON COLUMN bms.overdue_records.late_fee_calculation_details IS '연체료 계산 상세 JSON: 연체료 계산 과정과 적용된 요율 정보';

COMMENT ON FUNCTION bms.calculate_late_fee(UUID, DATE) IS '연체료 계산 함수 - 연체 정책에 따라 연체료를 계산하고 상세 내역을 반환';
COMMENT ON FUNCTION bms.update_overdue_status(UUID, DATE) IS '연체 현황 업데이트 함수 - 연체 일수, 단계, 연체료를 일괄 업데이트';
COMMENT ON FUNCTION bms.create_overdue_notification(UUID, VARCHAR, VARCHAR, TIMESTAMP WITH TIME ZONE) IS '연체 알림 생성 함수 - 연체자에게 발송할 알림을 생성';

COMMENT ON VIEW bms.v_overdue_dashboard IS '연체 관리 대시보드 뷰 - 연체 현황을 종합적으로 조회';
COMMENT ON VIEW bms.v_overdue_statistics IS '연체 통계 뷰 - 회사별 연체 현황 통계 정보';

-- 스크립트 완료 메시지
SELECT '연체 관리 시스템 함수 및 뷰 생성이 완료되었습니다.' as message;