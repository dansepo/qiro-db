package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 업체 정보 엔티티
 * 지출과 관련된 업체 정보를 관리
 */
@Entity
@Table(
    name = "vendors",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "vendor_code"])
    ]
)
data class Vendor(
    @Id
    @Column(name = "vendor_id")
    val vendorId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "vendor_code", nullable = false, length = 20)
    val vendorCode: String,

    @Column(name = "vendor_name", nullable = false, length = 100)
    val vendorName: String,

    @Column(name = "business_number", length = 20)
    val businessNumber: String? = null,

    @Column(name = "contact_person", length = 50)
    val contactPerson: String? = null,

    @Column(name = "phone_number", length = 20)
    val phoneNumber: String? = null,

    @Column(name = "email", length = 100)
    val email: String? = null,

    @Column(name = "address", columnDefinition = "TEXT")
    val address: String? = null,

    @Column(name = "bank_account", length = 50)
    val bankAccount: String? = null,

    @Column(name = "bank_name", length = 50)
    val bankName: String? = null,

    @Column(name = "account_holder", length = 50)
    val accountHolder: String? = null,

    @Column(name = "vendor_type", length = 50)
    val vendorType: String? = null,

    @Column(name = "payment_terms")
    val paymentTerms: Int = 30,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 업체 유형 열거형
     */
    enum class VendorType(val code: String, val displayName: String) {
        MAINTENANCE("MAINTENANCE", "유지보수업체"),
        UTILITY("UTILITY", "공과금업체"),
        CLEANING("CLEANING", "청소업체"),
        SECURITY("SECURITY", "경비업체"),
        INSURANCE("INSURANCE", "보험회사"),
        CONSTRUCTION("CONSTRUCTION", "건설업체"),
        SUPPLIES("SUPPLIES", "용품업체"),
        SERVICE("SERVICE", "서비스업체"),
        OTHER("OTHER", "기타");

        companion object {
            fun fromCode(code: String): VendorType? = values().find { it.code == code }
        }
    }

    /**
     * 업체 정보 업데이트
     */
    fun updateInfo(
        vendorName: String? = null,
        contactPerson: String? = null,
        phoneNumber: String? = null,
        email: String? = null,
        address: String? = null
    ): Vendor {
        return this.copy(
            vendorName = vendorName ?: this.vendorName,
            contactPerson = contactPerson ?: this.contactPerson,
            phoneNumber = phoneNumber ?: this.phoneNumber,
            email = email ?: this.email,
            address = address ?: this.address
        )
    }

    /**
     * 계좌 정보 업데이트
     */
    fun updateBankInfo(
        bankAccount: String?,
        bankName: String?,
        accountHolder: String?
    ): Vendor {
        return this.copy(
            bankAccount = bankAccount,
            bankName = bankName,
            accountHolder = accountHolder
        )
    }

    /**
     * 업체 비활성화
     */
    fun deactivate(): Vendor {
        return this.copy(isActive = false)
    }

    /**
     * 업체 활성화
     */
    fun activate(): Vendor {
        return this.copy(isActive = true)
    }
}