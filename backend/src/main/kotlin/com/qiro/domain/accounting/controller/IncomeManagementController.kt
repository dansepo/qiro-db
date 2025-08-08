package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.IncomeManagementService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 수입 관리 REST API Controller
 * 건물관리용 수입 관리 기능 (관리비, 임대료, 주차비, 미수금)
 */
@RestController
@RequestMapping("/api/income")
@CrossOrigin(origins = ["*"])
class IncomeManagementController(
    private val incomeManagementService: IncomeManagementService
) {

    /**
     * 수입 기록 생성
     */
    @PostMapping("/records")
    fun createIncomeRecord(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateIncomeRecordRequest
    ): ResponseEntity<IncomeRecordResponse> {
        val incomeRecord = incomeManagementService.createIncomeRecord(
            companyId = companyId,
            incomeTypeId = request.incomeTypeId,
            unitId = request.unitId,
            amount = request.amount,
            dueDate = request.dueDate,
            period = request.period,
            description = request.description
        )
        
        val response = IncomeRecordResponse(
            id = incomeRecord.id,
            incomeTypeName = incomeRecord.incomeType?.typeName ?: "",
            unitId = incomeRecord.unitId,
            amount = incomeRecord.amount,
            dueDate = incomeRecord.dueDate,
            period = incomeRecord.period,
            status = incomeRecord.status.name,
            description = incomeRecord.description,
            createdAt = incomeRecord.createdAt.toString()
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 수입 기록 목록 조회
     */
    @GetMapping("/records")
    fun getIncomeRecords(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) startDate: LocalDate?,
        @RequestParam(required = false) endDate: LocalDate?,
        @RequestParam(required = false) incomeTypeId: UUID?,
        @RequestParam(required = false) unitId: String?,
        @RequestParam(required = false) status: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<List<IncomeRecordResponse>> {
        val incomeRecords = incomeManagementService.getIncomeRecords(
            companyId = companyId,
            startDate = startDate,
            endDate = endDate,
            incomeTypeId = incomeTypeId,
            unitId = unitId,
            status = status
        )
        
        val responses = incomeRecords.map { record ->
            IncomeRecordResponse(
                id = record.id,
                incomeTypeName = record.incomeType?.typeName ?: "",
                unitId = record.unitId,
                amount = record.amount,
                dueDate = record.dueDate,
                period = record.period,
                status = record.status.name,
                description = record.description,
                createdAt = record.createdAt.toString()
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 미수금 목록 조회
     */
    @GetMapping("/receivables")
    fun getReceivables(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) unitId: String?,
        @RequestParam(required = false) status: String?,
        @RequestParam(required = false) overdueDaysMin: Int?
    ): ResponseEntity<List<ReceivableResponse>> {
        val receivables = incomeManagementService.getReceivables(
            companyId = companyId,
            unitId = unitId,
            status = status,
            overdueDaysMin = overdueDaysMin
        )
        
        val responses = receivables.map { receivable ->
            ReceivableResponse(
                id = receivable.id,
                incomeRecordId = receivable.incomeRecord?.id,
                unitId = receivable.unitId,
                originalAmount = receivable.originalAmount,
                remainingAmount = receivable.remainingAmount,
                dueDate = receivable.dueDate,
                overdueDays = receivable.overdueDays,
                lateFee = receivable.lateFee,
                status = receivable.status.name,
                description = receivable.description
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 결제 기록 생성
     */
    @PostMapping("/payments")
    fun createPaymentRecord(
        @RequestParam companyId: UUID,
        @RequestBody request: CreatePaymentRecordRequest
    ): ResponseEntity<PaymentRecordResponse> {
        val paymentRecord = incomeManagementService.createPaymentRecord(
            companyId = companyId,
            receivableId = request.receivableId,
            paidAmount = request.paidAmount,
            paymentDate = request.paymentDate,
            paymentMethod = request.paymentMethod,
            notes = request.notes
        )
        
        val response = PaymentRecordResponse(
            id = paymentRecord.id,
            receivableId = paymentRecord.receivable?.id,
            unitId = paymentRecord.unitId,
            paidAmount = paymentRecord.paidAmount,
            paymentDate = paymentRecord.paymentDate,
            paymentMethod = paymentRecord.paymentMethod,
            notes = paymentRecord.notes,
            createdAt = paymentRecord.createdAt.toString()
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 연체료 계산
     */
    @PostMapping("/calculate-late-fee")
    fun calculateLateFee(
        @RequestParam companyId: UUID,
        @RequestBody request: CalculateLateFeeRequest
    ): ResponseEntity<LateFeeCalculationResponse> {
        val lateFeeResult = incomeManagementService.calculateLateFee(
            companyId = companyId,
            receivableId = request.receivableId,
            calculationDate = request.calculationDate
        )
        
        val response = LateFeeCalculationResponse(
            receivableId = request.receivableId,
            originalAmount = lateFeeResult.originalAmount,
            overdueDays = lateFeeResult.overdueDays,
            lateFeeAmount = lateFeeResult.lateFeeAmount,
            totalAmount = lateFeeResult.totalAmount,
            calculationDate = request.calculationDate,
            policyApplied = lateFeeResult.policyName
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 수입 유형 목록 조회
     */
    @GetMapping("/types")
    fun getIncomeTypes(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<IncomeTypeResponse>> {
        val incomeTypes = incomeManagementService.getIncomeTypes(companyId)
        
        val responses = incomeTypes.map { type ->
            IncomeTypeResponse(
                id = type.id,
                typeName = type.typeName,
                category = type.category,
                description = type.description,
                isRecurring = type.isRecurring,
                defaultAmount = type.defaultAmount,
                isActive = type.isActive
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 수입 통계 조회
     */
    @GetMapping("/statistics")
    fun getIncomeStatistics(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) year: Int?,
        @RequestParam(required = false) month: Int?
    ): ResponseEntity<IncomeStatisticsResponse> {
        val statistics = incomeManagementService.getIncomeStatistics(
            companyId = companyId,
            year = year ?: LocalDate.now().year,
            month = month
        )
        
        return ResponseEntity.ok(statistics)
    }

    /**
     * 수입 대시보드 데이터 조회
     */
    @GetMapping("/dashboard")
    fun getIncomeDashboard(
        @RequestParam companyId: UUID
    ): ResponseEntity<IncomeDashboardResponse> {
        val dashboard = incomeManagementService.getIncomeDashboard(companyId)
        return ResponseEntity.ok(dashboard)
    }

    /**
     * 월별 수입 현황 조회
     */
    @GetMapping("/monthly")
    fun getMonthlyIncome(
        @RequestParam companyId: UUID,
        @RequestParam year: Int,
        @RequestParam(required = false) incomeTypeId: UUID?
    ): ResponseEntity<List<MonthlyIncomeData>> {
        val monthlyData = incomeManagementService.getMonthlyIncome(
            companyId = companyId,
            year = year,
            incomeTypeId = incomeTypeId
        )
        
        return ResponseEntity.ok(monthlyData)
    }

    /**
     * 세대별 수납 현황 조회
     */
    @GetMapping("/collection-status")
    fun getCollectionStatus(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) period: String? // YYYY-MM 형식
    ): ResponseEntity<List<UnitCollectionStatusResponse>> {
        val collectionStatus = incomeManagementService.getCollectionStatus(
            companyId = companyId,
            period = period ?: LocalDate.now().toString().substring(0, 7)
        )
        
        return ResponseEntity.ok(collectionStatus)
    }

    /**
     * 연체 현황 조회
     */
    @GetMapping("/overdue-status")
    fun getOverdueStatus(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) minOverdueDays: Int?
    ): ResponseEntity<OverdueStatusResponse> {
        val overdueStatus = incomeManagementService.getOverdueStatus(
            companyId = companyId,
            minOverdueDays = minOverdueDays ?: 1
        )
        
        return ResponseEntity.ok(overdueStatus)
    }

    /**
     * 정기 수입 자동 생성 실행
     */
    @PostMapping("/generate-recurring")
    fun generateRecurringIncome(
        @RequestParam companyId: UUID,
        @RequestParam targetMonth: String // YYYY-MM 형식
    ): ResponseEntity<Map<String, Any>> {
        val result = incomeManagementService.generateRecurringIncome(companyId, targetMonth)
        
        val response = mapOf(
            "success" to true,
            "message" to "정기 수입이 생성되었습니다.",
            "generatedCount" to result.size,
            "targetMonth" to targetMonth
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 미수금 일괄 연체료 적용
     */
    @PostMapping("/apply-late-fees")
    fun applyLateFees(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) targetDate: LocalDate?
    ): ResponseEntity<Map<String, Any>> {
        val result = incomeManagementService.applyLateFees(
            companyId = companyId,
            targetDate = targetDate ?: LocalDate.now()
        )
        
        val response = mapOf(
            "success" to true,
            "message" to "연체료가 적용되었습니다.",
            "processedCount" to result.processedCount,
            "totalLateFee" to result.totalLateFee,
            "targetDate" to (targetDate ?: LocalDate.now()).toString()
        )
        
        return ResponseEntity.ok(response)
    }
}

// 추가 응답 DTO들
data class UnitCollectionStatusResponse(
    val unitId: String,
    val period: String,
    val totalDue: java.math.BigDecimal,
    val totalPaid: java.math.BigDecimal,
    val remainingAmount: java.math.BigDecimal,
    val collectionRate: java.math.BigDecimal,
    val overdueDays: Int,
    val status: String // PAID, PARTIAL, OVERDUE
)

data class OverdueStatusResponse(
    val totalOverdueAmount: java.math.BigDecimal,
    val totalOverdueCount: Int,
    val averageOverdueDays: java.math.BigDecimal,
    val overdueByRange: List<OverdueRangeData>,
    val overdueByType: List<OverdueTypeData>
)

data class OverdueRangeData(
    val range: String, // "1-30일", "31-60일" 등
    val count: Int,
    val amount: java.math.BigDecimal
)

data class OverdueTypeData(
    val incomeType: String,
    val count: Int,
    val amount: java.math.BigDecimal
)