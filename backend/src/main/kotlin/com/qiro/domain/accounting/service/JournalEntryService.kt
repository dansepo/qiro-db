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
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 분개 처리 서비스
 * 분개 전표의 생성, 수정, 승인, 전기, 역분개 등의 핵심 기능을 제공합니다.
 */
@Service
@Transactional(readOnly = true)
class JournalEntryService(
    private val journalEntryRepository: JournalEntryRepository,
    private val journalEntryLineRepository: JournalEntryLineRepository,
    private val accountRepository: AccountRepository,
    private val financialPeriodRepository: FinancialPeriodRepository,
    private val journalEntryValidationService: JournalEntryValidationService
) {

    /**
     * 분개 전표 생성
     */
    @Transactional
    fun createJournalEntry(request: CreateJournalEntryRequest): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        // 회계 기간 확인
        val financialPeriod = financialPeriodRepository.findByCompanyIdAndDate(companyId, request.entryDate)
            ?: throw BusinessException(ErrorCode.BUSINESS_ERROR, "해당 날짜의 회계 기간이 존재하지 않습니다: ${request.entryDate}")
        
        if (financialPeriod.status == FinancialPeriodStatus.CLOSED || financialPeriod.status == FinancialPeriodStatus.LOCKED) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "마감된 회계 기간에는 분개 전표를 생성할 수 없습니다")
        }

        // 분개 전표 번호 생성
        val entryNumber = generateJournalEntryNumber(companyId, request.entryDate)

        // 계정 존재 확인
        val accounts = request.journalEntryLines.map { line ->
            accountRepository.findById(line.accountId).orElseThrow {
                BusinessException(ErrorCode.ENTITY_NOT_FOUND, "계정을 찾을 수 없습니다: ${line.accountId}")
            }
        }

        // 회사 소속 계정인지 확인
        accounts.forEach { account ->
            if (account.companyId != companyId) {
                throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 계정을 사용할 수 없습니다")
            }
        }

        // 분개 전표 생성
        val journalEntry = JournalEntry(
            entryNumber = entryNumber,
            entryDate = request.entryDate,
            entryType = request.entryType,
            referenceType = request.referenceType,
            referenceId = request.referenceId,
            description = request.description,
            totalAmount = request.journalEntryLines.sumOf { it.debitAmount }
        ).apply {
            companyId = TenantContext.getCurrentTenantId()
            createdBy = TenantContext.getCurrentUserId()
        }

        val savedJournalEntry = journalEntryRepository.save(journalEntry)

        // 분개선 생성
        request.journalEntryLines.forEachIndexed { index, lineRequest ->
            val account = accounts[index]
            val journalEntryLine = JournalEntryLine(
                account = account,
                debitAmount = lineRequest.debitAmount,
                creditAmount = lineRequest.creditAmount,
                description = lineRequest.description,
                referenceType = lineRequest.referenceType,
                referenceId = lineRequest.referenceId,
                lineOrder = lineRequest.lineOrder
            )
            savedJournalEntry.addJournalEntryLine(journalEntryLine)
        }

        journalEntryRepository.save(savedJournalEntry)

        // 복식부기 원칙 검증
        val validationResult = journalEntryValidationService.validateJournalEntryBalance(savedJournalEntry.entryId)
        if (!validationResult.isValid) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "분개 전표 검증 실패: ${validationResult.errors.joinToString(", ")}")
        }

        return convertToResponse(savedJournalEntry)
    }

    /**
     * 분개 전표 승인
     */
    @Transactional
    fun approveJournalEntry(entryId: UUID, request: ApproveJournalEntryRequest): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        val currentUserId = TenantContext.getCurrentUserId()
        
        val journalEntry = journalEntryRepository.findById(entryId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "분개 전표를 찾을 수 없습니다: $entryId")
        }

        // 회사 소속 확인
        if (journalEntry.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 분개 전표입니다")
        }

        // 승인 처리
        journalEntry.approve(currentUserId)
        
        val savedJournalEntry = journalEntryRepository.save(journalEntry)

        // 복식부기 원칙 검증
        val validationResult = journalEntryValidationService.validateJournalEntryBalance(savedJournalEntry.entryId)
        if (!validationResult.isValid) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "분개 전표 검증 실패: ${validationResult.errors.joinToString(", ")}")
        }

        return convertToResponse(savedJournalEntry)
    }

    /**
     * 분개 전표 전기
     */
    @Transactional
    fun postJournalEntry(entryId: UUID): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        val journalEntry = journalEntryRepository.findById(entryId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "분개 전표를 찾을 수 없습니다: $entryId")
        }

        // 회사 소속 확인
        if (journalEntry.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 분개 전표입니다")
        }

        // 전기 처리
        journalEntry.post()
        
        val savedJournalEntry = journalEntryRepository.save(journalEntry)

        // 복식부기 원칙 검증
        val validationResult = journalEntryValidationService.validateJournalEntryBalance(savedJournalEntry.entryId)
        if (!validationResult.isValid) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "분개 전표 검증 실패: ${validationResult.errors.joinToString(", ")}")
        }

        return convertToResponse(savedJournalEntry)
    }

    /**
     * 역분개 처리
     */
    @Transactional
    fun reverseJournalEntry(entryId: UUID, request: ReverseJournalEntryRequest): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        val currentUserId = TenantContext.getCurrentUserId()
        
        val originalEntry = journalEntryRepository.findById(entryId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "분개 전표를 찾을 수 없습니다: $entryId")
        }

        // 회사 소속 확인
        if (originalEntry.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 분개 전표입니다")
        }

        // 역분개 전표 번호 생성
        val reversalEntryNumber = generateJournalEntryNumber(companyId, LocalDate.now())

        // 역분개 전표 생성
        val reversalEntry = JournalEntry(
            entryNumber = reversalEntryNumber,
            entryDate = LocalDate.now(),
            entryType = JournalEntryType.ADJUSTMENT,
            referenceType = "REVERSAL",
            referenceId = entryId,
            description = "역분개: ${originalEntry.description} - ${request.reversalReason}",
            totalAmount = originalEntry.totalAmount,
            status = JournalEntryStatus.APPROVED
        ).apply {
            companyId = TenantContext.getCurrentTenantId()
            createdBy = currentUserId
            approvedBy = currentUserId
            approvedAt = java.time.LocalDateTime.now()
        }

        val savedReversalEntry = journalEntryRepository.save(reversalEntry)

        // 원본 분개선을 반대로 생성
        originalEntry.journalEntryLines.forEach { originalLine ->
            val reversalLine = JournalEntryLine(
                account = originalLine.account,
                debitAmount = originalLine.creditAmount,  // 차변과 대변을 바꿈
                creditAmount = originalLine.debitAmount,  // 차변과 대변을 바꿈
                description = "역분개: ${originalLine.description ?: ""}",
                referenceType = "REVERSAL",
                referenceId = originalLine.lineId,
                lineOrder = originalLine.lineOrder
            )
            savedReversalEntry.addJournalEntryLine(reversalLine)
        }

        journalEntryRepository.save(savedReversalEntry)

        // 역분개 전표 즉시 전기
        savedReversalEntry.post()
        journalEntryRepository.save(savedReversalEntry)

        // 원본 전표 역분개 처리
        originalEntry.reverse(request.reversalReason)
        journalEntryRepository.save(originalEntry)

        // 복식부기 원칙 검증
        val validationResult = journalEntryValidationService.validateJournalEntryBalance(savedReversalEntry.entryId)
        if (!validationResult.isValid) {
            throw BusinessException(ErrorCode.BUSINESS_ERROR, "역분개 전표 검증 실패: ${validationResult.errors.joinToString(", ")}")
        }

        return convertToResponse(savedReversalEntry)
    }

    /**
     * 분개 전표 조회
     */
    fun getJournalEntry(entryId: UUID): JournalEntryResponse {
        val companyId = TenantContext.getCurrentTenantId()
        
        val journalEntry = journalEntryRepository.findById(entryId).orElseThrow {
            BusinessException(ErrorCode.ENTITY_NOT_FOUND, "분개 전표를 찾을 수 없습니다: $entryId")
        }

        // 회사 소속 확인
        if (journalEntry.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "다른 회사의 분개 전표입니다")
        }

        return convertToResponse(journalEntry)
    }

    /**
     * 분개 전표 목록 조회
     */
    fun getJournalEntries(pageable: Pageable): Page<JournalEntryListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        return journalEntryRepository.findByCompanyIdOrderByEntryDateDescEntryNumberDesc(companyId, pageable)
            .map { convertToListResponse(it) }
    }

    /**
     * 분개 전표 검색
     */
    fun searchJournalEntries(searchRequest: JournalEntrySearchRequest): List<JournalEntryListResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        // 기본적인 검색 로직
        val entries = when {
            searchRequest.startDate != null && searchRequest.endDate != null -> {
                if (searchRequest.status != null) {
                    journalEntryRepository.findByCompanyIdAndEntryDateBetweenAndStatusOrderByEntryDateDescEntryNumberDesc(
                        companyId, searchRequest.startDate, searchRequest.endDate, searchRequest.status
                    )
                } else {
                    journalEntryRepository.findByCompanyIdAndEntryDateBetweenOrderByEntryDateDescEntryNumberDesc(
                        companyId, searchRequest.startDate, searchRequest.endDate
                    )
                }
            }
            searchRequest.status != null -> {
                journalEntryRepository.findByCompanyIdAndStatus(companyId, searchRequest.status)
            }
            else -> {
                journalEntryRepository.findByCompanyIdOrderByEntryDateDescEntryNumberDesc(companyId, Pageable.unpaged()).content
            }
        }

        return entries.map { convertToListResponse(it) }
    }

    /**
     * 시산표 조회
     */
    fun getTrialBalance(startDate: LocalDate, endDate: LocalDate): List<TrialBalanceResponse> {
        val companyId = TenantContext.getCurrentTenantId()
        
        val results = journalEntryLineRepository.getTrialBalance(companyId, startDate, endDate)
        
        return results.map { result ->
            val array = result as Array<*>
            TrialBalanceResponse(
                accountId = array[0] as UUID,
                accountCode = array[1] as String,
                accountName = array[2] as String,
                accountType = array[3] as String,
                totalDebit = array[4] as BigDecimal,
                totalCredit = array[5] as BigDecimal,
                balance = array[6] as BigDecimal
            )
        }
    }

    /**
     * 분개 전표 번호 생성
     */
    private fun generateJournalEntryNumber(companyId: UUID, entryDate: LocalDate): String {
        val year = entryDate.year
        val month = entryDate.monthValue
        val pattern = "JE$year${month.toString().padStart(2, '0')}%"
        
        val lastEntryNumber = journalEntryRepository.findLastEntryNumberByYearMonth(companyId, year, month, pattern)
        
        val sequence = if (lastEntryNumber != null) {
            val lastSequence = lastEntryNumber.substring(8).toInt()
            lastSequence + 1
        } else {
            1
        }
        
        return "JE$year${month.toString().padStart(2, '0')}${sequence.toString().padStart(4, '0')}"
    }

    /**
     * 엔티티를 응답 DTO로 변환
     */
    private fun convertToResponse(journalEntry: JournalEntry): JournalEntryResponse {
        return JournalEntryResponse(
            entryId = journalEntry.entryId,
            entryNumber = journalEntry.entryNumber,
            entryDate = journalEntry.entryDate,
            entryType = journalEntry.entryType,
            referenceType = journalEntry.referenceType,
            referenceId = journalEntry.referenceId,
            description = journalEntry.description,
            totalAmount = journalEntry.totalAmount,
            status = journalEntry.status,
            approvedBy = journalEntry.approvedBy,
            approvedAt = journalEntry.approvedAt,
            postedAt = journalEntry.postedAt,
            reversedAt = journalEntry.reversedAt,
            reversalReason = journalEntry.reversalReason,
            journalEntryLines = journalEntry.journalEntryLines.sortedBy { it.lineOrder }.map { line ->
                JournalEntryLineResponse(
                    lineId = line.lineId,
                    account = AccountSummaryResponse(
                        accountId = line.account.accountId,
                        accountCode = line.account.accountCode,
                        accountName = line.account.accountName,
                        accountType = line.account.accountType.name
                    ),
                    debitAmount = line.debitAmount,
                    creditAmount = line.creditAmount,
                    description = line.description,
                    referenceType = line.referenceType,
                    referenceId = line.referenceId,
                    lineOrder = line.lineOrder,
                    createdAt = line.createdAt
                )
            },
            createdAt = journalEntry.createdAt,
            updatedAt = journalEntry.updatedAt,
            createdBy = journalEntry.createdBy
        )
    }

    /**
     * 엔티티를 목록 응답 DTO로 변환
     */
    private fun convertToListResponse(journalEntry: JournalEntry): JournalEntryListResponse {
        return JournalEntryListResponse(
            entryId = journalEntry.entryId,
            entryNumber = journalEntry.entryNumber,
            entryDate = journalEntry.entryDate,
            entryType = journalEntry.entryType,
            description = journalEntry.description,
            totalAmount = journalEntry.totalAmount,
            status = journalEntry.status,
            createdAt = journalEntry.createdAt,
            createdBy = journalEntry.createdBy
        )
    }
}