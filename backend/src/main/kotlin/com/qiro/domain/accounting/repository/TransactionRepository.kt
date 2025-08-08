package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.Transaction
import com.qiro.domain.accounting.entity.TransactionCategory
import com.qiro.domain.accounting.entity.TransactionStatus
import com.qiro.domain.accounting.entity.TransactionType
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
 * 거래 Repository
 */
@Repository
interface TransactionRepository : JpaRepository<Transaction, UUID> {

    /**
     * 회사별 거래 조회 (페이징)
     */
    fun findByCompanyIdOrderByTransactionDateDescCreatedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<Transaction>

    /**
     * 회사별 거래 번호로 조회
     */
    fun findByCompanyIdAndTransactionNumber(companyId: UUID, transactionNumber: String): Transaction?

    /**
     * 회사별 상태로 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: TransactionStatus): List<Transaction>

    /**
     * 회사별 거래 유형으로 조회
     */
    fun findByCompanyIdAndTransactionType(companyId: UUID, transactionType: TransactionType): List<Transaction>

    /**
     * 회사별 거래 카테고리로 조회
     */
    fun findByCompanyIdAndTransactionCategory(
        companyId: UUID,
        transactionCategory: TransactionCategory
    ): List<Transaction>

    /**
     * 회사별 기간별 조회
     */
    fun findByCompanyIdAndTransactionDateBetweenOrderByTransactionDateDescCreatedAtDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<Transaction>

    /**
     * 회사별 기간별 상태별 조회
     */
    fun findByCompanyIdAndTransactionDateBetweenAndStatusOrderByTransactionDateDescCreatedAtDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        status: TransactionStatus
    ): List<Transaction>

    /**
     * 회사별 참조 정보로 조회
     */
    fun findByCompanyIdAndReferenceTypeAndReferenceId(
        companyId: UUID,
        referenceType: String,
        referenceId: UUID
    ): List<Transaction>

    /**
     * 거래 번호 중복 확인
     */
    fun existsByCompanyIdAndTransactionNumber(companyId: UUID, transactionNumber: String): Boolean

    /**
     * 해당 월의 마지막 거래 번호 조회
     */
    @Query("""
        SELECT t.transactionNumber 
        FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND EXTRACT(YEAR FROM t.transactionDate) = :year 
        AND EXTRACT(MONTH FROM t.transactionDate) = :month 
        AND t.transactionNumber LIKE :pattern 
        ORDER BY t.transactionNumber DESC 
        LIMIT 1
    """)
    fun findLastTransactionNumberByYearMonth(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int,
        @Param("month") month: Int,
        @Param("pattern") pattern: String
    ): String?

    /**
     * 승인 대기 중인 거래 조회
     */
    @Query("SELECT t FROM Transaction t WHERE t.companyId = :companyId AND t.status = 'PENDING' ORDER BY t.createdAt ASC")
    fun findPendingTransactions(@Param("companyId") companyId: UUID): List<Transaction>

    /**
     * 특정 계정이 제안된 거래 조회
     */
    @Query("""
        SELECT t FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.suggestedAccount.accountId = :accountId 
        ORDER BY t.transactionDate DESC, t.createdAt DESC
    """)
    fun findBySuggestedAccountId(
        @Param("companyId") companyId: UUID,
        @Param("accountId") accountId: UUID
    ): List<Transaction>

    /**
     * 거래처별 거래 조회
     */
    @Query("""
        SELECT t FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.counterparty LIKE %:counterparty% 
        ORDER BY t.transactionDate DESC
    """)
    fun findByCounterpartyContaining(
        @Param("companyId") companyId: UUID,
        @Param("counterparty") counterparty: String
    ): List<Transaction>

    /**
     * 월별 거래 통계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM t.transactionDate) as year,
            EXTRACT(MONTH FROM t.transactionDate) as month,
            t.transactionType,
            COUNT(t) as transactionCount,
            SUM(t.amount) as totalAmount
        FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.status IN ('APPROVED', 'PROCESSED')
        AND t.transactionDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM t.transactionDate), EXTRACT(MONTH FROM t.transactionDate), t.transactionType
        ORDER BY year DESC, month DESC, t.transactionType
    """)
    fun getMonthlyStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 카테고리별 거래 통계
     */
    @Query("""
        SELECT 
            t.transactionCategory,
            COUNT(t) as transactionCount,
            SUM(t.amount) as totalAmount,
            AVG(t.amount) as averageAmount
        FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.status IN ('APPROVED', 'PROCESSED')
        AND t.transactionDate BETWEEN :startDate AND :endDate
        GROUP BY t.transactionCategory
        ORDER BY totalAmount DESC
    """)
    fun getCategoryStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 거래처별 거래 통계
     */
    @Query("""
        SELECT 
            t.counterparty,
            COUNT(t) as transactionCount,
            SUM(t.amount) as totalAmount
        FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.status IN ('APPROVED', 'PROCESSED')
        AND t.counterparty IS NOT NULL
        AND t.transactionDate BETWEEN :startDate AND :endDate
        GROUP BY t.counterparty
        ORDER BY totalAmount DESC
        LIMIT 20
    """)
    fun getCounterpartyStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Any>

    /**
     * 미처리 거래 조회 (분개 전표가 생성되지 않은 승인된 거래)
     */
    @Query("""
        SELECT t FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.status = 'APPROVED'
        AND t.journalEntry IS NULL
        ORDER BY t.transactionDate ASC, t.createdAt ASC
    """)
    fun findUnprocessedTransactions(@Param("companyId") companyId: UUID): List<Transaction>

    /**
     * 금액 범위별 거래 조회
     */
    @Query("""
        SELECT t FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.amount BETWEEN :minAmount AND :maxAmount
        AND t.transactionDate BETWEEN :startDate AND :endDate
        ORDER BY t.amount DESC
    """)
    fun findByAmountRange(
        @Param("companyId") companyId: UUID,
        @Param("minAmount") minAmount: BigDecimal,
        @Param("maxAmount") maxAmount: BigDecimal,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Transaction>

    /**
     * 태그로 거래 검색
     */
    @Query("""
        SELECT t FROM Transaction t 
        WHERE t.companyId = :companyId 
        AND t.tags LIKE %:tag%
        ORDER BY t.transactionDate DESC
    """)
    fun findByTagContaining(
        @Param("companyId") companyId: UUID,
        @Param("tag") tag: String
    ): List<Transaction>
}