package com.qiro.domain.performance.dto

import java.time.LocalDateTime
import java.util.*

/**
 * 성능 메트릭 DTO
 */
data class PerformanceMetricDto(
    val metricId: UUID,
    val metricName: String,
    val metricType: PerformanceMetricType,
    val value: Double,
    val unit: String,
    val threshold: Double? = null,
    val status: MetricStatus,
    val tags: Map<String, String> = emptyMap(),
    val timestamp: LocalDateTime,
    val companyId: UUID
)

/**
 * 성능 메트릭 생성 요청 DTO
 */
data class CreatePerformanceMetricRequest(
    val metricName: String,
    val metricType: PerformanceMetricType,
    val value: Double,
    val unit: String,
    val threshold: Double? = null,
    val tags: Map<String, String> = emptyMap()
)

/**
 * 성능 메트릭 타입 열거형
 */
enum class PerformanceMetricType {
    RESPONSE_TIME,      // 응답 시간
    THROUGHPUT,         // 처리량
    ERROR_RATE,         // 오류율
    CPU_USAGE,          // CPU 사용률
    MEMORY_USAGE,       // 메모리 사용률
    DATABASE_QUERY,     // 데이터베이스 쿼리 시간
    CACHE_HIT_RATE,     // 캐시 히트율
    FILE_UPLOAD_TIME,   // 파일 업로드 시간
    CONCURRENT_USERS,   // 동시 사용자 수
    CUSTOM              // 커스텀 메트릭
}

/**
 * 메트릭 상태 열거형
 */
enum class MetricStatus {
    NORMAL,     // 정상
    WARNING,    // 경고
    CRITICAL,   // 위험
    UNKNOWN     // 알 수 없음
}

/**
 * 성능 통계 DTO
 */
data class PerformanceStatisticsDto(
    val metricName: String,
    val metricType: PerformanceMetricType,
    val period: String,
    val count: Long,
    val average: Double,
    val minimum: Double,
    val maximum: Double,
    val percentile50: Double,
    val percentile95: Double,
    val percentile99: Double,
    val unit: String,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime
)

/**
 * 성능 알림 DTO
 */
data class PerformanceAlertDto(
    val alertId: UUID,
    val alertName: String,
    val metricName: String,
    val condition: String,
    val threshold: Double,
    val currentValue: Double,
    val severity: AlertSeverity,
    val status: AlertStatus,
    val message: String,
    val triggeredAt: LocalDateTime,
    val resolvedAt: LocalDateTime? = null,
    val companyId: UUID
)

/**
 * 성능 알림 생성 요청 DTO
 */
data class CreatePerformanceAlertRequest(
    val alertName: String,
    val metricName: String,
    val condition: String, // GREATER_THAN, LESS_THAN, EQUALS
    val threshold: Double,
    val severity: AlertSeverity,
    val message: String? = null
)

/**
 * 알림 심각도 열거형
 */
enum class AlertSeverity {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH,       // 높음
    CRITICAL    // 위험
}

/**
 * 알림 상태 열거형
 */
enum class AlertStatus {
    ACTIVE,     // 활성
    RESOLVED,   // 해결됨
    SUPPRESSED  // 억제됨
}

/**
 * 시스템 상태 DTO
 */
data class SystemHealthDto(
    val status: SystemStatus,
    val uptime: Long, // 초 단위
    val version: String,
    val environment: String,
    val metrics: List<HealthMetricDto>,
    val checkedAt: LocalDateTime
)

/**
 * 시스템 상태 열거형
 */
enum class SystemStatus {
    HEALTHY,    // 정상
    DEGRADED,   // 성능 저하
    UNHEALTHY,  // 비정상
    UNKNOWN     // 알 수 없음
}

/**
 * 헬스 메트릭 DTO
 */
data class HealthMetricDto(
    val name: String,
    val status: MetricStatus,
    val value: Double,
    val unit: String,
    val message: String? = null
)

/**
 * 캐시 통계 DTO
 */
data class CacheStatisticsDto(
    val cacheName: String,
    val hitCount: Long,
    val missCount: Long,
    val hitRate: Double,
    val evictionCount: Long,
    val size: Long,
    val maxSize: Long,
    val averageLoadTime: Double,
    val lastUpdated: LocalDateTime
)

/**
 * 데이터베이스 성능 DTO
 */
data class DatabasePerformanceDto(
    val connectionPoolSize: Int,
    val activeConnections: Int,
    val idleConnections: Int,
    val averageQueryTime: Double,
    val slowQueries: List<SlowQueryDto>,
    val transactionCount: Long,
    val rollbackCount: Long,
    val checkedAt: LocalDateTime
)

/**
 * 느린 쿼리 DTO
 */
data class SlowQueryDto(
    val queryId: UUID,
    val query: String,
    val executionTime: Double,
    val executionCount: Long,
    val averageTime: Double,
    val lastExecuted: LocalDateTime
)

/**
 * API 성능 DTO
 */
data class ApiPerformanceDto(
    val endpoint: String,
    val method: String,
    val requestCount: Long,
    val averageResponseTime: Double,
    val minResponseTime: Double,
    val maxResponseTime: Double,
    val errorCount: Long,
    val errorRate: Double,
    val throughput: Double, // requests per second
    val period: String,
    val lastUpdated: LocalDateTime
)

/**
 * 성능 보고서 DTO
 */
data class PerformanceReportDto(
    val reportId: UUID,
    val reportName: String,
    val reportType: ReportType,
    val period: String,
    val systemHealth: SystemHealthDto,
    val apiPerformance: List<ApiPerformanceDto>,
    val databasePerformance: DatabasePerformanceDto,
    val cacheStatistics: List<CacheStatisticsDto>,
    val alerts: List<PerformanceAlertDto>,
    val recommendations: List<String>,
    val generatedAt: LocalDateTime,
    val companyId: UUID
)

/**
 * 보고서 타입 열거형
 */
enum class ReportType {
    DAILY,      // 일간
    WEEKLY,     // 주간
    MONTHLY,    // 월간
    CUSTOM      // 커스텀
}

/**
 * 성능 최적화 제안 DTO
 */
data class OptimizationSuggestionDto(
    val suggestionId: UUID,
    val category: OptimizationCategory,
    val title: String,
    val description: String,
    val impact: ImpactLevel,
    val effort: EffortLevel,
    val priority: Int,
    val metrics: List<String>,
    val implementation: String,
    val expectedImprovement: String,
    val createdAt: LocalDateTime
)

/**
 * 최적화 카테고리 열거형
 */
enum class OptimizationCategory {
    DATABASE,       // 데이터베이스
    CACHE,          // 캐시
    API,            // API
    MEMORY,         // 메모리
    CPU,            // CPU
    NETWORK,        // 네트워크
    STORAGE,        // 저장소
    CONFIGURATION   // 설정
}

/**
 * 영향도 레벨 열거형
 */
enum class ImpactLevel {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH        // 높음
}

/**
 * 노력 레벨 열거형
 */
enum class EffortLevel {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH        // 높음
}

/**
 * 성능 임계값 설정 DTO
 */
data class PerformanceThresholdDto(
    val thresholdId: UUID,
    val metricName: String,
    val metricType: PerformanceMetricType,
    val warningThreshold: Double,
    val criticalThreshold: Double,
    val unit: String,
    val isEnabled: Boolean,
    val description: String? = null,
    val companyId: UUID,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime? = null
)

/**
 * 성능 임계값 생성 요청 DTO
 */
data class CreatePerformanceThresholdRequest(
    val metricName: String,
    val metricType: PerformanceMetricType,
    val warningThreshold: Double,
    val criticalThreshold: Double,
    val unit: String,
    val description: String? = null
)

/**
 * 성능 임계값 수정 요청 DTO
 */
data class UpdatePerformanceThresholdRequest(
    val warningThreshold: Double? = null,
    val criticalThreshold: Double? = null,
    val isEnabled: Boolean? = null,
    val description: String? = null
)

/**
 * 성능 대시보드 DTO
 */
data class PerformanceDashboardDto(
    val systemHealth: SystemHealthDto,
    val recentMetrics: List<PerformanceMetricDto>,
    val activeAlerts: List<PerformanceAlertDto>,
    val topSlowQueries: List<SlowQueryDto>,
    val cacheStatistics: List<CacheStatisticsDto>,
    val apiPerformance: List<ApiPerformanceDto>,
    val recommendations: List<OptimizationSuggestionDto>,
    val lastUpdated: LocalDateTime
)

/**
 * 성능 트렌드 DTO
 */
data class PerformanceTrendDto(
    val metricName: String,
    val metricType: PerformanceMetricType,
    val dataPoints: List<TrendDataPointDto>,
    val trend: TrendDirection,
    val changePercentage: Double,
    val period: String,
    val unit: String
)

/**
 * 트렌드 데이터 포인트 DTO
 */
data class TrendDataPointDto(
    val timestamp: LocalDateTime,
    val value: Double
)

/**
 * 트렌드 방향 열거형
 */
enum class TrendDirection {
    INCREASING,     // 증가
    DECREASING,     // 감소
    STABLE,         // 안정
    VOLATILE        // 변동성
}