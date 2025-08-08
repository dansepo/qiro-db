package com.qiro.domain.building.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate

@Entity
@Table(name = "buildings")
class Building(
    @Column(name = "building_name", nullable = false, length = 100)
    var buildingName: String,
    
    @Column(name = "address", nullable = false, length = 500)
    var address: String,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "building_type", nullable = false, length = 50)
    var buildingType: BuildingType,
    
    @Column(name = "total_floors", nullable = false)
    var totalFloors: Int,
    
    @Column(name = "total_floor_area", nullable = false, precision = 10, scale = 2)
    var totalFloorArea: BigDecimal,
    
    @Column(name = "construction_year")
    var constructionYear: Int? = null,
    
    @Column(name = "completion_date")
    var completionDate: LocalDate? = null,
    
    @Column(name = "total_unit_count", nullable = false)
    var totalUnitCount: Int = 0,
    
    @Column(name = "occupied_unit_count", nullable = false)
    var occupiedUnitCount: Int = 0,
    
    @Column(name = "parking_spaces")
    var parkingSpaces: Int? = null,
    
    @Column(name = "elevator_count")
    var elevatorCount: Int? = null,
    
    @Column(name = "has_basement", nullable = false)
    var hasBasement: Boolean = false,
    
    @Column(name = "basement_floors")
    var basementFloors: Int? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "heating_type", length = 50)
    var heatingType: HeatingType? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "building_status", nullable = false, length = 20)
    var buildingStatus: BuildingStatus = BuildingStatus.ACTIVE,
    
    @Column(name = "management_office_phone", length = 20)
    var managementOfficePhone: String? = null,
    
    @Column(name = "management_office_location", length = 200)
    var managementOfficeLocation: String? = null,
    
    @Column(name = "security_system", length = 100)
    var securitySystem: String? = null,
    
    @Column(name = "cctv_count")
    var cctvCount: Int? = null,
    
    @Column(name = "fire_safety_grade", length = 10)
    var fireSafetyGrade: String? = null,
    
    @Column(name = "energy_efficiency_grade", length = 10)
    var energyEfficiencyGrade: String? = null,
    
    @Column(name = "maintenance_fee_per_sqm", precision = 8, scale = 2)
    var maintenanceFeePerSqm: BigDecimal? = null,
    
    @Column(name = "common_area_ratio", precision = 5, scale = 2)
    var commonAreaRatio: BigDecimal? = null,
    
    @Column(name = "land_area", precision = 10, scale = 2)
    var landArea: BigDecimal? = null,
    
    @Column(name = "building_coverage_ratio", precision = 5, scale = 2)
    var buildingCoverageRatio: BigDecimal? = null,
    
    @Column(name = "floor_area_ratio", precision = 5, scale = 2)
    var floorAreaRatio: BigDecimal? = null,
    
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null,
    
    @Column(name = "special_notes", columnDefinition = "TEXT")
    var specialNotes: String? = null
) : TenantAwareEntity() {
    
    fun update(
        buildingName: String,
        address: String,
        buildingType: BuildingType,
        totalFloors: Int,
        totalFloorArea: BigDecimal,
        constructionYear: Int? = null,
        completionDate: LocalDate? = null,
        parkingSpaces: Int? = null,
        elevatorCount: Int? = null,
        hasBasement: Boolean = false,
        basementFloors: Int? = null,
        heatingType: HeatingType? = null,
        managementOfficePhone: String? = null,
        managementOfficeLocation: String? = null,
        securitySystem: String? = null,
        cctvCount: Int? = null,
        fireSafetyGrade: String? = null,
        energyEfficiencyGrade: String? = null,
        maintenanceFeePerSqm: BigDecimal? = null,
        commonAreaRatio: BigDecimal? = null,
        landArea: BigDecimal? = null,
        buildingCoverageRatio: BigDecimal? = null,
        floorAreaRatio: BigDecimal? = null,
        description: String? = null,
        specialNotes: String? = null
    ) {
        this.buildingName = buildingName
        this.address = address
        this.buildingType = buildingType
        this.totalFloors = totalFloors
        this.totalFloorArea = totalFloorArea
        this.constructionYear = constructionYear
        this.completionDate = completionDate
        this.parkingSpaces = parkingSpaces
        this.elevatorCount = elevatorCount
        this.hasBasement = hasBasement
        this.basementFloors = basementFloors
        this.heatingType = heatingType
        this.managementOfficePhone = managementOfficePhone
        this.managementOfficeLocation = managementOfficeLocation
        this.securitySystem = securitySystem
        this.cctvCount = cctvCount
        this.fireSafetyGrade = fireSafetyGrade
        this.energyEfficiencyGrade = energyEfficiencyGrade
        this.maintenanceFeePerSqm = maintenanceFeePerSqm
        this.commonAreaRatio = commonAreaRatio
        this.landArea = landArea
        this.buildingCoverageRatio = buildingCoverageRatio
        this.floorAreaRatio = floorAreaRatio
        this.description = description
        this.specialNotes = specialNotes
    }
    
    fun updateUnitCounts(totalUnits: Int, occupiedUnits: Int) {
        this.totalUnitCount = totalUnits
        this.occupiedUnitCount = occupiedUnits
    }
    
    fun getOccupancyRate(): BigDecimal {
        return if (totalUnitCount > 0) {
            BigDecimal(occupiedUnitCount).divide(BigDecimal(totalUnitCount), 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal(100))
        } else {
            BigDecimal.ZERO
        }
    }
    
    fun getVacantUnitCount(): Int {
        return totalUnitCount - occupiedUnitCount
    }
    
    fun activate() {
        this.buildingStatus = BuildingStatus.ACTIVE
    }
    
    fun deactivate() {
        this.buildingStatus = BuildingStatus.INACTIVE
    }
    
    fun setUnderMaintenance() {
        this.buildingStatus = BuildingStatus.UNDER_MAINTENANCE
    }
    
    fun setUnderConstruction() {
        this.buildingStatus = BuildingStatus.UNDER_CONSTRUCTION
    }
}

enum class BuildingType(val displayName: String) {
    RESIDENTIAL("주거용"),
    COMMERCIAL("상업용"),
    OFFICE("사무용"),
    MIXED_USE("복합용도"),
    INDUSTRIAL("공업용"),
    WAREHOUSE("창고용"),
    RETAIL("소매용"),
    HOTEL("숙박용"),
    MEDICAL("의료용"),
    EDUCATIONAL("교육용"),
    RELIGIOUS("종교용"),
    CULTURAL("문화용"),
    SPORTS("체육용"),
    OTHER("기타")
}

enum class HeatingType(val displayName: String) {
    CENTRAL_HEATING("중앙난방"),
    INDIVIDUAL_HEATING("개별난방"),
    DISTRICT_HEATING("지역난방"),
    ELECTRIC_HEATING("전기난방"),
    GAS_HEATING("가스난방"),
    OIL_HEATING("기름난방"),
    HEAT_PUMP("히트펌프"),
    SOLAR_HEATING("태양열난방"),
    OTHER("기타")
}

enum class BuildingStatus(val displayName: String) {
    ACTIVE("운영중"),
    INACTIVE("비운영"),
    UNDER_CONSTRUCTION("건설중"),
    UNDER_MAINTENANCE("정비중"),
    DEMOLISHED("철거됨")
}