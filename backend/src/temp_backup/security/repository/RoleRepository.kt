package com.qiro.domain.security.repository

import com.qiro.domain.security.entity.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 역할 Repository
 */
@Repository
interface RoleRepository : JpaRepository<Role, UUID> {

    /**
     * 회사별 역할 조회
     */
    fun findByCompanyIdOrderByRoleNameAsc(companyId: UUID, pageable: Pageable): Page<Role>

    /**
     * 회사별 활성 역할 조회
     */
    fun findByCompanyIdAndIsActiveTrueOrderByRoleNameAsc(companyId: UUID): List<Role>

    /**
     * 역할 코드로 조회
     */
    fun findByCompanyIdAndRoleCode(companyId: UUID, roleCode: String): Role?

    /**
     * 역할 이름으로 조회
     */
    fun findByCompanyIdAndRoleName(companyId: UUID, roleName: String): Role?

    /**
     * 시스템 역할 조회
     */
    fun findByCompanyIdAndIsSystemRoleTrueOrderByRoleNameAsc(companyId: UUID): List<Role>

    /**
     * 사용자별 역할 조회
     */
    @Query("""
        SELECT r FROM Role r 
        JOIN UserRole ur ON r.roleId = ur.roleId 
        WHERE ur.userId = :userId 
        AND ur.isActive = true 
        AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY r.roleName
    """)
    fun findByUserId(@Param("userId") userId: UUID): List<Role>

    /**
     * 권한별 역할 조회
     */
    @Query("""
        SELECT r FROM Role r 
        JOIN RolePermission rp ON r.roleId = rp.roleId 
        JOIN Permission p ON rp.permissionId = p.permissionId 
        WHERE p.permissionCode = :permissionCode 
        AND r.companyId = :companyId 
        AND r.isActive = true
        ORDER BY r.roleName
    """)
    fun findByPermissionCode(
        @Param("companyId") companyId: UUID,
        @Param("permissionCode") permissionCode: String
    ): List<Role>

    /**
     * 역할 코드 중복 확인
     */
    fun existsByCompanyIdAndRoleCode(companyId: UUID, roleCode: String): Boolean

    /**
     * 역할 이름 중복 확인
     */
    fun existsByCompanyIdAndRoleName(companyId: UUID, roleName: String): Boolean
}

/**
 * 권한 Repository
 */
@Repository
interface PermissionRepository : JpaRepository<Permission, UUID> {

    /**
     * 권한 코드로 조회
     */
    fun findByPermissionCode(permissionCode: String): Permission?

    /**
     * 리소스별 권한 조회
     */
    fun findByResourceOrderByActionAsc(resource: String): List<Permission>

    /**
     * 리소스와 액션으로 조회
     */
    fun findByResourceAndAction(resource: String, action: String): Permission?

    /**
     * 시스템 권한 조회
     */
    fun findByIsSystemPermissionTrueOrderByResourceAscActionAsc(): List<Permission>

    /**
     * 권한 코드 목록으로 조회
     */
    fun findByPermissionCodeIn(permissionCodes: List<String>): List<Permission>

    /**
     * 역할별 권한 조회
     */
    @Query("""
        SELECT p FROM Permission p 
        JOIN RolePermission rp ON p.permissionId = rp.permissionId 
        WHERE rp.roleId = :roleId
        ORDER BY p.resource, p.action
    """)
    fun findByRoleId(@Param("roleId") roleId: UUID): List<Permission>

    /**
     * 사용자별 권한 조회 (역할을 통한)
     */
    @Query("""
        SELECT DISTINCT p FROM Permission p 
        JOIN RolePermission rp ON p.permissionId = rp.permissionId 
        JOIN Role r ON rp.roleId = r.roleId 
        JOIN UserRole ur ON r.roleId = ur.roleId 
        WHERE ur.userId = :userId 
        AND ur.isActive = true 
        AND r.isActive = true 
        AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY p.resource, p.action
    """)
    fun findByUserId(@Param("userId") userId: UUID): List<Permission>
}

/**
 * 역할-권한 매핑 Repository
 */
@Repository
interface RolePermissionRepository : JpaRepository<RolePermission, UUID> {

    /**
     * 역할별 권한 매핑 조회
     */
    fun findByRoleIdOrderByGrantedAtDesc(roleId: UUID): List<RolePermission>

    /**
     * 권한별 역할 매핑 조회
     */
    fun findByPermissionIdOrderByGrantedAtDesc(permissionId: UUID): List<RolePermission>

    /**
     * 역할-권한 매핑 존재 확인
     */
    fun existsByRoleIdAndPermissionId(roleId: UUID, permissionId: UUID): Boolean

    /**
     * 역할-권한 매핑 삭제
     */
    fun deleteByRoleIdAndPermissionId(roleId: UUID, permissionId: UUID)

    /**
     * 역할별 권한 매핑 삭제
     */
    fun deleteByRoleId(roleId: UUID)
}

/**
 * 사용자-역할 매핑 Repository
 */
@Repository
interface UserRoleRepository : JpaRepository<UserRole, UUID> {

    /**
     * 사용자별 역할 조회
     */
    fun findByUserIdOrderByAssignedAtDesc(userId: UUID): List<UserRole>

    /**
     * 사용자별 활성 역할 조회
     */
    @Query("""
        SELECT ur FROM UserRole ur 
        WHERE ur.userId = :userId 
        AND ur.isActive = true 
        AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY ur.assignedAt DESC
    """)
    fun findActiveByUserId(@Param("userId") userId: UUID): List<UserRole>

    /**
     * 역할별 사용자 조회
     */
    fun findByRoleIdOrderByAssignedAtDesc(roleId: UUID): List<UserRole>

    /**
     * 역할별 활성 사용자 조회
     */
    @Query("""
        SELECT ur FROM UserRole ur 
        WHERE ur.roleId = :roleId 
        AND ur.isActive = true 
        AND (ur.expiresAt IS NULL OR ur.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY ur.assignedAt DESC
    """)
    fun findActiveByRoleId(@Param("roleId") roleId: UUID): List<UserRole>

    /**
     * 사용자-역할 매핑 존재 확인
     */
    fun existsByUserIdAndRoleId(userId: UUID, roleId: UUID): Boolean

    /**
     * 사용자-역할 매핑 조회
     */
    fun findByUserIdAndRoleId(userId: UUID, roleId: UUID): UserRole?

    /**
     * 만료된 역할 조회
     */
    @Query("""
        SELECT ur FROM UserRole ur 
        WHERE ur.expiresAt IS NOT NULL 
        AND ur.expiresAt <= CURRENT_TIMESTAMP 
        AND ur.isActive = true
    """)
    fun findExpiredRoles(): List<UserRole>
}

/**
 * 리소스 권한 Repository
 */
@Repository
interface ResourcePermissionRepository : JpaRepository<ResourcePermission, UUID> {

    /**
     * 사용자별 리소스 권한 조회
     */
    fun findByUserIdOrderByGrantedAtDesc(userId: UUID): List<ResourcePermission>

    /**
     * 사용자별 활성 리소스 권한 조회
     */
    @Query("""
        SELECT rp FROM ResourcePermission rp 
        WHERE rp.userId = :userId 
        AND rp.isActive = true 
        AND (rp.expiresAt IS NULL OR rp.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY rp.grantedAt DESC
    """)
    fun findActiveByUserId(@Param("userId") userId: UUID): List<ResourcePermission>

    /**
     * 리소스별 권한 조회
     */
    fun findByResourceTypeAndResourceIdOrderByGrantedAtDesc(
        resourceType: String,
        resourceId: UUID
    ): List<ResourcePermission>

    /**
     * 사용자의 특정 리소스 권한 확인
     */
    fun findByUserIdAndResourceTypeAndResourceIdAndPermissionType(
        userId: UUID,
        resourceType: String,
        resourceId: UUID,
        permissionType: String
    ): ResourcePermission?

    /**
     * 사용자의 리소스 타입별 권한 조회
     */
    @Query("""
        SELECT rp FROM ResourcePermission rp 
        WHERE rp.userId = :userId 
        AND rp.resourceType = :resourceType 
        AND rp.isActive = true 
        AND (rp.expiresAt IS NULL OR rp.expiresAt > CURRENT_TIMESTAMP)
        ORDER BY rp.grantedAt DESC
    """)
    fun findByUserIdAndResourceType(
        @Param("userId") userId: UUID,
        @Param("resourceType") resourceType: String
    ): List<ResourcePermission>

    /**
     * 만료된 리소스 권한 조회
     */
    @Query("""
        SELECT rp FROM ResourcePermission rp 
        WHERE rp.expiresAt IS NOT NULL 
        AND rp.expiresAt <= CURRENT_TIMESTAMP 
        AND rp.isActive = true
    """)
    fun findExpiredPermissions(): List<ResourcePermission>
}

/**
 * 권한 감사 로그 Repository
 */
@Repository
interface PermissionAuditLogRepository : JpaRepository<PermissionAuditLog, UUID> {

    /**
     * 사용자별 감사 로그 조회
     */
    fun findByUserIdOrderByPerformedAtDesc(userId: UUID, pageable: Pageable): Page<PermissionAuditLog>

    /**
     * 회사별 감사 로그 조회
     */
    fun findByCompanyIdOrderByPerformedAtDesc(companyId: UUID, pageable: Pageable): Page<PermissionAuditLog>

    /**
     * 액션별 감사 로그 조회
     */
    fun findByCompanyIdAndActionOrderByPerformedAtDesc(
        companyId: UUID,
        action: String,
        pageable: Pageable
    ): Page<PermissionAuditLog>

    /**
     * 실패한 접근 시도 조회
     */
    fun findByCompanyIdAndSuccessFalseOrderByPerformedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<PermissionAuditLog>

    /**
     * 특정 기간의 감사 로그 조회
     */
    @Query("""
        SELECT pal FROM PermissionAuditLog pal 
        WHERE pal.companyId = :companyId 
        AND pal.performedAt BETWEEN :startDate AND :endDate 
        ORDER BY pal.performedAt DESC
    """)
    fun findByCompanyIdAndPerformedAtBetween(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: java.time.LocalDateTime,
        @Param("endDate") endDate: java.time.LocalDateTime,
        pageable: Pageable
    ): Page<PermissionAuditLog>
}