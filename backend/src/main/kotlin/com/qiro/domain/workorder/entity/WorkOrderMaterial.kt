package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 자료 엔티티
 * 작업에 필요한 자재 관리 및 사용량 추적
 */
@Entity
@Table(
    name = "work_order_materials",
    schema = "bms",
    indexes = [
        Index(name = "idx_work_materials_company_id", columnList = "company_id"),
        Index(name = "idx_work_materials_work_order", columnList = "work_order_id"),
        Index(name = "idx_work_materials_code", columnList = "material_code"),
        Index(name = "idx_work_materials_category", columnList = "material_category"),
        Index(name = "idx_work_materials_status", columnList = "material_status"),
        Index(name = "idx_work_materials_procurement", columnList = "procurement_status")
    ]
)
class WorkOrderMaterial : BaseEntity() {
    
    @Id
    @Column(name = "material_usage_id")
    val materialUsageId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "work_order_id", nullable = false)
    lateinit var workOrder: WorkOrder
    
    @Column(name = "material_code", length = 50)
    var materialCode: String? = null
    
    @Column(name = "material_name", nullable = false, length = 200)
    lateinit var materialName: String
    
    @Column(name = "material_category", length = 50)
    var materialCategory: String? = null
    
    @Column(name = "material_specification", columnDefinition = "TEXT")
    var materialSpecification: String? = null
    
    @Column(name = "required_quantity", nullable = false, precision = 10, scale = 3)
    lateinit var requiredQuantity: BigDecimal
    
    @Column(name = "allocated_quantity", precision = 10, scale = 3)
    var allocatedQuantity: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "used_quantity", precision = 10, scale = 3)
    var usedQuantity: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "returned_quantity", precision = 10, scale = 3)
    var returnedQuantity: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "unit_of_measure", nullable = false, length = 20)
    lateinit var unitOfMeasure: String
    
    @Column(name = "unit_cost", precision = 12, scale = 2)
    var unitCost: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "total_estimated_cost", precision = 12, scale = 2)
    var totalEstimatedCost: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "total_actual_cost", precision = 12, scale = 2)
    var totalActualCost: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "supplier_name", length = 200)
    var supplierName: String? = null
    
    @Column(name = "supplier_contact", columnDefinition = "JSONB")
    var supplierContact: String? = null
    
    @Column(name = "purchase_order_number", length = 50)
    var purchaseOrderNumber: String? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "material_status", length = 20)
    var materialStatus: MaterialStatus = MaterialStatus.REQUIRED
    
    @Enumerated(EnumType.STRING)
    @Column(name = "procurement_status", length = 20)
    var procurementStatus: ProcurementStatus = ProcurementStatus.PENDING
    
    @Column(name = "requested_delivery_date")
    var requestedDeliveryDate: LocalDate? = null
    
    @Column(name = "actual_delivery_date")
    var actualDeliveryDate: LocalDate? = null
    
    @Column(name = "delivery_location", columnDefinition = "TEXT")
    var deliveryLocation: String? = null
    
    @Column(name = "quality_specification", columnDefinition = "TEXT")
    var qualitySpecification: String? = null
    
    @Column(name = "quality_check_required")
    var qualityCheckRequired: Boolean = false
    
    @Column(name = "quality_check_passed")
    var qualityCheckPassed: Boolean = false
    
    @Column(name = "quality_notes", columnDefinition = "TEXT")
    var qualityNotes: String? = null
    
    @Column(name = "usage_date")
    var usageDate: LocalDateTime? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "used_by")
    var usedBy: User? = null
    
    @Column(name = "usage_notes", columnDefinition = "TEXT")
    var usageNotes: String? = null
    
    @Column(name = "waste_quantity", precision = 10, scale = 3)
    var wasteQuantity: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "waste_reason", columnDefinition = "TEXT")
    var wasteReason: String? = null
    
    @Column(name = "return_reason", columnDefinition = "TEXT")
    var returnReason: String? = null
    
    /**
     * 자재 할당
     */
    fun allocate(quantity: BigDecimal) {
        require(quantity > BigDecimal.ZERO) { "할당 수량은 0보다 커야 합니다." }
        require(quantity <= requiredQuantity) { "할당 수량은 필요 수량을 초과할 수 없습니다." }
        
        this.allocatedQuantity = quantity
        this.materialStatus = MaterialStatus.ALLOCATED
    }
    
    /**
     * 자재 사용
     */
    fun use(quantity: BigDecimal, usedBy: User, notes: String? = null) {
        require(quantity > BigDecimal.ZERO) { "사용 수량은 0보다 커야 합니다." }
        require(quantity <= allocatedQuantity) { "사용 수량은 할당 수량을 초과할 수 없습니다." }
        
        this.usedQuantity = this.usedQuantity.add(quantity)
        this.usedBy = usedBy
        this.usageDate = LocalDateTime.now()
        this.usageNotes = notes
        this.materialStatus = MaterialStatus.USED
        
        // 실제 비용 계산
        this.totalActualCost = this.usedQuantity.multiply(this.unitCost)
    }
    
    /**
     * 자재 반납
     */
    fun returnMaterial(quantity: BigDecimal, reason: String) {
        require(quantity > BigDecimal.ZERO) { "반납 수량은 0보다 커야 합니다." }
        require(quantity <= allocatedQuantity.subtract(usedQuantity)) { "반납 수량이 가능한 수량을 초과합니다." }
        
        this.returnedQuantity = this.returnedQuantity.add(quantity)
        this.returnReason = reason
        this.materialStatus = MaterialStatus.RETURNED
    }
    
    /**
     * 폐기 처리
     */
    fun recordWaste(quantity: BigDecimal, reason: String) {
        require(quantity > BigDecimal.ZERO) { "폐기 수량은 0보다 커야 합니다." }
        
        this.wasteQuantity = this.wasteQuantity.add(quantity)
        this.wasteReason = reason
    }
    
    /**
     * 품질 검사 수행
     */
    fun performQualityCheck(passed: Boolean, notes: String? = null) {
        this.qualityCheckPassed = passed
        this.qualityNotes = notes
        
        if (passed) {
            this.procurementStatus = ProcurementStatus.RECEIVED
        }
    }
    
    /**
     * 배송 완료 처리
     */
    fun markDelivered(deliveryDate: LocalDate = LocalDate.now()) {
        this.actualDeliveryDate = deliveryDate
        this.procurementStatus = ProcurementStatus.DELIVERED
        this.materialStatus = MaterialStatus.DELIVERED
    }
    
    /**
     * 예상 비용 계산
     */
    fun calculateEstimatedCost() {
        this.totalEstimatedCost = this.requiredQuantity.multiply(this.unitCost)
    }
    
    /**
     * 잔여 수량 계산
     */
    fun getRemainingQuantity(): BigDecimal {
        return allocatedQuantity.subtract(usedQuantity).subtract(returnedQuantity).subtract(wasteQuantity)
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is WorkOrderMaterial) return false
        return materialUsageId == other.materialUsageId
    }
    
    override fun hashCode(): Int {
        return materialUsageId.hashCode()
    }
    
    override fun toString(): String {
        return "WorkOrderMaterial(materialUsageId=$materialUsageId, materialName='$materialName', materialStatus=$materialStatus)"
    }
}

/**
 * 자재 상태
 */
enum class MaterialStatus(
    val displayName: String,
    val description: String
) {
    REQUIRED("필요", "자재가 필요함"),
    REQUESTED("요청됨", "자재 요청됨"),
    ORDERED("주문됨", "자재 주문됨"),
    DELIVERED("배송됨", "자재 배송 완료"),
    ALLOCATED("할당됨", "자재 할당됨"),
    USED("사용됨", "자재 사용됨"),
    RETURNED("반납됨", "자재 반납됨"),
    CANCELLED("취소됨", "자재 요청 취소됨");
    
    companion object {
        fun fromDisplayName(displayName: String): MaterialStatus? {
            return values().find { it.displayName == displayName }
        }
    }
}

/**
 * 조달 상태
 */
enum class ProcurementStatus(
    val displayName: String,
    val description: String
) {
    PENDING("대기중", "조달 대기 중"),
    REQUESTED("요청됨", "조달 요청됨"),
    APPROVED("승인됨", "조달 승인됨"),
    ORDERED("주문됨", "주문 완료"),
    DELIVERED("배송됨", "배송 완료"),
    RECEIVED("입고됨", "입고 완료"),
    REJECTED("거부됨", "조달 거부됨"),
    CANCELLED("취소됨", "조달 취소됨");
    
    companion object {
        fun fromDisplayName(displayName: String): ProcurementStatus? {
            return values().find { it.displayName == displayName }
        }
    }
}