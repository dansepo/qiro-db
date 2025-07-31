-- =====================================================
-- 건물 관리 전용 인덱스 생성 스크립트
-- Phase 5.1: 건물 관리 전용 인덱스 생성
-- =====================================================

-- 1. 건물 관리 핵심 조회 패턴 분석 및 인덱스 생성

-- 1.1 건물 관련 조회 최적화 인덱스
-- 회사별 건물 목록 조회 (가장 빈번한 쿼리)
CREATE INDEX IF NOT EXISTS idx_buildings_company_active 
ON bms.buildings(company_id, is_active) 
WHERE is_active = true;

-- 건물 타입별 조회
CREATE INDEX IF NOT EXISTS idx_buildings_type_status 
ON bms.buildings(building_type, status) 
WHERE is_active = true;

-- 건물명 검색 (부분 일치 검색 지원)
CREATE INDEX IF NOT EXISTS idx_buildings_name_gin 
ON bms.buildings USING gin(to_tsvector('korean', name));

-- 건물 주소 검색
CREATE INDEX IF NOT EXISTS idx_buildings_address_gin 
ON bms.buildings USING gin(to_tsvector('korean', address));

-- 1.2 호실 관련 조회 최적화 인덱스
-- 건물별 호실 목록 조회 (핵심 쿼리)
CREATE INDEX IF NOT EXISTS idx_units_building_active 
ON bms.units(building_id, is_active) 
WHERE is_active = true;

-- 호실 상태별 조회 (공실, 입주 등)
CREATE INDEX IF NOT EXISTS idx_units_status_type 
ON bms.units(status, unit_type) 
WHERE is_active = true;

-- 호실 번호 검색
CREATE INDEX IF NOT EXISTS idx_units_number_building 
ON bms.units(building_id, unit_number) 
WHERE is_active = true;

-- 면적 범위 검색
CREATE INDEX IF NOT EXISTS idx_units_area_range 
ON bms.units(area) 
WHERE is_active = true AND area IS NOT NULL;

-- 1.3 입주자 관련 조회 최적화 인덱스
-- 회사별 입주자 목록
CREATE INDEX IF NOT EXISTS idx_tenants_company_active 
ON bms.tenants(company_id, is_active) 
WHERE is_active = true;

-- 입주자명 검색
CREATE INDEX IF NOT EXISTS idx_tenants_name_gin 
ON bms.tenants USING gin(to_tsvector('korean', name));

-- 연락처 검색
CREATE INDEX IF NOT EXISTS idx_tenants_phone_email 
ON bms.tenants(phone, email) 
WHERE is_active = true;

-- 입주일 범위 검색
CREATE INDEX IF NOT EXISTS idx_tenants_move_in_date 
ON bms.tenants(move_in_date) 
WHERE is_active = true AND move_in_date IS NOT NULL;-- 1.4 계약
 관련 조회 최적화 인덱스
-- 활성 계약 조회
CREATE INDEX IF NOT EXISTS idx_contracts_active_dates 
ON bms.contracts(is_active, start_date, end_date) 
WHERE is_active = true;

-- 계약 만료 예정 조회
CREATE INDEX IF NOT EXISTS idx_contracts_expiring 
ON bms.contracts(end_date) 
WHERE is_active = true AND end_date IS NOT NULL;

-- 임대료 범위 검색
CREATE INDEX IF NOT EXISTS idx_contracts_rent_range 
ON bms.contracts(monthly_rent) 
WHERE is_active = true AND monthly_rent IS NOT NULL;

-- 보증금 범위 검색
CREATE INDEX IF NOT EXISTS idx_contracts_deposit_range 
ON bms.contracts(deposit) 
WHERE is_active = true AND deposit IS NOT NULL;

-- 1.5 관리비 관련 조회 최적화 인덱스
-- 관리비 항목별 조회
CREATE INDEX IF NOT EXISTS idx_fee_items_company_active 
ON bms.fee_items(company_id, is_active) 
WHERE is_active = true;

-- 관리비 계산 방식별 조회
CREATE INDEX IF NOT EXISTS idx_fee_items_calculation_method 
ON bms.fee_items(calculation_method) 
WHERE is_active = true;

-- 2. 복합 인덱스 (다중 조건 검색 최적화)

-- 2.1 건물-호실 관계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_units_building_status_type 
ON bms.units(building_id, status, unit_type) 
WHERE is_active = true;

-- 2.2 입주자-호실 관계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_tenant_units_tenant_active 
ON bms.tenant_units(tenant_id, is_active) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_tenant_units_unit_active 
ON bms.tenant_units(unit_id, is_active) 
WHERE is_active = true;

-- 2.3 계약-당사자 관계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_contracts_tenant_lessor 
ON bms.contracts(tenant_id, lessor_id) 
WHERE is_active = true;

-- 2.4 시간 기반 조회 최적화
CREATE INDEX IF NOT EXISTS idx_contracts_company_dates 
ON bms.contracts(company_id, start_date, end_date) 
WHERE is_active = true;

-- 3. 성능 모니터링을 위한 통계 인덱스

-- 3.1 건물별 호실 수 집계용
CREATE INDEX IF NOT EXISTS idx_units_building_count 
ON bms.units(building_id) 
WHERE is_active = true;

-- 3.2 월별 계약 통계용
CREATE INDEX IF NOT EXISTS idx_contracts_monthly_stats 
ON bms.contracts(EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)) 
WHERE is_active = true;

-- 3.3 입주자 타입별 통계용
CREATE INDEX IF NOT EXISTS idx_tenants_type_stats 
ON bms.tenants(tenant_type) 
WHERE is_active = true;

-- 4. 전문 검색 인덱스 (Full-text Search)

-- 4.1 통합 검색용 인덱스 (건물, 호실, 입주자 통합 검색)
-- 건물 통합 검색
CREATE INDEX IF NOT EXISTS idx_buildings_fulltext 
ON bms.buildings USING gin(
    to_tsvector('korean', 
        COALESCE(name, '') || ' ' || 
        COALESCE(address, '') || ' ' || 
        COALESCE(description, '')
    )
) WHERE is_active = true;

-- 입주자 통합 검색
CREATE INDEX IF NOT EXISTS idx_tenants_fulltext 
ON bms.tenants USING gin(
    to_tsvector('korean', 
        COALESCE(name, '') || ' ' || 
        COALESCE(phone, '') || ' ' || 
        COALESCE(email, '')
    )
) WHERE is_active = true;--
 5. 지리적 검색 인덱스 (PostGIS 확장 사용 시)

-- 5.1 건물 위치 기반 검색 (향후 확장용)
-- CREATE INDEX IF NOT EXISTS idx_buildings_location_gist 
-- ON bms.buildings USING gist(location) 
-- WHERE is_active = true AND location IS NOT NULL;

-- 6. 부분 인덱스 (조건부 인덱스로 성능 최적화)

-- 6.1 활성 상태만 인덱싱
CREATE INDEX IF NOT EXISTS idx_buildings_active_only 
ON bms.buildings(company_id, created_at) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_units_active_only 
ON bms.units(building_id, created_at) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_tenants_active_only 
ON bms.tenants(company_id, created_at) 
WHERE is_active = true;

-- 6.2 최근 데이터만 인덱싱 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_contracts_recent 
ON bms.contracts(company_id, start_date) 
WHERE is_active = true AND start_date >= CURRENT_DATE - INTERVAL '2 years';

-- 7. 정렬 최적화 인덱스

-- 7.1 건물 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_buildings_sort_name 
ON bms.buildings(company_id, name) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_buildings_sort_created 
ON bms.buildings(company_id, created_at DESC) 
WHERE is_active = true;

-- 7.2 호실 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_units_sort_number 
ON bms.units(building_id, unit_number) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_units_sort_area 
ON bms.units(building_id, area DESC) 
WHERE is_active = true;

-- 7.3 입주자 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_tenants_sort_name 
ON bms.tenants(company_id, name) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_tenants_sort_move_in 
ON bms.tenants(company_id, move_in_date DESC) 
WHERE is_active = true;

-- 8. 외래키 성능 최적화 인덱스

-- 8.1 참조 무결성 검사 성능 향상
CREATE INDEX IF NOT EXISTS idx_units_building_fk 
ON bms.units(building_id) 
WHERE building_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tenant_units_tenant_fk 
ON bms.tenant_units(tenant_id) 
WHERE tenant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_tenant_units_unit_fk 
ON bms.tenant_units(unit_id) 
WHERE unit_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_contracts_tenant_fk 
ON bms.contracts(tenant_id) 
WHERE tenant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_contracts_lessor_fk 
ON bms.contracts(lessor_id) 
WHERE lessor_id IS NOT NULL;

-- 9. 집계 쿼리 최적화 인덱스

-- 9.1 대시보드 통계용 인덱스
CREATE INDEX IF NOT EXISTS idx_buildings_stats 
ON bms.buildings(company_id, building_type, status) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_units_occupancy_stats 
ON bms.units(building_id, status) 
WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_contracts_revenue_stats 
ON bms.contracts(company_id, EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date)) 
WHERE is_active = true;

-- 10. 인덱스 사용량 모니터링 뷰 생성
CREATE OR REPLACE VIEW bms.v_index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_scan,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'LOW_USAGE'
        WHEN idx_scan < 1000 THEN 'MEDIUM_USAGE'
        ELSE 'HIGH_USAGE'
    END as usage_level
FROM pg_stat_user_indexes 
WHERE schemaname = 'bms'
ORDER BY idx_scan DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_index_usage_stats OWNER TO qiro;

-- 11. 인덱스 크기 모니터링 뷰 생성
CREATE OR REPLACE VIEW bms.v_index_size_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
    pg_relation_size(indexrelid) as index_size_bytes
FROM pg_stat_user_indexes 
WHERE schemaname = 'bms'
ORDER BY pg_relation_size(indexrelid) DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_index_size_stats OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 5.1 건물 관리 전용 인덱스 생성이 완료되었습니다!' as result;