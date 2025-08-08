package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.Account
import com.qiro.domain.accounting.entity.AccountType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 계정과목 Repository
 */
@Repository
interface AccountRepository : JpaRepository<Account, UUID> {

    /**
     * 회사별 계정과목 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<Account>

    /**
     * 회사별 계정 코드로 조회
     */
    fun findByCompanyIdAndAccountCode(companyId: UUID, accountCode: String): Account?

    /**
     * 회사별 계정 유형으로 조회
     */
    fun findByCompanyIdAndAccountTypeAndIsActiveTrue(
        companyId: UUID, 
        accountType: AccountType
    ): List<Account>

    /**
     * 회사별 상위 계정으로 조회
     */
    fun findByCompanyIdAndParentAccountAndIsActiveTrue(
        companyId: UUID, 
        parentAccount: Account
    ): List<Account>

    /**
     * 회사별 최상위 계정 조회 (부모가 없는 계정)
     */
    fun findByCompanyIdAndParentAccountIsNullAndIsActiveTrue(companyId: UUID): List<Account>

    /**
     * 계정 코드 중복 확인
     */
    fun existsByCompanyIdAndAccountCode(companyId: UUID, accountCode: String): Boolean

    /**
     * 계정명으로 검색
     */
    @Query("SELECT a FROM Account a WHERE a.companyId = :companyId AND a.accountName LIKE %:accountName% AND a.isActive = true")
    fun findByCompanyIdAndAccountNameContaining(
        @Param("companyId") companyId: UUID,
        @Param("accountName") accountName: String
    ): List<Account>

    /**
     * 계정 코드 범위로 조회
     */
    @Query("SELECT a FROM Account a WHERE a.companyId = :companyId AND a.accountCode BETWEEN :startCode AND :endCode AND a.isActive = true ORDER BY a.accountCode")
    fun findByCompanyIdAndAccountCodeBetween(
        @Param("companyId") companyId: UUID,
        @Param("startCode") startCode: String,
        @Param("endCode") endCode: String
    ): List<Account>

    /**
     * 계정 계층 구조 조회 (재귀 쿼리)
     */
    @Query("""
        WITH RECURSIVE account_hierarchy AS (
            SELECT a.account_id, a.account_code, a.account_name, a.account_type, 
                   a.parent_account_id, 0 as level, a.account_code as path
            FROM accounts a 
            WHERE a.company_id = :companyId AND a.parent_account_id IS NULL AND a.is_active = true
            
            UNION ALL
            
            SELECT a.account_id, a.account_code, a.account_name, a.account_type,
                   a.parent_account_id, ah.level + 1, ah.path || '.' || a.account_code
            FROM accounts a
            INNER JOIN account_hierarchy ah ON a.parent_account_id = ah.account_id
            WHERE a.is_active = true
        )
        SELECT * FROM account_hierarchy ORDER BY path
    """, nativeQuery = true)
    fun findAccountHierarchy(@Param("companyId") companyId: UUID): List<Any>
}