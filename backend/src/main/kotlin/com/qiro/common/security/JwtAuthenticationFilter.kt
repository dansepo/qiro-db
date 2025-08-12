package com.qiro.common.security

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.web.filter.OncePerRequestFilter

/**
 * JWT 인증 필터 (임시 구현)
 */
class JwtAuthenticationFilter : OncePerRequestFilter() {
    
    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        filterChain: FilterChain
    ) {
        // TODO: JWT 토큰 검증 로직 구현
        filterChain.doFilter(request, response)
    }
}