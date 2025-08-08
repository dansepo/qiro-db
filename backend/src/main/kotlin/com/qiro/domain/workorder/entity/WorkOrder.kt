package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.building.entity.Building
import com.qiro.domain.company.entity.Company
import com.qiro.domain.facility.entity.FacilityAsset
import com.qiro.domain.fault.entity.FaultReport
import com.qiro.domain.unit.entity.Unit
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 엔티티
 * 시설물 수리 및 유지보수 작업을 관리하는 핵심 엔티티
 */
@Entity
@Table(
    name = "work_orders",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_work_orders_number",
            columnNames = ["company_id", "work_order_number"]
        )
    ],
    indexes = [
        Index(name = "idx_work_orders_company_id", columnList = "company_id"),
        Index(name = "idx_work_orders_building_id", columnList = "building_id"),
        Index(name = "idx_work_orders_unit_id", columnList = "unit_id"),
        Index(name = "idx_work_orders_asset_id", columnList = "asset_id"),
        Index(name = "idx_work_orders_fault_report", columnList = "fault_report_id"),
        Index(name = "idx_work_orders_status", columnList = "work_status"),
        Index(name = "idx_work_orders_priority", columnList = "work_priority"),
        Index(name = "idx_work_orders_assigned", columnList = "assigned_to"),
        Index(name = "idx_work_orders_company_status", columnList = "company_id, work_status")
    ]
)
class WorkOrder : BaseEntity() {
    
    @Id
    @Column(name = "work_order_id")
    val workOrderId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id")
    var building: Building? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id")
    var unit: Unit? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asset_id")
    var asset: FacilityAsset? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fault_report_id")
    var faultReport: FaultReport? = null
    
    @Column(name = "work_order_number", nullable = false, length = 50)
    lateinit var workOrderNumber: String
    
    @Column(name = "work_order_title", nullable = false, length = 200)
    lateinit var workOrderTitle: String
    
    @Column(name = "work_description", nullable = false, columnDefinition = "TEXT")
    lateinit var workDescription: String
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_category", nullable = false, length = 30)
    lateinit var workCategory: WorkCategory
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_type", nullable = false, length = 30)
    lateinit var workType: WorkType
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_priority", nullable = false, length = 20)
    lateinit var workPriority: WorkPriority
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_urgency", nullable = false, length = 20)
    lateinit var workUrgency: WorkUrgency
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    var template: WorkOrderTemplate? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "requested_by")
    var requestedBy: User? = null
    
    @Column(name = "request_date")
    var requestDate: LocalDateTime = LocalDateTime.now()
    
    @Column(name = "request_reason", columnDefinition = "TEXT")
    var requestReason: String? = null
    
    @Column(name = "work_location", columnDefinition = "TEXT")
    var workLocation: String? = null
    
    @Column(name = "work_scope", columnDefinition = "TEXT")
    var workScope: String? = null
    
    @Column(name = "scheduled_start_date")
    var scheduledStartDate: LocalDateTime? = null
    
    @Column(name = "scheduled_end_date")
    var scheduledEndDate: LocalDateTime? = null
    
    @Column(name = "estimated_duration_hours", precision = 8, scale = 2)
    var estimatedDurationHours: BigDecimal = BigDecimal.ZERO
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    var assignedTo: User? = null
    
    @Column(name = "assigned_team", length = 50)
    var assignedTeam: String? = null
    
    @Column(name = "assignment_date")
    var assignmentDate: LocalDateTime? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_status", length = 20)
    var workStatus: WorkStatus = WorkStatus.PENDING
    
    @Enumerated(EnumType.STRING)
    @Column(name = "approval_status", length = 20)
    var approvalStatus: ApprovalStatus = ApprovalStatus.PENDING
    
    @Column(name = "actual_start_date")
    var actualStartDate: LocalDateTime? = null
    
    @Column(name = "actual_end_date")
    var actualEndDate: LocalDateTime? = null
    
    @Column(name = "actual_duration_hours", precision = 8, scale = 2)
    var actualDurationHours: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "progress_percentage")
    var progressPercentage: Int = 0
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_phase", length = 30)
    var workPhase: WorkPhase = WorkPhase.PLANNING
    
    @Column(name = "estimated_cost", precision = 12, scale = 2)
    var estimatedCost: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "approved_budget", precision = 12, scale = 2)
    var approvedBudget: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "actual_cost", precision = 12, scale = 2)
    var actualCost: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "work_completion_notes", columnDefinition = "TEXT")
    var workCompletionNotes: String? = null
    
    @Column(name = "quality_rating", precision = 3, scale = 1)
    var qualityRating: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "customer_satisfaction", precision = 3, scale = 1)
    var customerSatisfaction: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "follow_up_required")
    var followUpRequired: Boolean = false
    
    @Column(name = "follow_up_date")
    var followUpDate: LocalDateTime? = null
    
    @Column(name = "follow_up_notes", columnDefinition = "TEXT")
    var followUpNotes: String? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    var approvedBy: User? = null
    
    @Column(name = "approval_date")
    var approvalDate: LocalDateTime? = null
    
    @Column(name = "approval_notes", columnDefinition = "TEXT")
    var approvalNotes: String? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "closed_by")
    var closedBy: User? = null
    
    @Column(name = "closed_date")
    var closedDate: LocalDateTime? = null
    
    @Column(name = "closure_reason", length = 50)
    var closureReason: String? = null
    
    @OneToMany(mappedBy = "workOrder", cascade = [CascadeType.ALL], orphanRemoval = true)
    val assignments: MutableList<WorkOrderAssignment> = mutableListOf()
    
    @OneToMany(mappedBy = "workOrder", cascade = [CascadeType.ALL], orphanRemoval = true)
    val materials: MutableList<WorkOrderMaterial> = mutableListOf()
    
    @OneToMany(mappedBy = "workOrder", cascade = [CascadeType.ALL], orphanRemoval = true)
    val progressRecords: MutableList<WorkOrderProgress> = mutableListOf()
    
    /**
     * 작업 지시서 상태 변경
     */
    fun updateStatus(newStatus: WorkStatus, updatedBy: User? = null) {
        this.workStatus = newStatus
        when (newStatus) {
            WorkStatus.IN_PROGRESS -> {
                if (actualStartDate == null) {
                    actualStartDate = LocalDateTime.now()
                }
                workPhase = WorkPhase.EXECUTION
            }
            WorkStatus.COMPLETED -> {
                actualEndDate = LocalDateTime.now()
                progressPercentage = 100
                workPhase = WorkPhase.COMPLETION
            }
            WorkStatus.CANCELLED -> {
                workPhase = WorkPhase.CLOSURE
                closedDate = LocalDateTime.now()
                closedBy = updatedBy
            }
            else -> {}
        }
    }
    
    /**
     * 작업자 배정
     */
    fun assignWorker(worker: User, assignedBy: User? = null) {
        this.assignedTo = worker
        this.assignmentDate = LocalDateTime.now()
        if (workStatus == WorkStatus.PENDING) {
            workStatus = WorkStatus.SCHEDULED
        }
    }
    
    /**
     * 진행률 업데이트
     */
    fun updateProgress(percentage: Int, phase: WorkPhase? = null) {
        require(percentage in 0..100) { "진행률은 0-100 사이여야 합니다." }
        this.progressPercentage = percentage
        phase?.let { this.workPhase = it }
        
        if (percentage == 100 && workStatus != WorkStatus.COMPLETED) {
            updateStatus(WorkStatus.COMPLETED)
        }
    }
    
    /**
     * 작업 완료 처리
     */
    fun complete(completionNotes: String? = null, qualityRating: BigDecimal? = null) {
        updateStatus(WorkStatus.COMPLETED)
        this.workCompletionNotes = completionNotes
        qualityRating?.let { this.qualityRating = it }
    }
    
    /**
     * 작업 승인 처리
     */
    fun approve(approver: User, notes: String? = null) {
        this.approvalStatus = ApprovalStatus.APPROVED
        this.approvedBy = approver
        this.approvalDate = LocalDateTime.now()
        this.approvalNotes = notes
        
        if (workStatus == WorkStatus.PENDING) {
            workStatus = WorkStatus.APPROVED
        }
    }
    
    /**
     * 작업 거부 처리
     */
    fun reject(rejector: User, reason: String) {
        this.approvalStatus = ApprovalStatus.REJECTED
        this.approvedBy = rejector
        this.approvalDate = LocalDateTime.now()
        this.approvalNotes = reason
        this.workStatus = WorkStatus.REJECTED
    }
    
    /**
     * 실제 소요 시간 계산
     */
    fun calculateActualDuration(): BigDecimal {
        return if (actualStartDate != null && actualEndDate != null) {
            val duration = java.time.Duration.between(actualStartDate, actualEndDate)
            BigDecimal.valueOf(duration.toMinutes()).divide(BigDecimal.valueOf(60), 2, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 지연 여부 확인
     */
    fun isDelayed(): Boolean {
        return scheduledEndDate?.let { scheduled ->
            val now = LocalDateTime.now()
            val endDate = actualEndDate ?: now
            endDate.isAfter(scheduled)
        } ?: false
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is WorkOrder) return false
        return workOrderId == other.workOrderId
    }
    
    override fun hashCode(): Int {
        return workOrderId.hashCode()
    }
    
    override fun toString(): String {
        return "WorkOrder(workOrderId=$workOrderId, workOrderNumber='$workOrderNumber', workOrderTitle='$workOrderTitle', workStatus=$workStatus)"
    }
}