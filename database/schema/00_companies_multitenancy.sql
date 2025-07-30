-- =====================================================
-- QIRO 사업자 회원가입 및 멀티테넌시 구조
-- Companies 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 확장 기능 활성화 (필요시)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. 사업자 관련 ENUM 타입 정의
-- =====================================================

-- 사업자 인증 상태
CREATE TYPE verification_status AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');

-- 구독 상태
CREATE TYPE subscription_status AS ENUM ('ACTIVE', 'SUSPENDED', 'CANCELLED', 'TRIAL');

-- 사용자 타입
CREATE TYPE user_type AS ENUM ('SUPER_ADMIN', 'EMPLOYEE');

-- 사용자 상태
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'LOCKED', 'PENDING_VERIFICATION');

-- =====================================================
-- 2. 사업자등록번호 검증 함수 개선
-- =====================================================

-- 기존 함수가 있다면 대체
DROP FUNCTION IF EXISTS validate_business_registration_number(TEXT);

CREATE OR REPLACE FUNCTION validate_business_registration_number(brn TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    digits INTEGER[];
    check_sum INTEGER;
    calculated_check INTEGER;
BEGIN
    -- 사업자등록번호 형식 검증 (10자리 숫자)
    IF brn IS NULL OR LENGTH(brn) != 10 OR brn !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 각 자리수를 배열로 변환
    FOR i IN 1..10 LOOP
        digits[i] := SUBSTRING(brn FROM i FOR 1)::INTEGER;
    END LOOP;
    
    -- 체크섬 계산
    check_sum := digits[1] * 1 + digits[2] * 3 + digits[3] * 7 + digits[4] * 1 + 
                 digits[5] * 3 + digits[6] * 7 + digits[7] * 1 + digits[8] * 3 + 
                 (digits[9] * 5) % 10;
    
    calculated_check := (10 - (check_sum % 10)) % 10;
    
    -- 마지막 자리수와 계산된 체크 디지트 비교
    RETURN calculated_check = digits[10];
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Companies 테이블 생성
-- =====================================================

CREATE TABLE companies (
    company_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_registration_number VARCHAR(20) UNIQUE NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    representative_name VARCHAR(100) NOT NULL,
    business_address TEXT NOT NULL,
    contact_phone VARCHAR(20) NOT NULL,
    contact_email VARCHAR(255) NOT NULL,
    business_type VARCHAR(50) NOT NULL,
    establishment_date DATE NOT NULL,
    
    -- 인증 관련 필드
    verification_status verification_status NOT NULL DEFAULT 'PENDING',
    verification_date TIMESTAMPTZ,
    verification_data JSONB DEFAULT '{}',
    
    -- 구독 관련 필드
    subscription_plan VARCHAR(50) DEFAULT 'BASIC',
    subscription_status subscription_status DEFAULT 'TRIAL',
    subscription_start_date TIMESTAMPTZ DEFAULT now(),
    subscription_end_date TIMESTAMPTZ,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT chk_business_registration_number 
        CHECK (validate_business_registration_number(business_registration_number)),
    CONSTRAINT chk_contact_email 
        CHECK (contact_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_contact_phone 
        CHECK (contact_phone ~ '^[0-9-+().\s]+$'),
    CONSTRAINT chk_establishment_date 
        CHECK (establishment_date <= CURRENT_DATE)
);

-- =====================================================
-- 4. 인덱스 생성
-- =====================================================

-- 사업자등록번호 인덱스 (이미 UNIQUE 제약조건으로 생성됨)
-- 회사명 검색용 인덱스
CREATE INDEX idx_companies_company_name ON companies USING gin(to_tsvector('korean', company_name));

-- 인증 상태별 조회용 인덱스
CREATE INDEX idx_companies_verification_status ON companies(verification_status);

-- 구독 상태별 조회용 인덱스
CREATE INDEX idx_companies_subscription_status ON companies(subscription_status);

-- 생성일 기준 정렬용 인덱스
CREATE INDEX idx_companies_created_at ON companies(created_at DESC);

-- =====================================================
-- 5. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER companies_updated_at_trigger
    BEFORE UPDATE ON companies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

-- 애플리케이션 역할 생성 (존재하지 않는 경우)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'application_role') THEN
        CREATE ROLE application_role;
    END IF;
END
$$;

-- 조직별 데이터 격리 정책
CREATE POLICY company_isolation_policy ON companies
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY company_admin_policy ON companies
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON TABLE companies IS '사업자 회원가입 및 조직 정보 관리 테이블';
COMMENT ON COLUMN companies.company_id IS '회사 고유 식별자 (UUID)';
COMMENT ON COLUMN companies.business_registration_number IS '사업자등록번호 (10자리, 유효성 검증됨)';
COMMENT ON COLUMN companies.company_name IS '회사명';
COMMENT ON COLUMN companies.representative_name IS '대표자명';
COMMENT ON COLUMN companies.business_address IS '사업장 주소';
COMMENT ON COLUMN companies.contact_phone IS '연락처 전화번호';
COMMENT ON COLUMN companies.contact_email IS '연락처 이메일';
COMMENT ON COLUMN companies.business_type IS '업종';
COMMENT ON COLUMN companies.establishment_date IS '설립일';
COMMENT ON COLUMN companies.verification_status IS '사업자 인증 상태 (PENDING, VERIFIED, REJECTED, SUSPENDED)';
COMMENT ON COLUMN companies.verification_date IS '인증 완료일';
COMMENT ON COLUMN companies.verification_data IS '인증 관련 추가 데이터 (JSONB)';
COMMENT ON COLUMN companies.subscription_plan IS '구독 플랜 (BASIC, PREMIUM, ENTERPRISE)';
COMMENT ON COLUMN companies.subscription_status IS '구독 상태 (ACTIVE, SUSPENDED, CANCELLED, TRIAL)';
COMMENT ON COLUMN companies.subscription_start_date IS '구독 시작일';
COMMENT ON COLUMN companies.subscription_end_date IS '구독 종료일';