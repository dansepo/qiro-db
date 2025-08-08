package com.qiro.domain.maintenance.entity

import com.fasterxml.jackson.annotation.JsonIgnore
import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.time.LocalDateTime
import java.util.*

/**
 * 정비 작업 엔티티
 * 정비 계획에 포함된 개별 작업들을 관리합니다.
 */
@Entity
@Table(
    name = "maintenance_tasks",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["plan_id", "task_sequence"])
    ]
)
data class MaintenanceTask(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "task_id", columnDefinition = "uuid")
    val taskId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "plan_id", nullable = false, columnDefinition = "uuid")
    val planId: UUID,

    @Column(name = "task_sequence", nullable = false)
    val taskSequence: Int,

    @Column(name = "task_name", nullable = false, length = 200)
    val taskName: String,

    @Column(name = "task_description", columnDefinition = "text")
    val taskDescription: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "task_type", nullable = false, length = 30)
    val taskType: TaskType,

    @Column(name = "task_instructions", columnDefinition = "text")
    val taskInstructions: String? = null,

    @Column(name = "safety_precautions", columnDefinition = "text")
    val safetyPrecautions: String? = null,

    @Column(name = "quality_standards", columnDefinition = "text")
    val qualityStandards: String? = null,

    @Column(name = "estimated_duration_minutes")
    val estimatedDurationMinutes: Int = 0,

    @Enumerated(EnumType.STRING)
    @Column(name = "required_skill_level", length = 20)
    val requiredSkillLevel: SkillLevel = SkillLevel.BASIC,

    @Column(name = "required_tools", columnDefinition = "jsonb")
    val requiredTools: String? = null,

    @Column(name = "required_parts", columnDefinition = "jsonb")
    val requiredParts: String? = null,

    @Column(name = "prerequisite_tasks", columnDefinition = "jsonb")
    val prerequisiteTasks: String? = null,

    @Column(name = "environmental_conditions", columnDefinition = "text")
    val environmentalConditions: String? = null,

    @Column(name = "equipment_state_required", length = 30)
    val equipmentStateRequired: String? = null,

    @Column(name = "inspection_required")
    val inspectionRequired: Boolean = false,

    @Column(name = "measurement_required")
    val measurementRequired: Boolean = false,

    @Column(name = "documentation_required")
    val documentationRequired: Boolean = true,

    @Column(name = "photo_required")
    val photoRequired: Boolean = false,

    @Column(name = "acceptance_criteria", columnDefinition = "text")
    val acceptanceCriteria: String? = null,

    @Column(name = "measurement_points", columnDefinition = "jsonb")
    val measurementPoints: String? = null,

    @Column(name = "tolerance_specifications", columnDefinition = "jsonb")
    val toleranceSpecifications: String? = null,

    @Column(name = "is_critical")
    val isCritical: Boolean = false,

    @Column(name = "is_active")
    val isActive: Boolean = true,

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
    @OneToMany(mappedBy = "taskId", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val taskExecutions: List<MaintenanceTaskExecution> = mutableListOf()

    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

/**
 * 작업 유형
 */
enum class TaskType {
    INSPECTION,              // 점검
    CLEANING,                // 청소
    LUBRICATION,             // 윤활
    ADJUSTMENT,              // 조정
    CALIBRATION,             // 교정
    REPLACEMENT,             // 교체
    REPAIR,                  // 수리
    TESTING,                 // 테스트
    MEASUREMENT,             // 측정
    DOCUMENTATION            // 문서화
}

/**
 * 기술 수준
 */
enum class SkillLevel {
    BASIC,                   // 기본
    INTERMEDIATE,            // 중급
    ADVANCED,                // 고급
    EXPERT,                  // 전문가
    CERTIFIED                // 인증
}