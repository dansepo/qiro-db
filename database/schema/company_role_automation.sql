-- =====================================================
-- QIRO 조직 관리 자동화 및 비즈니스 로직 구현
-- 회사 생성 시 기본 역할 자동 생성 트리거 개선
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 기본 역할 생성 함수 개선
-- =====================================================

-- 기존 함수 대체
DROP FUNCTION IF EXISTS create_default_roles_for_company(UUID);

CREATE OR REPLACE FUNCTION create_default_roles_for_company(p_company_id UUID)
RETURNS VOID AS $
DECLARE
    super_admin_role_id UUID;
    building_manager_role_id UUID;
    accountant_role_id UUID;
    employee_role_id UUID;
BEGIN
    -- 예외 처리: 회사 ID 유효성 검증
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION '회사 ID가 NULL일 수 없습니다.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM companies WHERE company_id = p_company_id) THEN
        RAISE EXCEPTION '존재하지 않는 회사 ID입니다: %', p_company_id;
    END IF;
    
    -- 이미 역할이 생성되어 있는지 확인
    IF EXISTS (SELECT 1 FROM roles WHERE company_id = p_company_id AND is_system_role = true) THEN
        RAISE NOTICE '회사 %에 대한 기본 역할이 이미 존재합니다.', p_company_id;
        RETURN;
    END IF;
    
    -- 1. 총괄관리자 역할 생성
    INSERT INTO roles (
        company_id, 
        role_name, 
        role_code, 
        description, 
        is_system_role, 
        permissions
    )
    VALUES (
        p_company_id,
        '총괄관리자',
        'SUPER_ADMIN',
        '모든 권한을 가진 최고 관리자 - 시스템 전체 관리, 사용자 관리, 권한 설정',
        true,
        '{
            "system": {
                "admin": ["*"],
                "settings": ["create", "read", "update", "delete"],
                "backup": ["create", "read"],
                "audit": ["read"]
            },
            "users": {
                "management": ["create", "read", "update", "delete"],
                "roles": ["create", "read", "update", "delete", "assign"],
                "permissions": ["create", "read", "update", "delete"]
            },
            "buildings": {
                "management": ["create", "read", "update", "delete"],
                "groups": ["create", "read", "update", "delete"],
                "assignments": ["create", "read", "update", "delete"]
            },
            "billing": {
                "items": ["create", "read", "update", "delete"],
                "invoices": ["create", "read", "update", "delete"],
                "payments": ["create", "read", "update", "delete"],
                "reports": ["create", "read", "update", "delete"]
            },
            "maintenance": {
                "requests": ["create", "read", "update", "delete"],
                "schedules": ["create", "read", "update", "delete"],
                "vendors": ["create", "read", "update", "delete"]
            },
            "reports": {
                "financial": ["create", "read", "update", "delete"],
                "operational": ["create", "read", "update", "delete"],
                "analytics": ["create", "read", "update", "delete"]
            }
        }'::jsonb
    )
    RETURNING role_id INTO super_admin_role_id;
    
    -- 2. 관리소장 역할 생성
    INSERT INTO roles (
        company_id, 
        role_name, 
        role_code, 
        description, 
        is_system_role, 
        permissions
    )
    VALUES (
        p_company_id,
        '관리소장',
        'BUILDING_MANAGER',
        '건물 관리 담당자 - 건물 운영, 임차인 관리, 시설 유지보수',
        true,
        '{
            "buildings": {
                "management": ["read", "update"],
                "units": ["read", "update"],
                "common_areas": ["read", "update"]
            },
            "tenants": {
                "management": ["create", "read", "update", "delete"],
                "contracts": ["create", "read", "update", "delete"],
                "communications": ["create", "read", "update", "delete"]
            },
            "maintenance": {
                "requests": ["create", "read", "update", "delete"],
                "schedules": ["create", "read", "update", "delete"],
                "inspections": ["create", "read", "update", "delete"],
                "vendors": ["read", "update"]
            },
            "complaints": {
                "management": ["create", "read", "update", "delete"],
                "responses": ["create", "read", "update", "delete"]
            },
            "facilities": {
                "management": ["create", "read", "update", "delete"],
                "monitoring": ["read", "update"]
            },
            "reports": {
                "operational": ["read"],
                "maintenance": ["create", "read", "update"]
            }
        }'::jsonb
    )
    RETURNING role_id INTO building_manager_role_id;
    
    -- 3. 경리담당자 역할 생성
    INSERT INTO roles (
        company_id, 
        role_name, 
        role_code, 
        description, 
        is_system_role, 
        permissions
    )
    VALUES (
        p_company_id,
        '경리담당자',
        'ACCOUNTANT',
        '회계 및 관리비 담당자 - 관리비 계산, 청구서 발행, 수납 관리',
        true,
        '{
            "billing": {
                "items": ["create", "read", "update", "delete"],
                "calculations": ["create", "read", "update", "delete"],
                "invoices": ["create", "read", "update", "delete"],
                "adjustments": ["create", "read", "update", "delete"]
            },
            "payments": {
                "processing": ["create", "read", "update", "delete"],
                "reconciliation": ["create", "read", "update", "delete"],
                "overdue": ["read", "update"],
                "refunds": ["create", "read", "update"]
            },
            "accounting": {
                "entries": ["create", "read", "update", "delete"],
                "accounts": ["read", "update"],
                "reconciliation": ["create", "read", "update"],
                "closing": ["create", "read", "update"]
            },
            "reports": {
                "financial": ["create", "read", "update"],
                "billing": ["create", "read", "update"],
                "collections": ["create", "read", "update"]
            },
            "tenants": {
                "billing_info": ["read", "update"],
                "payment_history": ["read"]
            }
        }'::jsonb
    )
    RETURNING role_id INTO accountant_role_id;
    
    -- 4. 일반직원 역할 생성
    INSERT INTO roles (
        company_id, 
        role_name, 
        role_code, 
        description, 
        is_system_role, 
        permissions
    )
    VALUES (
        p_company_id,
        '일반직원',
        'EMPLOYEE',
        '기본 직원 권한 - 조회 중심의 제한된 권한',
        true,
        '{
            "buildings": {
                "management": ["read"],
                "units": ["read"]
            },
            "tenants": {
                "management": ["read"],
                "communications": ["read"]
            },
            "maintenance": {
                "requests": ["read"],
                "schedules": ["read"]
            },
            "complaints": {
                "management": ["read"]
            },
            "reports": {
                "operational": ["read"]
            }
        }'::jsonb
    )
    RETURNING role_id INTO employee_role_id;
    
    -- 로그 기록
    RAISE NOTICE '회사 %에 대한 기본 역할 생성 완료: SUPER_ADMIN(%), BUILDING_MANAGER(%), ACCOUNTANT(%), EMPLOYEE(%)', 
        p_company_id, super_admin_role_id, building_manager_role_id, accountant_role_id, employee_role_id;
        
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '회사 %에 대한 기본 역할 생성 중 오류 발생: %', p_company_id, SQLERRM;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 회사 생성 시 기본 역할 자동 생성 트리거 개선
-- =====================================================

-- 기존 트리거 함수 대체
DROP FUNCTION IF EXISTS create_default_roles_trigger();

CREATE OR REPLACE FUNCTION create_default_roles_trigger()
RETURNS TRIGGER AS $
BEGIN
    -- 트랜잭션 내에서 안전하게 기본 역할 생성
    BEGIN
        PERFORM create_default_roles_for_company(NEW.company_id);
        
        -- 성공 로그
        INSERT INTO audit_logs (
            table_name,
            operation,
            record_id,
            old_values,
            new_values,
            user_id,
            timestamp
        ) VALUES (
            'companies',
            'ROLES_CREATED',
            NEW.company_id::TEXT,
            NULL,
            jsonb_build_object(
                'company_id', NEW.company_id,
                'company_name', NEW.company_name,
                'action', 'default_roles_created'
            ),
            NEW.created_by,
            now()
        );
        
    EXCEPTION
        WHEN OTHERS THEN
            -- 오류 로그 기록
            INSERT INTO audit_logs (
                table_name,
                operation,
                record_id,
                old_values,
                new_values,
                user_id,
                timestamp
            ) VALUES (
                'companies',
                'ROLES_CREATION_FAILED',
                NEW.company_id::TEXT,
                NULL,
                jsonb_build_object(
                    'company_id', NEW.company_id,
                    'company_name', NEW.company_name,
                    'error', SQLERRM
                ),
                NEW.created_by,
                now()
            );
            
            -- 오류를 다시 발생시켜 트랜잭션 롤백
            RAISE;
    END;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 기존 트리거 삭제 후 재생성
DROP TRIGGER IF EXISTS companies_create_default_roles_trigger ON companies;

CREATE TRIGGER companies_create_default_roles_trigger
    AFTER INSERT ON companies
    FOR EACH ROW
    EXECUTE FUNCTION create_default_roles_trigger();

-- =====================================================
-- 3. 역할 관리 유틸리티 함수들
-- =====================================================

-- 회사의 기본 역할 재생성 함수 (관리용)
CREATE OR REPLACE FUNCTION recreate_default_roles_for_company(p_company_id UUID)
RETURNS VOID AS $
BEGIN
    -- 기존 시스템 역할 삭제 (CASCADE로 user_role_links도 함께 삭제됨)
    DELETE FROM roles 
    WHERE company_id = p_company_id AND is_system_role = true;
    
    -- 새로운 기본 역할 생성
    PERFORM create_default_roles_for_company(p_company_id);
    
    RAISE NOTICE '회사 %의 기본 역할이 재생성되었습니다.', p_company_id;
END;
$ LANGUAGE plpgsql;

-- 특정 역할의 권한 업데이트 함수
CREATE OR REPLACE FUNCTION update_role_permissions(
    p_role_id UUID,
    p_new_permissions JSONB
)
RETURNS VOID AS $
DECLARE
    old_permissions JSONB;
BEGIN
    -- 기존 권한 백업
    SELECT permissions INTO old_permissions
    FROM roles
    WHERE role_id = p_role_id;
    
    -- 권한 업데이트
    UPDATE roles 
    SET 
        permissions = p_new_permissions,
        updated_at = now()
    WHERE role_id = p_role_id;
    
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
        'roles',
        'PERMISSIONS_UPDATED',
        p_role_id::TEXT,
        jsonb_build_object('permissions', old_permissions),
        jsonb_build_object('permissions', p_new_permissions),
        current_setting('app.current_user_id', true)::UUID,
        now()
    );
END;
$ LANGUAGE plpgsql;

-- 역할별 사용자 수 조회 함수
CREATE OR REPLACE FUNCTION get_role_user_count(p_company_id UUID)
RETURNS TABLE(
    role_id UUID,
    role_name VARCHAR(100),
    role_code VARCHAR(50),
    user_count BIGINT,
    active_user_count BIGINT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        r.role_id,
        r.role_name,
        r.role_code,
        COUNT(url.user_id) as user_count,
        COUNT(CASE WHEN url.is_active = true THEN 1 END) as active_user_count
    FROM roles r
    LEFT JOIN user_role_links url ON r.role_id = url.role_id
    WHERE r.company_id = p_company_id
    GROUP BY r.role_id, r.role_name, r.role_code
    ORDER BY r.role_name;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 역할 검증 함수들
-- =====================================================

-- 회사의 필수 역할 존재 여부 확인
CREATE OR REPLACE FUNCTION validate_company_essential_roles(p_company_id UUID)
RETURNS BOOLEAN AS $
DECLARE
    essential_roles TEXT[] := ARRAY['SUPER_ADMIN', 'BUILDING_MANAGER', 'ACCOUNTANT', 'EMPLOYEE'];
    role_code TEXT;
    missing_roles TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- 필수 역할들이 모두 존재하는지 확인
    FOREACH role_code IN ARRAY essential_roles
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM roles 
            WHERE company_id = p_company_id 
              AND role_code = role_code 
              AND is_system_role = true
              AND is_active = true
        ) THEN
            missing_roles := array_append(missing_roles, role_code);
        END IF;
    END LOOP;
    
    -- 누락된 역할이 있으면 로그 기록 후 false 반환
    IF array_length(missing_roles, 1) > 0 THEN
        RAISE WARNING '회사 %에 누락된 필수 역할: %', p_company_id, array_to_string(missing_roles, ', ');
        RETURN false;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 역할 권한 구조 검증 함수
CREATE OR REPLACE FUNCTION validate_role_permissions(p_permissions JSONB)
RETURNS BOOLEAN AS $
DECLARE
    required_structure TEXT[] := ARRAY['system', 'users', 'buildings', 'billing', 'maintenance', 'reports'];
    key TEXT;
BEGIN
    -- 기본 구조 검증
    IF jsonb_typeof(p_permissions) != 'object' THEN
        RETURN false;
    END IF;
    
    -- 각 키의 값이 객체인지 확인
    FOR key IN SELECT jsonb_object_keys(p_permissions)
    LOOP
        IF jsonb_typeof(p_permissions->key) NOT IN ('object', 'array') THEN
            RETURN false;
        END IF;
    END LOOP;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 코멘트 추가
-- =====================================================

COMMENT ON FUNCTION create_default_roles_for_company(UUID) IS '회사 생성 시 기본 역할(총괄관리자, 관리소장, 경리담당자, 일반직원)을 자동으로 생성하는 함수';
COMMENT ON FUNCTION create_default_roles_trigger() IS '회사 테이블에 새 레코드 삽입 시 기본 역할을 자동 생성하는 트리거 함수';
COMMENT ON FUNCTION recreate_default_roles_for_company(UUID) IS '회사의 기본 역할을 삭제 후 재생성하는 관리용 함수';
COMMENT ON FUNCTION update_role_permissions(UUID, JSONB) IS '특정 역할의 권한을 업데이트하고 감사 로그를 기록하는 함수';
COMMENT ON FUNCTION get_role_user_count(UUID) IS '회사의 각 역할별 사용자 수를 조회하는 함수';
COMMENT ON FUNCTION validate_company_essential_roles(UUID) IS '회사의 필수 역할 존재 여부를 검증하는 함수';
COMMENT ON FUNCTION validate_role_permissions(JSONB) IS '역할 권한 구조의 유효성을 검증하는 함수';