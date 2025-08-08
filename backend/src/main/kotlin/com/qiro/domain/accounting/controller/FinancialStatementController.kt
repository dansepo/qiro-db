package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.FinancialStatementService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 재무제표 REST API Controller
 * 손익계산서, 대차대조표, 현금흐름표 생성 및 분석 기능
 */
@RestController
@RequestMapping("/api/financial-statements")
@CrossOrigin(origins = ["*"])
class FinancialStatementController(
    private val financialStatementService: FinancialStatementService
) {

    /**
     * 재무제표 생성
     */
    @PostMapping("/generate")
    fun generateFinancialStatement(
        @RequestParam companyId: UUID,
        @RequestBody request: GenerateFinancialStatementRequest
    ): ResponseEntity<FinancialStatementResponse> {
        val statement = financialStatementService.generateFinancialStatement(
            companyId = companyId,
            statementType = request.statementType,
            periodStart = request.periodStart,
            periodEnd = request.periodEnd,
            templateId = request.templateId
        )
        
        return ResponseEntity.ok(statement)
    }

    /**
     * 손익계산서 생성
     */
    @PostMapping("/income-statement")
    fun generateIncomeStatement(
        @RequestParam companyId: UUID,
        @RequestParam periodStart: LocalDate,
        @RequestParam periodEnd: LocalDate
    ): ResponseEntity<IncomeStatementResponse> {
        val incomeStatement = financialStatementService.generateIncomeStatement(
            companyId = companyId,
            periodStart = periodStart,
            periodEnd = periodEnd
        )
        
        return ResponseEntity.ok(incomeStatement)
    }

    /**
     * 대차대조표 생성
     */
    @PostMapping("/balance-sheet")
    fun generateBalanceSheet(
        @RequestParam companyId: UUID,
        @RequestParam asOfDate: LocalDate
    ): ResponseEntity<BalanceSheetResponse> {
        val balanceSheet = financialStatementService.generateBalanceSheet(
            companyId = companyId,
            asOfDate = asOfDate
        )
        
        return ResponseEntity.ok(balanceSheet)
    }

    /**
     * 현금흐름표 생성
     */
    @PostMapping("/cash-flow-statement")
    fun generateCashFlowStatement(
        @RequestParam companyId: UUID,
        @RequestParam periodStart: LocalDate,
        @RequestParam periodEnd: LocalDate
    ): ResponseEntity<CashFlowStatementResponse> {
        val cashFlowStatement = financialStatementService.generateCashFlowStatement(
            companyId = companyId,
            periodStart = periodStart,
            periodEnd = periodEnd
        )
        
        return ResponseEntity.ok(cashFlowStatement)
    }

    /**
     * 재무비율 분석
     */
    @GetMapping("/financial-ratios")
    fun getFinancialRatios(
        @RequestParam companyId: UUID,
        @RequestParam periodStart: LocalDate,
        @RequestParam periodEnd: LocalDate
    ): ResponseEntity<FinancialRatiosResponse> {
        val ratios = financialStatementService.calculateFinancialRatios(
            companyId = companyId,
            periodStart = periodStart,
            periodEnd = periodEnd
        )
        
        return ResponseEntity.ok(ratios)
    }

    /**
     * 재무제표 목록 조회
     */
    @GetMapping
    fun getFinancialStatements(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) statementType: String?,
        @RequestParam(required = false) year: Int?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<List<FinancialStatementResponse>> {
        val statements = financialStatementService.getFinancialStatements(
            companyId = companyId,
            statementType = statementType,
            year = year,
            page = page,
            size = size
        )
        
        return ResponseEntity.ok(statements)
    }

    /**
     * 재무제표 상세 조회
     */
    @GetMapping("/{statementId}")
    fun getFinancialStatement(
        @PathVariable statementId: UUID
    ): ResponseEntity<FinancialStatementResponse> {
        val statement = financialStatementService.getFinancialStatement(statementId)
        return ResponseEntity.ok(statement)
    }

    /**
     * 재무제표 비교 분석
     */
    @GetMapping("/compare")
    fun compareFinancialStatements(
        @RequestParam companyId: UUID,
        @RequestParam statementType: String,
        @RequestParam currentPeriodStart: LocalDate,
        @RequestParam currentPeriodEnd: LocalDate,
        @RequestParam previousPeriodStart: LocalDate,
        @RequestParam previousPeriodEnd: LocalDate
    ): ResponseEntity<FinancialComparisonResponse> {
        val comparison = financialStatementService.compareFinancialStatements(
            companyId = companyId,
            statementType = statementType,
            currentPeriodStart = currentPeriodStart,
            currentPeriodEnd = currentPeriodEnd,
            previousPeriodStart = previousPeriodStart,
            previousPeriodEnd = previousPeriodEnd
        )
        
        return ResponseEntity.ok(comparison)
    }

    /**
     * 재무제표 템플릿 목록 조회
     */
    @GetMapping("/templates")
    fun getFinancialStatementTemplates(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) statementType: String?
    ): ResponseEntity<List<FinancialStatementTemplateResponse>> {
        val templates = financialStatementService.getFinancialStatementTemplates(
            companyId = companyId,
            statementType = statementType
        )
        
        return ResponseEntity.ok(templates)
    }

    /**
     * 재무제표 Excel 내보내기
     */
    @PostMapping("/{statementId}/export/excel")
    fun exportToExcel(
        @PathVariable statementId: UUID
    ): ResponseEntity<Map<String, Any>> {
        val exportResult = financialStatementService.exportToExcel(statementId)
        
        val response = mapOf(
            "success" to true,
            "message" to "Excel 파일이 생성되었습니다.",
            "downloadUrl" to exportResult.downloadUrl,
            "fileName" to exportResult.fileName
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 재무제표 PDF 내보내기
     */
    @PostMapping("/{statementId}/export/pdf")
    fun exportToPdf(
        @PathVariable statementId: UUID
    ): ResponseEntity<Map<String, Any>> {
        val exportResult = financialStatementService.exportToPdf(statementId)
        
        val response = mapOf(
            "success" to true,
            "message" to "PDF 파일이 생성되었습니다.",
            "downloadUrl" to exportResult.downloadUrl,
            "fileName" to exportResult.fileName
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 재무제표 요약 정보 조회
     */
    @GetMapping("/summary")
    fun getFinancialSummary(
        @RequestParam companyId: UUID,
        @RequestParam year: Int
    ): ResponseEntity<FinancialSummaryData> {
        val summary = financialStatementService.getFinancialSummary(
            companyId = companyId,
            year = year
        )
        
        return ResponseEntity.ok(summary)
    }

    /**
     * 월별 재무 현황 조회
     */
    @GetMapping("/monthly-summary")
    fun getMonthlySummary(
        @RequestParam companyId: UUID,
        @RequestParam year: Int
    ): ResponseEntity<List<MonthlyFinancialSummary>> {
        val monthlySummary = financialStatementService.getMonthlySummary(
            companyId = companyId,
            year = year
        )
        
        return ResponseEntity.ok(monthlySummary)
    }

    /**
     * 재무 지표 트렌드 분석
     */
    @GetMapping("/trends")
    fun getFinancialTrends(
        @RequestParam companyId: UUID,
        @RequestParam startYear: Int,
        @RequestParam endYear: Int
    ): ResponseEntity<FinancialTrendsResponse> {
        val trends = financialStatementService.getFinancialTrends(
            companyId = companyId,
            startYear = startYear,
            endYear = endYear
        )
        
        return ResponseEntity.ok(trends)
    }
}

// 추가 응답 DTO들
data class ExportResult(
    val downloadUrl: String,
    val fileName: String
)

data class MonthlyFinancialSummary(
    val month: Int,
    val monthName: String,
    val revenue: BigDecimal,
    val expenses: BigDecimal,
    val netIncome: BigDecimal,
    val profitMargin: BigDecimal
)

data class FinancialTrendsResponse(
    val companyId: UUID,
    val startYear: Int,
    val endYear: Int,
    val revenueTrend: List<YearlyData>,
    val profitTrend: List<YearlyData>,
    val assetTrend: List<YearlyData>,
    val ratioTrends: RatioTrendsData
)

data class YearlyData(
    val year: Int,
    val value: BigDecimal,
    val growthRate: BigDecimal
)

data class RatioTrendsData(
    val profitMarginTrend: List<YearlyData>,
    val roaTrend: List<YearlyData>,
    val roeTrend: List<YearlyData>,
    val currentRatioTrend: List<YearlyData>
)