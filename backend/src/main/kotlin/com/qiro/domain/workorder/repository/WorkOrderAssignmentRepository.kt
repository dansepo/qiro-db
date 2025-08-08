package com.qiro.domain.workorder.repository

import com.qiro.domain.workorder.entity.*
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
 * 작업 지시서 배정 Repository
 */
@Repository
interface WorkOrderAssignmentRepository : JpaRepository<WorkOrderAssignment, UUID> {
    
    /**
     * 회사별 작업 배정 조회
     */
    fun findByCompanyCompanyId(companyId: UUID, pageable: Pageable): Page<WorkOrderAssignment>
    
    /**
     * 작업 지시서별 배정 조회
     */
    fun findByWorkOrderWorkOrderId(workOrderId: UUID): List<WorkOrderAssignment>
    
    /**
     * 작업자별 배정 조회
     */
    fun findByCompanyCompanyIdAndAssignedToUserId(
        companyId: UUID,
        assignedToId: UUID,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 상태별 배정 조회
     */
    fun findByCompanyCompanyIdAndAssignmentStatus(
        companyId: UUID,
        assignmentStatus: AssignmentStatus,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 수락 상태별 배정 조회
     */
    fun findByCompanyCompanyIdAndAcceptanceStatus(
        companyId: UUID,
        acceptanceStatus: AcceptanceStatus,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 역할별 배정 조회
     */
    fun findByCompanyCompanyIdAndAssignmentRole(
        companyId: UUID,
        assignmentRole: AssignmentRole,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 유형별 배정 조회
     */
    fun findByCompanyCompanyIdAndAssignmentType(
        companyId: UUID,
        assignmentType: AssignmentType,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 작업자의 활성 배정 조회
     */
    @Query("""
        SELECT a FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId 
        AND a.assignmentStatus IN ('ASSIGNED', 'ACCEPTED', 'IN_PROGRESS')
    """)
    fun findActiveAssignmentsByWorker(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID
    ): List<WorkOrderAssignment>
    
    /**
     * 작업자의 대기 중인 배정 조회
     */
    @Query("""
        SELECT a FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId 
        AND a.acceptanceStatus = 'PENDING'
        ORDER BY a.assignedDate ASC
    """)
    fun findPendingAssignmentsByWorker(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID
    ): List<WorkOrderAssignment>
    
    /**
     * 기간별 배정 조회
     */
    fun findByCompanyCompanyIdAndAssignedDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 복합 검색 쿼리
     */
    @Query("""
        SELECT a FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND (:workOrderId IS NULL OR a.workOrder.workOrderId = :workOrderId)
        AND (:assignedToId IS NULL OR a.assignedTo.userId = :assignedToId)
        AND (:assignmentRole IS NULL OR a.assignmentRole = :assignmentRole)
        AND (:assignmentStatus IS NULL OR a.assignmentStatus = :assignmentStatus)
        AND (:acceptanceStatus IS NULL OR a.acceptanceStatus = :acceptanceStatus)
        AND (:startDate IS NULL OR a.assignedDate >= :startDate)
        AND (:endDate IS NULL OR a.assignedDate <= :endDate)
    """)
    fun searchAssignments(
        @Param("companyId") companyId: UUID,
        @Param("workOrderId") workOrderId: UUID?,
        @Param("assignedToId") assignedToId: UUID?,
        @Param("assignmentRole") assignmentRole: AssignmentRole?,
        @Param("assignmentStatus") assignmentStatus: AssignmentStatus?,
        @Param("acceptanceStatus") acceptanceStatus: AcceptanceStatus?,
        @Param("startDate") startDate: LocalDateTime?,
        @Param("endDate") endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<WorkOrderAssignment>
    
    /**
     * 작업자별 배정 통계
     */
    @Query("""
        SELECT a.assignedTo.userId,
               COUNT(*) as totalAssignments,
               COUNT(CASE WHEN a.assignmentStatus IN ('ASSIGNED', 'ACCEPTED', 'IN_PROGRESS') THEN 1 END) as activeAssignments,
               COUNT(CASE WHEN a.assignmentStatus = 'COMPLETED' THEN 1 END) as completedAssignments,
               AVG(CASE WHEN a.performanceRating > 0 THEN a.performanceRating END) as avgPerformanceRating,
               AVG(CASE WHEN a.qualityScore > 0 THEN a.qualityScore END) as avgQualityScore,
               AVG(CASE WHEN a.timelinessScore > 0 THEN a.timelinessScore END) as avgTimelinessScore,
               SUM(a.allocatedHours) as totalAllocatedHours,
               SUM(a.actualHours) as totalActualHours
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId
        AND a.assignedDate BETWEEN :startDate AND :endDate
        GROUP BY a.assignedTo.userId
    """)
    fun getWorkerAssignmentStatistics(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 상태별 개수 조회
     */
    fun countByCompanyCompanyIdAndAssignmentStatus(companyId: UUID, assignmentStatus: AssignmentStatus): Long
    
    /**
     * 수락 상태별 개수 조회
     */
    fun countByCompanyCompanyIdAndAcceptanceStatus(companyId: UUID, acceptanceStatus: AcceptanceStatus): Long
    
    /**
     * 역할별 개수 조회
     */
    fun countByCompanyCompanyIdAndAssignmentRole(companyId: UUID, assignmentRole: AssignmentRole): Long
    
    /**
     * 유형별 개수 조회
     */
    fun countByCompanyCompanyIdAndAssignmentType(companyId: UUID, assignmentType: AssignmentType): Long
    
    /**
     * 작업자별 현재 워크로드 계산
     */
    @Query("""
        SELECT SUM(a.workPercentage) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId 
        AND a.assignmentStatus IN ('ASSIGNED', 'ACCEPTED', 'IN_PROGRESS')
    """)
    fun calculateCurrentWorkload(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID
    ): Long?
    
    /**
     * 수락률 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN a.acceptanceStatus = 'ACCEPTED' THEN 1 END) * 100.0 / COUNT(*) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAcceptanceRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 완료율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN a.assignmentStatus = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(*) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateCompletionRate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 평균 성과 평가 점수
     */
    @Query("""
        SELECT AVG(a.performanceRating) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignmentStatus = 'COMPLETED'
        AND a.performanceRating > 0
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAveragePerformanceRating(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 평균 품질 점수
     */
    @Query("""
        SELECT AVG(a.qualityScore) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignmentStatus = 'COMPLETED'
        AND a.qualityScore > 0
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageQualityScore(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 평균 시간 준수 점수
     */
    @Query("""
        SELECT AVG(a.timelinessScore) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignmentStatus = 'COMPLETED'
        AND a.timelinessScore > 0
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageTimelinessScore(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
    
    /**
     * 작업자의 정시 완료율 계산
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN a.completedDate <= a.expectedEndDate THEN 1 END) * 100.0 / 
            COUNT(CASE WHEN a.completedDate IS NOT NULL AND a.expectedEndDate IS NOT NULL THEN 1 END)
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId
        AND a.assignmentStatus = 'COMPLETED'
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateWorkerOnTimeCompletionRate(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?
    
    /**
     * 작업자별 평균 배정당 작업 시간
     */
    @Query("""
        SELECT AVG(a.actualHours) 
        FROM WorkOrderAssignment a 
        WHERE a.company.companyId = :companyId 
        AND a.assignedTo.userId = :assignedToId
        AND a.assignmentStatus = 'COMPLETED'
        AND a.actualHours > 0
        AND a.assignedDate BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageHoursPerAssignment(
        @Param("companyId") companyId: UUID,
        @Param("assignedToId") assignedToId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): BigDecimal?
}