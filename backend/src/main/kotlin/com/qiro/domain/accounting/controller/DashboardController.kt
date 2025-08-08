package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.*
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 대시보드 REST API Controller
 * 건물관리용 통합 대시보드 기능 (최소 기능)
 */
@RestController
@RequestMapping("/api/dashboard")
@CrossOrigin(origins = ["*"])
class DashboardController(
    private val incomeManagementService: IncomeManagementService,
    private val expenseManagementService: ExpenseManagementService
) {

    /**
     * 메인 대시보드 데이터 조회 (간소화 버전)
     */
    @GetMapping("/main")
    fun getMainDashboard(
        @RequestParam companyId: UUID
    ): ResponseEntity<MainDashboardResponse> {
        
        // 회사 정보
        val companyInfo = CompanyInfoData(
            companyId = companyId,
            companyName = "건물관리 회사",
            currentMonth = LocalDate.now().month.name,
            currentYear = LocalDate.now().year,
            lastUpdated = LocalDate.now().toString()
        )
        
        // 재무 요약 (간소화)
        val financialSummary = FinancialSummaryData(
            totalAssets = BigDecimal("500000000"),
            totalLiabilities = BigDecimal("150000000"),
            netWorth = BigDecimal("350000000"),
            monthlyProfit = BigDecimal("8000000"),
            yearlyProfit = BigDecimal("96000000"),
            profitMargin = BigDecimal("0.20"),
            cashBalance = BigDecimal("75000000")
        )
        
        // 수입 개요
        val incomeOverview = getIncomeOverview(companyId)
        
        // 지출 개요
        val expenseOverview = getExpenseOverview(companyId)
        
        // 예산 개요 (간소화)
        val budgetOverview = BudgetOverviewData(
            totalBudget = BigDecimal("120000000"),
            totalSpent = BigDecimal("45000000"),
            remainingBudget = BigDecimal("75000000"),
            utilizationRate = BigDecimal("0.375"),
            overBudgetCategories = 2,
            budgetAlerts = 3,
            monthlyProgress = BigDecimal("0.42")
        )
        
        // 최근 활동 (간소화)
        val recentActivities = getRecentActivities(companyId)
        
        // 알림 (간소화)
        val alerts = getDashboardAlerts(companyId)
        
        // 차트 데이터 (간소화)
        val charts = getDashboardCharts(companyId)
        
        val response = MainDashboardResponse(
            companyInfo = companyInfo,
            financialSummary = financialSummary,
            incomeOverview = incomeOverview,
            expenseOverview = expenseOverview,
            budgetOverview = budgetOverview,
            recentActivities = recentActivities,
            alerts = alerts,
            charts = charts
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 월별 수입/지출 차트 데이터
     */
    @GetMapping("/monthly-chart")
    fun getMonthlyChart(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) year: Int?
    ): ResponseEntity<List<MonthlyIncomeExpenseData>> {
        
        val chartData = (1..12).map { month ->
            val income = BigDecimal("${15000000 + (month * 500000)}")
            val expense = BigDecimal("${12000000 + (month * 300000)}")
            MonthlyIncomeExpenseData(
                month = "${year ?: LocalDate.now().year}-${month.toString().padStart(2, '0')}",
                income = income,
                expense = expense,
                profit = income - expense
            )
        }
        
        return ResponseEntity.ok(chartData)
    }

    /**
     * 카테고리별 분포 차트 데이터
     */
    @GetMapping("/category-distribution")
    fun getCategoryDistribution(
        @RequestParam companyId: UUID,
        @RequestParam type: String // INCOME 또는 EXPENSE
    ): ResponseEntity<List<CategoryDistributionData>> {
        
        val distributionData = if (type == "INCOME") {
            listOf(
                CategoryDistributionData("관리비", BigDecimal("120000000"), BigDecimal("0.60"), "#3B82F6"),
                CategoryDistributionData("임대료", BigDecimal("60000000"), BigDecimal("0.30"), "#10B981"),
                CategoryDistributionData("주차비", BigDecimal("15000000"), BigDecimal("0.075"), "#F59E0B"),
                CategoryDistributionData("기타", BigDecimal("5000000"), BigDecimal("0.025"), "#EF4444")
            )
        } else {
            listOf(
                CategoryDistributionData("유지보수비", BigDecimal("45000000"), BigDecimal("0.35"), "#8B5CF6"),
                CategoryDistributionData("공과금", BigDecimal("35000000"), BigDecimal("0.27"), "#06B6D4"),
                CategoryDistributionData("관리비", BigDecimal("25000000"), BigDecimal("0.19"), "#84CC16"),
                CategoryDistributionData("보험료", BigDecimal("15000000"), BigDecimal("0.12"), "#F97316"),
                CategoryDistributionData("기타", BigDecimal("8000000"), BigDecimal("0.06"), "#EC4899")
            )
        }
        
        return ResponseEntity.ok(distributionData)
    }

    /**
     * 건물관리 특화 지표 조회 (간소화)
     */
    @GetMapping("/building-metrics")
    fun getBuildingManagementMetrics(
        @RequestParam companyId: UUID
    ): ResponseEntity<BuildingManagementMetricsResponse> {
        
        val metrics = BuildingManagementMetricsResponse(
            occupancyRate = BigDecimal("0.95"), // 95% 입주율
            maintenanceCostRatio = BigDecimal("0.15"), // 15% 유지보수비 비율
            utilityCostPerUnit = BigDecimal("150000"), // 세대당 15만원
            collectionEfficiency = BigDecimal("0.98"), // 98% 수납률
            maintenanceMetrics = MaintenanceMetricsData(
                totalMaintenanceCost = BigDecimal("25000000"),
                preventiveMaintenanceRatio = BigDecimal("0.70"),
                emergencyRepairCost = BigDecimal("3000000"),
                maintenanceFrequency = 45,
                averageRepairTime = BigDecimal("2.5")
            ),
            tenantMetrics = TenantMetricsData(
                totalUnits = 200,
                occupiedUnits = 190,
                vacantUnits = 10,
                newTenants = 5,
                tenantTurnover = BigDecimal("0.08"),
                averageRent = BigDecimal("800000")
            )
        )
        
        return ResponseEntity.ok(metrics)
    }

    // Helper methods
    private fun getIncomeOverview(companyId: UUID): IncomeOverviewData {
        return IncomeOverviewData(
            todayIncome = BigDecimal("500000"),
            monthlyIncome = BigDecimal("18000000"),
            yearlyIncome = BigDecimal("200000000"),
            totalReceivables = BigDecimal("5000000"),
            overdueReceivables = BigDecimal("1200000"),
            collectionRate = BigDecimal("0.95"),
            incomeGrowth = BigDecimal("0.08"),
            topIncomeTypes = listOf(
                IncomeTypeData("관리비", BigDecimal("120000000"), BigDecimal("0.60")),
                IncomeTypeData("임대료", BigDecimal("60000000"), BigDecimal("0.30")),
                IncomeTypeData("주차비", BigDecimal("15000000"), BigDecimal("0.075"))
            )
        )
    }

    private fun getExpenseOverview(companyId: UUID): ExpenseOverviewData {
        return ExpenseOverviewData(
            todayExpense = BigDecimal("400000"),
            monthlyExpense = BigDecimal("12000000"),
            yearlyExpense = BigDecimal("128000000"),
            pendingApprovals = 5,
            pendingAmount = BigDecimal("2500000"),
            expenseGrowth = BigDecimal("0.05"),
            topExpenseCategories = listOf(
                ExpenseCategoryData("유지보수비", BigDecimal("45000000"), BigDecimal("0.35")),
                ExpenseCategoryData("공과금", BigDecimal("35000000"), BigDecimal("0.27")),
                ExpenseCategoryData("관리비", BigDecimal("25000000"), BigDecimal("0.19"))
            )
        )
    }

    private fun getRecentActivities(companyId: UUID): List<RecentActivityData> {
        return listOf(
            RecentActivityData(
                id = UUID.randomUUID(),
                type = "INCOME",
                title = "관리비 수납",
                description = "101호 관리비 납부 완료",
                amount = BigDecimal("150000"),
                date = LocalDate.now(),
                status = "COMPLETED",
                priority = "LOW"
            ),
            RecentActivityData(
                id = UUID.randomUUID(),
                type = "EXPENSE",
                title = "엘리베이터 수리",
                description = "1호기 엘리베이터 정기점검",
                amount = BigDecimal("500000"),
                date = LocalDate.now().minusDays(1),
                status = "PENDING",
                priority = "HIGH"
            ),
            RecentActivityData(
                id = UUID.randomUUID(),
                type = "APPROVAL",
                title = "지출 승인 요청",
                description = "보일러 수리비 승인 대기",
                amount = BigDecimal("800000"),
                date = LocalDate.now().minusDays(2),
                status = "PENDING",
                priority = "MEDIUM"
            )
        )
    }

    private fun getDashboardAlerts(companyId: UUID): List<DashboardAlertData> {
        return listOf(
            DashboardAlertData(
                id = UUID.randomUUID(),
                alertType = "OVERDUE",
                title = "연체 관리비",
                message = "3세대에서 관리비 연체 중입니다.",
                severity = "WARNING",
                actionRequired = true,
                actionUrl = "/income/overdue",
                createdAt = LocalDate.now().toString()
            ),
            DashboardAlertData(
                id = UUID.randomUUID(),
                alertType = "APPROVAL_PENDING",
                title = "승인 대기",
                message = "5건의 지출이 승인을 기다리고 있습니다.",
                severity = "INFO",
                actionRequired = true,
                actionUrl = "/expense/pending",
                createdAt = LocalDate.now().toString()
            ),
            DashboardAlertData(
                id = UUID.randomUUID(),
                alertType = "BUDGET_EXCEEDED",
                title = "예산 초과",
                message = "유지보수비 예산이 80%를 초과했습니다.",
                severity = "ERROR",
                actionRequired = true,
                actionUrl = "/budget/analysis",
                createdAt = LocalDate.now().toString()
            )
        )
    }

    private fun getDashboardCharts(companyId: UUID): DashboardChartsData {
        return DashboardChartsData(
            monthlyIncomeExpense = (1..12).map { month ->
                val income = BigDecimal("${15000000 + (month * 500000)}")
                val expense = BigDecimal("${12000000 + (month * 300000)}")
                MonthlyIncomeExpenseData(
                    month = "2025-${month.toString().padStart(2, '0')}",
                    income = income,
                    expense = expense,
                    profit = income - expense
                )
            },
            categoryDistribution = listOf(
                CategoryDistributionData("관리비", BigDecimal("120000000"), BigDecimal("0.60"), "#3B82F6"),
                CategoryDistributionData("임대료", BigDecimal("60000000"), BigDecimal("0.30"), "#10B981"),
                CategoryDistributionData("주차비", BigDecimal("15000000"), BigDecimal("0.075"), "#F59E0B")
            ),
            budgetUtilization = listOf(
                BudgetUtilizationData("유지보수비", BigDecimal("30000000"), BigDecimal("22000000"), BigDecimal("0.73")),
                BudgetUtilizationData("공과금", BigDecimal("25000000"), BigDecimal("18000000"), BigDecimal("0.72")),
                BudgetUtilizationData("관리비", BigDecimal("20000000"), BigDecimal("12000000"), BigDecimal("0.60"))
            ),
            cashFlowTrend = (0..29).map { dayOffset ->
                val date = LocalDate.now().minusDays(dayOffset.toLong())
                CashFlowTrendData(
                    date = date.toString(),
                    inflow = BigDecimal("${500000 + (dayOffset * 10000)}"),
                    outflow = BigDecimal("${400000 + (dayOffset * 8000)}"),
                    balance = BigDecimal("${50000000 + (dayOffset * 2000)}")
                )
            }.reversed()
        )
    }
}