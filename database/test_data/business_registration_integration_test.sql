-- =====================================================
-- 사업자 회원가입 플로우 통합 테스트
-- QIRO 사업자 회원가입 시스템
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 테스트 환경 설정
SET client_min_messages = WARNING;

-- =====================================================
-- 1. 테스트 시나리오 정의
-- =====================================================

-- 테스트 시나리오:
-- 1. 사업자 정보 입력 및 검증
-- 2. 사업자등록번호 유효성 검증
-- 3. 회사 등록 및 기본 역할 생성
-- 4. 총괄관리자 계정 생성
-- 5. 본인 인증 프로세스
-- 6. 건물 등록 및 그룹 생성
-- 7. 직원 계정 생성 및 권한 부여
-- 8. 오류 상황 처리 테스트

-- =====================================================
-- 2. 테스트 데이터 준비
-- =====================================================

-- 테스트용 임시 테이블 생성
CREATE TEMP TABLE test_registration_data (
    test_id SERIAL PRIMARY KEY,
    business_number VARCHAR(20),
    company_name VARCHAR(255),
    representative_name VARCHAR(100),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    expected_result TEXT,
    test_description TEXT
);

-- 테스트 데이터 삽입
INSERT INTO test_registration_data (
    business_number, company_name, representative_name, 
    contact_email, contact_phone, expected_result, test_description
) VALUES 
    ('1234567890', '정상회사', '김정상', 'normal@test.com', '02-1234-5678', 'SUCCESS', '정상적인 사업자 등록'),
    ('9876543210', '정상회사2', '박정상', 'normal2@test.com', '02-9876-5432', 'SUCCESS', '두 번째 정상 등록'),
    ('1234567899', '잘못된회사', '김잘못', 'wrong@test.com', '02-1111-1111', 'VALIDATION_ERROR', '잘못된 사업자등록번호'),
    ('1234567890', '중복회사', '김중복', 'duplicate@test.com', '02-2222-2222', 'DUPLICATE_ERROR', '중복 사업자등록번호'),
    ('5555555555', '이메일중복회사', '김이메일', 'normal@test.com', '02-3333-3333', 'EMAIL_DUPLICATE_ERROR', '중복 이메일');

-- =====================================================
-- 3. 사업자 회원가입 플로우 테스트 함수
-- =====================================================

-- 메인 테스트 함수: 전체 회원가입 플로우 검증
CREATE OR REPLACE FUNCTION test_business_registration_flow()
RETURNS TABLE (
    test_step TEXT,
    test_case TEXT,
    expected_result TEXT,
    actual_result TEXT,
    test_passed BOOLEAN,
    error_message TEXT,
    execution_time INTERVAL
) AS $
DECLARE
    rec RECORD;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    company_id UUID;
    user_id UUID;
    role_count INTEGER;
    verification_id UUID;
    test_result TEXT;
    error_msg TEXT;
    test_success BOOLEAN;
BEGIN
    RAISE NOTICE '=== 사업자 회원가입 플로우 통합 테스트 시작 ===';
    
    -- 각 테스트 케이스에 대해 반복
    FOR rec IN SELECT * FROM test_registration_data ORDER BY test_id LOOP
        start_time := clock_timestamp();
        
        RAISE NOTICE '';
        RAISE NOTICE '테스트 케이스: %', rec.test_description;
        RAISE NOTICE '사업자등록번호: %', rec.business_number;
        
        -- 1단계: 사업자등록번호 유효성 검증
        BEGIN
            IF validate_business_registration_number(rec.business_number) THEN
                test_result := 'VALID';
            ELSE
                test_result := 'INVALID';
            END IF;
            
            test_success := CASE 
                WHEN rec.expected_result = 'VALIDATION_ERROR' THEN test_result = 'INVALID'
                ELSE test_result = 'VALID'
            END;
            
            error_msg := NULL;
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '1. 사업자등록번호 검증'::TEXT,
            rec.test_description,
            CASE WHEN rec.expected_result = 'VALIDATION_ERROR' THEN 'INVALID' ELSE 'VALID' END,
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 유효성 검증 실패 시 다음 단계 스킵
        IF NOT test_success AND rec.expected_result = 'VALIDATION_ERROR' THEN
            CONTINUE;
        ELSIF NOT test_success THEN
            CONTINUE;
        END IF;
        
        -- 2단계: 회사 등록
        start_time := clock_timestamp();
        BEGIN
            INSERT INTO companies (
                business_registration_number, company_name, representative_name,
                business_address, contact_phone, contact_email, business_type,
                establishment_date, verification_status
            ) VALUES (
                rec.business_number, rec.company_name, rec.representative_name,
                '서울시 강남구 테스트로 123', rec.contact_phone, rec.contact_email,
                '부동산임대업', '2020-01-01', 'PENDING'
            ) RETURNING company_id INTO company_id;
            
            test_result := 'SUCCESS';
            test_success := (rec.expected_result NOT IN ('DUPLICATE_ERROR', 'EMAIL_DUPLICATE_ERROR'));
            error_msg := NULL;
            
        EXCEPTION WHEN unique_violation THEN
            test_result := 'DUPLICATE_ERROR';
            test_success := (rec.expected_result IN ('DUPLICATE_ERROR', 'EMAIL_DUPLICATE_ERROR'));
            error_msg := SQLERRM;
            company_id := NULL;
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
            company_id := NULL;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '2. 회사 등록'::TEXT,
            rec.test_description,
            CASE WHEN rec.expected_result IN ('DUPLICATE_ERROR', 'EMAIL_DUPLICATE_ERROR') 
                 THEN 'DUPLICATE_ERROR' ELSE 'SUCCESS' END,
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 회사 등록 실패 시 다음 단계 스킵
        IF company_id IS NULL THEN
            CONTINUE;
        END IF;
        
        -- 3단계: 기본 역할 자동 생성 확인
        start_time := clock_timestamp();
        BEGIN
            SELECT COUNT(*) INTO role_count 
            FROM roles 
            WHERE company_id = company_id AND is_system_role = true;
            
            test_result := role_count::TEXT || ' roles created';
            test_success := (role_count >= 3); -- 최소 3개 기본 역할 생성되어야 함
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '3. 기본 역할 생성'::TEXT,
            rec.test_description,
            '3 roles created',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 4단계: 총괄관리자 계정 생성
        start_time := clock_timestamp();
        BEGIN
            INSERT INTO users (
                company_id, email, password_hash, full_name,
                phone_number, user_type, status, email_verified
            ) VALUES (
                company_id, rec.contact_email, '$2a$10$example.hash',
                rec.representative_name, rec.contact_phone, 'SUPER_ADMIN',
                'PENDING_VERIFICATION', false
            ) RETURNING user_id INTO user_id;
            
            -- 총괄관리자 역할 할당
            INSERT INTO user_role_links (user_id, role_id)
            SELECT user_id, role_id 
            FROM roles 
            WHERE company_id = company_id AND role_code = 'SUPER_ADMIN';
            
            test_result := 'SUCCESS';
            test_success := true;
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
            user_id := NULL;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '4. 총괄관리자 계정 생성'::TEXT,
            rec.test_description,
            'SUCCESS',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 사용자 생성 실패 시 다음 단계 스킵
        IF user_id IS NULL THEN
            CONTINUE;
        END IF;
        
        -- 5단계: 본인 인증 레코드 생성
        start_time := clock_timestamp();
        BEGIN
            INSERT INTO business_verification_records (
                company_id, verification_type, verification_data,
                verification_status
            ) VALUES (
                company_id, 'BUSINESS_REGISTRATION',
                jsonb_build_object(
                    'business_number', rec.business_number,
                    'company_name', rec.company_name,
                    'representative_name', rec.representative_name
                ),
                'PENDING'
            ) RETURNING verification_id INTO verification_id;
            
            test_result := 'SUCCESS';
            test_success := true;
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '5. 본인 인증 레코드 생성'::TEXT,
            rec.test_description,
            'SUCCESS',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 6단계: 인증 완료 처리
        start_time := clock_timestamp();
        BEGIN
            -- 인증 완료 처리
            UPDATE business_verification_records 
            SET verification_status = 'SUCCESS',
                verification_date = now()
            WHERE verification_id = verification_id;
            
            -- 회사 인증 상태 업데이트
            UPDATE companies 
            SET verification_status = 'VERIFIED',
                verification_date = now()
            WHERE company_id = company_id;
            
            -- 사용자 계정 활성화
            UPDATE users 
            SET status = 'ACTIVE',
                email_verified = true
            WHERE user_id = user_id;
            
            test_result := 'SUCCESS';
            test_success := true;
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '6. 인증 완료 처리'::TEXT,
            rec.test_description,
            'SUCCESS',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 7단계: 건물 등록 테스트
        start_time := clock_timestamp();
        BEGIN
            INSERT INTO buildings (
                company_id, name, address, building_type,
                total_floors, total_area, total_units
            ) VALUES (
                company_id, rec.company_name || ' 관리건물',
                '서울시 강남구 ' || rec.company_name || '로 456',
                'APARTMENT', 10, 5000.00, 50
            );
            
            test_result := 'SUCCESS';
            test_success := true;
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '7. 건물 등록'::TEXT,
            rec.test_description,
            'SUCCESS',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
        -- 8단계: 건물 그룹 생성
        start_time := clock_timestamp();
        BEGIN
            INSERT INTO building_groups (
                company_id, group_name, group_type, description
            ) VALUES (
                company_id, rec.company_name || ' 기본그룹',
                'MANAGEMENT_UNIT', '기본 관리 그룹'
            );
            
            test_result := 'SUCCESS';
            test_success := true;
            error_msg := NULL;
            
        EXCEPTION WHEN OTHERS THEN
            test_result := 'ERROR';
            test_success := false;
            error_msg := SQLERRM;
        END;
        
        end_time := clock_timestamp();
        
        RETURN QUERY SELECT 
            '8. 건물 그룹 생성'::TEXT,
            rec.test_description,
            'SUCCESS',
            test_result,
            test_success,
            error_msg,
            end_time - start_time;
        
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 사업자 회원가입 플로우 테스트 완료 ===';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 오류 상황 처리 테스트
-- =====================================================

-- 오류 상황 테스트 함수
CREATE OR REPLACE FUNCTION test_error_scenarios()
RETURNS TABLE (
    scenario_name TEXT,
    test_passed BOOLEAN,
    error_message TEXT,
    recovery_successful BOOLEAN
) AS $
DECLARE
    test_company_id UUID;
    test_user_id UUID;
    test_success BOOLEAN;
    error_msg TEXT;
    recovery_success BOOLEAN;
BEGIN
    RAISE NOTICE '=== 오류 상황 처리 테스트 시작 ===';
    
    -- 시나리오 1: 트랜잭션 롤백 테스트
    BEGIN
        BEGIN
            -- 정상적인 회사 생성
            INSERT INTO companies (
                business_registration_number, company_name, representative_name,
                business_address, contact_phone, contact_email, business_type,
                establishment_date
            ) VALUES (
                '1111111111', '롤백테스트회사', '롤백대표',
                '서울시 강남구 롤백로 123', '02-1111-1111', 'rollback@test.com',
                '부동산임대업', '2020-01-01'
            ) RETURNING company_id INTO test_company_id;
            
            -- 의도적으로 오류 발생 (잘못된 사용자 데이터)
            INSERT INTO users (
                company_id, email, password_hash, full_name,
                user_type, status
            ) VALUES (
                test_company_id, 'invalid-email', -- 잘못된 이메일 형식
                '$2a$10$example.hash', '롤백사용자',
                'INVALID_TYPE', 'ACTIVE' -- 잘못된 사용자 타입
            );
            
            test_success := false; -- 여기까지 오면 안됨
            error_msg := '트랜잭션이 롤백되지 않음';
            
        EXCEPTION WHEN OTHERS THEN
            -- 롤백 확인
            SELECT COUNT(*) = 0 INTO recovery_success
            FROM companies WHERE company_id = test_company_id;
            
            test_success := true;
            error_msg := SQLERRM;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        test_success := false;
        error_msg := SQLERRM;
        recovery_success := false;
    END;
    
    RETURN QUERY SELECT 
        '트랜잭션 롤백 테스트'::TEXT,
        test_success,
        error_msg,
        recovery_success;
    
    -- 시나리오 2: 동시성 제어 테스트
    BEGIN
        -- 첫 번째 회사 생성
        INSERT INTO companies (
            business_registration_number, company_name, representative_name,
            business_address, contact_phone, contact_email, business_type,
            establishment_date
        ) VALUES (
            '2222222222', '동시성테스트회사', '동시성대표',
            '서울시 강남구 동시성로 123', '02-2222-2222', 'concurrency@test.com',
            '부동산임대업', '2020-01-01'
        ) RETURNING company_id INTO test_company_id;
        
        -- 동일한 사업자등록번호로 두 번째 회사 생성 시도
        BEGIN
            INSERT INTO companies (
                business_registration_number, company_name, representative_name,
                business_address, contact_phone, contact_email, business_type,
                establishment_date
            ) VALUES (
                '2222222222', '중복동시성테스트회사', '중복동시성대표',
                '서울시 강남구 중복동시성로 456', '02-3333-3333', 'duplicate@test.com',
                '부동산관리업', '2021-01-01'
            );
            
            test_success := false; -- 중복 등록이 성공하면 안됨
            error_msg := '중복 사업자등록번호 등록이 허용됨';
            recovery_success := false;
            
        EXCEPTION WHEN unique_violation THEN
            test_success := true; -- 유니크 제약조건으로 차단되어야 함
            error_msg := '중복 등록이 정상적으로 차단됨';
            recovery_success := true;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        test_success := false;
        error_msg := SQLERRM;
        recovery_success := false;
    END;
    
    RETURN QUERY SELECT 
        '동시성 제어 테스트'::TEXT,
        test_success,
        error_msg,
        recovery_success;
    
    -- 시나리오 3: 외래키 제약조건 테스트
    BEGIN
        -- 존재하지 않는 회사 ID로 사용자 생성 시도
        BEGIN
            INSERT INTO users (
                company_id, email, password_hash, full_name,
                user_type, status
            ) VALUES (
                gen_random_uuid(), 'orphan@test.com',
                '$2a$10$example.hash', '고아사용자',
                'EMPLOYEE', 'ACTIVE'
            );
            
            test_success := false; -- 외래키 제약조건 위반으로 실패해야 함
            error_msg := '외래키 제약조건이 작동하지 않음';
            recovery_success := false;
            
        EXCEPTION WHEN foreign_key_violation THEN
            test_success := true; -- 외래키 제약조건으로 차단되어야 함
            error_msg := '외래키 제약조건이 정상 작동';
            recovery_success := true;
        END;
        
    EXCEPTION WHEN OTHERS THEN
        test_success := false;
        error_msg := SQLERRM;
        recovery_success := false;
    END;
    
    RETURN QUERY SELECT 
        '외래키 제약조건 테스트'::TEXT,
        test_success,
        error_msg,
        recovery_success;
    
    RAISE NOTICE '=== 오류 상황 처리 테스트 완료 ===';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 성능 테스트
-- =====================================================

-- 성능 테스트 함수
CREATE OR REPLACE FUNCTION test_registration_performance()
RETURNS TABLE (
    operation_name TEXT,
    iterations INTEGER,
    total_time INTERVAL,
    avg_time_ms NUMERIC,
    operations_per_second NUMERIC
) AS $
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    i INTEGER;
    company_id UUID;
    total_duration INTERVAL;
BEGIN
    RAISE NOTICE '=== 성능 테스트 시작 ===';
    
    -- 테스트 1: 회사 등록 성능 (100회)
    start_time := clock_timestamp();
    
    FOR i IN 1..100 LOOP
        INSERT INTO companies (
            business_registration_number, company_name, representative_name,
            business_address, contact_phone, contact_email, business_type,
            establishment_date
        ) VALUES (
            LPAD(i::TEXT, 10, '0'), '성능테스트회사' || i, '성능대표' || i,
            '서울시 강남구 성능로 ' || i, '02-' || LPAD(i::TEXT, 8, '0'),
            'perf' || i || '@test.com', '부동산임대업', '2020-01-01'
        );
    END LOOP;
    
    end_time := clock_timestamp();
    total_duration := end_time - start_time;
    
    RETURN QUERY SELECT 
        '회사 등록'::TEXT,
        100::INTEGER,
        total_duration,
        ROUND(EXTRACT(EPOCH FROM total_duration) * 1000 / 100, 2),
        ROUND(100 / EXTRACT(EPOCH FROM total_duration), 2);
    
    -- 테스트 2: 사용자 등록 성능 (100회)
    start_time := clock_timestamp();
    
    FOR i IN 1..100 LOOP
        SELECT company_id INTO company_id 
        FROM companies 
        WHERE business_registration_number = LPAD(i::TEXT, 10, '0');
        
        INSERT INTO users (
            company_id, email, password_hash, full_name,
            user_type, status
        ) VALUES (
            company_id, 'user' || i || '@test.com',
            '$2a$10$example.hash', '성능사용자' || i,
            'SUPER_ADMIN', 'ACTIVE'
        );
    END LOOP;
    
    end_time := clock_timestamp();
    total_duration := end_time - start_time;
    
    RETURN QUERY SELECT 
        '사용자 등록'::TEXT,
        100::INTEGER,
        total_duration,
        ROUND(EXTRACT(EPOCH FROM total_duration) * 1000 / 100, 2),
        ROUND(100 / EXTRACT(EPOCH FROM total_duration), 2);
    
    -- 테스트 3: 복합 조회 성능 (1000회)
    start_time := clock_timestamp();
    
    FOR i IN 1..1000 LOOP
        PERFORM c.company_name, u.full_name, COUNT(bg.group_id)
        FROM companies c
        LEFT JOIN users u ON c.company_id = u.company_id
        LEFT JOIN building_groups bg ON c.company_id = bg.company_id
        WHERE c.verification_status = 'VERIFIED'
        GROUP BY c.company_id, c.company_name, u.full_name
        LIMIT 10;
    END LOOP;
    
    end_time := clock_timestamp();
    total_duration := end_time - start_time;
    
    RETURN QUERY SELECT 
        '복합 조회'::TEXT,
        1000::INTEGER,
        total_duration,
        ROUND(EXTRACT(EPOCH FROM total_duration) * 1000 / 1000, 2),
        ROUND(1000 / EXTRACT(EPOCH FROM total_duration), 2);
    
    RAISE NOTICE '=== 성능 테스트 완료 ===';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 테스트 실행 및 결과 요약
-- =====================================================

-- 전체 테스트 실행 함수
CREATE OR REPLACE FUNCTION run_business_registration_integration_tests()
RETURNS TABLE (
    test_category TEXT,
    total_tests INTEGER,
    passed_tests INTEGER,
    failed_tests INTEGER,
    success_rate NUMERIC(5,2),
    avg_execution_time_ms NUMERIC
) AS $
DECLARE
    flow_total INTEGER := 0;
    flow_passed INTEGER := 0;
    error_total INTEGER := 0;
    error_passed INTEGER := 0;
    total_time_ms NUMERIC := 0;
    test_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== 사업자 회원가입 통합 테스트 실행 ===';
    
    -- 1. 회원가입 플로우 테스트
    RAISE NOTICE '';
    RAISE NOTICE '1. 회원가입 플로우 테스트 결과:';
    RAISE NOTICE '%-30s | %-30s | %-10s | %-10s | %-6s | %-15s | %s', 
        '테스트 단계', '테스트 케이스', '예상결과', '실제결과', '결과', '실행시간(ms)', '오류메시지';
    RAISE NOTICE '%s', REPEAT('-', 150);
    
    FOR rec IN SELECT * FROM test_business_registration_flow() LOOP
        flow_total := flow_total + 1;
        test_count := test_count + 1;
        total_time_ms := total_time_ms + EXTRACT(EPOCH FROM rec.execution_time) * 1000;
        
        IF rec.test_passed THEN
            flow_passed := flow_passed + 1;
        END IF;
        
        RAISE NOTICE '%-30s | %-30s | %-10s | %-10s | %-6s | %-15s | %s', 
            rec.test_step, 
            SUBSTRING(rec.test_case FROM 1 FOR 30),
            rec.expected_result, 
            rec.actual_result,
            CASE WHEN rec.test_passed THEN 'PASS' ELSE 'FAIL' END,
            ROUND(EXTRACT(EPOCH FROM rec.execution_time) * 1000, 2),
            COALESCE(rec.error_message, '');
    END LOOP;
    
    -- 2. 오류 상황 테스트
    RAISE NOTICE '';
    RAISE NOTICE '2. 오류 상황 처리 테스트 결과:';
    RAISE NOTICE '%-30s | %-6s | %-10s | %s', 
        '시나리오명', '결과', '복구성공', '오류메시지';
    RAISE NOTICE '%s', REPEAT('-', 100);
    
    FOR rec IN SELECT * FROM test_error_scenarios() LOOP
        error_total := error_total + 1;
        IF rec.test_passed THEN
            error_passed := error_passed + 1;
        END IF;
        
        RAISE NOTICE '%-30s | %-6s | %-10s | %s', 
            rec.scenario_name,
            CASE WHEN rec.test_passed THEN 'PASS' ELSE 'FAIL' END,
            CASE WHEN rec.recovery_successful THEN 'YES' ELSE 'NO' END,
            COALESCE(rec.error_message, '');
    END LOOP;
    
    -- 3. 성능 테스트
    RAISE NOTICE '';
    RAISE NOTICE '3. 성능 테스트 결과:';
    RAISE NOTICE '%-20s | %-10s | %-15s | %-15s | %s', 
        '작업명', '반복횟수', '평균시간(ms)', '초당처리량', '총시간';
    RAISE NOTICE '%s', REPEAT('-', 80);
    
    FOR rec IN SELECT * FROM test_registration_performance() LOOP
        RAISE NOTICE '%-20s | %-10s | %-15s | %-15s | %s', 
            rec.operation_name, rec.iterations, rec.avg_time_ms,
            rec.operations_per_second, rec.total_time;
    END LOOP;
    
    -- 결과 요약 반환
    RETURN QUERY SELECT 
        '회원가입 플로우 테스트'::TEXT,
        flow_total,
        flow_passed,
        flow_total - flow_passed,
        CASE WHEN flow_total > 0 THEN ROUND((flow_passed::NUMERIC / flow_total) * 100, 2) ELSE 0 END,
        CASE WHEN test_count > 0 THEN ROUND(total_time_ms / test_count, 2) ELSE 0 END;
    
    RETURN QUERY SELECT 
        '오류 상황 처리 테스트'::TEXT,
        error_total,
        error_passed,
        error_total - error_passed,
        CASE WHEN error_total > 0 THEN ROUND((error_passed::NUMERIC / error_total) * 100, 2) ELSE 0 END,
        0::NUMERIC;

    RAISE NOTICE '';
    RAISE NOTICE '=== 통합 테스트 완료 ===';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 테스트 정리 함수
-- =====================================================

-- 테스트 데이터 정리 함수
CREATE OR REPLACE FUNCTION cleanup_business_registration_test_data()
RETURNS VOID AS $
BEGIN
    -- 테스트 데이터 삭제
    DELETE FROM companies WHERE business_registration_number ~ '^[0-9]{10}
</content>
</file> AND company_name LIKE '%테스트%';
    DELETE FROM companies WHERE business_registration_number ~ '^[0-9]{10}
</content>
</file> AND company_name LIKE '%성능%';
    DELETE FROM companies WHERE business_registration_number IN ('1111111111', '2222222222');
    
    -- 임시 테이블 삭제
    DROP TABLE IF EXISTS test_registration_data;
    
    -- 테스트 함수들 삭제
    DROP FUNCTION IF EXISTS test_business_registration_flow();
    DROP FUNCTION IF EXISTS test_error_scenarios();
    DROP FUNCTION IF EXISTS test_registration_performance();
    DROP FUNCTION IF EXISTS run_business_registration_integration_tests();
    DROP FUNCTION IF EXISTS cleanup_business_registration_test_data();
    
    RAISE NOTICE '테스트 데이터 및 함수 정리 완료';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 8. 테스트 실행 명령어
-- =====================================================

-- 통합 테스트 실행
SELECT * FROM run_business_registration_integration_tests();

-- 테스트 완료 후 정리 (필요시 주석 해제)
-- SELECT cleanup_business_registration_test_data();