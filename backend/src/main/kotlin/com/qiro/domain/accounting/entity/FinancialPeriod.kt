package com.qiro.domain.accounting.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 회계 기간 엔티티
 * 회계 기간 정보를 관리합니다.
 */
@Entity
@Table(
    name = "financial_periods",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "fiscal_year", "period_number"])
    ],
    indexes = [
        Index(name = "idx_financial_periods_company_year", columnList = "company_id, fiscal_year"),
        Index(name = "idx_financial_periods_status", columnList = "status")
    ]
)
class FinancialPeriod(
    @Id
    @Column(name = "period_id")
    val periodId: UUID = UUID.randomUUID(),

    @Column(name = "fiscal_year", nullable = false)
    val fiscalYear: Int,

    @Column(name = "period_number", nullable = false)
    val periodNumber: Int,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: FinancialPeriodStatus = FinancialPeriodStatus.OPEN,

    @Column(name = "is_closed", nullable = false)
    var isClosed: Boolean = false,

    @Column(name = "closed_at")
    var closedAt: LocalDateTime? = null,

    @Column(name = "closed_by")
    var closedBy: UUID? = null
) : TenantAwareEntity() {

    init {
        require(periodNumber in 1..12) { "회계 기간 번호는 1-12 사이여야 합니다." }
        require(startDate.isBefore(endDate)) { "시작일은 종료일보다 이전이어야 합니다." }
    }

    /**
     * 회계 기간 마감
     */
    fun close(closedBy: UUID) {
        require(status == FinancialPeriodStatus.OPEN) { "열린 회계 기간만 마감할 수 있습니다." }
        
        this.status = FinancialPeriodStatus.CLOSED
        this.isClosed = true
        this.closedAt = LocalDateTime.now()
        this.closedBy = closedBy
    }

    /**
     * 회계 기간 잠금
     */
    fun lock() {
        require(status == FinancialPeriodStatus.CLOSED) { "마감된 회계 기간만 잠글 수 있습니다." }
        
        this.status = FinancialPeriodStatus.LOCKED
    }

    /**
     * 회계 기간 재개방
     */
    fun reopen() {
        require(status == FinancialPeriodStatus.CLOSED) { "마감된 회계 기간만 재개방할 수 있습니다." }
        
        this.status = FinancialPeriodStatus.OPEN
        this.isClosed = false
        this.closedAt = null
        this.closedBy = null
    }

    /**
     * 특정 날짜가 이 회계 기간에 포함되는지 확인
     */
    fun contains(date: LocalDate): Boolean {
        return !date.isBefore(startDate) && !date.isAfter(endDate)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is FinancialPeriod) return false
        return periodId == other.periodId
    }

    override fun hashCode(): Int = periodId.hashCode()

    override fun toString(): String {
        return "FinancialPeriod(periodId=$periodId, fiscalYear=$fiscalYear, periodNumber=$periodNumber, status=$status)"
    }
}

/**
 * 회계 기간 상태 열거형
 */
enum class FinancialPeriodStatus {
    /** 열림 */
    OPEN,
    /** 마감됨 */
    CLOSED,
    /** 잠김 */
    LOCKED
}