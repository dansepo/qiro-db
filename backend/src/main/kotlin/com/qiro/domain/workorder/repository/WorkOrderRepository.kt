package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 Repository
 */
@Repository
interface WorkOrderRepository : JpaRepository<WorkOrder, UUID> {
    
    /**
     * 회사별 작업 지시서 조회
     */
    fun findByCompanyCompanyId(companyId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 작업 지시서 번호로 조회
     */
    fun findByCompanyCompanyIdAndWorkOrderNumber(companyId: UUID, workOrderNumber: String): WorkOrder?
    
    /**
     * 상태별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndWorkStatus(companyId: UUID, workStatus: WorkStatus, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 우선순위별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndWorkPriority(companyId: UUID, workPriority: WorkPriority, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 카테고리별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndWorkCategory(companyId: UUID, workCategory: WorkCategory, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 작업 유형별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndWorkType(companyId: UUID, workType: WorkType, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 담당자별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndAssignedToUserId(companyId: UUID, assignedToId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 요청자별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndRequestedByUserId(companyId: UUID, requestedById: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 건물별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndBuildingBuildingId(companyId: UUID, buildingId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 유닛별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndUnitUnitId(companyId: UUID, unitId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 자산별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndAssetAssetId(companyId: UUID, assetId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 고장 신고별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndFaultReportReportId(companyId: UUID, faultReportId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 기간별 작업 지시서 조회
     */
    fun findByCompanyCompanyIdAndRequestDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<WorkOrder>
    
    /**
     * 예정 시작일 기준 조회
     */
    fun findByCompanyCompanyIdAndScheduledStartDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<WorkOrder>
    
    /**
     * 지연된 작업 지시서 조회
     */
    @Query("""
        SELECT w FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus IN ('IN_PROGRESS', 'SCHEDULED') 
        AND w.scheduledEndDate < :currentDate
    """)
    fun findDelayedWorkOrders(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDateTime,
        pageable: Pageable
    ): Page<WorkOrder>
    
    /**
     * 긴급 작업 지시서 조회
     */
    @Query("""
        SELECT w FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workPriority IN ('URGENT', 'EMERGENCY') 
        AND w.workStatus NOT IN ('COMPLETED', 'CANCELLED', 'REJECTED')
        ORDER BY w.workPriority DESC, w.requestDate ASC
    """)
    fun findUrgentWorkOrders(@Param("companyId") companyId: UUID, pageable: Pageable): Page<WorkOrder>
    
    /**
     * 복합 검색 쿼리
     */
    @Query("""
        SELECT w FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND (:keyword IS NULL OR 
             LOWER(w.workOrderTitle) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
             LOWER(w.workDescription) LIKE LOWER(CONCAT('%', :keyword, '%')) OR 
             LOWER(w.workOrderNumber) LIKE LOWER(CONCAT('%', :keyword, '%')))
        AND (:workCategory IS NULL OR w.workCategory = :workCategory)
        AND (:workType IS NULL OR w.workType = :workType)
        AND (:workStatus IS NULL OR w.workStatus = :workStatus)
        AND (:workPriority IS NULL OR w.workPriority = :workPriority)
        AND (:assignedToId IS NULL OR w.assignedTo.userId = :assignedToId)
        AND (:buildingId IS NULL OR w.building.buildingId = :buildingId)
        AND (:unitId IS NULL OR w.unit.unitId = :unitId)
        AND (:requestedById IS NULL OR w.requestedBy.userId = :requestedById)
        AND (:startDate IS NULL OR w.requestDate >= :startDate)
        AND (:endDate IS NULL OR w.requestDate <= :endDate)
    """)
    fun searchWorkOrders(
        @Param("companyId") companyId: UUID,
        @Param("keyword") keyword: String?,
        @Param("workCategory") workCategory: WorkCategory?,
        @Param("workType") workType: WorkType?,
        @Param("workStatus") workStatus: WorkStatus?,
        @Param("workPriority") workPriority: WorkPriority?,
        @Param("assignedToId") assignedToId: UUID?,
        @Param("buildingId") buildingId: UUID?,
        @Param("unitId") unitId: UUID?,
        @Param("requestedById") requestedById: UUID?,
        @Param("startDate") startDate: LocalDateTime?,
        @Param("endDate") endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<WorkOrder>
    
    /**
     * 상태별 개수 조회
     */
    fun countByCompanyCompanyIdAndWorkStatus(companyId: UUID, workStatus: WorkStatus): Long
    
    /**
     * 카테고리별 개수 조회
     */
    fun countByCompanyCompanyIdAndWorkCategory(companyId: UUID, workCategory: WorkCategory): Long
    
    /**
     * 유형별 개수 조회
     */
    fun countByCompanyCompanyIdAndWorkType(companyId: UUID, workType: WorkType): Long
    
    /**
     * 우선순위별 개수 조회
     */
    fun countByCompanyCompanyIdAndWorkPriority(companyId: UUID, workPriority: WorkPriority): Long
    
    /**
     * 지연된 작업 개수 조회
     */
    @Query("""
        SELECT COUNT(w) FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus IN ('IN_PROGRESS', 'SCHEDULED') 
        AND w.scheduledEndDate < :currentDate
    """)
    fun countDelayedWorkOrders(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDateTime
    ): Long
    
    /**
     * 완료율 계산을 위한 쿼리
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN w.workStatus = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(*) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateCompletionRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 평균 완료 시간 계산
     */
    @Query("""
        SELECT AVG(
            CASE WHEN w.actualEndDate IS NOT NULL AND w.actualStartDate IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (w.actualEndDate - w.actualStartDate)) / 86400.0 
            END
        )
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus = 'COMPLETED'
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageCompletionDays(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 정시 완료율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN w.actualEndDate <= w.scheduledEndDate THEN 1 END) * 100.0 / 
            COUNT(CASE WHEN w.actualEndDate IS NOT NULL AND w.scheduledEndDate IS NOT NULL THEN 1 END)
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus = 'COMPLETED'
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateOnTimeCompletionRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 평균 품질 평가 점수
     */
    @Query("""
        SELECT AVG(w.qualityRating) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus = 'COMPLETED'
        AND w.qualityRating > 0
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageQualityRating(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 평균 고객 만족도
     */
    @Query("""
        SELECT AVG(w.customerSatisfaction) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workStatus = 'COMPLETED'
        AND w.customerSatisfaction > 0
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageCustomerSatisfaction(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 다음 작업 지시서 번호 생성을 위한 최대 번호 조회
     */
    @Query("""
        SELECT MAX(CAST(SUBSTRING(w.workOrderNumber, LENGTH(:prefix) + 1) AS INTEGER))
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.workOrderNumber LIKE CONCAT(:prefix, '%')
    """)
    fun findMaxWorkOrderNumber(
        @Param("companyId") companyId: UUID,
        @Param("prefix") prefix: String
    ): Int?

    /**
     * 작업자별 할당된 작업 목록 조회
     */
    @Query("""
        SELECT w FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND (:status IS NULL OR w.workStatus = :status)
        AND (:startDate IS NULL OR w.requestDate >= :startDate)
        AND (:endDate IS NULL OR w.requestDate <= :endDate)
        ORDER BY w.workPriority DESC, w.requestDate ASC
    """)
    fun findWorkerAssignments(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("status") status: WorkStatus?,
        @Param("startDate") startDate: LocalDateTime?,
        @Param("endDate") endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<WorkOrder>

    /**
     * 작업자별 할당된 작업 수 조회
     */
    @Query("""
        SELECT COUNT(w) FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun countByAssignedWorker(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Long

    /**
     * 작업자별 상태별 작업 수 조회
     */
    @Query("""
        SELECT COUNT(w) FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.workStatus = :status
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun countByAssignedWorkerAndStatus(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("status") status: WorkStatus,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Long

    /**
     * 작업자별 평균 완료 시간 계산
     */
    @Query("""
        SELECT AVG(
            CASE WHEN w.actualEndDate IS NOT NULL AND w.actualStartDate IS NOT NULL 
            THEN EXTRACT(EPOCH FROM (w.actualEndDate - w.actualStartDate)) / 86400.0 
            END
        )
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.workStatus = 'COMPLETED'
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateWorkerAverageCompletionDays(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 작업자별 정시 완료율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN w.actualEndDate <= w.scheduledEndDate THEN 1 END) * 100.0 / 
            COUNT(CASE WHEN w.actualEndDate IS NOT NULL AND w.scheduledEndDate IS NOT NULL THEN 1 END)
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.workStatus = 'COMPLETED'
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateWorkerOnTimeCompletionRate(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 작업자별 평균 품질 평가 점수
     */
    @Query("""
        SELECT AVG(w.qualityRating) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.workStatus = 'COMPLETED'
        AND w.qualityRating > 0
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateWorkerAverageQualityRating(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 작업자별 총 작업 시간 계산
     */
    @Query("""
        SELECT COALESCE(SUM(w.actualDurationHours), 0) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.workStatus = 'COMPLETED'
        AND w.requestDate BETWEEN :startDate AND :endDate
    """)
    fun calculateWorkerTotalWorkingHours(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): java.math.BigDecimal?

    /**
     * 작업자별 카테고리별 작업량 조회
     */
    @Query("""
        SELECT w.workCategory, COUNT(w) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.requestDate BETWEEN :startDate AND :endDate
        GROUP BY w.workCategory
    """)
    fun getWorkerWorkloadByCategory(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Map<WorkCategory, Long>

    /**
     * 작업자별 유형별 작업량 조회
     */
    @Query("""
        SELECT w.workType, COUNT(w) 
        FROM WorkOrder w 
        WHERE w.company.companyId = :companyId 
        AND w.assignedTo.userId = :workerId
        AND w.requestDate BETWEEN :startDate AND :endDate
        GROUP BY w.workType
    """)
    fun getWorkerWorkloadByType(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Map<WorkType, Long>

    /**
     * 작업자별 월별 완료 추이 조회
     */
    @Query(
        value = """
        SELECT 
            TO_CHAR(w.actual_end_date, 'YYYY-MM') as month,
            COUNT(*) as completed_count
        FROM work_orders w 
        WHERE w.company_id = :companyId 
        AND w.assigned_to = :workerId
        AND w.work_status = 'COMPLETED'
        AND w.request_date BETWEEN :startDate AND :endDate
        GROUP BY TO_CHAR(w.actual_end_date, 'YYYY-MM')
        ORDER BY month
        """,
        nativeQuery = true
    )
    fun getWorkerMonthlyCompletionTrend(
        @Param("companyId") companyId: UUID,
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Map<String, Long>
}