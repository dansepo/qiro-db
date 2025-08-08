package com.qiro.common.exception

/**
 * 비즈니스 로직 예외 클래스
 */
class BusinessException(
    val errorCode: ErrorCode,
    override val message: String = errorCode.message,
    override val cause: Throwable? = null
) : RuntimeException(message, cause) {
    
    constructor(errorCode: ErrorCode, cause: Throwable) : this(errorCode, errorCode.message, cause)
}