package com.qiro.domain.mobile.controller

import com.qiro.domain.mobile.dto.*
import com.qiro.domain.mobile.service.MobileDashboardService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 모바일 대시보드 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/mobile/companies/{companyId}/dashboard")
@Tag(name = "Mobile Dashboard", description = "모바일 대시보드 API")
class MobileDashboardController(
    private val mobileDashboardService: MobileDashboardService
) {

    @Operation(summary = "모바일 대시보드 조회", description = "사용자별 맞춤형 모바일 대시보드 데이터를 조회합니다")
    @GetMapping
    fun getMobileDashboard(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @RequestHeader("X-User-Role") userRole: String
    ): ResponseEntity<MobileDashboardDto> {
        val result = mobileDashboardService.getMobileDashboard(companyId, userId, userRole)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "대시보드 요약 정보 조회", description = "대시보드 요약 통계를 조회합니다")
    @GetMapping("/summary")
    fun getDashboardSummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<DashboardSummaryDto> {
        val result = mobileDashboardService.getDashboardSummary(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "오늘의 작업 조회", description = "오늘 예정된 작업들을 조회합니다")
    @GetMapping("/today-tasks")
    fun getTodayTasks(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<TodayTasksDto> {
        val result = mobileDashboardService.getTodayTasks(companyId, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "긴급 항목 조회", description = "긴급하게 처리해야 할 항목들을 조회합니다")
    @GetMapping("/urgent-items")
    fun getUrgentItems(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<UrgentItemsDto> {
        val result = mobileDashboardService.getUrgentItems(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "최근 활동 조회", description = "최근 시스템 활동 내역을 조회합니다")
    @GetMapping("/recent-activities")
    fun getRecentActivities(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "조회할 개수") @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<RecentActivityDto>> {
        val result = mobileDashboardService.getRecentActivities(companyId, limit)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "빠른 작업 메뉴 조회", description = "사용자 역할에 따른 빠른 작업 메뉴를 조회합니다")
    @GetMapping("/quick-actions")
    fun getQuickActions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Role") userRole: String
    ): ResponseEntity<List<QuickActionDto>> {
        val result = mobileDashboardService.getQuickActions(userRole)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "알림 목록 조회", description = "사용자의 알림 목록을 조회합니다")
    @GetMapping("/notifications")
    fun getNotifications(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @Parameter(description = "조회할 개수") @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<NotificationDto>> {
        val result = mobileDashboardService.getNotifications(companyId, userId, limit)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "기술자 성과 조회", description = "기술자의 성과 정보를 조회합니다")
    @GetMapping("/technician-performance")
    fun getTechnicianPerformance(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @Parameter(description = "기간") @RequestParam(defaultValue = "MONTHLY") period: String
    ): ResponseEntity<TechnicianPerformanceDto> {
        val result = mobileDashboardService.getTechnicianPerformance(companyId, userId, period)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모바일 설정 조회", description = "사용자의 모바일 앱 설정을 조회합니다")
    @GetMapping("/settings")
    fun getMobileSettings(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileSettingsDto> {
        val result = mobileDashboardService.getMobileSettings(userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모바일 설정 업데이트", description = "사용자의 모바일 앱 설정을 업데이트합니다")
    @PutMapping("/settings")
    fun updateMobileSettings(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @RequestBody settings: MobileSettingsDto
    ): ResponseEntity<MobileSettingsDto> {
        val result = mobileDashboardService.updateMobileSettings(userId, settings)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "알림 읽음 처리", description = "특정 알림을 읽음 처리합니다")
    @PutMapping("/notifications/{notificationId}/read")
    fun markNotificationAsRead(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "알림 ID") @PathVariable notificationId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 실제 구현에서는 알림 서비스를 호출하여 읽음 처리
        val response = mapOf(
            "success" to true,
            "message" to "알림이 읽음 처리되었습니다",
            "notificationId" to notificationId,
            "readAt" to java.time.LocalDateTime.now()
        )
        return ResponseEntity.ok(response)
    }

    @Operation(summary = "모든 알림 읽음 처리", description = "사용자의 모든 알림을 읽음 처리합니다")
    @PutMapping("/notifications/read-all")
    fun markAllNotificationsAsRead(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 실제 구현에서는 알림 서비스를 호출하여 모든 알림 읽음 처리
        val response = mapOf(
            "success" to true,
            "message" to "모든 알림이 읽음 처리되었습니다",
            "readCount" to 5,
            "readAt" to java.time.LocalDateTime.now()
        )
        return ResponseEntity.ok(response)
    }
}