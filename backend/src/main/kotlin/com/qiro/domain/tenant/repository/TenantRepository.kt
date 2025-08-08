package com.qiro.domain.tenant.repository

import com.qiro.domain.tenant.entity.Tenant
import com.qiro.domain.tenant.entity.TenantStatus
import com.qiro.domain.tenant.entity.TenantType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface TenantRepository : JpaRepository<Tenant, UUID> {
    
    fun findByCompanyIdAndTenantStatus(
        companyId: UUID, 
        tenantStatus: TenantStatus, 
        pageable: Pageable
    ): Page<Tenant>
    
    fun findByIdAndCompanyId(id: UUID, companyId: UUID): Tenant?
    
    @Query("""
        SELECT t FROM Tenant t 
        WHERE t.companyId = :companyId 
        AND t.tenantStatus = :status
        AND (
            LOWER(t.tenantName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            t.contactPhone LIKE CONCAT('%', :search, '%') OR
            LOWER(t.contactEmail) LIKE LOWER(CONCAT('%', :search, '%'))
        )
    """)
    fun findByCompanyIdAndTenantStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("status") status: TenantStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<Tenant>
    
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
    
    fun countByCompanyIdAndTenantStatus(companyId: UUID, tenantStatus: TenantStatus): Long
    
    fun countByCompanyIdAndTenantType(companyId: UUID, tenantType: TenantType): Long
    
    @Query("""
        SELECT t FROM Tenant t 
        WHERE t.companyId = :companyId 
        AND t.tenantStatus = :status
        AND (:tenantType IS NULL OR t.tenantType = :tenantType)
        AND (:hasEmail IS NULL OR (t.contactEmail IS NOT NULL) = :hasEmail)
        AND (:backgroundCheckStatus IS NULL OR t.backgroundCheckStatus = :backgroundCheckStatus)
    """)
    fun findTenantsByFilters(
        @Param("companyId") companyId: UUID,
        @Param("status") status: TenantStatus,
        @Param("tenantType") tenantType: TenantType?,
        @Param("hasEmail") hasEmail: Boolean?,
        @Param("backgroundCheckStatus") backgroundCheckStatus: String?,
        pageable: Pageable
    ): Page<Tenant>
}