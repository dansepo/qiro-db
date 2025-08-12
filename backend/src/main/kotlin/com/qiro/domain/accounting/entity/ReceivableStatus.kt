package com.qiro.domain.accounting.entity

/**
 * 미수금 상태 enum
 */
enum class ReceivableStatus(val displayName: String) {
    OUTSTANDING("미수"), // 미수
    PARTIALLY_PAID("부분수납"), // 부분 수납
    FULLY_PAID("완납"), // 완납
    WRITTEN_OFF("손실처리"); // 손실 처리

    companion object {
        fun fromCode(code: String): ReceivableStatus? {
            return values().find { it.name == code }
        }
    }
}