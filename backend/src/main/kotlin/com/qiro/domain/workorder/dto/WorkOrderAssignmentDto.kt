package com.qiro.domain.workorder.dto

import com.qiro.domain.workorder.entity.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 배정 생성 요청 DTO
 */
data class CreateAssignmentRequest(
    val workOrderId: UUID,
    val assignedToId: UUID,
    val assignmentRole: AssignmentRole,
    val assignmentType: AssignmentType,
    val expectedStartDate: LocalDateTime? = null,
    val expectedEndDate: LocalDateTime? = null,
    val allocatedHours: BigDecimal = BigDecimal.ZERO,
    val assignmentNotes: String? = null
)

/**
 * 작업 배정 수락/거부 요청 DTO
 */
data class AssignmentResponseRequest(
    val accepted: Boolean,
    val notes: String? = null
)

/**
 * 작업 배정 진행률 업데이트 요청 DTO
 */
data class AssignmentProgressUpdateRequest(
    val workPercentage: Int,
    val actualHours: BigDecimal? = null,
    val notes: String? = null
)

/**
 * 작업 배정 완료 요청 DTO
 */
data class CompleteAssignmentRequest(
    val completionNotes: String? = null,
    val actualHours: BigDecimal? = null
)

/**
 * 작업 배정 성과 평가 요청 DTO
 */
data class EvaluateAssignmentRequest(
    val performanceRating: BigDecimal,
    val qualityScore: BigDecimal,
    val timelinessScore: BigDecimal,
    val evaluationNotes: String? = null
)

/**
 * 작업 배정 응답 DTO
 */
data class WorkOrderAssignmentResponse(
    val assignmentId: UUID,
    val workOrderId: UUID,
    val workOrderNumber: String,
    val workOrderTitle: String,
    val assignedTo: UserSummary,
    val assignmentRole: AssignmentRole,
    val assignmentType: AssignmentType,
    val assignedDate: LocalDateTime,
    val expectedStartDate: LocalDateTime? = null,
    val expectedEndDate: LocalDateTime? = null,
    val assignmentStatus: AssignmentStatus,
    val acceptanceStatus: AcceptanceStatus,
    val allocatedHours: BigDecimal,
    val actualHours: BigDecimal,
    val workPercentage: Int,
    val assignmentNotes: String? = null,
    val acceptanceNotes: String? = null,
    val completionNotes: String? = null,
    val performanceRating: BigDecimal,
    val qualityScore: BigDecimal,
    val timelinessScore: BigDecimal,
    val completedDate: LocalDateTime? = null,
    val completedBy: UserSummary? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

/**
 * 작업 배정 요약 DTO
 */
data class AssignmentSummary(
    val assignmentId: UUID,
    val workOrderNumber: String,
    val workOrderTitle: String,
    val assignmentRole: AssignmentRole,
    val assignmentStatus: AssignmentStatus,
    val workPercentage: Int,
    val expectedStartDate: LocalDateTime? = null,
    val expectedEndDate: LocalDateTime? = null,
    val assignedDate: LocalDateTime
)

/**
 * 작업자별 배정 현황 DTO
 */
data class WorkerAssignmentStatus(
    val worker: UserSummary,
    val totalAssignments: Int,
    val activeAssignments: Int,
    val completedAssignments: Int,
    val averagePerformanceRating: BigDecimal,
    val averageQualityScore: BigDecimal,
    val averageTimelinessScore: BigDecimal,
    val totalAllocatedHours: BigDecimal,
    val totalActualHours: BigDecimal,
    val currentWorkload: Int, // 현재 진행 중인 작업의 총 진행률
    val assignments: List<AssignmentSummary>
)

/**
 * 작업 배정 검색 요청 DTO
 */
data class AssignmentSearchRequest(
    val workOrderId: UUID? = null,
    val assignedToId: UUID? = null,
    val assignmentRole: AssignmentRole? = null,
    val assignmentStatus: AssignmentStatus? = null,
    val acceptanceStatus: AcceptanceStatus? = null,
    val startDate: LocalDateTime? = null,
    val endDate: LocalDateTime? = null,
    val page: Int = 0,
    val size: Int = 20,
    val sortBy: String = "assignedDate",
    val sortDirection: String = "DESC"
)

/**
 * 작업 배정 통계 DTO
 */
data class AssignmentStatistics(
    val totalAssignments: Long,
    val activeAssignments: Long,
    val completedAssignments: Long,
    val cancelledAssignments: Long,
    val acceptanceRate: Double,
    val completionRate: Double,
    val averagePerformanceRating: BigDecimal,
    val averageQualityScore: BigDecimal,
    val averageTimelinessScore: BigDecimal,
    val roleStatistics: Map<AssignmentRole, Long>,
    val typeStatistics: Map<AssignmentType, Long>,
    val statusStatistics: Map<AssignmentStatus, Long>
)

/**
 * 작업자 성과 요약 DTO
 */
data class WorkerPerformanceSummary(
    val worker: UserSummary,
    val period: String, // 예: "2024-01", "2024-Q1"
    val totalAssignments: Int,
    val completedAssignments: Int,
    val completionRate: Double,
    val averagePerformanceRating: BigDecimal,
    val averageQualityScore: BigDecimal,
    val averageTimelinessScore: BigDecimal,
    val totalHoursWorked: BigDecimal,
    val averageHoursPerAssignment: BigDecimal,
    val onTimeCompletionRate: Double
)