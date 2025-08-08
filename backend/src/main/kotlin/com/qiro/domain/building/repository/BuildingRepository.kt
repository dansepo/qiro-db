package com.qiro.domain.building.repository

import com.qiro.domain.building.entity.Building
import com.qiro.domain.building.entity.BuildingStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface BuildingRepository : JpaRepository<Building, UUID>, BuildingRepositoryCustom {
    
    fun findByCompanyId(companyId: UUID, pageable: Pageable): Page<Building>
    
    fun findByIdAndCompanyId(id: UUID, companyId: UUID): Building?
    
    fun findByCompanyIdAndBuildingStatus(
        companyId: UUID, 
        buildingStatus: BuildingStatus, 
        pageable: Pageable
    ): Page<Building>
    
    @Query("""
        SELECT b FROM Building b 
        WHERE b.companyId = :companyId 
        AND b.buildingStatus = :status
        AND (
            LOWER(b.buildingName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            LOWER(b.address) LIKE LOWER(CONCAT('%', :search, '%'))
        )
    """)
    fun findByCompanyIdAndBuildingStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("status") status: BuildingStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<Building>
    
    fun countByCompanyId(companyId: UUID): Long
    
    fun countByCompanyIdAndBuildingStatus(companyId: UUID, buildingStatus: BuildingStatus): Long
    
    fun existsByCompanyIdAndBuildingName(companyId: UUID, buildingName: String): Boolean
    
    fun existsByCompanyIdAndBuildingNameAndIdNot(
        companyId: UUID, 
        buildingName: String, 
        id: UUID
    ): Boolean
}

interface BuildingRepositoryCustom {
    fun findBuildingsWithStatistics(companyId: UUID, pageable: Pageable): Page<BuildingWithStats>
    fun findBuildingsByComplexConditions(searchCriteria: BuildingSearchCriteria): List<Building>
}

data class BuildingWithStats(
    val buildingId: UUID,
    val buildingName: String,
    val address: String,
    val buildingType: String,
    val totalFloors: Int,
    val totalFloorArea: java.math.BigDecimal,
    val totalUnits: Long,
    val occupiedUnits: Long,
    val vacantUnits: Long,
    val occupancyRate: java.math.BigDecimal,
    val totalMonthlyRent: java.math.BigDecimal
)

data class BuildingSearchCriteria(
    val companyId: UUID,
    val buildingName: String? = null,
    val address: String? = null,
    val buildingType: String? = null,
    val buildingStatus: BuildingStatus? = null,
    val minFloors: Int? = null,
    val maxFloors: Int? = null,
    val minArea: java.math.BigDecimal? = null,
    val maxArea: java.math.BigDecimal? = null,
    val hasParking: Boolean? = null,
    val hasElevator: Boolean? = null
)