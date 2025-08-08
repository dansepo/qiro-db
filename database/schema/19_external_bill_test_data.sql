-- =====================================================
-- 외부 고지서 관리 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    supplier_count INTEGER := 0;
    bill_count INTEGER := 0;
    config_count INTEGER := 0;
    
    -- 공급업체 ID 저장용 변수들
    electric_supplier_id UUID;
    water_supplier_id UUID;
    gas_supplier_id UUID;
    heating_supplier_id UUID;
BEGIN
    -- 각 회사에 대해 외부 고지서 관리 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 외부 고지서 관리 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 외부 공급업체 생성
        -- 전력회사
        INSERT INTO bms.external_suppliers (
            company_id, supplier_name, supplier_code, supplier_type,
            contact_person, phone_number, email,
            business_number, billing_cycle, billing_day, payment_due_days,
            auto_import_enabled, import_method
        ) VALUES 
        (company_rec.company_id, '한국전력공사', 'KEPCO', 'ELECTRIC',
         '김전력', '02-1234-5678', 'billing@kepco.co.kr',
         '123-45-67890', 'MONTHLY', 15, 30,
         true, 'EMAIL');
        
        -- 수도회사
        INSERT INTO bms.external_suppliers (
            company_id, supplier_name, supplier_code, supplier_type,
            contact_person, phone_number, email,
            business_number, billing_cycle, billing_day, payment_due_days,
            auto_import_enabled, import_method
        ) VALUES 
        (company_rec.company_id, '서울특별시 상수도사업본부', 'SEOUL_WATER', 'WATER',
         '박수도', '02-2222-3333', 'billing@waterworks.seoul.kr',
         '234-56-78901', 'MONTHLY', 20, 25,
         true, 'API');
        
        -- 가스회사
        INSERT INTO bms.external_suppliers (
            company_id, supplier_name, supplier_code, supplier_type,
            contact_person, phone_number, email,
            business_number, billing_cycle, billing_day, payment_due_days,
            auto_import_enabled, import_method
        ) VALUES 
        (company_rec.company_id, '서울도시가스', 'SEOUL_GAS', 'GAS',
         '최가스', '02-3333-4444', 'billing@seoulgas.co.kr',
         '345-67-89012', 'MONTHLY', 25, 30,
         false, 'MANUAL');
        
        -- 난방회사
        INSERT INTO bms.external_suppliers (
            company_id, supplier_name, supplier_code, supplier_type,
            contact_person, phone_number, email,
            business_number, billing_cycle, billing_day, payment_due_days,
            auto_import_enabled, import_method
        ) VALUES 
        (company_rec.company_id, '한국지역난방공사', 'KDHC', 'HEATING',
         '정난방', '02-4444-5555', 'billing@kdhc.co.kr',
         '456-78-90123', 'MONTHLY', 10, 35,
         true, 'FILE_UPLOAD');
        
        -- 공급업체 ID 조회
        SELECT supplier_id INTO electric_supplier_id FROM bms.external_suppliers WHERE company_id = company_rec.company_id AND supplier_type = 'ELECTRIC';
        SELECT supplier_id INTO water_supplier_id FROM bms.external_suppliers WHERE company_id = company_rec.company_id AND supplier_type = 'WATER';
        SELECT supplier_id INTO gas_supplier_id FROM bms.external_suppliers WHERE company_id = company_rec.company_id AND supplier_type = 'GAS';
        SELECT supplier_id INTO heating_supplier_id FROM bms.external_suppliers WHERE company_id = company_rec.company_id AND supplier_type = 'HEATING';
        
        supplier_count := supplier_count + 4;
        
        -- 2. 자동 가져오기 설정 생성
        -- 전력 자동 가져오기 설정
        INSERT INTO bms.bill_import_configurations (
            company_id, supplier_id, config_name, config_description,
            import_method, import_schedule, file_format,
            parsing_rules, field_mappings, validation_rules,
            auto_validation, auto_approval, auto_approval_threshold,
            notification_enabled, notification_recipients
        ) VALUES 
        (company_rec.company_id, electric_supplier_id, '전력 고지서 자동 가져오기', '한국전력공사 고지서 이메일 자동 처리',
         'EMAIL', '0 0 16 * *', 'PDF',
         '{"email_subject_pattern": "전력요금 고지서", "attachment_required": true}'::jsonb,
         '{"bill_number": "고지서번호", "total_amount": "총금액", "usage_amount": "사용량"}'::jsonb,
         '{"max_amount": 1000000, "min_usage": 0}'::jsonb,
         true, true, 500000,
         true, ARRAY['admin@' || company_rec.company_name || '.com']);
        
        -- 수도 자동 가져오기 설정
        INSERT INTO bms.bill_import_configurations (
            company_id, supplier_id, config_name, config_description,
            import_method, import_schedule, file_format,
            parsing_rules, field_mappings, validation_rules,
            auto_validation, auto_approval, auto_approval_threshold,
            notification_enabled, notification_recipients
        ) VALUES 
        (company_rec.company_id, water_supplier_id, '수도 고지서 API 연동', '서울시 상수도 API 자동 연동',
         'API', '0 0 21 * *', 'JSON',
         '{"api_endpoint": "https://api.waterworks.seoul.kr/bills", "auth_method": "API_KEY"}'::jsonb,
         '{"billNo": "bill_number", "totalAmount": "total_amount", "usage": "usage_amount"}'::jsonb,
         '{"max_amount": 800000, "min_usage": 0}'::jsonb,
         true, true, 300000,
         true, ARRAY['billing@' || company_rec.company_name || '.com']);
        
        config_count := config_count + 2;
        
        -- 3. 외부 고지서 생성 (최근 6개월)
        FOR i IN 0..5 LOOP
            DECLARE
                v_bill_period_start DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL;
                v_bill_period_end DATE := v_bill_period_start + INTERVAL '1 month' - INTERVAL '1 day';
                v_issue_date DATE := v_bill_period_end + INTERVAL '5 days';
                v_due_date DATE := v_issue_date + INTERVAL '30 days';
                v_supplier_ids UUID[] := ARRAY[electric_supplier_id, water_supplier_id, gas_supplier_id, heating_supplier_id];
                v_supplier_types TEXT[] := ARRAY['ELECTRIC', 'WATER', 'GAS', 'HEATING'];
                v_supplier_id UUID;
                v_supplier_type TEXT;
                v_usage_amount DECIMAL(15,4);
                v_total_amount DECIMAL(15,2);
            BEGIN
                -- 각 공급업체별로 고지서 생성
                FOR j IN 1..4 LOOP
                    v_supplier_id := v_supplier_ids[j];
                    v_supplier_type := v_supplier_types[j];
                    
                    -- 사용량 및 금액 계산 (랜덤)
                    CASE v_supplier_type
                        WHEN 'ELECTRIC' THEN
                            v_usage_amount := 1000 + random() * 3000;  -- 1000~4000 kWh
                            v_total_amount := v_usage_amount * (120 + random() * 50);  -- kWh당 120~170원
                        WHEN 'WATER' THEN
                            v_usage_amount := 50 + random() * 150;     -- 50~200 m³
                            v_total_amount := v_usage_amount * (800 + random() * 400);  -- m³당 800~1200원
                        WHEN 'GAS' THEN
                            v_usage_amount := 100 + random() * 300;    -- 100~400 m³
                            v_total_amount := v_usage_amount * (600 + random() * 300);  -- m³당 600~900원
                        WHEN 'HEATING' THEN
                            v_usage_amount := 20 + random() * 80;      -- 20~100 Gcal
                            v_total_amount := v_usage_amount * (50000 + random() * 20000);  -- Gcal당 50000~70000원
                    END CASE;
                    
                    -- 각 건물별로 고지서 생성
                    FOR building_rec IN 
                        SELECT building_id, name as building_name
                        FROM bms.buildings 
                        WHERE company_id = company_rec.company_id
                        LIMIT 2  -- 각 회사당 2개 건물만
                    LOOP
                        INSERT INTO bms.external_bills (
                            company_id, supplier_id, building_id,
                            bill_number, bill_type, bill_period_start, bill_period_end,
                            issue_date, due_date,
                            previous_reading, current_reading, usage_amount, usage_unit,
                            basic_charge, usage_charge, tax_amount, total_amount,
                            charge_details,
                            import_method, import_status, imported_at,
                            validation_status, approval_status, payment_status
                        ) VALUES (
                            company_rec.company_id, v_supplier_id, building_rec.building_id,
                            v_supplier_type || '-' || TO_CHAR(v_bill_period_start, 'YYYYMM') || '-' || building_rec.building_id::text,
                            'UTILITY', v_bill_period_start, v_bill_period_end,
                            v_issue_date, v_due_date,
                            CASE WHEN i = 0 THEN 0 ELSE v_usage_amount * (1 + random() * 0.2) END,  -- 이전 지시수
                            v_usage_amount * (1 + random() * 0.2),  -- 현재 지시수
                            v_usage_amount,
                            CASE v_supplier_type
                                WHEN 'ELECTRIC' THEN 'kWh'
                                WHEN 'WATER' THEN 'm³'
                                WHEN 'GAS' THEN 'm³'
                                WHEN 'HEATING' THEN 'Gcal'
                            END,
                            v_total_amount * 0.3,  -- 기본요금 (30%)
                            v_total_amount * 0.6,  -- 사용요금 (60%)
                            v_total_amount * 0.1,  -- 세금 (10%)
                            v_total_amount,
                            jsonb_build_object(
                                'basic_rate', CASE v_supplier_type WHEN 'ELECTRIC' THEN 910 WHEN 'WATER' THEN 1200 WHEN 'GAS' THEN 800 ELSE 30000 END,
                                'usage_rate', CASE v_supplier_type WHEN 'ELECTRIC' THEN 120 WHEN 'WATER' THEN 800 WHEN 'GAS' THEN 600 ELSE 50000 END,
                                'tax_rate', 0.1,
                                'discount_applied', false
                            ),
                            CASE WHEN random() < 0.8 THEN 'EMAIL' ELSE 'MANUAL' END,  -- 80% 이메일, 20% 수동
                            'COMPLETED',
                            v_issue_date + (random() * 3 || ' days')::INTERVAL,
                            CASE WHEN random() < 0.9 THEN 'PASSED' ELSE 'PENDING' END,  -- 90% 검증 통과
                            CASE WHEN random() < 0.8 THEN 'APPROVED' ELSE 'PENDING' END,  -- 80% 승인
                            CASE 
                                WHEN v_due_date < CURRENT_DATE AND random() < 0.1 THEN 'OVERDUE'  -- 10% 연체
                                WHEN random() < 0.7 THEN 'PAID'  -- 70% 지불 완료
                                ELSE 'UNPAID'  -- 나머지 미지불
                            END
                        );
                        
                        bill_count := bill_count + 1;
                        
                        -- 처리 이력 생성
                        INSERT INTO bms.bill_processing_history (
                            bill_id, company_id, action_type, action_description,
                            processing_result, processing_method
                        ) VALUES (
                            (SELECT bill_id FROM bms.external_bills WHERE company_id = company_rec.company_id AND supplier_id = v_supplier_id AND building_id = building_rec.building_id AND bill_period_start = v_bill_period_start),
                            company_rec.company_id, 'IMPORT', '고지서 자동 가져오기',
                            'SUCCESS', 'AUTOMATIC'
                        );
                    END LOOP;
                END LOOP;
            END;
        END LOOP;
        
        -- 4. 일부 고지서에 대해 결제 정보 업데이트
        UPDATE bms.external_bills
        SET paid_amount = total_amount,
            paid_date = due_date - INTERVAL '5 days',
            payment_method = CASE 
                WHEN random() < 0.6 THEN 'AUTO_DEBIT'
                WHEN random() < 0.8 THEN 'BANK_TRANSFER'
                ELSE 'CREDIT_CARD'
            END,
            payment_reference = 'PAY-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((random() * 9999)::integer::text, 4, '0')
        WHERE company_id = company_rec.company_id
          AND payment_status = 'PAID';
        
        RAISE NOTICE '회사 % 외부 고지서 관리 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 외부 고지서 관리 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 공급업체: %개', supplier_count;
    RAISE NOTICE '생성된 자동화 설정: %개', config_count;
    RAISE NOTICE '생성된 고지서: %개', bill_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 외부 고지서 관리 시스템 테스트 데이터 생성이 완료되었습니다!' as result;