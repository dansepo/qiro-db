package com.qiro.domain.search.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 통합 검색 요청 DTO
 */
data class UnifiedSearchRequest(
    val query: String,
    val searchTypes: List<SearchType> = SearchType.values().toList(),
    val filters: SearchFilters = SearchFilters(),
    val sortBy: String = "relevance",
    val sortDirection: SortDirection = SortDirection.DESC,
    val includeInactive: Boolean = false
)

/**
 * 검색 유형 열거형
 */
enum class SearchType {
    FAULT_REPORT,       // 고장 신고
    WORK_ORDER,         // 작업 지시서
    FACILITY_ASSET,     // 시설물 자산
    MAINTENANCE_PLAN,   // 정비 계획
    COST_TRACKING,      // 비용 기록
    USER,               // 사용자
    LOCATION            // 위치
}

/**
 * 정렬 방향 열거형
 */
enum class SortDirection {
    ASC, DESC
}

/**
 * 검색 필터 DTO
 */
data class SearchFilters(
    val dateRange: DateRangeFilter? = null,
    val status: List<String> = emptyList(),
    val priority: List<String> = emptyList(),
    val category: List<String> = emptyList(),
    val location: String? = null,
    val assignedTo: UUID? = null,
    val createdBy: UUID? = null,
    val amountRange: AmountRangeFilter? = null,
    val tags: List<String> = emptyList(),
    val customFields: Map<String, Any> = emptyMap()
)

/**
 * 날짜 범위 필터 DTO
 */
data class DateRangeFilter(
    val startDate: LocalDate,
    val endDate: LocalDate,
    val dateField: String = "createdAt" // createdAt, updatedAt, dueDate 등
)

/**
 * 금액 범위 필터 DTO
 */
data class AmountRangeFilter(
    val minAmount: BigDecimal,
    val maxAmount: BigDecimal
)

/**
 * 통합 검색 응답 DTO
 */
data class UnifiedSearchResponse(
    val query: String,
    val totalResults: Long,
    val searchTime: Long, // 밀리초
    val results: List<SearchResultGroup>,
    val suggestions: List<String> = emptyList(),
    val facets: Map<String, List<FacetItem>> = emptyMap()
)

/**
 * 검색 결과 그룹 DTO
 */
data class SearchResultGroup(
    val searchType: SearchType,
    val totalCount: Long,
    val items: List<SearchResultItem>
)

/**
 * 검색 결과 항목 DTO
 */
data class SearchResultItem(
    val id: UUID,
    val type: SearchType,
    val title: String,
    val description: String,
    val status: String,
    val priority: String? = null,
    val location: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime? = null,
    val assignedTo: String? = null,
    val createdBy: String? = null,
    val tags: List<String> = emptyList(),
    val relevanceScore: Double = 0.0,
    val highlights: Map<String, List<String>> = emptyMap(),
    val metadata: Map<String, Any> = emptyMap(),
    val url: String? = null,
    val thumbnailUrl: String? = null
)

/**
 * 패싯 항목 DTO
 */
data class FacetItem(
    val value: String,
    val count: Long,
    val selected: Boolean = false
)

/**
 * 고급 검색 요청 DTO
 */
data class AdvancedSearchRequest(
    val searchCriteria: List<SearchCriterion>,
    val logicalOperator: LogicalOperator = LogicalOperator.AND,
    val searchTypes: List<SearchType> = SearchType.values().toList(),
    val sortBy: String = "relevance",
    val sortDirection: SortDirection = SortDirection.DESC,
    val includeInactive: Boolean = false
)

/**
 * 검색 조건 DTO
 */
data class SearchCriterion(
    val field: String,
    val operator: SearchOperator,
    val value: Any,
    val boost: Double = 1.0
)

/**
 * 논리 연산자 열거형
 */
enum class LogicalOperator {
    AND, OR, NOT
}

/**
 * 검색 연산자 열거형
 */
enum class SearchOperator {
    EQUALS,             // 정확히 일치
    CONTAINS,           // 포함
    STARTS_WITH,        // 시작
    ENDS_WITH,          // 끝
    GREATER_THAN,       // 초과
    GREATER_THAN_OR_EQUAL, // 이상
    LESS_THAN,          // 미만
    LESS_THAN_OR_EQUAL, // 이하
    BETWEEN,            // 범위
    IN,                 // 목록 포함
    NOT_IN,             // 목록 제외
    IS_NULL,            // NULL
    IS_NOT_NULL,        // NOT NULL
    REGEX,              // 정규식
    FUZZY               // 유사 검색
}

/**
 * 검색 자동완성 요청 DTO
 */
data class AutocompleteRequest(
    val query: String,
    val searchTypes: List<SearchType> = SearchType.values().toList(),
    val limit: Int = 10,
    val includeInactive: Boolean = false
)

/**
 * 검색 자동완성 응답 DTO
 */
data class AutocompleteResponse(
    val query: String,
    val suggestions: List<AutocompleteSuggestion>
)

/**
 * 자동완성 제안 DTO
 */
data class AutocompleteSuggestion(
    val text: String,
    val type: SearchType,
    val count: Long,
    val highlight: String? = null
)

/**
 * 검색 통계 DTO
 */
data class SearchStatisticsDto(
    val totalSearches: Long,
    val popularQueries: List<PopularQuery>,
    val searchTypeDistribution: Map<SearchType, Long>,
    val averageResponseTime: Double,
    val noResultsQueries: List<String>,
    val period: String
)

/**
 * 인기 검색어 DTO
 */
data class PopularQuery(
    val query: String,
    val count: Long,
    val averageResults: Double
)

/**
 * 저장된 검색 DTO
 */
data class SavedSearchDto(
    val searchId: UUID,
    val name: String,
    val description: String? = null,
    val searchRequest: UnifiedSearchRequest,
    val userId: UUID,
    val isPublic: Boolean = false,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime? = null,
    val lastUsedAt: LocalDateTime? = null,
    val useCount: Long = 0
)

/**
 * 저장된 검색 생성 요청 DTO
 */
data class CreateSavedSearchRequest(
    val name: String,
    val description: String? = null,
    val searchRequest: UnifiedSearchRequest,
    val isPublic: Boolean = false
)

/**
 * 검색 필터 템플릿 DTO
 */
data class SearchFilterTemplate(
    val templateId: UUID,
    val name: String,
    val description: String? = null,
    val searchType: SearchType,
    val filters: SearchFilters,
    val isDefault: Boolean = false,
    val createdBy: UUID,
    val createdAt: LocalDateTime
)

/**
 * 검색 인덱스 상태 DTO
 */
data class SearchIndexStatus(
    val indexName: String,
    val documentCount: Long,
    val indexSize: String,
    val lastUpdated: LocalDateTime,
    val status: IndexStatus,
    val errorMessage: String? = null
)

/**
 * 인덱스 상태 열거형
 */
enum class IndexStatus {
    HEALTHY,        // 정상
    UPDATING,       // 업데이트 중
    ERROR,          // 오류
    REBUILDING      // 재구축 중
}