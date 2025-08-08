package com.qiro.domain.contractor.controller

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.ContractorEvaluation
import com.qiro.domain.contractor.service.ContractorEvaluationService
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 외부 업체 평가 컨트롤러
 * 협력업체 평가 관리 API 엔드포인트 제공
 */
@RestController
@RequestMapping("/api/contractor-evaluations")
class ContractorEvaluationController(
    private val contractorEvaluationService: ContractorEvaluationService
) {

    /**
     * 업체별 평가 목록 조회
     */
    @GetMapping("/by-contractor")
    fun getEvaluationsByContractor(
        @RequestParam companyId: UUID,
        @RequestParam contractorId: UUID
    ): ResponseEntity<List<ContractorEvaluationDto>> {
        val evaluations = contractorEvaluationService.getEvaluationsByContractor(companyId, contractorId)
        return ResponseEntity.ok(evaluations)
    }

    /**
     * 평가 상세 조회
     */
    @GetMapping("/{evaluationId}")
    fun getEvaluation(@PathVariable evaluationId: UUID): ResponseEntity<ContractorEvaluationDto> {
        val evaluation = contractorEvaluationService.getEvaluationById(evaluationId)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(evaluation)
    }

    /**
     * 평가 번호로 조회
     */
    @GetMapping("/by-number")
    fun getEvaluationByNumber(
        @RequestParam companyId: UUID,
        @RequestParam evaluationNumber: String
    ): ResponseEntity<ContractorEvaluationDto> {
        val evaluation = contractorEvaluationService.getEvaluationByNumber(companyId, evaluationNumber)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(evaluation)
    }

    /**
     * 업체의 최신 평가 조회
     */
    @GetMapping("/latest")
    fun getLatestEvaluationByContractor(
        @RequestParam companyId: UUID,
        @RequestParam contractorId: UUID
    ): ResponseEntity<ContractorEvaluationDto> {
        val evaluation = contractorEvaluationService.getLatestEvaluationByContractor(companyId, contractorId)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(evaluation)
    }

    /**
     * 평가 유형별 조회
     */
    @GetMapping("/by-type")
    fun getEvaluationsByType(
        @RequestParam companyId: UUID,
        @RequestParam evaluationType: ContractorEvaluation.EvaluationType
    ): ResponseEntity<List<ContractorEvaluationDto>> {
        val evaluations = contractorEvaluationService.getEvaluationsByType(companyId, evaluationType)
        return ResponseEntity.ok(evaluations)
    }

    /**
     * 평가 상태별 조회
     */
    @GetMapping("/by-status")
    fun getEvaluationsByStatus(
        @RequestParam companyId: UUID,
        @RequestParam evaluationStatus: ContractorEvaluation.EvaluationStatus
    ): ResponseEntity<List<ContractorEvaluationDto>> {
        val evaluations = contractorEvaluationService.getEvaluationsByStatus(companyId, evaluationStatus)
        return ResponseEntity.ok(evaluations)
    }

    /**
     * 복합 검색 조건으로 평가 조회
     */
    @PostMapping("/search")
    fun searchEvaluations(
        @RequestParam companyId: UUID,
        @RequestBody searchCriteria: ContractorEvaluationSearchCriteria,
        pageable: Pageable
    ): ResponseEntity<Page<ContractorEvaluationDto>> {
        val evaluations = contractorEvaluationService.searchEvaluations(companyId, searchCriteria, pageable)
        return ResponseEntity.ok(evaluations)
    }

    /**
     * 업체 평가 통계 조회
     */
    @GetMapping("/statistics")
    fun getEvaluationStatistics(
        @RequestParam companyId: UUID,
        @RequestParam contractorId: UUID
    ): ResponseEntity<ContractorEvaluationStatisticsDto> {
        val statistics = contractorEvaluationService.getEvaluationStatistics(companyId, contractorId)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(statistics)
    }

    /**
     * 업체 평균 평가 점수 조회
     */
    @GetMapping("/average-score")
    fun getAverageScoreByContractor(
        @RequestParam companyId: UUID,
        @RequestParam contractorId: UUID
    ): ResponseEntity<Map<String, Any>> {
        val averageScore = contractorEvaluationService.getAverageScoreByContractor(companyId, contractorId)
        val response = mapOf("averageScore" to (averageScore ?: 0))
        return ResponseEntity.ok(response)
    }

    /**
     * 업체 최근 평균 점수 조회
     */
    @GetMapping("/recent-average-score")
    fun getRecentAverageScore(
        @RequestParam companyId: UUID,
        @RequestParam contractorId: UUID,
        @RequestParam(defaultValue = "12") months: Long
    ): ResponseEntity<Map<String, Any>> {
        val recentAverageScore = contractorEvaluationService.getRecentAverageScore(companyId, contractorId, months)
        val response = mapOf(
            "recentAverageScore" to (recentAverageScore ?: 0),
            "months" to months
        )
        return ResponseEntity.ok(response)
    }

    /**
     * 평가 등록
     */
    @PostMapping
    fun createEvaluation(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateContractorEvaluationRequest,
        @RequestParam createdBy: UUID
    ): ResponseEntity<ContractorEvaluationDto> {
        return try {
            val evaluation = contractorEvaluationService.createEvaluation(companyId, request, createdBy)
            ResponseEntity.status(HttpStatus.CREATED).body(evaluation)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 평가 수정
     */
    @PutMapping("/{evaluationId}")
    fun updateEvaluation(
        @PathVariable evaluationId: UUID,
        @RequestBody request: UpdateContractorEvaluationRequest,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<ContractorEvaluationDto> {
        return try {
            val evaluation = contractorEvaluationService.updateEvaluation(evaluationId, request, updatedBy)
            ResponseEntity.ok(evaluation)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 평가 승인
     */
    @PostMapping("/{evaluationId}/approve")
    fun approveEvaluation(
        @PathVariable evaluationId: UUID,
        @RequestBody request: ApproveContractorEvaluationRequest,
        @RequestParam approvedBy: UUID
    ): ResponseEntity<ContractorEvaluationDto> {
        return try {
            val evaluation = contractorEvaluationService.approveEvaluation(evaluationId, request, approvedBy)
            ResponseEntity.ok(evaluation)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 평가 거부
     */
    @PostMapping("/{evaluationId}/reject")
    fun rejectEvaluation(
        @PathVariable evaluationId: UUID,
        @RequestParam rejectionReason: String,
        @RequestParam rejectedBy: UUID
    ): ResponseEntity<ContractorEvaluationDto> {
        return try {
            val evaluation = contractorEvaluationService.rejectEvaluation(evaluationId, rejectionReason, rejectedBy)
            ResponseEntity.ok(evaluation)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }

    /**
     * 평가 삭제
     */
    @DeleteMapping("/{evaluationId}")
    fun deleteEvaluation(@PathVariable evaluationId: UUID): ResponseEntity<Void> {
        return try {
            contractorEvaluationService.deleteEvaluation(evaluationId)
            ResponseEntity.noContent().build()
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }
}