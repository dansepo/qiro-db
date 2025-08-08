package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import org.imgscalr.Scalr
import org.springframework.stereotype.Service
import java.awt.image.BufferedImage
import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import javax.imageio.ImageIO

/**
 * 이미지 처리 서비스
 * 이미지 리사이징, 썸네일 생성, 포맷 변환 등을 담당
 */
@Service
class ImageProcessingService(
    private val fileStorageConfig: FileStorageConfig
) {

    /**
     * 썸네일 생성
     * @param originalImagePath 원본 이미지 경로
     * @param thumbnailPath 썸네일 저장 경로
     * @return 생성된 썸네일 경로
     */
    fun generateThumbnail(originalImagePath: String, thumbnailPath: String): String? {
        return try {
            val originalFile = File(originalImagePath)
            if (!originalFile.exists()) {
                throw IllegalArgumentException("원본 이미지 파일이 존재하지 않습니다: $originalImagePath")
            }

            // 원본 이미지 읽기
            val originalImage = ImageIO.read(originalFile)
                ?: throw IllegalArgumentException("이미지를 읽을 수 없습니다: $originalImagePath")

            // 썸네일 생성
            val thumbnail = createThumbnail(originalImage)

            // 썸네일 저장 디렉토리 생성
            val thumbnailFile = File(thumbnailPath)
            Files.createDirectories(thumbnailFile.parentFile.toPath())

            // 썸네일 저장
            val format = getImageFormat(originalImagePath)
            ImageIO.write(thumbnail, format, thumbnailFile)

            thumbnailPath
        } catch (e: Exception) {
            println("썸네일 생성 실패: $originalImagePath -> $thumbnailPath, 오류: ${e.message}")
            null
        }
    }

    /**
     * 이미지 리사이징
     * @param originalImagePath 원본 이미지 경로
     * @param targetWidth 목표 너비
     * @param targetHeight 목표 높이
     * @param outputPath 출력 경로
     * @return 리사이징된 이미지 경로
     */
    fun resizeImage(
        originalImagePath: String,
        targetWidth: Int,
        targetHeight: Int,
        outputPath: String
    ): String? {
        return try {
            val originalFile = File(originalImagePath)
            val originalImage = ImageIO.read(originalFile)
                ?: throw IllegalArgumentException("이미지를 읽을 수 없습니다: $originalImagePath")

            // 이미지 리사이징
            val resizedImage = Scalr.resize(
                originalImage,
                Scalr.Method.QUALITY,
                Scalr.Mode.FIT_EXACT,
                targetWidth,
                targetHeight
            )

            // 출력 디렉토리 생성
            val outputFile = File(outputPath)
            Files.createDirectories(outputFile.parentFile.toPath())

            // 리사이징된 이미지 저장
            val format = getImageFormat(originalImagePath)
            ImageIO.write(resizedImage, format, outputFile)

            outputPath
        } catch (e: Exception) {
            println("이미지 리사이징 실패: $originalImagePath -> $outputPath, 오류: ${e.message}")
            null
        }
    }

    /**
     * 이미지 압축
     * @param originalImagePath 원본 이미지 경로
     * @param quality 압축 품질 (0.0 ~ 1.0)
     * @param outputPath 출력 경로
     * @return 압축된 이미지 경로
     */
    fun compressImage(
        originalImagePath: String,
        quality: Float = fileStorageConfig.thumbnailQuality,
        outputPath: String
    ): String? {
        return try {
            val originalFile = File(originalImagePath)
            val originalImage = ImageIO.read(originalFile)
                ?: throw IllegalArgumentException("이미지를 읽을 수 없습니다: $originalImagePath")

            // 출력 디렉토리 생성
            val outputFile = File(outputPath)
            Files.createDirectories(outputFile.parentFile.toPath())

            // JPEG 압축 설정
            val writers = ImageIO.getImageWritersByFormatName("jpg")
            if (!writers.hasNext()) {
                throw IllegalStateException("JPEG writer를 찾을 수 없습니다")
            }

            val writer = writers.next()
            val writeParam = writer.defaultWriteParam
            writeParam.compressionMode = javax.imageio.ImageWriteParam.MODE_EXPLICIT
            writeParam.compressionQuality = quality

            // 압축된 이미지 저장
            outputFile.outputStream().use { output ->
                val ios = ImageIO.createImageOutputStream(output)
                writer.output = ios
                writer.write(null, javax.imageio.IIOImage(originalImage, null, null), writeParam)
                writer.dispose()
                ios.close()
            }

            outputPath
        } catch (e: Exception) {
            println("이미지 압축 실패: $originalImagePath -> $outputPath, 오류: ${e.message}")
            null
        }
    }

    /**
     * 이미지 포맷 변환
     * @param originalImagePath 원본 이미지 경로
     * @param targetFormat 목표 포맷 (jpg, png, webp 등)
     * @param outputPath 출력 경로
     * @return 변환된 이미지 경로
     */
    fun convertImageFormat(
        originalImagePath: String,
        targetFormat: String,
        outputPath: String
    ): String? {
        return try {
            val originalFile = File(originalImagePath)
            val originalImage = ImageIO.read(originalFile)
                ?: throw IllegalArgumentException("이미지를 읽을 수 없습니다: $originalImagePath")

            // 출력 디렉토리 생성
            val outputFile = File(outputPath)
            Files.createDirectories(outputFile.parentFile.toPath())

            // 포맷 변환 및 저장
            ImageIO.write(originalImage, targetFormat.lowercase(), outputFile)

            outputPath
        } catch (e: Exception) {
            println("이미지 포맷 변환 실패: $originalImagePath -> $outputPath, 오류: ${e.message}")
            null
        }
    }

    /**
     * 이미지 메타데이터 추출
     * @param imagePath 이미지 경로
     * @return 이미지 메타데이터
     */
    fun extractImageMetadata(imagePath: String): ImageMetadata? {
        return try {
            val imageFile = File(imagePath)
            val image = ImageIO.read(imageFile)
                ?: throw IllegalArgumentException("이미지를 읽을 수 없습니다: $imagePath")

            ImageMetadata(
                width = image.width,
                height = image.height,
                format = getImageFormat(imagePath),
                fileSize = imageFile.length(),
                colorModel = image.colorModel.javaClass.simpleName,
                hasAlpha = image.colorModel.hasAlpha()
            )
        } catch (e: Exception) {
            println("이미지 메타데이터 추출 실패: $imagePath, 오류: ${e.message}")
            null
        }
    }

    /**
     * 이미지 유효성 검사
     * @param imagePath 이미지 경로
     * @return 유효한 이미지인지 여부
     */
    fun validateImage(imagePath: String): Boolean {
        return try {
            val imageFile = File(imagePath)
            if (!imageFile.exists()) return false

            val image = ImageIO.read(imageFile)
            image != null && image.width > 0 && image.height > 0
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 썸네일 생성 (내부 메서드)
     */
    private fun createThumbnail(originalImage: BufferedImage): BufferedImage {
        val maxWidth = fileStorageConfig.thumbnailMaxWidth
        val maxHeight = fileStorageConfig.thumbnailMaxHeight

        // 원본 이미지 크기
        val originalWidth = originalImage.width
        val originalHeight = originalImage.height

        // 썸네일 크기 계산 (비율 유지)
        val ratio = minOf(
            maxWidth.toDouble() / originalWidth,
            maxHeight.toDouble() / originalHeight
        )

        val thumbnailWidth = (originalWidth * ratio).toInt()
        val thumbnailHeight = (originalHeight * ratio).toInt()

        // 썸네일 생성
        return Scalr.resize(
            originalImage,
            Scalr.Method.QUALITY,
            Scalr.Mode.FIT_EXACT,
            thumbnailWidth,
            thumbnailHeight
        )
    }

    /**
     * 이미지 포맷 추출
     */
    private fun getImageFormat(imagePath: String): String {
        val extension = imagePath.substringAfterLast('.', "").lowercase()
        return when (extension) {
            "jpg", "jpeg" -> "jpg"
            "png" -> "png"
            "gif" -> "gif"
            "bmp" -> "bmp"
            "webp" -> "webp"
            else -> "jpg" // 기본값
        }
    }
}

/**
 * 이미지 메타데이터
 */
data class ImageMetadata(
    val width: Int,
    val height: Int,
    val format: String,
    val fileSize: Long,
    val colorModel: String,
    val hasAlpha: Boolean
)