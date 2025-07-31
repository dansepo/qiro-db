-- =====================================================
-- 성능 및 부하 테스트 데이터 생성 (수정된 버전)
-- QIRO 사업자 회원가입 시스템
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 수정일: 2025-01-31 (실제 DB 적용 후 수정)
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;
SET search_path TO bms;

-- =====================================================
-- 1. 대용량 테스트 데이터 생성 함수 (수정된 버전)
-- =====================================================

-- 대용량 회사 데이터 생성 함수
CREATE OR REPLACE FUNCTION generate_test_companies(company_count INTEGER DEFAULT 1000)
RETURNS VOID AS $$
DECLARE
    i INTEGER;
    business_number TEXT;
    company_name TEXT;
    representative_name TEXT;
    contact_email TEXT;
    contact_phone TEXT;
    business_address TEXT;
BEGIN
    RAISE NOTICE '대용량 회사 데이터 생성 시작: % 개', company_count;
    
    FOR i IN 1..company_count LOOP
        -- 유효한 사업자등록번호 생성 (간단한 패턴 사용)
        business_number := LPAD((1000000000 + i)::TEXT, 10, '0');
        
        -- 테스트 데이터 생성
        company_name := '성능테스트회사' || i;
        representative_name := '대표자' || i;
        contact_email := 'company' || i || '@test.com';
        contact_phone := '02-' || LPAD(i::TEXT, 8, '0');
        business_address := '서울시 강남구 테스트로 ' || i;
        
        INSERT INTO companies (
            business_registration_number, company_name, representative_name,
            business_address, contact_phone, contact_email, business_type,
            establishment_date, verification_status, subscription_status
        ) VALUES (
            business_number, company_name, representative_name,
            business_address, contact_phone, contact_email, '부동산임대업',
            '2020-01-01'::DATE + (i % 1000)::INTEGER, 
            'VERIFIED'::verification_status, 'ACTIVE'::subscription_status
        );
        
        -- 진행 상황 출력 (100개마다)
        IF i % 100 = 0 THEN
            RAISE NOTICE '회사 데이터 생성 진행: %/%', i, company_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 회사 데이터 생성 완료: % 개', company_count;
END;
$$ LANGUAGE plpgsql;

-- 대용량 사용자 데이터 생성 함수 (수정된 버전)
CREATE OR REPLACE FUNCTION generate_test_users(users_per_company INTEGER DEFAULT 3)
RETURNS VOID AS $$
DECLARE
    company_rec RECORD;
    i INTEGER;
    user_email TEXT;
    user_name TEXT;
    user_phone TEXT;
    user_count INTEGER := 0;
    company_number INTEGER := 0;
    new_role_id UUID;
    new_user_id UUID;
    user_type_val user_type;
    user_status_val user_status;
BEGIN
    RAISE NOTICE '대용량 사용자 데이터 생성 시작: 회사당 % 명', users_per_company;
    
    FOR company_rec IN 
        SELECT company_id, company_name 
        FROM companies 
        WHERE company_name LIKE '성능테스트회사%' 
        ORDER BY company_name 
    LOOP
        company_number := company_number + 1;
        
        -- 각 회사에 기본 역할이 없으면 생성
        SELECT r.role_id INTO new_role_id 
        FROM roles r 
        WHERE r.company_id = company_rec.company_id AND r.role_code = 'SUPER_ADMIN';
        
        IF new_role_id IS NULL THEN
            INSERT INTO roles (company_id, role_name, role_code, description, is_system_role)
            VALUES (
                company_rec.company_id, '총괄관리자', 'SUPER_ADMIN', 
                '시스템 전체 관리자', true
            ) RETURNING roles.role_id INTO new_role_id;
        END IF;
        
        FOR i IN 1..users_per_company LOOP
            user_count := user_count + 1;
            user_email := 'perfuser' || user_count || '@company' || company_number || '.test';
            user_name := '성능사용자' || user_count;
            user_phone := '010-' || LPAD((user_count % 10000)::TEXT, 4, '0') || '-' || LPAD(((user_count + 1000) % 10000)::TEXT, 4, '0');
            
            -- ENUM 값 설정 (타입 캐스팅 명시)
            IF i = 1 THEN
                user_type_val := 'SUPER_ADMIN'::user_type;
            ELSE
                user_type_val := 'EMPLOYEE'::user_type;
            END IF;
            user_status_val := 'ACTIVE'::user_status;
            
            INSERT INTO users (
                company_id, email, password_hash, full_name,
                phone_number, user_type, status, email_verified
            ) VALUES (
                company_rec.company_id, user_email, '$2a$10$example.hash',
                user_name, user_phone, user_type_val, user_status_val, true
            ) RETURNING users.user_id INTO new_user_id;
            
            -- 첫 번째 사용자는 관리자 역할 부여
            IF i = 1 THEN
                INSERT INTO user_role_links (user_id, role_id)
                VALUES (new_user_id, new_role_id);
            END IF;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF company_number % 100 = 0 THEN
            RAISE NOTICE '사용자 데이터 생성 진행: % 개 회사, % 명 사용자', company_number, user_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 사용자 데이터 생성 완료: % 개 회사, % 명 사용자', company_number, user_count;
END;
$$ LANGUAGE plpgsql;

-- 대용량 건물 데이터 생성 함수 (수정된 버전)
CREATE OR REPLACE FUNCTION generate_test_buildings(buildings_per_company INTEGER DEFAULT 2)
RETURNS VOID AS $$
DECLARE
    company_rec RECORD;
    i INTEGER;
    building_name TEXT;
    building_address TEXT;
    building_count INTEGER := 0;
    company_number INTEGER := 0;
BEGIN
    RAISE NOTICE '대용량 건물 데이터 생성 시작: 회사당 % 개', buildings_per_company;
    
    FOR company_rec IN 
        SELECT company_id, company_name 
        FROM companies 
        WHERE company_name LIKE '성능테스트회사%' 
        ORDER BY company_name 
    LOOP
        company_number := company_number + 1;
        
        FOR i IN 1..buildings_per_company LOOP
            building_name := company_rec.company_name || ' 건물' || i;
            building_address := '서울시 강남구 ' || company_rec.company_name || '로 ' || (i * 100);
            
            INSERT INTO buildings (
                company_id, name, address, building_type,
                total_floors, total_area, total_units, status
            ) VALUES (
                company_rec.company_id, building_name, building_address,
                CASE (i % 3) 
                    WHEN 0 THEN 'APARTMENT'
                    WHEN 1 THEN 'COMMERCIAL'
                    ELSE 'MIXED_USE'
                END,
                5 + (i % 15), -- 5~20층
                1000.00 + (i * 500), -- 1000~2500㎡
                20 + (i * 10), -- 20~50호실
                'ACTIVE'
            );
            
            building_count := building_count + 1;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF company_number % 100 = 0 THEN
            RAISE NOTICE '건물 데이터 생성 진행: % 개 회사, % 개 건물', company_number, building_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 건물 데이터 생성 완료: % 개 회사, % 개 건물', company_number, building_count;
END;
$$ LANGUAGE plpgsql;

-- 대용량 건물 그룹 데이터 생성 함수 (수정된 버전)
CREATE OR REPLACE FUNCTION generate_test_building_groups(groups_per_company INTEGER DEFAULT 2)
RETURNS VOID AS $$
DECLARE
    company_rec RECORD;
    i INTEGER;
    group_name TEXT;
    group_count INTEGER := 0;
    company_number INTEGER := 0;
    group_type_val group_type;
BEGIN
    RAISE NOTICE '대용량 건물 그룹 데이터 생성 시작: 회사당 % 개', groups_per_company;
    
    FOR company_rec IN 
        SELECT company_id, company_name 
        FROM companies 
        WHERE company_name LIKE '성능테스트회사%' 
        ORDER BY company_name 
    LOOP
        company_number := company_number + 1;
        
        FOR i IN 1..groups_per_company LOOP
            group_name := company_rec.company_name || ' 그룹' || i;
            
            -- 그룹 타입 설정 (ENUM 타입 캐스팅)
            CASE (i % 4)
                WHEN 0 THEN group_type_val := 'COST_ALLOCATION'::group_type;
                WHEN 1 THEN group_type_val := 'MANAGEMENT_UNIT'::group_type;
                WHEN 2 THEN group_type_val := 'GEOGRAPHIC'::group_type;
                ELSE group_type_val := 'CUSTOM'::group_type;
            END CASE;
            
            INSERT INTO building_groups (
                company_id, group_name, group_type, description
            ) VALUES (
                company_rec.company_id, group_name, group_type_val,
                '성능 테스트용 ' || group_name
            );
            
            group_count := group_count + 1;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF company_number % 100 = 0 THEN
            RAISE NOTICE '건물 그룹 데이터 생성 진행: % 개 회사, % 개 그룹', company_number, group_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 건물 그룹 데이터 생성 완료: % 개 회사, % 개 그룹', company_number, group_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 테스트 데이터 생성 실행 함수 (수정된 버전)
-- =====================================================

-- 테스트 데이터 생성 함수 (전체)
CREATE OR REPLACE FUNCTION setup_performance_test_data(
    company_count INTEGER DEFAULT 1000,
    users_per_company INTEGER DEFAULT 3,
    buildings_per_company INTEGER DEFAULT 2,
    groups_per_company INTEGER DEFAULT 2
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
BEGIN
    start_time := clock_timestamp();
    
    RAISE NOTICE '=== 성능 테스트 데이터 생성 시작 ===';
    RAISE NOTICE '회사: % 개, 회사당 사용자: % 명, 회사당 건물: % 개, 회사당 그룹: % 개', 
        company_count, users_per_company, buildings_per_company, groups_per_company;
    
    -- 1. 회사 데이터 생성
    PERFORM generate_test_companies(company_count);
    
    -- 2. 사용자 데이터 생성
    PERFORM generate_test_users(users_per_company);
    
    -- 3. 건물 데이터 생성
    PERFORM generate_test_buildings(buildings_per_company);
    
    -- 4. 건물 그룹 데이터 생성
    PERFORM generate_test_building_groups(groups_per_company);
    
    end_time := clock_timestamp();
    
    RAISE NOTICE '=== 성능 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 소요 시간: %', end_time - start_time;
    
    -- 생성된 데이터 통계 출력
    RAISE NOTICE '';
    RAISE NOTICE '생성된 데이터 통계:';
    RAISE NOTICE '- 회사: % 개', (SELECT COUNT(*) FROM companies WHERE company_name LIKE '성능테스트회사%');
    RAISE NOTICE '- 사용자: % 명', (SELECT COUNT(*) FROM users u JOIN companies c ON u.company_id = c.company_id WHERE c.company_name LIKE '성능테스트회사%');
    RAISE NOTICE '- 건물: % 개', (SELECT COUNT(*) FROM buildings b JOIN companies c ON b.company_id = c.company_id WHERE c.company_name LIKE '성능테스트회사%');
    RAISE NOTICE '- 건물 그룹: % 개', (SELECT COUNT(*) FROM building_groups bg JOIN companies c ON bg.company_id = c.company_id WHERE c.company_name LIKE '성능테스트회사%');
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 테스트 데이터 정리 함수 (수정된 버전)
-- =====================================================

-- 성능 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_performance_test_data()
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    deleted_companies INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    RAISE NOTICE '=== 성능 테스트 데이터 정리 시작 ===';
    
    -- 테스트 데이터 삭제 (CASCADE로 관련 데이터도 함께 삭제됨)
    DELETE FROM companies WHERE company_name LIKE '성능테스트회사%';
    GET DIAGNOSTICS deleted_companies = ROW_COUNT;
    
    -- 함수들 삭제
    DROP FUNCTION IF EXISTS generate_test_companies(INTEGER);
    DROP FUNCTION IF EXISTS generate_test_users(INTEGER);
    DROP FUNCTION IF EXISTS generate_test_buildings(INTEGER);
    DROP FUNCTION IF EXISTS generate_test_building_groups(INTEGER);
    DROP FUNCTION IF EXISTS setup_performance_test_data(INTEGER, INTEGER, INTEGER, INTEGER);
    DROP FUNCTION IF EXISTS cleanup_performance_test_data();
    
    end_time := clock_timestamp();
    
    RAISE NOTICE '=== 성능 테스트 데이터 정리 완료 ===';
    RAISE NOTICE '삭제된 회사: % 개', deleted_companies;
    RAISE NOTICE '총 소요 시간: %', end_time - start_time;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 사용법 안내
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== 성능 테스트 데이터 생성 시스템 준비 완료 ===';
    RAISE NOTICE '';
    RAISE NOTICE '사용법:';
    RAISE NOTICE '1. 소규모 테스트 데이터 생성 (100개 회사):';
    RAISE NOTICE '   SELECT setup_performance_test_data(100, 2, 1, 1);';
    RAISE NOTICE '';
    RAISE NOTICE '2. 중간 규모 테스트 데이터 생성 (500개 회사):';
    RAISE NOTICE '   SELECT setup_performance_test_data(500, 3, 2, 2);';
    RAISE NOTICE '';
    RAISE NOTICE '3. 대규모 테스트 데이터 생성 (1000개 회사):';
    RAISE NOTICE '   SELECT setup_performance_test_data(1000, 5, 3, 2);';
    RAISE NOTICE '';
    RAISE NOTICE '4. 테스트 데이터 정리:';
    RAISE NOTICE '   SELECT cleanup_performance_test_data();';
    RAISE NOTICE '';
    RAISE NOTICE '주요 수정사항:';
    RAISE NOTICE '- ENUM 타입 명시적 캐스팅 추가';
    RAISE NOTICE '- 변수명 충돌 해결';
    RAISE NOTICE '- 외래키 제약조건 고려';
    RAISE NOTICE '- 진행 상황 모니터링 개선';
END
$$;