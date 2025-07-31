-- =====================================================
-- 성능 및 부하 테스트 데이터 생성
-- QIRO 사업자 회원가입 시스템
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;

-- =====================================================
-- 1. 대용량 테스트 데이터 생성 함수
-- =====================================================

-- 대용량 회사 데이터 생성 함수
CREATE OR REPLACE FUNCTION generate_test_companies(company_count INTEGER DEFAULT 1000)
RETURNS VOID AS $
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
        company_name := '테스트회사' || i;
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
            '2020-01-01'::DATE + (i % 1000)::INTEGER, 'VERIFIED', 'ACTIVE'
        );
        
        -- 진행 상황 출력 (100개마다)
        IF i % 100 = 0 THEN
            RAISE NOTICE '회사 데이터 생성 진행: %/%', i, company_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 회사 데이터 생성 완료: % 개', company_count;
END;
$ LANGUAGE plpgsql;

-- 대용량 사용자 데이터 생성 함수
CREATE OR REPLACE FUNCTION generate_test_users(users_per_company INTEGER DEFAULT 5)
RETURNS VOID AS $
DECLARE
    company_rec RECORD;
    i INTEGER;
    user_email TEXT;
    user_name TEXT;
    user_phone TEXT;
    user_count INTEGER := 0;
BEGIN
    RAISE NOTICE '대용량 사용자 데이터 생성 시작: 회사당 % 명', users_per_company;
    
    FOR company_rec IN SELECT company_id, company_name FROM companies WHERE company_name LIKE '테스트회사%' LOOP
        FOR i IN 1..users_per_company LOOP
            user_email := 'user' || user_count || '@' || LOWER(REPLACE(company_rec.company_name, '테스트회사', 'company')) || '.com';
            user_name := '사용자' || user_count;
            user_phone := '010-' || LPAD(user_count::TEXT, 8, '0');
            
            INSERT INTO users (
                company_id, email, password_hash, full_name,
                phone_number, user_type, status, email_verified
            ) VALUES (
                company_rec.company_id, user_email, '$2a$10$example.hash',
                user_name, user_phone,
                CASE WHEN i = 1 THEN 'SUPER_ADMIN' ELSE 'EMPLOYEE' END,
                'ACTIVE', true
            );
            
            user_count := user_count + 1;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF user_count % (100 * users_per_company) = 0 THEN
            RAISE NOTICE '사용자 데이터 생성 진행: % 명', user_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 사용자 데이터 생성 완료: % 명', user_count;
END;
$ LANGUAGE plpgsql;

-- 대용량 건물 데이터 생성 함수
CREATE OR REPLACE FUNCTION generate_test_buildings(buildings_per_company INTEGER DEFAULT 3)
RETURNS VOID AS $
DECLARE
    company_rec RECORD;
    i INTEGER;
    building_name TEXT;
    building_address TEXT;
    building_count INTEGER := 0;
BEGIN
    RAISE NOTICE '대용량 건물 데이터 생성 시작: 회사당 % 개', buildings_per_company;
    
    FOR company_rec IN SELECT company_id, company_name FROM companies WHERE company_name LIKE '테스트회사%' LOOP
        FOR i IN 1..buildings_per_company LOOP
            building_name := company_rec.company_name || ' 건물' || i;
            building_address := '서울시 강남구 ' || company_rec.company_name || '로 ' || (i * 100);
            
            INSERT INTO buildings (
                company_id, name, address, building_type,
                total_floors, total_area, total_units,
                construction_year, status
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
                2015 + (i % 8), -- 2015~2023년
                'ACTIVE'
            );
            
            building_count := building_count + 1;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF building_count % (100 * buildings_per_company) = 0 THEN
            RAISE NOTICE '건물 데이터 생성 진행: % 개', building_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 건물 데이터 생성 완료: % 개', building_count;
END;
$ LANGUAGE plpgsql;

-- 대용량 건물 그룹 데이터 생성 함수
CREATE OR REPLACE FUNCTION generate_test_building_groups(groups_per_company INTEGER DEFAULT 2)
RETURNS VOID AS $
DECLARE
    company_rec RECORD;
    i INTEGER;
    group_name TEXT;
    group_count INTEGER := 0;
BEGIN
    RAISE NOTICE '대용량 건물 그룹 데이터 생성 시작: 회사당 % 개', groups_per_company;
    
    FOR company_rec IN SELECT company_id, company_name FROM companies WHERE company_name LIKE '테스트회사%' LOOP
        FOR i IN 1..groups_per_company LOOP
            group_name := company_rec.company_name || ' 그룹' || i;
            
            INSERT INTO building_groups (
                company_id, group_name, group_type, description
            ) VALUES (
                company_rec.company_id, group_name,
                CASE (i % 4)
                    WHEN 0 THEN 'COST_ALLOCATION'
                    WHEN 1 THEN 'MANAGEMENT_UNIT'
                    WHEN 2 THEN 'GEOGRAPHIC'
                    ELSE 'CUSTOM'
                END,
                '테스트용 ' || group_name
            );
            
            group_count := group_count + 1;
        END LOOP;
        
        -- 진행 상황 출력 (100개 회사마다)
        IF group_count % (100 * groups_per_company) = 0 THEN
            RAISE NOTICE '건물 그룹 데이터 생성 진행: % 개', group_count;
        END IF;
    END LOOP;
    
    RAISE NOTICE '대용량 건물 그룹 데이터 생성 완료: % 개', group_count;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 테스트 데이터 생성 실행
-- =====================================================

-- 테스트 데이터 생성 함수 (전체)
CREATE OR REPLACE FUNCTION setup_performance_test_data(
    company_count INTEGER DEFAULT 1000,
    users_per_company INTEGER DEFAULT 5,
    buildings_per_company INTEGER DEFAULT 3,
    groups_per_company INTEGER DEFAULT 2
)
RETURNS VOID AS $
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
    RAISE NOTICE '- 회사: % 개', (SELECT COUNT(*) FROM companies WHERE company_name LIKE '테스트회사%');
    RAISE NOTICE '- 사용자: % 명', (SELECT COUNT(*) FROM users u JOIN companies c ON u.company_id = c.company_id WHERE c.company_name LIKE '테스트회사%');
    RAISE NOTICE '- 건물: % 개', (SELECT COUNT(*) FROM buildings b JOIN companies c ON b.company_id = c.company_id WHERE c.company_name LIKE '테스트회사%');
    RAISE NOTICE '- 건물 그룹: % 개', (SELECT COUNT(*) FROM building_groups bg JOIN companies c ON bg.company_id = c.company_id WHERE c.company_name LIKE '테스트회사%');
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 테스트 데이터 정리 함수
-- =====================================================

-- 성능 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_performance_test_data()
RETURNS VOID AS $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    deleted_companies INTEGER;
BEGIN
    start_time := clock_timestamp();
    
    RAISE NOTICE '=== 성능 테스트 데이터 정리 시작 ===';
    
    -- 테스트 데이터 삭제 (CASCADE로 관련 데이터도 함께 삭제됨)
    DELETE FROM companies WHERE company_name LIKE '테스트회사%';
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
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 테스트 데이터 생성 실행 (기본값 사용)
-- =====================================================

-- 성능 테스트용 데이터 생성 (소규모 - 100개 회사)
-- SELECT setup_performance_test_data(100, 3, 2, 1);

-- 성능 테스트용 데이터 생성 (중간 규모 - 500개 회사)
-- SELECT setup_performance_test_data(500, 5, 3, 2);

-- 성능 테스트용 데이터 생성 (대규모 - 1000개 회사)
-- SELECT setup_performance_test_data(1000, 5, 3, 2);

-- 테스트 완료 후 정리 (필요시 주석 해제)
-- SELECT cleanup_performance_test_data();