package com.qiro.domain.accounting.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 수입 관리 DTO 클래스들
 * 건물관리용 수입 관리 API 요청/응답 데이터
 */

// 수입 기록 생성 요청
data class CreateIncomeRecordRequest(
    val incomeTypeId: UUID,
    val amount: BigDecimal,
    val incomeDate: LocalDate,
    val description: String? = null,
    val unitId: String? = null, // 세대/호수
    val period: String? = null // 관리비 기간 (예: 2025-01)
)

// 수입 기록 응답
data class IncomeRecordResponse(
    val id: UUID,
    val incomeTypeName: String,
    val amount: BigDecimal,
    val incomeDate: LocalDate,
    val status: String,
    val description: String?,
    val unitId: String?,
    val period: String?,
    val createdAt: String
)

// 미수금 응답
data class ReceivableResponse(
    val id: UUID,
    val incomeRecordId: UUID,
    val unitId: String?,
    val originalAmount: BigDecimal,
    val remainingAmount: BigDecimal,
    val dueDate: LocalDate,
    val overdueDays: Int,
    val lateFee: BigDecimal,
    val status: String,
    val incomeTypeName: String,
    val period: String?
)

// 수입 통계 응답
data class IncomeStatisticsResponse(
    val totalIncome: BigDecimal,
    val totalReceivables: BigDecimal,
    val totalLateFees: BigDecimal,
    val collectionRate: BigDecimal, // 수납률
    val overdueCount: Int,
    val monthlyIncome: List<MonthlyIncomeData>
)

data class MonthlyIncomeData(
    val month: String,
    val income: BigDecimal,
    val receivables: BigDecimal
)

// 연체료 계산 요청
data class CalculateLateFeeRequest(
    val receivableId: UUID,
    val calculationDate: LocalDate = LocalDate.now()
)

// 연체료 계산 응답
data class LateFeeCalculationResponse(
    val receivableId: UUID,
    val overdueDays: Int,
    val lateFeeAmount: BigDecimal,
    val totalAmount: BigDecimal, // 원금 + 연체료
    val calculationDate: LocalDate
)

// 수입 유형 응답
data class IncomeTypeResponse(
    val id: UUID,
    val typeName: String,
    val description: String?,
    val isRecurring: Boolean,
    val defaultAmount: BigDecimal?,
    val isActive: Boolean
)

// 결제 기록 생성 요청
data class CreatePaymentRecordRequest(
    val receivableId: UUID,
    val paymentAmount: BigDecimal,
    val paymentDate: LocalDate,
    val paymentMethod: String, // CASH, BANK_TRANSFER, CARD 등
    val notes: String? = null
)

// 결제 기록 응답
data class PaymentRecordResponse(
    val id: UUID,
    val receivableId: UUID,
    val paymentAmount: BigDecimal,
    val paymentDate: LocalDate,
    val paymentMethod: String,
    val notes: String?,
    val createdAt: String
)

// 수입 대시보드 응답
data class IncomeDashboardResponse(
    val todayIncome: BigDecimal,
    val monthlyIncome: BigDecimal,
    val yearlyIncome: BigDecimal,
    val totalReceivables: BigDecimal,
    val overdueReceivables: BigDecimal,
    val collectionRate: BigDecimal,
    val recentIncomes: List<IncomeRecordResponse>,
    val overdueList: List<ReceivableResponse>
)

// 연체료 정책 생성 요청
data class CreateLateFeePolicyRequest(
    val incomeTypeId: UUID,
    val calculationType: String, // PERCENTAGE, FIXED_AMOUNT, DAILY_RATE
    val feeRate: BigDecimal,
    val minimumFee: BigDecimal? = null,
    val maximumFee: BigDecimal? = null,
    val gracePeriodDays: Int = 0,
    val description: String? = null
)

// 연체료 정책 응답
data class LateFeePolicyDto(
    val id: UUID,
    val incomeTypeId: UUID,
    val incomeTypeName: String,
    val calculationType: String,
    val feeRate: BigDecimal,
    val minimumFee: BigDecimal?,
    val maximumFee: BigDecimal?,
    val gracePeriodDays: Int,
    val description: String?,
    val isActive: Boolean,
    val createdAt: String
)

// 정기 수입 스케줄 생성 요청
data class CreateRecurringIncomeScheduleRequest(
    val incomeTypeId: UUID,
    val amount: BigDecimal,
    val frequency: String, // MONTHLY, QUARTERLY, YEARLY
    val startDate: LocalDate,
    val endDate: LocalDate? = null,
    val dayOfMonth: Int? = null, // 매월 몇 일에 생성할지
    val description: String? = null,
    val autoApprove: Boolean = false
)

// 정기 수입 스케줄 응답
data class RecurringIncomeScheduleDto(
    val id: UUID,
    val incomeTypeId: UUID,
    val incomeTypeName: String,
    val amount: BigDecimal,
    val frequency: String,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val dayOfMonth: Int?,
    val description: String?,
    val autoApprove: Boolean,
    val isActive: Boolean,
    val lastGeneratedDate: LocalDate?,
    val nextGenerationDate: LocalDate?,
    val createdAt: String
)

// 미수금 요약 응답
data class ReceivableSummaryDto(
    val totalReceivables: BigDecimal,
    val totalOverdue: BigDecimal,
    val overdueCount: Int,
    val averageOverdueDays: Double,
    val collectionRate: BigDecimal
)

// 수입 기록 DTO (페이징용)
data class IncomeRecordDto(
    val id: UUID,
    val incomeTypeId: UUID,
    val incomeTypeName: String,
    val amount: BigDecimal,
    val incomeDate: LocalDate,
    val status: String,
    val description: String?,
    val unitId: String?,
    val period: String?,
    val createdAt: String,
    val updatedAt: String
)

// 미수금 DTO (페이징용)
data class ReceivableDto(
    val id: UUID,
    val incomeRecordId: UUID,
    val unitId: String?,
    val originalAmount: BigDecimal,
    val remainingAmount: BigDecimal,
    val dueDate: LocalDate,
    val overdueDays: Int,
    val lateFee: BigDecimal,
    val status: String,
    val incomeTypeName: String,
    val period: String?,
    val createdAt: String,
    val updatedAt: String
)