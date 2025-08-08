package com.qiro.domain.maintenance.entity

import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 정비 작업 실행 엔티티
 * 개별 정비 작업의 실행 결과를 관리합니다.
 */
@Entity
@Table(
    name = "maintenance_task_executions",
    schema = "bms",
    indexes = [
        Index(name = "idx_task_executions_execution", columnList = "execution_id"),
        Index(name = "idx_task_executions_task", columnList = "task_id"),
        Index(name = "idx_task_executions_status", columnList = "execution_status"),
        Index(name = "idx_task_executions_technician", columnList = "executed_by")
    ]
)
data class MaintenanceTaskExecution(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "task_execution_id", columnDefinition = "uuid")
    val taskExecutionId: UUID = UUID.randomUUID(),

    @Column(name = "execution_id", nullable = false, columnDefinition = "uuid")
    val executionId: UUID,

    @Column(name = "task_id", nullable = false, columnDefinition = "uuid")
    val taskId: UUID,

    @Column(name = "task_sequence", nullable = false)
    val taskSequence: Int,

    @Column(name = "task_name", nullable = false, length = 200)
    val taskName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "execution_status", length = 20)
    var executionStatus: TaskExecutionStatus = TaskExecutionStatus.PENDING,

    @Column(name = "started_at")
    var startedAt: LocalDateTime? = null,

    @Column(name = "completed_at")
    var completedAt: LocalDateTime? = null,

    @Column(name = "actual_duration_minutes")
    var actualDurationMinutes: Int = 0,

    @Column(name = "executed_by", columnDefinition = "uuid")
    var executedBy: UUID? = null,

    @Column(name = "execution_notes", columnDefinition = "text")
    var executionNotes: String? = null,

    @Column(name = "quality_check_passed")
    var qualityCheckPassed: Boolean = false,

    @Column(name = "quality_check_notes", columnDefinition = "text")
    var qualityCheckNotes: String? = null,

    @Column(name = "measurements_taken", columnDefinition = "jsonb")
    var measurementsTaken: String? = null,

    @Column(name = "photos_taken", columnDefinition = "jsonb")
    var photosTaken: String? = null,

    @Column(name = "parts_used", columnDefinition = "jsonb")
    var partsUsed: String? = null,

    @Column(name = "tools_used", columnDefinition = "jsonb")
    var toolsUsed: String? = null,

    @Column(name = "issues_found", columnDefinition = "jsonb")
    var issuesFound: String? = null,

    @Column(name = "corrective_actions", columnDefinition = "jsonb")
    var correctiveActions: String? = null,

    @Column(name = "task_cost", precision = 10, scale = 2)
    var taskCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "labor_hours", precision = 6, scale = 2)
    var laborHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "material_cost", precision = 10, scale = 2)
    var materialCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "completion_percentage", precision = 5, scale = 2)
    var completionPercentage: BigDecimal = BigDecimal.ZERO,

    @Column(name = "requires_follow_up")
    var requiresFollowUp: Boolean = false,

    @Column(name = "follow_up_notes", columnDefinition = "text")
    var followUpNotes: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", columnDefinition = "uuid")
    val createdBy: UUID? = null,

    @Column(name = "updated_by", columnDefinition = "uuid")
    var updatedBy: UUID? = null
) {
    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

/**
 * 작업 실행 상태
 */
enum class TaskExecutionStatus {
    PENDING,                 // 대기중
    IN_PROGRESS,             // 진행중
    COMPLETED,               // 완료됨
    SKIPPED,                 // 건너뜀
    FAILED,                  // 실패
    DEFERRED                 // 연기됨
}