package com.qiro.domain.contractor.repository

import com.qiro.domain.contractor.entity.OutsourcingWorkRequest
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 외주 작업 요청 Repository
 * 외부 업체 작업 의뢰에 대한 데이터 액세스 기능 제공
 */
@Repository
interface OutsourcingWorkRequestRepository : JpaRepository<OutsourcingWorkRequest, UUID> {

    /**
     * 요청 번호로 조회
     */
    fun findByCompanyIdAndRequestNumber(companyId: UUID, requestNumber: String): OutsourcingWorkRequest?

    /**
     * 요청자별 요청 목록 조회
     */
    fun findByCompanyIdAndRequesterIdOrderByRequestDateDesc(
        companyId: UUID,
        requesterId: UUID
    ): List<OutsourcingWorkRequest>

    /**
     * 요청 상태별 조회
     */
    fun findByCompanyIdAndRequestStatusOrderByRequestDateDesc(
        companyId: UUID,
        requestStatus: OutsourcingWorkRequest.RequestStatus
    ): List<OutsourcingWorkRequest>

    /**
     * 승인 상태별 조회
     */
    fun findByCompanyIdAndApprovalStatusOrderByRequestDateDesc(
        companyId: UUID,
        approvalStatus: OutsourcingWorkRequest.ApprovalStatus
    ): List<OutsourcingWorkRequest>

    /**
     * 요청 유형별 조회
     */
    fun findByCompanyIdAndRequestTypeOrderByRequestDateDesc(
        companyId: UUID,
        requestType: OutsourcingWorkRequest.RequestType
    ): List<OutsourcingWorkRequest>

    /**
     * 우선순위별 조회
     */
    fun findByCompanyIdAndPriorityLevelOrderByRequestDateDesc(
        companyId: UUID,
        priorityLevel: OutsourcingWorkRequest.PriorityLevel
    ): List<OutsourcingWorkRequest>

    /**
     * 긴급도별 조회
     */
    fun findByCompanyIdAndUrgencyLevelOrderByRequestDateDesc(
        companyId: UUID,
        urgencyLevel: OutsourcingWorkRequest.UrgencyLevel
    ): List<OutsourcingWorkRequest>

    /**
     * 현재 승인자별 조회
     */
    fun findByCompanyIdAndCurrentApproverIdAndApprovalStatusOrderByRequestDateAsc(
        companyId: UUID,
        currentApproverId: UUID,
        approvalStatus: OutsourcingWorkRequest.ApprovalStatus
    ): List<OutsourcingWorkRequest>

    /**
     * 기간별 요청 조회
     */
    fun findByCompanyIdAndRequestDateBetweenOrderByRequestDateDesc(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): List<OutsourcingWorkRequest>

    /**
     * 완료 예정일별 조회
     */
    fun findByCompanyIdAndRequiredCompletionDateBetweenOrderByRequiredCompletionDateAsc(
        companyId: UUID,
        startDate: LocalDate,
        endDate: LocalDate
    ): List<OutsourcingWorkRequest>

    /**
     * 예산 범위별 조회
     */
    @Query("""
        SELECT r FROM OutsourcingWorkRequest r 
        WHERE r.companyId = :companyId 
        AND r.estimatedBudget >= :minBudget 
        AND r.estimatedBudget <= :maxBudget 
        ORDER BY r.estimatedBudget DESC
    """)
    fun findByBudgetRange(
        @Param("companyId") companyId: UUID,
        @Param("minBudget") minBudget: BigDecimal,
        @Param("maxBudget") maxBudget: BigDecimal
    ): List<OutsourcingWorkRequest>

    /**
     * 부서별 요청 조회
     */
    fun findByCompanyIdAndDepartmentOrderByRequestDateDesc(
        companyId: UUID,
        department: String
    ): List<OutsourcingWorkRequest>

    /**
     * 비용 센터별 요청 조회
     */
    fun findByCompanyIdAndCostCenterOrderByRequestDateDesc(
        companyId: UUID,
        costCenter: String
    ): List<OutsourcingWorkRequest>

    /**
     * 필요 업체 카테고리별 조회
     */
    fun findByCompanyIdAndRequiredContractorCategoryOrderByRequestDateDesc(
        companyId: UUID,
        requiredContractorCategory: UUID
    ): List<OutsourcingWorkRequest>

    /**
     * 제목으로 검색
     */
    fun findByCompanyIdAndRequestTitleContainingIgnoreCaseOrderByRequestDateDesc(
        companyId: UUID,
        requestTitle: String,
        pageable: Pageable
    ): Page<OutsourcingWorkRequest>

    /**
     * 작업 설명으로 검색
     */
    fun findByCompanyIdAndWorkDescriptionContainingIgnoreCaseOrderByRequestDateDesc(
        companyId: UUID,
        workDescription: String,
        pageable: Pageable
    ): Page<OutsourcingWorkRequest>

    /**
     * 요청 상태별 개수 조회
     */
    fun countByCompanyIdAndRequestStatus(
        companyId: UUID,
        requestStatus: OutsourcingWorkRequest.RequestStatus
    ): Long

    /**
     * 승인 상태별 개수 조회
     */
    fun countByCompanyIdAndApprovalStatus(
        companyId: UUID,
        approvalStatus: OutsourcingWorkRequest.ApprovalStatus
    ): Long

    /**
     * 긴급 요청 조회 (높은 우선순위 + 긴급도)
     */
    @Query("""
        SELECT r FROM OutsourcingWorkRequest r 
        WHERE r.companyId = :companyId 
        AND (r.priorityLevel IN ('URGENT', 'EMERGENCY') OR r.urgencyLevel IN ('HIGH', 'CRITICAL'))
        AND r.requestStatus NOT IN ('CANCELLED', 'REJECTED')
        ORDER BY 
            CASE r.priorityLevel 
                WHEN 'EMERGENCY' THEN 1 
                WHEN 'URGENT' THEN 2 
                WHEN 'HIGH' THEN 3 
                ELSE 4 
            END,
            CASE r.urgencyLevel 
                WHEN 'CRITICAL' THEN 1 
                WHEN 'HIGH' THEN 2 
                ELSE 3 
            END,
            r.requestDate ASC
    """)
    fun findUrgentRequests(@Param("companyId") companyId: UUID): List<OutsourcingWorkRequest>

    /**
     * 지연 위험 요청 조회 (완료 예정일이 임박한 요청)
     */
    @Query("""
        SELECT r FROM OutsourcingWorkRequest r 
        WHERE r.companyId = :companyId 
        AND r.requiredCompletionDate IS NOT NULL 
        AND r.requiredCompletionDate <= :riskDate
        AND r.requestStatus NOT IN ('CANCELLED', 'REJECTED', 'ASSIGNED')
        ORDER BY r.requiredCompletionDate ASC
    """)
    fun findDelayRiskRequests(
        @Param("companyId") companyId: UUID,
        @Param("riskDate") riskDate: LocalDate
    ): List<OutsourcingWorkRequest>

    /**
     * 복합 검색 조건으로 요청 조회
     */
    @Query("""
        SELECT r FROM OutsourcingWorkRequest r 
        WHERE r.companyId = :companyId
        AND (:requestTitle IS NULL OR LOWER(r.requestTitle) LIKE LOWER(CONCAT('%', :requestTitle, '%')))
        AND (:requestType IS NULL OR r.requestType = :requestType)
        AND (:requestStatus IS NULL OR r.requestStatus = :requestStatus)
        AND (:approvalStatus IS NULL OR r.approvalStatus = :approvalStatus)
        AND (:priorityLevel IS NULL OR r.priorityLevel = :priorityLevel)
        AND (:requesterId IS NULL OR r.requesterId = :requesterId)
        AND (:department IS NULL OR r.department = :department)
        AND (:fromDate IS NULL OR r.requestDate >= :fromDate)
        AND (:toDate IS NULL OR r.requestDate <= :toDate)
        ORDER BY r.requestDate DESC
    """)
    fun findBySearchCriteria(
        @Param("companyId") companyId: UUID,
        @Param("requestTitle") requestTitle: String?,
        @Param("requestType") requestType: OutsourcingWorkRequest.RequestType?,
        @Param("requestStatus") requestStatus: OutsourcingWorkRequest.RequestStatus?,
        @Param("approvalStatus") approvalStatus: OutsourcingWorkRequest.ApprovalStatus?,
        @Param("priorityLevel") priorityLevel: OutsourcingWorkRequest.PriorityLevel?,
        @Param("requesterId") requesterId: UUID?,
        @Param("department") department: String?,
        @Param("fromDate") fromDate: LocalDateTime?,
        @Param("toDate") toDate: LocalDateTime?,
        pageable: Pageable
    ): Page<OutsourcingWorkRequest>
}