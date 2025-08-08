-- =====================================================
-- 민원 및 회계 관리 시스템 - 시스템 추가 테이블 (기존 구조 호환)
-- 작성일: 2025-01-30
-- 요구사항: 12.1, 14.1 - 시스템 통합, 보안 및 개인정보 보호
-- =====================================================

-- 시스템 공통 ENUM 타입 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'access_result') THEN
        CREATE TYPE access_result AS ENUM ('SUCCESS', 'FAILED', 'BLOCKED', 'EXPIRED');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'log_level') THEN
        CREATE TYPE log_level AS ENUM ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'setting_type') THEN
        CREATE TYPE setting_type AS ENUM ('STRING', 'INTEGER', 'DECIMAL', 'BOOLEAN', 'JSON', 'DATE', 'TIME');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'permission_type') THEN
        CREATE TYPE permission_type AS ENUM ('read', 'write', 'delete', 'admin');
    END IF;
END $$;

-- 사용자 역할 테이블
CREATE TABLE IF NOT EXISTS bms.user_roles (
    role_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    role_code VARCHAR(50) NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- 권한 설정
    permissions JSONB DEFAULT '{}',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID REFERENCES bms.users(user_id),
    
    CONSTRAINT uk_user_roles_company_code UNIQUE(company_id, role_code)
);

-- 사용자 역할 할당 테이블
CREATE TABLE IF NOT EXISTS bms.user_role_assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES bms.users(user_id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES bms.user_roles(role_id) ON DELETE CASCADE,
    
    -- 할당 기간
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    -- 할당자 정보
    assigned_by UUID REFERENCES bms.users(user_id),
    
    CONSTRAINT uk_user_role_assignments UNIQUE(user_id, role_id)
);

-- 사용자 권한 테이블
CREATE TABLE IF NOT EXISTS bms.user_permissions (
    permission_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    permission_code VARCHAR(100) NOT NULL,
    permission_name VARCHAR(255) NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    permission_type permission_type NOT NULL,
    description TEXT,
    is_system_permission BOOLEAN DEFAULT false,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_user_permissions_company_code UNIQUE(company_id, permission_code)
);

-- 역할별 권한 할당 테이블
CREATE TABLE IF NOT EXISTS bms.role_permissions (
    role_permission_id BIGSERIAL PRIMARY KEY,
    role_id BIGINT NOT NULL REFERENCES bms.user_roles(role_id) ON DELETE CASCADE,
    permission_id BIGINT NOT NULL REFERENCES bms.user_permissions(permission_id) ON DELETE CASCADE,
    
    -- 권한 부여 정보
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID REFERENCES bms.users(user_id),
    
    CONSTRAINT uk_role_permissions UNIQUE(role_id, permission_id)
);

-- 접근 로그 테이블
CREATE TABLE IF NOT EXISTS bms.access_logs (
    log_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id),
    user_id UUID REFERENCES bms.users(user_id),
    
    -- 접근 정보
    access_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    access_type VARCHAR(50) NOT NULL, -- LOGIN, LOGOUT, API_CALL, PAGE_VIEW, etc.
    resource_type VARCHAR(100),
    resource_id VARCHAR(100),
    action VARCHAR(100),
    
    -- 접근 결과
    access_result access_result NOT NULL,
    error_message TEXT,
    
    -- 클라이언트 정보
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    
    -- 요청/응답 정보
    request_method VARCHAR(10),
    request_url TEXT,
    request_params JSONB,
    response_status INTEGER,
    response_time_ms INTEGER,
    
    -- 추가 메타데이터
    metadata JSONB DEFAULT '{}'
);

-- 시스템 로그 테이블
CREATE TABLE IF NOT EXISTS bms.system_logs (
    log_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id),
    
    -- 로그 기본 정보
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_level log_level NOT NULL,
    logger_name VARCHAR(255),
    
    -- 로그 내용
    message TEXT NOT NULL,
    exception_class VARCHAR(255),
    exception_message TEXT,
    stack_trace TEXT,
    
    -- 컨텍스트 정보
    thread_name VARCHAR(100),
    class_name VARCHAR(255),
    method_name VARCHAR(100),
    line_number INTEGER,
    
    -- 사용자 정보
    user_id UUID REFERENCES bms.users(user_id),
    session_id VARCHAR(255),
    
    -- 추가 데이터
    additional_data JSONB DEFAULT '{}'
);

-- 데이터 암호화 키 관리 테이블
CREATE TABLE IF NOT EXISTS bms.encryption_keys (
    key_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id),
    
    -- 키 정보
    key_name VARCHAR(255) NOT NULL,
    key_type VARCHAR(50) NOT NULL, -- AES, RSA, etc.
    key_purpose VARCHAR(100) NOT NULL, -- PII, PAYMENT, etc.
    
    -- 키 데이터 (암호화되어 저장)
    encrypted_key TEXT NOT NULL,
    key_version INTEGER DEFAULT 1,
    
    -- 키 상태
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- 키 사용 통계
    usage_count BIGINT DEFAULT 0,
    last_used_at TIMESTAMP,
    
    CONSTRAINT uk_encryption_keys_company_name UNIQUE(company_id, key_name)
);

-- 개인정보 처리 로그 테이블
CREATE TABLE IF NOT EXISTS bms.privacy_processing_logs (
    log_id BIGSERIAL PRIMARY KEY,
    company_id UUID REFERENCES bms.companies(company_id),
    
    -- 처리 대상 정보
    data_subject_id UUID, -- 정보주체 ID
    data_subject_type VARCHAR(50), -- USER, TENANT, etc.
    
    -- 처리 정보
    processing_purpose VARCHAR(255) NOT NULL,
    processing_type VARCHAR(100) NOT NULL, -- COLLECT, USE, PROVIDE, DESTROY, etc.
    data_categories TEXT[], -- 처리한 개인정보 항목들
    
    -- 법적 근거
    legal_basis VARCHAR(255),
    consent_id BIGINT, -- 동의 ID (해당하는 경우)
    
    -- 처리 결과
    processing_result VARCHAR(50) DEFAULT 'SUCCESS',
    error_message TEXT,
    
    -- 처리자 정보
    processed_by UUID REFERENCES bms.users(user_id),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 추가 메타데이터
    metadata JSONB DEFAULT '{}'
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_roles_company ON bms.user_roles(company_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON bms.user_roles(is_active);

CREATE INDEX IF NOT EXISTS idx_user_role_assignments_user ON bms.user_role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_role ON bms.user_role_assignments(role_id);
CREATE INDEX IF NOT EXISTS idx_user_role_assignments_active ON bms.user_role_assignments(is_active);

CREATE INDEX IF NOT EXISTS idx_user_permissions_company ON bms.user_permissions(company_id);
CREATE INDEX IF NOT EXISTS idx_user_permissions_resource ON bms.user_permissions(resource_type);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON bms.role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission ON bms.role_permissions(permission_id);

CREATE INDEX IF NOT EXISTS idx_access_logs_company ON bms.access_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_user ON bms.access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_access_logs_time ON bms.access_logs(access_time);
CREATE INDEX IF NOT EXISTS idx_access_logs_type ON bms.access_logs(access_type);
CREATE INDEX IF NOT EXISTS idx_access_logs_result ON bms.access_logs(access_result);
CREATE INDEX IF NOT EXISTS idx_access_logs_ip ON bms.access_logs(ip_address);

CREATE INDEX IF NOT EXISTS idx_system_logs_company ON bms.system_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_system_logs_time ON bms.system_logs(log_time);
CREATE INDEX IF NOT EXISTS idx_system_logs_level ON bms.system_logs(log_level);
CREATE INDEX IF NOT EXISTS idx_system_logs_user ON bms.system_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_encryption_keys_company ON bms.encryption_keys(company_id);
CREATE INDEX IF NOT EXISTS idx_encryption_keys_active ON bms.encryption_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_encryption_keys_purpose ON bms.encryption_keys(key_purpose);

CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_company ON bms.privacy_processing_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_subject ON bms.privacy_processing_logs(data_subject_id, data_subject_type);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_processed_at ON bms.privacy_processing_logs(processed_at);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_type ON bms.privacy_processing_logs(processing_type);

-- 접근 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_user_access(
    p_company_id UUID,
    p_user_id UUID,
    p_access_type VARCHAR(50),
    p_resource_type VARCHAR(100) DEFAULT NULL,
    p_resource_id VARCHAR(100) DEFAULT NULL,
    p_action VARCHAR(100) DEFAULT NULL,
    p_access_result access_result DEFAULT 'SUCCESS',
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_session_id VARCHAR(255) DEFAULT NULL,
    p_request_method VARCHAR(10) DEFAULT NULL,
    p_request_url TEXT DEFAULT NULL,
    p_response_status INTEGER DEFAULT NULL,
    p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.access_logs (
        company_id, user_id, access_type, resource_type, resource_id, action,
        access_result, ip_address, user_agent, session_id, request_method,
        request_url, response_status, error_message
    ) VALUES (
        p_company_id, p_user_id, p_access_type, p_resource_type, p_resource_id, p_action,
        p_access_result, p_ip_address, p_user_agent, p_session_id, p_request_method,
        p_request_url, p_response_status, p_error_message
    );
END;
$$ LANGUAGE plpgsql;

-- 시스템 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_system_event(
    p_company_id UUID,
    p_log_level log_level,
    p_message TEXT,
    p_logger_name VARCHAR(255) DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_exception_class VARCHAR(255) DEFAULT NULL,
    p_exception_message TEXT DEFAULT NULL,
    p_additional_data JSONB DEFAULT '{}'
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.system_logs (
        company_id, log_level, message, logger_name, user_id,
        exception_class, exception_message, additional_data
    ) VALUES (
        p_company_id, p_log_level, p_message, p_logger_name, p_user_id,
        p_exception_class, p_exception_message, p_additional_data
    );
END;
$$ LANGUAGE plpgsql;

-- 개인정보 처리 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_privacy_processing(
    p_company_id UUID,
    p_data_subject_id UUID,
    p_data_subject_type VARCHAR(50),
    p_processing_purpose VARCHAR(255),
    p_processing_type VARCHAR(100),
    p_data_categories TEXT[],
    p_legal_basis VARCHAR(255) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.privacy_processing_logs (
        company_id, data_subject_id, data_subject_type, processing_purpose,
        processing_type, data_categories, legal_basis, processed_by
    ) VALUES (
        p_company_id, p_data_subject_id, p_data_subject_type, p_processing_purpose,
        p_processing_type, p_data_categories, p_legal_basis, p_processed_by
    );
END;
$$ LANGUAGE plpgsql;

-- 사용자 권한 확인 함수
CREATE OR REPLACE FUNCTION bms.check_user_permission(
    p_user_id UUID,
    p_resource_type VARCHAR(100),
    p_permission_type permission_type
)
RETURNS BOOLEAN AS $$
DECLARE
    has_permission BOOLEAN := false;
BEGIN
    -- 역할을 통한 권한 확인
    SELECT EXISTS (
        SELECT 1
        FROM bms.user_role_assignments ura
        JOIN bms.role_permissions rp ON ura.role_id = rp.role_id
        JOIN bms.user_permissions up ON rp.permission_id = up.permission_id
        WHERE ura.user_id = p_user_id
          AND ura.is_active = true
          AND (ura.expires_at IS NULL OR ura.expires_at > CURRENT_TIMESTAMP)
          AND up.resource_type = p_resource_type
          AND up.permission_type = p_permission_type
    ) INTO has_permission;
    
    RETURN has_permission;
END;
$$ LANGUAGE plpgsql;

-- 기본 시스템 역할 생성 함수
CREATE OR REPLACE FUNCTION bms.create_default_roles(p_company_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.user_roles (company_id, role_code, role_name, description, is_system_role, permissions) VALUES
    (p_company_id, 'SYSTEM_ADMIN', '시스템 관리자', '모든 시스템 기능에 대한 관리 권한', true, '{"all": true}'::jsonb),
    (p_company_id, 'BUILDING_MANAGER', '건물 관리자', '건물 관리 업무 전반에 대한 권한', true, '{"buildings": ["read", "write"], "units": ["read", "write"], "complaints": ["read", "write"], "announcements": ["read", "write"]}'::jsonb),
    (p_company_id, 'ACCOUNTANT', '회계 담당자', '회계 및 재무 관리 권한', true, '{"accounting": ["read", "write"], "budget": ["read", "write"], "reports": ["read"]}'::jsonb),
    (p_company_id, 'STAFF', '일반 직원', '기본적인 업무 처리 권한', true, '{"complaints": ["read", "write"], "announcements": ["read"], "services": ["read", "write"]}'::jsonb),
    (p_company_id, 'TENANT', '임차인', '임차인 기본 권한', true, '{"complaints": ["read", "write"], "announcements": ["read"], "services": ["read"]}'::jsonb),
    (p_company_id, 'OWNER', '임대인', '임대인 기본 권한', true, '{"reports": ["read"], "announcements": ["read"], "accounting": ["read"]}'::jsonb)
    ON CONFLICT (company_id, role_code) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.user_roles IS '사용자 역할 테이블 - 역할 기반 접근 제어를 위한 역할 정의';
COMMENT ON TABLE bms.user_role_assignments IS '사용자 역할 할당 테이블 - 사용자별 역할 할당 관리';
COMMENT ON TABLE bms.user_permissions IS '사용자 권한 테이블 - 세분화된 권한 정의';
COMMENT ON TABLE bms.role_permissions IS '역할별 권한 할당 테이블 - 역할과 권한의 매핑';
COMMENT ON TABLE bms.access_logs IS '접근 로그 테이블 - 사용자 접근 및 활동 기록';
COMMENT ON TABLE bms.system_logs IS '시스템 로그 테이블 - 시스템 이벤트 및 오류 기록';
COMMENT ON TABLE bms.encryption_keys IS '암호화 키 관리 테이블 - 개인정보 암호화를 위한 키 관리';
COMMENT ON TABLE bms.privacy_processing_logs IS '개인정보 처리 로그 테이블 - 개인정보 처리 이력 관리';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.access_logs.access_result IS '접근 결과 - SUCCESS(성공), FAILED(실패), BLOCKED(차단), EXPIRED(만료)';
COMMENT ON COLUMN bms.access_logs.ip_address IS '접근 IP 주소';
COMMENT ON COLUMN bms.access_logs.response_time_ms IS '응답 시간 (밀리초)';

COMMENT ON COLUMN bms.privacy_processing_logs.processing_type IS '처리 유형 - COLLECT(수집), USE(이용), PROVIDE(제공), DESTROY(파기) 등';
COMMENT ON COLUMN bms.privacy_processing_logs.data_categories IS '처리한 개인정보 항목 배열';