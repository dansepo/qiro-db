package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.entity.AccountType
import com.qiro.domain.accounting.repository.AccountCodeRepository
import org.springframework.stereotype.Service
import java.util.*

/**
 * 계정과목 코드 자동 생성 서비스
 */
@Service
class AccountCodeGeneratorService(
    private val accountCodeRepository: AccountCodeRepository
) {

    /**
     * 계정 유형에 따른 다음 계정과목 코드를 생성합니다.
     */
    fun generateNextAccountCode(companyId: UUID, accountType: AccountType, parentAccountId: Long? = null): String {
        return if (parentAccountId != null) {
            generateChildAccountCode(companyId, parentAccountId)
        } else {
            generateRootAccountCode(companyId, accountType)
        }
    }

    /**
     * 최상위 계정과목 코드를 생성합니다.
     */
    private fun generateRootAccountCode(companyId: UUID, accountType: AccountType): String {
        val prefix = getAccountTypePrefix(accountType)
        val maxCode = accountCodeRepository.findMaxAccountCodeByTypeAndPrefix(companyId, accountType, prefix)
        
        return if (maxCode != null) {
            val currentNumber = maxCode.substring(1).toInt()
            val nextNumber = findNextAvailableNumber(companyId, prefix, currentNumber)
            prefix + String.format("%03d", nextNumber)
        } else {
            prefix + "100" // 첫 번째 계정은 x100부터 시작
        }
    }

    /**
     * 하위 계정과목 코드를 생성합니다.
     */
    private fun generateChildAccountCode(companyId: UUID, parentAccountId: Long): String {
        val parentAccount = accountCodeRepository.findById(parentAccountId)
            .orElseThrow { IllegalArgumentException("상위 계정과목을 찾을 수 없습니다: $parentAccountId") }

        val parentCode = parentAccount.accountCode
        val childAccounts = accountCodeRepository.findByParentAccountIdAndIsActiveTrue(parentAccountId)
        
        if (childAccounts.isEmpty()) {
            // 첫 번째 하위 계정
            return when (parentAccount.accountLevel) {
                1 -> parentCode.substring(0, 2) + "10" // 1100 -> 1110
                2 -> parentCode.substring(0, 3) + "1"  // 1110 -> 1111
                else -> throw IllegalArgumentException("3레벨 이하의 계정과목은 지원하지 않습니다")
            }
        } else {
            // 기존 하위 계정이 있는 경우 다음 번호 생성
            val maxChildCode = childAccounts.maxByOrNull { it.accountCode }?.accountCode
                ?: throw IllegalStateException("하위 계정 코드를 찾을 수 없습니다")

            return generateNextSequentialCode(maxChildCode, parentAccount.accountLevel)
        }
    }

    /**
     * 순차적인 다음 코드를 생성합니다.
     */
    private fun generateNextSequentialCode(maxCode: String, parentLevel: Int): String {
        return when (parentLevel) {
            1 -> {
                // 2레벨: 1110 -> 1120
                val baseCode = maxCode.substring(0, 2)
                val lastTwoDigits = maxCode.substring(2).toInt()
                baseCode + String.format("%02d", lastTwoDigits + 10)
            }
            2 -> {
                // 3레벨: 1111 -> 1112
                val baseCode = maxCode.substring(0, 3)
                val lastDigit = maxCode.substring(3).toInt()
                baseCode + (lastDigit + 1).toString()
            }
            else -> throw IllegalArgumentException("지원하지 않는 계정 레벨입니다: $parentLevel")
        }
    }

    /**
     * 사용 가능한 다음 번호를 찾습니다.
     */
    private fun findNextAvailableNumber(companyId: UUID, prefix: String, currentMax: Int): Int {
        var nextNumber = currentMax + 100 // 100 단위로 증가
        
        // 최대 10번 시도하여 사용 가능한 번호 찾기
        repeat(10) {
            val candidateCode = prefix + String.format("%03d", nextNumber)
            if (!accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, candidateCode)) {
                return nextNumber
            }
            nextNumber += 100
        }
        
        throw IllegalStateException("사용 가능한 계정과목 코드를 생성할 수 없습니다")
    }

    /**
     * 계정 유형별 접두사를 반환합니다.
     */
    private fun getAccountTypePrefix(accountType: AccountType): String {
        return when (accountType) {
            AccountType.ASSET -> "1"
            AccountType.LIABILITY -> "2"
            AccountType.EQUITY -> "3"
            AccountType.REVENUE -> "4"
            AccountType.EXPENSE -> "5"
        }
    }

    /**
     * 계정과목 코드의 유효성을 검증합니다.
     */
    fun validateAccountCode(accountCode: String, accountType: AccountType): Boolean {
        // 4자리 숫자 형식 확인
        if (!accountCode.matches(Regex("^[0-9]{4}$"))) {
            return false
        }

        // 계정 유형과 첫 번째 자리 일치 확인
        val expectedPrefix = getAccountTypePrefix(accountType)
        if (!accountCode.startsWith(expectedPrefix)) {
            return false
        }

        return true
    }

    /**
     * 계정과목 코드 체계를 검증합니다.
     */
    fun validateAccountCodeHierarchy(
        companyId: UUID,
        accountCode: String,
        parentAccountId: Long?
    ): Boolean {
        if (parentAccountId == null) {
            // 최상위 계정인 경우 x100 형태여야 함
            return accountCode.matches(Regex("^[1-5][0-9]00$"))
        }

        val parentAccount = accountCodeRepository.findById(parentAccountId)
            .orElseThrow { IllegalArgumentException("상위 계정과목을 찾을 수 없습니다: $parentAccountId") }

        val parentCode = parentAccount.accountCode

        return when (parentAccount.accountLevel) {
            1 -> {
                // 2레벨: 1100 -> 11xx 형태
                accountCode.startsWith(parentCode.substring(0, 2)) && 
                accountCode.matches(Regex("^${parentCode.substring(0, 2)}[1-9]0$"))
            }
            2 -> {
                // 3레벨: 1110 -> 111x 형태
                accountCode.startsWith(parentCode.substring(0, 3)) && 
                accountCode.matches(Regex("^${parentCode.substring(0, 3)}[1-9]$"))
            }
            else -> false
        }
    }

    /**
     * 표준 계정과목 코드 체계를 반환합니다.
     */
    fun getStandardAccountCodes(): Map<AccountType, List<Pair<String, String>>> {
        return mapOf(
            AccountType.ASSET to listOf(
                "1100" to "현금",
                "1200" to "예금",
                "1300" to "미수금",
                "1400" to "재고자산",
                "1500" to "유형자산",
                "1600" to "무형자산"
            ),
            AccountType.LIABILITY to listOf(
                "2100" to "미지급금",
                "2200" to "단기차입금",
                "2300" to "장기차입금",
                "2400" to "충당금"
            ),
            AccountType.EQUITY to listOf(
                "3100" to "자본금",
                "3200" to "자본잉여금",
                "3300" to "이익잉여금"
            ),
            AccountType.REVENUE to listOf(
                "4100" to "매출액",
                "4200" to "임대료수익",
                "4300" to "기타수익"
            ),
            AccountType.EXPENSE to listOf(
                "5100" to "매출원가",
                "5200" to "판매관리비",
                "5300" to "기타비용"
            )
        )
    }
}