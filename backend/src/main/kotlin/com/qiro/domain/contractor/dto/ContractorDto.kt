package com.qiro.domain.contractor.dto

import com.qiro.domain.contractor.entity.Contractor
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 정보 DTO
 */
data class ContractorDto(
    val contractorId: UUID,
    val companyId: UUID,
    val contractorCode: String,
    val contractorName: String,
    val contractorNameEn: String?,
    val businessRegistrationNumber: String,
    val businessType: Contractor.BusinessType,
    val contractorType: Contractor.ContractorType,
    val categoryId: UUID,
    val representativeName: String,
    val contactPerson: String?,
    val phoneNumber: String?,
    val mobileNumber: String?,
    val faxNumber: String?,
    val email: String?,
    val website: String?,
    val address: String,
    val postalCode: String?,
    val city: String?,
    val state: String?,
    val country: String,
    val establishmentDate: LocalDate?,
    val capitalAmount: BigDecimal?,
    val annualRevenue: BigDecimal?,
    val employeeCount: Int?,
    val specializationAreas: String?,
    val serviceRegions: String?,
    val workCapacity: String?,
    val creditRating: String?,
    val financialStatus: Contractor.FinancialStatus,
    val registrationStatus: Contractor.RegistrationStatus,
    val registrationDate: LocalDateTime?,
    val expiryDate: LocalDate?,
    val overallRating: BigDecimal,
    val performanceGrade: Contractor.PerformanceGrade?,
    val contractorStatus: Contractor.ContractorStatus,
    val remarks: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(contractor: Contractor): ContractorDto {
            return ContractorDto(
                contractorId = contractor.contractorId,
                companyId = contractor.companyId,
                contractorCode = contractor.contractorCode,
                contractorName = contractor.contractorName,
                contractorNameEn = contractor.contractorNameEn,
                businessRegistrationNumber = contractor.businessRegistrationNumber,
                businessType = contractor.businessType,
                contractorType = contractor.contractorType,
                categoryId = contractor.categoryId,
                representativeName = contractor.representativeName,
                contactPerson = contractor.contactPerson,
                phoneNumber = contractor.phoneNumber,
                mobileNumber = contractor.mobileNumber,
                faxNumber = contractor.faxNumber,
                email = contractor.email,
                website = contractor.website,
                address = contractor.address,
                postalCode = contractor.postalCode,
                city = contractor.city,
                state = contractor.state,
                country = contractor.country,
                establishmentDate = contractor.establishmentDate,
                capitalAmount = contractor.capitalAmount,
                annualRevenue = contractor.annualRevenue,
                employeeCount = contractor.employeeCount,
                specializationAreas = contractor.specializationAreas,
                serviceRegions = contractor.serviceRegions,
                workCapacity = contractor.workCapacity,
                creditRating = contractor.creditRating,
                financialStatus = contractor.financialStatus,
                registrationStatus = contractor.registrationStatus,
                registrationDate = contractor.registrationDate,
                expiryDate = contractor.expiryDate,
                overallRating = contractor.overallRating,
                performanceGrade = contractor.performanceGrade,
                contractorStatus = contractor.contractorStatus,
                remarks = contractor.remarks,
                createdAt = contractor.createdAt,
                updatedAt = contractor.updatedAt,
                createdBy = contractor.createdBy,
                updatedBy = contractor.updatedBy
            )
        }
    }
}

/**
 * 외부 업체 생성 요청 DTO
 */
data class CreateContractorRequest(
    val contractorCode: String,
    val contractorName: String,
    val contractorNameEn: String?,
    val businessRegistrationNumber: String,
    val businessType: Contractor.BusinessType,
    val contractorType: Contractor.ContractorType,
    val categoryId: UUID,
    val representativeName: String,
    val contactPerson: String?,
    val phoneNumber: String?,
    val mobileNumber: String?,
    val faxNumber: String?,
    val email: String?,
    val website: String?,
    val address: String,
    val postalCode: String?,
    val city: String?,
    val state: String?,
    val country: String = "KR",
    val establishmentDate: LocalDate?,
    val capitalAmount: BigDecimal?,
    val annualRevenue: BigDecimal?,
    val employeeCount: Int?,
    val specializationAreas: String?,
    val serviceRegions: String?,
    val workCapacity: String?,
    val creditRating: String?,
    val remarks: String?
)

/**
 * 외부 업체 수정 요청 DTO
 */
data class UpdateContractorRequest(
    val contractorName: String?,
    val contractorNameEn: String?,
    val contractorType: Contractor.ContractorType?,
    val categoryId: UUID?,
    val representativeName: String?,
    val contactPerson: String?,
    val phoneNumber: String?,
    val mobileNumber: String?,
    val faxNumber: String?,
    val email: String?,
    val website: String?,
    val address: String?,
    val postalCode: String?,
    val city: String?,
    val state: String?,
    val country: String?,
    val establishmentDate: LocalDate?,
    val capitalAmount: BigDecimal?,
    val annualRevenue: BigDecimal?,
    val employeeCount: Int?,
    val specializationAreas: String?,
    val serviceRegions: String?,
    val workCapacity: String?,
    val creditRating: String?,
    val financialStatus: Contractor.FinancialStatus?,
    val contractorStatus: Contractor.ContractorStatus?,
    val remarks: String?
)

/**
 * 외부 업체 검색 조건 DTO
 */
data class ContractorSearchCriteria(
    val contractorName: String?,
    val categoryId: UUID?,
    val contractorType: Contractor.ContractorType?,
    val contractorStatus: Contractor.ContractorStatus?,
    val minRating: BigDecimal?,
    val maxRating: BigDecimal?,
    val performanceGrade: Contractor.PerformanceGrade?,
    val registrationStatus: Contractor.RegistrationStatus?,
    val financialStatus: Contractor.FinancialStatus?
)

/**
 * 외부 업체 요약 정보 DTO
 */
data class ContractorSummaryDto(
    val contractorId: UUID,
    val contractorCode: String,
    val contractorName: String,
    val contractorType: Contractor.ContractorType,
    val overallRating: BigDecimal,
    val performanceGrade: Contractor.PerformanceGrade?,
    val contractorStatus: Contractor.ContractorStatus,
    val phoneNumber: String?,
    val email: String?
) {
    companion object {
        fun from(contractor: Contractor): ContractorSummaryDto {
            return ContractorSummaryDto(
                contractorId = contractor.contractorId,
                contractorCode = contractor.contractorCode,
                contractorName = contractor.contractorName,
                contractorType = contractor.contractorType,
                overallRating = contractor.overallRating,
                performanceGrade = contractor.performanceGrade,
                contractorStatus = contractor.contractorStatus,
                phoneNumber = contractor.phoneNumber,
                email = contractor.email
            )
        }
    }
}