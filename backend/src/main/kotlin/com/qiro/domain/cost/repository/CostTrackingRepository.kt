package com.qiro.domain.cost.repository

import com.qiro.domain.cost.dto.CostCategory
import com.qiro.domain.cost.dto.CostType
import com.qiro.domain.cost.entity.CostTracking
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 비용 추적 Repository
 */
@Repository
interface CostTrackingRepository : JpaRepository<CostTracking, UUID> {

    /**
     * 회사별 비용 기록 조회
     */
    fun findByCompanyIdOrderByCostDateDesc(companyId: UUID, pageable: Pageable): Page<CostTracking>

    /**
     * 작업 지시서별 비용 기록 조회
     */
    fun findByWorkOrderIdOrderByCostDateDesc(workOrderId: UUID): List<CostTracking>

    /**
     * 정비 계획별 비용 기록 조회
     */
    fun findByMaintenanceIdOrderByCostDateDesc(maintenanceId: UUID): List<CostTracking>

    /**
     * 고장 신고별 비용 기록 조회
     */
    fun findByFaultReportIdOrderByCostDateDesc(faultReportId: UUID): List<CostTracking>

    /**
     * 비용 유형별 조회
     */
    fun findByCompanyIdAndCostTypeOrderByCostDateDesc(
        companyId: UUID,
        costType: CostType,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 비용 카테고리별 조회
     */
    fun findByCompanyIdAndCategoryOrderByCostDateDesc(
        companyId: UUID,
        category: CostCategory,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 기간별 비용 기록 조회
     */
    fun findByCompanyIdAndCostDateBetweenOrderByCostDateDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 금액 범위별 조회
     */
    fun findByCompanyIdAndAmountBetweenOrderByCostDateDesc(
        companyId: UUID,
        minAmount: BigDecimal,
        maxAmount: BigDecimal,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 승인 대기 중인 비용 기록 조회
     */
    fun findByCompanyIdAndApprovedByIsNullOrderByCostDateDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 승인된 비용 기록 조회
     */
    fun findByCompanyIdAndApprovedByIsNotNullOrderByCostDateDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<CostTracking>

    /**
     * 예산 카테고리별 연도별 총 비용 조회
     */
    @Query("""
        SELECT SUM(ct.amount) 
        FROM CostTracking ct 
        WHERE ct.companyId = :companyId 
        AND ct.budgetCategory = :budgetCategory 
        AND ct.budgetYear = :budgetYear
    """)
    fun getTotalCostByBudgetCategoryAndYear(
        @Param("companyId") companyId: UUID,
        @Param("budgetCategory") budgetCategory: String,
        @Param("budgetYear") budgetYear: Int
    ): BigDecimal?

    /**
     * 월별 비용 통계 조회
     */
    @Query("""
        SELECT 
            EXTRACT(MONTH FROM ct.costDate) as month,
            SUM(ct.amount) as totalAmount,
            COUNT(ct) as transactionCount,
            AVG(ct.amount) as averageAmount
        FROM CostTracking ct 
        WHERE ct.companyId = :companyId 
        AND EXTRACT(YEAR FROM ct.costDate) = :year
        AND (:category IS NULL OR ct.category = :category)
        GROUP BY EXTRACT(MONTH FROM ct.costDate)
        ORDER BY EXTRACT(MONTH FROM ct.costDate)
    """)
    fun getMonthlyCostStatistics(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int,
        @Param("category") category: CostCategory?
    ): List<Array<Any>>

    /**
     * 비용 유형별 통계 조회
     */
    @Query("""
        SELECT 
            ct.costType,
            SUM(ct.amount) as totalAmount,
            COUNT(ct) as transactionCount
        FROM CostTracking ct 
        WHERE ct.companyId = :companyId 
        AND ct.costDate BETWEEN :startDate AND :endDate
        GROUP BY ct.costType
        ORDER BY SUM(ct.amount) DESC
    """)
    fun getCostStatisticsByType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 비용 카테고리별 통계 조회
     */
    @Query("""
        SELECT 
            ct.category,
            SUM(ct.amount) as totalAmount,
            COUNT(ct) as transactionCount
        FROM CostTracking ct 
        WHERE ct.companyId = :companyId 
        AND ct.costDate BETWEEN :startDate AND :endDate
        GROUP BY ct.category
        ORDER BY SUM(ct.amount) DESC
    """)
    fun getCostStatisticsByCategory(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 상위 비용 항목 조회
     */
    fun findTop10ByCompanyIdAndCostDateBetweenOrderByAmountDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<CostTracking>

    /**
     * 비용 번호 중복 확인
     */
    fun existsByCompanyIdAndCostNumber(companyId: UUID, costNumber: String): Boolean

    /**
     * 복합 조건 검색
     */
    @Query("""
        SELECT ct FROM CostTracking ct 
        WHERE ct.companyId = :companyId
        AND (:costType IS NULL OR ct.costType = :costType)
        AND (:category IS NULL OR ct.category = :category)
        AND (:startDate IS NULL OR ct.costDate >= :startDate)
        AND (:endDate IS NULL OR ct.costDate <= :endDate)
        AND (:minAmount IS NULL OR ct.amount >= :minAmount)
        AND (:maxAmount IS NULL OR ct.amount <= :maxAmount)
        AND (:budgetCategory IS NULL OR ct.budgetCategory = :budgetCategory)
        AND (:budgetYear IS NULL OR ct.budgetYear = :budgetYear)
        AND (:approvalStatus = 'ALL' OR 
             (:approvalStatus = 'APPROVED' AND ct.approvedBy IS NOT NULL) OR
             (:approvalStatus = 'PENDING' AND ct.approvedBy IS NULL))
        ORDER BY ct.costDate DESC
    """)
    fun findByComplexFilter(
        @Param("companyId") companyId: UUID,
        @Param("costType") costType: CostType?,
        @Param("category") category: CostCategory?,
        @Param("startDate") startDate: LocalDate?,
        @Param("endDate") endDate: LocalDate?,
        @Param("minAmount") minAmount: BigDecimal?,
        @Param("maxAmount") maxAmount: BigDecimal?,
        @Param("budgetCategory") budgetCategory: String?,
        @Param("budgetYear") budgetYear: Int?,
        @Param("approvalStatus") approvalStatus: String,
        pageable: Pageable
    ): Page<CostTracking>
}