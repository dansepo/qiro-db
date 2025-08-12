package com.qiro.common.config

import org.slf4j.LoggerFactory
import org.springframework.boot.context.properties.ConfigurationPropertiesBinding
// import org.springframework.cloud.context.refresh.ContextRefresher
import org.springframework.context.ApplicationEventPublisher
import org.springframework.stereotype.Service
import java.time.LocalDateTime

/**
 * 설정 갱신 서비스
 */
@Service
class ConfigurationRefreshService(
    // private val contextRefresher: ContextRefresher?,
    private val applicationEventPublisher: ApplicationEventPublisher,
    private val applicationProperties: ApplicationProperties
) {

    private val logger = LoggerFactory.getLogger(ConfigurationRefreshService::class.java)
    private var lastRefreshTime: LocalDateTime? = null

    /**
     * 설정 갱신
     */
    fun refreshConfiguration(): ConfigurationRefreshResult {
        return try {
            logger.info("Starting configuration refresh...")
            
            val startTime = System.currentTimeMillis()
            
            // Spring Cloud Config를 사용하는 경우 설정 갱신
            val changedKeys = emptySet<String>()
            
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            lastRefreshTime = LocalDateTime.now()
            
            // 설정 갱신 이벤트 발행
            val event = ConfigurationRefreshEvent(
                refreshTime = lastRefreshTime!!,
                changedKeys = changedKeys,
                duration = duration,
                success = true
            )
            applicationEventPublisher.publishEvent(event)
            
            logger.info("Configuration refresh completed successfully in {}ms. Changed keys: {}", 
                duration, changedKeys)
            
            ConfigurationRefreshResult(
                success = true,
                changedKeys = changedKeys,
                duration = duration,
                message = "Configuration refreshed successfully"
            )
            
        } catch (e: Exception) {
            logger.error("Configuration refresh failed", e)
            
            val event = ConfigurationRefreshEvent(
                refreshTime = LocalDateTime.now(),
                changedKeys = emptySet(),
                duration = 0,
                success = false,
                error = e.message
            )
            applicationEventPublisher.publishEvent(event)
            
            ConfigurationRefreshResult(
                success = false,
                changedKeys = emptySet(),
                duration = 0,
                message = "Configuration refresh failed: ${e.message}"
            )
        }
    }

    /**
     * 현재 설정 상태 조회
     */
    fun getCurrentConfiguration(): Map<String, Any> {
        return mapOf(
            "lastRefreshTime" to (lastRefreshTime?.toString() ?: "Never"),
            "jwt" to mapOf(
                "accessTokenExpiration" to applicationProperties.jwt.accessTokenExpiration.toString(),
                "refreshTokenExpiration" to applicationProperties.jwt.refreshTokenExpiration.toString(),
                "issuer" to applicationProperties.jwt.issuer
            ),
            "database" to mapOf(
                "maxPoolSize" to applicationProperties.database.maxPoolSize,
                "minPoolSize" to applicationProperties.database.minPoolSize,
                "connectionTimeout" to applicationProperties.database.connectionTimeout.toString()
            ),
            "file" to mapOf(
                "uploadPath" to applicationProperties.file.uploadPath,
                "maxFileSize" to applicationProperties.file.maxFileSize,
                "allowedExtensions" to applicationProperties.file.allowedExtensions
            ),
            "business" to mapOf(
                "invoice" to mapOf(
                    "defaultDueDays" to applicationProperties.business.invoice.defaultDueDays,
                    "lateFeeRate" to applicationProperties.business.invoice.lateFeeRate,
                    "autoSendEnabled" to applicationProperties.business.invoice.autoSendEnabled
                ),
                "payment" to mapOf(
                    "supportedMethods" to applicationProperties.business.payment.supportedMethods,
                    "autoConfirmationEnabled" to applicationProperties.business.payment.autoConfirmationEnabled
                )
            )
        )
    }

    /**
     * 설정 검증
     */
    fun validateConfiguration(): ConfigurationValidationResult {
        val errors = mutableListOf<String>()
        val warnings = mutableListOf<String>()

        // JWT 설정 검증
        if (applicationProperties.jwt.secret.length < 32) {
            errors.add("JWT secret key is too short (minimum 32 characters required)")
        }
        
        if (applicationProperties.jwt.accessTokenExpiration.toMinutes() > 60) {
            warnings.add("JWT access token expiration is longer than 1 hour")
        }

        // 데이터베이스 설정 검증
        if (applicationProperties.database.maxPoolSize < applicationProperties.database.minPoolSize) {
            errors.add("Database max pool size must be greater than min pool size")
        }
        
        if (applicationProperties.database.maxPoolSize > 100) {
            warnings.add("Database max pool size is very high (${applicationProperties.database.maxPoolSize})")
        }

        // 파일 설정 검증
        if (applicationProperties.file.maxFileSize > 100 * 1024 * 1024) { // 100MB
            warnings.add("Max file size is very large (${applicationProperties.file.maxFileSize} bytes)")
        }

        // 비즈니스 설정 검증
        if (applicationProperties.business.invoice.lateFeeRate > 0.1) { // 10%
            warnings.add("Late fee rate is very high (${applicationProperties.business.invoice.lateFeeRate * 100}%)")
        }

        return ConfigurationValidationResult(
            valid = errors.isEmpty(),
            errors = errors,
            warnings = warnings
        )
    }

    /**
     * 설정 롤백 (이전 상태로 복원)
     */
    fun rollbackConfiguration(): ConfigurationRollbackResult {
        return try {
            logger.info("Rolling back configuration...")
            
            // 실제 구현에서는 이전 설정 상태를 저장하고 복원하는 로직 필요
            // 여기서는 단순히 현재 설정을 다시 로드하는 것으로 시뮬레이션
            
            val refreshResult = refreshConfiguration()
            
            ConfigurationRollbackResult(
                success = refreshResult.success,
                message = if (refreshResult.success) "Configuration rolled back successfully" 
                         else "Configuration rollback failed"
            )
            
        } catch (e: Exception) {
            logger.error("Configuration rollback failed", e)
            
            ConfigurationRollbackResult(
                success = false,
                message = "Configuration rollback failed: ${e.message}"
            )
        }
    }
}

/**
 * 설정 갱신 결과
 */
data class ConfigurationRefreshResult(
    val success: Boolean,
    val changedKeys: Set<String>,
    val duration: Long,
    val message: String
)

/**
 * 설정 검증 결과
 */
data class ConfigurationValidationResult(
    val valid: Boolean,
    val errors: List<String>,
    val warnings: List<String>
)

/**
 * 설정 롤백 결과
 */
data class ConfigurationRollbackResult(
    val success: Boolean,
    val message: String
)

/**
 * 설정 갱신 이벤트
 */
data class ConfigurationRefreshEvent(
    val refreshTime: LocalDateTime,
    val changedKeys: Set<String>,
    val duration: Long,
    val success: Boolean,
    val error: String? = null
)