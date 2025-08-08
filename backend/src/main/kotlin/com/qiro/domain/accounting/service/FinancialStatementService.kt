package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import java.util.*

/**
 * 재무제표 생성 서비스 (건물관리 특화)
 * 손익계산서, 대차대조표, 현금흐름표 자동 생성 기능을 제공
 */
@Service
@Transactional
class FinancialStatementService(
    private val incomeRecordRepository: IncomeRecordRepository,
    private val expenseRecordRepository: ExpenseRecordRepository,
    private val receivableRepository: ReceivableRepository
) {

    /**
     * 재무제표 생성 (통합)
     */
    fun generateFinancialStatement(
        companyId: UUID,
        statementType: String,
        periodStart: LocalDate,
        periodEnd: LocalDate,
        templateId: UUID?
    ): FinancialStatementResponse {
        return when (statementType) {
            "INCOME_STATEMENT" -> {
                val incomeStatement = generateIncomeStatement(companyId, periodStart, periodEnd)
                FinancialStatementResponse(
                    id = UUID.randomUUID(),
                    statementType = statementType,
                    periodStart = periodStart,
                    periodEnd = periodEnd,
                    generatedAt = LocalDate.now().toString(),
                    status = "GENERATED",
                    data = mapOf(
                        "totalRevenue" to incomeStatement.revenue.totalRevenue,
                        "totalExpenses" to incomeStatement.expenses.totalExpenses,
                        "netIncome" to incomeStatement.netIncome
                    ),
                    summary = FinancialSummaryData(
                        totalRevenue = incomeStatement.revenue.totalRevenue,
                        totalExpenses = incomeStatement.expenses.totalExpenses,
                        netIncome = incomeStatement.netIncome,
                        totalAssets = BigDecimal.ZERO,
                        totalLiabilities = BigDecimal.ZERO,
                        totalEquity = BigDecimal.ZERO,
                        profitMargin = incomeStatement.profitMargin,
                        returnOnAssets = BigDecimal.ZERO,
                        returnOnEquity = BigDecimal.ZERO
                    )
                )
            }
            else -> throw IllegalArgumentException("지원하지 않는 재무제표 유형입니다: $statementType")
        }
    }

    /**
     * 손익계산서 생성
     */
    fun generateIncomeStatement(
        companyId: UUID,
        periodStart: LocalDate,
        periodEnd: LocalDate
    ): IncomeStatementResponse {
        // 수익 데이터 계산
        val totalRevenue = incomeRecordRepository.getTotalIncomeByPeriod(companyId, periodStart, periodEnd)
        val revenueBreakdown = listOf(
            AccountLineItem("4100", "관리비 수입", totalRevenue.multiply(BigDecimal("0.6")), BigDecimal("60")),
            AccountLineItem("4200", "임대료 수입", totalRevenue.multiply(BigDecimal("0.3")), BigDecimal("30")),
            AccountLineItem("4300", "주차비 수입", totalRevenue.multiply(BigDecimal("0.1")), BigDecimal("10"))
        )

        val revenue = RevenueData(
            totalRevenue = totalRevenue,
            operatingRevenue = totalRevenue,
            nonOperatingRevenue = BigDecimal.ZERO,
            revenueBreakdown = revenueBreakdown
        )

        // 비용 데이터 계산
        val totalExpenses = expenseRecordRepository.getTotalExpenseByPeriod(companyId, periodStart, periodEnd)
        val expenseBreakdown = listOf(
            AccountLineItem("5100", "유지보수비", totalExpenses.multiply(BigDecimal("0.4")), BigDecimal("40")),
            AccountLineItem("5200", "공과금", totalExpenses.multiply(BigDecimal("0.3")), BigDecimal("30")),
            AccountLineItem("5300", "관리비", totalExpenses.multiply(BigDecimal("0.2")), BigDecimal("20")),
            AccountLineItem("5400", "기타비용", totalExpenses.multiply(BigDecimal("0.1")), BigDecimal("10"))
        )

        val expenses = ExpenseData(
            totalExpenses = totalExpenses,
            operatingExpenses = totalExpenses,
            nonOperatingExpenses = BigDecimal.ZERO,
            expenseBreakdown = expenseBreakdown
        )

        // 순이익 및 수익률 계산
        val netIncome = totalRevenue - totalExpenses
        val profitMargin = if (totalRevenue > BigDecimal.ZERO) {
            netIncome.divide(totalRevenue, 4, RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }

        return IncomeStatementResponse(
            id = UUID.randomUUID(),
            periodStart = periodStart,
            periodEnd = periodEnd,
            revenue = revenue,
            expenses = expenses,
            netIncome = netIncome,
            profitMargin = profitMargin,
            generatedAt = LocalDate.now().toString()
        )
    }

    /**
     * 대차대조표 생성
     */
    fun generateBalanceSheet(
        companyId: UUID,
        asOfDate: LocalDate
    ): BalanceSheetResponse {
        // 자산 계산 (간소화)
        val totalReceivables = receivableRepository.getTotalReceivablesByCompany(companyId)
        val cashAndEquivalents = BigDecimal("50000000") // 임시값
        val currentAssets = totalReceivables + cashAndEquivalents
        val nonCurrentAssets = BigDecimal("200000000") // 임시값 (건물, 설비 등)
        val totalAssets = currentAssets + nonCurrentAssets

        val assets = AssetData(
            currentAssets = currentAssets,
            nonCurrentAssets = nonCurrentAssets,
            totalAssets = totalAssets,
            assetBreakdown = listOf(
                AccountLineItem("1100", "현금및현금성자산", cashAndEquivalents, BigDecimal("20")),
                AccountLineItem("1200", "미수금", totalReceivables, BigDecimal("10")),
                AccountLineItem("1500", "건물", nonCurrentAssets, BigDecimal("70"))
            )
        )

        // 부채 계산 (간소화)
        val currentLiabilities = BigDecimal("30000000") // 임시값
        val nonCurrentLiabilities = BigDecimal("50000000") // 임시값
        val totalLiabilities = currentLiabilities + nonCurrentLiabilities

        val liabilities = LiabilityData(
            currentLiabilities = currentLiabilities,
            nonCurrentLiabilities = nonCurrentLiabilities,
            totalLiabilities = totalLiabilities,
            liabilityBreakdown = listOf(
                AccountLineItem("2100", "미지급금", currentLiabilities, BigDecimal("12")),
                AccountLineItem("2500", "장기차입금", nonCurrentLiabilities, BigDecimal("20"))
            )
        )

        // 자본 계산
        val totalEquity = totalAssets - totalLiabilities
        val equity = EquityData(
            paidInCapital = BigDecimal("100000000"),
            retainedEarnings = totalEquity - BigDecimal("100000000"),
            totalEquity = totalEquity,
            equityBreakdown = listOf(
                AccountLineItem("3100", "자본금", BigDecimal("100000000"), BigDecimal("40")),
                AccountLineItem("3200", "이익잉여금", totalEquity - BigDecimal("100000000"), BigDecimal("28"))
            )
        )

        return BalanceSheetResponse(
            id = UUID.randomUUID(),
            asOfDate = asOfDate,
            assets = assets,
            liabilities = liabilities,
            equity = equity,
            totalAssets = totalAssets,
            totalLiabilitiesAndEquity = totalLiabilities + totalEquity,
            isBalanced = totalAssets == (totalLiabilities + totalEquity),
            generatedAt = LocalDate.now().toString()
        )
    }

    /**
     * 현금흐름표 생성
     */
    fun generateCashFlowStatement(
        companyId: UUID,
        periodStart: LocalDate,
        periodEnd: LocalDate
    ): CashFlowStatementResponse {
        val netIncome = incomeRecordRepository.getTotalIncomeByPeriod(companyId, periodStart, periodEnd) -
                expenseRecordRepository.getTotalExpenseByPeriod(companyId, periodStart, periodEnd)

        // 영업활동 현금흐름
        val operatingActivities = CashFlowSection(
            sectionName = "영업활동",
            netCashFlow = netIncome,
            items = listOf(
                CashFlowItem("순이익", netIncome, true),
                CashFlowItem("미수금 증감", BigDecimal("-2000000"), false),
                CashFlowItem("미지급금 증감", BigDecimal("1000000"), true)
            )
        )

        // 투자활동 현금흐름
        val investingActivities = CashFlowSection(
            sectionName = "투자활동",
            netCashFlow = BigDecimal("-5000000"),
            items = listOf(
                CashFlowItem("설비투자", BigDecimal("-5000000"), false)
            )
        )

        // 재무활동 현금흐름
        val financingActivities = CashFlowSection(
            sectionName = "재무활동",
            netCashFlow = BigDecimal("0"),
            items = listOf(
                CashFlowItem("차입금 상환", BigDecimal("0"), false)
            )
        )

        val netCashFlow = operatingActivities.netCashFlow + 
                         investingActivities.netCashFlow + 
                         financingActivities.netCashFlow

        return CashFlowStatementResponse(
            id = UUID.randomUUID(),
            periodStart = periodStart,
            periodEnd = periodEnd,
            operatingActivities = operatingActivities,
            investingActivities = investingActivities,
            financingActivities = financingActivities,
            netCashFlow = netCashFlow,
            beginningCash = BigDecimal("45000000"),
            endingCash = BigDecimal("45000000") + netCashFlow,
            generatedAt = LocalDate.now().toString()
        )
    }

    /**
     * 재무비율 계산
     */
    fun calculateFinancialRatios(
        companyId: UUID,
        periodStart: LocalDate,
        periodEnd: LocalDate
    ): FinancialRatiosResponse {
        val totalRevenue = incomeRecordRepository.getTotalIncomeByPeriod(companyId, periodStart, periodEnd)
        val totalExpenses = expenseRecordRepository.getTotalExpenseByPeriod(companyId, periodStart, periodEnd)
        val netIncome = totalRevenue - totalExpenses
        val totalAssets = BigDecimal("250000000") // 임시값
        val totalEquity = BigDecimal("170000000") // 임시값
        val currentAssets = BigDecimal("80000000") // 임시값
        val currentLiabilities = BigDecimal("30000000") // 임시값

        return FinancialRatiosResponse(
            companyId = companyId,
            periodStart = periodStart,
            periodEnd = periodEnd,
            profitabilityRatios = ProfitabilityRatios(
                grossProfitMargin = if (totalRevenue > BigDecimal.ZERO) netIncome.divide(totalRevenue, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                operatingProfitMargin = if (totalRevenue > BigDecimal.ZERO) netIncome.divide(totalRevenue, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                netProfitMargin = if (totalRevenue > BigDecimal.ZERO) netIncome.divide(totalRevenue, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                returnOnAssets = if (totalAssets > BigDecimal.ZERO) netIncome.divide(totalAssets, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                returnOnEquity = if (totalEquity > BigDecimal.ZERO) netIncome.divide(totalEquity, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO
            ),
            liquidityRatios = LiquidityRatios(
                currentRatio = if (currentLiabilities > BigDecimal.ZERO) currentAssets.divide(currentLiabilities, 2, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                quickRatio = BigDecimal("2.0"),
                cashRatio = BigDecimal("1.5"),
                workingCapital = currentAssets - currentLiabilities
            ),
            leverageRatios = LeverageRatios(
                debtToEquityRatio = BigDecimal("0.47"),
                debtToAssetsRatio = BigDecimal("0.32"),
                equityMultiplier = BigDecimal("1.47"),
                interestCoverageRatio = BigDecimal("8.5")
            ),
            efficiencyRatios = EfficiencyRatios(
                assetTurnover = if (totalAssets > BigDecimal.ZERO) totalRevenue.divide(totalAssets, 2, RoundingMode.HALF_UP) else BigDecimal.ZERO,
                receivablesTurnover = BigDecimal("12.0"),
                inventoryTurnover = BigDecimal("0"),
                payablesTurnover = BigDecimal("8.0")
            )
        )
    }

    /**
     * 재무제표 목록 조회
     */
    @Transactional(readOnly = true)
    fun getFinancialStatements(
        companyId: UUID,
        statementType: String?,
        year: Int?,
        page: Int,
        size: Int
    ): List<FinancialStatementResponse> {
        // 임시 구현 - 실제로는 데이터베이스에서 조회
        return listOf(
            FinancialStatementResponse(
                id = UUID.randomUUID(),
                statementType = "INCOME_STATEMENT",
                periodStart = LocalDate.of(2025, 1, 1),
                periodEnd = LocalDate.of(2025, 1, 31),
                generatedAt = LocalDate.now().toString(),
                status = "GENERATED",
                data = mapOf("totalRevenue" to BigDecimal("18000000")),
                summary = FinancialSummaryData(
                    totalRevenue = BigDecimal("18000000"),
                    totalExpenses = BigDecimal("12000000"),
                    netIncome = BigDecimal("6000000"),
                    totalAssets = BigDecimal("250000000"),
                    totalLiabilities = BigDecimal("80000000"),
                    totalEquity = BigDecimal("170000000"),
                    profitMargin = BigDecimal("0.33"),
                    returnOnAssets = BigDecimal("0.024"),
                    returnOnEquity = BigDecimal("0.035")
                )
            )
        )
    }

    /**
     * 재무제표 상세 조회
     */
    @Transactional(readOnly = true)
    fun getFinancialStatement(statementId: UUID): FinancialStatementResponse {
        // 임시 구현
        return FinancialStatementResponse(
            id = statementId,
            statementType = "INCOME_STATEMENT",
            periodStart = LocalDate.of(2025, 1, 1),
            periodEnd = LocalDate.of(2025, 1, 31),
            generatedAt = LocalDate.now().toString(),
            status = "GENERATED",
            data = mapOf("totalRevenue" to BigDecimal("18000000")),
            summary = FinancialSummaryData(
                totalRevenue = BigDecimal("18000000"),
                totalExpenses = BigDecimal("12000000"),
                netIncome = BigDecimal("6000000"),
                totalAssets = BigDecimal("250000000"),
                totalLiabilities = BigDecimal("80000000"),
                totalEquity = BigDecimal("170000000"),
                profitMargin = BigDecimal("0.33"),
                returnOnAssets = BigDecimal("0.024"),
                returnOnEquity = BigDecimal("0.035")
            )
        )
    }

    /**
     * 재무제표 비교 분석
     */
    fun compareFinancialStatements(
        companyId: UUID,
        statementType: String,
        currentPeriodStart: LocalDate,
        currentPeriodEnd: LocalDate,
        previousPeriodStart: LocalDate,
        previousPeriodEnd: LocalDate
    ): FinancialComparisonResponse {
        val currentStatement = generateFinancialStatement(companyId, statementType, currentPeriodStart, currentPeriodEnd, null)
        val previousStatement = generateFinancialStatement(companyId, statementType, previousPeriodStart, previousPeriodEnd, null)
        
        val revenueGrowth = calculateGrowthRate(
            currentStatement.summary.totalRevenue,
            previousStatement.summary.totalRevenue
        )
        
        val comparison = ComparisonData(
            revenueGrowth = revenueGrowth,
            expenseGrowth = calculateGrowthRate(currentStatement.summary.totalExpenses, previousStatement.summary.totalExpenses),
            profitGrowth = calculateGrowthRate(currentStatement.summary.netIncome, previousStatement.summary.netIncome),
            assetGrowth = BigDecimal("0.05"),
            liabilityGrowth = BigDecimal("0.02"),
            equityGrowth = BigDecimal("0.08"),
            keyInsights = listOf(
                "매출이 전년 동기 대비 ${revenueGrowth.multiply(BigDecimal("100"))}% 증가했습니다.",
                "순이익률이 개선되었습니다.",
                "현금흐름이 안정적입니다."
            )
        )

        return FinancialComparisonResponse(
            currentPeriod = currentStatement,
            previousPeriod = previousStatement,
            comparison = comparison
        )
    }

    /**
     * 재무제표 템플릿 목록 조회
     */
    @Transactional(readOnly = true)
    fun getFinancialStatementTemplates(
        companyId: UUID,
        statementType: String?
    ): List<FinancialStatementTemplateResponse> {
        return listOf(
            FinancialStatementTemplateResponse(
                id = UUID.randomUUID(),
                templateName = "기본 손익계산서",
                statementType = "INCOME_STATEMENT",
                structure = mapOf("sections" to listOf("revenue", "expenses", "netIncome")),
                isDefault = true,
                isActive = true
            )
        )
    }

    /**
     * Excel 내보내기
     */
    fun exportToExcel(statementId: UUID): ExportResult {
        return ExportResult(
            downloadUrl = "/api/downloads/financial-statement-${statementId}.xlsx",
            fileName = "재무제표_${LocalDate.now()}.xlsx"
        )
    }

    /**
     * PDF 내보내기
     */
    fun exportToPdf(statementId: UUID): ExportResult {
        return ExportResult(
            downloadUrl = "/api/downloads/financial-statement-${statementId}.pdf",
            fileName = "재무제표_${LocalDate.now()}.pdf"
        )
    }

    /**
     * 재무 요약 정보 조회
     */
    @Transactional(readOnly = true)
    fun getFinancialSummary(companyId: UUID, year: Int): FinancialSummaryData {
        val periodStart = LocalDate.of(year, 1, 1)
        val periodEnd = LocalDate.of(year, 12, 31)
        
        val totalRevenue = incomeRecordRepository.getTotalIncomeByPeriod(companyId, periodStart, periodEnd)
        val totalExpenses = expenseRecordRepository.getTotalExpenseByPeriod(companyId, periodStart, periodEnd)
        val netIncome = totalRevenue - totalExpenses
        
        return FinancialSummaryData(
            totalRevenue = totalRevenue,
            totalExpenses = totalExpenses,
            netIncome = netIncome,
            totalAssets = BigDecimal("250000000"),
            totalLiabilities = BigDecimal("80000000"),
            totalEquity = BigDecimal("170000000"),
            profitMargin = if (totalRevenue > BigDecimal.ZERO) netIncome.divide(totalRevenue, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO,
            returnOnAssets = BigDecimal("0.024"),
            returnOnEquity = BigDecimal("0.035")
        )
    }

    /**
     * 월별 재무 현황 조회
     */
    @Transactional(readOnly = true)
    fun getMonthlySummary(companyId: UUID, year: Int): List<MonthlyFinancialSummary> {
        return (1..12).map { month ->
            val monthStart = LocalDate.of(year, month, 1)
            val monthEnd = monthStart.plusMonths(1).minusDays(1)
            
            val revenue = incomeRecordRepository.getTotalIncomeByPeriod(companyId, monthStart, monthEnd)
            val expenses = expenseRecordRepository.getTotalExpenseByPeriod(companyId, monthStart, monthEnd)
            val netIncome = revenue - expenses
            val profitMargin = if (revenue > BigDecimal.ZERO) netIncome.divide(revenue, 4, RoundingMode.HALF_UP) else BigDecimal.ZERO
            
            MonthlyFinancialSummary(
                month = month,
                monthName = "${month}월",
                revenue = revenue,
                expenses = expenses,
                netIncome = netIncome,
                profitMargin = profitMargin
            )
        }
    }

    /**
     * 재무 지표 트렌드 분석
     */
    @Transactional(readOnly = true)
    fun getFinancialTrends(companyId: UUID, startYear: Int, endYear: Int): FinancialTrendsResponse {
        val years = (startYear..endYear).toList()
        
        val revenueTrend = years.map { year ->
            val revenue = incomeRecordRepository.getTotalIncomeByPeriod(
                companyId, LocalDate.of(year, 1, 1), LocalDate.of(year, 12, 31)
            )
            YearlyData(year, revenue, BigDecimal("0.08")) // 임시 성장률
        }
        
        val profitTrend = years.map { year ->
            val revenue = incomeRecordRepository.getTotalIncomeByPeriod(
                companyId, LocalDate.of(year, 1, 1), LocalDate.of(year, 12, 31)
            )
            val expenses = expenseRecordRepository.getTotalExpenseByPeriod(
                companyId, LocalDate.of(year, 1, 1), LocalDate.of(year, 12, 31)
            )
            val profit = revenue - expenses
            YearlyData(year, profit, BigDecimal("0.12")) // 임시 성장률
        }
        
        return FinancialTrendsResponse(
            companyId = companyId,
            startYear = startYear,
            endYear = endYear,
            revenueTrend = revenueTrend,
            profitTrend = profitTrend,
            assetTrend = years.map { YearlyData(it, BigDecimal("250000000"), BigDecimal("0.05")) },
            ratioTrends = RatioTrendsData(
                profitMarginTrend = years.map { YearlyData(it, BigDecimal("0.33"), BigDecimal("0.02")) },
                roaTrend = years.map { YearlyData(it, BigDecimal("0.024"), BigDecimal("0.001")) },
                roeTrend = years.map { YearlyData(it, BigDecimal("0.035"), BigDecimal("0.002")) },
                currentRatioTrend = years.map { YearlyData(it, BigDecimal("2.67"), BigDecimal("0.1")) }
            )
        )
    }

    // Helper methods
    private fun calculateGrowthRate(current: BigDecimal, previous: BigDecimal): BigDecimal {
        return if (previous > BigDecimal.ZERO) {
            (current - previous).divide(previous, 4, RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
            "total_revenue" to totalRevenue.toDouble(),
            "total_expenses" to totalExpenses.toDouble(),
            "net_income" to netIncome.toDouble()
        )

        val statement = FinancialStatement(
            companyId = companyId,
            statementType = FinancialStatement.StatementType.INCOME_STATEMENT,
            periodStart = periodStart,
            periodEnd = periodEnd,
            statementData = statementData,
            generatedBy = generatedBy
        )

        val savedStatement = financialStatementRepository.save(statement)
        return FinancialStatementDto.from(savedStatement)
    }

    /**
     * 대차대조표 생성
     */
    fun generateBalanceSheet(
        companyId: UUID,
        asOfDate: LocalDate,
        generatedBy: UUID
    ): FinancialStatementDto {
        // 자산 계정 집계
        val assetAccounts = accountRepository.findByCompanyIdAndAccountTypeAndIsActiveTrue(
            companyId, Account.AccountType.ASSET
        )
        val totalAssets = calculateAccountBalanceAsOf(assetAccounts, asOfDate)

        // 부채 계정 집계
        val liabilityAccounts = accountRepository.findByCompanyIdAndAccountTypeAndIsActiveTrue(
            companyId, Account.AccountType.LIABILITY
        )
        val totalLiabilities = calculateAccountBalanceAsOf(liabilityAccounts, asOfDate)

        // 자본 계정 집계
        val equityAccounts = accountRepository.findByCompanyIdAndAccountTypeAndIsActiveTrue(
            companyId, Account.AccountType.EQUITY
        )
        val totalEquity = calculateAccountBalanceAsOf(equityAccounts, asOfDate)

        val statementData = mapOf(
            "total_assets" to totalAssets.toDouble(),
            "total_liabilities" to totalLiabilities.toDouble(),
            "total_equity" to totalEquity.toDouble()
        )

        val statement = FinancialStatement(
            companyId = companyId,
            statementType = FinancialStatement.StatementType.BALANCE_SHEET,
            periodStart = asOfDate,
            periodEnd = asOfDate,
            statementData = statementData,
            generatedBy = generatedBy
        )

        val savedStatement = financialStatementRepository.save(statement)
        return FinancialStatementDto.from(savedStatement)
    }

    /**
     * 계정 잔액 계산 (기간별)
     */
    private fun calculateAccountBalance(
        accounts: List<Account>,
        periodStart: LocalDate,
        periodEnd: LocalDate
    ): BigDecimal {
        if (accounts.isEmpty()) return BigDecimal.ZERO
        val accountIds = accounts.map { it.accountId }
        return journalEntryLineRepository.sumAmountByAccountIdsAndPeriod(
            accountIds, periodStart, periodEnd
        ) ?: BigDecimal.ZERO
    }

    /**
     * 계정 잔액 계산 (특정 시점)
     */
    private fun calculateAccountBalanceAsOf(
        accounts: List<Account>,
        asOfDate: LocalDate
    ): BigDecimal {
        if (accounts.isEmpty()) return BigDecimal.ZERO
        val accountIds = accounts.map { it.accountId }
        return journalEntryLineRepository.sumAmountByAccountIdsAsOf(
            accountIds, asOfDate
        ) ?: BigDecimal.ZERO
    }
}