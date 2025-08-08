package com.qiro.domain.accounting.dto

import com.qiro.domain.accounting.entity.JournalEntryStatus
import com.qiro.domain.accounting.entity.JournalEntryType
import jakarta.validation.Valid
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 분개 전표 생성 요청 DTO
 */
data class CreateJournalEntryRequest(
    @field:NotNull(message = "분개 일자는 필수입니다")
    val entryDate: LocalDate,

    @field:NotBlank(message = "분개 설명은 필수입니다")
    @field:Size(max = 1000, message = "분개 설명은 1000자를 초과할 수 없습니다")
    val description: String,

    @field:NotNull(message = "분개 유형은 필수입니다")
    val entryType: JournalEntryType = JournalEntryType.MANUAL,

    val referenceType: String? = null,
    val referenceId: UUID? = null,

    @field:Valid
    @field:NotEmpty(message = "분개선은 최소 2개 이상이어야 합니다")
    @field:Size(min = 2, message = "분개선은 최소 2개 이상이어야 합니다")
    val journalEntryLines: List<CreateJournalEntryLineRequest>
) {
    init {
        // 복식부기 원칙 검증
        val totalDebit = journalEntryLines.sumOf { it.debitAmount }
        val totalCredit = journalEntryLines.sumOf { it.creditAmount }
        require(totalDebit.compareTo(totalCredit) == 0) {
            "차변과 대변의 합계가 일치해야 합니다. 차변: $totalDebit, 대변: $totalCredit"
        }
    }
}

/**
 * 분개선 생성 요청 DTO
 */
data class CreateJournalEntryLineRequest(
    @field:NotNull(message = "계정 ID는 필수입니다")
    val accountId: UUID,

    @field:NotNull(message = "차변 금액은 필수입니다")
    @field:DecimalMin(value = "0.0", message = "차변 금액은 0 이상이어야 합니다")
    @field:Digits(integer = 13, fraction = 2, message = "차변 금액은 최대 13자리 정수와 2자리 소수점을 가질 수 있습니다")
    val debitAmount: BigDecimal = BigDecimal.ZERO,

    @field:NotNull(message = "대변 금액은 필수입니다")
    @field:DecimalMin(value = "0.0", message = "대변 금액은 0 이상이어야 합니다")
    @field:Digits(integer = 13, fraction = 2, message = "대변 금액은 최대 13자리 정수와 2자리 소수점을 가질 수 있습니다")
    val creditAmount: BigDecimal = BigDecimal.ZERO,

    @field:Size(max = 500, message = "분개선 설명은 500자를 초과할 수 없습니다")
    val description: String? = null,

    val referenceType: String? = null,
    val referenceId: UUID? = null,

    @field:NotNull(message = "분개선 순서는 필수입니다")
    @field:Min(value = 1, message = "분개선 순서는 1 이상이어야 합니다")
    val lineOrder: Int
) {
    init {
        // 차변 또는 대변 중 하나만 값을 가져야 함
        require((debitAmount > BigDecimal.ZERO && creditAmount == BigDecimal.ZERO) ||
                (debitAmount == BigDecimal.ZERO && creditAmount > BigDecimal.ZERO)) {
            "차변 또는 대변 중 하나만 값을 가져야 합니다"
        }
    }
}

/**
 * 분개 전표 수정 요청 DTO
 */
data class UpdateJournalEntryRequest(
    @field:NotNull(message = "분개 일자는 필수입니다")
    val entryDate: LocalDate,

    @field:NotBlank(message = "분개 설명은 필수입니다")
    @field:Size(max = 1000, message = "분개 설명은 1000자를 초과할 수 없습니다")
    val description: String,

    val referenceType: String? = null,
    val referenceId: UUID? = null,

    @field:Valid
    @field:NotEmpty(message = "분개선은 최소 2개 이상이어야 합니다")
    @field:Size(min = 2, message = "분개선은 최소 2개 이상이어야 합니다")
    val journalEntryLines: List<CreateJournalEntryLineRequest>
) {
    init {
        // 복식부기 원칙 검증
        val totalDebit = journalEntryLines.sumOf { it.debitAmount }
        val totalCredit = journalEntryLines.sumOf { it.creditAmount }
        require(totalDebit.compareTo(totalCredit) == 0) {
            "차변과 대변의 합계가 일치해야 합니다. 차변: $totalDebit, 대변: $totalCredit"
        }
    }
}

/**
 * 분개 전표 응답 DTO
 */
data class JournalEntryResponse(
    val entryId: UUID,
    val entryNumber: String,
    val entryDate: LocalDate,
    val entryType: JournalEntryType,
    val referenceType: String?,
    val referenceId: UUID?,
    val description: String,
    val totalAmount: BigDecimal,
    val status: JournalEntryStatus,
    val approvedBy: UUID?,
    val approvedAt: LocalDateTime?,
    val postedAt: LocalDateTime?,
    val reversedAt: LocalDateTime?,
    val reversalReason: String?,
    val journalEntryLines: List<JournalEntryLineResponse>,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID
)

/**
 * 분개선 응답 DTO
 */
data class JournalEntryLineResponse(
    val lineId: UUID,
    val account: AccountSummaryResponse,
    val debitAmount: BigDecimal,
    val creditAmount: BigDecimal,
    val description: String?,
    val referenceType: String?,
    val referenceId: UUID?,
    val lineOrder: Int,
    val createdAt: LocalDateTime
)

/**
 * 계정 요약 응답 DTO
 */
data class AccountSummaryResponse(
    val accountId: UUID,
    val accountCode: String,
    val accountName: String,
    val accountType: String
)

/**
 * 분개 전표 목록 응답 DTO
 */
data class JournalEntryListResponse(
    val entryId: UUID,
    val entryNumber: String,
    val entryDate: LocalDate,
    val entryType: JournalEntryType,
    val description: String,
    val totalAmount: BigDecimal,
    val status: JournalEntryStatus,
    val createdAt: LocalDateTime,
    val createdBy: UUID
)

/**
 * 분개 전표 승인 요청 DTO
 */
data class ApproveJournalEntryRequest(
    @field:Size(max = 500, message = "승인 의견은 500자를 초과할 수 없습니다")
    val approvalComment: String? = null
)

/**
 * 역분개 요청 DTO
 */
data class ReverseJournalEntryRequest(
    @field:NotBlank(message = "역분개 사유는 필수입니다")
    @field:Size(max = 1000, message = "역분개 사유는 1000자를 초과할 수 없습니다")
    val reversalReason: String
)

/**
 * 분개 전표 검색 요청 DTO
 */
data class JournalEntrySearchRequest(
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val status: JournalEntryStatus? = null,
    val entryType: JournalEntryType? = null,
    val accountId: UUID? = null,
    val description: String? = null,
    val entryNumber: String? = null,
    val referenceType: String? = null,
    val referenceId: UUID? = null
)

/**
 * 시산표 응답 DTO
 */
data class TrialBalanceResponse(
    val accountId: UUID,
    val accountCode: String,
    val accountName: String,
    val accountType: String,
    val totalDebit: BigDecimal,
    val totalCredit: BigDecimal,
    val balance: BigDecimal
)

/**
 * 계정원장 응답 DTO
 */
data class GeneralLedgerResponse(
    val entryDate: LocalDate,
    val entryNumber: String,
    val entryDescription: String,
    val lineDescription: String?,
    val debitAmount: BigDecimal,
    val creditAmount: BigDecimal,
    val runningBalance: BigDecimal
)