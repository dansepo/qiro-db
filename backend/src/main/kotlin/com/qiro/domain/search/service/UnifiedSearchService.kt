package com.qiro.domain.search.service

import com.qiro.domain.search.dto.*
import com.qiro.domain.fault.repository.FaultReportRepository
import com.qiro.domain.workorder.repository.WorkOrderRepository
import com.qiro.domain.facility.repository.FacilityAssetRepository
import com.qiro.domain.maintenance.repository.MaintenancePlanRepository
import com.qiro.domain.cost.repository.CostTrackingRepository
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*
import kotlin.system.measureTimeMillis

/**
 * 통합 검색 서비스
 */
@Service
@Transactional(readOnly = true)
class UnifiedSearchService(
    private val faultReportRepository: FaultReportRepository,
    private val workOrderRepository: WorkOrderRepository,
    private val facilityAssetRepository: FacilityAssetRepository,
    private val maintenancePlanRepository: MaintenancePlanRepository,
    private val costTrackingRepository: CostTrackingRepository
) {

    /**
     * 통합 검색 실행
     */
    fun search(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): UnifiedSearchResponse {
        val searchTime = measureTimeMillis {
            // 검색 실행 로직
        }
        
        val results = mutableListOf<SearchResultGroup>()
        var totalResults = 0L
        
        // 각 검색 타입별로 검색 실행
        for (searchType in request.searchTypes) {
            val searchResults = when (searchType) {
                SearchType.FAULT_REPORT -> searchFaultReports(companyId, request, pageable)
                SearchType.WORK_ORDER -> searchWorkOrders(companyId, request, pageable)
                SearchType.FACILITY_ASSET -> searchFacilityAssets(companyId, request, pageable)
                SearchType.MAINTENANCE_PLAN -> searchMaintenancePlans(companyId, request, pageable)
                SearchType.COST_TRACKING -> searchCostTracking(companyId, request, pageable)
                SearchType.USER -> searchUsers(companyId, request, pageable)
                SearchType.LOCATION -> searchLocations(companyId, request, pageable)
            }
            
            if (searchResults.items.isNotEmpty()) {
                results.add(searchResults)
                totalResults += searchResults.totalCount
            }
        }
        
        // 관련도 순으로 정렬
        val sortedResults = results.map { group ->
            group.copy(items = group.items.sortedByDescending { it.relevanceScore })
        }
        
        return UnifiedSearchResponse(
            query = request.query,
            totalResults = totalResults,
            searchTime = searchTime,
            results = sortedResults,
            suggestions = generateSuggestions(request.query),
            facets = generateFacets(companyId, request)
        )
    }

    /**
     * 고급 검색 실행
     */
    fun advancedSearch(companyId: UUID, request: AdvancedSearchRequest, pageable: Pageable): UnifiedSearchResponse {
        // 고급 검색 로직 구현
        val unifiedRequest = convertToUnifiedRequest(request)
        return search(companyId, unifiedRequest, pageable)
    }

    /**
     * 자동완성 검색
     */
    fun autocomplete(companyId: UUID, request: AutocompleteRequest): AutocompleteResponse {
        val suggestions = mutableListOf<AutocompleteSuggestion>()
        
        // 각 검색 타입별로 자동완성 제안 생성
        for (searchType in request.searchTypes) {
            val typeSuggestions = when (searchType) {
                SearchType.FAULT_REPORT -> getFaultReportSuggestions(companyId, request.query, request.limit)
                SearchType.WORK_ORDER -> getWorkOrderSuggestions(companyId, request.query, request.limit)
                SearchType.FACILITY_ASSET -> getFacilityAssetSuggestions(companyId, request.query, request.limit)
                SearchType.MAINTENANCE_PLAN -> getMaintenancePlanSuggestions(companyId, request.query, request.limit)
                SearchType.COST_TRACKING -> getCostTrackingSuggestions(companyId, request.query, request.limit)
                SearchType.USER -> getUserSuggestions(companyId, request.query, request.limit)
                SearchType.LOCATION -> getLocationSuggestions(companyId, request.query, request.limit)
            }
            suggestions.addAll(typeSuggestions)
        }
        
        // 관련도 순으로 정렬하고 제한
        val sortedSuggestions = suggestions
            .sortedByDescending { it.count }
            .take(request.limit)
        
        return AutocompleteResponse(
            query = request.query,
            suggestions = sortedSuggestions
        )
    }

    /**
     * 고장 신고 검색
     */
    private fun searchFaultReports(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        // 실제 구현에서는 전문 검색 엔진(Elasticsearch 등) 사용 권장
        val query = request.query.lowercase()
        val results = mutableListOf<SearchResultItem>()
        
        // 간단한 텍스트 매칭 검색 (실제로는 더 정교한 검색 로직 필요)
        val faultReports = faultReportRepository.findByCompanyIdOrderByReportedAtDesc(companyId, PageRequest.of(0, 50))
        
        for (report in faultReports.content) {
            val relevanceScore = calculateRelevanceScore(
                query,
                listOf(report.title, report.description, report.location, report.reportNumber)
            )
            
            if (relevanceScore > 0.0) {
                results.add(SearchResultItem(
                    id = report.reportId,
                    type = SearchType.FAULT_REPORT,
                    title = report.title,
                    description = report.description,
                    status = report.status.name,
                    priority = report.priority.name,
                    location = report.location,
                    createdAt = report.reportedAt,
                    updatedAt = report.updatedAt,
                    assignedTo = report.assignedTechnicianName,
                    relevanceScore = relevanceScore,
                    highlights = generateHighlights(query, mapOf(
                        "title" to report.title,
                        "description" to report.description
                    )),
                    metadata = mapOf(
                        "reportNumber" to report.reportNumber,
                        "estimatedCost" to (report.estimatedRepairCost ?: 0)
                    ),
                    url = "/fault-reports/${report.reportId}"
                ))
            }
        }
        
        return SearchResultGroup(
            searchType = SearchType.FAULT_REPORT,
            totalCount = results.size.toLong(),
            items = results.sortedByDescending { it.relevanceScore }
        )
    }

    /**
     * 작업 지시서 검색
     */
    private fun searchWorkOrders(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        val query = request.query.lowercase()
        val results = mutableListOf<SearchResultItem>()
        
        val workOrders = workOrderRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, PageRequest.of(0, 50))
        
        for (workOrder in workOrders.content) {
            val relevanceScore = calculateRelevanceScore(
                query,
                listOf(workOrder.title, workOrder.description, workOrder.location, workOrder.workOrderNumber)
            )
            
            if (relevanceScore > 0.0) {
                results.add(SearchResultItem(
                    id = workOrder.workOrderId,
                    type = SearchType.WORK_ORDER,
                    title = workOrder.title,
                    description = workOrder.description,
                    status = workOrder.status.name,
                    priority = workOrder.priority.name,
                    location = workOrder.location,
                    createdAt = workOrder.createdAt,
                    updatedAt = workOrder.updatedAt,
                    assignedTo = workOrder.assignedTechnicianName,
                    relevanceScore = relevanceScore,
                    highlights = generateHighlights(query, mapOf(
                        "title" to workOrder.title,
                        "description" to workOrder.description
                    )),
                    metadata = mapOf(
                        "workOrderNumber" to workOrder.workOrderNumber,
                        "workType" to workOrder.workType,
                        "estimatedCost" to (workOrder.estimatedCost ?: 0)
                    ),
                    url = "/work-orders/${workOrder.workOrderId}"
                ))
            }
        }
        
        return SearchResultGroup(
            searchType = SearchType.WORK_ORDER,
            totalCount = results.size.toLong(),
            items = results.sortedByDescending { it.relevanceScore }
        )
    }

    /**
     * 시설물 자산 검색
     */
    private fun searchFacilityAssets(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        val query = request.query.lowercase()
        val results = mutableListOf<SearchResultItem>()
        
        val assets = facilityAssetRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, PageRequest.of(0, 50))
        
        for (asset in assets.content) {
            val relevanceScore = calculateRelevanceScore(
                query,
                listOf(asset.assetName, asset.assetNumber, asset.location, asset.manufacturer, asset.modelNumber)
            )
            
            if (relevanceScore > 0.0) {
                results.add(SearchResultItem(
                    id = asset.assetId,
                    type = SearchType.FACILITY_ASSET,
                    title = asset.assetName,
                    description = "${asset.manufacturer} ${asset.modelNumber}",
                    status = asset.status.name,
                    location = asset.location,
                    createdAt = asset.createdAt,
                    updatedAt = asset.updatedAt,
                    relevanceScore = relevanceScore,
                    highlights = generateHighlights(query, mapOf(
                        "assetName" to asset.assetName,
                        "manufacturer" to (asset.manufacturer ?: ""),
                        "modelNumber" to (asset.modelNumber ?: "")
                    )),
                    metadata = mapOf(
                        "assetNumber" to asset.assetNumber,
                        "assetType" to asset.assetType,
                        "category" to asset.category,
                        "purchaseCost" to (asset.purchaseCost ?: 0)
                    ),
                    url = "/facility-assets/${asset.assetId}"
                ))
            }
        }
        
        return SearchResultGroup(
            searchType = SearchType.FACILITY_ASSET,
            totalCount = results.size.toLong(),
            items = results.sortedByDescending { it.relevanceScore }
        )
    }

    /**
     * 정비 계획 검색
     */
    private fun searchMaintenancePlans(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        val query = request.query.lowercase()
        val results = mutableListOf<SearchResultItem>()
        
        val plans = maintenancePlanRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, PageRequest.of(0, 50))
        
        for (plan in plans.content) {
            val relevanceScore = calculateRelevanceScore(
                query,
                listOf(plan.planName, plan.description, plan.maintenanceType)
            )
            
            if (relevanceScore > 0.0) {
                results.add(SearchResultItem(
                    id = plan.planId,
                    type = SearchType.MAINTENANCE_PLAN,
                    title = plan.planName,
                    description = plan.description ?: "",
                    status = plan.planStatus.name,
                    createdAt = plan.createdAt,
                    updatedAt = plan.updatedAt,
                    relevanceScore = relevanceScore,
                    highlights = generateHighlights(query, mapOf(
                        "planName" to plan.planName,
                        "description" to (plan.description ?: "")
                    )),
                    metadata = mapOf(
                        "maintenanceType" to plan.maintenanceType,
                        "frequency" to plan.frequency,
                        "estimatedCost" to plan.estimatedCost
                    ),
                    url = "/maintenance-plans/${plan.planId}"
                ))
            }
        }
        
        return SearchResultGroup(
            searchType = SearchType.MAINTENANCE_PLAN,
            totalCount = results.size.toLong(),
            items = results.sortedByDescending { it.relevanceScore }
        )
    }

    /**
     * 비용 추적 검색
     */
    private fun searchCostTracking(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        val query = request.query.lowercase()
        val results = mutableListOf<SearchResultItem>()
        
        val costs = costTrackingRepository.findByCompanyIdOrderByCostDateDesc(companyId, PageRequest.of(0, 50))
        
        for (cost in costs.content) {
            val relevanceScore = calculateRelevanceScore(
                query,
                listOf(cost.costNumber, cost.description ?: "", cost.costType.name, cost.category.name)
            )
            
            if (relevanceScore > 0.0) {
                results.add(SearchResultItem(
                    id = cost.costId,
                    type = SearchType.COST_TRACKING,
                    title = cost.costNumber,
                    description = cost.description ?: "",
                    status = if (cost.approvedBy != null) "APPROVED" else "PENDING",
                    createdAt = cost.createdAt,
                    updatedAt = cost.updatedAt,
                    relevanceScore = relevanceScore,
                    highlights = generateHighlights(query, mapOf(
                        "costNumber" to cost.costNumber,
                        "description" to (cost.description ?: "")
                    )),
                    metadata = mapOf(
                        "costType" to cost.costType.name,
                        "category" to cost.category.name,
                        "amount" to cost.amount,
                        "currency" to cost.currency
                    ),
                    url = "/costs/${cost.costId}"
                ))
            }
        }
        
        return SearchResultGroup(
            searchType = SearchType.COST_TRACKING,
            totalCount = results.size.toLong(),
            items = results.sortedByDescending { it.relevanceScore }
        )
    }

    /**
     * 사용자 검색 (모의 구현)
     */
    private fun searchUsers(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        // 실제 구현에서는 UserRepository 사용
        return SearchResultGroup(
            searchType = SearchType.USER,
            totalCount = 0,
            items = emptyList()
        )
    }

    /**
     * 위치 검색 (모의 구현)
     */
    private fun searchLocations(companyId: UUID, request: UnifiedSearchRequest, pageable: Pageable): SearchResultGroup {
        // 실제 구현에서는 LocationRepository 사용
        return SearchResultGroup(
            searchType = SearchType.LOCATION,
            totalCount = 0,
            items = emptyList()
        )
    }

    /**
     * 관련도 점수 계산
     */
    private fun calculateRelevanceScore(query: String, fields: List<String>): Double {
        var score = 0.0
        val queryTerms = query.split(" ").filter { it.isNotBlank() }
        
        for (field in fields) {
            val fieldLower = field.lowercase()
            for (term in queryTerms) {
                when {
                    fieldLower == term -> score += 10.0
                    fieldLower.contains(term) -> score += 5.0
                    fieldLower.startsWith(term) -> score += 3.0
                    fieldLower.endsWith(term) -> score += 2.0
                }
            }
        }
        
        return score
    }

    /**
     * 하이라이트 생성
     */
    private fun generateHighlights(query: String, fields: Map<String, String>): Map<String, List<String>> {
        val highlights = mutableMapOf<String, List<String>>()
        val queryTerms = query.split(" ").filter { it.isNotBlank() }
        
        for ((fieldName, fieldValue) in fields) {
            val fieldHighlights = mutableListOf<String>()
            var highlightedText = fieldValue
            
            for (term in queryTerms) {
                if (fieldValue.lowercase().contains(term.lowercase())) {
                    highlightedText = highlightedText.replace(
                        term,
                        "<mark>$term</mark>",
                        ignoreCase = true
                    )
                }
            }
            
            if (highlightedText != fieldValue) {
                fieldHighlights.add(highlightedText)
            }
            
            if (fieldHighlights.isNotEmpty()) {
                highlights[fieldName] = fieldHighlights
            }
        }
        
        return highlights
    }

    /**
     * 검색 제안 생성
     */
    private fun generateSuggestions(query: String): List<String> {
        // 실제 구현에서는 검색 로그 분석, 유사 검색어 등을 활용
        return listOf(
            "엘리베이터 고장",
            "조명 교체",
            "정기 점검",
            "응급 수리"
        ).filter { it.contains(query, ignoreCase = true) }
    }

    /**
     * 패싯 생성
     */
    private fun generateFacets(companyId: UUID, request: UnifiedSearchRequest): Map<String, List<FacetItem>> {
        // 실제 구현에서는 검색 결과를 기반으로 패싯 생성
        return mapOf(
            "status" to listOf(
                FacetItem("ACTIVE", 25),
                FacetItem("COMPLETED", 15),
                FacetItem("PENDING", 8)
            ),
            "priority" to listOf(
                FacetItem("HIGH", 12),
                FacetItem("NORMAL", 28),
                FacetItem("LOW", 8)
            ),
            "type" to listOf(
                FacetItem("FAULT_REPORT", 20),
                FacetItem("WORK_ORDER", 18),
                FacetItem("FACILITY_ASSET", 10)
            )
        )
    }

    /**
     * 고급 검색 요청을 통합 검색 요청으로 변환
     */
    private fun convertToUnifiedRequest(request: AdvancedSearchRequest): UnifiedSearchRequest {
        // 고급 검색 조건을 기본 검색 쿼리로 변환
        val queryParts = mutableListOf<String>()
        
        for (criterion in request.searchCriteria) {
            when (criterion.operator) {
                SearchOperator.CONTAINS -> queryParts.add(criterion.value.toString())
                SearchOperator.EQUALS -> queryParts.add("\"${criterion.value}\"")
                else -> queryParts.add(criterion.value.toString())
            }
        }
        
        return UnifiedSearchRequest(
            query = queryParts.joinToString(" "),
            searchTypes = request.searchTypes,
            sortBy = request.sortBy,
            sortDirection = request.sortDirection,
            includeInactive = request.includeInactive
        )
    }

    /**
     * 고장 신고 자동완성 제안
     */
    private fun getFaultReportSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        // 실제 구현에서는 데이터베이스에서 조회
        return listOf(
            AutocompleteSuggestion("엘리베이터 고장", SearchType.FAULT_REPORT, 5),
            AutocompleteSuggestion("조명 불량", SearchType.FAULT_REPORT, 3)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }

    /**
     * 작업 지시서 자동완성 제안
     */
    private fun getWorkOrderSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return listOf(
            AutocompleteSuggestion("정기 점검", SearchType.WORK_ORDER, 8),
            AutocompleteSuggestion("응급 수리", SearchType.WORK_ORDER, 4)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }

    /**
     * 시설물 자산 자동완성 제안
     */
    private fun getFacilityAssetSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return listOf(
            AutocompleteSuggestion("엘리베이터", SearchType.FACILITY_ASSET, 2),
            AutocompleteSuggestion("보일러", SearchType.FACILITY_ASSET, 1)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }

    /**
     * 정비 계획 자동완성 제안
     */
    private fun getMaintenancePlanSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return listOf(
            AutocompleteSuggestion("월간 점검", SearchType.MAINTENANCE_PLAN, 6),
            AutocompleteSuggestion("연간 정비", SearchType.MAINTENANCE_PLAN, 2)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }

    /**
     * 비용 추적 자동완성 제안
     */
    private fun getCostTrackingSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return listOf(
            AutocompleteSuggestion("부품비", SearchType.COST_TRACKING, 10),
            AutocompleteSuggestion("인건비", SearchType.COST_TRACKING, 8)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }

    /**
     * 사용자 자동완성 제안
     */
    private fun getUserSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return emptyList() // 실제 구현에서는 UserService 사용
    }

    /**
     * 위치 자동완성 제안
     */
    private fun getLocationSuggestions(companyId: UUID, query: String, limit: Int): List<AutocompleteSuggestion> {
        return listOf(
            AutocompleteSuggestion("1층 로비", SearchType.LOCATION, 15),
            AutocompleteSuggestion("지하 기계실", SearchType.LOCATION, 8)
        ).filter { it.text.contains(query, ignoreCase = true) }
    }
}