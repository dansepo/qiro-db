package com.qiro.domain.security.service

import com.qiro.domain.security.dto.*
import com.qiro.domain.security.entity.*
import com.qiro.domain.security.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 사용자 역할 관리 서비스
 */
@Service
@Transactional
class UserRoleService(
    private val userRoleRepository: UserRoleRepository,
    private val roleRepository: RoleRepository,
    private val resourcePermissionRepository: ResourcePermissionRepository,
    private val permissionAuditService: PermissionAuditService
) {

    /**
     * 사용자에게 역할 배정
     */
    fun assignRoleToUser(request: AssignRoleRequest, assignedBy: UUID): UserRoleDto {
        val role = roleRepository.findById(request.roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: ${request.roleId}") }
        
        // 이미 배정된 역할인지 확인
        val existingUserRole = userRoleRepository.findByUserIdAndRoleId(request.userId, request.roleId)
        if (existingUserRole != null && existingUserRole.isValid()) {
            throw IllegalArgumentException("이미 배정된 역할입니다")
        }
        
        val userRole = if (existingUserRole != null) {
            // 기존 역할을 재활성화
            existingUserRole.copy(
                isActive = true,
                assignedAt = LocalDateTime.now(),
                assignedBy = assignedBy,
                expiresAt = request.expiresAt
            )
        } else {
            // 새로운 역할 배정
            UserRole(
                userId = request.userId,
                roleId = request.roleId,
                assignedBy = assignedBy,
                expiresAt = request.expiresAt,
                role = role
            )
        }
        
        val savedUserRole = userRoleRepository.save(userRole)
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = role.companyId,
            userId = request.userId,
            action = AuditAction.ROLE_ASSIGNED,
            resourceType = ResourceType.ROLE,
            resourceId = request.roleId,
            success = true,
            performedBy = assignedBy
        )
        
        return savedUserRole.toDto()
    }

    /**
     * 사용자에서 역할 제거
     */
    fun revokeRoleFromUser(userId: UUID, roleId: UUID, revokedBy: UUID): Boolean {
        val userRole = userRoleRepository.findByUserIdAndRoleId(userId, roleId)
            ?: return false
        
        val deactivatedUserRole = userRole.deactivate()
        userRoleRepository.save(deactivatedUserRole)
        
        val role = roleRepository.findById(roleId).orElse(null)
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = role?.companyId ?: UUID.randomUUID(),
            userId = userId,
            action = AuditAction.ROLE_REVOKED,
            resourceType = ResourceType.ROLE,
            resourceId = roleId,
            success = true,
            performedBy = revokedBy
        )
        
        return true
    }

    /**
     * 사용자의 모든 역할 조회
     */
    @Transactional(readOnly = true)
    fun getUserRoles(userId: UUID): List<UserRoleDto> {
        return userRoleRepository.findByUserIdOrderByAssignedAtDesc(userId)
            .map { it.toDto() }
    }

    /**
     * 사용자의 활성 역할 조회
     */
    @Transactional(readOnly = true)
    fun getActiveUserRoles(userId: UUID): List<UserRoleDto> {
        return userRoleRepository.findActiveByUserId(userId)
            .map { it.toDto() }
    }

    /**
     * 역할별 사용자 조회
     */
    @Transactional(readOnly = true)
    fun getUsersByRole(roleId: UUID): List<UserRoleDto> {
        return userRoleRepository.findByRoleIdOrderByAssignedAtDesc(roleId)
            .map { it.toDto() }
    }

    /**
     * 역할별 활성 사용자 조회
     */
    @Transactional(readOnly = true)
    fun getActiveUsersByRole(roleId: UUID): List<UserRoleDto> {
        return userRoleRepository.findActiveByRoleId(roleId)
            .map { it.toDto() }
    }

    /**
     * 만료된 역할 정리
     */
    fun cleanupExpiredRoles(): Int {
        val expiredRoles = userRoleRepository.findExpiredRoles()
        var cleanedCount = 0
        
        for (userRole in expiredRoles) {
            val deactivatedUserRole = userRole.deactivate()
            userRoleRepository.save(deactivatedUserRole)
            cleanedCount++
        }
        
        return cleanedCount
    }

    /**
     * UserRole 엔티티를 DTO로 변환
     */
    private fun UserRole.toDto(): UserRoleDto {
        return UserRoleDto(
            userRoleId = this.userRoleId,
            userId = this.userId,
            roleId = this.roleId,
            roleName = this.role.roleName,
            roleCode = this.role.roleCode,
            assignedAt = this.assignedAt,
            assignedBy = this.assignedBy,
            expiresAt = this.expiresAt,
            isActive = this.isActive && !this.isExpired()
        )
    }
}

/**
 * 권한 확인 서비스
 */
@Service
@Transactional(readOnly = true)
class PermissionCheckService(
    private val userRoleRepository: UserRoleRepository,
    private val permissionRepository: PermissionRepository,
    private val resourcePermissionRepository: ResourcePermissionRepository,
    private val permissionAuditService: PermissionAuditService
) {

    /**
     * 사용자 권한 확인
     */
    fun checkUserPermission(
        companyId: UUID,
        userId: UUID,
        permissionCode: String,
        ipAddress: String? = null,
        userAgent: String? = null
    ): CheckPermissionResponse {
        try {
            // 역할을 통한 권한 확인
            val hasRolePermission = checkRoleBasedPermission(userId, permissionCode)
            
            val response = CheckPermissionResponse(
                hasPermission = hasRolePermission,
                grantedThrough = if (hasRolePermission) "ROLE" else null,
                reason = if (hasRolePermission) null else "권한이 없습니다"
            )
            
            // 감사 로그 기록
            permissionAuditService.logAudit(
                companyId = companyId,
                userId = userId,
                action = if (hasRolePermission) AuditAction.ACCESS_GRANTED else AuditAction.ACCESS_DENIED,
                permissionCode = permissionCode,
                ipAddress = ipAddress,
                userAgent = userAgent,
                success = hasRolePermission,
                errorMessage = if (hasRolePermission) null else "권한 없음"
            )
            
            return response
        } catch (e: Exception) {
            // 감사 로그 기록
            permissionAuditService.logAudit(
                companyId = companyId,
                userId = userId,
                action = AuditAction.ACCESS_DENIED,
                permissionCode = permissionCode,
                ipAddress = ipAddress,
                userAgent = userAgent,
                success = false,
                errorMessage = e.message
            )
            
            return CheckPermissionResponse(
                hasPermission = false,
                reason = "권한 확인 중 오류가 발생했습니다"
            )
        }
    }

    /**
     * 리소스별 권한 확인
     */
    fun checkResourcePermission(
        companyId: UUID,
        userId: UUID,
        resourceType: ResourceType,
        resourceId: UUID,
        permissionType: ResourcePermissionType,
        ipAddress: String? = null,
        userAgent: String? = null
    ): CheckPermissionResponse {
        try {
            // 직접적인 리소스 권한 확인
            val resourcePermission = resourcePermissionRepository.findByUserIdAndResourceTypeAndResourceIdAndPermissionType(
                userId, resourceType.name, resourceId, permissionType.name
            )
            
            val hasPermission = resourcePermission?.isValid() ?: false
            
            val response = CheckPermissionResponse(
                hasPermission = hasPermission,
                grantedThrough = if (hasPermission) "RESOURCE_PERMISSION" else null,
                reason = if (hasPermission) null else "리소스 접근 권한이 없습니다"
            )
            
            // 감사 로그 기록
            permissionAuditService.logAudit(
                companyId = companyId,
                userId = userId,
                action = if (hasPermission) AuditAction.ACCESS_GRANTED else AuditAction.ACCESS_DENIED,
                resourceType = resourceType,
                resourceId = resourceId,
                ipAddress = ipAddress,
                userAgent = userAgent,
                success = hasPermission,
                errorMessage = if (hasPermission) null else "리소스 접근 권한 없음"
            )
            
            return response
        } catch (e: Exception) {
            // 감사 로그 기록
            permissionAuditService.logAudit(
                companyId = companyId,
                userId = userId,
                action = AuditAction.ACCESS_DENIED,
                resourceType = resourceType,
                resourceId = resourceId,
                ipAddress = ipAddress,
                userAgent = userAgent,
                success = false,
                errorMessage = e.message
            )
            
            return CheckPermissionResponse(
                hasPermission = false,
                reason = "리소스 권한 확인 중 오류가 발생했습니다"
            )
        }
    }

    /**
     * 사용자 권한 요약 조회
     */
    fun getUserPermissionSummary(userId: UUID): UserPermissionSummaryDto {
        val userRoles = userRoleRepository.findActiveByUserId(userId)
        val permissions = permissionRepository.findByUserId(userId)
        val resourcePermissions = resourcePermissionRepository.findActiveByUserId(userId)
        
        return UserPermissionSummaryDto(
            userId = userId,
            roles = userRoles.map { it.toDto() },
            permissions = permissions.map { it.toDto() },
            resourcePermissions = resourcePermissions.map { it.toDto() },
            lastLoginAt = null, // 실제 구현에서는 사용자 서비스에서 조회
            permissionCount = permissions.size,
            activeRoleCount = userRoles.size
        )
    }

    /**
     * 역할 기반 권한 확인
     */
    private fun checkRoleBasedPermission(userId: UUID, permissionCode: String): Boolean {
        val userRoles = userRoleRepository.findActiveByUserId(userId)
        
        for (userRole in userRoles) {
            val rolePermissions = permissionRepository.findByRoleId(userRole.roleId)
            if (rolePermissions.any { it.permissionCode == permissionCode }) {
                return true
            }
        }
        
        return false
    }

    /**
     * UserRole 엔티티를 DTO로 변환
     */
    private fun UserRole.toDto(): UserRoleDto {
        return UserRoleDto(
            userRoleId = this.userRoleId,
            userId = this.userId,
            roleId = this.roleId,
            roleName = this.role.roleName,
            roleCode = this.role.roleCode,
            assignedAt = this.assignedAt,
            assignedBy = this.assignedBy,
            expiresAt = this.expiresAt,
            isActive = this.isActive && !this.isExpired()
        )
    }

    /**
     * Permission 엔티티를 DTO로 변환
     */
    private fun Permission.toDto(): PermissionDto {
        return PermissionDto(
            permissionId = this.permissionId,
            permissionName = this.permissionName,
            permissionCode = this.permissionCode,
            resource = this.resource,
            action = this.action,
            description = this.description,
            isSystemPermission = this.isSystemPermission
        )
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