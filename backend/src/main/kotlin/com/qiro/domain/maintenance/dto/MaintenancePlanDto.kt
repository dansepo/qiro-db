package com.qiro.domain.maintenance.dto

import com.qiro.domain.maintenance.entity.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 정비 계획 DTO
 */
data class MaintenancePlanDto(
    val planId: UUID,
    val companyId: UUID,
    val assetId: UUID,
    val planName: String,
    val planCode: String,
    val planDescription: String?,
    val planType: MaintenancePlanType,
    val maintenanceStrategy: MaintenanceStrategy,
    val maintenanceApproach: MaintenanceApproach,
    val criticalityAnalysis: String?,
    val frequencyType: FrequencyType,
    val frequencyInterval: Int,
    val frequencyUnit: String?,
    val estimatedDurationHours: BigDecimal,
    val estimatedCost: BigDecimal,
    val requiredDowntimeHours: BigDecimal,
    val requiredPersonnel: String?,
    val requiredSkills: String?,
    val requiredTools: String?,
    val requiredParts: String?,
    val safetyRequirements: String?,
    val permitRequirements: String?,
    val regulatoryCompliance: String?,
    val targetAvailability: BigDecimal,
    val targetReliability: BigDecimal,
    val targetCostPerYear: BigDecimal,
    val planStatus: PlanStatus,
    val approvalStatus: ApprovalStatus,
    val effectiveDate: LocalDate,
    val reviewDate: LocalDate?,
    val actualCostYtd: BigDecimal,
    val actualHoursYtd: BigDecimal,
    val completionRate: BigDecimal,
    val effectivenessScore: BigDecimal,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?,
    val approvedBy: UUID?,
    val approvedAt: LocalDateTime?
)

/**
 * 정비 계획 생성 요청 DTO
 */
data class CreateMaintenancePlanRequest(
    val companyId: UUID,
    val assetId: UUID,
    val planName: String,
    val planCode: String,
    val planDescription: String?,
    val planType: MaintenancePlanType,
    val maintenanceStrategy: MaintenanceStrategy,
    val maintenanceApproach: MaintenanceApproach,
    val criticalityAnalysis: String?,
    val frequencyType: FrequencyType,
    val frequencyInterval: Int = 1,
    val frequencyUnit: String?,
    val estimatedDurationHours: BigDecimal = BigDecimal.ZERO,
    val estimatedCost: BigDecimal = BigDecimal.ZERO,
    val requiredDowntimeHours: BigDecimal = BigDecimal.ZERO,
    val requiredPersonnel: String?,
    val requiredSkills: String?,
    val requiredTools: String?,
    val requiredParts: String?,
    val safetyRequirements: String?,
    val permitRequirements: String?,
    val regulatoryCompliance: String?,
    val targetAvailability: BigDecimal = BigDecimal("95.00"),
    val targetReliability: BigDecimal = BigDecimal("95.00"),
    val targetCostPerYear: BigDecimal = BigDecimal.ZERO,
    val effectiveDate: LocalDate = LocalDate.now(),
    val reviewDate: LocalDate?,
    val createdBy: UUID?
)

/**
 * 정비 계획 업데이트 요청 DTO
 */
data class UpdateMaintenancePlanRequest(
    val planName: String?,
    val planDescription: String?,
    val planType: MaintenancePlanType?,
    val maintenanceStrategy: MaintenanceStrategy?,
    val maintenanceApproach: MaintenanceApproach?,
    val criticalityAnalysis: String?,
    val frequencyType: FrequencyType?,
    val frequencyInterval: Int?,
    val frequencyUnit: String?,
    val estimatedDurationHours: BigDecimal?,
    val estimatedCost: BigDecimal?,
    val requiredDowntimeHours: BigDecimal?,
    val requiredPersonnel: String?,
    val requiredSkills: String?,
    val requiredTools: String?,
    val requiredParts: String?,
    val safetyRequirements: String?,
    val permitRequirements: String?,
    val regulatoryCompliance: String?,
    val targetAvailability: BigDecimal?,
    val targetReliability: BigDecimal?,
    val targetCostPerYear: BigDecimal?,
    val planStatus: PlanStatus?,
    val effectiveDate: LocalDate?,
    val reviewDate: LocalDate?,
    val updatedBy: UUID?
)

/**
 * 정비 계획 승인 요청 DTO
 */
data class ApprovePlanRequest(
    val approvalStatus: ApprovalStatus,
    val approvalComments: String?,
    val approvedBy: UUID
)

/**
 * 정비 계획 필터 DTO
 */
data class MaintenancePlanFilter(
    val companyId: UUID,
    val assetId: UUID? = null,
    val planStatus: PlanStatus? = null,
    val approvalStatus: ApprovalStatus? = null,
    val planType: MaintenancePlanType? = null,
    val maintenanceStrategy: MaintenanceStrategy? = null,
    val effectiveDateFrom: LocalDate? = null,
    val effectiveDateTo: LocalDate? = null,
    val reviewDateFrom: LocalDate? = null,
    val reviewDateTo: LocalDate? = null,
    val searchKeyword: String? = null
)

/**
 * 정비 계획 요약 DTO
 */
data class MaintenancePlanSummaryDto(
    val planId: UUID,
    val planName: String,
    val planCode: String,
    val assetId: UUID,
    val planType: MaintenancePlanType,
    val frequencyType: FrequencyType,
    val planStatus: PlanStatus,
    val approvalStatus: ApprovalStatus,
    val effectiveDate: LocalDate,
    val nextExecutionDate: LocalDate?,
    val completionRate: BigDecimal,
    val effectivenessScore: BigDecimal
)

/**
 * 정비 계획 통계 DTO
 */
data class MaintenancePlanStatisticsDto(
    val totalPlans: Long,
    val activePlans: Long,
    val pendingApprovalPlans: Long,
    val overdueReviewPlans: Long,
    val lowEffectivenessPlans: Long,
    val budgetRiskPlans: Long,
    val plansByType: Map<MaintenancePlanType, Long>,
    val plansByStrategy: Map<MaintenanceStrategy, Long>
)
/**
 * 
정비 작업 DTO
 */
data class MaintenanceTaskDto(
    val taskId: UUID,
    val companyId: UUID,
    val planId: UUID,
    val taskSequence: Int,
    val taskName: String,
    val taskDescription: String?,
    val taskType: TaskType,
    val taskInstructions: String?,
    val safetyPrecautions: String?,
    val qualityStandards: String?,
    val estimatedDurationMinutes: Int,
    val requiredSkillLevel: SkillLevel,
    val requiredTools: String?,
    val requiredParts: String?,
    val prerequisiteTasks: String?,
    val environmentalConditions: String?,
    val equipmentStateRequired: String?,
    val inspectionRequired: Boolean,
    val measurementRequired: Boolean,
    val documentationRequired: Boolean,
    val photoRequired: Boolean,
    val acceptanceCriteria: String?,
    val measurementPoints: String?,
    val toleranceSpecifications: String?,
    val isCritical: Boolean,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

/**
 * 정비 작업 생성 요청 DTO
 */
data class CreateMaintenanceTaskRequest(
    val companyId: UUID,
    val planId: UUID,
    val taskSequence: Int,
    val taskName: String,
    val taskDescription: String?,
    val taskType: TaskType,
    val taskInstructions: String?,
    val safetyPrecautions: String?,
    val qualityStandards: String?,
    val estimatedDurationMinutes: Int = 0,
    val requiredSkillLevel: SkillLevel = SkillLevel.BASIC,
    val requiredTools: String?,
    val requiredParts: String?,
    val prerequisiteTasks: String?,
    val environmentalConditions: String?,
    val equipmentStateRequired: String?,
    val inspectionRequired: Boolean = false,
    val measurementRequired: Boolean = false,
    val documentationRequired: Boolean = true,
    val photoRequired: Boolean = false,
    val acceptanceCriteria: String?,
    val measurementPoints: String?,
    val toleranceSpecifications: String?,
    val isCritical: Boolean = false,
    val createdBy: UUID?
)

/**
 * 정비 작업 실행 DTO
 */
data class MaintenanceTaskExecutionDto(
    val taskExecutionId: UUID,
    val executionId: UUID,
    val taskId: UUID,
    val taskSequence: Int,
    val taskName: String,
    val executionStatus: TaskExecutionStatus,
    val startedAt: LocalDateTime?,
    val completedAt: LocalDateTime?,
    val actualDurationMinutes: Int,
    val executedBy: UUID?,
    val executionNotes: String?,
    val qualityCheckPassed: Boolean,
    val qualityCheckNotes: String?,
    val measurementsTaken: String?,
    val photosTaken: String?,
    val partsUsed: String?,
    val toolsUsed: String?,
    val issuesFound: String?,
    val correctiveActions: String?,
    val taskCost: BigDecimal,
    val laborHours: BigDecimal,
    val materialCost: BigDecimal,
    val completionPercentage: BigDecimal,
    val requiresFollowUp: Boolean,
    val followUpNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

/**
 * 작업 실행 완료 요청 DTO
 */
data class CompleteTaskExecutionRequest(
    val executionNotes: String?,
    val qualityCheckPassed: Boolean = true,
    val qualityCheckNotes: String?,
    val measurementsTaken: String?,
    val photosTaken: String?,
    val partsUsed: String?,
    val toolsUsed: String?,
    val issuesFound: String?,
    val correctiveActions: String?,
    val taskCost: BigDecimal = BigDecimal.ZERO,
    val laborHours: BigDecimal = BigDecimal.ZERO,
    val materialCost: BigDecimal = BigDecimal.ZERO,
    val requiresFollowUp: Boolean = false,
    val followUpNotes: String?,
    val completedBy: UUID
)

/**
 * 작업 실행 통계 DTO
 */
data class TaskExecutionStatisticsDto(
    val totalTasks: Long,
    val completedTasks: Long,
    val pendingTasks: Long,
    val inProgressTasks: Long,
    val skippedTasks: Long,
    val failedTasks: Long,
    val completionPercentage: BigDecimal
)

/**
 * 정비 실행 생성 요청 DTO
 */
data class CreateMaintenanceExecutionRequest(
    val planId: UUID,
    val assetId: UUID,
    val scheduledDate: LocalDate,
    val assignedTo: UUID?,
    val priority: ExecutionPriority = ExecutionPriority.NORMAL,
    val executionNotes: String?,
    val estimatedDurationHours: BigDecimal = BigDecimal.ZERO
)

/**
 * 정비 실행 시작 요청 DTO
 */
data class StartMaintenanceExecutionRequest(
    val actualStartTime: LocalDateTime = LocalDateTime.now(),
    val startNotes: String?,
    val preExecutionChecklist: Map<String, Boolean>? = null
)

/**
 * 정비 실행 완료 요청 DTO
 */
data class CompleteMaintenanceExecutionRequest(
    val actualEndTime: LocalDateTime = LocalDateTime.now(),
    val completionNotes: String?,
    val actualCost: BigDecimal = BigDecimal.ZERO,
    val actualLaborHours: BigDecimal = BigDecimal.ZERO,
    val actualMaterialCost: BigDecimal = BigDecimal.ZERO,
    val qualityRating: BigDecimal = BigDecimal.ZERO,
    val effectivenessRating: BigDecimal = BigDecimal.ZERO,
    val issuesFound: String?,
    val correctiveActions: String?,
    val recommendationsForNextTime: String?,
    val postExecutionChecklist: Map<String, Boolean>? = null,
    val requiresFollowUp: Boolean = false,
    val followUpDate: LocalDate?,
    val followUpNotes: String?
)

/**
 * 정비 실행 필터 DTO
 */
data class MaintenanceExecutionFilter(
    val companyId: UUID,
    val assetId: UUID? = null,
    val planId: UUID? = null,
    val executionStatus: String? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val assignedTo: UUID? = null,
    val priority: ExecutionPriority? = null
)

/**
 * 다음 정비 일정 DTO
 */
data class NextMaintenanceScheduleDto(
    val planId: UUID,
    val planName: String,
    val assetId: UUID,
    val lastExecutionDate: LocalDate?,
    val nextScheduledDate: LocalDate,
    val daysUntilDue: Long,
    val frequencyType: FrequencyType,
    val frequencyInterval: Int,
    val isOverdue: Boolean,
    val calculationMethod: String,
    val calculationNotes: String?
)

/**
 * 정비 효과성 분석 DTO
 */
data class MaintenanceEffectivenessDto(
    val planId: UUID,
    val planName: String,
    val analysisStartDate: LocalDate,
    val analysisEndDate: LocalDate,
    val totalExecutions: Long,
    val completedExecutions: Long,
    val averageExecutionTime: BigDecimal,
    val totalCost: BigDecimal,
    val averageCostPerExecution: BigDecimal,
    val costTrend: String, // INCREASING, DECREASING, STABLE
    val qualityTrend: String, // IMPROVING, DECLINING, STABLE
    val averageQualityRating: BigDecimal,
    val averageEffectivenessRating: BigDecimal,
    val mtbfImprovement: BigDecimal, // Mean Time Between Failures improvement
    val availabilityImprovement: BigDecimal,
    val costSavings: BigDecimal,
    val recommendedActions: List<String>,
    val effectivenessScore: BigDecimal // Overall effectiveness score (0-100)
)

/**
 * 정비 실행 통계 DTO
 */
data class MaintenanceExecutionStatisticsDto(
    val totalExecutions: Long,
    val completedExecutions: Long,
    val inProgressExecutions: Long,
    val scheduledExecutions: Long,
    val overdueExecutions: Long,
    val cancelledExecutions: Long,
    val completionRate: BigDecimal,
    val onTimeCompletionRate: BigDecimal,
    val averageExecutionTime: BigDecimal,
    val totalCost: BigDecimal,
    val averageCostPerExecution: BigDecimal,
    val averageQualityRating: BigDecimal,
    val averageEffectivenessRating: BigDecimal,
    val executionsByStatus: Map<String, Long>,
    val executionsByPriority: Map<ExecutionPriority, Long>,
    val monthlyExecutionTrend: Map<String, Long>
)

/**
 * 정비 실행 대시보드 DTO
 */
data class MaintenanceExecutionDashboardDto(
    val statistics: MaintenanceExecutionStatisticsDto,
    val todayExecutions: List<PreventiveMaintenanceExecutionDto>,
    val overdueExecutions: List<PreventiveMaintenanceExecutionDto>,
    val inProgressExecutions: List<PreventiveMaintenanceExecutionDto>,
    val upcomingExecutions: List<PreventiveMaintenanceExecutionDto>,
    val recentCompletedExecutions: List<PreventiveMaintenanceExecutionDto>,
    val alertsAndNotifications: List<MaintenanceAlertDto>
)

/**
 * 정비 알림 DTO
 */
data class MaintenanceAlertDto(
    val alertId: UUID,
    val alertType: AlertType,
    val severity: AlertSeverity,
    val title: String,
    val message: String,
    val relatedExecutionId: UUID?,
    val relatedAssetId: UUID?,
    val createdAt: LocalDateTime,
    val isRead: Boolean = false
)

/**
 * 실행 우선순위 열거형
 */
enum class ExecutionPriority {
    LOW,        // 낮음
    NORMAL,     // 보통
    HIGH,       // 높음
    URGENT,     // 긴급
    CRITICAL    // 중요
}

/**
 * 알림 유형 열거형
 */
enum class AlertType {
    OVERDUE_MAINTENANCE,        // 지연된 정비
    UPCOMING_MAINTENANCE,       // 예정된 정비
    MAINTENANCE_COMPLETED,      // 정비 완료
    MAINTENANCE_FAILED,         // 정비 실패
    QUALITY_ISSUE,             // 품질 문제
    COST_OVERRUN,              // 비용 초과
    SCHEDULE_CONFLICT          // 일정 충돌
}

/**
 * 알림 심각도 열거형
 */
enum class AlertSeverity {
    INFO,       // 정보
    WARNING,    // 경고
    ERROR,      // 오류
    CRITICAL    // 중요
}