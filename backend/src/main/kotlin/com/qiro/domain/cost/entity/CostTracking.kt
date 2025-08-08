package com.qiro.domain.cost.entity

import com.qiro.domain.cost.dto.CostCategory
import com.qiro.domain.cost.dto.CostType
import com.qiro.domain.cost.dto.PaymentMethod
import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 추적 엔티티
 */
@Entity
@Table(
    name = "cost_tracking",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_cost_number", columnNames = ["company_id", "cost_number"])
    ]
)
data class CostTracking(
    @Id
    @Column(name = "cost_id")
    val costId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "work_order_id")
    val workOrderId: UUID? = null,

    @Column(name = "maintenance_id")
    val maintenanceId: UUID? = null,

    @Column(name = "fault_report_id")
    val faultReportId: UUID? = null,

    @Column(name = "cost_number", nullable = false, length = 50)
    val costNumber: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "cost_type", nullable = false, length = 30)
    val costType: CostType,

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    val category: CostCategory,

    @Column(name = "amount", nullable = false, precision = 12, scale = 2)
    val amount: BigDecimal,

    @Column(name = "currency", length = 3)
    val currency: String = "KRW",

    @Column(name = "cost_date", nullable = false)
    val costDate: LocalDate,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", length = 20)
    val paymentMethod: PaymentMethod? = null,

    @Column(name = "invoice_number", length = 50)
    val invoiceNumber: String? = null,

    @Column(name = "receipt_number", length = 50)
    val receiptNumber: String? = null,

    @Column(name = "approved_by")
    val approvedBy: UUID? = null,

    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,

    @Column(name = "approval_notes", columnDefinition = "TEXT")
    val approvalNotes: String? = null,

    @Column(name = "budget_category", length = 50)
    val budgetCategory: String? = null,

    @Column(name = "budget_year")
    val budgetYear: Int? = null,

    @Column(name = "budget_month")
    val budgetMonth: Int? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @UpdateTimestamp
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 비용 승인
     */
    fun approve(approvedBy: UUID, approvalNotes: String? = null): CostTracking {
        return this.copy(
            approvedBy = approvedBy,
            approvalDate = LocalDateTime.now(),
            approvalNotes = approvalNotes,
            updatedBy = approvedBy
        )
    }

    /**
     * 비용 정보 업데이트
     */
    fun update(
        amount: BigDecimal? = null,
        costDate: LocalDate? = null,
        description: String? = null,
        paymentMethod: PaymentMethod? = null,
        invoiceNumber: String? = null,
        receiptNumber: String? = null,
        budgetCategory: String? = null,
        updatedBy: UUID
    ): CostTracking {
        return this.copy(
            amount = amount ?: this.amount,
            costDate = costDate ?: this.costDate,
            description = description ?: this.description,
            paymentMethod = paymentMethod ?: this.paymentMethod,
            invoiceNumber = invoiceNumber ?: this.invoiceNumber,
            receiptNumber = receiptNumber ?: this.receiptNumber,
            budgetCategory = budgetCategory ?: this.budgetCategory,
            updatedBy = updatedBy
        )
    }

    /**
     * 승인 여부 확인
     */
    fun isApproved(): Boolean = approvedBy != null && approvalDate != null

    /**
     * 예산 연도/월 자동 설정
     */
    fun withBudgetPeriod(): CostTracking {
        return this.copy(
            budgetYear = costDate.year,
            budgetMonth = costDate.monthValue
        )
    }
}