package com.qiro.domain.maintenance.controller

import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.MaintenanceChecklistService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 정비 체크리스트 컨트롤러
 * 점검 체크리스트 관리 시스템을 제공하는 REST API입니다.
 */
@RestController
@RequestMapping("/api/maintenance/checklist")
@Tag(name = "정비 체크리스트", description = "정비 작업 체크리스트 관리 API")
class MaintenanceChecklistController(
    private val maintenanceChecklistService: MaintenanceChecklistService
) {

    @Operation(summary = "정비 작업 생성", description = "정비 계획에 새로운 작업을 추가합니다.")
    @PostMapping("/tasks")
    fun createMaintenanceTask(
        @RequestBody request: CreateMaintenanceTaskRequest
    ): ResponseEntity<MaintenanceTaskDto> {
        val task = maintenanceChecklistService.createMaintenanceTask(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(task)
    }

    @Operation(summary = "정비 계획별 작업 목록 조회", description = "특정 정비 계획의 모든 작업을 조회합니다.")
    @GetMapping("/tasks/plan/{planId}")
    fun getMaintenanceTasksByPlan(
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<List<MaintenanceTaskDto>> {
        val tasks = maintenanceChecklistService.getMaintenanceTasksByPlan(planId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "중요 작업 조회", description = "특정 정비 계획의 중요 작업들을 조회합니다.")
    @GetMapping("/tasks/plan/{planId}/critical")
    fun getCriticalTasksByPlan(
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<List<MaintenanceTaskDto>> {
        val tasks = maintenanceChecklistService.getCriticalTasksByPlan(planId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "점검 작업 조회", description = "특정 정비 계획의 점검이 필요한 작업들을 조회합니다.")
    @GetMapping("/tasks/plan/{planId}/inspection")
    fun getInspectionTasksByPlan(
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<List<MaintenanceTaskDto>> {
        val tasks = maintenanceChecklistService.getInspectionTasksByPlan(planId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "측정 작업 조회", description = "특정 정비 계획의 측정이 필요한 작업들을 조회합니다.")
    @GetMapping("/tasks/plan/{planId}/measurement")
    fun getMeasurementTasksByPlan(
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<List<MaintenanceTaskDto>> {
        val tasks = maintenanceChecklistService.getMeasurementTasksByPlan(planId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "정비 실행 체크리스트 생성", description = "정비 실행 시 작업 체크리스트를 생성합니다.")
    @PostMapping("/executions/{executionId}/tasks")
    fun createTaskExecutionsForMaintenance(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<List<MaintenanceTaskExecutionDto>> {
        val taskExecutions = maintenanceChecklistService.createTaskExecutionsForMaintenance(executionId)
        return ResponseEntity.status(HttpStatus.CREATED).body(taskExecutions)
    }

    @Operation(summary = "정비 실행별 작업 체크리스트 조회", description = "특정 정비 실행의 모든 작업 체크리스트를 조회합니다.")
    @GetMapping("/executions/{executionId}/tasks")
    fun getTaskExecutionsByMaintenance(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<List<MaintenanceTaskExecutionDto>> {
        val taskExecutions = maintenanceChecklistService.getTaskExecutionsByMaintenance(executionId)
        return ResponseEntity.ok(taskExecutions)
    }

    @Operation(summary = "작업 실행 시작", description = "특정 작업의 실행을 시작합니다.")
    @PostMapping("/task-executions/{taskExecutionId}/start")
    fun startTaskExecution(
        @Parameter(description = "작업 실행 ID") @PathVariable taskExecutionId: UUID,
        @Parameter(description = "실행자 ID") @RequestParam executedBy: UUID
    ): ResponseEntity<MaintenanceTaskExecutionDto> {
        val taskExecution = maintenanceChecklistService.startTaskExecution(taskExecutionId, executedBy)
        return ResponseEntity.ok(taskExecution)
    }

    @Operation(summary = "작업 실행 완료", description = "특정 작업의 실행을 완료합니다.")
    @PostMapping("/task-executions/{taskExecutionId}/complete")
    fun completeTaskExecution(
        @Parameter(description = "작업 실행 ID") @PathVariable taskExecutionId: UUID,
        @RequestBody request: CompleteTaskExecutionRequest
    ): ResponseEntity<MaintenanceTaskExecutionDto> {
        val taskExecution = maintenanceChecklistService.completeTaskExecution(taskExecutionId, request)
        return ResponseEntity.ok(taskExecution)
    }

    @Operation(summary = "작업 건너뛰기", description = "특정 작업을 건너뜁니다.")
    @PostMapping("/task-executions/{taskExecutionId}/skip")
    fun skipTaskExecution(
        @Parameter(description = "작업 실행 ID") @PathVariable taskExecutionId: UUID,
        @Parameter(description = "건너뛰는 이유") @RequestParam reason: String,
        @Parameter(description = "건너뛴 사용자 ID") @RequestParam skippedBy: UUID
    ): ResponseEntity<MaintenanceTaskExecutionDto> {
        val taskExecution = maintenanceChecklistService.skipTaskExecution(taskExecutionId, reason, skippedBy)
        return ResponseEntity.ok(taskExecution)
    }

    @Operation(summary = "품질 검사 실패 작업 조회", description = "품질 검사를 통과하지 못한 작업들을 조회합니다.")
    @GetMapping("/executions/{executionId}/failed-quality-check")
    fun getFailedQualityCheckTasks(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<List<MaintenanceTaskExecutionDto>> {
        val tasks = maintenanceChecklistService.getFailedQualityCheckTasks(executionId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "후속 조치 필요 작업 조회", description = "후속 조치가 필요한 작업들을 조회합니다.")
    @GetMapping("/executions/{executionId}/follow-up-required")
    fun getFollowUpRequiredTasks(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<List<MaintenanceTaskExecutionDto>> {
        val tasks = maintenanceChecklistService.getFollowUpRequiredTasks(executionId)
        return ResponseEntity.ok(tasks)
    }

    @Operation(summary = "작업 실행 통계 조회", description = "특정 정비 실행의 작업 통계를 조회합니다.")
    @GetMapping("/executions/{executionId}/statistics")
    fun getTaskExecutionStatistics(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<TaskExecutionStatisticsDto> {
        val statistics = maintenanceChecklistService.getTaskExecutionStatistics(executionId)
        return ResponseEntity.ok(statistics)
    }

    @Operation(summary = "체크리스트 대시보드", description = "체크리스트 관리를 위한 대시보드 데이터를 조회합니다.")
    @GetMapping("/executions/{executionId}/dashboard")
    fun getChecklistDashboard(
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<ChecklistDashboardDto> {
        val statistics = maintenanceChecklistService.getTaskExecutionStatistics(executionId)
        val taskExecutions = maintenanceChecklistService.getTaskExecutionsByMaintenance(executionId)
        val failedQualityTasks = maintenanceChecklistService.getFailedQualityCheckTasks(executionId)
        val followUpTasks = maintenanceChecklistService.getFollowUpRequiredTasks(executionId)

        val dashboard = ChecklistDashboardDto(
            statistics = statistics,
            totalTasks = taskExecutions.size,
            criticalTasksCount = taskExecutions.count { task ->
                // 실제로는 MaintenanceTask에서 isCritical 정보를 가져와야 함
                false // 임시값
            },
            inspectionTasksCount = taskExecutions.count { task ->
                // 실제로는 MaintenanceTask에서 inspectionRequired 정보를 가져와야 함
                false // 임시값
            },
            measurementTasksCount = taskExecutions.count { task ->
                // 실제로는 MaintenanceTask에서 measurementRequired 정보를 가져와야 함
                false // 임시값
            },
            failedQualityTasksCount = failedQualityTasks.size,
            followUpRequiredTasksCount = followUpTasks.size
        )

        return ResponseEntity.ok(dashboard)
    }
}

/**
 * 체크리스트 대시보드 DTO
 */
data class ChecklistDashboardDto(
    val statistics: TaskExecutionStatisticsDto,
    val totalTasks: Int,
    val criticalTasksCount: Int,
    val inspectionTasksCount: Int,
    val measurementTasksCount: Int,
    val failedQualityTasksCount: Int,
    val followUpRequiredTasksCount: Int
)