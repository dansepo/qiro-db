package com.qiro.domain.accounting.entity

/**
 * 지출 상태 enum
 */
enum class ExpenseStatus(val displayName: String) {
    PENDING("대기중"), // 대기중
    APPROVED("승인됨"), // 승인됨
    PAID("지급완료"), // 지급완료
    CANCELLED("취소"); // 취소

    companion object {
        fun fromCode(code: String): ExpenseStatus? {
            return values().find { it.name == code }
        }
    }
}