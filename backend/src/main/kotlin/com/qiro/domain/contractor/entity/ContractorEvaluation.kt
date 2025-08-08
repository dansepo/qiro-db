package com.qiro.domain.contractor.entity

import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 평가 엔티티
 * 협력업체의 성과 평가 정보를 관리
 */
@Entity
@Table(
    name = "contractor_evaluations",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_contractor_evaluations_number", columnNames = ["company_id", "evaluation_number"])
    ],
    indexes = [
        Index(name = "idx_contractor_evaluations_company_id", columnList = "company_id"),
        Index(name = "idx_contractor_evaluations_contractor_id", columnList = "contractor_id"),
        Index(name = "idx_contractor_evaluations_contractor_date", columnList = "contractor_id, evaluation_date"),
        Index(name = "idx_contractor_evaluations_date", columnList = "evaluation_date"),
        Index(name = "idx_contractor_evaluations_grade", columnList = "evaluation_grade"),
        Index(name = "idx_contractor_evaluations_status", columnList = "evaluation_status"),
        Index(name = "idx_contractor_evaluations_type", columnList = "evaluation_type")
    ]
)
data class ContractorEvaluation(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "evaluation_id", columnDefinition = "uuid")
    val evaluationId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "contractor_id", nullable = false, columnDefinition = "uuid")
    val contractorId: UUID,

    @Column(name = "evaluation_number", nullable = false, length = 50)
    val evaluationNumber: String,

    @Column(name = "evaluation_title", nullable = false, length = 200)
    val evaluationTitle: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "evaluation_type", nullable = false, length = 30)
    val evaluationType: EvaluationType,

    @Column(name = "evaluation_period_start", nullable = false)
    val evaluationPeriodStart: LocalDate,

    @Column(name = "evaluation_period_end", nullable = false)
    val evaluationPeriodEnd: LocalDate,

    @Column(name = "evaluator_id", nullable = false, columnDefinition = "uuid")
    val evaluatorId: UUID,

    @Column(name = "evaluation_date", nullable = false)
    val evaluationDate: LocalDateTime = LocalDateTime.now(),

    // 평가 점수들 (0-100점)
    @Column(name = "quality_score", precision = 5, scale = 2)
    val qualityScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "schedule_score", precision = 5, scale = 2)
    val scheduleScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "cost_score", precision = 5, scale = 2)
    val costScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "safety_score", precision = 5, scale = 2)
    val safetyScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "communication_score", precision = 5, scale = 2)
    val communicationScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "technical_score", precision = 5, scale = 2)
    val technicalScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "total_score", precision = 5, scale = 2)
    val totalScore: BigDecimal = BigDecimal.ZERO,

    @Column(name = "weighted_score", precision = 5, scale = 2)
    val weightedScore: BigDecimal = BigDecimal.ZERO,

    @Enumerated(EnumType.STRING)
    @Column(name = "evaluation_grade", length = 10)
    val evaluationGrade: EvaluationGrade? = null,

    @Column(name = "strengths", columnDefinition = "text")
    val strengths: String? = null,

    @Column(name = "weaknesses", columnDefinition = "text")
    val weaknesses: String? = null,

    @Column(name = "improvement_recommendations", columnDefinition = "text")
    val improvementRecommendations: String? = null,

    @Column(name = "reference_projects", columnDefinition = "jsonb")
    val referenceProjects: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "evaluation_status", length = 20)
    val evaluationStatus: EvaluationStatus = EvaluationStatus.DRAFT,

    @Column(name = "approved_by", columnDefinition = "uuid")
    val approvedBy: UUID? = null,

    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,

    @Column(name = "approval_notes", columnDefinition = "text")
    val approvalNotes: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", columnDefinition = "uuid")
    val createdBy: UUID? = null,

    @Column(name = "updated_by", columnDefinition = "uuid")
    val updatedBy: UUID? = null
) {
    /**
     * 평가 유형
     */
    enum class EvaluationType {
        INITIAL,          // 초기평가
        ANNUAL,           // 연간평가
        PROJECT_BASED,    // 프로젝트별 평가
        INCIDENT_BASED,   // 사고기반 평가
        RENEWAL          // 갱신평가
    }

    /**
     * 평가 등급
     */
    enum class EvaluationGrade {
        A_PLUS,          // A+
        A,               // A
        B_PLUS,          // B+
        B,               // B
        C_PLUS,          // C+
        C,               // C
        D,               // D
        F                // F
    }

    /**
     * 평가 상태
     */
    enum class EvaluationStatus {
        DRAFT,           // 초안
        SUBMITTED,       // 제출됨
        APPROVED,        // 승인됨
        REJECTED         // 거부됨
    }
}