package com.qiro.domain.lessor.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "lessors")
class Lessor(
    @Column(name = "lessor_name", nullable = false, length = 100)
    var lessorName: String,
    
    @Column(name = "contact_phone", nullable = false, length = 20)
    var contactPhone: String,
    
    @Column(name = "contact_email", length = 255)
    var contactEmail: String? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "lessor_type", nullable = false, length = 20)
    var lessorType: LessorType,
    
    @Column(name = "business_registration_number", length = 20)
    var businessRegistrationNumber: String? = null,
    
    @Column(name = "identification_number", length = 20)
    var identificationNumber: String? = null,
    
    @Column(name = "date_of_birth")
    var dateOfBirth: LocalDate? = null,
    
    @Column(name = "nationality", length = 50)
    var nationality: String? = null,
    
    @Column(name = "address", length = 500)
    var address: String? = null,
    
    @Column(name = "mailing_address", length = 500)
    var mailingAddress: String? = null,
    
    @Column(name = "bank_account_number", length = 50)
    var bankAccountNumber: String? = null,
    
    @Column(name = "bank_name", length = 100)
    var bankName: String? = null,
    
    @Column(name = "tax_id", length = 20)
    var taxId: String? = null,
    
    @Column(name = "preferred_contact_method", length = 20)
    var preferredContactMethod: String? = null,
    
    @Column(name = "language_preference", length = 20)
    var languagePreference: String? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "lessor_status", nullable = false, length = 20)
    var lessorStatus: LessorStatus = LessorStatus.ACTIVE,
    
    @Column(name = "property_management_company", length = 200)
    var propertyManagementCompany: String? = null,
    
    @Column(name = "property_manager_name", length = 100)
    var propertyManagerName: String? = null,
    
    @Column(name = "property_manager_phone", length = 20)
    var propertyManagerPhone: String? = null,
    
    @Column(name = "property_manager_email", length = 255)
    var propertyManagerEmail: String? = null,
    
    @Column(name = "legal_representative_name", length = 100)
    var legalRepresentativeName: String? = null,
    
    @Column(name = "legal_representative_phone", length = 20)
    var legalRepresentativePhone: String? = null,
    
    @Column(name = "legal_representative_email", length = 255)
    var legalRepresentativeEmail: String? = null,
    
    @Column(name = "emergency_contact_name", length = 100)
    var emergencyContactName: String? = null,
    
    @Column(name = "emergency_contact_phone", length = 20)
    var emergencyContactPhone: String? = null,
    
    @Column(name = "emergency_contact_relationship", length = 50)
    var emergencyContactRelationship: String? = null,
    
    @Column(name = "insurance_company", length = 200)
    var insuranceCompany: String? = null,
    
    @Column(name = "insurance_policy_number", length = 50)
    var insurancePolicyNumber: String? = null,
    
    @Column(name = "insurance_expiry_date")
    var insuranceExpiryDate: LocalDate? = null,
    
    @Column(name = "special_instructions", columnDefinition = "TEXT")
    var specialInstructions: String? = null,
    
    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null,
    
    @Column(name = "profile_image_url", length = 500)
    var profileImageUrl: String? = null
) : TenantAwareEntity() {
    
    fun updateBasicInfo(
        lessorName: String,
        contactPhone: String,
        contactEmail: String?,
        lessorType: LessorType,
        businessRegistrationNumber: String? = null,
        identificationNumber: String? = null,
        dateOfBirth: LocalDate? = null,
        nationality: String? = null,
        address: String? = null,
        mailingAddress: String? = null
    ) {
        this.lessorName = lessorName
        this.contactPhone = contactPhone
        this.contactEmail = contactEmail
        this.lessorType = lessorType
        this.businessRegistrationNumber = businessRegistrationNumber
        this.identificationNumber = identificationNumber
        this.dateOfBirth = dateOfBirth
        this.nationality = nationality
        this.address = address
        this.mailingAddress = mailingAddress
    }
    
    fun updateFinancialInfo(
        bankAccountNumber: String?,
        bankName: String?,
        taxId: String?
    ) {
        this.bankAccountNumber = bankAccountNumber
        this.bankName = bankName
        this.taxId = taxId
    }
    
    fun updatePropertyManagement(
        propertyManagementCompany: String?,
        propertyManagerName: String?,
        propertyManagerPhone: String?,
        propertyManagerEmail: String?
    ) {
        this.propertyManagementCompany = propertyManagementCompany
        this.propertyManagerName = propertyManagerName
        this.propertyManagerPhone = propertyManagerPhone
        this.propertyManagerEmail = propertyManagerEmail
    }
    
    fun updateLegalRepresentative(
        legalRepresentativeName: String?,
        legalRepresentativePhone: String?,
        legalRepresentativeEmail: String?
    ) {
        this.legalRepresentativeName = legalRepresentativeName
        this.legalRepresentativePhone = legalRepresentativePhone
        this.legalRepresentativeEmail = legalRepresentativeEmail
    }
    
    fun updateEmergencyContact(
        emergencyContactName: String?,
        emergencyContactPhone: String?,
        emergencyContactRelationship: String?
    ) {
        this.emergencyContactName = emergencyContactName
        this.emergencyContactPhone = emergencyContactPhone
        this.emergencyContactRelationship = emergencyContactRelationship
    }
    
    fun updateInsurance(
        insuranceCompany: String?,
        insurancePolicyNumber: String?,
        insuranceExpiryDate: LocalDate?
    ) {
        this.insuranceCompany = insuranceCompany
        this.insurancePolicyNumber = insurancePolicyNumber
        this.insuranceExpiryDate = insuranceExpiryDate
    }
    
    fun activate() {
        this.lessorStatus = LessorStatus.ACTIVE
    }
    
    fun deactivate() {
        this.lessorStatus = LessorStatus.INACTIVE
    }
    
    fun suspend() {
        this.lessorStatus = LessorStatus.SUSPENDED
    }
    
    fun isInsuranceValid(): Boolean {
        return insuranceExpiryDate?.isAfter(LocalDate.now()) == true
    }
    
    fun isEligibleForLeasing(): Boolean {
        return lessorStatus == LessorStatus.ACTIVE
    }
}

enum class LessorType(val displayName: String) {
    INDIVIDUAL("개인"),
    CORPORATE("법인"),
    TRUST("신탁"),
    GOVERNMENT("정부기관"),
    INSTITUTIONAL("기관투자자")
}

enum class LessorStatus(val displayName: String) {
    ACTIVE("활성"),
    INACTIVE("비활성"),
    SUSPENDED("정지"),
    UNDER_REVIEW("검토중")
}