-- =====================================================
-- QIRO 멀티테넌시 구조 테스트 데이터
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 사업자 회원가입 및 멀티테넌시 기능 테스트용 데이터
-- =====================================================

-- 테스트 전 기존 데이터 정리
TRUNCATE TABLE user_role_links CASCADE;
TRUNCATE TABLE users CASCADE;
TRUNCATE TABLE roles CASCADE;
TRUNCATE TABLE companies CASCADE;

-- =====================================================
-- 1. 테스트 회사 데이터 생성
-- =====================================================

-- 회사 1: 대한빌딩관리 (아파트 관리 전문)
INSERT INTO companies (
    company_id,
    business_registration_number,
    company_name,
    representative_name,
    business_address,
    contact_phone,
    contact_email,
    business_type,
    establishment_date,
    verification_status,
    verification_date,
    subscription_plan,
    subscription_status
) VALUES (
    '11111111-1111-1111-1111-111111111111',
    '1234567890',  -- 유효한 사업자등록번호
    '대한빌딩관리(주)',
    '김대표',
    '서울특별시 강남구 테헤란로 123',
    '02-1234-5678',
    'admin@daehan-building.co.kr',
    '부동산 관리업',
    '2020-01-15',
    'VERIFIED',
    now() - interval '30 days',
    'PREMIUM',
    'ACTIVE'
);

-- 회사 2: 서울종합관리 (상업용 건물 관리)
INSERT INTO companies (
    company_id,
    business_registration_number,
    company_name,
    representative_name,
    business_address,
    contact_phone,
    contact_email,
    business_type,
    establishment_date,
    verification_status,
    verification_date,
    subscription_plan,
    subscription_status
) VALUES (
    '22222222-2222-2222-2222-222222222222',
    '2345678901',  -- 유효한 사업자등록번호
    '서울종합관리(주)',
    '이사장',
    '서울특별시 중구 명동길 456',
    '02-2345-6789',
    'info@seoul-management.co.kr',
    '건물 종합관리업',
    '2019-03-20',
    'VERIFIED',
    now() - interval '60 days',
    'ENTERPRISE',
    'ACTIVE'
);

-- 회사 3: 신규 가입 회사 (인증 대기 중)
INSERT INTO companies (
    company_id,
    business_registration_number,
    company_name,
    representative_name,
    business_address,
    contact_phone,
    contact_email,
    business_type,
    establishment_date,
    verification_status,
    subscription_plan,
    subscription_status
) VALUES (
    '33333333-3333-3333-3333-333333333333',
    '3456789012',  -- 유효한 사업자등록번호
    '미래관리서비스',
    '박대표',
    '부산광역시 해운대구 센텀로 789',
    '051-3456-7890',
    'contact@future-service.co.kr',
    '시설관리업',
    '2024-12-01',
    'PENDING',
    'BASIC',
    'TRIAL'
);

-- =====================================================
-- 2. 테스트 사용자 데이터 생성
-- =====================================================

-- 대한빌딩관리 사용자들
INSERT INTO users (
    user_id,
    company_id,
    email,
    password_hash,
    full_name,
    phone_number,
    department,
    position,
    user_type,
    status,
    email_verified,
    phone_verified,
    must_change_password
) VALUES 
-- 총괄관리자
(
    'a1111111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'admin@daehan-building.co.kr',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    '김대표',
    '010-1234-5678',
    '경영진',
    '대표이사',
    'SUPER_ADMIN',
    'ACTIVE',
    true,
    true,
    false
),
-- 관리소장
(
    'a1111111-1111-1111-1111-111111111112',
    '11111111-1111-1111-1111-111111111111',
    'manager1@daehan-building.co.kr',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    '이관리',
    '010-1234-5679',
    '관리부',
    '관리소장',
    'EMPLOYEE',
    'ACTIVE',
    true,
    true,
    false
),
-- 경리담당자
(
    'a1111111-1111-1111-1111-111111111113',
    '11111111-1111-1111-1111-111111111111',
    'accountant@daehan-building.co.kr',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    '박경리',
    '010-1234-5680',
    '회계부',
    '경리담당자',
    'EMPLOYEE',
    'ACTIVE',
    true,
    true,
    false
);

-- 서울종합관리 사용자들
INSERT INTO users (
    user_id,
    company_id,
    email,
    password_hash,
    full_name,
    phone_number,
    department,
    position,
    user_type,
    status,
    email_verified,
    phone_verified,
    must_change_password
) VALUES 
-- 총괄관리자
(
    'a2222222-2222-2222-2222-222222222221',
    '22222222-2222-2222-2222-222222222222',
    'ceo@seoul-management.co.kr',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    '이사장',
    '010-2345-6789',
    '경영진',
    '사장',
    'SUPER_ADMIN',
    'ACTIVE',
    true,
    true,
    false
),
-- 관리소장
(
    'a2222222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'manager@seoul-management.co.kr',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6hsxq5S/kS', -- password: admin123
    '최관리',
    '010-2345-6790',
    '관리부',
    '관리소장',
    'EMPLOYEE',
    'ACTIVE',
    true,
    true,
    false
);

-- =====================================================
-- 3. 역할 할당 테스트
-- =====================================================

-- 대한빌딩관리 역할 할당
DO $$
DECLARE
    super_admin_role_id UUID;
    building_manager_role_id UUID;
    accountant_role_id UUID;
BEGIN
    -- 대한빌딩관리의 역할 ID 조회
    SELECT role_id INTO super_admin_role_id 
    FROM roles 
    WHERE company_id = '11111111-1111-1111-1111-111111111111' 
      AND role_code = 'SUPER_ADMIN';
      
    SELECT role_id INTO building_manager_role_id 
    FROM roles 
    WHERE company_id = '11111111-1111-1111-1111-111111111111' 
      AND role_code = 'BUILDING_MANAGER';
      
    SELECT role_id INTO accountant_role_id 
    FROM roles 
    WHERE company_id = '11111111-1111-1111-1111-111111111111' 
      AND role_code = 'ACCOUNTANT';

    -- 역할 할당
    PERFORM assign_role_to_user(
        'a1111111-1111-1111-1111-111111111111', 
        super_admin_role_id,
        'a1111111-1111-1111-1111-111111111111',
        NULL,
        '시스템 초기 설정'
    );
    
    PERFORM assign_role_to_user(
        'a1111111-1111-1111-1111-111111111112', 
        building_manager_role_id,
        'a1111111-1111-1111-1111-111111111111',
        NULL,
        '관리소장 임명'
    );
    
    PERFORM assign_role_to_user(
        'a1111111-1111-1111-1111-111111111113', 
        accountant_role_id,
        'a1111111-1111-1111-1111-111111111111',
        NULL,
        '경리담당자 임명'
    );
END $$;

-- 서울종합관리 역할 할당
DO $$
DECLARE
    super_admin_role_id UUID;
    building_manager_role_id UUID;
BEGIN
    -- 서울종합관리의 역할 ID 조회
    SELECT role_id INTO super_admin_role_id 
    FROM roles 
    WHERE company_id = '22222222-2222-2222-2222-222222222222' 
      AND role_code = 'SUPER_ADMIN';
      
    SELECT role_id INTO building_manager_role_id 
    FROM roles 
    WHERE company_id = '22222222-2222-2222-2222-222222222222' 
      AND role_code = 'BUILDING_MANAGER';

    -- 역할 할당
    PERFORM assign_role_to_user(
        'a2222222-2222-2222-2222-222222222221', 
        super_admin_role_id,
        'a2222222-2222-2222-2222-222222222221',
        NULL,
        '시스템 초기 설정'
    );
    
    PERFORM assign_role_to_user(
        'a2222222-2222-2222-2222-222222222222', 
        building_manager_role_id,
        'a2222222-2222-2222-2222-222222222221',
        NULL,
        '관리소장 임명'
    );
END $$;

-- =====================================================
-- 4. 테스트 데이터 확인 쿼리
-- =====================================================

\echo '=== 테스트 데이터 생성 완료 ==='

-- 회사별 사용자 수 확인
SELECT 
    c.company_name,
    c.verification_status,
    c.subscription_status,
    COUNT(u.user_id) as user_count
FROM companies c
LEFT JOIN users u ON c.company_id = u.company_id
GROUP BY c.company_id, c.company_name, c.verification_status, c.subscription_status
ORDER BY c.company_name;

-- 사용자별 역할 확인
SELECT 
    c.company_name,
    u.full_name,
    u.email,
    u.user_type,
    u.status,
    r.role_name,
    url.assigned_at
FROM companies c
JOIN users u ON c.company_id = u.company_id
LEFT JOIN user_role_links url ON u.user_id = url.user_id AND url.is_active = true
LEFT JOIN roles r ON url.role_id = r.role_id
ORDER BY c.company_name, u.full_name;

-- 회사별 역할 수 확인
SELECT 
    c.company_name,
    COUNT(r.role_id) as role_count,
    COUNT(CASE WHEN r.is_system_role THEN 1 END) as system_role_count
FROM companies c
LEFT JOIN roles r ON c.company_id = r.company_id
GROUP BY c.company_id, c.company_name
ORDER BY c.company_name;