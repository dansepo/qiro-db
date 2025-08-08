-- =====================================================
-- RBAC 시스템 함수 및 프로시저
-- 작업: 18. 권한 관리 시스템 구현
-- =====================================================

-- 1. 사용자 권한 확인 함수
CREATE OR REPLACE FUNCTION bms.check_user_permission(
    p_user_id UUID,
    p_company_id UUID,
    p_permission_code VARCHAR(100)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN := false;
BEGIN
    -- 사용자의 역할을 통한 권한 확인
    SELECT EXISTS(
        SELECT 1
        FROM bms.user_roles ur
        JOIN bms.roles r ON ur.role_id = r.role_id
        JOIN bms.role_permissions rp ON r.role_id = rp.role_id
        JOIN bms.permissions p ON rp.permission_id = p.permission_id
        WHERE ur.user_id = p_user_id
        AND r.company_id = p_company_id
        AND p.permission_code = p_permission_code
        AND ur.is_active = true
        AND r.is_active = true
        AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    ) INTO v_has_permission;
    
    RETURN v_has_permission;
END;
$$ LANGUAGE plpgsql;

-- 2. 리소스별 접근 권한 확인 함수
CREATE OR REPLACE FUNCTION bms.check_resource_permission(
    p_user_id UUID,
    p_resource_type VARCHAR(50),
    p_resource_id UUID,
    p_permission_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN := false;
BEGIN
    -- 직접적인 리소스 권한 확인
    SELECT EXISTS(
        SELECT 1
        FROM bms.resource_permissions rp
        WHERE rp.user_id = p_user_id
        AND rp.resource_type = p_resource_type
        AND rp.resource_id = p_resource_id
        AND rp.permission_type = p_permission_type
        AND rp.is_active = true
        AND (rp.expires_at IS NULL OR rp.expires_at > NOW())
    ) INTO v_has_permission;
    
    RETURN v_has_permission;
END;
$$ LANGUAGE plpgsql;

-- 3. 사용자의 모든 권한 조회 함수
CREATE OR REPLACE FUNCTION bms.get_user_permissions(
    p_user_id UUID,
    p_company_id UUID
)
RETURNS TABLE (
    permission_code VARCHAR(100),
    permission_name VARCHAR(100),
    resource VARCHAR(50),
    action VARCHAR(50),
    role_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT
        p.permission_code,
        p.permission_name,
        p.resource,
        p.action,
        r.role_name
    FROM bms.user_roles ur
    JOIN bms.roles r ON ur.role_id = r.role_id
    JOIN bms.role_permissions rp ON r.role_id = rp.role_id
    JOIN bms.permissions p ON rp.permission_id = p.permission_id
    WHERE ur.user_id = p_user_id
    AND r.company_id = p_company_id
    AND ur.is_active = true
    AND r.is_active = true
    AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
    ORDER BY p.resource, p.action;
END;
$$ LANGUAGE plpgsql;

-- 4. 역할에 권한 부여 함수
CREATE OR REPLACE FUNCTION bms.grant_permission_to_role(
    p_role_id UUID,
    p_permission_code VARCHAR(100),
    p_granted_by UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_permission_id UUID;
    v_exists BOOLEAN;
BEGIN
    -- 권한 ID 조회
    SELECT permission_id INTO v_permission_id
    FROM bms.permissions
    WHERE permission_code = p_permission_code;
    
    IF v_permission_id IS NULL THEN
        RAISE EXCEPTION '권한을 찾을 수 없습니다: %', p_permission_code;
    END IF;
    
    -- 이미 부여된 권한인지 확인
    SELECT EXISTS(
        SELECT 1
        FROM bms.role_permissions
        WHERE role_id = p_role_id AND permission_id = v_permission_id
    ) INTO v_exists;
    
    IF v_exists THEN
        RETURN false; -- 이미 존재함
    END IF;
    
    -- 권한 부여
    INSERT INTO bms.role_permissions (role_id, permission_id, granted_by)
    VALUES (p_role_id, v_permission_id, p_granted_by);
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 5. 역할에서 권한 제거 함수
CREATE OR REPLACE FUNCTION bms.revoke_permission_from_role(
    p_role_id UUID,
    p_permission_code VARCHAR(100)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_permission_id UUID;
    v_deleted_count INTEGER;
BEGIN
    -- 권한 ID 조회
    SELECT permission_id INTO v_permission_id
    FROM bms.permissions
    WHERE permission_code = p_permission_code;
    
    IF v_permission_id IS NULL THEN
        RAISE EXCEPTION '권한을 찾을 수 없습니다: %', p_permission_code;
    END IF;
    
    -- 권한 제거
    DELETE FROM bms.role_permissions
    WHERE role_id = p_role_id AND permission_id = v_permission_id;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    RETURN v_deleted_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 6. 사용자에게 역할 배정 함수
CREATE OR REPLACE FUNCTION bms.assign_role_to_user(
    p_user_id UUID,
    p_role_id UUID,
    p_assigned_by UUID,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    -- 이미 배정된 역할인지 확인
    SELECT EXISTS(
        SELECT 1
        FROM bms.user_roles
        WHERE user_id = p_user_id AND role_id = p_role_id AND is_active = true
    ) INTO v_exists;
    
    IF v_exists THEN
        RETURN false; -- 이미 존재함
    END IF;
    
    -- 역할 배정
    INSERT INTO bms.user_roles (user_id, role_id, assigned_by, expires_at)
    VALUES (p_user_id, p_role_id, p_assigned_by, p_expires_at)
    ON CONFLICT (user_id, role_id) 
    DO UPDATE SET 
        is_active = true,
        assigned_at = NOW(),
        assigned_by = p_assigned_by,
        expires_at = p_expires_at;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 7. 사용자에서 역할 제거 함수
CREATE OR REPLACE FUNCTION bms.revoke_role_from_user(
    p_user_id UUID,
    p_role_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- 역할 비활성화
    UPDATE bms.user_roles
    SET is_active = false
    WHERE user_id = p_user_id AND role_id = p_role_id;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 8. 리소스 권한 부여 함수
CREATE OR REPLACE FUNCTION bms.grant_resource_permission(
    p_user_id UUID,
    p_resource_type VARCHAR(50),
    p_resource_id UUID,
    p_permission_type VARCHAR(50),
    p_granted_by UUID,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO bms.resource_permissions (
        user_id, resource_type, resource_id, permission_type, 
        granted_by, expires_at
    )
    VALUES (
        p_user_id, p_resource_type, p_resource_id, p_permission_type,
        p_granted_by, p_expires_at
    )
    ON CONFLICT (user_id, resource_type, resource_id, permission_type)
    DO UPDATE SET
        is_active = true,
        granted_at = NOW(),
        granted_by = p_granted_by,
        expires_at = p_expires_at;
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 9. 리소스 권한 제거 함수
CREATE OR REPLACE FUNCTION bms.revoke_resource_permission(
    p_user_id UUID,
    p_resource_type VARCHAR(50),
    p_resource_id UUID,
    p_permission_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    UPDATE bms.resource_permissions
    SET is_active = false
    WHERE user_id = p_user_id
    AND resource_type = p_resource_type
    AND resource_id = p_resource_id
    AND permission_type = p_permission_type;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN v_updated_count > 0;
END;
$$ LANGUAGE plpgsql;

-- 10. 권한 감사 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_permission_audit(
    p_company_id UUID,
    p_user_id UUID,
    p_action VARCHAR(50),
    p_resource_type VARCHAR(50) DEFAULT NULL,
    p_resource_id UUID DEFAULT NULL,
    p_permission_code VARCHAR(100) DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL,
    p_performed_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO bms.permission_audit_log (
        company_id, user_id, action, resource_type, resource_id,
        permission_code, ip_address, user_agent, success,
        error_message, performed_by
    )
    VALUES (
        p_company_id, p_user_id, p_action, p_resource_type, p_resource_id,
        p_permission_code, p_ip_address, p_user_agent, p_success,
        p_error_message, p_performed_by
    )
    RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- 11. 사용자의 리소스 접근 권한 목록 조회 함수
CREATE OR REPLACE FUNCTION bms.get_user_resource_permissions(
    p_user_id UUID,
    p_resource_type VARCHAR(50) DEFAULT NULL
)
RETURNS TABLE (
    resource_type VARCHAR(50),
    resource_id UUID,
    permission_type VARCHAR(50),
    granted_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rp.resource_type,
        rp.resource_id,
        rp.permission_type,
        rp.granted_at,
        rp.expires_at
    FROM bms.resource_permissions rp
    WHERE rp.user_id = p_user_id
    AND rp.is_active = true
    AND (rp.expires_at IS NULL OR rp.expires_at > NOW())
    AND (p_resource_type IS NULL OR rp.resource_type = p_resource_type)
    ORDER BY rp.resource_type, rp.permission_type;
END;
$$ LANGUAGE plpgsql;

-- 12. 역할의 권한 목록 조회 함수
CREATE OR REPLACE FUNCTION bms.get_role_permissions(
    p_role_id UUID
)
RETURNS TABLE (
    permission_code VARCHAR(100),
    permission_name VARCHAR(100),
    resource VARCHAR(50),
    action VARCHAR(50),
    granted_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.permission_code,
        p.permission_name,
        p.resource,
        p.action,
        rp.granted_at
    FROM bms.role_permissions rp
    JOIN bms.permissions p ON rp.permission_id = p.permission_id
    WHERE rp.role_id = p_role_id
    ORDER BY p.resource, p.action;
END;
$$ LANGUAGE plpgsql;

-- 13. 만료된 권한 정리 함수
CREATE OR REPLACE FUNCTION bms.cleanup_expired_permissions()
RETURNS INTEGER AS $$
DECLARE
    v_cleaned_count INTEGER := 0;
BEGIN
    -- 만료된 사용자 역할 비활성화
    UPDATE bms.user_roles
    SET is_active = false
    WHERE expires_at IS NOT NULL 
    AND expires_at <= NOW()
    AND is_active = true;
    
    GET DIAGNOSTICS v_cleaned_count = ROW_COUNT;
    
    -- 만료된 리소스 권한 비활성화
    UPDATE bms.resource_permissions
    SET is_active = false
    WHERE expires_at IS NOT NULL 
    AND expires_at <= NOW()
    AND is_active = true;
    
    DECLARE
        v_resource_count INTEGER;
    BEGIN
        GET DIAGNOSTICS v_resource_count = ROW_COUNT;
        v_cleaned_count := v_cleaned_count + v_resource_count;
    
        RETURN v_cleaned_count;
    END;
END;
$$ LANGUAGE plpgsql;

-- 14. 함수 코멘트
COMMENT ON FUNCTION bms.check_user_permission(UUID, UUID, VARCHAR(100)) IS '사용자의 특정 권한 보유 여부 확인';
COMMENT ON FUNCTION bms.check_resource_permission(UUID, VARCHAR(50), UUID, VARCHAR(50)) IS '사용자의 리소스별 접근 권한 확인';
COMMENT ON FUNCTION bms.get_user_permissions(UUID, UUID) IS '사용자의 모든 권한 목록 조회';
COMMENT ON FUNCTION bms.grant_permission_to_role(UUID, VARCHAR(100), UUID) IS '역할에 권한 부여';
COMMENT ON FUNCTION bms.revoke_permission_from_role(UUID, VARCHAR(100)) IS '역할에서 권한 제거';
COMMENT ON FUNCTION bms.assign_role_to_user(UUID, UUID, UUID, TIMESTAMP WITH TIME ZONE) IS '사용자에게 역할 배정';
COMMENT ON FUNCTION bms.revoke_role_from_user(UUID, UUID) IS '사용자에서 역할 제거';
COMMENT ON FUNCTION bms.grant_resource_permission(UUID, VARCHAR(50), UUID, VARCHAR(50), UUID, TIMESTAMP WITH TIME ZONE) IS '리소스별 권한 부여';
COMMENT ON FUNCTION bms.revoke_resource_permission(UUID, VARCHAR(50), UUID, VARCHAR(50)) IS '리소스별 권한 제거';
COMMENT ON FUNCTION bms.log_permission_audit(UUID, UUID, VARCHAR(50), VARCHAR(50), UUID, VARCHAR(100), INET, TEXT, BOOLEAN, TEXT, UUID) IS '권한 감사 로그 기록';
COMMENT ON FUNCTION bms.cleanup_expired_permissions() IS '만료된 권한 정리';