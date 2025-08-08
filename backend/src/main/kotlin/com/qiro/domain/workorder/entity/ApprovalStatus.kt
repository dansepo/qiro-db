package com.qiro.domain.workorder.entity

/**
 * 승인 상태
 * 작업 지시서의 승인 진행 상태
 */
enum class ApprovalStatus(
    val displayName: String,
    val description: String
) {
    PENDING("승인대기", "승인 대기 중"),
    APPROVED("승인완료", "승인 완료"),
    REJECTED("승인거부", "승인 거부됨"),
    REQUIRES_REVISION("수정요청", "수정 후 재승인 필요");
    
    companion object {
        fun fromDisplayName(displayName: String): ApprovalStatus? {
            return values().find { it.displayName == displayName }
        }
    }
}