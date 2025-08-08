package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import java.awt.image.BufferedImage
import java.io.File
import javax.imageio.ImageIO

/**
 * 이미지 처리 서비스 테스트
 */
class ImageProcessingServiceTest : BehaviorSpec({

    val fileStorageConfig = mockk<FileStorageConfig> {
        every { thumbnailMaxWidth } returns 300
        every { thumbnailMaxHeight } returns 300
        every { thumbnailQuality } returns 0.8f
    }
    
    val imageProcessingService = ImageProcessingService(fileStorageConfig)

    Given("유효한 이미지 파일이 주어졌을 때") {
        // 테스트용 이미지 생성
        val testImage = BufferedImage(800, 600, BufferedImage.TYPE_INT_RGB)
        val graphics = testImage.createGraphics()
        graphics.color = java.awt.Color.BLUE
        graphics.fillRect(0, 0, 800, 600)
        graphics.dispose()
        
        val tempDir = System.getProperty("java.io.tmpdir")
        val testImagePath = "$tempDir/test-image.jpg"
        val testImageFile = File(testImagePath)
        
        // 테스트 이미지 저장
        ImageIO.write(testImage, "jpg", testImageFile)

        When("이미지 메타데이터를 추출하면") {
            val metadata = imageProcessingService.extractImageMetadata(testImagePath)

            Then("올바른 메타데이터가 반환된다") {
                metadata shouldNotBe null
                metadata!!.width shouldBe 800
                metadata.height shouldBe 600
                metadata.format shouldBe "jpg"
                metadata.fileSize shouldBe testImageFile.length()
            }
        }

        When("이미지를 리사이징하면") {
            val resizedPath = "$tempDir/resized-image.jpg"
            val result = imageProcessingService.resizeImage(testImagePath, 400, 300, resizedPath)

            Then("리사이징된 이미지가 생성된다") {
                result shouldNotBe null
                result shouldBe resizedPath
                
                val resizedFile = File(resizedPath)
                resizedFile.exists() shouldBe true
                
                // 리사이징된 이미지 크기 확인
                val resizedImage = ImageIO.read(resizedFile)
                resizedImage.width shouldBe 400
                resizedImage.height shouldBe 300
            }
        }

        When("이미지를 압축하면") {
            val compressedPath = "$tempDir/compressed-image.jpg"
            val result = imageProcessingService.compressImage(testImagePath, 0.5f, compressedPath)

            Then("압축된 이미지가 생성된다") {
                result shouldNotBe null
                result shouldBe compressedPath
                
                val compressedFile = File(compressedPath)
                compressedFile.exists() shouldBe true
                
                // 압축된 파일이 원본보다 작은지 확인
                compressedFile.length() shouldBe lessThan(testImageFile.length())
            }
        }

        When("이미지 유효성을 검사하면") {
            val isValid = imageProcessingService.validateImage(testImagePath)

            Then("유효한 이미지로 판단된다") {
                isValid shouldBe true
            }
        }

        // 테스트 후 정리
        afterTest {
            listOf(testImagePath, "$tempDir/resized-image.jpg", "$tempDir/compressed-image.jpg")
                .forEach { path ->
                    try {
                        File(path).delete()
                    } catch (e: Exception) {
                        // 무시
                    }
                }
        }
    }

    Given("존재하지 않는 이미지 파일이 주어졌을 때") {
        val nonExistentPath = "/non/existent/image.jpg"

        When("이미지 메타데이터를 추출하려고 하면") {
            val metadata = imageProcessingService.extractImageMetadata(nonExistentPath)

            Then("null이 반환된다") {
                metadata shouldBe null
            }
        }

        When("이미지 유효성을 검사하면") {
            val isValid = imageProcessingService.validateImage(nonExistentPath)

            Then("유효하지 않은 이미지로 판단된다") {
                isValid shouldBe false
            }
        }
    }
})