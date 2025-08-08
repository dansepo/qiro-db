package com.qiro.domain.contractor.service

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.Contractor
import com.qiro.domain.contractor.repository.ContractorRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 외부 업체 관리 서비스
 * 협력업체 정보 관리 비즈니스 로직 처리
 */
@Service
@Transactional(readOnly = true)
class ContractorService(
    private val contractorRepository: ContractorRepository
) {

    /**
     * 업체 목록 조회 (회사별)
     */
    fun getContractorsByCompany(
        companyId: UUID,
        contractorStatus: Contractor.ContractorStatus = Contractor.ContractorStatus.ACTIVE
    ): List<ContractorDto> {
        return contractorRepository.findByCompanyIdAndContractorStatusOrderByContractorName(
            companyId, contractorStatus
        ).map { ContractorDto.from(it) }
    }

    /**
     * 업체 상세 조회
     */
    fun getContractorById(contractorId: UUID): ContractorDto? {
        return contractorRepository.findById(contractorId)
            .map { ContractorDto.from(it) }
            .orElse(null)
    }

    /**
     * 업체 코드로 조회
     */
    fun getContractorByCode(companyId: UUID, contractorCode: String): ContractorDto? {
        return contractorRepository.findByCompanyIdAndContractorCode(companyId, contractorCode)
            ?.let { ContractorDto.from(it) }
    }

    /**
     * 사업자등록번호로 조회
     */
    fun getContractorByBusinessRegistrationNumber(
        companyId: UUID,
        businessRegistrationNumber: String
    ): ContractorDto? {
        return contractorRepository.findByCompanyIdAndBusinessRegistrationNumber(
            companyId, businessRegistrationNumber
        )?.let { ContractorDto.from(it) }
    }

    /**
     * 업체명으로 검색
     */
    fun searchContractorsByName(
        companyId: UUID,
        contractorName: String,
        pageable: Pageable
    ): Page<ContractorDto> {
        return contractorRepository.findByCompanyIdAndContractorNameContainingIgnoreCaseOrderByContractorName(
            companyId, contractorName, pageable
        ).map { ContractorDto.from(it) }
    }

    /**
     * 카테고리별 업체 조회
     */
    fun getContractorsByCategory(
        companyId: UUID,
        categoryId: UUID,
        contractorStatus: Contractor.ContractorStatus = Contractor.ContractorStatus.ACTIVE
    ): List<ContractorDto> {
        return contractorRepository.findByCompanyIdAndCategoryIdAndContractorStatusOrderByOverallRatingDesc(
            companyId, categoryId, contractorStatus
        ).map { ContractorDto.from(it) }
    }

    /**
     * 성과 등급별 업체 조회
     */
    fun getContractorsByPerformanceGrade(
        companyId: UUID,
        performanceGrade: Contractor.PerformanceGrade,
        contractorStatus: Contractor.ContractorStatus = Contractor.ContractorStatus.ACTIVE
    ): List<ContractorDto> {
        return contractorRepository.findByCompanyIdAndPerformanceGradeAndContractorStatusOrderByOverallRatingDesc(
            companyId, performanceGrade, contractorStatus
        ).map { ContractorDto.from(it) }
    }

    /**
     * 평점 범위별 업체 조회
     */
    fun getContractorsByRatingRange(
        companyId: UUID,
        minRating: BigDecimal,
        maxRating: BigDecimal,
        contractorStatus: Contractor.ContractorStatus = Contractor.ContractorStatus.ACTIVE
    ): List<ContractorDto> {
        return contractorRepository.findByRatingRange(
            companyId, minRating, maxRating, contractorStatus
        ).map { ContractorDto.from(it) }
    }

    /**
     * 복합 검색 조건으로 업체 조회
     */
    fun searchContractors(
        companyId: UUID,
        searchCriteria: ContractorSearchCriteria,
        pageable: Pageable
    ): Page<ContractorDto> {
        return contractorRepository.findBySearchCriteria(
            companyId = companyId,
            contractorName = searchCriteria.contractorName,
            categoryId = searchCriteria.categoryId,
            contractorType = searchCriteria.contractorType,
            contractorStatus = searchCriteria.contractorStatus,
            minRating = searchCriteria.minRating,
            pageable = pageable
        ).map { ContractorDto.from(it) }
    }

    /**
     * 만료 예정 업체 조회
     */
    fun getExpiringContractors(companyId: UUID, daysAhead: Int = 30): List<ContractorDto> {
        return contractorRepository.findExpiringContractors(companyId, daysAhead)
            .map { ContractorDto.from(it) }
    }

    /**
     * 업체 통계 조회
     */
    fun getContractorStatistics(companyId: UUID): Map<String, Any> {
        val totalCount = contractorRepository.countByCompanyIdAndContractorStatus(
            companyId, Contractor.ContractorStatus.ACTIVE
        )
        val inactiveCount = contractorRepository.countByCompanyIdAndContractorStatus(
            companyId, Contractor.ContractorStatus.INACTIVE
        )
        val suspendedCount = contractorRepository.countByCompanyIdAndContractorStatus(
            companyId, Contractor.ContractorStatus.SUSPENDED
        )
        val blacklistedCount = contractorRepository.countByCompanyIdAndContractorStatus(
            companyId, Contractor.ContractorStatus.BLACKLISTED
        )

        return mapOf(
            "totalActiveContractors" to totalCount,
            "inactiveContractors" to inactiveCount,
            "suspendedContractors" to suspendedCount,
            "blacklistedContractors" to blacklistedCount,
            "totalContractors" to (totalCount + inactiveCount + suspendedCount + blacklistedCount)
        )
    }

    /**
     * 업체 등록
     */
    @Transactional
    fun createContractor(companyId: UUID, request: CreateContractorRequest, createdBy: UUID): ContractorDto {
        // 업체 코드 중복 확인
        contractorRepository.findByCompanyIdAndContractorCode(companyId, request.contractorCode)
            ?.let { throw IllegalArgumentException("업체 코드가 이미 존재합니다: ${request.contractorCode}") }

        // 사업자등록번호 중복 확인
        contractorRepository.findByCompanyIdAndBusinessRegistrationNumber(
            companyId, request.businessRegistrationNumber
        )?.let { throw IllegalArgumentException("사업자등록번호가 이미 존재합니다: ${request.businessRegistrationNumber}") }

        val contractor = Contractor(
            companyId = companyId,
            contractorCode = request.contractorCode,
            contractorName = request.contractorName,
            contractorNameEn = request.contractorNameEn,
            businessRegistrationNumber = request.businessRegistrationNumber,
            businessType = request.businessType,
            contractorType = request.contractorType,
            categoryId = request.categoryId,
            representativeName = request.representativeName,
            contactPerson = request.contactPerson,
            phoneNumber = request.phoneNumber,
            mobileNumber = request.mobileNumber,
            faxNumber = request.faxNumber,
            email = request.email,
            website = request.website,
            address = request.address,
            postalCode = request.postalCode,
            city = request.city,
            state = request.state,
            country = request.country,
            establishmentDate = request.establishmentDate,
            capitalAmount = request.capitalAmount,
            annualRevenue = request.annualRevenue,
            employeeCount = request.employeeCount,
            specializationAreas = request.specializationAreas,
            serviceRegions = request.serviceRegions,
            workCapacity = request.workCapacity,
            creditRating = request.creditRating,
            remarks = request.remarks,
            createdBy = createdBy
        )

        val savedContractor = contractorRepository.save(contractor)
        return ContractorDto.from(savedContractor)
    }

    /**
     * 업체 정보 수정
     */
    @Transactional
    fun updateContractor(
        contractorId: UUID,
        request: UpdateContractorRequest,
        updatedBy: UUID
    ): ContractorDto {
        val contractor = contractorRepository.findById(contractorId)
            .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: $contractorId") }

        val updatedContractor = contractor.copy(
            contractorName = request.contractorName ?: contractor.contractorName,
            contractorNameEn = request.contractorNameEn ?: contractor.contractorNameEn,
            contractorType = request.contractorType ?: contractor.contractorType,
            categoryId = request.categoryId ?: contractor.categoryId,
            representativeName = request.representativeName ?: contractor.representativeName,
            contactPerson = request.contactPerson ?: contractor.contactPerson,
            phoneNumber = request.phoneNumber ?: contractor.phoneNumber,
            mobileNumber = request.mobileNumber ?: contractor.mobileNumber,
            faxNumber = request.faxNumber ?: contractor.faxNumber,
            email = request.email ?: contractor.email,
            website = request.website ?: contractor.website,
            address = request.address ?: contractor.address,
            postalCode = request.postalCode ?: contractor.postalCode,
            city = request.city ?: contractor.city,
            state = request.state ?: contractor.state,
            country = request.country ?: contractor.country,
            establishmentDate = request.establishmentDate ?: contractor.establishmentDate,
            capitalAmount = request.capitalAmount ?: contractor.capitalAmount,
            annualRevenue = request.annualRevenue ?: contractor.annualRevenue,
            employeeCount = request.employeeCount ?: contractor.employeeCount,
            specializationAreas = request.specializationAreas ?: contractor.specializationAreas,
            serviceRegions = request.serviceRegions ?: contractor.serviceRegions,
            workCapacity = request.workCapacity ?: contractor.workCapacity,
            creditRating = request.creditRating ?: contractor.creditRating,
            financialStatus = request.financialStatus ?: contractor.financialStatus,
            contractorStatus = request.contractorStatus ?: contractor.contractorStatus,
            remarks = request.remarks ?: contractor.remarks,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedContractor = contractorRepository.save(updatedContractor)
        return ContractorDto.from(savedContractor)
    }

    /**
     * 업체 상태 변경
     */
    @Transactional
    fun updateContractorStatus(
        contractorId: UUID,
        contractorStatus: Contractor.ContractorStatus,
        updatedBy: UUID
    ): ContractorDto {
        val contractor = contractorRepository.findById(contractorId)
            .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: $contractorId") }

        val updatedContractor = contractor.copy(
            contractorStatus = contractorStatus,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedContractor = contractorRepository.save(updatedContractor)
        return ContractorDto.from(savedContractor)
    }

    /**
     * 업체 평점 업데이트
     */
    @Transactional
    fun updateContractorRating(
        contractorId: UUID,
        overallRating: BigDecimal,
        performanceGrade: Contractor.PerformanceGrade?,
        updatedBy: UUID
    ): ContractorDto {
        val contractor = contractorRepository.findById(contractorId)
            .orElseThrow { IllegalArgumentException("업체를 찾을 수 없습니다: $contractorId") }

        val updatedContractor = contractor.copy(
            overallRating = overallRating,
            performanceGrade = performanceGrade,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedContractor = contractorRepository.save(updatedContractor)
        return ContractorDto.from(savedContractor)
    }

    /**
     * 업체 삭제 (소프트 삭제 - 상태를 TERMINATED로 변경)
     */
    @Transactional
    fun deleteContractor(contractorId: UUID, updatedBy: UUID): ContractorDto {
        return updateContractorStatus(contractorId, Contractor.ContractorStatus.TERMINATED, updatedBy)
    }
}