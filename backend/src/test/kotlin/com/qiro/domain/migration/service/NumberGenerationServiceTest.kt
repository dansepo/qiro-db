package com.qiro.domain.migration.service

import com.qiro.domain.migration.exception.ProcedureMigrationException
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldMatch
import io.kotest.matchers.collections.shouldHaveSize
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.jdbc.core.JdbcTemplate
import java.util.*

/**
 * NumberGenerationService 단위 테스트
 */
class NumberGenerationServiceTest : BehaviorSpec({

    val jdbcTemplate = mockk<JdbcTemplate>()
    val numberGenerationService = NumberGenerationService(jdbcTemplate)

    given("NumberGenerationService") {
        
        beforeEach {
            // 기본 시퀀스 조회 설정
            every { 
                jdbcTemplate.queryForObject(
                    "SELECT current_value FROM bms.number_sequences WHERE sequence_key = ?",
                    Long::class.java,
                    any<String>()
                )
            } returns null
            
            every { 
                jdbcTemplate.update(
                    "UPDATE bms.number_sequences SET current_value = ?, updated_at = NOW() WHERE sequence_key = ?",
                    any<Long>(),
                    any<String>()
                )
            } returns 0
            
            every { 
                jdbcTemplate.update(
                    """
                    INSERT INTO bms.number_sequences (sequence_key, current_value, created_at, updated_at) 
                    VALUES (?, ?, NOW(), NOW())
                    """.trimIndent(),
                    any<String>(),
                    any<Long>()
                )
            } returns 1
        }

        `when`("generateAccountingNumber를 호출할 때") {
            then("유효한 파라미터로 호출하면 올바른 형식의 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val accountType = "INCOME"

                // When
                val result = numberGenerationService.generateAccountingNumber(companyId, accountType)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("INC-\\d{6}-\\d{6}")
                result.message shouldContain "회계 번호가 성공적으로 생성되었습니다"
            }

            then("다른 회계 유형으로 호출하면 해당 접두사를 사용해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val accountType = "EXPENSE"

                // When
                val result = numberGenerationService.generateAccountingNumber(companyId, accountType)

                // Then
                result.success shouldBe true
                result.data!! shouldMatch Regex("EXP-\\d{6}-\\d{6}")
            }

            then("데이터베이스 오류 발생 시 예외를 던져야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val accountType = "INCOME"
                
                every { 
                    jdbcTemplate.update(any<String>(), any<String>(), any<Long>())
                } throws RuntimeException("Database error")

                // When & Then
                shouldThrow<ProcedureMigrationException.DataIntegrityException> {
                    numberGenerationService.generateAccountingNumber(companyId, accountType)
                }
            }
        }

        `when`("generateNoticeNumber를 호출할 때") {
            then("유효한 파라미터로 호출하면 올바른 형식의 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val noticeType = "URGENT"

                // When
                val result = numberGenerationService.generateNoticeNumber(companyId, noticeType)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("URG-\\d{6}-\\d{4}")
            }
        }

        `when`("generateWorkOrderNumber를 호출할 때") {
            then("유효한 파라미터로 호출하면 올바른 형식의 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val workType = "MAINTENANCE"

                // When
                val result = numberGenerationService.generateWorkOrderNumber(companyId, workType)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("MNT-\\d{6}-\\d{5}")
            }
        }

        `when`("generateFaultReportNumber를 호출할 때") {
            then("우선순위에 따라 올바른 접두사를 사용해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val priority = "HIGH"

                // When
                val result = numberGenerationService.generateFaultReportNumber(companyId, priority)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("FH-\\d{8}-\\d{4}")
            }
        }

        `when`("generateUserId를 호출할 때") {
            then("사용자 유형에 따라 올바른 접두사를 사용해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val userType = "ADMIN"

                // When
                val result = numberGenerationService.generateUserId(companyId, userType)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("ADM[A-Z0-9]{4}\\d{4}")
            }
        }

        `when`("generateUnitNumber를 호출할 때") {
            then("층수와 시퀀스에 따라 올바른 형식의 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val buildingId = UUID.randomUUID()
                val floor = 3

                // When
                val result = numberGenerationService.generateUnitNumber(companyId, buildingId, floor)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldMatch Regex("03\\d{2}")
            }
        }

        `when`("generateBatchNumbers를 호출할 때") {
            then("유효한 개수로 호출하면 해당 개수만큼 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val numberType = "WORK_ORDER"
                val count = 5
                val additionalParams = mapOf("workType" to "MAINTENANCE")

                // When
                val result = numberGenerationService.generateBatchNumbers(companyId, numberType, count, additionalParams)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldHaveSize count
                result.data!!.forEach { number ->
                    number shouldMatch Regex("MNT-\\d{6}-\\d{5}")
                }
            }

            then("0 이하의 개수로 호출하면 실패해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val numberType = "WORK_ORDER"
                val count = 0

                // When
                val result = numberGenerationService.generateBatchNumbers(companyId, numberType, count)

                // Then
                result.success shouldBe false
                result.message shouldContain "생성할 번호 개수는 1~1000 사이여야 합니다"
            }

            then("1000 초과의 개수로 호출하면 실패해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val numberType = "WORK_ORDER"
                val count = 1001

                // When
                val result = numberGenerationService.generateBatchNumbers(companyId, numberType, count)

                // Then
                result.success shouldBe false
                result.message shouldContain "생성할 번호 개수는 1~1000 사이여야 합니다"
            }

            then("지원하지 않는 번호 유형으로 호출하면 빈 목록을 반환해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val numberType = "INVALID_TYPE"
                val count = 3

                // When
                val result = numberGenerationService.generateBatchNumbers(companyId, numberType, count)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data!! shouldHaveSize 0
            }
        }

        `when`("resetSequence를 호출할 때") {
            then("유효한 시퀀스 키로 호출하면 성공해야 한다") {
                // Given
                val sequenceKey = "test_sequence_key"
                
                every { 
                    jdbcTemplate.update(
                        "DELETE FROM bms.number_sequences WHERE sequence_key = ?",
                        sequenceKey
                    )
                } returns 1

                // When
                val result = numberGenerationService.resetSequence(sequenceKey)

                // Then
                result.success shouldBe true
                result.data shouldBe true
                result.message shouldContain "시퀀스가 성공적으로 초기화되었습니다"
                
                verify { 
                    jdbcTemplate.update(
                        "DELETE FROM bms.number_sequences WHERE sequence_key = ?",
                        sequenceKey
                    )
                }
            }

            then("데이터베이스 오류 발생 시 예외를 던져야 한다") {
                // Given
                val sequenceKey = "test_sequence_key"
                
                every { 
                    jdbcTemplate.update(
                        "DELETE FROM bms.number_sequences WHERE sequence_key = ?",
                        sequenceKey
                    )
                } throws RuntimeException("Database error")

                // When & Then
                shouldThrow<ProcedureMigrationException.DataIntegrityException> {
                    numberGenerationService.resetSequence(sequenceKey)
                }
            }
        }

        `when`("동일한 시퀀스 키로 여러 번 호출할 때") {
            then("순차적으로 증가하는 번호를 생성해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                val accountType = "INCOME"
                
                // 첫 번째 호출에서는 시퀀스가 없으므로 1부터 시작
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT current_value FROM bms.number_sequences WHERE sequence_key = ?",
                        Long::class.java,
                        any<String>()
                    )
                } returns null andThen 1L andThen 2L

                // When
                val result1 = numberGenerationService.generateAccountingNumber(companyId, accountType)
                val result2 = numberGenerationService.generateAccountingNumber(companyId, accountType)
                val result3 = numberGenerationService.generateAccountingNumber(companyId, accountType)

                // Then
                result1.success shouldBe true
                result2.success shouldBe true
                result3.success shouldBe true
                
                // 각 번호는 달라야 함 (시퀀스가 증가)
                result1.data shouldNotBe result2.data
                result2.data shouldNotBe result3.data
                result1.data shouldNotBe result3.data
            }
        }
    }
})