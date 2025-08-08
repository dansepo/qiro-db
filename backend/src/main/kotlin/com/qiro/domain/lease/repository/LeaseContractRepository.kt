package com.qiro.domain.lease.repository

import com.qiro.domain.lease.entity.ContractStatus
import com.qiro.domain.lease.entity.ContractType
import com.qiro.domain.lease.entity.LeaseContract
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

@Repository
interface LeaseContractRepository : JpaRepository<LeaseContract, UUID> {
    
    fun findByCompanyIdAndContractStatus(
        companyId: UUID, 
        contractStatus: ContractStatus, 
        pageable: Pageable
    ): Page<LeaseContract>
    
    fun findByIdAndCompanyId(id: UUID, companyId: UUID): LeaseContract?
    
    fun findByContractNumberAndCompanyId(contractNumber: String, companyId: UUID): LeaseContract?
    
    fun findByUnitIdAndContractStatus(unitId: UUID, contractStatus: ContractStatus): LeaseContract?
    
    fun findByTenantIdAndCompanyId(tenantId: UUID, companyId: UUID, pageable: Pageable): Page<LeaseContract>
    
    fun findByLessorIdAndCompanyId(lessorId: UUID, companyId: UUID, pageable: Pageable): Page<LeaseContract>
    
    @Query("""
        SELECT lc FROM LeaseContract lc 
        WHERE lc.companyId = :companyId 
        AND lc.contractStatus = :status
        AND (
            lc.contractNumber LIKE CONCAT('%', :search, '%') OR
            LOWER(lc.tenant.tenantName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            LOWER(lc.lessor.lessorName) LIKE LOWER(CONCAT('%', :search, '%')) OR
            lc.unit.unitNumber LIKE CONCAT('%', :search, '%')
        )
    """)
    fun findByCompanyIdAndContractStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("status") status: ContractStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<LeaseContract>
    
    fun existsByContractNumberAndCompanyId(contractNumber: String, companyId: UUID): Boolean
    
    fun existsByContractNumberAndCompanyIdAndIdNot(
        contractNumber: String, 
        companyId: UUID, 
        id: UUID
    ): Boolean
    
    @Query("""
        SELECT lc FROM LeaseContract lc 
        WHERE lc.companyId = :companyId 
        AND lc.contractStatus = 'ACTIVE'
        AND lc.endDate <= :expiryDate
        ORDER BY lc.endDate ASC
    """)
    fun findExpiringContracts(
        @Param("companyId") companyId: UUID,
        @Param("expiryDate") expiryDate: LocalDate
    ): List<LeaseContract>
    
    @Query("""
        SELECT lc FROM LeaseContract lc 
        WHERE lc.companyId = :companyId 
        AND lc.contractStatus = 'ACTIVE'
        AND lc.autoRenewal = true
        AND lc.endDate <= :renewalDate
        ORDER BY lc.endDate ASC
    """)
    fun findContractsForAutoRenewal(
        @Param("companyId") companyId: UUID,
        @Param("renewalDate") renewalDate: LocalDate
    ): List<LeaseContract>
    
    @Query("""
        SELECT lc FROM LeaseContract lc 
        WHERE lc.companyId = :companyId 
        AND (:contractStatus IS NULL OR lc.contractStatus = :contractStatus)
        AND (:contractType IS NULL OR lc.contractType = :contractType)
        AND (:unitId IS NULL OR lc.unit.id = :unitId)
        AND (:tenantId IS NULL OR lc.tenant.id = :tenantId)
        AND (:lessorId IS NULL OR lc.lessor.id = :lessorId)
        AND (:startDateFrom IS NULL OR lc.startDate >= :startDateFrom)
        AND (:startDateTo IS NULL OR lc.startDate <= :startDateTo)
        AND (:endDateFrom IS NULL OR lc.endDate >= :endDateFrom)
        AND (:endDateTo IS NULL OR lc.endDate <= :endDateTo)
    """)
    fun findContractsByFilters(
        @Param("companyId") companyId: UUID,
        @Param("contractStatus") contractStatus: ContractStatus?,
        @Param("contractType") contractType: ContractType?,
        @Param("unitId") unitId: UUID?,
        @Param("tenantId") tenantId: UUID?,
        @Param("lessorId") lessorId: UUID?,
        @Param("startDateFrom") startDateFrom: LocalDate?,
        @Param("startDateTo") startDateTo: LocalDate?,
        @Param("endDateFrom") endDateFrom: LocalDate?,
        @Param("endDateTo") endDateTo: LocalDate?,
        pageable: Pageable
    ): Page<LeaseContract>
    
    fun countByCompanyIdAndContractStatus(companyId: UUID, contractStatus: ContractStatus): Long
    
    fun countByCompanyIdAndContractType(companyId: UUID, contractType: ContractType): Long
    
    @Query("""
        SELECT 
            lc.contractStatus as status,
            COUNT(lc) as count
        FROM LeaseContract lc 
        WHERE lc.companyId = :companyId
        GROUP BY lc.contractStatus
    """)
    fun getContractStatusStatistics(@Param("companyId") companyId: UUID): List<ContractStatusStatistics>
    
    @Query("""
        SELECT 
            lc.contractType as type,
            COUNT(lc) as count,
            AVG(lc.monthlyRent) as averageRent,
            SUM(lc.monthlyRent) as totalRent
        FROM LeaseContract lc 
        WHERE lc.companyId = :companyId
        AND lc.contractStatus = 'ACTIVE'
        GROUP BY lc.contractType
    """)
    fun getContractTypeStatistics(@Param("companyId") companyId: UUID): List<ContractTypeStatistics>
}

interface ContractStatusStatistics {
    val status: ContractStatus
    val count: Long
}

interface ContractTypeStatistics {
    val type: ContractType
    val count: Long
    val averageRent: java.math.BigDecimal?
    val totalRent: java.math.BigDecimal?
}