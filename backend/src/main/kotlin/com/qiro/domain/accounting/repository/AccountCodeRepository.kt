package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.AccountCode
import com.qiro.domain.accounting.entity.AccountType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 계정과목 리포지토리
 */
@Repository
interface AccountCodeRepository : JpaRepository<AccountCode, Long> {

    /**
     * 회사별 계정과목 조회
     */
    fun findByCompanyCompanyIdAndIsActiveTrue(companyId: UUID): List<AccountCode>

    /**
     * 회사별 계정과목 페이징 조회
     */
    fun findByCompanyCompanyId(companyId: UUID, pageable: Pageable): Page<AccountCode>

    /**
     * 회사별 활성 계정과목 페이징 조회
     */
    fun findByCompanyCompanyIdAndIsActiveTrue(companyId: UUID, pageable: Pageable): Page<AccountCode>

    /**
     * 계정과목 코드로 조회
     */
    fun findByCompanyCompanyIdAndAccountCode(companyId: UUID, accountCode: String): AccountCode?

    /**
     * 계정 유형별 조회
     */
    fun findByCompanyCompanyIdAndAccountTypeAndIsActiveTrue(
        companyId: UUID,
        accountType: AccountType
    ): List<AccountCode>

    /**
     * 상위 계정과목별 하위 계정 조회
     */
    fun findByParentAccountIdAndIsActiveTrue(parentAccountId: Long): List<AccountCode>

    /**
     * 최상위 계정과목 조회 (부모가 없는 계정)
     */
    fun findByCompanyCompanyIdAndParentAccountIsNullAndIsActiveTrue(companyId: UUID): List<AccountCode>

    /**
     * 계정과목 코드 중복 확인
     */
    fun existsByCompanyCompanyIdAndAccountCode(companyId: UUID, accountCode: String): Boolean

    /**
     * 계정과목명으로 검색
     */
    @Query("""
        SELECT ac FROM AccountCode ac 
        WHERE ac.company.companyId = :companyId 
        AND (:accountName IS NULL OR ac.accountName LIKE %:accountName%)
        AND (:isActive IS NULL OR ac.isActive = :isActive)
        ORDER BY ac.accountCode
    """)
    fun searchByAccountName(
        @Param("companyId") companyId: UUID,
        @Param("accountName") accountName: String?,
        @Param("isActive") isActive: Boolean?,
        pageable: Pageable
    ): Page<AccountCode>

    /**
     * 복합 검색 조건으로 계정과목 조회
     */
    @Query("""
        SELECT ac FROM AccountCode ac 
        WHERE ac.company.companyId = :companyId 
        AND (:accountCode IS NULL OR ac.accountCode LIKE %:accountCode%)
        AND (:accountName IS NULL OR ac.accountName LIKE %:accountName%)
        AND (:accountType IS NULL OR ac.accountType = :accountType)
        AND (:parentAccountId IS NULL OR ac.parentAccount.id = :parentAccountId)
        AND (:accountLevel IS NULL OR ac.accountLevel = :accountLevel)
        AND (:activeOnly = false OR ac.isActive = true)
        AND (:includeSystemAccounts = true OR ac.isSystemAccount = false)
        ORDER BY ac.accountCode
    """)
    fun searchAccountCodes(
        @Param("companyId") companyId: UUID,
        @Param("accountCode") accountCode: String?,
        @Param("accountName") accountName: String?,
        @Param("accountType") accountType: AccountType?,
        @Param("parentAccountId") parentAccountId: Long?,
        @Param("accountLevel") accountLevel: Int?,
        @Param("activeOnly") activeOnly: Boolean,
        @Param("includeSystemAccounts") includeSystemAccounts: Boolean,
        pageable: Pageable
    ): Page<AccountCode>

    /**
     * 계정 유형별 통계
     */
    @Query("""
        SELECT ac.accountType, COUNT(ac) 
        FROM AccountCode ac 
        WHERE ac.company.companyId = :companyId 
        AND ac.isActive = true
        GROUP BY ac.accountType
    """)
    fun getAccountTypeStatistics(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 계정 레벨별 통계
     */
    @Query("""
        SELECT ac.accountLevel, COUNT(ac) 
        FROM AccountCode ac 
        WHERE ac.company.companyId = :companyId 
        AND ac.isActive = true
        GROUP BY ac.accountLevel
        ORDER BY ac.accountLevel
    """)
    fun getAccountLevelStatistics(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 활성 계정과목 수 조회
     */
    fun countByCompanyCompanyIdAndIsActiveTrue(companyId: UUID): Long

    /**
     * 전체 계정과목 수 조회
     */
    fun countByCompanyCompanyId(companyId: UUID): Long

    /**
     * 다음 계정과목 코드 생성을 위한 최대 코드 조회
     */
    @Query("""
        SELECT MAX(ac.accountCode) 
        FROM AccountCode ac 
        WHERE ac.company.companyId = :companyId 
        AND ac.accountType = :accountType
        AND ac.accountCode LIKE :codePrefix%
    """)
    fun findMaxAccountCodeByTypeAndPrefix(
        @Param("companyId") companyId: UUID,
        @Param("accountType") accountType: AccountType,
        @Param("codePrefix") codePrefix: String
    ): String?

    /**
     * 하위 계정과목이 있는지 확인
     */
    fun existsByParentAccountId(parentAccountId: Long): Boolean

    /**
     * 시스템 계정과목 조회
     */
    fun findByCompanyCompanyIdAndIsSystemAccountTrue(companyId: UUID): List<AccountCode>
}