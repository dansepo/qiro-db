package com.qiro.domain.notification.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.notification.dto.*
import com.qiro.domain.notification.entity.*
import com.qiro.domain.notification.repository.NotificationLogRepository
import com.qiro.domain.notification.repository.NotificationSettingRepository
import com.qiro.domain.notification.repository.NotificationTemplateRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 서비스
 * 다채널 알림 발송, 템플릿 관리, 자동 발송 규칙 등을 처리합니다.
 */
@Service
@Transactional
class NotificationService(
    private val notificationLogRepository: NotificationLogRepository,
    private val notificationSettingRepository: NotificationSettingRepository,
    private val notificationTemplateRepository: NotificationTemplateRepository,
    private val emailNotificationService: EmailNotificationService,
    private val smsNotificationService: SmsNotificationService,
    private val pushNotificationService: PushNotificationService
) {
    private val logger = LoggerFactory.getLogger(NotificationService::class.java)

    /**
     * 알림 발송
     */
    fun sendNotification(request: SendNotificationRequest): List<NotificationLogDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val results = mutableListOf<NotificationLogDto>()

        // 템플릿 사용 시 메시지 렌더링
        val (finalTitle, finalMessage) = if (request.templateId != null) {
            renderTemplate(request.templateId, request.templateVariables, request.channels.first())
        } else {
            Pair(request.title, request.message)
        }

        request.recipientIds.forEach { recipientId ->
            request.channels.forEach { channel ->
                try {
                    val notificationLog = createNotificationLog(
                        companyId = companyId,
                        recipientId = recipientId,
                        notificationType = request.notificationType,
                        title = finalTitle,
                        message = finalMessage,
                        channel = channel,
                        priorityLevel = request.priorityLevel,
                        scheduledAt = request.scheduledAt,
                        expiresAt = request.expiresAt,
                        metadata = request.metadata
                    )

                    // 즉시 발송 또는 스케줄 발송
                    if (request.scheduledAt == null || request.scheduledAt.isBefore(LocalDateTime.now())) {
                        sendNotificationByChannel(notificationLog, channel)
                    }

                    results.add(notificationLog.toDto())
                } catch (e: Exception) {
                    logger.error("알림 발송 실패 - 수신자: $recipientId, 채널: $channel", e)
                }
            }
        }

        return results
    }

    /**
     * 긴급 알림 발송
     */
    fun sendUrgentAlert(request: SendUrgentAlertRequest): List<NotificationLogDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val results = mutableListOf<NotificationLogDto>()

        // 긴급 알림은 최고 우선순위로 즉시 발송
        request.recipientIds.forEach { recipientId ->
            request.channels.forEach { channel ->
                try {
                    val notificationLog = createNotificationLog(
                        companyId = companyId,
                        recipientId = recipientId,
                        notificationType = NotificationType.URGENT_ALERT,
                        title = request.title,
                        message = request.message,
                        channel = channel,
                        priorityLevel = 1, // 최고 우선순위
                        metadata = request.metadata
                    )

                    sendNotificationByChannel(notificationLog, channel)
                    results.add(notificationLog.toDto())
                } catch (e: Exception) {
                    logger.error("긴급 알림 발송 실패 - 수신자: $recipientId, 채널: $channel", e)
                }
            }
        }

        return results
    }

    /**
     * 스케줄 알림 등록
     */
    fun scheduleNotification(request: ScheduleNotificationRequest): List<NotificationLogDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val results = mutableListOf<NotificationLogDto>()

        request.recipientIds.forEach { recipientId ->
            request.channels.forEach { channel ->
                val notificationLog = createNotificationLog(
                    companyId = companyId,
                    recipientId = recipientId,
                    notificationType = request.notificationType,
                    title = request.title,
                    message = request.message,
                    channel = channel,
                    priorityLevel = request.priorityLevel,
                    scheduledAt = request.scheduledAt,
                    expiresAt = request.expiresAt,
                    metadata = request.metadata
                )

                results.add(notificationLog.toDto())
            }
        }

        return results
    }

    /**
     * 알림 이력 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationHistory(pageable: Pageable): Page<NotificationLogDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationLogRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 수신자별 알림 이력 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationHistoryByRecipient(recipientId: UUID, pageable: Pageable): Page<NotificationLogDto> {
        return notificationLogRepository.findByRecipientIdOrderByCreatedAtDesc(recipientId, pageable)
            .map { it.toDto() }
    }

    /**
     * 읽지 않은 알림 개수 조회
     */
    @Transactional(readOnly = true)
    fun getUnreadNotificationCount(recipientId: UUID): Long {
        return notificationLogRepository.countUnreadNotifications(recipientId)
    }

    /**
     * 알림 읽음 처리
     */
    fun markAsRead(notificationId: UUID) {
        val notification = notificationLogRepository.findById(notificationId)
            .orElseThrow { BusinessException(ErrorCode.NOTIFICATION_NOT_FOUND) }

        notification.readAt = LocalDateTime.now()
        notification.status = NotificationStatus.READ
        notificationLogRepository.save(notification)
    }

    /**
     * 실패한 알림 재시도
     */
    fun retryFailedNotifications() {
        val companyId = TenantContext.getCurrentCompanyId()
        val since = LocalDateTime.now().minusHours(24) // 24시간 이내 실패한 알림만 재시도

        val failedNotifications = notificationLogRepository.findFailedNotificationsForRetry(companyId, since)

        failedNotifications.forEach { notification ->
            try {
                sendNotificationByChannel(notification, notification.channel)
                logger.info("알림 재시도 성공 - ID: ${notification.id}")
            } catch (e: Exception) {
                notification.retryCount++
                notification.errorMessage = e.message
                notificationLogRepository.save(notification)
                logger.error("알림 재시도 실패 - ID: ${notification.id}", e)
            }
        }
    }

    /**
     * 만료된 알림 정리
     */
    fun cleanupExpiredNotifications() {
        val expiredNotifications = notificationLogRepository.findExpiredNotifications(LocalDateTime.now())
        
        expiredNotifications.forEach { notification ->
            notification.status = NotificationStatus.EXPIRED
        }
        
        notificationLogRepository.saveAll(expiredNotifications)
        logger.info("만료된 알림 ${expiredNotifications.size}개 정리 완료")
    }

    /**
     * 알림 통계 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationStatistics(startDate: LocalDateTime, endDate: LocalDateTime): NotificationStatisticsDto {
        val companyId = TenantContext.getCurrentCompanyId()
        val statistics = notificationLogRepository.getNotificationStatistics(companyId, startDate, endDate)

        var totalSent = 0L
        var totalDelivered = 0L
        var totalFailed = 0L
        var totalRead = 0L

        statistics.forEach { stat ->
            val status = stat[0] as NotificationStatus
            val count = stat[1] as Long

            when (status) {
                NotificationStatus.SENT, NotificationStatus.DELIVERED -> {
                    totalSent += count
                    if (status == NotificationStatus.DELIVERED) totalDelivered += count
                }
                NotificationStatus.FAILED -> totalFailed += count
                NotificationStatus.READ -> totalRead += count
                else -> {}
            }
        }

        val deliveryRate = if (totalSent > 0) totalDelivered.toDouble() / totalSent else 0.0
        val readRate = if (totalDelivered > 0) totalRead.toDouble() / totalDelivered else 0.0
        val failureRate = if ((totalSent + totalFailed) > 0) totalFailed.toDouble() / (totalSent + totalFailed) else 0.0

        return NotificationStatisticsDto(
            totalSent = totalSent,
            totalDelivered = totalDelivered,
            totalFailed = totalFailed,
            totalRead = totalRead,
            deliveryRate = deliveryRate,
            readRate = readRate,
            failureRate = failureRate,
            statisticsByChannel = emptyMap(), // TODO: 채널별 통계 구현
            statisticsByType = emptyMap() // TODO: 유형별 통계 구현
        )
    }

    /**
     * 채널별 알림 발송
     */
    private fun sendNotificationByChannel(notification: NotificationLog, channel: NotificationMethod) {
        try {
            when (channel) {
                NotificationMethod.EMAIL -> {
                    emailNotificationService.sendEmail(notification)
                }
                NotificationMethod.SMS -> {
                    smsNotificationService.sendSms(notification)
                }
                NotificationMethod.PUSH -> {
                    pushNotificationService.sendPush(notification)
                }
                NotificationMethod.IN_APP -> {
                    // 인앱 알림은 DB 저장만으로 처리
                }
            }

            notification.status = NotificationStatus.SENT
            notification.sentAt = LocalDateTime.now()
        } catch (e: Exception) {
            notification.status = NotificationStatus.FAILED
            notification.errorMessage = e.message
            notification.retryCount++
            throw e
        } finally {
            notificationLogRepository.save(notification)
        }
    }

    /**
     * 알림 로그 생성
     */
    private fun createNotificationLog(
        companyId: UUID,
        recipientId: UUID,
        notificationType: NotificationType,
        title: String,
        message: String,
        channel: NotificationMethod,
        priorityLevel: Int = 3,
        scheduledAt: LocalDateTime? = null,
        expiresAt: LocalDateTime? = null,
        metadata: Map<String, Any> = emptyMap()
    ): NotificationLog {
        val notification = NotificationLog().apply {
            this.companyId = companyId
            this.recipientId = recipientId
            this.notificationType = notificationType
            this.title = title
            this.message = message
            this.channel = channel
            this.status = if (scheduledAt != null && scheduledAt.isAfter(LocalDateTime.now())) 
                NotificationStatus.PENDING else NotificationStatus.PENDING
            this.priorityLevel = priorityLevel
            this.scheduledAt = scheduledAt
            this.expiresAt = expiresAt
            this.metadata = metadata
        }

        return notificationLogRepository.save(notification)
    }

    /**
     * 템플릿 렌더링
     */
    private fun renderTemplate(
        templateId: UUID,
        variables: Map<String, Any>,
        channel: NotificationMethod
    ): Pair<String, String> {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        val title = template.renderSubject(variables) ?: ""
        val message = template.renderTemplate(variables)

        return Pair(title, message)
    }
}

/**
 * NotificationLog 확장 함수
 */
private fun NotificationLog.toDto(): NotificationLogDto {
    return NotificationLogDto(
        id = this.id,
        recipientId = this.recipientId,
        notificationType = this.notificationType,
        title = this.title,
        message = this.message,
        channel = this.channel,
        status = this.status,
        sentAt = this.sentAt,
        readAt = this.readAt,
        retryCount = this.retryCount,
        errorMessage = this.errorMessage,
        priorityLevel = this.priorityLevel,
        scheduledAt = this.scheduledAt,
        expiresAt = this.expiresAt,
        createdAt = this.createdAt
    )
}