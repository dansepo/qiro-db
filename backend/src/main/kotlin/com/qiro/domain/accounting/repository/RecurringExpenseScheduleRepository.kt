package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.RecurringExpenseSchedule
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 정기 지출 스케줄 Repository
 */
@Repository
interface RecurringExpenseScheduleRepository : JpaRepository<RecurringExpenseSchedule, UUID> {

    /**
     * 회사별 활성 스케줄 조회
     */
    fun findByCompanyIdAndIsActiveTrueOrderByNextGenerationDateAsc(companyId: UUID): List<RecurringExpenseSchedule>

    /**
     * 생성 대상 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.isActive = true 
        AND res.nextGenerationDate <= :date 
        AND (res.endDate IS NULL OR res.endDate >= :date)
        ORDER BY res.nextGenerationDate ASC
    """)
    fun findSchedulesToGenerate(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): List<RecurringExpenseSchedule>

    /**
     * 지출 유형별 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.expenseType.expenseTypeId = :expenseTypeId 
        AND res.isActive = true
    """)
    fun findByExpenseType(
        @Param("companyId") companyId: UUID,
        @Param("expenseTypeId") expenseTypeId: UUID
    ): List<RecurringExpenseSchedule>

    /**
     * 건물별 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.buildingId = :buildingId 
        AND res.isActive = true
    """)
    fun findByBuilding(
        @Param("companyId") companyId: UUID,
        @Param("buildingId") buildingId: UUID
    ): List<RecurringExpenseSchedule>

    /**
     * 세대별 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.unitId = :unitId 
        AND res.isActive = true
    """)
    fun findByUnit(
        @Param("companyId") companyId: UUID,
        @Param("unitId") unitId: UUID
    ): List<RecurringExpenseSchedule>

    /**
     * 업체별 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.vendor.vendorId = :vendorId 
        AND res.isActive = true
    """)
    fun findByVendor(
        @Param("companyId") companyId: UUID,
        @Param("vendorId") vendorId: UUID
    ): List<RecurringExpenseSchedule>

    /**
     * 주기별 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.frequency = :frequency 
        AND res.isActive = true
    """)
    fun findByFrequency(
        @Param("companyId") companyId: UUID,
        @Param("frequency") frequency: RecurringExpenseSchedule.Frequency
    ): List<RecurringExpenseSchedule>

    /**
     * 자동 승인 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.autoApprove = true 
        AND res.isActive = true
    """)
    fun findAutoApproveSchedules(@Param("companyId") companyId: UUID): List<RecurringExpenseSchedule>

    /**
     * 만료된 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.endDate IS NOT NULL 
        AND res.endDate < :date 
        AND res.isActive = true
    """)
    fun findExpiredSchedules(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now()
    ): List<RecurringExpenseSchedule>

    /**
     * 곧 만료될 스케줄 조회
     */
    @Query("""
        SELECT res FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.isActive = true 
        AND res.endDate IS NOT NULL 
        AND res.endDate BETWEEN :date AND :endDate
    """)
    fun findExpiringSchedules(
        @Param("companyId") companyId: UUID,
        @Param("date") date: LocalDate = LocalDate.now(),
        @Param("endDate") endDate: LocalDate = LocalDate.now().plusDays(30)
    ): List<RecurringExpenseSchedule>

    /**
     * 스케줄명으로 조회
     */
    fun findByCompanyIdAndScheduleName(companyId: UUID, scheduleName: String): RecurringExpenseSchedule?

    /**
     * 중복 스케줄 확인
     */
    @Query("""
        SELECT COUNT(res) > 0 FROM RecurringExpenseSchedule res 
        WHERE res.companyId = :companyId 
        AND res.expenseType.expenseTypeId = :expenseTypeId 
        AND res.unitId = :unitId 
        AND res.vendor.vendorId = :vendorId
        AND res.isActive = true 
        AND (:scheduleId IS NULL OR res.scheduleId != :scheduleId)
    """)
    fun hasDuplicateSchedule(
        @Param("companyId") companyId: UUID,
        @Param("expenseTypeId") expenseTypeId: UUID,
        @Param("unitId") unitId: UUID?,
        @Param("vendorId") vendorId: UUID?,
        @Param("scheduleId") scheduleId: UUID?
    ): Boolean

    // Service에서 필요한 추가 메서드들
    
    /**
     * 회사별 활성 정기 지출 스케줄 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<RecurringExpenseSchedule>
}