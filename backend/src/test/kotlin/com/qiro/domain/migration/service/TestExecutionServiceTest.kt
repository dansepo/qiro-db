package com.qiro.domain.migration.service

import com.qiro.domain.migration.exception.ProcedureMigrationException
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.jdbc.core.JdbcTemplate
import java.util.*

/**
 * TestExecutionService 단위 테스트
 */
class TestExecutionServiceTest : BehaviorSpec({

    val jdbcTemplate = mockk<JdbcTemplate>()
    val testExecutionService = TestExecutionService(jdbcTemplate)

    given("TestExecutionService") {
        
        `when`("generateTestCompanies를 호출할 때") {
            then("유효한 개수로 호출하면 성공해야 한다") {
                // Given
                val count = 5
                every { 
                    jdbcTemplate.update(any<String>(), any(), any(), any(), any(), any(), any(), any(), any(), any()) 
                } returns 1

                // When
                val result = testExecutionService.generateTestCompanies(count)

                // Then
                result.success shouldBe true
                result.data shouldBe true
                result.message shouldContain "테스트 회사가 성공적으로 생성되었습니다"
            }

            then("0 이하의 개수로 호출하면 실패해야 한다") {
                // Given
                val count = 0

                // When
                val result = testExecutionService.generateTestCompanies(count)

                // Then
                result.success shouldBe false
                result.message shouldContain "생성할 회사 수는 1 이상이어야 합니다"
            }

            then("데이터베이스 오류 발생 시 예외를 던져야 한다") {
                // Given
                val count = 5
                every { 
                    jdbcTemplate.update(any<String>(), any(), any(), any(), any(), any(), any(), any(), any(), any()) 
                } throws RuntimeException("Database error")

                // When & Then
                shouldThrow<ProcedureMigrationException.DataIntegrityException> {
                    testExecutionService.generateTestCompanies(count)
                }
            }
        }

        `when`("validateBusinessRegistrationNumber를 호출할 때") {
            then("유효한 사업자등록번호는 true를 반환해야 한다") {
                // Given - 유효한 사업자등록번호 생성 (체크 디지트 계산)
                val validNumber = "1234567890" // 실제 유효한 번호로 계산 필요
                
                // When
                val result = testExecutionService.validateBusinessRegistrationNumber("2208800135")

                // Then
                result shouldBe true
            }

            then("무효한 사업자등록번호는 false를 반환해야 한다") {
                // Given
                val invalidNumber = "0000000000"

                // When
                val result = testExecutionService.validateBusinessRegistrationNumber(invalidNumber)

                // Then
                result shouldBe false
            }

            then("빈 문자열은 false를 반환해야 한다") {
                // Given
                val emptyNumber = ""

                // When
                val result = testExecutionService.validateBusinessRegistrationNumber(emptyNumber)

                // Then
                result shouldBe false
            }

            then("길이가 10이 아닌 번호는 false를 반환해야 한다") {
                // Given
                val shortNumber = "123456789"

                // When
                val result = testExecutionService.validateBusinessRegistrationNumber(shortNumber)

                // Then
                result shouldBe false
            }

            then("숫자가 아닌 문자가 포함된 번호는 false를 반환해야 한다") {
                // Given
                val invalidNumber = "12345678ab"

                // When
                val result = testExecutionService.validateBusinessRegistrationNumber(invalidNumber)

                // Then
                result shouldBe false
            }
        }

        `when`("getCodeName을 호출할 때") {
            then("존재하는 코드는 코드명을 반환해야 한다") {
                // Given
                val codeGroup = "BUILDING_TYPE"
                val code = "OFFICE"
                val expectedCodeName = "사무실"
                
                every {
                    jdbcTemplate.queryForObject(
                        "SELECT code_name FROM bms.common_codes WHERE code_group = ? AND code = ? AND use_yn = 'Y'",
                        String::class.java,
                        codeGroup,
                        code
                    )
                } returns expectedCodeName

                // When
                val result = testExecutionService.getCodeName(codeGroup, code)

                // Then
                result shouldBe expectedCodeName
            }

            then("존재하지 않는 코드는 null을 반환해야 한다") {
                // Given
                val codeGroup = "INVALID_GROUP"
                val code = "INVALID_CODE"
                
                every {
                    jdbcTemplate.queryForObject(
                        "SELECT code_name FROM bms.common_codes WHERE code_group = ? AND code = ? AND use_yn = 'Y'",
                        String::class.java,
                        codeGroup,
                        code
                    )
                } throws RuntimeException("No data found")

                // When
                val result = testExecutionService.getCodeName(codeGroup, code)

                // Then
                result shouldBe null
            }
        }

        `when`("executeFunctionalTest를 호출할 때") {
            then("generate_test_companies 프로시저 테스트가 성공해야 한다") {
                // Given
                val procedureName = "generate_test_companies"
                every { 
                    jdbcTemplate.update(any<String>(), any(), any(), any(), any(), any(), any(), any(), any(), any()) 
                } returns 1

                // When
                val result = testExecutionService.executeFunctionalTest(procedureName)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.procedureName shouldBe procedureName
            }

            then("validate_business_registration_number 프로시저 테스트가 성공해야 한다") {
                // Given
                val procedureName = "validate_business_registration_number"
                every {
                    jdbcTemplate.queryForObject(
                        "SELECT validate_business_registration_number(?)",
                        Boolean::class.java,
                        any<String>()
                    )
                } returns true

                // When
                val result = testExecutionService.executeFunctionalTest(procedureName)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.procedureName shouldBe procedureName
            }
        }

        `when`("executeIntegrationTest를 호출할 때") {
            then("통합 테스트가 성공적으로 실행되어야 한다") {
                // Given
                val procedureName = "create_work_order"

                // When
                val result = testExecutionService.executeIntegrationTest(procedureName)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.procedureName shouldBe procedureName
            }
        }
    }
})