-- =====================================================
-- 성능 최적화를 위한 인덱스 설계 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 주요 쿼리 패턴에 최적화된 인덱스 설계
-- =====================================================

\set ECHO all
\timing on

-- =====================================================
-- 1. 기본 테이블 인덱스 (Primary Key, Unique 제약조건 외)
-- =====================================================

-- 1.1 건물 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_buildings_status_type 
ON buildings (status, building_type) 
WHERE status = 'ACTIVE';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_buildings_name_gin 
ON buildings USING gin (to_tsvector('korean', name));

-- 1.2 호실 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_units_building_status 
ON units (building_id, status) 
INCLUDE (unit_number, area);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_units_building_floor 
ON units (building_id, floor_number, unit_number);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_units_type_status 
ON units (unit_type, status) 
WHERE status IN ('AVAILABLE', 'OCCUPIED');

-- 1.3 임차인 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_name_gin 
ON tenants USING gin (to_tsvector('korean', name));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_phone_email 
ON tenants (primary_phone, email) 
WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_business_number 
ON tenants (business_registration_number) 
WHERE business_registration_number IS NOT NULL;

-- =====================================================
-- 2. 관리비 처리 워크플로우 최적화 인덱스
-- =====================================================

-- 2.1 청구월 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_billing_months_building_year_month 
ON billing_months (building_id, billing_year DESC, billing_month DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_billing_months_status_due_date 
ON billing_months (status, due_date) 
WHERE status IN ('DRAFT', 'DATA_INPUT', 'CALCULATING');

-- 2.2 검침 데이터 최적화 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_unit_meter_readings_billing_unit_type 
ON unit_meter_readings (billing_month_id, unit_id, meter_type) 
INCLUDE (usage_amount, calculated_amount);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_unit_meter_readings_building_month_type 
ON unit_meter_readings (billing_month_id, meter_type) 
INCLUDE (usage_amount, calculated_amount);

-- 검침 데이터 시계열 분석용 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_unit_meter_readings_unit_type_time 
ON unit_meter_readings (unit_id, meter_type, billing_month_id) 
INCLUDE (usage_amount, reading_date);

-- 2.3 관리비 산정 최적화 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_monthly_fees_billing_unit_item 
ON monthly_fees (billing_month_id, unit_id, fee_item_id) 
INCLUDE (calculated_amount, final_amount);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_monthly_fees_building_month_summary 
ON monthly_fees (billing_month_id) 
INCLUDE (calculated_amount, tax_amount, final_amount);

-- 관리비 항목별 집계용 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_monthly_fees_item_month 
ON monthly_fees (fee_item_id, billing_month_id) 
INCLUDE (calculated_amount);

-- =====================================================
-- 3. 고지서 및 수납 처리 최적화 인덱스
-- =====================================================

-- 3.1 고지서 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_billing_unit 
ON invoices (billing_month_id, unit_id) 
INCLUDE (total_amount, status, due_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_status_due_date 
ON invoices (status, due_date) 
WHERE status IN ('ISSUED', 'SENT', 'VIEWED', 'OVERDUE');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_due_date_status 
ON invoices (due_date, status) 
WHERE status != 'PAID';

-- 미납 관리용 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_overdue 
ON invoices (due_date, status, total_amount) 
WHERE status IN ('ISSUED', 'SENT', 'VIEWED', 'OVERDUE') 
  AND due_date < CURRENT_DATE;

-- 3.2 수납 처리 최적화 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_invoice_date 
ON payments (invoice_id, payment_date DESC) 
INCLUDE (amount, payment_method);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_date_method 
ON payments (payment_date, payment_method) 
WHERE payment_status = 'COMPLETED';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payments_method_status 
ON payments (payment_method, payment_status, payment_date DESC);

-- =====================================================
-- 4. 임대차 관리 최적화 인덱스
-- =====================================================

-- 4.1 임대 계약 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lease_contracts_unit_status 
ON lease_contracts (unit_id, status) 
INCLUDE (start_date, end_date, monthly_rent);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lease_contracts_tenant_status 
ON lease_contracts (tenant_id, status) 
INCLUDE (start_date, end_date);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lease_contracts_end_date 
ON lease_contracts (end_date, status) 
WHERE status = 'ACTIVE' AND end_date >= CURRENT_DATE;

-- 계약 만료 알림용 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_lease_contracts_expiring 
ON lease_contracts (end_date, status) 
WHERE status = 'ACTIVE' 
  AND end_date BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '90 days';

-- =====================================================
-- 5. 시설 관리 최적화 인덱스
-- =====================================================

-- 5.1 시설물 관련 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_facilities_building_type_status 
ON facilities (building_id, facility_type, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_facilities_maintenance_schedule 
ON facilities (next_maintenance_date, status) 
WHERE status = 'ACTIVE' AND next_maintenance_date IS NOT NULL;

-- 5.2 유지보수 요청 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_maintenance_requests_building_status 
ON maintenance_requests (building_id, status, priority DESC, requested_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_maintenance_requests_facility_status 
ON maintenance_requests (facility_id, status) 
WHERE facility_id IS NOT NULL;

-- =====================================================
-- 6. 복합 비즈니스 쿼리 최적화 인덱스
-- =====================================================

-- 6.1 건물별 월별 수익 분석용 복합 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_revenue_analysis 
ON monthly_fees (billing_month_id, fee_item_id) 
INCLUDE (calculated_amount, tax_amount);

-- 6.2 호실별 연간 관리비 추이 분석용 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_unit_annual_fees 
ON invoices (unit_id, billing_month_id) 
INCLUDE (total_amount, status);

-- 6.3 미납 현황 분석용 복합 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delinquency_analysis 
ON invoices (status, due_date, unit_id) 
INCLUDE (total_amount, paid_amount)
WHERE status IN ('ISSUED', 'SENT', 'VIEWED', 'OVERDUE');

-- =====================================================
-- 7. 전문 검색 및 텍스트 검색 인덱스
-- =====================================================

-- 7.1 GIN 인덱스 (전문 검색)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_search_gin 
ON tenants USING gin (
    to_tsvector('korean', 
        COALESCE(name, '') || ' ' || 
        COALESCE(email, '') || ' ' || 
        COALESCE(primary_phone, '')
    )
);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_buildings_search_gin 
ON buildings USING gin (
    to_tsvector('korean', 
        COALESCE(name, '') || ' ' || 
        COALESCE(address, '')
    )
);

-- 7.2 부분 문자열 검색용 인덱스 (trigram)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_name_trgm 
ON tenants USING gin (name gin_trgm_ops);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_phone_trgm 
ON tenants USING gin (primary_phone gin_trgm_ops);

-- =====================================================
-- 8. 파티셔닝 지원 인덱스
-- =====================================================

-- 8.1 시간 기반 파티셔닝 지원 인덱스
-- (향후 파티셔닝 구현 시 사용)

-- 청구월 데이터 파티셔닝 준비
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_billing_months_partition_key 
ON billing_months (billing_year, billing_month, building_id);

-- 검침 데이터 파티셔닝 준비  
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_unit_meter_readings_partition_key 
ON unit_meter_readings (billing_month_id) 
INCLUDE (unit_id, meter_type, usage_amount);

-- 관리비 산정 데이터 파티셔닝 준비
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_monthly_fees_partition_key 
ON monthly_fees (billing_month_id) 
INCLUDE (unit_id, fee_item_id, calculated_amount);

-- =====================================================
-- 9. 성능 모니터링용 인덱스
-- =====================================================

-- 9.1 감사 로그 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_table_action_time 
ON audit_logs (table_name, action, changed_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_audit_logs_user_time 
ON audit_logs (changed_by, changed_at DESC) 
WHERE changed_by IS NOT NULL;

-- 9.2 사용자 활동 추적 인덱스
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_last_login 
ON users (last_login_at DESC, is_active) 
WHERE is_active = true;

-- =====================================================
-- 10. 인덱스 사용률 모니터링 뷰
-- =====================================================

-- 인덱스 사용률 모니터링 뷰 생성
CREATE OR REPLACE VIEW v_index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_scan = 0 THEN 'UNUSED'
        WHEN idx_scan < 100 THEN 'LOW_USAGE'
        WHEN idx_scan < 1000 THEN 'MEDIUM_USAGE'
        ELSE 'HIGH_USAGE'
    END as usage_level,
    pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- 테이블별 인덱스 효율성 분석 뷰
CREATE OR REPLACE VIEW v_table_index_efficiency AS
SELECT 
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    CASE 
        WHEN seq_scan + idx_scan = 0 THEN 0
        ELSE ROUND(idx_scan * 100.0 / (seq_scan + idx_scan), 2)
    END as index_usage_ratio,
    CASE 
        WHEN seq_scan = 0 THEN 0
        ELSE ROUND(seq_tup_read / seq_scan, 0)
    END as avg_seq_read_per_scan
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
ORDER BY index_usage_ratio ASC;

-- =====================================================
-- 인덱스 생성 완료 메시지
-- =====================================================

\echo '====================================================='
\echo '성능 최적화 인덱스 생성 완료'
\echo '====================================================='
\echo '1. 기본 테이블 인덱스: 건물, 호실, 임차인'
\echo '2. 관리비 워크플로우: 청구월, 검침, 산정'
\echo '3. 고지서/수납: 미납 관리, 수납 패턴'
\echo '4. 임대차 관리: 계약, 만료 알림'
\echo '5. 시설 관리: 유지보수, 점검 일정'
\echo '6. 복합 비즈니스: 수익 분석, 추이 분석'
\echo '7. 전문 검색: GIN, trigram 인덱스'
\echo '8. 파티셔닝 지원: 시간 기반 분할 준비'
\echo '9. 성능 모니터링: 감사 로그, 사용자 활동'
\echo '10. 모니터링 뷰: 인덱스 사용률, 효율성'
\echo '====================================================='