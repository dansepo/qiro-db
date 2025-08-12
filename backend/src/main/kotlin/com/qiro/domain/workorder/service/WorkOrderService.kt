package com.qiro.domain.workorder.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.user.repository.UserRepository
import com.qiro.domain.workorder.dto.*
import com.qiro.domain.workorder.entity.*
import com.qiro.domain.workorder.repository.WorkOrderRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.data.domain.Sort
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * 작업 지시서 서비스
 * 작업 지시서 생성, 수정, 상태 관리 등의 비즈니스 로직 처리
 */
@Service
@Transactional(readOnly = true)
class WorkOrderService(
    private val workOrderRepository: WorkOrderRepository,
    private val companyRepository: CompanyRepository,
    private val userRepository: UserRepository
) {
    
    /**
     * 작업 지시서 생성
     */
    @Transactional
    fun createWorkOrder(companyId: UUID, request: CreateWorkOrderRequest, createdBy: UUID): WorkOrderResponse {
        val company = companyRepository.findById(companyId)
            .orElseThrow { BusinessException(ErrorCode.COMPANY_NOT_FOUND) }
        
        val workOrder = WorkOrder().apply {
            this.company = company
            workOrderNumber = generateWorkOrderNumber(companyId)
            workOrderTitle = request.workOrderTitle
            workDescription = request.workDescription
            workCategory = request.workCategory
            workType = request.workType
            workPriority = request.workPriority
            workUrgency = request.workUrgency
            requestReason = request.requestReason
            workLocation = request.workLocation
            workScope = request.workScope
            scheduledStartDate = request.scheduledStartDate
            scheduledEndDate = request.scheduledEndDate
            estimatedDurationHours = request.estimatedDurationHours
            estimatedCost = request.estimatedCost
            
            // 관련 엔티티 설정
            request.buildingId?.let { buildingId ->
                // 실제 구현에서는 BuildingRepository를 통해 조회
                // building = buildingRepository.findById(buildingId).orElse(null)
            }
            
            request.unitId?.let { unitId ->
                // 실제 구현에서는 UnitRepository를 통해 조회
                // unit = unitRepository.findById(unitId).orElse(null)
            }
            
            request.assetId?.let { assetId ->
                // 실제 구현에서는 FacilityAssetRepository를 통해 조회
                // asset = facilityAssetRepository.findById(assetId).orElse(null)
            }
            
            request.faultReportId?.let { faultReportId ->
                // 실제 구현에서는 FaultReportRepository를 통해 조회
                // faultReport = faultReportRepository.findById(faultReportId).orElse(null)
            }
            
            request.templateId?.let { templateId ->
                // 실제 구현에서는 WorkOrderTemplateRepository를 통해 조회
                // template = workOrderTemplateRepository.findById(templateId).orElse(null)
            }
            
            // 요청자 설정
            requestedBy = userRepository.findById(createdBy).orElse(null)
        }
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 지시서 수정
     */
    @Transactional
    fun updateWorkOrder(
        companyId: UUID,
        workOrderId: UUID,
        request: UpdateWorkOrderRequest,
        updatedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        
        // 완료된 작업은 수정 불가
        if (workOrder.workStatus in listOf(WorkStatus.COMPLETED, WorkStatus.CANCELLED)) {
            throw BusinessException(ErrorCode.WORK_ORDER_CANNOT_BE_MODIFIED)
        }
        
        request.workOrderTitle?.let { workOrder.workOrderTitle = it }
        request.workDescription?.let { workOrder.workDescription = it }
        request.workPriority?.let { workOrder.workPriority = it }
        request.workUrgency?.let { workOrder.workUrgency = it }
        request.workLocation?.let { workOrder.workLocation = it }
        request.workScope?.let { workOrder.workScope = it }
        request.scheduledStartDate?.let { workOrder.scheduledStartDate = it }
        request.scheduledEndDate?.let { workOrder.scheduledEndDate = it }
        request.estimatedDurationHours?.let { workOrder.estimatedDurationHours = it }
        request.estimatedCost?.let { workOrder.estimatedCost = it }
        request.approvedBudget?.let { workOrder.approvedBudget = it }
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 지시서 상태 변경
     */
    @Transactional
    fun updateWorkOrderStatus(
        companyId: UUID,
        workOrderId: UUID,
        request: WorkOrderStatusUpdateRequest,
        updatedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val updater = userRepository.findById(updatedBy).orElse(null)
        
        // 상태 전환 가능 여부 확인
        if (!workOrder.canTransitionTo(request.newStatus)) {
            throw BusinessException(ErrorCode.INVALID_STATUS_TRANSITION)
        }
        
        workOrder.updateStatus(request.newStatus, updater)
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업자 배정
     */
    @Transactional
    fun assignWorker(
        companyId: UUID,
        workOrderId: UUID,
        request: AssignWorkerRequest,
        assignedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val worker = userRepository.findById(request.workerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        val assigner = userRepository.findById(assignedBy).orElse(null)
        
        // 이미 배정된 작업인지 확인
        if (workOrder.assignedTo != null) {
            throw BusinessException(ErrorCode.WORK_ORDER_ALREADY_ASSIGNED)
        }
        
        workOrder.assignWorker(worker, assigner)
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 승인
     */
    @Transactional
    fun approveWorkOrder(
        companyId: UUID,
        workOrderId: UUID,
        request: ApproveWorkOrderRequest,
        approvedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val approver = userRepository.findById(approvedBy)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        
        if (workOrder.approvalStatus != ApprovalStatus.PENDING) {
            throw BusinessException(ErrorCode.WORK_ORDER_ALREADY_PROCESSED)
        }
        
        workOrder.approve(approver, request.approvalNotes)
        request.approvedBudget?.let { workOrder.approvedBudget = it }
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 거부
     */
    @Transactional
    fun rejectWorkOrder(
        companyId: UUID,
        workOrderId: UUID,
        reason: String,
        rejectedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val rejector = userRepository.findById(rejectedBy)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        
        if (workOrder.approvalStatus != ApprovalStatus.PENDING) {
            throw BusinessException(ErrorCode.WORK_ORDER_ALREADY_PROCESSED)
        }
        
        workOrder.reject(rejector, reason)
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 완료
     */
    @Transactional
    fun completeWorkOrder(
        companyId: UUID,
        workOrderId: UUID,
        request: CompleteWorkOrderRequest,
        completedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        
        if (workOrder.workStatus != WorkStatus.IN_PROGRESS) {
            throw BusinessException(ErrorCode.WORK_ORDER_NOT_IN_PROGRESS)
        }
        
        workOrder.complete(request.completionNotes, request.qualityRating)
        request.customerSatisfaction?.let { workOrder.customerSatisfaction = it }
        request.actualCost?.let { workOrder.actualCost = it }
        workOrder.followUpRequired = request.followUpRequired
        workOrder.followUpDate = request.followUpDate
        workOrder.followUpNotes = request.followUpNotes
        
        // 실제 소요 시간 계산
        workOrder.actualDurationHours = workOrder.calculateActualDuration()
        
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }
    
    /**
     * 작업 지시서 조회
     */
    fun getWorkOrder(companyId: UUID, workOrderId: UUID): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        return convertToResponse(workOrder)
    }
    
    /**
     * 작업 지시서 목록 조회
     */
    fun getWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderSummary> {
        return workOrderRepository.findByCompanyCompanyId(companyId, pageable)
            .map { convertToSummary(it) }
    }
    
    /**
     * 작업 지시서 검색
     */
    fun searchWorkOrders(companyId: UUID, request: WorkOrderSearchRequest): Page<WorkOrderSummary> {
        val pageable = PageRequest.of(
            request.page,
            request.size,
            Sort.Direction.fromString(request.sortDirection),
            request.sortBy
        )
        
        return workOrderRepository.searchWorkOrders(
            companyId = companyId,
            keyword = request.keyword,
            workCategory = request.workCategory,
            workType = request.workType,
            workStatus = request.workStatus,
            workPriority = request.workPriority,
            assignedToId = request.assignedTo,
            buildingId = request.buildingId,
            unitId = request.unitId,
            requestedById = request.requestedBy,
            startDate = request.startDate,
            endDate = request.endDate,
            pageable = pageable
        ).map { convertToSummary(it) }
    }
    
    /**
     * 긴급 작업 지시서 조회
     */
    fun getUrgentWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderSummary> {
        return workOrderRepository.findUrgentWorkOrders(companyId, pageable)
            .map { convertToSummary(it) }
    }
    
    /**
     * 지연된 작업 지시서 조회
     */
    fun getDelayedWorkOrders(companyId: UUID, pageable: Pageable): Page<WorkOrderSummary> {
        return workOrderRepository.findDelayedWorkOrders(companyId, LocalDateTime.now(), pageable)
            .map { convertToSummary(it) }
    }
    
    /**
     * 담당자별 작업 지시서 조회
     */
    fun getWorkOrdersByAssignee(companyId: UUID, assigneeId: UUID, pageable: Pageable): Page<WorkOrderSummary> {
        return workOrderRepository.findByCompanyCompanyIdAndAssignedToUserId(companyId, assigneeId, pageable)
            .map { convertToSummary(it) }
    }
    
    /**
     * 작업 지시서 통계 조회
     */
    fun getWorkOrderStatistics(companyId: UUID, startDate: LocalDateTime, endDate: LocalDateTime): WorkOrderStatistics {
        val totalCount = workOrderRepository.countByCompanyCompanyIdAndRequestDateBetween(companyId, startDate, endDate)
        val pendingCount = workOrderRepository.countByCompanyCompanyIdAndWorkStatus(companyId, WorkStatus.PENDING)
        val inProgressCount = workOrderRepository.countByCompanyCompanyIdAndWorkStatus(companyId, WorkStatus.IN_PROGRESS)
        val completedCount = workOrderRepository.countByCompanyCompanyIdAndWorkStatus(companyId, WorkStatus.COMPLETED)
        val cancelledCount = workOrderRepository.countByCompanyCompanyIdAndWorkStatus(companyId, WorkStatus.CANCELLED)
        val delayedCount = workOrderRepository.countDelayedWorkOrders(companyId, LocalDateTime.now())
        
        val completionRate = workOrderRepository.calculateCompletionRate(companyId, startDate, endDate) ?: 0.0
        val averageCompletionDays = workOrderRepository.calculateAverageCompletionDays(companyId, startDate, endDate) ?: 0.0
        val onTimeCompletionRate = workOrderRepository.calculateOnTimeCompletionRate(companyId, startDate, endDate) ?: 0.0
        val averageQualityRating = workOrderRepository.calculateAverageQualityRating(companyId, startDate, endDate)?.let { BigDecimal.valueOf(it) } ?: BigDecimal.ZERO
        val averageCustomerSatisfaction = workOrderRepository.calculateAverageCustomerSatisfaction(companyId, startDate, endDate)?.let { BigDecimal.valueOf(it) } ?: BigDecimal.ZERO
        
        // 카테고리별 통계
        val categoryStatistics = WorkCategory.values().associateWith { category ->
            workOrderRepository.countByCompanyCompanyIdAndWorkCategory(companyId, category)
        }
        
        // 유형별 통계
        val typeStatistics = WorkType.values().associateWith { type ->
            workOrderRepository.countByCompanyCompanyIdAndWorkType(companyId, type)
        }
        
        // 우선순위별 통계
        val priorityStatistics = WorkPriority.values().associateWith { priority ->
            workOrderRepository.countByCompanyCompanyIdAndWorkPriority(companyId, priority)
        }
        
        return WorkOrderStatistics(
            totalCount = totalCount,
            pendingCount = pendingCount,
            inProgressCount = inProgressCount,
            completedCount = completedCount,
            cancelledCount = cancelledCount,
            delayedCount = delayedCount,
            averageCompletionDays = averageCompletionDays,
            completionRate = completionRate,
            onTimeCompletionRate = onTimeCompletionRate,
            averageQualityRating = averageQualityRating,
            averageCustomerSatisfaction = averageCustomerSatisfaction,
            categoryStatistics = categoryStatistics,
            typeStatistics = typeStatistics,
            priorityStatistics = priorityStatistics
        )
    }
    
    /**
     * 작업 지시서 대시보드 데이터 조회
     */
    fun getWorkOrderDashboard(companyId: UUID, userId: UUID): WorkOrderDashboard {
        val now = LocalDateTime.now()
        val startOfMonth = now.withDayOfMonth(1).withHour(0).withMinute(0).withSecond(0)
        val endOfMonth = now.withDayOfMonth(now.toLocalDate().lengthOfMonth()).withHour(23).withMinute(59).withSecond(59)
        
        val statistics = getWorkOrderStatistics(companyId, startOfMonth, endOfMonth)
        
        val recentPageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "createdAt"))
        val urgentPageable = PageRequest.of(0, 10)
        val delayedPageable = PageRequest.of(0, 10)
        val myAssignedPageable = PageRequest.of(0, 10, Sort.by(Sort.Direction.DESC, "createdAt"))
        
        val recentWorkOrders = getWorkOrders(companyId, recentPageable).content
        val urgentWorkOrders = getUrgentWorkOrders(companyId, urgentPageable).content
        val delayedWorkOrders = getDelayedWorkOrders(companyId, delayedPageable).content
        val myAssignedWorkOrders = getWorkOrdersByAssignee(companyId, userId, myAssignedPageable).content
        
        return WorkOrderDashboard(
            statistics = statistics,
            recentWorkOrders = recentWorkOrders,
            urgentWorkOrders = urgentWorkOrders,
            delayedWorkOrders = delayedWorkOrders,
            myAssignedWorkOrders = myAssignedWorkOrders
        )
    }
    
    /**
     * 작업 지시서 번호 생성
     */
    private fun generateWorkOrderNumber(companyId: UUID): String {
        val now = LocalDateTime.now()
        val prefix = "WO${now.format(DateTimeFormatter.ofPattern("yyyyMM"))}"
        val maxNumber = workOrderRepository.findMaxWorkOrderNumber(companyId, prefix) ?: 0
        val nextNumber = maxNumber + 1
        return "${prefix}${String.format("%04d", nextNumber)}"
    }
    
    /**
     * 작업 지시서 조회 (내부용)
     */
    private fun findWorkOrderByIdAndCompany(workOrderId: UUID, companyId: UUID): WorkOrder {
        return workOrderRepository.findById(workOrderId)
            .filter { it.company.id == companyId }
            .orElseThrow { BusinessException(ErrorCode.WORK_ORDER_NOT_FOUND) }
    }
    
    /**
     * WorkOrder 엔티티를 WorkOrderResponse DTO로 변환
     */
    private fun convertToResponse(workOrder: WorkOrder): WorkOrderResponse {
        return WorkOrderResponse(
            workOrderId = workOrder.workOrderId,
            workOrderNumber = workOrder.workOrderNumber,
            workOrderTitle = workOrder.workOrderTitle,
            workDescription = workOrder.workDescription,
            workCategory = workOrder.workCategory,
            workType = workOrder.workType,
            workPriority = workOrder.workPriority,
            workUrgency = workOrder.workUrgency,
            workStatus = workOrder.workStatus,
            approvalStatus = workOrder.approvalStatus,
            workPhase = workOrder.workPhase,
            progressPercentage = workOrder.progressPercentage,
            buildingId = workOrder.building?.id,
            buildingName = workOrder.building?.buildingName,
            unitId = null, // Unit 엔티티에 id 필드가 없음
            unitName = workOrder.unit?.unitNumber,
            assetId = null, // FacilityAsset의 id는 Long 타입이므로 UUID 변환 필요
            assetName = workOrder.asset?.assetName,
            faultReportId = workOrder.faultReport?.id,
            templateId = workOrder.template?.templateId,
            requestedBy = workOrder.requestedBy?.let { 
                UserSummary(it.id, it.fullName, it.email) 
            },
            requestDate = workOrder.requestDate,
            requestReason = workOrder.requestReason,
            workLocation = workOrder.workLocation,
            workScope = workOrder.workScope,
            scheduledStartDate = workOrder.scheduledStartDate,
            scheduledEndDate = workOrder.scheduledEndDate,
            estimatedDurationHours = workOrder.estimatedDurationHours,
            assignedTo = workOrder.assignedTo?.let { 
                UserSummary(it.id, it.fullName, it.email) 
            },
            assignedTeam = workOrder.assignedTeam,
            assignmentDate = workOrder.assignmentDate,
            actualStartDate = workOrder.actualStartDate,
            actualEndDate = workOrder.actualEndDate,
            actualDurationHours = workOrder.actualDurationHours,
            estimatedCost = workOrder.estimatedCost,
            approvedBudget = workOrder.approvedBudget,
            actualCost = workOrder.actualCost,
            workCompletionNotes = workOrder.workCompletionNotes,
            qualityRating = workOrder.qualityRating,
            customerSatisfaction = workOrder.customerSatisfaction,
            followUpRequired = workOrder.followUpRequired,
            followUpDate = workOrder.followUpDate,
            followUpNotes = workOrder.followUpNotes,
            approvedBy = workOrder.approvedBy?.let { 
                UserSummary(it.id, it.fullName, it.email) 
            },
            approvalDate = workOrder.approvalDate,
            approvalNotes = workOrder.approvalNotes,
            closedBy = workOrder.closedBy?.let { 
                UserSummary(it.id, it.fullName, it.email) 
            },
            closedDate = workOrder.closedDate,
            closureReason = workOrder.closureReason,
            createdAt = workOrder.createdAt ?: LocalDateTime.now(),
            updatedAt = workOrder.updatedAt ?: LocalDateTime.now(),
            isDelayed = workOrder.isDelayed()
        )
    }
    
    /**
     * WorkOrder 엔티티를 WorkOrderSummary DTO로 변환
     */
    private fun convertToSummary(workOrder: WorkOrder): WorkOrderSummary {
        return WorkOrderSummary(
            workOrderId = workOrder.workOrderId,
            workOrderNumber = workOrder.workOrderNumber,
            workOrderTitle = workOrder.workOrderTitle,
            workCategory = workOrder.workCategory,
            workType = workOrder.workType,
            workPriority = workOrder.workPriority,
            workStatus = workOrder.workStatus,
            progressPercentage = workOrder.progressPercentage,
            assignedTo = workOrder.assignedTo?.let { 
                UserSummary(it.id, it.fullName, it.email) 
            },
            scheduledStartDate = workOrder.scheduledStartDate,
            scheduledEndDate = workOrder.scheduledEndDate,
            isDelayed = workOrder.isDelayed(),
            createdAt = workOrder.createdAt ?: LocalDateTime.now()
        )
    }
    
    /**
     * 기간별 작업 지시서 개수 조회 (Repository 확장 메서드)
     */
    private fun WorkOrderRepository.countByCompanyCompanyIdAndRequestDateBetween(
        companyId: UUID,
        startDate: LocalDateTime,
        endDate: LocalDateTime
    ): Long {
        return findByCompanyCompanyIdAndRequestDateBetween(companyId, startDate, endDate, Pageable.unpaged()).totalElements
    }

    /**
     * 작업자별 할당된 작업 목록 조회
     */
    fun getWorkerAssignments(
        companyId: UUID,
        workerId: UUID,
        status: WorkStatus?,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<WorkOrderResponse> {
        return workOrderRepository.findWorkerAssignments(companyId, workerId, status, startDate, endDate, pageable)
            .map { convertToResponse(it) }
    }

    /**
     * 작업자별 작업 통계 조회
     */
    fun getWorkerStatistics(
        companyId: UUID,
        workerId: UUID,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?
    ): WorkerStatistics {
        val worker = userRepository.findById(workerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }

        val effectiveStartDate = startDate ?: LocalDateTime.now().minusMonths(12)
        val effectiveEndDate = endDate ?: LocalDateTime.now()

        val totalAssigned = workOrderRepository.countByAssignedWorker(companyId, workerId, effectiveStartDate, effectiveEndDate)
        val completed = workOrderRepository.countByAssignedWorkerAndStatus(companyId, workerId, WorkStatus.COMPLETED, effectiveStartDate, effectiveEndDate)
        val inProgress = workOrderRepository.countByAssignedWorkerAndStatus(companyId, workerId, WorkStatus.IN_PROGRESS, effectiveStartDate, effectiveEndDate)
        val pending = workOrderRepository.countByAssignedWorkerAndStatus(companyId, workerId, WorkStatus.PENDING, effectiveStartDate, effectiveEndDate)
        val cancelled = workOrderRepository.countByAssignedWorkerAndStatus(companyId, workerId, WorkStatus.CANCELLED, effectiveStartDate, effectiveEndDate)

        val completionRate = if (totalAssigned > 0) (completed.toDouble() / totalAssigned.toDouble()) * 100 else 0.0
        val avgCompletionDays = workOrderRepository.calculateWorkerAverageCompletionDays(companyId, workerId, effectiveStartDate, effectiveEndDate) ?: 0.0
        val onTimeCompletionRate = workOrderRepository.calculateWorkerOnTimeCompletionRate(companyId, workerId, effectiveStartDate, effectiveEndDate) ?: 0.0
        val avgQualityRating = workOrderRepository.calculateWorkerAverageQualityRating(companyId, workerId, effectiveStartDate, effectiveEndDate)?.let { BigDecimal.valueOf(it) } ?: BigDecimal.ZERO
        val totalWorkingHours = workOrderRepository.calculateWorkerTotalWorkingHours(companyId, workerId, effectiveStartDate, effectiveEndDate) ?: BigDecimal.ZERO

        val workloadByCategory = workOrderRepository.getWorkerWorkloadByCategory(companyId, workerId, effectiveStartDate, effectiveEndDate)
        val workloadByType = workOrderRepository.getWorkerWorkloadByType(companyId, workerId, effectiveStartDate, effectiveEndDate)
        val monthlyTrend = workOrderRepository.getWorkerMonthlyCompletionTrend(companyId, workerId, effectiveStartDate, effectiveEndDate)

        return WorkerStatistics(
            workerId = workerId,
            workerName = worker.fullName,
            totalAssignedCount = totalAssigned,
            completedCount = completed,
            inProgressCount = inProgress,
            pendingCount = pending,
            cancelledCount = cancelled,
            completionRate = completionRate,
            averageCompletionDays = avgCompletionDays,
            onTimeCompletionRate = onTimeCompletionRate,
            averageQualityRating = avgQualityRating,
            totalWorkingHours = totalWorkingHours,
            workloadByCategory = workloadByCategory,
            workloadByType = workloadByType,
            monthlyCompletionTrend = monthlyTrend
        )
    }

    /**
     * 작업 진행 상황 업데이트
     */
    @Transactional
    fun updateWorkProgress(
        companyId: UUID,
        workOrderId: UUID,
        request: WorkProgressUpdateRequest,
        updatedBy: UUID
    ): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val updater = userRepository.findById(updatedBy).orElse(null)

        if (workOrder.workStatus != WorkStatus.IN_PROGRESS) {
            throw BusinessException(ErrorCode.WORK_ORDER_NOT_IN_PROGRESS)
        }

        workOrder.updateProgress(
            percentage = request.progressPercentage,
            phase = request.workPhase
        )
        
        // 추가 필드 업데이트
        // progressNotes 필드는 WorkOrder 엔티티에 없음
        workOrder.actualDurationHours = request.actualHoursWorked ?: BigDecimal.ZERO

        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }

    /**
     * 작업 일시 중지
     */
    @Transactional
    fun pauseWorkOrder(companyId: UUID, workOrderId: UUID, reason: String, pausedBy: UUID): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val pauser = userRepository.findById(pausedBy).orElse(null)

        if (workOrder.workStatus != WorkStatus.IN_PROGRESS) {
            throw BusinessException(ErrorCode.WORK_ORDER_NOT_IN_PROGRESS)
        }

        workOrder.pause()
        // progressNotes 필드는 WorkOrder 엔티티에 없음
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }

    /**
     * 작업 재개
     */
    @Transactional
    fun resumeWorkOrder(companyId: UUID, workOrderId: UUID, reason: String?, resumedBy: UUID): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val resumer = userRepository.findById(resumedBy).orElse(null)

        if (workOrder.workStatus != WorkStatus.PAUSED) {
            throw BusinessException(ErrorCode.WORK_ORDER_NOT_PAUSED)
        }

        workOrder.resume()
        // progressNotes 필드는 WorkOrder 엔티티에 없음
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }

    /**
     * 작업 취소
     */
    @Transactional
    fun cancelWorkOrder(companyId: UUID, workOrderId: UUID, reason: String, cancelledBy: UUID): WorkOrderResponse {
        val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val canceller = userRepository.findById(cancelledBy).orElse(null)

        if (workOrder.workStatus in listOf(WorkStatus.COMPLETED, WorkStatus.CANCELLED)) {
            throw BusinessException(ErrorCode.WORK_ORDER_CANNOT_BE_CANCELLED)
        }

        workOrder.cancel()
        // progressNotes 필드는 WorkOrder 엔티티에 없음
        val savedWorkOrder = workOrderRepository.save(workOrder)
        return convertToResponse(savedWorkOrder)
    }

    /**
     * 작업 지시서 복사
     */
    @Transactional
    fun copyWorkOrder(
        companyId: UUID,
        workOrderId: UUID,
        request: CopyWorkOrderRequest,
        createdBy: UUID
    ): WorkOrderResponse {
        val originalWorkOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
        val creator = userRepository.findById(createdBy).orElse(null)

        val copiedWorkOrder = WorkOrder().apply {
            company = originalWorkOrder.company
            building = originalWorkOrder.building
            unit = originalWorkOrder.unit
            asset = originalWorkOrder.asset
            faultReport = null
            workOrderNumber = generateWorkOrderNumber(companyId)
            workOrderTitle = request.newTitle
            workDescription = request.newDescription ?: originalWorkOrder.workDescription
            workCategory = originalWorkOrder.workCategory
            workType = originalWorkOrder.workType
            workPriority = originalWorkOrder.workPriority
            estimatedDurationHours = originalWorkOrder.estimatedDurationHours
            estimatedCost = originalWorkOrder.estimatedCost
            scheduledStartDate = request.scheduledStartDate
            scheduledEndDate = request.scheduledEndDate
            workStatus = WorkStatus.PENDING
            approvalStatus = ApprovalStatus.PENDING
            workPhase = WorkPhase.PLANNING
            progressPercentage = 0
            requestedBy = creator
            requestDate = LocalDateTime.now()
            if (request.copyAssignments) {
                assignedTo = originalWorkOrder.assignedTo
                assignedTeam = originalWorkOrder.assignedTeam
            }
        }

        val savedWorkOrder = workOrderRepository.save(copiedWorkOrder)
        return convertToResponse(savedWorkOrder)
    }

    /**
     * 작업 지시서 일괄 상태 변경
     */
    @Transactional
    fun batchUpdateStatus(
        companyId: UUID,
        request: BatchStatusUpdateRequest,
        updatedBy: UUID
    ): BatchUpdateResult {
        val updater = userRepository.findById(updatedBy).orElse(null)
        val failures = mutableListOf<BatchUpdateFailure>()
        var successCount = 0

        request.workOrderIds.forEach { workOrderId ->
            try {
                val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
                
                if (workOrder.canTransitionTo(request.newStatus)) {
                    workOrder.updateStatus(request.newStatus, updater)
                    workOrderRepository.save(workOrder)
                    successCount++
                } else {
                    failures.add(BatchUpdateFailure(
                        workOrderId = workOrderId,
                        workOrderNumber = workOrder.workOrderNumber,
                        reason = "Invalid status transition from ${workOrder.workStatus} to ${request.newStatus}"
                    ))
                }
            } catch (e: Exception) {
                failures.add(BatchUpdateFailure(
                    workOrderId = workOrderId,
                    workOrderNumber = "Unknown",
                    reason = e.message ?: "Unknown error"
                ))
            }
        }

        return BatchUpdateResult(
            totalCount = request.workOrderIds.size,
            successCount = successCount,
            failureCount = failures.size,
            failedItems = failures
        )
    }

    /**
     * 작업 지시서 일괄 배정
     */
    @Transactional
    fun batchAssignWorker(
        companyId: UUID,
        request: BatchAssignRequest,
        assignedBy: UUID
    ): BatchUpdateResult {
        val worker = userRepository.findById(request.workerId)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        val assigner = userRepository.findById(assignedBy).orElse(null)
        val failures = mutableListOf<BatchUpdateFailure>()
        var successCount = 0

        request.workOrderIds.forEach { workOrderId ->
            try {
                val workOrder = findWorkOrderByIdAndCompany(workOrderId, companyId)
                
                if (workOrder.assignedTo == null && workOrder.workStatus in listOf(WorkStatus.PENDING, WorkStatus.APPROVED)) {
                    workOrder.assignWorker(worker, assigner)
                    workOrderRepository.save(workOrder)
                    successCount++
                } else {
                    failures.add(BatchUpdateFailure(
                        workOrderId = workOrderId,
                        workOrderNumber = workOrder.workOrderNumber,
                        reason = "Work order is already assigned or not in assignable status"
                    ))
                }
            } catch (e: Exception) {
                failures.add(BatchUpdateFailure(
                    workOrderId = workOrderId,
                    workOrderNumber = "Unknown",
                    reason = e.message ?: "Unknown error"
                ))
            }
        }

        return BatchUpdateResult(
            totalCount = request.workOrderIds.size,
            successCount = successCount,
            failureCount = failures.size,
            failedItems = failures
        )
    }
}