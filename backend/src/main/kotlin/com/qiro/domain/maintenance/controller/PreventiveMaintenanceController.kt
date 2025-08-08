package com.qiro.domain.maintenance.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.PreventiveMaintenanceService
import com.qiro.security.CustomUserPrincipal
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 예방 정비 실행 컨트롤러
 * 정비 실행 및 결과 기록, 정비 이력 조회 API
 */
@Tag(name = "예방 정비 실행", description = "예방 정비 실행 및 이력 관리 API")
@RestController
@RequestMapping("/api/v1/maintenance/executions")
@PreAuthorize("hasRole('USER')")
class PreventiveMaintenanceController(
    private val preventiveMaintenanceService: PreventiveMaintenanceService
) {

    /**
     * 정비 실행 생성
     */
    @Operation(
        summary = "정비 실행 생성",
        description = "정비 계획을 기반으로 새로운 정비 실행을 생성합니다."
    )
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun createMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: CreateMaintenanceExecutionRequest
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.createMaintenanceExecution(
            companyId = userPrincipal.companyId,
            request = request,
            createdBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 성공적으로 생성되었습니다."))
    }

    /**
     * 정비 실행 시작
     */
    @Operation(
        summary = "정비 실행 시작",
        description = "예정된 정비 실행을 시작합니다."
    )
    @PostMapping("/{executionId}/start")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun startMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID,
        @Valid @RequestBody request: StartMaintenanceExecutionRequest
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.startMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId,
            request = request,
            startedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 시작되었습니다."))
    }

    /**
     * 정비 실행 완료
     */
    @Operation(
        summary = "정비 실행 완료",
        description = "진행 중인 정비 실행을 완료합니다."
    )
    @PostMapping("/{executionId}/complete")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun completeMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID,
        @Valid @RequestBody request: CompleteMaintenanceExecutionRequest
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.completeMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId,
            request = request,
            completedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 완료되었습니다."))
    }

    /**
     * 정비 실행 일시 중지
     */
    @Operation(
        summary = "정비 실행 일시 중지",
        description = "진행 중인 정비 실행을 일시 중지합니다."
    )
    @PostMapping("/{executionId}/pause")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun pauseMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID,
        @Parameter(description = "중지 사유") @RequestParam reason: String
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.pauseMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId,
            reason = reason,
            pausedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 일시 중지되었습니다."))
    }

    /**
     * 정비 실행 재개
     */
    @Operation(
        summary = "정비 실행 재개",
        description = "일시 중지된 정비 실행을 재개합니다."
    )
    @PostMapping("/{executionId}/resume")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun resumeMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID,
        @Parameter(description = "재개 사유") @RequestParam(required = false) reason: String?
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.resumeMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId,
            reason = reason,
            resumedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 재개되었습니다."))
    }

    /**
     * 정비 실행 취소
     */
    @Operation(
        summary = "정비 실행 취소",
        description = "정비 실행을 취소합니다."
    )
    @PostMapping("/{executionId}/cancel")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun cancelMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID,
        @Parameter(description = "취소 사유") @RequestParam reason: String
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.cancelMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId,
            reason = reason,
            cancelledBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(execution, "정비 실행이 취소되었습니다."))
    }

    /**
     * 정비 실행 상세 조회
     */
    @Operation(
        summary = "정비 실행 상세 조회",
        description = "특정 정비 실행의 상세 정보를 조회합니다."
    )
    @GetMapping("/{executionId}")
    fun getMaintenanceExecution(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "실행 ID") @PathVariable executionId: UUID
    ): ResponseEntity<ApiResponse<PreventiveMaintenanceExecutionDto>> {
        val execution = preventiveMaintenanceService.getMaintenanceExecution(
            companyId = userPrincipal.companyId,
            executionId = executionId
        )
        return ResponseEntity.ok(ApiResponse.success(execution))
    }

    /**
     * 정비 실행 목록 조회
     */
    @Operation(
        summary = "정비 실행 목록 조회",
        description = "정비 실행 목록을 페이징하여 조회합니다."
    )
    @GetMapping
    fun getMaintenanceExecutions(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "계획 ID") @RequestParam(required = false) planId: UUID?,
        @Parameter(description = "실행 상태") @RequestParam(required = false) executionStatus: String?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @Parameter(description = "담당자 ID") @RequestParam(required = false) assignedTo: UUID?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<PreventiveMaintenanceExecutionDto>>> {
        val filter = MaintenanceExecutionFilter(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            planId = planId,
            executionStatus = executionStatus,
            startDate = startDate,
            endDate = endDate,
            assignedTo = assignedTo
        )
        val executions = preventiveMaintenanceService.getMaintenanceExecutions(filter, pageable)
        return ResponseEntity.ok(ApiResponse.success(executions))
    }

    /**
     * 자산별 정비 이력 조회
     */
    @Operation(
        summary = "자산별 정비 이력 조회",
        description = "특정 자산의 정비 실행 이력을 조회합니다."
    )
    @GetMapping("/asset/{assetId}/history")
    fun getAssetMaintenanceHistory(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: UUID,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<PreventiveMaintenanceExecutionDto>>> {
        val history = preventiveMaintenanceService.getAssetMaintenanceHistory(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            startDate = startDate,
            endDate = endDate,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(history))
    }

    /**
     * 계획별 정비 이력 조회
     */
    @Operation(
        summary = "계획별 정비 이력 조회",
        description = "특정 정비 계획의 실행 이력을 조회합니다."
    )
    @GetMapping("/plan/{planId}/history")
    fun getPlanMaintenanceHistory(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<PreventiveMaintenanceExecutionDto>>> {
        val history = preventiveMaintenanceService.getPlanMaintenanceHistory(
            companyId = userPrincipal.companyId,
            planId = planId,
            startDate = startDate,
            endDate = endDate,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(history))
    }

    /**
     * 다음 정비 일정 계산
     */
    @Operation(
        summary = "다음 정비 일정 계산",
        description = "정비 계획을 기반으로 다음 정비 일정을 계산합니다."
    )
    @GetMapping("/plan/{planId}/next-schedule")
    fun calculateNextMaintenanceSchedule(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "기준일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) baseDate: LocalDate?
    ): ResponseEntity<ApiResponse<NextMaintenanceScheduleDto>> {
        val nextSchedule = preventiveMaintenanceService.calculateNextMaintenanceSchedule(
            companyId = userPrincipal.companyId,
            planId = planId,
            baseDate = baseDate ?: LocalDate.now()
        )
        return ResponseEntity.ok(ApiResponse.success(nextSchedule))
    }

    /**
     * 정비 효과성 분석
     */
    @Operation(
        summary = "정비 효과성 분석",
        description = "정비 계획의 효과성을 분석합니다."
    )
    @GetMapping("/plan/{planId}/effectiveness")
    fun analyzeMaintenanceEffectiveness(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "분석 기간(개월)") @RequestParam(defaultValue = "12") months: Int
    ): ResponseEntity<ApiResponse<MaintenanceEffectivenessDto>> {
        val effectiveness = preventiveMaintenanceService.analyzeMaintenanceEffectiveness(
            companyId = userPrincipal.companyId,
            planId = planId,
            months = months
        )
        return ResponseEntity.ok(ApiResponse.success(effectiveness))
    }

    /**
     * 정비 실행 통계
     */
    @Operation(
        summary = "정비 실행 통계",
        description = "정비 실행 관련 통계를 조회합니다."
    )
    @GetMapping("/statistics")
    fun getMaintenanceExecutionStatistics(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) startDate: LocalDate?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) endDate: LocalDate?,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?
    ): ResponseEntity<ApiResponse<MaintenanceExecutionStatisticsDto>> {
        val statistics = preventiveMaintenanceService.getMaintenanceExecutionStatistics(
            companyId = userPrincipal.companyId,
            startDate = startDate,
            endDate = endDate,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    /**
     * 오늘 예정된 정비 조회
     */
    @Operation(
        summary = "오늘 예정된 정비 조회",
        description = "오늘 실행 예정인 정비 작업을 조회합니다."
    )
    @GetMapping("/today")
    fun getTodayMaintenanceExecutions(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<List<PreventiveMaintenanceExecutionDto>>> {
        val executions = preventiveMaintenanceService.getTodayMaintenanceExecutions(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(executions))
    }

    /**
     * 지연된 정비 조회
     */
    @Operation(
        summary = "지연된 정비 조회",
        description = "예정일을 초과한 정비 작업을 조회합니다."
    )
    @GetMapping("/overdue")
    fun getOverdueMaintenanceExecutions(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<List<PreventiveMaintenanceExecutionDto>>> {
        val executions = preventiveMaintenanceService.getOverdueMaintenanceExecutions(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(executions))
    }

    /**
     * 진행 중인 정비 조회
     */
    @Operation(
        summary = "진행 중인 정비 조회",
        description = "현재 진행 중인 정비 작업을 조회합니다."
    )
    @GetMapping("/in-progress")
    fun getInProgressMaintenanceExecutions(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<List<PreventiveMaintenanceExecutionDto>>> {
        val executions = preventiveMaintenanceService.getInProgressMaintenanceExecutions(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(executions))
    }

    /**
     * 담당자별 정비 작업 조회
     */
    @Operation(
        summary = "담당자별 정비 작업 조회",
        description = "특정 담당자에게 할당된 정비 작업을 조회합니다."
    )
    @GetMapping("/assignee/{assigneeId}")
    fun getMaintenanceExecutionsByAssignee(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "담당자 ID") @PathVariable assigneeId: UUID,
        @Parameter(description = "실행 상태") @RequestParam(required = false) executionStatus: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<PreventiveMaintenanceExecutionDto>>> {
        val executions = preventiveMaintenanceService.getMaintenanceExecutionsByAssignee(
            companyId = userPrincipal.companyId,
            assigneeId = assigneeId,
            executionStatus = executionStatus,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(executions))
    }

    /**
     * 정비 실행 대시보드
     */
    @Operation(
        summary = "정비 실행 대시보드",
        description = "정비 실행 관리를 위한 대시보드 데이터를 조회합니다."
    )
    @GetMapping("/dashboard")
    fun getMaintenanceExecutionDashboard(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<MaintenanceExecutionDashboardDto>> {
        val dashboard = preventiveMaintenanceService.getMaintenanceExecutionDashboard(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(dashboard))
    }
}