-- =====================================================
-- QIRO 사업자 회원가입 및 멀티테넌시 구조 통합 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 기반 조직 관리 테이블 통합 설치 스크립트
-- =====================================================

-- 실행 순서:
-- 1. 00_companies_multitenancy.sql
-- 2. 01_users_multitenancy.sql  
-- 3. 02_roles_permissions.sql

\echo '=== QIRO 멀티테넌시 구조 설치 시작 ==='

-- 1. Companies 테이블 및 관련 구조
\echo '1. Companies 테이블 생성 중...'
\i database/schema/00_companies_multitenancy.sql

-- 2. Users 테이블 및 관련 구조
\echo '2. Users 테이블 생성 중...'
\i database/schema/01_users_multitenancy.sql

-- 3. Roles 및 User_role_links 테이블
\echo '3. Roles 및 권한 시스템 생성 중...'
\i database/schema/02_roles_permissions.sql

\echo '=== 멀티테넌시 구조 설치 완료 ==='

-- 설치 확인 쿼리
\echo '=== 설치 확인 ==='

SELECT 
    'companies' as table_name,
    COUNT(*) as row_count
FROM companies
UNION ALL
SELECT 
    'users' as table_name,
    COUNT(*) as row_count  
FROM users
UNION ALL
SELECT 
    'roles' as table_name,
    COUNT(*) as row_count
FROM roles
UNION ALL
SELECT 
    'user_role_links' as table_name,
    COUNT(*) as row_count
FROM user_role_links;

\echo '=== 테이블 구조 확인 ==='

\d+ companies
\d+ users  
\d+ roles
\d+ user_role_links