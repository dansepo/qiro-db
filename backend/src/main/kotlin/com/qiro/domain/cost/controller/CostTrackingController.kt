package com.qiro.domain.cost.controller

import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.service.CostTrackingService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 비용 추적 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/costs")
@Tag(name = "Cost Tracking", description = "비용 추적 관리 API")
class CostTrackingController(
    private val costTrackingService: CostTrackingService
) {

    @Operation(summary = "비용 기록 생성", description = "새로운 비용 기록을 생성합니다")
    @PostMapping
    fun createCostRecord(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateCostTrackingRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<CostTrackingDto> {
        val result = costTrackingService.createCostRecord(companyId, request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "비용 기록 수정", description = "기존 비용 기록을 수정합니다")
    @PutMapping("/{costId}")
    fun updateCostRecord(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "비용 ID") @PathVariable costId: UUID,
        @RequestBody request: UpdateCostTrackingRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<CostTrackingDto> {
        val result = costTrackingService.updateCostRecord(costId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 승인", description = "비용 기록을 승인합니다")
    @PostMapping("/{costId}/approve")
    fun approveCost(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "비용 ID") @PathVariable costId: UUID,
        @RequestBody request: ApproveCostRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<CostTrackingDto> {
        val result = costTrackingService.approveCost(costId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 기록 조회", description = "특정 비용 기록을 조회합니다")
    @GetMapping("/{costId}")
    fun getCostRecord(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "비용 ID") @PathVariable costId: UUID
    ): ResponseEntity<CostTrackingDto> {
        val result = costTrackingService.getCostRecord(costId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 기록 목록 조회", description = "회사의 모든 비용 기록을 조회합니다")
    @GetMapping
    fun getCostRecords(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<CostTrackingDto>> {
        val result = costTrackingService.getCostRecords(companyId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "필터링된 비용 기록 조회", description = "조건에 따라 필터링된 비용 기록을 조회합니다")
    @GetMapping("/search")
    fun getCostRecordsWithFilter(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "비용 유형") @RequestParam(required = false) costType: CostType?,
        @Parameter(description = "비용 카테고리") @RequestParam(required = false) category: CostCategory?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @Parameter(description = "최소 금액") @RequestParam(required = false) minAmount: java.math.BigDecimal?,
        @Parameter(description = "최대 금액") @RequestParam(required = false) maxAmount: java.math.BigDecimal?,
        @Parameter(description = "결제 방법") @RequestParam(required = false) paymentMethod: PaymentMethod?,
        @Parameter(description = "예산 카테고리") @RequestParam(required = false) budgetCategory: String?,
        @Parameter(description = "예산 연도") @RequestParam(required = false) budgetYear: Int?,
        @Parameter(description = "승인 상태") @RequestParam(required = false) approvalStatus: ApprovalStatus?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<CostTrackingDto>> {
        val filter = CostTrackingFilter(
            costType = costType,
            category = category,
            startDate = startDate,
            endDate = endDate,
            minAmount = minAmount,
            maxAmount = maxAmount,
            paymentMethod = paymentMethod,
            budgetCategory = budgetCategory,
            budgetYear = budgetYear,
            approvalStatus = approvalStatus
        )
        val result = costTrackingService.getCostRecordsWithFilter(companyId, filter, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 통계 조회", description = "지정된 기간의 비용 통계를 조회합니다")
    @GetMapping("/statistics")
    fun getCostStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        @Parameter(description = "카테고리") @RequestParam(required = false) category: CostCategory?
    ): ResponseEntity<CostStatisticsDto> {
        val result = costTrackingService.getCostStatistics(companyId, startDate, endDate, category)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "월별 비용 트렌드 조회", description = "연도별 월별 비용 트렌드를 조회합니다")
    @GetMapping("/trends/monthly")
    fun getMonthlyCostTrend(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "연도") @RequestParam year: Int,
        @Parameter(description = "카테고리") @RequestParam(required = false) category: CostCategory?
    ): ResponseEntity<List<MonthlyCostTrendDto>> {
        val result = costTrackingService.getMonthlyCostTrend(companyId, year, category)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 요약 조회", description = "지정된 기간의 비용 요약 정보를 조회합니다")
    @GetMapping("/summary")
    fun getCostSummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate
    ): ResponseEntity<CostSummaryDto> {
        val result = costTrackingService.getCostSummary(companyId, startDate, endDate)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "작업 지시서별 비용 조회", description = "특정 작업 지시서의 모든 비용을 조회합니다")
    @GetMapping("/work-orders/{workOrderId}")
    fun getCostsByWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID
    ): ResponseEntity<List<CostTrackingDto>> {
        val result = costTrackingService.getCostsByWorkOrder(workOrderId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "정비 계획별 비용 조회", description = "특정 정비 계획의 모든 비용을 조회합니다")
    @GetMapping("/maintenance/{maintenanceId}")
    fun getCostsByMaintenance(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "정비 계획 ID") @PathVariable maintenanceId: UUID
    ): ResponseEntity<List<CostTrackingDto>> {
        val result = costTrackingService.getCostsByMaintenance(maintenanceId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "고장 신고별 비용 조회", description = "특정 고장 신고의 모든 비용을 조회합니다")
    @GetMapping("/fault-reports/{faultReportId}")
    fun getCostsByFaultReport(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "고장 신고 ID") @PathVariable faultReportId: UUID
    ): ResponseEntity<List<CostTrackingDto>> {
        val result = costTrackingService.getCostsByFaultReport(faultReportId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "비용 기록 삭제", description = "비용 기록을 삭제합니다")
    @DeleteMapping("/{costId}")
    fun deleteCostRecord(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "비용 ID") @PathVariable costId: UUID
    ): ResponseEntity<Void> {
        costTrackingService.deleteCostRecord(costId)
        return ResponseEntity.noContent().build()
    }
}