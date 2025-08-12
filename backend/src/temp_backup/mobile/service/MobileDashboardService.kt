package com.qiro.domain.mobile.service

import com.qiro.domain.mobile.dto.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 모바일 대시보드 서비스
 */
@Service
@Transactional
class MobileDashboardService(
    private val mobileFaultReportService: MobileFaultReportService,
    private val mobileWorkOrderService: MobileWorkOrderService
) {

    /**
     * 모바일 대시보드 데이터 조회
     */
    @Transactional(readOnly = true)
    fun getMobileDashboard(companyId: UUID, userId: UUID, userRole: String): MobileDashboardDto {
        return MobileDashboardDto(
            userRole = userRole,
            userName = getUserName(userId),
            lastLoginAt = getLastLoginTime(userId),
            summary = getDashboardSummary(companyId),
            todayTasks = getTodayTasks(companyId, userId),
            urgentItems = getUrgentItems(companyId),
            recentActivities = getRecentActivities(companyId, 10),
            quickActions = getQuickActions(userRole),
            notifications = getNotifications(companyId, userId, 5),
            weatherInfo = getWeatherInfo(),
            refreshedAt = LocalDateTime.now()
        )
    }

    /**
     * 대시보드 요약 정보 조회
     */
    @Transactional(readOnly = true)
    fun getDashboardSummary(companyId: UUID): DashboardSummaryDto {
        // 실제 구현에서는 각 서비스에서 통계 데이터를 가져와야 함
        return DashboardSummaryDto(
            totalFaultReports = 45,
            activeFaultReports = 12,
            totalWorkOrders = 78,
            activeWorkOrders = 23,
            completedToday = 8,
            overdueItems = 3,
            upcomingMaintenance = 5,
            criticalAlerts = 2
        )
    }

    /**
     * 오늘의 작업 조회
     */
    @Transactional(readOnly = true)
    fun getTodayTasks(companyId: UUID, userId: UUID): TodayTasksDto {
        // 실제 구현에서는 각 서비스에서 오늘 예정된 작업들을 가져와야 함
        return TodayTasksDto(
            scheduledWorkOrders = emptyList(), // mobileWorkOrderService에서 조회
            dueMaintenance = listOf(
                MaintenanceTaskDto(
                    maintenanceId = UUID.randomUUID(),
                    title = "엘리베이터 월간점검",
                    assetName = "엘리베이터 #1",
                    location = "1층 로비",
                    dueDate = LocalDate.now(),
                    priority = "HIGH",
                    estimatedDuration = 120,
                    assignedTechnician = "김기술",
                    isOverdue = false
                )
            ),
            pendingApprovals = listOf(
                PendingApprovalDto(
                    approvalId = UUID.randomUUID(),
                    type = "WORK_ORDER",
                    title = "긴급 수리 작업",
                    requestedBy = "이작업",
                    requestedAt = LocalDateTime.now().minusHours(2),
                    amount = BigDecimal("150000"),
                    priority = "URGENT",
                    canApprove = true
                )
            ),
            totalHoursScheduled = BigDecimal("6.5"),
            completionRate = BigDecimal("75.0")
        )
    }

    /**
     * 긴급 항목 조회
     */
    @Transactional(readOnly = true)
    fun getUrgentItems(companyId: UUID): UrgentItemsDto {
        return UrgentItemsDto(
            emergencyFaultReports = mobileFaultReportService.getUrgentFaultReports(companyId),
            overdueWorkOrders = emptyList(), // mobileWorkOrderService에서 조회
            criticalMaintenanceAlerts = listOf(
                MaintenanceAlertDto(
                    alertId = UUID.randomUUID(),
                    assetName = "보일러 #2",
                    location = "지하 기계실",
                    alertType = "OVERDUE",
                    dueDate = LocalDate.now().minusDays(3),
                    daysOverdue = 3,
                    priority = "CRITICAL"
                )
            ),
            budgetAlerts = listOf(
                BudgetAlertSummaryDto(
                    budgetName = "2024년 정비예산",
                    category = "MAINTENANCE",
                    utilizationPercentage = BigDecimal("95.5"),
                    alertLevel = "CRITICAL",
                    remainingAmount = BigDecimal("450000")
                )
            )
        )
    }

    /**
     * 최근 활동 조회
     */
    @Transactional(readOnly = true)
    fun getRecentActivities(companyId: UUID, limit: Int): List<RecentActivityDto> {
        return listOf(
            RecentActivityDto(
                activityId = UUID.randomUUID(),
                activityType = ActivityType.WORK_ORDER_COMPLETED,
                title = "작업 완료",
                description = "엘리베이터 정기점검이 완료되었습니다",
                performedBy = "김기술",
                performedAt = LocalDateTime.now().minusMinutes(30),
                entityId = UUID.randomUUID(),
                entityType = "WORK_ORDER",
                icon = "check-circle",
                color = "#10B981"
            ),
            RecentActivityDto(
                activityId = UUID.randomUUID(),
                activityType = ActivityType.FAULT_REPORTED,
                title = "고장 신고",
                description = "화장실 조명 고장이 신고되었습니다",
                performedBy = "박입주",
                performedAt = LocalDateTime.now().minusHours(1),
                entityId = UUID.randomUUID(),
                entityType = "FAULT_REPORT",
                icon = "exclamation-triangle",
                color = "#F59E0B"
            ),
            RecentActivityDto(
                activityId = UUID.randomUUID(),
                activityType = ActivityType.MAINTENANCE_PERFORMED,
                title = "정비 수행",
                description = "보일러 월간점검이 수행되었습니다",
                performedBy = "이정비",
                performedAt = LocalDateTime.now().minusHours(2),
                entityId = UUID.randomUUID(),
                entityType = "MAINTENANCE",
                icon = "cog",
                color = "#3B82F6"
            )
        )
    }

    /**
     * 빠른 작업 메뉴 조회
     */
    @Transactional(readOnly = true)
    fun getQuickActions(userRole: String): List<QuickActionDto> {
        val commonActions = listOf(
            QuickActionDto(
                actionId = "scan_qr",
                title = "QR코드 스캔",
                description = "자산이나 부품 QR코드 스캔",
                icon = "qrcode",
                color = "#3B82F6",
                actionUrl = "/mobile/qr-scan",
                isEnabled = true
            ),
            QuickActionDto(
                actionId = "report_fault",
                title = "고장 신고",
                description = "새로운 고장 신고 등록",
                icon = "exclamation-circle",
                color = "#EF4444",
                actionUrl = "/mobile/fault-reports/create",
                isEnabled = true
            )
        )

        val technicianActions = listOf(
            QuickActionDto(
                actionId = "my_work_orders",
                title = "내 작업 목록",
                description = "배정된 작업 지시서 확인",
                icon = "clipboard-list",
                color = "#10B981",
                actionUrl = "/mobile/work-orders/my",
                requiresPermission = "TECHNICIAN",
                isEnabled = true
            ),
            QuickActionDto(
                actionId = "record_part_usage",
                title = "부품 사용 기록",
                description = "사용한 부품 기록",
                icon = "cube",
                color = "#F59E0B",
                actionUrl = "/mobile/parts/usage",
                requiresPermission = "TECHNICIAN",
                isEnabled = true
            )
        )

        return when (userRole) {
            "TECHNICIAN" -> commonActions + technicianActions
            "MANAGER" -> commonActions + listOf(
                QuickActionDto(
                    actionId = "dashboard",
                    title = "관리 대시보드",
                    description = "전체 현황 확인",
                    icon = "chart-bar",
                    color = "#8B5CF6",
                    actionUrl = "/mobile/dashboard/manager",
                    requiresPermission = "MANAGER",
                    isEnabled = true
                )
            )
            else -> commonActions
        }
    }

    /**
     * 알림 조회
     */
    @Transactional(readOnly = true)
    fun getNotifications(companyId: UUID, userId: UUID, limit: Int): List<NotificationDto> {
        return listOf(
            NotificationDto(
                notificationId = UUID.randomUUID(),
                title = "긴급 작업 배정",
                message = "엘리베이터 고장으로 긴급 수리 작업이 배정되었습니다",
                type = NotificationType.URGENT,
                priority = NotificationPriority.CRITICAL,
                isRead = false,
                createdAt = LocalDateTime.now().minusMinutes(15),
                actionUrl = "/mobile/work-orders/urgent-001",
                actionText = "작업 확인",
                icon = "bell",
                color = "#EF4444"
            ),
            NotificationDto(
                notificationId = UUID.randomUUID(),
                title = "정비 일정 알림",
                message = "내일 오전 10시에 보일러 정기점검이 예정되어 있습니다",
                type = NotificationType.REMINDER,
                priority = NotificationPriority.NORMAL,
                isRead = false,
                createdAt = LocalDateTime.now().minusHours(1),
                actionUrl = "/mobile/maintenance/schedule-001",
                actionText = "일정 확인",
                icon = "calendar",
                color = "#3B82F6"
            ),
            NotificationDto(
                notificationId = UUID.randomUUID(),
                title = "작업 완료 확인",
                message = "화장실 조명 수리가 완료되었습니다",
                type = NotificationType.SUCCESS,
                priority = NotificationPriority.LOW,
                isRead = true,
                createdAt = LocalDateTime.now().minusHours(3),
                icon = "check-circle",
                color = "#10B981"
            )
        )
    }

    /**
     * 기술자 성과 조회
     */
    @Transactional(readOnly = true)
    fun getTechnicianPerformance(
        companyId: UUID,
        technicianId: UUID,
        period: String
    ): TechnicianPerformanceDto {
        return TechnicianPerformanceDto(
            technicianId = technicianId,
            technicianName = "김기술",
            period = period,
            completedWorkOrders = 25,
            averageCompletionTime = BigDecimal("2.5"),
            qualityRating = BigDecimal("4.2"),
            onTimeCompletionRate = BigDecimal("88.0"),
            totalHoursWorked = BigDecimal("160.5"),
            costEfficiency = BigDecimal("95.2"),
            customerSatisfaction = BigDecimal("4.5"),
            badges = listOf(
                PerformanceBadgeDto(
                    badgeId = "quality_expert",
                    name = "품질 전문가",
                    description = "높은 품질의 작업을 지속적으로 수행",
                    icon = "star",
                    color = "#F59E0B",
                    earnedAt = LocalDateTime.now().minusDays(7)
                )
            )
        )
    }

    /**
     * 모바일 설정 조회
     */
    @Transactional(readOnly = true)
    fun getMobileSettings(userId: UUID): MobileSettingsDto {
        return MobileSettingsDto(
            userId = userId,
            notificationSettings = NotificationSettingsDto(
                pushNotifications = true,
                emailNotifications = true,
                smsNotifications = false,
                workOrderAlerts = true,
                maintenanceReminders = true,
                emergencyAlerts = true,
                budgetAlerts = true,
                quietHoursStart = "22:00",
                quietHoursEnd = "08:00"
            ),
            displaySettings = DisplaySettingsDto(
                theme = "AUTO",
                fontSize = "MEDIUM",
                language = "ko",
                dateFormat = "yyyy-MM-dd",
                timeFormat = "24H",
                currency = "KRW"
            ),
            locationSettings = LocationSettingsDto(
                enableGPS = true,
                autoLocationUpdate = true,
                locationAccuracy = "HIGH",
                shareLocation = false
            ),
            syncSettings = SyncSettingsDto(
                autoSync = true,
                syncFrequency = "REAL_TIME",
                syncOnWiFiOnly = false,
                offlineMode = true,
                cacheSize = "MEDIUM"
            )
        )
    }

    /**
     * 모바일 설정 업데이트
     */
    fun updateMobileSettings(userId: UUID, settings: MobileSettingsDto): MobileSettingsDto {
        // 실제 구현에서는 설정을 데이터베이스에 저장
        return settings
    }

    /**
     * 사용자 이름 조회
     */
    private fun getUserName(userId: UUID): String {
        // 실제 구현에서는 UserService에서 조회
        return "김사용자"
    }

    /**
     * 마지막 로그인 시간 조회
     */
    private fun getLastLoginTime(userId: UUID): LocalDateTime? {
        // 실제 구현에서는 UserService에서 조회
        return LocalDateTime.now().minusHours(2)
    }

    /**
     * 날씨 정보 조회
     */
    private fun getWeatherInfo(): WeatherInfoDto? {
        // 실제 구현에서는 외부 날씨 API 호출
        return WeatherInfoDto(
            location = "서울",
            temperature = 15.5,
            condition = "맑음",
            humidity = 65,
            windSpeed = 2.3,
            icon = "sunny",
            lastUpdated = LocalDateTime.now().minusMinutes(30)
        )
    }
}