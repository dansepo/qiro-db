package com.qiro.domain.auth.controller

import com.qiro.common.dto.ApiResponse
import com.qiro.domain.auth.dto.*
import com.qiro.domain.auth.service.AuthService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*

@RestController
@RequestMapping("/v1/auth")
@Tag(name = "Authentication", description = "인증 관리 API")
class AuthController(
    private val authService: AuthService
) {
    
    @PostMapping("/login")
    @Operation(summary = "로그인", description = "사용자 로그인을 처리합니다")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<ApiResponse<LoginResponse>> {
        val response = authService.login(request)
        return ResponseEntity.ok(ApiResponse.success(response, "로그인에 성공했습니다"))
    }
    
    @PostMapping("/refresh")
    @Operation(summary = "토큰 갱신", description = "리프레시 토큰을 사용하여 새로운 액세스 토큰을 발급합니다")
    fun refreshToken(@Valid @RequestBody request: RefreshTokenRequest): ResponseEntity<ApiResponse<RefreshTokenResponse>> {
        val response = authService.refreshToken(request)
        return ResponseEntity.ok(ApiResponse.success(response, "토큰이 갱신되었습니다"))
    }
    
    @PostMapping("/logout")
    @Operation(summary = "로그아웃", description = "사용자 로그아웃을 처리합니다")
    fun logout(): ResponseEntity<ApiResponse<String>> {
        val message = authService.logout()
        return ResponseEntity.ok(ApiResponse.success(message))
    }
    
    @PostMapping("/change-password")
    @Operation(summary = "비밀번호 변경", description = "현재 사용자의 비밀번호를 변경합니다")
    fun changePassword(@Valid @RequestBody request: ChangePasswordRequest): ResponseEntity<ApiResponse<String>> {
        val message = authService.changePassword(request)
        return ResponseEntity.ok(ApiResponse.success(message))
    }
    
    @PostMapping("/reset-password")
    @Operation(summary = "비밀번호 재설정", description = "이메일을 통해 비밀번호를 재설정합니다")
    fun resetPassword(@Valid @RequestBody request: ResetPasswordRequest): ResponseEntity<ApiResponse<String>> {
        val message = authService.resetPassword(request)
        return ResponseEntity.ok(ApiResponse.success(message))
    }
    
    @GetMapping("/me")
    @Operation(summary = "현재 사용자 정보", description = "현재 로그인한 사용자의 정보를 조회합니다")
    fun getCurrentUser(): ResponseEntity<ApiResponse<UserInfo>> {
        val currentUser = authService.getCurrentUser()
        val userInfo = UserInfo(
            id = currentUser.id,
            username = currentUser.username,
            email = currentUser.email,
            fullName = currentUser.fullName,
            companyId = currentUser.companyId,
            userRole = currentUser.userRole,
            department = null, // TODO: User 엔티티에서 가져오기
            position = null,   // TODO: User 엔티티에서 가져오기
            profileImageUrl = null, // TODO: User 엔티티에서 가져오기
            lastLoginAt = null,     // TODO: User 엔티티에서 가져오기
            emailVerified = false,  // TODO: User 엔티티에서 가져오기
            twoFactorEnabled = false // TODO: User 엔티티에서 가져오기
        )
        return ResponseEntity.ok(ApiResponse.success(userInfo))
    }
}