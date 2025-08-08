package com.qiro.domain.contractor.dto

import com.qiro.domain.contractor.entity.OutsourcingWorkRequest
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외주 작업 요청 DTO
 */
data class OutsourcingWorkRequestDto(
    val requestId: UUID,
    val companyId: UUID,
    val requestNumber: String,
    val requestTitle: String,
    val requestType: OutsourcingWorkRequest.RequestType,
    val requestDate: LocalDateTime,
    val requesterId: UUID,
    val department: String?,
    val costCenter: String?,
    val workDescription: String,
    val workLocation: String?,
    val workScope: String?,
    val technicalRequirements: String?,
    val requiredStartDate: LocalDate?,
    val requiredCompletionDate: LocalDate?,
    val estimatedDuration: Int?,
    val estimatedBudget: BigDecimal,
    val budgetCode: String?,
    val currencyCode: String,
    val priorityLevel: OutsourcingWorkRequest.PriorityLevel,
    val urgencyLevel: OutsourcingWorkRequest.UrgencyLevel,
    val requiredContractorCategory: UUID?,
    val requiredLicenses: String?,
    val requiredCertifications: String?,
    val minimumExperienceYears: Int,
    val approvalStatus: OutsourcingWorkRequest.ApprovalStatus,
    val currentApproverId: UUID?,
    val approvalLevel: Int,
    val requestStatus: OutsourcingWorkRequest.RequestStatus,
    val requestDocuments: String?,
    val requestNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(request: OutsourcingWorkRequest): OutsourcingWorkRequestDto {
            return OutsourcingWorkRequestDto(
                requestId = request.requestId,
                companyId = request.companyId,
                requestNumber = request.requestNumber,
                requestTitle = request.requestTitle,
                requestType = request.requestType,
                requestDate = request.requestDate,
                requesterId = request.requesterId,
                department = request.department,
                costCenter = request.costCenter,
                workDescription = request.workDescription,
                workLocation = request.workLocation,
                workScope = request.workScope,
                technicalRequirements = request.technicalRequirements,
                requiredStartDate = request.requiredStartDate,
                requiredCompletionDate = request.requiredCompletionDate,
                estimatedDuration = request.estimatedDuration,
                estimatedBudget = request.estimatedBudget,
                budgetCode = request.budgetCode,
                currencyCode = request.currencyCode,
                priorityLevel = request.priorityLevel,
                urgencyLevel = request.urgencyLevel,
                requiredContractorCategory = request.requiredContractorCategory,
                requiredLicenses = request.requiredLicenses,
                requiredCertifications = request.requiredCertifications,
                minimumExperienceYears = request.minimumExperienceYears,
                approvalStatus = request.approvalStatus,
                currentApproverId = request.currentApproverId,
                approvalLevel = request.approvalLevel,
                requestStatus = request.requestStatus,
                requestDocuments = request.requestDocuments,
                requestNotes = request.requestNotes,
                createdAt = request.createdAt,
                updatedAt = request.updatedAt,
                createdBy = request.createdBy,
                updatedBy = request.updatedBy
            )
        }
    }
}

/**
 * 외주 작업 요청 생성 DTO
 */
data class CreateOutsourcingWorkRequestRequest(
    val requestNumber: String,
    val requestTitle: String,
    val requestType: OutsourcingWorkRequest.RequestType,
    val requesterId: UUID,
    val department: String?,
    val costCenter: String?,
    val workDescription: String,
    val workLocation: String?,
    val workScope: String?,
    val technicalRequirements: String?,
    val requiredStartDate: LocalDate?,
    val requiredCompletionDate: LocalDate?,
    val estimatedDuration: Int?,
    val estimatedBudget: BigDecimal,
    val budgetCode: String?,
    val currencyCode: String = "KRW",
    val priorityLevel: OutsourcingWorkRequest.PriorityLevel = OutsourcingWorkRequest.PriorityLevel.NORMAL,
    val urgencyLevel: OutsourcingWorkRequest.UrgencyLevel = OutsourcingWorkRequest.UrgencyLevel.NORMAL,
    val requiredContractorCategory: UUID?,
    val requiredLicenses: String?,
    val requiredCertifications: String?,
    val minimumExperienceYears: Int = 0,
    val requestDocuments: String?,
    val requestNotes: String?
)

/**
 * 외주 작업 요청 수정 DTO
 */
data class UpdateOutsourcingWorkRequestRequest(
    val requestTitle: String?,
    val requestType: OutsourcingWorkRequest.RequestType?,
    val department: String?,
    val costCenter: String?,
    val workDescription: String?,
    val workLocation: String?,
    val workScope: String?,
    val technicalRequirements: String?,
    val requiredStartDate: LocalDate?,
    val requiredCompletionDate: LocalDate?,
    val estimatedDuration: Int?,
    val estimatedBudget: BigDecimal?,
    val budgetCode: String?,
    val priorityLevel: OutsourcingWorkRequest.PriorityLevel?,
    val urgencyLevel: OutsourcingWorkRequest.UrgencyLevel?,
    val requiredContractorCategory: UUID?,
    val requiredLicenses: String?,
    val requiredCertifications: String?,
    val minimumExperienceYears: Int?,
    val requestDocuments: String?,
    val requestNotes: String?
)

/**
 * 외주 작업 요청 승인 DTO
 */
data class ApproveOutsourcingWorkRequestRequest(
    val approvalNotes: String?
)

/**
 * 외주 작업 요청 거부 DTO
 */
data class RejectOutsourcingWorkRequestRequest(
    val rejectionReason: String
)

/**
 * 외주 작업 요청 검색 조건 DTO
 */
data class OutsourcingWorkRequestSearchCriteria(
    val requestTitle: String?,
    val requestType: OutsourcingWorkRequest.RequestType?,
    val requestStatus: OutsourcingWorkRequest.RequestStatus?,
    val approvalStatus: OutsourcingWorkRequest.ApprovalStatus?,
    val priorityLevel: OutsourcingWorkRequest.PriorityLevel?,
    val urgencyLevel: OutsourcingWorkRequest.UrgencyLevel?,
    val requesterId: UUID?,
    val department: String?,
    val costCenter: String?,
    val fromDate: LocalDateTime?,
    val toDate: LocalDateTime?,
    val minBudget: BigDecimal?,
    val maxBudget: BigDecimal?
)

/**
 * 외주 작업 요청 요약 DTO
 */
data class OutsourcingWorkRequestSummaryDto(
    val requestId: UUID,
    val requestNumber: String,
    val requestTitle: String,
    val requestType: OutsourcingWorkRequest.RequestType,
    val requestDate: LocalDateTime,
    val priorityLevel: OutsourcingWorkRequest.PriorityLevel,
    val urgencyLevel: OutsourcingWorkRequest.UrgencyLevel,
    val estimatedBudget: BigDecimal,
    val requestStatus: OutsourcingWorkRequest.RequestStatus,
    val approvalStatus: OutsourcingWorkRequest.ApprovalStatus,
    val requiredCompletionDate: LocalDate?
) {
    companion object {
        fun from(request: OutsourcingWorkRequest): OutsourcingWorkRequestSummaryDto {
            return OutsourcingWorkRequestSummaryDto(
                requestId = request.requestId,
                requestNumber = request.requestNumber,
                requestTitle = request.requestTitle,
                requestType = request.requestType,
                requestDate = request.requestDate,
                priorityLevel = request.priorityLevel,
                urgencyLevel = request.urgencyLevel,
                estimatedBudget = request.estimatedBudget,
                requestStatus = request.requestStatus,
                approvalStatus = request.approvalStatus,
                requiredCompletionDate = request.requiredCompletionDate
            )
        }
    }
}

/**
 * 외주 작업 요청 대시보드 통계 DTO
 */
data class OutsourcingWorkRequestDashboardDto(
    val totalRequests: Long,
    val pendingApprovalRequests: Long,
    val approvedRequests: Long,
    val rejectedRequests: Long,
    val urgentRequests: Long,
    val delayRiskRequests: Long,
    val totalEstimatedBudget: BigDecimal,
    val averageEstimatedBudget: BigDecimal
)