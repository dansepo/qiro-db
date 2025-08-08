package com.qiro.common.security

import java.util.*

/**
 * 인증된 사용자 정보
 */
data class UserPrincipal(
    val userId: UUID,
    val username: String,
    val companyId: UUID,
    val roles: Set<String> = emptySet()
)