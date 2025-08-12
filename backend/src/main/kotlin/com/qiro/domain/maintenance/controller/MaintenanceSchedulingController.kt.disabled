package com.qiro.domain.maintenance.controller

import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.MaintenanceSchedulingService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 정비 스케줄링 컨트롤러
 * 자동 정비 일정 생성 및 알림 기능을 제공하는 REST API입니다.
 */
@RestController
@RequestMapping("/api/maintenance/scheduling")
@Tag(name = "정비 스케줄링", description = "예방 정비 스케줄링 관리 API")
class MaintenanceSchedulingController(
    private val maintenanceSchedulingService: MaintenanceSchedulingService
) {

    @Operation(summary = "정비 계획 생성", description = "새로운 정비 계획을 생성합니다.")
    @PostMapping("/plans")
    fun createMaintenancePlan(
        @RequestBody request: CreateMaintenancePlanRequest
    ): ResponseEntity<MaintenancePlanDto> {
        val plan = maintenanceSchedulingService.createMaintenancePlan(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(plan)
    }

    @Operation(summary = "정비 계획 목록 조회", description = "정비 계획 목록을 조회합니다.")
    @GetMapping("/plans")
    fun getMaintenancePlans(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "계획 상태") @RequestParam(required = false) planStatus: String?,
        @Parameter(description = "승인 상태") @RequestParam(required = false) approvalStatus: String?,
        @Parameter(description = "계획 유형") @RequestParam(required = false) planType: String?,
        @Parameter(description = "정비 전략") @RequestParam(required = false) maintenanceStrategy: String?,
        @Parameter(description = "검색 키워드") @RequestParam(required = false) searchKeyword: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<MaintenancePlanDto>> {
        val filter = MaintenancePlanFilter(
            companyId = companyId,
            assetId = assetId,
            searchKeyword = searchKeyword
        )
        val plans = maintenanceSchedulingService.getMaintenancePlans(filter, pageable)
        return ResponseEntity.ok(plans)
    }

    @Operation(summary = "정비 계획 상세 조회", description = "특정 정비 계획의 상세 정보를 조회합니다.")
    @GetMapping("/plans/{planId}")
    fun getMaintenancePlan(
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<MaintenancePlanDto> {
        val plan = maintenanceSchedulingService.getMaintenancePlan(planId)
        return ResponseEntity.ok(plan)
    }

    @Operation(summary = "자동 정비 일정 생성", description = "정비 계획을 기반으로 자동으로 정비 일정을 생성합니다.")
    @PostMapping("/schedules/generate")
    fun generateMaintenanceSchedules(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "대상 날짜") @RequestParam(required = false) targetDate: LocalDate?
    ): ResponseEntity<List<PreventiveMaintenanceExecutionDto>> {
        val schedules = maintenanceSchedulingService.generateMaintenanceSchedules(
            companyId = companyId,
            targetDate = targetDate ?: LocalDate.now()
        )
        return ResponseEntity.ok(schedules)
    }

    @Operation(summary = "예정된 정비 알림 조회", description = "지정된 기간 내 예정된 정비 작업에 대한 알림을 조회합니다.")
    @GetMapping("/notifications/upcoming")
    fun getUpcomingMaintenanceNotifications(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "조회 기간(일)") @RequestParam(defaultValue = "7") days: Int
    ): ResponseEntity<List<MaintenanceScheduleNotificationDto>> {
        val notifications = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, days)
        return ResponseEntity.ok(notifications)
    }

    @Operation(summary = "지연된 정비 알림 조회", description = "지연된 정비 작업에 대한 알림을 조회합니다.")
    @GetMapping("/notifications/overdue")
    fun getOverdueMaintenanceNotifications(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<List<MaintenanceScheduleNotificationDto>> {
        val notifications = maintenanceSchedulingService.getOverdueMaintenanceNotifications(companyId)
        return ResponseEntity.ok(notifications)
    }

    @Operation(summary = "정비 계획 통계 조회", description = "정비 계획 관련 통계 정보를 조회합니다.")
    @GetMapping("/plans/statistics")
    fun getMaintenancePlanStatistics(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<MaintenancePlanStatisticsDto> {
        val statistics = maintenanceSchedulingService.getMaintenancePlanStatistics(companyId)
        return ResponseEntity.ok(statistics)
    }

    @Operation(summary = "오늘의 정비 일정 조회", description = "오늘 실행 예정인 정비 작업을 조회합니다.")
    @GetMapping("/schedules/today")
    fun getTodayMaintenanceSchedules(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<List<MaintenanceScheduleNotificationDto>> {
        val notifications = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, 0)
        return ResponseEntity.ok(notifications)
    }

    @Operation(summary = "이번 주 정비 일정 조회", description = "이번 주 실행 예정인 정비 작업을 조회합니다.")
    @GetMapping("/schedules/this-week")
    fun getThisWeekMaintenanceSchedules(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<List<MaintenanceScheduleNotificationDto>> {
        val notifications = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, 7)
        return ResponseEntity.ok(notifications)
    }

    @Operation(summary = "다음 달 정비 일정 조회", description = "다음 달 실행 예정인 정비 작업을 조회합니다.")
    @GetMapping("/schedules/next-month")
    fun getNextMonthMaintenanceSchedules(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<List<MaintenanceScheduleNotificationDto>> {
        val notifications = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, 30)
        return ResponseEntity.ok(notifications)
    }

    @Operation(summary = "정비 일정 대시보드", description = "정비 일정 관리를 위한 대시보드 데이터를 조회합니다.")
    @GetMapping("/dashboard")
    fun getMaintenanceDashboard(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ResponseEntity<MaintenanceDashboardDto> {
        val planStatistics = maintenanceSchedulingService.getMaintenancePlanStatistics(companyId)
        val upcomingNotifications = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, 7)
        val overdueNotifications = maintenanceSchedulingService.getOverdueMaintenanceNotifications(companyId)

        val dashboard = MaintenanceDashboardDto(
            planStatistics = planStatistics,
            upcomingMaintenanceCount = upcomingNotifications.size,
            overdueMaintenanceCount = overdueNotifications.size,
            todayMaintenanceCount = maintenanceSchedulingService.getUpcomingMaintenanceNotifications(companyId, 0).size,
            thisWeekMaintenanceCount = upcomingNotifications.size,
            urgentMaintenanceCount = upcomingNotifications.count { it.notificationType == NotificationType.URGENT_MAINTENANCE }
        )

        return ResponseEntity.ok(dashboard)
    }
}

/**
 * 정비 대시보드 DTO
 */
data class MaintenanceDashboardDto(
    val planStatistics: MaintenancePlanStatisticsDto,
    val upcomingMaintenanceCount: Int,
    val overdueMaintenanceCount: Int,
    val todayMaintenanceCount: Int,
    val thisWeekMaintenanceCount: Int,
    val urgentMaintenanceCount: Int
)