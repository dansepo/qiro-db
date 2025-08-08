package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 세무 관리 서비스
 * 부가세, 원천징수, 세금계산서 등 세무 업무를 통합 관리합니다.
 */
@Service
@Transactional
class TaxManagementService(
    private val taxPeriodRepository: TaxPeriodRepository,
    private val withholdingTaxRepository: WithholdingTaxRepository,
    private val taxInvoiceRepository: TaxInvoiceRepository,
    private val taxScheduleRepository: TaxScheduleRepository,
    private val taxDocumentRepository: TaxDocumentRepository
) {

    /**
     * 세무 기간 생성
     */
    fun createTaxPeriod(
        companyId: UUID,
        periodType: TaxPeriod.PeriodType,
        taxType: TaxPeriod.TaxType,
        periodYear: Int,
        periodMonth: Int? = null,
        periodQuarter: Int? = null,
        startDate: LocalDate,
        endDate: LocalDate,
        dueDate: LocalDate
    ): TaxPeriod {
        val taxPeriod = TaxPeriod(
            companyId = companyId,
            periodType = periodType,
            taxType = taxType,
            periodYear = periodYear,
            periodMonth = periodMonth,
            periodQuarter = periodQuarter,
            startDate = startDate,
            endDate = endDate,
            dueDate = dueDate
        )
        return taxPeriodRepository.save(taxPeriod)
    }

    /**
     * 연간 세무 기간 자동 생성
     */
    fun generateAnnualTaxPeriods(companyId: UUID, year: Int): List<TaxPeriod> {
        val taxPeriods = mutableListOf<TaxPeriod>()

        // 분기별 부가세 신고 기간 생성
        for (quarter in 1..4) {
            val (startDate, endDate, dueDate) = getQuarterDates(year, quarter)
            val vatPeriod = createTaxPeriod(
                companyId = companyId,
                periodType = TaxPeriod.PeriodType.QUARTERLY,
                taxType = TaxPeriod.TaxType.VAT,
                periodYear = year,
                periodQuarter = quarter,
                startDate = startDate,
                endDate = endDate,
                dueDate = dueDate
            )
            taxPeriods.add(vatPeriod)
        }

        // 월별 원천징수 신고 기간 생성
        for (month in 1..12) {
            val startDate = LocalDate.of(year, month, 1)
            val endDate = startDate.withDayOfMonth(startDate.lengthOfMonth())
            val dueDate = if (month == 12) {
                LocalDate.of(year + 1, 1, 10)
            } else {
                LocalDate.of(year, month + 1, 10)
            }

            val withholdingPeriod = createTaxPeriod(
                companyId = companyId,
                periodType = TaxPeriod.PeriodType.MONTHLY,
                taxType = TaxPeriod.TaxType.WITHHOLDING,
                periodYear = year,
                periodMonth = month,
                startDate = startDate,
                endDate = endDate,
                dueDate = dueDate
            )
            taxPeriods.add(withholdingPeriod)
        }

        return taxPeriods
    }

    /**
     * 원천징수 내역 생성
     */
    fun createWithholdingTax(
        companyId: UUID,
        paymentDate: LocalDate,
        payeeName: String,
        payeeRegistrationNumber: String?,
        incomeType: WithholdingTax.IncomeType,
        incomeAmount: BigDecimal,
        taxRate: BigDecimal,
        notes: String? = null
    ): WithholdingTax {
        val withholdingAmount = incomeAmount.multiply(taxRate)
        
        val withholdingTax = WithholdingTax(
            companyId = companyId,
            paymentDate = paymentDate,
            payeeName = payeeName,
            payeeRegistrationNumber = payeeRegistrationNumber,
            incomeType = incomeType,
            incomeAmount = incomeAmount,
            taxRate = taxRate,
            withholdingAmount = withholdingAmount,
            notes = notes
        )
        
        return withholdingTaxRepository.save(withholdingTax)
    }

    /**
     * 세금계산서 생성
     */
    fun createTaxInvoice(
        companyId: UUID,
        invoiceType: TaxInvoice.InvoiceType,
        invoiceNumber: String,
        issueDate: LocalDate,
        supplierName: String,
        supplierRegistrationNumber: String,
        buyerName: String,
        buyerRegistrationNumber: String,
        supplyAmount: BigDecimal,
        vatAmount: BigDecimal,
        itemDescription: String? = null
    ): TaxInvoice {
        val totalAmount = supplyAmount.add(vatAmount)
        
        val taxInvoice = TaxInvoice(
            companyId = companyId,
            invoiceType = invoiceType,
            invoiceNumber = invoiceNumber,
            issueDate = issueDate,
            supplierName = supplierName,
            supplierRegistrationNumber = supplierRegistrationNumber,
            buyerName = buyerName,
            buyerRegistrationNumber = buyerRegistrationNumber,
            supplyAmount = supplyAmount,
            vatAmount = vatAmount,
            totalAmount = totalAmount,
            itemDescription = itemDescription
        )
        
        return taxInvoiceRepository.save(taxInvoice)
    }

    /**
     * 부가세 계산
     */
    @Transactional(readOnly = true)
    fun calculateVat(companyId: UUID, startDate: LocalDate, endDate: LocalDate): VatCalculationResult {
        // 매출세액 계산 (발행 세금계산서)
        val outputVatData = taxInvoiceRepository.calculateOutputVat(companyId, startDate, endDate)
        val outputSupplyAmount = outputVatData[0] ?: BigDecimal.ZERO
        val outputVatAmount = outputVatData[1] ?: BigDecimal.ZERO

        // 매입세액 계산 (수취 세금계산서)
        val inputVatData = taxInvoiceRepository.calculateInputVat(companyId, startDate, endDate)
        val inputSupplyAmount = inputVatData[0] ?: BigDecimal.ZERO
        val inputVatAmount = inputVatData[1] ?: BigDecimal.ZERO

        // 납부할 부가세 계산
        val netVatAmount = outputVatAmount.subtract(inputVatAmount)

        return VatCalculationResult(
            outputSupplyAmount = outputSupplyAmount,
            outputVatAmount = outputVatAmount,
            inputSupplyAmount = inputSupplyAmount,
            inputVatAmount = inputVatAmount,
            netVatAmount = netVatAmount,
            calculationDate = LocalDate.now()
        )
    }

    /**
     * 원천징수 집계
     */
    @Transactional(readOnly = true)
    fun calculateWithholdingSummary(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): WithholdingSummary {
        val statistics = withholdingTaxRepository.getWithholdingStatistics(companyId, startDate, endDate)
        
        return WithholdingSummary(
            totalCount = (statistics[0] as Number).toInt(),
            totalIncomeAmount = statistics[1] as BigDecimal? ?: BigDecimal.ZERO,
            totalWithholdingAmount = statistics[2] as BigDecimal? ?: BigDecimal.ZERO,
            averageTaxRate = statistics[3] as BigDecimal? ?: BigDecimal.ZERO,
            pendingCount = (statistics[4] as Number).toInt(),
            reportedCount = (statistics[5] as Number).toInt()
        )
    }

    /**
     * 세무 일정 생성
     */
    fun createTaxSchedule(
        companyId: UUID,
        scheduleName: String,
        taxType: TaxSchedule.TaxType,
        scheduleType: TaxSchedule.ScheduleType,
        dueDate: LocalDate,
        reminderDate: LocalDate? = null,
        priority: TaxSchedule.Priority = TaxSchedule.Priority.MEDIUM,
        assignedTo: UUID? = null,
        description: String? = null
    ): TaxSchedule {
        val taxSchedule = TaxSchedule(
            companyId = companyId,
            scheduleName = scheduleName,
            taxType = taxType,
            scheduleType = scheduleType,
            dueDate = dueDate,
            reminderDate = reminderDate,
            priority = priority,
            assignedTo = assignedTo,
            description = description
        )
        
        return taxScheduleRepository.save(taxSchedule)
    }

    /**
     * 연간 세무 일정 자동 생성
     */
    fun generateAnnualTaxSchedules(companyId: UUID, year: Int): List<TaxSchedule> {
        val schedules = mutableListOf<TaxSchedule>()

        // 분기별 부가세 신고 일정
        for (quarter in 1..4) {
            val (_, _, dueDate) = getQuarterDates(year, quarter)
            val reminderDate = dueDate.minusDays(10)
            
            val vatSchedule = createTaxSchedule(
                companyId = companyId,
                scheduleName = "${year}년 ${quarter}분기 부가세 신고",
                taxType = TaxSchedule.TaxType.VAT,
                scheduleType = TaxSchedule.ScheduleType.FILING,
                dueDate = dueDate,
                reminderDate = reminderDate,
                priority = TaxSchedule.Priority.HIGH
            )
            schedules.add(vatSchedule)
        }

        // 월별 원천징수 신고 일정
        for (month in 1..12) {
            val dueDate = if (month == 12) {
                LocalDate.of(year + 1, 1, 10)
            } else {
                LocalDate.of(year, month + 1, 10)
            }
            val reminderDate = dueDate.minusDays(5)
            
            val withholdingSchedule = createTaxSchedule(
                companyId = companyId,
                scheduleName = "${year}년 ${month}월 원천징수 신고",
                taxType = TaxSchedule.TaxType.WITHHOLDING,
                scheduleType = TaxSchedule.ScheduleType.FILING,
                dueDate = dueDate,
                reminderDate = reminderDate,
                priority = TaxSchedule.Priority.MEDIUM
            )
            schedules.add(withholdingSchedule)
        }

        return schedules
    }

    /**
     * 세무 서류 등록
     */
    fun createTaxDocument(
        companyId: UUID,
        documentName: String,
        documentType: TaxDocument.DocumentType,
        fileName: String,
        filePath: String,
        fileSize: Long? = null,
        fileType: String? = null,
        description: String? = null,
        tags: String? = null
    ): TaxDocument {
        val taxDocument = TaxDocument(
            companyId = companyId,
            documentName = documentName,
            documentType = documentType,
            fileName = fileName,
            filePath = filePath,
            fileSize = fileSize,
            fileType = fileType,
            description = description,
            tags = tags,
            expiryDate = LocalDate.now().plusYears(5) // 기본 5년 보관
        )
        
        return taxDocumentRepository.save(taxDocument)
    }

    /**
     * 세무 대시보드 데이터 조회
     */
    @Transactional(readOnly = true)
    fun getTaxDashboardData(companyId: UUID): TaxDashboardData {
        val currentDate = LocalDate.now()
        val startOfYear = LocalDate.of(currentDate.year, 1, 1)
        val endOfYear = LocalDate.of(currentDate.year, 12, 31)

        // 오늘 마감 일정
        val todayDueSchedules = taxScheduleRepository.findTodayDueSchedules(companyId, currentDate)
        
        // 연체된 일정
        val overdueSchedules = taxScheduleRepository.findOverdueSchedules(companyId, currentDate)
        
        // 임박한 일정 (향후 7일)
        val upcomingSchedules = taxScheduleRepository.findUpcomingSchedules(
            companyId, currentDate, currentDate.plusDays(7)
        )

        // 부가세 계산
        val vatCalculation = calculateVat(companyId, startOfYear, endOfYear)
        
        // 원천징수 집계
        val withholdingSummary = calculateWithholdingSummary(companyId, startOfYear, endOfYear)

        return TaxDashboardData(
            todayDueSchedules = todayDueSchedules,
            overdueSchedules = overdueSchedules,
            upcomingSchedules = upcomingSchedules,
            vatCalculation = vatCalculation,
            withholdingSummary = withholdingSummary
        )
    }

    /**
     * 분기별 날짜 계산 헬퍼 함수
     */
    private fun getQuarterDates(year: Int, quarter: Int): Triple<LocalDate, LocalDate, LocalDate> {
        return when (quarter) {
            1 -> Triple(
                LocalDate.of(year, 1, 1),
                LocalDate.of(year, 3, 31),
                LocalDate.of(year, 4, 25)
            )
            2 -> Triple(
                LocalDate.of(year, 4, 1),
                LocalDate.of(year, 6, 30),
                LocalDate.of(year, 7, 25)
            )
            3 -> Triple(
                LocalDate.of(year, 7, 1),
                LocalDate.of(year, 9, 30),
                LocalDate.of(year, 10, 25)
            )
            4 -> Triple(
                LocalDate.of(year, 10, 1),
                LocalDate.of(year, 12, 31),
                LocalDate.of(year + 1, 1, 25)
            )
            else -> throw IllegalArgumentException("Invalid quarter: $quarter")
        }
    }

    /**
     * 부가세 계산 결과 데이터 클래스
     */
    data class VatCalculationResult(
        val outputSupplyAmount: BigDecimal,
        val outputVatAmount: BigDecimal,
        val inputSupplyAmount: BigDecimal,
        val inputVatAmount: BigDecimal,
        val netVatAmount: BigDecimal,
        val calculationDate: LocalDate
    )

    /**
     * 원천징수 집계 데이터 클래스
     */
    data class WithholdingSummary(
        val totalCount: Int,
        val totalIncomeAmount: BigDecimal,
        val totalWithholdingAmount: BigDecimal,
        val averageTaxRate: BigDecimal,
        val pendingCount: Int,
        val reportedCount: Int
    )

    /**
     * 세무 대시보드 데이터 클래스
     */
    data class TaxDashboardData(
        val todayDueSchedules: List<TaxSchedule>,
        val overdueSchedules: List<TaxSchedule>,
        val upcomingSchedules: List<TaxSchedule>,
        val vatCalculation: VatCalculationResult,
        val withholdingSummary: WithholdingSummary
    )
}