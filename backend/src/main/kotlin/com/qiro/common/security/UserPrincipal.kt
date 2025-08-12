package com.qiro.common.security

import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import java.util.*

/**
 * 사용자 주체 정보
 */
data class UserPrincipal(
    val id: UUID,
    val companyId: UUID,
    private val username: String,
    private val password: String,
    private val authorities: Collection<GrantedAuthority>,
    private val enabled: Boolean = true,
    private val accountNonExpired: Boolean = true,
    private val accountNonLocked: Boolean = true,
    private val credentialsNonExpired: Boolean = true
) : UserDetails {

    override fun getAuthorities(): Collection<GrantedAuthority> = authorities

    override fun getPassword(): String = password

    override fun getUsername(): String = username

    override fun isAccountNonExpired(): Boolean = accountNonExpired

    override fun isAccountNonLocked(): Boolean = accountNonLocked

    override fun isCredentialsNonExpired(): Boolean = credentialsNonExpired

    override fun isEnabled(): Boolean = enabled
}