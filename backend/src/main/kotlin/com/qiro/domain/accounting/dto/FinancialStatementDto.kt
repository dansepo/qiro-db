package com.qiro.domain.accounting.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 재무제표 DTO 클래스들
 * 손익계산서, 대차대조표, 현금흐름표 관련 데이터
 */

// 재무제표 생성 요청
data class GenerateFinancialStatementRequest(
    val statementType: String, // INCOME_STATEMENT, BALANCE_SHEET, CASH_FLOW
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val templateId: UUID? = null
)

// 재무제표 응답
data class FinancialStatementResponse(
    val id: UUID,
    val statementType: String,
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val generatedAt: String,
    val status: String,
    val data: Map<String, Any>,
    val summary: FinancialSummaryData
)

// 손익계산서 응답
data class IncomeStatementResponse(
    val id: UUID,
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val revenue: RevenueData,
    val expenses: ExpenseData,
    val netIncome: BigDecimal,
    val profitMargin: BigDecimal,
    val generatedAt: String
)

data class RevenueData(
    val totalRevenue: BigDecimal,
    val operatingRevenue: BigDecimal,
    val nonOperatingRevenue: BigDecimal,
    val revenueBreakdown: List<AccountLineItem>
)

data class ExpenseData(
    val totalExpenses: BigDecimal,
    val operatingExpenses: BigDecimal,
    val nonOperatingExpenses: BigDecimal,
    val expenseBreakdown: List<AccountLineItem>
)

data class AccountLineItem(
    val accountCode: String,
    val accountName: String,
    val amount: BigDecimal,
    val percentage: BigDecimal
)

// 대차대조표 응답
data class BalanceSheetResponse(
    val id: UUID,
    val asOfDate: LocalDate,
    val assets: AssetData,
    val liabilities: LiabilityData,
    val equity: EquityData,
    val totalAssets: BigDecimal,
    val totalLiabilitiesAndEquity: BigDecimal,
    val isBalanced: Boolean,
    val generatedAt: String
)

data class AssetData(
    val currentAssets: BigDecimal,
    val nonCurrentAssets: BigDecimal,
    val totalAssets: BigDecimal,
    val assetBreakdown: List<AccountLineItem>
)

data class LiabilityData(
    val currentLiabilities: BigDecimal,
    val nonCurrentLiabilities: BigDecimal,
    val totalLiabilities: BigDecimal,
    val liabilityBreakdown: List<AccountLineItem>
)

data class EquityData(
    val paidInCapital: BigDecimal,
    val retainedEarnings: BigDecimal,
    val totalEquity: BigDecimal,
    val equityBreakdown: List<AccountLineItem>
)

// 현금흐름표 응답
data class CashFlowStatementResponse(
    val id: UUID,
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val operatingActivities: CashFlowSection,
    val investingActivities: CashFlowSection,
    val financingActivities: CashFlowSection,
    val netCashFlow: BigDecimal,
    val beginningCash: BigDecimal,
    val endingCash: BigDecimal,
    val generatedAt: String
)

data class CashFlowSection(
    val sectionName: String,
    val netCashFlow: BigDecimal,
    val items: List<CashFlowItem>
)

data class CashFlowItem(
    val description: String,
    val amount: BigDecimal,
    val isInflow: Boolean
)

// 재무비율 분석 응답
data class FinancialRatiosResponse(
    val companyId: UUID,
    val periodStart: LocalDate,
    val periodEnd: LocalDate,
    val profitabilityRatios: ProfitabilityRatios,
    val liquidityRatios: LiquidityRatios,
    val leverageRatios: LeverageRatios,
    val efficiencyRatios: EfficiencyRatios,
    val marketRatios: MarketRatios? = null
)

data class ProfitabilityRatios(
    val grossProfitMargin: BigDecimal,
    val operatingProfitMargin: BigDecimal,
    val netProfitMargin: BigDecimal,
    val returnOnAssets: BigDecimal,
    val returnOnEquity: BigDecimal
)

data class LiquidityRatios(
    val currentRatio: BigDecimal,
    val quickRatio: BigDecimal,
    val cashRatio: BigDecimal,
    val workingCapital: BigDecimal
)

data class LeverageRatios(
    val debtToEquityRatio: BigDecimal,
    val debtToAssetsRatio: BigDecimal,
    val equityMultiplier: BigDecimal,
    val interestCoverageRatio: BigDecimal
)

data class EfficiencyRatios(
    val assetTurnover: BigDecimal,
    val receivablesTurnover: BigDecimal,
    val inventoryTurnover: BigDecimal,
    val payablesTurnover: BigDecimal
)

data class MarketRatios(
    val priceToEarningsRatio: BigDecimal? = null,
    val priceToBookRatio: BigDecimal? = null,
    val dividendYield: BigDecimal? = null
)

// 재무제표 템플릿 응답
data class FinancialStatementTemplateResponse(
    val id: UUID,
    val templateName: String,
    val statementType: String,
    val structure: Map<String, Any>,
    val isDefault: Boolean,
    val isActive: Boolean
)

// 재무제표 비교 분석 응답
data class FinancialComparisonResponse(
    val currentPeriod: FinancialStatementResponse,
    val previousPeriod: FinancialStatementResponse,
    val comparison: ComparisonData
)

data class ComparisonData(
    val revenueGrowth: BigDecimal,
    val expenseGrowth: BigDecimal,
    val profitGrowth: BigDecimal,
    val assetGrowth: BigDecimal,
    val liabilityGrowth: BigDecimal,
    val equityGrowth: BigDecimal,
    val keyInsights: List<String>
)

// 재무제표 요약 데이터
data class FinancialSummaryData(
    val totalRevenue: BigDecimal,
    val totalExpenses: BigDecimal,
    val netIncome: BigDecimal,
    val totalAssets: BigDecimal,
    val totalLiabilities: BigDecimal,
    val totalEquity: BigDecimal,
    val profitMargin: BigDecimal,
    val returnOnAssets: BigDecimal,
    val returnOnEquity: BigDecimal
)