package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 수입 유형 엔티티
 * 관리비, 임대료 등 수입의 유형을 관리
 */
@Entity
@Table(
    name = "income_types",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "type_code"])
    ]
)
data class IncomeType(
    @Id
    @Column(name = "income_type_id")
    val incomeTypeId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "type_code", nullable = false, length = 20)
    val typeCode: String,

    @Column(name = "type_name", nullable = false, length = 100)
    val typeName: String,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Column(name = "is_recurring")
    val isRecurring: Boolean = false,

    @Column(name = "default_account_id")
    val defaultAccountId: UUID? = null,

    @Column(name = "is_active")
    val isActive: Boolean = true,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 수입 유형 코드 열거형
     */
    enum class TypeCode(val code: String, val displayName: String) {
        MAINTENANCE_FEE("MAINTENANCE_FEE", "관리비"),
        RENT("RENT", "임대료"),
        DEPOSIT("DEPOSIT", "보증금"),
        PARKING_FEE("PARKING_FEE", "주차비"),
        UTILITY_FEE("UTILITY_FEE", "공과금"),
        LATE_FEE("LATE_FEE", "연체료"),
        OTHER("OTHER", "기타");

        companion object {
            fun fromCode(code: String): TypeCode? = values().find { it.code == code }
        }
    }
}