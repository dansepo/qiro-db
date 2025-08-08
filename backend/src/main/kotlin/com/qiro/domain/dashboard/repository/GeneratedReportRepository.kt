package com.qiro.domain.dashboard.repository

import com.qiro.domain.dashboard.entity.GeneratedReport
import com.qiro.domain.dashboard.entity.ReportType
import com.qiro.domain.dashboard.entity.ReportStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 생성된 보고서 Repository
 */
@Repository
interface GeneratedReportRepository : JpaRepository<GeneratedReport, UUID> {

    /**
     * 회사별 생성된 보고서 조회 (페이징)
     */
    fun findByCompanyCompanyIdOrderByGeneratedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<GeneratedReport>

    /**
     * 회사별 보고서 유형으로 조회
     */
    fun findByCompanyCompanyIdAndReportTypeOrderByGeneratedAtDesc(
        companyId: UUID,
        reportType: ReportType
    ): List<GeneratedReport>

    /**
     * 기간별 보고서 조회
     */
    fun findByCompanyCompanyIdAndGeneratedAtBetweenOrderByGeneratedAtDesc(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<GeneratedReport>

    /**
     * 보고서 상태별 조회
     */
    fun findByCompanyCompanyIdAndReportStatusOrderByGeneratedAtDesc(
        companyId: UUID,
        reportStatus: ReportStatus
    ): List<GeneratedReport>

    /**
     * 템플릿별 생성된 보고서 조회
     */
    fun findByTemplateTemplateIdOrderByGeneratedAtDesc(templateId: UUID): List<GeneratedReport>

    /**
     * 최근 생성된 보고서 조회
     */
    @Query(
        """
        SELECT r FROM GeneratedReport r 
        WHERE r.company.companyId = :companyId 
        ORDER BY r.generatedAt DESC
        """
    )
    fun findRecentReports(
        @Param("companyId") companyId: UUID,
        pageable: Pageable
    ): Page<GeneratedReport>

    /**
     * 보고서 기간별 조회
     */
    fun findByCompanyCompanyIdAndReportPeriodStartAndReportPeriodEnd(
        companyId: UUID,
        periodStart: LocalDate,
        periodEnd: LocalDate
    ): List<GeneratedReport>

    /**
     * 회사별 보고서 수 조회
     */
    @Query("SELECT COUNT(r) FROM GeneratedReport r WHERE r.company.companyId = :companyId")
    fun countByCompanyId(@Param("companyId") companyId: UUID): Long

    /**
     * 보고서 유형별 수 조회
     */
    @Query(
        """
        SELECT r.reportType, COUNT(r) 
        FROM GeneratedReport r 
        WHERE r.company.companyId = :companyId 
        GROUP BY r.reportType
        """
    )
    fun countByReportType(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 월별 보고서 생성 통계
     */
    @Query(
        value = """
        SELECT 
            DATE_TRUNC('month', generated_at) as month,
            COUNT(*) as report_count
        FROM bms.generated_reports 
        WHERE company_id = :companyId 
          AND generated_at >= :startDate
        GROUP BY DATE_TRUNC('month', generated_at)
        ORDER BY month DESC
        """,
        nativeQuery = true
    )
    fun getMonthlyReportStats(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 보고서 상태별 통계
     */
    @Query(
        """
        SELECT r.reportStatus, COUNT(r) 
        FROM GeneratedReport r 
        WHERE r.company.companyId = :companyId 
        GROUP BY r.reportStatus
        """
    )
    fun getReportStatusStats(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 파일 크기 통계
     */
    @Query(
        """
        SELECT 
            COUNT(r) as total_reports,
            COALESCE(SUM(r.fileSize), 0) as total_file_size,
            COALESCE(AVG(r.fileSize), 0) as avg_file_size
        FROM GeneratedReport r 
        WHERE r.company.companyId = :companyId 
          AND r.fileSize IS NOT NULL
        """
    )
    fun getFileSizeStats(@Param("companyId") companyId: UUID): Map<String, Any>
}