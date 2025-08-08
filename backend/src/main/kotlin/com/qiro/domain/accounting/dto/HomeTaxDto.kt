package com.qiro.domain.accounting.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 국세청 홈택스 연동 DTO 클래스들
 * 부가세 신고서 자동 전송, 세금계산서 자동 발행/수취 관련 데이터
 */

// 홈택스 연동 설정 요청
data class HomeTaxConnectionRequest(
    val businessNumber: String, // 사업자등록번호
    val representativeName: String, // 대표자명
    val certType: String, // 인증서 유형 (PERSONAL, CORPORATE)
    val certPassword: String, // 인증서 비밀번호
    val apiKey: String? = null, // API 키 (선택사항)
    val connectionType: String = "CERTIFICATE" // CERTIFICATE, API, SCRAPING
)

// 홈택스 연동 설정 응답
data class HomeTaxConnectionResponse(
    val connectionId: UUID,
    val businessNumber: String,
    val companyName: String,
    val representativeName: String,
    val connectionStatus: String, // CONNECTED, DISCONNECTED, ERROR, EXPIRED
    val certExpiryDate: LocalDate?,
    val lastSyncAt: LocalDateTime?,
    val supportedServices: List<String> // VAT_RETURN, TAX_INVOICE, WITHHOLDING_TAX
)

// 부가세 신고서 생성 요청
data class VatReturnSubmissionRequest(
    val taxPeriodId: UUID, // 세무 기간 ID
    val returnType: String, // GENERAL, SIMPLIFIED, ZERO_RATE
    val submissionType: String = "ELECTRONIC", // ELECTRONIC, PAPER
    val autoCalculate: Boolean = true // 자동 계산 여부
)

// 부가세 신고서 응답
data class VatReturnResponse(
    val returnId: UUID,
    val taxPeriod: String, // 2025-1Q
    val businessNumber: String,
    val companyName: String,
    val returnType: String,
    val salesAmount: BigDecimal, // 매출액
    val outputVat: BigDecimal, // 매출세액
    val purchaseAmount: BigDecimal, // 매입액
    val inputVat: BigDecimal, // 매입세액
    val payableVat: BigDecimal, // 납부할 세액
    val refundableVat: BigDecimal, // 환급받을 세액
    val submissionStatus: String, // DRAFT, SUBMITTED, ACCEPTED, REJECTED
    val submissionDate: LocalDateTime?,
    val acceptanceNumber: String?, // 접수번호
    val dueDate: LocalDate // 납부기한
)

// 세금계산서 발행 요청
data class TaxInvoiceIssueRequest(
    val invoiceType: String, // GENERAL, SIMPLIFIED, RECEIPT
    val transactionType: String, // SALE, PURCHASE, RETURN
    val supplierBusinessNumber: String,
    val supplierName: String,
    val supplierAddress: String?,
    val buyerBusinessNumber: String,
    val buyerName: String,
    val buyerAddress: String?,
    val issueDate: LocalDate,
    val supplyAmount: BigDecimal, // 공급가액
    val vatAmount: BigDecimal, // 부가세액
    val totalAmount: BigDecimal, // 총 금액
    val items: List<TaxInvoiceItemRequest>,
    val memo: String? = null
)

data class TaxInvoiceItemRequest(
    val itemName: String, // 품목명
    val specification: String? = null, // 규격
    val quantity: BigDecimal, // 수량
    val unitPrice: BigDecimal, // 단가
    val supplyAmount: BigDecimal, // 공급가액
    val vatAmount: BigDecimal // 부가세액
)

// 세금계산서 응답
data class TaxInvoiceResponse(
    val invoiceId: UUID,
    val invoiceNumber: String, // 세금계산서 번호
    val invoiceType: String,
    val transactionType: String,
    val issueDate: LocalDate,
    val supplierInfo: CompanyInfo,
    val buyerInfo: CompanyInfo,
    val supplyAmount: BigDecimal,
    val vatAmount: BigDecimal,
    val totalAmount: BigDecimal,
    val items: List<TaxInvoiceItemResponse>,
    val status: String, // ISSUED, SENT, RECEIVED, CANCELLED
    val issuanceStatus: String, // SUCCESS, FAILED, PENDING
    val errorMessage: String? = null,
    val ntsConfirmNumber: String? = null // 국세청 승인번호
)

data class CompanyInfo(
    val businessNumber: String,
    val companyName: String,
    val representativeName: String,
    val address: String?,
    val businessType: String?,
    val businessItem: String?
)

data class TaxInvoiceItemResponse(
    val itemName: String,
    val specification: String?,
    val quantity: BigDecimal,
    val unitPrice: BigDecimal,
    val supplyAmount: BigDecimal,
    val vatAmount: BigDecimal
)

// 원천징수 신고서 생성 요청
data class WithholdingTaxReturnRequest(
    val taxPeriodId: UUID,
    val returnType: String, // MONTHLY, QUARTERLY, ANNUAL
    val incomeType: String, // SALARY, BONUS, RETIREMENT, BUSINESS, PROFESSIONAL
    val autoCalculate: Boolean = true
)

// 원천징수 신고서 응답
data class WithholdingTaxReturnResponse(
    val returnId: UUID,
    val taxPeriod: String,
    val businessNumber: String,
    val returnType: String,
    val incomeType: String,
    val totalIncomeAmount: BigDecimal, // 총 지급액
    val totalTaxAmount: BigDecimal, // 총 원천징수세액
    val recipientCount: Int, // 지급대상자 수
    val submissionStatus: String,
    val submissionDate: LocalDateTime?,
    val acceptanceNumber: String?,
    val dueDate: LocalDate
)

// 홈택스 신고 현황 조회 응답
data class HomeTaxSubmissionStatusResponse(
    val businessNumber: String,
    val companyName: String,
    val pendingSubmissions: List<PendingSubmission>,
    val recentSubmissions: List<RecentSubmission>,
    val upcomingDeadlines: List<UpcomingDeadline>,
    val connectionStatus: String,
    val lastSyncAt: LocalDateTime?
)

data class PendingSubmission(
    val submissionId: UUID,
    val submissionType: String, // VAT_RETURN, WITHHOLDING_TAX, TAX_INVOICE
    val taxPeriod: String,
    val dueDate: LocalDate,
    val status: String,
    val priority: String // HIGH, MEDIUM, LOW
)

data class RecentSubmission(
    val submissionId: UUID,
    val submissionType: String,
    val taxPeriod: String,
    val submissionDate: LocalDateTime,
    val status: String,
    val acceptanceNumber: String?
)

data class UpcomingDeadline(
    val deadlineType: String,
    val description: String,
    val dueDate: LocalDate,
    val daysRemaining: Int,
    val priority: String
)

// 세금계산서 수취 현황 응답
data class TaxInvoiceReceiptStatusResponse(
    val totalReceived: Int,
    val totalIssued: Int,
    val pendingReceipts: Int,
    val rejectedReceipts: Int,
    val recentReceipts: List<TaxInvoiceReceiptInfo>,
    val monthlyStatistics: List<MonthlyTaxInvoiceStats>
)

data class TaxInvoiceReceiptInfo(
    val invoiceId: UUID,
    val invoiceNumber: String,
    val supplierName: String,
    val issueDate: LocalDate,
    val totalAmount: BigDecimal,
    val receiptStatus: String, // RECEIVED, PENDING, REJECTED
    val receiptDate: LocalDateTime?
)

data class MonthlyTaxInvoiceStats(
    val month: String,
    val issuedCount: Int,
    val receivedCount: Int,
    val totalIssuedAmount: BigDecimal,
    val totalReceivedAmount: BigDecimal
)

// 홈택스 API 상태 응답
data class HomeTaxApiStatusResponse(
    val serviceStatus: String, // NORMAL, MAINTENANCE, ERROR
    val lastHealthCheck: LocalDateTime,
    val responseTime: Long, // milliseconds
    val errorRate: BigDecimal,
    val dailyQuota: Int,
    val usedQuota: Int,
    val remainingQuota: Int,
    val maintenanceSchedule: List<MaintenanceInfo>
)

data class MaintenanceInfo(
    val maintenanceType: String,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime,
    val description: String,
    val affectedServices: List<String>
)

// 세무 신고 일정 응답
data class TaxScheduleResponse(
    val scheduleId: UUID,
    val taxType: String, // VAT, WITHHOLDING_TAX, CORPORATE_TAX, LOCAL_TAX
    val description: String,
    val dueDate: LocalDate,
    val reminderDate: LocalDate,
    val status: String, // PENDING, COMPLETED, OVERDUE
    val priority: String,
    val estimatedAmount: BigDecimal?,
    val actualAmount: BigDecimal?,
    val submissionId: UUID?
)

// 세무 대시보드 응답
data class TaxDashboardResponse(
    val businessNumber: String,
    val companyName: String,
    val currentTaxPeriod: String,
    val connectionStatus: String,
    val pendingTasks: List<PendingTaxTask>,
    val recentActivities: List<TaxActivity>,
    val taxSummary: TaxSummaryData,
    val alerts: List<TaxAlert>
)

data class PendingTaxTask(
    val taskId: UUID,
    val taskType: String,
    val description: String,
    val dueDate: LocalDate,
    val priority: String,
    val estimatedTime: Int // minutes
)

data class TaxActivity(
    val activityId: UUID,
    val activityType: String,
    val description: String,
    val activityDate: LocalDateTime,
    val status: String,
    val amount: BigDecimal?
)

data class TaxSummaryData(
    val currentQuarterVat: BigDecimal,
    val currentMonthWithholding: BigDecimal,
    val yearToDateVat: BigDecimal,
    val yearToDateWithholding: BigDecimal,
    val taxInvoiceIssued: Int,
    val taxInvoiceReceived: Int
)

data class TaxAlert(
    val alertId: UUID,
    val alertType: String, // DEADLINE_APPROACHING, SUBMISSION_FAILED, CERTIFICATE_EXPIRING
    val title: String,
    val message: String,
    val severity: String, // INFO, WARNING, ERROR
    val actionRequired: Boolean,
    val dueDate: LocalDate?,
    val createdAt: LocalDateTime
)

// 인증서 관리 응답
data class CertificateManagementResponse(
    val certificateId: UUID,
    val certificateType: String, // PERSONAL, CORPORATE
    val issuer: String, // 발급기관
    val subjectName: String, // 인증서 주체
    val validFrom: LocalDate,
    val validTo: LocalDate,
    val daysUntilExpiry: Int,
    val status: String, // VALID, EXPIRED, REVOKED, SUSPENDED
    val usageCount: Int,
    val lastUsedAt: LocalDateTime?
)