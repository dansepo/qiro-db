package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.Receivable
import com.qiro.domain.accounting.entity.ReceivableStatus
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
 * 미수금 Repository
 */
@Repository
interface ReceivableRepository : JpaRepository<Receivable, UUID> {

    /**
     * 회사별 미수금 조회 (페이징)
     */
    fun findByCompanyIdOrderByDueDateDesc(companyId: UUID, pageable: Pageable): Page<Receivable>

    /**
     * 상태별 미수금 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: ReceivableStatus): List<Receivable>

    /**
     * 연체된 미수금 조회
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.dueDate < :asOfDate 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
        ORDER BY r.dueDate ASC
    """)
    fun findOverdueReceivables(
        @Param("companyId") companyId: UUID,
        @Param("asOfDate") asOfDate: LocalDate = LocalDate.now()
    ): List<Receivable>

    /**
     * 임차인별 미수금 조회
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.tenantId = :tenantId 
        ORDER BY r.dueDate DESC
    """)
    fun findByTenant(
        @Param("companyId") companyId: UUID,
        @Param("tenantId") tenantId: UUID
    ): List<Receivable>

    /**
     * 건물별 미수금 조회
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.buildingId = :buildingId 
        ORDER BY r.dueDate DESC
    """)
    fun findByBuilding(
        @Param("companyId") companyId: UUID,
        @Param("buildingId") buildingId: UUID
    ): List<Receivable>

    /**
     * 세대별 미수금 조회
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.unitId = :unitId 
        ORDER BY r.dueDate DESC
    """)
    fun findByUnit(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: UUID
    ): List<Receivable>

    /**
     * 총 미수금 금액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(r.totalOutstanding), 0) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
    """)
    fun getTotalOutstandingAmount(@Param("companyId") companyId: UUID): BigDecimal

    /**
     * 연체 미수금 총액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(r.totalOutstanding), 0) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.dueDate < :asOfDate 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
    """)
    fun getTotalOverdueAmount(
        @Param("companyId") companyId: UUID,
        @Param("asOfDate") asOfDate: LocalDate = LocalDate.now()
    ): BigDecimal

    /**
     * 연체료 총액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(r.lateFeeAmount), 0) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
    """)
    fun getTotalLateFeeAmount(@Param("companyId") companyId: UUID): BigDecimal

    /**
     * 기간별 미수금 현황
     */
    @Query("""
        SELECT r.status, COUNT(r), SUM(r.totalOutstanding) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.dueDate BETWEEN :startDate AND :endDate 
        GROUP BY r.status
    """)
    fun getReceivableStatusSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 연체 일수별 미수금 분포
     */
    @Query("""
        SELECT 
            CASE 
                WHEN r.overdueDays <= 30 THEN '30일 이하'
                WHEN r.overdueDays <= 60 THEN '31-60일'
                WHEN r.overdueDays <= 90 THEN '61-90일'
                ELSE '90일 초과'
            END as period,
            COUNT(r),
            SUM(r.totalOutstanding)
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
        AND r.overdueDays > 0
        GROUP BY 
            CASE 
                WHEN r.overdueDays <= 30 THEN '30일 이하'
                WHEN r.overdueDays <= 60 THEN '31-60일'
                WHEN r.overdueDays <= 90 THEN '61-90일'
                ELSE '90일 초과'
            END
    """)
    fun getOverdueDistribution(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 수입 기록으로 미수금 조회
     */
    fun findByIncomeRecordIncomeRecordId(incomeRecordId: UUID): Receivable?

    // Service에서 필요한 추가 메서드들
    
    /**
     * 필터 조건에 따른 미수금 조회
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND (:unitId IS NULL OR r.unitId = :unitId)
        AND (:status IS NULL OR r.status = :status)
        AND (:overdueDaysMin IS NULL OR r.overdueDays >= :overdueDaysMin)
        ORDER BY r.dueDate DESC
    """)
    fun findByCompanyIdAndFilters(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: String?,
        @Param("status") status: com.qiro.domain.accounting.entity.ReceivableStatus?,
        @Param("overdueDaysMin") overdueDaysMin: Int?
    ): List<Receivable>

    /**
     * 회사별 총 미수금 조회
     */
    @Query("""
        SELECT COALESCE(SUM(r.remainingAmount), 0) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
    """)
    fun getTotalReceivablesByCompany(@Param("companyId") companyId: UUID): BigDecimal

    /**
     * 회사별 총 연체 미수금 조회
     */
    @Query("""
        SELECT COALESCE(SUM(r.remainingAmount), 0) 
        FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
        AND r.dueDate < CURRENT_DATE
    """)
    fun getTotalOverdueReceivables(@Param("companyId") companyId: UUID): BigDecimal

    /**
     * 연체된 미수금 조회 (최소 연체일수 기준)
     */
    @Query("""
        SELECT r FROM Receivable r 
        WHERE r.companyId = :companyId 
        AND r.status IN ('OUTSTANDING', 'PARTIALLY_PAID')
        AND r.overdueDays >= :minOverdueDays
        ORDER BY r.overdueDays DESC
    """)
    fun findOverdueReceivables(
        @Param("companyId") companyId: UUID,
        @Param("minOverdueDays") minOverdueDays: Int
    ): List<Receivable>
}