package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 진행 상황 엔티티
 * 작업 진행 상황 추적 및 기록 관리
 */
@Entity
@Table(
    name = "work_order_progress",
    schema = "bms",
    indexes = [
        Index(name = "idx_work_progress_company_id", columnList = "company_id"),
        Index(name = "idx_work_progress_work_order", columnList = "work_order_id"),
        Index(name = "idx_work_progress_date", columnList = "progress_date"),
        Index(name = "idx_work_progress_phase", columnList = "work_phase"),
        Index(name = "idx_work_progress_reported_by", columnList = "reported_by")
    ]
)
class WorkOrderProgress : BaseEntity() {
    
    @Id
    @Column(name = "progress_id")
    val progressId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "work_order_id", nullable = false)
    lateinit var workOrder: WorkOrder
    
    @Column(name = "progress_date")
    var progressDate: LocalDateTime = LocalDateTime.now()
    
    @Column(name = "progress_percentage", nullable = false)
    var progressPercentage: Int = 0
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_phase", nullable = false, length = 30)
    lateinit var workPhase: WorkPhase
    
    @Column(name = "work_completed", columnDefinition = "TEXT")
    var workCompleted: String? = null
    
    @Column(name = "work_remaining", columnDefinition = "TEXT")
    var workRemaining: String? = null
    
    @Column(name = "issues_encountered", columnDefinition = "TEXT")
    var issuesEncountered: String? = null
    
    @Column(name = "hours_worked", precision = 8, scale = 2)
    var hoursWorked: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "cumulative_hours", precision = 8, scale = 2)
    var cumulativeHours: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "quality_checkpoints_completed")
    var qualityCheckpointsCompleted: Int = 0
    
    @Column(name = "quality_issues_found")
    var qualityIssuesFound: Int = 0
    
    @Column(name = "quality_issues_resolved")
    var qualityIssuesResolved: Int = 0
    
    @Column(name = "materials_used", columnDefinition = "JSONB")
    var materialsUsed: String? = null
    
    @Column(name = "tools_used", columnDefinition = "JSONB")
    var toolsUsed: String? = null
    
    @Column(name = "personnel_involved", columnDefinition = "JSONB")
    var personnelInvolved: String? = null
    
    @Column(name = "progress_photos", columnDefinition = "JSONB")
    var progressPhotos: String? = null
    
    @Column(name = "progress_documents", columnDefinition = "JSONB")
    var progressDocuments: String? = null
    
    @Column(name = "next_steps", columnDefinition = "TEXT")
    var nextSteps: String? = null
    
    @Column(name = "expected_completion_date")
    var expectedCompletionDate: LocalDateTime? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reported_by", nullable = false)
    lateinit var reportedBy: User
    
    @Column(name = "supervisor_reviewed")
    var supervisorReviewed: Boolean = false
    
    @Column(name = "supervisor_notes", columnDefinition = "TEXT")
    var supervisorNotes: String? = null
    
    /**
     * 진행률 업데이트
     */
    fun updateProgress(
        percentage: Int,
        phase: WorkPhase,
        workCompleted: String? = null,
        workRemaining: String? = null
    ) {
        require(percentage in 0..100) { "진행률은 0-100 사이여야 합니다." }
        require(percentage >= this.progressPercentage) { "진행률은 이전 값보다 작을 수 없습니다." }
        
        this.progressPercentage = percentage
        this.workPhase = phase
        this.workCompleted = workCompleted
        this.workRemaining = workRemaining
        this.progressDate = LocalDateTime.now()
        
        // 작업 지시서의 진행률도 업데이트
        workOrder.updateProgress(percentage, phase)
    }
    
    /**
     * 작업 시간 기록
     */
    fun recordWorkHours(hours: BigDecimal) {
        require(hours >= BigDecimal.ZERO) { "작업 시간은 0 이상이어야 합니다." }
        
        this.hoursWorked = hours
        this.cumulativeHours = this.cumulativeHours.add(hours)
        
        // 작업 지시서의 실제 작업 시간도 업데이트
        workOrder.actualDurationHours = workOrder.actualDurationHours.add(hours)
    }
    
    /**
     * 품질 체크포인트 완료
     */
    fun completeQualityCheckpoint(checkpointsCompleted: Int = 1) {
        this.qualityCheckpointsCompleted += checkpointsCompleted
    }
    
    /**
     * 품질 이슈 기록
     */
    fun recordQualityIssue(issuesFound: Int = 1) {
        this.qualityIssuesFound += issuesFound
    }
    
    /**
     * 품질 이슈 해결
     */
    fun resolveQualityIssue(issuesResolved: Int = 1) {
        require(issuesResolved <= qualityIssuesFound) { "해결된 이슈 수는 발견된 이슈 수를 초과할 수 없습니다." }
        this.qualityIssuesResolved += issuesResolved
    }
    
    /**
     * 이슈 발생 기록
     */
    fun recordIssue(issue: String) {
        this.issuesEncountered = if (this.issuesEncountered.isNullOrBlank()) {
            issue
        } else {
            "${this.issuesEncountered}\n$issue"
        }
    }
    
    /**
     * 감독자 검토
     */
    fun reviewBySupervisor(notes: String? = null) {
        this.supervisorReviewed = true
        this.supervisorNotes = notes
    }
    
    /**
     * 다음 단계 설정
     */
    fun setNextSteps(steps: String, expectedCompletion: LocalDateTime? = null) {
        this.nextSteps = steps
        this.expectedCompletionDate = expectedCompletion
    }
    
    /**
     * 사진 추가
     */
    fun addProgressPhoto(photoUrl: String) {
        // JSON 배열 형태로 사진 URL 저장
        val photos = if (progressPhotos.isNullOrBlank()) {
            mutableListOf<String>()
        } else {
            // 실제 구현에서는 JSON 파싱 라이브러리 사용
            mutableListOf<String>()
        }
        photos.add(photoUrl)
        // 실제 구현에서는 JSON으로 직렬화
        this.progressPhotos = photos.toString()
    }
    
    /**
     * 문서 추가
     */
    fun addProgressDocument(documentUrl: String, documentName: String) {
        // JSON 객체 형태로 문서 정보 저장
        // 실제 구현에서는 JSON 파싱 라이브러리 사용
        val documents = mutableMapOf<String, String>()
        documents[documentName] = documentUrl
        this.progressDocuments = documents.toString()
    }
    
    /**
     * 진행률 검증
     */
    fun validateProgress(): Boolean {
        return when (workPhase) {
            WorkPhase.PLANNING -> progressPercentage in 0..10
            WorkPhase.PREPARATION -> progressPercentage in 11..20
            WorkPhase.EXECUTION -> progressPercentage in 21..80
            WorkPhase.TESTING -> progressPercentage in 81..95
            WorkPhase.COMPLETION -> progressPercentage in 96..99
            WorkPhase.CLOSURE -> progressPercentage == 100
        }
    }
    
    /**
     * 품질 점수 계산
     */
    fun calculateQualityScore(): BigDecimal {
        return if (qualityCheckpointsCompleted > 0) {
            val issueRate = qualityIssuesFound.toDouble() / qualityCheckpointsCompleted.toDouble()
            val resolveRate = if (qualityIssuesFound > 0) {
                qualityIssuesResolved.toDouble() / qualityIssuesFound.toDouble()
            } else {
                1.0
            }
            
            val score = (1.0 - issueRate * 0.5) * resolveRate * 10.0
            BigDecimal.valueOf(score.coerceIn(0.0, 10.0))
        } else {
            BigDecimal.ZERO
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is WorkOrderProgress) return false
        return progressId == other.progressId
    }
    
    override fun hashCode(): Int {
        return progressId.hashCode()
    }
    
    override fun toString(): String {
        return "WorkOrderProgress(progressId=$progressId, progressPercentage=$progressPercentage, workPhase=$workPhase, progressDate=$progressDate)"
    }
}