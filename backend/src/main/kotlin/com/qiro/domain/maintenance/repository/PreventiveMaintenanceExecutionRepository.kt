package com.qiro.domain.maintenance.repository

import com.qiro.domain.maintenance.entity.ExecutionStatus
import com.qiro.domain.maintenance.entity.ExecutionType
import com.qiro.domain.maintenance.entity.PreventiveMaintenanceExecution
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예방 정비 실행 Repository
 * 자동 정비 일정 생성 및 알림을 위한 데이터 접근 계층입니다.
 */
@Repository
interface PreventiveMaintenanceExecutionRepository : JpaRepository<PreventiveMaintenanceExecution, UUID> {

    /**
     * 회사별 실행 내역 조회
     */
    fun findByCompanyIdOrderByExecutionDateDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<PreventiveMaintenanceExecution>

    /**
     * 계획별 실행 내역 조회
     */
    fun findByPlanIdOrderByExecutionDateDesc(planId: UUID): List<PreventiveMaintenanceExecution>

    /**
     * 자산별 실행 내역 조회
     */
    fun findByAssetIdOrderByExecutionDateDesc(assetId: UUID): List<PreventiveMaintenanceExecution>

    /**
     * 실행 번호로 조회
     */
    fun findByCompanyIdAndExecutionNumber(
        companyId: UUID,
        executionNumber: String
    ): PreventiveMaintenanceExecution?

    /**
     * 특정 날짜의 실행 예정 작업 조회
     */
    fun findByCompanyIdAndExecutionDateAndExecutionStatusIn(
        companyId: UUID,
        executionDate: LocalDate,
        executionStatuses: List<ExecutionStatus>
    ): List<PreventiveMaintenanceExecution>

    /**
     * 기간별 실행 내역 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate BETWEEN :startDate AND :endDate
        ORDER BY pme.executionDate DESC, pme.plannedStartTime ASC
    """)
    fun findExecutionsInPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<PreventiveMaintenanceExecution>

    /**
     * 상태별 실행 내역 조회
     */
    fun findByCompanyIdAndExecutionStatusOrderByExecutionDateAsc(
        companyId: UUID,
        executionStatus: ExecutionStatus
    ): List<PreventiveMaintenanceExecution>

    /**
     * 담당 기술자별 실행 내역 조회
     */
    fun findByLeadTechnicianIdAndExecutionStatusInOrderByExecutionDateAsc(
        leadTechnicianId: UUID,
        executionStatuses: List<ExecutionStatus>
    ): List<PreventiveMaintenanceExecution>

    /**
     * 지연된 실행 작업 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate < :currentDate
        AND pme.executionStatus IN ('PLANNED', 'SCHEDULED')
        ORDER BY pme.executionDate ASC
    """)
    fun findOverdueExecutions(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate
    ): List<PreventiveMaintenanceExecution>

    /**
     * 오늘 실행 예정인 작업 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate = :today
        AND pme.executionStatus IN ('PLANNED', 'SCHEDULED')
        ORDER BY pme.plannedStartTime ASC
    """)
    fun findTodayExecutions(
        @Param("companyId") companyId: UUID,
        @Param("today") today: LocalDate
    ): List<PreventiveMaintenanceExecution>

    /**
     * 다음 주 실행 예정인 작업 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate BETWEEN :startDate AND :endDate
        AND pme.executionStatus IN ('PLANNED', 'SCHEDULED')
        ORDER BY pme.executionDate ASC, pme.plannedStartTime ASC
    """)
    fun findUpcomingExecutions(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<PreventiveMaintenanceExecution>

    /**
     * 진행 중인 작업 조회
     */
    fun findByCompanyIdAndExecutionStatusOrderByActualStartTimeAsc(
        companyId: UUID,
        executionStatus: ExecutionStatus
    ): List<PreventiveMaintenanceExecution>

    /**
     * 최근 완료된 작업 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionStatus = 'COMPLETED'
        AND pme.workCompletionDate >= :sinceDate
        ORDER BY pme.workCompletionDate DESC
    """)
    fun findRecentlyCompletedExecutions(
        @Param("companyId") companyId: UUID,
        @Param("sinceDate") sinceDate: LocalDateTime
    ): List<PreventiveMaintenanceExecution>

    /**
     * 자산별 마지막 실행 내역 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.assetId = :assetId 
        AND pme.executionStatus = 'COMPLETED'
        ORDER BY pme.executionDate DESC
        LIMIT 1
    """)
    fun findLastCompletedExecutionByAsset(@Param("assetId") assetId: UUID): PreventiveMaintenanceExecution?

    /**
     * 계획별 마지막 실행 내역 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.planId = :planId 
        AND pme.executionStatus = 'COMPLETED'
        ORDER BY pme.executionDate DESC
        LIMIT 1
    """)
    fun findLastCompletedExecutionByPlan(@Param("planId") planId: UUID): PreventiveMaintenanceExecution?

    /**
     * 실행 통계 조회
     */
    @Query("""
        SELECT pme.executionStatus, COUNT(pme) 
        FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate BETWEEN :startDate AND :endDate
        GROUP BY pme.executionStatus
    """)
    fun getExecutionStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 실행 유형별 통계 조회
     */
    @Query("""
        SELECT pme.executionType, COUNT(pme) 
        FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionDate BETWEEN :startDate AND :endDate
        GROUP BY pme.executionType
        ORDER BY COUNT(pme) DESC
    """)
    fun getExecutionTypeStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 다음 실행 번호 생성을 위한 시퀀스 조회
     */
    @Query("""
        SELECT COUNT(pme) + 1 
        FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.executionNumber LIKE :prefix%
    """)
    fun getNextExecutionSequence(
        @Param("companyId") companyId: UUID,
        @Param("prefix") prefix: String
    ): Long

    /**
     * 품질 평가가 낮은 실행 내역 조회
     */
    @Query("""
        SELECT pme FROM PreventiveMaintenanceExecution pme 
        WHERE pme.companyId = :companyId 
        AND pme.workQualityRating < :minRating
        AND pme.executionStatus = 'COMPLETED'
        ORDER BY pme.workQualityRating ASC, pme.executionDate DESC
    """)
    fun findLowQualityExecutions(
        @Param("companyId") companyId: UUID,
        @Param("minRating") minRating: Double
    ): List<PreventiveMaintenanceExecution>
}