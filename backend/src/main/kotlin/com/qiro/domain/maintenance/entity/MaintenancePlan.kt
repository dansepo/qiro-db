package com.qiro.domain.maintenance.entity

import com.fasterxml.jackson.annotation.JsonIgnore
import com.qiro.domain.facility.entity.FacilityAsset
import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 정기 점검 일정 관리 엔티티
 * 시설물별 예방 정비 계획을 관리합니다.
 */
@Entity
@Table(
    name = "maintenance_plans",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "plan_code"])
    ]
)
data class MaintenancePlan(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "plan_id", columnDefinition = "uuid")
    val planId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "asset_id", nullable = false, columnDefinition = "uuid")
    val assetId: UUID,

    @Column(name = "plan_name", nullable = false, length = 200)
    val planName: String,

    @Column(name = "plan_code", nullable = false, length = 50)
    val planCode: String,

    @Column(name = "plan_description", columnDefinition = "text")
    val planDescription: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "plan_type", nullable = false, length = 30)
    val planType: MaintenancePlanType,

    @Enumerated(EnumType.STRING)
    @Column(name = "maintenance_strategy", nullable = false, length = 30)
    val maintenanceStrategy: MaintenanceStrategy,

    @Enumerated(EnumType.STRING)
    @Column(name = "maintenance_approach", nullable = false, length = 30)
    val maintenanceApproach: MaintenanceApproach,

    @Column(name = "criticality_analysis", columnDefinition = "jsonb")
    val criticalityAnalysis: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "frequency_type", nullable = false, length = 20)
    val frequencyType: FrequencyType,

    @Column(name = "frequency_interval")
    val frequencyInterval: Int = 1,

    @Column(name = "frequency_unit", length = 20)
    val frequencyUnit: String? = null,

    @Column(name = "estimated_duration_hours", precision = 8, scale = 2)
    val estimatedDurationHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "estimated_cost", precision = 12, scale = 2)
    val estimatedCost: BigDecimal = BigDecimal.ZERO,

    @Column(name = "required_downtime_hours", precision = 8, scale = 2)
    val requiredDowntimeHours: BigDecimal = BigDecimal.ZERO,

    @Column(name = "required_personnel", columnDefinition = "jsonb")
    val requiredPersonnel: String? = null,

    @Column(name = "required_skills", columnDefinition = "jsonb")
    val requiredSkills: String? = null,

    @Column(name = "required_tools", columnDefinition = "jsonb")
    val requiredTools: String? = null,

    @Column(name = "required_parts", columnDefinition = "jsonb")
    val requiredParts: String? = null,

    @Column(name = "safety_requirements", columnDefinition = "text")
    val safetyRequirements: String? = null,

    @Column(name = "permit_requirements", columnDefinition = "jsonb")
    val permitRequirements: String? = null,

    @Column(name = "regulatory_compliance", columnDefinition = "jsonb")
    val regulatoryCompliance: String? = null,

    @Column(name = "target_availability", precision = 5, scale = 2)
    val targetAvailability: BigDecimal = BigDecimal("95.00"),

    @Column(name = "target_reliability", precision = 5, scale = 2)
    val targetReliability: BigDecimal = BigDecimal("95.00"),

    @Column(name = "target_cost_per_year", precision = 12, scale = 2)
    val targetCostPerYear: BigDecimal = BigDecimal.ZERO,

    @Enumerated(EnumType.STRING)
    @Column(name = "plan_status", length = 20)
    val planStatus: PlanStatus = PlanStatus.ACTIVE,

    @Enumerated(EnumType.STRING)
    @Column(name = "approval_status", length = 20)
    val approvalStatus: ApprovalStatus = ApprovalStatus.PENDING,

    @Column(name = "effective_date")
    val effectiveDate: LocalDate = LocalDate.now(),

    @Column(name = "review_date")
    val reviewDate: LocalDate? = null,

    @Column(name = "actual_cost_ytd", precision = 12, scale = 2)
    val actualCostYtd: BigDecimal = BigDecimal.ZERO,

    @Column(name = "actual_hours_ytd", precision = 8, scale = 2)
    val actualHoursYtd: BigDecimal = BigDecimal.ZERO,

    @Column(name = "completion_rate", precision = 5, scale = 2)
    val completionRate: BigDecimal = BigDecimal.ZERO,

    @Column(name = "effectiveness_score", precision = 5, scale = 2)
    val effectivenessScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", columnDefinition = "uuid")
    val createdBy: UUID? = null,

    @Column(name = "updated_by", columnDefinition = "uuid")
    var updatedBy: UUID? = null,

    @Column(name = "approved_by", columnDefinition = "uuid")
    val approvedBy: UUID? = null,

    @Column(name = "approved_at")
    val approvedAt: LocalDateTime? = null
) {
    @JsonIgnore
    @OneToMany(mappedBy = "planId", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val maintenanceTasks: List<MaintenanceTask> = mutableListOf()

    @JsonIgnore
    @OneToMany(mappedBy = "planId", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val preventiveMaintenanceExecutions: List<PreventiveMaintenanceExecution> = mutableListOf()

    @PreUpdate
    fun preUpdate() {
        updatedAt = LocalDateTime.now()
    }
}

/**
 * 정비 계획 유형
 */
enum class MaintenancePlanType {
    PREVENTIVE_MAINTENANCE,     // 예방 정비
    PREDICTIVE_MAINTENANCE,     // 예측 정비
    CONDITION_BASED,           // 상태 기반
    TIME_BASED,               // 시간 기반
    USAGE_BASED,              // 사용량 기반
    RELIABILITY_CENTERED,     // 신뢰성 중심
    TOTAL_PRODUCTIVE          // 전체 생산성
}

/**
 * 정비 전략
 */
enum class MaintenanceStrategy {
    REACTIVE,                 // 반응적
    PREVENTIVE,              // 예방적
    PREDICTIVE,              // 예측적
    PROACTIVE,               // 사전적
    RELIABILITY_CENTERED     // 신뢰성 중심
}

/**
 * 정비 접근법
 */
enum class MaintenanceApproach {
    IN_HOUSE,                // 내부
    OUTSOURCED,              // 외주
    HYBRID,                  // 혼합
    VENDOR_MANAGED           // 업체 관리
}

/**
 * 빈도 유형
 */
enum class FrequencyType {
    DAILY,                   // 일별
    WEEKLY,                  // 주별
    MONTHLY,                 // 월별
    QUARTERLY,               // 분기별
    SEMI_ANNUALLY,           // 반기별
    ANNUALLY,                // 연별
    CUSTOM                   // 사용자 정의
}

/**
 * 계획 상태
 */
enum class PlanStatus {
    ACTIVE,                  // 활성
    INACTIVE,                // 비활성
    DRAFT,                   // 초안
    UNDER_REVIEW,            // 검토중
    ARCHIVED                 // 보관됨
}

/**
 * 승인 상태
 */
enum class ApprovalStatus {
    PENDING,                 // 대기중
    APPROVED,                // 승인됨
    REJECTED,                // 거부됨
    UNDER_REVIEW             // 검토중
}