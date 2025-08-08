package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/** 국세청 홈택스 연동 서비스 (건물관리 특화) 부가세 신고서 자동 전송, 세금계산서 자동 발행/수취 기능 제공 */
@Service
@Transactional
class HomeTaxService(
        private val taxPeriodRepository: TaxPeriodRepository,
        private val vatReturnRepository: VatReturnRepository,
        private val withholdingTaxRepository: WithholdingTaxRepository,
        private val taxInvoiceRepository: TaxInvoiceRepository,
        private val incomeRecordRepository: IncomeRecordRepository,
        private val expenseRecordRepository: ExpenseRecordRepository
) {

    /** 홈택스 연동 설정 */
    fun connectHomeTax(
            companyId: UUID,
            request: HomeTaxConnectionRequest
    ): HomeTaxConnectionResponse {
        // 실제 구현에서는 홈택스 API 또는 인증서 검증
        validateBusinessNumber(request.businessNumber)
        validateCertificate(request.certType, request.certPassword)

        // 연동 정보 저장
        val connectionId = UUID.randomUUID()
        saveHomeTaxConnection(companyId, connectionId, request)

        return HomeTaxConnectionResponse(
                connectionId = connectionId,
                businessNumber = maskBusinessNumber(request.businessNumber),
                companyName = "건물관리 회사",
                representativeName = request.representativeName,
                connectionStatus = "CONNECTED",
                certExpiryDate = LocalDate.now().plusYears(1),
                lastSyncAt = LocalDateTime.now(),
                supportedServices = listOf("VAT_RETURN", "TAX_INVOICE", "WITHHOLDING_TAX")
        )
    }

    /** 부가세 신고서 생성 및 전송 */
    fun submitVatReturn(companyId: UUID, request: VatReturnSubmissionRequest): VatReturnResponse {
        val taxPeriod =
                taxPeriodRepository.findById(request.taxPeriodId).orElseThrow {
                    IllegalArgumentException("세무 기간을 찾을 수 없습니다: ${request.taxPeriodId}")
                }

        // 부가세 신고서 데이터 자동 계산
        val vatData =
                if (request.autoCalculate) {
                    calculateVatReturnData(companyId, taxPeriod)
                } else {
                    getExistingVatReturnData(companyId, taxPeriod)
                }

        // 홈택스 API로 신고서 전송 (실제 구현에서는 외부 API 호출)
        val submissionResult = submitToHomeTax(vatData)

        // 신고서 정보 저장
        val vatReturn = saveVatReturn(companyId, taxPeriod, vatData, submissionResult)

        return VatReturnResponse(
                returnId = vatReturn.id,
                taxPeriod = "${taxPeriod.periodYear}-${taxPeriod.periodQuarter}Q",
                businessNumber = maskBusinessNumber(vatData.businessNumber),
                companyName = vatData.companyName,
                returnType = request.returnType,
                salesAmount = vatData.salesAmount,
                outputVat = vatData.outputVat,
                purchaseAmount = vatData.purchaseAmount,
                inputVat = vatData.inputVat,
                payableVat = vatData.payableVat,
                refundableVat = vatData.refundableVat,
                submissionStatus = submissionResult.status,
                submissionDate = submissionResult.submissionDate,
                acceptanceNumber = submissionResult.acceptanceNumber,
                dueDate = taxPeriod.dueDate
        )
    }

    /** 세금계산서 발행 */
    fun issueTaxInvoice(companyId: UUID, request: TaxInvoiceIssueRequest): TaxInvoiceResponse {
        // 세금계산서 데이터 검증
        validateTaxInvoiceData(request)

        // 세금계산서 번호 생성
        val invoiceNumber = generateTaxInvoiceNumber(companyId)

        // 홈택스 API로 세금계산서 발행 (실제 구현에서는 외부 API 호출)
        val issuanceResult = issueToHomeTax(request, invoiceNumber)

        // 세금계산서 정보 저장
        val taxInvoice = saveTaxInvoice(companyId, request, invoiceNumber, issuanceResult)

        return TaxInvoiceResponse(
                invoiceId = taxInvoice.id,
                invoiceNumber = invoiceNumber,
                invoiceType = request.invoiceType,
                transactionType = request.transactionType,
                issueDate = request.issueDate,
                supplierInfo =
                        CompanyInfo(
                                businessNumber = maskBusinessNumber(request.supplierBusinessNumber),
                                companyName = request.supplierName,
                                representativeName = "대표자",
                                address = request.supplierAddress,
                                businessType = "부동산업",
                                businessItem = "건물관리"
                        ),
                buyerInfo =
                        CompanyInfo(
                                businessNumber = maskBusinessNumber(request.buyerBusinessNumber),
                                companyName = request.buyerName,
                                representativeName = "대표자",
                                address = request.buyerAddress,
                                businessType = "기타",
                                businessItem = "기타"
                        ),
                supplyAmount = request.supplyAmount,
                vatAmount = request.vatAmount,
                totalAmount = request.totalAmount,
                items =
                        request.items.map { item ->
                            TaxInvoiceItemResponse(
                                    itemName = item.itemName,
                                    specification = item.specification,
                                    quantity = item.quantity,
                                    unitPrice = item.unitPrice,
                                    supplyAmount = item.supplyAmount,
                                    vatAmount = item.vatAmount
                            )
                        },
                status = issuanceResult.status,
                issuanceStatus = issuanceResult.issuanceStatus,
                errorMessage = issuanceResult.errorMessage,
                ntsConfirmNumber = issuanceResult.ntsConfirmNumber
        )
    }

    /** 원천징수 신고서 생성 및 전송 */
    fun submitWithholdingTaxReturn(
            companyId: UUID,
            request: WithholdingTaxReturnRequest
    ): WithholdingTaxReturnResponse {
        val taxPeriod =
                taxPeriodRepository.findById(request.taxPeriodId).orElseThrow {
                    IllegalArgumentException("세무 기간을 찾을 수 없습니다: ${request.taxPeriodId}")
                }

        // 원천징수 신고서 데이터 자동 계산
        val withholdingData =
                if (request.autoCalculate) {
                    calculateWithholdingTaxData(companyId, taxPeriod, request.incomeType)
                } else {
                    getExistingWithholdingTaxData(companyId, taxPeriod, request.incomeType)
                }

        // 홈택스 API로 신고서 전송
        val submissionResult = submitWithholdingToHomeTax(withholdingData)

        return WithholdingTaxReturnResponse(
                returnId = UUID.randomUUID(),
                taxPeriod =
                        "${taxPeriod.periodYear}-${(taxPeriod.periodMonth ?: 1).toString().padStart(2, '0')}",
                businessNumber = maskBusinessNumber(withholdingData.businessNumber),
                returnType = request.returnType,
                incomeType = request.incomeType,
                totalIncomeAmount = withholdingData.totalIncomeAmount,
                totalTaxAmount = withholdingData.totalTaxAmount,
                recipientCount = withholdingData.recipientCount,
                submissionStatus = submissionResult.status,
                submissionDate = submissionResult.submissionDate,
                acceptanceNumber = submissionResult.acceptanceNumber,
                dueDate = taxPeriod.dueDate
        )
    }

    /** 홈택스 신고 현황 조회 */
    @Transactional(readOnly = true)
    fun getHomeTaxSubmissionStatus(companyId: UUID): HomeTaxSubmissionStatusResponse {
        val pendingSubmissions = getPendingSubmissions(companyId)
        val recentSubmissions = getRecentSubmissions(companyId)
        val upcomingDeadlines = getUpcomingDeadlines(companyId)

        return HomeTaxSubmissionStatusResponse(
                businessNumber = maskBusinessNumber("123-45-67890"),
                companyName = "건물관리 회사",
                pendingSubmissions = pendingSubmissions,
                recentSubmissions = recentSubmissions,
                upcomingDeadlines = upcomingDeadlines,
                connectionStatus = "CONNECTED",
                lastSyncAt = LocalDateTime.now().minusHours(1)
        )
    }

    /** 세금계산서 수취 현황 조회 */
    @Transactional(readOnly = true)
    fun getTaxInvoiceReceiptStatus(companyId: UUID): TaxInvoiceReceiptStatusResponse {
        val currentYear = LocalDate.now().year
        val monthlyStats =
                (1..12).map { month ->
                    MonthlyTaxInvoiceStats(
                            month = "${currentYear}-${month.toString().padStart(2, '0')}",
                            issuedCount = (5..15).random(),
                            receivedCount = (10..25).random(),
                            totalIssuedAmount = BigDecimal("${(1000000..5000000).random()}"),
                            totalReceivedAmount = BigDecimal("${(2000000..8000000).random()}")
                    )
                }

        return TaxInvoiceReceiptStatusResponse(
                totalReceived = 156,
                totalIssued = 89,
                pendingReceipts = 3,
                rejectedReceipts = 1,
                recentReceipts = getRecentTaxInvoiceReceipts(companyId),
                monthlyStatistics = monthlyStats
        )
    }

    /** 홈택스 API 상태 조회 */
    @Transactional(readOnly = true)
    fun getHomeTaxApiStatus(): HomeTaxApiStatusResponse {
        return HomeTaxApiStatusResponse(
                serviceStatus = "NORMAL",
                lastHealthCheck = LocalDateTime.now().minusMinutes(5),
                responseTime = 1200L,
                errorRate = BigDecimal("0.02"),
                dailyQuota = 1000,
                usedQuota = 45,
                remainingQuota = 955,
                maintenanceSchedule =
                        listOf(
                                MaintenanceInfo(
                                        maintenanceType = "정기점검",
                                        startTime =
                                                LocalDateTime.now()
                                                        .plusDays(7)
                                                        .withHour(2)
                                                        .withMinute(0),
                                        endTime =
                                                LocalDateTime.now()
                                                        .plusDays(7)
                                                        .withHour(6)
                                                        .withMinute(0),
                                        description = "시스템 정기점검 및 업데이트",
                                        affectedServices = listOf("VAT_RETURN", "TAX_INVOICE")
                                )
                        )
        )
    }

    /** 세무 신고 일정 조회 */
    @Transactional(readOnly = true)
    fun getTaxSchedule(companyId: UUID): List<TaxScheduleResponse> {
        return listOf(
                TaxScheduleResponse(
                        scheduleId = UUID.randomUUID(),
                        taxType = "VAT",
                        description = "2025년 1분기 부가세 신고",
                        dueDate = LocalDate.of(2025, 4, 25),
                        reminderDate = LocalDate.of(2025, 4, 20),
                        status = "PENDING",
                        priority = "HIGH",
                        estimatedAmount = BigDecimal("2500000"),
                        actualAmount = null,
                        submissionId = null
                ),
                TaxScheduleResponse(
                        scheduleId = UUID.randomUUID(),
                        taxType = "WITHHOLDING_TAX",
                        description = "2025년 1월 원천징수 신고",
                        dueDate = LocalDate.of(2025, 2, 10),
                        reminderDate = LocalDate.of(2025, 2, 5),
                        status = "COMPLETED",
                        priority = "MEDIUM",
                        estimatedAmount = BigDecimal("150000"),
                        actualAmount = BigDecimal("148000"),
                        submissionId = UUID.randomUUID()
                )
        )
    }

    /** 세무 대시보드 데이터 조회 */
    @Transactional(readOnly = true)
    fun getTaxDashboard(companyId: UUID): TaxDashboardResponse {
        return TaxDashboardResponse(
                businessNumber = maskBusinessNumber("123-45-67890"),
                companyName = "건물관리 회사",
                currentTaxPeriod = "2025-1Q",
                connectionStatus = "CONNECTED",
                pendingTasks = getPendingTaxTasks(companyId),
                recentActivities = getRecentTaxActivities(companyId),
                taxSummary = getTaxSummaryData(companyId),
                alerts = getTaxAlerts(companyId)
        )
    }

    /** 인증서 관리 정보 조회 */
    @Transactional(readOnly = true)
    fun getCertificateManagement(companyId: UUID): List<CertificateManagementResponse> {
        return listOf(
                CertificateManagementResponse(
                        certificateId = UUID.randomUUID(),
                        certificateType = "CORPORATE",
                        issuer = "한국정보인증",
                        subjectName = "건물관리 회사",
                        validFrom = LocalDate.now().minusYears(1),
                        validTo = LocalDate.now().plusMonths(11),
                        daysUntilExpiry = 335,
                        status = "VALID",
                        usageCount = 127,
                        lastUsedAt = LocalDateTime.now().minusHours(3)
                )
        )
    }

    // Private helper methods
    private fun validateBusinessNumber(businessNumber: String) {
        // 사업자등록번호 유효성 검증
        if (!businessNumber.matches(Regex("\\d{3}-\\d{2}-\\d{5}"))) {
            throw IllegalArgumentException("올바르지 않은 사업자등록번호 형식입니다: $businessNumber")
        }
    }

    private fun validateCertificate(certType: String, certPassword: String) {
        // 인증서 유효성 검증 (실제 구현에서는 인증서 파일 검증)
        if (certPassword.length < 8) {
            throw IllegalArgumentException("인증서 비밀번호는 8자 이상이어야 합니다.")
        }
    }

    private fun saveHomeTaxConnection(
            companyId: UUID,
            connectionId: UUID,
            request: HomeTaxConnectionRequest
    ) {
        // 실제 구현에서는 HomeTaxConnection 엔티티에 저장
    }

    private fun calculateVatReturnData(companyId: UUID, taxPeriod: TaxPeriod): VatReturnData {
        val periodStart =
                LocalDate.of(taxPeriod.periodYear, (taxPeriod.periodQuarter ?: 1 - 1) * 3 + 1, 1)
        val periodEnd = periodStart.plusMonths(3).minusDays(1)

        // 매출액 및 매출세액 계산 (수입 기록 기반)
        val totalIncome =
                incomeRecordRepository.getTotalIncomeByPeriod(companyId, periodStart, periodEnd)
        val salesAmount = totalIncome.divide(BigDecimal("1.1"), 0, java.math.RoundingMode.HALF_UP)
        val outputVat = totalIncome - salesAmount

        // 매입액 및 매입세액 계산 (지출 기록 기반)
        val totalExpense =
                expenseRecordRepository.getTotalExpenseByPeriod(companyId, periodStart, periodEnd)
        val purchaseAmount =
                totalExpense.divide(BigDecimal("1.1"), 0, java.math.RoundingMode.HALF_UP)
        val inputVat = totalExpense - purchaseAmount

        // 납부할 세액 계산
        val payableVat = (outputVat - inputVat).coerceAtLeast(BigDecimal.ZERO)
        val refundableVat = (inputVat - outputVat).coerceAtLeast(BigDecimal.ZERO)

        return VatReturnData(
                businessNumber = "123-45-67890",
                companyName = "건물관리 회사",
                salesAmount = salesAmount,
                outputVat = outputVat,
                purchaseAmount = purchaseAmount,
                inputVat = inputVat,
                payableVat = payableVat,
                refundableVat = refundableVat
        )
    }

    private fun getExistingVatReturnData(companyId: UUID, taxPeriod: TaxPeriod): VatReturnData {
        // 기존 부가세 신고서 데이터 조회
        return calculateVatReturnData(companyId, taxPeriod) // 임시로 계산된 데이터 반환
    }

    private fun submitToHomeTax(vatData: VatReturnData): SubmissionResult {
        // 실제 구현에서는 홈택스 API 호출
        return SubmissionResult(
                status = "SUBMITTED",
                submissionDate = LocalDateTime.now(),
                acceptanceNumber = "VAT${System.currentTimeMillis()}",
                issuanceStatus = "SUCCESS",
                errorMessage = null,
                ntsConfirmNumber = "NTS${System.currentTimeMillis()}"
        )
    }

    private fun saveVatReturn(
            companyId: UUID,
            taxPeriod: TaxPeriod,
            vatData: VatReturnData,
            submissionResult: SubmissionResult
    ): VatReturn {
        // 실제 구현에서는 VatReturn 엔티티에 저장
        return VatReturn(
                id = UUID.randomUUID(),
                companyId = companyId,
                taxPeriodId = taxPeriod.id,
                salesAmount = vatData.salesAmount,
                outputVat = vatData.outputVat,
                purchaseAmount = vatData.purchaseAmount,
                inputVat = vatData.inputVat,
                payableVat = vatData.payableVat,
                refundableVat = vatData.refundableVat,
                submissionStatus = submissionResult.status,
                submissionDate = submissionResult.submissionDate.toLocalDate(),
                acceptanceNumber = submissionResult.acceptanceNumber
        )
    }

    private fun validateTaxInvoiceData(request: TaxInvoiceIssueRequest) {
        if (request.supplyAmount + request.vatAmount != request.totalAmount) {
            throw IllegalArgumentException("공급가액 + 부가세액이 총 금액과 일치하지 않습니다.")
        }
    }

    private fun generateTaxInvoiceNumber(companyId: UUID): String {
        return "TI${LocalDate.now().year}${System.currentTimeMillis().toString().takeLast(8)}"
    }

    private fun issueToHomeTax(
            request: TaxInvoiceIssueRequest,
            invoiceNumber: String
    ): SubmissionResult {
        // 실제 구현에서는 홈택스 세금계산서 발행 API 호출
        return SubmissionResult(
                status = "ISSUED",
                submissionDate = LocalDateTime.now(),
                acceptanceNumber = invoiceNumber,
                issuanceStatus = "SUCCESS",
                errorMessage = null,
                ntsConfirmNumber = "NTS${System.currentTimeMillis()}"
        )
    }

    private fun saveTaxInvoice(
            companyId: UUID,
            request: TaxInvoiceIssueRequest,
            invoiceNumber: String,
            issuanceResult: SubmissionResult
    ): TaxInvoiceEntity {
        // 실제 구현에서는 TaxInvoice 엔티티에 저장
        return TaxInvoiceEntity(
                id = UUID.randomUUID(),
                companyId = companyId,
                invoiceNumber = invoiceNumber
        )
    }

    private fun calculateWithholdingTaxData(
            companyId: UUID,
            taxPeriod: TaxPeriod,
            incomeType: String
    ): WithholdingTaxData {
        // 원천징수 데이터 계산 (임시 구현)
        return WithholdingTaxData(
                businessNumber = "123-45-67890",
                totalIncomeAmount = BigDecimal("5000000"),
                totalTaxAmount = BigDecimal("500000"),
                recipientCount = 10
        )
    }

    private fun getExistingWithholdingTaxData(
            companyId: UUID,
            taxPeriod: TaxPeriod,
            incomeType: String
    ): WithholdingTaxData {
        return calculateWithholdingTaxData(companyId, taxPeriod, incomeType)
    }

    private fun submitWithholdingToHomeTax(withholdingData: WithholdingTaxData): SubmissionResult {
        return SubmissionResult(
                status = "SUBMITTED",
                submissionDate = LocalDateTime.now(),
                acceptanceNumber = "WTH${System.currentTimeMillis()}",
                issuanceStatus = "SUCCESS",
                errorMessage = null,
                ntsConfirmNumber = null
        )
    }

    private fun getPendingSubmissions(companyId: UUID): List<PendingSubmission> {
        return listOf(
                PendingSubmission(
                        submissionId = UUID.randomUUID(),
                        submissionType = "VAT_RETURN",
                        taxPeriod = "2025-1Q",
                        dueDate = LocalDate.of(2025, 4, 25),
                        status = "DRAFT",
                        priority = "HIGH"
                )
        )
    }

    private fun getRecentSubmissions(companyId: UUID): List<RecentSubmission> {
        return listOf(
                RecentSubmission(
                        submissionId = UUID.randomUUID(),
                        submissionType = "WITHHOLDING_TAX",
                        taxPeriod = "2024-12",
                        submissionDate = LocalDateTime.now().minusDays(5),
                        status = "ACCEPTED",
                        acceptanceNumber = "WTH20241205001"
                )
        )
    }

    private fun getUpcomingDeadlines(companyId: UUID): List<UpcomingDeadline> {
        return listOf(
                UpcomingDeadline(
                        deadlineType = "VAT_RETURN",
                        description = "2025년 1분기 부가세 신고",
                        dueDate = LocalDate.of(2025, 4, 25),
                        daysRemaining = 107,
                        priority = "HIGH"
                )
        )
    }

    private fun getRecentTaxInvoiceReceipts(companyId: UUID): List<TaxInvoiceReceiptInfo> {
        return listOf(
                TaxInvoiceReceiptInfo(
                        invoiceId = UUID.randomUUID(),
                        invoiceNumber = "TI2025001",
                        supplierName = "ABC 유지보수",
                        issueDate = LocalDate.now().minusDays(2),
                        totalAmount = BigDecimal("550000"),
                        receiptStatus = "RECEIVED",
                        receiptDate = LocalDateTime.now().minusDays(1)
                )
        )
    }

    private fun getPendingTaxTasks(companyId: UUID): List<PendingTaxTask> {
        return listOf(
                PendingTaxTask(
                        taskId = UUID.randomUUID(),
                        taskType = "VAT_RETURN_PREPARATION",
                        description = "1분기 부가세 신고서 작성",
                        dueDate = LocalDate.of(2025, 4, 20),
                        priority = "HIGH",
                        estimatedTime = 120
                )
        )
    }

    private fun getRecentTaxActivities(companyId: UUID): List<TaxActivity> {
        return listOf(
                TaxActivity(
                        activityId = UUID.randomUUID(),
                        activityType = "TAX_INVOICE_ISSUED",
                        description = "세금계산서 발행 (TI2025001)",
                        activityDate = LocalDateTime.now().minusHours(3),
                        status = "SUCCESS",
                        amount = BigDecimal("550000")
                )
        )
    }

    private fun getTaxSummaryData(companyId: UUID): TaxSummaryData {
        return TaxSummaryData(
                currentQuarterVat = BigDecimal("2500000"),
                currentMonthWithholding = BigDecimal("150000"),
                yearToDateVat = BigDecimal("2500000"),
                yearToDateWithholding = BigDecimal("150000"),
                taxInvoiceIssued = 89,
                taxInvoiceReceived = 156
        )
    }

    private fun getTaxAlerts(companyId: UUID): List<TaxAlert> {
        return listOf(
                TaxAlert(
                        alertId = UUID.randomUUID(),
                        alertType = "DEADLINE_APPROACHING",
                        title = "부가세 신고 마감 임박",
                        message = "2025년 1분기 부가세 신고 마감이 107일 남았습니다.",
                        severity = "WARNING",
                        actionRequired = true,
                        dueDate = LocalDate.of(2025, 4, 25),
                        createdAt = LocalDateTime.now().minusHours(1)
                )
        )
    }

    private fun maskBusinessNumber(businessNumber: String): String {
        return if (businessNumber.length >= 10) {
            businessNumber.take(3) + "-**-" + businessNumber.takeLast(5)
        } else {
            businessNumber
        }
    }
}

// Helper data classes
data class VatReturnData(
        val businessNumber: String,
        val companyName: String,
        val salesAmount: BigDecimal,
        val outputVat: BigDecimal,
        val purchaseAmount: BigDecimal,
        val inputVat: BigDecimal,
        val payableVat: BigDecimal,
        val refundableVat: BigDecimal
)

data class WithholdingTaxData(
        val businessNumber: String,
        val totalIncomeAmount: BigDecimal,
        val totalTaxAmount: BigDecimal,
        val recipientCount: Int
)

data class SubmissionResult(
        val status: String,
        val submissionDate: LocalDateTime,
        val acceptanceNumber: String,
        val issuanceStatus: String,
        val errorMessage: String?,
        val ntsConfirmNumber: String?
)

data class TaxInvoiceEntity(val id: UUID, val companyId: UUID, val invoiceNumber: String)
