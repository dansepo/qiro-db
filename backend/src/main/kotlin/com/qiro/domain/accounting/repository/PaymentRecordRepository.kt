package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.PaymentRecord
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
 * 결제 기록 Repository
 */
@Repository
interface PaymentRecordRepository : JpaRepository<PaymentRecord, UUID> {

    /**
     * 회사별 결제 기록 조회 (페이징)
     */
    fun findByCompanyIdOrderByPaymentDateDesc(companyId: UUID, pageable: Pageable): Page<PaymentRecord>

    /**
     * 미수금별 결제 기록 조회
     */
    fun findByReceivableReceivableIdOrderByPaymentDateDesc(receivableId: UUID): List<PaymentRecord>

    /**
     * 수입 기록별 결제 기록 조회
     */
    fun findByIncomeRecordIncomeRecordIdOrderByPaymentDateDesc(incomeRecordId: UUID): List<PaymentRecord>

    /**
     * 기간별 결제 기록 조회
     */
    @Query("""
        SELECT pr FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentDate BETWEEN :startDate AND :endDate 
        ORDER BY pr.paymentDate DESC
    """)
    fun findByDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<PaymentRecord>

    /**
     * 결제 방법별 결제 기록 조회
     */
    @Query("""
        SELECT pr FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentMethod = :paymentMethod 
        ORDER BY pr.paymentDate DESC
    """)
    fun findByPaymentMethod(
        @Param("companyId") companyId: UUID,
        @Param("paymentMethod") paymentMethod: String
    ): List<PaymentRecord>

    /**
     * 기간별 총 결제 금액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(pr.totalPaid), 0) 
        FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentDate BETWEEN :startDate AND :endDate
    """)
    fun getTotalPaymentAmount(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 기간별 연체료 납부 총액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(pr.lateFeePaid), 0) 
        FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentDate BETWEEN :startDate AND :endDate
    """)
    fun getTotalLateFeePaid(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 월별 결제 집계
     */
    @Query("""
        SELECT EXTRACT(YEAR FROM pr.paymentDate), EXTRACT(MONTH FROM pr.paymentDate), SUM(pr.totalPaid) 
        FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentDate BETWEEN :startDate AND :endDate 
        GROUP BY EXTRACT(YEAR FROM pr.paymentDate), EXTRACT(MONTH FROM pr.paymentDate)
        ORDER BY EXTRACT(YEAR FROM pr.paymentDate), EXTRACT(MONTH FROM pr.paymentDate)
    """)
    fun getMonthlyPaymentTotal(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 결제 방법별 집계
     */
    @Query("""
        SELECT pr.paymentMethod, COUNT(pr), SUM(pr.totalPaid) 
        FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.paymentDate BETWEEN :startDate AND :endDate 
        GROUP BY pr.paymentMethod
    """)
    fun getPaymentMethodSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 거래 참조 번호로 결제 기록 조회
     */
    fun findByCompanyIdAndTransactionReference(companyId: UUID, transactionReference: String): PaymentRecord?

    /**
     * 분개 전표 연결되지 않은 결제 기록 조회
     */
    @Query("""
        SELECT pr FROM PaymentRecord pr 
        WHERE pr.companyId = :companyId 
        AND pr.journalEntryId IS NULL
    """)
    fun findUnlinkedPaymentRecords(@Param("companyId") companyId: UUID): List<PaymentRecord>

    /**
     * 미수금별 총 결제 금액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(pr.totalPaid), 0) 
        FROM PaymentRecord pr 
        WHERE pr.receivable.receivableId = :receivableId
    """)
    fun getTotalPaidByReceivable(@Param("receivableId") receivableId: UUID): BigDecimal
}