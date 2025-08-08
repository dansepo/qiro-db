package com.qiro.domain.building.repository

import com.qiro.domain.building.entity.Building
import com.qiro.domain.building.entity.QBuilding
import com.qiro.domain.unit.entity.QUnit
import com.querydsl.core.BooleanBuilder
import com.querydsl.core.types.Projections
import com.querydsl.jpa.impl.JPAQueryFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.util.*

@Repository
class BuildingRepositoryImpl(
    private val queryFactory: JPAQueryFactory
) : BuildingRepositoryCustom {
    
    private val building = QBuilding.building
    private val unit = QUnit.unit
    
    override fun findBuildingsWithStatistics(
        companyId: UUID, 
        pageable: Pageable
    ): Page<BuildingWithStats> {
        val query = queryFactory
            .select(
                Projections.constructor(
                    BuildingWithStats::class.java,
                    building.id,
                    building.buildingName,
                    building.address,
                    building.buildingType.stringValue(),
                    building.totalFloors,
                    building.totalFloorArea,
                    unit.count().coalesce(0L),
                    unit.count().filter(unit.currentStatus.eq(com.qiro.domain.unit.entity.UnitStatus.OCCUPIED)).coalesce(0L),
                    unit.count().filter(unit.currentStatus.eq(com.qiro.domain.unit.entity.UnitStatus.VACANT)).coalesce(0L),
                    building.occupiedUnitCount.multiply(100.0).divide(building.totalUnitCount.coalesce(1)).coalesce(0.0),
                    unit.monthlyRent.sum().coalesce(BigDecimal.ZERO)
                )
            )
            .from(building)
            .leftJoin(unit).on(unit.building.id.eq(building.id))
            .where(building.companyId.eq(companyId))
            .groupBy(building.id)
            .orderBy(building.buildingName.asc())
            
        val results = query
            .offset(pageable.offset)
            .limit(pageable.pageSize.toLong())
            .fetch()
            
        val total = queryFactory
            .select(building.count())
            .from(building)
            .where(building.companyId.eq(companyId))
            .fetchOne() ?: 0L
            
        return PageImpl(results, pageable, total)
    }
    
    override fun findBuildingsByComplexConditions(
        searchCriteria: BuildingSearchCriteria
    ): List<Building> {
        val whereClause = BooleanBuilder()
        
        whereClause.and(building.companyId.eq(searchCriteria.companyId))
        
        searchCriteria.buildingName?.let { name ->
            whereClause.and(building.buildingName.containsIgnoreCase(name))
        }
        
        searchCriteria.address?.let { address ->
            whereClause.and(building.address.containsIgnoreCase(address))
        }
        
        searchCriteria.buildingType?.let { type ->
            whereClause.and(building.buildingType.eq(com.qiro.domain.building.entity.BuildingType.valueOf(type)))
        }
        
        searchCriteria.buildingStatus?.let { status ->
            whereClause.and(building.buildingStatus.eq(status))
        }
        
        searchCriteria.minFloors?.let { minFloors ->
            whereClause.and(building.totalFloors.goe(minFloors))
        }
        
        searchCriteria.maxFloors?.let { maxFloors ->
            whereClause.and(building.totalFloors.loe(maxFloors))
        }
        
        searchCriteria.minArea?.let { minArea ->
            whereClause.and(building.totalFloorArea.goe(minArea))
        }
        
        searchCriteria.maxArea?.let { maxArea ->
            whereClause.and(building.totalFloorArea.loe(maxArea))
        }
        
        searchCriteria.hasParking?.let { hasParking ->
            if (hasParking) {
                whereClause.and(building.parkingSpaces.gt(0))
            } else {
                whereClause.and(building.parkingSpaces.isNull.or(building.parkingSpaces.eq(0)))
            }
        }
        
        searchCriteria.hasElevator?.let { hasElevator ->
            if (hasElevator) {
                whereClause.and(building.elevatorCount.gt(0))
            } else {
                whereClause.and(building.elevatorCount.isNull.or(building.elevatorCount.eq(0)))
            }
        }
        
        return queryFactory
            .selectFrom(building)
            .where(whereClause)
            .orderBy(building.buildingName.asc())
            .fetch()
    }
}