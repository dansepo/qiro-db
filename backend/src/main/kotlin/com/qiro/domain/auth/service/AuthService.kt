package com.qiro.domain.auth.service

import com.qiro.common.exception.EntityNotFoundException
import com.qiro.common.exception.InvalidBusinessRuleException
import com.qiro.domain.auth.dto.*
import com.qiro.domain.user.entity.UserStatus
import com.qiro.domain.user.repository.UserRepository
import com.qiro.security.CustomUserPrincipal
import com.qiro.security.jwt.JwtTokenProvider
import org.springframework.security.authentication.AuthenticationManager
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.Authentication
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

@Service
@Transactional(readOnly = true)
class AuthService(
    private val authenticationManager: AuthenticationManager,
    private val jwtTokenProvider: JwtTokenProvider,
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder
) {
    
    @Transactional
    fun login(request: LoginRequest): LoginResponse {
        try {
            val authentication = authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken(request.username, request.password)
            )
            
            val userPrincipal = authentication.principal as CustomUserPrincipal
            val user = userRepository.findById(userPrincipal.id)
                .orElseThrow { EntityNotFoundException("사용자를 찾을 수 없습니다") }
            
            // 로그인 성공 기록
            user.recordSuccessfulLogin()
            
            // 토큰 생성
            val accessToken = jwtTokenProvider.generateAccessToken(authentication)
            val refreshToken = jwtTokenProvider.generateRefreshToken(userPrincipal.username)
            
            return LoginResponse(
                accessToken = accessToken,
                refreshToken = refreshToken,
                expiresIn = 3600, // 1시간 (초 단위)
                user = UserInfo(
                    id = user.id,
                    username = user.username,
                    email = user.email,
                    fullName = user.fullName,
                    companyId = user.companyId,
                    userRole = user.userRole,
                    department = user.department,
                    position = user.position,
                    profileImageUrl = user.profileImageUrl,
                    lastLoginAt = user.lastLoginAt,
                    emailVerified = user.emailVerified,
                    twoFactorEnabled = user.twoFactorEnabled
                )
            )
        } catch (ex: BadCredentialsException) {
            // 로그인 실패 기록
            val user = userRepository.findByUsernameAndUserStatus(request.username, UserStatus.ACTIVE)
            user?.recordFailedLogin()
            
            throw InvalidBusinessRuleException("사용자명 또는 비밀번호가 올바르지 않습니다")
        }
    }
    
    fun refreshToken(request: RefreshTokenRequest): RefreshTokenResponse {
        if (!jwtTokenProvider.validateToken(request.refreshToken)) {
            throw InvalidBusinessRuleException("유효하지 않은 리프레시 토큰입니다")
        }
        
        val username = jwtTokenProvider.getUsernameFromToken(request.refreshToken)
        val user = userRepository.findByUsernameAndUserStatus(username, UserStatus.ACTIVE)
            ?: throw EntityNotFoundException("사용자를 찾을 수 없습니다")
        
        // 새로운 인증 객체 생성
        val userPrincipal = CustomUserPrincipal(
            id = user.id,
            username = user.username,
            password = user.password,
            email = user.email,
            fullName = user.fullName,
            companyId = user.companyId,
            userRole = user.userRole,
            authorities = user.userRole.permissions.map { org.springframework.security.core.authority.SimpleGrantedAuthority(it) },
            accountNonExpired = true,
            accountNonLocked = !user.isAccountLocked(),
            credentialsNonExpired = true,
            enabled = user.userStatus == UserStatus.ACTIVE
        )
        
        val authentication = UsernamePasswordAuthenticationToken(userPrincipal, null, userPrincipal.authorities)
        val newAccessToken = jwtTokenProvider.generateAccessToken(authentication)
        
        return RefreshTokenResponse(
            accessToken = newAccessToken,
            expiresIn = 3600 // 1시간 (초 단위)
        )
    }
    
    @Transactional
    fun changePassword(request: ChangePasswordRequest): String {
        val currentUser = getCurrentUser()
        val user = userRepository.findById(currentUser.id)
            .orElseThrow { EntityNotFoundException("사용자를 찾을 수 없습니다") }
        
        // 현재 비밀번호 확인
        if (!passwordEncoder.matches(request.currentPassword, user.password)) {
            throw InvalidBusinessRuleException("현재 비밀번호가 올바르지 않습니다")
        }
        
        // 새 비밀번호와 확인 비밀번호 일치 확인
        if (request.newPassword != request.confirmPassword) {
            throw InvalidBusinessRuleException("새 비밀번호와 확인 비밀번호가 일치하지 않습니다")
        }
        
        // 현재 비밀번호와 새 비밀번호가 같은지 확인
        if (passwordEncoder.matches(request.newPassword, user.password)) {
            throw InvalidBusinessRuleException("새 비밀번호는 현재 비밀번호와 달라야 합니다")
        }
        
        // 비밀번호 변경
        val encodedPassword = passwordEncoder.encode(request.newPassword)
        user.changePassword(encodedPassword)
        
        return "비밀번호가 성공적으로 변경되었습니다"
    }
    
    fun logout(): String {
        // JWT는 상태가 없으므로 서버에서 특별한 처리가 필요하지 않음
        // 클라이언트에서 토큰을 삭제하도록 안내
        SecurityContextHolder.clearContext()
        return "로그아웃되었습니다"
    }
    
    fun getCurrentUser(): CustomUserPrincipal {
        val authentication = SecurityContextHolder.getContext().authentication
            ?: throw InvalidBusinessRuleException("인증되지 않은 사용자입니다")
        
        return authentication.principal as CustomUserPrincipal
    }
    
    fun resetPassword(request: ResetPasswordRequest): String {
        val user = userRepository.findByEmailAndUserStatus(request.email, UserStatus.ACTIVE)
            ?: throw EntityNotFoundException("해당 이메일로 등록된 사용자를 찾을 수 없습니다")
        
        // 임시 비밀번호 생성 (실제로는 이메일 발송 등의 처리가 필요)
        val temporaryPassword = generateTemporaryPassword()
        val encodedPassword = passwordEncoder.encode(temporaryPassword)
        
        user.changePassword(encodedPassword)
        user.mustChangePassword = true
        
        // TODO: 이메일 발송 로직 구현
        // emailService.sendTemporaryPassword(user.email, temporaryPassword)
        
        return "임시 비밀번호가 이메일로 발송되었습니다"
    }
    
    private fun generateTemporaryPassword(): String {
        val chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
        return (1..12)
            .map { chars.random() }
            .joinToString("")
    }
}