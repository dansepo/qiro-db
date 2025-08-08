package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 은행 API 연동 서비스 (건물관리 특화)
 * 은행 거래 내역 자동 가져오기, 계좌 잔액 조회, 자동 매칭 기능 제공
 */
@Service
@Transactional
class BankApiService(
    private val bankAccountRepository: BankAccountRepository,
    private val bankTransactionRepository: BankTransactionRepository,
    private val incomeRecordRepository: IncomeRecordRepository,
    private val expenseRecordRepository: ExpenseRecordRepository
) {

    /**
     * 은행 계좌 연동
     */
    fun connectBankAccount(
        companyId: UUID,
        request: BankAccountConnectionRequest
    ): BankAccountConnectionResponse {
        // 실제 구현에서는 오픈뱅킹 API 또는 스크래핑 서비스 연동
        val connectionId = UUID.randomUUID()
        
        // 은행 정보 조회 (임시 데이터)
        val bankInfo = getBankInfo(request.bankCode)
        
        // 계좌 정보 검증 및 연동 (실제로는 은행 API 호출)
        val accountInfo = validateAndConnectAccount(request)
        
        // 연동 정보 저장
        saveBankConnection(companyId, connectionId, request, accountInfo)
        
        return BankAccountConnectionResponse(
            connectionId = connectionId,
            bankCode = request.bankCode,
            bankName = bankInfo.bankName,
            accountNumber = maskAccountNumber(request.accountNumber),
            accountName = accountInfo.accountName,
            accountType = accountInfo.accountType,
            balance = accountInfo.balance,
            connectionStatus = "CONNECTED",
            lastSyncAt = null,
            nextSyncAt = LocalDateTime.now().plusHours(1)
        )
    }

    /**
     * 은행 거래 내역 동기화
     */
    fun syncBankTransactions(
        companyId: UUID,
        request: BankTransactionSyncRequest
    ): BankTransactionSyncResult {
        val startTime = LocalDateTime.now()
        
        try {
            // 은행 API에서 거래 내역 조회 (실제로는 외부 API 호출)
            val transactions = fetchBankTransactions(request)
            
            var newCount = 0
            var updatedCount = 0
            var matchedCount = 0
            
            transactions.forEach { transaction ->
                val existing = bankTransactionRepository.findByTransactionId(transaction.transactionId)
                
                if (existing == null) {
                    // 새로운 거래 내역 저장
                    saveBankTransaction(companyId, request.connectionId, transaction)
                    newCount++
                    
                    // 자동 매칭 시도
                    val matchingResult = attemptAutoMatching(companyId, transaction)
                    if (matchingResult.matchingStatus == "MATCHED") {
                        matchedCount++
                    }
                } else {
                    // 기존 거래 내역 업데이트
                    updateBankTransaction(existing, transaction)
                    updatedCount++
                }
            }
            
            val endTime = LocalDateTime.now()
            val unmatchedCount = newCount - matchedCount
            
            return BankTransactionSyncResult(
                connectionId = request.connectionId,
                syncStartTime = startTime,
                syncEndTime = endTime,
                totalTransactions = transactions.size,
                newTransactions = newCount,
                updatedTransactions = updatedCount,
                matchedTransactions = matchedCount,
                unmatchedTransactions = unmatchedCount,
                errors = emptyList(),
                status = "SUCCESS"
            )
            
        } catch (e: Exception) {
            return BankTransactionSyncResult(
                connectionId = request.connectionId,
                syncStartTime = startTime,
                syncEndTime = LocalDateTime.now(),
                totalTransactions = 0,
                newTransactions = 0,
                updatedTransactions = 0,
                matchedTransactions = 0,
                unmatchedTransactions = 0,
                errors = listOf(e.message ?: "알 수 없는 오류"),
                status = "FAILED"
            )
        }
    }

    /**
     * 계좌 잔액 조회
     */
    @Transactional(readOnly = true)
    fun getAccountBalance(
        companyId: UUID,
        connectionId: UUID
    ): AccountBalanceResponse {
        // 실제 구현에서는 은행 API 호출
        val connection = getBankConnection(companyId, connectionId)
        val balance = fetchAccountBalance(connection)
        
        return AccountBalanceResponse(
            connectionId = connectionId,
            accountNumber = maskAccountNumber(connection.accountNumber),
            currentBalance = balance.currentBalance,
            availableBalance = balance.availableBalance,
            lastUpdated = LocalDateTime.now(),
            currency = "KRW"
        )
    }

    /**
     * 거래 내역 자동 매칭
     */
    fun matchTransaction(
        companyId: UUID,
        request: TransactionMatchingRequest
    ): TransactionMatchingResult {
        val bankTransaction = bankTransactionRepository.findByTransactionId(request.bankTransactionId)
            ?: throw IllegalArgumentException("은행 거래 내역을 찾을 수 없습니다: ${request.bankTransactionId}")

        return when (request.matchingType) {
            "AUTO" -> attemptAutoMatching(companyId, bankTransaction)
            "MANUAL" -> performManualMatching(companyId, bankTransaction, request.targetRecordId!!)
            else -> throw IllegalArgumentException("지원하지 않는 매칭 유형입니다: ${request.matchingType}")
        }
    }

    /**
     * 거래 내역 분류
     */
    fun categorizeTransaction(
        request: TransactionCategorizationRequest
    ): TransactionCategorizationResponse {
        // 거래 내역 분석 및 카테고리 추천
        val category = analyzeTransactionCategory(
            request.description,
            request.amount,
            request.counterpartyName,
            request.transactionType
        )
        
        return TransactionCategorizationResponse(
            transactionId = request.transactionId,
            suggestedCategory = category.category,
            confidence = category.confidence,
            suggestedAccountCode = category.accountCode,
            suggestedRecordType = category.recordType,
            categorizationReason = category.reason,
            alternativeCategories = category.alternatives
        )
    }

    /**
     * 은행 연동 설정 조회
     */
    @Transactional(readOnly = true)
    fun getBankConnectionSettings(
        companyId: UUID,
        connectionId: UUID
    ): BankConnectionSettingsResponse {
        val connection = getBankConnection(companyId, connectionId)
        val matchingRules = getMatchingRules(companyId, connectionId)
        
        return BankConnectionSettingsResponse(
            connectionId = connectionId,
            bankCode = connection.bankCode,
            bankName = connection.bankName,
            accountNumber = maskAccountNumber(connection.accountNumber),
            accountName = connection.accountName,
            syncFrequency = connection.syncFrequency,
            autoMatching = connection.autoMatching,
            matchingRules = matchingRules,
            isActive = connection.isActive,
            lastSyncAt = connection.lastSyncAt,
            nextSyncAt = connection.nextSyncAt
        )
    }

    /**
     * 은행 연동 통계 조회
     */
    @Transactional(readOnly = true)
    fun getBankConnectionStatistics(companyId: UUID): BankConnectionStatisticsResponse {
        val connections = bankAccountRepository.findByCompanyId(companyId)
        val totalTransactions = bankTransactionRepository.countByCompanyId(companyId)
        val matchedTransactions = bankTransactionRepository.countByCompanyIdAndIsMatchedTrue(companyId)
        
        val matchingRate = if (totalTransactions > 0) {
            BigDecimal(matchedTransactions).divide(BigDecimal(totalTransactions), 4, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
        
        return BankConnectionStatisticsResponse(
            totalConnections = connections.size,
            activeConnections = connections.count { it.isActive },
            totalTransactions = totalTransactions,
            matchedTransactions = matchedTransactions,
            unmatchedTransactions = totalTransactions - matchedTransactions,
            matchingRate = matchingRate,
            lastSyncStatus = connections.associate { it.id to (it.lastSyncStatus ?: "NEVER_SYNCED") },
            syncErrors = getSyncErrors(companyId)
        )
    }

    /**
     * 지원 은행 목록 조회
     */
    @Transactional(readOnly = true)
    fun getSupportedBanks(): List<SupportedBankResponse> {
        return listOf(
            SupportedBankResponse(
                bankCode = "004",
                bankName = "KB국민은행",
                logoUrl = "/images/banks/kb.png",
                supportedServices = listOf("BALANCE_INQUIRY", "TRANSACTION_HISTORY"),
                connectionMethods = listOf("OPEN_BANKING", "SCRAPING"),
                isActive = true
            ),
            SupportedBankResponse(
                bankCode = "011",
                bankName = "NH농협은행",
                logoUrl = "/images/banks/nh.png",
                supportedServices = listOf("BALANCE_INQUIRY", "TRANSACTION_HISTORY"),
                connectionMethods = listOf("OPEN_BANKING"),
                isActive = true
            ),
            SupportedBankResponse(
                bankCode = "020",
                bankName = "우리은행",
                logoUrl = "/images/banks/woori.png",
                supportedServices = listOf("BALANCE_INQUIRY", "TRANSACTION_HISTORY"),
                connectionMethods = listOf("OPEN_BANKING", "SCRAPING"),
                isActive = true
            ),
            SupportedBankResponse(
                bankCode = "081",
                bankName = "하나은행",
                logoUrl = "/images/banks/hana.png",
                supportedServices = listOf("BALANCE_INQUIRY", "TRANSACTION_HISTORY"),
                connectionMethods = listOf("OPEN_BANKING"),
                isActive = true
            ),
            SupportedBankResponse(
                bankCode = "088",
                bankName = "신한은행",
                logoUrl = "/images/banks/shinhan.png",
                supportedServices = listOf("BALANCE_INQUIRY", "TRANSACTION_HISTORY"),
                connectionMethods = listOf("OPEN_BANKING", "SCRAPING"),
                isActive = true
            )
        )
    }

    /**
     * 은행 API 상태 조회
     */
    @Transactional(readOnly = true)
    fun getBankApiStatus(): List<BankApiStatusResponse> {
        return listOf(
            BankApiStatusResponse(
                apiProvider = "OPEN_BANKING",
                status = "ACTIVE",
                lastHealthCheck = LocalDateTime.now().minusMinutes(5),
                responseTime = 250L,
                errorRate = BigDecimal("0.02"),
                dailyQuota = 10000,
                usedQuota = 1250,
                remainingQuota = 8750
            ),
            BankApiStatusResponse(
                apiProvider = "CODEF",
                status = "ACTIVE",
                lastHealthCheck = LocalDateTime.now().minusMinutes(3),
                responseTime = 180L,
                errorRate = BigDecimal("0.01"),
                dailyQuota = 5000,
                usedQuota = 320,
                remainingQuota = 4680
            )
        )
    }

    // Private helper methods
    private fun getBankInfo(bankCode: String): BankInfo {
        val bankMap = mapOf(
            "004" to BankInfo("KB국민은행", "KB"),
            "011" to BankInfo("NH농협은행", "NH"),
            "020" to BankInfo("우리은행", "WOORI"),
            "081" to BankInfo("하나은행", "HANA"),
            "088" to BankInfo("신한은행", "SHINHAN")
        )
        return bankMap[bankCode] ?: throw IllegalArgumentException("지원하지 않는 은행 코드입니다: $bankCode")
    }

    private fun validateAndConnectAccount(request: BankAccountConnectionRequest): AccountInfo {
        // 실제 구현에서는 은행 API 호출하여 계좌 정보 검증
        return AccountInfo(
            accountName = "건물관리 회사 주거래 계좌",
            accountType = "CHECKING",
            balance = BigDecimal("50000000")
        )
    }

    private fun saveBankConnection(
        companyId: UUID,
        connectionId: UUID,
        request: BankAccountConnectionRequest,
        accountInfo: AccountInfo
    ) {
        // 실제 구현에서는 BankAccount 엔티티에 저장
        // 여기서는 로직만 구현
    }

    private fun fetchBankTransactions(request: BankTransactionSyncRequest): List<BankTransactionResponse> {
        // 실제 구현에서는 은행 API 호출
        // 임시 데이터 반환
        return listOf(
            BankTransactionResponse(
                transactionId = "TXN_${UUID.randomUUID()}",
                accountNumber = "123-456-789",
                transactionDate = LocalDate.now(),
                transactionTime = LocalDateTime.now(),
                transactionType = "DEPOSIT",
                amount = BigDecimal("150000"),
                balance = BigDecimal("50150000"),
                description = "101호 관리비",
                counterpartyName = "김철수",
                counterpartyAccount = "987-654-321",
                memo = "2025년 1월 관리비",
                category = "관리비 수입"
            )
        )
    }

    private fun saveBankTransaction(
        companyId: UUID,
        connectionId: UUID,
        transaction: BankTransactionResponse
    ) {
        // 실제 구현에서는 BankTransaction 엔티티에 저장
    }

    private fun updateBankTransaction(existing: Any, transaction: BankTransactionResponse) {
        // 기존 거래 내역 업데이트
    }

    private fun attemptAutoMatching(
        companyId: UUID,
        transaction: BankTransactionResponse
    ): TransactionMatchingResult {
        // 자동 매칭 로직 구현
        val suggestions = findMatchingSuggestions(companyId, transaction)
        
        val bestMatch = suggestions.maxByOrNull { it.confidence }
        
        return if (bestMatch != null && bestMatch.confidence >= BigDecimal("0.8")) {
            TransactionMatchingResult(
                bankTransactionId = transaction.transactionId,
                matchingStatus = "MATCHED",
                matchedRecordId = bestMatch.recordId,
                matchedRecordType = bestMatch.recordType,
                confidence = bestMatch.confidence,
                matchingReason = "자동 매칭: ${bestMatch.matchingFactors.joinToString(", ")}",
                suggestedMatches = suggestions
            )
        } else {
            TransactionMatchingResult(
                bankTransactionId = transaction.transactionId,
                matchingStatus = "UNMATCHED",
                matchedRecordId = null,
                matchedRecordType = null,
                confidence = bestMatch?.confidence ?: BigDecimal.ZERO,
                matchingReason = "매칭 신뢰도 부족",
                suggestedMatches = suggestions
            )
        }
    }

    private fun performManualMatching(
        companyId: UUID,
        transaction: BankTransactionResponse,
        targetRecordId: UUID
    ): TransactionMatchingResult {
        // 수동 매칭 처리
        return TransactionMatchingResult(
            bankTransactionId = transaction.transactionId,
            matchingStatus = "MATCHED",
            matchedRecordId = targetRecordId,
            matchedRecordType = "INCOME", // 실제로는 레코드 조회해서 확인
            confidence = BigDecimal.ONE,
            matchingReason = "수동 매칭",
            suggestedMatches = emptyList()
        )
    }

    private fun findMatchingSuggestions(
        companyId: UUID,
        transaction: BankTransactionResponse
    ): List<MatchingSuggestion> {
        val suggestions = mutableListOf<MatchingSuggestion>()
        
        // 금액과 날짜 기준으로 수입 기록 검색
        if (transaction.transactionType == "DEPOSIT") {
            val incomeRecords = incomeRecordRepository.findByCompanyIdAndAmountAndDateRange(
                companyId, transaction.amount, 
                transaction.transactionDate.minusDays(3), 
                transaction.transactionDate.plusDays(3)
            )
            
            incomeRecords.forEach { record ->
                val confidence = calculateMatchingConfidence(transaction, record)
                if (confidence > BigDecimal("0.3")) {
                    suggestions.add(
                        MatchingSuggestion(
                            recordId = record.id,
                            recordType = "INCOME",
                            description = record.description ?: "",
                            amount = record.amount,
                            date = record.dueDate ?: record.createdAt.toLocalDate(),
                            confidence = confidence,
                            matchingFactors = listOf("금액 일치", "날짜 근접")
                        )
                    )
                }
            }
        }
        
        return suggestions.sortedByDescending { it.confidence }
    }

    private fun calculateMatchingConfidence(
        transaction: BankTransactionResponse,
        record: Any
    ): BigDecimal {
        // 매칭 신뢰도 계산 로직
        var confidence = BigDecimal.ZERO
        
        // 금액 일치 시 +0.5
        // 날짜 근접 시 +0.3
        // 설명 유사도에 따라 +0.2
        
        return confidence.coerceAtMost(BigDecimal.ONE)
    }

    private fun analyzeTransactionCategory(
        description: String,
        amount: BigDecimal,
        counterpartyName: String?,
        transactionType: String
    ): CategoryAnalysisResult {
        // 거래 내역 분석 및 카테고리 추천 로직
        return when {
            description.contains("관리비") -> CategoryAnalysisResult(
                category = "관리비 수입",
                accountCode = "4100",
                recordType = "INCOME",
                confidence = BigDecimal("0.9"),
                reason = "거래 설명에 '관리비' 포함",
                alternatives = listOf(
                    CategorySuggestion("임대료 수입", "4200", BigDecimal("0.3"), "금액 유사")
                )
            )
            description.contains("전기료") || description.contains("가스료") -> CategoryAnalysisResult(
                category = "공과금",
                accountCode = "5200",
                recordType = "EXPENSE",
                confidence = BigDecimal("0.85"),
                reason = "공과금 관련 키워드 포함",
                alternatives = emptyList()
            )
            else -> CategoryAnalysisResult(
                category = "기타",
                accountCode = "9999",
                recordType = if (transactionType == "DEPOSIT") "INCOME" else "EXPENSE",
                confidence = BigDecimal("0.5"),
                reason = "자동 분류 불가",
                alternatives = emptyList()
            )
        }
    }

    private fun getBankConnection(companyId: UUID, connectionId: UUID): BankConnectionInfo {
        // 실제 구현에서는 데이터베이스에서 조회
        return BankConnectionInfo(
            bankCode = "004",
            bankName = "KB국민은행",
            accountNumber = "123-456-789",
            accountName = "건물관리 회사",
            syncFrequency = "DAILY",
            autoMatching = true,
            isActive = true,
            lastSyncAt = LocalDateTime.now().minusHours(2),
            nextSyncAt = LocalDateTime.now().plusHours(22)
        )
    }

    private fun getMatchingRules(companyId: UUID, connectionId: UUID): List<MatchingRuleResponse> {
        return listOf(
            MatchingRuleResponse(
                ruleId = UUID.randomUUID(),
                ruleName = "관리비 자동 매칭",
                pattern = ".*관리비.*",
                targetAccountCode = "4100",
                targetRecordType = "INCOME",
                priority = 1,
                isActive = true
            )
        )
    }

    private fun fetchAccountBalance(connection: BankConnectionInfo): BalanceInfo {
        // 실제 구현에서는 은행 API 호출
        return BalanceInfo(
            currentBalance = BigDecimal("50000000"),
            availableBalance = BigDecimal("49500000")
        )
    }

    private fun getSyncErrors(companyId: UUID): List<SyncErrorInfo> {
        return emptyList() // 실제 구현에서는 오류 로그 조회
    }

    private fun maskAccountNumber(accountNumber: String): String {
        return if (accountNumber.length > 6) {
            accountNumber.take(3) + "***" + accountNumber.takeLast(3)
        } else {
            accountNumber
        }
    }
}

// Helper data classes
data class BankInfo(val bankName: String, val shortName: String)
data class AccountInfo(val accountName: String, val accountType: String, val balance: BigDecimal)
data class BalanceInfo(val currentBalance: BigDecimal, val availableBalance: BigDecimal)
data class BankConnectionInfo(
    val bankCode: String,
    val bankName: String,
    val accountNumber: String,
    val accountName: String,
    val syncFrequency: String,
    val autoMatching: Boolean,
    val isActive: Boolean,
    val lastSyncAt: LocalDateTime?,
    val nextSyncAt: LocalDateTime?
)

data class CategoryAnalysisResult(
    val category: String,
    val accountCode: String,
    val recordType: String,
    val confidence: BigDecimal,
    val reason: String,
    val alternatives: List<CategorySuggestion>
)