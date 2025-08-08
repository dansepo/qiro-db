package com.qiro.domain.cost.repository

import com.qiro.domain.cost.dto.BudgetStatus
import com.qiro.domain.cost.entity.BudgetManagement
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
 * 예산 관리 Repository
 */
@Repository
interface BudgetManagementRepository : JpaRepository<BudgetManagement, UUID> {

    /**
     * 회사별 예산 조회
     */
    fun findByCompanyIdOrderByBudgetYearDescBudgetNameAsc(companyId: UUID, pageable: Pageable): Page<BudgetManagement>

    /**
     * 연도별 예산 조회
     */
    fun findByCompanyIdAndBudgetYearOrderByBudgetNameAsc(
        companyId: UUID,
        budgetYear: Int,
        pageable: Pageable
    ): Page<BudgetManagement>

    /**
     * 카테고리별 예산 조회
     */
    fun findByCompanyIdAndBudgetCategoryOrderByBudgetYearDescBudgetNameAsc(
        companyId: UUID,
        budgetCategory: String,
        pageable: Pageable
    ): Page<BudgetManagement>

    /**
     * 상태별 예산 조회
     */
    fun findByCompanyIdAndBudgetStatusOrderByBudgetYearDescBudgetNameAsc(
        companyId: UUID,
        budgetStatus: BudgetStatus,
        pageable: Pageable
    ): Page<BudgetManagement>

    /**
     * 활성 예산 조회
     */
    fun findByCompanyIdAndBudgetStatusAndStartDateLessThanEqualAndEndDateGreaterThanEqualOrderByBudgetNameAsc(
        companyId: UUID,
        budgetStatus: BudgetStatus,
        startDate: LocalDate,
        endDate: LocalDate,
        pageable: Pageable
    ): Page<BudgetManagement>

    /**
     * 특정 카테고리와 연도의 예산 조회
     */
    fun findByCompanyIdAndBudgetCategoryAndBudgetYear(
        companyId: UUID,
        budgetCategory: String,
        budgetYear: Int
    ): BudgetManagement?

    /**
     * 예산 이름 중복 확인
     */
    fun existsByCompanyIdAndBudgetNameAndBudgetYear(
        companyId: UUID,
        budgetName: String,
        budgetYear: Int
    ): Boolean

    /**
     * 경고 수준 이상의 예산 조회
     */
    @Query("""
        SELECT bm FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        AND bm.budgetStatus = 'ACTIVE'
        AND (bm.spentAmount / bm.allocatedAmount * 100) >= bm.warningThreshold
        ORDER BY (bm.spentAmount / bm.allocatedAmount * 100) DESC
    """)
    fun findBudgetsWithWarningLevel(@Param("companyId") companyId: UUID): List<BudgetManagement>

    /**
     * 위험 수준 이상의 예산 조회
     */
    @Query("""
        SELECT bm FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        AND bm.budgetStatus = 'ACTIVE'
        AND (bm.spentAmount / bm.allocatedAmount * 100) >= bm.criticalThreshold
        ORDER BY (bm.spentAmount / bm.allocatedAmount * 100) DESC
    """)
    fun findBudgetsWithCriticalLevel(@Param("companyId") companyId: UUID): List<BudgetManagement>

    /**
     * 만료 예정 예산 조회
     */
    @Query("""
        SELECT bm FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        AND bm.budgetStatus = 'ACTIVE'
        AND bm.endDate BETWEEN :startDate AND :endDate
        ORDER BY bm.endDate ASC
    """)
    fun findBudgetsExpiringBetween(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<BudgetManagement>

    /**
     * 예산 사용률별 조회
     */
    @Query("""
        SELECT bm FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        AND bm.budgetStatus = 'ACTIVE'
        AND (bm.spentAmount / bm.allocatedAmount * 100) BETWEEN :minUtilization AND :maxUtilization
        ORDER BY (bm.spentAmount / bm.allocatedAmount * 100) DESC
    """)
    fun findBudgetsByUtilizationRange(
        @Param("companyId") companyId: UUID,
        @Param("minUtilization") minUtilization: BigDecimal,
        @Param("maxUtilization") maxUtilization: BigDecimal
    ): List<BudgetManagement>

    /**
     * 연도별 총 예산 조회
     */
    @Query("""
        SELECT 
            bm.budgetYear,
            SUM(bm.allocatedAmount) as totalAllocated,
            SUM(bm.spentAmount) as totalSpent,
            SUM(bm.availableAmount) as totalAvailable
        FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        GROUP BY bm.budgetYear
        ORDER BY bm.budgetYear DESC
    """)
    fun getYearlyBudgetSummary(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 카테고리별 예산 통계 조회
     */
    @Query("""
        SELECT 
            bm.budgetCategory,
            COUNT(bm) as budgetCount,
            SUM(bm.allocatedAmount) as totalAllocated,
            SUM(bm.spentAmount) as totalSpent,
            AVG(bm.spentAmount / bm.allocatedAmount * 100) as avgUtilization
        FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId 
        AND bm.budgetYear = :budgetYear
        GROUP BY bm.budgetCategory
        ORDER BY SUM(bm.allocatedAmount) DESC
    """)
    fun getBudgetStatisticsByCategory(
        @Param("companyId") companyId: UUID,
        @Param("budgetYear") budgetYear: Int
    ): List<Array<Any>>

    /**
     * 복합 조건 검색
     */
    @Query("""
        SELECT bm FROM BudgetManagement bm 
        WHERE bm.companyId = :companyId
        AND (:budgetYear IS NULL OR bm.budgetYear = :budgetYear)
        AND (:budgetCategory IS NULL OR bm.budgetCategory = :budgetCategory)
        AND (:budgetStatus IS NULL OR bm.budgetStatus = :budgetStatus)
        AND (:minUtilization IS NULL OR (bm.spentAmount / bm.allocatedAmount * 100) >= :minUtilization)
        AND (:maxUtilization IS NULL OR (bm.spentAmount / bm.allocatedAmount * 100) <= :maxUtilization)
        ORDER BY bm.budgetYear DESC, bm.budgetName ASC
    """)
    fun findByComplexFilter(
        @Param("companyId") companyId: UUID,
        @Param("budgetYear") budgetYear: Int?,
        @Param("budgetCategory") budgetCategory: String?,
        @Param("budgetStatus") budgetStatus: BudgetStatus?,
        @Param("minUtilization") minUtilization: BigDecimal?,
        @Param("maxUtilization") maxUtilization: BigDecimal?,
        pageable: Pageable
    ): Page<BudgetManagement>
}