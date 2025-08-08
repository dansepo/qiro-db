package com.qiro.domain.maintenance.repository

import com.qiro.domain.maintenance.entity.MaintenancePlan
import com.qiro.domain.maintenance.entity.PlanStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 정비 계획 Repository
 * 정기 점검 일정 관리를 위한 데이터 접근 계층입니다.
 */
@Repository
interface MaintenancePlanRepository : JpaRepository<MaintenancePlan, UUID> {

    /**
     * 회사별 정비 계획 조회
     */
    fun findByCompanyIdAndPlanStatus(
        companyId: UUID,
        planStatus: PlanStatus,
        pageable: Pageable
    ): Page<MaintenancePlan>

    /**
     * 자산별 정비 계획 조회
     */
    fun findByAssetIdAndPlanStatus(
        assetId: UUID,
        planStatus: PlanStatus
    ): List<MaintenancePlan>

    /**
     * 계획 코드로 조회
     */
    fun findByCompanyIdAndPlanCode(
        companyId: UUID,
        planCode: String
    ): MaintenancePlan?

    /**
     * 검토 예정인 정비 계획 조회
     */
    @Query("""
        SELECT mp FROM MaintenancePlan mp 
        WHERE mp.companyId = :companyId 
        AND mp.reviewDate <= :reviewDate 
        AND mp.planStatus = 'ACTIVE'
        ORDER BY mp.reviewDate ASC
    """)
    fun findPlansForReview(
        @Param("companyId") companyId: UUID,
        @Param("reviewDate") reviewDate: LocalDate
    ): List<MaintenancePlan>

    /**
     * 다음 정비 일정이 임박한 계획 조회
     */
    @Query("""
        SELECT mp FROM MaintenancePlan mp 
        WHERE mp.companyId = :companyId 
        AND mp.planStatus = 'ACTIVE'
        AND mp.effectiveDate <= :currentDate
        AND NOT EXISTS (
            SELECT 1 FROM PreventiveMaintenanceExecution pme 
            WHERE pme.planId = mp.planId 
            AND pme.executionDate > :lastExecutionDate
            AND pme.executionStatus IN ('COMPLETED', 'IN_PROGRESS')
        )
        ORDER BY mp.effectiveDate ASC
    """)
    fun findPlansNeedingExecution(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate,
        @Param("lastExecutionDate") lastExecutionDate: LocalDate
    ): List<MaintenancePlan>

    /**
     * 자산별 활성 정비 계획 수 조회
     */
    @Query("""
        SELECT COUNT(mp) FROM MaintenancePlan mp 
        WHERE mp.assetId = :assetId 
        AND mp.planStatus = 'ACTIVE'
    """)
    fun countActiveMaintenancePlansByAsset(@Param("assetId") assetId: UUID): Long

    /**
     * 회사별 정비 계획 통계 조회
     */
    @Query("""
        SELECT mp.planStatus, COUNT(mp) 
        FROM MaintenancePlan mp 
        WHERE mp.companyId = :companyId 
        GROUP BY mp.planStatus
    """)
    fun getMaintenancePlanStatistics(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 효과성 점수가 낮은 정비 계획 조회
     */
    @Query("""
        SELECT mp FROM MaintenancePlan mp 
        WHERE mp.companyId = :companyId 
        AND mp.effectivenessScore < :minScore 
        AND mp.planStatus = 'ACTIVE'
        ORDER BY mp.effectivenessScore ASC
    """)
    fun findLowEffectivenessPlan(
        @Param("companyId") companyId: UUID,
        @Param("minScore") minScore: Double
    ): List<MaintenancePlan>

    /**
     * 예산 초과 위험이 있는 정비 계획 조회
     */
    @Query("""
        SELECT mp FROM MaintenancePlan mp 
        WHERE mp.companyId = :companyId 
        AND mp.actualCostYtd > (mp.targetCostPerYear * :thresholdRatio)
        AND mp.planStatus = 'ACTIVE'
        ORDER BY (mp.actualCostYtd / mp.targetCostPerYear) DESC
    """)
    fun findBudgetRiskPlans(
        @Param("companyId") companyId: UUID,
        @Param("thresholdRatio") thresholdRatio: Double
    ): List<MaintenancePlan>

    /**
     * 특정 기간 내 실행 예정인 정비 계획 조회
     */
    @Query("""
        SELECT DISTINCT mp FROM MaintenancePlan mp 
        LEFT JOIN PreventiveMaintenanceExecution pme ON mp.planId = pme.planId
        WHERE mp.companyId = :companyId 
        AND mp.planStatus = 'ACTIVE'
        AND (
            (pme.executionDate BETWEEN :startDate AND :endDate AND pme.executionStatus IN ('PLANNED', 'SCHEDULED'))
            OR (
                pme.executionId IS NULL 
                AND mp.effectiveDate <= :endDate
            )
        )
        ORDER BY COALESCE(pme.executionDate, mp.effectiveDate) ASC
    """)
    fun findPlansInPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<MaintenancePlan>
}