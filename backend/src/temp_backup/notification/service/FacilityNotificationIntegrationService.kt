package com.qiro.domain.notification.service

import com.qiro.common.tenant.TenantContext
import com.qiro.domain.fault.entity.FaultReport
import com.qiro.domain.notification.dto.SendNotificationRequest
import com.qiro.domain.notification.dto.SendUrgentAlertRequest
import com.qiro.domain.notification.entity.NotificationMethod
import com.qiro.domain.notification.entity.NotificationType
import com.qiro.domain.workorder.entity.WorkOrder
import org.slf4j.LoggerFactory
import org.springframework.context.event.EventListener
import org.springframework.stereotype.Service
import java.util.*

/**
 * 시설 관리 시스템과 알림 시스템 통합 서비스
 * 시설 관리 이벤트에 따른 자동 알림 발송을 처리합니다.
 */
@Service
class FacilityNotificationIntegrationService(
    private val notificationService: NotificationService,
    private val notificationEscalationService: NotificationEscalationService,
    private val notificationSettingService: NotificationSettingService
) {
    private val logger = LoggerFactory.getLogger(FacilityNotificationIntegrationService::class.java)

    /**
     * 고장 신고 접수 시 알림 발송
     */
    fun sendFaultReportNotification(faultReport: FaultReport) {
        try {
            val companyId = TenantContext.getCurrentCompanyId()
            
            // 긴급도에 따른 알림 처리
            when (faultReport.priority) {
                "URGENT", "HIGH" -> {
                    // 긴급 알림 발송
                    notificationEscalationService.triggerFacilityEmergencyAlert(
                        facilityName = faultReport.assetId?.toString() ?: "알 수 없는 시설",
                        faultDescription = faultReport.description ?: "",
                        location = faultReport.location ?: "",
                        reporterId = faultReport.reporterId ?: UUID.randomUUID()
                    )
                }
                else -> {
                    // 일반 알림 발송
                    sendGeneralFaultReportNotification(faultReport)
                }
            }

            logger.info("고장 신고 알림 발송 완료 - 신고 ID: ${faultReport.id}")
        } catch (e: Exception) {
            logger.error("고장 신고 알림 발송 실패 - 신고 ID: ${faultReport.id}", e)
        }
    }

    /**
     * 작업 지시서 배정 시 알림 발송
     */
    fun sendWorkOrderAssignmentNotification(workOrder: WorkOrder) {
        try {
            val assignedTo = workOrder.assignedTo ?: return
            
            val request = SendNotificationRequest(
                recipientIds = listOf(assignedTo),
                notificationType = NotificationType.WORK_ORDER_ASSIGNED,
                title = "새로운 작업이 배정되었습니다",
                message = """
                    작업 번호: ${workOrder.workOrderNumber}
                    작업 제목: ${workOrder.title}
                    우선순위: ${workOrder.priority}
                    예정 시작일: ${workOrder.scheduledStart}
                    예정 완료일: ${workOrder.scheduledEnd}
                """.trimIndent(),
                channels = setOf(NotificationMethod.EMAIL, NotificationMethod.PUSH),
                priorityLevel = getPriorityLevel(workOrder.priority),
                metadata = mapOf(
                    "work_order_id" to workOrder.id.toString(),
                    "work_order_number" to workOrder.workOrderNumber,
                    "asset_id" to (workOrder.assetId?.toString() ?: "")
                )
            )

            notificationService.sendNotification(request)
            logger.info("작업 지시서 배정 알림 발송 완료 - 작업 ID: ${workOrder.id}")
        } catch (e: Exception) {
            logger.error("작업 지시서 배정 알림 발송 실패 - 작업 ID: ${workOrder.id}", e)
        }
    }

    /**
     * 작업 완료 시 알림 발송
     */
    fun sendWorkOrderCompletionNotification(workOrder: WorkOrder) {
        try {
            // 신고자에게 완료 알림 발송
            val faultReportId = workOrder.faultReportId
            if (faultReportId != null) {
                sendCompletionNotificationToReporter(workOrder, faultReportId)
            }

            // 관리자에게 완료 보고
            sendCompletionNotificationToManagers(workOrder)

            logger.info("작업 완료 알림 발송 완료 - 작업 ID: ${workOrder.id}")
        } catch (e: Exception) {
            logger.error("작업 완료 알림 발송 실패 - 작업 ID: ${workOrder.id}", e)
        }
    }

    /**
     * 정비 일정 알림 발송
     */
    fun sendMaintenanceReminderNotification(
        assetId: UUID,
        maintenanceType: String,
        scheduledDate: String,
        assignedTo: UUID
    ) {
        try {
            val request = SendNotificationRequest(
                recipientIds = listOf(assignedTo),
                notificationType = NotificationType.MAINTENANCE_DUE,
                title = "정비 일정 알림",
                message = """
                    정비 유형: $maintenanceType
                    예정일: $scheduledDate
                    시설 ID: $assetId
                    
                    정비 일정이 다가왔습니다. 준비해 주세요.
                """.trimIndent(),
                channels = setOf(NotificationMethod.EMAIL, NotificationMethod.PUSH),
                priorityLevel = 3,
                metadata = mapOf(
                    "asset_id" to assetId.toString(),
                    "maintenance_type" to maintenanceType,
                    "scheduled_date" to scheduledDate
                )
            )

            notificationService.sendNotification(request)
            logger.info("정비 일정 알림 발송 완료 - 시설 ID: $assetId")
        } catch (e: Exception) {
            logger.error("정비 일정 알림 발송 실패 - 시설 ID: $assetId", e)
        }
    }

    /**
     * 시설 경고 알림 발송
     */
    fun sendFacilityAlertNotification(
        assetId: UUID,
        alertType: String,
        alertMessage: String,
        severity: String
    ) {
        try {
            val isUrgent = severity in listOf("CRITICAL", "HIGH")
            
            if (isUrgent) {
                // 긴급 경고는 에스컬레이션 처리
                notificationEscalationService.triggerUrgentAlert(
                    title = "시설 경고 발생",
                    message = """
                        시설 ID: $assetId
                        경고 유형: $alertType
                        심각도: $severity
                        내용: $alertMessage
                    """.trimIndent(),
                    metadata = mapOf(
                        "asset_id" to assetId.toString(),
                        "alert_type" to alertType,
                        "severity" to severity
                    )
                )
            } else {
                // 일반 경고는 표준 알림
                sendGeneralFacilityAlert(assetId, alertType, alertMessage, severity)
            }

            logger.info("시설 경고 알림 발송 완료 - 시설 ID: $assetId, 심각도: $severity")
        } catch (e: Exception) {
            logger.error("시설 경고 알림 발송 실패 - 시설 ID: $assetId", e)
        }
    }

    /**
     * 일반 고장 신고 알림 발송
     */
    private fun sendGeneralFaultReportNotification(faultReport: FaultReport) {
        val managers = getManagerRecipients()
        
        if (managers.isNotEmpty()) {
            val request = SendNotificationRequest(
                recipientIds = managers,
                notificationType = NotificationType.FAULT_REPORT,
                title = "새로운 고장 신고",
                message = """
                    신고 번호: ${faultReport.reportNumber}
                    제목: ${faultReport.title}
                    위치: ${faultReport.location ?: "미지정"}
                    우선순위: ${faultReport.priority}
                    신고 내용: ${faultReport.description ?: ""}
                """.trimIndent(),
                channels = setOf(NotificationMethod.EMAIL, NotificationMethod.IN_APP),
                priorityLevel = getPriorityLevel(faultReport.priority),
                metadata = mapOf(
                    "fault_report_id" to faultReport.id.toString(),
                    "report_number" to faultReport.reportNumber,
                    "asset_id" to (faultReport.assetId?.toString() ?: "")
                )
            )

            notificationService.sendNotification(request)
        }
    }

    /**
     * 신고자에게 완료 알림 발송
     */
    private fun sendCompletionNotificationToReporter(workOrder: WorkOrder, faultReportId: UUID) {
        // TODO: FaultReport에서 신고자 정보 조회
        // 현재는 임시로 처리
        val reporterId = UUID.randomUUID() // 실제로는 faultReport.reporterId 사용
        
        val request = SendNotificationRequest(
            recipientIds = listOf(reporterId),
            notificationType = NotificationType.WORK_ORDER_COMPLETED,
            title = "신고하신 고장이 수리 완료되었습니다",
            message = """
                작업 번호: ${workOrder.workOrderNumber}
                작업 내용: ${workOrder.title}
                완료 시간: ${workOrder.actualEnd}
                작업 결과: ${workOrder.completionNotes ?: "정상 완료"}
            """.trimIndent(),
            channels = setOf(NotificationMethod.SMS, NotificationMethod.EMAIL),
            priorityLevel = 2,
            metadata = mapOf(
                "work_order_id" to workOrder.id.toString(),
                "fault_report_id" to faultReportId.toString()
            )
        )

        notificationService.sendNotification(request)
    }

    /**
     * 관리자에게 완료 보고
     */
    private fun sendCompletionNotificationToManagers(workOrder: WorkOrder) {
        val managers = getManagerRecipients()
        
        if (managers.isNotEmpty()) {
            val request = SendNotificationRequest(
                recipientIds = managers,
                notificationType = NotificationType.WORK_ORDER_COMPLETED,
                title = "작업 완료 보고",
                message = """
                    작업 번호: ${workOrder.workOrderNumber}
                    작업자: ${workOrder.assignedTo}
                    완료 시간: ${workOrder.actualEnd}
                    소요 시간: ${calculateWorkDuration(workOrder)}
                    작업 결과: ${workOrder.completionNotes ?: "정상 완료"}
                """.trimIndent(),
                channels = setOf(NotificationMethod.EMAIL, NotificationMethod.IN_APP),
                priorityLevel = 3,
                metadata = mapOf(
                    "work_order_id" to workOrder.id.toString(),
                    "assigned_to" to (workOrder.assignedTo?.toString() ?: "")
                )
            )

            notificationService.sendNotification(request)
        }
    }

    /**
     * 일반 시설 경고 알림 발송
     */
    private fun sendGeneralFacilityAlert(
        assetId: UUID,
        alertType: String,
        alertMessage: String,
        severity: String
    ) {
        val recipients = getFacilityManagerRecipients()
        
        if (recipients.isNotEmpty()) {
            val request = SendNotificationRequest(
                recipientIds = recipients,
                notificationType = NotificationType.FACILITY_ALERT,
                title = "시설 경고",
                message = """
                    시설 ID: $assetId
                    경고 유형: $alertType
                    심각도: $severity
                    내용: $alertMessage
                """.trimIndent(),
                channels = setOf(NotificationMethod.EMAIL, NotificationMethod.IN_APP),
                priorityLevel = getSeverityPriorityLevel(severity),
                metadata = mapOf(
                    "asset_id" to assetId.toString(),
                    "alert_type" to alertType,
                    "severity" to severity
                )
            )

            notificationService.sendNotification(request)
        }
    }

    /**
     * 우선순위 문자열을 숫자로 변환
     */
    private fun getPriorityLevel(priority: String?): Int {
        return when (priority?.uppercase()) {
            "URGENT" -> 1
            "HIGH" -> 2
            "MEDIUM" -> 3
            "LOW" -> 4
            else -> 3
        }
    }

    /**
     * 심각도를 우선순위 레벨로 변환
     */
    private fun getSeverityPriorityLevel(severity: String): Int {
        return when (severity.uppercase()) {
            "CRITICAL" -> 1
            "HIGH" -> 2
            "MEDIUM" -> 3
            "LOW" -> 4
            "INFO" -> 5
            else -> 3
        }
    }

    /**
     * 작업 소요 시간 계산
     */
    private fun calculateWorkDuration(workOrder: WorkOrder): String {
        val start = workOrder.actualStart
        val end = workOrder.actualEnd
        
        return if (start != null && end != null) {
            val duration = java.time.Duration.between(start, end)
            "${duration.toHours()}시간 ${duration.toMinutesPart()}분"
        } else {
            "미확인"
        }
    }

    /**
     * 관리자 수신자 목록 조회
     */
    private fun getManagerRecipients(): List<UUID> {
        // TODO: 실제 관리자 목록 조회 로직 구현
        // 현재는 임시 데이터 반환
        return listOf(
            UUID.fromString("00000000-0000-0000-0000-000000000001"),
            UUID.fromString("00000000-0000-0000-0000-000000000002")
        )
    }

    /**
     * 시설 관리자 수신자 목록 조회
     */
    private fun getFacilityManagerRecipients(): List<UUID> {
        // TODO: 실제 시설 관리자 목록 조회 로직 구현
        // 현재는 임시 데이터 반환
        return listOf(
            UUID.fromString("00000000-0000-0000-0000-000000000003"),
            UUID.fromString("00000000-0000-0000-0000-000000000004")
        )
    }
}