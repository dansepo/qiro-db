package com.qiro.domain.fault.service

import com.qiro.config.FileStorageConfig
import com.qiro.domain.fault.entity.Attachment
import com.qiro.domain.fault.entity.EntityType
import org.springframework.stereotype.Service
import org.springframework.web.multipart.MultipartFile
import java.io.File
import java.nio.file.Files
import java.nio.file.Path
import java.security.MessageDigest
import java.util.*

/**
 * 파일 보안 서비스
 * 파일 업로드 보안, 접근 권한 관리, 악성 파일 검사 등을 담당
 */
@Service
class FileSecurityService(
    private val fileStorageConfig: FileStorageConfig
) {

    companion object {
        // 악성 파일 시그니처 (매직 넘버)
        private val MALICIOUS_SIGNATURES = mapOf(
            // 실행 파일
            "4D5A" to "exe", // PE 실행 파일
            "7F454C46" to "elf", // ELF 실행 파일
            "CAFEBABE" to "class", // Java 클래스 파일
            "504B0304" to "zip", // ZIP 파일 (JAR 포함)
            
            // 스크립트 파일 패턴
            "3C3F706870" to "php", // <?php
            "3C25" to "jsp", // <%
            "23212F" to "script" // #!/
        )
        
        // 허용되지 않는 파일 헤더
        private val FORBIDDEN_HEADERS = setOf(
            "4D5A", // PE 실행 파일
            "7F454C46", // ELF 실행 파일
            "CAFEBABE" // Java 클래스 파일
        )
    }

    /**
     * 파일 보안 검사
     * @param file 업로드된 파일
     * @return 보안 검사 결과
     */
    fun validateFileSecurity(file: MultipartFile): FileSecurityResult {
        val errors = mutableListOf<String>()

        try {
            // 1. 파일 크기 검사
            if (file.size > fileStorageConfig.maxFileSize) {
                errors.add("파일 크기가 너무 큽니다. 최대 ${fileStorageConfig.maxFileSize / 1024 / 1024}MB까지 업로드 가능합니다.")
            }

            // 2. 파일명 검사
            val fileName = file.originalFilename
            if (fileName.isNullOrBlank()) {
                errors.add("파일명이 없습니다.")
            } else {
                // 파일명 길이 검사
                if (fileName.length > 255) {
                    errors.add("파일명이 너무 깁니다. 최대 255자까지 가능합니다.")
                }

                // 특수 문자 검사
                if (containsDangerousCharacters(fileName)) {
                    errors.add("파일명에 허용되지 않는 문자가 포함되어 있습니다.")
                }

                // 확장자 검사
                val extension = fileName.substringAfterLast('.', "")
                if (fileStorageConfig.isDangerousExtension(extension)) {
                    errors.add("보안상 업로드할 수 없는 파일 유형입니다: $extension")
                }
            }

            // 3. MIME 타입 검사
            val contentType = file.contentType
            if (contentType == null || !fileStorageConfig.isAllowedFileType(contentType)) {
                errors.add("지원하지 않는 파일 유형입니다: $contentType")
            }

            // 4. 파일 헤더 검사 (매직 넘버)
            val fileHeader = getFileHeader(file)
            if (isMaliciousFile(fileHeader)) {
                errors.add("악성 파일로 의심되는 파일입니다.")
            }

            // 5. 파일 내용 검사
            if (containsMaliciousContent(file)) {
                errors.add("파일 내용에 악성 코드가 포함되어 있을 수 있습니다.")
            }

        } catch (e: Exception) {
            errors.add("파일 보안 검사 중 오류가 발생했습니다: ${e.message}")
        }

        return FileSecurityResult(
            isValid = errors.isEmpty(),
            errors = errors,
            fileHash = if (errors.isEmpty()) calculateFileHash(file) else null
        )
    }

    /**
     * 파일 접근 권한 검사
     * @param attachment 첨부파일
     * @param userId 사용자 ID
     * @param userRoles 사용자 역할
     * @return 접근 가능 여부
     */
    fun checkFileAccess(
        attachment: Attachment,
        userId: UUID,
        userRoles: Set<String>
    ): FileAccessResult {
        try {
            // 1. 파일이 비활성화된 경우
            if (!attachment.isActive) {
                return FileAccessResult(false, "삭제된 파일입니다.")
            }

            // 2. 공개 파일인 경우
            if (attachment.isPublic) {
                return FileAccessResult(true, "공개 파일입니다.")
            }

            // 3. 업로더 본인인 경우
            if (attachment.uploadedBy == userId) {
                return FileAccessResult(true, "업로더 본인입니다.")
            }

            // 4. 관리자 권한인 경우
            if (userRoles.contains("ADMIN") || userRoles.contains("SUPER_ADMIN")) {
                return FileAccessResult(true, "관리자 권한입니다.")
            }

            // 5. 엔티티별 접근 권한 검사
            when (attachment.entityType) {
                EntityType.FAULT_REPORT -> {
                    // 고장신고 관련 파일: 신고자, 담당자, 관리자만 접근 가능
                    if (userRoles.contains("TECHNICIAN") || userRoles.contains("MANAGER")) {
                        return FileAccessResult(true, "담당자 권한입니다.")
                    }
                }
                EntityType.WORK_ORDER -> {
                    // 작업지시서 관련 파일: 작업자, 관리자만 접근 가능
                    if (userRoles.contains("TECHNICIAN") || userRoles.contains("MANAGER")) {
                        return FileAccessResult(true, "작업자 권한입니다.")
                    }
                }
                EntityType.MAINTENANCE -> {
                    // 정비 관련 파일: 정비 담당자, 관리자만 접근 가능
                    if (userRoles.contains("MAINTENANCE_STAFF") || userRoles.contains("MANAGER")) {
                        return FileAccessResult(true, "정비 담당자 권한입니다.")
                    }
                }
                else -> {
                    // 기타 파일: 기본 권한 검사
                    if (userRoles.contains("USER")) {
                        return FileAccessResult(true, "일반 사용자 권한입니다.")
                    }
                }
            }

            return FileAccessResult(false, "파일에 접근할 권한이 없습니다.")

        } catch (e: Exception) {
            return FileAccessResult(false, "권한 검사 중 오류가 발생했습니다: ${e.message}")
        }
    }

    /**
     * 안전한 파일명 생성
     * @param originalFileName 원본 파일명
     * @return 안전한 파일명
     */
    fun generateSecureFileName(originalFileName: String): String {
        val extension = originalFileName.substringAfterLast('.', "")
        val nameWithoutExtension = originalFileName.substringBeforeLast('.')
        
        // 특수 문자 제거 및 안전한 문자로 변환
        val safeName = nameWithoutExtension
            .replace(Regex("[^a-zA-Z0-9가-힣._-]"), "_")
            .take(100) // 파일명 길이 제한
        
        val uniqueId = UUID.randomUUID().toString().take(8)
        
        return if (extension.isNotEmpty()) {
            "${safeName}_${uniqueId}.${extension}"
        } else {
            "${safeName}_${uniqueId}"
        }
    }

    /**
     * 파일 해시 계산
     * @param file 파일
     * @return SHA-256 해시
     */
    fun calculateFileHash(file: MultipartFile): String {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            val hashBytes = digest.digest(file.bytes)
            hashBytes.joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * 파일 무결성 검증
     * @param filePath 파일 경로
     * @param expectedHash 예상 해시값
     * @return 무결성 검증 결과
     */
    fun verifyFileIntegrity(filePath: String, expectedHash: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val digest = MessageDigest.getInstance("SHA-256")
            val fileBytes = Files.readAllBytes(file.toPath())
            val actualHash = digest.digest(fileBytes).joinToString("") { "%02x".format(it) }

            actualHash == expectedHash
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 임시 파일 정리
     * @param tempDir 임시 디렉토리
     * @param maxAgeHours 최대 보관 시간 (시간)
     */
    fun cleanupTempFiles(tempDir: Path, maxAgeHours: Int = 24) {
        try {
            if (!Files.exists(tempDir)) return

            val cutoffTime = System.currentTimeMillis() - (maxAgeHours * 60 * 60 * 1000L)

            Files.walk(tempDir)
                .filter { Files.isRegularFile(it) }
                .filter { Files.getLastModifiedTime(it).toMillis() < cutoffTime }
                .forEach { 
                    try {
                        Files.deleteIfExists(it)
                    } catch (e: Exception) {
                        println("임시 파일 삭제 실패: $it, 오류: ${e.message}")
                    }
                }
        } catch (e: Exception) {
            println("임시 파일 정리 실패: ${e.message}")
        }
    }

    /**
     * 파일 헤더 추출 (매직 넘버)
     */
    private fun getFileHeader(file: MultipartFile): String {
        return try {
            val bytes = file.bytes
            if (bytes.size < 4) return ""
            
            bytes.take(8).joinToString("") { "%02X".format(it) }
        } catch (e: Exception) {
            ""
        }
    }

    /**
     * 악성 파일 검사
     */
    private fun isMaliciousFile(fileHeader: String): Boolean {
        if (fileHeader.isEmpty()) return false
        
        return FORBIDDEN_HEADERS.any { fileHeader.startsWith(it) }
    }

    /**
     * 위험한 문자 포함 검사
     */
    private fun containsDangerousCharacters(fileName: String): Boolean {
        val dangerousChars = setOf('<', '>', ':', '"', '|', '?', '*', '\\', '/', '\u0000')
        return fileName.any { it in dangerousChars }
    }

    /**
     * 악성 콘텐츠 검사
     */
    private fun containsMaliciousContent(file: MultipartFile): Boolean {
        return try {
            val content = String(file.bytes.take(1024).toByteArray()) // 첫 1KB만 검사
            val maliciousPatterns = listOf(
                "<?php", "<%", "#!/", "<script", "javascript:", "vbscript:",
                "eval(", "exec(", "system(", "shell_exec("
            )
            
            maliciousPatterns.any { pattern ->
                content.contains(pattern, ignoreCase = true)
            }
        } catch (e: Exception) {
            false
        }
    }
}

/**
 * 파일 보안 검사 결과
 */
data class FileSecurityResult(
    val isValid: Boolean,
    val errors: List<String>,
    val fileHash: String? = null
)

/**
 * 파일 접근 권한 검사 결과
 */
data class FileAccessResult(
    val hasAccess: Boolean,
    val reason: String
)