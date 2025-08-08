package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 예산 항목 엔티티
 * 예산 계획의 세부 항목 관리
 */
@Entity
@Table(name = "budget_items", schema = "bms")
data class BudgetItem(
    @Id
    @Column(name = "budget_item_id")
    val budgetItemId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "budget_plan_id", nullable = false)
    val budgetPlan: BudgetPlan,

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    val category: Category,

    @Column(name = "subcategory", length = 50)
    val subcategory: String? = null,

    @Column(name = "item_name", nullable = false, length = 100)
    val itemName: String,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "annual_budget", nullable = false, precision = 15, scale = 2)
    val annualBudget: BigDecimal,

    @Column(name = "allocated_budget", precision = 15, scale = 2)
    val allocatedBudget: BigDecimal = BigDecimal.ZERO,

    @Column(name = "used_budget", precision = 15, scale = 2)
    val usedBudget: BigDecimal = BigDecimal.ZERO,

    @Column(name = "remaining_budget", precision = 15, scale = 2)
    val remainingBudget: BigDecimal = BigDecimal.ZERO,

    @Column(name = "account_id")
    val accountId: UUID? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @OneToMany(mappedBy = "budgetItem", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val monthlyAllocations: List<MonthlyBudgetAllocation> = emptyList(),

    @OneToMany(mappedBy = "budgetItem", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val performanceTrackings: List<BudgetPerformanceTracking> = emptyList(),

    @OneToMany(mappedBy = "budgetItem", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val alertSettings: List<BudgetAlertSetting> = emptyList()
) {
    /**
     * 예산 카테고리
     */
    enum class Category(val displayName: String) {
        INCOME("수입"),
        EXPENSE("지출"),
        INVESTMENT("투자"),
        RESERVE("적립")
    }

    /**
     * 예산 사용 금액 업데이트
     */
    fun updateUsedBudget(amount: BigDecimal): BudgetItem {
        val newUsedBudget = usedBudget + amount
        val newRemainingBudget = annualBudget - newUsedBudget
        
        return this.copy(
            usedBudget = newUsedBudget,
            remainingBudget = newRemainingBudget
        )
    }

    /**
     * 예산 배정 금액 업데이트
     */
    fun updateAllocatedBudget(amount: BigDecimal): BudgetItem {
        return this.copy(allocatedBudget = amount)
    }

    /**
     * 예산 사용률 계산
     */
    fun getUsagePercentage(): BigDecimal {
        if (annualBudget == BigDecimal.ZERO) return BigDecimal.ZERO
        return usedBudget.divide(annualBudget, 4, java.math.RoundingMode.HALF_UP)
            .multiply(BigDecimal(100))
    }

    /**
     * 예산 초과 여부 확인
     */
    fun isOverBudget(): Boolean {
        return usedBudget > annualBudget
    }

    /**
     * 예산 경고 필요 여부 확인
     */
    fun needsAlert(thresholdPercentage: BigDecimal): Boolean {
        return getUsagePercentage() >= thresholdPercentage
    }

    /**
     * 월별 총 배정 금액 계산
     */
    fun getTotalMonthlyAllocation(): BigDecimal {
        return monthlyAllocations.sumOf { it.allocatedAmount }
    }

    /**
     * 월별 총 사용 금액 계산
     */
    fun getTotalMonthlyUsage(): BigDecimal {
        return monthlyAllocations.sumOf { it.usedAmount }
    }

    /**
     * 특정 월의 배정 정보 조회
     */
    fun getMonthlyAllocation(year: Int, month: Int): MonthlyBudgetAllocation? {
        return monthlyAllocations.find { 
            it.allocationYear == year && it.allocationMonth == month 
        }
    }

    /**
     * 예산 항목 비활성화
     */
    fun deactivate(): BudgetItem {
        return this.copy(isActive = false)
    }

    /**
     * 예산 항목 활성화
     */
    fun activate(): BudgetItem {
        return this.copy(isActive = true)
    }
}