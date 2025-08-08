package com.qiro.domain.mobile.dto

import com.qiro.domain.workorder.dto.WorkOrderPriority
import com.qiro.domain.workorder.dto.WorkOrderStatus
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 모바일 작업 지시서 DTO
 */
data class MobileWorkOrderDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val description: String,
    val priority: WorkOrderPriority,
    val status: WorkOrderStatus,
    val workType: String,
    val location: String,
    val scheduledStart: LocalDateTime?,
    val scheduledEnd: LocalDateTime?,
    val actualStart: LocalDateTime?,
    val actualEnd: LocalDateTime?,
    val assignedTechnician: TechnicianInfo?,
    val estimatedDuration: Int?, // 분 단위
    val actualDuration: Int?, // 분 단위
    val completionPercentage: Int = 0,
    val canStart: Boolean = false,
    val canComplete: Boolean = false,
    val canPause: Boolean = false,
    val requiresSignature: Boolean = false
)

/**
 * 모바일 작업 지시서 목록 DTO
 */
data class MobileWorkOrderListDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val priority: WorkOrderPriority,
    val status: WorkOrderStatus,
    val workType: String,
    val location: String,
    val scheduledStart: LocalDateTime?,
    val assignedTechnician: String?,
    val statusBadge: StatusBadge,
    val isOverdue: Boolean = false,
    val estimatedDuration: Int? = null
)

/**
 * 모바일 작업 지시서 상세 DTO
 */
data class MobileWorkOrderDetailDto(
    val workOrderId: UUID,
    val workOrderNumber: String,
    val title: String,
    val description: String,
    val priority: WorkOrderPriority,
    val status: WorkOrderStatus,
    val workType: String,
    val location: String,
    val scheduledStart: LocalDateTime?,
    val scheduledEnd: LocalDateTime?,
    val actualStart: LocalDateTime?,
    val actualEnd: LocalDateTime?,
    val assignedTechnician: TechnicianInfo?,
    val estimatedCost: BigDecimal?,
    val actualCost: BigDecimal?,
    val workInstructions: String?,
    val safetyNotes: String?,
    val requiredTools: List<String> = emptyList(),
    val requiredParts: List<RequiredPartDto> = emptyList(),
    val checklistItems: List<ChecklistItemDto> = emptyList(),
    val workPhotos: List<PhotoDto> = emptyList(),
    val workNotes: String?,
    val completionNotes: String?,
    val customerSignature: String? = null,
    val technicianSignature: String? = null,
    val timeline: List<TimelineEventDto> = emptyList(),
    val canStart: Boolean = false,
    val canComplete: Boolean = false,
    val canPause: Boolean = false,
    val requiresSignature: Boolean = false
)

/**
 * 필요 부품 DTO
 */
data class RequiredPartDto(
    val partId: UUID,
    val partName: String,
    val partNumber: String,
    val quantityRequired: Int,
    val quantityUsed: Int = 0,
    val unitCost: BigDecimal?,
    val isAvailable: Boolean = true,
    val qrCode: String? = null
)

/**
 * 체크리스트 항목 DTO
 */
data class ChecklistItemDto(
    val itemId: UUID,
    val description: String,
    val isRequired: Boolean = false,
    val isCompleted: Boolean = false,
    val completedAt: LocalDateTime? = null,
    val notes: String? = null,
    val photoRequired: Boolean = false,
    val photos: List<PhotoDto> = emptyList()
)

/**
 * 작업 시작 요청 DTO
 */
data class StartWorkOrderRequest(
    val actualStartTime: LocalDateTime = LocalDateTime.now(),
    val startNotes: String? = null,
    val gpsLatitude: Double? = null,
    val gpsLongitude: Double? = null
)

/**
 * 작업 완료 요청 DTO
 */
data class CompleteWorkOrderRequest(
    val actualEndTime: LocalDateTime = LocalDateTime.now(),
    val completionNotes: String,
    val workQuality: Int, // 1-5 점수
    val usedParts: List<UsedPartDto> = emptyList(),
    val laborHours: BigDecimal,
    val completionPhotos: List<String> = emptyList(),
    val customerSignature: String? = null,
    val technicianSignature: String? = null,
    val followUpRequired: Boolean = false,
    val followUpNotes: String? = null
)

/**
 * 사용된 부품 DTO
 */
data class UsedPartDto(
    val partId: UUID,
    val quantityUsed: Int,
    val actualCost: BigDecimal? = null,
    val notes: String? = null
)

/**
 * 작업 상태 업데이트 요청 DTO
 */
data class UpdateWorkOrderStatusRequest(
    val status: WorkOrderStatus,
    val notes: String? = null,
    val completionPercentage: Int? = null,
    val photos: List<String> = emptyList(),
    val gpsLatitude: Double? = null,
    val gpsLongitude: Double? = null
)

/**
 * 체크리스트 항목 업데이트 요청 DTO
 */
data class UpdateChecklistItemRequest(
    val isCompleted: Boolean,
    val notes: String? = null,
    val photos: List<String> = emptyList()
)

/**
 * 모바일 작업 지시서 필터 DTO
 */
data class MobileWorkOrderFilter(
    val status: WorkOrderStatus? = null,
    val priority: WorkOrderPriority? = null,
    val workType: String? = null,
    val assignedToMe: Boolean = false,
    val dateRange: DateRangeFilter? = null,
    val location: String? = null,
    val isOverdue: Boolean? = null
)

/**
 * 작업자 일일 요약 DTO
 */
data class TechnicianDailySummaryDto(
    val date: String,
    val totalWorkOrders: Int,
    val completedWorkOrders: Int,
    val inProgressWorkOrders: Int,
    val overdueWorkOrders: Int,
    val totalHoursWorked: BigDecimal,
    val averageCompletionTime: BigDecimal,
    val upcomingWorkOrders: List<MobileWorkOrderListDto> = emptyList()
)