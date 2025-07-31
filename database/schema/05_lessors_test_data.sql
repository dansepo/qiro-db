-- =====================================================
-- 임대인(Lessor) 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    building_rec RECORD;
    lessor_count INTEGER := 0;
    lessor_names TEXT[] := ARRAY[
        '김부동산', '이건물주', '박임대', '최소유', '정건물', '한부자', '임소유', '송건물',
        '강부동산', '윤임대', '조소유', '배건물주', '신부자', '오임대', '홍부동산', '김소유'
    ];
    company_names TEXT[] := ARRAY[
        '(주)부동산개발', '(주)건물관리', '(주)임대사업', '(주)부동산투자',
        '(주)건설개발', '(주)자산관리', '(주)부동산운용', '(주)투자개발'
    ];
    banks TEXT[] := ARRAY[
        '국민은행', '신한은행', '우리은행', 'KEB하나은행', '농협은행', 
        '기업은행', '수협은행', '대구은행', '부산은행', '경남은행'
    ];
    payment_methods TEXT[] := ARRAY[
        '계좌이체', '현금', '수표', '온라인송금', '자동이체'
    ];
    random_idx INTEGER;
    random_date DATE;
    random_amount DECIMAL;
    assignment_count INTEGER := 0;
BEGIN
    -- 각 건물에 대해 임대인 생성
    FOR building_rec IN 
        SELECT building_id, company_id, name
        FROM bms.buildings 
        WHERE building_status = 'ACTIVE'
        LIMIT 10  -- 10개 건물에만 임대인 데이터 생성
    LOOP
        RAISE NOTICE '건물 % (%) 임대인 생성 시작', building_rec.name, building_rec.building_id;
        
        -- 개인 임대인 생성 (70% 확률)
        IF RANDOM() < 0.7 THEN
            random_idx := (RANDOM() * (array_length(lessor_names, 1) - 1))::INTEGER + 1;
            
            INSERT INTO bms.lessors (
                company_id, lessor_name, lessor_type, birth_date, gender, nationality,
                primary_phone, secondary_phone, email, address, postal_code,
                bank_name, account_number, account_holder,
                total_properties, total_rental_income, preferred_payment_method, payment_day,
                property_manager_name, property_manager_phone,
                lessor_status, is_verified, verification_date, credit_rating,
                privacy_consent, privacy_consent_date
            ) VALUES (
                building_rec.company_id,
                lessor_names[random_idx],
                'INDIVIDUAL',
                CURRENT_DATE - INTERVAL '30 years' - (RANDOM() * INTERVAL '30 years'), -- 30-60세
                CASE WHEN RANDOM() < 0.6 THEN 'MALE' ELSE 'FEMALE' END,
                'KR',
                '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0'),
                CASE WHEN RANDOM() < 0.4 THEN '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') ELSE NULL END,
                'lessor' || lessor_count || '@example.com',
                '서울시 강남구 역삼동 ' || (RANDOM() * 500 + 1)::INTEGER || '번지',
                '06' || LPAD((RANDOM() * 999)::INTEGER::TEXT, 3, '0'),
                banks[(RANDOM() * (array_length(banks, 1) - 1))::INTEGER + 1],
                LPAD((RANDOM() * 999999999999)::BIGINT::TEXT, 12, '0'),
                lessor_names[random_idx],
                (RANDOM() * 5 + 1)::INTEGER,  -- 1-6개 부동산
                (RANDOM() * 50000000 + 10000000)::DECIMAL(15,2),  -- 1천만원 ~ 6천만원
                payment_methods[(RANDOM() * (array_length(payment_methods, 1) - 1))::INTEGER + 1],
                (RANDOM() * 28 + 1)::INTEGER,  -- 1-28일
                CASE WHEN RANDOM() < 0.3 THEN '김관리' ELSE NULL END,
                CASE WHEN RANDOM() < 0.3 THEN '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') ELSE NULL END,
                CASE WHEN RANDOM() < 0.9 THEN 'ACTIVE' ELSE 'INACTIVE' END,
                RANDOM() < 0.8,  -- 80% 확률로 신원 확인
                CASE WHEN RANDOM() < 0.8 THEN CURRENT_DATE - (RANDOM() * 365)::INTEGER ELSE NULL END,
                CASE 
                    WHEN RANDOM() < 0.2 THEN 'AAA'
                    WHEN RANDOM() < 0.4 THEN 'AA'
                    WHEN RANDOM() < 0.6 THEN 'A'
                    WHEN RANDOM() < 0.8 THEN 'BBB'
                    ELSE 'BB'
                END,
                true,
                CURRENT_DATE - (RANDOM() * 365)::INTEGER
            );
        ELSE
            -- 법인 임대인 생성 (30% 확률)
            random_idx := (RANDOM() * (array_length(company_names, 1) - 1))::INTEGER + 1;
            
            INSERT INTO bms.lessors (
                company_id, lessor_name, lessor_type, business_registration_number,
                representative_name, business_type, establishment_date,
                primary_phone, email, address, postal_code,
                bank_name, account_number, account_holder,
                total_properties, total_rental_income, preferred_payment_method, payment_day,
                property_management_company,
                lessor_status, is_verified, verification_date, credit_rating,
                privacy_consent, privacy_consent_date
            ) VALUES (
                building_rec.company_id,
                company_names[random_idx],
                'CORPORATION',
                LPAD((RANDOM() * 999999999 + 100000000)::BIGINT::TEXT, 10, '0'),
                lessor_names[(RANDOM() * (array_length(lessor_names, 1) - 1))::INTEGER + 1],
                CASE 
                    WHEN RANDOM() < 0.3 THEN '부동산임대업'
                    WHEN RANDOM() < 0.6 THEN '부동산개발업'
                    ELSE '부동산관리업'
                END,
                CURRENT_DATE - (RANDOM() * 365 * 15 + 365)::INTEGER,  -- 1-16년 전 설립
                '02-' || LPAD((RANDOM() * 999 + 100)::INTEGER::TEXT, 3, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0'),
                'company' || lessor_count || '@company.com',
                '서울시 강남구 테헤란로 ' || (RANDOM() * 500 + 1)::INTEGER || '번길',
                '06' || LPAD((RANDOM() * 999)::INTEGER::TEXT, 3, '0'),
                banks[(RANDOM() * (array_length(banks, 1) - 1))::INTEGER + 1],
                LPAD((RANDOM() * 999999999999)::BIGINT::TEXT, 12, '0'),
                company_names[random_idx],
                (RANDOM() * 20 + 5)::INTEGER,  -- 5-25개 부동산
                (RANDOM() * 200000000 + 50000000)::DECIMAL(15,2),  -- 5천만원 ~ 2억5천만원
                payment_methods[(RANDOM() * (array_length(payment_methods, 1) - 1))::INTEGER + 1],
                (RANDOM() * 28 + 1)::INTEGER,  -- 1-28일
                '(주)부동산관리전문',
                CASE WHEN RANDOM() < 0.95 THEN 'ACTIVE' ELSE 'INACTIVE' END,
                true,  -- 법인은 모두 신원 확인
                CURRENT_DATE - (RANDOM() * 365)::INTEGER,
                CASE 
                    WHEN RANDOM() < 0.4 THEN 'AAA'
                    WHEN RANDOM() < 0.7 THEN 'AA'
                    ELSE 'A'
                END,
                true,
                CURRENT_DATE - (RANDOM() * 365)::INTEGER
            );
        END IF;
        
        lessor_count := lessor_count + 1;
        
        -- 방금 생성한 임대인과 건물을 연결
        INSERT INTO bms.lessor_building_assignments (
            company_id, lessor_id, building_id,
            ownership_percentage, ownership_start_date, ownership_type
        ) VALUES (
            building_rec.company_id,
            (SELECT lessor_id FROM bms.lessors WHERE company_id = building_rec.company_id ORDER BY created_at DESC LIMIT 1),
            building_rec.building_id,
            CASE 
                WHEN RANDOM() < 0.8 THEN 100.00  -- 80% 확률로 단독 소유
                ELSE (RANDOM() * 50 + 50)::DECIMAL(5,2)  -- 50-100% 지분
            END,
            CURRENT_DATE - (RANDOM() * 365 * 5)::INTEGER,  -- 0-5년 전부터 소유
            CASE 
                WHEN RANDOM() < 0.7 THEN 'FULL'
                WHEN RANDOM() < 0.9 THEN 'PARTIAL'
                ELSE 'JOINT'
            END
        );
        
        assignment_count := assignment_count + 1;
        
        RAISE NOTICE '건물 % 임대인 생성 완료', building_rec.name;
    END LOOP;
    
    -- 일부 임대인을 비활성화 (5% 확률)
    UPDATE bms.lessors 
    SET lessor_status = 'INACTIVE'
    WHERE lessor_id IN (
        SELECT lessor_id 
        FROM bms.lessors 
        WHERE lessor_status = 'ACTIVE'
        ORDER BY RANDOM() 
        LIMIT (lessor_count * 0.05)::INTEGER
    );
    
    RAISE NOTICE '총 % 개의 테스트 임대인이 생성되었습니다.', lessor_count;
    RAISE NOTICE '총 % 개의 임대인-건물 연결이 생성되었습니다.', assignment_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.lessors;
ANALYZE bms.lessor_building_assignments;

-- 데이터 검증 및 결과 출력
SELECT 
    '임대인 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_lessors,
    COUNT(CASE WHEN lessor_status = 'ACTIVE' THEN 1 END) as active_lessors,
    COUNT(CASE WHEN lessor_status = 'INACTIVE' THEN 1 END) as inactive_lessors,
    COUNT(CASE WHEN lessor_type = 'INDIVIDUAL' THEN 1 END) as individual_lessors,
    COUNT(CASE WHEN lessor_type = 'CORPORATION' THEN 1 END) as corporate_lessors,
    COUNT(CASE WHEN is_verified = true THEN 1 END) as verified_lessors,
    ROUND(AVG(total_rental_income), 0) as avg_rental_income
FROM bms.lessors;

-- 임대인 타입별 통계
SELECT 
    '임대인 타입별 현황' as info,
    lessor_type,
    COUNT(*) as count,
    COUNT(CASE WHEN lessor_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN is_verified = true THEN 1 END) as verified_count,
    ROUND(AVG(total_properties), 1) as avg_properties,
    ROUND(AVG(total_rental_income), 0) as avg_income
FROM bms.lessors
GROUP BY lessor_type
ORDER BY count DESC;

-- 임대료 지급일별 분포
SELECT 
    '지급일별 분포' as info,
    CASE 
        WHEN payment_day <= 5 THEN '1-5일'
        WHEN payment_day <= 10 THEN '6-10일'
        WHEN payment_day <= 15 THEN '11-15일'
        WHEN payment_day <= 20 THEN '16-20일'
        WHEN payment_day <= 25 THEN '21-25일'
        ELSE '26-31일'
    END as payment_period,
    COUNT(*) as lessor_count,
    ROUND(AVG(total_rental_income), 0) as avg_income
FROM bms.lessors
GROUP BY 
    CASE 
        WHEN payment_day <= 5 THEN '1-5일'
        WHEN payment_day <= 10 THEN '6-10일'
        WHEN payment_day <= 15 THEN '11-15일'
        WHEN payment_day <= 20 THEN '16-20일'
        WHEN payment_day <= 25 THEN '21-25일'
        ELSE '26-31일'
    END
ORDER BY MIN(payment_day);

-- 임대인-건물 관계 통계
SELECT 
    '임대인-건물 관계' as info,
    COUNT(*) as total_assignments,
    COUNT(CASE WHEN ownership_percentage = 100 THEN 1 END) as full_ownership,
    COUNT(CASE WHEN ownership_percentage < 100 THEN 1 END) as partial_ownership,
    ROUND(AVG(ownership_percentage), 2) as avg_ownership_percentage
FROM bms.lessor_building_assignments;

-- 임대인-건물 관계 뷰 테스트
SELECT 
    '임대인-건물 관계 뷰' as info,
    lessor_name,
    lessor_type,
    building_name,
    ownership_percentage,
    ownership_type,
    ownership_status
FROM bms.v_lessor_building_relationships
ORDER BY ownership_percentage DESC
LIMIT 5;

-- 완료 메시지
SELECT '✅ 임대인 테스트 데이터 생성이 완료되었습니다!' as result;