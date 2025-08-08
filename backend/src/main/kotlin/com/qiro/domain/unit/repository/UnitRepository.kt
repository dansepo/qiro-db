package com.qiro.domain.unit.repository

import com.qiro.domain.unit.entity.Unit
import com.qiro.domain.unit.entity.UnitStatus
import com.qiro.domain.unit.entity.UnitType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UnitRepository : JpaRepository<Unit, UUID> {
    
    fun findByBuildingIdAndCompanyId(buildingId: UUID, companyId: UUID, pageable: Pageable): Page<Unit>
    
    fun findByIdAndCompanyId(id: UUID, companyId: UUID): Unit?
    
    fun findByBuildingIdAndCompanyIdAndCurrentStatus(
        buildingId: UUID, 
        companyId: UUID, 
        currentStatus: UnitStatus, 
        pageable: Pageable
    ): Page<Unit>
    
    @Query("""
        SELECT u FROM Unit u 
        WHERE u.building.id = :buildingId 
        AND u.companyId = :companyId
        AND (
            u.unitNumber LIKE CONCAT('%', :search, '%') OR
            CAST(u.floor AS string) LIKE CONCAT('%', :search, '%')
        )
    """)
    fun findByBuildingIdAndCompanyIdAndSearch(
        @Param("buildingId") buildingId: UUID,
        @Param("companyId") companyId: UUID,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<Unit>
    
    fun countByBuildingIdAndCompanyId(buildingId: UUID, companyId: UUID): Long
    
    fun countByBuildingIdAndCompanyIdAndCurrentStatus(
        buildingId: UUID, 
        companyId: UUID, 
        currentStatus: UnitStatus
    ): Long
    
    fun countByCompanyIdAndCurrentStatus(companyId: UUID, currentStatus: UnitStatus): Long
    
    fun existsByBuildingIdAndUnitNumber(buildingId: UUID, unitNumber: String): Boolean
    
    fun existsByBuildingIdAndUnitNumberAndIdNot(
        buildingId: UUID, 
        unitNumber: String, 
        id: UUID
    ): Boolean
    
    @Query("""
        SELECT u FROM Unit u 
        WHERE u.companyId = :companyId 
        AND u.currentStatus = :status
        AND (:unitType IS NULL OR u.unitType = :unitType)
        AND (:minArea IS NULL OR u.exclusiveArea >= :minArea)
        AND (:maxArea IS NULL OR u.exclusiveArea <= :maxArea)
        AND (:minRent IS NULL OR u.monthlyRent >= :minRent)
        AND (:maxRent IS NULL OR u.monthlyRent <= :maxRent)
        AND (:floor IS NULL OR u.floor = :floor)
        AND (:petAllowed IS NULL OR u.petAllowed = :petAllowed)
        AND (:furnished IS NULL OR u.furnished = :furnished)
    """)
    fun findAvailableUnits(
        @Param("companyId") companyId: UUID,
        @Param("status") status: UnitStatus,
        @Param("unitType") unitType: UnitType?,
        @Param("minArea") minArea: java.math.BigDecimal?,
        @Param("maxArea") maxArea: java.math.BigDecimal?,
        @Param("minRent") minRent: java.math.BigDecimal?,
        @Param("maxRent") maxRent: java.math.BigDecimal?,
        @Param("floor") floor: Int?,
        @Param("petAllowed") petAllowed: Boolean?,
        @Param("furnished") furnished: Boolean?,
        pageable: Pageable
    ): Page<Unit>
    
    @Query("""
        SELECT u FROM Unit u 
        WHERE u.building.id = :buildingId 
        AND u.companyId = :companyId
        ORDER BY u.floor ASC, u.unitNumber ASC
    """)
    fun findByBuildingIdOrderByFloorAndUnitNumber(
        @Param("buildingId") buildingId: UUID,
        @Param("companyId") companyId: UUID
    ): List<Unit>
    
    @Query("""
        SELECT 
            u.currentStatus as status,
            COUNT(u) as count
        FROM Unit u 
        WHERE u.building.id = :buildingId 
        AND u.companyId = :companyId
        GROUP BY u.currentStatus
    """)
    fun getUnitStatusStatistics(
        @Param("buildingId") buildingId: UUID,
        @Param("companyId") companyId: UUID
    ): List<UnitStatusStatistics>
    
    @Query("""
        SELECT 
            u.unitType as type,
            COUNT(u) as count,
            AVG(u.monthlyRent) as averageRent,
            AVG(u.exclusiveArea) as averageArea
        FROM Unit u 
        WHERE u.building.id = :buildingId 
        AND u.companyId = :companyId
        GROUP BY u.unitType
    """)
    fun getUnitTypeStatistics(
        @Param("buildingId") buildingId: UUID,
        @Param("companyId") companyId: UUID
    ): List<UnitTypeStatistics>
}

interface UnitStatusStatistics {
    val status: UnitStatus
    val count: Long
}

interface UnitTypeStatistics {
    val type: UnitType
    val count: Long
    val averageRent: java.math.BigDecimal?
    val averageArea: java.math.BigDecimal
}