-- =====================================================
-- QIRO 멀티테넌시 통합 설정 스크립트
-- 작성일: 2025-01-30
-- 설명: 전체 시스템의 멀티테넌시 구조 설정 및 초기화
-- =====================================================

-- 1. 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. 애플리케이션 역할 생성
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'application_role') THEN
        CREATE ROLE application_role;
        RAISE NOTICE '애플리케이션 역할 생성 완료';
    ELSE
        RAISE NOTICE '애플리케이션 역할이 이미 존재합니다';
    END IF;
END $$;

-- 3. 조직 컨텍스트 설정 함수
CREATE OR REPLACE FUNCTION set_company_context(company_id UUID)
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_company_id', company_id::TEXT, false);
    RAISE NOTICE '회사 컨텍스트 설정: %', company_id;
END;
$$ LANGUAGE plpgsql;

-- 4. 현재 조직 컨텍스트 조회 함수
CREATE OR REPLACE FUNCTION get_current_company_id()
RETURNS UUID AS $$
BEGIN
    RETURN current_setting('app.current_company_id', true)::UUID;
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 5. 조직 컨텍스트 초기화 함수
CREATE OR REPLACE FUNCTION clear_company_context()
RETURNS VOID AS $$
BEGIN
    PERFORM set_config('app.current_company_id', '', false);
    RAISE NOTICE '회사 컨텍스트 초기화 완료';
END;
$$ LANGUAGE plpgsql;

-- 6. 멀티테넌시 상태 확인 함수
CREATE OR REPLACE FUNCTION check_multitenancy_status()
RETURNS TABLE (
    table_name TEXT,
    rls_enabled BOOLEAN,
    policy_count BIGINT,
    has_company_context BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        t.rowsecurity,
        COUNT(p.policyname)::BIGINT,
        EXISTS(
            SELECT 1 FROM information_schema.columns c
            WHERE c.table_name = t.tablename 
            AND c.column_name = 'company_id'
        ) as has_company_context
    FROM pg_tables t
    LEFT JOIN pg_policies p ON t.tablename = p.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename IN (
        'companies', 'users', 'buildings', 'units', 'lessors', 'tenants',
        'fee_items', 'billing_months', 'invoices', 'payments',
        'building_groups', 'user_group_assignments'
    )
    GROUP BY t.tablename, t.rowsecurity
    ORDER BY t.tablename;
END;
$$ LANGUAGE plpgsql;

-- 7. 전체 시스템 통계 함수
CREATE OR REPLACE FUNCTION get_system_multitenancy_stats()
RETURNS TABLE (
    metric_name TEXT,
    metric_value BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 'total_organizations'::TEXT, COUNT(*)::BIGINT FROM companies;
    
    RETURN QUERY
    SELECT 'total_users'::TEXT, COUNT(*)::BIGINT FROM users;
    
    RETURN QUERY
    SELECT 'total_buildings'::TEXT, COUNT(*)::BIGINT FROM buildings;
    
    RETURN QUERY
    SELECT 'total_units'::TEXT, COUNT(*)::BIGINT FROM units;
    
    RETURN QUERY
    SELECT 'rls_enabled_tables'::TEXT, COUNT(*)::BIGINT 
    FROM pg_tables t 
    WHERE t.schemaname = 'public' AND t.rowsecurity = true;
    
    RETURN QUERY
    SELECT 'total_policies'::TEXT, COUNT(*)::BIGINT 
    FROM pg_policies p 
    WHERE p.schemaname = 'public';
END;
$$ LANGUAGE plpgsql;

-- 8. 조직별 데이터 격리 테스트 함수
CREATE OR REPLACE FUNCTION test_company_isolation(company1_id UUID, company2_id UUID)
RETURNS TABLE (
    test_name TEXT,
    result BOOLEAN,
    description TEXT
) AS $$
DECLARE
    company1_building_count BIGINT;
    company2_building_count BIGINT;
    cross_access_count BIGINT;
BEGIN
    -- 회사 1 컨텍스트에서 건물 수 확인
    PERFORM set_company_context(company1_id);
    SELECT COUNT(*) INTO company1_building_count FROM buildings;
    
    -- 회사 2 컨텍스트에서 건물 수 확인
    PERFORM set_company_context(company2_id);
    SELECT COUNT(*) INTO company2_building_count FROM buildings;
    
    -- 회사 1 컨텍스트에서 회사 2 데이터 접근 시도
    PERFORM set_company_context(company1_id);
    SELECT COUNT(*) INTO cross_access_count 
    FROM buildings 
    WHERE company_id = company2_id;
    
    -- 테스트 결과 반환
    RETURN QUERY
    SELECT 
        'company1_data_access'::TEXT,
        company1_building_count > 0,
        format('회사 1에서 %s개 건물 접근 가능', company1_building_count);
    
    RETURN QUERY
    SELECT 
        'company2_data_access'::TEXT,
        company2_building_count > 0,
        format('회사 2에서 %s개 건물 접근 가능', company2_building_count);
    
    RETURN QUERY
    SELECT 
        'cross_company_isolation'::TEXT,
        cross_access_count = 0,
        format('회사 간 데이터 격리 테스트: %s', 
            CASE WHEN cross_access_count = 0 THEN '성공' ELSE '실패' END);
    
    -- 컨텍스트 초기화
    PERFORM clear_company_context();
END;
$$ LANGUAGE plpgsql;

-- 9. 마이그레이션 실행 순서 가이드 함수
CREATE OR REPLACE FUNCTION get_migration_guide()
RETURNS TABLE (
    step_number INTEGER,
    script_name TEXT,
    description TEXT,
    dependencies TEXT
) AS $$
BEGIN
    RETURN QUERY VALUES
    (1, 'companies_users_roles.sql', '기본 조직 및 사용자 구조 생성', '없음'),
    (2, 'building_groups_management.sql', '건물 그룹 관리 시스템 생성', '1단계 완료'),
    (3, 'business_verification.sql', '사업자 인증 시스템 생성', '1단계 완료'),
    (4, 'migration_buildings_multitenancy.sql', '건물 테이블 멀티테넌시 적용', '1-3단계 완료'),
    (5, 'migration_users_multitenancy.sql', '사용자 테이블 멀티테넌시 적용', '4단계 완료'),
    (6, 'migration_billing_lease_multitenancy.sql', '관리비/임대차 테이블 멀티테넌시 적용', '5단계 완료'),
    (7, 'row_level_security_policies.sql', 'RLS 정책 최종 적용', '6단계 완료'),
    (8, 'multitenancy_setup.sql', '멀티테넌시 통합 설정', '7단계 완료');
END;
$$ LANGUAGE plpgsql;

-- 10. 개발/테스트용 샘플 데이터 생성 함수
CREATE OR REPLACE FUNCTION create_sample_multitenancy_data()
RETURNS VOID AS $$
DECLARE
    company1_id UUID;
    company2_id UUID;
    user1_id UUID;
    user2_id UUID;
BEGIN
    -- 샘플 회사 1 생성
    INSERT INTO companies (
        business_registration_number,
        company_name,
        representative_name,
        business_address,
        contact_phone,
        contact_email,
        business_type,
        establishment_date,
        verification_status
    ) VALUES (
        '123-45-67890',
        '테스트 부동산 관리회사 A',
        '김관리',
        '서울특별시 강남구 테헤란로 123',
        '02-1234-5678',
        'admin@company-a.com',
        '부동산 관리업',
        '2020-01-01',
        'VERIFIED'
    ) RETURNING company_id INTO company1_id;
    
    -- 샘플 회사 2 생성
    INSERT INTO companies (
        business_registration_number,
        company_name,
        representative_name,
        business_address,
        contact_phone,
        contact_email,
        business_type,
        establishment_date,
        verification_status
    ) VALUES (
        '987-65-43210',
        '테스트 부동산 관리회사 B',
        '이관리',
        '서울특별시 서초구 서초대로 456',
        '02-9876-5432',
        'admin@company-b.com',
        '부동산 관리업',
        '2021-01-01',
        'VERIFIED'
    ) RETURNING company_id INTO company2_id;
    
    -- 회사 1 관리자 생성
    PERFORM set_company_context(company1_id);
    SELECT create_user(
        'admin@company-a.com',
        '$2a$10$example.hash.for.testing',
        '김관리',
        '010-1234-5678',
        'SUPER_ADMIN',
        '관리팀',
        '대표'
    ) INTO user1_id;
    
    -- 회사 2 관리자 생성
    PERFORM set_company_context(company2_id);
    SELECT create_user(
        'admin@company-b.com',
        '$2a$10$example.hash.for.testing',
        '이관리',
        '010-9876-5432',
        'SUPER_ADMIN',
        '관리팀',
        '대표'
    ) INTO user2_id;
    
    -- 샘플 건물 생성
    PERFORM set_company_context(company1_id);
    INSERT INTO buildings (
        company_id,
        name,
        address,
        building_type,
        total_floors,
        total_area,
        total_units,
        construction_year,
        status
    ) VALUES (
        company1_id,
        '테스트 아파트 A동',
        '서울특별시 강남구 테스트로 100',
        'APARTMENT',
        15,
        5000.00,
        60,
        2018,
        'ACTIVE'
    );
    
    PERFORM set_company_context(company2_id);
    INSERT INTO buildings (
        company_id,
        name,
        address,
        building_type,
        total_floors,
        total_area,
        total_units,
        construction_year,
        status
    ) VALUES (
        company2_id,
        '테스트 오피스텔 B동',
        '서울특별시 서초구 테스트대로 200',
        'MIXED_USE',
        20,
        8000.00,
        100,
        2020,
        'ACTIVE'
    );
    
    PERFORM clear_company_context();
    
    RAISE NOTICE '샘플 멀티테넌시 데이터 생성 완료';
    RAISE NOTICE '회사 1 ID: %', company1_id;
    RAISE NOTICE '회사 2 ID: %', company2_id;
END;
$$ LANGUAGE plpgsql;

-- 11. 멀티테넌시 설정 완료 확인
DO $$
BEGIN
    RAISE NOTICE '=== QIRO 멀티테넌시 통합 설정 완료 ===';
    RAISE NOTICE '1. 애플리케이션 역할 설정 완료';
    RAISE NOTICE '2. 조직 컨텍스트 관리 함수 생성 완료';
    RAISE NOTICE '3. 멀티테넌시 상태 확인 함수 생성 완료';
    RAISE NOTICE '4. 데이터 격리 테스트 함수 생성 완료';
    RAISE NOTICE '5. 마이그레이션 가이드 함수 생성 완료';
    RAISE NOTICE '';
    RAISE NOTICE '=== 사용 가능한 함수들 ===';
    RAISE NOTICE '- check_multitenancy_status(): 멀티테넌시 상태 확인';
    RAISE NOTICE '- get_system_multitenancy_stats(): 시스템 통계';
    RAISE NOTICE '- get_migration_guide(): 마이그레이션 실행 순서';
    RAISE NOTICE '- create_sample_multitenancy_data(): 샘플 데이터 생성';
    RAISE NOTICE '- test_company_isolation(uuid, uuid): 격리 테스트';
    RAISE NOTICE '';
    RAISE NOTICE '=== 회사 컨텍스트 관리 ===';
    RAISE NOTICE '- set_company_context(uuid): 회사 컨텍스트 설정';
    RAISE NOTICE '- get_current_company_id(): 현재 회사 ID 조회';
    RAISE NOTICE '- clear_company_context(): 컨텍스트 초기화';
END $$;