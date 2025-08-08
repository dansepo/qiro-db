package com.qiro.domain.performance.repository

import com.qiro.domain.performance.dto.*
import com.qiro.domain.performance.entity.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 성능 메트릭 리포지토리
 */
@Repository
interface PerformanceMetricRepository : JpaRepository<PerformanceMetric, UUID> {
    
    /**
     * 회사별 메트릭 조회
     */
    fun findByCompanyIdOrderByTimestampDesc(companyId: UUID): List<PerformanceMetric>
    
    /**
     * 메트릭 이름별 조회
     */
    fun findByCompanyIdAndMetricNameOrderByTimestampDesc(
        companyId: UUID,
        metricName: String
    ): List<PerformanceMetric>
    
    /**
     * 메트릭 타입별 조회
     */
    fun findByCompanyIdAndMetricTypeOrderByTimestampDesc(
        companyId: UUID,
        metricType: PerformanceMetricType
    ): List<PerformanceMetric>
    
    /**
     * 기간별 메트릭 조회
     */
    fun findByCompanyIdAndTimestampBetweenOrderByTimestampDesc(
        companyId: UUID,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): List<PerformanceMetric>
    
    /**
     * 상태별 메트릭 조회
     */
    fun findByCompanyIdAndStatusOrderByTimestampDesc(
        companyId: UUID,
        status: MetricStatus
    ): List<PerformanceMetric>
    
    /**
     * 최근 메트릭 조회
     */
    @Query("""
        SELECT pm FROM PerformanceMetric pm 
        WHERE pm.companyId = :companyId 
        AND pm.timestamp >= :since
        ORDER BY pm.timestamp DESC
    """)
    fun findRecentMetrics(
        @Param("companyId") companyId: UUID,
        @Param("since") since: LocalDateTime
    ): List<PerformanceMetric>
    
    /**
     * 메트릭 통계 조회
     */
    @Query("""
        SELECT 
            pm.metricName as metricName,
            pm.metricType as metricType,
            COUNT(*) as count,
            AVG(pm.value) as average,
            MIN(pm.value) as minimum,
            MAX(pm.value) as maximum,
            pm.unit as unit
        FROM PerformanceMetric pm 
        WHERE pm.companyId = :companyId 
        AND pm.metricName = :metricName
        AND pm.timestamp BETWEEN :startTime AND :endTime
        GROUP BY pm.metricName, pm.metricType, pm.unit
    """)
    fun getMetricStatistics(
        @Param("companyId") companyId: UUID,
        @Param("metricName") metricName: String,
        @Param("startTime") startTime: LocalDateTime,
        @Param("endTime") endTime: LocalDateTime
    ): List<Map<String, Any>>
    
    /**
     * 임계값 초과 메트릭 조회
     */
    @Query("""
        SELECT pm FROM PerformanceMetric pm 
        WHERE pm.companyId = :companyId 
        AND pm.threshold IS NOT NULL 
        AND pm.value > pm.threshold
        AND pm.timestamp >= :since
        ORDER BY pm.timestamp DESC
    """)
    fun findMetricsExceedingThreshold(
        @Param("companyId") companyId: UUID,
        @Param("since") since: LocalDateTime
    ): List<PerformanceMetric>
}

/**
 * 성능 알림 리포지토리
 */
@Repository
interface PerformanceAlertRepository : JpaRepository<PerformanceAlert, UUID> {
    
    /**
     * 활성 알림 조회
     */
    fun findByCompanyIdAndStatusOrderByTriggeredAtDesc(
        companyId: UUID,
        status: AlertStatus
    ): List<PerformanceAlert>
    
    /**
     * 심각도별 알림 조회
     */
    fun findByCompanyIdAndSeverityOrderByTriggeredAtDesc(
        companyId: UUID,
        severity: AlertSeverity
    ): List<PerformanceAlert>
    
    /**
     * 메트릭별 알림 조회
     */
    fun findByCompanyIdAndMetricNameOrderByTriggeredAtDesc(
        companyId: UUID,
        metricName: String
    ): List<PerformanceAlert>
    
    /**
     * 기간별 알림 조회
     */
    fun findByCompanyIdAndTriggeredAtBetweenOrderByTriggeredAtDesc(
        companyId: UUID,
        startTime: LocalDateTime,
        endTime: LocalDateTime
    ): List<PerformanceAlert>
    
    /**
     * 해결되지 않은 알림 조회
     */
    @Query("""
        SELECT pa FROM PerformanceAlert pa 
        WHERE pa.companyId = :companyId 
        AND pa.status = 'ACTIVE'
        AND pa.triggeredAt <= :before
        ORDER BY pa.severity DESC, pa.triggeredAt ASC
    """)
    fun findUnresolvedAlerts(
        @Param("companyId") companyId: UUID,
        @Param("before") before: LocalDateTime
    ): List<PerformanceAlert>
    
    /**
     * 알림 통계 조회
     */
    @Query("""
        SELECT 
            pa.severity as severity,
            pa.status as status,
            COUNT(*) as count
        FROM PerformanceAlert pa 
        WHERE pa.companyId = :companyId 
        AND pa.triggeredAt BETWEEN :startTime AND :endTime
        GROUP BY pa.severity, pa.status
    """)
    fun getAlertStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startTime") startTime: LocalDateTime,
        @Param("endTime") endTime: LocalDateTime
    ): List<Map<String, Any>>
}

/**
 * 성능 임계값 리포지토리
 */
@Repository
interface PerformanceThresholdRepository : JpaRepository<PerformanceThreshold, UUID> {
    
    /**
     * 회사별 임계값 조회
     */
    fun findByCompanyIdOrderByMetricNameAsc(companyId: UUID): List<PerformanceThreshold>
    
    /**
     * 메트릭별 임계값 조회
     */
    fun findByCompanyIdAndMetricName(companyId: UUID, metricName: String): PerformanceThreshold?
    
    /**
     * 메트릭 타입별 임계값 조회
     */
    fun findByCompanyIdAndMetricType(companyId: UUID, metricType: PerformanceMetricType): List<PerformanceThreshold>
    
    /**
     * 활성 임계값 조회
     */
    fun findByCompanyIdAndIsEnabledTrueOrderByMetricNameAsc(companyId: UUID): List<PerformanceThreshold>
}

/**
 * 캐시 통계 리포지토리
 */
@Repository
interface CacheStatisticsRepository : JpaRepository<CacheStatistics, UUID> {
    
    /**
     * 회사별 캐시 통계 조회
     */
    fun findByCompanyIdOrderByLastUpdatedDesc(companyId: UUID): List<CacheStatistics>
    
    /**
     * 캐시 이름별 통계 조회
     */
    fun findByCompanyIdAndCacheName(companyId: UUID, cacheName: String): CacheStatistics?
    
    /**
     * 히트율이 낮은 캐시 조회
     */
    @Query("""
        SELECT cs FROM CacheStatistics cs 
        WHERE cs.companyId = :companyId 
        AND cs.hitRate < :threshold
        ORDER BY cs.hitRate ASC
    """)
    fun findCachesWithLowHitRate(
        @Param("companyId") companyId: UUID,
        @Param("threshold") threshold: Double
    ): List<CacheStatistics>
    
    /**
     * 캐시 사용률이 높은 캐시 조회
     */
    @Query("""
        SELECT cs FROM CacheStatistics cs 
        WHERE cs.companyId = :companyId 
        AND (cs.size * 100.0 / cs.maxSize) > :threshold
        ORDER BY (cs.size * 100.0 / cs.maxSize) DESC
    """)
    fun findCachesWithHighUsage(
        @Param("companyId") companyId: UUID,
        @Param("threshold") threshold: Double
    ): List<CacheStatistics>
}

/**
 * 느린 쿼리 리포지토리
 */
@Repository
interface SlowQueryRepository : JpaRepository<SlowQuery, UUID> {
    
    /**
     * 회사별 느린 쿼리 조회
     */
    fun findByCompanyIdOrderByExecutionTimeDesc(companyId: UUID): List<SlowQuery>
    
    /**
     * 실행 시간 기준 상위 쿼리 조회
     */
    @Query("""
        SELECT sq FROM SlowQuery sq 
        WHERE sq.companyId = :companyId 
        ORDER BY sq.executionTime DESC
    """)
    fun findTopSlowQueries(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<SlowQuery>
    
    /**
     * 실행 횟수 기준 상위 쿼리 조회
     */
    @Query("""
        SELECT sq FROM SlowQuery sq 
        WHERE sq.companyId = :companyId 
        ORDER BY sq.executionCount DESC
    """)
    fun findMostExecutedQueries(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<SlowQuery>
    
    /**
     * 평균 시간 기준 상위 쿼리 조회
     */
    @Query("""
        SELECT sq FROM SlowQuery sq 
        WHERE sq.companyId = :companyId 
        ORDER BY sq.averageTime DESC
    """)
    fun findQueriesWithHighAverageTime(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<SlowQuery>
    
    /**
     * 쿼리 해시로 조회
     */
    @Query("""
        SELECT sq FROM SlowQuery sq 
        WHERE sq.companyId = :companyId 
        AND FUNCTION('MD5', sq.query) = :queryHash
    """)
    fun findByQueryHash(
        @Param("companyId") companyId: UUID,
        @Param("queryHash") queryHash: String
    ): SlowQuery?
}

/**
 * API 성능 리포지토리
 */
@Repository
interface ApiPerformanceRepository : JpaRepository<ApiPerformance, UUID> {
    
    /**
     * 회사별 API 성능 조회
     */
    fun findByCompanyIdOrderByLastUpdatedDesc(companyId: UUID): List<ApiPerformance>
    
    /**
     * 엔드포인트별 성능 조회
     */
    fun findByCompanyIdAndEndpointAndMethod(
        companyId: UUID,
        endpoint: String,
        method: String
    ): ApiPerformance?
    
    /**
     * 응답 시간이 느린 API 조회
     */
    @Query("""
        SELECT ap FROM ApiPerformance ap 
        WHERE ap.companyId = :companyId 
        AND ap.averageResponseTime > :threshold
        ORDER BY ap.averageResponseTime DESC
    """)
    fun findSlowApis(
        @Param("companyId") companyId: UUID,
        @Param("threshold") threshold: Double
    ): List<ApiPerformance>
    
    /**
     * 오류율이 높은 API 조회
     */
    @Query("""
        SELECT ap FROM ApiPerformance ap 
        WHERE ap.companyId = :companyId 
        AND ap.errorRate > :threshold
        ORDER BY ap.errorRate DESC
    """)
    fun findApisWithHighErrorRate(
        @Param("companyId") companyId: UUID,
        @Param("threshold") threshold: Double
    ): List<ApiPerformance>
    
    /**
     * 처리량이 높은 API 조회
     */
    @Query("""
        SELECT ap FROM ApiPerformance ap 
        WHERE ap.companyId = :companyId 
        ORDER BY ap.throughput DESC
    """)
    fun findHighThroughputApis(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<ApiPerformance>
    
    /**
     * 기간별 API 성능 조회
     */
    fun findByCompanyIdAndPeriodOrderByLastUpdatedDesc(
        companyId: UUID,
        period: String
    ): List<ApiPerformance>
}

/**
 * 최적화 제안 리포지토리
 */
@Repository
interface OptimizationSuggestionRepository : JpaRepository<OptimizationSuggestion, UUID> {
    
    /**
     * 회사별 제안 조회
     */
    fun findByCompanyIdOrderByPriorityAscCreatedAtDesc(companyId: UUID): List<OptimizationSuggestion>
    
    /**
     * 카테고리별 제안 조회
     */
    fun findByCompanyIdAndCategoryOrderByPriorityAsc(
        companyId: UUID,
        category: OptimizationCategory
    ): List<OptimizationSuggestion>
    
    /**
     * 영향도별 제안 조회
     */
    fun findByCompanyIdAndImpactOrderByPriorityAsc(
        companyId: UUID,
        impact: ImpactLevel
    ): List<OptimizationSuggestion>
    
    /**
     * 노력 수준별 제안 조회
     */
    fun findByCompanyIdAndEffortOrderByPriorityAsc(
        companyId: UUID,
        effort: EffortLevel
    ): List<OptimizationSuggestion>
    
    /**
     * 우선순위 기준 상위 제안 조회
     */
    @Query("""
        SELECT os FROM OptimizationSuggestion os 
        WHERE os.companyId = :companyId 
        ORDER BY os.priority ASC, os.impact DESC, os.effort ASC
    """)
    fun findTopPriorityRecommendations(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<OptimizationSuggestion>
    
    /**
     * 빠른 승리 제안 조회 (높은 영향도, 낮은 노력)
     */
    @Query("""
        SELECT os FROM OptimizationSuggestion os 
        WHERE os.companyId = :companyId 
        AND os.impact = 'HIGH'
        AND os.effort = 'LOW'
        ORDER BY os.priority ASC
    """)
    fun findQuickWins(@Param("companyId") companyId: UUID): List<OptimizationSuggestion>
}