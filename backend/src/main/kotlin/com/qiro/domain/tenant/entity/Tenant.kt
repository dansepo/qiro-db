package com.qiro.domain.tenant.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "tenants")
class Tenant(
    @Column(name = "tenant_name", nullable = false, length = 100)
    var tenantName: String,
    
    @Column(name = "contact_phone", nullable = false, length = 20)
    var contactPhone: String,
    
    @Column(name = "contact_email", length = 255)
    var contactEmail: String? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "tenant_type", nullable = false, length = 20)
    var tenantType: TenantType,
    
    @Column(name = "business_registration_number", length = 20)
    var businessRegistrationNumber: String? = null,
    
    @Column(name = "identification_number", length = 20)
    var identificationNumber: String? = null,
    
    @Column(name = "date_of_birth")
    var dateOfBirth: LocalDate? = null,
    
    @Column(name = "nationality", length = 50)
    var nationality: String? = null,
    
    @Column(name = "occupation", length = 100)
    var occupation: String? = null,
    
    @Column(name = "employer", length = 200)
    var employer: String? = null,
    
    @Column(name = "monthly_income", precision = 12, scale = 2)
    var monthlyIncome: java.math.BigDecimal? = null,
    
    @Column(name = "credit_score")
    var creditScore: Int? = null,
    
    @Column(name = "emergency_contact_name", length = 100)
    var emergencyContactName: String? = null,
    
    @Column(name = "emergency_contact_phone", length = 20)
    var emergencyContactPhone: String? = null,
    
    @Column(name = "emergency_contact_relationship", length = 50)
    var emergencyContactRelationship: String? = null,
    
    @Column(name = "previous_address", length = 500)
    var previousAddress: String? = null,
    
    @Column(name = "current_address", length = 500)
    var currentAddress: String? = null,
    
    @Column(name = "mailing_address", length = 500)
    var mailingAddress: String? = null,
    
    @Column(name = "preferred_contact_method", length = 20)
    var preferredContactMethod: String? = null,
    
    @Column(name = "language_preference", length = 20)
    var languagePreference: String? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "tenant_status", nullable = false, length = 20)
    var tenantStatus: TenantStatus = TenantStatus.ACTIVE,
    
    @Column(name = "background_check_status", length = 20)
    var backgroundCheckStatus: String? = null,
    
    @Column(name = "background_check_date")
    var backgroundCheckDate: LocalDate? = null,
    
    @Column(name = "reference_check_status", length = 20)
    var referenceCheckStatus: String? = null,
    
    @Column(name = "reference_check_date")
    var referenceCheckDate: LocalDate? = null,
    
    @Column(name = "bank_account_number", length = 50)
    var bankAccountNumber: String? = null,
    
    @Column(name = "bank_name", length = 100)
    var bankName: String? = null,
    
    @Column(name = "payment_method", length = 20)
    var paymentMethod: String? = null,
    
    @Column(name = "auto_pay_enabled", nullable = false)
    var autoPayEnabled: Boolean = false,
    
    @Column(name = "special_requirements", columnDefinition = "TEXT")
    var specialRequirements: String? = null,
    
    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null,
    
    @Column(name = "profile_image_url", length = 500)
    var profileImageUrl: String? = null
) : TenantAwareEntity() {
    
    fun updateBasicInfo(
        tenantName: String,
        contactPhone: String,
        contactEmail: String?,
        tenantType: TenantType,
        businessRegistrationNumber: String? = null,
        identificationNumber: String? = null,
        dateOfBirth: LocalDate? = null,
        nationality: String? = null,
        occupation: String? = null,
        employer: String? = null,
        monthlyIncome: java.math.BigDecimal? = null
    ) {
        this.tenantName = tenantName
        this.contactPhone = contactPhone
        this.contactEmail = contactEmail
        this.tenantType = tenantType
        this.businessRegistrationNumber = businessRegistrationNumber
        this.identificationNumber = identificationNumber
        this.dateOfBirth = dateOfBirth
        this.nationality = nationality
        this.occupation = occupation
        this.employer = employer
        this.monthlyIncome = monthlyIncome
    }
    
    fun updateContactInfo(
        emergencyContactName: String?,
        emergencyContactPhone: String?,
        emergencyContactRelationship: String?,
        currentAddress: String?,
        mailingAddress: String?,
        preferredContactMethod: String?,
        languagePreference: String?
    ) {
        this.emergencyContactName = emergencyContactName
        this.emergencyContactPhone = emergencyContactPhone
        this.emergencyContactRelationship = emergencyContactRelationship
        this.currentAddress = currentAddress
        this.mailingAddress = mailingAddress
        this.preferredContactMethod = preferredContactMethod
        this.languagePreference = languagePreference
    }
    
    fun updateFinancialInfo(
        creditScore: Int?,
        bankAccountNumber: String?,
        bankName: String?,
        paymentMethod: String?,
        autoPayEnabled: Boolean
    ) {
        this.creditScore = creditScore
        this.bankAccountNumber = bankAccountNumber
        this.bankName = bankName
        this.paymentMethod = paymentMethod
        this.autoPayEnabled = autoPayEnabled
    }
    
    fun completeBackgroundCheck(status: String, checkDate: LocalDate) {
        this.backgroundCheckStatus = status
        this.backgroundCheckDate = checkDate
    }
    
    fun completeReferenceCheck(status: String, checkDate: LocalDate) {
        this.referenceCheckStatus = status
        this.referenceCheckDate = checkDate
    }
    
    fun activate() {
        this.tenantStatus = TenantStatus.ACTIVE
    }
    
    fun deactivate() {
        this.tenantStatus = TenantStatus.INACTIVE
    }
    
    fun blacklist() {
        this.tenantStatus = TenantStatus.BLACKLISTED
    }
    
    fun isEligibleForRental(): Boolean {
        return tenantStatus == TenantStatus.ACTIVE &&
                backgroundCheckStatus == "PASSED" &&
                referenceCheckStatus == "PASSED"
    }
}

enum class TenantType(val displayName: String) {
    INDIVIDUAL("개인"),
    CORPORATE("법인"),
    GOVERNMENT("정부기관"),
    NON_PROFIT("비영리단체")
}

enum class TenantStatus(val displayName: String) {
    ACTIVE("활성"),
    INACTIVE("비활성"),
    PENDING_VERIFICATION("검증 대기"),
    BLACKLISTED("블랙리스트"),
    SUSPENDED("정지")
}