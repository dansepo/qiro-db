package com.qiro.domain.contractor.entity

import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 정보 엔티티
 * 외부 협력업체의 기본 정보와 평가 정보를 관리
 */
@Entity
@Table(
    name = "contractors",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_contractors_code", columnNames = ["company_id", "contractor_code"]),
        UniqueConstraint(name = "uk_contractors_business_reg", columnNames = ["company_id", "business_registration_number"])
    ],
    indexes = [
        Index(name = "idx_contractors_company_id", columnList = "company_id"),
        Index(name = "idx_contractors_code", columnList = "contractor_code"),
        Index(name = "idx_contractors_name", columnList = "contractor_name"),
        Index(name = "idx_contractors_category", columnList = "category_id"),
        Index(name = "idx_contractors_status", columnList = "contractor_status"),
        Index(name = "idx_contractors_rating", columnList = "overall_rating"),
        Index(name = "idx_contractors_grade", columnList = "performance_grade")
    ]
)
data class Contractor(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "contractor_id", columnDefinition = "uuid")
    val contractorId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "contractor_code", nullable = false, length = 50)
    val contractorCode: String,

    @Column(name = "contractor_name", nullable = false, length = 200)
    val contractorName: String,

    @Column(name = "contractor_name_en", length = 200)
    val contractorNameEn: String? = null,

    @Column(name = "business_registration_number", nullable = false, length = 20)
    val businessRegistrationNumber: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "business_type", nullable = false, length = 30)
    val businessType: BusinessType,

    @Enumerated(EnumType.STRING)
    @Column(name = "contractor_type", nullable = false, length = 30)
    val contractorType: ContractorType,

    @Column(name = "category_id", nullable = false, columnDefinition = "uuid")
    val categoryId: UUID,

    @Column(name = "representative_name", nullable = false, length = 100)
    val representativeName: String,

    @Column(name = "contact_person", length = 100)
    val contactPerson: String? = null,

    @Column(name = "phone_number", length = 20)
    val phoneNumber: String? = null,

    @Column(name = "mobile_number", length = 20)
    val mobileNumber: String? = null,

    @Column(name = "fax_number", length = 20)
    val faxNumber: String? = null,

    @Column(name = "email", length = 100)
    val email: String? = null,

    @Column(name = "website", length = 200)
    val website: String? = null,

    @Column(name = "address", nullable = false, columnDefinition = "text")
    val address: String,

    @Column(name = "postal_code", length = 10)
    val postalCode: String? = null,

    @Column(name = "city", length = 50)
    val city: String? = null,

    @Column(name = "state", length = 50)
    val state: String? = null,

    @Column(name = "country", length = 50)
    val country: String = "KR",

    @Column(name = "establishment_date")
    val establishmentDate: LocalDate? = null,

    @Column(name = "capital_amount", precision = 15, scale = 2)
    val capitalAmount: BigDecimal? = null,

    @Column(name = "annual_revenue", precision = 15, scale = 2)
    val annualRevenue: BigDecimal? = null,

    @Column(name = "employee_count")
    val employeeCount: Int? = null,

    @Column(name = "specialization_areas", columnDefinition = "jsonb")
    val specializationAreas: String? = null,

    @Column(name = "service_regions", columnDefinition = "jsonb")
    val serviceRegions: String? = null,

    @Column(name = "work_capacity", columnDefinition = "jsonb")
    val workCapacity: String? = null,

    @Column(name = "credit_rating", length = 10)
    val creditRating: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "financial_status", length = 20)
    val financialStatus: FinancialStatus = FinancialStatus.NORMAL,

    @Enumerated(EnumType.STRING)
    @Column(name = "registration_status", length = 20)
    val registrationStatus: RegistrationStatus = RegistrationStatus.PENDING,

    @Column(name = "registration_date")
    val registrationDate: LocalDateTime? = null,

    @Column(name = "expiry_date")
    val expiryDate: LocalDate? = null,

    @Column(name = "overall_rating", precision = 3, scale = 2)
    val overallRating: BigDecimal = BigDecimal.ZERO,

    @Enumerated(EnumType.STRING)
    @Column(name = "performance_grade", length = 10)
    val performanceGrade: PerformanceGrade? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "contractor_status", length = 20)
    val contractorStatus: ContractorStatus = ContractorStatus.ACTIVE,

    @Column(name = "remarks", columnDefinition = "text")
    val remarks: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", columnDefinition = "uuid")
    val createdBy: UUID? = null,

    @Column(name = "updated_by", columnDefinition = "uuid")
    val updatedBy: UUID? = null
) {
    /**
     * 업체 유형
     */
    enum class BusinessType {
        CORPORATION,        // 법인
        PARTNERSHIP,        // 합명회사
        SOLE_PROPRIETORSHIP, // 개인사업자
        COOPERATIVE,        // 협동조합
        OTHER              // 기타
    }

    /**
     * 협력업체 유형
     */
    enum class ContractorType {
        GENERAL,           // 일반업체
        SPECIALIZED,       // 전문업체
        SUBCONTRACTOR,     // 하청업체
        CONSULTANT,        // 컨설팅업체
        SUPPLIER          // 공급업체
    }

    /**
     * 재무 상태
     */
    enum class FinancialStatus {
        EXCELLENT,         // 우수
        GOOD,             // 양호
        NORMAL,           // 보통
        POOR,             // 미흡
        CRITICAL          // 위험
    }

    /**
     * 등록 상태
     */
    enum class RegistrationStatus {
        PENDING,          // 대기중
        APPROVED,         // 승인됨
        REJECTED,         // 거부됨
        SUSPENDED,        // 정지됨
        EXPIRED           // 만료됨
    }

    /**
     * 성과 등급
     */
    enum class PerformanceGrade {
        A_PLUS,           // A+
        A,                // A
        B_PLUS,           // B+
        B,                // B
        C_PLUS,           // C+
        C,                // C
        D,                // D
        F                 // F
    }

    /**
     * 업체 상태
     */
    enum class ContractorStatus {
        ACTIVE,           // 활성
        INACTIVE,         // 비활성
        SUSPENDED,        // 정지
        BLACKLISTED,      // 블랙리스트
        TERMINATED        // 계약종료
    }
}