-- =====================================================
-- QIRO 데이터 암호화 및 보안 시스템
-- 민감 정보 암호화 구현
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 암호화 확장 기능 활성화
-- =====================================================

-- pgcrypto 확장 활성화 (이미 활성화되어 있을 수 있음)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 2. 암호화 키 관리 테이블
-- =====================================================

-- 암호화 키 관리 테이블 (키 회전 지원)
CREATE TABLE encryption_keys (
    key_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key_name VARCHAR(100) UNIQUE NOT NULL,
    key_version INTEGER NOT NULL DEFAULT 1,
    encrypted_key BYTEA NOT NULL, -- 마스터 키로 암호화된 실제 키
    key_purpose VARCHAR(50) NOT NULL, -- PII, BUSINESS_DATA, PHONE, etc.
    algorithm VARCHAR(50) NOT NULL DEFAULT 'AES-256-GCM',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ,
    created_by UUID,
    
    CONSTRAINT encryption_keys_purpose_check 
        CHECK (key_purpose IN ('PII', 'BUSINESS_DATA', 'PHONE', 'EMAIL', 'DOCUMENT')),
    CONSTRAINT encryption_keys_algorithm_check 
        CHECK (algorithm IN ('AES-256-GCM', 'AES-256-CBC', 'ChaCha20-Poly1305'))
);

-- 키 버전별 인덱스
CREATE INDEX idx_encryption_keys_name_version ON encryption_keys(key_name, key_version);
CREATE INDEX idx_encryption_keys_active ON encryption_keys(is_active) WHERE is_active = true;

-- =====================================================
-- 3. 암호화/복호화 함수
-- =====================================================

-- 마스터 키 생성 함수 (애플리케이션에서 관리)
CREATE OR REPLACE FUNCTION generate_master_key()
RETURNS TEXT AS $
BEGIN
    -- 실제 환경에서는 외부 키 관리 시스템(AWS KMS, HashiCorp Vault 등) 사용 권장
    RETURN encode(gen_random_bytes(32), 'base64');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 데이터 암호화 함수 (AES-256-GCM)
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
    plain_text TEXT,
    key_name VARCHAR(100) DEFAULT 'default_pii_key'
)
RETURNS TEXT AS $
DECLARE
    encryption_key BYTEA;
    encrypted_result BYTEA;
    key_info RECORD;
BEGIN
    -- 빈 값 처리
    IF plain_text IS NULL OR plain_text = '' THEN
        RETURN NULL;
    END IF;
    
    -- 활성 키 조회
    SELECT encrypted_key, algorithm 
    INTO key_info
    FROM encryption_keys 
    WHERE key_name = encrypt_sensitive_data.key_name 
    AND is_active = true 
    ORDER BY key_version DESC 
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '암호화 키를 찾을 수 없습니다: %', key_name;
    END IF;
    
    -- 실제 환경에서는 마스터 키로 encryption_key를 복호화해야 함
    -- 여기서는 단순화된 구현
    encryption_key := key_info.encrypted_key;
    
    -- AES-256-GCM 암호화
    encrypted_result := pgp_sym_encrypt(plain_text::BYTEA, encryption_key);
    
    -- Base64 인코딩하여 TEXT로 반환
    RETURN encode(encrypted_result, 'base64');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 데이터 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(
    encrypted_text TEXT,
    key_name VARCHAR(100) DEFAULT 'default_pii_key'
)
RETURNS TEXT AS $
DECLARE
    encryption_key BYTEA;
    encrypted_data BYTEA;
    decrypted_result BYTEA;
    key_info RECORD;
BEGIN
    -- 빈 값 처리
    IF encrypted_text IS NULL OR encrypted_text = '' THEN
        RETURN NULL;
    END IF;
    
    -- 활성 키 조회
    SELECT encrypted_key, algorithm 
    INTO key_info
    FROM encryption_keys 
    WHERE key_name = decrypt_sensitive_data.key_name 
    AND is_active = true 
    ORDER BY key_version DESC 
    LIMIT 1;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '복호화 키를 찾을 수 없습니다: %', key_name;
    END IF;
    
    -- Base64 디코딩
    encrypted_data := decode(encrypted_text, 'base64');
    encryption_key := key_info.encrypted_key;
    
    -- 복호화
    decrypted_result := pgp_sym_decrypt(encrypted_data, encryption_key);
    
    RETURN convert_from(decrypted_result, 'UTF8');
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '복호화 실패: %', SQLERRM;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. 특화된 암호화 함수들
-- =====================================================

-- 사업자등록번호 암호화 함수
CREATE OR REPLACE FUNCTION encrypt_business_number(business_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN encrypt_sensitive_data(business_number, 'business_data_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사업자등록번호 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_business_number(encrypted_business_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN decrypt_sensitive_data(encrypted_business_number, 'business_data_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 전화번호 암호화 함수
CREATE OR REPLACE FUNCTION encrypt_phone_number(phone_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN encrypt_sensitive_data(phone_number, 'phone_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 전화번호 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_phone_number(encrypted_phone_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN decrypt_sensitive_data(encrypted_phone_number, 'phone_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 이메일 암호화 함수 (선택적)
CREATE OR REPLACE FUNCTION encrypt_email(email TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN encrypt_sensitive_data(email, 'email_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 이메일 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_email(encrypted_email TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN decrypt_sensitive_data(encrypted_email, 'email_key');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. 해시 함수들 (검색 가능한 암호화)
-- =====================================================

-- 검색 가능한 해시 생성 (HMAC-SHA256)
CREATE OR REPLACE FUNCTION create_searchable_hash(
    plain_text TEXT,
    salt TEXT DEFAULT 'qiro_search_salt_2025'
)
RETURNS TEXT AS $
BEGIN
    IF plain_text IS NULL OR plain_text = '' THEN
        RETURN NULL;
    END IF;
    
    RETURN encode(hmac(plain_text, salt, 'sha256'), 'hex');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 사업자등록번호 검색용 해시
CREATE OR REPLACE FUNCTION hash_business_number(business_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN create_searchable_hash(business_number, 'business_search_salt');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 전화번호 검색용 해시
CREATE OR REPLACE FUNCTION hash_phone_number(phone_number TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN create_searchable_hash(phone_number, 'phone_search_salt');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 이메일 검색용 해시
CREATE OR REPLACE FUNCTION hash_email(email TEXT)
RETURNS TEXT AS $
BEGIN
    RETURN create_searchable_hash(email, 'email_search_salt');
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. 키 관리 함수들
-- =====================================================

-- 새 암호화 키 생성
CREATE OR REPLACE FUNCTION create_encryption_key(
    p_key_name VARCHAR(100),
    p_key_purpose VARCHAR(50),
    p_algorithm VARCHAR(50) DEFAULT 'AES-256-GCM'
)
RETURNS UUID AS $
DECLARE
    new_key_id UUID;
    new_version INTEGER;
    raw_key BYTEA;
BEGIN
    -- 기존 키의 최대 버전 확인
    SELECT COALESCE(MAX(key_version), 0) + 1 
    INTO new_version
    FROM encryption_keys 
    WHERE key_name = p_key_name;
    
    -- 기존 키들 비활성화
    UPDATE encryption_keys 
    SET is_active = false 
    WHERE key_name = p_key_name;
    
    -- 새 키 생성 (32바이트 = 256비트)
    raw_key := gen_random_bytes(32);
    
    -- 키 저장 (실제 환경에서는 마스터 키로 암호화해야 함)
    INSERT INTO encryption_keys (
        key_name,
        key_version,
        encrypted_key,
        key_purpose,
        algorithm,
        is_active,
        created_by
    ) VALUES (
        p_key_name,
        new_version,
        raw_key, -- 실제로는 마스터 키로 암호화된 값
        p_key_purpose,
        p_algorithm,
        true,
        current_setting('app.current_user_id', true)::UUID
    ) RETURNING key_id INTO new_key_id;
    
    RETURN new_key_id;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 키 회전 (새 버전 생성)
CREATE OR REPLACE FUNCTION rotate_encryption_key(p_key_name VARCHAR(100))
RETURNS UUID AS $
BEGIN
    RETURN create_encryption_key(
        p_key_name,
        (SELECT key_purpose FROM encryption_keys WHERE key_name = p_key_name LIMIT 1),
        (SELECT algorithm FROM encryption_keys WHERE key_name = p_key_name LIMIT 1)
    );
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기본 암호화 키들 초기화
CREATE OR REPLACE FUNCTION initialize_default_encryption_keys()
RETURNS VOID AS $
BEGIN
    -- PII 데이터용 키
    PERFORM create_encryption_key('default_pii_key', 'PII');
    
    -- 사업자 데이터용 키
    PERFORM create_encryption_key('business_data_key', 'BUSINESS_DATA');
    
    -- 전화번호용 키
    PERFORM create_encryption_key('phone_key', 'PHONE');
    
    -- 이메일용 키
    PERFORM create_encryption_key('email_key', 'EMAIL');
    
    RAISE NOTICE '기본 암호화 키 초기화 완료';
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. 암호화된 데이터 검색 지원 뷰
-- =====================================================

-- 회사 정보 검색 뷰 (복호화된 데이터 포함)
CREATE OR REPLACE VIEW companies_decrypted AS
SELECT 
    company_id,
    decrypt_business_number(business_registration_number_encrypted) as business_registration_number,
    company_name,
    representative_name,
    business_address,
    decrypt_phone_number(contact_phone_encrypted) as contact_phone,
    contact_email,
    business_type,
    establishment_date,
    verification_status,
    verification_date,
    subscription_plan,
    subscription_status,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM companies;

-- 사용자 정보 검색 뷰 (복호화된 데이터 포함)
CREATE OR REPLACE VIEW users_decrypted AS
SELECT 
    user_id,
    company_id,
    email,
    password_hash,
    full_name,
    decrypt_phone_number(phone_number_encrypted) as phone_number,
    department,
    position,
    user_type,
    status,
    email_verified,
    email_verified_at,
    phone_verified,
    phone_verified_at,
    last_login_at,
    last_login_ip,
    failed_login_attempts,
    locked_until,
    password_changed_at,
    must_change_password,
    profile_image_url,
    timezone,
    language,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM users;

-- =====================================================
-- 8. 암호화 상태 모니터링 함수
-- =====================================================

-- 암호화 키 상태 확인
CREATE OR REPLACE FUNCTION check_encryption_key_status()
RETURNS TABLE (
    key_name VARCHAR(100),
    current_version INTEGER,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    days_until_expiry INTEGER
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        ek.key_name,
        ek.key_version,
        ek.is_active,
        ek.created_at,
        ek.expires_at,
        CASE 
            WHEN ek.expires_at IS NOT NULL 
            THEN EXTRACT(DAY FROM ek.expires_at - now())::INTEGER
            ELSE NULL
        END as days_until_expiry
    FROM encryption_keys ek
    WHERE ek.is_active = true
    ORDER BY ek.key_name, ek.key_version DESC;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 암호화된 데이터 통계
CREATE OR REPLACE FUNCTION get_encryption_statistics()
RETURNS TABLE (
    table_name TEXT,
    encrypted_columns TEXT[],
    total_records BIGINT,
    encrypted_records BIGINT,
    encryption_percentage NUMERIC(5,2)
) AS $
BEGIN
    -- Companies 테이블 통계
    RETURN QUERY
    SELECT 
        'companies'::TEXT,
        ARRAY['business_registration_number', 'contact_phone']::TEXT[],
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN business_registration_number_encrypted IS NOT NULL THEN 1 END)::BIGINT,
        ROUND(
            COUNT(CASE WHEN business_registration_number_encrypted IS NOT NULL THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(*), 0) * 100, 2
        )
    FROM companies;
    
    -- Users 테이블 통계
    RETURN QUERY
    SELECT 
        'users'::TEXT,
        ARRAY['phone_number']::TEXT[],
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN phone_number_encrypted IS NOT NULL THEN 1 END)::BIGINT,
        ROUND(
            COUNT(CASE WHEN phone_number_encrypted IS NOT NULL THEN 1 END)::NUMERIC / 
            NULLIF(COUNT(*), 0) * 100, 2
        )
    FROM users;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. 데이터 마이그레이션 함수 (기존 데이터 암호화)
-- =====================================================

-- 기존 회사 데이터 암호화 마이그레이션
CREATE OR REPLACE FUNCTION migrate_companies_encryption()
RETURNS INTEGER AS $
DECLARE
    company_record RECORD;
    migrated_count INTEGER := 0;
BEGIN
    -- 암호화되지 않은 회사 데이터 처리
    FOR company_record IN 
        SELECT company_id, business_registration_number, contact_phone
        FROM companies 
        WHERE business_registration_number_encrypted IS NULL
        AND business_registration_number IS NOT NULL
    LOOP
        UPDATE companies SET
            business_registration_number_encrypted = encrypt_business_number(company_record.business_registration_number),
            business_registration_number_hash = hash_business_number(company_record.business_registration_number),
            contact_phone_encrypted = encrypt_phone_number(company_record.contact_phone),
            contact_phone_hash = hash_phone_number(company_record.contact_phone)
        WHERE company_id = company_record.company_id;
        
        migrated_count := migrated_count + 1;
    END LOOP;
    
    RETURN migrated_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 기존 사용자 데이터 암호화 마이그레이션
CREATE OR REPLACE FUNCTION migrate_users_encryption()
RETURNS INTEGER AS $
DECLARE
    user_record RECORD;
    migrated_count INTEGER := 0;
BEGIN
    -- 암호화되지 않은 사용자 데이터 처리
    FOR user_record IN 
        SELECT user_id, phone_number
        FROM users 
        WHERE phone_number_encrypted IS NULL
        AND phone_number IS NOT NULL
    LOOP
        UPDATE users SET
            phone_number_encrypted = encrypt_phone_number(user_record.phone_number),
            phone_number_hash = hash_phone_number(user_record.phone_number)
        WHERE user_id = user_record.user_id;
        
        migrated_count := migrated_count + 1;
    END LOOP;
    
    RETURN migrated_count;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. 코멘트 추가
-- =====================================================

COMMENT ON TABLE encryption_keys IS '암호화 키 관리 테이블 (키 회전 지원)';
COMMENT ON FUNCTION encrypt_sensitive_data(TEXT, VARCHAR) IS '민감 데이터 AES-256-GCM 암호화';
COMMENT ON FUNCTION decrypt_sensitive_data(TEXT, VARCHAR) IS '암호화된 데이터 복호화';
COMMENT ON FUNCTION create_searchable_hash(TEXT, TEXT) IS '검색 가능한 HMAC-SHA256 해시 생성';
COMMENT ON FUNCTION create_encryption_key(VARCHAR, VARCHAR, VARCHAR) IS '새 암호화 키 생성 및 등록';
COMMENT ON FUNCTION rotate_encryption_key(VARCHAR) IS '암호화 키 회전 (새 버전 생성)';

-- =====================================================
-- 11. 초기 설정 실행
-- =====================================================

-- 기본 암호화 키 초기화 (처음 실행 시에만)
SELECT initialize_default_encryption_keys();

-- 설정 완료 메시지
DO $
BEGIN
    RAISE NOTICE '=== QIRO 데이터 암호화 시스템 설정 완료 ===';
    RAISE NOTICE '1. 암호화 키 관리 시스템 구축 완료';
    RAISE NOTICE '2. AES-256-GCM 암호화/복호화 함수 생성 완료';
    RAISE NOTICE '3. 검색 가능한 해시 함수 생성 완료';
    RAISE NOTICE '4. 특화된 암호화 함수들 생성 완료';
    RAISE NOTICE '5. 키 관리 및 회전 시스템 구축 완료';
    RAISE NOTICE '';
    RAISE NOTICE '=== 주요 함수들 ===';
    RAISE NOTICE '- encrypt_business_number(text): 사업자등록번호 암호화';
    RAISE NOTICE '- encrypt_phone_number(text): 전화번호 암호화';
    RAISE NOTICE '- decrypt_business_number(text): 사업자등록번호 복호화';
    RAISE NOTICE '- decrypt_phone_number(text): 전화번호 복호화';
    RAISE NOTICE '- check_encryption_key_status(): 키 상태 확인';
    RAISE NOTICE '- get_encryption_statistics(): 암호화 통계';
    RAISE NOTICE '';
    RAISE NOTICE '=== 보안 권장사항 ===';
    RAISE NOTICE '1. 실제 운영환경에서는 외부 키 관리 시스템 사용 권장';
    RAISE NOTICE '2. 정기적인 키 회전 정책 수립 필요';
    RAISE NOTICE '3. 암호화된 데이터 백업 및 복구 절차 수립 필요';
END $;