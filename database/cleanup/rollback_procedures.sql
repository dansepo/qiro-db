-- =====================================================
-- 프로시저 삭제 롤백 스크립트
-- 삭제 작업에 문제가 발생한 경우 사용
-- 실행 전 반드시 백업에서 복원 필요
-- =====================================================

-- =====================================================
-- 롤백 실행 전 확인사항
-- =====================================================

DO $rollback_check$
BEGIN
    RAISE NOTICE '=== 프로시저 삭제 롤백 시작 ===';
    RAISE NOTICE '실행 시간: %', NOW();
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  중요: 이 스크립트는 백업에서 함수를 복원한 후 실행하세요';
    RAISE NOTICE '⚠️  백엔드 서비스를 먼저 중단하고 데이터베이스 함수 호출로 전환하세요';
    RAISE NOTICE '';
    
    -- 현재 남은 함수 개수 확인
    RAISE NOTICE '현재 bms 스키마 함수 개수: %', (
        SELECT COUNT(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'bms'
    );
END $rollback_check$;

-- =====================================================
-- 1. 백엔드 서비스 비활성화 확인
-- =====================================================

-- 백엔드 서비스가 데이터베이스 함수를 호출하지 않도록 설정 확인
-- 이 부분은 애플리케이션 설정에서 수행해야 함

/*
애플리케이션에서 수행해야 할 작업:

1. 서비스 중단
   - Spring Boot 애플리케이션 중단
   - 로드 밸런서에서 트래픽 차단
   - 헬스체크 실패 상태로 전환

2. 설정 변경
   - application.yml에서 database.use-procedures=true 설정
   - 또는 feature flag로 프로시저 사용 활성화
   - 백엔드 서비스 호출 비활성화

3. 데이터베이스 연결 확인
   - 프로시저 호출 권한 확인
   - 연결 풀 설정 확인
   - 트랜잭션 설정 확인
*/

-- =====================================================
-- 2. 핵심 함수 존재 확인
-- =====================================================

DO $function_check$
DECLARE
    missing_functions TEXT[] := ARRAY[]::TEXT[];
    func_name TEXT;
    critical_functions TEXT[] := ARRAY[
        'validate_business_registration_number',
        'calculate_fee_amount',
        'create_work_order',
        'process_invoice_payment',
        'create_lease_contract',
        'log_user_activity',
        'get_system_setting'
    ];
BEGIN
    RAISE NOTICE '=== 핵심 함수 존재 확인 ===';
    
    FOREACH func_name IN ARRAY critical_functions
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'bms' 
            AND routine_name = func_name
        ) THEN
            missing_functions := array_append(missing_functions, func_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_functions, 1) > 0 THEN
        RAISE NOTICE '❌ 누락된 핵심 함수들:';
        FOREACH func_name IN ARRAY missing_functions
        LOOP
            RAISE NOTICE '  - bms.%', func_name;
        END LOOP;
        RAISE NOTICE '';
        RAISE NOTICE '백업에서 함수들을 복원한 후 다시 실행하세요.';
        RAISE EXCEPTION '핵심 함수들이 누락되어 롤백을 중단합니다.';
    ELSE
        RAISE NOTICE '✓ 모든 핵심 함수가 존재합니다.';
    END IF;
END $function_check$;

-- =====================================================
-- 3. 함수 호출 테스트
-- =====================================================

DO $function_test$
DECLARE
    test_company_id UUID;
    test_result TEXT;
BEGIN
    RAISE NOTICE '=== 함수 호출 테스트 ===';
    
    -- 테스트용 회사 ID 조회 (실제 데이터 사용)
    SELECT company_id INTO test_company_id 
    FROM bms.companies 
    WHERE verification_status = 'VERIFIED' 
    LIMIT 1;
    
    IF test_company_id IS NULL THEN
        RAISE NOTICE '⚠️  테스트용 회사 데이터가 없어 함수 테스트를 건너뜁니다.';
    ELSE
        BEGIN
            -- 시스템 설정 조회 테스트
            SELECT bms.get_system_setting(test_company_id, 'SYSTEM_NAME') INTO test_result;
            RAISE NOTICE '✓ get_system_setting() 함수 호출 성공';
            
            -- 사업자등록번호 검증 테스트
            SELECT bms.validate_business_registration_number('123-45-67890') INTO test_result;
            RAISE NOTICE '✓ validate_business_registration_number() 함수 호출 성공';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ 함수 호출 테스트 실패: %', SQLERRM;
            RAISE NOTICE '함수가 제대로 복원되지 않았을 수 있습니다.';
        END;
    END IF;
END $function_test$;

-- =====================================================
-- 4. 애플리케이션 설정 가이드
-- =====================================================

DO $config_guide$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 애플리케이션 설정 변경 가이드 ===';
    RAISE NOTICE '';
    RAISE NOTICE '1. Spring Boot 설정 변경 (application.yml):';
    RAISE NOTICE '   database:';
    RAISE NOTICE '     use-procedures: true';
    RAISE NOTICE '     use-backend-services: false';
    RAISE NOTICE '';
    RAISE NOTICE '2. 서비스 클래스 비활성화:';
    RAISE NOTICE '   - @ConditionalOnProperty 어노테이션 사용';
    RAISE NOTICE '   - 또는 @Profile("!use-procedures") 사용';
    RAISE NOTICE '';
    RAISE NOTICE '3. 데이터베이스 호출 활성화:';
    RAISE NOTICE '   - JdbcTemplate 또는 MyBatis 설정';
    RAISE NOTICE '   - 프로시저 호출 매퍼 활성화';
    RAISE NOTICE '';
    RAISE NOTICE '4. 트랜잭션 설정 확인:';
    RAISE NOTICE '   - @Transactional 어노테이션 유지';
    RAISE NOTICE '   - 데이터베이스 레벨 트랜잭션 관리';
END $config_guide$;

-- =====================================================
-- 5. 성능 및 기능 검증 가이드
-- =====================================================

DO $verification_guide$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '=== 롤백 후 검증 가이드 ===';
    RAISE NOTICE '';
    RAISE NOTICE '1. 기능 테스트:';
    RAISE NOTICE '   - 핵심 비즈니스 로직 동작 확인';
    RAISE NOTICE '   - API 엔드포인트 응답 확인';
    RAISE NOTICE '   - 데이터 무결성 검증';
    RAISE NOTICE '';
    RAISE NOTICE '2. 성능 테스트:';
    RAISE NOTICE '   - 응답 시간 측정';
    RAISE NOTICE '   - 동시 사용자 부하 테스트';
    RAISE NOTICE '   - 메모리 사용량 모니터링';
    RAISE NOTICE '';
    RAISE NOTICE '3. 모니터링 설정:';
    RAISE NOTICE '   - 데이터베이스 연결 모니터링';
    RAISE NOTICE '   - 프로시저 실행 시간 추적';
    RAISE NOTICE '   - 오류 로그 모니터링';
    RAISE NOTICE '';
    RAISE NOTICE '4. 백업 및 복구:';
    RAISE NOTICE '   - 현재 상태 백업 생성';
    RAISE NOTICE '   - 복구 절차 문서화';
    RAISE NOTICE '   - 재해 복구 계획 업데이트';
END $verification_guide$;

-- =====================================================
-- 6. 롤백 완료 확인
-- =====================================================

DO $rollback_complete$
DECLARE
    total_functions INTEGER;
    total_procedures INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_functions
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'FUNCTION';
    
    SELECT COUNT(*) INTO total_procedures
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'PROCEDURE';
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 롤백 완료 상태 ===';
    RAISE NOTICE '완료 시간: %', NOW();
    RAISE NOTICE '복원된 함수: %개', total_functions;
    RAISE NOTICE '복원된 프로시저: %개', total_procedures;
    RAISE NOTICE '총 복원된 루틴: %개', total_functions + total_procedures;
    RAISE NOTICE '';
    
    IF total_functions + total_procedures >= 200 THEN
        RAISE NOTICE '✅ 롤백이 성공적으로 완료된 것으로 보입니다.';
        RAISE NOTICE '애플리케이션 설정을 변경하고 서비스를 재시작하세요.';
    ELSE
        RAISE NOTICE '⚠️  예상보다 적은 수의 함수가 복원되었습니다.';
        RAISE NOTICE '백업 복원 과정을 다시 확인하세요.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계:';
    RAISE NOTICE '1. 애플리케이션 설정 변경';
    RAISE NOTICE '2. 서비스 재시작';
    RAISE NOTICE '3. 기능 및 성능 테스트';
    RAISE NOTICE '4. 모니터링 설정';
END $rollback_complete$;

-- =====================================================
-- 7. 긴급 연락처 및 지원 정보
-- =====================================================

/*
롤백 과정에서 문제가 발생한 경우:

1. 즉시 수행할 작업:
   - 서비스 중단 유지
   - 사용자 접근 차단
   - 현재 상태 백업 생성

2. 기술 지원:
   - 데이터베이스 관리자 연락
   - 백엔드 개발팀 연락
   - 인프라 팀 연락

3. 복구 옵션:
   - 이전 백업으로 완전 복원
   - 단계별 부분 복원
   - 하이브리드 모드 (일부 함수만 사용)

4. 문서 참조:
   - 데이터베이스 복원 가이드
   - 애플리케이션 설정 매뉴얼
   - 장애 대응 절차서
*/