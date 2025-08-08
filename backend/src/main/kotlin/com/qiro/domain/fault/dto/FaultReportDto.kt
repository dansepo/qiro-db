package com.qiro.domain.fault.dto

import com.qiro.domain.fault.entity.*
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 신고 DTO
 */
data class FaultReportDto(
    val id: UUID,
    val companyId: UUID,
    val buildingId: UUID? = null,
    val unitId: UUID? = null,
    val assetId: UUID? = null,
    val categoryId: UUID,
    val reportNumber: String,
    val reportTitle: String,
    val reportDescription: String,
    val reporterType: ReporterType,
    val reporterName: String? = null,
    val reporterContact: Map<String, String>? = null,
    val reporterUnitId: UUID? = null,
    val anonymousReport: Boolean = false,
    val faultType: FaultType,
    val faultSeverity: FaultSeverity,
    val faultUrgency: FaultUrgency,
    val faultPriority: FaultPriority,
    val faultLocation: String? = null,
    val affectedAreas: List<String>? = null,
    val environmentalConditions: String? = null,
    val safetyImpact: ImpactLevel = ImpactLevel.NONE,
    val operationalImpact: ImpactLevel = ImpactLevel.MINOR,
    val residentImpact: ImpactLevel = ImpactLevel.MINOR,
    val estimatedAffectedUnits: Int = 0,
    val faultOccurredAt: LocalDateTime? = null,
    val reportedAt: LocalDateTime,
    val firstResponseDue: LocalDateTime? = null,
    val resolutionDue: LocalDateTime? = null,
    val reportStatus: ReportStatus,
    val resolutionStatus: ResolutionStatus,
    val assignedTo: UUID? = null,
    val assignedTeam: String? = null,
    val contractorId: UUID? = null,
    val escalationLevel: Int = 1,
    val firstResponseAt: LocalDateTime? = null,
    val acknowledgedAt: LocalDateTime? = null,
    val acknowledgedBy: UUID? = null,
    val workStartedAt: LocalDateTime? = null,
    val resolvedAt: LocalDateTime? = null,
    val resolvedBy: UUID? = null,
    val resolutionMethod: String? = null,
    val resolutionDescription: String? = null,
    val estimatedRepairCost: BigDecimal = BigDecimal.ZERO,
    val actualRepairCost: BigDecimal = BigDecimal.ZERO,
    val resolutionQualityRating: BigDecimal = BigDecimal.ZERO,
    val reporterSatisfactionRating: BigDecimal = BigDecimal.ZERO,
    val initialPhotos: List<String>? = null,
    val resolutionPhotos: List<String>? = null,
    val supportingDocuments: List<String>? = null,
    val communicationLog: List<Map<String, Any>>? = null,
    val internalNotes: String? = null,
    val followUpRequired: Boolean = false,
    val followUpDate: LocalDateTime? = null,
    val followUpNotes: String? = null,
    val isRecurringIssue: Boolean = false,
    val createdAt: LocalDateTime? = null,
    val updatedAt: LocalDateTime? = null,
    val createdBy: UUID? = null,
    val updatedBy: UUID? = null,
    
    // 추가 정보 (조인된 데이터)
    val buildingName: String? = null,
    val unitNumber: String? = null,
    val categoryName: String? = null,
    val assignedToName: String? = null,
    val attachments: List<AttachmentDto>? = null
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(entity: FaultReport): FaultReportDto {
            return FaultReportDto(
                id = entity.id,
                companyId = entity.companyId,
                buildingId = entity.buildingId,
                unitId = entity.unitId,
                assetId = entity.assetId,
                categoryId = entity.categoryId,
                reportNumber = entity.reportNumber,
                reportTitle = entity.reportTitle,
                reportDescription = entity.reportDescription,
                reporterType = entity.reporterType,
                reporterName = entity.reporterName,
                reporterContact = entity.reporterContact,
                reporterUnitId = entity.reporterUnitId,
                anonymousReport = entity.anonymousReport,
                faultType = entity.faultType,
                faultSeverity = entity.faultSeverity,
                faultUrgency = entity.faultUrgency,
                faultPriority = entity.faultPriority,
                faultLocation = entity.faultLocation,
                affectedAreas = entity.affectedAreas,
                environmentalConditions = entity.environmentalConditions,
                safetyImpact = entity.safetyImpact,
                operationalImpact = entity.operationalImpact,
                residentImpact = entity.residentImpact,
                estimatedAffectedUnits = entity.estimatedAffectedUnits,
                faultOccurredAt = entity.faultOccurredAt,
                reportedAt = entity.reportedAt,
                firstResponseDue = entity.firstResponseDue,
                resolutionDue = entity.resolutionDue,
                reportStatus = entity.reportStatus,
                resolutionStatus = entity.resolutionStatus,
                assignedTo = entity.assignedTo,
                assignedTeam = entity.assignedTeam,
                contractorId = entity.contractorId,
                escalationLevel = entity.escalationLevel,
                firstResponseAt = entity.firstResponseAt,
                acknowledgedAt = entity.acknowledgedAt,
                acknowledgedBy = entity.acknowledgedBy,
                workStartedAt = entity.workStartedAt,
                resolvedAt = entity.resolvedAt,
                resolvedBy = entity.resolvedBy,
                resolutionMethod = entity.resolutionMethod,
                resolutionDescription = entity.resolutionDescription,
                estimatedRepairCost = entity.estimatedRepairCost,
                actualRepairCost = entity.actualRepairCost,
                resolutionQualityRating = entity.resolutionQualityRating,
                reporterSatisfactionRating = entity.reporterSatisfactionRating,
                initialPhotos = entity.initialPhotos,
                resolutionPhotos = entity.resolutionPhotos,
                supportingDocuments = entity.supportingDocuments,
                communicationLog = entity.communicationLog,
                internalNotes = entity.internalNotes,
                followUpRequired = entity.followUpRequired,
                followUpDate = entity.followUpDate,
                followUpNotes = entity.followUpNotes,
                isRecurringIssue = entity.isRecurringIssue,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                createdBy = entity.createdBy,
                updatedBy = entity.updatedBy
            )
        }
    }

    /**
     * 긴급 신고 여부
     */
    fun isUrgent(): Boolean {
        return faultUrgency == FaultUrgency.CRITICAL || faultPriority == FaultPriority.EMERGENCY
    }

    /**
     * 응답 시간 초과 여부
     */
    fun isResponseOverdue(): Boolean {
        return firstResponseDue?.isBefore(LocalDateTime.now()) == true && firstResponseAt == null
    }

    /**
     * 해결 시간 초과 여부
     */
    fun isResolutionOverdue(): Boolean {
        return resolutionDue?.isBefore(LocalDateTime.now()) == true && resolvedAt == null
    }

    /**
     * 응답 시간 계산 (시간 단위)
     */
    fun getResponseTimeHours(): Double? {
        return if (firstResponseAt != null) {
            java.time.Duration.between(reportedAt, firstResponseAt).toMinutes() / 60.0
        } else null
    }

    /**
     * 해결 시간 계산 (시간 단위)
     */
    fun getResolutionTimeHours(): Double? {
        return if (resolvedAt != null) {
            java.time.Duration.between(reportedAt, resolvedAt).toMinutes() / 60.0
        } else null
    }
}

/**
 * 고장 신고 생성 요청 DTO
 */
data class CreateFaultReportRequest(
    @field:NotNull(message = "회사 ID는 필수입니다")
    val companyId: UUID,
    val buildingId: UUID? = null,
    val unitId: UUID? = null,
    val assetId: UUID? = null,
    @field:NotNull(message = "분류 ID는 필수입니다")
    val categoryId: UUID,
    @field:NotBlank(message = "신고 제목은 필수입니다")
    @field:Size(max = 200, message = "신고 제목은 200자 이하여야 합니다")
    val reportTitle: String,
    @field:NotBlank(message = "신고 설명은 필수입니다")
    val reportDescription: String,
    @field:NotNull(message = "신고자 유형은 필수입니다")
    val reporterType: ReporterType,
    @field:Size(max = 100, message = "신고자 이름은 100자 이하여야 합니다")
    val reporterName: String? = null,
    val reporterContact: Map<String, String>? = null,
    val reporterUnitId: UUID? = null,
    val anonymousReport: Boolean = false,
    @field:NotNull(message = "고장 유형은 필수입니다")
    val faultType: FaultType,
    @field:NotNull(message = "고장 심각도는 필수입니다")
    val faultSeverity: FaultSeverity,
    val faultLocation: String? = null,
    val affectedAreas: List<String>? = null,
    val environmentalConditions: String? = null,
    val safetyImpact: ImpactLevel = ImpactLevel.NONE,
    val operationalImpact: ImpactLevel = ImpactLevel.MINOR,
    val residentImpact: ImpactLevel = ImpactLevel.MINOR,
    @field:Min(value = 0, message = "예상 영향 세대 수는 0 이상이어야 합니다")
    val estimatedAffectedUnits: Int = 0,
    val faultOccurredAt: LocalDateTime? = null,
    val initialPhotos: List<String>? = null,
    val supportingDocuments: List<String>? = null
)

/**
 * 고장 신고 업데이트 요청 DTO
 */
data class UpdateFaultReportRequest(
    val reportTitle: String? = null,
    val reportDescription: String? = null,
    val faultSeverity: FaultSeverity? = null,
    val faultLocation: String? = null,
    val affectedAreas: List<String>? = null,
    val environmentalConditions: String? = null,
    val safetyImpact: ImpactLevel? = null,
    val operationalImpact: ImpactLevel? = null,
    val residentImpact: ImpactLevel? = null,
    val estimatedAffectedUnits: Int? = null,
    val assignedTo: UUID? = null,
    val assignedTeam: String? = null,
    val contractorId: UUID? = null,
    val internalNotes: String? = null,
    val followUpRequired: Boolean? = null,
    val followUpDate: LocalDateTime? = null,
    val followUpNotes: String? = null
)

/**
 * 고장 신고 상태 업데이트 요청 DTO
 */
data class UpdateFaultReportStatusRequest(
    val reportStatus: ReportStatus,
    val resolutionStatus: ResolutionStatus? = null,
    val statusNotes: String? = null
)

/**
 * 고장 신고 해결 완료 요청 DTO
 */
data class CompleteFaultReportRequest(
    val resolutionMethod: String,
    val resolutionDescription: String,
    val actualRepairCost: BigDecimal? = null,
    val resolutionPhotos: List<String>? = null,
    val followUpRequired: Boolean = false,
    val followUpDate: LocalDateTime? = null,
    val followUpNotes: String? = null
)

/**
 * 고장 신고 검색 필터 DTO
 */
data class FaultReportFilter(
    val companyId: UUID,
    val buildingId: UUID? = null,
    val unitId: UUID? = null,
    val categoryId: UUID? = null,
    val reportStatus: ReportStatus? = null,
    val resolutionStatus: ResolutionStatus? = null,
    val faultPriority: FaultPriority? = null,
    val faultUrgency: FaultUrgency? = null,
    val faultType: FaultType? = null,
    val assignedTo: UUID? = null,
    val reporterType: ReporterType? = null,
    val dateFrom: LocalDateTime? = null,
    val dateTo: LocalDateTime? = null,
    val isOverdue: Boolean? = null,
    val isUrgent: Boolean? = null,
    val searchKeyword: String? = null
)

/**
 * 신고자 이력 검색 필터 DTO
 */
data class ReporterHistoryFilter(
    val companyId: UUID,
    val reporterType: ReporterType,
    val reporterName: String? = null,
    val reporterUnitId: UUID? = null,
    val reporterContact: String? = null
)

/**
 * 신고자별 통계 DTO
 */
data class ReporterStatisticsDto(
    val reporterType: ReporterType,
    val reporterName: String?,
    val reporterUnitId: UUID?,
    val unitNumber: String?,
    val totalReports: Long,
    val completedReports: Long,
    val pendingReports: Long,
    val urgentReports: Long,
    val avgResponseTimeHours: Double,
    val avgResolutionTimeHours: Double,
    val satisfactionRating: BigDecimal,
    val lastReportDate: LocalDateTime?
)

/**
 * 고장 신고 전체 통계 DTO
 */
data class FaultReportStatisticsDto(
    val totalReports: Long,
    val completedReports: Long,
    val pendingReports: Long,
    val overdueReports: Long,
    val urgentReports: Long,
    val avgResponseTimeHours: Double,
    val avgResolutionTimeHours: Double,
    val completionRate: Double,
    val onTimeCompletionRate: Double,
    val reportsByStatus: Map<String, Long>,
    val reportsByPriority: Map<String, Long>,
    val reportsByType: Map<String, Long>,
    val reportsByCategory: Map<String, Long>
)

/**
 * 응답 시간 통계 DTO
 */
data class ResponseTimeStatisticsDto(
    val avgResponseTimeHours: Double,
    val medianResponseTimeHours: Double,
    val minResponseTimeHours: Double,
    val maxResponseTimeHours: Double,
    val responseTimeByPriority: Map<String, Double>,
    val onTimeResponseRate: Double,
    val overdueResponseCount: Long,
    val totalResponseCount: Long
)

/**
 * 고장 유형별 통계 DTO
 */
data class FaultTypeStatisticsDto(
    val faultType: FaultType,
    val totalReports: Long,
    val completedReports: Long,
    val avgResolutionTimeHours: Double,
    val avgRepairCost: BigDecimal,
    val recurringIssueCount: Long,
    val satisfactionRating: BigDecimal
)

/**
 * 월별 추이 DTO
 */
data class MonthlyTrendDto(
    val year: Int,
    val month: Int,
    val totalReports: Long,
    val completedReports: Long,
    val urgentReports: Long,
    val avgResponseTimeHours: Double,
    val avgResolutionTimeHours: Double,
    val totalRepairCost: BigDecimal
)