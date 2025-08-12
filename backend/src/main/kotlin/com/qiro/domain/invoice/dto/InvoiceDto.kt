package com.qiro.domain.invoice.dto

import com.qiro.domain.invoice.entity.InvoiceStatus
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 고지서 생성 요청 DTO
 */
data class CreateInvoiceRequest(
    val unitId: UUID,
    val billingId: UUID,
    val dueDate: LocalDate,
    val notes: String? = null
)

/**
 * 고지서 응답 DTO
 */
data class InvoiceResponse(
    val id: UUID,
    val invoiceNumber: String,
    val unitNumber: String,
    val unitId: UUID,
    val billingId: UUID,
    val billingMonth: String,
    val issueDate: LocalDate,
    val dueDate: LocalDate,
    val status: InvoiceStatus,
    val statusDisplayName: String,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val lateFee: BigDecimal,
    val discountAmount: BigDecimal,
    val outstandingAmount: BigDecimal,
    val isFullyPaid: Boolean,
    val isOverdue: Boolean,
    val overdueDays: Long,
    val pdfFilePath: String?,
    val sentDate: LocalDateTime?,
    val notes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

/**
 * 고지서 목록 조회 요청 DTO
 */
data class InvoiceSearchRequest(
    val unitId: UUID? = null,
    val status: InvoiceStatus? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val overdueOnly: Boolean = false,
    val page: Int = 0,
    val size: Int = 20
)

/**
 * 고지서 결제 처리 요청 DTO
 */
data class ProcessPaymentRequest(
    val amount: BigDecimal,
    val paymentDate: LocalDate = LocalDate.now(),
    val paymentMethod: String,
    val notes: String? = null
)

/**
 * 연체료 적용 요청 DTO
 */
data class ApplyLateFeeRequest(
    val lateFee: BigDecimal,
    val reason: String? = null
)

/**
 * 할인 적용 요청 DTO
 */
data class ApplyDiscountRequest(
    val discountAmount: BigDecimal,
    val reason: String
)

/**
 * 고지서 취소 요청 DTO
 */
data class CancelInvoiceRequest(
    val reason: String
)

/**
 * 고지서 통계 응답 DTO
 */
data class InvoiceStatisticsResponse(
    val totalCount: Long,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val outstandingAmount: BigDecimal,
    val collectionRate: BigDecimal // 수납률
) {
    companion object {
        fun from(stats: com.qiro.domain.invoice.repository.InvoiceStatistics): InvoiceStatisticsResponse {
            val collectionRate = if (stats.totalAmount > BigDecimal.ZERO) {
                stats.paidAmount.divide(stats.totalAmount, 4, java.math.RoundingMode.HALF_UP)
                    .multiply(BigDecimal(100))
            } else {
                BigDecimal.ZERO
            }
            
            return InvoiceStatisticsResponse(
                totalCount = stats.totalCount,
                totalAmount = stats.totalAmount,
                paidAmount = stats.paidAmount,
                outstandingAmount = stats.outstandingAmount,
                collectionRate = collectionRate
            )
        }
    }
}

/**
 * 연체 통계 응답 DTO
 */
data class OverdueStatisticsResponse(
    val overdueCount: Long,
    val overdueAmount: BigDecimal
) {
    companion object {
        fun from(stats: com.qiro.domain.invoice.repository.OverdueStatistics): OverdueStatisticsResponse {
            return OverdueStatisticsResponse(
                overdueCount = stats.overdueCount,
                overdueAmount = stats.overdueAmount
            )
        }
    }
}

/**
 * 월별 고지서 통계 응답 DTO
 */
data class MonthlyInvoiceStatsResponse(
    val year: Int,
    val month: Int,
    val invoiceCount: Long,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val collectionRate: BigDecimal
) {
    companion object {
        fun from(stats: com.qiro.domain.invoice.repository.MonthlyInvoiceStats): MonthlyInvoiceStatsResponse {
            val collectionRate = if (stats.totalAmount > BigDecimal.ZERO) {
                stats.paidAmount.divide(stats.totalAmount, 4, java.math.RoundingMode.HALF_UP)
                    .multiply(BigDecimal(100))
            } else {
                BigDecimal.ZERO
            }
            
            return MonthlyInvoiceStatsResponse(
                year = stats.year,
                month = stats.month,
                invoiceCount = stats.invoiceCount,
                totalAmount = stats.totalAmount,
                paidAmount = stats.paidAmount,
                collectionRate = collectionRate
            )
        }
    }
}

/**
 * 세대별 미납 통계 응답 DTO
 */
data class UnitUnpaidStatsResponse(
    val unitId: UUID,
    val unitNumber: String,
    val unpaidCount: Long,
    val unpaidAmount: BigDecimal
) {
    companion object {
        fun from(stats: com.qiro.domain.invoice.repository.UnitUnpaidStats): UnitUnpaidStatsResponse {
            return UnitUnpaidStatsResponse(
                unitId = stats.unitId,
                unitNumber = stats.unitNumber,
                unpaidCount = stats.unpaidCount,
                unpaidAmount = stats.unpaidAmount
            )
        }
    }
}

/**
 * 고지서 대시보드 응답 DTO
 */
data class InvoiceDashboardResponse(
    val totalStatistics: InvoiceStatisticsResponse,
    val overdueStatistics: OverdueStatisticsResponse,
    val monthlyStats: List<MonthlyInvoiceStatsResponse>,
    val topUnpaidUnits: List<UnitUnpaidStatsResponse>
)