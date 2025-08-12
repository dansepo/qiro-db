package com.qiro.common.config

import com.qiro.common.dto.ApiResponse
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*

/**
 * 설정 관리 컨트롤러
 */
@Tag(name = "Configuration", description = "설정 관리 API")
@RestController
@RequestMapping("/api/v1/admin/config")
@PreAuthorize("hasRole('ADMIN')")
class ConfigurationController(
    private val configurationRefreshService: ConfigurationRefreshService
) {

    @Operation(summary = "현재 설정 조회", description = "현재 애플리케이션 설정을 조회합니다.")
    @GetMapping
    fun getCurrentConfiguration(): ResponseEntity<ApiResponse<Map<String, Any>>> {
        val configuration = configurationRefreshService.getCurrentConfiguration()
        
        return ResponseEntity.ok(
            ApiResponse.success(configuration)
        )
    }

    @Operation(summary = "설정 갱신", description = "애플리케이션 설정을 갱신합니다.")
    @PostMapping("/refresh")
    fun refreshConfiguration(): ResponseEntity<ApiResponse<ConfigurationRefreshResult>> {
        val result = configurationRefreshService.refreshConfiguration()
        
        return ResponseEntity.ok(
            ApiResponse.success(result, "설정 갱신이 ${if (result.success) "성공" else "실패"}했습니다.")
        )
    }

    @Operation(summary = "설정 검증", description = "현재 설정의 유효성을 검증합니다.")
    @PostMapping("/validate")
    fun validateConfiguration(): ResponseEntity<ApiResponse<ConfigurationValidationResult>> {
        val result = configurationRefreshService.validateConfiguration()
        
        return ResponseEntity.ok(
            ApiResponse.success(result, "설정 검증이 완료되었습니다.")
        )
    }

    @Operation(summary = "설정 롤백", description = "설정을 이전 상태로 롤백합니다.")
    @PostMapping("/rollback")
    fun rollbackConfiguration(): ResponseEntity<ApiResponse<ConfigurationRollbackResult>> {
        val result = configurationRefreshService.rollbackConfiguration()
        
        return ResponseEntity.ok(
            ApiResponse.success(result, "설정 롤백이 ${if (result.success) "성공" else "실패"}했습니다.")
        )
    }
}