package com.qiro.domain.accounting.dto

import com.qiro.domain.accounting.entity.TransactionCategory
import com.qiro.domain.accounting.entity.TransactionStatus
import com.qiro.domain.accounting.entity.TransactionType
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 거래 생성 요청 DTO
 */
data class CreateTransactionRequest(
    @field:NotNull(message = "거래 일자는 필수입니다")
    val transactionDate: LocalDate,

    @field:NotNull(message = "거래 유형은 필수입니다")
    val transactionType: TransactionType,

    @field:NotNull(message = "거래 카테고리는 필수입니다")
    val transactionCategory: TransactionCategory,

    @field:NotBlank(message = "거래 설명은 필수입니다")
    @field:Size(max = 1000, message = "거래 설명은 1000자를 초과할 수 없습니다")
    val description: String,

    @field:NotNull(message = "거래 금액은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "거래 금액은 0.01 이상이어야 합니다")
    @field:Digits(integer = 13, fraction = 2, message = "거래 금액은 최대 13자리 정수와 2자리 소수점을 가질 수 있습니다")
    val amount: BigDecimal,

    @field:Size(max = 255, message = "거래처명은 255자를 초과할 수 없습니다")
    val counterparty: String? = null,

    @field:Size(max = 50, message = "거래처 계좌는 50자를 초과할 수 없습니다")
    val counterpartyAccount: String? = null,

    val referenceType: String? = null,
    val referenceId: UUID? = null,

    val tags: List<String>? = null,

    @field:Size(max = 1000, message = "메모는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

/**
 * 거래 수정 요청 DTO
 */
data class UpdateTransactionRequest(
    @field:NotNull(message = "거래 일자는 필수입니다")
    val transactionDate: LocalDate,

    @field:NotNull(message = "거래 유형은 필수입니다")
    val transactionType: TransactionType,

    @field:NotNull(message = "거래 카테고리는 필수입니다")
    val transactionCategory: TransactionCategory,

    @field:NotBlank(message = "거래 설명은 필수입니다")
    @field:Size(max = 1000, message = "거래 설명은 1000자를 초과할 수 없습니다")
    val description: String,

    @field:NotNull(message = "거래 금액은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "거래 금액은 0.01 이상이어야 합니다")
    @field:Digits(integer = 13, fraction = 2, message = "거래 금액은 최대 13자리 정수와 2자리 소수점을 가질 수 있습니다")
    val amount: BigDecimal,

    @field:Size(max = 255, message = "거래처명은 255자를 초과할 수 없습니다")
    val counterparty: String? = null,

    @field:Size(max = 50, message = "거래처 계좌는 50자를 초과할 수 없습니다")
    val counterpartyAccount: String? = null,

    val referenceType: String? = null,
    val referenceId: UUID? = null,

    val tags: List<String>? = null,

    @field:Size(max = 1000, message = "메모는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

/**
 * 거래 승인 요청 DTO
 */
data class ApproveTransactionRequest(
    @field:NotNull(message = "계정과목 ID는 필수입니다")
    val accountId: UUID,

    @field:Size(max = 500, message = "승인 메모는 500자를 초과할 수 없습니다")
    val notes: String? = null
)

/**
 * 거래 거부 요청 DTO
 */
data class RejectTransactionRequest(
    @field:NotBlank(message = "거부 사유는 필수입니다")
    @field:Size(max = 1000, message = "거부 사유는 1000자를 초과할 수 없습니다")
    val reason: String
)

/**
 * 거래 응답 DTO
 */
data class TransactionResponse(
    val transactionId: UUID,
    val transactionNumber: String,
    val transactionDate: LocalDate,
    val transactionType: TransactionType,
    val transactionCategory: TransactionCategory,
    val description: String,
    val amount: BigDecimal,
    val counterparty: String?,
    val counterpartyAccount: String?,
    val suggestedAccount: AccountSummaryResponse?,
    val confidenceScore: BigDecimal?,
    val referenceType: String?,
    val referenceId: UUID?,
    val status: TransactionStatus,
    val approvedBy: UUID?,
    val approvedAt: LocalDateTime?,
    val rejectionReason: String?,
    val tags: List<String>,
    val notes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID
)

/**
 * 거래 목록 응답 DTO
 */
data class TransactionListResponse(
    val transactionId: UUID,
    val transactionNumber: String,
    val transactionDate: LocalDate,
    val transactionType: TransactionType,
    val transactionCategory: TransactionCategory,
    val description: String,
    val amount: BigDecimal,
    val counterparty: String?,
    val status: TransactionStatus,
    val suggestedAccount: AccountSummaryResponse?,
    val confidenceScore: BigDecimal?,
    val createdAt: LocalDateTime
)

/**
 * 거래 검색 요청 DTO
 */
data class TransactionSearchRequest(
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val transactionType: TransactionType? = null,
    val transactionCategory: TransactionCategory? = null,
    val status: TransactionStatus? = null,
    val counterparty: String? = null,
    val description: String? = null,
    val minAmount: BigDecimal? = null,
    val maxAmount: BigDecimal? = null,
    val accountId: UUID? = null,
    val tags: List<String>? = null,
    val referenceType: String? = null,
    val referenceId: UUID? = null
)

/**
 * 거래 통계 응답 DTO
 */
data class TransactionStatisticsResponse(
    val totalTransactions: Long,
    val totalAmount: BigDecimal,
    val incomeAmount: BigDecimal,
    val expenseAmount: BigDecimal,
    val pendingCount: Long,
    val approvedCount: Long,
    val rejectedCount: Long,
    val processedCount: Long,
    val monthlyStatistics: List<MonthlyTransactionStatistics>,
    val categoryStatistics: List<CategoryTransactionStatistics>,
    val counterpartyStatistics: List<CounterpartyTransactionStatistics>
)

/**
 * 월별 거래 통계 DTO
 */
data class MonthlyTransactionStatistics(
    val year: Int,
    val month: Int,
    val transactionType: TransactionType,
    val transactionCount: Long,
    val totalAmount: BigDecimal
)

/**
 * 카테고리별 거래 통계 DTO
 */
data class CategoryTransactionStatistics(
    val transactionCategory: TransactionCategory,
    val transactionCount: Long,
    val totalAmount: BigDecimal,
    val averageAmount: BigDecimal
)

/**
 * 거래처별 거래 통계 DTO
 */
data class CounterpartyTransactionStatistics(
    val counterparty: String,
    val transactionCount: Long,
    val totalAmount: BigDecimal
)

/**
 * 거래 분류 규칙 생성 요청 DTO
 */
data class CreateTransactionRuleRequest(
    @field:NotBlank(message = "규칙명은 필수입니다")
    @field:Size(max = 255, message = "규칙명은 255자를 초과할 수 없습니다")
    val ruleName: String,

    @field:Size(max = 1000, message = "규칙 설명은 1000자를 초과할 수 없습니다")
    val description: String? = null,

    val transactionType: TransactionType? = null,
    val transactionCategory: TransactionCategory? = null,

    @field:Size(max = 255, message = "거래처 패턴은 255자를 초과할 수 없습니다")
    val counterpartyPattern: String? = null,

    @field:Size(max = 255, message = "설명 패턴은 255자를 초과할 수 없습니다")
    val descriptionPattern: String? = null,

    @field:DecimalMin(value = "0.0", message = "최소 금액은 0 이상이어야 합니다")
    val amountMin: BigDecimal? = null,

    @field:DecimalMin(value = "0.0", message = "최대 금액은 0 이상이어야 합니다")
    val amountMax: BigDecimal? = null,

    @field:NotNull(message = "제안 계정과목 ID는 필수입니다")
    val suggestedAccountId: UUID,

    @field:NotNull(message = "신뢰도 점수는 필수입니다")
    @field:DecimalMin(value = "0.0", message = "신뢰도 점수는 0 이상이어야 합니다")
    @field:DecimalMax(value = "1.0", message = "신뢰도 점수는 1 이하여야 합니다")
    val confidenceScore: BigDecimal,

    @field:NotNull(message = "우선순위는 필수입니다")
    @field:Min(value = 1, message = "우선순위는 1 이상이어야 합니다")
    val priority: Int
) {
    init {
        if (amountMin != null && amountMax != null) {
            require(amountMin <= amountMax) { "최소 금액은 최대 금액보다 작거나 같아야 합니다" }
        }
    }
}

/**
 * 거래 분류 규칙 응답 DTO
 */
data class TransactionRuleResponse(
    val ruleId: UUID,
    val ruleName: String,
    val description: String?,
    val transactionType: TransactionType?,
    val transactionCategory: TransactionCategory?,
    val counterpartyPattern: String?,
    val descriptionPattern: String?,
    val amountMin: BigDecimal?,
    val amountMax: BigDecimal?,
    val suggestedAccount: AccountSummaryResponse,
    val confidenceScore: BigDecimal,
    val priority: Int,
    val isActive: Boolean,
    val usageCount: Long,
    val successCount: Long,
    val successRate: BigDecimal,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID
)

/**
 * 거래 분류 규칙 목록 응답 DTO
 */
data class TransactionRuleListResponse(
    val ruleId: UUID,
    val ruleName: String,
    val transactionType: TransactionType?,
    val transactionCategory: TransactionCategory?,
    val suggestedAccount: AccountSummaryResponse,
    val confidenceScore: BigDecimal,
    val priority: Int,
    val isActive: Boolean,
    val usageCount: Long,
    val successCount: Long,
    val successRate: BigDecimal
)