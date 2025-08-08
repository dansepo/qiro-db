package com.qiro.domain.accounting.controller

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.service.ExpenseManagementService
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDate
import java.util.*

/**
 * 지출 관리 REST API Controller
 * 건물관리용 지출 관리 기능 (유지보수비, 공과금, 관리비, 승인)
 */
@RestController
@RequestMapping("/api/expense")
@CrossOrigin(origins = ["*"])
class ExpenseManagementController(
    private val expenseManagementService: ExpenseManagementService
) {

    /**
     * 지출 기록 생성
     */
    @PostMapping("/records")
    fun createExpenseRecord(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateExpenseRecordRequest
    ): ResponseEntity<ExpenseRecordResponse> {
        val expenseRecord = expenseManagementService.createExpenseRecord(
            companyId = companyId,
            expenseTypeId = request.expenseTypeId,
            vendorId = request.vendorId,
            amount = request.amount,
            expenseDate = request.expenseDate,
            description = request.description,
            invoiceNumber = request.invoiceNumber
        )
        
        val response = ExpenseRecordResponse(
            id = expenseRecord.id,
            expenseTypeName = expenseRecord.expenseType?.typeName ?: "",
            vendorName = expenseRecord.vendor?.vendorName,
            amount = expenseRecord.amount,
            expenseDate = expenseRecord.expenseDate,
            status = expenseRecord.status.name,
            description = expenseRecord.description,
            invoiceNumber = expenseRecord.invoiceNumber,
            isRecurring = expenseRecord.isRecurring,
            approvalStatus = expenseRecord.approvalStatus?.name,
            createdAt = expenseRecord.createdAt.toString()
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 지출 기록 목록 조회
     */
    @GetMapping("/records")
    fun getExpenseRecords(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) startDate: LocalDate?,
        @RequestParam(required = false) endDate: LocalDate?,
        @RequestParam(required = false) expenseTypeId: UUID?,
        @RequestParam(required = false) vendorId: UUID?,
        @RequestParam(required = false) status: String?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<List<ExpenseRecordResponse>> {
        val expenseRecords = expenseManagementService.getExpenseRecords(
            companyId = companyId,
            startDate = startDate,
            endDate = endDate,
            expenseTypeId = expenseTypeId,
            vendorId = vendorId,
            status = status
        )
        
        val responses = expenseRecords.map { record ->
            ExpenseRecordResponse(
                id = record.id,
                expenseTypeName = record.expenseType?.typeName ?: "",
                vendorName = record.vendor?.vendorName,
                amount = record.amount,
                expenseDate = record.expenseDate,
                status = record.status.name,
                description = record.description,
                invoiceNumber = record.invoiceNumber,
                isRecurring = record.isRecurring,
                approvalStatus = record.approvalStatus?.name,
                createdAt = record.createdAt.toString()
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 지출 승인 처리
     */
    @PostMapping("/approve")
    fun approveExpense(
        @RequestParam companyId: UUID,
        @RequestBody request: ApproveExpenseRequest
    ): ResponseEntity<ExpenseApprovalResponse> {
        val approval = expenseManagementService.approveExpense(
            companyId = companyId,
            expenseId = request.expenseId,
            approved = request.approved,
            approvalNotes = request.approvalNotes
        )
        
        val response = ExpenseApprovalResponse(
            expenseId = request.expenseId,
            approved = request.approved,
            approvalDate = LocalDate.now(),
            approverName = "관리자", // 실제 구현에서는 현재 사용자 정보
            approvalNotes = request.approvalNotes
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 승인 대기 지출 목록 조회
     */
    @GetMapping("/pending-approvals")
    fun getPendingApprovals(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<ExpenseRecordResponse>> {
        val pendingExpenses = expenseManagementService.getPendingApprovals(companyId)
        
        val responses = pendingExpenses.map { record ->
            ExpenseRecordResponse(
                id = record.id,
                expenseTypeName = record.expenseType?.typeName ?: "",
                vendorName = record.vendor?.vendorName,
                amount = record.amount,
                expenseDate = record.expenseDate,
                status = record.status.name,
                description = record.description,
                invoiceNumber = record.invoiceNumber,
                isRecurring = record.isRecurring,
                approvalStatus = record.approvalStatus?.name,
                createdAt = record.createdAt.toString()
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 지출 유형 목록 조회
     */
    @GetMapping("/types")
    fun getExpenseTypes(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<ExpenseTypeResponse>> {
        val expenseTypes = expenseManagementService.getExpenseTypes(companyId)
        
        val responses = expenseTypes.map { type ->
            ExpenseTypeResponse(
                id = type.id,
                typeName = type.typeName,
                category = type.category,
                description = type.description,
                requiresApproval = type.requiresApproval,
                budgetLimit = type.budgetLimit,
                isActive = type.isActive
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 업체 목록 조회
     */
    @GetMapping("/vendors")
    fun getVendors(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) search: String?
    ): ResponseEntity<List<VendorResponse>> {
        val vendors = expenseManagementService.getVendors(companyId, search)
        
        val responses = vendors.map { vendor ->
            VendorResponse(
                id = vendor.id,
                vendorName = vendor.vendorName,
                businessNumber = vendor.businessNumber,
                contactPerson = vendor.contactPerson,
                phoneNumber = vendor.phoneNumber,
                email = vendor.email,
                address = vendor.address,
                isActive = vendor.isActive
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 업체 생성
     */
    @PostMapping("/vendors")
    fun createVendor(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateVendorRequest
    ): ResponseEntity<VendorResponse> {
        val vendor = expenseManagementService.createVendor(
            companyId = companyId,
            vendorName = request.vendorName,
            businessNumber = request.businessNumber,
            contactPerson = request.contactPerson,
            phoneNumber = request.phoneNumber,
            email = request.email,
            address = request.address
        )
        
        val response = VendorResponse(
            id = vendor.id,
            vendorName = vendor.vendorName,
            businessNumber = vendor.businessNumber,
            contactPerson = vendor.contactPerson,
            phoneNumber = vendor.phoneNumber,
            email = vendor.email,
            address = vendor.address,
            isActive = vendor.isActive
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 정기 지출 생성
     */
    @PostMapping("/recurring")
    fun createRecurringExpense(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateRecurringExpenseRequest
    ): ResponseEntity<RecurringExpenseResponse> {
        val recurringExpense = expenseManagementService.createRecurringExpense(
            companyId = companyId,
            expenseTypeId = request.expenseTypeId,
            vendorId = request.vendorId,
            amount = request.amount,
            description = request.description,
            recurringPeriod = request.recurringPeriod,
            startDate = request.startDate,
            endDate = request.endDate,
            dayOfMonth = request.dayOfMonth
        )
        
        val response = RecurringExpenseResponse(
            id = recurringExpense.id,
            expenseTypeName = recurringExpense.expenseType?.typeName ?: "",
            vendorName = recurringExpense.vendor?.vendorName,
            amount = recurringExpense.amount,
            description = recurringExpense.description,
            recurringPeriod = recurringExpense.recurringPeriod.name,
            startDate = recurringExpense.startDate,
            endDate = recurringExpense.endDate,
            dayOfMonth = recurringExpense.dayOfMonth,
            isActive = recurringExpense.isActive,
            nextGenerationDate = recurringExpense.nextGenerationDate,
            generatedCount = recurringExpense.generatedCount
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 정기 지출 목록 조회
     */
    @GetMapping("/recurring")
    fun getRecurringExpenses(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<RecurringExpenseResponse>> {
        val recurringExpenses = expenseManagementService.getRecurringExpenses(companyId)
        
        val responses = recurringExpenses.map { recurring ->
            RecurringExpenseResponse(
                id = recurring.id,
                expenseTypeName = recurring.expenseType?.typeName ?: "",
                vendorName = recurring.vendor?.vendorName,
                amount = recurring.amount,
                description = recurring.description,
                recurringPeriod = recurring.recurringPeriod.name,
                startDate = recurring.startDate,
                endDate = recurring.endDate,
                dayOfMonth = recurring.dayOfMonth,
                isActive = recurring.isActive,
                nextGenerationDate = recurring.nextGenerationDate,
                generatedCount = recurring.generatedCount
            )
        }
        
        return ResponseEntity.ok(responses)
    }

    /**
     * 지출 통계 조회
     */
    @GetMapping("/statistics")
    fun getExpenseStatistics(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) year: Int?,
        @RequestParam(required = false) month: Int?
    ): ResponseEntity<ExpenseStatisticsResponse> {
        val statistics = expenseManagementService.getExpenseStatistics(
            companyId = companyId,
            year = year ?: LocalDate.now().year,
            month = month
        )
        
        return ResponseEntity.ok(statistics)
    }

    /**
     * 지출 대시보드 데이터 조회
     */
    @GetMapping("/dashboard")
    fun getExpenseDashboard(
        @RequestParam companyId: UUID
    ): ResponseEntity<ExpenseDashboardResponse> {
        val dashboard = expenseManagementService.getExpenseDashboard(companyId)
        return ResponseEntity.ok(dashboard)
    }

    /**
     * 예산 대비 지출 현황 조회
     */
    @GetMapping("/budget-vs-expense")
    fun getBudgetVsExpense(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) year: Int?,
        @RequestParam(required = false) month: Int?
    ): ResponseEntity<List<BudgetVsExpenseResponse>> {
        val budgetVsExpense = expenseManagementService.getBudgetVsExpense(
            companyId = companyId,
            year = year ?: LocalDate.now().year,
            month = month
        )
        
        return ResponseEntity.ok(budgetVsExpense)
    }

    /**
     * 정기 지출 자동 생성 실행
     */
    @PostMapping("/generate-recurring")
    fun generateRecurringExpenses(
        @RequestParam companyId: UUID,
        @RequestParam targetMonth: String // YYYY-MM 형식
    ): ResponseEntity<Map<String, Any>> {
        val result = expenseManagementService.generateRecurringExpenses(companyId, targetMonth)
        
        val response = mapOf(
            "success" to true,
            "message" to "정기 지출이 생성되었습니다.",
            "generatedCount" to result.size,
            "targetMonth" to targetMonth
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 월별 지출 현황 조회
     */
    @GetMapping("/monthly")
    fun getMonthlyExpense(
        @RequestParam companyId: UUID,
        @RequestParam year: Int,
        @RequestParam(required = false) expenseTypeId: UUID?
    ): ResponseEntity<List<MonthlyExpenseData>> {
        val monthlyData = expenseManagementService.getMonthlyExpense(
            companyId = companyId,
            year = year,
            expenseTypeId = expenseTypeId
        )
        
        return ResponseEntity.ok(monthlyData)
    }

    /**
     * 업체별 지출 현황 조회
     */
    @GetMapping("/by-vendor")
    fun getExpenseByVendor(
        @RequestParam companyId: UUID,
        @RequestParam(required = false) year: Int?,
        @RequestParam(required = false) month: Int?
    ): ResponseEntity<List<VendorExpenseData>> {
        val vendorData = expenseManagementService.getExpenseByVendor(
            companyId = companyId,
            year = year ?: LocalDate.now().year,
            month = month
        )
        
        return ResponseEntity.ok(vendorData)
    }
}