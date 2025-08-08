package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.TaxSchedule
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.util.*

/**
 * 세무 일정 Repository
 */
@Repository
interface TaxScheduleRepository : JpaRepository<TaxSchedule, UUID> {

    /**
     * 회사별 세무 일정 조회
     */
    fun findByCompanyIdOrderByDueDateAsc(companyId: UUID): List<TaxSchedule>

    /**
     * 회사별, 상태별 세무 일정 조회
     */
    fun findByCompanyIdAndStatusOrderByDueDateAsc(
        companyId: UUID,
        status: TaxSchedule.ScheduleStatus
    ): List<TaxSchedule>

    /**
     * 회사별, 세금 유형별 세무 일정 조회
     */
    fun findByCompanyIdAndTaxTypeOrderByDueDateAsc(
        companyId: UUID,
        taxType: TaxSchedule.TaxType
    ): List<TaxSchedule>

    /**
     * 회사별, 담당자별 세무 일정 조회
     */
    fun findByCompanyIdAndAssignedToOrderByDueDateAsc(
        companyId: UUID,
        assignedTo: UUID
    ): List<TaxSchedule>

    /**
     * 기간별 세무 일정 조회
     */
    fun findByCompanyIdAndDueDateBetweenOrderByDueDateAsc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<TaxSchedule>

    /**
     * 오늘 마감인 세무 일정 조회
     */
    @Query("""
        SELECT ts FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate = :today
        AND ts.status IN ('PENDING', 'IN_PROGRESS')
        ORDER BY ts.priority DESC, ts.dueDate ASC
    """)
    fun findTodayDueSchedules(
        @Param("companyId") companyId: UUID,
        @Param("today") today: LocalDate
    ): List<TaxSchedule>

    /**
     * 연체된 세무 일정 조회
     */
    @Query("""
        SELECT ts FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate < :currentDate
        AND ts.status IN ('PENDING', 'IN_PROGRESS')
        ORDER BY ts.dueDate ASC
    """)
    fun findOverdueSchedules(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate
    ): List<TaxSchedule>

    /**
     * 임박한 세무 일정 조회 (향후 N일 이내)
     */
    @Query("""
        SELECT ts FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate BETWEEN :currentDate AND :futureDate
        AND ts.status IN ('PENDING', 'IN_PROGRESS')
        ORDER BY ts.dueDate ASC, ts.priority DESC
    """)
    fun findUpcomingSchedules(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate,
        @Param("futureDate") futureDate: LocalDate
    ): List<TaxSchedule>

    /**
     * 알림이 필요한 세무 일정 조회
     */
    @Query("""
        SELECT ts FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.reminderDate <= :currentDate
        AND ts.status = 'PENDING'
        ORDER BY ts.dueDate ASC
    """)
    fun findSchedulesNeedingReminder(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDate
    ): List<TaxSchedule>

    /**
     * 우선순위별 세무 일정 조회
     */
    fun findByCompanyIdAndPriorityOrderByDueDateAsc(
        companyId: UUID,
        priority: TaxSchedule.Priority
    ): List<TaxSchedule>

    /**
     * 월별 세무 일정 통계
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM ts.dueDate) as year,
            EXTRACT(MONTH FROM ts.dueDate) as month,
            ts.status,
            COUNT(ts) as count
        FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM ts.dueDate), EXTRACT(MONTH FROM ts.dueDate), ts.status
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyScheduleStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 세금 유형별 일정 통계
     */
    @Query("""
        SELECT 
            ts.taxType,
            ts.status,
            COUNT(ts) as count
        FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate BETWEEN :startDate AND :endDate
        GROUP BY ts.taxType, ts.status
        ORDER BY ts.taxType
    """)
    fun getScheduleStatisticsByTaxType(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 담당자별 일정 통계
     */
    @Query("""
        SELECT 
            ts.assignedTo,
            ts.status,
            COUNT(ts) as count
        FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.assignedTo IS NOT NULL
        AND ts.dueDate BETWEEN :startDate AND :endDate
        GROUP BY ts.assignedTo, ts.status
        ORDER BY ts.assignedTo
    """)
    fun getScheduleStatisticsByAssignee(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<Array<Any>>

    /**
     * 완료율 통계
     */
    @Query("""
        SELECT 
            COUNT(CASE WHEN ts.status = 'COMPLETED' THEN 1 END) as completedCount,
            COUNT(ts) as totalCount,
            ROUND(
                COUNT(CASE WHEN ts.status = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(ts), 2
            ) as completionRate
        FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.dueDate BETWEEN :startDate AND :endDate
    """)
    fun getCompletionStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): Array<Any>

    /**
     * 일정 유형별 세무 일정 조회
     */
    fun findByCompanyIdAndScheduleTypeOrderByDueDateAsc(
        companyId: UUID,
        scheduleType: TaxSchedule.ScheduleType
    ): List<TaxSchedule>

    /**
     * 특정 기간 내 완료된 일정 조회
     */
    @Query("""
        SELECT ts FROM TaxSchedule ts 
        WHERE ts.companyId = :companyId 
        AND ts.status = 'COMPLETED'
        AND ts.completionDate BETWEEN :startDate AND :endDate
        ORDER BY ts.completionDate DESC
    """)
    fun findCompletedSchedulesInPeriod(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<TaxSchedule>
}