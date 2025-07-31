-- =====================================================
-- 공통 코드 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    group_count INTEGER := 0;
    code_count INTEGER := 0;
    building_type_group_id UUID;
    unit_type_group_id UUID;
    facility_category_group_id UUID;
    contract_status_group_id UUID;
    payment_method_group_id UUID;
    tenant_status_group_id UUID;
    lessor_status_group_id UUID;
BEGIN
    -- 각 회사에 대해 공통 코드 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 공통 코드 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 건물 타입 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'BUILDING_TYPE', '건물 타입', '건물의 용도별 분류', 1, true
        ) RETURNING group_id INTO building_type_group_id;
        
        -- 건물 타입 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, building_type_group_id, 'OFFICE', '오피스', '사무용 건물', 1, true),
        (company_rec.company_id, building_type_group_id, 'COMMERCIAL', '상업시설', '상업용 건물', 2, true),
        (company_rec.company_id, building_type_group_id, 'RESIDENTIAL', '주거시설', '주거용 건물', 3, true),
        (company_rec.company_id, building_type_group_id, 'MIXED_USE', '복합용도', '복합용도 건물', 4, true),
        (company_rec.company_id, building_type_group_id, 'INDUSTRIAL', '공업시설', '공업용 건물', 5, true),
        (company_rec.company_id, building_type_group_id, 'WAREHOUSE', '창고시설', '창고용 건물', 6, true);
        
        code_count := code_count + 6;
        
        -- 2. 호실 타입 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'UNIT_TYPE', '호실 타입', '호실의 용도별 분류', 2, true
        ) RETURNING group_id INTO unit_type_group_id;
        
        -- 호실 타입 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, unit_type_group_id, 'OFFICE', '사무실', '사무용 호실', 1, true),
        (company_rec.company_id, unit_type_group_id, 'RETAIL', '매장', '소매용 호실', 2, true),
        (company_rec.company_id, unit_type_group_id, 'WAREHOUSE', '창고', '창고용 호실', 3, true),
        (company_rec.company_id, unit_type_group_id, 'APARTMENT', '아파트', '주거용 호실', 4, true),
        (company_rec.company_id, unit_type_group_id, 'STUDIO', '원룸', '원룸형 호실', 5, true),
        (company_rec.company_id, unit_type_group_id, 'PARKING', '주차장', '주차용 공간', 6, true),
        (company_rec.company_id, unit_type_group_id, 'STORAGE', '창고', '보관용 공간', 7, true);
        
        code_count := code_count + 7;
        
        -- 3. 시설 분류 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'FACILITY_CATEGORY', '시설 분류', '공용시설의 분류', 3, true
        ) RETURNING group_id INTO facility_category_group_id;
        
        -- 시설 분류 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, facility_category_group_id, 'ELEVATOR', '승강기', '엘리베이터 및 에스컬레이터', 1, true),
        (company_rec.company_id, facility_category_group_id, 'HVAC', '공조설비', '냉난방 및 환기 시설', 2, true),
        (company_rec.company_id, facility_category_group_id, 'ELECTRICAL', '전기설비', '전기 관련 시설', 3, true),
        (company_rec.company_id, facility_category_group_id, 'PLUMBING', '급배수', '급수 및 배수 시설', 4, true),
        (company_rec.company_id, facility_category_group_id, 'FIRE_SAFETY', '소방설비', '화재 예방 및 진압 시설', 5, true),
        (company_rec.company_id, facility_category_group_id, 'SECURITY', '보안설비', '보안 관련 시설', 6, true),
        (company_rec.company_id, facility_category_group_id, 'PARKING', '주차시설', '주차 관련 시설', 7, true),
        (company_rec.company_id, facility_category_group_id, 'COMMUNICATION', '통신설비', '통신 관련 시설', 8, true);
        
        code_count := code_count + 8;
        
        -- 4. 계약 상태 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'CONTRACT_STATUS', '계약 상태', '임대차 계약의 상태', 4, true
        ) RETURNING group_id INTO contract_status_group_id;
        
        -- 계약 상태 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code,
            extra_attributes
        ) VALUES 
        (company_rec.company_id, contract_status_group_id, 'DRAFT', '초안', '계약서 작성 중', 1, true, 
         '{"color": "#gray", "icon": "edit"}'),
        (company_rec.company_id, contract_status_group_id, 'PENDING', '검토중', '계약 검토 및 승인 대기', 2, true,
         '{"color": "#yellow", "icon": "clock"}'),
        (company_rec.company_id, contract_status_group_id, 'ACTIVE', '활성', '계약 진행 중', 3, true,
         '{"color": "#green", "icon": "check"}'),
        (company_rec.company_id, contract_status_group_id, 'EXPIRED', '만료', '계약 기간 만료', 4, true,
         '{"color": "#orange", "icon": "calendar"}'),
        (company_rec.company_id, contract_status_group_id, 'TERMINATED', '해지', '계약 해지됨', 5, true,
         '{"color": "#red", "icon": "x"}'),
        (company_rec.company_id, contract_status_group_id, 'RENEWED', '갱신', '계약 갱신됨', 6, true,
         '{"color": "#blue", "icon": "refresh"}');
        
        code_count := code_count + 6;
        
        -- 5. 지급 방법 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'PAYMENT_METHOD', '지급 방법', '임대료 지급 방법', 5, false
        ) RETURNING group_id INTO payment_method_group_id;
        
        -- 지급 방법 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, payment_method_group_id, 'BANK_TRANSFER', '계좌이체', '은행 계좌 이체', 1, false),
        (company_rec.company_id, payment_method_group_id, 'CASH', '현금', '현금 지급', 2, false),
        (company_rec.company_id, payment_method_group_id, 'CHECK', '수표', '수표 지급', 3, false),
        (company_rec.company_id, payment_method_group_id, 'ONLINE', '온라인송금', '온라인 송금', 4, false),
        (company_rec.company_id, payment_method_group_id, 'AUTO_TRANSFER', '자동이체', '자동 계좌 이체', 5, false);
        
        code_count := code_count + 5;
        
        -- 6. 입주자 상태 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'TENANT_STATUS', '입주자 상태', '입주자의 상태', 6, true
        ) RETURNING group_id INTO tenant_status_group_id;
        
        -- 입주자 상태 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, tenant_status_group_id, 'ACTIVE', '활성', '현재 입주 중', 1, true),
        (company_rec.company_id, tenant_status_group_id, 'INACTIVE', '비활성', '일시적 비활성', 2, true),
        (company_rec.company_id, tenant_status_group_id, 'MOVED_OUT', '퇴거', '퇴거 완료', 3, true),
        (company_rec.company_id, tenant_status_group_id, 'BLACKLISTED', '블랙리스트', '블랙리스트 등록', 4, true);
        
        code_count := code_count + 4;
        
        -- 7. 임대인 상태 코드 그룹 생성
        INSERT INTO bms.code_groups (
            company_id, group_code, group_name, group_description, display_order, is_system_code
        ) VALUES (
            company_rec.company_id, 'LESSOR_STATUS', '임대인 상태', '임대인의 상태', 7, true
        ) RETURNING group_id INTO lessor_status_group_id;
        
        -- 임대인 상태 코드들
        INSERT INTO bms.common_codes (
            company_id, group_id, code_value, code_name, code_description, display_order, is_system_code
        ) VALUES 
        (company_rec.company_id, lessor_status_group_id, 'ACTIVE', '활성', '활성 임대인', 1, true),
        (company_rec.company_id, lessor_status_group_id, 'INACTIVE', '비활성', '비활성 임대인', 2, true),
        (company_rec.company_id, lessor_status_group_id, 'SUSPENDED', '정지', '일시 정지', 3, true),
        (company_rec.company_id, lessor_status_group_id, 'TERMINATED', '종료', '계약 종료', 4, true);
        
        code_count := code_count + 4;
        group_count := group_count + 7;
        
        RAISE NOTICE '회사 % 공통 코드 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 일부 코드를 비활성화 (테스트용)
    UPDATE bms.common_codes 
    SET is_active = false
    WHERE code_value IN ('WAREHOUSE', 'STUDIO') 
      AND code_id IN (
          SELECT code_id 
          FROM bms.common_codes 
          ORDER BY RANDOM() 
          LIMIT 2
      );
    
    -- 일부 코드에 유효 종료일 설정 (테스트용)
    UPDATE bms.common_codes 
    SET effective_end_date = CURRENT_DATE + INTERVAL '30 days'
    WHERE code_value = 'CHECK'
      AND code_id IN (
          SELECT code_id 
          FROM bms.common_codes 
          WHERE code_value = 'CHECK'
          LIMIT 1
      );
    
    RAISE NOTICE '총 % 개의 코드 그룹과 % 개의 공통 코드가 생성되었습니다.', group_count, code_count;
END $$;

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.code_groups;
ANALYZE bms.common_codes;

-- 데이터 검증 및 결과 출력
SELECT 
    '공통 코드 테스트 데이터 생성 완료' as status,
    (SELECT COUNT(*) FROM bms.code_groups) as total_groups,
    (SELECT COUNT(*) FROM bms.code_groups WHERE is_active = true) as active_groups,
    (SELECT COUNT(*) FROM bms.common_codes) as total_codes,
    (SELECT COUNT(*) FROM bms.common_codes WHERE is_active = true) as active_codes,
    (SELECT COUNT(*) FROM bms.common_codes WHERE is_system_code = true) as system_codes;

-- 코드 그룹별 통계
SELECT 
    '코드 그룹별 현황' as info,
    group_code,
    group_name,
    total_codes,
    active_codes,
    inactive_codes,
    group_is_active
FROM bms.v_common_code_statistics
ORDER BY group_code;

-- 활성 공통 코드 뷰 테스트
SELECT 
    '활성 공통 코드' as info,
    group_code,
    code_value,
    code_name,
    display_order
FROM bms.v_active_common_codes
ORDER BY group_code, display_order
LIMIT 15;

-- 공통 코드 조회 함수 테스트
SELECT 
    '코드 조회 함수 테스트' as info,
    bms.get_code_name('BUILDING_TYPE', 'OFFICE') as office_name,
    bms.get_code_name('CONTRACT_STATUS', 'ACTIVE') as active_status_name,
    bms.get_code_name('PAYMENT_METHOD', 'BANK_TRANSFER') as bank_transfer_name;

-- 완료 메시지
SELECT '✅ 공통 코드 테스트 데이터 생성이 완료되었습니다!' as result;