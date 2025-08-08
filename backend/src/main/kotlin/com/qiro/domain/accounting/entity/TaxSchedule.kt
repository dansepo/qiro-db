package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 세무 일정 엔티티
 * 세무 신고 및 납부 일정을 관리합니다.
 */
@Entity
@Table(
    name = "tax_schedules",
    schema = "bms",
    indexes = [
        Index(name = "idx_tax_schedules_company", columnList = "company_id"),
        Index(name = "idx_tax_schedules_due_date", columnList = "due_date"),
        Index(name = "idx_tax_schedules_status", columnList = "status"),
        Index(name = "idx_tax_schedules_assigned", columnList = "assigned_to")
    ]
)
data class TaxSchedule(
    @Id
    @GeneratedValue
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    // 일정 정보
    @Column(name = "schedule_name", nullable = false, length = 200)
    val scheduleName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "tax_type", nullable = false)
    val taxType: TaxType,

    @Enumerated(EnumType.STRING)
    @Column(name = "schedule_type", nullable = false)
    val scheduleType: ScheduleType,

    // 날짜 정보
    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    @Column(name = "reminder_date")
    val reminderDate: LocalDate? = null,

    @Column(name = "completion_date")
    val completionDate: LocalDate? = null,

    // 상태 관리
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    val status: ScheduleStatus = ScheduleStatus.PENDING,

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false)
    val priority: Priority = Priority.MEDIUM,

    // 담당자 정보
    @Column(name = "assigned_to")
    val assignedTo: UUID? = null,

    // 메타데이터
    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "notes", columnDefinition = "TEXT")
    val notes: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by")
    val createdBy: UUID? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 세금 유형
     */
    enum class TaxType {
        VAT,         // 부가세
        WITHHOLDING, // 원천징수
        CORPORATE,   // 법인세
        LOCAL,       // 지방세
        OTHER        // 기타
    }

    /**
     * 일정 유형
     */
    enum class ScheduleType {
        FILING,      // 신고
        PAYMENT,     // 납부
        PREPARATION, // 준비
        REVIEW       // 검토
    }

    /**
     * 일정 상태
     */
    enum class ScheduleStatus {
        PENDING,     // 대기중
        IN_PROGRESS, // 진행중
        COMPLETED,   // 완료
        OVERDUE      // 연체
    }

    /**
     * 우선순위
     */
    enum class Priority {
        LOW,     // 낮음
        MEDIUM,  // 보통
        HIGH,    // 높음
        URGENT   // 긴급
    }

    /**
     * 완료 처리
     */
    fun complete(completionDate: LocalDate = LocalDate.now()): TaxSchedule {
        return this.copy(
            completionDate = completionDate,
            status = ScheduleStatus.COMPLETED,
            updatedAt = LocalDateTime.now()
        )
    }

    /**
     * 연체 여부 확인
     */
    fun isOverdue(): Boolean {
        return dueDate.isBefore(LocalDate.now()) && status != ScheduleStatus.COMPLETED
    }

    /**
     * 알림 필요 여부 확인
     */
    fun needsReminder(): Boolean {
        return reminderDate?.let { 
            it.isEqual(LocalDate.now()) || it.isBefore(LocalDate.now()) 
        } ?: false && status == ScheduleStatus.PENDING
    }

    /**
     * 남은 일수 계산
     */
    fun getDaysRemaining(): Long {
        return java.time.temporal.ChronoUnit.DAYS.between(LocalDate.now(), dueDate)
    }
}