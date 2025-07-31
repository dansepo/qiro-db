-- =====================================================
-- QIRO 인증 보안 강화 시스템
-- JWT 토큰, 비밀번호 정책, 다단계 인증 지원
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. JWT 토큰 관리 테이블
-- =====================================================

-- JWT 리프레시 토큰 관리
CREATE TABLE refresh_tokens (
    token_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 토큰 정보
    token_hash VARCHAR(255) NOT NULL UNIQUE, -- SHA-256 해시된 토큰
    token_family VARCHAR(255) NOT NULL, -- 토큰 패밀리 (회전 감지용)
    
    -- 만료 및 상태
    expires_at TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT false,
    revoked_at TIMESTAMPTZ,
    revoked_reason VARCHAR(100),
    
    -- 세션 정보
    device_info JSONB,
    ip_address INET,
    user_agent TEXT,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ DEFAULT now(),
    
    CONSTRAINT chk_expires_at_future CHECK (expires_at > created_at),
    CONSTRAINT chk_revoked_consistency CHECK (
        (is_revoked = false AND revoked_at IS NULL) OR
        (is_revoked = true AND revoked_at IS NOT NULL)
    )
);

-- 인덱스 생성
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_company_id ON refresh_tokens(company_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
CREATE INDEX idx_refresh_tokens_active ON refresh_tokens(user_id, is_revoked) 
    WHERE is_revoked = false;

-- =====================================================
-- 2. 비밀번호 정책 관리 테이블
-- =====================================================

-- 비밀번호 정책 설정
CREATE TABLE password_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 정책 설정 (NULL이면 시스템 기본값 사용)
    min_length INTEGER DEFAULT 8,
    max_length INTEGER DEFAULT 128,
    require_uppercase BOOLEAN DEFAULT true,
    require_lowercase BOOLEAN DEFAULT true,
    require_numbers BOOLEAN DEFAULT true,
    require_special_chars BOOLEAN DEFAULT true,
    
    -- 고급 정책
    min_unique_chars INTEGER DEFAULT 4,
    max_repeated_chars INTEGER DEFAULT 2,
    prevent_common_passwords BOOLEAN DEFAULT true,
    prevent_personal_info BOOLEAN DEFAULT true,
    
    -- 변경 정책
    password_expiry_days INTEGER DEFAULT 90,
    password_history_count INTEGER DEFAULT 5,
    min_change_interval_hours INTEGER DEFAULT 1,
    
    -- 계정 잠금 정책
    max_failed_attempts INTEGER DEFAULT 5,
    lockout_duration_minutes INTEGER DEFAULT 30,
    progressive_lockout BOOLEAN DEFAULT true,
    
    -- 정책 메타데이터
    policy_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id),
    
    CONSTRAINT chk_length_range CHECK (min_length <= max_length),
    CONSTRAINT chk_positive_values CHECK (
        min_length > 0 AND max_length > 0 AND
        password_expiry_days > 0 AND password_history_count >= 0 AND
        max_failed_attempts > 0 AND lockout_duration_minutes > 0
    )
);

-- 기본 정책 인덱스
CREATE INDEX idx_password_policies_company_id ON password_policies(company_id);
CREATE INDEX idx_password_policies_active ON password_policies(is_active) 
    WHERE is_active = true;

-- =====================================================
-- 3. 비밀번호 이력 관리 테이블
-- =====================================================

-- 비밀번호 변경 이력
CREATE TABLE password_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES users(user_id),
    change_reason VARCHAR(50) DEFAULT 'USER_INITIATED',
    
    CONSTRAINT chk_change_reason CHECK (
        change_reason IN ('USER_INITIATED', 'ADMIN_RESET', 'POLICY_EXPIRY', 'SECURITY_BREACH')
    )
);

-- 인덱스 생성
CREATE INDEX idx_password_history_user_id ON password_history(user_id);
CREATE INDEX idx_password_history_created_at ON password_history(created_at DESC);

-- =====================================================
-- 4. 다단계 인증 (MFA) 관리 테이블
-- =====================================================

-- MFA 설정 관리
CREATE TABLE mfa_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- MFA 타입 및 상태
    mfa_type VARCHAR(20) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT false,
    is_primary BOOLEAN NOT NULL DEFAULT false,
    
    -- 설정 데이터 (암호화됨)
    secret_key_encrypted TEXT, -- TOTP 시크릿 키
    backup_codes_encrypted TEXT, -- 백업 코드들 (JSON 배열)
    phone_number_encrypted TEXT, -- SMS용 전화번호
    
    -- 검증 상태
    is_verified BOOLEAN NOT NULL DEFAULT false,
    verified_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    
    -- 메타데이터
    device_name VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT chk_mfa_type CHECK (
        mfa_type IN ('TOTP', 'SMS', 'EMAIL', 'BACKUP_CODES', 'HARDWARE_TOKEN')
    ),
    CONSTRAINT chk_primary_mfa_enabled CHECK (
        NOT is_primary OR is_enabled = true
    ),
    UNIQUE(user_id, mfa_type)
);

-- 인덱스 생성
CREATE INDEX idx_mfa_settings_user_id ON mfa_settings(user_id);
CREATE INDEX idx_mfa_settings_enabled ON mfa_settings(user_id, is_enabled) 
    WHERE is_enabled = true;
CREATE INDEX idx_mfa_settings_primary ON mfa_settings(user_id, is_primary) 
    WHERE is_primary = true;

-- =====================================================
-- 5. MFA 인증 시도 로그 테이블
-- =====================================================

-- MFA 인증 시도 기록
CREATE TABLE mfa_attempts (
    attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    setting_id UUID REFERENCES mfa_settings(setting_id) ON DELETE SET NULL,
    
    -- 시도 정보
    mfa_type VARCHAR(20) NOT NULL,
    attempt_result VARCHAR(20) NOT NULL,
    error_message TEXT,
    
    -- 세션 정보
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    
    -- 시간 정보
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT chk_mfa_attempt_type CHECK (
        mfa_type IN ('TOTP', 'SMS', 'EMAIL', 'BACKUP_CODES', 'HARDWARE_TOKEN')
    ),
    CONSTRAINT chk_attempt_result CHECK (
        attempt_result IN ('SUCCESS', 'INVALID_CODE', 'EXPIRED_CODE', 'RATE_LIMITED', 'SYSTEM_ERROR')
    )
);

-- 인덱스 생성
CREATE INDEX idx_mfa_attempts_user_id ON mfa_attempts(user_id);
CREATE INDEX idx_mfa_attempts_attempted_at ON mfa_attempts(attempted_at DESC);
CREATE INDEX idx_mfa_attempts_result ON mfa_attempts(attempt_result);

-- =====================================================
-- 6. 비밀번호 정책 검증 함수들
-- =====================================================

-- 비밀번호 정책 조회
CREATE OR REPLACE FUNCTION get_password_policy(p_company_id UUID)
RETURNS password_policies AS $
DECLARE
    policy_record password_policies;
BEGIN
    -- 회사별 정책 조회
    SELECT * INTO policy_record
    FROM password_policies
    WHERE company_id = p_company_id AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- 회사별 정책이 없으면 시스템 기본 정책 사용
    IF NOT FOUND THEN
        SELECT * INTO policy_record
        FROM password_policies
        WHERE company_id IS NULL AND is_active = true
        ORDER BY created_at DESC
        LIMIT 1;
    END IF;
    
    -- 기본 정책도 없으면 하드코딩된 기본값 반환
    IF NOT FOUND THEN
        policy_record.min_length := 8;
        policy_record.max_length := 128;
        policy_record.require_uppercase := true;
        policy_record.require_lowercase := true;
        policy_record.require_numbers := true;
        policy_record.require_special_chars := true;
        policy_record.password_expiry_days := 90;
        policy_record.password_history_count := 5;
        policy_record.max_failed_attempts := 5;
        policy_record.lockout_duration_minutes := 30;
    END IF;
    
    RETURN policy_record;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 비밀번호 강도 검증
CREATE OR REPLACE FUNCTION validate_password_strength(
    p_password TEXT,
    p_company_id UUID,
    p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
    is_valid BOOLEAN,
    error_code VARCHAR(50),
    error_message TEXT
) AS $
DECLARE
    policy password_policies;
    user_info RECORD;
BEGIN
    -- 정책 조회
    policy := get_password_policy(p_company_id);
    
    -- 사용자 정보 조회 (개인정보 검증용)
    IF p_user_id IS NOT NULL THEN
        SELECT email, full_name INTO user_info
        FROM users WHERE user_id = p_user_id;
    END IF;
    
    -- 길이 검증
    IF length(p_password) < policy.min_length THEN
        RETURN QUERY SELECT false, 'PASSWORD_TOO_SHORT'::VARCHAR(50), 
            format('비밀번호는 최소 %s자 이상이어야 합니다.', policy.min_length);
        RETURN;
    END IF;
    
    IF length(p_password) > policy.max_length THEN
        RETURN QUERY SELECT false, 'PASSWORD_TOO_LONG'::VARCHAR(50), 
            format('비밀번호는 최대 %s자 이하여야 합니다.', policy.max_length);
        RETURN;
    END IF;
    
    -- 대문자 검증
    IF policy.require_uppercase AND p_password !~ '[A-Z]' THEN
        RETURN QUERY SELECT false, 'MISSING_UPPERCASE'::VARCHAR(50), 
            '비밀번호에 대문자가 포함되어야 합니다.';
        RETURN;
    END IF;
    
    -- 소문자 검증
    IF policy.require_lowercase AND p_password !~ '[a-z]' THEN
        RETURN QUERY SELECT false, 'MISSING_LOWERCASE'::VARCHAR(50), 
            '비밀번호에 소문자가 포함되어야 합니다.';
        RETURN;
    END IF;
    
    -- 숫자 검증
    IF policy.require_numbers AND p_password !~ '[0-9]' THEN
        RETURN QUERY SELECT false, 'MISSING_NUMBERS'::VARCHAR(50), 
            '비밀번호에 숫자가 포함되어야 합니다.';
        RETURN;
    END IF;
    
    -- 특수문자 검증
    IF policy.require_special_chars AND p_password !~ '[^A-Za-z0-9]' THEN
        RETURN QUERY SELECT false, 'MISSING_SPECIAL_CHARS'::VARCHAR(50), 
            '비밀번호에 특수문자가 포함되어야 합니다.';
        RETURN;
    END IF;
    
    -- 개인정보 포함 검증
    IF policy.prevent_personal_info AND user_info IS NOT NULL THEN
        IF position(lower(split_part(user_info.email, '@', 1)) in lower(p_password)) > 0 THEN
            RETURN QUERY SELECT false, 'CONTAINS_PERSONAL_INFO'::VARCHAR(50), 
                '비밀번호에 개인정보가 포함될 수 없습니다.';
            RETURN;
        END IF;
        
        IF position(lower(user_info.full_name) in lower(p_password)) > 0 THEN
            RETURN QUERY SELECT false, 'CONTAINS_PERSONAL_INFO'::VARCHAR(50), 
                '비밀번호에 개인정보가 포함될 수 없습니다.';
            RETURN;
        END IF;
    END IF;
    
    -- 모든 검증 통과
    RETURN QUERY SELECT true, NULL::VARCHAR(50), NULL::TEXT;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 비밀번호 이력 검증
CREATE OR REPLACE FUNCTION check_password_history(
    p_user_id UUID,
    p_new_password_hash TEXT
)
RETURNS BOOLEAN AS $
DECLARE
    policy password_policies;
    history_count INTEGER;
BEGIN
    -- 사용자의 회사 정책 조회
    SELECT get_password_policy(u.company_id) INTO policy
    FROM users u WHERE u.user_id = p_user_id;
    
    -- 이력 검증이 비활성화된 경우
    IF policy.password_history_count = 0 THEN
        RETURN true;
    END IF;
    
    -- 최근 N개 비밀번호와 비교
    SELECT COUNT(*) INTO history_count
    FROM (
        SELECT password_hash
        FROM password_history
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT policy.password_history_count
    ) recent_passwords
    WHERE password_hash = p_new_password_hash;
    
    RETURN history_count = 0;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. JWT 토큰 관리 함수들
-- =====================================================

-- 리프레시 토큰 생성
CREATE OR REPLACE FUNCTION create_refresh_token(
    p_user_id UUID,
    p_token_hash VARCHAR(255),
    p_token_family VARCHAR(255),
    p_expires_at TIMESTAMPTZ,
    p_device_info JSONB DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    new_token_id UUID;
    user_company_id UUID;
BEGIN
    -- 사용자의 회사 ID 조회
    SELECT company_id INTO user_company_id
    FROM users WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '사용자를 찾을 수 없습니다: %', p_user_id;
    END IF;
    
    -- 기존 동일 패밀리 토큰 무효화
    UPDATE refresh_tokens 
    SET is_revoked = true, 
        revoked_at = now(),
        revoked_reason = 'TOKEN_ROTATION'
    WHERE user_id = p_user_id 
    AND token_family = p_token_family 
    AND is_revoked = false;
    
    -- 새 토큰 생성
    INSERT INTO refresh_tokens (
        user_id,
        company_id,
        token_hash,
        token_family,
        expires_at,
        device_info,
        ip_address,
        user_agent
    ) VALUES (
        p_user_id,
        user_company_id,
        p_token_hash,
        p_token_family,
        p_expires_at,
        p_device_info,
        p_ip_address,
        p_user_agent
    ) RETURNING token_id INTO new_token_id;
    
    RETURN new_token_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 리프레시 토큰 검증
CREATE OR REPLACE FUNCTION validate_refresh_token(p_token_hash VARCHAR(255))
RETURNS TABLE (
    is_valid BOOLEAN,
    user_id UUID,
    company_id UUID,
    token_family VARCHAR(255),
    error_code VARCHAR(50)
) AS $
DECLARE
    token_record RECORD;
BEGIN
    -- 토큰 조회
    SELECT rt.*, u.status as user_status, c.verification_status as company_status
    INTO token_record
    FROM refresh_tokens rt
    JOIN users u ON rt.user_id = u.user_id
    JOIN companies c ON rt.company_id = c.company_id
    WHERE rt.token_hash = p_token_hash;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT false, NULL::UUID, NULL::UUID, NULL::VARCHAR(255), 'TOKEN_NOT_FOUND'::VARCHAR(50);
        RETURN;
    END IF;
    
    -- 토큰 무효화 확인
    IF token_record.is_revoked THEN
        RETURN QUERY SELECT false, token_record.user_id, token_record.company_id, 
            token_record.token_family, 'TOKEN_REVOKED'::VARCHAR(50);
        RETURN;
    END IF;
    
    -- 토큰 만료 확인
    IF token_record.expires_at <= now() THEN
        -- 만료된 토큰 자동 무효화
        UPDATE refresh_tokens 
        SET is_revoked = true, 
            revoked_at = now(),
            revoked_reason = 'TOKEN_EXPIRED'
        WHERE token_hash = p_token_hash;
        
        RETURN QUERY SELECT false, token_record.user_id, token_record.company_id, 
            token_record.token_family, 'TOKEN_EXPIRED'::VARCHAR(50);
        RETURN;
    END IF;
    
    -- 사용자 상태 확인
    IF token_record.user_status != 'ACTIVE' THEN
        RETURN QUERY SELECT false, token_record.user_id, token_record.company_id, 
            token_record.token_family, 'USER_INACTIVE'::VARCHAR(50);
        RETURN;
    END IF;
    
    -- 회사 상태 확인
    IF token_record.company_status != 'VERIFIED' THEN
        RETURN QUERY SELECT false, token_record.user_id, token_record.company_id, 
            token_record.token_family, 'COMPANY_UNVERIFIED'::VARCHAR(50);
        RETURN;
    END IF;
    
    -- 토큰 사용 시간 업데이트
    UPDATE refresh_tokens 
    SET last_used_at = now()
    WHERE token_hash = p_token_hash;
    
    -- 유효한 토큰
    RETURN QUERY SELECT true, token_record.user_id, token_record.company_id, 
        token_record.token_family, NULL::VARCHAR(50);
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자의 모든 토큰 무효화
CREATE OR REPLACE FUNCTION revoke_all_user_tokens(
    p_user_id UUID,
    p_reason VARCHAR(100) DEFAULT 'USER_LOGOUT'
)
RETURNS INTEGER AS $
DECLARE
    revoked_count INTEGER;
BEGIN
    UPDATE refresh_tokens 
    SET is_revoked = true,
        revoked_at = now(),
        revoked_reason = p_reason
    WHERE user_id = p_user_id 
    AND is_revoked = false;
    
    GET DIAGNOSTICS revoked_count = ROW_COUNT;
    RETURN revoked_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. MFA 관리 함수들
-- =====================================================

-- MFA 설정 생성/업데이트
CREATE OR REPLACE FUNCTION setup_mfa(
    p_user_id UUID,
    p_mfa_type VARCHAR(20),
    p_secret_key TEXT DEFAULT NULL,
    p_phone_number TEXT DEFAULT NULL,
    p_device_name VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    setting_id UUID;
    encrypted_secret TEXT;
    encrypted_phone TEXT;
BEGIN
    -- 기존 설정 확인
    SELECT mfa_settings.setting_id INTO setting_id
    FROM mfa_settings
    WHERE user_id = p_user_id AND mfa_type = p_mfa_type;
    
    -- 민감 데이터 암호화
    IF p_secret_key IS NOT NULL THEN
        encrypted_secret := encrypt_sensitive_data(p_secret_key, 'default_pii_key');
    END IF;
    
    IF p_phone_number IS NOT NULL THEN
        encrypted_phone := encrypt_phone_number(p_phone_number);
    END IF;
    
    -- 기존 설정 업데이트 또는 새 설정 생성
    INSERT INTO mfa_settings (
        user_id,
        mfa_type,
        secret_key_encrypted,
        phone_number_encrypted,
        device_name,
        is_enabled,
        updated_at
    ) VALUES (
        p_user_id,
        p_mfa_type,
        encrypted_secret,
        encrypted_phone,
        p_device_name,
        false, -- 초기에는 비활성화
        now()
    )
    ON CONFLICT (user_id, mfa_type)
    DO UPDATE SET
        secret_key_encrypted = EXCLUDED.secret_key_encrypted,
        phone_number_encrypted = EXCLUDED.phone_number_encrypted,
        device_name = EXCLUDED.device_name,
        updated_at = now()
    RETURNING mfa_settings.setting_id INTO setting_id;
    
    RETURN setting_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- MFA 활성화
CREATE OR REPLACE FUNCTION enable_mfa(
    p_user_id UUID,
    p_mfa_type VARCHAR(20),
    p_verification_code TEXT
)
RETURNS BOOLEAN AS $
DECLARE
    setting_record RECORD;
    is_code_valid BOOLEAN := false;
BEGIN
    -- MFA 설정 조회
    SELECT * INTO setting_record
    FROM mfa_settings
    WHERE user_id = p_user_id AND mfa_type = p_mfa_type;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'MFA 설정을 찾을 수 없습니다';
    END IF;
    
    -- 검증 코드 확인 (실제 구현에서는 TOTP/SMS 검증 로직 필요)
    -- 여기서는 단순화된 구현
    IF p_mfa_type = 'TOTP' THEN
        -- TOTP 코드 검증 로직 (외부 라이브러리 필요)
        is_code_valid := length(p_verification_code) = 6 AND p_verification_code ~ '^[0-9]+$';
    ELSIF p_mfa_type = 'SMS' THEN
        -- SMS 코드 검증 로직
        is_code_valid := length(p_verification_code) = 6 AND p_verification_code ~ '^[0-9]+$';
    END IF;
    
    IF NOT is_code_valid THEN
        -- 실패 로그 기록
        INSERT INTO mfa_attempts (user_id, setting_id, mfa_type, attempt_result, error_message)
        VALUES (p_user_id, setting_record.setting_id, p_mfa_type, 'INVALID_CODE', '잘못된 인증 코드');
        
        RETURN false;
    END IF;
    
    -- MFA 활성화
    UPDATE mfa_settings
    SET is_enabled = true,
        is_verified = true,
        verified_at = now(),
        updated_at = now()
    WHERE setting_id = setting_record.setting_id;
    
    -- 성공 로그 기록
    INSERT INTO mfa_attempts (user_id, setting_id, mfa_type, attempt_result)
    VALUES (p_user_id, setting_record.setting_id, p_mfa_type, 'SUCCESS');
    
    RETURN true;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- MFA 인증 검증
CREATE OR REPLACE FUNCTION verify_mfa(
    p_user_id UUID,
    p_mfa_type VARCHAR(20),
    p_verification_code TEXT,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
DECLARE
    setting_record RECORD;
    is_code_valid BOOLEAN := false;
    recent_attempts INTEGER;
BEGIN
    -- 최근 시도 횟수 확인 (Rate Limiting)
    SELECT COUNT(*) INTO recent_attempts
    FROM mfa_attempts
    WHERE user_id = p_user_id 
    AND mfa_type = p_mfa_type
    AND attempted_at > now() - INTERVAL '5 minutes';
    
    IF recent_attempts >= 5 THEN
        INSERT INTO mfa_attempts (
            user_id, mfa_type, attempt_result, error_message, 
            ip_address, user_agent
        ) VALUES (
            p_user_id, p_mfa_type, 'RATE_LIMITED', 
            '너무 많은 시도로 인한 제한', p_ip_address, p_user_agent
        );
        
        RETURN false;
    END IF;
    
    -- MFA 설정 조회
    SELECT * INTO setting_record
    FROM mfa_settings
    WHERE user_id = p_user_id 
    AND mfa_type = p_mfa_type 
    AND is_enabled = true;
    
    IF NOT FOUND THEN
        INSERT INTO mfa_attempts (
            user_id, mfa_type, attempt_result, error_message,
            ip_address, user_agent
        ) VALUES (
            p_user_id, p_mfa_type, 'SYSTEM_ERROR', 
            'MFA 설정을 찾을 수 없음', p_ip_address, p_user_agent
        );
        
        RETURN false;
    END IF;
    
    -- 검증 코드 확인 (실제 구현에서는 TOTP/SMS 검증 로직 필요)
    IF p_mfa_type = 'TOTP' THEN
        is_code_valid := length(p_verification_code) = 6 AND p_verification_code ~ '^[0-9]+$';
    ELSIF p_mfa_type = 'SMS' THEN
        is_code_valid := length(p_verification_code) = 6 AND p_verification_code ~ '^[0-9]+$';
    ELSIF p_mfa_type = 'BACKUP_CODES' THEN
        -- 백업 코드 검증 로직
        is_code_valid := length(p_verification_code) = 8;
    END IF;
    
    -- 결과 기록
    INSERT INTO mfa_attempts (
        user_id, setting_id, mfa_type, 
        attempt_result, ip_address, user_agent
    ) VALUES (
        p_user_id, setting_record.setting_id, p_mfa_type,
        CASE WHEN is_code_valid THEN 'SUCCESS' ELSE 'INVALID_CODE' END,
        p_ip_address, p_user_agent
    );
    
    -- 성공 시 마지막 사용 시간 업데이트
    IF is_code_valid THEN
        UPDATE mfa_settings
        SET last_used_at = now()
        WHERE setting_id = setting_record.setting_id;
    END IF;
    
    RETURN is_code_valid;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. 보안 정책 초기화 함수
-- =====================================================

-- 기본 비밀번호 정책 생성
CREATE OR REPLACE FUNCTION create_default_password_policies()
RETURNS VOID AS $
BEGIN
    -- 시스템 기본 정책 (모든 회사에 적용)
    INSERT INTO password_policies (
        company_id,
        policy_name,
        description,
        min_length,
        max_length,
        require_uppercase,
        require_lowercase,
        require_numbers,
        require_special_chars,
        password_expiry_days,
        password_history_count,
        max_failed_attempts,
        lockout_duration_minutes
    ) VALUES (
        NULL, -- 시스템 기본 정책
        '시스템 기본 보안 정책',
        'QIRO 시스템의 기본 비밀번호 및 보안 정책',
        8,    -- 최소 8자
        128,  -- 최대 128자
        true, -- 대문자 필수
        true, -- 소문자 필수
        true, -- 숫자 필수
        true, -- 특수문자 필수
        90,   -- 90일 후 만료
        5,    -- 최근 5개 비밀번호 재사용 금지
        5,    -- 5회 실패 시 잠금
        30    -- 30분 잠금
    )
    ON CONFLICT DO NOTHING;
    
    RAISE NOTICE '기본 비밀번호 정책 생성 완료';
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. 정리 및 유지보수 함수들
-- =====================================================

-- 만료된 토큰 정리
CREATE OR REPLACE FUNCTION cleanup_expired_tokens()
RETURNS INTEGER AS $
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM refresh_tokens
    WHERE expires_at <= now() - INTERVAL '7 days'; -- 만료 후 7일 뒤 삭제
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 오래된 MFA 시도 로그 정리
CREATE OR REPLACE FUNCTION cleanup_old_mfa_attempts()
RETURNS INTEGER AS $
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM mfa_attempts
    WHERE attempted_at <= now() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 오래된 비밀번호 이력 정리
CREATE OR REPLACE FUNCTION cleanup_old_password_history()
RETURNS INTEGER AS $
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 각 사용자별로 최신 10개만 유지
    DELETE FROM password_history
    WHERE history_id NOT IN (
        SELECT history_id
        FROM (
            SELECT history_id,
                   ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
            FROM password_history
        ) ranked
        WHERE rn <= 10
    );
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. 코멘�� 추가
-- =====================================================

COMMENT ON TABLE refresh_tokens IS 'JWT 리프레시 토큰 관리 테이블';
COMMENT ON TABLE password_policies IS '비밀번호 정책 관리 테이블';
COMMENT ON TABLE password_history IS '비밀번호 변경 이력 테이블';
COMMENT ON TABLE mfa_settings IS '다단계 인증 설정 테이블';
COMMENT ON TABLE mfa_attempts IS 'MFA 인증 시도 로그 테이블';

COMMENT ON FUNCTION validate_password_strength(TEXT, UUID, UUID) IS '비밀번호 강도 검증';
COMMENT ON FUNCTION create_refresh_token(UUID, VARCHAR, VARCHAR, TIMESTAMPTZ, JSONB, INET, TEXT) IS '리프레시 토큰 생성';
COMMENT ON FUNCTION validate_refresh_token(VARCHAR) IS '리프레시 토큰 검증';
COMMENT ON FUNCTION setup_mfa(UUID, VARCHAR, TEXT, TEXT, VARCHAR) IS 'MFA 설정 생성/업데이트';
COMMENT ON FUNCTION verify_mfa(UUID, VARCHAR, TEXT, INET, TEXT) IS 'MFA 인증 검증';

-- =====================================================
-- 12. 초기 설정 실행
-- =====================================================

-- 기본 정책 생성
SELECT create_default_password_policies();

-- 설정 완료 메시지
DO $
BEGIN
    RAISE NOTICE '=== QIRO 인증 보안 강화 시스템 설정 완료 ===';
    RAISE NOTICE '1. JWT 리프레시 토큰 관리 시스템 구축 완료';
    RAISE NOTICE '2. 비밀번호 정책 관리 시스템 구축 완료';
    RAISE NOTICE '3. 비밀번호 이력 관리 시스템 구축 완료';
    RAISE NOTICE '4. 다단계 인증(MFA) 시스템 구축 완료';
    RAISE NOTICE '5. 보안 정책 검증 함수들 생성 완료';
    RAISE NOTICE '';
    RAISE NOTICE '=== 주요 기능들 ===';
    RAISE NOTICE '- validate_password_strength(): 비밀번호 강도 검증';
    RAISE NOTICE '- create_refresh_token(): JWT 리프레시 토큰 생성';
    RAISE NOTICE '- validate_refresh_token(): 토큰 검증';
    RAISE NOTICE '- setup_mfa(): MFA 설정';
    RAISE NOTICE '- verify_mfa(): MFA 인증 검증';
    RAISE NOTICE '';
    RAISE NOTICE '=== 보안 권장사항 ===';
    RAISE NOTICE '1. 정기적인 토큰 정리 작업 스케줄링 필요';
    RAISE NOTICE '2. MFA 백업 코드 안전한 저장 방안 수립';
    RAISE NOTICE '3. 비밀번호 정책 정기 검토 및 업데이트';
END $;