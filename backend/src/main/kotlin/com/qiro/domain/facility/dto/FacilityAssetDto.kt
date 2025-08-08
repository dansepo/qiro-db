package com.qiro.domain.facility.dto

import com.qiro.domain.facility.entity.AssetStatus
import com.qiro.domain.facility.entity.FacilityAsset
import com.qiro.domain.facility.entity.ImportanceLevel
import com.qiro.domain.facility.entity.UsageStatus
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime

/**
 * 시설물 자산 응답 DTO
 */
data class FacilityAssetResponseDto(
    val id: Long,
    val assetCode: String,
    val assetName: String,
    val assetCategory: String,
    val assetType: String?,
    val manufacturer: String?,
    val modelName: String?,
    val serialNumber: String?,
    val location: String,
    val buildingId: Long,
    val floorNumber: Int?,
    val purchaseDate: LocalDate?,
    val purchaseAmount: BigDecimal?,
    val installationDate: LocalDate?,
    val warrantyStartDate: LocalDate?,
    val warrantyEndDate: LocalDate?,
    val assetStatus: AssetStatus,
    val usageStatus: UsageStatus,
    val importanceLevel: ImportanceLevel,
    val maintenanceCycleDays: Int?,
    val lastMaintenanceDate: LocalDate?,
    val nextMaintenanceDate: LocalDate?,
    val description: String?,
    val managerId: Long?,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: Long?,
    val updatedBy: Long?,
    
    // 계산된 필드들
    val isWarrantyExpired: Boolean,
    val isMaintenanceRequired: Boolean,
    val daysUntilWarrantyExpiry: Long?,
    val daysUntilMaintenance: Long?
) {
    companion object {
        fun from(asset: FacilityAsset): FacilityAssetResponseDto {
            val now = LocalDate.now()
            return FacilityAssetResponseDto(
                id = asset.id!!,
                assetCode = asset.assetCode,
                assetName = asset.assetName,
                assetCategory = asset.assetCategory,
                assetType = asset.assetType,
                manufacturer = asset.manufacturer,
                modelName = asset.modelName,
                serialNumber = asset.serialNumber,
                location = asset.location,
                buildingId = asset.buildingId,
                floorNumber = asset.floorNumber,
                purchaseDate = asset.purchaseDate,
                purchaseAmount = asset.purchaseAmount,
                installationDate = asset.installationDate,
                warrantyStartDate = asset.warrantyStartDate,
                warrantyEndDate = asset.warrantyEndDate,
                assetStatus = asset.assetStatus,
                usageStatus = asset.usageStatus,
                importanceLevel = asset.importanceLevel,
                maintenanceCycleDays = asset.maintenanceCycleDays,
                lastMaintenanceDate = asset.lastMaintenanceDate,
                nextMaintenanceDate = asset.nextMaintenanceDate,
                description = asset.description,
                managerId = asset.managerId,
                isActive = asset.isActive,
                createdAt = asset.createdAt!!,
                updatedAt = asset.updatedAt!!,
                createdBy = asset.createdBy,
                updatedBy = asset.updatedBy,
                isWarrantyExpired = asset.isWarrantyExpired(),
                isMaintenanceRequired = asset.isMaintenanceRequired(),
                daysUntilWarrantyExpiry = asset.warrantyEndDate?.let { 
                    java.time.temporal.ChronoUnit.DAYS.between(now, it)
                },
                daysUntilMaintenance = asset.nextMaintenanceDate?.let {
                    java.time.temporal.ChronoUnit.DAYS.between(now, it)
                }
            )
        }
    }
}

/**
 * 시설물 자산 생성 요청 DTO
 */
data class CreateFacilityAssetRequestDto(
    val assetCode: String,
    val assetName: String,
    val assetCategory: String,
    val assetType: String? = null,
    val manufacturer: String? = null,
    val modelName: String? = null,
    val serialNumber: String? = null,
    val location: String,
    val buildingId: Long,
    val floorNumber: Int? = null,
    val purchaseDate: LocalDate? = null,
    val purchaseAmount: BigDecimal? = null,
    val installationDate: LocalDate? = null,
    val warrantyStartDate: LocalDate? = null,
    val warrantyEndDate: LocalDate? = null,
    val assetStatus: AssetStatus = AssetStatus.NORMAL,
    val usageStatus: UsageStatus = UsageStatus.IN_USE,
    val importanceLevel: ImportanceLevel = ImportanceLevel.MEDIUM,
    val maintenanceCycleDays: Int? = null,
    val description: String? = null,
    val managerId: Long? = null
) {
    fun toEntity(createdBy: Long?): FacilityAsset {
        return FacilityAsset(
            assetCode = assetCode,
            assetName = assetName,
            assetCategory = assetCategory,
            assetType = assetType,
            manufacturer = manufacturer,
            modelName = modelName,
            serialNumber = serialNumber,
            location = location,
            buildingId = buildingId,
            floorNumber = floorNumber,
            purchaseDate = purchaseDate,
            purchaseAmount = purchaseAmount,
            installationDate = installationDate,
            warrantyStartDate = warrantyStartDate,
            warrantyEndDate = warrantyEndDate,
            assetStatus = assetStatus,
            usageStatus = usageStatus,
            importanceLevel = importanceLevel,
            maintenanceCycleDays = maintenanceCycleDays,
            nextMaintenanceDate = calculateNextMaintenanceDate(),
            description = description,
            managerId = managerId,
            createdBy = createdBy
        )
    }
    
    private fun calculateNextMaintenanceDate(): LocalDate? {
        return if (maintenanceCycleDays != null && installationDate != null) {
            installationDate.plusDays(maintenanceCycleDays.toLong())
        } else null
    }
}

/**
 * 시설물 자산 수정 요청 DTO
 */
data class UpdateFacilityAssetRequestDto(
    val assetName: String? = null,
    val assetCategory: String? = null,
    val assetType: String? = null,
    val manufacturer: String? = null,
    val modelName: String? = null,
    val serialNumber: String? = null,
    val location: String? = null,
    val floorNumber: Int? = null,
    val purchaseDate: LocalDate? = null,
    val purchaseAmount: BigDecimal? = null,
    val installationDate: LocalDate? = null,
    val warrantyStartDate: LocalDate? = null,
    val warrantyEndDate: LocalDate? = null,
    val assetStatus: AssetStatus? = null,
    val usageStatus: UsageStatus? = null,
    val importanceLevel: ImportanceLevel? = null,
    val maintenanceCycleDays: Int? = null,
    val description: String? = null,
    val managerId: Long? = null
)

/**
 * 시설물 자산 검색 조건 DTO
 */
data class FacilityAssetSearchCriteria(
    val keyword: String? = null,
    val assetCategory: String? = null,
    val assetStatus: AssetStatus? = null,
    val usageStatus: UsageStatus? = null,
    val importanceLevel: ImportanceLevel? = null,
    val buildingId: Long? = null,
    val floorNumber: Int? = null,
    val managerId: Long? = null,
    val warrantyExpiring: Boolean = false,
    val maintenanceRequired: Boolean = false,
    val warrantyExpiryDays: Int? = null // 며칠 이내 보증 만료
)

/**
 * 시설물 자산 통계 DTO
 */
data class FacilityAssetStatsDto(
    val totalAssets: Long,
    val normalAssets: Long,
    val inspectionRequiredAssets: Long,
    val underRepairAssets: Long,
    val outOfOrderAssets: Long,
    val warrantyExpiringSoon: Long,
    val maintenanceRequired: Long,
    val categoryStats: Map<String, Long>,
    val importanceLevelStats: Map<ImportanceLevel, Long>
)

/**
 * 자산 상태 업데이트 요청 DTO
 */
data class AssetStatusUpdateRequestDto(
    val assetStatus: AssetStatus,
    val reason: String? = null,
    val updatedBy: Long
)

/**
 * 자산 정비 완료 요청 DTO
 */
data class AssetMaintenanceCompleteRequestDto(
    val maintenanceDate: LocalDate,
    val nextMaintenanceDate: LocalDate? = null,
    val maintenanceNotes: String? = null,
    val updatedBy: Long
)