package com.qiro.domain.fault.controller

import com.qiro.domain.fault.dto.AttachmentDto
import com.qiro.domain.fault.entity.AttachmentCategory
import com.qiro.domain.fault.entity.EntityType
import com.qiro.domain.fault.service.AttachmentService
import io.kotest.core.spec.style.BehaviorSpec
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.http.MediaType
import org.springframework.mock.web.MockMultipartFile
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import java.time.LocalDateTime
import java.util.*

/**
 * 첨부파일 컨트롤러 통합 테스트
 */
class AttachmentControllerTest : BehaviorSpec({

    val attachmentService = mockk<AttachmentService>()
    val attachmentController = AttachmentController(attachmentService)
    val mockMvc = MockMvcBuilders.standaloneSetup(attachmentController).build()

    Given("파일 업로드 요청이 주어졌을 때") {
        val testFile = MockMultipartFile(
            "file",
            "test-image.jpg",
            "image/jpeg",
            "test image content".toByteArray()
        )
        
        val entityId = UUID.randomUUID()
        val uploadedBy = UUID.randomUUID()
        
        val expectedDto = AttachmentDto(
            id = UUID.randomUUID(),
            entityId = entityId,
            entityType = EntityType.FAULT_REPORT,
            fileName = "test-image.jpg",
            filePath = "/uploads/fault_report/$entityId/secure-test-image.jpg",
            fileType = "image/jpeg",
            fileSize = testFile.size.toLong(),
            attachmentCategory = AttachmentCategory.INITIAL_PHOTO,
            description = "테스트 이미지",
            thumbnailPath = "/thumbnails/fault_report/$entityId/thumb_secure-test-image.jpg",
            uploadedBy = uploadedBy,
            isPublic = false,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now(),
            fileSizeInMB = 0.001,
            fileExtension = "jpg"
        )

        every { 
            attachmentService.uploadFile(any(), any(), any()) 
        } returns expectedDto

        When("파일 업로드 API를 호출하면") {
            val result = mockMvc.perform(
                multipart("/api/v1/attachments")
                    .file(testFile)
                    .param("entityId", entityId.toString())
                    .param("entityType", "FAULT_REPORT")
                    .param("attachmentCategory", "INITIAL_PHOTO")
                    .param("description", "테스트 이미지")
                    .param("isPublic", "false")
                    .param("uploadedBy", uploadedBy.toString())
            )

            Then("파일이 성공적으로 업로드된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.fileName").value("test-image.jpg"))
                    .andExpect(jsonPath("$.data.fileType").value("image/jpeg"))
                    .andExpect(jsonPath("$.data.entityId").value(entityId.toString()))
                    .andExpect(jsonPath("$.message").value("파일이 성공적으로 업로드되었습니다."))

                verify { attachmentService.uploadFile(any(), any(), uploadedBy) }
            }
        }
    }

    Given("첨부파일 조회 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()
        val expectedDto = AttachmentDto(
            id = attachmentId,
            entityId = UUID.randomUUID(),
            entityType = EntityType.FAULT_REPORT,
            fileName = "test-image.jpg",
            filePath = "/uploads/test-image.jpg",
            fileType = "image/jpeg",
            fileSize = 1024L,
            attachmentCategory = AttachmentCategory.INITIAL_PHOTO,
            uploadedBy = UUID.randomUUID(),
            isPublic = false,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )

        every { attachmentService.getAttachment(attachmentId) } returns expectedDto

        When("첨부파일 조회 API를 호출하면") {
            val result = mockMvc.perform(
                get("/api/v1/attachments/$attachmentId")
            )

            Then("첨부파일 정보가 반환된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.id").value(attachmentId.toString()))
                    .andExpect(jsonPath("$.data.fileName").value("test-image.jpg"))

                verify { attachmentService.getAttachment(attachmentId) }
            }
        }
    }

    Given("이미지 리사이징 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val userRoles = setOf("USER")
        
        val resizedDto = AttachmentDto(
            id = UUID.randomUUID(),
            entityId = UUID.randomUUID(),
            entityType = EntityType.FAULT_REPORT,
            fileName = "resized_300x200_test-image.jpg",
            filePath = "/uploads/resized_300x200_test-image.jpg",
            fileType = "image/jpeg",
            fileSize = 512L,
            attachmentCategory = AttachmentCategory.INITIAL_PHOTO,
            uploadedBy = userId,
            isPublic = false,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )

        every { 
            attachmentService.resizeImage(attachmentId, 300, 200, userId, userRoles) 
        } returns resizedDto

        When("이미지 리사이징 API를 호출하면") {
            val result = mockMvc.perform(
                post("/api/v1/attachments/$attachmentId/resize")
                    .param("targetWidth", "300")
                    .param("targetHeight", "200")
                    .param("userId", userId.toString())
                    .param("userRoles", "USER")
            )

            Then("리사이징된 이미지가 생성된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.fileName").value("resized_300x200_test-image.jpg"))
                    .andExpect(jsonPath("$.message").value("이미지가 성공적으로 리사이징되었습니다."))

                verify { attachmentService.resizeImage(attachmentId, 300, 200, userId, userRoles) }
            }
        }
    }

    Given("이미지 압축 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val userRoles = setOf("USER")
        val quality = 0.7f
        
        val compressedDto = AttachmentDto(
            id = UUID.randomUUID(),
            entityId = UUID.randomUUID(),
            entityType = EntityType.FAULT_REPORT,
            fileName = "compressed_70_test-image.jpg",
            filePath = "/uploads/compressed_70_test-image.jpg",
            fileType = "image/jpeg",
            fileSize = 256L,
            attachmentCategory = AttachmentCategory.INITIAL_PHOTO,
            uploadedBy = userId,
            isPublic = false,
            isActive = true,
            createdAt = LocalDateTime.now(),
            updatedAt = LocalDateTime.now()
        )

        every { 
            attachmentService.compressImage(attachmentId, quality, userId, userRoles) 
        } returns compressedDto

        When("이미지 압축 API를 호출하면") {
            val result = mockMvc.perform(
                post("/api/v1/attachments/$attachmentId/compress")
                    .param("quality", quality.toString())
                    .param("userId", userId.toString())
                    .param("userRoles", "USER")
            )

            Then("압축된 이미지가 생성된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.fileName").value("compressed_70_test-image.jpg"))
                    .andExpect(jsonPath("$.message").value("이미지가 성공적으로 압축되었습니다."))

                verify { attachmentService.compressImage(attachmentId, quality, userId, userRoles) }
            }
        }
    }

    Given("파일 접근 권한 검사 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()
        val userId = UUID.randomUUID()
        val userRoles = setOf("USER")

        every { attachmentService.checkFileAccess(attachmentId, userId, userRoles) } returns true

        When("파일 접근 권한 검사 API를 호출하면") {
            val result = mockMvc.perform(
                get("/api/v1/attachments/$attachmentId/access-check")
                    .param("userId", userId.toString())
                    .param("userRoles", "USER")
            )

            Then("접근 권한 결과가 반환된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data").value(true))

                verify { attachmentService.checkFileAccess(attachmentId, userId, userRoles) }
            }
        }
    }

    Given("파일 무결성 검증 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()

        every { attachmentService.verifyFileIntegrity(attachmentId) } returns true

        When("파일 무결성 검증 API를 호출하면") {
            val result = mockMvc.perform(
                get("/api/v1/attachments/$attachmentId/verify-integrity")
            )

            Then("무결성 검증 결과가 반환된다") {
                result.andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data").value(true))
                    .andExpect(jsonPath("$.message").value("파일 무결성이 확인되었습니다."))

                verify { attachmentService.verifyFileIntegrity(attachmentId) }
            }
        }
    }

    Given("첨부파일 삭제 요청이 주어졌을 때") {
        val attachmentId = UUID.randomUUID()

        every { attachmentService.deleteAttachment(attachmentId) } returns Unit

        When("첨부파일 삭제 API를 호출하면") {
            val result = mockMvc.perform(
                delete("/api/v1/attachments/$attachmentId")
            )

            Then("첨부파일이 성공적으로 삭제된다") {
                result.andExpect(status().isNoContent)

                verify { attachmentService.deleteAttachment(attachmentId) }
            }
        }
    }
})