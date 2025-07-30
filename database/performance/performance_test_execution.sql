-- =====================================================
-- 성능 테스트 실행 및 결과 분석 스크립트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 성능 테스트 자동 실행 및 결과 분석
-- =====================================================

\set ECHO all
\timing on

-- 성능 테스트 결과 저장 테이블 생성
CREATE TABLE IF NOT EXISTS performance_test_results (
    id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_category VARCHAR(100) NOT NULL,
    execution_time_ms DECIMAL(10,2) NOT NULL,
    rows_processed BIGINT,
    buffer_hits BIGINT,
    buffer_reads BIGINT,
    hit_ratio DECIMAL(5,2),
    test_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    test_description TEXT,
    query_plan TEXT,
    performance_grade CHAR(1) CHECK (performance_grade IN ('A', 'B', 'C', 'D', 'F')),
    recommendations TEXT
);

-- 성능 테스트 실행 함수
CREATE OR REPLACE FUNCTION execute_performance_test(
    test_name TEXT,
    test_category TEXT,
    test_query TEXT,
    expected_max_time_ms DECIMAL DEFAULT 2000,
    test_description TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    execution_time_ms DECIMAL;
    explain_result TEXT;
    rows_processed BIGINT;
    buffer_hits BIGINT;
    buffer_reads BIGINT;
    hit_ratio DECIMAL;
    performance_grade CHAR(1);
    recommendations TEXT;
BEGIN
    -- 통계 초기화
    PERFORM pg_stat_reset();
    
    -- 실행 시간 측정 시작
    start_time := clock_timestamp();
    
    -- 쿼리 실행
    EXECUTE test_query;
    
    -- 실행 시간 측정 종료
    end_time := clock_timestamp();
    execution_time_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
    
    -- EXPLAIN ANALYZE 결과 수집
    EXECUTE 'EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) ' || test_query INTO explain_result;
    
    -- 버퍼 통계 수집
    SELECT 
        COALESCE(SUM(heap_blks_hit), 0),
        COALESCE(SUM(heap_blks_read), 0),
        CASE 
            WHEN SUM(heap_blks_hit + heap_blks_read) = 0 THEN 0
            ELSE ROUND(SUM(heap_blks_hit) * 100.0 / SUM(heap_blks_hit + heap_blks_read), 2)
        END
    INTO buffer_hits, buffer_reads, hit_ratio
    FROM pg_statio_user_tables;
    
    -- 처리된 행 수 추출 (EXPLAIN 결과에서)
    rows_processed := COALESCE(
        (regexp_match(explain_result, 'rows=(\d+)'))[1]::BIGINT, 
        0
    );
    
    -- 성능 등급 결정
    performance_grade := CASE 
        WHEN execution_time_ms <= expected_max_time_ms * 0.5 THEN 'A'
        WHEN execution_time_ms <= expected_max_time_ms * 0.8 THEN 'B'
        WHEN execution_time_ms <= expected_max_time_ms THEN 'C'
        WHEN execution_time_ms <= expected_max_time_ms * 1.5 THEN 'D'
        ELSE 'F'
    END;
    
    -- 권장사항 생성
    recommendations := CASE 
        WHEN performance_grade = 'F' THEN '심각한 성능 문제 - 즉시 최적화 필요'
        WHEN performance_grade = 'D' THEN '성능 개선 필요 - 인덱스 검토 권장'
        WHEN performance_grade = 'C' THEN '성능 모니터링 필요'
        WHEN performance_grade = 'B' THEN '양호한 성능'
        ELSE '우수한 성능'
    END;
    
    IF hit_ratio < 90 THEN
        recommendations := recommendations || ' | 캐시 히트율 낮음 - 메모리 설정 검토';
    END IF;
    
    -- 결과 저장
    INSERT INTO performance_test_results (
        test_name, test_category, execution_time_ms, rows_processed,
        buffer_hits, buffer_reads, hit_ratio, test_description,
        query_plan, performance_grade, recommendations
    ) VALUES (
        test_name, test_category, execution_time_ms, rows_processed,
        buffer_hits, buffer_reads, hit_ratio, test_description,
        explain_result, performance_grade, recommendations
    );
    
    RAISE NOTICE '테스트 완료: % | 실행시간: %ms | 등급: % | %', 
        test_name, execution_time_ms, performance_grade, recommendations;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 성능 테스트 실행
-- =====================================================

-- 1. 기본 조회 성능 테스트
SELECT execute_performance_test(
    '건물별_호실_현황_조회',
    'BASIC_QUERY',
    'SELECT b.name, COUNT(*) as total_units, 
     COUNT(CASE WHEN u.status = ''OCCUPIED'' THEN 1 END) as occupied_units
     FROM buildings b JOIN units u ON b.id = u.building_id 
     WHERE b.name LIKE ''성능테스트빌딩%'' 
     GROUP BY b.id, b.name ORDER BY b.name',
    2000,
    'NFR-PF-002: 데이터 조회 결과 2초 이내 표시'
);

-- 2. 복잡한 집계 쿼리 테스트
SELECT execute_performance_test(
    '월별_관리비_수익_분석',
    'COMPLEX_AGGREGATION',
    'SELECT b.name, bm.billing_year, bm.billing_month, fi.name, 
     COUNT(mf.id) as calculation_count, SUM(mf.calculated_amount) as total_calculated
     FROM buildings b 
     JOIN billing_months bm ON b.id = bm.building_id
     JOIN monthly_fees mf ON bm.id = mf.billing_month_id
     JOIN fee_items fi ON mf.fee_item_id = fi.id
     WHERE b.name LIKE ''성능테스트빌딩%''
     GROUP BY b.id, b.name, bm.billing_year, bm.billing_month, fi.id, fi.name
     ORDER BY b.name, bm.billing_year DESC, bm.billing_month DESC',
    10000,
    'NFR-PF-003: 관리비 자동 계산 500세대 기준 10초 이내'
);

-- 3. 대용량 검침 데이터 조회 테스트
SELECT execute_performance_test(
    '대용량_검침_데이터_집계',
    'LARGE_DATA_QUERY',
    'SELECT b.name, umr.meter_type, COUNT(*) as reading_count,
     SUM(umr.usage_amount) as total_usage, AVG(umr.usage_amount) as avg_usage
     FROM buildings b
     JOIN billing_months bm ON b.id = bm.building_id
     JOIN unit_meter_readings umr ON bm.id = umr.billing_month_id
     WHERE b.name LIKE ''성능테스트빌딩%''
     GROUP BY b.id, b.name, umr.meter_type
     ORDER BY b.name, umr.meter_type',
    5000,
    '대용량 검침 데이터 조회 및 집계 성능'
);

-- 4. 미납 현황 분석 테스트
SELECT execute_performance_test(
    '미납_현황_분석',
    'BUSINESS_LOGIC',
    'SELECT b.name, u.unit_number, i.total_amount,
     COALESCE(SUM(p.amount), 0) as paid_amount,
     i.total_amount - COALESCE(SUM(p.amount), 0) as outstanding_amount,
     CURRENT_DATE - i.due_date as overdue_days
     FROM buildings b
     JOIN units u ON b.id = u.building_id
     JOIN billing_months bm ON b.id = bm.building_id
     JOIN invoices i ON bm.id = i.billing_month_id AND u.id = i.unit_id
     LEFT JOIN payments p ON i.id = p.invoice_id
     WHERE b.name LIKE ''성능테스트빌딩%''
     AND i.status IN (''ISSUED'', ''SENT'', ''VIEWED'', ''OVERDUE'')
     GROUP BY b.id, b.name, u.id, u.unit_number, i.id, i.total_amount, i.due_date
     HAVING i.total_amount - COALESCE(SUM(p.amount), 0) > 0
     ORDER BY overdue_days DESC',
    30000,
    'NFR-PF-004: 고지서 일괄 생성 1000건 기준 30초 이내'
);

-- 5. 텍스트 검색 성능 테스트
SELECT execute_performance_test(
    '임차인_텍스트_검색',
    'TEXT_SEARCH',
    'SELECT * FROM tenants 
     WHERE name ILIKE ''%테스트%'' OR email ILIKE ''%test%'' 
     ORDER BY name LIMIT 100',
    1000,
    '텍스트 검색 성능 (ILIKE 패턴 매칭)'
);

-- 6. 조인 성능 테스트
SELECT execute_performance_test(
    '대용량_조인_쿼리',
    'JOIN_PERFORMANCE',
    'SELECT b.name, u.unit_number, bm.billing_year, bm.billing_month,
     i.total_amount, p.payment_date, p.amount
     FROM buildings b
     JOIN units u ON b.id = u.building_id
     JOIN billing_months bm ON b.id = bm.building_id
     JOIN invoices i ON bm.id = i.billing_month_id AND u.id = i.unit_id
     LEFT JOIN payments p ON i.id = p.invoice_id
     WHERE b.name LIKE ''성능테스트빌딩%''
     ORDER BY b.name, u.unit_number, bm.billing_year DESC, bm.billing_month DESC
     LIMIT 10000',
    8000,
    '대용량 다중 테이블 조인 성능'
);--
 =====================================================
-- 성능 테스트 결과 분석 및 리포트
-- =====================================================

-- 성능 테스트 결과 요약 뷰
CREATE OR REPLACE VIEW v_performance_test_summary AS
SELECT 
    test_category,
    COUNT(*) as total_tests,
    COUNT(CASE WHEN performance_grade IN ('A', 'B') THEN 1 END) as passed_tests,
    COUNT(CASE WHEN performance_grade IN ('D', 'F') THEN 1 END) as failed_tests,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time_ms,
    ROUND(AVG(hit_ratio), 2) as avg_hit_ratio,
    MAX(test_timestamp) as last_test_time
FROM performance_test_results
GROUP BY test_category
ORDER BY test_category;

-- 성능 등급별 분포 뷰
CREATE OR REPLACE VIEW v_performance_grade_distribution AS
SELECT 
    performance_grade,
    COUNT(*) as test_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    ROUND(AVG(execution_time_ms), 2) as avg_execution_time,
    STRING_AGG(DISTINCT test_category, ', ') as categories
FROM performance_test_results
GROUP BY performance_grade
ORDER BY performance_grade;

-- 성능 문제 테스트 식별 뷰
CREATE OR REPLACE VIEW v_performance_issues AS
SELECT 
    test_name,
    test_category,
    execution_time_ms,
    performance_grade,
    hit_ratio,
    recommendations,
    test_timestamp
FROM performance_test_results
WHERE performance_grade IN ('D', 'F')
ORDER BY execution_time_ms DESC;

-- 성능 개선 추이 분석 함수
CREATE OR REPLACE FUNCTION analyze_performance_trends(days_back INTEGER DEFAULT 30)
RETURNS TABLE (
    test_name TEXT,
    test_category TEXT,
    current_avg_time DECIMAL,
    previous_avg_time DECIMAL,
    improvement_pct DECIMAL,
    trend_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH current_period AS (
        SELECT 
            ptr.test_name,
            ptr.test_category,
            AVG(ptr.execution_time_ms) as avg_time
        FROM performance_test_results ptr
        WHERE ptr.test_timestamp >= CURRENT_DATE - (days_back/2 || ' days')::INTERVAL
        GROUP BY ptr.test_name, ptr.test_category
    ),
    previous_period AS (
        SELECT 
            ptr.test_name,
            ptr.test_category,
            AVG(ptr.execution_time_ms) as avg_time
        FROM performance_test_results ptr
        WHERE ptr.test_timestamp >= CURRENT_DATE - (days_back || ' days')::INTERVAL
        AND ptr.test_timestamp < CURRENT_DATE - (days_back/2 || ' days')::INTERVAL
        GROUP BY ptr.test_name, ptr.test_category
    )
    SELECT 
        c.test_name,
        c.test_category,
        ROUND(c.avg_time, 2) as current_avg_time,
        ROUND(COALESCE(p.avg_time, c.avg_time), 2) as previous_avg_time,
        ROUND(
            CASE 
                WHEN p.avg_time IS NULL OR p.avg_time = 0 THEN 0
                ELSE ((p.avg_time - c.avg_time) / p.avg_time * 100)
            END, 2
        ) as improvement_pct,
        CASE 
            WHEN p.avg_time IS NULL THEN 'NEW_TEST'
            WHEN c.avg_time < p.avg_time * 0.9 THEN 'IMPROVED'
            WHEN c.avg_time > p.avg_time * 1.1 THEN 'DEGRADED'
            ELSE 'STABLE'
        END as trend_status
    FROM current_period c
    LEFT JOIN previous_period p ON c.test_name = p.test_name AND c.test_category = p.test_category
    ORDER BY improvement_pct DESC;
END;
$$ LANGUAGE plpgsql;

-- 성능 테스트 리포트 생성 함수
CREATE OR REPLACE FUNCTION generate_performance_report()
RETURNS TEXT AS $$
DECLARE
    report_content TEXT;
    test_summary RECORD;
    grade_dist RECORD;
    issue_count INTEGER;
    total_tests INTEGER;
    pass_rate DECIMAL;
BEGIN
    -- 리포트 헤더
    report_content := E'=======================================================\n';
    report_content := report_content || '성능 테스트 결과 리포트\n';
    report_content := report_content || '생성일시: ' || CURRENT_TIMESTAMP || E'\n';
    report_content := report_content || E'=======================================================\n\n';
    
    -- 전체 요약
    SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN performance_grade IN ('A', 'B') THEN 1 END) as passed,
        ROUND(COUNT(CASE WHEN performance_grade IN ('A', 'B') THEN 1 END) * 100.0 / COUNT(*), 2) as pass_rate
    INTO total_tests, issue_count, pass_rate
    FROM performance_test_results;
    
    report_content := report_content || '1. 전체 요약\n';
    report_content := report_content || '   - 총 테스트 수: ' || total_tests || E'\n';
    report_content := report_content || '   - 통과 테스트: ' || issue_count || E'\n';
    report_content := report_content || '   - 통과율: ' || pass_rate || E'%\n\n';
    
    -- 카테고리별 요약
    report_content := report_content || '2. 카테고리별 성능 요약\n';
    FOR test_summary IN 
        SELECT * FROM v_performance_test_summary
    LOOP
        report_content := report_content || '   [' || test_summary.test_category || ']\n';
        report_content := report_content || '     - 테스트 수: ' || test_summary.total_tests || E'\n';
        report_content := report_content || '     - 통과: ' || test_summary.passed_tests || E'\n';
        report_content := report_content || '     - 실패: ' || test_summary.failed_tests || E'\n';
        report_content := report_content || '     - 평균 실행시간: ' || test_summary.avg_execution_time_ms || E'ms\n';
        report_content := report_content || '     - 평균 캐시 히트율: ' || test_summary.avg_hit_ratio || E'%\n\n';
    END LOOP;
    
    -- 성능 등급 분포
    report_content := report_content || '3. 성능 등급 분포\n';
    FOR grade_dist IN 
        SELECT * FROM v_performance_grade_distribution
    LOOP
        report_content := report_content || '   등급 ' || grade_dist.performance_grade || ': ';
        report_content := report_content || grade_dist.test_count || '건 (' || grade_dist.percentage || '%)';
        report_content := report_content || ' - 평균 ' || grade_dist.avg_execution_time || E'ms\n';
    END LOOP;
    
    -- 성능 문제 항목
    SELECT COUNT(*) INTO issue_count FROM v_performance_issues;
    
    report_content := report_content || E'\n4. 성능 문제 항목 (' || issue_count || E'건)\n';
    
    IF issue_count > 0 THEN
        FOR test_summary IN 
            SELECT test_name, execution_time_ms, performance_grade, recommendations
            FROM v_performance_issues
            LIMIT 10
        LOOP
            report_content := report_content || '   - ' || test_summary.test_name;
            report_content := report_content || ' (' || test_summary.execution_time_ms || 'ms, ';
            report_content := report_content || '등급: ' || test_summary.performance_grade || ')\n';
            report_content := report_content || '     권장사항: ' || test_summary.recommendations || E'\n';
        END LOOP;
    ELSE
        report_content := report_content || '   성능 문제 없음\n';
    END IF;
    
    -- 권장사항
    report_content := report_content || E'\n5. 전체 권장사항\n';
    
    IF pass_rate < 80 THEN
        report_content := report_content || '   - 전체 통과율이 낮습니다. 인덱스 최적화를 검토하세요.\n';
    END IF;
    
    -- 캐시 히트율 체크
    SELECT AVG(hit_ratio) INTO pass_rate FROM performance_test_results;
    IF pass_rate < 90 THEN
        report_content := report_content || '   - 캐시 히트율이 낮습니다. shared_buffers 설정을 검토하세요.\n';
    END IF;
    
    report_content := report_content || '   - 정기적인 VACUUM ANALYZE 실행을 권장합니다.\n';
    report_content := report_content || '   - 슬로우 쿼리 로그를 활성화하여 지속적인 모니터링을 하세요.\n';
    
    report_content := report_content || E'\n=======================================================\n';
    
    RETURN report_content;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 성능 최적화 권장사항 생성
-- =====================================================

-- 최적화 권장사항 생성 함수
CREATE OR REPLACE FUNCTION generate_optimization_recommendations()
RETURNS TABLE (
    priority INTEGER,
    category TEXT,
    issue TEXT,
    recommendation TEXT,
    estimated_impact TEXT
) AS $$
BEGIN
    -- 1. 심각한 성능 문제 (F등급)
    RETURN QUERY
    SELECT 
        1 as priority,
        'CRITICAL' as category,
        'F등급 성능 테스트: ' || test_name as issue,
        '즉시 쿼리 최적화 및 인덱스 검토 필요' as recommendation,
        'HIGH' as estimated_impact
    FROM performance_test_results
    WHERE performance_grade = 'F'
    ORDER BY execution_time_ms DESC;
    
    -- 2. 캐시 히트율 문제
    RETURN QUERY
    SELECT 
        2 as priority,
        'MEMORY' as category,
        '낮은 캐시 히트율: ' || test_name || ' (' || hit_ratio || '%)' as issue,
        'shared_buffers 증가 또는 쿼리 최적화 검토' as recommendation,
        'MEDIUM' as estimated_impact
    FROM performance_test_results
    WHERE hit_ratio < 80
    ORDER BY hit_ratio ASC;
    
    -- 3. 인덱스 사용률 문제
    RETURN QUERY
    SELECT 
        3 as priority,
        'INDEX' as category,
        '미사용 인덱스: ' || indexname as issue,
        '인덱스 삭제 검토 (저장공간 절약)' as recommendation,
        'LOW' as estimated_impact
    FROM pg_stat_user_indexes
    WHERE schemaname = 'public' AND idx_scan = 0
    ORDER BY pg_relation_size(indexrelid) DESC;
    
    -- 4. 테이블 크기 문제
    RETURN QUERY
    SELECT 
        4 as priority,
        'STORAGE' as category,
        '대용량 테이블: ' || tablename || ' (' || pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) || ')' as issue,
        '파티셔닝 또는 아카이빙 검토' as recommendation,
        'MEDIUM' as estimated_impact
    FROM pg_stat_user_tables
    WHERE schemaname = 'public' 
    AND pg_total_relation_size(schemaname||'.'||tablename) > 1073741824  -- 1GB
    ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 성능 테스트 결과 출력
-- =====================================================

-- 성능 테스트 요약 출력
\echo '====================================================='
\echo '성능 테스트 결과 요약'
\echo '====================================================='

SELECT * FROM v_performance_test_summary;

\echo ''
\echo '성능 등급 분포:'
SELECT * FROM v_performance_grade_distribution;

\echo ''
\echo '성능 문제 항목:'
SELECT test_name, execution_time_ms, performance_grade, recommendations 
FROM v_performance_issues;

\echo ''
\echo '최적화 권장사항:'
SELECT priority, category, issue, recommendation, estimated_impact 
FROM generate_optimization_recommendations() 
ORDER BY priority, estimated_impact DESC;

-- 전체 성능 리포트 생성
\echo ''
\echo '====================================================='
\echo '전체 성능 리포트'
\echo '====================================================='
SELECT generate_performance_report();

\echo ''
\echo '====================================================='
\echo '성능 테스트 및 최적화 완료'
\echo '====================================================='
\echo '다음 명령어로 추가 분석 가능:'
\echo '- SELECT * FROM analyze_performance_trends(30);'
\echo '- SELECT generate_performance_report();'
\echo '- SELECT * FROM generate_optimization_recommendations();'
\echo '====================================================='