package com.qiro.domain.lease.dto

import com.qiro.domain.lease.entity.ContractStatus
import com.qiro.domain.lease.entity.ContractType
import jakarta.validation.constraints.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

// Request DTOs
data class CreateLeaseContractRequest(
    @field:NotNull(message = "세대 ID는 필수입니다")
    val unitId: UUID,
    
    @field:NotNull(message = "임대인 ID는 필수입니다")
    val lessorId: UUID,
    
    @field:NotNull(message = "임차인 ID는 필수입니다")
    val tenantId: UUID,
    
    @field:NotBlank(message = "계약 번호는 필수입니다")
    @field:Size(max = 50, message = "계약 번호는 50자를 초과할 수 없습니다")
    val contractNumber: String,
    
    @field:NotNull(message = "계약 유형은 필수입니다")
    val contractType: ContractType,
    
    @field:NotNull(message = "계약 시작일은 필수입니다")
    val startDate: LocalDate,
    
    @field:NotNull(message = "계약 종료일은 필수입니다")
    val endDate: LocalDate,
    
    @field:NotNull(message = "월 임대료는 필수입니다")
    @field:DecimalMin(value = "0", message = "월 임대료는 0 이상이어야 합니다")
    val monthlyRent: BigDecimal,
    
    @field:NotNull(message = "보증금은 필수입니다")
    @field:DecimalMin(value = "0", message = "보증금은 0 이상이어야 합니다")
    val securityDeposit: BigDecimal,
    
    @field:DecimalMin(value = "0", message = "권리금은 0 이상이어야 합니다")
    val keyMoney: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "관리비는 0 이상이어야 합니다")
    val maintenanceFee: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "공과금 보증금은 0 이상이어야 합니다")
    val utilityDeposit: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "주차비는 0 이상이어야 합니다")
    val parkingFee: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "연체료율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "연체료율은 100 이하여야 합니다")
    val lateFeeRate: BigDecimal? = null,
    
    @field:Min(value = 1, message = "임대료 납부일은 1일 이상이어야 합니다")
    @field:Max(value = 31, message = "임대료 납부일은 31일 이하여야 합니다")
    val rentDueDay: Int = 1,
    
    @field:Min(value = 0, message = "유예 기간은 0일 이상이어야 합니다")
    val gracePeriodDays: Int? = null,
    
    val autoRenewal: Boolean = false,
    
    @field:Min(value = 1, message = "갱신 통지 기간은 1일 이상이어야 합니다")
    val renewalNoticeDays: Int? = null,
    
    val earlyTerminationAllowed: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "조기 해지 위약금은 0 이상이어야 합니다")
    val earlyTerminationPenalty: BigDecimal? = null,
    
    val petAllowed: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "반려동물 보증금은 0 이상이어야 합니다")
    val petDeposit: BigDecimal? = null,
    
    val smokingAllowed: Boolean = false,
    val sublettingAllowed: Boolean = false,
    val utilitiesIncluded: Boolean = false,
    val furnished: Boolean = false,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    val storageIncluded: Boolean = false,
    
    @field:Size(max = 2000, message = "특별 조건은 2000자를 초과할 수 없습니다")
    val specialTerms: String? = null,
    
    @field:Size(max = 1000, message = "비고는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

data class UpdateLeaseContractRequest(
    @field:NotNull(message = "계약 유형은 필수입니다")
    val contractType: ContractType,
    
    @field:NotNull(message = "계약 시작일은 필수입니다")
    val startDate: LocalDate,
    
    @field:NotNull(message = "계약 종료일은 필수입니다")
    val endDate: LocalDate,
    
    @field:NotNull(message = "월 임대료는 필수입니다")
    @field:DecimalMin(value = "0", message = "월 임대료는 0 이상이어야 합니다")
    val monthlyRent: BigDecimal,
    
    @field:NotNull(message = "보증금은 필수입니다")
    @field:DecimalMin(value = "0", message = "보증금은 0 이상이어야 합니다")
    val securityDeposit: BigDecimal,
    
    @field:DecimalMin(value = "0", message = "권리금은 0 이상이어야 합니다")
    val keyMoney: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "관리비는 0 이상이어야 합니다")
    val maintenanceFee: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "공과금 보증금은 0 이상이어야 합니다")
    val utilityDeposit: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "주차비는 0 이상이어야 합니다")
    val parkingFee: BigDecimal? = null,
    
    @field:DecimalMin(value = "0", message = "연체료율은 0 이상이어야 합니다")
    @field:DecimalMax(value = "100", message = "연체료율은 100 이하여야 합니다")
    val lateFeeRate: BigDecimal? = null,
    
    @field:Min(value = 1, message = "임대료 납부일은 1일 이상이어야 합니다")
    @field:Max(value = 31, message = "임대료 납부일은 31일 이하여야 합니다")
    val rentDueDay: Int = 1,
    
    @field:Min(value = 0, message = "유예 기간은 0일 이상이어야 합니다")
    val gracePeriodDays: Int? = null,
    
    val autoRenewal: Boolean = false,
    
    @field:Min(value = 1, message = "갱신 통지 기간은 1일 이상이어야 합니다")
    val renewalNoticeDays: Int? = null,
    
    val earlyTerminationAllowed: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "조기 해지 위약금은 0 이상이어야 합니다")
    val earlyTerminationPenalty: BigDecimal? = null,
    
    val petAllowed: Boolean = false,
    
    @field:DecimalMin(value = "0", message = "반려동물 보증금은 0 이상이어야 합니다")
    val petDeposit: BigDecimal? = null,
    
    val smokingAllowed: Boolean = false,
    val sublettingAllowed: Boolean = false,
    val utilitiesIncluded: Boolean = false,
    val furnished: Boolean = false,
    
    @field:Min(value = 0, message = "주차 공간은 0 이상이어야 합니다")
    val parkingSpaces: Int? = null,
    
    val storageIncluded: Boolean = false,
    
    @field:Size(max = 2000, message = "특별 조건은 2000자를 초과할 수 없습니다")
    val specialTerms: String? = null,
    
    @field:Size(max = 1000, message = "비고는 1000자를 초과할 수 없습니다")
    val notes: String? = null
)

data class SignContractRequest(
    @field:NotNull(message = "서명일은 필수입니다")
    val signatureDate: LocalDate,
    
    @field:NotNull(message = "서명자 유형은 필수입니다")
    val signerType: SignerType,
    
    val witnessName: String? = null,
    val witnessSignatureDate: LocalDate? = null
)

data class ActivateContractRequest(
    @field:NotNull(message = "입주일은 필수입니다")
    val moveInDate: LocalDate
)

data class TerminateContractRequest(
    @field:NotNull(message = "해지일은 필수입니다")
    val terminationDate: LocalDate,
    
    @field:Size(max = 500, message = "해지 사유는 500자를 초과할 수 없습니다")
    val reason: String? = null
)

data class RenewContractRequest(
    @field:NotNull(message = "새로운 계약 종료일은 필수입니다")
    val newEndDate: LocalDate,
    
    @field:DecimalMin(value = "0", message = "새로운 월 임대료는 0 이상이어야 합니다")
    val newMonthlyRent: BigDecimal? = null
)

data class ContractSearchRequest(
    val contractStatus: ContractStatus? = null,
    val contractType: ContractType? = null,
    val unitId: UUID? = null,
    val tenantId: UUID? = null,
    val lessorId: UUID? = null,
    val startDateFrom: LocalDate? = null,
    val startDateTo: LocalDate? = null,
    val endDateFrom: LocalDate? = null,
    val endDateTo: LocalDate? = null
)

// Response DTOs
data class LeaseContractDto(
    val contractId: UUID,
    val contractNumber: String,
    val contractType: ContractType,
    val contractStatus: ContractStatus,
    val unitInfo: UnitInfo,
    val lessorInfo: LessorInfo,
    val tenantInfo: TenantInfo,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val monthlyRent: BigDecimal,
    val securityDeposit: BigDecimal,
    val keyMoney: BigDecimal?,
    val maintenanceFee: BigDecimal?,
    val utilityDeposit: BigDecimal?,
    val parkingFee: BigDecimal?,
    val totalDeposit: BigDecimal,
    val totalMonthlyPayment: BigDecimal,
    val lateFeeRate: BigDecimal?,
    val rentDueDay: Int,
    val gracePeriodDays: Int?,
    val autoRenewal: Boolean,
    val renewalNoticeDays: Int?,
    val earlyTerminationAllowed: Boolean,
    val earlyTerminationPenalty: BigDecimal?,
    val petAllowed: Boolean,
    val petDeposit: BigDecimal?,
    val smokingAllowed: Boolean,
    val sublettingAllowed: Boolean,
    val utilitiesIncluded: Boolean,
    val furnished: Boolean,
    val parkingSpaces: Int?,
    val storageIncluded: Boolean,
    val signedDate: LocalDate?,
    val moveInDate: LocalDate?,
    val moveOutDate: LocalDate?,
    val actualEndDate: LocalDate?,
    val renewalCount: Int,
    val parentContractId: UUID?,
    val terminationReason: String?,
    val specialTerms: String?,
    val lessorSignatureDate: LocalDate?,
    val tenantSignatureDate: LocalDate?,
    val witnessName: String?,
    val witnessSignatureDate: LocalDate?,
    val contractDocumentPath: String?,
    val notes: String?,
    val durationInMonths: Long,
    val isExpiringSoon: Boolean,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

data class LeaseContractSummaryDto(
    val contractId: UUID,
    val contractNumber: String,
    val contractType: ContractType,
    val contractStatus: ContractStatus,
    val unitNumber: String,
    val buildingName: String,
    val tenantName: String,
    val lessorName: String,
    val startDate: LocalDate,
    val endDate: LocalDate,
    val monthlyRent: BigDecimal,
    val totalDeposit: BigDecimal,
    val isExpiringSoon: Boolean
)

data class UnitInfo(
    val unitId: UUID,
    val unitNumber: String,
    val buildingId: UUID,
    val buildingName: String,
    val floor: Int,
    val exclusiveArea: BigDecimal
)

data class LessorInfo(
    val lessorId: UUID,
    val lessorName: String,
    val contactPhone: String,
    val contactEmail: String?
)

data class TenantInfo(
    val tenantId: UUID,
    val tenantName: String,
    val contactPhone: String,
    val contactEmail: String?
)

data class ContractStatusStatsDto(
    val status: ContractStatus,
    val count: Long,
    val percentage: BigDecimal
)

data class ContractTypeStatsDto(
    val type: ContractType,
    val count: Long,
    val averageRent: BigDecimal?,
    val totalRent: BigDecimal?,
    val percentage: BigDecimal
)

enum class SignerType {
    LESSOR, TENANT
}