package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.ExpenseType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 지출 유형 Repository
 */
@Repository
interface ExpenseTypeRepository : JpaRepository<ExpenseType, UUID> {

    /**
     * 회사별 지출 유형 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<ExpenseType>

    /**
     * 회사별 지출 유형 코드로 조회
     */
    fun findByCompanyIdAndTypeCode(companyId: UUID, typeCode: String): ExpenseType?

    /**
     * 회사별 활성 지출 유형 조회
     */
    @Query("""
        SELECT et FROM ExpenseType et 
        WHERE et.companyId = :companyId 
        AND et.isActive = true 
        ORDER BY et.typeName
    """)
    fun findActiveExpenseTypes(@Param("companyId") companyId: UUID): List<ExpenseType>

    /**
     * 카테고리별 지출 유형 조회
     */
    @Query("""
        SELECT et FROM ExpenseType et 
        WHERE et.companyId = :companyId 
        AND et.category = :category 
        AND et.isActive = true
        ORDER BY et.typeName
    """)
    fun findByCategory(
        @Param("companyId") companyId: UUID,
        @Param("category") category: ExpenseType.Category
    ): List<ExpenseType>

    /**
     * 정기 지출 유형 조회
     */
    @Query("""
        SELECT et FROM ExpenseType et 
        WHERE et.companyId = :companyId 
        AND et.isRecurring = true 
        AND et.isActive = true
    """)
    fun findRecurringExpenseTypes(@Param("companyId") companyId: UUID): List<ExpenseType>

    /**
     * 승인이 필요한 지출 유형 조회
     */
    @Query("""
        SELECT et FROM ExpenseType et 
        WHERE et.companyId = :companyId 
        AND et.requiresApproval = true 
        AND et.isActive = true
    """)
    fun findApprovalRequiredTypes(@Param("companyId") companyId: UUID): List<ExpenseType>

    /**
     * 지출 유형 코드 중복 확인
     */
    fun existsByCompanyIdAndTypeCode(companyId: UUID, typeCode: String): Boolean
}