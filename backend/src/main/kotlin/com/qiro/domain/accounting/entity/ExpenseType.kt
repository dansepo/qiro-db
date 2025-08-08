package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 지출 유형 엔티티
 * 관리비, 공과금, 시설 관리비 등 지출의 유형을 관리
 */
@Entity
@Table(
    name = "expense_types",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(columnNames = ["company_id", "type_code"])
    ]
)
data class ExpenseType(
    @Id
    @Column(name = "expense_type_id")
    val expenseTypeId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @Column(name = "type_code", nullable = false, length = 20)
    val typeCode: String,

    @Column(name = "type_name", nullable = false, length = 100)
    val typeName: String,

    @Column(name = "description", columnDefinition = "TEXT")
    val description: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "category", nullable = false, length = 50)
    val category: Category,

    @Column(name = "is_recurring")
    val isRecurring: Boolean = false,

    @Column(name = "requires_approval")
    val requiresApproval: Boolean = true,

    @Column(name = "approval_limit", precision = 15, scale = 2)
    val approvalLimit: BigDecimal? = null,

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
     * 지출 카테고리 열거형
     */
    enum class Category(val displayName: String) {
        MAINTENANCE("유지보수"),
        UTILITIES("공과금"),
        MANAGEMENT("관리비"),
        FACILITY("시설비"),
        ADMINISTRATIVE("관리운영비"),
        OTHER("기타")
    }

    /**
     * 지출 유형 코드 열거형
     */
    enum class TypeCode(val code: String, val displayName: String, val category: Category) {
        MAINTENANCE_COST("MAINTENANCE_COST", "유지보수비", Category.MAINTENANCE),
        UTILITY_BILL("UTILITY_BILL", "공과금", Category.UTILITIES),
        MANAGEMENT_FEE("MANAGEMENT_FEE", "관리비", Category.MANAGEMENT),
        FACILITY_REPAIR("FACILITY_REPAIR", "시설수리비", Category.FACILITY),
        CLEANING_COST("CLEANING_COST", "청소비", Category.MANAGEMENT),
        SECURITY_COST("SECURITY_COST", "경비비", Category.MANAGEMENT),
        INSURANCE_PREMIUM("INSURANCE_PREMIUM", "보험료", Category.ADMINISTRATIVE),
        OFFICE_SUPPLIES("OFFICE_SUPPLIES", "사무용품비", Category.ADMINISTRATIVE),
        OTHER("OTHER", "기타", Category.OTHER);

        companion object {
            fun fromCode(code: String): TypeCode? = values().find { it.code == code }
        }
    }

    /**
     * 승인이 필요한지 확인
     */
    fun needsApproval(amount: BigDecimal): Boolean {
        if (!requiresApproval) return false
        return approvalLimit == null || amount > approvalLimit
    }
}