package com.qiro.domain.mobile.service

import com.qiro.domain.mobile.dto.*
import com.qiro.domain.workorder.dto.WorkOrderPriority
import com.qiro.domain.workorder.dto.WorkOrderStatus
import com.qiro.domain.workorder.service.WorkOrderService
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.*

/**
 * 모바일 작업 지시서 서비스
 */
@Service
@Transactional
class MobileWorkOrderService(
    private val workOrderService: WorkOrderService
) {

    /**
     * 모바일 작업 지시서 목록 조회
     */
    @Transactional(readOnly = true)
    fun getMobileWorkOrders(
        companyId: UUID,
        filter: MobileWorkOrderFilter?,
        pageable: Pageable
    ): Page<MobileWorkOrderListDto> {
        // 필터를 기존 서비스 필터로 변환
        val workOrderFilter = filter?.let { mobileFilter ->
            com.qiro.domain.workorder.dto.WorkOrderFilter(
                status = mobileFilter.status,
                priority = mobileFilter.priority,
                workType = mobileFilter.workType,
                assignedTechnicianId = if (mobileFilter.assignedToMe) UUID.randomUUID() else null, // 실제로는 현재 사용자 ID
                startDate = mobileFilter.dateRange?.startDate?.toLocalDate(),
                endDate = mobileFilter.dateRange?.endDate?.toLocalDate(),
                location = mobileFilter.location
            )
        }
        
        val workOrders = if (workOrderFilter != null) {
            workOrderService.getWorkOrdersWithFilter(companyId, workOrderFilter, pageable)
        } else {
            workOrderService.getWorkOrders(companyId, pageable)
        }
        
        val mobileList = workOrders.content.map { convertToMobileListDto(it) }
        return PageImpl(mobileList, pageable, workOrders.totalElements)
    }

    /**
     * 모바일 작업 지시서 상세 조회
     */
    @Transactional(readOnly = true)
    fun getMobileWorkOrderDetail(workOrderId: UUID): MobileWorkOrderDetailDto {
        val workOrder = workOrderService.getWorkOrder(workOrderId)
        return convertToMobileDetailDto(workOrder)
    }

    /**
     * 작업 시작
     */
    fun startWorkOrder(
        workOrderId: UUID,
        request: StartWorkOrderRequest,
        technicianId: UUID
    ): MobileWorkOrderDto {
        val startRequest = com.qiro.domain.workorder.dto.StartWorkOrderRequest(
            actualStartTime = request.actualStartTime,
            startNotes = request.startNotes
        )
        
        val workOrder = workOrderService.startWorkOrder(workOrderId, startRequest, technicianId)
        return convertToMobileDto(workOrder)
    }

    /**
     * 작업 완료
     */
    fun completeWorkOrder(
        workOrderId: UUID,
        request: CompleteWorkOrderRequest,
        technicianId: UUID
    ): MobileWorkOrderDto {
        val completeRequest = com.qiro.domain.workorder.dto.CompleteWorkOrderRequest(
            actualEndTime = request.actualEndTime,
            completionNotes = request.completionNotes,
            workQuality = request.workQuality,
            laborHours = request.laborHours,
            followUpRequired = request.followUpRequired,
            followUpNotes = request.followUpNotes
        )
        
        val workOrder = workOrderService.completeWorkOrder(workOrderId, completeRequest, technicianId)
        return convertToMobileDto(workOrder)
    }

    /**
     * 작업 상태 업데이트
     */
    fun updateWorkOrderStatus(
        workOrderId: UUID,
        request: UpdateWorkOrderStatusRequest,
        technicianId: UUID
    ): MobileWorkOrderDto {
        val updateRequest = com.qiro.domain.workorder.dto.UpdateWorkOrderStatusRequest(
            status = request.status,
            notes = request.notes,
            completionPercentage = request.completionPercentage
        )
        
        val workOrder = workOrderService.updateWorkOrderStatus(workOrderId, updateRequest, technicianId)
        return convertToMobileDto(workOrder)
    }

    /**
     * 체크리스트 항목 업데이트
     */
    fun updateChecklistItem(
        workOrderId: UUID,
        itemId: UUID,
        request: UpdateChecklistItemRequest,
        technicianId: UUID
    ): ChecklistItemDto {
        // 실제 구현에서는 체크리스트 서비스를 호출해야 함
        return ChecklistItemDto(
            itemId = itemId,
            description = "체크리스트 항목",
            isRequired = true,
            isCompleted = request.isCompleted,
            completedAt = if (request.isCompleted) LocalDateTime.now() else null,
            notes = request.notes,
            photoRequired = false,
            photos = request.photos.map { photoUrl ->
                PhotoDto(
                    photoId = UUID.randomUUID(),
                    fileName = photoUrl.substringAfterLast("/"),
                    thumbnailUrl = photoUrl,
                    fullUrl = photoUrl,
                    uploadedAt = LocalDateTime.now()
                )
            }
        )
    }

    /**
     * 기술자별 작업 지시서 조회
     */
    @Transactional(readOnly = true)
    fun getWorkOrdersByTechnician(
        companyId: UUID,
        technicianId: UUID,
        pageable: Pageable
    ): Page<MobileWorkOrderListDto> {
        val workOrders = workOrderService.getWorkOrdersByTechnician(companyId, technicianId, pageable)
        val mobileList = workOrders.content.map { convertToMobileListDto(it) }
        return PageImpl(mobileList, pageable, workOrders.totalElements)
    }

    /**
     * 기술자 일일 요약 조회
     */
    @Transactional(readOnly = true)
    fun getTechnicianDailySummary(
        companyId: UUID,
        technicianId: UUID,
        date: String
    ): TechnicianDailySummaryDto {
        // 실제 구현에서는 통계 서비스를 호출해야 함
        val upcomingWorkOrders = getWorkOrdersByTechnician(companyId, technicianId, Pageable.ofSize(5))
        
        return TechnicianDailySummaryDto(
            date = date,
            totalWorkOrders = 8,
            completedWorkOrders = 5,
            inProgressWorkOrders = 2,
            overdueWorkOrders = 1,
            totalHoursWorked = BigDecimal("7.5"),
            averageCompletionTime = BigDecimal("1.5"),
            upcomingWorkOrders = upcomingWorkOrders.content
        )
    }

    /**
     * WorkOrderDto를 MobileWorkOrderDto로 변환
     */
    private fun convertToMobileDto(workOrder: com.qiro.domain.workorder.dto.WorkOrderDto): MobileWorkOrderDto {
        return MobileWorkOrderDto(
            workOrderId = workOrder.workOrderId,
            workOrderNumber = workOrder.workOrderNumber,
            title = workOrder.title,
            description = workOrder.description,
            priority = workOrder.priority,
            status = workOrder.status,
            workType = workOrder.workType,
            location = workOrder.location,
            scheduledStart = workOrder.scheduledStart,
            scheduledEnd = workOrder.scheduledEnd,
            actualStart = workOrder.actualStart,
            actualEnd = workOrder.actualEnd,
            assignedTechnician = workOrder.assignedTechnicianName?.let {
                TechnicianInfo(
                    technicianId = UUID.randomUUID(), // 실제로는 기술자 ID
                    name = it,
                    phone = null,
                    specialization = null
                )
            },
            estimatedDuration = workOrder.scheduledStart?.let { start ->
                workOrder.scheduledEnd?.let { end ->
                    ChronoUnit.MINUTES.between(start, end).toInt()
                }
            },
            actualDuration = workOrder.actualStart?.let { start ->
                workOrder.actualEnd?.let { end ->
                    ChronoUnit.MINUTES.between(start, end).toInt()
                }
            },
            completionPercentage = calculateCompletionPercentage(workOrder.status),
            canStart = canStartWork(workOrder.status),
            canComplete = canCompleteWork(workOrder.status),
            canPause = canPauseWork(workOrder.status),
            requiresSignature = requiresSignature(workOrder.workType)
        )
    }

    /**
     * WorkOrderDto를 MobileWorkOrderListDto로 변환
     */
    private fun convertToMobileListDto(workOrder: com.qiro.domain.workorder.dto.WorkOrderDto): MobileWorkOrderListDto {
        return MobileWorkOrderListDto(
            workOrderId = workOrder.workOrderId,
            workOrderNumber = workOrder.workOrderNumber,
            title = workOrder.title,
            priority = workOrder.priority,
            status = workOrder.status,
            workType = workOrder.workType,
            location = workOrder.location,
            scheduledStart = workOrder.scheduledStart,
            assignedTechnician = workOrder.assignedTechnicianName,
            statusBadge = getWorkOrderStatusBadge(workOrder.status),
            isOverdue = isOverdue(workOrder.scheduledEnd),
            estimatedDuration = workOrder.scheduledStart?.let { start ->
                workOrder.scheduledEnd?.let { end ->
                    ChronoUnit.MINUTES.between(start, end).toInt()
                }
            }
        )
    }

    /**
     * WorkOrderDto를 MobileWorkOrderDetailDto로 변환
     */
    private fun convertToMobileDetailDto(workOrder: com.qiro.domain.workorder.dto.WorkOrderDto): MobileWorkOrderDetailDto {
        return MobileWorkOrderDetailDto(
            workOrderId = workOrder.workOrderId,
            workOrderNumber = workOrder.workOrderNumber,
            title = workOrder.title,
            description = workOrder.description,
            priority = workOrder.priority,
            status = workOrder.status,
            workType = workOrder.workType,
            location = workOrder.location,
            scheduledStart = workOrder.scheduledStart,
            scheduledEnd = workOrder.scheduledEnd,
            actualStart = workOrder.actualStart,
            actualEnd = workOrder.actualEnd,
            assignedTechnician = workOrder.assignedTechnicianName?.let {
                TechnicianInfo(
                    technicianId = UUID.randomUUID(),
                    name = it,
                    phone = null,
                    specialization = null
                )
            },
            estimatedCost = workOrder.estimatedCost,
            actualCost = workOrder.actualCost,
            workInstructions = workOrder.workNotes,
            safetyNotes = "안전 수칙을 준수하세요",
            requiredTools = listOf("드라이버", "렌치", "멀티미터"),
            requiredParts = generateRequiredParts(),
            checklistItems = generateChecklistItems(),
            workPhotos = emptyList(),
            workNotes = workOrder.workNotes,
            completionNotes = workOrder.completionNotes,
            timeline = generateWorkOrderTimeline(workOrder),
            canStart = canStartWork(workOrder.status),
            canComplete = canCompleteWork(workOrder.status),
            canPause = canPauseWork(workOrder.status),
            requiresSignature = requiresSignature(workOrder.workType)
        )
    }

    /**
     * 작업 지시서 상태 배지 생성
     */
    private fun getWorkOrderStatusBadge(status: WorkOrderStatus): StatusBadge {
        return when (status) {
            WorkOrderStatus.CREATED -> StatusBadge("생성됨", "#FFFFFF", "#6B7280")
            WorkOrderStatus.ASSIGNED -> StatusBadge("배정됨", "#FFFFFF", "#3B82F6")
            WorkOrderStatus.IN_PROGRESS -> StatusBadge("진행중", "#FFFFFF", "#F59E0B")
            WorkOrderStatus.ON_HOLD -> StatusBadge("보류", "#FFFFFF", "#EF4444")
            WorkOrderStatus.COMPLETED -> StatusBadge("완료됨", "#FFFFFF", "#10B981")
            WorkOrderStatus.VERIFIED -> StatusBadge("확인됨", "#FFFFFF", "#059669")
            WorkOrderStatus.CANCELLED -> StatusBadge("취소됨", "#FFFFFF", "#EF4444")
        }
    }

    /**
     * 완료율 계산
     */
    private fun calculateCompletionPercentage(status: WorkOrderStatus): Int {
        return when (status) {
            WorkOrderStatus.CREATED -> 0
            WorkOrderStatus.ASSIGNED -> 10
            WorkOrderStatus.IN_PROGRESS -> 50
            WorkOrderStatus.ON_HOLD -> 30
            WorkOrderStatus.COMPLETED -> 100
            WorkOrderStatus.VERIFIED -> 100
            WorkOrderStatus.CANCELLED -> 0
        }
    }

    /**
     * 작업 시작 가능 여부 확인
     */
    private fun canStartWork(status: WorkOrderStatus): Boolean {
        return status == WorkOrderStatus.ASSIGNED
    }

    /**
     * 작업 완료 가능 여부 확인
     */
    private fun canCompleteWork(status: WorkOrderStatus): Boolean {
        return status == WorkOrderStatus.IN_PROGRESS
    }

    /**
     * 작업 일시정지 가능 여부 확인
     */
    private fun canPauseWork(status: WorkOrderStatus): Boolean {
        return status == WorkOrderStatus.IN_PROGRESS
    }

    /**
     * 서명 필요 여부 확인
     */
    private fun requiresSignature(workType: String): Boolean {
        return workType in listOf("ELECTRICAL", "PLUMBING", "HVAC")
    }

    /**
     * 지연 여부 확인
     */
    private fun isOverdue(scheduledEnd: LocalDateTime?): Boolean {
        return scheduledEnd?.isBefore(LocalDateTime.now()) ?: false
    }

    /**
     * 필요 부품 목록 생성
     */
    private fun generateRequiredParts(): List<RequiredPartDto> {
        return listOf(
            RequiredPartDto(
                partId = UUID.randomUUID(),
                partName = "전구",
                partNumber = "LED-001",
                quantityRequired = 2,
                quantityUsed = 0,
                unitCost = BigDecimal("5000"),
                isAvailable = true,
                qrCode = "QR-LED-001"
            )
        )
    }

    /**
     * 체크리스트 항목 생성
     */
    private fun generateChecklistItems(): List<ChecklistItemDto> {
        return listOf(
            ChecklistItemDto(
                itemId = UUID.randomUUID(),
                description = "전원 차단 확인",
                isRequired = true,
                isCompleted = false,
                photoRequired = true
            ),
            ChecklistItemDto(
                itemId = UUID.randomUUID(),
                description = "작업 완료 후 테스트",
                isRequired = true,
                isCompleted = false,
                photoRequired = false
            )
        )
    }

    /**
     * 작업 지시서 타임라인 생성
     */
    private fun generateWorkOrderTimeline(workOrder: com.qiro.domain.workorder.dto.WorkOrderDto): List<TimelineEventDto> {
        val timeline = mutableListOf<TimelineEventDto>()
        
        timeline.add(TimelineEventDto(
            eventId = UUID.randomUUID(),
            eventType = "CREATED",
            title = "작업 지시서 생성",
            description = "작업 지시서가 생성되었습니다",
            occurredAt = workOrder.createdAt,
            performedBy = "시스템",
            icon = "create",
            color = "#3B82F6"
        ))
        
        if (workOrder.status.ordinal >= WorkOrderStatus.ASSIGNED.ordinal) {
            timeline.add(TimelineEventDto(
                eventId = UUID.randomUUID(),
                eventType = "ASSIGNED",
                title = "담당자 배정",
                description = "${workOrder.assignedTechnicianName}님이 배정되었습니다",
                occurredAt = LocalDateTime.now(),
                performedBy = "관리자",
                icon = "assign",
                color = "#10B981"
            ))
        }
        
        return timeline.sortedByDescending { it.occurredAt }
    }
}