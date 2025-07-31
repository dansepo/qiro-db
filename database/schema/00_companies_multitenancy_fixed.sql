-- =====================================================
-- QIRO 사업자 회원가입 및 멀티테넌시 구조 (수정된 버전)
-- Companies 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 수정일: 2025-01-31 (실제 DB 적용 후 수정)
-- =====================================================

-- 스키마 설정
SET search_path TO bms;

-- 확장 기능 활성화 (필요시)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. 사업자 관련 ENUM 타입 정의
-- =====================================================

-- ENUM 타입 생성 (IF NOT EXISTS 방식)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_status' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.subscription_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CANCELLED', 'TRIAL');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_type' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.user_type AS ENUM ('SUPER_ADMIN', 'EMPLOYEE');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_status' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.user_status AS ENUM ('ACTIVE', 'INACTIVE', 'LOCKED', 'PENDING_VERIFICATION');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'group_type' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.group_type AS ENUM ('COST_ALLOCATION', 'MANAGEMENT_UNIT', 'GEOGRAPHIC', 'CUSTOM');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'access_level' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.access_level AS ENUM ('read', 'write', 'admin');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_type' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.verification_type AS ENUM ('BUSINESS_REGISTRATION', 'PHONE', 'EMAIL', 'DOCUMENT');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verification_result' AND typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'bms')) THEN
        CREATE TYPE bms.verification_result AS ENUM ('SUCCESS', 'FAILED', 'PENDING', 'EXPIRED');
    END IF;
END
$$;

-- =====================================================
-- 2. 공통 함수 정의
-- =====================================================

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 사업자등록번호 검증 함수 (수정된 버전)
CREATE OR REPLACE FUNCTION validate_business_registration_number(brn TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    digits INTEGER[];
    check_sum INTEGER;
    calculated_check INTEGER;
BEGIN
    -- 사업자등록번호 형식 검증 (10자리 숫자) - 정규식 수정
    IF brn IS NULL OR LENGTH(brn) != 10 OR brn !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 각 자리수를 배열로 변환
    FOR i IN 1..10 LOOP
        digits[i] := SUBSTRING(brn FROM i FOR 1)::INTEGER;
    END LOOP;
    
    -- 체크섬 계산
    check_sum := digits[1] * 1 + digits[2] * 3 + digits[3] * 7 + digits[4] * 1 + 
                 digits[5] * 3 + digits[6] * 7 + digits[7] * 1 + digits[8] * 3 + 
                 (digits[9] * 5) % 10;
    
    calculated_check := (10 - (check_sum % 10)) % 10;
    
    -- 마지막 자리수와 계산된 체크 디지트 비교
    RETURN calculated_check = digits[10];
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Companies 테이블 생성
-- =====================================================

CREATE TABLE IF NOT EXISTS companies (
    company_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_registration_number VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    representative_name VARCHAR(100) NOT NULL,
    business_address TEXT NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    business_type VARCHAR(50) NOT NULL,
    establishment_date DATE NOT NULL,
    
    -- 인증 관련 필드
    verification_status verification_status NOT NULL DEFAULT 'PENDING',
    verification_date TIMESTAMPTZ,
    verification_data JSONB DEFAULT '{}',
    
    -- 구독 관련 필드
    subscription_plan VARCHAR(50) DEFAULT 'BASIC',
    subscription_status subscription_status DEFAULT 'TRIAL',
    subscription_start_date TIMESTAMPTZ DEFAULT now(),
    subscription_end_date TIMESTAMPTZ,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건 (검증 함수 제외 - 필요시 별도 추가)
    CONSTRAINT chk_establishment_date 
        CHECK (establishment_date <= CURRENT_DATE)
);

-- =====================================================
-- 4. 사용자 관리 테이블들
-- =====================================================

-- 역할 테이블
CREATE TABLE IF NOT EXISTS roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    role_name VARCHAR(100) NOT NULL,
    role_code VARCHAR(50) NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '{}',
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    CONSTRAINT uk_company_role_code UNIQUE (company_id, role_code)
);

-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    user_type user_type NOT NULL DEFAULT 'EMPLOYEE',
    status user_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    last_login_ip INET,
    password_changed_at TIMESTAMPTZ DEFAULT now(),
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID
);

-- 사용자-역할 연결 테이블
CREATE TABLE IF NOT EXISTS user_role_links (
    link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT now(),
    assigned_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT uk_user_role UNIQUE (user_id, role_id)
);

-- =====================================================
-- 5. 건물 그룹 관리 테이블들
-- =====================================================

-- 건물 그룹 테이블
CREATE TABLE IF NOT EXISTS building_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    group_name VARCHAR(255) NOT NULL,
    group_type group_type NOT NULL DEFAULT 'CUSTOM',
    description TEXT,
    parent_group_id UUID REFERENCES building_groups(group_id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    CONSTRAINT uk_company_group_name UNIQUE (company_id, group_name),
    CONSTRAINT chk_no_self_parent CHECK (group_id != parent_group_id)
);

-- 건물 테이블 (간단한 버전)
CREATE TABLE IF NOT EXISTS buildings (
    building_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    building_type VARCHAR(50) DEFAULT 'APARTMENT',
    total_floors INTEGER DEFAULT 1,
    total_area DECIMAL(12,2) DEFAULT 0,
    total_units INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID
);

-- 건물 그룹 배정 테이블
CREATE TABLE IF NOT EXISTS building_group_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES building_groups(group_id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES buildings(building_id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ DEFAULT now(),
    assigned_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT uk_group_building UNIQUE (group_id, building_id)
);

-- 사용자 그룹 배정 테이블
CREATE TABLE IF NOT EXISTS user_group_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES building_groups(group_id) ON DELETE CASCADE,
    access_level access_level NOT NULL DEFAULT 'read',
    assigned_at TIMESTAMPTZ DEFAULT now(),
    assigned_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT uk_user_group UNIQUE (user_id, group_id)
);

-- =====================================================
-- 6. 인증 관련 테이블들
-- =====================================================

-- 사업자 인증 레코드 테이블
CREATE TABLE IF NOT EXISTS business_verification_records (
    verification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    verification_type verification_type NOT NULL,
    verification_data JSONB NOT NULL DEFAULT '{}',
    verification_status verification_result NOT NULL DEFAULT 'PENDING',
    verification_date TIMESTAMPTZ,
    verification_response JSONB DEFAULT '{}',
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    created_by UUID,
    updated_by UUID
);

-- 전화번호 인증 토큰 테이블 (파티션, PRIMARY KEY 수정)
CREATE TABLE IF NOT EXISTS phone_verification_tokens (
    token_id UUID DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    verification_code VARCHAR(10) NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    PRIMARY KEY (token_id, created_at),
    CONSTRAINT chk_expires_future CHECK (expires_at > created_at)
) PARTITION BY RANGE (created_at);

-- 이메일 인증 토큰 테이블 (파티션, PRIMARY KEY 수정)
CREATE TABLE IF NOT EXISTS email_verification_tokens (
    token_id UUID DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    verification_token VARCHAR(255) NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    PRIMARY KEY (token_id, created_at),
    CONSTRAINT chk_email_expires_future CHECK (expires_at > created_at)
) PARTITION BY RANGE (created_at);

-- =====================================================
-- 7. 파티션 테이블 생성
-- =====================================================

-- 현재 월 파티션 생성
DO $$
BEGIN
    -- 전화번호 인증 토큰 파티션
    IF NOT EXISTS (
        SELECT 1 FROM pg_class WHERE relname = 'phone_verification_tokens_current'
    ) THEN
        EXECUTE format(
            'CREATE TABLE phone_verification_tokens_current PARTITION OF phone_verification_tokens
             FOR VALUES FROM (%L) TO (%L)',
            date_trunc('month', CURRENT_DATE),
            date_trunc('month', CURRENT_DATE) + INTERVAL '1 month'
        );
    END IF;
    
    -- 이메일 인증 토큰 파티션
    IF NOT EXISTS (
        SELECT 1 FROM pg_class WHERE relname = 'email_verification_tokens_current'
    ) THEN
        EXECUTE format(
            'CREATE TABLE email_verification_tokens_current PARTITION OF email_verification_tokens
             FOR VALUES FROM (%L) TO (%L)',
            date_trunc('month', CURRENT_DATE),
            date_trunc('month', CURRENT_DATE) + INTERVAL '1 month'
        );
    END IF;
END
$$;

-- =====================================================
-- 8. 트리거 생성
-- =====================================================

-- 트리거 생성 (IF NOT EXISTS 방식)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'companies_updated_at_trigger') THEN
        CREATE TRIGGER companies_updated_at_trigger
            BEFORE UPDATE ON companies
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'roles_updated_at_trigger') THEN
        CREATE TRIGGER roles_updated_at_trigger
            BEFORE UPDATE ON roles
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'users_updated_at_trigger') THEN
        CREATE TRIGGER users_updated_at_trigger
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'building_groups_updated_at_trigger') THEN
        CREATE TRIGGER building_groups_updated_at_trigger
            BEFORE UPDATE ON building_groups
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'buildings_updated_at_trigger') THEN
        CREATE TRIGGER buildings_updated_at_trigger
            BEFORE UPDATE ON buildings
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'business_verification_records_updated_at_trigger') THEN
        CREATE TRIGGER business_verification_records_updated_at_trigger
            BEFORE UPDATE ON business_verification_records
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

-- =====================================================
-- 9. 인덱스 생성
-- =====================================================

-- 인덱스 생성 (IF NOT EXISTS 방식)
CREATE INDEX IF NOT EXISTS idx_companies_verification_status ON companies(verification_status);
CREATE INDEX IF NOT EXISTS idx_companies_subscription_status ON companies(subscription_status);
CREATE INDEX IF NOT EXISTS idx_companies_created_at ON companies(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_roles_company_id ON roles(company_id);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_user_role_links_user_id ON user_role_links(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_links_role_id ON user_role_links(role_id);

CREATE INDEX IF NOT EXISTS idx_building_groups_company_id ON building_groups(company_id);
CREATE INDEX IF NOT EXISTS idx_building_groups_parent_id ON building_groups(parent_group_id);
CREATE INDEX IF NOT EXISTS idx_buildings_company_id ON buildings(company_id);
CREATE INDEX IF NOT EXISTS idx_building_group_assignments_group_id ON building_group_assignments(group_id);
CREATE INDEX IF NOT EXISTS idx_building_group_assignments_building_id ON building_group_assignments(building_id);
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_user_id ON user_group_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_group_assignments_group_id ON user_group_assignments(group_id);

CREATE INDEX IF NOT EXISTS idx_business_verification_records_company_id ON business_verification_records(company_id);
CREATE INDEX IF NOT EXISTS idx_business_verification_records_status ON business_verification_records(verification_status);
CREATE INDEX IF NOT EXISTS idx_business_verification_records_created_at ON business_verification_records(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_phone_verification_tokens_user_id ON phone_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_phone_verification_tokens_phone ON phone_verification_tokens(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_verification_tokens_expires ON phone_verification_tokens(expires_at);

CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_user_id ON email_verification_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_email ON email_verification_tokens(email);
CREATE INDEX IF NOT EXISTS idx_email_verification_tokens_expires ON email_verification_tokens(expires_at);

-- =====================================================
-- 10. RLS 정책 설정
-- =====================================================

-- 애플리케이션 역할 생성
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'application_role') THEN
        CREATE ROLE application_role;
    END IF;
END
$$;

-- 권한 부여
GRANT USAGE ON SCHEMA bms TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bms TO application_role;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA bms TO application_role;

-- RLS 활성화
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE building_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;
ALTER TABLE building_group_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_group_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_verification_records ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성 (IF NOT EXISTS 방식)
DO $$
BEGIN
    -- Companies 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'company_isolation_policy' AND tablename = 'companies') THEN
        CREATE POLICY company_isolation_policy ON companies
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- Users 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'user_isolation_policy' AND tablename = 'users') THEN
        CREATE POLICY user_isolation_policy ON users
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- Roles 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'role_isolation_policy' AND tablename = 'roles') THEN
        CREATE POLICY role_isolation_policy ON roles
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- Building Groups 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'building_group_isolation_policy' AND tablename = 'building_groups') THEN
        CREATE POLICY building_group_isolation_policy ON building_groups
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- Buildings 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'building_isolation_policy' AND tablename = 'buildings') THEN
        CREATE POLICY building_isolation_policy ON buildings
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- Building Group Assignments 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'building_group_assignment_isolation_policy' AND tablename = 'building_group_assignments') THEN
        CREATE POLICY building_group_assignment_isolation_policy ON building_group_assignments
            FOR ALL
            TO application_role
            USING (
                group_id IN (
                    SELECT group_id FROM building_groups 
                    WHERE company_id = current_setting('app.current_company_id', true)::UUID
                )
            );
    END IF;
    
    -- User Group Assignments 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'user_group_assignment_isolation_policy' AND tablename = 'user_group_assignments') THEN
        CREATE POLICY user_group_assignment_isolation_policy ON user_group_assignments
            FOR ALL
            TO application_role
            USING (
                user_id IN (
                    SELECT user_id FROM users 
                    WHERE company_id = current_setting('app.current_company_id', true)::UUID
                )
            );
    END IF;
    
    -- Business Verification Records 정책
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'verification_record_isolation_policy' AND tablename = 'business_verification_records') THEN
        CREATE POLICY verification_record_isolation_policy ON business_verification_records
            FOR ALL
            TO application_role
            USING (company_id = current_setting('app.current_company_id', true)::UUID);
    END IF;
    
    -- 관리자 전체 접근 정책들
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'admin_full_access_companies' AND tablename = 'companies') THEN
        CREATE POLICY admin_full_access_companies ON companies
            FOR ALL
            TO postgres
            USING (true);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_policy WHERE policyname = 'admin_full_access_users' AND tablename = 'users') THEN
        CREATE POLICY admin_full_access_users ON users
            FOR ALL
            TO postgres
            USING (true);
    END IF;
END
$$;

-- =====================================================
-- 11. 코멘트 추가
-- =====================================================

COMMENT ON TABLE companies IS '사업자 회원가입 및 조직 정보 관리 테이블';
COMMENT ON TABLE users IS '사용자 정보 관리 테이블';
COMMENT ON TABLE roles IS '역할 정보 관리 테이블';
COMMENT ON TABLE building_groups IS '건물 그룹 관리 테이블';
COMMENT ON TABLE buildings IS '건물 정보 관리 테이블';
COMMENT ON TABLE business_verification_records IS '사업자 인증 레코드 테이블';

COMMENT ON FUNCTION validate_business_registration_number(TEXT) IS '사업자등록번호 유효성 검증 함수';
COMMENT ON FUNCTION update_updated_at_column() IS 'updated_at 컬럼 자동 업데이트 트리거 함수';

-- =====================================================
-- 12. 완료 메시지
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== QIRO 멀티테넌시 스키마 생성 완료 ===';
    RAISE NOTICE '생성된 테이블 수: %', (
        SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'bms'
    );
    RAISE NOTICE '생성된 인덱스 수: %', (
        SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'bms'
    );
    RAISE NOTICE '활성화된 RLS 테이블 수: %', (
        SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'bms' AND rowsecurity = true
    );
END
$$;