package com.qiro.domain.cost.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예산 관리 DTO
 */
data class BudgetManagementDto(
    val budgetId: UUID,
    val companyId: UUID,
    val budgetName: String,
    val budgetYear: Int,
    val budgetCategory: String,
    val allocatedAmount: BigDecimal,
    val spentAmount: BigDecimal,
    val committedAmount: BigDecimal,
    val availableAmount: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val budgetStatus: BudgetStatus,
    val warningThreshold: BigDecimal,
    val criticalThreshold: BigDecimal,
    val approvedBy: UUID?,
    val approvalDate: LocalDateTime?,
    val createdAt: LocalDateTime,
    val createdBy: UUID,
    val updatedAt: LocalDateTime?,
    val updatedBy: UUID?
)

/**
 * 예산 생성 요청 DTO
 */
data class CreateBudgetRequest(
    val budgetName: String,
    val budgetYear: Int,
    val budgetCategory: String,
    val allocatedAmount: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val warningThreshold: BigDecimal = BigDecimal("80.00"),
    val criticalThreshold: BigDecimal = BigDecimal("95.00")
)

/**
 * 예산 수정 요청 DTO
 */
data class UpdateBudgetRequest(
    val budgetName: String? = null,
    val allocatedAmount: BigDecimal? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val warningThreshold: BigDecimal? = null,
    val criticalThreshold: BigDecimal? = null,
    val budgetStatus: BudgetStatus? = null
)

/**
 * 예산 승인 요청 DTO
 */
data class ApproveBudgetRequest(
    val approvalNotes: String? = null
)

/**
 * 예산 상태 DTO
 */
data class BudgetStatusDto(
    val budgetId: UUID,
    val companyId: UUID,
    val budgetName: String,
    val budgetYear: Int,
    val budgetCategory: String,
    val allocatedAmount: BigDecimal,
    val spentAmount: BigDecimal,
    val committedAmount: BigDecimal,
    val availableAmount: BigDecimal,
    val utilizationPercentage: BigDecimal,
    val commitmentPercentage: BigDecimal,
    val statusLevel: BudgetStatusLevel,
    val remainingBudget: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val periodStatus: PeriodStatus
)

/**
 * 예산 경고 DTO
 */
data class BudgetAlertDto(
    val budgetId: UUID,
    val budgetName: String,
    val budgetCategory: String,
    val utilizationPercentage: BigDecimal,
    val alertLevel: AlertLevel,
    val remainingAmount: BigDecimal,
    val daysRemaining: Int
)

/**
 * 예산 분석 DTO
 */
data class BudgetAnalysisDto(
    val budgetId: UUID,
    val budgetName: String,
    val budgetCategory: String,
    val allocatedAmount: BigDecimal,
    val spentAmount: BigDecimal,
    val utilizationPercentage: BigDecimal,
    val monthlySpending: List<MonthlySpendingDto>,
    val topExpenseCategories: List<ExpenseCategoryDto>,
    val projectedYearEndSpending: BigDecimal,
    val budgetVariance: BigDecimal,
    val recommendations: List<String>
)

/**
 * 월별 지출 DTO
 */
data class MonthlySpendingDto(
    val month: Int,
    val monthName: String,
    val amount: BigDecimal,
    val transactionCount: Long
)

/**
 * 지출 카테고리 DTO
 */
data class ExpenseCategoryDto(
    val category: String,
    val amount: BigDecimal,
    val percentage: BigDecimal,
    val transactionCount: Long
)

/**
 * 예산 상태 열거형
 */
enum class BudgetStatus {
    ACTIVE,         // 활성
    SUSPENDED,      // 일시중단
    CLOSED,         // 종료
    EXCEEDED        // 초과
}

/**
 * 예산 상태 레벨 열거형
 */
enum class BudgetStatusLevel {
    NORMAL,         // 정상
    WARNING,        // 경고
    CRITICAL        // 위험
}

/**
 * 기간 상태 열거형
 */
enum class PeriodStatus {
    FUTURE,         // 미래
    ACTIVE,         // 활성
    EXPIRED         // 만료
}

/**
 * 경고 레벨 열거형
 */
enum class AlertLevel {
    NORMAL,         // 정상
    WARNING,        // 경고
    CRITICAL        // 위험
}

/**
 * 예산 필터 DTO
 */
data class BudgetFilter(
    val budgetYear: Int? = null,
    val budgetCategory: String? = null,
    val budgetStatus: BudgetStatus? = null,
    val statusLevel: BudgetStatusLevel? = null,
    val minUtilization: BigDecimal? = null,
    val maxUtilization: BigDecimal? = null
)