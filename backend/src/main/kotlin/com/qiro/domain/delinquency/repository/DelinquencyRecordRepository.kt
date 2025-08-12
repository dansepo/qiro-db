package com.qiro.domain.delinquency.repository

import com.qiro.domain.delinquency.entity.DelinquencyRecord
import com.qiro.domain.delinquency.entity.DelinquencyStatus
import com.qiro.domain.delinquency.entity.SeverityLevel
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
 * 미납 관리 Repository
 */
@Repository
interface DelinquencyRecordRepository : JpaRepository<DelinquencyRecord, UUID> {

    /**
     * 회사별 미납 기록 목록 조회
     */
    fun findByCompanyIdOrderByCreatedDateDesc(companyId: UUID, pageable: Pageable): Page<DelinquencyRecord>

    /**
     * 활성 미납 기록 조회
     */
    fun findByCompanyIdAndStatusOrderByOverdueDaysDesc(
        companyId: UUID,
        status: DelinquencyStatus,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 세대별 미납 기록 조회
     */
    fun findByCompanyIdAndUnitIdOrderByCreatedDateDesc(
        companyId: UUID,
        unitId: UUID,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 심각도별 미납 기록 조회
     */
    fun findByCompanyIdAndSeverityLevelOrderByOverdueDaysDesc(
        companyId: UUID,
        severityLevel: SeverityLevel,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 연체 일수 기준 미납 기록 조회
     */
    @Query("""
        SELECT d FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId 
        AND d.overdueDays >= :minOverdueDays
        AND d.status = 'ACTIVE'
        ORDER BY d.overdueDays DESC
    """)
    fun findByOverdueDaysGreaterThanEqual(
        @Param("companyId") companyId: UUID,
        @Param("minOverdueDays") minOverdueDays: Int,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 담당자별 미납 기록 조회
     */
    fun findByCompanyIdAndAssignedToOrderByOverdueDaysDesc(
        companyId: UUID,
        assignedTo: String,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 다음 조치 예정 미납 기록 조회
     */
    @Query("""
        SELECT d FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId 
        AND d.nextActionDate <= :targetDate
        AND d.status = 'ACTIVE'
        ORDER BY d.nextActionDate ASC
    """)
    fun findByNextActionDateBefore(
        @Param("companyId") companyId: UUID,
        @Param("targetDate") targetDate: LocalDate,
        pageable: Pageable
    ): Page<DelinquencyRecord>

    /**
     * 미납 통계 조회
     */
    @Query("""
        SELECT 
            COUNT(d) as totalCount,
            COALESCE(SUM(d.outstandingAmount), 0) as totalOutstandingAmount,
            COALESCE(SUM(d.lateFeeAmount), 0) as totalLateFeeAmount,
            COALESCE(SUM(d.outstandingAmount + d.lateFeeAmount), 0) as totalDelinquencyAmount,
            COALESCE(AVG(d.overdueDays), 0) as averageOverdueDays
        FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId
        AND (:status IS NULL OR d.status = :status)
        AND (:severityLevel IS NULL OR d.severityLevel = :severityLevel)
    """)
    fun getDelinquencyStatistics(
        @Param("companyId") companyId: UUID,
        @Param("status") status: DelinquencyStatus? = null,
        @Param("severityLevel") severityLevel: SeverityLevel? = null
    ): DelinquencyStatistics

    /**
     * 심각도별 미납 통계 조회
     */
    @Query("""
        SELECT 
            d.severityLevel as severityLevel,
            COUNT(d) as recordCount,
            COALESCE(SUM(d.outstandingAmount + d.lateFeeAmount), 0) as totalAmount,
            COALESCE(AVG(d.overdueDays), 0) as averageOverdueDays
        FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId
        AND d.status = 'ACTIVE'
        GROUP BY d.severityLevel
        ORDER BY d.severityLevel
    """)
    fun getSeverityLevelStats(@Param("companyId") companyId: UUID): List<SeverityLevelStats>

    /**
     * 월별 미납 발생 현황 조회
     */
    @Query("""
        SELECT 
            EXTRACT(YEAR FROM d.createdDate) as year,
            EXTRACT(MONTH FROM d.createdDate) as month,
            COUNT(d) as newDelinquencyCount,
            COALESCE(SUM(d.originalAmount), 0) as totalOriginalAmount
        FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId
        AND d.createdDate BETWEEN :startDate AND :endDate
        GROUP BY EXTRACT(YEAR FROM d.createdDate), EXTRACT(MONTH FROM d.createdDate)
        ORDER BY year DESC, month DESC
    """)
    fun getMonthlyDelinquencyStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDate,
        @Param("endDate") endDate: LocalDate
    ): List<MonthlyDelinquencyStats>

    /**
     * 세대별 미납 현황 조회
     */
    @Query("""
        SELECT 
            d.unit.id as unitId,
            d.unit.unitNumber as unitNumber,
            COUNT(d) as delinquencyCount,
            COALESCE(SUM(d.outstandingAmount + d.lateFeeAmount), 0) as totalAmount,
            MAX(d.overdueDays) as maxOverdueDays,
            MAX(d.severityLevel) as maxSeverityLevel
        FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId
        AND d.status = 'ACTIVE'
        GROUP BY d.unit.id, d.unit.unitNumber
        ORDER BY totalAmount DESC
    """)
    fun getUnitDelinquencyStats(@Param("companyId") companyId: UUID): List<UnitDelinquencyStats>

    /**
     * 연체료 적용 대상 조회
     */
    @Query("""
        SELECT d FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId 
        AND d.status = 'ACTIVE'
        AND d.overdueDays > 0
        AND (d.lateFeeAmount = 0 OR d.lateFeeAmount IS NULL)
        ORDER BY d.overdueDays DESC
    """)
    fun findLateFeeApplicableRecords(@Param("companyId") companyId: UUID): List<DelinquencyRecord>

    /**
     * 독촉 대상 조회
     */
    @Query("""
        SELECT d FROM DelinquencyRecord d 
        WHERE d.companyId = :companyId 
        AND d.status = 'ACTIVE'
        AND (d.lastNoticeDate IS NULL OR d.lastNoticeDate <= :cutoffDate)
        AND d.overdueDays >= :minOverdueDays
        ORDER BY d.overdueDays DESC
    """)
    fun findNoticeTargetRecords(
        @Param("companyId") companyId: UUID,
        @Param("cutoffDate") cutoffDate: LocalDate,
        @Param("minOverdueDays") minOverdueDays: Int = 7
    ): List<DelinquencyRecord>
}

/**
 * 미납 통계 인터페이스
 */
interface DelinquencyStatistics {
    val totalCount: Long
    val totalOutstandingAmount: BigDecimal
    val totalLateFeeAmount: BigDecimal
    val totalDelinquencyAmount: BigDecimal
    val averageOverdueDays: Double
}

/**
 * 심각도별 통계 인터페이스
 */
interface SeverityLevelStats {
    val severityLevel: SeverityLevel
    val recordCount: Long
    val totalAmount: BigDecimal
    val averageOverdueDays: Double
}

/**
 * 월별 미납 통계 인터페이스
 */
interface MonthlyDelinquencyStats {
    val year: Int
    val month: Int
    val newDelinquencyCount: Long
    val totalOriginalAmount: BigDecimal
}

/**
 * 세대별 미납 통계 인터페이스
 */
interface UnitDelinquencyStats {
    val unitId: UUID
    val unitNumber: String
    val delinquencyCount: Long
    val totalAmount: BigDecimal
    val maxOverdueDays: Int
    val maxSeverityLevel: SeverityLevel
}