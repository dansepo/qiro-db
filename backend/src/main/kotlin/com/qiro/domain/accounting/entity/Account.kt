package com.qiro.domain.accounting.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import java.util.*

/**
 * 계정과목 엔티티
 * 회계 시스템의 계정과목 정보를 관리합니다.
 */
@Entity
@Table(
    name = "accounts",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "account_code"])
    ],
    indexes = [
        Index(name = "idx_accounts_company_code", columnList = "company_id, account_code"),
        Index(name = "idx_accounts_type", columnList = "account_type"),
        Index(name = "idx_accounts_parent", columnList = "parent_account_id")
    ]
)
class Account(
    @Id
    @Column(name = "account_id")
    val accountId: UUID = UUID.randomUUID(),

    @Column(name = "account_code", nullable = false, length = 20)
    val accountCode: String,

    @Column(name = "account_name", nullable = false)
    val accountName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "account_type", nullable = false, length = 20)
    val accountType: AccountType,

    @Column(name = "account_category", length = 50)
    val accountCategory: String? = null,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_account_id")
    val parentAccount: Account? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null
) : TenantAwareEntity() {

    @OneToMany(mappedBy = "parentAccount", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val childAccounts: MutableSet<Account> = mutableSetOf()

    @OneToMany(mappedBy = "account", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val journalEntryLines: MutableSet<JournalEntryLine> = mutableSetOf()

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Account) return false
        return accountId == other.accountId
    }

    override fun hashCode(): Int = accountId.hashCode()

    override fun toString(): String {
        return "Account(accountId=$accountId, accountCode='$accountCode', accountName='$accountName', accountType=$accountType)"
    }
}

/**
 * 계정 유형 열거형
 */
enum class AccountType {
    /** 자산 */
    ASSET,
    /** 부채 */
    LIABILITY,
    /** 자본 */
    EQUITY,
    /** 수익 */
    REVENUE,
    /** 비용 */
    EXPENSE
}