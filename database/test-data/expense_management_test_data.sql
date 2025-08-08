-- 지출 관리 시스템 테스트 데이터
-- 기본 지출 유형, 업체, 정기 지출 스케줄 등을 생성

DO $$
DECLARE
    test_company_id UUID;
    test_user_id UUID;
    maintenance_type_id UUID;
    utility_type_id UUID;
    management_type_id UUID;
    facility_type_id UUID;
    test_vendor1_id UUID;
    test_vendor2_id UUID;
    test_vendor3_id UUID;
    test_building_id UUID;
    test_unit_id UUID;
    test_expense_record_id UUID;
BEGIN
    -- 테스트 회사 ID 조회 (기존 수입 관리 시스템에서 생성된 회사 사용)
    SELECT company_id INTO test_company_id 
    FROM bms.companies 
    WHERE verification_status = 'VERIFIED' 
    LIMIT 1;
    
    IF test_company_id IS NULL THEN
        RAISE EXCEPTION '테스트 회사가 존재하지 않습니다. 먼저 수입 관리 시스템 테스트 데이터를 생성하세요.';
    END IF;
    
    -- 테스트 사용자 ID 설정
    test_user_id := '00000000-0000-0000-0000-000000000001'::UUID;
    
    -- 기본 지출 유형 생성
    -- 1. 유지보수비
    maintenance_type_id := gen_random_uuid();
    INSERT INTO bms.expense_types (
        expense_type_id, company_id, type_code, type_name, description, 
        category, is_recurring, requires_approval, approval_limit, is_active
    ) VALUES (
        maintenance_type_id, test_company_id, 'MAINTENANCE_COST', '유지보수비', 
        '시설 유지보수 관련 비용', 'MAINTENANCE', true, true, 1000000.00, true
    );
    
    -- 2. 공과금
    utility_type_id := gen_random_uuid();
    INSERT INTO bms.expense_types (
        expense_type_id, company_id, type_code, type_name, description, 
        category, is_recurring, requires_approval, approval_limit, is_active
    ) VALUES (
        utility_type_id, test_company_id, 'UTILITY_BILL', '공과금', 
        '전기, 가스, 수도 요금', 'UTILITIES', true, true, 500000.00, true
    );
    
    -- 3. 관리비
    management_type_id := gen_random_uuid();
    INSERT INTO bms.expense_types (
        expense_type_id, company_id, type_code, type_name, description, 
        category, is_recurring, requires_approval, approval_limit, is_active
    ) VALUES (
        management_type_id, test_company_id, 'MANAGEMENT_FEE', '관리비', 
        '건물 관리 운영비', 'MANAGEMENT', true, true, 2000000.00, true
    );
    
    -- 4. 시설수리비
    facility_type_id := gen_random_uuid();
    INSERT INTO bms.expense_types (
        expense_type_id, company_id, type_code, type_name, description, 
        category, is_recurring, requires_approval, approval_limit, is_active
    ) VALUES (
        facility_type_id, test_company_id, 'FACILITY_REPAIR', '시설수리비', 
        '시설 수리 및 교체 비용', 'FACILITY', false, true, 3000000.00, true
    );
    
    -- 5. 기타 지출 유형들
    INSERT INTO bms.expense_types (
        expense_type_id, company_id, type_code, type_name, description, 
        category, is_recurring, requires_approval, approval_limit, is_active
    ) VALUES 
    (gen_random_uuid(), test_company_id, 'CLEANING_COST', '청소비', '청소 서비스 비용', 'MANAGEMENT', true, true, 300000.00, true),
    (gen_random_uuid(), test_company_id, 'SECURITY_COST', '경비비', '경비 서비스 비용', 'MANAGEMENT', true, true, 500000.00, true),
    (gen_random_uuid(), test_company_id, 'INSURANCE_PREMIUM', '보험료', '건물 보험료', 'ADMINISTRATIVE', false, true, 1000000.00, true),
    (gen_random_uuid(), test_company_id, 'OFFICE_SUPPLIES', '사무용품비', '사무용품 구매비', 'ADMINISTRATIVE', false, false, 100000.00, true);
    
    -- 업체 정보 생성
    -- 1. 유지보수 업체
    test_vendor1_id := gen_random_uuid();
    INSERT INTO bms.vendors (
        vendor_id, company_id, vendor_code, vendor_name, business_number,
        contact_person, phone_number, email, address,
        bank_account, bank_name, account_holder, vendor_type, payment_terms, is_active
    ) VALUES (
        test_vendor1_id, test_company_id, 'V001', '(주)한국유지보수', '123-45-67890',
        '김유지', '02-1234-5678', 'maintenance@example.com', '서울시 강남구 테헤란로 123',
        '123-456-789012', '국민은행', '(주)한국유지보수', 'MAINTENANCE', 30, true
    );
    
    -- 2. 공과금 업체 (한국전력공사)
    test_vendor2_id := gen_random_uuid();
    INSERT INTO bms.vendors (
        vendor_id, company_id, vendor_code, vendor_name, business_number,
        contact_person, phone_number, email, address,
        bank_account, bank_name, account_holder, vendor_type, payment_terms, is_active
    ) VALUES (
        test_vendor2_id, test_company_id, 'V002', '한국전력공사', '123-45-67891',
        '박전력', '02-2345-6789', 'power@kepco.co.kr', '서울시 서초구 전력로 456',
        '234-567-890123', '우리은행', '한국전력공사', 'UTILITY', 15, true
    );
    
    -- 3. 청소 업체
    test_vendor3_id := gen_random_uuid();
    INSERT INTO bms.vendors (
        vendor_id, company_id, vendor_code, vendor_name, business_number,
        contact_person, phone_number, email, address,
        bank_account, bank_name, account_holder, vendor_type, payment_terms, is_active
    ) VALUES (
        test_vendor3_id, test_company_id, 'V003', '깨끗한청소', '123-45-67892',
        '이청소', '02-3456-7890', 'clean@example.com', '서울시 마포구 청소로 789',
        '345-678-901234', '신한은행', '깨끗한청소', 'CLEANING', 20, true
    );
    
    -- 기존 건물, 세대 정보 조회
    SELECT building_id INTO test_building_id FROM bms.buildings WHERE company_id = test_company_id LIMIT 1;
    SELECT unit_id INTO test_unit_id FROM bms.units WHERE building_id = test_building_id LIMIT 1;
    
    -- 정기 지출 스케줄 생성
    -- 1. 유지보수비 월별 스케줄
    INSERT INTO bms.recurring_expense_schedules (
        schedule_id, company_id, expense_type_id, building_id, unit_id, 
        vendor_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, auto_approve, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, maintenance_type_id, test_building_id, null,
        test_vendor1_id, '건물 정기 유지보수', 'MONTHLY', 1,
        800000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', false, true
    );
    
    -- 2. 공과금 월별 스케줄
    INSERT INTO bms.recurring_expense_schedules (
        schedule_id, company_id, expense_type_id, building_id, unit_id, 
        vendor_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, auto_approve, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, utility_type_id, test_building_id, null,
        test_vendor2_id, '전기요금', 'MONTHLY', 1,
        450000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', true, true
    );
    
    -- 3. 청소비 월별 스케줄
    INSERT INTO bms.recurring_expense_schedules (
        schedule_id, company_id, expense_type_id, building_id, unit_id, 
        vendor_id, schedule_name, frequency, interval_value,
        amount, start_date, next_generation_date, auto_approve, is_active
    ) VALUES (
        gen_random_uuid(), test_company_id, 
        (SELECT expense_type_id FROM bms.expense_types WHERE company_id = test_company_id AND type_code = 'CLEANING_COST'),
        test_building_id, null, test_vendor3_id, '건물 청소', 'MONTHLY', 1,
        250000.00, CURRENT_DATE - INTERVAL '6 months', CURRENT_DATE + INTERVAL '1 month', true, true
    );
    
    -- 테스트 지출 기록 생성
    -- 1. 승인된 유지보수비 지출 (지난달)
    test_expense_record_id := gen_random_uuid();
    INSERT INTO bms.expense_records (
        expense_record_id, company_id, expense_type_id, building_id, unit_id,
        vendor_id, expense_date, due_date, amount, total_amount,
        description, status, approval_status, approved_by, approved_at, created_by
    ) VALUES (
        test_expense_record_id, test_company_id, maintenance_type_id, test_building_id, null,
        test_vendor1_id, CURRENT_DATE - INTERVAL '1 month', 
        CURRENT_DATE - INTERVAL '1 month' + INTERVAL '30 days', 800000.00, 800000.00,
        '엘리베이터 정기점검 - ' || TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM'), 
        'APPROVED', 'APPROVED', test_user_id, CURRENT_TIMESTAMP - INTERVAL '25 days', test_user_id
    );
    
    -- 2. 승인 대기 중인 시설수리비 지출 (이번달)
    INSERT INTO bms.expense_records (
        expense_record_id, company_id, expense_type_id, building_id, unit_id,
        vendor_id, expense_date, due_date, amount, total_amount,
        description, status, approval_status, created_by
    ) VALUES (
        gen_random_uuid(), test_company_id, facility_type_id, test_building_id, null,
        test_vendor1_id, CURRENT_DATE, 
        CURRENT_DATE + INTERVAL '30 days', 1500000.00, 1500000.00,
        '옥상 방수공사', 'PENDING', 'PENDING', test_user_id
    );
    
    -- 3. 자동 승인된 공과금 지출 (이번달)
    INSERT INTO bms.expense_records (
        expense_record_id, company_id, expense_type_id, building_id, unit_id,
        vendor_id, expense_date, due_date, amount, total_amount,
        description, status, approval_status, approved_by, approved_at, created_by
    ) VALUES (
        gen_random_uuid(), test_company_id, utility_type_id, test_building_id, null,
        test_vendor2_id, CURRENT_DATE, 
        CURRENT_DATE + INTERVAL '15 days', 450000.00, 450000.00,
        '전기요금 - ' || TO_CHAR(CURRENT_DATE, 'YYYY-MM'), 
        'APPROVED', 'APPROVED', '00000000-0000-0000-0000-000000000000'::UUID, CURRENT_TIMESTAMP, '00000000-0000-0000-0000-000000000000'::UUID
    );
    
    -- 4. 지급 완료된 청소비 지출 (지난달)
    INSERT INTO bms.expense_records (
        expense_record_id, company_id, expense_type_id, building_id, unit_id,
        vendor_id, expense_date, due_date, amount, total_amount,
        description, status, approval_status, approved_by, approved_at, paid_at, created_by
    ) VALUES (
        gen_random_uuid(), test_company_id, 
        (SELECT expense_type_id FROM bms.expense_types WHERE company_id = test_company_id AND type_code = 'CLEANING_COST'),
        test_building_id, null, test_vendor3_id, CURRENT_DATE - INTERVAL '1 month', 
        CURRENT_DATE - INTERVAL '1 month' + INTERVAL '20 days', 250000.00, 250000.00,
        '건물 청소 - ' || TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'YYYY-MM'), 
        'PAID', 'APPROVED', '00000000-0000-0000-0000-000000000000'::UUID, 
        CURRENT_TIMESTAMP - INTERVAL '25 days', CURRENT_TIMESTAMP - INTERVAL '20 days', '00000000-0000-0000-0000-000000000000'::UUID
    );
    
    RAISE NOTICE '지출 관리 시스템 테스트 데이터 생성 완료';
    RAISE NOTICE '- 회사 ID: %', test_company_id;
    RAISE NOTICE '- 지출 유형: 8개';
    RAISE NOTICE '- 업체: 3개';
    RAISE NOTICE '- 정기 지출 스케줄: 3개';
    RAISE NOTICE '- 지출 기록: 4개';
    
END $$;