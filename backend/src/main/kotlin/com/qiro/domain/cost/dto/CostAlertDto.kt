package com.qiro.domain.cost.dto

import com.qiro.domain.cost.entity.CostAlert
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 경고 DTO
 */
data class CostAlertDto(
    val alertId: UUID,
    val companyId: UUID,
    val budgetId: UUID? = null,
    val budgetName: String? = null,
    val alertType: CostAlert.AlertType,
    val alertSeverity: CostAlert.AlertSeverity,
    val alertTitle: String,
    val alertMessage: String,
    val thresholdValue: BigDecimal? = null,
    val currentValue: BigDecimal? = null,
    val varianceAmount: BigDecimal? = null,
    val variancePercentage: BigDecimal? = null,
    val alertStatus: CostAlert.AlertStatus,
    val triggeredAt: LocalDateTime,
    val resolvedAt: LocalDateTime? = null,
    val resolvedBy: UUID? = null,
    val resolvedByName: String? = null,
    val resolutionNotes: String? = null,
    val autoResolved: Boolean,
    val notificationSent: Boolean,
    val notificationSentAt: LocalDateTime? = null,
    val escalationLevel: Int,
    val escalatedAt: LocalDateTime? = null,
    val suppressedUntil: LocalDateTime? = null,
    val recurrenceCount: Int,
    val lastOccurrence: LocalDateTime,
    val metadata: String? = null,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(entity: CostAlert): CostAlertDto {
            return CostAlertDto(
                alertId = entity.alertId,
                companyId = entity.company.companyId,
                budgetId = entity.budget?.budgetId,
                budgetName = entity.budget?.budgetName,
                alertType = entity.alertType,
                alertSeverity = entity.alertSeverity,
                alertTitle = entity.alertTitle,
                alertMessage = entity.alertMessage,
                thresholdValue = entity.thresholdValue,
                currentValue = entity.currentValue,
                varianceAmount = entity.varianceAmount,
                variancePercentage = entity.variancePercentage,
                alertStatus = entity.alertStatus,
                triggeredAt = entity.triggeredAt,
                resolvedAt = entity.resolvedAt,
                resolvedBy = entity.resolvedBy?.userId,
                resolutionNotes = entity.resolutionNotes,
                autoResolved = entity.autoResolved,
                notificationSent = entity.notificationSent,
                notificationSentAt = entity.notificationSentAt,
                escalationLevel = entity.escalationLevel,
                escalatedAt = entity.escalatedAt,
                suppressedUntil = entity.suppressedUntil,
                recurrenceCount = entity.recurrenceCount,
                lastOccurrence = entity.lastOccurrence,
                metadata = entity.metadata,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
}

/**
 * 경고 생성 요청 DTO
 */
data class CreateCostAlertRequest(
    val budgetId: UUID? = null,
    val alertType: CostAlert.AlertType,
    val alertSeverity: CostAlert.AlertSeverity,
    val alertTitle: String,
    val alertMessage: String,
    val thresholdValue: BigDecimal? = null,
    val currentValue: BigDecimal? = null,
    val varianceAmount: BigDecimal? = null,
    val variancePercentage: BigDecimal? = null,
    val metadata: String? = null
)

/**
 * 경고 해결 요청 DTO
 */
data class ResolveCostAlertRequest(
    val resolutionNotes: String? = null
)

/**
 * 경고 억제 요청 DTO
 */
data class SuppressCostAlertRequest(
    val suppressDurationMinutes: Long,
    val reason: String? = null
)

/**
 * 경고 통계 DTO
 */
data class AlertStatisticsDto(
    val alertType: CostAlert.AlertType,
    val totalCount: Long,
    val activeCount: Long,
    val resolvedCount: Long,
    val averageRecurrence: BigDecimal,
    val averageResolutionHours: BigDecimal? = null
)

/**
 * 경고 심각도별 통계 DTO
 */
data class AlertStatisticsBySeverityDto(
    val alertSeverity: CostAlert.AlertSeverity,
    val totalCount: Long,
    val activeCount: Long,
    val averageResolutionHours: BigDecimal? = null
)

/**
 * 일별 경고 추세 DTO
 */
data class DailyAlertTrendDto(
    val alertDate: String,
    val dailyCount: Long,
    val criticalCount: Long
)

/**
 * 예산별 경고 빈도 DTO
 */
data class AlertFrequencyByBudgetDto(
    val budgetId: UUID,
    val budgetName: String,
    val alertCount: Long,
    val lastAlertTime: LocalDateTime
)

/**
 * 경고 해결 시간 분석 DTO
 */
data class AlertResolutionAnalysisDto(
    val alertType: CostAlert.AlertType,
    val averageResolutionHours: BigDecimal,
    val minResolutionHours: BigDecimal,
    val maxResolutionHours: BigDecimal,
    val totalResolved: Long
)

/**
 * 경고 필터 DTO
 */
data class AlertFilterDto(
    val alertTypes: List<CostAlert.AlertType>? = null,
    val alertSeverities: List<CostAlert.AlertSeverity>? = null,
    val alertStatuses: List<CostAlert.AlertStatus>? = null,
    val budgetId: UUID? = null,
    val startDate: LocalDateTime? = null,
    val endDate: LocalDateTime? = null,
    val escalationLevel: Int? = null,
    val autoResolved: Boolean? = null,
    val notificationSent: Boolean? = null,
    val minRecurrenceCount: Int? = null
)

/**
 * 경고 대시보드 DTO
 */
data class AlertDashboardDto(
    val totalActiveAlerts: Long,
    val criticalAlerts: Long,
    val highAlerts: Long,
    val mediumAlerts: Long,
    val lowAlerts: Long,
    val escalatedAlerts: Long,
    val recurringAlerts: Long,
    val averageResolutionTime: BigDecimal,
    val alertsByType: List<AlertStatisticsDto>,
    val alertsBySeverity: List<AlertStatisticsBySeverityDto>,
    val dailyTrend: List<DailyAlertTrendDto>,
    val budgetAlertFrequency: List<AlertFrequencyByBudgetDto>,
    val resolutionAnalysis: List<AlertResolutionAnalysisDto>,
    val recentCriticalAlerts: List<CostAlertDto>,
    val pendingEscalation: List<CostAlertDto>,
    val dashboardDate: LocalDateTime = LocalDateTime.now()
)

/**
 * 경고 요약 DTO
 */
data class AlertSummaryDto(
    val totalAlerts: Long,
    val activeAlerts: Long,
    val resolvedAlerts: Long,
    val suppressedAlerts: Long,
    val criticalAlerts: Long,
    val escalatedAlerts: Long,
    val autoResolvedAlerts: Long,
    val averageResolutionHours: BigDecimal,
    val alertResolutionRate: BigDecimal,
    val period: String
)

/**
 * 경고 성과 지표 DTO
 */
data class AlertPerformanceDto(
    val totalAlertsGenerated: Long,
    val alertsResolved: Long,
    val alertsAutoResolved: Long,
    val averageResolutionTime: BigDecimal,
    val escalationRate: BigDecimal,
    val recurrenceRate: BigDecimal,
    val falsePositiveRate: BigDecimal,
    val alertEffectivenessScore: BigDecimal
)

/**
 * 경고 에스컬레이션 정보 DTO
 */
data class AlertEscalationDto(
    val alertId: UUID,
    val alertTitle: String,
    val alertSeverity: CostAlert.AlertSeverity,
    val escalationLevel: Int,
    val triggeredAt: LocalDateTime,
    val escalatedAt: LocalDateTime? = null,
    val timeSinceTriggered: Long, // 분 단위
    val budgetName: String? = null,
    val currentValue: BigDecimal? = null,
    val thresholdValue: BigDecimal? = null
)