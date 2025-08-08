package com.qiro.domain.notification.repository

import com.qiro.domain.notification.entity.NotificationSetting
import com.qiro.domain.notification.entity.NotificationType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

/**
 * 알림 설정 리포지토리
 */
@Repository
interface NotificationSettingRepository : JpaRepository<NotificationSetting, UUID> {

    /**
     * 회사별 알림 설정 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<NotificationSetting>

    /**
     * 알림 유형별 활성 설정 조회
     */
    fun findByCompanyIdAndNotificationTypeAndIsActiveTrue(
        companyId: UUID,
        notificationType: NotificationType
    ): List<NotificationSetting>

    /**
     * 건물별 알림 설정 조회
     */
    fun findByCompanyIdAndBuildingIdAndIsActiveTrue(
        companyId: UUID,
        buildingId: UUID
    ): List<NotificationSetting>

    /**
     * 우선순위별 알림 설정 조회
     */
    @Query("""
        SELECT ns FROM NotificationSetting ns 
        WHERE ns.companyId = :companyId 
        AND ns.isActive = true 
        AND ns.priorityLevel >= :minPriority
        ORDER BY ns.priorityLevel DESC
    """)
    fun findByCompanyIdAndPriorityLevel(
        @Param("companyId") companyId: UUID,
        @Param("minPriority") minPriority: Int
    ): List<NotificationSetting>

    /**
     * 페이징된 알림 설정 조회
     */
    fun findByCompanyId(companyId: UUID, pageable: Pageable): Page<NotificationSetting>

    /**
     * 알림 유형과 건물로 설정 조회
     */
    fun findByCompanyIdAndNotificationTypeAndBuildingIdAndIsActiveTrue(
        companyId: UUID,
        notificationType: NotificationType,
        buildingId: UUID?
    ): List<NotificationSetting>

    /**
     * 긴급 알림 설정 조회 (우선순위 1-2)
     */
    @Query("""
        SELECT ns FROM NotificationSetting ns 
        WHERE ns.companyId = :companyId 
        AND ns.isActive = true 
        AND ns.priorityLevel <= 2
        ORDER BY ns.priorityLevel ASC
    """)
    fun findUrgentNotificationSettings(@Param("companyId") companyId: UUID): List<NotificationSetting>

    /**
     * 스케줄된 알림 설정 조회
     */
    @Query("""
        SELECT ns FROM NotificationSetting ns 
        WHERE ns.companyId = :companyId 
        AND ns.isActive = true 
        AND ns.triggerSchedule IS NOT NULL
    """)
    fun findScheduledNotificationSettings(@Param("companyId") companyId: UUID): List<NotificationSetting>
}