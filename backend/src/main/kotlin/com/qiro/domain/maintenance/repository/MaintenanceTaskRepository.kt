package com.qiro.domain.maintenance.repository

import com.qiro.domain.maintenance.entity.MaintenanceTask
import com.qiro.domain.maintenance.entity.TaskType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 정비 작업 Repository
 * 점검 체크리스트 관리를 위한 데이터 접근 계층입니다.
 */
@Repository
interface MaintenanceTaskRepository : JpaRepository<MaintenanceTask, UUID> {

    /**
     * 정비 계획별 작업 목록 조회 (순서대로)
     */
    fun findByPlanIdAndIsActiveTrueOrderByTaskSequenceAsc(planId: UUID): List<MaintenanceTask>

    /**
     * 정비 계획별 특정 작업 유형 조회
     */
    fun findByPlanIdAndTaskTypeAndIsActiveTrue(
        planId: UUID,
        taskType: TaskType
    ): List<MaintenanceTask>

    /**
     * 회사별 작업 템플릿 조회
     */
    @Query("""
        SELECT mt FROM MaintenanceTask mt 
        WHERE mt.companyId = :companyId 
        AND mt.isActive = true
        ORDER BY mt.taskType, mt.taskName
    """)
    fun findTaskTemplatesByCompany(@Param("companyId") companyId: UUID): List<MaintenanceTask>

    /**
     * 중요 작업 조회
     */
    fun findByPlanIdAndIsCriticalTrueAndIsActiveTrueOrderByTaskSequenceAsc(
        planId: UUID
    ): List<MaintenanceTask>

    /**
     * 특정 기술 수준이 필요한 작업 조회
     */
    @Query("""
        SELECT mt FROM MaintenanceTask mt 
        WHERE mt.planId = :planId 
        AND mt.requiredSkillLevel IN :skillLevels
        AND mt.isActive = true
        ORDER BY mt.taskSequence
    """)
    fun findTasksBySkillLevel(
        @Param("planId") planId: UUID,
        @Param("skillLevels") skillLevels: List<String>
    ): List<MaintenanceTask>

    /**
     * 점검이 필요한 작업 조회
     */
    fun findByPlanIdAndInspectionRequiredTrueAndIsActiveTrueOrderByTaskSequenceAsc(
        planId: UUID
    ): List<MaintenanceTask>

    /**
     * 측정이 필요한 작업 조회
     */
    fun findByPlanIdAndMeasurementRequiredTrueAndIsActiveTrueOrderByTaskSequenceAsc(
        planId: UUID
    ): List<MaintenanceTask>

    /**
     * 사진 촬영이 필요한 작업 조회
     */
    fun findByPlanIdAndPhotoRequiredTrueAndIsActiveTrueOrderByTaskSequenceAsc(
        planId: UUID
    ): List<MaintenanceTask>

    /**
     * 작업 순서 중복 확인
     */
    fun existsByPlanIdAndTaskSequenceAndIsActiveTrue(
        planId: UUID,
        taskSequence: Int
    ): Boolean

    /**
     * 계획별 작업 수 조회
     */
    @Query("""
        SELECT COUNT(mt) FROM MaintenanceTask mt 
        WHERE mt.planId = :planId 
        AND mt.isActive = true
    """)
    fun countActiveTasksByPlan(@Param("planId") planId: UUID): Long

    /**
     * 작업 유형별 통계 조회
     */
    @Query("""
        SELECT mt.taskType, COUNT(mt) 
        FROM MaintenanceTask mt 
        WHERE mt.companyId = :companyId 
        AND mt.isActive = true
        GROUP BY mt.taskType
        ORDER BY COUNT(mt) DESC
    """)
    fun getTaskTypeStatistics(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 평균 작업 시간이 긴 작업 조회
     */
    @Query("""
        SELECT mt FROM MaintenanceTask mt 
        WHERE mt.companyId = :companyId 
        AND mt.estimatedDurationMinutes > :minDuration
        AND mt.isActive = true
        ORDER BY mt.estimatedDurationMinutes DESC
    """)
    fun findLongDurationTasks(
        @Param("companyId") companyId: UUID,
        @Param("minDuration") minDuration: Int
    ): List<MaintenanceTask>

    /**
     * 다음 작업 순서 번호 조회
     */
    @Query("""
        SELECT COALESCE(MAX(mt.taskSequence), 0) + 1 
        FROM MaintenanceTask mt 
        WHERE mt.planId = :planId
    """)
    fun getNextTaskSequence(@Param("planId") planId: UUID): Int
}