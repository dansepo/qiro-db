package com.qiro.common.service

import com.qiro.domain.migration.common.BaseService
import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.AuditLog
import com.qiro.domain.migration.entity.UserActivityLog
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.AuditLogRepository
import com.qiro.domain.migration.repository.UserActivityLogRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.*

/**
 * 감사 서비스 구현
 */
@Service
@Transactional
class AuditServiceImpl(
    private val auditLogRepository: AuditLogRepository,
    private val userActivityLogRepository: UserActivityLogRepository
) : AuditService, BaseService {

    private val logger = LoggerFactory.getLogger(AuditServiceImpl::class.java)

    /**
     * 감사 로그 생성
     */
    override fun createAuditLog(request: CreateAuditLogRequest): AuditLogDto {
        logOperation("createAuditLog", request)
        
        try {
            val auditLog = AuditLog(
                companyId = request.companyId,
                userId = request.userId,
                sessionId = request.sessionId,
                eventType = request.eventType,
                eventCategory = request.eventCategory,
                resourceType = request.resourceType,
                resourceId = request.resourceId,
                eventDescription = request.eventDescription,
                eventDetails = request.eventDetails,
                ipAddress = request.ipAddress,
                userAgent = request.userAgent,
                eventResult = request.eventResult,
                errorMessage = request.errorMessage,
                eventDate = LocalDate.now()
            )
            
            val savedLog = auditLogRepository.save(auditLog)
            return savedLog.toDto()
            
        } catch (e: Exception) {
            logger.error("감사 로그 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("감사 로그 생성 실패: ${e.message}")
        }
    }

    /**
     * 사용자 활동 로그 생성
     */
    override fun logUserActivity(request: CreateUserActivityLogRequest): UserActivityLogDto {
        logOperation("logUserActivity", request)
        
        try {
            val activityLog = UserActivityLog(
                companyId = request.companyId,
                userId = request.userId,
                sessionId = request.sessionId,
                activityType = request.activityType,
                activityCategory = request.activityCategory,
                activityDescription = request.activityDescription,
                activityResult = request.activityResult,
                resourceType = request.resourceType,
                resourceId = request.resourceId,
                pageUrl = request.pageUrl,
                ipAddress = request.ipAddress,
                userAgent = request.userAgent,
                durationMs = request.durationMs,
                activityDate = LocalDate.now()
            )
            
            val savedLog = userActivityLogRepository.save(activityLog)
            return savedLog.toDto()
            
        } catch (e: Exception) {
            logger.error("사용자 활동 로그 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("사용자 활동 로그 생성 실패: ${e.message}")
        }
    }

    /**
     * 감사 로그 조회 (페이징)
     */
    @Transactional(readOnly = true)
    override fun getAuditLogs(companyId: UUID, pageable: Pageable): Page<AuditLogDto> {
        logOperation("getAuditLogs", mapOf("companyId" to companyId, "pageable" to pageable))
        
        return try {
            auditLogRepository.findByCompanyIdOrderByEventTimestampDesc(companyId, pageable)
                .map { it.toDto() }
        } catch (e: Exception) {
            logger.error("감사 로그 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("감사 로그 조회 실패: ${e.message}")
        }
    }

    /**
     * 감사 로그 필터 조회
     */
    @Transactional(readOnly = true)
    override fun getAuditLogsWithFilter(filter: AuditLogFilter, pageable: Pageable): Page<AuditLogDto> {
        logOperation("getAuditLogsWithFilter", filter)
        
        return try {
            auditLogRepository.findWithFilter(
                companyId = filter.companyId,
                userId = filter.userId,
                eventType = filter.eventType,
                eventCategory = filter.eventCategory,
                resourceType = filter.resourceType,
                resourceId = filter.resourceId,
                startDate = filter.startDate,
                endDate = filter.endDate,
                ipAddress = filter.ipAddress,
                eventResult = filter.eventResult,
                pageable = pageable
            ).map { it.toDto() }
        } catch (e: Exception) {
            logger.error("감사 로그 필터 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("감사 로그 필터 조회 실패: ${e.message}")
        }
    }

    /**
     * 사용자별 감사 로그 조회
     */
    @Transactional(readOnly = true)
    override fun getAuditLogsByUser(companyId: UUID, userId: UUID, pageable: Pageable): Page<AuditLogDto> {
        logOperation("getAuditLogsByUser", mapOf("companyId" to companyId, "userId" to userId))
        
        return try {
            auditLogRepository.findByCompanyIdAndUserIdOrderByEventTimestampDesc(companyId, userId, pageable)
                .map { it.toDto() }
        } catch (e: Exception) {
            logger.error("사용자별 감사 로그 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("사용자별 감사 로그 조회 실패: ${e.message}")
        }
    }

    /**
     * 사용자 활동 로그 조회
     */
    @Transactional(readOnly = true)
    override fun getUserActivityLogs(companyId: UUID, pageable: Pageable): Page<UserActivityLogDto> {
        logOperation("getUserActivityLogs", mapOf("companyId" to companyId))
        
        return try {
            userActivityLogRepository.findByCompanyIdOrderByActivityTimestampDesc(companyId, pageable)
                .map { it.toDto() }
        } catch (e: Exception) {
            logger.error("사용자 활동 로그 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("사용자 활동 로그 조회 실패: ${e.message}")
        }
    }

    /**
     * 사용자별 활동 로그 조회
     */
    @Transactional(readOnly = true)
    override fun getUserActivityLogsByUser(companyId: UUID, userId: UUID, pageable: Pageable): Page<UserActivityLogDto> {
        logOperation("getUserActivityLogsByUser", mapOf("companyId" to companyId, "userId" to userId))
        
        return try {
            userActivityLogRepository.findByCompanyIdAndUserIdOrderByActivityTimestampDesc(companyId, userId, pageable)
                .map { it.toDto() }
        } catch (e: Exception) {
            logger.error("사용자별 활동 로그 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("사용자별 활동 로그 조회 실패: ${e.message}")
        }
    }

    /**
     * 감사 로그 통계 조회
     */
    @Transactional(readOnly = true)
    override fun getAuditLogStatistics(companyId: UUID, startDate: LocalDate?, endDate: LocalDate?): AuditLogStatisticsDto {
        logOperation("getAuditLogStatistics", mapOf("companyId" to companyId, "startDate" to startDate, "endDate" to endDate))
        
        return try {
            val totalEvents = auditLogRepository.countByCompanyIdAndDateRange(companyId, startDate, endDate)
            val uniqueUsers = auditLogRepository.countDistinctUsersByCompanyIdAndDateRange(companyId, startDate, endDate)
            val latestEvent = auditLogRepository.findLatestEventTimestamp(companyId)
            
            val eventsByType = auditLogRepository.countByEventTypeAndCompanyIdAndDateRange(companyId, startDate, endDate)
                .associate { it[0] as String to it[1] as Long }
            
            AuditLogStatisticsDto(
                totalEvents = totalEvents,
                uniqueUsers = uniqueUsers,
                eventsByType = eventsByType,
                eventsByCategory = emptyMap(), // 필요시 추가 구현
                eventsByResult = emptyMap(), // 필요시 추가 구현
                latestEvent = latestEvent
            )
        } catch (e: Exception) {
            logger.error("감사 로그 통계 조회 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("감사 로그 통계 조회 실패: ${e.message}")
        }
    }

    /**
     * 오래된 로그 정리
     */
    override fun cleanupOldLogs(retentionDays: Int): Map<String, Long> {
        logOperation("cleanupOldLogs", retentionDays)
        
        return try {
            val cutoffDate = LocalDate.now().minusDays(retentionDays.toLong())
            
            val deletedAuditLogs = auditLogRepository.deleteByEventDateBefore(cutoffDate)
            val deletedActivityLogs = userActivityLogRepository.deleteByActivityDateBefore(cutoffDate)
            
            mapOf(
                "audit_logs" to deletedAuditLogs,
                "user_activity_logs" to deletedActivityLogs
            )
        } catch (e: Exception) {
            logger.error("오래된 로그 정리 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("오래된 로그 정리 실패: ${e.message}")
        }
    }

    /**
     * 보안 이벤트 로그 (높은 우선순위)
     */
    override fun logSecurityEvent(
        companyId: UUID,
        userId: UUID?,
        eventType: String,
        description: String,
        ipAddress: String?,
        userAgent: String?,
        eventResult: String
    ): AuditLogDto {
        val request = CreateAuditLogRequest(
            companyId = companyId,
            userId = userId,
            eventType = eventType,
            eventCategory = "SECURITY",
            eventDescription = description,
            ipAddress = ipAddress,
            userAgent = userAgent,
            eventResult = eventResult
        )
        
        return createAuditLog(request)
    }

    /**
     * 데이터 변경 로그
     */
    override fun logDataChange(
        companyId: UUID,
        userId: UUID?,
        resourceType: String,
        resourceId: UUID,
        operation: String,
        description: String,
        details: String?
    ): AuditLogDto {
        val request = CreateAuditLogRequest(
            companyId = companyId,
            userId = userId,
            eventType = operation,
            eventCategory = "DATA_MODIFICATION",
            resourceType = resourceType,
            resourceId = resourceId,
            eventDescription = description,
            eventDetails = details,
            eventResult = "SUCCESS"
        )
        
        return createAuditLog(request)
    }

    /**
     * 시스템 이벤트 로그
     */
    override fun logSystemEvent(
        companyId: UUID,
        eventType: String,
        description: String,
        details: String?,
        eventResult: String
    ): AuditLogDto {
        val request = CreateAuditLogRequest(
            companyId = companyId,
            eventType = eventType,
            eventCategory = "SYSTEM_ADMINISTRATION",
            eventDescription = description,
            eventDetails = details,
            eventResult = eventResult
        )
        
        return createAuditLog(request)
    }

    override fun validateInput(input: Any): ValidationResult {
        return ValidationResult(isValid = true)
    }

    override fun logOperation(operation: String, result: Any, executionTimeMs: Long?) {
        logger.info("AuditService.$operation executed with result: $result")
    }
}

/**
 * AuditLog 엔티티를 DTO로 변환하는 확장 함수
 */
private fun AuditLog.toDto(): AuditLogDto {
    return AuditLogDto(
        id = this.id,
        companyId = this.companyId,
        userId = this.userId,
        sessionId = this.sessionId,
        eventType = this.eventType,
        eventCategory = this.eventCategory,
        resourceType = this.resourceType,
        resourceId = this.resourceId,
        eventDescription = this.eventDescription,
        eventDetails = this.eventDetails,
        ipAddress = this.ipAddress,
        userAgent = this.userAgent,
        eventResult = this.eventResult,
        errorMessage = this.errorMessage,
        eventTimestamp = this.eventTimestamp,
        eventDate = this.eventDate
    )
}

/**
 * UserActivityLog 엔티티를 DTO로 변환하는 확장 함수
 */
private fun UserActivityLog.toDto(): UserActivityLogDto {
    return UserActivityLogDto(
        id = this.id,
        companyId = this.companyId,
        userId = this.userId,
        sessionId = this.sessionId,
        activityType = this.activityType,
        activityCategory = this.activityCategory,
        activityDescription = this.activityDescription,
        activityResult = this.activityResult,
        resourceType = this.resourceType,
        resourceId = this.resourceId,
        pageUrl = this.pageUrl,
        ipAddress = this.ipAddress,
        userAgent = this.userAgent,
        durationMs = this.durationMs,
        activityTimestamp = this.activityTimestamp,
        activityDate = this.activityDate
    )
}