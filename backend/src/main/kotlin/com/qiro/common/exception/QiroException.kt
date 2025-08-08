package com.qiro.common.exception

/**
 * QIRO 시스템의 기본 예외 클래스
 */
abstract class QiroException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)

/**
 * 엔티티를 찾을 수 없을 때 발생하는 예외
 */
class EntityNotFoundException(message: String) : QiroException(message)

/**
 * 중복된 엔티티가 존재할 때 발생하는 예외
 */
class DuplicateEntityException(message: String) : QiroException(message)

/**
 * 비즈니스 규칙 위반 시 발생하는 예외
 */
class InvalidBusinessRuleException(message: String) : QiroException(message)

/**
 * 권한이 부족할 때 발생하는 예외
 */
class InsufficientPermissionException(message: String) : QiroException(message)

/**
 * 관리비 처리 관련 예외
 */
class BillingProcessException(message: String, cause: Throwable? = null) : QiroException(message, cause)

/**
 * 유효하지 않은 청구 기간 예외
 */
class InvalidBillingPeriodException(message: String) : QiroException(message)

/**
 * 결제 처리 예외
 */
class PaymentProcessingException(message: String, cause: Throwable? = null) : QiroException(message, cause)

/**
 * 계약 검증 예외
 */
class ContractValidationException(message: String) : QiroException(message)

/**
 * 계약 충돌 예외
 */
class ContractConflictException(message: String) : QiroException(message)