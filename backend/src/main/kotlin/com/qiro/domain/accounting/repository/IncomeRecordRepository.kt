package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.IncomeRecord
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 수입 기록 Repository
 */
@Repository
interface IncomeRecordRepository : JpaRepository<IncomeRecord, UUID> {

    /**
     * 회사별 수입 기록 조회 (페이징)
     */
    fun findByCompanyIdOrderByIncomeDateDesc(companyId: UUID, pageable: Pageable): Page<IncomeRecord>

    /**
     * 기간별 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.incomeDate BETWEEN :startDate AND :endDate 
        ORDER BY ir.incomeDate DESC
    """)
    fun findByDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<IncomeRecord>

    /**
     * 상태별 수입 기록 조회
     */
    fun findByCompanyIdAndStatus(companyId: UUID, status: IncomeRecord.Status): List<IncomeRecord>

    /**
     * 건물별 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.buildingId = :buildingId 
        ORDER BY ir.incomeDate DESC
    """)
    fun findByBuilding(
        @Param("companyId") companyId: UUID,
        @Param("buildingId") buildingId: UUID
    ): List<IncomeRecord>

    /**
     * 세대별 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.unitId = :unitId 
        ORDER BY ir.incomeDate DESC
    """)
    fun findByUnit(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: UUID
    ): List<IncomeRecord>

    /**
     * 임차인별 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.tenantId = :tenantId 
        ORDER BY ir.incomeDate DESC
    """)
    fun findByTenant(
        @Param("companyId") companyId: UUID,
        @Param("tenantId") tenantId: UUID
    ): List<IncomeRecord>

    /**
     * 수입 유형별 기간 집계
     */
    @Query("""
        SELECT ir.incomeType.typeCode, SUM(ir.totalAmount) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.incomeDate BETWEEN :startDate AND :endDate 
        AND ir.status = 'CONFIRMED'
        GROUP BY ir.incomeType.typeCode
    """)
    fun getIncomeByTypeAndPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 월별 수입 집계
     */
    @Query("""
        SELECT EXTRACT(YEAR FROM ir.incomeDate), EXTRACT(MONTH FROM ir.incomeDate), SUM(ir.totalAmount) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.incomeDate BETWEEN :startDate AND :endDate 
        AND ir.status = 'CONFIRMED'
        GROUP BY EXTRACT(YEAR FROM ir.incomeDate), EXTRACT(MONTH FROM ir.incomeDate)
        ORDER BY EXTRACT(YEAR FROM ir.incomeDate), EXTRACT(MONTH FROM ir.incomeDate)
    """)
    fun getMonthlyIncomeTotal(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 총 수입 금액 계산
     */
    @Query("""
        SELECT COALESCE(SUM(ir.totalAmount), 0) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.incomeDate BETWEEN :startDate AND :endDate 
        AND ir.status = 'CONFIRMED'
    """)
    fun getTotalIncomeAmount(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 참조 번호로 수입 기록 조회
     */
    fun findByCompanyIdAndReferenceNumber(companyId: UUID, referenceNumber: String): IncomeRecord?

    /**
     * 분개 전표 연결되지 않은 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.status = 'CONFIRMED' 
        AND ir.journalEntryId IS NULL
    """)
    fun findUnlinkedIncomeRecords(@Param("companyId") companyId: UUID): List<IncomeRecord>

    // Service에서 필요한 추가 메서드들
    
    /**
     * 필터 조건에 따른 수입 기록 조회
     */
    @Query("""
        SELECT ir FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND (:startDate IS NULL OR ir.dueDate >= :startDate)
        AND (:endDate IS NULL OR ir.dueDate <= :endDate)
        AND (:incomeTypeId IS NULL OR ir.incomeType.id = :incomeTypeId)
        AND (:unitId IS NULL OR ir.unitId = :unitId)
        AND (:status IS NULL OR ir.status = :status)
        ORDER BY ir.dueDate DESC
    """)
    fun findByCompanyIdAndFilters(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate?,
        @Param("endDate") endDate: LocalDate?,
        @Param("incomeTypeId") incomeTypeId: UUID?,
        @Param("unitId") unitId: String?,
        @Param("status") status: com.qiro.domain.accounting.entity.IncomeStatus?
    ): List<IncomeRecord>

    /**
     * 기간별 총 수입 금액 조회
     */
    @Query("""
        SELECT COALESCE(SUM(ir.amount), 0) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.dueDate BETWEEN :startDate AND :endDate
    """)
    fun getTotalIncomeByPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): BigDecimal

    /**
     * 기간별 수입 건수 조회
     */
    @Query("""
        SELECT COUNT(ir) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.dueDate BETWEEN :startDate AND :endDate
    """)
    fun getIncomeCountByPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Int

    /**
     * 기간별 및 유형별 총 수입 금액 조회
     */
    @Query("""
        SELECT COALESCE(SUM(ir.amount), 0) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.dueDate BETWEEN :startDate AND :endDate
        AND ir.incomeType.id = :incomeTypeId
    """)
    fun getTotalIncomeByPeriodAndType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        @Param("incomeTypeId") incomeTypeId: UUID
    ): BigDecimal

    /**
     * 기간별 및 유형별 수입 건수 조회
     */
    @Query("""
        SELECT COUNT(ir) 
        FROM IncomeRecord ir 
        WHERE ir.companyId = :companyId 
        AND ir.dueDate BETWEEN :startDate AND :endDate
        AND ir.incomeType.id = :incomeTypeId
    """)
    fun getIncomeCountByPeriodAndType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate,
        @Param("incomeTypeId") incomeTypeId: UUID
    ): Int
}