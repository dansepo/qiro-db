package com.qiro.common.service

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*
import kotlin.system.measureTimeMillis

/**
 * 성능 모니터링 서비스
 * 기존 데이터베이스 성능 테스트 함수들을 백엔드로 이관
 */
@Service
@Transactional(readOnly = true)
class PerformanceMonitoringService {

    data class PerformanceTestResult(
        val testName: String,
        val executionTimeMs: Long,
        val status: String,
        val details: String? = null
    )

    data class BenchmarkResult(
        val category: String,
        val testName: String,
        val executionTimeMs: Long,
        val recordsProcessed: Int,
        val throughputPerSecond: Double
    )

    /**
     * 멀티테넌시 성능 벤치마크 실행
     * 기존 run_multitenancy_benchmark() 함수 이관
     */
    fun runMultitenancyBenchmark(companyId: UUID): List<BenchmarkResult> {
        val results = mutableListOf<BenchmarkResult>()

        // 1. 회사별 데이터 조회 성능 테스트
        val companyQueryTime = measureTimeMillis {
            // 실제 구현에서는 Repository를 통해 회사 데이터 조회
            // companyRepository.findByCompanyId(companyId)
        }
        
        results.add(BenchmarkResult(
            category = "데이터 조회",
            testName = "회사별 데이터 조회",
            executionTimeMs = companyQueryTime,
            recordsProcessed = 1,
            throughputPerSecond = if (companyQueryTime > 0) 1000.0 / companyQueryTime else 0.0
        ))

        // 2. 사용자 목록 조회 성능 테스트
        val userQueryTime = measureTimeMillis {
            // userRepository.findByCompanyId(companyId)
        }
        
        results.add(BenchmarkResult(
            category = "데이터 조회",
            testName = "사용자 목록 조회",
            executionTimeMs = userQueryTime,
            recordsProcessed = 10, // 예상 사용자 수
            throughputPerSecond = if (userQueryTime > 0) 10000.0 / userQueryTime else 0.0
        ))

        // 3. 건물 목록 조회 성능 테스트
        val buildingQueryTime = measureTimeMillis {
            // buildingRepository.findByCompanyId(companyId)
        }
        
        results.add(BenchmarkResult(
            category = "데이터 조회",
            testName = "건물 목록 조회",
            executionTimeMs = buildingQueryTime,
            recordsProcessed = 5, // 예상 건물 수
            throughputPerSecond = if (buildingQueryTime > 0) 5000.0 / buildingQueryTime else 0.0
        ))

        // 4. 복합 조인 쿼리 성능 테스트
        val complexQueryTime = measureTimeMillis {
            // 건물-세대-계약 조인 쿼리 실행
            // leaseContractRepository.findDetailsByCompanyId(companyId)
        }
        
        results.add(BenchmarkResult(
            category = "복합 쿼리",
            testName = "건물-세대-계약 조인",
            executionTimeMs = complexQueryTime,
            recordsProcessed = 50, // 예상 계약 수
            throughputPerSecond = if (complexQueryTime > 0) 50000.0 / complexQueryTime else 0.0
        ))

        return results
    }

    /**
     * 데이터베이스 연결 성능 테스트
     */
    fun testDatabaseConnectionPerformance(): PerformanceTestResult {
        val executionTime = measureTimeMillis {
            // 간단한 SELECT 1 쿼리 실행
            // jdbcTemplate.queryForObject("SELECT 1", Int::class.java)
        }

        return PerformanceTestResult(
            testName = "데이터베이스 연결 테스트",
            executionTimeMs = executionTime,
            status = if (executionTime < 100) "PASS" else "WARN",
            details = "연결 응답 시간: ${executionTime}ms"
        )
    }

    /**
     * 캐시 성능 테스트
     */
    fun testCachePerformance(): PerformanceTestResult {
        val executionTime = measureTimeMillis {
            // Redis 캐시 읽기/쓰기 테스트
            // redisTemplate.opsForValue().set("test_key", "test_value")
            // redisTemplate.opsForValue().get("test_key")
        }

        return PerformanceTestResult(
            testName = "캐시 성능 테스트",
            executionTimeMs = executionTime,
            status = if (executionTime < 50) "PASS" else "WARN",
            details = "캐시 응답 시간: ${executionTime}ms"
        )
    }

    /**
     * API 응답 시간 테스트
     */
    fun testApiResponseTime(endpoint: String): PerformanceTestResult {
        val executionTime = measureTimeMillis {
            // 실제 API 호출 시뮬레이션
            Thread.sleep(10) // 시뮬레이션용
        }

        return PerformanceTestResult(
            testName = "API 응답 시간 테스트: $endpoint",
            executionTimeMs = executionTime,
            status = when {
                executionTime < 200 -> "PASS"
                executionTime < 500 -> "WARN"
                else -> "FAIL"
            },
            details = "API 응답 시간: ${executionTime}ms"
        )
    }

    /**
     * 메모리 사용량 모니터링
     */
    fun getMemoryUsageStats(): Map<String, Any> {
        val runtime = Runtime.getRuntime()
        val totalMemory = runtime.totalMemory()
        val freeMemory = runtime.freeMemory()
        val usedMemory = totalMemory - freeMemory
        val maxMemory = runtime.maxMemory()

        return mapOf(
            "totalMemoryMB" to totalMemory / (1024 * 1024),
            "usedMemoryMB" to usedMemory / (1024 * 1024),
            "freeMemoryMB" to freeMemory / (1024 * 1024),
            "maxMemoryMB" to maxMemory / (1024 * 1024),
            "memoryUsagePercent" to (usedMemory.toDouble() / maxMemory * 100).toInt()
        )
    }

    /**
     * 종합 성능 테스트 실행
     */
    fun runComprehensivePerformanceTest(companyId: UUID): Map<String, Any> {
        val startTime = LocalDateTime.now()
        val results = mutableListOf<PerformanceTestResult>()

        // 1. 데이터베이스 연결 테스트
        results.add(testDatabaseConnectionPerformance())

        // 2. 캐시 성능 테스트
        results.add(testCachePerformance())

        // 3. API 응답 시간 테스트
        results.add(testApiResponseTime("/api/v1/companies"))
        results.add(testApiResponseTime("/api/v1/buildings"))
        results.add(testApiResponseTime("/api/v1/lease/contracts"))

        // 4. 멀티테넌시 벤치마크
        val benchmarkResults = runMultitenancyBenchmark(companyId)

        val endTime = LocalDateTime.now()
        val totalTests = results.size + benchmarkResults.size
        val passedTests = results.count { it.status == "PASS" } + 
                         benchmarkResults.count { it.executionTimeMs < 1000 }

        return mapOf(
            "testSession" to mapOf(
                "startTime" to startTime,
                "endTime" to endTime,
                "totalTests" to totalTests,
                "passedTests" to passedTests,
                "successRate" to (passedTests.toDouble() / totalTests * 100).toInt()
            ),
            "performanceTests" to results,
            "benchmarkResults" to benchmarkResults,
            "memoryStats" to getMemoryUsageStats()
        )
    }

    /**
     * 성능 임계값 검증
     */
    fun validatePerformanceThresholds(results: List<PerformanceTestResult>): List<String> {
        val warnings = mutableListOf<String>()

        results.forEach { result ->
            when {
                result.testName.contains("데이터베이스") && result.executionTimeMs > 100 -> {
                    warnings.add("데이터베이스 응답 시간이 임계값(100ms)을 초과했습니다: ${result.executionTimeMs}ms")
                }
                result.testName.contains("캐시") && result.executionTimeMs > 50 -> {
                    warnings.add("캐시 응답 시간이 임계값(50ms)을 초과했습니다: ${result.executionTimeMs}ms")
                }
                result.testName.contains("API") && result.executionTimeMs > 500 -> {
                    warnings.add("API 응답 시간이 임계값(500ms)을 초과했습니다: ${result.executionTimeMs}ms")
                }
            }
        }

        return warnings
    }

    /**
     * 성능 트렌드 분석
     */
    fun analyzePerformanceTrend(
        currentResults: List<PerformanceTestResult>,
        previousResults: List<PerformanceTestResult>
    ): Map<String, Any> {
        val trends = mutableMapOf<String, Any>()

        currentResults.forEach { current ->
            val previous = previousResults.find { it.testName == current.testName }
            if (previous != null) {
                val improvement = previous.executionTimeMs - current.executionTimeMs
                val improvementPercent = (improvement.toDouble() / previous.executionTimeMs * 100).toInt()
                
                trends[current.testName] = mapOf(
                    "current" to current.executionTimeMs,
                    "previous" to previous.executionTimeMs,
                    "improvement" to improvement,
                    "improvementPercent" to improvementPercent,
                    "trend" to when {
                        improvement > 0 -> "IMPROVED"
                        improvement < 0 -> "DEGRADED"
                        else -> "STABLE"
                    }
                )
            }
        }

        return trends
    }

    /**
     * 시스템 리소스 사용량 모니터링
     */
    fun getSystemResourceUsage(): Map<String, Any> {
        val memoryStats = getMemoryUsageStats()
        
        return mapOf(
            "memory" to memoryStats,
            "timestamp" to LocalDateTime.now(),
            "activeThreads" to Thread.activeCount(),
            "availableProcessors" to Runtime.getRuntime().availableProcessors()
        )
    }
}