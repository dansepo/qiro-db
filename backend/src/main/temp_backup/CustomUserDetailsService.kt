package com.qiro.security

import com.qiro.domain.user.repository.UserRepository
import org.springframework.security.core.authority.SimpleGrantedAuthority
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.core.userdetails.UsernameNotFoundException
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

@Service
@Transactional(readOnly = true)
class CustomUserDetailsService(
    private val userRepository: UserRepository
) : UserDetailsService {
    
    override fun loadUserByUsername(username: String): UserDetails {
        val user = userRepository.findByUsernameAndUserStatus(username, com.qiro.domain.user.entity.UserStatus.ACTIVE)
            ?: throw UsernameNotFoundException("사용자를 찾을 수 없습니다: $username")
        
        return CustomUserPrincipal(
            id = user.id,
            username = user.username,
            password = user.password,
            email = user.email,
            fullName = user.fullName,
            companyId = user.companyId,
            userRole = user.userRole,
            authorities = user.userRole.permissions.map { SimpleGrantedAuthority(it) },
            accountNonExpired = true,
            accountNonLocked = !user.isAccountLocked(),
            credentialsNonExpired = true,
            enabled = user.userStatus == com.qiro.domain.user.entity.UserStatus.ACTIVE
        )
    }
}