package com.qiro.domain.fault.controller

import com.qiro.common.response.ApiResponse
import com.qiro.domain.fault.dto.*
import com.qiro.domain.fault.entity.*
import com.qiro.domain.fault.service.FaultReportService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 고장 신고 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/fault-reports")
@Tag(name = "고장 신고", description = "고장 신고 관리 API")
class FaultReportController(
    private val faultReportService: FaultReportService
) {

    /**
     * 고장 신고 생성
     */
    @PostMapping
    @Operation(summary = "고장 신고 생성", description = "새로운 고장 신고를 생성합니다.")
    fun createFaultReport(
        @Valid @RequestBody request: CreateFaultReportRequest
    ): ApiResponse<FaultReportDto> {
        val faultReport = faultReportService.createFaultReport(request)
        return ApiResponse.success(faultReport, "고장 신고가 성공적으로 생성되었습니다.")
    }

    /**
     * 고장 신고 조회
     */
    @GetMapping("/{id}")
    @Operation(summary = "고장 신고 조회", description = "고장 신고 상세 정보를 조회합니다.")
    fun getFaultReport(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID
    ): ApiResponse<FaultReportDto> {
        val faultReport = faultReportService.getFaultReport(id)
        return ApiResponse.success(faultReport)
    }

    /**
     * 고장 신고 목록 조회
     */
    @GetMapping
    @Operation(summary = "고장 신고 목록 조회", description = "고장 신고 목록을 조회합니다.")
    fun getFaultReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "건물 ID") @RequestParam(required = false) buildingId: UUID?,
        @Parameter(description = "세대 ID") @RequestParam(required = false) unitId: UUID?,
        @Parameter(description = "분류 ID") @RequestParam(required = false) categoryId: UUID?,
        @Parameter(description = "신고 상태") @RequestParam(required = false) reportStatus: String?,
        @Parameter(description = "해결 상태") @RequestParam(required = false) resolutionStatus: String?,
        @Parameter(description = "우선순위") @RequestParam(required = false) faultPriority: String?,
        @Parameter(description = "긴급도") @RequestParam(required = false) faultUrgency: String?,
        @Parameter(description = "고장 유형") @RequestParam(required = false) faultType: String?,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?,
        @Parameter(description = "신고자 유형") @RequestParam(required = false) reporterType: String?,
        @Parameter(description = "시작 날짜") @RequestParam(required = false) dateFrom: String?,
        @Parameter(description = "종료 날짜") @RequestParam(required = false) dateTo: String?,
        @Parameter(description = "초과 여부") @RequestParam(required = false) isOverdue: Boolean?,
        @Parameter(description = "긴급 여부") @RequestParam(required = false) isUrgent: Boolean?,
        @Parameter(description = "검색 키워드") @RequestParam(required = false) searchKeyword: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<Page<FaultReportDto>> {
        val filter = FaultReportFilter(
            companyId = companyId,
            buildingId = buildingId,
            unitId = unitId,
            categoryId = categoryId,
            reportStatus = reportStatus?.let { com.qiro.domain.fault.entity.ReportStatus.valueOf(it) },
            resolutionStatus = resolutionStatus?.let { com.qiro.domain.fault.entity.ResolutionStatus.valueOf(it) },
            faultPriority = faultPriority?.let { com.qiro.domain.fault.entity.FaultPriority.valueOf(it) },
            faultUrgency = faultUrgency?.let { com.qiro.domain.fault.entity.FaultUrgency.valueOf(it) },
            faultType = faultType?.let { com.qiro.domain.fault.entity.FaultType.valueOf(it) },
            assignedTo = assignedTo,
            reporterType = reporterType?.let { com.qiro.domain.fault.entity.ReporterType.valueOf(it) },
            dateFrom = dateFrom?.let { java.time.LocalDateTime.parse(it) },
            dateTo = dateTo?.let { java.time.LocalDateTime.parse(it) },
            isOverdue = isOverdue,
            isUrgent = isUrgent,
            searchKeyword = searchKeyword
        )

        val faultReports = faultReportService.getFaultReports(filter, pageable)
        return ApiResponse.success(faultReports)
    }

    /**
     * 긴급 고장 신고 조회
     */
    @GetMapping("/urgent")
    @Operation(summary = "긴급 고장 신고 조회", description = "긴급 고장 신고 목록을 조회합니다.")
    fun getUrgentFaultReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultReportDto>> {
        val urgentReports = faultReportService.getUrgentFaultReports(companyId)
        return ApiResponse.success(urgentReports)
    }

    /**
     * 응답 시간 초과 신고 조회
     */
    @GetMapping("/overdue-response")
    @Operation(summary = "응답 시간 초과 신고 조회", description = "응답 시간이 초과된 고장 신고를 조회합니다.")
    fun getOverdueResponseReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultReportDto>> {
        val overdueReports = faultReportService.getOverdueResponseReports(companyId)
        return ApiResponse.success(overdueReports)
    }

    /**
     * 해결 시간 초과 신고 조회
     */
    @GetMapping("/overdue-resolution")
    @Operation(summary = "해결 시간 초과 신고 조회", description = "해결 시간이 초과된 고장 신고를 조회합니다.")
    fun getOverdueResolutionReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultReportDto>> {
        val overdueReports = faultReportService.getOverdueResolutionReports(companyId)
        return ApiResponse.success(overdueReports)
    }

    /**
     * 미배정 신고 조회
     */
    @GetMapping("/unassigned")
    @Operation(summary = "미배정 신고 조회", description = "담당자가 배정되지 않은 고장 신고를 조회합니다.")
    fun getUnassignedReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultReportDto>> {
        val unassignedReports = faultReportService.getUnassignedReports(companyId)
        return ApiResponse.success(unassignedReports)
    }

    /**
     * 진행 중인 신고 조회
     */
    @GetMapping("/active")
    @Operation(summary = "진행 중인 신고 조회", description = "현재 진행 중인 고장 신고를 조회합니다.")
    fun getActiveReports(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID
    ): ApiResponse<List<FaultReportDto>> {
        val activeReports = faultReportService.getActiveReports(companyId)
        return ApiResponse.success(activeReports)
    }

    /**
     * 고장 신고 업데이트
     */
    @PutMapping("/{id}")
    @Operation(summary = "고장 신고 업데이트", description = "고장 신고 정보를 업데이트합니다.")
    fun updateFaultReport(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateFaultReportRequest
    ): ApiResponse<FaultReportDto> {
        val updatedReport = faultReportService.updateFaultReport(id, request)
        return ApiResponse.success(updatedReport, "고장 신고가 성공적으로 업데이트되었습니다.")
    }

    /**
     * 고장 신고 상태 업데이트
     */
    @PatchMapping("/{id}/status")
    @Operation(summary = "고장 신고 상태 업데이트", description = "고장 신고의 상태를 업데이트합니다.")
    fun updateFaultReportStatus(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateFaultReportStatusRequest
    ): ApiResponse<FaultReportDto> {
        val updatedReport = faultReportService.updateFaultReportStatus(id, request)
        return ApiResponse.success(updatedReport, "고장 신고 상태가 성공적으로 업데이트되었습니다.")
    }

    /**
     * 담당자 배정
     */
    @PatchMapping("/{id}/assign")
    @Operation(summary = "담당자 배정", description = "고장 신고에 담당자를 배정합니다.")
    fun assignTechnician(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID,
        @Parameter(description = "담당자 ID") @RequestParam technicianId: UUID,
        @Parameter(description = "팀명") @RequestParam(required = false) team: String?
    ): ApiResponse<FaultReportDto> {
        val assignedReport = faultReportService.assignTechnician(id, technicianId, team)
        return ApiResponse.success(assignedReport, "담당자가 성공적으로 배정되었습니다.")
    }

    /**
     * 접수 확인
     */
    @PatchMapping("/{id}/acknowledge")
    @Operation(summary = "접수 확인", description = "고장 신고를 접수 확인합니다.")
    fun acknowledgeFaultReport(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID,
        @Parameter(description = "확인자 ID") @RequestParam userId: UUID
    ): ApiResponse<FaultReportDto> {
        val acknowledgedReport = faultReportService.acknowledgeFaultReport(id, userId)
        return ApiResponse.success(acknowledgedReport, "고장 신고가 성공적으로 접수 확인되었습니다.")
    }

    /**
     * 작업 시작
     */
    @PatchMapping("/{id}/start-work")
    @Operation(summary = "작업 시작", description = "고장 신고 작업을 시작합니다.")
    fun startWork(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID
    ): ApiResponse<FaultReportDto> {
        val startedReport = faultReportService.startWork(id)
        return ApiResponse.success(startedReport, "작업이 성공적으로 시작되었습니다.")
    }

    /**
     * 해결 완료
     */
    @PatchMapping("/{id}/complete")
    @Operation(summary = "해결 완료", description = "고장 신고를 해결 완료 처리합니다.")
    fun completeFaultReport(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID,
        @Parameter(description = "완료자 ID") @RequestParam userId: UUID,
        @Valid @RequestBody request: CompleteFaultReportRequest
    ): ApiResponse<FaultReportDto> {
        val completedReport = faultReportService.completeFaultReport(id, userId, request)
        return ApiResponse.success(completedReport, "고장 신고가 성공적으로 완료되었습니다.")
    }

    /**
     * 신고자별 신고 이력 조회
     */
    @GetMapping("/reporter-history")
    @Operation(summary = "신고자별 신고 이력 조회", description = "특정 신고자의 고장 신고 이력을 조회합니다.")
    fun getReporterHistory(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "신고자 유형") @RequestParam reporterType: String,
        @Parameter(description = "신고자 이름") @RequestParam(required = false) reporterName: String?,
        @Parameter(description = "신고자 세대 ID") @RequestParam(required = false) reporterUnitId: UUID?,
        @Parameter(description = "신고자 연락처") @RequestParam(required = false) reporterContact: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<Page<FaultReportDto>> {
        val reporterHistoryFilter = ReporterHistoryFilter(
            companyId = companyId,
            reporterType = ReporterType.valueOf(reporterType),
            reporterName = reporterName,
            reporterUnitId = reporterUnitId,
            reporterContact = reporterContact
        )
        
        val reporterHistory = faultReportService.getReporterHistory(reporterHistoryFilter, pageable)
        return ApiResponse.success(reporterHistory)
    }

    /**
     * 신고자별 통계 조회
     */
    @GetMapping("/reporter-statistics")
    @Operation(summary = "신고자별 통계 조회", description = "신고자별 통계 정보를 조회합니다.")
    fun getReporterStatistics(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "신고자 유형") @RequestParam(required = false) reporterType: String?,
        @Parameter(description = "기간 시작") @RequestParam(required = false) dateFrom: String?,
        @Parameter(description = "기간 종료") @RequestParam(required = false) dateTo: String?
    ): ApiResponse<List<ReporterStatisticsDto>> {
        val statistics = faultReportService.getReporterStatistics(
            companyId = companyId,
            reporterType = reporterType?.let { ReporterType.valueOf(it) },
            dateFrom = dateFrom?.let { LocalDateTime.parse(it) },
            dateTo = dateTo?.let { LocalDateTime.parse(it) }
        )
        return ApiResponse.success(statistics)
    }

    /**
     * 고장 신고 통계 조회
     */
    @GetMapping("/statistics")
    @Operation(summary = "고장 신고 통계 조회", description = "고장 신고 전체 통계를 조회합니다.")
    fun getFaultReportStatistics(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "기간 시작") @RequestParam(required = false) dateFrom: String?,
        @Parameter(description = "기간 종료") @RequestParam(required = false) dateTo: String?,
        @Parameter(description = "그룹핑 기준") @RequestParam(required = false) groupBy: String?
    ): ApiResponse<FaultReportStatisticsDto> {
        val statistics = faultReportService.getFaultReportStatistics(
            companyId = companyId,
            dateFrom = dateFrom?.let { LocalDateTime.parse(it) },
            dateTo = dateTo?.let { LocalDateTime.parse(it) },
            groupBy = groupBy
        )
        return ApiResponse.success(statistics)
    }

    /**
     * 응답 시간 통계 조회
     */
    @GetMapping("/response-time-statistics")
    @Operation(summary = "응답 시간 통계 조회", description = "고장 신고 응답 시간 통계를 조회합니다.")
    fun getResponseTimeStatistics(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "기간 시작") @RequestParam(required = false) dateFrom: String?,
        @Parameter(description = "기간 종료") @RequestParam(required = false) dateTo: String?
    ): ApiResponse<ResponseTimeStatisticsDto> {
        val statistics = faultReportService.getResponseTimeStatistics(
            companyId = companyId,
            dateFrom = dateFrom?.let { LocalDateTime.parse(it) },
            dateTo = dateTo?.let { LocalDateTime.parse(it) }
        )
        return ApiResponse.success(statistics)
    }

    /**
     * 고장 유형별 통계 조회
     */
    @GetMapping("/fault-type-statistics")
    @Operation(summary = "고장 유형별 통계 조회", description = "고장 유형별 통계를 조회합니다.")
    fun getFaultTypeStatistics(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "기간 시작") @RequestParam(required = false) dateFrom: String?,
        @Parameter(description = "기간 종료") @RequestParam(required = false) dateTo: String?
    ): ApiResponse<List<FaultTypeStatisticsDto>> {
        val statistics = faultReportService.getFaultTypeStatistics(
            companyId = companyId,
            dateFrom = dateFrom?.let { LocalDateTime.parse(it) },
            dateTo = dateTo?.let { LocalDateTime.parse(it) }
        )
        return ApiResponse.success(statistics)
    }

    /**
     * 월별 고장 신고 추이 조회
     */
    @GetMapping("/monthly-trend")
    @Operation(summary = "월별 고장 신고 추이 조회", description = "월별 고장 신고 추이를 조회합니다.")
    fun getMonthlyTrend(
        @Parameter(description = "회사 ID") @RequestParam companyId: UUID,
        @Parameter(description = "조회 개월 수") @RequestParam(defaultValue = "12") months: Int
    ): ApiResponse<List<MonthlyTrendDto>> {
        val trend = faultReportService.getMonthlyTrend(companyId, months)
        return ApiResponse.success(trend)
    }

    /**
     * 고장 신고 삭제
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "고장 신고 삭제", description = "고장 신고를 삭제합니다.")
    fun deleteFaultReport(
        @Parameter(description = "고장 신고 ID") @PathVariable id: UUID
    ): ApiResponse<Unit> {
        faultReportService.deleteFaultReport(id)
        return ApiResponse.success(message = "고장 신고가 성공적으로 삭제되었습니다.")
    }
}