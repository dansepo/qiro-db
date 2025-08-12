package com.qiro.domain.search.service

import com.qiro.domain.search.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 저장된 검색 서비스
 */
@Service
@Transactional
class SavedSearchService {

    // 실제 구현에서는 SavedSearchRepository 사용
    private val savedSearches = mutableMapOf<UUID, SavedSearchDto>()

    /**
     * 검색 저장
     */
    fun saveSearch(companyId: UUID, request: CreateSavedSearchRequest, userId: UUID): SavedSearchDto {
        val searchId = UUID.randomUUID()
        val savedSearch = SavedSearchDto(
            searchId = searchId,
            name = request.name,
            description = request.description,
            searchRequest = request.searchRequest,
            userId = userId,
            isPublic = request.isPublic,
            createdAt = LocalDateTime.now(),
            useCount = 0
        )
        
        savedSearches[searchId] = savedSearch
        return savedSearch
    }

    /**
     * 저장된 검색 수정
     */
    fun updateSavedSearch(searchId: UUID, request: CreateSavedSearchRequest, userId: UUID): SavedSearchDto {
        val existingSearch = savedSearches[searchId]
            ?: throw IllegalArgumentException("저장된 검색을 찾을 수 없습니다: $searchId")
        
        if (existingSearch.userId != userId) {
            throw IllegalArgumentException("권한이 없습니다")
        }
        
        val updatedSearch = existingSearch.copy(
            name = request.name,
            description = request.description,
            searchRequest = request.searchRequest,
            isPublic = request.isPublic,
            updatedAt = LocalDateTime.now()
        )
        
        savedSearches[searchId] = updatedSearch
        return updatedSearch
    }

    /**
     * 저장된 검색 조회
     */
    @Transactional(readOnly = true)
    fun getSavedSearch(searchId: UUID, userId: UUID): SavedSearchDto {
        val savedSearch = savedSearches[searchId]
            ?: throw IllegalArgumentException("저장된 검색을 찾을 수 없습니다: $searchId")
        
        if (savedSearch.userId != userId && !savedSearch.isPublic) {
            throw IllegalArgumentException("권한이 없습니다")
        }
        
        return savedSearch
    }

    /**
     * 사용자별 저장된 검색 목록 조회
     */
    @Transactional(readOnly = true)
    fun getSavedSearchesByUser(userId: UUID, pageable: Pageable): Page<SavedSearchDto> {
        val userSearches = savedSearches.values
            .filter { it.userId == userId }
            .sortedByDescending { it.createdAt }
        
        val start = pageable.offset.toInt()
        val end = minOf(start + pageable.pageSize, userSearches.size)
        val pageContent = if (start < userSearches.size) userSearches.subList(start, end) else emptyList()
        
        return PageImpl(pageContent, pageable, userSearches.size.toLong())
    }

    /**
     * 공개된 저장된 검색 목록 조회
     */
    @Transactional(readOnly = true)
    fun getPublicSavedSearches(pageable: Pageable): Page<SavedSearchDto> {
        val publicSearches = savedSearches.values
            .filter { it.isPublic }
            .sortedByDescending { it.useCount }
        
        val start = pageable.offset.toInt()
        val end = minOf(start + pageable.pageSize, publicSearches.size)
        val pageContent = if (start < publicSearches.size) publicSearches.subList(start, end) else emptyList()
        
        return PageImpl(pageContent, pageable, publicSearches.size.toLong())
    }

    /**
     * 저장된 검색 실행
     */
    fun executeSavedSearch(
        searchId: UUID, 
        userId: UUID, 
        unifiedSearchService: UnifiedSearchService,
        companyId: UUID,
        pageable: Pageable
    ): UnifiedSearchResponse {
        val savedSearch = getSavedSearch(searchId, userId)
        
        // 사용 횟수 증가
        val updatedSearch = savedSearch.copy(
            useCount = savedSearch.useCount + 1,
            lastUsedAt = LocalDateTime.now()
        )
        savedSearches[searchId] = updatedSearch
        
        return unifiedSearchService.search(companyId, savedSearch.searchRequest, pageable)
    }

    /**
     * 저장된 검색 삭제
     */
    fun deleteSavedSearch(searchId: UUID, userId: UUID) {
        val savedSearch = savedSearches[searchId]
            ?: throw IllegalArgumentException("저장된 검색을 찾을 수 없습니다: $searchId")
        
        if (savedSearch.userId != userId) {
            throw IllegalArgumentException("권한이 없습니다")
        }
        
        savedSearches.remove(searchId)
    }

    /**
     * 인기 저장된 검색 조회
     */
    @Transactional(readOnly = true)
    fun getPopularSavedSearches(limit: Int = 10): List<SavedSearchDto> {
        return savedSearches.values
            .filter { it.isPublic }
            .sortedByDescending { it.useCount }
            .take(limit)
    }

    /**
     * 최근 사용된 저장된 검색 조회
     */
    @Transactional(readOnly = true)
    fun getRecentlyUsedSavedSearches(userId: UUID, limit: Int = 5): List<SavedSearchDto> {
        return savedSearches.values
            .filter { it.userId == userId && it.lastUsedAt != null }
            .sortedByDescending { it.lastUsedAt }
            .take(limit)
    }
}

/**
 * 검색 통계 서비스
 */
@Service
@Transactional(readOnly = true)
class SearchStatisticsService {

    // 실제 구현에서는 SearchLogRepository 사용
    private val searchLogs = mutableListOf<SearchLogEntry>()

    /**
     * 검색 로그 기록
     */
    @Transactional
    fun logSearch(
        companyId: UUID,
        userId: UUID,
        query: String,
        searchTypes: List<SearchType>,
        resultCount: Long,
        responseTime: Long
    ) {
        val logEntry = SearchLogEntry(
            logId = UUID.randomUUID(),
            companyId = companyId,
            userId = userId,
            query = query,
            searchTypes = searchTypes,
            resultCount = resultCount,
            responseTime = responseTime,
            timestamp = LocalDateTime.now()
        )
        
        searchLogs.add(logEntry)
    }

    /**
     * 검색 통계 조회
     */
    fun getSearchStatistics(companyId: UUID, period: String): SearchStatisticsDto {
        val companyLogs = searchLogs.filter { it.companyId == companyId }
        
        val popularQueries = companyLogs
            .groupBy { it.query }
            .map { (query, logs) ->
                PopularQuery(
                    query = query,
                    count = logs.size.toLong(),
                    averageResults = logs.map { it.resultCount }.average()
                )
            }
            .sortedByDescending { it.count }
            .take(10)
        
        val searchTypeDistribution = companyLogs
            .flatMap { it.searchTypes }
            .groupBy { it }
            .mapValues { (_, types) -> types.size.toLong() }
        
        val noResultsQueries = companyLogs
            .filter { it.resultCount == 0L }
            .map { it.query }
            .distinct()
            .take(10)
        
        return SearchStatisticsDto(
            totalSearches = companyLogs.size.toLong(),
            popularQueries = popularQueries,
            searchTypeDistribution = searchTypeDistribution,
            averageResponseTime = companyLogs.map { it.responseTime }.average(),
            noResultsQueries = noResultsQueries,
            period = period
        )
    }

    /**
     * 사용자별 검색 통계 조회
     */
    fun getUserSearchStatistics(companyId: UUID, userId: UUID): Map<String, Any> {
        val userLogs = searchLogs.filter { it.companyId == companyId && it.userId == userId }
        
        return mapOf(
            "totalSearches" to userLogs.size,
            "averageResultCount" to userLogs.map { it.resultCount }.average(),
            "mostUsedSearchTypes" to userLogs
                .flatMap { it.searchTypes }
                .groupBy { it }
                .mapValues { (_, types) -> types.size }
                .toList()
                .sortedByDescending { it.second }
                .take(5),
            "recentQueries" to userLogs
                .sortedByDescending { it.timestamp }
                .take(10)
                .map { it.query }
        )
    }
}

/**
 * 검색 로그 엔트리 (내부 데이터 클래스)
 */
private data class SearchLogEntry(
    val logId: UUID,
    val companyId: UUID,
    val userId: UUID,
    val query: String,
    val searchTypes: List<SearchType>,
    val resultCount: Long,
    val responseTime: Long,
    val timestamp: LocalDateTime
)