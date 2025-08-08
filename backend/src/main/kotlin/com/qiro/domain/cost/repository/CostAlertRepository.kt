package com.qiro.domain.cost.repository

import com.qiro.domain.cost.entity.CostAlert
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 경고 Repository
 */
@Repository
interface CostAlertRepository : JpaRepository<CostAlert, UUID> {
    
    /**
     * 회사별 경고 조회
     */
    fun findByCompanyCompanyIdOrderByTriggeredAtDesc(companyId: UUID, pageable: Pageable): Page<CostAlert>
    
    /**
     * 예산별 경고 조회
     */
    fun findByBudgetBudgetIdOrderByTriggeredAtDesc(budgetId: UUID): List<CostAlert>
    
    /**
     * 경고 유형별 조회
     */
    fun findByCompanyCompanyIdAndAlertTypeOrderByTriggeredAtDesc(
        companyId: UUID, 
        alertType: CostAlert.AlertType,
        pageable: Pageable
    ): Page<CostAlert>
    
    /**
     * 경고 심각도별 조회
     */
    fun findByCompanyCompanyIdAndAlertSeverityOrderByTriggeredAtDesc(
        companyId: UUID, 
        alertSeverity: CostAlert.AlertSeverity,
        pageable: Pageable
    ): Page<CostAlert>
    
    /**
     * 경고 상태별 조회
     */
    fun findByCompanyCompanyIdAndAlertStatusOrderByTriggeredAtDesc(
        companyId: UUID, 
        alertStatus: CostAlert.AlertStatus,
        pageable: Pageable
    ): Page<CostAlert>
    
    /**
     * 활성 경고 조회
     */
    fun findByCompanyCompanyIdAndAlertStatusInOrderByAlertSeverityDescTriggeredAtDesc(
        companyId: UUID,
        alertStatuses: List<CostAlert.AlertStatus>
    ): List<CostAlert>
    
    /**
     * 미해결 경고 조회
     */
    fun findByCompanyCompanyIdAndAlertStatusNotInOrderByTriggeredAtDesc(
        companyId: UUID,
        resolvedStatuses: List<CostAlert.AlertStatus>
    ): List<CostAlert>
    
    /**
     * 위험 수준 경고 조회
     */
    fun findByCompanyCompanyIdAndAlertSeverityInAndAlertStatusOrderByTriggeredAtDesc(
        companyId: UUID,
        severities: List<CostAlert.AlertSeverity>,
        alertStatus: CostAlert.AlertStatus
    ): List<CostAlert>
    
    /**
     * 에스컬레이션 필요한 경고 조회
     */
    @Query("""
        SELECT a FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.alertStatus = 'ACTIVE'
        AND a.triggeredAt < :thresholdTime
        AND a.escalationLevel < 3
        ORDER BY a.triggeredAt ASC
    """)
    fun findAlertsNeedingEscalation(
        @Param("companyId") companyId: UUID,
        @Param("thresholdTime") thresholdTime: LocalDateTime
    ): List<CostAlert>
    
    /**
     * 억제된 경고 조회 (억제 기간 만료)
     */
    @Query("""
        SELECT a FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.alertStatus = 'SUPPRESSED'
        AND a.suppressedUntil < :currentTime
        ORDER BY a.suppressedUntil ASC
    """)
    fun findExpiredSuppressedAlerts(
        @Param("companyId") companyId: UUID,
        @Param("currentTime") currentTime: LocalDateTime
    ): List<CostAlert>
    
    /**
     * 알림 미발송 경고 조회
     */
    fun findByCompanyCompanyIdAndNotificationSentFalseAndAlertStatusOrderByTriggeredAtDesc(
        companyId: UUID,
        alertStatus: CostAlert.AlertStatus
    ): List<CostAlert>
    
    /**
     * 재발성 경고 조회
     */
    @Query("""
        SELECT a FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.recurrenceCount > 1
        ORDER BY a.recurrenceCount DESC, a.lastOccurrence DESC
    """)
    fun findRecurringAlerts(@Param("companyId") companyId: UUID): List<CostAlert>
    
    /**
     * 경고 유형별 통계 조회
     */
    @Query("""
        SELECT a.alertType, 
               COUNT(a) as totalCount,
               COUNT(CASE WHEN a.alertStatus = 'ACTIVE' THEN 1 END) as activeCount,
               COUNT(CASE WHEN a.alertStatus = 'RESOLVED' THEN 1 END) as resolvedCount,
               AVG(a.recurrenceCount) as avgRecurrence
        FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.triggeredAt BETWEEN :startDate AND :endDate
        GROUP BY a.alertType
        ORDER BY totalCount DESC
    """)
    fun findAlertStatisticsByType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 경고 심각도별 통계 조회
     */
    @Query("""
        SELECT a.alertSeverity, 
               COUNT(a) as totalCount,
               COUNT(CASE WHEN a.alertStatus = 'ACTIVE' THEN 1 END) as activeCount,
               AVG(CASE WHEN a.resolvedAt IS NOT NULL 
                   THEN EXTRACT(EPOCH FROM (a.resolvedAt - a.triggeredAt))/3600 
                   END) as avgResolutionHours
        FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.triggeredAt BETWEEN :startDate AND :endDate
        GROUP BY a.alertSeverity
        ORDER BY a.alertSeverity DESC
    """)
    fun findAlertStatisticsBySeverity(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 일별 경고 발생 추세 조회
     */
    @Query("""
        SELECT DATE(a.triggeredAt) as alertDate,
               COUNT(a) as dailyCount,
               COUNT(CASE WHEN a.alertSeverity = 'CRITICAL' THEN 1 END) as criticalCount
        FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.triggeredAt BETWEEN :startDate AND :endDate
        GROUP BY DATE(a.triggeredAt)
        ORDER BY alertDate DESC
    """)
    fun findDailyAlertTrend(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 예산별 경고 발생 빈도 조회
     */
    @Query("""
        SELECT a.budget.budgetId,
               a.budget.budgetName,
               COUNT(a) as alertCount,
               MAX(a.triggeredAt) as lastAlertTime
        FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.budget IS NOT NULL
        AND a.triggeredAt BETWEEN :startDate AND :endDate
        GROUP BY a.budget.budgetId, a.budget.budgetName
        ORDER BY alertCount DESC
    """)
    fun findAlertFrequencyByBudget(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 해결 시간 분석 조회
     */
    @Query("""
        SELECT a.alertType,
               AVG(EXTRACT(EPOCH FROM (a.resolvedAt - a.triggeredAt))/3600) as avgResolutionHours,
               MIN(EXTRACT(EPOCH FROM (a.resolvedAt - a.triggeredAt))/3600) as minResolutionHours,
               MAX(EXTRACT(EPOCH FROM (a.resolvedAt - a.triggeredAt))/3600) as maxResolutionHours
        FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.alertStatus = 'RESOLVED'
        AND a.resolvedAt IS NOT NULL
        AND a.triggeredAt BETWEEN :startDate AND :endDate
        GROUP BY a.alertType
        ORDER BY avgResolutionHours DESC
    """)
    fun findResolutionTimeAnalysis(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>
    
    /**
     * 중복 경고 조회 (같은 예산, 같은 유형)
     */
    @Query("""
        SELECT a FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.budget.budgetId = :budgetId
        AND a.alertType = :alertType
        AND a.alertStatus = 'ACTIVE'
        ORDER BY a.triggeredAt DESC
    """)
    fun findDuplicateAlerts(
        @Param("companyId") companyId: UUID,
        @Param("budgetId") budgetId: UUID,
        @Param("alertType") alertType: CostAlert.AlertType
    ): List<CostAlert>
    
    /**
     * 자동 해결된 경고 조회
     */
    fun findByCompanyCompanyIdAndAutoResolvedTrueOrderByResolvedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<CostAlert>
    
    /**
     * 에스컬레이션 이력 조회
     */
    @Query("""
        SELECT a FROM CostAlert a 
        WHERE a.company.companyId = :companyId 
        AND a.escalationLevel > 0
        ORDER BY a.escalationLevel DESC, a.escalatedAt DESC
    """)
    fun findEscalatedAlerts(@Param("companyId") companyId: UUID): List<CostAlert>
}