package com.qiro.domain.notice.controller

import com.qiro.domain.notice.dto.*
import com.qiro.domain.notice.entity.NoticeCategory
import com.qiro.domain.notice.entity.NoticePriority
import com.qiro.domain.notice.service.NoticeService
import org.springframework.data.domain.PageRequest
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import java.util.*

/**
 * 공지사항 REST API Controller
 */
@RestController
@RequestMapping("/api/notices")
@CrossOrigin(origins = ["*"])
class NoticeController(
    private val noticeService: NoticeService
) {

    /**
     * 공지사항 목록 조회
     */
    @GetMapping
    fun getNotices(
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int,
        @RequestParam(required = false) category: NoticeCategory?,
        @RequestParam(required = false) priority: NoticePriority?
    ): ResponseEntity<NoticePageResponse> {
        val pageable = PageRequest.of(page, size)
        
        val response = when {
            category != null -> noticeService.getNoticesByCategory(category, pageable)
            else -> noticeService.getPublishedNotices(pageable)
        }
        
        return ResponseEntity.ok(response)
    }

    /**
     * 공지사항 상세 조회
     */
    @GetMapping("/{id}")
    fun getNotice(@PathVariable id: UUID): ResponseEntity<NoticeResponse> {
        val response = noticeService.getNotice(id)
        return ResponseEntity.ok(response)
    }

    /**
     * 공지사항 생성 (관리자)
     */
    @PostMapping
    fun createNotice(
        @RequestBody request: NoticeCreateRequest,
        @RequestHeader("X-User-Id") createdBy: String
    ): ResponseEntity<NoticeResponse> {
        val createdByUuid = UUID.fromString(createdBy)
        val response = noticeService.createNotice(request, createdByUuid)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }

    /**
     * 공지사항 수정 (관리자)
     */
    @PutMapping("/{id}")
    fun updateNotice(
        @PathVariable id: UUID,
        @RequestBody request: NoticeUpdateRequest,
        @RequestHeader("X-User-Id") updatedBy: String
    ): ResponseEntity<NoticeResponse> {
        val updatedByUuid = UUID.fromString(updatedBy)
        val response = noticeService.updateNotice(id, request, updatedByUuid)
        return ResponseEntity.ok(response)
    }

    /**
     * 공지사항 삭제 (관리자)
     */
    @DeleteMapping("/{id}")
    fun deleteNotice(
        @PathVariable id: UUID,
        @RequestHeader("X-User-Id") deletedBy: String
    ): ResponseEntity<Map<String, String>> {
        val deletedByUuid = UUID.fromString(deletedBy)
        noticeService.deleteNotice(id, deletedByUuid)
        return ResponseEntity.ok(mapOf("message" to "공지사항이 삭제되었습니다."))
    }

    /**
     * 공지사항 검색
     */
    @GetMapping("/search")
    fun searchNotices(
        @RequestParam(required = false) keyword: String?,
        @RequestParam(required = false) category: NoticeCategory?,
        @RequestParam(required = false) priority: NoticePriority?,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NoticePageResponse> {
        val request = NoticeSearchRequest(
            keyword = keyword,
            category = category,
            priority = priority,
            page = page,
            size = size
        )
        
        val response = noticeService.searchNotices(request)
        return ResponseEntity.ok(response)
    }

    /**
     * 공지사항 분류 목록 조회
     */
    @GetMapping("/categories")
    fun getCategories(): ResponseEntity<List<Map<String, Any>>> {
        val categories = NoticeCategory.values().map { category ->
            mapOf(
                "code" to category.name,
                "name" to category.displayName,
                "description" to category.description
            )
        }
        return ResponseEntity.ok(categories)
    }

    /**
     * 공지사항 중요도 목록 조회
     */
    @GetMapping("/priorities")
    fun getPriorities(): ResponseEntity<List<Map<String, Any>>> {
        val priorities = NoticePriority.values().map { priority ->
            mapOf(
                "code" to priority.name,
                "name" to priority.displayName,
                "level" to priority.level,
                "color" to priority.color
            )
        }
        return ResponseEntity.ok(priorities)
    }

    /**
     * 긴급 공지사항 조회
     */
    @GetMapping("/urgent")
    fun getUrgentNotices(): ResponseEntity<List<NoticeListResponse>> {
        val response = noticeService.getUrgentNotices()
        return ResponseEntity.ok(response)
    }

    /**
     * 최근 공지사항 조회
     */
    @GetMapping("/recent")
    fun getRecentNotices(
        @RequestParam(defaultValue = "5") limit: Int
    ): ResponseEntity<List<NoticeListResponse>> {
        val response = noticeService.getRecentNotices(limit)
        return ResponseEntity.ok(response)
    }

    /**
     * 공지사항 발행 (관리자)
     */
    @PostMapping("/{id}/publish")
    fun publishNotice(
        @PathVariable id: UUID,
        @RequestBody request: NoticePublishRequest
    ): ResponseEntity<NoticePublishResponse> {
        val response = noticeService.publishNotice(id, request)
        return ResponseEntity.ok(response)
    }

    /**
     * 첨부파일 업로드 (관리자)
     */
    @PostMapping("/{id}/attachments")
    fun uploadAttachment(
        @PathVariable id: UUID,
        @RequestParam("file") file: MultipartFile
    ): ResponseEntity<NoticeAttachmentUploadResponse> {
        if (file.isEmpty) {
            return ResponseEntity.badRequest().build()
        }

        val response = noticeService.uploadAttachment(id, file)
        return ResponseEntity.status(HttpStatus.CREATED).body(response)
    }

    /**
     * 첨부파일 다운로드
     */
    @GetMapping("/attachments/{attachmentId}/download")
    fun downloadAttachment(@PathVariable attachmentId: UUID): ResponseEntity<String> {
        // 실제 구현에서는 파일 다운로드 로직 구현
        // 여기서는 다운로드 URL 반환
        val downloadUrl = "/files/attachments/$attachmentId"
        return ResponseEntity.ok(downloadUrl)
    }

    /**
     * 공지사항 통계 조회 (관리자)
     */
    @GetMapping("/stats")
    fun getNoticeStats(): ResponseEntity<NoticeStatsResponse> {
        val response = noticeService.getNoticeStats()
        return ResponseEntity.ok(response)
    }

    /**
     * 분류별 공지사항 조회
     */
    @GetMapping("/category/{category}")
    fun getNoticesByCategory(
        @PathVariable category: NoticeCategory,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NoticePageResponse> {
        val pageable = PageRequest.of(page, size)
        val response = noticeService.getNoticesByCategory(category, pageable)
        return ResponseEntity.ok(response)
    }

    /**
     * 중요도별 공지사항 조회
     */
    @GetMapping("/priority/{priority}")
    fun getNoticesByPriority(
        @PathVariable priority: NoticePriority,
        @RequestParam(defaultValue = "0") page: Int,
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<NoticePageResponse> {
        val pageable = PageRequest.of(page, size)
        // 우선순위별 조회는 검색 기능을 활용
        val request = NoticeSearchRequest(
            priority = priority,
            page = page,
            size = size
        )
        val response = noticeService.searchNotices(request)
        return ResponseEntity.ok(response)
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