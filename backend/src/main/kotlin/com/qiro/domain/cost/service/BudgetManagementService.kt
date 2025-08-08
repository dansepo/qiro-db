package com.qiro.domain.cost.service

import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.entity.BudgetManagement
import com.qiro.domain.cost.repository.BudgetManagementRepository
import com.qiro.domain.cost.repository.CostTrackingRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 예산 관리 서비스
 */
@Service
@Transactional
class BudgetManagementService(
    private val budgetManagementRepository: BudgetManagementRepository,
    private val costTrackingRepository: CostTrackingRepository
) {

    /**
     * 예산 생성
     */
    fun createBudget(companyId: UUID, request: CreateBudgetRequest, createdBy: UUID): BudgetManagementDto {
        // 중복 확인
        if (budgetManagementRepository.existsByCompanyIdAndBudgetNameAndBudgetYear(
                companyId, request.budgetName, request.budgetYear)) {
            throw IllegalArgumentException("동일한 이름과 연도의 예산이 이미 존재합니다: ${request.budgetName} (${request.budgetYear})")
        }
        
        val budget = BudgetManagement(
            companyId = companyId,
            budgetName = request.budgetName,
            budgetYear = request.budgetYear,
            budgetCategory = request.budgetCategory,
            allocatedAmount = request.allocatedAmount,
            availableAmount = request.allocatedAmount,
            startDate = request.startDate,
            endDate = request.endDate,
            warningThreshold = request.warningThreshold,
            criticalThreshold = request.criticalThreshold,
            createdBy = createdBy
        )
        
        return budgetManagementRepository.save(budget).toDto()
    }

    /**
     * 예산 수정
     */
    fun updateBudget(budgetId: UUID, request: UpdateBudgetRequest, updatedBy: UUID): BudgetManagementDto {
        val budget = budgetManagementRepository.findById(budgetId)
            .orElseThrow { IllegalArgumentException("예산을 찾을 수 없습니다: $budgetId") }
        
        val updatedBudget = budget.update(
            budgetName = request.budgetName,
            allocatedAmount = request.allocatedAmount,
            startDate = request.startDate,
            endDate = request.endDate,
            warningThreshold = request.warningThreshold,
            criticalThreshold = request.criticalThreshold,
            budgetStatus = request.budgetStatus,
            updatedBy = updatedBy
        )
        
        return budgetManagementRepository.save(updatedBudget).toDto()
    }

    /**
     * 예산 승인
     */
    fun approveBudget(budgetId: UUID, request: ApproveBudgetRequest, approvedBy: UUID): BudgetManagementDto {
        val budget = budgetManagementRepository.findById(budgetId)
            .orElseThrow { IllegalArgumentException("예산을 찾을 수 없습니다: $budgetId") }
        
        val approvedBudget = budget.approve(approvedBy)
        return budgetManagementRepository.save(approvedBudget).toDto()
    }

    /**
     * 예산 조회
     */
    @Transactional(readOnly = true)
    fun getBudget(budgetId: UUID): BudgetManagementDto {
        return budgetManagementRepository.findById(budgetId)
            .orElseThrow { IllegalArgumentException("예산을 찾을 수 없습니다: $budgetId") }
            .toDto()
    }

    /**
     * 회사별 예산 목록 조회
     */
    @Transactional(readOnly = true)
    fun getBudgets(companyId: UUID, pageable: Pageable): Page<BudgetManagementDto> {
        return budgetManagementRepository.findByCompanyIdOrderByBudgetYearDescBudgetNameAsc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 필터링된 예산 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetsWithFilter(
        companyId: UUID, 
        filter: BudgetFilter, 
        pageable: Pageable
    ): Page<BudgetManagementDto> {
        return budgetManagementRepository.findByComplexFilter(
            companyId = companyId,
            budgetYear = filter.budgetYear,
            budgetCategory = filter.budgetCategory,
            budgetStatus = filter.budgetStatus,
            minUtilization = filter.minUtilization,
            maxUtilization = filter.maxUtilization,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 예산 상태 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetStatus(companyId: UUID, budgetCategory: String, budgetYear: Int): BudgetStatusDto? {
        return budgetManagementRepository.findByCompanyIdAndBudgetCategoryAndBudgetYear(
            companyId, budgetCategory, budgetYear
        )?.toBudgetStatusDto()
    }

    /**
     * 모든 예산 상태 조회
     */
    @Transactional(readOnly = true)
    fun getAllBudgetStatus(companyId: UUID, budgetYear: Int): List<BudgetStatusDto> {
        return budgetManagementRepository.findByCompanyIdAndBudgetYearOrderByBudgetNameAsc(
            companyId, budgetYear, Pageable.unpaged()
        ).content.map { it.toBudgetStatusDto() }
    }

    /**
     * 예산 경고 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetAlerts(companyId: UUID): List<BudgetAlertDto> {
        val warningBudgets = budgetManagementRepository.findBudgetsWithWarningLevel(companyId)
        val expiringBudgets = budgetManagementRepository.findBudgetsExpiringBetween(
            companyId, LocalDate.now(), LocalDate.now().plusDays(30)
        )
        
        val allAlerts = (warningBudgets + expiringBudgets).distinctBy { it.budgetId }
        
        return allAlerts.map { budget ->
            val utilizationPercentage = budget.getUtilizationPercentage()
            val daysRemaining = (budget.endDate.toEpochDay() - LocalDate.now().toEpochDay()).toInt()
            
            BudgetAlertDto(
                budgetId = budget.budgetId,
                budgetName = budget.budgetName,
                budgetCategory = budget.budgetCategory,
                utilizationPercentage = utilizationPercentage,
                alertLevel = when {
                    utilizationPercentage >= budget.criticalThreshold -> AlertLevel.CRITICAL
                    utilizationPercentage >= budget.warningThreshold -> AlertLevel.WARNING
                    else -> AlertLevel.NORMAL
                },
                remainingAmount = budget.availableAmount,
                daysRemaining = daysRemaining
            )
        }.sortedWith(
            compareBy<BudgetAlertDto> { 
                when (it.alertLevel) {
                    AlertLevel.CRITICAL -> 1
                    AlertLevel.WARNING -> 2
                    AlertLevel.NORMAL -> 3
                }
            }.thenBy { it.budgetName }
        )
    }

    /**
     * 예산 분석
     */
    @Transactional(readOnly = true)
    fun getBudgetAnalysis(budgetId: UUID): BudgetAnalysisDto {
        val budget = budgetManagementRepository.findById(budgetId)
            .orElseThrow { IllegalArgumentException("예산을 찾을 수 없습니다: $budgetId") }
        
        // 월별 지출 데이터
        val monthlySpending = getMonthlySpending(budget)
        
        // 상위 지출 카테고리
        val topExpenseCategories = getTopExpenseCategories(budget)
        
        // 연말 예상 지출 계산
        val projectedYearEndSpending = calculateProjectedSpending(budget, monthlySpending)
        
        // 예산 차이
        val budgetVariance = budget.allocatedAmount - budget.spentAmount
        
        // 권장사항 생성
        val recommendations = generateRecommendations(budget, monthlySpending)
        
        return BudgetAnalysisDto(
            budgetId = budget.budgetId,
            budgetName = budget.budgetName,
            budgetCategory = budget.budgetCategory,
            allocatedAmount = budget.allocatedAmount,
            spentAmount = budget.spentAmount,
            utilizationPercentage = budget.getUtilizationPercentage(),
            monthlySpending = monthlySpending,
            topExpenseCategories = topExpenseCategories,
            projectedYearEndSpending = projectedYearEndSpending,
            budgetVariance = budgetVariance,
            recommendations = recommendations
        )
    }

    /**
     * 예산 삭제
     */
    fun deleteBudget(budgetId: UUID) {
        val budget = budgetManagementRepository.findById(budgetId)
            .orElseThrow { IllegalArgumentException("예산을 찾을 수 없습니다: $budgetId") }
        
        // 사용된 예산이 있는 경우 삭제 불가
        if (budget.spentAmount > BigDecimal.ZERO) {
            throw IllegalStateException("사용된 예산은 삭제할 수 없습니다")
        }
        
        budgetManagementRepository.delete(budget)
    }

    /**
     * 월별 지출 데이터 조회
     */
    private fun getMonthlySpending(budget: BudgetManagement): List<MonthlySpendingDto> {
        val results = costTrackingRepository.getMonthlyCostStatistics(
            budget.companyId, budget.budgetYear, null
        )
        
        return (1..12).map { month ->
            val monthData = results.find { (it[0] as Number).toInt() == month }
            MonthlySpendingDto(
                month = month,
                monthName = getMonthName(month),
                amount = monthData?.get(1) as BigDecimal? ?: BigDecimal.ZERO,
                transactionCount = monthData?.get(2) as Long? ?: 0L
            )
        }
    }

    /**
     * 상위 지출 카테고리 조회
     */
    private fun getTopExpenseCategories(budget: BudgetManagement): List<ExpenseCategoryDto> {
        val categoryStats = costTrackingRepository.getCostStatisticsByCategory(
            budget.companyId, budget.startDate, budget.endDate
        )
        
        val totalAmount = categoryStats.sumOf { it[1] as BigDecimal }
        
        return categoryStats.map { row ->
            val category = row[0] as String
            val amount = row[1] as BigDecimal
            val transactionCount = (row[2] as Number).toLong()
            val percentage = if (totalAmount > BigDecimal.ZERO) {
                amount.divide(totalAmount, 4, BigDecimal.ROUND_HALF_UP).multiply(BigDecimal("100"))
            } else BigDecimal.ZERO
            
            ExpenseCategoryDto(
                category = category,
                amount = amount,
                percentage = percentage,
                transactionCount = transactionCount
            )
        }.sortedByDescending { it.amount }
    }

    /**
     * 연말 예상 지출 계산
     */
    private fun calculateProjectedSpending(
        budget: BudgetManagement, 
        monthlySpending: List<MonthlySpendingDto>
    ): BigDecimal {
        val currentMonth = LocalDate.now().monthValue
        val spentSoFar = monthlySpending.take(currentMonth).sumOf { it.amount }
        val averageMonthlySpending = if (currentMonth > 0) {
            spentSoFar.divide(BigDecimal(currentMonth), 2, BigDecimal.ROUND_HALF_UP)
        } else BigDecimal.ZERO
        
        val remainingMonths = 12 - currentMonth
        return spentSoFar + (averageMonthlySpending * BigDecimal(remainingMonths))
    }

    /**
     * 권장사항 생성
     */
    private fun generateRecommendations(
        budget: BudgetManagement, 
        monthlySpending: List<MonthlySpendingDto>
    ): List<String> {
        val recommendations = mutableListOf<String>()
        val utilizationPercentage = budget.getUtilizationPercentage()
        
        when {
            utilizationPercentage >= budget.criticalThreshold -> {
                recommendations.add("예산 사용률이 위험 수준입니다. 즉시 지출을 제한하세요.")
                recommendations.add("불필요한 지출을 검토하고 우선순위를 재조정하세요.")
            }
            utilizationPercentage >= budget.warningThreshold -> {
                recommendations.add("예산 사용률이 경고 수준입니다. 지출을 모니터링하세요.")
                recommendations.add("남은 기간 동안의 지출 계획을 재검토하세요.")
            }
            else -> {
                recommendations.add("예산 사용률이 정상 범위입니다.")
            }
        }
        
        // 월별 지출 패턴 분석
        val recentMonths = monthlySpending.takeLast(3).filter { it.amount > BigDecimal.ZERO }
        if (recentMonths.size >= 2) {
            val trend = recentMonths.last().amount.compareTo(recentMonths.first().amount)
            when {
                trend > 0 -> recommendations.add("최근 지출이 증가 추세입니다. 원인을 분석해보세요.")
                trend < 0 -> recommendations.add("최근 지출이 감소 추세입니다. 좋은 경향입니다.")
            }
        }
        
        return recommendations
    }

    /**
     * 월 이름 반환
     */
    private fun getMonthName(month: Int): String {
        return when (month) {
            1 -> "1월"
            2 -> "2월"
            3 -> "3월"
            4 -> "4월"
            5 -> "5월"
            6 -> "6월"
            7 -> "7월"
            8 -> "8월"
            9 -> "9월"
            10 -> "10월"
            11 -> "11월"
            12 -> "12월"
            else -> "${month}월"
        }
    }

    /**
     * BudgetManagement 엔티티를 DTO로 변환
     */
    private fun BudgetManagement.toDto(): BudgetManagementDto {
        return BudgetManagementDto(
            budgetId = this.budgetId,
            companyId = this.companyId,
            budgetName = this.budgetName,
            budgetYear = this.budgetYear,
            budgetCategory = this.budgetCategory,
            allocatedAmount = this.allocatedAmount,
            spentAmount = this.spentAmount,
            committedAmount = this.committedAmount,
            availableAmount = this.availableAmount,
            startDate = this.startDate,
            endDate = this.endDate,
            budgetStatus = this.budgetStatus,
            warningThreshold = this.warningThreshold,
            criticalThreshold = this.criticalThreshold,
            approvedBy = this.approvedBy,
            approvalDate = this.approvalDate,
            createdAt = this.createdAt,
            createdBy = this.createdBy,
            updatedAt = this.updatedAt,
            updatedBy = this.updatedBy
        )
    }

    /**
     * BudgetManagement 엔티티를 BudgetStatusDto로 변환
     */
    private fun BudgetManagement.toBudgetStatusDto(): BudgetStatusDto {
        return BudgetStatusDto(
            budgetId = this.budgetId,
            companyId = this.companyId,
            budgetName = this.budgetName,
            budgetYear = this.budgetYear,
            budgetCategory = this.budgetCategory,
            allocatedAmount = this.allocatedAmount,
            spentAmount = this.spentAmount,
            committedAmount = this.committedAmount,
            availableAmount = this.availableAmount,
            utilizationPercentage = this.getUtilizationPercentage(),
            commitmentPercentage = this.getCommitmentPercentage(),
            statusLevel = when (this.getStatusLevel()) {
                "CRITICAL" -> BudgetStatusLevel.CRITICAL
                "WARNING" -> BudgetStatusLevel.WARNING
                else -> BudgetStatusLevel.NORMAL
            },
            remainingBudget = this.availableAmount,
            startDate = this.startDate,
            endDate = this.endDate,
            periodStatus = when (this.getPeriodStatus()) {
                "FUTURE" -> PeriodStatus.FUTURE
                "EXPIRED" -> PeriodStatus.EXPIRED
                else -> PeriodStatus.ACTIVE
            }
        )
    }
}