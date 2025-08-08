package com.qiro.domain.dashboard.repository

import com.qiro.domain.dashboard.dto.*
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 대시보드 데이터 조회를 위한 Repository
 */
@Repository
interface DashboardRepository {
    
    /**
     * 시설 관리 대시보드 개요 데이터 조회
     */
    fun getDashboardOverview(companyId: UUID): DashboardOverviewDto?
    
    /**
     * 대시보드 KPI 데이터 조회
     */
    fun getDashboardKpi(companyId: UUID): DashboardKpiDto?
    
    /**
     * 월별 시설 관리 현황 보고서 데이터 조회
     */
    fun getMonthlyFacilityReport(companyId: UUID): MonthlyFacilityReportDto?
    
    /**
     * 비용 분석 보고서 데이터 조회
     */
    fun getCostAnalysisReport(companyId: UUID): CostAnalysisReportDto?
    
    /**
     * 시설 관리 알림 및 경고 데이터 조회
     */
    fun getFacilityAlerts(companyId: UUID): FacilityAlertsDto?
    
    /**
     * 위젯 데이터 조회
     */
    fun getWidgetData(
        companyId: UUID,
        widgetType: String,
        filterConfig: Map<String, Any>? = null
    ): WidgetDataDto?
    
    /**
     * 대시보드 데이터 새로고침
     */
    fun refreshDashboardData(
        companyId: UUID,
        dashboardType: String? = null
    ): Map<String, Any>
}

/**
 * 대시보드 설정 Repository
 */
@Repository
interface DashboardConfigurationRepository : JpaRepository<DashboardConfiguration, UUID> {
    
    @Query("SELECT dc FROM DashboardConfiguration dc WHERE dc.companyId = :companyId AND dc.isActive = true")
    fun findByCompanyIdAndIsActiveTrue(@Param("companyId") companyId: UUID): List<DashboardConfiguration>
    
    @Query("SELECT dc FROM DashboardConfiguration dc WHERE dc.companyId = :companyId AND dc.dashboardType = :dashboardType AND dc.isActive = true")
    fun findByCompanyIdAndDashboardTypeAndIsActiveTrue(
        @Param("companyId") companyId: UUID,
        @Param("dashboardType") dashboardType: String
    ): List<DashboardConfiguration>
    
    @Query("SELECT dc FROM DashboardConfiguration dc WHERE dc.companyId = :companyId AND dc.dashboardName = :dashboardName")
    fun findByCompanyIdAndDashboardName(
        @Param("companyId") companyId: UUID,
        @Param("dashboardName") dashboardName: String
    ): DashboardConfiguration?
}

/**
 * 보고서 템플릿 Repository
 */
@Repository
interface ReportTemplateRepository : JpaRepository<ReportTemplate, UUID> {
    
    @Query("SELECT rt FROM ReportTemplate rt WHERE rt.companyId = :companyId AND rt.isActive = true")
    fun findByCompanyIdAndIsActiveTrue(@Param("companyId") companyId: UUID): List<ReportTemplate>
    
    @Query("SELECT rt FROM ReportTemplate rt WHERE rt.companyId = :companyId AND rt.templateType = :templateType AND rt.isActive = true")
    fun findByCompanyIdAndTemplateTypeAndIsActiveTrue(
        @Param("companyId") companyId: UUID,
        @Param("templateType") templateType: String
    ): List<ReportTemplate>
    
    @Query("SELECT rt FROM ReportTemplate rt WHERE rt.companyId = :companyId AND rt.autoGenerate = true AND rt.isActive = true")
    fun findByCompanyIdAndAutoGenerateTrueAndIsActiveTrue(@Param("companyId") companyId: UUID): List<ReportTemplate>
    
    @Query("SELECT rt FROM ReportTemplate rt WHERE rt.companyId = :companyId AND rt.reportFrequency = :frequency AND rt.autoGenerate = true AND rt.isActive = true")
    fun findByCompanyIdAndReportFrequencyAndAutoGenerateTrueAndIsActiveTrue(
        @Param("companyId") companyId: UUID,
        @Param("frequency") frequency: String
    ): List<ReportTemplate>
}

/**
 * 생성된 보고서 Repository
 */
@Repository
interface GeneratedReportRepository : JpaRepository<GeneratedReport, UUID> {
    
    @Query("SELECT gr FROM GeneratedReport gr WHERE gr.companyId = :companyId ORDER BY gr.generatedAt DESC")
    fun findByCompanyIdOrderByGeneratedAtDesc(@Param("companyId") companyId: UUID): List<GeneratedReport>
    
    @Query("SELECT gr FROM GeneratedReport gr WHERE gr.companyId = :companyId AND gr.reportType = :reportType ORDER BY gr.generatedAt DESC")
    fun findByCompanyIdAndReportTypeOrderByGeneratedAtDesc(
        @Param("companyId") companyId: UUID,
        @Param("reportType") reportType: String
    ): List<GeneratedReport>
    
    @Query("SELECT gr FROM GeneratedReport gr WHERE gr.templateId = :templateId ORDER BY gr.generatedAt DESC")
    fun findByTemplateIdOrderByGeneratedAtDesc(@Param("templateId") templateId: UUID): List<GeneratedReport>
    
    @Query("SELECT gr FROM GeneratedReport gr WHERE gr.companyId = :companyId AND gr.generatedAt >= :startDate AND gr.generatedAt <= :endDate ORDER BY gr.generatedAt DESC")
    fun findByCompanyIdAndGeneratedAtBetweenOrderByGeneratedAtDesc(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<GeneratedReport>
    
    @Query("SELECT gr FROM GeneratedReport gr WHERE gr.companyId = :companyId AND gr.reportStatus = :status ORDER BY gr.generatedAt DESC")
    fun findByCompanyIdAndReportStatusOrderByGeneratedAtDesc(
        @Param("companyId") companyId: UUID,
        @Param("status") status: String
    ): List<GeneratedReport>
    
    @Query("SELECT MAX(gr.generatedAt) FROM GeneratedReport gr WHERE gr.templateId = :templateId AND gr.generationType = 'AUTO'")
    fun findLastAutoGeneratedDateByTemplateId(@Param("templateId") templateId: UUID): LocalDateTime?
}

/**
 * 대시보드 위젯 Repository
 */
@Repository
interface DashboardWidgetRepository : JpaRepository<DashboardWidget, UUID> {
    
    @Query("SELECT dw FROM DashboardWidget dw WHERE dw.companyId = :companyId AND dw.isActive = true")
    fun findByCompanyIdAndIsActiveTrue(@Param("companyId") companyId: UUID): List<DashboardWidget>
    
    @Query("SELECT dw FROM DashboardWidget dw WHERE dw.dashboardConfigId = :configId AND dw.isActive = true ORDER BY dw.positionY, dw.positionX")
    fun findByDashboardConfigIdAndIsActiveTrueOrderByPositionYAscPositionXAsc(
        @Param("configId") configId: UUID
    ): List<DashboardWidget>
    
    @Query("SELECT dw FROM DashboardWidget dw WHERE dw.companyId = :companyId AND dw.widgetType = :widgetType AND dw.isActive = true")
    fun findByCompanyIdAndWidgetTypeAndIsActiveTrue(
        @Param("companyId") companyId: UUID,
        @Param("widgetType") widgetType: String
    ): List<DashboardWidget>
}

// Entity 클래스들 (간단한 정의)
data class DashboardConfiguration(
    val configId: UUID,
    val companyId: UUID,
    val dashboardName: String,
    val dashboardType: String,
    val description: String?,
    val widgetConfiguration: String?, // JSON 문자열
    val refreshIntervalMinutes: Int,
    val autoRefresh: Boolean,
    val accessRoles: String?, // JSON 문자열
    val isPublic: Boolean,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

data class ReportTemplate(
    val templateId: UUID,
    val companyId: UUID,
    val templateName: String,
    val templateType: String,
    val description: String?,
    val reportFormat: String,
    val reportFrequency: String,
    val dataSources: String?, // JSON 문자열
    val filterCriteria: String?, // JSON 문자열
    val layoutConfiguration: String?, // JSON 문자열
    val autoGenerate: Boolean,
    val distributionList: String?, // JSON 문자열
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)

data class GeneratedReport(
    val reportId: UUID,
    val companyId: UUID,
    val templateId: UUID?,
    val reportName: String,
    val reportType: String,
    val reportPeriodStart: LocalDateTime?,
    val reportPeriodEnd: LocalDateTime?,
    val generationType: String,
    val fileName: String?,
    val fileFormat: String?,
    val summaryData: String?, // JSON 문자열
    val keyMetrics: String?, // JSON 문자열
    val reportStatus: String,
    val generatedAt: LocalDateTime,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class DashboardWidget(
    val widgetId: UUID,
    val companyId: UUID,
    val dashboardConfigId: UUID?,
    val widgetName: String,
    val widgetType: String,
    val widgetTitle: String?,
    val positionX: Int,
    val positionY: Int,
    val width: Int,
    val height: Int,
    val dataSource: String?,
    val queryConfiguration: String?, // JSON 문자열
    val filterConfiguration: String?, // JSON 문자열
    val displayConfiguration: String?, // JSON 문자열
    val refreshIntervalMinutes: Int,
    val autoRefresh: Boolean,
    val isVisible: Boolean,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
)