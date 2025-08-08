package com.qiro.domain.workorder.entity

/**
 * 작업 긴급도
 * 작업의 시급성 정도
 */
enum class WorkUrgency(
    val displayName: String,
    val description: String,
    val maxResponseHours: Int
) {
    LOW("낮음", "시급하지 않은 작업", 168), // 1주일
    NORMAL("보통", "일반적인 긴급도", 72), // 3일
    HIGH("높음", "빠른 대응이 필요한 작업", 24), // 1일
    CRITICAL("매우높음", "즉시 대응이 필요한 작업", 4); // 4시간
    
    companion object {
        fun fromDisplayName(displayName: String): WorkUrgency? {
            return values().find { it.displayName == displayName }
        }
        
        /**
         * 우선순위와 긴급도의 조합으로 최종 처리 순서 결정
         */
        fun calculateProcessingOrder(priority: WorkPriority, urgency: WorkUrgency): Int {
            return priority.sortOrder * 10 + urgency.ordinal
        }
    }
}