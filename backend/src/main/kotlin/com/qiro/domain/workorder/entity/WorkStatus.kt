package com.qiro.domain.workorder.entity

/**
 * 작업 상태
 * 작업 지시서의 진행 상태
 */
enum class WorkStatus(
    val displayName: String,
    val description: String,
    val isActive: Boolean,
    val allowedTransitions: List<String>
) {
    PENDING(
        "대기중", 
        "작업 지시서가 생성되어 승인 대기 중",
        true,
        listOf("APPROVED", "REJECTED", "CANCELLED")
    ),
    APPROVED(
        "승인됨", 
        "작업이 승인되어 배정 대기 중",
        true,
        listOf("SCHEDULED", "CANCELLED")
    ),
    SCHEDULED(
        "예정됨", 
        "작업자가 배정되어 시작 대기 중",
        true,
        listOf("IN_PROGRESS", "ON_HOLD", "CANCELLED")
    ),
    IN_PROGRESS(
        "진행중", 
        "작업이 진행 중",
        true,
        listOf("COMPLETED", "ON_HOLD", "CANCELLED")
    ),
    ON_HOLD(
        "보류", 
        "작업이 일시 중단됨",
        true,
        listOf("IN_PROGRESS", "CANCELLED")
    ),
    COMPLETED(
        "완료", 
        "작업이 완료됨",
        false,
        emptyList()
    ),
    CANCELLED(
        "취소", 
        "작업이 취소됨",
        false,
        emptyList()
    ),
    REJECTED(
        "거부", 
        "작업이 거부됨",
        false,
        listOf("PENDING")
    );
    
    companion object {
        fun fromDisplayName(displayName: String): WorkStatus? {
            return values().find { it.displayName == displayName }
        }
        
        /**
         * 활성 상태 목록 반환
         */
        fun getActiveStatuses(): List<WorkStatus> {
            return values().filter { it.isActive }
        }
        
        /**
         * 완료된 상태 목록 반환
         */
        fun getCompletedStatuses(): List<WorkStatus> {
            return listOf(COMPLETED, CANCELLED, REJECTED)
        }
        
        /**
         * 상태 전환 가능 여부 확인
         */
        fun canTransitionTo(from: WorkStatus, to: WorkStatus): Boolean {
            return from.allowedTransitions.contains(to.name)
        }
        
        /**
         * 다음 가능한 상태들 반환
         */
        fun getNextPossibleStatuses(current: WorkStatus): List<WorkStatus> {
            return current.allowedTransitions.mapNotNull { statusName ->
                values().find { it.name == statusName }
            }
        }
    }
}