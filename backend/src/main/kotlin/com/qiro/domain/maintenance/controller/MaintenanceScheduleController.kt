package com.qiro.domain.maintenance.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.MaintenanceScheduleService
import com.qiro.security.CustomUserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 정비 일정 관리 컨트롤러
 * 정비 일정 생성, 조회, 수정 및 캘린더 관리 API
 */
@Tag(name = "정비 일정 관리", description = "예방 정비 일정 관리 및 스케줄링 API")
@RestController
@RequestMapping("/api/v1/maintenance/schedules")
@PreAuthorize("hasRole('USER')")
class MaintenanceScheduleController(
    private val maintenanceScheduleService: MaintenanceScheduleService
) {

    /**
     * 정비 일정 자동 생성
     */
    @Operation(
        summary = "정비 일정 자동 생성",
        description = "정비 계획을 기반으로 자동으로 정비 일정을 생성합니다."
    )
    @PostMapping("/auto-generate")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun autoGenerateMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "생성 시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @Parameter(description = "생성 종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        @Parameter(description = "기존 일정 덮어쓰기") @RequestParam(defaultValue = "false") overwriteExisting: Boolean
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.autoGenerateSchedules(
            companyId = userPrincipal.companyId,
            planId = planId,
            assetId = assetId,
            startDate = startDate,
            endDate = endDate,
            overwriteExisting = overwriteExisting,
            createdBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(schedules, "정비 일정이 자동으로 생성되었습니다."))
    }

    /**
     * 정비 일정 수동 생성
     */
    @Operation(
        summary = "정비 일정 수동 생성",
        description = "수동으로 정비 일정을 생성합니다."
    )
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun createMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: CreateMaintenanceScheduleRequest
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.createMaintenanceSchedule(
            request = request.copy(
                companyId = userPrincipal.companyId,
                createdBy = userPrincipal.userId
            )
        )
        return ResponseEntity.ok(ApiResponse.success(schedule, "정비 일정이 성공적으로 생성되었습니다."))
    }

    /**
     * 정비 일정 상세 조회
     */
    @Operation(
        summary = "정비 일정 상세 조회",
        description = "특정 정비 일정의 상세 정보를 조회합니다."
    )
    @GetMapping("/{scheduleId}")
    fun getMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.getMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId
        )
        return ResponseEntity.ok(ApiResponse.success(schedule))
    }

    /**
     * 정비 일정 목록 조회
     */
    @Operation(
        summary = "정비 일정 목록 조회",
        description = "정비 일정 목록을 페이징하여 조회합니다."
    )
    @GetMapping
    fun getMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?,
        @Parameter(description = "일정 상태") @RequestParam(required = false) scheduleStatus: String?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?,
        @Parameter(description = "우선순위") @RequestParam(required = false) priority: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceScheduleDto>>> {
        val filter = MaintenanceScheduleFilter(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            planId = planId,
            scheduleStatus = scheduleStatus?.let { ScheduleStatus.valueOf(it) },
            startDate = startDate,
            endDate = endDate,
            assignedTo = assignedTo,
            priority = priority?.let { ExecutionPriority.valueOf(it) }
        )
        val schedules = maintenanceScheduleService.getMaintenanceSchedules(filter, pageable)
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 정비 일정 업데이트
     */
    @Operation(
        summary = "정비 일정 업데이트",
        description = "기존 정비 일정을 업데이트합니다."
    )
    @PutMapping("/{scheduleId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun updateMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID,
        @Valid @RequestBody request: UpdateMaintenanceScheduleRequest
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.updateMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId,
            request = request.copy(updatedBy = userPrincipal.userId)
        )
        return ResponseEntity.ok(ApiResponse.success(schedule, "정비 일정이 성공적으로 업데이트되었습니다."))
    }

    /**
     * 정비 일정 삭제
     */
    @Operation(
        summary = "정비 일정 삭제",
        description = "정비 일정을 삭제합니다."
    )
    @DeleteMapping("/{scheduleId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun deleteMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID
    ): ResponseEntity<ApiResponse<Void>> {
        maintenanceScheduleService.deleteMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId
        )
        return ResponseEntity.ok(ApiResponse.success(null, "정비 일정이 성공적으로 삭제되었습니다."))
    }

    /**
     * 정비 일정 재조정
     */
    @Operation(
        summary = "정비 일정 재조정",
        description = "정비 일정을 새로운 날짜로 재조정합니다."
    )
    @PostMapping("/{scheduleId}/reschedule")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun rescheduleMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID,
        @Parameter(description = "새로운 예정일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) newScheduledDate: LocalDate,
        @Parameter(description = "재조정 사유") @RequestParam reason: String
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.rescheduleMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId,
            newScheduledDate = newScheduledDate,
            reason = reason,
            rescheduledBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(schedule, "정비 일정이 재조정되었습니다."))
    }

    /**
     * 정비 일정 담당자 배정
     */
    @Operation(
        summary = "정비 일정 담당자 배정",
        description = "정비 일정에 담당자를 배정합니다."
    )
    @PostMapping("/{scheduleId}/assign")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun assignMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID,
        @Parameter(description = "담당자 ID") @RequestParam assignedTo: UUID,
        @Parameter(description = "배정 메모") @RequestParam(required = false) assignmentNotes: String?
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.assignMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId,
            assignedTo = assignedTo,
            assignmentNotes = assignmentNotes,
            assignedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(schedule, "정비 일정에 담당자가 배정되었습니다."))
    }

    /**
     * 정비 일정 우선순위 변경
     */
    @Operation(
        summary = "정비 일정 우선순위 변경",
        description = "정비 일정의 우선순위를 변경합니다."
    )
    @PostMapping("/{scheduleId}/priority")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun updateSchedulePriority(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "일정 ID") @PathVariable scheduleId: UUID,
        @Parameter(description = "새로운 우선순위") @RequestParam priority: String,
        @Parameter(description = "변경 사유") @RequestParam(required = false) reason: String?
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDto>> {
        val schedule = maintenanceScheduleService.updateSchedulePriority(
            companyId = userPrincipal.companyId,
            scheduleId = scheduleId,
            priority = ExecutionPriority.valueOf(priority),
            reason = reason,
            updatedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(schedule, "정비 일정 우선순위가 변경되었습니다."))
    }

    /**
     * 오늘 예정된 정비 일정 조회
     */
    @Operation(
        summary = "오늘 예정된 정비 일정 조회",
        description = "오늘 예정된 정비 일정을 조회합니다."
    )
    @GetMapping("/today")
    fun getTodayMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getTodayMaintenanceSchedules(
            companyId = userPrincipal.companyId,
            assignedTo = assignedTo
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 이번 주 예정된 정비 일정 조회
     */
    @Operation(
        summary = "이번 주 예정된 정비 일정 조회",
        description = "이번 주 예정된 정비 일정을 조회합니다."
    )
    @GetMapping("/this-week")
    fun getThisWeekMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getThisWeekMaintenanceSchedules(
            companyId = userPrincipal.companyId,
            assignedTo = assignedTo
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 지연된 정비 일정 조회
     */
    @Operation(
        summary = "지연된 정비 일정 조회",
        description = "예정일을 초과한 정비 일정을 조회합니다."
    )
    @GetMapping("/overdue")
    fun getOverdueMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getOverdueMaintenanceSchedules(
            companyId = userPrincipal.companyId,
            assignedTo = assignedTo
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 예정된 정비 일정 조회
     */
    @Operation(
        summary = "예정된 정비 일정 조회",
        description = "향후 예정된 정비 일정을 조회합니다."
    )
    @GetMapping("/upcoming")
    fun getUpcomingMaintenanceSchedules(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "조회 기간(일)") @RequestParam(defaultValue = "30") days: Int,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getUpcomingMaintenanceSchedules(
            companyId = userPrincipal.companyId,
            days = days,
            assignedTo = assignedTo
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 담당자별 정비 일정 조회
     */
    @Operation(
        summary = "담당자별 정비 일정 조회",
        description = "특정 담당자의 정비 일정을 조회합니다."
    )
    @GetMapping("/assignee/{assigneeId}")
    fun getMaintenanceSchedulesByAssignee(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "담당자 ID") @PathVariable assigneeId: UUID,
        @Parameter(description = "일정 상태") @RequestParam(required = false) scheduleStatus: String?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getMaintenanceSchedulesByAssignee(
            companyId = userPrincipal.companyId,
            assigneeId = assigneeId,
            scheduleStatus = scheduleStatus?.let { ScheduleStatus.valueOf(it) },
            startDate = startDate,
            endDate = endDate,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 자산별 정비 일정 조회
     */
    @Operation(
        summary = "자산별 정비 일정 조회",
        description = "특정 자산의 정비 일정을 조회합니다."
    )
    @GetMapping("/asset/{assetId}")
    fun getMaintenanceSchedulesByAsset(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: UUID,
        @Parameter(description = "일정 상태") @RequestParam(required = false) scheduleStatus: String?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenanceScheduleDto>>> {
        val schedules = maintenanceScheduleService.getMaintenanceSchedulesByAsset(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            scheduleStatus = scheduleStatus?.let { ScheduleStatus.valueOf(it) },
            startDate = startDate,
            endDate = endDate,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(schedules))
    }

    /**
     * 정비 일정 캘린더 뷰
     */
    @Operation(
        summary = "정비 일정 캘린더 뷰",
        description = "정비 일정을 캘린더 형태로 조회합니다."
    )
    @GetMapping("/calendar")
    fun getMaintenanceScheduleCalendar(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "조회 년도") @RequestParam year: Int,
        @Parameter(description = "조회 월") @RequestParam month: Int,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenanceScheduleCalendarDto>>> {
        val calendar = maintenanceScheduleService.getMaintenanceScheduleCalendar(
            companyId = userPrincipal.companyId,
            year = year,
            month = month,
            assetId = assetId,
            assignedTo = assignedTo
        )
        return ResponseEntity.ok(ApiResponse.success(calendar))
    }

    /**
     * 정비 일정 통계
     */
    @Operation(
        summary = "정비 일정 통계",
        description = "정비 일정 관련 통계를 조회합니다."
    )
    @GetMapping("/statistics")
    fun getMaintenanceScheduleStatistics(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?
    ): ResponseEntity<ApiResponse<MaintenanceScheduleStatisticsDto>> {
        val statistics = maintenanceScheduleService.getMaintenanceScheduleStatistics(
            companyId = userPrincipal.companyId,
            startDate = startDate,
            endDate = endDate,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    /**
     * 정비 일정 대시보드
     */
    @Operation(
        summary = "정비 일정 대시보드",
        description = "정비 일정 관리를 위한 대시보드 데이터를 조회합니다."
    )
    @GetMapping("/dashboard")
    fun getMaintenanceScheduleDashboard(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<MaintenanceScheduleDashboardDto>> {
        val dashboard = maintenanceScheduleService.getMaintenanceScheduleDashboard(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(dashboard))
    }

    /**
     * 일정 충돌 검사
     */
    @Operation(
        summary = "일정 충돌 검사",
        description = "새로운 정비 일정이 기존 일정과 충돌하는지 검사합니다."
    )
    @PostMapping("/check-conflicts")
    fun checkScheduleConflicts(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: CheckScheduleConflictRequest
    ): ResponseEntity<ApiResponse<List<ScheduleConflictDto>>> {
        val conflicts = maintenanceScheduleService.checkScheduleConflicts(
            companyId = userPrincipal.companyId,
            request = request
        )
        return ResponseEntity.ok(ApiResponse.success(conflicts))
    }

    /**
     * 일정 최적화 제안
     */
    @Operation(
        summary = "일정 최적화 제안",
        description = "정비 일정 최적화 제안을 조회합니다."
    )
    @GetMapping("/optimization-suggestions")
    fun getScheduleOptimizationSuggestions(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?
    ): ResponseEntity<ApiResponse<List<ScheduleOptimizationSuggestionDto>>> {
        val suggestions = maintenanceScheduleService.getScheduleOptimizationSuggestions(
            companyId = userPrincipal.companyId,
            startDate = startDate,
            endDate = endDate,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(suggestions))
    }
}

// 추가 DTO 클래스들
data class MaintenanceScheduleDto(
    val scheduleId: UUID,
    val companyId: UUID,
    val planId: UUID,
    val assetId: UUID,
    val scheduledDate: LocalDate,
    val scheduledStartTime: LocalDateTime?,
    val scheduledEndTime: LocalDateTime?,
    val scheduleStatus: ScheduleStatus,
    val priority: ExecutionPriority,
    val assignedTo: UUID?,
    val estimatedDurationHours: java.math.BigDecimal,
    val scheduleNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

data class CreateMaintenanceScheduleRequest(
    val companyId: UUID,
    val planId: UUID,
    val assetId: UUID,
    val scheduledDate: LocalDate,
    val scheduledStartTime: LocalDateTime?,
    val scheduledEndTime: LocalDateTime?,
    val priority: ExecutionPriority = ExecutionPriority.NORMAL,
    val assignedTo: UUID?,
    val estimatedDurationHours: java.math.BigDecimal = java.math.BigDecimal.ZERO,
    val scheduleNotes: String?,
    val createdBy: UUID?
)

data class UpdateMaintenanceScheduleRequest(
    val scheduledDate: LocalDate?,
    val scheduledStartTime: LocalDateTime?,
    val scheduledEndTime: LocalDateTime?,
    val scheduleStatus: ScheduleStatus?,
    val priority: ExecutionPriority?,
    val assignedTo: UUID?,
    val estimatedDurationHours: java.math.BigDecimal?,
    val scheduleNotes: String?,
    val updatedBy: UUID?
)

data class MaintenanceScheduleFilter(
    val companyId: UUID,
    val assetId: UUID? = null,
    val planId: UUID? = null,
    val scheduleStatus: ScheduleStatus? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val assignedTo: UUID? = null,
    val priority: ExecutionPriority? = null
)

data class MaintenanceScheduleCalendarDto(
    val date: LocalDate,
    val schedules: List<MaintenanceScheduleCalendarItemDto>
)

data class MaintenanceScheduleCalendarItemDto(
    val scheduleId: UUID,
    val planName: String,
    val assetName: String,
    val scheduleStatus: ScheduleStatus,
    val priority: ExecutionPriority,
    val assignedTo: UUID?,
    val assigneeName: String?,
    val estimatedDurationHours: java.math.BigDecimal
)

data class MaintenanceScheduleStatisticsDto(
    val totalSchedules: Long,
    val scheduledCount: Long,
    val inProgressCount: Long,
    val completedCount: Long,
    val overdueCount: Long,
    val cancelledCount: Long,
    val schedulesByStatus: Map<ScheduleStatus, Long>,
    val schedulesByPriority: Map<ExecutionPriority, Long>,
    val monthlyScheduleTrend: Map<String, Long>
)

data class MaintenanceScheduleDashboardDto(
    val statistics: MaintenanceScheduleStatisticsDto,
    val todaySchedules: List<MaintenanceScheduleDto>,
    val overdueSchedules: List<MaintenanceScheduleDto>,
    val upcomingSchedules: List<MaintenanceScheduleDto>,
    val recentlyCompletedSchedules: List<MaintenanceScheduleDto>
)

data class CheckScheduleConflictRequest(
    val assetId: UUID,
    val scheduledDate: LocalDate,
    val scheduledStartTime: LocalDateTime?,
    val scheduledEndTime: LocalDateTime?,
    val excludeScheduleId: UUID? = null
)

data class ScheduleConflictDto(
    val conflictingScheduleId: UUID,
    val conflictingPlanName: String,
    val conflictType: ConflictType,
    val conflictDescription: String,
    val severity: ConflictSeverity
)

data class ScheduleOptimizationSuggestionDto(
    val suggestionType: OptimizationSuggestionType,
    val title: String,
    val description: String,
    val affectedSchedules: List<UUID>,
    val potentialBenefits: String,
    val implementationComplexity: ComplexityLevel
)

enum class ScheduleStatus {
    SCHEDULED,      // 예정됨
    IN_PROGRESS,    // 진행 중
    COMPLETED,      // 완료됨
    OVERDUE,        // 지연됨
    CANCELLED,      // 취소됨
    RESCHEDULED     // 재조정됨
}

enum class ConflictType {
    TIME_OVERLAP,           // 시간 중복
    RESOURCE_CONFLICT,      // 자원 충돌
    TECHNICIAN_UNAVAILABLE, // 기술자 불가
    ASSET_UNAVAILABLE       // 자산 불가
}

enum class ConflictSeverity {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH,       // 높음
    CRITICAL    // 중요
}

enum class OptimizationSuggestionType {
    SCHEDULE_GROUPING,      // 일정 그룹화
    RESOURCE_OPTIMIZATION,  // 자원 최적화
    TIME_SLOT_ADJUSTMENT,   // 시간대 조정
    PRIORITY_REBALANCING    // 우선순위 재조정
}

enum class ComplexityLevel {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH        // 높음
}