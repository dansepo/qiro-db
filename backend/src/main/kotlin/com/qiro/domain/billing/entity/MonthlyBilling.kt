package com.qiro.domain.billing.entity

import com.qiro.domain.lease.entity.LeaseContract
import com.qiro.domain.unit.entity.Unit
import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 월별 관리비 청구서 엔티티
 */
@Entity
@Table(
    name = "monthly_billings",
    indexes = [
        Index(name = "idx_monthly_billing_company_billing_month", columns = ["company_id", "billing_year", "billing_month"]),
        Index(name = "idx_monthly_billing_unit_billing_month", columns = ["unit_id", "billing_year", "billing_month"]),
        Index(name = "idx_monthly_billing_contract", columns = ["contract_id"]),
        Index(name = "idx_monthly_billing_status", columns = ["billing_status"]),
        Index(name = "idx_monthly_billing_due_date", columns = ["due_date"])
    ],
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_monthly_billing_unit_month",
            columnNames = ["unit_id", "billing_year", "billing_month"]
        )
    ]
)
class MonthlyBilling(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "billing_id")
    val billingId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    val unit: Unit,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contract_id", nullable = false)
    val contract: LeaseContract,

    @Column(name = "billing_number", nullable = false, length = 50)
    val billingNumber: String,

    @Column(name = "billing_year", nullable = false)
    val billingYear: Int,

    @Column(name = "billing_month", nullable = false)
    val billingMonth: Int,

    @Enumerated(EnumType.STRING)
    @Column(name = "billing_status", nullable = false, length = 20)
    var billingStatus: BillingStatus = BillingStatus.DRAFT,

    @Column(name = "issue_date", nullable = false)
    val issueDate: LocalDate,

    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    // 임대료 관련
    @Column(name = "monthly_rent", nullable = false, precision = 15, scale = 2)
    val monthlyRent: BigDecimal,

    @Column(name = "maintenance_fee", precision = 15, scale = 2)
    val maintenanceFee: BigDecimal? = null,

    @Column(name = "parking_fee", precision = 15, scale = 2)
    val parkingFee: BigDecimal? = null,

    // 공과금 관련
    @Column(name = "electricity_fee", precision = 15, scale = 2)
    var electricityFee: BigDecimal? = null,

    @Column(name = "gas_fee", precision = 15, scale = 2)
    var gasFee: BigDecimal? = null,

    @Column(name = "water_fee", precision = 15, scale = 2)
    var waterFee: BigDecimal? = null,

    @Column(name = "heating_fee", precision = 15, scale = 2)
    var heatingFee: BigDecimal? = null,

    @Column(name = "internet_fee", precision = 15, scale = 2)
    var internetFee: BigDecimal? = null,

    @Column(name = "tv_fee", precision = 15, scale = 2)
    var tvFee: BigDecimal? = null,

    // 기타 비용
    @Column(name = "cleaning_fee", precision = 15, scale = 2)
    var cleaningFee: BigDecimal? = null,

    @Column(name = "security_fee", precision = 15, scale = 2)
    var securityFee: BigDecimal? = null,

    @Column(name = "elevator_fee", precision = 15, scale = 2)
    var elevatorFee: BigDecimal? = null,

    @Column(name = "common_area_fee", precision = 15, scale = 2)
    var commonAreaFee: BigDecimal? = null,

    @Column(name = "repair_reserve_fee", precision = 15, scale = 2)
    var repairReserveFee: BigDecimal? = null,

    @Column(name = "insurance_fee", precision = 15, scale = 2)
    var insuranceFee: BigDecimal? = null,

    @Column(name = "other_fees", precision = 15, scale = 2)
    var otherFees: BigDecimal? = null,

    // 할인/할증
    @Column(name = "discount_amount", precision = 15, scale = 2)
    var discountAmount: BigDecimal? = null,

    @Column(name = "discount_reason", length = 200)
    var discountReason: String? = null,

    @Column(name = "late_fee", precision = 15, scale = 2)
    var lateFee: BigDecimal? = null,

    @Column(name = "adjustment_amount", precision = 15, scale = 2)
    var adjustmentAmount: BigDecimal? = null,

    @Column(name = "adjustment_reason", length = 200)
    var adjustmentReason: String? = null,

    // 결제 관련
    @Column(name = "paid_amount", precision = 15, scale = 2)
    var paidAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "payment_date")
    var paymentDate: LocalDate? = null,

    @Column(name = "payment_method", length = 50)
    var paymentMethod: String? = null,

    @Column(name = "payment_reference", length = 100)
    var paymentReference: String? = null,

    // 고지서 발송 관련
    @Column(name = "sent_date")
    var sentDate: LocalDateTime? = null,

    @Column(name = "sent_method", length = 50)
    var sentMethod: String? = null,

    @Column(name = "recipient_email", length = 100)
    var recipientEmail: String? = null,

    @Column(name = "recipient_phone", length = 20)
    var recipientPhone: String? = null,

    // 메모
    @Column(name = "notes", length = 1000)
    var notes: String? = null

) : BaseEntity() {

    /**
     * 총 청구 금액 계산
     */
    fun calculateTotalAmount(): BigDecimal {
        var total = monthlyRent
        
        // 관리비 추가
        maintenanceFee?.let { total = total.add(it) }
        parkingFee?.let { total = total.add(it) }
        
        // 공과금 추가
        electricityFee?.let { total = total.add(it) }
        gasFee?.let { total = total.add(it) }
        waterFee?.let { total = total.add(it) }
        heatingFee?.let { total = total.add(it) }
        internetFee?.let { total = total.add(it) }
        tvFee?.let { total = total.add(it) }
        
        // 기타 비용 추가
        cleaningFee?.let { total = total.add(it) }
        securityFee?.let { total = total.add(it) }
        elevatorFee?.let { total = total.add(it) }
        commonAreaFee?.let { total = total.add(it) }
        repairReserveFee?.let { total = total.add(it) }
        insuranceFee?.let { total = total.add(it) }
        otherFees?.let { total = total.add(it) }
        
        // 연체료 추가
        lateFee?.let { total = total.add(it) }
        
        // 조정 금액 추가/차감
        adjustmentAmount?.let { total = total.add(it) }
        
        // 할인 차감
        discountAmount?.let { total = total.subtract(it) }
        
        return total.max(BigDecimal.ZERO)
    }

    /**
     * 미납 금액 계산
     */
    fun calculateUnpaidAmount(): BigDecimal {
        return calculateTotalAmount().subtract(paidAmount).max(BigDecimal.ZERO)
    }

    /**
     * 완납 여부 확인
     */
    fun isFullyPaid(): Boolean {
        return calculateUnpaidAmount() == BigDecimal.ZERO
    }

    /**
     * 연체 여부 확인
     */
    fun isOverdue(): Boolean {
        return !isFullyPaid() && dueDate.isBefore(LocalDate.now())
    }

    /**
     * 부분 결제 처리
     */
    fun processPayment(amount: BigDecimal, paymentDate: LocalDate, method: String?, reference: String?) {
        this.paidAmount = this.paidAmount.add(amount)
        this.paymentDate = paymentDate
        this.paymentMethod = method
        this.paymentReference = reference
        
        // 완납 시 상태 변경
        if (isFullyPaid()) {
            this.billingStatus = BillingStatus.PAID
        } else {
            this.billingStatus = BillingStatus.PARTIAL_PAID
        }
    }

    /**
     * 연체료 계산 및 적용
     */
    fun calculateAndApplyLateFee(lateFeeRate: BigDecimal?) {
        if (isOverdue() && lateFeeRate != null && lateFeeRate > BigDecimal.ZERO) {
            val unpaidAmount = calculateUnpaidAmount()
            val daysPastDue = java.time.temporal.ChronoUnit.DAYS.between(dueDate, LocalDate.now())
            
            if (daysPastDue > 0) {
                // 일할 계산: (미납금액 × 연체료율 × 연체일수) / 365
                val calculatedLateFee = unpaidAmount
                    .multiply(lateFeeRate.divide(BigDecimal.valueOf(100)))
                    .multiply(BigDecimal.valueOf(daysPastDue))
                    .divide(BigDecimal.valueOf(365), 2, java.math.RoundingMode.HALF_UP)
                
                this.lateFee = calculatedLateFee
            }
        }
    }

    /**
     * 고지서 발송 처리
     */
    fun markAsSent(method: String, email: String?, phone: String?) {
        this.sentDate = LocalDateTime.now()
        this.sentMethod = method
        this.recipientEmail = email
        this.recipientPhone = phone
        
        if (billingStatus == BillingStatus.DRAFT) {
            this.billingStatus = BillingStatus.ISSUED
        }
    }
}

/**
 * 청구서 상태
 */
enum class BillingStatus(val description: String) {
    DRAFT("초안"),
    ISSUED("발행"),
    SENT("발송"),
    PARTIAL_PAID("부분납부"),
    PAID("완납"),
    OVERDUE("연체"),
    CANCELLED("취소")
}