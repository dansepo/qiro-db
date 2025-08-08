package com.qiro.domain.fault.controller

import com.qiro.common.response.ApiResponse
import com.qiro.domain.fault.dto.AttachmentDto
import com.qiro.domain.fault.dto.UpdateAttachmentRequest
import com.qiro.domain.fault.dto.UploadAttachmentRequest
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import com.qiro.domain.fault.service.AttachmentService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.web.bind.annotation.*
import org.springframework.web.multipart.MultipartFile
import java.util.*
import jakarta.validation.Valid

/**
 * 첨부파일 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/attachments")
@Tag(name = "첨부파일", description = "첨부파일 관리 API")
class AttachmentController(
    private val attachmentService: AttachmentService
) {

    /**
     * 파일 업로드
     */
    @PostMapping(consumes = [MediaType.MULTIPART_FORM_DATA_VALUE])
    @Operation(summary = "파일 업로드", description = "새로운 파일을 업로드합니다.")
    fun uploadFile(
        @Parameter(description = "업로드할 파일") @RequestPart("file") file: MultipartFile,
        @Parameter(description = "연결된 엔티티 ID") @RequestParam entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String,
        @Parameter(description = "첨부파일 분류") @RequestParam(required = false, defaultValue = "GENERAL") attachmentCategory: String,
        @Parameter(description = "설명") @RequestParam(required = false) description: String?,
        @Parameter(description = "공개 여부") @RequestParam(required = false, defaultValue = "false") isPublic: Boolean,
        @Parameter(description = "업로드한 사용자 ID") @RequestParam uploadedBy: UUID
    ): ApiResponse<AttachmentDto> {
        val request = UploadAttachmentRequest(
            entityId = entityId,
            entityType = EntityType.valueOf(entityType),
            attachmentCategory = AttachmentCategory.valueOf(attachmentCategory),
            description = description,
            isPublic = isPublic
        )

        val attachment = attachmentService.uploadFile(file, request, uploadedBy)
        return ApiResponse.success(attachment, "파일이 성공적으로 업로드되었습니다.")
    }

    /**
     * 첨부파일 조회
     */
    @GetMapping("/{id}")
    @Operation(summary = "첨부파일 조회", description = "첨부파일 상세 정보를 조회합니다.")
    fun getAttachment(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID
    ): ApiResponse<AttachmentDto> {
        val attachment = attachmentService.getAttachment(id)
        return ApiResponse.success(attachment)
    }

    /**
     * 엔티티별 첨부파일 조회
     */
    @GetMapping("/entity/{entityId}")
    @Operation(summary = "엔티티별 첨부파일 조회", description = "특정 엔티티의 첨부파일을 조회합니다.")
    fun getAttachmentsByEntity(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<List<AttachmentDto>> {
        val attachments = attachmentService.getAttachmentsByEntity(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(attachments)
    }

    /**
     * 엔티티별 분류별 첨부파일 조회
     */
    @GetMapping("/entity/{entityId}/category/{category}")
    @Operation(summary = "엔티티별 분류별 첨부파일 조회", description = "특정 엔티티의 특정 분류 첨부파일을 조회합니다.")
    fun getAttachmentsByEntityAndCategory(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String,
        @Parameter(description = "첨부파일 분류") @PathVariable category: String
    ): ApiResponse<List<AttachmentDto>> {
        val attachments = attachmentService.getAttachmentsByEntityAndCategory(
            entityId, 
            EntityType.valueOf(entityType), 
            AttachmentCategory.valueOf(category)
        )
        return ApiResponse.success(attachments)
    }

    /**
     * 이미지 첨부파일만 조회
     */
    @GetMapping("/entity/{entityId}/images")
    @Operation(summary = "이미지 첨부파일 조회", description = "특정 엔티티의 이미지 첨부파일만 조회합니다.")
    fun getImagesByEntity(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<List<AttachmentDto>> {
        val images = attachmentService.getImagesByEntity(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(images)
    }

    /**
     * 비디오 첨부파일만 조회
     */
    @GetMapping("/entity/{entityId}/videos")
    @Operation(summary = "비디오 첨부파일 조회", description = "특정 엔티티의 비디오 첨부파일만 조회합니다.")
    fun getVideosByEntity(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<List<AttachmentDto>> {
        val videos = attachmentService.getVideosByEntity(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(videos)
    }

    /**
     * 문서 첨부파일만 조회
     */
    @GetMapping("/entity/{entityId}/documents")
    @Operation(summary = "문서 첨부파일 조회", description = "특정 엔티티의 문서 첨부파일만 조회합니다.")
    fun getDocumentsByEntity(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<List<AttachmentDto>> {
        val documents = attachmentService.getDocumentsByEntity(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(documents)
    }

    /**
     * 공개 첨부파일 조회
     */
    @GetMapping("/entity/{entityId}/public")
    @Operation(summary = "공개 첨부파일 조회", description = "특정 엔티티의 공개 첨부파일을 조회합니다.")
    fun getPublicAttachments(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<List<AttachmentDto>> {
        val publicAttachments = attachmentService.getPublicAttachments(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(publicAttachments)
    }

    /**
     * 업로더별 첨부파일 조회
     */
    @GetMapping("/uploader/{uploadedBy}")
    @Operation(summary = "업로더별 첨부파일 조회", description = "특정 사용자가 업로드한 첨부파일을 조회합니다.")
    fun getAttachmentsByUploader(
        @Parameter(description = "업로더 ID") @PathVariable uploadedBy: UUID
    ): ApiResponse<List<AttachmentDto>> {
        val attachments = attachmentService.getAttachmentsByUploader(uploadedBy)
        return ApiResponse.success(attachments)
    }

    /**
     * 첨부파일 업데이트
     */
    @PutMapping("/{id}")
    @Operation(summary = "첨부파일 업데이트", description = "첨부파일 정보를 업데이트합니다.")
    fun updateAttachment(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID,
        @Valid @RequestBody request: UpdateAttachmentRequest
    ): ApiResponse<AttachmentDto> {
        val updatedAttachment = attachmentService.updateAttachment(id, request)
        return ApiResponse.success(updatedAttachment, "첨부파일이 성공적으로 업데이트되었습니다.")
    }

    /**
     * 엔티티별 총 파일 크기 조회
     */
    @GetMapping("/entity/{entityId}/total-size")
    @Operation(summary = "총 파일 크기 조회", description = "특정 엔티티의 총 파일 크기를 조회합니다.")
    fun getTotalFileSize(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<Long> {
        val totalSize = attachmentService.calculateTotalFileSize(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(totalSize)
    }

    /**
     * 분류별 첨부파일 개수 조회
     */
    @GetMapping("/entity/{entityId}/count-by-category")
    @Operation(summary = "분류별 개수 조회", description = "특정 엔티티의 분류별 첨부파일 개수를 조회합니다.")
    fun getAttachmentCountByCategory(
        @Parameter(description = "엔티티 ID") @PathVariable entityId: UUID,
        @Parameter(description = "엔티티 유형") @RequestParam entityType: String
    ): ApiResponse<Map<AttachmentCategory, Long>> {
        val countByCategory = attachmentService.getAttachmentCountByCategory(entityId, EntityType.valueOf(entityType))
        return ApiResponse.success(countByCategory)
    }

    /**
     * 첨부파일 삭제 (소프트 삭제)
     */
    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "첨부파일 삭제", description = "첨부파일을 삭제합니다.")
    fun deleteAttachment(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID
    ): ApiResponse<Unit> {
        attachmentService.deleteAttachment(id)
        return ApiResponse.success(message = "첨부파일이 성공적으로 삭제되었습니다.")
    }

    /**
     * 첨부파일 물리적 삭제
     */
    @DeleteMapping("/{id}/permanent")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "첨부파일 물리적 삭제", description = "첨부파일을 물리적으로 삭제합니다.")
    fun permanentlyDeleteAttachment(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID
    ): ApiResponse<Unit> {
        attachmentService.permanentlyDeleteAttachment(id)
        return ApiResponse.success(message = "첨부파일이 영구적으로 삭제되었습니다.")
    }

    /**
     * 오래된 비활성 첨부파일 정리
     */
    @DeleteMapping("/cleanup/inactive")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "비활성 첨부파일 정리", description = "오래된 비활성 첨부파일을 정리합니다.")
    fun cleanupOldInactiveAttachments(
        @Parameter(description = "정리 기준 일수") @RequestParam(defaultValue = "30") daysOld: Int
    ): ApiResponse<Unit> {
        attachmentService.cleanupOldInactiveAttachments(daysOld)
        return ApiResponse.success(message = "비활성 첨부파일이 성공적으로 정리되었습니다.")
    }

    /**
     * 고아 첨부파일 정리
     */
    @DeleteMapping("/cleanup/orphaned")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "고아 첨부파일 정리", description = "연결된 엔티티가 없는 고아 첨부파일을 정리합니다.")
    fun cleanupOrphanedAttachments(): ApiResponse<Unit> {
        attachmentService.cleanupOrphanedAttachments()
        return ApiResponse.success(message = "고아 첨부파일이 성공적으로 정리되었습니다.")
    }

    /**
     * 파일 접근 권한 검사
     */
    @GetMapping("/{id}/access-check")
    @Operation(summary = "파일 접근 권한 검사", description = "사용자의 파일 접근 권한을 확인합니다.")
    fun checkFileAccess(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID,
        @Parameter(description = "사용자 ID") @RequestParam userId: UUID,
        @Parameter(description = "사용자 역할") @RequestParam userRoles: Set<String>
    ): ApiResponse<Boolean> {
        val hasAccess = attachmentService.checkFileAccess(id, userId, userRoles)
        return ApiResponse.success(hasAccess)
    }

    /**
     * 이미지 리사이징
     */
    @PostMapping("/{id}/resize")
    @Operation(summary = "이미지 리사이징", description = "이미지를 지정된 크기로 리사이징합니다.")
    fun resizeImage(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID,
        @Parameter(description = "목표 너비") @RequestParam targetWidth: Int,
        @Parameter(description = "목표 높이") @RequestParam targetHeight: Int,
        @Parameter(description = "사용자 ID") @RequestParam userId: UUID,
        @Parameter(description = "사용자 역할") @RequestParam userRoles: Set<String>
    ): ApiResponse<AttachmentDto> {
        val resizedAttachment = attachmentService.resizeImage(id, targetWidth, targetHeight, userId, userRoles)
        return ApiResponse.success(resizedAttachment, "이미지가 성공적으로 리사이징되었습니다.")
    }

    /**
     * 이미지 압축
     */
    @PostMapping("/{id}/compress")
    @Operation(summary = "이미지 압축", description = "이미지를 지정된 품질로 압축합니다.")
    fun compressImage(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID,
        @Parameter(description = "압축 품질 (0.0 ~ 1.0)") @RequestParam quality: Float,
        @Parameter(description = "사용자 ID") @RequestParam userId: UUID,
        @Parameter(description = "사용자 역할") @RequestParam userRoles: Set<String>
    ): ApiResponse<AttachmentDto> {
        val compressedAttachment = attachmentService.compressImage(id, quality, userId, userRoles)
        return ApiResponse.success(compressedAttachment, "이미지가 성공적으로 압축되었습니다.")
    }

    /**
     * 파일 무결성 검증
     */
    @GetMapping("/{id}/verify-integrity")
    @Operation(summary = "파일 무결성 검증", description = "파일의 무결성을 검증합니다.")
    fun verifyFileIntegrity(
        @Parameter(description = "첨부파일 ID") @PathVariable id: UUID
    ): ApiResponse<Boolean> {
        val isValid = attachmentService.verifyFileIntegrity(id)
        return ApiResponse.success(isValid, if (isValid) "파일 무결성이 확인되었습니다." else "파일 무결성 검증에 실패했습니다.")
    }
}