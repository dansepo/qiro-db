package com.qiro.domain.cost.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.service.CostBudgetService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*
import jakarta.validation.Valid

/**
 * 비용 예산 관리 컨트롤러
 * 시설 관리 예산 계획 및 실행을 추적하고 관리하는 REST API
 */
@Tag(name = "비용 예산 관리", description = "시설 관리 예산 계획 및 관리 API")
@RestController
@RequestMapping("/api/v1/budgets")
class CostBudgetController(
    private val costBudgetService: CostBudgetService
) {
    
    @Operation(summary = "예산 생성", description = "새로운 예산을 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createBudget(
        @Valid @RequestBody request: CreateCostBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.createBudget(request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 생성되었습니다.")
    }
    
    @Operation(summary = "예산 수정", description = "기존 예산을 수정합니다.")
    @PutMapping("/{budgetId}")
    fun updateBudget(
        @PathVariable budgetId: UUID,
        @Valid @RequestBody request: UpdateCostBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.updateBudget(budgetId, request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 수정되었습니다.")
    }
    
    @Operation(summary = "예산 승인", description = "예산을 승인합니다.")
    @PostMapping("/{budgetId}/approve")
    fun approveBudget(
        @PathVariable budgetId: UUID,
        @Valid @RequestBody request: ApproveBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.approveBudget(budgetId, request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 승인되었습니다.")
    }
    
    @Operation(summary = "예산 활성화", description = "승인된 예산을 활성화합니다.")
    @PostMapping("/{budgetId}/activate")
    fun activateBudget(
        @PathVariable budgetId: UUID,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.activateBudget(budgetId, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 활성화되었습니다.")
    }
    
    @Operation(summary = "예산 할당", description = "예산을 할당합니다.")
    @PostMapping("/{budgetId}/allocate")
    fun allocateBudget(
        @PathVariable budgetId: UUID,
        @Valid @RequestBody request: AllocateBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.allocateBudget(budgetId, request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 할당되었습니다.")
    }
    
    @Operation(summary = "예산 사용", description = "예산을 사용 처리합니다.")
    @PostMapping("/{budgetId}/spend")
    fun spendBudget(
        @PathVariable budgetId: UUID,
        @Valid @RequestBody request: SpendBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.spendBudget(budgetId, request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 사용 처리되었습니다.")
    }
    
    @Operation(summary = "예산 약정", description = "예산을 약정 처리합니다.")
    @PostMapping("/{budgetId}/commit")
    fun commitBudget(
        @PathVariable budgetId: UUID,
        @Valid @RequestBody request: CommitBudgetRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.commitBudget(budgetId, request, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 약정 처리되었습니다.")
    }
    
    @Operation(summary = "예산 조회", description = "특정 예산을 조회합니다.")
    @GetMapping("/{budgetId}")
    fun getBudget(@PathVariable budgetId: UUID): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.getBudget(budgetId)
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "예산 목록 조회", description = "예산 목록을 조회합니다.")
    @GetMapping
    fun getBudgets(
        @RequestParam(required = false) budgetCategories: List<String>?,
        @RequestParam(required = false) budgetPeriods: List<String>?,
        @RequestParam(required = false) budgetStatuses: List<String>?,
        @RequestParam(required = false) fiscalYear: Int?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @RequestParam(required = false) budgetOwnerId: UUID?,
        @RequestParam(required = false) minPlannedAmount: String?,
        @RequestParam(required = false) maxPlannedAmount: String?,
        @RequestParam(required = false) minUtilizationRate: String?,
        @RequestParam(required = false) maxUtilizationRate: String?,
        @RequestParam(required = false) alertThresholdExceeded: Boolean?,
        @RequestParam(required = false) criticalThresholdExceeded: Boolean?,
        @RequestParam(required = false) overBudget: Boolean?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<CostBudgetDto>> {
        // 필터 생성 (실제로는 별도 매퍼 클래스 사용 권장)
        val filter = if (budgetCategories != null || budgetPeriods != null || budgetStatuses != null ||
                         fiscalYear != null || startDate != null || endDate != null ||
                         budgetOwnerId != null || minPlannedAmount != null || maxPlannedAmount != null ||
                         minUtilizationRate != null || maxUtilizationRate != null ||
                         alertThresholdExceeded != null || criticalThresholdExceeded != null ||
                         overBudget != null) {
            BudgetFilterDto(
                fiscalYear = fiscalYear,
                startDate = startDate,
                endDate = endDate,
                budgetOwnerId = budgetOwnerId,
                alertThresholdExceeded = alertThresholdExceeded,
                criticalThresholdExceeded = criticalThresholdExceeded,
                overBudget = overBudget
                // 다른 필터들은 enum 변환 필요
            )
        } else null
        
        val result = costBudgetService.getBudgets(filter, pageable)
        return ApiResponse.success(PageResponse.from(result))
    }
    
    @Operation(summary = "활성 예산 조회", description = "현재 활성 상태인 예산 목록을 조회합니다.")
    @GetMapping("/active")
    fun getActiveBudgets(): ApiResponse<List<CostBudgetDto>> {
        val result = costBudgetService.getActiveBudgets()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "경고 임계값 초과 예산 조회", description = "경고 임계값을 초과한 예산 목록을 조회합니다.")
    @GetMapping("/alert-threshold-exceeded")
    fun getBudgetsExceedingAlertThreshold(): ApiResponse<List<CostBudgetDto>> {
        val result = costBudgetService.getBudgetsExceedingAlertThreshold()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "위험 임계값 초과 예산 조회", description = "위험 임계값을 초과한 예산 목록을 조회합니다.")
    @GetMapping("/critical-threshold-exceeded")
    fun getBudgetsExceedingCriticalThreshold(): ApiResponse<List<CostBudgetDto>> {
        val result = costBudgetService.getBudgetsExceedingCriticalThreshold()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "예산 초과 조회", description = "예산을 초과한 목록을 조회합니다.")
    @GetMapping("/over-budget")
    fun getOverBudgets(): ApiResponse<List<CostBudgetDto>> {
        val result = costBudgetService.getOverBudgets()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "예산 상태 요약 조회", description = "지정된 회계연도의 예산 상태 요약을 조회합니다.")
    @GetMapping("/status")
    fun getBudgetStatus(
        @RequestParam(defaultValue = "2024") fiscalYear: Int
    ): ApiResponse<BudgetStatusDto> {
        val result = costBudgetService.getBudgetStatus(fiscalYear)
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "예산 대시보드 조회", description = "지정된 회계연도의 예산 대시보드 정보를 조회합니다.")
    @GetMapping("/dashboard")
    fun getBudgetDashboard(
        @RequestParam(defaultValue = "2024") fiscalYear: Int
    ): ApiResponse<BudgetDashboardDto> {
        val result = costBudgetService.getBudgetDashboard(fiscalYear)
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "예산 종료", description = "예산을 종료합니다.")
    @PostMapping("/{budgetId}/close")
    fun closeBudget(
        @PathVariable budgetId: UUID,
        @RequestParam(required = false) reason: String?,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostBudgetDto> {
        val result = costBudgetService.closeBudget(budgetId, reason, currentUser)
        return ApiResponse.success(result, "예산이 성공적으로 종료되었습니다.")
    }
    
    @Operation(summary = "예산 삭제", description = "예산을 삭제합니다.")
    @DeleteMapping("/{budgetId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteBudget(
        @PathVariable budgetId: UUID,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<Unit> {
        costBudgetService.deleteBudget(budgetId, currentUser)
        return ApiResponse.success(Unit, "예산이 성공적으로 삭제되었습니다.")
    }
}