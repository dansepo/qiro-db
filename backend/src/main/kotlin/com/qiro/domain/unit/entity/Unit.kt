package com.qiro.domain.unit.entity

import com.qiro.common.entity.TenantAwareEntity
import com.qiro.domain.building.entity.Building
import jakarta.persistence.*
import java.math.BigDecimal

@Entity
@Table(name = "units")
class Unit(
    @Column(name = "unit_number", nullable = false, length = 20)
    var unitNumber: String,
    
    @Column(name = "floor", nullable = false)
    var floor: Int,
    
    @Column(name = "exclusive_area", nullable = false, precision = 8, scale = 2)
    var exclusiveArea: BigDecimal,
    
    @Column(name = "common_area", precision = 8, scale = 2)
    var commonArea: BigDecimal? = null,
    
    @Column(name = "total_area", precision = 8, scale = 2)
    var totalArea: BigDecimal? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "unit_type", nullable = false, length = 50)
    var unitType: UnitType,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "current_status", nullable = false, length = 20)
    var currentStatus: UnitStatus = UnitStatus.VACANT,
    
    @Column(name = "room_count")
    var roomCount: Int? = null,
    
    @Column(name = "bathroom_count")
    var bathroomCount: Int? = null,
    
    @Column(name = "balcony_count")
    var balconyCount: Int? = null,
    
    @Column(name = "has_terrace", nullable = false)
    var hasTerrace: Boolean = false,
    
    @Column(name = "terrace_area", precision = 8, scale = 2)
    var terraceArea: BigDecimal? = null,
    
    @Column(name = "parking_spaces")
    var parkingSpaces: Int? = null,
    
    @Column(name = "storage_spaces")
    var storageSpaces: Int? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "facing_direction", length = 20)
    var facingDirection: FacingDirection? = null,
    
    @Column(name = "has_elevator_access", nullable = false)
    var hasElevatorAccess: Boolean = false,
    
    @Column(name = "monthly_rent", precision = 12, scale = 2)
    var monthlyRent: BigDecimal? = null,
    
    @Column(name = "security_deposit", precision = 12, scale = 2)
    var securityDeposit: BigDecimal? = null,
    
    @Column(name = "maintenance_fee", precision = 10, scale = 2)
    var maintenanceFee: BigDecimal? = null,
    
    @Column(name = "utility_included", nullable = false)
    var utilityIncluded: Boolean = false,
    
    @Column(name = "furnished", nullable = false)
    var furnished: Boolean = false,
    
    @Column(name = "pet_allowed", nullable = false)
    var petAllowed: Boolean = false,
    
    @Column(name = "smoking_allowed", nullable = false)
    var smokingAllowed: Boolean = false,
    
    @Column(name = "move_in_date")
    var moveInDate: java.time.LocalDate? = null,
    
    @Column(name = "move_out_date")
    var moveOutDate: java.time.LocalDate? = null,
    
    @Column(name = "last_renovation_date")
    var lastRenovationDate: java.time.LocalDate? = null,
    
    @Column(name = "condition_rating")
    var conditionRating: Int? = null,
    
    @Column(name = "special_features", columnDefinition = "TEXT")
    var specialFeatures: String? = null,
    
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null,
    
    @Column(name = "internal_notes", columnDefinition = "TEXT")
    var internalNotes: String? = null
) : TenantAwareEntity() {
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "building_id", nullable = false)
    lateinit var building: Building
    
    fun update(
        unitNumber: String,
        floor: Int,
        exclusiveArea: BigDecimal,
        commonArea: BigDecimal? = null,
        unitType: UnitType,
        roomCount: Int? = null,
        bathroomCount: Int? = null,
        balconyCount: Int? = null,
        hasTerrace: Boolean = false,
        terraceArea: BigDecimal? = null,
        parkingSpaces: Int? = null,
        storageSpaces: Int? = null,
        facingDirection: FacingDirection? = null,
        hasElevatorAccess: Boolean = false,
        monthlyRent: BigDecimal? = null,
        securityDeposit: BigDecimal? = null,
        maintenanceFee: BigDecimal? = null,
        utilityIncluded: Boolean = false,
        furnished: Boolean = false,
        petAllowed: Boolean = false,
        smokingAllowed: Boolean = false,
        lastRenovationDate: java.time.LocalDate? = null,
        conditionRating: Int? = null,
        specialFeatures: String? = null,
        description: String? = null,
        internalNotes: String? = null
    ) {
        this.unitNumber = unitNumber
        this.floor = floor
        this.exclusiveArea = exclusiveArea
        this.commonArea = commonArea
        this.unitType = unitType
        this.roomCount = roomCount
        this.bathroomCount = bathroomCount
        this.balconyCount = balconyCount
        this.hasTerrace = hasTerrace
        this.terraceArea = terraceArea
        this.parkingSpaces = parkingSpaces
        this.storageSpaces = storageSpaces
        this.facingDirection = facingDirection
        this.hasElevatorAccess = hasElevatorAccess
        this.monthlyRent = monthlyRent
        this.securityDeposit = securityDeposit
        this.maintenanceFee = maintenanceFee
        this.utilityIncluded = utilityIncluded
        this.furnished = furnished
        this.petAllowed = petAllowed
        this.smokingAllowed = smokingAllowed
        this.lastRenovationDate = lastRenovationDate
        this.conditionRating = conditionRating
        this.specialFeatures = specialFeatures
        this.description = description
        this.internalNotes = internalNotes
        
        // 총 면적 계산
        this.totalArea = exclusiveArea + (commonArea ?: BigDecimal.ZERO)
    }
    
    fun occupy(moveInDate: java.time.LocalDate) {
        this.currentStatus = UnitStatus.OCCUPIED
        this.moveInDate = moveInDate
        this.moveOutDate = null
    }
    
    fun vacate(moveOutDate: java.time.LocalDate) {
        this.currentStatus = UnitStatus.VACANT
        this.moveOutDate = moveOutDate
    }
    
    fun setUnderMaintenance() {
        this.currentStatus = UnitStatus.UNDER_MAINTENANCE
    }
    
    fun setUnderRenovation() {
        this.currentStatus = UnitStatus.UNDER_RENOVATION
    }
    
    fun setReserved() {
        this.currentStatus = UnitStatus.RESERVED
    }
    
    fun setUnavailable() {
        this.currentStatus = UnitStatus.UNAVAILABLE
    }
    
    fun isAvailableForRent(): Boolean {
        return currentStatus == UnitStatus.VACANT
    }
    
    fun getTotalArea(): BigDecimal {
        return exclusiveArea + (commonArea ?: BigDecimal.ZERO)
    }
    
    fun getFullUnitNumber(): String {
        return "${building.buildingName} ${unitNumber}"
    }
}

enum class UnitType(val displayName: String) {
    STUDIO("원룸"),
    ONE_BEDROOM("1룸"),
    TWO_BEDROOM("2룸"),
    THREE_BEDROOM("3룸"),
    FOUR_BEDROOM("4룸"),
    FIVE_PLUS_BEDROOM("5룸 이상"),
    DUPLEX("복층"),
    PENTHOUSE("펜트하우스"),
    LOFT("로프트"),
    OFFICE("사무실"),
    RETAIL("상가"),
    WAREHOUSE("창고"),
    PARKING("주차장"),
    STORAGE("창고"),
    OTHER("기타")
}

enum class UnitStatus(val displayName: String) {
    VACANT("공실"),
    OCCUPIED("임대중"),
    RESERVED("예약됨"),
    UNDER_MAINTENANCE("정비중"),
    UNDER_RENOVATION("리모델링중"),
    UNAVAILABLE("임대불가")
}

enum class FacingDirection(val displayName: String) {
    NORTH("북향"),
    NORTHEAST("북동향"),
    EAST("동향"),
    SOUTHEAST("남동향"),
    SOUTH("남향"),
    SOUTHWEST("남서향"),
    WEST("서향"),
    NORTHWEST("북서향")
}