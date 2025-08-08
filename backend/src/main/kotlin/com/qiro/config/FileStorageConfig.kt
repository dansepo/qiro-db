package com.qiro.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Configuration
import java.nio.file.Path
import java.nio.file.Paths

/**
 * 파일 저장소 설정
 */
@Configuration
@ConfigurationProperties(prefix = "app.file-storage")
data class FileStorageConfig(
    /**
     * 파일 업로드 기본 디렉토리
     */
    var uploadDir: String = "uploads",
    
    /**
     * 썸네일 디렉토리
     */
    var thumbnailDir: String = "thumbnails",
    
    /**
     * 최대 파일 크기 (바이트)
     */
    var maxFileSize: Long = 10 * 1024 * 1024L, // 10MB
    
    /**
     * 썸네일 최대 너비
     */
    var thumbnailMaxWidth: Int = 300,
    
    /**
     * 썸네일 최대 높이
     */
    var thumbnailMaxHeight: Int = 300,
    
    /**
     * 썸네일 품질 (0.0 ~ 1.0)
     */
    var thumbnailQuality: Float = 0.8f,
    
    /**
     * 허용된 이미지 타입
     */
    var allowedImageTypes: Set<String> = setOf(
        "image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp", "image/bmp"
    ),
    
    /**
     * 허용된 비디오 타입
     */
    var allowedVideoTypes: Set<String> = setOf(
        "video/mp4", "video/avi", "video/mov", "video/wmv", "video/webm", "video/mkv"
    ),
    
    /**
     * 허용된 문서 타입
     */
    var allowedDocumentTypes: Set<String> = setOf(
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.ms-excel",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.ms-powerpoint",
        "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        "text/plain",
        "text/csv"
    ),
    
    /**
     * 위험한 파일 확장자
     */
    var dangerousExtensions: Set<String> = setOf(
        "exe", "bat", "cmd", "com", "pif", "scr", "vbs", "js", "jar", "sh", "ps1"
    )
) {
    
    /**
     * 업로드 디렉토리 Path 반환
     */
    fun getUploadPath(): Path = Paths.get(uploadDir)
    
    /**
     * 썸네일 디렉토리 Path 반환
     */
    fun getThumbnailPath(): Path = Paths.get(thumbnailDir)
    
    /**
     * 허용된 파일 타입인지 확인
     */
    fun isAllowedFileType(contentType: String): Boolean {
        return contentType in allowedImageTypes ||
               contentType in allowedVideoTypes ||
               contentType in allowedDocumentTypes
    }
    
    /**
     * 이미지 파일인지 확인
     */
    fun isImageFile(contentType: String): Boolean {
        return contentType in allowedImageTypes
    }
    
    /**
     * 비디오 파일인지 확인
     */
    fun isVideoFile(contentType: String): Boolean {
        return contentType in allowedVideoTypes
    }
    
    /**
     * 문서 파일인지 확인
     */
    fun isDocumentFile(contentType: String): Boolean {
        return contentType in allowedDocumentTypes
    }
    
    /**
     * 위험한 파일 확장자인지 확인
     */
    fun isDangerousExtension(extension: String): Boolean {
        return extension.lowercase() in dangerousExtensions
    }
}