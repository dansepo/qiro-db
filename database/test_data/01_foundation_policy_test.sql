-- =====================================================
-- 기초 정보 및 정책 관리 도메인 테스트 데이터
-- 작성일: 2025-01-30
-- 설명: 건물, 호실, 임대인, 임차인, 관리비 항목, 납부 정책 테스트 데이터
-- =====================================================

-- 테스트 시나리오별 데이터 생성

-- =====================================================
-- 1. 다양한 유형의 건물 테스트 데이터
-- =====================================================

-- 상업용 건물 (소규모)
INSERT INTO buildings (
    name, address, building_type, total_floors, basement_floors, total_area,
    construction_year, owner_name, owner_contact, management_company,
    status, created_by, updated_by
) VALUES 
('테스트 상가빌딩', '서울시 종로구 종로 100', 'COMMERCIAL', 5, 1, 2000.00,
 2019, '김상가', '010-1000-1000', 'QIRO 관리', 'ACTIVE', 1, 1),
('테스트 오피스텔', '서울시 강남구 강남대로 200', 'OFFICETEL', 12, 2, 6000.00,
 2021, '이오피스', '010-2000-2000', 'QIRO 관리', 'ACTIVE', 1, 1),
('테스트 주상복합', '서울시 마포구 월드컵로 300', 'MIXED_USE', 25, 3, 15000.00,
 2023, '박복합', '010-3000-3000', 'QIRO 관리', 'ACTIVE', 1, 1);

-- 건설 중인 건물 (테스트용)
INSERT INTO buildings (
    name, address, building_type, total_floors, basement_floors, total_area,
    construction_year, owner_name, owner_contact, management_company,
    status, created_by, updated_by
) VALUES 
('건설중 테스트빌딩', '서울시 서초구 서초대로 400', 'OFFICE', 20, 4, 10000.00,
 2025, '최건설', '010-4000-4000', 'QIRO 관리', 'UNDER_CONSTRUCTION', 1, 1);

-- =====================================================
-- 2. 다양한 호실 유형 및 상태 테스트 데이터
-- =====================================================

-- 상가빌딩 호실들 (다양한 면적과 임대료)
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, common_area,
    monthly_rent, deposit, maintenance_fee, status, room_count, bathroom_count,
    has_balcony, has_parking, created_by, updated_by
) VALUES 
-- 1층 상가
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '101', 1, 'RETAIL', 45.5, 10.0, 800000, 8000000, 150000, 'OCCUPIED', 1, 1, false, false, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '102', 1, 'RETAIL', 60.0, 15.0, 1200000, 12000000, 200000, 'AVAILABLE', 2, 1, false, true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '103', 1, 'RESTAURANT', 80.0, 20.0, 2000000, 20000000, 300000, 'MAINTENANCE', 3, 2, false, true, 1, 1),
-- 2층 사무실
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '201', 2, 'OFFICE', 100.0, 25.0, 1800000, 18000000, 250000, 'OCCUPIED', 4, 2, true, true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '202', 2, 'OFFICE', 120.0, 30.0, 2200000, 22000000, 300000, 'AVAILABLE', 5, 2, true, true, 1, 1);

-- 오피스텔 호실들 (표준화된 구조)
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, common_area,
    monthly_rent, deposit, maintenance_fee, status, room_count, bathroom_count,
    has_balcony, has_parking, created_by, updated_by
) VALUES 
-- 3층 오피스텔
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '301', 3, 'OFFICETEL', 33.0, 8.0, 1500000, 15000000, 200000, 'OCCUPIED', 1, 1, true, true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '302', 3, 'OFFICETEL', 33.0, 8.0, 1500000, 15000000, 200000, 'OCCUPIED', 1, 1, true, true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '303', 3, 'OFFICETEL', 42.0, 10.0, 1800000, 18000000, 250000, 'AVAILABLE', 2, 1, true, true, 1, 1);

-- 주상복합 호실들 (주거+상업)
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, common_area,
    monthly_rent, deposit, maintenance_fee, status, room_count, bathroom_count,
    has_balcony, has_parking, created_by, updated_by
) VALUES 
-- 지하1층 상가
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), 'B101', -1, 'RETAIL', 50.0, 12.0, 1000000, 10000000, 180000, 'OCCUPIED', 1, 1, false, false, 1, 1),
-- 10층 주거
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '1001', 10, 'RESIDENTIAL', 84.5, 15.0, 2500000, 30000000, 350000, 'OCCUPIED', 3, 2, true, true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '1002', 10, 'RESIDENTIAL', 84.5, 15.0, 2500000, 30000000, 350000, 'AVAILABLE', 3, 2, true, true, 1, 1);

-- =====================================================
-- 3. 다양한 임대인 유형 테스트 데이터
-- =====================================================

-- 개인 임대인
INSERT INTO lessors (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, address, bank_name, account_holder,
    is_active, privacy_consent, created_by, updated_by
) VALUES 
('김개인', 'INDIVIDUAL', NULL, NULL, '010-1001-1001', 'kim.individual@test.com',
 '서울시 강남구 역삼동 123-45', '국민은행', '김개인', true, true, 1, 1),
('이소유', 'INDIVIDUAL', NULL, NULL, '010-1002-1002', 'lee.owner@test.com',
 '서울시 서초구 잠원동 678-90', '신한은행', '이소유', true, true, 1, 1);

-- 법인 임대인
INSERT INTO lessors (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, address, bank_name, account_holder,
    is_active, privacy_consent, created_by, updated_by
) VALUES 
('테스트부동산(주)', 'CORPORATION', '123-45-67890', '박대표', '02-1001-1001', 'info@testrealty.co.kr',
 '서울시 종로구 종로 100', '우리은행', '테스트부동산(주)', true, true, 1, 1),
('글로벌빌딩', 'CORPORATION', '234-56-78901', '최사장', '02-1002-1002', 'global@building.co.kr',
 '서울시 강남구 테헤란로 500', 'KEB하나은행', '글로벌빌딩', true, true, 1, 1);

-- =====================================================
-- 4. 다양한 임차인 유형 테스트 데이터
-- =====================================================

-- 개인 임차인 (다양한 직업군)
INSERT INTO tenants (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, current_address, occupation, monthly_income,
    family_members, is_active, privacy_consent, created_by, updated_by
) VALUES 
('정직장인', 'INDIVIDUAL', NULL, NULL, '010-2001-2001', 'jung.worker@test.com',
 '서울시 종로구 종로 100 101호', '회사원', 4500000, 2, true, true, 1, 1),
('김프리', 'INDIVIDUAL', NULL, NULL, '010-2002-2002', 'kim.freelancer@test.com',
 '서울시 강남구 강남대로 200 301호', '프리랜서', 3500000, 1, true, true, 1, 1),
('이의사', 'INDIVIDUAL', NULL, NULL, '010-2003-2003', 'lee.doctor@test.com',
 '서울시 마포구 월드컵로 300 1001호', '의사', 15000000, 4, true, true, 1, 1);

-- 법인 임차인 (다양한 업종)
INSERT INTO tenants (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, current_address, occupation, monthly_income,
    family_members, is_active, privacy_consent, created_by, updated_by
) VALUES 
('테스트카페', 'CORPORATION', '345-67-89012', '박사장', '02-2001-2001', 'test@cafe.co.kr',
 '서울시 종로구 종로 100 103호', '카페운영', 8000000, 1, true, true, 1, 1),
('스타트업IT', 'CORPORATION', '456-78-90123', '최대표', '02-2002-2002', 'startup@it.co.kr',
 '서울시 강남구 강남대로 200 201호', 'IT서비스', 25000000, 1, true, true, 1, 1),
('헬스케어솔루션', 'CORPORATION', '567-89-01234', '한대표', '02-2003-2003', 'health@solution.co.kr',
 '서울시 마포구 월드컵로 300 B101호', '의료서비스', 12000000, 1, true, true, 1, 1);

-- =====================================================
-- 5. 건물별 특화된 관리비 항목 테스트 데이터
-- =====================================================

-- 상가빌딩 관리비 항목 (상업시설 특화)
INSERT INTO fee_items (
    building_id, name, code, fee_type, calculation_method, charge_target,
    unit_price, fixed_amount, is_taxable, is_active, display_order,
    created_by, updated_by
) VALUES 
-- 테스트 상가빌딩 관리비 항목
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 800.00, NULL, false, true, 1, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 400.00, NULL, false, true, 2, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '보안비', 'SECURITY', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 40000.00, false, true, 3, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '승강기유지비', 'ELEVATOR', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 25000.00, false, true, 4, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 115.00, NULL, true, true, 5, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '수도료', 'WATER', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 750.00, NULL, true, true, 6, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '가스료', 'GAS', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 900.00, NULL, true, true, 7, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '쓰레기수거비', 'WASTE', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 15000.00, false, true, 8, 1, 1);

-- 오피스텔 관리비 항목 (주거+업무 복합)
INSERT INTO fee_items (
    building_id, name, code, fee_type, calculation_method, charge_target,
    unit_price, fixed_amount, is_taxable, is_active, display_order,
    created_by, updated_by
) VALUES 
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 1100.00, NULL, false, true, 1, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 550.00, NULL, false, true, 2, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '보안비', 'SECURITY', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 45000.00, false, true, 3, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '승강기유지비', 'ELEVATOR', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 35000.00, false, true, 4, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 118.00, NULL, true, true, 5, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '수도료', 'WATER', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 780.00, NULL, true, true, 6, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '난방비', 'HEATING', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 850.00, NULL, true, true, 7, 1, 1);

-- 주상복합 관리비 항목 (복합용도)
INSERT INTO fee_items (
    building_id, name, code, fee_type, calculation_method, charge_target,
    unit_price, fixed_amount, is_taxable, is_active, display_order,
    created_by, updated_by
) VALUES 
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 1300.00, NULL, false, true, 1, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 650.00, NULL, false, true, 2, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '보안비', 'SECURITY', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 55000.00, false, true, 3, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '승강기유지비', 'ELEVATOR', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 40000.00, false, true, 4, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 122.00, NULL, true, true, 5, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '수도료', 'WATER', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 820.00, NULL, true, true, 6, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '난방비', 'HEATING', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 880.00, NULL, true, true, 7, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '주차관리비', 'PARKING', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'PARKING_USERS', NULL, 30000.00, false, true, 8, 1, 1);

-- =====================================================
-- 6. 건물별 납부 정책 테스트 데이터
-- =====================================================

INSERT INTO payment_policies (
    building_id, policy_name, payment_due_day, grace_period_days, late_fee_rate,
    bank_name, account_number, account_holder, effective_from,
    is_active, created_by, updated_by
) VALUES 
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '상가빌딩 납부정책', 5, 3, 0.0150, '국민은행', '111-222-333444', 'QIRO관리', '2024-01-01', true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '오피스텔 납부정책', 10, 5, 0.0180, '신한은행', '222-333-444555', 'QIRO관리', '2024-01-01', true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '주상복합 납부정책', 25, 7, 0.0200, '우리은행', '333-444-555666', 'QIRO관리', '2024-01-01', true, 1, 1);

-- =====================================================
-- 7. 외부 고지서 계정 테스트 데이터
-- =====================================================

INSERT INTO external_bill_accounts (
    building_id, provider_name, provider_type, account_number, usage_purpose,
    connected_units, is_active, created_by, updated_by
) VALUES 
-- 상가빌딩 외부 계정
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '한국전력공사', 'KEPCO', 'KEPCO001001', '건물 전체 전기', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 상가빌딩')), true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '서울시 상수도사업본부', 'K_WATER', 'WATER001001', '건물 전체 수도', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 상가빌딩')), true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 상가빌딩'), '서울도시가스', 'CITY_GAS', 'GAS001001', '건물 전체 가스', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 상가빌딩')), true, 1, 1),

-- 오피스텔 외부 계정
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '한국전력공사', 'KEPCO', 'KEPCO002001', '건물 전체 전기', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 오피스텔')), true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '서울시 상수도사업본부', 'K_WATER', 'WATER002001', '건물 전체 수도', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 오피스텔')), true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 오피스텔'), '한국지역난방공사', 'DISTRICT_HEATING', 'HEAT002001', '건물 전체 난방', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 오피스텔')), true, 1, 1),

-- 주상복합 외부 계정
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '한국전력공사', 'KEPCO', 'KEPCO003001', '건물 전체 전기', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 주상복합')), true, 1, 1),
((SELECT id FROM buildings WHERE name = '테스트 주상복합'), '서울시 상수도사업본부', 'K_WATER', 'WATER003001', '건물 전체 수도', 
 (SELECT json_agg(id) FROM units WHERE building_id = (SELECT id FROM buildings WHERE name = '테스트 주상복합')), true, 1, 1);

-- =====================================================
-- 8. 데이터 검증 쿼리
-- =====================================================

-- 생성된 테스트 데이터 개수 확인
SELECT 
    '기초 정보 및 정책 관리 도메인 테스트 데이터 생성 완료' as message,
    (SELECT COUNT(*) FROM buildings WHERE name LIKE '테스트%') as test_buildings,
    (SELECT COUNT(*) FROM units WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '테스트%')) as test_units,
    (SELECT COUNT(*) FROM lessors WHERE name LIKE '%테스트%' OR name LIKE '김개인' OR name LIKE '이소유') as test_lessors,
    (SELECT COUNT(*) FROM tenants WHERE name LIKE '%테스트%' OR name LIKE '정직장인' OR name LIKE '김프리' OR name LIKE '이의사') as test_tenants,
    (SELECT COUNT(*) FROM fee_items WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '테스트%')) as test_fee_items,
    (SELECT COUNT(*) FROM payment_policies WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '테스트%')) as test_payment_policies,
    (SELECT COUNT(*) FROM external_bill_accounts WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '테스트%')) as test_external_accounts;

-- 건물별 호실 수 검증
SELECT 
    b.name as building_name,
    b.total_units as recorded_total,
    COUNT(u.id) as actual_count,
    CASE WHEN b.total_units = COUNT(u.id) THEN 'PASS' ELSE 'FAIL' END as validation_result
FROM buildings b
LEFT JOIN units u ON b.id = u.building_id
WHERE b.name LIKE '테스트%'
GROUP BY b.id, b.name, b.total_units
ORDER BY b.name;

COMMIT;