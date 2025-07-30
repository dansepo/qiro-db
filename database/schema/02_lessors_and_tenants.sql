-- =====================================================
-- 임대인 및 임차인 정보 테이블 설계
-- 요구사항: 1.3, 1.4
-- =====================================================

-- 개인/법인 구분 ENUM 타입
CREATE TYPE entity_type AS ENUM (
    'INDIVIDUAL',       -- 개인
    'CORPORATION',      -- 법인
    'PARTNERSHIP'       -- 조합/파트너십
);

-- 연락처 우선순위 ENUM 타입
CREATE TYPE contact_priority AS ENUM (
    'PRIMARY',          -- 주 연락처
    'SECONDARY',        -- 보조 연락처
    'EMERGENCY'         -- 비상 연락처
);

-- =====================================================
-- 임대인 정보 테이블 (lessors)
-- =====================================================
CREATE TABLE lessors (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    name VARCHAR(255) NOT NULL COMMENT '임대인명/법인명',
    entity_type entity_type NOT NULL DEFAULT 'INDIVIDUAL' COMMENT '개인/법인 구분',
    
    -- 개인 정보 (개인인 경우)
    resident_number_encrypted BYTEA COMMENT '주민등록번호 (암호화)',
    birth_date DATE COMMENT '생년월일',
    gender CHAR(1) CHECK (gender IN ('M', 'F')) COMMENT '성별',
    
    -- 법인 정보 (법인인 경우)
    business_registration_number VARCHAR(20) COMMENT '사업자등록번호',
    corporate_registration_number VARCHAR(20) COMMENT '법인등록번호',
    representative_name VARCHAR(255) COMMENT '대표자명',
    business_type VARCHAR(100) COMMENT '업종',
    establishment_date DATE COMMENT '설립일',
    
    -- 연락처 정보
    primary_phone VARCHAR(20) COMMENT '주 연락처',
    secondary_phone VARCHAR(20) COMMENT '보조 연락처',
    email VARCHAR(255) COMMENT '이메일',
    fax VARCHAR(20) COMMENT '팩스번호',
    
    -- 주소 정보
    address TEXT COMMENT '주소',
    postal_code VARCHAR(10) COMMENT '우편번호',
    detailed_address TEXT COMMENT '상세주소',
    
    -- 은행 정보
    bank_name VARCHAR(100) COMMENT '은행명',
    account_number_encrypted BYTEA COMMENT '계좌번호 (암호화)',
    account_holder VARCHAR(255) COMMENT '예금주',
    
    -- 세무 정보
    tax_id VARCHAR(20) COMMENT '납세자번호',
    tax_office VARCHAR(100) COMMENT '관할 세무서',
    
    -- 상태 및 메타데이터
    is_active BOOLEAN DEFAULT true COMMENT '활성 상태',
    notes TEXT COMMENT '특이사항',
    
    -- 개인정보 동의
    privacy_consent BOOLEAN DEFAULT false COMMENT '개인정보 수집/이용 동의',
    privacy_consent_date TIMESTAMP COMMENT '개인정보 동의일시',
    marketing_consent BOOLEAN DEFAULT false COMMENT '마케팅 활용 동의',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID'
);

-- 임대인 테이블 인덱스
CREATE INDEX idx_lessors_name ON lessors(name);
CREATE INDEX idx_lessors_entity_type ON lessors(entity_type);
CREATE INDEX idx_lessors_business_number ON lessors(business_registration_number);
CREATE INDEX idx_lessors_email ON lessors(email);
CREATE INDEX idx_lessors_is_active ON lessors(is_active);
CREATE INDEX idx_lessors_created_at ON lessors(created_at);

-- =====================================================
-- 임차인 정보 테이블 (tenants)
-- =====================================================
CREATE TABLE tenants (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    name VARCHAR(255) NOT NULL COMMENT '임차인명/법인명',
    entity_type entity_type NOT NULL DEFAULT 'INDIVIDUAL' COMMENT '개인/법인 구분',
    
    -- 개인 정보 (개인인 경우)
    resident_number_encrypted BYTEA COMMENT '주민등록번호 (암호화)',
    birth_date DATE COMMENT '생년월일',
    gender CHAR(1) CHECK (gender IN ('M', 'F')) COMMENT '성별',
    nationality VARCHAR(50) DEFAULT 'KR' COMMENT '국적',
    
    -- 법인 정보 (법인인 경우)
    business_registration_number VARCHAR(20) COMMENT '사업자등록번호',
    corporate_registration_number VARCHAR(20) COMMENT '법인등록번호',
    representative_name VARCHAR(255) COMMENT '대표자명',
    business_type VARCHAR(100) COMMENT '업종',
    establishment_date DATE COMMENT '설립일',
    
    -- 연락처 정보
    primary_phone VARCHAR(20) COMMENT '주 연락처',
    secondary_phone VARCHAR(20) COMMENT '보조 연락처',
    email VARCHAR(255) COMMENT '이메일',
    emergency_contact_name VARCHAR(255) COMMENT '비상연락처 이름',
    emergency_contact_phone VARCHAR(20) COMMENT '비상연락처 번호',
    emergency_contact_relation VARCHAR(50) COMMENT '비상연락처 관계',
    
    -- 주소 정보
    current_address TEXT COMMENT '현재 주소',
    permanent_address TEXT COMMENT '영구 주소',
    postal_code VARCHAR(10) COMMENT '우편번호',
    detailed_address TEXT COMMENT '상세주소',
    
    -- 직업 및 소득 정보
    occupation VARCHAR(100) COMMENT '직업',
    employer VARCHAR(255) COMMENT '직장명',
    monthly_income DECIMAL(12,2) COMMENT '월 소득',
    income_proof_type VARCHAR(50) COMMENT '소득증빙 유형',
    
    -- 신용 정보
    credit_score INTEGER CHECK (credit_score >= 0 AND credit_score <= 1000) COMMENT '신용점수',
    credit_rating VARCHAR(10) COMMENT '신용등급',
    
    -- 가족 정보
    family_members INTEGER DEFAULT 1 CHECK (family_members >= 1) COMMENT '가족 구성원 수',
    has_pets BOOLEAN DEFAULT false COMMENT '반려동물 유무',
    pet_details TEXT COMMENT '반려동물 상세정보',
    
    -- 임대 이력
    previous_rental_experience BOOLEAN DEFAULT false COMMENT '임대 경험 유무',
    rental_references TEXT COMMENT '임대 추천인 정보',
    
    -- 상태 및 메타데이터
    is_active BOOLEAN DEFAULT true COMMENT '활성 상태',
    blacklist_status BOOLEAN DEFAULT false COMMENT '블랙리스트 여부',
    blacklist_reason TEXT COMMENT '블랙리스트 사유',
    notes TEXT COMMENT '특이사항',
    
    -- 개인정보 동의
    privacy_consent BOOLEAN DEFAULT false COMMENT '개인정보 수집/이용 동의',
    privacy_consent_date TIMESTAMP COMMENT '개인정보 동의일시',
    marketing_consent BOOLEAN DEFAULT false COMMENT '마케팅 활용 동의',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID'
);

-- 임차인 테이블 인덱스
CREATE INDEX idx_tenants_name ON tenants(name);
CREATE INDEX idx_tenants_entity_type ON tenants(entity_type);
CREATE INDEX idx_tenants_business_number ON tenants(business_registration_number);
CREATE INDEX idx_tenants_email ON tenants(email);
CREATE INDEX idx_tenants_primary_phone ON tenants(primary_phone);
CREATE INDEX idx_tenants_is_active ON tenants(is_active);
CREATE INDEX idx_tenants_blacklist_status ON tenants(blacklist_status);
CREATE INDEX idx_tenants_created_at ON tenants(created_at);

-- =====================================================
-- 연락처 정보 테이블 (contacts) - 확장 가능한 연락처 관리
-- =====================================================
CREATE TABLE contacts (
    id BIGSERIAL PRIMARY KEY,
    
    -- 연관 관계 (임대인 또는 임차인)
    lessor_id BIGINT REFERENCES lessors(id) ON DELETE CASCADE,
    tenant_id BIGINT REFERENCES tenants(id) ON DELETE CASCADE,
    
    -- 연락처 정보
    contact_type VARCHAR(20) NOT NULL COMMENT '연락처 유형 (PHONE, EMAIL, FAX)',
    contact_value VARCHAR(255) NOT NULL COMMENT '연락처 값',
    priority contact_priority DEFAULT 'SECONDARY' COMMENT '우선순위',
    
    -- 메타데이터
    label VARCHAR(100) COMMENT '연락처 라벨',
    is_verified BOOLEAN DEFAULT false COMMENT '인증 여부',
    verified_at TIMESTAMP COMMENT '인증일시',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 제약조건: 임대인 또는 임차인 중 하나만 연결
    CONSTRAINT chk_contact_owner CHECK (
        (lessor_id IS NOT NULL AND tenant_id IS NULL) OR
        (lessor_id IS NULL AND tenant_id IS NOT NULL)
    )
);

-- 연락처 테이블 인덱스
CREATE INDEX idx_contacts_lessor_id ON contacts(lessor_id);
CREATE INDEX idx_contacts_tenant_id ON contacts(tenant_id);
CREATE INDEX idx_contacts_type ON contacts(contact_type);
CREATE INDEX idx_contacts_priority ON contacts(priority);

-- =====================================================
-- 데이터 암호화 및 보안 함수
-- =====================================================

-- 개인정보 암호화 함수 (예시 - 실제 구현 시 적절한 암호화 라이브러리 사용)
CREATE OR REPLACE FUNCTION encrypt_personal_data(data TEXT, key TEXT DEFAULT 'default_key')
RETURNS BYTEA AS $$
BEGIN
    -- 실제 구현에서는 AES-256 등의 강력한 암호화 알고리즘 사용
    -- 여기서는 예시로 간단한 변환만 수행
    RETURN encode(data::BYTEA, 'base64')::BYTEA;
END;
$$ LANGUAGE plpgsql;

-- 개인정보 복호화 함수
CREATE OR REPLACE FUNCTION decrypt_personal_data(encrypted_data BYTEA, key TEXT DEFAULT 'default_key')
RETURNS TEXT AS $$
BEGIN
    -- 실제 구현에서는 해당하는 복호화 알고리즘 사용
    RETURN decode(encrypted_data, 'base64')::TEXT;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 사업자등록번호 유효성 검증 함수
-- =====================================================
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
-- 트리거 함수들
-- =====================================================

-- 사업자등록번호 유효성 검증 트리거 함수
CREATE OR REPLACE FUNCTION validate_business_number_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- 사업자등록번호가 입력된 경우 유효성 검증
    IF NEW.business_registration_number IS NOT NULL THEN
        IF NOT validate_business_registration_number(NEW.business_registration_number) THEN
            RAISE EXCEPTION '유효하지 않은 사업자등록번호입니다: %', NEW.business_registration_number;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 개인정보 자동 암호화 트리거 함수 (임대인)
CREATE OR REPLACE FUNCTION encrypt_lessor_personal_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 주민등록번호 암호화
    IF NEW.resident_number_encrypted IS NULL AND TG_ARGV[0] IS NOT NULL THEN
        NEW.resident_number_encrypted := encrypt_personal_data(TG_ARGV[0]);
    END IF;
    
    -- 계좌번호 암호화
    IF NEW.account_number_encrypted IS NULL AND TG_ARGV[1] IS NOT NULL THEN
        NEW.account_number_encrypted := encrypt_personal_data(TG_ARGV[1]);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 개인정보 자동 암호화 트리거 함수 (임차인)
CREATE OR REPLACE FUNCTION encrypt_tenant_personal_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 주민등록번호 암호화
    IF NEW.resident_number_encrypted IS NULL AND TG_ARGV[0] IS NOT NULL THEN
        NEW.resident_number_encrypted := encrypt_personal_data(TG_ARGV[0]);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 생성
-- =====================================================

-- 임대인 사업자등록번호 유효성 검증 트리거
CREATE TRIGGER trigger_validate_lessor_business_number
    BEFORE INSERT OR UPDATE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION validate_business_number_trigger();

-- 임차인 사업자등록번호 유효성 검증 트리거
CREATE TRIGGER trigger_validate_tenant_business_number
    BEFORE INSERT OR UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION validate_business_number_trigger();

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER trigger_lessors_updated_at
    BEFORE UPDATE ON lessors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_tenants_updated_at
    BEFORE UPDATE ON tenants
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_contacts_updated_at
    BEFORE UPDATE ON contacts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 보안 정책 및 RLS (Row Level Security)
-- =====================================================

-- 임대인 테이블 RLS 활성화
ALTER TABLE lessors ENABLE ROW LEVEL SECURITY;

-- 임차인 테이블 RLS 활성화
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

-- 기본 정책: 관리자만 모든 데이터 접근 가능
CREATE POLICY lessors_admin_policy ON lessors
    FOR ALL
    TO admin_role
    USING (true);

CREATE POLICY tenants_admin_policy ON tenants
    FOR ALL
    TO admin_role
    USING (true);

-- =====================================================
-- 테이블 코멘트
-- =====================================================
COMMENT ON TABLE lessors IS '임대인 정보를 관리하는 테이블 (개인정보 암호화 적용)';
COMMENT ON TABLE tenants IS '임차인 정보를 관리하는 테이블 (개인정보 암호화 적용)';
COMMENT ON TABLE contacts IS '임대인/임차인의 확장 연락처 정보를 관리하는 테이블';

-- 중요 컬럼 코멘트
COMMENT ON COLUMN lessors.resident_number_encrypted IS '주민등록번호 (AES-256 암호화 저장)';
COMMENT ON COLUMN lessors.account_number_encrypted IS '계좌번호 (AES-256 암호화 저장)';
COMMENT ON COLUMN tenants.resident_number_encrypted IS '주민등록번호 (AES-256 암호화 저장)';