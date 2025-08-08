package com.qiro.domain.accounting.dto

import com.qiro.domain.accounting.entity.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 지출 유형 DTO
 */
data class ExpenseTypeDto(
    val expenseTypeId: UUID,
    val companyId: UUID,
    val typeCode: String,
    val typeName: String,
    val description: String?,
    val category: ExpenseType.Category,
    val isRecurring: Boolean,
    val requiresApproval: Boolean,
    val approvalLimit: BigDecimal?,
    val defaultAccountId: UUID?,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(entity: ExpenseType): ExpenseTypeDto {
            return ExpenseTypeDto(
                expenseTypeId = entity.expenseTypeId,
                companyId = entity.companyId,
                typeCode = entity.typeCode,
                typeName = entity.typeName,
                description = entity.description,
                category = entity.category,
                isRecurring = entity.isRecurring,
                requiresApproval = entity.requiresApproval,
                approvalLimit = entity.approvalLimit,
                defaultAccountId = entity.defaultAccountId,
                isActive = entity.isActive,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
}

/**
 * 지출 기록 DTO
 */
data class ExpenseRecordDto(
    val expenseRecordId: UUID,
    val companyId: UUID,
    val expenseType: ExpenseTypeDto,
    val buildingId: UUID?,
    val unitId: UUID?,
    val vendor: VendorDto?,
    val expenseDate: LocalDate,
    val dueDate: LocalDate?,
    val amount: BigDecimal,
    val taxAmount: BigDecimal,
    val totalAmount: BigDecimal,
    val paymentMethod: String?,
    val bankAccountId: UUID?,
    val referenceNumber: String?,
    val invoiceNumber: String?,
    val description: String?,
    val status: ExpenseRecord.Status,
    val approvalStatus: ExpenseRecord.ApprovalStatus,
    val approvedBy: UUID?,
    val approvedAt: LocalDateTime?,
    val paidAt: LocalDateTime?,
    val journalEntryId: UUID?,
    val createdBy: UUID,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(entity: ExpenseRecord): ExpenseRecordDto {
            return ExpenseRecordDto(
                expenseRecordId = entity.expenseRecordId,
                companyId = entity.companyId,
                expenseType = ExpenseTypeDto.from(entity.expenseType),
                buildingId = entity.buildingId,
                unitId = entity.unitId,
                vendor = entity.vendor?.let { VendorDto.from(it) },
                expenseDate = entity.expenseDate,
                dueDate = entity.dueDate,
                amount = entity.amount,
                taxAmount = entity.taxAmount,
                totalAmount = entity.totalAmount,
                paymentMethod = entity.paymentMethod,
                bankAccountId = entity.bankAccountId,
                referenceNumber = entity.referenceNumber,
                invoiceNumber = entity.invoiceNumber,
                description = entity.description,
                status = entity.status,
                approvalStatus = entity.approvalStatus,
                approvedBy = entity.approvedBy,
                approvedAt = entity.approvedAt,
                paidAt = entity.paidAt,
                journalEntryId = entity.journalEntryId,
                createdBy = entity.createdBy,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
}

/**
 * 업체 DTO
 */
data class VendorDto(
    val vendorId: UUID,
    val companyId: UUID,
    val vendorCode: String,
    val vendorName: String,
    val businessNumber: String?,
    val contactPerson: String?,
    val phoneNumber: String?,
    val email: String?,
    val address: String?,
    val bankAccount: String?,
    val bankName: String?,
    val accountHolder: String?,
    val vendorType: String?,
    val paymentTerms: Int,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(entity: Vendor): VendorDto {
            return VendorDto(
                vendorId = entity.vendorId,
                companyId = entity.companyId,
                vendorCode = entity.vendorCode,
                vendorName = entity.vendorName,
                businessNumber = entity.businessNumber,
                contactPerson = entity.contactPerson,
                phoneNumber = entity.phoneNumber,
                email = entity.email,
                address = entity.address,
                bankAccount = entity.bankAccount,
                bankName = entity.bankName,
                accountHolder = entity.accountHolder,
                vendorType = entity.vendorType,
                paymentTerms = entity.paymentTerms,
                isActive = entity.isActive,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
}

/**
 * 정기 지출 스케줄 DTO
 */
data class RecurringExpenseScheduleDto(
    val scheduleId: UUID,
    val companyId: UUID,
    val expenseType: ExpenseTypeDto,
    val buildingId: UUID?,
    val unitId: UUID?,
    val vendor: VendorDto?,
    val scheduleName: String,
    val frequency: RecurringExpenseSchedule.Frequency,
    val intervalValue: Int,
    val amount: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val nextGenerationDate: LocalDate,
    val lastGeneratedDate: LocalDate?,
    val autoApprove: Boolean,
    val isActive: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
) {
    companion object {
        fun from(entity: RecurringExpenseSchedule): RecurringExpenseScheduleDto {
            return RecurringExpenseScheduleDto(
                scheduleId = entity.scheduleId,
                companyId = entity.companyId,
                expenseType = ExpenseTypeDto.from(entity.expenseType),
                buildingId = entity.buildingId,
                unitId = entity.unitId,
                vendor = entity.vendor?.let { VendorDto.from(it) },
                scheduleName = entity.scheduleName,
                frequency = entity.frequency,
                intervalValue = entity.intervalValue,
                amount = entity.amount,
                startDate = entity.startDate,
                endDate = entity.endDate,
                nextGenerationDate = entity.nextGenerationDate,
                lastGeneratedDate = entity.lastGeneratedDate,
                autoApprove = entity.autoApprove,
                isActive = entity.isActive,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt
            )
        }
    }
}

// 요청 DTO들

/**
 * 지출 유형 생성 요청 DTO
 */
data class CreateExpenseTypeRequest(
    val typeCode: String,
    val typeName: String,
    val description: String?,
    val category: ExpenseType.Category,
    val isRecurring: Boolean = false,
    val requiresApproval: Boolean = true,
    val approvalLimit: BigDecimal?,
    val defaultAccountId: UUID?
)

/**
 * 지출 기록 생성 요청 DTO
 */
data class CreateExpenseRecordRequest(
    val expenseTypeId: UUID,
    val buildingId: UUID?,
    val unitId: UUID?,
    val vendorId: UUID?,
    val expenseDate: LocalDate,
    val dueDate: LocalDate?,
    val amount: BigDecimal,
    val taxAmount: BigDecimal = BigDecimal.ZERO,
    val paymentMethod: String?,
    val bankAccountId: UUID?,
    val referenceNumber: String?,
    val invoiceNumber: String?,
    val description: String?
)

/**
 * 업체 생성 요청 DTO
 */
data class CreateVendorRequest(
    val vendorCode: String,
    val vendorName: String,
    val businessNumber: String?,
    val contactPerson: String?,
    val phoneNumber: String?,
    val email: String?,
    val address: String?,
    val bankAccount: String?,
    val bankName: String?,
    val accountHolder: String?,
    val vendorType: String?,
    val paymentTerms: Int = 30
)

/**
 * 정기 지출 스케줄 생성 요청 DTO
 */
data class CreateRecurringExpenseScheduleRequest(
    val expenseTypeId: UUID,
    val buildingId: UUID?,
    val unitId: UUID?,
    val vendorId: UUID?,
    val scheduleName: String,
    val frequency: RecurringExpenseSchedule.Frequency,
    val intervalValue: Int = 1,
    val amount: BigDecimal,
    val startDate: LocalDate,
    val endDate: LocalDate?,
    val autoApprove: Boolean = false
)

// 응답 DTO들

/**
 * 지출 현황 요약 DTO
 */
data class ExpenseSummaryDto(
    val totalExpense: BigDecimal,
    val pendingApprovalAmount: BigDecimal,
    val paidAmount: BigDecimal,
    val pendingApprovalCount: Long,
    val expenseByCategory: Map<ExpenseType.Category, BigDecimal>
)

/**
 * 지출 통계 DTO
 */
data class ExpenseStatisticsDto(
    val totalExpense: BigDecimal,
    val expenseByType: Map<String, BigDecimal>,
    val expenseByCategory: Map<ExpenseType.Category, BigDecimal>,
    val monthlyExpense: List<MonthlyExpenseDto>,
    val vendorStatistics: List<VendorExpenseDto>
)

/**
 * 월별 지출 DTO
 */
data class MonthlyExpenseDto(
    val year: Int,
    val month: Int,
    val totalAmount: BigDecimal
)

/**
 * 업체별 지출 DTO
 */
data class VendorExpenseDto(
    val vendorName: String,
    val transactionCount: Long,
    val totalAmount: BigDecimal
)