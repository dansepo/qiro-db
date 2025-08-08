package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 원천징수 엔티티
 * 원천징수 대상 소득과 징수 내역을 관리합니다.
 */
@Entity
@Table(
    name = "withholding_taxes",
    schema = "bms",
    indexes = [
        Index(name = "idx_withholding_taxes_company", columnList = "company_id"),
        Index(name = "idx_withholding_taxes_period", columnList = "tax_period_id"),
        Index(name = "idx_withholding_taxes_payment_date", columnList = "payment_date"),
        Index(name = "idx_withholding_taxes_payee", columnList = "payee_registration_number")
    ]
)
data class WithholdingTax(
    @Id
    @GeneratedValue
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "tax_period_id")
    val taxPeriodId: UUID? = null,

    // 지급 정보
    @Column(name = "payment_date", nullable = false)
    val paymentDate: LocalDate,

    @Column(name = "payee_name", nullable = false, length = 200)
    val payeeName: String,

    @Column(name = "payee_registration_number", length = 20)
    val payeeRegistrationNumber: String? = null,

    @Column(name = "payee_address", columnDefinition = "TEXT")
    val payeeAddress: String? = null,

    // 소득 정보
    @Enumerated(EnumType.STRING)
    @Column(name = "income_type", nullable = false)
    val incomeType: IncomeType,

    @Column(name = "income_amount", nullable = false, precision = 15, scale = 2)
    val incomeAmount: BigDecimal,

    @Column(name = "tax_rate", nullable = false, precision = 5, scale = 4)
    val taxRate: BigDecimal,

    @Column(name = "withholding_amount", nullable = false, precision = 15, scale = 2)
    val withholdingAmount: BigDecimal,

    // 신고 정보
    @Column(name = "report_date")
    val reportDate: LocalDate? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "report_status", nullable = false)
    val reportStatus: ReportStatus = ReportStatus.PENDING,

    @Column(name = "report_reference", length = 100)
    val reportReference: String? = null,

    // 메타데이터
    @Column(name = "notes", columnDefinition = "TEXT")
    val notes: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by")
    val createdBy: UUID? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 소득 유형
     */
    enum class IncomeType {
        SALARY,      // 급여
        BONUS,       // 상여
        RETIREMENT,  // 퇴직
        BUSINESS,    // 사업소득
        PROFESSIONAL,// 전문직
        OTHER        // 기타
    }

    /**
     * 신고 상태
     */
    enum class ReportStatus {
        PENDING,   // 신고 대기
        REPORTED,  // 신고 완료
        CORRECTED  // 수정 신고
    }

    /**
     * 원천징수액 계산
     */
    fun calculateWithholdingAmount(): BigDecimal {
        return incomeAmount.multiply(taxRate)
    }

    /**
     * 실수령액 계산
     */
    fun calculateNetAmount(): BigDecimal {
        return incomeAmount.subtract(withholdingAmount)
    }
}