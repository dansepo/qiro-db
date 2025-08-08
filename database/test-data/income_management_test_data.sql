-- 수입 관리 시스템 테스트 데이터
-- 기본 수입 유형, 연체료 정책, 정기 수입 스케줄 등을 생성

-- 테스트용 회사 ID (기존 companies 테이블에서 가져오기)
DO $$
DECLARE
    test_company_id UUID;
    test_user_id UUID;
    maintenance_fee_type_id UUID;
    rent_type_id UUID;
    parking_fee_type_id UUID;
    maintenance_policy_id UUID;
    rent_policy_id UUID;
    test_building_id UUID;
    test_unit_id UUID;
    test_tenant_id UUID;
    test_contract_id UUID;
    test_lessor_id UUID;
    test_income_record_id UUID;
    test_receivable_id UUID;
BEGIN
    -- 테스트 회사 ID 조회 (첫 번째 회사 사용)
    SELECT company_id INTO test_company_id 
    FROM bms.companies 
    WHERE verification_status = 'VERIFIED' 
    LIMIT 1;
    
    IF test_company_id IS NULL THEN
        -- 테스트 회사가 없으면 생성
        test_company_id := gen_random_uuid();
        INSERT INTO bms.companies (
            company_id, company_name, business_registration_number, 
            representative_name, verification_status, subscription_status,
            created_by, updated_by
        ) VALUES (
            test_company_id, '테스트 관리회사', '123-45-67890', 
            '테스트 대표', 'VERIFIED', 'ACTIVE',
            test_user_id, test_user_id
        );
    END IF;
    
    -- 테스트 사용자 ID 설정
    test_user_id := '00000000-0000-0000-0000-000000000001'::UUID;
    
    -- 기본 수입 유형 생성
    -- 1. 관리비
    maintenance_fee_type_id := gen_random_uuid();
    INSERT INTO bms.income_types (
        income_type_id, company_id, type_code, type_name, description, 
        is_recurring, is_active
    ) VALUES (
        maintenance_fee_type_id, test_company_id, 'MAINTENANCE_FEE', '관리비', 
        '월별 관리비 수입', true, true
    );
    
    -- 2. 임대료
    rent_type_id := gen_random_uuid();
    INSERT INTO bms.income_types (
        income_type_id, company_id, type_code, type_name, description, 
        is_recurring, is_active
    ) VALUES (
        rent_type_id, test_company_id, 'RENT', '임대료', 
        '월별 임대료 수입', true, true
    );
    
    -- 3. 주차비
    parking_fee_type_id := gen_random_uuid();
    INSERT INTO bms.income_types (
        income_type_id, company_id, type_code, type_name, description, 
        is_recurring, is_active
    ) VALUES (
        parking_fee_type_id, test_company_id, 'PARKING_FEE', '주차비', 
        '월별 주차비 수입', true, true
    );
    
    -- 4. 기타 수입 유형들
    INSERT INTO bms.income_types (
        income_type_id, company_id, type_code, type_name, description, 
        is_recurring, is_active
    ) VALUES 
    (gen_random_uuid(), test_company_id, 'DEPOSIT', '보증금', '임대 보증금', false, true),
    (gen_random_uuid(), test_company_id, 'UTILITY_FEE', '공과금', '전기, 가스, 수도 요금', false, true),
    (gen_random_uuid(), test_company_id, 'LATE_FEE', '연체료', '납부 지연에 따른 연체료', false, true),
    (gen_random_uuid(), test_company_id, 'OTHER', '기타', '기타 수입', false, true);
    
    -- 연체료 정책 생성
    -- 1. 관리비 연체료 정책 (월 2% 비율)
    maintenance_policy_id := gen_random_uuid();
    INSERT INTO bms.late_fee_policies (
        policy_id, company_id, income_type_id, policy_name, 
        grace_period_days, late_fee_type, late_fee_rate, max_late_fee,
        compound_interest, is_active, effective_from
    ) VALUES (
        maintenance_policy_id, test_company_id, maintenance_fee_type_id, '관리비 연체료 정책',
        5, 'PERCENTAGE', 2.0000, 100000.00,
        false, true, CURRENT_DATE - INTERVAL '1 year'
    );
    
    -- 2. 임대료 연체료 정책 (일할 0.1% 비율)
    rent_policy_id := gen_random_uuid();
    INSERT INTO bms.late_fee_policies (
        policy_id, company_id, income_type_id, policy_name, 
        grace_period_days, late_fee_type, late_fee_rate, max_late_fee,
        compound_interest, is_active, effective_from
    ) VALUES (
        rent_policy_id, test_company_id, rent_type_id, '임대료 연체료 정책',
        3, 'DAILY_RATE', 0.1000, 500000.00,
        false, true, CURRENT_DATE - INTERVAL '1 year'
    );
    
    -- 3. 주차비 연체료 정책 (고정 금액)
    INSERT INTO bms.late_fee_policies (
        policy_id, company_id, income_type_id, policy_name, 
        grace_period_days, late_fee_type, fixed_late_fee,
        compound_interest, is_active, effective_from
    ) VALUES (
        gen_random_uuid(), test_company_id, parking_fee_type_id, '주차비 연체료 정책',
        7, 'FIXED', 10000.00,
        false, true, CURRENT_DATE - INTERVAL '1 year'
    );
    
    -- 테스트용 건물, 세대, 임차인, 계약 데이터 생성 (기존 데이터가 없는 경우)
    SELECT building_id INTO test_building_id FROM bms.buildings WHERE company_id = test_company_id LIMIT 1;
    IF test_building_id IS NULL THEN
        test_building_id := gen_random_uuid();
        INSERT INTO bms.buildings (
            building_id, company_id, name, address, building_type, 
            total_floors, total_units, status, created_by, updated_by
        ) VALUES (
            test_building_id, test_company_id, '테스트 빌딩', '서울시 강남구 테스트로 123', 'RESIDENTIAL',
            10, 100, 'ACTIVE', test_user_id, test_user_id
        );
    END IF;
    
    SELECT unit_id INTO test_unit_id FROM bms.units WHERE building_id = test_building_id LIMIT 1;
    IF test_unit_id IS NULL THEN
        test_unit_id := gen_random_uuid();
        INSERT INTO bms.units (
            unit_id, building_id, company_id, unit_number, floor_number, unit_type, 
            exclusive_area, unit_status, created_by, updated_by
        ) VALUES (
            test_unit_id, test_building_id, test_company_id, '101호', 1, 'APARTMENT', 
            84.5, 'VACANT', test_user_id, test_user_id
        );
    END IF;
    
    SELECT tenant_id INTO test_tenant_id FROM bms.tenants WHERE company_id = test_company_id LIMIT 1;
    IF test_tenant_id IS NULL THEN
        test_tenant_id := gen_random_uuid();
        INSERT INTO bms.tenants (
            tenant_id, company_id, tenant_name, primary_phone, email, 
            created_by, updated_by
        ) VALUES (
            test_tenant_id, test_company_id, '김테스트', '010-1234-5678', 'test@example.com', 
            test_user_id, test_user_id
        );
    END IF;
    
    -- 테스트 임대인 생성
    SELECT lessor_id INTO test_lessor_id FROM bms.lessors WHERE company_id = test_company_id LIMIT 1;
    IF test_lessor_id IS NULL THEN
        test_lessor_id := gen_random_uuid();
        INSERT INTO bms.lessors (
            lessor_id, company_id, lessor_name, primary_phone, email,
            created_by, updated_by
        ) VALUES (
            test_lessor_id, test_company_id, '박임대인', '010-9876-5432', 'lessor@example.com',
            test_user_id, test_user_id
        );
    END IF;
    
    SELECT contract_id INTO test_contract_id FROM bms.lease_contracts WHERE unit_id = test_unit_id LIMIT 1;
    IF test_contract_id IS NULL THEN
        test_contract_id := gen_random_uuid();
        INSERT INTO bms.lease_contracts (
            contract_id, company_id, building_id, unit_id, lessor_id, tenant_id, 
            contract_number, contract_start_date, contract_end_date, monthly_rent, deposit_amount, 
            contract_status, created_by, updated_by
        ) VALUES (
            test_contract_id, test_company_id, test_building_id, test_unit_id, test_lessor_id, test_tenant_id,
            'CONTRACT-001', CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '6 months', 
            1000000.00, 10000000.00, 'ACTIVE', test_user_id, test_user_id
        );
    END IF;
    
    -- 정기 수입 스케줄 생성
    -- 1. 관리비 월별 스케줄
    INSERT INTO bms.recurring_income_schedules (
        schedule_id, company_id, income_type_id, building_id, unit_id, 
        contract_id, tenant_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, maintenance_fee_type_id, test_building_id, test_unit_id,
        test_contract_id, test_tenant_id, '101호 관리비', 'MONTHLY', 1,
        150000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', true
    );
    
    -- 2. 임대료 월별 스케줄
    INSERT INTO bms.recurring_income_schedules (
        schedule_id, company_id, income_type_id, building_id, unit_id, 
        contract_id, tenant_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, rent_type_id, test_building_id, test_unit_id,
        test_contract_id, test_tenant_id, '101호 임대료', 'MONTHLY', 1,
        1000000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', true
    );
    
    -- 3. 주차비 월별 스케줄
    INSERT INTO bms.recurring_income_schedules (
        schedule_id, company_id, income_type_id, building_id, unit_id, 
        contract_id, tenant_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, parking_fee_type_id, test_building_id, test_unit_id,
        test_contract_id, test_tenant_id, '101호 주차비', 'MONTHLY', 1,
        50000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', true
    );
    
    -- 테스트 수입 기록 생성
    -- 1. 확정된 관리비 수입 (지난달)
    test_income_record_id := gen_random_uuid();
    INSERT INTO bms.income_records (
        income_record_id, company_id, income_type_id, building_id, unit_id,
        contract_id, tenant_id, income_date, due_date, amount, total_amount,
        description, status, created_by
    ) VALUES (
        test_income_record_id, test_company_id, maintenance_fee_type_id, test_building_id, test_unit_id,
        test_contract_id, test_tenant_id, CURRENT_DATE - INTERVAL '1 month', 
        CURRENT_DATE - INTERVAL '1 month' + INTERVAL '30 days', 150000.00, 150000.00,
        '101호 관리비 - ' || TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM'), 
        'CONFIRMED', test_user_id
    );
    
    -- 2. 대기중인 임대료 수입 (이번달)
    INSERT INTO bms.income_records (
        income_record_id, company_id, income_type_id, building_id, unit_id,
        contract_id, tenant_id, income_date, due_date, amount, total_amount,
        description, status, created_by
    ) VALUES (
        gen_random_uuid(), test_company_id, rent_type_id, test_building_id, test_unit_id,
        test_contract_id, test_tenant_id, CURRENT_DATE, 
        CURRENT_DATE + INTERVAL '30 days', 1000000.00, 1000000.00,
        '101호 임대료 - ' || TO_CHAR(CURRENT_DATE, 'YYYY-MM'), 
        'PENDING', test_user_id
    );
    
    -- 테스트 미수금 생성
    -- 1. 연체된 관리비 미수금
    test_receivable_id := gen_random_uuid();
    INSERT INTO bms.receivables (
        receivable_id, company_id, income_record_id, building_id, unit_id, tenant_id,
        original_amount, outstanding_amount, overdue_days, late_fee_amount, 
        total_outstanding, due_date, status
    ) VALUES (
        test_receivable_id, test_company_id, test_income_record_id, test_building_id, test_unit_id, test_tenant_id,
        150000.00, 150000.00, 15, 3000.00, 
        153000.00, CURRENT_DATE - INTERVAL '15 days', 'OUTSTANDING'
    );
    
    -- 2. 정상 임대료 미수금
    INSERT INTO bms.receivables (
        receivable_id, company_id, income_record_id, building_id, unit_id, tenant_id,
        original_amount, outstanding_amount, overdue_days, late_fee_amount, 
        total_outstanding, due_date, status
    ) VALUES (
        gen_random_uuid(), test_company_id, 
        (SELECT income_record_id FROM bms.income_records WHERE description LIKE '%임대료%' LIMIT 1),
        test_building_id, test_unit_id, test_tenant_id,
        1000000.00, 1000000.00, 0, 0.00, 
        1000000.00, CURRENT_DATE + INTERVAL '15 days', 'OUTSTANDING'
    );
    
    -- 테스트 결제 기록 생성
    -- 1. 부분 결제 기록
    INSERT INTO bms.payment_records (
        payment_record_id, company_id, receivable_id, income_record_id,
        payment_date, payment_amount, late_fee_paid, total_paid,
        payment_method, notes, created_by
    ) VALUES (
        gen_random_uuid(), test_company_id, test_receivable_id, test_income_record_id,
        CURRENT_DATE - INTERVAL '5 days', 100000.00, 0.00, 100000.00,
        'BANK_TRANSFER', '부분 결제', test_user_id
    );
    
    RAISE NOTICE '수입 관리 시스템 테스트 데이터 생성 완료';
    RAISE NOTICE '- 회사 ID: %', test_company_id;
    RAISE NOTICE '- 수입 유형: 7개';
    RAISE NOTICE '- 연체료 정책: 3개';
    RAISE NOTICE '- 정기 수입 스케줄: 3개';
    RAISE NOTICE '- 수입 기록: 2개';
    RAISE NOTICE '- 미수금: 2개';
    RAISE NOTICE '- 결제 기록: 1개';
    
END $$;