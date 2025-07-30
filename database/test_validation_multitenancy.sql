-- =====================================================
-- QIRO 멀티테넌시 구조 검증 테스트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 데이터 격리 및 기능 검증
-- =====================================================

\echo '=== 멀티테넌시 구조 검증 테스트 시작 ==='

-- =====================================================
-- 1. 사업자등록번호 검증 테스트
-- =====================================================

\echo '1. 사업자등록번호 검증 테스트'

-- 유효한 사업자등록번호 테스트
SELECT 
    '1234567890' as brn,
    validate_business_registration_number('1234567890') as is_valid;

-- 무효한 사업자등록번호 테스트
SELECT 
    '1234567891' as brn,
    validate_business_registration_number('1234567891') as is_valid;

-- =====================================================
-- 2. 데이터 격리 검증 테스트
-- =====================================================

\echo '2. 데이터 격리 검증 테스트'

-- 회사별 사용자 격리 확인
SELECT 
    'Company 1 Users' as test_case,
    COUNT(*) as user_count
FROM users 
WHERE company_id = '11111111-1111-1111-1111-111111111111';

SELECT 
    'Company 2 Users' as test_case,
    COUNT(*) as user_count
FROM users 
WHERE company_id = '22222222-2222-2222-2222-222222222222';

-- =====================================================
-- 3. 권한 시스템 검증 테스트
-- =====================================================

\echo '3. 권한 시스템 검증 테스트'

-- 사용자 권한 확인 테스트
SELECT 
    u.full_name,
    user_has_permission(u.user_id, 'buildings', 'create') as can_create_buildings,
    user_has_permission(u.user_id, 'users', 'delete') as can_delete_users
FROM users u
WHERE u.company_id = '11111111-1111-1111-1111-111111111111'
LIMIT 3;

\echo '=== 멀티테넌시 구조 검증 테스트 완료 ==='