package com.qiro.domain.accounting.repository

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 부가세 신고서 Repository
 */
@Repository
interface VatReturnRepository : JpaRepository<VatReturn, UUID> {

    /**
     * 회사별 부가세 신고서 조회
     */
    fun findByCompanyIdOrderByCreatedAtDesc(companyId: UUID): List<VatReturn>

    /**
     * 회사별 특정 기간 부가세 신고서 조회
     */
    @Query("""
        SELECT v FROM VatReturn v 
        WHERE v.companyId = :companyId 
        AND v.taxPeriodId = :taxPeriodId
    """)
    fun findByCompanyIdAndTaxPeriodId(
        @Param("companyId") companyId: UUID,
        @Param("taxPeriodId") taxPeriodId: UUID
    ): VatReturn?

    /**
     * 회사별 연도별 부가세 신고서 조회
     */
    @Query("""
        SELECT v FROM VatReturn v 
        JOIN TaxPeriod tp ON v.taxPeriodId = tp.id
        WHERE v.companyId = :companyId 
        AND tp.periodYear = :year
        ORDER BY tp.periodQuarter
    """)
    fun findByCompanyIdAndYear(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int
    ): List<VatReturn>

    /**
     * 회사별 부가세 신고 현황 통계
     */
    @Query("""
        SELECT COUNT(v) FROM VatReturn v 
        WHERE v.companyId = :companyId 
        AND v.submissionStatus = :status
    """)
    fun countByCompanyIdAndStatus(
        @Param("companyId") companyId: UUID,
        @Param("status") status: String
    ): Long

    /**
     * 회사별 연간 부가세 총액 조회
     */
    @Query("""
        SELECT COALESCE(SUM(v.payableVat), 0) FROM VatReturn v 
        JOIN TaxPeriod tp ON v.taxPeriodId = tp.id
        WHERE v.companyId = :companyId 
        AND tp.periodYear = :year
    """)
    fun getTotalVatByCompanyIdAndYear(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int
    ): BigDecimal

    /**
     * 최근 부가세 신고서 조회
     */
    @Query("""
        SELECT v FROM VatReturn v 
        WHERE v.companyId = :companyId 
        ORDER BY v.submissionDate DESC
        LIMIT :limit
    """)
    fun findRecentVatReturns(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int = 10
    ): List<VatReturn>
}

/**
 * 부가세 신고서 엔티티 (임시)
 */
data class VatReturn(
    val id: UUID,
    val companyId: UUID,
    val taxPeriodId: UUID,
    val salesAmount: BigDecimal = BigDecimal.ZERO,
    val outputVat: BigDecimal = BigDecimal.ZERO,
    val purchaseAmount: BigDecimal = BigDecimal.ZERO,
    val inputVat: BigDecimal = BigDecimal.ZERO,
    val payableVat: BigDecimal = BigDecimal.ZERO,
    val refundableVat: BigDecimal = BigDecimal.ZERO,
    val submissionStatus: String = "DRAFT",
    val submissionDate: LocalDate? = null,
    val acceptanceNumber: String? = null
)