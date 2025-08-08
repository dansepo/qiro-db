package com.qiro.domain.cost.service

import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.entity.CostTracking
import com.qiro.domain.cost.repository.CostTrackingRepository
import com.qiro.domain.cost.repository.BudgetManagementRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * 비용 추적 서비스
 */
@Service
@Transactional
class CostTrackingService(
    private val costTrackingRepository: CostTrackingRepository,
    private val budgetManagementRepository: BudgetManagementRepository
) {

    /**
     * 비용 기록 생성
     */
    fun createCostRecord(companyId: UUID, request: CreateCostTrackingRequest, createdBy: UUID): CostTrackingDto {
        // 비용 번호 생성
        val costNumber = generateCostNumber()
        
        // 예산 연도/월 설정
        val budgetYear = request.costDate.year
        val budgetMonth = request.costDate.monthValue
        
        val costTracking = CostTracking(
            companyId = companyId,
            workOrderId = request.workOrderId,
            maintenanceId = request.maintenanceId,
            faultReportId = request.faultReportId,
            costNumber = costNumber,
            costType = request.costType,
            category = request.category,
            amount = request.amount,
            costDate = request.costDate,
            description = request.description,
            paymentMethod = request.paymentMethod,
            invoiceNumber = request.invoiceNumber,
            receiptNumber = request.receiptNumber,
            budgetCategory = request.budgetCategory ?: request.category.name,
            budgetYear = budgetYear,
            budgetMonth = budgetMonth,
            createdBy = createdBy
        )
        
        val savedCost = costTrackingRepository.save(costTracking)
        
        // 예산 사용량 업데이트 (예산이 설정된 경우)
        request.budgetCategory?.let { budgetCategory ->
            updateBudgetUsage(companyId, budgetCategory, budgetYear, request.amount)
        }
        
        return savedCost.toDto()
    }

    /**
     * 비용 기록 수정
     */
    fun updateCostRecord(
        costId: UUID, 
        request: UpdateCostTrackingRequest, 
        updatedBy: UUID
    ): CostTrackingDto {
        val costTracking = costTrackingRepository.findById(costId)
            .orElseThrow { IllegalArgumentException("비용 기록을 찾을 수 없습니다: $costId") }
        
        val updatedCost = costTracking.update(
            amount = request.amount,
            costDate = request.costDate,
            description = request.description,
            paymentMethod = request.paymentMethod,
            invoiceNumber = request.invoiceNumber,
            receiptNumber = request.receiptNumber,
            budgetCategory = request.budgetCategory,
            updatedBy = updatedBy
        )
        
        return costTrackingRepository.save(updatedCost).toDto()
    }

    /**
     * 비용 승인
     */
    fun approveCost(costId: UUID, request: ApproveCostRequest, approvedBy: UUID): CostTrackingDto {
        val costTracking = costTrackingRepository.findById(costId)
            .orElseThrow { IllegalArgumentException("비용 기록을 찾을 수 없습니다: $costId") }
        
        val approvedCost = costTracking.approve(approvedBy, request.approvalNotes)
        return costTrackingRepository.save(approvedCost).toDto()
    }

    /**
     * 비용 기록 조회
     */
    @Transactional(readOnly = true)
    fun getCostRecord(costId: UUID): CostTrackingDto {
        return costTrackingRepository.findById(costId)
            .orElseThrow { IllegalArgumentException("비용 기록을 찾을 수 없습니다: $costId") }
            .toDto()
    }

    /**
     * 회사별 비용 기록 목록 조회
     */
    @Transactional(readOnly = true)
    fun getCostRecords(companyId: UUID, pageable: Pageable): Page<CostTrackingDto> {
        return costTrackingRepository.findByCompanyIdOrderByCostDateDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 필터링된 비용 기록 조회
     */
    @Transactional(readOnly = true)
    fun getCostRecordsWithFilter(
        companyId: UUID, 
        filter: CostTrackingFilter, 
        pageable: Pageable
    ): Page<CostTrackingDto> {
        val approvalStatus = when (filter.approvalStatus) {
            ApprovalStatus.APPROVED -> "APPROVED"
            ApprovalStatus.PENDING -> "PENDING"
            ApprovalStatus.REJECTED -> "REJECTED"
            null -> "ALL"
        }
        
        return costTrackingRepository.findByComplexFilter(
            companyId = companyId,
            costType = filter.costType,
            category = filter.category,
            startDate = filter.startDate,
            endDate = filter.endDate,
            minAmount = filter.minAmount,
            maxAmount = filter.maxAmount,
            budgetCategory = filter.budgetCategory,
            budgetYear = filter.budgetYear,
            approvalStatus = approvalStatus,
            pageable = pageable
        ).map { it.toDto() }
    }

    /**
     * 비용 통계 조회
     */
    @Transactional(readOnly = true)
    fun getCostStatistics(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate,
        category: CostCategory? = null
    ): CostStatisticsDto {
        val costs = if (category != null) {
            costTrackingRepository.findByCompanyIdAndCategoryOrderByCostDateDesc(
                companyId, category, Pageable.unpaged()
            ).content.filter { it.costDate in startDate..endDate }
        } else {
            costTrackingRepository.findByCompanyIdAndCostDateBetweenOrderByCostDateDesc(
                companyId, startDate, endDate, Pageable.unpaged()
            ).content
        }
        
        val totalCost = costs.sumOf { it.amount }
        val transactionCount = costs.size.toLong()
        val averageCost = if (transactionCount > 0) totalCost.divide(BigDecimal(transactionCount), 2, BigDecimal.ROUND_HALF_UP) else BigDecimal.ZERO
        
        return CostStatisticsDto(
            totalCost = totalCost,
            transactionCount = transactionCount,
            averageCost = averageCost,
            laborCost = costs.filter { it.costType == CostType.LABOR }.sumOf { it.amount },
            materialCost = costs.filter { it.costType == CostType.MATERIAL }.sumOf { it.amount },
            equipmentCost = costs.filter { it.costType == CostType.EQUIPMENT }.sumOf { it.amount },
            contractorCost = costs.filter { it.costType == CostType.CONTRACTOR }.sumOf { it.amount },
            emergencyCost = costs.filter { it.costType == CostType.EMERGENCY }.sumOf { it.amount },
            preventiveCost = costs.filter { it.category == CostCategory.PREVENTIVE }.sumOf { it.amount },
            correctiveCost = costs.filter { it.category == CostCategory.CORRECTIVE }.sumOf { it.amount },
            upgradeCost = costs.filter { it.category == CostCategory.UPGRADE }.sumOf { it.amount }
        )
    }

    /**
     * 월별 비용 트렌드 조회
     */
    @Transactional(readOnly = true)
    fun getMonthlyCostTrend(
        companyId: UUID, 
        year: Int, 
        category: CostCategory? = null
    ): List<MonthlyCostTrendDto> {
        val results = costTrackingRepository.getMonthlyCostStatistics(companyId, year, category)
        
        return results.map { row ->
            val month = (row[0] as Number).toInt()
            val totalAmount = row[1] as BigDecimal? ?: BigDecimal.ZERO
            val transactionCount = (row[2] as Number).toLong()
            val averageAmount = row[3] as BigDecimal? ?: BigDecimal.ZERO
            
            MonthlyCostTrendDto(
                monthNumber = month,
                monthName = getMonthName(month),
                totalCost = totalAmount,
                transactionCount = transactionCount,
                averageCost = averageAmount,
                costChangePercentage = BigDecimal.ZERO // 변화율은 별도 계산 필요
            )
        }
    }

    /**
     * 비용 요약 조회
     */
    @Transactional(readOnly = true)
    fun getCostSummary(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): CostSummaryDto {
        val costs = costTrackingRepository.findByCompanyIdAndCostDateBetweenOrderByCostDateDesc(
            companyId, startDate, endDate, Pageable.unpaged()
        ).content
        
        val totalCost = costs.sumOf { it.amount }
        val transactionCount = costs.size.toLong()
        val averageCost = if (transactionCount > 0) totalCost.divide(BigDecimal(transactionCount), 2, BigDecimal.ROUND_HALF_UP) else BigDecimal.ZERO
        
        val costByType = CostType.values().associateWith { type ->
            costs.filter { it.costType == type }.sumOf { it.amount }
        }
        
        val costByCategory = CostCategory.values().associateWith { category ->
            costs.filter { it.category == category }.sumOf { it.amount }
        }
        
        val topExpenses = costs.sortedByDescending { it.amount }.take(10).map { it.toDto() }
        
        return CostSummaryDto(
            period = "${startDate} ~ ${endDate}",
            totalCost = totalCost,
            costByType = costByType,
            costByCategory = costByCategory,
            transactionCount = transactionCount,
            averageCost = averageCost,
            topExpenses = topExpenses
        )
    }

    /**
     * 작업 지시서별 비용 조회
     */
    @Transactional(readOnly = true)
    fun getCostsByWorkOrder(workOrderId: UUID): List<CostTrackingDto> {
        return costTrackingRepository.findByWorkOrderIdOrderByCostDateDesc(workOrderId)
            .map { it.toDto() }
    }

    /**
     * 정비 계획별 비용 조회
     */
    @Transactional(readOnly = true)
    fun getCostsByMaintenance(maintenanceId: UUID): List<CostTrackingDto> {
        return costTrackingRepository.findByMaintenanceIdOrderByCostDateDesc(maintenanceId)
            .map { it.toDto() }
    }

    /**
     * 고장 신고별 비용 조회
     */
    @Transactional(readOnly = true)
    fun getCostsByFaultReport(faultReportId: UUID): List<CostTrackingDto> {
        return costTrackingRepository.findByFaultReportIdOrderByCostDateDesc(faultReportId)
            .map { it.toDto() }
    }

    /**
     * 비용 기록 삭제
     */
    fun deleteCostRecord(costId: UUID) {
        val costTracking = costTrackingRepository.findById(costId)
            .orElseThrow { IllegalArgumentException("비용 기록을 찾을 수 없습니다: $costId") }
        
        // 예산 사용량 복원 (승인된 비용인 경우)
        if (costTracking.isApproved() && costTracking.budgetCategory != null) {
            updateBudgetUsage(
                costTracking.companyId, 
                costTracking.budgetCategory!!, 
                costTracking.budgetYear!!, 
                costTracking.amount.negate()
            )
        }
        
        costTrackingRepository.delete(costTracking)
    }

    /**
     * 예산 사용량 업데이트
     */
    private fun updateBudgetUsage(companyId: UUID, budgetCategory: String, budgetYear: Int, amount: BigDecimal) {
        budgetManagementRepository.findByCompanyIdAndBudgetCategoryAndBudgetYear(
            companyId, budgetCategory, budgetYear
        )?.let { budget ->
            val updatedBudget = budget.updateSpentAmount(amount)
            budgetManagementRepository.save(updatedBudget)
        }
    }

    /**
     * 비용 번호 생성
     */
    private fun generateCostNumber(): String {
        val now = LocalDateTime.now()
        val dateStr = now.format(DateTimeFormatter.ofPattern("yyyyMMdd"))
        val timeStr = now.format(DateTimeFormatter.ofPattern("HHmmss"))
        return "COST-$dateStr-$timeStr"
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
     * CostTracking 엔티티를 DTO로 변환
     */
    private fun CostTracking.toDto(): CostTrackingDto {
        return CostTrackingDto(
            costId = this.costId,
            companyId = this.companyId,
            workOrderId = this.workOrderId,
            maintenanceId = this.maintenanceId,
            faultReportId = this.faultReportId,
            costNumber = this.costNumber,
            costType = this.costType,
            category = this.category,
            amount = this.amount,
            currency = this.currency,
            costDate = this.costDate,
            description = this.description,
            paymentMethod = this.paymentMethod,
            invoiceNumber = this.invoiceNumber,
            receiptNumber = this.receiptNumber,
            approvedBy = this.approvedBy,
            approvalDate = this.approvalDate,
            approvalNotes = this.approvalNotes,
            budgetCategory = this.budgetCategory,
            budgetYear = this.budgetYear,
            budgetMonth = this.budgetMonth,
            createdAt = this.createdAt,
            createdBy = this.createdBy,
            updatedAt = this.updatedAt,
            updatedBy = this.updatedBy
        )
    }
}