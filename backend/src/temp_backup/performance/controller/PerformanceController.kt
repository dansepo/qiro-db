package com.qiro.domain.performance.controller

import com.qiro.domain.performance.dto.*
import com.qiro.domain.performance.service.CachingService
import com.qiro.domain.performance.service.PerformanceMonitoringService
import com.qiro.domain.performance.service.PerformanceOptimizationService
import com.qiro.global.response.ApiResponse
import com.qiro.global.security.CurrentUser
import com.qiro.global.security.UserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*

/**
 * 성능 모니터링 컨트롤러
 */
@Tag(name = "Performance Monitoring", description = "성능 모니터링 API")
@RestController
@RequestMapping("/api/v1/performance")
class PerformanceController(
    private val performanceMonitoringService: PerformanceMonitoringService,
    private val performanceOptimizationService: PerformanceOptimizationService,
    private val cachingService: CachingService
) {

    /**
     * 성능 메트릭 기록
     */
    @Operation(summary = "성능 메트릭 기록", description = "새로운 성능 메트릭을 기록합니다")
    @PostMapping("/metrics")
    @PreAuthorize("hasRole('ADMIN')")
    fun recordMetric(
        @Parameter(description = "성능 메트릭 생성 요청") @Valid @RequestBody request: CreatePerformanceMetricRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<PerformanceMetricDto>> {
        val result = performanceMonitoringService.recordMetric(request, userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 성능 메트릭 조회
     */
    @Operation(summary = "성능 메트릭 조회", description = "성능 메트릭을 조회합니다")
    @GetMapping("/metrics")
    @PreAuthorize("hasRole('ADMIN')")
    fun getMetrics(
        @Parameter(description = "메트릭 이름") @RequestParam(required = false) metricName: String?,
        @Parameter(description = "메트릭 타입") @RequestParam(required = false) metricType: PerformanceMetricType?,
        @Parameter(description = "시작 시간") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startTime: LocalDateTime?,
        @Parameter(description = "종료 시간") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endTime: LocalDateTime?,
        @Parameter(description = "상태") @RequestParam(required = false) status: MetricStatus?,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<PerformanceMetricDto>>> {
        val result = performanceMonitoringService.getMetrics(
            companyId = userPrincipal.companyId,
            metricName = metricName,
            metricType = metricType,
            startTime = startTime,
            endTime = endTime,
            status = status
        )
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 성능 통계 조회
     */
    @Operation(summary = "성능 통계 조회", description = "특정 메트릭의 통계를 조회합니다")
    @GetMapping("/metrics/{metricName}/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    fun getMetricStatistics(
        @Parameter(description = "메트릭 이름") @PathVariable metricName: String,
        @Parameter(description = "시작 시간") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startTime: LocalDateTime,
        @Parameter(description = "종료 시간") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endTime: LocalDateTime,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<PerformanceStatisticsDto>> {
        val result = performanceMonitoringService.getMetricStatistics(
            companyId = userPrincipal.companyId,
            metricName = metricName,
            startTime = startTime,
            endTime = endTime
        )
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 성능 알림 조회
     */
    @Operation(summary = "성능 알림 조회", description = "성능 알림을 조회합니다")
    @GetMapping("/alerts")
    @PreAuthorize("hasRole('ADMIN')")
    fun getAlerts(
        @Parameter(description = "알림 상태") @RequestParam(required = false) status: AlertStatus?,
        @Parameter(description = "심각도") @RequestParam(required = false) severity: AlertSeverity?,
        @Parameter(description = "메트릭 이름") @RequestParam(required = false) metricName: String?,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<PerformanceAlertDto>>> {
        val result = performanceMonitoringService.getAlerts(
            companyId = userPrincipal.companyId,
            status = status,
            severity = severity,
            metricName = metricName
        )
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 시스템 상태 조회
     */
    @Operation(summary = "시스템 상태 조회", description = "전체 시스템의 상태를 조회합니다")
    @GetMapping("/system/health")
    @PreAuthorize("hasRole('USER')")
    fun getSystemHealth(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<SystemHealthDto>> {
        val result = performanceMonitoringService.getSystemHealth(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 성능 대시보드 조회
     */
    @Operation(summary = "성능 대시보드 조회", description = "성능 모니터링 대시보드 데이터를 조회합니다")
    @GetMapping("/dashboard")
    @PreAuthorize("hasRole('ADMIN')")
    fun getPerformanceDashboard(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<PerformanceDashboardDto>> {
        val result = performanceMonitoringService.getPerformanceDashboard(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 성능 트렌드 분석
     */
    @Operation(summary = "성능 트렌드 분석", description = "특정 메트릭의 트렌드를 분석합니다")
    @GetMapping("/metrics/{metricName}/trend")
    @PreAuthorize("hasRole('ADMIN')")
    fun getPerformanceTrend(
        @Parameter(description = "메트릭 이름") @PathVariable metricName: String,
        @Parameter(description = "시작 시간") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startTime: LocalDateTime,
        @Parameter(description = "종료 시간") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endTime: LocalDateTime,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<PerformanceTrendDto>> {
        val result = performanceMonitoringService.getPerformanceTrend(
            companyId = userPrincipal.companyId,
            metricName = metricName,
            startTime = startTime,
            endTime = endTime
        )
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 최적화 제안 생성
     */
    @Operation(summary = "최적화 제안 생성", description = "시스템 성능 최적화 제안을 생성합니다")
    @PostMapping("/optimization/suggestions")
    @PreAuthorize("hasRole('ADMIN')")
    fun generateOptimizationSuggestions(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<OptimizationSuggestionDto>>> {
        val result = performanceMonitoringService.generateOptimizationSuggestions(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }
}

/**
 * 성능 최적화 컨트롤러
 */
@Tag(name = "Performance Optimization", description = "성능 최적화 API")
@RestController
@RequestMapping("/api/v1/performance/optimization")
class PerformanceOptimizationController(
    private val performanceOptimizationService: PerformanceOptimizationService
) {

    /**
     * 전체 시스템 성능 최적화
     */
    @Operation(summary = "전체 시스템 성능 최적화", description = "전체 시스템의 성능을 최적화합니다")
    @PostMapping("/system")
    @PreAuthorize("hasRole('ADMIN')")
    fun optimizeSystemPerformance(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<PerformanceReportDto>> {
        val result = performanceOptimizationService.optimizeSystemPerformance(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 캐시 성능 최적화
     */
    @Operation(summary = "캐시 성능 최적화", description = "캐시 시스템의 성능을 최적화합니다")
    @PostMapping("/cache")
    @PreAuthorize("hasRole('ADMIN')")
    fun optimizeCachePerformance(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val result = performanceOptimizationService.optimizeCachePerformance(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * API 응답 시간 최적화
     */
    @Operation(summary = "API 응답 시간 최적화", description = "API의 응답 시간을 최적화합니다")
    @PostMapping("/api")
    @PreAuthorize("hasRole('ADMIN')")
    fun optimizeApiResponseTime(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<ApiPerformanceDto>>> {
        val result = performanceOptimizationService.optimizeApiResponseTime(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 메모리 사용량 최적화
     */
    @Operation(summary = "메모리 사용량 최적화", description = "메모리 사용량을 최적화합니다")
    @PostMapping("/memory")
    @PreAuthorize("hasRole('ADMIN')")
    fun optimizeMemoryUsage(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val result = performanceOptimizationService.optimizeMemoryUsage(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 동시 사용자 처리 최적화
     */
    @Operation(summary = "동시 사용자 처리 최적화", description = "동시 사용자 처리 성능을 최적화합니다")
    @PostMapping("/concurrent-users")
    @PreAuthorize("hasRole('ADMIN')")
    fun optimizeConcurrentUserHandling(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val result = performanceOptimizationService.optimizeConcurrentUserHandling(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 자동 성능 튜닝
     */
    @Operation(summary = "자동 성능 튜닝", description = "시스템을 자동으로 분석하여 성능을 튜닝합니다")
    @PostMapping("/auto-tune")
    @PreAuthorize("hasRole('ADMIN')")
    fun autoTunePerformance(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<OptimizationSuggestionDto>>> {
        val result = performanceOptimizationService.autoTunePerformance(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }
}

/**
 * 캐시 관리 컨트롤러
 */
@Tag(name = "Cache Management", description = "캐시 관리 API")
@RestController
@RequestMapping("/api/v1/cache")
class CacheController(
    private val cachingService: CachingService
) {

    /**
     * 캐시 통계 조회
     */
    @Operation(summary = "캐시 통계 조회", description = "모든 캐시의 통계를 조회합니다")
    @GetMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    fun getCacheStatistics(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<List<CacheStatisticsDto>>> {
        val result = cachingService.getCacheStatistics(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 캐시 성능 분석
     */
    @Operation(summary = "캐시 성능 분석", description = "캐시 시스템의 성능을 분석합니다")
    @GetMapping("/analysis")
    @PreAuthorize("hasRole('ADMIN')")
    fun analyzeCachePerformance(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val result = cachingService.analyzeCachePerformance(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 특정 캐시 제거
     */
    @Operation(summary = "특정 캐시 제거", description = "지정된 캐시를 제거합니다")
    @DeleteMapping("/{cacheName}")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictCache(
        @Parameter(description = "캐시 이름") @PathVariable cacheName: String
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictCache(cacheName)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 모든 캐시 제거
     */
    @Operation(summary = "모든 캐시 제거", description = "모든 캐시를 제거합니다")
    @DeleteMapping("/all")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictAllCaches(): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictAllCaches()
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 캐시 워밍업
     */
    @Operation(summary = "캐시 워밍업", description = "자주 사용되는 데이터를 캐시에 미리 로드합니다")
    @PostMapping("/warmup")
    @PreAuthorize("hasRole('ADMIN')")
    fun warmUpCaches(
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.warmUpCaches(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 시설물 캐시 제거
     */
    @Operation(summary = "시설물 캐시 제거", description = "특정 시설물의 캐시를 제거합니다")
    @DeleteMapping("/facilities/{facilityId}")
    @PreAuthorize("hasRole('USER')")
    fun evictFacilityCache(
        @Parameter(description = "시설물 ID") @PathVariable facilityId: UUID
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictFacilityCache(facilityId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 사용자 캐시 제거
     */
    @Operation(summary = "사용자 캐시 제거", description = "특정 사용자의 캐시를 제거합니다")
    @DeleteMapping("/users/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictUserCache(
        @Parameter(description = "사용자 ID") @PathVariable userId: UUID
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictUserCache(userId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 권한 캐시 제거
     */
    @Operation(summary = "권한 캐시 제거", description = "특정 사용자의 권한 캐시를 제거합니다")
    @DeleteMapping("/permissions/{userId}")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictUserPermissionsCache(
        @Parameter(description = "사용자 ID") @PathVariable userId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictUserPermissionsCache(userId, userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 작업지시서 캐시 제거
     */
    @Operation(summary = "작업지시서 캐시 제거", description = "작업지시서 목록 캐시를 제거합니다")
    @DeleteMapping("/work-orders")
    @PreAuthorize("hasRole('USER')")
    fun evictWorkOrdersCache(): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictWorkOrdersCache()
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 대시보드 캐시 제거
     */
    @Operation(summary = "대시보드 캐시 제거", description = "대시보드 데이터 캐시를 제거합니다")
    @DeleteMapping("/dashboard")
    @PreAuthorize("hasRole('USER')")
    fun evictDashboardCache(): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictDashboardCache()
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 알림 템플릿 캐시 제거
     */
    @Operation(summary = "알림 템플릿 캐시 제거", description = "알림 템플릿 캐시를 제거합니다")
    @DeleteMapping("/notification-templates")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictNotificationTemplatesCache(): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictNotificationTemplatesCache()
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 설정 캐시 제거
     */
    @Operation(summary = "설정 캐시 제거", description = "특정 설정의 캐시를 제거합니다")
    @DeleteMapping("/settings/{settingKey}")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictSettingCache(
        @Parameter(description = "설정 키") @PathVariable settingKey: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictSettingCache(userPrincipal.companyId, settingKey)
        return ResponseEntity.ok(ApiResponse.success())
    }

    /**
     * 통계 캐시 제거
     */
    @Operation(summary = "통계 캐시 제거", description = "통계 데이터 캐시를 제거합니다")
    @DeleteMapping("/statistics")
    @PreAuthorize("hasRole('ADMIN')")
    fun evictStatisticsCache(): ResponseEntity<ApiResponse<Void>> {
        cachingService.evictStatisticsCache()
        return ResponseEntity.ok(ApiResponse.success())
    }
}