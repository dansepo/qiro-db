package com.qiro.domain.workorder.dto

import com.fasterxml.jackson.databind.JsonNode
import com.qiro.domain.workorder.entity.WorkOrderPartUsage
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 부품 사용 내역 DTO
 */
data class WorkOrderPartUsageDto(
    val usageId: UUID,
    val companyId: UUID,
    val workOrderId: UUID,
    val materialUsageId: UUID,
    
    // 사용 세부 정보
    val usageDate: LocalDateTime,
    val usedBy: UUID,
    val usedByName: String? = null,
    val usageLocation: String? = null,
    
    // 수량 정보
    val quantityUsed: BigDecimal,
    val unitId: UUID,
    val unitName: String? = null,
    
    // 배치/시리얼 추적
    val batchNumber: String? = null,
    val serialNumbers: JsonNode? = null,
    
    // 품질 정보
    val qualityStatus: WorkOrderPartUsage.QualityStatus,
    val qualityNotes: String? = null,
    
    // 사용 목적 및 위치
    val usagePurpose: String? = null,
    val installationLocation: String? = null,
    
    // 폐기/반품 정보
    val wasteQuantity: BigDecimal,
    val wasteReason: String? = null,
    val returnQuantity: BigDecimal,
    val returnReason: String? = null,
    
    // 비용 정보
    val unitCost: BigDecimal,
    val totalCost: BigDecimal,
    
    // 승인 정보
    val approvedBy: UUID? = null,
    val approvedByName: String? = null,
    val approvalDate: LocalDateTime? = null,
    val approvalNotes: String? = null,
    
    // 상태
    val usageStatus: WorkOrderPartUsage.UsageStatus,
    
    // 계산된 필드
    val actualUsedQuantity: BigDecimal,
    val isApproved: Boolean,
    val hasBatchTracking: Boolean,
    val hasSerialTracking: Boolean,
    
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
        fun from(entity: WorkOrderPartUsage): WorkOrderPartUsageDto {
            return WorkOrderPartUsageDto(
                usageId = entity.usageId,
                companyId = entity.companyId,
                workOrderId = entity.workOrderId,
                materialUsageId = entity.materialUsageId,
                usageDate = entity.usageDate,
                usedBy = entity.usedBy,
                usageLocation = entity.usageLocation,
                quantityUsed = entity.quantityUsed,
                unitId = entity.unitId,
                batchNumber = entity.batchNumber,
                serialNumbers = entity.serialNumbers,
                qualityStatus = entity.qualityStatus,
                qualityNotes = entity.qualityNotes,
                usagePurpose = entity.usagePurpose,
                installationLocation = entity.installationLocation,
                wasteQuantity = entity.wasteQuantity,
                wasteReason = entity.wasteReason,
                returnQuantity = entity.returnQuantity,
                returnReason = entity.returnReason,
                unitCost = entity.unitCost,
                totalCost = entity.totalCost,
                approvedBy = entity.approvedBy,
                approvalDate = entity.approvalDate,
                approvalNotes = entity.approvalNotes,
                usageStatus = entity.usageStatus,
                actualUsedQuantity = entity.getActualUsedQuantity(),
                isApproved = entity.isApproved(),
                hasBatchTracking = entity.hasBatchTracking(),
                hasSerialTracking = entity.hasSerialTracking(),
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                createdBy = entity.createdBy,
                updatedBy = entity.updatedBy
            )
        }
    }
}

/**
 * 부품 사용 내역 생성 요청 DTO
 */
data class CreatePartUsageRequest(
    val workOrderId: UUID,
    val materialUsageId: UUID,
    val usedBy: UUID,
    val usageLocation: String? = null,
    val quantityUsed: BigDecimal,
    val unitId: UUID,
    val batchNumber: String? = null,
    val serialNumbers: JsonNode? = null,
    val qualityStatus: WorkOrderPartUsage.QualityStatus = WorkOrderPartUsage.QualityStatus.GOOD,
    val qualityNotes: String? = null,
    val usagePurpose: String? = null,
    val installationLocation: String? = null,
    val wasteQuantity: BigDecimal = BigDecimal.ZERO,
    val wasteReason: String? = null,
    val returnQuantity: BigDecimal = BigDecimal.ZERO,
    val returnReason: String? = null,
    val unitCost: BigDecimal = BigDecimal.ZERO
)

/**
 * 부품 사용 내역 수정 요청 DTO
 */
data class UpdatePartUsageRequest(
    val usageLocation: String? = null,
    val qualityStatus: WorkOrderPartUsage.QualityStatus? = null,
    val qualityNotes: String? = null,
    val usagePurpose: String? = null,
    val installationLocation: String? = null,
    val wasteQuantity: BigDecimal? = null,
    val wasteReason: String? = null,
    val returnQuantity: BigDecimal? = null,
    val returnReason: String? = null,
    val usageStatus: WorkOrderPartUsage.UsageStatus? = null
)

/**
 * 부품 사용 승인 요청 DTO
 */
data class ApprovePartUsageRequest(
    val approvalNotes: String? = null
)

/**
 * 부품 사용 내역 검색 필터 DTO
 */
data class PartUsageFilter(
    val workOrderId: UUID? = null,
    val usedBy: UUID? = null,
    val usageStatus: WorkOrderPartUsage.UsageStatus? = null,
    val qualityStatus: WorkOrderPartUsage.QualityStatus? = null,
    val usageDateFrom: LocalDateTime? = null,
    val usageDateTo: LocalDateTime? = null,
    val batchNumber: String? = null,
    val isApproved: Boolean? = null
)

/**
 * 부품 사용 통계 DTO
 */
data class PartUsageStatistics(
    val totalUsages: Long,
    val totalQuantityUsed: BigDecimal,
    val totalCost: BigDecimal,
    val totalWasteQuantity: BigDecimal,
    val totalReturnQuantity: BigDecimal,
    val averageUnitCost: BigDecimal,
    val usagesByStatus: Map<WorkOrderPartUsage.UsageStatus, Long>,
    val usagesByQuality: Map<WorkOrderPartUsage.QualityStatus, Long>,
    val approvalRate: BigDecimal,
    val wasteRate: BigDecimal,
    val returnRate: BigDecimal
)