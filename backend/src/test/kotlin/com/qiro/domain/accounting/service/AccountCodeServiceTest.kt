package com.qiro.domain.accounting.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.domain.accounting.dto.CreateAccountCodeRequest
import com.qiro.domain.accounting.dto.UpdateAccountCodeRequest
import com.qiro.domain.accounting.entity.AccountCode
import com.qiro.domain.accounting.entity.AccountType
import com.qiro.domain.accounting.repository.AccountCodeRepository
import com.qiro.domain.company.entity.Company
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.user.entity.User
import com.qiro.domain.user.repository.UserRepository
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.LocalDateTime
import java.util.*

/**
 * 계정과목 서비스 테스트
 */
class AccountCodeServiceTest : BehaviorSpec({

    val accountCodeRepository = mockk<AccountCodeRepository>()
    val companyRepository = mockk<CompanyRepository>()
    val userRepository = mockk<UserRepository>()
    val accountCodeService = AccountCodeService(accountCodeRepository, companyRepository, userRepository)

    val companyId = UUID.randomUUID()
    val userId = UUID.randomUUID()
    val accountId = 1L

    val mockCompany = mockk<Company> {
        every { companyId } returns this@AccountCodeServiceTest.companyId
    }

    val mockUser = mockk<User> {
        every { userId } returns this@AccountCodeServiceTest.userId
    }

    val mockAccountCode = AccountCode(
        id = accountId,
        company = mockCompany,
        accountCode = "1100",
        accountName = "현금",
        accountType = AccountType.ASSET,
        description = "현금 및 현금성 자산",
        createdBy = mockUser
    ).apply {
        createdAt = LocalDateTime.now()
        updatedAt = LocalDateTime.now()
    }

    given("계정과목 생성 시") {
        `when`("유효한 요청으로 계정과목을 생성하면") {
            val request = CreateAccountCodeRequest(
                accountCode = "1100",
                accountName = "현금",
                accountType = AccountType.ASSET,
                description = "현금 및 현금성 자산"
            )

            every { companyRepository.findById(companyId) } returns Optional.of(mockCompany)
            every { userRepository.findById(userId) } returns Optional.of(mockUser)
            every { accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, "1100") } returns false
            every { accountCodeRepository.save(any<AccountCode>()) } returns mockAccountCode

            then("계정과목이 성공적으로 생성된다") {
                val result = accountCodeService.createAccountCode(companyId, request, userId)

                result.accountCode shouldBe "1100"
                result.accountName shouldBe "현금"
                result.accountType shouldBe AccountType.ASSET
                result.description shouldBe "현금 및 현금성 자산"

                verify { accountCodeRepository.save(any<AccountCode>()) }
            }
        }

        `when`("중복된 계정과목 코드로 생성하면") {
            val request = CreateAccountCodeRequest(
                accountCode = "1100",
                accountName = "현금",
                accountType = AccountType.ASSET
            )

            every { companyRepository.findById(companyId) } returns Optional.of(mockCompany)
            every { userRepository.findById(userId) } returns Optional.of(mockUser)
            every { accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, "1100") } returns true

            then("중복 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.createAccountCode(companyId, request, userId)
                }
                exception.errorCode shouldBe ErrorCode.DUPLICATE_ACCOUNT_CODE
            }
        }

        `when`("잘못된 계정과목 코드 형식으로 생성하면") {
            val request = CreateAccountCodeRequest(
                accountCode = "INVALID",
                accountName = "현금",
                accountType = AccountType.ASSET
            )

            every { companyRepository.findById(companyId) } returns Optional.of(mockCompany)
            every { userRepository.findById(userId) } returns Optional.of(mockUser)
            every { accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, "INVALID") } returns false

            then("유효성 검증 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.createAccountCode(companyId, request, userId)
                }
                exception.errorCode shouldBe ErrorCode.INVALID_ACCOUNT_CODE
            }
        }

        `when`("존재하지 않는 회사로 생성하면") {
            val request = CreateAccountCodeRequest(
                accountCode = "1100",
                accountName = "현금",
                accountType = AccountType.ASSET
            )

            every { companyRepository.findById(companyId) } returns Optional.empty()

            then("회사 없음 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.createAccountCode(companyId, request, userId)
                }
                exception.errorCode shouldBe ErrorCode.COMPANY_NOT_FOUND
            }
        }
    }

    given("계정과목 수정 시") {
        `when`("유효한 요청으로 계정과목을 수정하면") {
            val request = UpdateAccountCodeRequest(
                accountName = "수정된 현금",
                description = "수정된 설명"
            )

            every { accountCodeRepository.findById(accountId) } returns Optional.of(mockAccountCode)
            every { userRepository.findById(userId) } returns Optional.of(mockUser)
            every { accountCodeRepository.save(any<AccountCode>()) } returns mockAccountCode.apply {
                accountName = "수정된 현금"
                description = "수정된 설명"
            }

            then("계정과목이 성공적으로 수정된다") {
                val result = accountCodeService.updateAccountCode(companyId, accountId, request, userId)

                result.accountName shouldBe "수정된 현금"
                result.description shouldBe "수정된 설명"

                verify { accountCodeRepository.save(any<AccountCode>()) }
            }
        }

        `when`("시스템 계정과목을 수정하려고 하면") {
            val systemAccount = mockAccountCode.apply { isSystemAccount = true }
            val request = UpdateAccountCodeRequest(accountName = "수정된 이름")

            every { accountCodeRepository.findById(accountId) } returns Optional.of(systemAccount)

            then("시스템 계정 수정 불가 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.updateAccountCode(companyId, accountId, request, userId)
                }
                exception.errorCode shouldBe ErrorCode.SYSTEM_ACCOUNT_NOT_MODIFIABLE
            }
        }

        `when`("존재하지 않는 계정과목을 수정하려고 하면") {
            val request = UpdateAccountCodeRequest(accountName = "수정된 이름")

            every { accountCodeRepository.findById(accountId) } returns Optional.empty()

            then("계정과목 없음 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.updateAccountCode(companyId, accountId, request, userId)
                }
                exception.errorCode shouldBe ErrorCode.ACCOUNT_CODE_NOT_FOUND
            }
        }
    }

    given("계정과목 삭제 시") {
        `when`("유효한 계정과목을 삭제하면") {
            every { accountCodeRepository.findById(accountId) } returns Optional.of(mockAccountCode)
            every { accountCodeRepository.existsByParentAccountId(accountId) } returns false
            every { accountCodeRepository.delete(mockAccountCode) } returns Unit

            then("계정과목이 성공적으로 삭제된다") {
                accountCodeService.deleteAccountCode(companyId, accountId)

                verify { accountCodeRepository.delete(mockAccountCode) }
            }
        }

        `when`("시스템 계정과목을 삭제하려고 하면") {
            val systemAccount = mockAccountCode.apply { isSystemAccount = true }

            every { accountCodeRepository.findById(accountId) } returns Optional.of(systemAccount)

            then("시스템 계정 삭제 불가 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.deleteAccountCode(companyId, accountId)
                }
                exception.errorCode shouldBe ErrorCode.SYSTEM_ACCOUNT_NOT_DELETABLE
            }
        }

        `when`("하위 계정과목이 있는 계정을 삭제하려고 하면") {
            every { accountCodeRepository.findById(accountId) } returns Optional.of(mockAccountCode)
            every { accountCodeRepository.existsByParentAccountId(accountId) } returns true

            then("하위 계정 존재 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.deleteAccountCode(companyId, accountId)
                }
                exception.errorCode shouldBe ErrorCode.ACCOUNT_HAS_CHILD_ACCOUNTS
            }
        }
    }

    given("계정과목 조회 시") {
        `when`("존재하는 계정과목을 조회하면") {
            every { accountCodeRepository.findById(accountId) } returns Optional.of(mockAccountCode)

            then("계정과목 정보가 반환된다") {
                val result = accountCodeService.getAccountCode(companyId, accountId)

                result.id shouldBe accountId
                result.accountCode shouldBe "1100"
                result.accountName shouldBe "현금"
                result.accountType shouldBe AccountType.ASSET
            }
        }

        `when`("존재하지 않는 계정과목을 조회하면") {
            every { accountCodeRepository.findById(accountId) } returns Optional.empty()

            then("계정과목 없음 에러가 발생한다") {
                val exception = shouldThrow<BusinessException> {
                    accountCodeService.getAccountCode(companyId, accountId)
                }
                exception.errorCode shouldBe ErrorCode.ACCOUNT_CODE_NOT_FOUND
            }
        }
    }

    given("계정과목 목록 조회 시") {
        `when`("페이징으로 계정과목 목록을 조회하면") {
            val pageable = PageRequest.of(0, 10)
            val accountCodes = listOf(mockAccountCode)
            val page = PageImpl(accountCodes, pageable, 1)

            every { accountCodeRepository.findByCompanyCompanyId(companyId, pageable) } returns page

            then("페이징된 계정과목 목록이 반환된다") {
                val result = accountCodeService.getAccountCodes(companyId, pageable)

                result.content.size shouldBe 1
                result.content[0].accountCode shouldBe "1100"
                result.totalElements shouldBe 1
            }
        }

        `when`("활성 계정과목만 조회하면") {
            val pageable = PageRequest.of(0, 10)
            val accountCodes = listOf(mockAccountCode)
            val page = PageImpl(accountCodes, pageable, 1)

            every { accountCodeRepository.findByCompanyCompanyIdAndIsActiveTrue(companyId, pageable) } returns page

            then("활성 계정과목 목록이 반환된다") {
                val result = accountCodeService.getActiveAccountCodes(companyId, pageable)

                result.content.size shouldBe 1
                result.content[0].isActive shouldBe true
            }
        }
    }

    given("계정과목 통계 조회 시") {
        `when`("통계를 조회하면") {
            every { accountCodeRepository.countByCompanyCompanyId(companyId) } returns 10L
            every { accountCodeRepository.countByCompanyCompanyIdAndIsActiveTrue(companyId) } returns 8L
            every { accountCodeRepository.getAccountTypeStatistics(companyId) } returns listOf(
                arrayOf(AccountType.ASSET, 5L),
                arrayOf(AccountType.LIABILITY, 3L)
            )
            every { accountCodeRepository.getAccountLevelStatistics(companyId) } returns listOf(
                arrayOf(1, 5L),
                arrayOf(2, 3L)
            )

            then("통계 정보가 반환된다") {
                val result = accountCodeService.getAccountCodeStatistics(companyId)

                result.totalAccounts shouldBe 10L
                result.activeAccounts shouldBe 8L
                result.accountTypeStatistics[AccountType.ASSET] shouldBe 5L
                result.accountLevelStatistics[1] shouldBe 5L
            }
        }
    }

    given("다음 계정과목 코드 생성 시") {
        `when`("자산 계정의 다음 코드를 생성하면") {
            every { accountCodeRepository.findMaxAccountCodeByTypeAndPrefix(companyId, AccountType.ASSET, "1") } returns "1100"

            then("다음 코드가 생성된다") {
                val result = accountCodeService.generateNextAccountCode(companyId, AccountType.ASSET)
                result shouldBe "1101"
            }
        }

        `when`("첫 번째 계정과목 코드를 생성하면") {
            every { accountCodeRepository.findMaxAccountCodeByTypeAndPrefix(companyId, AccountType.ASSET, "1") } returns null

            then("첫 번째 코드가 생성된다") {
                val result = accountCodeService.generateNextAccountCode(companyId, AccountType.ASSET)
                result shouldBe "1001"
            }
        }
    }

    given("기본 계정과목 생성 시") {
        `when`("기본 계정과목을 생성하면") {
            every { companyRepository.findById(companyId) } returns Optional.of(mockCompany)
            every { userRepository.findById(userId) } returns Optional.of(mockUser)
            every { accountCodeRepository.existsByCompanyCompanyIdAndAccountCode(companyId, any()) } returns false
            every { accountCodeRepository.save(any<AccountCode>()) } returns mockAccountCode

            then("기본 계정과목들이 생성된다") {
                accountCodeService.createDefaultAccountCodes(companyId, userId)

                verify(atLeast = 1) { accountCodeRepository.save(any<AccountCode>()) }
            }
        }
    }
})