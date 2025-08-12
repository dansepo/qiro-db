package com.qiro.domain.accounting.entity

/**
 * 수입 상태 enum
 */
enum class IncomeStatus(val displayName: String) {
    PENDING("대기중"), // 대기중
    CONFIRMED("확정"), // 확정
    CANCELLED("취소"); // 취소

    companion object {
        fun fromCode(code: String): IncomeStatus? {
            return values().find { it.name == code }
        }
    }
}