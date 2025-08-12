package com.qiro.domain.security.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 역할 엔티티
 */
@Entity
@Table(
    name = "roles",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_role_code_company", columnNames = ["company_id", "role_code"]),
        UniqueConstraint(name = "uk_role_name_company", columnNames = ["company_id", "role_name"])
    ]
)
data class Role(
    @Id
    @Column(name = "role_id")
    val roleId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "role_name", nullable = false, length = 100)
    val roleName: String,

    @Column(name = "role_code", nullable = false, length = 50)
    val roleCode: String,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "is_system_role")
    val isSystemRole: Boolean = false,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @UpdateTimestamp
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null,

    @OneToMany(mappedBy = "role", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val rolePermissions: MutableSet<RolePermission> = mutableSetOf(),

    @OneToMany(mappedBy = "role", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val userRoles: MutableSet<UserRole> = mutableSetOf()
) {
    /**
     * 역할 정보 업데이트
     */
    fun update(
        roleName: String? = null,
        description: String? = null,
        isActive: Boolean? = null,
        updatedBy: UUID
    ): Role {
        return this.copy(
            roleName = roleName ?: this.roleName,
            description = description ?: this.description,
            isActive = isActive ?: this.isActive,
            updatedBy = updatedBy
        )
    }

    /**
     * 권한 추가
     */
    fun addPermission(permission: Permission, grantedBy: UUID): RolePermission {
        val rolePermission = RolePermission(
            roleId = this.roleId,
            permissionId = permission.permissionId,
            grantedBy = grantedBy,
            role = this,
            permission = permission
        )
        this.rolePermissions.add(rolePermission)
        return rolePermission
    }

    /**
     * 권한 제거
     */
    fun removePermission(permission: Permission): Boolean {
        return this.rolePermissions.removeIf { it.permission.permissionId == permission.permissionId }
    }

    /**
     * 특정 권한 보유 여부 확인
     */
    fun hasPermission(permissionCode: String): Boolean {
        return this.rolePermissions.any { it.permission.permissionCode == permissionCode }
    }

    /**
     * 활성 권한 목록 조회
     */
    fun getActivePermissions(): List<Permission> {
        return this.rolePermissions.map { it.permission }
    }
}

/**
 * 권한 엔티티
 */
@Entity
@Table(
    name = "permissions",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_permission_code", columnNames = ["permission_code"]),
        UniqueConstraint(name = "uk_permission_resource_action", columnNames = ["resource", "action"])
    ]
)
data class Permission(
    @Id
    @Column(name = "permission_id")
    val permissionId: UUID = UUID.randomUUID(),

    @Column(name = "permission_name", nullable = false, length = 100)
    val permissionName: String,

    @Column(name = "permission_code", nullable = false, length = 100)
    val permissionCode: String,

    @Column(name = "resource", nullable = false, length = 50)
    val resource: String,

    @Column(name = "action", nullable = false, length = 50)
    val action: String,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "is_system_permission")
    val isSystemPermission: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @OneToMany(mappedBy = "permission", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val rolePermissions: MutableSet<RolePermission> = mutableSetOf()
)

/**
 * 역할-권한 매핑 엔티티
 */
@Entity
@Table(
    name = "role_permissions",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_role_permission", columnNames = ["role_id", "permission_id"])
    ]
)
data class RolePermission(
    @Id
    @Column(name = "role_permission_id")
    val rolePermissionId: UUID = UUID.randomUUID(),

    @Column(name = "role_id", nullable = false)
    val roleId: UUID,

    @Column(name = "permission_id", nullable = false)
    val permissionId: UUID,

    @CreationTimestamp
    @Column(name = "granted_at", nullable = false)
    val grantedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "granted_by", nullable = false)
    val grantedBy: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", insertable = false, updatable = false)
    val role: Role,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "permission_id", insertable = false, updatable = false)
    val permission: Permission
)

/**
 * 사용자-역할 매핑 엔티티
 */
@Entity
@Table(
    name = "user_roles",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_user_role", columnNames = ["user_id", "role_id"])
    ]
)
data class UserRole(
    @Id
    @Column(name = "user_role_id")
    val userRoleId: UUID = UUID.randomUUID(),

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "role_id", nullable = false)
    val roleId: UUID,

    @CreationTimestamp
    @Column(name = "assigned_at", nullable = false)
    val assignedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "assigned_by", nullable = false)
    val assignedBy: UUID,

    @Column(name = "expires_at")
    val expiresAt: LocalDateTime? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", insertable = false, updatable = false)
    val role: Role
) {
    /**
     * 만료 여부 확인
     */
    fun isExpired(): Boolean {
        return expiresAt?.isBefore(LocalDateTime.now()) ?: false
    }

    /**
     * 유효한 역할인지 확인
     */
    fun isValid(): Boolean {
        return isActive && !isExpired()
    }

    /**
     * 역할 비활성화
     */
    fun deactivate(): UserRole {
        return this.copy(isActive = false)
    }
}

/**
 * 리소스별 권한 엔티티
 */
@Entity
@Table(
    name = "resource_permissions",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_user_resource_permission", columnNames = ["user_id", "resource_type", "resource_id", "permission_type"])
    ]
)
data class ResourcePermission(
    @Id
    @Column(name = "resource_permission_id")
    val resourcePermissionId: UUID = UUID.randomUUID(),

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "resource_type", nullable = false, length = 50)
    val resourceType: String,

    @Column(name = "resource_id", nullable = false)
    val resourceId: UUID,

    @Column(name = "permission_type", nullable = false, length = 50)
    val permissionType: String,

    @CreationTimestamp
    @Column(name = "granted_at", nullable = false)
    val grantedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "granted_by", nullable = false)
    val grantedBy: UUID,

    @Column(name = "expires_at")
    val expiresAt: LocalDateTime? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true
) {
    /**
     * 만료 여부 확인
     */
    fun isExpired(): Boolean {
        return expiresAt?.isBefore(LocalDateTime.now()) ?: false
    }

    /**
     * 유효한 권한인지 확인
     */
    fun isValid(): Boolean {
        return isActive && !isExpired()
    }

    /**
     * 권한 비활성화
     */
    fun deactivate(): ResourcePermission {
        return this.copy(isActive = false)
    }
}

/**
 * 권한 감사 로그 엔티티
 */
@Entity
@Table(
    name = "permission_audit_log",
    schema = "bms"
)
data class PermissionAuditLog(
    @Id
    @Column(name = "log_id")
    val logId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "action", nullable = false, length = 50)
    val action: String,

    @Column(name = "resource_type", length = 50)
    val resourceType: String? = null,

    @Column(name = "resource_id")
    val resourceId: UUID? = null,

    @Column(name = "permission_code", length = 100)
    val permissionCode: String? = null,

    @Column(name = "ip_address")
    val ipAddress: String? = null,

    @Column(name = "user_agent", columnDefinition = "TEXT")
    val userAgent: String? = null,

    @Column(name = "success", nullable = false)
    val success: Boolean,

    @Column(name = "error_message", columnDefinition = "TEXT")
    val errorMessage: String? = null,

    @CreationTimestamp
    @Column(name = "performed_at", nullable = false)
    val performedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "performed_by")
    val performedBy: UUID? = null
)