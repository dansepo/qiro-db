package com.qiro.domain.workorder.entity

import com.fasterxml.jackson.databind.JsonNode
import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 재고 차감 로그 엔티티
 * 부품 사용에 따른 재고 자동 차감 이력 관리
 */
@Entity
@Table(
    name = "inventory_deduction_log",
    schema = "bms",
    indexes = [
        Index(name = "idx_deduction_work_order", columnList = "workOrderId"),
        Index(name = "idx_deduction_material", columnList = "materialId"),
        Index(name = "idx_deduction_location", columnList = "locationId"),
        Index(name = "idx_deduction_date", columnList = "deductionDate"),
        Index(name = "idx_deduction_type", columnList = "deductionType"),
        Index(name = "idx_deduction_status", columnList = "deductionStatus")
    ]
)
data class InventoryDeductionLog(
    @Id
    @Column(name = "deduction_id")
    val deductionId: UUID = UUID.randomUUID(),
    
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,
    
    // 연관 정보
    @Column(name = "work_order_id", nullable = false)
    val workOrderId: UUID,
    
    @Column(name = "material_usage_id", nullable = false)
    val materialUsageId: UUID,
    
    @Column(name = "part_usage_id", nullable = false)
    val partUsageId: UUID,
    
    // 재고 정보
    @Column(name = "material_id", nullable = false)
    val materialId: UUID,
    
    @Column(name = "location_id", nullable = false)
    val locationId: UUID,
    
    // 차감 정보
    @Column(name = "deduction_date", nullable = false)
    val deductionDate: LocalDateTime = LocalDateTime.now(),
    
    @Column(name = "quantity_deducted", nullable = false, precision = 15, scale = 3)
    val quantityDeducted: BigDecimal,
    
    @Column(name = "unit_id", nullable = false)
    val unitId: UUID,
    
    // 재고 상태 (차감 전/후)
    @Column(name = "stock_before", nullable = false, precision = 15, scale = 3)
    val stockBefore: BigDecimal,
    
    @Column(name = "stock_after", nullable = false, precision = 15, scale = 3)
    val stockAfter: BigDecimal,
    
    // 배치/시리얼 정보
    @Column(name = "batch_number", length = 50)
    val batchNumber: String? = null,
    
    @Column(name = "serial_numbers", columnDefinition = "jsonb")
    val serialNumbers: JsonNode? = null,
    
    // 차감 유형
    @Enumerated(EnumType.STRING)
    @Column(name = "deduction_type", length = 20)
    val deductionType: DeductionType = DeductionType.WORK_ORDER,
    
    @Column(name = "deduction_reason", columnDefinition = "TEXT")
    val deductionReason: String? = null,
    
    // 자동/수동 구분
    @Column(name = "is_automatic", nullable = false)
    val isAutomatic: Boolean = true,
    
    @Column(name = "processed_by")
    val processedBy: UUID? = null,
    
    // 상태
    @Enumerated(EnumType.STRING)
    @Column(name = "deduction_status", length = 20)
    val deductionStatus: DeductionStatus = DeductionStatus.COMPLETED
    
) : BaseEntity() {
    
    /**
     * 차감 유형 열거형
     */
    enum class DeductionType {
        WORK_ORDER,     // 작업 지시서
        MAINTENANCE,    // 유지보수
        EMERGENCY,      // 긴급
        ADJUSTMENT,     // 조정
        TRANSFER        // 이동
    }
    
    /**
     * 차감 상태 열거형
     */
    enum class DeductionStatus {
        PENDING,        // 대기중
        COMPLETED,      // 완료됨
        FAILED,         // 실패
        REVERSED        // 취소됨
    }
    
    /**
     * 차감량 검증
     */
    fun validateDeduction(): Boolean {
        return quantityDeducted > BigDecimal.ZERO &&
                stockBefore >= BigDecimal.ZERO &&
                stockAfter >= BigDecimal.ZERO &&
                stockAfter == stockBefore.subtract(quantityDeducted)
    }
    
    /**
     * 자동 처리 여부 확인
     */
    fun isAutomaticProcessing(): Boolean {
        return isAutomatic && processedBy == null
    }
    
    /**
     * 차감 완료 여부 확인
     */
    fun isCompleted(): Boolean {
        return deductionStatus == DeductionStatus.COMPLETED
    }
    
    /**
     * 차감 취소 가능 여부 확인
     */
    fun canReverse(): Boolean {
        return deductionStatus == DeductionStatus.COMPLETED
    }
}