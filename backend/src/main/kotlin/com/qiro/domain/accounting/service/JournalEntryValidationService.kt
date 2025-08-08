package com.qiro.domain.accounting.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.domain.accounting.entity.JournalEntry
import com.qiro.domain.accounting.entity.JournalEntryStatus
import com.qiro.domain.accounting.repository.JournalEntryRepository
import com.qiro.domain.accounting.repository.JournalEntryLineRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.util.*

/**
 * 분개 전표 검증 서비스
 * 복식부기 원칙 및 회계 규칙 검증을 담당합니다.
 */
@Service
@Transactional(readOnly = true)
class JournalEntryValidationService(
    private val journalEntryRepository: JournalEntryRepository,
    private val journalEntryLineRepository: JournalEntryLineRepository
) {

    private val logger = LoggerFactory.getLogger(JournalEntryValidationService::class.java)

    /**
     * 분개 전표 복식부기 원칙 검증
     * 데이터베이스 트리거 기능을 백엔드로 이관
     */
    fun validateJournalEntryBalance(entryId: UUID): ValidationResult {
        logger.info("분개 전표 복식부기 검증 시작: $entryId")
        
        try {
            val journalEntry = journalEntryRepository.findById(entryId).orElseThrow {
                BusinessException(ErrorCode.ENTITY_NOT_FOUND, "분개 전표를 찾을 수 없습니다: $entryId")
            }

            val errors = mutableListOf<String>()

            // 1. 분개선 존재 확인
            if (journalEntry.journalEntryLines.isEmpty()) {
                errors.add("분개선이 존재하지 않습니다")
                return ValidationResult(false, errors)
            }

            // 2. 최소 분개선 개수 확인 (2개 이상)
            if (journalEntry.journalEntryLines.size < 2) {
                errors.add("분개선은 최소 2개 이상이어야 합니다")
            }

            // 3. 차변/대변 합계 계산
            val totalDebit = journalEntry.getTotalDebitAmount()
            val totalCredit = journalEntry.getTotalCreditAmount()

            // 4. 복식부기 원칙 검증 (차변 = 대변)
            if (totalDebit.compareTo(totalCredit) != 0) {
                errors.add("복식부기 원칙 위반: 차변($totalDebit)과 대변($totalCredit)의 합계가 일치하지 않습니다")
            }

            // 5. 분개선별 차변/대변 검증
            journalEntry.journalEntryLines.forEach { line ->
                val hasDebit = line.debitAmount > BigDecimal.ZERO
                val hasCredit = line.creditAmount > BigDecimal.ZERO

                if (hasDebit && hasCredit) {
                    errors.add("분개선 ${line.lineOrder}: 차변과 대변을 동시에 가질 수 없습니다")
                } else if (!hasDebit && !hasCredit) {
                    errors.add("분개선 ${line.lineOrder}: 차변 또는 대변 중 하나는 반드시 값을 가져야 합니다")
                }

                if (line.debitAmount < BigDecimal.ZERO || line.creditAmount < BigDecimal.ZERO) {
                    errors.add("분개선 ${line.lineOrder}: 금액은 0 이상이어야 합니다")
                }
            }

            // 6. 전표 총액과 분개선 합계 일치 확인
            if (journalEntry.totalAmount.compareTo(totalDebit) != 0) {
                errors.add("전표 총액(${journalEntry.totalAmount})과 차변 합계($totalDebit)가 일치하지 않습니다")
            }

            val result = ValidationResult(errors.isEmpty(), errors)
            logger.info("분개 전표 복식부기 검증 완료: $entryId, 결과: ${result.isValid}")
            
            return result

        } catch (e: Exception) {
            logger.error("분개 전표 복식부기 검증 중 오류 발생: ${e.message}", e)
            throw BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "분개 전표 검증 실패: ${e.message}")
        }
    }

    /**
     * 회계 기간 마감 전 데이터 검증
     */
    fun validateFinancialPeriodClosure(companyId: UUID, fiscalYear: Int, periodNumber: Int): ValidationResult {
        logger.info("회계 기간 마감 검증 시작: $companyId-$fiscalYear-$periodNumber")
        
        try {
            val errors = mutableListOf<String>()

            // 1. 해당 기간의 모든 분개 전표가 전기되었는지 확인
            val unpostedEntries = journalEntryRepository.findByCompanyIdAndStatus(companyId, JournalEntryStatus.DRAFT)
                .plus(journalEntryRepository.findByCompanyIdAndStatus(companyId, JournalEntryStatus.PENDING))
                .plus(journalEntryRepository.findByCompanyIdAndStatus(companyId, JournalEntryStatus.APPROVED))

            if (unpostedEntries.isNotEmpty()) {
                errors.add("전기되지 않은 분개 전표가 ${unpostedEntries.size}개 있습니다")
            }

            // 2. 전체 차변/대변 합계 일치 확인
            val balanceValidation = journalEntryLineRepository.validateTotalBalance(companyId)
            if (balanceValidation.isNotEmpty()) {
                val result = balanceValidation.first() as Array<*>
                val totalDebit = result[0] as BigDecimal
                val totalCredit = result[1] as BigDecimal
                
                if (totalDebit.compareTo(totalCredit) != 0) {
                    errors.add("전체 차변($totalDebit)과 대변($totalCredit)의 합계가 일치하지 않습니다")
                }
            }

            // 3. 복식부기 원칙 위반 분개 전표 확인
            val unbalancedEntries = journalEntryRepository.findUnbalancedJournalEntries(companyId)
            if (unbalancedEntries.isNotEmpty()) {
                errors.add("복식부기 원칙을 위반한 분개 전표가 ${unbalancedEntries.size}개 있습니다")
            }

            val result = ValidationResult(errors.isEmpty(), errors)
            logger.info("회계 기간 마감 검증 완료: $companyId-$fiscalYear-$periodNumber, 결과: ${result.isValid}")
            
            return result

        } catch (e: Exception) {
            logger.error("회계 기간 마감 검증 중 오류 발생: ${e.message}", e)
            throw BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "회계 기간 마감 검증 실패: ${e.message}")
        }
    }

    /**
     * 계정과목 사용 여부 검증
     */
    fun validateAccountUsage(accountId: UUID): ValidationResult {
        logger.info("계정과목 사용 여부 검증 시작: $accountId")
        
        try {
            val errors = mutableListOf<String>()

            // 1. 해당 계정이 분개선에서 사용되고 있는지 확인
            val journalEntryLines = journalEntryLineRepository.findByAccountAccountId(accountId)
            if (journalEntryLines.isNotEmpty()) {
                errors.add("해당 계정은 ${journalEntryLines.size}개의 분개선에서 사용 중이므로 삭제할 수 없습니다")
            }

            // 2. 하위 계정 존재 여부는 AccountService에서 확인하도록 위임
            // (순환 참조 방지)

            val result = ValidationResult(errors.isEmpty(), errors)
            logger.info("계정과목 사용 여부 검증 완료: $accountId, 결과: ${result.isValid}")
            
            return result

        } catch (e: Exception) {
            logger.error("계정과목 사용 여부 검증 중 오류 발생: ${e.message}", e)
            throw BusinessException(ErrorCode.INTERNAL_SERVER_ERROR, "계정과목 사용 여부 검증 실패: ${e.message}")
        }
    }

    /**
     * 분개 전표 상태 변경 가능 여부 검증
     */
    fun validateStatusChange(journalEntry: JournalEntry, targetStatus: JournalEntryStatus): ValidationResult {
        logger.info("분개 전표 상태 변경 검증: ${journalEntry.entryId}, ${journalEntry.status} -> $targetStatus")
        
        val errors = mutableListOf<String>()
        val currentStatus = journalEntry.status

        when (targetStatus) {
            JournalEntryStatus.PENDING -> {
                if (currentStatus != JournalEntryStatus.DRAFT) {
                    errors.add("초안 상태의 분개 전표만 승인 요청할 수 있습니다")
                }
            }
            JournalEntryStatus.APPROVED -> {
                if (currentStatus != JournalEntryStatus.PENDING) {
                    errors.add("승인 대기 중인 분개 전표만 승인할 수 있습니다")
                }
                // 복식부기 원칙 검증
                val balanceValidation = validateJournalEntryBalance(journalEntry.entryId)
                if (!balanceValidation.isValid) {
                    errors.addAll(balanceValidation.errors)
                }
            }
            JournalEntryStatus.POSTED -> {
                if (currentStatus != JournalEntryStatus.APPROVED) {
                    errors.add("승인된 분개 전표만 전기할 수 있습니다")
                }
                // 복식부기 원칙 재검증
                val balanceValidation = validateJournalEntryBalance(journalEntry.entryId)
                if (!balanceValidation.isValid) {
                    errors.addAll(balanceValidation.errors)
                }
            }
            JournalEntryStatus.REVERSED -> {
                if (currentStatus != JournalEntryStatus.POSTED) {
                    errors.add("전기된 분개 전표만 역분개할 수 있습니다")
                }
            }
            JournalEntryStatus.DRAFT -> {
                if (currentStatus != JournalEntryStatus.PENDING) {
                    errors.add("승인 대기 중인 분개 전표만 초안으로 되돌릴 수 있습니다")
                }
            }
        }

        return ValidationResult(errors.isEmpty(), errors)
    }
}

/**
 * 검증 결과 데이터 클래스
 */
data class ValidationResult(
    val isValid: Boolean,
    val errors: List<String> = emptyList(),
    val validatedAt: java.time.LocalDateTime = java.time.LocalDateTime.now()
)