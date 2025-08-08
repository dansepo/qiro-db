package com.qiro.common.response

import com.fasterxml.jackson.annotation.JsonInclude
import java.time.LocalDateTime

/**
 * API 응답 공통 형식
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val message: String? = null,
    val error: ErrorResponse? = null,
    val timestamp: LocalDateTime = LocalDateTime.now()
) {
    companion object {
        fun <T> success(data: T, message: String? = null): ApiResponse<T> {
            return ApiResponse(success = true, data = data, message = message)
        }
        
        fun success(message: String? = null): ApiResponse<Unit> {
            return ApiResponse(success = true, data = Unit, message = message)
        }
        
        fun <T> error(errorCode: String, message: String): ApiResponse<T> {
            return ApiResponse(
                success = false,
                error = ErrorResponse(errorCode, message)
            )
        }
        
        fun <T> error(errorResponse: ErrorResponse): ApiResponse<T> {
            return ApiResponse(
                success = false,
                error = errorResponse
            )
        }
    }
}

/**
 * 에러 응답 형식
 */
data class ErrorResponse(
    val code: String,
    val message: String,
    val details: Map<String, Any>? = null
)