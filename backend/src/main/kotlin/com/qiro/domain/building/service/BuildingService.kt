package com.qiro.domain.building.service

import com.qiro.common.dto.PagedResponse
import com.qiro.common.exception.DuplicateEntityException
import com.qiro.common.exception.EntityNotFoundException
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.building.dto.*
import com.qiro.domain.building.entity.Building
import com.qiro.domain.building.entity.BuildingStatus
import com.qiro.domain.building.repository.BuildingRepository
import com.qiro.domain.building.repository.BuildingSearchCriteria
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

@Service
@Transactional(readOnly = true)
class BuildingService(
    private val buildingRepository: BuildingRepository,
    private val tenantContext: TenantContext
) {
    
    fun getBuildings(pageable: Pageable, search: String?): PagedResponse<BuildingSummaryDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        
        val buildings = if (search.isNullOrBlank()) {
            buildingRepository.findByCompanyIdAndBuildingStatus(companyId, BuildingStatus.ACTIVE, pageable)
        } else {
            buildingRepository.findByCompanyIdAndBuildingStatusAndSearch(
                companyId, BuildingStatus.ACTIVE, search, pageable
            )
        }
        
        return PagedResponse.of(buildings) { building ->
            BuildingSummaryDto(
                buildingId = building.id,
                buildingName = building.buildingName,
                address = building.address,
                buildingType = building.buildingType,
                buildingStatus = building.buildingStatus,
                totalFloors = building.totalFloors,
                totalFloorArea = building.totalFloorArea,
                totalUnitCount = building.totalUnitCount,
                occupiedUnitCount = building.occupiedUnitCount,
                occupancyRate = building.getOccupancyRate()
            )
        }
    }
    
    fun getBuildingById(id: UUID): BuildingDto {
        val companyId = tenantContext.getCurrentCompanyId()
        val building = buildingRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $id")
        
        return mapToDto(building)
    }
    
    @Transactional
    fun createBuilding(request: CreateBuildingRequest): BuildingDto {
        val companyId = tenantContext.getCurrentCompanyId()
        
        // 중복 건물명 검사
        if (buildingRepository.existsByCompanyIdAndBuildingName(companyId, request.buildingName)) {
            throw DuplicateEntityException("이미 존재하는 건물명입니다: ${request.buildingName}")
        }
        
        val building = Building(
            buildingName = request.buildingName,
            address = request.address,
            buildingType = request.buildingType,
            totalFloors = request.totalFloors,
            totalFloorArea = request.totalFloorArea,
            constructionYear = request.constructionYear,
            completionDate = request.completionDate,
            parkingSpaces = request.parkingSpaces,
            elevatorCount = request.elevatorCount,
            hasBasement = request.hasBasement,
            basementFloors = request.basementFloors,
            heatingType = request.heatingType,
            managementOfficePhone = request.managementOfficePhone,
            managementOfficeLocation = request.managementOfficeLocation,
            securitySystem = request.securitySystem,
            cctvCount = request.cctvCount,
            fireSafetyGrade = request.fireSafetyGrade,
            energyEfficiencyGrade = request.energyEfficiencyGrade,
            maintenanceFeePerSqm = request.maintenanceFeePerSqm,
            commonAreaRatio = request.commonAreaRatio,
            landArea = request.landArea,
            buildingCoverageRatio = request.buildingCoverageRatio,
            floorAreaRatio = request.floorAreaRatio,
            description = request.description,
            specialNotes = request.specialNotes
        ).apply {
            setCompanyId(companyId)
            createdBy = tenantContext.getCurrentCompanyId() // TODO: 실제 사용자 ID로 변경
            updatedBy = tenantContext.getCurrentCompanyId() // TODO: 실제 사용자 ID로 변경
        }
        
        val savedBuilding = buildingRepository.save(building)
        return mapToDto(savedBuilding)
    }
    
    @Transactional
    fun updateBuilding(id: UUID, request: UpdateBuildingRequest): BuildingDto {
        val companyId = tenantContext.getCurrentCompanyId()
        val building = buildingRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $id")
        
        // 중복 건물명 검사 (자신 제외)
        if (buildingRepository.existsByCompanyIdAndBuildingNameAndIdNot(
                companyId, request.buildingName, id
            )) {
            throw DuplicateEntityException("이미 존재하는 건물명입니다: ${request.buildingName}")
        }
        
        building.update(
            buildingName = request.buildingName,
            address = request.address,
            buildingType = request.buildingType,
            totalFloors = request.totalFloors,
            totalFloorArea = request.totalFloorArea,
            constructionYear = request.constructionYear,
            completionDate = request.completionDate,
            parkingSpaces = request.parkingSpaces,
            elevatorCount = request.elevatorCount,
            hasBasement = request.hasBasement,
            basementFloors = request.basementFloors,
            heatingType = request.heatingType,
            managementOfficePhone = request.managementOfficePhone,
            managementOfficeLocation = request.managementOfficeLocation,
            securitySystem = request.securitySystem,
            cctvCount = request.cctvCount,
            fireSafetyGrade = request.fireSafetyGrade,
            energyEfficiencyGrade = request.energyEfficiencyGrade,
            maintenanceFeePerSqm = request.maintenanceFeePerSqm,
            commonAreaRatio = request.commonAreaRatio,
            landArea = request.landArea,
            buildingCoverageRatio = request.buildingCoverageRatio,
            floorAreaRatio = request.floorAreaRatio,
            description = request.description,
            specialNotes = request.specialNotes
        )
        
        building.updatedBy = tenantContext.getCurrentCompanyId() // TODO: 실제 사용자 ID로 변경
        
        return mapToDto(building)
    }
    
    @Transactional
    fun deleteBuilding(id: UUID) {
        val companyId = tenantContext.getCurrentCompanyId()
        val building = buildingRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $id")
        
        // 소프트 삭제 (상태 변경)
        building.deactivate()
        building.updatedBy = tenantContext.getCurrentCompanyId() // TODO: 실제 사용자 ID로 변경
    }
    
    fun getBuildingsWithStatistics(pageable: Pageable): PagedResponse<BuildingStatsDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        val buildingsWithStats = buildingRepository.findBuildingsWithStatistics(companyId, pageable)
        
        return PagedResponse.of(buildingsWithStats) { stats ->
            BuildingStatsDto(
                buildingId = stats.buildingId,
                buildingName = stats.buildingName,
                totalUnits = stats.totalUnits,
                occupiedUnits = stats.occupiedUnits,
                vacantUnits = stats.vacantUnits,
                occupancyRate = stats.occupancyRate,
                totalMonthlyRent = stats.totalMonthlyRent,
                averageRentPerUnit = if (stats.totalUnits > 0) {
                    stats.totalMonthlyRent.divide(java.math.BigDecimal(stats.totalUnits), 2, java.math.RoundingMode.HALF_UP)
                } else {
                    java.math.BigDecimal.ZERO
                },
                averageAreaPerUnit = if (stats.totalUnits > 0) {
                    stats.totalFloorArea.divide(java.math.BigDecimal(stats.totalUnits), 2, java.math.RoundingMode.HALF_UP)
                } else {
                    java.math.BigDecimal.ZERO
                }
            )
        }
    }
    
    fun searchBuildings(searchCriteria: BuildingSearchCriteria): List<BuildingSummaryDto> {
        val buildings = buildingRepository.findBuildingsByComplexConditions(searchCriteria)
        
        return buildings.map { building ->
            BuildingSummaryDto(
                buildingId = building.id,
                buildingName = building.buildingName,
                address = building.address,
                buildingType = building.buildingType,
                buildingStatus = building.buildingStatus,
                totalFloors = building.totalFloors,
                totalFloorArea = building.totalFloorArea,
                totalUnitCount = building.totalUnitCount,
                occupiedUnitCount = building.occupiedUnitCount,
                occupancyRate = building.getOccupancyRate()
            )
        }
    }
    
    private fun mapToDto(building: Building): BuildingDto {
        return BuildingDto(
            buildingId = building.id,
            buildingName = building.buildingName,
            address = building.address,
            buildingType = building.buildingType,
            buildingStatus = building.buildingStatus,
            totalFloors = building.totalFloors,
            totalFloorArea = building.totalFloorArea,
            constructionYear = building.constructionYear,
            completionDate = building.completionDate,
            totalUnitCount = building.totalUnitCount,
            occupiedUnitCount = building.occupiedUnitCount,
            vacantUnitCount = building.getVacantUnitCount(),
            occupancyRate = building.getOccupancyRate(),
            parkingSpaces = building.parkingSpaces,
            elevatorCount = building.elevatorCount,
            hasBasement = building.hasBasement,
            basementFloors = building.basementFloors,
            heatingType = building.heatingType,
            managementOfficePhone = building.managementOfficePhone,
            managementOfficeLocation = building.managementOfficeLocation,
            securitySystem = building.securitySystem,
            cctvCount = building.cctvCount,
            fireSafetyGrade = building.fireSafetyGrade,
            energyEfficiencyGrade = building.energyEfficiencyGrade,
            maintenanceFeePerSqm = building.maintenanceFeePerSqm,
            commonAreaRatio = building.commonAreaRatio,
            landArea = building.landArea,
            buildingCoverageRatio = building.buildingCoverageRatio,
            floorAreaRatio = building.floorAreaRatio,
            description = building.description,
            specialNotes = building.specialNotes,
            createdAt = building.createdAt,
            updatedAt = building.updatedAt
        )
    }
}