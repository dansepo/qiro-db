package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 예산 관리 서비스
 * 연간 예산 수립 및 월별 배정, 예산 대비 실적 실시간 계산 기능을 제공
 */
@Service
@Transactional
class BudgetManagementService(
    private val budgetPlanRepository: BudgetPlanRepository,
    private val budgetItemRepository: BudgetItemRepository,
    private val monthlyBudgetAllocationRepository: MonthlyBudgetAllocationRepository,
    private val budgetPerformanceTrackingRepository: BudgetPerformanceTrackingRepository,
    private val budgetAlertSettingRepository: BudgetAlertSettingRepository,
    private val budgetAlertHistoryRepository: BudgetAlertHistoryRepository
) {

    /**
     * 예산 계획 생성
     */
    fun createBudgetPlan(companyId: UUID, request: CreateBudgetPlanRequest, createdBy: UUID): BudgetPlanDto {
        // 동일 회계연도 예산 계획 중복 확인
        if (budgetPlanRepository.existsByCompanyIdAndFiscalYear(companyId, request.fiscalYear)) {
            throw IllegalArgumentException("${request.fiscalYear}년도 예산 계획이 이미 존재합니다")
        }

        val budgetPlan = BudgetPlan(
            companyId = companyId,
            planName = request.planName,
            fiscalYear = request.fiscalYear,
            startDate = request.startDate,
            endDate = request.endDate,
            totalBudget = request.totalBudget,
            createdBy = createdBy
        )

        val savedBudgetPlan = budgetPlanRepository.save(budgetPlan)
        return BudgetPlanDto.from(savedBudgetPlan)
    }

    /**
     * 예산 항목 생성
     */
    fun createBudgetItem(companyId: UUID, request: CreateBudgetItemRequest): BudgetItemDto {
        val budgetPlan = budgetPlanRepository.findById(request.budgetPlanId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 계획입니다: ${request.budgetPlanId}") }

        if (budgetPlan.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 계획입니다")
        }

        if (!budgetPlan.canModify()) {
            throw IllegalArgumentException("수정할 수 없는 예산 계획 상태입니다: ${budgetPlan.status}")
        }

        val budgetItem = BudgetItem(
            budgetPlan = budgetPlan,
            companyId = companyId,
            category = request.category,
            subcategory = request.subcategory,
            itemName = request.itemName,
            description = request.description,
            annualBudget = request.annualBudget,
            accountId = request.accountId
        )

        val savedBudgetItem = budgetItemRepository.save(budgetItem)
        return BudgetItemDto.from(savedBudgetItem)
    }

    /**
     * 월별 예산 배정
     */
    fun allocateMonthlyBudget(
        companyId: UUID,
        budgetItemId: UUID,
        allocations: List<MonthlyAllocationRequest>
    ): List<MonthlyBudgetAllocationDto> {
        val budgetItem = budgetItemRepository.findById(budgetItemId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 항목입니다: $budgetItemId") }

        if (budgetItem.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 항목입니다")
        }

        // 총 배정 금액 검증
        val totalAllocation = allocations.sumOf { it.allocatedAmount }
        if (totalAllocation > budgetItem.annualBudget) {
            throw IllegalArgumentException("총 배정 금액이 연간 예산을 초과합니다")
        }

        val savedAllocations = allocations.map { allocation ->
            // 기존 배정 확인 및 업데이트 또는 생성
            val existingAllocation = monthlyBudgetAllocationRepository
                .findByBudgetItemIdAndAllocationYearAndAllocationMonth(
                    budgetItemId, allocation.year, allocation.month
                )

            val monthlyAllocation = if (existingAllocation != null) {
                existingAllocation.copy(
                    allocatedAmount = allocation.allocatedAmount,
                    remainingAmount = allocation.allocatedAmount - existingAllocation.usedAmount
                )
            } else {
                MonthlyBudgetAllocation(
                    budgetItem = budgetItem,
                    companyId = companyId,
                    allocationYear = allocation.year,
                    allocationMonth = allocation.month,
                    allocatedAmount = allocation.allocatedAmount,
                    remainingAmount = allocation.allocatedAmount
                )
            }

            monthlyBudgetAllocationRepository.save(monthlyAllocation)
        }

        // 예산 항목의 총 배정 금액 업데이트
        val updatedBudgetItem = budgetItem.updateAllocatedBudget(totalAllocation)
        budgetItemRepository.save(updatedBudgetItem)

        return savedAllocations.map { MonthlyBudgetAllocationDto.from(it) }
    }

    /**
     * 예산 실적 업데이트
     */
    fun updateBudgetPerformance(
        budgetItemId: UUID,
        amount: BigDecimal,
        transactionType: BudgetPerformanceTracking.TransactionType,
        transactionId: UUID? = null,
        expenseRecordId: UUID? = null,
        incomeRecordId: UUID? = null,
        trackingDate: LocalDate = LocalDate.now(),
        description: String? = null
    ): BudgetPerformanceTrackingDto {
        val budgetItem = budgetItemRepository.findById(budgetItemId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 항목입니다: $budgetItemId") }

        // 예산 항목 사용 금액 업데이트
        val updatedBudgetItem = budgetItem.updateUsedBudget(amount)
        budgetItemRepository.save(updatedBudgetItem)

        // 월별 배정 사용 금액 업데이트
        val year = trackingDate.year
        val month = trackingDate.monthValue
        
        monthlyBudgetAllocationRepository
            .findByBudgetItemIdAndAllocationYearAndAllocationMonth(budgetItemId, year, month)
            ?.let { allocation ->
                val updatedAllocation = allocation.updateUsedAmount(amount)
                monthlyBudgetAllocationRepository.save(updatedAllocation)
            }

        // 실적 추적 기록 생성
        val performanceTracking = BudgetPerformanceTracking(
            budgetItem = budgetItem,
            companyId = budgetItem.companyId,
            transactionId = transactionId,
            expenseRecordId = expenseRecordId,
            incomeRecordId = incomeRecordId,
            trackingDate = trackingDate,
            amount = amount,
            transactionType = transactionType,
            description = description
        )

        val savedTracking = budgetPerformanceTrackingRepository.save(performanceTracking)

        // 예산 경고 확인
        checkBudgetAlerts(budgetItemId)

        return BudgetPerformanceTrackingDto.from(savedTracking)
    }

    /**
     * 예산 계획 승인
     */
    fun approveBudgetPlan(companyId: UUID, budgetPlanId: UUID, approvedBy: UUID): BudgetPlanDto {
        val budgetPlan = budgetPlanRepository.findById(budgetPlanId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 계획입니다: $budgetPlanId") }

        if (budgetPlan.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 계획입니다")
        }

        val approvedBudgetPlan = budgetPlan.approve(approvedBy)
        val savedBudgetPlan = budgetPlanRepository.save(approvedBudgetPlan)

        return BudgetPlanDto.from(savedBudgetPlan)
    }

    /**
     * 예산 계획 활성화
     */
    fun activateBudgetPlan(companyId: UUID, budgetPlanId: UUID): BudgetPlanDto {
        val budgetPlan = budgetPlanRepository.findById(budgetPlanId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 계획입니다: $budgetPlanId") }

        if (budgetPlan.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 계획입니다")
        }

        // 기존 활성 예산 계획 비활성화
        budgetPlanRepository.findByCompanyIdAndStatus(companyId, BudgetPlan.Status.ACTIVE)
            .forEach { activePlan ->
                val closedPlan = activePlan.close()
                budgetPlanRepository.save(closedPlan)
            }

        val activatedBudgetPlan = budgetPlan.activate()
        val savedBudgetPlan = budgetPlanRepository.save(activatedBudgetPlan)

        return BudgetPlanDto.from(savedBudgetPlan)
    }

    /**
     * 예산 경고 설정 생성
     */
    fun createBudgetAlertSetting(
        companyId: UUID,
        request: CreateBudgetAlertSettingRequest
    ): BudgetAlertSettingDto {
        val budgetItem = budgetItemRepository.findById(request.budgetItemId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 항목입니다: ${request.budgetItemId}") }

        if (budgetItem.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 항목입니다")
        }

        val alertSetting = BudgetAlertSetting(
            budgetItem = budgetItem,
            companyId = companyId,
            alertType = request.alertType,
            thresholdPercentage = request.thresholdPercentage,
            thresholdAmount = request.thresholdAmount,
            notificationEmails = request.notificationEmails
        )

        val savedAlertSetting = budgetAlertSettingRepository.save(alertSetting)
        return BudgetAlertSettingDto.from(savedAlertSetting)
    }

    /**
     * 예산 경고 확인
     */
    private fun checkBudgetAlerts(budgetItemId: UUID) {
        val budgetItem = budgetItemRepository.findById(budgetItemId).orElse(null) ?: return
        val usagePercentage = budgetItem.getUsagePercentage()

        val alertSettings = budgetAlertSettingRepository
            .findByBudgetItemIdAndIsEnabledTrue(budgetItemId)

        alertSettings.forEach { setting ->
            if (usagePercentage >= setting.thresholdPercentage) {
                val alertLevel = when {
                    usagePercentage >= BigDecimal(100) -> BudgetAlertHistory.AlertLevel.EMERGENCY
                    usagePercentage >= BigDecimal(90) -> BudgetAlertHistory.AlertLevel.CRITICAL
                    usagePercentage >= BigDecimal(80) -> BudgetAlertHistory.AlertLevel.WARNING
                    else -> BudgetAlertHistory.AlertLevel.INFO
                }

                val alertMessage = "예산 항목 '${budgetItem.itemName}'의 사용률이 ${usagePercentage}%에 달했습니다. " +
                        "(사용금액: ${budgetItem.usedBudget}, 예산: ${budgetItem.annualBudget})"

                val alertHistory = BudgetAlertHistory(
                    budgetItem = budgetItem,
                    companyId = budgetItem.companyId,
                    alertType = setting.alertType,
                    alertLevel = alertLevel,
                    currentUsageAmount = budgetItem.usedBudget,
                    currentUsagePercentage = usagePercentage,
                    thresholdPercentage = setting.thresholdPercentage,
                    alertMessage = alertMessage
                )

                budgetAlertHistoryRepository.save(alertHistory)
            }
        }
    }

    /**
     * 예산 현황 요약 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetSummary(companyId: UUID, fiscalYear: Int): BudgetSummaryDto {
        val budgetPlan = budgetPlanRepository.findByCompanyIdAndFiscalYear(companyId, fiscalYear)
            ?: throw IllegalArgumentException("${fiscalYear}년도 예산 계획이 존재하지 않습니다")

        val budgetItems = budgetItemRepository.findByBudgetPlanIdAndIsActiveTrue(budgetPlan.budgetPlanId)

        val totalBudget = budgetPlan.totalBudget
        val totalUsed = budgetItems.sumOf { it.usedBudget }
        val totalRemaining = totalBudget - totalUsed
        val usagePercentage = if (totalBudget > BigDecimal.ZERO) {
            totalUsed.divide(totalBudget, 4, java.math.RoundingMode.HALF_UP).multiply(BigDecimal(100))
        } else BigDecimal.ZERO

        val budgetByCategory = budgetItems.groupBy { it.category }
            .mapValues { (_, items) ->
                BudgetCategorySummaryDto(
                    category = it.key,
                    totalBudget = items.sumOf { it.annualBudget },
                    totalUsed = items.sumOf { it.usedBudget },
                    itemCount = items.size
                )
            }

        val recentAlerts = budgetAlertHistoryRepository
            .findTop10ByCompanyIdAndIsResolvedFalseOrderByCreatedAtDesc(companyId)
            .map { BudgetAlertHistoryDto.from(it) }

        return BudgetSummaryDto(
            budgetPlan = BudgetPlanDto.from(budgetPlan),
            totalBudget = totalBudget,
            totalUsed = totalUsed,
            totalRemaining = totalRemaining,
            usagePercentage = usagePercentage,
            budgetByCategory = budgetByCategory,
            recentAlerts = recentAlerts
        )
    }

    /**
     * 예산 대비 실적 분석
     */
    @Transactional(readOnly = true)
    fun getBudgetPerformanceAnalysis(
        companyId: UUID,
        budgetPlanId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): BudgetPerformanceAnalysisDto {
        val budgetPlan = budgetPlanRepository.findById(budgetPlanId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 예산 계획입니다: $budgetPlanId") }

        if (budgetPlan.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 예산 계획입니다")
        }

        val budgetItems = budgetItemRepository.findByBudgetPlanIdAndIsActiveTrue(budgetPlanId)
        
        val performanceByItem = budgetItems.map { item ->
            val trackings = budgetPerformanceTrackingRepository
                .findByBudgetItemIdAndTrackingDateBetween(item.budgetItemId, startDate, endDate)
            
            val actualAmount = trackings.sumOf { it.amount }
            val variance = actualAmount - item.annualBudget
            val variancePercentage = if (item.annualBudget > BigDecimal.ZERO) {
                variance.divide(item.annualBudget, 4, java.math.RoundingMode.HALF_UP).multiply(BigDecimal(100))
            } else BigDecimal.ZERO

            BudgetItemPerformanceDto(
                budgetItem = BudgetItemDto.from(item),
                budgetAmount = item.annualBudget,
                actualAmount = actualAmount,
                variance = variance,
                variancePercentage = variancePercentage,
                transactionCount = trackings.size.toLong()
            )
        }

        return BudgetPerformanceAnalysisDto(
            budgetPlan = BudgetPlanDto.from(budgetPlan),
            analysisStartDate = startDate,
            analysisEndDate = endDate,
            performanceByItem = performanceByItem,
            totalBudget = budgetPlan.totalBudget,
            totalActual = performanceByItem.sumOf { it.actualAmount },
            totalVariance = performanceByItem.sumOf { it.variance }
        )
    }
}