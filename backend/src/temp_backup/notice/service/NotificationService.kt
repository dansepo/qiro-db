package com.qiro.domain.notice.service

import com.qiro.domain.notice.dto.*
import com.qiro.domain.notice.entity.*
import com.qiro.domain.notice.repository.NotificationRepository
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 서비스
 */
@Service
@Transactional
class NotificationService(
    private val notificationRepository: NotificationRepository
) {

    /**
     * 공지사항 알림 전송
     */
    fun sendNoticeNotification(notice: Notice): Int {
        // 실제 구현에서는 사용자 목록을 조회해서 알림 생성
        // 여기서는 예시로 더미 사용자들에게 알림 전송
        val userIds = getDummyUserIds() // 실제로는 UserService에서 조회
        
        var sentCount = 0
        userIds.forEach { userId ->
            try {
                val notification = Notification(
                    userId = userId,
                    notice = notice,
                    title = "[${notice.category.displayName}] ${notice.title}",
                    message = notice.content.take(200),
                    type = when (notice.category) {
                        NoticeCategory.URGENT -> NotificationType.URGENT
                        NoticeCategory.MAINTENANCE -> NotificationType.MAINTENANCE
                        NoticeCategory.MANAGEMENT_FEE -> NotificationType.MANAGEMENT_FEE
                        else -> NotificationType.NOTICE
                    }
                )
                
                notificationRepository.save(notification)
                sentCount++
            } catch (e: Exception) {
                // 로그 기록 (실제 구현에서는 로깅 프레임워크 사용)
                println("알림 전송 실패 - 사용자: $userId, 오류: ${e.message}")
            }
        }
        
        return sentCount
    }

    /**
     * 알림 생성
     */
    fun createNotification(request: NotificationCreateRequest): NotificationResponse {
        val notification = Notification(
            userId = request.userId,
            notice = null, // 공지사항과 연결되지 않은 일반 알림
            title = request.title,
            message = request.message,
            type = request.type
        )

        val savedNotification = notificationRepository.save(notification)
        return convertToResponse(savedNotification)
    }

    /**
     * 대량 알림 생성
     */
    fun createBulkNotifications(request: BulkNotificationCreateRequest): BulkNotificationCreateResponse {
        var successCount = 0
        var failureCount = 0

        request.userIds.forEach { userId ->
            try {
                val notification = Notification(
                    userId = userId,
                    notice = null,
                    title = request.title,
                    message = request.message,
                    type = request.type
                )
                
                notificationRepository.save(notification)
                successCount++
            } catch (e: Exception) {
                failureCount++
                println("대량 알림 생성 실패 - 사용자: $userId, 오류: ${e.message}")
            }
        }

        return BulkNotificationCreateResponse(
            totalUsers = request.userIds.size,
            successCount = successCount,
            failureCount = failureCount,
            createdAt = LocalDateTime.now(),
            message = "대량 알림이 생성되었습니다. 성공: $successCount, 실패: $failureCount"
        )
    }

    /**
     * 사용자별 알림 목록 조회
     */
    @Transactional(readOnly = true)
    fun getUserNotifications(userId: UUID, pageable: Pageable): NotificationPageResponse {
        val notificationPage = notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
        val unreadCount = notificationRepository.countByUserIdAndIsReadFalse(userId)

        val content = notificationPage.content.map { convertToListResponse(it) }

        return NotificationPageResponse(
            content = content,
            totalElements = notificationPage.totalElements,
            totalPages = notificationPage.totalPages,
            currentPage = notificationPage.number,
            size = notificationPage.size,
            hasNext = notificationPage.hasNext(),
            hasPrevious = notificationPage.hasPrevious(),
            unreadCount = unreadCount
        )
    }

    /**
     * 알림 상세 조회
     */
    @Transactional(readOnly = true)
    fun getNotification(notificationId: UUID, userId: UUID): NotificationResponse {
        val notification = notificationRepository.findById(notificationId)
            .orElseThrow { IllegalArgumentException("알림을 찾을 수 없습니다: $notificationId") }

        // 사용자 권한 확인
        if (notification.userId != userId) {
            throw IllegalArgumentException("알림을 조회할 권한이 없습니다")
        }

        return convertToResponse(notification)
    }

    /**
     * 알림 읽음 처리
     */
    fun markNotificationsAsRead(userId: UUID, request: NotificationReadRequest): NotificationReadResponse {
        val processedCount = if (request.markAll) {
            // 전체 읽음 처리
            notificationRepository.markAllAsReadByUserId(userId, LocalDateTime.now())
        } else if (!request.notificationIds.isNullOrEmpty()) {
            // 선택된 알림들 읽음 처리
            var count = 0
            request.notificationIds.forEach { notificationId ->
                count += notificationRepository.markAsReadByIdAndUserId(
                    notificationId, userId, LocalDateTime.now()
                )
            }
            count
        } else {
            0
        }

        val remainingUnreadCount = notificationRepository.countByUserIdAndIsReadFalse(userId)

        return NotificationReadResponse(
            processedCount = processedCount,
            remainingUnreadCount = remainingUnreadCount,
            message = "${processedCount}개의 알림이 읽음 처리되었습니다."
        )
    }

    /**
     * 사용자별 읽지 않은 알림 개수 조회
     */
    @Transactional(readOnly = true)
    fun getUnreadCount(userId: UUID): Long {
        return notificationRepository.countByUserIdAndIsReadFalse(userId)
    }

    /**
     * 사용자별 긴급 알림 조회
     */
    @Transactional(readOnly = true)
    fun getUrgentNotifications(userId: UUID): List<NotificationListResponse> {
        return notificationRepository.findUrgentNotificationsByUserId(userId)
            .map { convertToListResponse(it) }
    }

    /**
     * 사용자별 최근 알림 조회
     */
    @Transactional(readOnly = true)
    fun getRecentNotifications(userId: UUID, limit: Int = 10): List<NotificationListResponse> {
        return notificationRepository.findRecentNotificationsByUserId(userId, limit)
            .map { convertToListResponse(it) }
    }

    /**
     * 알림 검색
     */
    @Transactional(readOnly = true)
    fun searchNotifications(request: NotificationSearchRequest): NotificationPageResponse {
        val pageable = PageRequest.of(request.page, request.size)
        
        val notificationPage = when {
            request.type != null -> {
                notificationRepository.findByUserIdAndTypeOrderByCreatedAtDesc(
                    request.userId, request.type, pageable
                )
            }
            request.startDate != null && request.endDate != null -> {
                notificationRepository.findNotificationsByUserIdAndDateRange(
                    request.userId, request.startDate, request.endDate
                )
                // 페이징 처리를 위해 임시로 전체 조회 후 수동 페이징
                // 실제 구현에서는 Repository에 페이징 쿼리 추가 필요
                val allNotifications = notificationRepository.findNotificationsByUserIdAndDateRange(
                    request.userId, request.startDate, request.endDate
                )
                val startIndex = request.page * request.size
                val endIndex = minOf(startIndex + request.size, allNotifications.size)
                val content = if (startIndex < allNotifications.size) {
                    allNotifications.subList(startIndex, endIndex).map { convertToListResponse(it) }
                } else {
                    emptyList()
                }
                
                val unreadCount = notificationRepository.countByUserIdAndIsReadFalse(request.userId)
                
                return NotificationPageResponse(
                    content = content,
                    totalElements = allNotifications.size.toLong(),
                    totalPages = (allNotifications.size + request.size - 1) / request.size,
                    currentPage = request.page,
                    size = request.size,
                    hasNext = endIndex < allNotifications.size,
                    hasPrevious = request.page > 0,
                    unreadCount = unreadCount
                )
            }
            else -> {
                notificationRepository.findByUserIdOrderByCreatedAtDesc(request.userId, pageable)
            }
        }

        val content = notificationPage.content.map { convertToListResponse(it) }
        val unreadCount = notificationRepository.countByUserIdAndIsReadFalse(request.userId)

        return NotificationPageResponse(
            content = content,
            totalElements = notificationPage.totalElements,
            totalPages = notificationPage.totalPages,
            currentPage = notificationPage.number,
            size = notificationPage.size,
            hasNext = notificationPage.hasNext(),
            hasPrevious = notificationPage.hasPrevious(),
            unreadCount = unreadCount
        )
    }

    /**
     * 알림 통계 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationStats(userId: UUID): NotificationStatsResponse {
        val totalNotifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(
            userId, PageRequest.of(0, 1)
        ).totalElements
        
        val unreadCount = notificationRepository.countByUserIdAndIsReadFalse(userId)
        val readCount = totalNotifications - unreadCount
        
        val urgentNotifications = notificationRepository.findUrgentNotificationsByUserId(userId)
        val urgentCount = urgentNotifications.size.toLong()
        
        val recentNotifications = notificationRepository.findRecentNotificationsByUserId(userId, 100)
        val recentCount = recentNotifications.size.toLong()

        val typeStats = notificationRepository.getNotificationStatsByUserId(userId)
            .map { result ->
                NotificationTypeStats(
                    type = result[0] as NotificationType,
                    typeName = (result[0] as NotificationType).displayName,
                    totalCount = result[1] as Long,
                    unreadCount = result[2] as Long
                )
            }

        return NotificationStatsResponse(
            totalNotifications = totalNotifications,
            unreadCount = unreadCount,
            readCount = readCount,
            urgentCount = urgentCount,
            recentCount = recentCount,
            typeStats = typeStats
        )
    }

    /**
     * 오래된 읽은 알림 정리
     */
    fun cleanupOldNotifications(beforeDays: Long = 30): Int {
        val beforeDate = LocalDateTime.now().minusDays(beforeDays)
        return notificationRepository.deleteReadNotificationsBefore(beforeDate)
    }

    /**
     * Notification 엔티티를 NotificationResponse로 변환
     */
    private fun convertToResponse(notification: Notification): NotificationResponse {
        val noticeInfo = notification.notice?.let { notice ->
            NotificationNoticeInfo(
                noticeId = notice.id,
                title = notice.title,
                category = notice.category.displayName,
                priority = notice.priority.displayName,
                publishedAt = notice.publishedAt
            )
        }

        return NotificationResponse(
            id = notification.id,
            userId = notification.userId,
            noticeId = notification.notice?.id,
            title = notification.title,
            message = notification.message,
            summary = notification.getSummary(),
            type = notification.type,
            typeName = notification.type.displayName,
            isRead = notification.isRead,
            readAt = notification.readAt,
            createdAt = notification.createdAt,
            isRecent = notification.isRecent(),
            isUrgent = notification.isUrgent(),
            noticeInfo = noticeInfo
        )
    }

    /**
     * Notification 엔티티를 NotificationListResponse로 변환
     */
    private fun convertToListResponse(notification: Notification): NotificationListResponse {
        return NotificationListResponse(
            id = notification.id,
            title = notification.title,
            summary = notification.getSummary(),
            type = notification.type,
            typeName = notification.type.displayName,
            isRead = notification.isRead,
            createdAt = notification.createdAt,
            isRecent = notification.isRecent(),
            isUrgent = notification.isUrgent()
        )
    }

    /**
     * 더미 사용자 ID 목록 (실제 구현에서는 UserService에서 조회)
     */
    private fun getDummyUserIds(): List<UUID> {
        return listOf(
            UUID.fromString("11111111-1111-1111-1111-111111111111"),
            UUID.fromString("22222222-2222-2222-2222-222222222222"),
            UUID.fromString("33333333-3333-3333-3333-333333333333")
        )
    }
}