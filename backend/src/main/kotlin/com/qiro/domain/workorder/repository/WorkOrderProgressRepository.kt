package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.WorkOrderProgress
import com.qiro.domain.workorder.entity.WorkPhase
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
 * 작업 진행 상황 Repository
 */
@Repository
interface WorkOrderProgressRepository : JpaRepository<WorkOrderProgress, UUID> {
    
    /**
     * 회사별 진행 상황 조회
     */
    fun findByCompanyCompanyId(companyId: UUID, pageable: Pageable): Page<WorkOrderProgress>
    
    /**
     * 작업 지시서별 진행 상황 조회
     */
    fun findByWorkOrderWorkOrderIdOrderByProgressDateDesc(workOrderId: UUID): List<WorkOrderProgress>
    
    /**
     * 작업 지시서별 진행 상황 조회 (페이징)
     */
    fun findByWorkOrderWorkOrderId(workOrderId: UUID, pageable: Pageable): Page<WorkOrderProgress>
    
    /**
     * 보고자별 진행 상황 조회
     */
    fun findByCompanyCompanyIdAndReportedByUserId(
        companyId: UUID,
        reportedById: UUID,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 단계별 진행 상황 조회
     */
    fun findByCompanyCompanyIdAndWorkPhase(
        companyId: UUID,
        workPhase: WorkPhase,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 기간별 진행 상황 조회
     */
    fun findByCompanyCompanyIdAndProgressDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 감독자 검토 상태별 조회
     */
    fun findByCompanyCompanyIdAndSupervisorReviewed(
        companyId: UUID,
        supervisorReviewed: Boolean,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 이슈가 있는 진행 상황 조회
     */
    @Query("""
        SELECT p FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND (p.issuesEncountered IS NOT NULL AND p.issuesEncountered != '')
        OR p.qualityIssuesFound > 0
    """)
    fun findProgressWithIssues(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 작업 지시서의 최신 진행 상황 조회
     */
    @Query("""
        SELECT p FROM WorkOrderProgress p 
        WHERE p.workOrder.workOrderId = :workOrderId 
        ORDER BY p.progressDate DESC 
        LIMIT 1
    """)
    fun findLatestProgressByWorkOrder(@Param("workOrderId") workOrderId: UUID): WorkOrderProgress?
    
    /**
     * 복합 검색 쿼리
     */
    @Query("""
        SELECT p FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND (:workOrderId IS NULL OR p.workOrder.workOrderId = :workOrderId)
        AND (:workPhase IS NULL OR p.workPhase = :workPhase)
        AND (:reportedById IS NULL OR p.reportedBy.userId = :reportedById)
        AND (:startDate IS NULL OR p.progressDate >= :startDate)
        AND (:endDate IS NULL OR p.progressDate <= :endDate)
        AND (:supervisorReviewed IS NULL OR p.supervisorReviewed = :supervisorReviewed)
        AND (:hasIssues IS NULL OR 
             (:hasIssues = true AND (p.issuesEncountered IS NOT NULL AND p.issuesEncountered != '' OR p.qualityIssuesFound > 0)) OR
             (:hasIssues = false AND (p.issuesEncountered IS NULL OR p.issuesEncountered = '') AND p.qualityIssuesFound = 0))
    """)
    fun searchProgress(
        @Param("companyId") companyId: UUID,
        @Param("workOrderId") workOrderId: UUID?,
        @Param("workPhase") workPhase: WorkPhase?,
        @Param("reportedById") reportedById: UUID?,
        @Param("startDate") startDate: LocalDateTime?,
        @Param("endDate") endDate: LocalDateTime?,
        @Param("supervisorReviewed") supervisorReviewed: Boolean?,
        @Param("hasIssues") hasIssues: Boolean?,
        pageable: Pageable
    ): Page<WorkOrderProgress>
    
    /**
     * 단계별 개수 조회
     */
    fun countByCompanyCompanyIdAndWorkPhase(companyId: UUID, workPhase: WorkPhase): Long
    
    /**
     * 감독자 검토율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN p.supervisorReviewed = true THEN 1 END) * 100.0 / COUNT(*) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateSupervisorReviewRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 일별 평균 진행률 계산
     */
    @Query("""
        SELECT AVG(
            CASE WHEN p.progressPercentage > LAG(p.progressPercentage) OVER (
                PARTITION BY p.workOrder.workOrderId ORDER BY p.progressDate
            ) THEN p.progressPercentage - LAG(p.progressPercentage) OVER (
                PARTITION BY p.workOrder.workOrderId ORDER BY p.progressDate
            ) ELSE 0 END
        )
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageProgressPerDay(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 총 작업 시간 계산
     */
    @Query("""
        SELECT SUM(p.hoursWorked) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateTotalHoursWorked(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 기록당 평균 작업 시간 계산
     */
    @Query("""
        SELECT AVG(p.hoursWorked) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.hoursWorked > 0
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageHoursPerRecord(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 총 품질 체크포인트 수 계산
     */
    @Query("""
        SELECT SUM(p.qualityCheckpointsCompleted) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateTotalQualityCheckpoints(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Long?
    
    /**
     * 총 품질 이슈 수 계산
     */
    @Query("""
        SELECT SUM(p.qualityIssuesFound) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateTotalQualityIssues(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Long?
    
    /**
     * 품질 이슈 해결률 계산
     */
    @Query("""
        SELECT 
            CASE WHEN SUM(p.qualityIssuesFound) > 0 
            THEN SUM(p.qualityIssuesResolved) * 100.0 / SUM(p.qualityIssuesFound) 
            ELSE 0 END
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateQualityIssueResolutionRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 평균 품질 점수 계산
     */
    @Query("""
        SELECT AVG(
            CASE WHEN p.qualityCheckpointsCompleted > 0 
            THEN (1.0 - (p.qualityIssuesFound::DECIMAL / p.qualityCheckpointsCompleted::DECIMAL) * 0.5) * 
                 (CASE WHEN p.qualityIssuesFound > 0 
                  THEN p.qualityIssuesResolved::DECIMAL / p.qualityIssuesFound::DECIMAL 
                  ELSE 1.0 END) * 10.0
            ELSE 0 END
        )
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageQualityScore(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 이슈 발생 빈도 계산 (기록당 평균 이슈 수)
     */
    @Query("""
        SELECT AVG(p.qualityIssuesFound + 
                   CASE WHEN p.issuesEncountered IS NOT NULL AND p.issuesEncountered != '' THEN 1 ELSE 0 END) 
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
    """)
    fun calculateIssueFrequency(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 일별 진행 현황 통계
     */
    @Query("""
        SELECT 
            DATE(p.progressDate) as progressDate,
            COUNT(DISTINCT p.workOrder.workOrderId) as totalWorkOrders,
            COUNT(DISTINCT CASE WHEN p.workOrder.workStatus IN ('IN_PROGRESS', 'SCHEDULED') THEN p.workOrder.workOrderId END) as activeWorkOrders,
            COUNT(DISTINCT CASE WHEN p.workOrder.workStatus = 'COMPLETED' THEN p.workOrder.workOrderId END) as completedWorkOrders,
            SUM(p.hoursWorked) as totalHoursWorked,
            AVG(p.progressPercentage) as averageProgress,
            SUM(p.qualityIssuesFound) as qualityIssuesReported,
            SUM(p.qualityIssuesResolved) as qualityIssuesResolved
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.progressDate BETWEEN :startDate AND :endDate
        GROUP BY DATE(p.progressDate)
        ORDER BY DATE(p.progressDate)
    """)
    fun getDailyProgressReport(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 작업자별 진행 현황 통계
     */
    @Query("""
        SELECT 
            p.reportedBy.userId,
            COUNT(*) as totalProgressRecords,
            SUM(p.hoursWorked) as totalHoursWorked,
            AVG(p.progressPercentage) as averageProgressPerRecord,
            SUM(p.qualityCheckpointsCompleted) as qualityCheckpointsCompleted,
            SUM(p.qualityIssuesFound) as qualityIssuesFound,
            SUM(p.qualityIssuesResolved) as qualityIssuesResolved,
            COUNT(CASE WHEN p.supervisorReviewed = true THEN 1 END) * 100.0 / COUNT(*) as supervisorReviewRate
        FROM WorkOrderProgress p 
        WHERE p.company.companyId = :companyId 
        AND p.reportedBy.userId = :reportedById
        AND p.progressDate BETWEEN :startDate AND :endDate
        GROUP BY p.reportedBy.userId
    """)
    fun getWorkerProgressReport(
        @Param("companyId") companyId: UUID,
        @Param("reportedById") reportedById: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
}