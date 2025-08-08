package com.qiro.domain.performance.service

import com.qiro.domain.performance.dto.CacheStatisticsDto
import org.springframework.cache.Cache
import org.springframework.cache.CacheManager
import org.springframework.cache.annotation.CacheEvict
import org.springframework.cache.annotation.CachePut
import org.springframework.cache.annotation.Cacheable
import org.springframework.stereotype.Service
import java.time.LocalDateTime
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * 캐싱 서비스
 */
@Service
class CachingService(
    private val cacheManager: CacheManager,
    private val performanceMonitoringService: PerformanceMonitoringService
) {

    private val cacheStatistics = ConcurrentHashMap<String, CacheMetrics>()

    /**
     * 시설물 정보 캐싱
     */
    @Cacheable(value = ["facilities"], key = "#facilityId")
    fun getFacilityFromCache(facilityId: UUID, companyId: UUID): Any? {
        recordCacheAccess("facilities", true)
        return null // 실제 구현에서는 데이터베이스에서 조회
    }

    /**
     * 시설물 정보 캐시 업데이트
     */
    @CachePut(value = ["facilities"], key = "#facilityId")
    fun updateFacilityCache(facilityId: UUID, facility: Any): Any {
        recordCacheAccess("facilities", false)
        return facility
    }

    /**
     * 시설물 정보 캐시 제거
     */
    @CacheEvict(value = ["facilities"], key = "#facilityId")
    fun evictFacilityCache(facilityId: UUID) {
        recordCacheEviction("facilities")
    }

    /**
     * 사용자 정보 캐싱
     */
    @Cacheable(value = ["users"], key = "#userId")
    fun getUserFromCache(userId: UUID, companyId: UUID): Any? {
        recordCacheAccess("users", true)
        return null // 실제 구현에서는 데이터베이스에서 조회
    }

    /**
     * 사용자 정보 캐시 업데이트
     */
    @CachePut(value = ["users"], key = "#userId")
    fun updateUserCache(userId: UUID, user: Any): Any {
        recordCacheAccess("users", false)
        return user
    }

    /**
     * 사용자 정보 캐시 제거
     */
    @CacheEvict(value = ["users"], key = "#userId")
    fun evictUserCache(userId: UUID) {
        recordCacheEviction("users")
    }

    /**
     * 권한 정보 캐싱
     */
    @Cacheable(value = ["permissions"], key = "#userId + '_' + #companyId")
    fun getUserPermissionsFromCache(userId: UUID, companyId: UUID): Any? {
        recordCacheAccess("permissions", true)
        return null // 실제 구현에서는 권한 서비스에서 조회
    }

    /**
     * 권한 정보 캐시 업데이트
     */
    @CachePut(value = ["permissions"], key = "#userId + '_' + #companyId")
    fun updateUserPermissionsCache(userId: UUID, companyId: UUID, permissions: Any): Any {
        recordCacheAccess("permissions", false)
        return permissions
    }

    /**
     * 권한 정보 캐시 제거
     */
    @CacheEvict(value = ["permissions"], key = "#userId + '_' + #companyId")
    fun evictUserPermissionsCache(userId: UUID, companyId: UUID) {
        recordCacheEviction("permissions")
    }

    /**
     * 작업지시서 목록 캐싱
     */
    @Cacheable(value = ["workOrders"], key = "#companyId + '_' + #status + '_' + #page")
    fun getWorkOrdersFromCache(companyId: UUID, status: String?, page: Int): Any? {
        recordCacheAccess("workOrders", true)
        return null // 실제 구현에서는 작업지시서 서비스에서 조회
    }

    /**
     * 작업지시서 목록 캐시 제거
     */
    @CacheEvict(value = ["workOrders"], allEntries = true)
    fun evictWorkOrdersCache() {
        recordCacheEviction("workOrders")
    }

    /**
     * 대시보드 데이터 캐싱
     */
    @Cacheable(value = ["dashboard"], key = "#companyId + '_' + #userId")
    fun getDashboardDataFromCache(companyId: UUID, userId: UUID): Any? {
        recordCacheAccess("dashboard", true)
        return null // 실제 구현에서는 대시보드 서비스에서 조회
    }

    /**
     * 대시보드 데이터 캐시 업데이트
     */
    @CachePut(value = ["dashboard"], key = "#companyId + '_' + #userId")
    fun updateDashboardDataCache(companyId: UUID, userId: UUID, dashboardData: Any): Any {
        recordCacheAccess("dashboard", false)
        return dashboardData
    }

    /**
     * 대시보드 데이터 캐시 제거
     */
    @CacheEvict(value = ["dashboard"], allEntries = true)
    fun evictDashboardCache() {
        recordCacheEviction("dashboard")
    }

    /**
     * 알림 템플릿 캐싱
     */
    @Cacheable(value = ["notificationTemplates"], key = "#templateType + '_' + #companyId")
    fun getNotificationTemplateFromCache(templateType: String, companyId: UUID): Any? {
        recordCacheAccess("notificationTemplates", true)
        return null // 실제 구현에서는 알림 서비스에서 조회
    }

    /**
     * 알림 템플릿 캐시 업데이트
     */
    @CachePut(value = ["notificationTemplates"], key = "#templateType + '_' + #companyId")
    fun updateNotificationTemplateCache(templateType: String, companyId: UUID, template: Any): Any {
        recordCacheAccess("notificationTemplates", false)
        return template
    }

    /**
     * 알림 템플릿 캐시 제거
     */
    @CacheEvict(value = ["notificationTemplates"], allEntries = true)
    fun evictNotificationTemplatesCache() {
        recordCacheEviction("notificationTemplates")
    }

    /**
     * 설정 정보 캐싱
     */
    @Cacheable(value = ["settings"], key = "#companyId + '_' + #settingKey")
    fun getSettingFromCache(companyId: UUID, settingKey: String): Any? {
        recordCacheAccess("settings", true)
        return null // 실제 구현에서는 설정 서비스에서 조회
    }

    /**
     * 설정 정보 캐시 업데이트
     */
    @CachePut(value = ["settings"], key = "#companyId + '_' + #settingKey")
    fun updateSettingCache(companyId: UUID, settingKey: String, settingValue: Any): Any {
        recordCacheAccess("settings", false)
        return settingValue
    }

    /**
     * 설정 정보 캐시 제거
     */
    @CacheEvict(value = ["settings"], key = "#companyId + '_' + #settingKey")
    fun evictSettingCache(companyId: UUID, settingKey: String) {
        recordCacheEviction("settings")
    }

    /**
     * 통계 데이터 캐싱
     */
    @Cacheable(value = ["statistics"], key = "#companyId + '_' + #statisticsType + '_' + #period")
    fun getStatisticsFromCache(companyId: UUID, statisticsType: String, period: String): Any? {
        recordCacheAccess("statistics", true)
        return null // 실제 구현에서는 통계 서비스에서 조회
    }

    /**
     * 통계 데이터 캐시 업데이트
     */
    @CachePut(value = ["statistics"], key = "#companyId + '_' + #statisticsType + '_' + #period")
    fun updateStatisticsCache(companyId: UUID, statisticsType: String, period: String, statistics: Any): Any {
        recordCacheAccess("statistics", false)
        return statistics
    }

    /**
     * 통계 데이터 캐시 제거
     */
    @CacheEvict(value = ["statistics"], allEntries = true)
    fun evictStatisticsCache() {
        recordCacheEviction("statistics")
    }

    /**
     * 모든 캐시 제거
     */
    @CacheEvict(value = ["facilities", "users", "permissions", "workOrders", "dashboard", "notificationTemplates", "settings", "statistics"], allEntries = true)
    fun evictAllCaches() {
        cacheStatistics.keys.forEach { cacheName ->
            recordCacheEviction(cacheName)
        }
    }

    /**
     * 특정 캐시 제거
     */
    fun evictCache(cacheName: String) {
        val cache = cacheManager.getCache(cacheName)
        cache?.clear()
        recordCacheEviction(cacheName)
    }

    /**
     * 캐시 통계 조회
     */
    fun getCacheStatistics(companyId: UUID): List<CacheStatisticsDto> {
        val statistics = mutableListOf<CacheStatisticsDto>()
        
        cacheManager.cacheNames.forEach { cacheName ->
            val cache = cacheManager.getCache(cacheName)
            val metrics = cacheStatistics[cacheName] ?: CacheMetrics()
            
            if (cache != null) {
                val nativeCache = cache.nativeCache
                val size = when (nativeCache) {
                    is com.github.benmanes.caffeine.cache.Cache<*, *> -> nativeCache.estimatedSize()
                    else -> 0L
                }
                
                // 캐시 통계 업데이트
                performanceMonitoringService.updateCacheStatistics(
                    cacheName = cacheName,
                    hitCount = metrics.hitCount,
                    missCount = metrics.missCount,
                    evictionCount = metrics.evictionCount,
                    size = size,
                    maxSize = 10000, // 설정에서 가져와야 함
                    averageLoadTime = metrics.averageLoadTime,
                    companyId = companyId
                )
                
                statistics.add(
                    CacheStatisticsDto(
                        cacheName = cacheName,
                        hitCount = metrics.hitCount,
                        missCount = metrics.missCount,
                        hitRate = metrics.getHitRate(),
                        evictionCount = metrics.evictionCount,
                        size = size,
                        maxSize = 10000,
                        averageLoadTime = metrics.averageLoadTime,
                        lastUpdated = LocalDateTime.now()
                    )
                )
            }
        }
        
        return statistics
    }

    /**
     * 캐시 워밍업
     */
    fun warmUpCaches(companyId: UUID) {
        // 자주 사용되는 데이터를 미리 캐시에 로드
        
        // 활성 사용자 정보 로드
        // loadActiveUsers(companyId)
        
        // 자주 조회되는 시설물 정보 로드
        // loadFrequentlyAccessedFacilities(companyId)
        
        // 알림 템플릿 로드
        // loadNotificationTemplates(companyId)
        
        // 시스템 설정 로드
        // loadSystemSettings(companyId)
    }

    /**
     * 캐시 성능 분석
     */
    fun analyzeCachePerformance(companyId: UUID): Map<String, Any> {
        val analysis = mutableMapOf<String, Any>()
        val statistics = getCacheStatistics(companyId)
        
        // 전체 히트율
        val totalHits = statistics.sumOf { it.hitCount }
        val totalMisses = statistics.sumOf { it.missCount }
        val overallHitRate = if (totalHits + totalMisses > 0) {
            totalHits.toDouble() / (totalHits + totalMisses)
        } else 0.0
        
        analysis["overallHitRate"] = overallHitRate
        analysis["totalCaches"] = statistics.size
        analysis["totalSize"] = statistics.sumOf { it.size }
        analysis["totalMaxSize"] = statistics.sumOf { it.maxSize }
        
        // 성능이 좋지 않은 캐시 식별
        val lowPerformanceCaches = statistics.filter { it.hitRate < 0.7 }
        analysis["lowPerformanceCaches"] = lowPerformanceCaches.map { it.cacheName }
        
        // 사용률이 높은 캐시 식별
        val highUsageCaches = statistics.filter { 
            it.maxSize > 0 && (it.size.toDouble() / it.maxSize) > 0.8 
        }
        analysis["highUsageCaches"] = highUsageCaches.map { it.cacheName }
        
        // 권장사항
        val recommendations = mutableListOf<String>()
        if (overallHitRate < 0.8) {
            recommendations.add("전체 캐시 히트율이 낮습니다. 캐시 전략을 재검토하세요.")
        }
        if (lowPerformanceCaches.isNotEmpty()) {
            recommendations.add("히트율이 낮은 캐시들의 TTL과 크기를 조정하세요.")
        }
        if (highUsageCaches.isNotEmpty()) {
            recommendations.add("사용률이 높은 캐시들의 최대 크기를 증가시키는 것을 고려하세요.")
        }
        
        analysis["recommendations"] = recommendations
        
        return analysis
    }

    // Private helper methods
    
    private fun recordCacheAccess(cacheName: String, isHit: Boolean) {
        val metrics = cacheStatistics.computeIfAbsent(cacheName) { CacheMetrics() }
        if (isHit) {
            metrics.hitCount++
        } else {
            metrics.missCount++
        }
    }
    
    private fun recordCacheEviction(cacheName: String) {
        val metrics = cacheStatistics.computeIfAbsent(cacheName) { CacheMetrics() }
        metrics.evictionCount++
    }
    
    /**
     * 캐시 메트릭 클래스
     */
    private data class CacheMetrics(
        var hitCount: Long = 0,
        var missCount: Long = 0,
        var evictionCount: Long = 0,
        var averageLoadTime: Double = 0.0
    ) {
        fun getHitRate(): Double {
            val total = hitCount + missCount
            return if (total > 0) hitCount.toDouble() / total else 0.0
        }
    }
}

/**
 * 캐시 설정 서비스
 */
@Service
class CacheConfigurationService {
    
    /**
     * 캐시 설정 정보
     */
    data class CacheConfig(
        val name: String,
        val maxSize: Long,
        val ttlMinutes: Long,
        val refreshAfterWriteMinutes: Long? = null,
        val recordStats: Boolean = true
    )
    
    /**
     * 기본 캐시 설정들
     */
    fun getDefaultCacheConfigs(): List<CacheConfig> {
        return listOf(
            CacheConfig(
                name = "facilities",
                maxSize = 10000,
                ttlMinutes = 60,
                refreshAfterWriteMinutes = 30
            ),
            CacheConfig(
                name = "users",
                maxSize = 5000,
                ttlMinutes = 30,
                refreshAfterWriteMinutes = 15
            ),
            CacheConfig(
                name = "permissions",
                maxSize = 5000,
                ttlMinutes = 15
            ),
            CacheConfig(
                name = "workOrders",
                maxSize = 1000,
                ttlMinutes = 5
            ),
            CacheConfig(
                name = "dashboard",
                maxSize = 1000,
                ttlMinutes = 2
            ),
            CacheConfig(
                name = "notificationTemplates",
                maxSize = 500,
                ttlMinutes = 120
            ),
            CacheConfig(
                name = "settings",
                maxSize = 1000,
                ttlMinutes = 60
            ),
            CacheConfig(
                name = "statistics",
                maxSize = 2000,
                ttlMinutes = 10
            )
        )
    }
    
    /**
     * 캐시 설정 최적화 제안
     */
    fun optimizeCacheConfig(cacheName: String, statistics: CacheStatisticsDto): CacheConfig? {
        val currentConfig = getDefaultCacheConfigs().find { it.name == cacheName }
            ?: return null
        
        var optimizedConfig = currentConfig.copy()
        
        // 히트율이 낮으면 TTL 증가
        if (statistics.hitRate < 0.7) {
            optimizedConfig = optimizedConfig.copy(ttlMinutes = optimizedConfig.ttlMinutes * 2)
        }
        
        // 사용률이 높으면 최대 크기 증가
        val usageRate = statistics.size.toDouble() / statistics.maxSize
        if (usageRate > 0.8) {
            optimizedConfig = optimizedConfig.copy(maxSize = (optimizedConfig.maxSize * 1.5).toLong())
        }
        
        // 제거가 자주 발생하면 최대 크기 증가
        if (statistics.evictionCount > statistics.hitCount * 0.1) {
            optimizedConfig = optimizedConfig.copy(maxSize = (optimizedConfig.maxSize * 1.2).toLong())
        }
        
        return optimizedConfig
    }
}