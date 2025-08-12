package com.qiro.domain.payment.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.unit.entity.Unit
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 수납 기록 엔티티
 * 관리비 및 기타 요금의 수납 내역을 관리합니다.
 */
@Entity
@Table(
    name = "payment_records",
    indexes = [
        Index(name = "idx_payment_company_id", columnList = "company_id"),
        Index(name = "idx_payment_unit_id", columnList = "unit_id"),
        Index(name = "idx_payment_invoice_id", columnList = "invoice_id"),
        Index(name = "idx_payment_date", columnList = "payment_date"),
        Index(name = "idx_payment_method", columnList = "payment_method"),
        Index(name = "idx_payment_status", columnList = "status")
    ]
)
class PaymentRecord(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "payment_id")
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    val unit: Unit,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = true)
    val invoice: Invoice? = null,

    @Column(name = "payment_number", nullable = false, unique = true, length = 50)
    val paymentNumber: String,

    @Column(name = "payment_date", nullable = false)
    val paymentDate: LocalDate,

    @Column(name = "payment_amount", nullable = false, precision = 15, scale = 2)
    val paymentAmount: BigDecimal,

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method", nullable = false, length = 20)
    val paymentMethod: PaymentMethod,

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_type", nullable = false, length = 20)
    val paymentType: PaymentType,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: PaymentStatus = PaymentStatus.COMPLETED,

    @Column(name = "bank_name", length = 50)
    val bankName: String? = null,

    @Column(name = "account_number", length = 50)
    val accountNumber: String? = null,

    @Column(name = "transaction_id", length = 100)
    val transactionId: String? = null,

    @Column(name = "receipt_number", length = 50)
    val receiptNumber: String? = null,

    @Column(name = "payer_name", nullable = false, length = 100)
    val payerName: String,

    @Column(name = "payer_phone", length = 20)
    val payerPhone: String? = null,

    @Column(name = "processed_by", length = 100)
    val processedBy: String? = null,

    @Column(name = "processed_at")
    val processedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "notes", length = 1000)
    var notes: String? = null,

    @Column(name = "refund_amount", precision = 15, scale = 2)
    var refundAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "refund_date")
    var refundDate: LocalDate? = null,

    @Column(name = "refund_reason", length = 500)
    var refundReason: String? = null

) : BaseEntity() {

    /**
     * 실제 수납 금액 (환불 제외)
     */
    val netPaymentAmount: BigDecimal
        get() = paymentAmount.subtract(refundAmount)

    /**
     * 환불 여부 확인
     */
    val isRefunded: Boolean
        get() = refundAmount > BigDecimal.ZERO

    /**
     * 부분 환불 여부 확인
     */
    val isPartiallyRefunded: Boolean
        get() = refundAmount > BigDecimal.ZERO && refundAmount < paymentAmount

    /**
     * 전액 환불 여부 확인
     */
    val isFullyRefunded: Boolean
        get() = refundAmount >= paymentAmount

    /**
     * 결제 취소
     */
    fun cancel(reason: String) {
        this.status = PaymentStatus.CANCELLED
        this.notes = reason
    }

    /**
     * 환불 처리
     */
    fun processRefund(amount: BigDecimal, reason: String) {
        require(amount > BigDecimal.ZERO) { "환불 금액은 0보다 커야 합니다." }
        require(amount <= paymentAmount.subtract(refundAmount)) { "환불 금액이 잔여 금액을 초과합니다." }
        
        this.refundAmount = this.refundAmount.add(amount)
        this.refundDate = LocalDate.now()
        this.refundReason = reason
        
        this.status = when {
            isFullyRefunded -> PaymentStatus.REFUNDED
            isPartiallyRefunded -> PaymentStatus.PARTIALLY_REFUNDED
            else -> PaymentStatus.COMPLETED
        }
    }

    /**
     * 결제 확인 처리
     */
    fun confirm() {
        this.status = PaymentStatus.CONFIRMED
    }
}

/**
 * 결제 방법
 */
enum class PaymentMethod(val displayName: String) {
    CASH("현금"),
    BANK_TRANSFER("계좌이체"),
    CARD("카드결제"),
    VIRTUAL_ACCOUNT("가상계좌"),
    MOBILE_PAYMENT("모바일결제"),
    CHECK("수표"),
    OTHER("기타")
}

/**
 * 결제 유형
 */
enum class PaymentType(val displayName: String) {
    MANAGEMENT_FEE("관리비"),
    LATE_FEE("연체료"),
    DEPOSIT("보증금"),
    UTILITY("공과금"),
    PARKING("주차비"),
    OTHER("기타")
}

/**
 * 결제 상태
 */
enum class PaymentStatus(val displayName: String) {
    PENDING("대기중"),
    COMPLETED("완료"),
    CONFIRMED("확인완료"),
    CANCELLED("취소"),
    PARTIALLY_REFUNDED("부분환불"),
    REFUNDED("환불완료"),
    FAILED("실패")
}