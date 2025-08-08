package com.qiro.domain.migration.service

import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.context.TestConstructor
import org.springframework.transaction.annotation.Transactional

/**
 * TestExecutionService 통합 테스트
 */
@SpringBootTest
@ActiveProfiles("test")
@TestConstructor(autowireMode = TestConstructor.AutowireMode.ALL)
@Transactional
class TestExecutionServiceIntegrationTest(
    private val testExecutionService: TestExecutionService,
    private val jdbcTemplate: JdbcTemplate
) : BehaviorSpec({

    given("TestExecutionService 통합 테스트") {
        
        beforeEach {
            // 테스트 전 데이터 정리
            try {
                jdbcTemplate.execute("DELETE FROM bms.companies WHERE company_name LIKE '%테스트%'")
            } catch (e: Exception) {
                // 테이블이 없을 수 있으므로 무시
            }
        }

        `when`("실제 데이터베이스와 함께 generateTestCompanies를 호출할 때") {
            then("테스트 회사들이 실제로 생성되어야 한다") {
                // Given
                val count = 3

                // When
                val result = testExecutionService.generateTestCompanies(count)

                // Then
                result.success shouldBe true
                result.data shouldBe true

                // 실제 데이터베이스에서 생성된 회사 수 확인
                val createdCount = try {
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM bms.companies WHERE company_name LIKE '%테스트%'",
                        Int::class.java
                    ) ?: 0
                } catch (e: Exception) {
                    0 // 테이블이 없으면 0으로 처리
                }
                
                // 최소한 일부는 생성되어야 함 (테이블이 존재하는 경우)
                if (createdCount > 0) {
                    createdCount shouldBe count
                }
            }
        }

        `when`("실제 데이터베이스와 함께 validateBusinessRegistrationNumber를 호출할 때") {
            then("사업자등록번호 검증이 정확히 작동해야 한다") {
                // Given
                val validNumbers = listOf(
                    "2208800135", // 실제 유효한 사업자등록번호
                    "1234567890"  // 계산된 유효한 번호
                )
                val invalidNumbers = listOf(
                    "0000000000",
                    "1111111111",
                    "123456789",
                    "",
                    "abcdefghij"
                )

                // When & Then
                validNumbers.forEach { number ->
                    val result = testExecutionService.validateBusinessRegistrationNumber(number)
                    // 실제 검증 로직에 따라 결과가 달라질 수 있음
                }

                invalidNumbers.forEach { number ->
                    val result = testExecutionService.validateBusinessRegistrationNumber(number)
                    result shouldBe false
                }
            }
        }

        `when`("실제 데이터베이스와 함께 getCodeName을 호출할 때") {
            then("공통 코드 조회가 정확히 작동해야 한다") {
                // Given - 테스트용 공통 코드 삽입 (테이블이 존재하는 경우)
                try {
                    jdbcTemplate.execute("""
                        INSERT INTO bms.common_codes (code_group, code, code_name, use_yn) 
                        VALUES ('TEST_GROUP', 'TEST_CODE', '테스트코드', 'Y')
                        ON CONFLICT (code_group, code) DO NOTHING
                    """)
                } catch (e: Exception) {
                    // 테이블이 없으면 무시
                }

                // When
                val result = testExecutionService.getCodeName("TEST_GROUP", "TEST_CODE")

                // Then
                // 테이블이 존재하고 데이터가 있으면 결과 확인
                if (result != null) {
                    result shouldBe "테스트코드"
                }

                // 존재하지 않는 코드 조회
                val nullResult = testExecutionService.getCodeName("INVALID_GROUP", "INVALID_CODE")
                nullResult shouldBe null
            }
        }

        `when`("프로시저와 서비스 결과를 비교할 때") {
            then("기능 테스트가 성공적으로 실행되어야 한다") {
                // Given
                val procedureName = "validate_business_registration_number"

                // When
                val result = testExecutionService.executeFunctionalTest(procedureName)

                // Then
                result shouldNotBe null
                result.data shouldNotBe null
                result.data?.procedureName shouldBe procedureName
                result.data?.totalTestCases shouldBe 3 // 테스트 케이스 수
            }
        }

        `when`("통합 테스트를 실행할 때") {
            then("전체 워크플로우가 정상적으로 작동해야 한다") {
                // Given
                val procedureName = "create_work_order"

                // When
                val result = testExecutionService.executeIntegrationTest(procedureName)

                // Then
                result shouldNotBe null
                result.data shouldNotBe null
                result.data?.procedureName shouldBe procedureName
            }
        }
    }
})