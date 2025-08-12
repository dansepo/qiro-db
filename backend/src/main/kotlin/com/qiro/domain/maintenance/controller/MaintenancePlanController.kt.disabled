package com.qiro.domain.maintenance.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.service.MaintenancePlanService
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
import java.util.*
import jakarta.validation.Valid

/**
 * 정비 계획 관리 컨트롤러
 * 정비 계획 CRUD 및 일정 관리 API
 */
@Tag(name = "정비 계획 관리", description = "예방 정비 계획 관리 API")
@RestController
@RequestMapping("/api/v1/maintenance/plans")
@PreAuthorize("hasRole('USER')")
class MaintenancePlanController(
    private val maintenancePlanService: MaintenancePlanService
) {

    /**
     * 정비 계획 생성
     */
    @Operation(
        summary = "정비 계획 생성",
        description = "새로운 예방 정비 계획을 생성합니다."
    )
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun createMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: CreateMaintenancePlanRequest
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val plan = maintenancePlanService.createMaintenancePlan(
            request = request.copy(
                companyId = userPrincipal.companyId,
                createdBy = userPrincipal.userId
            )
        )
        return ResponseEntity.ok(ApiResponse.success(plan, "정비 계획이 성공적으로 생성되었습니다."))
    }

    /**
     * 정비 계획 상세 조회
     */
    @Operation(
        summary = "정비 계획 상세 조회",
        description = "특정 정비 계획의 상세 정보를 조회합니다."
    )
    @GetMapping("/{planId}")
    fun getMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val plan = maintenancePlanService.getMaintenancePlan(
            companyId = userPrincipal.companyId,
            planId = planId
        )
        return ResponseEntity.ok(ApiResponse.success(plan))
    }

    /**
     * 정비 계획 목록 조회
     */
    @Operation(
        summary = "정비 계획 목록 조회",
        description = "정비 계획 목록을 페이징하여 조회합니다."
    )
    @GetMapping
    fun getMaintenancePlans(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "계획 상태") @RequestParam(required = false) planStatus: String?,
        @Parameter(description = "승인 상태") @RequestParam(required = false) approvalStatus: String?,
        @Parameter(description = "계획 유형") @RequestParam(required = false) planType: String?,
        @Parameter(description = "정비 전략") @RequestParam(required = false) maintenanceStrategy: String?,
        @Parameter(description = "유효일 시작") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) effectiveDateFrom: LocalDate?,
        @Parameter(description = "유효일 종료") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) effectiveDateTo: LocalDate?,
        @Parameter(description = "검토일 시작") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) reviewDateFrom: LocalDate?,
        @Parameter(description = "검토일 종료") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) reviewDateTo: LocalDate?,
        @Parameter(description = "검색 키워드") @RequestParam(required = false) searchKeyword: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val filter = MaintenancePlanFilter(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            planStatus = planStatus?.let { PlanStatus.valueOf(it) },
            approvalStatus = approvalStatus?.let { ApprovalStatus.valueOf(it) },
            planType = planType?.let { MaintenancePlanType.valueOf(it) },
            maintenanceStrategy = maintenanceStrategy?.let { MaintenanceStrategy.valueOf(it) },
            effectiveDateFrom = effectiveDateFrom,
            effectiveDateTo = effectiveDateTo,
            reviewDateFrom = reviewDateFrom,
            reviewDateTo = reviewDateTo,
            searchKeyword = searchKeyword
        )
        val plans = maintenancePlanService.getMaintenancePlans(filter, pageable)
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 정비 계획 업데이트
     */
    @Operation(
        summary = "정비 계획 업데이트",
        description = "기존 정비 계획을 업데이트합니다."
    )
    @PutMapping("/{planId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun updateMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Valid @RequestBody request: UpdateMaintenancePlanRequest
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val plan = maintenancePlanService.updateMaintenancePlan(
            companyId = userPrincipal.companyId,
            planId = planId,
            request = request.copy(updatedBy = userPrincipal.userId)
        )
        return ResponseEntity.ok(ApiResponse.success(plan, "정비 계획이 성공적으로 업데이트되었습니다."))
    }

    /**
     * 정비 계획 삭제
     */
    @Operation(
        summary = "정비 계획 삭제",
        description = "정비 계획을 삭제합니다."
    )
    @DeleteMapping("/{planId}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun deleteMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID
    ): ResponseEntity<ApiResponse<Void>> {
        maintenancePlanService.deleteMaintenancePlan(
            companyId = userPrincipal.companyId,
            planId = planId
        )
        return ResponseEntity.ok(ApiResponse.success(null, "정비 계획이 성공적으로 삭제되었습니다."))
    }

    /**
     * 정비 계획 승인
     */
    @Operation(
        summary = "정비 계획 승인",
        description = "정비 계획을 승인하거나 거부합니다."
    )
    @PostMapping("/{planId}/approve")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun approveMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Valid @RequestBody request: ApprovePlanRequest
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val plan = maintenancePlanService.approveMaintenancePlan(
            companyId = userPrincipal.companyId,
            planId = planId,
            request = request.copy(approvedBy = userPrincipal.userId)
        )
        return ResponseEntity.ok(ApiResponse.success(plan, "정비 계획 승인이 처리되었습니다."))
    }

    /**
     * 정비 계획 활성화/비활성화
     */
    @Operation(
        summary = "정비 계획 활성화/비활성화",
        description = "정비 계획의 활성 상태를 변경합니다."
    )
    @PostMapping("/{planId}/toggle-status")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun togglePlanStatus(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "새로운 상태") @RequestParam planStatus: String
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val plan = maintenancePlanService.updatePlanStatus(
            companyId = userPrincipal.companyId,
            planId = planId,
            planStatus = PlanStatus.valueOf(planStatus),
            updatedBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(plan, "정비 계획 상태가 변경되었습니다."))
    }

    /**
     * 자산별 정비 계획 조회
     */
    @Operation(
        summary = "자산별 정비 계획 조회",
        description = "특정 자산의 정비 계획을 조회합니다."
    )
    @GetMapping("/asset/{assetId}")
    fun getMaintenancePlansByAsset(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: UUID,
        @Parameter(description = "계획 상태") @RequestParam(required = false) planStatus: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val plans = maintenancePlanService.getMaintenancePlansByAsset(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            planStatus = planStatus?.let { PlanStatus.valueOf(it) },
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 정비 계획 요약 조회
     */
    @Operation(
        summary = "정비 계획 요약 조회",
        description = "정비 계획의 요약 정보를 조회합니다."
    )
    @GetMapping("/summary")
    fun getMaintenancePlanSummary(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?,
        @Parameter(description = "계획 상태") @RequestParam(required = false) planStatus: String?,
        @PageableDefault(size = 50) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanSummaryDto>>> {
        val summary = maintenancePlanService.getMaintenancePlanSummary(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            planStatus = planStatus?.let { PlanStatus.valueOf(it) },
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(summary))
    }

    /**
     * 정비 계획 통계
     */
    @Operation(
        summary = "정비 계획 통계",
        description = "정비 계획 관련 통계를 조회합니다."
    )
    @GetMapping("/statistics")
    fun getMaintenancePlanStatistics(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?
    ): ResponseEntity<ApiResponse<MaintenancePlanStatisticsDto>> {
        val statistics = maintenancePlanService.getMaintenancePlanStatistics(
            companyId = userPrincipal.companyId,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }

    /**
     * 승인 대기 중인 계획 조회
     */
    @Operation(
        summary = "승인 대기 중인 계획 조회",
        description = "승인 대기 중인 정비 계획을 조회합니다."
    )
    @GetMapping("/pending-approval")
    fun getPendingApprovalPlans(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val plans = maintenancePlanService.getPendingApprovalPlans(
            companyId = userPrincipal.companyId,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 검토 기한이 임박한 계획 조회
     */
    @Operation(
        summary = "검토 기한이 임박한 계획 조회",
        description = "검토 기한이 임박한 정비 계획을 조회합니다."
    )
    @GetMapping("/review-due")
    fun getReviewDuePlans(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "기준일로부터 며칠 이내") @RequestParam(defaultValue = "30") daysAhead: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val plans = maintenancePlanService.getReviewDuePlans(
            companyId = userPrincipal.companyId,
            daysAhead = daysAhead,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 효과성이 낮은 계획 조회
     */
    @Operation(
        summary = "효과성이 낮은 계획 조회",
        description = "효과성 점수가 낮은 정비 계획을 조회합니다."
    )
    @GetMapping("/low-effectiveness")
    fun getLowEffectivenessPlans(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "효과성 임계값") @RequestParam(defaultValue = "70") effectivenessThreshold: Double,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val plans = maintenancePlanService.getLowEffectivenessPlans(
            companyId = userPrincipal.companyId,
            effectivenessThreshold = effectivenessThreshold.toBigDecimal(),
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 예산 초과 위험 계획 조회
     */
    @Operation(
        summary = "예산 초과 위험 계획 조회",
        description = "예산 초과 위험이 있는 정비 계획을 조회합니다."
    )
    @GetMapping("/budget-risk")
    fun getBudgetRiskPlans(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "예산 초과 임계값 (%)") @RequestParam(defaultValue = "90") budgetThreshold: Double,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<MaintenancePlanDto>>> {
        val plans = maintenancePlanService.getBudgetRiskPlans(
            companyId = userPrincipal.companyId,
            budgetThreshold = budgetThreshold,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(plans))
    }

    /**
     * 정비 계획 복사
     */
    @Operation(
        summary = "정비 계획 복사",
        description = "기존 정비 계획을 복사하여 새로운 계획을 생성합니다."
    )
    @PostMapping("/{planId}/copy")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun copyMaintenancePlan(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "원본 계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "새로운 계획명") @RequestParam newPlanName: String,
        @Parameter(description = "새로운 계획 코드") @RequestParam newPlanCode: String,
        @Parameter(description = "대상 자산 ID") @RequestParam(required = false) targetAssetId: UUID?
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val copiedPlan = maintenancePlanService.copyMaintenancePlan(
            companyId = userPrincipal.companyId,
            sourcePlanId = planId,
            newPlanName = newPlanName,
            newPlanCode = newPlanCode,
            targetAssetId = targetAssetId,
            createdBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(copiedPlan, "정비 계획이 성공적으로 복사되었습니다."))
    }

    /**
     * 정비 계획 템플릿 생성
     */
    @Operation(
        summary = "정비 계획 템플릿 생성",
        description = "기존 정비 계획을 템플릿으로 저장합니다."
    )
    @PostMapping("/{planId}/create-template")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun createPlanTemplate(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "계획 ID") @PathVariable planId: UUID,
        @Parameter(description = "템플릿명") @RequestParam templateName: String,
        @Parameter(description = "템플릿 설명") @RequestParam(required = false) templateDescription: String?
    ): ResponseEntity<ApiResponse<MaintenancePlanDto>> {
        val template = maintenancePlanService.createPlanTemplate(
            companyId = userPrincipal.companyId,
            planId = planId,
            templateName = templateName,
            templateDescription = templateDescription,
            createdBy = userPrincipal.userId
        )
        return ResponseEntity.ok(ApiResponse.success(template, "정비 계획 템플릿이 생성되었습니다."))
    }

    /**
     * 정비 계획 대시보드
     */
    @Operation(
        summary = "정비 계획 대시보드",
        description = "정비 계획 관리를 위한 대시보드 데이터를 조회합니다."
    )
    @GetMapping("/dashboard")
    fun getMaintenancePlanDashboard(
        @CurrentUser userPrincipal: CustomUserPrincipal
    ): ResponseEntity<ApiResponse<MaintenancePlanDashboardDto>> {
        val dashboard = maintenancePlanService.getMaintenancePlanDashboard(userPrincipal.companyId)
        return ResponseEntity.ok(ApiResponse.success(dashboard))
    }

    /**
     * 정비 계획 캘린더 뷰
     */
    @Operation(
        summary = "정비 계획 캘린더 뷰",
        description = "정비 계획을 캘린더 형태로 조회합니다."
    )
    @GetMapping("/calendar")
    fun getMaintenancePlanCalendar(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "조회 년도") @RequestParam year: Int,
        @Parameter(description = "조회 월") @RequestParam month: Int,
        @Parameter(description = "자산 ID") @RequestParam(required = false) assetId: UUID?
    ): ResponseEntity<ApiResponse<List<MaintenancePlanCalendarDto>>> {
        val calendar = maintenancePlanService.getMaintenancePlanCalendar(
            companyId = userPrincipal.companyId,
            year = year,
            month = month,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(calendar))
    }
}

/**
 * 정비 계획 대시보드 DTO
 */
data class MaintenancePlanDashboardDto(
    val statistics: MaintenancePlanStatisticsDto,
    val pendingApprovalPlans: List<MaintenancePlanSummaryDto>,
    val reviewDuePlans: List<MaintenancePlanSummaryDto>,
    val lowEffectivenessPlans: List<MaintenancePlanSummaryDto>,
    val budgetRiskPlans: List<MaintenancePlanSummaryDto>,
    val recentlyCreatedPlans: List<MaintenancePlanSummaryDto>,
    val upcomingExecutions: List<NextMaintenanceScheduleDto>
)

/**
 * 정비 계획 캘린더 DTO
 */
data class MaintenancePlanCalendarDto(
    val date: LocalDate,
    val plans: List<MaintenancePlanCalendarItemDto>
)

/**
 * 정비 계획 캘린더 항목 DTO
 */
data class MaintenancePlanCalendarItemDto(
    val planId: UUID,
    val planName: String,
    val assetId: UUID,
    val assetName: String,
    val planType: MaintenancePlanType,
    val priority: ExecutionPriority,
    val estimatedDurationHours: java.math.BigDecimal,
    val assignedTo: UUID?,
    val assigneeName: String?
)