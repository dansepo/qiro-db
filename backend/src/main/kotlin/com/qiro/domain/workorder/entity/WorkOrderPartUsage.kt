package com.qiro.domain.workorder.entity

import com.fasterxml.jackson.databind.JsonNode
import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 부품 사용 내역 엔티티
 * 부품 사용의 상세 추적 및 관리
 */
@Entity
@Table(
    name = "work_order_part_usage",
    schema = "bms",
    indexes = [
        Index(name = "idx_part_usage_work_order", columnList = "workOrderId"),
        Index(name = "idx_part_usage_material", columnList = "materialUsageId"),
        Index(name = "idx_part_usage_date", columnList = "usageDate"),
        Index(name = "idx_part_usage_used_by", columnList = "usedBy"),
        Index(name = "idx_part_usage_status", columnList = "usageStatus")
    ]
)
data class WorkOrderPartUsage(
    @Id
    @Column(name = "usage_id")
    val usageId: UUID = UUID.randomUUID(),
    
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,
    
    @Column(name = "work_order_id", nullable = false)
    val workOrderId: UUID,
    
    @Column(name = "material_usage_id", nullable = false)
    val materialUsageId: UUID,
    
    // 사용 세부 정보
    @Column(name = "usage_date", nullable = false)
    val usageDate: LocalDateTime = LocalDateTime.now(),
    
    @Column(name = "used_by", nullable = false)
    val usedBy: UUID,
    
    @Column(name = "usage_location")
    val usageLocation: String? = null,
    
    // 수량 정보
    @Column(name = "quantity_used", nullable = false, precision = 10, scale = 3)
    val quantityUsed: BigDecimal,
    
    @Column(name = "unit_id", nullable = false)
    val unitId: UUID,
    
    // 배치/시리얼 추적
    @Column(name = "batch_number", length = 50)
    val batchNumber: String? = null,
    
    @Column(name = "serial_numbers", columnDefinition = "jsonb")
    val serialNumbers: JsonNode? = null,
    
    // 품질 정보
    @Enumerated(EnumType.STRING)
    @Column(name = "quality_status", length = 20)
    val qualityStatus: QualityStatus = QualityStatus.GOOD,
    
    @Column(name = "quality_notes", columnDefinition = "TEXT")
    val qualityNotes: String? = null,
    
    // 사용 목적 및 위치
    @Column(name = "usage_purpose", columnDefinition = "TEXT")
    val usagePurpose: String? = null,
    
    @Column(name = "installation_location", columnDefinition = "TEXT")
    val installationLocation: String? = null,
    
    // 폐기/반품 정보
    @Column(name = "waste_quantity", precision = 10, scale = 3)
    val wasteQuantity: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "waste_reason", columnDefinition = "TEXT")
    val wasteReason: String? = null,
    
    @Column(name = "return_quantity", precision = 10, scale = 3)
    val returnQuantity: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "return_reason", columnDefinition = "TEXT")
    val returnReason: String? = null,
    
    // 비용 정보
    @Column(name = "unit_cost", precision = 12, scale = 2)
    val unitCost: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_cost", precision = 12, scale = 2)
    val totalCost: BigDecimal = BigDecimal.ZERO,
    
    // 승인 정보
    @Column(name = "approved_by")
    val approvedBy: UUID? = null,
    
    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,
    
    @Column(name = "approval_notes", columnDefinition = "TEXT")
    val approvalNotes: String? = null,
    
    // 상태
    @Enumerated(EnumType.STRING)
    @Column(name = "usage_status", length = 20)
    val usageStatus: UsageStatus = UsageStatus.USED
    
) : BaseEntity() {
    
    /**
     * 품질 상태 열거형
     */
    enum class QualityStatus {
        GOOD,           // 양호
        DAMAGED,        // 손상됨
        DEFECTIVE,      // 결함
        EXPIRED,        // 만료됨
        RETURNED        // 반품됨
    }
    
    /**
     * 사용 상태 열거형
     */
    enum class UsageStatus {
        USED,           // 사용됨
        PARTIALLY_USED, // 부분 사용
        RETURNED,       // 반품됨
        WASTED,         // 폐기됨
        CANCELLED       // 취소됨
    }
    
    /**
     * 실제 사용된 수량 계산 (사용량 - 폐기량 - 반품량)
     */
    fun getActualUsedQuantity(): BigDecimal {
        return quantityUsed.subtract(wasteQuantity).subtract(returnQuantity)
    }
    
    /**
     * 승인 여부 확인
     */
    fun isApproved(): Boolean {
        return approvedBy != null && approvalDate != null
    }
    
    /**
     * 배치 추적 여부 확인
     */
    fun hasBatchTracking(): Boolean {
        return !batchNumber.isNullOrBlank()
    }
    
    /**
     * 시리얼 추적 여부 확인
     */
    fun hasSerialTracking(): Boolean {
        return serialNumbers != null && serialNumbers.isArray && serialNumbers.size() > 0
    }
}