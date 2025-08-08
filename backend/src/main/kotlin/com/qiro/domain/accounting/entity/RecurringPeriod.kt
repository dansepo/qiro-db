package com.qiro.domain.accounting.entity

/**
 * 정기 처리 주기 열거형
 */
enum class RecurringPeriod(val code: String, val displayName: String) {
    MONTHLY("MONTHLY", "월별"),
    QUARTERLY("QUARTERLY", "분기별"),
    YEARLY("YEARLY", "연별");

    companion object {
        fun fromCode(code: String): RecurringPeriod? = values().find { it.code == code }
    }
}