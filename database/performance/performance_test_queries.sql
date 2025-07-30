-- =====================================================
-- 성능 테스트 쿼리 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 주요 비즈니스 쿼리의 성능 테스트
-- =====================================================

\set ECHO all
\timing on

-- =====================================================
-- 1. 기본 조회 성능 테스트
-- =====================================================

-- 1.1 건물별 호실 현황 조회 (NFR-PF-002: 2초 이내)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    COUNT(*) AS total_units,
    COUNT(CASE WHEN u.status = 'OCCUPIED' THEN 1 END) AS occupied_units,
    COUNT(CASE WHEN u.status = 'AVAILABLE' THEN 1 END) AS available_units,
    ROUND(COUNT(CASE WHEN u.status = 'OCCUPIED' THEN 1 END) * 100.0 / COUNT(*), 2) AS occupancy_rate
FROM buildings b
JOIN units u ON b.id = u.building_id
WHERE b.name LIKE '성능테스트빌딩%'
GROUP BY b.id, b.name
ORDER BY b.name;

-- 1.2 최근 3개월 관리비 현황 조회
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    bm.billing_year,
    bm.billing_month,
    COUNT(DISTINCT i.id) AS total_invoices,
    SUM(i.total_amount) AS total_amount,
    COUNT(CASE WHEN i.status = 'PAID' THEN 1 END) AS paid_invoices,
    SUM(CASE WHEN i.status = 'PAID' THEN i.total_amount ELSE 0 END) AS paid_amount,
    ROUND(COUNT(CASE WHEN i.status = 'PAID' THEN 1 END) * 100.0 / COUNT(*), 2) AS payment_rate
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year * 100 + bm.billing_month >= 
      (EXTRACT(YEAR FROM CURRENT_DATE) * 100 + EXTRACT(MONTH FROM CURRENT_DATE) - 3)
GROUP BY b.id, b.name, bm.billing_year, bm.billing_month
ORDER BY b.name, bm.billing_year DESC, bm.billing_month DESC;

-- =====================================================
-- 2. 복잡한 집계 쿼리 성능 테스트
-- =====================================================

-- 2.1 건물별 월별 수익 분석 (NFR-PF-003: 관리비 계산 10초 이내)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    bm.billing_year,
    bm.billing_month,
    fi.name AS fee_item_name,
    fi.fee_type,
    COUNT(mf.id) AS calculation_count,
    SUM(mf.calculated_amount) AS total_calculated,
    AVG(mf.calculated_amount) AS avg_per_unit,
    MIN(mf.calculated_amount) AS min_amount,
    MAX(mf.calculated_amount) AS max_amount,
    STDDEV(mf.calculated_amount) AS amount_stddev
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN monthly_fees mf ON bm.id = mf.billing_month_id
JOIN fee_items fi ON mf.fee_item_id = fi.id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY b.id, b.name, bm.billing_year, bm.billing_month, fi.id, fi.name, fi.fee_type
ORDER BY b.name, bm.billing_year DESC, bm.billing_month DESC, fi.name;

-- 2.2 호실별 연간 관리비 추이 분석
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    u.unit_number,
    EXTRACT(YEAR FROM (bm.billing_year || '-' || bm.billing_month || '-01')::DATE) AS year,
    COUNT(DISTINCT bm.id) AS billing_months,
    SUM(i.total_amount) AS annual_total,
    AVG(i.total_amount) AS monthly_average,
    SUM(p.amount) AS paid_amount,
    SUM(i.total_amount) - COALESCE(SUM(p.amount), 0) AS outstanding_amount
FROM buildings b
JOIN units u ON b.id = u.building_id
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id AND u.id = i.unit_id
LEFT JOIN payments p ON i.id = p.invoice_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND u.status = 'OCCUPIED'
  AND bm.billing_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY b.id, b.name, u.id, u.unit_number, EXTRACT(YEAR FROM (bm.billing_year || '-' || bm.billing_month || '-01')::DATE)
HAVING COUNT(DISTINCT bm.id) >= 6  -- 최소 6개월 데이터
ORDER BY b.name, u.unit_number, year DESC;-- ======
===============================================
-- 3. 검침 데이터 관련 성능 테스트
-- =====================================================

-- 3.1 대용량 검침 데이터 조회 및 집계
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    umr.meter_type,
    bm.billing_year,
    bm.billing_month,
    COUNT(*) AS reading_count,
    SUM(umr.usage_amount) AS total_usage,
    AVG(umr.usage_amount) AS avg_usage,
    SUM(umr.calculated_amount) AS total_amount,
    COUNT(CASE WHEN umr.is_estimated = true THEN 1 END) AS estimated_count,
    ROUND(COUNT(CASE WHEN umr.is_estimated = true THEN 1 END) * 100.0 / COUNT(*), 2) AS estimated_rate
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN unit_meter_readings umr ON bm.id = umr.billing_month_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY b.id, b.name, umr.meter_type, bm.billing_year, bm.billing_month
ORDER BY b.name, bm.billing_year DESC, bm.billing_month DESC, umr.meter_type;

-- 3.2 호실별 사용량 패턴 분석 (시계열 분석)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
WITH monthly_usage AS (
    SELECT 
        b.name AS building_name,
        u.unit_number,
        umr.meter_type,
        bm.billing_year,
        bm.billing_month,
        umr.usage_amount,
        LAG(umr.usage_amount) OVER (
            PARTITION BY u.id, umr.meter_type 
            ORDER BY bm.billing_year, bm.billing_month
        ) AS prev_usage,
        AVG(umr.usage_amount) OVER (
            PARTITION BY u.id, umr.meter_type 
            ORDER BY bm.billing_year, bm.billing_month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_avg_3m
    FROM buildings b
    JOIN units u ON b.id = u.building_id
    JOIN billing_months bm ON b.id = bm.building_id
    JOIN unit_meter_readings umr ON bm.id = umr.billing_month_id AND u.id = umr.unit_id
    WHERE b.name LIKE '성능테스트빌딩%'
      AND bm.billing_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
)
SELECT 
    building_name,
    unit_number,
    meter_type,
    billing_year,
    billing_month,
    usage_amount,
    prev_usage,
    CASE 
        WHEN prev_usage IS NOT NULL AND prev_usage > 0 
        THEN ROUND(((usage_amount - prev_usage) / prev_usage * 100), 2)
        ELSE NULL 
    END AS usage_change_pct,
    moving_avg_3m,
    CASE 
        WHEN moving_avg_3m > 0 
        THEN ROUND((usage_amount / moving_avg_3m * 100), 2)
        ELSE NULL 
    END AS vs_moving_avg_pct
FROM monthly_usage
WHERE usage_amount IS NOT NULL
ORDER BY building_name, unit_number, meter_type, billing_year DESC, billing_month DESC
LIMIT 1000;

-- =====================================================
-- 4. 고지서 및 수납 관련 성능 테스트
-- =====================================================

-- 4.1 미납 현황 분석 (NFR-PF-004: 고지서 생성 30초 이내)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    u.unit_number,
    i.invoice_number,
    i.issue_date,
    i.due_date,
    i.total_amount,
    COALESCE(SUM(p.amount), 0) AS paid_amount,
    i.total_amount - COALESCE(SUM(p.amount), 0) AS outstanding_amount,
    CURRENT_DATE - i.due_date AS overdue_days,
    CASE 
        WHEN CURRENT_DATE <= i.due_date THEN '정상'
        WHEN CURRENT_DATE - i.due_date <= 30 THEN '30일이내연체'
        WHEN CURRENT_DATE - i.due_date <= 60 THEN '60일이내연체'
        WHEN CURRENT_DATE - i.due_date <= 90 THEN '90일이내연체'
        ELSE '90일초과연체'
    END AS overdue_category
FROM buildings b
JOIN units u ON b.id = u.building_id
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id AND u.id = i.unit_id
LEFT JOIN payments p ON i.id = p.invoice_id AND p.payment_status = 'COMPLETED'
WHERE b.name LIKE '성능테스트빌딩%'
  AND i.status IN ('ISSUED', 'SENT', 'VIEWED', 'OVERDUE')
GROUP BY b.id, b.name, u.id, u.unit_number, i.id, i.invoice_number, i.issue_date, i.due_date, i.total_amount
HAVING i.total_amount - COALESCE(SUM(p.amount), 0) > 0
ORDER BY overdue_days DESC, outstanding_amount DESC;

-- 4.2 수납 패턴 분석
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name AS building_name,
    DATE_TRUNC('month', p.payment_date) AS payment_month,
    p.payment_method,
    COUNT(*) AS payment_count,
    SUM(p.amount) AS total_amount,
    AVG(p.amount) AS avg_amount,
    COUNT(CASE WHEN p.payment_date <= i.due_date THEN 1 END) AS on_time_payments,
    COUNT(CASE WHEN p.payment_date > i.due_date THEN 1 END) AS late_payments,
    ROUND(COUNT(CASE WHEN p.payment_date <= i.due_date THEN 1 END) * 100.0 / COUNT(*), 2) AS on_time_rate
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id
JOIN payments p ON i.id = p.invoice_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND p.payment_status = 'COMPLETED'
  AND p.payment_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY b.id, b.name, DATE_TRUNC('month', p.payment_date), p.payment_method
ORDER BY b.name, payment_month DESC, p.payment_method;-- 
=====================================================
-- 5. 동시성 테스트 시나리오
-- =====================================================

-- 5.1 동시 관리비 계산 시뮬레이션 (트랜잭션 격리 테스트)
-- 세션 1에서 실행할 쿼리
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 특정 청구월의 관리비 계산 시뮬레이션
UPDATE billing_months 
SET status = 'CALCULATING'::billing_month_status,
    updated_at = CURRENT_TIMESTAMP
WHERE building_id = (SELECT id FROM buildings WHERE name = '성능테스트빌딩1' LIMIT 1)
  AND billing_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND billing_month = EXTRACT(MONTH FROM CURRENT_DATE);

-- 관리비 계산 시뮬레이션 (대량 INSERT)
INSERT INTO monthly_fees (billing_month_id, unit_id, fee_item_id, calculation_method, calculated_amount)
SELECT 
    bm.id,
    u.id,
    fi.id,
    'FIXED_AMOUNT'::fee_calculation_method,
    (random() * 100000 + 50000)::DECIMAL(12,2)
FROM billing_months bm
JOIN buildings b ON bm.building_id = b.id
JOIN units u ON b.id = u.building_id
JOIN fee_items fi ON b.id = fi.building_id
WHERE b.name = '성능테스트빌딩1'
  AND bm.billing_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND bm.billing_month = EXTRACT(MONTH FROM CURRENT_DATE)
  AND u.status = 'OCCUPIED'
  AND fi.is_active = true
ON CONFLICT (billing_month_id, unit_id, fee_item_id) DO UPDATE SET
    calculated_amount = EXCLUDED.calculated_amount,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

-- 5.2 동시 고지서 생성 시뮬레이션
BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- 고지서 일괄 생성 시뮬레이션
INSERT INTO invoices (billing_month_id, unit_id, invoice_number, issue_date, due_date, subtotal_amount, status)
SELECT 
    bm.id,
    u.id,
    'PERF-' || bm.id || '-' || u.id || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '25 days',
    COALESCE(SUM(mf.calculated_amount), 0),
    'ISSUED'::invoice_status
FROM billing_months bm
JOIN buildings b ON bm.building_id = b.id
JOIN units u ON b.id = u.building_id
LEFT JOIN monthly_fees mf ON bm.id = mf.billing_month_id AND u.id = mf.unit_id
WHERE b.name = '성능테스트빌딩2'
  AND bm.billing_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND bm.billing_month = EXTRACT(MONTH FROM CURRENT_DATE)
  AND u.status = 'OCCUPIED'
GROUP BY bm.id, u.id
ON CONFLICT (billing_month_id, unit_id) DO UPDATE SET
    subtotal_amount = EXCLUDED.subtotal_amount,
    updated_at = CURRENT_TIMESTAMP;

COMMIT;

-- =====================================================
-- 6. 인덱스 효율성 테스트
-- =====================================================

-- 6.1 복합 인덱스 활용도 테스트
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM unit_meter_readings umr
JOIN billing_months bm ON umr.billing_month_id = bm.id
WHERE bm.building_id = (SELECT id FROM buildings WHERE name = '성능테스트빌딩1' LIMIT 1)
  AND bm.billing_year = EXTRACT(YEAR FROM CURRENT_DATE)
  AND bm.billing_month = EXTRACT(MONTH FROM CURRENT_DATE)
  AND umr.meter_type = 'ELECTRICITY'::meter_type;

-- 6.2 날짜 범위 검색 성능 테스트
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    COUNT(*) as total_payments,
    SUM(amount) as total_amount
FROM payments p
JOIN invoices i ON p.invoice_id = i.id
JOIN billing_months bm ON i.billing_month_id = bm.id
JOIN buildings b ON bm.building_id = b.id
WHERE b.name LIKE '성능테스트빌딩%'
  AND p.payment_date BETWEEN CURRENT_DATE - INTERVAL '6 months' AND CURRENT_DATE;

-- 6.3 텍스트 검색 성능 테스트
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM tenants t
WHERE t.name ILIKE '%테스트%'
   OR t.email ILIKE '%test%'
   OR t.primary_phone LIKE '%1234%'
ORDER BY t.name
LIMIT 100;

-- =====================================================
-- 7. 메모리 사용량 및 캐시 효율성 테스트
-- =====================================================

-- 7.1 대용량 조인 쿼리 (메모리 사용량 테스트)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    b.name,
    u.unit_number,
    t.name as tenant_name,
    bm.billing_year,
    bm.billing_month,
    i.total_amount,
    p.payment_date,
    p.amount as paid_amount
FROM buildings b
JOIN units u ON b.id = u.building_id
LEFT JOIN lease_contracts lc ON u.id = lc.unit_id AND lc.status = 'ACTIVE'
LEFT JOIN tenants t ON lc.tenant_id = t.id
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id AND u.id = i.unit_id
LEFT JOIN payments p ON i.id = p.invoice_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
ORDER BY b.name, u.unit_number, bm.billing_year DESC, bm.billing_month DESC;

-- 7.2 집계 함수 성능 테스트 (GROUP BY with ROLLUP)
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    COALESCE(b.name, 'TOTAL') as building_name,
    COALESCE(fi.fee_type::TEXT, 'SUBTOTAL') as fee_type,
    COUNT(*) as calculation_count,
    SUM(mf.calculated_amount) as total_amount,
    AVG(mf.calculated_amount) as avg_amount
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN monthly_fees mf ON bm.id = mf.billing_month_id
JOIN fee_items fi ON mf.fee_item_id = fi.id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY ROLLUP(b.name, fi.fee_type)
ORDER BY b.name NULLS LAST, fi.fee_type NULLS LAST;-- ===
==================================================
-- 8. 성능 모니터링 및 분석 쿼리
-- =====================================================

-- 8.1 테이블별 크기 및 인덱스 사용률 분석
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation,
    most_common_vals,
    most_common_freqs
FROM pg_stats 
WHERE schemaname = 'public' 
  AND tablename IN ('buildings', 'units', 'billing_months', 'monthly_fees', 'invoices', 'payments')
ORDER BY tablename, attname;

-- 8.2 인덱스 사용 통계
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
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- 8.3 테이블 크기 및 성능 통계
SELECT 
    schemaname,
    tablename,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    CASE 
        WHEN n_live_tup = 0 THEN 0
        ELSE ROUND(n_dead_tup * 100.0 / n_live_tup, 2)
    END as dead_tuple_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
  AND tablename IN ('buildings', 'units', 'billing_months', 'monthly_fees', 'invoices', 'payments')
ORDER BY n_live_tup DESC;

-- 8.4 슬로우 쿼리 분석 (pg_stat_statements 확장 필요)
-- CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements 
WHERE query LIKE '%buildings%' 
   OR query LIKE '%units%'
   OR query LIKE '%invoices%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- =====================================================
-- 9. 성능 최적화 권장사항 생성
-- =====================================================

-- 9.1 누락된 인덱스 후보 식별
WITH table_stats AS (
    SELECT 
        schemaname,
        tablename,
        n_tup_ins + n_tup_upd + n_tup_del as total_writes,
        seq_scan,
        seq_tup_read,
        CASE 
            WHEN seq_scan = 0 THEN 0
            ELSE seq_tup_read / seq_scan
        END as avg_seq_read
    FROM pg_stat_user_tables
    WHERE schemaname = 'public'
)
SELECT 
    tablename,
    total_writes,
    seq_scan,
    avg_seq_read,
    CASE 
        WHEN avg_seq_read > 1000 AND seq_scan > 100 THEN 'HIGH_PRIORITY'
        WHEN avg_seq_read > 500 AND seq_scan > 50 THEN 'MEDIUM_PRIORITY'
        WHEN avg_seq_read > 100 AND seq_scan > 10 THEN 'LOW_PRIORITY'
        ELSE 'OK'
    END as index_recommendation
FROM table_stats
WHERE avg_seq_read > 100
ORDER BY avg_seq_read DESC;

-- 9.2 파티셔닝 후보 테이블 식별
SELECT 
    tablename,
    n_live_tup as row_count,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as table_size,
    CASE 
        WHEN n_live_tup > 1000000 THEN 'PARTITION_RECOMMENDED'
        WHEN n_live_tup > 500000 THEN 'CONSIDER_PARTITIONING'
        ELSE 'OK'
    END as partition_recommendation
FROM pg_stat_user_tables
WHERE schemaname = 'public'
  AND n_live_tup > 100000
ORDER BY n_live_tup DESC;

-- =====================================================
-- 10. 성능 테스트 결과 요약
-- =====================================================

-- 10.1 전체 성능 테스트 요약 리포트
SELECT 
    'PERFORMANCE_TEST_SUMMARY' as report_type,
    CURRENT_TIMESTAMP as test_timestamp,
    (SELECT COUNT(*) FROM buildings WHERE name LIKE '성능테스트빌딩%') as test_buildings,
    (SELECT COUNT(*) FROM units u JOIN buildings b ON u.building_id = b.id WHERE b.name LIKE '성능테스트빌딩%') as test_units,
    (SELECT COUNT(*) FROM monthly_fees mf 
     JOIN billing_months bm ON mf.billing_month_id = bm.id 
     JOIN buildings b ON bm.building_id = b.id 
     WHERE b.name LIKE '성능테스트빌딩%') as test_calculations,
    (SELECT COUNT(*) FROM invoices i 
     JOIN billing_months bm ON i.billing_month_id = bm.id 
     JOIN buildings b ON bm.building_id = b.id 
     WHERE b.name LIKE '성능테스트빌딩%') as test_invoices,
    (SELECT COUNT(*) FROM payments p 
     JOIN invoices i ON p.invoice_id = i.id 
     JOIN billing_months bm ON i.billing_month_id = bm.id 
     JOIN buildings b ON bm.building_id = b.id 
     WHERE b.name LIKE '성능테스트빌딩%') as test_payments;

-- 성능 테스트 완료 메시지
\echo '====================================================='
\echo '성능 테스트 쿼리 실행 완료'
\echo '====================================================='
\echo '1. 기본 조회 성능: 건물별 호실 현황, 관리비 현황'
\echo '2. 복잡한 집계: 수익 분석, 연간 추이 분석'
\echo '3. 검침 데이터: 대용량 집계, 시계열 분석'
\echo '4. 고지서/수납: 미납 현황, 수납 패턴'
\echo '5. 동시성 테스트: 관리비 계산, 고지서 생성'
\echo '6. 인덱스 효율성: 복합 인덱스, 날짜 범위, 텍스트 검색'
\echo '7. 메모리 사용량: 대용량 조인, 집계 함수'
\echo '8. 성능 모니터링: 통계 분석, 슬로우 쿼리'
\echo '9. 최적화 권장: 인덱스 후보, 파티셔닝 후보'
\echo '10. 테스트 요약: 전체 결과 리포트'
\echo '====================================================='