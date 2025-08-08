package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 세무 신고 기간 엔티티
 * 부가세, 원천징수 등의 신고 기간을 관리합니다.
 */
@Entity
@Table(
    name = "tax_periods",
    schema = "bms",
    indexes = [
        Index(name = "idx_tax_periods_company_type", columnList = "company_id, tax_type"),
        Index(name = "idx_tax_periods_period", columnList = "period_year, period_month, period_quarter"),
        Index(name = "idx_tax_periods_due_date", columnList = "due_date"),
        Index(name = "idx_tax_periods_status", columnList = "status")
    ]
)
data class TaxPeriod(
    @Id
    @GeneratedValue
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", nullable = false)
    val periodType: PeriodType,

    @Enumerated(EnumType.STRING)
    @Column(name = "tax_type", nullable = false)
    val taxType: TaxType,

    @Column(name = "period_year", nullable = false)
    val periodYear: Int,

    @Column(name = "period_month")
    val periodMonth: Int? = null,

    @Column(name = "period_quarter")
    val periodQuarter: Int? = null,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDate,

    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    val status: TaxPeriodStatus = TaxPeriodStatus.OPEN,

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
     * 신고 주기 유형
     */
    enum class PeriodType {
        MONTHLY,    // 월별
        QUARTERLY,  // 분기별
        YEARLY      // 연별
    }

    /**
     * 세금 유형
     */
    enum class TaxType {
        VAT,         // 부가세
        WITHHOLDING, // 원천징수
        CORPORATE,   // 법인세
        LOCAL        // 지방세
    }

    /**
     * 신고 기간 상태
     */
    enum class TaxPeriodStatus {
        OPEN,      // 진행중
        CLOSED,    // 마감
        SUBMITTED, // 제출완료
        APPROVED   // 승인완료
    }
}