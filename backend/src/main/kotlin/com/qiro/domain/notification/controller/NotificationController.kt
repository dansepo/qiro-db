package com.qiro.domain.notification.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.domain.notification.dto.*
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationType
import com.qiro.domain.notification.service.NotificationEscalationService
import com.qiro.domain.notification.service.NotificationService
import com.qiro.domain.notification.service.NotificationSettingService
import com.qiro.domain.notification.service.NotificationTemplateService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 관리 컨트롤러
 * 알림 발송, 설정 관리, 템플릿 관리 등의 API를 제공합니다.
 */
@Tag(name = "알림 관리", description = "알림 발송 및 설정 관리 API")
@RestController
@RequestMapping("/api/notifications")
class NotificationController(
    private val notificationService: NotificationService,
    private val notificationSettingService: NotificationSettingService,
    private val notificationTemplateService: NotificationTemplateService,
    private val notificationEscalationService: NotificationEscalationService
) {

    // ===== 알림 발송 API =====

    @Operation(summary = "알림 발송", description = "지정된 수신자에게 알림을 발송합니다.")
    @PostMapping("/send")
    fun sendNotification(
        @RequestBody request: SendNotificationRequest
    ): ResponseEntity<ApiResponse<List<NotificationLogDto>>> {
        val result = notificationService.sendNotification(request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "긴급 알림 발송", description = "긴급 알림을 즉시 발송합니다.")
    @PostMapping("/urgent")
    fun sendUrgentAlert(
        @RequestBody request: SendUrgentAlertRequest
    ): ResponseEntity<ApiResponse<List<NotificationLogDto>>> {
        val result = notificationService.sendUrgentAlert(request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "스케줄 알림 등록", description = "지정된 시간에 발송될 알림을 등록합니다.")
    @PostMapping("/schedule")
    fun scheduleNotification(
        @RequestBody request: ScheduleNotificationRequest
    ): ResponseEntity<ApiResponse<List<NotificationLogDto>>> {
        val result = notificationService.scheduleNotification(request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    // ===== 알림 이력 조회 API =====

    @Operation(summary = "알림 이력 조회", description = "회사의 알림 발송 이력을 조회합니다.")
    @GetMapping("/history")
    fun getNotificationHistory(
        @PageableDefault pageable: Pageable
    ): ResponseEntity<PageResponse<NotificationLogDto>> {
        val result = notificationService.getNotificationHistory(pageable)
        return ResponseEntity.ok(PageResponse.of(result))
    }

    @Operation(summary = "수신자별 알림 이력 조회", description = "특정 수신자의 알림 이력을 조회합니다.")
    @GetMapping("/history/recipient/{recipientId}")
    fun getNotificationHistoryByRecipient(
        @Parameter(description = "수신자 ID") @PathVariable recipientId: UUID,
        @PageableDefault pageable: Pageable
    ): ResponseEntity<PageResponse<NotificationLogDto>> {
        val result = notificationService.getNotificationHistoryByRecipient(recipientId, pageable)
        return ResponseEntity.ok(PageResponse.of(result))
    }

    @Operation(summary = "읽지 않은 알림 개수 조회", description = "특정 수신자의 읽지 않은 알림 개수를 조회합니다.")
    @GetMapping("/unread-count/{recipientId}")
    fun getUnreadNotificationCount(
        @Parameter(description = "수신자 ID") @PathVariable recipientId: UUID
    ): ResponseEntity<ApiResponse<Long>> {
        val count = notificationService.getUnreadNotificationCount(recipientId)
        return ResponseEntity.ok(ApiResponse.success(count))
    }

    @Operation(summary = "알림 읽음 처리", description = "알림을 읽음 상태로 변경합니다.")
    @PutMapping("/{notificationId}/read")
    fun markAsRead(
        @Parameter(description = "알림 ID") @PathVariable notificationId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationService.markAsRead(notificationId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    // ===== 알림 통계 API =====

    @Operation(summary = "알림 통계 조회", description = "지정된 기간의 알림 발송 통계를 조회합니다.")
    @GetMapping("/statistics")
    fun getNotificationStatistics(
        @Parameter(description = "시작 날짜") @RequestParam startDate: LocalDateTime,
        @Parameter(description = "종료 날짜") @RequestParam endDate: LocalDateTime
    ): ResponseEntity<ApiResponse<NotificationStatisticsDto>> {
        val statistics = notificationService.getNotificationStatistics(startDate, endDate)
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    // ===== 알림 설정 관리 API =====

    @Operation(summary = "알림 설정 생성", description = "새로운 알림 설정을 생성합니다.")
    @PostMapping("/settings")
    fun createNotificationSetting(
        @RequestBody request: CreateNotificationSettingRequest
    ): ResponseEntity<ApiResponse<NotificationSettingDto>> {
        val result = notificationSettingService.createNotificationSetting(request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 설정 수정", description = "기존 알림 설정을 수정합니다.")
    @PutMapping("/settings/{settingId}")
    fun updateNotificationSetting(
        @Parameter(description = "설정 ID") @PathVariable settingId: UUID,
        @RequestBody request: UpdateNotificationSettingRequest
    ): ResponseEntity<ApiResponse<NotificationSettingDto>> {
        val result = notificationSettingService.updateNotificationSetting(settingId, request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 설정 조회", description = "특정 알림 설정을 조회합니다.")
    @GetMapping("/settings/{settingId}")
    fun getNotificationSetting(
        @Parameter(description = "설정 ID") @PathVariable settingId: UUID
    ): ResponseEntity<ApiResponse<NotificationSettingDto>> {
        val result = notificationSettingService.getNotificationSetting(settingId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 설정 목록 조회", description = "회사의 모든 알림 설정을 조회합니다.")
    @GetMapping("/settings")
    fun getNotificationSettings(
        @PageableDefault pageable: Pageable
    ): ResponseEntity<PageResponse<NotificationSettingDto>> {
        val result = notificationSettingService.getNotificationSettings(pageable)
        return ResponseEntity.ok(PageResponse.of(result))
    }

    @Operation(summary = "알림 유형별 설정 조회", description = "특정 알림 유형의 활성 설정을 조회합니다.")
    @GetMapping("/settings/type/{notificationType}")
    fun getActiveNotificationSettings(
        @Parameter(description = "알림 유형") @PathVariable notificationType: NotificationType
    ): ResponseEntity<ApiResponse<List<NotificationSettingDto>>> {
        val result = notificationSettingService.getActiveNotificationSettings(notificationType)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "건물별 알림 설정 조회", description = "특정 건물의 알림 설정을 조회합니다.")
    @GetMapping("/settings/building/{buildingId}")
    fun getNotificationSettingsByBuilding(
        @Parameter(description = "건물 ID") @PathVariable buildingId: UUID
    ): ResponseEntity<ApiResponse<List<NotificationSettingDto>>> {
        val result = notificationSettingService.getNotificationSettingsByBuilding(buildingId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 설정 삭제", description = "알림 설정을 삭제합니다.")
    @DeleteMapping("/settings/{settingId}")
    fun deleteNotificationSetting(
        @Parameter(description = "설정 ID") @PathVariable settingId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationSettingService.deleteNotificationSetting(settingId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @Operation(summary = "알림 설정 활성화/비활성화", description = "알림 설정을 활성화하거나 비활성화합니다.")
    @PutMapping("/settings/{settingId}/toggle")
    fun toggleNotificationSetting(
        @Parameter(description = "설정 ID") @PathVariable settingId: UUID,
        @Parameter(description = "활성화 여부") @RequestParam isActive: Boolean
    ): ResponseEntity<ApiResponse<NotificationSettingDto>> {
        val result = notificationSettingService.toggleNotificationSetting(settingId, isActive)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    // ===== 알림 템플릿 관리 API =====

    @Operation(summary = "알림 템플릿 생성", description = "새로운 알림 템플릿을 생성합니다.")
    @PostMapping("/templates")
    fun createNotificationTemplate(
        @RequestBody request: CreateNotificationTemplateRequest
    ): ResponseEntity<ApiResponse<NotificationTemplateDto>> {
        val result = notificationTemplateService.createNotificationTemplate(request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 템플릿 수정", description = "기존 알림 템플릿을 수정합니다.")
    @PutMapping("/templates/{templateId}")
    fun updateNotificationTemplate(
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID,
        @RequestBody request: CreateNotificationTemplateRequest
    ): ResponseEntity<ApiResponse<NotificationTemplateDto>> {
        val result = notificationTemplateService.updateNotificationTemplate(templateId, request)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 템플릿 조회", description = "특정 알림 템플릿을 조회합니다.")
    @GetMapping("/templates/{templateId}")
    fun getNotificationTemplate(
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID
    ): ResponseEntity<ApiResponse<NotificationTemplateDto>> {
        val result = notificationTemplateService.getNotificationTemplate(templateId)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 템플릿 목록 조회", description = "회사의 모든 알림 템플릿을 조회합니다.")
    @GetMapping("/templates")
    fun getNotificationTemplates(
        @PageableDefault pageable: Pageable
    ): ResponseEntity<PageResponse<NotificationTemplateDto>> {
        val result = notificationTemplateService.getNotificationTemplates(pageable)
        return ResponseEntity.ok(PageResponse.of(result))
    }

    @Operation(summary = "알림 유형별 템플릿 조회", description = "특정 알림 유형의 템플릿을 조회합니다.")
    @GetMapping("/templates/type/{notificationType}")
    fun getTemplatesByType(
        @Parameter(description = "알림 유형") @PathVariable notificationType: NotificationType
    ): ResponseEntity<ApiResponse<List<NotificationTemplateDto>>> {
        val result = notificationTemplateService.getTemplatesByType(notificationType)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "채널별 템플릿 조회", description = "특정 채널의 템플릿을 조회합니다.")
    @GetMapping("/templates/channel/{channel}")
    fun getTemplatesByChannel(
        @Parameter(description = "알림 채널") @PathVariable channel: NotificationMethod
    ): ResponseEntity<ApiResponse<List<NotificationTemplateDto>>> {
        val result = notificationTemplateService.getTemplatesByChannel(channel)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "기본 템플릿 조회", description = "특정 유형과 채널의 기본 템플릿을 조회합니다.")
    @GetMapping("/templates/default")
    fun getDefaultTemplate(
        @Parameter(description = "알림 유형") @RequestParam notificationType: NotificationType,
        @Parameter(description = "알림 채널") @RequestParam channel: NotificationMethod
    ): ResponseEntity<ApiResponse<NotificationTemplateDto?>> {
        val result = notificationTemplateService.getDefaultTemplate(notificationType, channel)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "템플릿 미리보기", description = "템플릿을 변수와 함께 렌더링하여 미리보기합니다.")
    @PostMapping("/templates/{templateId}/preview")
    fun previewTemplate(
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID,
        @RequestBody variables: Map<String, Any>
    ): ResponseEntity<ApiResponse<Map<String, String>>> {
        val result = notificationTemplateService.previewTemplate(templateId, variables)
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    @Operation(summary = "알림 템플릿 삭제", description = "알림 템플릿을 삭제합니다.")
    @DeleteMapping("/templates/{templateId}")
    fun deleteNotificationTemplate(
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationTemplateService.deleteNotificationTemplate(templateId)
        return ResponseEntity.ok(ApiResponse.success())
    }

    // ===== 긴급 알림 및 에스컬레이션 API =====

    @Operation(summary = "시설 긴급 알림 발송", description = "시설 고장에 대한 긴급 알림을 발송합니다.")
    @PostMapping("/emergency/facility")
    fun triggerFacilityEmergencyAlert(
        @Parameter(description = "시설명") @RequestParam facilityName: String,
        @Parameter(description = "고장 내용") @RequestParam faultDescription: String,
        @Parameter(description = "위치") @RequestParam location: String,
        @Parameter(description = "신고자 ID") @RequestParam reporterId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationEscalationService.triggerFacilityEmergencyAlert(
            facilityName, faultDescription, location, reporterId
        )
        return ResponseEntity.ok(ApiResponse.success())
    }

    @Operation(summary = "안전 사고 긴급 알림 발송", description = "안전 사고에 대한 긴급 알림을 발송합니다.")
    @PostMapping("/emergency/safety")
    fun triggerSafetyEmergencyAlert(
        @Parameter(description = "사고 유형") @RequestParam incidentType: String,
        @Parameter(description = "위치") @RequestParam location: String,
        @Parameter(description = "심각도") @RequestParam severity: String,
        @Parameter(description = "상세 내용") @RequestParam description: String
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationEscalationService.triggerSafetyEmergencyAlert(
            incidentType, location, severity, description
        )
        return ResponseEntity.ok(ApiResponse.success())
    }

    @Operation(summary = "에스컬레이션 중단", description = "진행 중인 에스컬레이션을 중단합니다.")
    @PostMapping("/escalation/{alertId}/stop")
    fun stopEscalation(
        @Parameter(description = "알림 ID") @PathVariable alertId: UUID,
        @Parameter(description = "중단 사유") @RequestParam reason: String
    ): ResponseEntity<ApiResponse<Unit>> {
        notificationEscalationService.stopEscalation(alertId, reason)
        return ResponseEntity.ok(ApiResponse.success())
    }

    @Operation(summary = "에스컬레이션 상태 조회", description = "에스컬레이션 진행 상태를 조회합니다.")
    @GetMapping("/escalation/{alertId}/status")
    fun getEscalationStatus(
        @Parameter(description = "알림 ID") @PathVariable alertId: UUID
    ): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val status = notificationEscalationService.getEscalationStatus(alertId)
        return ResponseEntity.ok(ApiResponse.success(status))
    }

    // ===== 시스템 관리 API =====

    @Operation(summary = "실패한 알림 재시도", description = "실패한 알림을 재시도합니다.")
    @PostMapping("/retry-failed")
    fun retryFailedNotifications(): ResponseEntity<ApiResponse<Unit>> {
        notificationService.retryFailedNotifications()
        return ResponseEntity.ok(ApiResponse.success())
    }

    @Operation(summary = "만료된 알림 정리", description = "만료된 알림을 정리합니다.")
    @PostMapping("/cleanup-expired")
    fun cleanupExpiredNotifications(): ResponseEntity<ApiResponse<Unit>> {
        notificationService.cleanupExpiredNotifications()
        return ResponseEntity.ok(ApiResponse.success())
    }
}