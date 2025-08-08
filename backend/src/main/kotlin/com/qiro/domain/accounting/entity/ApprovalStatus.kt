package com.qiro.domain.accounting.entity

/**
 * 승인 상태 열거형
 */
enum class ApprovalStatus(val code: String, val displayName: String) {
    PENDING("PENDING", "승인 대기"),
    APPROVED("APPROVED", "승인됨"),
    REJECTED("REJECTED", "거부됨");

    companion object {
        fun fromCode(code: String): ApprovalStatus? = values().find { it.code == code }
    }
}