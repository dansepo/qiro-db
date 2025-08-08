package com.qiro.domain.dashboard.service

import com.qiro.domain.dashboard.dto.*
import com.qiro.domain.dashboard.repository.*
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 대시보드 서비스
 */
@Service
@Transactional(readOnly = true)
class DashboardService(
    private val dashboardRepository: DashboardRepository,
    private val dashboardConfigurationRepository: DashboardConfigurationRepository,
    private val dashboardWidgetRepository: DashboardWidgetRepository,
    private val namedParameterJdbcTemplate: NamedParameterJdbcTemplate
) {
    
    /**
     * 시설 관리 대시보드 개요 데이터 조회
     */
    fun getDashboardOverview(companyId: UUID): DashboardOverviewDto? {
        return dashboardRepository.getDashboardOverview(companyId)
    }
    
    /**
     * 대시보드 KPI 데이터 조회
     */
    fun getDashboardKpi(companyId: UUID): DashboardKpiDto? {
        return dashboardRepository.getDashboardKpi(companyId)
    }
    
    /**
     * 시설 관리 알림 및 경고 데이터 조회
     */
    fun getFacilityAlerts(companyId: UUID): FacilityAlertsDto? {
        return dashboardRepository.getFacilityAlerts(companyId)
    }
    
    /**
     * 위젯 데이터 조회
     */
    fun getWidgetData(
        companyId: UUID,
        widgetType: String,
        filterConfig: Map<String, Any>? = null
    ): WidgetDataDto? {
        return dashboardRepository.getWidgetData(companyId, widgetType, filterConfig)
    }
    
    /**
     * 대시보드 데이터 새로고침
     */
    fun refreshDashboardData(
        companyId: UUID,
        dashboardType: String? = null
    ): Map<String, Any> {
        return dashboardRepository.refreshDashboardData(companyId, dashboardType)
    }
    
    /**
     * 회사별 대시보드 설정 목록 조회
     */
    fun getDashboardConfigurations(companyId: UUID): List<DashboardConfigurationDto> {
        return dashboardConfigurationRepository.findByCompanyIdAndIsActiveTrue(companyId)
            .map { config ->
                DashboardConfigurationDto(
                    configId = config.configId,
                    companyId = config.companyId,
                    dashboardName = config.dashboardName,
                    dashboardType = config.dashboardType,
                    description = config.description,
                    widgetConfiguration = parseJsonToMap(config.widgetConfiguration),
                    refreshIntervalMinutes = config.refreshIntervalMinutes,
                    autoRefresh = config.autoRefresh,
                    accessRoles = parseJsonToList(config.accessRoles),
                    isPublic = config.isPublic,
                    isActive = config.isActive
                )
            }
    }
    
    /**
     * 대시보드 유형별 설정 조회
     */
    fun getDashboardConfigurationsByType(companyId: UUID, dashboardType: String): List<DashboardConfigurationDto> {
        return dashboardConfigurationRepository.findByCompanyIdAndDashboardTypeAndIsActiveTrue(companyId, dashboardType)
            .map { config ->
                DashboardConfigurationDto(
                    configId = config.configId,
                    companyId = config.companyId,
                    dashboardName = config.dashboardName,
                    dashboardType = config.dashboardType,
                    description = config.description,
                    widgetConfiguration = parseJsonToMap(config.widgetConfiguration),
                    refreshIntervalMinutes = config.refreshIntervalMinutes,
                    autoRefresh = config.autoRefresh,
                    accessRoles = parseJsonToList(config.accessRoles),
                    isPublic = config.isPublic,
                    isActive = config.isActive
                )
            }
    }
    
    /**
     * 대시보드 위젯 목록 조회
     */
    fun getDashboardWidgets(companyId: UUID): List<DashboardWidget> {
        return dashboardWidgetRepository.findByCompanyIdAndIsActiveTrue(companyId)
    }
    
    /**
     * 대시보드 설정별 위젯 목록 조회
     */
    fun getWidgetsByDashboardConfig(configId: UUID): List<DashboardWidget> {
        return dashboardWidgetRepository.findByDashboardConfigIdAndIsActiveTrueOrderByPositionYAscPositionXAsc(configId)
    }
    
    /**
     * 위젯 유형별 위젯 목록 조회
     */
    fun getWidgetsByType(companyId: UUID, widgetType: String): List<DashboardWidget> {
        return dashboardWidgetRepository.findByCompanyIdAndWidgetTypeAndIsActiveTrue(companyId, widgetType)
    }
    
    /**
     * 대시보드 설정 저장
     */
    @Transactional
    fun saveDashboardConfiguration(dto: DashboardConfigurationDto): DashboardConfigurationDto {
        // 실제 구현에서는 JPA Entity를 사용하여 저장
        // 여기서는 간단한 예시로 DTO를 반환
        return dto.copy(
            configId = dto.configId ?: UUID.randomUUID()
        )
    }
    
    /**
     * 대시보드 설정 업데이트
     */
    @Transactional
    fun updateDashboardConfiguration(configId: UUID, dto: DashboardConfigurationDto): DashboardConfigurationDto {
        // 실제 구현에서는 JPA Entity를 사용하여 업데이트
        return dto.copy(configId = configId)
    }
    
    /**
     * 대시보드 설정 삭제 (논리 삭제)
     */
    @Transactional
    fun deleteDashboardConfiguration(configId: UUID) {
        // 실제 구현에서는 isActive를 false로 설정
    }
    
    /**
     * JSON 문자열을 Map으로 파싱
     */
    private fun parseJsonToMap(json: String?): Map<String, Any>? {
        if (json.isNullOrBlank()) return null
        return try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            objectMapper.readValue(json, Map::class.java) as Map<String, Any>
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * JSON 문자열을 List로 파싱
     */
    private fun parseJsonToList(json: String?): List<String>? {
        if (json.isNullOrBlank()) return null
        return try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            objectMapper.readValue(json, List::class.java) as List<String>
        } catch (e: Exception) {
            null
        }
    }
}

/**
 * 보고서 서비스
 */
@Service
@Transactional(readOnly = true)
class ReportService(
    private val dashboardRepository: DashboardRepository,
    private val reportTemplateRepository: ReportTemplateRepository,
    private val generatedReportRepository: GeneratedReportRepository,
    private val namedParameterJdbcTemplate: NamedParameterJdbcTemplate
) {
    
    /**
     * 월별 시설 관리 현황 보고서 조회
     */
    fun getMonthlyFacilityReport(companyId: UUID): MonthlyFacilityReportDto? {
        return dashboardRepository.getMonthlyFacilityReport(companyId)
    }
    
    /**
     * 비용 분석 보고서 조회
     */
    fun getCostAnalysisReport(companyId: UUID): CostAnalysisReportDto? {
        return dashboardRepository.getCostAnalysisReport(companyId)
    }
    
    /**
     * 보고서 템플릿 목록 조회
     */
    fun getReportTemplates(companyId: UUID): List<ReportTemplateDto> {
        return reportTemplateRepository.findByCompanyIdAndIsActiveTrue(companyId)
            .map { template ->
                ReportTemplateDto(
                    templateId = template.templateId,
                    companyId = template.companyId,
                    templateName = template.templateName,
                    templateType = template.templateType,
                    description = template.description,
                    reportFormat = template.reportFormat,
                    reportFrequency = template.reportFrequency,
                    dataSources = parseJsonToMap(template.dataSources),
                    filterCriteria = parseJsonToMap(template.filterCriteria),
                    layoutConfiguration = parseJsonToMap(template.layoutConfiguration),
                    autoGenerate = template.autoGenerate,
                    distributionList = parseJsonToList(template.distributionList),
                    isActive = template.isActive
                )
            }
    }
    
    /**
     * 보고서 유형별 템플릿 조회
     */
    fun getReportTemplatesByType(companyId: UUID, templateType: String): List<ReportTemplateDto> {
        return reportTemplateRepository.findByCompanyIdAndTemplateTypeAndIsActiveTrue(companyId, templateType)
            .map { template ->
                ReportTemplateDto(
                    templateId = template.templateId,
                    companyId = template.companyId,
                    templateName = template.templateName,
                    templateType = template.templateType,
                    description = template.description,
                    reportFormat = template.reportFormat,
                    reportFrequency = template.reportFrequency,
                    dataSources = parseJsonToMap(template.dataSources),
                    filterCriteria = parseJsonToMap(template.filterCriteria),
                    layoutConfiguration = parseJsonToMap(template.layoutConfiguration),
                    autoGenerate = template.autoGenerate,
                    distributionList = parseJsonToList(template.distributionList),
                    isActive = template.isActive
                )
            }
    }
    
    /**
     * 생성된 보고서 목록 조회
     */
    fun getGeneratedReports(companyId: UUID): List<GeneratedReportDto> {
        return generatedReportRepository.findByCompanyIdOrderByGeneratedAtDesc(companyId)
            .map { report ->
                GeneratedReportDto(
                    reportId = report.reportId,
                    companyId = report.companyId,
                    templateId = report.templateId,
                    reportName = report.reportName,
                    reportType = report.reportType,
                    reportPeriodStart = report.reportPeriodStart,
                    reportPeriodEnd = report.reportPeriodEnd,
                    generationType = report.generationType,
                    fileName = report.fileName,
                    fileFormat = report.fileFormat,
                    summaryData = parseJsonToMap(report.summaryData),
                    keyMetrics = parseJsonToMap(report.keyMetrics),
                    reportStatus = report.reportStatus,
                    generatedAt = report.generatedAt
                )
            }
    }
    
    /**
     * 보고서 유형별 생성된 보고서 조회
     */
    fun getGeneratedReportsByType(companyId: UUID, reportType: String): List<GeneratedReportDto> {
        return generatedReportRepository.findByCompanyIdAndReportTypeOrderByGeneratedAtDesc(companyId, reportType)
            .map { report ->
                GeneratedReportDto(
                    reportId = report.reportId,
                    companyId = report.companyId,
                    templateId = report.templateId,
                    reportName = report.reportName,
                    reportType = report.reportType,
                    reportPeriodStart = report.reportPeriodStart,
                    reportPeriodEnd = report.reportPeriodEnd,
                    generationType = report.generationType,
                    fileName = report.fileName,
                    fileFormat = report.fileFormat,
                    summaryData = parseJsonToMap(report.summaryData),
                    keyMetrics = parseJsonToMap(report.keyMetrics),
                    reportStatus = report.reportStatus,
                    generatedAt = report.generatedAt
                )
            }
    }
    
    /**
     * 월별 시설 관리 보고서 생성
     */
    @Transactional
    fun generateMonthlyFacilityReport(
        companyId: UUID,
        reportMonth: LocalDate? = null
    ): UUID {
        val sql = "SELECT bms.generate_monthly_facility_report(:companyId, :reportMonth) as report_id"
        
        val params = mapOf(
            "companyId" to companyId,
            "reportMonth" to (reportMonth ?: LocalDate.now().minusMonths(1).withDayOfMonth(1))
        )
        
        return namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
            UUID.fromString(rs.getString("report_id"))
        } ?: throw RuntimeException("보고서 생성에 실패했습니다.")
    }
    
    /**
     * 비용 분석 보고서 생성
     */
    @Transactional
    fun generateCostAnalysisReport(
        companyId: UUID,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null
    ): UUID {
        val sql = "SELECT bms.generate_cost_analysis_report(:companyId, :startDate, :endDate) as report_id"
        
        val params = mapOf(
            "companyId" to companyId,
            "startDate" to (startDate ?: LocalDate.now().minusMonths(1).withDayOfMonth(1)),
            "endDate" to (endDate ?: LocalDate.now().minusDays(1))
        )
        
        return namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
            UUID.fromString(rs.getString("report_id"))
        } ?: throw RuntimeException("비용 분석 보고서 생성에 실패했습니다.")
    }
    
    /**
     * 시설물 성능 보고서 생성
     */
    @Transactional
    fun generatePerformanceReport(
        companyId: UUID,
        assetType: String? = null
    ): UUID {
        val sql = "SELECT bms.generate_performance_report(:companyId, :assetType) as report_id"
        
        val params = mapOf(
            "companyId" to companyId,
            "assetType" to assetType
        )
        
        return namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
            UUID.fromString(rs.getString("report_id"))
        } ?: throw RuntimeException("성능 분석 보고서 생성에 실패했습니다.")
    }
    
    /**
     * 보고서 템플릿 저장
     */
    @Transactional
    fun saveReportTemplate(dto: ReportTemplateDto): ReportTemplateDto {
        // 실제 구현에서는 JPA Entity를 사용하여 저장
        return dto.copy(
            templateId = dto.templateId ?: UUID.randomUUID()
        )
    }
    
    /**
     * 보고서 템플릿 업데이트
     */
    @Transactional
    fun updateReportTemplate(templateId: UUID, dto: ReportTemplateDto): ReportTemplateDto {
        // 실제 구현에서는 JPA Entity를 사용하여 업데이트
        return dto.copy(templateId = templateId)
    }
    
    /**
     * 보고서 템플릿 삭제 (논리 삭제)
     */
    @Transactional
    fun deleteReportTemplate(templateId: UUID) {
        // 실제 구현에서는 isActive를 false로 설정
    }
    
    /**
     * JSON 문자열을 Map으로 파싱
     */
    private fun parseJsonToMap(json: String?): Map<String, Any>? {
        if (json.isNullOrBlank()) return null
        return try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            objectMapper.readValue(json, Map::class.java) as Map<String, Any>
        } catch (e: Exception) {
            null
        }
    }
    
    /**
     * JSON 문자열을 List로 파싱
     */
    private fun parseJsonToList(json: String?): List<String>? {
        if (json.isNullOrBlank()) return null
        return try {
            val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
            objectMapper.readValue(json, List::class.java) as List<String>
        } catch (e: Exception) {
            null
        }
    }
}