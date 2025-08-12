package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.ExpenseRecord
import com.qiro.domain.accounting.entity.ApprovalStatus
import com.qiro.domain.accounting.entity.ExpenseStatus
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
 * 지출 기록 Repository
 */
@Repository
interface ExpenseRecordRepository : JpaRepository<ExpenseRecord, UUID> {

    /**
     * 회사별 지출 기록 조회 (페이징)
     */
    fun findByCompanyIdOrderByExpenseDateDesc(companyId: UUID, pageable: Pageable): Page<ExpenseRecord>

    /**
     * 기간별 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        ORDER BY er.expenseDate DESC
    """)
    fun findByDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<ExpenseRecord>

    /**
     * 상태별 지출 기록 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: ExpenseStatus): List<ExpenseRecord>

    /**
     * 승인 상태별 지출 기록 조회
     */
    fun findByCompanyIdAndApprovalStatus(
        companyId: UUID, 
        approvalStatus: ApprovalStatus
    ): List<ExpenseRecord>

    /**
     * 승인 대기 중인 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.approvalStatus = 'PENDING' 
        ORDER BY er.createdAt ASC
    """)
    fun findPendingApprovalExpenses(@Param("companyId") companyId: UUID): List<ExpenseRecord>

    /**
     * 건물별 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.buildingId = :buildingId 
        ORDER BY er.expenseDate DESC
    """)
    fun findByBuilding(
        @Param("companyId") companyId: UUID,
        @Param("buildingId") buildingId: UUID
    ): List<ExpenseRecord>

    /**
     * 세대별 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.unitId = :unitId 
        ORDER BY er.expenseDate DESC
    """)
    fun findByUnit(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: UUID
    ): List<ExpenseRecord>

    /**
     * 업체별 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.vendor.vendorId = :vendorId 
        ORDER BY er.expenseDate DESC
    """)
    fun findByVendor(
        @Param("companyId") companyId: UUID,
        @Param("vendorId") vendorId: UUID
    ): List<ExpenseRecord>

    /**
     * 지출 유형별 기간 집계
     */
    @Query("""
        SELECT er.expenseType.typeCode, SUM(er.totalAmount) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        AND er.status = 'PAID'
        GROUP BY er.expenseType.typeCode
    """)
    fun getExpenseByTypeAndPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 카테고리별 기간 집계
     */
    @Query("""
        SELECT er.expenseType.category, SUM(er.totalAmount) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        AND er.status = 'PAID'
        GROUP BY er.expenseType.category
    """)
    fun getExpenseByCategoryAndPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 월별 지출 집계
     */
    @Query("""
        SELECT EXTRACT(YEAR FROM er.expenseDate), EXTRACT(MONTH FROM er.expenseDate), SUM(er.totalAmount) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        AND er.status = 'PAID'
        GROUP BY EXTRACT(YEAR FROM er.expenseDate), EXTRACT(MONTH FROM er.expenseDate)
        ORDER BY EXTRACT(YEAR FROM er.expenseDate), EXTRACT(MONTH FROM er.expenseDate)
    """)
    fun getMonthlyExpenseTotal(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 총 지출 금액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(er.totalAmount), 0) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        AND er.status = 'PAID'
    """)
    fun getTotalExpenseAmount(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 승인 대기 중인 지출 총액
     */
    @Query("""
        SELECT COALESCE(SUM(er.totalAmount), 0) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.approvalStatus = 'PENDING'
    """)
    fun getPendingApprovalAmount(@Param("companyId") companyId: UUID): BigDecimal

    /**
     * 참조 번호로 지출 기록 조회
     */
    fun findByCompanyIdAndReferenceNumber(companyId: UUID, referenceNumber: String): ExpenseRecord?

    /**
     * 송장 번호로 지출 기록 조회
     */
    fun findByCompanyIdAndInvoiceNumber(companyId: UUID, invoiceNumber: String): ExpenseRecord?

    /**
     * 분개 전표 연결되지 않은 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.status = 'PAID' 
        AND er.journalEntryId IS NULL
    """)
    fun findUnlinkedExpenseRecords(@Param("companyId") companyId: UUID): List<ExpenseRecord>

    /**
     * 업체별 지출 통계
     */
    @Query("""
        SELECT er.vendor.vendorName, COUNT(er), SUM(er.totalAmount) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate 
        AND er.status = 'PAID'
        AND er.vendor IS NOT NULL
        GROUP BY er.vendor.vendorName
        ORDER BY SUM(er.totalAmount) DESC
    """)
    fun getVendorExpenseStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    // Service에서 필요한 추가 메서드들
    
    /**
     * 필터 조건에 따른 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND (:startDate IS NULL OR er.expenseDate >= :startDate)
        AND (:endDate IS NULL OR er.expenseDate <= :endDate)
        AND (:expenseTypeId IS NULL OR er.expenseType.id = :expenseTypeId)
        AND (:vendorId IS NULL OR er.vendor.id = :vendorId)
        AND (:status IS NULL OR er.status = :status)
        ORDER BY er.expenseDate DESC
    """)
    fun findByCompanyIdAndFilters(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate?,
        @Param("endDate") endDate: LocalDate?,
        @Param("expenseTypeId") expenseTypeId: UUID?,
        @Param("vendorId") vendorId: UUID?,
        @Param("status") status: ExpenseStatus?
    ): List<ExpenseRecord>

    /**
     * 기간별 총 지출 금액 조회
     */
    @Query("""
        SELECT COALESCE(SUM(er.amount), 0) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate
    """)
    fun getTotalExpenseByPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 기간별 지출 건수 조회
     */
    @Query("""
        SELECT COUNT(er) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate
    """)
    fun getExpenseCountByPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Int

    /**
     * 기간별 및 유형별 총 지출 금액 조회
     */
    @Query("""
        SELECT COALESCE(SUM(er.amount), 0) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate
        AND er.expenseType.id = :expenseTypeId
    """)
    fun getTotalExpenseByPeriodAndType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        @Param("expenseTypeId") expenseTypeId: UUID
    ): BigDecimal

    /**
     * 기간별 및 유형별 지출 건수 조회
     */
    @Query("""
        SELECT COUNT(er) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.expenseDate BETWEEN :startDate AND :endDate
        AND er.expenseType.id = :expenseTypeId
    """)
    fun getExpenseCountByPeriodAndType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        @Param("expenseTypeId") expenseTypeId: UUID
    ): Int

    /**
     * 승인 상태별 지출 건수 조회
     */
    @Query("""
        SELECT COUNT(er) 
        FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        AND er.approvalStatus = :approvalStatus
    """)
    fun countByCompanyIdAndApprovalStatus(
        @Param("companyId") companyId: UUID,
        @Param("approvalStatus") approvalStatus: ApprovalStatus
    ): Int

    /**
     * 최근 지출 기록 조회
     */
    @Query("""
        SELECT er FROM ExpenseRecord er 
        WHERE er.companyId = :companyId 
        ORDER BY er.createdAt DESC
        LIMIT :limit
    """)
    fun findRecentExpenses(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int
    ): List<ExpenseRecord>

    /**
     * 회사별 지출 기록 조회 (기본)
     */
    fun findByCompanyId(companyId: UUID): List<ExpenseRecord>
}