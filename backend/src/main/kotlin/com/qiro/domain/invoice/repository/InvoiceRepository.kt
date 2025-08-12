package com.qiro.domain.invoice.repository

import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.invoice.entity.InvoiceStatus
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
 * 고지서 Repository
 */
@Repository
interface InvoiceRepository : JpaRepository<Invoice, UUID> {

    /**
     * 회사별 고지서 목록 조회
     */
    fun findByCompanyIdOrderByIssueDateDesc(companyId: UUID, pageable: Pageable): Page<Invoice>

    /**
     * 회사별 특정 상태의 고지서 목록 조회
     */
    fun findByCompanyIdAndStatusOrderByIssueDateDesc(
        companyId: UUID,
        status: InvoiceStatus,
        pageable: Pageable
    ): Page<Invoice>

    /**
     * 세대별 고지서 목록 조회
     */
    fun findByCompanyIdAndUnitIdOrderByIssueDateDesc(
        companyId: UUID,
        unitId: UUID,
        pageable: Pageable
    ): Page<Invoice>

    /**
     * 연체된 고지서 목록 조회
     */
    @Query("""
        SELECT i FROM Invoice i 
        WHERE i.companyId = :companyId 
        AND i.dueDate < :currentDate 
        AND i.status NOT IN ('PAID', 'CANCELLED')
        ORDER BY i.dueDate ASC
    """)
    fun findOverdueInvoices(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate = LocalDate.now(),
        pageable: Pageable
    ): Page<Invoice>

    /**
     * 특정 기간의 고지서 목록 조회
     */
    @Query("""
        SELECT i FROM Invoice i 
        WHERE i.companyId = :companyId 
        AND i.issueDate BETWEEN :startDate AND :endDate
        ORDER BY i.issueDate DESC
    """)
    fun findByCompanyIdAndIssueDateBetween(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        pageable: Pageable
    ): Page<Invoice>

    /**
     * 고지서 번호로 조회
     */
    fun findByCompanyIdAndInvoiceNumber(companyId: UUID, invoiceNumber: String): Invoice?

    /**
     * 회사별 고지서 통계 조회
     */
    @Query("""
        SELECT 
            COUNT(i) as totalCount,
            COALESCE(SUM(i.totalAmount), 0) as totalAmount,
            COALESCE(SUM(i.paidAmount), 0) as paidAmount,
            COALESCE(SUM(i.totalAmount + i.lateFee - i.discountAmount - i.paidAmount), 0) as outstandingAmount
        FROM Invoice i 
        WHERE i.companyId = :companyId
        AND (:status IS NULL OR i.status = :status)
        AND (:startDate IS NULL OR i.issueDate >= :startDate)
        AND (:endDate IS NULL OR i.issueDate <= :endDate)
    """)
    fun getInvoiceStatistics(
        @Param("companyId") companyId: UUID,
        @Param("status") status: InvoiceStatus? = null,
        @Param("startDate") startDate: LocalDate? = null,
        @Param("endDate") endDate: LocalDate? = null
    ): InvoiceStatistics

    /**
     * 연체 고지서 통계 조회
     */
    @Query("""
        SELECT 
            COUNT(i) as overdueCount,
            COALESCE(SUM(i.totalAmount + i.lateFee - i.discountAmount - i.paidAmount), 0) as overdueAmount
        FROM Invoice i 
        WHERE i.companyId = :companyId 
        AND i.dueDate < :currentDate 
        AND i.status NOT IN ('PAID', 'CANCELLED')
    """)
    fun getOverdueStatistics(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate = LocalDate.now()
    ): OverdueStatistics

    /**
     * 월별 고지서 발행 현황 조회
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM i.issueDate) as year,
            EXTRACT(MONTH FROM i.issueDate) as month,
            COUNT(i) as invoiceCount,
            COALESCE(SUM(i.totalAmount), 0) as totalAmount,
            COALESCE(SUM(i.paidAmount), 0) as paidAmount
        FROM Invoice i 
        WHERE i.companyId = :companyId
        AND i.issueDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM i.issueDate), EXTRACT(MONTH FROM i.issueDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyInvoiceStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<MonthlyInvoiceStats>

    /**
     * 세대별 미납 현황 조회
     */
    @Query("""
        SELECT 
            i.unit.id as unitId,
            i.unit.unitNumber as unitNumber,
            COUNT(i) as unpaidCount,
            COALESCE(SUM(i.totalAmount + i.lateFee - i.discountAmount - i.paidAmount), 0) as unpaidAmount
        FROM Invoice i 
        WHERE i.companyId = :companyId 
        AND i.status NOT IN ('PAID', 'CANCELLED')
        GROUP BY i.unit.id, i.unit.unitNumber
        HAVING SUM(i.totalAmount + i.lateFee - i.discountAmount - i.paidAmount) > 0
        ORDER BY unpaidAmount DESC
    """)
    fun getUnitUnpaidStats(@Param("companyId") companyId: UUID): List<UnitUnpaidStats>
}

/**
 * 고지서 통계 인터페이스
 */
interface InvoiceStatistics {
    val totalCount: Long
    val totalAmount: BigDecimal
    val paidAmount: BigDecimal
    val outstandingAmount: BigDecimal
}

/**
 * 연체 통계 인터페이스
 */
interface OverdueStatistics {
    val overdueCount: Long
    val overdueAmount: BigDecimal
}

/**
 * 월별 고지서 통계 인터페이스
 */
interface MonthlyInvoiceStats {
    val year: Int
    val month: Int
    val invoiceCount: Long
    val totalAmount: BigDecimal
    val paidAmount: BigDecimal
}

/**
 * 세대별 미납 통계 인터페이스
 */
interface UnitUnpaidStats {
    val unitId: UUID
    val unitNumber: String
    val unpaidCount: Long
    val unpaidAmount: BigDecimal
}