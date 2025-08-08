package com.qiro.domain.accounting.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.AccountCode
import com.qiro.domain.accounting.entity.AccountType
import com.qiro.domain.accounting.repository.AccountCodeRepository
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.user.repository.UserRepository
import java.util.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/** 계정과목 관리 서비스 */
@Service
@Transactional(readOnly = true)
class AccountCodeService(
        private val accountCodeRepository: AccountCodeRepository,
        private val companyRepository: CompanyRepository,
        private val userRepository: UserRepository
) {

    /** 계정과목 생성 */
    @Transactional
    fun createAccountCode(
            companyId: UUID,
            request: CreateAccountCodeRequest,
            userId: UUID
    ): AccountCodeDto {
        // 회사 존재 확인
        val company =
                companyRepository.findById(companyId).orElseThrow {
                    BusinessException(ErrorCode.COMPANY_NOT_FOUND)
                }

        // 사용자 존재 확인
        val user =
                userRepository.findById(userId).orElseThrow {
                    BusinessException(ErrorCode.USER_NOT_FOUND)
                }

        // 계정과목 코드 중복 확인
        if (accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(
                        companyId,
                        request.accountCode
                )
        ) {
            throw BusinessException(ErrorCode.DUPLICATE_ACCOUNT_CODE)
        }

        // 계정과목 코드 유효성 검증
        if (!isValidAccountCode(request.accountCode)) {
            throw BusinessException(ErrorCode.INVALID_ACCOUNT_CODE)
        }

        // 상위 계정과목 확인 및 레벨 계산
        var parentAccount: AccountCode? = null
        var accountLevel = 1

        request.parentAccountId?.let { parentId ->
            parentAccount =
                    accountCodeRepository.findById(parentId).orElseThrow {
                        BusinessException(ErrorCode.PARENT_ACCOUNT_NOT_FOUND)
                    }

            // 상위 계정과목이 같은 회사인지 확인
            if (parentAccount!!.company.companyId != companyId) {
                throw BusinessException(ErrorCode.INVALID_PARENT_ACCOUNT)
            }

            accountLevel = parentAccount!!.accountLevel + 1
        }

        // 계정과목 생성
        val accountCode =
                AccountCode(
                        company = company,
                        accountCode = request.accountCode,
                        accountName = request.accountName,
                        accountType = request.accountType,
                        parentAccount = parentAccount,
                        accountLevel = accountLevel,
                        description = request.description,
                        createdBy = user
                )

        val savedAccountCode = accountCodeRepository.save(accountCode)
        return convertToDto(savedAccountCode)
    }

    /** 계정과목 수정 */
    @Transactional
    fun updateAccountCode(
            companyId: UUID,
            accountId: Long,
            request: UpdateAccountCodeRequest,
            userId: UUID
    ): AccountCodeDto {
        val accountCode = findAccountCodeByIdAndCompany(accountId, companyId)
        val user =
                userRepository.findById(userId).orElseThrow {
                    BusinessException(ErrorCode.USER_NOT_FOUND)
                }

        // 시스템 계정과목은 수정 불가
        if (accountCode.isSystemAccount) {
            throw BusinessException(ErrorCode.SYSTEM_ACCOUNT_NOT_MODIFIABLE)
        }

        // 필드별 업데이트
        request.accountName?.let { accountCode.accountName = it }
        request.accountType?.let { accountCode.accountType = it }
        request.description?.let { accountCode.description = it }
        request.isActive?.let {
            if (!it) {
                accountCode.deactivate()
            } else {
                accountCode.isActive = it
            }
        }

        // 상위 계정과목 변경
        request.parentAccountId?.let { parentId ->
            val parentAccount =
                    accountCodeRepository.findById(parentId).orElseThrow {
                        BusinessException(ErrorCode.PARENT_ACCOUNT_NOT_FOUND)
                    }

            if (parentAccount.company.companyId != companyId) {
                throw BusinessException(ErrorCode.INVALID_PARENT_ACCOUNT)
            }

            // 순환 참조 방지
            if (isCircularReference(accountCode, parentAccount)) {
                throw BusinessException(ErrorCode.CIRCULAR_REFERENCE_DETECTED)
            }

            accountCode.parentAccount = parentAccount
            accountCode.accountLevel = parentAccount.accountLevel + 1
        }

        accountCode.updatedBy = user
        val savedAccountCode = accountCodeRepository.save(accountCode)
        return convertToDto(savedAccountCode)
    }

    /** 계정과목 삭제 */
    @Transactional
    fun deleteAccountCode(companyId: UUID, accountId: Long) {
        val accountCode = findAccountCodeByIdAndCompany(accountId, companyId)

        // 시스템 계정과목은 삭제 불가
        if (accountCode.isSystemAccount) {
            throw BusinessException(ErrorCode.SYSTEM_ACCOUNT_NOT_DELETABLE)
        }

        // 하위 계정과목이 있는지 확인
        if (accountCodeRepository.existsByParentAccountId(accountId)) {
            throw BusinessException(ErrorCode.ACCOUNT_HAS_CHILD_ACCOUNTS)
        }

        // 활성 거래가 있는지 확인
        if (accountCode.hasActiveTransactions()) {
            throw BusinessException(ErrorCode.ACCOUNT_HAS_ACTIVE_TRANSACTIONS)
        }

        accountCodeRepository.delete(accountCode)
    }

    /** 계정과목 단건 조회 */
    fun getAccountCode(companyId: UUID, accountId: Long): AccountCodeDto {
        val accountCode = findAccountCodeByIdAndCompany(accountId, companyId)
        return convertToDto(accountCode)
    }

    /** 계정과목 목록 조회 */
    fun getAccountCodes(companyId: UUID, pageable: Pageable): Page<AccountCodeDto> {
        return accountCodeRepository.findByCompanyCompanyId(companyId, pageable).map {
            convertToDto(it)
        }
    }

    /** 활성 계정과목 목록 조회 */
    fun getActiveAccountCodes(companyId: UUID, pageable: Pageable): Page<AccountCodeDto> {
        return accountCodeRepository.findByCompanyCompanyIdAndIsActiveTrue(companyId, pageable)
                .map { convertToDto(it) }
    }

    /** 계정과목 검색 */
    fun searchAccountCodes(
            companyId: UUID,
            searchRequest: AccountCodeSearchRequest,
            pageable: Pageable
    ): Page<AccountCodeDto> {
        return accountCodeRepository.searchAccountCodes(
                        companyId = companyId,
                        accountCode = searchRequest.accountCode,
                        accountName = searchRequest.accountName,
                        accountType = searchRequest.accountType,
                        parentAccountId = searchRequest.parentAccountId,
                        accountLevel = searchRequest.accountLevel,
                        activeOnly = searchRequest.activeOnly,
                        includeSystemAccounts = searchRequest.includeSystemAccounts,
                        pageable = pageable
                )
                .map { convertToDto(it) }
    }

    /** 계정과목 계층 구조 조회 */
    fun getAccountCodeHierarchy(companyId: UUID): List<AccountCodeHierarchyDto> {
        val rootAccounts =
                accountCodeRepository.findByCompanyCompanyIdAndParentAccountIsNullAndIsActiveTrue(
                        companyId
                )
        return rootAccounts.map { buildHierarchy(it) }
    }

    /** 계정 유형별 계정과목 조회 */
    fun getAccountCodesByType(companyId: UUID, accountType: AccountType): List<AccountCodeDto> {
        return accountCodeRepository.findByCompanyCompanyIdAndAccountTypeAndIsActiveTrue(
                        companyId,
                        accountType
                )
                .map { convertToDto(it) }
    }

    /** 계정과목 통계 조회 */
    fun getAccountCodeStatistics(companyId: UUID): AccountCodeStatisticsDto {
        val totalAccounts = accountCodeRepository.countByCompanyCompanyId(companyId)
        val activeAccounts = accountCodeRepository.countByCompanyCompanyIdAndIsActiveTrue(companyId)

        val accountTypeStats =
                accountCodeRepository.getAccountTypeStatistics(companyId).associate {
                    (it[0] as AccountType) to (it[1] as Long)
                }

        val accountLevelStats =
                accountCodeRepository.getAccountLevelStatistics(companyId).associate {
                    (it[0] as Int) to (it[1] as Long)
                }

        return AccountCodeStatisticsDto(
                totalAccounts = totalAccounts,
                activeAccounts = activeAccounts,
                accountTypeStatistics = accountTypeStats,
                accountLevelStatistics = accountLevelStats
        )
    }

    /** 다음 계정과목 코드 생성 */
    fun generateNextAccountCode(companyId: UUID, accountType: AccountType): String {
        val prefix = getAccountTypePrefix(accountType)
        val maxCode =
                accountCodeRepository.findMaxAccountCodeByTypeAndPrefix(
                        companyId,
                        accountType,
                        prefix
                )

        return if (maxCode != null) {
            val nextNumber = maxCode.substring(1).toInt() + 1
            prefix + String.format("%03d", nextNumber)
        } else {
            prefix + "001"
        }
    }

    /** 기본 계정과목 생성 */
    @Transactional
    fun createDefaultAccountCodes(companyId: UUID, userId: UUID) {
        val company =
                companyRepository.findById(companyId).orElseThrow {
                    BusinessException(ErrorCode.COMPANY_NOT_FOUND)
                }
        val user =
                userRepository.findById(userId).orElseThrow {
                    BusinessException(ErrorCode.USER_NOT_FOUND)
                }

        val defaultAccounts = getDefaultAccountCodes()

        defaultAccounts.forEach { (code, name, type, description) ->
            if (!accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, code)) {
                val accountCode =
                        AccountCode(
                                company = company,
                                accountCode = code,
                                accountName = name,
                                accountType = type,
                                description = description,
                                isSystemAccount = true,
                                createdBy = user
                        )
                accountCodeRepository.save(accountCode)
            }
        }
    }

    // Private helper methods

    private fun findAccountCodeByIdAndCompany(accountId: Long, companyId: UUID): AccountCode {
        val accountCode =
                accountCodeRepository.findById(accountId).orElseThrow {
                    BusinessException(ErrorCode.ACCOUNT_CODE_NOT_FOUND)
                }

        if (accountCode.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCOUNT_CODE_NOT_FOUND)
        }

        return accountCode
    }

    private fun convertToDto(accountCode: AccountCode): AccountCodeDto {
        return AccountCodeDto(
                id = accountCode.id,
                companyId = accountCode.company.companyId,
                accountCode = accountCode.accountCode,
                accountName = accountCode.accountName,
                accountType = accountCode.accountType,
                parentAccountId = accountCode.parentAccount?.id,
                parentAccountName = accountCode.parentAccount?.accountName,
                accountLevel = accountCode.accountLevel,
                isActive = accountCode.isActive,
                isSystemAccount = accountCode.isSystemAccount,
                description = accountCode.description,
                currentBalance = accountCode.calculateBalance(),
                debitBalance = accountCode.calculateDebitBalance(),
                creditBalance = accountCode.calculateCreditBalance(),
                fullPath = accountCode.getFullPath(),
                childAccountCount = accountCode.childAccounts.size,
                createdAt = accountCode.createdAt,
                updatedAt = accountCode.updatedAt,
                createdBy = accountCode.createdBy?.userId,
                updatedBy = accountCode.updatedBy?.userId
        )
    }

    private fun buildHierarchy(accountCode: AccountCode): AccountCodeHierarchyDto {
        val children =
                accountCodeRepository.findByParentAccountIdAndIsActiveTrue(accountCode.id).map {
                    buildHierarchy(it)
                }

        return AccountCodeHierarchyDto(account = convertToDto(accountCode), children = children)
    }

    private fun isValidAccountCode(accountCode: String): Boolean {
        return accountCode.matches(Regex("^[0-9]{4}$"))
    }

    private fun isCircularReference(accountCode: AccountCode, newParent: AccountCode): Boolean {
        var current: AccountCode? = newParent
        while (current != null) {
            if (current.id == accountCode.id) {
                return true
            }
            current = current.parentAccount
        }
        return false
    }

    private fun getAccountTypePrefix(accountType: AccountType): String {
        return when (accountType) {
            AccountType.ASSET -> "1"
            AccountType.LIABILITY -> "2"
            AccountType.EQUITY -> "3"
            AccountType.REVENUE -> "4"
            AccountType.EXPENSE -> "5"
        }
    }

    private fun getDefaultAccountCodes(): List<Tuple4<String, String, AccountType, String>> {
        return listOf(
                // 자산 계정
                Tuple4("1100", "현금", AccountType.ASSET, "현금 및 현금성 자산"),
                Tuple4("1200", "예금", AccountType.ASSET, "은행 예금"),
                Tuple4("1300", "미수금", AccountType.ASSET, "임대료 및 관리비 미수금"),
                Tuple4("1400", "보증금", AccountType.ASSET, "임차인으로부터 받은 보증금"),
                Tuple4("1500", "건물", AccountType.ASSET, "건물 자산"),
                Tuple4("1600", "감가상각누계액", AccountType.ASSET, "건물 감가상각 누계액"),

                // 부채 계정
                Tuple4("2100", "미지급금", AccountType.LIABILITY, "각종 미지급 비용"),
                Tuple4("2200", "예수보증금", AccountType.LIABILITY, "임차인에게 받은 보증금"),
                Tuple4("2300", "미지급세금", AccountType.LIABILITY, "미지급 세금"),

                // 자본 계정
                Tuple4("3100", "자본금", AccountType.EQUITY, "소유자 자본금"),
                Tuple4("3200", "이익잉여금", AccountType.EQUITY, "누적 이익잉여금"),

                // 수익 계정
                Tuple4("4100", "임대료수익", AccountType.REVENUE, "임대료 수익"),
                Tuple4("4200", "관리비수익", AccountType.REVENUE, "관리비 수익"),
                Tuple4("4300", "기타수익", AccountType.REVENUE, "기타 수익"),

                // 비용 계정
                Tuple4("5100", "관리비", AccountType.EXPENSE, "건물 관리비용"),
                Tuple4("5200", "수선비", AccountType.EXPENSE, "건물 수선 및 유지비"),
                Tuple4("5300", "세금과공과", AccountType.EXPENSE, "세금 및 공과금"),
                Tuple4("5400", "감가상각비", AccountType.EXPENSE, "건물 감가상각비"),
                Tuple4("5500", "기타비용", AccountType.EXPENSE, "기타 운영비용")
        )
    }

    private data class Tuple4<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)
}
