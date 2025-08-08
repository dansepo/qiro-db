package com.qiro.domain.validation.service

import com.qiro.domain.validation.dto.*
import com.qiro.domain.validation.entity.BusinessRule
import com.qiro.domain.validation.entity.RuleExecutionLog
import com.qiro.domain.validation.entity.ValidationConfig
import com.qiro.domain.validation.repository.BusinessRuleRepository
import com.qiro.domain.validation.repository.RuleExecutionLogRepository
import com.qiro.domain.validation.repository.ValidationConfigRepository
import com.qiro.global.exception.BusinessException
import com.qiro.global.exception.ErrorCode
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 검증 서비스
 */
@Service
@Transactional(readOnly = true)
class ValidationService(
    private val businessRuleRepository: BusinessRuleRepository,
    private val validationConfigRepository: ValidationConfigRepository,
    private val ruleExecutionLogRepository: RuleExecutionLogRepository,
    private val businessRuleEngine: BusinessRuleEngine,
    private val dataIntegrityService: DataIntegrityService
) {

    /**
     * 엔티티 검증
     */
    fun validateEntity(
        entityType: String,
        entityData: Map<String, Any>,
        companyId: UUID,
        userId: UUID,
        operation: String = "CREATE"
    ): ValidationResultDto {
        val errors = mutableListOf<ValidationErrorDto>()
        val warnings = mutableListOf<ValidationWarningDto>()

        try {
            // 1. 기본 검증 설정 적용
            val validationConfigs = validationConfigRepository
                .findByCompanyIdAndEntityTypeAndIsActiveTrue(companyId, entityType)
            
            validationConfigs.forEach { config ->
                val fieldValue = entityData[config.field]
                val fieldErrors = validateField(config, fieldValue)
                errors.addAll(fieldErrors)
            }

            // 2. 비즈니스 규칙 적용
            val businessRules = businessRuleRepository
                .findByCompanyIdAndEntityTypeAndIsActiveTrueOrderByPriorityAsc(companyId, entityType)
            
            val context = RuleExecutionContextDto(
                entityType = entityType,
                entityId = entityData["id"] as? UUID ?: UUID.randomUUID(),
                entityData = entityData,
                operation = operation,
                userId = userId,
                companyId = companyId
            )

            businessRules.forEach { rule ->
                val ruleResult = businessRuleEngine.executeRule(rule, context)
                logRuleExecution(rule, context, ruleResult)
                
                if (!ruleResult.success) {
                    errors.add(
                        ValidationErrorDto(
                            field = "business_rule",
                            code = rule.ruleCode,
                            message = ruleResult.errorMessage ?: "비즈니스 규칙 위반",
                            severity = ValidationSeverity.ERROR
                        )
                    )
                }
            }

            return ValidationResultDto(
                isValid = errors.isEmpty(),
                errors = errors,
                warnings = warnings,
                validatedBy = userId.toString()
            )

        } catch (e: Exception) {
            throw BusinessException(ErrorCode.VALIDATION_ERROR, "검증 중 오류가 발생했습니다: ${e.message}")
        }
    }

    /**
     * 배치 검증
     */
    fun validateBatch(request: BatchValidationRequest, companyId: UUID, userId: UUID): BatchValidationResultDto {
        val results = mutableListOf<EntityValidationResultDto>()
        var validCount = 0
        var invalidCount = 0

        request.entities.forEachIndexed { index, entityData ->
            val validationResult = validateEntity(
                entityType = request.entityType,
                entityData = entityData,
                companyId = companyId,
                userId = userId
            )

            results.add(
                EntityValidationResultDto(
                    entityIndex = index,
                    entityId = entityData["id"] as? UUID,
                    validationResult = validationResult
                )
            )

            if (validationResult.isValid) {
                validCount++
            } else {
                invalidCount++
                if (request.stopOnFirstError) {
                    // 첫 번째 오류에서 중단
                    break
                }
            }
        }

        val summary = createValidationSummary(results)

        return BatchValidationResultDto(
            totalEntities = request.entities.size,
            validEntities = validCount,
            invalidEntities = invalidCount,
            results = results,
            summary = summary
        )
    }

    /**
     * 필드 검증
     */
    private fun validateField(config: ValidationConfig, fieldValue: Any?): List<ValidationErrorDto> {
        val errors = mutableListOf<ValidationErrorDto>()

        // 필수 필드 검증
        if (config.isRequired && (fieldValue == null || fieldValue.toString().isBlank())) {
            errors.add(
                ValidationErrorDto(
                    field = config.field,
                    code = "REQUIRED_FIELD",
                    message = config.errorMessage ?: "${config.field}은(는) 필수 입력 항목입니다",
                    rejectedValue = fieldValue
                )
            )
            return errors
        }

        if (fieldValue == null) return errors

        // 검증 타입별 처리
        when (config.validationType) {
            "NOT_EMPTY" -> {
                if (fieldValue.toString().isBlank()) {
                    errors.add(createValidationError(config, fieldValue, "빈 값은 허용되지 않습니다"))
                }
            }
            "MIN_LENGTH" -> {
                val minLength = getConfigValue(config, "minLength") as? Int ?: 0
                if (fieldValue.toString().length < minLength) {
                    errors.add(createValidationError(config, fieldValue, "최소 ${minLength}자 이상 입력해야 합니다"))
                }
            }
            "MAX_LENGTH" -> {
                val maxLength = getConfigValue(config, "maxLength") as? Int ?: Int.MAX_VALUE
                if (fieldValue.toString().length > maxLength) {
                    errors.add(createValidationError(config, fieldValue, "최대 ${maxLength}자까지 입력 가능합니다"))
                }
            }
            "PATTERN" -> {
                val pattern = getConfigValue(config, "pattern") as? String
                if (pattern != null && !fieldValue.toString().matches(Regex(pattern))) {
                    errors.add(createValidationError(config, fieldValue, "올바른 형식이 아닙니다"))
                }
            }
            "NUMBER_RANGE" -> {
                val min = getConfigValue(config, "min") as? Number
                val max = getConfigValue(config, "max") as? Number
                val numValue = fieldValue.toString().toDoubleOrNull()
                
                if (numValue != null) {
                    if (min != null && numValue < min.toDouble()) {
                        errors.add(createValidationError(config, fieldValue, "최소값은 ${min}입니다"))
                    }
                    if (max != null && numValue > max.toDouble()) {
                        errors.add(createValidationError(config, fieldValue, "최대값은 ${max}입니다"))
                    }
                }
            }
        }

        return errors
    }

    /**
     * 검증 오류 생성
     */
    private fun createValidationError(
        config: ValidationConfig,
        rejectedValue: Any?,
        defaultMessage: String
    ): ValidationErrorDto {
        return ValidationErrorDto(
            field = config.field,
            code = config.validationType,
            message = config.errorMessage ?: defaultMessage,
            rejectedValue = rejectedValue
        )
    }

    /**
     * 설정 값 추출
     */
    private fun getConfigValue(config: ValidationConfig, key: String): Any? {
        // JSON 파싱 로직 구현 필요
        return null
    }

    /**
     * 규칙 실행 로그 기록
     */
    @Transactional
    private fun logRuleExecution(
        rule: BusinessRule,
        context: RuleExecutionContextDto,
        result: RuleExecutionResultDto
    ) {
        val log = RuleExecutionLog(
            ruleId = rule.ruleId,
            ruleName = rule.ruleName,
            entityType = context.entityType,
            entityId = context.entityId,
            executed = result.executed,
            success = result.success,
            result = result.result?.toString(),
            errorMessage = result.errorMessage,
            executionTime = result.executionTime,
            executedBy = context.userId,
            companyId = context.companyId
        )
        
        ruleExecutionLogRepository.save(log)
    }

    /**
     * 검증 요약 생성
     */
    private fun createValidationSummary(results: List<EntityValidationResultDto>): ValidationSummaryDto {
        val allErrors = results.flatMap { it.validationResult.errors }
        val allWarnings = results.flatMap { it.validationResult.warnings }

        val errorsByField = allErrors.groupBy { it.field }.mapValues { it.value.size }
        val errorsByCode = allErrors.groupBy { it.code }.mapValues { it.value.size }

        val mostCommonErrors = errorsByCode.entries
            .sortedByDescending { it.value }
            .take(10)
            .map { (code, count) ->
                val sampleError = allErrors.first { it.code == code }
                ValidationErrorSummaryDto(
                    code = code,
                    message = sampleError.message,
                    count = count,
                    affectedFields = allErrors.filter { it.code == code }.map { it.field }.distinct()
                )
            }

        return ValidationSummaryDto(
            totalErrors = allErrors.size,
            totalWarnings = allWarnings.size,
            errorsByField = errorsByField,
            errorsByCode = errorsByCode,
            mostCommonErrors = mostCommonErrors
        )
    }

    /**
     * 데이터 무결성 검사
     */
    fun checkDataIntegrity(
        entityType: String,
        companyId: UUID,
        userId: UUID
    ): DataIntegrityCheckResultDto {
        return dataIntegrityService.checkIntegrity(entityType, companyId, userId)
    }

    /**
     * 실행 통계 조회
     */
    fun getExecutionStatistics(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<Map<String, Any>> {
        return ruleExecutionLogRepository.getExecutionStatistics(companyId, startDate, endDate)
    }

    /**
     * 규칙별 실행 통계 조회
     */
    fun getRuleExecutionStatistics(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<Map<String, Any>> {
        return ruleExecutionLogRepository.getRuleExecutionStatistics(companyId, startDate, endDate)
    }
}