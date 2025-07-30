-- =====================================================
-- QIRO 사업자 회원가입 및 멀티테넌시 구조
-- Roles 및 User_role_links 테이블 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. Roles 테이블 생성
-- =====================================================

CREATE TABLE roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 역할 기본 정보
    role_name VARCHAR(100) NOT NULL,
    role_code VARCHAR(50) NOT NULL,
    description TEXT,
    
    -- 역할 분류
    is_system_role BOOLEAN NOT NULL DEFAULT false,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- 권한 정보 (JSONB 형태로 저장)
    permissions JSONB NOT NULL DEFAULT '{}',
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT roles_company_role_code_unique UNIQUE(company_id, role_code),
    CONSTRAINT chk_role_code_format 
        CHECK (role_code ~ '^[A-Z_][A-Z0-9_]*$'),
    CONSTRAINT chk_permissions_format 
        CHECK (jsonb_typeof(permissions) = 'object')
);

-- =====================================================
-- 2. User_role_links 테이블 생성
-- =====================================================

CREATE TABLE user_role_links (
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(role_id) ON DELETE CASCADE,
    
    -- 할당 정보
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID REFERENCES users(user_id),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- 추가 메타데이터
    assignment_reason TEXT,
    
    PRIMARY KEY (user_id, role_id)
);

-- =====================================================
-- 3. 인덱스 생성
-- =====================================================

-- Roles 테이블 인덱스
CREATE INDEX idx_roles_company_id ON roles(company_id);
CREATE INDEX idx_roles_role_code ON roles(role_code);
CREATE INDEX idx_roles_is_system_role ON roles(is_system_role);
CREATE INDEX idx_roles_is_active ON roles(is_active);
CREATE INDEX idx_roles_created_at ON roles(created_at DESC);

-- 권한 검색용 GIN 인덱스
CREATE INDEX idx_roles_permissions ON roles USING gin(permissions);

-- User_role_links 테이블 인덱스
CREATE INDEX idx_user_role_links_user_id ON user_role_links(user_id);
CREATE INDEX idx_user_role_links_role_id ON user_role_links(role_id);
CREATE INDEX idx_user_role_links_assigned_at ON user_role_links(assigned_at DESC);
CREATE INDEX idx_user_role_links_expires_at ON user_role_links(expires_at) 
    WHERE expires_at IS NOT NULL;

-- 활성 역할 할당 조회용 복합 인덱스
CREATE INDEX idx_user_role_links_active ON user_role_links(user_id, is_active) 
    WHERE is_active = true;

-- =====================================================
-- 4. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER roles_updated_at_trigger
    BEFORE UPDATE ON roles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. 역할 및 권한 관리 함수
-- =====================================================

-- 기본 시스템 역할 생성 함수
CREATE OR REPLACE FUNCTION create_default_roles_for_company(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    -- 총괄관리자 역할 생성
    INSERT INTO roles (company_id, role_name, role_code, description, is_system_role, permissions)
    VALUES (
        p_company_id,
        '총괄관리자',
        'SUPER_ADMIN',
        '모든 권한을 가진 최고 관리자',
        true,
        '{
            "buildings": ["create", "read", "update", "delete"],
            "users": ["create", "read", "update", "delete"],
            "roles": ["create", "read", "update", "delete"],
            "billing": ["create", "read", "update", "delete"],
            "maintenance": ["create", "read", "update", "delete"],
            "reports": ["create", "read", "update", "delete"],
            "settings": ["create", "read", "update", "delete"],
            "admin": ["*"]
        }'::jsonb
    );
    
    -- 관리소장 역할 생성
    INSERT INTO roles (company_id, role_name, role_code, description, is_system_role, permissions)
    VALUES (
        p_company_id,
        '관리소장',
        'BUILDING_MANAGER',
        '건물 관리 담당자',
        true,
        '{
            "buildings": ["read", "update"],
            "tenants": ["create", "read", "update", "delete"],
            "maintenance": ["create", "read", "update", "delete"],
            "complaints": ["create", "read", "update", "delete"],
            "facilities": ["create", "read", "update", "delete"],
            "reports": ["read"]
        }'::jsonb
    );
    
    -- 경리담당자 역할 생성
    INSERT INTO roles (company_id, role_name, role_code, description, is_system_role, permissions)
    VALUES (
        p_company_id,
        '경리담당자',
        'ACCOUNTANT',
        '회계 및 관리비 담당자',
        true,
        '{
            "billing": ["create", "read", "update", "delete"],
            "payments": ["create", "read", "update", "delete"],
            "invoices": ["create", "read", "update", "delete"],
            "accounting": ["create", "read", "update", "delete"],
            "reports": ["read"],
            "tenants": ["read"]
        }'::jsonb
    );
    
    -- 일반 직원 역할 생성
    INSERT INTO roles (company_id, role_name, role_code, description, is_system_role, permissions)
    VALUES (
        p_company_id,
        '일반직원',
        'EMPLOYEE',
        '기본 직원 권한',
        true,
        '{
            "buildings": ["read"],
            "tenants": ["read"],
            "maintenance": ["read"],
            "complaints": ["read"],
            "reports": ["read"]
        }'::jsonb
    );
END;
$$ LANGUAGE plpgsql;

-- 사용자에게 역할 할당 함수
CREATE OR REPLACE FUNCTION assign_role_to_user(
    p_user_id UUID,
    p_role_id UUID,
    p_assigned_by UUID DEFAULT NULL,
    p_expires_at TIMESTAMPTZ DEFAULT NULL,
    p_assignment_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO user_role_links (
        user_id, 
        role_id, 
        assigned_by, 
        expires_at, 
        assignment_reason
    )
    VALUES (
        p_user_id, 
        p_role_id, 
        p_assigned_by, 
        p_expires_at, 
        p_assignment_reason
    )
    ON CONFLICT (user_id, role_id) 
    DO UPDATE SET
        is_active = true,
        assigned_at = now(),
        assigned_by = p_assigned_by,
        expires_at = p_expires_at,
        assignment_reason = p_assignment_reason;
END;
$$ LANGUAGE plpgsql;

-- 사용자 역할 해제 함수
CREATE OR REPLACE FUNCTION revoke_role_from_user(p_user_id UUID, p_role_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE user_role_links 
    SET is_active = false
    WHERE user_id = p_user_id AND role_id = p_role_id;
END;
$$ LANGUAGE plpgsql;

-- 사용자 권한 확인 함수
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id UUID,
    p_resource TEXT,
    p_action TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN := false;
    role_permissions JSONB;
BEGIN
    -- 사용자의 활성 역할들의 권한을 확인
    FOR role_permissions IN
        SELECT r.permissions
        FROM user_role_links url
        JOIN roles r ON url.role_id = r.role_id
        WHERE url.user_id = p_user_id 
          AND url.is_active = true
          AND r.is_active = true
          AND (url.expires_at IS NULL OR url.expires_at > now())
    LOOP
        -- 전체 권한 확인 (admin 권한)
        IF role_permissions ? 'admin' AND role_permissions->'admin' ? '*' THEN
            RETURN true;
        END IF;
        
        -- 특정 리소스에 대한 전체 권한 확인
        IF role_permissions ? p_resource AND role_permissions->p_resource ? '*' THEN
            RETURN true;
        END IF;
        
        -- 특정 리소스의 특정 액션 권한 확인
        IF role_permissions ? p_resource AND role_permissions->p_resource ? p_action THEN
            RETURN true;
        END IF;
    END LOOP;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql;

-- 만료된 역할 할당 정리 함수
CREATE OR REPLACE FUNCTION cleanup_expired_role_assignments()
RETURNS INTEGER AS $$
DECLARE
    cleaned_count INTEGER;
BEGIN
    UPDATE user_role_links 
    SET is_active = false
    WHERE is_active = true 
      AND expires_at IS NOT NULL 
      AND expires_at <= now();
    
    GET DIAGNOSTICS cleaned_count = ROW_COUNT;
    RETURN cleaned_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 회사 생성 시 기본 역할 자동 생성 트리거
-- =====================================================

CREATE OR REPLACE FUNCTION create_default_roles_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- 새로운 회사가 생성될 때 기본 역할들을 자동으로 생성
    PERFORM create_default_roles_for_company(NEW.company_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER companies_create_default_roles_trigger
    AFTER INSERT ON companies
    FOR EACH ROW
    EXECUTE FUNCTION create_default_roles_trigger();

-- =====================================================
-- 7. Row Level Security (RLS) 설정
-- =====================================================

-- Roles 테이블 RLS 활성화
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

-- 조직별 역할 데이터 격리 정책
CREATE POLICY roles_company_isolation_policy ON roles
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY roles_admin_policy ON roles
    FOR ALL
    TO postgres
    USING (true);

-- User_role_links 테이블 RLS 활성화
ALTER TABLE user_role_links ENABLE ROW LEVEL SECURITY;

-- 사용자 역할 할당 데이터 격리 정책 (사용자의 회사를 통해 제어)
CREATE POLICY user_role_links_isolation_policy ON user_role_links
    FOR ALL
    TO application_role
    USING (
        user_id IN (
            SELECT user_id 
            FROM users 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY user_role_links_admin_policy ON user_role_links
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 8. 코멘트 추가
-- =====================================================

COMMENT ON TABLE roles IS '조직별 역할 정의 테이블';
COMMENT ON COLUMN roles.role_id IS '역할 고유 식별자 (UUID)';
COMMENT ON COLUMN roles.company_id IS '소속 회사 식별자 (NULL이면 시스템 전역 역할)';
COMMENT ON COLUMN roles.role_name IS '역할 이름 (한글)';
COMMENT ON COLUMN roles.role_code IS '역할 코드 (영문 대문자, 언더스코어)';
COMMENT ON COLUMN roles.description IS '역할 설명';
COMMENT ON COLUMN roles.is_system_role IS '시스템 기본 역할 여부';
COMMENT ON COLUMN roles.is_active IS '역할 활성화 상태';
COMMENT ON COLUMN roles.permissions IS '권한 정보 (JSONB 형태)';

COMMENT ON TABLE user_role_links IS '사용자-역할 연결 테이블';
COMMENT ON COLUMN user_role_links.user_id IS '사용자 식별자';
COMMENT ON COLUMN user_role_links.role_id IS '역할 식별자';
COMMENT ON COLUMN user_role_links.assigned_at IS '역할 할당 시간';
COMMENT ON COLUMN user_role_links.assigned_by IS '역할을 할당한 사용자';
COMMENT ON COLUMN user_role_links.expires_at IS '역할 만료 시간 (NULL이면 무기한)';
COMMENT ON COLUMN user_role_links.is_active IS '할당 활성화 상태';
COMMENT ON COLUMN user_role_links.assignment_reason IS '역할 할당 사유';