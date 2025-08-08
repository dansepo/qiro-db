package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.RecurringIncomeSchedule
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 정기 수입 스케줄 Repository
 */
@Repository
interface RecurringIncomeScheduleRepository : JpaRepository<RecurringIncomeSchedule, UUID> {

    /**
     * 회사별 활성 스케줄 조회
     */
    fun findByCompanyIdAndIsActiveTrueOrderByNextGenerationDateAsc(companyId: UUID): List<RecurringIncomeSchedule>

    /**
     * 생성 대상 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.isActive = true 
        AND ris.nextGenerationDate <= :date 
        AND (ris.endDate IS NULL OR ris.endDate >= :date)
        ORDER BY ris.nextGenerationDate ASC
    """)
    fun findSchedulesToGenerate(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): List<RecurringIncomeSchedule>

    /**
     * 수입 유형별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.incomeType.incomeTypeId = :incomeTypeId 
        AND ris.isActive = true
    """)
    fun findByIncomeType(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID
    ): List<RecurringIncomeSchedule>

    /**
     * 건물별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.buildingId = :buildingId 
        AND ris.isActive = true
    """)
    fun findByBuilding(
        @Param("companyId") companyId: UUID,
        @Param("buildingId") buildingId: UUID
    ): List<RecurringIncomeSchedule>

    /**
     * 세대별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.unitId = :unitId 
        AND ris.isActive = true
    """)
    fun findByUnit(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: UUID
    ): List<RecurringIncomeSchedule>

    /**
     * 임차인별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.tenantId = :tenantId 
        AND ris.isActive = true
    """)
    fun findByTenant(
        @Param("companyId") companyId: UUID,
        @Param("tenantId") tenantId: UUID
    ): List<RecurringIncomeSchedule>

    /**
     * 계약별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.contractId = :contractId 
        AND ris.isActive = true
    """)
    fun findByContract(
        @Param("companyId") companyId: UUID,
        @Param("contractId") contractId: UUID
    ): List<RecurringIncomeSchedule>

    /**
     * 주기별 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.frequency = :frequency 
        AND ris.isActive = true
    """)
    fun findByFrequency(
        @Param("companyId") companyId: UUID,
        @Param("frequency") frequency: RecurringIncomeSchedule.Frequency
    ): List<RecurringIncomeSchedule>

    /**
     * 만료된 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.endDate IS NOT NULL 
        AND ris.endDate < :date 
        AND ris.isActive = true
    """)
    fun findExpiredSchedules(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): List<RecurringIncomeSchedule>

    /**
     * 곧 만료될 스케줄 조회
     */
    @Query("""
        SELECT ris FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.isActive = true 
        AND ris.endDate IS NOT NULL 
        AND ris.endDate BETWEEN :date AND :endDate
    """)
    fun findExpiringSchedules(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now(),
        @Param("endDate") endDate: LocalDate = LocalDate.now().plusDays(30)
    ): List<RecurringIncomeSchedule>

    /**
     * 스케줄명으로 조회
     */
    fun findByCompanyIdAndScheduleName(companyId: UUID, scheduleName: String): RecurringIncomeSchedule?

    /**
     * 중복 스케줄 확인
     */
    @Query("""
        SELECT COUNT(ris) > 0 FROM RecurringIncomeSchedule ris 
        WHERE ris.companyId = :companyId 
        AND ris.incomeType.incomeTypeId = :incomeTypeId 
        AND ris.unitId = :unitId 
        AND ris.isActive = true 
        AND (:scheduleId IS NULL OR ris.scheduleId != :scheduleId)
    """)
    fun hasDuplicateSchedule(
        @Param("companyId") companyId: UUID,
        @Param("incomeTypeId") incomeTypeId: UUID,
        @Param("unitId") unitId: UUID?,
        @Param("scheduleId") scheduleId: UUID?
    ): Boolean
}