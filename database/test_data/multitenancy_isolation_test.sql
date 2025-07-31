-- =====================================================
-- 멀티테넌시 데이터 격리 테스트
-- QIRO 사업자 회원가입 시스템
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;

-- =====================================================
-- 1. 테스트 데이터 준비
-- =====================================================

-- 테스트용 회사 데이터 생성
DO $
DECLARE
    company1_id UUID;
    company2_id UUID;
    user1_id UUID;
    user2_id UUID;
    building1_id UUID;
    building2_id UUID;
    group1_id UUID;
    group2_id UUID;
BEGIN
    -- 회사 1 생성
    INSERT INTO companies (
        company_id, business_registration_number, company_name, 
        representative_name, business_address, contact_phone, 
        contact_email, business_type, establishment_date,
        verification_status
    ) VALUES (
        gen_random_uuid(), '1234567890', '테스트회사1',
        '김대표', '서울시 강남구 테헤란로 123', '02-1234-5678',
        'test1@company1.com', '부동산임대업', '2020-01-01',
        'VERIFIED'
    ) RETURNING company_id INTO company1_id;

    -- 회사 2 생성
    INSERT INTO companies (
        company_id, business_registration_number, company_name, 
        representative_name, business_address, contact_phone, 
        contact_email, business_type, establishment_date,
        verification_status
    ) VALUES (
        gen_random_uuid(), '9876543210', '테스트회사2',
        '박대표', '서울시 서초구 서초대로 456', '02-9876-5432',
        'test2@company2.com', '부동산관리업', '2021-01-01',
        'VERIFIED'
    ) RETURNING company_id INTO company2_id;

    -- 사용자 1 생성 (회사 1 소속)
    INSERT INTO users (
        user_id, company_id, email, password_hash, full_name,
        phone_number, user_type, status
    ) VALUES (
        gen_random_uuid(), company1_id, 'admin1@company1.com',
        '$2a$10$example.hash1', '관리자1', '010-1234-5678',
        'SUPER_ADMIN', 'ACTIVE'
    ) RETURNING user_id INTO user1_id;

    -- 사용자 2 생성 (회사 2 소속)
    INSERT INTO users (
        user_id, company_id, email, password_hash, full_name,
        phone_number, user_type, status
    ) VALUES (
        gen_random_uuid(), company2_id, 'admin2@company2.com',
        '$2a$10$example.hash2', '관리자2', '010-9876-5432',
        'SUPER_ADMIN', 'ACTIVE'
    ) RETURNING user_id INTO user2_id;

    -- 건물 1 생성 (회사 1 소속)
    INSERT INTO buildings (
        building_id, company_id, name, address, building_type,
        total_floors, total_area, total_units
    ) VALUES (
        gen_random_uuid(), company1_id, '테스트빌딩1', 
        '서울시 강남구 역삼동 123-45', 'APARTMENT',
        10, 5000.00, 50
    ) RETURNING building_id INTO building1_id;

    -- 건물 2 생성 (회사 2 소속)
    INSERT INTO buildings (
        building_id, company_id, name, address, building_type,
        total_floors, total_area, total_units
    ) VALUES (
        gen_random_uuid(), company2_id, '테스트빌딩2', 
        '서울시 서초구 서초동 789-12', 'COMMERCIAL',
        15, 8000.00, 80
    ) RETURNING building_id INTO building2_id;

    -- 건물 그룹 1 생성 (회사 1 소속)
    INSERT INTO building_groups (
        group_id, company_id, group_name, group_type, description
    ) VALUES (
        gen_random_uuid(), company1_id, '강남권 관리그룹', 
        'MANAGEMENT_UNIT', '강남구 소재 건물 관리 그룹'
    ) RETURNING group_id INTO group1_id;

    -- 건물 그룹 2 생성 (회사 2 소속)
    INSERT INTO building_groups (
        group_id, company_id, group_name, group_type, description
    ) VALUES (
        gen_random_uuid(), company2_id, '서초권 관리그룹', 
        'MANAGEMENT_UNIT', '서초구 소재 건물 관리 그룹'
    ) RETURNING group_id INTO group2_id;

    -- 테스트 변수 저장 (임시 테이블 사용)
    CREATE TEMP TABLE test_variables (
        company1_id UUID,
        company2_id UUID,
        user1_id UUID,
        user2_id UUID,
        building1_id UUID,
        building2_id UUID,
        group1_id UUID,
        group2_id UUID
    );

    INSERT INTO test_variables VALUES (
        company1_id, company2_id, user1_id, user2_id,
        building1_id, building2_id, group1_id, group2_id
    );

    RAISE NOTICE '테스트 데이터 생성 완료';
    RAISE NOTICE '회사1 ID: %', company1_id;
    RAISE NOTICE '회사2 ID: %', company2_id;
END
$;

-- =====================================================
-- 2. RLS 정책 동작 테스트
-- =====================================================

-- 테스트 함수: 조직별 데이터 격리 검증
CREATE OR REPLACE FUNCTION test_company_data_isolation()
RETURNS TABLE (
    test_name TEXT,
    expected_result INTEGER,
    actual_result INTEGER,
    test_passed BOOLEAN,
    notes TEXT
) AS $
DECLARE
    company1_id UUID;
    company2_id UUID;
    test_count INTEGER;
BEGIN
    -- 테스트 변수 가져오기
    SELECT tv.company1_id, tv.company2_id 
    INTO company1_id, company2_id
    FROM test_variables tv;

    -- 테스트 1: 회사1 컨텍스트에서 회사 데이터 조회
    PERFORM set_config('app.current_company_id', company1_id::TEXT, false);
    
    SELECT COUNT(*) INTO test_count FROM companies;
    RETURN QUERY SELECT 
        '회사1 컨텍스트에서 companies 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사1 데이터만 조회되어야 함'::TEXT;

    -- 테스트 2: 회사1 컨텍스트에서 사용자 데이터 조회
    SELECT COUNT(*) INTO test_count FROM users;
    RETURN QUERY SELECT 
        '회사1 컨텍스트에서 users 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사1 소속 사용자만 조회되어야 함'::TEXT;

    -- 테스트 3: 회사1 컨텍스트에서 건물 데이터 조회
    SELECT COUNT(*) INTO test_count FROM buildings;
    RETURN QUERY SELECT 
        '회사1 컨텍스트에서 buildings 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사1 소속 건물만 조회되어야 함'::TEXT;

    -- 테스트 4: 회사1 컨텍스트에서 건물 그룹 데이터 조회
    SELECT COUNT(*) INTO test_count FROM building_groups;
    RETURN QUERY SELECT 
        '회사1 컨텍스트에서 building_groups 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사1 소속 그룹만 조회되어야 함'::TEXT;

    -- 테스트 5: 회사2 컨텍스트로 변경
    PERFORM set_config('app.current_company_id', company2_id::TEXT, false);
    
    SELECT COUNT(*) INTO test_count FROM companies;
    RETURN QUERY SELECT 
        '회사2 컨텍스트에서 companies 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사2 데이터만 조회되어야 함'::TEXT;

    -- 테스트 6: 회사2 컨텍스트에서 사용자 데이터 조회
    SELECT COUNT(*) INTO test_count FROM users;
    RETURN QUERY SELECT 
        '회사2 컨텍스트에서 users 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사2 소속 사용자만 조회되어야 함'::TEXT;

    -- 테스트 7: 회사2 컨텍스트에서 건물 데이터 조회
    SELECT COUNT(*) INTO test_count FROM buildings;
    RETURN QUERY SELECT 
        '회사2 컨텍스트에서 buildings 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사2 소속 건물만 조회되어야 함'::TEXT;

    -- 테스트 8: 회사2 컨텍스트에서 건물 그룹 데이터 조회
    SELECT COUNT(*) INTO test_count FROM building_groups;
    RETURN QUERY SELECT 
        '회사2 컨텍스트에서 building_groups 테이블 조회'::TEXT,
        1::INTEGER,
        test_count::INTEGER,
        (test_count = 1)::BOOLEAN,
        '회사2 소속 그룹만 조회되어야 함'::TEXT;

    -- 컨텍스트 초기화
    PERFORM set_config('app.current_company_id', '', false);
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 권한 기반 접근 제어 테스트
-- =====================================================

-- 테스트 함수: 사용자 권한 검증
CREATE OR REPLACE FUNCTION test_user_permissions()
RETURNS TABLE (
    test_name TEXT,
    test_passed BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    company1_id UUID;
    company2_id UUID;
    user1_id UUID;
    user2_id UUID;
    test_result BOOLEAN;
    error_msg TEXT;
BEGIN
    -- 테스트 변수 가져오기
    SELECT tv.company1_id, tv.company2_id, tv.user1_id, tv.user2_id
    INTO company1_id, company2_id, user1_id, user2_id
    FROM test_variables tv;

    -- 테스트 1: 사용자1이 자신의 회사 데이터에 접근
    BEGIN
        PERFORM set_config('app.current_company_id', company1_id::TEXT, false);
        PERFORM set_config('app.current_user_id', user1_id::TEXT, false);
        
        PERFORM * FROM companies WHERE company_id = company1_id;
        test_result := true;
        error_msg := NULL;
    EXCEPTION WHEN OTHERS THEN
        test_result := false;
        error_msg := SQLERRM;
    END;

    RETURN QUERY SELECT 
        '사용자1의 자신 회사 데이터 접근'::TEXT,
        test_result,
        error_msg;

    -- 테스트 2: 사용자1이 다른 회사 데이터에 접근 시도 (실패해야 함)
    BEGIN
        PERFORM set_config('app.current_company_id', company2_id::TEXT, false);
        PERFORM set_config('app.current_user_id', user1_id::TEXT, false);
        
        PERFORM * FROM companies WHERE company_id = company2_id;
        test_result := false; -- 접근이 성공하면 테스트 실패
        error_msg := '다른 회사 데이터에 접근이 허용됨 (보안 위험)';
    EXCEPTION WHEN insufficient_privilege THEN
        test_result := true; -- 접근이 차단되면 테스트 성공
        error_msg := NULL;
    EXCEPTION WHEN OTHERS THEN
        test_result := false;
        error_msg := SQLERRM;
    END;

    RETURN QUERY SELECT 
        '사용자1의 다른 회사 데이터 접근 차단'::TEXT,
        test_result,
        error_msg;

    -- 컨텍스트 초기화
    PERFORM set_config('app.current_company_id', '', false);
    PERFORM set_config('app.current_user_id', '', false);
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 데이터 무결성 테스트
-- =====================================================

-- 테스트 함수: 외래키 제약조건 및 데이터 무결성 검증
CREATE OR REPLACE FUNCTION test_data_integrity()
RETURNS TABLE (
    test_name TEXT,
    test_passed BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    company1_id UUID;
    company2_id UUID;
    building1_id UUID;
    test_result BOOLEAN;
    error_msg TEXT;
BEGIN
    -- 테스트 변수 가져오기
    SELECT tv.company1_id, tv.company2_id, tv.building1_id
    INTO company1_id, company2_id, building1_id
    FROM test_variables tv;

    -- 테스트 1: 다른 회사의 건물에 사용자 배정 시도 (실패해야 함)
    BEGIN
        INSERT INTO user_group_assignments (
            user_id, group_id, access_level
        ) SELECT 
            (SELECT user_id FROM users WHERE company_id = company2_id LIMIT 1),
            (SELECT group_id FROM building_groups WHERE company_id = company1_id LIMIT 1),
            'read';
        
        test_result := false; -- 삽입이 성공하면 테스트 실패
        error_msg := '다른 회사 그룹에 사용자 배정이 허용됨 (데이터 무결성 위반)';
    EXCEPTION WHEN foreign_key_violation OR check_violation THEN
        test_result := true; -- 제약조건 위반으로 차단되면 테스트 성공
        error_msg := NULL;
    EXCEPTION WHEN OTHERS THEN
        test_result := false;
        error_msg := SQLERRM;
    END;

    RETURN QUERY SELECT 
        '다른 회사 그룹에 사용자 배정 차단'::TEXT,
        test_result,
        error_msg;

    -- 테스트 2: 사업자등록번호 중복 등록 시도 (실패해야 함)
    BEGIN
        INSERT INTO companies (
            business_registration_number, company_name, 
            representative_name, business_address, contact_phone, 
            contact_email, business_type, establishment_date
        ) VALUES (
            '1234567890', '중복테스트회사',
            '중복대표', '서울시 중구 중복로 123', '02-0000-0000',
            'duplicate@test.com', '중복업종', '2022-01-01'
        );
        
        test_result := false; -- 삽입이 성공하면 테스트 실패
        error_msg := '중복 사업자등록번호 등록이 허용됨 (유니크 제약조건 위반)';
    EXCEPTION WHEN unique_violation THEN
        test_result := true; -- 유니크 제약조건 위반으로 차단되면 테스트 성공
        error_msg := NULL;
    EXCEPTION WHEN OTHERS THEN
        test_result := false;
        error_msg := SQLERRM;
    END;

    RETURN QUERY SELECT 
        '사업자등록번호 중복 등록 차단'::TEXT,
        test_result,
        error_msg;

    -- 테스트 3: 잘못된 사업자등록번호 등록 시도 (실패해야 함)
    BEGIN
        INSERT INTO companies (
            business_registration_number, company_name, 
            representative_name, business_address, contact_phone, 
            contact_email, business_type, establishment_date
        ) VALUES (
            '1234567899', '잘못된번호회사', -- 체크섬이 맞지 않는 번호
            '잘못대표', '서울시 중구 잘못로 123', '02-1111-1111',
            'wrong@test.com', '잘못업종', '2022-01-01'
        );
        
        test_result := false; -- 삽입이 성공하면 테스트 실패
        error_msg := '잘못된 사업자등록번호 등록이 허용됨 (체크섬 검증 실패)';
    EXCEPTION WHEN check_violation THEN
        test_result := true; -- 체크 제약조건 위반으로 차단되면 테스트 성공
        error_msg := NULL;
    EXCEPTION WHEN OTHERS THEN
        test_result := false;
        error_msg := SQLERRM;
    END;

    RETURN QUERY SELECT 
        '잘못된 사업자등록번호 등록 차단'::TEXT,
        test_result,
        error_msg;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 테스트 실행 및 결과 출력
-- =====================================================

-- 테스트 결과 요약 함수
CREATE OR REPLACE FUNCTION run_multitenancy_isolation_tests()
RETURNS TABLE (
    test_category TEXT,
    total_tests INTEGER,
    passed_tests INTEGER,
    failed_tests INTEGER,
    success_rate NUMERIC(5,2)
) AS $
DECLARE
    rls_total INTEGER := 0;
    rls_passed INTEGER := 0;
    perm_total INTEGER := 0;
    perm_passed INTEGER := 0;
    integrity_total INTEGER := 0;
    integrity_passed INTEGER := 0;
BEGIN
    RAISE NOTICE '=== 멀티테넌시 데이터 격리 테스트 시작 ===';
    
    -- RLS 정책 테스트 실행
    RAISE NOTICE '';
    RAISE NOTICE '1. RLS 정책 동작 테스트:';
    RAISE NOTICE '%-50s | %-8s | %-8s | %-6s | %s', 
        '테스트명', '예상값', '실제값', '결과', '비고';
    RAISE NOTICE '%s', REPEAT('-', 100);
    
    FOR rec IN SELECT * FROM test_company_data_isolation() LOOP
        rls_total := rls_total + 1;
        IF rec.test_passed THEN
            rls_passed := rls_passed + 1;
        END IF;
        
        RAISE NOTICE '%-50s | %-8s | %-8s | %-6s | %s', 
            rec.test_name, rec.expected_result, rec.actual_result,
            CASE WHEN rec.test_passed THEN 'PASS' ELSE 'FAIL' END,
            rec.notes;
    END LOOP;

    -- 권한 테스트 실행
    RAISE NOTICE '';
    RAISE NOTICE '2. 권한 기반 접근 제어 테스트:';
    RAISE NOTICE '%-50s | %-6s | %s', '테스트명', '결과', '오류메시지';
    RAISE NOTICE '%s', REPEAT('-', 100);
    
    FOR rec IN SELECT * FROM test_user_permissions() LOOP
        perm_total := perm_total + 1;
        IF rec.test_passed THEN
            perm_passed := perm_passed + 1;
        END IF;
        
        RAISE NOTICE '%-50s | %-6s | %s', 
            rec.test_name,
            CASE WHEN rec.test_passed THEN 'PASS' ELSE 'FAIL' END,
            COALESCE(rec.error_message, '');
    END LOOP;

    -- 데이터 무결성 테스트 실행
    RAISE NOTICE '';
    RAISE NOTICE '3. 데이터 무결성 테스트:';
    RAISE NOTICE '%-50s | %-6s | %s', '테스트명', '결과', '오류메시지';
    RAISE NOTICE '%s', REPEAT('-', 100);
    
    FOR rec IN SELECT * FROM test_data_integrity() LOOP
        integrity_total := integrity_total + 1;
        IF rec.test_passed THEN
            integrity_passed := integrity_passed + 1;
        END IF;
        
        RAISE NOTICE '%-50s | %-6s | %s', 
            rec.test_name,
            CASE WHEN rec.test_passed THEN 'PASS' ELSE 'FAIL' END,
            COALESCE(rec.error_message, '');
    END LOOP;

    -- 결과 요약 반환
    RETURN QUERY SELECT 
        'RLS 정책 테스트'::TEXT,
        rls_total,
        rls_passed,
        rls_total - rls_passed,
        CASE WHEN rls_total > 0 THEN ROUND((rls_passed::NUMERIC / rls_total) * 100, 2) ELSE 0 END;
    
    RETURN QUERY SELECT 
        '권한 접근 제어 테스트'::TEXT,
        perm_total,
        perm_passed,
        perm_total - perm_passed,
        CASE WHEN perm_total > 0 THEN ROUND((perm_passed::NUMERIC / perm_total) * 100, 2) ELSE 0 END;
    
    RETURN QUERY SELECT 
        '데이터 무결성 테스트'::TEXT,
        integrity_total,
        integrity_passed,
        integrity_total - integrity_passed,
        CASE WHEN integrity_total > 0 THEN ROUND((integrity_passed::NUMERIC / integrity_total) * 100, 2) ELSE 0 END;

    RAISE NOTICE '';
    RAISE NOTICE '=== 테스트 완료 ===';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 테스트 정리 함수
-- =====================================================

-- 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_multitenancy_test_data()
RETURNS VOID AS $
BEGIN
    -- 테스트 데이터 삭제 (CASCADE로 관련 데이터도 함께 삭제됨)
    DELETE FROM companies WHERE business_registration_number IN ('1234567890', '9876543210');
    
    -- 임시 테이블 삭제
    DROP TABLE IF EXISTS test_variables;
    
    -- 테스트 함수들 삭제
    DROP FUNCTION IF EXISTS test_company_data_isolation();
    DROP FUNCTION IF EXISTS test_user_permissions();
    DROP FUNCTION IF EXISTS test_data_integrity();
    DROP FUNCTION IF EXISTS run_multitenancy_isolation_tests();
    DROP FUNCTION IF EXISTS cleanup_multitenancy_test_data();
    
    RAISE NOTICE '테스트 데이터 및 함수 정리 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 테스트 실행 명령어
-- =====================================================

-- 테스트 실행
SELECT * FROM run_multitenancy_isolation_tests();

-- 테스트 완료 후 정리 (필요시 주석 해제)
-- SELECT cleanup_multitenancy_test_data();