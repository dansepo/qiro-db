package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.TaxInvoice
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 세금계산서 Repository
 */
@Repository
interface TaxInvoiceRepository : JpaRepository<TaxInvoice, UUID> {

    /**
     * 회사별 세금계산서 조회
     */
    fun findByCompanyIdOrderByIssueDateDesc(companyId: UUID): List<TaxInvoice>

    /**
     * 회사별, 유형별 세금계산서 조회
     */
    fun findByCompanyIdAndInvoiceTypeOrderByIssueDateDesc(
        companyId: UUID,
        invoiceType: TaxInvoice.InvoiceType
    ): List<TaxInvoice>

    /**
     * 회사별, 기간별 세금계산서 조회
     */
    fun findByCompanyIdAndIssueDateBetweenOrderByIssueDateDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<TaxInvoice>

    /**
     * 세금계산서 번호로 조회
     */
    fun findByCompanyIdAndInvoiceNumber(
        companyId: UUID,
        invoiceNumber: String
    ): TaxInvoice?

    /**
     * 공급자 사업자등록번호로 조회
     */
    fun findByCompanyIdAndSupplierRegistrationNumberOrderByIssueDateDesc(
        companyId: UUID,
        supplierRegistrationNumber: String
    ): List<TaxInvoice>

    /**
     * 공급받는자 사업자등록번호로 조회
     */
    fun findByCompanyIdAndBuyerRegistrationNumberOrderByIssueDateDesc(
        companyId: UUID,
        buyerRegistrationNumber: String
    ): List<TaxInvoice>

    /**
     * 상태별 세금계산서 조회
     */
    fun findByCompanyIdAndStatusOrderByIssueDateDesc(
        companyId: UUID,
        status: TaxInvoice.InvoiceStatus
    ): List<TaxInvoice>

    /**
     * 월별 발행 세금계산서 집계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM ti.issueDate) as year,
            EXTRACT(MONTH FROM ti.issueDate) as month,
            COUNT(ti) as count,
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat,
            SUM(ti.totalAmount) as totalAmount
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.invoiceType = 'ISSUED'
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('ISSUED', 'SENT', 'CONFIRMED')
        GROUP BY EXTRACT(YEAR FROM ti.issueDate), EXTRACT(MONTH FROM ti.issueDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyIssuedInvoiceSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 월별 수취 세금계산서 집계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM ti.issueDate) as year,
            EXTRACT(MONTH FROM ti.issueDate) as month,
            COUNT(ti) as count,
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat,
            SUM(ti.totalAmount) as totalAmount
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.invoiceType = 'RECEIVED'
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('RECEIVED', 'CONFIRMED')
        GROUP BY EXTRACT(YEAR FROM ti.issueDate), EXTRACT(MONTH FROM ti.issueDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyReceivedInvoiceSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 부가세 신고용 매출세액 계산
     */
    @Query("""
        SELECT 
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.invoiceType = 'ISSUED'
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('ISSUED', 'SENT', 'CONFIRMED')
    """)
    fun calculateOutputVat(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Array<BigDecimal>

    /**
     * 부가세 신고용 매입세액 계산
     */
    @Query("""
        SELECT 
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.invoiceType = 'RECEIVED'
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('RECEIVED', 'CONFIRMED')
    """)
    fun calculateInputVat(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Array<BigDecimal>

    /**
     * 거래처별 세금계산서 집계
     */
    @Query("""
        SELECT 
            CASE WHEN ti.invoiceType = 'ISSUED' THEN ti.buyerRegistrationNumber 
                 ELSE ti.supplierRegistrationNumber END as partnerRegNumber,
            CASE WHEN ti.invoiceType = 'ISSUED' THEN ti.buyerName 
                 ELSE ti.supplierName END as partnerName,
            ti.invoiceType,
            COUNT(ti) as count,
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('ISSUED', 'SENT', 'RECEIVED', 'CONFIRMED')
        GROUP BY partnerRegNumber, partnerName, ti.invoiceType
        ORDER BY totalSupply DESC
    """)
    fun getInvoiceSummaryByPartner(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 고액 세금계산서 조회
     */
    @Query("""
        SELECT ti FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.totalAmount >= :minAmount
        AND ti.issueDate BETWEEN :startDate AND :endDate
        ORDER BY ti.totalAmount DESC
    """)
    fun findHighValueInvoices(
        @Param("companyId") companyId: UUID,
        @Param("minAmount") minAmount: BigDecimal,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<TaxInvoice>

    /**
     * 세금계산서 통계 대시보드 데이터
     */
    @Query("""
        SELECT 
            ti.invoiceType,
            COUNT(ti) as count,
            SUM(ti.supplyAmount) as totalSupply,
            SUM(ti.vatAmount) as totalVat,
            SUM(ti.totalAmount) as totalAmount,
            AVG(ti.totalAmount) as avgAmount
        FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.issueDate BETWEEN :startDate AND :endDate
        AND ti.status IN ('ISSUED', 'SENT', 'RECEIVED', 'CONFIRMED')
        GROUP BY ti.invoiceType
    """)
    fun getInvoiceStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 연동된 거래/수입/지출 기록이 있는 세금계산서 조회
     */
    @Query("""
        SELECT ti FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND (ti.relatedTransactionId IS NOT NULL 
             OR ti.relatedExpenseId IS NOT NULL 
             OR ti.relatedIncomeId IS NOT NULL)
        ORDER BY ti.issueDate DESC
    """)
    fun findLinkedInvoices(companyId: UUID): List<TaxInvoice>

    /**
     * 연동되지 않은 세금계산서 조회
     */
    @Query("""
        SELECT ti FROM TaxInvoice ti 
        WHERE ti.companyId = :companyId 
        AND ti.relatedTransactionId IS NULL 
        AND ti.relatedExpenseId IS NULL 
        AND ti.relatedIncomeId IS NULL
        AND ti.status IN ('ISSUED', 'SENT', 'RECEIVED', 'CONFIRMED')
        ORDER BY ti.issueDate DESC
    """)
    fun findUnlinkedInvoices(companyId: UUID): List<TaxInvoice>
}