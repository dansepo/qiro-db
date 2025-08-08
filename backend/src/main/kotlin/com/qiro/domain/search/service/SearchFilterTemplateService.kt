package com.qiro.domain.search.service

import com.qiro.domain.search.dto.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 검색 필터 템플릿 서비스
 */
@Service
@Transactional
class SearchFilterTemplateService {

    // 실제 구현에서는 SearchFilterTemplateRepository 사용
    private val filterTemplates = mutableMapOf<UUID, SearchFilterTemplate>()

    init {
        // 기본 필터 템플릿 초기화
        initializeDefaultTemplates()
    }

    /**
     * 필터 템플릿 생성
     */
    fun createFilterTemplate(
        companyId: UUID,
        name: String,
        description: String?,
        searchType: SearchType,
        filters: SearchFilters,
        createdBy: UUID
    ): SearchFilterTemplate {
        val templateId = UUID.randomUUID()
        val template = SearchFilterTemplate(
            templateId = templateId,
            name = name,
            description = description,
            searchType = searchType,
            filters = filters,
            isDefault = false,
            createdBy = createdBy,
            createdAt = LocalDateTime.now()
        )
        
        filterTemplates[templateId] = template
        return template
    }

    /**
     * 필터 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getFilterTemplate(templateId: UUID): SearchFilterTemplate {
        return filterTemplates[templateId]
            ?: throw IllegalArgumentException("필터 템플릿을 찾을 수 없습니다: $templateId")
    }

    /**
     * 검색 타입별 필터 템플릿 목록 조회
     */
    @Transactional(readOnly = true)
    fun getFilterTemplatesBySearchType(searchType: SearchType): List<SearchFilterTemplate> {
        return filterTemplates.values
            .filter { it.searchType == searchType }
            .sortedWith(compareByDescending<SearchFilterTemplate> { it.isDefault }.thenBy { it.name })
    }

    /**
     * 모든 필터 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getAllFilterTemplates(): List<SearchFilterTemplate> {
        return filterTemplates.values
            .sortedWith(compareBy<SearchFilterTemplate> { it.searchType }.thenByDescending { it.isDefault }.thenBy { it.name })
    }

    /**
     * 기본 필터 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getDefaultFilterTemplates(): List<SearchFilterTemplate> {
        return filterTemplates.values
            .filter { it.isDefault }
            .sortedBy { it.searchType }
    }

    /**
     * 필터 템플릿 수정
     */
    fun updateFilterTemplate(
        templateId: UUID,
        name: String?,
        description: String?,
        filters: SearchFilters?,
        updatedBy: UUID
    ): SearchFilterTemplate {
        val existingTemplate = getFilterTemplate(templateId)
        
        if (existingTemplate.isDefault) {
            throw IllegalArgumentException("기본 템플릿은 수정할 수 없습니다")
        }
        
        val updatedTemplate = existingTemplate.copy(
            name = name ?: existingTemplate.name,
            description = description ?: existingTemplate.description,
            filters = filters ?: existingTemplate.filters
        )
        
        filterTemplates[templateId] = updatedTemplate
        return updatedTemplate
    }

    /**
     * 필터 템플릿 삭제
     */
    fun deleteFilterTemplate(templateId: UUID, deletedBy: UUID) {
        val template = getFilterTemplate(templateId)
        
        if (template.isDefault) {
            throw IllegalArgumentException("기본 템플릿은 삭제할 수 없습니다")
        }
        
        if (template.createdBy != deletedBy) {
            throw IllegalArgumentException("권한이 없습니다")
        }
        
        filterTemplates.remove(templateId)
    }

    /**
     * 필터 적용
     */
    fun applyFilterTemplate(templateId: UUID, baseRequest: UnifiedSearchRequest): UnifiedSearchRequest {
        val template = getFilterTemplate(templateId)
        
        return baseRequest.copy(
            filters = mergeFilters(baseRequest.filters, template.filters),
            searchTypes = if (baseRequest.searchTypes.isEmpty()) listOf(template.searchType) else baseRequest.searchTypes
        )
    }

    /**
     * 스마트 필터 제안
     */
    @Transactional(readOnly = true)
    fun suggestFilters(
        companyId: UUID,
        searchType: SearchType,
        query: String,
        currentFilters: SearchFilters
    ): List<SearchFilterSuggestion> {
        val suggestions = mutableListOf<SearchFilterSuggestion>()
        
        // 검색어 기반 필터 제안
        when (searchType) {
            SearchType.FAULT_REPORT -> {
                if (query.contains("긴급", ignoreCase = true)) {
                    suggestions.add(SearchFilterSuggestion(
                        filterType = "priority",
                        filterValue = "URGENT",
                        description = "긴급 우선순위로 필터링",
                        confidence = 0.9
                    ))
                }
                if (query.contains("완료", ignoreCase = true)) {
                    suggestions.add(SearchFilterSuggestion(
                        filterType = "status",
                        filterValue = "COMPLETED",
                        description = "완료된 신고로 필터링",
                        confidence = 0.8
                    ))
                }
            }
            SearchType.WORK_ORDER -> {
                if (query.contains("정비", ignoreCase = true) || query.contains("점검", ignoreCase = true)) {
                    suggestions.add(SearchFilterSuggestion(
                        filterType = "category",
                        filterValue = "MAINTENANCE",
                        description = "정비 작업으로 필터링",
                        confidence = 0.85
                    ))
                }
            }
            SearchType.FACILITY_ASSET -> {
                if (query.contains("엘리베이터", ignoreCase = true)) {
                    suggestions.add(SearchFilterSuggestion(
                        filterType = "category",
                        filterValue = "ELEVATOR",
                        description = "엘리베이터 자산으로 필터링",
                        confidence = 0.95
                    ))
                }
            }
            else -> {
                // 다른 검색 타입에 대한 제안 로직
            }
        }
        
        // 날짜 기반 제안
        if (currentFilters.dateRange == null) {
            suggestions.add(SearchFilterSuggestion(
                filterType = "dateRange",
                filterValue = "LAST_30_DAYS",
                description = "최근 30일로 필터링",
                confidence = 0.6
            ))
        }
        
        return suggestions.sortedByDescending { it.confidence }
    }

    /**
     * 필터 병합
     */
    private fun mergeFilters(baseFilters: SearchFilters, templateFilters: SearchFilters): SearchFilters {
        return SearchFilters(
            dateRange = baseFilters.dateRange ?: templateFilters.dateRange,
            status = if (baseFilters.status.isNotEmpty()) baseFilters.status else templateFilters.status,
            priority = if (baseFilters.priority.isNotEmpty()) baseFilters.priority else templateFilters.priority,
            category = if (baseFilters.category.isNotEmpty()) baseFilters.category else templateFilters.category,
            location = baseFilters.location ?: templateFilters.location,
            assignedTo = baseFilters.assignedTo ?: templateFilters.assignedTo,
            createdBy = baseFilters.createdBy ?: templateFilters.createdBy,
            amountRange = baseFilters.amountRange ?: templateFilters.amountRange,
            tags = (baseFilters.tags + templateFilters.tags).distinct(),
            customFields = baseFilters.customFields + templateFilters.customFields
        )
    }

    /**
     * 기본 필터 템플릿 초기화
     */
    private fun initializeDefaultTemplates() {
        val systemUserId = UUID.fromString("00000000-0000-0000-0000-000000000000")
        
        // 고장 신고 기본 템플릿
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "긴급 고장 신고",
            description = "긴급 우선순위의 고장 신고만 조회",
            searchType = SearchType.FAULT_REPORT,
            filters = SearchFilters(
                priority = listOf("URGENT"),
                status = listOf("REPORTED", "ASSIGNED", "IN_PROGRESS")
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "최근 완료된 고장 신고",
            description = "최근 7일간 완료된 고장 신고",
            searchType = SearchType.FAULT_REPORT,
            filters = SearchFilters(
                status = listOf("COMPLETED", "VERIFIED"),
                dateRange = DateRangeFilter(
                    startDate = LocalDate.now().minusDays(7),
                    endDate = LocalDate.now(),
                    dateField = "actualCompletion"
                )
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        // 작업 지시서 기본 템플릿
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "진행 중인 작업",
            description = "현재 진행 중인 작업 지시서",
            searchType = SearchType.WORK_ORDER,
            filters = SearchFilters(
                status = listOf("ASSIGNED", "IN_PROGRESS")
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "지연된 작업",
            description = "예정일을 초과한 작업 지시서",
            searchType = SearchType.WORK_ORDER,
            filters = SearchFilters(
                status = listOf("ASSIGNED", "IN_PROGRESS"),
                dateRange = DateRangeFilter(
                    startDate = LocalDate.of(2020, 1, 1),
                    endDate = LocalDate.now().minusDays(1),
                    dateField = "scheduledEnd"
                )
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        // 시설물 자산 기본 템플릿
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "보증 만료 예정 자산",
            description = "30일 내 보증이 만료되는 자산",
            searchType = SearchType.FACILITY_ASSET,
            filters = SearchFilters(
                dateRange = DateRangeFilter(
                    startDate = LocalDate.now(),
                    endDate = LocalDate.now().plusDays(30),
                    dateField = "warrantyExpiry"
                )
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        // 비용 추적 기본 템플릿
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "고액 비용",
            description = "100만원 이상의 비용 기록",
            searchType = SearchType.COST_TRACKING,
            filters = SearchFilters(
                amountRange = AmountRangeFilter(
                    minAmount = BigDecimal("1000000"),
                    maxAmount = BigDecimal("999999999")
                )
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
        
        filterTemplates[UUID.randomUUID()] = SearchFilterTemplate(
            templateId = UUID.randomUUID(),
            name = "승인 대기 비용",
            description = "승인 대기 중인 비용 기록",
            searchType = SearchType.COST_TRACKING,
            filters = SearchFilters(
                status = listOf("PENDING")
            ),
            isDefault = true,
            createdBy = systemUserId,
            createdAt = LocalDateTime.now()
        )
    }
}

/**
 * 검색 필터 제안 DTO
 */
data class SearchFilterSuggestion(
    val filterType: String,
    val filterValue: String,
    val description: String,
    val confidence: Double
)