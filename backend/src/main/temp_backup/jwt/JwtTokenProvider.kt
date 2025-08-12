package com.qiro.security.jwt

import com.qiro.config.JwtProperties
import io.jsonwebtoken.*
import io.jsonwebtoken.security.Keys
import org.slf4j.LoggerFactory
import org.springframework.security.core.Authentication
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.stereotype.Component
import java.security.Key
import java.util.*

@Component
class JwtTokenProvider(
    private val jwtProperties: JwtProperties
) {

    private val key: Key = Keys.hmacShaKeyFor(jwtProperties.secret.toByteArray())
    private val logger = LoggerFactory.getLogger(JwtTokenProvider::class.java)

    /**
     * Access Token 생성
     */
    fun generateAccessToken(authentication: Authentication): String {
        val userPrincipal = authentication.principal as UserDetails
        val now = Date()
        val expiryDate = Date(now.time + jwtProperties.accessTokenExpiration)

        return Jwts.builder()
            .setSubject(userPrincipal.username)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(key) // Deprecated API 수정
            .compact()
    }

    /**
     * Refresh Token 생성
     */
    fun generateRefreshToken(username: String): String {
        val now = Date()
        val expiryDate = Date(now.time + jwtProperties.refreshTokenExpiration)

        return Jwts.builder()
            .setSubject(username)
            .setIssuedAt(now)
            .setExpiration(expiryDate)
            .signWith(key) // Deprecated API 수정
            .compact()
    }

    /**
     * 토큰에서 사용자명 추출
     */
    fun getUsernameFromToken(token: String): String {
        val claims = Jwts.parserBuilder()
            .setSigningKey(key)
            .build()
            .parseClaimsJws(token)
            .body

        return claims.subject
    }

    /**
     * 토큰 유효성 검증
     */
    fun validateToken(token: String): Boolean {
        try {
            Jwts.parserBuilder()
                .setSigningKey(key)
                .build()
                .parseClaimsJws(token)
            return true
        } catch (ex: SecurityException) {
            logger.error("Invalid JWT signature", ex)
        } catch (ex: MalformedJwtException) {
            logger.error("Invalid JWT token", ex)
        } catch (ex: ExpiredJwtException) {
            logger.error("Expired JWT token", ex)
        } catch (ex: UnsupportedJwtException) {
            logger.error("Unsupported JWT token", ex)
        } catch (ex: IllegalArgumentException) {
            logger.error("JWT claims string is empty", ex)
        }
        return false
    }

    /**
     * 토큰 만료 시간 확인
     */
    fun getExpirationDateFromToken(token: String): Date {
        val claims = Jwts.parserBuilder()
            .setSigningKey(key)
            .build()
            .parseClaimsJws(token)
            .body

        return claims.expiration
    }

    /**
     * 토큰이 만료되었는지 확인
     */
    fun isTokenExpired(token: String): Boolean {
        val expiration = getExpirationDateFromToken(token)
        return expiration.before(Date())
    }
}