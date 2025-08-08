package com.qiro.domain.accounting.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.util.*

/**
 * 거래 분류 규칙 엔티티
 * 자동 계정과목 제안을 위한 규칙을 관리합니다.
 */
@Entity
@Table(
    name = "transaction_rules",
    indexes = [
        Index(name = "idx_transaction_rules_company", columnList = "company_id"),
        Index(name = "idx_transaction_rules_priority", columnList = "priority"),
        Index(name = "idx_transaction_rules_active", columnList = "is_active")
    ]
)
class TransactionRule(
    @Id
    @Column(name = "rule_id")
    val ruleId: UUID = UUID.randomUUID(),

    @Column(name = "rule_name", nullable = false)
    val ruleName: String,

    @Column(name = "description")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_type")
    val transactionType: TransactionType? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "transaction_category")
    val transactionCategory: TransactionCategory? = null,

    @Column(name = "counterparty_pattern")
    val counterpartyPattern: String? = null,

    @Column(name = "description_pattern")
    val descriptionPattern: String? = null,

    @Column(name = "amount_min", precision = 15, scale = 2)
    val amountMin: BigDecimal? = null,

    @Column(name = "amount_max", precision = 15, scale = 2)
    val amountMax: BigDecimal? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_account_id", nullable = false)
    val suggestedAccount: Account,

    @Column(name = "confidence_score", nullable = false, precision = 5, scale = 2)
    val confidenceScore: BigDecimal = BigDecimal("0.80"),

    @Column(name = "priority", nullable = false)
    val priority: Int = 100,

    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    @Column(name = "usage_count", nullable = false)
    var usageCount: Long = 0,

    @Column(name = "success_count", nullable = false)
    var successCount: Long = 0
) : TenantAwareEntity() {

    /**
     * 거래가 이 규칙에 매칭되는지 확인
     */
    fun matches(transaction: Transaction): Boolean {
        if (!isActive) return false

        // 거래 유형 확인
        if (transactionType != null && transactionType != transaction.transactionType) {
            return false
        }

        // 거래 카테고리 확인
        if (transactionCategory != null && transactionCategory != transaction.transactionCategory) {
            return false
        }

        // 거래처 패턴 확인
        if (counterpartyPattern != null && transaction.counterparty != null) {
            val regex = Regex(counterpartyPattern, RegexOption.IGNORE_CASE)
            if (!regex.containsMatchIn(transaction.counterparty)) {
                return false
            }
        }

        // 설명 패턴 확인
        if (descriptionPattern != null) {
            val regex = Regex(descriptionPattern, RegexOption.IGNORE_CASE)
            if (!regex.containsMatchIn(transaction.description)) {
                return false
            }
        }

        // 금액 범위 확인
        if (amountMin != null && transaction.amount < amountMin) {
            return false
        }

        if (amountMax != null && transaction.amount > amountMax) {
            return false
        }

        return true
    }

    /**
     * 규칙 사용 횟수 증가
     */
    fun incrementUsage() {
        usageCount++
    }

    /**
     * 규칙 성공 횟수 증가
     */
    fun incrementSuccess() {
        successCount++
    }

    /**
     * 규칙 성공률 계산
     */
    fun getSuccessRate(): BigDecimal {
        return if (usageCount > 0) {
            BigDecimal(successCount).divide(BigDecimal(usageCount), 4, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }

    /**
     * 규칙 비활성화
     */
    fun deactivate() {
        isActive = false
    }

    /**
     * 규칙 활성화
     */
    fun activate() {
        isActive = true
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TransactionRule) return false
        return ruleId == other.ruleId
    }

    override fun hashCode(): Int = ruleId.hashCode()

    override fun toString(): String {
        return "TransactionRule(ruleId=$ruleId, ruleName='$ruleName', priority=$priority, isActive=$isActive)"
    }
}