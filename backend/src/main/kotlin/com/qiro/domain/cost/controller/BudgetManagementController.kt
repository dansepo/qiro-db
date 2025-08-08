package com.qiro.domain.cost.controller

import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.service.BudgetManagementService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.util.*

/**
 * 예산 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/budgets")
@Tag(name = "Budget Management", description = "예산 관리 API")
class BudgetManagementController(
    private val budgetManagementService: BudgetManagementService
) {

    @Operation(summary = "예산 생성", description = "새로운 예산을 생성합니다")
    @PostMapping
    fun createBudget(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateBudgetRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<BudgetManagementDto> {
        val result = budgetManagementService.createBudget(companyId, request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "예산 수정", description = "기존 예산을 수정합니다")
    @PutMapping("/{budgetId}")
    fun updateBudget(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 ID") @PathVariable budgetId: UUID,
        @RequestBody request: UpdateBudgetRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<BudgetManagementDto> {
        val result = budgetManagementService.updateBudget(budgetId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 승인", description = "예산을 승인합니다")
    @PostMapping("/{budgetId}/approve")
    fun approveBudget(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 ID") @PathVariable budgetId: UUID,
        @RequestBody request: ApproveBudgetRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<BudgetManagementDto> {
        val result = budgetManagementService.approveBudget(budgetId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 조회", description = "특정 예산을 조회합니다")
    @GetMapping("/{budgetId}")
    fun getBudget(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 ID") @PathVariable budgetId: UUID
    ): ResponseEntity<BudgetManagementDto> {
        val result = budgetManagementService.getBudget(budgetId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 목록 조회", description = "회사의 모든 예산을 조회합니다")
    @GetMapping
    fun getBudgets(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<BudgetManagementDto>> {
        val result = budgetManagementService.getBudgets(companyId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "필터링된 예산 조회", description = "조건에 따라 필터링된 예산을 조회합니다")
    @GetMapping("/search")
    fun getBudgetsWithFilter(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 연도") @RequestParam(required = false) budgetYear: Int?,
        @Parameter(description = "예산 카테고리") @RequestParam(required = false) budgetCategory: String?,
        @Parameter(description = "예산 상태") @RequestParam(required = false) budgetStatus: BudgetStatus?,
        @Parameter(description = "최소 사용률") @RequestParam(required = false) minUtilization: BigDecimal?,
        @Parameter(description = "최대 사용률") @RequestParam(required = false) maxUtilization: BigDecimal?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<BudgetManagementDto>> {
        val filter = BudgetFilter(
            budgetYear = budgetYear,
            budgetCategory = budgetCategory,
            budgetStatus = budgetStatus,
            minUtilization = minUtilization,
            maxUtilization = maxUtilization
        )
        val result = budgetManagementService.getBudgetsWithFilter(companyId, filter, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 상태 조회", description = "특정 카테고리와 연도의 예산 상태를 조회합니다")
    @GetMapping("/status")
    fun getBudgetStatus(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 카테고리") @RequestParam budgetCategory: String,
        @Parameter(description = "예산 연도") @RequestParam budgetYear: Int
    ): ResponseEntity<BudgetStatusDto?> {
        val result = budgetManagementService.getBudgetStatus(companyId, budgetCategory, budgetYear)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모든 예산 상태 조회", description = "특정 연도의 모든 예산 상태를 조회합니다")
    @GetMapping("/status/all")
    fun getAllBudgetStatus(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 연도") @RequestParam budgetYear: Int
    ): ResponseEntity<List<BudgetStatusDto>> {
        val result = budgetManagementService.getAllBudgetStatus(companyId, budgetYear)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 경고 조회", description = "경고 수준 이상의 예산들을 조회합니다")
    @GetMapping("/alerts")
    fun getBudgetAlerts(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<List<BudgetAlertDto>> {
        val result = budgetManagementService.getBudgetAlerts(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 분석", description = "예산의 상세 분석 정보를 조회합니다")
    @GetMapping("/{budgetId}/analysis")
    fun getBudgetAnalysis(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 ID") @PathVariable budgetId: UUID
    ): ResponseEntity<BudgetAnalysisDto> {
        val result = budgetManagementService.getBudgetAnalysis(budgetId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "예산 삭제", description = "예산을 삭제합니다")
    @DeleteMapping("/{budgetId}")
    fun deleteBudget(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "예산 ID") @PathVariable budgetId: UUID
    ): ResponseEntity<Void> {
        budgetManagementService.deleteBudget(budgetId)
        return ResponseEntity.noContent().build()
    }
}