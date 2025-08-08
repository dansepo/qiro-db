package com.qiro.domain.workorder.dto

import com.fasterxml.jackson.databind.JsonNode
import com.qiro.domain.workorder.entity.WorkOrderLaborTracking
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 인력 시간 추적 DTO
 */
data class WorkOrderLaborTrackingDto(
    val laborTrackingId: UUID,
    val companyId: UUID,
    val workOrderId: UUID,
    val assignmentId: UUID,
    
    // 작업자 정보
    val workerId: UUID,
    val workerName: String? = null,
    val workerRole: WorkOrderLaborTracking.WorkerRole,
    val skillLevel: WorkOrderLaborTracking.SkillLevel,
    
    // 시간 추적
    val workDate: LocalDate,
    val startTime: LocalDateTime? = null,
    val endTime: LocalDateTime? = null,
    val breakDurationMinutes: Int,
    val actualWorkHours: BigDecimal,
    
    // 작업 내용
    val workDescription: String? = null,
    val workLocation: String? = null,
    val workPhase: WorkOrderLaborTracking.WorkPhase? = null,
    
    // 비용 정보
    val hourlyRate: BigDecimal,
    val overtimeRate: BigDecimal,
    val regularHours: BigDecimal,
    val overtimeHours: BigDecimal,
    val totalLaborCost: BigDecimal,
    
    // 성과 지표
    val productivityScore: BigDecimal,
    val qualityScore: BigDecimal,
    val safetyScore: BigDecimal,
    
    // 도구 및 장비 사용
    val toolsUsed: JsonNode? = null,
    val equipmentUsed: JsonNode? = null,
    
    // 상태 및 승인
    val trackingStatus: WorkOrderLaborTracking.TrackingStatus,
    val approvedBy: UUID? = null,
    val approvedByName: String? = null,
    val approvalDate: LocalDateTime? = null,
    val approvalNotes: String? = null,
    
    // 계산된 필드
    val totalWorkHours: BigDecimal,
    val hasOvertime: Boolean,
    val isApproved: Boolean,
    val averagePerformanceScore: BigDecimal,
    val costEfficiency: BigDecimal,
    
    // 메타데이터
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID? = null,
    val updatedBy: UUID? = null
) {
    companion object {
        /**
         * 엔티티를 DTO로 변환
         */
        fun from(entity: WorkOrderLaborTracking): WorkOrderLaborTrackingDto {
            return WorkOrderLaborTrackingDto(
                laborTrackingId = entity.laborTrackingId,
                companyId = entity.companyId,
                workOrderId = entity.workOrderId,
                assignmentId = entity.assignmentId,
                workerId = entity.workerId,
                workerRole = entity.workerRole,
                skillLevel = entity.skillLevel,
                workDate = entity.workDate,
                startTime = entity.startTime,
                endTime = entity.endTime,
                breakDurationMinutes = entity.breakDurationMinutes,
                actualWorkHours = entity.actualWorkHours,
                workDescription = entity.workDescription,
                workLocation = entity.workLocation,
                workPhase = entity.workPhase,
                hourlyRate = entity.hourlyRate,
                overtimeRate = entity.overtimeRate,
                regularHours = entity.regularHours,
                overtimeHours = entity.overtimeHours,
                totalLaborCost = entity.totalLaborCost,
                productivityScore = entity.productivityScore,
                qualityScore = entity.qualityScore,
                safetyScore = entity.safetyScore,
                toolsUsed = entity.toolsUsed,
                equipmentUsed = entity.equipmentUsed,
                trackingStatus = entity.trackingStatus,
                approvedBy = entity.approvedBy,
                approvalDate = entity.approvalDate,
                approvalNotes = entity.approvalNotes,
                totalWorkHours = entity.getTotalWorkHours(),
                hasOvertime = entity.hasOvertime(),
                isApproved = entity.isApproved(),
                averagePerformanceScore = entity.getAveragePerformanceScore(),
                costEfficiency = entity.getCostEfficiency(),
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                createdBy = entity.createdBy,
                updatedBy = entity.updatedBy
            )
        }
    }
}

/**
 * 인력 시간 추적 생성 요청 DTO
 */
data class CreateLaborTrackingRequest(
    val workOrderId: UUID,
    val assignmentId: UUID,
    val workerId: UUID,
    val workerRole: WorkOrderLaborTracking.WorkerRole,
    val skillLevel: WorkOrderLaborTracking.SkillLevel = WorkOrderLaborTracking.SkillLevel.BASIC,
    val workDate: LocalDate,
    val startTime: LocalDateTime? = null,
    val endTime: LocalDateTime? = null,
    val breakDurationMinutes: Int = 0,
    val actualWorkHours: BigDecimal,
    val workDescription: String? = null,
    val workLocation: String? = null,
    val workPhase: WorkOrderLaborTracking.WorkPhase? = null,
    val hourlyRate: BigDecimal = BigDecimal.ZERO,
    val overtimeRate: BigDecimal = BigDecimal.ZERO,
    val regularHours: BigDecimal = BigDecimal.ZERO,
    val overtimeHours: BigDecimal = BigDecimal.ZERO,
    val productivityScore: BigDecimal = BigDecimal.ZERO,
    val qualityScore: BigDecimal = BigDecimal.ZERO,
    val safetyScore: BigDecimal = BigDecimal.ZERO,
    val toolsUsed: JsonNode? = null,
    val equipmentUsed: JsonNode? = null
)

/**
 * 인력 시간 추적 수정 요청 DTO
 */
data class UpdateLaborTrackingRequest(
    val startTime: LocalDateTime? = null,
    val endTime: LocalDateTime? = null,
    val breakDurationMinutes: Int? = null,
    val actualWorkHours: BigDecimal? = null,
    val workDescription: String? = null,
    val workLocation: String? = null,
    val workPhase: WorkOrderLaborTracking.WorkPhase? = null,
    val regularHours: BigDecimal? = null,
    val overtimeHours: BigDecimal? = null,
    val productivityScore: BigDecimal? = null,
    val qualityScore: BigDecimal? = null,
    val safetyScore: BigDecimal? = null,
    val toolsUsed: JsonNode? = null,
    val equipmentUsed: JsonNode? = null,
    val trackingStatus: WorkOrderLaborTracking.TrackingStatus? = null
)

/**
 * 인력 시간 추적 승인 요청 DTO
 */
data class ApproveLaborTrackingRequest(
    val approvalNotes: String? = null
)

/**
 * 인력 시간 추적 검색 필터 DTO
 */
data class LaborTrackingFilter(
    val workOrderId: UUID? = null,
    val workerId: UUID? = null,
    val workerRole: WorkOrderLaborTracking.WorkerRole? = null,
    val skillLevel: WorkOrderLaborTracking.SkillLevel? = null,
    val workPhase: WorkOrderLaborTracking.WorkPhase? = null,
    val trackingStatus: WorkOrderLaborTracking.TrackingStatus? = null,
    val workDateFrom: LocalDate? = null,
    val workDateTo: LocalDate? = null,
    val isApproved: Boolean? = null,
    val hasOvertime: Boolean? = null
)

/**
 * 인력 시간 통계 DTO
 */
data class LaborTrackingStatistics(
    val totalRecords: Long,
    val totalWorkHours: BigDecimal,
    val totalRegularHours: BigDecimal,
    val totalOvertimeHours: BigDecimal,
    val totalLaborCost: BigDecimal,
    val averageHourlyRate: BigDecimal,
    val averageProductivityScore: BigDecimal,
    val averageQualityScore: BigDecimal,
    val averageSafetyScore: BigDecimal,
    val overtimePercentage: BigDecimal,
    val approvalRate: BigDecimal,
    val trackingsByStatus: Map<WorkOrderLaborTracking.TrackingStatus, Long>,
    val trackingsByRole: Map<WorkOrderLaborTracking.WorkerRole, Long>,
    val trackingsBySkillLevel: Map<WorkOrderLaborTracking.SkillLevel, Long>
)

/**
 * 작업자별 성과 요약 DTO
 */
data class WorkerPerformanceSummary(
    val workerId: UUID,
    val workerName: String? = null,
    val totalWorkHours: BigDecimal,
    val totalLaborCost: BigDecimal,
    val averageHourlyRate: BigDecimal,
    val averageProductivityScore: BigDecimal,
    val averageQualityScore: BigDecimal,
    val averageSafetyScore: BigDecimal,
    val overtimeHours: BigDecimal,
    val overtimePercentage: BigDecimal,
    val completedTasks: Long,
    val approvalRate: BigDecimal,
    val costEfficiency: BigDecimal
)