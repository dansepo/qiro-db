package com.qiro.domain.company.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.time.LocalDate

@Entity
@Table(name = "companies")
class Company(
    @Column(name = "company_name", nullable = false, length = 100)
    var companyName: String,
    
    @Column(name = "business_registration_number", nullable = false, length = 20, unique = true)
    var businessRegistrationNumber: String,
    
    @Column(name = "representative_name", nullable = false, length = 100)
    var representativeName: String,
    
    @Column(name = "business_address", nullable = false, length = 500)
    var businessAddress: String,
    
    @Column(name = "contact_phone", nullable = false, length = 20)
    var contactPhone: String,
    
    @Column(name = "contact_email", nullable = false, length = 255)
    var contactEmail: String,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "business_type", nullable = false, length = 50)
    var businessType: BusinessType,
    
    @Column(name = "establishment_date", nullable = false)
    var establishmentDate: LocalDate,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "company_status", nullable = false, length = 20)
    var companyStatus: CompanyStatus = CompanyStatus.ACTIVE,
    
    @Column(name = "tax_id", length = 20)
    var taxId: String? = null,
    
    @Column(name = "website_url", length = 255)
    var websiteUrl: String? = null,
    
    @Column(name = "employee_count")
    var employeeCount: Int? = null,
    
    @Column(name = "annual_revenue")
    var annualRevenue: Long? = null,
    
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null,
    
    @Column(name = "is_verified", nullable = false)
    var isVerified: Boolean = false
) : BaseEntity() {
    
    fun update(
        companyName: String,
        representativeName: String,
        businessAddress: String,
        contactPhone: String,
        contactEmail: String,
        businessType: BusinessType,
        establishmentDate: LocalDate,
        taxId: String? = null,
        websiteUrl: String? = null,
        employeeCount: Int? = null,
        annualRevenue: Long? = null,
        description: String? = null
    ) {
        this.companyName = companyName
        this.representativeName = representativeName
        this.businessAddress = businessAddress
        this.contactPhone = contactPhone
        this.contactEmail = contactEmail
        this.businessType = businessType
        this.establishmentDate = establishmentDate
        this.taxId = taxId
        this.websiteUrl = websiteUrl
        this.employeeCount = employeeCount
        this.annualRevenue = annualRevenue
        this.description = description
    }
    
    fun activate() {
        this.companyStatus = CompanyStatus.ACTIVE
    }
    
    fun deactivate() {
        this.companyStatus = CompanyStatus.INACTIVE
    }
    
    fun suspend() {
        this.companyStatus = CompanyStatus.SUSPENDED
    }
    
    fun verify() {
        this.isVerified = true
    }
}

enum class BusinessType(val displayName: String) {
    CORPORATION("법인"),
    INDIVIDUAL("개인사업자"),
    PARTNERSHIP("합명회사"),
    LIMITED_PARTNERSHIP("합자회사"),
    LIMITED_LIABILITY("유한회사"),
    NON_PROFIT("비영리단체"),
    GOVERNMENT("정부기관"),
    OTHER("기타")
}

enum class CompanyStatus(val displayName: String) {
    ACTIVE("활성"),
    INACTIVE("비활성"),
    SUSPENDED("정지"),
    TERMINATED("해지")
}