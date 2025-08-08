package com.qiro.domain.cost.dto

import com.qiro.domain.cost.entity.CostBudget
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 예산 DTO
 */
data class CostBudgetDto(
    val budgetId: UUID,
    val companyId: UUID,
    val budgetCode: String,
    val budgetName: String,
    val description: String? = null,
    val budgetCategory: CostBudget.BudgetCategory,
    val budgetPeriod: CostBudget.BudgetPeriod,
    val fiscalYear: Int,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val plannedAmount: BigDecimal,
    val allocatedAmount: BigDecimal,
    val committedAmount: BigDecimal,
    val spentAmount: BigDecimal,
    val remainingAmount: BigDecimal,
    val utilizationRate: BigDecimal,
    val varianceAmount: BigDecimal,
    val variancePercentage: BigDecimal,
    val budgetStatus: CostBudget.BudgetStatus,
    val alertThreshold: BigDecimal,
    val criticalThreshold: BigDecimal,
    val autoApprovalLimit: BigDecimal,
    val budgetOwnerId: UUID? = null,
    val budgetOwnerName: String? = null,
    val approvedBy: UUID? = null,
    val approvedByName: String? = null,
    val approvalDate: LocalDateTime? = null,
    val approvalNotes: String? = null,
    val lastReviewDate: LocalDate? = null,
    val nextReviewDate: LocalDate? = null,
    val reviewFrequency: String,
    val notes: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID? = null,
    val updatedBy: UUID? = null
) {
    companion object {
        fun from(entity: CostBudget): CostBudgetDto {
            return CostBudgetDto(
                budgetId = entity.budgetId,
                companyId = entity.company.companyId,
                budgetCode = entity.budgetCode,
                budgetName = entity.budgetName,
                description = entity.description,
                budgetCategory = entity.budgetCategory,
                budgetPeriod = entity.budgetPeriod,
                fiscalYear = entity.fiscalYear,
                startDate = entity.startDate,
                endDate = entity.endDate,
                plannedAmount = entity.plannedAmount,
                allocatedAmount = entity.allocatedAmount,
                committedAmount = entity.committedAmount,
                spentAmount = entity.spentAmount,
                remainingAmount = entity.remainingAmount,
                utilizationRate = entity.utilizationRate,
                varianceAmount = entity.varianceAmount,
                variancePercentage = entity.variancePercentage,
                budgetStatus = entity.budgetStatus,
                alertThreshold = entity.alertThreshold,
                criticalThreshold = entity.criticalThreshold,
                autoApprovalLimit = entity.autoApprovalLimit,
                budgetOwnerId = entity.budgetOwner?.userId,
                approvedBy = entity.approvedBy?.userId,
                approvalDate = entity.approvalDate,
                approvalNotes = entity.approvalNotes,
                lastReviewDate = entity.lastReviewDate,
                nextReviewDate = entity.nextReviewDate,
                reviewFrequency = entity.reviewFrequency,
                notes = entity.notes,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                createdBy = entity.createdBy,
                updatedBy = entity.updatedBy
            )
        }
    }
}

/**
 * 예산 생성 요청 DTO
 */
data class CreateCostBudgetRequest(
    val budgetCode: String,
    val budgetName: String,
    val description: String? = null,
    val budgetCategory: CostBudget.BudgetCategory,
    val budgetPeriod: CostBudget.BudgetPeriod,
    val fiscalYear: Int = LocalDate.now().year,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val plannedAmount: BigDecimal,
    val alertThreshold: BigDecimal = BigDecimal.valueOf(80),
    val criticalThreshold: BigDecimal = BigDecimal.valueOf(95),
    val autoApprovalLimit: BigDecimal = BigDecimal.ZERO,
    val budgetOwnerId: UUID? = null,
    val reviewFrequency: String = "MONTHLY",
    val notes: String? = null
)

/**
 * 예산 업데이트 요청 DTO
 */
data class UpdateCostBudgetRequest(
    val budgetName: String? = null,
    val description: String? = null,
    val budgetCategory: CostBudget.BudgetCategory? = null,
    val budgetPeriod: CostBudget.BudgetPeriod? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val plannedAmount: BigDecimal? = null,
    val alertThreshold: BigDecimal? = null,
    val criticalThreshold: BigDecimal? = null,
    val autoApprovalLimit: BigDecimal? = null,
    val budgetOwnerId: UUID? = null,
    val reviewFrequency: String? = null,
    val notes: String? = null
)

/**
 * 예산 승인 요청 DTO
 */
data class ApproveBudgetRequest(
    val approvalNotes: String? = null
)

/**
 * 예산 할당 요청 DTO
 */
data class AllocateBudgetRequest(
    val amount: BigDecimal,
    val description: String? = null,
    val projectCode: String? = null
)

/**
 * 예산 사용 요청 DTO
 */
data class SpendBudgetRequest(
    val amount: BigDecimal,
    val costTrackingId: UUID,
    val description: String? = null
)

/**
 * 예산 약정 요청 DTO
 */
data class CommitBudgetRequest(
    val amount: BigDecimal,
    val description: String? = null,
    val expectedDate: LocalDate? = null
)

/**
 * 예산 상태 DTO
 */
data class BudgetStatusDto(
    val totalPlanned: BigDecimal,
    val totalAllocated: BigDecimal,
    val totalCommitted: BigDecimal,
    val totalSpent: BigDecimal,
    val totalRemaining: BigDecimal,
    val overallUtilizationRate: BigDecimal,
    val budgetCount: Long,
    val activeBudgetCount: Long,
    val alertCount: Long,
    val criticalCount: Long,
    val overBudgetCount: Long
)

/**
 * 예산 분류별 요약 DTO
 */
data class BudgetSummaryByCategoryDto(
    val budgetCategory: CostBudget.BudgetCategory,
    val totalPlanned: BigDecimal,
    val totalSpent: BigDecimal,
    val utilizationRate: BigDecimal,
    val budgetCount: Long,
    val overBudgetCount: Long
)

/**
 * 예산 기간별 요약 DTO
 */
data class BudgetSummaryByPeriodDto(
    val budgetPeriod: CostBudget.BudgetPeriod,
    val totalPlanned: BigDecimal,
    val totalSpent: BigDecimal,
    val utilizationRate: BigDecimal,
    val budgetCount: Long
)

/**
 * 예산 성과 지표 DTO
 */
data class BudgetPerformanceDto(
    val totalBudgets: Long,
    val alertCount: Long,
    val criticalCount: Long,
    val overBudgetCount: Long,
    val averageUtilization: BigDecimal,
    val averageVariance: BigDecimal,
    val onTimeCompletionRate: BigDecimal,
    val budgetAccuracyRate: BigDecimal
)

/**
 * 분기별 예산 추세 DTO
 */
data class QuarterlyBudgetTrendDto(
    val quarter: Int,
    val totalPlanned: BigDecimal,
    val totalSpent: BigDecimal,
    val averageUtilization: BigDecimal,
    val budgetCount: Long
)

/**
 * 예산 소유자별 성과 DTO
 */
data class BudgetPerformanceByOwnerDto(
    val ownerId: UUID,
    val ownerName: String? = null,
    val budgetCount: Long,
    val totalPlanned: BigDecimal,
    val totalSpent: BigDecimal,
    val averageUtilization: BigDecimal,
    val overBudgetCount: Long,
    val onTimeCompletionRate: BigDecimal
)

/**
 * 예산 필터 DTO
 */
data class BudgetFilterDto(
    val budgetCategories: List<CostBudget.BudgetCategory>? = null,
    val budgetPeriods: List<CostBudget.BudgetPeriod>? = null,
    val budgetStatuses: List<CostBudget.BudgetStatus>? = null,
    val fiscalYear: Int? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val budgetOwnerId: UUID? = null,
    val minPlannedAmount: BigDecimal? = null,
    val maxPlannedAmount: BigDecimal? = null,
    val minUtilizationRate: BigDecimal? = null,
    val maxUtilizationRate: BigDecimal? = null,
    val alertThresholdExceeded: Boolean? = null,
    val criticalThresholdExceeded: Boolean? = null,
    val overBudget: Boolean? = null
)

/**
 * 예산 대시보드 DTO
 */
data class BudgetDashboardDto(
    val budgetStatus: BudgetStatusDto,
    val budgetsByCategory: List<BudgetSummaryByCategoryDto>,
    val budgetsByPeriod: List<BudgetSummaryByPeriodDto>,
    val quarterlyTrend: List<QuarterlyBudgetTrendDto>,
    val performanceMetrics: BudgetPerformanceDto,
    val alertingBudgets: List<CostBudgetDto>,
    val criticalBudgets: List<CostBudgetDto>,
    val overBudgets: List<CostBudgetDto>,
    val expiringBudgets: List<CostBudgetDto>,
    val topPerformers: List<BudgetPerformanceByOwnerDto>,
    val dashboardDate: LocalDateTime = LocalDateTime.now()
)