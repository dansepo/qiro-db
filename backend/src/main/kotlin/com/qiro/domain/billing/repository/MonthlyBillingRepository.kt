package com.qiro.domain.billing.repository

import com.qiro.domain.billing.entity.BillingStatus
import com.qiro.domain.billing.entity.MonthlyBilling
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

@Repository
interface MonthlyBillingRepository : JpaRepository<MonthlyBilling, UUID> {

    fun findByCompanyId(companyId: UUID, pageable: Pageable): Page<MonthlyBilling>

    fun findByIdAndCompanyId(id: UUID, companyId: UUID): MonthlyBilling?

    fun findByCompanyIdAndBillingStatus(
        companyId: UUID,
        billingStatus: BillingStatus,
        pageable: Pageable
    ): Page<MonthlyBilling>

    fun findByCompanyIdAndBillingYearAndBillingMonth(
        companyId: UUID,
        billingYear: Int,
        billingMonth: Int,
        pageable: Pageable
    ): Page<MonthlyBilling>

    fun findByUnitIdAndBillingYearAndBillingMonth(
        unitId: UUID,
        billingYear: Int,
        billingMonth: Int
    ): MonthlyBilling?

    fun findByContractIdAndCompanyId(
        contractId: UUID,
        companyId: UUID,
        pageable: Pageable
    ): Page<MonthlyBilling>

    @Query("""
        SELECT mb FROM MonthlyBilling mb 
        JOIN mb.unit u 
        JOIN mb.contract c 
        JOIN c.tenant t 
        WHERE mb.companyId = :companyId 
        AND mb.billingStatus = :status
        AND (
            mb.billingNumber LIKE CONCAT('%', :search, '%') OR
            u.unitNumber LIKE CONCAT('%', :search, '%') OR
            LOWER(t.tenantName) LIKE LOWER(CONCAT('%', :search, '%'))
        )
    """)
    fun findByCompanyIdAndBillingStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("status") status: BillingStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<MonthlyBilling>

    @Query("""
        SELECT mb FROM MonthlyBilling mb 
        WHERE mb.companyId = :companyId 
        AND mb.billingStatus IN :statuses
        AND mb.dueDate < :currentDate
    """)
    fun findOverdueBillings(
        @Param("companyId") companyId: UUID,
        @Param("statuses") statuses: List<BillingStatus>,
        @Param("currentDate") currentDate: LocalDate,
        pageable: Pageable
    ): Page<MonthlyBilling>

    @Query("""
        SELECT mb FROM MonthlyBilling mb 
        WHERE mb.companyId = :companyId 
        AND mb.billingStatus IN ('ISSUED', 'SENT', 'PARTIAL_PAID')
        AND mb.dueDate BETWEEN :startDate AND :endDate
    """)
    fun findBillingsWithUpcomingDueDate(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        pageable: Pageable
    ): Page<MonthlyBilling>

    fun existsByUnitIdAndBillingYearAndBillingMonth(
        unitId: UUID,
        billingYear: Int,
        billingMonth: Int
    ): Boolean

    fun countByCompanyIdAndBillingStatus(companyId: UUID, billingStatus: BillingStatus): Long

    fun countByCompanyIdAndBillingYearAndBillingMonth(
        companyId: UUID,
        billingYear: Int,
        billingMonth: Int
    ): Long

    @Query("""
        SELECT 
            mb.billingStatus as status,
            COUNT(mb) as count,
            COALESCE(SUM(
                mb.monthlyRent + 
                COALESCE(mb.maintenanceFee, 0) + 
                COALESCE(mb.parkingFee, 0) + 
                COALESCE(mb.electricityFee, 0) + 
                COALESCE(mb.gasFee, 0) + 
                COALESCE(mb.waterFee, 0) + 
                COALESCE(mb.heatingFee, 0) + 
                COALESCE(mb.internetFee, 0) + 
                COALESCE(mb.tvFee, 0) + 
                COALESCE(mb.cleaningFee, 0) + 
                COALESCE(mb.securityFee, 0) + 
                COALESCE(mb.elevatorFee, 0) + 
                COALESCE(mb.commonAreaFee, 0) + 
                COALESCE(mb.repairReserveFee, 0) + 
                COALESCE(mb.insuranceFee, 0) + 
                COALESCE(mb.otherFees, 0) + 
                COALESCE(mb.lateFee, 0) + 
                COALESCE(mb.adjustmentAmount, 0) - 
                COALESCE(mb.discountAmount, 0)
            ), 0) as totalAmount
        FROM MonthlyBilling mb 
        WHERE mb.companyId = :companyId 
        AND mb.billingYear = :year
        AND (:month IS NULL OR mb.billingMonth = :month)
        GROUP BY mb.billingStatus
    """)
    fun getBillingStatusStatistics(
        @Param("companyId") companyId: UUID,
        @Param("year") year: Int,
        @Param("month") month: Int?
    ): List<BillingStatusStatistics>

    @Query("""
        SELECT 
            mb.billingYear as year,
            mb.billingMonth as month,
            COUNT(mb) as totalBillings,
            COALESCE(SUM(
                mb.monthlyRent + 
                COALESCE(mb.maintenanceFee, 0) + 
                COALESCE(mb.parkingFee, 0) + 
                COALESCE(mb.electricityFee, 0) + 
                COALESCE(mb.gasFee, 0) + 
                COALESCE(mb.waterFee, 0) + 
                COALESCE(mb.heatingFee, 0) + 
                COALESCE(mb.internetFee, 0) + 
                COALESCE(mb.tvFee, 0) + 
                COALESCE(mb.cleaningFee, 0) + 
                COALESCE(mb.securityFee, 0) + 
                COALESCE(mb.elevatorFee, 0) + 
                COALESCE(mb.commonAreaFee, 0) + 
                COALESCE(mb.repairReserveFee, 0) + 
                COALESCE(mb.insuranceFee, 0) + 
                COALESCE(mb.otherFees, 0) + 
                COALESCE(mb.lateFee, 0) + 
                COALESCE(mb.adjustmentAmount, 0) - 
                COALESCE(mb.discountAmount, 0)
            ), 0) as totalAmount,
            COALESCE(SUM(mb.paidAmount), 0) as paidAmount
        FROM MonthlyBilling mb 
        WHERE mb.companyId = :companyId 
        AND mb.billingYear >= :startYear
        GROUP BY mb.billingYear, mb.billingMonth
        ORDER BY mb.billingYear DESC, mb.billingMonth DESC
    """)
    fun getMonthlyBillingStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startYear") startYear: Int
    ): List<MonthlyBillingStatistics>

    @Query("""
        SELECT COALESCE(SUM(
            mb.monthlyRent + 
            COALESCE(mb.maintenanceFee, 0) + 
            COALESCE(mb.parkingFee, 0) + 
            COALESCE(mb.electricityFee, 0) + 
            COALESCE(mb.gasFee, 0) + 
            COALESCE(mb.waterFee, 0) + 
            COALESCE(mb.heatingFee, 0) + 
            COALESCE(mb.internetFee, 0) + 
            COALESCE(mb.tvFee, 0) + 
            COALESCE(mb.cleaningFee, 0) + 
            COALESCE(mb.securityFee, 0) + 
            COALESCE(mb.elevatorFee, 0) + 
            COALESCE(mb.commonAreaFee, 0) + 
            COALESCE(mb.repairReserveFee, 0) + 
            COALESCE(mb.insuranceFee, 0) + 
            COALESCE(mb.otherFees, 0) + 
            COALESCE(mb.lateFee, 0) + 
            COALESCE(mb.adjustmentAmount, 0) - 
            COALESCE(mb.discountAmount, 0)
        ), 0)
        FROM MonthlyBilling mb 
        WHERE mb.companyId = :companyId 
        AND mb.billingStatus IN :statuses
        AND mb.dueDate < :currentDate
    """)
    fun getTotalOverdueAmount(
        @Param("companyId") companyId: UUID,
        @Param("statuses") statuses: List<BillingStatus>,
        @Param("currentDate") currentDate: LocalDate
    ): BigDecimal

    @Query("""
        SELECT mb FROM MonthlyBilling mb 
        JOIN mb.unit u 
        JOIN u.building b 
        WHERE mb.companyId = :companyId 
        AND b.buildingId IN :buildingIds
        AND mb.billingYear = :year
        AND mb.billingMonth = :month
    """)
    fun findByBuildingIdsAndYearMonth(
        @Param("companyId") companyId: UUID,
        @Param("buildingIds") buildingIds: List<UUID>,
        @Param("year") year: Int,
        @Param("month") month: Int
    ): List<MonthlyBilling>
}

interface BillingStatusStatistics {
    val status: BillingStatus
    val count: Long
    val totalAmount: BigDecimal
}

interface MonthlyBillingStatistics {
    val year: Int
    val month: Int
    val totalBillings: Long
    val totalAmount: BigDecimal
    val paidAmount: BigDecimal
}