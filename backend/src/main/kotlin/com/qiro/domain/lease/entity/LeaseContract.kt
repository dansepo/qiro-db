package com.qiro.domain.lease.entity

import com.qiro.common.entity.TenantAwareEntity
import com.qiro.domain.lessor.entity.Lessor
import com.qiro.domain.tenant.entity.Tenant
import com.qiro.domain.unit.entity.Unit
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate

@Entity
@Table(name = "lease_contracts")
class LeaseContract(
    @Column(name = "contract_number", nullable = false, length = 50, unique = true)
    var contractNumber: String,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "contract_type", nullable = false, length = 20)
    var contractType: ContractType,
    
    @Column(name = "start_date", nullable = false)
    var startDate: LocalDate,
    
    @Column(name = "end_date", nullable = false)
    var endDate: LocalDate,
    
    @Column(name = "monthly_rent", nullable = false, precision = 12, scale = 2)
    var monthlyRent: BigDecimal,
    
    @Column(name = "security_deposit", nullable = false, precision = 12, scale = 2)
    var securityDeposit: BigDecimal,
    
    @Column(name = "key_money", precision = 12, scale = 2)
    var keyMoney: BigDecimal? = null,
    
    @Column(name = "maintenance_fee", precision = 10, scale = 2)
    var maintenanceFee: BigDecimal? = null,
    
    @Column(name = "utility_deposit", precision = 10, scale = 2)
    var utilityDeposit: BigDecimal? = null,
    
    @Column(name = "parking_fee", precision = 8, scale = 2)
    var parkingFee: BigDecimal? = null,
    
    @Column(name = "late_fee_rate", precision = 5, scale = 2)
    var lateFeeRate: BigDecimal? = null,
    
    @Column(name = "rent_due_day", nullable = false)
    var rentDueDay: Int = 1,
    
    @Column(name = "grace_period_days")
    var gracePeriodDays: Int? = null,
    
    @Column(name = "auto_renewal", nullable = false)
    var autoRenewal: Boolean = false,
    
    @Column(name = "renewal_notice_days")
    var renewalNoticeDays: Int? = null,
    
    @Column(name = "early_termination_allowed", nullable = false)
    var earlyTerminationAllowed: Boolean = false,
    
    @Column(name = "early_termination_penalty", precision = 12, scale = 2)
    var earlyTerminationPenalty: BigDecimal? = null,
    
    @Column(name = "pet_allowed", nullable = false)
    var petAllowed: Boolean = false,
    
    @Column(name = "pet_deposit", precision = 10, scale = 2)
    var petDeposit: BigDecimal? = null,
    
    @Column(name = "smoking_allowed", nullable = false)
    var smokingAllowed: Boolean = false,
    
    @Column(name = "subletting_allowed", nullable = false)
    var sublettingAllowed: Boolean = false,
    
    @Column(name = "utilities_included", nullable = false)
    var utilitiesIncluded: Boolean = false,
    
    @Column(name = "furnished", nullable = false)
    var furnished: Boolean = false,
    
    @Column(name = "parking_spaces")
    var parkingSpaces: Int? = null,
    
    @Column(name = "storage_included", nullable = false)
    var storageIncluded: Boolean = false,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "contract_status", nullable = false, length = 20)
    var contractStatus: ContractStatus = ContractStatus.DRAFT,
    
    @Column(name = "signed_date")
    var signedDate: LocalDate? = null,
    
    @Column(name = "move_in_date")
    var moveInDate: LocalDate? = null,
    
    @Column(name = "move_out_date")
    var moveOutDate: LocalDate? = null,
    
    @Column(name = "actual_end_date")
    var actualEndDate: LocalDate? = null,
    
    @Column(name = "renewal_count", nullable = false)
    var renewalCount: Int = 0,
    
    @Column(name = "parent_contract_id")
    var parentContractId: java.util.UUID? = null,
    
    @Column(name = "termination_reason", length = 500)
    var terminationReason: String? = null,
    
    @Column(name = "special_terms", columnDefinition = "TEXT")
    var specialTerms: String? = null,
    
    @Column(name = "lessor_signature_date")
    var lessorSignatureDate: LocalDate? = null,
    
    @Column(name = "tenant_signature_date")
    var tenantSignatureDate: LocalDate? = null,
    
    @Column(name = "witness_name", length = 100)
    var witnessName: String? = null,
    
    @Column(name = "witness_signature_date")
    var witnessSignatureDate: LocalDate? = null,
    
    @Column(name = "contract_document_path", length = 500)
    var contractDocumentPath: String? = null,
    
    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null
) : TenantAwareEntity() {
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    lateinit var unit: Unit
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "lessor_id", nullable = false)
    lateinit var lessor: Lessor
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tenant_id", nullable = false)
    lateinit var tenant: Tenant
    
    fun updateBasicTerms(
        contractType: ContractType,
        startDate: LocalDate,
        endDate: LocalDate,
        monthlyRent: BigDecimal,
        securityDeposit: BigDecimal,
        keyMoney: BigDecimal? = null,
        maintenanceFee: BigDecimal? = null,
        utilityDeposit: BigDecimal? = null,
        parkingFee: BigDecimal? = null
    ) {
        this.contractType = contractType
        this.startDate = startDate
        this.endDate = endDate
        this.monthlyRent = monthlyRent
        this.securityDeposit = securityDeposit
        this.keyMoney = keyMoney
        this.maintenanceFee = maintenanceFee
        this.utilityDeposit = utilityDeposit
        this.parkingFee = parkingFee
    }
    
    fun updatePaymentTerms(
        rentDueDay: Int,
        lateFeeRate: BigDecimal?,
        gracePeriodDays: Int?
    ) {
        this.rentDueDay = rentDueDay
        this.lateFeeRate = lateFeeRate
        this.gracePeriodDays = gracePeriodDays
    }
    
    fun updateRenewalTerms(
        autoRenewal: Boolean,
        renewalNoticeDays: Int?
    ) {
        this.autoRenewal = autoRenewal
        this.renewalNoticeDays = renewalNoticeDays
    }
    
    fun updateTerminationTerms(
        earlyTerminationAllowed: Boolean,
        earlyTerminationPenalty: BigDecimal?
    ) {
        this.earlyTerminationAllowed = earlyTerminationAllowed
        this.earlyTerminationPenalty = earlyTerminationPenalty
    }
    
    fun updatePropertyRules(
        petAllowed: Boolean,
        petDeposit: BigDecimal?,
        smokingAllowed: Boolean,
        sublettingAllowed: Boolean
    ) {
        this.petAllowed = petAllowed
        this.petDeposit = petDeposit
        this.smokingAllowed = smokingAllowed
        this.sublettingAllowed = sublettingAllowed
    }
    
    fun updateAmenities(
        utilitiesIncluded: Boolean,
        furnished: Boolean,
        parkingSpaces: Int?,
        storageIncluded: Boolean
    ) {
        this.utilitiesIncluded = utilitiesIncluded
        this.furnished = furnished
        this.parkingSpaces = parkingSpaces
        this.storageIncluded = storageIncluded
    }
    
    fun signByLessor(signatureDate: LocalDate) {
        this.lessorSignatureDate = signatureDate
        checkAndUpdateSignedStatus()
    }
    
    fun signByTenant(signatureDate: LocalDate) {
        this.tenantSignatureDate = signatureDate
        checkAndUpdateSignedStatus()
    }
    
    fun addWitness(witnessName: String, signatureDate: LocalDate) {
        this.witnessName = witnessName
        this.witnessSignatureDate = signatureDate
    }
    
    private fun checkAndUpdateSignedStatus() {
        if (lessorSignatureDate != null && tenantSignatureDate != null && contractStatus == ContractStatus.DRAFT) {
            this.contractStatus = ContractStatus.SIGNED
            this.signedDate = maxOf(lessorSignatureDate!!, tenantSignatureDate!!)
        }
    }
    
    fun activate(moveInDate: LocalDate) {
        if (contractStatus != ContractStatus.SIGNED) {
            throw IllegalStateException("계약이 서명되지 않았습니다")
        }
        this.contractStatus = ContractStatus.ACTIVE
        this.moveInDate = moveInDate
        
        // 세대 상태를 임대중으로 변경
        unit.occupy(moveInDate)
    }
    
    fun terminate(terminationDate: LocalDate, reason: String?) {
        this.contractStatus = ContractStatus.TERMINATED
        this.actualEndDate = terminationDate
        this.terminationReason = reason
        
        // 세대 상태를 공실로 변경
        unit.vacate(terminationDate)
    }
    
    fun expire() {
        this.contractStatus = ContractStatus.EXPIRED
        this.actualEndDate = endDate
        
        // 세대 상태를 공실로 변경
        unit.vacate(endDate)
    }
    
    fun renew(newEndDate: LocalDate, newMonthlyRent: BigDecimal? = null): LeaseContract {
        if (contractStatus != ContractStatus.ACTIVE) {
            throw IllegalStateException("활성 계약만 갱신할 수 있습니다")
        }
        
        // 현재 계약 만료 처리
        this.contractStatus = ContractStatus.EXPIRED
        this.actualEndDate = endDate
        
        // 새로운 계약 생성
        val renewedContract = LeaseContract(
            contractNumber = "${contractNumber}-R${renewalCount + 1}",
            contractType = contractType,
            startDate = endDate.plusDays(1),
            endDate = newEndDate,
            monthlyRent = newMonthlyRent ?: monthlyRent,
            securityDeposit = securityDeposit,
            keyMoney = keyMoney,
            maintenanceFee = maintenanceFee,
            utilityDeposit = utilityDeposit,
            parkingFee = parkingFee,
            lateFeeRate = lateFeeRate,
            rentDueDay = rentDueDay,
            gracePeriodDays = gracePeriodDays,
            autoRenewal = autoRenewal,
            renewalNoticeDays = renewalNoticeDays,
            earlyTerminationAllowed = earlyTerminationAllowed,
            earlyTerminationPenalty = earlyTerminationPenalty,
            petAllowed = petAllowed,
            petDeposit = petDeposit,
            smokingAllowed = smokingAllowed,
            sublettingAllowed = sublettingAllowed,
            utilitiesIncluded = utilitiesIncluded,
            furnished = furnished,
            parkingSpaces = parkingSpaces,
            storageIncluded = storageIncluded,
            renewalCount = renewalCount + 1,
            parentContractId = id
        ).apply {
            this.unit = this@LeaseContract.unit
            this.lessor = this@LeaseContract.lessor
            this.tenant = this@LeaseContract.tenant
            setCompanyId(this@LeaseContract.companyId)
        }
        
        return renewedContract
    }
    
    fun getTotalDeposit(): BigDecimal {
        return securityDeposit + 
               (keyMoney ?: BigDecimal.ZERO) + 
               (utilityDeposit ?: BigDecimal.ZERO) + 
               (petDeposit ?: BigDecimal.ZERO)
    }
    
    fun getTotalMonthlyPayment(): BigDecimal {
        return monthlyRent + 
               (maintenanceFee ?: BigDecimal.ZERO) + 
               (parkingFee ?: BigDecimal.ZERO)
    }
    
    fun isActive(): Boolean {
        return contractStatus == ContractStatus.ACTIVE
    }
    
    fun isExpiringSoon(daysAhead: Int = 30): Boolean {
        return contractStatus == ContractStatus.ACTIVE && 
               endDate.isBefore(LocalDate.now().plusDays(daysAhead.toLong()))
    }
    
    fun getDurationInMonths(): Long {
        return java.time.temporal.ChronoUnit.MONTHS.between(startDate, endDate)
    }
}

enum class ContractType(val displayName: String) {
    MONTHLY("월세"),
    JEONSE("전세"),
    MIXED("반전세"),
    SHORT_TERM("단기임대"),
    LONG_TERM("장기임대")
}

enum class ContractStatus(val displayName: String) {
    DRAFT("초안"),
    SIGNED("서명완료"),
    ACTIVE("활성"),
    EXPIRED("만료"),
    TERMINATED("해지"),
    CANCELLED("취소")
}