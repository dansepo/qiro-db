package com.qiro.domain.accounting.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.util.*

/**
 * 계정과목 엔티티
 * 회계 처리를 위한 계정 체계를 관리합니다.
 */
@Entity
@Table(
    name = "account_codes",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_account_codes_company_code",
            columnNames = ["company_id", "account_code"]
        )
    ],
    indexes = [
        Index(name = "idx_account_codes_company", columnList = "company_id"),
        Index(name = "idx_account_codes_type", columnList = "account_type"),
        Index(name = "idx_account_codes_parent", columnList = "parent_account_id"),
        Index(name = "idx_account_codes_active", columnList = "is_active")
    ]
)
class AccountCode(
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    val company: Company,

    @Column(name = "account_code", nullable = false, length = 20)
    var accountCode: String,

    @Column(name = "account_name", nullable = false)
    var accountName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "account_type", nullable = false)
    var accountType: AccountType,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_account_id")
    var parentAccount: AccountCode? = null,

    @Column(name = "account_level", nullable = false)
    var accountLevel: Int = 1,

    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    @Column(name = "is_system_account", nullable = false)
    var isSystemAccount: Boolean = false,

    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null
) : BaseEntity() {

    @OneToMany(mappedBy = "parentAccount", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val childAccounts: MutableList<AccountCode> = mutableListOf()

    /**
     * 계정과목의 현재 잔액을 계산합니다.
     * 실제 구현에서는 회계 항목들을 집계하여 계산합니다.
     */
    fun calculateBalance(): BigDecimal {
        // TODO: 실제 회계 항목들을 집계하여 잔액 계산
        return BigDecimal.ZERO
    }

    /**
     * 계정과목의 차변 잔액을 계산합니다.
     */
    fun calculateDebitBalance(): BigDecimal {
        // TODO: 차변 항목들을 집계하여 계산
        return BigDecimal.ZERO
    }

    /**
     * 계정과목의 대변 잔액을 계산합니다.
     */
    fun calculateCreditBalance(): BigDecimal {
        // TODO: 대변 항목들을 집계하여 계산
        return BigDecimal.ZERO
    }

    /**
     * 하위 계정과목을 추가합니다.
     */
    fun addChildAccount(childAccount: AccountCode) {
        childAccount.parentAccount = this
        childAccount.accountLevel = this.accountLevel + 1
        childAccounts.add(childAccount)
    }

    /**
     * 계정과목을 비활성화합니다.
     */
    fun deactivate() {
        if (hasActiveTransactions()) {
            throw IllegalStateException("활성 거래가 있는 계정과목은 비활성화할 수 없습니다.")
        }
        this.isActive = false
    }

    /**
     * 활성 거래가 있는지 확인합니다.
     */
    private fun hasActiveTransactions(): Boolean {
        // TODO: 실제 거래 내역 확인 로직 구현
        return false
    }

    /**
     * 계정과목 코드의 유효성을 검증합니다.
     */
    fun validateAccountCode(): Boolean {
        return accountCode.matches(Regex("^[0-9]{4}$"))
    }

    /**
     * 계정과목의 전체 경로를 반환합니다.
     */
    fun getFullPath(): String {
        return if (parentAccount != null) {
            "${parentAccount!!.getFullPath()} > $accountName"
        } else {
            accountName
        }
    }

    override fun toString(): String {
        return "AccountCode(id=$id, accountCode='$accountCode', accountName='$accountName', accountType=$accountType)"
    }
}

/**
 * 계정 유형 열거형
 */
enum class AccountType(val description: String, val normalBalance: String) {
    ASSET("자산", "DEBIT"),
    LIABILITY("부채", "CREDIT"),
    EQUITY("자본", "CREDIT"),
    REVENUE("수익", "CREDIT"),
    EXPENSE("비용", "DEBIT");

    /**
     * 차변이 정상 잔액인지 확인합니다.
     */
    fun isDebitNormal(): Boolean = normalBalance == "DEBIT"

    /**
     * 대변이 정상 잔액인지 확인합니다.
     */
    fun isCreditNormal(): Boolean = normalBalance == "CREDIT"
}