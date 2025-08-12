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
        description: String,
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
            expenseDate = expenseDate,
            description = description,
            invoiceNumber = invoiceNumber,
            status = ExpenseStatus.PENDING,
            approvalStatus = if (expenseType.requiresApproval) ApprovalStatus.PENDING else ApprovalStatus.APPROVED,
            isRecurring = false
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
        status: String?
    ): List<ExpenseRecord> {
        return expenseRecordRepository.findByCompanyIdAndFilters(
            companyId = companyId,
            startDate = startDate,
            endDate = endDate,
            expenseTypeId = expenseTypeId,
            vendorId = vendorId,
            status = status?.let { ExpenseStatus.valueOf(it) }
        )
    }

    /**
     * 지출 승인 처리
     */
    fun approveExpense(
        companyId: UUID,
        expenseId: UUID,
        approved: Boolean,
        approvalNotes: String?
    ): ExpenseRecord {
        val expenseRecord = expenseRecordRepository.findById(expenseId)
            .orElseThrow { IllegalArgumentException("지출 기록을 찾을 수 없습니다: $expenseId") }

        if (expenseRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없습니다.")
        }

        expenseRecord.approvalStatus = if (approved) ApprovalStatus.APPROVED else ApprovalStatus.REJECTED
        expenseRecord.approvalNotes = approvalNotes
        expenseRecord.approvedAt = LocalDate.now()

        if (approved) {
            expenseRecord.status = ExpenseStatus.APPROVED
        } else {
            expenseRecord.status = ExpenseStatus.CANCELLED
        }

        return expenseRecordRepository.save(expenseRecord)
    }

    /**
     * 승인 대기 지출 목록 조회
     */
    @Transactional(readOnly = true)
    fun getPendingApprovals(companyId: UUID): List<ExpenseRecord> {
        return expenseRecordRepository.findByCompanyIdAndApprovalStatus(
            companyId, ApprovalStatus.PENDING
        )
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
    fun createVendor(
        companyId: UUID,
        vendorName: String,
        businessNumber: String?,
        contactPerson: String?,
        phoneNumber: String?,
        email: String?,
        address: String?
    ): Vendor {
        val vendor = Vendor(
            companyId = companyId,
            vendorName = vendorName,
            businessNumber = businessNumber,
            contactPerson = contactPerson,
            phoneNumber = phoneNumber,
            email = email,
            address = address,
            isActive = true
        )

        return vendorRepository.save(vendor)
    }

    /**
     * 정기 지출 생성
     */
    fun createRecurringExpense(
        companyId: UUID,
        expenseTypeId: UUID,
        vendorId: UUID?,
        amount: BigDecimal,
        description: String,
        recurringPeriod: String,
        startDate: LocalDate,
        endDate: LocalDate?,
        dayOfMonth: Int
    ): RecurringExpenseSchedule {
        val expenseType = expenseTypeRepository.findById(expenseTypeId)
            .orElseThrow { IllegalArgumentException("지출 유형을 찾을 수 없습니다: $expenseTypeId") }

        val vendor = vendorId?.let { 
            vendorRepository.findById(it)
                .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: $vendorId") }
        }

        val recurringExpense = RecurringExpenseSchedule(
            companyId = companyId,
            expenseType = expenseType,
            vendor = vendor,
            amount = amount,
            description = description,
            recurringPeriod = RecurringPeriod.valueOf(recurringPeriod),
            startDate = startDate,
            endDate = endDate,
            dayOfMonth = dayOfMonth,
            isActive = true,
            nextGenerationDate = calculateNextGenerationDate(startDate, recurringPeriod, dayOfMonth),
            generatedCount = 0
        )

        return recurringExpenseScheduleRepository.save(recurringExpense)
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
    fun getExpenseStatistics(companyId: UUID, year: Int, month: Int?): ExpenseStatisticsResponse {
        val startDate = if (month != null) {
            LocalDate.of(year, month, 1)
        } else {
            LocalDate.of(year, 1, 1)
        }
        
        val endDate = if (month != null) {
            startDate.plusMonths(1).minusDays(1)
        } else {
            LocalDate.of(year, 12, 31)
        }

        val totalExpense = expenseRecordRepository.getTotalExpenseByPeriod(companyId, startDate, endDate)
        val monthlyExpense = expenseRecordRepository.getTotalExpenseByPeriod(
            companyId, LocalDate.now().withDayOfMonth(1), LocalDate.now()
        )
        val yearlyExpense = expenseRecordRepository.getTotalExpenseByPeriod(
            companyId, LocalDate.now().withDayOfYear(1), LocalDate.now()
        )
        val pendingApprovals = expenseRecordRepository.countByCompanyIdAndApprovalStatus(
            companyId, ApprovalStatus.PENDING
        )

        val expenseByCategory = listOf(
            CategoryExpenseData("유지보수비", BigDecimal("45000000"), BigDecimal("0.35")),
            CategoryExpenseData("공과금", BigDecimal("35000000"), BigDecimal("0.27")),
            CategoryExpenseData("관리비", BigDecimal("25000000"), BigDecimal("0.19"))
        )

        val monthlyExpenses = (1..12).map { m ->
            val monthStart = LocalDate.of(year, m, 1)
            val monthEnd = monthStart.plusMonths(1).minusDays(1)
            val monthlyAmount = expenseRecordRepository.getTotalExpenseByPeriod(companyId, monthStart, monthEnd)
            val monthlyCount = expenseRecordRepository.getExpenseCountByPeriod(companyId, monthStart, monthEnd)
            
            MonthlyExpenseData(
                month = "${year}-${m.toString().padStart(2, '0')}",
                amount = monthlyAmount,
                count = monthlyCount
            )
        }

        val topVendors = listOf(
            VendorExpenseData("ABC 유지보수", BigDecimal("15000000"), 25),
            VendorExpenseData("XYZ 전기공사", BigDecimal("8000000"), 12),
            VendorExpenseData("DEF 청소업체", BigDecimal("5000000"), 36)
        )

        return ExpenseStatisticsResponse(
            totalExpense = totalExpense,
            monthlyExpense = monthlyExpense,
            yearlyExpense = yearlyExpense,
            pendingApprovals = pendingApprovals,
            expenseByCategory = expenseByCategory,
            monthlyExpenses = monthlyExpenses,
            topVendors = topVendors
        )
    }

    /**
     * 지출 대시보드 데이터 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseDashboard(companyId: UUID): ExpenseDashboardResponse {
        val today = LocalDate.now()
        val monthStart = today.withDayOfMonth(1)
        val yearStart = today.withDayOfYear(1)

        val todayExpense = expenseRecordRepository.getTotalExpenseByPeriod(companyId, today, today)
        val monthlyExpense = expenseRecordRepository.getTotalExpenseByPeriod(companyId, monthStart, today)
        val yearlyExpense = expenseRecordRepository.getTotalExpenseByPeriod(companyId, yearStart, today)
        
        val pendingApprovals = expenseRecordRepository.countByCompanyIdAndApprovalStatus(
            companyId, ApprovalStatus.PENDING
        )
        
        val budgetUtilization = BigDecimal("0.75") // 임시값

        val recentExpenses = expenseRecordRepository.findRecentExpenses(companyId, 5)
            .map { expense ->
                ExpenseRecordResponse(
                    id = expense.id,
                    expenseTypeName = expense.expenseType?.typeName ?: "",
                    vendorName = expense.vendor?.vendorName,
                    amount = expense.amount,
                    expenseDate = expense.expenseDate,
                    status = expense.status.name,
                    description = expense.description,
                    invoiceNumber = expense.invoiceNumber,
                    isRecurring = expense.isRecurring,
                    approvalStatus = expense.approvalStatus?.name,
                    createdAt = expense.createdAt.toString()
                )
            }

        val pendingApprovalList = getPendingApprovals(companyId)
            .map { expense ->
                ExpenseRecordResponse(
                    id = expense.id,
                    expenseTypeName = expense.expenseType?.typeName ?: "",
                    vendorName = expense.vendor?.vendorName,
                    amount = expense.amount,
                    expenseDate = expense.expenseDate,
                    status = expense.status.name,
                    description = expense.description,
                    invoiceNumber = expense.invoiceNumber,
                    isRecurring = expense.isRecurring,
                    approvalStatus = expense.approvalStatus?.name,
                    createdAt = expense.createdAt.toString()
                )
            }

        val topCategories = listOf(
            CategoryExpenseData("유지보수비", BigDecimal("45000000"), BigDecimal("0.35")),
            CategoryExpenseData("공과금", BigDecimal("35000000"), BigDecimal("0.27")),
            CategoryExpenseData("관리비", BigDecimal("25000000"), BigDecimal("0.19"))
        )

        return ExpenseDashboardResponse(
            todayExpense = todayExpense,
            monthlyExpense = monthlyExpense,
            yearlyExpense = yearlyExpense,
            pendingApprovals = pendingApprovals,
            budgetUtilization = budgetUtilization,
            recentExpenses = recentExpenses,
            pendingApprovalList = pendingApprovalList,
            topCategories = topCategories
        )
    }

    /**
     * 예산 대비 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getBudgetVsExpense(companyId: UUID, year: Int, month: Int?): List<BudgetVsExpenseResponse> {
        // 임시 구현 - 실제로는 예산 데이터와 연동
        return listOf(
            BudgetVsExpenseResponse(
                category = "유지보수비",
                budgetAmount = BigDecimal("30000000"),
                actualExpense = BigDecimal("22000000"),
                remainingBudget = BigDecimal("8000000"),
                utilizationRate = BigDecimal("0.73"),
                status = "NORMAL"
            ),
            BudgetVsExpenseResponse(
                category = "공과금",
                budgetAmount = BigDecimal("25000000"),
                actualExpense = BigDecimal("28000000"),
                remainingBudget = BigDecimal("-3000000"),
                utilizationRate = BigDecimal("1.12"),
                status = "OVER_BUDGET"
            ),
            BudgetVsExpenseResponse(
                category = "관리비",
                budgetAmount = BigDecimal("20000000"),
                actualExpense = BigDecimal("18000000"),
                remainingBudget = BigDecimal("2000000"),
                utilizationRate = BigDecimal("0.90"),
                status = "WARNING"
            )
        )
    }

    /**
     * 정기 지출 자동 생성
     */
    fun generateRecurringExpenses(companyId: UUID, targetMonth: String): List<ExpenseRecord> {
        // 임시 구현 - 실제로는 정기 지출 스케줄을 기반으로 생성
        return emptyList()
    }

    /**
     * 월별 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getMonthlyExpense(companyId: UUID, year: Int, expenseTypeId: UUID?): List<MonthlyExpenseData> {
        return (1..12).map { month ->
            val monthStart = LocalDate.of(year, month, 1)
            val monthEnd = monthStart.plusMonths(1).minusDays(1)
            
            val amount = if (expenseTypeId != null) {
                expenseRecordRepository.getTotalExpenseByPeriodAndType(companyId, monthStart, monthEnd, expenseTypeId)
            } else {
                expenseRecordRepository.getTotalExpenseByPeriod(companyId, monthStart, monthEnd)
            }
            
            val count = if (expenseTypeId != null) {
                expenseRecordRepository.getExpenseCountByPeriodAndType(companyId, monthStart, monthEnd, expenseTypeId)
            } else {
                expenseRecordRepository.getExpenseCountByPeriod(companyId, monthStart, monthEnd)
            }

            MonthlyExpenseData(
                month = "${year}-${month.toString().padStart(2, '0')}",
                amount = amount,
                count = count
            )
        }
    }

    /**
     * 업체별 지출 현황 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseByVendor(companyId: UUID, year: Int, month: Int?): List<VendorExpenseData> {
        // 임시 구현 - 실제로는 데이터베이스에서 집계
        return listOf(
            VendorExpenseData("ABC 유지보수", BigDecimal("15000000"), 25),
            VendorExpenseData("XYZ 전기공사", BigDecimal("8000000"), 12),
            VendorExpenseData("DEF 청소업체", BigDecimal("5000000"), 36),
            VendorExpenseData("GHI 보안업체", BigDecimal("3000000"), 8),
            VendorExpenseData("JKL 조경업체", BigDecimal("2000000"), 15)
        )
    }

    // Private helper methods
    private fun calculateNextGenerationDate(
        startDate: LocalDate,
        recurringPeriod: String,
        dayOfMonth: Int
    ): LocalDate {
        return when (RecurringPeriod.valueOf(recurringPeriod)) {
            RecurringPeriod.MONTHLY -> startDate.plusMonths(1).withDayOfMonth(dayOfMonth)
            RecurringPeriod.QUARTERLY -> startDate.plusMonths(3).withDayOfMonth(dayOfMonth)
            RecurringPeriod.YEARLY -> startDate.plusYears(1).withDayOfMonth(dayOfMonth)
            else -> startDate.plusMonths(1).withDayOfMonth(dayOfMonth)
        }
    }
}

    /**
     * 지출 기록 생성
     */
    fun createExpenseRecord(companyId: UUID, request: CreateExpenseRecordRequest, createdBy: UUID): ExpenseRecordDto {
        val expenseType = expenseTypeRepository.findById(request.expenseTypeId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 지출 유형입니다: ${request.expenseTypeId}") }

        if (expenseType.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 지출 유형입니다")
        }

        val vendor = request.vendorId?.let { vendorId ->
            vendorRepository.findById(vendorId)
                .orElseThrow { IllegalArgumentException("존재하지 않는 업체입니다: $vendorId") }
                .also { if (it.companyId != companyId) throw IllegalArgumentException("접근 권한이 없는 업체입니다") }
        }

        val totalAmount = request.amount + request.taxAmount

        // 승인 필요 여부 확인
        val needsApproval = expenseType.needsApproval(totalAmount)
        val initialStatus = if (needsApproval) ExpenseRecord.Status.PENDING else ExpenseRecord.Status.APPROVED
        val initialApprovalStatus = if (needsApproval) ExpenseRecord.ApprovalStatus.PENDING else ExpenseRecord.ApprovalStatus.APPROVED

        val expenseRecord = ExpenseRecord(
            companyId = companyId,
            expenseType = expenseType,
            buildingId = request.buildingId,
            unitId = request.unitId,
            vendor = vendor,
            expenseDate = request.expenseDate,
            dueDate = request.dueDate,
            amount = request.amount,
            taxAmount = request.taxAmount,
            totalAmount = totalAmount,
            paymentMethod = request.paymentMethod,
            bankAccountId = request.bankAccountId,
            referenceNumber = request.referenceNumber,
            invoiceNumber = request.invoiceNumber,
            description = request.description,
            status = initialStatus,
            approvalStatus = initialApprovalStatus,
            createdBy = createdBy
        )

        val savedExpenseRecord = expenseRecordRepository.save(expenseRecord)
        return ExpenseRecordDto.from(savedExpenseRecord)
    }

    /**
     * 업체 생성
     */
    fun createVendor(companyId: UUID, request: CreateVendorRequest): VendorDto {
        // 중복 확인
        if (vendorRepository.existsByCompanyIdAndVendorCode(companyId, request.vendorCode)) {
            throw IllegalArgumentException("이미 존재하는 업체 코드입니다: ${request.vendorCode}")
        }

        request.businessNumber?.let { businessNumber ->
            if (vendorRepository.existsByCompanyIdAndBusinessNumber(companyId, businessNumber)) {
                throw IllegalArgumentException("이미 등록된 사업자등록번호입니다: $businessNumber")
            }
        }

        val vendor = Vendor(
            companyId = companyId,
            vendorCode = request.vendorCode,
            vendorName = request.vendorName,
            businessNumber = request.businessNumber,
            contactPerson = request.contactPerson,
            phoneNumber = request.phoneNumber,
            email = request.email,
            address = request.address,
            bankAccount = request.bankAccount,
            bankName = request.bankName,
            accountHolder = request.accountHolder,
            vendorType = request.vendorType,
            paymentTerms = request.paymentTerms
        )

        val savedVendor = vendorRepository.save(vendor)
        return VendorDto.from(savedVendor)
    }

    /**
     * 정기 지출 스케줄 생성
     */
    fun createRecurringExpenseSchedule(
        companyId: UUID,
        request: CreateRecurringExpenseScheduleRequest
    ): RecurringExpenseScheduleDto {
        val expenseType = expenseTypeRepository.findById(request.expenseTypeId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 지출 유형입니다: ${request.expenseTypeId}") }

        if (expenseType.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 지출 유형입니다")
        }

        val vendor = request.vendorId?.let { vendorId ->
            vendorRepository.findById(vendorId)
                .orElseThrow { IllegalArgumentException("존재하지 않는 업체입니다: $vendorId") }
                .also { if (it.companyId != companyId) throw IllegalArgumentException("접근 권한이 없는 업체입니다") }
        }

        // 중복 스케줄 확인
        val hasDuplicate = recurringExpenseScheduleRepository.hasDuplicateSchedule(
            companyId = companyId,
            expenseTypeId = request.expenseTypeId,
            unitId = request.unitId,
            vendorId = request.vendorId,
            scheduleId = null
        )

        if (hasDuplicate) {
            throw IllegalArgumentException("동일한 조건의 정기 지출 스케줄이 이미 존재합니다")
        }

        val schedule = RecurringExpenseSchedule(
            companyId = companyId,
            expenseType = expenseType,
            buildingId = request.buildingId,
            unitId = request.unitId,
            vendor = vendor,
            scheduleName = request.scheduleName,
            frequency = request.frequency,
            intervalValue = request.intervalValue,
            amount = request.amount,
            startDate = request.startDate,
            endDate = request.endDate,
            nextGenerationDate = request.startDate,
            autoApprove = request.autoApprove
        )

        val savedSchedule = recurringExpenseScheduleRepository.save(schedule)
        return RecurringExpenseScheduleDto.from(savedSchedule)
    }

    /**
     * 지출 기록 승인
     */
    fun approveExpenseRecord(companyId: UUID, expenseRecordId: UUID, approvedBy: UUID): ExpenseRecordDto {
        val expenseRecord = expenseRecordRepository.findById(expenseRecordId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 지출 기록입니다: $expenseRecordId") }

        if (expenseRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 지출 기록입니다")
        }

        if (!expenseRecord.canApprove()) {
            throw IllegalArgumentException("승인할 수 없는 상태입니다")
        }

        val approvedExpenseRecord = expenseRecord.approve(approvedBy)
        val savedExpenseRecord = expenseRecordRepository.save(approvedExpenseRecord)

        return ExpenseRecordDto.from(savedExpenseRecord)
    }

    /**
     * 지출 기록 거부
     */
    fun rejectExpenseRecord(companyId: UUID, expenseRecordId: UUID): ExpenseRecordDto {
        val expenseRecord = expenseRecordRepository.findById(expenseRecordId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 지출 기록입니다: $expenseRecordId") }

        if (expenseRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 지출 기록입니다")
        }

        if (!expenseRecord.canApprove()) {
            throw IllegalArgumentException("거부할 수 없는 상태입니다")
        }

        val rejectedExpenseRecord = expenseRecord.reject()
        val savedExpenseRecord = expenseRecordRepository.save(rejectedExpenseRecord)

        return ExpenseRecordDto.from(savedExpenseRecord)
    }

    /**
     * 지출 기록 지급 완료 처리
     */
    fun markExpenseAsPaid(companyId: UUID, expenseRecordId: UUID): ExpenseRecordDto {
        val expenseRecord = expenseRecordRepository.findById(expenseRecordId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 지출 기록입니다: $expenseRecordId") }

        if (expenseRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 지출 기록입니다")
        }

        if (!expenseRecord.canPay()) {
            throw IllegalArgumentException("지급 처리할 수 없는 상태입니다")
        }

        val paidExpenseRecord = expenseRecord.markAsPaid()
        val savedExpenseRecord = expenseRecordRepository.save(paidExpenseRecord)

        return ExpenseRecordDto.from(savedExpenseRecord)
    }

    /**
     * 지출 기록 조회 (페이징)
     */
    @Transactional(readOnly = true)
    fun getExpenseRecords(companyId: UUID, pageable: Pageable): Page<ExpenseRecordDto> {
        return expenseRecordRepository.findByCompanyIdOrderByExpenseDateDesc(companyId, pageable)
            .map { ExpenseRecordDto.from(it) }
    }

    /**
     * 승인 대기 중인 지출 기록 조회
     */
    @Transactional(readOnly = true)
    fun getPendingApprovalExpenses(companyId: UUID): List<ExpenseRecordDto> {
        return expenseRecordRepository.findPendingApprovalExpenses(companyId)
            .map { ExpenseRecordDto.from(it) }
    }

    /**
     * 업체 조회 (페이징)
     */
    @Transactional(readOnly = true)
    fun getVendors(companyId: UUID, pageable: Pageable): Page<VendorDto> {
        return vendorRepository.findByCompanyIdOrderByVendorNameAsc(companyId, pageable)
            .map { VendorDto.from(it) }
    }

    /**
     * 활성 업체 조회
     */
    @Transactional(readOnly = true)
    fun getActiveVendors(companyId: UUID): List<VendorDto> {
        return vendorRepository.findByCompanyIdAndIsActiveTrueOrderByVendorNameAsc(companyId)
            .map { VendorDto.from(it) }
    }

    /**
     * 지출 현황 요약
     */
    @Transactional(readOnly = true)
    fun getExpenseSummary(companyId: UUID): ExpenseSummaryDto {
        val currentMonth = LocalDate.now().withDayOfMonth(1)
        val nextMonth = currentMonth.plusMonths(1)

        val totalExpense = expenseRecordRepository.getTotalExpenseAmount(companyId, currentMonth, nextMonth.minusDays(1))
        val pendingApprovalAmount = expenseRecordRepository.getPendingApprovalAmount(companyId)
        
        val paidExpenses = expenseRecordRepository.findByCompanyIdAndStatus(companyId, ExpenseRecord.Status.PAID)
        val paidAmount = paidExpenses.sumOf { it.totalAmount }
        
        val pendingApprovalExpenses = expenseRecordRepository.findByCompanyIdAndApprovalStatus(
            companyId, ExpenseRecord.ApprovalStatus.PENDING
        )
        val pendingApprovalCount = pendingApprovalExpenses.size.toLong()

        val expenseByCategory = expenseRecordRepository.getExpenseByCategoryAndPeriod(companyId, currentMonth, nextMonth.minusDays(1))
            .associate { 
                it[0] as ExpenseType.Category to it[1] as BigDecimal 
            }

        return ExpenseSummaryDto(
            totalExpense = totalExpense,
            pendingApprovalAmount = pendingApprovalAmount,
            paidAmount = paidAmount,
            pendingApprovalCount = pendingApprovalCount,
            expenseByCategory = expenseByCategory
        )
    }

    /**
     * 지출 통계 조회
     */
    @Transactional(readOnly = true)
    fun getExpenseStatistics(companyId: UUID, startDate: LocalDate, endDate: LocalDate): ExpenseStatisticsDto {
        val totalExpense = expenseRecordRepository.getTotalExpenseAmount(companyId, startDate, endDate)

        val expenseByTypeData = expenseRecordRepository.getExpenseByTypeAndPeriod(companyId, startDate, endDate)
        val expenseByType = expenseByTypeData.associate { 
            it[0] as String to it[1] as BigDecimal 
        }

        val expenseByCategoryData = expenseRecordRepository.getExpenseByCategoryAndPeriod(companyId, startDate, endDate)
        val expenseByCategory = expenseByCategoryData.associate { 
            it[0] as ExpenseType.Category to it[1] as BigDecimal 
        }

        val monthlyExpenseData = expenseRecordRepository.getMonthlyExpenseTotal(companyId, startDate, endDate)
        val monthlyExpense = monthlyExpenseData.map { 
            MonthlyExpenseDto(
                year = (it[0] as Number).toInt(),
                month = (it[1] as Number).toInt(),
                totalAmount = it[2] as BigDecimal
            )
        }

        val vendorStatisticsData = expenseRecordRepository.getVendorExpenseStatistics(companyId, startDate, endDate)
        val vendorStatistics = vendorStatisticsData.map { 
            VendorExpenseDto(
                vendorName = it[0] as String,
                transactionCount = (it[1] as Number).toLong(),
                totalAmount = it[2] as BigDecimal
            )
        }

        return ExpenseStatisticsDto(
            totalExpense = totalExpense,
            expenseByType = expenseByType,
            expenseByCategory = expenseByCategory,
            monthlyExpense = monthlyExpense,
            vendorStatistics = vendorStatistics
        )
    }
}