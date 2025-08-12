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
 * 역할 관리 서비스
 */
@Service
@Transactional
class RoleService(
    private val roleRepository: RoleRepository,
    private val permissionRepository: PermissionRepository,
    private val rolePermissionRepository: RolePermissionRepository,
    private val userRoleRepository: UserRoleRepository,
    private val permissionAuditService: PermissionAuditService
) {

    /**
     * 역할 생성
     */
    fun createRole(companyId: UUID, request: CreateRoleRequest, createdBy: UUID): RoleDto {
        // 중복 확인
        if (roleRepository.existsByCompanyIdAndRoleCode(companyId, request.roleCode)) {
            throw IllegalArgumentException("이미 존재하는 역할 코드입니다: ${request.roleCode}")
        }
        
        if (roleRepository.existsByCompanyIdAndRoleName(companyId, request.roleName)) {
            throw IllegalArgumentException("이미 존재하는 역할 이름입니다: ${request.roleName}")
        }
        
        val role = Role(
            companyId = companyId,
            roleName = request.roleName,
            roleCode = request.roleCode,
            description = request.description,
            createdBy = createdBy
        )
        
        val savedRole = roleRepository.save(role)
        
        // 권한 부여
        if (request.permissionCodes.isNotEmpty()) {
            grantPermissionsToRole(savedRole.roleId, request.permissionCodes, createdBy)
        }
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = companyId,
            userId = createdBy,
            action = AuditAction.GRANT,
            resourceType = ResourceType.ROLE,
            resourceId = savedRole.roleId,
            success = true,
            performedBy = createdBy
        )
        
        return savedRole.toDto()
    }

    /**
     * 역할 수정
     */
    fun updateRole(roleId: UUID, request: UpdateRoleRequest, updatedBy: UUID): RoleDto {
        val role = roleRepository.findById(roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: $roleId") }
        
        if (role.isSystemRole) {
            throw IllegalArgumentException("시스템 역할은 수정할 수 없습니다")
        }
        
        // 이름 중복 확인 (변경하는 경우)
        if (request.roleName != null && request.roleName != role.roleName) {
            if (roleRepository.existsByCompanyIdAndRoleName(role.companyId, request.roleName)) {
                throw IllegalArgumentException("이미 존재하는 역할 이름입니다: ${request.roleName}")
            }
        }
        
        val updatedRole = role.update(
            roleName = request.roleName,
            description = request.description,
            isActive = request.isActive,
            updatedBy = updatedBy
        )
        
        val savedRole = roleRepository.save(updatedRole)
        
        // 권한 업데이트
        if (request.permissionCodes != null) {
            updateRolePermissions(roleId, request.permissionCodes, updatedBy)
        }
        
        return savedRole.toDto()
    }

    /**
     * 역할 조회
     */
    @Transactional(readOnly = true)
    fun getRole(roleId: UUID): RoleDto {
        val role = roleRepository.findById(roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: $roleId") }
        
        return role.toDto()
    }

    /**
     * 회사별 역할 목록 조회
     */
    @Transactional(readOnly = true)
    fun getRoles(companyId: UUID, pageable: Pageable): Page<RoleDto> {
        return roleRepository.findByCompanyIdOrderByRoleNameAsc(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 활성 역할 목록 조회
     */
    @Transactional(readOnly = true)
    fun getActiveRoles(companyId: UUID): List<RoleDto> {
        return roleRepository.findByCompanyIdAndIsActiveTrueOrderByRoleNameAsc(companyId)
            .map { it.toDto() }
    }

    /**
     * 역할에 권한 부여
     */
    fun grantPermissionsToRole(roleId: UUID, permissionCodes: List<String>, grantedBy: UUID): RoleDto {
        val role = roleRepository.findById(roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: $roleId") }
        
        val permissions = permissionRepository.findByPermissionCodeIn(permissionCodes)
        if (permissions.size != permissionCodes.size) {
            val foundCodes = permissions.map { it.permissionCode }
            val notFoundCodes = permissionCodes - foundCodes.toSet()
            throw IllegalArgumentException("존재하지 않는 권한 코드: $notFoundCodes")
        }
        
        for (permission in permissions) {
            if (!rolePermissionRepository.existsByRoleIdAndPermissionId(roleId, permission.permissionId)) {
                val rolePermission = RolePermission(
                    roleId = roleId,
                    permissionId = permission.permissionId,
                    grantedBy = grantedBy,
                    role = role,
                    permission = permission
                )
                rolePermissionRepository.save(rolePermission)
            }
        }
        
        return role.toDto()
    }

    /**
     * 역할에서 권한 제거
     */
    fun revokePermissionsFromRole(roleId: UUID, permissionCodes: List<String>): RoleDto {
        val role = roleRepository.findById(roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: $roleId") }
        
        val permissions = permissionRepository.findByPermissionCodeIn(permissionCodes)
        
        for (permission in permissions) {
            rolePermissionRepository.deleteByRoleIdAndPermissionId(roleId, permission.permissionId)
        }
        
        return role.toDto()
    }

    /**
     * 역할 권한 업데이트 (전체 교체)
     */
    fun updateRolePermissions(roleId: UUID, permissionCodes: List<String>, updatedBy: UUID): RoleDto {
        // 기존 권한 모두 제거
        rolePermissionRepository.deleteByRoleId(roleId)
        
        // 새 권한 부여
        if (permissionCodes.isNotEmpty()) {
            grantPermissionsToRole(roleId, permissionCodes, updatedBy)
        }
        
        return getRole(roleId)
    }

    /**
     * 역할 삭제
     */
    fun deleteRole(roleId: UUID, deletedBy: UUID) {
        val role = roleRepository.findById(roleId)
            .orElseThrow { IllegalArgumentException("역할을 찾을 수 없습니다: $roleId") }
        
        if (role.isSystemRole) {
            throw IllegalArgumentException("시스템 역할은 삭제할 수 없습니다")
        }
        
        // 사용자에게 배정된 역할인지 확인
        val activeUserRoles = userRoleRepository.findActiveByRoleId(roleId)
        if (activeUserRoles.isNotEmpty()) {
            throw IllegalArgumentException("사용자에게 배정된 역할은 삭제할 수 없습니다")
        }
        
        roleRepository.delete(role)
        
        // 감사 로그 기록
        permissionAuditService.logAudit(
            companyId = role.companyId,
            userId = deletedBy,
            action = AuditAction.REVOKE,
            resourceType = ResourceType.ROLE,
            resourceId = roleId,
            success = true,
            performedBy = deletedBy
        )
    }

    /**
     * 사용자별 역할 조회
     */
    @Transactional(readOnly = true)
    fun getUserRoles(userId: UUID): List<RoleDto> {
        return roleRepository.findByUserId(userId)
            .map { it.toDto() }
    }

    /**
     * 권한별 역할 조회
     */
    @Transactional(readOnly = true)
    fun getRolesByPermission(companyId: UUID, permissionCode: String): List<RoleDto> {
        return roleRepository.findByPermissionCode(companyId, permissionCode)
            .map { it.toDto() }
    }

    /**
     * Role 엔티티를 DTO로 변환
     */
    private fun Role.toDto(): RoleDto {
        val permissions = permissionRepository.findByRoleId(this.roleId)
            .map { it.toDto() }
        
        val userCount = userRoleRepository.findActiveByRoleId(this.roleId).size
        
        return RoleDto(
            roleId = this.roleId,
            companyId = this.companyId,
            roleName = this.roleName,
            roleCode = this.roleCode,
            description = this.description,
            isSystemRole = this.isSystemRole,
            isActive = this.isActive,
            permissions = permissions,
            userCount = userCount,
            createdAt = this.createdAt,
            createdBy = this.createdBy,
            updatedAt = this.updatedAt,
            updatedBy = this.updatedBy
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
}

/**
 * 권한 관리 서비스
 */
@Service
@Transactional(readOnly = true)
class PermissionService(
    private val permissionRepository: PermissionRepository,
    private val roleRepository: RoleRepository
) {

    /**
     * 모든 권한 조회
     */
    fun getAllPermissions(): List<PermissionDto> {
        return permissionRepository.findByIsSystemPermissionTrueOrderByResourceAscActionAsc()
            .map { it.toDto() }
    }

    /**
     * 리소스별 권한 조회
     */
    fun getPermissionsByResource(resource: String): List<PermissionDto> {
        return permissionRepository.findByResourceOrderByActionAsc(resource)
            .map { it.toDto() }
    }

    /**
     * 권한 코드로 조회
     */
    fun getPermissionByCode(permissionCode: String): PermissionDto? {
        return permissionRepository.findByPermissionCode(permissionCode)?.toDto()
    }

    /**
     * 역할별 권한 조회
     */
    fun getPermissionsByRole(roleId: UUID): List<PermissionDto> {
        return permissionRepository.findByRoleId(roleId)
            .map { it.toDto() }
    }

    /**
     * 사용자별 권한 조회
     */
    fun getPermissionsByUser(userId: UUID): List<PermissionDto> {
        return permissionRepository.findByUserId(userId)
            .map { it.toDto() }
    }

    /**
     * 권한 매트릭스 생성
     */
    fun getPermissionMatrix(companyId: UUID): PermissionMatrixDto {
        val roles = roleRepository.findByCompanyIdAndIsActiveTrueOrderByRoleNameAsc(companyId)
        val allPermissions = permissionRepository.findByIsSystemPermissionTrueOrderByResourceAscActionAsc()
        
        val resources = allPermissions.map { it.resource }.distinct().sorted()
        val actions = allPermissions.map { it.action }.distinct().sorted()
        
        val roleMatrixes = roles.map { role ->
            val rolePermissions = permissionRepository.findByRoleId(role.roleId)
            val permissionMap = mutableMapOf<String, MutableMap<String, Boolean>>()
            
            for (resource in resources) {
                permissionMap[resource] = mutableMapOf()
                for (action in actions) {
                    val hasPermission = rolePermissions.any { 
                        it.resource == resource && it.action == action 
                    }
                    permissionMap[resource]!![action] = hasPermission
                }
            }
            
            RolePermissionMatrixDto(
                roleId = role.roleId,
                roleName = role.roleName,
                permissions = permissionMap
            )
        }
        
        return PermissionMatrixDto(
            resources = resources,
            actions = actions,
            roles = roleMatrixes
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
}