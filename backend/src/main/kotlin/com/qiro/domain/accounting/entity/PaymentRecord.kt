package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 결제 기록 엔티티
 * 미수금에 대한 결제 내역을 기록
 */
@Entity
@Table(name = "payment_records", schema = "bms")
data class PaymentRecord(
    @Id
    @Column(name = "payment_record_id")
    val paymentRecordId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receivable_id", nullable = false)
    val receivable: Receivable,

    @Column(name = "unit_id", length = 50)
    val unitId: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "income_record_id", nullable = false)
    val incomeRecord: IncomeRecord,

    @Column(name = "payment_date", nullable = false)
    val paymentDate: LocalDate,

    @Column(name = "payment_amount", nullable = false, precision = 15, scale = 2)
    val paidAmount: BigDecimal,

    @Column(name = "late_fee_paid", precision = 15, scale = 2)
    val lateFeePaid: BigDecimal = BigDecimal.ZERO,

    @Column(name = "total_paid", nullable = false, precision = 15, scale = 2)
    val totalPaid: BigDecimal = paidAmount + lateFeePaid,

    @Column(name = "payment_method", length = 50)
    val paymentMethod: String? = null,

    @Column(name = "bank_account_id")
    val bankAccountId: UUID? = null,

    @Column(name = "transaction_reference", length = 100)
    val transactionReference: String? = null,

    @Column(name = "notes", columnDefinition = "TEXT")
    val notes: String? = null,

    @Column(name = "journal_entry_id")
    val journalEntryId: UUID? = null,

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 분개 전표 연결
     */
    fun withJournalEntry(journalEntryId: UUID): PaymentRecord {
        return this.copy(journalEntryId = journalEntryId)
    }

    /**
     * 결제 유효성 검증
     */
    fun isValid(): Boolean {
        return paidAmount > BigDecimal.ZERO &&
                lateFeePaid >= BigDecimal.ZERO &&
                totalPaid == paidAmount + lateFeePaid
    }
}