package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 수입 기록 엔티티
 * 관리비, 임대료 등의 수입을 기록
 */
@Entity
@Table(name = "income_records", schema = "bms")
data class IncomeRecord(
    @Id
    @Column(name = "income_record_id")
    val incomeRecordId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "income_type_id", nullable = false)
    val incomeType: IncomeType,

    @Column(name = "building_id")
    val buildingId: UUID? = null,

    @Column(name = "unit_id", length = 50)
    val unitId: String? = null,

    @Column(name = "contract_id")
    val contractId: UUID? = null,

    @Column(name = "tenant_id")
    val tenantId: UUID? = null,

    @Column(name = "income_date", nullable = false)
    val incomeDate: LocalDate,

    @Column(name = "due_date")
    val dueDate: LocalDate? = null,

    @Column(name = "period", length = 10)
    val period: String? = null, // YYYY-MM 형식

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

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    val status: IncomeStatus = IncomeStatus.PENDING,

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
        VIRTUAL_ACCOUNT("VIRTUAL_ACCOUNT", "가상계좌"),
        MOBILE_PAYMENT("MOBILE_PAYMENT", "모바일결제");

        companion object {
            fun fromCode(code: String): PaymentMethod? = values().find { it.code == code }
        }
    }

    /**
     * 수입 기록 복사 (상태 변경용)
     */
    fun withStatus(newStatus: IncomeStatus): IncomeRecord {
        return this.copy(status = newStatus)
    }

    /**
     * 분개 전표 연결
     */
    fun withJournalEntry(journalEntryId: UUID): IncomeRecord {
        return this.copy(journalEntryId = journalEntryId)
    }
}