package com.qiro.domain.billing.controller

import com.qiro.domain.billing.dto.*
import com.qiro.domain.billing.entity.BillingStatus
import com.qiro.domain.billing.service.MonthlyBillingService
import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.common.security.UserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.util.*

@Tag(name = "월별 관리비 관리", description = "월별 관리비 청구 및 수납 관리 API")
@RestController
@RequestMapping("/api/v1/billing/monthly")
class MonthlyBillingController(
    private val monthlyBillingService: MonthlyBillingService
) {

    @Operation(summary = "청구서 목록 조회", description = "회사의 모든 월별 청구서 목록을 조회합니다")
    @GetMapping
    fun getBillings(
        @CurrentUser userPrincipal: UserPrincipal,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.getBillings(userPrincipal.companyId, pageable)
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "상태별 청구서 목록 조회", description = "특정 상태의 청구서 목록을 조회합니다")
    @GetMapping("/status/{status}")
    fun getBillingsByStatus(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 상태") @PathVariable status: BillingStatus,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.getBillingsByStatus(
            userPrincipal.companyId, status, pageable
        )
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "연월별 청구서 목록 조회", description = "특정 연월의 청구서 목록을 조회합니다")
    @GetMapping("/year/{year}/month/{month}")
    fun getBillingsByYearMonth(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "연도") @PathVariable year: Int,
        @Parameter(description = "월") @PathVariable month: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.getBillingsByYearMonth(
            userPrincipal.companyId, year, month, pageable
        )
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "청구서 검색", description = "청구서 번호, 세대번호, 임차인명으로 청구서를 검색합니다")
    @GetMapping("/search")
    fun searchBillings(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 상태") @RequestParam status: BillingStatus,
        @Parameter(description = "검색어") @RequestParam search: String,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.searchBillings(
            userPrincipal.companyId, status, search, pageable
        )
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "청구서 상세 조회", description = "특정 청구서의 상세 정보를 조회합니다")
    @GetMapping("/{billingId}")
    fun getBilling(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 ID") @PathVariable billingId: UUID
    ): ApiResponse<MonthlyBillingDto> {
        val billing = monthlyBillingService.getBilling(billingId, userPrincipal.companyId)
        return ApiResponse.success(billing)
    }

    @Operation(summary = "연체 청구서 조회", description = "납부 기한이 지난 연체 청구서 목록을 조회합니다")
    @GetMapping("/overdue")
    fun getOverdueBillings(
        @CurrentUser userPrincipal: UserPrincipal,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.getOverdueBillings(userPrincipal.companyId, pageable)
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "납부 예정 청구서 조회", description = "지정된 일수 내에 납부 예정인 청구서 목록을 조회합니다")
    @GetMapping("/upcoming-due")
    fun getUpcomingDueBillings(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "조회 기간 (일)") @RequestParam(defaultValue = "7") days: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<MonthlyBillingSummaryDto>> {
        val billings = monthlyBillingService.getUpcomingDueBillings(
            userPrincipal.companyId, days, pageable
        )
        return ApiResponse.success(PageResponse.of(billings))
    }

    @Operation(summary = "청구서 통계 조회", description = "월별 청구서 관련 통계 정보를 조회합니다")
    @GetMapping("/statistics")
    fun getBillingStatistics(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "연도") @RequestParam year: Int,
        @Parameter(description = "월 (선택사항)") @RequestParam(required = false) month: Int?
    ): ApiResponse<BillingStatisticsDto> {
        val statistics = monthlyBillingService.getBillingStatistics(
            userPrincipal.companyId, year, month
        )
        return ApiResponse.success(statistics)
    }

    @Operation(summary = "청구서 생성", description = "새로운 월별 청구서를 생성합니다")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createBilling(
        @CurrentUser userPrincipal: UserPrincipal,
        @Valid @RequestBody request: CreateMonthlyBillingRequest
    ): ApiResponse<MonthlyBillingDto> {
        val billing = monthlyBillingService.createBilling(userPrincipal.companyId, request)
        return ApiResponse.success(billing)
    }

    @Operation(summary = "청구서 수정", description = "청구서 정보를 수정합니다 (결제 완료 전까지만 가능)")
    @PutMapping("/{billingId}")
    fun updateBilling(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 ID") @PathVariable billingId: UUID,
        @Valid @RequestBody request: UpdateMonthlyBillingRequest
    ): ApiResponse<MonthlyBillingDto> {
        val billing = monthlyBillingService.updateBilling(
            billingId, userPrincipal.companyId, request
        )
        return ApiResponse.success(billing)
    }

    @Operation(summary = "결제 처리", description = "청구서에 대한 결제를 처리합니다")
    @PostMapping("/{billingId}/payment")
    fun processPayment(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 ID") @PathVariable billingId: UUID,
        @Valid @RequestBody request: ProcessPaymentRequest
    ): ApiResponse<MonthlyBillingDto> {
        val billing = monthlyBillingService.processPayment(
            billingId, userPrincipal.companyId, request
        )
        return ApiResponse.success(billing)
    }

    @Operation(summary = "청구서 발송", description = "청구서를 임차인에게 발송합니다")
    @PostMapping("/{billingId}/send")
    fun sendBilling(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 ID") @PathVariable billingId: UUID,
        @Valid @RequestBody request: SendBillingRequest
    ): ApiResponse<MonthlyBillingDto> {
        val billing = monthlyBillingService.sendBilling(
            billingId, userPrincipal.companyId, request
        )
        return ApiResponse.success(billing)
    }

    @Operation(summary = "연체료 계산", description = "지정된 연월의 연체 청구서에 대해 연체료를 계산하고 적용합니다")
    @PostMapping("/calculate-late-fees")
    fun calculateLateFees(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "연도") @RequestParam year: Int,
        @Parameter(description = "월") @RequestParam month: Int
    ): ApiResponse<Map<String, Int>> {
        val updatedCount = monthlyBillingService.calculateLateFees(
            userPrincipal.companyId, year, month
        )
        return ApiResponse.success(mapOf("updatedCount" to updatedCount))
    }

    @Operation(summary = "청구서 일괄 생성", description = "지정된 건물들의 활성 계약에 대해 월별 청구서를 일괄 생성합니다")
    @PostMapping("/bulk-create")
    fun bulkCreateBillings(
        @CurrentUser userPrincipal: UserPrincipal,
        @Valid @RequestBody request: BulkCreateBillingRequest
    ): ApiResponse<BulkCreateResultDto> {
        val result = monthlyBillingService.bulkCreateBillings(userPrincipal.companyId, request)
        return ApiResponse.success(result)
    }

    @Operation(summary = "청구서 삭제", description = "초안 상태의 청구서를 삭제합니다")
    @DeleteMapping("/{billingId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteBilling(
        @CurrentUser userPrincipal: UserPrincipal,
        @Parameter(description = "청구서 ID") @PathVariable billingId: UUID
    ): ApiResponse<Unit> {
        monthlyBillingService.deleteBilling(billingId, userPrincipal.companyId)
        return ApiResponse.success()
    }
}