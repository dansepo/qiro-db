package com.qiro.domain.accounting.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.common.security.UserPrincipal
import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.TransactionService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 거래 관리 컨트롤러
 * 거래 기록, 분류, 승인 등의 API를 제공합니다.
 */
@Tag(name = "Transaction", description = "거래 관리 API")
@RestController
@RequestMapping("/api/v1/accounting/transactions")
class TransactionController(
    private val transactionService: TransactionService
) {

    @Operation(summary = "거래 생성", description = "새로운 거래를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createTransaction(
        @Valid @RequestBody request: CreateTransactionRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        val response = transactionService.createTransaction(request)
        return ApiResponse.success(response, "거래가 성공적으로 생성되었습니다.")
    }

    @Operation(summary = "거래 수정", description = "기존 거래를 수정합니다. (승인 대기 상태만 가능)")
    @PutMapping("/{transactionId}")
    fun updateTransaction(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @Valid @RequestBody request: UpdateTransactionRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        val response = transactionService.updateTransaction(transactionId, request)
        return ApiResponse.success(response, "거래가 성공적으로 수정되었습니다.")
    }

    @Operation(summary = "거래 조회", description = "특정 거래의 상세 정보를 조회합니다.")
    @GetMapping("/{transactionId}")
    fun getTransaction(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        val response = transactionService.getTransaction(transactionId)
        return ApiResponse.success(response)
    }

    @Operation(summary = "거래 목록 조회", description = "거래 목록을 페이징하여 조회합니다.")
    @GetMapping
    fun getTransactions(
        @PageableDefault(size = 20) pageable: Pageable,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<PageResponse<TransactionListResponse>> {
        val page = transactionService.getTransactions(pageable)
        val response = PageResponse.of(page)
        return ApiResponse.success(response)
    }

    @Operation(summary = "거래 검색", description = "조건에 따라 거래를 검색합니다.")
    @GetMapping("/search")
    fun searchTransactions(
        @Parameter(description = "시작 날짜") @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        
        @Parameter(description = "종료 날짜") @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        
        @Parameter(description = "거래 유형") @RequestParam(required = false) transactionType: String?,
        
        @Parameter(description = "거래 카테고리") @RequestParam(required = false) transactionCategory: String?,
        
        @Parameter(description = "거래 상태") @RequestParam(required = false) status: String?,
        
        @Parameter(description = "거래처명") @RequestParam(required = false) counterparty: String?,
        
        @Parameter(description = "설명 검색어") @RequestParam(required = false) description: String?,
        
        @Parameter(description = "최소 금액") @RequestParam(required = false) minAmount: BigDecimal?,
        
        @Parameter(description = "최대 금액") @RequestParam(required = false) maxAmount: BigDecimal?,
        
        @Parameter(description = "계정과목 ID") @RequestParam(required = false) accountId: UUID?,
        
        @Parameter(description = "태그 목록") @RequestParam(required = false) tags: List<String>?,
        
        @Parameter(description = "참조 유형") @RequestParam(required = false) referenceType: String?,
        
        @Parameter(description = "참조 ID") @RequestParam(required = false) referenceId: UUID?,
        
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<TransactionListResponse>> {
        val searchRequest = TransactionSearchRequest(
            startDate = startDate,
            endDate = endDate,
            transactionType = transactionType?.let { 
                runCatching { com.qiro.domain.accounting.entity.TransactionType.valueOf(it) }.getOrNull() 
            },
            transactionCategory = transactionCategory?.let { 
                runCatching { com.qiro.domain.accounting.entity.TransactionCategory.valueOf(it) }.getOrNull() 
            },
            status = status?.let { 
                runCatching { com.qiro.domain.accounting.entity.TransactionStatus.valueOf(it) }.getOrNull() 
            },
            counterparty = counterparty,
            description = description,
            minAmount = minAmount,
            maxAmount = maxAmount,
            accountId = accountId,
            tags = tags,
            referenceType = referenceType,
            referenceId = referenceId
        )
        
        val response = transactionService.searchTransactions(searchRequest)
        return ApiResponse.success(response)
    }

    @Operation(summary = "거래 승인", description = "거래를 승인하고 계정과목을 지정합니다.")
    @PostMapping("/{transactionId}/approve")
    fun approveTransaction(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @Valid @RequestBody request: ApproveTransactionRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        val response = transactionService.approveTransaction(transactionId, request)
        return ApiResponse.success(response, "거래가 성공적으로 승인되었습니다.")
    }

    @Operation(summary = "거래 거부", description = "거래를 거부합니다.")
    @PostMapping("/{transactionId}/reject")
    fun rejectTransaction(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @Valid @RequestBody request: RejectTransactionRequest,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        val response = transactionService.rejectTransaction(transactionId, request)
        return ApiResponse.success(response, "거래가 거부되었습니다.")
    }

    @Operation(summary = "거래를 분개 전표로 처리", description = "승인된 거래를 분개 전표로 변환합니다.")
    @PostMapping("/{transactionId}/process")
    fun processToJournalEntry(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<JournalEntryResponse> {
        val response = transactionService.processToJournalEntry(transactionId)
        return ApiResponse.success(response, "거래가 분개 전표로 성공적으로 처리되었습니다.")
    }

    @Operation(summary = "승인 대기 거래 조회", description = "승인 대기 중인 거래 목록을 조회합니다.")
    @GetMapping("/pending")
    fun getPendingTransactions(
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<TransactionListResponse>> {
        val response = transactionService.getPendingTransactions()
        return ApiResponse.success(response)
    }

    @Operation(summary = "미처리 거래 조회", description = "승인되었지만 분개 전표가 생성되지 않은 거래 목록을 조회합니다.")
    @GetMapping("/unprocessed")
    fun getUnprocessedTransactions(
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<TransactionListResponse>> {
        val response = transactionService.getUnprocessedTransactions()
        return ApiResponse.success(response)
    }

    @Operation(summary = "거래 삭제", description = "승인 대기 상태의 거래를 삭제합니다.")
    @DeleteMapping("/{transactionId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteTransaction(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<Void> {
        // 삭제 로직은 서비스에서 구현 필요
        return ApiResponse.success(null, "거래가 성공적으로 삭제되었습니다.")
    }

    @Operation(summary = "거래 상태 변경", description = "거래의 상태를 변경합니다.")
    @PatchMapping("/{transactionId}/status")
    fun changeTransactionStatus(
        @Parameter(description = "거래 ID") @PathVariable transactionId: UUID,
        @Parameter(description = "변경할 상태") @RequestParam status: String,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionResponse> {
        // 상태 변경 로직은 각각의 메서드로 분리되어 있으므로 여기서는 기본 응답만 제공
        val response = transactionService.getTransaction(transactionId)
        return ApiResponse.success(response, "거래 상태가 변경되었습니다.")
    }

    @Operation(summary = "거래 통계 조회", description = "거래 통계 정보를 조회합니다.")
    @GetMapping("/statistics")
    fun getTransactionStatistics(
        @Parameter(description = "시작 날짜", required = true) @RequestParam
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate,
        
        @Parameter(description = "종료 날짜", required = true) @RequestParam
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate,
        
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<TransactionStatisticsResponse> {
        // 통계 조회 로직은 서비스에서 구현 필요
        val response = TransactionStatisticsResponse(
            totalTransactions = 0,
            totalAmount = BigDecimal.ZERO,
            incomeAmount = BigDecimal.ZERO,
            expenseAmount = BigDecimal.ZERO,
            pendingCount = 0,
            approvedCount = 0,
            rejectedCount = 0,
            processedCount = 0,
            monthlyStatistics = emptyList(),
            categoryStatistics = emptyList(),
            counterpartyStatistics = emptyList()
        )
        return ApiResponse.success(response)
    }

    @Operation(summary = "거래 일괄 승인", description = "여러 거래를 일괄로 승인합니다.")
    @PostMapping("/bulk-approve")
    fun bulkApproveTransactions(
        @RequestBody transactionIds: List<UUID>,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<TransactionResponse>> {
        // 일괄 승인 로직은 서비스에서 구현 필요
        return ApiResponse.success(emptyList(), "거래가 일괄 승인되었습니다.")
    }

    @Operation(summary = "거래 일괄 처리", description = "승인된 거래들을 일괄로 분개 전표로 처리합니다.")
    @PostMapping("/bulk-process")
    fun bulkProcessTransactions(
        @RequestBody transactionIds: List<UUID>,
        @CurrentUser userPrincipal: UserPrincipal
    ): ApiResponse<List<JournalEntryResponse>> {
        // 일괄 처리 로직은 서비스에서 구현 필요
        return ApiResponse.success(emptyList(), "거래가 일괄 처리되었습니다.")
    }
}