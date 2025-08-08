package com.qiro.domain.dashboard.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import com.qiro.domain.user.entity.User
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.GeneratedValue
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 생성된 보고서 엔티티
 * 생성된 보고서의 이력과 메타데이터를 관리
 */
@Entity
@Table(
    name = "generated_reports",
    schema = "bms"
)
class GeneratedReport(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "report_id")
    val reportId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    val company: Company,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "template_id")
    val template: ReportTemplate? = null,

    @Column(name = "report_name", nullable = false, length = 200)
    var reportName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "report_type", nullable = false, length = 30)
    var reportType: ReportType,

    @Column(name = "report_period_start")
    var reportPeriodStart: LocalDate? = null,

    @Column(name = "report_period_end")
    var reportPeriodEnd: LocalDate? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "generation_type", length = 20)
    var generationType: GenerationType = GenerationType.MANUAL,

    @Column(name = "generated_at")
    var generatedAt: LocalDateTime = LocalDateTime.now(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "generated_by")
    var generatedBy: User? = null,

    @Column(name = "file_name")
    var fileName: String? = null,

    @Column(name = "file_path", length = 500)
    var filePath: String? = null,

    @Column(name = "file_size")
    var fileSize: Long? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "file_format", length = 20)
    var fileFormat: ReportFormat? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "summary_data")
    var summaryData: Map<String, Any>? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "key_metrics")
    var keyMetrics: Map<String, Any>? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "distribution_status", length = 20)
    var distributionStatus: DistributionStatus = DistributionStatus.PENDING,

    @Column(name = "distributed_at")
    var distributedAt: LocalDateTime? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "distribution_log")
    var distributionLog: List<Map<String, Any>>? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "report_status", length = 20)
    var reportStatus: ReportStatus = ReportStatus.GENERATED
) : BaseEntity()

/**
 * 보고서 생성 유형 열거형
 */
enum class GenerationType {
    MANUAL,     // 수동 생성
    AUTO,       // 자동 생성
    SCHEDULED   // 예약 생성
}

/**
 * 배포 상태 열거형
 */
enum class DistributionStatus {
    PENDING,        // 대기중
    IN_PROGRESS,    // 진행중
    COMPLETED,      // 완료
    FAILED,         // 실패
    CANCELLED       // 취소
}

/**
 * 보고서 상태 열거형
 */
enum class ReportStatus {
    GENERATING,     // 생성중
    GENERATED,      // 생성완료
    DISTRIBUTED,    // 배포완료
    ARCHIVED,       // 보관
    DELETED         // 삭제
}