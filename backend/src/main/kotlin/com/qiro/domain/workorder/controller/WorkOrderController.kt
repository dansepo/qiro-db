package com.qiro.domain.workorder.controller

import com.qiro.common.response.ApiResponse
import com.qiro.domain.workorder.dto.*
import com.qiro.domain.workorder.entity.WorkOrder
import com.qiro.domain.workorder.entity.WorkStatus
import com.qiro.domain.workorder.service.WorkOrderService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.*
import java.time.LocalDateTime
import java.util.*
import jakarta.validation.Valid

/**
 * 작업 지시서 컨트롤러
 * 작업 지시서 관리 관련 REST API 제공
 */
@Tag(name = "작업 지시서 관리", description = "작업 지시서 생성, 수정, 조회, 상태 관리 API")
@RestController
@RequestMapping("/api/v1/companies/{companyId}/work-orders")
class WorkOrderController(
    private val workOrderService: WorkOrderService
) {
    
    /**
     * 작업 지시서 생성
     */
    @Operation(summary = "작업 지시서 생성", description = "새로운 작업 지시서를 생성합니다.")
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    fun createWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody request: CreateWorkOrderRequest,
        @Parameter(description = "생성자 ID") @RequestHeader("X-User-Id") createdBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.createWorkOrder(companyId, request, createdBy)
        return ApiResponse.success(workOrder, "작업 지시서가 성공적으로 생성되었습니다.")
    }
    
    /**
     * 작업 지시서 수정
     */
    @Operation(summary = "작업 지시서 수정", description = "기존 작업 지시서 정보를 수정합니다.")
    @PutMapping("/{workOrderId}")
    fun updateWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: UpdateWorkOrderRequest,
        @Parameter(description = "수정자 ID") @RequestHeader("X-User-Id") updatedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.updateWorkOrder(companyId, workOrderId, request, updatedBy)
        return ApiResponse.success(workOrder, "작업 지시서가 성공적으로 수정되었습니다.")
    }
    
    /**
     * 작업 지시서 상태 변경
     */
    @Operation(summary = "작업 지시서 상태 변경", description = "작업 지시서의 상태를 변경합니다.")
    @PatchMapping("/{workOrderId}/status")
    fun updateWorkOrderStatus(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: WorkOrderStatusUpdateRequest,
        @Parameter(description = "수정자 ID") @RequestHeader("X-User-Id") updatedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.updateWorkOrderStatus(companyId, workOrderId, request, updatedBy)
        return ApiResponse.success(workOrder, "작업 지시서 상태가 성공적으로 변경되었습니다.")
    }
    
    /**
     * 작업자 배정
     */
    @Operation(summary = "작업자 배정", description = "작업 지시서에 작업자를 배정합니다.")
    @PostMapping("/{workOrderId}/assign")
    fun assignWorker(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: AssignWorkerRequest,
        @Parameter(description = "배정자 ID") @RequestHeader("X-User-Id") assignedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.assignWorker(companyId, workOrderId, request, assignedBy)
        return ApiResponse.success(workOrder, "작업자가 성공적으로 배정되었습니다.")
    }
    
    /**
     * 작업 승인
     */
    @Operation(summary = "작업 승인", description = "작업 지시서를 승인합니다.")
    @PostMapping("/{workOrderId}/approve")
    fun approveWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: ApproveWorkOrderRequest,
        @Parameter(description = "승인자 ID") @RequestHeader("X-User-Id") approvedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.approveWorkOrder(companyId, workOrderId, request, approvedBy)
        return ApiResponse.success(workOrder, "작업 지시서가 성공적으로 승인되었습니다.")
    }
    
    /**
     * 작업 거부
     */
    @Operation(summary = "작업 거부", description = "작업 지시서를 거부합니다.")
    @PostMapping("/{workOrderId}/reject")
    fun rejectWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Parameter(description = "거부 사유") @RequestParam reason: String,
        @Parameter(description = "거부자 ID") @RequestHeader("X-User-Id") rejectedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.rejectWorkOrder(companyId, workOrderId, reason, rejectedBy)
        return ApiResponse.success(workOrder, "작업 지시서가 거부되었습니다.")
    }
    
    /**
     * 작업 완료
     */
    @Operation(summary = "작업 완료", description = "작업을 완료 처리합니다.")
    @PostMapping("/{workOrderId}/complete")
    fun completeWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: CompleteWorkOrderRequest,
        @Parameter(description = "완료자 ID") @RequestHeader("X-User-Id") completedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.completeWorkOrder(companyId, workOrderId, request, completedBy)
        return ApiResponse.success(workOrder, "작업이 성공적으로 완료되었습니다.")
    }
    
    /**
     * 작업 지시서 상세 조회
     */
    @Operation(summary = "작업 지시서 상세 조회", description = "특정 작업 지시서의 상세 정보를 조회합니다.")
    @GetMapping("/{workOrderId}")
    fun getWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.getWorkOrder(companyId, workOrderId)
        return ApiResponse.success(workOrder)
    }
    
    /**
     * 작업 지시서 목록 조회
     */
    @Operation(summary = "작업 지시서 목록 조회", description = "작업 지시서 목록을 페이징하여 조회합니다.")
    @GetMapping
    fun getWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "페이지 번호") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "페이지 크기") @RequestParam(defaultValue = "20") size: Int,
        @Parameter(description = "정렬 기준") @RequestParam(defaultValue = "createdAt") sortBy: String,
        @Parameter(description = "정렬 방향") @RequestParam(defaultValue = "DESC") sortDirection: String
    ): ApiResponse<Page<WorkOrderSummary>> {
        val pageable = PageRequest.of(page, size, Sort.Direction.fromString(sortDirection), sortBy)
        val workOrders = workOrderService.getWorkOrders(companyId, pageable)
        return ApiResponse.success(workOrders)
    }
    
    /**
     * 작업 지시서 검색
     */
    @Operation(summary = "작업 지시서 검색", description = "다양한 조건으로 작업 지시서를 검색합니다.")
    @PostMapping("/search")
    fun searchWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody request: WorkOrderSearchRequest
    ): ApiResponse<Page<WorkOrderSummary>> {
        val workOrders = workOrderService.searchWorkOrders(companyId, request)
        return ApiResponse.success(workOrders)
    }
    
    /**
     * 긴급 작업 지시서 조회
     */
    @Operation(summary = "긴급 작업 지시서 조회", description = "긴급 우선순위의 작업 지시서를 조회합니다.")
    @GetMapping("/urgent")
    fun getUrgentWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "페이지 번호") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "페이지 크기") @RequestParam(defaultValue = "20") size: Int
    ): ApiResponse<Page<WorkOrderSummary>> {
        val pageable = PageRequest.of(page, size)
        val workOrders = workOrderService.getUrgentWorkOrders(companyId, pageable)
        return ApiResponse.success(workOrders)
    }
    
    /**
     * 지연된 작업 지시서 조회
     */
    @Operation(summary = "지연된 작업 지시서 조회", description = "예정일을 초과한 작업 지시서를 조회합니다.")
    @GetMapping("/delayed")
    fun getDelayedWorkOrders(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "페이지 번호") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "페이지 크기") @RequestParam(defaultValue = "20") size: Int
    ): ApiResponse<Page<WorkOrderSummary>> {
        val pageable = PageRequest.of(page, size)
        val workOrders = workOrderService.getDelayedWorkOrders(companyId, pageable)
        return ApiResponse.success(workOrders)
    }
    
    /**
     * 담당자별 작업 지시서 조회
     */
    @Operation(summary = "담당자별 작업 지시서 조회", description = "특정 담당자에게 배정된 작업 지시서를 조회합니다.")
    @GetMapping("/assignee/{assigneeId}")
    fun getWorkOrdersByAssignee(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "담당자 ID") @PathVariable assigneeId: UUID,
        @Parameter(description = "페이지 번호") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "페이지 크기") @RequestParam(defaultValue = "20") size: Int
    ): ApiResponse<Page<WorkOrderSummary>> {
        val pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        val workOrders = workOrderService.getWorkOrdersByAssignee(companyId, assigneeId, pageable)
        return ApiResponse.success(workOrders)
    }
    
    /**
     * 작업 지시서 통계 조회
     */
    @Operation(summary = "작업 지시서 통계 조회", description = "지정된 기간의 작업 지시서 통계를 조회합니다.")
    @GetMapping("/statistics")
    fun getWorkOrderStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "시작일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime,
        @Parameter(description = "종료일") @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime
    ): ApiResponse<WorkOrderStatistics> {
        val statistics = workOrderService.getWorkOrderStatistics(companyId, startDate, endDate)
        return ApiResponse.success(statistics)
    }
    
    /**
     * 작업 지시서 대시보드 조회
     */
    @Operation(summary = "작업 지시서 대시보드 조회", description = "작업 지시서 대시보드 데이터를 조회합니다.")
    @GetMapping("/dashboard")
    fun getWorkOrderDashboard(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "사용자 ID") @RequestHeader("X-User-Id") userId: UUID
    ): ApiResponse<WorkOrderDashboard> {
        val dashboard = workOrderService.getWorkOrderDashboard(companyId, userId)
        return ApiResponse.success(dashboard)
    }

    /**
     * 작업자별 할당된 작업 목록 조회 (상세)
     */
    @Operation(summary = "작업자별 할당된 작업 목록 조회", description = "특정 작업자에게 할당된 모든 작업을 상태별로 조회합니다.")
    @GetMapping("/worker/{workerId}/assignments")
    fun getWorkerAssignments(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업자 ID") @PathVariable workerId: UUID,
        @Parameter(description = "작업 상태") @RequestParam(required = false) status: WorkStatus?,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime?,
        @Parameter(description = "페이지 번호") @RequestParam(defaultValue = "0") page: Int,
        @Parameter(description = "페이지 크기") @RequestParam(defaultValue = "20") size: Int
    ): ApiResponse<Page<WorkOrderResponse>> {
        val pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        val assignments = workOrderService.getWorkerAssignments(companyId, workerId, status, startDate, endDate, pageable)
        return ApiResponse.success(assignments)
    }

    /**
     * 작업자별 작업 통계 조회
     */
    @Operation(summary = "작업자별 작업 통계 조회", description = "특정 작업자의 작업 수행 통계를 조회합니다.")
    @GetMapping("/worker/{workerId}/statistics")
    fun getWorkerStatistics(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업자 ID") @PathVariable workerId: UUID,
        @Parameter(description = "시작일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) startDate: LocalDateTime?,
        @Parameter(description = "종료일") @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) endDate: LocalDateTime?
    ): ApiResponse<WorkerStatistics> {
        val statistics = workOrderService.getWorkerStatistics(companyId, workerId, startDate, endDate)
        return ApiResponse.success(statistics)
    }

    /**
     * 작업 진행 상황 업데이트
     */
    @Operation(summary = "작업 진행 상황 업데이트", description = "작업의 진행 상황을 업데이트합니다.")
    @PostMapping("/{workOrderId}/progress")
    fun updateWorkProgress(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: WorkProgressUpdateRequest,
        @Parameter(description = "업데이트자 ID") @RequestHeader("X-User-Id") updatedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.updateWorkProgress(companyId, workOrderId, request, updatedBy)
        return ApiResponse.success(workOrder, "작업 진행 상황이 성공적으로 업데이트되었습니다.")
    }

    /**
     * 작업 일시 중지
     */
    @Operation(summary = "작업 일시 중지", description = "진행 중인 작업을 일시 중지합니다.")
    @PostMapping("/{workOrderId}/pause")
    fun pauseWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Parameter(description = "중지 사유") @RequestParam reason: String,
        @Parameter(description = "중지자 ID") @RequestHeader("X-User-Id") pausedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.pauseWorkOrder(companyId, workOrderId, reason, pausedBy)
        return ApiResponse.success(workOrder, "작업이 일시 중지되었습니다.")
    }

    /**
     * 작업 재개
     */
    @Operation(summary = "작업 재개", description = "일시 중지된 작업을 재개합니다.")
    @PostMapping("/{workOrderId}/resume")
    fun resumeWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Parameter(description = "재개 사유") @RequestParam(required = false) reason: String?,
        @Parameter(description = "재개자 ID") @RequestHeader("X-User-Id") resumedBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.resumeWorkOrder(companyId, workOrderId, reason, resumedBy)
        return ApiResponse.success(workOrder, "작업이 재개되었습니다.")
    }

    /**
     * 작업 취소
     */
    @Operation(summary = "작업 취소", description = "작업 지시서를 취소합니다.")
    @PostMapping("/{workOrderId}/cancel")
    fun cancelWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Parameter(description = "취소 사유") @RequestParam reason: String,
        @Parameter(description = "취소자 ID") @RequestHeader("X-User-Id") cancelledBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.cancelWorkOrder(companyId, workOrderId, reason, cancelledBy)
        return ApiResponse.success(workOrder, "작업 지시서가 취소되었습니다.")
    }

    /**
     * 작업 지시서 복사
     */
    @Operation(summary = "작업 지시서 복사", description = "기존 작업 지시서를 복사하여 새로운 작업 지시서를 생성합니다.")
    @PostMapping("/{workOrderId}/copy")
    fun copyWorkOrder(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Parameter(description = "원본 작업 지시서 ID") @PathVariable workOrderId: UUID,
        @Valid @RequestBody request: CopyWorkOrderRequest,
        @Parameter(description = "생성자 ID") @RequestHeader("X-User-Id") createdBy: UUID
    ): ApiResponse<WorkOrderResponse> {
        val workOrder = workOrderService.copyWorkOrder(companyId, workOrderId, request, createdBy)
        return ApiResponse.success(workOrder, "작업 지시서가 성공적으로 복사되었습니다.")
    }

    /**
     * 작업 지시서 일괄 상태 변경
     */
    @Operation(summary = "작업 지시서 일괄 상태 변경", description = "여러 작업 지시서의 상태를 일괄 변경합니다.")
    @PostMapping("/batch/status")
    fun batchUpdateStatus(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody request: BatchStatusUpdateRequest,
        @Parameter(description = "업데이트자 ID") @RequestHeader("X-User-Id") updatedBy: UUID
    ): ApiResponse<BatchUpdateResult> {
        val result = workOrderService.batchUpdateStatus(companyId, request, updatedBy)
        return ApiResponse.success(result, "작업 지시서 상태가 일괄 변경되었습니다.")
    }

    /**
     * 작업 지시서 일괄 배정
     */
    @Operation(summary = "작업 지시서 일괄 배정", description = "여러 작업 지시서를 특정 작업자에게 일괄 배정합니다.")
    @PostMapping("/batch/assign")
    fun batchAssignWorker(
        @Parameter(description = "회사 ID") @PathVariable companyId: UUID,
        @Valid @RequestBody request: BatchAssignRequest,
        @Parameter(description = "배정자 ID") @RequestHeader("X-User-Id") assignedBy: UUID
    ): ApiResponse<BatchUpdateResult> {
        val result = workOrderService.batchAssignWorker(companyId, request, assignedBy)
        return ApiResponse.success(result, "작업 지시서가 일괄 배정되었습니다.")
    }
}