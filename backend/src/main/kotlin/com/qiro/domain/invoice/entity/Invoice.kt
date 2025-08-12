package com.qiro.domain.invoice.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.billing.entity.MonthlyBilling
import com.qiro.domain.unit.entity.Unit
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 고지서 엔티티
 * 월별 관리비 고지서를 관리합니다.
 */
@Entity
@Table(
    name = "invoices",
    indexes = [
        Index(name = "idx_invoice_company_id", columnList = "company_id"),
        Index(name = "idx_invoice_unit_id", columnList = "unit_id"),
        Index(name = "idx_invoice_billing_id", columnList = "billing_id"),
        Index(name = "idx_invoice_status", columnList = "status"),
        Index(name = "idx_invoice_due_date", columnList = "due_date"),
        Index(name = "idx_invoice_issue_date", columnList = "issue_date")
    ]
)
class Invoice(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "invoice_id")
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    val unit: Unit,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "billing_id", nullable = false)
    val billing: MonthlyBilling,

    @Column(name = "invoice_number", nullable = false, unique = true, length = 50)
    val invoiceNumber: String,

    @Column(name = "issue_date", nullable = false)
    val issueDate: LocalDate,

    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: InvoiceStatus = InvoiceStatus.ISSUED,

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    val totalAmount: BigDecimal,

    @Column(name = "paid_amount", nullable = false, precision = 15, scale = 2)
    var paidAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "late_fee", nullable = false, precision = 15, scale = 2)
    var lateFee: BigDecimal = BigDecimal.ZERO,

    @Column(name = "discount_amount", nullable = false, precision = 15, scale = 2)
    var discountAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "pdf_file_path", length = 500)
    var pdfFilePath: String? = null,

    @Column(name = "sent_date")
    var sentDate: LocalDateTime? = null,

    @Column(name = "notes", length = 1000)
    var notes: String? = null

) : BaseEntity() {

    /**
     * 미납 금액 계산
     */
    val outstandingAmount: BigDecimal
        get() = totalAmount.add(lateFee).subtract(discountAmount).subtract(paidAmount)

    /**
     * 완납 여부 확인
     */
    val isFullyPaid: Boolean
        get() = outstandingAmount <= BigDecimal.ZERO

    /**
     * 연체 여부 확인
     */
    val isOverdue: Boolean
        get() = LocalDate.now().isAfter(dueDate) && !isFullyPaid

    /**
     * 연체 일수 계산
     */
    val overdueDays: Long
        get() = if (isOverdue) {
            java.time.temporal.ChronoUnit.DAYS.between(dueDate, LocalDate.now())
        } else 0

    /**
     * 고지서 발송 처리
     */
    fun markAsSent() {
        this.sentDate = LocalDateTime.now()
        this.status = InvoiceStatus.SENT
    }

    /**
     * 결제 처리
     */
    fun processPayment(amount: BigDecimal) {
        require(amount > BigDecimal.ZERO) { "결제 금액은 0보다 커야 합니다." }
        
        this.paidAmount = this.paidAmount.add(amount)
        
        this.status = when {
            isFullyPaid -> InvoiceStatus.PAID
            paidAmount > BigDecimal.ZERO -> InvoiceStatus.PARTIALLY_PAID
            else -> InvoiceStatus.SENT
        }
    }

    /**
     * 연체료 적용
     */
    fun applyLateFee(fee: BigDecimal) {
        require(fee >= BigDecimal.ZERO) { "연체료는 0 이상이어야 합니다." }
        this.lateFee = fee
    }

    /**
     * 할인 적용
     */
    fun applyDiscount(discount: BigDecimal) {
        require(discount >= BigDecimal.ZERO) { "할인 금액은 0 이상이어야 합니다." }
        this.discountAmount = discount
    }

    /**
     * 고지서 취소
     */
    fun cancel(reason: String) {
        this.status = InvoiceStatus.CANCELLED
        this.notes = reason
    }
}

/**
 * 고지서 상태
 */
enum class InvoiceStatus(val displayName: String) {
    DRAFT("임시저장"),
    ISSUED("발행"),
    SENT("발송완료"),
    PARTIALLY_PAID("부분납부"),
    PAID("완납"),
    OVERDUE("연체"),
    CANCELLED("취소")
}