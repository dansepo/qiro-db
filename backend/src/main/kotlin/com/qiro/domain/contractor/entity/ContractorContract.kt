package com.qiro.domain.contractor.entity

import jakarta.persistence.*
import org.hibernate.annotations.GenericGenerator
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 계약 엔티티
 * 협력업체와의 계약 정보를 관리
 */
@Entity
@Table(
    name = "contractor_contracts",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_contractor_contracts_number", columnNames = ["company_id", "contract_number"])
    ],
    indexes = [
        Index(name = "idx_contractor_contracts_company_id", columnList = "company_id"),
        Index(name = "idx_contractor_contracts_contractor_id", columnList = "contractor_id"),
        Index(name = "idx_contractor_contracts_number", columnList = "contract_number"),
        Index(name = "idx_contractor_contracts_dates", columnList = "start_date, end_date"),
        Index(name = "idx_contractor_contracts_status", columnList = "contract_status"),
        Index(name = "idx_contractor_contracts_type", columnList = "contract_type")
    ]
)
data class ContractorContract(
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "contract_id", columnDefinition = "uuid")
    val contractId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false, columnDefinition = "uuid")
    val companyId: UUID,

    @Column(name = "contractor_id", nullable = false, columnDefinition = "uuid")
    val contractorId: UUID,

    @Column(name = "contract_number", nullable = false, length = 50)
    val contractNumber: String,

    @Column(name = "contract_title", nullable = false, length = 200)
    val contractTitle: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "contract_type", nullable = false, length = 30)
    val contractType: ContractType,

    @Column(name = "contract_description", columnDefinition = "text")
    val contractDescription: String? = null,

    @Column(name = "scope_of_work", nullable = false, columnDefinition = "text")
    val scopeOfWork: String,

    @Column(name = "contract_amount", nullable = false, precision = 15, scale = 2)
    val contractAmount: BigDecimal,

    @Column(name = "currency_code", length = 3)
    val currencyCode: String = "KRW",

    @Column(name = "payment_terms", length = 200)
    val paymentTerms: String? = null,

    @Column(name = "contract_date", nullable = false)
    val contractDate: LocalDate,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDate,

    @Column(name = "performance_bond_required")
    val performanceBondRequired: Boolean = false,

    @Column(name = "performance_bond_amount", precision = 15, scale = 2)
    val performanceBondAmount: BigDecimal? = null,

    @Column(name = "warranty_period")
    val warrantyPeriod: Int? = null,

    @Column(name = "penalty_terms", columnDefinition = "text")
    val penaltyTerms: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "contract_status", length = 20)
    val contractStatus: ContractStatus = ContractStatus.DRAFT,

    @Column(name = "approved_by", columnDefinition = "uuid")
    val approvedBy: UUID? = null,

    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,

    @Column(name = "contract_document_path", length = 500)
    val contractDocumentPath: String? = null,

    @Column(name = "contract_notes", columnDefinition = "text")
    val contractNotes: String? = null,

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
     * 계약 유형
     */
    enum class ContractType {
        SERVICE,          // 서비스 계약
        MAINTENANCE,      // 유지보수 계약
        CONSTRUCTION,     // 건설 계약
        SUPPLY,          // 공급 계약
        CONSULTING,      // 컨설팅 계약
        FRAMEWORK        // 기본 계약
    }

    /**
     * 계약 상태
     */
    enum class ContractStatus {
        DRAFT,           // 초안
        PENDING_APPROVAL, // 승인 대기
        ACTIVE,          // 활성
        COMPLETED,       // 완료
        TERMINATED,      // 해지
        EXPIRED          // 만료
    }
}