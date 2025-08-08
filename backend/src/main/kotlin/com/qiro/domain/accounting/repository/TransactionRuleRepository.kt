package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.TransactionRule
import com.qiro.domain.accounting.entity.TransactionType
import com.qiro.domain.accounting.entity.TransactionCategory
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 거래 분류 규칙 Repository
 */
@Repository
interface TransactionRuleRepository : JpaRepository<TransactionRule, UUID> {

    /**
     * 회사별 활성 규칙 조회 (우선순위 순)
     */
    fun findByCompanyIdAndIsActiveTrueOrderByPriorityAscCreatedAtAsc(companyId: UUID): List<TransactionRule>

    /**
     * 회사별 모든 규칙 조회 (우선순위 순)
     */
    fun findByCompanyIdOrderByPriorityAscCreatedAtAsc(companyId: UUID): List<TransactionRule>

    /**
     * 회사별 거래 유형별 활성 규칙 조회
     */
    fun findByCompanyIdAndTransactionTypeAndIsActiveTrueOrderByPriorityAsc(
        companyId: UUID,
        transactionType: TransactionType
    ): List<TransactionRule>

    /**
     * 회사별 거래 카테고리별 활성 규칙 조회
     */
    fun findByCompanyIdAndTransactionCategoryAndIsActiveTrueOrderByPriorityAsc(
        companyId: UUID,
        transactionCategory: TransactionCategory
    ): List<TransactionRule>

    /**
     * 회사별 계정별 규칙 조회
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.suggestedAccount.accountId = :accountId 
        ORDER BY tr.priority ASC, tr.createdAt ASC
    """)
    fun findBySuggestedAccountId(
        @Param("companyId") companyId: UUID,
        @Param("accountId") accountId: UUID
    ): List<TransactionRule>

    /**
     * 규칙명으로 조회
     */
    fun findByCompanyIdAndRuleName(companyId: UUID, ruleName: String): TransactionRule?

    /**
     * 규칙명 중복 확인
     */
    fun existsByCompanyIdAndRuleName(companyId: UUID, ruleName: String): Boolean

    /**
     * 거래처 패턴으로 규칙 검색
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.counterpartyPattern IS NOT NULL
        AND tr.counterpartyPattern LIKE %:pattern%
        AND tr.isActive = true
        ORDER BY tr.priority ASC
    """)
    fun findByCounterpartyPatternContaining(
        @Param("companyId") companyId: UUID,
        @Param("pattern") pattern: String
    ): List<TransactionRule>

    /**
     * 설명 패턴으로 규칙 검색
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.descriptionPattern IS NOT NULL
        AND tr.descriptionPattern LIKE %:pattern%
        AND tr.isActive = true
        ORDER BY tr.priority ASC
    """)
    fun findByDescriptionPatternContaining(
        @Param("companyId") companyId: UUID,
        @Param("pattern") pattern: String
    ): List<TransactionRule>

    /**
     * 성공률이 높은 규칙 조회
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.isActive = true
        AND tr.usageCount >= :minUsageCount
        ORDER BY (CAST(tr.successCount AS double) / CAST(tr.usageCount AS double)) DESC, tr.usageCount DESC
        LIMIT :limit
    """)
    fun findTopPerformingRules(
        @Param("companyId") companyId: UUID,
        @Param("minUsageCount") minUsageCount: Long = 5,
        @Param("limit") limit: Int = 10
    ): List<TransactionRule>

    /**
     * 사용 빈도가 높은 규칙 조회
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.isActive = true
        ORDER BY tr.usageCount DESC, tr.successCount DESC
        LIMIT :limit
    """)
    fun findMostUsedRules(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int = 10
    ): List<TransactionRule>

    /**
     * 우선순위 범위의 규칙 조회
     */
    @Query("""
        SELECT tr FROM TransactionRule tr 
        WHERE tr.companyId = :companyId 
        AND tr.priority BETWEEN :minPriority AND :maxPriority
        ORDER BY tr.priority ASC, tr.createdAt ASC
    """)
    fun findByPriorityRange(
        @Param("companyId") companyId: UUID,
        @Param("minPriority") minPriority: Int,
        @Param("maxPriority") maxPriority: Int
    ): List<TransactionRule>

    /**
     * 특정 우선순위보다 높은 규칙들의 우선순위를 1씩 증가
     */
    @Query("""
        UPDATE TransactionRule tr 
        SET tr.priority = tr.priority + 1 
        WHERE tr.companyId = :companyId 
        AND tr.priority >= :priority
    """)
    fun incrementPriorityFrom(
        @Param("companyId") companyId: UUID,
        @Param("priority") priority: Int
    )

    /**
     * 비활성 규칙 조회
     */
    fun findByCompanyIdAndIsActiveFalseOrderByUpdatedAtDesc(companyId: UUID): List<TransactionRule>

    /**
     * 규칙 통계 조회
     */
    @Query("""
        SELECT 
            COUNT(tr) as totalRules,
            SUM(CASE WHEN tr.isActive = true THEN 1 ELSE 0 END) as activeRules,
            SUM(tr.usageCount) as totalUsage,
            SUM(tr.successCount) as totalSuccess,
            AVG(CAST(tr.successCount AS double) / NULLIF(CAST(tr.usageCount AS double), 0)) as averageSuccessRate
        FROM TransactionRule tr 
        WHERE tr.companyId = :companyId
    """)
    fun getRuleStatistics(@Param("companyId") companyId: UUID): List<Any>
}