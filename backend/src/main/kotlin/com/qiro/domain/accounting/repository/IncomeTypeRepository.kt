package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.IncomeType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 수입 유형 Repository
 */
@Repository
interface IncomeTypeRepository : JpaRepository<IncomeType, UUID> {

    /**
     * 회사별 수입 유형 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<IncomeType>

    /**
     * 회사별 수입 유형 코드로 조회
     */
    fun findByCompanyIdAndTypeCode(companyId: UUID, typeCode: String): IncomeType?

    /**
     * 회사별 활성 수입 유형 조회
     */
    @Query("""
        SELECT it FROM IncomeType it 
        WHERE it.companyId = :companyId 
        AND it.isActive = true 
        ORDER BY it.typeName
    """)
    fun findActiveIncomeTypes(@Param("companyId") companyId: UUID): List<IncomeType>

    /**
     * 정기 수입 유형 조회
     */
    @Query("""
        SELECT it FROM IncomeType it 
        WHERE it.companyId = :companyId 
        AND it.isRecurring = true 
        AND it.isActive = true
    """)
    fun findRecurringIncomeTypes(@Param("companyId") companyId: UUID): List<IncomeType>

    /**
     * 수입 유형 코드 중복 확인
     */
    fun existsByCompanyIdAndTypeCode(companyId: UUID, typeCode: String): Boolean
}