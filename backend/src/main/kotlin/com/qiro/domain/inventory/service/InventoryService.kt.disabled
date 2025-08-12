package com.qiro.domain.inventory.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 재고 및 자재 관리 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 재고 관리 (8개 프로시저)
 * - 자재 관리 (4개 프로시저)
 * - 공급업체 관리 (5개 프로시저)
 * - 구매 관리 (6개 프로시저)
 */
interface InventoryService {
    
    // === 자재 관리 ===
    
    /**
     * 자재 생성
     * 기존 프로시저: bms.create_material
     */
    fun createMaterial(request: CreateMaterialRequest): MaterialDto
    
    /**
     * 자재 조회
     */
    fun getMaterial(companyId: UUID, materialId: UUID): MaterialDto?
    
    /**
     * 자재 목록 조회
     * 기존 프로시저: bms.get_materials
     */
    fun getMaterials(companyId: UUID, pageable: Pageable): Page<MaterialDto>
    
    /**
     * 자재 필터 조회
     */
    fun getMaterialsWithFilter(filter: InventoryManagementFilter, pageable: Pageable): Page<MaterialDto>
    
    /**
     * 자재 수정
     */
    fun updateMaterial(materialId: UUID, request: CreateMaterialRequest): MaterialDto
    
    /**
     * 자재 삭제 (비활성화)
     */
    fun deleteMaterial(companyId: UUID, materialId: UUID): Boolean
    
    /**
     * 자재 비용 업데이트
     * 기존 프로시저: bms.update_material_cost
     */
    fun updateMaterialCost(materialId: UUID, newCost: BigDecimal, reason: String? = null): MaterialDto
    
    /**
     * 자재 통계 조회
     * 기존 프로시저: bms.get_material_statistics
     */
    fun getMaterialStatistics(companyId: UUID, categoryId: UUID? = null): Map<String, Any>
    
    // === 공급업체 관리 ===
    
    /**
     * 공급업체 생성
     * 기존 프로시저: bms.create_supplier
     */
    fun createSupplier(request: CreateSupplierRequest): SupplierDto
    
    /**
     * 공급업체 조회
     */
    fun getSupplier(companyId: UUID, supplierId: UUID): SupplierDto?
    
    /**
     * 공급업체 목록 조회
     * 기존 프로시저: bms.get_suppliers
     */
    fun getSuppliers(companyId: UUID, pageable: Pageable): Page<SupplierDto>
    
    /**
     * 공급업체 필터 조회
     */
    fun getSuppliersWithFilter(filter: InventoryManagementFilter, pageable: Pageable): Page<SupplierDto>
    
    /**
     * 공급업체 수정
     */
    fun updateSupplier(supplierId: UUID, request: CreateSupplierRequest): SupplierDto
    
    /**
     * 공급업체 삭제 (비활성화)
     */
    fun deleteSupplier(companyId: UUID, supplierId: UUID): Boolean
    
    /**
     * 자재-공급업체 관계 추가
     * 기존 프로시저: bms.add_material_supplier
     */
    fun addMaterialSupplier(
        materialId: UUID, 
        supplierId: UUID, 
        unitCost: BigDecimal? = null,
        leadTimeDays: Int? = null,
        minimumOrderQuantity: Int? = null
    ): Boolean
    
    /**
     * 자재별 공급업체 조회
     * 기존 프로시저: bms.get_material_suppliers
     */
    fun getMaterialSuppliers(materialId: UUID): List<SupplierDto>
    
    /**
     * 공급업체 성과 조회
     * 기존 프로시저: bms.get_supplier_performance_report
     */
    fun getSupplierPerformance(companyId: UUID, supplierId: UUID? = null): List<SupplierPerformanceDto>
    
    // === 재고 관리 ===
    
    /**
     * 재고 거래 생성
     */
    fun createInventoryTransaction(request: CreateInventoryTransactionRequest): InventoryTransactionDto
    
    /**
     * 재고 입고 처리
     * 기존 프로시저: bms.create_inventory_receipt_transaction
     */
    fun processInventoryReceipt(
        companyId: UUID,
        materialId: UUID,
        quantity: Int,
        unitCost: BigDecimal,
        referenceType: String? = null,
        referenceId: UUID? = null
    ): InventoryTransactionDto
    
    /**
     * 재고 출고 처리
     */
    fun processInventoryIssue(
        companyId: UUID,
        materialId: UUID,
        quantity: Int,
        referenceType: String? = null,
        referenceId: UUID? = null,
        notes: String? = null
    ): InventoryTransactionDto
    
    /**
     * 재고 예약
     * 기존 프로시저: bms.reserve_inventory
     */
    fun reserveInventory(request: ReserveInventoryRequest): InventoryReservationResult
    
    /**
     * 재고 예약 해제
     */
    fun releaseInventoryReservation(
        companyId: UUID,
        reservationId: UUID,
        reason: String? = null
    ): Boolean
    
    /**
     * 재고 이동
     */
    fun transferInventory(
        companyId: UUID,
        materialId: UUID,
        quantity: Int,
        fromLocation: String,
        toLocation: String,
        notes: String? = null
    ): InventoryTransactionDto
    
    /**
     * 재고 조정
     */
    fun adjustInventory(
        companyId: UUID,
        materialId: UUID,
        adjustmentQuantity: Int,
        reason: String,
        notes: String? = null
    ): InventoryTransactionDto
    
    /**
     * 재고 현황 조회
     */
    fun getInventoryStatus(companyId: UUID, materialId: UUID): InventoryStatusDto?
    
    /**
     * 재고 현황 목록 조회
     */
    fun getInventoryStatusList(companyId: UUID, pageable: Pageable): Page<InventoryStatusDto>
    
    /**
     * 위치별 재고 요약 조회
     * 기존 프로시저: bms.get_inventory_summary_by_location
     */
    fun getInventorySummaryByLocation(companyId: UUID, locationId: UUID? = null): Map<String, Any>
    
    /**
     * 재고 부족 보고서 조회
     * 기존 프로시저: bms.get_low_stock_report
     */
    fun getLowStockReport(companyId: UUID, locationId: UUID? = null): List<LowStockAlertDto>
    
    /**
     * 재고 이동 이력 조회
     * 기존 프로시저: bms.get_inventory_movement_history
     */
    fun getInventoryMovementHistory(
        companyId: UUID,
        materialId: UUID,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null,
        pageable: Pageable
    ): Page<InventoryMovementHistoryDto>
    
    // === 구매 관리 ===
    
    /**
     * 구매 요청 생성
     * 기존 프로시저: bms.create_purchase_request
     */
    fun createPurchaseRequest(request: CreatePurchaseRequestRequest): PurchaseRequestDto
    
    /**
     * 구매 요청 조회
     */
    fun getPurchaseRequest(companyId: UUID, requestId: UUID): PurchaseRequestDto?
    
    /**
     * 구매 요청 목록 조회
     */
    fun getPurchaseRequests(companyId: UUID, pageable: Pageable): Page<PurchaseRequestDto>
    
    /**
     * 구매 요청 항목 추가
     * 기존 프로시저: bms.add_purchase_request_item
     */
    fun addPurchaseRequestItem(request: AddPurchaseRequestItemRequest): PurchaseRequestItemDto
    
    /**
     * 구매 요청 승인 제출
     * 기존 프로시저: bms.submit_purchase_request
     */
    fun submitPurchaseRequest(requestId: UUID, submittedBy: UUID? = null): PurchaseRequestDto
    
    /**
     * 구매 요청 승인
     */
    fun approvePurchaseRequest(
        companyId: UUID,
        requestId: UUID,
        approvedBy: UUID,
        approvalNotes: String? = null
    ): PurchaseRequestDto
    
    /**
     * 구매 주문 생성
     * 기존 프로시저: bms.create_purchase_order_from_quotation
     */
    fun createPurchaseOrder(request: CreatePurchaseOrderRequest): PurchaseOrderDto
    
    /**
     * 구매 주문 조회
     */
    fun getPurchaseOrder(companyId: UUID, orderId: UUID): PurchaseOrderDto?
    
    /**
     * 구매 주문 목록 조회
     */
    fun getPurchaseOrders(companyId: UUID, pageable: Pageable): Page<PurchaseOrderDto>
    
    /**
     * 구매 주문 승인
     */
    fun approvePurchaseOrder(
        companyId: UUID,
        orderId: UUID,
        approvedBy: UUID,
        approvalNotes: String? = null
    ): PurchaseOrderDto
    
    /**
     * 구매 주문 완료 처리
     */
    fun completePurchaseOrder(
        companyId: UUID,
        orderId: UUID,
        completionNotes: String? = null
    ): PurchaseOrderDto
    
    /**
     * 구매 요청 상태 요약 조회
     * 기존 프로시저: bms.get_purchase_request_summary
     */
    fun getPurchaseRequestSummary(
        companyId: UUID,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null
    ): Map<String, Any>
    
    // === 통계 및 분석 ===
    
    /**
     * 재고 관리 통계 조회
     */
    fun getInventoryManagementStatistics(companyId: UUID): InventoryManagementStatisticsDto
    
    /**
     * 월별 구매 요약 조회
     */
    fun getMonthlyPurchaseSummary(
        companyId: UUID,
        year: Int,
        month: Int
    ): PurchaseSummaryDto?
    
    /**
     * 기간별 구매 요약 조회
     */
    fun getPurchaseSummaryByPeriod(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<PurchaseSummaryDto>
    
    /**
     * 재고 회전율 분석
     */
    fun getInventoryTurnoverAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 자재별 사용량 분석
     */
    fun getMaterialUsageAnalysis(
        companyId: UUID,
        materialId: UUID? = null,
        period: String = "MONTHLY"
    ): Map<String, Any>
    
    /**
     * 공급업체별 구매 분석
     */
    fun getSupplierPurchaseAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 재고 가치 분석
     */
    fun getInventoryValueAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 구매 트렌드 분석
     */
    fun getPurchaseTrendAnalysis(
        companyId: UUID,
        period: String = "MONTHLY"
    ): Map<String, Any>
    
    // === 알림 및 자동화 ===
    
    /**
     * 재고 부족 알림 생성
     */
    fun generateLowStockAlerts(companyId: UUID): List<LowStockAlertDto>
    
    /**
     * 자동 재주문 처리
     */
    fun processAutoReorder(companyId: UUID): List<PurchaseRequestDto>
    
    /**
     * 재고 만료 알림 생성
     */
    fun generateExpiryAlerts(companyId: UUID, daysAhead: Int = 30): List<Map<String, Any>>
    
    /**
     * 공급업체 성과 알림 생성
     */
    fun generateSupplierPerformanceAlerts(companyId: UUID): List<Map<String, Any>>
    
    /**
     * 재고 최적화 제안
     */
    fun generateInventoryOptimizationSuggestions(companyId: UUID): List<Map<String, Any>>
    
    // === 배치 작업 ===
    
    /**
     * 재고 잔량 업데이트
     */
    fun updateInventoryBalances(companyId: UUID): Map<String, Any>
    
    /**
     * 재고 평가 업데이트
     */
    fun updateInventoryValuation(companyId: UUID): Map<String, Any>
    
    /**
     * 공급업체 성과 업데이트
     */
    fun updateSupplierPerformanceMetrics(companyId: UUID): Map<String, Any>
    
    /**
     * 재고 통계 업데이트
     */
    fun updateInventoryStatistics(companyId: UUID): Map<String, Any>
}