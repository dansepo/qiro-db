package com.qiro.domain.accounting.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.util.*

/**
 * 거래 첨부파일 엔티티
 * 거래와 관련된 영수증, 증빙서류 등을 관리합니다.
 */
@Entity
@Table(
    name = "transaction_attachments",
    indexes = [
        Index(name = "idx_transaction_attachments_transaction", columnList = "transaction_id"),
        Index(name = "idx_transaction_attachments_type", columnList = "file_type")
    ]
)
class TransactionAttachment(
    @Id
    @Column(name = "attachment_id")
    val attachmentId: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transaction_id", nullable = false)
    var transaction: Transaction? = null,

    @Column(name = "original_filename", nullable = false)
    val originalFilename: String,

    @Column(name = "stored_filename", nullable = false)
    val storedFilename: String,

    @Column(name = "file_path", nullable = false)
    val filePath: String,

    @Column(name = "file_size", nullable = false)
    val fileSize: Long,

    @Column(name = "content_type", nullable = false, length = 100)
    val contentType: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "file_type", nullable = false, length = 20)
    val fileType: AttachmentType,

    @Column(name = "description")
    val description: String? = null,

    @Column(name = "ocr_extracted_data", columnDefinition = "JSONB")
    var ocrExtractedData: String? = null,

    @Column(name = "is_ocr_processed", nullable = false)
    var isOcrProcessed: Boolean = false
) : BaseEntity() {

    /**
     * OCR 처리 완료 표시
     */
    fun markOcrProcessed(extractedData: String) {
        this.ocrExtractedData = extractedData
        this.isOcrProcessed = true
    }

    /**
     * 파일 확장자 반환
     */
    fun getFileExtension(): String {
        return originalFilename.substringAfterLast('.', "")
    }

    /**
     * 이미지 파일인지 확인
     */
    fun isImageFile(): Boolean {
        val imageTypes = setOf("image/jpeg", "image/png", "image/gif", "image/bmp", "image/webp")
        return contentType.lowercase() in imageTypes
    }

    /**
     * PDF 파일인지 확인
     */
    fun isPdfFile(): Boolean {
        return contentType.lowercase() == "application/pdf"
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TransactionAttachment) return false
        return attachmentId == other.attachmentId
    }

    override fun hashCode(): Int = attachmentId.hashCode()

    override fun toString(): String {
        return "TransactionAttachment(attachmentId=$attachmentId, originalFilename='$originalFilename', fileType=$fileType)"
    }
}

/**
 * 첨부파일 유형 열거형
 */
enum class AttachmentType {
    /** 영수증 */
    RECEIPT,
    /** 세금계산서 */
    TAX_INVOICE,
    /** 계산서 */
    INVOICE,
    /** 입금표 */
    DEPOSIT_SLIP,
    /** 계약서 */
    CONTRACT,
    /** 기타 증빙서류 */
    OTHER_DOCUMENT
}