package com.qiro.domain.accounting.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 은행 API 연동 DTO 클래스들
 * 은행 거래 내역 자동 가져오기 및 계좌 잔액 조회 관련 데이터
 */

// 은행 계좌 연동 요청
data class BankAccountConnectionRequest(
    val bankCode: String, // 은행 코드 (예: "004" - KB국민은행)
    val accountNumber: String,
    val accountPassword: String? = null,
    val apiKey: String? = null,
    val connectionType: String = "OPEN_BANKING" // OPEN_BANKING, SCRAPING, DIRECT_API
)

// 은행 계좌 연동 응답
data class BankAccountConnectionResponse(
    val connectionId: UUID,
    val bankCode: String,
    val bankName: String,
    val accountNumber: String,
    val accountName: String,
    val accountType: String, // CHECKING, SAVINGS, LOAN
    val balance: BigDecimal,
    val connectionStatus: String, // CONNECTED, DISCONNECTED, ERROR
    val lastSyncAt: LocalDateTime?,
    val nextSyncAt: LocalDateTime?
)

// 은행 거래 내역 조회 요청
data class BankTransactionSyncRequest(
    val connectionId: UUID,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val syncType: String = "INCREMENTAL" // FULL, INCREMENTAL
)

// 은행 거래 내역 응답
data class BankTransactionResponse(
    val transactionId: String, // 은행 거래 고유 ID
    val accountNumber: String,
    val transactionDate: LocalDate,
    val transactionTime: LocalDateTime,
    val transactionType: String, // DEPOSIT, WITHDRAWAL, TRANSFER
    val amount: BigDecimal,
    val balance: BigDecimal, // 거래 후 잔액
    val description: String,
    val counterpartyName: String?, // 거래 상대방
    val counterpartyAccount: String?,
    val memo: String?,
    val category: String?, // 자동 분류된 카테고리
    val isMatched: Boolean = false, // 회계 기록과 매칭 여부
    val matchedRecordId: UUID? = null
)

// 은행 거래 내역 동기화 결과
data class BankTransactionSyncResult(
    val connectionId: UUID,
    val syncStartTime: LocalDateTime,
    val syncEndTime: LocalDateTime,
    val totalTransactions: Int,
    val newTransactions: Int,
    val updatedTransactions: Int,
    val matchedTransactions: Int,
    val unmatchedTransactions: Int,
    val errors: List<String>,
    val status: String // SUCCESS, PARTIAL_SUCCESS, FAILED
)

// 계좌 잔액 조회 응답
data class AccountBalanceResponse(
    val connectionId: UUID,
    val accountNumber: String,
    val currentBalance: BigDecimal,
    val availableBalance: BigDecimal,
    val lastUpdated: LocalDateTime,
    val currency: String = "KRW"
)

// 거래 내역 자동 매칭 요청
data class TransactionMatchingRequest(
    val bankTransactionId: String,
    val matchingType: String, // AUTO, MANUAL
    val targetRecordType: String, // INCOME, EXPENSE
    val targetRecordId: UUID? = null,
    val confidence: BigDecimal? = null // 매칭 신뢰도 (0.0 ~ 1.0)
)

// 거래 내역 자동 매칭 결과
data class TransactionMatchingResult(
    val bankTransactionId: String,
    val matchingStatus: String, // MATCHED, UNMATCHED, PARTIAL_MATCH
    val matchedRecordId: UUID?,
    val matchedRecordType: String?,
    val confidence: BigDecimal,
    val matchingReason: String,
    val suggestedMatches: List<MatchingSuggestion>
)

data class MatchingSuggestion(
    val recordId: UUID,
    val recordType: String,
    val description: String,
    val amount: BigDecimal,
    val date: LocalDate,
    val confidence: BigDecimal,
    val matchingFactors: List<String>
)

// 은행 연동 설정 응답
data class BankConnectionSettingsResponse(
    val connectionId: UUID,
    val bankCode: String,
    val bankName: String,
    val accountNumber: String,
    val accountName: String,
    val syncFrequency: String, // REAL_TIME, HOURLY, DAILY, WEEKLY
    val autoMatching: Boolean,
    val matchingRules: List<MatchingRuleResponse>,
    val isActive: Boolean,
    val lastSyncAt: LocalDateTime?,
    val nextSyncAt: LocalDateTime?
)

data class MatchingRuleResponse(
    val ruleId: UUID,
    val ruleName: String,
    val pattern: String, // 매칭 패턴 (정규식 또는 키워드)
    val targetAccountCode: String,
    val targetRecordType: String,
    val priority: Int,
    val isActive: Boolean
)

// 은행 연동 통계 응답
data class BankConnectionStatisticsResponse(
    val totalConnections: Int,
    val activeConnections: Int,
    val totalTransactions: Int,
    val matchedTransactions: Int,
    val unmatchedTransactions: Int,
    val matchingRate: BigDecimal,
    val lastSyncStatus: Map<UUID, String>,
    val syncErrors: List<SyncErrorInfo>
)

data class SyncErrorInfo(
    val connectionId: UUID,
    val bankName: String,
    val accountNumber: String,
    val errorMessage: String,
    val errorTime: LocalDateTime,
    val errorType: String // CONNECTION_ERROR, AUTH_ERROR, DATA_ERROR
)

// 은행 목록 응답
data class SupportedBankResponse(
    val bankCode: String,
    val bankName: String,
    val logoUrl: String?,
    val supportedServices: List<String>, // BALANCE_INQUIRY, TRANSACTION_HISTORY, TRANSFER
    val connectionMethods: List<String>, // OPEN_BANKING, SCRAPING, DIRECT_API
    val isActive: Boolean
)

// 거래 내역 분류 요청
data class TransactionCategorizationRequest(
    val transactionId: String,
    val description: String,
    val amount: BigDecimal,
    val counterpartyName: String?,
    val transactionType: String
)

// 거래 내역 분류 응답
data class TransactionCategorizationResponse(
    val transactionId: String,
    val suggestedCategory: String,
    val confidence: BigDecimal,
    val suggestedAccountCode: String?,
    val suggestedRecordType: String, // INCOME, EXPENSE
    val categorizationReason: String,
    val alternativeCategories: List<CategorySuggestion>
)

data class CategorySuggestion(
    val category: String,
    val accountCode: String,
    val confidence: BigDecimal,
    val reason: String
)

// 은행 API 연동 상태 응답
data class BankApiStatusResponse(
    val apiProvider: String, // OPEN_BANKING, BANK_SALAD, CODEF
    val status: String, // ACTIVE, INACTIVE, ERROR
    val lastHealthCheck: LocalDateTime,
    val responseTime: Long, // milliseconds
    val errorRate: BigDecimal, // 0.0 ~ 1.0
    val dailyQuota: Int,
    val usedQuota: Int,
    val remainingQuota: Int
)