package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 지출 관리 서비스 (건물관리 특화)
 * 지출 유형별 분류 및 기록, 시설 관리 비용 연동 기능을 제공
 */
@Service
@Transactional
class ExpenseManagementService(
    private val expenseTypeRepository: ExpenseTypeRepository,
    private val expenseRecordRepository: ExpenseRecordRepository,
    private val vendorRepository: VendorRepository,
    private val recurringExpenseScheduleRepository: RecurringExpenseScheduleRepository
) {

    /**
     * 지출 기록 생성
     */
    fun createExpenseRecord(
        companyId: UUID,
        expenseTypeId: UUID,
        vendorId: UUID?,
        amount: BigDecimal,
        expenseDate: LocalDate,
        description: String?,
        invoiceNumber: String?
    ): ExpenseRecord {
        val expenseType = expenseTypeRepository.findById(expenseTypeId)
            .orElseThrow { IllegalArgumentException("지출 유형을 찾을 수 없습니다: $expenseTypeId") }

        val vendor = vendorId?.let { 
            vendorRepository.findById(it)
                .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: $vendorId") }
        }

        val expenseRecord = ExpenseRecord(
            companyId = companyId,
            expenseType = expenseType,
            vendor = vendor,
            amount = amount,
            totalAmount = amount,
            expenseDate = expenseDate,
            description = description,
            invoiceNumber = invoiceNumber,
            status = ExpenseStatus.PENDING,
            approvalStatus = if (expenseType.requiresApproval) ApprovalStatus.PENDING else ApprovalStatus.APPROVED,
            createdBy = companyId // TODO: 실제 사용자 ID로 변경
        )

        return expenseRecordRepository.save(expenseRecord)
    }

    /**
     * 지출 기록 목록 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseRecords(
        companyId: UUID,
        startDate: LocalDate?,
        endDate: LocalDate?,
        expenseTypeId: UUID?,
        vendorId: UUID?,
        status: String?,
        page: Int,
        size: Int
    ): List<ExpenseRecord> {
        val expenseStatus = status?.let { ExpenseStatus.valueOf(it) }
        return expenseRecordRepository.findByCompanyIdAndFilters(
            companyId, startDate, endDate, expenseTypeId, vendorId, expenseStatus
        )
    }

    /**
     * 지출 승인 처리
     */
    fun approveExpense(
        companyId: UUID,
        expenseRecordId: UUID,
        approved: Boolean,
        approvalNotes: String?,
        approvedBy: UUID
    ): ExpenseRecord {
        val expenseRecord = expenseRecordRepository.findById(expenseRecordId)
            .orElseThrow { IllegalArgumentException("지출 기록을 찾을 수 없습니다: $expenseRecordId") }

        if (expenseRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없습니다.")
        }

        val updatedRecord = if (approved) {
            expenseRecord.approve(approvedBy)
        } else {
            expenseRecord.reject()
        }

        return expenseRecordRepository.save(updatedRecord.copy(approvalNotes = approvalNotes))
    }

    /**
     * 승인 대기 목록 조회
     */
    @Transactional(readOnly = true)
    fun getPendingApprovals(companyId: UUID): List<ExpenseRecord> {
        return expenseRecordRepository.findByCompanyIdAndApprovalStatus(companyId, ApprovalStatus.PENDING)
    }

    /**
     * 지출 유형 목록 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseTypes(companyId: UUID): List<ExpenseType> {
        return expenseTypeRepository.findByCompanyIdAndIsActiveTrue(companyId)
    }

    /**
     * 업체 목록 조회
     */
    @Transactional(readOnly = true)
    fun getVendors(companyId: UUID, search: String?): List<Vendor> {
        return if (search.isNullOrBlank()) {
            vendorRepository.findByCompanyIdAndIsActiveTrue(companyId)
        } else {
            vendorRepository.findByCompanyIdAndVendorNameContainingIgnoreCase(companyId, search)
        }
    }

    /**
     * 업체 생성
     */
    fun createVendor(companyId: UUID, request: CreateVendorRequest): Vendor {
        val vendor = Vendor(
            companyId = companyId,
            vendorCode = request.vendorCode,
            vendorName = request.vendorName,
            businessNumber = request.businessNumber,
            contactPerson = request.contactPerson,
            phoneNumber = request.phoneNumber,
            email = request.email
        )

        return vendorRepository.save(vendor)
    }

    /**
     * 정기 지출 생성
     */
    fun createRecurringExpense(companyId: UUID, request: CreateRecurringExpenseRequest): RecurringExpenseSchedule {
        val expenseType = expenseTypeRepository.findById(request.expenseTypeId)
            .orElseThrow { IllegalArgumentException("지출 유형을 찾을 수 없습니다: ${request.expenseTypeId}") }

        val vendor = request.vendorId?.let { 
            vendorRepository.findById(it)
                .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: ${request.vendorId}") }
        }

        val schedule = RecurringExpenseSchedule(
            companyId = companyId,
            expenseType = expenseType,
            vendor = vendor,
            scheduleName = request.description,
            frequency = RecurringExpenseSchedule.Frequency.valueOf(request.recurringPeriod),
            amount = request.amount,
            startDate = request.startDate,
            nextGenerationDate = request.startDate
        )

        return recurringExpenseScheduleRepository.save(schedule)
    }

    /**
     * 정기 지출 목록 조회
     */
    @Transactional(readOnly = true)
    fun getRecurringExpenses(companyId: UUID): List<RecurringExpenseSchedule> {
        return recurringExpenseScheduleRepository.findByCompanyIdAndIsActiveTrue(companyId)
    }

    /**
     * 지출 통계 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseStatistics(companyId: UUID, year: Int?, month: Int?): ExpenseStatisticsResponse {
        // TODO: 실제 통계 계산 로직 구현
        return ExpenseStatisticsResponse(
            totalExpense = BigDecimal.ZERO,
            monthlyExpense = BigDecimal.ZERO,
            yearlyExpense = BigDecimal.ZERO,
            pendingApprovalCount = 0L,
            pendingApprovalAmount = BigDecimal.ZERO,
            expenseByCategory = emptyMap(),
            topExpenseTypes = emptyList()
        )
    }

    /**
     * 지출 대시보드 데이터 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseDashboard(companyId: UUID): ExpenseDashboardResponse {
        // TODO: 실제 대시보드 데이터 계산 로직 구현
        return ExpenseDashboardResponse(
            todayExpense = BigDecimal.ZERO,
            monthlyExpense = BigDecimal.ZERO,
            yearlyExpense = BigDecimal.ZERO,
            pendingApprovalCount = 0L,
            recentExpenses = emptyList()
        )
    }

    /**
     * 예산 대비 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetVsExpense(companyId: UUID, expenseTypeId: UUID?): BudgetVsExpenseResponse {
        // TODO: 실제 예산 대비 지출 계산 로직 구현
        return BudgetVsExpenseResponse(
            budgetAmount = BigDecimal.ZERO,
            actualExpense = BigDecimal.ZERO,
            remainingBudget = BigDecimal.ZERO,
            usagePercentage = 0.0,
            isOverBudget = false
        )
    }

    /**
     * 월별 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getMonthlyExpense(companyId: UUID, year: Int): List<MonthlyExpenseData> {
        // TODO: 실제 월별 지출 계산 로직 구현
        return emptyList()
    }

    /**
     * 업체별 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getVendorExpense(companyId: UUID, year: Int?, month: Int?): List<VendorExpenseData> {
        // TODO: 실제 업체별 지출 계산 로직 구현
        return emptyList()
    }
}