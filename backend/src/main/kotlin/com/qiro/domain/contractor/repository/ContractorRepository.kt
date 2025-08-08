package com.qiro.domain.contractor.repository

import com.qiro.domain.contractor.entity.Contractor
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.util.*

/**
 * 외부 업체 정보 Repository
 * 협력업체 정보에 대한 데이터 액세스 기능 제공
 */
@Repository
interface ContractorRepository : JpaRepository<Contractor, UUID> {

    /**
     * 회사별 업체 목록 조회
     */
    fun findByCompanyIdAndContractorStatusOrderByContractorName(
        companyId: UUID,
        contractorStatus: Contractor.ContractorStatus
    ): List<Contractor>

    /**
     * 업체 코드로 조회
     */
    fun findByCompanyIdAndContractorCode(companyId: UUID, contractorCode: String): Contractor?

    /**
     * 사업자등록번호로 조회
     */
    fun findByCompanyIdAndBusinessRegistrationNumber(
        companyId: UUID,
        businessRegistrationNumber: String
    ): Contractor?

    /**
     * 업체명으로 검색 (페이징)
     */
    fun findByCompanyIdAndContractorNameContainingIgnoreCaseOrderByContractorName(
        companyId: UUID,
        contractorName: String,
        pageable: Pageable
    ): Page<Contractor>

    /**
     * 카테고리별 업체 조회
     */
    fun findByCompanyIdAndCategoryIdAndContractorStatusOrderByOverallRatingDesc(
        companyId: UUID,
        categoryId: UUID,
        contractorStatus: Contractor.ContractorStatus
    ): List<Contractor>

    /**
     * 성과 등급별 업체 조회
     */
    fun findByCompanyIdAndPerformanceGradeAndContractorStatusOrderByOverallRatingDesc(
        companyId: UUID,
        performanceGrade: Contractor.PerformanceGrade,
        contractorStatus: Contractor.ContractorStatus
    ): List<Contractor>

    /**
     * 평점 범위별 업체 조회
     */
    @Query("""
        SELECT c FROM Contractor c 
        WHERE c.companyId = :companyId 
        AND c.overallRating >= :minRating 
        AND c.overallRating <= :maxRating 
        AND c.contractorStatus = :status
        ORDER BY c.overallRating DESC
    """)
    fun findByRatingRange(
        @Param("companyId") companyId: UUID,
        @Param("minRating") minRating: BigDecimal,
        @Param("maxRating") maxRating: BigDecimal,
        @Param("status") status: Contractor.ContractorStatus
    ): List<Contractor>

    /**
     * 업체 유형별 조회
     */
    fun findByCompanyIdAndContractorTypeAndContractorStatusOrderByContractorName(
        companyId: UUID,
        contractorType: Contractor.ContractorType,
        contractorStatus: Contractor.ContractorStatus
    ): List<Contractor>

    /**
     * 등록 상태별 업체 조회
     */
    fun findByCompanyIdAndRegistrationStatusOrderByRegistrationDate(
        companyId: UUID,
        registrationStatus: Contractor.RegistrationStatus
    ): List<Contractor>

    /**
     * 활성 업체 수 조회
     */
    fun countByCompanyIdAndContractorStatus(
        companyId: UUID,
        contractorStatus: Contractor.ContractorStatus
    ): Long

    /**
     * 카테고리별 활성 업체 수 조회
     */
    fun countByCompanyIdAndCategoryIdAndContractorStatus(
        companyId: UUID,
        categoryId: UUID,
        contractorStatus: Contractor.ContractorStatus
    ): Long

    /**
     * 복합 검색 조건으로 업체 조회
     */
    @Query("""
        SELECT c FROM Contractor c 
        WHERE c.companyId = :companyId
        AND (:contractorName IS NULL OR LOWER(c.contractorName) LIKE LOWER(CONCAT('%', :contractorName, '%')))
        AND (:categoryId IS NULL OR c.categoryId = :categoryId)
        AND (:contractorType IS NULL OR c.contractorType = :contractorType)
        AND (:contractorStatus IS NULL OR c.contractorStatus = :contractorStatus)
        AND (:minRating IS NULL OR c.overallRating >= :minRating)
        ORDER BY c.overallRating DESC, c.contractorName ASC
    """)
    fun findBySearchCriteria(
        @Param("companyId") companyId: UUID,
        @Param("contractorName") contractorName: String?,
        @Param("categoryId") categoryId: UUID?,
        @Param("contractorType") contractorType: Contractor.ContractorType?,
        @Param("contractorStatus") contractorStatus: Contractor.ContractorStatus?,
        @Param("minRating") minRating: BigDecimal?,
        pageable: Pageable
    ): Page<Contractor>

    /**
     * 만료 예정 업체 조회 (등록 만료일 기준)
     */
    @Query("""
        SELECT c FROM Contractor c 
        WHERE c.companyId = :companyId 
        AND c.expiryDate IS NOT NULL 
        AND c.expiryDate <= CURRENT_DATE + :daysAhead
        AND c.contractorStatus = 'ACTIVE'
        ORDER BY c.expiryDate ASC
    """)
    fun findExpiringContractors(
        @Param("companyId") companyId: UUID,
        @Param("daysAhead") daysAhead: Int
    ): List<Contractor>
}