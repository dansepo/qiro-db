-- =====================================================
-- QIRO 조직 관리 자동화 및 비즈니스 로직 구현
-- 사용자 생성 및 역할 할당 자동화 함수
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 사용자 생성 및 역할 할당 통합 함수
-- =====================================================

CREATE OR REPLACE FUNCTION create_user_with_role(
    p_company_id UUID,
    p_email VARCHAR(255),
    p_full_name VARCHAR(100),
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_department VARCHAR(100) DEFAULT NULL,
    p_position VARCHAR(100) DEFAULT NULL,
    p_user_type user_type DEFAULT 'EMPLOYEE',
    p_role_codes TEXT[] DEFAULT ARRAY['EMPLOYEE'],
    p_temporary_password TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    new_user_id UUID;
    role_record RECORD;
    temp_password TEXT;
    role_code TEXT;
BEGIN
    -- 입력 검증
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION '회사 ID는 필수입니다.';
    END IF;
    
    IF p_email IS NULL OR LENGTH(TRIM(p_email)) = 0 THEN
        RAISE EXCEPTION '이메일은 필수입니다.';
    END IF;
    
    IF p_full_name IS NULL OR LENGTH(TRIM(p_full_name)) = 0 THEN
        RAISE EXCEPTION '사용자 이름은 필수입니다.';
    END IF;
    
    -- 회사 존재 여부 확인
    IF NOT EXISTS (SELECT 1 FROM companies WHERE company_id = p_company_id) THEN
        RAISE EXCEPTION '존재하지 않는 회사입니다: %', p_company_id;
    END IF;
    
    -- 이메일 중복 검증 (조직 내)
    IF EXISTS (
        SELECT 1 FROM users 
        WHERE company_id = p_company_id AND email = LOWER(TRIM(p_email))
    ) THEN
        RAISE EXCEPTION '해당 조직에 이미 존재하는 이메일입니다: %', p_email;
    END IF;
    
    -- 임시 비밀번호 생성 (제공되지 않은 경우)
    IF p_temporary_password IS NULL THEN
        temp_password := 'Temp' || EXTRACT(EPOCH FROM now())::BIGINT || '!';
    ELSE
        temp_password := p_temporary_password;
    END IF;
    
    -- 사용자 생성
    INSERT INTO users (
        company_id,
        email,
        password_hash,
        full_name,
        phone_number,
        department,
        position,
        user_type,
        status,
        must_change_password,
        created_by,
        updated_by
    )
    VALUES (
        p_company_id,
        LOWER(TRIM(p_email)),
        hash_password(temp_password),
        TRIM(p_full_name),
        CASE WHEN p_phone_number IS NOT NULL THEN TRIM(p_phone_number) END,
        CASE WHEN p_department IS NOT NULL THEN TRIM(p_department) END,
        CASE WHEN p_position IS NOT NULL THEN TRIM(p_position) END,
        p_user_type,
        'PENDING_VERIFICATION',
        true,
        p_created_by,
        p_created_by
    )
    RETURNING user_id INTO new_user_id;
    
    -- 역할 할당
    FOREACH role_code IN ARRAY p_role_codes
    LOOP
        -- 역할 존재 여부 확인
        SELECT role_id, role_name INTO role_record
        FROM roles 
        WHERE company_id = p_company_id 
          AND role_code = role_code 
          AND is_active = true;
        
        IF NOT FOUND THEN
            RAISE WARNING '역할을 찾을 수 없습니다: % (회사: %)', role_code, p_company_id;
            CONTINUE;
        END IF;
        
        -- 역할 할당
        PERFORM assign_role_to_user(
            new_user_id,
            role_record.role_id,
            p_created_by,
            NULL,
            '사용자 생성 시 기본 역할 할당'
        );
        
        RAISE NOTICE '사용자 %에게 역할 % 할당 완료', new_user_id, role_record.role_name;
    END LOOP;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'users',
        'USER_CREATED_WITH_ROLES',
        new_user_id::TEXT,
        NULL,
        jsonb_build_object(
            'user_id', new_user_id,
            'company_id', p_company_id,
            'email', p_email,
            'full_name', p_full_name,
            'user_type', p_user_type,
            'assigned_roles', p_role_codes,
            'temporary_password_set', true
        ),
        p_created_by,
        now()
    );
    
    RAISE NOTICE '사용자 생성 완료: % (ID: %)', p_full_name, new_user_id;
    RETURN new_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '사용자 생성 중 오류 발생: %', SQLERRM;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 사용자 역할 변경 함수
-- =====================================================

CREATE OR REPLACE FUNCTION change_user_roles(
    p_user_id UUID,
    p_new_role_codes TEXT[],
    p_changed_by UUID DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $
DECLARE
    user_company_id UUID;
    role_record RECORD;
    role_code TEXT;
    old_roles JSONB;
BEGIN
    -- 사용자 존재 여부 및 회사 ID 확인
    SELECT company_id INTO user_company_id
    FROM users
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 사용자입니다: %', p_user_id;
    END IF;
    
    -- 기존 역할 정보 백업
    SELECT jsonb_agg(
        jsonb_build_object(
            'role_id', r.role_id,
            'role_code', r.role_code,
            'role_name', r.role_name
        )
    ) INTO old_roles
    FROM user_role_links url
    JOIN roles r ON url.role_id = r.role_id
    WHERE url.user_id = p_user_id AND url.is_active = true;
    
    -- 기존 역할 모두 비활성화
    UPDATE user_role_links 
    SET 
        is_active = false,
        updated_at = now()
    WHERE user_id = p_user_id AND is_active = true;
    
    -- 새로운 역할들 할당
    FOREACH role_code IN ARRAY p_new_role_codes
    LOOP
        -- 역할 존재 여부 확인
        SELECT role_id, role_name INTO role_record
        FROM roles 
        WHERE company_id = user_company_id 
          AND role_code = role_code 
          AND is_active = true;
        
        IF NOT FOUND THEN
            RAISE WARNING '역할을 찾을 수 없습니다: % (회사: %)', role_code, user_company_id;
            CONTINUE;
        END IF;
        
        -- 역할 할당
        PERFORM assign_role_to_user(
            p_user_id,
            role_record.role_id,
            p_changed_by,
            NULL,
            COALESCE(p_reason, '역할 변경')
        );
    END LOOP;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'user_role_links',
        'ROLES_CHANGED',
        p_user_id::TEXT,
        jsonb_build_object('old_roles', old_roles),
        jsonb_build_object(
            'new_role_codes', p_new_role_codes,
            'reason', p_reason
        ),
        p_changed_by,
        now()
    );
    
    RAISE NOTICE '사용자 %의 역할 변경 완료', p_user_id;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 초기 비밀번호 설정 및 변경 강제 함수
-- =====================================================

CREATE OR REPLACE FUNCTION set_initial_password(
    p_user_id UUID,
    p_new_password TEXT,
    p_force_change BOOLEAN DEFAULT true
)
RETURNS VOID AS $
DECLARE
    user_email VARCHAR(255);
BEGIN
    -- 사용자 존재 여부 확인
    SELECT email INTO user_email
    FROM users
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 사용자입니다: %', p_user_id;
    END IF;
    
    -- 비밀번호 유효성 검증
    IF p_new_password IS NULL OR LENGTH(p_new_password) < 8 THEN
        RAISE EXCEPTION '비밀번호는 최소 8자 이상이어야 합니다.';
    END IF;
    
    -- 비밀번호 업데이트
    UPDATE users 
    SET 
        password_hash = hash_password(p_new_password),
        password_changed_at = now(),
        must_change_password = p_force_change,
        failed_login_attempts = 0,
        locked_until = NULL,
        status = CASE 
            WHEN status = 'LOCKED' THEN 'PENDING_VERIFICATION'
            ELSE status
        END,
        updated_at = now()
    WHERE user_id = p_user_id;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'users',
        'PASSWORD_RESET',
        p_user_id::TEXT,
        NULL,
        jsonb_build_object(
            'email', user_email,
            'force_change', p_force_change,
            'reset_at', now()
        ),
        p_user_id,
        now()
    );
    
    RAISE NOTICE '사용자 %의 비밀번호가 재설정되었습니다.', user_email;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 사용자 활성화/비활성화 함수
-- =====================================================

CREATE OR REPLACE FUNCTION activate_user(
    p_user_id UUID,
    p_activated_by UUID DEFAULT NULL
)
RETURNS VOID AS $
DECLARE
    user_info RECORD;
BEGIN
    -- 사용자 정보 조회
    SELECT email, full_name, status INTO user_info
    FROM users
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 사용자입니다: %', p_user_id;
    END IF;
    
    -- 사용자 활성화
    UPDATE users 
    SET 
        status = 'ACTIVE',
        failed_login_attempts = 0,
        locked_until = NULL,
        updated_at = now(),
        updated_by = p_activated_by
    WHERE user_id = p_user_id;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'users',
        'USER_ACTIVATED',
        p_user_id::TEXT,
        jsonb_build_object('old_status', user_info.status),
        jsonb_build_object(
            'new_status', 'ACTIVE',
            'email', user_info.email,
            'full_name', user_info.full_name
        ),
        p_activated_by,
        now()
    );
    
    RAISE NOTICE '사용자 활성화 완료: % (%)', user_info.full_name, user_info.email;
END;
$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION deactivate_user(
    p_user_id UUID,
    p_deactivated_by UUID DEFAULT NULL,
    p_reason TEXT DEFAULT NULL
)
RETURNS VOID AS $
DECLARE
    user_info RECORD;
BEGIN
    -- 사용자 정보 조회
    SELECT email, full_name, status INTO user_info
    FROM users
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 사용자입니다: %', p_user_id;
    END IF;
    
    -- 사용자 비활성화
    UPDATE users 
    SET 
        status = 'INACTIVE',
        updated_at = now(),
        updated_by = p_deactivated_by
    WHERE user_id = p_user_id;
    
    -- 모든 역할 할당 비활성화
    UPDATE user_role_links 
    SET 
        is_active = false,
        updated_at = now()
    WHERE user_id = p_user_id AND is_active = true;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'users',
        'USER_DEACTIVATED',
        p_user_id::TEXT,
        jsonb_build_object('old_status', user_info.status),
        jsonb_build_object(
            'new_status', 'INACTIVE',
            'email', user_info.email,
            'full_name', user_info.full_name,
            'reason', p_reason
        ),
        p_deactivated_by,
        now()
    );
    
    RAISE NOTICE '사용자 비활성화 완료: % (%) - 사유: %', 
        user_info.full_name, user_info.email, COALESCE(p_reason, '미지정');
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 이메일 중복 검증 함수 (조직 내)
-- =====================================================

CREATE OR REPLACE FUNCTION validate_email_uniqueness_in_company(
    p_company_id UUID,
    p_email VARCHAR(255),
    p_exclude_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $
DECLARE
    normalized_email VARCHAR(255);
BEGIN
    -- 이메일 정규화
    normalized_email := LOWER(TRIM(p_email));
    
    -- 중복 검사 (특정 사용자 제외 가능)
    IF EXISTS (
        SELECT 1 FROM users 
        WHERE company_id = p_company_id 
          AND email = normalized_email
          AND (p_exclude_user_id IS NULL OR user_id != p_exclude_user_id)
    ) THEN
        RETURN false;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 사용자 정보 조회 함수들
-- =====================================================

-- 사용자의 현재 역할 조회
CREATE OR REPLACE FUNCTION get_user_current_roles(p_user_id UUID)
RETURNS TABLE(
    role_id UUID,
    role_name VARCHAR(100),
    role_code VARCHAR(50),
    permissions JSONB,
    assigned_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        r.role_id,
        r.role_name,
        r.role_code,
        r.permissions,
        url.assigned_at,
        url.expires_at
    FROM user_role_links url
    JOIN roles r ON url.role_id = r.role_id
    WHERE url.user_id = p_user_id 
      AND url.is_active = true
      AND r.is_active = true
      AND (url.expires_at IS NULL OR url.expires_at > now())
    ORDER BY url.assigned_at DESC;
END;
$ LANGUAGE plpgsql;

-- 회사의 사용자 목록 조회 (역할 정보 포함)
CREATE OR REPLACE FUNCTION get_company_users_with_roles(p_company_id UUID)
RETURNS TABLE(
    user_id UUID,
    email VARCHAR(255),
    full_name VARCHAR(100),
    department VARCHAR(100),
    position VARCHAR(100),
    user_type user_type,
    status user_status,
    roles JSONB,
    created_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        u.user_id,
        u.email,
        u.full_name,
        u.department,
        u.position,
        u.user_type,
        u.status,
        COALESCE(
            jsonb_agg(
                CASE WHEN r.role_id IS NOT NULL THEN
                    jsonb_build_object(
                        'role_id', r.role_id,
                        'role_name', r.role_name,
                        'role_code', r.role_code,
                        'assigned_at', url.assigned_at
                    )
                END
            ) FILTER (WHERE r.role_id IS NOT NULL),
            '[]'::jsonb
        ) as roles,
        u.created_at,
        u.last_login_at
    FROM users u
    LEFT JOIN user_role_links url ON u.user_id = url.user_id AND url.is_active = true
    LEFT JOIN roles r ON url.role_id = r.role_id AND r.is_active = true
    WHERE u.company_id = p_company_id
    GROUP BY u.user_id, u.email, u.full_name, u.department, u.position, 
             u.user_type, u.status, u.created_at, u.last_login_at
    ORDER BY u.created_at DESC;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON FUNCTION create_user_with_role(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, user_type, TEXT[], TEXT, UUID) IS '사용자 생성과 동시에 역할을 할당하는 통합 함수';
COMMENT ON FUNCTION change_user_roles(UUID, TEXT[], UUID, TEXT) IS '사용자의 역할을 변경하는 함수 (기존 역할 해제 후 새 역할 할당)';
COMMENT ON FUNCTION set_initial_password(UUID, TEXT, BOOLEAN) IS '사용자의 초기 비밀번호를 설정하고 변경을 강제하는 함수';
COMMENT ON FUNCTION activate_user(UUID, UUID) IS '사용자 계정을 활성화하는 함수';
COMMENT ON FUNCTION deactivate_user(UUID, UUID, TEXT) IS '사용자 계정을 비활성화하고 모든 역할을 해제하는 함수';
COMMENT ON FUNCTION validate_email_uniqueness_in_company(UUID, VARCHAR, UUID) IS '조직 내 이메일 중복을 검증하는 함수';
COMMENT ON FUNCTION get_user_current_roles(UUID) IS '사용자의 현재 활성 역할 목록을 조회하는 함수';
COMMENT ON FUNCTION get_company_users_with_roles(UUID) IS '회사의 모든 사용자와 그들의 역할 정보를 조회하는 함수';