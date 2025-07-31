-- =====================================================
-- Buildings 테이블 멀티테넌시 마이그레이션
-- 작성일: 2025-01-30
-- 설명: 기존 Buildings 테이블에 organization_id 추가 및 RLS 정책 적용
-- =====================================================

-- 1. 기존 Buildings 테이블에 company_id 컬럼 추가
ALTER TABLE buildings 
ADD COLUMN company_id UUID;

-- 2. 외래키 제약조건 추가 (companies 테이블이 존재한다고 가정)
-- 먼저 companies 테이블이 존재하는지 확인하고 없으면 생성
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'companies') THEN
        -- Companies 테이블이 없으면 생성 (이미 생성되어 있어야 함)
        RAISE EXCEPTION 'Companies 테이블이 존재하지 않습니다. 먼저 companies 테이블을 생성해주세요.';
    END IF;
END $$;

-- 3. 기존 데이터 마이그레이션을 위한 임시 조직 생성 (개발/테스트 환경용)
-- 실제 운영 환경에서는 실제 조직 데이터로 매핑해야 함
DO $$
DECLARE
    default_org_id UUID;
BEGIN
    -- 기본 조직이 없으면 생성 (개발/테스트용)
    SELECT company_id INTO default_org_id 
    FROM companies 
    WHERE business_registration_number = '000-00-00000' 
    LIMIT 1;
    
    IF default_org_id IS NULL THEN
        INSERT INTO companies (
            company_id,
            business_registration_number,
            company_name,
            representative_name,
            business_address,
            contact_phone,
            contact_email,
            business_type,
            establishment_date,
            verification_status,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            '000-00-00000',
            '기본 조직 (마이그레이션용)',
            '시스템 관리자',
            '서울특별시 강남구',
            '02-0000-0000',
            'admin@qiro.co.kr',
            '소프트웨어 개발업',
            '2025-01-01',
            'VERIFIED',
            now(),
            now()
        ) RETURNING company_id INTO default_org_id;
    END IF;
    
    -- 기존 buildings 데이터에 기본 조직 ID 할당
    UPDATE buildings 
    SET company_id = default_org_id 
    WHERE company_id IS NULL;
END $$;

-- 4. company_id를 NOT NULL로 변경
ALTER TABLE buildings 
ALTER COLUMN company_id SET NOT NULL;

-- 5. 외래키 제약조건 추가
ALTER TABLE buildings 
ADD CONSTRAINT fk_buildings_company_id 
FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE;

-- 6. 인덱스 생성 (성능 최적화)
CREATE INDEX idx_buildings_company_id ON buildings(company_id);
CREATE INDEX idx_buildings_company_status ON buildings(company_id, status);
CREATE INDEX idx_buildings_company_type ON buildings(company_id, building_type);

-- 7. Row Level Security (RLS) 정책 적용
ALTER TABLE buildings ENABLE ROW LEVEL SECURITY;

-- 8. 애플리케이션 역할 생성 (없으면)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'application_role') THEN
        CREATE ROLE application_role;
    END IF;
END $$;

-- 9. RLS 정책 생성
CREATE POLICY buildings_org_isolation_policy ON buildings
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 10. 기본 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON buildings TO application_role;

-- 11. 데이터 무결성 검증 함수
CREATE OR REPLACE FUNCTION verify_buildings_migration()
RETURNS TABLE (
    total_buildings BIGINT,
    buildings_with_company_id BIGINT,
    buildings_without_company_id BIGINT,
    unique_companies BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_buildings,
        COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END) as buildings_with_company_id,
        COUNT(CASE WHEN company_id IS NULL THEN 1 END) as buildings_without_company_id,
        COUNT(DISTINCT company_id) as unique_companies
    FROM buildings;
END;
$$ LANGUAGE plpgsql;

-- 12. 마이그레이션 검증 실행
SELECT * FROM verify_buildings_migration();

-- 13. 조직별 건물 통계 조회 함수
CREATE OR REPLACE FUNCTION get_buildings_by_organization()
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    building_count BIGINT,
    active_buildings BIGINT,
    total_units BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.company_id,
        c.company_name,
        COUNT(b.id) as building_count,
        COUNT(CASE WHEN b.status = 'ACTIVE' THEN 1 END) as active_buildings,
        COALESCE(SUM(b.total_units), 0) as total_units
    FROM companies c
    LEFT JOIN buildings b ON c.company_id = b.company_id
    GROUP BY c.company_id, c.company_name
    ORDER BY building_count DESC;
END;
$$ LANGUAGE plpgsql;

-- 14. 마이그레이션 완료 로그
INSERT INTO migration_log (
    migration_name,
    description,
    executed_at,
    status
) VALUES (
    'buildings_multitenancy_migration',
    'Buildings 테이블에 organization_id 추가 및 RLS 정책 적용',
    now(),
    'COMPLETED'
) ON CONFLICT DO NOTHING;

-- 15. 마이그레이션 로그 테이블이 없으면 생성
CREATE TABLE IF NOT EXISTS migration_log (
    id BIGSERIAL PRIMARY KEY,
    migration_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    executed_at TIMESTAMP DEFAULT now(),
    status VARCHAR(20) DEFAULT 'PENDING',
    error_message TEXT
);

-- 마이그레이션 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== Buildings 테이블 멀티테넌시 마이그레이션 완료 ===';
    RAISE NOTICE '1. company_id 컬럼 추가 완료';
    RAISE NOTICE '2. 외래키 제약조건 추가 완료';
    RAISE NOTICE '3. 기존 데이터 마이그레이션 완료';
    RAISE NOTICE '4. RLS 정책 적용 완료';
    RAISE NOTICE '5. 인덱스 생성 완료';
    RAISE NOTICE '6. 검증 함수 생성 완료';
    RAISE NOTICE '=== 마이그레이션 검증을 위해 verify_buildings_migration() 함수를 실행하세요 ===';
END $$;