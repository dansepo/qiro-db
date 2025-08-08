package com.qiro.domain.dashboard.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import java.util.*

/**
 * 대시보드 설정 엔티티
 * 시설 관리 대시보드의 구성 정보를 관리
 */
@Entity
@Table(
    name = "dashboard_configurations",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_dashboard_config_name",
            columnNames = ["company_id", "dashboard_name"]
        )
    ]
)
class DashboardConfiguration(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "config_id")
    val configId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    val company: Company,

    @Column(name = "dashboard_name", nullable = false, length = 100)
    var dashboardName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "dashboard_type", nullable = false, length = 30)
    var dashboardType: DashboardType,

    @Column(name = "description")
    var description: String? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "widget_configuration")
    var widgetConfiguration: Map<String, Any>? = null,

    @Column(name = "refresh_interval_minutes")
    var refreshIntervalMinutes: Int = 15,

    @Column(name = "auto_refresh")
    var autoRefresh: Boolean = true,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "access_roles")
    var accessRoles: List<String>? = null,

    @Column(name = "is_public")
    var isPublic: Boolean = false,

    @Column(name = "is_active")
    var isActive: Boolean = true
) : BaseEntity()

/**
 * 대시보드 유형 열거형
 */
enum class DashboardType {
    FACILITY_OVERVIEW,      // 시설 현황 개요
    MAINTENANCE_STATUS,     // 유지보수 현황
    COST_ANALYSIS,         // 비용 분석
    FAULT_TRACKING,        // 고장 추적
    PERFORMANCE_METRICS,   // 성능 지표
    CUSTOM                 // 사용자 정의
}