package com.qiro.common.security

import java.util.*

/**
 * 사용자 인증 정보를 담는 Principal 클래스
 */
data class CustomUserPrincipal(
    val id: UUID,
    val username: String,
    val email: String,
    val fullName: String,
    val companyId: UUID,
    val userRole: String,
    val authorities: List<String> = emptyList(),
    val isAccountLocked: Boolean = false,
    val userStatus: String = "ACTIVE"
)