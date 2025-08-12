package com.qiro.common.dto

import com.fasterxml.jackson.annotation.JsonInclude
import java.time.LocalDateTime

/**
 * API 응답 래퍼 클래스
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val errorCode: String? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
) {
    companion object {
        fun <T> success(data: T): ApiResponse<T> {
            return ApiResponse(success = true, data = data)
        }
        
        fun <T> success(data: T, message: String): ApiResponse<T> {
            return ApiResponse(success = true, data = data, message = message)
        }
        
        fun <T> error(message: String): ApiResponse<T> {
            return ApiResponse(success = false, message = message)
        }
        
        fun <T> error(message: String, errorCode: String): ApiResponse<T> {
            return ApiResponse(success = false, message = message, errorCode = errorCode)
        }
    }
}