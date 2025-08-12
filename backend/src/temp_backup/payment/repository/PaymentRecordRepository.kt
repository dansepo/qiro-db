package com.qiro.domain.payment.repository

import com.qiro.domain.payment.entity.PaymentRecord
import com.qiro.domain.payment.entity.PaymentMethod
import com.qiro.domain.payment.entity.PaymentStatus
import com.qiro.domain.payment.entity.PaymentType
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
 * 수납 기록 Repository
 */
@Repository
interface PaymentRecordRepository : JpaRepository<PaymentRecord, UUID> {

    /**
     * 회사별 수납 기록 목록 조회
     */
    fun findByCompanyIdOrderByPaymentDateDesc(companyId: UUID, pageable: Pageable): Page<PaymentRecord>

    /**
     * 세대별 수납 기록 목록 조회
     */
    fun findByCompanyIdAndUnitIdOrderByPaymentDateDesc(
        companyId: UUID,
        unitId: UUID,
        pageable: Pageable
    ): Page<PaymentRecord>

    /**
     * 고지서별 수납 기록 목록 조회
     */
    fun findByCompanyIdAndInvoiceIdOrderByPaymentDateDesc(
        companyId: UUID,
        invoiceId: UUID,
        pageable: Pageable
    ): Page<PaymentRecord>

    /**
     * 특정 기간의 수납 기록 조회
     */
    @Query("""
        SELECT p FROM PaymentRecord p 
        WHERE p.companyId = :companyId 
        AND p.paymentDate BETWEEN :startDate AND :endDate
        ORDER BY p.paymentDate DESC
    """)
    fun findByCompanyIdAndPaymentDateBetween(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        pageable: Pageable
    ): Page<PaymentRecord>

    /**
     * 결제 방법별 수납 기록 조회
     */
    fun findByCompanyIdAndPaymentMethodOrderByPaymentDateDesc(
        companyId: UUID,
        paymentMethod: PaymentMethod,
        pageable: Pageable
    ): Page<PaymentRecord>

    /**
     * 결제 상태별 수납 기록 조회
     */
    fun findByCompanyIdAndStatusOrderByPaymentDateDesc(
        companyId: UUID,
        status: PaymentStatus,
        pageable: Pageable
    ): Page<PaymentRecord>

    /**
     * 수납 번호로 조회
     */
    fun findByCompanyIdAndPaymentNumber(companyId: UUID, paymentNumber: String): PaymentRecord?

    /**
     * 거래 ID로 조회
     */
    fun findByCompanyIdAndTransactionId(companyId: UUID, transactionId: String): PaymentRecord?

    /**
     * 회사별 수납 통계 조회
     */
    @Query("""
        SELECT 
            COUNT(p) as totalCount,
            COALESCE(SUM(p.paymentAmount), 0) as totalAmount,
            COALESCE(SUM(p.refundAmount), 0) as totalRefundAmount,
            COALESCE(SUM(p.paymentAmount - p.refundAmount), 0) as netAmount
        FROM PaymentRecord p 
        WHERE p.companyId = :companyId
        AND (:status IS NULL OR p.status = :status)
        AND (:paymentMethod IS NULL OR p.paymentMethod = :paymentMethod)
        AND (:startDate IS NULL OR p.paymentDate >= :startDate)
        AND (:endDate IS NULL OR p.paymentDate <= :endDate)
    """)
    fun getPaymentStatistics(
        @Param("companyId") companyId: UUID,
        @Param("status") status: PaymentStatus? = null,
        @Param("paymentMethod") paymentMethod: PaymentMethod? = null,
        @Param("startDate") startDate: LocalDate? = null,
        @Param("endDate") endDate: LocalDate? = null
    ): PaymentStatistics

    /**
     * 월별 수납 현황 조회
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM p.paymentDate) as year,
            EXTRACT(MONTH FROM p.paymentDate) as month,
            COUNT(p) as paymentCount,
            COALESCE(SUM(p.paymentAmount), 0) as totalAmount,
            COALESCE(SUM(p.refundAmount), 0) as refundAmount,
            COALESCE(SUM(p.paymentAmount - p.refundAmount), 0) as netAmount
        FROM PaymentRecord p 
        WHERE p.companyId = :companyId
        AND p.paymentDate BETWEEN :startDate AND :endDate
        AND p.status NOT IN ('CANCELLED', 'FAILED')
        GROUP BY EXTRACT(YEAR FROM p.paymentDate), EXTRACT(MONTH FROM p.paymentDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyPaymentStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<MonthlyPaymentStats>

    /**
     * 결제 방법별 통계 조회
     */
    @Query("""
        SELECT 
            p.paymentMethod as paymentMethod,
            COUNT(p) as paymentCount,
            COALESCE(SUM(p.paymentAmount - p.refundAmount), 0) as totalAmount
        FROM PaymentRecord p 
        WHERE p.companyId = :companyId
        AND p.paymentDate BETWEEN :startDate AND :endDate
        AND p.status NOT IN ('CANCELLED', 'FAILED')
        GROUP BY p.paymentMethod
        ORDER BY totalAmount DESC
    """)
    fun getPaymentMethodStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<PaymentMethodStats>

    /**
     * 세대별 수납 현황 조회
     */
    @Query("""
        SELECT 
            p.unit.id as unitId,
            p.unit.unitNumber as unitNumber,
            COUNT(p) as paymentCount,
            COALESCE(SUM(p.paymentAmount - p.refundAmount), 0) as totalAmount,
            MAX(p.paymentDate) as lastPaymentDate
        FROM PaymentRecord p 
        WHERE p.companyId = :companyId
        AND p.paymentDate BETWEEN :startDate AND :endDate
        AND p.status NOT IN ('CANCELLED', 'FAILED')
        GROUP BY p.unit.id, p.unit.unitNumber
        ORDER BY totalAmount DESC
    """)
    fun getUnitPaymentStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<UnitPaymentStats>

    /**
     * 일별 수납 현황 조회
     */
    @Query("""
        SELECT 
            p.paymentDate as paymentDate,
            COUNT(p) as paymentCount,
            COALESCE(SUM(p.paymentAmount - p.refundAmount), 0) as totalAmount
        FROM PaymentRecord p 
        WHERE p.companyId = :companyId
        AND p.paymentDate BETWEEN :startDate AND :endDate
        AND p.status NOT IN ('CANCELLED', 'FAILED')
        GROUP BY p.paymentDate
        ORDER BY p.paymentDate DESC
    """)
    fun getDailyPaymentStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<DailyPaymentStats>
}

/**
 * 수납 통계 인터페이스
 */
interface PaymentStatistics {
    val totalCount: Long
    val totalAmount: BigDecimal
    val totalRefundAmount: BigDecimal
    val netAmount: BigDecimal
}

/**
 * 월별 수납 통계 인터페이스
 */
interface MonthlyPaymentStats {
    val year: Int
    val month: Int
    val paymentCount: Long
    val totalAmount: BigDecimal
    val refundAmount: BigDecimal
    val netAmount: BigDecimal
}

/**
 * 결제 방법별 통계 인터페이스
 */
interface PaymentMethodStats {
    val paymentMethod: PaymentMethod
    val paymentCount: Long
    val totalAmount: BigDecimal
}

/**
 * 세대별 수납 통계 인터페이스
 */
interface UnitPaymentStats {
    val unitId: UUID
    val unitNumber: String
    val paymentCount: Long
    val totalAmount: BigDecimal
    val lastPaymentDate: LocalDate
}

/**
 * 일별 수납 통계 인터페이스
 */
interface DailyPaymentStats {
    val paymentDate: LocalDate
    val paymentCount: Long
    val totalAmount: BigDecimal
}