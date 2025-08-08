package com.qiro.domain.cost.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.response.PageResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.service.CostAlertService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 비용 경고 관리 컨트롤러
 * 예산 초과 및 비용 관련 경고를 생성하고 관리하는 REST API
 */
@Tag(name = "비용 경고 관리", description = "예산 초과 및 비용 경고 관리 API")
@RestController
@RequestMapping("/api/v1/cost-alerts")
class CostAlertController(
    private val costAlertService: CostAlertService
) {
    
    @Operation(summary = "경고 생성", description = "새로운 비용 경고를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createAlert(
        @Valid @RequestBody request: CreateCostAlertRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostAlertDto> {
        val result = costAlertService.createAlert(request, currentUser)
        return ApiResponse.success(result, "경고가 성공적으로 생성되었습니다.")
    }
    
    @Operation(summary = "예산 임계값 경고 자동 생성", description = "예산 임계값을 초과한 경고를 자동으로 생성합니다.")
    @PostMapping("/generate-budget-threshold-alerts")
    fun generateBudgetThresholdAlerts(): ApiResponse<List<CostAlertDto>> {
        val result = costAlertService.generateBudgetThresholdAlerts()
        return ApiResponse.success(result, "${result.size}개의 예산 임계값 경고가 생성되었습니다.")
    }
    
    @Operation(summary = "경고 해결", description = "경고를 해결 상태로 변경합니다.")
    @PostMapping("/{alertId}/resolve")
    fun resolveAlert(
        @PathVariable alertId: UUID,
        @Valid @RequestBody request: ResolveCostAlertRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostAlertDto> {
        val result = costAlertService.resolveAlert(alertId, request, currentUser)
        return ApiResponse.success(result, "경고가 성공적으로 해결되었습니다.")
    }
    
    @Operation(summary = "경고 확인", description = "경고를 확인 상태로 변경합니다.")
    @PostMapping("/{alertId}/acknowledge")
    fun acknowledgeAlert(
        @PathVariable alertId: UUID,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostAlertDto> {
        val result = costAlertService.acknowledgeAlert(alertId, currentUser)
        return ApiResponse.success(result, "경고가 성공적으로 확인되었습니다.")
    }
    
    @Operation(summary = "경고 억제", description = "경고를 일정 시간 동안 억제합니다.")
    @PostMapping("/{alertId}/suppress")
    fun suppressAlert(
        @PathVariable alertId: UUID,
        @Valid @RequestBody request: SuppressCostAlertRequest,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<CostAlertDto> {
        val result = costAlertService.suppressAlert(alertId, request, currentUser)
        return ApiResponse.success(result, "경고가 성공적으로 억제되었습니다.")
    }
    
    @Operation(summary = "경고 에스컬레이션 처리", description = "장시간 미해결 경고의 에스컬레이션을 처리합니다.")
    @PostMapping("/process-escalations")
    fun processEscalations(): ApiResponse<List<CostAlertDto>> {
        val result = costAlertService.processEscalations()
        return ApiResponse.success(result, "${result.size}개의 경고가 에스컬레이션되었습니다.")
    }
    
    @Operation(summary = "억제된 경고 복원", description = "억제 기간이 만료된 경고를 복원합니다.")
    @PostMapping("/restore-suppressed")
    fun restoreSuppressedAlerts(): ApiResponse<List<CostAlertDto>> {
        val result = costAlertService.restoreSuppressedAlerts()
        return ApiResponse.success(result, "${result.size}개의 억제된 경고가 복원되었습니다.")
    }
    
    @Operation(summary = "경고 조회", description = "특정 경고를 조회합니다.")
    @GetMapping("/{alertId}")
    fun getAlert(@PathVariable alertId: UUID): ApiResponse<CostAlertDto> {
        val result = costAlertService.getAlert(alertId)
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "경고 목록 조회", description = "경고 목록을 조회합니다.")
    @GetMapping
    fun getAlerts(
        @RequestParam(required = false) alertTypes: List<String>?,
        @RequestParam(required = false) alertSeverities: List<String>?,
        @RequestParam(required = false) alertStatuses: List<String>?,
        @RequestParam(required = false) budgetId: UUID?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime?,
        @RequestParam(required = false) escalationLevel: Int?,
        @RequestParam(required = false) autoResolved: Boolean?,
        @RequestParam(required = false) notificationSent: Boolean?,
        @RequestParam(required = false) minRecurrenceCount: Int?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ApiResponse<PageResponse<CostAlertDto>> {
        // 필터 생성 (실제로는 별도 매퍼 클래스 사용 권장)
        val filter = if (alertTypes != null || alertSeverities != null || alertStatuses != null ||
                         budgetId != null || startDate != null || endDate != null ||
                         escalationLevel != null || autoResolved != null || notificationSent != null ||
                         minRecurrenceCount != null) {
            AlertFilterDto(
                budgetId = budgetId,
                startDate = startDate,
                endDate = endDate,
                escalationLevel = escalationLevel,
                autoResolved = autoResolved,
                notificationSent = notificationSent,
                minRecurrenceCount = minRecurrenceCount
                // 다른 필터들은 enum 변환 필요
            )
        } else null
        
        val result = costAlertService.getAlerts(filter, pageable)
        return ApiResponse.success(PageResponse.from(result))
    }
    
    @Operation(summary = "활성 경고 조회", description = "현재 활성 상태인 경고 목록을 조회합니다.")
    @GetMapping("/active")
    fun getActiveAlerts(): ApiResponse<List<CostAlertDto>> {
        val result = costAlertService.getActiveAlerts()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "위험 수준 경고 조회", description = "높음 또는 위험 수준의 경고 목록을 조회합니다.")
    @GetMapping("/critical")
    fun getCriticalAlerts(): ApiResponse<List<CostAlertDto>> {
        val result = costAlertService.getCriticalAlerts()
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "경고 대시보드 조회", description = "지정된 기간의 경고 대시보드 정보를 조회합니다.")
    @GetMapping("/dashboard")
    fun getAlertDashboard(
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime?,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime?
    ): ApiResponse<AlertDashboardDto> {
        val start = startDate ?: LocalDateTime.now().minusDays(30)
        val end = endDate ?: LocalDateTime.now()
        
        val result = costAlertService.getAlertDashboard(start, end)
        return ApiResponse.success(result)
    }
    
    @Operation(summary = "경고 삭제", description = "경고를 삭제합니다.")
    @DeleteMapping("/{alertId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun deleteAlert(
        @PathVariable alertId: UUID,
        @Parameter(hidden = true) @CurrentUser currentUser: UUID
    ): ApiResponse<Unit> {
        costAlertService.deleteAlert(alertId, currentUser)
        return ApiResponse.success(Unit, "경고가 성공적으로 삭제되었습니다.")
    }
}