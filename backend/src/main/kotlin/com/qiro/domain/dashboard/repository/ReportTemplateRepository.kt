package com.qiro.domain.dashboard.repository

import com.qiro.domain.dashboard.entity.ReportTemplate
import com.qiro.domain.dashboard.entity.ReportType
import com.qiro.domain.dashboard.entity.ReportFrequency
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 보고서 템플릿 Repository
 */
@Repository
interface ReportTemplateRepository : JpaRepository<ReportTemplate, UUID> {

    /**
     * 회사별 보고서 템플릿 조회
     */
    fun findByCompanyCompanyIdAndIsActiveTrue(companyId: UUID): List<ReportTemplate>

    /**
     * 회사별 보고서 유형으로 조회
     */
    fun findByCompanyCompanyIdAndTemplateTypeAndIsActiveTrue(
        companyId: UUID,
        templateType: ReportType
    ): List<ReportTemplate>

    /**
     * 템플릿 이름으로 조회
     */
    fun findByCompanyCompanyIdAndTemplateNameAndIsActiveTrue(
        companyId: UUID,
        templateName: String
    ): ReportTemplate?

    /**
     * 자동 생성 템플릿 조회
     */
    fun findByCompanyCompanyIdAndAutoGenerateTrueAndIsActiveTrue(companyId: UUID): List<ReportTemplate>

    /**
     * 보고서 주기별 템플릿 조회
     */
    fun findByCompanyCompanyIdAndReportFrequencyAndAutoGenerateTrueAndIsActiveTrue(
        companyId: UUID,
        reportFrequency: ReportFrequency
    ): List<ReportTemplate>

    /**
     * 템플릿 이름 존재 여부 확인
     */
    fun existsByCompanyCompanyIdAndTemplateName(companyId: UUID, templateName: String): Boolean

    /**
     * 회사별 템플릿 수 조회
     */
    @Query("SELECT COUNT(t) FROM ReportTemplate t WHERE t.company.companyId = :companyId AND t.isActive = true")
    fun countByCompanyId(@Param("companyId") companyId: UUID): Long

    /**
     * 보고서 유형별 수 조회
     */
    @Query(
        """
        SELECT t.templateType, COUNT(t) 
        FROM ReportTemplate t 
        WHERE t.company.companyId = :companyId AND t.isActive = true 
        GROUP BY t.templateType
        """
    )
    fun countByTemplateType(@Param("companyId") companyId: UUID): List<Array<Any>>

    /**
     * 자동 생성 템플릿 수 조회
     */
    @Query(
        """
        SELECT COUNT(t) 
        FROM ReportTemplate t 
        WHERE t.company.companyId = :companyId AND t.autoGenerate = true AND t.isActive = true
        """
    )
    fun countAutoGenerateTemplates(@Param("companyId") companyId: UUID): Long
}