package com.qiro.domain.contractor.service

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.ContractorEvaluation
import com.qiro.domain.contractor.repository.ContractorEvaluationRepository
import com.qiro.domain.contractor.repository.ContractorRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 평가 서비스
 * 협력업체 평가 관리 비즈니스 로직 처리
 */
@Service
@Transactional(readOnly = true)
class ContractorEvaluationService(
    private val contractorEvaluationRepository: ContractorEvaluationRepository,
    private val contractorRepository: ContractorRepository,
    private val contractorService: ContractorService
) {

    /**
     * 업체별 평가 목록 조회
     */
    fun getEvaluationsByContractor(companyId: UUID, contractorId: UUID): List<ContractorEvaluationDto> {
        return contractorEvaluationRepository.findByCompanyIdAndContractorIdOrderByEvaluationDateDesc(
            companyId, contractorId
        ).map { ContractorEvaluationDto.from(it) }
    }

    /**
     * 평가 상세 조회
     */
    fun getEvaluationById(evaluationId: UUID): ContractorEvaluationDto? {
        return contractorEvaluationRepository.findById(evaluationId)
            .map { ContractorEvaluationDto.from(it) }
            .orElse(null)
    }

    /**
     * 평가 번호로 조회
     */
    fun getEvaluationByNumber(companyId: UUID, evaluationNumber: String): ContractorEvaluationDto? {
        return contractorEvaluationRepository.findByCompanyIdAndEvaluationNumber(companyId, evaluationNumber)
            ?.let { ContractorEvaluationDto.from(it) }
    }

    /**
     * 업체의 최신 평가 조회
     */
    fun getLatestEvaluationByContractor(companyId: UUID, contractorId: UUID): ContractorEvaluationDto? {
        return contractorEvaluationRepository.findFirstByCompanyIdAndContractorIdOrderByEvaluationDateDesc(
            companyId, contractorId
        )?.let { ContractorEvaluationDto.from(it) }
    }

    /**
     * 평가 유형별 조회
     */
    fun getEvaluationsByType(
        companyId: UUID,
        evaluationType: ContractorEvaluation.EvaluationType
    ): List<ContractorEvaluationDto> {
        return contractorEvaluationRepository.findByCompanyIdAndEvaluationTypeOrderByEvaluationDateDesc(
            companyId, evaluationType
        ).map { ContractorEvaluationDto.from(it) }
    }

    /**
     * 평가 상태별 조회
     */
    fun getEvaluationsByStatus(
        companyId: UUID,
        evaluationStatus: ContractorEvaluation.EvaluationStatus
    ): List<ContractorEvaluationDto> {
        return contractorEvaluationRepository.findByCompanyIdAndEvaluationStatusOrderByEvaluationDateDesc(
            companyId, evaluationStatus
        ).map { ContractorEvaluationDto.from(it) }
    }

    /**
     * 복합 검색 조건으로 평가 조회
     */
    fun searchEvaluations(
        companyId: UUID,
        searchCriteria: ContractorEvaluationSearchCriteria,
        pageable: Pageable
    ): Page<ContractorEvaluationDto> {
        return contractorEvaluationRepository.findBySearchCriteria(
            companyId = companyId,
            contractorId = searchCriteria.contractorId,
            evaluationType = searchCriteria.evaluationType,
            evaluationStatus = searchCriteria.evaluationStatus,
            evaluatorId = searchCriteria.evaluatorId,
            fromDate = searchCriteria.fromDate,
            toDate = searchCriteria.toDate,
            pageable = pageable
        ).map { ContractorEvaluationDto.from(it) }
    }

    /**
     * 업체 평가 통계 조회
     */
    fun getEvaluationStatistics(companyId: UUID, contractorId: UUID): ContractorEvaluationStatisticsDto? {
        val statistics = contractorEvaluationRepository.findEvaluationStatistics(companyId, contractorId)
        
        if (statistics.isEmpty()) return null

        val stat = statistics[0]
        val latestEvaluation = contractorEvaluationRepository
            .findFirstByCompanyIdAndContractorIdOrderByEvaluationDateDesc(companyId, contractorId)

        return ContractorEvaluationStatisticsDto(
            contractorId = contractorId,
            evaluationCount = stat[1] as Long,
            averageQualityScore = (stat[2] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageScheduleScore = (stat[3] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageCostScore = (stat[4] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageSafetyScore = (stat[5] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageCommunicationScore = (stat[6] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageTechnicalScore = (stat[7] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            averageWeightedScore = (stat[8] as BigDecimal).setScale(2, RoundingMode.HALF_UP),
            latestEvaluationDate = latestEvaluation?.evaluationDate,
            latestEvaluationGrade = latestEvaluation?.evaluationGrade
        )
    }

    /**
     * 업체 평균 평가 점수 조회
     */
    fun getAverageScoreByContractor(companyId: UUID, contractorId: UUID): BigDecimal? {
        return contractorEvaluationRepository.findAverageScoreByContractor(companyId, contractorId)
    }

    /**
     * 업체 최근 평균 점수 조회 (N개월)
     */
    fun getRecentAverageScore(companyId: UUID, contractorId: UUID, months: Long): BigDecimal? {
        val fromDate = LocalDateTime.now().minusMonths(months)
        return contractorEvaluationRepository.findRecentAverageScore(companyId, contractorId, fromDate)
    }

    /**
     * 평가 등록
     */
    @Transactional
    fun createEvaluation(
        companyId: UUID,
        request: CreateContractorEvaluationRequest,
        createdBy: UUID
    ): ContractorEvaluationDto {
        // 업체 존재 확인
        contractorRepository.findById(request.contractorId)
            .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: ${request.contractorId}") }

        // 평가 번호 중복 확인
        contractorEvaluationRepository.findByCompanyIdAndEvaluationNumber(companyId, request.evaluationNumber)
            ?.let { throw IllegalArgumentException("평가 번호가 이미 존재합니다: ${request.evaluationNumber}") }

        // 총점 및 가중 점수 계산
        val totalScore = calculateTotalScore(
            request.qualityScore, request.scheduleScore, request.costScore,
            request.safetyScore, request.communicationScore, request.technicalScore
        )
        val weightedScore = calculateWeightedScore(
            request.qualityScore, request.scheduleScore, request.costScore,
            request.safetyScore, request.communicationScore, request.technicalScore
        )
        val evaluationGrade = calculateEvaluationGrade(weightedScore)

        val evaluation = ContractorEvaluation(
            companyId = companyId,
            contractorId = request.contractorId,
            evaluationNumber = request.evaluationNumber,
            evaluationTitle = request.evaluationTitle,
            evaluationType = request.evaluationType,
            evaluationPeriodStart = request.evaluationPeriodStart,
            evaluationPeriodEnd = request.evaluationPeriodEnd,
            evaluatorId = request.evaluatorId,
            qualityScore = request.qualityScore,
            scheduleScore = request.scheduleScore,
            costScore = request.costScore,
            safetyScore = request.safetyScore,
            communicationScore = request.communicationScore,
            technicalScore = request.technicalScore,
            totalScore = totalScore,
            weightedScore = weightedScore,
            evaluationGrade = evaluationGrade,
            strengths = request.strengths,
            weaknesses = request.weaknesses,
            improvementRecommendations = request.improvementRecommendations,
            referenceProjects = request.referenceProjects,
            createdBy = createdBy
        )

        val savedEvaluation = contractorEvaluationRepository.save(evaluation)
        return ContractorEvaluationDto.from(savedEvaluation)
    }

    /**
     * 평가 수정
     */
    @Transactional
    fun updateEvaluation(
        evaluationId: UUID,
        request: UpdateContractorEvaluationRequest,
        updatedBy: UUID
    ): ContractorEvaluationDto {
        val evaluation = contractorEvaluationRepository.findById(evaluationId)
            .orElseThrow { IllegalArgumentException("평가를 찾을 수 없습니다: $evaluationId") }

        // 승인된 평가는 수정 불가
        if (evaluation.evaluationStatus == ContractorEvaluation.EvaluationStatus.APPROVED) {
            throw IllegalStateException("승인된 평가는 수정할 수 없습니다")
        }

        val qualityScore = request.qualityScore ?: evaluation.qualityScore
        val scheduleScore = request.scheduleScore ?: evaluation.scheduleScore
        val costScore = request.costScore ?: evaluation.costScore
        val safetyScore = request.safetyScore ?: evaluation.safetyScore
        val communicationScore = request.communicationScore ?: evaluation.communicationScore
        val technicalScore = request.technicalScore ?: evaluation.technicalScore

        val totalScore = calculateTotalScore(
            qualityScore, scheduleScore, costScore, safetyScore, communicationScore, technicalScore
        )
        val weightedScore = calculateWeightedScore(
            qualityScore, scheduleScore, costScore, safetyScore, communicationScore, technicalScore
        )
        val evaluationGrade = calculateEvaluationGrade(weightedScore)

        val updatedEvaluation = evaluation.copy(
            evaluationTitle = request.evaluationTitle ?: evaluation.evaluationTitle,
            evaluationType = request.evaluationType ?: evaluation.evaluationType,
            evaluationPeriodStart = request.evaluationPeriodStart ?: evaluation.evaluationPeriodStart,
            evaluationPeriodEnd = request.evaluationPeriodEnd ?: evaluation.evaluationPeriodEnd,
            qualityScore = qualityScore,
            scheduleScore = scheduleScore,
            costScore = costScore,
            safetyScore = safetyScore,
            communicationScore = communicationScore,
            technicalScore = technicalScore,
            totalScore = totalScore,
            weightedScore = weightedScore,
            evaluationGrade = evaluationGrade,
            strengths = request.strengths ?: evaluation.strengths,
            weaknesses = request.weaknesses ?: evaluation.weaknesses,
            improvementRecommendations = request.improvementRecommendations ?: evaluation.improvementRecommendations,
            referenceProjects = request.referenceProjects ?: evaluation.referenceProjects,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedEvaluation = contractorEvaluationRepository.save(updatedEvaluation)
        return ContractorEvaluationDto.from(savedEvaluation)
    }

    /**
     * 평가 승인
     */
    @Transactional
    fun approveEvaluation(
        evaluationId: UUID,
        request: ApproveContractorEvaluationRequest,
        approvedBy: UUID
    ): ContractorEvaluationDto {
        val evaluation = contractorEvaluationRepository.findById(evaluationId)
            .orElseThrow { IllegalArgumentException("평가를 찾을 수 없습니다: $evaluationId") }

        if (evaluation.evaluationStatus == ContractorEvaluation.EvaluationStatus.APPROVED) {
            throw IllegalStateException("이미 승인된 평가입니다")
        }

        val approvedEvaluation = evaluation.copy(
            evaluationStatus = ContractorEvaluation.EvaluationStatus.APPROVED,
            approvedBy = approvedBy,
            approvalDate = LocalDateTime.now(),
            approvalNotes = request.approvalNotes,
            updatedAt = LocalDateTime.now(),
            updatedBy = approvedBy
        )

        val savedEvaluation = contractorEvaluationRepository.save(approvedEvaluation)

        // 업체 전체 평점 업데이트
        updateContractorOverallRating(evaluation.companyId, evaluation.contractorId, approvedBy)

        return ContractorEvaluationDto.from(savedEvaluation)
    }

    /**
     * 평가 거부
     */
    @Transactional
    fun rejectEvaluation(evaluationId: UUID, rejectionReason: String, rejectedBy: UUID): ContractorEvaluationDto {
        val evaluation = contractorEvaluationRepository.findById(evaluationId)
            .orElseThrow { IllegalArgumentException("평가를 찾을 수 없습니다: $evaluationId") }

        val rejectedEvaluation = evaluation.copy(
            evaluationStatus = ContractorEvaluation.EvaluationStatus.REJECTED,
            approvalNotes = rejectionReason,
            updatedAt = LocalDateTime.now(),
            updatedBy = rejectedBy
        )

        val savedEvaluation = contractorEvaluationRepository.save(rejectedEvaluation)
        return ContractorEvaluationDto.from(savedEvaluation)
    }

    /**
     * 평가 삭제
     */
    @Transactional
    fun deleteEvaluation(evaluationId: UUID) {
        val evaluation = contractorEvaluationRepository.findById(evaluationId)
            .orElseThrow { IllegalArgumentException("평가를 찾을 수 없습니다: $evaluationId") }

        if (evaluation.evaluationStatus == ContractorEvaluation.EvaluationStatus.APPROVED) {
            throw IllegalStateException("승인된 평가는 삭제할 수 없습니다")
        }

        contractorEvaluationRepository.delete(evaluation)
    }

    /**
     * 총점 계산 (단순 평균)
     */
    private fun calculateTotalScore(
        qualityScore: BigDecimal,
        scheduleScore: BigDecimal,
        costScore: BigDecimal,
        safetyScore: BigDecimal,
        communicationScore: BigDecimal,
        technicalScore: BigDecimal
    ): BigDecimal {
        val total = qualityScore + scheduleScore + costScore + safetyScore + communicationScore + technicalScore
        return total.divide(BigDecimal(6), 2, RoundingMode.HALF_UP)
    }

    /**
     * 가중 점수 계산 (품질 30%, 일정 20%, 비용 20%, 안전 15%, 소통 10%, 기술 5%)
     */
    private fun calculateWeightedScore(
        qualityScore: BigDecimal,
        scheduleScore: BigDecimal,
        costScore: BigDecimal,
        safetyScore: BigDecimal,
        communicationScore: BigDecimal,
        technicalScore: BigDecimal
    ): BigDecimal {
        val weightedTotal = qualityScore.multiply(BigDecimal("0.30")) +
                scheduleScore.multiply(BigDecimal("0.20")) +
                costScore.multiply(BigDecimal("0.20")) +
                safetyScore.multiply(BigDecimal("0.15")) +
                communicationScore.multiply(BigDecimal("0.10")) +
                technicalScore.multiply(BigDecimal("0.05"))
        
        return weightedTotal.setScale(2, RoundingMode.HALF_UP)
    }

    /**
     * 평가 등급 계산
     */
    private fun calculateEvaluationGrade(weightedScore: BigDecimal): ContractorEvaluation.EvaluationGrade {
        return when {
            weightedScore >= BigDecimal("95") -> ContractorEvaluation.EvaluationGrade.A_PLUS
            weightedScore >= BigDecimal("90") -> ContractorEvaluation.EvaluationGrade.A
            weightedScore >= BigDecimal("85") -> ContractorEvaluation.EvaluationGrade.B_PLUS
            weightedScore >= BigDecimal("80") -> ContractorEvaluation.EvaluationGrade.B
            weightedScore >= BigDecimal("75") -> ContractorEvaluation.EvaluationGrade.C_PLUS
            weightedScore >= BigDecimal("70") -> ContractorEvaluation.EvaluationGrade.C
            weightedScore >= BigDecimal("60") -> ContractorEvaluation.EvaluationGrade.D
            else -> ContractorEvaluation.EvaluationGrade.F
        }
    }

    /**
     * 업체 전체 평점 업데이트
     */
    private fun updateContractorOverallRating(companyId: UUID, contractorId: UUID, updatedBy: UUID) {
        val averageScore = contractorEvaluationRepository.findAverageScoreByContractor(companyId, contractorId)
        if (averageScore != null) {
            val performanceGrade = when {
                averageScore >= BigDecimal("95") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.A_PLUS
                averageScore >= BigDecimal("90") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.A
                averageScore >= BigDecimal("85") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.B_PLUS
                averageScore >= BigDecimal("80") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.B
                averageScore >= BigDecimal("75") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.C_PLUS
                averageScore >= BigDecimal("70") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.C
                averageScore >= BigDecimal("60") -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.D
                else -> com.qiro.domain.contractor.entity.Contractor.PerformanceGrade.F
            }

            contractorService.updateContractorRating(contractorId, averageScore, performanceGrade, updatedBy)
        }
    }
}