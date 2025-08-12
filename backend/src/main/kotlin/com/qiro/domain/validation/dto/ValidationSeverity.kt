package com.qiro.domain.validation.dto

/**
 * 검증 심각도
 */
enum class ValidationSeverity(val displayName: String, val level: Int) {
    INFO("정보", 1),
    WARNING("경고", 2),
    ERROR("오류", 3),
    CRITICAL("치명적", 4)
}