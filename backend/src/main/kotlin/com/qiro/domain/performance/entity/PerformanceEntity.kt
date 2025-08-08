package com.qiro.domain.performance.entity

import com.qiro.domain.performance.dto.*
import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 성능 메트릭 엔티티
 */
@Entity
@Table(
    name = "performance_metrics",
    schema = "bms",
    indexes = [
        Index(name = "idx_performance_metric_name", columnList = "metric_name"),
        Index(name = "idx_performance_metric_type", columnList = "metric_type"),
        Index(name = "idx_performance_metric_timestamp", columnList = "timestamp"),
        Index(name = "idx_performance_metric_company", columnList = "company_id"),
        Index(name = "idx_performance_metric_status", columnList = "status")
    ]
)
data class PerformanceMetric(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "metric_id")
    val metricId: UUID = UUID.randomUUID(),

    /**
     * 메트릭 이름
     */
    @Column(name = "metric_name", nullable = false, length = 100)
    val metricName: String,

    /**
     * 메트릭 타입
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "metric_type", nullable = false, length = 30)
    val metricType: PerformanceMetricType,

    /**
     * 메트릭 값
     */
    @Column(name = "value", nullable = false)
    val value: Double,

    /**
     * 단위
     */
    @Column(name = "unit", nullable = false, length = 20)
    val unit: String,

    /**
     * 임계값
     */
    @Column(name = "threshold")
    val threshold: Double? = null,

    /**
     * 상태
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    val status: MetricStatus,

    /**
     * 태그 (JSON)
     */
    @Column(name = "tags", columnDefinition = "JSONB")
    val tags: String = "{}",

    /**
     * 타임스탬프
     */
    @Column(name = "timestamp", nullable = false)
    val timestamp: LocalDateTime,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID
)

/**
 * 성능 알림 엔티티
 */
@Entity
@Table(
    name = "performance_alerts",
    schema = "bms",
    indexes = [
        Index(name = "idx_performance_alert_metric", columnList = "metric_name"),
        Index(name = "idx_performance_alert_status", columnList = "status"),
        Index(name = "idx_performance_alert_severity", columnList = "severity"),
        Index(name = "idx_performance_alert_triggered", columnList = "triggered_at"),
        Index(name = "idx_performance_alert_company", columnList = "company_id")
    ]
)
data class PerformanceAlert(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "alert_id")
    val alertId: UUID = UUID.randomUUID(),

    /**
     * 알림 이름
     */
    @Column(name = "alert_name", nullable = false, length = 100)
    val alertName: String,

    /**
     * 메트릭 이름
     */
    @Column(name = "metric_name", nullable = false, length = 100)
    val metricName: String,

    /**
     * 조건
     */
    @Column(name = "condition", nullable = false, length = 50)
    val condition: String,

    /**
     * 임계값
     */
    @Column(name = "threshold", nullable = false)
    val threshold: Double,

    /**
     * 현재 값
     */
    @Column(name = "current_value", nullable = false)
    val currentValue: Double,

    /**
     * 심각도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "severity", nullable = false, length = 20)
    val severity: AlertSeverity,

    /**
     * 상태
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: AlertStatus,

    /**
     * 메시지
     */
    @Column(name = "message", columnDefinition = "TEXT")
    val message: String,

    /**
     * 트리거 시간
     */
    @Column(name = "triggered_at", nullable = false)
    val triggeredAt: LocalDateTime,

    /**
     * 해결 시간
     */
    @Column(name = "resolved_at")
    var resolvedAt: LocalDateTime? = null,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID
) {
    /**
     * 알림 해결
     */
    fun resolve() {
        this.status = AlertStatus.RESOLVED
        this.resolvedAt = LocalDateTime.now()
    }

    /**
     * 알림 억제
     */
    fun suppress() {
        this.status = AlertStatus.SUPPRESSED
    }
}

/**
 * 성능 임계값 엔티티
 */
@Entity
@Table(
    name = "performance_thresholds",
    schema = "bms",
    indexes = [
        Index(name = "idx_performance_threshold_metric", columnList = "metric_name"),
        Index(name = "idx_performance_threshold_type", columnList = "metric_type"),
        Index(name = "idx_performance_threshold_enabled", columnList = "is_enabled"),
        Index(name = "idx_performance_threshold_company", columnList = "company_id")
    ]
)
data class PerformanceThreshold(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "threshold_id")
    val thresholdId: UUID = UUID.randomUUID(),

    /**
     * 메트릭 이름
     */
    @Column(name = "metric_name", nullable = false, length = 100)
    val metricName: String,

    /**
     * 메트릭 타입
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "metric_type", nullable = false, length = 30)
    val metricType: PerformanceMetricType,

    /**
     * 경고 임계값
     */
    @Column(name = "warning_threshold", nullable = false)
    var warningThreshold: Double,

    /**
     * 위험 임계값
     */
    @Column(name = "critical_threshold", nullable = false)
    var criticalThreshold: Double,

    /**
     * 단위
     */
    @Column(name = "unit", nullable = false, length = 20)
    val unit: String,

    /**
     * 활성화 여부
     */
    @Column(name = "is_enabled", nullable = false)
    var isEnabled: Boolean = true,

    /**
     * 설명
     */
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 생성일시
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    /**
     * 수정일시
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    var updatedAt: LocalDateTime? = null
) {
    /**
     * 임계값 업데이트
     */
    fun updateThresholds(
        warningThreshold: Double? = null,
        criticalThreshold: Double? = null,
        isEnabled: Boolean? = null,
        description: String? = null
    ) {
        warningThreshold?.let { this.warningThreshold = it }
        criticalThreshold?.let { this.criticalThreshold = it }
        isEnabled?.let { this.isEnabled = it }
        description?.let { this.description = it }
    }

    /**
     * 메트릭 상태 평가
     */
    fun evaluateStatus(value: Double): MetricStatus {
        return when {
            value >= criticalThreshold -> MetricStatus.CRITICAL
            value >= warningThreshold -> MetricStatus.WARNING
            else -> MetricStatus.NORMAL
        }
    }
}

/**
 * 캐시 통계 엔티티
 */
@Entity
@Table(
    name = "cache_statistics",
    schema = "bms",
    indexes = [
        Index(name = "idx_cache_statistics_name", columnList = "cache_name"),
        Index(name = "idx_cache_statistics_updated", columnList = "last_updated"),
        Index(name = "idx_cache_statistics_company", columnList = "company_id")
    ]
)
data class CacheStatistics(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "statistics_id")
    val statisticsId: UUID = UUID.randomUUID(),

    /**
     * 캐시 이름
     */
    @Column(name = "cache_name", nullable = false, length = 100)
    val cacheName: String,

    /**
     * 히트 수
     */
    @Column(name = "hit_count", nullable = false)
    var hitCount: Long,

    /**
     * 미스 수
     */
    @Column(name = "miss_count", nullable = false)
    var missCount: Long,

    /**
     * 히트율
     */
    @Column(name = "hit_rate", nullable = false)
    var hitRate: Double,

    /**
     * 제거 수
     */
    @Column(name = "eviction_count", nullable = false)
    var evictionCount: Long,

    /**
     * 현재 크기
     */
    @Column(name = "size", nullable = false)
    var size: Long,

    /**
     * 최대 크기
     */
    @Column(name = "max_size", nullable = false)
    val maxSize: Long,

    /**
     * 평균 로드 시간
     */
    @Column(name = "average_load_time", nullable = false)
    var averageLoadTime: Double,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 마지막 업데이트
     */
    @UpdateTimestamp
    @Column(name = "last_updated", nullable = false)
    var lastUpdated: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 통계 업데이트
     */
    fun updateStatistics(
        hitCount: Long,
        missCount: Long,
        evictionCount: Long,
        size: Long,
        averageLoadTime: Double
    ) {
        this.hitCount = hitCount
        this.missCount = missCount
        this.hitRate = if (hitCount + missCount > 0) {
            hitCount.toDouble() / (hitCount + missCount)
        } else 0.0
        this.evictionCount = evictionCount
        this.size = size
        this.averageLoadTime = averageLoadTime
    }
}

/**
 * 느린 쿼리 엔티티
 */
@Entity
@Table(
    name = "slow_queries",
    schema = "bms",
    indexes = [
        Index(name = "idx_slow_query_execution_time", columnList = "execution_time"),
        Index(name = "idx_slow_query_count", columnList = "execution_count"),
        Index(name = "idx_slow_query_last_executed", columnList = "last_executed"),
        Index(name = "idx_slow_query_company", columnList = "company_id")
    ]
)
data class SlowQuery(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "query_id")
    val queryId: UUID = UUID.randomUUID(),

    /**
     * 쿼리 문
     */
    @Column(name = "query", columnDefinition = "TEXT", nullable = false)
    val query: String,

    /**
     * 실행 시간 (밀리초)
     */
    @Column(name = "execution_time", nullable = false)
    var executionTime: Double,

    /**
     * 실행 횟수
     */
    @Column(name = "execution_count", nullable = false)
    var executionCount: Long,

    /**
     * 평균 시간
     */
    @Column(name = "average_time", nullable = false)
    var averageTime: Double,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 마지막 실행 시간
     */
    @Column(name = "last_executed", nullable = false)
    var lastExecuted: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 쿼리 실행 정보 업데이트
     */
    fun updateExecution(executionTime: Double) {
        this.executionCount++
        this.averageTime = ((this.averageTime * (this.executionCount - 1)) + executionTime) / this.executionCount
        if (executionTime > this.executionTime) {
            this.executionTime = executionTime
        }
        this.lastExecuted = LocalDateTime.now()
    }
}

/**
 * API 성능 엔티티
 */
@Entity
@Table(
    name = "api_performance",
    schema = "bms",
    indexes = [
        Index(name = "idx_api_performance_endpoint", columnList = "endpoint"),
        Index(name = "idx_api_performance_method", columnList = "method"),
        Index(name = "idx_api_performance_response_time", columnList = "average_response_time"),
        Index(name = "idx_api_performance_error_rate", columnList = "error_rate"),
        Index(name = "idx_api_performance_updated", columnList = "last_updated"),
        Index(name = "idx_api_performance_company", columnList = "company_id")
    ]
)
data class ApiPerformance(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "performance_id")
    val performanceId: UUID = UUID.randomUUID(),

    /**
     * API 엔드포인트
     */
    @Column(name = "endpoint", nullable = false, length = 200)
    val endpoint: String,

    /**
     * HTTP 메서드
     */
    @Column(name = "method", nullable = false, length = 10)
    val method: String,

    /**
     * 요청 수
     */
    @Column(name = "request_count", nullable = false)
    var requestCount: Long,

    /**
     * 평균 응답 시간
     */
    @Column(name = "average_response_time", nullable = false)
    var averageResponseTime: Double,

    /**
     * 최소 응답 시간
     */
    @Column(name = "min_response_time", nullable = false)
    var minResponseTime: Double,

    /**
     * 최대 응답 시간
     */
    @Column(name = "max_response_time", nullable = false)
    var maxResponseTime: Double,

    /**
     * 오류 수
     */
    @Column(name = "error_count", nullable = false)
    var errorCount: Long,

    /**
     * 오류율
     */
    @Column(name = "error_rate", nullable = false)
    var errorRate: Double,

    /**
     * 처리량 (초당 요청 수)
     */
    @Column(name = "throughput", nullable = false)
    var throughput: Double,

    /**
     * 기간
     */
    @Column(name = "period", nullable = false, length = 20)
    val period: String,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 마지막 업데이트
     */
    @UpdateTimestamp
    @Column(name = "last_updated", nullable = false)
    var lastUpdated: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 성능 정보 업데이트
     */
    fun updatePerformance(
        responseTime: Double,
        isError: Boolean
    ) {
        this.requestCount++
        
        // 평균 응답 시간 업데이트
        this.averageResponseTime = ((this.averageResponseTime * (this.requestCount - 1)) + responseTime) / this.requestCount
        
        // 최소/최대 응답 시간 업데이트
        if (responseTime < this.minResponseTime) {
            this.minResponseTime = responseTime
        }
        if (responseTime > this.maxResponseTime) {
            this.maxResponseTime = responseTime
        }
        
        // 오류 정보 업데이트
        if (isError) {
            this.errorCount++
        }
        this.errorRate = this.errorCount.toDouble() / this.requestCount
        
        // 처리량 계산 (간단한 예시)
        this.throughput = this.requestCount.toDouble() / 3600 // 시간당 요청 수
    }
}

/**
 * 최적화 제안 엔티티
 */
@Entity
@Table(
    name = "optimization_suggestions",
    schema = "bms",
    indexes = [
        Index(name = "idx_optimization_category", columnList = "category"),
        Index(name = "idx_optimization_impact", columnList = "impact"),
        Index(name = "idx_optimization_priority", columnList = "priority"),
        Index(name = "idx_optimization_created", columnList = "created_at"),
        Index(name = "idx_optimization_company", columnList = "company_id")
    ]
)
data class OptimizationSuggestion(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "suggestion_id")
    val suggestionId: UUID = UUID.randomUUID(),

    /**
     * 카테고리
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 30)
    val category: OptimizationCategory,

    /**
     * 제목
     */
    @Column(name = "title", nullable = false, length = 200)
    val title: String,

    /**
     * 설명
     */
    @Column(name = "description", columnDefinition = "TEXT", nullable = false)
    val description: String,

    /**
     * 영향도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "impact", nullable = false, length = 20)
    val impact: ImpactLevel,

    /**
     * 노력 수준
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "effort", nullable = false, length = 20)
    val effort: EffortLevel,

    /**
     * 우선순위
     */
    @Column(name = "priority", nullable = false)
    val priority: Int,

    /**
     * 관련 메트릭들 (JSON)
     */
    @Column(name = "metrics", columnDefinition = "JSONB")
    val metrics: String = "[]",

    /**
     * 구현 방법
     */
    @Column(name = "implementation", columnDefinition = "TEXT")
    val implementation: String,

    /**
     * 예상 개선 효과
     */
    @Column(name = "expected_improvement", columnDefinition = "TEXT")
    val expectedImprovement: String,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 생성일시
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
)