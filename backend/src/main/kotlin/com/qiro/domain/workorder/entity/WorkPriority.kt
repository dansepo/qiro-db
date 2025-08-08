package com.qiro.domain.workorder.entity

/**
 * 작업 우선순위
 * 작업의 중요도 및 긴급도에 따른 우선순위
 */
enum class WorkPriority(
    val displayName: String,
    val description: String,
    val responseTimeHours: Int,
    val sortOrder: Int
) {
    LOW("낮음", "일반적인 작업, 계획된 시간 내 처리", 72, 1),
    MEDIUM("보통", "표준 우선순위 작업", 48, 2),
    HIGH("높음", "중요한 작업, 빠른 처리 필요", 24, 3),
    URGENT("긴급", "긴급한 작업, 즉시 처리 필요", 4, 4),
    EMERGENCY("응급", "응급 상황, 최우선 처리", 1, 5);
    
    companion object {
        fun fromDisplayName(displayName: String): WorkPriority? {
            return values().find { it.displayName == displayName }
        }
        
        /**
         * 우선순위 순으로 정렬된 목록 반환
         */
        fun getSortedByPriority(): List<WorkPriority> {
            return values().sortedByDescending { it.sortOrder }
        }
        
        /**
         * 고장 신고 우선순위에서 작업 우선순위로 변환
         */
        fun fromFaultPriority(faultPriority: String): WorkPriority {
            return when (faultPriority.uppercase()) {
                "LOW" -> LOW
                "MEDIUM", "NORMAL" -> MEDIUM
                "HIGH" -> HIGH
                "URGENT" -> URGENT
                "EMERGENCY", "CRITICAL" -> EMERGENCY
                else -> MEDIUM
            }
        }
    }
}