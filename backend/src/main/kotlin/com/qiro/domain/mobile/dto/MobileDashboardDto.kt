package com.qiro.domain.mobile.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 모바일 대시보드 DTO
 */
data class MobileDashboardDto(
    val userRole: String,
    val userName: String,
    val lastLoginAt: LocalDateTime?,
    val summary: DashboardSummaryDto,
    val todayTasks: TodayTasksDto,
    val urgentItems: UrgentItemsDto,
    val recentActivities: List<RecentActivityDto> = emptyList(),
    val quickActions: List<QuickActionDto> = emptyList(),
    val notifications: List<NotificationDto> = emptyList(),
    val weatherInfo: WeatherInfoDto? = null,
    val refreshedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * 대시보드 요약 DTO
 */
data class DashboardSummaryDto(
    val totalFaultReports: Int,
    val activeFaultReports: Int,
    val totalWorkOrders: Int,
    val activeWorkOrders: Int,
    val completedToday: Int,
    val overdueItems: Int,
    val upcomingMaintenance: Int,
    val criticalAlerts: Int
)

/**
 * 오늘의 작업 DTO
 */
data class TodayTasksDto(
    val scheduledWorkOrders: List<MobileWorkOrderListDto> = emptyList(),
    val dueMaintenance: List<MaintenanceTaskDto> = emptyList(),
    val pendingApprovals: List<PendingApprovalDto> = emptyList(),
    val totalHoursScheduled: BigDecimal = BigDecimal.ZERO,
    val completionRate: BigDecimal = BigDecimal.ZERO
)

/**
 * 긴급 항목 DTO
 */
data class UrgentItemsDto(
    val emergencyFaultReports: List<MobileFaultReportListDto> = emptyList(),
    val overdueWorkOrders: List<MobileWorkOrderListDto> = emptyList(),
    val criticalMaintenanceAlerts: List<MaintenanceAlertDto> = emptyList(),
    val budgetAlerts: List<BudgetAlertSummaryDto> = emptyList()
)

/**
 * 최근 활동 DTO
 */
data class RecentActivityDto(
    val activityId: UUID,
    val activityType: ActivityType,
    val title: String,
    val description: String,
    val performedBy: String,
    val performedAt: LocalDateTime,
    val entityId: UUID?,
    val entityType: String?,
    val icon: String? = null,
    val color: String? = null
)

/**
 * 활동 유형 열거형
 */
enum class ActivityType {
    FAULT_REPORTED,         // 고장 신고됨
    WORK_ORDER_CREATED,     // 작업 지시서 생성됨
    WORK_ORDER_COMPLETED,   // 작업 지시서 완료됨
    MAINTENANCE_PERFORMED,  // 정비 수행됨
    ASSET_UPDATED,         // 자산 업데이트됨
    COST_RECORDED,         // 비용 기록됨
    BUDGET_ALERT,          // 예산 경고
    USER_LOGIN,            // 사용자 로그인
    SYSTEM_ALERT           // 시스템 알림
}

/**
 * 빠른 작업 DTO
 */
data class QuickActionDto(
    val actionId: String,
    val title: String,
    val description: String,
    val icon: String,
    val color: String,
    val actionUrl: String,
    val requiresPermission: String? = null,
    val isEnabled: Boolean = true
)

/**
 * 알림 DTO
 */
data class NotificationDto(
    val notificationId: UUID,
    val title: String,
    val message: String,
    val type: NotificationType,
    val priority: NotificationPriority,
    val isRead: Boolean = false,
    val createdAt: LocalDateTime,
    val expiresAt: LocalDateTime? = null,
    val actionUrl: String? = null,
    val actionText: String? = null,
    val icon: String? = null,
    val color: String? = null
)

/**
 * 알림 유형 열거형
 */
enum class NotificationType {
    INFO,           // 정보
    WARNING,        // 경고
    ERROR,          // 오류
    SUCCESS,        // 성공
    REMINDER,       // 리마인더
    URGENT          // 긴급
}

/**
 * 알림 우선순위 열거형
 */
enum class NotificationPriority {
    LOW,            // 낮음
    NORMAL,         // 보통
    HIGH,           // 높음
    CRITICAL        // 위험
}

/**
 * 정비 작업 DTO
 */
data class MaintenanceTaskDto(
    val maintenanceId: UUID,
    val title: String,
    val assetName: String,
    val location: String,
    val dueDate: LocalDate,
    val priority: String,
    val estimatedDuration: Int, // 분 단위
    val assignedTechnician: String?,
    val isOverdue: Boolean = false
)

/**
 * 승인 대기 DTO
 */
data class PendingApprovalDto(
    val approvalId: UUID,
    val type: String, // WORK_ORDER, COST, BUDGET 등
    val title: String,
    val requestedBy: String,
    val requestedAt: LocalDateTime,
    val amount: BigDecimal? = null,
    val priority: String,
    val canApprove: Boolean = true
)

/**
 * 정비 알림 DTO
 */
data class MaintenanceAlertDto(
    val alertId: UUID,
    val assetName: String,
    val location: String,
    val alertType: String, // OVERDUE, DUE_SOON, CRITICAL
    val dueDate: LocalDate,
    val daysOverdue: Int = 0,
    val priority: String
)

/**
 * 예산 알림 요약 DTO
 */
data class BudgetAlertSummaryDto(
    val budgetName: String,
    val category: String,
    val utilizationPercentage: BigDecimal,
    val alertLevel: String, // WARNING, CRITICAL
    val remainingAmount: BigDecimal
)

/**
 * 날씨 정보 DTO
 */
data class WeatherInfoDto(
    val location: String,
    val temperature: Double,
    val condition: String,
    val humidity: Int,
    val windSpeed: Double,
    val icon: String,
    val lastUpdated: LocalDateTime
)

/**
 * 작업자 성과 DTO
 */
data class TechnicianPerformanceDto(
    val technicianId: UUID,
    val technicianName: String,
    val period: String, // DAILY, WEEKLY, MONTHLY
    val completedWorkOrders: Int,
    val averageCompletionTime: BigDecimal, // 시간 단위
    val qualityRating: BigDecimal, // 1-5 점수
    val onTimeCompletionRate: BigDecimal, // 백분율
    val totalHoursWorked: BigDecimal,
    val costEfficiency: BigDecimal, // 예산 대비 실제 비용 비율
    val customerSatisfaction: BigDecimal? = null, // 1-5 점수
    val badges: List<PerformanceBadgeDto> = emptyList()
)

/**
 * 성과 배지 DTO
 */
data class PerformanceBadgeDto(
    val badgeId: String,
    val name: String,
    val description: String,
    val icon: String,
    val color: String,
    val earnedAt: LocalDateTime
)

/**
 * 모바일 설정 DTO
 */
data class MobileSettingsDto(
    val userId: UUID,
    val notificationSettings: NotificationSettingsDto,
    val displaySettings: DisplaySettingsDto,
    val locationSettings: LocationSettingsDto,
    val syncSettings: SyncSettingsDto
)

/**
 * 알림 설정 DTO
 */
data class NotificationSettingsDto(
    val pushNotifications: Boolean = true,
    val emailNotifications: Boolean = true,
    val smsNotifications: Boolean = false,
    val workOrderAlerts: Boolean = true,
    val maintenanceReminders: Boolean = true,
    val emergencyAlerts: Boolean = true,
    val budgetAlerts: Boolean = true,
    val quietHoursStart: String? = null, // HH:mm 형식
    val quietHoursEnd: String? = null // HH:mm 형식
)

/**
 * 화면 설정 DTO
 */
data class DisplaySettingsDto(
    val theme: String = "AUTO", // LIGHT, DARK, AUTO
    val fontSize: String = "MEDIUM", // SMALL, MEDIUM, LARGE
    val language: String = "ko",
    val dateFormat: String = "yyyy-MM-dd",
    val timeFormat: String = "24H", // 12H, 24H
    val currency: String = "KRW"
)

/**
 * 위치 설정 DTO
 */
data class LocationSettingsDto(
    val enableGPS: Boolean = true,
    val autoLocationUpdate: Boolean = true,
    val locationAccuracy: String = "HIGH", // LOW, MEDIUM, HIGH
    val shareLocation: Boolean = false
)

/**
 * 동기화 설정 DTO
 */
data class SyncSettingsDto(
    val autoSync: Boolean = true,
    val syncFrequency: String = "REAL_TIME", // REAL_TIME, HOURLY, DAILY
    val syncOnWiFiOnly: Boolean = false,
    val offlineMode: Boolean = true,
    val cacheSize: String = "MEDIUM" // SMALL, MEDIUM, LARGE
)