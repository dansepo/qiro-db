-- =====================================================
-- QIRO 사업자 회원가입 및 멀티테넌시 구조
-- Users 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. Users 테이블 생성 (멀티테넌시 지원)
-- =====================================================

CREATE TABLE users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 기본 정보
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    department VARCHAR(100),
    position VARCHAR(100),
    
    -- 사용자 분류
    user_type user_type NOT NULL DEFAULT 'EMPLOYEE',
    status user_status NOT NULL DEFAULT 'PENDING_VERIFICATION',
    
    -- 인증 관련
    email_verified BOOLEAN NOT NULL DEFAULT false,
    email_verified_at TIMESTAMPTZ,
    phone_verified BOOLEAN NOT NULL DEFAULT false,
    phone_verified_at TIMESTAMPTZ,
    
    -- 보안 관련
    last_login_at TIMESTAMPTZ,
    last_login_ip INET,
    failed_login_attempts INTEGER DEFAULT 0,
    locked_until TIMESTAMPTZ,
    password_changed_at TIMESTAMPTZ DEFAULT now(),
    must_change_password BOOLEAN DEFAULT true,
    
    -- 추가 정보
    profile_image_url TEXT,
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',
    language VARCHAR(10) DEFAULT 'ko',
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT users_company_email_unique UNIQUE(company_id, email),
    CONSTRAINT chk_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_phone_format 
        CHECK (phone_number IS NULL OR phone_number ~ '^[0-9-+().\s]+$'),
    CONSTRAINT chk_failed_attempts 
        CHECK (failed_login_attempts >= 0 AND failed_login_attempts <= 10),
    CONSTRAINT chk_password_changed_at 
        CHECK (password_changed_at <= now())
);

-- =====================================================
-- 2. 인덱스 생성
-- =====================================================

-- 조직별 사용자 조회용 인덱스
CREATE INDEX idx_users_company_id ON users(company_id);

-- 이메일 검색용 인덱스
CREATE INDEX idx_users_email ON users(email);

-- 사용자 타입별 조회용 인덱스
CREATE INDEX idx_users_user_type ON users(user_type);

-- 상태별 조회용 인덱스
CREATE INDEX idx_users_status ON users(status);

-- 인증 상태별 조회용 인덱스
CREATE INDEX idx_users_email_verified ON users(email_verified);
CREATE INDEX idx_users_phone_verified ON users(phone_verified);

-- 마지막 로그인 기준 정렬용 인덱스
CREATE INDEX idx_users_last_login_at ON users(last_login_at DESC NULLS LAST);

-- 생성일 기준 정렬용 인덱스
CREATE INDEX idx_users_created_at ON users(created_at DESC);

-- 복합 인덱스: 조직별 활성 사용자
CREATE INDEX idx_users_company_active ON users(company_id, status) 
    WHERE status = 'ACTIVE';

-- =====================================================
-- 3. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER users_updated_at_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 4. 사용자 관련 함수
-- =====================================================

-- 비밀번호 해시 생성 함수
CREATE OR REPLACE FUNCTION hash_password(plain_password TEXT)
RETURNS TEXT AS $$
BEGIN
    -- bcrypt 해시 생성 (실제 구현에서는 애플리케이션 레벨에서 처리)
    RETURN crypt(plain_password, gen_salt('bf', 12));
END;
$$ LANGUAGE plpgsql;

-- 비밀번호 검증 함수
CREATE OR REPLACE FUNCTION verify_password(plain_password TEXT, hashed_password TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN hashed_password = crypt(plain_password, hashed_password);
END;
$$ LANGUAGE plpgsql;

-- 사용자 계정 잠금 함수
CREATE OR REPLACE FUNCTION lock_user_account(p_user_id UUID, lock_duration_minutes INTEGER DEFAULT 30)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        status = 'LOCKED',
        locked_until = now() + (lock_duration_minutes || ' minutes')::INTERVAL,
        updated_at = now()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 로그인 실패 처리 함수
CREATE OR REPLACE FUNCTION handle_login_failure(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    current_attempts INTEGER;
    max_attempts INTEGER := 5;
BEGIN
    -- 실패 횟수 증가
    UPDATE users 
    SET 
        failed_login_attempts = failed_login_attempts + 1,
        updated_at = now()
    WHERE user_id = p_user_id
    RETURNING failed_login_attempts INTO current_attempts;
    
    -- 최대 시도 횟수 초과 시 계정 잠금
    IF current_attempts >= max_attempts THEN
        PERFORM lock_user_account(p_user_id, 30);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 로그인 성공 처리 함수
CREATE OR REPLACE FUNCTION handle_login_success(p_user_id UUID, p_login_ip INET DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        failed_login_attempts = 0,
        last_login_at = now(),
        last_login_ip = p_login_ip,
        locked_until = NULL,
        status = CASE 
            WHEN status = 'LOCKED' THEN 'ACTIVE'
            ELSE status
        END,
        updated_at = now()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 계정 잠금 해제 함수
CREATE OR REPLACE FUNCTION unlock_user_account(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE users 
    SET 
        status = 'ACTIVE',
        locked_until = NULL,
        failed_login_attempts = 0,
        updated_at = now()
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 조직별 사용자 데이터 격리 정책
CREATE POLICY users_company_isolation_policy ON users
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY users_admin_policy ON users
    FOR ALL
    TO postgres
    USING (true);

-- 사용자 자신의 데이터 접근 정책
CREATE POLICY users_self_access_policy ON users
    FOR SELECT
    TO application_role
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- =====================================================
-- 6. 자동 계정 잠금 해제 함수 (스케줄러용)
-- =====================================================

CREATE OR REPLACE FUNCTION auto_unlock_expired_accounts()
RETURNS INTEGER AS $$
DECLARE
    unlocked_count INTEGER;
BEGIN
    UPDATE users 
    SET 
        status = 'ACTIVE',
        locked_until = NULL,
        failed_login_attempts = 0,
        updated_at = now()
    WHERE 
        status = 'LOCKED' 
        AND locked_until IS NOT NULL 
        AND locked_until <= now();
    
    GET DIAGNOSTICS unlocked_count = ROW_COUNT;
    RETURN unlocked_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON TABLE users IS '멀티테넌시 지원 사용자 정보 테이블';
COMMENT ON COLUMN users.user_id IS '사용자 고유 식별자 (UUID)';
COMMENT ON COLUMN users.company_id IS '소속 회사 식별자 (외래키)';
COMMENT ON COLUMN users.email IS '이메일 주소 (조직 내 유일)';
COMMENT ON COLUMN users.password_hash IS '암호화된 비밀번호';
COMMENT ON COLUMN users.full_name IS '사용자 전체 이름';
COMMENT ON COLUMN users.phone_number IS '전화번호';
COMMENT ON COLUMN users.department IS '부서명';
COMMENT ON COLUMN users.position IS '직책';
COMMENT ON COLUMN users.user_type IS '사용자 타입 (SUPER_ADMIN, EMPLOYEE)';
COMMENT ON COLUMN users.status IS '계정 상태 (ACTIVE, INACTIVE, LOCKED, PENDING_VERIFICATION)';
COMMENT ON COLUMN users.email_verified IS '이메일 인증 여부';
COMMENT ON COLUMN users.email_verified_at IS '이메일 인증 완료 시간';
COMMENT ON COLUMN users.phone_verified IS '전화번호 인증 여부';
COMMENT ON COLUMN users.phone_verified_at IS '전화번호 인증 완료 시간';
COMMENT ON COLUMN users.last_login_at IS '마지막 로그인 시간';
COMMENT ON COLUMN users.last_login_ip IS '마지막 로그인 IP 주소';
COMMENT ON COLUMN users.failed_login_attempts IS '로그인 실패 횟수';
COMMENT ON COLUMN users.locked_until IS '계정 잠금 해제 시간';
COMMENT ON COLUMN users.password_changed_at IS '비밀번호 마지막 변경 시간';
COMMENT ON COLUMN users.must_change_password IS '비밀번호 변경 강제 여부';
COMMENT ON COLUMN users.profile_image_url IS '프로필 이미지 URL';
COMMENT ON COLUMN users.timezone IS '사용자 시간대';
COMMENT ON COLUMN users.language IS '사용자 언어 설정';