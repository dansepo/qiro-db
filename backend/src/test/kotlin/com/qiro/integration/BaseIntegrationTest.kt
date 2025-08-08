package com.qiro.integration

import io.kotest.core.spec.style.BehaviorSpec
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.context.TestPropertySource
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 통합 테스트 베이스 클래스
 * 모든 통합 테스트가 상속받아 사용하는 공통 설정
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("integration")
@TestPropertySource(locations = ["classpath:application-integration.yml"])
@Transactional
abstract class BaseIntegrationTest : BehaviorSpec() {

    companion object {
        /**
         * 테스트용 회사 ID 생성
         */
        fun generateTestCompanyId(): UUID = UUID.randomUUID()

        /**
         * 테스트용 사용자 ID 생성
         */
        fun generateTestUserId(): UUID = UUID.randomUUID()

        /**
         * 테스트용 시설물 ID 생성
         */
        fun generateTestAssetId(): UUID = UUID.randomUUID()

        /**
         * 테스트용 작업 지시서 ID 생성
         */
        fun generateTestWorkOrderId(): UUID = UUID.randomUUID()

        /**
         * 테스트용 고장 신고 ID 생성
         */
        fun generateTestFaultReportId(): UUID = UUID.randomUUID()

        /**
         * 테스트 실행 시간 측정
         */
        inline fun <T> measureExecutionTime(block: () -> T): Pair<T, Long> {
            val startTime = System.currentTimeMillis()
            val result = block()
            val executionTime = System.currentTimeMillis() - startTime
            return Pair(result, executionTime)
        }

        /**
         * 테스트 성공률 계산
         */
        fun calculateSuccessRate(totalTests: Int, passedTests: Int): Double {
            return if (totalTests > 0) {
                (passedTests.toDouble() / totalTests) * 100.0
            } else 0.0
        }

        /**
         * 테스트 결과 검증 헬퍼
         */
        fun validateTestResult(
            testResult: String,
            executionTimeMs: Long,
            maxExecutionTimeMs: Long = 5000L
        ): Boolean {
            return testResult in listOf("PASS", "WARN") && executionTimeMs <= maxExecutionTimeMs
        }

        /**
         * 테스트 데이터 생성 헬퍼
         */
        fun createTestCompanyData(): TestCompanyData {
            return TestCompanyData(
                companyId = generateTestCompanyId(),
                companyName = "테스트 회사 ${System.currentTimeMillis()}",
                businessRegistrationNumber = generateValidBusinessNumber(),
                adminUserId = generateTestUserId()
            )
        }

        /**
         * 유효한 사업자등록번호 생성
         */
        private fun generateValidBusinessNumber(): String {
            // 간단한 유효한 사업자등록번호 생성 로직
            val digits = mutableListOf<Int>()
            repeat(9) { digits.add((0..9).random()) }
            
            val weights = listOf(1, 3, 7, 1, 3, 7, 1, 3, 5)
            val sum = digits.zip(weights).sumOf { (digit, weight) -> digit * weight }
            val checkDigit = (10 - (sum % 10)) % 10
            
            return digits.joinToString("") + checkDigit
        }

        /**
         * 테스트용 시설물 데이터 생성
         */
        fun createTestAssetData(companyId: UUID): TestAssetData {
            return TestAssetData(
                assetId = generateTestAssetId(),
                companyId = companyId,
                assetName = "테스트 시설물 ${System.currentTimeMillis()}",
                assetType = "ELEVATOR",
                location = "1층 로비",
                status = "ACTIVE"
            )
        }

        /**
         * 테스트용 고장 신고 데이터 생성
         */
        fun createTestFaultReportData(companyId: UUID, assetId: UUID): TestFaultReportData {
            return TestFaultReportData(
                faultReportId = generateTestFaultReportId(),
                companyId = companyId,
                assetId = assetId,
                reporterId = generateTestUserId(),
                title = "테스트 고장 신고",
                description = "테스트용 고장 신고입니다",
                priority = "MEDIUM",
                status = "REPORTED"
            )
        }

        /**
         * 테스트용 작업 지시서 데이터 생성
         */
        fun createTestWorkOrderData(companyId: UUID, faultReportId: UUID): TestWorkOrderData {
            return TestWorkOrderData(
                workOrderId = generateTestWorkOrderId(),
                companyId = companyId,
                faultReportId = faultReportId,
                title = "테스트 작업 지시서",
                description = "테스트용 작업 지시서입니다",
                workType = "REPAIR",
                priority = "MEDIUM",
                status = "CREATED",
                assignedTo = generateTestUserId()
            )
        }

        /**
         * 테스트 결과 로깅
         */
        fun logTestResult(
            testName: String,
            result: String,
            executionTime: Long,
            notes: String? = null
        ) {
            println("=== 테스트 결과 ===")
            println("테스트명: $testName")
            println("결과: $result")
            println("실행시간: ${executionTime}ms")
            if (notes != null) {
                println("비고: $notes")
            }
            println("==================")
        }

        /**
         * 테스트 환경 정보 출력
         */
        fun printTestEnvironmentInfo() {
            println("=== 테스트 환경 정보 ===")
            println("Java Version: ${System.getProperty("java.version")}")
            println("Spring Profile: integration")
            println("Database: H2 (In-Memory)")
            println("Test Mode: Enabled")
            println("========================")
        }
    }

    /**
     * 테스트 회사 데이터 클래스
     */
    data class TestCompanyData(
        val companyId: UUID,
        val companyName: String,
        val businessRegistrationNumber: String,
        val adminUserId: UUID
    )

    /**
     * 테스트 시설물 데이터 클래스
     */
    data class TestAssetData(
        val assetId: UUID,
        val companyId: UUID,
        val assetName: String,
        val assetType: String,
        val location: String,
        val status: String
    )

    /**
     * 테스트 고장 신고 데이터 클래스
     */
    data class TestFaultReportData(
        val faultReportId: UUID,
        val companyId: UUID,
        val assetId: UUID,
        val reporterId: UUID,
        val title: String,
        val description: String,
        val priority: String,
        val status: String
    )

    /**
     * 테스트 작업 지시서 데이터 클래스
     */
    data class TestWorkOrderData(
        val workOrderId: UUID,
        val companyId: UUID,
        val faultReportId: UUID,
        val title: String,
        val description: String,
        val workType: String,
        val priority: String,
        val status: String,
        val assignedTo: UUID
    )
}