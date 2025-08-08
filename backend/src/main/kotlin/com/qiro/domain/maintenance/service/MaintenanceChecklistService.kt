package com.qiro.domain.maintenance.service

import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.entity.*
import com.qiro.domain.maintenance.repository.MaintenanceTaskRepository
import com.qiro.domain.maintenance.repository.MaintenanceTaskExecutionRepository
import com.qiro.domain.maintenance.repository.PreventiveMaintenanceExecutionRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 정비 체크리스트 서비스
 * 점검 체크리스트 관리 시스템을 제공합니다.
 */
@Service
@Transactional
class MaintenanceChecklistService(
    private val maintenanceTaskRepository: MaintenanceTaskRepository,
    private val maintenanceTaskExecutionRepository: MaintenanceTaskExecutionRepository,
    private val preventiveMaintenanceExecutionRepository: PreventiveMaintenanceExecutionRepository
) {
    private val logger = LoggerFactory.getLogger(MaintenanceChecklistService::class.java)

    /**
     * 정비 작업 생성
     */
    fun createMaintenanceTask(request: CreateMaintenanceTaskRequest): MaintenanceTaskDto {
        logger.info("정비 작업 생성 시작: planId={}, taskName={}", request.planId, request.taskName)

        // 작업 순서 중복 확인
        if (maintenanceTaskRepository.existsByPlanIdAndTaskSequenceAndIsActiveTrue(request.planId, request.taskSequence)) {
            throw IllegalArgumentException("이미 존재하는 작업 순서입니다: ${request.taskSequence}")
        }

        val maintenanceTask = MaintenanceTask(
            companyId = request.companyId,
            planId = request.planId,
            taskSequence = request.taskSequence,
            taskName = request.taskName,
            taskDescription = request.taskDescription,
            taskType = request.taskType,
            taskInstructions = request.taskInstructions,
            safetyPrecautions = request.safetyPrecautions,
            qualityStandards = request.qualityStandards,
            estimatedDurationMinutes = request.estimatedDurationMinutes,
            requiredSkillLevel = request.requiredSkillLevel,
            requiredTools = request.requiredTools,
            requiredParts = request.requiredParts,
            prerequisiteTasks = request.prerequisiteTasks,
            environmentalConditions = request.environmentalConditions,
            equipmentStateRequired = request.equipmentStateRequired,
            inspectionRequired = request.inspectionRequired,
            measurementRequired = request.measurementRequired,
            documentationRequired = request.documentationRequired,
            photoRequired = request.photoRequired,
            acceptanceCriteria = request.acceptanceCriteria,
            measurementPoints = request.measurementPoints,
            toleranceSpecifications = request.toleranceSpecifications,
            isCritical = request.isCritical,
            createdBy = request.createdBy
        )

        val savedTask = maintenanceTaskRepository.save(maintenanceTask)
        logger.info("정비 작업 생성 완료: taskId={}", savedTask.taskId)

        return convertToDto(savedTask)
    }

    /**
     * 정비 실행 시 작업 체크리스트 생성
     */
    fun createTaskExecutionsForMaintenance(executionId: UUID): List<MaintenanceTaskExecutionDto> {
        logger.info("정비 실행 작업 체크리스트 생성 시작: executionId={}", executionId)

        val execution = preventiveMaintenanceExecutionRepository.findById(executionId)
            .orElseThrow { IllegalArgumentException("정비 실행을 찾을 수 없습니다: $executionId") }

        val tasks = maintenanceTaskRepository.findByPlanIdAndIsActiveTrueOrderByTaskSequenceAsc(execution.planId)

        val taskExecutions = tasks.map { task ->
            MaintenanceTaskExecution(
                executionId = executionId,
                taskId = task.taskId,
                taskSequence = task.taskSequence,
                taskName = task.taskName,
                executionStatus = TaskExecutionStatus.PENDING
            )
        }

        val savedExecutions = maintenanceTaskExecutionRepository.saveAll(taskExecutions)
        logger.info("정비 실행 작업 체크리스트 생성 완료: 생성된 작업 수={}", savedExecutions.size)

        return savedExecutions.map { convertToDto(it) }
    }

    /**
     * 작업 실행 시작
     */
    fun startTaskExecution(taskExecutionId: UUID, executedBy: UUID): MaintenanceTaskExecutionDto {
        logger.info("작업 실행 시작: taskExecutionId={}, executedBy={}", taskExecutionId, executedBy)

        val taskExecution = maintenanceTaskExecutionRepository.findById(taskExecutionId)
            .orElseThrow { IllegalArgumentException("작업 실행을 찾을 수 없습니다: $taskExecutionId") }

        if (taskExecution.executionStatus != TaskExecutionStatus.PENDING) {
            throw IllegalStateException("이미 시작된 작업입니다: ${taskExecution.executionStatus}")
        }

        val updatedExecution = taskExecution.copy(
            executionStatus = TaskExecutionStatus.IN_PROGRESS,
            startedAt = LocalDateTime.now(),
            executedBy = executedBy,
            updatedBy = executedBy
        )

        val savedExecution = maintenanceTaskExecutionRepository.save(updatedExecution)
        logger.info("작업 실행 시작 완료: taskExecutionId={}", savedExecution.taskExecutionId)

        return convertToDto(savedExecution)
    }

    /**
     * 작업 실행 완료
     */
    fun completeTaskExecution(
        taskExecutionId: UUID,
        request: CompleteTaskExecutionRequest
    ): MaintenanceTaskExecutionDto {
        logger.info("작업 실행 완료: taskExecutionId={}", taskExecutionId)

        val taskExecution = maintenanceTaskExecutionRepository.findById(taskExecutionId)
            .orElseThrow { IllegalArgumentException("작업 실행을 찾을 수 없습니다: $taskExecutionId") }

        if (taskExecution.executionStatus != TaskExecutionStatus.IN_PROGRESS) {
            throw IllegalStateException("진행 중이 아닌 작업은 완료할 수 없습니다: ${taskExecution.executionStatus}")
        }

        val completedAt = LocalDateTime.now()
        val actualDuration = if (taskExecution.startedAt != null) {
            java.time.Duration.between(taskExecution.startedAt, completedAt).toMinutes().toInt()
        } else {
            0
        }

        val updatedExecution = taskExecution.copy(
            executionStatus = TaskExecutionStatus.COMPLETED,
            completedAt = completedAt,
            actualDurationMinutes = actualDuration,
            executionNotes = request.executionNotes,
            qualityCheckPassed = request.qualityCheckPassed,
            qualityCheckNotes = request.qualityCheckNotes,
            measurementsTaken = request.measurementsTaken,
            photosTaken = request.photosTaken,
            partsUsed = request.partsUsed,
            toolsUsed = request.toolsUsed,
            issuesFound = request.issuesFound,
            correctiveActions = request.correctiveActions,
            taskCost = request.taskCost,
            laborHours = request.laborHours,
            materialCost = request.materialCost,
            completionPercentage = BigDecimal("100.00"),
            requiresFollowUp = request.requiresFollowUp,
            followUpNotes = request.followUpNotes,
            updatedBy = request.completedBy
        )

        val savedExecution = maintenanceTaskExecutionRepository.save(updatedExecution)

        // 전체 정비 실행의 진행률 업데이트
        updateMaintenanceExecutionProgress(taskExecution.executionId)

        logger.info("작업 실행 완료: taskExecutionId={}, duration={}분", 
                   savedExecution.taskExecutionId, actualDuration)

        return convertToDto(savedExecution)
    }

    /**
     * 작업 건너뛰기
     */
    fun skipTaskExecution(
        taskExecutionId: UUID,
        reason: String,
        skippedBy: UUID
    ): MaintenanceTaskExecutionDto {
        logger.info("작업 건너뛰기: taskExecutionId={}, reason={}", taskExecutionId, reason)

        val taskExecution = maintenanceTaskExecutionRepository.findById(taskExecutionId)
            .orElseThrow { IllegalArgumentException("작업 실행을 찾을 수 없습니다: $taskExecutionId") }

        val updatedExecution = taskExecution.copy(
            executionStatus = TaskExecutionStatus.SKIPPED,
            executionNotes = reason,
            completionPercentage = BigDecimal.ZERO,
            updatedBy = skippedBy
        )

        val savedExecution = maintenanceTaskExecutionRepository.save(updatedExecution)

        // 전체 정비 실행의 진행률 업데이트
        updateMaintenanceExecutionProgress(taskExecution.executionId)

        logger.info("작업 건너뛰기 완료: taskExecutionId={}", savedExecution.taskExecutionId)

        return convertToDto(savedExecution)
    }

    /**
     * 정비 실행 진행률 업데이트
     */
    private fun updateMaintenanceExecutionProgress(executionId: UUID) {
        val progress = maintenanceTaskExecutionRepository.calculateExecutionProgress(executionId)
        
        preventiveMaintenanceExecutionRepository.findById(executionId)?.let { execution ->
            val updatedExecution = execution.copy(
                completionPercentage = BigDecimal.valueOf(progress),
                updatedAt = LocalDateTime.now()
            )
            preventiveMaintenanceExecutionRepository.save(updatedExecution)
            
            logger.debug("정비 실행 진행률 업데이트: executionId={}, progress={}%", executionId, progress)
        }
    }

    /**
     * 정비 계획별 작업 목록 조회
     */
    @Transactional(readOnly = true)
    fun getMaintenanceTasksByPlan(planId: UUID): List<MaintenanceTaskDto> {
        val tasks = maintenanceTaskRepository.findByPlanIdAndIsActiveTrueOrderByTaskSequenceAsc(planId)
        return tasks.map { convertToDto(it) }
    }

    /**
     * 정비 실행별 작업 체크리스트 조회
     */
    @Transactional(readOnly = true)
    fun getTaskExecutionsByMaintenance(executionId: UUID): List<MaintenanceTaskExecutionDto> {
        val taskExecutions = maintenanceTaskExecutionRepository.findByExecutionIdOrderByTaskSequenceAsc(executionId)
        return taskExecutions.map { convertToDto(it) }
    }

    /**
     * 중요 작업 조회
     */
    @Transactional(readOnly = true)
    fun getCriticalTasksByPlan(planId: UUID): List<MaintenanceTaskDto> {
        val tasks = maintenanceTaskRepository.findByPlanIdAndIsCriticalTrueAndIsActiveTrueOrderByTaskSequenceAsc(planId)
        return tasks.map { convertToDto(it) }
    }

    /**
     * 점검이 필요한 작업 조회
     */
    @Transactional(readOnly = true)
    fun getInspectionTasksByPlan(planId: UUID): List<MaintenanceTaskDto> {
        val tasks = maintenanceTaskRepository.findByPlanIdAndInspectionRequiredTrueAndIsActiveTrueOrderByTaskSequenceAsc(planId)
        return tasks.map { convertToDto(it) }
    }

    /**
     * 측정이 필요한 작업 조회
     */
    @Transactional(readOnly = true)
    fun getMeasurementTasksByPlan(planId: UUID): List<MaintenanceTaskDto> {
        val tasks = maintenanceTaskRepository.findByPlanIdAndMeasurementRequiredTrueAndIsActiveTrueOrderByTaskSequenceAsc(planId)
        return tasks.map { convertToDto(it) }
    }

    /**
     * 품질 검사 실패 작업 조회
     */
    @Transactional(readOnly = true)
    fun getFailedQualityCheckTasks(executionId: UUID): List<MaintenanceTaskExecutionDto> {
        val taskExecutions = maintenanceTaskExecutionRepository.findByExecutionIdAndQualityCheckPassedFalseOrderByTaskSequenceAsc(executionId)
        return taskExecutions.map { convertToDto(it) }
    }

    /**
     * 후속 조치가 필요한 작업 조회
     */
    @Transactional(readOnly = true)
    fun getFollowUpRequiredTasks(executionId: UUID): List<MaintenanceTaskExecutionDto> {
        val taskExecutions = maintenanceTaskExecutionRepository.findByExecutionIdAndRequiresFollowUpTrueOrderByTaskSequenceAsc(executionId)
        return taskExecutions.map { convertToDto(it) }
    }

    /**
     * 작업 실행 통계 조회
     */
    @Transactional(readOnly = true)
    fun getTaskExecutionStatistics(executionId: UUID): TaskExecutionStatisticsDto {
        val statistics = maintenanceTaskExecutionRepository.getTaskExecutionStatistics(executionId)
        val totalTasks = maintenanceTaskExecutionRepository.countTotalTasksByExecution(executionId)
        val completedTasks = maintenanceTaskExecutionRepository.countCompletedTasksByExecution(executionId)
        val progress = maintenanceTaskExecutionRepository.calculateExecutionProgress(executionId)

        return TaskExecutionStatisticsDto(
            totalTasks = totalTasks,
            completedTasks = completedTasks,
            pendingTasks = statistics.find { it[0] == TaskExecutionStatus.PENDING }?.get(1) as Long? ?: 0L,
            inProgressTasks = statistics.find { it[0] == TaskExecutionStatus.IN_PROGRESS }?.get(1) as Long? ?: 0L,
            skippedTasks = statistics.find { it[0] == TaskExecutionStatus.SKIPPED }?.get(1) as Long? ?: 0L,
            failedTasks = statistics.find { it[0] == TaskExecutionStatus.FAILED }?.get(1) as Long? ?: 0L,
            completionPercentage = BigDecimal.valueOf(progress)
        )
    }

    /**
     * MaintenanceTask 엔티티를 DTO로 변환
     */
    private fun convertToDto(task: MaintenanceTask): MaintenanceTaskDto {
        return MaintenanceTaskDto(
            taskId = task.taskId,
            companyId = task.companyId,
            planId = task.planId,
            taskSequence = task.taskSequence,
            taskName = task.taskName,
            taskDescription = task.taskDescription,
            taskType = task.taskType,
            taskInstructions = task.taskInstructions,
            safetyPrecautions = task.safetyPrecautions,
            qualityStandards = task.qualityStandards,
            estimatedDurationMinutes = task.estimatedDurationMinutes,
            requiredSkillLevel = task.requiredSkillLevel,
            requiredTools = task.requiredTools,
            requiredParts = task.requiredParts,
            prerequisiteTasks = task.prerequisiteTasks,
            environmentalConditions = task.environmentalConditions,
            equipmentStateRequired = task.equipmentStateRequired,
            inspectionRequired = task.inspectionRequired,
            measurementRequired = task.measurementRequired,
            documentationRequired = task.documentationRequired,
            photoRequired = task.photoRequired,
            acceptanceCriteria = task.acceptanceCriteria,
            measurementPoints = task.measurementPoints,
            toleranceSpecifications = task.toleranceSpecifications,
            isCritical = task.isCritical,
            isActive = task.isActive,
            createdAt = task.createdAt,
            updatedAt = task.updatedAt,
            createdBy = task.createdBy,
            updatedBy = task.updatedBy
        )
    }

    /**
     * MaintenanceTaskExecution 엔티티를 DTO로 변환
     */
    private fun convertToDto(execution: MaintenanceTaskExecution): MaintenanceTaskExecutionDto {
        return MaintenanceTaskExecutionDto(
            taskExecutionId = execution.taskExecutionId,
            executionId = execution.executionId,
            taskId = execution.taskId,
            taskSequence = execution.taskSequence,
            taskName = execution.taskName,
            executionStatus = execution.executionStatus,
            startedAt = execution.startedAt,
            completedAt = execution.completedAt,
            actualDurationMinutes = execution.actualDurationMinutes,
            executedBy = execution.executedBy,
            executionNotes = execution.executionNotes,
            qualityCheckPassed = execution.qualityCheckPassed,
            qualityCheckNotes = execution.qualityCheckNotes,
            measurementsTaken = execution.measurementsTaken,
            photosTaken = execution.photosTaken,
            partsUsed = execution.partsUsed,
            toolsUsed = execution.toolsUsed,
            issuesFound = execution.issuesFound,
            correctiveActions = execution.correctiveActions,
            taskCost = execution.taskCost,
            laborHours = execution.laborHours,
            materialCost = execution.materialCost,
            completionPercentage = execution.completionPercentage,
            requiresFollowUp = execution.requiresFollowUp,
            followUpNotes = execution.followUpNotes,
            createdAt = execution.createdAt,
            updatedAt = execution.updatedAt,
            createdBy = execution.createdBy,
            updatedBy = execution.updatedBy
        )
    }
}