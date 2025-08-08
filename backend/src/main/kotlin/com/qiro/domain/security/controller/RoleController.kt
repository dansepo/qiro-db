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
import java.util.*

/**
 * 역할 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/roles")
@Tag(name = "Role Management", description = "역할 관리 API")
class RoleController(
    private val roleService: RoleService,
    private val permissionCheckService: PermissionCheckService
) {

    @Operation(summary = "역할 생성", description = "새로운 역할을 생성합니다")
    @PostMapping
    fun createRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: CreateRoleRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<RoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_CREATE")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.createRole(companyId, request, userId)
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "역할 수정", description = "기존 역할을 수정합니다")
    @PutMapping("/{roleId}")
    fun updateRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestBody request: UpdateRoleRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<RoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_UPDATE")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.updateRole(roleId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할 조회", description = "특정 역할을 조회합니다")
    @GetMapping("/{roleId}")
    fun getRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<RoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.getRole(roleId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할 목록 조회", description = "회사의 모든 역할을 조회합니다")
    @GetMapping
    fun getRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<RoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.getRoles(companyId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "활성 역할 목록 조회", description = "활성 상태인 역할 목록을 조회합니다")
    @GetMapping("/active")
    fun getActiveRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<RoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.getActiveRoles(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할에 권한 부여", description = "역할에 권한을 부여합니다")
    @PostMapping("/{roleId}/permissions")
    fun grantPermissionsToRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestBody request: Map<String, List<String>>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<RoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_UPDATE")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val permissionCodes = request["permissionCodes"] ?: emptyList()
        val result = roleService.grantPermissionsToRole(roleId, permissionCodes, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할에서 권한 제거", description = "역할에서 권한을 제거합니다")
    @DeleteMapping("/{roleId}/permissions")
    fun revokePermissionsFromRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestBody request: Map<String, List<String>>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<RoleDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_UPDATE")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val permissionCodes = request["permissionCodes"] ?: emptyList()
        val result = roleService.revokePermissionsFromRole(roleId, permissionCodes)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할 삭제", description = "역할을 삭제합니다")
    @DeleteMapping("/{roleId}")
    fun deleteRole(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Void> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "ROLE_DELETE")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        roleService.deleteRole(roleId, userId)
        return ResponseEntity.noContent().build()
    }

    @Operation(summary = "사용자별 역할 조회", description = "특정 사용자의 역할을 조회합니다")
    @GetMapping("/users/{targetUserId}")
    fun getUserRoles(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<List<RoleDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "USER_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = roleService.getUserRoles(targetUserId)
        return ResponseEntity.ok(result)
    }
}

/**
 * 권한 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/permissions")
@Tag(name = "Permission Management", description = "권한 관리 API")
class PermissionController(
    private val permissionService: PermissionService
) {

    @Operation(summary = "모든 권한 조회", description = "시스템의 모든 권한을 조회합니다")
    @GetMapping
    fun getAllPermissions(): ResponseEntity<List<PermissionDto>> {
        val result = permissionService.getAllPermissions()
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "리소스별 권한 조회", description = "특정 리소스의 권한을 조회합니다")
    @GetMapping("/resources/{resource}")
    fun getPermissionsByResource(
        @Parameter(description = "리소스 타입") @PathVariable resource: String
    ): ResponseEntity<List<PermissionDto>> {
        val result = permissionService.getPermissionsByResource(resource)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "권한 코드로 조회", description = "권한 코드로 특정 권한을 조회합니다")
    @GetMapping("/{permissionCode}")
    fun getPermissionByCode(
        @Parameter(description = "권한 코드") @PathVariable permissionCode: String
    ): ResponseEntity<PermissionDto?> {
        val result = permissionService.getPermissionByCode(permissionCode)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "역할별 권한 조회", description = "특정 역할의 권한을 조회합니다")
    @GetMapping("/roles/{roleId}")
    fun getPermissionsByRole(
        @Parameter(description = "역할 ID") @PathVariable roleId: UUID
    ): ResponseEntity<List<PermissionDto>> {
        val result = permissionService.getPermissionsByRole(roleId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자별 권한 조회", description = "특정 사용자의 권한을 조회합니다")
    @GetMapping("/users/{userId}")
    fun getPermissionsByUser(
        @Parameter(description = "사용자 ID") @PathVariable userId: UUID
    ): ResponseEntity<List<PermissionDto>> {
        val result = permissionService.getPermissionsByUser(userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "권한 매트릭스 조회", description = "회사의 권한 매트릭스를 조회합니다")
    @GetMapping("/companies/{companyId}/matrix")
    fun getPermissionMatrix(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID
    ): ResponseEntity<PermissionMatrixDto> {
        val result = permissionService.getPermissionMatrix(companyId)
        return ResponseEntity.ok(result)
    }
}