package com.qiro.domain.contractor.controller

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.OutsourcingWorkRequest
import com.qiro.domain.contractor.service.OutsourcingWorkRequestService
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 외주 작업 요청 컨트롤러
 * 외부 업체 작업 의뢰 관리 API 엔드포인트 제공
 */
@RestController
@RequestMapping("/api/outsourcing-work-requests")
class OutsourcingWorkRequestController(
    private val outsourcingWorkRequestService: OutsourcingWorkRequestService
) {

    /**
     * 작업 요청 상세 조회
     */
    @GetMapping("/{requestId}")
    fun getRequest(@PathVariable requestId: UUID): ResponseEntity<OutsourcingWorkRequestDto> {
        val request = outsourcingWorkRequestService.getRequestById(requestId)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(request)
    }

    /**
     * 요청 번호로 조회
     */
    @GetMapping("/by-number")
    fun getRequestByNumber(
        @RequestParam companyId: UUID,
        @RequestParam requestNumber: String
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        val request = outsourcingWorkRequestService.getRequestByNumber(companyId, requestNumber)
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(request)
    }

    /**
     * 요청자별 요청 목록 조회
     */
    @GetMapping("/by-requester")
    fun getRequestsByRequester(
        @RequestParam companyId: UUID,
        @RequestParam requesterId: UUID
    ): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getRequestsByRequester(companyId, requesterId)
        return ResponseEntity.ok(requests)
    }

    /**
     * 요청 상태별 조회
     */
    @GetMapping("/by-status")
    fun getRequestsByStatus(
        @RequestParam companyId: UUID,
        @RequestParam requestStatus: OutsourcingWorkRequest.RequestStatus
    ): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getRequestsByStatus(companyId, requestStatus)
        return ResponseEntity.ok(requests)
    }

    /**
     * 승인 상태별 조회
     */
    @GetMapping("/by-approval-status")
    fun getRequestsByApprovalStatus(
        @RequestParam companyId: UUID,
        @RequestParam approvalStatus: OutsourcingWorkRequest.ApprovalStatus
    ): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getRequestsByApprovalStatus(companyId, approvalStatus)
        return ResponseEntity.ok(requests)
    }

    /**
     * 현재 승인자별 대기 중인 요청 조회
     */
    @GetMapping("/pending-approval")
    fun getPendingRequestsByApprover(
        @RequestParam companyId: UUID,
        @RequestParam approverId: UUID
    ): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getPendingRequestsByApprover(companyId, approverId)
        return ResponseEntity.ok(requests)
    }

    /**
     * 긴급 요청 조회
     */
    @GetMapping("/urgent")
    fun getUrgentRequests(@RequestParam companyId: UUID): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getUrgentRequests(companyId)
        return ResponseEntity.ok(requests)
    }

    /**
     * 지연 위험 요청 조회
     */
    @GetMapping("/delay-risk")
    fun getDelayRiskRequests(
        @RequestParam companyId: UUID,
        @RequestParam(defaultValue = "7") riskDays: Long
    ): ResponseEntity<List<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.getDelayRiskRequests(companyId, riskDays)
        return ResponseEntity.ok(requests)
    }

    /**
     * 복합 검색 조건으로 요청 조회
     */
    @PostMapping("/search")
    fun searchRequests(
        @RequestParam companyId: UUID,
        @RequestBody searchCriteria: OutsourcingWorkRequestSearchCriteria,
        pageable: Pageable
    ): ResponseEntity<Page<OutsourcingWorkRequestDto>> {
        val requests = outsourcingWorkRequestService.searchRequests(companyId, searchCriteria, pageable)
        return ResponseEntity.ok(requests)
    }

    /**
     * 대시보드 통계 조회
     */
    @GetMapping("/dashboard-statistics")
    fun getDashboardStatistics(@RequestParam companyId: UUID): ResponseEntity<OutsourcingWorkRequestDashboardDto> {
        val statistics = outsourcingWorkRequestService.getDashboardStatistics(companyId)
        return ResponseEntity.ok(statistics)
    }

    /**
     * 작업 요청 등록
     */
    @PostMapping
    fun createRequest(
        @RequestParam companyId: UUID,
        @RequestBody request: CreateOutsourcingWorkRequestRequest,
        @RequestParam createdBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.createRequest(companyId, request, createdBy)
            ResponseEntity.status(HttpStatus.CREATED).body(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 수정
     */
    @PutMapping("/{requestId}")
    fun updateRequest(
        @PathVariable requestId: UUID,
        @RequestBody request: UpdateOutsourcingWorkRequestRequest,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.updateRequest(requestId, request, updatedBy)
            ResponseEntity.ok(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 제출
     */
    @PostMapping("/{requestId}/submit")
    fun submitRequest(
        @PathVariable requestId: UUID,
        @RequestParam updatedBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.submitRequest(requestId, updatedBy)
            ResponseEntity.ok(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 승인
     */
    @PostMapping("/{requestId}/approve")
    fun approveRequest(
        @PathVariable requestId: UUID,
        @RequestBody request: ApproveOutsourcingWorkRequestRequest,
        @RequestParam approvedBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.approveRequest(requestId, request, approvedBy)
            ResponseEntity.ok(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 거부
     */
    @PostMapping("/{requestId}/reject")
    fun rejectRequest(
        @PathVariable requestId: UUID,
        @RequestBody request: RejectOutsourcingWorkRequestRequest,
        @RequestParam rejectedBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.rejectRequest(requestId, request, rejectedBy)
            ResponseEntity.ok(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 취소
     */
    @PostMapping("/{requestId}/cancel")
    fun cancelRequest(
        @PathVariable requestId: UUID,
        @RequestParam cancellationReason: String,
        @RequestParam cancelledBy: UUID
    ): ResponseEntity<OutsourcingWorkRequestDto> {
        return try {
            val workRequest = outsourcingWorkRequestService.cancelRequest(requestId, cancellationReason, cancelledBy)
            ResponseEntity.ok(workRequest)
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }

    /**
     * 작업 요청 삭제
     */
    @DeleteMapping("/{requestId}")
    fun deleteRequest(@PathVariable requestId: UUID): ResponseEntity<Void> {
        return try {
            outsourcingWorkRequestService.deleteRequest(requestId)
            ResponseEntity.noContent().build()
        } catch (e: IllegalArgumentException) {
            ResponseEntity.notFound().build()
        } catch (e: IllegalStateException) {
            ResponseEntity.badRequest().build()
        }
    }
}