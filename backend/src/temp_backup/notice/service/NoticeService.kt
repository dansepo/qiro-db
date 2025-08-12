package com.qiro.domain.notice.service

import com.qiro.domain.notice.dto.*
import com.qiro.domain.notice.entity.*
import com.qiro.domain.notice.repository.NoticeRepository
import com.qiro.domain.notice.repository.NoticeAttachmentRepository
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.io.File
import java.nio.file.Files
import java.nio.file.Paths
import java.time.LocalDateTime
import java.util.*

/**
 * 공지사항 서비스
 */
@Service
@Transactional
class NoticeService(
    private val noticeRepository: NoticeRepository,
    private val noticeAttachmentRepository: NoticeAttachmentRepository,
    private val notificationService: NotificationService
) {

    /**
     * 공지사항 생성
     */
    fun createNotice(request: NoticeCreateRequest, createdBy: UUID): NoticeResponse {
        val notice = Notice(
            title = request.title,
            content = request.content,
            category = request.category,
            priority = request.priority,
            publishedAt = request.publishedAt,
            expiresAt = request.expiresAt,
            createdBy = createdBy
        )

        val savedNotice = noticeRepository.save(notice)
        
        // 즉시 발행되는 경우 알림 전송
        if (request.publishedAt != null && request.publishedAt.isBefore(LocalDateTime.now().plusMinutes(1))) {
            notificationService.sendNoticeNotification(savedNotice)
        }

        return convertToResponse(savedNotice)
    }

    /**
     * 공지사항 수정
     */
    fun updateNotice(noticeId: UUID, request: NoticeUpdateRequest, updatedBy: UUID): NoticeResponse {
        val notice = noticeRepository.findById(noticeId)
            .orElseThrow { IllegalArgumentException("공지사항을 찾을 수 없습니다: $noticeId") }

        // 작성자 권한 확인 (실제 구현에서는 관리자 권한도 확인)
        if (notice.createdBy != updatedBy) {
            throw IllegalArgumentException("공지사항을 수정할 권한이 없습니다")
        }

        val updatedNotice = notice.copy(
            title = request.title ?: notice.title,
            content = request.content ?: notice.content,
            category = request.category ?: notice.category,
            priority = request.priority ?: notice.priority,
            publishedAt = request.publishedAt ?: notice.publishedAt,
            expiresAt = request.expiresAt ?: notice.expiresAt,
            updatedAt = LocalDateTime.now()
        )

        val savedNotice = noticeRepository.save(updatedNotice)
        return convertToResponse(savedNotice)
    }

    /**
     * 공지사항 삭제
     */
    fun deleteNotice(noticeId: UUID, deletedBy: UUID) {
        val notice = noticeRepository.findById(noticeId)
            .orElseThrow { IllegalArgumentException("공지사항을 찾을 수 없습니다: $noticeId") }

        // 작성자 권한 확인
        if (notice.createdBy != deletedBy) {
            throw IllegalArgumentException("공지사항을 삭제할 권한이 없습니다")
        }

        // 첨부파일도 함께 삭제
        noticeAttachmentRepository.deleteByNoticeId(noticeId)
        noticeRepository.delete(notice)
    }

    /**
     * 공지사항 상세 조회
     */
    @Transactional(readOnly = true)
    fun getNotice(noticeId: UUID): NoticeResponse {
        val notice = noticeRepository.findById(noticeId)
            .orElseThrow { IllegalArgumentException("공지사항을 찾을 수 없습니다: $noticeId") }

        return convertToResponse(notice)
    }

    /**
     * 발행된 공지사항 목록 조회
     */
    @Transactional(readOnly = true)
    fun getPublishedNotices(pageable: Pageable): NoticePageResponse {
        val now = LocalDateTime.now()
        val noticePage = noticeRepository.findPublishedNotices(now, pageable)

        val content = noticePage.content.map { convertToListResponse(it) }

        return NoticePageResponse(
            content = content,
            totalElements = noticePage.totalElements,
            totalPages = noticePage.totalPages,
            currentPage = noticePage.number,
            size = noticePage.size,
            hasNext = noticePage.hasNext(),
            hasPrevious = noticePage.hasPrevious()
        )
    }

    /**
     * 분류별 공지사항 조회
     */
    @Transactional(readOnly = true)
    fun getNoticesByCategory(category: NoticeCategory, pageable: Pageable): NoticePageResponse {
        val now = LocalDateTime.now()
        val noticePage = noticeRepository.findPublishedNoticesByCategory(category, now, pageable)

        val content = noticePage.content.map { convertToListResponse(it) }

        return NoticePageResponse(
            content = content,
            totalElements = noticePage.totalElements,
            totalPages = noticePage.totalPages,
            currentPage = noticePage.number,
            size = noticePage.size,
            hasNext = noticePage.hasNext(),
            hasPrevious = noticePage.hasPrevious()
        )
    }

    /**
     * 공지사항 검색
     */
    @Transactional(readOnly = true)
    fun searchNotices(request: NoticeSearchRequest): NoticePageResponse {
        val now = LocalDateTime.now()
        val pageable = PageRequest.of(request.page, request.size)

        val noticePage = when {
            !request.keyword.isNullOrBlank() -> {
                noticeRepository.searchPublishedNotices(request.keyword, now, pageable)
            }
            request.category != null -> {
                noticeRepository.findPublishedNoticesByCategory(request.category, now, pageable)
            }
            request.priority != null -> {
                noticeRepository.findPublishedNoticesByPriority(request.priority, now, pageable)
            }
            else -> {
                noticeRepository.findPublishedNotices(now, pageable)
            }
        }

        val content = noticePage.content.map { convertToListResponse(it) }

        return NoticePageResponse(
            content = content,
            totalElements = noticePage.totalElements,
            totalPages = noticePage.totalPages,
            currentPage = noticePage.number,
            size = noticePage.size,
            hasNext = noticePage.hasNext(),
            hasPrevious = noticePage.hasPrevious()
        )
    }

    /**
     * 긴급 공지사항 조회
     */
    @Transactional(readOnly = true)
    fun getUrgentNotices(): List<NoticeListResponse> {
        val now = LocalDateTime.now()
        return noticeRepository.findUrgentNotices(now)
            .map { convertToListResponse(it) }
    }

    /**
     * 최근 공지사항 조회
     */
    @Transactional(readOnly = true)
    fun getRecentNotices(limit: Int = 5): List<NoticeListResponse> {
        val now = LocalDateTime.now()
        return noticeRepository.findRecentNotices(now, limit)
            .map { convertToListResponse(it) }
    }

    /**
     * 공지사항 발행
     */
    fun publishNotice(noticeId: UUID, request: NoticePublishRequest): NoticePublishResponse {
        val notice = noticeRepository.findById(noticeId)
            .orElseThrow { IllegalArgumentException("공지사항을 찾을 수 없습니다: $noticeId") }

        val publishedNotice = notice.copy(
            publishedAt = request.publishedAt,
            updatedAt = LocalDateTime.now()
        )

        val savedNotice = noticeRepository.save(publishedNotice)

        // 알림 전송
        var notificationsSent = 0
        if (request.sendNotification) {
            notificationsSent = notificationService.sendNoticeNotification(savedNotice)
        }

        return NoticePublishResponse(
            noticeId = savedNotice.id,
            title = savedNotice.title,
            publishedAt = savedNotice.publishedAt!!,
            notificationsSent = notificationsSent
        )
    }

    /**
     * 첨부파일 업로드
     */
    fun uploadAttachment(noticeId: UUID, file: MultipartFile): NoticeAttachmentUploadResponse {
        val notice = noticeRepository.findById(noticeId)
            .orElseThrow { IllegalArgumentException("공지사항을 찾을 수 없습니다: $noticeId") }

        // 파일 저장 (실제 구현에서는 설정 가능한 경로 사용)
        val uploadDir = "uploads/notices/$noticeId"
        val uploadPath = Paths.get(uploadDir)
        Files.createDirectories(uploadPath)

        val fileName = "${UUID.randomUUID()}_${file.originalFilename}"
        val filePath = uploadPath.resolve(fileName)
        Files.copy(file.inputStream, filePath)

        val attachment = NoticeAttachment(
            notice = notice,
            filename = file.originalFilename ?: fileName,
            filePath = filePath.toString(),
            fileSize = file.size,
            contentType = file.contentType
        )

        val savedAttachment = noticeAttachmentRepository.save(attachment)

        return NoticeAttachmentUploadResponse(
            id = savedAttachment.id,
            filename = savedAttachment.filename,
            fileSize = savedAttachment.fileSize ?: 0,
            contentType = savedAttachment.contentType,
            uploadedAt = savedAttachment.createdAt
        )
    }

    /**
     * 공지사항 통계 조회
     */
    @Transactional(readOnly = true)
    fun getNoticeStats(): NoticeStatsResponse {
        val now = LocalDateTime.now()
        
        val totalNotices = noticeRepository.count()
        val publishedNotices = noticeRepository.findPublishedNotices(now, PageRequest.of(0, 1)).totalElements
        val urgentNotices = noticeRepository.findUrgentNotices(now).size.toLong()
        val expiredNotices = noticeRepository.findExpiredNotices(now).size.toLong()
        
        val categoryStats = noticeRepository.countNoticesByCategory(now)
            .map { result ->
                NoticeCategoryStats(
                    category = result[0] as NoticeCategory,
                    categoryName = (result[0] as NoticeCategory).displayName,
                    count = result[1] as Long
                )
            }

        val recentNotices = getRecentNotices(5)

        return NoticeStatsResponse(
            totalNotices = totalNotices,
            publishedNotices = publishedNotices,
            urgentNotices = urgentNotices,
            expiredNotices = expiredNotices,
            categoryStats = categoryStats,
            recentNotices = recentNotices
        )
    }

    /**
     * Notice 엔티티를 NoticeResponse로 변환
     */
    private fun convertToResponse(notice: Notice): NoticeResponse {
        val attachments = noticeAttachmentRepository.findByNoticeIdOrderByCreatedAtAsc(notice.id)
            .map { attachment ->
                NoticeAttachmentResponse(
                    id = attachment.id,
                    filename = attachment.filename,
                    fileSize = attachment.fileSize,
                    formattedFileSize = attachment.getFormattedFileSize(),
                    contentType = attachment.contentType,
                    downloadUrl = "/api/notices/attachments/${attachment.id}/download",
                    isImage = attachment.isImage(),
                    isDocument = attachment.isDocument(),
                    createdAt = attachment.createdAt
                )
            }

        return NoticeResponse(
            id = notice.id,
            title = notice.title,
            content = notice.content,
            category = notice.category,
            categoryName = notice.category.displayName,
            priority = notice.priority,
            priorityName = notice.priority.displayName,
            priorityColor = notice.priority.color,
            publishedAt = notice.publishedAt,
            expiresAt = notice.expiresAt,
            createdBy = notice.createdBy,
            createdAt = notice.createdAt,
            updatedAt = notice.updatedAt,
            attachments = attachments,
            isActive = notice.isActive(),
            isPublished = notice.isPublished(),
            isExpired = notice.isExpired(),
            isUrgent = notice.isUrgent()
        )
    }

    /**
     * Notice 엔티티를 NoticeListResponse로 변환
     */
    private fun convertToListResponse(notice: Notice): NoticeListResponse {
        val attachmentCount = noticeAttachmentRepository.countByNoticeId(notice.id).toInt()
        val summary = if (notice.content.length > 100) {
            notice.content.take(100) + "..."
        } else {
            notice.content
        }

        return NoticeListResponse(
            id = notice.id,
            title = notice.title,
            category = notice.category,
            categoryName = notice.category.displayName,
            priority = notice.priority,
            priorityName = notice.priority.displayName,
            priorityColor = notice.priority.color,
            publishedAt = notice.publishedAt,
            expiresAt = notice.expiresAt,
            createdAt = notice.createdAt,
            attachmentCount = attachmentCount,
            isActive = notice.isActive(),
            isUrgent = notice.isUrgent(),
            summary = summary
        )
    }
}