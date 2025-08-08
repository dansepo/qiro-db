package com.qiro.domain.security.dto

import java.time.LocalDateTime
import java.util.*

/**
 * 역할 DTO
 */
data class RoleDto(
    val roleId: UUID,
    val companyId: UUID,
    val roleName: String,
    val roleCode: String,
    val description: String?,
    val isSystemRole: Boolean,
    val isActive: Boolean,
    val permissions: List<PermissionDto> = emptyList(),
    val userCount: Int = 0,
    val createdAt: LocalDateTime,
    val createdBy: UUID,
    val updatedAt: LocalDateTime?,
    val updatedBy: UUID?
)

/**
 * 역할 생성 요청 DTO
 */
data class CreateRoleRequest(
    val roleName: String,
    val roleCode: String,
    val description: String? = null,
    val permissionCodes: List<String> = emptyList()
)

/**
 * 역할 수정 요청 DTO
 */
data class UpdateRoleRequest(
    val roleName: String? = null,
    val description: String? = null,
    val isActive: Boolean? = null,
    val permissionCodes: List<String>? = null
)

/**
 * 권한 DTO
 */
data class PermissionDto(
    val permissionId: UUID,
    val permissionName: String,
    val permissionCode: String,
    val resource: String,
    val action: String,
    val description: String?,
    val isSystemPermission: Boolean
)

/**
 * 사용자 역할 DTO
 */
data class UserRoleDto(
    val userRoleId: UUID,
    val userId: UUID,
    val roleId: UUID,
    val roleName: String,
    val roleCode: String,
    val assignedAt: LocalDateTime,
    val assignedBy: UUID,
    val expiresAt: LocalDateTime?,
    val isActive: Boolean
)

/**
 * 사용자 역할 배정 요청 DTO
 */
data class AssignRoleRequest(
    val userId: UUID,
    val roleId: UUID,
    val expiresAt: LocalDateTime? = null
)

/**
 * 리소스 권한 DTO
 */
data class ResourcePermissionDto(
    val resourcePermissionId: UUID,
    val userId: UUID,
    val resourceType: ResourceType,
    val resourceId: UUID,
    val permissionType: ResourcePermissionType,
    val grantedAt: LocalDateTime,
    val grantedBy: UUID,
    val expiresAt: LocalDateTime?,
    val isActive: Boolean
)

/**
 * 리소스 권한 부여 요청 DTO
 */
data class GrantResourcePermissionRequest(
    val userId: UUID,
    val resourceType: ResourceType,
    val resourceId: UUID,
    val permissionType: ResourcePermissionType,
    val expiresAt: LocalDateTime? = null
)

/**
 * 권한 확인 요청 DTO
 */
data class CheckPermissionRequest(
    val userId: UUID,
    val permissionCode: String,
    val resourceType: ResourceType? = null,
    val resourceId: UUID? = null
)

/**
 * 권한 확인 응답 DTO
 */
data class CheckPermissionResponse(
    val hasPermission: Boolean,
    val reason: String? = null,
    val grantedThrough: String? = null // ROLE, RESOURCE_PERMISSION
)

/**
 * 사용자 권한 요약 DTO
 */
data class UserPermissionSummaryDto(
    val userId: UUID,
    val roles: List<UserRoleDto>,
    val permissions: List<PermissionDto>,
    val resourcePermissions: List<ResourcePermissionDto>,
    val lastLoginAt: LocalDateTime?,
    val permissionCount: Int,
    val activeRoleCount: Int
)

/**
 * 권한 감사 로그 DTO
 */
data class PermissionAuditLogDto(
    val logId: UUID,
    val companyId: UUID,
    val userId: UUID,
    val action: AuditAction,
    val resourceType: String?,
    val resourceId: UUID?,
    val permissionCode: String?,
    val ipAddress: String?,
    val userAgent: String?,
    val success: Boolean,
    val errorMessage: String?,
    val performedAt: LocalDateTime,
    val performedBy: UUID?
)

/**
 * 리소스 타입 열거형
 */
enum class ResourceType {
    FACILITY_ASSET,     // 시설물 자산
    BUILDING,           // 건물
    UNIT,               // 세대/유닛
    LOCATION,           // 위치
    WORK_ORDER,         // 작업 지시서
    FAULT_REPORT,       // 고장 신고
    MAINTENANCE_PLAN,   // 정비 계획
    COST_TRACKING,      // 비용 추적
    BUDGET,             // 예산
    USER,               // 사용자
    ROLE,               // 역할
    SYSTEM              // 시스템
}

/**
 * 리소스 권한 타입 열거형
 */
enum class ResourcePermissionType {
    READ,               // 읽기
    WRITE,              // 쓰기
    DELETE,             // 삭제
    MANAGE              // 관리
}

/**
 * 감사 액션 열거형
 */
enum class AuditAction {
    GRANT,              // 권한 부여
    REVOKE,             // 권한 제거
    LOGIN,              // 로그인
    LOGOUT,             // 로그아웃
    ACCESS_GRANTED,     // 접근 허용
    ACCESS_DENIED,      // 접근 거부
    ROLE_ASSIGNED,      // 역할 배정
    ROLE_REVOKED,       // 역할 제거
    PERMISSION_CHECKED  // 권한 확인
}

/**
 * 권한 그룹 DTO
 */
data class PermissionGroupDto(
    val groupId: UUID,
    val companyId: UUID,
    val groupName: String,
    val groupCode: String,
    val description: String?,
    val permissions: List<PermissionDto> = emptyList(),
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val createdBy: UUID
)

/**
 * 권한 그룹 생성 요청 DTO
 */
data class CreatePermissionGroupRequest(
    val groupName: String,
    val groupCode: String,
    val description: String? = null,
    val permissionCodes: List<String> = emptyList()
)

/**
 * 역할 계층 구조 DTO
 */
data class RoleHierarchyDto(
    val roleId: UUID,
    val roleName: String,
    val roleCode: String,
    val level: Int,
    val parentRoleId: UUID?,
    val childRoles: List<RoleHierarchyDto> = emptyList(),
    val inheritedPermissions: List<PermissionDto> = emptyList()
)

/**
 * 권한 매트릭스 DTO
 */
data class PermissionMatrixDto(
    val resources: List<String>,
    val actions: List<String>,
    val roles: List<RolePermissionMatrixDto>
)

/**
 * 역할별 권한 매트릭스 DTO
 */
data class RolePermissionMatrixDto(
    val roleId: UUID,
    val roleName: String,
    val permissions: Map<String, Map<String, Boolean>> // resource -> action -> hasPermission
)

/**
 * 권한 통계 DTO
 */
data class PermissionStatisticsDto(
    val totalRoles: Int,
    val totalPermissions: Int,
    val totalUsers: Int,
    val activeUsers: Int,
    val mostUsedPermissions: List<PermissionUsageDto>,
    val roleDistribution: Map<String, Int>,
    val recentAuditLogs: List<PermissionAuditLogDto>
)

/**
 * 권한 사용 통계 DTO
 */
data class PermissionUsageDto(
    val permissionCode: String,
    val permissionName: String,
    val usageCount: Long,
    val lastUsedAt: LocalDateTime?
)