package com.qiro.security

import com.qiro.domain.user.entity.UserRole
import org.springframework.security.core.GrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import java.util.*

data class CustomUserPrincipal(
    val id: UUID,
    private val username: String,
    private val password: String,
    val email: String,
    val fullName: String,
    val companyId: UUID,
    val userRole: UserRole,
    private val authorities: Collection<GrantedAuthority>,
    private val accountNonExpired: Boolean,
    private val accountNonLocked: Boolean,
    private val credentialsNonExpired: Boolean,
    private val enabled: Boolean
) : UserDetails {
    
    override fun getAuthorities(): Collection<GrantedAuthority> = authorities
    
    override fun getPassword(): String = password
    
    override fun getUsername(): String = username
    
    override fun isAccountNonExpired(): Boolean = accountNonExpired
    
    override fun isAccountNonLocked(): Boolean = accountNonLocked
    
    override fun isCredentialsNonExpired(): Boolean = credentialsNonExpired
    
    override fun isEnabled(): Boolean = enabled
    
    fun hasPermission(permission: String): Boolean {
        return authorities.any { authority ->
            authority.authority == "*" || 
            authority.authority == permission ||
            (authority.authority.endsWith(":*") && permission.startsWith(authority.authority.substringBefore(":*")))
        }
    }
}