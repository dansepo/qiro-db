package com.qiro.domain.accounting.entity

/**
 * 지출 기록 상태 열거형
 */
enum class ExpenseStatus(val code: String, val displayName: String) {
    PENDING("PENDING", "대기중"),
    APPROVED("APPROVED", "승인됨"),
    PAID("PAID", "지급완료"),
    CANCELLED("CANCELLED", "취소됨");

    companion object {
        fun fromCode(code: String): ExpenseStatus? = values().find { it.code == code }
    }
}