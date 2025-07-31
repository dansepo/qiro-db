-- =====================================================
-- 입주자(Tenant) 정보 테이블 생성 스크립트
-- Phase 2.1: 입주자(Tenant) 정보 테이블 생성
-- =====================================================

-- 1. 입주자(Tenant) 정보 테이블 생성
CREATE TABLE IF NOT EXISTS bms.tenants (
    tenant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                    -- 현재 거주 건물 (NULL 가능)
    unit_id UUID,                                        -- 현재 거주 호실 (NULL 가능)
    
    -- 기본 정보
    tenant_name VARCHAR(200) NOT NULL,                   -- 입주자명/법인명
    tenant_type VARCHAR(20) NOT NULL DEFAULT 'INDIVIDUAL', -- 개인/법인 구분
    
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
    emergency_contact_name VARCHAR(200),                 -- 비상연락처 이름
    emergency_contact_phone VARCHAR(20),                 -- 비상연락처 번호
    emergency_contact_relation VARCHAR(50),              -- 비상연락처 관계
    
    -- 주소 정보
    current_address TEXT,                                -- 현재 주소
    permanent_address TEXT,                              -- 영구 주소
    postal_code VARCHAR(10),                             -- 우편번호
    detailed_address TEXT,                               -- 상세주소
    
    -- 직업 및 소득 정보
    occupation VARCHAR(100),                             -- 직업
    employer VARCHAR(200),                               -- 직장명
    monthly_income DECIMAL(12,2),                        -- 월 소득
    income_proof_type VARCHAR(50),                       -- 소득증빙 유형
    
    -- 신용 정보
    credit_score INTEGER,                                -- 신용점수
    credit_rating VARCHAR(10),                           -- 신용등급
    
    -- 가족 정보
    family_members INTEGER DEFAULT 1,                   -- 가족 구성원 수
    has_pets BOOLEAN DEFAULT false,                      -- 반려동물 유무
    pet_details TEXT,                                    -- 반려동물 상세정보
    
    -- 임대 이력
    previous_rental_experience BOOLEAN DEFAULT false,   -- 임대 경험 유무
    rental_references TEXT,                              -- 임대 추천인 정보
    
    -- 입주 정보
    move_in_date DATE,                                   -- 입주일
    move_out_date DATE,                                  -- 퇴거일
    lease_start_date DATE,                               -- 임대차 시작일
    lease_end_date DATE,                                 -- 임대차 종료일
    deposit_amount DECIMAL(15,2),                        -- 보증금
    monthly_rent DECIMAL(12,2),                          -- 월 임대료
    
    -- 상태 및 메타데이터
    tenant_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 입주자 상태
    is_blacklisted BOOLEAN DEFAULT false,                -- 블랙리스트 여부
    blacklist_reason TEXT,                               -- 블랙리스트 사유
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
    CONSTRAINT fk_tenants_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_tenants_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_tenants_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_tenant_type CHECK (tenant_type IN ('INDIVIDUAL', 'CORPORATION', 'PARTNERSHIP')),
    CONSTRAINT chk_tenant_status CHECK (tenant_status IN ('ACTIVE', 'INACTIVE', 'MOVED_OUT', 'BLACKLISTED')),
    CONSTRAINT chk_gender CHECK (gender IN ('MALE', 'FEMALE', 'OTHER')),
    CONSTRAINT chk_family_members CHECK (family_members >= 1),
    CONSTRAINT chk_credit_score CHECK (credit_score IS NULL OR (credit_score >= 0 AND credit_score <= 1000)),
    CONSTRAINT chk_lease_dates CHECK (lease_end_date IS NULL OR lease_start_date IS NULL OR lease_end_date >= lease_start_date),
    CONSTRAINT chk_move_dates CHECK (move_out_date IS NULL OR move_in_date IS NULL OR move_out_date >= move_in_date),
    CONSTRAINT chk_deposit_amount CHECK (deposit_amount IS NULL OR deposit_amount >= 0),
    CONSTRAINT chk_monthly_rent CHECK (monthly_rent IS NULL OR monthly_rent >= 0),
    CONSTRAINT chk_monthly_income CHECK (monthly_income IS NULL OR monthly_income >= 0)
);

-- 2. RLS 정책 활성화
ALTER TABLE bms.tenants ENABLE ROW LEVEL SECURITY;

-- 3. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY tenant_isolation_policy ON bms.tenants
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX idx_tenants_company_id ON bms.tenants(company_id);
CREATE INDEX idx_tenants_building_id ON bms.tenants(building_id);
CREATE INDEX idx_tenants_unit_id ON bms.tenants(unit_id);
CREATE INDEX idx_tenants_tenant_name ON bms.tenants(tenant_name);
CREATE INDEX idx_tenants_tenant_type ON bms.tenants(tenant_type);
CREATE INDEX idx_tenants_tenant_status ON bms.tenants(tenant_status);
CREATE INDEX idx_tenants_primary_phone ON bms.tenants(primary_phone);
CREATE INDEX idx_tenants_email ON bms.tenants(email);
CREATE INDEX idx_tenants_business_number ON bms.tenants(business_registration_number);
CREATE INDEX idx_tenants_move_in_date ON bms.tenants(move_in_date);
CREATE INDEX idx_tenants_lease_end_date ON bms.tenants(lease_end_date);
CREATE INDEX idx_tenants_is_blacklisted ON bms.tenants(is_blacklisted);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX idx_tenants_company_building ON bms.tenants(company_id, building_id);
CREATE INDEX idx_tenants_building_unit ON bms.tenants(building_id, unit_id);
CREATE INDEX idx_tenants_status_type ON bms.tenants(tenant_status, tenant_type);
CREATE INDEX idx_tenants_company_status ON bms.tenants(company_id, tenant_status);

-- 5. updated_at 자동 업데이트 트리거
CREATE TRIGGER tenants_updated_at_trigger
    BEFORE UPDATE ON bms.tenants
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 6. 입주자 정보 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_tenant_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 가족 구성원 수는 1 이상이어야 함
    IF NEW.family_members < 1 THEN
        RAISE EXCEPTION '가족 구성원 수는 1 이상이어야 합니다.';
    END IF;
    
    -- 신용점수 범위 검증
    IF NEW.credit_score IS NOT NULL AND (NEW.credit_score < 0 OR NEW.credit_score > 1000) THEN
        RAISE EXCEPTION '신용점수는 0-1000 범위여야 합니다.';
    END IF;
    
    -- 임대차 기간 검증
    IF NEW.lease_start_date IS NOT NULL AND NEW.lease_end_date IS NOT NULL 
       AND NEW.lease_end_date < NEW.lease_start_date THEN
        RAISE EXCEPTION '임대차 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 입주/퇴거일 검증
    IF NEW.move_in_date IS NOT NULL AND NEW.move_out_date IS NOT NULL 
       AND NEW.move_out_date < NEW.move_in_date THEN
        RAISE EXCEPTION '퇴거일은 입주일보다 늦어야 합니다.';
    END IF;
    
    -- 이메일 형식 검증
    IF NEW.email IS NOT NULL AND NEW.email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION '올바른 이메일 형식이 아닙니다.';
    END IF;
    
    -- 퇴거한 입주자는 상태를 MOVED_OUT으로 설정
    IF NEW.move_out_date IS NOT NULL AND NEW.tenant_status = 'ACTIVE' THEN
        NEW.tenant_status := 'MOVED_OUT';
    END IF;
    
    -- 블랙리스트 상태 동기화
    IF NEW.is_blacklisted = true AND NEW.tenant_status != 'BLACKLISTED' THEN
        NEW.tenant_status := 'BLACKLISTED';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 입주자 검증 트리거 생성
CREATE TRIGGER trg_validate_tenant_data
    BEFORE INSERT OR UPDATE ON bms.tenants
    FOR EACH ROW EXECUTE FUNCTION bms.validate_tenant_data();

-- 8. 입주자 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.log_tenant_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND OLD.tenant_status IS DISTINCT FROM NEW.tenant_status THEN
        -- 상태 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        RAISE NOTICE '입주자 % 상태가 %에서 %로 변경되었습니다.', NEW.tenant_name, OLD.tenant_status, NEW.tenant_status;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 9. 상태 변경 이력 트리거 생성
CREATE TRIGGER trg_log_tenant_status_changes
    AFTER UPDATE ON bms.tenants
    FOR EACH ROW EXECUTE FUNCTION bms.log_tenant_status_changes();

-- 10. 입주자 요약 뷰 생성
CREATE OR REPLACE VIEW bms.v_tenant_summary AS
SELECT 
    t.tenant_id,
    t.company_id,
    t.building_id,
    b.name as building_name,
    t.unit_id,
    u.unit_number,
    t.tenant_name,
    t.tenant_type,
    t.tenant_status,
    t.primary_phone,
    t.email,
    t.move_in_date,
    t.move_out_date,
    t.lease_start_date,
    t.lease_end_date,
    t.deposit_amount,
    t.monthly_rent,
    t.family_members,
    t.has_pets,
    t.is_blacklisted,
    t.created_at,
    t.updated_at
FROM bms.tenants t
LEFT JOIN bms.buildings b ON t.building_id = b.building_id
LEFT JOIN bms.units u ON t.unit_id = u.unit_id;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_tenant_summary OWNER TO qiro;

-- 11. 건물별 입주자 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_building_tenant_statistics AS
SELECT 
    t.building_id,
    b.name as building_name,
    t.company_id,
    COUNT(*) as total_tenants,
    COUNT(CASE WHEN t.tenant_status = 'ACTIVE' THEN 1 END) as active_tenants,
    COUNT(CASE WHEN t.tenant_status = 'MOVED_OUT' THEN 1 END) as moved_out_tenants,
    COUNT(CASE WHEN t.tenant_status = 'BLACKLISTED' THEN 1 END) as blacklisted_tenants,
    COUNT(CASE WHEN t.tenant_type = 'INDIVIDUAL' THEN 1 END) as individual_tenants,
    COUNT(CASE WHEN t.tenant_type = 'CORPORATION' THEN 1 END) as corporate_tenants,
    SUM(t.family_members) as total_family_members,
    COUNT(CASE WHEN t.has_pets = true THEN 1 END) as tenants_with_pets,
    SUM(CASE WHEN t.tenant_status = 'ACTIVE' THEN t.monthly_rent ELSE 0 END) as total_monthly_rent,
    AVG(CASE WHEN t.tenant_status = 'ACTIVE' THEN t.monthly_rent END) as avg_monthly_rent
FROM bms.tenants t
LEFT JOIN bms.buildings b ON t.building_id = b.building_id
GROUP BY t.building_id, b.name, t.company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_tenant_statistics OWNER TO qiro;

-- 12. 입주자 타입별 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_tenant_type_statistics AS
SELECT 
    t.company_id,
    t.tenant_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN t.tenant_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN t.tenant_status = 'MOVED_OUT' THEN 1 END) as moved_out_count,
    COUNT(CASE WHEN t.is_blacklisted = true THEN 1 END) as blacklisted_count,
    ROUND(COUNT(CASE WHEN t.tenant_status = 'ACTIVE' THEN 1 END) * 100.0 / COUNT(*), 2) as active_rate,
    AVG(t.family_members) as avg_family_members,
    AVG(CASE WHEN t.tenant_status = 'ACTIVE' THEN t.monthly_rent END) as avg_rent,
    AVG(t.monthly_income) as avg_income
FROM bms.tenants t
GROUP BY t.company_id, t.tenant_type;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_tenant_type_statistics OWNER TO qiro;

-- 13. 임대차 만료 예정 뷰 생성
CREATE OR REPLACE VIEW bms.v_lease_expiration_schedule AS
SELECT 
    t.tenant_id,
    t.company_id,
    t.building_id,
    b.name as building_name,
    t.unit_id,
    u.unit_number,
    t.tenant_name,
    t.primary_phone,
    t.email,
    t.lease_start_date,
    t.lease_end_date,
    t.monthly_rent,
    t.deposit_amount,
    CASE 
        WHEN t.lease_end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN t.lease_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN t.lease_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_IN_3_MONTHS'
        ELSE 'FUTURE'
    END as expiration_status,
    CURRENT_DATE - t.lease_end_date as days_expired
FROM bms.tenants t
LEFT JOIN bms.buildings b ON t.building_id = b.building_id
LEFT JOIN bms.units u ON t.unit_id = u.unit_id
WHERE t.tenant_status = 'ACTIVE' 
  AND t.lease_end_date IS NOT NULL
ORDER BY t.lease_end_date;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_lease_expiration_schedule OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 2.1 입주자(Tenant) 정보 테이블 생성이 완료되었습니다!' as result;