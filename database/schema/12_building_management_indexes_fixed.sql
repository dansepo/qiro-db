-- =====================================================
-- 건물 관리 전용 인덱스 생성 스크립트 (수정됨)
-- Phase 5.1: 건물 관리 전용 인덱스 생성
-- =====================================================

-- 1. 건물 관련 조회 최적화 인덱스

-- 1.1 건물 기본 조회 인덱스
-- 회사별 건물 목록 조회 (가장 빈번한 쿼리)
CREATE INDEX IF NOT EXISTS idx_buildings_company_name 
ON bms.buildings(company_id, name);

-- 건물 타입별 조회
CREATE INDEX IF NOT EXISTS idx_buildings_type 
ON bms.buildings(building_type);

-- 건물명 검색 (부분 일치 검색 지원)
CREATE INDEX IF NOT EXISTS idx_buildings_name_text 
ON bms.buildings USING gin(to_tsvector('simple', name));

-- 건물 주소 검색
CREATE INDEX IF NOT EXISTS idx_buildings_address_text 
ON bms.buildings USING gin(to_tsvector('simple', address));

-- 1.2 호실 관련 조회 최적화 인덱스
-- 건물별 호실 목록 조회 (핵심 쿼리)
CREATE INDEX IF NOT EXISTS idx_units_building_number 
ON bms.units(building_id, unit_number);

-- 호실 상태별 조회
CREATE INDEX IF NOT EXISTS idx_units_status_type 
ON bms.units(status, unit_type);

-- 면적 범위 검색
CREATE INDEX IF NOT EXISTS idx_units_area_range 
ON bms.units(area) 
WHERE area IS NOT NULL;

-- 1.3 입주자 관련 조회 최적화 인덱스
-- 회사별 입주자 목록
CREATE INDEX IF NOT EXISTS idx_tenants_company_id 
ON bms.tenants(company_id);

-- 입주자명 검색
CREATE INDEX IF NOT EXISTS idx_tenants_name_text 
ON bms.tenants USING gin(to_tsvector('simple', tenant_name));

-- 연락처 검색
CREATE INDEX IF NOT EXISTS idx_tenants_contact 
ON bms.tenants(phone_number, email);

-- 입주일 범위 검색
CREATE INDEX IF NOT EXISTS idx_tenants_move_in_date 
ON bms.tenants(move_in_date) 
WHERE move_in_date IS NOT NULL;

-- 1.4 임대차 계약 관련 조회 최적화 인덱스
-- 활성 계약 조회
CREATE INDEX IF NOT EXISTS idx_lease_contracts_dates 
ON bms.lease_contracts(start_date, end_date);

-- 계약 만료 예정 조회
CREATE INDEX IF NOT EXISTS idx_lease_contracts_expiring 
ON bms.lease_contracts(end_date) 
WHERE end_date IS NOT NULL;

-- 임대료 범위 검색
CREATE INDEX IF NOT EXISTS idx_lease_contracts_rent 
ON bms.lease_contracts(monthly_rent) 
WHERE monthly_rent IS NOT NULL;

-- 보증금 범위 검색
CREATE INDEX IF NOT EXISTS idx_lease_contracts_deposit 
ON bms.lease_contracts(deposit_amount) 
WHERE deposit_amount IS NOT NULL;-- 1.5 임대
인 관련 조회 최적화 인덱스
-- 회사별 임대인 목록
CREATE INDEX IF NOT EXISTS idx_lessors_company_id 
ON bms.lessors(company_id);

-- 임대인명 검색
CREATE INDEX IF NOT EXISTS idx_lessors_name_text 
ON bms.lessors USING gin(to_tsvector('simple', lessor_name));

-- 1.6 관리비 관련 조회 최적화 인덱스
-- 관리비 항목별 조회 (이미 존재하는 인덱스는 스킵됨)
CREATE INDEX IF NOT EXISTS idx_fee_items_company_active 
ON bms.fee_items(company_id, is_active);

-- 관리비 계산 방식별 조회 (이미 존재하는 인덱스는 스킵됨)
CREATE INDEX IF NOT EXISTS idx_fee_items_calculation_method 
ON bms.fee_items(calculation_method);

-- 2. 복합 인덱스 (다중 조건 검색 최적화)

-- 2.1 건물-호실 관계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_units_building_status_type 
ON bms.units(building_id, status, unit_type);

-- 2.2 계약-당사자 관계 조회 최적화
CREATE INDEX IF NOT EXISTS idx_lease_contracts_tenant_lessor 
ON bms.lease_contracts(tenant_id, lessor_id);

-- 2.3 시간 기반 조회 최적화
CREATE INDEX IF NOT EXISTS idx_lease_contracts_company_dates 
ON bms.lease_contracts(company_id, start_date, end_date);

-- 3. 성능 모니터링을 위한 통계 인덱스

-- 3.1 건물별 호실 수 집계용
CREATE INDEX IF NOT EXISTS idx_units_building_count 
ON bms.units(building_id);

-- 3.2 월별 계약 통계용
CREATE INDEX IF NOT EXISTS idx_lease_contracts_monthly_stats 
ON bms.lease_contracts(EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date));

-- 3.3 입주자 타입별 통계용
CREATE INDEX IF NOT EXISTS idx_tenants_type_stats 
ON bms.tenants(tenant_type);

-- 4. 전문 검색 인덱스 (Full-text Search)

-- 4.1 통합 검색용 인덱스
-- 건물 통합 검색
CREATE INDEX IF NOT EXISTS idx_buildings_fulltext 
ON bms.buildings USING gin(
    to_tsvector('simple', 
        COALESCE(name, '') || ' ' || 
        COALESCE(address, '') || ' ' || 
        COALESCE(description, '')
    )
);

-- 입주자 통합 검색
CREATE INDEX IF NOT EXISTS idx_tenants_fulltext 
ON bms.tenants USING gin(
    to_tsvector('simple', 
        COALESCE(tenant_name, '') || ' ' || 
        COALESCE(phone_number, '') || ' ' || 
        COALESCE(email, '')
    )
);

-- 5. 정렬 최적화 인덱스

-- 5.1 건물 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_buildings_sort_name 
ON bms.buildings(company_id, name);

CREATE INDEX IF NOT EXISTS idx_buildings_sort_created 
ON bms.buildings(company_id, created_at DESC);

-- 5.2 호실 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_units_sort_number 
ON bms.units(building_id, unit_number);

CREATE INDEX IF NOT EXISTS idx_units_sort_area 
ON bms.units(building_id, area DESC);

-- 5.3 입주자 목록 정렬용
CREATE INDEX IF NOT EXISTS idx_tenants_sort_name 
ON bms.tenants(company_id, tenant_name);

CREATE INDEX IF NOT EXISTS idx_tenants_sort_move_in 
ON bms.tenants(company_id, move_in_date DESC);

-- 6. 외래키 성능 최적화 인덱스

-- 6.1 참조 무결성 검사 성능 향상
CREATE INDEX IF NOT EXISTS idx_units_building_fk 
ON bms.units(building_id) 
WHERE building_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_lease_contracts_tenant_fk 
ON bms.lease_contracts(tenant_id) 
WHERE tenant_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_lease_contracts_lessor_fk 
ON bms.lease_contracts(lessor_id) 
WHERE lessor_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_lease_contracts_unit_fk 
ON bms.lease_contracts(unit_id) 
WHERE unit_id IS NOT NULL;

-- 7. 집계 쿼리 최적화 인덱스

-- 7.1 대시보드 통계용 인덱스
CREATE INDEX IF NOT EXISTS idx_buildings_stats 
ON bms.buildings(company_id, building_type);

CREATE INDEX IF NOT EXISTS idx_units_occupancy_stats 
ON bms.units(building_id, status);

CREATE INDEX IF NOT EXISTS idx_lease_contracts_revenue_stats 
ON bms.lease_contracts(company_id, EXTRACT(YEAR FROM start_date), EXTRACT(MONTH FROM start_date));

-- 8. 시스템 테이블 인덱스 최적화

-- 8.1 사용자 활동 로그 조회 최적화 (이미 존재하는 인덱스 보완)
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_feature 
ON bms.user_activity_logs(feature_used, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_activity_logs_business_context 
ON bms.user_activity_logs(business_context, created_at DESC);

-- 8.2 감사 로그 조회 최적화 (이미 존재하는 인덱스 보완)
CREATE INDEX IF NOT EXISTS idx_audit_logs_business_context 
ON bms.audit_logs(business_context, operation_timestamp DESC);

-- 8.3 시스템 설정 조회 최적화 (이미 존재하는 인덱스 보완)
CREATE INDEX IF NOT EXISTS idx_system_settings_group_order 
ON bms.system_settings(setting_group, display_order);

-- 9. 건물 그룹 관련 인덱스
CREATE INDEX IF NOT EXISTS idx_building_groups_company 
ON bms.building_groups(company_id, group_name);

CREATE INDEX IF NOT EXISTS idx_building_group_assignments_group 
ON bms.building_group_assignments(group_id, building_id);

-- 10. 공통 시설 관련 인덱스
CREATE INDEX IF NOT EXISTS idx_common_facilities_building 
ON bms.common_facilities(building_id, facility_type);

CREATE INDEX IF NOT EXISTS idx_common_facilities_status 
ON bms.common_facilities(status, maintenance_schedule);

-- 완료 메시지
SELECT '✅ 5.1 건물 관리 전용 인덱스 생성이 완료되었습니다!' as result;