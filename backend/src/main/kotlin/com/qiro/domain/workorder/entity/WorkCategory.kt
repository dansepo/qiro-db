package com.qiro.domain.workorder.entity

/**
 * 작업 카테고리
 * 작업의 성격에 따른 분류
 */
enum class WorkCategory(
    val displayName: String,
    val description: String
) {
    PREVENTIVE("예방정비", "정기적인 예방 정비 작업"),
    CORRECTIVE("수정정비", "고장 발생 후 수리 작업"),
    EMERGENCY("응급정비", "긴급 상황 대응 작업"),
    IMPROVEMENT("개선작업", "시설 개선 및 업그레이드 작업"),
    INSPECTION("점검작업", "정기 점검 및 검사 작업");
    
    companion object {
        fun fromDisplayName(displayName: String): WorkCategory? {
            return values().find { it.displayName == displayName }
        }
    }
}