package com.qiro.common.tenant

import org.springframework.stereotype.Component
import java.util.*

@Component
class TenantContext {
    
    private val tenantHolder = ThreadLocal<UUID>()
    
    fun setCurrentCompanyId(companyId: UUID) {
        tenantHolder.set(companyId)
    }
    
    fun getCurrentCompanyId(): UUID {
        return tenantHolder.get() 
            ?: throw IllegalStateException("테넌트 컨텍스트가 설정되지 않았습니다")
    }
    
    fun getCurrentCompanyIdOrNull(): UUID? {
        return tenantHolder.get()
    }
    
    fun clear() {
        tenantHolder.remove()
    }
    
    fun hasCurrentCompanyId(): Boolean {
        return tenantHolder.get() != null
    }
}