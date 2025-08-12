package com.qiro.domain.workorder.entity

/**
 * 작업 상태
 */
enum class WorkStatus(val displayName: String) {
    DRAFT("임시저장"),
    PENDING("대기"),
    SCHEDULED("예정"),
    APPROVED("승인"),
    IN_PROGRESS("진행중"),
    PAUSED("일시정지"),
    COMPLETED("완료"),
    CANCELLED("취소"),
    REJECTED("거부");
    
    /**
     * 상태 전환 가능 여부 확인
     */
    fun canTransitionTo(newStatus: WorkStatus): Boolean {
        return when (this) {
            DRAFT -> newStatus in listOf(PENDING, CANCELLED)
            PENDING -> newStatus in listOf(SCHEDULED, APPROVED, REJECTED, CANCELLED)
            SCHEDULED -> newStatus in listOf(APPROVED, IN_PROGRESS, CANCELLED)
            APPROVED -> newStatus in listOf(IN_PROGRESS, CANCELLED)
            IN_PROGRESS -> newStatus in listOf(PAUSED, COMPLETED, CANCELLED)
            PAUSED -> newStatus in listOf(IN_PROGRESS, CANCELLED)
            COMPLETED -> false // 완료된 작업은 상태 변경 불가
            CANCELLED -> false // 취소된 작업은 상태 변경 불가
            REJECTED -> newStatus in listOf(PENDING) // 거부된 작업은 다시 대기로만 가능
        }
    }
}