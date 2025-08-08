package com.qiro.domain.contractor.service

import com.qiro.domain.contractor.dto.*
import com.qiro.domain.contractor.entity.OutsourcingWorkRequest
import com.qiro.domain.contractor.repository.OutsourcingWorkRequestRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외주 작업 요청 서비스
 * 외부 업체 작업 의뢰 관리 비즈니스 로직 처리
 */
@Service
@Transactional(readOnly = true)
class OutsourcingWorkRequestService(
    private val outsourcingWorkRequestRepository: OutsourcingWorkRequestRepository
) {

    /**
     * 작업 요청 상세 조회
     */
    fun getRequestById(requestId: UUID): OutsourcingWorkRequestDto? {
        return outsourcingWorkRequestRepository.findById(requestId)
            .map { OutsourcingWorkRequestDto.from(it) }
            .orElse(null)
    }

    /**
     * 요청 번호로 조회
     */
    fun getRequestByNumber(companyId: UUID, requestNumber: String): OutsourcingWorkRequestDto? {
        return outsourcingWorkRequestRepository.findByCompanyIdAndRequestNumber(companyId, requestNumber)
            ?.let { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 요청자별 요청 목록 조회
     */
    fun getRequestsByRequester(companyId: UUID, requesterId: UUID): List<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findByCompanyIdAndRequesterIdOrderByRequestDateDesc(
            companyId, requesterId
        ).map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 요청 상태별 조회
     */
    fun getRequestsByStatus(
        companyId: UUID,
        requestStatus: OutsourcingWorkRequest.RequestStatus
    ): List<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findByCompanyIdAndRequestStatusOrderByRequestDateDesc(
            companyId, requestStatus
        ).map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 승인 상태별 조회
     */
    fun getRequestsByApprovalStatus(
        companyId: UUID,
        approvalStatus: OutsourcingWorkRequest.ApprovalStatus
    ): List<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findByCompanyIdAndApprovalStatusOrderByRequestDateDesc(
            companyId, approvalStatus
        ).map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 현재 승인자별 대기 중인 요청 조회
     */
    fun getPendingRequestsByApprover(companyId: UUID, approverId: UUID): List<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findByCompanyIdAndCurrentApproverIdAndApprovalStatusOrderByRequestDateAsc(
            companyId, approverId, OutsourcingWorkRequest.ApprovalStatus.PENDING
        ).map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 긴급 요청 조회
     */
    fun getUrgentRequests(companyId: UUID): List<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findUrgentRequests(companyId)
            .map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 지연 위험 요청 조회
     */
    fun getDelayRiskRequests(companyId: UUID, riskDays: Long = 7): List<OutsourcingWorkRequestDto> {
        val riskDate = LocalDate.now().plusDays(riskDays)
        return outsourcingWorkRequestRepository.findDelayRiskRequests(companyId, riskDate)
            .map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 복합 검색 조건으로 요청 조회
     */
    fun searchRequests(
        companyId: UUID,
        searchCriteria: OutsourcingWorkRequestSearchCriteria,
        pageable: Pageable
    ): Page<OutsourcingWorkRequestDto> {
        return outsourcingWorkRequestRepository.findBySearchCriteria(
            companyId = companyId,
            requestTitle = searchCriteria.requestTitle,
            requestType = searchCriteria.requestType,
            requestStatus = searchCriteria.requestStatus,
            approvalStatus = searchCriteria.approvalStatus,
            priorityLevel = searchCriteria.priorityLevel,
            requesterId = searchCriteria.requesterId,
            department = searchCriteria.department,
            fromDate = searchCriteria.fromDate,
            toDate = searchCriteria.toDate,
            pageable = pageable
        ).map { OutsourcingWorkRequestDto.from(it) }
    }

    /**
     * 대시보드 통계 조회
     */
    fun getDashboardStatistics(companyId: UUID): OutsourcingWorkRequestDashboardDto {
        val totalRequests = outsourcingWorkRequestRepository.count()
        val pendingApprovalRequests = outsourcingWorkRequestRepository.countByCompanyIdAndApprovalStatus(
            companyId, OutsourcingWorkRequest.ApprovalStatus.PENDING
        )
        val approvedRequests = outsourcingWorkRequestRepository.countByCompanyIdAndApprovalStatus(
            companyId, OutsourcingWorkRequest.ApprovalStatus.APPROVED
        )
        val rejectedRequests = outsourcingWorkRequestRepository.countByCompanyIdAndApprovalStatus(
            companyId, OutsourcingWorkRequest.ApprovalStatus.REJECTED
        )

        val urgentRequests = outsourcingWorkRequestRepository.findUrgentRequests(companyId).size.toLong()
        val delayRiskRequests = getDelayRiskRequests(companyId).size.toLong()

        // 예산 통계 계산 (실제 구현에서는 더 정교한 쿼리 필요)
        val allRequests = outsourcingWorkRequestRepository.findByCompanyIdAndRequestStatusOrderByRequestDateDesc(
            companyId, OutsourcingWorkRequest.RequestStatus.APPROVED
        )
        val totalEstimatedBudget = allRequests.sumOf { it.estimatedBudget }
        val averageEstimatedBudget = if (allRequests.isNotEmpty()) {
            totalEstimatedBudget.divide(BigDecimal(allRequests.size), 2, java.math.RoundingMode.HALF_UP)
        } else BigDecimal.ZERO

        return OutsourcingWorkRequestDashboardDto(
            totalRequests = totalRequests,
            pendingApprovalRequests = pendingApprovalRequests,
            approvedRequests = approvedRequests,
            rejectedRequests = rejectedRequests,
            urgentRequests = urgentRequests,
            delayRiskRequests = delayRiskRequests,
            totalEstimatedBudget = totalEstimatedBudget,
            averageEstimatedBudget = averageEstimatedBudget
        )
    }

    /**
     * 작업 요청 등록
     */
    @Transactional
    fun createRequest(
        companyId: UUID,
        request: CreateOutsourcingWorkRequestRequest,
        createdBy: UUID
    ): OutsourcingWorkRequestDto {
        // 요청 번호 중복 확인
        outsourcingWorkRequestRepository.findByCompanyIdAndRequestNumber(companyId, request.requestNumber)
            ?.let { throw IllegalArgumentException("요청 번호가 이미 존재합니다: ${request.requestNumber}") }

        val workRequest = OutsourcingWorkRequest(
            companyId = companyId,
            requestNumber = request.requestNumber,
            requestTitle = request.requestTitle,
            requestType = request.requestType,
            requesterId = request.requesterId,
            department = request.department,
            costCenter = request.costCenter,
            workDescription = request.workDescription,
            workLocation = request.workLocation,
            workScope = request.workScope,
            technicalRequirements = request.technicalRequirements,
            requiredStartDate = request.requiredStartDate,
            requiredCompletionDate = request.requiredCompletionDate,
            estimatedDuration = request.estimatedDuration,
            estimatedBudget = request.estimatedBudget,
            budgetCode = request.budgetCode,
            currencyCode = request.currencyCode,
            priorityLevel = request.priorityLevel,
            urgencyLevel = request.urgencyLevel,
            requiredContractorCategory = request.requiredContractorCategory,
            requiredLicenses = request.requiredLicenses,
            requiredCertifications = request.requiredCertifications,
            minimumExperienceYears = request.minimumExperienceYears,
            requestDocuments = request.requestDocuments,
            requestNotes = request.requestNotes,
            createdBy = createdBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(workRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 수정
     */
    @Transactional
    fun updateRequest(
        requestId: UUID,
        request: UpdateOutsourcingWorkRequestRequest,
        updatedBy: UUID
    ): OutsourcingWorkRequestDto {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        // 승인된 요청은 수정 불가
        if (workRequest.approvalStatus == OutsourcingWorkRequest.ApprovalStatus.APPROVED) {
            throw IllegalStateException("승인된 요청은 수정할 수 없습니다")
        }

        val updatedRequest = workRequest.copy(
            requestTitle = request.requestTitle ?: workRequest.requestTitle,
            requestType = request.requestType ?: workRequest.requestType,
            department = request.department ?: workRequest.department,
            costCenter = request.costCenter ?: workRequest.costCenter,
            workDescription = request.workDescription ?: workRequest.workDescription,
            workLocation = request.workLocation ?: workRequest.workLocation,
            workScope = request.workScope ?: workRequest.workScope,
            technicalRequirements = request.technicalRequirements ?: workRequest.technicalRequirements,
            requiredStartDate = request.requiredStartDate ?: workRequest.requiredStartDate,
            requiredCompletionDate = request.requiredCompletionDate ?: workRequest.requiredCompletionDate,
            estimatedDuration = request.estimatedDuration ?: workRequest.estimatedDuration,
            estimatedBudget = request.estimatedBudget ?: workRequest.estimatedBudget,
            budgetCode = request.budgetCode ?: workRequest.budgetCode,
            priorityLevel = request.priorityLevel ?: workRequest.priorityLevel,
            urgencyLevel = request.urgencyLevel ?: workRequest.urgencyLevel,
            requiredContractorCategory = request.requiredContractorCategory ?: workRequest.requiredContractorCategory,
            requiredLicenses = request.requiredLicenses ?: workRequest.requiredLicenses,
            requiredCertifications = request.requiredCertifications ?: workRequest.requiredCertifications,
            minimumExperienceYears = request.minimumExperienceYears ?: workRequest.minimumExperienceYears,
            requestDocuments = request.requestDocuments ?: workRequest.requestDocuments,
            requestNotes = request.requestNotes ?: workRequest.requestNotes,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(updatedRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 제출
     */
    @Transactional
    fun submitRequest(requestId: UUID, updatedBy: UUID): OutsourcingWorkRequestDto {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        if (workRequest.requestStatus != OutsourcingWorkRequest.RequestStatus.DRAFT) {
            throw IllegalStateException("초안 상태의 요청만 제출할 수 있습니다")
        }

        val submittedRequest = workRequest.copy(
            requestStatus = OutsourcingWorkRequest.RequestStatus.SUBMITTED,
            approvalStatus = OutsourcingWorkRequest.ApprovalStatus.PENDING,
            updatedAt = LocalDateTime.now(),
            updatedBy = updatedBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(submittedRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 승인
     */
    @Transactional
    fun approveRequest(
        requestId: UUID,
        request: ApproveOutsourcingWorkRequestRequest,
        approvedBy: UUID
    ): OutsourcingWorkRequestDto {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        if (workRequest.approvalStatus != OutsourcingWorkRequest.ApprovalStatus.PENDING) {
            throw IllegalStateException("승인 대기 중인 요청만 승인할 수 있습니다")
        }

        val approvedRequest = workRequest.copy(
            approvalStatus = OutsourcingWorkRequest.ApprovalStatus.APPROVED,
            requestStatus = OutsourcingWorkRequest.RequestStatus.APPROVED,
            requestNotes = if (request.approvalNotes != null) {
                "${workRequest.requestNotes ?: ""}\n[승인 메모] ${request.approvalNotes}"
            } else workRequest.requestNotes,
            updatedAt = LocalDateTime.now(),
            updatedBy = approvedBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(approvedRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 거부
     */
    @Transactional
    fun rejectRequest(
        requestId: UUID,
        request: RejectOutsourcingWorkRequestRequest,
        rejectedBy: UUID
    ): OutsourcingWorkRequestDto {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        if (workRequest.approvalStatus != OutsourcingWorkRequest.ApprovalStatus.PENDING) {
            throw IllegalStateException("승인 대기 중인 요청만 거부할 수 있습니다")
        }

        val rejectedRequest = workRequest.copy(
            approvalStatus = OutsourcingWorkRequest.ApprovalStatus.REJECTED,
            requestStatus = OutsourcingWorkRequest.RequestStatus.REJECTED,
            requestNotes = "${workRequest.requestNotes ?: ""}\n[거부 사유] ${request.rejectionReason}",
            updatedAt = LocalDateTime.now(),
            updatedBy = rejectedBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(rejectedRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 취소
     */
    @Transactional
    fun cancelRequest(requestId: UUID, cancellationReason: String, cancelledBy: UUID): OutsourcingWorkRequestDto {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        if (workRequest.requestStatus == OutsourcingWorkRequest.RequestStatus.ASSIGNED) {
            throw IllegalStateException("이미 할당된 요청은 취소할 수 없습니다")
        }

        val cancelledRequest = workRequest.copy(
            requestStatus = OutsourcingWorkRequest.RequestStatus.CANCELLED,
            approvalStatus = OutsourcingWorkRequest.ApprovalStatus.CANCELLED,
            requestNotes = "${workRequest.requestNotes ?: ""}\n[취소 사유] $cancellationReason",
            updatedAt = LocalDateTime.now(),
            updatedBy = cancelledBy
        )

        val savedRequest = outsourcingWorkRequestRepository.save(cancelledRequest)
        return OutsourcingWorkRequestDto.from(savedRequest)
    }

    /**
     * 작업 요청 삭제
     */
    @Transactional
    fun deleteRequest(requestId: UUID) {
        val workRequest = outsourcingWorkRequestRepository.findById(requestId)
            .orElseThrow { IllegalArgumentException("작업 요청을 찾을 수 없습니다: $requestId") }

        if (workRequest.requestStatus == OutsourcingWorkRequest.RequestStatus.ASSIGNED ||
            workRequest.approvalStatus == OutsourcingWorkRequest.ApprovalStatus.APPROVED) {
            throw IllegalStateException("승인되거나 할당된 요청은 삭제할 수 없습니다")
        }

        outsourcingWorkRequestRepository.delete(workRequest)
    }
}