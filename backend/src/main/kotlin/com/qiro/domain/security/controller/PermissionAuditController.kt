package com.qiro.domain.security.controller

import com.qiro.domain.security.dto.*
import com.qiro.domain.security.service.*
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*

/**
 * 권한 감사 로그 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/companies/{companyId}/audit-logs")
@Tag(name = "Permission Audit", description = "권한 감사 로그 API")
class PermissionAuditController(
    private val permissionAuditService: PermissionAuditService,
    private val permissionCheckService: PermissionCheckService
) {

    @Operation(summary = "회사별 감사 로그 조회", description = "회사의 모든 감사 로그를 조회합니다")
    @GetMapping
    fun getCompanyAuditLogs(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getCompanyAuditLogs(companyId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "사용자별 감사 로그 조회", description = "특정 사용자의 감사 로그를 조회합니다")
    @GetMapping("/users/{targetUserId}")
    fun getUserAuditLogs(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "대상 사용자 ID") @PathVariable targetUserId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getUserAuditLogs(targetUserId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "액션별 감사 로그 조회", description = "특정 액션의 감사 로그를 조회합니다")
    @GetMapping("/actions/{action}")
    fun getAuditLogsByAction(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "액션") @PathVariable action: AuditAction,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getAuditLogsByAction(companyId, action, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "실패한 접근 시도 조회", description = "실패한 접근 시도 로그를 조회합니다")
    @GetMapping("/failed-attempts")
    fun getFailedAccessAttempts(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getFailedAccessAttempts(companyId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "기간별 감사 로그 조회", description = "특정 기간의 감사 로그를 조회합니다")
    @GetMapping("/period")
    fun getAuditLogsByPeriod(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "시작일시") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime,
        @Parameter(description = "종료일시") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getAuditLogsByPeriod(companyId, startDate, endDate, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "권한 통계 조회", description = "회사의 권한 관련 통계를 조회합니다")
    @GetMapping("/statistics")
    fun getPermissionStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<PermissionStatisticsDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val result = permissionAuditService.getPermissionStatistics(companyId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "내 감사 로그 조회", description = "현재 사용자의 감사 로그를 조회합니다")
    @GetMapping("/my-logs")
    fun getMyAuditLogs(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<PermissionAuditLogDto>> {
        val result = permissionAuditService.getUserAuditLogs(userId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "감사 로그 수동 기록", description = "수동으로 감사 로그를 기록합니다")
    @PostMapping
    fun logAudit(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestBody request: Map<String, Any>,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<PermissionAuditLogDto> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val targetUserId = UUID.fromString(request["targetUserId"] as String)
        val action = AuditAction.valueOf(request["action"] as String)
        val resourceType = request["resourceType"]?.let { ResourceType.valueOf(it as String) }
        val resourceId = request["resourceId"]?.let { UUID.fromString(it as String) }
        val permissionCode = request["permissionCode"] as String?
        val success = request["success"] as Boolean? ?: true
        val errorMessage = request["errorMessage"] as String?
        
        val result = permissionAuditService.logAudit(
            companyId = companyId,
            userId = targetUserId,
            action = action,
            resourceType = resourceType,
            resourceId = resourceId,
            permissionCode = permissionCode,
            success = success,
            errorMessage = errorMessage,
            performedBy = userId
        )
        
        return ResponseEntity.status(HttpStatus.CREATED).body(result)
    }

    @Operation(summary = "보안 이벤트 요약", description = "최근 보안 이벤트 요약을 조회합니다")
    @GetMapping("/security-summary")
    fun getSecurityEventSummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "조회 기간 (시간)") @RequestParam(defaultValue = "24") hours: Int,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<Map<String, Any>> {
        // 권한 확인
        val permissionCheck = permissionCheckService.checkUserPermission(companyId, userId, "AUDIT_LOG_READ")
        if (!permissionCheck.hasPermission) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build()
        }
        
        val endDate = LocalDateTime.now()
        val startDate = endDate.minusHours(hours.toLong())
        
        val auditLogs = permissionAuditService.getAuditLogsByPeriod(
            companyId, startDate, endDate, 
            org.springframework.data.domain.PageRequest.of(0, 1000)
        ).content
        
        val summary = mapOf(
            "period" to "${hours}시간",
            "totalEvents" to auditLogs.size,
            "successfulEvents" to auditLogs.count { it.success },
            "failedEvents" to auditLogs.count { !it.success },
            "uniqueUsers" to auditLogs.map { it.userId }.distinct().size,
            "topActions" to auditLogs.groupBy { it.action }
                .mapValues { it.value.size }
                .toList()
                .sortedByDescending { it.second }
                .take(5),
            "recentFailures" to auditLogs
                .filter { !it.success }
                .sortedByDescending { it.performedAt }
                .take(10)
                .map { mapOf(
                    "userId" to it.userId,
                    "action" to it.action,
                    "errorMessage" to it.errorMessage,
                    "performedAt" to it.performedAt
                ) },
            "generatedAt" to LocalDateTime.now()
        )
        
        return ResponseEntity.ok(summary)
    }
}