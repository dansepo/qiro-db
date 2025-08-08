package com.qiro.domain.cost.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 예산 관리 엔티티
 * 시설 관리 예산 계획 및 실행 추적
 */
@Entity
@Table(
    name = "cost_budgets",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_cost_budgets_code",
            columnNames = ["company_id", "budget_code"]
        )
    ],
    indexes = [
        Index(name = "idx_cost_budgets_company_id", columnList = "company_id"),
        Index(name = "idx_cost_budgets_category", columnList = "budget_category"),
        Index(name = "idx_cost_budgets_period", columnList = "budget_period"),
        Index(name = "idx_cost_budgets_status", columnList = "budget_status"),
        Index(name = "idx_cost_budgets_date_range", columnList = "start_date, end_date")
    ]
)
class CostBudget : BaseEntity() {
    
    @Id
    @Column(name = "budget_id")
    val budgetId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @Column(name = "budget_code", nullable = false, length = 50)
    lateinit var budgetCode: String
    
    @Column(name = "budget_name", nullable = false, length = 200)
    lateinit var budgetName: String
    
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "budget_category", nullable = false, length = 50)
    lateinit var budgetCategory: BudgetCategory
    
    @Enumerated(EnumType.STRING)
    @Column(name = "budget_period", nullable = false, length = 20)
    lateinit var budgetPeriod: BudgetPeriod
    
    @Column(name = "fiscal_year", nullable = false)
    var fiscalYear: Int = LocalDate.now().year
    
    @Column(name = "start_date", nullable = false)
    var startDate: LocalDate = LocalDate.now()
    
    @Column(name = "end_date", nullable = false)
    var endDate: LocalDate = LocalDate.now().plusYears(1)
    
    @Column(name = "planned_amount", nullable = false, precision = 15, scale = 2)
    var plannedAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "allocated_amount", precision = 15, scale = 2)
    var allocatedAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "committed_amount", precision = 15, scale = 2)
    var committedAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "spent_amount", precision = 15, scale = 2)
    var spentAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "remaining_amount", precision = 15, scale = 2)
    var remainingAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "utilization_rate", precision = 5, scale = 2)
    var utilizationRate: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "variance_amount", precision = 15, scale = 2)
    var varianceAmount: BigDecimal = BigDecimal.ZERO
    
    @Column(name = "variance_percentage", precision = 5, scale = 2)
    var variancePercentage: BigDecimal = BigDecimal.ZERO
    
    @Enumerated(EnumType.STRING)
    @Column(name = "budget_status", nullable = false, length = 20)
    var budgetStatus: BudgetStatus = BudgetStatus.DRAFT
    
    @Column(name = "alert_threshold", precision = 5, scale = 2)
    var alertThreshold: BigDecimal = BigDecimal.valueOf(80) // 80% 기본값
    
    @Column(name = "critical_threshold", precision = 5, scale = 2)
    var criticalThreshold: BigDecimal = BigDecimal.valueOf(95) // 95% 기본값
    
    @Column(name = "auto_approval_limit", precision = 12, scale = 2)
    var autoApprovalLimit: BigDecimal = BigDecimal.ZERO
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "budget_owner")
    var budgetOwner: User? = null
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approved_by")
    var approvedBy: User? = null
    
    @Column(name = "approval_date")
    var approvalDate: LocalDateTime? = null
    
    @Column(name = "approval_notes", columnDefinition = "TEXT")
    var approvalNotes: String? = null
    
    @Column(name = "last_review_date")
    var lastReviewDate: LocalDate? = null
    
    @Column(name = "next_review_date")
    var nextReviewDate: LocalDate? = null
    
    @Column(name = "review_frequency", length = 20)
    var reviewFrequency: String = "MONTHLY"
    
    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null
    
    /**
     * 예산 분류 열거형
     */
    enum class BudgetCategory {
        MAINTENANCE,        // 유지보수
        REPAIR,            // 수리
        EMERGENCY,         // 응급
        PREVENTIVE,        // 예방정비
        IMPROVEMENT,       // 개선
        REPLACEMENT,       // 교체
        UTILITIES,         // 유틸리티
        CONTRACTOR,        // 외주
        MATERIALS,         // 자재
        EQUIPMENT,         // 장비
        LABOR,             // 인건비
        OVERHEAD,          // 간접비
        CONTINGENCY,       // 비상예비비
        OTHER              // 기타
    }
    
    /**
     * 예산 기간 열거형
     */
    enum class BudgetPeriod {
        MONTHLY,           // 월별
        QUARTERLY,         // 분기별
        SEMI_ANNUAL,       // 반기별
        ANNUAL,            // 연간
        PROJECT            // 프로젝트별
    }
    
    /**
     * 예산 상태 열거형
     */
    enum class BudgetStatus {
        DRAFT,             // 초안
        SUBMITTED,         // 제출됨
        APPROVED,          // 승인됨
        ACTIVE,            // 활성
        SUSPENDED,         // 중단됨
        CLOSED,            // 종료됨
        CANCELLED          // 취소됨
    }
    
    /**
     * 예산 사용률 계산
     */
    fun calculateUtilizationRate() {
        if (plannedAmount > BigDecimal.ZERO) {
            this.utilizationRate = spentAmount.divide(plannedAmount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        }
    }
    
    /**
     * 잔여 예산 계산
     */
    fun calculateRemainingAmount() {
        this.remainingAmount = plannedAmount.subtract(spentAmount).subtract(committedAmount)
    }
    
    /**
     * 예산 차이 계산
     */
    fun calculateVariance() {
        this.varianceAmount = spentAmount.subtract(plannedAmount)
        if (plannedAmount > BigDecimal.ZERO) {
            this.variancePercentage = varianceAmount.divide(plannedAmount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        }
    }
    
    /**
     * 예산 상태 업데이트
     */
    fun updateBudgetMetrics() {
        calculateRemainingAmount()
        calculateUtilizationRate()
        calculateVariance()
    }
    
    /**
     * 경고 임계값 초과 여부 확인
     */
    fun isAlertThresholdExceeded(): Boolean {
        return utilizationRate >= alertThreshold
    }
    
    /**
     * 위험 임계값 초과 여부 확인
     */
    fun isCriticalThresholdExceeded(): Boolean {
        return utilizationRate >= criticalThreshold
    }
    
    /**
     * 예산 초과 여부 확인
     */
    fun isOverBudget(): Boolean {
        return spentAmount > plannedAmount
    }
    
    /**
     * 예산 승인
     */
    fun approve(approver: User, notes: String? = null) {
        this.budgetStatus = BudgetStatus.APPROVED
        this.approvedBy = approver
        this.approvalDate = LocalDateTime.now()
        this.approvalNotes = notes
    }
    
    /**
     * 예산 활성화
     */
    fun activate() {
        require(budgetStatus == BudgetStatus.APPROVED) { "승인된 예산만 활성화할 수 있습니다." }
        this.budgetStatus = BudgetStatus.ACTIVE
    }
    
    /**
     * 예산 종료
     */
    fun close(reason: String? = null) {
        this.budgetStatus = BudgetStatus.CLOSED
        this.notes = if (notes.isNullOrBlank()) reason else "$notes\n종료 사유: $reason"
    }
    
    /**
     * 자동 승인 가능 여부 확인
     */
    fun canAutoApprove(amount: BigDecimal): Boolean {
        return amount <= autoApprovalLimit && remainingAmount >= amount
    }
    
    /**
     * 예산 할당
     */
    fun allocate(amount: BigDecimal): Boolean {
        return if (remainingAmount >= amount) {
            this.allocatedAmount = allocatedAmount.add(amount)
            updateBudgetMetrics()
            true
        } else {
            false
        }
    }
    
    /**
     * 예산 사용
     */
    fun spend(amount: BigDecimal) {
        this.spentAmount = spentAmount.add(amount)
        updateBudgetMetrics()
    }
    
    /**
     * 예산 약정
     */
    fun commit(amount: BigDecimal): Boolean {
        return if (remainingAmount >= amount) {
            this.committedAmount = committedAmount.add(amount)
            updateBudgetMetrics()
            true
        } else {
            false
        }
    }
    
    /**
     * 다음 검토 일자 계산
     */
    fun calculateNextReviewDate() {
        this.nextReviewDate = when (reviewFrequency) {
            "WEEKLY" -> LocalDate.now().plusWeeks(1)
            "MONTHLY" -> LocalDate.now().plusMonths(1)
            "QUARTERLY" -> LocalDate.now().plusMonths(3)
            "SEMI_ANNUAL" -> LocalDate.now().plusMonths(6)
            "ANNUAL" -> LocalDate.now().plusYears(1)
            else -> LocalDate.now().plusMonths(1)
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is CostBudget) return false
        return budgetId == other.budgetId
    }
    
    override fun hashCode(): Int {
        return budgetId.hashCode()
    }
    
    override fun toString(): String {
        return "CostBudget(budgetId=$budgetId, budgetCode='$budgetCode', budgetName='$budgetName', plannedAmount=$plannedAmount, spentAmount=$spentAmount)"
    }
}