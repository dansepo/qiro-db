package com.qiro.domain.fault.repository

import com.qiro.domain.fault.dto.*
import com.qiro.domain.fault.entity.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 신고 Repository
 */
@Repository
interface FaultReportRepository : JpaRepository<FaultReport, UUID> {

    /**
     * 회사별 고장 신고 조회
     */
    fun findByCompanyIdOrderByReportedAtDesc(companyId: UUID, pageable: Pageable): Page<FaultReport>

    /**
     * 회사별 상태별 고장 신고 조회
     */
    fun findByCompanyIdAndReportStatusOrderByReportedAtDesc(
        companyId: UUID, 
        reportStatus: ReportStatus, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 회사별 우선순위별 고장 신고 조회
     */
    fun findByCompanyIdAndFaultPriorityOrderByReportedAtDesc(
        companyId: UUID, 
        faultPriority: FaultPriority, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 회사별 긴급도별 고장 신고 조회
     */
    fun findByCompanyIdAndFaultUrgencyOrderByReportedAtDesc(
        companyId: UUID, 
        faultUrgency: FaultUrgency, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 담당자별 고장 신고 조회
     */
    fun findByCompanyIdAndAssignedToOrderByReportedAtDesc(
        companyId: UUID, 
        assignedTo: UUID, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 건물별 고장 신고 조회
     */
    fun findByCompanyIdAndBuildingIdOrderByReportedAtDesc(
        companyId: UUID, 
        buildingId: UUID, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 세대별 고장 신고 조회
     */
    fun findByCompanyIdAndUnitIdOrderByReportedAtDesc(
        companyId: UUID, 
        unitId: UUID, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 시설물별 고장 신고 조회
     */
    fun findByCompanyIdAndAssetIdOrderByReportedAtDesc(
        companyId: UUID, 
        assetId: UUID, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 분류별 고장 신고 조회
     */
    fun findByCompanyIdAndCategoryIdOrderByReportedAtDesc(
        companyId: UUID, 
        categoryId: UUID, 
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 신고 번호로 조회
     */
    fun findByCompanyIdAndReportNumber(companyId: UUID, reportNumber: String): FaultReport?

    /**
     * 긴급 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND (fr.faultUrgency = 'CRITICAL' OR fr.faultPriority = 'EMERGENCY')
        AND fr.reportStatus NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ORDER BY fr.reportedAt DESC
    """)
    fun findUrgentFaultReports(@Param("companyId") companyId: UUID): List<FaultReport>

    /**
     * 응답 시간 초과 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.firstResponseDue < :currentTime
        AND fr.firstResponseAt IS NULL
        AND fr.reportStatus NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ORDER BY fr.firstResponseDue ASC
    """)
    fun findOverdueResponseReports(
        @Param("companyId") companyId: UUID,
        @Param("currentTime") currentTime: LocalDateTime
    ): List<FaultReport>

    /**
     * 해결 시간 초과 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.resolutionDue < :currentTime
        AND fr.resolvedAt IS NULL
        AND fr.reportStatus NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ORDER BY fr.resolutionDue ASC
    """)
    fun findOverdueResolutionReports(
        @Param("companyId") companyId: UUID,
        @Param("currentTime") currentTime: LocalDateTime
    ): List<FaultReport>

    /**
     * 기간별 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reportedAt BETWEEN :startDate AND :endDate
        ORDER BY fr.reportedAt DESC
    """)
    fun findByCompanyIdAndReportedAtBetween(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime,
        pageable: Pageable
    ): Page<FaultReport>

    /**
     * 미배정 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.assignedTo IS NULL
        AND fr.reportStatus NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED')
        ORDER BY fr.faultPriority DESC, fr.reportedAt ASC
    """)
    fun findUnassignedReports(@Param("companyId") companyId: UUID): List<FaultReport>

    /**
     * 진행 중인 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reportStatus IN ('ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS')
        ORDER BY fr.faultPriority DESC, fr.reportedAt ASC
    """)
    fun findActiveReports(@Param("companyId") companyId: UUID): List<FaultReport>

    /**
     * 반복 문제 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.isRecurringIssue = true
        ORDER BY fr.reportedAt DESC
    """)
    fun findRecurringIssues(@Param("companyId") companyId: UUID): List<FaultReport>

    /**
     * 후속 조치 필요 고장 신고 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.followUpRequired = true
        AND (fr.followUpDate IS NULL OR fr.followUpDate <= :currentDate)
        ORDER BY fr.followUpDate ASC NULLS FIRST, fr.reportedAt DESC
    """)
    fun findReportsRequiringFollowUp(
        @Param("companyId") companyId: UUID,
        @Param("currentDate") currentDate: LocalDateTime
    ): List<FaultReport>

    /**
     * 통계용 쿼리 - 상태별 개수
     */
    @Query("""
        SELECT fr.reportStatus, COUNT(fr) 
        FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reportedAt BETWEEN :startDate AND :endDate
        GROUP BY fr.reportStatus
    """)
    fun countByStatusAndDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 통계용 쿼리 - 우선순위별 개수
     */
    @Query("""
        SELECT fr.faultPriority, COUNT(fr) 
        FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reportedAt BETWEEN :startDate AND :endDate
        GROUP BY fr.faultPriority
    """)
    fun countByPriorityAndDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 통계용 쿼리 - 분류별 개수
     */
    @Query("""
        SELECT fc.categoryName, COUNT(fr) 
        FROM FaultReport fr 
        JOIN FaultCategory fc ON fr.categoryId = fc.id
        WHERE fr.companyId = :companyId 
        AND fr.reportedAt BETWEEN :startDate AND :endDate
        GROUP BY fc.categoryName
    """)
    fun countByCategoryAndDateRange(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 평균 응답 시간 계산
     */
    @Query("""
        SELECT AVG(EXTRACT(EPOCH FROM (fr.firstResponseAt - fr.reportedAt)) / 3600.0)
        FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.firstResponseAt IS NOT NULL
        AND fr.reportedAt BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageResponseTimeHours(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 평균 해결 시간 계산
     */
    @Query("""
        SELECT AVG(EXTRACT(EPOCH FROM (fr.resolvedAt - fr.reportedAt)) / 3600.0)
        FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.resolvedAt IS NOT NULL
        AND fr.reportedAt BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageResolutionTimeHours(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 평균 만족도 계산
     */
    @Query("""
        SELECT AVG(fr.reporterSatisfactionRating)
        FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reporterSatisfactionRating > 0
        AND fr.reportedAt BETWEEN :startDate AND :endDate
    """)
    fun calculateAverageSatisfactionRating(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): Double?

    /**
     * 신고자별 신고 이력 조회
     */
    @Query("""
        SELECT fr FROM FaultReport fr 
        WHERE fr.companyId = :companyId 
        AND fr.reporterType = :reporterType
        AND (:reporterName IS NULL OR fr.reporterName = :reporterName)
        AND (:reporterUnitId IS NULL OR fr.reporterUnitId = :reporterUnitId)
        AND (:reporterContact IS NULL OR CAST(fr.reporterContact AS string) LIKE %:reporterContact%)
        ORDER BY fr.reportedAt DESC
    """)
    fun findReporterHistory(
        @Param("companyId") companyId: UUID,
        @Param("reporterType") reporterType: com.qiro.domain.fault.entity.ReporterType,
        @Param("reporterName") reporterName: String?,
        @Param("reporterUnitId") reporterUnitId: UUID?,
        @Param("reporterContact") reporterContact: String?,
        pageable: Pageable
    ): Page<FaultReport>
}