package com.qiro.domain.workorder.service

import com.qiro.domain.workorder.dto.CreatePartUsageRequest
import com.qiro.domain.workorder.entity.InventoryDeductionLog
import com.qiro.domain.workorder.entity.WorkOrderPartUsage
import com.qiro.domain.workorder.repository.InventoryDeductionLogRepository
import com.qiro.domain.workorder.repository.WorkOrderPartUsageRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 재고 차감 서비스
 * 부품 사용에 따른 재고 자동 차감 로직 관리
 */
@Service
@Transactional
class InventoryDeductionService(
    private val inventoryDeductionLogRepository: InventoryDeductionLogRepository,
    private val partUsageRepository: WorkOrderPartUsageRepository,
    private val inventoryService: InventoryService // 재고 관리 서비스 (가정)
) {
    
    /**
     * 부품 사용에 따른 자동 재고 차감
     */
    fun processAutomaticDeduction(
        partUsage: WorkOrderPartUsage,
        materialId: UUID,
        locationId: UUID
    ): InventoryDeductionLog {
        // 1. 현재 재고 확인
        val currentStock = inventoryService.getCurrentStock(materialId, locationId)
        
        // 2. 재고 부족 확인
        if (currentStock < partUsage.quantityUsed) {
            throw InsufficientStockException(
                "재고가 부족합니다. 현재 재고: $currentStock, 필요 수량: ${partUsage.quantityUsed}"
            )
        }
        
        // 3. 재고 차감 실행
        val newStock = currentStock.subtract(partUsage.quantityUsed)
        inventoryService.updateStock(materialId, locationId, newStock)
        
        // 4. 차감 로그 생성
        val deductionLog = InventoryDeductionLog(
            companyId = partUsage.companyId,
            workOrderId = partUsage.workOrderId,
            materialUsageId = partUsage.materialUsageId,
            partUsageId = partUsage.usageId,
            materialId = materialId,
            locationId = locationId,
            deductionDate = LocalDateTime.now(),
            quantityDeducted = partUsage.quantityUsed,
            unitId = partUsage.unitId,
            stockBefore = currentStock,
            stockAfter = newStock,
            batchNumber = partUsage.batchNumber,
            serialNumbers = partUsage.serialNumbers,
            deductionType = InventoryDeductionLog.DeductionType.WORK_ORDER,
            deductionReason = "작업 지시서 부품 사용: ${partUsage.usagePurpose ?: ""}",
            isAutomatic = true,
            deductionStatus = InventoryDeductionLog.DeductionStatus.COMPLETED
        )
        
        return inventoryDeductionLogRepository.save(deductionLog)
    }
    
    /**
     * 수동 재고 차감
     */
    fun processManualDeduction(
        companyId: UUID,
        workOrderId: UUID,
        materialUsageId: UUID,
        partUsageId: UUID,
        materialId: UUID,
        locationId: UUID,
        quantityToDeduct: BigDecimal,
        unitId: UUID,
        deductionReason: String,
        processedBy: UUID,
        batchNumber: String? = null
    ): InventoryDeductionLog {
        // 1. 현재 재고 확인
        val currentStock = inventoryService.getCurrentStock(materialId, locationId)
        
        // 2. 재고 부족 확인
        if (currentStock < quantityToDeduct) {
            throw InsufficientStockException(
                "재고가 부족합니다. 현재 재고: $currentStock, 차감 수량: $quantityToDeduct"
            )
        }
        
        // 3. 재고 차감 실행
        val newStock = currentStock.subtract(quantityToDeduct)
        inventoryService.updateStock(materialId, locationId, newStock)
        
        // 4. 차감 로그 생성
        val deductionLog = InventoryDeductionLog(
            companyId = companyId,
            workOrderId = workOrderId,
            materialUsageId = materialUsageId,
            partUsageId = partUsageId,
            materialId = materialId,
            locationId = locationId,
            deductionDate = LocalDateTime.now(),
            quantityDeducted = quantityToDeduct,
            unitId = unitId,
            stockBefore = currentStock,
            stockAfter = newStock,
            batchNumber = batchNumber,
            deductionType = InventoryDeductionLog.DeductionType.WORK_ORDER,
            deductionReason = deductionReason,
            isAutomatic = false,
            processedBy = processedBy,
            deductionStatus = InventoryDeductionLog.DeductionStatus.COMPLETED
        )
        
        return inventoryDeductionLogRepository.save(deductionLog)
    }
    
    /**
     * 재고 차감 취소 (반품 처리)
     */
    fun reverseDeduction(
        deductionId: UUID,
        reversalReason: String,
        processedBy: UUID
    ): InventoryDeductionLog {
        val originalDeduction = inventoryDeductionLogRepository.findById(deductionId)
            .orElseThrow { IllegalArgumentException("차감 로그를 찾을 수 없습니다: $deductionId") }
        
        // 1. 취소 가능 여부 확인
        if (!originalDeduction.canReverse()) {
            throw IllegalStateException("취소할 수 없는 차감 로그입니다: ${originalDeduction.deductionStatus}")
        }
        
        // 2. 재고 복원
        val currentStock = inventoryService.getCurrentStock(
            originalDeduction.materialId, 
            originalDeduction.locationId
        )
        val restoredStock = currentStock.add(originalDeduction.quantityDeducted)
        inventoryService.updateStock(
            originalDeduction.materialId, 
            originalDeduction.locationId, 
            restoredStock
        )
        
        // 3. 취소 로그 생성
        val reversalLog = InventoryDeductionLog(
            companyId = originalDeduction.companyId,
            workOrderId = originalDeduction.workOrderId,
            materialUsageId = originalDeduction.materialUsageId,
            partUsageId = originalDeduction.partUsageId,
            materialId = originalDeduction.materialId,
            locationId = originalDeduction.locationId,
            deductionDate = LocalDateTime.now(),
            quantityDeducted = originalDeduction.quantityDeducted.negate(), // 음수로 기록
            unitId = originalDeduction.unitId,
            stockBefore = currentStock,
            stockAfter = restoredStock,
            batchNumber = originalDeduction.batchNumber,
            serialNumbers = originalDeduction.serialNumbers,
            deductionType = originalDeduction.deductionType,
            deductionReason = "차감 취소: $reversalReason",
            isAutomatic = false,
            processedBy = processedBy,
            deductionStatus = InventoryDeductionLog.DeductionStatus.REVERSED
        )
        
        // 4. 원본 차감 로그 상태 업데이트
        val updatedOriginal = originalDeduction.copy(
            deductionStatus = InventoryDeductionLog.DeductionStatus.REVERSED
        )
        inventoryDeductionLogRepository.save(updatedOriginal)
        
        return inventoryDeductionLogRepository.save(reversalLog)
    }
    
    /**
     * 작업 지시서별 재고 차감 내역 조회
     */
    @Transactional(readOnly = true)
    fun getDeductionsByWorkOrder(workOrderId: UUID): List<InventoryDeductionLog> {
        return inventoryDeductionLogRepository.findByWorkOrderIdOrderByDeductionDateDesc(workOrderId)
    }
    
    /**
     * 자재별 재고 차감 내역 조회
     */
    @Transactional(readOnly = true)
    fun getDeductionsByMaterial(
        materialId: UUID,
        startDate: LocalDateTime? = null,
        endDate: LocalDateTime? = null
    ): List<InventoryDeductionLog> {
        return if (startDate != null && endDate != null) {
            inventoryDeductionLogRepository.findByMaterialIdAndDeductionDateBetweenOrderByDeductionDateDesc(
                materialId, startDate, endDate
            )
        } else {
            inventoryDeductionLogRepository.findByMaterialIdOrderByDeductionDateDesc(materialId)
        }
    }
    
    /**
     * 재고 차감 통계 조회
     */
    @Transactional(readOnly = true)
    fun getDeductionStatistics(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): DeductionStatistics {
        val deductions = inventoryDeductionLogRepository
            .findByCompanyIdAndDeductionDateBetween(companyId, startDate, endDate)
        
        val totalDeductions = deductions.size.toLong()
        val totalQuantity = deductions.sumOf { it.quantityDeducted }
        val automaticDeductions = deductions.count { it.isAutomatic }.toLong()
        val completedDeductions = deductions.count { 
            it.deductionStatus == InventoryDeductionLog.DeductionStatus.COMPLETED 
        }.toLong()
        val reversedDeductions = deductions.count { 
            it.deductionStatus == InventoryDeductionLog.DeductionStatus.REVERSED 
        }.toLong()
        
        val deductionsByType = deductions.groupBy { it.deductionType }
            .mapValues { it.value.size.toLong() }
        
        val deductionsByStatus = deductions.groupBy { it.deductionStatus }
            .mapValues { it.value.size.toLong() }
        
        return DeductionStatistics(
            totalDeductions = totalDeductions,
            totalQuantityDeducted = totalQuantity,
            automaticDeductionCount = automaticDeductions,
            manualDeductionCount = totalDeductions - automaticDeductions,
            completedDeductionCount = completedDeductions,
            reversedDeductionCount = reversedDeductions,
            automaticDeductionRate = if (totalDeductions > 0) {
                BigDecimal.valueOf(automaticDeductions * 100).divide(
                    BigDecimal.valueOf(totalDeductions), 2, java.math.RoundingMode.HALF_UP
                )
            } else BigDecimal.ZERO,
            successRate = if (totalDeductions > 0) {
                BigDecimal.valueOf(completedDeductions * 100).divide(
                    BigDecimal.valueOf(totalDeductions), 2, java.math.RoundingMode.HALF_UP
                )
            } else BigDecimal.ZERO,
            deductionsByType = deductionsByType,
            deductionsByStatus = deductionsByStatus
        )
    }
    
    /**
     * 재고 부족 알림 확인
     */
    @Transactional(readOnly = true)
    fun checkLowStockAlerts(companyId: UUID): List<LowStockAlert> {
        // 재고 서비스에서 낮은 재고 목록을 가져와서 알림 생성
        return inventoryService.getLowStockMaterials(companyId)
            .map { material ->
                LowStockAlert(
                    materialId = material.materialId,
                    materialName = material.materialName,
                    currentStock = material.currentStock,
                    minimumStock = material.minimumStock,
                    reorderPoint = material.reorderPoint,
                    stockShortage = material.minimumStock.subtract(material.currentStock),
                    alertLevel = when {
                        material.currentStock <= BigDecimal.ZERO -> AlertLevel.CRITICAL
                        material.currentStock <= material.reorderPoint -> AlertLevel.HIGH
                        material.currentStock <= material.minimumStock -> AlertLevel.MEDIUM
                        else -> AlertLevel.LOW
                    }
                )
            }
    }
}

/**
 * 재고 부족 예외
 */
class InsufficientStockException(message: String) : RuntimeException(message)

/**
 * 재고 차감 통계 DTO
 */
data class DeductionStatistics(
    val totalDeductions: Long,
    val totalQuantityDeducted: BigDecimal,
    val automaticDeductionCount: Long,
    val manualDeductionCount: Long,
    val completedDeductionCount: Long,
    val reversedDeductionCount: Long,
    val automaticDeductionRate: BigDecimal,
    val successRate: BigDecimal,
    val deductionsByType: Map<InventoryDeductionLog.DeductionType, Long>,
    val deductionsByStatus: Map<InventoryDeductionLog.DeductionStatus, Long>
)

/**
 * 낮은 재고 알림 DTO
 */
data class LowStockAlert(
    val materialId: UUID,
    val materialName: String,
    val currentStock: BigDecimal,
    val minimumStock: BigDecimal,
    val reorderPoint: BigDecimal,
    val stockShortage: BigDecimal,
    val alertLevel: AlertLevel
)

/**
 * 알림 수준 열거형
 */
enum class AlertLevel {
    LOW,        // 낮음
    MEDIUM,     // 보통
    HIGH,       // 높음
    CRITICAL    // 긴급
}

/**
 * 재고 서비스 인터페이스 (가정)
 */
interface InventoryService {
    fun getCurrentStock(materialId: UUID, locationId: UUID): BigDecimal
    fun updateStock(materialId: UUID, locationId: UUID, newStock: BigDecimal)
    fun getLowStockMaterials(companyId: UUID): List<MaterialStockInfo>
}

/**
 * 자재 재고 정보 DTO (가정)
 */
data class MaterialStockInfo(
    val materialId: UUID,
    val materialName: String,
    val currentStock: BigDecimal,
    val minimumStock: BigDecimal,
    val reorderPoint: BigDecimal
)