package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.BankApiService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 은행 API 연동 REST API Controller
 * 은행 거래 내역 자동 가져오기, 계좌 잔액 조회, 자동 매칭 기능
 */
@RestController
@RequestMapping("/api/bank-api")
@CrossOrigin(origins = ["*"])
class BankApiController(
    private val bankApiService: BankApiService
) {

    /**
     * 은행 계좌 연동
     */
    @PostMapping("/connect")
    fun connectBankAccount(
        @RequestParam companyId: UUID,
        @RequestBody request: BankAccountConnectionRequest
    ): ResponseEntity<BankAccountConnectionResponse> {
        val connection = bankApiService.connectBankAccount(companyId, request)
        return ResponseEntity.ok(connection)
    }

    /**
     * 은행 거래 내역 동기화
     */
    @PostMapping("/sync-transactions")
    fun syncBankTransactions(
        @RequestParam companyId: UUID,
        @RequestBody request: BankTransactionSyncRequest
    ): ResponseEntity<BankTransactionSyncResult> {
        val result = bankApiService.syncBankTransactions(companyId, request)
        return ResponseEntity.ok(result)
    }

    /**
     * 계좌 잔액 조회
     */
    @GetMapping("/balance/{connectionId}")
    fun getAccountBalance(
        @RequestParam companyId: UUID,
        @PathVariable connectionId: UUID
    ): ResponseEntity<AccountBalanceResponse> {
        val balance = bankApiService.getAccountBalance(companyId, connectionId)
        return ResponseEntity.ok(balance)
    }

    /**
     * 거래 내역 자동 매칭
     */
    @PostMapping("/match-transaction")
    fun matchTransaction(
        @RequestParam companyId: UUID,
        @RequestBody request: TransactionMatchingRequest
    ): ResponseEntity<TransactionMatchingResult> {
        val result = bankApiService.matchTransaction(companyId, request)
        return ResponseEntity.ok(result)
    }

    /**
     * 거래 내역 분류
     */
    @PostMapping("/categorize-transaction")
    fun categorizeTransaction(
        @RequestBody request: TransactionCategorizationRequest
    ): ResponseEntity<TransactionCategorizationResponse> {
        val result = bankApiService.categorizeTransaction(request)
        return ResponseEntity.ok(result)
    }

    /**
     * 은행 연동 설정 조회
     */
    @GetMapping("/settings/{connectionId}")
    fun getBankConnectionSettings(
        @RequestParam companyId: UUID,
        @PathVariable connectionId: UUID
    ): ResponseEntity<BankConnectionSettingsResponse> {
        val settings = bankApiService.getBankConnectionSettings(companyId, connectionId)
        return ResponseEntity.ok(settings)
    }

    /**
     * 은행 연동 통계 조회
     */
    @GetMapping("/statistics")
    fun getBankConnectionStatistics(
        @RequestParam companyId: UUID
    ): ResponseEntity<BankConnectionStatisticsResponse> {
        val statistics = bankApiService.getBankConnectionStatistics(companyId)
        return ResponseEntity.ok(statistics)
    }

    /**
     * 지원 은행 목록 조회
     */
    @GetMapping("/supported-banks")
    fun getSupportedBanks(): ResponseEntity<List<SupportedBankResponse>> {
        val banks = bankApiService.getSupportedBanks()
        return ResponseEntity.ok(banks)
    }

    /**
     * 은행 API 상태 조회
     */
    @GetMapping("/api-status")
    fun getBankApiStatus(): ResponseEntity<List<BankApiStatusResponse>> {
        val status = bankApiService.getBankApiStatus()
        return ResponseEntity.ok(status)
    }

    /**
     * 연동된 계좌 목록 조회
     */
    @GetMapping("/connections")
    fun getBankConnections(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<BankAccountConnectionResponse>> {
        // 임시 구현 - 실제로는 Service에서 처리
        val connections = listOf(
            BankAccountConnectionResponse(
                connectionId = UUID.randomUUID(),
                bankCode = "004",
                bankName = "KB국민은행",
                accountNumber = "123***789",
                accountName = "건물관리 회사 주거래",
                accountType = "CHECKING",
                balance = java.math.BigDecimal("50000000"),
                connectionStatus = "CONNECTED",
                lastSyncAt = java.time.LocalDateTime.now().minusHours(2),
                nextSyncAt = java.time.LocalDateTime.now().plusHours(22)
            )
        )
        
        return ResponseEntity.ok(connections)
    }

    /**
     * 은행 거래 내역 조회
     */
    @GetMapping("/transactions")
    fun getBankTransactions(
        @RequestParam companyId: UUID,
        @RequestParam connectionId: UUID,
        @RequestParam(required = false) startDate: LocalDate?,
        @RequestParam(required = false) endDate: LocalDate?,
        @RequestParam(required = false) isMatched: Boolean?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<List<BankTransactionResponse>> {
        // 임시 구현 - 실제로는 Service에서 처리
        val transactions = listOf(
            BankTransactionResponse(
                transactionId = "TXN_001",
                accountNumber = "123***789",
                transactionDate = LocalDate.now(),
                transactionTime = java.time.LocalDateTime.now(),
                transactionType = "DEPOSIT",
                amount = java.math.BigDecimal("150000"),
                balance = java.math.BigDecimal("50150000"),
                description = "101호 관리비",
                counterpartyName = "김철수",
                counterpartyAccount = "987***321",
                memo = "2025년 1월 관리비",
                category = "관리비 수입",
                isMatched = true,
                matchedRecordId = UUID.randomUUID()
            ),
            BankTransactionResponse(
                transactionId = "TXN_002",
                accountNumber = "123***789",
                transactionDate = LocalDate.now().minusDays(1),
                transactionTime = java.time.LocalDateTime.now().minusDays(1),
                transactionType = "WITHDRAWAL",
                amount = java.math.BigDecimal("500000"),
                balance = java.math.BigDecimal("49650000"),
                description = "엘리베이터 수리비",
                counterpartyName = "ABC유지보수",
                counterpartyAccount = "555***888",
                memo = "1호기 엘리베이터 정기점검",
                category = "유지보수비",
                isMatched = false,
                matchedRecordId = null
            )
        )
        
        return ResponseEntity.ok(transactions)
    }

    /**
     * 매칭되지 않은 거래 내역 조회
     */
    @GetMapping("/unmatched-transactions")
    fun getUnmatchedTransactions(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) connectionId: UUID?
    ): ResponseEntity<List<BankTransactionResponse>> {
        // 임시 구현
        val unmatchedTransactions = listOf(
            BankTransactionResponse(
                transactionId = "TXN_003",
                accountNumber = "123***789",
                transactionDate = LocalDate.now().minusDays(2),
                transactionTime = java.time.LocalDateTime.now().minusDays(2),
                transactionType = "DEPOSIT",
                amount = java.math.BigDecimal("80000"),
                balance = java.math.BigDecimal("49730000"),
                description = "주차비",
                counterpartyName = "이영희",
                counterpartyAccount = "111***222",
                memo = "지하주차장 월 주차비",
                category = "주차비 수입",
                isMatched = false,
                matchedRecordId = null
            )
        )
        
        return ResponseEntity.ok(unmatchedTransactions)
    }

    /**
     * 자동 매칭 규칙 설정
     */
    @PostMapping("/matching-rules")
    fun createMatchingRule(
        @RequestParam companyId: UUID,
        @RequestParam connectionId: UUID,
        @RequestBody request: CreateMatchingRuleRequest
    ): ResponseEntity<MatchingRuleResponse> {
        val rule = MatchingRuleResponse(
            ruleId = UUID.randomUUID(),
            ruleName = request.ruleName,
            pattern = request.pattern,
            targetAccountCode = request.targetAccountCode,
            targetRecordType = request.targetRecordType,
            priority = request.priority,
            isActive = true
        )
        
        return ResponseEntity.ok(rule)
    }

    /**
     * 은행 연동 해제
     */
    @DeleteMapping("/disconnect/{connectionId}")
    fun disconnectBankAccount(
        @RequestParam companyId: UUID,
        @PathVariable connectionId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 실제 구현에서는 Service에서 처리
        val response = mapOf(
            "success" to true,
            "message" to "은행 계좌 연동이 해제되었습니다.",
            "connectionId" to connectionId
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 수동 동기화 실행
     */
    @PostMapping("/manual-sync/{connectionId}")
    fun manualSync(
        @RequestParam companyId: UUID,
        @PathVariable connectionId: UUID
    ): ResponseEntity<BankTransactionSyncResult> {
        val request = BankTransactionSyncRequest(
            connectionId = connectionId,
            startDate = LocalDate.now().minusDays(7),
            endDate = LocalDate.now(),
            syncType = "INCREMENTAL"
        )
        
        val result = bankApiService.syncBankTransactions(companyId, request)
        return ResponseEntity.ok(result)
    }
}

// 추가 요청 DTO
data class CreateMatchingRuleRequest(
    val ruleName: String,
    val pattern: String,
    val targetAccountCode: String,
    val targetRecordType: String,
    val priority: Int
)