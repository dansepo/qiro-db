package com.qiro.common.exception

import com.qiro.common.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.http.converter.HttpMessageNotReadableException
import org.springframework.validation.BindException
import org.springframework.web.HttpRequestMethodNotSupportedException
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.MissingServletRequestParameterException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException
import org.springframework.web.servlet.NoHandlerFoundException
import jakarta.validation.ConstraintViolationException

/**
 * 전역 예외 처리 핸들러
 */
@RestControllerAdvice
class GlobalExceptionHandler {

    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)

    /**
     * 비즈니스 예외 처리
     */
    @ExceptionHandler(BusinessException::class)
    fun handleBusinessException(ex: BusinessException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Business exception occurred: ${ex.message}", ex)
        
        val status = when (ex.errorCode) {
            ErrorCode.NOT_FOUND -> HttpStatus.NOT_FOUND
            ErrorCode.FORBIDDEN -> HttpStatus.FORBIDDEN
            ErrorCode.UNAUTHORIZED -> HttpStatus.UNAUTHORIZED
            ErrorCode.INVALID_REQUEST -> HttpStatus.BAD_REQUEST
            else -> HttpStatus.BAD_REQUEST
        }
        
        return ResponseEntity.status(status)
            .body(ApiResponse.error(ex.message ?: "알 수 없는 오류가 발생했습니다.", ex.errorCode.code))
    }

    /**
     * 유효성 검증 실패 처리
     */
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(ex: MethodArgumentNotValidException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Validation failed: ${ex.message}")
        
        val errors = ex.bindingResult.fieldErrors.map { error ->
            "${error.field}: ${error.defaultMessage}"
        }.joinToString(", ")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("VALIDATION_FAILED", "입력값 검증에 실패했습니다: $errors"))
    }    /**

     * 바인딩 예외 처리
     */
    @ExceptionHandler(BindException::class)
    fun handleBindException(ex: BindException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Binding failed: ${ex.message}")
        
        val errors = ex.bindingResult.fieldErrors.map { error ->
            "${error.field}: ${error.defaultMessage}"
        }.joinToString(", ")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("BINDING_FAILED", "데이터 바인딩에 실패했습니다: $errors"))
    }

    /**
     * 제약 조건 위반 처리
     */
    @ExceptionHandler(ConstraintViolationException::class)
    fun handleConstraintViolationException(ex: ConstraintViolationException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Constraint violation: ${ex.message}")
        
        val errors = ex.constraintViolations.map { violation ->
            "${violation.propertyPath}: ${violation.message}"
        }.joinToString(", ")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("CONSTRAINT_VIOLATION", "제약 조건 위반: $errors"))
    }

    /**
     * 데이터 무결성 위반 처리
     */
    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrityViolationException(ex: DataIntegrityViolationException): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Data integrity violation: ${ex.message}", ex)
        
        return ResponseEntity.status(HttpStatus.CONFLICT)
            .body(ApiResponse.error("DATA_INTEGRITY_VIOLATION", "데이터 무결성 위반이 발생했습니다."))
    }

    /**
     * HTTP 메시지 읽기 실패 처리
     */
    @ExceptionHandler(HttpMessageNotReadableException::class)
    fun handleHttpMessageNotReadableException(ex: HttpMessageNotReadableException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("HTTP message not readable: ${ex.message}")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("MESSAGE_NOT_READABLE", "요청 메시지를 읽을 수 없습니다."))
    }

    /**
     * 메서드 인자 타입 불일치 처리
     */
    @ExceptionHandler(MethodArgumentTypeMismatchException::class)
    fun handleMethodArgumentTypeMismatchException(ex: MethodArgumentTypeMismatchException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Method argument type mismatch: ${ex.message}")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("ARGUMENT_TYPE_MISMATCH", "인자 타입이 일치하지 않습니다: ${ex.name}"))
    }

    /**
     * 필수 파라미터 누락 처리
     */
    @ExceptionHandler(MissingServletRequestParameterException::class)
    fun handleMissingServletRequestParameterException(ex: MissingServletRequestParameterException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Missing request parameter: ${ex.message}")
        
        return ResponseEntity.badRequest()
            .body(ApiResponse.error("MISSING_PARAMETER", "필수 파라미터가 누락되었습니다: ${ex.parameterName}"))
    }

    /**
     * 지원하지 않는 HTTP 메서드 처리
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException::class)
    fun handleHttpRequestMethodNotSupportedException(ex: HttpRequestMethodNotSupportedException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("HTTP method not supported: ${ex.message}")
        
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
            .body(ApiResponse.error("METHOD_NOT_ALLOWED", "지원하지 않는 HTTP 메서드입니다: ${ex.method}"))
    }

    /**
     * 핸들러를 찾을 수 없는 경우 처리
     */
    @ExceptionHandler(NoHandlerFoundException::class)
    fun handleNoHandlerFoundException(ex: NoHandlerFoundException): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("No handler found: ${ex.message}")
        
        return ResponseEntity.notFound()
            .build()
    }

    /**
     * 일반적인 예외 처리
     */
    @ExceptionHandler(Exception::class)
    fun handleGenericException(ex: Exception): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Unexpected error occurred: ${ex.message}", ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
            .body(ApiResponse.error("INTERNAL_SERVER_ERROR", "서버 내부 오류가 발생했습니다."))
    }
}