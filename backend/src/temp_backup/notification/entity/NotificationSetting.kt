package com.qiro.domain.notification.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.util.*

/**
 * 알림 설정 엔티티
 * 다양한 알림 유형에 대한 설정을 관리합니다.
 */
@Entity
@Table(
    name = "notification_settings",
    schema = "bms",
    indexes = [
        Index(name = "idx_notification_settings_company_id", columnList = "company_id"),
        Index(name = "idx_notification_settings_building_id", columnList = "building_id"),
        Index(name = "idx_notification_settings_company_type", columnList = "company_id, notification_type"),
        Index(name = "idx_notification_settings_type", columnList = "notification_type"),
        Index(name = "idx_notification_settings_is_active", columnList = "is_active"),
        Index(name = "idx_notification_settings_priority", columnList = "priority_level")
    ]
)
class NotificationSetting : TenantAwareEntity() {

    @Id
    @GeneratedValue
    @Column(name = "notification_id")
    val id: UUID = UUID.randomUUID()

    @Column(name = "building_id")
    var buildingId: UUID? = null

    @Enumerated(EnumType.STRING)
    @Column(name = "notification_type", nullable = false, length = 50)
    var notificationType: NotificationType = NotificationType.CUSTOM

    @Column(name = "notification_name", nullable = false, length = 200)
    var notificationName: String = ""

    @Column(name = "notification_description")
    var notificationDescription: String? = null

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "trigger_condition", nullable = false, columnDefinition = "jsonb")
    var triggerCondition: Map<String, Any> = emptyMap()

    @Column(name = "trigger_schedule", length = 100)
    var triggerSchedule: String? = null

    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_type", nullable = false, length = 30)
    var recipientType: RecipientType = RecipientType.USER

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "recipient_list", columnDefinition = "jsonb")
    var recipientList: List<String> = emptyList()

    @ElementCollection
    @Enumerated(EnumType.STRING)
    @CollectionTable(
        name = "notification_methods",
        joinColumns = [JoinColumn(name = "notification_id")]
    )
    @Column(name = "method")
    var notificationMethods: Set<NotificationMethod> = setOf(NotificationMethod.EMAIL)

    @Column(name = "email_template_id")
    var emailTemplateId: UUID? = null

    @Column(name = "sms_template_id")
    var smsTemplateId: UUID? = null

    @Column(name = "subject_template")
    var subjectTemplate: String? = null

    @Column(name = "message_template")
    var messageTemplate: String? = null

    @Column(name = "is_active")
    var isActive: Boolean = true

    @Column(name = "priority_level")
    var priorityLevel: Int = 3

    @Column(name = "retry_count")
    var retryCount: Int = 3

    @Column(name = "retry_interval")
    var retryInterval: Int = 300 // seconds

    @Column(name = "daily_limit")
    var dailyLimit: Int? = null

    @Column(name = "hourly_limit")
    var hourlyLimit: Int? = null

    @Column(name = "created_by")
    var createdBy: UUID? = null

    @Column(name = "updated_by")
    var updatedBy: UUID? = null
}

/**
 * 알림 유형 열거형
 */
enum class NotificationType {
    CONTRACT_EXPIRY,        // 계약 만료
    PAYMENT_DUE,           // 결제 예정
    PAYMENT_OVERDUE,       // 결제 연체
    MAINTENANCE_DUE,       // 정비 예정
    FACILITY_ALERT,        // 시설 경고
    SYSTEM_ALERT,          // 시스템 경고
    TENANT_MOVE_IN,        // 입주
    TENANT_MOVE_OUT,       // 퇴거
    INSPECTION_REMINDER,   // 점검 알림
    FAULT_REPORT,          // 고장 신고
    WORK_ORDER_ASSIGNED,   // 작업 지시 배정
    WORK_ORDER_COMPLETED,  // 작업 완료
    URGENT_ALERT,          // 긴급 알림
    CUSTOM                 // 사용자 정의
}

/**
 * 수신자 유형 열거형
 */
enum class RecipientType {
    USER,      // 사용자
    ROLE,      // 역할
    TENANT,    // 임차인
    LESSOR,    // 임대인
    MANAGER,   // 관리자
    EXTERNAL,  // 외부
    CUSTOM     // 사용자 정의
}

/**
 * 알림 방법 열거형
 */
enum class NotificationMethod {
    EMAIL,     // 이메일
    SMS,       // SMS
    PUSH,      // 푸시 알림
    IN_APP     // 앱 내 알림
}