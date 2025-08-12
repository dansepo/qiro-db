package com.qiro.domain.accounting.entity

/**
 * 승인 상태 enum
 */
enum class ApprovalStatus(val displayName: String) {
    PENDING("승인대기"), // 승인 대기
    APPROVED("승인완료"), // 승인 완료
    REJECTED("승인거부"); // 승인 거부

    companion object {
        fun fromCode(code: String): ApprovalStatus? {
            return values().find { it.name == code }
        }
    }
}