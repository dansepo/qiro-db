package com.qiro.domain.facility.dto

import com.qiro.domain.facility.entity.AssetStatus
import java.time.LocalDateTime
import java.util.*

/**
 * 시설물 자산 이력 DTO
 */
data class FacilityAssetHistoryDto(
    val historyId: UUID,
    val assetId: Long,
    val changeType: AssetChangeType,
    val previousValue: String?,
    val newValue: String?,
    val fieldName: String,
    val changeReason: String?,
    val changedAt: LocalDateTime,
    val changedBy: Long?,
    val changedByName: String?
)

/**
 * 자산 변경 유형
 */
enum class AssetChangeType(val description: String) {
    STATUS_CHANGE("상태 변경"),
    LOCATION_CHANGE("위치 변경"),
    MAINTENANCE_COMPLETED("정비 완료"),
    WARRANTY_UPDATE("보증 정보 업데이트"),
    MANAGER_CHANGE("담당자 변경"),
    SPECIFICATION_UPDATE("사양 업데이트"),
    CREATED("자산 등록"),
    DELETED("자산 삭제")
}

/**
 * 자산 상세 정보 DTO (이력 포함)
 */
data class FacilityAssetDetailDto(
    val asset: FacilityAssetResponseDto,
    val recentHistory: List<FacilityAssetHistoryDto>,
    val maintenanceHistory: List<MaintenanceHistoryDto>,
    val relatedWorkOrders: List<RelatedWorkOrderDto>,
    val relatedFaultReports: List<RelatedFaultReportDto>
)

/**
 * 정비 이력 DTO
 */
data class MaintenanceHistoryDto(
    val maintenanceId: UUID,
    val maintenanceDate: LocalDateTime,
    val maintenanceType: String,
    val description: String?,
    val performedBy: Long?,
    val performedByName: String?,
    val cost: java.math.BigDecimal?,
    val nextMaintenanceDate: LocalDateTime?
)

/**
 * 관련 작업 지시서 DTO
 */
data class RelatedWorkOrderDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val status: String,
    val createdAt: LocalDateTime,
    val assignedTo: Long?,
    val assignedToName: String?
)

/**
 * 관련 고장 신고 DTO
 */
data class RelatedFaultReportDto(
    val reportId: UUID,
    val reportNumber: String,
    val title: String,
    val status: String,
    val reportedAt: LocalDateTime,
    val reportedBy: Long?,
    val reportedByName: String?
)

/**
 * 자산 성능 지표 DTO
 */
data class AssetPerformanceMetricsDto(
    val assetId: Long,
    val assetCode: String,
    val assetName: String,
    val uptimePercentage: Double,
    val mtbf: Double, // Mean Time Between Failures (평균 고장 간격)
    val mttr: Double, // Mean Time To Repair (평균 수리 시간)
    val totalMaintenanceCost: java.math.BigDecimal,
    val maintenanceFrequency: Int,
    val faultCount: Int,
    val lastFaultDate: LocalDateTime?,
    val performanceScore: Double, // 종합 성능 점수 (0-100)
    val calculatedAt: LocalDateTime
)

/**
 * 자산 수명 주기 분석 DTO
 */
data class AssetLifecycleAnalysisDto(
    val assetId: Long,
    val assetCode: String,
    val assetName: String,
    val installationDate: LocalDateTime?,
    val currentAge: Int, // 설치 후 경과 일수
    val expectedLifespan: Int, // 예상 수명 (일)
    val remainingLifespan: Int, // 잔여 수명 (일)
    val depreciationRate: Double, // 감가상각률
    val currentValue: java.math.BigDecimal, // 현재 가치
    val replacementRecommendation: String?, // 교체 권장사항
    val lifecycleStage: LifecycleStage
)

/**
 * 자산 수명 주기 단계
 */
enum class LifecycleStage(val description: String) {
    NEW("신규"),
    OPERATIONAL("운영"),
    AGING("노후화"),
    REPLACEMENT_DUE("교체 필요"),
    END_OF_LIFE("수명 종료")
}

/**
 * 자산 비교 분석 DTO
 */
data class AssetComparisonDto(
    val comparisonId: UUID,
    val assets: List<FacilityAssetResponseDto>,
    val comparisonMetrics: Map<String, List<Any>>,
    val recommendations: List<String>,
    val createdAt: LocalDateTime
)

/**
 * 자산 검색 필터 확장 DTO
 */
data class AdvancedAssetSearchCriteria(
    val keyword: String? = null,
    val assetCategory: String? = null,
    val assetStatus: AssetStatus? = null,
    val buildingId: Long? = null,
    val floorNumber: Int? = null,
    val managerId: Long? = null,
    val manufacturerKeyword: String? = null,
    val modelKeyword: String? = null,
    val installationDateFrom: LocalDateTime? = null,
    val installationDateTo: LocalDateTime? = null,
    val purchaseAmountFrom: java.math.BigDecimal? = null,
    val purchaseAmountTo: java.math.BigDecimal? = null,
    val warrantyExpiring: Boolean = false,
    val warrantyExpiryDays: Int? = null,
    val maintenanceRequired: Boolean = false,
    val maintenanceOverdue: Boolean = false,
    val performanceScoreMin: Double? = null,
    val performanceScoreMax: Double? = null,
    val hasRecentFaults: Boolean = false,
    val faultCountMin: Int? = null,
    val faultCountMax: Int? = null
)

/**
 * 자산 대량 업데이트 요청 DTO
 */
data class BulkAssetUpdateRequestDto(
    val assetIds: List<Long>,
    val updateFields: Map<String, Any>,
    val reason: String?,
    val updatedBy: Long
)

/**
 * 자산 대량 업데이트 결과 DTO
 */
data class BulkAssetUpdateResultDto(
    val totalRequested: Int,
    val successCount: Int,
    val failureCount: Int,
    val successfulAssets: List<Long>,
    val failedAssets: List<BulkUpdateFailure>,
    val processedAt: LocalDateTime
)

/**
 * 대량 업데이트 실패 정보
 */
data class BulkUpdateFailure(
    val assetId: Long,
    val reason: String
)

/**
 * 자산 QR 코드 정보 DTO
 */
data class AssetQrCodeDto(
    val assetId: Long,
    val assetCode: String,
    val qrCodeData: String,
    val qrCodeImageUrl: String?,
    val generatedAt: LocalDateTime
)

/**
 * 자산 체크인/체크아웃 DTO
 */
data class AssetCheckInOutDto(
    val checkId: UUID,
    val assetId: Long,
    val checkType: CheckType,
    val checkedBy: Long,
    val checkedByName: String?,
    val checkTime: LocalDateTime,
    val location: String?,
    val notes: String?,
    val photoUrls: List<String>?
)

/**
 * 체크 유형
 */
enum class CheckType(val description: String) {
    CHECK_IN("체크인"),
    CHECK_OUT("체크아웃"),
    INSPECTION("점검"),
    MAINTENANCE("정비")
}