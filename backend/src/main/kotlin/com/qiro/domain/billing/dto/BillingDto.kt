package com.qiro.domain.billing.dto

import com.qiro.domain.billing.entity.BillingStatus
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

// Request DTOs
data class CreateMonthlyBillingRequest(
    @field:NotNull(message = "세대 ID는 필수입니다")
    val unitId: UUID,

    @field:NotNull(message = "계약 ID는 필수입니다")
    val contractId: UUID,

    @field:NotNull(message = "청구 연도는 필수입니다")
    @field:Min(value = 2020, message = "청구 연도는 2020년 이상이어야 합니다")
    @field:Max(value = 2100, message = "청구 연도는 2100년 이하여야 합니다")
    val billingYear: Int,

    @field:NotNull(message = "청구 월은 필수입니다")
    @field:Min(value = 1, message = "청구 월은 1 이상이어야 합니다")
    @field:Max(value = 12, message = "청구 월은 12 이하여야 합니다")
    val billingMonth: Int,

    @field:NotNull(message = "발행일은 필수입니다")
    val issueDate: LocalDate,

    @field:NotNull(message = "납부 기한은 필수입니다")
    @field:Future(message = "납부 기한은 미래 날짜여야 합니다")
    val dueDate: LocalDate,

    // 공과금
    @field:DecimalMin(value = "0", message = "전기료는 0 이상이어야 합니다")
    val electricityFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "가스료는 0 이상이어야 합니다")
    val gasFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "수도료는 0 이상이어야 합니다")
    val waterFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "난방비는 0 이상이어야 합니다")
    val heatingFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "인터넷료는 0 이상이어야 합니다")
    val internetFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "TV료는 0 이상이어야 합니다")
    val tvFee: BigDecimal? = null,

    // 기타 비용
    @field:DecimalMin(value = "0", message = "청소비는 0 이상이어야 합니다")
    val cleaningFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "경비비는 0 이상이어야 합니다")
    val securityFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "승강기료는 0 이상이어야 합니다")
    val elevatorFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "공용구역비는 0 이상이어야 합니다")
    val commonAreaFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "수선충당금은 0 이상이어야 합니다")
    val repairReserveFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "보험료는 0 이상이어야 합니다")
    val insuranceFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "기타비용은 0 이상이어야 합니다")
    val otherFees: BigDecimal? = null,

    // 할인/조정
    @field:DecimalMin(value = "0", message = "할인금액은 0 이상이어야 합니다")
    val discountAmount: BigDecimal? = null,

    @field:Size(max = 200, message = "할인사유는 200자를 초과할 수 없습니다")
    val discountReason: String? = null,

    val adjustmentAmount: BigDecimal? = null,

    @field:Size(max = 200, message = "조정사유는 200자를 초과할 수 없습니다")
    val adjustmentReason: String? = null,

    @field:Size(max = 1000, message = "비고는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

data class UpdateMonthlyBillingRequest(
    @field:NotNull(message = "발행일은 필수입니다")
    val issueDate: LocalDate,

    @field:NotNull(message = "납부 기한은 필수입니다")
    val dueDate: LocalDate,

    // 공과금
    @field:DecimalMin(value = "0", message = "전기료는 0 이상이어야 합니다")
    val electricityFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "가스료는 0 이상이어야 합니다")
    val gasFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "수도료는 0 이상이어야 합니다")
    val waterFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "난방비는 0 이상이어야 합니다")
    val heatingFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "인터넷료는 0 이상이어야 합니다")
    val internetFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "TV료는 0 이상이어야 합니다")
    val tvFee: BigDecimal? = null,

    // 기타 비용
    @field:DecimalMin(value = "0", message = "청소비는 0 이상이어야 합니다")
    val cleaningFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "경비비는 0 이상이어야 합니다")
    val securityFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "승강기료는 0 이상이어야 합니다")
    val elevatorFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "공용구역비는 0 이상이어야 합니다")
    val commonAreaFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "수선충당금은 0 이상이어야 합니다")
    val repairReserveFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "보험료는 0 이상이어야 합니다")
    val insuranceFee: BigDecimal? = null,

    @field:DecimalMin(value = "0", message = "기타비용은 0 이상이어야 합니다")
    val otherFees: BigDecimal? = null,

    // 할인/조정
    @field:DecimalMin(value = "0", message = "할인금액은 0 이상이어야 합니다")
    val discountAmount: BigDecimal? = null,

    @field:Size(max = 200, message = "할인사유는 200자를 초과할 수 없습니다")
    val discountReason: String? = null,

    val adjustmentAmount: BigDecimal? = null,

    @field:Size(max = 200, message = "조정사유는 200자를 초과할 수 없습니다")
    val adjustmentReason: String? = null,

    @field:Size(max = 1000, message = "비고는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

data class ProcessPaymentRequest(
    @field:NotNull(message = "결제 금액은 필수입니다")
    @field:DecimalMin(value = "0.01", message = "결제 금액은 0보다 커야 합니다")
    val amount: BigDecimal,

    @field:NotNull(message = "결제일은 필수입니다")
    val paymentDate: LocalDate,

    @field:Size(max = 50, message = "결제 방법은 50자를 초과할 수 없습니다")
    val paymentMethod: String? = null,

    @field:Size(max = 100, message = "결제 참조번호는 100자를 초과할 수 없습니다")
    val paymentReference: String? = null
)

data class SendBillingRequest(
    @field:NotBlank(message = "발송 방법은 필수입니다")
    @field:Size(max = 50, message = "발송 방법은 50자를 초과할 수 없습니다")
    val sendMethod: String,

    @field:Email(message = "올바른 이메일 형식이 아닙니다")
    val recipientEmail: String? = null,

    @field:Pattern(
        regexp = "^\\d{2,3}-\\d{3,4}-\\d{4}$",
        message = "올바른 전화번호 형식이 아닙니다"
    )
    val recipientPhone: String? = null
)

data class BulkCreateBillingRequest(
    @field:NotNull(message = "청구 연도는 필수입니다")
    @field:Min(value = 2020, message = "청구 연도는 2020년 이상이어야 합니다")
    @field:Max(value = 2100, message = "청구 연도는 2100년 이하여야 합니다")
    val billingYear: Int,

    @field:NotNull(message = "청구 월은 필수입니다")
    @field:Min(value = 1, message = "청구 월은 1 이상이어야 합니다")
    @field:Max(value = 12, message = "청구 월은 12 이하여야 합니다")
    val billingMonth: Int,

    @field:NotNull(message = "발행일은 필수입니다")
    val issueDate: LocalDate,

    @field:NotNull(message = "납부 기한은 필수입니다")
    @field:Future(message = "납부 기한은 미래 날짜여야 합니다")
    val dueDate: LocalDate,

    @field:NotEmpty(message = "건물 ID 목록은 필수입니다")
    val buildingIds: List<UUID>
)

// Response DTOs
data class MonthlyBillingDto(
    val billingId: UUID,
    val billingNumber: String,
    val billingYear: Int,
    val billingMonth: Int,
    val billingStatus: BillingStatus,
    val issueDate: LocalDate,
    val dueDate: LocalDate,
    
    // 기본 임대료 정보
    val monthlyRent: BigDecimal,
    val maintenanceFee: BigDecimal?,
    val parkingFee: BigDecimal?,
    
    // 공과금
    val electricityFee: BigDecimal?,
    val gasFee: BigDecimal?,
    val waterFee: BigDecimal?,
    val heatingFee: BigDecimal?,
    val internetFee: BigDecimal?,
    val tvFee: BigDecimal?,
    
    // 기타 비용
    val cleaningFee: BigDecimal?,
    val securityFee: BigDecimal?,
    val elevatorFee: BigDecimal?,
    val commonAreaFee: BigDecimal?,
    val repairReserveFee: BigDecimal?,
    val insuranceFee: BigDecimal?,
    val otherFees: BigDecimal?,
    
    // 할인/조정
    val discountAmount: BigDecimal?,
    val discountReason: String?,
    val lateFee: BigDecimal?,
    val adjustmentAmount: BigDecimal?,
    val adjustmentReason: String?,
    
    // 계산된 금액
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val unpaidAmount: BigDecimal,
    
    // 결제 정보
    val paymentDate: LocalDate?,
    val paymentMethod: String?,
    val paymentReference: String?,
    
    // 발송 정보
    val sentDate: LocalDateTime?,
    val sentMethod: String?,
    val recipientEmail: String?,
    val recipientPhone: String?,
    
    // 관련 정보
    val unit: BillingUnitDto,
    val contract: BillingContractDto,
    
    // 상태 정보
    val isFullyPaid: Boolean,
    val isOverdue: Boolean,
    val daysPastDue: Long?,
    
    val notes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class MonthlyBillingSummaryDto(
    val billingId: UUID,
    val billingNumber: String,
    val billingYear: Int,
    val billingMonth: Int,
    val billingStatus: BillingStatus,
    val dueDate: LocalDate,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val unpaidAmount: BigDecimal,
    val unitNumber: String,
    val buildingName: String,
    val tenantName: String,
    val isOverdue: Boolean,
    val daysPastDue: Long?
)

data class BillingUnitDto(
    val unitId: UUID,
    val unitNumber: String,
    val buildingName: String,
    val floor: Int
)

data class BillingContractDto(
    val contractId: UUID,
    val contractNumber: String,
    val tenantName: String,
    val lessorName: String,
    val monthlyRent: BigDecimal,
    val maintenanceFee: BigDecimal?,
    val parkingFee: BigDecimal?
)

data class BillingStatisticsDto(
    val totalBillings: Long,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val unpaidAmount: BigDecimal,
    val overdueAmount: BigDecimal,
    val collectionRate: BigDecimal,
    val averageBillingAmount: BigDecimal,
    val statusStats: List<BillingStatusStatsDto>,
    val monthlyStats: List<BillingMonthlyStatsDto>
)

data class BillingStatusStatsDto(
    val status: BillingStatus,
    val count: Long,
    val totalAmount: BigDecimal,
    val percentage: BigDecimal
)

data class BillingMonthlyStatsDto(
    val year: Int,
    val month: Int,
    val totalBillings: Long,
    val totalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val collectionRate: BigDecimal
)

data class BulkCreateResultDto(
    val successCount: Int,
    val failureCount: Int,
    val createdBillings: List<UUID>,
    val errors: List<String>
)