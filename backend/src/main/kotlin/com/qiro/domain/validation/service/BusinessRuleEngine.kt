package com.qiro.domain.validation.service

import com.qiro.domain.validation.dto.RuleExecutionContextDto
import com.qiro.domain.validation.dto.RuleExecutionResultDto
import com.qiro.domain.validation.entity.BusinessRule
import org.springframework.stereotype.Service
import java.time.LocalDateTime
import java.util.*

/**
 * 비즈니스 규칙 엔진
 */
@Service
class BusinessRuleEngine {

    /**
     * 규칙 실행
     */
    fun executeRule(rule: BusinessRule, context: RuleExecutionContextDto): RuleExecutionResultDto {
        val startTime = System.currentTimeMillis()
        
        return try {
            val conditionResult = evaluateCondition(rule.condition, context)
            
            if (conditionResult) {
                val actionResult = executeAction(rule.action, context)
                
                RuleExecutionResultDto(
                    ruleId = rule.ruleId,
                    ruleName = rule.ruleName,
                    executed = true,
                    success = true,
                    result = actionResult,
                    executionTime = System.currentTimeMillis() - startTime
                )
            } else {
                RuleExecutionResultDto(
                    ruleId = rule.ruleId,
                    ruleName = rule.ruleName,
                    executed = false,
                    success = true,
                    result = "조건이 만족되지 않아 실행되지 않음",
                    executionTime = System.currentTimeMillis() - startTime
                )
            }
        } catch (e: Exception) {
            RuleExecutionResultDto(
                ruleId = rule.ruleId,
                ruleName = rule.ruleName,
                executed = true,
                success = false,
                errorMessage = e.message,
                executionTime = System.currentTimeMillis() - startTime
            )
        }
    }

    /**
     * 조건 평가
     */
    private fun evaluateCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        return when {
            condition.startsWith("FIELD_") -> evaluateFieldCondition(condition, context)
            condition.startsWith("RANGE_") -> evaluateRangeCondition(condition, context)
            condition.startsWith("DATE_") -> evaluateDateCondition(condition, context)
            condition.startsWith("STATUS_") -> evaluateStatusCondition(condition, context)
            condition.startsWith("CUSTOM_") -> evaluateCustomCondition(condition, context)
            else -> evaluateExpressionCondition(condition, context)
        }
    }

    /**
     * 필드 조건 평가
     */
    private fun evaluateFieldCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // FIELD_NOT_NULL:fieldName
        // FIELD_EQUALS:fieldName:value
        // FIELD_CONTAINS:fieldName:value
        val parts = condition.split(":")
        if (parts.size < 2) return false

        val conditionType = parts[0]
        val fieldName = parts[1]
        val fieldValue = context.entityData[fieldName]

        return when (conditionType) {
            "FIELD_NOT_NULL" -> fieldValue != null
            "FIELD_NULL" -> fieldValue == null
            "FIELD_EMPTY" -> fieldValue == null || fieldValue.toString().isBlank()
            "FIELD_NOT_EMPTY" -> fieldValue != null && fieldValue.toString().isNotBlank()
            "FIELD_EQUALS" -> {
                if (parts.size < 3) false
                else fieldValue?.toString() == parts[2]
            }
            "FIELD_NOT_EQUALS" -> {
                if (parts.size < 3) false
                else fieldValue?.toString() != parts[2]
            }
            "FIELD_CONTAINS" -> {
                if (parts.size < 3) false
                else fieldValue?.toString()?.contains(parts[2]) == true
            }
            "FIELD_STARTS_WITH" -> {
                if (parts.size < 3) false
                else fieldValue?.toString()?.startsWith(parts[2]) == true
            }
            "FIELD_ENDS_WITH" -> {
                if (parts.size < 3) false
                else fieldValue?.toString()?.endsWith(parts[2]) == true
            }
            else -> false
        }
    }

    /**
     * 범위 조건 평가
     */
    private fun evaluateRangeCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // RANGE_BETWEEN:fieldName:min:max
        // RANGE_GREATER_THAN:fieldName:value
        // RANGE_LESS_THAN:fieldName:value
        val parts = condition.split(":")
        if (parts.size < 3) return false

        val conditionType = parts[0]
        val fieldName = parts[1]
        val fieldValue = context.entityData[fieldName]?.toString()?.toDoubleOrNull() ?: return false

        return when (conditionType) {
            "RANGE_GREATER_THAN" -> {
                val threshold = parts[2].toDoubleOrNull() ?: return false
                fieldValue > threshold
            }
            "RANGE_GREATER_EQUAL" -> {
                val threshold = parts[2].toDoubleOrNull() ?: return false
                fieldValue >= threshold
            }
            "RANGE_LESS_THAN" -> {
                val threshold = parts[2].toDoubleOrNull() ?: return false
                fieldValue < threshold
            }
            "RANGE_LESS_EQUAL" -> {
                val threshold = parts[2].toDoubleOrNull() ?: return false
                fieldValue <= threshold
            }
            "RANGE_BETWEEN" -> {
                if (parts.size < 4) return false
                val min = parts[2].toDoubleOrNull() ?: return false
                val max = parts[3].toDoubleOrNull() ?: return false
                fieldValue in min..max
            }
            else -> false
        }
    }

    /**
     * 날짜 조건 평가
     */
    private fun evaluateDateCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // DATE_BEFORE:fieldName:date
        // DATE_AFTER:fieldName:date
        // DATE_BETWEEN:fieldName:startDate:endDate
        val parts = condition.split(":")
        if (parts.size < 3) return false

        val conditionType = parts[0]
        val fieldName = parts[1]
        val fieldValue = context.entityData[fieldName] as? LocalDateTime ?: return false

        return when (conditionType) {
            "DATE_BEFORE" -> {
                val compareDate = LocalDateTime.parse(parts[2])
                fieldValue.isBefore(compareDate)
            }
            "DATE_AFTER" -> {
                val compareDate = LocalDateTime.parse(parts[2])
                fieldValue.isAfter(compareDate)
            }
            "DATE_BETWEEN" -> {
                if (parts.size < 4) return false
                val startDate = LocalDateTime.parse(parts[2])
                val endDate = LocalDateTime.parse(parts[3])
                fieldValue.isAfter(startDate) && fieldValue.isBefore(endDate)
            }
            "DATE_TODAY" -> {
                val today = LocalDateTime.now().toLocalDate()
                fieldValue.toLocalDate() == today
            }
            "DATE_PAST" -> {
                fieldValue.isBefore(LocalDateTime.now())
            }
            "DATE_FUTURE" -> {
                fieldValue.isAfter(LocalDateTime.now())
            }
            else -> false
        }
    }

    /**
     * 상태 조건 평가
     */
    private fun evaluateStatusCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // STATUS_EQUALS:fieldName:status
        // STATUS_IN:fieldName:status1,status2,status3
        // STATUS_CHANGED_FROM:fieldName:oldStatus
        val parts = condition.split(":")
        if (parts.size < 3) return false

        val conditionType = parts[0]
        val fieldName = parts[1]
        val fieldValue = context.entityData[fieldName]?.toString()

        return when (conditionType) {
            "STATUS_EQUALS" -> fieldValue == parts[2]
            "STATUS_NOT_EQUALS" -> fieldValue != parts[2]
            "STATUS_IN" -> {
                val allowedStatuses = parts[2].split(",")
                fieldValue in allowedStatuses
            }
            "STATUS_NOT_IN" -> {
                val forbiddenStatuses = parts[2].split(",")
                fieldValue !in forbiddenStatuses
            }
            else -> false
        }
    }

    /**
     * 커스텀 조건 평가
     */
    private fun evaluateCustomCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // 커스텀 비즈니스 로직 구현
        val parts = condition.split(":")
        if (parts.isEmpty()) return false

        return when (parts[0]) {
            "CUSTOM_WORKING_HOURS" -> evaluateWorkingHours(context)
            "CUSTOM_BUDGET_LIMIT" -> evaluateBudgetLimit(context)
            "CUSTOM_MAINTENANCE_DUE" -> evaluateMaintenanceDue(context)
            "CUSTOM_APPROVAL_REQUIRED" -> evaluateApprovalRequired(context)
            else -> false
        }
    }

    /**
     * 표현식 조건 평가 (간단한 표현식 파서)
     */
    private fun evaluateExpressionCondition(condition: String, context: RuleExecutionContextDto): Boolean {
        // 간단한 표현식 평가 (실제로는 더 복잡한 파서 필요)
        return try {
            // 변수 치환
            var expression = condition
            context.entityData.forEach { (key, value) ->
                expression = expression.replace("\${$key}", value.toString())
            }
            
            // 기본적인 비교 연산자 처리
            when {
                expression.contains("==") -> {
                    val parts = expression.split("==").map { it.trim() }
                    parts[0] == parts[1]
                }
                expression.contains("!=") -> {
                    val parts = expression.split("!=").map { it.trim() }
                    parts[0] != parts[1]
                }
                expression.contains(">=") -> {
                    val parts = expression.split(">=").map { it.trim() }
                    val left = parts[0].toDoubleOrNull() ?: return false
                    val right = parts[1].toDoubleOrNull() ?: return false
                    left >= right
                }
                expression.contains("<=") -> {
                    val parts = expression.split("<=").map { it.trim() }
                    val left = parts[0].toDoubleOrNull() ?: return false
                    val right = parts[1].toDoubleOrNull() ?: return false
                    left <= right
                }
                expression.contains(">") -> {
                    val parts = expression.split(">").map { it.trim() }
                    val left = parts[0].toDoubleOrNull() ?: return false
                    val right = parts[1].toDoubleOrNull() ?: return false
                    left > right
                }
                expression.contains("<") -> {
                    val parts = expression.split("<").map { it.trim() }
                    val left = parts[0].toDoubleOrNull() ?: return false
                    val right = parts[1].toDoubleOrNull() ?: return false
                    left < right
                }
                else -> expression.toBoolean()
            }
        } catch (e: Exception) {
            false
        }
    }

    /**
     * 액션 실행
     */
    private fun executeAction(action: String, context: RuleExecutionContextDto): Any? {
        return when {
            action.startsWith("SET_") -> executeSetAction(action, context)
            action.startsWith("SEND_") -> executeSendAction(action, context)
            action.startsWith("CREATE_") -> executeCreateAction(action, context)
            action.startsWith("UPDATE_") -> executeUpdateAction(action, context)
            action.startsWith("VALIDATE_") -> executeValidateAction(action, context)
            else -> executeCustomAction(action, context)
        }
    }

    /**
     * 설정 액션 실행
     */
    private fun executeSetAction(action: String, context: RuleExecutionContextDto): String {
        // SET_FIELD:fieldName:value
        // SET_STATUS:status
        val parts = action.split(":")
        if (parts.size < 2) return "액션 형식이 올바르지 않습니다"

        return when (parts[0]) {
            "SET_FIELD" -> {
                if (parts.size < 3) "필드명과 값이 필요합니다"
                else "필드 ${parts[1]}을(를) ${parts[2]}로 설정"
            }
            "SET_STATUS" -> "상태를 ${parts[1]}로 변경"
            "SET_PRIORITY" -> "우선순위를 ${parts[1]}로 설정"
            else -> "알 수 없는 설정 액션"
        }
    }

    /**
     * 전송 액션 실행
     */
    private fun executeSendAction(action: String, context: RuleExecutionContextDto): String {
        // SEND_EMAIL:recipient:subject:template
        // SEND_NOTIFICATION:type:message
        val parts = action.split(":")
        if (parts.size < 2) return "액션 형식이 올바르지 않습니다"

        return when (parts[0]) {
            "SEND_EMAIL" -> "이메일 전송 예약"
            "SEND_NOTIFICATION" -> "알림 전송 예약"
            "SEND_SMS" -> "SMS 전송 예약"
            else -> "알 수 없는 전송 액션"
        }
    }

    /**
     * 생성 액션 실행
     */
    private fun executeCreateAction(action: String, context: RuleExecutionContextDto): String {
        // CREATE_TASK:title:description
        // CREATE_WORKORDER:type:priority
        val parts = action.split(":")
        if (parts.size < 2) return "액션 형식이 올바르지 않습니다"

        return when (parts[0]) {
            "CREATE_TASK" -> "작업 생성 예약"
            "CREATE_WORKORDER" -> "작업지시서 생성 예약"
            "CREATE_NOTIFICATION" -> "알림 생성 예약"
            else -> "알 수 없는 생성 액션"
        }
    }

    /**
     * 업데이트 액션 실행
     */
    private fun executeUpdateAction(action: String, context: RuleExecutionContextDto): String {
        // UPDATE_STATUS:newStatus
        // UPDATE_PRIORITY:newPriority
        val parts = action.split(":")
        if (parts.size < 2) return "액션 형식이 올바르지 않습니다"

        return when (parts[0]) {
            "UPDATE_STATUS" -> "상태 업데이트 예약"
            "UPDATE_PRIORITY" -> "우선순위 업데이트 예약"
            "UPDATE_ASSIGNEE" -> "담당자 업데이트 예약"
            else -> "알 수 없는 업데이트 액션"
        }
    }

    /**
     * 검증 액션 실행
     */
    private fun executeValidateAction(action: String, context: RuleExecutionContextDto): String {
        // VALIDATE_REQUIRED:fieldName
        // VALIDATE_FORMAT:fieldName:pattern
        val parts = action.split(":")
        if (parts.size < 2) return "액션 형식이 올바르지 않습니다"

        return when (parts[0]) {
            "VALIDATE_REQUIRED" -> "필수 필드 검증"
            "VALIDATE_FORMAT" -> "형식 검증"
            "VALIDATE_RANGE" -> "범위 검증"
            else -> "알 수 없는 검증 액션"
        }
    }

    /**
     * 커스텀 액션 실행
     */
    private fun executeCustomAction(action: String, context: RuleExecutionContextDto): String {
        return "커스텀 액션 실행: $action"
    }

    // 커스텀 조건 평가 메서드들
    private fun evaluateWorkingHours(context: RuleExecutionContextDto): Boolean {
        val now = LocalDateTime.now()
        val hour = now.hour
        return hour in 9..18 // 9시-18시 근무시간
    }

    private fun evaluateBudgetLimit(context: RuleExecutionContextDto): Boolean {
        val amount = context.entityData["amount"]?.toString()?.toDoubleOrNull() ?: return false
        val budgetLimit = context.additionalContext["budgetLimit"]?.toString()?.toDoubleOrNull() ?: return false
        return amount > budgetLimit
    }

    private fun evaluateMaintenanceDue(context: RuleExecutionContextDto): Boolean {
        val lastMaintenanceDate = context.entityData["lastMaintenanceDate"] as? LocalDateTime ?: return false
        val maintenanceCycle = context.entityData["maintenanceCycle"]?.toString()?.toIntOrNull() ?: return false
        val nextMaintenanceDate = lastMaintenanceDate.plusDays(maintenanceCycle.toLong())
        return LocalDateTime.now().isAfter(nextMaintenanceDate)
    }

    private fun evaluateApprovalRequired(context: RuleExecutionContextDto): Boolean {
        val amount = context.entityData["amount"]?.toString()?.toDoubleOrNull() ?: return false
        val approvalThreshold = context.additionalContext["approvalThreshold"]?.toString()?.toDoubleOrNull() ?: return false
        return amount >= approvalThreshold
    }
}