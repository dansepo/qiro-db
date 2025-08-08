package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 세무 서류 엔티티
 * 세무 관련 서류 및 첨부파일을 관리합니다.
 */
@Entity
@Table(
    name = "tax_documents",
    schema = "bms",
    indexes = [
        Index(name = "idx_tax_documents_company", columnList = "company_id"),
        Index(name = "idx_tax_documents_type", columnList = "document_type"),
        Index(name = "idx_tax_documents_period", columnList = "related_tax_period_id")
    ]
)
data class TaxDocument(
    @Id
    @GeneratedValue
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    // 서류 정보
    @Column(name = "document_name", nullable = false, length = 200)
    val documentName: String,

    @Enumerated(EnumType.STRING)
    @Column(name = "document_type", nullable = false)
    val documentType: DocumentType,

    @Column(name = "document_category", length = 50)
    val documentCategory: String? = null,

    // 파일 정보
    @Column(name = "file_name", nullable = false, length = 255)
    val fileName: String,

    @Column(name = "file_path", nullable = false, length = 500)
    val filePath: String,

    @Column(name = "file_size")
    val fileSize: Long? = null,

    @Column(name = "file_type", length = 50)
    val fileType: String? = null,

    // 관련 정보
    @Column(name = "related_tax_period_id")
    val relatedTaxPeriodId: UUID? = null,

    @Column(name = "related_vat_return_id")
    val relatedVatReturnId: Long? = null,

    @Column(name = "related_withholding_id")
    val relatedWithholdingId: UUID? = null,

    @Column(name = "related_tax_invoice_id")
    val relatedTaxInvoiceId: UUID? = null,

    // 보관 정보
    @Column(name = "retention_period")
    val retentionPeriod: Int = 5, // 보관 연수

    @Column(name = "expiry_date")
    val expiryDate: LocalDate? = null,

    // 메타데이터
    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "tags", length = 500)
    val tags: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by")
    val createdBy: UUID? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 서류 유형
     */
    enum class DocumentType {
        VAT_RETURN,         // 부가세신고서
        WITHHOLDING_REPORT, // 원천징수신고서
        TAX_INVOICE,        // 세금계산서
        RECEIPT,            // 영수증
        CONTRACT,           // 계약서
        OTHER               // 기타
    }

    /**
     * 보관 기간 만료 여부 확인
     */
    fun isExpired(): Boolean {
        return expiryDate?.isBefore(LocalDate.now()) ?: false
    }

    /**
     * 보관 기간 만료일 계산
     */
    fun calculateExpiryDate(): LocalDate {
        return createdAt.toLocalDate().plusYears(retentionPeriod.toLong())
    }

    /**
     * 파일 확장자 추출
     */
    fun getFileExtension(): String? {
        return fileName.substringAfterLast('.', "").takeIf { it.isNotEmpty() }
    }

    /**
     * 파일 크기를 읽기 쉬운 형태로 변환
     */
    fun getFormattedFileSize(): String {
        return fileSize?.let { size ->
            when {
                size < 1024 -> "$size B"
                size < 1024 * 1024 -> "${size / 1024} KB"
                size < 1024 * 1024 * 1024 -> "${size / (1024 * 1024)} MB"
                else -> "${size / (1024 * 1024 * 1024)} GB"
            }
        } ?: "Unknown"
    }

    /**
     * 태그 목록 반환
     */
    fun getTagList(): List<String> {
        return tags?.split(",")?.map { it.trim() }?.filter { it.isNotEmpty() } ?: emptyList()
    }

    /**
     * 태그 추가
     */
    fun addTag(tag: String): TaxDocument {
        val currentTags = getTagList().toMutableList()
        if (!currentTags.contains(tag)) {
            currentTags.add(tag)
            return this.copy(tags = currentTags.joinToString(", "))
        }
        return this
    }

    /**
     * 태그 제거
     */
    fun removeTag(tag: String): TaxDocument {
        val currentTags = getTagList().toMutableList()
        currentTags.remove(tag)
        return this.copy(tags = currentTags.joinToString(", "))
    }
}