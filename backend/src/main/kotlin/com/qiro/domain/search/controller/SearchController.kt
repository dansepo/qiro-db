package com.qiro.domain.search.controller

import com.qiro.domain.search.dto.*
import com.qiro.domain.search.service.*
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 통합 검색 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/search")
@Tag(name = "Unified Search", description = "통합 검색 API")
class SearchController(
    private val unifiedSearchService: UnifiedSearchService,
    private val savedSearchService: SavedSearchService,
    private val searchFilterTemplateService: SearchFilterTemplateService,
    private val searchStatisticsService: SearchStatisticsService
) {

    @Operation(summary = "통합 검색", description = "모든 엔티티를 대상으로 통합 검색을 수행합니다")
    @PostMapping
    fun search(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: UnifiedSearchRequest,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<UnifiedSearchResponse> {
        val startTime = System.currentTimeMillis()
        val result = unifiedSearchService.search(companyId, request, pageable)
        val responseTime = System.currentTimeMillis() - startTime
        
        // 검색 로그 기록
        searchStatisticsService.logSearch(
            companyId = companyId,
            userId = userId,
            query = request.query,
            searchTypes = request.searchTypes,
            resultCount = result.totalResults,
            responseTime = responseTime
        )
        
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "고급 검색", description = "복잡한 조건을 사용한 고급 검색을 수행합니다")
    @PostMapping("/advanced")
    fun advancedSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: AdvancedSearchRequest,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<UnifiedSearchResponse> {
        val result = unifiedSearchService.advancedSearch(companyId, request, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "자동완성", description = "검색어 자동완성 제안을 제공합니다")
    @PostMapping("/autocomplete")
    fun autocomplete(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: AutocompleteRequest
    ): ResponseEntity<AutocompleteResponse> {
        val result = unifiedSearchService.autocomplete(companyId, request)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "빠른 검색", description = "자주 사용되는 검색어로 빠른 검색을 수행합니다")
    @GetMapping("/quick")
    fun quickSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "검색어") @RequestParam query: String,
        @Parameter(description = "검색 타입") @RequestParam(required = false) searchType: SearchType?,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 10) pageable: Pageable
    ): ResponseEntity<UnifiedSearchResponse> {
        val searchTypes = if (searchType != null) listOf(searchType) else SearchType.values().toList()
        val request = UnifiedSearchRequest(
            query = query,
            searchTypes = searchTypes
        )
        
        val result = unifiedSearchService.search(companyId, request, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "검색 제안", description = "검색어 기반 제안을 제공합니다")
    @GetMapping("/suggestions")
    fun getSearchSuggestions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "검색어") @RequestParam query: String,
        @Parameter(description = "제안 개수") @RequestParam(defaultValue = "5") limit: Int
    ): ResponseEntity<List<String>> {
        // 실제 구현에서는 검색 로그 분석을 통한 제안 생성
        val suggestions = listOf(
            "엘리베이터 고장",
            "조명 교체",
            "정기 점검",
            "응급 수리",
            "보일러 정비"
        ).filter { it.contains(query, ignoreCase = true) }.take(limit)
        
        return ResponseEntity.ok(suggestions)
    }
}

/**
 * 저장된 검색 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/search/saved")
@Tag(name = "Saved Search", description = "저장된 검색 API")
class SavedSearchController(
    private val savedSearchService: SavedSearchService,
    private val unifiedSearchService: UnifiedSearchService
) {

    @Operation(summary = "검색 저장", description = "현재 검색 조건을 저장합니다")
    @PostMapping
    fun saveSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateSavedSearchRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<SavedSearchDto> {
        val result = savedSearchService.saveSearch(companyId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "저장된 검색 수정", description = "저장된 검색을 수정합니다")
    @PutMapping("/{searchId}")
    fun updateSavedSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "저장된 검색 ID") @PathVariable searchId: UUID,
        @RequestBody request: CreateSavedSearchRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<SavedSearchDto> {
        val result = savedSearchService.updateSavedSearch(searchId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "저장된 검색 조회", description = "특정 저장된 검색을 조회합니다")
    @GetMapping("/{searchId}")
    fun getSavedSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "저장된 검색 ID") @PathVariable searchId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<SavedSearchDto> {
        val result = savedSearchService.getSavedSearch(searchId, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "내 저장된 검색 목록", description = "현재 사용자의 저장된 검색 목록을 조회합니다")
    @GetMapping("/my")
    fun getMySavedSearches(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<SavedSearchDto>> {
        val result = savedSearchService.getSavedSearchesByUser(userId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "공개 저장된 검색 목록", description = "공개된 저장된 검색 목록을 조회합니다")
    @GetMapping("/public")
    fun getPublicSavedSearches(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<SavedSearchDto>> {
        val result = savedSearchService.getPublicSavedSearches(pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "저장된 검색 실행", description = "저장된 검색을 실행합니다")
    @PostMapping("/{searchId}/execute")
    fun executeSavedSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "저장된 검색 ID") @PathVariable searchId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<UnifiedSearchResponse> {
        val result = savedSearchService.executeSavedSearch(
            searchId, userId, unifiedSearchService, companyId, pageable
        )
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "저장된 검색 삭제", description = "저장된 검색을 삭제합니다")
    @DeleteMapping("/{searchId}")
    fun deleteSavedSearch(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "저장된 검색 ID") @PathVariable searchId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Void> {
        savedSearchService.deleteSavedSearch(searchId, userId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "인기 저장된 검색", description = "인기 있는 저장된 검색 목록을 조회합니다")
    @GetMapping("/popular")
    fun getPopularSavedSearches(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "조회할 개수") @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<SavedSearchDto>> {
        val result = savedSearchService.getPopularSavedSearches(limit)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "최근 사용된 저장된 검색", description = "최근 사용된 저장된 검색 목록을 조회합니다")
    @GetMapping("/recent")
    fun getRecentlyUsedSavedSearches(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @Parameter(description = "조회할 개수") @RequestParam(defaultValue = "5") limit: Int
    ): ResponseEntity<List<SavedSearchDto>> {
        val result = savedSearchService.getRecentlyUsedSavedSearches(userId, limit)
        return ResponseEntity.ok(result)
    }
}

/**
 * 검색 필터 템플릿 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/search/filter-templates")
@Tag(name = "Search Filter Templates", description = "검색 필터 템플릿 API")
class SearchFilterTemplateController(
    private val searchFilterTemplateService: SearchFilterTemplateService
) {

    @Operation(summary = "필터 템플릿 생성", description = "새로운 검색 필터 템플릿을 생성합니다")
    @PostMapping
    fun createFilterTemplate(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateFilterTemplateRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<SearchFilterTemplate> {
        val result = searchFilterTemplateService.createFilterTemplate(
            companyId = companyId,
            name = request.name,
            description = request.description,
            searchType = request.searchType,
            filters = request.filters,
            createdBy = userId
        )
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "필터 템플릿 조회", description = "특정 필터 템플릿을 조회합니다")
    @GetMapping("/{templateId}")
    fun getFilterTemplate(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID
    ): ResponseEntity<SearchFilterTemplate> {
        val result = searchFilterTemplateService.getFilterTemplate(templateId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "검색 타입별 필터 템플릿 목록", description = "특정 검색 타입의 필터 템플릿 목록을 조회합니다")
    @GetMapping
    fun getFilterTemplatesBySearchType(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "검색 타입") @RequestParam searchType: SearchType
    ): ResponseEntity<List<SearchFilterTemplate>> {
        val result = searchFilterTemplateService.getFilterTemplatesBySearchType(searchType)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모든 필터 템플릿 조회", description = "모든 필터 템플릿을 조회합니다")
    @GetMapping("/all")
    fun getAllFilterTemplates(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<List<SearchFilterTemplate>> {
        val result = searchFilterTemplateService.getAllFilterTemplates()
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "기본 필터 템플릿 조회", description = "기본 필터 템플릿 목록을 조회합니다")
    @GetMapping("/default")
    fun getDefaultFilterTemplates(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<List<SearchFilterTemplate>> {
        val result = searchFilterTemplateService.getDefaultFilterTemplates()
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "필터 템플릿 적용", description = "필터 템플릿을 검색 요청에 적용합니다")
    @PostMapping("/{templateId}/apply")
    fun applyFilterTemplate(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID,
        @RequestBody baseRequest: UnifiedSearchRequest
    ): ResponseEntity<UnifiedSearchRequest> {
        val result = searchFilterTemplateService.applyFilterTemplate(templateId, baseRequest)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "스마트 필터 제안", description = "검색어와 컨텍스트를 기반으로 필터를 제안합니다")
    @PostMapping("/suggest")
    fun suggestFilters(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: FilterSuggestionRequest
    ): ResponseEntity<List<SearchFilterSuggestion>> {
        val result = searchFilterTemplateService.suggestFilters(
            companyId = companyId,
            searchType = request.searchType,
            query = request.query,
            currentFilters = request.currentFilters
        )
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "필터 템플릿 삭제", description = "필터 템플릿을 삭제합니다")
    @DeleteMapping("/{templateId}")
    fun deleteFilterTemplate(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Void> {
        searchFilterTemplateService.deleteFilterTemplate(templateId, userId)
        return ResponseEntity.noContent().build()
    }
}

/**
 * 검색 통계 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/search/statistics")
@Tag(name = "Search Statistics", description = "검색 통계 API")
class SearchStatisticsController(
    private val searchStatisticsService: SearchStatisticsService
) {

    @Operation(summary = "검색 통계 조회", description = "회사의 검색 통계를 조회합니다")
    @GetMapping
    fun getSearchStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "기간") @RequestParam(defaultValue = "MONTHLY") period: String
    ): ResponseEntity<SearchStatisticsDto> {
        val result = searchStatisticsService.getSearchStatistics(companyId, period)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자 검색 통계", description = "특정 사용자의 검색 통계를 조회합니다")
    @GetMapping("/user")
    fun getUserSearchStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        val result = searchStatisticsService.getUserSearchStatistics(companyId, userId)
        return ResponseEntity.ok(result)
    }
}

/**
 * 필터 템플릿 생성 요청 DTO
 */
data class CreateFilterTemplateRequest(
    val name: String,
    val description: String?,
    val searchType: SearchType,
    val filters: SearchFilters
)

/**
 * 필터 제안 요청 DTO
 */
data class FilterSuggestionRequest(
    val searchType: SearchType,
    val query: String,
    val currentFilters: SearchFilters
)