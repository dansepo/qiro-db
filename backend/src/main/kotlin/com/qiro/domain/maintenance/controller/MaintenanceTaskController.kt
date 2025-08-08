package com.qiro.domain.maintenance.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.MaintenanceTaskService
import com.qiro.security.CustomUserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.util.*
import jakarta.validation.Valid

/**
 * 정비 작업 관리 컨트롤러
 * 정비 계획의 세부 작업 관리 API
 */
@Tag(name = "정비 작업 관리", description = "정비 계획의 세부 작업 관리 API")
@RestController
@RequestMapping("/api/v1/maintenance/tasks")
@PreAuthorize("hasRole('USER')")
class MaintenanceTaskController(
    private val maintenanceTaskService: MaintenanceTaskService
) {

    /**
     * 정비 작업 생성
     */
    @Operation(
        summary = "정비 작업 생성",
        description = "정비 계획에 새로운 작업을 추가합니다."
    )
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun createMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: CreateMaintenanceTaskRequest
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val task = maintenanceTaskService.createMaintenanceTask(
            request = request.copy(
                companyId = userPrincipal.companyId,
                createdBy = userPrincipal.userId
            )
        )
        return ResponseEntity.ok(ApiResponse.success(task, "정비 작업이 성공적으로 생성되었습니다."))
    }

    /**
     * 정비 작업 상세 조회
     */
    @Operation(
        summary = "정비 작업 상세 조회",
        description = "특정 정비 작업의 상세 정보를 조회합니다."
    )
    @GetMapping("/{taskId}")
    fun getMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "작업 ID") @PathVariable taskId: UUID
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val task = maintenanceTaskService.getMaintenanceTask(
            companyId = userPrincipal.companyId,
            taskId = taskId
        )
        return ResponseEntity.ok(ApiResponse.success(task))
    }

    /**
     * 계획별 정비 작업 목록 조회
     */
    @Operation(
        summary = "계획별 정비 작업 목록 조회",
        description = "특정 정비 계획의 작업 목록을 조회합니다."
    )
    @GetMapping("/plan/{planId}")
    fun getMaintenanceTasksByPlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "작업 유형") @RequestParam(required = false) taskType: String?,
        @Parameter(description = "활성 상태만") @RequestParam(defaultValue = "true") activeOnly: Boolean,
        @PageableDefault(size = 50) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceTaskDto>>> {
        val tasks = maintenanceTaskService.getMaintenanceTasksByPlan(
            companyId = userPrincipal.companyId,
            planId = planId,
            taskType = taskType?.let { TaskType.valueOf(it) },
            activeOnly = activeOnly,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(tasks))
    }

    /**
     * 정비 작업 업데이트
     */
    @Operation(
        summary = "정비 작업 업데이트",
        description = "기존 정비 작업을 업데이트합니다."
    )
    @PutMapping("/{taskId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun updateMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "작업 ID") @PathVariable taskId: UUID,
        @Valid @RequestBody request: UpdateMaintenanceTaskRequest
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val task = maintenanceTaskService.updateMaintenanceTask(
            companyId = userPrincipal.companyId,
            taskId = taskId,
            request = request.copy(updatedBy = userPrincipal.userId)
        )
        return ResponseEntity.ok(ApiResponse.success(task, "정비 작업이 성공적으로 업데이트되었습니다."))
    }

    /**
     * 정비 작업 삭제
     */
    @Operation(
        summary = "정비 작업 삭제",
        description = "정비 작업을 삭제합니다."
    )
    @DeleteMapping("/{taskId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun deleteMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "작업 ID") @PathVariable taskId: UUID
    ): ResponseEntity<ApiResponse<Void>> {
        maintenanceTaskService.deleteMaintenanceTask(
            companyId = userPrincipal.companyId,
            taskId = taskId
        )
        return ResponseEntity.ok(ApiResponse.success(null, "정비 작업이 성공적으로 삭제되었습니다."))
    }

    /**
     * 정비 작업 순서 변경
     */
    @Operation(
        summary = "정비 작업 순서 변경",
        description = "정비 작업의 실행 순서를 변경합니다."
    )
    @PostMapping("/{taskId}/reorder")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun reorderMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "작업 ID") @PathVariable taskId: UUID,
        @Parameter(description = "새로운 순서") @RequestParam newSequence: Int
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val task = maintenanceTaskService.reorderMaintenanceTask(
            companyId = userPrincipal.companyId,
            taskId = taskId,
            newSequence = newSequence,
            updatedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(task, "정비 작업 순서가 변경되었습니다."))
    }

    /**
     * 정비 작업 복사
     */
    @Operation(
        summary = "정비 작업 복사",
        description = "기존 정비 작업을 복사하여 새로운 작업을 생성합니다."
    )
    @PostMapping("/{taskId}/copy")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun copyMaintenanceTask(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "원본 작업 ID") @PathVariable taskId: UUID,
        @Parameter(description = "대상 계획 ID") @RequestParam targetPlanId: UUID,
        @Parameter(description = "새로운 작업명") @RequestParam(required = false) newTaskName: String?
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val copiedTask = maintenanceTaskService.copyMaintenanceTask(
            companyId = userPrincipal.companyId,
            sourceTaskId = taskId,
            targetPlanId = targetPlanId,
            newTaskName = newTaskName,
            createdBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(copiedTask, "정비 작업이 성공적으로 복사되었습니다."))
    }

    /**
     * 정비 작업 활성화/비활성화
     */
    @Operation(
        summary = "정비 작업 활성화/비활성화",
        description = "정비 작업의 활성 상태를 변경합니다."
    )
    @PostMapping("/{taskId}/toggle-active")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun toggleTaskActive(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "작업 ID") @PathVariable taskId: UUID,
        @Parameter(description = "활성 상태") @RequestParam isActive: Boolean
    ): ResponseEntity<ApiResponse<MaintenanceTaskDto>> {
        val task = maintenanceTaskService.toggleTaskActive(
            companyId = userPrincipal.companyId,
            taskId = taskId,
            isActive = isActive,
            updatedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(task, "정비 작업 활성 상태가 변경되었습니다."))
    }

    /**
     * 정비 작업 체크리스트 조회
     */
    @Operation(
        summary = "정비 작업 체크리스트 조회",
        description = "정비 계획의 작업 체크리스트를 조회합니다."
    )
    @GetMapping("/plan/{planId}/checklist")
    fun getMaintenanceTaskChecklist(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<ApiResponse<List<MaintenanceTaskChecklistDto>>> {
        val checklist = maintenanceTaskService.getMaintenanceTaskChecklist(
            companyId = userPrincipal.companyId,
            planId = planId
        )
        return ResponseEntity.ok(ApiResponse.success(checklist))
    }

    /**
     * 중요 작업 조회
     */
    @Operation(
        summary = "중요 작업 조회",
        description = "중요로 표시된 정비 작업을 조회합니다."
    )
    @GetMapping("/critical")
    fun getCriticalMaintenanceTasks(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceTaskDto>>> {
        val tasks = maintenanceTaskService.getCriticalMaintenanceTasks(
            companyId = userPrincipal.companyId,
            planId = planId,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(tasks))
    }

    /**
     * 기술 수준별 작업 조회
     */
    @Operation(
        summary = "기술 수준별 작업 조회",
        description = "특정 기술 수준이 필요한 정비 작업을 조회합니다."
    )
    @GetMapping("/skill-level/{skillLevel}")
    fun getTasksBySkillLevel(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "기술 수준") @PathVariable skillLevel: String,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceTaskDto>>> {
        val tasks = maintenanceTaskService.getTasksBySkillLevel(
            companyId = userPrincipal.companyId,
            skillLevel = SkillLevel.valueOf(skillLevel),
            planId = planId,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(tasks))
    }

    /**
     * 작업 유형별 통계
     */
    @Operation(
        summary = "작업 유형별 통계",
        description = "정비 작업의 유형별 통계를 조회합니다."
    )
    @GetMapping("/statistics/by-type")
    fun getTaskStatisticsByType(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?
    ): ResponseEntity<ApiResponse<Map<TaskType, Long>>> {
        val statistics = maintenanceTaskService.getTaskStatisticsByType(
            companyId = userPrincipal.companyId,
            planId = planId
        )
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    /**
     * 작업 소요 시간 통계
     */
    @Operation(
        summary = "작업 소요 시간 통계",
        description = "정비 작업의 소요 시간 통계를 조회합니다."
    )
    @GetMapping("/statistics/duration")
    fun getTaskDurationStatistics(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?
    ): ResponseEntity<ApiResponse<TaskDurationStatisticsDto>> {
        val statistics = maintenanceTaskService.getTaskDurationStatistics(
            companyId = userPrincipal.companyId,
            planId = planId
        )
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }
}

/**
 * 정비 작업 업데이트 요청 DTO
 */
data class UpdateMaintenanceTaskRequest(
    val taskName: String?,
    val taskDescription: String?,
    val taskType: TaskType?,
    val taskInstructions: String?,
    val safetyPrecautions: String?,
    val qualityStandards: String?,
    val estimatedDurationMinutes: Int?,
    val requiredSkillLevel: SkillLevel?,
    val requiredTools: String?,
    val requiredParts: String?,
    val prerequisiteTasks: String?,
    val environmentalConditions: String?,
    val equipmentStateRequired: String?,
    val inspectionRequired: Boolean?,
    val measurementRequired: Boolean?,
    val documentationRequired: Boolean?,
    val photoRequired: Boolean?,
    val acceptanceCriteria: String?,
    val measurementPoints: String?,
    val toleranceSpecifications: String?,
    val isCritical: Boolean?,
    val updatedBy: UUID?
)

/**
 * 정비 작업 체크리스트 DTO
 */
data class MaintenanceTaskChecklistDto(
    val taskId: UUID,
    val taskSequence: Int,
    val taskName: String,
    val taskType: TaskType,
    val estimatedDurationMinutes: Int,
    val requiredSkillLevel: SkillLevel,
    val isCritical: Boolean,
    val inspectionRequired: Boolean,
    val measurementRequired: Boolean,
    val documentationRequired: Boolean,
    val photoRequired: Boolean,
    val safetyPrecautions: String?,
    val acceptanceCriteria: String?
)

/**
 * 작업 소요 시간 통계 DTO
 */
data class TaskDurationStatisticsDto(
    val totalTasks: Long,
    val totalEstimatedMinutes: Long,
    val averageEstimatedMinutes: Double,
    val minEstimatedMinutes: Int,
    val maxEstimatedMinutes: Int,
    val durationByType: Map<TaskType, Long>,
    val durationBySkillLevel: Map<SkillLevel, Long>
)