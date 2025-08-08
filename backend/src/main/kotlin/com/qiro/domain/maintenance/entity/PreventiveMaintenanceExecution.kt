package com.qiro.domain.maintenance.entity

import com.fasterxml.jackson.annotation.JsonIgnore
import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예방 정비 실행 엔티티
 * 실제 예방 정비 작업의 실행 내역을 관리합니다.
 */
@Entity
@Table(
    name = "preventive_maintenance_executions",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "execution_number"])
    ],
    indexes = [
        Index(name = "idx_pm_executions_company_id", columnList = "company_id"),
        Index(name = "idx_pm_executions_plan_id", columnList = "plan_id"),
        Index(name = "idx_pm_executions_asset_id", columnList = "asset_id"),
        Index(name = "idx_pm_executions_date", columnList = "execution_date"),
        Index(name = "idx_pm_executions_status", columnList = "execution_status"),
        Index(name = "idx_pm_executions_type", columnList = "execution_type"),
        Index(name = "idx_pm_executions_technician", columnList = "lead_technician_id"),
        Index(name = "idx_pm_executions_company_status", columnList = "company_id, execution_status"),
        Index(name = "idx_pm_executions_asset_date", columnList = "asset_id, execution_date"),
        Index(name = "idx_pm_executions_number", columnList = "execution_number")
    ]
)
data class PreventiveMaintenanceExecution(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "execution_id", columnDefinition = "uuid")
    val executionId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "plan_id", nullable = false, columnDefinition = "uuid")
    val planId: UUID,

    @Column(name = "asset_id", nullable = false, columnDefinition = "uuid")
    val assetId: UUID,

    @Column(name = "execution_number", nullable = false, length = 50)
    val executionNumber: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "execution_type", nullable = false, length = 30)
    val executionType: ExecutionType = ExecutionType.SCHEDULED,

    @Column(name = "execution_date", nullable = false)
    val executionDate: LocalDate,

    @Column(name = "planned_start_time")
    val plannedStartTime: LocalDateTime? = null,

    @Column(name = "actual_start_time")
    var actualStartTime: LocalDateTime? = null,

    @Column(name = "planned_end_time")
    val plannedEndTime: LocalDateTime? = null,

    @Column(name = "actual_end_time")
    var actualEndTime: LocalDateTime? = null,

    @Column(name = "planned_duration_hours", precision = 8, scale = 2)
    val plannedDurationHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "actual_duration_hours", precision = 8, scale = 2)
    var actualDurationHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "downtime_hours", precision = 8, scale = 2)
    var downtimeHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "maintenance_team", columnDefinition = "jsonb")
    val maintenanceTeam: String? = null,

    @Column(name = "lead_technician_id", columnDefinition = "uuid")
    val leadTechnicianId: UUID? = null,

    @Column(name = "supporting_technicians", columnDefinition = "jsonb")
    val supportingTechnicians: String? = null,

    @Column(name = "contractor_id", columnDefinition = "uuid")
    val contractorId: UUID? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "execution_status", length = 20)
    var executionStatus: ExecutionStatus = ExecutionStatus.PLANNED,

    @Column(name = "completion_percentage", precision = 5, scale = 2)
    var completionPercentage: BigDecimal = BigDecimal.ZERO,

    @Column(name = "equipment_shutdown_required")
    val equipmentShutdownRequired: Boolean = false,

    @Column(name = "shutdown_start_time")
    var shutdownStartTime: LocalDateTime? = null,

    @Column(name = "shutdown_end_time")
    var shutdownEndTime: LocalDateTime? = null,

    @Column(name = "environmental_conditions", columnDefinition = "text")
    var environmentalConditions: String? = null,

    @Column(name = "safety_briefing_completed")
    var safetyBriefingCompleted: Boolean = false,

    @Column(name = "permits_obtained", columnDefinition = "jsonb")
    var permitsObtained: String? = null,

    @Column(name = "lockout_tagout_applied")
    var lockoutTagoutApplied: Boolean = false,

    @Column(name = "safety_incidents", columnDefinition = "jsonb")
    var safetyIncidents: String? = null,

    @Column(name = "materials_used", columnDefinition = "jsonb")
    var materialsUsed: String? = null,

    @Column(name = "tools_used", columnDefinition = "jsonb")
    var toolsUsed: String? = null,

    @Column(name = "spare_parts_consumed", columnDefinition = "jsonb")
    var sparePartsConsumed: String? = null,

    @Column(name = "planned_cost", precision = 12, scale = 2)
    val plannedCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "actual_cost", precision = 12, scale = 2)
    var actualCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "labor_cost", precision = 12, scale = 2)
    var laborCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "material_cost", precision = 12, scale = 2)
    var materialCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "contractor_cost", precision = 12, scale = 2)
    var contractorCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "work_quality_rating", precision = 3, scale = 1)
    var workQualityRating: BigDecimal = BigDecimal.ZERO,

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_condition_before", length = 20)
    var assetConditionBefore: AssetCondition? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "asset_condition_after", length = 20)
    var assetConditionAfter: AssetCondition? = null,

    @Column(name = "performance_improvement", precision = 5, scale = 2)
    var performanceImprovement: BigDecimal = BigDecimal.ZERO,

    @Column(name = "issues_encountered", columnDefinition = "jsonb")
    var issuesEncountered: String? = null,

    @Column(name = "unexpected_findings", columnDefinition = "jsonb")
    var unexpectedFindings: String? = null,

    @Column(name = "additional_work_required")
    var additionalWorkRequired: Boolean = false,

    @Column(name = "follow_up_actions", columnDefinition = "jsonb")
    var followUpActions: String? = null,

    @Column(name = "work_photos", columnDefinition = "jsonb")
    var workPhotos: String? = null,

    @Column(name = "completion_certificates", columnDefinition = "jsonb")
    var completionCertificates: String? = null,

    @Column(name = "test_results", columnDefinition = "jsonb")
    var testResults: String? = null,

    @Column(name = "maintenance_reports", columnDefinition = "jsonb")
    var maintenanceReports: String? = null,

    @Column(name = "work_completed_by", columnDefinition = "uuid")
    var workCompletedBy: UUID? = null,

    @Column(name = "work_completion_date")
    var workCompletionDate: LocalDateTime? = null,

    @Column(name = "reviewed_by", columnDefinition = "uuid")
    var reviewedBy: UUID? = null,

    @Column(name = "review_date")
    var reviewDate: LocalDate? = null,

    @Column(name = "approved_by", columnDefinition = "uuid")
    var approvedBy: UUID? = null,

    @Column(name = "approval_date")
    var approvalDate: LocalDate? = null,

    @Column(name = "technician_notes", columnDefinition = "text")
    var technicianNotes: String? = null,

    @Column(name = "supervisor_comments", columnDefinition = "text")
    var supervisorComments: String? = null,

    @Column(name = "lessons_learned", columnDefinition = "text")
    var lessonsLearned: String? = null,

    @Column(name = "recommendations", columnDefinition = "text")
    var recommendations: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", columnDefinition = "uuid")
    val createdBy: UUID? = null,

    @Column(name = "updated_by", columnDefinition = "uuid")
    var updatedBy: UUID? = null
) {
    @JsonIgnore
    @OneToMany(mappedBy = "executionId", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val taskExecutions: List<MaintenanceTaskExecution> = mutableListOf()

    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

/**
 * 실행 유형
 */
enum class ExecutionType {
    SCHEDULED,               // 예정된
    EMERGENCY,               // 긴급
    CONDITION_BASED,         // 상태 기반
    OPPORTUNITY,             // 기회
    CORRECTIVE               // 교정
}

/**
 * 실행 상태
 */
enum class ExecutionStatus {
    PLANNED,                 // 계획됨
    SCHEDULED,               // 예약됨
    IN_PROGRESS,             // 진행중
    COMPLETED,               // 완료됨
    CANCELLED,               // 취소됨
    DEFERRED,                // 연기됨
    FAILED                   // 실패
}

/**
 * 자산 상태
 */
enum class AssetCondition {
    EXCELLENT,               // 우수
    GOOD,                    // 양호
    FAIR,                    // 보통
    POOR,                    // 불량
    CRITICAL                 // 위험
}