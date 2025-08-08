package com.qiro.domain.security.service

import com.qiro.domain.security.dto.*
import com.qiro.domain.security.entity.*
import com.qiro.domain.security.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 리소스 권한 관리 서비스
 */
@Service
@Transactional
class ResourcePermissionService(
    private val resourcePermissionRepository: ResourcePermissionRepository,
    private val permissionAuditService: PermissionAuditService
) {

    /**
     * 리소스 권한 부여
     */
    fun grantResourcePermission(
        companyId: UUID,
        request: GrantResourcePermissionRequest,
        grantedBy: UUID
    ): ResourcePermissionDto {
        // 기존 권한 확인
        val existingPermission = resourcePermissionRepository.findByUserIdAndResourceTypeAndResourceIdAndPermissionType(
            request.userId,
            request.resourceType.name,
            request.resourceId,
            request.permissionType.name
        )
        
        val resourcePermission = if (existingPermission != null) {
            // 기존 권한 업데이트
            existingPermission.copy(
                isActive = true,
                grantedAt = LocalDateTime.now(),
                grantedBy = grantedBy,
                expiresAt = request.expiresAt
            )
        } else {
            // 새로운 권한 생성
            ResourcePermission(
                userId = request.userId,
                resourceType = request.resourceType.name,
                resourceId = request.resourceId,
                permissionType = request.permissionType.name,
                grantedBy = grantedBy,
                expiresAt = request.expiresAt
            )
        }
        
        val savedPermission = resourcePermissionRepository.save(resourcePermission)
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = companyId,
            userId = request.userId,
            action = AuditAction.GRANT,
            resourceType = request.resourceType,
            resourceId = request.resourceId,
            success = true,
            performedBy = grantedBy
        )
        
        return savedPermission.toDto()
    }

    /**
     * 리소스 권한 제거
     */
    fun revokeResourcePermission(
        companyId: UUID,
        userId: UUID,
        resourceType: ResourceType,
        resourceId: UUID,
        permissionType: ResourcePermissionType,
        revokedBy: UUID
    ): Boolean {
        val resourcePermission = resourcePermissionRepository.findByUserIdAndResourceTypeAndResourceIdAndPermissionType(
            userId,
            resourceType.name,
            resourceId,
            permissionType.name
        ) ?: return false
        
        val deactivatedPermission = resourcePermission.deactivate()
        resourcePermissionRepository.save(deactivatedPermission)
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = companyId,
            userId = userId,
            action = AuditAction.REVOKE,
            resourceType = resourceType,
            resourceId = resourceId,
            success = true,
            performedBy = revokedBy
        )
        
        return true
    }

    /**
     * 사용자의 리소스 권한 조회
     */
    @Transactional(readOnly = true)
    fun getUserResourcePermissions(userId: UUID): List<ResourcePermissionDto> {
        return resourcePermissionRepository.findByUserIdOrderByGrantedAtDesc(userId)
            .map { it.toDto() }
    }

    /**
     * 사용자의 활성 리소스 권한 조회
     */
    @Transactional(readOnly = true)
    fun getActiveUserResourcePermissions(userId: UUID): List<ResourcePermissionDto> {
        return resourcePermissionRepository.findActiveByUserId(userId)
            .map { it.toDto() }
    }

    /**
     * 사용자의 특정 리소스 타입 권한 조회
     */
    @Transactional(readOnly = true)
    fun getUserResourcePermissionsByType(userId: UUID, resourceType: ResourceType): List<ResourcePermissionDto> {
        return resourcePermissionRepository.findByUserIdAndResourceType(userId, resourceType.name)
            .map { it.toDto() }
    }

    /**
     * 리소스별 권한 조회
     */
    @Transactional(readOnly = true)
    fun getResourcePermissions(resourceType: ResourceType, resourceId: UUID): List<ResourcePermissionDto> {
        return resourcePermissionRepository.findByResourceTypeAndResourceIdOrderByGrantedAtDesc(
            resourceType.name,
            resourceId
        ).map { it.toDto() }
    }

    /**
     * 만료된 리소스 권한 정리
     */
    fun cleanupExpiredResourcePermissions(): Int {
        val expiredPermissions = resourcePermissionRepository.findExpiredPermissions()
        var cleanedCount = 0
        
        for (permission in expiredPermissions) {
            val deactivatedPermission = permission.deactivate()
            resourcePermissionRepository.save(deactivatedPermission)
            cleanedCount++
        }
        
        return cleanedCount
    }

    /**
     * 사용자의 모든 리소스 권한 제거
     */
    fun revokeAllUserResourcePermissions(companyId: UUID, userId: UUID, revokedBy: UUID): Int {
        val userPermissions = resourcePermissionRepository.findActiveByUserId(userId)
        var revokedCount = 0
        
        for (permission in userPermissions) {
            val deactivatedPermission = permission.deactivate()
            resourcePermissionRepository.save(deactivatedPermission)
            revokedCount++
        }
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = companyId,
            userId = userId,
            action = AuditAction.REVOKE,
            success = true,
            performedBy = revokedBy
        )
        
        return revokedCount
    }

    /**
     * 특정 리소스의 모든 권한 제거
     */
    fun revokeAllResourcePermissions(
        companyId: UUID,
        resourceType: ResourceType,
        resourceId: UUID,
        revokedBy: UUID
    ): Int {
        val resourcePermissions = resourcePermissionRepository.findByResourceTypeAndResourceIdOrderByGrantedAtDesc(
            resourceType.name,
            resourceId
        )
        var revokedCount = 0
        
        for (permission in resourcePermissions) {
            if (permission.isActive) {
                val deactivatedPermission = permission.deactivate()
                resourcePermissionRepository.save(deactivatedPermission)
                revokedCount++
            }
        }
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = companyId,
            userId = revokedBy,
            action = AuditAction.REVOKE,
            resourceType = resourceType,
            resourceId = resourceId,
            success = true,
            performedBy = revokedBy
        )
        
        return revokedCount
    }

    /**
     * ResourcePermission 엔티티를 DTO로 변환
     */
    private fun ResourcePermission.toDto(): ResourcePermissionDto {
        return ResourcePermissionDto(
            resourcePermissionId = this.resourcePermissionId,
            userId = this.userId,
            resourceType = ResourceType.valueOf(this.resourceType),
            resourceId = this.resourceId,
            permissionType = ResourcePermissionType.valueOf(this.permissionType),
            grantedAt = this.grantedAt,
            grantedBy = this.grantedBy,
            expiresAt = this.expiresAt,
            isActive = this.isActive && !this.isExpired()
        )
    }
}

/**
 * 권한 감사 로그 서비스
 */
@Service
@Transactional
class PermissionAuditService(
    private val permissionAuditLogRepository: PermissionAuditLogRepository
) {

    /**
     * 감사 로그 기록
     */
    fun logAudit(
        companyId: UUID,
        userId: UUID,
        action: AuditAction,
        resourceType: ResourceType? = null,
        resourceId: UUID? = null,
        permissionCode: String? = null,
        ipAddress: String? = null,
        userAgent: String? = null,
        success: Boolean = true,
        errorMessage: String? = null,
        performedBy: UUID? = null
    ): PermissionAuditLogDto {
        val auditLog = PermissionAuditLog(
            companyId = companyId,
            userId = userId,
            action = action.name,
            resourceType = resourceType?.name,
            resourceId = resourceId,
            permissionCode = permissionCode,
            ipAddress = ipAddress,
            userAgent = userAgent,
            success = success,
            errorMessage = errorMessage,
            performedBy = performedBy
        )
        
        val savedLog = permissionAuditLogRepository.save(auditLog)
        return savedLog.toDto()
    }

    /**
     * 사용자별 감사 로그 조회
     */
    @Transactional(readOnly = true)
    fun getUserAuditLogs(userId: UUID, pageable: Pageable): Page<PermissionAuditLogDto> {
        return permissionAuditLogRepository.findByUserIdOrderByPerformedAtDesc(userId, pageable)
            .map { it.toDto() }
    }

    /**
     * 회사별 감사 로그 조회
     */
    @Transactional(readOnly = true)
    fun getCompanyAuditLogs(companyId: UUID, pageable: Pageable): Page<PermissionAuditLogDto> {
        return permissionAuditLogRepository.findByCompanyIdOrderByPerformedAtDesc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 액션별 감사 로그 조회
     */
    @Transactional(readOnly = true)
    fun getAuditLogsByAction(companyId: UUID, action: AuditAction, pageable: Pageable): Page<PermissionAuditLogDto> {
        return permissionAuditLogRepository.findByCompanyIdAndActionOrderByPerformedAtDesc(
            companyId, action.name, pageable
        ).map { it.toDto() }
    }

    /**
     * 실패한 접근 시도 조회
     */
    @Transactional(readOnly = true)
    fun getFailedAccessAttempts(companyId: UUID, pageable: Pageable): Page<PermissionAuditLogDto> {
        return permissionAuditLogRepository.findByCompanyIdAndSuccessFalseOrderByPerformedAtDesc(
            companyId, pageable
        ).map { it.toDto() }
    }

    /**
     * 기간별 감사 로그 조회
     */
    @Transactional(readOnly = true)
    fun getAuditLogsByPeriod(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime,
        pageable: Pageable
    ): Page<PermissionAuditLogDto> {
        return permissionAuditLogRepository.findByCompanyIdAndPerformedAtBetween(
            companyId, startDate, endDate, pageable
        ).map { it.toDto() }
    }

    /**
     * 권한 통계 조회
     */
    @Transactional(readOnly = true)
    fun getPermissionStatistics(companyId: UUID): PermissionStatisticsDto {
        // 실제 구현에서는 더 복잡한 통계 쿼리 필요
        val recentLogs = permissionAuditLogRepository.findByCompanyIdOrderByPerformedAtDesc(
            companyId, 
            org.springframework.data.domain.PageRequest.of(0, 10)
        ).content.map { it.toDto() }
        
        return PermissionStatisticsDto(
            totalRoles = 0, // 실제 구현에서는 RoleRepository에서 조회
            totalPermissions = 0, // 실제 구현에서는 PermissionRepository에서 조회
            totalUsers = 0, // 실제 구현에서는 UserRepository에서 조회
            activeUsers = 0, // 실제 구현에서는 UserRepository에서 조회
            mostUsedPermissions = emptyList(), // 실제 구현에서는 통계 쿼리 필요
            roleDistribution = emptyMap(), // 실제 구현에서는 통계 쿼리 필요
            recentAuditLogs = recentLogs
        )
    }

    /**
     * PermissionAuditLog 엔티티를 DTO로 변환
     */
    private fun PermissionAuditLog.toDto(): PermissionAuditLogDto {
        return PermissionAuditLogDto(
            logId = this.logId,
            companyId = this.companyId,
            userId = this.userId,
            action = AuditAction.valueOf(this.action),
            resourceType = this.resourceType,
            resourceId = this.resourceId,
            permissionCode = this.permissionCode,
            ipAddress = this.ipAddress,
            userAgent = this.userAgent,
            success = this.success,
            errorMessage = this.errorMessage,
            performedAt = this.performedAt,
            performedBy = this.performedBy
        )
    }
}