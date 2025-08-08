package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.WithholdingTax
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 원천징수 Repository
 */
@Repository
interface WithholdingTaxRepository : JpaRepository<WithholdingTax, UUID> {

    /**
     * 회사별 원천징수 내역 조회
     */
    fun findByCompanyIdOrderByPaymentDateDesc(companyId: UUID): List<WithholdingTax>

    /**
     * 회사별, 기간별 원천징수 내역 조회
     */
    fun findByCompanyIdAndPaymentDateBetweenOrderByPaymentDateDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<WithholdingTax>

    /**
     * 회사별, 소득자별 원천징수 내역 조회
     */
    fun findByCompanyIdAndPayeeRegistrationNumberOrderByPaymentDateDesc(
        companyId: UUID,
        payeeRegistrationNumber: String
    ): List<WithholdingTax>

    /**
     * 회사별, 소득 유형별 원천징수 내역 조회
     */
    fun findByCompanyIdAndIncomeTypeOrderByPaymentDateDesc(
        companyId: UUID,
        incomeType: WithholdingTax.IncomeType
    ): List<WithholdingTax>

    /**
     * 신고 상태별 원천징수 내역 조회
     */
    fun findByCompanyIdAndReportStatusOrderByPaymentDateDesc(
        companyId: UUID,
        reportStatus: WithholdingTax.ReportStatus
    ): List<WithholdingTax>

    /**
     * 월별 원천징수 집계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM wt.paymentDate) as year,
            EXTRACT(MONTH FROM wt.paymentDate) as month,
            COUNT(wt) as count,
            SUM(wt.incomeAmount) as totalIncome,
            SUM(wt.withholdingAmount) as totalWithholding
        FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND wt.paymentDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM wt.paymentDate), EXTRACT(MONTH FROM wt.paymentDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyWithholdingSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 소득자별 연간 원천징수 집계
     */
    @Query("""
        SELECT 
            wt.payeeRegistrationNumber,
            wt.payeeName,
            COUNT(wt) as count,
            SUM(wt.incomeAmount) as totalIncome,
            SUM(wt.withholdingAmount) as totalWithholding
        FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND EXTRACT(YEAR FROM wt.paymentDate) = :year
        GROUP BY wt.payeeRegistrationNumber, wt.payeeName
        ORDER BY totalIncome DESC
    """)
    fun getAnnualWithholdingByPayee(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int
    ): List<Array<Any>>

    /**
     * 소득 유형별 원천징수 집계
     */
    @Query("""
        SELECT 
            wt.incomeType,
            COUNT(wt) as count,
            SUM(wt.incomeAmount) as totalIncome,
            SUM(wt.withholdingAmount) as totalWithholding,
            AVG(wt.taxRate) as avgTaxRate
        FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND wt.paymentDate BETWEEN :startDate AND :endDate
        GROUP BY wt.incomeType
        ORDER BY totalIncome DESC
    """)
    fun getWithholdingByIncomeType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 신고 대기 중인 원천징수 내역 조회
     */
    @Query("""
        SELECT wt FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND wt.reportStatus = 'PENDING'
        AND wt.paymentDate <= :cutoffDate
        ORDER BY wt.paymentDate ASC
    """)
    fun findPendingWithholdingTaxes(
        @Param("companyId") companyId: UUID,
        @Param("cutoffDate") cutoffDate: LocalDate
    ): List<WithholdingTax>

    /**
     * 특정 금액 이상의 원천징수 내역 조회
     */
    @Query("""
        SELECT wt FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND wt.incomeAmount >= :minAmount
        AND wt.paymentDate BETWEEN :startDate AND :endDate
        ORDER BY wt.incomeAmount DESC
    """)
    fun findHighValueWithholdingTaxes(
        @Param("companyId") companyId: UUID,
        @Param("minAmount") minAmount: BigDecimal,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<WithholdingTax>

    /**
     * 원천징수 통계 대시보드 데이터
     */
    @Query("""
        SELECT 
            COUNT(wt) as totalCount,
            SUM(wt.incomeAmount) as totalIncome,
            SUM(wt.withholdingAmount) as totalWithholding,
            AVG(wt.taxRate) as avgTaxRate,
            COUNT(CASE WHEN wt.reportStatus = 'PENDING' THEN 1 END) as pendingCount,
            COUNT(CASE WHEN wt.reportStatus = 'REPORTED' THEN 1 END) as reportedCount
        FROM WithholdingTax wt 
        WHERE wt.companyId = :companyId 
        AND wt.paymentDate BETWEEN :startDate AND :endDate
    """)
    fun getWithholdingStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Array<Any>

    /**
     * 세무 기간별 원천징수 내역 조회
     */
    fun findByCompanyIdAndTaxPeriodIdOrderByPaymentDateDesc(
        companyId: UUID,
        taxPeriodId: UUID
    ): List<WithholdingTax>
}