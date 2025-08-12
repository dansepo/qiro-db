package com.qiro.domain.security.controller

import com.qiro.domain.security.dto.*
import com.qiro.domain.security.service.*
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*
import jakarta.servlet.http.HttpServletRequest

/**
 * 사용자 역할 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/user-roles")
@Tag(name = "User Role Management", description = "사용자 역할 관리 API")
class UserRoleController(
    private val userRoleService: UserRoleService,
    private val permissionCheckService: PermissionCheckService
) {

    @Operation(summary = "사용자에게 역할 배정", description = "사용자에게 역할을 배정합니다")
    @PostMapping
    fun assignRoleToUser(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: AssignRoleRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<UserRoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_ASSIGN")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = userRoleService.assignRoleToUser(request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "사용자에서 역할 제거", description = "사용자에서 역할을 제거합니다")
    @DeleteMapping("/users/{targetUserId}/roles/{roleId}")
    fun revokeRoleFromUser(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_ASSIGN")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val success = userRoleService.revokeRoleFromUser(targetUserId, roleId, userId)
        val response = mapOf(
            "success" to success,
            "message" to if (success) "역할이 제거되었습니다" else "제거할 역할을 찾을 수 없습니다"
        )
        return ResponseEntity.ok(response)
    }

    @Operation(summary = "사용자의 모든 역할 조회", description = "사용자의 모든 역할을 조회합니다")
    @GetMapping("/users/{targetUserId}")
    fun getUserRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<UserRoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = userRoleService.getUserRoles(targetUserId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자의 활성 역할 조회", description = "사용자의 활성 역할을 조회합니다")
    @GetMapping("/users/{targetUserId}/active")
    fun getActiveUserRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<UserRoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = userRoleService.getActiveUserRoles(targetUserId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할별 사용자 조회", description = "특정 역할을 가진 사용자를 조회합니다")
    @GetMapping("/roles/{roleId}/users")
    fun getUsersByRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<UserRoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = userRoleService.getUsersByRole(roleId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할별 활성 사용자 조회", description = "특정 역할을 가진 활성 사용자를 조회합니다")
    @GetMapping("/roles/{roleId}/users/active")
    fun getActiveUsersByRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<UserRoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = userRoleService.getActiveUsersByRole(roleId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "만료된 역할 정리", description = "만료된 역할을 정리합니다")
    @PostMapping("/cleanup-expired")
    fun cleanupExpiredRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "SYSTEM_CONFIG")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val cleanedCount = userRoleService.cleanupExpiredRoles()
        val response = mapOf(
            "cleanedCount" to cleanedCount,
            "message" to "${cleanedCount}개의 만료된 역할이 정리되었습니다",
            "cleanedAt" to LocalDateTime.now()
        )
        return ResponseEntity.ok(response)
    }
}

/**
 * 권한 확인 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/permissions")
@Tag(name = "Permission Check", description = "권한 확인 API")
class PermissionCheckController(
    private val permissionCheckService: PermissionCheckService
) {

    @Operation(summary = "사용자 권한 확인", description = "사용자의 특정 권한을 확인합니다")
    @PostMapping("/check")
    fun checkUserPermission(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CheckPermissionRequest,
        @RequestHeader("X-User-Id") userId: UUID,
        httpRequest: HttpServletRequest
    ): ResponseEntity<CheckPermissionResponse> {
        val ipAddress = getClientIpAddress(httpRequest)
        val userAgent = httpRequest.getHeader("User-Agent")
        
        val result = permissionCheckService.checkUserPermission(
            companyId = companyId,
            userId = request.userId,
            permissionCode = request.permissionCode,
            ipAddress = ipAddress,
            userAgent = userAgent
        )
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "리소스 권한 확인", description = "사용자의 리소스별 권한을 확인합니다")
    @PostMapping("/check-resource")
    fun checkResourcePermission(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: Map<String, Any>,
        @RequestHeader("X-User-Id") userId: UUID,
        httpRequest: HttpServletRequest
    ): ResponseEntity<CheckPermissionResponse> {
        val targetUserId = UUID.fromString(request["userId"] as String)
        val resourceType = ResourceType.valueOf(request["resourceType"] as String)
        val resourceId = UUID.fromString(request["resourceId"] as String)
        val permissionType = ResourcePermissionType.valueOf(request["permissionType"] as String)
        
        val ipAddress = getClientIpAddress(httpRequest)
        val userAgent = httpRequest.getHeader("User-Agent")
        
        val result = permissionCheckService.checkResourcePermission(
            companyId = companyId,
            userId = targetUserId,
            resourceType = resourceType,
            resourceId = resourceId,
            permissionType = permissionType,
            ipAddress = ipAddress,
            userAgent = userAgent
        )
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자 권한 요약 조회", description = "사용자의 권한 요약 정보를 조회합니다")
    @GetMapping("/users/{targetUserId}/summary")
    fun getUserPermissionSummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<UserPermissionSummaryDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionCheckService.getUserPermissionSummary(targetUserId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "내 권한 요약 조회", description = "현재 사용자의 권한 요약 정보를 조회합니다")
    @GetMapping("/my-summary")
    fun getMyPermissionSummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<UserPermissionSummaryDto> {
        val result = permissionCheckService.getUserPermissionSummary(userId)
        return ResponseEntity.ok(result)
    }

    /**
     * 클라이언트 IP 주소 추출
     */
    private fun getClientIpAddress(request: HttpServletRequest): String? {
        val xForwardedFor = request.getHeader("X-Forwarded-For")
        if (!xForwardedFor.isNullOrBlank()) {
            return xForwardedFor.split(",")[0].trim()
        }
        
        val xRealIp = request.getHeader("X-Real-IP")
        if (!xRealIp.isNullOrBlank()) {
            return xRealIp
        }
        
        return request.remoteAddr
    }
}

/**
 * 리소스 권한 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/resource-permissions")
@Tag(name = "Resource Permission Management", description = "리소스 권한 관리 API")
class ResourcePermissionController(
    private val resourcePermissionService: ResourcePermissionService,
    private val permissionCheckService: PermissionCheckService
) {

    @Operation(summary = "리소스 권한 부여", description = "사용자에게 리소스별 권한을 부여합니다")
    @PostMapping
    fun grantResourcePermission(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: GrantResourcePermissionRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<ResourcePermissionDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_ASSIGN")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = resourcePermissionService.grantResourcePermission(companyId, request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "리소스 권한 제거", description = "사용자의 리소스별 권한을 제거합니다")
    @DeleteMapping
    fun revokeResourcePermission(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestParam targetUserId: UUID,
        @RequestParam resourceType: ResourceType,
        @RequestParam resourceId: UUID,
        @RequestParam permissionType: ResourcePermissionType,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_ASSIGN")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val success = resourcePermissionService.revokeResourcePermission(
            companyId, targetUserId, resourceType, resourceId, permissionType, userId
        )
        
        val response = mapOf(
            "success" to success,
            "message" to if (success) "리소스 권한이 제거되었습니다" else "제거할 권한을 찾을 수 없습니다"
        )
        return ResponseEntity.ok(response)
    }

    @Operation(summary = "사용자의 리소스 권한 조회", description = "사용자의 모든 리소스 권한을 조회합니다")
    @GetMapping("/users/{targetUserId}")
    fun getUserResourcePermissions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<ResourcePermissionDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = resourcePermissionService.getUserResourcePermissions(targetUserId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자의 활성 리소스 권한 조회", description = "사용자의 활성 리소스 권한을 조회합니다")
    @GetMapping("/users/{targetUserId}/active")
    fun getActiveUserResourcePermissions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<ResourcePermissionDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = resourcePermissionService.getActiveUserResourcePermissions(targetUserId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "리소스별 권한 조회", description = "특정 리소스의 모든 권한을 조회합니다")
    @GetMapping("/resources")
    fun getResourcePermissions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestParam resourceType: ResourceType,
        @RequestParam resourceId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<ResourcePermissionDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = resourcePermissionService.getResourcePermissions(resourceType, resourceId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "만료된 리소스 권한 정리", description = "만료된 리소스 권한을 정리합니다")
    @PostMapping("/cleanup-expired")
    fun cleanupExpiredResourcePermissions(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "SYSTEM_CONFIG")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val cleanedCount = resourcePermissionService.cleanupExpiredResourcePermissions()
        val response = mapOf(
            "cleanedCount" to cleanedCount,
            "message" to "${cleanedCount}개의 만료된 리소스 권한이 정리되었습니다",
            "cleanedAt" to LocalDateTime.now()
        )
        return ResponseEntity.ok(response)
    }
}