-- =====================================================
-- QIRO 멀티테넌시 환경 성능 최적화 인덱스
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 멀티테넌시 환경에서 성능 최적화를 위한 인덱스 설계
-- =====================================================

-- =====================================================
-- 1. 멀티테넌시 핵심 인덱스 (company_id 기반)
-- =====================================================

-- Companies 테이블 최적화 인덱스
-- 사업자등록번호 검색 최적화 (이미 UNIQUE 제약조건으로 존재)
-- CREATE UNIQUE INDEX idx_companies_business_registration_number ON companies(business_registration_number);

-- 인증 상태별 회사 조회 최적화
CREATE INDEX IF NOT EXISTS idx_companies_verification_status_active 
ON companies(verification_status, subscription_status) 
WHERE verification_status = 'VERIFIED' AND subscription_status = 'ACTIVE';

-- 구독 만료 예정 회사 조회 최적화
CREATE INDEX IF NOT EXISTS idx_companies_subscription_expiry 
ON companies(subscription_end_date) 
WHERE subscription_end_date IS NOT NULL AND subscription_status = 'ACTIVE';

-- 회사명 전문 검색 최적화 (한국어 지원)
CREATE INDEX IF NOT EXISTS idx_companies_name_fulltext 
ON companies USING gin(to_tsvector('korean', company_name));

-- =====================================================
-- 2. Users 테이블 멀티테넌시 최적화 인덱스
-- =====================================================

-- 조직별 활성 사용자 조회 최적화 (가장 빈번한 쿼리)
CREATE INDEX IF NOT EXISTS idx_users_company_status_active 
ON users(company_id, status) 
WHERE status = 'ACTIVE';

-- 조직별 사용자 타입 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_user_type 
ON users(company_id, user_type);

-- 조직별 이메일 인증 상태 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_email_verified 
ON users(company_id, email_verified) 
WHERE email_verified = false;

-- 조직별 전화번호 인증 상태 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_phone_verified 
ON users(company_id, phone_verified) 
WHERE phone_verified = false;

-- 조직별 로그인 실패 계정 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_failed_attempts 
ON users(company_id, failed_login_attempts) 
WHERE failed_login_attempts > 0;

-- 조직별 잠긴 계정 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_locked 
ON users(company_id, locked_until) 
WHERE locked_until IS NOT NULL AND locked_until > now();

-- 조직별 최근 로그인 사용자 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_last_login 
ON users(company_id, last_login_at DESC NULLS LAST);

-- 조직별 사용자 생성일 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_company_created_at 
ON users(company_id, created_at DESC);

-- =====================================================
-- 3. Roles 테이블 멀티테넌시 최적화 인덱스
-- =====================================================

-- 조직별 활성 역할 조회 최적화
CREATE INDEX IF NOT EXISTS idx_roles_company_active 
ON roles(company_id, is_active) 
WHERE is_active = true;

-- 조직별 시스템 역할 조회 최적화
CREATE INDEX IF NOT EXISTS idx_roles_company_system 
ON roles(company_id, is_system_role) 
WHERE is_system_role = true;

-- 조직별 역할 코드 조회 최적화
CREATE INDEX IF NOT EXISTS idx_roles_company_role_code 
ON roles(company_id, role_code);

-- =====================================================
-- 4. User_role_links 테이블 최적화 인덱스
-- =====================================================

-- 사용자별 역할 조회 최적화 (이미 PRIMARY KEY로 존재)
-- CREATE INDEX idx_user_role_links_user_id ON user_role_links(user_id);

-- 역할별 사용자 조회 최적화 (이미 PRIMARY KEY로 존재)
-- CREATE INDEX idx_user_role_links_role_id ON user_role_links(role_id);

-- 역할 배정일 기준 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_role_links_assigned_at 
ON user_role_links(assigned_at DESC);

-- 배정자별 이력 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_role_links_assigned_by 
ON user_role_links(assigned_by) 
WHERE assigned_by IS NOT NULL;

-- =====================================================
-- 5. Building_groups 테이블 멀티테넌시 최적화 인덱스
-- =====================================================

-- 조직별 활성 그룹 조회 최적화 (이미 존재)
-- CREATE INDEX idx_building_groups_company_active ON building_groups(company_id, is_active) WHERE is_active = true;

-- 조직별 그룹 타입 조회 최적화 (이미 존재)
-- CREATE INDEX idx_building_groups_company_type ON building_groups(company_id, group_type);

-- 조직별 그룹명 검색 최적화 (한국어 지원)
CREATE INDEX IF NOT EXISTS idx_building_groups_company_name_search 
ON building_groups(company_id) 
INCLUDE (group_name, group_type, is_active);

-- 조직별 그룹 생성일 조회 최적화
CREATE INDEX IF NOT EXISTS idx_building_groups_company_created_at 
ON building_groups(company_id, created_at DESC);

-- =====================================================
-- 6. Building_group_assignments 테이블 최적화 인덱스
-- =====================================================

-- 그룹별 활성 건물 조회 최적화 (이미 존재)
-- CREATE INDEX idx_building_group_assignments_group_active ON building_group_assignments(group_id, is_active) WHERE is_active = true;

-- 건물별 활성 그룹 조회 최적화 (이미 존재)
-- CREATE INDEX idx_building_group_assignments_building_active ON building_group_assignments(building_id, is_active) WHERE is_active = true;

-- 배정 이력 조회 최적화
CREATE INDEX IF NOT EXISTS idx_building_group_assignments_history 
ON building_group_assignments(assigned_at DESC, unassigned_at DESC NULLS FIRST);

-- 배정자별 작업 이력 조회 최적화
CREATE INDEX IF NOT EXISTS idx_building_group_assignments_assigned_by_date 
ON building_group_assignments(assigned_by, assigned_at DESC) 
WHERE assigned_by IS NOT NULL;

-- =====================================================
-- 7. User_group_assignments 테이블 최적화 인덱스
-- =====================================================

-- 사용자별 활성 그룹 배정 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_user_active 
ON user_group_assignments(user_id, is_active) 
WHERE is_active = true;

-- 그룹별 활성 담당자 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_group_active 
ON user_group_assignments(group_id, is_active) 
WHERE is_active = true;

-- 접근 권한 레벨별 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_access_level 
ON user_group_assignments(group_id, access_level, is_active) 
WHERE is_active = true;

-- 배정 만료일 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_expires_at 
ON user_group_assignments(expires_at) 
WHERE expires_at IS NOT NULL AND is_active = true;

-- 배정 이력 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_assigned_at 
ON user_group_assignments(assigned_at DESC);

-- =====================================================
-- 8. Business_verification_records 테이블 최적화 인덱스
-- =====================================================

-- 조직별 인증 기록 조회 최적화
CREATE INDEX IF NOT EXISTS idx_business_verification_company_type 
ON business_verification_records(company_id, verification_type);

-- 인증 상태별 조회 최적화
CREATE INDEX IF NOT EXISTS idx_business_verification_status 
ON business_verification_records(verification_status, verification_type);

-- 인증 만료 예정 기록 조회 최적화
CREATE INDEX IF NOT EXISTS idx_business_verification_expiry 
ON business_verification_records(expiry_date) 
WHERE expiry_date IS NOT NULL AND verification_status = 'SUCCESS';

-- 인증 생성일 조회 최적화
CREATE INDEX IF NOT EXISTS idx_business_verification_created_at 
ON business_verification_records(company_id, created_at DESC);

-- =====================================================
-- 9. Phone_verification_tokens 테이블 최적화 인덱스
-- =====================================================

-- 사용자별 활성 토큰 조회 최적화
CREATE INDEX IF NOT EXISTS idx_phone_verification_user_active 
ON phone_verification_tokens(user_id, is_used, expires_at) 
WHERE is_used = false AND expires_at > now();

-- 전화번호별 토큰 조회 최적화
CREATE INDEX IF NOT EXISTS idx_phone_verification_phone_active 
ON phone_verification_tokens(phone_number, is_used, expires_at) 
WHERE is_used = false AND expires_at > now();

-- 만료된 토큰 정리용 인덱스
CREATE INDEX IF NOT EXISTS idx_phone_verification_expired 
ON phone_verification_tokens(expires_at) 
WHERE expires_at <= now();

-- 토큰 해시 조회 최적화
CREATE INDEX IF NOT EXISTS idx_phone_verification_token_hash 
ON phone_verification_tokens(token_hash) 
WHERE is_used = false;

-- =====================================================
-- 10. Buildings 테이블 멀티테넌시 최적화 인덱스 (기존 테이블 확장)
-- =====================================================

-- 조직별 건물 조회 최적화 (company_id 컬럼이 추가된 경우)
CREATE INDEX IF NOT EXISTS idx_buildings_company_id 
ON buildings(company_id) 
WHERE company_id IS NOT NULL;

-- 조직별 활성 건물 조회 최적화
CREATE INDEX IF NOT EXISTS idx_buildings_company_status 
ON buildings(company_id, status) 
WHERE company_id IS NOT NULL AND status = 'ACTIVE';

-- 조직별 건물 타입 조회 최적화
CREATE INDEX IF NOT EXISTS idx_buildings_company_type 
ON buildings(company_id, building_type) 
WHERE company_id IS NOT NULL;

-- 조직별 건물명 검색 최적화 (한국어 지원)
CREATE INDEX IF NOT EXISTS idx_buildings_company_name_search 
ON buildings(company_id) 
INCLUDE (name, address, building_type, status) 
WHERE company_id IS NOT NULL;

-- =====================================================
-- 11. RLS 성능 최적화를 위한 특수 인덱스
-- =====================================================

-- RLS 정책에서 사용되는 current_setting 함수 최적화를 위한 인덱스
-- 이 인덱스들은 RLS 정책이 적용될 때 성능을 크게 향상시킵니다.

-- Companies 테이블 RLS 최적화
CREATE INDEX IF NOT EXISTS idx_companies_rls_optimization 
ON companies(company_id) 
INCLUDE (company_name, verification_status, subscription_status);

-- Users 테이블 RLS 최적화
CREATE INDEX IF NOT EXISTS idx_users_rls_optimization 
ON users(company_id) 
INCLUDE (user_id, email, full_name, user_type, status);

-- Building_groups 테이블 RLS 최적화
CREATE INDEX IF NOT EXISTS idx_building_groups_rls_optimization 
ON building_groups(company_id) 
INCLUDE (group_id, group_name, group_type, is_active);

-- Roles 테이블 RLS 최적화
CREATE INDEX IF NOT EXISTS idx_roles_rls_optimization 
ON roles(company_id) 
INCLUDE (role_id, role_name, role_code, is_system_role, is_active);

-- =====================================================
-- 12. 복합 쿼리 최적화를 위한 커버링 인덱스
-- =====================================================

-- 사용자 대시보드 조회 최적화 (사용자 + 역할 + 그룹 정보)
CREATE INDEX IF NOT EXISTS idx_users_dashboard_optimization 
ON users(company_id, user_id) 
INCLUDE (email, full_name, user_type, status, last_login_at, created_at);

-- 그룹 관리 대시보드 최적화 (그룹 + 건물 수 + 담당자 수)
CREATE INDEX IF NOT EXISTS idx_building_groups_dashboard_optimization 
ON building_groups(company_id, is_active) 
INCLUDE (group_id, group_name, group_type, created_at, updated_at);

-- 건물 배정 현황 조회 최적화
CREATE INDEX IF NOT EXISTS idx_building_assignments_status_optimization 
ON building_group_assignments(group_id, is_active) 
INCLUDE (building_id, assigned_at, assigned_by);

-- 사용자 권한 조회 최적화
CREATE INDEX IF NOT EXISTS idx_user_permissions_optimization 
ON user_role_links(user_id) 
INCLUDE (role_id, assigned_at, assigned_by);

-- =====================================================
-- 13. 통계 및 리포팅 최적화 인덱스
-- =====================================================

-- 월별 가입 통계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_companies_monthly_stats 
ON companies(DATE_TRUNC('month', created_at), verification_status);

-- 사용자 활동 통계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_users_activity_stats 
ON users(company_id, DATE_TRUNC('month', last_login_at)) 
WHERE last_login_at IS NOT NULL;

-- 그룹 사용 통계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_building_groups_usage_stats 
ON building_groups(company_id, group_type, DATE_TRUNC('month', created_at));

-- =====================================================
-- 14. 인덱스 사용량 모니터링을 위한 뷰 생성
-- =====================================================

-- 인덱스 사용 통계 뷰
CREATE OR REPLACE VIEW v_index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'LOW_USAGE'
        WHEN idx_scan < 1000 THEN 'MEDIUM_USAGE'
        ELSE 'HIGH_USAGE'
    END as usage_level
FROM pg_stat_user_indexes
WHERE schemaname = current_schema()
ORDER BY idx_scan DESC;

-- 테이블 크기 및 인덱스 크기 모니터링 뷰
CREATE OR REPLACE VIEW v_table_index_sizes AS
SELECT 
    t.tablename,
    pg_size_pretty(pg_total_relation_size(t.schemaname||'.'||t.tablename)) as total_size,
    pg_size_pretty(pg_relation_size(t.schemaname||'.'||t.tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(t.schemaname||'.'||t.tablename) - pg_relation_size(t.schemaname||'.'||t.tablename)) as index_size,
    ROUND(
        (pg_total_relation_size(t.schemaname||'.'||t.tablename) - pg_relation_size(t.schemaname||'.'||t.tablename))::NUMERIC / 
        pg_total_relation_size(t.schemaname||'.'||t.tablename) * 100, 2
    ) as index_ratio_percent
FROM pg_tables t
WHERE t.schemaname = current_schema()
ORDER BY pg_total_relation_size(t.schemaname||'.'||t.tablename) DESC;

-- =====================================================
-- 15. 인덱스 유지보수 함수
-- =====================================================

-- 사용되지 않는 인덱스 조회 함수
CREATE OR REPLACE FUNCTION get_unused_indexes()
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    index_size TEXT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        s.schemaname::TEXT,
        s.tablename::TEXT,
        s.indexname::TEXT,
        pg_size_pretty(pg_relation_size(s.schemaname||'.'||s.indexname))::TEXT
    FROM pg_stat_user_indexes s
    JOIN pg_index i ON s.indexrelid = i.indexrelid
    WHERE 
        s.idx_scan = 0
        AND NOT i.indisunique
        AND NOT i.indisprimary
        AND s.schemaname = current_schema()
    ORDER BY pg_relation_size(s.schemaname||'.'||s.indexname) DESC;
END;
$ LANGUAGE plpgsql;

-- 인덱스 재구성 함수 (REINDEX)
CREATE OR REPLACE FUNCTION reindex_multitenancy_tables()
RETURNS TEXT AS $
DECLARE
    table_name TEXT;
    result_text TEXT := '';
BEGIN
    -- 멀티테넌시 핵심 테이블들에 대해 REINDEX 수행
    FOR table_name IN 
        SELECT unnest(ARRAY['companies', 'users', 'roles', 'user_role_links', 
                           'building_groups', 'building_group_assignments', 
                           'user_group_assignments', 'business_verification_records', 
                           'phone_verification_tokens'])
    LOOP
        EXECUTE 'REINDEX TABLE ' || table_name;
        result_text := result_text || 'REINDEXED: ' || table_name || E'\n';
    END LOOP;
    
    RETURN result_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 16. 코멘트 추가
-- =====================================================

COMMENT ON INDEX idx_companies_verification_status_active IS '인증된 활성 회사 조회 최적화';
COMMENT ON INDEX idx_companies_subscription_expiry IS '구독 만료 예정 회사 조회 최적화';
COMMENT ON INDEX idx_companies_name_fulltext IS '회사명 전문 검색 최적화 (한국어 지원)';

COMMENT ON INDEX idx_users_company_status_active IS '조직별 활성 사용자 조회 최적화 (가장 빈번한 쿼리)';
COMMENT ON INDEX idx_users_company_user_type IS '조직별 사용자 타입 조회 최적화';
COMMENT ON INDEX idx_users_company_email_verified IS '조직별 이메일 미인증 사용자 조회 최적화';
COMMENT ON INDEX idx_users_company_phone_verified IS '조직별 전화번호 미인증 사용자 조회 최적화';

COMMENT ON INDEX idx_building_groups_company_name_search IS '조직별 그룹명 검색 최적화 (커버링 인덱스)';
COMMENT ON INDEX idx_building_groups_company_created_at IS '조직별 그룹 생성일 조회 최적화';

COMMENT ON VIEW v_index_usage_stats IS '인덱스 사용량 통계 모니터링 뷰';
COMMENT ON VIEW v_table_index_sizes IS '테이블 및 인덱스 크기 모니터링 뷰';

COMMENT ON FUNCTION get_unused_indexes() IS '사용되지 않는 인덱스 조회 함수';
COMMENT ON FUNCTION reindex_multitenancy_tables() IS '멀티테넌시 핵심 테이블 인덱스 재구성 함수';

-- =====================================================
-- 17. 인덱스 생성 완료 로그
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '멀티테넌시 환경 성능 최적화 인덱스 생성이 완료되었습니다.';
    RAISE NOTICE '총 % 개의 인덱스가 생성되었습니다.', (
        SELECT COUNT(*) 
        FROM pg_indexes 
        WHERE schemaname = current_schema() 
        AND indexname LIKE 'idx_%'
    );
END
$;