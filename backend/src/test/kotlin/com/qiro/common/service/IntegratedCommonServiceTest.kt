package com.qiro.common.service

import com.qiro.common.dto.*
import com.qiro.domain.validation.service.DataIntegrityService
import com.qiro.domain.performance.service.PerformanceMonitoringService
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import java.time.LocalDateTime
import java.util.*

/**
 * 통합 공통 서비스 테스트
 */
class IntegratedCommonServiceTest : BehaviorSpec({

    val dataIntegrityService = mockk<DataIntegrityService>()
    val performanceMonitoringService = mockk<PerformanceMonitoringService>()
    val testExecutionService = mockk<TestExecutionService>()
    
    val integratedCommonService = IntegratedCommonService(
        dataIntegrityService,
        performanceMonitoringService,
        testExecutionService
    )

    given("통합 시스템 상태 조회") {
        val companyId = UUID.randomUUID()
        
        `when`("시스템 상태를 조회할 때") {
            // Mock 설정
            every { 
                dataIntegrityService.checkIntegrity(any(), companyId, any()) 
            } returns mockDataIntegrityResult()
            
            every { 
                performanceMonitoringService.getSystemHealth(companyId) 
            } returns mockSystemHealth()

            val result = integratedCommonService.getIntegratedSystemStatus(companyId)

            then("통합 시스템 상태가 반환되어야 한다") {
                result.companyId shouldBe companyId
                result.overallStatus shouldNotBe null
                result.dataIntegrityStatus shouldNotBe null
                result.performanceStatus shouldNotBe null
                result.recommendations.shouldNotBeEmpty()
            }
        }
    }

    given("통합 최적화 실행") {
        val companyId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val options = OptimizationOptionsDto(
            includeDataIntegrity = true,
            includePerformanceOptimization = true,
            includeCacheOptimization = true,
            includeDatabaseOptimization = true
        )

        `when`("통합 최적화를 실행할 때") {
            // Mock 설정
            every { 
                dataIntegrityService.checkIntegrity(any(), companyId, userId) 
            } returns mockDataIntegrityResult()
            
            every { 
                performanceMonitoringService.generateOptimizationSuggestions(companyId) 
            } returns emptyList()
            
            every { 
                performanceMonitoringService.updateCacheStatistics(any(), any(), any(), any(), any(), any(), any(), companyId) 
            } returns mockCacheStatistics()
            
            every { 
                performanceMonitoringService.recordSlowQuery(any(), any(), companyId) 
            } returns mockSlowQuery()

            val result = integratedCommonService.performIntegratedOptimization(
                companyId, userId, options
            )

            then("최적화 결과가 반환되어야 한다") {
                result.companyId shouldBe companyId
                result.optimizationId shouldNotBe null
                result.results.shouldNotBeEmpty()
                result.totalDurationMs shouldBeGreaterThan 0.0
                result.recommendations.shouldNotBeEmpty()
            }
        }
    }

    given("통합 테스트 실행") {
        val companyId = UUID.randomUUID()
        val testOptions = IntegratedTestOptionsDto(
            includeIntegrationTests = true,
            includeDataIntegrityTests = true,
            includePerformanceTests = true,
            includeSecurityTests = true
        )

        `when`("통합 테스트를 실행할 때") {
            // Mock 설정
            val mockTestResults = listOf(
                TestExecutionService.TestResult(
                    testCategory = "통합",
                    testName = "기본 통합 테스트",
                    testResult = "PASS",
                    executionTimeMs = 100L
                ),
                TestExecutionService.TestResult(
                    testCategory = "데이터 무결성",
                    testName = "회사 데이터 무결성 검사",
                    testResult = "PASS",
                    executionTimeMs = 150L
                )
            )
            
            val mockSummary = listOf(
                TestExecutionService.TestSummary(
                    category = "통합",
                    totalTests = 1,
                    passedTests = 1,
                    failedTests = 0,
                    warningTests = 0,
                    errorTests = 0,
                    successRate = 100.0,
                    avgExecutionTimeMs = 100.0
                )
            )
            
            every { 
                testExecutionService.runIntegrationTests(companyId) 
            } returns mockTestResults
            
            every { 
                testExecutionService.summarizeTestResults(any()) 
            } returns mockSummary
            
            every { 
                testExecutionService.getFailedTestsDetail(any()) 
            } returns emptyList()
            
            every { 
                performanceMonitoringService.getSystemHealth(companyId) 
            } returns mockSystemHealth()

            val result = integratedCommonService.runIntegratedTests(companyId, testOptions)

            then("테스트 결과가 반환되어야 한다") {
                result.companyId shouldBe companyId
                result.testSessionId shouldNotBe null
                result.totalTests shouldBeGreaterThan 0
                result.overallSuccessRate shouldBeGreaterThan 0.0
                result.testResults.shouldNotBeEmpty()
                result.summary.shouldNotBeEmpty()
            }
        }
    }

    given("서비스 의존성 최적화") {
        val companyId = UUID.randomUUID()

        `when`("서비스 의존성을 최적화할 때") {
            val result = integratedCommonService.optimizeServiceDependencies(companyId)

            then("의존성 최적화 결과가 반환되어야 한다") {
                result.companyId shouldBe companyId
                result.optimizationId shouldNotBe null
                result.optimizationSteps.shouldNotBeEmpty()
                result.totalDurationMs shouldBeGreaterThan 0.0
                result.recommendations.shouldNotBeEmpty()
            }
        }
    }

    given("프로시저 이관 상태 확인") {
        `when`("프로시저 이관 상태를 확인할 때") {
            val result = integratedCommonService.checkProcedureMigrationStatus()

            then("이관 상태가 반환되어야 한다") {
                result.totalProcedures shouldBeGreaterThan 0
                result.migrationChecks.shouldNotBeEmpty()
                result.migrationProgress shouldBeGreaterThan 0.0
                result.lastChecked shouldNotBe null
            }
        }
    }

    given("데이터 무결성 서비스 통합") {
        val companyId = UUID.randomUUID()

        `when`("데이터 무결성 검사를 실행할 때") {
            every { 
                dataIntegrityService.validateBusinessRegistrationNumber("1234567890") 
            } returns true
            
            every { 
                dataIntegrityService.validateBusinessRegistrationNumber("1111111111") 
            } returns false

            val validResult = dataIntegrityService.validateBusinessRegistrationNumber("1234567890")
            val invalidResult = dataIntegrityService.validateBusinessRegistrationNumber("1111111111")

            then("사업자등록번호 검증이 정상 동작해야 한다") {
                validResult shouldBe true
                invalidResult shouldBe false
                
                verify { dataIntegrityService.validateBusinessRegistrationNumber("1234567890") }
                verify { dataIntegrityService.validateBusinessRegistrationNumber("1111111111") }
            }
        }
    }

    given("성능 모니터링 서비스 통합") {
        val companyId = UUID.randomUUID()

        `when`("성능 테스트를 실행할 때") {
            every { 
                performanceMonitoringService.testDatabaseConnectionPerformance() 
            } returns PerformanceMonitoringService.TestResultDto(
                status = "PASS",
                duration = 50L,
                message = "데이터베이스 연결 성능: 50ms"
            )

            val result = performanceMonitoringService.testDatabaseConnectionPerformance()

            then("성능 테스트가 정상 동작해야 한다") {
                result.status shouldBe "PASS"
                result.duration shouldBeGreaterThan 0L
                result.message shouldNotBe null
                
                verify { performanceMonitoringService.testDatabaseConnectionPerformance() }
            }
        }
    }

    given("테스트 실행 서비스 통합") {
        val companyId = UUID.randomUUID()

        `when`("통합 테스트를 실행할 때") {
            val mockResults = listOf(
                TestExecutionService.TestResult(
                    testCategory = "데이터 구조",
                    testName = "회사 데이터 존재 확인",
                    testResult = "PASS",
                    executionTimeMs = 100L
                )
            )
            
            every { 
                testExecutionService.runIntegrationTests(companyId) 
            } returns mockResults

            val result = testExecutionService.runIntegrationTests(companyId)

            then("테스트 실행이 정상 동작해야 한다") {
                result.shouldNotBeEmpty()
                result.first().testCategory shouldBe "데이터 구조"
                result.first().testResult shouldBe "PASS"
                
                verify { testExecutionService.runIntegrationTests(companyId) }
            }
        }
    }
}) {
    companion object {
        private fun mockDataIntegrityResult() = com.qiro.domain.validation.dto.DataIntegrityCheckResultDto(
            checkId = UUID.randomUUID(),
            checkName = "테스트 무결성 검사",
            entityType = "COMPANY",
            totalRecords = 100L,
            validRecords = 95L,
            invalidRecords = 5L,
            issues = emptyList(),
            duration = 1000L
        )
        
        private fun mockSystemHealth() = com.qiro.domain.performance.dto.SystemHealthDto(
            status = com.qiro.domain.performance.dto.SystemStatus.HEALTHY,
            uptime = 86400L,
            version = "1.0.0",
            environment = "test",
            metrics = emptyList(),
            checkedAt = LocalDateTime.now()
        )
        
        private fun mockCacheStatistics() = com.qiro.domain.performance.dto.CacheStatisticsDto(
            cacheName = "testCache",
            hitCount = 1000L,
            missCount = 100L,
            hitRate = 0.9,
            evictionCount = 10L,
            size = 500L,
            maxSize = 1000L,
            averageLoadTime = 50.0,
            lastUpdated = LocalDateTime.now()
        )
        
        private fun mockSlowQuery() = com.qiro.domain.performance.dto.SlowQueryDto(
            queryId = UUID.randomUUID(),
            query = "SELECT * FROM test_table",
            executionTime = 1500.0,
            executionCount = 1L,
            averageTime = 1500.0,
            lastExecuted = LocalDateTime.now()
        )
    }
}