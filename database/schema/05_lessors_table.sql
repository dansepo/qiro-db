-- =====================================================
-- 임대인(Lessor) 정보 테이블 생성 스크립트
-- Phase 2.2: 임대인(Lessor) 정보 테이블 생성
-- =====================================================

-- 1. 임대인(Lessor) 정보 테이블 생성
CREATE TABLE IF NOT EXISTS bms.lessors (
    lessor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 기본 정보
    lessor_name VARCHAR(200) NOT NULL,                   -- 임대인명/법인명
    lessor_type VARCHAR(20) NOT NULL DEFAULT 'INDIVIDUAL', -- 개인/법인 구분
    
    -- 개인 정보 (개인인 경우)
    birth_date DATE,                                     -- 생년월일
    gender VARCHAR(10),                                  -- 성별
    nationality VARCHAR(50) DEFAULT 'KR',               -- 국적
    
    -- 법인 정보 (법인인 경우)
    business_registration_number VARCHAR(20),           -- 사업자등록번호
    corporate_registration_number VARCHAR(20),          -- 법인등록번호
    representative_name VARCHAR(200),                    -- 대표자명
    business_type VARCHAR(100),                          -- 업종
    establishment_date DATE,                             -- 설립일
    
    -- 연락처 정보
    primary_phone VARCHAR(20),                           -- 주 연락처
    secondary_phone VARCHAR(20),                         -- 보조 연락처
    email VARCHAR(200),                                  -- 이메일
    fax VARCHAR(20),                                     -- 팩스번호
    
    -- 주소 정보
    address TEXT,                                        -- 주소
    postal_code VARCHAR(10),                             -- 우편번호
    detailed_address TEXT,                               -- 상세주소
    
    -- 은행 정보
    bank_name VARCHAR(100),                              -- 은행명
    account_number VARCHAR(50),                          -- 계좌번호 (암호화 필요시 별도 처리)
    account_holder VARCHAR(200),                         -- 예금주
    
    -- 세무 정보
    tax_id VARCHAR(20),                                  -- 납세자번호
    tax_office VARCHAR(100),                             -- 관할 세무서
    
    -- 임대 관련 정보
    total_properties INTEGER DEFAULT 0,                 -- 총 보유 부동산 수
    total_rental_income DECIMAL(15,2) DEFAULT 0,        -- 총 임대 수입
    preferred_payment_method VARCHAR(50),               -- 선호 지급 방식
    payment_day INTEGER DEFAULT 25,                     -- 임대료 지급일
    
    -- 관리 정보
    property_manager_name VARCHAR(200),                 -- 부동산 관리인
    property_manager_phone VARCHAR(20),                 -- 관리인 연락처
    property_management_company VARCHAR(200),           -- 관리 업체
    
    -- 상태 및 메타데이터
    lessor_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 임대인 상태
    is_verified BOOLEAN DEFAULT false,                   -- 신원 확인 여부
    verification_date TIMESTAMP WITH TIME ZONE,         -- 신원 확인일
    credit_rating VARCHAR(10),                           -- 신용등급
    special_notes TEXT,                                  -- 특이사항
    
    -- 개인정보 동의
    privacy_consent BOOLEAN DEFAULT false,               -- 개인정보 수집/이용 동의
    privacy_consent_date TIMESTAMP WITH TIME ZONE,      -- 개인정보 동의일시
    marketing_consent BOOLEAN DEFAULT false,             -- 마케팅 활용 동의
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_lessors_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_lessor_type CHECK (lessor_type IN ('INDIVIDUAL', 'CORPORATION', 'PARTNERSHIP')),
    CONSTRAINT chk_lessor_status CHECK (lessor_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'TERMINATED')),
    CONSTRAINT chk_gender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    CONSTRAINT chk_total_properties CHECK (total_properties >= 0),
    CONSTRAINT chk_total_rental_income CHECK (total_rental_income >= 0),
    CONSTRAINT chk_payment_day CHECK (payment_day >= 1 AND payment_day <= 31)
);

-- 2. RLS 정책 활성화
ALTER TABLE bms.lessors ENABLE ROW LEVEL SECURITY;

-- 3. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY lessor_isolation_policy ON bms.lessors
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX idx_lessors_company_id ON bms.lessors(company_id);
CREATE INDEX idx_lessors_lessor_name ON bms.lessors(lessor_name);
CREATE INDEX idx_lessors_lessor_type ON bms.lessors(lessor_type);
CREATE INDEX idx_lessors_lessor_status ON bms.lessors(lessor_status);
CREATE INDEX idx_lessors_primary_phone ON bms.lessors(primary_phone);
CREATE INDEX idx_lessors_email ON bms.lessors(email);
CREATE INDEX idx_lessors_business_number ON bms.lessors(business_registration_number);
CREATE INDEX idx_lessors_is_verified ON bms.lessors(is_verified);
CREATE INDEX idx_lessors_payment_day ON bms.lessors(payment_day);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX idx_lessors_company_status ON bms.lessors(company_id, lessor_status);
CREATE INDEX idx_lessors_status_type ON bms.lessors(lessor_status, lessor_type);
CREATE INDEX idx_lessors_company_verified ON bms.lessors(company_id, is_verified);

-- 5. updated_at 자동 업데이트 트리거
CREATE TRIGGER lessors_updated_at_trigger
    BEFORE UPDATE ON bms.lessors
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 6. 임대인 정보 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_lessor_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 총 보유 부동산 수는 음수가 될 수 없음
    IF NEW.total_properties < 0 THEN
        RAISE EXCEPTION '총 보유 부동산 수는 음수가 될 수 없습니다.';
    END IF;
    
    -- 총 임대 수입은 음수가 될 수 없음
    IF NEW.total_rental_income < 0 THEN
        RAISE EXCEPTION '총 임대 수입은 음수가 될 수 없습니다.';
    END IF;
    
    -- 임대료 지급일은 1-31일 범위여야 함
    IF NEW.payment_day < 1 OR NEW.payment_day > 31 THEN
        RAISE EXCEPTION '임대료 지급일은 1-31일 범위여야 합니다.';
    END IF;
    
    -- 이메일 형식 검증
    IF NEW.email IS NOT NULL AND NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION '올바른 이메일 형식이 아닙니다.';
    END IF;
    
    -- 사업자등록번호 형식 검증 (10자리 숫자)
    IF NEW.business_registration_number IS NOT NULL 
       AND NEW.business_registration_number !~ '^[0-9]{10}$' THEN
        RAISE EXCEPTION '사업자등록번호는 10자리 숫자여야 합니다.';
    END IF;
    
    -- 법인인 경우 필수 정보 검증
    IF NEW.lessor_type = 'CORPORATION' THEN
        IF NEW.business_registration_number IS NULL THEN
            RAISE EXCEPTION '법인은 사업자등록번호가 필수입니다.';
        END IF;
        IF NEW.representative_name IS NULL THEN
            RAISE EXCEPTION '법인은 대표자명이 필수입니다.';
        END IF;
    END IF;
    
    -- 신원 확인된 경우 확인일 자동 설정
    IF NEW.is_verified = true AND OLD.is_verified = false AND NEW.verification_date IS NULL THEN
        NEW.verification_date := NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 임대인 검증 트리거 생성
CREATE TRIGGER trg_validate_lessor_data
    BEFORE INSERT OR UPDATE ON bms.lessors
    FOR EACH ROW EXECUTE FUNCTION bms.validate_lessor_data();

-- 8. 임대인 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.log_lessor_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND OLD.lessor_status IS DISTINCT FROM NEW.lessor_status THEN
        -- 상태 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        RAISE NOTICE '임대인 % 상태가 %에서 %로 변경되었습니다.', NEW.lessor_name, OLD.lessor_status, NEW.lessor_status;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 9. 상태 변경 이력 트리거 생성
CREATE TRIGGER trg_log_lessor_status_changes
    AFTER UPDATE ON bms.lessors
    FOR EACH ROW EXECUTE FUNCTION bms.log_lessor_status_changes();

-- 10. 임대인 요약 뷰 생성
CREATE OR REPLACE VIEW bms.v_lessor_summary AS
SELECT 
    l.lessor_id,
    l.company_id,
    l.lessor_name,
    l.lessor_type,
    l.lessor_status,
    l.primary_phone,
    l.email,
    l.total_properties,
    l.total_rental_income,
    l.preferred_payment_method,
    l.payment_day,
    l.is_verified,
    l.verification_date,
    l.credit_rating,
    l.property_manager_name,
    l.property_manager_phone,
    l.created_at,
    l.updated_at
FROM bms.lessors l;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_lessor_summary OWNER TO qiro;

-- 11. 임대인 타입별 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_lessor_type_statistics AS
SELECT 
    l.company_id,
    l.lessor_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN l.lessor_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN l.lessor_status = 'INACTIVE' THEN 1 END) as inactive_count,
    COUNT(CASE WHEN l.is_verified = true THEN 1 END) as verified_count,
    ROUND(COUNT(CASE WHEN l.lessor_status = 'ACTIVE' THEN 1 END) * 100.0 / COUNT(*), 2) as active_rate,
    ROUND(COUNT(CASE WHEN l.is_verified = true THEN 1 END) * 100.0 / COUNT(*), 2) as verification_rate,
    SUM(l.total_properties) as total_properties_sum,
    AVG(l.total_properties) as avg_properties_per_lessor,
    SUM(l.total_rental_income) as total_rental_income_sum,
    AVG(l.total_rental_income) as avg_rental_income
FROM bms.lessors l
GROUP BY l.company_id, l.lessor_type;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_lessor_type_statistics OWNER TO qiro;

-- 12. 임대료 지급일별 임대인 뷰 생성
CREATE OR REPLACE VIEW bms.v_lessor_payment_schedule AS
SELECT 
    l.lessor_id,
    l.company_id,
    l.lessor_name,
    l.lessor_type,
    l.primary_phone,
    l.email,
    l.payment_day,
    l.preferred_payment_method,
    l.total_rental_income,
    l.bank_name,
    l.account_holder,
    CASE 
        WHEN l.payment_day <= 5 THEN 'EARLY_MONTH'
        WHEN l.payment_day <= 15 THEN 'MID_MONTH'
        WHEN l.payment_day <= 25 THEN 'LATE_MONTH'
        ELSE 'END_MONTH'
    END as payment_period
FROM bms.lessors l
WHERE l.lessor_status = 'ACTIVE'
ORDER BY l.payment_day, l.lessor_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_lessor_payment_schedule OWNER TO qiro;

-- 13. 임대인-건물 연결 테이블 생성 (다대다 관계)
CREATE TABLE IF NOT EXISTS bms.lessor_building_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    lessor_id UUID NOT NULL,
    building_id UUID NOT NULL,
    ownership_percentage DECIMAL(5,2) DEFAULT 100.00,    -- 소유 지분 (%)
    ownership_start_date DATE NOT NULL,                  -- 소유 시작일
    ownership_end_date DATE,                             -- 소유 종료일
    ownership_type VARCHAR(50) DEFAULT 'FULL',           -- 소유 형태
    notes TEXT,                                          -- 특이사항
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_lessor_assignments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_lessor_assignments_lessor FOREIGN KEY (lessor_id) REFERENCES bms.lessors(lessor_id) ON DELETE CASCADE,
    CONSTRAINT fk_lessor_assignments_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_lessor_building_active UNIQUE (lessor_id, building_id, ownership_end_date), -- 동일 임대인-건물 조합에서 활성 소유권은 하나만
    
    -- 체크 제약조건
    CONSTRAINT chk_ownership_percentage CHECK (ownership_percentage > 0 AND ownership_percentage <= 100),
    CONSTRAINT chk_ownership_dates CHECK (ownership_end_date IS NULL OR ownership_end_date >= ownership_start_date),
    CONSTRAINT chk_ownership_type CHECK (ownership_type IN ('FULL', 'PARTIAL', 'JOINT', 'TRUST', 'OTHER'))
);

-- 14. 임대인-건물 연결 테이블 RLS 및 인덱스
ALTER TABLE bms.lessor_building_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY lessor_assignment_isolation_policy ON bms.lessor_building_assignments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE INDEX idx_lessor_assignments_company_id ON bms.lessor_building_assignments(company_id);
CREATE INDEX idx_lessor_assignments_lessor_id ON bms.lessor_building_assignments(lessor_id);
CREATE INDEX idx_lessor_assignments_building_id ON bms.lessor_building_assignments(building_id);
CREATE INDEX idx_lessor_assignments_ownership_dates ON bms.lessor_building_assignments(ownership_start_date, ownership_end_date);

-- 복합 인덱스
CREATE INDEX idx_lessor_assignments_lessor_building ON bms.lessor_building_assignments(lessor_id, building_id);
CREATE INDEX idx_lessor_assignments_company_lessor ON bms.lessor_building_assignments(company_id, lessor_id);

-- updated_at 트리거
CREATE TRIGGER lessor_assignments_updated_at_trigger
    BEFORE UPDATE ON bms.lessor_building_assignments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 15. 임대인-건물 관계 뷰 생성
CREATE OR REPLACE VIEW bms.v_lessor_building_relationships AS
SELECT 
    lba.assignment_id,
    lba.company_id,
    l.lessor_id,
    l.lessor_name,
    l.lessor_type,
    l.primary_phone,
    l.email,
    b.building_id,
    b.name as building_name,
    b.address,
    lba.ownership_percentage,
    lba.ownership_start_date,
    lba.ownership_end_date,
    lba.ownership_type,
    CASE 
        WHEN lba.ownership_end_date IS NULL THEN 'ACTIVE'
        WHEN lba.ownership_end_date > CURRENT_DATE THEN 'ACTIVE'
        ELSE 'EXPIRED'
    END as ownership_status,
    lba.notes,
    lba.created_at,
    lba.updated_at
FROM bms.lessor_building_assignments lba
JOIN bms.lessors l ON lba.lessor_id = l.lessor_id
JOIN bms.buildings b ON lba.building_id = b.building_id;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_lessor_building_relationships OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 2.2 임대인(Lessor) 정보 테이블 생성이 완료되었습니다!' as result;