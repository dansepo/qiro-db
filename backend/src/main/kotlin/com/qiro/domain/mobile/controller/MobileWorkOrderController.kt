package com.qiro.domain.mobile.controller

import com.qiro.domain.mobile.dto.*
import com.qiro.domain.mobile.service.MobileWorkOrderService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 모바일 작업 지시서 컨트롤러
 */
@RestController
@RequestMapping("/api/v1/mobile/companies/{companyId}/work-orders")
@Tag(name = "Mobile Work Orders", description = "모바일 작업 지시서 API")
class MobileWorkOrderController(
    private val mobileWorkOrderService: MobileWorkOrderService
) {

    @Operation(summary = "모바일 작업 지시서 목록 조회", description = "작업 지시서 목록을 조회합니다")
    @GetMapping
    fun getMobileWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "상태 필터") @RequestParam(required = false) status: com.qiro.domain.workorder.dto.WorkOrderStatus?,
        @Parameter(description = "우선순위 필터") @RequestParam(required = false) priority: com.qiro.domain.workorder.dto.WorkOrderPriority?,
        @Parameter(description = "작업 유형 필터") @RequestParam(required = false) workType: String?,
        @Parameter(description = "내 작업만 조회") @RequestParam(required = false, defaultValue = "false") assignedToMe: Boolean,
        @Parameter(description = "위치 필터") @RequestParam(required = false) location: String?,
        @Parameter(description = "지연된 작업만 조회") @RequestParam(required = false) isOverdue: Boolean?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<MobileWorkOrderListDto>> {
        val filter = MobileWorkOrderFilter(
            status = status,
            priority = priority,
            workType = workType,
            assignedToMe = assignedToMe,
            location = location,
            isOverdue = isOverdue
        )
        val result = mobileWorkOrderService.getMobileWorkOrders(companyId, filter, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "모바일 작업 지시서 상세 조회", description = "특정 작업 지시서의 상세 정보를 조회합니다")
    @GetMapping("/{workOrderId}")
    fun getMobileWorkOrderDetail(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID
    ): ResponseEntity<MobileWorkOrderDetailDto> {
        val result = mobileWorkOrderService.getMobileWorkOrderDetail(workOrderId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "내 작업 지시서 목록 조회", description = "현재 사용자에게 배정된 작업 지시서 목록을 조회합니다")
    @GetMapping("/my")
    fun getMyWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @RequestHeader("X-User-Id") userId: UUID,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Page<MobileWorkOrderListDto>> {
        val result = mobileWorkOrderService.getWorkOrdersByTechnician(companyId, userId, pageable)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "작업 시작", description = "작업 지시서의 작업을 시작합니다")
    @PostMapping("/{workOrderId}/start")
    fun startWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @RequestBody request: StartWorkOrderRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileWorkOrderDto> {
        val result = mobileWorkOrderService.startWorkOrder(workOrderId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "작업 완료", description = "작업 지시서의 작업을 완료합니다")
    @PostMapping("/{workOrderId}/complete")
    fun completeWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @RequestBody request: CompleteWorkOrderRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileWorkOrderDto> {
        val result = mobileWorkOrderService.completeWorkOrder(workOrderId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "작업 상태 업데이트", description = "작업 지시서의 상태를 업데이트합니다")
    @PutMapping("/{workOrderId}/status")
    fun updateWorkOrderStatus(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @RequestBody request: UpdateWorkOrderStatusRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<MobileWorkOrderDto> {
        val result = mobileWorkOrderService.updateWorkOrderStatus(workOrderId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "체크리스트 항목 업데이트", description = "작업 지시서의 체크리스트 항목을 업데이트합니다")
    @PutMapping("/{workOrderId}/checklist/{itemId}")
    fun updateChecklistItem(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Parameter(description = "체크리스트 항목 ID") @PathVariable itemId: UUID,
        @RequestBody request: UpdateChecklistItemRequest,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<ChecklistItemDto> {
        val result = mobileWorkOrderService.updateChecklistItem(workOrderId, itemId, request, userId)
        return ResponseEntity.ok(result)
    }

    @Operation(summary = "기술자 일일 요약 조회", description = "기술자의 일일 작업 요약 정보를 조회합니다")
    @GetMapping("/technician/daily-summary")
    fun getTechnicianDailySummary(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "날짜 (yyyy-MM-dd)") @RequestParam date: String,
        @RequestHeader("X-User-Id") userId: UUID
    ): ResponseEntity<TechnicianDailySummaryDto> {
        val result = mobileWorkOrderService.getTechnicianDailySummary(companyId, userId, date)
        return ResponseEntity.ok(result)
    }
}