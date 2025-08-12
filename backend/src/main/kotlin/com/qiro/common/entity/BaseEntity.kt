package com.qiro.common.entity

import jakarta.persistence.*
import org.springframework.data.annotation.CreatedDate
import org.springframework.data.annotation.LastModifiedDate
import org.springframework.data.jpa.domain.support.AuditingEntityListener
import java.time.LocalDateTime
import java.util.*

/**
 * 공통 엔티티 기본 클래스
 */
@MappedSuperclass
@EntityListeners(AuditingEntityListener::class)
abstract class BaseEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false)
    open val id: UUID = UUID.randomUUID()
    
    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: LocalDateTime? = null
        protected set
    
    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    var updatedAt: LocalDateTime? = null
        protected set
    
    @Column(name = "created_by")
    var createdBy: UUID? = null
    
    @Column(name = "updated_by")
    var updatedBy: UUID? = null
}