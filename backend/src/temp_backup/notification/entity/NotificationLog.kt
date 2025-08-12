package com.qiro.domain.notification.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 로그 엔티티
 * 발송된 알림의 이력을 관리합니다.
 */
@Entity
@Table(
    name = "notification_logs",
    schema = "bms",
    indexes = [
        Index(name = "idx_notification_logs_company_id", columnList = "company_id"),
        Index(name = "idx_notification_logs_recipient_id", columnList = "recipient_id"),
        Index(name = "idx_notification_logs_type", columnList = "notification_type"),
        Index(name = "idx_notification_logs_status", columnList = "status"),
        Index(name = "idx_notification_logs_sent_at", columnList = "sent_at"),
        Index(name = "idx_notification_logs_channel", columnList = "channel")
    ]
)
class NotificationLog : TenantAwareEntity() {

    @Id
    @GeneratedValue
    @Column(name = "notification_log_id")
    val id: UUID = UUID.randomUUID()

    @Column(name = "notification_setting_id")
    var notificationSettingId: UUID? = null

    @Column(name = "recipient_id", nullable = false)
    var recipientId: UUID = UUID.randomUUID()

    @Enumerated(EnumType.STRING)
    @Column(name = "notification_type", nullable = false, length = 50)
    var notificationType: NotificationType = NotificationType.CUSTOM

    @Column(name = "title", nullable = false, length = 200)
    var title: String = ""

    @Column(name = "message", nullable = false)
    var message: String = ""

    @Enumerated(EnumType.STRING)
    @Column(name = "channel", nullable = false, length = 20)
    var channel: NotificationMethod = NotificationMethod.EMAIL

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: NotificationStatus = NotificationStatus.PENDING

    @Column(name = "sent_at")
    var sentAt: LocalDateTime? = null

    @Column(name = "read_at")
    var readAt: LocalDateTime? = null

    @Column(name = "retry_count")
    var retryCount: Int = 0

    @Column(name = "error_message")
    var errorMessage: String? = null

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "metadata", columnDefinition = "jsonb")
    var metadata: Map<String, Any> = emptyMap()

    @Column(name = "external_id")
    var externalId: String? = null // 외부 서비스의 메시지 ID

    @Column(name = "priority_level")
    var priorityLevel: Int = 3

    @Column(name = "scheduled_at")
    var scheduledAt: LocalDateTime? = null

    @Column(name = "expires_at")
    var expiresAt: LocalDateTime? = null
}

/**
 * 알림 상태 열거형
 */
enum class NotificationStatus {
    PENDING,    // 대기중
    SENT,       // 발송됨
    DELIVERED,  // 전달됨
    READ,       // 읽음
    FAILED,     // 실패
    EXPIRED,    // 만료됨
    CANCELLED   // 취소됨
}