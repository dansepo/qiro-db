package com.qiro.domain.contractor.dto

import com.qiro.domain.contractor.entity.ContractorEvaluation
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 평가 DTO
 */
data class ContractorEvaluationDto(
    val evaluationId: UUID,
    val companyId: UUID,
    val contractorId: UUID,
    val evaluationNumber: String,
    val evaluationTitle: String,
    val evaluationType: ContractorEvaluation.EvaluationType,
    val evaluationPeriodStart: LocalDate,
    val evaluationPeriodEnd: LocalDate,
    val evaluatorId: UUID,
    val evaluationDate: LocalDateTime,
    val qualityScore: BigDecimal,
    val scheduleScore: BigDecimal,
    val costScore: BigDecimal,
    val safetyScore: BigDecimal,
    val communicationScore: BigDecimal,
    val technicalScore: BigDecimal,
    val totalScore: BigDecimal,
    val weightedScore: BigDecimal,
    val evaluationGrade: ContractorEvaluation.EvaluationGrade?,
    val strengths: String?,
    val weaknesses: String?,
    val improvementRecommendations: String?,
    val referenceProjects: String?,
    val evaluationStatus: ContractorEvaluation.EvaluationStatus,
    val approvedBy: UUID?,
    val approvalDate: LocalDateTime?,
    val approvalNotes: String?,
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime,
    val createdBy: UUID?,
    val updatedBy: UUID?
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(evaluation: ContractorEvaluation): ContractorEvaluationDto {
            return ContractorEvaluationDto(
                evaluationId = evaluation.evaluationId,
                companyId = evaluation.companyId,
                contractorId = evaluation.contractorId,
                evaluationNumber = evaluation.evaluationNumber,
                evaluationTitle = evaluation.evaluationTitle,
                evaluationType = evaluation.evaluationType,
                evaluationPeriodStart = evaluation.evaluationPeriodStart,
                evaluationPeriodEnd = evaluation.evaluationPeriodEnd,
                evaluatorId = evaluation.evaluatorId,
                evaluationDate = evaluation.evaluationDate,
                qualityScore = evaluation.qualityScore,
                scheduleScore = evaluation.scheduleScore,
                costScore = evaluation.costScore,
                safetyScore = evaluation.safetyScore,
                communicationScore = evaluation.communicationScore,
                technicalScore = evaluation.technicalScore,
                totalScore = evaluation.totalScore,
                weightedScore = evaluation.weightedScore,
                evaluationGrade = evaluation.evaluationGrade,
                strengths = evaluation.strengths,
                weaknesses = evaluation.weaknesses,
                improvementRecommendations = evaluation.improvementRecommendations,
                referenceProjects = evaluation.referenceProjects,
                evaluationStatus = evaluation.evaluationStatus,
                approvedBy = evaluation.approvedBy,
                approvalDate = evaluation.approvalDate,
                approvalNotes = evaluation.approvalNotes,
                createdAt = evaluation.createdAt,
                updatedAt = evaluation.updatedAt,
                createdBy = evaluation.createdBy,
                updatedBy = evaluation.updatedBy
            )
        }
    }
}

/**
 * 외부 업체 평가 생성 요청 DTO
 */
data class CreateContractorEvaluationRequest(
    val contractorId: UUID,
    val evaluationNumber: String,
    val evaluationTitle: String,
    val evaluationType: ContractorEvaluation.EvaluationType,
    val evaluationPeriodStart: LocalDate,
    val evaluationPeriodEnd: LocalDate,
    val evaluatorId: UUID,
    val qualityScore: BigDecimal,
    val scheduleScore: BigDecimal,
    val costScore: BigDecimal,
    val safetyScore: BigDecimal,
    val communicationScore: BigDecimal,
    val technicalScore: BigDecimal,
    val strengths: String?,
    val weaknesses: String?,
    val improvementRecommendations: String?,
    val referenceProjects: String?
)

/**
 * 외부 업체 평가 수정 요청 DTO
 */
data class UpdateContractorEvaluationRequest(
    val evaluationTitle: String?,
    val evaluationType: ContractorEvaluation.EvaluationType?,
    val evaluationPeriodStart: LocalDate?,
    val evaluationPeriodEnd: LocalDate?,
    val qualityScore: BigDecimal?,
    val scheduleScore: BigDecimal?,
    val costScore: BigDecimal?,
    val safetyScore: BigDecimal?,
    val communicationScore: BigDecimal?,
    val technicalScore: BigDecimal?,
    val strengths: String?,
    val weaknesses: String?,
    val improvementRecommendations: String?,
    val referenceProjects: String?
)

/**
 * 외부 업체 평가 승인 요청 DTO
 */
data class ApproveContractorEvaluationRequest(
    val approvalNotes: String?
)

/**
 * 외부 업체 평가 검색 조건 DTO
 */
data class ContractorEvaluationSearchCriteria(
    val contractorId: UUID?,
    val evaluationType: ContractorEvaluation.EvaluationType?,
    val evaluationStatus: ContractorEvaluation.EvaluationStatus?,
    val evaluatorId: UUID?,
    val fromDate: LocalDateTime?,
    val toDate: LocalDateTime?,
    val minScore: BigDecimal?,
    val maxScore: BigDecimal?,
    val evaluationGrade: ContractorEvaluation.EvaluationGrade?
)

/**
 * 외부 업체 평가 통계 DTO
 */
data class ContractorEvaluationStatisticsDto(
    val contractorId: UUID,
    val evaluationCount: Long,
    val averageQualityScore: BigDecimal,
    val averageScheduleScore: BigDecimal,
    val averageCostScore: BigDecimal,
    val averageSafetyScore: BigDecimal,
    val averageCommunicationScore: BigDecimal,
    val averageTechnicalScore: BigDecimal,
    val averageWeightedScore: BigDecimal,
    val latestEvaluationDate: LocalDateTime?,
    val latestEvaluationGrade: ContractorEvaluation.EvaluationGrade?
)

/**
 * 외부 업체 평가 요약 DTO
 */
data class ContractorEvaluationSummaryDto(
    val evaluationId: UUID,
    val evaluationNumber: String,
    val evaluationTitle: String,
    val evaluationType: ContractorEvaluation.EvaluationType,
    val evaluationDate: LocalDateTime,
    val weightedScore: BigDecimal,
    val evaluationGrade: ContractorEvaluation.EvaluationGrade?,
    val evaluationStatus: ContractorEvaluation.EvaluationStatus
) {
    companion object {
        fun from(evaluation: ContractorEvaluation): ContractorEvaluationSummaryDto {
            return ContractorEvaluationSummaryDto(
                evaluationId = evaluation.evaluationId,
                evaluationNumber = evaluation.evaluationNumber,
                evaluationTitle = evaluation.evaluationTitle,
                evaluationType = evaluation.evaluationType,
                evaluationDate = evaluation.evaluationDate,
                weightedScore = evaluation.weightedScore,
                evaluationGrade = evaluation.evaluationGrade,
                evaluationStatus = evaluation.evaluationStatus
            )
        }
    }
}