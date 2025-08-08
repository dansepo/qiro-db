package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.LateFeePolicy
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 연체료 정책 Repository
 */
@Repository
interface LateFeePolicyRepository : JpaRepository<LateFeePolicy, UUID> {

    /**
     * 회사별 활성 연체료 정책 조회
     */
    fun findByCompanyIdAndIsActiveTrueOrderByEffectiveFromDesc(companyId: UUID): List<LateFeePolicy>

    /**
     * 수입 유형별 활성 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.incomeType.incomeTypeId = :incomeTypeId 
        AND lfp.isActive = true 
        ORDER BY lfp.effectiveFrom DESC
    """)
    fun findByIncomeType(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID
    ): List<LateFeePolicy>

    /**
     * 특정 날짜에 유효한 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.incomeType.incomeTypeId = :incomeTypeId 
        AND lfp.isActive = true 
        AND lfp.effectiveFrom <= :date 
        AND (lfp.effectiveTo IS NULL OR lfp.effectiveTo >= :date)
        ORDER BY lfp.effectiveFrom DESC
    """)
    fun findEffectivePolicy(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): LateFeePolicy?

    /**
     * 정책명으로 연체료 정책 조회
     */
    fun findByCompanyIdAndPolicyName(companyId: UUID, policyName: String): LateFeePolicy?

    /**
     * 만료된 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.effectiveTo IS NOT NULL 
        AND lfp.effectiveTo < :date
    """)
    fun findExpiredPolicies(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): List<LateFeePolicy>

    /**
     * 곧 만료될 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.isActive = true 
        AND lfp.effectiveTo IS NOT NULL 
        AND lfp.effectiveTo BETWEEN :date AND :endDate
    """)
    fun findExpiringPolicies(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now(),
        @Param("endDate") endDate: LocalDate = LocalDate.now().plusDays(30)
    ): List<LateFeePolicy>

    /**
     * 연체료 정책 중복 확인
     */
    @Query("""
        SELECT COUNT(lfp) > 0 FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.incomeType.incomeTypeId = :incomeTypeId 
        AND lfp.isActive = true 
        AND lfp.effectiveFrom <= :endDate 
        AND (lfp.effectiveTo IS NULL OR lfp.effectiveTo >= :startDate)
        AND (:policyId IS NULL OR lfp.policyId != :policyId)
    """)
    fun hasOverlappingPolicy(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate?,
        @Param("policyId") policyId: UUID?
    ): Boolean

    // Service에서 필요한 추가 메서드들
    
    /**
     * 회사별 및 수입 유형별 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.incomeType.id = :incomeTypeId 
        AND lfp.isActive = true 
        ORDER BY lfp.effectiveFrom DESC
    """)
    fun findByCompanyIdAndIncomeTypeId(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID?
    ): LateFeePolicy?

    /**
     * 회사별 기본 연체료 정책 조회
     */
    @Query("""
        SELECT lfp FROM LateFeePolicy lfp 
        WHERE lfp.companyId = :companyId 
        AND lfp.incomeType IS NULL 
        AND lfp.isActive = true 
        ORDER BY lfp.effectiveFrom DESC
    """)
    fun findDefaultByCompanyId(@Param("companyId") companyId: UUID): LateFeePolicy?
}