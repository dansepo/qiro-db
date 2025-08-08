package com.qiro.domain.workorder.dto

import com.qiro.domain.workorder.entity.WorkPhase
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 진행 상황 기록 요청 DTO
 */
data class CreateProgressRecordRequest(
    val workOrderId: UUID,
    val progressPercentage: Int,
    val workPhase: WorkPhase,
    val workCompleted: String? = null,
    val workRemaining: String? = null,
    val issuesEncountered: String? = null,
    val hoursWorked: BigDecimal = BigDecimal.ZERO,
    val qualityCheckpointsCompleted: Int = 0,
    val qualityIssuesFound: Int = 0,
    val qualityIssuesResolved: Int = 0,
    val materialsUsed: String? = null,
    val toolsUsed: String? = null,
    val personnelInvolved: String? = null,
    val nextSteps: String? = null,
    val expectedCompletionDate: LocalDateTime? = null,
    val progressPhotos: List<String> = emptyList(),
    val progressDocuments: Map<String, String> = emptyMap()
)

/**
 * 작업 진행 상황 업데이트 요청 DTO
 */
data class UpdateProgressRecordRequest(
    val progressPercentage: Int? = null,
    val workPhase: WorkPhase? = null,
    val workCompleted: String? = null,
    val workRemaining: String? = null,
    val issuesEncountered: String? = null,
    val hoursWorked: BigDecimal? = null,
    val qualityCheckpointsCompleted: Int? = null,
    val qualityIssuesFound: Int? = null,
    val qualityIssuesResolved: Int? = null,
    val nextSteps: String? = null,
    val expectedCompletionDate: LocalDateTime? = null
)

/**
 * 감독자 검토 요청 DTO
 */
data class SupervisorReviewRequest(
    val supervisorNotes: String? = null,
    val approved: Boolean = true
)

/**
 * 작업 진행 상황 응답 DTO
 */
data class WorkOrderProgressResponse(
    val progressId: UUID,
    val workOrderId: UUID,
    val workOrderNumber: String,
    val progressDate: LocalDateTime,
    val progressPercentage: Int,
    val workPhase: WorkPhase,
    val workCompleted: String? = null,
    val workRemaining: String? = null,
    val issuesEncountered: String? = null,
    val hoursWorked: BigDecimal,
    val cumulativeHours: BigDecimal,
    val qualityCheckpointsCompleted: Int,
    val qualityIssuesFound: Int,
    val qualityIssuesResolved: Int,
    val materialsUsed: String? = null,
    val toolsUsed: String? = null,
    val personnelInvolved: String? = null,
    val progressPhotos: String? = null,
    val progressDocuments: String? = null,
    val nextSteps: String? = null,
    val expectedCompletionDate: LocalDateTime? = null,
    val reportedBy: UserSummary,
    val supervisorReviewed: Boolean,
    val supervisorNotes: String? = null,
    val qualityScore: BigDecimal,
    val createdAt: LocalDateTime
)

/**
 * 작업 진행 상황 요약 DTO
 */
data class ProgressSummary(
    val progressId: UUID,
    val progressDate: LocalDateTime,
    val progressPercentage: Int,
    val workPhase: WorkPhase,
    val hoursWorked: BigDecimal,
    val reportedBy: UserSummary,
    val supervisorReviewed: Boolean,
    val qualityScore: BigDecimal
)

/**
 * 작업 진행 타임라인 DTO
 */
data class WorkOrderTimeline(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val workOrderTitle: String,
    val currentStatus: String,
    val currentPhase: WorkPhase,
    val currentProgress: Int,
    val milestones: List<TimelineMilestone>,
    val progressRecords: List<ProgressSummary>
)

/**
 * 타임라인 마일스톤 DTO
 */
data class TimelineMilestone(
    val date: LocalDateTime,
    val title: String,
    val description: String,
    val type: MilestoneType,
    val completed: Boolean = false
)

/**
 * 마일스톤 유형
 */
enum class MilestoneType(
    val displayName: String
) {
    CREATED("생성됨"),
    APPROVED("승인됨"),
    ASSIGNED("배정됨"),
    STARTED("시작됨"),
    PHASE_CHANGED("단계변경"),
    ISSUE_REPORTED("이슈발생"),
    ISSUE_RESOLVED("이슈해결"),
    COMPLETED("완료됨"),
    CLOSED("종료됨")
}

/**
 * 작업 진행 상황 검색 요청 DTO
 */
data class ProgressSearchRequest(
    val workOrderId: UUID? = null,
    val workPhase: WorkPhase? = null,
    val reportedById: UUID? = null,
    val startDate: LocalDateTime? = null,
    val endDate: LocalDateTime? = null,
    val supervisorReviewed: Boolean? = null,
    val hasIssues: Boolean? = null,
    val page: Int = 0,
    val size: Int = 20,
    val sortBy: String = "progressDate",
    val sortDirection: String = "DESC"
)

/**
 * 작업 진행 통계 DTO
 */
data class ProgressStatistics(
    val totalRecords: Long,
    val averageProgressPerDay: Double,
    val totalHoursWorked: BigDecimal,
    val averageHoursPerRecord: BigDecimal,
    val totalQualityCheckpoints: Int,
    val totalQualityIssues: Int,
    val qualityIssueResolutionRate: Double,
    val averageQualityScore: BigDecimal,
    val phaseStatistics: Map<WorkPhase, Long>,
    val supervisorReviewRate: Double,
    val issueFrequency: Double // 기록당 평균 이슈 수
)

/**
 * 일별 진행 현황 DTO
 */
data class DailyProgressReport(
    val date: String, // YYYY-MM-DD 형식
    val totalWorkOrders: Int,
    val activeWorkOrders: Int,
    val completedWorkOrders: Int,
    val totalHoursWorked: BigDecimal,
    val averageProgress: Double,
    val qualityIssuesReported: Int,
    val qualityIssuesResolved: Int,
    val phaseDistribution: Map<WorkPhase, Int>
)

/**
 * 작업자별 진행 현황 DTO
 */
data class WorkerProgressReport(
    val worker: UserSummary,
    val period: String,
    val totalProgressRecords: Int,
    val totalHoursWorked: BigDecimal,
    val averageProgressPerRecord: Double,
    val qualityCheckpointsCompleted: Int,
    val qualityIssuesFound: Int,
    val qualityIssuesResolved: Int,
    val averageQualityScore: BigDecimal,
    val supervisorReviewRate: Double,
    val mostActivePhase: WorkPhase,
    val productivity: Double // 시간당 진행률
)