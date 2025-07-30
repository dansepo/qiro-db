-- =====================================================
-- 사용자 권한 및 감사 로그 테이블 설계 (User Management & Audit)
-- =====================================================

-- 사용자 역할 테이블 (Roles)
CREATE TABLE roles (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 사용자 정보 테이블 (Users)
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    role_id BIGINT NOT NULL REFERENCES roles(id),
    organization_id BIGINT, -- 조직/회사 ID (추후 확장용)
    is_active BOOLEAN DEFAULT true,
    is_email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 사용자-건물 접근 권한 테이블 (User Building Access)
CREATE TABLE user_building_access (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    access_level VARCHAR(20) NOT NULL DEFAULT 'READ' CHECK (access_level IN ('read', 'write', 'admin')),
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, building_id)
);

-- 권한 매트릭스 테이블 (Permission Matrix)
CREATE TABLE permission_matrix (
    id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    resource VARCHAR(100) NOT NULL, -- 리소스명 (예: buildings, tenants, invoices)
    action VARCHAR(50) NOT NULL,    -- 액션명 (예: create, read, update, delete)
    is_allowed BOOLEAN DEFAULT false,
    conditions JSONB, -- 조건부 권한 (예: 자신이 생성한 데이터만)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(role_id, resource, action)
);

-- 사용자 세션 테이블 (User Sessions)
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 감사 로그 테이블 (Audit Logs)
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),
    old_values JSONB,
    new_values JSONB,
    changed_fields TEXT[], -- 변경된 필드 목록
    user_id BIGINT REFERENCES users(id),
    session_id BIGINT REFERENCES user_sessions(id),
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100), -- 요청 추적용 ID
    building_id BIGINT REFERENCES buildings(id), -- 건물별 로그 분리용
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 로그인 이력 테이블 (Login History)
CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    username VARCHAR(50) NOT NULL, -- 사용자 삭제 시에도 기록 유지
    login_type VARCHAR(20) NOT NULL CHECK (login_type IN ('SUCCESS', 'FAILED', 'LOCKED', 'LOGOUT')),
    ip_address INET,
    user_agent TEXT,
    failure_reason VARCHAR(100), -- 실패 사유
    session_id BIGINT REFERENCES user_sessions(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 비밀번호 재설정 토큰 테이블 (Password Reset Tokens)
CREATE TABLE password_reset_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_used BOOLEAN DEFAULT false,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_user_building_access_user_id ON user_building_access(user_id);
CREATE INDEX idx_user_building_access_building_id ON user_building_access(building_id);
CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_building_id ON audit_logs(building_id);
CREATE INDEX idx_login_history_user_id ON login_history(user_id);
CREATE INDEX idx_login_history_created_at ON login_history(created_at);
CREATE INDEX idx_permission_matrix_role_resource ON permission_matrix(role_id, resource);

-- =====================================================
-- 감사 로그 자동 생성 트리거 함수
-- =====================================================

-- 감사 로그 생성 함수
CREATE OR REPLACE FUNCTION create_audit_log()
RETURNS TRIGGER AS $$
DECLARE
    audit_user_id BIGINT;
    audit_session_id BIGINT;
    audit_building_id BIGINT;
    changed_fields TEXT[] := '{}';
    field_name TEXT;
BEGIN
    -- 현재 사용자 정보 가져오기 (애플리케이션에서 설정)
    audit_user_id := NULLIF(current_setting('app.current_user_id', true), '')::BIGINT;
    audit_session_id := NULLIF(current_setting('app.current_session_id', true), '')::BIGINT;
    audit_building_id := NULLIF(current_setting('app.current_building_id', true), '')::BIGINT;
    
    -- UPDATE 작업의 경우 변경된 필드 목록 생성
    IF TG_OP = 'UPDATE' THEN
        FOR field_name IN 
            SELECT jsonb_object_keys(to_jsonb(NEW) - to_jsonb(OLD))
        LOOP
            changed_fields := array_append(changed_fields, field_name);
        END LOOP;
    END IF;
    
    -- 감사 로그 삽입
    INSERT INTO audit_logs (
        table_name,
        record_id,
        action,
        old_values,
        new_values,
        changed_fields,
        user_id,
        session_id,
        building_id,
        ip_address,
        user_agent,
        request_id
    ) VALUES (
        TG_TABLE_NAME,
        CASE 
            WHEN TG_OP = 'DELETE' THEN (OLD.id)::BIGINT
            ELSE (NEW.id)::BIGINT
        END,
        TG_OP,
        CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END,
        CASE WHEN TG_OP = 'UPDATE' THEN changed_fields ELSE NULL END,
        audit_user_id,
        audit_session_id,
        audit_building_id,
        NULLIF(current_setting('app.client_ip', true), '')::INET,
        NULLIF(current_setting('app.user_agent', true), ''),
        NULLIF(current_setting('app.request_id', true), '')
    );
    
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- 주요 테이블에 감사 로그 트리거 적용
CREATE TRIGGER audit_buildings
    AFTER INSERT OR UPDATE OR DELETE ON buildings
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_units
    AFTER INSERT OR UPDATE OR DELETE ON units
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_tenants
    AFTER INSERT OR UPDATE OR DELETE ON tenants
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_lease_contracts
    AFTER INSERT OR UPDATE OR DELETE ON lease_contracts
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_journal_entries
    AFTER INSERT OR UPDATE OR DELETE ON journal_entries
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

CREATE TRIGGER audit_users
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION create_audit_log();

-- =====================================================
-- 사용자 관리 관련 함수들
-- =====================================================

-- 사용자 로그인 처리 함수
CREATE OR REPLACE FUNCTION process_user_login(
    p_username VARCHAR(50),
    p_password_hash VARCHAR(255),
    p_ip_address INET,
    p_user_agent TEXT
)
RETURNS TABLE(
    success BOOLEAN,
    user_id BIGINT,
    session_token VARCHAR(255),
    message TEXT
) AS $$
DECLARE
    v_user_record users%ROWTYPE;
    v_session_token VARCHAR(255);
    v_session_id BIGINT;
BEGIN
    -- 사용자 조회
    SELECT * INTO v_user_record
    FROM users u
    WHERE u.username = p_username AND u.is_active = true;
    
    -- 사용자가 존재하지 않거나 계정이 잠긴 경우
    IF v_user_record.id IS NULL THEN
        INSERT INTO login_history (username, login_type, ip_address, user_agent, failure_reason)
        VALUES (p_username, 'FAILED', p_ip_address, p_user_agent, 'USER_NOT_FOUND');
        
        RETURN QUERY SELECT false, NULL::BIGINT, NULL::VARCHAR(255), '사용자를 찾을 수 없습니다.'::TEXT;
        RETURN;
    END IF;
    
    -- 계정 잠금 확인
    IF v_user_record.locked_until IS NOT NULL AND v_user_record.locked_until > CURRENT_TIMESTAMP THEN
        INSERT INTO login_history (user_id, username, login_type, ip_address, user_agent, failure_reason)
        VALUES (v_user_record.id, p_username, 'LOCKED', p_ip_address, p_user_agent, 'ACCOUNT_LOCKED');
        
        RETURN QUERY SELECT false, NULL::BIGINT, NULL::VARCHAR(255), '계정이 잠겨있습니다.'::TEXT;
        RETURN;
    END IF;
    
    -- 비밀번호 확인
    IF v_user_record.password_hash != p_password_hash THEN
        -- 실패 횟수 증가
        UPDATE users 
        SET 
            failed_login_attempts = failed_login_attempts + 1,
            locked_until = CASE 
                WHEN failed_login_attempts + 1 >= 5 THEN CURRENT_TIMESTAMP + INTERVAL '30 minutes'
                ELSE NULL
            END,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_user_record.id;
        
        INSERT INTO login_history (user_id, username, login_type, ip_address, user_agent, failure_reason)
        VALUES (v_user_record.id, p_username, 'FAILED', p_ip_address, p_user_agent, 'INVALID_PASSWORD');
        
        RETURN QUERY SELECT false, NULL::BIGINT, NULL::VARCHAR(255), '비밀번호가 올바르지 않습니다.'::TEXT;
        RETURN;
    END IF;
    
    -- 로그인 성공 처리
    v_session_token := encode(gen_random_bytes(32), 'base64');
    
    -- 세션 생성
    INSERT INTO user_sessions (user_id, session_token, ip_address, user_agent, expires_at)
    VALUES (v_user_record.id, v_session_token, p_ip_address, p_user_agent, CURRENT_TIMESTAMP + INTERVAL '24 hours')
    RETURNING id INTO v_session_id;
    
    -- 사용자 정보 업데이트
    UPDATE users 
    SET 
        last_login_at = CURRENT_TIMESTAMP,
        last_login_ip = p_ip_address,
        failed_login_attempts = 0,
        locked_until = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_record.id;
    
    -- 로그인 이력 기록
    INSERT INTO login_history (user_id, username, login_type, ip_address, user_agent, session_id)
    VALUES (v_user_record.id, p_username, 'SUCCESS', p_ip_address, p_user_agent, v_session_id);
    
    RETURN QUERY SELECT true, v_user_record.id, v_session_token, '로그인 성공'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- 권한 확인 함수
CREATE OR REPLACE FUNCTION check_user_permission(
    p_user_id BIGINT,
    p_resource VARCHAR(100),
    p_action VARCHAR(50),
    p_building_id BIGINT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_permission BOOLEAN := false;
    v_role_id BIGINT;
BEGIN
    -- 사용자 역할 조회
    SELECT role_id INTO v_role_id
    FROM users
    WHERE id = p_user_id AND is_active = true;
    
    IF v_role_id IS NULL THEN
        RETURN false;
    END IF;
    
    -- 권한 매트릭스에서 권한 확인
    SELECT is_allowed INTO v_has_permission
    FROM permission_matrix
    WHERE role_id = v_role_id
        AND resource = p_resource
        AND action = p_action;
    
    -- 건물별 접근 권한 확인 (필요한 경우)
    IF v_has_permission AND p_building_id IS NOT NULL THEN
        SELECT EXISTS(
            SELECT 1 
            FROM user_building_access uba
            WHERE uba.user_id = p_user_id
                AND uba.building_id = p_building_id
                AND uba.is_active = true
                AND (uba.expires_at IS NULL OR uba.expires_at > CURRENT_TIMESTAMP)
        ) INTO v_has_permission;
    END IF;
    
    RETURN COALESCE(v_has_permission, false);
END;
$$ LANGUAGE plpgsql;--
 =====================================================
-- 기본 역할 및 권한 데이터 삽입
-- =====================================================

-- 기본 역할 생성
INSERT INTO roles (name, display_name, description, is_system_role, permissions) VALUES
('SUPER_ADMIN', '시스템 관리자', '모든 권한을 가진 시스템 관리자', true, '{
    "system": ["*"],
    "users": ["*"],
    "buildings": ["*"],
    "accounting": ["*"]
}'),
('BUILDING_ADMIN', '건물 관리자', '건물 관리 전체 권한', false, '{
    "buildings": ["read", "update"],
    "tenants": ["*"],
    "contracts": ["*"],
    "invoices": ["*"],
    "payments": ["*"],
    "maintenance": ["*"],
    "reports": ["*"]
}'),
('ACCOUNTING_MANAGER', '회계 담당자', '회계 및 재무 관리 권한', false, '{
    "accounting": ["*"],
    "invoices": ["*"],
    "payments": ["*"],
    "reports": ["read"]
}'),
('FACILITY_MANAGER', '시설 관리자', '시설 유지보수 관리 권한', false, '{
    "buildings": ["read"],
    "maintenance": ["*"],
    "facilities": ["*"],
    "vendors": ["*"]
}'),
('STAFF', '일반 직원', '기본 조회 및 제한적 수정 권한', false, '{
    "buildings": ["read"],
    "tenants": ["read", "update"],
    "contracts": ["read"],
    "invoices": ["read"],
    "maintenance": ["read", "create"]
}'),
('VIEWER', '조회자', '읽기 전용 권한', false, '{
    "buildings": ["read"],
    "tenants": ["read"],
    "contracts": ["read"],
    "invoices": ["read"],
    "reports": ["read"]
}');

-- 권한 매트릭스 데이터 삽입
INSERT INTO permission_matrix (role_id, resource, action, is_allowed) VALUES
-- SUPER_ADMIN 권한 (모든 권한)
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'create', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'read', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'update', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'users', 'delete', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'create', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'update', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'buildings', 'delete', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'accounting', 'create', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'accounting', 'read', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'accounting', 'update', true),
((SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), 'accounting', 'delete', true),

-- BUILDING_ADMIN 권한
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'buildings', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'tenants', 'delete', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'contracts', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'contracts', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'contracts', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'contracts', 'delete', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'invoices', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'invoices', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'invoices', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'payments', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'payments', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'payments', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'maintenance', 'create', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'maintenance', 'read', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'maintenance', 'update', true),
((SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), 'reports', 'read', true),

-- ACCOUNTING_MANAGER 권한
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'accounting', 'create', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'accounting', 'read', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'accounting', 'update', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'accounting', 'delete', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'invoices', 'create', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'invoices', 'read', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'invoices', 'update', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'payments', 'create', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'payments', 'read', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'payments', 'update', true),
((SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), 'reports', 'read', true),

-- FACILITY_MANAGER 권한
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'maintenance', 'create', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'maintenance', 'read', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'maintenance', 'update', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'maintenance', 'delete', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'facilities', 'create', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'facilities', 'read', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'facilities', 'update', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'vendors', 'create', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'vendors', 'read', true),
((SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), 'vendors', 'update', true),

-- STAFF 권한
((SELECT id FROM roles WHERE name = 'STAFF'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'tenants', 'read', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'tenants', 'update', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'contracts', 'read', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'invoices', 'read', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'maintenance', 'read', true),
((SELECT id FROM roles WHERE name = 'STAFF'), 'maintenance', 'create', true),

-- VIEWER 권한 (읽기 전용)
((SELECT id FROM roles WHERE name = 'VIEWER'), 'buildings', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'tenants', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'contracts', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'invoices', 'read', true),
((SELECT id FROM roles WHERE name = 'VIEWER'), 'reports', 'read', true);

-- =====================================================
-- 감사 로그 관련 뷰 및 함수
-- =====================================================

-- 감사 로그 요약 뷰
CREATE VIEW v_audit_log_summary AS
SELECT 
    DATE(created_at) as audit_date,
    table_name,
    action,
    COUNT(*) as action_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT building_id) as unique_buildings
FROM audit_logs
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), table_name, action
ORDER BY audit_date DESC, table_name, action;

-- 사용자별 활동 요약 뷰
CREATE VIEW v_user_activity_summary AS
SELECT 
    u.id as user_id,
    u.username,
    u.full_name,
    r.display_name as role_name,
    COUNT(al.id) as total_actions,
    COUNT(DISTINCT al.table_name) as tables_accessed,
    MAX(al.created_at) as last_activity,
    COUNT(CASE WHEN al.action = 'INSERT' THEN 1 END) as creates,
    COUNT(CASE WHEN al.action = 'UPDATE' THEN 1 END) as updates,
    COUNT(CASE WHEN al.action = 'DELETE' THEN 1 END) as deletes
FROM users u
LEFT JOIN roles r ON u.role_id = r.id
LEFT JOIN audit_logs al ON u.id = al.user_id 
    AND al.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY u.id, u.username, u.full_name, r.display_name
ORDER BY total_actions DESC;

-- 로그인 통계 뷰
CREATE VIEW v_login_statistics AS
SELECT 
    DATE(created_at) as login_date,
    login_type,
    COUNT(*) as login_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT ip_address) as unique_ips
FROM login_history
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at), login_type
ORDER BY login_date DESC, login_type;

-- 세션 정리 함수 (만료된 세션 삭제)
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM user_sessions
    WHERE expires_at < CURRENT_TIMESTAMP OR is_active = false;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    -- 로그아웃 이력 기록
    INSERT INTO login_history (user_id, username, login_type, created_at)
    SELECT 
        u.id,
        u.username,
        'LOGOUT',
        CURRENT_TIMESTAMP
    FROM users u
    WHERE u.id IN (
        SELECT DISTINCT user_id 
        FROM user_sessions 
        WHERE expires_at < CURRENT_TIMESTAMP
    );
    
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 감사 로그 아카이빙 함수 (오래된 로그 정리)
CREATE OR REPLACE FUNCTION archive_old_audit_logs(
    p_days_to_keep INTEGER DEFAULT 365
)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER;
    cutoff_date TIMESTAMP;
BEGIN
    cutoff_date := CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    
    -- 아카이브 테이블로 이동 (실제 구현에서는 별도 아카이브 테이블 생성 필요)
    DELETE FROM audit_logs
    WHERE created_at < cutoff_date;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- 코멘트 추가
COMMENT ON TABLE roles IS '사용자 역할 정의 테이블';
COMMENT ON TABLE users IS '시스템 사용자 정보 테이블';
COMMENT ON TABLE user_building_access IS '사용자별 건물 접근 권한 테이블';
COMMENT ON TABLE permission_matrix IS 'RBAC 권한 매트릭스 테이블';
COMMENT ON TABLE user_sessions IS '사용자 세션 관리 테이블';
COMMENT ON TABLE audit_logs IS '시스템 감사 로그 테이블';
COMMENT ON TABLE login_history IS '로그인/로그아웃 이력 테이블';
COMMENT ON TABLE password_reset_tokens IS '비밀번호 재설정 토큰 테이블';

COMMENT ON COLUMN users.failed_login_attempts IS '연속 로그인 실패 횟수';
COMMENT ON COLUMN users.locked_until IS '계정 잠금 해제 시간';
COMMENT ON COLUMN audit_logs.changed_fields IS '변경된 필드 목록 (UPDATE 시)';
COMMENT ON COLUMN permission_matrix.conditions IS '조건부 권한 설정 (JSON 형태)';

-- 정기 작업을 위한 스케줄링 예제 (실제로는 cron job이나 스케줄러 사용)
/*
-- 매일 자정에 만료된 세션 정리
SELECT cron.schedule('cleanup-sessions', '0 0 * * *', 'SELECT cleanup_expired_sessions();');

-- 매월 1일에 1년 이상된 감사 로그 아카이빙
SELECT cron.schedule('archive-logs', '0 0 1 * *', 'SELECT archive_old_audit_logs(365);');
*/--
 =====================================================
-- 시스템 환경설정 테이블 설계 (System Configuration)
-- =====================================================

-- 조직 설정 테이블 (Organization Settings)
CREATE TABLE organization_settings (
    id BIGSERIAL PRIMARY KEY,
    organization_name VARCHAR(255) NOT NULL,
    business_registration_number VARCHAR(20),
    representative_name VARCHAR(255),
    address TEXT,
    contact_phone VARCHAR(20),
    contact_email VARCHAR(255),
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    locale VARCHAR(10) DEFAULT 'ko_KR',
    currency VARCHAR(3) DEFAULT 'KRW',
    date_format VARCHAR(20) DEFAULT 'YYYY-MM-DD',
    fiscal_year_start_month INTEGER DEFAULT 1 CHECK (fiscal_year_start_month BETWEEN 1 AND 12),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id)
);

-- 시스템 설정 테이블 (System Settings) - 키-값 구조
CREATE TABLE system_settings (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(20) DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json', 'encrypted')),
    category VARCHAR(50) NOT NULL, -- 설정 분류 (email, payment, security, etc.)
    description TEXT,
    is_public BOOLEAN DEFAULT false, -- 클라이언트에서 접근 가능한지 여부
    is_encrypted BOOLEAN DEFAULT false, -- 암호화 저장 여부
    validation_rule JSONB, -- 유효성 검증 규칙
    default_value TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id)
);

-- 설정 변경 이력 테이블 (Setting Change History)
CREATE TABLE setting_change_history (
    id BIGSERIAL PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT,
    changed_by BIGINT REFERENCES users(id),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- 외부 서비스 설정 테이블 (External Service Configurations)
CREATE TABLE external_service_configs (
    id BIGSERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL, -- email, sms, payment, api, etc.
    config_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    is_test_mode BOOLEAN DEFAULT false,
    api_endpoint VARCHAR(500),
    api_key_encrypted TEXT, -- 암호화된 API 키
    last_health_check TIMESTAMP,
    health_status VARCHAR(20) DEFAULT 'unknown' CHECK (health_status IN ('healthy', 'unhealthy', 'unknown')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    UNIQUE(service_name, service_type)
);

-- 알림 설정 테이블 (Notification Settings)
CREATE TABLE notification_settings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
    notification_type VARCHAR(50) NOT NULL, -- contract_expiry, payment_due, maintenance_request, etc.
    channel VARCHAR(20) NOT NULL CHECK (channel IN ('email', 'sms', 'push', 'in_app')),
    is_enabled BOOLEAN DEFAULT true,
    settings JSONB, -- 채널별 세부 설정
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, notification_type, channel)
);

-- 시스템 상태 모니터링 테이블 (System Health Monitoring)
CREATE TABLE system_health_logs (
    id BIGSERIAL PRIMARY KEY,
    component VARCHAR(100) NOT NULL, -- database, external_api, file_system, etc.
    status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'warning', 'critical', 'unknown')),
    response_time_ms INTEGER,
    error_message TEXT,
    additional_data JSONB,
    checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX idx_system_settings_category ON system_settings(category);
CREATE INDEX idx_system_settings_key ON system_settings(setting_key);
CREATE INDEX idx_setting_change_history_key ON setting_change_history(setting_key);
CREATE INDEX idx_setting_change_history_changed_at ON setting_change_history(changed_at);
CREATE INDEX idx_external_service_configs_service ON external_service_configs(service_name, service_type);
CREATE INDEX idx_notification_settings_user_type ON notification_settings(user_id, notification_type);
CREATE INDEX idx_system_health_logs_component ON system_health_logs(component);
CREATE INDEX idx_system_health_logs_checked_at ON system_health_logs(checked_at);

-- =====================================================
-- 시스템 설정 관리 함수들
-- =====================================================

-- 설정값 조회 함수
CREATE OR REPLACE FUNCTION get_system_setting(
    p_setting_key VARCHAR(100),
    p_default_value TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_setting_value TEXT;
BEGIN
    SELECT setting_value INTO v_setting_value
    FROM system_settings
    WHERE setting_key = p_setting_key;
    
    RETURN COALESCE(v_setting_value, p_default_value);
END;
$$ LANGUAGE plpgsql;

-- 설정값 업데이트 함수 (이력 기록 포함)
CREATE OR REPLACE FUNCTION update_system_setting(
    p_setting_key VARCHAR(100),
    p_new_value TEXT,
    p_changed_by BIGINT,
    p_change_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_old_value TEXT;
    v_setting_exists BOOLEAN;
BEGIN
    -- 기존 설정값 조회
    SELECT setting_value, true INTO v_old_value, v_setting_exists
    FROM system_settings
    WHERE setting_key = p_setting_key;
    
    IF NOT v_setting_exists THEN
        RAISE EXCEPTION '설정 키가 존재하지 않습니다: %', p_setting_key;
    END IF;
    
    -- 값이 동일하면 업데이트하지 않음
    IF v_old_value = p_new_value THEN
        RETURN false;
    END IF;
    
    -- 설정값 업데이트
    UPDATE system_settings
    SET 
        setting_value = p_new_value,
        updated_at = CURRENT_TIMESTAMP,
        updated_by = p_changed_by
    WHERE setting_key = p_setting_key;
    
    -- 변경 이력 기록
    INSERT INTO setting_change_history (
        setting_key,
        old_value,
        new_value,
        change_reason,
        changed_by,
        ip_address,
        user_agent
    ) VALUES (
        p_setting_key,
        v_old_value,
        p_new_value,
        p_change_reason,
        p_changed_by,
        NULLIF(current_setting('app.client_ip', true), '')::INET,
        NULLIF(current_setting('app.user_agent', true), '')
    );
    
    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- 외부 서비스 상태 확인 함수
CREATE OR REPLACE FUNCTION check_external_service_health(
    p_service_name VARCHAR(100),
    p_service_type VARCHAR(50)
)
RETURNS BOOLEAN AS $$
DECLARE
    v_config_exists BOOLEAN;
    v_is_active BOOLEAN;
BEGIN
    SELECT is_active, true INTO v_is_active, v_config_exists
    FROM external_service_configs
    WHERE service_name = p_service_name AND service_type = p_service_type;
    
    IF NOT v_config_exists THEN
        RETURN false;
    END IF;
    
    -- 실제 구현에서는 여기서 외부 서비스 API 호출하여 상태 확인
    -- 현재는 단순히 활성 상태만 반환
    RETURN v_is_active;
END;
$$ LANGUAGE plpgsql;

-- 시스템 상태 로그 기록 함수
CREATE OR REPLACE FUNCTION log_system_health(
    p_component VARCHAR(100),
    p_status VARCHAR(20),
    p_response_time_ms INTEGER DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL,
    p_additional_data JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO system_health_logs (
        component,
        status,
        response_time_ms,
        error_message,
        additional_data
    ) VALUES (
        p_component,
        p_status,
        p_response_time_ms,
        p_error_message,
        p_additional_data
    );
    
    -- 오래된 로그 정리 (최근 30일만 보관)
    DELETE FROM system_health_logs
    WHERE component = p_component
        AND checked_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 기본 시스템 설정 데이터 삽입
-- =====================================================

-- 기본 조직 설정
INSERT INTO organization_settings (
    organization_name,
    business_registration_number,
    representative_name,
    address,
    contact_phone,
    contact_email,
    timezone,
    locale,
    currency,
    fiscal_year_start_month,
    created_by
) VALUES (
    'QIRO 건물관리',
    '123-45-67890',
    '대표자명',
    '서울특별시 강남구 테헤란로 123',
    '02-1234-5678',
    'contact@qiro.co.kr',
    'Asia/Seoul',
    'ko_KR',
    'KRW',
    1,
    1
);

-- 기본 시스템 설정값들
INSERT INTO system_settings (setting_key, setting_value, setting_type, category, description, is_public, default_value, created_by) VALUES
-- 일반 설정
('app.name', 'QIRO 건물관리 시스템', 'string', 'general', '애플리케이션 이름', true, 'QIRO', 1),
('app.version', '1.0.0', 'string', 'general', '애플리케이션 버전', true, '1.0.0', 1),
('app.maintenance_mode', 'false', 'boolean', 'general', '유지보수 모드 활성화', false, 'false', 1),

-- 보안 설정
('security.session_timeout_minutes', '30', 'number', 'security', '세션 타임아웃 (분)', false, '30', 1),
('security.max_login_attempts', '5', 'number', 'security', '최대 로그인 시도 횟수', false, '5', 1),
('security.account_lockout_minutes', '30', 'number', 'security', '계정 잠금 시간 (분)', false, '30', 1),
('security.password_min_length', '8', 'number', 'security', '비밀번호 최소 길이', false, '8', 1),
('security.require_2fa_for_admin', 'true', 'boolean', 'security', '관리자 2단계 인증 필수', false, 'false', 1),

-- 이메일 설정
('email.smtp_host', 'smtp.gmail.com', 'string', 'email', 'SMTP 서버 호스트', false, '', 1),
('email.smtp_port', '587', 'number', 'email', 'SMTP 서버 포트', false, '587', 1),
('email.smtp_use_tls', 'true', 'boolean', 'email', 'SMTP TLS 사용', false, 'true', 1),
('email.from_address', 'noreply@qiro.co.kr', 'string', 'email', '발신자 이메일 주소', false, '', 1),
('email.from_name', 'QIRO 건물관리', 'string', 'email', '발신자 이름', false, 'QIRO', 1),

-- 알림 설정
('notification.contract_expiry_days', '30', 'number', 'notification', '계약 만료 알림 일수', false, '30', 1),
('notification.payment_due_days', '3', 'number', 'notification', '납부 기한 알림 일수', false, '3', 1),
('notification.maintenance_auto_assign', 'true', 'boolean', 'notification', '유지보수 요청 자동 배정', false, 'false', 1),

-- 파일 업로드 설정
('file.max_upload_size_mb', '10', 'number', 'file', '최대 파일 업로드 크기 (MB)', false, '10', 1),
('file.allowed_extensions', 'jpg,jpeg,png,pdf,doc,docx,xls,xlsx', 'string', 'file', '허용된 파일 확장자', false, 'jpg,png,pdf', 1),
('file.storage_path', '/uploads', 'string', 'file', '파일 저장 경로', false, '/uploads', 1),

-- 백업 설정
('backup.auto_backup_enabled', 'true', 'boolean', 'backup', '자동 백업 활성화', false, 'false', 1),
('backup.backup_retention_days', '30', 'number', 'backup', '백업 보관 일수', false, '7', 1),
('backup.backup_schedule', '0 2 * * *', 'string', 'backup', '백업 스케줄 (cron)', false, '0 2 * * *', 1);

-- 기본 외부 서비스 설정
INSERT INTO external_service_configs (service_name, service_type, config_data, is_active, is_test_mode, created_by) VALUES
('Gmail SMTP', 'email', '{
    "host": "smtp.gmail.com",
    "port": 587,
    "secure": false,
    "auth": {
        "user": "your-email@gmail.com",
        "pass": "your-app-password"
    }
}', false, true, 1),

('Twilio SMS', 'sms', '{
    "accountSid": "your-account-sid",
    "authToken": "your-auth-token",
    "fromNumber": "+1234567890"
}', false, true, 1),

('한국전력공사 API', 'utility', '{
    "apiUrl": "https://api.kepco.co.kr",
    "apiKey": "your-api-key",
    "timeout": 30000
}', false, true, 1);

-- 코멘트 추가
COMMENT ON TABLE organization_settings IS '조직/회사 기본 정보 설정 테이블';
COMMENT ON TABLE system_settings IS '시스템 전역 설정값 관리 테이블 (키-값 구조)';
COMMENT ON TABLE setting_change_history IS '시스템 설정 변경 이력 추적 테이블';
COMMENT ON TABLE external_service_configs IS '외부 서비스 연동 설정 테이블';
COMMENT ON TABLE notification_settings IS '사용자별 알림 설정 테이블';
COMMENT ON TABLE system_health_logs IS '시스템 상태 모니터링 로그 테이블';

COMMENT ON COLUMN system_settings.is_public IS '클라이언트에서 접근 가능한 설정인지 여부';
COMMENT ON COLUMN system_settings.is_encrypted IS '암호화하여 저장할 설정인지 여부';
COMMENT ON COLUMN system_settings.validation_rule IS '설정값 유효성 검증 규칙 (JSON 형태)';
COMMENT ON COLUMN external_service_configs.api_key_encrypted IS '암호화된 API 키 저장';
COMMENT ON COLUMN external_service_configs.health_status IS '외부 서비스 상태 (healthy/unhealthy/unknown)';