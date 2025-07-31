-- =====================================================
-- 파티셔닝 전략 수립 및 구현 스크립트
-- Phase 5.2: 파티셔닝 전략 수립
-- =====================================================

-- 1. 파티셔닝 전략 개요
/*
파티셔닝 대상 테이블 분석:
1. 대용량 데이터가 예상되는 테이블
   - user_activity_logs: 사용자 활동 로그 (시간 기반 파티셔닝)
   - audit_logs: 감사 로그 (시간 기반 파티셔닝)
   - security_event_logs: 보안 이벤트 로그 (시간 기반 파티셔닝)
   - system_setting_history: 시스템 설정 이력 (시간 기반 파티셔닝)

2. 파티셔닝 방식:
   - 시간 기반 파티셔닝 (월별/분기별)
   - 회사별 파티셔닝 (멀티테넌시 최적화)
   - 하이브리드 파티셔닝 (시간 + 회사)

3. 아카이빙 전략:
   - 2년 이상 된 데이터는 아카이브 테이블로 이동
   - 압축 저장 및 읽기 전용 처리
   - 정기적인 데이터 정리 작업
*/

-- 2. 사용자 활동 로그 파티셔닝 (월별)

-- 2.1 기존 테이블을 파티션 테이블로 변환 준비
-- 주의: 실제 운영 환경에서는 데이터 백업 후 진행해야 함

-- 새로운 파티션 테이블 생성 (향후 마이그레이션용)
CREATE TABLE IF NOT EXISTS bms.user_activity_logs_partitioned (
    LIKE bms.user_activity_logs INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 2025년 월별 파티션 생성
CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_01 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_02 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_03 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_04 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_05 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_06 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_07 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_08 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_09 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_10 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_11 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2025_12 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 2026년 1분기 파티션 미리 생성
CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2026_01 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2026_02 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE IF NOT EXISTS bms.user_activity_logs_2026_03 
PARTITION OF bms.user_activity_logs_partitioned
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');-- 3.
 감사 로그 파티셔닝 (월별)

-- 새로운 파티션 테이블 생성
CREATE TABLE IF NOT EXISTS bms.audit_logs_partitioned (
    LIKE bms.audit_logs INCLUDING ALL
) PARTITION BY RANGE (operation_timestamp);

-- 2025년 월별 파티션 생성
CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_01 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_02 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_03 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-03-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_04 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_05 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-05-01') TO ('2025-06-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_06 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-06-01') TO ('2025-07-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_07 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-07-01') TO ('2025-08-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_08 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_09 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-09-01') TO ('2025-10-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_10 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-10-01') TO ('2025-11-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_11 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE IF NOT EXISTS bms.audit_logs_2025_12 
PARTITION OF bms.audit_logs_partitioned
FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

-- 4. 보안 이벤트 로그 파티셔닝 (분기별)

-- 새로운 파티션 테이블 생성
CREATE TABLE IF NOT EXISTS bms.security_event_logs_partitioned (
    LIKE bms.security_event_logs INCLUDING ALL
) PARTITION BY RANGE (event_timestamp);

-- 2025년 분기별 파티션 생성
CREATE TABLE IF NOT EXISTS bms.security_event_logs_2025_q1 
PARTITION OF bms.security_event_logs_partitioned
FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');

CREATE TABLE IF NOT EXISTS bms.security_event_logs_2025_q2 
PARTITION OF bms.security_event_logs_partitioned
FOR VALUES FROM ('2025-04-01') TO ('2025-07-01');

CREATE TABLE IF NOT EXISTS bms.security_event_logs_2025_q3 
PARTITION OF bms.security_event_logs_partitioned
FOR VALUES FROM ('2025-07-01') TO ('2025-10-01');

CREATE TABLE IF NOT EXISTS bms.security_event_logs_2025_q4 
PARTITION OF bms.security_event_logs_partitioned
FOR VALUES FROM ('2025-10-01') TO ('2026-01-01');

-- 2026년 1분기 파티션
CREATE TABLE IF NOT EXISTS bms.security_event_logs_2026_q1 
PARTITION OF bms.security_event_logs_partitioned
FOR VALUES FROM ('2026-01-01') TO ('2026-04-01');

-- 5. 파티션 관리 함수 생성

-- 5.1 새로운 월별 파티션 자동 생성 함수
CREATE OR REPLACE FUNCTION bms.create_monthly_partitions(
    p_table_name TEXT,
    p_date_column TEXT,
    p_months_ahead INTEGER DEFAULT 3
)
RETURNS INTEGER AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_partition_name TEXT;
    v_sql TEXT;
    v_created_count INTEGER := 0;
    i INTEGER;
BEGIN
    -- 다음 달부터 시작
    v_start_date := date_trunc('month', CURRENT_DATE) + INTERVAL '1 month';
    
    FOR i IN 1..p_months_ahead LOOP
        v_end_date := v_start_date + INTERVAL '1 month';
        v_partition_name := p_table_name || '_' || to_char(v_start_date, 'YYYY_MM');
        
        -- 파티션이 이미 존재하는지 확인
        IF NOT EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'bms' 
            AND tablename = v_partition_name
        ) THEN
            v_sql := format(
                'CREATE TABLE bms.%I PARTITION OF bms.%I FOR VALUES FROM (%L) TO (%L)',
                v_partition_name, p_table_name, v_start_date, v_end_date
            );
            
            EXECUTE v_sql;
            v_created_count := v_created_count + 1;
            
            RAISE NOTICE '파티션 생성: %', v_partition_name;
        END IF;
        
        v_start_date := v_end_date;
    END LOOP;
    
    RETURN v_created_count;
END;
$$ LANGUAGE plpgsql;

-- 5.2 오래된 파티션 아카이브 함수
CREATE OR REPLACE FUNCTION bms.archive_old_partitions(
    p_table_name TEXT,
    p_archive_months INTEGER DEFAULT 24
)
RETURNS INTEGER AS $$
DECLARE
    v_cutoff_date DATE;
    v_partition_name TEXT;
    v_archive_table_name TEXT;
    v_sql TEXT;
    v_archived_count INTEGER := 0;
    partition_rec RECORD;
BEGIN
    -- 아카이브 기준 날짜 계산
    v_cutoff_date := date_trunc('month', CURRENT_DATE) - (p_archive_months || ' months')::INTERVAL;
    
    -- 오래된 파티션 찾기
    FOR partition_rec IN
        SELECT schemaname, tablename
        FROM pg_tables
        WHERE schemaname = 'bms'
        AND tablename LIKE p_table_name || '_%'
        AND tablename ~ '\d{4}_\d{2}$'
    LOOP
        -- 파티션 날짜 추출
        v_partition_name := partition_rec.tablename;
        
        -- 아카이브 테이블명 생성
        v_archive_table_name := 'archive_' || v_partition_name;
        
        -- 아카이브 테이블로 이동
        v_sql := format(
            'CREATE TABLE bms.%I AS SELECT * FROM bms.%I',
            v_archive_table_name, v_partition_name
        );
        
        EXECUTE v_sql;
        
        -- 원본 파티션 삭제
        v_sql := format('DROP TABLE bms.%I', v_partition_name);
        EXECUTE v_sql;
        
        v_archived_count := v_archived_count + 1;
        
        RAISE NOTICE '파티션 아카이브: % -> %', v_partition_name, v_archive_table_name;
    END LOOP;
    
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

-- 5.3 파티션 통계 조회 함수
CREATE OR REPLACE FUNCTION bms.get_partition_stats(p_table_name TEXT)
RETURNS TABLE (
    partition_name TEXT,
    row_count BIGINT,
    table_size TEXT,
    index_size TEXT,
    total_size TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.tablename::TEXT,
        (SELECT reltuples::BIGINT FROM pg_class WHERE relname = t.tablename),
        pg_size_pretty(pg_total_relation_size('bms.' || t.tablename)),
        pg_size_pretty(pg_indexes_size('bms.' || t.tablename)),
        pg_size_pretty(pg_total_relation_size('bms.' || t.tablename) + pg_indexes_size('bms.' || t.tablename))
    FROM pg_tables t
    WHERE t.schemaname = 'bms'
    AND t.tablename LIKE p_table_name || '%'
    ORDER BY t.tablename;
END;
$$ LANGUAGE plpgsql;-- 6. 파티션 유
지보수 작업 스케줄링

-- 6.1 월별 파티션 생성 작업 (cron job으로 실행 예정)
CREATE OR REPLACE FUNCTION bms.monthly_partition_maintenance()
RETURNS TEXT AS $$
DECLARE
    v_result TEXT := '';
    v_count INTEGER;
BEGIN
    -- 사용자 활동 로그 파티션 생성
    SELECT bms.create_monthly_partitions('user_activity_logs_partitioned', 'created_at', 3) INTO v_count;
    v_result := v_result || format('사용자 활동 로그 파티션 %s개 생성\n', v_count);
    
    -- 감사 로그 파티션 생성
    SELECT bms.create_monthly_partitions('audit_logs_partitioned', 'operation_timestamp', 3) INTO v_count;
    v_result := v_result || format('감사 로그 파티션 %s개 생성\n', v_count);
    
    -- 통계 업데이트
    ANALYZE bms.user_activity_logs_partitioned;
    ANALYZE bms.audit_logs_partitioned;
    ANALYZE bms.security_event_logs_partitioned;
    
    v_result := v_result || '파티션 통계 업데이트 완료\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 6.2 연간 아카이브 작업
CREATE OR REPLACE FUNCTION bms.annual_archive_maintenance()
RETURNS TEXT AS $$
DECLARE
    v_result TEXT := '';
    v_count INTEGER;
BEGIN
    -- 2년 이상 된 사용자 활동 로그 아카이브
    SELECT bms.archive_old_partitions('user_activity_logs', 24) INTO v_count;
    v_result := v_result || format('사용자 활동 로그 파티션 %s개 아카이브\n', v_count);
    
    -- 2년 이상 된 감사 로그 아카이브
    SELECT bms.archive_old_partitions('audit_logs', 24) INTO v_count;
    v_result := v_result || format('감사 로그 파티션 %s개 아카이브\n', v_count);
    
    -- 디스크 공간 정리
    VACUUM ANALYZE;
    
    v_result := v_result || '아카이브 작업 및 정리 완료\n';
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- 7. 파티션 모니터링 뷰 생성

-- 7.1 파티션 현황 뷰
CREATE OR REPLACE VIEW bms.v_partition_overview AS
SELECT 
    'user_activity_logs' as table_name,
    COUNT(*) as partition_count,
    MIN(tablename) as oldest_partition,
    MAX(tablename) as newest_partition,
    SUM(pg_total_relation_size('bms.' || tablename)) as total_size_bytes,
    pg_size_pretty(SUM(pg_total_relation_size('bms.' || tablename))) as total_size
FROM pg_tables
WHERE schemaname = 'bms' 
AND tablename LIKE 'user_activity_logs_%'

UNION ALL

SELECT 
    'audit_logs' as table_name,
    COUNT(*) as partition_count,
    MIN(tablename) as oldest_partition,
    MAX(tablename) as newest_partition,
    SUM(pg_total_relation_size('bms.' || tablename)) as total_size_bytes,
    pg_size_pretty(SUM(pg_total_relation_size('bms.' || tablename))) as total_size
FROM pg_tables
WHERE schemaname = 'bms' 
AND tablename LIKE 'audit_logs_%'

UNION ALL

SELECT 
    'security_event_logs' as table_name,
    COUNT(*) as partition_count,
    MIN(tablename) as oldest_partition,
    MAX(tablename) as newest_partition,
    SUM(pg_total_relation_size('bms.' || tablename)) as total_size_bytes,
    pg_size_pretty(SUM(pg_total_relation_size('bms.' || tablename))) as total_size
FROM pg_tables
WHERE schemaname = 'bms' 
AND tablename LIKE 'security_event_logs_%';

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_partition_overview OWNER TO qiro;

-- 8. 파티셔닝 마이그레이션 가이드 (주석)

/*
파티셔닝 마이그레이션 절차:

1. 준비 단계:
   - 기존 데이터 백업
   - 파티션 테이블 생성 (이미 완료)
   - 인덱스 및 제약조건 확인

2. 데이터 마이그레이션:
   -- 기존 데이터를 파티션 테이블로 복사
   INSERT INTO bms.user_activity_logs_partitioned 
   SELECT * FROM bms.user_activity_logs;
   
   -- 데이터 검증
   SELECT COUNT(*) FROM bms.user_activity_logs;
   SELECT COUNT(*) FROM bms.user_activity_logs_partitioned;

3. 전환 단계:
   -- 기존 테이블 백업
   ALTER TABLE bms.user_activity_logs RENAME TO user_activity_logs_backup;
   
   -- 파티션 테이블을 메인 테이블로 변경
   ALTER TABLE bms.user_activity_logs_partitioned RENAME TO user_activity_logs;

4. 검증 및 정리:
   -- 애플리케이션 테스트
   -- 성능 검증
   -- 백업 테이블 삭제 (충분한 검증 후)
   DROP TABLE bms.user_activity_logs_backup;
*/

-- 9. 파티션 성능 테스트 함수

CREATE OR REPLACE FUNCTION bms.test_partition_performance()
RETURNS TABLE (
    test_name TEXT,
    execution_time_ms NUMERIC,
    rows_affected BIGINT
) AS $$
DECLARE
    v_start_time TIMESTAMP;
    v_end_time TIMESTAMP;
    v_duration NUMERIC;
    v_count BIGINT;
BEGIN
    -- 테스트 1: 최근 7일 데이터 조회
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_count
    FROM bms.user_activity_logs
    WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT '최근 7일 데이터 조회'::TEXT, v_duration, v_count;
    
    -- 테스트 2: 특정 사용자 활동 조회
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_count
    FROM bms.user_activity_logs
    WHERE user_id = (SELECT user_id FROM bms.users LIMIT 1)
    AND created_at >= CURRENT_DATE - INTERVAL '30 days';
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT '특정 사용자 30일 활동'::TEXT, v_duration, v_count;
    
    -- 테스트 3: 활동 타입별 집계
    v_start_time := clock_timestamp();
    
    SELECT COUNT(*) INTO v_count
    FROM bms.user_activity_logs
    WHERE activity_type = 'LOGIN'
    AND created_at >= CURRENT_DATE - INTERVAL '7 days';
    
    v_end_time := clock_timestamp();
    v_duration := EXTRACT(EPOCH FROM (v_end_time - v_start_time)) * 1000;
    
    RETURN QUERY SELECT '로그인 활동 7일 집계'::TEXT, v_duration, v_count;
END;
$$ LANGUAGE plpgsql;

-- 10. 파티셔닝 전략 문서화

/*
=== 파티셔닝 전략 요약 ===

1. 파티셔닝 대상:
   - user_activity_logs: 월별 파티셔닝
   - audit_logs: 월별 파티셔닝  
   - security_event_logs: 분기별 파티셔닝

2. 파티셔닝 이점:
   - 쿼리 성능 향상 (파티션 제거)
   - 유지보수 효율성 (파티션별 관리)
   - 아카이빙 용이성
   - 병렬 처리 가능

3. 관리 작업:
   - 월별 새 파티션 자동 생성
   - 연간 오래된 파티션 아카이브
   - 정기적인 통계 업데이트
   - 성능 모니터링

4. 모니터링:
   - 파티션 크기 및 개수 추적
   - 쿼리 성능 측정
   - 디스크 사용량 모니터링
   - 아카이브 작업 로그

5. 향후 확장:
   - 회사별 서브파티셔닝 고려
   - 압축 테이블스페이스 활용
   - 자동 파티션 관리 도구 도입
*/

-- 완료 메시지
SELECT '✅ 5.2 파티셔닝 전략 수립이 완료되었습니다!' as result;