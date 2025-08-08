package com.qiro.domain.migration.service

import com.qiro.domain.migration.exception.ProcedureMigrationException
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.jdbc.core.JdbcTemplate
import java.util.*

/**
 * PerformanceMonitoringServiceImpl 단위 테스트
 */
class PerformanceMonitoringServiceImplTest : BehaviorSpec({

    val jdbcTemplate = mockk<JdbcTemplate>()
    val performanceMonitoringService = PerformanceMonitoringServiceImpl(jdbcTemplate)

    given("PerformanceMonitoringServiceImpl") {
        
        `when`("executePartitionPerformanceTest를 호출할 때") {
            then("유효한 테이블과 파티션 수로 호출하면 성공해야 한다") {
                // Given
                val tableName = "fault_reports"
                val partitionCount = 4
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = ? AND table_schema = 'bms'",
                        Int::class.java,
                        any<String>()
                    )
                } returns 1
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM bms.fault_reports_p1",
                        Long::class.java
                    )
                } returns 1000L
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT pg_total_relation_size('bms.fault_reports_p1')",
                        Long::class.java
                    )
                } returns 1048576L // 1MB

                // When
                val result = performanceMonitoringService.executePartitionPerformanceTest(tableName, partitionCount)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.tableName shouldBe tableName
                result.data?.totalPartitions shouldBe partitionCount
            }

            then("데이터베이스 오류 발생 시 예외를 던져야 한다") {
                // Given
                val tableName = "invalid_table"
                val partitionCount = 2
                
                every { 
                    jdbcTemplate.queryForObject(any<String>(), Int::class.java, any<String>())
                } throws RuntimeException("Database error")

                // When & Then
                shouldThrow<ProcedureMigrationException.PerformanceException> {
                    performanceMonitoringService.executePartitionPerformanceTest(tableName, partitionCount)
                }
            }
        }

        `when`("executeDataIsolationTest를 호출할 때") {
            then("유효한 회사 ID로 호출하면 성공해야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM bms.companies WHERE company_id = ?",
                        Long::class.java,
                        companyId
                    )
                } returns 10L
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM bms.companies WHERE company_id != ? OR company_id IS NULL",
                        Long::class.java,
                        companyId
                    )
                } returns 0L
                
                every { 
                    jdbcTemplate.queryForObject(
                        """
                        SELECT COUNT(*) FROM pg_policies 
                        WHERE schemaname = 'bms' AND tablename = ? AND enable = 'PERMISSIVE'
                        """.trimIndent(),
                        Int::class.java,
                        "companies"
                    )
                } returns 1

                // When
                val result = performanceMonitoringService.executeDataIsolationTest(companyId)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.companyId shouldBe companyId
                result.data?.overallIsolationScore shouldBeGreaterThan 0.0
            }

            then("데이터베이스 오류 발생 시 예외를 던져야 한다") {
                // Given
                val companyId = UUID.randomUUID()
                
                every { 
                    jdbcTemplate.queryForObject(any<String>(), Long::class.java, companyId)
                } throws RuntimeException("Database error")

                // When & Then
                shouldThrow<ProcedureMigrationException.PerformanceException> {
                    performanceMonitoringService.executeDataIsolationTest(companyId)
                }
            }
        }

        `when`("executePermissionTest를 호출할 때") {
            then("유효한 사용자 ID로 호출하면 성공해야 한다") {
                // Given
                val userId = UUID.randomUUID()
                
                every { jdbcTemplate.execute("SET app.current_user_id = '$userId'") } returns Unit
                every { jdbcTemplate.execute(any<String>()) } returns Unit

                // When
                val result = performanceMonitoringService.executePermissionTest(userId)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.userId shouldBe userId
                result.data?.totalPermissions shouldBeGreaterThan 0
            }

            then("권한 설정 실패 시에도 결과를 반환해야 한다") {
                // Given
                val userId = UUID.randomUUID()
                
                every { jdbcTemplate.execute("SET app.current_user_id = '$userId'") } returns Unit
                every { jdbcTemplate.execute(match { it.startsWith("SELECT") }) } throws RuntimeException("Permission denied")

                // When
                val result = performanceMonitoringService.executePermissionTest(userId)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.deniedPermissions shouldBeGreaterThan 0
            }
        }

        `when`("executeStatisticsCollection을 호출할 때") {
            then("유효한 테이블명으로 호출하면 성공해야 한다") {
                // Given
                val tableName = "buildings"
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT COUNT(*) FROM bms.$tableName",
                        Long::class.java
                    )
                } returns 100L
                
                every { 
                    jdbcTemplate.queryForObject(
                        "SELECT pg_total_relation_size('bms.$tableName')",
                        Long::class.java
                    )
                } returns 2097152L // 2MB
                
                every { 
                    jdbcTemplate.query(
                        any<String>(),
                        any<org.springframework.jdbc.core.RowMapper<IndexStatistics>>(),
                        tableName
                    )
                } returns listOf(
                    IndexStatistics("idx_buildings_company_id", 1000L, 800L)
                )
                
                every { 
                    jdbcTemplate.queryForMap(any<String>(), tableName)
                } returns mapOf(
                    "seq_tup_read" to 500L,
                    "idx_tup_fetch" to 1500L,
                    "n_tup_ins" to 100L,
                    "n_tup_upd" to 50L,
                    "n_tup_del" to 10L
                )

                // When
                val result = performanceMonitoringService.executeStatisticsCollection(tableName)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.tableName shouldBe tableName
                result.data?.tableStatistics?.rowCount shouldBe 100L
                result.data?.indexStatistics shouldHaveSize 1
            }

            then("존재하지 않는 테이블로 호출해도 기본값을 반환해야 한다") {
                // Given
                val tableName = "nonexistent_table"
                
                every { 
                    jdbcTemplate.queryForObject(any<String>(), Long::class.java)
                } throws RuntimeException("Table not found")
                
                every { 
                    jdbcTemplate.query(any<String>(), any<org.springframework.jdbc.core.RowMapper<IndexStatistics>>(), any<String>())
                } throws RuntimeException("Table not found")
                
                every { 
                    jdbcTemplate.queryForMap(any<String>(), any<String>())
                } throws RuntimeException("Table not found")

                // When
                val result = performanceMonitoringService.executeStatisticsCollection(tableName)

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.tableName shouldBe tableName
                result.data?.tableStatistics?.rowCount shouldBe 0L
            }
        }

        `when`("executeSystemMaintenance를 호출할 때") {
            then("모든 유지보수 작업이 성공하면 성공 결과를 반환해야 한다") {
                // Given
                every { jdbcTemplate.execute("VACUUM ANALYZE") } returns Unit
                every { jdbcTemplate.execute("ANALYZE") } returns Unit
                every { jdbcTemplate.execute("REINDEX SCHEMA bms") } returns Unit
                every { 
                    jdbcTemplate.update("DELETE FROM bms.user_activity_log WHERE created_at < NOW() - INTERVAL '30 days'")
                } returns 100

                // When
                val result = performanceMonitoringService.executeSystemMaintenance()

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.totalTasks shouldBe 4
                result.data?.successfulTasks shouldBe 4
                result.data?.failedTasks shouldBe 0
            }

            then("일부 유지보수 작업이 실패해도 결과를 반환해야 한다") {
                // Given
                every { jdbcTemplate.execute("VACUUM ANALYZE") } returns Unit
                every { jdbcTemplate.execute("ANALYZE") } throws RuntimeException("ANALYZE failed")
                every { jdbcTemplate.execute("REINDEX SCHEMA bms") } returns Unit
                every { 
                    jdbcTemplate.update("DELETE FROM bms.user_activity_log WHERE created_at < NOW() - INTERVAL '30 days'")
                } returns 50

                // When
                val result = performanceMonitoringService.executeSystemMaintenance()

                // Then
                result.success shouldBe true
                result.data shouldNotBe null
                result.data?.totalTasks shouldBe 4
                result.data?.successfulTasks shouldBe 3
                result.data?.failedTasks shouldBe 1
            }
        }
    }
})