-- =====================================================
-- 입주자(Tenant) 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    unit_rec RECORD;
    tenant_count INTEGER := 0;
    tenant_names TEXT[] := ARRAY[
        '김철수', '이영희', '박민수', '최지영', '정우진', '한소영', '임대호', '송미라',
        '강동원', '윤서연', '조현우', '배수지', '신민아', '오지호', '홍길동', '김영수'
    ];
    company_names TEXT[] := ARRAY[
        '(주)테크솔루션', '(주)글로벌무역', '(주)스마트시스템', '(주)디지털마케팅',
        '(주)그린에너지', '(주)바이오텍', '(주)클라우드서비스', '(주)모바일앱'
    ];
    occupations TEXT[] := ARRAY[
        '회사원', '자영업', '프리랜서', '공무원', '교사', '의사', '변호사', '엔지니어',
        '디자이너', '마케터', '개발자', '컨설턴트', '연구원', '간호사', '약사', '회계사'
    ];
    employers TEXT[] := ARRAY[
        '삼성전자', 'LG전자', '현대자동차', 'SK텔레콤', 'KT', '네이버', '카카오', '쿠팡',
        '배달의민족', '토스', '우아한형제들', '라인', '엔씨소프트', '넥슨', 'NHN', '위메프'
    ];
    random_idx INTEGER;
    random_date DATE;
    random_amount DECIMAL;
BEGIN
    -- 각 호실에 대해 입주자 생성 (일부 호실만)
    FOR unit_rec IN 
        SELECT u.unit_id, u.company_id, u.building_id, u.unit_number, u.unit_status
        FROM bms.units u
        WHERE u.unit_status IN ('OCCUPIED', 'VACANT')
        ORDER BY RANDOM()
        LIMIT 50  -- 50개 호실에만 입주자 데이터 생성
    LOOP
        -- 입주 중인 호실에는 활성 입주자, 공실에는 이전 입주자 생성
        random_idx := (RANDOM() * (array_length(tenant_names, 1) - 1))::INTEGER + 1;
        
        -- 개인 입주자 생성 (80% 확률)
        IF RANDOM() < 0.8 THEN
            INSERT INTO bms.tenants (
                company_id, building_id, unit_id,
                tenant_name, tenant_type, birth_date, gender, nationality,
                primary_phone, secondary_phone, email,
                emergency_contact_name, emergency_contact_phone, emergency_contact_relation,
                current_address, occupation, employer, monthly_income,
                credit_score, credit_rating, family_members, has_pets,
                move_in_date, move_out_date, lease_start_date, lease_end_date,
                deposit_amount, monthly_rent, tenant_status,
                privacy_consent, privacy_consent_date
            ) VALUES (
                unit_rec.company_id,
                unit_rec.building_id,
                unit_rec.unit_id,
                tenant_names[random_idx],
                'INDIVIDUAL',
                CURRENT_DATE - INTERVAL '20 years' - (RANDOM() * INTERVAL '30 years'),
                CASE WHEN RANDOM() < 0.5 THEN 'MALE' ELSE 'FEMALE' END,
                'KR',
                '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0'),
                CASE WHEN RANDOM() < 0.3 THEN '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') ELSE NULL END,
                'tenant' || random_idx || '@example.com',
                CASE WHEN RANDOM() < 0.7 THEN '김부모' ELSE NULL END,
                CASE WHEN RANDOM() < 0.7 THEN '010-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0') ELSE NULL END,
                CASE WHEN RANDOM() < 0.7 THEN '부모' ELSE NULL END,
                '서울시 강남구 테헤란로 ' || (RANDOM() * 500 + 1)::INTEGER || '번길',
                occupations[(RANDOM() * (array_length(occupations, 1) - 1))::INTEGER + 1],
                employers[(RANDOM() * (array_length(employers, 1) - 1))::INTEGER + 1],
                (RANDOM() * 5000000 + 2000000)::DECIMAL(12,2),  -- 200만원 ~ 700만원
                (RANDOM() * 300 + 600)::INTEGER,  -- 600~900점
                CASE 
                    WHEN RANDOM() < 0.3 THEN 'A'
                    WHEN RANDOM() < 0.6 THEN 'B'
                    WHEN RANDOM() < 0.8 THEN 'C'
                    ELSE 'D'
                END,
                (RANDOM() * 3 + 1)::INTEGER,  -- 1~4명
                RANDOM() < 0.2,  -- 20% 확률로 반려동물
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365 * 3 + 365)::INTEGER  -- 1~4년 전
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'VACANT' THEN CURRENT_DATE - (RANDOM() * 365)::INTEGER
                    ELSE NULL
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365 * 3 + 365)::INTEGER
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE + (RANDOM() * 365 * 2 + 365)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365)::INTEGER
                END,
                (RANDOM() * 50000000 + 10000000)::DECIMAL(15,2),  -- 1천만원 ~ 6천만원
                (RANDOM() * 1000000 + 500000)::DECIMAL(12,2),     -- 50만원 ~ 150만원
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN 'ACTIVE'
                    ELSE 'MOVED_OUT'
                END,
                true,
                CURRENT_DATE - (RANDOM() * 365)::INTEGER
            );
        ELSE
            -- 법인 입주자 생성 (20% 확률)
            random_idx := (RANDOM() * (array_length(company_names, 1) - 1))::INTEGER + 1;
            INSERT INTO bms.tenants (
                company_id, building_id, unit_id,
                tenant_name, tenant_type, business_registration_number,
                representative_name, business_type, establishment_date,
                primary_phone, email, current_address,
                monthly_income, family_members,
                move_in_date, move_out_date, lease_start_date, lease_end_date,
                deposit_amount, monthly_rent, tenant_status,
                privacy_consent, privacy_consent_date
            ) VALUES (
                unit_rec.company_id,
                unit_rec.building_id,
                unit_rec.unit_id,
                company_names[random_idx],
                'CORPORATION',
                LPAD((RANDOM() * 999999999 + 100000000)::BIGINT::TEXT, 10, '0'),
                tenant_names[(RANDOM() * (array_length(tenant_names, 1) - 1))::INTEGER + 1],
                CASE 
                    WHEN RANDOM() < 0.2 THEN 'IT서비스업'
                    WHEN RANDOM() < 0.4 THEN '제조업'
                    WHEN RANDOM() < 0.6 THEN '도소매업'
                    WHEN RANDOM() < 0.8 THEN '서비스업'
                    ELSE '기타'
                END,
                CURRENT_DATE - (RANDOM() * 365 * 10 + 365)::INTEGER,  -- 1~11년 전 설립
                '02-' || LPAD((RANDOM() * 999 + 100)::INTEGER::TEXT, 3, '0') || '-' || LPAD((RANDOM() * 9999)::INTEGER::TEXT, 4, '0'),
                'company' || random_idx || '@company.com',
                '서울시 강남구 테헤란로 ' || (RANDOM() * 500 + 1)::INTEGER || '번길',
                (RANDOM() * 20000000 + 5000000)::DECIMAL(12,2),  -- 500만원 ~ 2500만원
                1,  -- 법인은 가족 구성원 1명으로 설정
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365 * 3 + 365)::INTEGER
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'VACANT' THEN CURRENT_DATE - (RANDOM() * 365)::INTEGER
                    ELSE NULL
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE - (RANDOM() * 365 * 2)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365 * 3 + 365)::INTEGER
                END,
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN CURRENT_DATE + (RANDOM() * 365 * 2 + 365)::INTEGER
                    ELSE CURRENT_DATE - (RANDOM() * 365)::INTEGER
                END,
                (RANDOM() * 100000000 + 20000000)::DECIMAL(15,2),  -- 2천만원 ~ 1억2천만원
                (RANDOM() * 2000000 + 1000000)::DECIMAL(12,2),     -- 100만원 ~ 300만원
                CASE 
                    WHEN unit_rec.unit_status = 'OCCUPIED' THEN 'ACTIVE'
                    ELSE 'MOVED_OUT'
                END,
                true,
                CURRENT_DATE - (RANDOM() * 365)::INTEGER
            );
        END IF;
        
        tenant_count := tenant_count + 1;
    END LOOP;
    
    -- 일부 입주자를 블랙리스트로 설정 (5% 확률)
    UPDATE bms.tenants 
    SET is_blacklisted = true, 
        tenant_status = 'BLACKLISTED',
        blacklist_reason = '임대료 연체 및 시설 파손'
    WHERE tenant_id IN (
        SELECT tenant_id 
        FROM bms.tenants 
        ORDER BY RANDOM() 
        LIMIT (tenant_count * 0.05)::INTEGER
    );
    
    RAISE NOTICE '총 % 개의 테스트 입주자가 생성되었습니다.', tenant_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.tenants;

-- 데이터 검증 및 결과 출력
SELECT 
    '입주자 테스트 데이터 생성 완료' as status,
    COUNT(*) as total_tenants,
    COUNT(CASE WHEN tenant_status = 'ACTIVE' THEN 1 END) as active_tenants,
    COUNT(CASE WHEN tenant_status = 'MOVED_OUT' THEN 1 END) as moved_out_tenants,
    COUNT(CASE WHEN tenant_status = 'BLACKLISTED' THEN 1 END) as blacklisted_tenants,
    COUNT(CASE WHEN tenant_type = 'INDIVIDUAL' THEN 1 END) as individual_tenants,
    COUNT(CASE WHEN tenant_type = 'CORPORATION' THEN 1 END) as corporate_tenants,
    ROUND(AVG(monthly_rent), 0) as avg_monthly_rent
FROM bms.tenants;

-- 입주자 타입별 통계
SELECT 
    '입주자 타입별 현황' as info,
    tenant_type,
    COUNT(*) as count,
    COUNT(CASE WHEN tenant_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN is_blacklisted = true THEN 1 END) as blacklisted_count,
    ROUND(AVG(monthly_rent), 0) as avg_rent,
    ROUND(AVG(family_members), 1) as avg_family_members
FROM bms.tenants
GROUP BY tenant_type
ORDER BY count DESC;

-- 건물별 입주자 통계 뷰 테스트
SELECT 
    '건물별 입주자 통계' as info,
    building_name,
    total_tenants,
    active_tenants,
    moved_out_tenants,
    blacklisted_tenants,
    total_monthly_rent
FROM bms.v_building_tenant_statistics
WHERE total_tenants > 0
ORDER BY total_tenants DESC
LIMIT 5;

-- 임대차 만료 예정 뷰 테스트
SELECT 
    '임대차 만료 예정' as info,
    building_name,
    unit_number,
    tenant_name,
    lease_end_date,
    expiration_status
FROM bms.v_lease_expiration_schedule
WHERE expiration_status IN ('EXPIRED', 'EXPIRING_SOON', 'EXPIRING_IN_3_MONTHS')
ORDER BY lease_end_date
LIMIT 10;

-- 완료 메시지
SELECT '✅ 입주자 테스트 데이터 생성이 완료되었습니다!' as result;