package com.qiro.domain.notification.repository

import com.qiro.domain.notification.entity.NotificationLog
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationStatus
import com.qiro.domain.notification.entity.NotificationType
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 로그 리포지토리
 */
@Repository
interface NotificationLogRepository : JpaRepository<NotificationLog, UUID> {

    /**
     * 수신자별 알림 로그 조회
     */
    fun findByRecipientIdOrderByCreatedAtDesc(recipientId: UUID, pageable: Pageable): Page<NotificationLog>

    /**
     * 회사별 알림 로그 조회
     */
    fun findByCompanyIdOrderByCreatedAtDesc(companyId: UUID, pageable: Pageable): Page<NotificationLog>

    /**
     * 상태별 알림 로그 조회
     */
    fun findByCompanyIdAndStatusOrderByCreatedAtDesc(
        companyId: UUID,
        status: NotificationStatus,
        pageable: Pageable
    ): Page<NotificationLog>

    /**
     * 알림 유형별 로그 조회
     */
    fun findByCompanyIdAndNotificationTypeOrderByCreatedAtDesc(
        companyId: UUID,
        notificationType: NotificationType,
        pageable: Pageable
    ): Page<NotificationLog>

    /**
     * 채널별 알림 로그 조회
     */
    fun findByCompanyIdAndChannelOrderByCreatedAtDesc(
        companyId: UUID,
        channel: NotificationMethod,
        pageable: Pageable
    ): Page<NotificationLog>

    /**
     * 실패한 알림 조회 (재시도 대상)
     */
    @Query("""
        SELECT nl FROM NotificationLog nl 
        WHERE nl.companyId = :companyId 
        AND nl.status = 'FAILED' 
        AND nl.retryCount < 3
        AND nl.createdAt > :since
        ORDER BY nl.priorityLevel DESC, nl.createdAt ASC
    """)
    fun findFailedNotificationsForRetry(
        @Param("companyId") companyId: UUID,
        @Param("since") since: LocalDateTime
    ): List<NotificationLog>

    /**
     * 읽지 않은 알림 개수 조회
     */
    @Query("""
        SELECT COUNT(nl) FROM NotificationLog nl 
        WHERE nl.recipientId = :recipientId 
        AND nl.status IN ('SENT', 'DELIVERED')
        AND nl.readAt IS NULL
    """)
    fun countUnreadNotifications(@Param("recipientId") recipientId: UUID): Long

    /**
     * 기간별 알림 통계 조회
     */
    @Query("""
        SELECT nl.status, COUNT(nl) FROM NotificationLog nl 
        WHERE nl.companyId = :companyId 
        AND nl.createdAt BETWEEN :startDate AND :endDate
        GROUP BY nl.status
    """)
    fun getNotificationStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 일일 알림 발송 제한 확인
     */
    @Query("""
        SELECT COUNT(nl) FROM NotificationLog nl 
        WHERE nl.companyId = :companyId 
        AND nl.notificationSettingId = :settingId
        AND nl.sentAt >= :startOfDay
        AND nl.status IN ('SENT', 'DELIVERED')
    """)
    fun countDailyNotifications(
        @Param("companyId") companyId: UUID,
        @Param("settingId") settingId: UUID,
        @Param("startOfDay") startOfDay: LocalDateTime
    ): Long

    /**
     * 시간별 알림 발송 제한 확인
     */
    @Query("""
        SELECT COUNT(nl) FROM NotificationLog nl 
        WHERE nl.companyId = :companyId 
        AND nl.notificationSettingId = :settingId
        AND nl.sentAt >= :startOfHour
        AND nl.status IN ('SENT', 'DELIVERED')
    """)
    fun countHourlyNotifications(
        @Param("companyId") companyId: UUID,
        @Param("settingId") settingId: UUID,
        @Param("startOfHour") startOfHour: LocalDateTime
    ): Long

    /**
     * 만료된 알림 조회
     */
    @Query("""
        SELECT nl FROM NotificationLog nl 
        WHERE nl.status = 'PENDING'
        AND nl.expiresAt IS NOT NULL
        AND nl.expiresAt < :now
    """)
    fun findExpiredNotifications(@Param("now") now: LocalDateTime): List<NotificationLog>
}