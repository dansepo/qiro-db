-- =====================================================
-- 관리비 정책 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    unit_rec RECORD;
    policy_count INTEGER := 0;
    template_count INTEGER := 0;
    override_count INTEGER := 0;
BEGIN
    -- 각 회사에 대해 관리비 정책 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 관리비 정책 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 회사 기본 정책 생성
        INSERT INTO bms.maintenance_fee_policies (
            company_id, building_id, policy_name, policy_description, policy_type,
            billing_cycle, billing_day, payment_due_days, grace_period_days,
            late_fee_enabled, late_fee_rate, late_fee_calculation_method,
            late_fee_min_amount, late_fee_max_amount,
            early_payment_discount_enabled, early_payment_discount_rate, early_payment_discount_days,
            partial_payment_allowed, partial_payment_allocation_method, minimum_payment_ratio,
            advance_payment_allowed, advance_payment_max_months, advance_payment_discount_rate,
            auto_billing_enabled, auto_late_fee_enabled, auto_reminder_enabled,
            reminder_schedule, notification_methods
        ) VALUES 
        -- 표준 주거용 정책
        (company_rec.company_id, NULL, '표준 주거용 정책', '일반 주거용 건물에 적용되는 기본 관리비 정책', 'STANDARD',
         'MONTHLY', 1, 30, 5,
         true, 2.5, 'SIMPLE_INTEREST',
         1000, 100000,
         true, 1.0, 10,
         true, 'PRINCIPAL_FIRST', 30.0,
         true, 12, 0.5,
         true, true, true,
         '{"before_due": [7, 3, 1], "after_due": [1, 7, 14, 30]}',
         ARRAY['EMAIL', 'SMS', 'APP_PUSH']),
        
        -- 프리미엄 정책
        (company_rec.company_id, NULL, '프리미엄 정책', '고급 주거용 건물에 적용되는 프리미엄 정책', 'PREMIUM',
         'MONTHLY', 1, 45, 10,
         true, 2.0, 'SIMPLE_INTEREST',
         2000, 200000,
         true, 2.0, 15,
         true, 'PRINCIPAL_FIRST', 20.0,
         true, 24, 1.0,
         true, true, true,
         '{"before_due": [10, 5, 1], "after_due": [1, 5, 10, 20]}',
         ARRAY['EMAIL', 'SMS', 'APP_PUSH', 'MAIL']),
        
        -- 상업용 정책
        (company_rec.company_id, NULL, '상업용 정책', '상업용 건물에 적용되는 관리비 정책', 'COMMERCIAL',
         'MONTHLY', 5, 20, 3,
         true, 3.0, 'COMPOUND_INTEREST',
         5000, 500000,
         false, NULL, NULL,
         true, 'INTEREST_FIRST', 50.0,
         true, 6, 0.0,
         true, true, true,
         '{"before_due": [5, 2], "after_due": [1, 3, 7]}',
         ARRAY['EMAIL', 'FAX']);
        
        policy_count := policy_count + 3;
        
        -- 2. 건물별 개별 정책 생성 (일부 건물에 대해)
        FOR building_rec IN 
            SELECT building_id, name as building_name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            -- 50% 확률로 건물별 개별 정책 생성
            IF random() < 0.5 THEN
                RAISE NOTICE '  건물 % 개별 정책 생성', building_rec.building_name;
                
                INSERT INTO bms.maintenance_fee_policies (
                    company_id, building_id, policy_name, policy_description, policy_type,
                    billing_cycle, billing_day, payment_due_days, grace_period_days,
                    late_fee_enabled, late_fee_rate, late_fee_calculation_method,
                    late_fee_min_amount, late_fee_max_amount,
                    early_payment_discount_enabled, early_payment_discount_rate, early_payment_discount_days,
                    partial_payment_allowed, partial_payment_allocation_method,
                    auto_billing_enabled, auto_late_fee_enabled, auto_reminder_enabled,
                    notification_methods
                ) VALUES 
                (company_rec.company_id, building_rec.building_id, 
                 building_rec.building_name || ' 전용 정책', 
                 building_rec.building_name || '에 적용되는 개별 관리비 정책', 
                 'CUSTOM',
                 'MONTHLY', 
                 (ARRAY[1, 5, 10, 15])[ceil(random() * 4)],  -- 랜덤 부과일
                 (ARRAY[25, 30, 35])[ceil(random() * 3)],    -- 랜덤 납부기한
                 (ARRAY[3, 5, 7])[ceil(random() * 3)],       -- 랜덤 유예기간
                 true, 
                 2.0 + random() * 1.5,  -- 2.0~3.5% 연체료율
                 'SIMPLE_INTEREST',
                 1000, 150000,
                 random() < 0.7,  -- 70% 확률로 조기납부할인 적용
                 CASE WHEN random() < 0.7 THEN 1.0 + random() * 1.0 ELSE NULL END,  -- 1.0~2.0% 할인율
                 CASE WHEN random() < 0.7 THEN (ARRAY[7, 10, 14])[ceil(random() * 3)] ELSE NULL END,
                 true, 'PRINCIPAL_FIRST',
                 true, true, true,
                 ARRAY['EMAIL', 'SMS']);
                
                policy_count := policy_count + 1;
            END IF;
        END LOOP;
        
        -- 3. 정책 템플릿 생성
        INSERT INTO bms.fee_policy_templates (
            company_id, template_name, template_description, template_category,
            policy_config, applicable_building_types, applicable_unit_types
        ) VALUES 
        (company_rec.company_id, '기본 주거용 템플릿', '일반적인 주거용 건물에 사용할 수 있는 기본 템플릿', 'RESIDENTIAL',
         '{"billing_cycle": "MONTHLY", "billing_day": 1, "payment_due_days": 30, "late_fee_rate": 2.5, "grace_period_days": 5}',
         ARRAY['APARTMENT', 'VILLA', 'TOWNHOUSE'],
         ARRAY['RESIDENTIAL']),
        
        (company_rec.company_id, '상업용 템플릿', '상업용 건물에 사용할 수 있는 템플릿', 'COMMERCIAL',
         '{"billing_cycle": "MONTHLY", "billing_day": 5, "payment_due_days": 20, "late_fee_rate": 3.0, "grace_period_days": 3}',
         ARRAY['OFFICE', 'RETAIL', 'MIXED'],
         ARRAY['COMMERCIAL', 'OFFICE']),
        
        (company_rec.company_id, '사회적 배려 템플릿', '사회적 배려 대상자를 위한 템플릿', 'SOCIAL',
         '{"billing_cycle": "MONTHLY", "billing_day": 1, "payment_due_days": 45, "late_fee_rate": 1.5, "grace_period_days": 10, "exemption_enabled": true}',
         ARRAY['APARTMENT', 'VILLA'],
         ARRAY['RESIDENTIAL']);
        
        template_count := template_count + 3;
        
        -- 4. 호실별 개별 설정 생성 (일부 호실에 대해)
        FOR unit_rec IN 
            SELECT u.unit_id, u.unit_number, b.name as building_name
            FROM bms.units u
            JOIN bms.buildings b ON u.building_id = b.building_id
            WHERE b.company_id = company_rec.company_id
            LIMIT 5  -- 각 회사당 5개 호실만
        LOOP
            -- 30% 확률로 호실별 개별 설정 생성
            IF random() < 0.3 THEN
                RAISE NOTICE '  호실 %-%% 개별 설정 생성', unit_rec.building_name, unit_rec.unit_number;
                
                INSERT INTO bms.unit_fee_policy_overrides (
                    unit_id, policy_id, company_id,
                    custom_billing_day, custom_payment_due_days, custom_late_fee_rate,
                    exemption_reason, exemption_percentage,
                    approved_by, approved_at, approval_reason
                ) VALUES 
                (unit_rec.unit_id,
                 (SELECT policy_id FROM bms.maintenance_fee_policies WHERE company_id = company_rec.company_id AND building_id IS NULL LIMIT 1),
                 company_rec.company_id,
                 CASE WHEN random() < 0.3 THEN (ARRAY[5, 10, 15])[ceil(random() * 3)] ELSE NULL END,
                 CASE WHEN random() < 0.3 THEN (ARRAY[35, 40, 45])[ceil(random() * 3)] ELSE NULL END,
                 CASE WHEN random() < 0.3 THEN 1.5 + random() * 1.0 ELSE NULL END,
                 CASE WHEN random() < 0.5 THEN (ARRAY['기초생활수급자', '장애인 할인', '다자녀 가정 할인', '경로우대 할인'])[ceil(random() * 4)] ELSE NULL END,
                 CASE WHEN random() < 0.5 THEN 5.0 + random() * 15.0 ELSE NULL END,  -- 5~20% 감면
                 (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                 NOW() - (random() * 30 || ' days')::INTERVAL,
                 '특별 사유에 의한 개별 설정 승인');
                
                override_count := override_count + 1;
            END IF;
        END LOOP;
        
        -- 5. 정책 변경 이력 생성 (시뮬레이션)
        INSERT INTO bms.fee_policy_change_history (
            policy_id, company_id, change_type, changed_fields, old_values, new_values,
            change_reason, change_description, requested_by, approved_by, approved_at,
            scheduled_effective_date, actual_effective_date
        )
        SELECT 
            mfp.policy_id,
            company_rec.company_id,
            'UPDATE',
            '{"late_fee_rate": true}',
            '{"late_fee_rate": ' || (mfp.late_fee_rate - 0.5) || '}',
            '{"late_fee_rate": ' || mfp.late_fee_rate || '}',
            '연체료율 조정',
            '시장 상황을 반영한 연체료율 조정',
            (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
            (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
            NOW() - (random() * 60 || ' days')::INTERVAL,
            CURRENT_DATE - (random() * 30)::INTEGER,
            CURRENT_DATE - (random() * 30)::INTEGER
        FROM bms.maintenance_fee_policies mfp
        WHERE mfp.company_id = company_rec.company_id
          AND random() < 0.5  -- 50% 확률로 이력 생성
        LIMIT 2;
        
        RAISE NOTICE '회사 % 관리비 정책 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 관리비 정책 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 정책 수: %', policy_count;
    RAISE NOTICE '총 템플릿 수: %', template_count;
    RAISE NOTICE '총 개별 설정 수: %', override_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 관리비 정책 현황
SELECT 
    '관리비 정책' as category,
    c.company_name,
    COALESCE(b.name, '전체') as building_name,
    mfp.policy_name,
    mfp.policy_type,
    mfp.billing_cycle,
    mfp.billing_day,
    mfp.payment_due_days,
    mfp.late_fee_rate,
    mfp.early_payment_discount_rate
FROM bms.maintenance_fee_policies mfp
JOIN bms.companies c ON mfp.company_id = c.company_id
LEFT JOIN bms.buildings b ON mfp.building_id = b.building_id
WHERE mfp.is_active = true
ORDER BY c.company_name, b.name NULLS FIRST, mfp.policy_name;

-- 2. 정책 템플릿 현황
SELECT 
    '정책 템플릿' as category,
    c.company_name,
    fpt.template_name,
    fpt.template_category,
    fpt.applicable_building_types,
    fpt.applicable_unit_types,
    fpt.usage_count
FROM bms.fee_policy_templates fpt
JOIN bms.companies c ON fpt.company_id = c.company_id
WHERE fpt.is_active = true
ORDER BY c.company_name, fpt.template_name;

-- 3. 호실별 개별 설정 현황
SELECT 
    '호실별 설정' as category,
    c.company_name,
    b.name as building_name,
    u.unit_number,
    mfp.policy_name,
    upo.custom_billing_day,
    upo.custom_payment_due_days,
    upo.custom_late_fee_rate,
    upo.exemption_reason,
    upo.exemption_percentage
FROM bms.unit_fee_policy_overrides upo
JOIN bms.units u ON upo.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
JOIN bms.companies c ON upo.company_id = c.company_id
JOIN bms.maintenance_fee_policies mfp ON upo.policy_id = mfp.policy_id
WHERE upo.is_active = true
ORDER BY c.company_name, b.name, u.unit_number;

-- 4. 정책 변경 이력
SELECT 
    '정책 변경 이력' as category,
    c.company_name,
    mfp.policy_name,
    fpch.change_type,
    fpch.change_reason,
    fpch.scheduled_effective_date,
    fpch.actual_effective_date,
    fpch.created_at
FROM bms.fee_policy_change_history fpch
JOIN bms.maintenance_fee_policies mfp ON fpch.policy_id = mfp.policy_id
JOIN bms.companies c ON fpch.company_id = c.company_id
ORDER BY c.company_name, fpch.created_at DESC;

-- 5. 활성 정책 뷰 테스트
SELECT 
    '활성 정책 뷰' as category,
    company_name,
    building_name,
    policy_name,
    policy_type,
    billing_cycle,
    late_fee_rate,
    early_payment_discount_rate
FROM bms.v_active_fee_policies
ORDER BY company_name, building_name NULLS FIRST
LIMIT 10;

-- 6. 함수 테스트 - 유효한 정책 조회
SELECT 
    '정책 조회 함수' as category,
    policy_name,
    billing_cycle,
    billing_day,
    payment_due_days,
    late_fee_rate
FROM bms.get_effective_fee_policy(
    (SELECT building_id FROM bms.buildings LIMIT 1),
    NULL,
    CURRENT_DATE
);

-- 7. 함수 테스트 - 연체료 계산
SELECT 
    '연체료 계산 함수' as category,
    '100000원 30일 연체 (2.5% 단리)' as scenario,
    bms.calculate_late_fee(100000, 30, 2.5, 'SIMPLE_INTEREST') as late_fee

UNION ALL

SELECT 
    '연체료 계산 함수' as category,
    '50000원 45일 연체 (3.0% 복리)' as scenario,
    bms.calculate_late_fee(50000, 45, 3.0, 'COMPOUND_INTEREST') as late_fee

UNION ALL

SELECT 
    '연체료 계산 함수' as category,
    '200000원 60일 연체 (2.0% 단리)' as scenario,
    bms.calculate_late_fee(200000, 60, 2.0, 'SIMPLE_INTEREST') as late_fee;

-- 완료 메시지
SELECT '✅ 관리비 정책 테스트 데이터 생성이 완료되었습니다!' as result;