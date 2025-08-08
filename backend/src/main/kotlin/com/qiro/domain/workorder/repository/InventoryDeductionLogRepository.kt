package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.InventoryDeductionLog
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
 * 재고 차감 로그 Repository
 */
@Repository
interface InventoryDeductionLogRepository : JpaRepository<InventoryDeductionLog, UUID> {
    
    /**
     * 작업 지시서별 재고 차감 로그 조회
     */
    fun findByWorkOrderIdOrderByDeductionDateDesc(workOrderId: UUID): List<InventoryDeductionLog>
    
    /**
     * 자재별 재고 차감 로그 조회
     */
    fun findByMaterialIdOrderByDeductionDateDesc(materialId: UUID): List<InventoryDeductionLog>
    
    /**
     * 자재별 기간별 재고 차감 로그 조회
     */
    fun findByMaterialIdAndDeductionDateBetweenOrderByDeductionDateDesc(
        materialId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<InventoryDeductionLog>
    
    /**
     * 저장 위치별 재고 차감 로그 조회
     */
    fun findByLocationIdOrderByDeductionDateDesc(locationId: UUID): List<InventoryDeductionLog>
    
    /**
     * 차감 유형별 재고 차감 로그 조회
     */
    fun findByDeductionTypeOrderByDeductionDateDesc(
        deductionType: InventoryDeductionLog.DeductionType
    ): List<InventoryDeductionLog>
    
    /**
     * 차감 상태별 재고 차감 로그 조회
     */
    fun findByDeductionStatusOrderByDeductionDateDesc(
        deductionStatus: InventoryDeductionLog.DeductionStatus
    ): List<InventoryDeductionLog>
    
    /**
     * 자동 처리된 재고 차감 로그 조회
     */
    fun findByIsAutomaticTrueOrderByDeductionDateDesc(): List<InventoryDeductionLog>
    
    /**
     * 수동 처리된 재고 차감 로그 조회
     */
    fun findByIsAutomaticFalseOrderByDeductionDateDesc(): List<InventoryDeductionLog>
    
    /**
     * 처리자별 재고 차감 로그 조회
     */
    fun findByProcessedByOrderByDeductionDateDesc(processedBy: UUID): List<InventoryDeductionLog>
    
    /**
     * 회사별 기간별 재고 차감 로그 조회
     */
    fun findByCompanyIdAndDeductionDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<InventoryDeductionLog>
    
    /**
     * 배치 번호별 재고 차감 로그 조회
     */
    fun findByBatchNumberOrderByDeductionDateDesc(batchNumber: String): List<InventoryDeductionLog>
    
    /**
     * 부품 사용별 재고 차감 로그 조회
     */
    fun findByPartUsageIdOrderByDeductionDateDesc(partUsageId: UUID): List<InventoryDeductionLog>
    
    /**
     * 자재 사용별 재고 차감 로그 조회
     */
    fun findByMaterialUsageIdOrderByDeductionDateDesc(materialUsageId: UUID): List<InventoryDeductionLog>
    
    /**
     * 복합 조건 검색 - 자재, 위치, 기간
     */
    fun findByMaterialIdAndLocationIdAndDeductionDateBetweenOrderByDeductionDateDesc(
        materialId: UUID,
        locationId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<InventoryDeductionLog>
    
    /**
     * 복합 조건 검색 - 작업 지시서, 자재, 상태
     */
    fun findByWorkOrderIdAndMaterialIdAndDeductionStatus(
        workOrderId: UUID,
        materialId: UUID,
        deductionStatus: InventoryDeductionLog.DeductionStatus
    ): List<InventoryDeductionLog>
    
    /**
     * 페이징 조회 - 회사별 기간별
     */
    fun findByCompanyIdAndDeductionDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<InventoryDeductionLog>
    
    /**
     * 작업 지시서별 총 차감 수량 계산
     */
    @Query("""
        SELECT COALESCE(SUM(d.quantityDeducted), 0)
        FROM InventoryDeductionLog d
        WHERE d.workOrderId = :workOrderId
        AND d.deductionStatus = 'COMPLETED'
    """)
    fun calculateTotalDeductedQuantityByWorkOrder(@Param("workOrderId") workOrderId: UUID): BigDecimal
    
    /**
     * 자재별 총 차감 수량 계산
     */
    @Query("""
        SELECT COALESCE(SUM(d.quantityDeducted), 0)
        FROM InventoryDeductionLog d
        WHERE d.materialId = :materialId
        AND d.deductionStatus = 'COMPLETED'
        AND d.deductionDate BETWEEN :startDate AND :endDate
    """)
    fun calculateTotalDeductedQuantityByMaterial(
        @Param("materialId") materialId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal
    
    /**
     * 기간별 차감 통계
     */
    @Query("""
        SELECT new map(
            COUNT(d) as totalDeductions,
            COALESCE(SUM(d.quantityDeducted), 0) as totalQuantityDeducted,
            COUNT(CASE WHEN d.isAutomatic = true THEN 1 END) as automaticDeductions,
            COUNT(CASE WHEN d.deductionStatus = 'COMPLETED' THEN 1 END) as completedDeductions,
            COUNT(CASE WHEN d.deductionStatus = 'REVERSED' THEN 1 END) as reversedDeductions
        )
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
    """)
    fun getDeductionStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Map<String, Any>
    
    /**
     * 차감 유형별 통계
     */
    @Query("""
        SELECT d.deductionType, COUNT(d)
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
        GROUP BY d.deductionType
    """)
    fun getDeductionCountByType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 차감 상태별 통계
     */
    @Query("""
        SELECT d.deductionStatus, COUNT(d)
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
        GROUP BY d.deductionStatus
    """)
    fun getDeductionCountByStatus(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 자재별 차감 빈도 Top N
     */
    @Query("""
        SELECT d.materialId, COUNT(d) as deductionCount
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
        AND d.deductionStatus = 'COMPLETED'
        GROUP BY d.materialId
        ORDER BY deductionCount DESC
        LIMIT :limit
    """)
    fun getTopMaterialsByDeductionFrequency(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
        @Param("limit") limit: Int
    ): List<Array<Any>>
    
    /**
     * 위치별 차감 빈도 Top N
     */
    @Query("""
        SELECT d.locationId, COUNT(d) as deductionCount
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
        AND d.deductionStatus = 'COMPLETED'
        GROUP BY d.locationId
        ORDER BY deductionCount DESC
        LIMIT :limit
    """)
    fun getTopLocationsByDeductionFrequency(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
        @Param("limit") limit: Int
    ): List<Array<Any>>
    
    /**
     * 일별 차감 추이 데이터
     */
    @Query("""
        SELECT 
            DATE(d.deductionDate) as deductionDate,
            COUNT(d) as deductionCount,
            COALESCE(SUM(d.quantityDeducted), 0) as totalQuantity
        FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        AND d.deductionDate BETWEEN :startDate AND :endDate
        AND d.deductionStatus = 'COMPLETED'
        GROUP BY DATE(d.deductionDate)
        ORDER BY deductionDate
    """)
    fun getDailyDeductionTrend(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 실패한 차감 로그 조회
     */
    fun findByDeductionStatusAndDeductionDateBetweenOrderByDeductionDateDesc(
        deductionStatus: InventoryDeductionLog.DeductionStatus,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<InventoryDeductionLog>
    
    /**
     * 최근 차감 로그 조회 (Top N)
     */
    @Query("""
        SELECT d FROM InventoryDeductionLog d
        WHERE d.companyId = :companyId
        ORDER BY d.deductionDate DESC
        LIMIT :limit
    """)
    fun findRecentDeductions(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int
    ): List<InventoryDeductionLog>
}