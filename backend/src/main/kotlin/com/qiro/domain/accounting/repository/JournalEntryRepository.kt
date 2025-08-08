package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.JournalEntry
import com.qiro.domain.accounting.entity.JournalEntryStatus
import com.qiro.domain.accounting.entity.JournalEntryType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 분개 전표 Repository
 */
@Repository
interface JournalEntryRepository : JpaRepository<JournalEntry, UUID> {

    /**
     * 회사별 분개 전표 조회 (페이징)
     */
    fun findByCompanyIdOrderByEntryDateDescEntryNumberDesc(
        companyId: UUID, 
        pageable: Pageable
    ): Page<JournalEntry>

    /**
     * 회사별 전표 번호로 조회
     */
    fun findByCompanyIdAndEntryNumber(companyId: UUID, entryNumber: String): JournalEntry?

    /**
     * 회사별 상태로 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: JournalEntryStatus): List<JournalEntry>

    /**
     * 회사별 기간별 조회
     */
    fun findByCompanyIdAndEntryDateBetweenOrderByEntryDateDescEntryNumberDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<JournalEntry>

    /**
     * 회사별 기간별 상태별 조회
     */
    fun findByCompanyIdAndEntryDateBetweenAndStatusOrderByEntryDateDescEntryNumberDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        status: JournalEntryStatus
    ): List<JournalEntry>

    /**
     * 회사별 전표 유형으로 조회
     */
    fun findByCompanyIdAndEntryType(companyId: UUID, entryType: JournalEntryType): List<JournalEntry>

    /**
     * 회사별 참조 정보로 조회
     */
    fun findByCompanyIdAndReferenceTypeAndReferenceId(
        companyId: UUID,
        referenceType: String,
        referenceId: UUID
    ): List<JournalEntry>

    /**
     * 전표 번호 중복 확인
     */
    fun existsByCompanyIdAndEntryNumber(companyId: UUID, entryNumber: String): Boolean

    /**
     * 해당 월의 마지막 전표 번호 조회
     */
    @Query("""
        SELECT je.entryNumber 
        FROM JournalEntry je 
        WHERE je.companyId = :companyId 
        AND EXTRACT(YEAR FROM je.entryDate) = :year 
        AND EXTRACT(MONTH FROM je.entryDate) = :month 
        AND je.entryNumber LIKE :pattern 
        ORDER BY je.entryNumber DESC 
        LIMIT 1
    """)
    fun findLastEntryNumberByYearMonth(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int,
        @Param("month") month: Int,
        @Param("pattern") pattern: String
    ): String?

    /**
     * 승인 대기 중인 분개 전표 조회
     */
    @Query("SELECT je FROM JournalEntry je WHERE je.companyId = :companyId AND je.status = 'PENDING' ORDER BY je.createdAt ASC")
    fun findPendingJournalEntries(@Param("companyId") companyId: UUID): List<JournalEntry>

    /**
     * 특정 계정이 사용된 분개 전표 조회
     */
    @Query("""
        SELECT DISTINCT je FROM JournalEntry je 
        JOIN je.journalEntryLines jel 
        WHERE je.companyId = :companyId 
        AND jel.account.accountId = :accountId 
        AND je.status = 'POSTED'
        ORDER BY je.entryDate DESC, je.entryNumber DESC
    """)
    fun findByAccountId(
        @Param("companyId") companyId: UUID,
        @Param("accountId") accountId: UUID
    ): List<JournalEntry>

    /**
     * 월별 분개 전표 통계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM je.entryDate) as year,
            EXTRACT(MONTH FROM je.entryDate) as month,
            COUNT(je) as entryCount,
            SUM(je.totalAmount) as totalAmount
        FROM JournalEntry je 
        WHERE je.companyId = :companyId 
        AND je.status = 'POSTED'
        AND je.entryDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM je.entryDate), EXTRACT(MONTH FROM je.entryDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 복식부기 원칙 위반 분개 전표 조회
     */
    @Query("""
        SELECT je FROM JournalEntry je 
        WHERE je.companyId = :companyId 
        AND je.entryId IN (
            SELECT jel.journalEntry.entryId 
            FROM JournalEntryLine jel 
            GROUP BY jel.journalEntry.entryId 
            HAVING SUM(jel.debitAmount) != SUM(jel.creditAmount)
        )
    """)
    fun findUnbalancedJournalEntries(@Param("companyId") companyId: UUID): List<JournalEntry>
}