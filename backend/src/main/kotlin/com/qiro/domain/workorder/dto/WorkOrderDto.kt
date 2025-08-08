package com.qiro.domain.workorder.dto

import com.qiro.domain.workorder.entity.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 생성 요청 DTO
 */
data class CreateWorkOrderRequest(
    val workOrderTitle: String,
    val workDescription: String,
    val workCategory: WorkCategory,
    val workType: WorkType,
    val workPriority: WorkPriority,
    val workUrgency: WorkUrgency,
    val buildingId: UUID? = null,
    val unitId: UUID? = null,
    val assetId: UUID? = null,
    val faultReportId: UUID? = null,
    val templateId: UUID? = null,
    val requestReason: String? = null,
    val workLocation: String? = null,
    val workScope: String? = null,
    val scheduledStartDate: LocalDateTime? = null,
    val scheduledEndDate: LocalDateTime? = null,
    val estimatedDurationHours: BigDecimal = BigDecimal.ZERO,
    val estimatedCost: BigDecimal = BigDecimal.ZERO
)

/**
 * 작업 지시서 업데이트 요청 DTO
 */
data class UpdateWorkOrderRequest(
    val workOrderTitle: String? = null,
    val workDescription: String? = null,
    val workPriority: WorkPriority? = null,
    val workUrgency: WorkUrgency? = null,
    val workLocation: String? = null,
    val workScope: String? = null,
    val scheduledStartDate: LocalDateTime? = null,
    val scheduledEndDate: LocalDateTime? = null,
    val estimatedDurationHours: BigDecimal? = null,
    val estimatedCost: BigDecimal? = null,
    val approvedBudget: BigDecimal? = null
)

/**
 * 작업 지시서 상태 변경 요청 DTO
 */
data class WorkOrderStatusUpdateRequest(
    val newStatus: WorkStatus,
    val notes: String? = null
)

/**
 * 작업자 배정 요청 DTO
 */
data class AssignWorkerRequest(
    val workerId: UUID,
    val assignmentRole: AssignmentRole = AssignmentRole.PRIMARY_TECHNICIAN,
    val assignmentType: AssignmentType = AssignmentType.INTERNAL,
    val expectedStartDate: LocalDateTime? = null,
    val expectedEndDate: LocalDateTime? = null,
    val allocatedHours: BigDecimal = BigDecimal.ZERO,
    val assignmentNotes: String? = null
)

/**
 * 작업 승인 요청 DTO
 */
data class ApproveWorkOrderRequest(
    val approvalNotes: String? = null,
    val approvedBudget: BigDecimal? = null
)

/**
 * 작업 완료 요청 DTO
 */
data class CompleteWorkOrderRequest(
    val completionNotes: String? = null,
    val qualityRating: BigDecimal? = null,
    val customerSatisfaction: BigDecimal? = null,
    val actualCost: BigDecimal? = null,
    val followUpRequired: Boolean = false,
    val followUpDate: LocalDateTime? = null,
    val followUpNotes: String? = null
)

/**
 * 작업 지시서 응답 DTO
 */
data class WorkOrderResponse(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val workOrderTitle: String,
    val workDescription: String,
    val workCategory: WorkCategory,
    val workType: WorkType,
    val workPriority: WorkPriority,
    val workUrgency: WorkUrgency,
    val workStatus: WorkStatus,
    val approvalStatus: ApprovalStatus,
    val workPhase: WorkPhase,
    val progressPercentage: Int,
    val buildingId: UUID? = null,
    val buildingName: String? = null,
    val unitId: UUID? = null,
    val unitName: String? = null,
    val assetId: UUID? = null,
    val assetName: String? = null,
    val faultReportId: UUID? = null,
    val templateId: UUID? = null,
    val requestedBy: UserSummary? = null,
    val requestDate: LocalDateTime,
    val requestReason: String? = null,
    val workLocation: String? = null,
    val workScope: String? = null,
    val scheduledStartDate: LocalDateTime? = null,
    val scheduledEndDate: LocalDateTime? = null,
    val estimatedDurationHours: BigDecimal,
    val assignedTo: UserSummary? = null,
    val assignedTeam: String? = null,
    val assignmentDate: LocalDateTime? = null,
    val actualStartDate: LocalDateTime? = null,
    val actualEndDate: LocalDateTime? = null,
    val actualDurationHours: BigDecimal,
    val estimatedCost: BigDecimal,
    val approvedBudget: BigDecimal,
    val actualCost: BigDecimal,
    val workCompletionNotes: String? = null,
    val qualityRating: BigDecimal,
    val customerSatisfaction: BigDecimal,
    val followUpRequired: Boolean,
    val followUpDate: LocalDateTime? = null,
    val followUpNotes: String? = null,
    val approvedBy: UserSummary? = null,
    val approvalDate: LocalDateTime? = null,
    val approvalNotes: String? = null,
    val closedBy: UserSummary? = null,
    val closedDate: LocalDateTime? = null,
    val closureReason: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val isDelayed: Boolean = false
)

/**
 * 작업 지시서 요약 DTO
 */
data class WorkOrderSummary(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val workOrderTitle: String,
    val workCategory: WorkCategory,
    val workType: WorkType,
    val workPriority: WorkPriority,
    val workStatus: WorkStatus,
    val progressPercentage: Int,
    val assignedTo: UserSummary? = null,
    val scheduledStartDate: LocalDateTime? = null,
    val scheduledEndDate: LocalDateTime? = null,
    val isDelayed: Boolean = false,
    val createdAt: LocalDateTime
)

/**
 * 사용자 요약 DTO
 */
data class UserSummary(
    val userId: UUID,
    val userName: String,
    val userEmail: String? = null
)

/**
 * 작업 지시서 검색 요청 DTO
 */
data class WorkOrderSearchRequest(
    val keyword: String? = null,
    val workCategory: WorkCategory? = null,
    val workType: WorkType? = null,
    val workStatus: WorkStatus? = null,
    val workPriority: WorkPriority? = null,
    val assignedTo: UUID? = null,
    val buildingId: UUID? = null,
    val unitId: UUID? = null,
    val requestedBy: UUID? = null,
    val startDate: LocalDateTime? = null,
    val endDate: LocalDateTime? = null,
    val isDelayed: Boolean? = null,
    val page: Int = 0,
    val size: Int = 20,
    val sortBy: String = "createdAt",
    val sortDirection: String = "DESC"
)

/**
 * 작업 지시서 통계 DTO
 */
data class WorkOrderStatistics(
    val totalCount: Long,
    val pendingCount: Long,
    val inProgressCount: Long,
    val completedCount: Long,
    val cancelledCount: Long,
    val delayedCount: Long,
    val averageCompletionDays: Double,
    val completionRate: Double,
    val onTimeCompletionRate: Double,
    val averageQualityRating: BigDecimal,
    val averageCustomerSatisfaction: BigDecimal,
    val categoryStatistics: Map<WorkCategory, Long>,
    val typeStatistics: Map<WorkType, Long>,
    val priorityStatistics: Map<WorkPriority, Long>
)

/**
 * 작업 지시서 대시보드 DTO
 */
data class WorkOrderDashboard(
    val statistics: WorkOrderStatistics,
    val recentWorkOrders: List<WorkOrderSummary>,
    val urgentWorkOrders: List<WorkOrderSummary>,
    val delayedWorkOrders: List<WorkOrderSummary>,
    val myAssignedWorkOrders: List<WorkOrderSummary>
)

/**
 * 작업자 통계 DTO
 */
data class WorkerStatistics(
    val workerId: UUID,
    val workerName: String,
    val totalAssignedCount: Long,
    val completedCount: Long,
    val inProgressCount: Long,
    val pendingCount: Long,
    val cancelledCount: Long,
    val completionRate: Double,
    val averageCompletionDays: Double,
    val onTimeCompletionRate: Double,
    val averageQualityRating: BigDecimal,
    val totalWorkingHours: BigDecimal,
    val workloadByCategory: Map<WorkCategory, Long>,
    val workloadByType: Map<WorkType, Long>,
    val monthlyCompletionTrend: Map<String, Long>
)

/**
 * 작업 진행 상황 업데이트 요청 DTO
 */
data class WorkProgressUpdateRequest(
    val progressPercentage: Int,
    val workPhase: WorkPhase,
    val progressNotes: String? = null,
    val actualHoursWorked: BigDecimal? = null,
    val issuesEncountered: String? = null,
    val nextSteps: String? = null
)

/**
 * 작업 지시서 복사 요청 DTO
 */
data class CopyWorkOrderRequest(
    val newTitle: String,
    val newDescription: String? = null,
    val scheduledStartDate: LocalDateTime? = null,
    val scheduledEndDate: LocalDateTime? = null,
    val copyAssignments: Boolean = false,
    val copyMaterials: Boolean = false
)

/**
 * 일괄 상태 변경 요청 DTO
 */
data class BatchStatusUpdateRequest(
    val workOrderIds: List<UUID>,
    val newStatus: WorkStatus,
    val notes: String? = null
)

/**
 * 일괄 배정 요청 DTO
 */
data class BatchAssignRequest(
    val workOrderIds: List<UUID>,
    val workerId: UUID,
    val assignmentRole: AssignmentRole = AssignmentRole.PRIMARY_TECHNICIAN,
    val assignmentNotes: String? = null
)

/**
 * 일괄 업데이트 결과 DTO
 */
data class BatchUpdateResult(
    val totalCount: Int,
    val successCount: Int,
    val failureCount: Int,
    val failedItems: List<BatchUpdateFailure>
)

/**
 * 일괄 업데이트 실패 항목 DTO
 */
data class BatchUpdateFailure(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val reason: String
)

/**
 * 작업 배정 역할 열거형
 */
enum class AssignmentRole {
    PRIMARY_TECHNICIAN,     // 주 담당자
    SECONDARY_TECHNICIAN,   // 보조 담당자
    SUPERVISOR,             // 감독자
    SPECIALIST,             // 전문가
    CONTRACTOR              // 외부 업체
}

/**
 * 작업 배정 유형 열거형
 */
enum class AssignmentType {
    INTERNAL,               // 내부 직원
    CONTRACTOR,             // 외부 업체
    TEMPORARY               // 임시 배정
}