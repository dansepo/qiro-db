package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.WorkOrderPartUsage
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 부품 사용 내역 Repository
 */
@Repository
interface WorkOrderPartUsageRepository : JpaRepository<WorkOrderPartUsage, UUID> {
    
    /**
     * 작업 지시서별 부품 사용 내역 조회
     */
    fun findByWorkOrderIdOrderByUsageDateDesc(workOrderId: UUID): List<WorkOrderPartUsage>
    
    /**
     * 작업 지시서별 부품 사용 내역 페이징 조회
     */
    fun findByWorkOrderId(workOrderId: UUID, pageable: Pageable): Page<WorkOrderPartUsage>
    
    /**
     * 사용자별 부품 사용 내역 조회
     */
    fun findByUsedByOrderByUsageDateDesc(usedBy: UUID): List<WorkOrderPartUsage>
    
    /**
     * 자재 사용별 부품 사용 내역 조회
     */
    fun findByMaterialUsageIdOrderByUsageDateDesc(materialUsageId: UUID): List<WorkOrderPartUsage>
    
    /**
     * 상태별 부품 사용 내역 조회
     */
    fun findByUsageStatusOrderByUsageDateDesc(usageStatus: WorkOrderPartUsage.UsageStatus): List<WorkOrderPartUsage>
    
    /**
     * 품질 상태별 부품 사용 내역 조회
     */
    fun findByQualityStatusOrderByUsageDateDesc(qualityStatus: WorkOrderPartUsage.QualityStatus): List<WorkOrderPartUsage>
    
    /**
     * 승인 대기 중인 부품 사용 내역 조회
     */
    fun findByApprovedByIsNullOrderByUsageDateDesc(): List<WorkOrderPartUsage>
    
    /**
     * 승인된 부품 사용 내역 조회
     */
    fun findByApprovedByIsNotNullOrderByUsageDateDesc(): List<WorkOrderPartUsage>
    
    /**
     * 배치 번호별 부품 사용 내역 조회
     */
    fun findByBatchNumberOrderByUsageDateDesc(batchNumber: String): List<WorkOrderPartUsage>
    
    /**
     * 기간별 부품 사용 내역 조회
     */
    fun findByUsageDateBetweenOrderByUsageDateDesc(
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<WorkOrderPartUsage>
    
    /**
     * 회사별 기간별 부품 사용 내역 조회
     */
    fun findByCompanyIdAndUsageDateBetweenOrderByUsageDateDesc(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<WorkOrderPartUsage>
    
    /**
     * 복합 조건 검색 - 작업 지시서, 사용자, 상태
     */
    fun findByWorkOrderIdAndUsedByAndUsageStatus(
        workOrderId: UUID,
        usedBy: UUID,
        usageStatus: WorkOrderPartUsage.UsageStatus
    ): List<WorkOrderPartUsage>
    
    /**
     * 복합 조건 검색 - 작업 지시서, 기간, 상태
     */
    fun findByWorkOrderIdAndUsageDateBetweenAndUsageStatus(
        workOrderId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        usageStatus: WorkOrderPartUsage.UsageStatus
    ): List<WorkOrderPartUsage>
    
    /**
     * 작업 지시서별 총 부품 사용 비용 계산
     */
    @Query("""
        SELECT COALESCE(SUM(p.totalCost), 0)
        FROM WorkOrderPartUsage p
        WHERE p.workOrderId = :workOrderId
        AND p.usageStatus != 'CANCELLED'
    """)
    fun calculateTotalCostByWorkOrder(@Param("workOrderId") workOrderId: UUID): BigDecimal
    
    /**
     * 작업 지시서별 총 부품 사용 수량 계산
     */
    @Query("""
        SELECT COALESCE(SUM(p.quantityUsed - p.wasteQuantity - p.returnQuantity), 0)
        FROM WorkOrderPartUsage p
        WHERE p.workOrderId = :workOrderId
        AND p.usageStatus != 'CANCELLED'
    """)
    fun calculateTotalUsedQuantityByWorkOrder(@Param("workOrderId") workOrderId: UUID): BigDecimal
    
    /**
     * 기간별 부품 사용 통계
     */
    @Query("""
        SELECT new map(
            COUNT(p) as totalUsages,
            COALESCE(SUM(p.quantityUsed), 0) as totalQuantityUsed,
            COALESCE(SUM(p.totalCost), 0) as totalCost,
            COALESCE(SUM(p.wasteQuantity), 0) as totalWasteQuantity,
            COALESCE(SUM(p.returnQuantity), 0) as totalReturnQuantity,
            COALESCE(AVG(p.unitCost), 0) as averageUnitCost
        )
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        AND p.usageStatus != 'CANCELLED'
    """)
    fun getUsageStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Map<String, Any>
    
    /**
     * 상태별 부품 사용 건수 통계
     */
    @Query("""
        SELECT p.usageStatus, COUNT(p)
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        GROUP BY p.usageStatus
    """)
    fun getUsageCountByStatus(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 품질 상태별 부품 사용 건수 통계
     */
    @Query("""
        SELECT p.qualityStatus, COUNT(p)
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        GROUP BY p.qualityStatus
    """)
    fun getUsageCountByQuality(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 승인율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN p.approvedBy IS NOT NULL THEN 1 END) * 100.0 / COUNT(p)
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        AND p.usageStatus != 'CANCELLED'
    """)
    fun getApprovalRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 폐기율 계산
     */
    @Query("""
        SELECT 
            COALESCE(SUM(p.wasteQuantity), 0) * 100.0 / COALESCE(SUM(p.quantityUsed), 1)
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        AND p.usageStatus != 'CANCELLED'
    """)
    fun getWasteRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 반품율 계산
     */
    @Query("""
        SELECT 
            COALESCE(SUM(p.returnQuantity), 0) * 100.0 / COALESCE(SUM(p.quantityUsed), 1)
        FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        AND p.usageDate BETWEEN :startDate AND :endDate
        AND p.usageStatus != 'CANCELLED'
    """)
    fun getReturnRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 최근 부품 사용 내역 조회 (Top N)
     */
    @Query("""
        SELECT p FROM WorkOrderPartUsage p
        WHERE p.companyId = :companyId
        ORDER BY p.usageDate DESC
        LIMIT :limit
    """)
    fun findRecentUsages(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int
    ): List<WorkOrderPartUsage>
}