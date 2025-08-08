package com.qiro.domain.dashboard.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.dashboard.entity.*
import com.qiro.domain.dashboard.service.ReportService
import com.qiro.security.CustomUserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 보고서 컨트롤러
 * 보고서 템플릿 관리 및 보고서 생성 API 엔드포인트
 */
@Tag(name = "Report", description = "보고서 관리 API")
@RestController
@RequestMapping("/api/v1/reports")
@PreAuthorize("hasRole('USER')")
class ReportController(
    private val reportService: ReportService
) {

    @Operation(
        summary = "보고서 템플릿 생성",
        description = "새로운 보고서 템플릿을 생성합니다."
    )
    @PostMapping("/templates")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun createReportTemplate(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @RequestBody request: CreateReportTemplateRequest
    ): ResponseEntity<ApiResponse<ReportTemplate>> {
        val template = reportService.createReportTemplate(
            companyId = userPrincipal.companyId,
            templateName = request.templateName,
            templateType = request.templateType,
            description = request.description,
            reportFormat = request.reportFormat,
            reportFrequency = request.reportFrequency,
            autoGenerate = request.autoGenerate,
            userId = userPrincipal.userId
        )
        
        return ResponseEntity.ok(ApiResponse.success(template, "보고서 템플릿 생성 성공"))
    }

    @Operation(
        summary = "보고서 템플릿 수정",
        description = "기존 보고서 템플릿을 수정합니다."
    )
    @PutMapping("/templates/{templateId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun updateReportTemplate(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID,
        @RequestBody request: UpdateReportTemplateRequest
    ): ResponseEntity<ApiResponse<ReportTemplate>> {
        val template = reportService.updateReportTemplate(
            templateId = templateId,
            templateName = request.templateName,
            description = request.description,
            reportFormat = request.reportFormat,
            reportFrequency = request.reportFrequency,
            autoGenerate = request.autoGenerate,
            userId = userPrincipal.userId
        )
        
        return ResponseEntity.ok(ApiResponse.success(template, "보고서 템플릿 수정 성공"))
    }

    @Operation(
        summary = "보고서 템플릿 삭제",
        description = "보고서 템플릿을 삭제(비활성화)합니다."
    )
    @DeleteMapping("/templates/{templateId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun deleteReportTemplate(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        reportService.deleteReportTemplate(templateId, userPrincipal.userId)
        return ResponseEntity.ok(ApiResponse.success(Unit, "보고서 템플릿 삭제 성공"))
    }

    @Operation(
        summary = "보고서 템플릿 목록 조회",
        description = "회사의 모든 보고서 템플릿을 조회합니다."
    )
    @GetMapping("/templates")
    fun getReportTemplates(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<List<ReportTemplate>>> {
        val templates = reportService.getReportTemplates(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(templates, "보고서 템플릿 목록 조회 성공"))
    }

    @Operation(
        summary = "보고서 템플릿 상세 조회",
        description = "특정 보고서 템플릿의 상세 정보를 조회합니다."
    )
    @GetMapping("/templates/{templateId}")
    fun getReportTemplate(
        @Parameter(description = "템플릿 ID") @PathVariable templateId: UUID
    ): ResponseEntity<ApiResponse<ReportTemplate>> {
        val template = reportService.getReportTemplate(templateId)
        return ResponseEntity.ok(ApiResponse.success(template, "보고서 템플릿 상세 조회 성공"))
    }

    @Operation(
        summary = "보고서 생성",
        description = "템플릿을 기반으로 보고서를 생성합니다."
    )
    @PostMapping("/generate")
    fun generateReport(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @RequestBody request: GenerateReportRequest
    ): ResponseEntity<ApiResponse<GeneratedReport>> {
        val report = reportService.generateReport(
            templateId = request.templateId,
            reportName = request.reportName,
            periodStart = request.periodStart,
            periodEnd = request.periodEnd,
            userId = userPrincipal.userId
        )
        
        return ResponseEntity.ok(ApiResponse.success(report, "보고서 생성 성공"))
    }

    @Operation(
        summary = "생성된 보고서 목록 조회",
        description = "생성된 보고서 목록을 페이징하여 조회합니다."
    )
    @GetMapping("/generated")
    fun getGeneratedReports(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<GeneratedReport>>> {
        val reports = reportService.getGeneratedReports(userPrincipal.companyId, pageable)
        return ResponseEntity.ok(ApiResponse.success(reports, "생성된 보고서 목록 조회 성공"))
    }

    @Operation(
        summary = "생성된 보고서 상세 조회",
        description = "특정 생성된 보고서의 상세 정보를 조회합니다."
    )
    @GetMapping("/generated/{reportId}")
    fun getGeneratedReport(
        @Parameter(description = "보고서 ID") @PathVariable reportId: UUID
    ): ResponseEntity<ApiResponse<GeneratedReport>> {
        val report = reportService.getGeneratedReport(reportId)
        return ResponseEntity.ok(ApiResponse.success(report, "생성된 보고서 상세 조회 성공"))
    }

    @Operation(
        summary = "생성된 보고서 삭제",
        description = "생성된 보고서를 삭제합니다."
    )
    @DeleteMapping("/generated/{reportId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun deleteGeneratedReport(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "보고서 ID") @PathVariable reportId: UUID
    ): ResponseEntity<ApiResponse<Unit>> {
        reportService.deleteGeneratedReport(reportId, userPrincipal.userId)
        return ResponseEntity.ok(ApiResponse.success(Unit, "생성된 보고서 삭제 성공"))
    }

    @Operation(
        summary = "자동 보고서 생성 실행",
        description = "지정된 주기의 자동 보고서를 생성합니다."
    )
    @PostMapping("/auto-generate")
    @PreAuthorize("hasRole('ADMIN')")
    fun generateAutoReports(
        @Parameter(description = "보고서 주기") @RequestParam frequency: ReportFrequency
    ): ResponseEntity<ApiResponse<Unit>> {
        reportService.generateAutoReports(frequency)
        return ResponseEntity.ok(ApiResponse.success(Unit, "자동 보고서 생성 완료"))
    }
}

/**
 * 보고서 템플릿 생성 요청 DTO
 */
data class CreateReportTemplateRequest(
    val templateName: String,
    val templateType: ReportType,
    val description: String?,
    val reportFormat: ReportFormat,
    val reportFrequency: ReportFrequency,
    val autoGenerate: Boolean
)

/**
 * 보고서 템플릿 수정 요청 DTO
 */
data class UpdateReportTemplateRequest(
    val templateName: String?,
    val description: String?,
    val reportFormat: ReportFormat?,
    val reportFrequency: ReportFrequency?,
    val autoGenerate: Boolean?
)

/**
 * 보고서 생성 요청 DTO
 */
data class GenerateReportRequest(
    val templateId: UUID,
    val reportName: String,
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    val periodStart: LocalDate?,
    @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
    val periodEnd: LocalDate?
)