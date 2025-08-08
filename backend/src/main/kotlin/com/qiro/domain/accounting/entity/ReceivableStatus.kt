package com.qiro.domain.accounting.entity

/**
 * 미수금 상태 열거형
 */
enum class ReceivableStatus(val code: String, val displayName: String) {
    OUTSTANDING("OUTSTANDING", "미수"),
    PARTIALLY_PAID("PARTIALLY_PAID", "부분 납부"),
    FULLY_PAID("FULLY_PAID", "완납"),
    WRITTEN_OFF("WRITTEN_OFF", "대손처리");

    companion object {
        fun fromCode(code: String): ReceivableStatus? = values().find { it.code == code }
    }
}