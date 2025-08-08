package com.qiro.domain.auth.dto

import com.qiro.domain.user.entity.UserRole
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import java.time.LocalDateTime
import java.util.*

// Request DTOs
data class LoginRequest(
    @field:NotBlank(message = "사용자명은 필수입니다")
    @field:Size(min = 3, max = 50, message = "사용자명은 3-50자 사이여야 합니다")
    val username: String,
    
    @field:NotBlank(message = "비밀번호는 필수입니다")
    @field:Size(min = 8, max = 100, message = "비밀번호는 8-100자 사이여야 합니다")
    val password: String
)

data class RefreshTokenRequest(
    @field:NotBlank(message = "리프레시 토큰은 필수입니다")
    val refreshToken: String
)

data class ChangePasswordRequest(
    @field:NotBlank(message = "현재 비밀번호는 필수입니다")
    val currentPassword: String,
    
    @field:NotBlank(message = "새 비밀번호는 필수입니다")
    @field:Size(min = 8, max = 100, message = "새 비밀번호는 8-100자 사이여야 합니다")
    val newPassword: String,
    
    @field:NotBlank(message = "비밀번호 확인은 필수입니다")
    val confirmPassword: String
)

data class ResetPasswordRequest(
    @field:NotBlank(message = "이메일은 필수입니다")
    @field:Email(message = "올바른 이메일 형식이 아닙니다")
    val email: String
)

// Response DTOs
data class LoginResponse(
    val accessToken: String,
    val refreshToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long,
    val user: UserInfo
)

data class RefreshTokenResponse(
    val accessToken: String,
    val tokenType: String = "Bearer",
    val expiresIn: Long
)

data class UserInfo(
    val id: UUID,
    val username: String,
    val email: String,
    val fullName: String,
    val companyId: UUID,
    val userRole: UserRole,
    val department: String?,
    val position: String?,
    val profileImageUrl: String?,
    val lastLoginAt: LocalDateTime?,
    val emailVerified: Boolean,
    val twoFactorEnabled: Boolean
)

// Internal DTOs
data class TokenInfo(
    val accessToken: String,
    val refreshToken: String,
    val expiresIn: Long
)