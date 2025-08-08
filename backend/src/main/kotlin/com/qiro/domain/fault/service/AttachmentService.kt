package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import com.qiro.domain.fault.dto.AttachmentDto
import com.qiro.domain.fault.dto.UpdateAttachmentRequest
import com.qiro.domain.fault.dto.UploadAttachmentRequest
import com.qiro.domain.fault.entity.Attachment
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import com.qiro.domain.fault.repository.AttachmentRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.multipart.MultipartFile
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.time.LocalDateTime
import java.util.*

/**
 * 첨부파일 서비스 (개선된 버전)
 * 파일 업로드, 이미지 처리, 보안 검사, 접근 권한 관리 등을 담당
 */
@Service
@Transactional(readOnly = true)
class AttachmentService(
    private val attachmentRepository: AttachmentRepository,
    private val fileStorageConfig: FileStorageConfig,
    private val imageProcessingService: ImageProcessingService,
    private val fileSecurityService: FileSecurityService
) {

    /**
     * 파일 업로드 (개선된 버전)
     */
    @Transactional
    fun uploadFile(
        file: MultipartFile,
        request: UploadAttachmentRequest,
        uploadedBy: UUID
    ): AttachmentDto {
        // 1. 파일 보안 검사
        val securityResult = fileSecurityService.validateFileSecurity(file)
        if (!securityResult.isValid) {
            throw IllegalArgumentException("파일 보안 검사 실패: ${securityResult.errors.joinToString(", ")}")
        }

        // 2. 안전한 파일명 생성
        val originalFileName = file.originalFilename ?: "unknown"
        val secureFileName = fileSecurityService.generateSecureFileName(originalFileName)

        // 3. 파일 저장
        val savedFilePath = saveFileSecurely(file, request.entityType, request.entityId, secureFileName)

        // 4. 썸네일 생성 (이미지인 경우)
        val thumbnailPath = if (fileStorageConfig.isImageFile(file.contentType ?: "")) {
            generateThumbnailSecurely(savedFilePath, request.entityType, request.entityId, secureFileName)
        } else null

        // 5. 이미지 메타데이터 추출 (이미지인 경우)
        val imageMetadata = if (fileStorageConfig.isImageFile(file.contentType ?: "")) {
            imageProcessingService.extractImageMetadata(savedFilePath)
        } else null

        // 6. 첨부파일 엔티티 생성
        val attachment = Attachment(
            entityId = request.entityId,
            entityType = request.entityType,
            fileName = originalFileName,
            filePath = savedFilePath,
            fileType = file.contentType ?: "application/octet-stream",
            fileSize = file.size,
            attachmentCategory = request.attachmentCategory,
            description = request.description,
            thumbnailPath = thumbnailPath,
            uploadedBy = uploadedBy,
            isPublic = request.isPublic
        )

        val savedAttachment = attachmentRepository.save(attachment)
        
        // 7. 파일 무결성 검증 (비동기로 처리 가능)
        if (securityResult.fileHash != null) {
            verifyFileIntegrityAsync(savedFilePath, securityResult.fileHash)
        }

        return AttachmentDto.from(savedAttachment).copy(
            // 이미지 메타데이터 추가
            fileSizeInMB = savedAttachment.getFileSizeInMB(),
            fileExtension = savedAttachment.getFileExtension()
        )
    }

    /**
     * 첨부파일 조회
     */
    fun getAttachment(id: UUID): AttachmentDto {
        val attachment = attachmentRepository.findById(id)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $id") }

        return AttachmentDto.from(attachment)
    }

    /**
     * 엔티티별 첨부파일 조회
     */
    fun getAttachmentsByEntity(entityId: UUID, entityType: EntityType): List<AttachmentDto> {
        return attachmentRepository.findByEntityIdAndEntityTypeAndIsActiveTrueOrderByCreatedAtDesc(entityId, entityType)
            .map { AttachmentDto.from(it) }
    }

    /**
     * 엔티티별 분류별 첨부파일 조회
     */
    fun getAttachmentsByEntityAndCategory(
        entityId: UUID, 
        entityType: EntityType, 
        category: AttachmentCategory
    ): List<AttachmentDto> {
        return attachmentRepository.findByEntityIdAndEntityTypeAndAttachmentCategoryAndIsActiveTrueOrderByCreatedAtDesc(
            entityId, entityType, category
        ).map { AttachmentDto.from(it) }
    }

    /**
     * 이미지 첨부파일만 조회
     */
    fun getImagesByEntity(entityId: UUID, entityType: EntityType): List<AttachmentDto> {
        return attachmentRepository.findImagesByEntity(entityId, entityType)
            .map { AttachmentDto.from(it) }
    }

    /**
     * 비디오 첨부파일만 조회
     */
    fun getVideosByEntity(entityId: UUID, entityType: EntityType): List<AttachmentDto> {
        return attachmentRepository.findVideosByEntity(entityId, entityType)
            .map { AttachmentDto.from(it) }
    }

    /**
     * 문서 첨부파일만 조회
     */
    fun getDocumentsByEntity(entityId: UUID, entityType: EntityType): List<AttachmentDto> {
        return attachmentRepository.findDocumentsByEntity(entityId, entityType)
            .map { AttachmentDto.from(it) }
    }

    /**
     * 공개 첨부파일 조회
     */
    fun getPublicAttachments(entityId: UUID, entityType: EntityType): List<AttachmentDto> {
        return attachmentRepository.findByEntityIdAndEntityTypeAndIsPublicTrueAndIsActiveTrueOrderByCreatedAtDesc(
            entityId, entityType
        ).map { AttachmentDto.from(it) }
    }

    /**
     * 업로더별 첨부파일 조회
     */
    fun getAttachmentsByUploader(uploadedBy: UUID): List<AttachmentDto> {
        return attachmentRepository.findByUploadedByAndIsActiveTrueOrderByCreatedAtDesc(uploadedBy)
            .map { AttachmentDto.from(it) }
    }

    /**
     * 첨부파일 업데이트
     */
    @Transactional
    fun updateAttachment(id: UUID, request: UpdateAttachmentRequest): AttachmentDto {
        val attachment = attachmentRepository.findById(id)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $id") }

        val updatedAttachment = attachment.copy(
            description = request.description ?: attachment.description,
            attachmentCategory = request.attachmentCategory ?: attachment.attachmentCategory,
            isPublic = request.isPublic ?: attachment.isPublic
        )

        val savedAttachment = attachmentRepository.save(updatedAttachment)
        return AttachmentDto.from(savedAttachment)
    }

    /**
     * 첨부파일 삭제 (소프트 삭제)
     */
    @Transactional
    fun deleteAttachment(id: UUID) {
        val attachment = attachmentRepository.findById(id)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $id") }

        val deactivatedAttachment = attachment.deactivate()
        attachmentRepository.save(deactivatedAttachment)
    }

    /**
     * 첨부파일 물리적 삭제
     */
    @Transactional
    fun permanentlyDeleteAttachment(id: UUID) {
        val attachment = attachmentRepository.findById(id)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $id") }

        // 파일 시스템에서 파일 삭제
        try {
            Files.deleteIfExists(Paths.get(attachment.filePath))
            attachment.thumbnailPath?.let { Files.deleteIfExists(Paths.get(it)) }
        } catch (e: Exception) {
            // 파일 삭제 실패는 로그만 남기고 계속 진행
            println("파일 삭제 실패: ${attachment.filePath}, 오류: ${e.message}")
        }

        // 데이터베이스에서 삭제
        attachmentRepository.deleteById(id)
    }

    /**
     * 엔티티별 총 파일 크기 계산
     */
    fun calculateTotalFileSize(entityId: UUID, entityType: EntityType): Long {
        return attachmentRepository.calculateTotalFileSize(entityId, entityType)
    }

    /**
     * 분류별 첨부파일 개수 조회
     */
    fun getAttachmentCountByCategory(entityId: UUID, entityType: EntityType): Map<AttachmentCategory, Long> {
        return attachmentRepository.countByEntityAndCategory(entityId, entityType)
            .associate { 
                AttachmentCategory.valueOf(it[0].toString()) to (it[1] as Long)
            }
    }

    /**
     * 파일 접근 권한 검사
     */
    fun checkFileAccess(attachmentId: UUID, userId: UUID, userRoles: Set<String>): Boolean {
        val attachment = attachmentRepository.findById(attachmentId)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $attachmentId") }

        val accessResult = fileSecurityService.checkFileAccess(attachment, userId, userRoles)
        return accessResult.hasAccess
    }

    /**
     * 이미지 리사이징
     */
    @Transactional
    fun resizeImage(
        attachmentId: UUID,
        targetWidth: Int,
        targetHeight: Int,
        userId: UUID,
        userRoles: Set<String>
    ): AttachmentDto {
        // 권한 검사
        if (!checkFileAccess(attachmentId, userId, userRoles)) {
            throw IllegalArgumentException("파일에 접근할 권한이 없습니다.")
        }

        val attachment = attachmentRepository.findById(attachmentId)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $attachmentId") }

        // 이미지 파일인지 확인
        if (!attachment.isImage()) {
            throw IllegalArgumentException("이미지 파일이 아닙니다.")
        }

        // 리사이징된 파일 경로 생성
        val originalPath = attachment.filePath
        val resizedFileName = "resized_${targetWidth}x${targetHeight}_${attachment.fileName}"
        val resizedPath = originalPath.substringBeforeLast('/') + "/" + resizedFileName

        // 이미지 리사이징
        val resizedFilePath = imageProcessingService.resizeImage(
            originalPath, targetWidth, targetHeight, resizedPath
        ) ?: throw RuntimeException("이미지 리사이징에 실패했습니다.")

        // 새로운 첨부파일 엔티티 생성
        val resizedAttachment = attachment.copy(
            id = UUID.randomUUID(),
            fileName = resizedFileName,
            filePath = resizedFilePath,
            fileSize = File(resizedFilePath).length(),
            description = "${attachment.description ?: ""} (리사이징: ${targetWidth}x${targetHeight})",
            uploadedBy = userId
        )

        val savedAttachment = attachmentRepository.save(resizedAttachment)
        return AttachmentDto.from(savedAttachment)
    }

    /**
     * 이미지 압축
     */
    @Transactional
    fun compressImage(
        attachmentId: UUID,
        quality: Float,
        userId: UUID,
        userRoles: Set<String>
    ): AttachmentDto {
        // 권한 검사
        if (!checkFileAccess(attachmentId, userId, userRoles)) {
            throw IllegalArgumentException("파일에 접근할 권한이 없습니다.")
        }

        val attachment = attachmentRepository.findById(attachmentId)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $attachmentId") }

        // 이미지 파일인지 확인
        if (!attachment.isImage()) {
            throw IllegalArgumentException("이미지 파일이 아닙니다.")
        }

        // 압축된 파일 경로 생성
        val originalPath = attachment.filePath
        val compressedFileName = "compressed_${(quality * 100).toInt()}_${attachment.fileName}"
        val compressedPath = originalPath.substringBeforeLast('/') + "/" + compressedFileName

        // 이미지 압축
        val compressedFilePath = imageProcessingService.compressImage(
            originalPath, quality, compressedPath
        ) ?: throw RuntimeException("이미지 압축에 실패했습니다.")

        // 새로운 첨부파일 엔티티 생성
        val compressedAttachment = attachment.copy(
            id = UUID.randomUUID(),
            fileName = compressedFileName,
            filePath = compressedFilePath,
            fileSize = File(compressedFilePath).length(),
            description = "${attachment.description ?: ""} (압축: ${(quality * 100).toInt()}%)",
            uploadedBy = userId
        )

        val savedAttachment = attachmentRepository.save(compressedAttachment)
        return AttachmentDto.from(savedAttachment)
    }

    /**
     * 파일 무결성 검증
     */
    fun verifyFileIntegrity(attachmentId: UUID): Boolean {
        val attachment = attachmentRepository.findById(attachmentId)
            .orElseThrow { IllegalArgumentException("첨부파일을 찾을 수 없습니다: $attachmentId") }

        // 파일 존재 여부 확인
        val file = File(attachment.filePath)
        if (!file.exists()) {
            return false
        }

        // 파일 크기 검증
        if (file.length() != attachment.fileSize) {
            return false
        }

        // 이미지 파일인 경우 추가 검증
        if (attachment.isImage()) {
            return imageProcessingService.validateImage(attachment.filePath)
        }

        return true
    }

    /**
     * 안전한 파일 저장
     */
    private fun saveFileSecurely(
        file: MultipartFile,
        entityType: EntityType,
        entityId: UUID,
        secureFileName: String
    ): String {
        // 저장 디렉토리 생성
        val uploadPath = fileStorageConfig.getUploadPath()
            .resolve(entityType.name.lowercase())
            .resolve(entityId.toString())
        Files.createDirectories(uploadPath)

        // 파일 저장
        val filePath = uploadPath.resolve(secureFileName)
        Files.copy(file.inputStream, filePath)

        return filePath.toString()
    }

    /**
     * 안전한 썸네일 생성
     */
    private fun generateThumbnailSecurely(
        originalFilePath: String,
        entityType: EntityType,
        entityId: UUID,
        originalFileName: String
    ): String? {
        try {
            // 썸네일 저장 디렉토리 생성
            val thumbnailPath = fileStorageConfig.getThumbnailPath()
                .resolve(entityType.name.lowercase())
                .resolve(entityId.toString())
            Files.createDirectories(thumbnailPath)

            // 썸네일 파일명 생성
            val thumbnailFileName = "thumb_$originalFileName"
            val thumbnailFilePath = thumbnailPath.resolve(thumbnailFileName).toString()

            // 썸네일 생성
            return imageProcessingService.generateThumbnail(originalFilePath, thumbnailFilePath)
        } catch (e: Exception) {
            println("썸네일 생성 실패: $originalFilePath, 오류: ${e.message}")
            return null
        }
    }

    /**
     * 파일 무결성 검증 (비동기)
     */
    private fun verifyFileIntegrityAsync(filePath: String, expectedHash: String) {
        // TODO: 비동기 처리로 구현 (예: @Async 또는 별도 스레드)
        try {
            val isValid = fileSecurityService.verifyFileIntegrity(filePath, expectedHash)
            if (!isValid) {
                println("파일 무결성 검증 실패: $filePath")
                // TODO: 알림 또는 로그 처리
            }
        } catch (e: Exception) {
            println("파일 무결성 검증 오류: $filePath, 오류: ${e.message}")
        }
    }

    /**
     * 오래된 비활성 첨부파일 정리
     */
    @Transactional
    fun cleanupOldInactiveAttachments(daysOld: Int = 30) {
        val cutoffDate = LocalDateTime.now().minusDays(daysOld.toLong())
        val oldAttachments = attachmentRepository.findOldInactiveAttachments(cutoffDate)

        oldAttachments.forEach { attachment ->
            try {
                permanentlyDeleteAttachment(attachment.id)
            } catch (e: Exception) {
                println("첨부파일 정리 실패: ${attachment.id}, 오류: ${e.message}")
            }
        }
    }

    /**
     * 고아 첨부파일 정리
     */
    @Transactional
    fun cleanupOrphanedAttachments() {
        val orphanedAttachments = attachmentRepository.findOrphanedFaultReportAttachments()

        orphanedAttachments.forEach { attachment ->
            try {
                permanentlyDeleteAttachment(attachment.id)
            } catch (e: Exception) {
                println("고아 첨부파일 정리 실패: ${attachment.id}, 오류: ${e.message}")
            }
        }
    }
}