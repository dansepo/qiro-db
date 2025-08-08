package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 지출 첨부파일 엔티티
 * 지출과 관련된 영수증, 송장 등의 첨부파일을 관리
 */
@Entity
@Table(name = "expense_attachments", schema = "bms")
data class ExpenseAttachment(
    @Id
    @Column(name = "attachment_id")
    val attachmentId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "expense_record_id", nullable = false)
    val expenseRecord: ExpenseRecord,

    @Column(name = "file_name", nullable = false, length = 255)
    val fileName: String,

    @Column(name = "file_path", nullable = false, length = 500)
    val filePath: String,

    @Column(name = "file_size", nullable = false)
    val fileSize: Long,

    @Column(name = "file_type", nullable = false, length = 50)
    val fileType: String,

    @Column(name = "mime_type", length = 100)
    val mimeType: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "attachment_type", nullable = false, length = 50)
    val attachmentType: AttachmentType,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "uploaded_by", nullable = false)
    val uploadedBy: UUID,

    @CreationTimestamp
    @Column(name = "uploaded_at", nullable = false, updatable = false)
    val uploadedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 첨부파일 유형
     */
    enum class AttachmentType(val displayName: String) {
        INVOICE("송장"),
        RECEIPT("영수증"),
        CONTRACT("계약서"),
        ESTIMATE("견적서"),
        OTHER("기타")
    }

    /**
     * 파일 크기를 MB 단위로 반환
     */
    fun getFileSizeInMB(): Double {
        return fileSize / (1024.0 * 1024.0)
    }

    /**
     * 이미지 파일 여부 확인
     */
    fun isImageFile(): Boolean {
        return mimeType?.startsWith("image/") == true
    }

    /**
     * PDF 파일 여부 확인
     */
    fun isPdfFile(): Boolean {
        return mimeType == "application/pdf"
    }
}