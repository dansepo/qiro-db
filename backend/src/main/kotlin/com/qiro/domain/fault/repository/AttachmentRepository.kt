package com.qiro.domain.fault.repository

import com.qiro.domain.fault.entity.Attachment
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 첨부파일 Repository
 */
@Repository
interface AttachmentRepository : JpaRepository<Attachment, UUID> {

    /**
     * 엔티티별 첨부파일 조회 (활성화된 것만)
     */
    fun findByEntityIdAndEntityTypeAndIsActiveTrueOrderByCreatedAtDesc(
        entityId: UUID, 
        entityType: EntityType
    ): List<Attachment>

    /**
     * 엔티티별 분류별 첨부파일 조회
     */
    fun findByEntityIdAndEntityTypeAndAttachmentCategoryAndIsActiveTrueOrderByCreatedAtDesc(
        entityId: UUID, 
        entityType: EntityType, 
        attachmentCategory: AttachmentCategory
    ): List<Attachment>

    /**
     * 업로더별 첨부파일 조회
     */
    fun findByUploadedByAndIsActiveTrueOrderByCreatedAtDesc(uploadedBy: UUID): List<Attachment>

    /**
     * 파일 유형별 첨부파일 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.fileType LIKE :fileTypePattern 
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun findByFileTypePattern(@Param("fileTypePattern") fileTypePattern: String): List<Attachment>

    /**
     * 이미지 파일만 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.entityId = :entityId 
        AND a.entityType = :entityType
        AND a.fileType LIKE 'image/%'
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun findImagesByEntity(
        @Param("entityId") entityId: UUID,
        @Param("entityType") entityType: EntityType
    ): List<Attachment>

    /**
     * 비디오 파일만 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.entityId = :entityId 
        AND a.entityType = :entityType
        AND a.fileType LIKE 'video/%'
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun findVideosByEntity(
        @Param("entityId") entityId: UUID,
        @Param("entityType") entityType: EntityType
    ): List<Attachment>

    /**
     * 문서 파일만 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.entityId = :entityId 
        AND a.entityType = :entityType
        AND (a.fileType LIKE 'application/%' OR a.fileType LIKE 'text/%')
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun findDocumentsByEntity(
        @Param("entityId") entityId: UUID,
        @Param("entityType") entityType: EntityType
    ): List<Attachment>

    /**
     * 공개 첨부파일 조회
     */
    fun findByEntityIdAndEntityTypeAndIsPublicTrueAndIsActiveTrueOrderByCreatedAtDesc(
        entityId: UUID, 
        entityType: EntityType
    ): List<Attachment>

    /**
     * 파일 크기별 조회 (특정 크기 이상)
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.fileSize >= :minSize 
        AND a.isActive = true
        ORDER BY a.fileSize DESC
    """)
    fun findByFileSizeGreaterThanEqual(@Param("minSize") minSize: Long): List<Attachment>

    /**
     * 기간별 첨부파일 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.createdAt BETWEEN :startDate AND :endDate
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun findByCreatedAtBetween(
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Attachment>

    /**
     * 파일명으로 검색
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE LOWER(a.fileName) LIKE LOWER(CONCAT('%', :keyword, '%'))
        AND a.isActive = true
        ORDER BY a.createdAt DESC
    """)
    fun searchByFileName(@Param("keyword") keyword: String): List<Attachment>

    /**
     * 썸네일이 있는 첨부파일 조회
     */
    fun findByEntityIdAndEntityTypeAndThumbnailPathIsNotNullAndIsActiveTrueOrderByCreatedAtDesc(
        entityId: UUID, 
        entityType: EntityType
    ): List<Attachment>

    /**
     * 분류별 첨부파일 개수 조회
     */
    @Query("""
        SELECT a.attachmentCategory, COUNT(a) 
        FROM Attachment a 
        WHERE a.entityId = :entityId 
        AND a.entityType = :entityType
        AND a.isActive = true
        GROUP BY a.attachmentCategory
    """)
    fun countByEntityAndCategory(
        @Param("entityId") entityId: UUID,
        @Param("entityType") entityType: EntityType
    ): List<Array<Any>>

    /**
     * 총 파일 크기 계산
     */
    @Query("""
        SELECT COALESCE(SUM(a.fileSize), 0) 
        FROM Attachment a 
        WHERE a.entityId = :entityId 
        AND a.entityType = :entityType
        AND a.isActive = true
    """)
    fun calculateTotalFileSize(
        @Param("entityId") entityId: UUID,
        @Param("entityType") entityType: EntityType
    ): Long

    /**
     * 업로더별 파일 개수 통계
     */
    @Query("""
        SELECT a.uploadedBy, COUNT(a) 
        FROM Attachment a 
        WHERE a.createdAt BETWEEN :startDate AND :endDate
        AND a.isActive = true
        GROUP BY a.uploadedBy
        ORDER BY COUNT(a) DESC
    """)
    fun countByUploaderAndDateRange(
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 파일 유형별 통계
     */
    @Query("""
        SELECT 
            CASE 
                WHEN a.fileType LIKE 'image/%' THEN 'IMAGE'
                WHEN a.fileType LIKE 'video/%' THEN 'VIDEO'
                WHEN a.fileType LIKE 'application/%' OR a.fileType LIKE 'text/%' THEN 'DOCUMENT'
                ELSE 'OTHER'
            END as fileCategory,
            COUNT(a) as count,
            SUM(a.fileSize) as totalSize
        FROM Attachment a 
        WHERE a.createdAt BETWEEN :startDate AND :endDate
        AND a.isActive = true
        GROUP BY fileCategory
        ORDER BY count DESC
    """)
    fun getFileTypeStatistics(
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Array<Any>>

    /**
     * 고아 첨부파일 조회 (연결된 엔티티가 없는 파일)
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.entityType = 'FAULT_REPORT'
        AND NOT EXISTS (
            SELECT 1 FROM FaultReport fr WHERE fr.id = a.entityId
        )
        AND a.isActive = true
    """)
    fun findOrphanedFaultReportAttachments(): List<Attachment>

    /**
     * 오래된 비활성 첨부파일 조회
     */
    @Query("""
        SELECT a FROM Attachment a 
        WHERE a.isActive = false 
        AND a.updatedAt < :cutoffDate
        ORDER BY a.updatedAt ASC
    """)
    fun findOldInactiveAttachments(@Param("cutoffDate") cutoffDate: LocalDateTime): List<Attachment>
}