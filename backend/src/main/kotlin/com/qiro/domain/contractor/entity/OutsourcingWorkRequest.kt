package com.qiro.domain.contractor.entity

import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외주 작업 요청 엔티티
 * 외부 업체에 대한 작업 의뢰 정보를 관리
 */
@Entity
@Table(
    name = "outsourcing_work_requests",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_outsourcing_requests_number", columnNames = ["company_id", "request_number"])
    ],
    indexes = [
        Index(name = "idx_outsourcing_requests_company_id", columnList = "company_id"),
        Index(name = "idx_outsourcing_requests_number", columnList = "request_number"),
        Index(name = "idx_outsourcing_requests_requester", columnList = "requester_id"),
        Index(name = "idx_outsourcing_requests_date", columnList = "request_date"),
        Index(name = "idx_outsourcing_requests_status", columnList = "request_status"),
        Index(name = "idx_outsourcing_requests_status_date", columnList = "request_status, request_date"),
        Index(name = "idx_outsourcing_requests_type", columnList = "request_type"),
        Index(name = "idx_outsourcing_requests_priority", columnList = "priority_level")
    ]
)
data class OutsourcingWorkRequest(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "request_id", columnDefinition = "uuid")
    val requestId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "request_number", nullable = false, length = 50)
    val requestNumber: String,

    @Column(name = "request_title", nullable = false, length = 200)
    val requestTitle: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "request_type", nullable = false, length = 30)
    val requestType: RequestType,

    @Column(name = "request_date", nullable = false)
    val requestDate: LocalDateTime = LocalDateTime.now(),

    @Column(name = "requester_id", nullable = false, columnDefinition = "uuid")
    val requesterId: UUID,

    @Column(name = "department", length = 50)
    val department: String? = null,

    @Column(name = "cost_center", length = 20)
    val costCenter: String? = null,

    @Column(name = "work_description", nullable = false, columnDefinition = "text")
    val workDescription: String,

    @Column(name = "work_location", length = 200)
    val workLocation: String? = null,

    @Column(name = "work_scope", columnDefinition = "text")
    val workScope: String? = null,

    @Column(name = "technical_requirements", columnDefinition = "text")
    val technicalRequirements: String? = null,

    @Column(name = "required_start_date")
    val requiredStartDate: LocalDate? = null,

    @Column(name = "required_completion_date")
    val requiredCompletionDate: LocalDate? = null,

    @Column(name = "estimated_duration")
    val estimatedDuration: Int? = null,

    @Column(name = "estimated_budget", precision = 15, scale = 2)
    val estimatedBudget: BigDecimal = BigDecimal.ZERO,

    @Column(name = "budget_code", length = 30)
    val budgetCode: String? = null,

    @Column(name = "currency_code", length = 3)
    val currencyCode: String = "KRW",

    @Enumerated(EnumType.STRING)
    @Column(name = "priority_level", length = 20)
    val priorityLevel: PriorityLevel = PriorityLevel.NORMAL,

    @Enumerated(EnumType.STRING)
    @Column(name = "urgency_level", length = 20)
    val urgencyLevel: UrgencyLevel = UrgencyLevel.NORMAL,

    @Column(name = "required_contractor_category", columnDefinition = "uuid")
    val requiredContractorCategory: UUID? = null,

    @Column(name = "required_licenses", columnDefinition = "jsonb")
    val requiredLicenses: String? = null,

    @Column(name = "required_certifications", columnDefinition = "jsonb")
    val requiredCertifications: String? = null,

    @Column(name = "minimum_experience_years")
    val minimumExperienceYears: Int = 0,

    @Enumerated(EnumType.STRING)
    @Column(name = "approval_status", length = 20)
    val approvalStatus: ApprovalStatus = ApprovalStatus.PENDING,

    @Column(name = "current_approver_id", columnDefinition = "uuid")
    val currentApproverId: UUID? = null,

    @Column(name = "approval_level")
    val approvalLevel: Int = 1,

    @Enumerated(EnumType.STRING)
    @Column(name = "request_status", length = 20)
    val requestStatus: RequestStatus = RequestStatus.DRAFT,

    @Column(name = "request_documents", columnDefinition = "jsonb")
    val requestDocuments: String? = null,

    @Column(name = "request_notes", columnDefinition = "text")
    val requestNotes: String? = null,

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
     * 요청 유형
     */
    enum class RequestType {
        MAINTENANCE,      // 유지보수
        REPAIR,          // 수리
        INSTALLATION,    // 설치
        INSPECTION,      // 점검
        CLEANING,        // 청소
        SECURITY,        // 보안
        CONSTRUCTION,    // 건설
        CONSULTING       // 컨설팅
    }

    /**
     * 우선순위 레벨
     */
    enum class PriorityLevel {
        LOW,             // 낮음
        NORMAL,          // 보통
        HIGH,            // 높음
        URGENT,          // 긴급
        EMERGENCY        // 응급
    }

    /**
     * 긴급도 레벨
     */
    enum class UrgencyLevel {
        LOW,             // 낮음
        NORMAL,          // 보통
        HIGH,            // 높음
        CRITICAL         // 심각
    }

    /**
     * 승인 상태
     */
    enum class ApprovalStatus {
        PENDING,         // 대기중
        IN_REVIEW,       // 검토중
        APPROVED,        // 승인됨
        REJECTED,        // 거부됨
        CANCELLED        // 취소됨
    }

    /**
     * 요청 상태
     */
    enum class RequestStatus {
        DRAFT,           // 초안
        SUBMITTED,       // 제출됨
        IN_APPROVAL,     // 승인중
        APPROVED,        // 승인됨
        REJECTED,        // 거부됨
        CANCELLED,       // 취소됨
        ASSIGNED         // 할당됨
    }
}