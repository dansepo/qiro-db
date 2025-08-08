package com.qiro.domain.contractor.repository

import com.qiro.domain.contractor.entity.ContractorEvaluation
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 평가 Repository
 * 협력업체 평가 정보에 대한 데이터 액세스 기능 제공
 */
@Repository
interface ContractorEvaluationRepository : JpaRepository<ContractorEvaluation, UUID> {

    /**
     * 업체별 평가 목록 조회 (최신순)
     */
    fun findByCompanyIdAndContractorIdOrderByEvaluationDateDesc(
        companyId: UUID,
        contractorId: UUID
    ): List<ContractorEvaluation>

    /**
     * 평가 번호로 조회
     */
    fun findByCompanyIdAndEvaluationNumber(companyId: UUID, evaluationNumber: String): ContractorEvaluation?

    /**
     * 업체의 최신 평가 조회
     */
    fun findFirstByCompanyIdAndContractorIdOrderByEvaluationDateDesc(
        companyId: UUID,
        contractorId: UUID
    ): ContractorEvaluation?

    /**
     * 평가 유형별 조회
     */
    fun findByCompanyIdAndEvaluationTypeOrderByEvaluationDateDesc(
        companyId: UUID,
        evaluationType: ContractorEvaluation.EvaluationType
    ): List<ContractorEvaluation>

    /**
     * 평가 상태별 조회
     */
    fun findByCompanyIdAndEvaluationStatusOrderByEvaluationDateDesc(
        companyId: UUID,
        evaluationStatus: ContractorEvaluation.EvaluationStatus
    ): List<ContractorEvaluation>

    /**
     * 평가자별 평가 목록 조회
     */
    fun findByCompanyIdAndEvaluatorIdOrderByEvaluationDateDesc(
        companyId: UUID,
        evaluatorId: UUID
    ): List<ContractorEvaluation>

    /**
     * 기간별 평가 조회
     */
    fun findByCompanyIdAndEvaluationDateBetweenOrderByEvaluationDateDesc(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<ContractorEvaluation>

    /**
     * 평가 등급별 조회
     */
    fun findByCompanyIdAndEvaluationGradeOrderByEvaluationDateDesc(
        companyId: UUID,
        evaluationGrade: ContractorEvaluation.EvaluationGrade
    ): List<ContractorEvaluation>

    /**
     * 업체의 평균 평가 점수 조회
     */
    @Query("""
        SELECT AVG(e.weightedScore) 
        FROM ContractorEvaluation e 
        WHERE e.companyId = :companyId 
        AND e.contractorId = :contractorId 
        AND e.evaluationStatus = 'APPROVED'
    """)
    fun findAverageScoreByContractor(
        @Param("companyId") companyId: UUID,
        @Param("contractorId") contractorId: UUID
    ): BigDecimal?

    /**
     * 업체의 최근 N개월 평균 점수 조회
     */
    @Query("""
        SELECT AVG(e.weightedScore) 
        FROM ContractorEvaluation e 
        WHERE e.companyId = :companyId 
        AND e.contractorId = :contractorId 
        AND e.evaluationStatus = 'APPROVED'
        AND e.evaluationDate >= :fromDate
    """)
    fun findRecentAverageScore(
        @Param("companyId") companyId: UUID,
        @Param("contractorId") contractorId: UUID,
        @Param("fromDate") fromDate: LocalDateTime
    ): BigDecimal?

    /**
     * 업체별 평가 통계 조회
     */
    @Query("""
        SELECT e.contractorId,
               COUNT(e) as evaluationCount,
               AVG(e.qualityScore) as avgQualityScore,
               AVG(e.scheduleScore) as avgScheduleScore,
               AVG(e.costScore) as avgCostScore,
               AVG(e.safetyScore) as avgSafetyScore,
               AVG(e.communicationScore) as avgCommunicationScore,
               AVG(e.technicalScore) as avgTechnicalScore,
               AVG(e.weightedScore) as avgWeightedScore
        FROM ContractorEvaluation e 
        WHERE e.companyId = :companyId 
        AND e.contractorId = :contractorId
        AND e.evaluationStatus = 'APPROVED'
        GROUP BY e.contractorId
    """)
    fun findEvaluationStatistics(
        @Param("companyId") companyId: UUID,
        @Param("contractorId") contractorId: UUID
    ): List<Array<Any>>

    /**
     * 평가 기간별 업체 조회
     */
    fun findByCompanyIdAndEvaluationPeriodStartBetweenOrderByEvaluationDateDesc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<ContractorEvaluation>

    /**
     * 승인 대기 중인 평가 조회
     */
    fun findByCompanyIdAndEvaluationStatusAndEvaluationDateBetweenOrderByEvaluationDateAsc(
        companyId: UUID,
        evaluationStatus: ContractorEvaluation.EvaluationStatus,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<ContractorEvaluation>

    /**
     * 점수 범위별 평가 조회
     */
    @Query("""
        SELECT e FROM ContractorEvaluation e 
        WHERE e.companyId = :companyId 
        AND e.weightedScore >= :minScore 
        AND e.weightedScore <= :maxScore 
        AND e.evaluationStatus = 'APPROVED'
        ORDER BY e.weightedScore DESC, e.evaluationDate DESC
    """)
    fun findByScoreRange(
        @Param("companyId") companyId: UUID,
        @Param("minScore") minScore: BigDecimal,
        @Param("maxScore") maxScore: BigDecimal,
        pageable: Pageable
    ): Page<ContractorEvaluation>

    /**
     * 업체의 평가 개수 조회
     */
    fun countByCompanyIdAndContractorIdAndEvaluationStatus(
        companyId: UUID,
        contractorId: UUID,
        evaluationStatus: ContractorEvaluation.EvaluationStatus
    ): Long

    /**
     * 복합 검색 조건으로 평가 조회
     */
    @Query("""
        SELECT e FROM ContractorEvaluation e 
        WHERE e.companyId = :companyId
        AND (:contractorId IS NULL OR e.contractorId = :contractorId)
        AND (:evaluationType IS NULL OR e.evaluationType = :evaluationType)
        AND (:evaluationStatus IS NULL OR e.evaluationStatus = :evaluationStatus)
        AND (:evaluatorId IS NULL OR e.evaluatorId = :evaluatorId)
        AND (:fromDate IS NULL OR e.evaluationDate >= :fromDate)
        AND (:toDate IS NULL OR e.evaluationDate <= :toDate)
        ORDER BY e.evaluationDate DESC
    """)
    fun findBySearchCriteria(
        @Param("companyId") companyId: UUID,
        @Param("contractorId") contractorId: UUID?,
        @Param("evaluationType") evaluationType: ContractorEvaluation.EvaluationType?,
        @Param("evaluationStatus") evaluationStatus: ContractorEvaluation.EvaluationStatus?,
        @Param("evaluatorId") evaluatorId: UUID?,
        @Param("fromDate") fromDate: LocalDateTime?,
        @Param("toDate") toDate: LocalDateTime?,
        pageable: Pageable
    ): Page<ContractorEvaluation>
}