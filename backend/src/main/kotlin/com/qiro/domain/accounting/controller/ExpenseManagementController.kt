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
            id = expenseRecord.expenseRecordId,
            expenseTypeName = expenseRecord.expenseType.typeName,
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
            status = status,
            page = page,
            size = size
        )
        
        val responses = expenseRecords.map { record ->
            ExpenseRecordResponse(
                id = record.expenseRecordId,
                expenseTypeName = record.expenseType.typeName,
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
    @PostMapping("/approve/{expenseRecordId}")
    fun approveExpense(
        @RequestParam companyId: UUID,
        @PathVariable expenseRecordId: UUID,
        @RequestBody request: ApproveExpenseRequest
    ): ResponseEntity<ExpenseApprovalResponse> {
        val expenseRecord = expenseManagementService.approveExpense(
            companyId = companyId,
            expenseRecordId = expenseRecordId,
            approved = request.approved,
            approvalNotes = request.approvalNotes,
            approvedBy = companyId // TODO: 실제 사용자 ID로 변경
        )
        
        val response = ExpenseApprovalResponse(
            id = expenseRecord.expenseRecordId,
            approved = request.approved,
            approvalStatus = expenseRecord.approvalStatus?.name ?: "",
            approvedBy = expenseRecord.approvedBy,
            approvedAt = expenseRecord.approvedAt?.toString(),
            approvalNotes = expenseRecord.approvalNotes
        )
        
        return ResponseEntity.ok(response)
    }

    /**
     * 승인 대기 목록 조회
     */
    @GetMapping("/pending-approvals")
    fun getPendingApprovals(
        @RequestParam companyId: UUID
    ): ResponseEntity<List<ExpenseRecordResponse>> {
        val expenseRecords = expenseManagementService.getPendingApprovals(companyId)
        
        val responses = expenseRecords.map { record ->
            ExpenseRecordResponse(
                id = record.expenseRecordId,
                expenseTypeName = record.expenseType.typeName,
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
                id = type.expenseTypeId,
                typeName = type.typeName,
                category = type.category.name,
                requiresApproval = type.requiresApproval,
                budgetLimit = type.approvalLimit,
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
                id = vendor.vendorId,
                vendorName = vendor.vendorName,
                businessNumber = vendor.businessNumber,
                contactPerson = vendor.contactPerson,
                phoneNumber = vendor.phoneNumber,
                email = vendor.email,
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
        val vendor = expenseManagementService.createVendor(companyId, request)
        
        val response = VendorResponse(
            id = vendor.vendorId,
            vendorName = vendor.vendorName,
            businessNumber = vendor.businessNumber,
            contactPerson = vendor.contactPerson,
            phoneNumber = vendor.phoneNumber,
            email = vendor.email,
            isActive = vendor.isActive
        )
        
        return ResponseEntity.ok(response)
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
        val statistics = expenseManagementService.getExpenseStatistics(companyId, year, month)
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
}