package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 지출 기록 엔티티
 * 관리비, 공과금 등의 지출을 기록
 */
@Entity
@Table(name = "expense_records", schema = "bms")
data class ExpenseRecord(
    @Id
    @Column(name = "expense_record_id")
    val expenseRecordId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "expense_type_id", nullable = false)
    val expenseType: ExpenseType,

    @Column(name = "building_id")
    val buildingId: UUID? = null,

    @Column(name = "unit_id")
    val unitId: UUID? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendor_id")
    val vendor: Vendor? = null,

    @Column(name = "expense_date", nullable = false)
    val expenseDate: LocalDate,

    @Column(name = "due_date")
    val dueDate: LocalDate? = null,

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    val amount: BigDecimal,

    @Column(name = "tax_amount", precision = 15, scale = 2)
    val taxAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    val totalAmount: BigDecimal,

    @Column(name = "payment_method", length = 50)
    val paymentMethod: String? = null,

    @Column(name = "bank_account_id")
    val bankAccountId: UUID? = null,

    @Column(name = "reference_number", length = 100)
    val referenceNumber: String? = null,

    @Column(name = "invoice_number", length = 100)
    val invoiceNumber: String? = null,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    var status: ExpenseStatus = ExpenseStatus.PENDING,

    @Enumerated(EnumType.STRING)
    @Column(name = "approval_status", length = 20)
    var approvalStatus: ApprovalStatus? = ApprovalStatus.PENDING,

    @Column(name = "approved_by")
    val approvedBy: UUID? = null,

    @Column(name = "approved_at")
    var approvedAt: LocalDate? = null,

    @Column(name = "approval_notes", columnDefinition = "TEXT")
    var approvalNotes: String? = null,

    @Column(name = "is_recurring")
    val isRecurring: Boolean = false,

    @Column(name = "paid_at")
    val paidAt: LocalDateTime? = null,

    @Column(name = "journal_entry_id")
    val journalEntryId: UUID? = null,

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {


    /**
     * 결제 방법 열거형
     */
    enum class PaymentMethod(val code: String, val displayName: String) {
        BANK_TRANSFER("BANK_TRANSFER", "계좌이체"),
        CASH("CASH", "현금"),
        CARD("CARD", "카드"),
        CHECK("CHECK", "수표"),
        VIRTUAL_ACCOUNT("VIRTUAL_ACCOUNT", "가상계좌");

        companion object {
            fun fromCode(code: String): PaymentMethod? = values().find { it.code == code }
        }
    }

    /**
     * 승인 가능 여부 확인
     */
    fun canApprove(): Boolean {
        return approvalStatus == ApprovalStatus.PENDING && status == ExpenseStatus.PENDING
    }

    /**
     * 지급 가능 여부 확인
     */
    fun canPay(): Boolean {
        return approvalStatus == ApprovalStatus.APPROVED && status == ExpenseStatus.APPROVED
    }

    /**
     * 지출 기록 승인
     */
    fun approve(approvedBy: UUID): ExpenseRecord {
        return this.copy(
            approvalStatus = ApprovalStatus.APPROVED,
            status = ExpenseStatus.APPROVED,
            approvedBy = approvedBy,
            approvedAt = LocalDate.now()
        )
    }

    /**
     * 지출 기록 거부
     */
    fun reject(): ExpenseRecord {
        return this.copy(
            approvalStatus = ApprovalStatus.REJECTED,
            status = ExpenseStatus.CANCELLED
        )
    }

    /**
     * 지출 기록 지급 완료
     */
    fun markAsPaid(): ExpenseRecord {
        return this.copy(
            status = ExpenseStatus.PAID,
            paidAt = LocalDateTime.now()
        )
    }

    /**
     * 분개 전표 연결
     */
    fun withJournalEntry(journalEntryId: UUID): ExpenseRecord {
        return this.copy(journalEntryId = journalEntryId)
    }
}