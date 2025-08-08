package com.qiro.domain.workorder.entity

/**
 * 작업 단계
 * 작업의 세부 진행 단계
 */
enum class WorkPhase(
    val displayName: String,
    val description: String,
    val progressRange: IntRange
) {
    PLANNING("계획", "작업 계획 수립 단계", 0..10),
    PREPARATION("준비", "작업 준비 단계", 11..20),
    EXECUTION("실행", "작업 실행 단계", 21..80),
    TESTING("검증", "작업 결과 검증 단계", 81..95),
    COMPLETION("완료", "작업 완료 단계", 96..99),
    CLOSURE("종료", "작업 종료 및 정리 단계", 100..100);
    
    companion object {
        fun fromDisplayName(displayName: String): WorkPhase? {
            return values().find { it.displayName == displayName }
        }
        
        /**
         * 진행률에 따른 적절한 단계 반환
         */
        fun getPhaseByProgress(progress: Int): WorkPhase {
            return values().find { progress in it.progressRange } ?: PLANNING
        }
        
        /**
         * 다음 단계 반환
         */
        fun getNextPhase(current: WorkPhase): WorkPhase? {
            val currentIndex = values().indexOf(current)
            return if (currentIndex < values().size - 1) {
                values()[currentIndex + 1]
            } else {
                null
            }
        }
        
        /**
         * 이전 단계 반환
         */
        fun getPreviousPhase(current: WorkPhase): WorkPhase? {
            val currentIndex = values().indexOf(current)
            return if (currentIndex > 0) {
                values()[currentIndex - 1]
            } else {
                null
            }
        }
    }
}