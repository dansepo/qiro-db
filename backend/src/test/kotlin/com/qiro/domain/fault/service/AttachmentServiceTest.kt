package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import com.qiro.domain.fault.dto.UploadAttachmentRequest
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import com.qiro.domain.fault.repository.AttachmentRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.mock.web.MockMultipartFile
import java.util.*

/**
 * 첨부파일 서비스 테스트
 */
class AttachmentServiceTest : BehaviorSpec({

    val attachmentRepository = mockk<AttachmentRepository>()
    val fileStorageConfig = mockk<FileStorageConfig>()
    val imageProcessingService = mockk<ImageProcessingService>()
    val fileSecurityService = mockk<FileSecurityService>()
    
    val attachmentService = AttachmentService(
        attachmentRepository,
        fileStorageConfig,
        imageProcessingService,
        fileSecurityService
    )

    Given("유효한 이미지 파일이 주어졌을 때") {
        val imageFile = MockMultipartFile(
            "file",
            "test-image.jpg",
            "image/jpeg",
            "test image content".toByteArray()
        )
        
        val entityId = UUID.randomUUID()
        val uploadedBy = UUID.randomUUID()
        
        val uploadRequest = UploadAttachmentRequest(
            entityId = entityId,
            entityType = EntityType.FAULT_REPORT,
            attachmentCategory = AttachmentCategory.INITIAL_PHOTO,
            description = "테스트 이미지",
            isPublic = false
        )

        every { fileSecurityService.validateFileSecurity(any()) } returns FileSecurityResult(
            isValid = true,
            errors = emptyList(),
            fileHash = "test-hash"
        )
        every { fileSecurityService.generateSecureFileName(any()) } returns "secure-test-image.jpg"
        every { fileStorageConfig.isImageFile(any()) } returns true
        every { imageProcessingService.extractImageMetadata(any()) } returns null
        every { attachmentRepository.save(any()) } returnsArgument 0

        When("파일을 업로드하면") {
            val result = attachmentService.uploadFile(imageFile, uploadRequest, uploadedBy)

            Then("첨부파일이 성공적으로 저장된다") {
                result shouldNotBe null
                result.fileName shouldBe "test-image.jpg"
                result.fileType shouldBe "image/jpeg"
                result.entityId shouldBe entityId
                result.uploadedBy shouldBe uploadedBy
                
                verify { fileSecurityService.validateFileSecurity(imageFile) }
                verify { attachmentRepository.save(any()) }
            }
        }
    }

    Given("보안 검사에 실패한 파일이 주어졌을 때") {
        val maliciousFile = MockMultipartFile(
            "file",
            "malicious.exe",
            "application/octet-stream",
            "malicious content".toByteArray()
        )
        
        val entityId = UUID.randomUUID()
        val uploadedBy = UUID.randomUUID()
        
        val uploadRequest = UploadAttachmentRequest(
            entityId = entityId,
            entityType = EntityType.FAULT_REPORT,
            attachmentCategory = AttachmentCategory.GENERAL,
            isPublic = false
        )

        every { fileSecurityService.validateFileSecurity(any()) } returns FileSecurityResult(
            isValid = false,
            errors = listOf("보안상 업로드할 수 없는 파일 유형입니다")
        )

        When("파일을 업로드하려고 하면") {
            Then("보안 검사 실패로 예외가 발생한다") {
                try {
                    attachmentService.uploadFile(maliciousFile, uploadRequest, uploadedBy)
                    throw AssertionError("예외가 발생해야 합니다")
                } catch (e: IllegalArgumentException) {
                    e.message shouldBe "파일 보안 검사 실패: 보안상 업로드할 수 없는 파일 유형입니다"
                }
                
                verify { fileSecurityService.validateFileSecurity(maliciousFile) }
                verify(exactly = 0) { attachmentRepository.save(any()) }
            }
        }
    }

    Given("이미지 첨부파일이 존재할 때") {
        val attachmentId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val userRoles = setOf("USER")
        
        every { attachmentService.checkFileAccess(attachmentId, userId, userRoles) } returns true
        every { attachmentRepository.findById(attachmentId) } returns Optional.of(
            mockk {
                every { isImage() } returns true
                every { filePath } returns "/test/path/image.jpg"
                every { fileName } returns "image.jpg"
                every { copy(any(), any(), any(), any(), any(), any()) } returnsArgument 0
            }
        )
        every { imageProcessingService.resizeImage(any(), any(), any(), any()) } returns "/test/path/resized_image.jpg"
        every { attachmentRepository.save(any()) } returnsArgument 0

        When("이미지를 리사이징하면") {
            val result = attachmentService.resizeImage(attachmentId, 300, 200, userId, userRoles)

            Then("리사이징된 이미지가 생성된다") {
                result shouldNotBe null
                
                verify { imageProcessingService.resizeImage(any(), 300, 200, any()) }
                verify { attachmentRepository.save(any()) }
            }
        }
    }
})