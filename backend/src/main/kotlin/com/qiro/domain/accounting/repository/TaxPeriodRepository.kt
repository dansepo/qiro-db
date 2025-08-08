package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.TaxPeriod
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 세무 신고 기간 Repository
 */
@Repository
interface TaxPeriodRepository : JpaRepository<TaxPeriod, UUID> {

    /**
     * 회사별 세무 신고 기간 조회
     */
    fun findByCompanyIdOrderByPeriodYearDescPeriodQuarterDesc(companyId: UUID): List<TaxPeriod>

    /**
     * 회사별, 세금 유형별 세무 신고 기간 조회
     */
    fun findByCompanyIdAndTaxTypeOrderByPeriodYearDescPeriodQuarterDesc(
        companyId: UUID,
        taxType: TaxPeriod.TaxType
    ): List<TaxPeriod>

    /**
     * 회사별, 연도별 세무 신고 기간 조회
     */
    fun findByCompanyIdAndPeriodYearOrderByPeriodQuarterAsc(
        companyId: UUID,
        periodYear: Int
    ): List<TaxPeriod>

    /**
     * 회사별, 연도, 분기별 세무 신고 기간 조회
     */
    fun findByCompanyIdAndPeriodYearAndPeriodQuarter(
        companyId: UUID,
        periodYear: Int,
        periodQuarter: Int
    ): TaxPeriod?

    /**
     * 회사별, 연도, 월별 세무 신고 기간 조회
     */
    fun findByCompanyIdAndPeriodYearAndPeriodMonth(
        companyId: UUID,
        periodYear: Int,
        periodMonth: Int
    ): TaxPeriod?

    /**
     * 상태별 세무 신고 기간 조회
     */
    fun findByCompanyIdAndStatusOrderByDueDateAsc(
        companyId: UUID,
        status: TaxPeriod.TaxPeriodStatus
    ): List<TaxPeriod>

    /**
     * 기한이 임박한 세무 신고 기간 조회
     */
    @Query("""
        SELECT tp FROM TaxPeriod tp 
        WHERE tp.companyId = :companyId 
        AND tp.dueDate BETWEEN :startDate AND :endDate 
        AND tp.status IN ('OPEN', 'CLOSED')
        ORDER BY tp.dueDate ASC
    """)
    fun findUpcomingTaxPeriods(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<TaxPeriod>

    /**
     * 연체된 세무 신고 기간 조회
     */
    @Query("""
        SELECT tp FROM TaxPeriod tp 
        WHERE tp.companyId = :companyId 
        AND tp.dueDate < :currentDate 
        AND tp.status = 'OPEN'
        ORDER BY tp.dueDate ASC
    """)
    fun findOverdueTaxPeriods(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate
    ): List<TaxPeriod>

    /**
     * 특정 기간에 해당하는 세무 신고 기간 조회
     */
    @Query("""
        SELECT tp FROM TaxPeriod tp 
        WHERE tp.companyId = :companyId 
        AND tp.taxType = :taxType
        AND :targetDate BETWEEN tp.startDate AND tp.endDate
    """)
    fun findTaxPeriodByDate(
        @Param("companyId") companyId: UUID,
        @Param("taxType") taxType: TaxPeriod.TaxType,
        @Param("targetDate") targetDate: LocalDate
    ): TaxPeriod?

    /**
     * 세무 신고 기간 통계
     */
    @Query("""
        SELECT tp.status, COUNT(tp) 
        FROM TaxPeriod tp 
        WHERE tp.companyId = :companyId 
        AND tp.periodYear = :year
        GROUP BY tp.status
    """)
    fun getTaxPeriodStatistics(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int
    ): List<Array<Any>>

    /**
     * 회사별, 세금 유형별 최신 세무 신고 기간 조회
     */
    @Query("""
        SELECT tp FROM TaxPeriod tp 
        WHERE tp.companyId = :companyId 
        AND tp.taxType = :taxType
        ORDER BY tp.periodYear DESC, tp.periodQuarter DESC, tp.periodMonth DESC
        LIMIT 1
    """)
    fun findLatestTaxPeriod(
        @Param("companyId") companyId: UUID,
        @Param("taxType") taxType: TaxPeriod.TaxType
    ): TaxPeriod?
}