package com.qiro.domain.notification.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.notification.dto.CreateNotificationTemplateRequest
import com.qiro.domain.notification.dto.NotificationTemplateDto
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationTemplate
import com.qiro.domain.notification.entity.NotificationType
import com.qiro.domain.notification.repository.NotificationTemplateRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 알림 템플릿 서비스
 * 알림 템플릿의 생성, 수정, 조회를 담당합니다.
 */
@Service
@Transactional
class NotificationTemplateService(
    private val notificationTemplateRepository: NotificationTemplateRepository
) {

    /**
     * 알림 템플릿 생성
     */
    fun createNotificationTemplate(request: CreateNotificationTemplateRequest): NotificationTemplateDto {
        val companyId = TenantContext.getCurrentCompanyId()

        // 기본 템플릿으로 설정하는 경우 기존 기본 템플릿 해제
        if (request.isDefault) {
            clearDefaultTemplate(companyId, request.templateType, request.channel)
        }

        val template = NotificationTemplate().apply {
            this.companyId = companyId
            this.templateName = request.templateName
            this.templateDescription = request.templateDescription
            this.templateType = request.templateType
            this.channel = request.channel
            this.subjectTemplate = request.subjectTemplate
            this.bodyTemplate = request.bodyTemplate
            this.variables = request.variables
            this.isDefault = request.isDefault
            this.languageCode = request.languageCode
        }

        val savedTemplate = notificationTemplateRepository.save(template)
        return savedTemplate.toDto()
    }

    /**
     * 알림 템플릿 수정
     */
    fun updateNotificationTemplate(
        templateId: UUID,
        request: CreateNotificationTemplateRequest
    ): NotificationTemplateDto {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        // 기본 템플릿으로 변경하는 경우 기존 기본 템플릿 해제
        if (request.isDefault && !template.isDefault) {
            clearDefaultTemplate(template.companyId, request.templateType, request.channel)
        }

        template.apply {
            this.templateName = request.templateName
            this.templateDescription = request.templateDescription
            this.templateType = request.templateType
            this.channel = request.channel
            this.subjectTemplate = request.subjectTemplate
            this.bodyTemplate = request.bodyTemplate
            this.variables = request.variables
            this.isDefault = request.isDefault
            this.languageCode = request.languageCode
        }

        val updatedTemplate = notificationTemplateRepository.save(template)
        return updatedTemplate.toDto()
    }

    /**
     * 알림 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationTemplate(templateId: UUID): NotificationTemplateDto {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }
        return template.toDto()
    }

    /**
     * 알림 템플릿 목록 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationTemplates(pageable: Pageable): Page<NotificationTemplateDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByCompanyId(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 알림 유형별 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getTemplatesByType(notificationType: NotificationType): List<NotificationTemplateDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByCompanyIdAndTemplateTypeAndIsActiveTrue(
            companyId, notificationType
        ).map { it.toDto() }
    }

    /**
     * 채널별 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getTemplatesByChannel(channel: NotificationMethod): List<NotificationTemplateDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByCompanyIdAndChannelAndIsActiveTrue(
            companyId, channel
        ).map { it.toDto() }
    }

    /**
     * 기본 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getDefaultTemplate(
        notificationType: NotificationType,
        channel: NotificationMethod
    ): NotificationTemplateDto? {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByCompanyIdAndTemplateTypeAndChannelAndIsDefaultTrueAndIsActiveTrue(
            companyId, notificationType, channel
        )?.toDto()
    }

    /**
     * 언어별 템플릿 조회
     */
    @Transactional(readOnly = true)
    fun getTemplatesByLanguage(
        notificationType: NotificationType,
        channel: NotificationMethod,
        languageCode: String
    ): List<NotificationTemplateDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByCompanyIdAndTemplateTypeAndChannelAndLanguageCodeAndIsActiveTrue(
            companyId, notificationType, channel, languageCode
        ).map { it.toDto() }
    }

    /**
     * 템플릿 이름으로 검색
     */
    @Transactional(readOnly = true)
    fun searchTemplatesByName(name: String): List<NotificationTemplateDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationTemplateRepository.findByTemplateNameContaining(companyId, name)
            .map { it.toDto() }
    }

    /**
     * 알림 템플릿 삭제
     */
    fun deleteNotificationTemplate(templateId: UUID) {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        notificationTemplateRepository.delete(template)
    }

    /**
     * 템플릿 활성화/비활성화
     */
    fun toggleTemplate(templateId: UUID, isActive: Boolean): NotificationTemplateDto {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        template.isActive = isActive
        val updatedTemplate = notificationTemplateRepository.save(template)
        return updatedTemplate.toDto()
    }

    /**
     * 템플릿 복사
     */
    fun copyTemplate(templateId: UUID, newName: String): NotificationTemplateDto {
        val originalTemplate = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        val copiedTemplate = NotificationTemplate().apply {
            this.companyId = originalTemplate.companyId
            this.templateName = newName
            this.templateDescription = "${originalTemplate.templateDescription} (복사본)"
            this.templateType = originalTemplate.templateType
            this.channel = originalTemplate.channel
            this.subjectTemplate = originalTemplate.subjectTemplate
            this.bodyTemplate = originalTemplate.bodyTemplate
            this.variables = originalTemplate.variables
            this.isDefault = false // 복사본은 기본 템플릿이 될 수 없음
            this.languageCode = originalTemplate.languageCode
        }

        val savedTemplate = notificationTemplateRepository.save(copiedTemplate)
        return savedTemplate.toDto()
    }

    /**
     * 템플릿 미리보기
     */
    @Transactional(readOnly = true)
    fun previewTemplate(templateId: UUID, variables: Map<String, Any>): Map<String, String> {
        val template = notificationTemplateRepository.findById(templateId)
            .orElseThrow { BusinessException(ErrorCode.TEMPLATE_NOT_FOUND) }

        val renderedSubject = template.renderSubject(variables) ?: ""
        val renderedBody = template.renderTemplate(variables)

        return mapOf(
            "subject" to renderedSubject,
            "body" to renderedBody
        )
    }

    /**
     * 기존 기본 템플릿 해제
     */
    private fun clearDefaultTemplate(
        companyId: UUID,
        templateType: NotificationType,
        channel: NotificationMethod
    ) {
        val existingDefault = notificationTemplateRepository
            .findByCompanyIdAndTemplateTypeAndChannelAndIsDefaultTrueAndIsActiveTrue(
                companyId, templateType, channel
            )

        existingDefault?.let {
            it.isDefault = false
            notificationTemplateRepository.save(it)
        }
    }
}

/**
 * NotificationTemplate 확장 함수
 */
private fun NotificationTemplate.toDto(): NotificationTemplateDto {
    return NotificationTemplateDto(
        id = this.id,
        templateName = this.templateName,
        templateDescription = this.templateDescription,
        templateType = this.templateType,
        channel = this.channel,
        subjectTemplate = this.subjectTemplate,
        bodyTemplate = this.bodyTemplate,
        variables = this.variables,
        isActive = this.isActive,
        isDefault = this.isDefault,
        languageCode = this.languageCode,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}