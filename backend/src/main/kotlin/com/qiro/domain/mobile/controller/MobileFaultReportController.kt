package com.qiro.domain.mobile.controller

import com.qiro.domain.mobile.dto.*
import com.qiro.domain.mobile.service.MobileFaultReportService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 모바일 고장 신고 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/mobile/companies/{companyId}/fault-reports")
@Tag(name = "Mobile Fault Reports", description = "모바일 고장 신고 API")
class MobileFaultReportController(
    private val mobileFaultReportService: MobileFaultReportService
) {

    @Operation(summary = "모바일 고장 신고 생성", description = "모바일에서 새로운 고장 신고를 생성합니다")
    @PostMapping
    fun createMobileFaultReport(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateMobileFaultReportRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileFaultReportDto> {
        val result = mobileFaultReportService.createMobileFaultReport(companyId, request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "모바일 고장 신고 수정", description = "기존 고장 신고를 수정합니다")
    @PutMapping("/{reportId}")
    fun updateMobileFaultReport(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "신고 ID") @PathVariable reportId: UUID,
        @RequestBody request: UpdateMobileFaultReportRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileFaultReportDto> {
        val result = mobileFaultReportService.updateMobileFaultReport(reportId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모바일 고장 신고 상세 조회", description = "특정 고장 신고의 상세 정보를 조회합니다")
    @GetMapping("/{reportId}")
    fun getMobileFaultReportDetail(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "신고 ID") @PathVariable reportId: UUID
    ): ResponseEntity<MobileFaultReportDetailDto> {
        val result = mobileFaultReportService.getMobileFaultReportDetail(reportId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모바일 고장 신고 목록 조회", description = "고장 신고 목록을 조회합니다")
    @GetMapping
    fun getMobileFaultReports(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "상태 필터") @RequestParam(required = false) status: com.qiro.domain.fault.dto.FaultStatus?,
        @Parameter(description = "우선순위 필터") @RequestParam(required = false) priority: com.qiro.domain.fault.dto.FaultPriority?,
        @Parameter(description = "위치 필터") @RequestParam(required = false) location: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<MobileFaultReportListDto>> {
        val filter = MobileFaultReportFilter(
            status = status,
            priority = priority,
            location = location
        )
        val result = mobileFaultReportService.getMobileFaultReports(companyId, filter, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "내 고장 신고 목록 조회", description = "현재 사용자가 신고한 고장 신고 목록을 조회합니다")
    @GetMapping("/my")
    fun getMyFaultReports(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<MobileFaultReportListDto>> {
        val result = mobileFaultReportService.getMyFaultReports(companyId, userId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "긴급 고장 신고 목록 조회", description = "긴급 우선순위의 고장 신고 목록을 조회합니다")
    @GetMapping("/urgent")
    fun getUrgentFaultReports(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<List<MobileFaultReportListDto>> {
        val result = mobileFaultReportService.getUrgentFaultReports(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "고장 신고 취소", description = "고장 신고를 취소합니다")
    @PostMapping("/{reportId}/cancel")
    fun cancelFaultReport(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "신고 ID") @PathVariable reportId: UUID,
        @RequestBody request: Map<String, String>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileFaultReportDto> {
        val reason = request["reason"] ?: "사용자 요청"
        val result = mobileFaultReportService.cancelFaultReport(reportId, userId, reason)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "고장 신고 사진 추가", description = "기존 고장 신고에 사진을 추가합니다")
    @PostMapping("/{reportId}/photos")
    fun addPhotosToFaultReport(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "신고 ID") @PathVariable reportId: UUID,
        @RequestBody request: Map<String, List<String>>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileFaultReportDto> {
        val photos = request["photos"] ?: emptyList()
        val result = mobileFaultReportService.addPhotosToFaultReport(reportId, photos, userId)
        return ResponseEntity.ok(result)
    }
}