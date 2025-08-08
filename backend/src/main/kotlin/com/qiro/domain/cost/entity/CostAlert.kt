package com.qiro.domain.cost.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 경고 엔티티
 * 예산 초과 및 비용 관련 경고 관리
 */
@Entity
@Table(
    name = "cost_alerts",
    schema = "bms",
    indexes = [
        Index(name = "idx_cost_alerts_company_id", columnList = "company_id"),
        Index(name = "idx_cost_alerts_budget", columnList = "budget_id"),
        Index(name = "idx_cost_alerts_type", columnList = "alert_type"),
        Index(name = "idx_cost_alerts_severity", columnList = "alert_severity"),
        Index(name = "idx_cost_alerts_status", columnList = "alert_status"),
        Index(name = "idx_cost_alerts_created", columnList = "created_at")
    ]
)
class CostAlert : BaseEntity() {
    
    @Id
    @Column(name = "alert_id")
    val alertId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "budget_id")
    var budget: CostBudget? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "alert_type", nullable = false, length = 30)
    lateinit var alertType: AlertType
    
    @Enumerated(EnumType.STRING)
    @Column(name = "alert_severity", nullable = false, length = 20)
    lateinit var alertSeverity: AlertSeverity
    
    @Column(name = "alert_title", nullable = false, length = 200)
    lateinit var alertTitle: String
    
    @Column(name = "alert_message", nullable = false, columnDefinition = "TEXT")
    lateinit var alertMessage: String
    
    @Column(name = "threshold_value", precision = 15, scale = 2)
    var thresholdValue: BigDecimal? = null
    
    @Column(name = "current_value", precision = 15, scale = 2)
    var currentValue: BigDecimal? = null
    
    @Column(name = "variance_amount", precision = 15, scale = 2)
    var varianceAmount: BigDecimal? = null
    
    @Column(name = "variance_percentage", precision = 5, scale = 2)
    var variancePercentage: BigDecimal? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "alert_status", nullable = false, length = 20)
    var alertStatus: AlertStatus = AlertStatus.ACTIVE
    
    @Column(name = "triggered_at", nullable = false)
    var triggeredAt: LocalDateTime = LocalDateTime.now()
    
    @Column(name = "resolved_at")
    var resolvedAt: LocalDateTime? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by")
    var resolvedBy: User? = null
    
    @Column(name = "resolution_notes", columnDefinition = "TEXT")
    var resolutionNotes: String? = null
    
    @Column(name = "auto_resolved")
    var autoResolved: Boolean = false
    
    @Column(name = "notification_sent")
    var notificationSent: Boolean = false
    
    @Column(name = "notification_sent_at")
    var notificationSentAt: LocalDateTime? = null
    
    @Column(name = "escalation_level")
    var escalationLevel: Int = 0
    
    @Column(name = "escalated_at")
    var escalatedAt: LocalDateTime? = null
    
    @Column(name = "suppressed_until")
    var suppressedUntil: LocalDateTime? = null
    
    @Column(name = "recurrence_count")
    var recurrenceCount: Int = 1
    
    @Column(name = "last_occurrence")
    var lastOccurrence: LocalDateTime = LocalDateTime.now()
    
    @Column(name = "metadata", columnDefinition = "jsonb")
    var metadata: String? = null
    
    /**
     * 경고 유형 열거형
     */
    enum class AlertType {
        BUDGET_THRESHOLD,       // 예산 임계값 초과
        BUDGET_EXCEEDED,        // 예산 초과
        COST_SPIKE,            // 비용 급증
        PAYMENT_OVERDUE,       // 지불 연체
        RECURRING_COST_DUE,    // 반복 비용 만료
        APPROVAL_REQUIRED,     // 승인 필요
        VARIANCE_HIGH,         // 높은 차이
        UTILIZATION_LOW,       // 낮은 활용률
        CONTRACTOR_COST_HIGH,  // 높은 외주비
        EMERGENCY_COST,        // 응급 비용
        MAINTENANCE_OVERDUE,   // 정비 연체
        OTHER                  // 기타
    }
    
    /**
     * 경고 심각도 열거형
     */
    enum class AlertSeverity {
        LOW,        // 낮음
        MEDIUM,     // 보통
        HIGH,       // 높음
        CRITICAL    // 위험
    }
    
    /**
     * 경고 상태 열거형
     */
    enum class AlertStatus {
        ACTIVE,         // 활성
        ACKNOWLEDGED,   // 확인됨
        RESOLVED,       // 해결됨
        SUPPRESSED,     // 억제됨
        EXPIRED         // 만료됨
    }
    
    /**
     * 경고 확인 처리
     */
    fun acknowledge(user: User? = null) {
        this.alertStatus = AlertStatus.ACKNOWLEDGED
        // 확인자 정보는 별도 테이블로 관리하거나 메타데이터에 저장
    }
    
    /**
     * 경고 해결 처리
     */
    fun resolve(resolver: User, notes: String? = null) {
        this.alertStatus = AlertStatus.RESOLVED
        this.resolvedBy = resolver
        this.resolvedAt = LocalDateTime.now()
        this.resolutionNotes = notes
    }
    
    /**
     * 경고 자동 해결 처리
     */
    fun autoResolve(reason: String) {
        this.alertStatus = AlertStatus.RESOLVED
        this.resolvedAt = LocalDateTime.now()
        this.autoResolved = true
        this.resolutionNotes = "자동 해결: $reason"
    }
    
    /**
     * 경고 억제 처리
     */
    fun suppress(duration: Long) {
        this.alertStatus = AlertStatus.SUPPRESSED
        this.suppressedUntil = LocalDateTime.now().plusMinutes(duration)
    }
    
    /**
     * 경고 에스컬레이션
     */
    fun escalate() {
        this.escalationLevel++
        this.escalatedAt = LocalDateTime.now()
        
        // 심각도 상승
        when (alertSeverity) {
            AlertSeverity.LOW -> alertSeverity = AlertSeverity.MEDIUM
            AlertSeverity.MEDIUM -> alertSeverity = AlertSeverity.HIGH
            AlertSeverity.HIGH -> alertSeverity = AlertSeverity.CRITICAL
            AlertSeverity.CRITICAL -> {} // 이미 최고 수준
        }
    }
    
    /**
     * 재발생 처리
     */
    fun recordRecurrence() {
        this.recurrenceCount++
        this.lastOccurrence = LocalDateTime.now()
        
        // 재발생 시 상태를 다시 활성으로 변경
        if (alertStatus == AlertStatus.RESOLVED) {
            this.alertStatus = AlertStatus.ACTIVE
            this.resolvedAt = null
            this.resolvedBy = null
            this.resolutionNotes = null
        }
    }
    
    /**
     * 알림 발송 완료 처리
     */
    fun markNotificationSent() {
        this.notificationSent = true
        this.notificationSentAt = LocalDateTime.now()
    }
    
    /**
     * 억제 상태 확인
     */
    fun isSuppressed(): Boolean {
        return alertStatus == AlertStatus.SUPPRESSED && 
               suppressedUntil?.isAfter(LocalDateTime.now()) == true
    }
    
    /**
     * 활성 상태 확인
     */
    fun isActive(): Boolean {
        return alertStatus == AlertStatus.ACTIVE && !isSuppressed()
    }
    
    /**
     * 에스컬레이션 필요 여부 확인
     */
    fun needsEscalation(thresholdMinutes: Long = 60): Boolean {
        return isActive() && 
               triggeredAt.isBefore(LocalDateTime.now().minusMinutes(thresholdMinutes)) &&
               escalationLevel < 3 // 최대 3단계까지 에스컬레이션
    }
    
    /**
     * 만료 처리
     */
    fun expire() {
        this.alertStatus = AlertStatus.EXPIRED
    }
    
    /**
     * 경고 메시지 생성
     */
    fun generateAlertMessage(): String {
        return when (alertType) {
            AlertType.BUDGET_THRESHOLD -> {
                "예산 '${budget?.budgetName}' 사용률이 ${currentValue}%에 도달했습니다. (임계값: ${thresholdValue}%)"
            }
            AlertType.BUDGET_EXCEEDED -> {
                "예산 '${budget?.budgetName}'이 ${varianceAmount}원 초과되었습니다. (초과율: ${variancePercentage}%)"
            }
            AlertType.COST_SPIKE -> {
                "비용이 급증했습니다. 현재 값: ${currentValue}원 (이전 대비 ${variancePercentage}% 증가)"
            }
            AlertType.PAYMENT_OVERDUE -> {
                "지불 연체가 발생했습니다. 연체 금액: ${currentValue}원"
            }
            else -> alertMessage
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is CostAlert) return false
        return alertId == other.alertId
    }
    
    override fun hashCode(): Int {
        return alertId.hashCode()
    }
    
    override fun toString(): String {
        return "CostAlert(alertId=$alertId, alertType=$alertType, alertSeverity=$alertSeverity, alertStatus=$alertStatus)"
    }
}