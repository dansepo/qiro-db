package com.qiro.domain.validation.service

import com.qiro.domain.validation.dto.*
import com.qiro.domain.validation.entity.BusinessRule
import com.qiro.domain.validation.repository.BusinessRuleRepository
import com.qiro.global.exception.BusinessException
import com.qiro.global.exception.ErrorCode
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 비즈니스 규칙 관리 서비스
 */
@Service
@Transactional(readOnly = true)
class BusinessRuleService(
    private val businessRuleRepository: BusinessRuleRepository
) {

    /**
     * 비즈니스 규칙 생성
     */
    @Transactional
    fun createBusinessRule(
        request: CreateBusinessRuleRequest,
        companyId: UUID,
        userId: UUID
    ): BusinessRuleDto {
        // 규칙 코드 중복 검사
        businessRuleRepository.findByRuleCode(request.ruleCode)?.let {
            throw BusinessException(ErrorCode.DUPLICATE_RESOURCE, "이미 존재하는 규칙 코드입니다: ${request.ruleCode}")
        }

        // 조건과 액션 유효성 검사
        validateRuleCondition(request.condition)
        validateRuleAction(request.action)

        val businessRule = BusinessRule(
            ruleName = request.ruleName,
            ruleCode = request.ruleCode,
            description = request.description,
            ruleType = request.ruleType,
            entityType = request.entityType,
            condition = request.condition,
            action = request.action,
            priority = request.priority,
            companyId = companyId,
            createdBy = userId
        )

        val savedRule = businessRuleRepository.save(businessRule)
        return convertToDto(savedRule)
    }

    /**
     * 비즈니스 규칙 수정
     */
    @Transactional
    fun updateBusinessRule(
        ruleId: UUID,
        request: UpdateBusinessRuleRequest,
        companyId: UUID,
        userId: UUID
    ): BusinessRuleDto {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        // 조건과 액션 유효성 검사
        request.condition?.let { validateRuleCondition(it) }
        request.action?.let { validateRuleAction(it) }

        businessRule.update(
            ruleName = request.ruleName,
            description = request.description,
            condition = request.condition,
            action = request.action,
            priority = request.priority,
            isActive = request.isActive,
            updatedBy = userId
        )

        val savedRule = businessRuleRepository.save(businessRule)
        return convertToDto(savedRule)
    }

    /**
     * 비즈니스 규칙 삭제
     */
    @Transactional
    fun deleteBusinessRule(ruleId: UUID, companyId: UUID) {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        businessRuleRepository.delete(businessRule)
    }

    /**
     * 비즈니스 규칙 조회
     */
    fun getBusinessRule(ruleId: UUID, companyId: UUID): BusinessRuleDto {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        return convertToDto(businessRule)
    }

    /**
     * 비즈니스 규칙 목록 조회
     */
    fun getBusinessRules(
        companyId: UUID,
        ruleType: BusinessRuleType? = null,
        entityType: String? = null,
        isActive: Boolean? = null,
        keyword: String? = null,
        pageable: Pageable
    ): Page<BusinessRuleDto> {
        return businessRuleRepository.searchBusinessRules(
            companyId = companyId,
            ruleType = ruleType,
            entityType = entityType,
            isActive = isActive,
            keyword = keyword,
            pageable = pageable
        ).map { convertToDto(it) }
    }

    /**
     * 엔티티별 활성 규칙 조회
     */
    fun getActiveRulesByEntity(companyId: UUID, entityType: String): List<BusinessRuleDto> {
        return businessRuleRepository
            .findByCompanyIdAndEntityTypeAndIsActiveTrueOrderByPriorityAsc(companyId, entityType)
            .map { convertToDto(it) }
    }

    /**
     * 규칙 타입별 활성 규칙 조회
     */
    fun getActiveRulesByType(companyId: UUID, ruleType: BusinessRuleType): List<BusinessRuleDto> {
        return businessRuleRepository
            .findByCompanyIdAndRuleTypeAndIsActiveTrue(companyId, ruleType)
            .map { convertToDto(it) }
    }

    /**
     * 비즈니스 규칙 활성화
     */
    @Transactional
    fun activateBusinessRule(ruleId: UUID, companyId: UUID, userId: UUID): BusinessRuleDto {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        businessRule.activate(userId)
        val savedRule = businessRuleRepository.save(businessRule)
        return convertToDto(savedRule)
    }

    /**
     * 비즈니스 규칙 비활성화
     */
    @Transactional
    fun deactivateBusinessRule(ruleId: UUID, companyId: UUID, userId: UUID): BusinessRuleDto {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        businessRule.deactivate(userId)
        val savedRule = businessRuleRepository.save(businessRule)
        return convertToDto(savedRule)
    }

    /**
     * 우선순위 범위 내 규칙 조회
     */
    fun getRulesByPriorityRange(
        companyId: UUID,
        entityType: String,
        minPriority: Int,
        maxPriority: Int
    ): List<BusinessRuleDto> {
        return businessRuleRepository
            .findByPriorityRange(companyId, entityType, minPriority, maxPriority)
            .map { convertToDto(it) }
    }

    /**
     * 규칙 우선순위 업데이트
     */
    @Transactional
    fun updateRulePriority(
        ruleId: UUID,
        newPriority: Int,
        companyId: UUID,
        userId: UUID
    ): BusinessRuleDto {
        val businessRule = businessRuleRepository.findById(ruleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "비즈니스 규칙을 찾을 수 없습니다") }

        if (businessRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        businessRule.update(priority = newPriority, updatedBy = userId)
        val savedRule = businessRuleRepository.save(businessRule)
        return convertToDto(savedRule)
    }

    /**
     * 규칙 복사
     */
    @Transactional
    fun copyBusinessRule(
        sourceRuleId: UUID,
        newRuleCode: String,
        newRuleName: String,
        companyId: UUID,
        userId: UUID
    ): BusinessRuleDto {
        val sourceRule = businessRuleRepository.findById(sourceRuleId)
            .orElseThrow { BusinessException(ErrorCode.RESOURCE_NOT_FOUND, "원본 비즈니스 규칙을 찾을 수 없습니다") }

        if (sourceRule.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED, "해당 규칙에 대한 권한이 없습니다")
        }

        // 새 규칙 코드 중복 검사
        businessRuleRepository.findByRuleCode(newRuleCode)?.let {
            throw BusinessException(ErrorCode.DUPLICATE_RESOURCE, "이미 존재하는 규칙 코드입니다: $newRuleCode")
        }

        val copiedRule = BusinessRule(
            ruleName = newRuleName,
            ruleCode = newRuleCode,
            description = "${sourceRule.description} (복사본)",
            ruleType = sourceRule.ruleType,
            entityType = sourceRule.entityType,
            condition = sourceRule.condition,
            action = sourceRule.action,
            priority = sourceRule.priority + 1,
            isActive = false, // 복사된 규칙은 비활성 상태로 생성
            companyId = companyId,
            createdBy = userId
        )

        val savedRule = businessRuleRepository.save(copiedRule)
        return convertToDto(savedRule)
    }

    /**
     * 규칙 조건 유효성 검사
     */
    private fun validateRuleCondition(condition: String) {
        if (condition.isBlank()) {
            throw BusinessException(ErrorCode.INVALID_INPUT, "규칙 조건은 필수입니다")
        }

        // 기본적인 조건 형식 검사
        val validConditionPrefixes = listOf(
            "FIELD_", "RANGE_", "DATE_", "STATUS_", "CUSTOM_"
        )

        val hasValidPrefix = validConditionPrefixes.any { condition.startsWith(it) } ||
                condition.contains("==") || condition.contains("!=") ||
                condition.contains(">=") || condition.contains("<=") ||
                condition.contains(">") || condition.contains("<")

        if (!hasValidPrefix) {
            throw BusinessException(ErrorCode.INVALID_INPUT, "올바르지 않은 조건 형식입니다")
        }
    }

    /**
     * 규칙 액션 유효성 검사
     */
    private fun validateRuleAction(action: String) {
        if (action.isBlank()) {
            throw BusinessException(ErrorCode.INVALID_INPUT, "규칙 액션은 필수입니다")
        }

        // 기본적인 액션 형식 검사
        val validActionPrefixes = listOf(
            "SET_", "SEND_", "CREATE_", "UPDATE_", "VALIDATE_"
        )

        val hasValidPrefix = validActionPrefixes.any { action.startsWith(it) }

        if (!hasValidPrefix) {
            throw BusinessException(ErrorCode.INVALID_INPUT, "올바르지 않은 액션 형식입니다")
        }
    }

    /**
     * 엔티티를 DTO로 변환
     */
    private fun convertToDto(businessRule: BusinessRule): BusinessRuleDto {
        return BusinessRuleDto(
            ruleId = businessRule.ruleId,
            ruleName = businessRule.ruleName,
            ruleCode = businessRule.ruleCode,
            description = businessRule.description ?: "",
            ruleType = businessRule.ruleType,
            entityType = businessRule.entityType,
            condition = businessRule.condition,
            action = businessRule.action,
            priority = businessRule.priority,
            isActive = businessRule.isActive,
            createdAt = businessRule.createdAt,
            createdBy = businessRule.createdBy,
            updatedAt = businessRule.updatedAt,
            updatedBy = businessRule.updatedBy
        )
    }

    /**
     * 규칙 템플릿 생성
     */
    fun createRuleTemplates(companyId: UUID, userId: UUID): List<BusinessRuleDto> {
        val templates = listOf(
            // 시설물 관련 규칙
            CreateBusinessRuleRequest(
                ruleName = "시설물 정기점검 알림",
                ruleCode = "FACILITY_MAINTENANCE_DUE",
                description = "시설물 정기점검 일정이 도래했을 때 알림을 발송합니다",
                ruleType = BusinessRuleType.NOTIFICATION,
                entityType = "FACILITY",
                condition = "CUSTOM_MAINTENANCE_DUE",
                action = "SEND_NOTIFICATION:maintenance_due:정기점검이 필요합니다"
            ),
            // 작업지시서 관련 규칙
            CreateBusinessRuleRequest(
                ruleName = "긴급 작업지시서 승인 필요",
                ruleCode = "URGENT_WORKORDER_APPROVAL",
                description = "긴급 작업지시서는 관리자 승인이 필요합니다",
                ruleType = BusinessRuleType.APPROVAL,
                entityType = "WORK_ORDER",
                condition = "FIELD_EQUALS:priority:URGENT",
                action = "SET_STATUS:PENDING_APPROVAL"
            ),
            // 예산 관련 규칙
            CreateBusinessRuleRequest(
                ruleName = "예산 초과 경고",
                ruleCode = "BUDGET_EXCEEDED_WARNING",
                description = "예산 사용량이 80%를 초과하면 경고를 발송합니다",
                ruleType = BusinessRuleType.NOTIFICATION,
                entityType = "BUDGET_MANAGEMENT",
                condition = "CUSTOM_BUDGET_LIMIT",
                action = "SEND_NOTIFICATION:budget_warning:예산 사용량이 80%를 초과했습니다"
            )
        )

        return templates.map { template ->
            createBusinessRule(template, companyId, userId)
        }
    }
}