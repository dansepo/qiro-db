-- =====================================================
-- Users 테이블 멀티테넌시 마이그레이션
-- 작성일: 2025-01-30
-- 설명: 기존 Users 테이블을 멀티테넌시 구조로 변경
-- =====================================================

-- 1. 기존 Users 테이블 백업 (안전을 위해)
CREATE TABLE users_backup AS SELECT * FROM users;

-- 2. 기존 Users 테이블에 멀티테넌시 관련 컬럼 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_id UUID,
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'EMPLOYEE',
ADD COLUMN IF NOT EXISTS department VARCHAR(100),
ADD COLUMN IF NOT EXISTS position VARCHAR(100),
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

-- 3. 기존 컬럼 수정
-- email_verified 컬럼이 없으면 추가
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'email_verified'
    ) THEN
        ALTER TABLE users ADD COLUMN email_verified BOOLEAN DEFAULT false;
    END IF;
END $$;

-- is_email_verified를 email_verified로 변경 (있다면)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'is_email_verified'
    ) THEN
        UPDATE users SET email_verified = is_email_verified WHERE is_email_verified IS NOT NULL;
        ALTER TABLE users DROP COLUMN is_email_verified;
    END IF;
END $$;

-- is_active를 status로 변경하고 ENUM 타입 적용
DO $$
BEGIN
    -- status 컬럼이 없으면 추가
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'status'
    ) THEN
        ALTER TABLE users ADD COLUMN status VARCHAR(20) DEFAULT 'ACTIVE';
    END IF;
    
    -- is_active 값을 status로 마이그레이션
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'is_active'
    ) THEN
        UPDATE users SET status = CASE 
            WHEN is_active = true THEN 'ACTIVE'
            ELSE 'INACTIVE'
        END;
        ALTER TABLE users DROP COLUMN is_active;
    END IF;
END $$;

-- 4. user_type 제약조건 추가
ALTER TABLE users 
ADD CONSTRAINT chk_user_type 
CHECK (user_type IN ('SUPER_ADMIN', 'EMPLOYEE'));

-- 5. status 제약조건 추가
ALTER TABLE users 
ADD CONSTRAINT chk_user_status 
CHECK (status IN ('ACTIVE', 'INACTIVE', 'LOCKED', 'PENDING_VERIFICATION'));

-- 6. 기존 데이터 마이그레이션
DO $$
DECLARE
    default_org_id UUID;
    admin_role_id BIGINT;
BEGIN
    -- 기본 조직 ID 가져오기
    SELECT company_id INTO default_org_id 
    FROM companies 
    WHERE business_registration_number = '000-00-00000' 
    LIMIT 1;
    
    IF default_org_id IS NULL THEN
        RAISE EXCEPTION '기본 조직이 존재하지 않습니다. 먼저 companies 테이블을 설정해주세요.';
    END IF;
    
    -- 관리자 역할 ID 가져오기 (없으면 생성)
    SELECT id INTO admin_role_id FROM roles WHERE name = 'ADMIN' LIMIT 1;
    
    IF admin_role_id IS NULL THEN
        INSERT INTO roles (name, display_name, description, permissions, is_system_role)
        VALUES ('ADMIN', '관리자', '시스템 관리자', '{"*": ["*"]}'::jsonb, true)
        RETURNING id INTO admin_role_id;
    END IF;
    
    -- 기존 사용자들에게 기본 조직 할당
    UPDATE users 
    SET company_id = default_org_id,
        user_type = CASE 
            WHEN role_id = admin_role_id THEN 'SUPER_ADMIN'
            ELSE 'EMPLOYEE'
        END
    WHERE company_id IS NULL;
END $$;

-- 7. company_id를 NOT NULL로 변경
ALTER TABLE users 
ALTER COLUMN company_id SET NOT NULL;

-- 8. 외래키 제약조건 추가
ALTER TABLE users 
ADD CONSTRAINT fk_users_company_id 
FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE;

-- 9. 조직 내 이메일 유일성 제약조건 추가
-- 기존 UNIQUE 제약조건 제거 후 새로운 제약조건 추가
DO $$
BEGIN
    -- 기존 email UNIQUE 제약조건 찾아서 제거
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'users' AND constraint_type = 'UNIQUE' 
        AND constraint_name LIKE '%email%'
    ) THEN
        ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;
    END IF;
    
    -- 새로운 복합 UNIQUE 제약조건 추가
    ALTER TABLE users 
    ADD CONSTRAINT uk_users_company_email UNIQUE (company_id, email);
END $$;

-- 10. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_company_status ON users(company_id, status);
CREATE INDEX IF NOT EXISTS idx_users_company_type ON users(company_id, user_type);
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(email_verified);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON users(last_login_at);

-- 11. RLS 정책 적용
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 12. Users 테이블용 RLS 정책 생성
CREATE POLICY users_org_isolation_policy ON users
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 13. 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO application_role;

-- 14. 사용자 관리 함수들 업데이트

-- 조직별 사용자 통계 함수
CREATE OR REPLACE FUNCTION get_users_by_organization()
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    total_users BIGINT,
    active_users BIGINT,
    super_admins BIGINT,
    employees BIGINT,
    verified_users BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.company_id,
        c.company_name,
        COUNT(u.id) as total_users,
        COUNT(CASE WHEN u.status = 'ACTIVE' THEN 1 END) as active_users,
        COUNT(CASE WHEN u.user_type = 'SUPER_ADMIN' THEN 1 END) as super_admins,
        COUNT(CASE WHEN u.user_type = 'EMPLOYEE' THEN 1 END) as employees,
        COUNT(CASE WHEN u.email_verified = true THEN 1 END) as verified_users
    FROM companies c
    LEFT JOIN users u ON c.company_id = u.company_id
    GROUP BY c.company_id, c.company_name
    ORDER BY total_users DESC;
END;
$$ LANGUAGE plpgsql;

-- 사용자 생성 함수 (조직 컨텍스트 적용)
CREATE OR REPLACE FUNCTION create_user(
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255),
    p_full_name VARCHAR(255),
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_user_type VARCHAR(20) DEFAULT 'EMPLOYEE',
    p_department VARCHAR(100) DEFAULT NULL,
    p_position VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
    v_company_id UUID;
BEGIN
    -- 현재 조직 컨텍스트 가져오기
    v_company_id := current_setting('app.current_company_id', true)::UUID;
    
    IF v_company_id IS NULL THEN
        RAISE EXCEPTION '조직 컨텍스트가 설정되지 않았습니다.';
    END IF;
    
    -- 이메일 중복 검사 (조직 내)
    IF EXISTS (SELECT 1 FROM users WHERE company_id = v_company_id AND email = p_email) THEN
        RAISE EXCEPTION '해당 조직에 이미 존재하는 이메일입니다: %', p_email;
    END IF;
    
    -- 사용자 생성
    INSERT INTO users (
        company_id,
        email,
        password_hash,
        full_name,
        phone_number,
        user_type,
        department,
        position,
        status,
        created_at,
        updated_at
    ) VALUES (
        v_company_id,
        p_email,
        p_password_hash,
        p_full_name,
        p_phone_number,
        p_user_type,
        p_department,
        p_position,
        'PENDING_VERIFICATION',
        now(),
        now()
    ) RETURNING id INTO v_user_id;
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 15. 데이터 무결성 검증 함수
CREATE OR REPLACE FUNCTION verify_users_migration()
RETURNS TABLE (
    total_users BIGINT,
    users_with_company BIGINT,
    users_without_company BIGINT,
    unique_organizations BIGINT,
    super_admins BIGINT,
    employees BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END) as users_with_company,
        COUNT(CASE WHEN company_id IS NULL THEN 1 END) as users_without_company,
        COUNT(DISTINCT company_id) as unique_organizations,
        COUNT(CASE WHEN user_type = 'SUPER_ADMIN' THEN 1 END) as super_admins,
        COUNT(CASE WHEN user_type = 'EMPLOYEE' THEN 1 END) as employees
    FROM users;
END;
$$ LANGUAGE plpgsql;

-- 16. 마이그레이션 검증 실행
SELECT * FROM verify_users_migration();

-- 17. 트리거 업데이트 (updated_at 자동 업데이트)
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 18. 마이그레이션 로그 기록
INSERT INTO migration_log (
    migration_name,
    description,
    executed_at,
    status
) VALUES (
    'users_multitenancy_migration',
    'Users 테이블 멀티테넌시 구조 변경 및 RLS 정책 적용',
    now(),
    'COMPLETED'
) ON CONFLICT (migration_name) DO UPDATE SET
    executed_at = now(),
    status = 'COMPLETED';

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== Users 테이블 멀티테넌시 마이그레이션 완료 ===';
    RAISE NOTICE '1. 멀티테넌시 컬럼 추가 완료';
    RAISE NOTICE '2. 기존 데이터 마이그레이션 완료';
    RAISE NOTICE '3. 제약조건 및 인덱스 생성 완료';
    RAISE NOTICE '4. RLS 정책 적용 완료';
    RAISE NOTICE '5. 사용자 관리 함수 업데이트 완료';
    RAISE NOTICE '6. 데이터 무결성 검증 함수 생성 완료';
    RAISE NOTICE '=== 백업 테이블: users_backup ===';
END $$;