package com.qiro.domain.notification.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.util.*

/**
 * 알림 템플릿 엔티티
 * 알림 메시지 템플릿을 관리합니다.
 */
@Entity
@Table(
    name = "notification_templates",
    schema = "bms",
    indexes = [
        Index(name = "idx_notification_templates_company_id", columnList = "company_id"),
        Index(name = "idx_notification_templates_type", columnList = "template_type"),
        Index(name = "idx_notification_templates_channel", columnList = "channel"),
        Index(name = "idx_notification_templates_is_active", columnList = "is_active")
    ]
)
class NotificationTemplate : TenantAwareEntity() {

    @Id
    @GeneratedValue
    @Column(name = "template_id")
    val id: UUID = UUID.randomUUID()

    @Column(name = "template_name", nullable = false, length = 100)
    var templateName: String = ""

    @Column(name = "template_description")
    var templateDescription: String? = null

    @Enumerated(EnumType.STRING)
    @Column(name = "template_type", nullable = false, length = 50)
    var templateType: NotificationType = NotificationType.CUSTOM

    @Enumerated(EnumType.STRING)
    @Column(name = "channel", nullable = false, length = 20)
    var channel: NotificationMethod = NotificationMethod.EMAIL

    @Column(name = "subject_template", length = 200)
    var subjectTemplate: String? = null

    @Column(name = "body_template", nullable = false)
    var bodyTemplate: String = ""

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "variables", columnDefinition = "jsonb")
    var variables: List<String> = emptyList() // 템플릿에서 사용 가능한 변수 목록

    @Column(name = "is_active")
    var isActive: Boolean = true

    @Column(name = "is_default")
    var isDefault: Boolean = false

    @Column(name = "language_code", length = 10)
    var languageCode: String = "ko"

    @Column(name = "created_by")
    var createdBy: UUID? = null

    @Column(name = "updated_by")
    var updatedBy: UUID? = null

    /**
     * 템플릿 변수를 실제 값으로 치환합니다.
     */
    fun renderTemplate(variables: Map<String, Any>): String {
        var rendered = bodyTemplate
        variables.forEach { (key, value) ->
            rendered = rendered.replace("{{$key}}", value.toString())
        }
        return rendered
    }

    /**
     * 제목 템플릿을 렌더링합니다.
     */
    fun renderSubject(variables: Map<String, Any>): String? {
        return subjectTemplate?.let { template ->
            var rendered = template
            variables.forEach { (key, value) ->
                rendered = rendered.replace("{{$key}}", value.toString())
            }
            rendered
        }
    }
}