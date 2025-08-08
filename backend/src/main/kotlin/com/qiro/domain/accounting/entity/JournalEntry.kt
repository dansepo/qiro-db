package com.qiro.domain.accounting.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 분개 전표 엔티티
 * 회계 분개 전표의 헤더 정보를 관리합니다.
 */
@Entity
@Table(
    name = "journal_entries",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "entry_number"])
    ],
    indexes = [
        Index(name = "idx_journal_entries_company_date", columnList = "company_id, entry_date"),
        Index(name = "idx_journal_entries_status", columnList = "status"),
        Index(name = "idx_journal_entries_number", columnList = "entry_number"),
        Index(name = "idx_journal_entries_reference", columnList = "reference_type, reference_id")
    ]
)
class JournalEntry(
    @Id
    @Column(name = "entry_id")
    val entryId: UUID = UUID.randomUUID(),

    @Column(name = "entry_number", nullable = false, length = 50)
    val entryNumber: String,

    @Column(name = "entry_date", nullable = false)
    val entryDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "entry_type", nullable = false, length = 20)
    val entryType: JournalEntryType = JournalEntryType.MANUAL,

    @Column(name = "reference_type", length = 50)
    val referenceType: String? = null,

    @Column(name = "reference_id")
    val referenceId: UUID? = null,

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    val description: String,

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    var totalAmount: BigDecimal = BigDecimal.ZERO,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: JournalEntryStatus = JournalEntryStatus.DRAFT,

    @Column(name = "approved_by")
    var approvedBy: UUID? = null,

    @Column(name = "approved_at")
    var approvedAt: LocalDateTime? = null,

    @Column(name = "posted_at")
    var postedAt: LocalDateTime? = null,

    @Column(name = "reversed_at")
    var reversedAt: LocalDateTime? = null,

    @Column(name = "reversal_reason", columnDefinition = "TEXT")
    var reversalReason: String? = null
) : TenantAwareEntity() {

    @OneToMany(mappedBy = "journalEntry", cascade = [CascadeType.ALL], fetch = FetchType.LAZY, orphanRemoval = true)
    val journalEntryLines: MutableSet<JournalEntryLine> = mutableSetOf()

    /**
     * 분개선 추가
     */
    fun addJournalEntryLine(line: JournalEntryLine) {
        journalEntryLines.add(line)
        line.journalEntry = this
    }

    /**
     * 분개선 제거
     */
    fun removeJournalEntryLine(line: JournalEntryLine) {
        journalEntryLines.remove(line)
        line.journalEntry = null
    }

    /**
     * 총 차변 금액 계산
     */
    fun getTotalDebitAmount(): BigDecimal {
        return journalEntryLines.sumOf { it.debitAmount }
    }

    /**
     * 총 대변 금액 계산
     */
    fun getTotalCreditAmount(): BigDecimal {
        return journalEntryLines.sumOf { it.creditAmount }
    }

    /**
     * 복식부기 원칙 검증
     */
    fun isBalanced(): Boolean {
        return getTotalDebitAmount().compareTo(getTotalCreditAmount()) == 0
    }

    /**
     * 분개 전표 승인
     */
    fun approve(approvedBy: UUID) {
        require(status == JournalEntryStatus.PENDING) { "승인 대기 중인 분개 전표만 승인할 수 있습니다." }
        require(isBalanced()) { "차변과 대변의 합계가 일치하지 않습니다." }
        
        this.status = JournalEntryStatus.APPROVED
        this.approvedBy = approvedBy
        this.approvedAt = LocalDateTime.now()
    }

    /**
     * 분개 전표 전기
     */
    fun post() {
        require(status == JournalEntryStatus.APPROVED) { "승인된 분개 전표만 전기할 수 있습니다." }
        require(isBalanced()) { "차변과 대변의 합계가 일치하지 않습니다." }
        
        this.status = JournalEntryStatus.POSTED
        this.postedAt = LocalDateTime.now()
    }

    /**
     * 분개 전표 역분개 처리
     */
    fun reverse(reversalReason: String) {
        require(status == JournalEntryStatus.POSTED) { "전기된 분개 전표만 역분개할 수 있습니다." }
        
        this.status = JournalEntryStatus.REVERSED
        this.reversedAt = LocalDateTime.now()
        this.reversalReason = reversalReason
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is JournalEntry) return false
        return entryId == other.entryId
    }

    override fun hashCode(): Int = entryId.hashCode()

    override fun toString(): String {
        return "JournalEntry(entryId=$entryId, entryNumber='$entryNumber', entryDate=$entryDate, status=$status)"
    }
}

/**
 * 분개 전표 유형 열거형
 */
enum class JournalEntryType {
    /** 수동 입력 */
    MANUAL,
    /** 자동 생성 */
    AUTO,
    /** 수정 분개 */
    ADJUSTMENT,
    /** 마감 분개 */
    CLOSING
}

/**
 * 분개 전표 상태 열거형
 */
enum class JournalEntryStatus {
    /** 초안 */
    DRAFT,
    /** 승인 대기 */
    PENDING,
    /** 승인됨 */
    APPROVED,
    /** 전기됨 */
    POSTED,
    /** 역분개됨 */
    REVERSED
}