package com.qiro.domain.maintenance.repository

import com.qiro.domain.maintenance.entity.MaintenanceTaskExecution
import com.qiro.domain.maintenance.entity.TaskExecutionStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 정비 작업 실행 Repository
 * 개별 작업 실행 결과 관리를 위한 데이터 접근 계층입니다.
 */
@Repository
interface MaintenanceTaskExecutionRepository : JpaRepository<MaintenanceTaskExecution, UUID> {

    /**
     * 실행별 작업 실행 내역 조회 (순서대로)
     */
    fun findByExecutionIdOrderByTaskSequenceAsc(executionId: UUID): List<MaintenanceTaskExecution>

    /**
     * 작업별 실행 내역 조회
     */
    fun findByTaskIdOrderByCreatedAtDesc(taskId: UUID): List<MaintenanceTaskExecution>

    /**
     * 실행별 특정 상태의 작업 조회
     */
    fun findByExecutionIdAndExecutionStatusOrderByTaskSequenceAsc(
        executionId: UUID,
        executionStatus: TaskExecutionStatus
    ): List<MaintenanceTaskExecution>

    /**
     * 실행별 완료된 작업 수 조회
     */
    @Query("""
        SELECT COUNT(mte) FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId 
        AND mte.executionStatus = 'COMPLETED'
    """)
    fun countCompletedTasksByExecution(@Param("executionId") executionId: UUID): Long

    /**
     * 실행별 전체 작업 수 조회
     */
    @Query("""
        SELECT COUNT(mte) FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId
    """)
    fun countTotalTasksByExecution(@Param("executionId") executionId: UUID): Long

    /**
     * 실행별 진행률 계산
     */
    @Query("""
        SELECT 
            CASE 
                WHEN COUNT(mte) = 0 THEN 0.0
                ELSE (COUNT(CASE WHEN mte.executionStatus = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(mte))
            END
        FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId
    """)
    fun calculateExecutionProgress(@Param("executionId") executionId: UUID): Double

    /**
     * 품질 검사를 통과하지 못한 작업 조회
     */
    fun findByExecutionIdAndQualityCheckPassedFalseOrderByTaskSequenceAsc(
        executionId: UUID
    ): List<MaintenanceTaskExecution>

    /**
     * 후속 조치가 필요한 작업 조회
     */
    fun findByExecutionIdAndRequiresFollowUpTrueOrderByTaskSequenceAsc(
        executionId: UUID
    ): List<MaintenanceTaskExecution>

    /**
     * 문제가 발견된 작업 조회
     */
    @Query("""
        SELECT mte FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId 
        AND mte.issuesFound IS NOT NULL
        AND mte.issuesFound != ''
        ORDER BY mte.taskSequence ASC
    """)
    fun findTasksWithIssues(@Param("executionId") executionId: UUID): List<MaintenanceTaskExecution>

    /**
     * 실행자별 작업 실행 내역 조회
     */
    fun findByExecutedByOrderByCreatedAtDesc(executedBy: UUID): List<MaintenanceTaskExecution>

    /**
     * 작업 실행 통계 조회
     */
    @Query("""
        SELECT mte.executionStatus, COUNT(mte) 
        FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId
        GROUP BY mte.executionStatus
    """)
    fun getTaskExecutionStatistics(@Param("executionId") executionId: UUID): List<Array<Any>>

    /**
     * 평균 작업 시간 조회
     */
    @Query("""
        SELECT AVG(mte.actualDurationMinutes) 
        FROM MaintenanceTaskExecution mte 
        WHERE mte.taskId = :taskId 
        AND mte.executionStatus = 'COMPLETED'
        AND mte.actualDurationMinutes > 0
    """)
    fun getAverageTaskDuration(@Param("taskId") taskId: UUID): Double?

    /**
     * 작업별 성공률 조회
     */
    @Query("""
        SELECT 
            CASE 
                WHEN COUNT(mte) = 0 THEN 0.0
                ELSE (COUNT(CASE WHEN mte.executionStatus = 'COMPLETED' AND mte.qualityCheckPassed = true THEN 1 END) * 100.0 / COUNT(mte))
            END
        FROM MaintenanceTaskExecution mte 
        WHERE mte.taskId = :taskId
    """)
    fun getTaskSuccessRate(@Param("taskId") taskId: UUID): Double

    /**
     * 실행 중인 작업 조회
     */
    fun findByExecutionStatusAndExecutedByOrderByStartedAtAsc(
        executionStatus: TaskExecutionStatus,
        executedBy: UUID
    ): List<MaintenanceTaskExecution>

    /**
     * 지연된 작업 조회 (예상 시간 초과)
     */
    @Query("""
        SELECT mte FROM MaintenanceTaskExecution mte 
        JOIN MaintenanceTask mt ON mte.taskId = mt.taskId
        WHERE mte.executionStatus = 'IN_PROGRESS'
        AND mte.startedAt IS NOT NULL
        AND EXTRACT(EPOCH FROM (NOW() - mte.startedAt))/60 > mt.estimatedDurationMinutes * 1.5
        ORDER BY mte.startedAt ASC
    """)
    fun findDelayedTasks(): List<MaintenanceTaskExecution>

    /**
     * 실행별 총 비용 계산
     */
    @Query("""
        SELECT COALESCE(SUM(mte.taskCost), 0) 
        FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId
    """)
    fun calculateTotalCostByExecution(@Param("executionId") executionId: UUID): Double

    /**
     * 실행별 총 작업 시간 계산
     */
    @Query("""
        SELECT COALESCE(SUM(mte.laborHours), 0) 
        FROM MaintenanceTaskExecution mte 
        WHERE mte.executionId = :executionId
        AND mte.executionStatus = 'COMPLETED'
    """)
    fun calculateTotalLaborHoursByExecution(@Param("executionId") executionId: UUID): Double
}