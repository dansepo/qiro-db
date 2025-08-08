package com.qiro.domain.company.repository

import com.qiro.domain.company.entity.Company
import com.qiro.domain.company.entity.CompanyStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface CompanyRepository : JpaRepository<Company, UUID> {
    
    fun findByBusinessRegistrationNumber(businessRegistrationNumber: String): Company?
    
    fun findByCompanyStatus(companyStatus: CompanyStatus, pageable: Pageable): Page<Company>
    
    fun existsByBusinessRegistrationNumber(businessRegistrationNumber: String): Boolean
    
    fun existsByBusinessRegistrationNumberAndIdNot(businessRegistrationNumber: String, id: UUID): Boolean
    
    @Query("""
        SELECT c FROM Company c 
        WHERE c.companyStatus = :status
        AND (
            LOWER(c.companyName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            LOWER(c.representativeName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            c.businessRegistrationNumber LIKE CONCAT('%', :search, '%')
        )
    """)
    fun findByCompanyStatusAndSearch(
        @Param("status") status: CompanyStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<Company>
    
    fun countByCompanyStatus(companyStatus: CompanyStatus): Long
    
    fun countByIsVerified(isVerified: Boolean): Long
}