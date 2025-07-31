-- =====================================================
-- QIRO 암호화 컬럼 추가 마이그레이션
-- 기존 테이블에 암호화 필드 추가
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. Companies 테이블에 암호화 컬럼 추가
-- =====================================================

-- 사업자등록번호 암호화 컬럼 추가
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS business_registration_number_encrypted TEXT,
ADD COLUMN IF NOT EXISTS business_registration_number_hash VARCHAR(64);

-- 연락처 전화번호 암호화 컬럼 추가
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS contact_phone_encrypted TEXT,
ADD COLUMN IF NOT EXISTS contact_phone_hash VARCHAR(64);

-- 대표자명 암호화 컬럼 추가 (선택적)
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS representative_name_encrypted TEXT,
ADD COLUMN IF NOT EXISTS representative_name_hash VARCHAR(64);

-- 사업장 주소 암호화 컬럼 추가 (선택적)
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS business_address_encrypted TEXT;

-- =====================================================
-- 2. Users 테이블에 암호화 컬럼 추가
-- =====================================================

-- 전화번호 암호화 컬럼 추가
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone_number_encrypted TEXT,
ADD COLUMN IF NOT EXISTS phone_number_hash VARCHAR(64);

-- 이메일 암호화 컬럼 추가 (선택적 - 검색 필요성 고려)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email_encrypted TEXT,
ADD COLUMN IF NOT EXISTS email_hash VARCHAR(64);

-- 전체 이름 암호화 컬럼 추가 (선택적)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS full_name_encrypted TEXT,
ADD COLUMN IF NOT EXISTS full_name_hash VARCHAR(64);

-- =====================================================
-- 3. Business_verification_records 테이블에 암호화 컬럼 추가
-- =====================================================

-- 인증 데이터 암호화 강화
ALTER TABLE business_verification_records 
ADD COLUMN IF NOT EXISTS verification_data_encrypted TEXT;

-- =====================================================
-- 4. Phone_verification_tokens 테이블에 암호화 컬럼 추가
-- =====================================================

-- 전화번호 암호화 컬럼 추가
ALTER TABLE phone_verification_tokens 
ADD COLUMN IF NOT EXISTS phone_number_encrypted TEXT,
ADD COLUMN IF NOT EXISTS phone_number_hash VARCHAR(64);

-- =====================================================
-- 5. 암호화 컬럼 인덱스 생성
-- =====================================================

-- Companies 테이블 해시 인덱스
CREATE INDEX IF NOT EXISTS idx_companies_business_number_hash 
    ON companies(business_registration_number_hash);
CREATE INDEX IF NOT EXISTS idx_companies_contact_phone_hash 
    ON companies(contact_phone_hash);
CREATE INDEX IF NOT EXISTS idx_companies_representative_name_hash 
    ON companies(representative_name_hash);

-- Users 테이블 해시 인덱스
CREATE INDEX IF NOT EXISTS idx_users_phone_number_hash 
    ON users(phone_number_hash);
CREATE INDEX IF NOT EXISTS idx_users_email_hash 
    ON users(email_hash);
CREATE INDEX IF NOT EXISTS idx_users_full_name_hash 
    ON users(full_name_hash);

-- Phone_verification_tokens 테이블 해시 인덱스
CREATE INDEX IF NOT EXISTS idx_phone_tokens_phone_hash 
    ON phone_verification_tokens(phone_number_hash);

-- =====================================================
-- 6. 암호화 데이터 검증 제약조건
-- =====================================================

-- Companies 테이블 제약조건
ALTER TABLE companies 
ADD CONSTRAINT chk_business_number_encryption 
    CHECK (
        (business_registration_number IS NULL AND business_registration_number_encrypted IS NULL) OR
        (business_registration_number IS NOT NULL OR business_registration_number_encrypted IS NOT NULL)
    );

ALTER TABLE companies 
ADD CONSTRAINT chk_contact_phone_encryption 
    CHECK (
        (contact_phone IS NULL AND contact_phone_encrypted IS NULL) OR
        (contact_phone IS NOT NULL OR contact_phone_encrypted IS NOT NULL)
    );

-- Users 테이블 제약조건
ALTER TABLE users 
ADD CONSTRAINT chk_phone_number_encryption 
    CHECK (
        (phone_number IS NULL AND phone_number_encrypted IS NULL) OR
        (phone_number IS NOT NULL OR phone_number_encrypted IS NOT NULL)
    );

-- =====================================================
-- 7. 암호화 데이터 동기화 트리거 함수
-- =====================================================

-- Companies 테이블 암호화 동기화 트리거
CREATE OR REPLACE FUNCTION sync_companies_encryption()
RETURNS TRIGGER AS $
BEGIN
    -- 사업자등록번호 암호화 동기화
    IF NEW.business_registration_number IS DISTINCT FROM OLD.business_registration_number THEN
        NEW.business_registration_number_encrypted := encrypt_business_number(NEW.business_registration_number);
        NEW.business_registration_number_hash := hash_business_number(NEW.business_registration_number);
    END IF;
    
    -- 연락처 전화번호 암호화 동기화
    IF NEW.contact_phone IS DISTINCT FROM OLD.contact_phone THEN
        NEW.contact_phone_encrypted := encrypt_phone_number(NEW.contact_phone);
        NEW.contact_phone_hash := hash_phone_number(NEW.contact_phone);
    END IF;
    
    -- 대표자명 암호화 동기화
    IF NEW.representative_name IS DISTINCT FROM OLD.representative_name THEN
        NEW.representative_name_encrypted := encrypt_sensitive_data(NEW.representative_name, 'default_pii_key');
        NEW.representative_name_hash := create_searchable_hash(NEW.representative_name);
    END IF;
    
    -- 사업장 주소 암호화 동기화
    IF NEW.business_address IS DISTINCT FROM OLD.business_address THEN
        NEW.business_address_encrypted := encrypt_sensitive_data(NEW.business_address, 'default_pii_key');
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Companies 테이블 INSERT 트리거
CREATE OR REPLACE FUNCTION sync_companies_encryption_insert()
RETURNS TRIGGER AS $
BEGIN
    -- 사업자등록번호 암호화
    IF NEW.business_registration_number IS NOT NULL THEN
        NEW.business_registration_number_encrypted := encrypt_business_number(NEW.business_registration_number);
        NEW.business_registration_number_hash := hash_business_number(NEW.business_registration_number);
    END IF;
    
    -- 연락처 전화번호 암호화
    IF NEW.contact_phone IS NOT NULL THEN
        NEW.contact_phone_encrypted := encrypt_phone_number(NEW.contact_phone);
        NEW.contact_phone_hash := hash_phone_number(NEW.contact_phone);
    END IF;
    
    -- 대표자명 암호화
    IF NEW.representative_name IS NOT NULL THEN
        NEW.representative_name_encrypted := encrypt_sensitive_data(NEW.representative_name, 'default_pii_key');
        NEW.representative_name_hash := create_searchable_hash(NEW.representative_name);
    END IF;
    
    -- 사업장 주소 암호화
    IF NEW.business_address IS NOT NULL THEN
        NEW.business_address_encrypted := encrypt_sensitive_data(NEW.business_address, 'default_pii_key');
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users 테이블 암호화 동기화 트리거
CREATE OR REPLACE FUNCTION sync_users_encryption()
RETURNS TRIGGER AS $
BEGIN
    -- 전화번호 암호화 동기화
    IF NEW.phone_number IS DISTINCT FROM OLD.phone_number THEN
        NEW.phone_number_encrypted := encrypt_phone_number(NEW.phone_number);
        NEW.phone_number_hash := hash_phone_number(NEW.phone_number);
    END IF;
    
    -- 이메일 암호화 동기화 (선택적)
    IF NEW.email IS DISTINCT FROM OLD.email THEN
        NEW.email_encrypted := encrypt_email(NEW.email);
        NEW.email_hash := hash_email(NEW.email);
    END IF;
    
    -- 전체 이름 암호화 동기화
    IF NEW.full_name IS DISTINCT FROM OLD.full_name THEN
        NEW.full_name_encrypted := encrypt_sensitive_data(NEW.full_name, 'default_pii_key');
        NEW.full_name_hash := create_searchable_hash(NEW.full_name);
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- Users 테이블 INSERT 트리거
CREATE OR REPLACE FUNCTION sync_users_encryption_insert()
RETURNS TRIGGER AS $
BEGIN
    -- 전화번호 암호화
    IF NEW.phone_number IS NOT NULL THEN
        NEW.phone_number_encrypted := encrypt_phone_number(NEW.phone_number);
        NEW.phone_number_hash := hash_phone_number(NEW.phone_number);
    END IF;
    
    -- 이메일 암호화 (선택적)
    IF NEW.email IS NOT NULL THEN
        NEW.email_encrypted := encrypt_email(NEW.email);
        NEW.email_hash := hash_email(NEW.email);
    END IF;
    
    -- 전체 이름 암호화
    IF NEW.full_name IS NOT NULL THEN
        NEW.full_name_encrypted := encrypt_sensitive_data(NEW.full_name, 'default_pii_key');
        NEW.full_name_hash := create_searchable_hash(NEW.full_name);
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. 트리거 생성
-- =====================================================

-- Companies 테이블 트리거
DROP TRIGGER IF EXISTS companies_encryption_sync_trigger ON companies;
CREATE TRIGGER companies_encryption_sync_trigger
    BEFORE UPDATE ON companies
    FOR EACH ROW
    EXECUTE FUNCTION sync_companies_encryption();

DROP TRIGGER IF EXISTS companies_encryption_insert_trigger ON companies;
CREATE TRIGGER companies_encryption_insert_trigger
    BEFORE INSERT ON companies
    FOR EACH ROW
    EXECUTE FUNCTION sync_companies_encryption_insert();

-- Users 테이블 트리거
DROP TRIGGER IF EXISTS users_encryption_sync_trigger ON users;
CREATE TRIGGER users_encryption_sync_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_users_encryption();

DROP TRIGGER IF EXISTS users_encryption_insert_trigger ON users;
CREATE TRIGGER users_encryption_insert_trigger
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION sync_users_encryption_insert();

-- =====================================================
-- 9. 암호화된 데이터 검색 함수들
-- =====================================================

-- 사업자등록번호로 회사 검색
CREATE OR REPLACE FUNCTION find_company_by_business_number(search_business_number TEXT)
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    representative_name VARCHAR(100),
    verification_status VARCHAR(20)
) AS $
DECLARE
    search_hash VARCHAR(64);
BEGIN
    search_hash := hash_business_number(search_business_number);
    
    RETURN QUERY
    SELECT 
        c.company_id,
        c.company_name,
        c.representative_name,
        c.verification_status
    FROM companies c
    WHERE c.business_registration_number_hash = search_hash;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- 전화번호로 사용자 검색
CREATE OR REPLACE FUNCTION find_user_by_phone_number(search_phone_number TEXT)
RETURNS TABLE (
    user_id UUID,
    company_id UUID,
    email VARCHAR(255),
    full_name VARCHAR(100),
    user_type user_type,
    status user_status
) AS $
DECLARE
    search_hash VARCHAR(64);
BEGIN
    search_hash := hash_phone_number(search_phone_number);
    
    RETURN QUERY
    SELECT 
        u.user_id,
        u.company_id,
        u.email,
        u.full_name,
        u.user_type,
        u.status
    FROM users u
    WHERE u.phone_number_hash = search_hash;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. 데이터 마이그레이션 실행 함수
-- =====================================================

-- 전체 암호화 마이그레이션 실행
CREATE OR REPLACE FUNCTION execute_full_encryption_migration()
RETURNS TABLE (
    table_name TEXT,
    migrated_records INTEGER,
    status TEXT
) AS $
DECLARE
    companies_migrated INTEGER;
    users_migrated INTEGER;
BEGIN
    -- Companies 테이블 마이그레이션
    SELECT migrate_companies_encryption() INTO companies_migrated;
    
    RETURN QUERY
    SELECT 'companies'::TEXT, companies_migrated, 'completed'::TEXT;
    
    -- Users 테이블 마이그레이션
    SELECT migrate_users_encryption() INTO users_migrated;
    
    RETURN QUERY
    SELECT 'users'::TEXT, users_migrated, 'completed'::TEXT;
    
    -- 마이그레이션 완료 로그
    RAISE NOTICE '암호화 마이그레이션 완료: Companies(%), Users(%)', 
        companies_migrated, users_migrated;
END;
$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 11. 코멘트 추가
-- =====================================================

COMMENT ON COLUMN companies.business_registration_number_encrypted IS '암호화된 사업자등록번호';
COMMENT ON COLUMN companies.business_registration_number_hash IS '사업자등록번호 검색용 해시';
COMMENT ON COLUMN companies.contact_phone_encrypted IS '암호화된 연락처 전화번호';
COMMENT ON COLUMN companies.contact_phone_hash IS '전화번호 검색용 해시';

COMMENT ON COLUMN users.phone_number_encrypted IS '암호화된 전화번호';
COMMENT ON COLUMN users.phone_number_hash IS '전화번호 검색용 해시';
COMMENT ON COLUMN users.email_encrypted IS '암호화된 이메일 (선택적)';
COMMENT ON COLUMN users.email_hash IS '이메일 검색용 해시';

COMMENT ON FUNCTION find_company_by_business_number(TEXT) IS '사업자등록번호로 회사 검색 (해시 기반)';
COMMENT ON FUNCTION find_user_by_phone_number(TEXT) IS '전화번호로 사용자 검색 (해시 기반)';

-- =====================================================
-- 12. 마이그레이션 완료 메시지
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '=== QIRO 암호화 컬럼 마이그레이션 완료 ===';
    RAISE NOTICE '1. Companies 테이블 암호화 컬럼 추가 완료';
    RAISE NOTICE '2. Users 테이블 암호화 컬럼 추가 완료';
    RAISE NOTICE '3. 암호화 동기화 트리거 설정 완료';
    RAISE NOTICE '4. 검색용 해시 인덱스 생성 완료';
    RAISE NOTICE '5. 암호화된 데이터 검색 함수 생성 완료';
    RAISE NOTICE '';
    RAISE NOTICE '=== 다음 단계 ===';
    RAISE NOTICE '1. execute_full_encryption_migration() 실행으로 기존 데이터 암호화';
    RAISE NOTICE '2. 애플리케이션 코드에서 암호화된 컬럼 사용으로 전환';
    RAISE NOTICE '3. 기존 평문 컬럼 제거 (충분한 테스트 후)';
END $;