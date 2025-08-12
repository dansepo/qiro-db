package com.qiro.domain.delinquency.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.unit.entity.Unit
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 미납 관리 엔티티
 * 연체된 관리비 및 연체료 관리를 담당합니다.
 */
@Entity
@Table(
    name = "delinquency_records",
    indexes = [
        Index(name = "idx_delinquency_company_id", columnList = "company_id"),
        Index(name = "idx_delinquency_unit_id", columnList = "unit_id"),
        Index(name = "idx_delinquency_invoice_id", columnList = "invoice_id"),
        Index(name = "idx_delinquency_status", columnList = "status"),
        Index(name = "idx_delinquency_overdue_days", columnList = "overdue_days"),
        Index(name = "idx_delinquency_created_date", columnList = "created_date")
    ]
)
class DelinquencyRecord(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "delinquency_id")
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "unit_id", nullable = false)
    val unit: Unit,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "invoice_id", nullable = false)
    val invoice: Invoice,

    @Column(name = "created_date", nullable = false)
    val createdDate: LocalDate = LocalDate.now(),

    @Column(name = "due_date", nullable = false)
    val dueDate: LocalDate,

    @Column(name = "original_amount", nullable = false, precision = 15, scale = 2)
    val originalAmount: BigDecimal,

    @Column(name = "outstanding_amount", nullable = false, precision = 15, scale = 2)
    var outstandingAmount: BigDecimal,

    @Column(name = "late_fee_amount", nullable = false, precision = 15, scale = 2)
    var lateFeeAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "overdue_days", nullable = false)
    var overdueDays: Int,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: DelinquencyStatus = DelinquencyStatus.ACTIVE,

    @Enumerated(EnumType.STRING)
    @Column(name = "severity_level", nullable = false, length = 20)
    var severityLevel: SeverityLevel = SeverityLevel.LOW,

    @Column(name = "last_notice_date")
    var lastNoticeDate: LocalDate? = null,

    @Column(name = "notice_count", nullable = false)
    var noticeCount: Int = 0,

    @Column(name = "legal_action_date")
    var legalActionDate: LocalDate? = null,

    @Column(name = "settlement_date")
    var settlementDate: LocalDate? = null,

    @Column(name = "settlement_amount", precision = 15, scale = 2)
    var settlementAmount: BigDecimal? = null,

    @Column(name = "notes", length = 1000)
    var notes: String? = null,

    @Column(name = "assigned_to", length = 100)
    var assignedTo: String? = null,

    @Column(name = "next_action_date")
    var nextActionDate: LocalDate? = null,

    @Column(name = "contact_attempts", nullable = false)
    var contactAttempts: Int = 0,

    @Column(name = "last_contact_date")
    var lastContactDate: LocalDate? = null

) : BaseEntity() {

    /**
     * 총 미납 금액 (원금 + 연체료)
     */
    val totalDelinquencyAmount: BigDecimal
        get() = outstandingAmount.add(lateFeeAmount)

    /**
     * 연체료 비율 계산
     */
    val lateFeeRatio: BigDecimal
        get() = if (originalAmount > BigDecimal.ZERO) {
            lateFeeAmount.divide(originalAmount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal(100))
        } else {
            BigDecimal.ZERO
        }

    /**
     * 연체 일수 업데이트
     */
    fun updateOverdueDays() {
        this.overdueDays = java.time.temporal.ChronoUnit.DAYS.between(dueDate, LocalDate.now()).toInt()
        updateSeverityLevel()
    }

    /**
     * 심각도 레벨 업데이트
     */
    private fun updateSeverityLevel() {
        this.severityLevel = when {
            overdueDays >= 90 -> SeverityLevel.CRITICAL
            overdueDays >= 60 -> SeverityLevel.HIGH
            overdueDays >= 30 -> SeverityLevel.MEDIUM
            else -> SeverityLevel.LOW
        }
    }

    /**
     * 연체료 적용
     */
    fun applyLateFee(amount: BigDecimal) {
        require(amount >= BigDecimal.ZERO) { "연체료는 0 이상이어야 합니다." }
        this.lateFeeAmount = amount
    }

    /**
     * 부분 결제 처리
     */
    fun processPartialPayment(amount: BigDecimal) {
        require(amount > BigDecimal.ZERO) { "결제 금액은 0보다 커야 합니다." }
        require(amount <= totalDelinquencyAmount) { "결제 금액이 총 미납 금액을 초과합니다." }
        
        this.outstandingAmount = this.outstandingAmount.subtract(amount)
        
        if (this.outstandingAmount <= BigDecimal.ZERO) {
            this.status = DelinquencyStatus.RESOLVED
            this.settlementDate = LocalDate.now()
            this.settlementAmount = amount
        }
    }

    /**
     * 독촉 통지 발송
     */
    fun sendNotice() {
        this.lastNoticeDate = LocalDate.now()
        this.noticeCount++
        this.nextActionDate = LocalDate.now().plusDays(7) // 7일 후 다음 조치
    }

    /**
     * 연락 시도 기록
     */
    fun recordContactAttempt() {
        this.contactAttempts++
        this.lastContactDate = LocalDate.now()
    }

    /**
     * 법적 조치 시작
     */
    fun startLegalAction() {
        this.legalActionDate = LocalDate.now()
        this.status = DelinquencyStatus.LEGAL_ACTION
        this.severityLevel = SeverityLevel.CRITICAL
    }

    /**
     * 미납 해결
     */
    fun resolve(settlementAmount: BigDecimal, notes: String? = null) {
        this.status = DelinquencyStatus.RESOLVED
        this.settlementDate = LocalDate.now()
        this.settlementAmount = settlementAmount
        this.outstandingAmount = BigDecimal.ZERO
        this.notes = notes
    }

    /**
     * 미납 기록 비활성화
     */
    fun deactivate(reason: String) {
        this.status = DelinquencyStatus.INACTIVE
        this.notes = reason
    }

    /**
     * 담당자 배정
     */
    fun assignTo(assignee: String) {
        this.assignedTo = assignee
    }
}

/**
 * 미납 상태
 */
enum class DelinquencyStatus(val displayName: String) {
    ACTIVE("활성"),
    RESOLVED("해결"),
    LEGAL_ACTION("법적조치"),
    INACTIVE("비활성"),
    WRITTEN_OFF("손실처리")
}

/**
 * 심각도 레벨
 */
enum class SeverityLevel(val displayName: String, val colorCode: String) {
    LOW("낮음", "#28a745"),      // 초록색
    MEDIUM("보통", "#ffc107"),   // 노란색
    HIGH("높음", "#fd7e14"),     // 주황색
    CRITICAL("심각", "#dc3545")  // 빨간색
}