package com.qiro.domain.notification.dto

import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationStatus
import com.qiro.domain.notification.entity.NotificationType
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 발송 요청 DTO
 */
data class SendNotificationRequest(
    val recipientIds: List<UUID>,
    val notificationType: NotificationType,
    val title: String,
    val message: String,
    val channels: Set<NotificationMethod> = setOf(NotificationMethod.EMAIL),
    val priorityLevel: Int = 3,
    val scheduledAt: LocalDateTime? = null,
    val expiresAt: LocalDateTime? = null,
    val metadata: Map<String, Any> = emptyMap(),
    val templateId: UUID? = null,
    val templateVariables: Map<String, Any> = emptyMap()
)

/**
 * 긴급 알림 발송 요청 DTO
 */
data class SendUrgentAlertRequest(
    val recipientIds: List<UUID>,
    val title: String,
    val message: String,
    val channels: Set<NotificationMethod> = setOf(NotificationMethod.SMS, NotificationMethod.PUSH),
    val metadata: Map<String, Any> = emptyMap()
)

/**
 * 스케줄 알림 요청 DTO
 */
data class ScheduleNotificationRequest(
    val recipientIds: List<UUID>,
    val notificationType: NotificationType,
    val title: String,
    val message: String,
    val channels: Set<NotificationMethod> = setOf(NotificationMethod.EMAIL),
    val scheduledAt: LocalDateTime,
    val priorityLevel: Int = 3,
    val expiresAt: LocalDateTime? = null,
    val metadata: Map<String, Any> = emptyMap()
)

/**
 * 알림 로그 응답 DTO
 */
data class NotificationLogDto(
    val id: UUID,
    val recipientId: UUID,
    val notificationType: NotificationType,
    val title: String,
    val message: String,
    val channel: NotificationMethod,
    val status: NotificationStatus,
    val sentAt: LocalDateTime?,
    val readAt: LocalDateTime?,
    val retryCount: Int,
    val errorMessage: String?,
    val priorityLevel: Int,
    val scheduledAt: LocalDateTime?,
    val expiresAt: LocalDateTime?,
    val createdAt: LocalDateTime
)

/**
 * 알림 설정 생성 요청 DTO
 */
data class CreateNotificationSettingRequest(
    val buildingId: UUID? = null,
    val notificationType: NotificationType,
    val notificationName: String,
    val notificationDescription: String? = null,
    val triggerCondition: Map<String, Any> = emptyMap(),
    val triggerSchedule: String? = null,
    val recipientType: String,
    val recipientList: List<String> = emptyList(),
    val notificationMethods: Set<NotificationMethod> = setOf(NotificationMethod.EMAIL),
    val subjectTemplate: String? = null,
    val messageTemplate: String? = null,
    val priorityLevel: Int = 3,
    val retryCount: Int = 3,
    val retryInterval: Int = 300,
    val dailyLimit: Int? = null,
    val hourlyLimit: Int? = null
)

/**
 * 알림 설정 업데이트 요청 DTO
 */
data class UpdateNotificationSettingRequest(
    val notificationName: String? = null,
    val notificationDescription: String? = null,
    val triggerCondition: Map<String, Any>? = null,
    val triggerSchedule: String? = null,
    val recipientList: List<String>? = null,
    val notificationMethods: Set<NotificationMethod>? = null,
    val subjectTemplate: String? = null,
    val messageTemplate: String? = null,
    val isActive: Boolean? = null,
    val priorityLevel: Int? = null,
    val retryCount: Int? = null,
    val retryInterval: Int? = null,
    val dailyLimit: Int? = null,
    val hourlyLimit: Int? = null
)

/**
 * 알림 설정 응답 DTO
 */
data class NotificationSettingDto(
    val id: UUID,
    val buildingId: UUID?,
    val notificationType: NotificationType,
    val notificationName: String,
    val notificationDescription: String?,
    val triggerCondition: Map<String, Any>,
    val triggerSchedule: String?,
    val recipientType: String,
    val recipientList: List<String>,
    val notificationMethods: Set<NotificationMethod>,
    val subjectTemplate: String?,
    val messageTemplate: String?,
    val isActive: Boolean,
    val priorityLevel: Int,
    val retryCount: Int,
    val retryInterval: Int,
    val dailyLimit: Int?,
    val hourlyLimit: Int?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

/**
 * 알림 통계 DTO
 */
data class NotificationStatisticsDto(
    val totalSent: Long,
    val totalDelivered: Long,
    val totalFailed: Long,
    val totalRead: Long,
    val deliveryRate: Double,
    val readRate: Double,
    val failureRate: Double,
    val statisticsByChannel: Map<NotificationMethod, ChannelStatistics>,
    val statisticsByType: Map<NotificationType, TypeStatistics>
)

/**
 * 채널별 통계 DTO
 */
data class ChannelStatistics(
    val sent: Long,
    val delivered: Long,
    val failed: Long,
    val deliveryRate: Double
)

/**
 * 유형별 통계 DTO
 */
data class TypeStatistics(
    val sent: Long,
    val delivered: Long,
    val read: Long,
    val readRate: Double
)

/**
 * 알림 템플릿 생성 요청 DTO
 */
data class CreateNotificationTemplateRequest(
    val templateName: String,
    val templateDescription: String? = null,
    val templateType: NotificationType,
    val channel: NotificationMethod,
    val subjectTemplate: String? = null,
    val bodyTemplate: String,
    val variables: List<String> = emptyList(),
    val isDefault: Boolean = false,
    val languageCode: String = "ko"
)

/**
 * 알림 템플릿 응답 DTO
 */
data class NotificationTemplateDto(
    val id: UUID,
    val templateName: String,
    val templateDescription: String?,
    val templateType: NotificationType,
    val channel: NotificationMethod,
    val subjectTemplate: String?,
    val bodyTemplate: String,
    val variables: List<String>,
    val isActive: Boolean,
    val isDefault: Boolean,
    val languageCode: String,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)