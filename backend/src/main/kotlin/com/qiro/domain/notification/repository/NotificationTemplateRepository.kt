package com.qiro.domain.notification.repository

import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationTemplate
import com.qiro.domain.notification.entity.NotificationType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 알림 템플릿 리포지토리
 */
@Repository
interface NotificationTemplateRepository : JpaRepository<NotificationTemplate, UUID> {

    /**
     * 회사별 활성 템플릿 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<NotificationTemplate>

    /**
     * 알림 유형과 채널별 템플릿 조회
     */
    fun findByCompanyIdAndTemplateTypeAndChannelAndIsActiveTrue(
        companyId: UUID,
        templateType: NotificationType,
        channel: NotificationMethod
    ): List<NotificationTemplate>

    /**
     * 기본 템플릿 조회
     */
    fun findByCompanyIdAndTemplateTypeAndChannelAndIsDefaultTrueAndIsActiveTrue(
        companyId: UUID,
        templateType: NotificationType,
        channel: NotificationMethod
    ): NotificationTemplate?

    /**
     * 언어별 템플릿 조회
     */
    fun findByCompanyIdAndTemplateTypeAndChannelAndLanguageCodeAndIsActiveTrue(
        companyId: UUID,
        templateType: NotificationType,
        channel: NotificationMethod,
        languageCode: String
    ): List<NotificationTemplate>

    /**
     * 페이징된 템플릿 조회
     */
    fun findByCompanyId(companyId: UUID, pageable: Pageable): Page<NotificationTemplate>

    /**
     * 템플릿 이름으로 검색
     */
    @Query("""
        SELECT nt FROM NotificationTemplate nt 
        WHERE nt.companyId = :companyId 
        AND nt.isActive = true
        AND LOWER(nt.templateName) LIKE LOWER(CONCAT('%', :name, '%'))
    """)
    fun findByTemplateNameContaining(
        @Param("companyId") companyId: UUID,
        @Param("name") name: String
    ): List<NotificationTemplate>

    /**
     * 채널별 템플릿 조회
     */
    fun findByCompanyIdAndChannelAndIsActiveTrue(
        companyId: UUID,
        channel: NotificationMethod
    ): List<NotificationTemplate>

    /**
     * 알림 유형별 템플릿 조회
     */
    fun findByCompanyIdAndTemplateTypeAndIsActiveTrue(
        companyId: UUID,
        templateType: NotificationType
    ): List<NotificationTemplate>
}