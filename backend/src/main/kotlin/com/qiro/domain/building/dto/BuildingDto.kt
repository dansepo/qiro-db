package com.qiro.domain.building.dto

import com.qiro.domain.building.entity.BuildingStatus
import com.qiro.domain.building.entity.BuildingType
import com.qiro.domain.building.entity.HeatingType
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

// Request DTOs
data class CreateBuildingRequest(
    @field:NotBlank(message = "건물명은 필수입니다")
    @field:Size(max = 100, message = "건물명은 100자를 초과할 수 없습니다")
    val buildingName: String,
    
    @field:NotBlank(message = "주소는 필수입니다")
    @field:Size(max = 500, message = "주소는 500자를 초과할 수 없습니다")
    val address: String,
    
    @field:NotNull(message = "건물 유형은 필수입니다")
    val buildingType: BuildingType,
    
    @field:Min(value = 1, message = "총 층수는 1층 이상이어야 합니다")
    @field:Max(value = 200, message = "총 층수는 200층을 초과할 수 없습니다")
    val totalFloors: Int,
    
    @field:NotNull(message = "총 면적은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "총 면적은 0보다 커야 합니다")
    @field:DecimalMax(value = "999999999.99", message = "총 면적이 너무 큽니다")
    val totalFloorArea: BigDecimal,
    
    @field:Min(value = 1900, message = "건축년도는 1900년 이후여야 합니다")
    @field:Max(value = 2100, message = "건축년도는 2100년 이전이어야 합니다")
    val constructionYear: Int? = null,
    
    val completionDate: LocalDate? = null,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    @field:Min(value = 0, message = "엘리베이터 수는 0 이상이어야 합니다")
    val elevatorCount: Int? = null,
    
    val hasBasement: Boolean = false,
    
    @field:Min(value = 0, message = "지하 층수는 0 이상이어야 합니다")
    val basementFloors: Int? = null,
    
    val heatingType: HeatingType? = null,
    
    @field:Size(max = 20, message = "관리사무소 전화번호는 20자를 초과할 수 없습니다")
    val managementOfficePhone: String? = null,
    
    @field:Size(max = 200, message = "관리사무소 위치는 200자를 초과할 수 없습니다")
    val managementOfficeLocation: String? = null,
    
    @field:Size(max = 100, message = "보안 시스템 정보는 100자를 초과할 수 없습니다")
    val securitySystem: String? = null,
    
    @field:Min(value = 0, message = "CCTV 수는 0 이상이어야 합니다")
    val cctvCount: Int? = null,
    
    @field:Size(max = 10, message = "소방 안전 등급은 10자를 초과할 수 없습니다")
    val fireSafetyGrade: String? = null,
    
    @field:Size(max = 10, message = "에너지 효율 등급은 10자를 초과할 수 없습니다")
    val energyEfficiencyGrade: String? = null,
    
    @field:DecimalMin(value = "0", message = "평방미터당 관리비는 0 이상이어야 합니다")
    val maintenanceFeePerSqm: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "공용면적 비율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "공용면적 비율은 100 이하여야 합니다")
    val commonAreaRatio: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "대지면적은 0 이상이어야 합니다")
    val landArea: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "건폐율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "건폐율은 100 이하여야 합니다")
    val buildingCoverageRatio: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "용적률은 0 이상이어야 합니다")
    val floorAreaRatio: BigDecimal? = null,
    
    @field:Size(max = 1000, message = "설명은 1000자를 초과할 수 없습니다")
    val description: String? = null,
    
    @field:Size(max = 1000, message = "특이사항은 1000자를 초과할 수 없습니다")
    val specialNotes: String? = null
)

data class UpdateBuildingRequest(
    @field:NotBlank(message = "건물명은 필수입니다")
    @field:Size(max = 100, message = "건물명은 100자를 초과할 수 없습니다")
    val buildingName: String,
    
    @field:NotBlank(message = "주소는 필수입니다")
    @field:Size(max = 500, message = "주소는 500자를 초과할 수 없습니다")
    val address: String,
    
    @field:NotNull(message = "건물 유형은 필수입니다")
    val buildingType: BuildingType,
    
    @field:Min(value = 1, message = "총 층수는 1층 이상이어야 합니다")
    @field:Max(value = 200, message = "총 층수는 200층을 초과할 수 없습니다")
    val totalFloors: Int,
    
    @field:NotNull(message = "총 면적은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "총 면적은 0보다 커야 합니다")
    @field:DecimalMax(value = "999999999.99", message = "총 면적이 너무 큽니다")
    val totalFloorArea: BigDecimal,
    
    @field:Min(value = 1900, message = "건축년도는 1900년 이후여야 합니다")
    @field:Max(value = 2100, message = "건축년도는 2100년 이전이어야 합니다")
    val constructionYear: Int? = null,
    
    val completionDate: LocalDate? = null,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    @field:Min(value = 0, message = "엘리베이터 수는 0 이상이어야 합니다")
    val elevatorCount: Int? = null,
    
    val hasBasement: Boolean = false,
    
    @field:Min(value = 0, message = "지하 층수는 0 이상이어야 합니다")
    val basementFloors: Int? = null,
    
    val heatingType: HeatingType? = null,
    
    @field:Size(max = 20, message = "관리사무소 전화번호는 20자를 초과할 수 없습니다")
    val managementOfficePhone: String? = null,
    
    @field:Size(max = 200, message = "관리사무소 위치는 200자를 초과할 수 없습니다")
    val managementOfficeLocation: String? = null,
    
    @field:Size(max = 100, message = "보안 시스템 정보는 100자를 초과할 수 없습니다")
    val securitySystem: String? = null,
    
    @field:Min(value = 0, message = "CCTV 수는 0 이상이어야 합니다")
    val cctvCount: Int? = null,
    
    @field:Size(max = 10, message = "소방 안전 등급은 10자를 초과할 수 없습니다")
    val fireSafetyGrade: String? = null,
    
    @field:Size(max = 10, message = "에너지 효율 등급은 10자를 초과할 수 없습니다")
    val energyEfficiencyGrade: String? = null,
    
    @field:DecimalMin(value = "0", message = "평방미터당 관리비는 0 이상이어야 합니다")
    val maintenanceFeePerSqm: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "공용면적 비율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "공용면적 비율은 100 이하여야 합니다")
    val commonAreaRatio: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "대지면적은 0 이상이어야 합니다")
    val landArea: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "건폐율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "건폐율은 100 이하여야 합니다")
    val buildingCoverageRatio: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "용적률은 0 이상이어야 합니다")
    val floorAreaRatio: BigDecimal? = null,
    
    @field:Size(max = 1000, message = "설명은 1000자를 초과할 수 없습니다")
    val description: String? = null,
    
    @field:Size(max = 1000, message = "특이사항은 1000자를 초과할 수 없습니다")
    val specialNotes: String? = null
)

// Response DTOs
data class BuildingDto(
    val buildingId: UUID,
    val buildingName: String,
    val address: String,
    val buildingType: BuildingType,
    val buildingStatus: BuildingStatus,
    val totalFloors: Int,
    val totalFloorArea: BigDecimal,
    val constructionYear: Int?,
    val completionDate: LocalDate?,
    val totalUnitCount: Int,
    val occupiedUnitCount: Int,
    val vacantUnitCount: Int,
    val occupancyRate: BigDecimal,
    val parkingSpaces: Int?,
    val elevatorCount: Int?,
    val hasBasement: Boolean,
    val basementFloors: Int?,
    val heatingType: HeatingType?,
    val managementOfficePhone: String?,
    val managementOfficeLocation: String?,
    val securitySystem: String?,
    val cctvCount: Int?,
    val fireSafetyGrade: String?,
    val energyEfficiencyGrade: String?,
    val maintenanceFeePerSqm: BigDecimal?,
    val commonAreaRatio: BigDecimal?,
    val landArea: BigDecimal?,
    val buildingCoverageRatio: BigDecimal?,
    val floorAreaRatio: BigDecimal?,
    val description: String?,
    val specialNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class BuildingSummaryDto(
    val buildingId: UUID,
    val buildingName: String,
    val address: String,
    val buildingType: BuildingType,
    val buildingStatus: BuildingStatus,
    val totalFloors: Int,
    val totalFloorArea: BigDecimal,
    val totalUnitCount: Int,
    val occupiedUnitCount: Int,
    val occupancyRate: BigDecimal
)

data class BuildingStatsDto(
    val buildingId: UUID,
    val buildingName: String,
    val totalUnits: Long,
    val occupiedUnits: Long,
    val vacantUnits: Long,
    val occupancyRate: BigDecimal,
    val totalMonthlyRent: BigDecimal,
    val averageRentPerUnit: BigDecimal,
    val averageAreaPerUnit: BigDecimal
)