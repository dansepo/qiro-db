package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예산 계획 엔티티
 * 연간 예산 수립 및 관리
 */
@Entity
@Table(
    name = "budget_plans",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "fiscal_year"])
    ]
)
data class BudgetPlan(
    @Id
    @Column(name = "budget_plan_id")
    val budgetPlanId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "plan_name", nullable = false, length = 100)
    val planName: String,

    @Column(name = "fiscal_year", nullable = false)
    val fiscalYear: Int,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDate,

    @Column(name = "total_budget", nullable = false, precision = 15, scale = 2)
    val totalBudget: BigDecimal,

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20)
    val status: Status = Status.DRAFT,

    @Column(name = "approved_by")
    val approvedBy: UUID? = null,

    @Column(name = "approved_at")
    val approvedAt: LocalDateTime? = null,

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @OneToMany(mappedBy = "budgetPlan", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val budgetItems: List<BudgetItem> = emptyList()
) {
    /**
     * 예산 계획 상태
     */
    enum class Status(val displayName: String) {
        DRAFT("초안"),
        APPROVED("승인됨"),
        ACTIVE("활성"),
        CLOSED("마감")
    }

    /**
     * 예산 승인
     */
    fun approve(approvedBy: UUID): BudgetPlan {
        return this.copy(
            status = Status.APPROVED,
            approvedBy = approvedBy,
            approvedAt = LocalDateTime.now()
        )
    }

    /**
     * 예산 활성화
     */
    fun activate(): BudgetPlan {
        if (status != Status.APPROVED) {
            throw IllegalStateException("승인된 예산만 활성화할 수 있습니다")
        }
        return this.copy(status = Status.ACTIVE)
    }

    /**
     * 예산 마감
     */
    fun close(): BudgetPlan {
        return this.copy(status = Status.CLOSED)
    }

    /**
     * 예산 수정 가능 여부
     */
    fun canModify(): Boolean {
        return status == Status.DRAFT
    }

    /**
     * 총 배정 예산 계산
     */
    fun getTotalAllocatedBudget(): BigDecimal {
        return budgetItems.sumOf { it.allocatedBudget }
    }

    /**
     * 총 사용 예산 계산
     */
    fun getTotalUsedBudget(): BigDecimal {
        return budgetItems.sumOf { it.usedBudget }
    }

    /**
     * 예산 사용률 계산
     */
    fun getBudgetUsagePercentage(): BigDecimal {
        if (totalBudget == BigDecimal.ZERO) return BigDecimal.ZERO
        return getTotalUsedBudget().divide(totalBudget, 4, java.math.RoundingMode.HALF_UP)
            .multiply(BigDecimal(100))
    }

    /**
     * 잔여 예산 계산
     */
    fun getRemainingBudget(): BigDecimal {
        return totalBudget - getTotalUsedBudget()
    }
}