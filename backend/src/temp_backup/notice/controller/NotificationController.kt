package com.qiro.domain.notice.controller

import com.qiro.domain.notice.dto.*
import com.qiro.domain.notice.entity.NotificationType
import com.qiro.domain.notice.service.NotificationService
import org.springframework.data.domain.PageRequest
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 REST API Controller
 */
@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = ["*"])
class NotificationController(
    private val notificationService: NotificationService
) {

    /**
     * 사용자별 알림 목록 조회
     */
    @GetMapping
    fun getNotifications(
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        @RequestParam(required = false) type: NotificationType?,
        @RequestParam(required = false) isRead: Boolean?
    ): ResponseEntity<NotificationPageResponse> {
        val userUuid = UUID.fromString(userId)
        val pageable = PageRequest.of(page, size)
        
        val response = if (type != null || isRead != null) {
            // 검색 기능 활용
            val searchRequest = NotificationSearchRequest(
                userId = userUuid,
                type = type,
                isRead = isRead,
                page = page,
                size = size
            )
            notificationService.searchNotifications(searchRequest)
        } else {
            notificationService.getUserNotifications(userUuid, pageable)
        }
        
        return ResponseEntity.ok(response)
    }

    /**
     * 알림 상세 조회
     */
    @GetMapping("/{id}")
    fun getNotification(
        @PathVariable id: UUID,
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<NotificationResponse> {
        val userUuid = UUID.fromString(userId)
        val response = notificationService.getNotification(id, userUuid)
        return ResponseEntity.ok(response)
    }

    /**
     * 알림 생성 (관리자)
     */
    @PostMapping
    fun createNotification(
        @RequestBody request: NotificationCreateRequest
    ): ResponseEntity<NotificationResponse> {
        val response = notificationService.createNotification(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }

    /**
     * 대량 알림 생성 (관리자)
     */
    @PostMapping("/bulk")
    fun createBulkNotifications(
        @RequestBody request: BulkNotificationCreateRequest
    ): ResponseEntity<BulkNotificationCreateResponse> {
        val response = notificationService.createBulkNotifications(request)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }

    /**
     * 알림 읽음 처리
     */
    @PutMapping("/read")
    fun markNotificationsAsRead(
        @RequestHeader("X-User-Id") userId: String,
        @RequestBody request: NotificationReadRequest
    ): ResponseEntity<NotificationReadResponse> {
        val userUuid = UUID.fromString(userId)
        val response = notificationService.markNotificationsAsRead(userUuid, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 특정 알림 읽음 처리
     */
    @PutMapping("/{id}/read")
    fun markNotificationAsRead(
        @PathVariable id: UUID,
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<NotificationReadResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationReadRequest(
            notificationIds = listOf(id),
            markAll = false
        )
        val response = notificationService.markNotificationsAsRead(userUuid, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 전체 알림 읽음 처리
     */
    @PutMapping("/read-all")
    fun markAllNotificationsAsRead(
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<NotificationReadResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationReadRequest(markAll = true)
        val response = notificationService.markNotificationsAsRead(userUuid, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 읽지 않은 알림 개수 조회
     */
    @GetMapping("/unread-count")
    fun getUnreadCount(
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<Map<String, Long>> {
        val userUuid = UUID.fromString(userId)
        val count = notificationService.getUnreadCount(userUuid)
        return ResponseEntity.ok(mapOf("unreadCount" to count))
    }

    /**
     * 긴급 알림 조회
     */
    @GetMapping("/urgent")
    fun getUrgentNotifications(
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<List<NotificationListResponse>> {
        val userUuid = UUID.fromString(userId)
        val response = notificationService.getUrgentNotifications(userUuid)
        return ResponseEntity.ok(response)
    }

    /**
     * 최근 알림 조회
     */
    @GetMapping("/recent")
    fun getRecentNotifications(
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(defaultValue = "10") limit: Int
    ): ResponseEntity<List<NotificationListResponse>> {
        val userUuid = UUID.fromString(userId)
        val response = notificationService.getRecentNotifications(userUuid, limit)
        return ResponseEntity.ok(response)
    }

    /**
     * 알림 검색
     */
    @GetMapping("/search")
    fun searchNotifications(
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(required = false) type: NotificationType?,
        @RequestParam(required = false) isRead: Boolean?,
        @RequestParam(required = false) startDate: LocalDateTime?,
        @RequestParam(required = false) endDate: LocalDateTime?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NotificationPageResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationSearchRequest(
            userId = userUuid,
            type = type,
            isRead = isRead,
            startDate = startDate,
            endDate = endDate,
            page = page,
            size = size
        )
        
        val response = notificationService.searchNotifications(request)
        return ResponseEntity.ok(response)
    }

    /**
     * 알림 통계 조회
     */
    @GetMapping("/stats")
    fun getNotificationStats(
        @RequestHeader("X-User-Id") userId: String
    ): ResponseEntity<NotificationStatsResponse> {
        val userUuid = UUID.fromString(userId)
        val response = notificationService.getNotificationStats(userUuid)
        return ResponseEntity.ok(response)
    }

    /**
     * 알림 타입 목록 조회
     */
    @GetMapping("/types")
    fun getNotificationTypes(): ResponseEntity<List<Map<String, Any>>> {
        val types = NotificationType.values().map { type ->
            mapOf(
                "code" to type.name,
                "name" to type.displayName,
                "description" to type.description
            )
        }
        return ResponseEntity.ok(types)
    }

    /**
     * 타입별 알림 조회
     */
    @GetMapping("/type/{type}")
    fun getNotificationsByType(
        @PathVariable type: NotificationType,
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NotificationPageResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationSearchRequest(
            userId = userUuid,
            type = type,
            page = page,
            size = size
        )
        
        val response = notificationService.searchNotifications(request)
        return ResponseEntity.ok(response)
    }

    /**
     * 읽지 않은 알림만 조회
     */
    @GetMapping("/unread")
    fun getUnreadNotifications(
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NotificationPageResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationSearchRequest(
            userId = userUuid,
            isRead = false,
            page = page,
            size = size
        )
        
        val response = notificationService.searchNotifications(request)
        return ResponseEntity.ok(response)
    }

    /**
     * 읽은 알림만 조회
     */
    @GetMapping("/read")
    fun getReadNotifications(
        @RequestHeader("X-User-Id") userId: String,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NotificationPageResponse> {
        val userUuid = UUID.fromString(userId)
        val request = NotificationSearchRequest(
            userId = userUuid,
            isRead = true,
            page = page,
            size = size
        )
        
        val response = notificationService.searchNotifications(request)
        return ResponseEntity.ok(response)
    }

    /**
     * 오래된 읽은 알림 정리 (관리자)
     */
    @DeleteMapping("/cleanup")
    fun cleanupOldNotifications(
        @RequestParam(defaultValue = "30") beforeDays: Long
    ): ResponseEntity<Map<String, Any>> {
        val deletedCount = notificationService.cleanupOldNotifications(beforeDays)
        return ResponseEntity.ok(
            mapOf(
                "message" to "${beforeDays}일 이전의 읽은 알림이 정리되었습니다.",
                "deletedCount" to deletedCount
            )
        )
    }

    /**
     * 예외 처리
     */
    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgumentException(e: IllegalArgumentException): ResponseEntity<Map<String, String>> {
        return ResponseEntity.badRequest().body(
            mapOf(
                "error" to "잘못된 요청",
                "message" to (e.message ?: "알 수 없는 오류가 발생했습니다.")
            )
        )
    }

    @ExceptionHandler(Exception::class)
    fun handleException(e: Exception): ResponseEntity<Map<String, String>> {
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            mapOf(
                "error" to "서버 오류",
                "message" to "서버에서 오류가 발생했습니다."
            )
        )
    }
}