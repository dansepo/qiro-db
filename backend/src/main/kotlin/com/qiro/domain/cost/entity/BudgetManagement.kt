package com.qiro.domain.cost.entity

import com.qiro.domain.cost.dto.BudgetStatus
import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 예산 관리 엔티티
 */
@Entity
@Table(
    name = "budget_management",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(name = "uk_budget_name_year", columnNames = ["company_id", "budget_name", "budget_year"])
    ]
)
data class BudgetManagement(
    @Id
    @Column(name = "budget_id")
    val budgetId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "budget_name", nullable = false, length = 100)
    val budgetName: String,

    @Column(name = "budget_year", nullable = false)
    val budgetYear: Int,

    @Column(name = "budget_category", nullable = false, length = 50)
    val budgetCategory: String,

    @Column(name = "allocated_amount", nullable = false, precision = 12, scale = 2)
    val allocatedAmount: BigDecimal,

    @Column(name = "spent_amount", precision = 12, scale = 2)
    val spentAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "committed_amount", precision = 12, scale = 2)
    val committedAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "available_amount", precision = 12, scale = 2)
    val availableAmount: BigDecimal = BigDecimal.ZERO,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date", nullable = false)
    val endDate: LocalDate,

    @Enumerated(EnumType.STRING)
    @Column(name = "budget_status", length = 20)
    val budgetStatus: BudgetStatus = BudgetStatus.ACTIVE,

    @Column(name = "warning_threshold", precision = 5, scale = 2)
    val warningThreshold: BigDecimal = BigDecimal("80.00"),

    @Column(name = "critical_threshold", precision = 5, scale = 2)
    val criticalThreshold: BigDecimal = BigDecimal("95.00"),

    @Column(name = "approved_by")
    val approvedBy: UUID? = null,

    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    @UpdateTimestamp
    @Column(name = "updated_at")
    val updatedAt: LocalDateTime? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 예산 승인
     */
    fun approve(approvedBy: UUID): BudgetManagement {
        return this.copy(
            approvedBy = approvedBy,
            approvalDate = LocalDateTime.now(),
            updatedBy = approvedBy
        )
    }

    /**
     * 예산 정보 업데이트
     */
    fun update(
        budgetName: String? = null,
        allocatedAmount: BigDecimal? = null,
        startDate: LocalDate? = null,
        endDate: LocalDate? = null,
        warningThreshold: BigDecimal? = null,
        criticalThreshold: BigDecimal? = null,
        budgetStatus: BudgetStatus? = null,
        updatedBy: UUID
    ): BudgetManagement {
        val newAllocatedAmount = allocatedAmount ?: this.allocatedAmount
        val newAvailableAmount = newAllocatedAmount - this.spentAmount - this.committedAmount
        
        return this.copy(
            budgetName = budgetName ?: this.budgetName,
            allocatedAmount = newAllocatedAmount,
            availableAmount = newAvailableAmount,
            startDate = startDate ?: this.startDate,
            endDate = endDate ?: this.endDate,
            warningThreshold = warningThreshold ?: this.warningThreshold,
            criticalThreshold = criticalThreshold ?: this.criticalThreshold,
            budgetStatus = budgetStatus ?: this.budgetStatus,
            updatedBy = updatedBy
        )
    }

    /**
     * 예산 사용량 업데이트
     */
    fun updateSpentAmount(additionalAmount: BigDecimal): BudgetManagement {
        val newSpentAmount = this.spentAmount + additionalAmount
        val newAvailableAmount = this.allocatedAmount - newSpentAmount - this.committedAmount
        
        return this.copy(
            spentAmount = newSpentAmount,
            availableAmount = newAvailableAmount
        )
    }

    /**
     * 약정 금액 업데이트
     */
    fun updateCommittedAmount(additionalAmount: BigDecimal): BudgetManagement {
        val newCommittedAmount = this.committedAmount + additionalAmount
        val newAvailableAmount = this.allocatedAmount - this.spentAmount - newCommittedAmount
        
        return this.copy(
            committedAmount = newCommittedAmount,
            availableAmount = newAvailableAmount
        )
    }

    /**
     * 사용률 계산
     */
    fun getUtilizationPercentage(): BigDecimal {
        if (allocatedAmount == BigDecimal.ZERO) return BigDecimal.ZERO
        return (spentAmount.divide(allocatedAmount, 4, BigDecimal.ROUND_HALF_UP))
            .multiply(BigDecimal("100"))
    }

    /**
     * 약정률 계산 (사용량 + 약정량)
     */
    fun getCommitmentPercentage(): BigDecimal {
        if (allocatedAmount == BigDecimal.ZERO) return BigDecimal.ZERO
        return ((spentAmount + committedAmount).divide(allocatedAmount, 4, BigDecimal.ROUND_HALF_UP))
            .multiply(BigDecimal("100"))
    }

    /**
     * 예산 상태 레벨 확인
     */
    fun getStatusLevel(): String {
        val utilizationPercentage = getUtilizationPercentage()
        return when {
            utilizationPercentage >= criticalThreshold -> "CRITICAL"
            utilizationPercentage >= warningThreshold -> "WARNING"
            else -> "NORMAL"
        }
    }

    /**
     * 예산 기간 상태 확인
     */
    fun getPeriodStatus(): String {
        val currentDate = LocalDate.now()
        return when {
            currentDate < startDate -> "FUTURE"
            currentDate > endDate -> "EXPIRED"
            else -> "ACTIVE"
        }
    }

    /**
     * 승인 여부 확인
     */
    fun isApproved(): Boolean = approvedBy != null && approvalDate != null

    /**
     * 예산 초과 여부 확인
     */
    fun isExceeded(): Boolean = spentAmount > allocatedAmount

    /**
     * 경고 상태 여부 확인
     */
    fun isWarningLevel(): Boolean = getUtilizationPercentage() >= warningThreshold

    /**
     * 위험 상태 여부 확인
     */
    fun isCriticalLevel(): Boolean = getUtilizationPercentage() >= criticalThreshold
}