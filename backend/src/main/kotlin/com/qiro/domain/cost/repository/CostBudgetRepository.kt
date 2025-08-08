package com.qiro.domain.cost.repository

import com.qiro.domain.cost.entity.CostBudget
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
 * 비용 예산 Repository
 */
@Repository
interface CostBudgetRepository : JpaRepository<CostBudget, UUID> {
    
    /**
     * 회사별 예산 조회
     */
    fun findByCompanyCompanyIdOrderByCreatedAtDesc(companyId: UUID, pageable: Pageable): Page<CostBudget>
    
    /**
     * 예산 코드로 조회
     */
    fun findByCompanyCompanyIdAndBudgetCode(companyId: UUID, budgetCode: String): CostBudget?
    
    /**
     * 예산 분류별 조회
     */
    fun findByCompanyCompanyIdAndBudgetCategoryOrderByCreatedAtDesc(
        companyId: UUID, 
        budgetCategory: CostBudget.BudgetCategory,
        pageable: Pageable
    ): Page<CostBudget>
    
    /**
     * 예산 상태별 조회
     */
    fun findByCompanyCompanyIdAndBudgetStatusOrderByCreatedAtDesc(
        companyId: UUID, 
        budgetStatus: CostBudget.BudgetStatus,
        pageable: Pageable
    ): Page<CostBudget>
    
    /**
     * 활성 예산 조회
     */
    fun findByCompanyCompanyIdAndBudgetStatusAndStartDateLessThanEqualAndEndDateGreaterThanEqual(
        companyId: UUID,
        budgetStatus: CostBudget.BudgetStatus,
        currentDate1: LocalDate,
        currentDate2: LocalDate
    ): List<CostBudget>
    
    /**
     * 회계연도별 예산 조회
     */
    fun findByCompanyCompanyIdAndFiscalYearOrderByCreatedAtDesc(
        companyId: UUID, 
        fiscalYear: Int,
        pageable: Pageable
    ): Page<CostBudget>
    
    /**
     * 예산 기간별 조회
     */
    fun findByCompanyCompanyIdAndBudgetPeriodOrderByCreatedAtDesc(
        companyId: UUID, 
        budgetPeriod: CostBudget.BudgetPeriod,
        pageable: Pageable
    ): Page<CostBudget>
    
    /**
     * 예산 소유자별 조회
     */
    fun findByCompanyCompanyIdAndBudgetOwnerUserIdOrderByCreatedAtDesc(
        companyId: UUID, 
        ownerId: UUID,
        pageable: Pageable
    ): Page<CostBudget>
    
    /**
     * 검토 필요한 예산 조회
     */
    fun findByCompanyCompanyIdAndNextReviewDateLessThanEqualAndBudgetStatus(
        companyId: UUID,
        reviewDate: LocalDate,
        budgetStatus: CostBudget.BudgetStatus
    ): List<CostBudget>
    
    /**
     * 경고 임계값 초과 예산 조회
     */
    @Query("""
        SELECT b FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
        AND b.utilizationRate >= b.alertThreshold
        ORDER BY b.utilizationRate DESC
    """)
    fun findBudgetsExceedingAlertThreshold(@Param("companyId") companyId: UUID): List<CostBudget>
    
    /**
     * 위험 임계값 초과 예산 조회
     */
    @Query("""
        SELECT b FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
        AND b.utilizationRate >= b.criticalThreshold
        ORDER BY b.utilizationRate DESC
    """)
    fun findBudgetsExceedingCriticalThreshold(@Param("companyId") companyId: UUID): List<CostBudget>
    
    /**
     * 예산 초과 조회
     */
    @Query("""
        SELECT b FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
        AND b.spentAmount > b.plannedAmount
        ORDER BY b.variancePercentage DESC
    """)
    fun findOverBudgets(@Param("companyId") companyId: UUID): List<CostBudget>
    
    /**
     * 예산 사용률 낮은 예산 조회
     */
    @Query("""
        SELECT b FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
        AND b.utilizationRate < :threshold
        AND b.endDate > :currentDate
        ORDER BY b.utilizationRate ASC
    """)
    fun findUnderutilizedBudgets(
        @Param("companyId") companyId: UUID,
        @Param("threshold") threshold: BigDecimal,
        @Param("currentDate") currentDate: LocalDate
    ): List<CostBudget>
    
    /**
     * 예산 분류별 총 계획 금액 조회
     */
    @Query("""
        SELECT b.budgetCategory, SUM(b.plannedAmount) as totalPlanned
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
        GROUP BY b.budgetCategory
        ORDER BY totalPlanned DESC
    """)
    fun findBudgetSummaryByCategory(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): List<Array<Any>>
    
    /**
     * 예산 기간별 총 계획 금액 조회
     */
    @Query("""
        SELECT b.budgetPeriod, SUM(b.plannedAmount) as totalPlanned, SUM(b.spentAmount) as totalSpent
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
        GROUP BY b.budgetPeriod
        ORDER BY totalPlanned DESC
    """)
    fun findBudgetSummaryByPeriod(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): List<Array<Any>>
    
    /**
     * 월별 예산 실행률 조회
     */
    @Query("""
        SELECT EXTRACT(MONTH FROM b.startDate) as month,
               AVG(b.utilizationRate) as avgUtilization
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
        GROUP BY EXTRACT(MONTH FROM b.startDate)
        ORDER BY month
    """)
    fun findMonthlyUtilizationRate(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): List<Array<Any>>
    
    /**
     * 총 예산 현황 조회
     */
    @Query("""
        SELECT SUM(b.plannedAmount) as totalPlanned,
               SUM(b.allocatedAmount) as totalAllocated,
               SUM(b.committedAmount) as totalCommitted,
               SUM(b.spentAmount) as totalSpent,
               SUM(b.remainingAmount) as totalRemaining
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
    """)
    fun findTotalBudgetStatus(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): Array<Any>?
    
    /**
     * 예산 성과 지표 조회
     */
    @Query("""
        SELECT COUNT(b) as totalBudgets,
               COUNT(CASE WHEN b.utilizationRate >= b.alertThreshold THEN 1 END) as alertCount,
               COUNT(CASE WHEN b.utilizationRate >= b.criticalThreshold THEN 1 END) as criticalCount,
               COUNT(CASE WHEN b.spentAmount > b.plannedAmount THEN 1 END) as overBudgetCount,
               AVG(b.utilizationRate) as avgUtilization,
               AVG(b.variancePercentage) as avgVariance
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
    """)
    fun findBudgetPerformanceMetrics(@Param("companyId") companyId: UUID): Array<Any>?
    
    /**
     * 예산 트렌드 분석 (분기별)
     */
    @Query("""
        SELECT EXTRACT(QUARTER FROM b.startDate) as quarter,
               SUM(b.plannedAmount) as totalPlanned,
               SUM(b.spentAmount) as totalSpent,
               AVG(b.utilizationRate) as avgUtilization
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
        GROUP BY EXTRACT(QUARTER FROM b.startDate)
        ORDER BY quarter
    """)
    fun findQuarterlyBudgetTrend(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): List<Array<Any>>
    
    /**
     * 예산 소유자별 성과 조회
     */
    @Query("""
        SELECT b.budgetOwner.userId,
               COUNT(b) as budgetCount,
               SUM(b.plannedAmount) as totalPlanned,
               SUM(b.spentAmount) as totalSpent,
               AVG(b.utilizationRate) as avgUtilization
        FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.fiscalYear = :fiscalYear
        AND b.budgetStatus IN ('APPROVED', 'ACTIVE')
        AND b.budgetOwner IS NOT NULL
        GROUP BY b.budgetOwner.userId
        ORDER BY avgUtilization DESC
    """)
    fun findBudgetPerformanceByOwner(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int
    ): List<Array<Any>>
    
    /**
     * 만료 예정 예산 조회
     */
    @Query("""
        SELECT b FROM CostBudget b 
        WHERE b.company.companyId = :companyId 
        AND b.budgetStatus = 'ACTIVE'
        AND b.endDate BETWEEN :startDate AND :endDate
        ORDER BY b.endDate ASC
    """)
    fun findExpiringBudgets(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<CostBudget>
}