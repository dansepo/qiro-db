package com.qiro.domain.notification.service

import com.qiro.domain.notification.dto.SendNotificationRequest
import com.qiro.domain.notification.dto.SendUrgentAlertRequest
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationStatus
import com.qiro.domain.notification.entity.NotificationType
import com.qiro.domain.notification.repository.NotificationLogRepository
import com.qiro.domain.notification.repository.NotificationSettingRepository
import com.qiro.domain.notification.repository.NotificationTemplateRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 서비스 테스트
 */
class NotificationServiceTest : BehaviorSpec({

    val notificationLogRepository = mockk<NotificationLogRepository>(relaxed = true)
    val notificationSettingRepository = mockk<NotificationSettingRepository>(relaxed = true)
    val notificationTemplateRepository = mockk<NotificationTemplateRepository>(relaxed = true)
    val emailNotificationService = mockk<EmailNotificationService>(relaxed = true)
    val smsNotificationService = mockk<SmsNotificationService>(relaxed = true)
    val pushNotificationService = mockk<PushNotificationService>(relaxed = true)

    val notificationService = NotificationService(
        notificationLogRepository,
        notificationSettingRepository,
        notificationTemplateRepository,
        emailNotificationService,
        smsNotificationService,
        pushNotificationService
    )

    given("알림 발송 요청이 주어졌을 때") {
        val recipientIds = listOf(UUID.randomUUID(), UUID.randomUUID())
        val request = SendNotificationRequest(
            recipientIds = recipientIds,
            notificationType = NotificationType.FAULT_REPORT,
            title = "테스트 알림",
            message = "테스트 메시지입니다.",
            channels = setOf(NotificationMethod.EMAIL, NotificationMethod.SMS),
            priorityLevel = 2
        )

        `when`("알림을 발송하면") {
            every { notificationLogRepository.save(any()) } returnsArgument 0

            val result = notificationService.sendNotification(request)

            then("모든 수신자와 채널에 대해 알림이 생성되어야 한다") {
                result.size shouldBe 4 // 2명 × 2채널 = 4개
                result.forEach { notification ->
                    notification.notificationType shouldBe NotificationType.FAULT_REPORT
                    notification.title shouldBe "테스트 알림"
                    notification.message shouldBe "테스트 메시지입니다."
                    notification.priorityLevel shouldBe 2
                }
            }

            then("알림 로그가 저장되어야 한다") {
                verify(exactly = 4) { notificationLogRepository.save(any()) }
            }

            then("각 채널별 발송 서비스가 호출되어야 한다") {
                verify(exactly = 2) { emailNotificationService.sendEmail(any()) }
                verify(exactly = 2) { smsNotificationService.sendSms(any()) }
            }
        }
    }

    given("긴급 알림 발송 요청이 주어졌을 때") {
        val recipientIds = listOf(UUID.randomUUID())
        val request = SendUrgentAlertRequest(
            recipientIds = recipientIds,
            title = "긴급 알림",
            message = "긴급 상황입니다.",
            channels = setOf(NotificationMethod.SMS, NotificationMethod.PUSH)
        )

        `when`("긴급 알림을 발송하면") {
            every { notificationLogRepository.save(any()) } returnsArgument 0

            val result = notificationService.sendUrgentAlert(request)

            then("최고 우선순위로 알림이 생성되어야 한다") {
                result.size shouldBe 2 // 1명 × 2채널 = 2개
                result.forEach { notification ->
                    notification.notificationType shouldBe NotificationType.URGENT_ALERT
                    notification.priorityLevel shouldBe 1 // 최고 우선순위
                    notification.title shouldBe "긴급 알림"
                }
            }

            then("SMS와 푸시 알림이 발송되어야 한다") {
                verify(exactly = 1) { smsNotificationService.sendSms(any()) }
                verify(exactly = 1) { pushNotificationService.sendPush(any()) }
            }
        }
    }

    given("읽지 않은 알림이 있을 때") {
        val recipientId = UUID.randomUUID()
        val unreadCount = 5L

        `when`("읽지 않은 알림 개수를 조회하면") {
            every { notificationLogRepository.countUnreadNotifications(recipientId) } returns unreadCount

            val result = notificationService.getUnreadNotificationCount(recipientId)

            then("정확한 개수가 반환되어야 한다") {
                result shouldBe unreadCount
            }
        }
    }

    given("알림 ID가 주어졌을 때") {
        val notificationId = UUID.randomUUID()
        val mockNotification = mockk<com.qiro.domain.notification.entity.NotificationLog>(relaxed = true)

        `when`("알림을 읽음 처리하면") {
            every { notificationLogRepository.findById(notificationId) } returns Optional.of(mockNotification)
            every { notificationLogRepository.save(any()) } returnsArgument 0

            notificationService.markAsRead(notificationId)

            then("읽음 시간이 설정되어야 한다") {
                verify { mockNotification.readAt = any<LocalDateTime>() }
                verify { mockNotification.status = NotificationStatus.READ }
                verify { notificationLogRepository.save(mockNotification) }
            }
        }
    }

    given("실패한 알림들이 있을 때") {
        val companyId = UUID.randomUUID()
        val failedNotifications = listOf(
            mockk<com.qiro.domain.notification.entity.NotificationLog>(relaxed = true),
            mockk<com.qiro.domain.notification.entity.NotificationLog>(relaxed = true)
        )

        `when`("실패한 알림을 재시도하면") {
            every { 
                notificationLogRepository.findFailedNotificationsForRetry(any(), any()) 
            } returns failedNotifications

            failedNotifications.forEach { notification ->
                every { notification.channel } returns NotificationMethod.EMAIL
            }

            notificationService.retryFailedNotifications()

            then("각 실패한 알림에 대해 재발송이 시도되어야 한다") {
                verify(exactly = 2) { emailNotificationService.sendEmail(any()) }
            }
        }
    }

    given("만료된 알림들이 있을 때") {
        val expiredNotifications = listOf(
            mockk<com.qiro.domain.notification.entity.NotificationLog>(relaxed = true),
            mockk<com.qiro.domain.notification.entity.NotificationLog>(relaxed = true)
        )

        `when`("만료된 알림을 정리하면") {
            every { 
                notificationLogRepository.findExpiredNotifications(any()) 
            } returns expiredNotifications

            every { notificationLogRepository.saveAll(any<List<com.qiro.domain.notification.entity.NotificationLog>>()) } returns expiredNotifications

            notificationService.cleanupExpiredNotifications()

            then("만료된 알림들의 상태가 EXPIRED로 변경되어야 한다") {
                expiredNotifications.forEach { notification ->
                    verify { notification.status = NotificationStatus.EXPIRED }
                }
                verify { notificationLogRepository.saveAll(expiredNotifications) }
            }
        }
    }

    given("알림 통계 조회 요청이 있을 때") {
        val startDate = LocalDateTime.now().minusDays(7)
        val endDate = LocalDateTime.now()
        val companyId = UUID.randomUUID()

        val mockStatistics = listOf(
            arrayOf(NotificationStatus.SENT, 100L),
            arrayOf(NotificationStatus.DELIVERED, 95L),
            arrayOf(NotificationStatus.FAILED, 5L),
            arrayOf(NotificationStatus.READ, 80L)
        )

        `when`("통계를 조회하면") {
            every { 
                notificationLogRepository.getNotificationStatistics(companyId, startDate, endDate) 
            } returns mockStatistics

            val result = notificationService.getNotificationStatistics(startDate, endDate)

            then("정확한 통계가 계산되어야 한다") {
                result.totalSent shouldBe 195L // SENT + DELIVERED
                result.totalDelivered shouldBe 95L
                result.totalFailed shouldBe 5L
                result.totalRead shouldBe 80L
                result.deliveryRate shouldBe (95.0 / 195.0)
                result.readRate shouldBe (80.0 / 95.0)
                result.failureRate shouldBe (5.0 / 200.0) // 실패 / (성공 + 실패)
            }
        }
    }
})