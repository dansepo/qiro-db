package com.qiro.common.exception

/**
 * 비즈니스 로직 예외
 */
class BusinessException(
    val errorCode: ErrorCode,
    message: String? = null,
    cause: Throwable? = null
) : RuntimeException(message ?: errorCode.message, cause) {
    
    constructor(errorCode: ErrorCode) : this(errorCode, null, null)
    constructor(errorCode: ErrorCode, cause: Throwable) : this(errorCode, null, cause)
}