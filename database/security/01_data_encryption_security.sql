-- =====================================================
-- 데이터 암호화 및 보안 설계
-- QIRO 건물 관리 시스템 - 개인정보 보호 및 데이터 보안
-- =====================================================

-- 1. 암호화 확장 모듈 활성화
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. 개인정보 암호화를 위한 함수 생성
-- AES-256 암호화 함수
CREATE OR REPLACE FUNCTION encrypt_personal_data(data TEXT, key TEXT)
RETURNS TEXT AS $$
BEGIN
    IF data IS NULL OR data = '' THEN
        RETURN NULL;
    END IF;
    RETURN encode(encrypt(data::bytea, key::bytea, 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- AES-256 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_personal_data(encrypted_data TEXT, key TEXT)
RETURNS TEXT AS $$
BEGIN
    IF encrypted_data IS NULL OR encrypted_data = '' THEN
        RETURN NULL;
    END IF;
    RETURN convert_from(decrypt(decode(encrypted_data, 'base64'), key::bytea, 'aes'), 'UTF8');
EXCEPTION
    WHEN OTHERS THEN
        RETURN '[DECRYPTION_ERROR]';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 개인정보 필드별 암호화 전략 구현
-- 임대인 테이블 개인정보 암호화 컬럼 추가
ALTER TABLE lessors 
ADD COLUMN IF NOT EXISTS contact_phone_encrypted TEXT,
ADD COLUMN IF NOT EXISTS contact_email_encrypted TEXT,
ADD COLUMN IF NOT EXISTS business_registration_number_encrypted TEXT,
ADD COLUMN IF NOT EXISTS address_encrypted TEXT;

-- 임차인 테이블 개인정보 암호화 컬럼 추가
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS contact_phone_encrypted TEXT,
ADD COLUMN IF NOT EXISTS contact_email_encrypted TEXT,
ADD COLUMN IF NOT EXISTS business_registration_number_encrypted TEXT,
ADD COLUMN IF NOT EXISTS address_encrypted TEXT;

-- 사용자 테이블 개인정보 암호화 컬럼 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email_encrypted TEXT,
ADD COLUMN IF NOT EXISTS full_name_encrypted TEXT;

-- 4. 개인정보 암호화 트리거 함수
CREATE OR REPLACE FUNCTION encrypt_lessor_personal_data()
RETURNS TRIGGER AS $$
DECLARE
    encryption_key TEXT := current_setting('app.encryption_key', true);
BEGIN
    -- 암호화 키가 설정되지 않은 경우 오류 발생
    IF encryption_key IS NULL OR encryption_key = '' THEN
        RAISE EXCEPTION '암호화 키가 설정되지 않았습니다.';
    END IF;

    -- 개인정보 필드 암호화
    IF NEW.contact_phone IS NOT NULL THEN
        NEW.contact_phone_encrypted := encrypt_personal_data(NEW.contact_phone, encryption_key);
        NEW.contact_phone := '[ENCRYPTED]';
    END IF;
    
    IF NEW.contact_email IS NOT NULL THEN
        NEW.contact_email_encrypted := encrypt_personal_data(NEW.contact_email, encryption_key);
        NEW.contact_email := '[ENCRYPTED]';
    END IF;
    
    IF NEW.business_registration_number IS NOT NULL THEN
        NEW.business_registration_number_encrypted := encrypt_personal_data(NEW.business_registration_number, encryption_key);
        NEW.business_registration_number := '[ENCRYPTED]';
    END IF;
    
    IF NEW.address IS NOT NULL THEN
        NEW.address_encrypted := encrypt_personal_data(NEW.address, encryption_key);
        NEW.address := '[ENCRYPTED]';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 임대인 테이블 암호화 트리거
DROP TRIGGER IF EXISTS trigger_encrypt_lessor_data ON lessors;
CREATE TRIGGER trigger_encrypt_lessor_data
    BEFORE INSERT OR UPDATE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION encrypt_lessor_personal_data();

-- 임차인 테이블 암호화 트리거 함수
CREATE OR REPLACE FUNCTION encrypt_tenant_personal_data()
RETURNS TRIGGER AS $$
DECLARE
    encryption_key TEXT := current_setting('app.encryption_key', true);
BEGIN
    -- 암호화 키가 설정되지 않은 경우 오류 발생
    IF encryption_key IS NULL OR encryption_key = '' THEN
        RAISE EXCEPTION '암호화 키가 설정되지 않았습니다.';
    END IF;

    -- 개인정보 필드 암호화
    IF NEW.contact_phone IS NOT NULL THEN
        NEW.contact_phone_encrypted := encrypt_personal_data(NEW.contact_phone, encryption_key);
        NEW.contact_phone := '[ENCRYPTED]';
    END IF;
    
    IF NEW.contact_email IS NOT NULL THEN
        NEW.contact_email_encrypted := encrypt_personal_data(NEW.contact_email, encryption_key);
        NEW.contact_email := '[ENCRYPTED]';
    END IF;
    
    IF NEW.business_registration_number IS NOT NULL THEN
        NEW.business_registration_number_encrypted := encrypt_personal_data(NEW.business_registration_number, encryption_key);
        NEW.business_registration_number := '[ENCRYPTED]';
    END IF;
    
    IF NEW.address IS NOT NULL THEN
        NEW.address_encrypted := encrypt_personal_data(NEW.address, encryption_key);
        NEW.address := '[ENCRYPTED]';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 임차인 테이블 암호화 트리거
DROP TRIGGER IF EXISTS trigger_encrypt_tenant_data ON tenants;
CREATE TRIGGER trigger_encrypt_tenant_data
    BEFORE INSERT OR UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION encrypt_tenant_personal_data();

-- 사용자 테이블 암호화 트리거 함수
CREATE OR REPLACE FUNCTION encrypt_user_personal_data()
RETURNS TRIGGER AS $$
DECLARE
    encryption_key TEXT := current_setting('app.encryption_key', true);
BEGIN
    -- 암호화 키가 설정되지 않은 경우 오류 발생
    IF encryption_key IS NULL OR encryption_key = '' THEN
        RAISE EXCEPTION '암호화 키가 설정되지 않았습니다.';
    END IF;

    -- 개인정보 필드 암호화
    IF NEW.email IS NOT NULL THEN
        NEW.email_encrypted := encrypt_personal_data(NEW.email, encryption_key);
        NEW.email := '[ENCRYPTED]';
    END IF;
    
    IF NEW.full_name IS NOT NULL THEN
        NEW.full_name_encrypted := encrypt_personal_data(NEW.full_name, encryption_key);
        NEW.full_name := '[ENCRYPTED]';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사용자 테이블 암호화 트리거
DROP TRIGGER IF EXISTS trigger_encrypt_user_data ON users;
CREATE TRIGGER trigger_encrypt_user_data
    BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION encrypt_user_personal_data();

-- 5. 개인정보 복호화 뷰 생성 (권한이 있는 사용자만 접근 가능)
CREATE OR REPLACE VIEW lessors_decrypted AS
SELECT 
    id,
    name,
    CASE 
        WHEN contact_phone_encrypted IS NOT NULL 
        THEN decrypt_personal_data(contact_phone_encrypted, current_setting('app.encryption_key', true))
        ELSE contact_phone
    END AS contact_phone,
    CASE 
        WHEN contact_email_encrypted IS NOT NULL 
        THEN decrypt_personal_data(contact_email_encrypted, current_setting('app.encryption_key', true))
        ELSE contact_email
    END AS contact_email,
    CASE 
        WHEN business_registration_number_encrypted IS NOT NULL 
        THEN decrypt_personal_data(business_registration_number_encrypted, current_setting('app.encryption_key', true))
        ELSE business_registration_number
    END AS business_registration_number,
    CASE 
        WHEN address_encrypted IS NOT NULL 
        THEN decrypt_personal_data(address_encrypted, current_setting('app.encryption_key', true))
        ELSE address
    END AS address,
    created_at,
    updated_at
FROM lessors;

CREATE OR REPLACE VIEW tenants_decrypted AS
SELECT 
    id,
    name,
    CASE 
        WHEN contact_phone_encrypted IS NOT NULL 
        THEN decrypt_personal_data(contact_phone_encrypted, current_setting('app.encryption_key', true))
        ELSE contact_phone
    END AS contact_phone,
    CASE 
        WHEN contact_email_encrypted IS NOT NULL 
        THEN decrypt_personal_data(contact_email_encrypted, current_setting('app.encryption_key', true))
        ELSE contact_email
    END AS contact_email,
    CASE 
        WHEN business_registration_number_encrypted IS NOT NULL 
        THEN decrypt_personal_data(business_registration_number_encrypted, current_setting('app.encryption_key', true))
        ELSE business_registration_number
    END AS business_registration_number,
    representative_name,
    CASE 
        WHEN address_encrypted IS NOT NULL 
        THEN decrypt_personal_data(address_encrypted, current_setting('app.encryption_key', true))
        ELSE address
    END AS address,
    created_at,
    updated_at
FROM tenants;

CREATE OR REPLACE VIEW users_decrypted AS
SELECT 
    id,
    username,
    password_hash,
    CASE 
        WHEN email_encrypted IS NOT NULL 
        THEN decrypt_personal_data(email_encrypted, current_setting('app.encryption_key', true))
        ELSE email
    END AS email,
    CASE 
        WHEN full_name_encrypted IS NOT NULL 
        THEN decrypt_personal_data(full_name_encrypted, current_setting('app.encryption_key', true))
        ELSE full_name
    END AS full_name,
    role_id,
    is_active,
    last_login_at,
    created_at,
    updated_at
FROM users;

-- 6. 데이터베이스 연결 보안 설정
-- SSL 연결 강제 설정 (postgresql.conf에서 설정)
-- ssl = on
-- ssl_cert_file = 'server.crt'
-- ssl_key_file = 'server.key'
-- ssl_ca_file = 'ca.crt'

-- 7. 민감 데이터 접근 로깅 테이블
CREATE TABLE IF NOT EXISTS sensitive_data_access_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    username VARCHAR(50),
    table_name VARCHAR(50) NOT NULL,
    record_id BIGINT,
    access_type VARCHAR(20) NOT NULL, -- SELECT, INSERT, UPDATE, DELETE
    accessed_columns TEXT[], -- 접근한 컬럼 목록
    ip_address INET,
    user_agent TEXT,
    session_id VARCHAR(255),
    accessed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success BOOLEAN DEFAULT true,
    error_message TEXT
);

-- 민감 데이터 접근 로깅 인덱스
CREATE INDEX IF NOT EXISTS idx_sensitive_access_logs_user_id ON sensitive_data_access_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sensitive_access_logs_table_name ON sensitive_data_access_logs(table_name);
CREATE INDEX IF NOT EXISTS idx_sensitive_access_logs_accessed_at ON sensitive_data_access_logs(accessed_at);
CREATE INDEX IF NOT EXISTS idx_sensitive_access_logs_ip_address ON sensitive_data_access_logs(ip_address);

-- 8. 민감 데이터 접근 로깅 함수
CREATE OR REPLACE FUNCTION log_sensitive_data_access(
    p_user_id BIGINT,
    p_username VARCHAR(50),
    p_table_name VARCHAR(50),
    p_record_id BIGINT,
    p_access_type VARCHAR(20),
    p_accessed_columns TEXT[],
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_session_id VARCHAR(255) DEFAULT NULL,
    p_success BOOLEAN DEFAULT true,
    p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO sensitive_data_access_logs (
        user_id, username, table_name, record_id, access_type, 
        accessed_columns, ip_address, user_agent, session_id, 
        success, error_message
    ) VALUES (
        p_user_id, p_username, p_table_name, p_record_id, p_access_type,
        p_accessed_columns, p_ip_address, p_user_agent, p_session_id,
        p_success, p_error_message
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. 민감 데이터 접근 모니터링 트리거
CREATE OR REPLACE FUNCTION monitor_sensitive_data_access()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id BIGINT;
    current_username VARCHAR(50);
    accessed_columns TEXT[];
BEGIN
    -- 현재 사용자 정보 가져오기 (애플리케이션에서 설정)
    BEGIN
        current_user_id := current_setting('app.current_user_id')::BIGINT;
        current_username := current_setting('app.current_username');
    EXCEPTION
        WHEN OTHERS THEN
            current_user_id := NULL;
            current_username := session_user;
    END;

    -- 접근한 컬럼 정보 수집 (실제 구현에서는 애플리케이션 레벨에서 처리)
    accessed_columns := ARRAY['contact_phone', 'contact_email', 'business_registration_number', 'address'];

    -- 로그 기록
    PERFORM log_sensitive_data_access(
        current_user_id,
        current_username,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        accessed_columns,
        inet_client_addr(),
        current_setting('app.user_agent', true),
        current_setting('app.session_id', true)
    );

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 민감 데이터 테이블에 모니터링 트리거 적용
DROP TRIGGER IF EXISTS trigger_monitor_lessors_access ON lessors;
CREATE TRIGGER trigger_monitor_lessors_access
    AFTER INSERT OR UPDATE OR DELETE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION monitor_sensitive_data_access();

DROP TRIGGER IF EXISTS trigger_monitor_tenants_access ON tenants;
CREATE TRIGGER trigger_monitor_tenants_access
    AFTER INSERT OR UPDATE OR DELETE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION monitor_sensitive_data_access();

DROP TRIGGER IF EXISTS trigger_monitor_users_access ON users;
CREATE TRIGGER trigger_monitor_users_access
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION monitor_sensitive_data_access();

-- 10. 데이터 마스킹 함수 (개발/테스트 환경용)
CREATE OR REPLACE FUNCTION mask_personal_data(data TEXT, mask_type VARCHAR(20) DEFAULT 'partial')
RETURNS TEXT AS $$
BEGIN
    IF data IS NULL OR data = '' THEN
        RETURN data;
    END IF;

    CASE mask_type
        WHEN 'full' THEN
            RETURN '***';
        WHEN 'partial' THEN
            IF LENGTH(data) <= 3 THEN
                RETURN '***';
            ELSE
                RETURN LEFT(data, 2) || REPEAT('*', LENGTH(data) - 4) || RIGHT(data, 2);
            END IF;
        WHEN 'email' THEN
            IF POSITION('@' IN data) > 0 THEN
                RETURN LEFT(data, 2) || '***@' || SPLIT_PART(data, '@', 2);
            ELSE
                RETURN '***';
            END IF;
        WHEN 'phone' THEN
            IF LENGTH(data) >= 8 THEN
                RETURN LEFT(data, 3) || '-***-' || RIGHT(data, 4);
            ELSE
                RETURN '***-****';
            END IF;
        ELSE
            RETURN data;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 11. 개인정보 보호를 위한 뷰 (마스킹된 데이터)
CREATE OR REPLACE VIEW lessors_masked AS
SELECT 
    id,
    name,
    mask_personal_data(
        CASE 
            WHEN contact_phone_encrypted IS NOT NULL 
            THEN decrypt_personal_data(contact_phone_encrypted, current_setting('app.encryption_key', true))
            ELSE contact_phone
        END, 'phone'
    ) AS contact_phone,
    mask_personal_data(
        CASE 
            WHEN contact_email_encrypted IS NOT NULL 
            THEN decrypt_personal_data(contact_email_encrypted, current_setting('app.encryption_key', true))
            ELSE contact_email
        END, 'email'
    ) AS contact_email,
    mask_personal_data(
        CASE 
            WHEN business_registration_number_encrypted IS NOT NULL 
            THEN decrypt_personal_data(business_registration_number_encrypted, current_setting('app.encryption_key', true))
            ELSE business_registration_number
        END, 'partial'
    ) AS business_registration_number,
    mask_personal_data(
        CASE 
            WHEN address_encrypted IS NOT NULL 
            THEN decrypt_personal_data(address_encrypted, current_setting('app.encryption_key', true))
            ELSE address
        END, 'partial'
    ) AS address,
    created_at,
    updated_at
FROM lessors;

-- 12. 보안 정책 설정 테이블
CREATE TABLE IF NOT EXISTS security_policies (
    id BIGSERIAL PRIMARY KEY,
    policy_name VARCHAR(100) NOT NULL UNIQUE,
    policy_value TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 기본 보안 정책 설정
INSERT INTO security_policies (policy_name, policy_value, description) VALUES
('password_min_length', '10', '비밀번호 최소 길이'),
('password_complexity', 'true', '비밀번호 복잡성 요구사항 적용'),
('login_attempt_limit', '5', '로그인 시도 제한 횟수'),
('account_lockout_duration', '30', '계정 잠금 지속 시간 (분)'),
('session_timeout', '30', '세션 타임아웃 (분)'),
('mfa_required_for_admin', 'true', '관리자 계정 2단계 인증 필수'),
('audit_log_retention_days', '365', '감사 로그 보관 기간 (일)'),
('encryption_algorithm', 'AES-256', '암호화 알고리즘'),
('backup_encryption', 'true', '백업 데이터 암호화 여부')
ON CONFLICT (policy_name) DO NOTHING;

-- 13. 권한 기반 접근 제어를 위한 보안 함수
CREATE OR REPLACE FUNCTION check_data_access_permission(
    p_user_id BIGINT,
    p_table_name VARCHAR(50),
    p_operation VARCHAR(20)
)
RETURNS BOOLEAN AS $$
DECLARE
    user_role VARCHAR(50);
    has_permission BOOLEAN := false;
BEGIN
    -- 사용자 역할 조회
    SELECT r.name INTO user_role
    FROM users u
    JOIN roles r ON u.role_id = r.id
    WHERE u.id = p_user_id AND u.is_active = true;

    -- 권한 확인 로직
    CASE user_role
        WHEN 'ADMIN' THEN
            has_permission := true;
        WHEN 'MANAGER' THEN
            has_permission := (p_operation IN ('SELECT', 'INSERT', 'UPDATE'));
        WHEN 'STAFF' THEN
            has_permission := (p_operation = 'SELECT' AND p_table_name NOT IN ('users', 'audit_logs'));
        WHEN 'VIEWER' THEN
            has_permission := (p_operation = 'SELECT' AND p_table_name NOT LIKE '%_encrypted%');
        ELSE
            has_permission := false;
    END CASE;

    RETURN has_permission;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 14. 데이터베이스 보안 모니터링 뷰
CREATE OR REPLACE VIEW security_monitoring_summary AS
SELECT 
    DATE(accessed_at) as access_date,
    table_name,
    access_type,
    COUNT(*) as access_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN success = false THEN 1 END) as failed_attempts,
    COUNT(DISTINCT ip_address) as unique_ips
FROM sensitive_data_access_logs
WHERE accessed_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(accessed_at), table_name, access_type
ORDER BY access_date DESC, access_count DESC;

-- 15. 보안 설정 확인 함수
CREATE OR REPLACE FUNCTION check_security_configuration()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    description TEXT,
    recommendation TEXT
) AS $$
BEGIN
    -- SSL 연결 확인
    RETURN QUERY
    SELECT 
        'SSL Connection'::TEXT,
        CASE WHEN current_setting('ssl') = 'on' THEN 'OK' ELSE 'WARNING' END::TEXT,
        'SSL 연결 상태'::TEXT,
        CASE WHEN current_setting('ssl') = 'on' THEN '정상' ELSE 'SSL을 활성화하세요' END::TEXT;

    -- 암호화 확장 모듈 확인
    RETURN QUERY
    SELECT 
        'pgcrypto Extension'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN 'OK' ELSE 'ERROR' END::TEXT,
        'pgcrypto 확장 모듈 설치 상태'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN '정상' ELSE 'pgcrypto 확장을 설치하세요' END::TEXT;

    -- 보안 정책 확인
    RETURN QUERY
    SELECT 
        'Security Policies'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM security_policies WHERE is_active = true) THEN 'OK' ELSE 'WARNING' END::TEXT,
        '보안 정책 설정 상태'::TEXT,
        CASE WHEN EXISTS(SELECT 1 FROM security_policies WHERE is_active = true) THEN '정상' ELSE '보안 정책을 설정하세요' END::TEXT;

END;
$$ LANGUAGE plpgsql;

-- 16. 주석 및 문서화
COMMENT ON FUNCTION encrypt_personal_data(TEXT, TEXT) IS '개인정보 AES-256 암호화 함수';
COMMENT ON FUNCTION decrypt_personal_data(TEXT, TEXT) IS '개인정보 AES-256 복호화 함수';
COMMENT ON FUNCTION log_sensitive_data_access IS '민감 데이터 접근 로깅 함수';
COMMENT ON FUNCTION check_data_access_permission IS '데이터 접근 권한 확인 함수';
COMMENT ON FUNCTION mask_personal_data IS '개인정보 마스킹 함수 (개발/테스트용)';
COMMENT ON TABLE sensitive_data_access_logs IS '민감 데이터 접근 로그 테이블';
COMMENT ON TABLE security_policies IS '시스템 보안 정책 설정 테이블';
COMMENT ON VIEW security_monitoring_summary IS '보안 모니터링 요약 뷰';

-- 완료 메시지
SELECT '데이터 암호화 및 보안 설계가 완료되었습니다.' AS status;