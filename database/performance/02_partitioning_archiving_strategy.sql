-- =====================================================
-- 데이터 파티셔닝 및 아카이빙 전략 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 대용량 데이터 처리를 위한 파티셔닝 및 아카이빙
-- =====================================================

\set ECHO all
\timing on

-- =====================================================
-- 1. 시간 기반 파티셔닝 전략
-- =====================================================

-- 1.1 청구월 데이터 파티셔닝 (연도별)
-- 기존 테이블을 파티션 테이블로 변환하는 예시 (실제 운영에서는 신중히 진행)

-- 파티션 마스터 테이블 생성 (새로운 구조)
CREATE TABLE billing_months_partitioned (
    LIKE billing_months INCLUDING ALL
) PARTITION BY RANGE (billing_year);

-- 연도별 파티션 생성 (2023-2025년)
CREATE TABLE billing_months_2023 PARTITION OF billing_months_partitioned
    FOR VALUES FROM (2023) TO (2024);

CREATE TABLE billing_months_2024 PARTITION OF billing_months_partitioned
    FOR VALUES FROM (2024) TO (2025);

CREATE TABLE billing_months_2025 PARTITION OF billing_months_partitioned
    FOR VALUES FROM (2025) TO (2026);

-- 향후 연도 파티션 자동 생성 함수
CREATE OR REPLACE FUNCTION create_billing_month_partition(year_val INTEGER)
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
    start_val INTEGER;
    end_val INTEGER;
BEGIN
    partition_name := 'billing_months_' || year_val;
    start_val := year_val;
    end_val := year_val + 1;
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF billing_months_partitioned
                    FOR VALUES FROM (%s) TO (%s)',
                   partition_name, start_val, end_val);
    
    RAISE NOTICE '파티션 생성됨: %', partition_name;
END;
$$ LANGUAGE plpgsql;

-- 1.2 검침 데이터 파티셔닝 (월별)
-- 검침 데이터는 월별로 파티셔닝하여 더 세밀한 관리

CREATE TABLE unit_meter_readings_partitioned (
    LIKE unit_meter_readings INCLUDING ALL
) PARTITION BY RANGE (billing_month_id);

-- 월별 파티션 생성 함수
CREATE OR REPLACE FUNCTION create_meter_reading_partition(
    start_billing_month_id BIGINT,
    end_billing_month_id BIGINT,
    partition_suffix TEXT
)
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
BEGIN
    partition_name := 'unit_meter_readings_' || partition_suffix;
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF unit_meter_readings_partitioned
                    FOR VALUES FROM (%s) TO (%s)',
                   partition_name, start_billing_month_id, end_billing_month_id);
    
    -- 파티션별 인덱스 생성
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (unit_id, meter_type)',
                   'idx_' || partition_name || '_unit_type', partition_name);
    
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (meter_type, usage_amount)',
                   'idx_' || partition_name || '_type_usage', partition_name);
    
    RAISE NOTICE '검침 데이터 파티션 생성됨: %', partition_name;
END;
$$ LANGUAGE plpgsql;

-- 1.3 관리비 산정 데이터 파티셔닝 (월별)
CREATE TABLE monthly_fees_partitioned (
    LIKE monthly_fees INCLUDING ALL
) PARTITION BY RANGE (billing_month_id);

-- 관리비 파티션 생성 함수
CREATE OR REPLACE FUNCTION create_monthly_fees_partition(
    start_billing_month_id BIGINT,
    end_billing_month_id BIGINT,
    partition_suffix TEXT
)
RETURNS VOID AS $$
DECLARE
    partition_name TEXT;
BEGIN
    partition_name := 'monthly_fees_' || partition_suffix;
    
    EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF monthly_fees_partitioned
                    FOR VALUES FROM (%s) TO (%s)',
                   partition_name, start_billing_month_id, end_billing_month_id);
    
    -- 파티션별 인덱스 생성
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (unit_id, fee_item_id)',
                   'idx_' || partition_name || '_unit_item', partition_name);
    
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I (fee_item_id, calculated_amount)',
                   'idx_' || partition_name || '_item_amount', partition_name);
    
    RAISE NOTICE '관리비 산정 파티션 생성됨: %', partition_name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 자동 파티션 관리
-- =====================================================

-- 2.1 파티션 자동 생성 및 관리 함수
CREATE OR REPLACE FUNCTION maintain_partitions()
RETURNS VOID AS $$
DECLARE
    current_year INTEGER;
    next_year INTEGER;
    current_month INTEGER;
    billing_month_rec RECORD;
BEGIN
    current_year := EXTRACT(YEAR FROM CURRENT_DATE);
    next_year := current_year + 1;
    current_month := EXTRACT(MONTH FROM CURRENT_DATE);
    
    -- 다음 연도 청구월 파티션 생성
    PERFORM create_billing_month_partition(next_year);
    
    -- 향후 3개월간의 검침/관리비 파티션 생성
    FOR billing_month_rec IN 
        SELECT id, billing_year, billing_month
        FROM billing_months 
        WHERE billing_year * 100 + billing_month >= 
              current_year * 100 + current_month
        AND billing_year * 100 + billing_month <= 
            current_year * 100 + current_month + 3
        ORDER BY billing_year, billing_month
    LOOP
        -- 검침 데이터 파티션
        PERFORM create_meter_reading_partition(
            billing_month_rec.id,
            billing_month_rec.id + 1,
            billing_month_rec.billing_year || '_' || 
            LPAD(billing_month_rec.billing_month::TEXT, 2, '0')
        );
        
        -- 관리비 산정 파티션
        PERFORM create_monthly_fees_partition(
            billing_month_rec.id,
            billing_month_rec.id + 1,
            billing_month_rec.billing_year || '_' || 
            LPAD(billing_month_rec.billing_month::TEXT, 2, '0')
        );
    END LOOP;
    
    RAISE NOTICE '파티션 유지보수 완료: %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- 2.2 파티션 정리 함수 (오래된 파티션 삭제)
CREATE OR REPLACE FUNCTION cleanup_old_partitions(retention_years INTEGER DEFAULT 7)
RETURNS VOID AS $$
DECLARE
    cutoff_year INTEGER;
    partition_rec RECORD;
    partition_name TEXT;
BEGIN
    cutoff_year := EXTRACT(YEAR FROM CURRENT_DATE) - retention_years;
    
    -- 오래된 청구월 파티션 삭제
    FOR partition_rec IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'billing_months_%'
        AND tablename ~ '^billing_months_[0-9]{4}$'
        AND SUBSTRING(tablename FROM 'billing_months_([0-9]{4})')::INTEGER < cutoff_year
    LOOP
        partition_name := partition_rec.tablename;
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', partition_name);
        RAISE NOTICE '오래된 파티션 삭제됨: %', partition_name;
    END LOOP;
    
    -- 오래된 검침 데이터 파티션 삭제
    FOR partition_rec IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'unit_meter_readings_%'
        AND tablename ~ '^unit_meter_readings_[0-9]{4}_[0-9]{2}$'
        AND SUBSTRING(tablename FROM 'unit_meter_readings_([0-9]{4})_')::INTEGER < cutoff_year
    LOOP
        partition_name := partition_rec.tablename;
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', partition_name);
        RAISE NOTICE '오래된 검침 파티션 삭제됨: %', partition_name;
    END LOOP;
    
    -- 오래된 관리비 파티션 삭제
    FOR partition_rec IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename LIKE 'monthly_fees_%'
        AND tablename ~ '^monthly_fees_[0-9]{4}_[0-9]{2}$'
        AND SUBSTRING(tablename FROM 'monthly_fees_([0-9]{4})_')::INTEGER < cutoff_year
    LOOP
        partition_name := partition_rec.tablename;
        EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', partition_name);
        RAISE NOTICE '오래된 관리비 파티션 삭제됨: %', partition_name;
    END LOOP;
    
    RAISE NOTICE '파티션 정리 완료: % 년 이전 데이터 삭제', cutoff_year;
END;
$$ LANGUAGE plpgsql;-
- =====================================================
-- 3. 데이터 아카이빙 전략
-- =====================================================

-- 3.1 아카이브 테이블 생성
-- 과거 데이터를 별도 스키마로 이동하여 성능 향상

-- 아카이브 스키마 생성
CREATE SCHEMA IF NOT EXISTS archive;

-- 아카이브 테이블 생성 (압축 적용)
CREATE TABLE archive.billing_months_archive (
    LIKE billing_months INCLUDING ALL
) WITH (fillfactor = 100);  -- 압축 최적화

CREATE TABLE archive.unit_meter_readings_archive (
    LIKE unit_meter_readings INCLUDING ALL
) WITH (fillfactor = 100);

CREATE TABLE archive.monthly_fees_archive (
    LIKE monthly_fees INCLUDING ALL
) WITH (fillfactor = 100);

CREATE TABLE archive.invoices_archive (
    LIKE invoices INCLUDING ALL
) WITH (fillfactor = 100);

CREATE TABLE archive.payments_archive (
    LIKE payments INCLUDING ALL
) WITH (fillfactor = 100);

-- 3.2 데이터 아카이빙 함수
CREATE OR REPLACE FUNCTION archive_old_data(archive_years_ago INTEGER DEFAULT 3)
RETURNS VOID AS $$
DECLARE
    cutoff_date DATE;
    cutoff_year INTEGER;
    archived_count INTEGER;
    total_archived INTEGER := 0;
BEGIN
    cutoff_date := CURRENT_DATE - (archive_years_ago || ' years')::INTERVAL;
    cutoff_year := EXTRACT(YEAR FROM cutoff_date);
    
    RAISE NOTICE '아카이빙 시작: % 년 이전 데이터 (기준일: %)', archive_years_ago, cutoff_date;
    
    -- 1. 청구월 데이터 아카이빙
    WITH archived_billing AS (
        DELETE FROM billing_months 
        WHERE billing_year < cutoff_year
        RETURNING *
    )
    INSERT INTO archive.billing_months_archive 
    SELECT * FROM archived_billing;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    total_archived := total_archived + archived_count;
    RAISE NOTICE '청구월 데이터 아카이빙: % 건', archived_count;
    
    -- 2. 검침 데이터 아카이빙 (청구월 기준)
    WITH archived_readings AS (
        DELETE FROM unit_meter_readings umr
        USING billing_months bm
        WHERE umr.billing_month_id = bm.id
        AND bm.billing_year < cutoff_year
        RETURNING umr.*
    )
    INSERT INTO archive.unit_meter_readings_archive 
    SELECT * FROM archived_readings;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    total_archived := total_archived + archived_count;
    RAISE NOTICE '검침 데이터 아카이빙: % 건', archived_count;
    
    -- 3. 관리비 산정 데이터 아카이빙
    WITH archived_fees AS (
        DELETE FROM monthly_fees mf
        USING billing_months bm
        WHERE mf.billing_month_id = bm.id
        AND bm.billing_year < cutoff_year
        RETURNING mf.*
    )
    INSERT INTO archive.monthly_fees_archive 
    SELECT * FROM archived_fees;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    total_archived := total_archived + archived_count;
    RAISE NOTICE '관리비 산정 데이터 아카이빙: % 건', archived_count;
    
    -- 4. 고지서 데이터 아카이빙
    WITH archived_invoices AS (
        DELETE FROM invoices i
        USING billing_months bm
        WHERE i.billing_month_id = bm.id
        AND bm.billing_year < cutoff_year
        RETURNING i.*
    )
    INSERT INTO archive.invoices_archive 
    SELECT * FROM archived_invoices;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    total_archived := total_archived + archived_count;
    RAISE NOTICE '고지서 데이터 아카이빙: % 건', archived_count;
    
    -- 5. 수납 데이터 아카이빙
    WITH archived_payments AS (
        DELETE FROM payments p
        USING invoices i, billing_months bm
        WHERE p.invoice_id = i.id
        AND i.billing_month_id = bm.id
        AND bm.billing_year < cutoff_year
        RETURNING p.*
    )
    INSERT INTO archive.payments_archive 
    SELECT * FROM archived_payments;
    
    GET DIAGNOSTICS archived_count = ROW_COUNT;
    total_archived := total_archived + archived_count;
    RAISE NOTICE '수납 데이터 아카이빙: % 건', archived_count;
    
    -- 아카이브 테이블 압축 및 통계 업데이트
    VACUUM ANALYZE archive.billing_months_archive;
    VACUUM ANALYZE archive.unit_meter_readings_archive;
    VACUUM ANALYZE archive.monthly_fees_archive;
    VACUUM ANALYZE archive.invoices_archive;
    VACUUM ANALYZE archive.payments_archive;
    
    RAISE NOTICE '아카이빙 완료: 총 % 건 처리', total_archived;
END;
$$ LANGUAGE plpgsql;

-- 3.3 아카이브 데이터 조회 뷰 (통합 조회)
CREATE OR REPLACE VIEW v_billing_months_all AS
SELECT *, 'ACTIVE' as data_status FROM billing_months
UNION ALL
SELECT *, 'ARCHIVED' as data_status FROM archive.billing_months_archive;

CREATE OR REPLACE VIEW v_invoices_all AS
SELECT *, 'ACTIVE' as data_status FROM invoices
UNION ALL
SELECT *, 'ARCHIVED' as data_status FROM archive.invoices_archive;

CREATE OR REPLACE VIEW v_payments_all AS
SELECT *, 'ACTIVE' as data_status FROM payments
UNION ALL
SELECT *, 'ARCHIVED' as data_status FROM archive.payments_archive;

-- =====================================================
-- 4. 압축 및 저장 최적화
-- =====================================================

-- 4.1 테이블 압축 설정
-- 읽기 전용에 가까운 과거 데이터 테이블들의 압축률 향상
ALTER TABLE archive.billing_months_archive SET (fillfactor = 100);
ALTER TABLE archive.unit_meter_readings_archive SET (fillfactor = 100);
ALTER TABLE archive.monthly_fees_archive SET (fillfactor = 100);
ALTER TABLE archive.invoices_archive SET (fillfactor = 100);
ALTER TABLE archive.payments_archive SET (fillfactor = 100);

-- 4.2 테이블스페이스 분리 (선택사항)
-- 아카이브 데이터를 별도 저장소로 분리하여 성능 향상
-- CREATE TABLESPACE archive_data LOCATION '/var/lib/postgresql/archive';
-- ALTER TABLE archive.billing_months_archive SET TABLESPACE archive_data;

-- =====================================================
-- 5. 자동화된 유지보수 작업
-- =====================================================

-- 5.1 정기 유지보수 함수
CREATE OR REPLACE FUNCTION scheduled_maintenance()
RETURNS VOID AS $$
BEGIN
    -- 파티션 유지보수
    PERFORM maintain_partitions();
    
    -- 데이터 아카이빙 (3년 이전 데이터)
    PERFORM archive_old_data(3);
    
    -- 오래된 파티션 정리 (7년 이전)
    PERFORM cleanup_old_partitions(7);
    
    -- 통계 정보 업데이트
    ANALYZE;
    
    -- 인덱스 재구성 (필요시)
    REINDEX DATABASE qiro_building_management;
    
    RAISE NOTICE '정기 유지보수 완료: %', CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- 5.2 성능 모니터링 함수
CREATE OR REPLACE FUNCTION performance_health_check()
RETURNS TABLE (
    check_item TEXT,
    status TEXT,
    details TEXT,
    recommendation TEXT
) AS $$
BEGIN
    -- 테이블 크기 체크
    RETURN QUERY
    SELECT 
        'TABLE_SIZE' as check_item,
        CASE 
            WHEN pg_total_relation_size('billing_months') > 1073741824 THEN 'WARNING'  -- 1GB
            ELSE 'OK'
        END as status,
        'billing_months: ' || pg_size_pretty(pg_total_relation_size('billing_months')) as details,
        CASE 
            WHEN pg_total_relation_size('billing_months') > 1073741824 THEN 'Consider partitioning'
            ELSE 'No action needed'
        END as recommendation;
    
    -- 인덱스 사용률 체크
    RETURN QUERY
    SELECT 
        'INDEX_USAGE' as check_item,
        CASE 
            WHEN COUNT(*) FILTER (WHERE idx_scan = 0) > 5 THEN 'WARNING'
            ELSE 'OK'
        END as status,
        'Unused indexes: ' || COUNT(*) FILTER (WHERE idx_scan = 0) as details,
        CASE 
            WHEN COUNT(*) FILTER (WHERE idx_scan = 0) > 5 THEN 'Review and drop unused indexes'
            ELSE 'Index usage is healthy'
        END as recommendation
    FROM pg_stat_user_indexes 
    WHERE schemaname = 'public';
    
    -- 데드 튜플 체크
    RETURN QUERY
    SELECT 
        'DEAD_TUPLES' as check_item,
        CASE 
            WHEN MAX(n_dead_tup::FLOAT / NULLIF(n_live_tup, 0)) > 0.1 THEN 'WARNING'
            ELSE 'OK'
        END as status,
        'Max dead tuple ratio: ' || ROUND(MAX(n_dead_tup::FLOAT / NULLIF(n_live_tup, 0)) * 100, 2) || '%' as details,
        CASE 
            WHEN MAX(n_dead_tup::FLOAT / NULLIF(n_live_tup, 0)) > 0.1 THEN 'Run VACUUM on affected tables'
            ELSE 'Dead tuple levels are acceptable'
        END as recommendation
    FROM pg_stat_user_tables 
    WHERE schemaname = 'public';
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 백업 및 복구 지원
-- =====================================================

-- 6.1 논리적 백업 스크립트 생성 함수
CREATE OR REPLACE FUNCTION generate_backup_script(backup_type TEXT DEFAULT 'FULL')
RETURNS TEXT AS $$
DECLARE
    script_content TEXT;
    current_date_str TEXT;
BEGIN
    current_date_str := TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD');
    
    IF backup_type = 'FULL' THEN
        script_content := format('
-- 전체 데이터베이스 백업 스크립트 (%s)
pg_dump -h localhost -U postgres -d qiro_building_management \
    --format=custom \
    --compress=9 \
    --verbose \
    --file=qiro_backup_full_%s.dump

-- 아카이브 데이터 별도 백업
pg_dump -h localhost -U postgres -d qiro_building_management \
    --format=custom \
    --compress=9 \
    --schema=archive \
    --verbose \
    --file=qiro_backup_archive_%s.dump
        ', current_date_str, current_date_str, current_date_str);
        
    ELSIF backup_type = 'INCREMENTAL' THEN
        script_content := format('
-- 증분 백업 스크립트 (%s)
-- 최근 1개월 데이터만 백업
pg_dump -h localhost -U postgres -d qiro_building_management \
    --format=custom \
    --compress=9 \
    --verbose \
    --where="created_at >= CURRENT_DATE - INTERVAL ''1 month''" \
    --table=billing_months \
    --table=unit_meter_readings \
    --table=monthly_fees \
    --table=invoices \
    --table=payments \
    --file=qiro_backup_incremental_%s.dump
        ', current_date_str, current_date_str);
    END IF;
    
    RETURN script_content;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 파티셔닝 및 아카이빙 완료 메시지
-- =====================================================

\echo '====================================================='
\echo '파티셔닝 및 아카이빙 전략 설정 완료'
\echo '====================================================='
\echo '1. 시간 기반 파티셔닝: 청구월(연도별), 검침/관리비(월별)'
\echo '2. 자동 파티션 관리: 생성, 유지보수, 정리'
\echo '3. 데이터 아카이빙: 과거 데이터 별도 스키마 이동'
\echo '4. 압축 최적화: 아카이브 테이블 압축 설정'
\echo '5. 자동화 유지보수: 정기 작업, 성능 체크'
\echo '6. 백업 지원: 논리적 백업 스크립트 생성'
\echo '====================================================='
\echo '사용법:'
\echo '- 파티션 유지보수: SELECT maintain_partitions();'
\echo '- 데이터 아카이빙: SELECT archive_old_data(3);'
\echo '- 성능 체크: SELECT * FROM performance_health_check();'
\echo '- 정기 유지보수: SELECT scheduled_maintenance();'
\echo '====================================================='