package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 연체료 정책 엔티티
 * 수입 유형별 연체료 계산 정책을 관리
 */
@Entity
@Table(name = "late_fee_policies", schema = "bms")
data class LateFeePolicy(
    @Id
    @Column(name = "policy_id")
    val policyId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "income_type_id", nullable = false)
    val incomeType: IncomeType,

    @Column(name = "policy_name", nullable = false, length = 100)
    val policyName: String,

    @Column(name = "grace_period_days")
    val gracePeriodDays: Int = 0,

    @Enumerated(EnumType.STRING)
    @Column(name = "late_fee_type", nullable = false, length = 20)
    val lateFeeType: LateFeeType,

    @Column(name = "late_fee_rate", precision = 5, scale = 4)
    val lateFeeRate: BigDecimal? = null,

    @Column(name = "fixed_late_fee", precision = 15, scale = 2)
    val fixedLateFee: BigDecimal? = null,

    @Column(name = "max_late_fee", precision = 15, scale = 2)
    val maxLateFee: BigDecimal? = null,

    @Column(name = "compound_interest")
    val compoundInterest: Boolean = false,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @Column(name = "effective_from", nullable = false)
    val effectiveFrom: LocalDate,

    @Column(name = "effective_to")
    val effectiveTo: LocalDate? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 연체료 유형
     */
    enum class LateFeeType {
        PERCENTAGE,  // 비율 (%)
        FIXED,       // 고정 금액
        DAILY_RATE   // 일할 계산
    }

    /**
     * 정책 유효성 확인
     */
    fun isEffective(date: LocalDate = LocalDate.now()): Boolean {
        return isActive &&
                !date.isBefore(effectiveFrom) &&
                (effectiveTo == null || !date.isAfter(effectiveTo))
    }

    /**
     * 연체료 계산
     */
    fun calculateLateFee(
        outstandingAmount: BigDecimal,
        overdueDays: Int
    ): BigDecimal {
        if (overdueDays <= gracePeriodDays) {
            return BigDecimal.ZERO
        }

        val actualOverdueDays = overdueDays - gracePeriodDays
        var lateFee = BigDecimal.ZERO

        when (lateFeeType) {
            LateFeeType.PERCENTAGE -> {
                lateFeeRate?.let { rate ->
                    lateFee = outstandingAmount * rate / BigDecimal(100)
                }
            }
            LateFeeType.FIXED -> {
                fixedLateFee?.let { fee ->
                    lateFee = fee
                }
            }
            LateFeeType.DAILY_RATE -> {
                lateFeeRate?.let { rate ->
                    lateFee = outstandingAmount * rate / BigDecimal(100) * BigDecimal(actualOverdueDays)
                }
            }
        }

        // 최대 연체료 제한 적용
        maxLateFee?.let { maxFee ->
            if (lateFee > maxFee) {
                lateFee = maxFee
            }
        }

        return lateFee.coerceAtLeast(BigDecimal.ZERO)
    }

    /**
     * 정책 비활성화
     */
    fun deactivate(): LateFeePolicy {
        return this.copy(isActive = false)
    }

    /**
     * 정책 종료일 설정
     */
    fun endPolicy(endDate: LocalDate): LateFeePolicy {
        return this.copy(effectiveTo = endDate)
    }
}