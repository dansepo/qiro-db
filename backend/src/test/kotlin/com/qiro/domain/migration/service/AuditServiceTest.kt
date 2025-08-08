package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.CreateAuditLogRequest
import com.qiro.domain.migration.dto.CreateUserActivityLogRequest
import com.qiro.domain.migration.dto.AuditLogFilter
import com.qiro.domain.migration.entity.AuditLog
import com.qiro.domain.migration.entity.UserActivityLog
import com.qiro.domain.migration.repository.AuditLogRepository
import com.qiro.domain.migration.repository.UserActivityLogRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldHaveSize
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * AuditService 단위 테스트
 */
class AuditServiceTest : BehaviorSpec({

    val auditLogRepository = mockk<AuditLogRepository>()
    val userActivityLogRepository = mockk<UserActivityLogRepository>()
    val auditService = AuditServiceImpl(auditLogRepository, userActivityLogRepository)

    given("감사 로그 생성") {
        `when`("유효한 감사 로그 요청을 받을 때") {
            val companyId = UUID.randomUUID()
            val userId = UUID.randomUUID()
            val request = CreateAuditLogRequest(
                companyId = companyId,
                userId = userId,
                eventType = "LOGIN",
                eventCategory = "AUTHENTICATION",
                eventDescription = "사용자 로그인",
                ipAddress = "192.168.1.1",
                eventResult = "SUCCESS"
            )
            
            val savedAuditLog = AuditLog(
                id = UUID.randomUUID(),
                companyId = companyId,
                userId = userId,
                eventType = "LOGIN",
                eventCategory = "AUTHENTICATION",
                eventDescription = "사용자 로그인",
                ipAddress = "192.168.1.1",
                eventResult = "SUCCESS",
                eventDate = LocalDate.now(),
                eventTimestamp = LocalDateTime.now()
            )
            
            every { auditLogRepository.save(any()) } returns savedAuditLog
            
            then("감사 로그가 생성되어야 한다") {
                val result = auditService.createAuditLog(request)
                
                result.id shouldNotBe null
                result.companyId shouldBe companyId
                result.userId shouldBe userId
                result.eventType shouldBe "LOGIN"
                result.eventCategory shouldBe "AUTHENTICATION"
                result.eventDescription shouldBe "사용자 로그인"
                result.ipAddress shouldBe "192.168.1.1"
                result.eventResult shouldBe "SUCCESS"
                
                verify { auditLogRepository.save(any()) }
            }
        }
    }

    given("사용자 활동 로그 생성") {
        `when`("유효한 활동 로그 요청을 받을 때") {
            val companyId = UUID.randomUUID()
            val userId = UUID.randomUUID()
            val request = CreateUserActivityLogRequest(
                companyId = companyId,
                userId = userId,
                activityType = "PAGE_VIEW",
                activityCategory = "USER_INTERFACE",
                activityDescription = "대시보드 페이지 조회",
                pageUrl = "/dashboard",
                ipAddress = "192.168.1.1",
                durationMs = 1500L
            )
            
            val savedActivityLog = UserActivityLog(
                id = UUID.randomUUID(),
                companyId = companyId,
                userId = userId,
                activityType = "PAGE_VIEW",
                activityCategory = "USER_INTERFACE",
                activityDescription = "대시보드 페이지 조회",
                pageUrl = "/dashboard",
                ipAddress = "192.168.1.1",
                durationMs = 1500L,
                activityDate = LocalDate.now(),
                activityTimestamp = LocalDateTime.now()
            )
            
            every { userActivityLogRepository.save(any()) } returns savedActivityLog
            
            then("사용자 활동 로그가 생성되어야 한다") {
                val result = auditService.logUserActivity(request)
                
                result.id shouldNotBe null
                result.companyId shouldBe companyId
                result.userId shouldBe userId
                result.activityType shouldBe "PAGE_VIEW"
                result.activityCategory shouldBe "USER_INTERFACE"
                result.activityDescription shouldBe "대시보드 페이지 조회"
                result.pageUrl shouldBe "/dashboard"
                result.durationMs shouldBe 1500L
                
                verify { userActivityLogRepository.save(any()) }
            }
        }
    }

    given("감사 로그 조회") {
        `when`("회사 ID로 감사 로그를 조회할 때") {
            val companyId = UUID.randomUUID()
            val pageable = PageRequest.of(0, 10)
            
            val auditLogs = listOf(
                AuditLog(
                    id = UUID.randomUUID(),
                    companyId = companyId,
                    eventType = "LOGIN",
                    eventCategory = "AUTHENTICATION",
                    eventDescription = "사용자 로그인",
                    eventDate = LocalDate.now(),
                    eventTimestamp = LocalDateTime.now()
                ),
                AuditLog(
                    id = UUID.randomUUID(),
                    companyId = companyId,
                    eventType = "CREATE",
                    eventCategory = "DATA_MODIFICATION",
                    eventDescription = "새 레코드 생성",
                    eventDate = LocalDate.now(),
                    eventTimestamp = LocalDateTime.now()
                )
            )
            
            every { 
                auditLogRepository.findByCompanyIdOrderByEventTimestampDesc(companyId, pageable) 
            } returns PageImpl(auditLogs, pageable, auditLogs.size.toLong())
            
            then("감사 로그 목록이 반환되어야 한다") {
                val result = auditService.getAuditLogs(companyId, pageable)
                
                result.content shouldHaveSize 2
                result.content[0].eventType shouldBe "LOGIN"
                result.content[1].eventType shouldBe "CREATE"
                
                verify { auditLogRepository.findByCompanyIdOrderByEventTimestampDesc(companyId, pageable) }
            }
        }
    }

    given("감사 로그 필터 조회") {
        `when`("필터 조건으로 감사 로그를 조회할 때") {
            val companyId = UUID.randomUUID()
            val userId = UUID.randomUUID()
            val filter = AuditLogFilter(
                companyId = companyId,
                userId = userId,
                eventType = "LOGIN",
                startDate = LocalDate.now().minusDays(7),
                endDate = LocalDate.now()
            )
            val pageable = PageRequest.of(0, 10)
            
            val filteredLogs = listOf(
                AuditLog(
                    id = UUID.randomUUID(),
                    companyId = companyId,
                    userId = userId,
                    eventType = "LOGIN",
                    eventCategory = "AUTHENTICATION",
                    eventDescription = "사용자 로그인",
                    eventDate = LocalDate.now(),
                    eventTimestamp = LocalDateTime.now()
                )
            )
            
            every { 
                auditLogRepository.findWithFilter(
                    companyId = companyId,
                    userId = userId,
                    eventType = "LOGIN",
                    eventCategory = null,
                    resourceType = null,
                    resourceId = null,
                    startDate = filter.startDate,
                    endDate = filter.endDate,
                    ipAddress = null,
                    eventResult = null,
                    pageable = pageable
                ) 
            } returns PageImpl(filteredLogs, pageable, filteredLogs.size.toLong())
            
            then("필터링된 감사 로그가 반환되어야 한다") {
                val result = auditService.getAuditLogsWithFilter(filter, pageable)
                
                result.content shouldHaveSize 1
                result.content[0].eventType shouldBe "LOGIN"
                result.content[0].userId shouldBe userId
                
                verify { 
                    auditLogRepository.findWithFilter(
                        companyId = companyId,
                        userId = userId,
                        eventType = "LOGIN",
                        eventCategory = null,
                        resourceType = null,
                        resourceId = null,
                        startDate = filter.startDate,
                        endDate = filter.endDate,
                        ipAddress = null,
                        eventResult = null,
                        pageable = pageable
                    ) 
                }
            }
        }
    }

    given("감사 로그 통계 조회") {
        `when`("회사의 감사 로그 통계를 조회할 때") {
            val companyId = UUID.randomUUID()
            val startDate = LocalDate.now().minusDays(30)
            val endDate = LocalDate.now()
            
            every { 
                auditLogRepository.countByCompanyIdAndDateRange(companyId, startDate, endDate) 
            } returns 100L
            
            every { 
                auditLogRepository.countDistinctUsersByCompanyIdAndDateRange(companyId, startDate, endDate) 
            } returns 25L
            
            every { 
                auditLogRepository.findLatestEventTimestamp(companyId) 
            } returns LocalDateTime.now()
            
            every { 
                auditLogRepository.countByEventTypeAndCompanyIdAndDateRange(companyId, startDate, endDate) 
            } returns listOf(
                arrayOf("LOGIN", 50L),
                arrayOf("CREATE", 30L),
                arrayOf("UPDATE", 20L)
            )
            
            then("감사 로그 통계가 반환되어야 한다") {
                val result = auditService.getAuditLogStatistics(companyId, startDate, endDate)
                
                result.totalEvents shouldBe 100L
                result.uniqueUsers shouldBe 25L
                result.eventsByType["LOGIN"] shouldBe 50L
                result.eventsByType["CREATE"] shouldBe 30L
                result.eventsByType["UPDATE"] shouldBe 20L
                result.latestEvent shouldNotBe null
                
                verify { auditLogRepository.countByCompanyIdAndDateRange(companyId, startDate, endDate) }
                verify { auditLogRepository.countDistinctUsersByCompanyIdAndDateRange(companyId, startDate, endDate) }
                verify { auditLogRepository.findLatestEventTimestamp(companyId) }
                verify { auditLogRepository.countByEventTypeAndCompanyIdAndDateRange(companyId, startDate, endDate) }
            }
        }
    }

    given("보안 이벤트 로그") {
        `when`("보안 이벤트를 로그에 기록할 때") {
            val companyId = UUID.randomUUID()
            val userId = UUID.randomUUID()
            
            val savedAuditLog = AuditLog(
                id = UUID.randomUUID(),
                companyId = companyId,
                userId = userId,
                eventType = "FAILED_LOGIN",
                eventCategory = "SECURITY",
                eventDescription = "로그인 실패",
                ipAddress = "192.168.1.100",
                eventResult = "FAILURE",
                eventDate = LocalDate.now(),
                eventTimestamp = LocalDateTime.now()
            )
            
            every { auditLogRepository.save(any()) } returns savedAuditLog
            
            then("보안 이벤트가 로그에 기록되어야 한다") {
                val result = auditService.logSecurityEvent(
                    companyId = companyId,
                    userId = userId,
                    eventType = "FAILED_LOGIN",
                    description = "로그인 실패",
                    ipAddress = "192.168.1.100",
                    userAgent = "Mozilla/5.0",
                    eventResult = "FAILURE"
                )
                
                result.eventType shouldBe "FAILED_LOGIN"
                result.eventCategory shouldBe "SECURITY"
                result.eventDescription shouldBe "로그인 실패"
                result.eventResult shouldBe "FAILURE"
                
                verify { auditLogRepository.save(any()) }
            }
        }
    }

    given("오래된 로그 정리") {
        `when`("보존 기간이 지난 로그를 정리할 때") {
            val retentionDays = 365
            
            every { auditLogRepository.deleteByEventDateBefore(any()) } returns 50L
            every { userActivityLogRepository.deleteByActivityDateBefore(any()) } returns 100L
            
            then("오래된 로그가 정리되어야 한다") {
                val result = auditService.cleanupOldLogs(retentionDays)
                
                result["audit_logs"] shouldBe 50L
                result["user_activity_logs"] shouldBe 100L
                
                verify { auditLogRepository.deleteByEventDateBefore(any()) }
                verify { userActivityLogRepository.deleteByActivityDateBefore(any()) }
            }
        }
    }
})