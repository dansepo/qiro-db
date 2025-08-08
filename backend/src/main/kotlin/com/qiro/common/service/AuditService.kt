package com.qiro.common.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.time.LocalDate
import java.util.*

/**
 * 감사 서비스 인터페이스
 */
interface AuditService {
    
    /**
     * 감사 로그 생성
     */
    fun createAuditLog(request: CreateAuditLogRequest): AuditLogDto
    
    /**
     * 사용자 활동 로그 생성
     */
    fun logUserActivity(request: CreateUserActivityLogRequest): UserActivityLogDto
    
    /**
     * 감사 로그 조회 (페이징)
     */
    fun getAuditLogs(companyId: UUID, pageable: Pageable): Page<AuditLogDto>
    
    /**
     * 감사 로그 필터 조회
     */
    fun getAuditLogsWithFilter(filter: AuditLogFilter, pageable: Pageable): Page<AuditLogDto>
    
    /**
     * 사용자별 감사 로그 조회
     */
    fun getAuditLogsByUser(companyId: UUID, userId: UUID, pageable: Pageable): Page<AuditLogDto>
    
    /**
     * 사용자 활동 로그 조회
     */
    fun getUserActivityLogs(companyId: UUID, pageable: Pageable): Page<UserActivityLogDto>
    
    /**
     * 사용자별 활동 로그 조회
     */
    fun getUserActivityLogsByUser(companyId: UUID, userId: UUID, pageable: Pageable): Page<UserActivityLogDto>
    
    /**
     * 감사 로그 통계 조회
     */
    fun getAuditLogStatistics(companyId: UUID, startDate: LocalDate?, endDate: LocalDate?): AuditLogStatisticsDto
    
    /**
     * 오래된 로그 정리
     */
    fun cleanupOldLogs(retentionDays: Int): Map<String, Long>
    
    /**
     * 보안 이벤트 로그 (높은 우선순위)
     */
    fun logSecurityEvent(
        companyId: UUID,
        userId: UUID?,
        eventType: String,
        description: String,
        ipAddress: String?,
        userAgent: String?,
        eventResult: String = "SUCCESS"
    ): AuditLogDto
    
    /**
     * 데이터 변경 로그
     */
    fun logDataChange(
        companyId: UUID,
        userId: UUID?,
        resourceType: String,
        resourceId: UUID,
        operation: String,
        description: String,
        details: String? = null
    ): AuditLogDto
    
    /**
     * 시스템 이벤트 로그
     */
    fun logSystemEvent(
        companyId: UUID,
        eventType: String,
        description: String,
        details: String? = null,
        eventResult: String = "SUCCESS"
    ): AuditLogDto
}