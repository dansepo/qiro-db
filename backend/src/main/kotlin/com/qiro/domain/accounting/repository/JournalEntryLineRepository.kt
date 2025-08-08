package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.JournalEntryLine
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 분개선 Repository
 */
@Repository
interface JournalEntryLineRepository : JpaRepository<JournalEntryLine, UUID> {

    /**
     * 분개 전표별 분개선 조회
     */
    fun findByJournalEntryEntryIdOrderByLineOrder(entryId: UUID): List<JournalEntryLine>

    /**
     * 계정별 분개선 조회
     */
    fun findByAccountAccountId(accountId: UUID): List<JournalEntryLine>

    /**
     * 계정별 기간별 분개선 조회
     */
    @Query("""
        SELECT jel FROM JournalEntryLine jel 
        JOIN jel.journalEntry je 
        WHERE jel.account.accountId = :accountId 
        AND je.companyId = :companyId
        AND je.entryDate BETWEEN :startDate AND :endDate 
        AND je.status = 'POSTED'
        ORDER BY je.entryDate, je.entryNumber, jel.lineOrder
    """)
    fun findByAccountAndDateRange(
        @Param("accountId") accountId: UUID,
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<JournalEntryLine>

    /**
     * 계정별 잔액 계산
     */
    @Query("""
        SELECT 
            COALESCE(SUM(jel.debitAmount), 0) - COALESCE(SUM(jel.creditAmount), 0) as balance
        FROM JournalEntryLine jel 
        JOIN jel.journalEntry je 
        WHERE jel.account.accountId = :accountId 
        AND je.companyId = :companyId
        AND je.status = 'POSTED'
        AND je.entryDate <= :asOfDate
    """)
    fun calculateAccountBalance(
        @Param("accountId") accountId: UUID,
        @Param("companyId") companyId: UUID,
        @Param("asOfDate") asOfDate: LocalDate
    ): BigDecimal?

    /**
     * 계정별 기간별 차변/대변 합계
     */
    @Query("""
        SELECT 
            COALESCE(SUM(jel.debitAmount), 0) as totalDebit,
            COALESCE(SUM(jel.creditAmount), 0) as totalCredit
        FROM JournalEntryLine jel 
        JOIN jel.journalEntry je 
        WHERE jel.account.accountId = :accountId 
        AND je.companyId = :companyId
        AND je.entryDate BETWEEN :startDate AND :endDate 
        AND je.status = 'POSTED'
    """)
    fun calculateAccountTotals(
        @Param("accountId") accountId: UUID,
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 시산표 데이터 조회
     */
    @Query("""
        SELECT 
            a.accountId,
            a.accountCode,
            a.accountName,
            a.accountType,
            COALESCE(SUM(jel.debitAmount), 0) as totalDebit,
            COALESCE(SUM(jel.creditAmount), 0) as totalCredit,
            COALESCE(SUM(jel.debitAmount), 0) - COALESCE(SUM(jel.creditAmount), 0) as balance
        FROM Account a 
        LEFT JOIN JournalEntryLine jel ON a.accountId = jel.account.accountId
        LEFT JOIN JournalEntry je ON jel.journalEntry.entryId = je.entryId AND je.status = 'POSTED'
        WHERE a.companyId = :companyId 
        AND a.isActive = true
        AND (je.entryDate IS NULL OR je.entryDate BETWEEN :startDate AND :endDate)
        GROUP BY a.accountId, a.accountCode, a.accountName, a.accountType
        HAVING COALESCE(SUM(jel.debitAmount), 0) > 0 OR COALESCE(SUM(jel.creditAmount), 0) > 0
        ORDER BY a.accountCode
    """)
    fun getTrialBalance(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 계정원장 데이터 조회
     */
    @Query("""
        SELECT jel, je.entryDate, je.entryNumber, je.description
        FROM JournalEntryLine jel 
        JOIN jel.journalEntry je 
        WHERE jel.account.accountId = :accountId 
        AND je.companyId = :companyId
        AND je.status = 'POSTED'
        ORDER BY je.entryDate, je.entryNumber, jel.lineOrder
    """)
    fun getGeneralLedger(
        @Param("accountId") accountId: UUID,
        @Param("companyId") companyId: UUID
    ): List<Any>

    /**
     * 참조 정보로 분개선 조회
     */
    fun findByReferenceTypeAndReferenceId(
        referenceType: String,
        referenceId: UUID
    ): List<JournalEntryLine>

    /**
     * 회사별 전체 차변/대변 합계 검증
     */
    @Query("""
        SELECT 
            COALESCE(SUM(jel.debitAmount), 0) as totalDebit,
            COALESCE(SUM(jel.creditAmount), 0) as totalCredit
        FROM JournalEntryLine jel 
        JOIN jel.journalEntry je 
        WHERE je.companyId = :companyId 
        AND je.status = 'POSTED'
    """)
    fun validateTotalBalance(@Param("companyId") companyId: UUID): List<Any>
}