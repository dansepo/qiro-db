-- =====================================================
-- 성능 최적화 및 캐싱 시스템 스키마
-- =====================================================

-- 성능 메트릭 테이블
CREATE TABLE IF NOT EXISTS bms.performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_type VARCHAR(30) NOT NULL CHECK (metric_type IN ('RESPONSE_TIME', 'THROUGHPUT', 'ERROR_RATE', 'CPU_USAGE', 'MEMORY_USAGE', 'DATABASE_QUERY', 'CACHE_HIT_RATE', 'FILE_UPLOAD_TIME', 'CONCURRENT_USERS', 'CUSTOM')),
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(20) NOT NULL,
    threshold DOUBLE PRECISION,
    status VARCHAR(20) NOT NULL CHECK (status IN ('NORMAL', 'WARNING', 'CRITICAL', 'UNKNOWN')),
    tags JSONB DEFAULT '{}',
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE
);

-- 성능 메트릭 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_metric_name ON bms.performance_metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_metric_type ON bms.performance_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_performance_metric_timestamp ON bms.performance_metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_performance_metric_company ON bms.performance_metrics(company_id);
CREATE INDEX IF NOT EXISTS idx_performance_metric_status ON bms.performance_metrics(status);
CREATE INDEX IF NOT EXISTS idx_performance_metric_composite ON bms.performance_metrics(company_id, metric_name, timestamp);

-- 성능 알림 테이블
CREATE TABLE IF NOT EXISTS bms.performance_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_name VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    condition VARCHAR(50) NOT NULL,
    threshold DOUBLE PRECISION NOT NULL,
    current_value DOUBLE PRECISION NOT NULL,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'RESOLVED', 'SUPPRESSED')),
    message TEXT NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE NOT NULL,
    resolved_at TIMESTAMP WITH TIME ZONE,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE
);

-- 성능 알림 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_alert_metric ON bms.performance_alerts(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_alert_status ON bms.performance_alerts(status);
CREATE INDEX IF NOT EXISTS idx_performance_alert_severity ON bms.performance_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_performance_alert_triggered ON bms.performance_alerts(triggered_at);
CREATE INDEX IF NOT EXISTS idx_performance_alert_company ON bms.performance_alerts(company_id);

-- 성능 임계값 테이블
CREATE TABLE IF NOT EXISTS bms.performance_thresholds (
    threshold_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    metric_type VARCHAR(30) NOT NULL,
    warning_threshold DOUBLE PRECISION NOT NULL,
    critical_threshold DOUBLE PRECISION NOT NULL,
    unit VARCHAR(20) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    description TEXT,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE
);

-- 성능 임계값 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_threshold_metric ON bms.performance_thresholds(metric_name);
CREATE INDEX IF NOT EXISTS idx_performance_threshold_type ON bms.performance_thresholds(metric_type);
CREATE INDEX IF NOT EXISTS idx_performance_threshold_enabled ON bms.performance_thresholds(is_enabled);
CREATE INDEX IF NOT EXISTS idx_performance_threshold_company ON bms.performance_thresholds(company_id);

-- 캐시 통계 테이블
CREATE TABLE IF NOT EXISTS bms.cache_statistics (
    statistics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cache_name VARCHAR(100) NOT NULL,
    hit_count BIGINT NOT NULL DEFAULT 0,
    miss_count BIGINT NOT NULL DEFAULT 0,
    hit_rate DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    eviction_count BIGINT NOT NULL DEFAULT 0,
    size BIGINT NOT NULL DEFAULT 0,
    max_size BIGINT NOT NULL,
    average_load_time DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 캐시 통계 인덱스
CREATE INDEX IF NOT EXISTS idx_cache_statistics_name ON bms.cache_statistics(cache_name);
CREATE INDEX IF NOT EXISTS idx_cache_statistics_updated ON bms.cache_statistics(last_updated);
CREATE INDEX IF NOT EXISTS idx_cache_statistics_company ON bms.cache_statistics(company_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_cache_statistics_unique ON bms.cache_statistics(company_id, cache_name);

-- 느린 쿼리 테이블
CREATE TABLE IF NOT EXISTS bms.slow_queries (
    query_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    query TEXT NOT NULL,
    execution_time DOUBLE PRECISION NOT NULL,
    execution_count BIGINT NOT NULL DEFAULT 1,
    average_time DOUBLE PRECISION NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    last_executed TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 느린 쿼리 인덱스
CREATE INDEX IF NOT EXISTS idx_slow_query_execution_time ON bms.slow_queries(execution_time);
CREATE INDEX IF NOT EXISTS idx_slow_query_count ON bms.slow_queries(execution_count);
CREATE INDEX IF NOT EXISTS idx_slow_query_last_executed ON bms.slow_queries(last_executed);
CREATE INDEX IF NOT EXISTS idx_slow_query_company ON bms.slow_queries(company_id);
CREATE INDEX IF NOT EXISTS idx_slow_query_hash ON bms.slow_queries(company_id, MD5(query));

-- API 성능 테이블
CREATE TABLE IF NOT EXISTS bms.api_performance (
    performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    request_count BIGINT NOT NULL DEFAULT 0,
    average_response_time DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    min_response_time DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    max_response_time DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    error_count BIGINT NOT NULL DEFAULT 0,
    error_rate DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    throughput DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    period VARCHAR(20) NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    last_updated TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- API 성능 인덱스
CREATE INDEX IF NOT EXISTS idx_api_performance_endpoint ON bms.api_performance(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_performance_method ON bms.api_performance(method);
CREATE INDEX IF NOT EXISTS idx_api_performance_response_time ON bms.api_performance(average_response_time);
CREATE INDEX IF NOT EXISTS idx_api_performance_error_rate ON bms.api_performance(error_rate);
CREATE INDEX IF NOT EXISTS idx_api_performance_updated ON bms.api_performance(last_updated);
CREATE INDEX IF NOT EXISTS idx_api_performance_company ON bms.api_performance(company_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_api_performance_unique ON bms.api_performance(company_id, endpoint, method, period);

-- 최적화 제안 테이블
CREATE TABLE IF NOT EXISTS bms.optimization_suggestions (
    suggestion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(30) NOT NULL CHECK (category IN ('DATABASE', 'CACHE', 'API', 'MEMORY', 'CPU', 'NETWORK', 'STORAGE', 'CONFIGURATION')),
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    impact VARCHAR(20) NOT NULL CHECK (impact IN ('LOW', 'MEDIUM', 'HIGH')),
    effort VARCHAR(20) NOT NULL CHECK (effort IN ('LOW', 'MEDIUM', 'HIGH')),
    priority INTEGER NOT NULL,
    metrics JSONB DEFAULT '[]',
    implementation TEXT NOT NULL,
    expected_improvement TEXT NOT NULL,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 최적화 제안 인덱스
CREATE INDEX IF NOT EXISTS idx_optimization_category ON bms.optimization_suggestions(category);
CREATE INDEX IF NOT EXISTS idx_optimization_impact ON bms.optimization_suggestions(impact);
CREATE INDEX IF NOT EXISTS idx_optimization_priority ON bms.optimization_suggestions(priority);
CREATE INDEX IF NOT EXISTS idx_optimization_created ON bms.optimization_suggestions(created_at);
CREATE INDEX IF NOT EXISTS idx_optimization_company ON bms.optimization_suggestions(company_id);

-- =====================================================
-- 성능 관련 함수들
-- =====================================================

-- 성능 메트릭 집계 함수
CREATE OR REPLACE FUNCTION bms.aggregate_performance_metrics(
    p_company_id UUID,
    p_metric_name TEXT,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_interval_minutes INTEGER DEFAULT 60
)
RETURNS TABLE(
    time_bucket TIMESTAMP WITH TIME ZONE,
    avg_value DOUBLE PRECISION,
    min_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    count_values BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        date_trunc('hour', pm.timestamp) + 
        (EXTRACT(MINUTE FROM pm.timestamp)::INTEGER / p_interval_minutes) * 
        (p_interval_minutes || ' minutes')::INTERVAL as time_bucket,
        AVG(pm.value) as avg_value,
        MIN(pm.value) as min_value,
        MAX(pm.value) as max_value,
        COUNT(*)::BIGINT as count_values
    FROM bms.performance_metrics pm
    WHERE pm.company_id = p_company_id
    AND pm.metric_name = p_metric_name
    AND pm.timestamp BETWEEN p_start_time AND p_end_time
    GROUP BY time_bucket
    ORDER BY time_bucket;
END;
$$ LANGUAGE plpgsql;

-- 캐시 히트율 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_cache_hit_rate(
    p_company_id UUID,
    p_cache_name TEXT DEFAULT NULL
)
RETURNS TABLE(
    cache_name TEXT,
    hit_rate DOUBLE PRECISION,
    total_requests BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cs.cache_name::TEXT,
        CASE 
            WHEN (cs.hit_count + cs.miss_count) > 0 
            THEN cs.hit_count::DOUBLE PRECISION / (cs.hit_count + cs.miss_count)
            ELSE 0.0
        END as hit_rate,
        (cs.hit_count + cs.miss_count) as total_requests
    FROM bms.cache_statistics cs
    WHERE cs.company_id = p_company_id
    AND (p_cache_name IS NULL OR cs.cache_name = p_cache_name)
    ORDER BY hit_rate DESC;
END;
$$ LANGUAGE plpgsql;

-- 시스템 성능 요약 함수
CREATE OR REPLACE FUNCTION bms.get_system_performance_summary(
    p_company_id UUID,
    p_hours_back INTEGER DEFAULT 24
)
RETURNS TABLE(
    metric_type TEXT,
    avg_value DOUBLE PRECISION,
    max_value DOUBLE PRECISION,
    critical_count BIGINT,
    warning_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pm.metric_type::TEXT,
        AVG(pm.value) as avg_value,
        MAX(pm.value) as max_value,
        COUNT(*) FILTER (WHERE pm.status = 'CRITICAL')::BIGINT as critical_count,
        COUNT(*) FILTER (WHERE pm.status = 'WARNING')::BIGINT as warning_count
    FROM bms.performance_metrics pm
    WHERE pm.company_id = p_company_id
    AND pm.timestamp >= CURRENT_TIMESTAMP - (p_hours_back || ' hours')::INTERVAL
    GROUP BY pm.metric_type
    ORDER BY critical_count DESC, warning_count DESC;
END;
$$ LANGUAGE plpgsql;

-- 느린 쿼리 분석 함수
CREATE OR REPLACE FUNCTION bms.analyze_slow_queries(
    p_company_id UUID,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
    query_snippet TEXT,
    execution_time DOUBLE PRECISION,
    execution_count BIGINT,
    average_time DOUBLE PRECISION,
    performance_impact DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(sq.query, 100) || CASE WHEN LENGTH(sq.query) > 100 THEN '...' ELSE '' END as query_snippet,
        sq.execution_time,
        sq.execution_count,
        sq.average_time,
        (sq.average_time * sq.execution_count) as performance_impact
    FROM bms.slow_queries sq
    WHERE sq.company_id = p_company_id
    ORDER BY performance_impact DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- API 성능 분석 함수
CREATE OR REPLACE FUNCTION bms.analyze_api_performance(
    p_company_id UUID,
    p_threshold_ms DOUBLE PRECISION DEFAULT 1000.0
)
RETURNS TABLE(
    endpoint TEXT,
    method TEXT,
    average_response_time DOUBLE PRECISION,
    error_rate DOUBLE PRECISION,
    throughput DOUBLE PRECISION,
    performance_score DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ap.endpoint,
        ap.method,
        ap.average_response_time,
        ap.error_rate,
        ap.throughput,
        -- 성능 점수 계산 (응답시간, 오류율, 처리량 고려)
        CASE 
            WHEN ap.average_response_time = 0 THEN 100.0
            ELSE GREATEST(0.0, 100.0 - 
                (ap.average_response_time / p_threshold_ms * 50) - 
                (ap.error_rate * 50))
        END as performance_score
    FROM bms.api_performance ap
    WHERE ap.company_id = p_company_id
    ORDER BY performance_score ASC;
END;
$$ LANGUAGE plpgsql;

-- 성능 알림 생성 함수
CREATE OR REPLACE FUNCTION bms.create_performance_alert(
    p_company_id UUID,
    p_metric_name TEXT,
    p_current_value DOUBLE PRECISION,
    p_threshold DOUBLE PRECISION,
    p_severity TEXT DEFAULT 'MEDIUM'
)
RETURNS UUID AS $$
DECLARE
    v_alert_id UUID;
    v_message TEXT;
BEGIN
    v_alert_id := gen_random_uuid();
    v_message := format('메트릭 %s이(가) 임계값 %s을(를) 초과했습니다. 현재 값: %s', 
                       p_metric_name, p_threshold, p_current_value);
    
    INSERT INTO bms.performance_alerts (
        alert_id,
        alert_name,
        metric_name,
        condition,
        threshold,
        current_value,
        severity,
        status,
        message,
        triggered_at,
        company_id
    ) VALUES (
        v_alert_id,
        '임계값 초과: ' || p_metric_name,
        p_metric_name,
        'GREATER_THAN',
        p_threshold,
        p_current_value,
        p_severity,
        'ACTIVE',
        v_message,
        CURRENT_TIMESTAMP,
        p_company_id
    );
    
    RETURN v_alert_id;
END;
$$ LANGUAGE plpgsql;

-- 성능 데이터 정리 함수
CREATE OR REPLACE FUNCTION bms.cleanup_performance_data(
    p_company_id UUID,
    p_days_to_keep INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
    v_cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    v_cutoff_date := CURRENT_TIMESTAMP - (p_days_to_keep || ' days')::INTERVAL;
    
    -- 오래된 성능 메트릭 삭제
    DELETE FROM bms.performance_metrics 
    WHERE company_id = p_company_id 
    AND timestamp < v_cutoff_date;
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    
    -- 해결된 알림 중 오래된 것들 삭제
    DELETE FROM bms.performance_alerts 
    WHERE company_id = p_company_id 
    AND status = 'RESOLVED'
    AND resolved_at < v_cutoff_date;
    
    -- 오래된 느린 쿼리 기록 삭제 (실행 횟수가 적은 것들)
    DELETE FROM bms.slow_queries 
    WHERE company_id = p_company_id 
    AND last_executed < v_cutoff_date
    AND execution_count < 10;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 성능 최적화를 위한 파티셔닝 설정
-- =====================================================

-- 성능 메트릭 테이블 파티셔닝 (월별)
-- CREATE TABLE bms.performance_metrics_y2024m01 PARTITION OF bms.performance_metrics
-- FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

-- =====================================================
-- 기본 성능 임계값 설정
-- =====================================================

-- 기본 성능 임계값 데이터 삽입
INSERT INTO bms.performance_thresholds (
    metric_name, metric_type, warning_threshold, critical_threshold, unit, description, company_id
)
SELECT 
    'response_time', 'RESPONSE_TIME', 1000.0, 2000.0, 'ms', 'API 응답 시간 임계값', c.company_id
FROM bms.companies c
ON CONFLICT DO NOTHING;

INSERT INTO bms.performance_thresholds (
    metric_name, metric_type, warning_threshold, critical_threshold, unit, description, company_id
)
SELECT 
    'cpu_usage', 'CPU_USAGE', 70.0, 90.0, '%', 'CPU 사용률 임계값', c.company_id
FROM bms.companies c
ON CONFLICT DO NOTHING;

INSERT INTO bms.performance_thresholds (
    metric_name, metric_type, warning_threshold, critical_threshold, unit, description, company_id
)
SELECT 
    'memory_usage', 'MEMORY_USAGE', 80.0, 95.0, '%', '메모리 사용률 임계값', c.company_id
FROM bms.companies c
ON CONFLICT DO NOTHING;

INSERT INTO bms.performance_thresholds (
    metric_name, metric_type, warning_threshold, critical_threshold, unit, description, company_id
)
SELECT 
    'error_rate', 'ERROR_RATE', 5.0, 10.0, '%', '오류율 임계값', c.company_id
FROM bms.companies c
ON CONFLICT DO NOTHING;

INSERT INTO bms.performance_thresholds (
    metric_name, metric_type, warning_threshold, critical_threshold, unit, description, company_id
)
SELECT 
    'cache_hit_rate', 'CACHE_HIT_RATE', 70.0, 50.0, '%', '캐시 히트율 임계값 (낮을수록 경고)', c.company_id
FROM bms.companies c
ON CONFLICT DO NOTHING;

-- =====================================================
-- 성능 모니터링을 위한 뷰 생성
-- =====================================================

-- 실시간 시스템 상태 뷰
CREATE OR REPLACE VIEW bms.system_health_status AS
SELECT 
    pm.company_id,
    pm.metric_type,
    AVG(pm.value) as avg_value,
    MAX(pm.value) as max_value,
    COUNT(*) FILTER (WHERE pm.status = 'CRITICAL') as critical_count,
    COUNT(*) FILTER (WHERE pm.status = 'WARNING') as warning_count,
    COUNT(*) FILTER (WHERE pm.status = 'NORMAL') as normal_count
FROM bms.performance_metrics pm
WHERE pm.timestamp >= CURRENT_TIMESTAMP - INTERVAL '5 minutes'
GROUP BY pm.company_id, pm.metric_type;

-- 캐시 성능 요약 뷰
CREATE OR REPLACE VIEW bms.cache_performance_summary AS
SELECT 
    cs.company_id,
    cs.cache_name,
    cs.hit_rate,
    cs.size,
    cs.max_size,
    ROUND((cs.size::DOUBLE PRECISION / cs.max_size * 100), 2) as usage_percentage,
    cs.eviction_count,
    cs.average_load_time,
    cs.last_updated
FROM bms.cache_statistics cs
ORDER BY cs.hit_rate ASC;

-- API 성능 요약 뷰
CREATE OR REPLACE VIEW bms.api_performance_summary AS
SELECT 
    ap.company_id,
    ap.endpoint,
    ap.method,
    ap.average_response_time,
    ap.error_rate,
    ap.throughput,
    ap.request_count,
    CASE 
        WHEN ap.average_response_time > 2000 THEN 'SLOW'
        WHEN ap.average_response_time > 1000 THEN 'MODERATE'
        ELSE 'FAST'
    END as performance_category,
    ap.last_updated
FROM bms.api_performance ap
ORDER BY ap.average_response_time DESC;

-- =====================================================
-- 테이블 코멘트
-- =====================================================

COMMENT ON TABLE bms.performance_metrics IS '시스템 성능 메트릭을 저장하는 테이블';
COMMENT ON COLUMN bms.performance_metrics.metric_id IS '메트릭 고유 식별자';
COMMENT ON COLUMN bms.performance_metrics.metric_name IS '메트릭 이름';
COMMENT ON COLUMN bms.performance_metrics.metric_type IS '메트릭 타입';
COMMENT ON COLUMN bms.performance_metrics.value IS '메트릭 값';
COMMENT ON COLUMN bms.performance_metrics.unit IS '측정 단위';
COMMENT ON COLUMN bms.performance_metrics.threshold IS '임계값';
COMMENT ON COLUMN bms.performance_metrics.status IS '메트릭 상태';
COMMENT ON COLUMN bms.performance_metrics.tags IS '추가 태그 정보 (JSON)';
COMMENT ON COLUMN bms.performance_metrics.timestamp IS '측정 시간';

COMMENT ON TABLE bms.performance_alerts IS '성능 알림 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.performance_alerts.alert_id IS '알림 고유 식별자';
COMMENT ON COLUMN bms.performance_alerts.alert_name IS '알림 이름';
COMMENT ON COLUMN bms.performance_alerts.metric_name IS '관련 메트릭 이름';
COMMENT ON COLUMN bms.performance_alerts.condition IS '알림 조건';
COMMENT ON COLUMN bms.performance_alerts.threshold IS '임계값';
COMMENT ON COLUMN bms.performance_alerts.current_value IS '현재 값';
COMMENT ON COLUMN bms.performance_alerts.severity IS '심각도';
COMMENT ON COLUMN bms.performance_alerts.status IS '알림 상태';
COMMENT ON COLUMN bms.performance_alerts.message IS '알림 메시지';
COMMENT ON COLUMN bms.performance_alerts.triggered_at IS '알림 발생 시간';
COMMENT ON COLUMN bms.performance_alerts.resolved_at IS '알림 해결 시간';

COMMENT ON TABLE bms.performance_thresholds IS '성능 메트릭 임계값 설정 테이블';
COMMENT ON COLUMN bms.performance_thresholds.threshold_id IS '임계값 설정 고유 식별자';
COMMENT ON COLUMN bms.performance_thresholds.metric_name IS '메트릭 이름';
COMMENT ON COLUMN bms.performance_thresholds.metric_type IS '메트릭 타입';
COMMENT ON COLUMN bms.performance_thresholds.warning_threshold IS '경고 임계값';
COMMENT ON COLUMN bms.performance_thresholds.critical_threshold IS '위험 임계값';
COMMENT ON COLUMN bms.performance_thresholds.unit IS '측정 단위';
COMMENT ON COLUMN bms.performance_thresholds.is_enabled IS '활성화 여부';
COMMENT ON COLUMN bms.performance_thresholds.description IS '설명';

COMMENT ON TABLE bms.cache_statistics IS '캐시 통계 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.cache_statistics.statistics_id IS '통계 고유 식별자';
COMMENT ON COLUMN bms.cache_statistics.cache_name IS '캐시 이름';
COMMENT ON COLUMN bms.cache_statistics.hit_count IS '캐시 히트 수';
COMMENT ON COLUMN bms.cache_statistics.miss_count IS '캐시 미스 수';
COMMENT ON COLUMN bms.cache_statistics.hit_rate IS '캐시 히트율';
COMMENT ON COLUMN bms.cache_statistics.eviction_count IS '캐시 제거 수';
COMMENT ON COLUMN bms.cache_statistics.size IS '현재 캐시 크기';
COMMENT ON COLUMN bms.cache_statistics.max_size IS '최대 캐시 크기';
COMMENT ON COLUMN bms.cache_statistics.average_load_time IS '평균 로드 시간';

COMMENT ON TABLE bms.slow_queries IS '느린 쿼리 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.slow_queries.query_id IS '쿼리 고유 식별자';
COMMENT ON COLUMN bms.slow_queries.query IS '쿼리 문';
COMMENT ON COLUMN bms.slow_queries.execution_time IS '실행 시간 (밀리초)';
COMMENT ON COLUMN bms.slow_queries.execution_count IS '실행 횟수';
COMMENT ON COLUMN bms.slow_queries.average_time IS '평균 실행 시간';
COMMENT ON COLUMN bms.slow_queries.last_executed IS '마지막 실행 시간';

COMMENT ON TABLE bms.api_performance IS 'API 성능 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.api_performance.performance_id IS '성능 정보 고유 식별자';
COMMENT ON COLUMN bms.api_performance.endpoint IS 'API 엔드포인트';
COMMENT ON COLUMN bms.api_performance.method IS 'HTTP 메서드';
COMMENT ON COLUMN bms.api_performance.request_count IS '요청 수';
COMMENT ON COLUMN bms.api_performance.average_response_time IS '평균 응답 시간';
COMMENT ON COLUMN bms.api_performance.min_response_time IS '최소 응답 시간';
COMMENT ON COLUMN bms.api_performance.max_response_time IS '최대 응답 시간';
COMMENT ON COLUMN bms.api_performance.error_count IS '오류 수';
COMMENT ON COLUMN bms.api_performance.error_rate IS '오류율';
COMMENT ON COLUMN bms.api_performance.throughput IS '처리량 (초당 요청 수)';
COMMENT ON COLUMN bms.api_performance.period IS '측정 기간';

COMMENT ON TABLE bms.optimization_suggestions IS '성능 최적화 제안을 저장하는 테이블';
COMMENT ON COLUMN bms.optimization_suggestions.suggestion_id IS '제안 고유 식별자';
COMMENT ON COLUMN bms.optimization_suggestions.category IS '최적화 카테고리';
COMMENT ON COLUMN bms.optimization_suggestions.title IS '제안 제목';
COMMENT ON COLUMN bms.optimization_suggestions.description IS '제안 설명';
COMMENT ON COLUMN bms.optimization_suggestions.impact IS '영향도';
COMMENT ON COLUMN bms.optimization_suggestions.effort IS '노력 수준';
COMMENT ON COLUMN bms.optimization_suggestions.priority IS '우선순위';
COMMENT ON COLUMN bms.optimization_suggestions.metrics IS '관련 메트릭 (JSON)';
COMMENT ON COLUMN bms.optimization_suggestions.implementation IS '구현 방법';
COMMENT ON COLUMN bms.optimization_suggestions.expected_improvement IS '예상 개선 효과';