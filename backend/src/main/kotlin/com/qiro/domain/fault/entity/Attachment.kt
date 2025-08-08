package com.qiro.domain.fault.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.util.*

/**
 * 첨부파일 엔티티
 * 고장 신고 관련 파일 첨부 관리
 */
@Entity
@Table(name = "attachments", schema = "bms")
data class Attachment(
    @Id
    @Column(name = "attachment_id")
    val id: UUID = UUID.randomUUID(),

    /**
     * 연결된 엔티티 ID (고장 신고 ID 등)
     */
    @Column(name = "entity_id", nullable = false)
    val entityId: UUID,

    /**
     * 엔티티 유형 (FAULT_REPORT, WORK_ORDER 등)
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "entity_type", nullable = false)
    val entityType: EntityType,

    /**
     * 원본 파일명
     */
    @Column(name = "file_name", nullable = false, length = 255)
    val fileName: String,

    /**
     * 저장된 파일 경로
     */
    @Column(name = "file_path", nullable = false, length = 500)
    val filePath: String,

    /**
     * 파일 유형 (MIME Type)
     */
    @Column(name = "file_type", nullable = false, length = 100)
    val fileType: String,

    /**
     * 파일 크기 (바이트)
     */
    @Column(name = "file_size", nullable = false)
    val fileSize: Long,

    /**
     * 첨부파일 분류
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "attachment_category", nullable = false)
    val attachmentCategory: AttachmentCategory = AttachmentCategory.GENERAL,

    /**
     * 설명
     */
    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    /**
     * 썸네일 경로 (이미지인 경우)
     */
    @Column(name = "thumbnail_path", length = 500)
    val thumbnailPath: String? = null,

    /**
     * 업로드한 사용자 ID
     */
    @Column(name = "uploaded_by", nullable = false)
    val uploadedBy: UUID,

    /**
     * 공개 여부
     */
    @Column(name = "is_public", nullable = false)
    val isPublic: Boolean = false,

    /**
     * 활성 상태
     */
    @Column(name = "is_active", nullable = false)
    val isActive: Boolean = true

) : BaseEntity() {

    /**
     * 이미지 파일 여부 확인
     */
    fun isImage(): Boolean {
        return fileType.startsWith("image/")
    }

    /**
     * 비디오 파일 여부 확인
     */
    fun isVideo(): Boolean {
        return fileType.startsWith("video/")
    }

    /**
     * 문서 파일 여부 확인
     */
    fun isDocument(): Boolean {
        return fileType.startsWith("application/") || fileType.startsWith("text/")
    }

    /**
     * 파일 크기를 MB 단위로 반환
     */
    fun getFileSizeInMB(): Double {
        return fileSize.toDouble() / (1024 * 1024)
    }

    /**
     * 파일 확장자 반환
     */
    fun getFileExtension(): String {
        return fileName.substringAfterLast('.', "")
    }

    /**
     * 첨부파일 비활성화
     */
    fun deactivate(): Attachment = this.copy(isActive = false)

    /**
     * 공개 설정 변경
     */
    fun updatePublicStatus(isPublic: Boolean): Attachment = this.copy(isPublic = isPublic)
}

/**
 * 엔티티 유형
 */
enum class EntityType(val description: String) {
    FAULT_REPORT("고장신고"),
    WORK_ORDER("작업지시서"),
    MAINTENANCE("정비"),
    INSPECTION("점검"),
    FEEDBACK("피드백")
}

/**
 * 첨부파일 분류
 */
enum class AttachmentCategory(val description: String) {
    INITIAL_PHOTO("초기사진"),
    PROGRESS_PHOTO("진행사진"),
    COMPLETION_PHOTO("완료사진"),
    DOCUMENT("문서"),
    VIDEO("동영상"),
    AUDIO("음성"),
    GENERAL("일반")
}