package com.qiro.common.entity

import jakarta.persistence.Column
import jakarta.persistence.MappedSuperclass
import java.util.*

@MappedSuperclass
abstract class TenantAwareEntity : BaseEntity() {
    
    @Column(name = "company_id", nullable = false, updatable = false)
    open lateinit var companyId: UUID
        protected set
    
    fun setCompanyId(companyId: UUID) {
        this.companyId = companyId
    }
}