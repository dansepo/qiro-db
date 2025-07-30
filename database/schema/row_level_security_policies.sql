-- =====================================================
-- Row Level Security (RLS) 정책 설정 및 데이터 격리
-- 조직별 데이터 격리 및 권한 기반 접근 제어
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 애플리케이션 역할 및 컨텍스트 설정
-- =====================================================

-- 애플리케이션 역할 생성 (존재하지 않는 경우)
DO $
BEGIN
    -- 기본 애플리케이션 역할
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'application_role') THEN
        CREATE ROLE application_role;
    END IF;
    
    -- 읽기 전용 역할
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'readonly_role') THEN
        CREATE ROLE readonly_role;
    END IF;
    
    -- 관리자 역할
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_role') THEN
        CREATE ROLE admin_role;
    END IF;
    
    -- 감사 역할 (로그 조회만 가능)
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'audit_role') THEN
        CREATE ROLE audit_role;
    END IF;
END
$;

-- =====================================================
-- 2. 컨텍스트 설정 함수
-- =====================================================

-- 현재 조직 컨텍스트 설정 함수
CREATE OR REPLACE FUNCTION set_current_company_context(company_uuid UUID)
RETURNS VOID AS $
BEGIN
    PERFORM set_config('app.current_company_id', company_uuid::TEXT, false);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 현재 사용자 컨텍스트 설정 함수
CREATE OR REPLACE FUNCTION set_current_user_context(user_uuid UUID)
RETURNS VOID AS $
BEGIN
    PERFORM set_config('app.current_user_id', user_uuid::TEXT, false);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 현재 사용자 역할 컨텍스트 설정 함수
CREATE OR REPLACE FUNCTION set_current_user_role_context(user_role TEXT)
RETURNS VOID AS $
BEGIN
    PERFORM set_config('app.current_user_role', user_role, false);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 세션 컨텍스트 초기화 함수
CREATE OR REPLACE FUNCTION initialize_session_context(
    company_uuid UUID,
    user_uuid UUID,
    user_role TEXT DEFAULT 'EMPLOYEE'
)
RETURNS VOID AS $
BEGIN
    PERFORM set_current_company_context(company_uuid);
    PERFORM set_current_user_context(user_uuid);
    PERFORM set_current_user_role_context(user_role);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 현재 컨텍스트 조회 함수
CREATE OR REPLACE FUNCTION get_current_context()
RETURNS JSONB AS $
BEGIN
    RETURN jsonb_build_object(
        'company_id', current_setting('app.current_company_id', true),
        'user_id', current_setting('app.current_user_id', true),
        'user_role', current_setting('app.current_user_role', true),
        'session_user', session_user,
        'current_user', current_user
    );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. Companies 테이블 RLS 정책 개선
-- =====================================================

-- 기존 정책 삭제 후 재생성
DROP POLICY IF EXISTS company_isolation_policy ON companies;
DROP POLICY IF EXISTS company_admin_policy ON companies;

-- 조직별 데이터 격리 정책 (개선)
CREATE POLICY company_isolation_policy ON companies
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

-- 읽기 전용 접근 정책
CREATE POLICY company_readonly_policy ON companies
    FOR SELECT
    TO readonly_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 관리자 전체 접근 정책
CREATE POLICY company_admin_policy ON companies
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- 감사 역할 읽기 정책
CREATE POLICY company_audit_policy ON companies
    FOR SELECT
    TO audit_role
    USING (true);

-- =====================================================
-- 4. Users 테이블 RLS 정책 개선
-- =====================================================

-- 기존 정책 삭제 후 재생성
DROP POLICY IF EXISTS users_company_isolation_policy ON users;
DROP POLICY IF EXISTS users_admin_policy ON users;
DROP POLICY IF EXISTS users_self_access_policy ON users;

-- 조직별 사용자 데이터 격리 정책
CREATE POLICY users_company_isolation_policy ON users
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

-- 사용자 자신의 데이터 접근 정책 (읽기/수정)
CREATE POLICY users_self_access_policy ON users
    FOR ALL
    TO application_role
    USING (
        user_id = current_setting('app.current_user_id', true)::UUID
        AND company_id = current_setting('app.current_company_id', true)::UUID
    )
    WITH CHECK (
        user_id = current_setting('app.current_user_id', true)::UUID
        AND company_id = current_setting('app.current_company_id', true)::UUID
    );

-- 읽기 전용 접근 정책
CREATE POLICY users_readonly_policy ON users
    FOR SELECT
    TO readonly_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 관리자 전체 접근 정책
CREATE POLICY users_admin_policy ON users
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- 감사 역할 읽기 정책
CREATE POLICY users_audit_policy ON users
    FOR SELECT
    TO audit_role
    USING (true);

-- =====================================================
-- 5. Building_groups 테이블 RLS 정책 개선
-- =====================================================

-- 기존 정책 삭제 후 재생성
DROP POLICY IF EXISTS building_groups_company_isolation_policy ON building_groups;
DROP POLICY IF EXISTS building_groups_admin_policy ON building_groups;

-- 조직별 건물 그룹 데이터 격리 정책
CREATE POLICY building_groups_company_isolation_policy ON building_groups
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

-- 읽기 전용 접근 정책
CREATE POLICY building_groups_readonly_policy ON building_groups
    FOR SELECT
    TO readonly_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 관리자 전체 접근 정책
CREATE POLICY building_groups_admin_policy ON building_groups
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- 감사 역할 읽기 정책
CREATE POLICY building_groups_audit_policy ON building_groups
    FOR SELECT
    TO audit_role
    USING (true);

-- =====================================================
-- 6. 추가 테이블들에 대한 RLS 정책 설정
-- =====================================================

-- Building_group_assignments 테이블 RLS 설정
ALTER TABLE building_group_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY building_group_assignments_company_policy ON building_group_assignments
    FOR ALL
    TO application_role
    USING (
        EXISTS (
            SELECT 1 FROM building_groups bg 
            WHERE bg.group_id = building_group_assignments.group_id 
            AND bg.company_id = current_setting('app.current_company_id', true)::UUID
        )
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY building_group_assignments_readonly_policy ON building_group_assignments
    FOR SELECT
    TO readonly_role
    USING (
        EXISTS (
            SELECT 1 FROM building_groups bg 
            WHERE bg.group_id = building_group_assignments.group_id 
            AND bg.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

CREATE POLICY building_group_assignments_admin_policy ON building_group_assignments
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- User_group_assignments 테이블 RLS 설정
ALTER TABLE user_group_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_group_assignments_company_policy ON user_group_assignments
    FOR ALL
    TO application_role
    USING (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.user_id = user_group_assignments.user_id 
            AND u.company_id = current_setting('app.current_company_id', true)::UUID
        )
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY user_group_assignments_readonly_policy ON user_group_assignments
    FOR SELECT
    TO readonly_role
    USING (
        EXISTS (
            SELECT 1 FROM users u 
            WHERE u.user_id = user_group_assignments.user_id 
            AND u.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

CREATE POLICY user_group_assignments_admin_policy ON user_group_assignments
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- Business_verification_records 테이블 RLS 설정
ALTER TABLE business_verification_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY business_verification_records_company_policy ON business_verification_records
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY business_verification_records_readonly_policy ON business_verification_records
    FOR SELECT
    TO readonly_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

CREATE POLICY business_verification_records_admin_policy ON business_verification_records
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- Phone_verification_tokens 테이블 RLS 설정
ALTER TABLE phone_verification_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY phone_verification_tokens_company_policy ON phone_verification_tokens
    FOR ALL
    TO application_role
    USING (
        company_id = current_setting('app.current_company_id', true)::UUID
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

CREATE POLICY phone_verification_tokens_admin_policy ON phone_verification_tokens
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- Business_registration_cache 테이블 RLS 설정 (전역 캐시이므로 제한적 접근)
ALTER TABLE business_registration_cache ENABLE ROW LEVEL SECURITY;

CREATE POLICY business_registration_cache_app_policy ON business_registration_cache
    FOR SELECT
    TO application_role
    USING (true); -- 읽기는 모든 애플리케이션에서 가능

CREATE POLICY business_registration_cache_update_policy ON business_registration_cache
    FOR INSERT, UPDATE, DELETE
    TO application_role
    USING (true); -- 쓰기는 애플리케이션 역할만 가능

CREATE POLICY business_registration_cache_admin_policy ON business_registration_cache
    FOR ALL
    TO admin_role, postgres
    USING (true);

-- =====================================================
-- 7. 권한 부여
-- =====================================================

-- 기본 테이블 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON companies TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON building_groups TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON building_group_assignments TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON user_group_assignments TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON business_verification_records TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON phone_verification_tokens TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON business_registration_cache TO application_role;

-- 읽기 전용 권한
GRANT SELECT ON companies TO readonly_role;
GRANT SELECT ON users TO readonly_role;
GRANT SELECT ON building_groups TO readonly_role;
GRANT SELECT ON building_group_assignments TO readonly_role;
GRANT SELECT ON user_group_assignments TO readonly_role;
GRANT SELECT ON business_verification_records TO readonly_role;

-- 관리자 권한
GRANT ALL PRIVILEGES ON companies TO admin_role;
GRANT ALL PRIVILEGES ON users TO admin_role;
GRANT ALL PRIVILEGES ON building_groups TO admin_role;
GRANT ALL PRIVILEGES ON building_group_assignments TO admin_role;
GRANT ALL PRIVILEGES ON user_group_assignments TO admin_role;
GRANT ALL PRIVILEGES ON business_verification_records TO admin_role;
GRANT ALL PRIVILEGES ON phone_verification_tokens TO admin_role;
GRANT ALL PRIVILEGES ON business_registration_cache TO admin_role;

-- 감사 역할 권한 (읽기만)
GRANT SELECT ON companies TO audit_role;
GRANT SELECT ON users TO audit_role;
GRANT SELECT ON building_groups TO audit_role;
GRANT SELECT ON building_group_assignments TO audit_role;
GRANT SELECT ON user_group_assignments TO audit_role;
GRANT SELECT ON business_verification_records TO audit_role;

-- 함수 실행 권한
GRANT EXECUTE ON FUNCTION set_current_company_context(UUID) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION set_current_user_context(UUID) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION set_current_user_role_context(TEXT) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION initialize_session_context(UUID, UUID, TEXT) TO application_role, admin_role;
GRANT EXECUTE ON FUNCTION get_current_context() TO application_role, readonly_role, admin_role, audit_role;

-- =====================================================
-- 8. RLS 정책 테스트 함수
-- =====================================================

-- RLS 정책 테스트 함수
CREATE OR REPLACE FUNCTION test_rls_policies(
    test_company_id UUID,
    test_user_id UUID,
    test_user_role TEXT DEFAULT 'EMPLOYEE'
)
RETURNS JSONB AS $
DECLARE
    result JSONB;
    company_count INTEGER;
    user_count INTEGER;
    group_count INTEGER;
BEGIN
    -- 컨텍스트 설정
    PERFORM initialize_session_context(test_company_id, test_user_id, test_user_role);
    
    -- 각 테이블별 접근 가능한 레코드 수 확인
    SELECT COUNT(*) INTO company_count FROM companies;
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO group_count FROM building_groups;
    
    result := jsonb_build_object(
        'context', get_current_context(),
        'accessible_records', jsonb_build_object(
            'companies', company_count,
            'users', user_count,
            'building_groups', group_count
        ),
        'test_timestamp', now()
    );
    
    RETURN result;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. 모니터링 및 감사 함수
-- =====================================================

-- RLS 정책 상태 조회 함수
CREATE OR REPLACE FUNCTION get_rls_policy_status()
RETURNS TABLE (
    table_name TEXT,
    rls_enabled BOOLEAN,
    policy_count BIGINT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        t.rowsecurity,
        COUNT(p.policyname)
    FROM pg_tables t
    LEFT JOIN pg_policies p ON t.tablename = p.tablename
    WHERE t.schemaname = 'public'
    AND t.tablename IN ('companies', 'users', 'building_groups', 'building_group_assignments', 
                       'user_group_assignments', 'business_verification_records', 
                       'phone_verification_tokens', 'business_registration_cache')
    GROUP BY t.tablename, t.rowsecurity
    ORDER BY t.tablename;
END;
$ LANGUAGE plpgsql;

-- 현재 세션의 접근 권한 요약 함수
CREATE OR REPLACE FUNCTION get_current_session_permissions()
RETURNS JSONB AS $
DECLARE
    result JSONB;
    current_role TEXT;
BEGIN
    SELECT current_user INTO current_role;
    
    result := jsonb_build_object(
        'current_user', current_role,
        'session_user', session_user,
        'context', get_current_context(),
        'rls_status', (
            SELECT jsonb_agg(
                jsonb_build_object(
                    'table', table_name,
                    'rls_enabled', rls_enabled,
                    'policy_count', policy_count
                )
            )
            FROM get_rls_policy_status()
        )
    );
    
    RETURN result;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 10. 코멘트 추가
-- =====================================================

COMMENT ON FUNCTION set_current_company_context(UUID) IS '현재 세션의 조직 컨텍스트 설정';
COMMENT ON FUNCTION set_current_user_context(UUID) IS '현재 세션의 사용자 컨텍스트 설정';
COMMENT ON FUNCTION set_current_user_role_context(TEXT) IS '현재 세션의 사용자 역할 컨텍스트 설정';
COMMENT ON FUNCTION initialize_session_context(UUID, UUID, TEXT) IS '세션 컨텍스트 일괄 초기화';
COMMENT ON FUNCTION get_current_context() IS '현재 세션 컨텍스트 조회';
COMMENT ON FUNCTION test_rls_policies(UUID, UUID, TEXT) IS 'RLS 정책 테스트 함수';
COMMENT ON FUNCTION get_rls_policy_status() IS 'RLS 정책 상태 조회';
COMMENT ON FUNCTION get_current_session_permissions() IS '현재 세션 권한 요약 조회';