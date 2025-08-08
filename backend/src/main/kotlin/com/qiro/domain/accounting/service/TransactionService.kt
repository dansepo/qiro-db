package com.qiro.domain.accounting.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.*

/**
 * 거래 관리 서비스
 * 거래 기록, 분류, 승인 등의 핵심 기능을 제공합니다.
 */
@Service
@Transactional(readOnly = true)
class TransactionService(
    private val transactionRepository: TransactionRepository,
    private val accountRepository: AccountRepository,
    private val transactionClassificationService: TransactionClassificationService,
    private val journalEntryService: JournalEntryService
) {

    /**
     * 거래 생성
     */
    @Transactional
    fun createTransaction(request: CreateTransactionRequest): TransactionResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        // 거래 번호 생성
        val transactionNumber = generateTransactionNumber(companyId, request.transactionDate)

        // 거래 생성
        val transaction = Transaction(
            transactionNumber = transactionNumber,
            transactionDate = request.transactionDate,
            transactionType = request.transactionType,
            transactionCategory = request.transactionCategory,
            description = request.description,
            amount = request.amount,
            counterparty = request.counterparty,
            counterpartyAccount = request.counterpartyAccount,
            referenceType = request.referenceType,
            referenceId = request.referenceId,
            tags = request.tags?.joinToString(","),
            notes = request.notes
        ).apply {
            companyId = TenantContext.getCurrentTenantId()
            createdBy = TenantContext.getCurrentUserId()
        }

        val savedTransaction = transactionRepository.save(transaction)

        // 자동 계정과목 제안
        val suggestion = transactionClassificationService.suggestAccount(savedTransaction)
        if (suggestion != null) {
            savedTransaction.suggestedAccount = suggestion.account
            savedTransaction.confidenceScore = suggestion.confidenceScore
            transactionRepository.save(savedTransaction)
        }

        return convertToResponse(savedTransaction)
    }

    /**
     * 거래 수정
     */
    @Transactional
    fun updateTransaction(transactionId: UUID, request: UpdateTransactionRequest): TransactionResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        val transaction = transactionRepository.findById(transactionId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "거래를 찾을 수 없습니다: $transactionId")
        }

        // 회사 소속 확인
        if (transaction.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 거래입니다")
        }

        // 수정 가능 상태 확인
        if (transaction.status != TransactionStatus.PENDING) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "승인 대기 중인 거래만 수정할 수 있습니다")
        }

        // 거래 정보 업데이트 (새로운 Transaction 객체 생성)
        val updatedTransaction = Transaction(
            transactionId = transaction.transactionId,
            transactionNumber = transaction.transactionNumber,
            transactionDate = request.transactionDate,
            transactionType = request.transactionType,
            transactionCategory = request.transactionCategory,
            description = request.description,
            amount = request.amount,
            counterparty = request.counterparty,
            counterpartyAccount = request.counterpartyAccount,
            referenceType = request.referenceType,
            referenceId = request.referenceId,
            tags = request.tags?.joinToString(","),
            notes = request.notes,
            status = transaction.status
        ).apply {
            companyId = transaction.companyId
            createdBy = transaction.createdBy
            updatedBy = TenantContext.getCurrentUserId()
        }

        val savedTransaction = transactionRepository.save(updatedTransaction)

        // 계정과목 재제안
        val suggestion = transactionClassificationService.suggestAccount(savedTransaction)
        if (suggestion != null) {
            savedTransaction.suggestedAccount = suggestion.account
            savedTransaction.confidenceScore = suggestion.confidenceScore
            transactionRepository.save(savedTransaction)
        }

        return convertToResponse(savedTransaction)
    }

    /**
     * 거래 승인
     */
    @Transactional
    fun approveTransaction(transactionId: UUID, request: ApproveTransactionRequest): TransactionResponse {
        val companyId = TenantContext.getCurrentTenantId()
        val currentUserId = TenantContext.getCurrentUserId()
        
        val transaction = transactionRepository.findById(transactionId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "거래를 찾을 수 없습니다: $transactionId")
        }

        // 회사 소속 확인
        if (transaction.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 거래입니다")
        }

        // 계정과목 확인
        val account = accountRepository.findById(request.accountId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "계정과목을 찾을 수 없습니다: ${request.accountId}")
        }

        if (account.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 계정과목입니다")
        }

        // 승인 처리
        transaction.approve(currentUserId, account)
        transaction.notes = request.notes
        
        val savedTransaction = transactionRepository.save(transaction)

        // 분류 규칙 학습 (승인된 계정과목으로)
        transactionClassificationService.learnFromApproval(savedTransaction, account)

        return convertToResponse(savedTransaction)
    }

    /**
     * 거래 거부
     */
    @Transactional
    fun rejectTransaction(transactionId: UUID, request: RejectTransactionRequest): TransactionResponse {
        val companyId = TenantContext.getCurrentTenantId()
        val currentUserId = TenantContext.getCurrentUserId()
        
        val transaction = transactionRepository.findById(transactionId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "거래를 찾을 수 없습니다: $transactionId")
        }

        // 회사 소속 확인
        if (transaction.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 거래입니다")
        }

        // 거부 처리
        transaction.reject(currentUserId, request.reason)
        
        val savedTransaction = transactionRepository.save(transaction)

        return convertToResponse(savedTransaction)
    }

    /**
     * 거래를 분개 전표로 처리
     */
    @Transactional
    fun processToJournalEntry(transactionId: UUID): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        val transaction = transactionRepository.findById(transactionId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "거래를 찾을 수 없습니다: $transactionId")
        }

        // 회사 소속 확인
        if (transaction.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 거래입니다")
        }

        // 승인된 거래만 처리 가능
        if (transaction.status != TransactionStatus.APPROVED) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "승인된 거래만 분개 전표로 처리할 수 있습니다")
        }

        // 제안된 계정과목 확인
        val suggestedAccount = transaction.suggestedAccount
            ?: throw BusinessException(ErrorCode.BUSINESS_ERROR, "계정과목이 지정되지 않았습니다")

        // 분개 전표 생성 요청 구성
        val journalEntryRequest = createJournalEntryFromTransaction(transaction, suggestedAccount)
        
        // 분개 전표 생성
        val journalEntryResponse = journalEntryService.createJournalEntry(journalEntryRequest)

        // 거래 상태를 처리 완료로 변경
        val journalEntry = JournalEntry(
            entryId = UUID.fromString(journalEntryResponse.entryId.toString()),
            entryNumber = journalEntryResponse.entryNumber,
            entryDate = journalEntryResponse.entryDate,
            entryType = journalEntryResponse.entryType,
            description = journalEntryResponse.description,
            totalAmount = journalEntryResponse.totalAmount
        )
        
        transaction.markAsProcessed(journalEntry)
        transactionRepository.save(transaction)

        return journalEntryResponse
    }

    /**
     * 거래 조회
     */
    fun getTransaction(transactionId: UUID): TransactionResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        val transaction = transactionRepository.findById(transactionId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "거래를 찾을 수 없습니다: $transactionId")
        }

        // 회사 소속 확인
        if (transaction.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 거래입니다")
        }

        return convertToResponse(transaction)
    }

    /**
     * 거래 목록 조회
     */
    fun getTransactions(pageable: Pageable): Page<TransactionListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        return transactionRepository.findByCompanyIdOrderByTransactionDateDescCreatedAtDesc(companyId, pageable)
            .map { convertToListResponse(it) }
    }

    /**
     * 거래 검색
     */
    fun searchTransactions(searchRequest: TransactionSearchRequest): List<TransactionListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        val transactions = when {
            searchRequest.startDate != null && searchRequest.endDate != null -> {
                if (searchRequest.status != null) {
                    transactionRepository.findByCompanyIdAndTransactionDateBetweenAndStatusOrderByTransactionDateDescCreatedAtDesc(
                        companyId, searchRequest.startDate, searchRequest.endDate, searchRequest.status
                    )
                } else {
                    transactionRepository.findByCompanyIdAndTransactionDateBetweenOrderByTransactionDateDescCreatedAtDesc(
                        companyId, searchRequest.startDate, searchRequest.endDate
                    )
                }
            }
            searchRequest.status != null -> {
                transactionRepository.findByCompanyIdAndStatus(companyId, searchRequest.status)
            }
            searchRequest.transactionType != null -> {
                transactionRepository.findByCompanyIdAndTransactionType(companyId, searchRequest.transactionType)
            }
            searchRequest.counterparty != null -> {
                transactionRepository.findByCounterpartyContaining(companyId, searchRequest.counterparty)
            }
            else -> {
                transactionRepository.findByCompanyIdOrderByTransactionDateDescCreatedAtDesc(companyId, Pageable.unpaged()).content
            }
        }

        return transactions.map { convertToListResponse(it) }
    }

    /**
     * 승인 대기 거래 조회
     */
    fun getPendingTransactions(): List<TransactionListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        return transactionRepository.findPendingTransactions(companyId)
            .map { convertToListResponse(it) }
    }

    /**
     * 미처리 거래 조회 (분개 전표 미생성)
     */
    fun getUnprocessedTransactions(): List<TransactionListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        return transactionRepository.findUnprocessedTransactions(companyId)
            .map { convertToListResponse(it) }
    }

    /**
     * 거래 번호 생성
     */
    private fun generateTransactionNumber(companyId: UUID, transactionDate: LocalDate): String {
        val year = transactionDate.year
        val month = transactionDate.monthValue
        val pattern = "TX$year${month.toString().padStart(2, '0')}%"
        
        val lastTransactionNumber = transactionRepository.findLastTransactionNumberByYearMonth(companyId, year, month, pattern)
        
        val sequence = if (lastTransactionNumber != null) {
            val lastSequence = lastTransactionNumber.substring(8).toInt()
            lastSequence + 1
        } else {
            1
        }
        
        return "TX$year${month.toString().padStart(2, '0')}${sequence.toString().padStart(4, '0')}"
    }

    /**
     * 거래에서 분개 전표 생성 요청 구성
     */
    private fun createJournalEntryFromTransaction(
        transaction: Transaction,
        account: Account
    ): CreateJournalEntryRequest {
        val lines = mutableListOf<CreateJournalEntryLineRequest>()

        when (transaction.transactionType) {
            TransactionType.INCOME -> {
                // 수입: 차변(현금), 대변(수익계정)
                // 현금 계정 (차변)
                lines.add(CreateJournalEntryLineRequest(
                    accountId = getCashAccountId(),
                    debitAmount = transaction.amount,
                    creditAmount = java.math.BigDecimal.ZERO,
                    description = "${transaction.counterparty ?: ""} ${transaction.description}",
                    referenceType = "TRANSACTION",
                    referenceId = transaction.transactionId,
                    lineOrder = 1
                ))
                
                // 수익 계정 (대변)
                lines.add(CreateJournalEntryLineRequest(
                    accountId = account.accountId,
                    debitAmount = java.math.BigDecimal.ZERO,
                    creditAmount = transaction.amount,
                    description = transaction.description,
                    referenceType = "TRANSACTION",
                    referenceId = transaction.transactionId,
                    lineOrder = 2
                ))
            }
            
            TransactionType.EXPENSE -> {
                // 지출: 차변(비용계정), 대변(현금)
                // 비용 계정 (차변)
                lines.add(CreateJournalEntryLineRequest(
                    accountId = account.accountId,
                    debitAmount = transaction.amount,
                    creditAmount = java.math.BigDecimal.ZERO,
                    description = transaction.description,
                    referenceType = "TRANSACTION",
                    referenceId = transaction.transactionId,
                    lineOrder = 1
                ))
                
                // 현금 계정 (대변)
                lines.add(CreateJournalEntryLineRequest(
                    accountId = getCashAccountId(),
                    debitAmount = java.math.BigDecimal.ZERO,
                    creditAmount = transaction.amount,
                    description = "${transaction.counterparty ?: ""} ${transaction.description}",
                    referenceType = "TRANSACTION",
                    referenceId = transaction.transactionId,
                    lineOrder = 2
                ))
            }
        }

        return CreateJournalEntryRequest(
            entryDate = transaction.transactionDate,
            description = "거래 처리: ${transaction.description}",
            entryType = JournalEntryType.AUTO,
            referenceType = "TRANSACTION",
            referenceId = transaction.transactionId,
            journalEntryLines = lines
        )
    }

    /**
     * 현금 계정 ID 조회 (임시 구현)
     */
    private fun getCashAccountId(): UUID {
        val companyId = TenantContext.getCurrentTenantId()
        val cashAccount = accountRepository.findByCompanyIdAndAccountCode(companyId, "1100")
            ?: throw BusinessException(ErrorCode.ENTITY_NOT_FOUND, "현금 계정을 찾을 수 없습니다")
        return cashAccount.accountId
    }

    /**
     * 엔티티를 응답 DTO로 변환
     */
    private fun convertToResponse(transaction: Transaction): TransactionResponse {
        return TransactionResponse(
            transactionId = transaction.transactionId,
            transactionNumber = transaction.transactionNumber,
            transactionDate = transaction.transactionDate,
            transactionType = transaction.transactionType,
            transactionCategory = transaction.transactionCategory,
            description = transaction.description,
            amount = transaction.amount,
            counterparty = transaction.counterparty,
            counterpartyAccount = transaction.counterpartyAccount,
            suggestedAccount = transaction.suggestedAccount?.let { account ->
                AccountSummaryResponse(
                    accountId = account.accountId,
                    accountCode = account.accountCode,
                    accountName = account.accountName,
                    accountType = account.accountType.name
                )
            },
            confidenceScore = transaction.confidenceScore,
            referenceType = transaction.referenceType,
            referenceId = transaction.referenceId,
            status = transaction.status,
            approvedBy = transaction.approvedBy,
            approvedAt = transaction.approvedAt,
            rejectionReason = transaction.rejectionReason,
            tags = transaction.getTagList(),
            notes = transaction.notes,
            createdAt = transaction.createdAt,
            updatedAt = transaction.updatedAt,
            createdBy = transaction.createdBy
        )
    }

    /**
     * 엔티티를 목록 응답 DTO로 변환
     */
    private fun convertToListResponse(transaction: Transaction): TransactionListResponse {
        return TransactionListResponse(
            transactionId = transaction.transactionId,
            transactionNumber = transaction.transactionNumber,
            transactionDate = transaction.transactionDate,
            transactionType = transaction.transactionType,
            transactionCategory = transaction.transactionCategory,
            description = transaction.description,
            amount = transaction.amount,
            counterparty = transaction.counterparty,
            status = transaction.status,
            suggestedAccount = transaction.suggestedAccount?.let { account ->
                AccountSummaryResponse(
                    accountId = account.accountId,
                    accountCode = account.accountCode,
                    accountName = account.accountName,
                    accountType = account.accountType.name
                )
            },
            confidenceScore = transaction.confidenceScore,
            createdAt = transaction.createdAt
        )
    }
}