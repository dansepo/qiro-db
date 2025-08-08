package com.qiro.domain.maintenance.dto

import com.qiro.domain.maintenance.entity.AssetCondition
import com.qiro.domain.maintenance.entity.ExecutionStatus
import com.qiro.domain.maintenance.entity.ExecutionType
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예방 정비 실행 DTO
 */
data class PreventiveMaintenanceExecutionDto(
    val executionId: UUID,
    val companyId: UUID,
    val planId: UUID,
    val assetId: UUID,
    val executionNumber: String,
    val executionType: ExecutionType,
    val executionDate: LocalDate,
    val plannedStartTime: LocalDateTime?,
    val actualStartTime: LocalDateTime?,
    val plannedEndTime: LocalDateTime?,
    val actualEndTime: LocalDateTime?,
    val plannedDurationHours: BigDecimal,
    val actualDurationHours: BigDecimal,
    val downtimeHours: BigDecimal,
    val maintenanceTeam: String?,
    val leadTechnicianId: UUID?,
    val supportingTechnicians: String?,
    val contractorId: UUID?,
    val executionStatus: ExecutionStatus,
    val completionPercentage: BigDecimal,
    val equipmentShutdownRequired: Boolean,
    val shutdownStartTime: LocalDateTime?,
    val shutdownEndTime: LocalDateTime?,
    val environmentalConditions: String?,
    val safetyBriefingCompleted: Boolean,
    val permitsObtained: String?,
    val lockoutTagoutApplied: Boolean,
    val safetyIncidents: String?,
    val materialsUsed: String?,
    val toolsUsed: String?,
    val sparePartsConsumed: String?,
    val plannedCost: BigDecimal,
    val actualCost: BigDecimal,
    val laborCost: BigDecimal,
    val materialCost: BigDecimal,
    val contractorCost: BigDecimal,
    val workQualityRating: BigDecimal,
    val assetConditionBefore: AssetCondition?,
    val assetConditionAfter: AssetCondition?,
    val performanceImprovement: BigDecimal,
    val issuesEncountered: String?,
    val unexpectedFindings: String?,
    val additionalWorkRequired: Boolean,
    val followUpActions: String?,
    val workPhotos: String?,
    val completionCertificates: String?,
    val testResults: String?,
    val maintenanceReports: String?,
    val workCompletedBy: UUID?,
    val workCompletionDate: LocalDateTime?,
    val reviewedBy: UUID?,
    val reviewDate: LocalDate?,
    val approvedBy: UUID?,
    val approvalDate: LocalDate?,
    val technicianNotes: String?,
    val supervisorComments: String?,
    val lessonsLearned: String?,
    val recommendations: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

/**
 * 예방 정비 실행 생성 요청 DTO
 */
data class CreatePreventiveMaintenanceExecutionRequest(
    val companyId: UUID,
    val planId: UUID,
    val assetId: UUID,
    val executionType: ExecutionType = ExecutionType.SCHEDULED,
    val executionDate: LocalDate,
    val plannedStartTime: LocalDateTime?,
    val plannedEndTime: LocalDateTime?,
    val plannedDurationHours: BigDecimal = BigDecimal.ZERO,
    val maintenanceTeam: String?,
    val leadTechnicianId: UUID?,
    val supportingTechnicians: String?,
    val contractorId: UUID?,
    val equipmentShutdownRequired: Boolean = false,
    val environmentalConditions: String?,
    val plannedCost: BigDecimal = BigDecimal.ZERO,
    val createdBy: UUID?
)

/**
 * 예방 정비 실행 업데이트 요청 DTO
 */
data class UpdatePreventiveMaintenanceExecutionRequest(
    val executionStatus: ExecutionStatus?,
    val actualStartTime: LocalDateTime?,
    val actualEndTime: LocalDateTime?,
    val actualDurationHours: BigDecimal?,
    val downtimeHours: BigDecimal?,
    val completionPercentage: BigDecimal?,
    val shutdownStartTime: LocalDateTime?,
    val shutdownEndTime: LocalDateTime?,
    val environmentalConditions: String?,
    val safetyBriefingCompleted: Boolean?,
    val permitsObtained: String?,
    val lockoutTagoutApplied: Boolean?,
    val safetyIncidents: String?,
    val materialsUsed: String?,
    val toolsUsed: String?,
    val sparePartsConsumed: String?,
    val actualCost: BigDecimal?,
    val laborCost: BigDecimal?,
    val materialCost: BigDecimal?,
    val contractorCost: BigDecimal?,
    val workQualityRating: BigDecimal?,
    val assetConditionBefore: AssetCondition?,
    val assetConditionAfter: AssetCondition?,
    val performanceImprovement: BigDecimal?,
    val issuesEncountered: String?,
    val unexpectedFindings: String?,
    val additionalWorkRequired: Boolean?,
    val followUpActions: String?,
    val workPhotos: String?,
    val completionCertificates: String?,
    val testResults: String?,
    val maintenanceReports: String?,
    val technicianNotes: String?,
    val supervisorComments: String?,
    val lessonsLearned: String?,
    val recommendations: String?,
    val updatedBy: UUID?
)

/**
 * 예방 정비 실행 완료 요청 DTO
 */
data class CompletePreventiveMaintenanceExecutionRequest(
    val workCompletionDate: LocalDateTime = LocalDateTime.now(),
    val actualDurationHours: BigDecimal,
    val downtimeHours: BigDecimal = BigDecimal.ZERO,
    val actualCost: BigDecimal,
    val laborCost: BigDecimal = BigDecimal.ZERO,
    val materialCost: BigDecimal = BigDecimal.ZERO,
    val contractorCost: BigDecimal = BigDecimal.ZERO,
    val workQualityRating: BigDecimal,
    val assetConditionAfter: AssetCondition,
    val performanceImprovement: BigDecimal = BigDecimal.ZERO,
    val issuesEncountered: String?,
    val unexpectedFindings: String?,
    val additionalWorkRequired: Boolean = false,
    val followUpActions: String?,
    val workPhotos: String?,
    val completionCertificates: String?,
    val testResults: String?,
    val maintenanceReports: String?,
    val technicianNotes: String?,
    val supervisorComments: String?,
    val lessonsLearned: String?,
    val recommendations: String?,
    val workCompletedBy: UUID
)

/**
 * 예방 정비 실행 필터 DTO
 */
data class PreventiveMaintenanceExecutionFilter(
    val companyId: UUID,
    val planId: UUID? = null,
    val assetId: UUID? = null,
    val executionStatus: ExecutionStatus? = null,
    val executionType: ExecutionType? = null,
    val leadTechnicianId: UUID? = null,
    val contractorId: UUID? = null,
    val executionDateFrom: LocalDate? = null,
    val executionDateTo: LocalDate? = null,
    val searchKeyword: String? = null
)

/**
 * 예방 정비 실행 요약 DTO
 */
data class PreventiveMaintenanceExecutionSummaryDto(
    val executionId: UUID,
    val executionNumber: String,
    val planId: UUID,
    val planName: String,
    val assetId: UUID,
    val executionDate: LocalDate,
    val executionStatus: ExecutionStatus,
    val completionPercentage: BigDecimal,
    val leadTechnicianId: UUID?,
    val plannedCost: BigDecimal,
    val actualCost: BigDecimal
)

/**
 * 예방 정비 실행 통계 DTO
 */
data class PreventiveMaintenanceExecutionStatisticsDto(
    val totalExecutions: Long,
    val completedExecutions: Long,
    val inProgressExecutions: Long,
    val plannedExecutions: Long,
    val overdueExecutions: Long,
    val averageCompletionTime: Double,
    val averageCost: BigDecimal,
    val averageQualityRating: BigDecimal,
    val executionsByStatus: Map<ExecutionStatus, Long>,
    val executionsByType: Map<ExecutionType, Long>
)

/**
 * 정비 일정 알림 DTO
 */
data class MaintenanceScheduleNotificationDto(
    val executionId: UUID,
    val executionNumber: String,
    val planName: String,
    val assetName: String,
    val executionDate: LocalDate,
    val plannedStartTime: LocalDateTime?,
    val leadTechnicianId: UUID?,
    val notificationType: NotificationType,
    val daysUntilExecution: Long
)

/**
 * 알림 유형
 */
enum class NotificationType {
    UPCOMING_MAINTENANCE,    // 예정된 정비
    OVERDUE_MAINTENANCE,     // 지연된 정비
    URGENT_MAINTENANCE,      // 긴급 정비
    MAINTENANCE_REMINDER     // 정비 알림
}