package com.qiro.domain.unit.dto

import com.qiro.domain.unit.entity.FacingDirection
import com.qiro.domain.unit.entity.UnitStatus
import com.qiro.domain.unit.entity.UnitType
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

// Request DTOs
data class CreateUnitRequest(
    @field:NotNull(message = "건물 ID는 필수입니다")
    val buildingId: UUID,
    
    @field:NotBlank(message = "세대 번호는 필수입니다")
    @field:Size(max = 20, message = "세대 번호는 20자를 초과할 수 없습니다")
    val unitNumber: String,
    
    @field:NotNull(message = "층수는 필수입니다")
    val floor: Int,
    
    @field:NotNull(message = "전용면적은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "전용면적은 0보다 커야 합니다")
    @field:DecimalMax(value = "9999999.99", message = "전용면적이 너무 큽니다")
    val exclusiveArea: BigDecimal,
    
    @field:DecimalMin(value = "0", message = "공용면적은 0 이상이어야 합니다")
    val commonArea: BigDecimal? = null,
    
    @field:NotNull(message = "세대 유형은 필수입니다")
    val unitType: UnitType,
    
    @field:Min(value = 0, message = "방 개수는 0 이상이어야 합니다")
    val roomCount: Int? = null,
    
    @field:Min(value = 0, message = "욕실 개수는 0 이상이어야 합니다")
    val bathroomCount: Int? = null,
    
    @field:Min(value = 0, message = "발코니 개수는 0 이상이어야 합니다")
    val balconyCount: Int? = null,
    
    val hasTerrace: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "테라스 면적은 0 이상이어야 합니다")
    val terraceArea: BigDecimal? = null,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    @field:Min(value = 0, message = "창고 공간은 0 이상이어야 합니다")
    val storageSpaces: Int? = null,
    
    val facingDirection: FacingDirection? = null,
    
    val hasElevatorAccess: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "월 임대료는 0 이상이어야 합니다")
    val monthlyRent: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "보증금은 0 이상이어야 합니다")
    val securityDeposit: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "관리비는 0 이상이어야 합니다")
    val maintenanceFee: BigDecimal? = null,
    
    val utilityIncluded: Boolean = false,
    val furnished: Boolean = false,
    val petAllowed: Boolean = false,
    val smokingAllowed: Boolean = false,
    
    val lastRenovationDate: LocalDate? = null,
    
    @field:Min(value = 1, message = "상태 평가는 1 이상이어야 합니다")
    @field:Max(value = 10, message = "상태 평가는 10 이하여야 합니다")
    val conditionRating: Int? = null,
    
    @field:Size(max = 1000, message = "특별 기능은 1000자를 초과할 수 없습니다")
    val specialFeatures: String? = null,
    
    @field:Size(max = 1000, message = "설명은 1000자를 초과할 수 없습니다")
    val description: String? = null,
    
    @field:Size(max = 1000, message = "내부 메모는 1000자를 초과할 수 없습니다")
    val internalNotes: String? = null
)

data class UpdateUnitRequest(
    @field:NotBlank(message = "세대 번호는 필수입니다")
    @field:Size(max = 20, message = "세대 번호는 20자를 초과할 수 없습니다")
    val unitNumber: String,
    
    @field:NotNull(message = "층수는 필수입니다")
    val floor: Int,
    
    @field:NotNull(message = "전용면적은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "전용면적은 0보다 커야 합니다")
    @field:DecimalMax(value = "9999999.99", message = "전용면적이 너무 큽니다")
    val exclusiveArea: BigDecimal,
    
    @field:DecimalMin(value = "0", message = "공용면적은 0 이상이어야 합니다")
    val commonArea: BigDecimal? = null,
    
    @field:NotNull(message = "세대 유형은 필수입니다")
    val unitType: UnitType,
    
    @field:Min(value = 0, message = "방 개수는 0 이상이어야 합니다")
    val roomCount: Int? = null,
    
    @field:Min(value = 0, message = "욕실 개수는 0 이상이어야 합니다")
    val bathroomCount: Int? = null,
    
    @field:Min(value = 0, message = "발코니 개수는 0 이상이어야 합니다")
    val balconyCount: Int? = null,
    
    val hasTerrace: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "테라스 면적은 0 이상이어야 합니다")
    val terraceArea: BigDecimal? = null,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    @field:Min(value = 0, message = "창고 공간은 0 이상이어야 합니다")
    val storageSpaces: Int? = null,
    
    val facingDirection: FacingDirection? = null,
    
    val hasElevatorAccess: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "월 임대료는 0 이상이어야 합니다")
    val monthlyRent: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "보증금은 0 이상이어야 합니다")
    val securityDeposit: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "관리비는 0 이상이어야 합니다")
    val maintenanceFee: BigDecimal? = null,
    
    val utilityIncluded: Boolean = false,
    val furnished: Boolean = false,
    val petAllowed: Boolean = false,
    val smokingAllowed: Boolean = false,
    
    val lastRenovationDate: LocalDate? = null,
    
    @field:Min(value = 1, message = "상태 평가는 1 이상이어야 합니다")
    @field:Max(value = 10, message = "상태 평가는 10 이하여야 합니다")
    val conditionRating: Int? = null,
    
    @field:Size(max = 1000, message = "특별 기능은 1000자를 초과할 수 없습니다")
    val specialFeatures: String? = null,
    
    @field:Size(max = 1000, message = "설명은 1000자를 초과할 수 없습니다")
    val description: String? = null,
    
    @field:Size(max = 1000, message = "내부 메모는 1000자를 초과할 수 없습니다")
    val internalNotes: String? = null
)

data class UpdateUnitStatusRequest(
    @field:NotNull(message = "세대 상태는 필수입니다")
    val status: UnitStatus,
    
    val moveInDate: LocalDate? = null,
    val moveOutDate: LocalDate? = null,
    
    @field:Size(max = 500, message = "상태 변경 사유는 500자를 초과할 수 없습니다")
    val reason: String? = null
)

data class UnitSearchRequest(
    val buildingId: UUID? = null,
    val status: UnitStatus? = null,
    val unitType: UnitType? = null,
    val minArea: BigDecimal? = null,
    val maxArea: BigDecimal? = null,
    val minRent: BigDecimal? = null,
    val maxRent: BigDecimal? = null,
    val floor: Int? = null,
    val petAllowed: Boolean? = null,
    val furnished: Boolean? = null,
    val facingDirection: FacingDirection? = null
)

// Response DTOs
data class UnitDto(
    val unitId: UUID,
    val buildingId: UUID,
    val buildingName: String,
    val unitNumber: String,
    val floor: Int,
    val exclusiveArea: BigDecimal,
    val commonArea: BigDecimal?,
    val totalArea: BigDecimal,
    val unitType: UnitType,
    val currentStatus: UnitStatus,
    val roomCount: Int?,
    val bathroomCount: Int?,
    val balconyCount: Int?,
    val hasTerrace: Boolean,
    val terraceArea: BigDecimal?,
    val parkingSpaces: Int?,
    val storageSpaces: Int?,
    val facingDirection: FacingDirection?,
    val hasElevatorAccess: Boolean,
    val monthlyRent: BigDecimal?,
    val securityDeposit: BigDecimal?,
    val maintenanceFee: BigDecimal?,
    val utilityIncluded: Boolean,
    val furnished: Boolean,
    val petAllowed: Boolean,
    val smokingAllowed: Boolean,
    val moveInDate: LocalDate?,
    val moveOutDate: LocalDate?,
    val lastRenovationDate: LocalDate?,
    val conditionRating: Int?,
    val specialFeatures: String?,
    val description: String?,
    val internalNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class UnitSummaryDto(
    val unitId: UUID,
    val buildingId: UUID,
    val buildingName: String,
    val unitNumber: String,
    val floor: Int,
    val exclusiveArea: BigDecimal,
    val totalArea: BigDecimal,
    val unitType: UnitType,
    val currentStatus: UnitStatus,
    val monthlyRent: BigDecimal?,
    val facingDirection: FacingDirection?
)

data class UnitStatusStatsDto(
    val status: UnitStatus,
    val count: Long,
    val percentage: BigDecimal
)

data class UnitTypeStatsDto(
    val type: UnitType,
    val count: Long,
    val averageRent: BigDecimal?,
    val averageArea: BigDecimal,
    val percentage: BigDecimal
)