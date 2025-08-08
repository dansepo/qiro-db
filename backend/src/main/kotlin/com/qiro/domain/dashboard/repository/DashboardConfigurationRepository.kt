package com.qiro.domain.dashboard.repository

import com.qiro.domain.dashboard.entity.DashboardConfiguration
import com.qiro.domain.dashboard.entity.DashboardType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 대시보드 설정 Repository
 */
@Repository
interface DashboardConfigurationRepository : JpaRepository<DashboardConfiguration, UUID> {

    /**
     * 회사별 대시보드 설정 조회
     */
    fun findByCompanyCompanyIdAndIsActiveTrue(companyId: UUID): List<DashboardConfiguration>

    /**
     * 회사별 대시보드 유형으로 조회
     */
    fun findByCompanyCompanyIdAndDashboardTypeAndIsActiveTrue(
        companyId: UUID,
        dashboardType: DashboardType
    ): List<DashboardConfiguration>

    /**
     * 대시보드 이름으로 조회
     */
    fun findByCompanyCompanyIdAndDashboardNameAndIsActiveTrue(
        companyId: UUID,
        dashboardName: String
    ): DashboardConfiguration?

    /**
     * 공개 대시보드 조회
     */
    fun findByCompanyCompanyIdAndIsPublicTrueAndIsActiveTrue(companyId: UUID): List<DashboardConfiguration>

    /**
     * 대시보드 설정 존재 여부 확인
     */
    fun existsByCompanyCompanyIdAndDashboardName(companyId: UUID, dashboardName: String): Boolean

    /**
     * 회사별 대시보드 수 조회
     */
    @Query("SELECT COUNT(d) FROM DashboardConfiguration d WHERE d.company.companyId = :companyId AND d.isActive = true")
    fun countByCompanyId(@Param("companyId") companyId: UUID): Long

    /**
     * 대시보드 유형별 수 조회
     */
    @Query(
        """
        SELECT d.dashboardType, COUNT(d) 
        FROM DashboardConfiguration d 
        WHERE d.company.companyId = :companyId AND d.isActive = true 
        GROUP BY d.dashboardType
        """
    )
    fun countByDashboardType(@Param("companyId") companyId: UUID): List<Array<Any>>
}