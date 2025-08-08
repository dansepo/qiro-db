package com.qiro.domain.dashboard.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.time.LocalDate
import java.util.*

/**
 * 분석 및 리포팅 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 성과 분석 (5개 프로시저)
 * - 업무 요약 (1개 프로시저)
 * - 대시보드 데이터 생성 및 통계 분석 기능
 */
interface AnalyticsService {
    
    // === 대시보드 설정 관리 ===
    
    /**
     * 대시보드 설정 생성
     */
    fun createDashboardConfiguration(request: CreateDashboardConfigurationRequest): DashboardConfigurationDto
    
    /**
     * 대시보드 설정 조회
     */
    fun getDashboardConfiguration(companyId: UUID, configId: UUID): DashboardConfigurationDto?
    
    /**
     * 대시보드 설정 목록 조회
     */
    fun getDashboardConfigurations(companyId: UUID, pageable: Pageable): Page<DashboardConfigurationDto>
    
    /**
     * 대시보드 설정 수정
     */
    fun updateDashboardConfiguration(configId: UUID, request: CreateDashboardConfigurationRequest): DashboardConfigurationDto
    
    /**
     * 대시보드 설정 삭제
     */
    fun deleteDashboardConfiguration(companyId: UUID, configId: UUID): Boolean
    
    /**
     * 대시보드 타입별 설정 조회
     */
    fun getDashboardConfigurationsByType(companyId: UUID, dashboardType: String): List<DashboardConfigurationDto>
    
    // === 대시보드 위젯 관리 ===
    
    /**
     * 대시보드 위젯 생성
     */
    fun createDashboardWidget(request: CreateDashboardWidgetRequest): DashboardWidgetDto
    
    /**
     * 대시보드 위젯 조회
     */
    fun getDashboardWidget(companyId: UUID, widgetId: UUID): DashboardWidgetDto?
    
    /**
     * 대시보드별 위젯 목록 조회
     */
    fun getDashboardWidgets(companyId: UUID, dashboardConfigId: UUID): List<DashboardWidgetDto>
    
    /**
     * 대시보드 위젯 수정
     */
    fun updateDashboardWidget(widgetId: UUID, request: CreateDashboardWidgetRequest): DashboardWidgetDto
    
    /**
     * 대시보드 위젯 삭제
     */
    fun deleteDashboardWidget(companyId: UUID, widgetId: UUID): Boolean
    
    /**
     * 위젯 위치 업데이트
     */
    fun updateWidgetPosition(
        companyId: UUID,
        widgetId: UUID,
        positionX: Int,
        positionY: Int,
        width: Int? = null,
        height: Int? = null
    ): DashboardWidgetDto
    
    // === 보고서 템플릿 관리 ===
    
    /**
     * 보고서 템플릿 생성
     */
    fun createReportTemplate(request: CreateReportTemplateRequest): ReportTemplateDto
    
    /**
     * 보고서 템플릿 조회
     */
    fun getReportTemplate(companyId: UUID, templateId: UUID): ReportTemplateDto?
    
    /**
     * 보고서 템플릿 목록 조회
     */
    fun getReportTemplates(companyId: UUID, pageable: Pageable): Page<ReportTemplateDto>
    
    /**
     * 보고서 템플릿 수정
     */
    fun updateReportTemplate(templateId: UUID, request: CreateReportTemplateRequest): ReportTemplateDto
    
    /**
     * 보고서 템플릿 삭제
     */
    fun deleteReportTemplate(companyId: UUID, templateId: UUID): Boolean
    
    /**
     * 보고서 타입별 템플릿 조회
     */
    fun getReportTemplatesByType(companyId: UUID, templateType: String): List<ReportTemplateDto>
    
    /**
     * 자동 생성 템플릿 조회
     */
    fun getAutoGenerateTemplates(companyId: UUID): List<ReportTemplateDto>
    
    // === 보고서 생성 및 관리 ===
    
    /**
     * 보고서 생성
     */
    fun generateReport(request: GenerateReportRequest): GeneratedReportDto
    
    /**
     * 생성된 보고서 조회
     */
    fun getGeneratedReport(companyId: UUID, reportId: UUID): GeneratedReportDto?
    
    /**
     * 생성된 보고서 목록 조회
     */
    fun getGeneratedReports(companyId: UUID, pageable: Pageable): Page<GeneratedReportDto>
    
    /**
     * 보고서 필터 조회
     */
    fun getGeneratedReportsWithFilter(filter: AnalyticsFilter, pageable: Pageable): Page<GeneratedReportDto>
    
    /**
     * 보고서 배포
     */
    fun distributeReport(
        companyId: UUID,
        reportId: UUID,
        distributionList: List<String>,
        distributionMethod: String = "EMAIL"
    ): GeneratedReportDto
    
    /**
     * 보고서 삭제
     */
    fun deleteGeneratedReport(companyId: UUID, reportId: UUID): Boolean
    
    /**
     * 자동 보고서 생성 실행
     */
    fun executeAutoReportGeneration(companyId: UUID): List<GeneratedReportDto>
    
    // === 대시보드 데이터 조회 ===
    
    /**
     * 시설 관리 대시보드 개요 데이터 조회
     */
    fun getFacilityDashboardOverview(companyId: UUID): FacilityDashboardOverviewDto?
    
    /**
     * 월별 시설 관리 보고서 데이터 조회
     */
    fun getMonthlyFacilityReport(companyId: UUID): MonthlyFacilityReportDto?
    
    /**
     * 비용 분석 보고서 데이터 조회
     */
    fun getCostAnalysisReport(companyId: UUID): CostAnalysisReportDto?
    
    /**
     * 시설물 성능 지표 데이터 조회
     */
    fun getFacilityPerformanceMetrics(companyId: UUID, assetType: String? = null): List<FacilityPerformanceMetricsDto>
    
    /**
     * 시설 알림 대시보드 데이터 조회
     */
    fun getFacilityAlertsDashboard(companyId: UUID): FacilityAlertsDashboardDto?
    
    /**
     * 대시보드 데이터 조회 (통합)
     */
    fun getDashboardData(
        companyId: UUID,
        dashboardType: String,
        filter: AnalyticsFilter? = null
    ): DashboardDataResponseDto
    
    /**
     * 위젯 데이터 조회
     */
    fun getWidgetData(
        companyId: UUID,
        widgetId: UUID,
        filter: AnalyticsFilter? = null
    ): DashboardWidgetDataDto
    
    // === 성과 분석 (5개 프로시저 이관) ===
    
    /**
     * 시설 관리 성과 분석
     * 기존 프로시저: facility_performance_analysis
     */
    fun analyzeFacilityPerformance(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        analysisType: String = "COMPREHENSIVE"
    ): PerformanceAnalysisDto
    
    /**
     * 비용 효율성 분석
     * 기존 프로시저: cost_efficiency_analysis
     */
    fun analyzeCostEfficiency(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        costCategory: String? = null
    ): PerformanceAnalysisDto
    
    /**
     * 유지보수 효과성 분석
     * 기존 프로시저: maintenance_effectiveness_analysis
     */
    fun analyzeMaintenanceEffectiveness(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        maintenanceType: String? = null
    ): PerformanceAnalysisDto
    
    /**
     * 자산 활용도 분석
     * 기존 프로시저: asset_utilization_analysis
     */
    fun analyzeAssetUtilization(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        assetType: String? = null
    ): PerformanceAnalysisDto
    
    /**
     * 운영 효율성 분석
     * 기존 프로시저: operational_efficiency_analysis
     */
    fun analyzeOperationalEfficiency(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        departmentId: UUID? = null
    ): PerformanceAnalysisDto
    
    // === 업무 요약 (1개 프로시저 이관) ===
    
    /**
     * 업무 요약 생성
     * 기존 프로시저: generate_work_summary
     */
    fun generateWorkSummary(
        companyId: UUID,
        summaryDate: LocalDate = LocalDate.now(),
        summaryType: String = "DAILY"
    ): WorkSummaryDto
    
    /**
     * 기간별 업무 요약 조회
     */
    fun getWorkSummaryByPeriod(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate,
        groupBy: String = "DAILY"
    ): List<WorkSummaryDto>
    
    // === 통계 및 트렌드 분석 ===
    
    /**
     * 시설 관리 통계 조회
     */
    fun getFacilityManagementStatistics(
        companyId: UUID,
        period: String = "MONTHLY"
    ): Map<String, Any>
    
    /**
     * 비용 트렌드 분석
     */
    fun getCostTrendAnalysis(
        companyId: UUID,
        period: String = "MONTHLY",
        months: Int = 12
    ): Map<String, Any>
    
    /**
     * 작업 효율성 트렌드 분석
     */
    fun getWorkEfficiencyTrends(
        companyId: UUID,
        period: String = "WEEKLY",
        weeks: Int = 12
    ): Map<String, Any>
    
    /**
     * 고장 패턴 분석
     */
    fun getFaultPatternAnalysis(
        companyId: UUID,
        analysisType: String = "FREQUENCY"
    ): Map<String, Any>
    
    /**
     * 예방 정비 효과 분석
     */
    fun getPreventiveMaintenanceEffectiveness(companyId: UUID): Map<String, Any>
    
    /**
     * 자산 수명 분석
     */
    fun getAssetLifecycleAnalysis(
        companyId: UUID,
        assetType: String? = null
    ): Map<String, Any>
    
    /**
     * 부서별 성과 비교 분석
     */
    fun getDepartmentPerformanceComparison(companyId: UUID): Map<String, Any>
    
    /**
     * 계절별 운영 패턴 분석
     */
    fun getSeasonalOperationPatterns(companyId: UUID): Map<String, Any>
    
    // === 예측 분석 ===
    
    /**
     * 비용 예측 분석
     */
    fun predictMaintenanceCosts(
        companyId: UUID,
        forecastMonths: Int = 6
    ): Map<String, Any>
    
    /**
     * 자산 교체 예측
     */
    fun predictAssetReplacement(
        companyId: UUID,
        assetType: String? = null
    ): Map<String, Any>
    
    /**
     * 작업량 예측
     */
    fun predictWorkload(
        companyId: UUID,
        forecastWeeks: Int = 4
    ): Map<String, Any>
    
    // === 벤치마킹 및 비교 분석 ===
    
    /**
     * 업계 벤치마킹 분석
     */
    fun getIndustryBenchmarking(
        companyId: UUID,
        industryType: String,
        metrics: List<String>
    ): Map<String, Any>
    
    /**
     * 기간별 성과 비교
     */
    fun comparePeriodPerformance(
        companyId: UUID,
        currentPeriodStart: LocalDate,
        currentPeriodEnd: LocalDate,
        comparisonPeriodStart: LocalDate,
        comparisonPeriodEnd: LocalDate
    ): Map<String, Any>
    
    // === 자동화 및 배치 작업 ===
    
    /**
     * 일일 분석 보고서 자동 생성
     */
    fun generateDailyAnalyticsReport(companyId: UUID): Map<String, Any>
    
    /**
     * 주간 성과 요약 생성
     */
    fun generateWeeklyPerformanceSummary(companyId: UUID): Map<String, Any>
    
    /**
     * 월간 종합 분석 보고서 생성
     */
    fun generateMonthlyComprehensiveReport(companyId: UUID): Map<String, Any>
    
    /**
     * 분석 데이터 캐시 갱신
     */
    fun refreshAnalyticsCache(companyId: UUID): Map<String, Any>
    
    /**
     * 오래된 분석 데이터 아카이브
     */
    fun archiveOldAnalyticsData(
        companyId: UUID,
        archiveDate: LocalDate,
        dataTypes: List<String>
    ): Map<String, Any>
}