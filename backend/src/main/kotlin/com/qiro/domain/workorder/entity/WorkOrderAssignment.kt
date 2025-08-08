package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 배정 엔티티
 * 작업자별 작업 배정 및 성과 관리
 */
@Entity
@Table(
    name = "work_order_assignments",
    schema = "bms",
    indexes = [
        Index(name = "idx_work_assignments_company_id", columnList = "company_id"),
        Index(name = "idx_work_assignments_work_order", columnList = "work_order_id"),
        Index(name = "idx_work_assignments_assigned_to", columnList = "assigned_to"),
        Index(name = "idx_work_assignments_role", columnList = "assignment_role"),
        Index(name = "idx_work_assignments_status", columnList = "assignment_status"),
        Index(name = "idx_work_assignments_assigned_status", columnList = "assigned_to, assignment_status")
    ]
)
class WorkOrderAssignment : BaseEntity() {
    
    @Id
    @Column(name = "assignment_id")
    val assignmentId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "work_order_id", nullable = false)
    lateinit var workOrder: WorkOrder
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to", nullable = false)
    lateinit var assignedTo: User
    
    @Enumerated(EnumType.STRING)
    @Column(name = "assignment_role", nullable = false, length = 30)
    lateinit var assignmentRole: AssignmentRole
    
    @Enumerated(EnumType.STRING)
    @Column(name = "assignment_type", nullable = false, length = 20)
    lateinit var assignmentType: AssignmentType
    
    @Column(name = "assigned_date")
    var assignedDate: LocalDateTime = LocalDateTime.now()
    
    @Column(name = "expected_start_date")
    var expectedStartDate: LocalDateTime? = null
    
    @Column(name = "expected_end_date")
    var expectedEndDate: LocalDateTime? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "assignment_status", length = 20)
    var assignmentStatus: AssignmentStatus = AssignmentStatus.ASSIGNED
    
    @Enumerated(EnumType.STRING)
    @Column(name = "acceptance_status", length = 20)
    var acceptanceStatus: AcceptanceStatus = AcceptanceStatus.PENDING
    
    @Column(name = "allocated_hours", precision = 8, scale = 2)
    var allocatedHours: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "actual_hours", precision = 8, scale = 2)
    var actualHours: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "work_percentage")
    var workPercentage: Int = 0
    
    @Column(name = "assignment_notes", columnDefinition = "TEXT")
    var assignmentNotes: String? = null
    
    @Column(name = "acceptance_notes", columnDefinition = "TEXT")
    var acceptanceNotes: String? = null
    
    @Column(name = "completion_notes", columnDefinition = "TEXT")
    var completionNotes: String? = null
    
    @Column(name = "performance_rating", precision = 3, scale = 1)
    var performanceRating: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "quality_score", precision = 3, scale = 1)
    var qualityScore: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "timeliness_score", precision = 3, scale = 1)
    var timelinessScore: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "completed_date")
    var completedDate: LocalDateTime? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "completed_by")
    var completedBy: User? = null
    
    /**
     * 배정 수락
     */
    fun accept(notes: String? = null) {
        this.acceptanceStatus = AcceptanceStatus.ACCEPTED
        this.assignmentStatus = AssignmentStatus.ACCEPTED
        this.acceptanceNotes = notes
    }
    
    /**
     * 배정 거부
     */
    fun decline(reason: String) {
        this.acceptanceStatus = AcceptanceStatus.DECLINED
        this.assignmentStatus = AssignmentStatus.CANCELLED
        this.acceptanceNotes = reason
    }
    
    /**
     * 작업 시작
     */
    fun startWork() {
        require(acceptanceStatus == AcceptanceStatus.ACCEPTED) { "수락된 배정만 시작할 수 있습니다." }
        this.assignmentStatus = AssignmentStatus.IN_PROGRESS
    }
    
    /**
     * 작업 완료
     */
    fun complete(completionNotes: String? = null, completedBy: User? = null) {
        this.assignmentStatus = AssignmentStatus.COMPLETED
        this.completedDate = LocalDateTime.now()
        this.completionNotes = completionNotes
        this.completedBy = completedBy
        this.workPercentage = 100
    }
    
    /**
     * 성과 평가
     */
    fun evaluate(
        performanceRating: BigDecimal,
        qualityScore: BigDecimal,
        timelinessScore: BigDecimal
    ) {
        require(performanceRating in BigDecimal.ZERO..BigDecimal.TEN) { "성과 평가는 0-10 사이여야 합니다." }
        require(qualityScore in BigDecimal.ZERO..BigDecimal.TEN) { "품질 점수는 0-10 사이여야 합니다." }
        require(timelinessScore in BigDecimal.ZERO..BigDecimal.TEN) { "시간 준수 점수는 0-10 사이여야 합니다." }
        
        this.performanceRating = performanceRating
        this.qualityScore = qualityScore
        this.timelinessScore = timelinessScore
    }
    
    /**
     * 실제 작업 시간 기록
     */
    fun recordActualHours(hours: BigDecimal) {
        require(hours >= BigDecimal.ZERO) { "작업 시간은 0 이상이어야 합니다." }
        this.actualHours = hours
    }
    
    /**
     * 작업 진행률 업데이트
     */
    fun updateProgress(percentage: Int) {
        require(percentage in 0..100) { "진행률은 0-100 사이여야 합니다." }
        this.workPercentage = percentage
        
        if (percentage == 100 && assignmentStatus == AssignmentStatus.IN_PROGRESS) {
            assignmentStatus = AssignmentStatus.COMPLETED
            completedDate = LocalDateTime.now()
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is WorkOrderAssignment) return false
        return assignmentId == other.assignmentId
    }
    
    override fun hashCode(): Int {
        return assignmentId.hashCode()
    }
    
    override fun toString(): String {
        return "WorkOrderAssignment(assignmentId=$assignmentId, assignmentRole=$assignmentRole, assignmentStatus=$assignmentStatus)"
    }
}

/**
 * 배정 역할
 */
enum class AssignmentRole(
    val displayName: String,
    val description: String
) {
    PRIMARY_TECHNICIAN("주담당자", "작업의 주 담당 기술자"),
    ASSISTANT_TECHNICIAN("보조담당자", "작업 보조 기술자"),
    SUPERVISOR("감독자", "작업 감독 및 관리자"),
    SPECIALIST("전문가", "특수 기술 전문가"),
    CONTRACTOR("외주업체", "외부 계약업체"),
    INSPECTOR("검사자", "작업 검사 및 승인자"),
    COORDINATOR("조정자", "작업 조정 및 관리자");
    
    companion object {
        fun fromDisplayName(displayName: String): AssignmentRole? {
            return values().find { it.displayName == displayName }
        }
    }
}

/**
 * 배정 유형
 */
enum class AssignmentType(
    val displayName: String,
    val description: String
) {
    INTERNAL("내부", "사내 직원"),
    EXTERNAL("외부", "외부 인력"),
    CONTRACTOR("계약업체", "계약 업체"),
    CONSULTANT("컨설턴트", "외부 컨설턴트");
    
    companion object {
        fun fromDisplayName(displayName: String): AssignmentType? {
            return values().find { it.displayName == displayName }
        }
    }
}

/**
 * 배정 상태
 */
enum class AssignmentStatus(
    val displayName: String,
    val description: String
) {
    ASSIGNED("배정됨", "작업이 배정됨"),
    ACCEPTED("수락됨", "배정을 수락함"),
    IN_PROGRESS("진행중", "작업 진행 중"),
    COMPLETED("완료됨", "작업 완료됨"),
    CANCELLED("취소됨", "배정이 취소됨"),
    REASSIGNED("재배정됨", "다른 담당자로 재배정됨");
    
    companion object {
        fun fromDisplayName(displayName: String): AssignmentStatus? {
            return values().find { it.displayName == displayName }
        }
    }
}

/**
 * 수락 상태
 */
enum class AcceptanceStatus(
    val displayName: String,
    val description: String
) {
    PENDING("대기중", "수락 대기 중"),
    ACCEPTED("수락됨", "배정을 수락함"),
    DECLINED("거부됨", "배정을 거부함"),
    REQUIRES_CLARIFICATION("명확화필요", "추가 정보 필요");
    
    companion object {
        fun fromDisplayName(displayName: String): AcceptanceStatus? {
            return values().find { it.displayName == displayName }
        }
    }
}