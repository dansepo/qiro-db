-- =====================================================
-- QIRO 대용량 데이터 처리 최적화
-- 파티셔닝 및 아카이빙 전략
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 대용량 데이터 환경에서의 성능 최적화를 위한 파티셔닝 전략
-- =====================================================

-- =====================================================
-- 1. 파티셔닝 전략 개요
-- =====================================================

/*
파티셔닝 대상 테이블 및 전략:

1. 시간 기반 파티셔닝 (Range Partitioning):
   - business_verification_records: 월별 파티셔닝
   - phone_verification_tokens: 월별 파티셔닝
   - audit_logs: 월별 파티셔닝 (향후 구현)

2. 해시 파티셔닝 (Hash Partitioning):
   - users: company_id 기반 해시 파티셔닝 (대용량 시)
   - building_groups: company_id 기반 해시 파티셔닝 (대용량 시)

3. 리스트 파티셔닝 (List Partitioning):
   - companies: verification_status 기반 (필요시)
*/

-- =====================================================
-- 2. Business Verification Records 월별 파티셔닝
-- =====================================================

-- 기존 테이블을 파티션 테이블로 변환하는 함수
CREATE OR REPLACE FUNCTION convert_business_verification_to_partitioned()
RETURNS VOID AS $
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    current_month DATE;
BEGIN
    -- 파티션 테이블이 이미 존재하는지 확인
    IF EXISTS (
        SELECT 1 FROM pg_partitioned_table 
        WHERE partrelid = 'business_verification_records'::regclass
    ) THEN
        RAISE NOTICE '이미 파티션된 테이블입니다: business_verification_records';
        RETURN;
    END IF;

    -- 기존 데이터의 날짜 범위 확인
    SELECT 
        DATE_TRUNC('month', MIN(created_at))::DATE,
        DATE_TRUNC('month', MAX(created_at))::DATE + INTERVAL '1 month' - INTERVAL '1 day'
    INTO start_date, end_date
    FROM business_verification_records;

    -- 데이터가 없으면 현재 월부터 시작
    IF start_date IS NULL THEN
        start_date := DATE_TRUNC('month', CURRENT_DATE)::DATE;
        end_date := start_date + INTERVAL '1 month' - INTERVAL '1 day';
    END IF;

    RAISE NOTICE '파티셔닝 범위: % ~ %', start_date, end_date;

    -- 새로운 파티션 테이블 생성 (기존 테이블 백업 후)
    EXECUTE 'CREATE TABLE business_verification_records_backup AS SELECT * FROM business_verification_records';
    
    -- 기존 테이블 삭제 및 파티션 테이블 생성
    DROP TABLE business_verification_records CASCADE;
    
    CREATE TABLE business_verification_records (
        verification_id UUID DEFAULT gen_random_uuid(),
        company_id UUID NOT NULL,
        verification_type VARCHAR(50) NOT NULL 
            CHECK (verification_type IN ('BUSINESS_REGISTRATION', 'PHONE_VERIFICATION', 'EMAIL_VERIFICATION')),
        verification_data JSONB NOT NULL,
        verification_status VARCHAR(20) NOT NULL 
            CHECK (verification_status IN ('PENDING', 'SUCCESS', 'FAILED', 'EXPIRED')),
        verification_date TIMESTAMPTZ,
        expiry_date TIMESTAMPTZ,
        error_message TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (verification_id, created_at)
    ) PARTITION BY RANGE (created_at);

    -- 월별 파티션 생성
    current_month := start_date;
    WHILE current_month <= end_date + INTERVAL '3 months' LOOP
        partition_name := 'business_verification_records_' || TO_CHAR(current_month, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF business_verification_records 
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            current_month,
            current_month + INTERVAL '1 month'
        );
        
        -- 파티션별 인덱스 생성
        EXECUTE format('CREATE INDEX %I ON %I (company_id)', 
                      'idx_' || partition_name || '_company_id', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (verification_type)', 
                      'idx_' || partition_name || '_type', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (verification_status)', 
                      'idx_' || partition_name || '_status', partition_name);
        
        current_month := current_month + INTERVAL '1 month';
    END LOOP;

    -- 백업 데이터 복원
    INSERT INTO business_verification_records SELECT * FROM business_verification_records_backup;
    DROP TABLE business_verification_records_backup;

    RAISE NOTICE '파티셔닝 완료: business_verification_records';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. Phone Verification Tokens 월별 파티셔닝
-- =====================================================

CREATE OR REPLACE FUNCTION convert_phone_verification_to_partitioned()
RETURNS VOID AS $
DECLARE
    start_date DATE;
    end_date DATE;
    partition_name TEXT;
    current_month DATE;
BEGIN
    -- 파티션 테이블이 이미 존재하는지 확인
    IF EXISTS (
        SELECT 1 FROM pg_partitioned_table 
        WHERE partrelid = 'phone_verification_tokens'::regclass
    ) THEN
        RAISE NOTICE '이미 파티션된 테이블입니다: phone_verification_tokens';
        RETURN;
    END IF;

    -- 기존 데이터의 날짜 범위 확인
    SELECT 
        DATE_TRUNC('month', MIN(created_at))::DATE,
        DATE_TRUNC('month', MAX(created_at))::DATE + INTERVAL '1 month' - INTERVAL '1 day'
    INTO start_date, end_date
    FROM phone_verification_tokens;

    -- 데이터가 없으면 현재 월부터 시작
    IF start_date IS NULL THEN
        start_date := DATE_TRUNC('month', CURRENT_DATE)::DATE;
        end_date := start_date + INTERVAL '1 month' - INTERVAL '1 day';
    END IF;

    -- 새로운 파티션 테이블 생성
    EXECUTE 'CREATE TABLE phone_verification_tokens_backup AS SELECT * FROM phone_verification_tokens';
    
    DROP TABLE phone_verification_tokens CASCADE;
    
    CREATE TABLE phone_verification_tokens (
        token_id UUID DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL,
        phone_number VARCHAR(20) NOT NULL,
        verification_code VARCHAR(10) NOT NULL,
        token_hash VARCHAR(255) NOT NULL,
        expires_at TIMESTAMPTZ NOT NULL,
        is_used BOOLEAN NOT NULL DEFAULT false,
        used_at TIMESTAMPTZ,
        attempts INTEGER DEFAULT 0,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        PRIMARY KEY (token_id, created_at)
    ) PARTITION BY RANGE (created_at);

    -- 월별 파티션 생성 (과거 3개월 + 미래 3개월)
    current_month := start_date - INTERVAL '3 months';
    WHILE current_month <= end_date + INTERVAL '3 months' LOOP
        partition_name := 'phone_verification_tokens_' || TO_CHAR(current_month, 'YYYY_MM');
        
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF phone_verification_tokens 
             FOR VALUES FROM (%L) TO (%L)',
            partition_name,
            current_month,
            current_month + INTERVAL '1 month'
        );
        
        -- 파티션별 인덱스 생성
        EXECUTE format('CREATE INDEX %I ON %I (user_id)', 
                      'idx_' || partition_name || '_user_id', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (phone_number)', 
                      'idx_' || partition_name || '_phone', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (token_hash)', 
                      'idx_' || partition_name || '_hash', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (expires_at)', 
                      'idx_' || partition_name || '_expires', partition_name);
        
        current_month := current_month + INTERVAL '1 month';
    END LOOP;

    -- 백업 데이터 복원
    INSERT INTO phone_verification_tokens SELECT * FROM phone_verification_tokens_backup;
    DROP TABLE phone_verification_tokens_backup;

    RAISE NOTICE '파티셔닝 완료: phone_verification_tokens';
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 자동 파티션 생성 함수
-- =====================================================

-- 월별 파티션 자동 생성 함수
CREATE OR REPLACE FUNCTION create_monthly_partitions()
RETURNS TEXT AS $
DECLARE
    table_name TEXT;
    partition_name TEXT;
    next_month DATE;
    result_text TEXT := '';
BEGIN
    next_month := DATE_TRUNC('month', CURRENT_DATE + INTERVAL '1 month')::DATE;
    
    -- Business Verification Records 파티션 생성
    table_name := 'business_verification_records';
    partition_name := table_name || '_' || TO_CHAR(next_month, 'YYYY_MM');
    
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF %I 
             FOR VALUES FROM (%L) TO (%L)',
            partition_name, table_name,
            next_month,
            next_month + INTERVAL '1 month'
        );
        
        -- 인덱스 생성
        EXECUTE format('CREATE INDEX %I ON %I (company_id)', 
                      'idx_' || partition_name || '_company_id', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (verification_type)', 
                      'idx_' || partition_name || '_type', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (verification_status)', 
                      'idx_' || partition_name || '_status', partition_name);
        
        result_text := result_text || 'Created partition: ' || partition_name || E'\n';
    END IF;
    
    -- Phone Verification Tokens 파티션 생성
    table_name := 'phone_verification_tokens';
    partition_name := table_name || '_' || TO_CHAR(next_month, 'YYYY_MM');
    
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = partition_name) THEN
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF %I 
             FOR VALUES FROM (%L) TO (%L)',
            partition_name, table_name,
            next_month,
            next_month + INTERVAL '1 month'
        );
        
        -- 인덱스 생성
        EXECUTE format('CREATE INDEX %I ON %I (user_id)', 
                      'idx_' || partition_name || '_user_id', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (phone_number)', 
                      'idx_' || partition_name || '_phone', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (token_hash)', 
                      'idx_' || partition_name || '_hash', partition_name);
        EXECUTE format('CREATE INDEX %I ON %I (expires_at)', 
                      'idx_' || partition_name || '_expires', partition_name);
        
        result_text := result_text || 'Created partition: ' || partition_name || E'\n';
    END IF;
    
    IF result_text = '' THEN
        result_text := 'No new partitions needed for ' || TO_CHAR(next_month, 'YYYY-MM');
    END IF;
    
    RETURN result_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 파티션 정리 및 아카이빙 함수
-- =====================================================

-- 오래된 파티션 아카이빙 함수
CREATE OR REPLACE FUNCTION archive_old_partitions(
    p_months_to_keep INTEGER DEFAULT 12
)
RETURNS TEXT AS $
DECLARE
    partition_record RECORD;
    archive_date DATE;
    result_text TEXT := '';
BEGIN
    archive_date := DATE_TRUNC('month', CURRENT_DATE - (p_months_to_keep || ' months')::INTERVAL)::DATE;
    
    -- 아카이빙 대상 파티션 조회
    FOR partition_record IN
        SELECT 
            schemaname,
            tablename,
            SUBSTRING(tablename FROM '(\d{4}_\d{2})$') as partition_date_str
        FROM pg_tables 
        WHERE tablename ~ '^(business_verification_records|phone_verification_tokens)_\d{4}_\d{2}$'
        AND schemaname = current_schema()
    LOOP
        -- 파티션 날짜가 아카이빙 기준보다 오래된 경우
        IF TO_DATE(partition_record.partition_date_str, 'YYYY_MM') < archive_date THEN
            -- 아카이브 테이블로 데이터 이동
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS archive_%s AS SELECT * FROM %s WITH NO DATA',
                partition_record.tablename,
                partition_record.tablename
            );
            
            EXECUTE format(
                'INSERT INTO archive_%s SELECT * FROM %s',
                partition_record.tablename,
                partition_record.tablename
            );
            
            -- 원본 파티션 삭제
            EXECUTE format('DROP TABLE %s', partition_record.tablename);
            
            result_text := result_text || 'Archived partition: ' || partition_record.tablename || E'\n';
        END IF;
    END LOOP;
    
    IF result_text = '' THEN
        result_text := 'No partitions to archive (keeping ' || p_months_to_keep || ' months)';
    END IF;
    
    RETURN result_text;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 대용량 데이터 처리를 위한 배치 처리 함수
-- =====================================================

-- 대용량 데이터 배치 삽입 함수
CREATE OR REPLACE FUNCTION batch_insert_verification_records(
    p_records JSONB,
    p_batch_size INTEGER DEFAULT 1000
)
RETURNS INTEGER AS $
DECLARE
    record_count INTEGER;
    batch_start INTEGER := 1;
    batch_end INTEGER;
    current_batch JSONB;
    inserted_count INTEGER := 0;
BEGIN
    record_count := jsonb_array_length(p_records);
    
    WHILE batch_start <= record_count LOOP
        batch_end := LEAST(batch_start + p_batch_size - 1, record_count);
        current_batch := jsonb_path_query_array(p_records, '$[' || (batch_start-1) || ' to ' || (batch_end-1) || ']');
        
        -- 배치 단위로 삽입
        INSERT INTO business_verification_records (
            company_id,
            verification_type,
            verification_data,
            verification_status,
            verification_date,
            expiry_date,
            error_message
        )
        SELECT 
            (rec->>'company_id')::UUID,
            rec->>'verification_type',
            rec->'verification_data',
            rec->>'verification_status',
            (rec->>'verification_date')::TIMESTAMPTZ,
            (rec->>'expiry_date')::TIMESTAMPTZ,
            rec->>'error_message'
        FROM jsonb_array_elements(current_batch) AS rec;
        
        inserted_count := inserted_count + (batch_end - batch_start + 1);
        batch_start := batch_end + 1;
        
        -- 진행 상황 로그
        IF batch_start % (p_batch_size * 10) = 1 THEN
            RAISE NOTICE '배치 처리 진행률: %/%', inserted_count, record_count;
        END IF;
    END LOOP;
    
    RETURN inserted_count;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 동시성 제어 최적화
-- =====================================================

-- 락 대기 시간 최적화 설정
CREATE OR REPLACE FUNCTION optimize_concurrency_settings()
RETURNS VOID AS $
BEGIN
    -- 락 타임아웃 설정 (30초)
    EXECUTE 'SET lock_timeout = ''30s''';
    
    -- 데드락 타임아웃 설정 (1초)
    EXECUTE 'SET deadlock_timeout = ''1s''';
    
    -- 문장 타임아웃 설정 (5분)
    EXECUTE 'SET statement_timeout = ''5min''';
    
    -- 유휴 트랜잭션 타임아웃 설정 (10분)
    EXECUTE 'SET idle_in_transaction_session_timeout = ''10min''';
    
    RAISE NOTICE '동시성 제어 설정이 최적화되었습니다.';
END;
$ LANGUAGE plpgsql;

-- 테이블별 락 모니터링 함수
CREATE OR REPLACE FUNCTION monitor_table_locks()
RETURNS TABLE (
    lock_type TEXT,
    database_name TEXT,
    relation_name TEXT,
    mode TEXT,
    granted BOOLEAN,
    pid INTEGER,
    query TEXT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        l.locktype::TEXT,
        d.datname::TEXT,
        COALESCE(c.relname, l.locktype)::TEXT,
        l.mode::TEXT,
        l.granted,
        l.pid,
        a.query::TEXT
    FROM pg_locks l
    LEFT JOIN pg_database d ON l.database = d.oid
    LEFT JOIN pg_class c ON l.relation = c.oid
    LEFT JOIN pg_stat_activity a ON l.pid = a.pid
    WHERE l.locktype IN ('relation', 'tuple', 'page')
    AND d.datname = current_database()
    ORDER BY l.granted, l.pid;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 8. 성능 모니터링 및 통계 수집
-- =====================================================

-- 파티션별 성능 통계 뷰
CREATE OR REPLACE VIEW v_partition_performance_stats AS
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    n_tup_ins as inserts,
    n_tup_upd as updates,
    n_tup_del as deletes,
    n_live_tup as live_tuples,
    n_dead_tup as dead_tuples,
    ROUND(n_dead_tup::NUMERIC / GREATEST(n_live_tup, 1) * 100, 2) as dead_tuple_ratio,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE tablename ~ '^(business_verification_records|phone_verification_tokens)_\d{4}_\d{2}$'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- 쿼리 성능 모니터링 뷰
CREATE OR REPLACE VIEW v_slow_queries AS
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    min_exec_time,
    stddev_exec_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query LIKE '%business_verification_records%' 
   OR query LIKE '%phone_verification_tokens%'
   OR query LIKE '%companies%'
   OR query LIKE '%users%'
ORDER BY total_exec_time DESC
LIMIT 20;

-- =====================================================
-- 9. 자동 유지보수 작업 스케줄링
-- =====================================================

-- 파티션 유지보수 작업 함수
CREATE OR REPLACE FUNCTION partition_maintenance_job()
RETURNS TEXT AS $
DECLARE
    result_text TEXT := '';
    partition_result TEXT;
    archive_result TEXT;
BEGIN
    -- 새 파티션 생성
    SELECT create_monthly_partitions() INTO partition_result;
    result_text := result_text || 'Partition Creation: ' || partition_result || E'\n';
    
    -- 오래된 파티션 아카이빙 (12개월 보관)
    SELECT archive_old_partitions(12) INTO archive_result;
    result_text := result_text || 'Partition Archiving: ' || archive_result || E'\n';
    
    -- 통계 정보 업데이트
    ANALYZE business_verification_records;
    ANALYZE phone_verification_tokens;
    result_text := result_text || 'Statistics Updated' || E'\n';
    
    -- 결과 로그
    INSERT INTO maintenance_log (job_type, job_result, executed_at)
    VALUES ('partition_maintenance', result_text, now());
    
    RETURN result_text;
END;
$ LANGUAGE plpgsql;

-- 유지보수 로그 테이블 생성
CREATE TABLE IF NOT EXISTS maintenance_log (
    log_id BIGSERIAL PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,
    job_result TEXT,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    execution_time_ms INTEGER
);

-- =====================================================
-- 10. 성능 테스트 및 벤치마킹 함수
-- =====================================================

-- 파티션 성능 테스트 함수
CREATE OR REPLACE FUNCTION test_partition_performance(
    p_test_records INTEGER DEFAULT 10000
)
RETURNS TABLE (
    test_type TEXT,
    execution_time_ms BIGINT,
    records_processed INTEGER
) AS $
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    test_data JSONB;
    i INTEGER;
BEGIN
    -- 테스트 데이터 생성
    test_data := '[]'::JSONB;
    FOR i IN 1..p_test_records LOOP
        test_data := test_data || jsonb_build_object(
            'company_id', gen_random_uuid(),
            'verification_type', 'BUSINESS_REGISTRATION',
            'verification_data', '{}',
            'verification_status', 'PENDING',
            'verification_date', now(),
            'expiry_date', now() + INTERVAL '30 days'
        );
    END LOOP;
    
    -- 삽입 성능 테스트
    start_time := clock_timestamp();
    PERFORM batch_insert_verification_records(test_data, 1000);
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        'Batch Insert'::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT,
        p_test_records;
    
    -- 조회 성능 테스트
    start_time := clock_timestamp();
    PERFORM COUNT(*) FROM business_verification_records 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days';
    end_time := clock_timestamp();
    
    RETURN QUERY SELECT 
        'Range Query'::TEXT,
        EXTRACT(EPOCH FROM (end_time - start_time) * 1000)::BIGINT,
        (SELECT COUNT(*)::INTEGER FROM business_verification_records 
         WHERE created_at >= CURRENT_DATE - INTERVAL '30 days');
    
    -- 테스트 데이터 정리
    DELETE FROM business_verification_records 
    WHERE verification_status = 'PENDING' 
    AND verification_type = 'BUSINESS_REGISTRATION'
    AND created_at >= start_time;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 11. 코멘트 및 문서화
-- =====================================================

COMMENT ON FUNCTION convert_business_verification_to_partitioned() IS '사업자 인증 기록 테이블을 월별 파티션으로 변환';
COMMENT ON FUNCTION convert_phone_verification_to_partitioned() IS '전화번호 인증 토큰 테이블을 월별 파티션으로 변환';
COMMENT ON FUNCTION create_monthly_partitions() IS '월별 파티션 자동 생성 (스케줄러용)';
COMMENT ON FUNCTION archive_old_partitions(INTEGER) IS '오래된 파티션 아카이빙 (기본 12개월 보관)';
COMMENT ON FUNCTION batch_insert_verification_records(JSONB, INTEGER) IS '대용량 인증 기록 배치 삽입';
COMMENT ON FUNCTION optimize_concurrency_settings() IS '동시성 제어 설정 최적화';
COMMENT ON FUNCTION monitor_table_locks() IS '테이블 락 모니터링';
COMMENT ON FUNCTION partition_maintenance_job() IS '파티션 유지보수 작업 (스케줄러용)';
COMMENT ON FUNCTION test_partition_performance(INTEGER) IS '파티션 성능 테스트 및 벤치마킹';

COMMENT ON VIEW v_partition_performance_stats IS '파티션별 성능 통계 모니터링';
COMMENT ON VIEW v_slow_queries IS '느린 쿼리 모니터링 (pg_stat_statements 필요)';

COMMENT ON TABLE maintenance_log IS '시스템 유지보수 작업 로그';

-- =====================================================
-- 12. 초기화 및 설정 완료 메시지
-- =====================================================

DO $
BEGIN
    RAISE NOTICE '대용량 데이터 처리 최적화 설정이 완료되었습니다.';
    RAISE NOTICE '파티셔닝을 적용하려면 다음 함수를 실행하세요:';
    RAISE NOTICE '  - SELECT convert_business_verification_to_partitioned();';
    RAISE NOTICE '  - SELECT convert_phone_verification_to_partitioned();';
    RAISE NOTICE '정기 유지보수를 위해 다음 함수를 스케줄링하세요:';
    RAISE NOTICE '  - SELECT partition_maintenance_job(); (월 1회)';
END
$;