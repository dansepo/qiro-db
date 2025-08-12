package com.qiro.common.security

import java.util.*

/**
 * JWT 토큰 제공자 (임시 구현)
 */
class JwtTokenProvider {
    
    fun generateToken(userPrincipal: CustomUserPrincipal): String {
        // TODO: JWT 토큰 생성 로직 구현
        return "temporary-jwt-token"
    }
    
    fun validateToken(token: String): Boolean {
        // TODO: JWT 토큰 검증 로직 구현
        return true
    }
    
    fun getUserPrincipalFromToken(token: String): CustomUserPrincipal? {
        // TODO: JWT 토큰에서 사용자 정보 추출 로직 구현
        return null
    }
}