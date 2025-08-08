package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.FinancialPeriod
import com.qiro.domain.accounting.entity.FinancialPeriodStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 회계 기간 Repository
 */
@Repository
interface FinancialPeriodRepository : JpaRepository<FinancialPeriod, UUID> {

    /**
     * 회사별 회계 기간 조회
     */
    fun findByCompanyIdOrderByFiscalYearDescPeriodNumberDesc(companyId: UUID): List<FinancialPeriod>

    /**
     * 회사별 회계연도별 조회
     */
    fun findByCompanyIdAndFiscalYearOrderByPeriodNumber(
        companyId: UUID, 
        fiscalYear: Int
    ): List<FinancialPeriod>

    /**
     * 회사별 회계연도 및 기간번호로 조회
     */
    fun findByCompanyIdAndFiscalYearAndPeriodNumber(
        companyId: UUID,
        fiscalYear: Int,
        periodNumber: Int
    ): FinancialPeriod?

    /**
     * 회사별 상태별 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: FinancialPeriodStatus): List<FinancialPeriod>

    /**
     * 특정 날짜가 포함된 회계 기간 조회
     */
    @Query("""
        SELECT fp FROM FinancialPeriod fp 
        WHERE fp.companyId = :companyId 
        AND :date BETWEEN fp.startDate AND fp.endDate
    """)
    fun findByCompanyIdAndDate(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate
    ): FinancialPeriod?

    /**
     * 회사별 열린 회계 기간 조회
     */
    fun findByCompanyIdAndStatusOrderByFiscalYearDescPeriodNumberDesc(
        companyId: UUID,
        status: FinancialPeriodStatus
    ): List<FinancialPeriod>

    /**
     * 회사별 현재 활성 회계 기간 조회
     */
    @Query("""
        SELECT fp FROM FinancialPeriod fp 
        WHERE fp.companyId = :companyId 
        AND fp.status = 'OPEN'
        AND CURRENT_DATE BETWEEN fp.startDate AND fp.endDate
    """)
    fun findCurrentActivePeriod(@Param("companyId") companyId: UUID): FinancialPeriod?

    /**
     * 회계 기간 중복 확인
     */
    fun existsByCompanyIdAndFiscalYearAndPeriodNumber(
        companyId: UUID,
        fiscalYear: Int,
        periodNumber: Int
    ): Boolean

    /**
     * 회사별 최신 회계 기간 조회
     */
    @Query("""
        SELECT fp FROM FinancialPeriod fp 
        WHERE fp.companyId = :companyId 
        ORDER BY fp.fiscalYear DESC, fp.periodNumber DESC 
        LIMIT 1
    """)
    fun findLatestPeriod(@Param("companyId") companyId: UUID): FinancialPeriod?

    /**
     * 기간별 범위 조회
     */
    @Query("""
        SELECT fp FROM FinancialPeriod fp 
        WHERE fp.companyId = :companyId 
        AND ((fp.startDate BETWEEN :startDate AND :endDate) 
             OR (fp.endDate BETWEEN :startDate AND :endDate)
             OR (fp.startDate <= :startDate AND fp.endDate >= :endDate))
        ORDER BY fp.fiscalYear, fp.periodNumber
    """)
    fun findByDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<FinancialPeriod>

    /**
     * 마감되지 않은 이전 기간 확인
     */
    @Query("""
        SELECT COUNT(fp) FROM FinancialPeriod fp 
        WHERE fp.companyId = :companyId 
        AND fp.status = 'OPEN'
        AND (fp.fiscalYear < :fiscalYear 
             OR (fp.fiscalYear = :fiscalYear AND fp.periodNumber < :periodNumber))
    """)
    fun countUnclosedPreviousPeriods(
        @Param("companyId") companyId: UUID,
        @Param("fiscalYear") fiscalYear: Int,
        @Param("periodNumber") periodNumber: Int
    ): Long
}