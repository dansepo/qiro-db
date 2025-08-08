package com.qiro.domain.accounting.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 거래 엔티티
 * 회계 시스템의 모든 거래 정보를 관리합니다.
 */
@Entity
@Table(
    name = "transactions",
    indexes = [
        Index(name = "idx_transactions_company_date", columnList = "company_id, transaction_date"),
        Index(name = "idx_transactions_type", columnList = "transaction_type"),
        Index(name = "idx_transactions_status", columnList = "status"),
        Index(name = "idx_transactions_reference", columnList = "reference_type, reference_id"),
        Index(name = "idx_transactions_account", columnList = "suggested_account_id")
    ]
)
class Transaction(
    @Id
    @Column(name = "transaction_id")
    val transactionId: UUID = UUID.randomUUID(),

    @Column(name = "transaction_number", nullable = false, length = 50)
    val transactionNumber: String,

    @Column(name = "transaction_date", nullable = false)
    val transactionDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type", nullable = false, length = 20)
    val transactionType: TransactionType,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_category", nullable = false, length = 30)
    val transactionCategory: TransactionCategory,

    @Column(name = "description", nullable = false, columnDefinition = "TEXT")
    val description: String,

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    val amount: BigDecimal,

    @Column(name = "counterparty", length = 255)
    val counterparty: String? = null,

    @Column(name = "counterparty_account", length = 50)
    val counterpartyAccount: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_account_id")
    var suggestedAccount: Account? = null,

    @Column(name = "confidence_score", precision = 5, scale = 2)
    var confidenceScore: BigDecimal? = null,

    @Column(name = "reference_type", length = 50)
    val referenceType: String? = null,

    @Column(name = "reference_id")
    val referenceId: UUID? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    var status: TransactionStatus = TransactionStatus.PENDING,

    @Column(name = "approved_by")
    var approvedBy: UUID? = null,

    @Column(name = "approved_at")
    var approvedAt: LocalDateTime? = null,

    @Column(name = "rejection_reason", columnDefinition = "TEXT")
    var rejectionReason: String? = null,

    @Column(name = "tags", columnDefinition = "TEXT")
    val tags: String? = null,

    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null
) : TenantAwareEntity() {

    @OneToMany(mappedBy = "transaction", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val attachments: MutableSet<TransactionAttachment> = mutableSetOf()

    @OneToOne(mappedBy = "transaction", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    var journalEntry: JournalEntry? = null

    /**
     * 거래 승인
     */
    fun approve(approvedBy: UUID, suggestedAccount: Account) {
        require(status == TransactionStatus.PENDING) { "승인 대기 중인 거래만 승인할 수 있습니다." }
        
        this.status = TransactionStatus.APPROVED
        this.approvedBy = approvedBy
        this.approvedAt = LocalDateTime.now()
        this.suggestedAccount = suggestedAccount
    }

    /**
     * 거래 거부
     */
    fun reject(rejectedBy: UUID, reason: String) {
        require(status == TransactionStatus.PENDING) { "승인 대기 중인 거래만 거부할 수 있습니다." }
        
        this.status = TransactionStatus.REJECTED
        this.approvedBy = rejectedBy
        this.approvedAt = LocalDateTime.now()
        this.rejectionReason = reason
    }

    /**
     * 분개 전표 생성 완료 처리
     */
    fun markAsProcessed(journalEntry: JournalEntry) {
        require(status == TransactionStatus.APPROVED) { "승인된 거래만 처리할 수 있습니다." }
        
        this.status = TransactionStatus.PROCESSED
        this.journalEntry = journalEntry
    }

    /**
     * 첨부파일 추가
     */
    fun addAttachment(attachment: TransactionAttachment) {
        attachments.add(attachment)
        attachment.transaction = this
    }

    /**
     * 첨부파일 제거
     */
    fun removeAttachment(attachment: TransactionAttachment) {
        attachments.remove(attachment)
        attachment.transaction = null
    }

    /**
     * 태그 목록 반환
     */
    fun getTagList(): List<String> {
        return tags?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
    }

    /**
     * 수입 거래인지 확인
     */
    fun isIncome(): Boolean = transactionType == TransactionType.INCOME

    /**
     * 지출 거래인지 확인
     */
    fun isExpense(): Boolean = transactionType == TransactionType.EXPENSE

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Transaction) return false
        return transactionId == other.transactionId
    }

    override fun hashCode(): Int = transactionId.hashCode()

    override fun toString(): String {
        return "Transaction(transactionId=$transactionId, transactionNumber='$transactionNumber', transactionType=$transactionType, amount=$amount)"
    }
}

/**
 * 거래 유형 열거형
 */
enum class TransactionType {
    /** 수입 */
    INCOME,
    /** 지출 */
    EXPENSE
}

/**
 * 거래 카테고리 열거형
 */
enum class TransactionCategory {
    // 수입 카테고리
    /** 관리비 수입 */
    MANAGEMENT_FEE_INCOME,
    /** 임대료 수입 */
    RENTAL_INCOME,
    /** 주차비 수입 */
    PARKING_FEE_INCOME,
    /** 기타 수입 */
    OTHER_INCOME,
    
    // 지출 카테고리
    /** 시설 관리비 */
    FACILITY_MAINTENANCE,
    /** 인건비 */
    PERSONNEL_EXPENSE,
    /** 공과금 */
    UTILITY_EXPENSE,
    /** 보험료 */
    INSURANCE_EXPENSE,
    /** 세금 */
    TAX_EXPENSE,
    /** 수선비 */
    REPAIR_EXPENSE,
    /** 청소비 */
    CLEANING_EXPENSE,
    /** 보안비 */
    SECURITY_EXPENSE,
    /** 기타 지출 */
    OTHER_EXPENSE
}

/**
 * 거래 상태 열거형
 */
enum class TransactionStatus {
    /** 승인 대기 */
    PENDING,
    /** 승인됨 */
    APPROVED,
    /** 거부됨 */
    REJECTED,
    /** 처리 완료 (분개 전표 생성됨) */
    PROCESSED
}