package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 정기 수입 스케줄 엔티티
 * 관리비, 임대료 등의 정기적인 수입 생성을 관리
 */
@Entity
@Table(name = "recurring_income_schedules", schema = "bms")
data class RecurringIncomeSchedule(
    @Id
    @Column(name = "schedule_id")
    val scheduleId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "income_type_id", nullable = false)
    val incomeType: IncomeType,

    @Column(name = "building_id")
    val buildingId: UUID? = null,

    @Column(name = "unit_id")
    val unitId: UUID? = null,

    @Column(name = "contract_id")
    val contractId: UUID? = null,

    @Column(name = "tenant_id")
    val tenantId: UUID? = null,

    @Column(name = "schedule_name", nullable = false, length = 100)
    val scheduleName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "frequency", nullable = false, length = 20)
    val frequency: Frequency,

    @Column(name = "interval_value")
    val intervalValue: Int = 1,

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    val amount: BigDecimal,

    @Column(name = "start_date", nullable = false)
    val startDate: LocalDate,

    @Column(name = "end_date")
    val endDate: LocalDate? = null,

    @Column(name = "next_generation_date", nullable = false)
    val nextGenerationDate: LocalDate,

    @Column(name = "last_generated_date")
    val lastGeneratedDate: LocalDate? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 정기 수입 주기
     */
    enum class Frequency(val displayName: String) {
        MONTHLY("월별"),
        QUARTERLY("분기별"),
        SEMI_ANNUALLY("반기별"),
        ANNUALLY("연별")
    }

    /**
     * 스케줄 활성 상태 확인
     */
    fun isActiveSchedule(date: LocalDate = LocalDate.now()): Boolean {
        return isActive &&
                !date.isBefore(startDate) &&
                (endDate == null || !date.isAfter(endDate))
    }

    /**
     * 생성 대상 여부 확인
     */
    fun shouldGenerate(date: LocalDate = LocalDate.now()): Boolean {
        return isActiveSchedule(date) && !date.isBefore(nextGenerationDate)
    }

    /**
     * 다음 생성일 계산
     */
    fun calculateNextGenerationDate(): LocalDate {
        return when (frequency) {
            Frequency.MONTHLY -> nextGenerationDate.plusMonths(intervalValue.toLong())
            Frequency.QUARTERLY -> nextGenerationDate.plusMonths((intervalValue * 3).toLong())
            Frequency.SEMI_ANNUALLY -> nextGenerationDate.plusMonths((intervalValue * 6).toLong())
            Frequency.ANNUALLY -> nextGenerationDate.plusYears(intervalValue.toLong())
        }
    }

    /**
     * 스케줄 업데이트 (생성 후)
     */
    fun updateAfterGeneration(generationDate: LocalDate): RecurringIncomeSchedule {
        return this.copy(
            nextGenerationDate = calculateNextGenerationDate(),
            lastGeneratedDate = generationDate
        )
    }

    /**
     * 스케줄 비활성화
     */
    fun deactivate(): RecurringIncomeSchedule {
        return this.copy(isActive = false)
    }

    /**
     * 스케줄 종료
     */
    fun endSchedule(endDate: LocalDate): RecurringIncomeSchedule {
        return this.copy(endDate = endDate, isActive = false)
    }

    /**
     * 금액 변경
     */
    fun updateAmount(newAmount: BigDecimal): RecurringIncomeSchedule {
        return this.copy(amount = newAmount)
    }
}