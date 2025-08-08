package com.qiro.common.exception

import com.qiro.common.dto.ApiResponse
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.AccessDeniedException
import org.springframework.security.authentication.BadCredentialsException
import org.springframework.validation.FieldError
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import org.springframework.web.context.request.WebRequest

@RestControllerAdvice
class GlobalExceptionHandler {
    
    private val logger = LoggerFactory.getLogger(GlobalExceptionHandler::class.java)
    
    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(
        ex: MethodArgumentNotValidException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        val errors = ex.bindingResult.allErrors.map { error ->
            when (error) {
                is FieldError -> "${error.field}: ${error.defaultMessage}"
                else -> error.defaultMessage ?: "알 수 없는 검증 오류"
            }
        }
        
        logger.warn("Validation failed: {}", errors)
        
        return ResponseEntity.badRequest().body(
            ApiResponse.error("입력값 검증에 실패했습니다", errors)
        )
    }
    
    @ExceptionHandler(EntityNotFoundException::class)
    fun handleEntityNotFound(
        ex: EntityNotFoundException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Entity not found: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(
            ApiResponse.error(ex.message ?: "요청한 리소스를 찾을 수 없습니다")
        )
    }
    
    @ExceptionHandler(DuplicateEntityException::class)
    fun handleDuplicateEntity(
        ex: DuplicateEntityException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Duplicate entity: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.CONFLICT).body(
            ApiResponse.error(ex.message ?: "중복된 데이터가 존재합니다")
        )
    }
    
    @ExceptionHandler(InvalidBusinessRuleException::class)
    fun handleInvalidBusinessRule(
        ex: InvalidBusinessRuleException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Business rule violation: {}", ex.message)
        
        return ResponseEntity.badRequest().body(
            ApiResponse.error(ex.message ?: "비즈니스 규칙에 위반됩니다")
        )
    }
    
    @ExceptionHandler(InsufficientPermissionException::class)
    fun handleInsufficientPermission(
        ex: InsufficientPermissionException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Insufficient permission: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            ApiResponse.error(ex.message ?: "접근 권한이 없습니다")
        )
    }
    
    @ExceptionHandler(AccessDeniedException::class)
    fun handleAccessDenied(
        ex: AccessDeniedException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Access denied: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(
            ApiResponse.error("접근 권한이 없습니다")
        )
    }
    
    @ExceptionHandler(BadCredentialsException::class)
    fun handleBadCredentials(
        ex: BadCredentialsException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Bad credentials: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
            ApiResponse.error("인증에 실패했습니다")
        )
    }
    
    @ExceptionHandler(BillingProcessException::class)
    fun handleBillingProcess(
        ex: BillingProcessException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Billing process error: {}", ex.message, ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiResponse.error(ex.message ?: "관리비 처리 중 오류가 발생했습니다")
        )
    }
    
    @ExceptionHandler(PaymentProcessingException::class)
    fun handlePaymentProcessing(
        ex: PaymentProcessingException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Payment processing error: {}", ex.message, ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiResponse.error(ex.message ?: "결제 처리 중 오류가 발생했습니다")
        )
    }
    
    @ExceptionHandler(ContractValidationException::class)
    fun handleContractValidation(
        ex: ContractValidationException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Contract validation error: {}", ex.message)
        
        return ResponseEntity.badRequest().body(
            ApiResponse.error(ex.message ?: "계약 검증에 실패했습니다")
        )
    }
    
    @ExceptionHandler(ContractConflictException::class)
    fun handleContractConflict(
        ex: ContractConflictException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.warn("Contract conflict: {}", ex.message)
        
        return ResponseEntity.status(HttpStatus.CONFLICT).body(
            ApiResponse.error(ex.message ?: "계약 충돌이 발생했습니다")
        )
    }
    
    @ExceptionHandler(IllegalStateException::class)
    fun handleIllegalState(
        ex: IllegalStateException,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Illegal state: {}", ex.message, ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiResponse.error("시스템 상태 오류가 발생했습니다")
        )
    }
    
    @ExceptionHandler(Exception::class)
    fun handleGeneral(
        ex: Exception,
        request: WebRequest
    ): ResponseEntity<ApiResponse<Nothing>> {
        logger.error("Unexpected error: {}", ex.message, ex)
        
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
            ApiResponse.error("서버 내부 오류가 발생했습니다")
        )
    }
}