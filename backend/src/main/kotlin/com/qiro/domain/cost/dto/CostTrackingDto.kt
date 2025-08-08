package com.qiro.domain.cost.dto

import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 비용 추적 DTO
 */
data class CostTrackingDto(
    val costId: UUID,
    val companyId: UUID,
    val workOrderId: UUID?,
    val maintenanceId: UUID?,
    val faultReportId: UUID?,
    val costNumber: String,
    val costType: CostType,
    val category: CostCategory,
    val amount: BigDecimal,
    val currency: String,
    val costDate: LocalDate,
    val description: String?,
    val paymentMethod: PaymentMethod?,
    val invoiceNumber: String?,
    val receiptNumber: String?,
    val approvedBy: UUID?,
    val approvalDate: LocalDateTime?,
    val approvalNotes: String?,
    val budgetCategory: String?,
    val budgetYear: Int?,
    val budgetMonth: Int?,
    val createdAt: LocalDateTime,
    val createdBy: UUID,
    val updatedAt: LocalDateTime?,
    val updatedBy: UUID?
)

/**
 * 비용 기록 생성 요청 DTO
 */
data class CreateCostTrackingRequest(
    val workOrderId: UUID? = null,
    val maintenanceId: UUID? = null,
    val faultReportId: UUID? = null,
    val costType: CostType,
    val category: CostCategory,
    val amount: BigDecimal,
    val costDate: LocalDate,
    val description: String? = null,
    val paymentMethod: PaymentMethod? = null,
    val invoiceNumber: String? = null,
    val receiptNumber: String? = null,
    val budgetCategory: String? = null
)

/**
 * 비용 기록 수정 요청 DTO
 */
data class UpdateCostTrackingRequest(
    val amount: BigDecimal? = null,
    val costDate: LocalDate? = null,
    val description: String? = null,
    val paymentMethod: PaymentMethod? = null,
    val invoiceNumber: String? = null,
    val receiptNumber: String? = null,
    val budgetCategory: String? = null
)

/**
 * 비용 승인 요청 DTO
 */
data class ApproveCostRequest(
    val approvalNotes: String? = null
)

/**
 * 비용 통계 DTO
 */
data class CostStatisticsDto(
    val totalCost: BigDecimal,
    val transactionCount: Long,
    val averageCost: BigDecimal,
    val laborCost: BigDecimal,
    val materialCost: BigDecimal,
    val equipmentCost: BigDecimal,
    val contractorCost: BigDecimal,
    val emergencyCost: BigDecimal,
    val preventiveCost: BigDecimal,
    val correctiveCost: BigDecimal,
    val upgradeCost: BigDecimal
)

/**
 * 월별 비용 트렌드 DTO
 */
data class MonthlyCostTrendDto(
    val monthNumber: Int,
    val monthName: String,
    val totalCost: BigDecimal,
    val transactionCount: Long,
    val averageCost: BigDecimal,
    val costChangePercentage: BigDecimal
)

/**
 * 비용 요약 DTO
 */
data class CostSummaryDto(
    val period: String,
    val totalCost: BigDecimal,
    val costByType: Map<CostType, BigDecimal>,
    val costByCategory: Map<CostCategory, BigDecimal>,
    val transactionCount: Long,
    val averageCost: BigDecimal,
    val topExpenses: List<CostTrackingDto>
)

/**
 * 비용 유형 열거형
 */
enum class CostType {
    LABOR,          // 인건비
    MATERIAL,       // 자재비
    EQUIPMENT,      // 장비비
    CONTRACTOR,     // 외주비
    EMERGENCY,      // 응급비용
    MISCELLANEOUS   // 기타비용
}

/**
 * 비용 카테고리 열거형
 */
enum class CostCategory {
    PREVENTIVE,     // 예방정비
    CORRECTIVE,     // 수정정비
    EMERGENCY,      // 응급수리
    UPGRADE,        // 업그레이드
    INSPECTION      // 점검
}

/**
 * 결제 방법 열거형
 */
enum class PaymentMethod {
    CASH,           // 현금
    CARD,           // 카드
    TRANSFER,       // 계좌이체
    CHECK           // 수표
}

/**
 * 비용 필터 DTO
 */
data class CostTrackingFilter(
    val costType: CostType? = null,
    val category: CostCategory? = null,
    val startDate: LocalDate? = null,
    val endDate: LocalDate? = null,
    val minAmount: BigDecimal? = null,
    val maxAmount: BigDecimal? = null,
    val paymentMethod: PaymentMethod? = null,
    val budgetCategory: String? = null,
    val budgetYear: Int? = null,
    val approvalStatus: ApprovalStatus? = null
)

/**
 * 승인 상태 열거형
 */
enum class ApprovalStatus {
    PENDING,        // 승인 대기
    APPROVED,       // 승인됨
    REJECTED        // 거부됨
}