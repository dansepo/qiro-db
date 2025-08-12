package com.qiro.common.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.bind.ConstructorBinding
import java.time.Duration

/**
 * 애플리케이션 설정 프로퍼티
 */
@ConfigurationProperties(prefix = "qiro")
data class ApplicationProperties @ConstructorBinding constructor(
    val jwt: JwtProperties,
    val database: DatabaseProperties,
    val file: FileProperties,
    val notification: NotificationProperties,
    val monitoring: MonitoringProperties,
    val business: BusinessProperties
)

/**
 * JWT 관련 설정
 */
data class JwtProperties(
    val secret: String,
    val accessTokenExpiration: Duration = Duration.ofHours(1),
    val refreshTokenExpiration: Duration = Duration.ofDays(7),
    val issuer: String = "qiro-backend"
)

/**
 * 데이터베이스 관련 설정
 */
data class DatabaseProperties(
    val connectionTimeout: Duration = Duration.ofSeconds(30),
    val maxPoolSize: Int = 20,
    val minPoolSize: Int = 5,
    val idleTimeout: Duration = Duration.ofMinutes(10),
    val maxLifetime: Duration = Duration.ofMinutes(30)
)

/**
 * 파일 관리 관련 설정
 */
data class FileProperties(
    val uploadPath: String = "./uploads",
    val maxFileSize: Long = 10 * 1024 * 1024, // 10MB
    val allowedExtensions: List<String> = listOf("jpg", "jpeg", "png", "pdf", "doc", "docx", "xls", "xlsx"),
    val pdfGenerationPath: String = "./pdf-temp"
)

/**
 * 알림 관련 설정
 */
data class NotificationProperties(
    val email: EmailProperties,
    val sms: SmsProperties,
    val push: PushProperties
)

data class EmailProperties(
    val enabled: Boolean = true,
    val host: String = "localhost",
    val port: Int = 587,
    val username: String = "",
    val password: String = "",
    val fromAddress: String = "noreply@qiro.com",
    val fromName: String = "QIRO 시스템"
)

data class SmsProperties(
    val enabled: Boolean = false,
    val provider: String = "none", // "twilio", "aws-sns", etc.
    val apiKey: String = "",
    val apiSecret: String = "",
    val fromNumber: String = ""
)

data class PushProperties(
    val enabled: Boolean = false,
    val fcmServerKey: String = "",
    val apnsKeyId: String = "",
    val apnsTeamId: String = "",
    val apnsKeyPath: String = ""
)

/**
 * 모니터링 관련 설정
 */
data class MonitoringProperties(
    val metrics: MetricsProperties,
    val health: HealthProperties,
    val logging: LoggingProperties
)

data class MetricsProperties(
    val enabled: Boolean = true,
    val exportInterval: Duration = Duration.ofMinutes(1),
    val retentionPeriod: Duration = Duration.ofDays(30)
)

data class HealthProperties(
    val diskSpaceThreshold: Long = 1024 * 1024 * 1024, // 1GB
    val memoryThreshold: Double = 0.9, // 90%
    val databaseTimeout: Duration = Duration.ofSeconds(5)
)

data class LoggingProperties(
    val level: String = "INFO",
    val maxFileSize: String = "100MB",
    val maxHistory: Int = 30,
    val totalSizeCap: String = "3GB"
)

/**
 * 비즈니스 로직 관련 설정
 */
data class BusinessProperties(
    val invoice: InvoiceProperties,
    val payment: PaymentProperties,
    val maintenance: MaintenanceProperties
)

data class InvoiceProperties(
    val defaultDueDays: Int = 30,
    val lateFeeRate: Double = 0.02, // 2%
    val lateFeeGracePeriod: Int = 3, // 3일
    val autoSendEnabled: Boolean = true,
    val pdfGenerationEnabled: Boolean = true
)

data class PaymentProperties(
    val supportedMethods: List<String> = listOf("CASH", "BANK_TRANSFER", "CARD", "VIRTUAL_ACCOUNT"),
    val refundGracePeriod: Duration = Duration.ofDays(7),
    val autoConfirmationEnabled: Boolean = false
)

data class MaintenanceProperties(
    val defaultPriority: String = "MEDIUM",
    val autoAssignmentEnabled: Boolean = true,
    val escalationThreshold: Duration = Duration.ofHours(24),
    val reminderInterval: Duration = Duration.ofHours(4)
)