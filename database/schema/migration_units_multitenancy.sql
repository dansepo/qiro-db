-- =====================================================
-- Units 테이블 멀티테넌시 지원 강화
-- 작성일: 2025-01-30
-- 설명: Units 테이블의 RLS 정책 적용 및 조직별 데이터 격리
-- =====================================================

-- 1. Units 테이블에 RLS 활성화
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- 2. Units 테이블용 RLS 정책 생성 (Buildings를 통한 간접 조직 격리)
CREATE POLICY units_org_isolation_policy ON units
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 3. 조직별 호실 통계 조회 함수
CREATE OR REPLACE FUNCTION get_units_by_organization()
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    total_units BIGINT,
    available_units BIGINT,
    occupied_units BIGINT,
    maintenance_units BIGINT,
    total_area DECIMAL(15,2),
    average_rent DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.company_id,
        c.company_name,
        COUNT(u.id) as total_units,
        COUNT(CASE WHEN u.status = 'AVAILABLE' THEN 1 END) as available_units,
        COUNT(CASE WHEN u.status = 'OCCUPIED' THEN 1 END) as occupied_units,
        COUNT(CASE WHEN u.status = 'MAINTENANCE' THEN 1 END) as maintenance_units,
        COALESCE(SUM(u.total_area), 0) as total_area,
        COALESCE(AVG(u.monthly_rent), 0) as average_rent
    FROM companies c
    LEFT JOIN buildings b ON c.company_id = b.company_id
    LEFT JOIN units u ON b.id = u.building_id
    GROUP BY c.company_id, c.company_name
    ORDER BY total_units DESC;
END;
$$ LANGUAGE plpgsql;

-- 4. 건물별 호실 현황 조회 함수 (조직 컨텍스트 적용)
CREATE OR REPLACE FUNCTION get_units_by_building(p_building_id BIGINT)
RETURNS TABLE (
    unit_id BIGINT,
    unit_number VARCHAR(50),
    floor_number INTEGER,
    unit_type unit_type,
    area DECIMAL(10,2),
    status unit_status,
    monthly_rent DECIMAL(12,2),
    deposit DECIMAL(12,2)
) AS $$
BEGIN
    -- 조직 컨텍스트 검증
    IF NOT EXISTS (
        SELECT 1 FROM buildings 
        WHERE id = p_building_id 
        AND company_id = current_setting('app.current_company_id', true)::UUID
    ) THEN
        RAISE EXCEPTION '해당 건물에 대한 접근 권한이 없습니다.';
    END IF;
    
    RETURN QUERY
    SELECT 
        u.id,
        u.unit_number,
        u.floor_number,
        u.unit_type,
        u.area,
        u.status,
        u.monthly_rent,
        u.deposit
    FROM units u
    WHERE u.building_id = p_building_id
    ORDER BY u.floor_number, u.unit_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 인덱스 최적화 (조직별 쿼리 성능 향상)
CREATE INDEX IF NOT EXISTS idx_units_building_status ON units(building_id, status);
CREATE INDEX IF NOT EXISTS idx_units_building_type ON units(building_id, unit_type);
CREATE INDEX IF NOT EXISTS idx_units_building_floor ON units(building_id, floor_number);

-- 6. Units 테이블 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON units TO application_role;

-- 7. 데이터 무결성 검증 함수
CREATE OR REPLACE FUNCTION verify_units_multitenancy()
RETURNS TABLE (
    total_units BIGINT,
    units_with_valid_building BIGINT,
    orphaned_units BIGINT,
    organizations_with_units BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_units,
        COUNT(CASE WHEN b.id IS NOT NULL THEN 1 END) as units_with_valid_building,
        COUNT(CASE WHEN b.id IS NULL THEN 1 END) as orphaned_units,
        COUNT(DISTINCT b.company_id) as organizations_with_units
    FROM units u
    LEFT JOIN buildings b ON u.building_id = b.id;
END;
$$ LANGUAGE plpgsql;

-- 8. 마이그레이션 검증 실행
SELECT * FROM verify_units_multitenancy();

-- 9. 마이그레이션 로그 기록
INSERT INTO migration_log (
    migration_name,
    description,
    executed_at,
    status
) VALUES (
    'units_multitenancy_migration',
    'Units 테이블 RLS 정책 적용 및 조직별 데이터 격리',
    now(),
    'COMPLETED'
) ON CONFLICT (migration_name) DO UPDATE SET
    executed_at = now(),
    status = 'COMPLETED';

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== Units 테이블 멀티테넌시 지원 완료 ===';
    RAISE NOTICE '1. RLS 정책 적용 완료';
    RAISE NOTICE '2. 조직별 데이터 격리 설정 완료';
    RAISE NOTICE '3. 성능 최적화 인덱스 생성 완료';
    RAISE NOTICE '4. 조직별 통계 함수 생성 완료';
    RAISE NOTICE '5. 데이터 무결성 검증 함수 생성 완료';
END $$;