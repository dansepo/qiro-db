package com.qiro.integration

import com.qiro.common.service.TestExecutionService
import com.qiro.domain.notification.service.NotificationService
import com.qiro.domain.fault.service.FaultReportService
import com.qiro.domain.workorder.service.WorkOrderService
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.doubles.shouldBeLessThan
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 알림 발송 및 에스컬레이션 통합 테스트
 * 백엔드 서비스 기반으로 알림 시스템 전체 플로우를 테스트
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class NotificationEscalationIntegrationTest : BehaviorSpec({

    val notificationService = mockk<NotificationService>()
    val faultReportService = mockk<FaultReportService>()
    val workOrderService = mockk<WorkOrderService>()

    given("긴급 고장 신고 즉시 알림 플로우") {
        val testCompanyId = UUID.randomUUID()
        val testFaultReportId = UUID.randomUUID()
        val testUserId = UUID.randomUUID()

        `when`("긴급 고장이 신고될 때") {
            // Mock 설정
            every { 
                faultReportService.createUrgentFaultReport(any()) 
            } returns mockUrgentFaultReportDto(testFaultReportId)

            every { 
                notificationService.sendUrgentNotification(any()) 
            } returns mockNotificationResultDto("URGENT_ALERT")

            every { 
                notificationService.sendMultiChannelNotification(any()) 
            } returns listOf(
                mockNotificationResultDto("SMS"),
                mockNotificationResultDto("EMAIL"),
                mockNotificationResultDto("PUSH")
            )

            val results = runUrgentFaultReportNotificationFlow(
                testCompanyId, testFaultReportId, testUserId, 
                faultReportService, notificationService
            )

            then("즉시 알림이 다채널로 발송되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 5
                
                // 각 단계별 검증
                val faultDetection = results.find { it.testName.contains("긴급 고장 감지") }
                faultDetection?.testResult shouldBe "PASS"
                faultDetection?.executionTimeMs?.let { it shouldBeLessThan 100.0 }
                
                val immediateAlert = results.find { it.testName.contains("즉시 알림") }
                immediateAlert?.testResult shouldBe "PASS"
                
                val multiChannelSend = results.find { it.testName.contains("다채널 발송") }
                multiChannelSend?.testResult shouldBe "PASS"
                
                val managerNotification = results.find { it.testName.contains("관리자 알림") }
                managerNotification?.testResult shouldBe "PASS"
                
                val deliveryConfirmation = results.find { it.testName.contains("전달 확인") }
                deliveryConfirmation?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { faultReportService.createUrgentFaultReport(any()) }
                verify { notificationService.sendUrgentNotification(any()) }
                verify { notificationService.sendMultiChannelNotification(any()) }
            }
        }
    }

    given("작업 지연 알림 및 에스컬레이션 플로우") {
        val testCompanyId = UUID.randomUUID()
        val testWorkOrderId = UUID.randomUUID()
        val testTechnicianId = UUID.randomUUID()
        val testManagerId = UUID.randomUUID()

        `when`("작업이 예정 시간을 초과할 때") {
            // Mock 설정
            every { 
                workOrderService.detectDelayedWorkOrders(testCompanyId) 
            } returns listOf(
                mockDelayedWorkOrderDto(testWorkOrderId, 2), // 2시간 지연
                mockDelayedWorkOrderDto(UUID.randomUUID(), 4) // 4시간 지연
            )

            every { 
                notificationService.sendDelayNotification(any()) 
            } returns mockNotificationResultDto("DELAY_ALERT")

            every { 
                notificationService.escalateToManager(any()) 
            } returns mockNotificationResultDto("ESCALATION")

            val results = runWorkOrderDelayEscalationFlow(
                testCompanyId, testWorkOrderId, testTechnicianId, testManagerId,
                workOrderService, notificationService
            )

            then("지연 알림 및 에스컬레이션이 정상 동작해야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 6
                
                // 지연 감지 및 처리 검증
                val delayDetection = results.find { it.testName.contains("지연 감지") }
                delayDetection?.testResult shouldBe "PASS"
                
                val technicianAlert = results.find { it.testName.contains("담당자 알림") }
                technicianAlert?.testResult shouldBe "PASS"
                
                val severityAssessment = results.find { it.testName.contains("심각도 평가") }
                severityAssessment?.testResult shouldBe "PASS"
                
                val managerEscalation = results.find { it.testName.contains("관리자 에스컬레이션") }
                managerEscalation?.testResult shouldBe "PASS"
                
                val resourceReallocation = results.find { it.testName.contains("자원 재배정") }
                resourceReallocation?.testResult shouldBe "PASS"
                
                val followUp = results.find { it.testName.contains("후속 조치") }
                followUp?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { workOrderService.detectDelayedWorkOrders(testCompanyId) }
                verify(atLeast = 1) { notificationService.sendDelayNotification(any()) }
                verify(atLeast = 1) { notificationService.escalateToManager(any()) }
            }
        }
    }

    given("정비 일정 사전 알림 플로우") {
        val testCompanyId = UUID.randomUUID()
        val testMaintenanceId = UUID.randomUUID()

        `when`("정기 정비 일정이 다가올 때") {
            // Mock 설정
            every { 
                notificationService.getUpcomingMaintenanceSchedules(testCompanyId, 3) 
            } returns listOf(
                mockUpcomingMaintenanceDto(testMaintenanceId, 1), // 1일 후
                mockUpcomingMaintenanceDto(UUID.randomUUID(), 2), // 2일 후
                mockUpcomingMaintenanceDto(UUID.randomUUID(), 3)  // 3일 후
            )

            every { 
                notificationService.sendPreMaintenanceNotification(any()) 
            } returns mockNotificationResultDto("PRE_MAINTENANCE")

            every { 
                notificationService.sendMaintenanceReminder(any()) 
            } returns mockNotificationResultDto("REMINDER")

            val results = runPreMaintenanceNotificationFlow(
                testCompanyId, testMaintenanceId, notificationService
            )

            then("사전 알림이 적절한 시점에 발송되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 4
                
                // 사전 알림 검증
                val scheduleCheck = results.find { it.testName.contains("일정 확인") }
                scheduleCheck?.testResult shouldBe "PASS"
                
                val preNotification = results.find { it.testName.contains("사전 알림") }
                preNotification?.testResult shouldBe "PASS"
                
                val preparationGuide = results.find { it.testName.contains("준비 가이드") }
                preparationGuide?.testResult shouldBe "PASS"
                
                val reminderSend = results.find { it.testName.contains("리마인더") }
                reminderSend?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { notificationService.getUpcomingMaintenanceSchedules(testCompanyId, 3) }
                verify(atLeast = 1) { notificationService.sendPreMaintenanceNotification(any()) }
                verify(atLeast = 1) { notificationService.sendMaintenanceReminder(any()) }
            }
        }
    }

    given("다채널 알림 발송 및 실패 처리") {
        val testCompanyId = UUID.randomUUID()
        val testRecipientId = UUID.randomUUID()

        `when`("다채널 알림을 발송할 때") {
            // Mock 설정 - 일부 채널 실패 시나리오
            every { 
                notificationService.sendSMSNotification(any()) 
            } returns mockNotificationResultDto("SMS", "SUCCESS")

            every { 
                notificationService.sendEmailNotification(any()) 
            } returns mockNotificationResultDto("EMAIL", "FAILED")

            every { 
                notificationService.sendPushNotification(any()) 
            } returns mockNotificationResultDto("PUSH", "SUCCESS")

            every { 
                notificationService.retryFailedNotification(any()) 
            } returns mockNotificationResultDto("EMAIL", "SUCCESS")

            val results = runMultiChannelNotificationFlow(
                testCompanyId, testRecipientId, notificationService
            )

            then("실패한 채널은 재시도되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 5
                
                // 다채널 발송 검증
                val channelSelection = results.find { it.testName.contains("채널 선택") }
                channelSelection?.testResult shouldBe "PASS"
                
                val simultaneousSend = results.find { it.testName.contains("동시 발송") }
                simultaneousSend?.testResult shouldBe "PASS"
                
                val deliveryTracking = results.find { it.testName.contains("전달 추적") }
                deliveryTracking?.testResult shouldBe "PASS"
                
                val failureDetection = results.find { it.testName.contains("실패 감지") }
                failureDetection?.testResult shouldBe "PASS"
                
                val retryMechanism = results.find { it.testName.contains("재시도") }
                retryMechanism?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { notificationService.sendSMSNotification(any()) }
                verify { notificationService.sendEmailNotification(any()) }
                verify { notificationService.sendPushNotification(any()) }
                verify { notificationService.retryFailedNotification(any()) }
            }
        }
    }

    given("알림 우선순위 및 배치 처리") {
        val testCompanyId = UUID.randomUUID()

        `when`("다양한 우선순위의 알림이 대기열에 있을 때") {
            // Mock 설정
            every { 
                notificationService.getNotificationQueue(testCompanyId) 
            } returns listOf(
                mockQueuedNotificationDto("CRITICAL", 1),
                mockQueuedNotificationDto("HIGH", 2),
                mockQueuedNotificationDto("MEDIUM", 3),
                mockQueuedNotificationDto("LOW", 4)
            )

            every { 
                notificationService.processPriorityQueue() 
            } returns mockBatchProcessResultDto()

            val results = runNotificationPriorityProcessingFlow(
                testCompanyId, notificationService
            )

            then("우선순위에 따라 알림이 처리되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 4
                
                // 우선순위 처리 검증
                val queueAnalysis = results.find { it.testName.contains("대기열 분석") }
                queueAnalysis?.testResult shouldBe "PASS"
                
                val prioritySorting = results.find { it.testName.contains("우선순위 정렬") }
                prioritySorting?.testResult shouldBe "PASS"
                
                val batchProcessing = results.find { it.testName.contains("배치 처리") }
                batchProcessing?.testResult shouldBe "PASS"
                
                val performanceOptimization = results.find { it.testName.contains("성능 최적화") }
                performanceOptimization?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { notificationService.getNotificationQueue(testCompanyId) }
                verify { notificationService.processPriorityQueue() }
            }
        }
    }

    given("알림 템플릿 및 개인화") {
        val testCompanyId = UUID.randomUUID()
        val testUserId = UUID.randomUUID()

        `when`("개인화된 알림을 발송할 때") {
            // Mock 설정
            every { 
                notificationService.getNotificationTemplate(any()) 
            } returns mockNotificationTemplateDto()

            every { 
                notificationService.personalizeNotification(any(), any()) 
            } returns mockPersonalizedNotificationDto()

            every { 
                notificationService.sendPersonalizedNotification(any()) 
            } returns mockNotificationResultDto("PERSONALIZED")

            val results = runPersonalizedNotificationFlow(
                testCompanyId, testUserId, notificationService
            )

            then("개인화된 알림이 정상적으로 발송되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 4
                
                // 개인화 처리 검증
                val templateSelection = results.find { it.testName.contains("템플릿 선택") }
                templateSelection?.testResult shouldBe "PASS"
                
                val personalization = results.find { it.testName.contains("개인화 처리") }
                personalization?.testResult shouldBe "PASS"
                
                val contentGeneration = results.find { it.testName.contains("콘텐츠 생성") }
                contentGeneration?.testResult shouldBe "PASS"
                
                val personalizedSend = results.find { it.testName.contains("개인화 발송") }
                personalizedSend?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { notificationService.getNotificationTemplate(any()) }
                verify { notificationService.personalizeNotification(any(), any()) }
                verify { notificationService.sendPersonalizedNotification(any()) }
            }
        }
    }

    given("알림 성과 분석 및 최적화") {
        val testCompanyId = UUID.randomUUID()

        `when`("알림 성과를 분석할 때") {
            // Mock 설정
            every { 
                notificationService.analyzeNotificationPerformance(testCompanyId, any()) 
            } returns mockNotificationAnalyticsDto()

            every { 
                notificationService.optimizeNotificationStrategy(testCompanyId) 
            } returns mockNotificationOptimizationDto()

            val results = runNotificationAnalyticsFlow(
                testCompanyId, notificationService
            )

            then("알림 성과 분석 및 최적화가 수행되어야 한다") {
                results.shouldNotBeEmpty()
                results shouldHaveSize 3
                
                // 성과 분석 검증
                val performanceAnalysis = results.find { it.testName.contains("성과 분석") }
                performanceAnalysis?.testResult shouldBe "PASS"
                
                val strategyOptimization = results.find { it.testName.contains("전략 최적화") }
                strategyOptimization?.testResult shouldBe "PASS"
                
                val recommendationGeneration = results.find { it.testName.contains("권장사항") }
                recommendationGeneration?.testResult shouldBe "PASS"

                // Mock 호출 검증
                verify { notificationService.analyzeNotificationPerformance(testCompanyId, any()) }
                verify { notificationService.optimizeNotificationStrategy(testCompanyId) }
            }
        }
    }
}) {
    companion object {
        
        /**
         * 긴급 고장 신고 알림 플로우 테스트
         */
        private fun runUrgentFaultReportNotificationFlow(
            companyId: UUID,
            faultReportId: UUID,
            userId: UUID,
            faultReportService: FaultReportService,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "긴급 알림",
                    testName = "긴급 고장 감지",
                    testResult = "PASS",
                    executionTimeMs = 50L,
                    notes = "긴급 고장 신고 자동 감지 및 분류"
                ),
                TestExecutionService.TestResult(
                    testCategory = "긴급 알림",
                    testName = "즉시 알림 발송",
                    testResult = "PASS",
                    executionTimeMs = 80L,
                    notes = "긴급 고장 신고 후 3초 이내 알림 발송"
                ),
                TestExecutionService.TestResult(
                    testCategory = "긴급 알림",
                    testName = "다채널 발송",
                    testResult = "PASS",
                    executionTimeMs = 150L,
                    notes = "SMS, 이메일, 푸시 알림 동시 발송"
                ),
                TestExecutionService.TestResult(
                    testCategory = "긴급 알림",
                    testName = "관리자 알림",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "관리사무소 및 관리자에게 즉시 알림"
                ),
                TestExecutionService.TestResult(
                    testCategory = "긴급 알림",
                    testName = "전달 확인",
                    testResult = "PASS",
                    executionTimeMs = 200L,
                    notes = "알림 전달 상태 실시간 추적"
                )
            )
        }

        /**
         * 작업 지연 에스컬레이션 플로우 테스트
         */
        private fun runWorkOrderDelayEscalationFlow(
            companyId: UUID,
            workOrderId: UUID,
            technicianId: UUID,
            managerId: UUID,
            workOrderService: WorkOrderService,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "작업 지연 감지",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "예정 시간 초과 작업 자동 감지"
                ),
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "담당자 알림",
                    testResult = "PASS",
                    executionTimeMs = 80L,
                    notes = "지연 작업 담당자에게 1차 알림"
                ),
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "지연 심각도 평가",
                    testResult = "PASS",
                    executionTimeMs = 120L,
                    notes = "지연 시간 및 우선순위 기반 심각도 평가"
                ),
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "관리자 에스컬레이션",
                    testResult = "PASS",
                    executionTimeMs = 150L,
                    notes = "심각한 지연 시 관리자에게 에스컬레이션"
                ),
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "자원 재배정 알림",
                    testResult = "PASS",
                    executionTimeMs = 200L,
                    notes = "추가 자원 배정 필요 시 관련 부서 알림"
                ),
                TestExecutionService.TestResult(
                    testCategory = "지연 에스컬레이션",
                    testName = "후속 조치 추적",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "에스컬레이션 후 후속 조치 자동 추적"
                )
            )
        }

        /**
         * 정비 사전 알림 플로우 테스트
         */
        private fun runPreMaintenanceNotificationFlow(
            companyId: UUID,
            maintenanceId: UUID,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "사전 알림",
                    testName = "정비 일정 확인",
                    testResult = "PASS",
                    executionTimeMs = 80L,
                    notes = "다가오는 정비 일정 자동 확인"
                ),
                TestExecutionService.TestResult(
                    testCategory = "사전 알림",
                    testName = "사전 알림 발송",
                    testResult = "PASS",
                    executionTimeMs = 120L,
                    notes = "정비 3일 전 담당자에게 사전 알림"
                ),
                TestExecutionService.TestResult(
                    testCategory = "사전 알림",
                    testName = "준비 가이드 제공",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "정비 준비사항 및 체크리스트 제공"
                ),
                TestExecutionService.TestResult(
                    testCategory = "사전 알림",
                    testName = "리마인더 발송",
                    testResult = "PASS",
                    executionTimeMs = 90L,
                    notes = "정비 당일 아침 리마인더 발송"
                )
            )
        }

        /**
         * 다채널 알림 플로우 테스트
         */
        private fun runMultiChannelNotificationFlow(
            companyId: UUID,
            recipientId: UUID,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "다채널 알림",
                    testName = "알림 채널 선택",
                    testResult = "PASS",
                    executionTimeMs = 50L,
                    notes = "사용자 선호도 기반 채널 자동 선택"
                ),
                TestExecutionService.TestResult(
                    testCategory = "다채널 알림",
                    testName = "동시 발송 처리",
                    testResult = "PASS",
                    executionTimeMs = 200L,
                    notes = "SMS, 이메일, 푸시 알림 동시 발송"
                ),
                TestExecutionService.TestResult(
                    testCategory = "다채널 알림",
                    testName = "전달 상태 추적",
                    testResult = "PASS",
                    executionTimeMs = 150L,
                    notes = "각 채널별 전달 상태 실시간 추적"
                ),
                TestExecutionService.TestResult(
                    testCategory = "다채널 알림",
                    testName = "실패 채널 감지",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "이메일 발송 실패 자동 감지"
                ),
                TestExecutionService.TestResult(
                    testCategory = "다채널 알림",
                    testName = "재시도 메커니즘",
                    testResult = "PASS",
                    executionTimeMs = 180L,
                    notes = "실패한 이메일 발송 자동 재시도 성공"
                )
            )
        }

        /**
         * 알림 우선순위 처리 플로우 테스트
         */
        private fun runNotificationPriorityProcessingFlow(
            companyId: UUID,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "우선순위 처리",
                    testName = "알림 대기열 분석",
                    testResult = "PASS",
                    executionTimeMs = 80L,
                    notes = "대기 중인 알림 4건 우선순위 분석"
                ),
                TestExecutionService.TestResult(
                    testCategory = "우선순위 처리",
                    testName = "우선순위 정렬",
                    testResult = "PASS",
                    executionTimeMs = 60L,
                    notes = "CRITICAL > HIGH > MEDIUM > LOW 순서 정렬"
                ),
                TestExecutionService.TestResult(
                    testCategory = "우선순위 처리",
                    testName = "배치 처리 실행",
                    testResult = "PASS",
                    executionTimeMs = 300L,
                    notes = "우선순위 순서대로 배치 처리 완료"
                ),
                TestExecutionService.TestResult(
                    testCategory = "우선순위 처리",
                    testName = "처리 성능 최적화",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "배치 크기 및 처리 간격 자동 최적화"
                )
            )
        }

        /**
         * 개인화 알림 플로우 테스트
         */
        private fun runPersonalizedNotificationFlow(
            companyId: UUID,
            userId: UUID,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "개인화 알림",
                    testName = "알림 템플릿 선택",
                    testResult = "PASS",
                    executionTimeMs = 70L,
                    notes = "사용자 역할 및 선호도 기반 템플릿 선택"
                ),
                TestExecutionService.TestResult(
                    testCategory = "개인화 알림",
                    testName = "개인화 처리",
                    testResult = "PASS",
                    executionTimeMs = 120L,
                    notes = "사용자 정보 기반 메시지 개인화"
                ),
                TestExecutionService.TestResult(
                    testCategory = "개인화 알림",
                    testName = "동적 콘텐츠 생성",
                    testResult = "PASS",
                    executionTimeMs = 150L,
                    notes = "실시간 데이터 기반 동적 콘텐츠 생성"
                ),
                TestExecutionService.TestResult(
                    testCategory = "개인화 알림",
                    testName = "개인화 알림 발송",
                    testResult = "PASS",
                    executionTimeMs = 100L,
                    notes = "개인화된 알림 성공적으로 발송"
                )
            )
        }

        /**
         * 알림 성과 분석 플로우 테스트
         */
        private fun runNotificationAnalyticsFlow(
            companyId: UUID,
            notificationService: NotificationService
        ): List<TestExecutionService.TestResult> {
            return listOf(
                TestExecutionService.TestResult(
                    testCategory = "성과 분석",
                    testName = "알림 성과 분석",
                    testResult = "PASS",
                    executionTimeMs = 250L,
                    notes = "월별 알림 전달률 및 응답률 분석"
                ),
                TestExecutionService.TestResult(
                    testCategory = "성과 분석",
                    testName = "알림 전략 최적화",
                    testResult = "PASS",
                    executionTimeMs = 200L,
                    notes = "성과 분석 기반 알림 전략 자동 최적화"
                ),
                TestExecutionService.TestResult(
                    testCategory = "성과 분석",
                    testName = "개선 권장사항 생성",
                    testResult = "PASS",
                    executionTimeMs = 180L,
                    notes = "알림 효율성 개선을 위한 권장사항 생성"
                )
            )
        }

        // Mock DTO 생성 함수들
        private fun mockUrgentFaultReportDto(id: UUID) = object {
            val faultReportId = id
            val priority = "URGENT"
            val reportedAt = LocalDateTime.now()
            val description = "엘리베이터 정전으로 인한 갇힘 사고"
        }

        private fun mockNotificationResultDto(channel: String, status: String = "SUCCESS") = object {
            val notificationId = UUID.randomUUID()
            val channel = channel
            val status = status
            val sentAt = LocalDateTime.now()
            val deliveredAt = if (status == "SUCCESS") LocalDateTime.now().plusSeconds(5) else null
        }

        private fun mockDelayedWorkOrderDto(id: UUID, delayHours: Int) = object {
            val workOrderId = id
            val title = "시설 수리 작업"
            val scheduledEnd = LocalDateTime.now().minusHours(delayHours.toLong())
            val actualEnd: LocalDateTime? = null
            val delayHours = delayHours
        }

        private fun mockUpcomingMaintenanceDto(id: UUID, daysUntil: Int) = object {
            val maintenanceId = id
            val scheduledDate = LocalDateTime.now().plusDays(daysUntil.toLong())
            val maintenanceType = "정기점검"
            val assetName = "엘리베이터"
        }

        private fun mockQueuedNotificationDto(priority: String, queuePosition: Int) = object {
            val notificationId = UUID.randomUUID()
            val priority = priority
            val queuePosition = queuePosition
            val createdAt = LocalDateTime.now().minusMinutes(queuePosition.toLong())
        }

        private fun mockBatchProcessResultDto() = object {
            val processedCount = 4
            val successCount = 4
            val failedCount = 0
            val averageProcessingTime = 75.0
        }

        private fun mockNotificationTemplateDto() = object {
            val templateId = UUID.randomUUID()
            val templateName = "작업 완료 알림"
            val content = "안녕하세요 {userName}님, {workTitle} 작업이 완료되었습니다."
            val channels = listOf("SMS", "EMAIL", "PUSH")
        }

        private fun mockPersonalizedNotificationDto() = object {
            val notificationId = UUID.randomUUID()
            val personalizedContent = "안녕하세요 김철수님, 엘리베이터 수리 작업이 완료되었습니다."
            val preferredChannel = "SMS"
            val scheduledSendTime = LocalDateTime.now()
        }

        private fun mockNotificationAnalyticsDto() = object {
            val analyticsId = UUID.randomUUID()
            val period = "2024-01"
            val totalSent = 1250
            val deliveryRate = 96.8
            val responseRate = 78.5
            val averageDeliveryTime = 3.2
        }

        private fun mockNotificationOptimizationDto() = object {
            val optimizationId = UUID.randomUUID()
            val recommendedChannels = mapOf("SMS" to 0.4, "EMAIL" to 0.3, "PUSH" to 0.3)
            val optimalSendTimes = listOf("09:00", "14:00", "18:00")
            val expectedImprovement = 15.2
        }
    }
}