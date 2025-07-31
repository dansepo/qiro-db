-- =====================================================
-- QIRO 멀티테넌시 마이그레이션 통합 실행 스크립트
-- 작성일: 2025-01-30
-- 설명: 전체 멀티테넌시 마이그레이션을 순서대로 실행
-- =====================================================

-- 실행 전 확인사항
DO $$
BEGIN
    RAISE NOTICE '=== QIRO 멀티테넌시 마이그레이션 시작 ===';
    RAISE NOTICE '실행 시간: %', now();
    RAISE NOTICE '데이터베이스: %', current_database();
    RAISE NOTICE '사용자: %', current_user;
    RAISE NOTICE '';
    RAISE NOTICE '주의: 이 스크립트는 기존 데이터를 수정합니다.';
    RAISE NOTICE '운영 환경에서는 반드시 백업 후 실행하세요.';
    RAISE NOTICE '';
END $$;

-- 1단계: 기본 멀티테넌시 구조 확인
DO $$
BEGIN
    RAISE NOTICE '=== 1단계: 기본 구조 확인 ===';
    
    -- Companies 테이블 존재 확인
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'companies') THEN
        RAISE EXCEPTION 'Companies 테이블이 존재하지 않습니다. 먼저 기본 스키마를 생성해주세요.';
    END IF;
    
    -- Users 테이블 존재 확인
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE EXCEPTION 'Users 테이블이 존재하지 않습니다. 먼저 기본 스키마를 생성해주세요.';
    END IF;
    
    -- Buildings 테이블 존재 확인
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'buildings') THEN
        RAISE EXCEPTION 'Buildings 테이블이 존재하지 않습니다. 먼저 기본 스키마를 생성해주세요.';
    END IF;
    
    RAISE NOTICE '기본 테이블 구조 확인 완료';
END $$;

-- 2단계: Buildings 테이블 멀티테넌시 적용
\echo '=== 2단계: Buildings 테이블 멀티테넌시 적용 ==='
\i database/schema/migration_buildings_multitenancy.sql

-- 3단계: Users 테이블 멀티테넌시 적용
\echo '=== 3단계: Users 테이블 멀티테넌시 적용 ==='
\i database/schema/migration_users_multitenancy.sql

-- 4단계: 관리비 및 임대차 테이블 멀티테넌시 적용
\echo '=== 4단계: 관리비 및 임대차 테이블 멀티테넌시 적용 ==='
\i database/schema/migration_billing_lease_multitenancy.sql

-- 5단계: 멀티테넌시 통합 설정
\echo '=== 5단계: 멀티테넌시 통합 설정 ==='
\i database/schema/multitenancy_setup.sql

-- 6단계: 마이그레이션 검증
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== 6단계: 마이그레이션 검증 ===';
    
    -- 멀티테넌시 상태 확인
    RAISE NOTICE '멀티테넌시 상태:';
    FOR rec IN SELECT * FROM check_multitenancy_status() LOOP
        RAISE NOTICE '테이블: %, RLS: %, 정책수: %, 회사컨텍스트: %', 
            rec.table_name, rec.rls_enabled, rec.policy_count, rec.has_company_context;
    END LOOP;
    
    RAISE NOTICE '';
    
    -- 시스템 통계
    RAISE NOTICE '시스템 통계:';
    FOR rec IN SELECT * FROM get_system_multitenancy_stats() LOOP
        RAISE NOTICE '%: %', rec.metric_name, rec.metric_value;
    END LOOP;
END $$;

-- 7단계: 샘플 데이터 생성 (선택사항)
DO $$
BEGIN
    RAISE NOTICE '=== 7단계: 샘플 데이터 생성 (선택사항) ===';
    RAISE NOTICE '샘플 데이터를 생성하려면 다음 함수를 실행하세요:';
    RAISE NOTICE 'SELECT create_sample_multitenancy_data();';
    RAISE NOTICE '';
END $$;

-- 8단계: 마이그레이션 완료 로그
INSERT INTO migration_log (
    migration_name,
    description,
    executed_at,
    status
) VALUES (
    'complete_multitenancy_migration',
    '전체 멀티테넌시 마이그레이션 완료',
    now(),
    'COMPLETED'
) ON CONFLICT (migration_name) DO UPDATE SET
    executed_at = now(),
    status = 'COMPLETED';

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== QIRO 멀티테넌시 마이그레이션 완료 ===';
    RAISE NOTICE '완료 시간: %', now();
    RAISE NOTICE '';
    RAISE NOTICE '=== 다음 단계 ===';
    RAISE NOTICE '1. 애플리케이션에서 회사 컨텍스트 설정 구현';
    RAISE NOTICE '2. JWT 토큰에 company_id 포함';
    RAISE NOTICE '3. 모든 데이터베이스 연결에서 set_company_context() 호출';
    RAISE NOTICE '4. 기존 API 엔드포인트에 회사 격리 적용';
    RAISE NOTICE '5. 프론트엔드에서 회사별 데이터 표시';
    RAISE NOTICE '';
    RAISE NOTICE '=== 테스트 방법 ===';
    RAISE NOTICE '1. 두 개의 회사 생성';
    RAISE NOTICE '2. test_company_isolation(company1_id, company2_id) 함수 실행';
    RAISE NOTICE '3. 각 회사 컨텍스트에서 데이터 접근 테스트';
    RAISE NOTICE '';
    RAISE NOTICE '=== 주의사항 ===';
    RAISE NOTICE '- 모든 데이터베이스 쿼리 전에 회사 컨텍스트 설정 필수';
    RAISE NOTICE '- RLS 정책이 적용되어 잘못된 컨텍스트에서는 데이터 접근 불가';
    RAISE NOTICE '- 성능 모니터링 및 인덱스 최적화 필요';
END $$;