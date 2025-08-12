package com.qiro.domain.notification.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.notification.dto.*
import com.qiro.domain.notification.entity.NotificationSetting
import com.qiro.domain.notification.entity.NotificationType
import com.qiro.domain.notification.entity.RecipientType
import com.qiro.domain.notification.repository.NotificationSettingRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 알림 설정 서비스
 * 알림 설정의 생성, 수정, 조회를 담당합니다.
 */
@Service
@Transactional
class NotificationSettingService(
    private val notificationSettingRepository: NotificationSettingRepository
) {

    /**
     * 알림 설정 생성
     */
    fun createNotificationSetting(request: CreateNotificationSettingRequest): NotificationSettingDto {
        val companyId = TenantContext.getCurrentCompanyId()

        val setting = NotificationSetting().apply {
            this.companyId = companyId
            this.buildingId = request.buildingId
            this.notificationType = request.notificationType
            this.notificationName = request.notificationName
            this.notificationDescription = request.notificationDescription
            this.triggerCondition = request.triggerCondition
            this.triggerSchedule = request.triggerSchedule
            this.recipientType = RecipientType.valueOf(request.recipientType)
            this.recipientList = request.recipientList
            this.notificationMethods = request.notificationMethods
            this.subjectTemplate = request.subjectTemplate
            this.messageTemplate = request.messageTemplate
            this.priorityLevel = request.priorityLevel
            this.retryCount = request.retryCount
            this.retryInterval = request.retryInterval
            this.dailyLimit = request.dailyLimit
            this.hourlyLimit = request.hourlyLimit
        }

        val savedSetting = notificationSettingRepository.save(setting)
        return savedSetting.toDto()
    }

    /**
     * 알림 설정 수정
     */
    fun updateNotificationSetting(
        settingId: UUID,
        request: UpdateNotificationSettingRequest
    ): NotificationSettingDto {
        val setting = notificationSettingRepository.findById(settingId)
            .orElseThrow { BusinessException(ErrorCode.NOTIFICATION_SETTING_NOT_FOUND) }

        request.notificationName?.let { setting.notificationName = it }
        request.notificationDescription?.let { setting.notificationDescription = it }
        request.triggerCondition?.let { setting.triggerCondition = it }
        request.triggerSchedule?.let { setting.triggerSchedule = it }
        request.recipientList?.let { setting.recipientList = it }
        request.notificationMethods?.let { setting.notificationMethods = it }
        request.subjectTemplate?.let { setting.subjectTemplate = it }
        request.messageTemplate?.let { setting.messageTemplate = it }
        request.isActive?.let { setting.isActive = it }
        request.priorityLevel?.let { setting.priorityLevel = it }
        request.retryCount?.let { setting.retryCount = it }
        request.retryInterval?.let { setting.retryInterval = it }
        request.dailyLimit?.let { setting.dailyLimit = it }
        request.hourlyLimit?.let { setting.hourlyLimit = it }

        val updatedSetting = notificationSettingRepository.save(setting)
        return updatedSetting.toDto()
    }

    /**
     * 알림 설정 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationSetting(settingId: UUID): NotificationSettingDto {
        val setting = notificationSettingRepository.findById(settingId)
            .orElseThrow { BusinessException(ErrorCode.NOTIFICATION_SETTING_NOT_FOUND) }
        return setting.toDto()
    }

    /**
     * 알림 설정 목록 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationSettings(pageable: Pageable): Page<NotificationSettingDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationSettingRepository.findByCompanyId(companyId, pageable)
            .map { it.toDto() }
    }

    /**
     * 알림 유형별 활성 설정 조회
     */
    @Transactional(readOnly = true)
    fun getActiveNotificationSettings(notificationType: NotificationType): List<NotificationSettingDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationSettingRepository.findByCompanyIdAndNotificationTypeAndIsActiveTrue(
            companyId, notificationType
        ).map { it.toDto() }
    }

    /**
     * 건물별 알림 설정 조회
     */
    @Transactional(readOnly = true)
    fun getNotificationSettingsByBuilding(buildingId: UUID): List<NotificationSettingDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationSettingRepository.findByCompanyIdAndBuildingIdAndIsActiveTrue(
            companyId, buildingId
        ).map { it.toDto() }
    }

    /**
     * 긴급 알림 설정 조회
     */
    @Transactional(readOnly = true)
    fun getUrgentNotificationSettings(): List<NotificationSettingDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationSettingRepository.findUrgentNotificationSettings(companyId)
            .map { it.toDto() }
    }

    /**
     * 스케줄된 알림 설정 조회
     */
    @Transactional(readOnly = true)
    fun getScheduledNotificationSettings(): List<NotificationSettingDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        return notificationSettingRepository.findScheduledNotificationSettings(companyId)
            .map { it.toDto() }
    }

    /**
     * 알림 설정 삭제
     */
    fun deleteNotificationSetting(settingId: UUID) {
        val setting = notificationSettingRepository.findById(settingId)
            .orElseThrow { BusinessException(ErrorCode.NOTIFICATION_SETTING_NOT_FOUND) }

        notificationSettingRepository.delete(setting)
    }

    /**
     * 알림 설정 활성화/비활성화
     */
    fun toggleNotificationSetting(settingId: UUID, isActive: Boolean): NotificationSettingDto {
        val setting = notificationSettingRepository.findById(settingId)
            .orElseThrow { BusinessException(ErrorCode.NOTIFICATION_SETTING_NOT_FOUND) }

        setting.isActive = isActive
        val updatedSetting = notificationSettingRepository.save(setting)
        return updatedSetting.toDto()
    }
}

/**
 * NotificationSetting 확장 함수
 */
private fun NotificationSetting.toDto(): NotificationSettingDto {
    return NotificationSettingDto(
        id = this.id,
        buildingId = this.buildingId,
        notificationType = this.notificationType,
        notificationName = this.notificationName,
        notificationDescription = this.notificationDescription,
        triggerCondition = this.triggerCondition,
        triggerSchedule = this.triggerSchedule,
        recipientType = this.recipientType.name,
        recipientList = this.recipientList,
        notificationMethods = this.notificationMethods,
        subjectTemplate = this.subjectTemplate,
        messageTemplate = this.messageTemplate,
        isActive = this.isActive,
        priorityLevel = this.priorityLevel,
        retryCount = this.retryCount,
        retryInterval = this.retryInterval,
        dailyLimit = this.dailyLimit,
        hourlyLimit = this.hourlyLimit,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}