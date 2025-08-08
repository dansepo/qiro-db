-- =====================================================
-- 민원 및 회계 관리 시스템 - 시스템 공통 테이블
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
        CREATE TYPE permission_type AS ENUM ('READ', 'write', 'delete', 'admin');
    END IF;
END $$;

-- 기본 마스터 테이블들이 없는 경우 생성 (bms 스키마 사용)

-- Companies 테이블 (기존 테이블 참조하여 bms 스키마에 생성)
CREATE TABLE IF NOT EXISTS bms.companies (
    id BIGSERIAL PRIMARY KEY,
    company_uuid UUID UNIQUE DEFAULT gen_random_uuid(),
    business_registration_number VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    representative_name VARCHAR(100) NOT NULL,
    business_address TEXT NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    business_type VARCHAR(50) NOT NULL,
    establishment_date DATE NOT NULL,
    
    -- 인증 관련 필드
    verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED')),
    verification_date TIMESTAMP,
    verification_data JSONB DEFAULT '{}',
    
    -- 구독 관련 필드
    subscription_plan VARCHAR(50) DEFAULT 'BASIC',
    subscription_status VARCHAR(20) DEFAULT 'TRIAL' CHECK (subscription_status IN ('ACTIVE', 'SUSPENDED', 'CANCELLED', 'TRIAL')),
    subscription_start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subscription_end_date TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_companies_contact_email CHECK (contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_companies_establishment_date CHECK (establishment_date <= CURRENT_DATE)
);

-- Buildings 테이블 (기본 구조)
CREATE TABLE IF NOT EXISTS bms.buildings (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    building_code VARCHAR(20) NOT NULL,
    building_name VARCHAR(255) NOT NULL,
    building_type VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    postal_code VARCHAR(10),
    total_floors INTEGER DEFAULT 0,
    basement_floors INTEGER DEFAULT 0,
    total_units INTEGER DEFAULT 0,
    construction_date DATE,
    completion_date DATE,
    
    -- 건물 관리 정보
    management_start_date DATE,
    management_company VARCHAR(255),
    
    -- 위치 정보
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    
    -- 시설 정보
    facilities JSONB DEFAULT '{}',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_buildings_company_code UNIQUE(company_id, building_code)
);

-- Units 테이블 (기본 구조)
CREATE TABLE IF NOT EXISTS bms.units (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT NOT NULL REFERENCES bms.companies(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES bms.buildings(id) ON DELETE CASCADE,
    unit_code VARCHAR(20) NOT NULL,
    unit_number VARCHAR(50) NOT NULL,
    floor_number INTEGER NOT NULL,
    unit_type VARCHAR(50) NOT NULL,
    
    -- 면적 정보
    exclusive_area DECIMAL(8,2),
    common_area DECIMAL(8,2),
    total_area DECIMAL(8,2),
    
    -- 상태 정보
    occupancy_status VARCHAR(20) DEFAULT 'VACANT' CHECK (occupancy_status IN ('OCCUPIED', 'VACANT', 'MAINTENANCE')),
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    CONSTRAINT uk_units_building_code UNIQUE(building_id, unit_code),
    CONSTRAINT uk_units_building_number UNIQUE(building_id, unit_number)
);

-- Users 테이블 (기본 구조)
CREATE TABLE IF NOT EXISTS bms.users (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id) ON DELETE CASCADE,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    
    -- 개인 정보
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    
    -- 사용자 상태
    user_status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (user_status IN ('ACTIVE', 'INACTIVE', 'LOCKED', 'PENDING_VERIFICATION')),
    user_type VARCHAR(20) DEFAULT 'USER' CHECK (user_type IN ('SUPER_ADMIN', 'ADMIN', 'EMPLOYEE', 'USER')),
    
    -- 인증 관련
    email_verified BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    last_login_at TIMESTAMP,
    password_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 사용자 역할 테이블
CREATE TABLE IF NOT EXISTS bms.user_roles (
    role_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id) ON DELETE CASCADE,
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
    created_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_user_roles_company_code UNIQUE(company_id, role_code)
);

-- 사용자 역할 할당 테이블
CREATE TABLE IF NOT EXISTS bms.user_role_assignments (
    assignment_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES bms.users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL REFERENCES bms.user_roles(role_id) ON DELETE CASCADE,
    
    -- 할당 기간
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    
    -- 할당자 정보
    assigned_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_user_role_assignments UNIQUE(user_id, role_id)
);

-- 사용자 권한 테이블
CREATE TABLE IF NOT EXISTS bms.user_permissions (
    permission_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id) ON DELETE CASCADE,
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
    granted_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_role_permissions UNIQUE(role_id, permission_id)
);

-- 접근 로그 테이블
CREATE TABLE IF NOT EXISTS bms.access_logs (
    log_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id),
    user_id BIGINT REFERENCES bms.users(id),
    
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
    company_id BIGINT REFERENCES bms.companies(id),
    
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
    user_id BIGINT REFERENCES bms.users(id),
    session_id VARCHAR(255),
    
    -- 추가 데이터
    additional_data JSONB DEFAULT '{}'
);

-- 시스템 설정 테이블
CREATE TABLE IF NOT EXISTS bms.system_settings (
    setting_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id),
    
    -- 설정 정보
    setting_category VARCHAR(100) NOT NULL,
    setting_key VARCHAR(255) NOT NULL,
    setting_name VARCHAR(255) NOT NULL,
    setting_description TEXT,
    
    -- 설정 값
    setting_type setting_type NOT NULL,
    setting_value TEXT,
    default_value TEXT,
    
    -- 설정 속성
    is_system_setting BOOLEAN DEFAULT false,
    is_encrypted BOOLEAN DEFAULT false,
    is_required BOOLEAN DEFAULT false,
    
    -- 유효성 검증
    validation_rules JSONB,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_system_settings_company_key UNIQUE(company_id, setting_key)
);

-- 코드 관리 테이블
CREATE TABLE IF NOT EXISTS bms.common_codes (
    code_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id),
    
    -- 코드 정보
    code_group VARCHAR(100) NOT NULL,
    code_value VARCHAR(100) NOT NULL,
    code_name VARCHAR(255) NOT NULL,
    code_description TEXT,
    
    -- 코드 속성
    parent_code_id BIGINT REFERENCES bms.common_codes(code_id),
    sort_order INTEGER DEFAULT 0,
    is_system_code BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    
    -- 추가 속성
    attributes JSONB DEFAULT '{}',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT REFERENCES bms.users(id),
    updated_by BIGINT REFERENCES bms.users(id),
    
    CONSTRAINT uk_common_codes_company_group_value UNIQUE(company_id, code_group, code_value)
);

-- 데이터 암호화 키 관리 테이블
CREATE TABLE IF NOT EXISTS bms.encryption_keys (
    key_id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES bms.companies(id),
    
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
    company_id BIGINT REFERENCES bms.companies(id),
    
    -- 처리 대상 정보
    data_subject_id BIGINT, -- 정보주체 ID
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
    processed_by BIGINT REFERENCES bms.users(id),
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 추가 메타데이터
    metadata JSONB DEFAULT '{}'
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_companies_verification_status ON bms.companies(verification_status);
CREATE INDEX IF NOT EXISTS idx_companies_subscription_status ON bms.companies(subscription_status);
CREATE INDEX IF NOT EXISTS idx_companies_created_at ON bms.companies(created_at);

CREATE INDEX IF NOT EXISTS idx_buildings_company ON bms.buildings(company_id);
CREATE INDEX IF NOT EXISTS idx_buildings_building_type ON bms.buildings(building_type);

CREATE INDEX IF NOT EXISTS idx_units_company ON bms.units(company_id);
CREATE INDEX IF NOT EXISTS idx_units_building ON bms.units(building_id);
CREATE INDEX IF NOT EXISTS idx_units_occupancy_status ON bms.units(occupancy_status);

CREATE INDEX IF NOT EXISTS idx_users_company ON bms.users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_status ON bms.users(user_status);
CREATE INDEX IF NOT EXISTS idx_users_type ON bms.users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_email ON bms.users(email);
CREATE INDEX IF NOT EXISTS idx_users_last_login ON bms.users(last_login_at);

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

CREATE INDEX IF NOT EXISTS idx_system_settings_company ON bms.system_settings(company_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON bms.system_settings(setting_category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON bms.system_settings(setting_key);

CREATE INDEX IF NOT EXISTS idx_common_codes_company ON bms.common_codes(company_id);
CREATE INDEX IF NOT EXISTS idx_common_codes_group ON bms.common_codes(code_group);
CREATE INDEX IF NOT EXISTS idx_common_codes_parent ON bms.common_codes(parent_code_id);
CREATE INDEX IF NOT EXISTS idx_common_codes_active ON bms.common_codes(is_active);

CREATE INDEX IF NOT EXISTS idx_encryption_keys_company ON bms.encryption_keys(company_id);
CREATE INDEX IF NOT EXISTS idx_encryption_keys_active ON bms.encryption_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_encryption_keys_purpose ON bms.encryption_keys(key_purpose);

CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_company ON bms.privacy_processing_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_subject ON bms.privacy_processing_logs(data_subject_id, data_subject_type);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_processed_at ON bms.privacy_processing_logs(processed_at);
CREATE INDEX IF NOT EXISTS idx_privacy_processing_logs_type ON bms.privacy_processing_logs(processing_type);

-- 접근 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_user_access(
    p_company_id BIGINT,
    p_user_id BIGINT,
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
    p_company_id BIGINT,
    p_log_level log_level,
    p_message TEXT,
    p_logger_name VARCHAR(255) DEFAULT NULL,
    p_user_id BIGINT DEFAULT NULL,
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
    p_company_id BIGINT,
    p_data_subject_id BIGINT,
    p_data_subject_type VARCHAR(50),
    p_processing_purpose VARCHAR(255),
    p_processing_type VARCHAR(100),
    p_data_categories TEXT[],
    p_legal_basis VARCHAR(255) DEFAULT NULL,
    p_processed_by BIGINT DEFAULT NULL
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
    p_user_id BIGINT,
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

-- 시스템 설정 값 조회 함수
CREATE OR REPLACE FUNCTION bms.get_system_setting(
    p_company_id BIGINT,
    p_setting_key VARCHAR(255),
    p_default_value TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    setting_value TEXT;
BEGIN
    SELECT 
        CASE 
            WHEN setting_value IS NOT NULL THEN setting_value
            ELSE COALESCE(default_value, p_default_value)
        END
    INTO setting_value
    FROM bms.system_settings
    WHERE (company_id = p_company_id OR company_id IS NULL)
      AND setting_key = p_setting_key
    ORDER BY company_id NULLS LAST
    LIMIT 1;
    
    RETURN setting_value;
END;
$$ LANGUAGE plpgsql;

-- 기본 시스템 역할 생성 함수
CREATE OR REPLACE FUNCTION bms.create_default_roles(p_company_id BIGINT)
RETURNS VOID AS $$
BEGIN
    -- 시스템 관리자 역할
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

-- 기본 시스템 설정 생성 함수
CREATE OR REPLACE FUNCTION bms.create_default_system_settings(p_company_id BIGINT)
RETURNS VOID AS $$
BEGIN
    INSERT INTO bms.system_settings (company_id, setting_category, setting_key, setting_name, setting_type, setting_value, default_value, setting_description) VALUES
    -- 일반 설정
    (p_company_id, 'GENERAL', 'SYSTEM_NAME', '시스템명', 'STRING', 'QIRO 건물관리시스템', 'QIRO 건물관리시스템', '시스템 표시명'),
    (p_company_id, 'GENERAL', 'TIMEZONE', '시간대', 'STRING', 'Asia/Seoul', 'Asia/Seoul', '시스템 기본 시간대'),
    (p_company_id, 'GENERAL', 'DATE_FORMAT', '날짜 형식', 'STRING', 'YYYY-MM-DD', 'YYYY-MM-DD', '날짜 표시 형식'),
    (p_company_id, 'GENERAL', 'CURRENCY', '통화', 'STRING', 'KRW', 'KRW', '기본 통화 단위'),
    
    -- 보안 설정
    (p_company_id, 'SECURITY', 'PASSWORD_MIN_LENGTH', '최소 비밀번호 길이', 'INTEGER', '8', '8', '사용자 비밀번호 최소 길이'),
    (p_company_id, 'SECURITY', 'SESSION_TIMEOUT_MINUTES', '세션 타임아웃', 'INTEGER', '30', '30', '세션 만료 시간 (분)'),
    (p_company_id, 'SECURITY', 'MAX_LOGIN_ATTEMPTS', '최대 로그인 시도 횟수', 'INTEGER', '5', '5', '계정 잠금 전 최대 로그인 시도 횟수'),
    (p_company_id, 'SECURITY', 'ACCOUNT_LOCKOUT_MINUTES', '계정 잠금 시간', 'INTEGER', '30', '30', '계정 잠금 지속 시간 (분)'),
    
    -- 알림 설정
    (p_company_id, 'NOTIFICATION', 'EMAIL_ENABLED', '이메일 알림 활성화', 'BOOLEAN', 'true', 'true', '이메일 알림 사용 여부'),
    (p_company_id, 'NOTIFICATION', 'SMS_ENABLED', 'SMS 알림 활성화', 'BOOLEAN', 'true', 'true', 'SMS 알림 사용 여부'),
    (p_company_id, 'NOTIFICATION', 'PUSH_ENABLED', '푸시 알림 활성화', 'BOOLEAN', 'true', 'true', '푸시 알림 사용 여부'),
    
    -- 민원 관리 설정
    (p_company_id, 'COMPLAINT', 'DEFAULT_SLA_HOURS', '기본 SLA 시간', 'INTEGER', '72', '72', '민원 처리 기본 SLA (시간)'),
    (p_company_id, 'COMPLAINT', 'AUTO_ASSIGN_ENABLED', '자동 배정 활성화', 'BOOLEAN', 'true', 'true', '민원 자동 배정 사용 여부'),
    (p_company_id, 'COMPLAINT', 'SATISFACTION_SURVEY_ENABLED', '만족도 조사 활성화', 'BOOLEAN', 'true', 'true', '민원 해결 후 만족도 조사 실시 여부'),
    
    -- 회계 설정
    (p_company_id, 'ACCOUNTING', 'FISCAL_YEAR_START_MONTH', '회계연도 시작월', 'INTEGER', '1', '1', '회계연도 시작 월 (1-12)'),
    (p_company_id, 'ACCOUNTING', 'AUTO_APPROVAL_THRESHOLD', '자동 승인 한도', 'DECIMAL', '100000', '100000', '자동 승인 가능한 금액 한도'),
    (p_company_id, 'ACCOUNTING', 'BUDGET_ALERT_THRESHOLD', '예산 경고 임계값', 'DECIMAL', '0.8', '0.8', '예산 사용률 경고 임계값 (0.0-1.0)')
    ON CONFLICT (company_id, setting_key) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 기본 공통 코드 생성 함수
CREATE OR REPLACE FUNCTION bms.create_default_common_codes(p_company_id BIGINT)
RETURNS VOID AS $$
BEGIN
    -- 건물 유형
    INSERT INTO bms.common_codes (company_id, code_group, code_value, code_name, code_description, is_system_code) VALUES
    (p_company_id, 'BUILDING_TYPE', 'APARTMENT', '아파트', '공동주택 아파트', true),
    (p_company_id, 'BUILDING_TYPE', 'OFFICETEL', '오피스텔', '업무시설 겸용 주거시설', true),
    (p_company_id, 'BUILDING_TYPE', 'COMMERCIAL', '상업시설', '상업용 건물', true),
    (p_company_id, 'BUILDING_TYPE', 'OFFICE', '사무시설', '업무용 건물', true),
    (p_company_id, 'BUILDING_TYPE', 'MIXED', '복합시설', '주거/상업/업무 복합 건물', true),
    
    -- 세대 유형
    (p_company_id, 'UNIT_TYPE', 'RESIDENTIAL', '주거용', '주거 목적 세대', true),
    (p_company_id, 'UNIT_TYPE', 'COMMERCIAL', '상업용', '상업 목적 세대', true),
    (p_company_id, 'UNIT_TYPE', 'OFFICE', '사무용', '업무 목적 세대', true),
    (p_company_id, 'UNIT_TYPE', 'STORAGE', '창고', '창고 목적 세대', true),
    (p_company_id, 'UNIT_TYPE', 'PARKING', '주차장', '주차 목적 세대', true),
    
    -- 민원 우선순위
    (p_company_id, 'COMPLAINT_PRIORITY', 'LOW', '낮음', '일반적인 민원', true),
    (p_company_id, 'COMPLAINT_PRIORITY', 'MEDIUM', '보통', '보통 수준의 민원', true),
    (p_company_id, 'COMPLAINT_PRIORITY', 'HIGH', '높음', '중요한 민원', true),
    (p_company_id, 'COMPLAINT_PRIORITY', 'URGENT', '긴급', '긴급 처리 필요 민원', true)
    ON CONFLICT (company_id, code_group, code_value) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.companies IS '회사 정보 테이블 - 멀티테넌트 구조의 최상위 조직';
COMMENT ON TABLE bms.buildings IS '건물 정보 테이블 - 회사별 관리 건물 정보';
COMMENT ON TABLE bms.units IS '세대 정보 테이블 - 건물별 세대/호실 정보';
COMMENT ON TABLE bms.users IS '사용자 정보 테이블 - 시스템 사용자 계정 관리';
COMMENT ON TABLE bms.user_roles IS '사용자 역할 테이블 - 역할 기반 접근 제어를 위한 역할 정의';
COMMENT ON TABLE bms.user_role_assignments IS '사용자 역할 할당 테이블 - 사용자별 역할 할당 관리';
COMMENT ON TABLE bms.user_permissions IS '사용자 권한 테이블 - 세분화된 권한 정의';
COMMENT ON TABLE bms.role_permissions IS '역할별 권한 할당 테이블 - 역할과 권한의 매핑';
COMMENT ON TABLE bms.access_logs IS '접근 로그 테이블 - 사용자 접근 및 활동 기록';
COMMENT ON TABLE bms.system_logs IS '시스템 로그 테이블 - 시스템 이벤트 및 오류 기록';
COMMENT ON TABLE bms.system_settings IS '시스템 설정 테이블 - 회사별 시스템 설정 관리';
COMMENT ON TABLE bms.common_codes IS '공통 코드 테이블 - 시스템에서 사용하는 코드 값 관리';
COMMENT ON TABLE bms.encryption_keys IS '암호화 키 관리 테이블 - 개인정보 암호화를 위한 키 관리';
COMMENT ON TABLE bms.privacy_processing_logs IS '개인정보 처리 로그 테이블 - 개인정보 처리 이력 관리';

-- 컬럼 코멘트 추가
COMMENT ON COLUMN bms.companies.business_registration_number IS '사업자등록번호 - 10자리 숫자, 유효성 검증됨';
COMMENT ON COLUMN bms.companies.verification_status IS '사업자 인증 상태 - PENDING(대기), VERIFIED(인증), REJECTED(거부), SUSPENDED(정지)';
COMMENT ON COLUMN bms.companies.subscription_status IS '구독 상태 - ACTIVE(활성), SUSPENDED(정지), CANCELLED(취소), TRIAL(체험)';

COMMENT ON COLUMN bms.users.user_status IS '사용자 상태 - ACTIVE(활성), INACTIVE(비활성), LOCKED(잠금), PENDING_VERIFICATION(인증대기)';
COMMENT ON COLUMN bms.users.user_type IS '사용자 유형 - SUPER_ADMIN(슈퍼관리자), ADMIN(관리자), EMPLOYEE(직원), USER(일반사용자)';

COMMENT ON COLUMN bms.access_logs.access_result IS '접근 결과 - SUCCESS(성공), FAILED(실패), BLOCKED(차단), EXPIRED(만료)';
COMMENT ON COLUMN bms.access_logs.ip_address IS '접근 IP 주소';
COMMENT ON COLUMN bms.access_logs.response_time_ms IS '응답 시간 (밀리초)';

COMMENT ON COLUMN bms.system_settings.setting_type IS '설정 값 타입 - STRING, INTEGER, DECIMAL, BOOLEAN, JSON, DATE, TIME';
COMMENT ON COLUMN bms.system_settings.is_encrypted IS '암호화 여부 - 민감한 설정값의 경우 true';

COMMENT ON COLUMN bms.privacy_processing_logs.processing_type IS '처리 유형 - COLLECT(수집), USE(이용), PROVIDE(제공), DESTROY(파기) 등';
COMMENT ON COLUMN bms.privacy_processing_logs.data_categories IS '처리한 개인정보 항목 배열';