package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 미수금 엔티티
 * 미납된 수입에 대한 미수금 관리
 */
@Entity
@Table(name = "receivables", schema = "bms")
data class Receivable(
    @Id
    @Column(name = "receivable_id")
    val receivableId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "income_record_id", nullable = false)
    val incomeRecord: IncomeRecord,

    @Column(name = "building_id")
    val buildingId: UUID? = null,

    @Column(name = "unit_id", length = 50)
    val unitId: String? = null,

    @Column(name = "tenant_id")
    val tenantId: UUID? = null,

    @Column(name = "original_amount", nullable = false, precision = 15, scale = 2)
    val originalAmount: BigDecimal,

    @Column(name = "outstanding_amount", nullable = false, precision = 15, scale = 2)
    val outstandingAmount: BigDecimal,

    @Column(name = "remaining_amount", nullable = false, precision = 15, scale = 2)
    var remainingAmount: BigDecimal,

    @Column(name = "overdue_days")
    val overdueDays: Int = 0,

    @Column(name = "late_fee_amount", precision = 15, scale = 2)
    var lateFee: BigDecimal = BigDecimal.ZERO,

    @Column(name = "total_outstanding", nullable = false, precision = 15, scale = 2)
    val totalOutstanding: BigDecimal,

    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    @Column(name = "last_payment_date")
    val lastPaymentDate: LocalDate? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    var status: ReceivableStatus = ReceivableStatus.OUTSTANDING,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {


    /**
     * 연체 여부 확인
     */
    fun isOverdue(asOfDate: LocalDate = LocalDate.now()): Boolean {
        return asOfDate.isAfter(dueDate) && status in listOf(ReceivableStatus.OUTSTANDING, ReceivableStatus.PARTIALLY_PAID)
    }

    /**
     * 연체 일수 계산
     */
    fun calculateOverdueDays(asOfDate: LocalDate = LocalDate.now()): Int {
        return if (isOverdue(asOfDate)) {
            asOfDate.toEpochDay().toInt() - dueDate.toEpochDay().toInt()
        } else {
            0
        }
    }

    /**
     * 미수금 업데이트 (결제 후)
     */
    fun updateAfterPayment(
        paidAmount: BigDecimal,
        lateFee: BigDecimal,
        paymentDate: LocalDate
    ): Receivable {
        val newOutstanding = (outstandingAmount - paidAmount).coerceAtLeast(BigDecimal.ZERO)
        val newTotalOutstanding = newOutstanding + lateFee
        val newStatus = when {
            newTotalOutstanding <= BigDecimal.ZERO -> ReceivableStatus.FULLY_PAID
            newOutstanding < originalAmount -> ReceivableStatus.PARTIALLY_PAID
            else -> ReceivableStatus.OUTSTANDING
        }

        return this.copy(
            outstandingAmount = newOutstanding,
            lateFee = lateFee,
            totalOutstanding = newTotalOutstanding,
            lastPaymentDate = paymentDate,
            status = newStatus,
            overdueDays = calculateOverdueDays()
        )
    }

    /**
     * 연체료 적용
     */
    fun applyLateFee(lateFeeAmount: BigDecimal): Receivable {
        return this.copy(
            lateFee = lateFeeAmount,
            totalOutstanding = outstandingAmount + lateFeeAmount,
            overdueDays = calculateOverdueDays()
        )
    }
}