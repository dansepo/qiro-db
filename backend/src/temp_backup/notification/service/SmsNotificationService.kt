package com.qiro.domain.notification.service

import com.qiro.domain.notification.entity.NotificationLog
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service

/**
 * SMS 알림 서비스
 * SMS 발송을 담당합니다.
 */
@Service
class SmsNotificationService {
    private val logger = LoggerFactory.getLogger(SmsNotificationService::class.java)

    /**
     * SMS 발송
     */
    fun sendSms(notification: NotificationLog) {
        try {
            // TODO: 실제 SMS 발송 로직 구현
            // - SMS 게이트웨이 연동
            // - 메시지 길이 제한 처리
            // - 발송 결과 확인
            // - 비용 추적
            
            logger.info("SMS 발송 - 수신자: ${notification.recipientId}, 내용: ${notification.message}")
            
            // 임시로 성공 처리
            // 실제 구현 시에는 외부 SMS 서비스 API 호출
            
        } catch (e: Exception) {
            logger.error("SMS 발송 실패 - 수신자: ${notification.recipientId}", e)
            throw e
        }
    }

    /**
     * SMS 발송 가능 여부 확인
     */
    fun canSendSms(recipientId: String): Boolean {
        // TODO: 전화번호 유효성 검증
        // TODO: 수신 거부 목록 확인
        // TODO: 발송 제한 확인
        // TODO: 비용 한도 확인
        return true
    }

    /**
     * SMS 메시지 길이 검증
     */
    fun validateSmsMessage(message: String): Boolean {
        // SMS 메시지 길이 제한 (일반적으로 160자)
        return message.length <= 160
    }

    /**
     * 긴 메시지 분할
     */
    fun splitLongMessage(message: String): List<String> {
        if (message.length <= 160) {
            return listOf(message)
        }

        val parts = mutableListOf<String>()
        var remaining = message
        var partNumber = 1
        val totalParts = (message.length + 159) / 160

        while (remaining.isNotEmpty()) {
            val maxLength = if (totalParts > 1) 153 else 160 // 멀티파트 SMS는 헤더 공간 필요
            val part = if (remaining.length <= maxLength) {
                remaining
            } else {
                remaining.substring(0, maxLength)
            }

            if (totalParts > 1) {
                parts.add("($partNumber/$totalParts) $part")
            } else {
                parts.add(part)
            }

            remaining = remaining.drop(maxLength)
            partNumber++
        }

        return parts
    }
}