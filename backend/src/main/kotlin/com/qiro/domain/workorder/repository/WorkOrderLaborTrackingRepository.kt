package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.WorkOrderLaborTracking
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 인력 시간 추적 Repository
 */
@Repository
interface WorkOrderLaborTrackingRepository : JpaRepository<WorkOrderLaborTracking, UUID> {
    
    /**
     * 작업 지시서별 인력 시간 추적 조회
     */
    fun findByWorkOrderIdOrderByWorkDateDesc(workOrderId: UUID): List<WorkOrderLaborTracking>
    
    /**
     * 작업자별 인력 시간 추적 조회
     */
    fun findByWorkerIdOrderByWorkDateDesc(workerId: UUID): List<WorkOrderLaborTracking>
    
    /**
     * 할당별 인력 시간 추적 조회
     */
    fun findByAssignmentIdOrderByWorkDateDesc(assignmentId: UUID): List<WorkOrderLaborTracking>
    
    /**
     * 작업 역할별 인력 시간 추적 조회
     */
    fun findByWorkerRoleOrderByWorkDateDesc(
        workerRole: WorkOrderLaborTracking.WorkerRole
    ): List<WorkOrderLaborTracking>
    
    /**
     * 기술 수준별 인력 시간 추적 조회
     */
    fun findBySkillLevelOrderByWorkDateDesc(
        skillLevel: WorkOrderLaborTracking.SkillLevel
    ): List<WorkOrderLaborTracking>
    
    /**
     * 작업 단계별 인력 시간 추적 조회
     */
    fun findByWorkPhaseOrderByWorkDateDesc(
        workPhase: WorkOrderLaborTracking.WorkPhase
    ): List<WorkOrderLaborTracking>
    
    /**
     * 추적 상태별 인력 시간 추적 조회
     */
    fun findByTrackingStatusOrderByWorkDateDesc(
        trackingStatus: WorkOrderLaborTracking.TrackingStatus
    ): List<WorkOrderLaborTracking>
    
    /**
     * 승인 대기 중인 인력 시간 추적 조회
     */
    fun findByApprovedByIsNullOrderByWorkDateDesc(): List<WorkOrderLaborTracking>
    
    /**
     * 승인된 인력 시간 추적 조회
     */
    fun findByApprovedByIsNotNullOrderByWorkDateDesc(): List<WorkOrderLaborTracking>
    
    /**
     * 기간별 인력 시간 추적 조회
     */
    fun findByWorkDateBetweenOrderByWorkDateDesc(
        startDate: LocalDate,
        endDate: LocalDate
    ): List<WorkOrderLaborTracking>
    
    /**
     * 회사별 기간별 인력 시간 추적 조회
     */
    fun findByCompanyIdAndWorkDateBetweenOrderByWorkDateDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<WorkOrderLaborTracking>
    
    /**
     * 작업자별 기간별 인력 시간 추적 조회
     */
    fun findByWorkerIdAndWorkDateBetweenOrderByWorkDateDesc(
        workerId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<WorkOrderLaborTracking>
    
    /**
     * 초과 근무가 있는 인력 시간 추적 조회
     */
    @Query("""
        SELECT t FROM WorkOrderLaborTracking t
        WHERE t.overtimeHours > 0
        ORDER BY t.workDate DESC
    """)
    fun findWithOvertimeOrderByWorkDateDesc(): List<WorkOrderLaborTracking>
    
    /**
     * 복합 조건 검색 - 작업 지시서, 작업자, 기간
     */
    fun findByWorkOrderIdAndWorkerIdAndWorkDateBetween(
        workOrderId: UUID,
        workerId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<WorkOrderLaborTracking>
    
    /**
     * 복합 조건 검색 - 작업 지시서, 역할, 상태
     */
    fun findByWorkOrderIdAndWorkerRoleAndTrackingStatus(
        workOrderId: UUID,
        workerRole: WorkOrderLaborTracking.WorkerRole,
        trackingStatus: WorkOrderLaborTracking.TrackingStatus
    ): List<WorkOrderLaborTracking>
    
    /**
     * 페이징 조회 - 회사별 기간별
     */
    fun findByCompanyIdAndWorkDateBetween(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        pageable: Pageable
    ): Page<WorkOrderLaborTracking>
    
    /**
     * 작업 지시서별 총 작업 시간 계산
     */
    @Query("""
        SELECT COALESCE(SUM(t.actualWorkHours), 0)
        FROM WorkOrderLaborTracking t
        WHERE t.workOrderId = :workOrderId
        AND t.trackingStatus != 'REJECTED'
    """)
    fun calculateTotalWorkHoursByWorkOrder(@Param("workOrderId") workOrderId: UUID): BigDecimal
    
    /**
     * 작업 지시서별 총 인력 비용 계산
     */
    @Query("""
        SELECT COALESCE(SUM(t.totalLaborCost), 0)
        FROM WorkOrderLaborTracking t
        WHERE t.workOrderId = :workOrderId
        AND t.trackingStatus != 'REJECTED'
    """)
    fun calculateTotalLaborCostByWorkOrder(@Param("workOrderId") workOrderId: UUID): BigDecimal
    
    /**
     * 작업자별 총 작업 시간 계산
     */
    @Query("""
        SELECT COALESCE(SUM(t.actualWorkHours), 0)
        FROM WorkOrderLaborTracking t
        WHERE t.workerId = :workerId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
    """)
    fun calculateTotalWorkHoursByWorker(
        @Param("workerId") workerId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal
    
    /**
     * 기간별 인력 시간 통계
     */
    @Query("""
        SELECT new map(
            COUNT(t) as totalRecords,
            COALESCE(SUM(t.actualWorkHours), 0) as totalWorkHours,
            COALESCE(SUM(t.regularHours), 0) as totalRegularHours,
            COALESCE(SUM(t.overtimeHours), 0) as totalOvertimeHours,
            COALESCE(SUM(t.totalLaborCost), 0) as totalLaborCost,
            COALESCE(AVG(t.hourlyRate), 0) as averageHourlyRate,
            COALESCE(AVG(t.productivityScore), 0) as averageProductivityScore,
            COALESCE(AVG(t.qualityScore), 0) as averageQualityScore,
            COALESCE(AVG(t.safetyScore), 0) as averageSafetyScore
        )
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
    """)
    fun getLaborTrackingStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Map<String, Any>
    
    /**
     * 추적 상태별 통계
     */
    @Query("""
        SELECT t.trackingStatus, COUNT(t)
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        GROUP BY t.trackingStatus
    """)
    fun getTrackingCountByStatus(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>
    
    /**
     * 작업 역할별 통계
     */
    @Query("""
        SELECT t.workerRole, COUNT(t)
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        GROUP BY t.workerRole
    """)
    fun getTrackingCountByRole(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>
    
    /**
     * 기술 수준별 통계
     */
    @Query("""
        SELECT t.skillLevel, COUNT(t)
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        GROUP BY t.skillLevel
    """)
    fun getTrackingCountBySkillLevel(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>
    
    /**
     * 작업자별 성과 요약
     */
    @Query("""
        SELECT new map(
            t.workerId as workerId,
            COALESCE(SUM(t.actualWorkHours), 0) as totalWorkHours,
            COALESCE(SUM(t.totalLaborCost), 0) as totalLaborCost,
            COALESCE(AVG(t.hourlyRate), 0) as averageHourlyRate,
            COALESCE(AVG(t.productivityScore), 0) as averageProductivityScore,
            COALESCE(AVG(t.qualityScore), 0) as averageQualityScore,
            COALESCE(AVG(t.safetyScore), 0) as averageSafetyScore,
            COALESCE(SUM(t.overtimeHours), 0) as overtimeHours,
            COUNT(t) as completedTasks
        )
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
        GROUP BY t.workerId
    """)
    fun getWorkerPerformanceSummary(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Map<String, Any>>
    
    /**
     * 승인율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN t.approvedBy IS NOT NULL THEN 1 END) * 100.0 / COUNT(t)
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
    """)
    fun getApprovalRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal?
    
    /**
     * 초과 근무 비율 계산
     */
    @Query("""
        SELECT 
            COALESCE(SUM(t.overtimeHours), 0) * 100.0 / COALESCE(SUM(t.actualWorkHours), 1)
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
    """)
    fun getOvertimePercentage(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal?
    
    /**
     * 일별 작업 시간 추이 데이터
     */
    @Query("""
        SELECT 
            t.workDate as workDate,
            COALESCE(SUM(t.actualWorkHours), 0) as totalHours,
            COALESCE(SUM(t.totalLaborCost), 0) as totalCost,
            COUNT(DISTINCT t.workerId) as workerCount
        FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        AND t.workDate BETWEEN :startDate AND :endDate
        AND t.trackingStatus != 'REJECTED'
        GROUP BY t.workDate
        ORDER BY t.workDate
    """)
    fun getDailyLaborTrend(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>
    
    /**
     * 최근 인력 시간 추적 조회 (Top N)
     */
    @Query("""
        SELECT t FROM WorkOrderLaborTracking t
        WHERE t.companyId = :companyId
        ORDER BY t.workDate DESC, t.createdAt DESC
        LIMIT :limit
    """)
    fun findRecentTrackings(
        @Param("companyId") companyId: UUID,
        @Param("limit") limit: Int
    ): List<WorkOrderLaborTracking>
}