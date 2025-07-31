-- =====================================================
-- 계약 관리 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    tenant_rec RECORD;
    lessor_rec RECORD;
    contract_count INTEGER := 0;
    contract_types TEXT[] := ARRAY['LEASE', 'SUBLEASE', 'RENEWAL'];
    payment_methods TEXT[] := ARRAY['계좌이체', '현금', '수표', '온라인송금', '자동이체'];
    purposes TEXT[] := ARRAY['사무용', '상업용', '창고용', '주거용', '기타'];
    termination_reasons TEXT[] := ARRAY[
        '계약만료', '임차인 요청', '임대인 요청', '임대료 연체', '계약위반', '건물 재개발'
    ];
    random_idx INTEGER;
    contract_number_seq INTEGER := 1;
BEGIN
    -- 활성 입주자들에 대해 계약 생성
    FOR tenant_rec IN 
        SELECT t.tenant_id, t.company_id, t.building_id, t.unit_id, t.tenant_name,
               t.deposit_amount, t.monthly_rent, t.lease_start_date, t.lease_end_date,
               t.move_in_date, t.tenant_status
        FROM bms.tenants t
        WHERE t.building_id IS NOT NULL AND t.unit_id IS NOT NULL
        ORDER BY t.created_at
        LIMIT 30  -- 30개 계약만 생성
    LOOP
        -- 해당 건물의 임대인 찾기
        SELECT l.lessor_id, l.lessor_name INTO lessor_rec
        FROM bms.lessors l
        JOIN bms.lessor_building_assignments lba ON l.lessor_id = lba.lessor_id
        WHERE lba.building_id = tenant_rec.building_id
          AND lba.company_id = tenant_rec.company_id
          AND (lba.ownership_end_date IS NULL OR lba.ownership_end_date > CURRENT_DATE)
        LIMIT 1;
        
        -- 임대인이 있는 경우에만 계약 생성
        IF lessor_rec.lessor_id IS NOT NULL THEN
            random_idx := (RANDOM() * (array_length(contract_types, 1) - 1))::INTEGER + 1;
            
            INSERT INTO bms.lease_contracts (
                company_id, building_id, unit_id, lessor_id, tenant_id,
                contract_number, contract_type, contract_status,
                contract_start_date, contract_end_date,
                deposit_amount, monthly_rent, maintenance_fee, key_money,
                rent_payment_day, payment_method, late_fee_rate, grace_period_days,
                purpose_of_use, subletting_allowed, renovation_allowed, pet_allowed, smoking_allowed,
                special_terms, lessor_obligations, tenant_obligations,
                contract_signed_date, lessor_signature, tenant_signature,
                auto_renewal, renewal_notice_days, renewal_count,
                termination_date, termination_reason
            ) VALUES (
                tenant_rec.company_id,
                tenant_rec.building_id,
                tenant_rec.unit_id,
                lessor_rec.lessor_id,
                tenant_rec.tenant_id,
                'C' || LPAD(contract_number_seq::TEXT, 6, '0'),  -- C000001, C000002, ...
                contract_types[random_idx],
                CASE 
                    WHEN tenant_rec.tenant_status = 'ACTIVE' THEN 'ACTIVE'
                    WHEN tenant_rec.tenant_status = 'MOVED_OUT' THEN 'EXPIRED'
                    ELSE 'EXPIRED'
                END,
                COALESCE(tenant_rec.lease_start_date, tenant_rec.move_in_date, CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER),
                COALESCE(tenant_rec.lease_end_date, 
                    COALESCE(tenant_rec.lease_start_date, tenant_rec.move_in_date, CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER) + 
                    (RANDOM() * 365 * 2 + 365)::INTEGER),
                COALESCE(tenant_rec.deposit_amount, (RANDOM() * 50000000 + 10000000)::DECIMAL(15,2)),
                COALESCE(tenant_rec.monthly_rent, (RANDOM() * 2000000 + 500000)::DECIMAL(12,2)),
                (RANDOM() * 200000 + 50000)::DECIMAL(10,2),  -- 관리비 5-25만원
                CASE WHEN RANDOM() < 0.3 THEN (RANDOM() * 10000000 + 1000000)::DECIMAL(15,2) ELSE 0 END, -- 30% 확률로 권리금
                (RANDOM() * 28 + 1)::INTEGER,  -- 1-28일
                payment_methods[(RANDOM() * (array_length(payment_methods, 1) - 1))::INTEGER + 1],
                (RANDOM() * 20 + 5)::DECIMAL(5,2),  -- 5-25% 연체료율
                (RANDOM() * 10 + 3)::INTEGER,  -- 3-12일 유예기간
                purposes[(RANDOM() * (array_length(purposes, 1) - 1))::INTEGER + 1],
                RANDOM() < 0.2,  -- 20% 확률로 전대 허용
                RANDOM() < 0.3,  -- 30% 확률로 개조 허용
                RANDOM() < 0.1,  -- 10% 확률로 반려동물 허용
                RANDOM() < 0.1,  -- 10% 확률로 흡연 허용
                CASE WHEN RANDOM() < 0.4 THEN '특약사항: 계약 조건에 따른 추가 사항' ELSE NULL END,
                '임대인은 건물의 유지보수 및 관리에 책임을 진다.',
                '임차인은 건물을 선량한 관리자의 주의로 사용하여야 한다.',
                CASE 
                    WHEN tenant_rec.tenant_status = 'ACTIVE' THEN 
                        COALESCE(tenant_rec.lease_start_date, tenant_rec.move_in_date, CURRENT_DATE - (RANDOM() * 365)::INTEGER)
                    ELSE CURRENT_DATE - (RANDOM() * 365 * 3)::INTEGER
                END,
                true,  -- 임대인 서명 완료
                true,  -- 임차인 서명 완료
                RANDOM() < 0.6,  -- 60% 확률로 자동 갱신
                (RANDOM() * 60 + 30)::INTEGER,  -- 30-90일 갱신 통지 기간
                CASE WHEN contract_types[random_idx] = 'RENEWAL' THEN (RANDOM() * 3)::INTEGER ELSE 0 END,
                NULL, -- termination_date
                NULL  -- termination_reason
            );
            
            contract_count := contract_count + 1;
            contract_number_seq := contract_number_seq + 1;
        END IF;
    END LOOP;
    
    -- 일부 계약을 만료 상태로 변경
    UPDATE bms.lease_contracts 
    SET contract_status = 'EXPIRED'
    WHERE contract_status = 'ACTIVE' 
      AND contract_end_date < CURRENT_DATE;
    
    -- 일부 계약을 해지 상태로 변경 (해지 사유와 함께)
    UPDATE bms.lease_contracts 
    SET contract_status = 'TERMINATED',
        termination_date = CURRENT_DATE - (RANDOM() * 180)::INTEGER,
        termination_reason = termination_reasons[(RANDOM() * (array_length(termination_reasons, 1) - 1))::INTEGER + 1]
    WHERE contract_id IN (
        SELECT contract_id 
        FROM bms.lease_contracts 
        WHERE contract_status = 'EXPIRED'
        ORDER BY RANDOM() 
        LIMIT 3
    );
    
    -- 일부 활성 계약의 만료일을 가까운 미래로 설정 (만료 예정 테스트용)
    UPDATE bms.lease_contracts 
    SET contract_end_date = CURRENT_DATE + (RANDOM() * 60 + 10)::INTEGER
    WHERE contract_status = 'ACTIVE' 
      AND contract_id IN (
          SELECT contract_id 
          FROM bms.lease_contracts 
          WHERE contract_status = 'ACTIVE'
          ORDER BY RANDOM() 
          LIMIT 5
      );
    
    RAISE NOTICE '총 % 개의 테스트 계약이 생성되었습니다.', contract_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.lease_contracts;

-- 데이터 검증 및 결과 출력
SELECT 
    '계약 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_contracts,
    COUNT(CASE WHEN contract_status = 'ACTIVE' THEN 1 END) as active_contracts,
    COUNT(CASE WHEN contract_status = 'EXPIRED' THEN 1 END) as expired_contracts,
    COUNT(CASE WHEN contract_status = 'TERMINATED' THEN 1 END) as terminated_contracts,
    COUNT(CASE WHEN auto_renewal = true THEN 1 END) as auto_renewal_contracts,
    ROUND(AVG(monthly_rent), 0) as avg_monthly_rent,
    ROUND(AVG(deposit_amount), 0) as avg_deposit
FROM bms.lease_contracts;

-- 계약 타입별 통계
SELECT 
    '계약 타입별 현황' as info,
    contract_type,
    COUNT(*) as count,
    COUNT(CASE WHEN contract_status = 'ACTIVE' THEN 1 END) as active_count,
    ROUND(AVG(monthly_rent), 0) as avg_rent,
    ROUND(AVG(deposit_amount), 0) as avg_deposit
FROM bms.lease_contracts
GROUP BY contract_type
ORDER BY count DESC;

-- 계약 상태별 통계
SELECT 
    '계약 상태별 현황' as info,
    contract_status,
    COUNT(*) as count,
    ROUND(AVG(contract_duration_months), 1) as avg_duration_months,
    COUNT(CASE WHEN auto_renewal = true THEN 1 END) as auto_renewal_count
FROM bms.lease_contracts
GROUP BY contract_status
ORDER BY count DESC;

-- 계약 만료 예정 뷰 테스트
SELECT 
    '계약 만료 예정' as info,
    building_name,
    unit_number,
    tenant_name,
    contract_end_date,
    expiration_urgency,
    days_until_expiration
FROM bms.v_contract_expiration_schedule
WHERE expiration_urgency IN ('EXPIRED', 'EXPIRING_THIS_WEEK', 'EXPIRING_THIS_MONTH')
ORDER BY contract_end_date
LIMIT 10;

-- 임대료 수납 일정 뷰 테스트
SELECT 
    '임대료 수납 일정' as info,
    rent_payment_day,
    payment_period,
    COUNT(*) as contract_count,
    ROUND(SUM(monthly_rent), 0) as total_monthly_rent
FROM bms.v_rent_payment_schedule
GROUP BY rent_payment_day, payment_period
ORDER BY rent_payment_day
LIMIT 10;

-- 완료 메시지
SELECT '✅ 계약 테스트 데이터 생성이 완료되었습니다!' as result;