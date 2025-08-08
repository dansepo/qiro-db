package com.qiro.domain.accounting.entity

/**
 * 수입 기록 상태 열거형
 */
enum class IncomeStatus(val code: String, val displayName: String) {
    PENDING("PENDING", "대기중"),
    CONFIRMED("CONFIRMED", "확정됨"),
    CANCELLED("CANCELLED", "취소됨");

    companion object {
        fun fromCode(code: String): IncomeStatus? = values().find { it.code == code }
    }
}