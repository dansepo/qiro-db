package com.qiro.domain.accounting.entity

/**
 * 연체료 계산 방식 열거형
 */
enum class LateFeeCalculationType(val code: String, val displayName: String) {
    PERCENTAGE("PERCENTAGE", "비율"),
    FIXED_AMOUNT("FIXED_AMOUNT", "고정금액"),
    DAILY_RATE("DAILY_RATE", "일할계산");

    companion object {
        fun fromCode(code: String): LateFeeCalculationType? = values().find { it.code == code }
    }
}