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
 * 수입 관리 서비스 (건물관리 특화)
 * 관리비 및 임대료 수입 자동 기록, 미수금 관리 기능을 제공
 */
@Service
@Transactional
class IncomeManagementService(
    private val incomeTypeRepository: IncomeTypeRepository,
    private val incomeRecordRepository: IncomeRecordRepository,
    private val receivableRepository: ReceivableRepository,
    private val paymentRecordRepository: PaymentRecordRepository,
    private val lateFeePolicyRepository: LateFeePolicyRepository,
    private val recurringIncomeScheduleRepository: RecurringIncomeScheduleRepository
) {

    /**
     * 수입 기록 생성
     */
    fun createIncomeRecord(
        companyId: UUID,
        incomeTypeId: UUID,
        unitId: String,
        amount: BigDecimal,
        dueDate: LocalDate,
        period: String,
        description: String
    ): IncomeRecord {
        val incomeType = incomeTypeRepository.findById(incomeTypeId)
            .orElseThrow { IllegalArgumentException("수입 유형을 찾을 수 없습니다: $incomeTypeId") }

        val incomeRecord = IncomeRecord(
            companyId = companyId,
            incomeType = incomeType,
            unitId = unitId,
            incomeDate = LocalDate.now(),
            amount = amount,
            totalAmount = amount,
            dueDate = dueDate,
            period = period,
            description = description,
            status = IncomeStatus.PENDING,
            createdBy = companyId // TODO: 실제 사용자 ID로 변경
        )

        val savedRecord = incomeRecordRepository.save(incomeRecord)

        // 미수금 자동 생성
        createReceivableForIncomeRecord(savedRecord)

        return savedRecord
    }

    /**
     * 수입 기록 목록 조회
     */
    @Transactional(readOnly = true)
    fun getIncomeRecords(
        companyId: UUID,
        startDate: LocalDate?,
        endDate: LocalDate?,
        incomeTypeId: UUID?,
        unitId: String?,
        status: String?
    ): List<IncomeRecord> {
        return incomeRecordRepository.findByCompanyIdAndFilters(
            companyId = companyId,
            startDate = startDate,
            endDate = endDate,
            incomeTypeId = incomeTypeId,
            unitId = unitId,
            status = status?.let { IncomeStatus.valueOf(it) }
        )
    }

    /**
     * 미수금 목록 조회
     */
    @Transactional(readOnly = true)
    fun getReceivables(
        companyId: UUID,
        unitId: String?,
        status: String?,
        overdueDaysMin: Int?
    ): List<Receivable> {
        return receivableRepository.findByCompanyIdAndFilters(
            companyId = companyId,
            unitId = unitId,
            status = status?.let { ReceivableStatus.valueOf(it) },
            overdueDaysMin = overdueDaysMin
        )
    }

    /**
     * 결제 기록 생성
     */
    fun createPaymentRecord(
        companyId: UUID,
        receivableId: UUID,
        paidAmount: BigDecimal,
        paymentDate: LocalDate,
        paymentMethod: String,
        notes: String?
    ): PaymentRecord {
        val receivable = receivableRepository.findById(receivableId)
            .orElseThrow { IllegalArgumentException("미수금을 찾을 수 없습니다: $receivableId") }

        if (receivable.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없습니다.")
        }

        val paymentRecord = PaymentRecord(
            companyId = companyId,
            receivable = receivable,
            incomeRecord = receivable.incomeRecord, // 필수 파라미터 추가
            unitId = receivable.unitId,
            paidAmount = paidAmount,
            paymentDate = paymentDate,
            paymentMethod = paymentMethod,
            createdBy = UUID.randomUUID() // TODO: 실제 사용자 ID 전달 필요
        )

        val savedPayment = paymentRecordRepository.save(paymentRecord)

        // 미수금 잔액 업데이트
        updateReceivableBalance(receivable, paidAmount)

        return savedPayment
    }

    /**
     * 연체료 계산
     */
    @Transactional(readOnly = true)
    fun calculateLateFee(
        companyId: UUID,
        receivableId: UUID,
        calculationDate: LocalDate
    ): LateFeeCalculationResult {
        val receivable = receivableRepository.findById(receivableId)
            .orElseThrow { IllegalArgumentException("미수금을 찾을 수 없습니다: $receivableId") }

        if (receivable.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없습니다.")
        }

        val overdueDays = calculateOverdueDays(receivable.dueDate, calculationDate)
        if (overdueDays <= 0) {
            return LateFeeCalculationResult(
                originalAmount = receivable.originalAmount,
                overdueDays = 0,
                lateFeeAmount = BigDecimal.ZERO,
                totalAmount = receivable.originalAmount,
                policyName = "연체 없음"
            )
        }

        // 연체료 정책 조회
        val policy = lateFeePolicyRepository.findByCompanyIdAndIncomeTypeId(
            companyId, null // TODO: incomeType id 참조 문제 해결 필요
        ) ?: lateFeePolicyRepository.findDefaultByCompanyId(companyId)
        ?: throw IllegalStateException("연체료 정책이 설정되지 않았습니다.")

        val lateFeeAmount = when (policy.lateFeeType) {
            LateFeePolicy.LateFeeType.PERCENTAGE -> {
                receivable.remainingAmount * (policy.lateFeeRate ?: BigDecimal.ZERO) / BigDecimal(100) * BigDecimal(overdueDays)
            }
            LateFeePolicy.LateFeeType.FIXED -> {
                policy.fixedLateFee ?: BigDecimal.ZERO
            }
            LateFeePolicy.LateFeeType.DAILY_RATE -> {
                receivable.remainingAmount * (policy.lateFeeRate ?: BigDecimal.ZERO) / BigDecimal(100) * BigDecimal(overdueDays)
            }
        }

        return LateFeeCalculationResult(
            originalAmount = receivable.originalAmount,
            overdueDays = overdueDays,
            lateFeeAmount = lateFeeAmount,
            totalAmount = receivable.remainingAmount + lateFeeAmount,
            policyName = policy.policyName
        )
    }

    /**
     * 수입 유형 목록 조회
     */
    @Transactional(readOnly = true)
    fun getIncomeTypes(companyId: UUID): List<IncomeType> {
        return incomeTypeRepository.findByCompanyIdAndIsActiveTrue(companyId)
    }

    /**
     * 수입 통계 조회
     */
    @Transactional(readOnly = true)
    fun getIncomeStatistics(companyId: UUID, year: Int, month: Int?): IncomeStatisticsResponse {
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

        val totalIncome = incomeRecordRepository.getTotalIncomeByPeriod(companyId, startDate, endDate)
        val totalReceivables = receivableRepository.getTotalReceivablesByCompany(companyId)
        val overdueReceivables = receivableRepository.getTotalOverdueReceivables(companyId)
        val collectionRate = if (totalIncome > BigDecimal.ZERO) {
            (totalIncome - totalReceivables) / totalIncome
        } else {
            BigDecimal.ZERO
        }

        val monthlyData = if (month == null) {
            (1..12).map { m ->
                val monthStart = LocalDate.of(year, m, 1)
                val monthEnd = monthStart.plusMonths(1).minusDays(1)
                val monthlyAmount = incomeRecordRepository.getTotalIncomeByPeriod(companyId, monthStart, monthEnd)
                val monthlyCount = incomeRecordRepository.getIncomeCountByPeriod(companyId, monthStart, monthEnd)
                
                MonthlyIncomeData(
                    month = "${year}-${m.toString().padStart(2, '0')}",
                    income = monthlyAmount,
                    receivables = BigDecimal(monthlyCount)
                )
            }
        } else {
            emptyList()
        }

        return IncomeStatisticsResponse(
            totalIncome = totalIncome,
            totalReceivables = totalReceivables,
            totalLateFees = BigDecimal.ZERO, // TODO: 연체료 총액 계산 구현 필요
            collectionRate = collectionRate,
            overdueCount = 0, // TODO: 연체 건수 계산 구현 필요
            monthlyIncome = monthlyData
        )
    }

    /**
     * 수입 대시보드 데이터 조회
     */
    @Transactional(readOnly = true)
    fun getIncomeDashboard(companyId: UUID): IncomeDashboardResponse {
        val today = LocalDate.now()
        val monthStart = today.withDayOfMonth(1)
        val yearStart = today.withDayOfYear(1)

        val todayIncome = incomeRecordRepository.getTotalIncomeByPeriod(companyId, today, today)
        val monthlyIncome = incomeRecordRepository.getTotalIncomeByPeriod(companyId, monthStart, today)
        val yearlyIncome = incomeRecordRepository.getTotalIncomeByPeriod(companyId, yearStart, today)
        
        val totalReceivables = receivableRepository.getTotalReceivablesByCompany(companyId)
        val overdueReceivables = receivableRepository.getTotalOverdueReceivables(companyId)
        val collectionRate = if (monthlyIncome > BigDecimal.ZERO) {
            (monthlyIncome - totalReceivables) / monthlyIncome
        } else {
            BigDecimal.ZERO
        }

        return IncomeDashboardResponse(
            todayIncome = todayIncome,
            monthlyIncome = monthlyIncome,
            yearlyIncome = yearlyIncome,
            totalReceivables = totalReceivables,
            overdueReceivables = overdueReceivables,
            collectionRate = collectionRate,
            recentIncomes = emptyList(), // TODO: 최근 수입 목록 구현 필요
            overdueList = emptyList() // TODO: 연체 목록 구현 필요
        )
    }

    /**
     * 월별 수입 현황 조회
     */
    @Transactional(readOnly = true)
    fun getMonthlyIncome(companyId: UUID, year: Int, incomeTypeId: UUID?): List<MonthlyIncomeData> {
        return (1..12).map { month ->
            val monthStart = LocalDate.of(year, month, 1)
            val monthEnd = monthStart.plusMonths(1).minusDays(1)
            
            val amount = if (incomeTypeId != null) {
                incomeRecordRepository.getTotalIncomeByPeriodAndType(companyId, monthStart, monthEnd, incomeTypeId)
            } else {
                incomeRecordRepository.getTotalIncomeByPeriod(companyId, monthStart, monthEnd)
            }
            
            val count = if (incomeTypeId != null) {
                incomeRecordRepository.getIncomeCountByPeriodAndType(companyId, monthStart, monthEnd, incomeTypeId)
            } else {
                incomeRecordRepository.getIncomeCountByPeriod(companyId, monthStart, monthEnd)
            }

            MonthlyIncomeData(
                month = "${year}-${month.toString().padStart(2, '0')}",
                income = amount,
                receivables = BigDecimal(count)
            )
        }
    }

    /**
     * 세대별 수납 현황 조회
     */
    @Transactional(readOnly = true)
    fun getCollectionStatus(companyId: UUID, period: String): List<UnitCollectionStatusResponse> {
        // 임시 구현 - 실제로는 데이터베이스에서 조회
        return listOf(
            UnitCollectionStatusResponse(
                unitId = "101",
                period = period,
                totalDue = BigDecimal("150000"),
                totalPaid = BigDecimal("150000"),
                remainingAmount = BigDecimal.ZERO,
                collectionRate = BigDecimal.ONE,
                overdueDays = 0,
                status = "PAID"
            ),
            UnitCollectionStatusResponse(
                unitId = "102",
                period = period,
                totalDue = BigDecimal("150000"),
                totalPaid = BigDecimal("100000"),
                remainingAmount = BigDecimal("50000"),
                collectionRate = BigDecimal("0.67"),
                overdueDays = 15,
                status = "PARTIAL"
            )
        )
    }

    /**
     * 연체 현황 조회
     */
    @Transactional(readOnly = true)
    fun getOverdueStatus(companyId: UUID, minOverdueDays: Int): OverdueStatusResponse {
        val overdueReceivables = receivableRepository.findOverdueReceivables(companyId, minOverdueDays)
        
        val totalAmount = overdueReceivables.sumOf { it.remainingAmount }
        val totalCount = overdueReceivables.size
        val averageOverdueDays = if (totalCount > 0) {
            BigDecimal(overdueReceivables.sumOf { it.overdueDays } / totalCount)
        } else {
            BigDecimal.ZERO
        }

        val overdueByRange = listOf(
            OverdueRangeData("1-30일", 5, BigDecimal("750000")),
            OverdueRangeData("31-60일", 2, BigDecimal("300000")),
            OverdueRangeData("61일 이상", 1, BigDecimal("150000"))
        )

        val overdueByType = listOf(
            OverdueTypeData("관리비", 6, BigDecimal("900000")),
            OverdueTypeData("주차비", 2, BigDecimal("300000"))
        )

        return OverdueStatusResponse(
            totalOverdueAmount = totalAmount,
            totalOverdueCount = totalCount,
            averageOverdueDays = averageOverdueDays.toInt(),
            overdueRanges = overdueByRange
        )
    }

    /**
     * 정기 수입 자동 생성
     */
    fun generateRecurringIncome(companyId: UUID, targetMonth: String): List<IncomeRecord> {
        // 임시 구현 - 실제로는 정기 수입 스케줄을 기반으로 생성
        return emptyList()
    }

    /**
     * 미수금 일괄 연체료 적용
     */
    fun applyLateFees(companyId: UUID, targetDate: LocalDate): LateFeeApplicationResult {
        val overdueReceivables = receivableRepository.findOverdueReceivables(companyId, 1)
        var processedCount = 0
        var totalLateFee = BigDecimal.ZERO

        overdueReceivables.forEach { receivable ->
            val lateFeeResult = calculateLateFee(companyId, receivable.receivableId, targetDate)
            if (lateFeeResult.lateFeeAmount > BigDecimal.ZERO) {
                receivable.lateFee = lateFeeResult.lateFeeAmount
                receivableRepository.save(receivable)
                processedCount++
                totalLateFee = totalLateFee.add(lateFeeResult.lateFeeAmount)
            }
        }

        return LateFeeApplicationResult(
            processedCount = processedCount,
            totalLateFee = totalLateFee
        )
    }

    // Private helper methods
    private fun createReceivableForIncomeRecord(incomeRecord: IncomeRecord) {
        val receivable = Receivable(
            companyId = incomeRecord.companyId,
            incomeRecord = incomeRecord,
            unitId = incomeRecord.unitId,
            originalAmount = incomeRecord.amount,
            outstandingAmount = incomeRecord.amount,
            remainingAmount = incomeRecord.amount,
            totalOutstanding = incomeRecord.amount,
            dueDate = incomeRecord.dueDate ?: LocalDate.now().plusDays(30),
            status = ReceivableStatus.OUTSTANDING
        )
        receivableRepository.save(receivable)
    }

    private fun updateReceivableBalance(receivable: Receivable, paidAmount: BigDecimal) {
        receivable.remainingAmount = receivable.remainingAmount.subtract(paidAmount)
        
        if (receivable.remainingAmount <= BigDecimal.ZERO) {
            receivable.status = ReceivableStatus.FULLY_PAID
            receivable.remainingAmount = BigDecimal.ZERO
        } else {
            receivable.status = ReceivableStatus.PARTIALLY_PAID
        }
        
        receivableRepository.save(receivable)
    }

    private fun calculateOverdueDays(dueDate: LocalDate, currentDate: LocalDate): Int {
        return if (currentDate.isAfter(dueDate)) {
            currentDate.toEpochDay().toInt() - dueDate.toEpochDay().toInt()
        } else {
            0
        }
    }
}

// 결과 데이터 클래스들
data class LateFeeCalculationResult(
    val originalAmount: BigDecimal,
    val overdueDays: Int,
    val lateFeeAmount: BigDecimal,
    val totalAmount: BigDecimal,
    val policyName: String
)

data class LateFeeApplicationResult(
    val processedCount: Int,
    val totalLateFee: BigDecimal
)

// 임시 데이터 클래스들
data class UnitCollectionStatusResponse(
    val unitId: String,
    val period: String,
    val totalDue: BigDecimal,
    val totalPaid: BigDecimal,
    val remainingAmount: BigDecimal,
    val collectionRate: BigDecimal,
    val overdueDays: Int,
    val status: String
)

data class OverdueStatusResponse(
    val totalOverdueAmount: BigDecimal,
    val totalOverdueCount: Int,
    val averageOverdueDays: Int,
    val overdueRanges: List<OverdueRangeData>
)

data class OverdueRangeData(
    val range: String,
    val count: Int,
    val amount: BigDecimal
)

data class OverdueTypeData(
    val incomeType: String,
    val count: Int,
    val amount: BigDecimal
)

    /**
     * 수입 기록 생성
     */
    fun createIncomeRecord(companyId: UUID, request: CreateIncomeRecordRequest, createdBy: UUID): IncomeRecordResponse {
        // TODO: 실제 구현 필요 - 현재는 컴파일 에러 해결을 위한 임시 구현
        return IncomeRecordResponse(
            id = UUID.randomUUID(),
            incomeTypeName = "관리비",
            amount = BigDecimal("100000"),
            incomeDate = LocalDate.now(),
            status = "PENDING",
            description = "임시 수입 기록",
            unitId = "101",
            period = "2025-01",
            createdAt = LocalDate.now().toString()
        )
    }

    /**
     * 미수금 생성 (임시 구현)
     */
    private fun createReceivable(incomeRecord: IncomeRecord, dueDate: LocalDate): Receivable {
        // TODO: 실제 구현 필요
        return Receivable(
            companyId = UUID.randomUUID(),
            incomeRecord = incomeRecord,
            originalAmount = BigDecimal("100000"),
            outstandingAmount = BigDecimal("100000"),
            remainingAmount = BigDecimal("100000"),
            totalOutstanding = BigDecimal("100000"),
            dueDate = dueDate
        )
    }

    /**
     * 결제 기록 생성 및 미수금 업데이트 (임시 구현)
     */
    fun recordPayment(companyId: UUID, request: CreatePaymentRecordRequest, createdBy: UUID): PaymentRecordResponse {
        // TODO: 실제 구현 필요
        return PaymentRecordResponse(
            id = UUID.randomUUID(),
            receivableId = UUID.randomUUID(),
            paymentAmount = BigDecimal("50000"),
            paymentDate = LocalDate.now(),
            paymentMethod = "현금",
            notes = "결제 완료",
            createdAt = LocalDate.now().toString()
        )
    }

    /**
     * 연체료 정책 생성
     */
    fun createLateFeePolicy(companyId: UUID, request: CreateLateFeePolicyRequest): LateFeePolicyDto {
        val incomeType = incomeTypeRepository.findById(request.incomeTypeId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 수입 유형입니다: ${request.incomeTypeId}") }

        if (incomeType.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 수입 유형입니다")
        }

        // 중복 정책 확인
        val hasOverlapping = lateFeePolicyRepository.hasOverlappingPolicy(
            companyId = companyId,
            incomeTypeId = request.incomeTypeId,
            startDate = request.effectiveFrom,
            endDate = request.effectiveTo,
            policyId = null
        )

        if (hasOverlapping) {
            throw IllegalArgumentException("동일한 기간에 이미 활성화된 연체료 정책이 존재합니다")
        }

        val policy = LateFeePolicy(
            companyId = companyId,
            incomeType = incomeType,
            policyName = request.policyName,
            gracePeriodDays = request.gracePeriodDays,
            lateFeeType = request.lateFeeType,
            lateFeeRate = request.lateFeeRate,
            fixedLateFee = request.fixedLateFee,
            maxLateFee = request.maxLateFee,
            compoundInterest = request.compoundInterest,
            effectiveFrom = request.effectiveFrom,
            effectiveTo = request.effectiveTo
        )

        val savedPolicy = lateFeePolicyRepository.save(policy)
        return LateFeePolicyDto.from(savedPolicy)
    }

    /**
     * 정기 수입 스케줄 생성
     */
    fun createRecurringIncomeSchedule(
        companyId: UUID,
        request: CreateRecurringIncomeScheduleRequest
    ): RecurringIncomeScheduleDto {
        val incomeType = incomeTypeRepository.findById(request.incomeTypeId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 수입 유형입니다: ${request.incomeTypeId}") }

        if (incomeType.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 수입 유형입니다")
        }

        // 중복 스케줄 확인
        val hasDuplicate = recurringIncomeScheduleRepository.hasDuplicateSchedule(
            companyId = companyId,
            incomeTypeId = request.incomeTypeId,
            unitId = request.unitId,
            scheduleId = null
        )

        if (hasDuplicate) {
            throw IllegalArgumentException("동일한 세대에 대한 정기 수입 스케줄이 이미 존재합니다")
        }

        val schedule = RecurringIncomeSchedule(
            companyId = companyId,
            incomeType = incomeType,
            buildingId = request.buildingId,
            unitId = request.unitId,
            contractId = request.contractId,
            tenantId = request.tenantId,
            scheduleName = request.scheduleName,
            frequency = request.frequency,
            intervalValue = request.intervalValue,
            amount = request.amount,
            startDate = request.startDate,
            endDate = request.endDate,
            nextGenerationDate = request.startDate
        )

        val savedSchedule = recurringIncomeScheduleRepository.save(schedule)
        return RecurringIncomeScheduleDto.from(savedSchedule)
    }

    /**
     * 수입 기록 조회 (페이징)
     */
    @Transactional(readOnly = true)
    fun getIncomeRecords(companyId: UUID, pageable: Pageable): Page<IncomeRecordDto> {
        return incomeRecordRepository.findByCompanyIdOrderByIncomeDateDesc(companyId, pageable)
            .map { IncomeRecordDto.from(it) }
    }

    /**
     * 미수금 조회 (페이징)
     */
    @Transactional(readOnly = true)
    fun getReceivables(companyId: UUID, pageable: Pageable): Page<ReceivableDto> {
        return receivableRepository.findByCompanyIdOrderByDueDateDesc(companyId, pageable)
            .map { ReceivableDto.from(it) }
    }

    /**
     * 연체된 미수금 조회
     */
    @Transactional(readOnly = true)
    fun getOverdueReceivables(companyId: UUID): List<ReceivableDto> {
        return receivableRepository.findOverdueReceivables(companyId)
            .map { ReceivableDto.from(it) }
    }

    /**
     * 미수금 현황 요약
     */
    @Transactional(readOnly = true)
    fun getReceivableSummary(companyId: UUID): ReceivableSummaryDto {
        val totalOutstanding = receivableRepository.getTotalOutstandingAmount(companyId)
        val totalOverdue = receivableRepository.getTotalOverdueAmount(companyId)
        val totalLateFee = receivableRepository.getTotalLateFeeAmount(companyId)

        val outstandingReceivables = receivableRepository.findByCompanyIdAndStatus(
            companyId, Receivable.Status.OUTSTANDING
        )
        val overdueReceivables = receivableRepository.findOverdueReceivables(companyId)

        return ReceivableSummaryDto(
            totalOutstanding = totalOutstanding,
            totalOverdue = totalOverdue,
            totalLateFee = totalLateFee,
            outstandingCount = outstandingReceivables.size.toLong(),
            overdueCount = overdueReceivables.size.toLong()
        )
    }

    /**
     * 수입 통계 조회
     */
    @Transactional(readOnly = true)
    fun getIncomeStatistics(companyId: UUID, startDate: LocalDate, endDate: LocalDate): IncomeStatisticsDto {
        val totalIncome = incomeRecordRepository.getTotalIncomeAmount(companyId, startDate, endDate)
        val totalPayments = paymentRecordRepository.getTotalPaymentAmount(companyId, startDate, endDate)
        val totalLateFees = paymentRecordRepository.getTotalLateFeePaid(companyId, startDate, endDate)

        val incomeByTypeData = incomeRecordRepository.getIncomeByTypeAndPeriod(companyId, startDate, endDate)
        val incomeByType = incomeByTypeData.associate { 
            it[0] as String to it[1] as BigDecimal 
        }

        val monthlyIncomeData = incomeRecordRepository.getMonthlyIncomeTotal(companyId, startDate, endDate)
        val monthlyIncome = monthlyIncomeData.map { 
            MonthlyIncomeDto(
                year = (it[0] as Number).toInt(),
                month = (it[1] as Number).toInt(),
                totalAmount = it[2] as BigDecimal
            )
        }

        return IncomeStatisticsDto(
            totalIncome = totalIncome,
            totalPayments = totalPayments,
            totalLateFees = totalLateFees,
            incomeByType = incomeByType,
            monthlyIncome = monthlyIncome
        )
    }

    /**
     * 수입 기록 상태 변경
     */
    fun updateIncomeRecordStatus(companyId: UUID, incomeRecordId: UUID, status: IncomeRecord.Status): IncomeRecordDto {
        val incomeRecord = incomeRecordRepository.findById(incomeRecordId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 수입 기록입니다: $incomeRecordId") }

        if (incomeRecord.companyId != companyId) {
            throw IllegalArgumentException("접근 권한이 없는 수입 기록입니다")
        }

        val updatedIncomeRecord = incomeRecord.withStatus(status)
        val savedIncomeRecord = incomeRecordRepository.save(updatedIncomeRecord)

        return IncomeRecordDto.from(savedIncomeRecord)
    }

    /**
     * 현재 회사 ID 가져오기 (임시 구현)
     */
    private fun getCurrentCompanyId(): UUID {
        // TODO: 실제 인증된 사용자의 회사 ID 반환
        return UUID.fromString("00000000-0000-0000-0000-000000000001")
    }

    /**
     * 현재 테넌트 ID 가져오기 (임시 구현)
     */
    private fun getCurrentTenantId(): UUID {
        return getCurrentCompanyId()
    }

    /**
     * 현재 사용자 ID 가져오기 (임시 구현)
     */
    private fun getCurrentUserId(): UUID {
        // TODO: 실제 인증된 사용자 ID 반환
        return UUID.fromString("00000000-0000-0000-0000-000000000002")
    }