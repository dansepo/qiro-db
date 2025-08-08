package com.qiro.domain.validation.dto

import java.time.LocalDateTime
import java.util.*

/**
 * 검증 결과 DTO
 */
data class ValidationResult(
    val isValid: Boolean,
    val errors: List<ValidationError> = emptyList(),
    val warnings: List<ValidationWarning> = emptyList(),
    val validatedAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 오류가 있는지 확인
     */
    fun hasErrors(): Boolean = errors.isNotEmpty()
    
    /**
     * 경고가 있는지 확인
     */
    fun hasWarnings(): Boolean = warnings.isNotEmpty()
    
    /**
     * 첫 번째 오류 메시지 반환
     */
    fun getFirstErrorMessage(): String? = errors.firstOrNull()?.message
    
    /**
     * 모든 오류 메시지 반환
     */
    fun getAllErrorMessages(): List<String> = errors.map { it.message }
}

/**
 * 검증 오류 DTO
 */
data class ValidationError(
    val field: String,
    val message: String,
    val code: String,
    val rejectedValue: Any? = null,
    val severity: ValidationSeverity = ValidationSeverity.ERROR
)

/**
 * 검증 경고 DTO
 */
data class ValidationWarning(
    val field: String,
    val message: String,
    val code: String,
    val currentValue: Any? = null,
    val suggestedValue: Any? = null
)

/**
 * 검증 심각도 열거형
 */
enum class ValidationSeverity {
    INFO,       // 정보
    WARNING,    // 경고
    ERROR,      // 오류
    CRITICAL    // 치명적 오류
}

/**
 * 비즈니스 규칙 검증 결과 DTO
 */
data class BusinessRuleValidationResult(
    val ruleName: String,
    val isValid: Boolean,
    val message: String,
    val details: Map<String, Any> = emptyMap(),
    val validatedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * 데이터 무결성 검증 요청 DTO
 */
data class DataIntegrityCheckRequest(
    val entityType: String,
    val entityId: UUID?,
    val data: Map<String, Any>,
    val operation: DataOperation,
    val userId: UUID,
    val companyId: UUID
)

/**
 * 데이터 작업 유형 열거형
 */
enum class DataOperation {
    CREATE,     // 생성
    UPDATE,     // 수정
    DELETE,     // 삭제
    BULK_CREATE,// 대량 생성
    BULK_UPDATE,// 대량 수정
    BULK_DELETE // 대량 삭제
}

/**
 * 중복 검사 결과 DTO
 */
data class DuplicateCheckResult(
    val isDuplicate: Boolean,
    val duplicateField: String?,
    val duplicateValue: Any?,
    val existingEntityId: UUID?,
    val message: String?
)

/**
 * 참조 무결성 검증 결과 DTO
 */
data class ReferentialIntegrityResult(
    val isValid: Boolean,
    val missingReferences: List<MissingReference> = emptyList(),
    val orphanedReferences: List<OrphanedReference> = emptyList()
)

/**
 * 누락된 참조 DTO
 */
data class MissingReference(
    val field: String,
    val referencedTable: String,
    val referencedId: UUID,
    val message: String
)

/**
 * 고아 참조 DTO
 */
data class OrphanedReference(
    val field: String,
    val referencingTable: String,
    val referencingId: UUID,
    val message: String
)

/**
 * 데이터 일관성 검증 결과 DTO
 */
data class DataConsistencyResult(
    val isConsistent: Boolean,
    val inconsistencies: List<DataInconsistency> = emptyList()
)

/**
 * 데이터 불일치 DTO
 */
data class DataInconsistency(
    val field: String,
    val expectedValue: Any?,
    val actualValue: Any?,
    val message: String,
    val severity: ValidationSeverity = ValidationSeverity.ERROR
)

/**
 * 비즈니스 규칙 DTO
 */
data class BusinessRule(
    val ruleId: String,
    val ruleName: String,
    val description: String,
    val entityType: String,
    val isActive: Boolean = true,
    val priority: Int = 0,
    val conditions: List<RuleCondition> = emptyList(),
    val actions: List<RuleAction> = emptyList()
)

/**
 * 규칙 조건 DTO
 */
data class RuleCondition(
    val field: String,
    val operator: RuleOperator,
    val value: Any?,
    val logicalOperator: LogicalOperator = LogicalOperator.AND
)

/**
 * 규칙 액션 DTO
 */
data class RuleAction(
    val actionType: RuleActionType,
    val message: String,
    val parameters: Map<String, Any> = emptyMap()
)

/**
 * 규칙 연산자 열거형
 */
enum class RuleOperator {
    EQUALS,             // 같음
    NOT_EQUALS,         // 같지 않음
    GREATER_THAN,       // 초과
    GREATER_THAN_OR_EQUAL, // 이상
    LESS_THAN,          // 미만
    LESS_THAN_OR_EQUAL, // 이하
    CONTAINS,           // 포함
    NOT_CONTAINS,       // 포함하지 않음
    STARTS_WITH,        // 시작
    ENDS_WITH,          // 끝
    IS_NULL,            // NULL
    IS_NOT_NULL,        // NOT NULL
    IN,                 // 목록에 포함
    NOT_IN,             // 목록에 포함되지 않음
    REGEX,              // 정규식 매치
    BETWEEN             // 범위
}

/**
 * 논리 연산자 열거형
 */
enum class LogicalOperator {
    AND,    // 그리고
    OR,     // 또는
    NOT     // 아님
}

/**
 * 규칙 액션 유형 열거형
 */
enum class RuleActionType {
    REJECT,         // 거부
    WARN,           // 경고
    MODIFY,         // 수정
    LOG,            // 로그 기록
    NOTIFY,         // 알림 발송
    APPROVE_REQUIRED // 승인 필요
}

/**
 * 검증 컨텍스트 DTO
 */
data class ValidationContext(
    val userId: UUID,
    val companyId: UUID,
    val operation: DataOperation,
    val entityType: String,
    val entityId: UUID? = null,
    val additionalData: Map<String, Any> = emptyMap(),
    val skipRules: List<String> = emptyList()
)

/**
 * 검증 설정 DTO
 */
data class ValidationConfig(
    val enableStrictMode: Boolean = false,
    val enableWarnings: Boolean = true,
    val maxErrorCount: Int = 10,
    val enableBusinessRules: Boolean = true,
    val enableReferentialIntegrity: Boolean = true,
    val enableDataConsistency: Boolean = true,
    val customRules: List<String> = emptyList()
)