package com.qiro.domain.notification.service

import com.qiro.common.tenant.TenantContext
import com.qiro.domain.notification.dto.SendUrgentAlertRequest
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationType
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Async
import org.springframework.stereotype.Service
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 에스컬레이션 서비스
 * 긴급 알림 및 에스컬레이션 로직을 처리합니다.
 */
@Service
class NotificationEscalationService(
    private val notificationService: NotificationService,
    private val notificationSettingService: NotificationSettingService
) {
    private val logger = LoggerFactory.getLogger(NotificationEscalationService::class.java)

    /**
     * 긴급 알림 발송 및 에스컬레이션 시작
     */
    @Async
    fun triggerUrgentAlert(
        title: String,
        message: String,
        metadata: Map<String, Any> = emptyMap()
    ) {
        val companyId = TenantContext.getCurrentCompanyId()
        
        try {
            // 1단계: 긴급 알림 설정 조회
            val urgentSettings = notificationSettingService.getUrgentNotificationSettings()
            
            if (urgentSettings.isEmpty()) {
                logger.warn("긴급 알림 설정이 없습니다. 회사 ID: $companyId")
                return
            }

            // 2단계: 1차 긴급 알림 발송 (SMS + 푸시)
            val primaryRecipients = getUrgentRecipients(urgentSettings, 1)
            if (primaryRecipients.isNotEmpty()) {
                val urgentRequest = SendUrgentAlertRequest(
                    recipientIds = primaryRecipients,
                    title = "[긴급] $title",
                    message = message,
                    channels = setOf(NotificationMethod.SMS, NotificationMethod.PUSH),
                    metadata = metadata + mapOf("escalation_level" to 1)
                )
                
                notificationService.sendUrgentAlert(urgentRequest)
                logger.info("1차 긴급 알림 발송 완료 - 수신자 ${primaryRecipients.size}명")
            }

            // 3단계: 에스컬레이션 스케줄링 (15분 후)
            scheduleEscalation(title, message, metadata, 2, 15)
            
        } catch (e: Exception) {
            logger.error("긴급 알림 발송 실패", e)
        }
    }

    /**
     * 시설 고장 긴급 알림
     */
    @Async
    fun triggerFacilityEmergencyAlert(
        facilityName: String,
        faultDescription: String,
        location: String,
        reporterId: UUID
    ) {
        val title = "시설 긴급 고장 신고"
        val message = """
            시설명: $facilityName
            위치: $location
            고장 내용: $faultDescription
            신고자: $reporterId
            신고 시간: ${LocalDateTime.now()}
        """.trimIndent()

        val metadata = mapOf(
            "type" to "facility_emergency",
            "facility_name" to facilityName,
            "location" to location,
            "reporter_id" to reporterId.toString()
        )

        triggerUrgentAlert(title, message, metadata)
    }

    /**
     * 안전 사고 긴급 알림
     */
    @Async
    fun triggerSafetyEmergencyAlert(
        incidentType: String,
        location: String,
        severity: String,
        description: String
    ) {
        val title = "안전 사고 발생"
        val message = """
            사고 유형: $incidentType
            위치: $location
            심각도: $severity
            상세 내용: $description
            발생 시간: ${LocalDateTime.now()}
        """.trimIndent()

        val metadata = mapOf(
            "type" to "safety_emergency",
            "incident_type" to incidentType,
            "location" to location,
            "severity" to severity
        )

        triggerUrgentAlert(title, message, metadata)
    }

    /**
     * 시스템 장애 긴급 알림
     */
    @Async
    fun triggerSystemEmergencyAlert(
        systemName: String,
        errorMessage: String,
        impactLevel: String
    ) {
        val title = "시스템 장애 발생"
        val message = """
            시스템: $systemName
            오류 내용: $errorMessage
            영향도: $impactLevel
            발생 시간: ${LocalDateTime.now()}
        """.trimIndent()

        val metadata = mapOf(
            "type" to "system_emergency",
            "system_name" to systemName,
            "impact_level" to impactLevel
        )

        triggerUrgentAlert(title, message, metadata)
    }

    /**
     * 에스컬레이션 스케줄링
     */
    private fun scheduleEscalation(
        title: String,
        message: String,
        metadata: Map<String, Any>,
        escalationLevel: Int,
        delayMinutes: Long
    ) {
        // TODO: 실제 구현에서는 스케줄러 사용 (예: @Scheduled, Quartz 등)
        // 현재는 로깅만 수행
        logger.info("에스컬레이션 스케줄링 - 레벨: $escalationLevel, 지연: ${delayMinutes}분")
        
        // 임시로 즉시 에스컬레이션 실행 (실제로는 스케줄러에서 처리)
        if (escalationLevel <= 3) {
            executeEscalation(title, message, metadata, escalationLevel)
        }
    }

    /**
     * 에스컬레이션 실행
     */
    private fun executeEscalation(
        title: String,
        message: String,
        metadata: Map<String, Any>,
        escalationLevel: Int
    ) {
        try {
            val urgentSettings = notificationSettingService.getUrgentNotificationSettings()
            val recipients = getUrgentRecipients(urgentSettings, escalationLevel)
            
            if (recipients.isEmpty()) {
                logger.warn("에스컬레이션 레벨 $escalationLevel 에 대한 수신자가 없습니다.")
                return
            }

            val escalationChannels = when (escalationLevel) {
                2 -> setOf(NotificationMethod.SMS, NotificationMethod.EMAIL, NotificationMethod.PUSH)
                3 -> setOf(NotificationMethod.SMS, NotificationMethod.EMAIL) // 최고 관리자에게는 SMS + 이메일
                else -> setOf(NotificationMethod.SMS, NotificationMethod.PUSH)
            }

            val urgentRequest = SendUrgentAlertRequest(
                recipientIds = recipients,
                title = "[에스컬레이션 $escalationLevel] $title",
                message = "$message\n\n※ 이 알림은 ${escalationLevel}차 에스컬레이션입니다.",
                channels = escalationChannels,
                metadata = metadata + mapOf("escalation_level" to escalationLevel)
            )

            notificationService.sendUrgentAlert(urgentRequest)
            logger.info("${escalationLevel}차 에스컬레이션 알림 발송 완료 - 수신자 ${recipients.size}명")

            // 다음 단계 에스컬레이션 스케줄링
            if (escalationLevel < 3) {
                val nextDelay = when (escalationLevel) {
                    1 -> 15L // 1차 → 2차: 15분
                    2 -> 30L // 2차 → 3차: 30분
                    else -> 0L
                }
                if (nextDelay > 0) {
                    scheduleEscalation(title, message, metadata, escalationLevel + 1, nextDelay)
                }
            }

        } catch (e: Exception) {
            logger.error("에스컬레이션 실행 실패 - 레벨: $escalationLevel", e)
        }
    }

    /**
     * 에스컬레이션 레벨별 수신자 조회
     */
    private fun getUrgentRecipients(
        urgentSettings: List<com.qiro.domain.notification.dto.NotificationSettingDto>,
        escalationLevel: Int
    ): List<UUID> {
        return urgentSettings
            .filter { it.priorityLevel <= escalationLevel }
            .flatMap { setting ->
                setting.recipientList.mapNotNull { recipientId ->
                    try {
                        UUID.fromString(recipientId)
                    } catch (e: IllegalArgumentException) {
                        logger.warn("잘못된 수신자 ID 형식: $recipientId")
                        null
                    }
                }
            }
            .distinct()
    }

    /**
     * 에스컬레이션 중단
     */
    fun stopEscalation(alertId: UUID, reason: String) {
        // TODO: 스케줄된 에스컬레이션 취소
        logger.info("에스컬레이션 중단 - 알림 ID: $alertId, 사유: $reason")
    }

    /**
     * 에스컬레이션 상태 조회
     */
    fun getEscalationStatus(alertId: UUID): Map<String, Any> {
        // TODO: 에스컬레이션 상태 조회 구현
        return mapOf(
            "alert_id" to alertId,
            "current_level" to 1,
            "max_level" to 3,
            "status" to "active",
            "next_escalation_at" to LocalDateTime.now().plusMinutes(15)
        )
    }
}