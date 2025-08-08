package com.qiro.domain.fault.repository

import com.qiro.domain.fault.dto.*
import com.qiro.domain.fault.entity.FaultType
import com.qiro.domain.fault.entity.ReporterType
import jakarta.persistence.EntityManager
import jakarta.persistence.PersistenceContext
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 신고 Repository 구현체
 * 복잡한 통계 쿼리를 위한 네이티브 쿼리 구현
 */
@Repository
class FaultReportRepositoryImpl(
    @PersistenceContext
    private val entityManager: EntityManager
) {

    /**
     * 신고자별 통계 조회
     */
    fun findReporterStatistics(
        companyId: UUID,
        reporterType: ReporterType?,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): List<ReporterStatisticsDto> {
        val sql = """
            SELECT 
                fr.reporter_type,
                fr.reporter_name,
                fr.reporter_unit_id,
                u.unit_number,
                COUNT(*) as total_reports,
                COUNT(CASE WHEN fr.report_status = 'RESOLVED' THEN 1 END) as completed_reports,
                COUNT(CASE WHEN fr.report_status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') THEN 1 END) as pending_reports,
                COUNT(CASE WHEN fr.fault_priority = 'EMERGENCY' THEN 1 END) as urgent_reports,
                COALESCE(AVG(EXTRACT(EPOCH FROM (fr.first_response_at - fr.reported_at))/3600), 0) as avg_response_time_hours,
                COALESCE(AVG(EXTRACT(EPOCH FROM (fr.resolved_at - fr.reported_at))/3600), 0) as avg_resolution_time_hours,
                COALESCE(AVG(fr.reporter_satisfaction_rating), 0) as satisfaction_rating,
                MAX(fr.reported_at) as last_report_date
            FROM bms.fault_reports fr
            LEFT JOIN bms.units u ON fr.reporter_unit_id = u.unit_id
            WHERE fr.company_id = :companyId
            AND (:reporterType IS NULL OR fr.reporter_type = :reporterType)
            AND (:dateFrom IS NULL OR fr.reported_at >= :dateFrom)
            AND (:dateTo IS NULL OR fr.reported_at <= :dateTo)
            GROUP BY fr.reporter_type, fr.reporter_name, fr.reporter_unit_id, u.unit_number
            ORDER BY total_reports DESC
        """

        val query = entityManager.createNativeQuery(sql)
        query.setParameter("companyId", companyId)
        query.setParameter("reporterType", reporterType?.name)
        query.setParameter("dateFrom", dateFrom)
        query.setParameter("dateTo", dateTo)

        @Suppress("UNCHECKED_CAST")
        val results = query.resultList as List<Array<Any>>

        return results.map { row ->
            ReporterStatisticsDto(
                reporterType = ReporterType.valueOf(row[0] as String),
                reporterName = row[1] as String?,
                reporterUnitId = row[2] as UUID?,
                unitNumber = row[3] as String?,
                totalReports = (row[4] as Number).toLong(),
                completedReports = (row[5] as Number).toLong(),
                pendingReports = (row[6] as Number).toLong(),
                urgentReports = (row[7] as Number).toLong(),
                avgResponseTimeHours = (row[8] as Number).toDouble(),
                avgResolutionTimeHours = (row[9] as Number).toDouble(),
                satisfactionRating = BigDecimal.valueOf((row[10] as Number).toDouble()),
                lastReportDate = row[11] as LocalDateTime?
            )
        }
    }

    /**
     * 고장 신고 전체 통계 조회
     */
    fun findFaultReportStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?,
        groupBy: String?
    ): FaultReportStatisticsDto {
        val sql = """
            SELECT 
                COUNT(*) as total_reports,
                COUNT(CASE WHEN report_status = 'RESOLVED' THEN 1 END) as completed_reports,
                COUNT(CASE WHEN report_status NOT IN ('RESOLVED', 'CLOSED', 'CANCELLED') THEN 1 END) as pending_reports,
                COUNT(CASE WHEN resolution_due < NOW() AND resolved_at IS NULL THEN 1 END) as overdue_reports,
                COUNT(CASE WHEN fault_priority = 'EMERGENCY' THEN 1 END) as urgent_reports,
                COALESCE(AVG(EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as avg_response_time_hours,
                COALESCE(AVG(EXTRACT(EPOCH FROM (resolved_at - reported_at))/3600), 0) as avg_resolution_time_hours,
                CASE WHEN COUNT(*) > 0 THEN (COUNT(CASE WHEN report_status = 'RESOLVED' THEN 1 END) * 100.0 / COUNT(*)) ELSE 0 END as completion_rate,
                CASE WHEN COUNT(CASE WHEN resolved_at IS NOT NULL THEN 1 END) > 0 
                     THEN (COUNT(CASE WHEN resolved_at <= resolution_due THEN 1 END) * 100.0 / COUNT(CASE WHEN resolved_at IS NOT NULL THEN 1 END)) 
                     ELSE 0 END as on_time_completion_rate
            FROM bms.fault_reports 
            WHERE company_id = :companyId
            AND (:dateFrom IS NULL OR reported_at >= :dateFrom)
            AND (:dateTo IS NULL OR reported_at <= :dateTo)
        """

        val query = entityManager.createNativeQuery(sql)
        query.setParameter("companyId", companyId)
        query.setParameter("dateFrom", dateFrom)
        query.setParameter("dateTo", dateTo)

        val result = query.singleResult as Array<Any>

        return FaultReportStatisticsDto(
            totalReports = (result[0] as Number).toLong(),
            completedReports = (result[1] as Number).toLong(),
            pendingReports = (result[2] as Number).toLong(),
            overdueReports = (result[3] as Number).toLong(),
            urgentReports = (result[4] as Number).toLong(),
            avgResponseTimeHours = (result[5] as Number).toDouble(),
            avgResolutionTimeHours = (result[6] as Number).toDouble(),
            completionRate = (result[7] as Number).toDouble(),
            onTimeCompletionRate = (result[8] as Number).toDouble(),
            reportsByStatus = emptyMap(), // 별도 쿼리로 조회 필요
            reportsByPriority = emptyMap(), // 별도 쿼리로 조회 필요
            reportsByType = emptyMap(), // 별도 쿼리로 조회 필요
            reportsByCategory = emptyMap() // 별도 쿼리로 조회 필요
        )
    }

    /**
     * 응답 시간 통계 조회
     */
    fun findResponseTimeStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): ResponseTimeStatisticsDto {
        val sql = """
            SELECT 
                COALESCE(AVG(EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as avg_response_time_hours,
                COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as median_response_time_hours,
                COALESCE(MIN(EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as min_response_time_hours,
                COALESCE(MAX(EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as max_response_time_hours,
                CASE WHEN COUNT(CASE WHEN first_response_at IS NOT NULL THEN 1 END) > 0 
                     THEN (COUNT(CASE WHEN first_response_at <= first_response_due THEN 1 END) * 100.0 / COUNT(CASE WHEN first_response_at IS NOT NULL THEN 1 END)) 
                     ELSE 0 END as on_time_response_rate,
                COUNT(CASE WHEN first_response_due < NOW() AND first_response_at IS NULL THEN 1 END) as overdue_response_count,
                COUNT(CASE WHEN first_response_at IS NOT NULL THEN 1 END) as total_response_count
            FROM bms.fault_reports 
            WHERE company_id = :companyId
            AND (:dateFrom IS NULL OR reported_at >= :dateFrom)
            AND (:dateTo IS NULL OR reported_at <= :dateTo)
        """

        val query = entityManager.createNativeQuery(sql)
        query.setParameter("companyId", companyId)
        query.setParameter("dateFrom", dateFrom)
        query.setParameter("dateTo", dateTo)

        val result = query.singleResult as Array<Any>

        return ResponseTimeStatisticsDto(
            avgResponseTimeHours = (result[0] as Number).toDouble(),
            medianResponseTimeHours = (result[1] as Number).toDouble(),
            minResponseTimeHours = (result[2] as Number).toDouble(),
            maxResponseTimeHours = (result[3] as Number).toDouble(),
            responseTimeByPriority = emptyMap(), // 별도 쿼리로 조회 필요
            onTimeResponseRate = (result[4] as Number).toDouble(),
            overdueResponseCount = (result[5] as Number).toLong(),
            totalResponseCount = (result[6] as Number).toLong()
        )
    }

    /**
     * 고장 유형별 통계 조회
     */
    fun findFaultTypeStatistics(
        companyId: UUID,
        dateFrom: LocalDateTime?,
        dateTo: LocalDateTime?
    ): List<FaultTypeStatisticsDto> {
        val sql = """
            SELECT 
                fault_type,
                COUNT(*) as total_reports,
                COUNT(CASE WHEN report_status = 'RESOLVED' THEN 1 END) as completed_reports,
                COALESCE(AVG(EXTRACT(EPOCH FROM (resolved_at - reported_at))/3600), 0) as avg_resolution_time_hours,
                COALESCE(AVG(actual_repair_cost), 0) as avg_repair_cost,
                COUNT(CASE WHEN is_recurring_issue = true THEN 1 END) as recurring_issue_count,
                COALESCE(AVG(reporter_satisfaction_rating), 0) as satisfaction_rating
            FROM bms.fault_reports 
            WHERE company_id = :companyId
            AND (:dateFrom IS NULL OR reported_at >= :dateFrom)
            AND (:dateTo IS NULL OR reported_at <= :dateTo)
            GROUP BY fault_type
            ORDER BY total_reports DESC
        """

        val query = entityManager.createNativeQuery(sql)
        query.setParameter("companyId", companyId)
        query.setParameter("dateFrom", dateFrom)
        query.setParameter("dateTo", dateTo)

        @Suppress("UNCHECKED_CAST")
        val results = query.resultList as List<Array<Any>>

        return results.map { row ->
            FaultTypeStatisticsDto(
                faultType = FaultType.valueOf(row[0] as String),
                totalReports = (row[1] as Number).toLong(),
                completedReports = (row[2] as Number).toLong(),
                avgResolutionTimeHours = (row[3] as Number).toDouble(),
                avgRepairCost = BigDecimal.valueOf((row[4] as Number).toDouble()),
                recurringIssueCount = (row[5] as Number).toLong(),
                satisfactionRating = BigDecimal.valueOf((row[6] as Number).toDouble())
            )
        }
    }

    /**
     * 월별 고장 신고 추이 조회
     */
    fun findMonthlyTrend(companyId: UUID, months: Int): List<MonthlyTrendDto> {
        val sql = """
            SELECT 
                EXTRACT(YEAR FROM reported_at) as year,
                EXTRACT(MONTH FROM reported_at) as month,
                COUNT(*) as total_reports,
                COUNT(CASE WHEN report_status = 'RESOLVED' THEN 1 END) as completed_reports,
                COUNT(CASE WHEN fault_priority = 'EMERGENCY' THEN 1 END) as urgent_reports,
                COALESCE(AVG(EXTRACT(EPOCH FROM (first_response_at - reported_at))/3600), 0) as avg_response_time_hours,
                COALESCE(AVG(EXTRACT(EPOCH FROM (resolved_at - reported_at))/3600), 0) as avg_resolution_time_hours,
                COALESCE(SUM(actual_repair_cost), 0) as total_repair_cost
            FROM bms.fault_reports 
            WHERE company_id = :companyId
            AND reported_at >= NOW() - INTERVAL '$months months'
            GROUP BY EXTRACT(YEAR FROM reported_at), EXTRACT(MONTH FROM reported_at)
            ORDER BY year DESC, month DESC
        """

        val query = entityManager.createNativeQuery(sql)
        query.setParameter("companyId", companyId)

        @Suppress("UNCHECKED_CAST")
        val results = query.resultList as List<Array<Any>>

        return results.map { row ->
            MonthlyTrendDto(
                year = (row[0] as Number).toInt(),
                month = (row[1] as Number).toInt(),
                totalReports = (row[2] as Number).toLong(),
                completedReports = (row[3] as Number).toLong(),
                urgentReports = (row[4] as Number).toLong(),
                avgResponseTimeHours = (row[5] as Number).toDouble(),
                avgResolutionTimeHours = (row[6] as Number).toDouble(),
                totalRepairCost = BigDecimal.valueOf((row[7] as Number).toDouble())
            )
        }
    }
}