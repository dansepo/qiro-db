package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import com.qiro.domain.fault.entity.Attachment
import com.qiro.domain.fault.entity.EntityType
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import org.springframework.mock.web.MockMultipartFile
import java.util.*

/**
 * 파일 보안 서비스 테스트
 */
class FileSecurityServiceTest : BehaviorSpec({

    val fileStorageConfig = mockk<FileStorageConfig> {
        every { maxFileSize } returns 10 * 1024 * 1024L // 10MB
        every { isAllowedFileType(any()) } returns true
        every { isDangerousExtension(any()) } returns false
    }
    
    val fileSecurityService = FileSecurityService(fileStorageConfig)

    Given("유효한 이미지 파일이 주어졌을 때") {
        val validImageFile = MockMultipartFile(
            "file",
            "test-image.jpg",
            "image/jpeg",
            "valid image content".toByteArray()
        )

        When("파일 보안 검사를 수행하면") {
            val result = fileSecurityService.validateFileSecurity(validImageFile)

            Then("보안 검사를 통과한다") {
                result.isValid shouldBe true
                result.errors shouldBe emptyList()
                result.fileHash shouldNotBe null
            }
        }
    }

    Given("크기가 너무 큰 파일이 주어졌을 때") {
        val largeFile = MockMultipartFile(
            "file",
            "large-file.jpg",
            "image/jpeg",
            ByteArray(15 * 1024 * 1024) // 15MB
        )

        every { fileStorageConfig.maxFileSize } returns 10 * 1024 * 1024L

        When("파일 보안 검사를 수행하면") {
            val result = fileSecurityService.validateFileSecurity(largeFile)

            Then("파일 크기 오류로 검사에 실패한다") {
                result.isValid shouldBe false
                result.errors.any { it.contains("파일 크기가 너무 큽니다") } shouldBe true
            }
        }
    }

    Given("위험한 확장자를 가진 파일이 주어졌을 때") {
        val dangerousFile = MockMultipartFile(
            "file",
            "malicious.exe",
            "application/octet-stream",
            "malicious content".toByteArray()
        )

        every { fileStorageConfig.isDangerousExtension("exe") } returns true

        When("파일 보안 검사를 수행하면") {
            val result = fileSecurityService.validateFileSecurity(dangerousFile)

            Then("위험한 파일 유형 오류로 검사에 실패한다") {
                result.isValid shouldBe false
                result.errors.any { it.contains("보안상 업로드할 수 없는 파일 유형입니다") } shouldBe true
            }
        }
    }

    Given("파일명에 특수 문자가 포함된 파일이 주어졌을 때") {
        val fileWithSpecialChars = MockMultipartFile(
            "file",
            "test<>file.jpg",
            "image/jpeg",
            "content".toByteArray()
        )

        When("파일 보안 검사를 수행하면") {
            val result = fileSecurityService.validateFileSecurity(fileWithSpecialChars)

            Then("특수 문자 오류로 검사에 실패한다") {
                result.isValid shouldBe false
                result.errors.any { it.contains("허용되지 않는 문자가 포함되어 있습니다") } shouldBe true
            }
        }
    }

    Given("안전한 파일명 생성이 필요할 때") {
        val originalFileName = "테스트 파일<>이름.jpg"

        When("안전한 파일명을 생성하면") {
            val secureFileName = fileSecurityService.generateSecureFileName(originalFileName)

            Then("특수 문자가 제거되고 고유 ID가 추가된다") {
                secureFileName shouldNotBe originalFileName
                secureFileName.contains("<") shouldBe false
                secureFileName.contains(">") shouldBe false
                secureFileName.endsWith(".jpg") shouldBe true
                secureFileName.contains("_") shouldBe true // 고유 ID 구분자
            }
        }
    }

    Given("첨부파일과 사용자 정보가 주어졌을 때") {
        val userId = UUID.randomUUID()
        val uploaderId = UUID.randomUUID()
        
        val publicAttachment = mockk<Attachment> {
            every { isActive } returns true
            every { isPublic } returns true
            every { uploadedBy } returns uploaderId
            every { entityType } returns EntityType.FAULT_REPORT
        }

        When("공개 파일에 접근하면") {
            val result = fileSecurityService.checkFileAccess(publicAttachment, userId, setOf("USER"))

            Then("접근이 허용된다") {
                result.hasAccess shouldBe true
                result.reason shouldBe "공개 파일입니다."
            }
        }
    }

    Given("업로더 본인이 파일에 접근할 때") {
        val userId = UUID.randomUUID()
        
        val userAttachment = mockk<Attachment> {
            every { isActive } returns true
            every { isPublic } returns false
            every { uploadedBy } returns userId
            every { entityType } returns EntityType.FAULT_REPORT
        }

        When("본인의 파일에 접근하면") {
            val result = fileSecurityService.checkFileAccess(userAttachment, userId, setOf("USER"))

            Then("접근이 허용된다") {
                result.hasAccess shouldBe true
                result.reason shouldBe "업로더 본인입니다."
            }
        }
    }

    Given("관리자가 파일에 접근할 때") {
        val adminId = UUID.randomUUID()
        val uploaderId = UUID.randomUUID()
        
        val privateAttachment = mockk<Attachment> {
            every { isActive } returns true
            every { isPublic } returns false
            every { uploadedBy } returns uploaderId
            every { entityType } returns EntityType.FAULT_REPORT
        }

        When("관리자 권한으로 접근하면") {
            val result = fileSecurityService.checkFileAccess(privateAttachment, adminId, setOf("ADMIN"))

            Then("접근이 허용된다") {
                result.hasAccess shouldBe true
                result.reason shouldBe "관리자 권한입니다."
            }
        }
    }

    Given("권한이 없는 사용자가 비공개 파일에 접근할 때") {
        val userId = UUID.randomUUID()
        val uploaderId = UUID.randomUUID()
        
        val privateAttachment = mockk<Attachment> {
            every { isActive } returns true
            every { isPublic } returns false
            every { uploadedBy } returns uploaderId
            every { entityType } returns EntityType.FAULT_REPORT
        }

        When("권한 없는 사용자가 접근하면") {
            val result = fileSecurityService.checkFileAccess(privateAttachment, userId, setOf("USER"))

            Then("접근이 거부된다") {
                result.hasAccess shouldBe false
                result.reason shouldBe "파일에 접근할 권한이 없습니다."
            }
        }
    }

    Given("파일 해시 계산이 필요할 때") {
        val testFile = MockMultipartFile(
            "file",
            "test.txt",
            "text/plain",
            "test content".toByteArray()
        )

        When("파일 해시를 계산하면") {
            val hash1 = fileSecurityService.calculateFileHash(testFile)
            val hash2 = fileSecurityService.calculateFileHash(testFile)

            Then("동일한 파일에 대해 동일한 해시가 생성된다") {
                hash1 shouldNotBe ""
                hash1 shouldBe hash2
                hash1.length shouldBe 64 // SHA-256 해시 길이
            }
        }
    }
})