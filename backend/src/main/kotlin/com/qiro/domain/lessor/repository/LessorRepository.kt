package com.qiro.domain.lessor.repository

import com.qiro.domain.lessor.entity.Lessor
import com.qiro.domain.lessor.entity.LessorStatus
import com.qiro.domain.lessor.entity.LessorType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

@Repository
interface LessorRepository : JpaRepository<Lessor, UUID> {
    
    fun findByCompanyIdAndLessorStatus(
        companyId: UUID, 
        lessorStatus: LessorStatus, 
        pageable: Pageable
    ): Page<Lessor>
    
    fun findByIdAndCompanyId(id: UUID, companyId: UUID): Lessor?
    
    @Query("""
        SELECT l FROM Lessor l 
        WHERE l.companyId = :companyId 
        AND l.lessorStatus = :status
        AND (
            LOWER(l.lessorName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            l.contactPhone LIKE CONCAT('%', :search, '%') OR
            LOWER(l.contactEmail) LIKE LOWER(CONCAT('%', :search, '%'))
        )
    """)
    fun findByCompanyIdAndLessorStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("status") status: LessorStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<Lessor>
    
    fun existsByCompanyIdAndContactPhone(companyId: UUID, contactPhone: String): Boolean
    
    fun existsByCompanyIdAndContactPhoneAndIdNot(
        companyId: UUID, 
        contactPhone: String, 
        id: UUID
    ): Boolean
    
    fun existsByCompanyIdAndBusinessRegistrationNumber(
        companyId: UUID, 
        businessRegistrationNumber: String
    ): Boolean
    
    fun existsByCompanyIdAndBusinessRegistrationNumberAndIdNot(
        companyId: UUID, 
        businessRegistrationNumber: String, 
        id: UUID
    ): Boolean
    
    fun countByCompanyIdAndLessorStatus(companyId: UUID, lessorStatus: LessorStatus): Long
    
    fun countByCompanyIdAndLessorType(companyId: UUID, lessorType: LessorType): Long
    
    @Query("""
        SELECT l FROM Lessor l 
        WHERE l.companyId = :companyId 
        AND l.lessorStatus = :status
        AND (:lessorType IS NULL OR l.lessorType = :lessorType)
        AND (:hasInsurance IS NULL OR (l.insuranceCompany IS NOT NULL) = :hasInsurance)
        AND (:insuranceExpiring IS NULL OR 
             (:insuranceExpiring = true AND l.insuranceExpiryDate <= :expiryDate) OR
             (:insuranceExpiring = false AND (l.insuranceExpiryDate IS NULL OR l.insuranceExpiryDate > :expiryDate)))
    """)
    fun findLessorsByFilters(
        @Param("companyId") companyId: UUID,
        @Param("status") status: LessorStatus,
        @Param("lessorType") lessorType: LessorType?,
        @Param("hasInsurance") hasInsurance: Boolean?,
        @Param("insuranceExpiring") insuranceExpiring: Boolean?,
        @Param("expiryDate") expiryDate: LocalDate,
        pageable: Pageable
    ): Page<Lessor>
    
    @Query("""
        SELECT l FROM Lessor l 
        WHERE l.companyId = :companyId 
        AND l.insuranceExpiryDate IS NOT NULL 
        AND l.insuranceExpiryDate <= :expiryDate
        ORDER BY l.insuranceExpiryDate ASC
    """)
    fun findLessorsWithExpiringInsurance(
        @Param("companyId") companyId: UUID,
        @Param("expiryDate") expiryDate: LocalDate
    ): List<Lessor>
}