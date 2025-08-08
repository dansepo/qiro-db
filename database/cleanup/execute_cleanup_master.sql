-- =====================================================
-- 프로시저 삭제 마스터 실행 스크립트
-- 모든 Phase를 순차적으로 실행
-- 실행 전 반드시 전체 데이터베이스 백업 필요
-- =====================================================

-- =====================================================
-- 실행 전 필수 확인사항
-- =====================================================

DO $master_check$
DECLARE
    backup_confirmed BOOLEAN := FALSE;
    services_confirmed BOOLEAN := FALSE;
    testing_confirmed BOOLEAN := FALSE;
BEGIN
    RAISE NOTICE '=== 프로시저 삭제 마스터 스크립트 ===';
    RAISE NOTICE '실행 시간: %', NOW();
    RAISE NOTICE '데이터베이스: %', current_database();
    RAISE NOTICE '스키마: bms';
    RAISE NOTICE '';
    
    -- 현재 함수 개수 확인
    RAISE NOTICE '현재 bms 스키마 함수 개수: %', (
        SELECT COUNT(*) 
        FROM information_schema.routines 
        WHERE routine_schema = 'bms'
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '🚨 실행 전 필수 확인사항 🚨';
    RAISE NOTICE '';
    RAISE NOTICE '1. ✅ 전체 데이터베이스 백업 완료';
    RAISE NOTICE '2. ✅ 백엔드 서비스 구현 및 테스트 완료';
    RAISE NOTICE '3. ✅ 성능 비교 테스트 완료';
    RAISE NOTICE '4. ✅ 롤백 계획 수립 완료';
    RAISE NOTICE '5. ✅ 운영팀 및 개발팀 사전 통보 완료';
    RAISE NOTICE '';
    RAISE NOTICE '위 사항들이 모두 완료되었는지 확인하세요.';
    RAISE NOTICE '문제가 있다면 즉시 중단하고 준비를 완료한 후 재실행하세요.';
    RAISE NOTICE '';
    
    -- 10초 대기
    RAISE NOTICE '10초 후 자동으로 Phase 1부터 시작됩니다...';
    PERFORM pg_sleep(10);
END $master_check$;

-- =====================================================
-- Phase 1: 테스트 관련 함수 삭제
-- =====================================================

DO $phase1$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Phase 1 시작: 테스트 관련 함수 삭제';
    RAISE NOTICE '시작 시간: %', NOW();
END $phase1$;

-- Phase 1 스크립트 내용 포함
\i database/cleanup/phase1_test_functions_cleanup.sql

-- Phase 1 완료 확인
DO $phase1_complete$
DECLARE
    remaining_test_functions INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_test_functions
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND (
        routine_name LIKE '%test%' OR 
        routine_name LIKE '%cleanup%' OR
        routine_name LIKE '%partition%'
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Phase 1 완료';
    RAISE NOTICE '완료 시간: %', NOW();
    RAISE NOTICE '남은 테스트 관련 함수: %개', remaining_test_functions;
    
    -- 5초 대기 후 다음 Phase로
    RAISE NOTICE '';
    RAISE NOTICE '5초 후 Phase 2를 시작합니다...';
    PERFORM pg_sleep(5);
END $phase1_complete$;

-- =====================================================
-- Phase 2: 비즈니스 로직 함수 삭제
-- =====================================================

DO $phase2$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Phase 2 시작: 비즈니스 로직 함수 삭제';
    RAISE NOTICE '시작 시간: %', NOW();
END $phase2$;

-- Phase 2 스크립트 내용 포함
\i database/cleanup/phase2_business_functions_cleanup.sql

-- Phase 2 완료 확인
DO $phase2_complete$
DECLARE
    remaining_business_functions INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_business_functions
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND (
        routine_name LIKE '%validate%' OR 
        routine_name LIKE '%calculate%' OR
        routine_name LIKE '%generate_%' OR
        routine_name LIKE '%contract%'
    );
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Phase 2 완료';
    RAISE NOTICE '완료 시간: %', NOW();
    RAISE NOTICE '남은 비즈니스 로직 함수: %개', remaining_business_functions;
    
    -- 5초 대기 후 다음 Phase로
    RAISE NOTICE '';
    RAISE NOTICE '5초 후 Phase 3을 시작합니다...';
    PERFORM pg_sleep(5);
END $phase2_complete$;

-- =====================================================
-- Phase 3: 시스템 관리 함수 삭제
-- =====================================================

DO $phase3$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔄 Phase 3 시작: 시스템 관리 함수 삭제';
    RAISE NOTICE '시작 시간: %', NOW();
END $phase3$;

-- Phase 3 스크립트 내용 포함
\i database/cleanup/phase3_system_functions_cleanup.sql

-- =====================================================
-- 전체 작업 완료 및 최종 확인
-- =====================================================

DO $master_complete$
DECLARE
    final_function_count INTEGER;
    final_procedure_count INTEGER;
    total_remaining INTEGER;
    execution_duration INTERVAL;
    start_time TIMESTAMP := NOW() - INTERVAL '1 hour'; -- 대략적인 시작 시간
BEGIN
    -- 최종 함수 개수 확인
    SELECT COUNT(*) INTO final_function_count
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'FUNCTION';
    
    SELECT COUNT(*) INTO final_procedure_count
    FROM information_schema.routines 
    WHERE routine_schema = 'bms' 
    AND routine_type = 'PROCEDURE';
    
    total_remaining := final_function_count + final_procedure_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 =========================';
    RAISE NOTICE '🎉 전체 프로시저 삭제 완료!';
    RAISE NOTICE '🎉 =========================';
    RAISE NOTICE '';
    RAISE NOTICE '완료 시간: %', NOW();
    RAISE NOTICE '최종 남은 함수: %개', final_function_count;
    RAISE NOTICE '최종 남은 프로시저: %개', final_procedure_count;
    RAISE NOTICE '총 남은 루틴: %개', total_remaining;
    RAISE NOTICE '';
    
    -- 결과 평가
    IF total_remaining = 0 THEN
        RAISE NOTICE '🎊 완벽! 모든 bms 스키마 함수가 삭제되었습니다!';
    ELSIF total_remaining <= 5 THEN
        RAISE NOTICE '✅ 거의 완료! 소수의 함수만 남아있습니다.';
        RAISE NOTICE '   수동으로 검토 후 삭제하세요.';
    ELSIF total_remaining <= 20 THEN
        RAISE NOTICE '⚠️  양호! 일부 함수가 남아있습니다.';
        RAISE NOTICE '   추가 정리가 필요할 수 있습니다.';
    ELSE
        RAISE NOTICE '❌ 주의! 예상보다 많은 함수가 남아있습니다.';
        RAISE NOTICE '   스크립트 실행 과정을 검토하세요.';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== 다음 단계 ===';
    RAISE NOTICE '1. 백엔드 서비스 정상 동작 확인';
    RAISE NOTICE '2. API 엔드포인트 테스트 실행';
    RAISE NOTICE '3. 성능 테스트 및 모니터링 설정';
    RAISE NOTICE '4. 데이터베이스 최적화 (VACUUM, REINDEX)';
    RAISE NOTICE '5. 운영팀에 완료 보고';
    RAISE NOTICE '';
    RAISE NOTICE '=== 권장 최적화 명령어 ===';
    RAISE NOTICE 'VACUUM FULL;';
    RAISE NOTICE 'REINDEX DATABASE %s;', current_database();
    RAISE NOTICE 'ANALYZE;';
END $master_complete$;

-- =====================================================
-- 실행 후 권장 작업 가이드
-- =====================================================

/*
🔧 프로시저 삭제 완료 후 권장 작업

1. 즉시 수행할 작업:
   ✅ 백엔드 서비스 정상 동작 확인
   ✅ 핵심 API 엔드포인트 테스트
   ✅ 데이터베이스 연결 및 쿼리 성능 확인
   ✅ 로그 모니터링 설정

2. 데이터베이스 최적화:
   VACUUM FULL;                    -- 공간 회수
   REINDEX DATABASE qiro_dev;      -- 인덱스 재구성
   ANALYZE;                        -- 통계 정보 업데이트

3. 성능 테스트:
   - 응답 시간 측정
   - 동시 사용자 부하 테스트
   - 메모리 사용량 모니터링
   - 데이터베이스 커넥션 풀 최적화

4. 모니터링 설정:
   - 애플리케이션 성능 모니터링 (APM)
   - 데이터베이스 성능 모니터링
   - 오류 알림 설정
   - 로그 집계 및 분석

5. 문서 업데이트:
   - API 문서 갱신
   - 운영 가이드 업데이트
   - 장애 대응 매뉴얼 수정
   - 백업/복구 절차 업데이트

6. 백업 및 보안:
   - 새로운 구조 백업 생성
   - 복구 시나리오 테스트
   - 보안 설정 검토
   - 접근 권한 재확인

🚨 문제 발생 시:
   - 즉시 서비스 중단
   - rollback_procedures.sql 실행
   - 백업에서 데이터베이스 복원
   - 기술팀 긴급 소집

📞 긴급 연락처:
   - 데이터베이스 관리자
   - 백엔드 개발팀 리더
   - 인프라 팀 리더
   - 서비스 운영팀 리더
*/