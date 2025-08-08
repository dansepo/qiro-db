package com.qiro.domain.contractor.controller

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.Contractor
import com.qiro.domain.contractor.service.ContractorService
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.math.BigDecimal
import java.util.*

/**
 * 외부 업체 관리 컨트롤러
 * 협력업체 정보 관리 API 엔드포인트 제공
 */
@RestController
@RequestMapping("/api/contractors")
class ContractorController(
    private val contractorService: ContractorService
) {

    /**
     * 업체 목록 조회
     */
    @GetMapping
    fun getContractors(
        @RequestParam companyId: UUID,
        @RequestParam(defaultValue = "ACTIVE") contractorStatus: Contractor.ContractorStatus
    ): ResponseEntity<List<ContractorDto>> {
        val contractors = contractorService.getContractorsByCompany(companyId, contractorStatus)
        return ResponseEntity.ok(contractors)
    }

    /**
     * 업체 상세 조회
     */
    @GetMapping("/{contractorId}")
    fun getContractor(@PathVariable contractorId: UUID): ResponseEntity<ContractorDto> {
        val contractor = contractorService.getContractorById(contractorId)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(contractor)
    }

    /**
     * 업체 코드로 조회
     */
    @GetMapping("/by-code")
    fun getContractorByCode(
        @RequestParam companyId: UUID,
        @RequestParam contractorCode: String
    ): ResponseEntity<ContractorDto> {
        val contractor = contractorService.getContractorByCode(companyId, contractorCode)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(contractor)
    }

    /**
     * 사업자등록번호로 조회
     */
    @GetMapping("/by-business-registration")
    fun getContractorByBusinessRegistrationNumber(
        @RequestParam companyId: UUID,
        @RequestParam businessRegistrationNumber: String
    ): ResponseEntity<ContractorDto> {
        val contractor = contractorService.getContractorByBusinessRegistrationNumber(
            companyId, businessRegistrationNumber
        ) ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(contractor)
    }

    /**
     * 업체명으로 검색
     */
    @GetMapping("/search")
    fun searchContractorsByName(
        @RequestParam companyId: UUID,
        @RequestParam contractorName: String,
        pageable: Pageable
    ): ResponseEntity<Page<ContractorDto>> {
        val contractors = contractorService.searchContractorsByName(companyId, contractorName, pageable)
        return ResponseEntity.ok(contractors)
    }

    /**
     * 카테고리별 업체 조회
     */
    @GetMapping("/by-category")
    fun getContractorsByCategory(
        @RequestParam companyId: UUID,
        @RequestParam categoryId: UUID,
        @RequestParam(defaultValue = "ACTIVE") contractorStatus: Contractor.ContractorStatus
    ): ResponseEntity<List<ContractorDto>> {
        val contractors = contractorService.getContractorsByCategory(companyId, categoryId, contractorStatus)
        return ResponseEntity.ok(contractors)
    }

    /**
     * 성과 등급별 업체 조회
     */
    @GetMapping("/by-performance-grade")
    fun getContractorsByPerformanceGrade(
        @RequestParam companyId: UUID,
        @RequestParam performanceGrade: Contractor.PerformanceGrade,
        @RequestParam(defaultValue = "ACTIVE") contractorStatus: Contractor.ContractorStatus
    ): ResponseEntity<List<ContractorDto>> {
        val contractors = contractorService.getContractorsByPerformanceGrade(
            companyId, performanceGrade, contractorStatus
        )
        return ResponseEntity.ok(contractors)
    }

    /**
     * 평점 범위별 업체 조회
     */
    @GetMapping("/by-rating-range")
    fun getContractorsByRatingRange(
        @RequestParam companyId: UUID,
        @RequestParam minRating: BigDecimal,
        @RequestParam maxRating: BigDecimal,
        @RequestParam(defaultValue = "ACTIVE") contractorStatus: Contractor.ContractorStatus
    ): ResponseEntity<List<ContractorDto>> {
        val contractors = contractorService.getContractorsByRatingRange(
            companyId, minRating, maxRating, contractorStatus
        )
        return ResponseEntity.ok(contractors)
    }

    /**
     * 복합 검색 조건으로 업체 조회
     */
    @PostMapping("/search-advanced")
    fun searchContractors(
        @RequestParam companyId: UUID,
        @RequestBody searchCriteria: ContractorSearchCriteria,
        pageable: Pageable
    ): ResponseEntity<Page<ContractorDto>> {
        val contractors = contractorService.searchContractors(companyId, searchCriteria, pageable)
        return ResponseEntity.ok(contractors)
    }

    /**
     * 만료 예정 업체 조회
     */
    @GetMapping("/expiring")
    fun getExpiringContractors(
        @RequestParam companyId: UUID,
        @RequestParam(defaultValue = "30") daysAhead: Int
    ): ResponseEntity<List<ContractorDto>> {
        val contractors = contractorService.getExpiringContractors(companyId, daysAhead)
        return ResponseEntity.ok(contractors)
    }

    /**
     * 업체 통계 조회
     */
    @GetMapping("/statistics")
    fun getContractorStatistics(@RequestParam companyId: UUID): ResponseEntity<Map<String, Any>> {
        val statistics = contractorService.getContractorStatistics(companyId)
        return ResponseEntity.ok(statistics)
    }

    /**
     * 업체 등록
     */
    @PostMapping
    fun createContractor(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateContractorRequest,
        @RequestParam createdBy: UUID
    ): ResponseEntity<ContractorDto> {
        return try {
            val contractor = contractorService.createContractor(companyId, request, createdBy)
            ResponseEntity.status(HttpStatus.CREATED).body(contractor)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 업체 정보 수정
     */
    @PutMapping("/{contractorId}")
    fun updateContractor(
        @PathVariable contractorId: UUID,
        @RequestBody request: UpdateContractorRequest,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<ContractorDto> {
        return try {
            val contractor = contractorService.updateContractor(contractorId, request, updatedBy)
            ResponseEntity.ok(contractor)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }

    /**
     * 업체 상태 변경
     */
    @PatchMapping("/{contractorId}/status")
    fun updateContractorStatus(
        @PathVariable contractorId: UUID,
        @RequestParam contractorStatus: Contractor.ContractorStatus,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<ContractorDto> {
        return try {
            val contractor = contractorService.updateContractorStatus(contractorId, contractorStatus, updatedBy)
            ResponseEntity.ok(contractor)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }

    /**
     * 업체 평점 업데이트
     */
    @PatchMapping("/{contractorId}/rating")
    fun updateContractorRating(
        @PathVariable contractorId: UUID,
        @RequestParam overallRating: BigDecimal,
        @RequestParam(required = false) performanceGrade: Contractor.PerformanceGrade?,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<ContractorDto> {
        return try {
            val contractor = contractorService.updateContractorRating(
                contractorId, overallRating, performanceGrade, updatedBy
            )
            ResponseEntity.ok(contractor)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }

    /**
     * 업체 삭제 (소프트 삭제)
     */
    @DeleteMapping("/{contractorId}")
    fun deleteContractor(
        @PathVariable contractorId: UUID,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<ContractorDto> {
        return try {
            val contractor = contractorService.deleteContractor(contractorId, updatedBy)
            ResponseEntity.ok(contractor)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        }
    }
}