package com.qiro.domain.dashboard.service

import com.qiro.domain.dashboard.dto.*
import com.qiro.domain.dashboard.entity.*
import com.qiro.domain.dashboard.repository.GeneratedReportRepository
import com.qiro.domain.dashboard.repository.ReportTemplateRepository
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.user.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 보고서 서비스
 * 보고서 템플릿 관리 및 보고서 생성 기능
 */
@Service
@Transactional(readOnly = true)
class ReportService(
    private val reportTemplateRepository: ReportTemplateRepository,
    private val generatedReportRepository: GeneratedReportRepository,
    private val companyRepository: CompanyRepository,
    private val userRepository: UserRepository,
    private val dashboardService: DashboardService
) {

    /**
     * 보고서 템플릿 생성
     */
    @Transactional
    fun createReportTemplate(
        companyId: UUID,
        templateName: String,
        templateType: ReportType,
        description: String?,
        reportFormat: ReportFormat,
        reportFrequency: ReportFrequency,
        autoGenerate: Boolean,
        userId: UUID
    ): ReportTemplate {
        val company = companyRepository.findById(companyId)
            .orElseThrow { IllegalArgumentException("회사를 찾을 수 없습니다: $companyId") }

        // 템플릿 이름 중복 확인
        if (reportTemplateRepository.existsByCompanyCompanyIdAndTemplateName(companyId, templateName)) {
            throw IllegalArgumentException("이미 존재하는 템플릿 이름입니다: $templateName")
        }

        val template = ReportTemplate(
            company = company,
            templateName = templateName,
            templateType = templateType,
            description = description,
            reportFormat = reportFormat,
            reportFrequency = reportFrequency,
            autoGenerate = autoGenerate
        )

        return reportTemplateRepository.save(template)
    }

    /**
     * 보고서 템플릿 수정
     */
    @Transactional
    fun updateReportTemplate(
        templateId: UUID,
        templateName: String?,
        description: String?,
        reportFormat: ReportFormat?,
        reportFrequency: ReportFrequency?,
        autoGenerate: Boolean?,
        userId: UUID
    ): ReportTemplate {
        val template = reportTemplateRepository.findById(templateId)
            .orElseThrow { IllegalArgumentException("보고서 템플릿을 찾을 수 없습니다: $templateId") }

        templateName?.let { template.templateName = it }
        description?.let { template.description = it }
        reportFormat?.let { template.reportFormat = it }
        reportFrequency?.let { template.reportFrequency = it }
        autoGenerate?.let { template.autoGenerate = it }

        return reportTemplateRepository.save(template)
    }

    /**
     * 보고서 템플릿 삭제 (비활성화)
     */
    @Transactional
    fun deleteReportTemplate(templateId: UUID, userId: UUID) {
        val template = reportTemplateRepository.findById(templateId)
            .orElseThrow { IllegalArgumentException("보고서 템플릿을 찾을 수 없습니다: $templateId") }

        template.isActive = false
        reportTemplateRepository.save(template)
    }

    /**
     * 회사별 보고서 템플릿 조회
     */
    fun getReportTemplates(companyId: UUID): List<ReportTemplate> {
        return reportTemplateRepository.findByCompanyCompanyIdAndIsActiveTrue(companyId)
    }

    /**
     * 보고서 템플릿 상세 조회
     */
    fun getReportTemplate(templateId: UUID): ReportTemplate {
        return reportTemplateRepository.findById(templateId)
            .orElseThrow { IllegalArgumentException("보고서 템플릿을 찾을 수 없습니다: $templateId") }
    }

    /**
     * 보고서 생성 (수동)
     */
    @Transactional
    fun generateReport(
        templateId: UUID,
        reportName: String,
        periodStart: LocalDate?,
        periodEnd: LocalDate?,
        userId: UUID
    ): GeneratedReport {
        val template = reportTemplateRepository.findById(templateId)
            .orElseThrow { IllegalArgumentException("보고서 템플릿을 찾을 수 없습니다: $templateId") }

        val user = userRepository.findById(userId)
            .orElseThrow { IllegalArgumentException("사용자를 찾을 수 없습니다: $userId") }

        // 보고서 데이터 생성
        val reportData = generateReportData(template, periodStart, periodEnd)

        val generatedReport = GeneratedReport(
            company = template.company,
            template = template,
            reportName = reportName,
            reportType = template.templateType,
            reportPeriodStart = periodStart,
            reportPeriodEnd = periodEnd,
            generationType = com.qiro.domain.dashboard.entity.GenerationType.MANUAL,
            generatedBy = user,
            fileFormat = template.reportFormat,
            summaryData = reportData
        )

        return generatedReportRepository.save(generatedReport)
    }

    /**
     * 자동 보고서 생성
     */
    @Transactional
    fun generateAutoReports(reportFrequency: ReportFrequency) {
        val templates = reportTemplateRepository.findAll()
            .filter { it.autoGenerate && it.reportFrequency == reportFrequency && it.isActive }

        templates.forEach { template ->
            try {
                val (periodStart, periodEnd) = calculateReportPeriod(reportFrequency)
                
                // 이미 해당 기간의 보고서가 생성되었는지 확인
                val existingReports = generatedReportRepository.findByCompanyCompanyIdAndReportPeriodStartAndReportPeriodEnd(
                    template.company.companyId,
                    periodStart,
                    periodEnd
                )

                if (existingReports.isEmpty()) {
                    val reportData = generateReportData(template, periodStart, periodEnd)
                    
                    val generatedReport = GeneratedReport(
                        company = template.company,
                        template = template,
                        reportName = "${template.templateName} - ${periodStart}",
                        reportType = template.templateType,
                        reportPeriodStart = periodStart,
                        reportPeriodEnd = periodEnd,
                        generationType = com.qiro.domain.dashboard.entity.GenerationType.AUTO,
                        fileFormat = template.reportFormat,
                        summaryData = reportData
                    )

                    generatedReportRepository.save(generatedReport)
                }
            } catch (e: Exception) {
                // 로그 기록 및 에러 처리
                println("자동 보고서 생성 실패: ${template.templateName}, 오류: ${e.message}")
            }
        }
    }

    /**
     * 생성된 보고서 조회 (페이징)
     */
    fun getGeneratedReports(companyId: UUID, pageable: Pageable): Page<GeneratedReport> {
        return generatedReportRepository.findByCompanyCompanyIdOrderByGeneratedAtDesc(companyId, pageable)
    }

    /**
     * 생성된 보고서 상세 조회
     */
    fun getGeneratedReport(reportId: UUID): GeneratedReport {
        return generatedReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("생성된 보고서를 찾을 수 없습니다: $reportId") }
    }

    /**
     * 보고서 삭제
     */
    @Transactional
    fun deleteGeneratedReport(reportId: UUID, userId: UUID) {
        val report = generatedReportRepository.findById(reportId)
            .orElseThrow { IllegalArgumentException("생성된 보고서를 찾을 수 없습니다: $reportId") }

        report.reportStatus = ReportStatus.DELETED
        generatedReportRepository.save(report)
    }

    /**
     * 보고서 데이터 생성
     */
    private fun generateReportData(
        template: ReportTemplate,
        periodStart: LocalDate?,
        periodEnd: LocalDate?
    ): Map<String, Any> {
        return when (template.templateType) {
            ReportType.FACILITY_STATUS -> {
                val overview = dashboardService.getDashboardOverview(template.company.companyId)
                mapOf(
                    "type" to "facility_status",
                    "data" to overview,
                    "period" to mapOf(
                        "start" to periodStart,
                        "end" to periodEnd
                    )
                )
            }
            ReportType.MAINTENANCE_SUMMARY -> {
                val monthlyReport = dashboardService.getMonthlyFacilityReport(
                    template.company.companyId,
                    periodStart ?: LocalDate.now()
                )
                mapOf(
                    "type" to "maintenance_summary",
                    "data" to monthlyReport,
                    "period" to mapOf(
                        "start" to periodStart,
                        "end" to periodEnd
                    )
                )
            }
            ReportType.COST_ANALYSIS -> {
                val costAnalysis = dashboardService.getCostAnalysisReport(template.company.companyId)
                mapOf(
                    "type" to "cost_analysis",
                    "data" to costAnalysis,
                    "period" to mapOf(
                        "start" to periodStart,
                        "end" to periodEnd
                    )
                )
            }
            ReportType.PERFORMANCE_REPORT -> {
                val performanceMetrics = dashboardService.getFacilityPerformanceMetrics(template.company.companyId)
                mapOf(
                    "type" to "performance_report",
                    "data" to performanceMetrics,
                    "period" to mapOf(
                        "start" to periodStart,
                        "end" to periodEnd
                    )
                )
            }
            else -> {
                mapOf(
                    "type" to "custom",
                    "message" to "사용자 정의 보고서",
                    "period" to mapOf(
                        "start" to periodStart,
                        "end" to periodEnd
                    )
                )
            }
        }
    }

    /**
     * 보고서 기간 계산
     */
    private fun calculateReportPeriod(frequency: ReportFrequency): Pair<LocalDate, LocalDate> {
        val now = LocalDate.now()
        return when (frequency) {
            ReportFrequency.DAILY -> {
                val yesterday = now.minusDays(1)
                Pair(yesterday, yesterday)
            }
            ReportFrequency.WEEKLY -> {
                val lastWeekStart = now.minusWeeks(1).with(java.time.DayOfWeek.MONDAY)
                val lastWeekEnd = lastWeekStart.plusDays(6)
                Pair(lastWeekStart, lastWeekEnd)
            }
            ReportFrequency.MONTHLY -> {
                val lastMonth = now.minusMonths(1)
                val monthStart = lastMonth.withDayOfMonth(1)
                val monthEnd = lastMonth.withDayOfMonth(lastMonth.lengthOfMonth())
                Pair(monthStart, monthEnd)
            }
            ReportFrequency.QUARTERLY -> {
                val lastQuarter = now.minusMonths(3)
                val quarterStart = lastQuarter.withDayOfMonth(1)
                val quarterEnd = quarterStart.plusMonths(2).withDayOfMonth(quarterStart.plusMonths(2).lengthOfMonth())
                Pair(quarterStart, quarterEnd)
            }
            ReportFrequency.YEARLY -> {
                val lastYear = now.minusYears(1)
                val yearStart = lastYear.withDayOfYear(1)
                val yearEnd = lastYear.withDayOfYear(lastYear.lengthOfYear())
                Pair(yearStart, yearEnd)
            }
            ReportFrequency.ON_DEMAND -> {
                Pair(now, now)
            }
        }
    }
}