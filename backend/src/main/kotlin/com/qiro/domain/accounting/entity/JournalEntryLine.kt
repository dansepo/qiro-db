package com.qiro.domain.accounting.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.util.*

/**
 * 분개선 엔티티
 * 분개 전표의 상세 라인 정보를 관리합니다.
 */
@Entity
@Table(
    name = "journal_entry_lines",
    indexes = [
        Index(name = "idx_journal_entry_lines_entry", columnList = "entry_id"),
        Index(name = "idx_journal_entry_lines_account", columnList = "account_id"),
        Index(name = "idx_journal_entry_lines_reference", columnList = "reference_type, reference_id")
    ]
)
class JournalEntryLine(
    @Id
    @Column(name = "line_id")
    val lineId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "entry_id", nullable = false)
    var journalEntry: JournalEntry? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    val account: Account,

    @Column(name = "debit_amount", nullable = false, precision = 15, scale = 2)
    val debitAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "credit_amount", nullable = false, precision = 15, scale = 2)
    val creditAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "reference_type", length = 50)
    val referenceType: String? = null,

    @Column(name = "reference_id")
    val referenceId: UUID? = null,

    @Column(name = "line_order", nullable = false)
    val lineOrder: Int
) : BaseEntity() {

    init {
        // 차변 또는 대변 중 하나만 값을 가져야 함
        require((debitAmount > BigDecimal.ZERO && creditAmount == BigDecimal.ZERO) ||
                (debitAmount == BigDecimal.ZERO && creditAmount > BigDecimal.ZERO)) {
            "차변 또는 대변 중 하나만 값을 가져야 합니다."
        }
        
        // 금액은 0보다 커야 함
        require(debitAmount >= BigDecimal.ZERO && creditAmount >= BigDecimal.ZERO) {
            "금액은 0보다 크거나 같아야 합니다."
        }
    }

    /**
     * 차변 분개선인지 확인
     */
    fun isDebit(): Boolean = debitAmount > BigDecimal.ZERO

    /**
     * 대변 분개선인지 확인
     */
    fun isCredit(): Boolean = creditAmount > BigDecimal.ZERO

    /**
     * 분개선의 금액 반환 (차변은 양수, 대변은 음수)
     */
    fun getAmount(): BigDecimal = debitAmount - creditAmount

    /**
     * 분개선의 절대 금액 반환
     */
    fun getAbsoluteAmount(): BigDecimal = if (isDebit()) debitAmount else creditAmount

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is JournalEntryLine) return false
        return lineId == other.lineId
    }

    override fun hashCode(): Int = lineId.hashCode()

    override fun toString(): String {
        return "JournalEntryLine(lineId=$lineId, account=${account.accountCode}, debitAmount=$debitAmount, creditAmount=$creditAmount)"
    }
}