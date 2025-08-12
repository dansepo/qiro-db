package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.AccountBalanceDto
import com.qiro.domain.accounting.entity.AccountCode
import com.qiro.domain.accounting.entity.AccountType
import com.qiro.domain.accounting.repository.AccountCodeRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 계정과목 잔액 계산 서비스
 */
@Service
@Transactional(readOnly = true)
class AccountBalanceService(
    private val accountCodeRepository: AccountCodeRepository
) {

    /**
     * 특정 계정과목의 잔액을 계산합니다.
     */
    fun calculateAccountBalance(accountId: Long, asOfDate: LocalDate = LocalDate.now()): AccountBalanceDto {
        val accountCode = accountCodeRepository.findById(accountId)
            .orElseThrow { IllegalArgumentException("계정과목을 찾을 수 없습니다: $accountId") }

        // TODO: 실제 회계 항목들을 집계하여 잔액 계산
        // 현재는 임시로 0으로 설정
        val debitAmount = calculateDebitAmount(accountCode, asOfDate)
        val creditAmount = calculateCreditAmount(accountCode, asOfDate)
        val balance = calculateBalance(accountCode.accountType, debitAmount, creditAmount)

        return AccountBalanceDto(
            accountId = 0L, // TODO: AccountCode의 UUID를 Long으로 변환 필요
            accountCode = accountCode.accountCode,
            accountName = accountCode.accountName,
            accountType = accountCode.accountType,
            debitAmount = debitAmount,
            creditAmount = creditAmount,
            balance = balance,
            asOfDate = asOfDate.atStartOfDay()
        )
    }

    /**
     * 회사의 모든 계정과목 잔액을 계산합니다.
     */
    fun calculateAllAccountBalances(companyId: UUID, asOfDate: LocalDate = LocalDate.now()): List<AccountBalanceDto> {
        val accountCodes = accountCodeRepository.findByCompanyCompanyIdAndIsActiveTrue(companyId)
        
        return accountCodes.map { accountCode ->
            val debitAmount = calculateDebitAmount(accountCode, asOfDate)
            val creditAmount = calculateCreditAmount(accountCode, asOfDate)
            val balance = calculateBalance(accountCode.accountType, debitAmount, creditAmount)

            AccountBalanceDto(
                accountId = 0L, // TODO: AccountCode의 UUID를 Long으로 변환 필요
                accountCode = accountCode.accountCode,
                accountName = accountCode.accountName,
                accountType = accountCode.accountType,
                debitAmount = debitAmount,
                creditAmount = creditAmount,
                balance = balance,
                asOfDate = asOfDate.atStartOfDay()
            )
        }
    }

    /**
     * 계정 유형별 잔액 합계를 계산합니다.
     */
    fun calculateAccountTypeBalances(companyId: UUID, asOfDate: LocalDate = LocalDate.now()): Map<AccountType, BigDecimal> {
        val accountBalances = calculateAllAccountBalances(companyId, asOfDate)
        
        return accountBalances.groupBy { it.accountType }
            .mapValues { (_, balances) -> 
                balances.sumOf { it.balance }
            }
    }

    /**
     * 시산표(Trial Balance) 데이터를 생성합니다.
     */
    fun generateTrialBalance(companyId: UUID, asOfDate: LocalDate = LocalDate.now()): List<AccountBalanceDto> {
        return calculateAllAccountBalances(companyId, asOfDate)
            .filter { it.debitAmount != BigDecimal.ZERO || it.creditAmount != BigDecimal.ZERO }
            .sortedBy { it.accountCode }
    }

    /**
     * 계정과목의 월별 잔액 추이를 계산합니다.
     */
    fun calculateMonthlyBalanceTrend(
        accountId: Long, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): Map<LocalDate, BigDecimal> {
        val accountCode = accountCodeRepository.findById(accountId)
            .orElseThrow { IllegalArgumentException("계정과목을 찾을 수 없습니다: $accountId") }

        val result = mutableMapOf<LocalDate, BigDecimal>()
        var currentDate = startDate.withDayOfMonth(1) // 월 첫째 날로 설정
        
        while (!currentDate.isAfter(endDate)) {
            val monthEndDate = currentDate.withDayOfMonth(currentDate.lengthOfMonth())
            val debitAmount = calculateDebitAmount(accountCode, monthEndDate)
            val creditAmount = calculateCreditAmount(accountCode, monthEndDate)
            val balance = calculateBalance(accountCode.accountType, debitAmount, creditAmount)
            
            result[currentDate] = balance
            currentDate = currentDate.plusMonths(1)
        }
        
        return result
    }

    // Private helper methods

    /**
     * 계정과목의 차변 금액을 계산합니다.
     */
    private fun calculateDebitAmount(accountCode: AccountCode, asOfDate: LocalDate): BigDecimal {
        // TODO: 실제 회계 항목에서 차변 금액 집계
        // 현재는 임시로 0 반환
        return BigDecimal.ZERO
    }

    /**
     * 계정과목의 대변 금액을 계산합니다.
     */
    private fun calculateCreditAmount(accountCode: AccountCode, asOfDate: LocalDate): BigDecimal {
        // TODO: 실제 회계 항목에서 대변 금액 집계
        // 현재는 임시로 0 반환
        return BigDecimal.ZERO
    }

    /**
     * 계정 유형에 따라 잔액을 계산합니다.
     */
    private fun calculateBalance(accountType: AccountType, debitAmount: BigDecimal, creditAmount: BigDecimal): BigDecimal {
        return when (accountType) {
            AccountType.ASSET, AccountType.EXPENSE -> debitAmount - creditAmount
            AccountType.LIABILITY, AccountType.EQUITY, AccountType.REVENUE -> creditAmount - debitAmount
        }
    }
}