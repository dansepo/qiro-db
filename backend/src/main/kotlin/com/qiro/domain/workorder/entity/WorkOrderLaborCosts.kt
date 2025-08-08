package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 인력 비용 집계 엔티티
 * 인력 비용의 집계 및 분석
 */
@Entity
@Table(
    name = "work_order_labor_costs",
    schema = "bms",
    indexes = [
        Index(name = "idx_labor_costs_work_order", columnList = "workOrderId"),
        Index(name = "idx_labor_costs_date", columnList = "costDate"),
        Index(name = "idx_labor_costs_period", columnList = "costPeriod"),
        Index(name = "idx_labor_costs_status", columnList = "calculationStatus")
    ],
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_labor_costs_work_order_date",
            columnNames = ["workOrderId", "costDate", "costPeriod"]
        )
    ]
)
data class WorkOrderLaborCosts(
    @Id
    @Column(name = "labor_cost_id")
    val laborCostId: UUID = UUID.randomUUID(),
    
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,
    
    @Column(name = "work_order_id", nullable = false)
    val workOrderId: UUID,
    
    // 집계 기간
    @Column(name = "cost_date", nullable = false)
    val costDate: LocalDate,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "cost_period", length = 20)
    val costPeriod: CostPeriod = CostPeriod.DAILY,
    
    // 인력 비용 집계
    @Column(name = "total_regular_hours", precision = 10, scale = 2)
    val totalRegularHours: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_overtime_hours", precision = 10, scale = 2)
    val totalOvertimeHours: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_work_hours", precision = 10, scale = 2)
    val totalWorkHours: BigDecimal = BigDecimal.ZERO,
    
    // 비용 집계
    @Column(name = "total_regular_cost", precision = 12, scale = 2)
    val totalRegularCost: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_overtime_cost", precision = 12, scale = 2)
    val totalOvertimeCost: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_labor_cost", precision = 12, scale = 2)
    val totalLaborCost: BigDecimal = BigDecimal.ZERO,
    
    // 인력 수
    @Column(name = "worker_count")
    val workerCount: Int = 0,
    
    @Column(name = "contractor_count")
    val contractorCount: Int = 0,
    
    // 평균 비율
    @Column(name = "average_hourly_rate", precision = 10, scale = 2)
    val averageHourlyRate: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "average_productivity", precision = 3, scale = 1)
    val averageProductivity: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "average_quality_score", precision = 3, scale = 1)
    val averageQualityScore: BigDecimal = BigDecimal.ZERO,
    
    // 비용 분류
    @Column(name = "internal_labor_cost", precision = 12, scale = 2)
    val internalLaborCost: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "external_labor_cost", precision = 12, scale = 2)
    val externalLaborCost: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "contractor_cost", precision = 12, scale = 2)
    val contractorCost: BigDecimal = BigDecimal.ZERO,
    
    // 상태
    @Enumerated(EnumType.STRING)
    @Column(name = "calculation_status", length = 20)
    val calculationStatus: CalculationStatus = CalculationStatus.CALCULATED,
    
    @Column(name = "last_updated")
    val lastUpdated: LocalDateTime = LocalDateTime.now()
    
) : BaseEntity() {
    
    /**
     * 비용 집계 기간 열거형
     */
    enum class CostPeriod {
        DAILY,      // 일별
        WEEKLY,     // 주별
        MONTHLY,    // 월별
        PROJECT     // 프로젝트별
    }
    
    /**
     * 계산 상태 열거형
     */
    enum class CalculationStatus {
        CALCULATED,     // 계산됨
        APPROVED,       // 승인됨
        ADJUSTED,       // 조정됨
        FINALIZED       // 확정됨
    }
    
    /**
     * 총 인력 수 계산
     */
    fun getTotalWorkerCount(): Int {
        return workerCount + contractorCount
    }
    
    /**
     * 초과 근무 비율 계산
     */
    fun getOvertimePercentage(): BigDecimal {
        return if (totalWorkHours > BigDecimal.ZERO) {
            totalOvertimeHours.divide(totalWorkHours, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 시간당 평균 비용 계산
     */
    fun getAverageCostPerHour(): BigDecimal {
        return if (totalWorkHours > BigDecimal.ZERO) {
            totalLaborCost.divide(totalWorkHours, 2, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 내부 인력 비용 비율 계산
     */
    fun getInternalCostPercentage(): BigDecimal {
        return if (totalLaborCost > BigDecimal.ZERO) {
            internalLaborCost.divide(totalLaborCost, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 외부 인력 비용 비율 계산
     */
    fun getExternalCostPercentage(): BigDecimal {
        return if (totalLaborCost > BigDecimal.ZERO) {
            val externalTotal = externalLaborCost.add(contractorCost)
            externalTotal.divide(totalLaborCost, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 비용 효율성 지수 계산 (품질 점수 대비 비용)
     */
    fun getCostEfficiencyIndex(): BigDecimal {
        return if (averageQualityScore > BigDecimal.ZERO && totalLaborCost > BigDecimal.ZERO) {
            averageQualityScore.divide(
                totalLaborCost.divide(BigDecimal.valueOf(1000), 2, java.math.RoundingMode.HALF_UP),
                2, java.math.RoundingMode.HALF_UP
            )
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 집계 데이터 유효성 검증
     */
    fun validateAggregation(): Boolean {
        return totalWorkHours == totalRegularHours.add(totalOvertimeHours) &&
                totalLaborCost == totalRegularCost.add(totalOvertimeCost) &&
                totalLaborCost == internalLaborCost.add(externalLaborCost).add(contractorCost)
    }
}