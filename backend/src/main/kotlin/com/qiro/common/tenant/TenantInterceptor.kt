package com.qiro.common.tenant

import com.qiro.security.CustomUserPrincipal
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerInterceptor

@Component
class TenantInterceptor(
    private val tenantContext: TenantContext
) : HandlerInterceptor {
    
    override fun preHandle(
        request: HttpServletRequest,
        response: HttpServletResponse,
        handler: Any
    ): Boolean {
        val authentication = SecurityContextHolder.getContext().authentication
        
        if (authentication?.principal is CustomUserPrincipal) {
            val userPrincipal = authentication.principal as CustomUserPrincipal
            tenantContext.setCurrentCompanyId(userPrincipal.companyId)
        }
        
        return true
    }
    
    override fun afterCompletion(
        request: HttpServletRequest,
        response: HttpServletResponse,
        handler: Any,
        ex: Exception?
    ) {
        tenantContext.clear()
    }
}