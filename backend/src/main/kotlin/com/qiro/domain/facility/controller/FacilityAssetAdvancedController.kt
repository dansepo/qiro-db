package com.qiro.domain.facility.controller

import com.qiro.common.response.ApiResponse
import com.qiro.common.security.CurrentUser
import com.qiro.domain.facility.dto.*
import com.qiro.domain.facility.service.FacilityAssetAdvancedService
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
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 시설물 자산 고급 관리 컨트롤러
 * 자산 이력, 성능 분석, 수명 주기 관리 등 고급 기능 제공
 */
@RestController
@RequestMapping("/api/v1/facility/assets/advanced")
@Tag(name = "시설물 자산 고급 관리", description = "자산 이력, 성능 분석, 수명 주기 관리 API")
@PreAuthorize("hasRole('USER')")
class FacilityAssetAdvancedController(
    private val facilityAssetAdvancedService: FacilityAssetAdvancedService
) {

    /**
     * 자산 상세 정보 조회 (이력 포함)
     */
    @Operation(
        summary = "자산 상세 정보 조회",
        description = "자산의 상세 정보와 이력, 관련 작업 등을 포함하여 조회합니다."
    )
    @GetMapping("/{assetId}/detail")
    fun getAssetDetail(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long
    ): ResponseEntity<ApiResponse<FacilityAssetDetailDto>> {
        val detail = facilityAssetAdvancedService.getAssetDetail(
            companyId = userPrincipal.companyId,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(detail))
    }

    /**
     * 자산 이력 조회
     */
    @Operation(
        summary = "자산 이력 조회",
        description = "특정 자산의 변경 이력을 조회합니다."
    )
    @GetMapping("/{assetId}/history")
    fun getAssetHistory(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long,
        @Parameter(description = "변경 유형") @RequestParam(required = false) changeType: String?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<FacilityAssetHistoryDto>>> {
        val history = facilityAssetAdvancedService.getAssetHistory(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            changeType = changeType?.let { AssetChangeType.valueOf(it) },
            startDate = startDate,
            endDate = endDate,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(history))
    }

    /**
     * 자산 성능 지표 조회
     */
    @Operation(
        summary = "자산 성능 지표 조회",
        description = "자산의 성능 지표를 조회합니다."
    )
    @GetMapping("/{assetId}/performance")
    fun getAssetPerformanceMetrics(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long,
        @Parameter(description = "분석 기간(개월)") @RequestParam(defaultValue = "12") months: Int
    ): ResponseEntity<ApiResponse<AssetPerformanceMetricsDto>> {
        val metrics = facilityAssetAdvancedService.getAssetPerformanceMetrics(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            months = months
        )
        return ResponseEntity.ok(ApiResponse.success(metrics))
    }

    /**
     * 자산 수명 주기 분석
     */
    @Operation(
        summary = "자산 수명 주기 분석",
        description = "자산의 수명 주기를 분석합니다."
    )
    @GetMapping("/{assetId}/lifecycle")
    fun getAssetLifecycleAnalysis(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long
    ): ResponseEntity<ApiResponse<AssetLifecycleAnalysisDto>> {
        val analysis = facilityAssetAdvancedService.getAssetLifecycleAnalysis(
            companyId = userPrincipal.companyId,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(analysis))
    }

    /**
     * 고급 자산 검색
     */
    @Operation(
        summary = "고급 자산 검색",
        description = "다양한 조건을 사용하여 자산을 검색합니다."
    )
    @PostMapping("/search")
    fun advancedSearchAssets(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody criteria: AdvancedAssetSearchCriteria,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<FacilityAssetResponseDto>>> {
        val assets = facilityAssetAdvancedService.advancedSearchAssets(
            companyId = userPrincipal.companyId,
            criteria = criteria,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(assets))
    }

    /**
     * 자산 비교 분석
     */
    @Operation(
        summary = "자산 비교 분석",
        description = "여러 자산을 비교 분석합니다."
    )
    @PostMapping("/compare")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun compareAssets(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "비교할 자산 ID 목록") @RequestBody assetIds: List<Long>
    ): ResponseEntity<ApiResponse<AssetComparisonDto>> {
        val comparison = facilityAssetAdvancedService.compareAssets(
            companyId = userPrincipal.companyId,
            assetIds = assetIds
        )
        return ResponseEntity.ok(ApiResponse.success(comparison))
    }

    /**
     * 자산 대량 업데이트
     */
    @Operation(
        summary = "자산 대량 업데이트",
        description = "여러 자산을 한 번에 업데이트합니다."
    )
    @PostMapping("/bulk-update")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun bulkUpdateAssets(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Valid @RequestBody request: BulkAssetUpdateRequestDto
    ): ResponseEntity<ApiResponse<BulkAssetUpdateResultDto>> {
        val result = facilityAssetAdvancedService.bulkUpdateAssets(
            companyId = userPrincipal.companyId,
            request = request.copy(updatedBy = userPrincipal.userId)
        )
        return ResponseEntity.ok(ApiResponse.success(result))
    }

    /**
     * 자산 QR 코드 생성
     */
    @Operation(
        summary = "자산 QR 코드 생성",
        description = "자산의 QR 코드를 생성합니다."
    )
    @PostMapping("/{assetId}/qr-code")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER')")
    fun generateAssetQrCode(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long
    ): ResponseEntity<ApiResponse<AssetQrCodeDto>> {
        val qrCode = facilityAssetAdvancedService.generateAssetQrCode(
            companyId = userPrincipal.companyId,
            assetId = assetId
        )
        return ResponseEntity.ok(ApiResponse.success(qrCode))
    }

    /**
     * 자산 체크인/체크아웃
     */
    @Operation(
        summary = "자산 체크인/체크아웃",
        description = "자산을 체크인 또는 체크아웃합니다."
    )
    @PostMapping("/{assetId}/check")
    @PreAuthorize("hasRole('ADMIN') or hasRole('MANAGER') or hasRole('TECHNICIAN')")
    fun checkAsset(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long,
        @Parameter(description = "체크 유형") @RequestParam checkType: String,
        @Parameter(description = "위치") @RequestParam(required = false) location: String?,
        @Parameter(description = "메모") @RequestParam(required = false) notes: String?,
        @Parameter(description = "사진 URL 목록") @RequestParam(required = false) photoUrls: List<String>?
    ): ResponseEntity<ApiResponse<AssetCheckInOutDto>> {
        val checkResult = facilityAssetAdvancedService.checkAsset(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            checkType = CheckType.valueOf(checkType),
            checkedBy = userPrincipal.userId,
            location = location,
            notes = notes,
            photoUrls = photoUrls
        )
        return ResponseEntity.ok(ApiResponse.success(checkResult))
    }

    /**
     * 교체 예정 자산 조회
     */
    @Operation(
        summary = "교체 예정 자산 조회",
        description = "교체가 필요한 자산들을 조회합니다."
    )
    @GetMapping("/replacement-due")
    fun getAssetsReplacementDue(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "예정 일수") @RequestParam(defaultValue = "90") days: Int,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<FacilityAssetResponseDto>>> {
        val assets = facilityAssetAdvancedService.getAssetsReplacementDue(
            companyId = userPrincipal.companyId,
            days = days,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(assets))
    }

    /**
     * 성능 저하 자산 조회
     */
    @Operation(
        summary = "성능 저하 자산 조회",
        description = "성능이 저하된 자산들을 조회합니다."
    )
    @GetMapping("/performance-degraded")
    fun getPerformanceDegradedAssets(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "성능 점수 임계값") @RequestParam(defaultValue = "70.0") threshold: Double,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<ApiResponse<Page<FacilityAssetResponseDto>>> {
        val assets = facilityAssetAdvancedService.getPerformanceDegradedAssets(
            companyId = userPrincipal.companyId,
            threshold = threshold,
            pageable = pageable
        )
        return ResponseEntity.ok(ApiResponse.success(assets))
    }

    /**
     * 자산 가치 평가
     */
    @Operation(
        summary = "자산 가치 평가",
        description = "자산의 현재 가치를 평가합니다."
    )
    @GetMapping("/{assetId}/valuation")
    fun getAssetValuation(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long,
        @Parameter(description = "평가 기준일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) valuationDate: LocalDateTime?
    ): ResponseEntity<ApiResponse<AssetValuationDto>> {
        val valuation = facilityAssetAdvancedService.getAssetValuation(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            valuationDate = valuationDate ?: LocalDateTime.now()
        )
        return ResponseEntity.ok(ApiResponse.success(valuation))
    }

    /**
     * 자산 예측 분석
     */
    @Operation(
        summary = "자산 예측 분석",
        description = "자산의 미래 상태를 예측 분석합니다."
    )
    @GetMapping("/{assetId}/prediction")
    fun getAssetPrediction(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "자산 ID") @PathVariable assetId: Long,
        @Parameter(description = "예측 기간(개월)") @RequestParam(defaultValue = "12") months: Int
    ): ResponseEntity<ApiResponse<AssetPredictionDto>> {
        val prediction = facilityAssetAdvancedService.getAssetPrediction(
            companyId = userPrincipal.companyId,
            assetId = assetId,
            months = months
        )
        return ResponseEntity.ok(ApiResponse.success(prediction))
    }

    /**
     * 자산 최적화 제안
     */
    @Operation(
        summary = "자산 최적화 제안",
        description = "자산 관리 최적화 제안을 조회합니다."
    )
    @GetMapping("/optimization-suggestions")
    fun getAssetOptimizationSuggestions(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "건물 ID") @RequestParam(required = false) buildingId: Long?,
        @Parameter(description = "자산 분류") @RequestParam(required = false) assetCategory: String?
    ): ResponseEntity<ApiResponse<List<AssetOptimizationSuggestionDto>>> {
        val suggestions = facilityAssetAdvancedService.getAssetOptimizationSuggestions(
            companyId = userPrincipal.companyId,
            buildingId = buildingId,
            assetCategory = assetCategory
        )
        return ResponseEntity.ok(ApiResponse.success(suggestions))
    }

    /**
     * 자산 대시보드 데이터
     */
    @Operation(
        summary = "자산 대시보드 데이터",
        description = "자산 관리 대시보드를 위한 종합 데이터를 조회합니다."
    )
    @GetMapping("/dashboard")
    fun getAssetDashboard(
        @CurrentUser userPrincipal: CustomUserPrincipal,
        @Parameter(description = "건물 ID") @RequestParam(required = false) buildingId: Long?
    ): ResponseEntity<ApiResponse<AssetDashboardDto>> {
        val dashboard = facilityAssetAdvancedService.getAssetDashboard(
            companyId = userPrincipal.companyId,
            buildingId = buildingId
        )
        return ResponseEntity.ok(ApiResponse.success(dashboard))
    }
}

// 추가 DTO 클래스들
data class AssetValuationDto(
    val assetId: Long,
    val originalValue: java.math.BigDecimal,
    val currentValue: java.math.BigDecimal,
    val depreciatedValue: java.math.BigDecimal,
    val marketValue: java.math.BigDecimal?,
    val depreciationRate: Double,
    val valuationMethod: String,
    val valuationDate: LocalDateTime
)

data class AssetPredictionDto(
    val assetId: Long,
    val predictionPeriod: Int,
    val predictedFailures: List<PredictedFailure>,
    val predictedMaintenanceCosts: java.math.BigDecimal,
    val predictedPerformanceDecline: Double,
    val recommendedActions: List<String>,
    val confidenceLevel: Double
)

data class PredictedFailure(
    val failureType: String,
    val probability: Double,
    val estimatedDate: LocalDateTime,
    val estimatedCost: java.math.BigDecimal
)

data class AssetOptimizationSuggestionDto(
    val suggestionId: UUID,
    val suggestionType: OptimizationSuggestionType,
    val title: String,
    val description: String,
    val affectedAssets: List<Long>,
    val potentialSavings: java.math.BigDecimal,
    val implementationCost: java.math.BigDecimal,
    val paybackPeriod: Int, // 개월
    val priority: SuggestionPriority
)

enum class OptimizationSuggestionType {
    MAINTENANCE_SCHEDULE_OPTIMIZATION,
    ASSET_REPLACEMENT,
    ENERGY_EFFICIENCY_IMPROVEMENT,
    PREVENTIVE_MAINTENANCE_ENHANCEMENT,
    COST_REDUCTION
}

enum class SuggestionPriority {
    LOW, MEDIUM, HIGH, CRITICAL
}

data class AssetDashboardDto(
    val totalAssets: Long,
    val assetsByStatus: Map<String, Long>,
    val assetsByCategory: Map<String, Long>,
    val warrantyExpiringSoon: Long,
    val maintenanceRequired: Long,
    val performanceDegraded: Long,
    val replacementDue: Long,
    val totalAssetValue: java.math.BigDecimal,
    val monthlyMaintenanceCost: java.math.BigDecimal,
    val averagePerformanceScore: Double,
    val recentAlerts: List<AssetAlertDto>,
    val topPerformingAssets: List<FacilityAssetResponseDto>,
    val underperformingAssets: List<FacilityAssetResponseDto>
)

data class AssetAlertDto(
    val alertId: UUID,
    val assetId: Long,
    val assetName: String,
    val alertType: String,
    val severity: String,
    val message: String,
    val createdAt: LocalDateTime
)