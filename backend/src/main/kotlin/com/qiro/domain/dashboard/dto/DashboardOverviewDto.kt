package com.qiro.domain.dashboard.dto

import java.time.LocalDateTime
import java.util.*

/**
 * 시설 관리 대시보드 개요 DTO
 */
data class DashboardOverviewDto(
    val companyId: UUID,
    val companyName: String,
    
    // 시설물 현황
    val totalAssets: Long,
    val activeAssets: Long,
    val maintenanceAssets: Long,
    val outOfOrderAssets: Long,
    
    // 고장 신고 현황
    val totalFaultReports: Long,
    val newReports: Long,
    val inProgressReports: Long,
    val completedReports: Long,
    val emergencyReports: Long,
    
    // 작업 지시 현황
    val totalWorkOrders: Long,
    val assignedWorkOrders: Long,
    val inProgressWorkOrders: Long,
    val completedWorkOrders: Long,
    val overdueWorkOrders: Long,
    
    // 예방 정비 현황
    val totalMaintenancePlans: Long,
    val dueMaintenance: Long,
    val upcomingMaintenance: Long,
    
    // 비용 현황
    val monthlyCost: Double,
    val yearlyCost: Double,
    
    // 업데이트 시간
    val lastUpdated: LocalDateTime
)

/**
 * 대시보드 KPI DTO
 */
data class DashboardKpiDto(
    val companyId: UUID,
    val companyName: String,
    
    // 기본 KPI
    val totalAssets: Long,
    val activeAssets: Long,
    val avgUptimePercentage: Double,
    val totalReportsThisMonth: Long,
    val totalWorkOrdersThisMonth: Long,
    val totalCostThisMonth: Double,
    
    // 상태별 시설물 수
    val excellentAssets: Long,
    val goodAssets: Long,
    val fairAssets: Long,
    val poorAssets: Long,
    
    // 업데이트 시간
    val lastUpdated: LocalDateTime
)

/**
 * 월별 시설 관리 현황 보고서 DTO
 */
data class MonthlyFacilityReportDto(
    val companyId: UUID,
    val companyName: String,
    val reportMonth: LocalDateTime,
    
    // 고장 신고 통계
    val totalFaultReports: Long,
    val emergencyReports: Long,
    val highPriorityReports: Long,
    val resolvedReports: Long,
    val avgResolutionTimeHours: Double,
    
    // 작업 지시 통계
    val totalWorkOrders: Long,
    val preventiveWorkOrders: Long,
    val correctiveWorkOrders: Long,
    val emergencyWorkOrders: Long,
    
    // 비용 통계
    val totalMaintenanceCost: Double,
    val laborCost: Double,
    val materialCost: Double,
    val contractorCost: Double,
    
    // 시설물 상태 통계
    val totalAssets: Long,
    val activeAssets: Long,
    val excellentConditionAssets: Long,
    val goodConditionAssets: Long,
    val fairConditionAssets: Long,
    val poorConditionAssets: Long,
    
    // 예방 정비 통계
    val totalMaintenancePlans: Long,
    val completedMaintenance: Long,
    val overdueMaintenance: Long,
    
    // 생성 시간
    val generatedAt: LocalDateTime
)

/**
 * 비용 분석 보고서 DTO
 */
data class CostAnalysisReportDto(
    val companyId: UUID,
    val companyName: String,
    
    // 기간별 비용 분석
    val weeklyCost: Double,
    val monthlyCost: Double,
    val quarterlyCost: Double,
    val yearlyCost: Double,
    
    // 비용 유형별 분석
    val totalLaborCost: Double,
    val totalMaterialCost: Double,
    val totalContractorCost: Double,
    val totalEquipmentCost: Double,
    
    // 작업 카테고리별 비용
    val preventiveMaintenanceCost: Double,
    val correctiveMaintenanceCost: Double,
    val emergencyRepairCost: Double,
    
    // 시설물 유형별 비용
    val electricalCost: Double,
    val plumbingCost: Double,
    val hvacCost: Double,
    val elevatorCost: Double,
    val fireSafetyCost: Double,
    
    // 평균 비용 분석
    val avgCostPerWorkOrder: Double,
    val totalCostEntries: Long,
    
    // 최고/최저 비용
    val highestSingleCost: Double,
    val lowestSingleCost: Double,
    
    // 생성 시간
    val generatedAt: LocalDateTime
)

/**
 * 시설 관리 알림 및 경고 대시보드 DTO
 */
data class FacilityAlertsDto(
    val companyId: UUID,
    val companyName: String,
    
    // 긴급 알림
    val activeEmergencyReports: Long,
    val activeEmergencyWorkOrders: Long,
    
    // 지연 알림
    val overdueWorkOrders: Long,
    val overdueMaintenance: Long,
    
    // 보증 만료 알림
    val warrantyExpiringSoon: Long,
    val warrantyExpired: Long,
    
    // 성능 저하 알림
    val lowPerformanceAssets: Long,
    val poorConditionAssets: Long,
    
    // 예산 초과 위험
    val budgetRiskLevel: String, // HIGH, MEDIUM, LOW
    
    // 생성 시간
    val generatedAt: LocalDateTime
)

/**
 * 위젯 데이터 DTO
 */
data class WidgetDataDto(
    val widgetType: String,
    val data: Any,
    val lastUpdated: LocalDateTime
)

/**
 * 대시보드 설정 DTO
 */
data class DashboardConfigurationDto(
    val configId: UUID?,
    val companyId: UUID,
    val dashboardName: String,
    val dashboardType: String,
    val description: String?,
    val widgetConfiguration: Map<String, Any>?,
    val refreshIntervalMinutes: Int,
    val autoRefresh: Boolean,
    val accessRoles: List<String>?,
    val isPublic: Boolean,
    val isActive: Boolean
)

/**
 * 보고서 템플릿 DTO
 */
data class ReportTemplateDto(
    val templateId: UUID?,
    val companyId: UUID,
    val templateName: String,
    val templateType: String,
    val description: String?,
    val reportFormat: String,
    val reportFrequency: String,
    val dataSources: Map<String, Any>?,
    val filterCriteria: Map<String, Any>?,
    val layoutConfiguration: Map<String, Any>?,
    val autoGenerate: Boolean,
    val distributionList: List<String>?,
    val isActive: Boolean
)

/**
 * 생성된 보고서 DTO
 */
data class GeneratedReportDto(
    val reportId: UUID?,
    val companyId: UUID,
    val templateId: UUID?,
    val reportName: String,
    val reportType: String,
    val reportPeriodStart: LocalDateTime?,
    val reportPeriodEnd: LocalDateTime?,
    val generationType: String,
    val fileName: String?,
    val fileFormat: String?,
    val summaryData: Map<String, Any>?,
    val keyMetrics: Map<String, Any>?,
    val reportStatus: String,
    val generatedAt: LocalDateTime
)