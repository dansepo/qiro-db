package com.qiro.domain.facility.service

import com.qiro.domain.facility.dto.*
import com.qiro.domain.facility.repository.FacilityAssetRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 시설물 자산 고급 관리 서비스
 * 자산 이력, 성능 분석, 수명 주기 관리 등 고급 기능 제공
 */
@Service
@Transactional(readOnly = true)
class FacilityAssetAdvancedService(
    private val facilityAssetRepository: FacilityAssetRepository,
    private val facilityAssetService: FacilityAssetService
) {

    /**
     * 자산 상세 정보 조회 (이력 포함)
     */
    fun getAssetDetail(companyId: UUID, assetId: Long): FacilityAssetDetailDto {
        val asset = facilityAssetService.getAsset(assetId)
        
        // 최근 이력 조회 (최근 10개)
        val recentHistory = getRecentAssetHistory(assetId, 10)
        
        // 정비 이력 조회 (최근 5개)
        val maintenanceHistory = getMaintenanceHistory(assetId, 5)
        
        // 관련 작업 지시서 조회 (최근 5개)
        val relatedWorkOrders = getRelatedWorkOrders(assetId, 5)
        
        // 관련 고장 신고 조회 (최근 5개)
        val relatedFaultReports = getRelatedFaultReports(assetId, 5)
        
        return FacilityAssetDetailDto(
            asset = asset,
            recentHistory = recentHistory,
            maintenanceHistory = maintenanceHistory,
            relatedWorkOrders = relatedWorkOrders,
            relatedFaultReports = relatedFaultReports
        )
    }

    /**
     * 자산 이력 조회
     */
    fun getAssetHistory(
        companyId: UUID,
        assetId: Long,
        changeType: AssetChangeType?,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<FacilityAssetHistoryDto> {
        // 실제 구현에서는 데이터베이스에서 이력을 조회
        // 여기서는 샘플 데이터 반환
        val sampleHistory = listOf(
            FacilityAssetHistoryDto(
                historyId = UUID.randomUUID(),
                assetId = assetId,
                changeType = AssetChangeType.STATUS_CHANGE,
                previousValue = "NORMAL",
                newValue = "UNDER_REPAIR",
                fieldName = "assetStatus",
                changeReason = "정기 점검 중 문제 발견",
                changedAt = LocalDateTime.now().minusDays(1),
                changedBy = 1L,
                changedByName = "김기술"
            ),
            FacilityAssetHistoryDto(
                historyId = UUID.randomUUID(),
                assetId = assetId,
                changeType = AssetChangeType.MAINTENANCE_COMPLETED,
                previousValue = null,
                newValue = "정비 완료",
                fieldName = "maintenance",
                changeReason = "정기 정비 완료",
                changedAt = LocalDateTime.now().minusDays(7),
                changedBy = 1L,
                changedByName = "김기술"
            )
        )
        
        return PageImpl(sampleHistory, pageable, sampleHistory.size.toLong())
    }

    /**
     * 자산 성능 지표 조회
     */
    fun getAssetPerformanceMetrics(companyId: UUID, assetId: Long, months: Int): AssetPerformanceMetricsDto {
        val asset = facilityAssetService.getAsset(assetId)
        
        // 실제 구현에서는 데이터베이스에서 성능 데이터를 계산
        return AssetPerformanceMetricsDto(
            assetId = assetId,
            assetCode = asset.assetCode,
            assetName = asset.assetName,
            uptimePercentage = 95.5,
            mtbf = 720.0, // 30일
            mttr = 4.5, // 4.5시간
            totalMaintenanceCost = BigDecimal("1500000"),
            maintenanceFrequency = 12,
            faultCount = 3,
            lastFaultDate = LocalDateTime.now().minusDays(15),
            performanceScore = 87.5,
            calculatedAt = LocalDateTime.now()
        )
    }

    /**
     * 자산 수명 주기 분석
     */
    fun getAssetLifecycleAnalysis(companyId: UUID, assetId: Long): AssetLifecycleAnalysisDto {
        val asset = facilityAssetService.getAsset(assetId)
        
        val installationDate = asset.installationDate?.atStartOfDay()
        val currentAge = installationDate?.let {
            java.time.temporal.ChronoUnit.DAYS.between(it, LocalDateTime.now()).toInt()
        } ?: 0
        
        val expectedLifespan = 3650 // 10년
        val remainingLifespan = maxOf(0, expectedLifespan - currentAge)
        val depreciationRate = if (expectedLifespan > 0) currentAge.toDouble() / expectedLifespan else 0.0
        
        val currentValue = asset.purchaseAmount?.let { purchaseAmount ->
            purchaseAmount.multiply(BigDecimal(1.0 - depreciationRate))
        } ?: BigDecimal.ZERO
        
        val lifecycleStage = when {
            currentAge < 365 -> LifecycleStage.NEW
            currentAge < expectedLifespan * 0.7 -> LifecycleStage.OPERATIONAL
            currentAge < expectedLifespan * 0.9 -> LifecycleStage.AGING
            currentAge < expectedLifespan -> LifecycleStage.REPLACEMENT_DUE
            else -> LifecycleStage.END_OF_LIFE
        }
        
        return AssetLifecycleAnalysisDto(
            assetId = assetId,
            assetCode = asset.assetCode,
            assetName = asset.assetName,
            installationDate = installationDate,
            currentAge = currentAge,
            expectedLifespan = expectedLifespan,
            remainingLifespan = remainingLifespan,
            depreciationRate = depreciationRate,
            currentValue = currentValue,
            replacementRecommendation = if (lifecycleStage == LifecycleStage.REPLACEMENT_DUE) 
                "교체를 권장합니다" else null,
            lifecycleStage = lifecycleStage
        )
    }

    /**
     * 고급 자산 검색
     */
    fun advancedSearchAssets(
        companyId: UUID,
        criteria: AdvancedAssetSearchCriteria,
        pageable: Pageable
    ): Page<FacilityAssetResponseDto> {
        // 실제 구현에서는 복잡한 쿼리를 사용하여 검색
        // 여기서는 기본 검색 기능을 활용
        val basicCriteria = FacilityAssetSearchCriteria(
            keyword = criteria.keyword,
            assetCategory = criteria.assetCategory,
            assetStatus = criteria.assetStatus,
            buildingId = criteria.buildingId,
            floorNumber = criteria.floorNumber,
            managerId = criteria.managerId,
            warrantyExpiring = criteria.warrantyExpiring,
            warrantyExpiryDays = criteria.warrantyExpiryDays,
            maintenanceRequired = criteria.maintenanceRequired
        )
        
        return facilityAssetService.searchAssets(basicCriteria, pageable)
    }

    /**
     * 자산 비교 분석
     */
    fun compareAssets(companyId: UUID, assetIds: List<Long>): AssetComparisonDto {
        val assets = assetIds.map { facilityAssetService.getAsset(it) }
        
        val comparisonMetrics = mapOf(
            "purchaseAmount" to assets.map { it.purchaseAmount ?: BigDecimal.ZERO },
            "age" to assets.map { asset ->
                asset.installationDate?.let {
                    java.time.temporal.ChronoUnit.DAYS.between(it.atStartOfDay(), LocalDateTime.now())
                } ?: 0
            },
            "maintenanceCycle" to assets.map { it.maintenanceCycleDays ?: 0 },
            "warrantyStatus" to assets.map { !it.isWarrantyExpired }
        )
        
        val recommendations = listOf(
            "자산 ${assets.minByOrNull { it.purchaseAmount ?: BigDecimal.ZERO }?.assetName}이 가장 경제적입니다",
            "정기 점검 주기를 통일하여 관리 효율성을 높이는 것을 권장합니다"
        )
        
        return AssetComparisonDto(
            comparisonId = UUID.randomUUID(),
            assets = assets,
            comparisonMetrics = comparisonMetrics,
            recommendations = recommendations,
            createdAt = LocalDateTime.now()
        )
    }

    /**
     * 자산 대량 업데이트
     */
    @Transactional
    fun bulkUpdateAssets(companyId: UUID, request: BulkAssetUpdateRequestDto): BulkAssetUpdateResultDto {
        val successfulAssets = mutableListOf<Long>()
        val failedAssets = mutableListOf<BulkUpdateFailure>()
        
        request.assetIds.forEach { assetId ->
            try {
                // 실제 구현에서는 각 자산을 업데이트
                // 여기서는 성공으로 가정
                successfulAssets.add(assetId)
            } catch (e: Exception) {
                failedAssets.add(BulkUpdateFailure(assetId, e.message ?: "알 수 없는 오류"))
            }
        }
        
        return BulkAssetUpdateResultDto(
            totalRequested = request.assetIds.size,
            successCount = successfulAssets.size,
            failureCount = failedAssets.size,
            successfulAssets = successfulAssets,
            failedAssets = failedAssets,
            processedAt = LocalDateTime.now()
        )
    }

    /**
     * 자산 QR 코드 생성
     */
    fun generateAssetQrCode(companyId: UUID, assetId: Long): AssetQrCodeDto {
        val asset = facilityAssetService.getAsset(assetId)
        
        val qrCodeData = "ASSET:${asset.assetCode}:${assetId}"
        val qrCodeImageUrl = "/api/v1/qr-codes/${UUID.randomUUID()}.png"
        
        return AssetQrCodeDto(
            assetId = assetId,
            assetCode = asset.assetCode,
            qrCodeData = qrCodeData,
            qrCodeImageUrl = qrCodeImageUrl,
            generatedAt = LocalDateTime.now()
        )
    }

    /**
     * 자산 체크인/체크아웃
     */
    @Transactional
    fun checkAsset(
        companyId: UUID,
        assetId: Long,
        checkType: CheckType,
        checkedBy: Long,
        location: String?,
        notes: String?,
        photoUrls: List<String>?
    ): AssetCheckInOutDto {
        // 실제 구현에서는 체크인/체크아웃 이력을 데이터베이스에 저장
        
        return AssetCheckInOutDto(
            checkId = UUID.randomUUID(),
            assetId = assetId,
            checkType = checkType,
            checkedBy = checkedBy,
            checkedByName = "사용자", // 실제로는 사용자 정보 조회
            checkTime = LocalDateTime.now(),
            location = location,
            notes = notes,
            photoUrls = photoUrls
        )
    }

    /**
     * 교체 예정 자산 조회
     */
    fun getAssetsReplacementDue(companyId: UUID, days: Int, pageable: Pageable): Page<FacilityAssetResponseDto> {
        // 실제 구현에서는 수명 주기 분석을 통해 교체 예정 자산을 조회
        return facilityAssetService.searchAssets(FacilityAssetSearchCriteria(), pageable)
    }

    /**
     * 성능 저하 자산 조회
     */
    fun getPerformanceDegradedAssets(companyId: UUID, threshold: Double, pageable: Pageable): Page<FacilityAssetResponseDto> {
        // 실제 구현에서는 성능 지표를 기반으로 저하된 자산을 조회
        return facilityAssetService.searchAssets(FacilityAssetSearchCriteria(), pageable)
    }

    /**
     * 자산 가치 평가
     */
    fun getAssetValuation(companyId: UUID, assetId: Long, valuationDate: LocalDateTime): AssetValuationDto {
        val asset = facilityAssetService.getAsset(assetId)
        val originalValue = asset.purchaseAmount ?: BigDecimal.ZERO
        
        // 간단한 정액법 감가상각 계산
        val installationDate = asset.installationDate?.atStartOfDay()
        val depreciationRate = if (installationDate != null) {
            val ageInYears = java.time.temporal.ChronoUnit.DAYS.between(installationDate, valuationDate) / 365.0
            minOf(ageInYears / 10.0, 1.0) // 10년 수명 가정
        } else 0.0
        
        val depreciatedValue = originalValue.multiply(BigDecimal(1.0 - depreciationRate))
        
        return AssetValuationDto(
            assetId = assetId,
            originalValue = originalValue,
            currentValue = depreciatedValue,
            depreciatedValue = depreciatedValue,
            marketValue = depreciatedValue.multiply(BigDecimal("0.8")), // 시장가치는 80%로 가정
            depreciationRate = depreciationRate,
            valuationMethod = "정액법",
            valuationDate = valuationDate
        )
    }

    /**
     * 자산 예측 분석
     */
    fun getAssetPrediction(companyId: UUID, assetId: Long, months: Int): AssetPredictionDto {
        val predictedFailures = listOf(
            PredictedFailure(
                failureType = "전기 시스템 고장",
                probability = 0.15,
                estimatedDate = LocalDateTime.now().plusMonths(6),
                estimatedCost = BigDecimal("500000")
            ),
            PredictedFailure(
                failureType = "기계적 마모",
                probability = 0.25,
                estimatedDate = LocalDateTime.now().plusMonths(9),
                estimatedCost = BigDecimal("800000")
            )
        )
        
        return AssetPredictionDto(
            assetId = assetId,
            predictionPeriod = months,
            predictedFailures = predictedFailures,
            predictedMaintenanceCosts = BigDecimal("1200000"),
            predictedPerformanceDecline = 5.0,
            recommendedActions = listOf(
                "6개월 후 전기 시스템 점검 실시",
                "예방 정비 주기를 3개월로 단축 검토"
            ),
            confidenceLevel = 0.75
        )
    }

    /**
     * 자산 최적화 제안
     */
    fun getAssetOptimizationSuggestions(
        companyId: UUID,
        buildingId: Long?,
        assetCategory: String?
    ): List<AssetOptimizationSuggestionDto> {
        return listOf(
            AssetOptimizationSuggestionDto(
                suggestionId = UUID.randomUUID(),
                suggestionType = OptimizationSuggestionType.MAINTENANCE_SCHEDULE_OPTIMIZATION,
                title = "정비 일정 최적화",
                description = "유사한 자산들의 정비 일정을 통합하여 효율성을 높일 수 있습니다",
                affectedAssets = listOf(1L, 2L, 3L),
                potentialSavings = BigDecimal("300000"),
                implementationCost = BigDecimal("50000"),
                paybackPeriod = 2,
                priority = SuggestionPriority.HIGH
            ),
            AssetOptimizationSuggestionDto(
                suggestionId = UUID.randomUUID(),
                suggestionType = OptimizationSuggestionType.ENERGY_EFFICIENCY_IMPROVEMENT,
                title = "에너지 효율 개선",
                description = "노후 장비를 고효율 장비로 교체하여 운영비를 절감할 수 있습니다",
                affectedAssets = listOf(4L, 5L),
                potentialSavings = BigDecimal("1200000"),
                implementationCost = BigDecimal("5000000"),
                paybackPeriod = 50,
                priority = SuggestionPriority.MEDIUM
            )
        )
    }

    /**
     * 자산 대시보드 데이터
     */
    fun getAssetDashboard(companyId: UUID, buildingId: Long?): AssetDashboardDto {
        val stats = facilityAssetService.getAssetStatistics(buildingId)
        
        return AssetDashboardDto(
            totalAssets = stats.totalAssets,
            assetsByStatus = mapOf(
                "정상" to stats.normalAssets,
                "점검필요" to stats.inspectionRequiredAssets,
                "수리중" to stats.underRepairAssets,
                "고장" to stats.outOfOrderAssets
            ),
            assetsByCategory = stats.categoryStats,
            warrantyExpiringSoon = stats.warrantyExpiringSoon,
            maintenanceRequired = stats.maintenanceRequired,
            performanceDegraded = 5L, // 샘플 데이터
            replacementDue = 3L, // 샘플 데이터
            totalAssetValue = BigDecimal("50000000"),
            monthlyMaintenanceCost = BigDecimal("2000000"),
            averagePerformanceScore = 85.5,
            recentAlerts = listOf(
                AssetAlertDto(
                    alertId = UUID.randomUUID(),
                    assetId = 1L,
                    assetName = "냉각 시스템 A",
                    alertType = "WARRANTY_EXPIRING",
                    severity = "MEDIUM",
                    message = "보증 기간이 30일 후 만료됩니다",
                    createdAt = LocalDateTime.now().minusHours(2)
                )
            ),
            topPerformingAssets = emptyList(), // 실제로는 성능 상위 자산 조회
            underperformingAssets = emptyList() // 실제로는 성능 하위 자산 조회
        )
    }

    // 헬퍼 메서드들
    private fun getRecentAssetHistory(assetId: Long, limit: Int): List<FacilityAssetHistoryDto> {
        // 실제 구현에서는 데이터베이스에서 조회
        return emptyList()
    }

    private fun getMaintenanceHistory(assetId: Long, limit: Int): List<MaintenanceHistoryDto> {
        // 실제 구현에서는 데이터베이스에서 조회
        return emptyList()
    }

    private fun getRelatedWorkOrders(assetId: Long, limit: Int): List<RelatedWorkOrderDto> {
        // 실제 구현에서는 데이터베이스에서 조회
        return emptyList()
    }

    private fun getRelatedFaultReports(assetId: Long, limit: Int): List<RelatedFaultReportDto> {
        // 실제 구현에서는 데이터베이스에서 조회
        return emptyList()
    }
}