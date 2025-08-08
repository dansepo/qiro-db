package com.qiro.config

import com.qiro.common.tenant.TenantInterceptor
import org.springframework.context.annotation.Configuration
import org.springframework.web.servlet.config.annotation.InterceptorRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebConfig(
    private val tenantInterceptor: TenantInterceptor
) : WebMvcConfigurer {
    
    override fun addInterceptors(registry: InterceptorRegistry) {
        registry.addInterceptor(tenantInterceptor)
            .addPathPatterns("/v1/**")
            .excludePathPatterns(
                "/v1/auth/**",
                "/actuator/**",
                "/swagger-ui/**",
                "/v3/api-docs/**"
            )
    }
}