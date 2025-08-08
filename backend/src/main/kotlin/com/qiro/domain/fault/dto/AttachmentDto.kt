package com.qiro.domain.fault.dto

import com.qiro.domain.fault.entity.Attachment
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import java.time.LocalDateTime
import java.util.*

/**
 * 첨부파일 DTO
 */
data class AttachmentDto(
    val id: UUID,
    val entityId: UUID,
    val entityType: EntityType,
    val fileName: String,
    val filePath: String,
    val fileType: String,
    val fileSize: Long,
    val attachmentCategory: AttachmentCategory,
    val description: String? = null,
    val thumbnailPath: String? = null,
    val uploadedBy: UUID,
    val isPublic: Boolean,
    val isActive: Boolean,
    val createdAt: LocalDateTime? = null,
    val updatedAt: LocalDateTime? = null,
    
    // 추가 정보
    val uploaderName: String? = null,
    val fileSizeInMB: Double? = null,
    val fileExtension: String? = null
) {
    companion object {
        /**
         * Entity를 DTO로 변환
         */
        fun from(entity: Attachment): AttachmentDto {
            return AttachmentDto(
                id = entity.id,
                entityId = entity.entityId,
                entityType = entity.entityType,
                fileName = entity.fileName,
                filePath = entity.filePath,
                fileType = entity.fileType,
                fileSize = entity.fileSize,
                attachmentCategory = entity.attachmentCategory,
                description = entity.description,
                thumbnailPath = entity.thumbnailPath,
                uploadedBy = entity.uploadedBy,
                isPublic = entity.isPublic,
                isActive = entity.isActive,
                createdAt = entity.createdAt,
                updatedAt = entity.updatedAt,
                fileSizeInMB = entity.getFileSizeInMB(),
                fileExtension = entity.getFileExtension()
            )
        }
    }

    /**
     * 이미지 파일 여부
     */
    fun isImage(): Boolean = fileType.startsWith("image/")

    /**
     * 비디오 파일 여부
     */
    fun isVideo(): Boolean = fileType.startsWith("video/")

    /**
     * 문서 파일 여부
     */
    fun isDocument(): Boolean = fileType.startsWith("application/") || fileType.startsWith("text/")
}

/**
 * 첨부파일 업로드 요청 DTO
 */
data class UploadAttachmentRequest(
    val entityId: UUID,
    val entityType: EntityType,
    val attachmentCategory: AttachmentCategory = AttachmentCategory.GENERAL,
    val description: String? = null,
    val isPublic: Boolean = false
)

/**
 * 첨부파일 업데이트 요청 DTO
 */
data class UpdateAttachmentRequest(
    val description: String? = null,
    val attachmentCategory: AttachmentCategory? = null,
    val isPublic: Boolean? = null
)