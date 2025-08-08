package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 재무제표 엔티티
 * 손익계산서, 대차대조표, 현금흐름표 생성 이력 관리
 */
@Entity
@Table(name = "financial_statements", schema = "bms")
data class FinancialStatement(
    @Id
    @Column(name = "statement_id")
    val statementId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    val template: FinancialStatementTemplate? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "statement_type", nullable = false, length = 20)
    val statementType: StatementType,

    @Column(name = "period_start", nullable = false)
    val periodStart: LocalDate,

    @Column(name = "period_end", nullable = false)
    val periodEnd: LocalDate,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "statement_data", nullable = false, columnDefinition = "jsonb")
    val statementData: Map<String, Any>,

    @Column(name = "generated_by", nullable = false)
    val generatedBy: UUID,

    @CreationTimestamp
    @Column(name = "generated_at", nullable = false, updatable = false)
    val generatedAt: LocalDateTime = LocalDateTime.now(),

    @OneToMany(mappedBy = "statement", cascade = [CascadeType.ALL], fetch = FetchType.LAZY)
    val financialRatios: List<FinancialRatio> = emptyList()
) {
    /**
     * 재무제표 유형
     */
    enum class StatementType(val displayName: String, val description: String) {
        INCOME_STATEMENT("손익계산서", "일정 기간 동안의 수익과 비용을 나타내는 재무제표"),
        BALANCE_SHEET("대차대조표", "특정 시점의 자산, 부채, 자본을 나타내는 재무제표"),
        CASH_FLOW("현금흐름표", "일정 기간 동안의 현금 유입과 유출을 나타내는 재무제표")
    }

    /**
     * 재무제표 기간 유효성 검증
     */
    fun isValidPeriod(): Boolean {
        return periodStart.isBefore(periodEnd) || periodStart.isEqual(periodEnd)
    }

    /**
     * 재무제표 데이터에서 특정 항목 값 조회
     */
    fun getStatementValue(key: String): Any? {
        return statementData[key]
    }

    /**
     * 재무제표 데이터에서 숫자 값 조회
     */
    fun getNumericValue(key: String): Double? {
        return when (val value = statementData[key]) {
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        }
    }

    /**
     * 기간 길이 계산 (일 단위)
     */
    fun getPeriodDays(): Long {
        return java.time.temporal.ChronoUnit.DAYS.between(periodStart, periodEnd) + 1
    }

    /**
     * 월별 재무제표 여부 확인
     */
    fun isMonthlyStatement(): Boolean {
        return periodStart.dayOfMonth == 1 && 
               periodEnd == periodStart.plusMonths(1).minusDays(1)
    }

    /**
     * 분기별 재무제표 여부 확인
     */
    fun isQuarterlyStatement(): Boolean {
        return getPeriodDays() in 89..92 && // 분기는 약 90일
               periodStart.dayOfMonth == 1
    }

    /**
     * 연간 재무제표 여부 확인
     */
    fun isAnnualStatement(): Boolean {
        return periodStart.dayOfYear == 1 && 
               periodEnd.dayOfYear == periodEnd.lengthOfYear()
    }

    /**
     * 재무제표 요약 정보 생성
     */
    fun generateSummary(): FinancialStatementSummary {
        return when (statementType) {
            StatementType.INCOME_STATEMENT -> generateIncomeStatementSummary()
            StatementType.BALANCE_SHEET -> generateBalanceSheetSummary()
            StatementType.CASH_FLOW -> generateCashFlowSummary()
        }
    }

    private fun generateIncomeStatementSummary(): FinancialStatementSummary {
        val totalRevenue = getNumericValue("total_revenue") ?: 0.0
        val totalExpenses = getNumericValue("total_expenses") ?: 0.0
        val netIncome = totalRevenue - totalExpenses

        return FinancialStatementSummary(
            statementType = statementType,
            period = "${periodStart} ~ ${periodEnd}",
            keyMetrics = mapOf(
                "총수익" to totalRevenue,
                "총비용" to totalExpenses,
                "순이익" to netIncome,
                "수익률" to if (totalRevenue > 0) (netIncome / totalRevenue * 100) else 0.0
            )
        )
    }

    private fun generateBalanceSheetSummary(): FinancialStatementSummary {
        val totalAssets = getNumericValue("total_assets") ?: 0.0
        val totalLiabilities = getNumericValue("total_liabilities") ?: 0.0
        val totalEquity = getNumericValue("total_equity") ?: 0.0

        return FinancialStatementSummary(
            statementType = statementType,
            period = periodEnd.toString(),
            keyMetrics = mapOf(
                "총자산" to totalAssets,
                "총부채" to totalLiabilities,
                "총자본" to totalEquity,
                "부채비율" to if (totalAssets > 0) (totalLiabilities / totalAssets * 100) else 0.0
            )
        )
    }

    private fun generateCashFlowSummary(): FinancialStatementSummary {
        val operatingCashFlow = getNumericValue("operating_cash_flow") ?: 0.0
        val investingCashFlow = getNumericValue("investing_cash_flow") ?: 0.0
        val financingCashFlow = getNumericValue("financing_cash_flow") ?: 0.0
        val netCashFlow = operatingCashFlow + investingCashFlow + financingCashFlow

        return FinancialStatementSummary(
            statementType = statementType,
            period = "${periodStart} ~ ${periodEnd}",
            keyMetrics = mapOf(
                "영업현금흐름" to operatingCashFlow,
                "투자현금흐름" to investingCashFlow,
                "재무현금흐름" to financingCashFlow,
                "순현금흐름" to netCashFlow
            )
        )
    }
}

/**
 * 재무제표 요약 정보
 */
data class FinancialStatementSummary(
    val statementType: FinancialStatement.StatementType,
    val period: String,
    val keyMetrics: Map<String, Double>
)