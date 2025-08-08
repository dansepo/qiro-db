package com.qiro.domain.dashboard.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.util.*

/**
 * 보고서 템플릿 엔티티
 * 시설 관리 보고서 템플릿 정보를 관리
 */
@Entity
@Table(
    name = "report_templates",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_report_templates_name",
            columnNames = ["company_id", "template_name"]
        )
    ]
)
class ReportTemplate(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "template_id")
    val templateId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    val company: Company,

    @Column(name = "template_name", nullable = false, length = 100)
    var templateName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "template_type", nullable = false, length = 30)
    var templateType: ReportType,

    @Column(name = "description")
    var description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "report_format", length = 20)
    var reportFormat: ReportFormat = ReportFormat.PDF,

    @Enumerated(EnumType.STRING)
    @Column(name = "report_frequency", length = 20)
    var reportFrequency: ReportFrequency = ReportFrequency.MONTHLY,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "data_sources")
    var dataSources: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "filter_criteria")
    var filterCriteria: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "grouping_criteria")
    var groupingCriteria: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "sorting_criteria")
    var sortingCriteria: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "layout_configuration")
    var layoutConfiguration: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "chart_configurations")
    var chartConfigurations: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "table_configurations")
    var tableConfigurations: Map<String, Any>? = null,

    @Column(name = "auto_generate")
    var autoGenerate: Boolean = false,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "distribution_list")
    var distributionList: List<String>? = null,

    @Column(name = "is_active")
    var isActive: Boolean = true
) : BaseEntity()

/**
 * 보고서 유형 열거형
 */
enum class ReportType {
    FACILITY_STATUS,        // 시설 현황
    MAINTENANCE_SUMMARY,    // 유지보수 요약
    COST_ANALYSIS,         // 비용 분석
    FAULT_STATISTICS,      // 고장 통계
    PERFORMANCE_REPORT,    // 성능 보고서
    COMPLIANCE_REPORT,     // 규정 준수 보고서
    CUSTOM                 // 사용자 정의
}

/**
 * 보고서 형식 열거형
 */
enum class ReportFormat {
    PDF,
    EXCEL,
    HTML,
    CSV
}

/**
 * 보고서 생성 주기 열거형
 */
enum class ReportFrequency {
    DAILY,      // 일간
    WEEKLY,     // 주간
    MONTHLY,    // 월간
    QUARTERLY,  // 분기
    YEARLY,     // 연간
    ON_DEMAND   // 요청시
}