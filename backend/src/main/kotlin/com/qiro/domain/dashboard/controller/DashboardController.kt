package com.qiro.domain.dashboard.controller

import com.qiro.domain.dashboard.dto.*
import com.qiro.domain.dashboard.service.DashboardService
import com.qiro.domain.dashboard.service.ReportService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 시설 관리 대시보드 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/dashboard")
@Tag(name = "Dashboard", description = "시설 관리 대시보드 API")
class DashboardController(
    private val dashboardService: DashboardService
) {
    
    /**
     * 시설 관리 대시보드 개요 데이터 조회
     */
    @GetMapping("/overview")
    @Operation(summary = "대시보드 개요 조회", description = "시설 관리 대시보드의 전체 개요 데이터를 조회합니다.")
    fun getDashboardOverview(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<DashboardOverviewDto> {
        val overview = dashboardService.getDashboardOverview(companyId)
        return if (overview != null) {
            ResponseEntity.ok(overview)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 대시보드 KPI 데이터 조회
     */
    @GetMapping("/kpi")
    @Operation(summary = "대시보드 KPI 조회", description = "대시보드의 주요 성과 지표(KPI) 데이터를 조회합니다.")
    fun getDashboardKpi(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<DashboardKpiDto> {
        val kpi = dashboardService.getDashboardKpi(companyId)
        return if (kpi != null) {
            ResponseEntity.ok(kpi)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 시설 관리 알림 및 경고 데이터 조회
     */
    @GetMapping("/alerts")
    @Operation(summary = "시설 관리 알림 조회", description = "시설 관리 관련 알림 및 경고 데이터를 조회합니다.")
    fun getFacilityAlerts(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<FacilityAlertsDto> {
        val alerts = dashboardService.getFacilityAlerts(companyId)
        return if (alerts != null) {
            ResponseEntity.ok(alerts)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 위젯 데이터 조회
     */
    @GetMapping("/widget/{widgetType}")
    @Operation(summary = "위젯 데이터 조회", description = "특정 유형의 위젯 데이터를 조회합니다.")
    fun getWidgetData(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "위젯 유형", required = true)
        @PathVariable widgetType: String,
        @Parameter(description = "필터 설정")
        @RequestBody(required = false) filterConfig: Map<String, Any>?
    ): ResponseEntity<WidgetDataDto> {
        val widgetData = dashboardService.getWidgetData(companyId, widgetType, filterConfig)
        return if (widgetData != null) {
            ResponseEntity.ok(widgetData)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 대시보드 데이터 새로고침
     */
    @PostMapping("/refresh")
    @Operation(summary = "대시보드 데이터 새로고침", description = "대시보드의 모든 데이터를 새로고침합니다.")
    fun refreshDashboardData(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "대시보드 유형")
        @RequestParam(required = false) dashboardType: String?
    ): ResponseEntity<Map<String, Any>> {
        val refreshedData = dashboardService.refreshDashboardData(companyId, dashboardType)
        return ResponseEntity.ok(refreshedData)
    }
    
    /**
     * 대시보드 설정 목록 조회
     */
    @GetMapping("/configurations")
    @Operation(summary = "대시보드 설정 목록 조회", description = "회사의 대시보드 설정 목록을 조회합니다.")
    fun getDashboardConfigurations(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<List<DashboardConfigurationDto>> {
        val configurations = dashboardService.getDashboardConfigurations(companyId)
        return ResponseEntity.ok(configurations)
    }
    
    /**
     * 대시보드 유형별 설정 조회
     */
    @GetMapping("/configurations/{dashboardType}")
    @Operation(summary = "대시보드 유형별 설정 조회", description = "특정 유형의 대시보드 설정을 조회합니다.")
    fun getDashboardConfigurationsByType(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "대시보드 유형", required = true)
        @PathVariable dashboardType: String
    ): ResponseEntity<List<DashboardConfigurationDto>> {
        val configurations = dashboardService.getDashboardConfigurationsByType(companyId, dashboardType)
        return ResponseEntity.ok(configurations)
    }
    
    /**
     * 대시보드 설정 저장
     */
    @PostMapping("/configurations")
    @Operation(summary = "대시보드 설정 저장", description = "새로운 대시보드 설정을 저장합니다.")
    fun saveDashboardConfiguration(
        @Parameter(description = "대시보드 설정 정보", required = true)
        @RequestBody dto: DashboardConfigurationDto
    ): ResponseEntity<DashboardConfigurationDto> {
        val savedConfiguration = dashboardService.saveDashboardConfiguration(dto)
        return ResponseEntity.ok(savedConfiguration)
    }
    
    /**
     * 대시보드 설정 업데이트
     */
    @PutMapping("/configurations/{configId}")
    @Operation(summary = "대시보드 설정 업데이트", description = "기존 대시보드 설정을 업데이트합니다.")
    fun updateDashboardConfiguration(
        @Parameter(description = "설정 ID", required = true)
        @PathVariable configId: UUID,
        @Parameter(description = "대시보드 설정 정보", required = true)
        @RequestBody dto: DashboardConfigurationDto
    ): ResponseEntity<DashboardConfigurationDto> {
        val updatedConfiguration = dashboardService.updateDashboardConfiguration(configId, dto)
        return ResponseEntity.ok(updatedConfiguration)
    }
    
    /**
     * 대시보드 설정 삭제
     */
    @DeleteMapping("/configurations/{configId}")
    @Operation(summary = "대시보드 설정 삭제", description = "대시보드 설정을 삭제합니다.")
    fun deleteDashboardConfiguration(
        @Parameter(description = "설정 ID", required = true)
        @PathVariable configId: UUID
    ): ResponseEntity<Void> {
        dashboardService.deleteDashboardConfiguration(configId)
        return ResponseEntity.noContent().build()
    }
}

/**
 * 시설 관리 보고서 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/reports")
@Tag(name = "Reports", description = "시설 관리 보고서 API")
class ReportController(
    private val reportService: ReportService
) {
    
    /**
     * 월별 시설 관리 현황 보고서 조회
     */
    @GetMapping("/monthly-facility")
    @Operation(summary = "월별 시설 관리 현황 보고서 조회", description = "월별 시설 관리 현황 보고서 데이터를 조회합니다.")
    fun getMonthlyFacilityReport(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<MonthlyFacilityReportDto> {
        val report = reportService.getMonthlyFacilityReport(companyId)
        return if (report != null) {
            ResponseEntity.ok(report)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 비용 분석 보고서 조회
     */
    @GetMapping("/cost-analysis")
    @Operation(summary = "비용 분석 보고서 조회", description = "비용 분석 보고서 데이터를 조회합니다.")
    fun getCostAnalysisReport(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<CostAnalysisReportDto> {
        val report = reportService.getCostAnalysisReport(companyId)
        return if (report != null) {
            ResponseEntity.ok(report)
        } else {
            ResponseEntity.notFound().build()
        }
    }
    
    /**
     * 보고서 템플릿 목록 조회
     */
    @GetMapping("/templates")
    @Operation(summary = "보고서 템플릿 목록 조회", description = "회사의 보고서 템플릿 목록을 조회합니다.")
    fun getReportTemplates(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<List<ReportTemplateDto>> {
        val templates = reportService.getReportTemplates(companyId)
        return ResponseEntity.ok(templates)
    }
    
    /**
     * 보고서 유형별 템플릿 조회
     */
    @GetMapping("/templates/{templateType}")
    @Operation(summary = "보고서 유형별 템플릿 조회", description = "특정 유형의 보고서 템플릿을 조회합니다.")
    fun getReportTemplatesByType(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "템플릿 유형", required = true)
        @PathVariable templateType: String
    ): ResponseEntity<List<ReportTemplateDto>> {
        val templates = reportService.getReportTemplatesByType(companyId, templateType)
        return ResponseEntity.ok(templates)
    }
    
    /**
     * 생성된 보고서 목록 조회
     */
    @GetMapping("/generated")
    @Operation(summary = "생성된 보고서 목록 조회", description = "생성된 보고서 목록을 조회합니다.")
    fun getGeneratedReports(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID
    ): ResponseEntity<List<GeneratedReportDto>> {
        val reports = reportService.getGeneratedReports(companyId)
        return ResponseEntity.ok(reports)
    }
    
    /**
     * 보고서 유형별 생성된 보고서 조회
     */
    @GetMapping("/generated/{reportType}")
    @Operation(summary = "보고서 유형별 생성된 보고서 조회", description = "특정 유형의 생성된 보고서를 조회합니다.")
    fun getGeneratedReportsByType(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "보고서 유형", required = true)
        @PathVariable reportType: String
    ): ResponseEntity<List<GeneratedReportDto>> {
        val reports = reportService.getGeneratedReportsByType(companyId, reportType)
        return ResponseEntity.ok(reports)
    }
    
    /**
     * 월별 시설 관리 보고서 생성
     */
    @PostMapping("/generate/monthly-facility")
    @Operation(summary = "월별 시설 관리 보고서 생성", description = "월별 시설 관리 보고서를 생성합니다.")
    fun generateMonthlyFacilityReport(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "보고서 월 (YYYY-MM-DD 형식, 기본값: 지난달)")
        @RequestParam(required = false) reportMonth: LocalDate?
    ): ResponseEntity<Map<String, UUID>> {
        val reportId = reportService.generateMonthlyFacilityReport(companyId, reportMonth)
        return ResponseEntity.ok(mapOf("reportId" to reportId))
    }
    
    /**
     * 비용 분석 보고서 생성
     */
    @PostMapping("/generate/cost-analysis")
    @Operation(summary = "비용 분석 보고서 생성", description = "비용 분석 보고서를 생성합니다.")
    fun generateCostAnalysisReport(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "시작 날짜 (YYYY-MM-DD 형식)")
        @RequestParam(required = false) startDate: LocalDate?,
        @Parameter(description = "종료 날짜 (YYYY-MM-DD 형식)")
        @RequestParam(required = false) endDate: LocalDate?
    ): ResponseEntity<Map<String, UUID>> {
        val reportId = reportService.generateCostAnalysisReport(companyId, startDate, endDate)
        return ResponseEntity.ok(mapOf("reportId" to reportId))
    }
    
    /**
     * 시설물 성능 보고서 생성
     */
    @PostMapping("/generate/performance")
    @Operation(summary = "시설물 성능 보고서 생성", description = "시설물 성능 분석 보고서를 생성합니다.")
    fun generatePerformanceReport(
        @Parameter(description = "회사 ID", required = true)
        @RequestParam companyId: UUID,
        @Parameter(description = "시설물 유형 (선택사항)")
        @RequestParam(required = false) assetType: String?
    ): ResponseEntity<Map<String, UUID>> {
        val reportId = reportService.generatePerformanceReport(companyId, assetType)
        return ResponseEntity.ok(mapOf("reportId" to reportId))
    }
    
    /**
     * 보고서 템플릿 저장
     */
    @PostMapping("/templates")
    @Operation(summary = "보고서 템플릿 저장", description = "새로운 보고서 템플릿을 저장합니다.")
    fun saveReportTemplate(
        @Parameter(description = "보고서 템플릿 정보", required = true)
        @RequestBody dto: ReportTemplateDto
    ): ResponseEntity<ReportTemplateDto> {
        val savedTemplate = reportService.saveReportTemplate(dto)
        return ResponseEntity.ok(savedTemplate)
    }
    
    /**
     * 보고서 템플릿 업데이트
     */
    @PutMapping("/templates/{templateId}")
    @Operation(summary = "보고서 템플릿 업데이트", description = "기존 보고서 템플릿을 업데이트합니다.")
    fun updateReportTemplate(
        @Parameter(description = "템플릿 ID", required = true)
        @PathVariable templateId: UUID,
        @Parameter(description = "보고서 템플릿 정보", required = true)
        @RequestBody dto: ReportTemplateDto
    ): ResponseEntity<ReportTemplateDto> {
        val updatedTemplate = reportService.updateReportTemplate(templateId, dto)
        return ResponseEntity.ok(updatedTemplate)
    }
    
    /**
     * 보고서 템플릿 삭제
     */
    @DeleteMapping("/templates/{templateId}")
    @Operation(summary = "보고서 템플릿 삭제", description = "보고서 템플릿을 삭제합니다.")
    fun deleteReportTemplate(
        @Parameter(description = "템플릿 ID", required = true)
        @PathVariable templateId: UUID
    ): ResponseEntity<Void> {
        reportService.deleteReportTemplate(templateId)
        return ResponseEntity.noContent().build()
    }
}