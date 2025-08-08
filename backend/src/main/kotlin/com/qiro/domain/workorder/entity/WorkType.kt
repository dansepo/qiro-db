package com.qiro.domain.workorder.entity

/**
 * 작업 유형
 * 작업 분야별 세부 분류
 */
enum class WorkType(
    val displayName: String,
    val description: String
) {
    ELECTRICAL("전기", "전기 설비 관련 작업"),
    PLUMBING("배관", "급수, 배수, 가스 배관 작업"),
    HVAC("공조", "냉난방, 환기 시설 작업"),
    ELEVATOR("승강기", "엘리베이터, 에스컬레이터 작업"),
    FIRE_SAFETY("소방", "소방 설비 및 안전 시설 작업"),
    SECURITY("보안", "보안 시설 및 출입 통제 작업"),
    STRUCTURAL("구조", "건물 구조 및 외벽 작업"),
    APPLIANCE("기기", "각종 기기 및 장비 작업"),
    LIGHTING("조명", "조명 시설 작업"),
    CLEANING("청소", "청소 및 위생 관련 작업"),
    OTHER("기타", "기타 작업");
    
    companion object {
        fun fromDisplayName(displayName: String): WorkType? {
            return values().find { it.displayName == displayName }
        }
        
        /**
         * 카테고리별 추천 작업 유형
         */
        fun getRecommendedTypes(category: WorkCategory): List<WorkType> {
            return when (category) {
                WorkCategory.PREVENTIVE -> listOf(HVAC, ELEVATOR, FIRE_SAFETY, ELECTRICAL, PLUMBING)
                WorkCategory.CORRECTIVE -> listOf(ELECTRICAL, PLUMBING, HVAC, APPLIANCE, LIGHTING)
                WorkCategory.EMERGENCY -> listOf(ELECTRICAL, PLUMBING, FIRE_SAFETY, ELEVATOR, SECURITY)
                WorkCategory.IMPROVEMENT -> listOf(STRUCTURAL, LIGHTING, SECURITY, APPLIANCE)
                WorkCategory.INSPECTION -> listOf(FIRE_SAFETY, ELEVATOR, HVAC, ELECTRICAL, STRUCTURAL)
            }
        }
    }
}