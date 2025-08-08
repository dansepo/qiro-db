package com.qiro.domain.unit.service

import com.qiro.common.dto.PagedResponse
import com.qiro.common.exception.DuplicateEntityException
import com.qiro.common.exception.EntityNotFoundException
import com.qiro.common.exception.InvalidBusinessRuleException
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.building.repository.BuildingRepository
import com.qiro.domain.unit.dto.*
import com.qiro.domain.unit.entity.Unit
import com.qiro.domain.unit.entity.UnitStatus
import com.qiro.domain.unit.repository.UnitRepository
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.util.*

@Service
@Transactional(readOnly = true)
class UnitService(
    private val unitRepository: UnitRepository,
    private val buildingRepository: BuildingRepository,
    private val tenantContext: TenantContext
) {
    
    fun getUnitsByBuilding(buildingId: UUID, pageable: Pageable, search: String?): PagedResponse<UnitSummaryDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        
        // 건물 존재 확인
        buildingRepository.findByIdAndCompanyId(buildingId, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $buildingId")
        
        val units = if (search.isNullOrBlank()) {
            unitRepository.findByBuildingIdAndCompanyId(buildingId, companyId, pageable)
        } else {
            unitRepository.findByBuildingIdAndCompanyIdAndSearch(buildingId, companyId, search, pageable)
        }
        
        return PagedResponse.of(units) { unit ->
            UnitSummaryDto(
                unitId = unit.id,
                buildingId = unit.building.id,
                buildingName = unit.building.buildingName,
                unitNumber = unit.unitNumber,
                floor = unit.floor,
                exclusiveArea = unit.exclusiveArea,
                totalArea = unit.getTotalArea(),
                unitType = unit.unitType,
                currentStatus = unit.currentStatus,
                monthlyRent = unit.monthlyRent,
                facingDirection = unit.facingDirection
            )
        }
    }
    
    fun getUnitById(id: UUID): UnitDto {
        val companyId = tenantContext.getCurrentCompanyId()
        val unit = unitRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("세대를 찾을 수 없습니다: $id")
        
        return mapToDto(unit)
    }
    
    @Transactional
    fun createUnit(request: CreateUnitRequest): UnitDto {
        val companyId = tenantContext.getCurrentCompanyId()
        
        // 건물 존재 확인
        val building = buildingRepository.findByIdAndCompanyId(request.buildingId, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: ${request.buildingId}")
        
        // 중복 세대 번호 검사
        if (unitRepository.existsByBuildingIdAndUnitNumber(request.buildingId, request.unitNumber)) {
            throw DuplicateEntityException("이미 존재하는 세대 번호입니다: ${request.unitNumber}")
        }
        
        val unit = Unit(
            unitNumber = request.unitNumber,
            floor = request.floor,
            exclusiveArea = request.exclusiveArea,
            commonArea = request.commonArea,
            unitType = request.unitType,
            roomCount = request.roomCount,
            bathroomCount = request.bathroomCount,
            balconyCount = request.balconyCount,
            hasTerrace = request.hasTerrace,
            terraceArea = request.terraceArea,
            parkingSpaces = request.parkingSpaces,
            storageSpaces = request.storageSpaces,
            facingDirection = request.facingDirection,
            hasElevatorAccess = request.hasElevatorAccess,
            monthlyRent = request.monthlyRent,
            securityDeposit = request.securityDeposit,
            maintenanceFee = request.maintenanceFee,
            utilityIncluded = request.utilityIncluded,
            furnished = request.furnished,
            petAllowed = request.petAllowed,
            smokingAllowed = request.smokingAllowed,
            lastRenovationDate = request.lastRenovationDate,
            conditionRating = request.conditionRating,
            specialFeatures = request.specialFeatures,
            description = request.description,
            internalNotes = request.internalNotes
        ).apply {
            setCompanyId(companyId)
            this.building = building
            createdBy = companyId // TODO: 실제 사용자 ID로 변경
            updatedBy = companyId // TODO: 실제 사용자 ID로 변경
        }
        
        val savedUnit = unitRepository.save(unit)
        
        // 건물의 총 세대 수 업데이트
        updateBuildingUnitCounts(request.buildingId)
        
        return mapToDto(savedUnit)
    }
    
    @Transactional
    fun updateUnit(id: UUID, request: UpdateUnitRequest): UnitDto {
        val companyId = tenantContext.getCurrentCompanyId()
        val unit = unitRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("세대를 찾을 수 없습니다: $id")
        
        // 중복 세대 번호 검사 (자신 제외)
        if (unitRepository.existsByBuildingIdAndUnitNumberAndIdNot(
                unit.building.id, request.unitNumber, id
            )) {
            throw DuplicateEntityException("이미 존재하는 세대 번호입니다: ${request.unitNumber}")
        }
        
        unit.update(
            unitNumber = request.unitNumber,
            floor = request.floor,
            exclusiveArea = request.exclusiveArea,
            commonArea = request.commonArea,
            unitType = request.unitType,
            roomCount = request.roomCount,
            bathroomCount = request.bathroomCount,
            balconyCount = request.balconyCount,
            hasTerrace = request.hasTerrace,
            terraceArea = request.terraceArea,
            parkingSpaces = request.parkingSpaces,
            storageSpaces = request.storageSpaces,
            facingDirection = request.facingDirection,
            hasElevatorAccess = request.hasElevatorAccess,
            monthlyRent = request.monthlyRent,
            securityDeposit = request.securityDeposit,
            maintenanceFee = request.maintenanceFee,
            utilityIncluded = request.utilityIncluded,
            furnished = request.furnished,
            petAllowed = request.petAllowed,
            smokingAllowed = request.smokingAllowed,
            lastRenovationDate = request.lastRenovationDate,
            conditionRating = request.conditionRating,
            specialFeatures = request.specialFeatures,
            description = request.description,
            internalNotes = request.internalNotes
        )
        
        unit.updatedBy = companyId // TODO: 실제 사용자 ID로 변경
        
        return mapToDto(unit)
    }
    
    @Transactional
    fun updateUnitStatus(id: UUID, request: UpdateUnitStatusRequest): UnitDto {
        val companyId = tenantContext.getCurrentCompanyId()
        val unit = unitRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("세대를 찾을 수 없습니다: $id")
        
        val previousStatus = unit.currentStatus
        
        when (request.status) {
            UnitStatus.OCCUPIED -> {
                if (request.moveInDate == null) {
                    throw InvalidBusinessRuleException("입주일은 필수입니다")
                }
                unit.occupy(request.moveInDate)
            }
            UnitStatus.VACANT -> {
                if (request.moveOutDate == null) {
                    throw InvalidBusinessRuleException("퇴거일은 필수입니다")
                }
                unit.vacate(request.moveOutDate)
            }
            UnitStatus.UNDER_MAINTENANCE -> unit.setUnderMaintenance()
            UnitStatus.UNDER_RENOVATION -> unit.setUnderRenovation()
            UnitStatus.RESERVED -> unit.setReserved()
            UnitStatus.UNAVAILABLE -> unit.setUnavailable()
        }
        
        unit.updatedBy = companyId // TODO: 실제 사용자 ID로 변경
        
        // 상태가 변경된 경우 건물 통계 업데이트
        if (previousStatus != request.status) {
            updateBuildingUnitCounts(unit.building.id)
        }
        
        return mapToDto(unit)
    }
    
    @Transactional
    fun deleteUnit(id: UUID) {
        val companyId = tenantContext.getCurrentCompanyId()
        val unit = unitRepository.findByIdAndCompanyId(id, companyId)
            ?: throw EntityNotFoundException("세대를 찾을 수 없습니다: $id")
        
        // 임대중인 세대는 삭제할 수 없음
        if (unit.currentStatus == UnitStatus.OCCUPIED) {
            throw InvalidBusinessRuleException("임대중인 세대는 삭제할 수 없습니다")
        }
        
        val buildingId = unit.building.id
        unitRepository.delete(unit)
        
        // 건물의 총 세대 수 업데이트
        updateBuildingUnitCounts(buildingId)
    }
    
    fun searchAvailableUnits(searchRequest: UnitSearchRequest, pageable: Pageable): PagedResponse<UnitSummaryDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        
        val units = unitRepository.findAvailableUnits(
            companyId = companyId,
            status = searchRequest.status ?: UnitStatus.VACANT,
            unitType = searchRequest.unitType,
            minArea = searchRequest.minArea,
            maxArea = searchRequest.maxArea,
            minRent = searchRequest.minRent,
            maxRent = searchRequest.maxRent,
            floor = searchRequest.floor,
            petAllowed = searchRequest.petAllowed,
            furnished = searchRequest.furnished,
            pageable = pageable
        )
        
        return PagedResponse.of(units) { unit ->
            UnitSummaryDto(
                unitId = unit.id,
                buildingId = unit.building.id,
                buildingName = unit.building.buildingName,
                unitNumber = unit.unitNumber,
                floor = unit.floor,
                exclusiveArea = unit.exclusiveArea,
                totalArea = unit.getTotalArea(),
                unitType = unit.unitType,
                currentStatus = unit.currentStatus,
                monthlyRent = unit.monthlyRent,
                facingDirection = unit.facingDirection
            )
        }
    }
    
    fun getUnitStatusStatistics(buildingId: UUID): List<UnitStatusStatsDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        
        // 건물 존재 확인
        buildingRepository.findByIdAndCompanyId(buildingId, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $buildingId")
        
        val statistics = unitRepository.getUnitStatusStatistics(buildingId, companyId)
        val totalCount = statistics.sumOf { it.count }
        
        return statistics.map { stat ->
            UnitStatusStatsDto(
                status = stat.status,
                count = stat.count,
                percentage = if (totalCount > 0) {
                    BigDecimal(stat.count).divide(BigDecimal(totalCount), 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal(100))
                } else {
                    BigDecimal.ZERO
                }
            )
        }
    }
    
    fun getUnitTypeStatistics(buildingId: UUID): List<UnitTypeStatsDto> {
        val companyId = tenantContext.getCurrentCompanyId()
        
        // 건물 존재 확인
        buildingRepository.findByIdAndCompanyId(buildingId, companyId)
            ?: throw EntityNotFoundException("건물을 찾을 수 없습니다: $buildingId")
        
        val statistics = unitRepository.getUnitTypeStatistics(buildingId, companyId)
        val totalCount = statistics.sumOf { it.count }
        
        return statistics.map { stat ->
            UnitTypeStatsDto(
                type = stat.type,
                count = stat.count,
                averageRent = stat.averageRent,
                averageArea = stat.averageArea,
                percentage = if (totalCount > 0) {
                    BigDecimal(stat.count).divide(BigDecimal(totalCount), 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal(100))
                } else {
                    BigDecimal.ZERO
                }
            )
        }
    }
    
    @Transactional
    private fun updateBuildingUnitCounts(buildingId: UUID) {
        val companyId = tenantContext.getCurrentCompanyId()
        val building = buildingRepository.findByIdAndCompanyId(buildingId, companyId)
            ?: return
        
        val totalUnits = unitRepository.countByBuildingIdAndCompanyId(buildingId, companyId).toInt()
        val occupiedUnits = unitRepository.countByBuildingIdAndCompanyIdAndCurrentStatus(
            buildingId, companyId, UnitStatus.OCCUPIED
        ).toInt()
        
        building.updateUnitCounts(totalUnits, occupiedUnits)
    }
    
    private fun mapToDto(unit: Unit): UnitDto {
        return UnitDto(
            unitId = unit.id,
            buildingId = unit.building.id,
            buildingName = unit.building.buildingName,
            unitNumber = unit.unitNumber,
            floor = unit.floor,
            exclusiveArea = unit.exclusiveArea,
            commonArea = unit.commonArea,
            totalArea = unit.getTotalArea(),
            unitType = unit.unitType,
            currentStatus = unit.currentStatus,
            roomCount = unit.roomCount,
            bathroomCount = unit.bathroomCount,
            balconyCount = unit.balconyCount,
            hasTerrace = unit.hasTerrace,
            terraceArea = unit.terraceArea,
            parkingSpaces = unit.parkingSpaces,
            storageSpaces = unit.storageSpaces,
            facingDirection = unit.facingDirection,
            hasElevatorAccess = unit.hasElevatorAccess,
            monthlyRent = unit.monthlyRent,
            securityDeposit = unit.securityDeposit,
            maintenanceFee = unit.maintenanceFee,
            utilityIncluded = unit.utilityIncluded,
            furnished = unit.furnished,
            petAllowed = unit.petAllowed,
            smokingAllowed = unit.smokingAllowed,
            moveInDate = unit.moveInDate,
            moveOutDate = unit.moveOutDate,
            lastRenovationDate = unit.lastRenovationDate,
            conditionRating = unit.conditionRating,
            specialFeatures = unit.specialFeatures,
            description = unit.description,
            internalNotes = unit.internalNotes,
            createdAt = unit.createdAt,
            updatedAt = unit.updatedAt
        )
    }
}